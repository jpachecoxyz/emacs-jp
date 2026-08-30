;;; jp-minibuffer.el --- Extensions for the minibuffer and completions -*- lexical-binding: t -*-

;; Copyright (C) 2025-2026  Javier Pacheco

;; Author: Javier Pacheco <jpacheco@disroot.org>
;; Maintainer: Javier Pacheco <info@protesilaos.com>
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
;; Extensions for the minibuffer and completions, intended for my
;; Emacs setup: <https://jpachecoxyz.github.io>.

;;; Code:

(require 'jp-common)
(require 'jp-icons)

(defgroup jp-minibuffer nil
  "Extensions for the minibuffer and completions."
  :group 'minibuffer)

;;;; Completion category grouping, sorting, and affixating

;; Add some missing completion categories to let me configure the
;; relevant prompts via the `completion-category-overrides'.
(defun jp-minibuffer@read-from-kill-ring (&rest args)
  (let ((completion-extra-properties (list :category 'jp-minibuffer-kill-ring)))
    (apply args)))

(defun jp-minibuffer@read-library-name (&rest args)
  (let ((completion-extra-properties (list :category 'jp-minibuffer-library)))
    (apply args)))

(defun jp-minibuffer@emoji--read-emoji (&rest args)
  (let ((completion-extra-properties (list :category 'jp-minibuffer-emoji)))
    (apply args)))

;;;###autoload
(define-minor-mode jp-minibuffer-missing-categories-mode
  "When enabled, add missing compleiton categories to relevant prompts."
  :global t
  (if jp-minibuffer-missing-categories-mode
      (dolist (original (list #'read-from-kill-ring #'read-library-name #'emoji--read-emoji))
        (when-let* ((my-function-name (format "jp-minibuffer@%s" original))
                    (my-function-symbol (intern-soft my-function-name)))
          (advice-add original :around my-function-symbol)))
    (dolist (original (list #'read-from-kill-ring #'read-library-name #'emoji--read-emoji))
      (when-let* ((my-function-name (format "jp-minibuffer@%s" original))
                  (my-function-symbol (intern-soft my-function-name)))
        (advice-remove original my-function-symbol)))))

(defun jp-minibuffer-file-sort (files)
  "Sort FILES to have directories first and the rest alphabetically.
Omit the .. directory from FILES."
  (setq files (delete "../" files))
  (setq files (minibuffer-sort-alphabetically files))
  (let ((directory-p (lambda (file) (string-suffix-p "/" file))))
    (nconc (seq-filter directory-p files)
           (seq-remove directory-p files))))

(defun jp-minibuffer-file-affixate (files)
  "Return FILES with prefix and suffix."
  (mapcar
   (lambda (file)
     (list file (format "%s " (jp-icons-get-file-icon file)) ""))
   files))

(defun jp-minibuffer-file-group (file transform)
  "Return FILE group name unless TRANSFORM is non-nil."
  (cond
   (transform file)
   ((string-suffix-p "/" file) "/")
   ((string-prefix-p "." file) ".")
   ((when-let* ((extension (file-name-extension file :include-dot))
                (_ (not (string-blank-p extension))))
      extension))
   (t "Other")))

(defun jp-minibuffer--set-default-sort (candidates)
  "Sort CANDIDATES according to `completions-sort' and return the sorted list."
  (setq candidates
        (pcase completions-sort
          ('nil candidates)
          ('alphabetical (minibuffer-sort-alphabetically candidates))
          ('historical (minibuffer-sort-by-history candidates))
          (_ (funcall completions-sort candidates)))))

(defun jp-minibuffer-symbol-sort (symbols)
  "Sort SYMBOLS so that public ones come first."
  (setq symbols (jp-minibuffer--set-default-sort symbols))
  (let ((private-p (lambda (symbol) (string-match-p "--" symbol))))
    (nconc (seq-remove private-p symbols)
           (seq-filter private-p symbols))))

(defun jp-minibuffer-symbol-group (symbol-name transform)
  "Return SYMBOL-NAME group unless TRANSFORM is non-nil."
  (let ((first-word-fn (lambda (string)
                         (if (string-match "\\(.*?\\)[@/-].*" string)
                             (match-string 1 string)
                           string))))
    (cond
     (transform symbol-name)
     ((funcall first-word-fn symbol-name)))))

(defun jp-minibuffer--propertize-suffix-with-space (string)
  "Propertize STRING with spacing before it."
  (format " %s%s"
          (if (and (or (eq completions-format 'horizontal)
                       (eq completions-format 'vertical))
                   (not jp-emacs-completion-ui))
              " "
            (propertize " " 'display '(space :align-to 60)))
          (propertize string 'face 'completions-annotations)))

(defun jp-minibuffer-buffer-group (buffer-name transform)
  "Return BUFFER-NAME group name unless TRANSFORM is non-nil."
  (cond
   (transform buffer-name)
   ((string-prefix-p "*" buffer-name) "Special")
   ((string-match-p "\\`magit.*?:" buffer-name) "Git")
   ((if-let* ((buffer (get-buffer buffer-name)))
      (with-current-buffer buffer
        (cond
         ((derived-mode-p 'dired-mode)
          "Directory")
         ((derived-mode-p 'prog-mode)
          "Program")
         ((derived-mode-p 'text-mode)
          "Prose")
         (t
          (format "%s" major-mode))))
      ""))))

(defun jp-minibuffer-buffer-affixate (buffers)
  "Return BUFFERS with prefix and suffix."
  (mapcar
   (lambda (buffer)
     (let* ((buffer-object (get-buffer buffer))
            (mode (with-current-buffer buffer-object major-mode)))
       (list
        buffer
        (format "%s " (jp-icons-get-icon mode))
        (jp-minibuffer--propertize-suffix-with-space (format "%s" mode)))))
   buffers))

(defun jp-minibuffer-bookmark-affixate (bookmarks)
  "Return BOOKMARKS with prefix and suffix."
  (mapcar
   (lambda (bookmark)
     (let* ((data (bookmark-get-bookmark bookmark))
            (file (bookmark-prop-get data 'filename)))
       (list
        bookmark
        (format "%s " (jp-icons-get-file-icon file))
        (jp-minibuffer--propertize-suffix-with-space (format "%s" file)))))
   bookmarks))

(defun jp-minibuffer-library-sort (libraries)
  "Sort LIBRARIES, omitting autoloads and bytecode files."
  (setq libraries (seq-remove
                   (lambda (library)
                     (string-match-p "\\(-autoload\\|\\.elc\\|\\.dir-locals\\)" library))
                   libraries))
  (jp-minibuffer--set-default-sort libraries))

;; NOTE 2025-12-19: Maybe there is a better way, but this is okay to start with.
(defun jp-minibuffer-library-annotate (library)
  "Return the group documentation of LIBRARY."
  (when-let* ((group-documentation (get (intern-soft library) 'group-documentation)))
    (jp-minibuffer--propertize-suffix-with-space group-documentation)))

(defun jp-minibuffer-command-annotate (command)
  "Annotate COMMAND with its key binding and shortened documentation string."
  (let* ((symbol (intern-soft command))
         (key (if-let* ((binding (where-is-internal symbol overriding-local-map t))
                        (description (key-description binding))
                        (_ (and binding (not (stringp binding)))))
                  (format "  %s " (propertize description 'face 'help-key-binding))
                ""))
         (doc (if-let* ((doc (condition-case nil (documentation symbol) (error nil)))
                        (first-line (substring doc 0 (string-search "\n" doc))))
                  (propertize first-line 'face 'completions-annotations)
                "")))
    (format "%s%s" key (jp-minibuffer--propertize-suffix-with-space doc))))

;;;; Completions

(defun jp-minibuffer-completions-tweak-style ()
  "Tweak the style of the Completions buffer."
  (setq-local mode-line-format nil)
  (setq-local cursor-in-non-selected-windows nil)
  (when (and completions-header-format
             (not (string-blank-p completions-header-format)))
    (setq-local display-line-numbers-offset -1))
  (display-line-numbers-mode 1))

(defun jp-minibuffer-quit-completions ()
  "Always quit the Completions window."
  (when-let* ((window (get-buffer-window "*Completions*")))
    (quit-window nil window)))

(defun jp-minibuffer-choose-completion-no-exit ()
  "Call `choose-completion' without exiting the minibuffer.
Also see `jp-minibuffer-choose-completion-exit' and `jp-minibuffer-choose-completion-dwim'."
  (interactive)
  (choose-completion nil :no-exit :no-quit)
  (switch-to-minibuffer))

(defun jp-minibuffer-choose-completion-exit ()
  "Call `choose-completion' and exit the minibuffer.
Also see `jp-minibuffer-choose-completion-no-exit' and `jp-minibuffer-choose-completion-dwim'."
  (interactive)
  (choose-completion nil :no-exit)
  (exit-minibuffer))

(defun jp-minibuffer-crm-p ()
  "Return non-nil if `completing-read-multiple' is in use."
  (when-let* ((_ (featurep 'crm))
              (window (active-minibuffer-window))
              (buffer (window-buffer window)))
    (buffer-local-value 'crm-completion-table buffer)))

(defun jp-minibuffer-choose-completion-dwim ()
  "Call `choose-completion' that exits only on a unique match.
If the match is not unique, then complete up to the largest common
prefix or, anyhow, continue with the completion (e.g. in `find-file'
switch into the directory and then show the files therein).

Also see `jp-minibuffer-choose-completion-no-exit' and `jp-minibuffer-choose-completion-exit'."
  (interactive)
  (if (jp-minibuffer-crm-p)
      (jp-minibuffer-choose-completion-no-exit)
    (choose-completion nil :no-exit :no-quit)
    (switch-to-minibuffer)
    (minibuffer-completion-help)
    (unless (get-buffer-window "*Completions*")
      (exit-minibuffer))))

(define-advice minibuffer-completion-help (:around (&rest args) prot)
  "Make `minibuffer-completion-help' display *Completions* in a side window.
Make the window be at slot 0, such that the *Help* buffer produced by
`jp-minibuffer-completions-describe-at-point' is to its right."
  (let ((display-buffer-overriding-action
         `((display-buffer-reuse-mode-window display-buffer-in-side-window)
           (mode . completion-list-mode)
           (side . bottom)
           (slot . 0))))
    (apply args)))

(defun jp-minibuffer-completions-describe-at-point (symbol)
  "Describe SYMBOL at point inside the *Completions* buffer.
Place the *Help* buffer in a side window, situated to the right of the
*Completions* buffer.  Make the window have the `jp-minibuffer-help'
property, such that it can be found by `jp-minibuffer-completions-close-help'."
  (interactive (list (intern-soft (thing-at-point 'symbol))))
  (unless (derived-mode-p 'completion-list-mode)
    (user-error "Can only do this from the *Completions* buffer"))
  (when symbol
    (let ((help-window-select nil)
          (display-buffer-overriding-action
           `((display-buffer-reuse-mode-window display-buffer-in-side-window)
             (mode . help-mode)
             (side . bottom)
             (slot . 1)
             (window-height . fit-window-to-buffer)
             (window-parameters . ((jp-minibuffer-help . t))))))
      (describe-symbol symbol))))

(defun jp-minibuffer-completions-close-help ()
  "Close the window that has a `jp-minibuffer-help' parameter."
  (when-let* ((help (seq-find
                     (lambda (window)
                       (window-parameter window 'jp-minibuffer-help))
                     (window-list))))
    (delete-window help)))

;;;###autoload
(define-minor-mode jp-minibuffer-completions-mode
  "Tweak the interface of the minibuffer and the *Completions*."
  :global t
  (if jp-minibuffer-completions-mode
      (progn
        (setq completion-show-help nil)
        (setq completion-show-inline-help nil)
        (setq completions-detailed t)
        (setq completions-format 'one-column)
        (setq completions-header-format "")
        (setq completions-max-height 12)
        (setq completions-sort 'historical)
        (setq completion-auto-help t)
        (setq completion-auto-select t)
        (setq completion-eager-display 'auto)
        (setq completion-eager-update 'auto)
        (add-hook 'completion-list-mode-hook #'jp-minibuffer-completions-tweak-style)
        (add-hook 'minibuffer-exit-hook #'jp-minibuffer-quit-completions)
        (add-hook 'minibuffer-exit-hook #'jp-minibuffer-completions-close-help))
    (setq completion-show-help t)
    (setq completion-show-inline-help nil)
    (setq completions-detailed nil)
    (setq completions-format 'horizontal)
    (setq completions-header-format (propertize "%s possible completions:\n" 'face 'shadow))
    (setq completions-max-height nil)
    (setq completions-sort 'alphabetical)
    (setq completion-auto-help t)
    (setq completion-auto-select nil)
    (setq completion-eager-display 'auto)
    (setq completion-eager-update 'auto)
    (remove-hook 'completion-list-mode-hook #'jp-minibuffer-completions-tweak-style)
    (remove-hook 'minibuffer-exit-hook #'jp-minibuffer-quit-completions)
    (remove-hook 'minibuffer-exit-hook #'jp-minibuffer-completions-close-help)))

(provide 'jp-minibuffer)
;;; jp-minibuffer.el ends here
