;;; emacs-jp-kanban.el --- Org-backed Kanban board with M-x commands -*- lexical-binding: t; -*-

;;; Commentary:

;; A lightweight Kanban board built directly on Org headings.  It does
;; not copy tasks anywhere: every card is the heading in your Org file,
;; so agenda, deadlines, clocking, refile and capture keep working as
;; usual.
;;
;; Boards are inferred from the tasks themselves, in this order:
;;
;;   1. the inherited :KANBAN: property of the heading;
;;   2. an inherited @tag (the board is the tag without the @);
;;   3. the file-level #+KANBAN_BOARD: keyword;
;;   4. the file name (fallback, so untagged files still get a board).
;;
;; That means this already works with the current files:
;;
;;   :@work:      -> board "work"
;;   :@home:      -> board "home"
;;   :@personal:  -> board "personal"
;;   :@project:   -> board "project"
;;
;; Or you can be explicit:
;;
;;   #+KANBAN_BOARD: work
;;
;;   * Some project
;;   :PROPERTIES:
;;   :KANBAN: work
;;   :END:
;;
;; The board shows only the TODO keywords listed in `jp-kanban-columns':
;; by default TODO, DOING and DONE.  Any other keyword (NEXT, WAITING,
;; PROJ, CANCELLED, ...) is ignored until you add it to a column.
;;
;; Suggested commands while testing:
;;
;;   M-x load-file RET ~/.config/emacs/emacs-jp-modules/emacs-jp-kanban.el RET
;;   M-x jp-kanban-open
;;
;; Once it feels right, add (require 'emacs-jp-kanban) to init.el.
;;
;; Useful configuration (all optional):
;;
;;   (setq jp-kanban-files '("~/Documents/Emacs/org/agenda/"))
;;   (setq jp-kanban-board-files
;;         '(("work" . "~/Documents/Emacs/org/agenda/work.org")
;;           ("home" . "~/Documents/Emacs/org/agenda/agenda.org")))
;;   (setq jp-kanban-done-days 14)
;;   (setq jp-kanban-show-undated-done t)   ; also show DONE without CLOSED
;;   (setq jp-kanban-full-frame nil)        ; show in a split, not full frame
;;
;; The files in `jp-kanban-files' (or `org-agenda-files' when it is
;; nil) are scanned, and so are the inbox and per-board files, so a
;; card created from the board appears immediately.  `M-x
;; jp-kanban-open' with a prefix argument shows every board together.
;;
;; Keys in the board buffer:
;;
;;   n/p, j/k  next/previous card
;;   RET/o     open the card in its Org file (full frame by default)
;;   s         mark DOING
;;   x         mark DONE
;;   r         reopen as TODO
;;   m         choose any TODO state
;;   a         add a card
;;   e         edit the card title
;;   P         set priority
;;   D/S       set DEADLINE / SCHEDULED
;;   B         move the card to another board
;;   f/F       filter by tag / clear the filter
;;   i/O       clock in / clock out
;;   b         switch board
;;   A         Org agenda restricted to the board
;;   g         refresh
;;   q         quit
;;
;; The board is a normal read-only buffer, so Evil motions and regular
;; Emacs keys both work.  The important keys are also registered in
;; Evil's normal state when Evil is available.

;;; Code:

(require 'cl-lib)
(require 'seq)
(require 'subr-x)
(require 'org)
(require 'org-agenda)

(defgroup jp-kanban nil
  "Org-backed Kanban board."
  :group 'org
  :prefix "jp-kanban-")

(defcustom jp-kanban-files nil
  "Org files scanned by the Kanban board.
When nil, use `org-agenda-files'.  Entries may be files or
directories accepted by `org-agenda-files'."
  :type '(choice (const :tag "Use `org-agenda-files'" nil)
                 (repeat (file :tag "Org file or directory")))
  :group 'jp-kanban)

(defcustom jp-kanban-columns
  '(("TODO" "TODO")
    ("DOING" "DOING")
    ("DONE" "DONE"))
  "Kanban columns.
Each element is (LABEL STATE...).  LABEL is the heading shown in the
board and STATE... are the Org TODO keywords collected in that
column.

Only the states listed here are shown.  The default keeps just TODO,
DOING and DONE, so other keywords such as NEXT, WAITING, PROJ or
CANCELLED are ignored.  Add them to a column if you ever want them
back on the board."
  :type '(repeat (cons (string :tag "Column")
                       (repeat (string :tag "Org TODO state"))))
  :group 'jp-kanban)

(defcustom jp-kanban-done-column "DONE"
  "Label of the column that contains finished tasks.
Used for the done cutoff and to decide which states appear in the
board agenda."
  :type 'string
  :group 'jp-kanban)

(defcustom jp-kanban-done-days 7
  "How many days of DONE tasks to show.
The DONE column only includes tasks with a CLOSED timestamp in this
many days.  Set this to nil to show every DONE task, or increase it
when reviewing a longer period.

Tasks completed without logging a CLOSED timestamp are hidden unless
`jp-kanban-show-undated-done' is non-nil."
  :type '(choice (const :tag "All DONE tasks" nil)
                 (integer :tag "Days"))
  :group 'jp-kanban)

(defcustom jp-kanban-show-undated-done nil
  "Whether to show DONE tasks that have no CLOSED timestamp.
With the default nil, such tasks are hidden because the board cannot
tell how old they are.  Set this to t if you disable `org-log-done'
and still want to see finished tasks."
  :type 'boolean
  :group 'jp-kanban)

(defcustom jp-kanban-board-property "KANBAN"
  "Org property whose inherited value names the board."
  :type 'string
  :group 'jp-kanban)

(defcustom jp-kanban-board-keyword "KANBAN_BOARD"
  "File-level Org keyword that names the board of a file."
  :type 'string
  :group 'jp-kanban)

(defcustom jp-kanban-board-tag-prefix "@"
  "Prefix used by context tags that double as board names.
For example, the inherited tag :@work: becomes board \"work\"."
  :type 'string
  :group 'jp-kanban)

(defcustom jp-kanban-use-file-fallback t
  "Whether to use the file name as the board when nothing else matches."
  :type 'boolean
  :group 'jp-kanban)

(defcustom jp-kanban-default-board "inbox"
  "Board used when a task has no explicit board and no file name."
  :type 'string
  :group 'jp-kanban)

(defcustom jp-kanban-extra-boards nil
  "Board names to offer even when they have no tasks yet."
  :type '(repeat string)
  :group 'jp-kanban)

(defcustom jp-kanban-inbox-file
  (expand-file-name "agenda/refile.org" org-directory)
  "File where `jp-kanban-add-task' creates new cards when no board
specific file is configured."
  :type 'file
  :group 'jp-kanban)

(defcustom jp-kanban-inbox-heading "All tasks"
  "Heading under which `jp-kanban-add-task' creates new cards.
Set it to nil to append cards at the end of the file."
  :type '(choice (const :tag "End of file" nil)
                 (string :tag "Heading"))
  :group 'jp-kanban)

(defcustom jp-kanban-board-files nil
  "Alist mapping board names to the file used for new cards.
For example:
  ((\"work\" . \"~/Documents/Emacs/org/agenda/work.org\")
   (\"home\" . \"~/Documents/Emacs/org/agenda/agenda.org\"))
Boards not present here use `jp-kanban-inbox-file'."
  :type '(alist :key-type string :value-type file)
  :group 'jp-kanban)

(defcustom jp-kanban-show-tags t
  "Whether to show non-board tags on the card's metadata line."
  :type 'boolean
  :group 'jp-kanban)

(defcustom jp-kanban-show-category t
  "Whether to show the Org category on the card's metadata line."
  :type 'boolean
  :group 'jp-kanban)

(defcustom jp-kanban-save-on-change t
  "Whether board commands save the Org buffer after changing a card."
  :type 'boolean
  :group 'jp-kanban)

(defcustom jp-kanban-full-frame t
  "Whether to display Kanban buffers using the entire frame.
With the default t, opening a board and opening a card delete the
other windows of the frame.  Set it to nil to obey the normal
`display-buffer' rules and show them in a split window."
  :type 'boolean
  :group 'jp-kanban)

(defcustom jp-kanban-start-state "DOING"
  "TODO state used by `jp-kanban-start-task'."
  :type 'string
  :group 'jp-kanban)

(defcustom jp-kanban-done-state "DONE"
  "TODO state used by `jp-kanban-complete-task'."
  :type 'string
  :group 'jp-kanban)

(defcustom jp-kanban-reopen-state "TODO"
  "TODO state used by `jp-kanban-reopen-task'."
  :type 'string
  :group 'jp-kanban)

(defcustom jp-kanban-agenda-states nil
  "States shown by `jp-kanban-agenda'.
When nil, use every state from the non-DONE columns."
  :type '(choice (const :tag "All non-DONE states" nil)
                 (repeat (string :tag "Org TODO state")))
  :group 'jp-kanban)

;;;; Faces

(defface jp-kanban-header-title
  '((t :inherit bold :height 1.1))
  "Face for the Kanban title in the header line."
  :group 'jp-kanban)

(defface jp-kanban-header-board
  '((t :inherit font-lock-keyword-face :weight bold))
  "Face for the board name in the header line."
  :group 'jp-kanban)

(defface jp-kanban-header-counts
  '((t :inherit shadow))
  "Face for column counts in the header line."
  :group 'jp-kanban)

(defface jp-kanban-filter
  '((t :inherit warning))
  "Face for the active tag filter."
  :group 'jp-kanban)

(defface jp-kanban-column-heading
  '((t :inherit bold))
  "Face for a generic column heading."
  :group 'jp-kanban)

(defface jp-kanban-column-todo
  '((t :inherit org-todo :weight bold))
  "Face for the TODO column heading."
  :group 'jp-kanban)

(defface jp-kanban-column-doing
  '((t :inherit warning :weight bold))
  "Face for the DOING column heading."
  :group 'jp-kanban)

(defface jp-kanban-column-done
  '((t :inherit org-done :weight bold))
  "Face for the DONE column heading."
  :group 'jp-kanban)

(defface jp-kanban-separator
  '((t :inherit shadow))
  "Face for table separators."
  :group 'jp-kanban)

(defface jp-kanban-priority-a
  '((t :inherit error :weight bold))
  "Face for [#A] priorities."
  :group 'jp-kanban)

(defface jp-kanban-priority-b
  '((t :inherit warning :weight bold))
  "Face for [#B] priorities."
  :group 'jp-kanban)

(defface jp-kanban-priority-c
  '((t :inherit success :weight bold))
  "Face for [#C] priorities."
  :group 'jp-kanban)

(defface jp-kanban-overdue
  '((t :inherit error :weight bold))
  "Face for an overdue deadline."
  :group 'jp-kanban)

(defface jp-kanban-today
  '((t :inherit warning :weight bold))
  "Face for a deadline or scheduled date that falls today."
  :group 'jp-kanban)

(defface jp-kanban-date
  '((t :inherit shadow))
  "Face for ordinary card dates."
  :group 'jp-kanban)

(defface jp-kanban-done
  '((t :inherit shadow))
  "Face for completed card titles."
  :group 'jp-kanban)

(defface jp-kanban-meta
  '((t :inherit shadow))
  "Face for card metadata.
Keep this at the default height: scaled text has a different glyph
advance in most monospace fonts and breaks column alignment."
  :group 'jp-kanban)

(defface jp-kanban-board
  '((t :inherit font-lock-keyword-face))
  "Face for the board name shown on a card in the all-boards view."
  :group 'jp-kanban)

(defface jp-kanban-clock
  '((t :inherit success :weight bold))
  "Face for the clock indicator."
  :group 'jp-kanban)

(defface jp-kanban-state
  '((t :inherit warning))
  "Face for a TODO state that differs from its column label."
  :group 'jp-kanban)

;;;; Task records

(cl-defstruct (jp-kanban-task (:constructor jp-kanban--make-task))
  state
  column
  title
  priority
  priority-label
  deadline
  scheduled
  closed
  closed-days
  effort
  tags
  category
  board
  marker
  key)

(defvar jp-kanban-last-board nil
  "Board opened most recently, used as the default prompt.")

(defvar jp-kanban-board-history nil
  "Minibuffer history of Kanban boards.")

(defvar jp-kanban-tag-history nil
  "Minibuffer history of Kanban tag filters.")

(defvar jp-kanban--resize-timer nil
  "Idle timer used to realign boards after a window resize.")

(defvar jp-kanban--agenda-board nil
  "Board currently used by `jp-kanban-agenda'.")

(declare-function evil-define-key "evil" (state keymap key def &rest bindings))
(declare-function evil-set-initial-state "evil" (mode state))

(defvar-local jp-kanban--board nil
  "Board displayed in the current Kanban buffer.
Nil means the all-boards view.")

(defvar-local jp-kanban--filter nil
  "Tag filter active in the current Kanban buffer.")

(defvar-local jp-kanban--counts nil
  "Alist of (COLUMN . COUNT) for the current Kanban buffer.")

(defvar-local jp-kanban--task-list nil
  "Tasks currently shown in the Kanban buffer.")

(defvar-local jp-kanban--file-keyword-cache nil
  "Cache of the file-level board keyword.
A cons of (BUFFER-MODIFIED-TICK . BOARD).")

(defvar jp-kanban-cell-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-1] #'jp-kanban-mouse-open)
    (define-key map [mouse-2] #'jp-kanban-mouse-open)
    map)
  "Keymap used on clickable Kanban cards.")

;;;; Board and task discovery

(defun jp-kanban--normalize-board (board)
  "Return BOARD as a canonical board name, or nil.
The leading context-tag prefix is stripped and the result is
downcased."
  (when (and board (stringp board))
    (let ((name (string-trim board)))
      (when (and (not (string-empty-p jp-kanban-board-tag-prefix))
                 (string-prefix-p jp-kanban-board-tag-prefix name))
        (setq name (substring name (length jp-kanban-board-tag-prefix))))
      (unless (string-empty-p name)
        (downcase name)))))

(defun jp-kanban--file-keyword-board ()
  "Return the board declared by the current file's KANBAN_BOARD keyword."
  (let ((tick (buffer-chars-modified-tick)))
    (if (and (consp jp-kanban--file-keyword-cache)
             (eq (car jp-kanban--file-keyword-cache) tick))
        (cdr jp-kanban--file-keyword-cache)
      (let ((board
             (when (derived-mode-p 'org-mode)
               (jp-kanban--normalize-board
                (cadr (assoc-string
                       jp-kanban-board-keyword
                       (org-collect-keywords (list jp-kanban-board-keyword))
                       t))))))
        (setq jp-kanban--file-keyword-cache (cons tick board))
        board))))

(defun jp-kanban--fallback-board ()
  "Return the board inferred from the current file name."
  (when jp-kanban-use-file-fallback
    (jp-kanban--normalize-board
     (or (and buffer-file-name
              (file-name-sans-extension
               (file-name-nondirectory buffer-file-name)))
         jp-kanban-default-board))))

(defun jp-kanban--board-at-point (&optional no-fallback)
  "Return the board of the Org heading at point.
With NO-FALLBACK non-nil, do not fall back to the file name."
  (or (jp-kanban--normalize-board
       (org-entry-get nil jp-kanban-board-property t))
      (let ((tag (seq-find
                  (lambda (tag)
                    (and (not (string-empty-p jp-kanban-board-tag-prefix))
                         (string-prefix-p jp-kanban-board-tag-prefix tag)))
                  (org-get-tags))))
        (jp-kanban--normalize-board tag))
      (jp-kanban--file-keyword-board)
      (unless no-fallback
        (jp-kanban--fallback-board))))

(defun jp-kanban--files ()
  "Return the Org files that the board should scan.
This is `jp-kanban-files' (or `org-agenda-files') plus the files used
for new cards, so a card created from the board shows up right away
even when its file is not an agenda file.  Directory entries are
expanded the same way Org expands `org-agenda-files'."
  (let* ((org-agenda-files (or jp-kanban-files org-agenda-files))
         (files (org-agenda-files t))
         (card-files (cons jp-kanban-inbox-file
                           (mapcar #'cdr jp-kanban-board-files))))
    (delete-dups
     (seq-filter #'file-readable-p
                 (mapcar #'expand-file-name (append files card-files))))))

(defun jp-kanban--column-for-state (state)
  "Return the column that contains STATE, or nil."
  (when state
    (seq-find (lambda (column)
                (member state (cdr column)))
              jp-kanban-columns)))

(defun jp-kanban--done-column-p (column)
  "Return non-nil when COLUMN is the done column."
  (string= (car column) jp-kanban-done-column))

(defun jp-kanban--timestamp-days (timestamp)
  "Return TIMESTAMP as an absolute day number, or nil."
  (when (and timestamp (stringp timestamp))
    (ignore-errors
      (time-to-days (org-time-string-to-time timestamp)))))

(defun jp-kanban--task-at-heading (board column today)
  "Build a task from the heading at point.
BOARD is its board, COLUMN its Kanban column and TODAY the current
absolute day number."
  (let* ((state (org-get-todo-state))
         (closed (org-entry-get nil "CLOSED"))
         (closed-days (jp-kanban--timestamp-days closed))
         (done-p (jp-kanban--done-column-p column)))
    (when (or (not done-p)
              (null jp-kanban-done-days)
              (and closed-days
                   (>= closed-days (- today jp-kanban-done-days)))
              (and jp-kanban-show-undated-done (null closed-days)))
      (let* ((marker (point-marker))
             (heading (org-get-heading t t t t))
             (priority (org-get-priority (org-get-heading t t nil t)))
             (priority-label (org-entry-get nil "PRIORITY")))
        (jp-kanban--make-task
         :state state
         :column (car column)
         :title (string-trim heading)
         :priority priority
         :priority-label priority-label
         :deadline (org-entry-get nil "DEADLINE")
         :scheduled (org-entry-get nil "SCHEDULED")
         :closed closed
         :closed-days closed-days
         :effort (org-entry-get nil "EFFORT")
         :tags (org-get-tags)
         :category (org-get-category)
         :board board
         :marker marker
         :key (cons (buffer-file-name) (marker-position marker)))))))

(defun jp-kanban--scan ()
  "Scan Org files and return (TASKS . BOARDS).
TASKS is a list of `jp-kanban-task' records and BOARDS is a hash
table of board names."
  (let ((tasks nil)
        (boards (make-hash-table :test 'equal))
        (today (time-to-days (current-time))))
    (dolist (file (jp-kanban--files))
      (with-current-buffer (find-file-noselect file)
        (when (derived-mode-p 'org-mode)
          (org-map-entries
           (lambda ()
             (let* ((state (org-get-todo-state))
                    (explicit-board (jp-kanban--board-at-point t))
                    (board (or explicit-board
                               (and state (jp-kanban--fallback-board)))))
               (when explicit-board
                 (puthash explicit-board t boards))
               (when-let* ((column (jp-kanban--column-for-state state))
                           (task (jp-kanban--task-at-heading board column today)))
                 (when board
                   (puthash board t boards))
                 (push task tasks))))
           nil 'file 'archive 'comment))))
    (dolist (board jp-kanban-extra-boards)
      (when-let* ((name (jp-kanban--normalize-board board)))
        (puthash name t boards)))
    (cons (nreverse tasks) boards)))

(defun jp-kanban--board-names ()
  "Return the sorted list of known board names."
  (let ((data (jp-kanban--scan))
        names)
    (maphash (lambda (name _) (push name names)) (cdr data))
    (when-let* ((default (jp-kanban--normalize-board jp-kanban-default-board)))
      (push default names))
    (sort (delete-dups (delq nil names)) #'string<)))

(defun jp-kanban--read-board (&optional default)
  "Read a board name, using DEFAULT when provided."
  (completing-read
   (format-prompt "Kanban board" default)
   (jp-kanban--board-names)
   nil nil nil 'jp-kanban-board-history default))

(defun jp-kanban--board-states ()
  "Return every TODO state that the board is configured to show."
  (delete-dups (seq-mapcat #'cdr jp-kanban-columns)))

(defun jp-kanban--states-from-keywords (keywords)
  "Return plain state names from KEYWORDS.
KEYWORDS is either `org-todo-keywords-1' (a list of strings) or
`org-todo-keywords' (a list of sequences)."
  (let (states)
    (dolist (entry keywords)
      (dolist (keyword (if (listp entry) (cdr entry) (list entry)))
        (when (and (stringp keyword)
                   (not (string= keyword "|")))
          (let ((state (string-trim
                        (replace-regexp-in-string "[(!@].*\\'" "" keyword))))
            (unless (string-empty-p state)
              (push state states))))))
    (nreverse (delete-dups states))))

(defun jp-kanban--todo-states (&optional marker)
  "Return the board TODO states valid for the task at MARKER.
Org stores the states declared in each file in the buffer-local
variable `org-todo-keywords-1', so asking the task's own buffer keeps
the prompt in sync with the file.  Only states listed in
`jp-kanban-columns' are offered; other keywords are ignored."
  (let* ((buffer (and (markerp marker) (marker-buffer marker)))
         (valid
          (if (buffer-live-p buffer)
              (with-current-buffer buffer
                (jp-kanban--states-from-keywords
                 (or (and (bound-and-true-p org-todo-keywords-1)
                          (copy-sequence org-todo-keywords-1))
                     org-todo-keywords)))
            (jp-kanban--states-from-keywords
             (or (and (bound-and-true-p org-todo-keywords-1)
                      (copy-sequence org-todo-keywords-1))
                 org-todo-keywords)))))
    (seq-filter (lambda (state) (member state valid))
                (jp-kanban--board-states))))

(defun jp-kanban--agenda-states ()
  "Return the states shown by `jp-kanban-agenda'."
  (or jp-kanban-agenda-states
      (seq-mapcat #'cdr
                  (seq-remove #'jp-kanban--done-column-p
                              jp-kanban-columns))))

;;;; Filtering and sorting

(defun jp-kanban--task-on-board-p (task)
  "Return non-nil when TASK belongs to the current board."
  (or (null jp-kanban--board)
      (string= (jp-kanban-task-board task) jp-kanban--board)))

(defun jp-kanban--task-matches-p (task)
  "Return non-nil if TASK is in the current board and passes the filter."
  (and (jp-kanban--task-on-board-p task)
       (or (null jp-kanban--filter)
           (member jp-kanban--filter (jp-kanban-task-tags task)))))

(defun jp-kanban--task-lessp (a b)
  "Return non-nil when task A sorts before task B.
DONE tasks are newest first.  Everything else is ordered by
priority, then deadline, then scheduled date, then title."
  (let ((a-done (string= (jp-kanban-task-column a) jp-kanban-done-column))
        (b-done (string= (jp-kanban-task-column b) jp-kanban-done-column)))
    (if (and a-done b-done)
        (> (or (jp-kanban-task-closed-days a) 0)
           (or (jp-kanban-task-closed-days b) 0))
      (let ((a-priority (or (jp-kanban-task-priority a) 0))
            (b-priority (or (jp-kanban-task-priority b) 0)))
        (cond
         ((/= a-priority b-priority)
          (> a-priority b-priority))
         ((/= (or (jp-kanban--timestamp-days (jp-kanban-task-deadline a)) 999999)
               (or (jp-kanban--timestamp-days (jp-kanban-task-deadline b)) 999999))
          (< (or (jp-kanban--timestamp-days (jp-kanban-task-deadline a)) 999999)
             (or (jp-kanban--timestamp-days (jp-kanban-task-deadline b)) 999999)))
         ((/= (or (jp-kanban--timestamp-days (jp-kanban-task-scheduled a)) 999999)
               (or (jp-kanban--timestamp-days (jp-kanban-task-scheduled b)) 999999))
          (< (or (jp-kanban--timestamp-days (jp-kanban-task-scheduled a)) 999999)
             (or (jp-kanban--timestamp-days (jp-kanban-task-scheduled b)) 999999)))
         (t
          (string< (jp-kanban-task-title a) (jp-kanban-task-title b))))))))

(defun jp-kanban--columns-for-view (tasks)
  "Return (COLUMN . TASKS) for each column, filtered and sorted."
  (mapcar
   (lambda (column)
     (cons column
           (sort (seq-filter (lambda (task)
                               (and (jp-kanban--task-matches-p task)
                                    (string= (jp-kanban-task-column task)
                                             (car column))))
                             tasks)
                 #'jp-kanban--task-lessp)))
   jp-kanban-columns))

;;;; Formatting helpers

(defun jp-kanban--pad (string width)
  "Return STRING truncated or padded to exactly WIDTH columns."
  (let* ((string (or string ""))
         (string (truncate-string-to-width string width 0 nil "…")))
    (concat string
            (make-string (max 0 (- width (string-width string))) ?\s))))

(defun jp-kanban--priority-face (priority)
  "Return the face for PRIORITY label."
  (pcase priority
    ("A" 'jp-kanban-priority-a)
    ("B" 'jp-kanban-priority-b)
    ("C" 'jp-kanban-priority-c)
    (_ 'jp-kanban-column-heading)))

(defun jp-kanban--column-face (label)
  "Return the face for column LABEL."
  (cond
   ((string= label "TODO") 'jp-kanban-column-todo)
   ((string= label "DOING") 'jp-kanban-column-doing)
   ((string= label jp-kanban-done-column) 'jp-kanban-column-done)
   (t 'jp-kanban-column-heading)))

(defun jp-kanban--clocked-p (marker)
  "Return non-nil when MARKER is the heading currently being clocked."
  (and (markerp marker)
       (marker-buffer marker)
       (let ((heading (and (boundp 'org-clock-hd-marker)
                           (markerp org-clock-hd-marker)
                           org-clock-hd-marker))
             (clock (and (boundp 'org-clock-marker)
                         (markerp org-clock-marker)
                         org-clock-marker)))
         (or (and heading
                  (marker-buffer heading)
                  (eq (marker-buffer heading) (marker-buffer marker))
                  (= (marker-position heading) (marker-position marker)))
             ;; Older Org versions may only set `org-clock-marker'.
             (and (null heading)
                  clock
                  (marker-buffer clock)
                  (eq (marker-buffer clock) (marker-buffer marker))
                  (= (marker-position clock) (marker-position marker)))))))

(defun jp-kanban--format-date (timestamp days today)
  "Format TIMESTAMP, given as DAYS and TODAY absolute day numbers."
  (let* ((time (org-time-string-to-time timestamp))
         (delta (- days today))
         (same-year (= (decoded-time-year (decode-time time))
                       (decoded-time-year (decode-time (current-time)))))
         (date (cond
                ((= delta 0) "today")
                ((= delta 1) "tomorrow")
                ((= delta -1) "yesterday")
                (t (format-time-string
                    (if same-year "%b %d" "%Y-%m-%d") time))))
         (clock (format-time-string "%H:%M" time)))
    (if (string= clock "00:00")
        date
      (concat date " " clock))))

(defun jp-kanban--date-part (icon timestamp today &optional deadline-p)
  "Return a propertized date part for TIMESTAMP.
ICON is prepended, TODAY is the current absolute day and DEADLINE-P
controls whether a past date is shown as overdue."
  (when-let* ((days (jp-kanban--timestamp-days timestamp)))
    (let* ((face (cond
                  ((and deadline-p (< days today)) 'jp-kanban-overdue)
                  ((= days today) 'jp-kanban-today)
                  (t 'jp-kanban-date)))
           (text (jp-kanban--format-date timestamp days today)))
      (propertize (format "%s %s" icon text) 'face face))))

(defun jp-kanban--task-title-line (task)
  "Return the title line for TASK."
  (let* ((priority (jp-kanban-task-priority-label task))
         (done-p (string= (jp-kanban-task-column task) jp-kanban-done-column))
         (clocked (jp-kanban--clocked-p (jp-kanban-task-marker task))))
    (concat
     (when priority
       (propertize (format "[#%s] " priority)
                   'face (jp-kanban--priority-face priority)))
     (when clocked
       (propertize "▶ " 'face 'jp-kanban-clock))
     (propertize (jp-kanban-task-title task)
                 'face (if done-p 'jp-kanban-done 'default)))))

(defun jp-kanban--task-meta-line (task)
  "Return the metadata line for TASK."
  (let* ((today (time-to-days (current-time)))
         (board (jp-kanban-task-board task))
         (category (jp-kanban-task-category task))
         (done-p (string= (jp-kanban-task-column task) jp-kanban-done-column))
         (tags (seq-remove
                (lambda (tag)
                  (and (not (string-empty-p jp-kanban-board-tag-prefix))
                       (string-prefix-p jp-kanban-board-tag-prefix tag)))
                (jp-kanban-task-tags task)))
         parts)
    (when (null jp-kanban--board)
      (push (propertize (format "@%s" board) 'face 'jp-kanban-board) parts))
    (unless (string= (jp-kanban-task-state task) (jp-kanban-task-column task))
      (push (propertize (jp-kanban-task-state task) 'face 'jp-kanban-state) parts))
    (when-let* ((part (jp-kanban--date-part "S" (jp-kanban-task-scheduled task) today)))
      (push part parts))
    (when-let* ((part (jp-kanban--date-part "DUE" (jp-kanban-task-deadline task) today t)))
      (push part parts))
    (when-let* ((part (and done-p
                          (jp-kanban--date-part "✓" (jp-kanban-task-closed task) today))))
      (push part parts))
    (when-let* ((effort (jp-kanban-task-effort task)))
      (push (propertize (format "eff %s" effort) 'face 'jp-kanban-meta) parts))
    (when (and jp-kanban-show-category
               category
               (not (string-empty-p category))
               (not (string= (downcase category) board)))
      (push (propertize category 'face 'jp-kanban-meta) parts))
    (when (and jp-kanban-show-tags tags)
      (push (propertize
             (format ":%s:" (mapconcat #'identity (seq-take tags 2) ":"))
             'face 'jp-kanban-meta)
            parts))
    (mapconcat #'identity (nreverse parts) " · ")))

(defun jp-kanban--task-help (task)
  "Return the help-echo string for TASK."
  (let ((file (and (marker-buffer (jp-kanban-task-marker task))
                   (buffer-file-name (marker-buffer (jp-kanban-task-marker task))))))
    (concat (jp-kanban-task-title task)
            (when file (format "\n%s" file))
            "\n\nRET opens · s starts · x completes · m changes state")))

;;;; Rendering

(defun jp-kanban--column-width (columns)
  "Return the width of each column, given the number of COLUMNS."
  (let* ((window (or (get-buffer-window (current-buffer)) (selected-window)))
         (total (max 60 (window-body-width window)))
         (separators (* (1- columns) 3)))
    (max 12 (/ (- total separators) columns))))

(defun jp-kanban--insert-row (cells width)
  "Insert a row made of CELLS, each one a (TEXT TASK) list."
  (let ((line-start (point))
        (has-task nil))
    (dotimes (i (length cells))
      (let* ((cell (nth i cells))
             (text (nth 0 cell))
             (task (nth 1 cell))
             (start (point)))
        (insert (jp-kanban--pad text width))
        (when task
          (setq has-task t)
          (add-text-properties
           start (point)
           (list 'jp-kanban-task t
                 'jp-kanban-marker (jp-kanban-task-marker task)
                 'jp-kanban-key (jp-kanban-task-key task)
                 'jp-kanban-state (jp-kanban-task-state task)
                 'jp-kanban-board (jp-kanban-task-board task)
                 'mouse-face 'highlight
                 'keymap jp-kanban-cell-map
                 'help-echo (jp-kanban--task-help task))))
        (when (< i (1- (length cells)))
          (insert " │ "))))
    (when has-task
      (add-text-properties line-start (line-end-position) '(jp-kanban-line t)))
    (insert "\n")))

(defun jp-kanban--insert-separator (columns width)
  "Insert a horizontal separator for COLUMNS columns of WIDTH."
  (let ((parts (make-list columns (make-string width ?─))))
    (insert (propertize (mapconcat #'identity parts "─┼─")
                        'face 'jp-kanban-separator)
            "\n")))

(defun jp-kanban--render ()
  "Render the current board buffer from Org data."
  (let* ((inhibit-read-only t)
         (data (jp-kanban--scan))
         (tasks (car data))
         (columns (jp-kanban--columns-for-view tasks))
         (width (jp-kanban--column-width (length columns)))
         (total (seq-reduce (lambda (acc entry) (+ acc (length (cdr entry))))
                            columns 0)))
    (erase-buffer)
    (setq-local jp-kanban--counts
                (mapcar (lambda (entry)
                          (cons (car (car entry)) (length (cdr entry))))
                        columns))
    (setq-local jp-kanban--task-list (seq-mapcat #'cdr columns))
    (jp-kanban--insert-row
     (mapcar (lambda (entry)
               (let ((label (car (car entry))))
                 (list (propertize (format "%s (%d)" label (length (cdr entry)))
                                   'face (jp-kanban--column-face label))
                       nil)))
             columns)
     width)
    (jp-kanban--insert-separator (length columns) width)
    (let ((rows (apply #'max (mapcar (lambda (entry)
                                       (length (cdr entry)))
                                     columns))))
      (dotimes (i rows)
        (jp-kanban--insert-row
         (mapcar (lambda (entry)
                   (let ((task (nth i (cdr entry))))
                     (if task
                         (list (jp-kanban--task-title-line task) task)
                       (list "" nil))))
                 columns)
         width)
        (jp-kanban--insert-row
         (mapcar (lambda (entry)
                   (let ((task (nth i (cdr entry))))
                     (if task
                         (list (jp-kanban--task-meta-line task) task)
                       (list "" nil))))
                 columns)
         width)))
    (when (= total 0)
      (insert (propertize
               (format "\nNo tasks in %s.\n"
                       (if jp-kanban--board
                           (format "the \"%s\" board" jp-kanban--board)
                         "any board"))
               'face 'jp-kanban-meta)))
    (goto-char (point-min))
    (set-buffer-modified-p nil)))

(defun jp-kanban--header-line ()
  "Return the header line for the current Kanban buffer."
  (let* ((counts (or jp-kanban--counts nil))
         (total (seq-reduce (lambda (acc pair) (+ acc (cdr pair))) counts 0))
         (done (or (cdr (assoc jp-kanban-done-column counts)) 0))
         (percent (if (> total 0) (round (* 100.0 (/ (float done) total))) 0)))
    (concat
     (propertize " Kanban " 'face 'jp-kanban-header-title)
     (propertize (or jp-kanban--board "all boards")
                 'face 'jp-kanban-header-board)
     "  "
     (propertize
      (mapconcat (lambda (pair) (format "%s %d" (car pair) (cdr pair)))
                 counts "  ")
      'face 'jp-kanban-header-counts)
     (propertize (format "  %d%%" percent) 'face 'jp-kanban-header-counts)
     (when jp-kanban--filter
       (propertize (format "  filter:%s" jp-kanban--filter)
                   'face 'jp-kanban-filter))
     (when (and (boundp 'org-clock-current-task)
                org-clock-current-task)
       (propertize (format "  ▶ %s"
                           (truncate-string-to-width org-clock-current-task
                                                     28 nil nil "…"))
                   'face 'jp-kanban-clock)))))

(defun jp-kanban--marker-key (marker)
  "Return the stable key for MARKER."
  (when (and (markerp marker) (marker-buffer marker))
    (cons (buffer-file-name (marker-buffer marker))
          (marker-position marker))))

(defun jp-kanban--task-at-point ()
  "Return the task marker at point, or on the current line."
  (or (get-text-property (point) 'jp-kanban-marker)
      (let ((pos (line-beginning-position))
            (end (line-end-position))
            marker)
        (while (and (< pos end) (not marker))
          (setq marker (get-text-property pos 'jp-kanban-marker))
          (unless marker
            (setq pos (next-single-property-change
                       pos 'jp-kanban-marker nil end))))
        marker)))

(defun jp-kanban--task-key-at-point ()
  "Return the stable key of the task at point."
  (jp-kanban--marker-key (jp-kanban--task-at-point)))

(defun jp-kanban--goto-key (key)
  "Move to the task identified by KEY.  Return non-nil when found."
  (when key
    (goto-char (point-min))
    (let ((match (text-property-search-forward 'jp-kanban-key key #'equal)))
      (when match
        (goto-char (prop-match-beginning match))
        t))))

(defun jp-kanban--goto-first-task ()
  "Move to the first task line, if there is one."
  (goto-char (point-min))
  (unless (get-text-property (line-beginning-position) 'jp-kanban-line)
    (jp-kanban-next-task)))

(defun jp-kanban-refresh (&optional keep-key)
  "Refresh the current Kanban buffer.
KEEP-KEY is the task key to keep under point."
  (interactive)
  (let ((key (or keep-key (jp-kanban--task-key-at-point))))
    (jp-kanban--render)
    (unless (jp-kanban--goto-key key)
      (jp-kanban--goto-first-task))))

(defun jp-kanban--revert (&rest _)
  "Revert function for `jp-kanban-mode'."
  (jp-kanban-refresh))

;;;; Navigation

(defun jp-kanban--task-line-p ()
  "Return non-nil when the current line contains a task."
  (get-text-property (line-beginning-position) 'jp-kanban-line))

(defun jp-kanban-next-task (&optional count)
  "Move to the next task, COUNT times."
  (interactive "p")
  (dotimes (_ (or count 1))
    (let ((start (point)))
      (forward-line 1)
      (while (and (not (eobp)) (not (jp-kanban--task-line-p)))
        (forward-line 1))
      (when (eobp)
        (goto-char start)))))

(defun jp-kanban-previous-task (&optional count)
  "Move to the previous task, COUNT times."
  (interactive "p")
  (dotimes (_ (or count 1))
    (let ((start (point)))
      (forward-line -1)
      (while (and (not (bobp)) (not (jp-kanban--task-line-p)))
        (forward-line -1))
      (when (bobp)
        (goto-char start)))))

(defun jp-kanban-open-task ()
  "Open the task at point in its Org file."
  (interactive)
  (let* ((marker (jp-kanban--task-at-point))
         (buffer (and marker (marker-buffer marker))))
    (unless buffer
      (user-error "No task at point"))
    (pop-to-buffer buffer
                   (when jp-kanban-full-frame
                     '(display-buffer-full-frame)))
    (goto-char marker)
    (org-fold-show-context)
    (recenter)))

(defun jp-kanban-mouse-open (event)
  "Open the task clicked on in EVENT."
  (interactive "e")
  (goto-char (posn-point (event-start event)))
  (jp-kanban-open-task))

;;;; Card editing commands

(defun jp-kanban--apply-to-task (function)
  "Call FUNCTION at the task at point, then save and refresh.
FUNCTION runs with the Org buffer current and point on the heading."
  (let* ((marker (jp-kanban--task-at-point))
         (key (and marker (jp-kanban--marker-key marker))))
    (unless marker
      (user-error "No task at point"))
    (with-current-buffer (marker-buffer marker)
      (org-with-point-at marker
        (funcall function)))
    (when jp-kanban-save-on-change
      (with-current-buffer (marker-buffer marker)
        (when (buffer-modified-p)
          (save-buffer))))
    (jp-kanban-refresh key)))

(defun jp-kanban-set-state (state)
  "Set the task at point to STATE."
  (interactive
   (let ((marker (jp-kanban--task-at-point)))
     (list (completing-read
            "TODO state: "
            (jp-kanban--todo-states marker)
            nil t nil nil
            (get-text-property (point) 'jp-kanban-state)))))
  (jp-kanban--apply-to-task (lambda () (org-todo state))))

(defun jp-kanban-start-task ()
  "Mark the task at point as `jp-kanban-start-state'."
  (interactive)
  (jp-kanban--apply-to-task (lambda () (org-todo jp-kanban-start-state))))

(defun jp-kanban-complete-task ()
  "Mark the task at point as `jp-kanban-done-state'."
  (interactive)
  (jp-kanban--apply-to-task (lambda () (org-todo jp-kanban-done-state))))

(defun jp-kanban-reopen-task ()
  "Reopen the task at point as `jp-kanban-reopen-state'."
  (interactive)
  (jp-kanban--apply-to-task (lambda () (org-todo jp-kanban-reopen-state))))

(defun jp-kanban-edit-title ()
  "Edit the title of the task at point."
  (interactive)
  (jp-kanban--apply-to-task
   (lambda () (call-interactively #'org-edit-headline))))

(defun jp-kanban-set-priority ()
  "Set the priority of the task at point."
  (interactive)
  (jp-kanban--apply-to-task
   (lambda () (call-interactively #'org-priority))))

(defun jp-kanban-set-deadline ()
  "Set the DEADLINE of the task at point."
  (interactive)
  (jp-kanban--apply-to-task
   (lambda () (call-interactively #'org-deadline))))

(defun jp-kanban-set-scheduled ()
  "Set the SCHEDULED date of the task at point."
  (interactive)
  (jp-kanban--apply-to-task
   (lambda () (call-interactively #'org-schedule))))

(defun jp-kanban-move-to-board (board)
  "Move the task at point to BOARD."
  (interactive
   (list (jp-kanban--read-board
          (and (derived-mode-p 'jp-kanban-mode) jp-kanban--board))))
  (let ((board (jp-kanban--normalize-board board)))
    (jp-kanban--apply-to-task
     (lambda () (org-entry-put nil jp-kanban-board-property board)))
    (message "Task moved to board \"%s\"" board)))

(defun jp-kanban-set-board (board)
  "Set the board of the Org heading at point to BOARD."
  (interactive
   (list (jp-kanban--read-board
          (and (derived-mode-p 'org-mode) (jp-kanban--board-at-point)))))
  (unless (derived-mode-p 'org-mode)
    (user-error "Not an Org buffer"))
  (let ((board (jp-kanban--normalize-board board)))
    (org-entry-put nil jp-kanban-board-property board)
    (when (and jp-kanban-save-on-change (buffer-modified-p))
      (save-buffer))
    (message "Board set to \"%s\"" board)))

(defun jp-kanban-clock-in ()
  "Clock in the task at point."
  (interactive)
  (jp-kanban--apply-to-task (lambda () (org-clock-in))))

(defun jp-kanban-clock-out ()
  "Clock out the current Org clock."
  (interactive)
  (org-clock-out)
  (jp-kanban-refresh))

(defun jp-kanban-filter-tag (tag)
  "Show only cards tagged TAG."
  (interactive
   (list (completing-read
          "Filter by tag: "
          (sort (delete-dups
                 (seq-mapcat #'jp-kanban-task-tags
                             (seq-filter #'jp-kanban--task-on-board-p
                                         (car (jp-kanban--scan)))))
                #'string<)
          nil t nil 'jp-kanban-tag-history jp-kanban--filter)))
  (setq-local jp-kanban--filter (unless (string-empty-p tag) tag))
  (jp-kanban-refresh))

(defun jp-kanban-clear-filter ()
  "Remove the tag filter from the current board."
  (interactive)
  (setq-local jp-kanban--filter nil)
  (jp-kanban-refresh))

;;;; Opening and switching boards

(defun jp-kanban--display (board)
  "Display the Kanban buffer for BOARD, or all boards when nil."
  (let ((buffer (get-buffer-create
                 (format "*Kanban: %s*" (or board "all")))))
    (with-current-buffer buffer
      (unless (derived-mode-p 'jp-kanban-mode)
        (jp-kanban-mode))
      (setq-local jp-kanban--board board)
      (when board
        (setq jp-kanban-last-board board)))
    (pop-to-buffer buffer
                   (when jp-kanban-full-frame
                     '(display-buffer-full-frame)))
    (with-current-buffer buffer
      (jp-kanban-refresh))))

(defun jp-kanban-open (&optional board)
  "Open a Kanban board.
With no prefix argument, prompt for BOARD.  With a prefix argument,
show the all-boards view."
  (interactive
   (list (unless current-prefix-arg
           (jp-kanban--read-board
            (or (and (derived-mode-p 'org-mode)
                     (jp-kanban--board-at-point))
                jp-kanban-last-board)))))
  (jp-kanban--display board))

(defun jp-kanban-switch-board ()
  "Switch the current Kanban buffer to another board."
  (interactive)
  (jp-kanban--display
   (jp-kanban--read-board (or jp-kanban--board jp-kanban-last-board))))

(defun jp-kanban-add-task (title board &optional deadline)
  "Create a TODO card TITLE in BOARD.
With a prefix argument, also prompt for DEADLINE."
  (interactive
   (let* ((default (and (derived-mode-p 'jp-kanban-mode)
                        jp-kanban--board))
          (board (jp-kanban--normalize-board
                  (jp-kanban--read-board (or default jp-kanban-last-board))))
          (title (read-string "New task: ")))
     (list title board
           (when current-prefix-arg
             (org-read-date nil t nil "Deadline: ")))))
  (let* ((file (expand-file-name
                (or (cdr (assoc-string board jp-kanban-board-files t))
                    jp-kanban-inbox-file)))
         (buffer (find-file-noselect file)))
    (with-current-buffer buffer
      (org-with-wide-buffer
        (goto-char (point-min))
        (let ((level 1))
          (if (and jp-kanban-inbox-heading
                   (re-search-forward
                    (format "^\\*+[ \t]+%s[ \t]*$"
                            (regexp-quote jp-kanban-inbox-heading))
                    nil t))
              (progn
                (setq level (1+ (org-outline-level)))
                (goto-char (match-end 0))
                (org-end-of-subtree t t)
                (unless (bolp) (insert "\n")))
            (goto-char (point-max))
            (unless (bolp) (insert "\n"))
            (when jp-kanban-inbox-heading
              (insert "* " jp-kanban-inbox-heading "\n")
              (setq level 2)))
          (insert (make-string level ?*) " TODO " title "\n")
          (when deadline
            (insert (format "DEADLINE: <%s>\n"
                            (format-time-string "%Y-%m-%d %a" deadline))))
          (insert ":PROPERTIES:\n:"
                  jp-kanban-board-property ": " board "\n:END:\n"))
        (save-buffer)))
    (when (derived-mode-p 'jp-kanban-mode)
      (jp-kanban-refresh))
    (message "Added \"%s\" to board \"%s\" in %s"
             title board (file-name-nondirectory file))))

;;;; Org agenda integration

(defun jp-kanban--agenda-skip ()
  "Skip agenda entries that are not in `jp-kanban--agenda-board'."
  (unless (or (null jp-kanban--agenda-board)
              (string= (jp-kanban--board-at-point) jp-kanban--agenda-board))
    (save-excursion
      (org-end-of-subtree t t)
      (point))))

(defun jp-kanban-agenda (&optional board)
  "Show an Org agenda restricted to BOARD.
With a prefix argument, show every board."
  (interactive
   (list (unless current-prefix-arg
           (jp-kanban--read-board
            (and (derived-mode-p 'jp-kanban-mode) jp-kanban--board)))))
  (require 'org-agenda)
  (let* ((jp-kanban--agenda-board board)
         (org-agenda-files (jp-kanban--files))
         (title (if board
                    (format "Kanban: %s" board)
                  "Kanban: all boards"))
         (states (jp-kanban--agenda-states))
         (org-agenda-custom-commands
          `(("K" ,title
             ((todo ,(mapconcat #'identity states "|")
                    ((org-agenda-overriding-header ,title)
                     (org-agenda-skip-function #'jp-kanban--agenda-skip)
                     (org-agenda-sorting-strategy
                      '(priority-down deadline-up)))))))))
    (org-agenda nil "K")))

;;;; Mode and key bindings

(defvar jp-kanban-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "n") #'jp-kanban-next-task)
    (define-key map (kbd "p") #'jp-kanban-previous-task)
    (define-key map (kbd "j") #'jp-kanban-next-task)
    (define-key map (kbd "k") #'jp-kanban-previous-task)
    (define-key map (kbd "RET") #'jp-kanban-open-task)
    (define-key map (kbd "o") #'jp-kanban-open-task)
    (define-key map (kbd "s") #'jp-kanban-start-task)
    (define-key map (kbd "x") #'jp-kanban-complete-task)
    (define-key map (kbd "r") #'jp-kanban-reopen-task)
    (define-key map (kbd "m") #'jp-kanban-set-state)
    (define-key map (kbd "a") #'jp-kanban-add-task)
    (define-key map (kbd "e") #'jp-kanban-edit-title)
    (define-key map (kbd "P") #'jp-kanban-set-priority)
    (define-key map (kbd "D") #'jp-kanban-set-deadline)
    (define-key map (kbd "S") #'jp-kanban-set-scheduled)
    (define-key map (kbd "B") #'jp-kanban-move-to-board)
    (define-key map (kbd "f") #'jp-kanban-filter-tag)
    (define-key map (kbd "F") #'jp-kanban-clear-filter)
    (define-key map (kbd "i") #'jp-kanban-clock-in)
    (define-key map (kbd "O") #'jp-kanban-clock-out)
    (define-key map (kbd "b") #'jp-kanban-switch-board)
    (define-key map (kbd "A") #'jp-kanban-agenda)
    (define-key map (kbd "g") #'jp-kanban-refresh)
    (define-key map (kbd "q") #'quit-window)
    (define-key map (kbd "?") #'describe-mode)
    map)
  "Keymap for `jp-kanban-mode'.")

(define-derived-mode jp-kanban-mode special-mode "Kanban"
  "Major mode for viewing Org tasks as a Kanban board.
\\{jp-kanban-mode-map}"
  (setq-local truncate-lines t)
  (setq-local word-wrap nil)
  (setq-local header-line-format '(:eval (jp-kanban--header-line)))
  (setq-local revert-buffer-function #'jp-kanban--revert)
  (setq-local jp-kanban--board nil)
  (setq-local jp-kanban--filter nil)
  (setq-local jp-kanban--counts nil)
  (setq-local jp-kanban--task-list nil)
  (hl-line-mode 1)
  (jp-kanban-refresh))

(with-eval-after-load 'evil
  (evil-set-initial-state 'jp-kanban-mode 'normal)
  (evil-define-key 'normal jp-kanban-mode-map
    (kbd "n") #'jp-kanban-next-task
    (kbd "p") #'jp-kanban-previous-task
    (kbd "j") #'jp-kanban-next-task
    (kbd "k") #'jp-kanban-previous-task
    (kbd "RET") #'jp-kanban-open-task
    (kbd "o") #'jp-kanban-open-task
    (kbd "s") #'jp-kanban-start-task
    (kbd "x") #'jp-kanban-complete-task
    (kbd "r") #'jp-kanban-reopen-task
    (kbd "m") #'jp-kanban-set-state
    (kbd "a") #'jp-kanban-add-task
    (kbd "e") #'jp-kanban-edit-title
    (kbd "P") #'jp-kanban-set-priority
    (kbd "D") #'jp-kanban-set-deadline
    (kbd "S") #'jp-kanban-set-scheduled
    (kbd "B") #'jp-kanban-move-to-board
    (kbd "f") #'jp-kanban-filter-tag
    (kbd "F") #'jp-kanban-clear-filter
    (kbd "i") #'jp-kanban-clock-in
    (kbd "O") #'jp-kanban-clock-out
    (kbd "b") #'jp-kanban-switch-board
    (kbd "A") #'jp-kanban-agenda
    (kbd "g") #'jp-kanban-refresh
    (kbd "q") #'quit-window
    (kbd "?") #'describe-mode))

(defun jp-kanban--refresh-visible-buffers ()
  "Refresh every visible Kanban buffer."
  (dolist (window (window-list nil 'nomini))
    (with-current-buffer (window-buffer window)
      (when (derived-mode-p 'jp-kanban-mode)
        (jp-kanban-refresh)))))

(defun jp-kanban--window-size-change (&rest _)
  "Schedule a refresh of visible Kanban buffers after a resize."
  (when (timerp jp-kanban--resize-timer)
    (cancel-timer jp-kanban--resize-timer))
  (setq jp-kanban--resize-timer
        (run-with-idle-timer 0.3 nil
                             #'jp-kanban--refresh-visible-buffers)))

(add-hook 'window-size-change-functions #'jp-kanban--window-size-change)

(defvar savehist-additional-variables)

(with-eval-after-load 'savehist
  (add-to-list 'savehist-additional-variables 'jp-kanban-last-board)
  (add-to-list 'savehist-additional-variables 'jp-kanban-board-history))

(provide 'emacs-jp-kanban)

;;; emacs-jp-kanban.el ends here
