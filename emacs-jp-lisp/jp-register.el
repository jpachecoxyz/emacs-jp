;;; jp-register.el --- Extensions for project.el -*- lexical-binding: t -*-

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
;; Extensions for register.el.

;;; Code:

(require 'register)

;;;; Define new register for file with point

(cl-defmethod register--type ((_regval vector)) 'vector)

(cl-defmethod register-val-describe ((val vector) _verbose)
  (if-let* ((position (aref val 2))
            (file (aref val 1)))
      (princ (format "%s at position %s" file position))
    (princ "Garbage data")))

;;;###autoload
(defun jp-simple-file-to-register (register)
  "Store current location of file's point in REGISTER."
  (interactive (list (register-read-with-preview "File with point to register: ")))
  (set-register register (vector 'file-with-point (buffer-file-name) (point))))

(defvar jp-simple-file-to-register-jump-hook nil
  "Normal hook called after jumping to a file register.
See `jp-simple-file-to-register'.")

;;;###autoload
(cl-defmethod register-val-jump-to ((val vector) delete)
  "Handle how to jump to a location register.
This is like the default, but does not ask to visit a file: it does it
outright."
  (cond
   ((eq (aref val 0) 'file-with-point)
    (find-file (aref val 1))
    (goto-char (aref val 2))
    (run-hooks 'jp-simple-file-to-register-jump-hook))
   (t (cl-call-next-method val delete))))

;;;; Do-What-I-Mean commands

;;;###autoload
(defun jp-register-add-dwim (register &optional number)
  "Do-What-I-Mean with REGISTER.
If the region is active, call `copy-to-register'.

If the optional prefix argument NUMBER is non-nil, then call
`number-to-register'.

If there are more than two windows or there are more than one
`tab-bar-mode' tabs, then do `frameset-to-register'.

Otherwise, use `jp-simple-file-to-register'.

Also see `jp-register-use-dwim'."
  (interactive
   (list
    (register-read-with-preview "Add register: ")
    (when current-prefix-arg
      (prefix-numeric-value current-prefix-arg))))
  (cond
   ((when-let* ((_ (region-active-p))
                (beg (region-beginning))
                (end (region-end))
                (text (buffer-substring beg end))
                (_ (not (string-blank-p text))))
      (copy-to-register register beg end)
      (message "Copied `%s' to register `%c'" text register)))
   (number
    (number-to-register number register)
    (message "Copied number `%d' to register `%c'" number register))
   ((or (length> (window-list) 2)
        (and (bound-and-true-p tab-bar-mode)
             (length> (tab-bar-tabs) 1)))
    (frameset-to-register register)
    (message "Copied current frameset to register `%c'" register))
   (t
    (jp-simple-file-to-register register)
    (message "Copied current point in file to register `%c'" register))))

;;;###autoload
(defun jp-register-use-dwim (register)
  "Use the REGISTER, jumping or inserting it, depending on its ocntents."
  (interactive (list (register-read-with-preview "Use register: ")))
  (let ((contents (get-register register)))
    (cond
     ((register--jumpable-p contents)
      (jump-to-register register))
     ((or (register--insertable-p contents)
          (numberp register))
      (insert-register register))
     (t
      (error "The register is unknown: %S" contents)))))

;;;; The `jp-register-persist-mode'

(defcustom jp-register-save-file (locate-user-emacs-file "jp-register.eld")
  "File to store registers to and retrieve from."
  :type 'file)

(defun jp-register-store ()
  "Escribe `register-alist' al archivo, ignorando objetos complejos."
  (with-temp-file jp-register-save-file
    (insert ";; Auto-generated file: DO NOT EDIT -*- mode: emacs-lisp -*-\n")
    (let ((printable-alist 
           (cl-remove-if-not
            (lambda (reg)
              (let ((val (cdr reg)))
                ;; Filtro estricto: solo guardamos lo que es seguro
                (or (stringp val)       ;; Texto copiado
                    (numberp val)       ;; Números
                    (and (vectorp val)  ;; Tu función de archivo + posición
                         (eq (aref val 0) 'file-with-point))
                    ;; Opcional: registrar posiciones simples de archivos nativos
                    (and (consp val) (eq (car val) 'file)))))
            register-alist)))
      (pp printable-alist (current-buffer)))))

(defun jp-register-load ()
  "Read `jp-register-save-file' and return its contents."
  (with-temp-buffer
    (when (file-exists-p jp-register-save-file)
      (insert-file-contents jp-register-save-file)
      (read (buffer-string)))))

(defun jp-register-watcher (symbol newval operation where)
  (when (and (eq operation 'set) (null where) newval)
    (jp-register-store)))

;;;###autoload
(define-minor-mode jp-register-persist-mode
  "When enabled save `register-alist' to `jp-register-save-file' when a change occurs."
  :globat t
  (if jp-register-persist-mode
      (progn
        (add-variable-watcher 'register-alist #'jp-register-watcher)
        (add-hook 'kill-emacs-hook #'jp-register-store))
    (remove-variable-watcher 'register-alist #'jp-register-watcher)
    (remove-hook 'kill-emacs-hook #'jp-register-store)))

(provide 'jp-register)
;;; jp-register.el ends here
