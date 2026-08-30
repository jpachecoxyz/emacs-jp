;;; jp-simple.el --- Common commands for my dotemacs -*- lexical-binding: t -*-

;; Copyright (C) 2020-2026  Javier Pacheco

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
;; Common commands for my Emacs: <https://jpachecoxyz.github.io>.

;;; Code:

(eval-when-compile
  (require 'cl-lib))
(require 'jp-common)

(defgroup jp-simple ()
  "Generic utilities for my dotemacs."
  :group 'editing)

(defcustom jp-simple-date-specifier "%F"
  "Date specifier for `format-time-string'.
Used by `jp-simple-inset-date'."
  :type 'string
  :group 'jp-simple)

(defcustom jp-simple-time-specifier "%R %z"
  "Time specifier for `format-time-string'.
Used by `jp-simple-inset-date'."
  :type 'string
  :group 'jp-simple)

;;; Commands

;;;; General commands

;;;###autoload
(defun jp-simple-describe-at-point (symbol)
  "Describe the SYMBOL at point.
If there is no symbol or the symbol at point does not satisfy `symbolp',
prompt for one."
  (interactive (list (intern-soft (thing-at-point 'symbol))))
  (if symbol
      (describe-symbol symbol)
    (call-interactively 'describe-symbol)))

;;;###autoload
(defun jp-simple-indent-dwim ()
  "Indent the current defun in `prog-mode' or paragraph in `text-mode'."
  (interactive)
  (save-excursion
    (cond
     ((derived-mode-p 'prog-mode)
      (mark-defun))
     ((derived-mode-p 'text-mode)
      (mark-paragraph)))
    (indent-for-tab-command)
    (deactivate-mark)))

;;;###autoload
(defun jp-simple-sudo ()
  "Find the current file or directory using `sudo'."
  (interactive)
  (let ((destination (or buffer-file-name default-directory))
        (auto-save-default nil))
    (if (string= (file-remote-p destination 'method) "sudo")
        (user-error "Already using `sudo'")
      (find-file (format "/sudo::/%s" destination)))))

(defun jp-simple--mark (bounds)
  "Mark between BOUNDS as a cons cell of beginning and end positions."
  (push-mark (car bounds))
  (goto-char (cdr bounds))
  (activate-mark))

;;;###autoload
(defun jp-simple-mark-sexp ()
  "Mark symbolic expression at or near point.
Repeat to extend the region forward to the next symbolic
expression."
  (interactive)
  (if (and (region-active-p)
           (eq last-command this-command))
      (ignore-errors (forward-sexp 1))
    (when-let* ((thing (cond
                        ((thing-at-point 'url) 'url)
                        ((thing-at-point 'sexp) 'sexp)
                        ((thing-at-point 'string) 'string)
                        ((thing-at-point 'word) 'word))))
      (jp-simple--mark (bounds-of-thing-at-point thing)))))

;;;###autoload
(defun jp-simple-keyboard-quit-dwim ()
  "Do-What-I-Mean behaviour for a general `keyboard-quit'.

The generic `keyboard-quit' does not do the expected thing when
the minibuffer is open.  Whereas we want it to close the
minibuffer, even without explicitly focusing it.

The DWIM behaviour of this command is as follows:

- When the region is active, disable it.

- When a minibuffer is open, but not focused, close the minibuffer.  For
  recursive minibuffers, make sure to only close one level of depth.

- When in a *Completions* or `special-mode' buffer (e.g. *Help* or
  *Messages*), close it.

- When the *Completions* or a `special-mode' buffer is on display but
  not selected, close it.  If there are more than one, close them all.

- In every other case use the regular `keyboard-quit'."
  (interactive)
  (cond
   ((region-active-p)
    (keyboard-quit))
   ((and (derived-mode-p 'completion-list-mode 'special-mode)
         (not (one-window-p)))
    (quit-window))
   ((when-let* ((_ (not (one-window-p)))
                (windows (seq-filter
                          (lambda (window)
                            (with-selected-window window
                              (derived-mode-p 'completion-list-mode 'special-mode)))
                          (window-list))))
      (dolist (window windows)
        (quit-window nil window))))
   ((> (minibuffer-depth) 0)
    (abort-recursive-edit))
   (t
    (keyboard-quit))))

;;;###autoload
(defun jp-simple-delete-window-dwim ()
  "Do What I Mean to delete the current THING.
When there is more than one window, THING is a window.
When there are more than one `tab-bar-mode' tabs, THING is a tab.
Else THING is a frame if frames are more than one."
  (declare (interactive-only t))
  (interactive)
  (cond
   ((length> (window-list) 1)
    (delete-window))
   ((and (featurep 'tab-bar)
         (length> (tab-bar-tabs) 1))
    (tab-close))
   ((length> (frame-list) 1)
    (delete-frame))
   (t
    (user-error "Nothing to delete"))))

;;;; Commands for lines

;;;###autoload
(defun jp-simple-new-line-below (n)
  "Create N empty lines below the current one.
When called interactively without a prefix numeric argument, N is
1."
  (interactive "p")
  (goto-char (line-end-position))
  (dotimes (_ n) (insert "\n")))

;;;###autoload
(defun jp-simple-new-line-above (n)
  "Create N empty lines above the current one.
When called interactively without a prefix numeric argument, N is
1."
  (interactive "p")
  (let ((point-min (point-min)))
    (if (or (bobp)
            (eq (point) point-min)
            (eq (line-number-at-pos point-min) 1))
        (progn
          (goto-char (line-beginning-position))
          (dotimes (_ n) (insert "\n"))
          (forward-line (- n)))
      (forward-line (- n))
      (jp-simple-new-line-below n))))

;;;###autoload
(defun jp-simple-copy-line ()
  "Copy the current line to the `kill-ring'."
  (interactive)
  (copy-region-as-kill (line-beginning-position) (line-end-position)))

(make-obsolete 'jp-simple-copy-line-or-region 'jp-simple-copy-line "2023-09-26")

;;;###autoload
(defun jp-simple-kill-ring-save (&optional beg end)
  "Copy the current region or line.
When the region is active, use `kill-ring-save' between the BEG and END
positions.  Otherwise, copy the current line."
  ;; NOTE 2025-02-23: Using (interactive "r") returns an error before
  ;; running the body of this function if there is no mark.  This
  ;; happens when visiting a file.
  (interactive
   (when (region-active-p)
     (list
      (region-beginning)
      (region-end))))
  (if (and beg end)
      (copy-region-as-kill beg end)
    (jp-simple-copy-line))
  (setq this-command 'kill-ring-save))

;;;###autoload
(defun jp-simple-kill-region (&optional beg end)
  "Do `kill-region' when the region is active, else `kill-ring-save' symbol at point."
  (interactive
   (when (region-active-p)
     (list
      (region-beginning)
      (region-end))))
  (if (and beg end)
      (kill-region beg end)
    (jp-simple-mark-sexp)
    (copy-region-as-kill (region-beginning) (region-end)))
  (setq this-command 'kill-ring-save))

(defun jp-simple--duplicate-buffer-substring (boundaries)
  "Duplicate buffer substring between BOUNDARIES.
BOUNDARIES is a cons cell representing buffer positions."
  (unless (consp boundaries)
    (error "`%s' is not a cons cell" boundaries))
  (let ((beg (car boundaries))
        (end (cdr boundaries)))
    (goto-char end)
    (newline)
    (insert (buffer-substring-no-properties beg end))))

;;;###autoload
(defun jp-simple-duplicate-line-or-region ()
  "Duplicate the current line or active region."
  (interactive)
  (unless mark-ring                  ; needed when entering a new buffer
    (push-mark (point) t nil))
  (jp-simple--duplicate-buffer-substring
   (if (region-active-p)
       (cons (region-beginning) (region-end))
     (cons (line-beginning-position) (line-end-position))))
  (setq this-command 'yank))

;;;###autoload
(defun jp-simple-yank-replace-line-or-region ()
  "Replace line or region with latest kill.
This command can then be followed by the standard
`yank-pop' (default is bound to \\[yank-pop])."
  (interactive)
  (if (use-region-p)
      (delete-region (region-beginning) (region-end))
    (delete-region (line-beginning-position) (line-end-position)))
  (yank)
  (setq this-command 'yank))

;;;###autoload
(defun jp-simple-multi-line-below ()
  "Move half a screen below."
  (interactive)
  (forward-line (floor (window-height) 2))
  (setq this-command 'scroll-up-command))

;;;###autoload
(defun jp-simple-multi-line-above ()
  "Move half a screen above."
  (interactive)
  (forward-line (- (floor (window-height) 2)))
  (setq this-command 'scroll-down-command))

;;;###autoload
(defun jp-simple-kill-line-backward ()
  "Kill from point to the beginning of the line."
  (interactive)
  (kill-line 0)
  (setq this-command 'kill-line))

;;;###autoload
(defun jp-simple-copy-line-forward (n)
  "Copy from point to the end of the Nth line.
Without numeric prefix argument N, operate on the current line."
  (interactive "p")
  (let ((point (point))
        (end (line-end-position n))
        (max (point-max)))
    (copy-region-as-kill
     point
     (if (> end max)
         max
       end)))
  (setq this-command 'kill-ring-save))

;;;###autoload
(defun jp-simple-copy-line-backward (n)
  "Copy from point to the beginning of the Nth line.
Without numeric prefix argument N, operate on the current line."
  (interactive "p")
  (let ((point (point))
        (beg (line-beginning-position n))
        (min (point-min)))
    (copy-region-as-kill
     point
     (if (< beg min)
         min
       beg)))
  (setq this-command 'kill-ring-save))

;;;###autoload
(defun jp-simple-delete-line ()
  "Delete (not kill) from point to the end of the line."
  (interactive)
  (let* ((point (point))
         (end (line-end-position))
         (end+ (+ end 1)))
    (cond
     ((> end+ (point-max)) (delete-region point end))
     ((= point end) (delete-region point end+))
     (t (delete-region point end))))
  (setq this-command 'delete-region))

;;;###autoload
(defun jp-simple-delete-line-backward ()
  "Delete (not kill) from point to the beginning of the line."
  (interactive)
  (let* ((point (point))
         (beg (line-beginning-position))
         (beg- (- beg 1)))
    (cond
     ((< beg- (point-min)) (delete-region beg point))
     ((= point beg) (delete-region beg- point))
     (t (delete-region beg point))))
  (setq this-command 'delete-region))

;;;###autoload
(define-minor-mode jp-simple-auto-fill-visual-line-mode
  "Enable `visual-line-mode' and disable `auto-fill-mode' in the current buffer."
  :global nil
  (if jp-simple-auto-fill-visual-line-mode
      (progn
        (auto-fill-mode -1)
        (visual-line-mode 1))
    (auto-fill-mode -1)
    (visual-line-mode -1)))

;;;; Commands for text insertion or manipulation

;;;###autoload
(defun jp-simple-insert-date (&optional arg)
  "Insert the current date as `jp-simple-date-specifier'.

With optional prefix ARG (\\[universal-argument]) also append the
current time understood as `jp-simple-time-specifier'.

When region is active, delete the highlighted text and replace it
with the specified date."
  (interactive "P")
  (let* ((date jp-simple-date-specifier)
         (time jp-simple-time-specifier)
         (format (if arg (format "%s %s" date time) date)))
    (when (use-region-p)
      (delete-region (region-beginning) (region-end)))
    (insert (format-time-string format))))

(defun jp-simple--pos-url-on-line (char)
  "Return position of `jp-common-url-regexp' at CHAR."
  (when (integer-or-marker-p char)
    (save-excursion
      (goto-char char)
      (re-search-forward jp-common-url-regexp (line-end-position) :noerror))))

;;;###autoload
(defun jp-simple-escape-url-line (char)
  "Escape all URLs or email addresses on the current line.
When called from Lisp CHAR is a buffer position to operate from
until the end of the line.  In interactive use, CHAR corresponds
to `line-beginning-position'."
  (interactive
   (list
    (if current-prefix-arg
        (re-search-forward
         jp-common-url-regexp
         (line-end-position) :no-error
         (prefix-numeric-value current-prefix-arg))
      (line-beginning-position))))
  (when-let* ((regexp-end (jp-simple--pos-url-on-line char)))
    (goto-char regexp-end)
    (unless (looking-at ">")
      (insert ">")
      (when (search-backward "\s" (line-beginning-position) :noerror)
        (forward-char 1))
      (insert "<"))
    (jp-simple-escape-url-line (1+ regexp-end)))
  (goto-char (line-end-position)))

;; Thanks to Bruno Boal for the original `jp-simple-escape-url-region'.
;; Check Bruno's Emacs config: <https://github.com/BBoal/emacs-config>.

;;;###autoload
(defun jp-simple-escape-url-region (&optional beg end)
  "Apply `jp-simple-escape-url-line' on region lines between BEG and END."
  (interactive
   (if (region-active-p)
       (list (region-beginning) (region-end))
     (error "There is no region!")))
  (let ((beg (min beg end))
        (end (max beg end)))
    (save-excursion
      (goto-char beg)
      (setq beg (line-beginning-position))
      (while (<= beg end)
        (jp-simple-escape-url-line beg)
        (beginning-of-line 2)
        (setq beg (point))))))

;;;###autoload
(defun jp-simple-escape-url-dwim ()
  "Escape URL on the current line or lines implied by the active region.
Call the commands `jp-simple-escape-url-line' and
`jp-simple-escape-url-region' ."
  (interactive)
  (if (region-active-p)
      (jp-simple-escape-url-region (region-beginning) (region-end))
    (jp-simple-escape-url-line (line-beginning-position))))

;;;###autoload
(defun jp-simple-zap-to-char-backward (char &optional arg)
  "Backward `zap-to-char' for CHAR.
Optional ARG is a numeric prefix to match ARGth occurance of
CHAR."
  (interactive
   (list
    (read-char-from-minibuffer "Zap to char: " nil 'read-char-history)
    (prefix-numeric-value current-prefix-arg)))
  (zap-to-char (- arg) char t))

(defvar jp-simple-flush-and-diff-history nil
  "Minibuffer history for `jp-simple-flush-and-diff'.")

;;;###autoload
(defun jp-simple-flush-and-diff (regexp beg end)
  "Call `flush-lines' for REGEXP and produce diff if file is modified.
When region is active, operate between the region boundaries
demarcated by BEG and END."
  (interactive
   (let ((regionp (region-active-p)))
     (list
      (read-regexp "Flush lines using REGEXP: " nil 'jp-simple-flush-and-diff-history)
      (and regionp (region-beginning))
      (and regionp (region-end)))))
  (flush-lines regexp (or beg (point-min)) (or end (point-max)) :no-message)
  (when (and (buffer-modified-p) buffer-file-name)
    (diff-buffer-with-file (current-buffer))))

;;;; Commands for object transposition

;; The "move" functions all the way to `jp-simple-move-below-dwim'
;; are courtesy of Bruno Boal: <https://git.sr.ht/~bboal>.  With minor
;; tweaks by me.
(defun jp-simple--move-line (count dir)
  "Move line or region COUNTth times in DIR direction."
  (let* ((start (pos-bol))
         (end (pos-eol))
         diff-eol-point
         diff-eol-mark)
    (when-let* (((use-region-p))
                (pos (point))
                (mrk (mark))
                (line-diff-mark-point (1+ (- (line-number-at-pos mrk)
                                             (line-number-at-pos pos)))))
      (if (> pos mrk)
          (setq start (pos-bol line-diff-mark-point)) ; pos-bol of where the mark is
        (setq end (pos-eol line-diff-mark-point)))    ; pos-eol of the line where the mark is
      (setq diff-eol-mark (1+ (- end mrk))))          ; 1+ to get the \n
    ;; this is valid for region or a single line
    (setq diff-eol-point (1+ (- end (point))))
    (let* ((max (point-max))
           (end (1+ end))
           (end (if (> end max) max end))
           (deactivate-mark)
           (lines (delete-and-extract-region start end)))
      (forward-line (* count dir))
      ;; Handle the special case when there isn't a newline as the eob.
      (when (and (eq (point) max)
                 (/= (current-column) 0))
        (insert "\n"))
      (insert lines)
      ;; if user provided a region
      (when diff-eol-mark
        (set-mark (- (point) diff-eol-mark)))
      ;; either way go to same point location reference initial motion
      (goto-char (- (point) diff-eol-point)))))

(defun jp-simple--move-line-user-error (boundary)
  "Return `user-error' with message accounting for BOUNDARY.
BOUNDARY is a buffer position, expected to be `point-min' or `point-max'."
  (when-let* ((bound (line-number-at-pos boundary))
              (scope (cond
                      ((and (use-region-p)
                            (or (= (line-number-at-pos (point)) bound)
                                (= (line-number-at-pos (mark)) bound)))
                       "region is ")
                      ((= (line-number-at-pos (point)) bound)
                       "")
                      (t nil))))
    (user-error (format "Warning: %salready in the last line!" scope))))

(defun jp-simple-move-above-dwim (arg)
  "Move line or region ARGth times up.
If ARG is nil, do it one time."
  (interactive "p")
  (unless (jp-simple--move-line-user-error (point-min))
    (jp-simple--move-line arg -1)))

(defun jp-simple-move-below-dwim (arg)
  "Move line or region ARGth times down.
If ARG is nil, do it one time."
  (interactive "p")
  (unless (jp-simple--move-line-user-error (point-max))
    (jp-simple--move-line arg 1)))

(defmacro jp-simple-define-transpose (scope)
  "Define transposition command for SCOPE.
SCOPE is the text object to operate on.  The command's name is
jp-simple-transpose-SCOPE."
  `(defun ,(intern (format "jp-simple-transpose-%s" scope)) (arg)
     ,(format "Transpose %s.
Transposition over an active region will swap the object at
the region beginning with the one at the region end." scope)
     (interactive "p")
     (let ((fn (intern (format "%s-%s" "transpose" ,scope))))
       (if (use-region-p)
           (funcall fn 0)
         (funcall fn arg)))))

;;;###autoload (autoload 'jp-simple-transpose-lines "jp-simple")
;;;###autoload (autoload 'jp-simple-transpose-paragraphs "jp-simple")
;;;###autoload (autoload 'jp-simple-transpose-sentences "jp-simple")
;;;###autoload (autoload 'jp-simple-transpose-sexps "jp-simple")
;;;###autoload (autoload 'jp-simple-transpose-words "jp-simple")
(jp-simple-define-transpose "lines")
(jp-simple-define-transpose "paragraphs")
(jp-simple-define-transpose "sentences")
(jp-simple-define-transpose "sexps")
(jp-simple-define-transpose "words")

;;;###autoload
(defun jp-simple-transpose-chars ()
  "Always transposes the two characters before point.
There is no dragging the character forward.  This is the
behaviour of `transpose-chars' when point is at the end of the
line."
  (interactive)
  (if (eq (point) (line-end-position))
      (transpose-chars 1)
    (transpose-chars -1)
    (forward-char)))

;;;; Commands for paragraphs

;;;###autoload
(defun jp-simple-unfill-region-or-paragraph ()
  "Unfill current paragraph or the active region."
  (interactive)
  (unless mark-ring ; needed when entering a new buffer
    (push-mark (point) t nil))
  (let ((fill-column most-positive-fixnum))
    (if (region-active-p)
        (fill-region (region-beginning) (region-end))
      (fill-paragraph))))

;;;; Commands for windows and pages

;;;###autoload
(defun jp-simple-other-window ()
  "Wrapper for `other-window' and `next-multiframe-window'.
If there is only one window and multiple frames, call
`next-multiframe-window'.  Otherwise, call `other-window'."
  (interactive)
  (if (and (one-window-p) (length> (frame-list) 1))
      (progn
        (call-interactively #'next-multiframe-window)
        (setq this-command #'next-multiframe-window))
    (call-interactively #'other-window)
    (setq this-command #'other-window)))

;;;###autoload
(defun jp-simple-narrow-visible-window ()
  "Narrow buffer to wisible window area.
Also check `jp-simple-narrow-dwim'."
  (interactive)
  (let* ((bounds (jp-common-window-bounds))
         (window-area (- (cdr bounds) (car bounds)))
         (buffer-area (- (point-max) (point-min))))
    (if (/= buffer-area window-area)
        (narrow-to-region (car bounds) (cdr bounds))
      (user-error "Buffer fits in the window; won't narrow"))))

;;;###autoload
(defun jp-simple-narrow-dwim ()
  "Do-what-I-mean narrowing.
If region is active, narrow the buffer to the region's
boundaries.

If pages are defined by virtue of `jp-common-page-p', narrow to
the current page boundaries.

If no region is active and no pages exist, narrow to the visible
portion of the window.

If narrowing is in effect, widen the view."
  (interactive)
  (unless mark-ring                  ; needed when entering a new buffer
    (push-mark (point) t nil))
  (cond
   ((and (use-region-p)
         (null (buffer-narrowed-p)))
    (narrow-to-region (region-beginning) (region-end)))
   ((jp-common-page-p)
    (narrow-to-page))
   ((null (buffer-narrowed-p))
    (jp-simple-narrow-visible-window))
   ((widen))))

(defun jp-simple--narrow-to-page (count &optional back)
  "Narrow to COUNTth page with optional BACK motion."
  (if back
      (narrow-to-page (or (- count) -1))
    (narrow-to-page (or (abs count) 1)))
  ;; Avoids the problem of skipping pages while cycling back and forth.
  (goto-char (point-min)))

;;;###autoload
(defun jp-simple-forward-page-dwim (&optional count)
  "Move to next or COUNTth page forward.
If buffer is narrowed to the page, keep the effect while
performing the motion.  Always move point to the beginning of the
narrowed page."
  (interactive "p")
  (if (buffer-narrowed-p)
      (jp-simple--narrow-to-page count)
    (forward-page count)
    (setq this-command 'forward-page)))

;;;###autoload
(defun jp-simple-backward-page-dwim (&optional count)
  "Move to previous or COUNTth page backward.
If buffer is narrowed to the page, keep the effect while
performing the motion.  Always move point to the beginning of the
narrowed page."
  (interactive "p")
  (if (buffer-narrowed-p)
      (jp-simple--narrow-to-page count t)
    (backward-page count)
    (setq this-command 'backward-page)))

;;;###autoload
(defun jp-simple-delete-page-delimiters (&optional beg end)
  "Delete lines with just page delimiters in the current buffer.
When region is active, only operate on the region between BEG and
END, representing the point and mark."
  (interactive "r")
  (let (b e)
    (if (use-region-p)
        (setq b beg
              e end)
      (setq b (point-min)
            e (point-max)))
    (widen)
    (flush-lines (format "%s$" page-delimiter) b e)
    (setq this-command 'flush-lines)))

;; NOTE 2023-06-18: The idea of narrowing to a defun in an indirect
;; buffer is still experimental.
(defun jp-simple-narrow--guess-defun-symbol ()
  "Try to return symbol of current defun as a string."
  (save-excursion
    (beginning-of-defun)
    (search-forward " ")
    (thing-at-point 'symbol :no-properties)))

;;;###autoload
(defun jp-simple-narrow-to-cloned-buffer ()
  "Narrow to defun in cloned buffer.
Name the buffer after the defun's symbol."
  (interactive)
  (clone-indirect-buffer-other-window
   (format "%s -- %s"
           (buffer-name)
           (jp-simple-narrow--guess-defun-symbol))
   :display)
  (narrow-to-defun))

;;;; Commands for buffers

(defun jp-simple--display-unsaved-buffers (buffers buffer-menu-name)
  "Produce buffer menu listing BUFFERS called BUFFER-MENU-NAME."
  (let ((old-buf (current-buffer))
        (buf (get-buffer-create buffer-menu-name)))
    (with-current-buffer buf
      (Buffer-menu-mode)
      (setq-local Buffer-menu-files-only nil
                  Buffer-menu-buffer-list buffers
                  Buffer-menu-filter-predicate nil)
      (list-buffers--refresh buffers old-buf)
      (tabulated-list-print))
    (display-buffer buf)))

(defun jp-simple--get-unsaved-buffers ()
  "Get list of unsaved buffers."
  (seq-filter
   (lambda (buffer)
     (and (buffer-file-name buffer)
          (buffer-modified-p buffer)))
   (buffer-list)))

;;;###autoload
(defun jp-simple-display-unsaved-buffers ()
  "Produce buffer menu listing unsaved file-visiting buffers."
  (interactive)
  (if-let* ((unsaved-buffers (jp-simple--get-unsaved-buffers)))
      (jp-simple--display-unsaved-buffers unsaved-buffers "*Unsaved buffers*")
    (message "No unsaved buffers")))

(defun jp-simple-display-unsaved-buffers-on-exit (&rest _)
  "Produce buffer menu listing unsaved file-visiting buffers.
Add this as :before advice to `save-buffers-kill-emacs'."
  (when-let* ((unsaved-buffers (jp-simple--get-unsaved-buffers)))
    (jp-simple--display-unsaved-buffers unsaved-buffers "*Unsaved buffers*")))

;;;###autoload
(defun jp-simple-copy-current-buffer-name ()
  "Add the current buffer's name to the `kill-ring'."
  (declare (interactive-only t))
  (interactive)
  (kill-new (buffer-name (current-buffer))))

;;;###autoload
(defun jp-simple-copy-current-buffer-file ()
  "Add the current buffer's file path to the `kill-ring'."
  (declare (interactive-only t))
  (interactive)
  (if buffer-file-name
      (kill-new buffer-file-name)
    (user-error "%s is not associated with a file" (buffer-name (current-buffer)))))

;;;###autoload
(defun jp-simple-kill-buffer (buffer)
  "Kill current BUFFER without confirmation.
When called interactively, prompt for BUFFER."
  (interactive (list (read-buffer "Select buffer: ")))
  (let ((kill-buffer-query-functions nil))
    (kill-buffer (or buffer (current-buffer)))))

(make-obsolete
 'jp-simple-kill-buffer-current
 'jp-simple-kill-buffer-dwim
 "2025-11-04")

;;;###autoload
(defun jp-simple-kill-buffer-dwim (&optional arg)
  "Kill current buffer.
With optional prefix ARG (\\[universal-argument]) delete the
buffer's window as well.  Kill the window regardless of ARG if it
satisfies `jp-common-window-small-p' and it has no previous
buffers in its history."
  (interactive "P")
  (let ((kill-buffer-query-functions nil))
    (cond
     ;; Is a tab whose last window's buffer is to be deleted.
     ((and (one-window-p)
           (length> (tab-bar-tabs) 1))
      (let ((buffer (current-buffer)))
        (tab-close)
        (kill-buffer buffer)))
     ;; Is an ancillary window that appeared for this buffer but is
     ;; otherwise not supposed to be there.
     ((and (jp-common-window-small-p)
           (null (window-prev-buffers)))
      (kill-buffer-and-window))
     (t
      (kill-buffer)))))

;;;###autoload
(defun jp-simple-copy-current-path ()
  "Copy the current absolute path.
If in a file-visiting buffer, copy the `buffer-file-name'.  Else copy
the `default-directory'."
  (declare (interactive-only t))
  (interactive)
  (let ((path (or buffer-file-name default-directory)))
    (kill-new path)
    (message "Copied `%s'" (propertize path 'face 'success))))

;;;###autoload
(defun jp-simple-rename-file-and-buffer (name)
  "Apply NAME to current file and rename its buffer.
Do not try to make a new directory or anything fancy."
  (interactive
   (list (read-string "Rename current file: " (buffer-file-name))))
  (let ((file (buffer-file-name)))
    (if (vc-registered file)
        (vc-rename-file file name)
      (rename-file file name))
    (set-visited-file-name name t t)))

(defun jp-simple--buffer-major-mode-prompt ()
  "Prompt of `jp-simple-buffers-major-mode'.
Limit list of buffers to those matching the current
`major-mode' or its derivatives."
  (let ((read-buffer-function nil)
        (current-major-mode major-mode))
    (read-buffer
     (format "Buffer for %s: " major-mode)
     nil
     :require-match
     (lambda (pair) ; pair is (name-string . buffer-object)
       (with-current-buffer (cdr pair)
         (derived-mode-p current-major-mode))))))

;;;###autoload
(defun jp-simple-buffers-major-mode ()
  "Select BUFFER matching the current one's major mode."
  (interactive)
  (switch-to-buffer (jp-simple--buffer-major-mode-prompt)))

(defun jp-simple--buffer-vc-root-prompt ()
  "Prompt of `jp-simple-buffers-vc-root'."
  (let ((root (or (vc-root-dir)
                  (locate-dominating-file "." ".git")))
        (read-buffer-function nil))
    (read-buffer
     (format "Buffers in %s: " root)
     nil t
     (lambda (pair) ; pair is (name-string . buffer-object)
       (with-current-buffer (cdr pair) (string-match-p root default-directory))))))

;;;###autoload
(defun jp-simple-buffers-vc-root ()
  "Select buffer matching the current one's VC root."
  (interactive)
  (switch-to-buffer (jp-simple--buffer-vc-root-prompt)))

;;;###autoload
(defun jp-simple-swap-window-buffers (counter)
  "Swap states of live buffers.
With two windows, transpose their buffers.  With more windows,
perform a clockwise rotation.  Do not alter the window layout.
Just move the buffers around.

With COUNTER as a prefix argument, do the rotation
counter-clockwise."
  (interactive "P")
  (when-let* ((winlist (if counter (reverse (window-list)) (window-list)))
              (wincount (count-windows))
              ((> wincount 1)))
    (dotimes (i (- wincount 1))
      (window-swap-states (elt winlist i) (elt winlist (+ i 1))))))

;;;; Commands of a general nature

(autoload 'color-rgb-to-hex "color")
(autoload 'color-name-to-rgb "color")

(defun jp-simple-accessible-colors (variant)
  "Return list of accessible `defined-colors'.
VARIANT is either `dark' or `light'."
  (let ((variant-color (if (eq variant 'black) "#000000" "#ffffff")))
    (seq-filter
     (lambda (c)
       (let* ((rgb (color-name-to-rgb c))
              (r (nth 0 rgb))
              (g (nth 1 rgb))
              (b (nth 2 rgb))
              (hex (color-rgb-to-hex r g b 2)))
         (when (>= (jp-common-contrast variant-color hex) 4.5)
           c)))
     (defined-colors))))

(defun jp-simple--list-accessible-colors-prompt ()
  "Use `read-multiple-choice' to return white or black background."
  (intern
   (cadr
    (read-multiple-choice
     "Variant"
     '((?b "black" "Black background")
       (?w "white" "White background"))
     "Choose between white or black background."))))

;;;###autoload
(defun jp-simple-list-accessible-colors (variant)
  "Return buffer with list of accessible `defined-colors'.
VARIANT is either `dark' or `light'."
  (interactive (list (jp-simple--list-accessible-colors-prompt)))
  (list-colors-display (jp-simple-accessible-colors variant)))

(defun jp-simple-update-package-repositories-pull (package package-directory buffer)
  "Pull PACKAGE which extends PACKAGE-DIRECTORY.
Use BUFFER for standard output and return the exit code."
  (let ((default-directory package-directory))
    (message "Pulling %s from directory %s" package default-directory)
    (call-process "git" nil (list buffer t) nil "pull")))

(defun jp-simple-update-package-repositories-clone (package base-directory buffer)
  "Clone PACKAGE to an extension of BASE-DIRECTORY.
Use BUFFER for standard output and return the exit code."
  (message "Cloning %s to directory %s" package base-directory)
  (call-process "git" nil (list buffer t) nil "clone" (format "git@github.com:jpachecoxyz/%s %s" package base-directory)))

(define-error 'jp-package-no-update "Package could not be updated" 'error)

(defun jp-simple-update-package-repositories-subr (packages)
  "Pull or clone all repositories of my PACKAGES."
  (unless (executable-find "git")
    (user-error "Cannot find git program; install it first or add it to the $PATH; aborting"))
  (unless (getenv "SSH_AUTH_SOCK")
    (user-error "Cannot find $SSH_AUTH_SOCK; check your SSH connection; aborting"))
  (let ((stdout (get-buffer-create " *jp-simple-git-package-stdout*")))
    (dolist (package packages)
      (let* ((name (cond
                    ((symbolp package) (symbol-name package))
                    ((stringp package) package)
                    (t (error "The `%s' is neither a symbol nor a string" package))))
             (common-directory (expand-file-name "~/Git/Projects/"))
             (package-directory (expand-file-name name common-directory))
             (exit-code (if (file-directory-p package-directory)
                            (jp-simple-update-package-repositories-pull package package-directory stdout)
                          (jp-simple-update-package-repositories-clone package common-directory stdout))))
        (condition-case error-data
            (when (> exit-code 0)
              (signal 'jp-package-no-update (list (format "Package `%s' got exit code `%s'" package exit-code))))
          (:success
           (message "Updated `%s' repository" package))
          (jp-package-no-update
           ;; TODO 2025-11-06: Is it safe to stash changes outright?
           ;; I think it is fine, but maybe there is a case where this
           ;; can lead to data loss?
           (when (file-directory-p package-directory)
             (let ((default-directory package-directory))
               (unless (fboundp 'vc-git-stash)
                 (require 'vc-git))
               (vc-git-stash (format "jp-package-update %s: %s" (format-time-string "%FT%T") package))))
           (message "Tried to stash changes in package `%s' because: %s" package (cdr error-data)))
          ((error user-error)
           (message "The package `%s' returned error data: %s" package error-data))
          (quit
           (message "Aborted by the user")))))))

(defvar jp-simple-update-package-repositories-prompt-history nil
  "Minibuffer history of `jp-simple-update-package-repositories-prompt'.")

(defun jp-simple-update-package-repositories-prompt ()
  "Prompt for packages among `jp-emacs-my-packages'."
  (let ((default (car jp-simple-update-package-repositories-prompt-history)))
    (completing-read-multiple
     (format-prompt "Select packages" default)
     jp-emacs-my-packages
     nil t nil
     'jp-simple-update-package-repositories-prompt-history
     default)))

;;;###autoload
(defun jp-simple-update-some-or-all-of-my-package-repositories (packages &optional all-packages)
  "Prompt for PACKAGES among `jp-emacs-my-packages' to pull or clone.
With a universal prefix argument for ALL-PACKAGES, do not prompt for packages and
update them all instead."
  (interactive
   (list
    (if current-prefix-arg
        jp-emacs-my-packages
      (jp-simple-update-package-repositories-prompt))))
  (jp-simple-update-package-repositories-subr packages))

;;;; Global minor mode to override key maps

(defvar jp-simple-override-mode-map (make-sparse-keymap)
  "Key map of `jp-simple-override-mode'.
Enable that mode to have its key bindings take effect over those of the
major mode.")

(define-minor-mode jp-simple-override-mode
  "Enable the `jp-simple-override-mode-map'."
  :init-value nil
  :global t
  :keymap jp-simple-override-mode-map)

;;;; Preview hexadecimal RGB colours

;; FIXME 2026-01-10: Why is this not working in Org tables?  The
;; properties are applied but the face is not displayed.
(defun jp-simple-hex-fontify (limit)
  "Colorea el código hexadecimal completo hasta LIMIT."
  (when (re-search-forward "#\\([a-fA-F0-9]\\{6\\}\\)" limit t)
    (let* ((beg (match-beginning 0)) ;; Inicio en el '#'
           (end (match-end 0))       ;; Fin tras el sexto dígito
           (color (match-string-no-properties 0))
           ;; Usamos :foreground "white" para que el texto sea legible sobre el fondo
           (face (list :background color :foreground "white")))
      (add-text-properties beg end (list 'face face 'font-lock-face face))
      t)))

(defun jp-simple-hex-unfontify ()
  "Limpia las propiedades de visualización en todo el buffer."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "#\\([a-fA-F0-9]\\{6\\}\\)" nil t)
      ;; Eliminamos las propiedades de color y cualquier rastro de 'display
      (remove-text-properties (match-beginning 0) (match-end 0) 
                              '(face nil font-lock-face nil display nil)))))

(defvar jp-simple-hex-color-keywords
  '((jp-simple-hex-fontify))
  "Font lock keywords for `jp-simple-hex-color-mode'.")

(define-minor-mode jp-simple-hex-color-mode
  "Preview hexadecimal colour values."
  :global nil
  :init-value nil
  (if jp-simple-hex-color-mode
      (font-lock-add-keywords nil jp-simple-hex-color-keywords)
    (jp-simple-hex-unfontify)
    (font-lock-remove-keywords nil jp-simple-hex-color-keywords))
  (font-lock-flush (point-min) (point-max)))

(provide 'jp-simple)
;;; jp-simple.el ends here
