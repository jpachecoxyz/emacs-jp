;;; jp-project.el --- Extensions for project.el -*- lexical-binding: t -*-

;; Copyright (C) 2025-2026  Javier Pacheco

;; Author: Javier Pacheco <jpacheco@disroot.org>
;; URL: https://jpachecoxyz.github.io
;; Version: 0.1.0
;; Package-Requires: ((emacs "30.1"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Extensions for project.el.

;;; Code:

(require 'project)
(require 'tab-bar)

;;;; Switch to a project root Dired outright

(defun jp-project--switch (directory &optional command)
  "Do the work of `project-switch-project' in the given DIRECTORY.
With optional COMMAND, run it in DIRECTORY."
  (let ((command (or (when (functionp command) command)
                     (if (symbolp project-switch-commands)
                         project-switch-commands
                       (project--switch-project-command))))
        (buffer (current-buffer)))
    (unwind-protect
        (progn
          (setq-local project-current-directory-override directory)
          (call-interactively command))
      (with-current-buffer buffer
        (kill-local-variable 'project-current-directory-override)))))

(defun jp-project--frame-names ()
  "Return a list of frame names."
  (mapcar #'car (make-frame-names-alist)))

(defvar jp-project-switch-hook nil
  "Normal hook called after `jp-project-switch'.")

;;;###autoload
(defun jp-project-switch (directory)
  "Switch to project DIRECTORY.
If DIRECTORY exists in a frame, select it.  Otherwise switch to
the project in DIRECTORY using `project-dired'."
  (interactive (list (funcall project-prompter)))
  (project--remember-dir directory)
  (let ((name (file-name-nondirectory (directory-file-name directory))))
    (if (member name (jp-project--frame-names))
        (select-frame-by-name name)
      (jp-project--switch directory 'project-dired))
    (run-hooks 'jp-project-switch-hook)
    (setq this-command 'project-switch-project)))

;;;; Produce a VC root log for the project

(defun jp-project-rename-vc-root-log (&rest _)
  "Rename the buffer of `vc-print-root-log' to mention the project."
  (when-let* ((root (vc-root-dir))
              ((consp project--list))
              ((member root (mapcar #'car project--list))))
    (rename-buffer (format "*vc-root-log: %s*" root))))

(advice-add #'vc-print-root-log :after #'jp-project-rename-vc-root-log)

;;;; One tab per project

;; NOTE 2024-01-15 07:07:52 +0200: I define the "in tab" functions as
;; a coding exercise.  I don't have a use for it, as I prefer to use
;; the approach of my `beframe' package instead.
(defun jp-project-in-tab--get-tab-names (&optional frame)
  "Return list of tab names associated with FRAME.
If FRAME is nil, use the current frame."
  (mapcar
   (lambda (tab)
     (alist-get 'name tab))
   (frame-parameter frame 'tabs)))

(defun jp-project-in-tab--create-tab (directory name)
  "Create new tab visiting DIRECTORY and named NAME."
  (tab-new)
  (find-file directory)
  (unwind-protect
      (jp-project--switch directory 'project-dired)
    (tab-rename name)
    ;; NOTE 2024-01-15 06:52 +0200: I am adding this because
    ;; `tab-rename' is not persistent for some reason. Probably a bug...
    (let* ((tabs (funcall tab-bar-tabs-function))
           (tab-to-rename (nth (tab-bar--current-tab-index) tabs)))
      (setf (alist-get 'explicit-name tab-to-rename) name))))

;;;###autoload
(defun jp-project-in-tab (directory)
  "Switch to project DIRECTORY in a tab.
If a tab is named after the non-directory component of DIRECTORY,
switch to it.  Otherwise, create a new tab and name it after the
non-directory component of DIRECTORY.

Use this as an alternative to `project-switch-project'."
  (interactive (list (funcall project-prompter)))
  (project--remember-dir directory)
  (let ((name (file-name-nondirectory (directory-file-name directory))))
    (if (member name (jp-project-in-tab--get-tab-names))
        (tab-switch name)
      (jp-project-in-tab--create-tab directory name))
    (setq this-command 'project-switch-project)))

;;;###autoload
(defun jp-project-maybe-in-tab ()
  "Switch to project depending on `beframe-mode'.
When the mode is enabled (the expected behaviour), use the command
`jp-project-switch'.  Otherwise, do `jp-project-in-tab'."
  (interactive)
  (call-interactively
   (if (bound-and-true-p beframe-mode)
       'jp-project-switch
     'jp-project-in-tab)))

;;;; Set up a project root

;; I don't actually have a use-case for `jp-project-find-root',
;; but I wrote it once so I keep it here in case I ever need it.
;; Use it like this: (jp-project-find-root c-mode "Makefile")
(defmacro jp-project-find-root (mode file)
  "Define project root check for MODE given FILE.
MODE must be the symbol of the major mode, without a quote.  FILE
is a string."
  (let ((project-find-fn (intern (format "project-find-%s-root" mode)))
        (major-mode-fn (intern (format "jp-%s-project-find-function" mode)))
        (file-symbol (intern file)))
    `(progn
       (defun ,project-find-fn (dir)
         (when-let* ((root (locate-dominating-file dir ,file)))
           (cons ',file-symbol root)))

       (cl-defmethod project-root ((project (head ,file-symbol)))
         (cdr project))

       (defun ,(intern (format "jp-%s-project-find-function" mode)) ()
         (add-hook 'project-find-functions #',project-find-fn :depth :local))

       (add-hook ',(intern (format "%s-hook" mode)) #',major-mode-fn))))

;;;; Enable completion in the `compile' command

(defun jp-project-compilation-read-command (command)
  "Like `compilation-read-command' for COMMAND with completion against the `compile-history'."
  (if-let* ((history compile-history)
            (default (car history)))
      (completing-read "Compile command: " history nil nil nil 'compile-history default)
    (read-shell-command "Compile command: " command
                      (if (equal (car compile-history) command)
                          '(compile-history . 1)
                        'compile-history))))

(advice-add #'compilation-read-command :override #'jp-project-compilation-read-command)

(provide 'jp-project)
;;; jp-project.el ends here
