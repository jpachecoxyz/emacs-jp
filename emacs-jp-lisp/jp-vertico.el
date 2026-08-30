;;; jp-vertico.el --- Custom Vertico extras -*- lexical-binding: t -*-

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;;; Code:

(require 'vertico)

(defvar jp-vertico-multiform-minimal
  '(unobtrusive
    (vertico-flat-format . ( :multiple  ""
                             :single    ""
                             :prompt    ""
                             :separator ""
                             :ellipsis  ""
                             :no-match  ""))
    (vertico-preselect . prompt))
  "List of configurations for minimal Vertico multiform.
The minimal view is intended to be more private or less
revealing.  This is important when, for example, a prompt shows
names of people.  Of course, such a view also provides a minimal
style for general usage.

Toggle the vertical view with the `vertico-multiform-vertical'
command or use the commands `jp-vertico-private-next' and
`jp-vertico-private-previous', which toggle the vertical view
automatically.")

(defvar jp-vertico-multiform-maximal
  '((vertico-count . 10)
    (vertico-preselect . directory)
    (vertico-resize . t))
  "List of configurations for maximal Vertico multiform.")

(defun jp-vertico-private-next ()
  "Like `vertico-next' but toggle vertical view if needed.
This is done to accommodate `jp-vertico-multiform-minimal'."
  (interactive)
  (if vertico-unobtrusive-mode
      (progn
        (vertico-multiform-vertical)
        (vertico-next 1))
    (vertico-next 1)))

(defun jp-vertico-private-previous ()
  "Like `vertico-previous' but toggle vertical view if needed.
This is done to accommodate `jp-vertico-multiform-minimal'."
  (interactive)
  (if vertico-unobtrusive-mode
      (progn
        (vertico-multiform-vertical)
        (vertico-previous 1))
    (vertico-previous 1)))

(defun jp-vertico-private-complete ()
  "Expand contents and show remaining candidates, if needed.
This is done to accommodate `jp-vertico-multiform-minimal'."
  (interactive)
  (if (and vertico-unobtrusive-mode (> vertico--total 1))
      (progn
        (minibuffer-complete)
        (jp-vertico-private-next))
    (vertico-insert)))

(defun jp-vertico-private-exit ()
  "Exit with the candidate if `jp-vertico-multiform-minimal'.
If there are more candidates that match the given input, expand the
minibuffer to show the remaining candidates and select the first one.
Else do `vertico-exit'."
  (interactive)
  (cond
   ((and (= vertico--total 1)
         (not (eq 'file (vertico--metadata-get 'category))))
    (minibuffer-complete)
    (vertico-exit))
   ((and vertico-unobtrusive-mode
         (not minibuffer--require-match)
         (or (string-empty-p (minibuffer-contents))
             minibuffer-default
             (eq vertico-preselect 'directory)
             (eq vertico-preselect 'prompt)))
    (vertico-exit-input))
   ((and vertico-unobtrusive-mode (> vertico--total 1))
    (minibuffer-complete-and-exit)
    (jp-vertico-private-next))
   (t
    (vertico-exit))))

;; (cl-defgeneric vertico--display-candidates (lines)
;;   "Reverse the default vertico view of LINES."
;;   (move-overlay vertico--candidates-ov (point-min) (point-min))
;;   ;; (setq lines (nreverse lines))
;;   (unless (eq vertico-resize t)
;;     (setq lines (nconc (make-list (max 0 (- vertico-count (length lines))) "\n") lines)))
;;   (let ((string (apply #'concat lines)))
;;     (add-face-text-property 0 (length string) 'default 'append string)
;;     (overlay-put vertico--candidates-ov 'before-string string)
;;     (overlay-put vertico--candidates-ov 'after-string nil)))

(provide 'jp-vertico)
;;; jp-vertico.el ends here
