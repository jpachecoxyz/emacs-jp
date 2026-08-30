;;; jp-abbrev.el --- Functions for use with abbrev-mode -*- lexical-binding: t -*-

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
;; Functions for use with `abbrev-mode'.

;;; Code:

(defgroup jp-abbrev ()
  "Functions for use with `abbrev-mode'."
  :group 'editing)

(defcustom jp-abbrev-time-specifier "%R"
  "Time specifier for `format-time-string'."
  :type 'string
  :group 'jp-abbrev)

(defcustom jp-abbrev-date-specifier "%F"
  "Date specifier for `format-time-string'."
  :type 'string
  :group 'jp-abbrev)

(defun jp-abbrev-current-time ()
  "Insert the current time per `jp-abbrev-time-specifier'."
  (insert (format-time-string jp-abbrev-time-specifier)))

(defun jp-abbrev-current-date ()
  "Insert the current date per `jp-abbrev-date-specifier'."
  (insert (format-time-string jp-abbrev-date-specifier)))

(defun jp-abbrev-jitsi-link ()
  "Insert a Jitsi link."
  (insert (concat "https://meet.jit.si/" (format-time-string "%Y%m%dT%H%M%S"))))

(defvar jp-abbrev-update-html-history nil
  "Minibuffer history for `jp-abbrev-update-html-prompt'.")

(defun jp-abbrev-update-html-prompt ()
  "Minibuffer prompt for `jp-abbrev-update-html'.
Use completion among previous entries, retrieving their data from
`jp-abbrev-update-html-history'."
  (completing-read
   "Insert update for manual: "
   jp-abbrev-update-html-history
   nil nil nil 'jp-abbrev-update-html-history))

(defun jp-abbrev-update-html ()
  "Insert message to update NAME.html page, by prompting for NAME."
  (insert (format "Update %s.html" (jp-abbrev-update-html-prompt))))

(defvar jp-abbrev-org-macro-key-history nil
  "Minibuffer history for `jp-abbrev-org-macro-key-prompt'.")

(defun jp-abbrev-org-macro-key-prompt ()
  "Minibuffer prompt for `jp-abbrev-org-macro-key'.
Use completion among previous entries, retrieving their data from
`jp-abbrev-org-macro-key-history'."
  (completing-read
   "Key binding: "
   jp-abbrev-org-macro-key-history
   nil nil nil 'jp-abbrev-org-macro-key-history))

(defvar jp-abbrev-org-macro-key-symbol-history nil
  "Minibuffer history for `jp-abbrev-org-macro-key-symbol-prompt'.")

(defun jp-abbrev-org-macro-key-symbol-prompt ()
  "Minibuffer prompt for `jp-abbrev-org-macro-key'.
Use completion among previous entries, retrieving their data from
`jp-abbrev-org-macro-key-symbol-history'."
  (completing-read
   "Command name: "
   jp-abbrev-org-macro-key-symbol-history
   nil nil nil 'jp-abbrev-org-macro-key-symbol-history))

(defun jp-abbrev-org-macro-key-command ()
  "Insert {{{kbd(KEY)}}} (~SYMBOL~) by prompting for KEY and SYMBOL."
  (insert (format "{{{kbd(%s)}}} (~%s~)"
                  (jp-abbrev-org-macro-key-prompt)
                  (jp-abbrev-org-macro-key-symbol-prompt))))

(defun jp-abbrev-org-macro-key ()
  "Insert {{{kbd(KEY)}}} by prompting for KEY."
  (insert (format "{{{kbd(%s)}}}" (jp-abbrev-org-macro-key-prompt))))

(provide 'jp-abbrev)
;;; jp-abbrev.el ends here
