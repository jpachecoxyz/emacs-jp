;;; jp-coach.el --- Code for my personal coaching sessions -*- lexical-binding: t -*-

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
;; Code for my personal coaching sessions: <https://protesilaos.com/coach>.
;;
;; Remember that every piece of Elisp that I write is for my own
;; educational and recreational purposes.  I am not a programmer and I
;; do not recommend that you copy any of this if you are not certain of
;; what it does.

;;; Code:

;;;; Jitsi link

(declare-function message-fetch-field "message" (header &optional first))
(declare-function notmuch-show-get-header "notmuch-show")

(defvar jp-coach--name-prompt-history nil
  "Minibuffer history of `jp-coach-name-prompt'.")

(defun jp-coach--name-prompt-default ()
  "Return default value for `jp-coach-name-prompt'."
  (when-let* ((from (cond
                     ((derived-mode-p 'message-mode)
                      (message-fetch-field "To"))
                     ((derived-mode-p 'notmuch-show-mode)
                      (notmuch-show-get-header :From)))))
    (string-clean-whitespace (car (split-string from "<")))))

(defun jp-coach-name-prompt ()
  "Prompt for student name."
  (let ((def (jp-coach--name-prompt-default)))
    (read-string
     (format-prompt "Name of student" def)
     nil 'jp-coach--name-prompt-history def)))

(defun jp-coach-get-identifier ()
  "Return identifier as YYYYmmddTHHMMSS.
This is the Denote identifier I use practically everywhere:
https://protesilaos.com/emacs/denote."
  (format-time-string "%Y%m%dT%H%M%S"))

;; I copied the "slug" functions from my denote.el.
(defconst jp-coach-excluded-punctuation-regexp "[][{}!@#$%^&*()=+'\"?,.\|;:~`‘’“”/]*"
  "Punctionation that is removed from file names.
We consider those characters illegal for our purposes.")

(defvar jp-coach-excluded-punctuation-extra-regexp nil
  "Additional punctuation that is removed from file names.
This variable is for advanced users who need to extend the
`jp-coach-excluded-punctuation-regexp'.  Once we have a better
understanding of what we should be omitting, we will update
things accordingly.")

(defun jp-coach--slug-no-punct (str)
  "Convert STR to a file name slug."
  (replace-regexp-in-string
   (concat jp-coach-excluded-punctuation-regexp
           jp-coach-excluded-punctuation-extra-regexp)
   "" str))

(defun jp-coach--slug-hyphenate (str)
  "Replace spaces and underscores with hyphens in STR.
Also replace multiple hyphens with a single one and remove any
leading and trailing hyphen."
  (replace-regexp-in-string
   "^-\\|-$" ""
   (replace-regexp-in-string
    "-\\{2,\\}" "-"
    (replace-regexp-in-string "_\\|\s+" "-" str))))

(defun jp-coach-sluggify (str)
  "Make STR an appropriate slug for file names and related."
  (downcase (jp-coach--slug-hyphenate (jp-coach--slug-no-punct str))))

(defun jp-coach--format-jitsi (name)
  "Format a Jitsi link with a unique identifier that includes NAME."
  (format "https://meet.jit.si/%s--%s"
          (jp-coach-get-identifier)
          (jp-coach-sluggify name)))

;;;###autoload
(defun jp-coach-jitsi-link (name)
  "Insert Jitsi link for NAME person."
  (interactive (list (jp-coach-name-prompt)))
  (insert (jp-coach--format-jitsi name)))

;;;; Time tables

(require 'org)

;; FIXME 2023-03-29: Can this work with logbooks for repeatable
;; entries?
(defun jp-coach--get-deadline-and-close (&optional name)
  "Get time stamps of deadline and closed for optional NAME.
Omit entries with a CANCEL state."
  (org-with-point-at (point)
    (when-let* ((case-fold-search t)
                (heading (org-no-properties
                          (org-get-heading :no-tags :no-todo :no-priority :no-comment)))
                ((string-match-p (or name ".*") heading))
                (deadline (org-entry-get nil "DEADLINE"))
                (closed (org-entry-get nil "CLOSED"))
                ((not (string= (org-entry-get nil "TODO") "CANCEL"))))
      (list heading (format "%s" deadline) (format "%s" closed)))))

(defun jp-coach--print-table-with-sessions (name sessions)
  "Return time table for NAME given SESSIONS."
  (let ((buf (get-buffer-create (format "*jp-coach with %s" name))))
    (with-current-buffer buf
      (org-mode)
      (erase-buffer)
      (goto-char (point-min))
      (insert "# Type C-c C-c in the TBLFM line to produce the table\n\n")
      (insert "* Cost without counting minutes\n")
      (insert (concat
               "\n"
               "| Description | Started | Closed | Days | Hours | Cost (EUR) |" "\n"
               "|-------------+---------+--------+------+-------+------------|" "\n"))
      (mapc
       (lambda (session)
         (insert (format "| %s | %s | %s |\n"
                         (nth 0 session)
                         (nth 1 session)
                         (nth 2 session))))
       sessions)
      (insert (concat "|-+" "\n"
                      "| " "\n"
                      "#+TBLFM: $4=date($3) - date($2) :: $5=86400 * $4;U"
                      ":: @>$5=vsum(@<<..@>>);U :: $6=$5*20;N :: @>$>=vsum(@<<..@>>)"
                      ":: @>$1='(length (org-lookup-all \".*\" '(@<<$1..@>>$1) nil 'string-match-p))"
                      "\n"))
      (org-table-recalculate-buffer-tables))
    (pop-to-buffer buf)))

;;;###autoload
(defun jp-coach-done-sessions-with-person ()
  "Produce buffer with time table for a given student."
  (declare (interactive-only t))
  (interactive)
  (when-let* ((file (buffer-file-name))
              (dir (file-name-directory file))
              ((string-match-p "coach" file))
              ((or (member file org-agenda-files)
                   ;; NOTE 2023-03-29: This assumes the file paths are
                   ;; absolute and end with a directory delimiter.
                   (member dir org-agenda-files)))
              (name (jp-coach-name-prompt)))
    (let (sessions)
      (org-map-entries
       (lambda ()
         (when-let* ((entry (jp-coach--get-deadline-and-close name)))
           (push entry sessions))))
      (jp-coach--print-table-with-sessions name sessions))))

(provide 'jp-coach)
;;; jp-coach.el ends here
