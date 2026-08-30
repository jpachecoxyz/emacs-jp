;;; jp-elisp.el --- Emacs Lisp extras for my dotemacs -*- lexical-binding: t -*-

;; Copyright (C) 2025-2026  Javier Pacheco

;; Author: Javier Pacheco <jpacheco@disroot.org>
;; URL: https://jpachecoxyz.github.io
;; Version: 0.1.0
;; Package-Requires: ((emacs "30.1"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
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
;; Extensions for Emacs Lisp, intended for use in my Emacs setup:
;; https://jpachecoxyz.github.io.

;;; Code:

;;;###autoload
(defun jp-elisp-eval-and-print-last-sexp ()
  "Evaluate and print expression before point like `eval-print-last-sexp'.
Prepend a comment to the return value.  Also copy the return value to
the `kill-ring' and set the mark to where point was before inserting the
return value."
  (declare (interactive-only t))
  (interactive)
  (let* ((state (syntax-ppss))
         ;; Find the start of the outermost list.
         ;; If not inside a list, fall back to the symbol/sexp under point.
         (start-pos (if (nth 9 state)
                        (car (nth 9 state))
                      (car (bounds-of-thing-at-point 'sexp))))
         form result end-pos)
    
    (unless start-pos
      (user-error "No expression found around point"))
    
    ;; save-excursion ensures your cursor stays exactly at the `|` position
    (save-excursion
      (goto-char start-pos)
      ;; `read` parses the expression and automatically moves point to its end
      (setq form (read (current-buffer)))
      ;; Evaluate the parsed expression
      (setq result (eval form lexical-binding))
      (setq end-pos (point))
      
      ;; Insert the result at the end of the expression
      (goto-char end-pos)
      (insert (format "\n;; => %S" result)))))

(defvar-keymap jp-elisp-macroexpand-mode-map
  :doc "Key map for `jp-elisp-macroexpand-mode'."
  :parent special-mode-map)

(define-derived-mode jp-elisp-macroexpand-mode emacs-lisp-mode "MacroExpand"
  "Like `emacs-lisp-mode' but for macroexpanded forms."
  :interactive nil
  (read-only-mode 1)
  (display-line-numbers-mode 1)
  (setq-local elisp-fontify-semantically t
              elisp-add-help-echo t)
  (cursor-sensor-mode 1))

;;;###autoload
(defun jp-elisp-pp-macroexpand-last-sexp ()
  "Like `pp-macroexpand-last-sexp' but with a generic `display-buffer'.
Now use `display-buffer-alist' like the Lisp gods intended."
  (declare (interactive-only t))
  (interactive)
  (if-let* ((thing (thing-at-point 'sexp :no-properties))
            (expression (read thing))
            (buffer (get-buffer-create "*jp-elisp-macroexpand*"))
            (inhibit-read-only t))
      (progn
        (with-current-buffer buffer
          (erase-buffer)
          (insert (format "%S" (macroexpand-1 expression)))
          (jp-elisp-macroexpand-mode)
          (pp-buffer))
        (display-buffer buffer))
    (user-error "No expression to macroexpand")))

(provide 'jp-elisp)
;;; jp-elisp.el ends here
