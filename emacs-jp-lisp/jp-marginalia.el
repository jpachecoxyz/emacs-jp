;;; jp-marginalia.el --- Code for my custom mode line -*- lexical-binding: t -*-

;; Copyright (C) 2023-2026  Javier Pacheco

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
;; Remember that every piece of Elisp that I write is for my own
;; educational and recreational purposes.  I am not a programmer and I
;; do not recommend that you copy any of this if you are not certain of
;; what it does.

;;; Code:

(require 'bookmark)
(require 'package)

(defun jp-marginalia-truncate (string)
  "Truncate STRING to `fill-column', if necessary."
  (if (> (length string) fill-column)
      (concat (substring string 0 fill-column) "...")
    string))

(defun jp-marginalia-display (string)
  "Propertize the display of STRING for completion annotation purposes."
  (when (stringp string)
    (format "%s%s"
            (propertize " " 'display `(space :align-to 40))
            (propertize (jp-marginalia-truncate string)
                        'face 'completions-annotations))))

(defun jp-marginalia-bookmark (bookmark)
  "Annotate BOOKMARK with its file path."
  (when-let* ((bm (assoc bookmark (bound-and-true-p bookmark-alist)))
              (path (bookmark-get-filename bookmark)))
    (jp-marginalia-display path)))

(defun jp-marginalia-buffer (buffer)
  "Annotate BUFFER with the return value of function `buffer-file-name'."
  (if-let* ((name (buffer-file-name (get-buffer buffer))))
      (jp-marginalia-display (abbreviate-file-name name))
    (jp-marginalia-display (format "%s" (buffer-local-value 'major-mode (get-buffer buffer))))))

(defun jp-marginalia-package (package)
  "Annotate PACKAGE with its summary."
  (when-let* ((pkg-alist (bound-and-true-p package-alist))
              (pkg (intern-soft package))
              (desc (or (when (package-desc-p pkg) pkg)
                        (car (alist-get pkg pkg-alist))
                        (if-let* ((built-in (assq pkg package--builtins)))
                            (package--from-builtin built-in)
                          (car (alist-get pkg package-archive-contents))))))
    (jp-marginalia-display (package-desc-summary desc))))

(defun jp-marginalia--get-symbol-doc (symbol)
  "Return documentation string according to SYMBOL type."
  (cond
   ((or (functionp symbol) (macrop symbol))
    (documentation symbol))
   (t
    (get symbol 'variable-documentation))))

(defun jp-marginalia--first-line-documentation (symbol)
  "Return first line of SYMBOL documentation string."
  (when-let* ((doc-string (jp-marginalia--get-symbol-doc symbol))
              ((stringp doc-string))
              ((not (string-empty-p doc-string))))
    (car (split-string doc-string "[?!.\n]"))))

(defun jp-marginalia-symbol (symbol)
  "Annotate SYMBOL with its documentation string."
  (when-let* ((sym (intern-soft symbol))
              (doc-string (jp-marginalia--first-line-documentation sym)))
    (jp-marginalia-display doc-string)))

(provide 'jp-marginalia)
;;; jp-marginalia.el ends here
