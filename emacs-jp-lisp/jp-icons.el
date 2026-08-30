;;; jp-icons.el --- Get characters, icons, and symbols for things -*- lexical-binding: t -*-

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
;; Extensions to get icons and symbols for files, buffers, or related.
;; Intended for my Emacs setup: <https://jpachecoxyz.github.io>.

;;; Code:

(require 'jp-common)

(defgroup jp-icons nil
  "Get characters, icons, and symbols for things."
  :group 'convenience)

(defface jp-icons-icon
  '((t :inherit (bold fixed-pitch)))
  "Basic attributes for an icon."
  :group 'jp-icons)

(defface jp-icons-red
  '((default :inherit jp-icons-icon)
    (((class color) (min-colors 88) (background light))
     :foreground "#aa3232")
    (((class color) (min-colors 88) (background dark))
     :foreground "#f06464")
    (t :foreground "red"))
  "Face for icons."
  :group 'jp-icons)

(defface jp-icons-green
  '((default :inherit jp-icons-icon)
    (((class color) (min-colors 88) (background light))
     :foreground "#107010")
    (((class color) (min-colors 88) (background dark))
     :foreground "#33bb33")
    (t :foreground "green"))
  "Face for icons."
  :group 'jp-icons)

(defface jp-icons-yellow
  '((default :inherit jp-icons-icon)
    (((class color) (min-colors 88) (background light))
     :foreground "#605000")
    (((class color) (min-colors 88) (background dark))
     :foreground "#e0a055")
    (t :foreground "yellow"))
  "Face for icons."
  :group 'jp-icons)

(defface jp-icons-blue
  '((default :inherit jp-icons-icon)
    (((class color) (min-colors 88) (background light))
     :foreground "#223399")
    (((class color) (min-colors 88) (background dark))
     :foreground "#5599ff")
    (t :foreground "blue"))
  "Face for icons."
  :group 'jp-icons)

(defface jp-icons-magenta
  '((default :inherit jp-icons-icon)
    (((class color) (min-colors 88) (background light))
     :foreground "#8f2270")
    (((class color) (min-colors 88) (background dark))
     :foreground "#ee70aa")
    (t :foreground "magenta"))
  "Face for icons."
  :group 'jp-icons)

(defface jp-icons-cyan
  '((default :inherit jp-icons-icon)
    (((class color) (min-colors 88) (background light))
     :foreground "#226067")
    (((class color) (min-colors 88) (background dark))
     :foreground "#77b0c0")
    (t :foreground "cyan"))
  "Face for icons."
  :group 'jp-icons)

(defface jp-icons-gray
  '((default :inherit jp-icons-icon)
    (((class color) (min-colors 88) (background light))
     :foreground "gray30")
    (((class color) (min-colors 88) (background dark))
     :foreground "gray70")
    (t :foreground "gray"))
  "Face for icons."
  :group 'jp-icons)

(defface jp-icons-directory
  `((t :inherit ,(if (facep 'dired-directory)
                     '(jp-icons-icon dired-directory)
                   'jp-icons-icon)))
  "Face for icons."
  :group 'jp-icons)

;; (defvar jp-icons
;;   '((dired-mode "|*" jp-icons-directory)
;;     (archive-mode "|@" jp-icons-directory)
;;     (diff-mode ">Δ" jp-icons-yellow) ; διαφορά
;;     (prog-mode ">Π" jp-icons-magenta) ; πρόγραμμα
;;     (conf-mode ">Π" jp-icons-gray) ; πρόγραμμα
;;     (text-mode ">Α" jp-icons-green) ; αλφάβητο
;;     (comint-mode ">_" jp-icons-gray)
;;     (document ">Σ" jp-icons-red) ; σύγγραμμα
;;     (audio ">Η" jp-icons-cyan) ; ήχος
;;     (image ">Ε" jp-icons-yellow) ; εικόνα
;;     (video ">Κ" jp-icons-blue) ; κίνηση (κινηματογράφος)
;;     (frame "[]" jp-icons-gray)
;;     (git "|-" jp-icons-gray)
;;     (t ">." jp-icons-gray))
;;   "Major modes or concepts and their corresponding icons.
;; Each element is a cons cell of the form (THING STRING FACE), where THING
;; is a symbol STRING is one or more characters that represent THING, and
;; FACE is the face to use for it, where applicable.")

(defvar jp-icons
  '((dired-mode "Δ" jp-icons-directory)   ; delta → cambio / filesystem
    (archive-mode "Ω" jp-icons-directory) ; omega → final / paquete
    (diff-mode "Δ" jp-icons-yellow)       ; delta → difference
    (prog-mode "ξ" jp-icons-magenta)     ; programming / lambda
    (conf-mode "κ" jp-icons-gray)         ; kappa → configuración
    (text-mode "α" jp-icons-green)        ; alpha → texto
    (comint-mode "ψ" jp-icons-gray)       ; psi → shell / interacción
    (document "σ" jp-icons-red)           ; sigma → documento
    (audio "η" jp-icons-cyan)             ; eta → sonido
    (image "ε" jp-icons-yellow)           ; epsilon → imagen
    (video "θ" jp-icons-blue)             ; theta → movimiento
    (frame "φ" jp-icons-gray)             ; phi → frame
    (git "ψ" jp-icons-gray)              ; branch
    (t "·" jp-icons-gray))
  "Major modes or concepts and their corresponding glyphs.
Each element is a cons cell of the form (THING STRING FACE).")

(defun jp-icons--get (thing)
  "Return `jp-icons' representation of THING."
  (unless (symbolp thing)
    (error "The thing `%s' is not a symbol" thing))
  (when (string-suffix-p "-mode" (symbol-name thing))
    (while-let ((parent (get thing 'derived-mode-parent)))
      (setq thing parent)))
  (or (alist-get thing jp-icons)
      (alist-get t jp-icons)))

(defun jp-icons-get-icon (thing &optional face)
  "Return propertized icon THING."
  (pcase-let ((`(,icon ,inherent-face) (jp-icons--get thing)))
    (let ((face (or face inherent-face)))
      (format "%2s" (propertize icon 'font-lock-face face 'face face)))))

(defun jp-icons-get-file-icon (file)
  "Return FILE icon and face."
  (cond
   ((null file)
    (jp-icons-get-icon nil))
   ((string-suffix-p "/" file)
    (jp-icons-get-icon 'dired-mode))
   ((string-match-p (jp-common--get-file-type-regexp 'archive) file)
    (jp-icons-get-icon 'archive-mode))
   ((string-match-p (jp-common--get-file-type-regexp 'text) file)
    (jp-icons-get-icon 'text-mode))
   ((string-match-p (jp-common--get-file-type-regexp 'image) file)
    (jp-icons-get-icon 'image))
   ((string-match-p (jp-common--get-file-type-regexp 'audio) file)
    (jp-icons-get-icon 'audio))
   ((string-match-p (jp-common--get-file-type-regexp 'video) file)
    (jp-icons-get-icon 'video))
   ((string-match-p (jp-common--get-file-type-regexp 'document) file)
    (jp-icons-get-icon 'document))
   ((string-match-p (jp-common--get-file-type-regexp 'diff) file)
    (jp-icons-get-icon 'diff-mode))
   ((string-match-p (jp-common--get-file-type-regexp 'program) file)
    (jp-icons-get-icon 'prog-mode))
   ((string-match-p (jp-common--get-file-type-regexp 'program-data) file)
    (jp-icons-get-icon 'conf-mode))
   (t (jp-icons-get-icon nil))))

;;;; Icons for Dired

;; Adapted from `nerd-icons-dired'

(defun jp-icons-dired--add-overlay (pos string)
  "Add overlay to display STRING at POS."
  (let ((overlay (make-overlay (1- pos) pos)))
    (overlay-put overlay 'jp-icons-overlay t)
    (overlay-put overlay 'evaporate t)
    (overlay-put overlay 'before-string (propertize string 'display string))
    (overlay-put overlay 'after-string (propertize " " 'display '(space :align-to 1)))))

(defun jp-icons-dired--remove-all-overlays ()
  "Remove all `jp-icons' overlays."
  (dolist (buffer (buffer-list))
    (when (and (derived-mode-p 'dired-mode) jp-icons-dired-mode)
      (save-restriction
        (widen)
        (remove-overlays nil nil 'jp-icons-overlay t)))))

(defun jp-icons-dired--annotate ()
  "Add icons to all files in the visible region of the buffer."
  (save-excursion
    (goto-char (point-min))
    (while (and (dired-next-line 1) (not (eobp)))
      (when-let* ((file (dired-get-filename nil :no-error))
                  (icon (if (file-directory-p file)
                            (jp-icons-get-file-icon (concat file "/"))
                          (jp-icons-get-file-icon file))))
        (jp-icons-dired--add-overlay (dired-move-to-filename) icon)))))

(defun jp-icons-dired--refresh (&rest _)
  "Update the display of icons of files in a Dired buffer."
  (jp-icons-dired--remove-all-overlays)
  (save-restriction
    (widen)
    (jp-icons-dired--annotate)))

(defun jp-icons-dired--setup ()
  "Set up Dired to display icons."
  (setq-local tab-width 1)
  (jp-icons-dired--refresh))

;;;###autoload
(define-minor-mode jp-icons-dired-mode
  "Display icons for Dired entries."
  :global t
  (if jp-icons-dired-mode
      (progn
        (add-hook 'dired-mode-hook #'jp-icons-dired--setup)
        (add-hook 'dired-after-readin-hook 'jp-icons-dired--annotate)
        (advice-add #'dired-do-redisplay :after #'jp-icons-dired--refresh)
        (advice-add #'wdired-abort-changes :after #'jp-icons-dired--refresh))
    (jp-icons-dired--remove-all-overlays)
    (remove-hook 'dired-mode-hook #'jp-icons-dired--setup)
    (remove-hook 'dired-after-readin-hook 'jp-icons-dired--annotate)
    (advice-remove #'dired-do-redisplay #'jp-icons-dired--refresh)
    (advice-remove #'wdired-abort-changes #'jp-icons-dired--refresh)))

;;;; Icons for Xref

;; Adapted from `nerd-icons-xref'

(defun jp-icons-xref--add-overlay (position string)
  "Add overlay at POSITION to display STRING."
  (let ((overlay (make-overlay position (+ position 1))))
    (overlay-put overlay 'jp-icons-overlay t)
    (overlay-put overlay 'evaporate t)
    (overlay-put overlay 'before-string (format "%s " (propertize string 'display string)))))

(defun jp-icons-xref--add-icons ()
  "Add icons to Xref headings."
  (save-excursion
    (goto-char (point-min))
    (let ((prop))
      (while (setq prop (text-property-search-forward 'xref-group))
        (when-let* ((start (prop-match-beginning prop))
                    (end (prop-match-end prop))
                    (file (string-chop-newline (buffer-substring-no-properties start end)))
                    (icon (jp-icons-get-file-icon file)))
          (jp-icons-xref--add-overlay start icon))))))

;;;###autoload
(define-minor-mode jp-icons-xref-mode
  "Display icons for Xref headings."
  :global t
  (if jp-icons-xref-mode
      (add-hook 'xref-after-update-hook #'jp-icons-xref--add-icons)
    (remove-hook 'xref-after-update-hook #'jp-icons-xref--add-icons)))

;;;; Icons for Buffer menu

(defun jp-icons-buffer-menu--add-overlay (position string)
  "Add overlay at POSITION to display STRING."
  (let ((overlay (make-overlay position (+ position 1))))
    (overlay-put overlay 'jp-icons-overlay t)
    (overlay-put overlay 'evaporate t)
    (overlay-put overlay 'before-string (propertize string 'display string))))

(defun jp-icons-buffer-menu--add-icons (&rest _)
  "Add icons to `Buffer-menu-mode' entries."
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (derived-mode-p 'Buffer-menu-mode)
        (save-excursion
          (goto-char (point-min))
          (while-let ((match (text-property-search-forward 'tabulated-list-id))
                      (buffer (prop-match-value match))
                      (mode (with-current-buffer buffer major-mode))
                      (icon (jp-icons-get-icon mode)))
            (jp-icons-buffer-menu--add-overlay (line-beginning-position) (concat icon " "))))))))

;;;###autoload
(define-minor-mode jp-icons-buffer-menu-mode
  "Display icons for `Buffer-menu-mode' entries."
  :global t
  (if jp-icons-buffer-menu-mode
      (advice-add #'list-buffers--refresh :after #'jp-icons-buffer-menu--add-icons)
    (advice-remove #'list-buffers--refresh #'jp-icons-buffer-menu--add-icons)))

(provide 'jp-icons)
;;; jp-icons.el ends here
