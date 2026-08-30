;;; emacs-jp-git.el --- Project, version control, Magit and git gutter -*- lexical-binding: t; -*-

;;; Commentary:

;; `project', `diff-mode', `ediff', `smerge-mode', the built-in VC
;; framework, Magit, git gutter and undohist.

;;; Code:

;;;; `project'
(define-key global-map (kbd "C-x p .") #'project-dired)
(define-key global-map (kbd "C-x p C-g") #'keyboard-quit)
(define-key global-map (kbd "C-x p <return>") #'project-dired)
(define-key global-map (kbd "C-x p <delete>") #'project-forget-project)

(setopt project-switch-commands
        '((project-find-file "Find file")
          (project-find-regexp "Find regexp")
          (project-find-dir "Find directory")
          (project-dired "Root dired")
          (project-vc-dir "VC-Dir")
          (project-shell "Shell")
          (keyboard-quit "Quit")))
(setq project-vc-extra-root-markers '(".project")) ; Emacs 29
(setq project-key-prompt-style t) ; Emacs 30

(advice-add #'project-switch-project :after #'jp-common-clear-minibuffer-message)

(autoload #'jp-project-maybe-in-tab "jp-project")
(autoload #'jp-project-switch "jp-project")
(define-key project-prefix-map (kbd "p") #'jp-project-maybe-in-tab)

;;;; `diff-mode'
(setq diff-default-read-only t)
(setq diff-advance-after-apply-hunk t)
(setq diff-update-on-the-fly t)
;; The following are from Emacs 27.1.
(setq diff-refine nil) ; on demand, with the `agitate' package
(setq diff-font-lock-prettify t)
(setq diff-font-lock-syntax nil)

;;;; `ediff'
(setq ediff-split-window-function 'split-window-horizontally)
(setq ediff-window-setup-function 'ediff-setup-windows-plain)
(setq ediff-keep-variants nil)
(setq ediff-make-buffers-readonly-at-startup nil)
(setq ediff-merge-revisions-with-ancestor t)
(setq ediff-show-clashes-only t)

(with-eval-after-load 'outline
  (add-hook 'ediff-prepare-buffer-hook #'outline-show-all))

(autoload #'jp-ediff-visible-buffers-2 "jp-ediff")
(autoload #'jp-ediff-visible-buffers-3 "jp-ediff")
(autoload #'jp-ediff-store-layout "jp-ediff")
(autoload #'jp-ediff-restore-layout "jp-ediff")
;; The C-x v prefix is for all "version control" commands that are
;; already built into Emacs.  It makes sense to extend it for this
;; use-case.
(define-key global-map (kbd "C-x v 2") #'jp-ediff-visible-buffers-2)
(define-key global-map (kbd "C-x v 3") #'jp-ediff-visible-buffers-3)
(add-hook 'ediff-before-setup-hook #'jp-ediff-store-layout)
(add-hook 'ediff-quit-hook #'jp-ediff-restore-layout)

;;;; `smerge-mode'
(setq smerge-diff-buffer-name "*smerge-diff*")
(setq smerge-refine-shadow-cursor nil) ; Emacs 31

;;; Version control framework (vc.el, vc-git.el, and more)
(setq vc-follow-symlinks t)

(with-eval-after-load 'vc
  ;; Those offer various types of functionality, such as blaming,
  ;; viewing logs, showing a dedicated buffer with changes to affected
  ;; files.
  (require 'vc-annotate)
  (require 'vc-dir)
  (require 'vc-git)
  (require 'add-log)
  (require 'log-view)

  ;; Only Git is used.  This may have an effect on performance, as
  ;; Emacs will not try to check for a bunch of backends.
  (setq vc-handled-backends '(Git))

  (setq vc-dir-save-some-buffers-on-revert t) ; Emacs 31

  ;; This one is for editing commit messages.
  (require 'log-edit)
  (setq log-edit-confirm 'changed)
  (setq log-edit-keep-buffer nil)
  (setq log-edit-require-final-newline t)
  (setq log-edit-setup-add-author nil)

  (with-eval-after-load 'log-edit
    (add-hook 'log-edit-hook #'log-edit-insert-message-template)
    (add-hook 'log-edit-hook #'log-edit-maybe-show-diff))

  (setq vc-display-failed-async-commands t) ; Emacs 31
  (setq vc-find-revision-no-save t)
  (setq vc-annotate-display-mode 'scale) ; scale to oldest
  ;; A different account is used for git commits.
  (setq add-log-mailing-address "info@protesilaos.com")
  (setq add-log-keep-changes-together t)
  (setq vc-git-diff-switches '("--patch-with-stat" "--histogram"))
  (setq vc-git-log-switches '("--stat"))
  (setq vc-git-print-log-follow t)
  (setq vc-git-revision-complete-only-branches nil) ; Emacs 28
  (setq vc-git-root-log-format
        `("%d %h %ai %an: %s"
          ;; The first shy group matches the characters drawn by --graph.
          ;; Numbered groups because `log-view-message-re' wants the
          ;; revision number to be group 1.
          ,(concat "^\\(?:[*/\\|]+\\)\\(?:[*/\\| ]+\\)?"
                   "\\(?2: ([^)]+) \\)?\\(?1:[0-9a-z]+\\) "
                   "\\(?4:[0-9]\\{4\\}-[0-9-]\\{4\\}[0-9\s+:-]\\{16\\}\\) "
                   "\\(?3:.*?\\):")
          ((1 'log-view-message)
           (2 'change-log-list nil lax)
           (3 'change-log-name)
           (4 'change-log-date))))

  ;; These two are from Emacs 29.
  (setq vc-git-log-edit-summary-target-len 50)
  (setq vc-git-log-edit-summary-max-len 70)

  (define-advice vc-push (:around (&rest args) prot)
    (let ((current-window (selected-window)))
      (apply args)
      (select-window current-window)))

  (define-advice vc-pull (:around (&rest args) prot)
    (let ((current-window (selected-window)))
      (apply args)
      (select-window current-window)))

  (defun jp/vc-diff-dwim ()
    "Show diff of buffer against file or against VC history."
    (interactive)
    (if-let* ((buffer (current-buffer))
              (_ (buffer-modified-p buffer)))
        (diff-buffer-with-file buffer)
      (call-interactively #'vc-diff)))

  (defvar jp/vc-git-grep-history nil
    "Minibuffer history for `jp/vc-git-grep'.")

  (defun jp/vc-git-grep (directory regexp)
    "Use `vc-git-grep' with REGEXP in the current root Git DIRECTORY."
    (interactive
     (let ((directory (or (vc-root-dir)
                          (locate-dominating-file "." ".git")
                          (user-error "No VC root available"))))
       (list
        directory
        (read-regexp
         (format "vc-git-grep for REGEXP in `%s': "
                 (propertize directory 'face 'warning))
         nil 'jp/vc-git-grep-history))))
    (vc-git-grep regexp "*" directory))

  ;; NOTE: lots of the defaults are overridden.
  (define-key global-map (kbd "C-x v B") #'vc-annotate) ; Blame mnemonic
  (define-key global-map (kbd "C-x v g") #'jp/vc-git-grep) ; override original `vc-annotate' key
  (define-key global-map (kbd "C-x v e") #'vc-ediff)
  (define-key global-map (kbd "C-x v k") #'vc-delete-file) ; 'k' for kill==>delete is more common
  (define-key global-map (kbd "C-x v G") #'vc-log-search)  ; git log --grep
  (define-key global-map (kbd "C-x v t") #'vc-create-tag)
  (define-key global-map (kbd "C-x v c") #'vc-clone) ; Emacs 31
  (define-key global-map (kbd "C-x v d") #'jp/vc-diff-dwim)
  (define-key global-map (kbd "C-x v .") #'vc-dir-root) ; `vc-dir-root' is from Emacs 28
  (define-key global-map (kbd "C-x v <return>") #'vc-dir-root)

  (define-key vc-dir-mode-map (kbd "t") #'vc-create-tag)
  (define-key vc-dir-mode-map (kbd "I") #'vc-log-incoming)
  (define-key vc-dir-mode-map (kbd "O") #'vc-log-outgoing)
  (define-key vc-dir-mode-map (kbd "o") #'vc-dir-find-file-other-window)
  (define-key vc-dir-mode-map (kbd "d") #'vc-diff) ; parallel to D: `vc-root-diff'
  (define-key vc-dir-mode-map (kbd "k") #'vc-dir-delete-file)
  (define-key vc-dir-mode-map (kbd "G") #'vc-revert)

  (define-key vc-git-stash-shared-map (kbd "a") #'vc-git-stash-apply-at-point)
  (define-key vc-git-stash-shared-map (kbd "c") #'vc-git-stash) ; "create" named stash
  (define-key vc-git-stash-shared-map (kbd "k") #'vc-git-stash-delete-at-point) ; symmetry with `vc-dir-delete-file'
  (define-key vc-git-stash-shared-map (kbd "p") #'vc-git-stash-pop-at-point)
  (define-key vc-git-stash-shared-map (kbd "s") #'vc-git-stash-snapshot)

  (define-key vc-annotate-mode-map (kbd "M-q") #'vc-annotate-toggle-annotation-visibility)
  (define-key vc-annotate-mode-map (kbd "C-c C-c") #'vc-annotate-goto-line)
  (define-key vc-annotate-mode-map (kbd "<return>") #'vc-annotate-find-revision-at-line)

  (define-key log-edit-mode-map (kbd "M-s") nil) ; M-s is used for the search commands
  (define-key log-edit-mode-map (kbd "M-r") nil)

  (define-key log-view-mode-map (kbd "<tab>") #'log-view-toggle-entry-display)
  (define-key log-view-mode-map (kbd "<return>") #'log-view-find-revision)
  (define-key log-view-mode-map (kbd "s") #'vc-log-search))

(defun jp/modus-vc-annotate ()
  (modus-themes-with-colors
    (setq vc-annotate-background-mode nil)
    (setq vc-annotate-very-old-color fg-dim)
    (setq vc-annotate-color-map
          `(( 20. . ,red)
            ( 40. . ,red-cooler)
            ( 60. . ,red-warmer)
            ( 80. . ,yellow-warmer)
            (100. . ,yellow)
            (120. . ,yellow-cooler)
            (140. . ,green-warmer)
            (160. . ,green)
            (180. . ,green-cooler)
            (200. . ,cyan-cooler)
            (220. . ,cyan-warmer)
            (240. . ,cyan)
            (260. . ,blue-warmer)
            (280. . ,blue)
            (300. . ,blue-cooler)
            (320. . ,blue-intense)
            (340. . ,magenta-cooler)
            (360. . ,fg-dim)))))

(when (memq jp-emacs-load-theme-family '(modus ef standard))
  (with-eval-after-load 'vc-annotate
    (jp/modus-vc-annotate)
    (add-hook 'modus-themes-after-load-theme-hook #'jp/modus-vc-annotate)))

;;; Interactive and powerful git front-end (Magit)
(setq transient-show-popup 0.5)

(use-package magit
  :config
  ;; Let `display-buffer-alist' do its job.
  (setq magit-display-buffer-function #'display-buffer)

  (define-key global-map (kbd "C-c g") #'magit-status)

  (with-eval-after-load 'magit
    (define-key magit-mode-map (kbd "C-w") nil)
    (define-key magit-mode-map (kbd "M-w") nil))

  (setq magit-define-global-key-bindings nil)
  (setq magit-section-visibility-indicators
        `((" ▼" . t))) ; same as `org-ellipsis'

  ;; Show icons for files in the Magit status and other buffers
  ;; (from jp-icons.el).
  (with-eval-after-load 'jp-icons
    (setq magit-format-file-function
          (lambda (_kind file face &rest _)
            (let ((icon (jp-icons-get-file-icon file)))
              (format "%s %s" icon (propertize file 'font-lock-face face))))))

  (setq magit-diff-refine-hunk t)
  (setq magit-diff-refine-ignore-whitespace t)

  (setq magit-log-auto-more t)

  (setq magit-repository-directories
        '(("~/Git/Projects" . 1)))
  (setq magit-repolist-columns
        `(("Name" 25 ,#'magit-repolist-column-ident)
          ("Version" 15 ,#'magit-repolist-column-version
           ((:sort magit-repolist-version<)))
          ("Unpulled" 10 ,#'magit-repolist-column-unpulled-from-upstream
           ((:help-echo "Upstream changes not in branch")
            (:right-align t)
            (:sort <)))
          ("Unpushed" 10 ,#'magit-repolist-column-unpushed-to-upstream
           ((:help-echo "Local changes not in upstream")
            (:right-align t)
            (:sort <)))
          ("Path" 99 ,#'magit-repolist-column-path)))

  (setq git-commit-summary-max-length 50)
  (setq git-commit-style-convention-checks '(non-empty-second-line))
  (setq git-commit-major-mode #'text-mode)
  (add-hook 'git-commit-mode-hook 'evil-insert))

;;; Git gutter (simple experimental)
(progn
  (require 'cl-lib)

  (defun jp/goto-next-hunk ()
    "Jump cursor to the closest next hunk."
    (interactive)
    (let* ((current-line (line-number-at-pos))
           (line-numbers (mapcar #'car git-gutter-diff-info))
           (sorted-line-numbers (sort line-numbers '<))
           (next-line-number
            (if (not (member current-line sorted-line-numbers))
                (cl-find-if (lambda (line) (> line current-line)) sorted-line-numbers)
              (let ((last-line nil))
                (cl-loop for line in sorted-line-numbers
                         when (and (> line current-line)
                                   (or (not last-line)
                                       (/= line (1+ last-line))))
                         return line
                         do (setq last-line line))))))
      (when next-line-number
        (goto-line next-line-number))))

  (defun jp/goto-previous-hunk ()
    "Jump cursor to the closest previous hunk."
    (interactive)
    (let* ((current-line (line-number-at-pos))
           (line-numbers (mapcar #'car git-gutter-diff-info))
           (sorted-line-numbers (sort line-numbers '<))
           (previous-line-number
            (if (not (member current-line sorted-line-numbers))
                (cl-find-if (lambda (line) (< line current-line)) (reverse sorted-line-numbers))
              (let ((previous-line nil))
                (dolist (line sorted-line-numbers)
                  (when (and (< line current-line)
                             (not (member (1- line) line-numbers)))
                    (setq previous-line line)))
                previous-line))))
      (when previous-line-number
        (goto-line previous-line-number))))

  (defun jp/git-gutter-process-git-diff ()
    "Process git diff for adds/mods/removals.
Marks lines as added, deleted, or changed."
    (interactive)
    (setq-local result '())
    (let* ((file-path (buffer-file-name))
           (grep-command "rg -Po")                         ; for rgrep
           (output (shell-command-to-string
                    (format
                     "git diff --unified=0 %s | %s '^@@ -[0-9]+(,[0-9]+)? \\+\\K[0-9]+(,[0-9]+)?(?= @@)'"
                     file-path
                     grep-command))))
      (setq-local lines (split-string output "\n"))
      (dolist (line lines)
        (if (string-match "\\(^[0-9]+\\),\\([0-9]+\\)\\(?:,0\\)?$" line)
            (let ((num (string-to-number (match-string 1 line)))
                  (count (string-to-number (match-string 2 line))))
              (if (= count 0)
                  (add-to-list 'result (cons (+ 1 num) "deleted"))
                (dotimes (i count)
                  (add-to-list 'result (cons (+ num i) "changed")))))
          (if (string-match "\\(^[0-9]+\\)$" line)
              (add-to-list 'result (cons (string-to-number line) "added"))))
        (setq-local git-gutter-diff-info result))
      result))

  (defun jp/git-gutter-add-mark (&rest args)
    "Add symbols to the left margin based on Git diff statuses.
   - '+' for added lines (lightgreen)
   - '~' for changed lines (yellowish)
   - '-' for deleted lines (tomato)."
    (interactive)
    (set-window-margins (selected-window) 2 0)
    (remove-overlays (point-min) (point-max) 'jp--git-gutter-overlay t)
    (let ((lines-status (or (jp/git-gutter-process-git-diff) '())))
      (save-excursion
        (dolist (line-status lines-status)
          (let ((line-num (car line-status))
                (status (cdr line-status)))
            (when (and line-num status)
              (goto-char (point-min))
              (forward-line (1- line-num))
              (let ((overlay (make-overlay (point-at-bol) (point-at-bol))))
                (overlay-put overlay 'jp--git-gutter-overlay t)
                (overlay-put overlay 'before-string
                             (propertize " "
                                         'display
                                         `((margin left-margin)
                                           ,(propertize
                                             (cond ;; Alternatives:
                                              ((string= status "added")   "+")  ;; +  │ ▏┃
                                              ((string= status "changed") "~")  ;; ~
                                              ((string= status "deleted") "_")) ;; _
                                             'face
                                             `(:foreground
                                               ,(cond
                                                 ((string= status "added") "gray") ;; lightgreen
                                                 ((string= status "changed") "gray") ;; gold
                                                 ((string= status "deleted") "gray"))))))))))))))

  (defun jp/timed-git-gutter-on ()
    (run-at-time 0.1 nil #'jp/git-gutter-add-mark))

  (defun jp/git-gutter-off ()
    "Remove all `jp--git-gutter-overlay' marks and other overlays."
    (interactive)
    (set-window-margins (selected-window) 2 0)
    (remove-overlays (point-min) (point-max) 'jp--git-gutter-overlay t)
    (remove-hook 'find-file-hook #'jp-git-gutter-on)
    (remove-hook 'after-save-hook #'jp/git-gutter-add-mark))

  (defun jp/git-gutter-on ()
    (interactive)
    (jp/git-gutter-add-mark)
    (add-hook 'find-file-hook #'jp/timed-git-gutter-on)
    (add-hook 'after-save-hook #'jp/git-gutter-add-mark))

  (defvar-keymap jp-git-gutter-prefix
    :doc "Git gutter commands."
    "p" #'jp/git-gutter-goto-previous-hunk
    "n" #'jp/git-gutter-goto-next-hunk
    "g" #'jp/git-gutter-on
    "G" #'jp/git-gutter-off)

  (keymap-global-set "C-c g" jp-git-gutter-prefix)
  (add-hook 'after-init-hook #'jp/git-gutter-on))

;; When commit starts in insert mode
(add-hook 'git-commit-mode-hook #'evil-insert-state)

;;; Undo-history mode
(use-package undohist
  :config
  (undohist-initialize))

(provide 'emacs-jp-git)

;;; emacs-jp-git.el ends here
