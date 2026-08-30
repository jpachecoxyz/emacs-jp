;;; jp-org.el --- Tweaks for my org-mode configurations -*- lexical-binding: t -*-

;;; Commentary:
;;
;; This covers my tweaks for Org that are meant for use in my
;; Emacs setup: https://jpachecoxyz.github.io.

;;; Code:

(require 'jp-common)
(require 'org)

(defgroup jp-org ()
  "Extensions for org.el."
  :group 'org)

;;;; org-capture

(declare-function cl-letf "cl-lib")

;; Adapted from source: <https://stackoverflow.com/a/54251825>.
;;
;; Thanks to Juanjo Presa (@uningan on GitHub) for discovering that the
;; original version was causing an error in `org-roam'.  I then figure
;; we were missing the `&rest':
;; <https://github.com/org-roam/org-roam/issues/2142#issuecomment-1100718373>.
(defun jp-org--capture-no-delete-windows (&rest args)
  "Apply ARGS while ignoring `delete-other-windows'."
  (cl-letf (((symbol-function 'delete-other-windows) 'ignore))
    (apply args)))

;; Same source as above
(advice-add 'org-capture-place-template :around 'jp-org--capture-no-delete-windows)
(advice-add 'org-add-log-note :around 'jp-org--capture-no-delete-windows)

;;;;; Custom function to select a project to add to

(defun jp-org--get-outline (&optional file)
  "Return `outline-regexp' headings and line numbers of current file or FILE."
  (with-current-buffer (find-file-noselect file)
    (let ((outline-regexp (format "^\\(?:%s\\)" (or (bound-and-true-p outline-regexp) "[*\^L]+")))
          candidates)
      (save-excursion
        (goto-char (point-min))
        (while (if (bound-and-true-p outline-search-function)
                   (funcall outline-search-function)
                 (re-search-forward outline-regexp nil t))
          (push
           ;; NOTE 2024-11-24: The -5 (minimum width) is a sufficiently high number to keep the
           ;; alignment consistent in most cases.  Larger files will simply shift the heading text
           ;; in minibuffer, but this is not an issue anymore.
           (format "%-5s\t%s"
                   (line-number-at-pos (point))
                   (buffer-substring-no-properties (line-beginning-position) (line-end-position)))
           candidates)
          (goto-char (1+ (line-end-position)))))
      (if candidates
          (nreverse candidates)
        (user-error "No outline")))))

(defvar jp-org-outline-history nil
  "Minibuffer history for `jp-org-outline-prompt'.")

(defun jp-org-outline-prompt (&optional file)
  "Prompt for outline among headings retrieved by `jp-org--get-outline'.
With optional FILE use the outline of it, otherwise use that of
the current file."
  (let ((current-file (or file buffer-file-name))
        (default (car jp-org-outline-history)))
    (completing-read
     (format-prompt
      (format "Select heading inside `%s': "
              (propertize (file-name-nondirectory current-file) 'face 'error))
      default)
     (jp-common-completion-table-no-sort 'imenu (jp-org--get-outline current-file))
     nil :require-match nil 'jp-org-outline-history default)))

(defvar jp-org-file-history nil
  "Minibuffer history of `jp-org-file-prompt'.")

(defun jp-org--not-useful-p (file)
  "Return non-nil if FILE is not a useful Org file for `org-capture'."
  (or (string-match-p "\\.org_archive\\'" file)
      (backup-file-name-p file)
      (not (string-match-p "\\.org\\'" file))))

(defun jp-org-file-prompt ()
  "Select a file in the `org-directory'."
  (if-let* ((dir org-directory)
            (files (directory-files-recursively org-directory ".*" nil))
            (files (seq-remove #'jp-org--not-useful-p files)))
      (let ((default (car jp-org-file-history)))
        (completing-read
         (format-prompt "Select file" default)
         (jp-common-completion-table 'file files)
         nil :require-match nil 'jp-org-file-history default))
    (user-error "There are no files in the `org-directory'")))

;;;###autoload
(defun jp-org-select-heading-in-file ()
  "Move to heading in Org file stored in `org-directory'.
Prompt for file, then for heading inside of that file.

This function can also be used as part of an `org-capture' template to
navigate to a file+heading and then capture something which is inserted
there."
  (declare (interactive-only t))
  (interactive)
  (pcase-let* ((file (jp-org-file-prompt))
               (line-with-heading (jp-org-outline-prompt file))
               (`(,line ,text) (split-string line-with-heading "\t"))
               (line (string-to-number line)))
    ;; NOTE 2024-11-24: `with-current-buffer' does not work with `org-capture'.
    (find-file file)
    (goto-char (point-min))
    (forward-line (1- line))))

(defalias 'jp-org-goto-heading-in-file 'jp-org-select-heading-in-file
 "Alias for `jp-org-select-heading-in-file'.")

;;;; Org clock report

(defvar jp-org-clock--template-with-effort
  "#+BEGIN: clocktable :formula % :properties (\"Effort\") :timestamp t :sort (1 . ?a) :link t :scope nil :hidefiles t :maxlevel 8 :stepskip0 t
#+END:"
  "Clock table with effort estimate column to use for custom clock reports.")

(defvar jp-org-clock--template-no-effort
  "#+BEGIN: clocktable :formula % :timestamp t :sort (1 . ?a) :link nil :scope nil :hidefiles t :maxlevel 8 :stepskip0 t
#+END:"
  "Clock table to use for custom clock reports.")

(defvar jp-org-clock--ranges
  '( today yesterday thisweek lastweek thismonth
     lastmonth thisyear lastyear untilnow)
  "Time ranges of my interest for clock reports.")

(defvar jp-org-clock--report-range-history nil
  "Minibuffer history for `jp-org-clock--report-range-prompt'.")

(defun jp-org-clock--report-range-prompt ()
  "Prompt for a clock table range among `jp-org-clock--ranges'."
  (let ((default (car jp-org-clock--report-range-history)))
    (completing-read
     (format-prompt "Select a time range for the clock" default)
     jp-org-clock--ranges nil :require-match nil 'jp-org-clock--report-range-history
     default)))

(defun jp-org-clock--get-report (scope)
  "Produce clock report with current file SCOPE and return its buffer.
SCOPE is a symbol of either `file' or `subtree'.  If the former, then
use the entire file's contents.  Else use those of the current subtree."
  (let ((buffer (get-buffer-create "*jp-org-custom-clock-report*")))
    (save-restriction
      (unwind-protect
          (progn
            (pcase scope
              ('file nil)
              ('subtree (org-narrow-to-subtree))
              (_ (error "The scope `%s' is unknown" scope)))
            (let ((contents (buffer-substring (point-min) (point-max))))
              (with-current-buffer buffer
                (erase-buffer)
                (org-mode)
                (save-excursion
                  (insert (format "%s\n\n" jp-org-clock--template-with-effort))
                  (insert contents))
                (save-excursion
                  (let ((range (jp-org-clock--report-range-prompt)))
                    (goto-char (line-end-position))
                    (insert (concat " :block " range))))
                (org-dblock-update))))
        (widen)))
    buffer))

;;;###autoload
(defun jp-org-clock-report-current-subtree-or-file (&optional whole-buffer)
  "Produce a clock report in a new buffer for the subtree at point.
With optional WHOLE-BUFFER as a non-nil value, operate on the entire file.
When called interactively WHOLE-BUFFER is a prefix argument."
  (interactive "P")
  (when-let* ((buffer (jp-org-clock--get-report (if whole-buffer 'file 'subtree))))
    (pop-to-buffer buffer)))

;;;###autoload
(defun jp-org-clock-select-heading-and-clock-report ()
  "Select a heading in a file and do a clock report for it in a new buffer."
  (interactive)
  (call-interactively 'jp-org-select-heading-in-file)
  (call-interactively 'jp-org-clock-report-current-subtree-or-file))

;;;;; Coaching-related Org custom clocking

;; TODO 2024-12-15: This sort of thing must exist in Org, but I did
;; not find it.
(defun jp-org--timestamp-to-time (string)
  "Return time object of STRING timestamp."
  (org-timestamp-to-time (org-timestamp-from-string string)))

(defun jp-org-coach--get-entries (todo-keyword string since)
  "Get Org entries matching TODO-KEYWORD followed by STRING in the heading.
Limit entries to those whole deadline/scheduled is equal or greater to
SINCE date.

Each entry is a plist of :heading, :contents, :started, :closed."
  (or (delq nil
            (org-map-entries
             (lambda ()
               (when-let* ((case-fold-search t)
                           (started (jp-org--timestamp-to-time (or (org-entry-get nil "DEADLINE") (org-entry-get nil "SCHEDULED"))))
                           (closed (jp-org--timestamp-to-time (org-entry-get nil "CLOSED")))
                           ((re-search-forward (format "\\<%s\\>.*\\<%s\\>" todo-keyword string) (line-end-position) t 1))
                           ((org-time-less-p since started)))
                 (list
                  :heading (org-get-heading :no-tags :no-todo :no-priority :no-comment)
                  :contents (org-get-entry)
                  :started started
                  :closed closed)))))
      (user-error "No entries with heading matching `\\<%s\\>.*\\<%s\\>'" todo-keyword string)))

(defvar jp-org-coach--name-history nil
  "Minibuffer history of `jp-org-coach--name-prompt'.")

(defun jp-org-coach--name-prompt ()
  "Prompt for name of person."
  (let ((default (car jp-org-coach--name-history)))
    (read-string
     (format-prompt "Name of person" default)
     nil 'jp-org-coach--name-history default)))

;;;###autoload
(defun jp-org-coach-report (name since)
  "Produce clock report for coaching with person of NAME.
SINCE is the date (of time 00:00) to count from until now."
  (interactive
   (list
    (jp-org-coach--name-prompt)
    (format "[%s]" (org-read-date))))
  (if-let* ((since-object (jp-org--timestamp-to-time since))
            (entries (jp-org-coach--get-entries "done" name since-object))
            (buffer (get-buffer-create "*jp-org-coach-entries*")))
      (with-current-buffer (pop-to-buffer buffer)
        (erase-buffer)
        (org-mode)
        (dolist (entry entries)
          (insert (format "* %s\n%s\n\n" (plist-get entry :heading) (plist-get entry :contents)))
          (org-clock-in nil (plist-get entry :started))
          (org-clock-out nil t (plist-get entry :closed)))
        (goto-char (point-min))
        (save-excursion
          (insert (format "%s\n\n" jp-org-clock--template-no-effort)))
        (save-excursion
          (goto-char (line-end-position))
          (insert (format " :tstart %S" since)))
        (org-dblock-update))
    (user-error "No entries for name `%s'" name)))

;;;; org-agenda

(declare-function calendar-day-name "calendar")
(declare-function calendar-day-of-week "calendar")
(declare-function calendar-month-name "calendar")
(declare-function org-days-to-iso-week "org")
(declare-function calendar-absolute-from-gregorian "calendar")

(defvar org-agenda-format-date)

;;;###autoload
(defun jp-org-agenda-format-date-aligned (date)
  "Format a DATE string for display in the daily/weekly agenda.
This function makes sure that dates are aligned for easy reading.

Slightly tweaked version of `org-agenda-format-date-aligned' that
produces dates with a fixed length."
  (require 'cal-iso)
  (let* ((dayname (calendar-day-name date t))
         (day (cadr date))
         (day-of-week (calendar-day-of-week date))
         (month (car date))
         (monthname (calendar-month-name month t))
         (year (nth 2 date))
         (iso-week (org-days-to-iso-week
                    (calendar-absolute-from-gregorian date)))
         ;; (weekyear (cond ((and (= month 1) (>= iso-week 52))
         ;;                  (1- year))
         ;;                 ((and (= month 12) (<= iso-week 1))
         ;;                  (1+ year))
         ;;                 (t year)))
         (weekstring (if (= day-of-week 1)
                         (format " (W%02d)" iso-week)
                       "")))
    (format "%s %2d %s %4d%s"
            dayname day monthname year weekstring)))

(defvar org-priority-highest)

(defun jp-org-agenda-include-priority-no-timestamp ()
  "Return nil if heading has a priority but no timestamp.
Otherwise, return the buffer position from where the search should
continue, per `org-agenda-skip-function'."
  (let ((point (point)))
    (if (and (eq (nth 3 (org-heading-components)) ?A)
             (not (org-get-deadline-time point))
             (not (org-get-scheduled-time point)))
        nil
      (line-beginning-position 2))))

(defvar jp-org-custom-daily-agenda
  ;; NOTE 2021-12-08: Specifying a match like the following does not
  ;; work.
  ;;
  ;; tags-todo "+PRIORITY=\"A\""
  ;;
  ;; So we match everything and then skip entries with
  ;; `org-agenda-skip-function'.
  `((tags-todo "*"
               ((org-agenda-overriding-header "Important tasks without a date\n")
                ;; NOTE 2024-10-31: Those used to work, but now the
                ;; query for the timestamp is ignored.  I thus wrote
                ;; `jp-org-agenda-include-priority-no-timestamp'.
                ;;
                ;; (org-agenda-skip-function '(org-agenda-skip-subtree-if nil '(timestamp)))
                ;; (org-agenda-skip-function
                ;;  `(org-agenda-skip-entry-if
                ;;    'notregexp ,(format "\\[#%s\\]" (char-to-string org-priority-highest))))
                (org-agenda-skip-function #'jp-org-agenda-include-priority-no-timestamp)
                (org-agenda-block-separator nil)))
    (agenda "" ((org-agenda-overriding-header "\nPending scheduled tasks")
                (org-agenda-time-grid nil)
                (org-agenda-start-on-weekday nil)
                (org-agenda-span 1)
                (org-agenda-show-all-dates nil)
                (org-scheduled-past-days 365)
                ;; Excludes today's scheduled items
                (org-scheduled-delay-days 1)
                (org-agenda-block-separator nil)
                (org-agenda-entry-types '(:scheduled))
                (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                (org-agenda-skip-function '(org-agenda-skip-entry-if 'regexp "ROUTINE"))
                (org-agenda-day-face-function (lambda (date) 'org-agenda-date))
                (org-agenda-format-date "")))
    (agenda "" ((org-agenda-overriding-header "\nToday's agenda\n")
                (org-agenda-span 1)
                (org-deadline-warning-days 0)
                (org-agenda-block-separator nil)
                (org-scheduled-past-days 0)
                (org-agenda-skip-function '(org-agenda-skip-entry-if 'regexp "ROUTINE"))
                ;; We don't need the `org-agenda-date-today'
                ;; highlight because that only has a practical
                ;; utility in multi-day views.
                (org-agenda-day-face-function (lambda (date) 'org-agenda-date))
                (org-agenda-format-date "%A %-e %B %Y")))
    ;; (agenda "" ((org-agenda-overriding-header "\nRoutine")
    ;;             (org-agenda-time-grid nil)
    ;;             (org-agenda-start-on-weekday nil)
    ;;             (org-agenda-span 1)
    ;;             (org-agenda-show-all-dates nil)
    ;;             (org-scheduled-past-days 365)
    ;;             ;; Excludes today's scheduled items
    ;;             (org-scheduled-delay-days 1)
    ;;             (org-agenda-block-separator nil)
    ;;             (org-agenda-entry-types '(:scheduled))
    ;;             (org-agenda-skip-function '(org-agenda-skip-entry-if 'notregexp "ROUTINE"))
    ;;             (org-agenda-day-face-function (lambda (date) 'org-agenda-date))
    ;;             (org-agenda-format-date "")))
    (agenda "" ((org-agenda-overriding-header "\nNext three days\n")
                (org-agenda-start-on-weekday nil)
                (org-agenda-start-day nil)
                (org-agenda-start-day "+1d")
                (org-agenda-span 3)
                (org-deadline-warning-days 0)
                (org-agenda-block-separator nil)
                (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))))
    (agenda "" ((org-agenda-overriding-header "\nUpcoming deadlines (+14d)\n")
                (org-agenda-time-grid nil)
                (org-agenda-start-on-weekday nil)
                ;; We don't want to replicate the previous section's
                ;; three days, so we start counting from the day after.
                (org-agenda-start-day "+4d")
                (org-agenda-span 14)
                (org-agenda-show-all-dates nil)
                (org-deadline-warning-days 0)
                (org-agenda-block-separator nil)
                (org-agenda-entry-types '(:deadline))
                (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done)))))
  "Custom agenda for use in `org-agenda-custom-commands'.")

(defun jp-org-agenda-set-outline ()
  "Set `outline-regexp' for my Org agenda buffers."
  (when (derived-mode-p 'org-agenda-mode)
    (setq-local outline-regexp "^\\([\s\t]+\\)\\([A-Z]+ \\|[0-9]+:[0-9]+ \\)\\(Deadline\\|Scheduled\\)")))

(add-hook 'org-agenda-mode-hook #'jp-org-agenda-set-outline)

;;;;; agenda appointments

(defvar jp-org-agenda-after-edit-hook nil
  "Hook that runs after select Org commands.
To be used with `advice-add'.")

(defun jp-org--agenda-after-edit (&rest _)
  "Run `jp-org-agenda-after-edit-hook'."
  (run-hooks 'jp-org-agenda-after-edit-hook))

(defvar jp-org-after-deadline-or-schedule-hook nil
  "Hook that runs after `org--deadline-or-schedule'.
To be used with `advice-add'.")

(defvar jp-org--appt-agenda-commands
  '( org-agenda-archive org-agenda-deadline org-agenda-schedule
     org-agenda-todo org-archive-subtree)
  "List of commands that run `jp-org-agenda-after-edit-hook'.")

(dolist (fn jp-org--appt-agenda-commands)
  (advice-add fn :after #'jp-org--agenda-after-edit))

(defun jp-org--after-deadline-or-schedule (&rest _)
  "Run `jp-org-after-deadline-or-schedule-hook'."
  (run-hooks 'jp-org-after-deadline-or-schedule-hook))

(defun jp-org-org-agenda-to-appt ()
  "Make `org-agenda-to-appt' always refresh appointment list."
  (org-agenda-to-appt :refresh))

(dolist (hook '(org-capture-after-finalize-hook
                org-after-todo-state-change-hook
                org-agenda-after-show-hook
                jp-org-agenda-after-edit-hook))
  (add-hook hook #'jp-org-org-agenda-to-appt))

(declare-function org--deadline-or-schedule "org" (arg type time))

(advice-add #'org--deadline-or-schedule :after #'jp-org--after-deadline-or-schedule)

(add-hook 'jp-org-after-deadline-or-schedule-hook #'jp-org-org-agenda-to-appt)

;;;; org-export

(declare-function org-html-export-as-html "org")
(declare-function org-texinfo-export-to-info "org")

;;;###autoload
(defun jp-org-ox-html ()
  "Streamline HTML export."
  (interactive)
  (org-html-export-as-html nil nil nil t nil))

;;;###autoload
(defun jp-org-ox-texinfo ()
  "Streamline Info export."
  (interactive)
  (org-texinfo-export-to-info))

;;;; org-id

(declare-function org-id-add-location "org")
(declare-function org-with-point-at "org")
(declare-function org-entry-get "org")
(declare-function org-id-new "org")
(declare-function org-entry-put "org")

;; Original idea:
;; <https://writequit.org/articles/emacs-org-mode-generate-ids.html>.
(defun jp-org--id-get ()
  "Get the CUSTOM_ID of the current entry.
If the entry already has a CUSTOM_ID, return it as-is, else
create a new one."
  (let* ((pos (point))
         (id (org-entry-get pos "CUSTOM_ID")))
    (or (and id (stringp id) (string-match-p "\\S-" id))
        (and (setq id (org-id-new "h")) (org-entry-put pos "CUSTOM_ID" id)))
    id))

(defun jp-org--heading-to-id ()
  "Convert current heading text to an ID for CUSTOM_ID purposes."
  (thread-last
    (org-get-heading :no-tags :no-todo :no-priority :no-comment)
    (replace-regexp-in-string "[][{}!@#$%^&*()+'\"?,.\|;:~`‘’“”/=]*" "")
    (replace-regexp-in-string "\s" "-")
    (string-trim)
    (downcase)
    (concat "h:")))

(defun jp-org--id-get-readable (&optional force)
  "Like `jp-org--id-get' but use the heading wording to create and ID.
With optional FORCE, update the value even if one exists."
  (let* ((pos (point))
         (id (unless force (org-entry-get pos "CUSTOM_ID"))))
    (or (and id (stringp id) (string-match-p "\\S-" id))
        (and (setq id (jp-org--heading-to-id))
             (org-entry-put pos "CUSTOM_ID" id)))
    id))

(declare-function org-map-entries "org")

;;;###autoload
(defun jp-org-id-headlines ()
  "Add missing CUSTOM_ID to all headlines in current file."
  (interactive)
  (org-map-entries (lambda () (jp-org--id-get))))

;;;###autoload
(defun jp-org-id-headlines-readable (&optional force)
  "Like `jp-org-id-headlines' but with readable IDs.
A readable identifier is one derived from the text of the heading.  In
theory, this may not be unique.

With optional FORCE, update the value even if one exists."
  (interactive "P")
  (org-map-entries (lambda () (jp-org--id-get-readable force))))

;;;###autoload
(defun jp-org-id-headline (&optional readable)
  "Add missing CUSTOM_ID to headline at point.
With optional prefix argument READABLE get a readable identifier derived
from the heading text instead of a UUID."
  (interactive "P")
  (funcall (if readable 'jp-org--id-get-readable 'jp-org--id-get)))

;;;###autoload
(defun jp-org-get-dotemacs-link ()
  "Get URL to current heading in my dotemacs file."
  (declare (interactive-only t))
  (interactive)
  (if (and (derived-mode-p 'org-mode)
           (string-match-p "jp-emacs\\.org\\'" buffer-file-name))
      (if-let* ((id (org-entry-get (point) "CUSTOM_ID"))
                (url (concat "https://jpachecoxyz.github.io#" id)))
          (progn
            (kill-new url)
            (message "Copied %s" (propertize url 'face 'success)))
        (error "No CUSTOM_ID for the current entry"))
    (user-error "You are not in the right file")))


(provide 'jp-org)
;;; jp-org.el ends here
