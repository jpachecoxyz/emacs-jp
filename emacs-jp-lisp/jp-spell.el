;;; jp-spell.el --- Spelling-related extensions for my dotemacs -*- lexical-binding: t -*-

;; Copyright (C) 2021-2026  Javier Pacheco

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
;; This covers my spelling-related extensions, for use in my Emacs
;; setup: https://jpachecoxyz.github.io.

;;; Code:

(require 'ispell)

(defgroup jp-spell ()
  "Extensions for ispell and flyspell."
  :group 'ispell)

(defcustom jp-spell-dictionaries
  '(("EN English" . "en")
    ("EL Ελληνικά" . "el")
    ("FR Français" . "fr")
    ("ES Espanõl" . "es"))
  "Alist of strings with descriptions and dictionary keys.
Used by `jp-spell-change-dictionary'."
  :type 'alist
  :group 'jp-spell)

(defvar jp-spell--dictionary-hist '()
  "Input history for `jp-spell-change-dictionary'.")

(defun jp-spell--dictionary-prompt ()
  "Helper prompt to select from `jp-spell-dictionaries'."
  (let ((def (car jp-spell--dictionary-hist)))
    (completing-read
     (format "Select dictionary [%s]: " def)
     (mapcar #'car jp-spell-dictionaries)
     nil t nil 'jp-spell--dictionary-hist def)))

;;;###autoload
(defun jp-spell-change-dictionary (dictionary)
  "Select a DICTIONARY from `jp-spell-dictionaries'."
  (interactive
   (list (jp-spell--dictionary-prompt)))
  (let* ((key (cdr (assoc dictionary jp-spell-dictionaries)))
         (desc (car (assoc dictionary jp-spell-dictionaries))))
    (ispell-change-dictionary key)
    (message "Switched dictionary to %s" (propertize desc 'face 'bold))))

;;;###autoload
(defun jp-spell-spell-dwim (beg end)
  "Spell check between BEG END, current word, or select a dictionary.

Use `flyspell-region' on the active region and deactivate the
mark.

With point over a word and no active region invoke `ispell-word'.

Else call `jp-spell-change-dictionary'."
  (interactive "r")
  (cond
   ((use-region-p)
    (flyspell-region beg end)
    (deactivate-mark))
   ((thing-at-point 'word)
    (call-interactively 'ispell-word))
   (t
    (call-interactively 'jp-spell-change-dictionary))))

(defun jp-spell-ispell-display-buffer (buffer)
  "Function to override `ispell-display-buffer' for BUFFER.
Use this as `advice-add' to override the aforementioned Ispell
function.  Then you can control the buffer's specifics via
`display-buffer-alist' (how it ought to be!)."
  (pop-to-buffer buffer)
  (set-window-point (get-buffer-window buffer) (point-min)))

(advice-add #'ispell-display-buffer :override #'jp-spell-ispell-display-buffer)

(provide 'jp-spell)
;;; jp-spell.el ends here
