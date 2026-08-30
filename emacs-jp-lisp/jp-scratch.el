;;; jp-scratch.el --- Scratch buffers for editable major mode of choice -*- lexical-binding: t -*-

;;; Commentary:
;;
;; Set up a scratch buffer for an editable major mode of choice.  The
;; idea is based on the `scratch.el' package by Ian Eure:
;; <https://github.com/ieure/scratch-el>.

;;; Code:

(require 'jp-common)

(defgroup jp-scratch ()
  "Scratch buffers for editable major mode of choice."
  :group 'editing)

(defcustom jp-scratch-default-mode 'text-mode
  "Default major mode for `jp-scratch-scratch-buffer'."
  :type 'symbol
  :group 'jp-scratch)

(defun jp-scratch--scratch-list-modes ()
  "List known major modes."
  (let (symbols)
    (mapatoms
     (lambda (symbol)
       (when (and (functionp symbol)
                  (or (provided-mode-derived-p symbol 'text-mode)
                      (provided-mode-derived-p symbol 'prog-mode)))
         (push symbol symbols))))
    symbols))

(defun jp-scratch--insert-comment ()
  "Insert comment for major mode, if appropriate.
Insert a comment if `comment-start' is non-nil and the buffer is
empty."
  (when (and (jp-common-empty-buffer-p) comment-start)
    (insert (format "Scratch buffer for: %s\n\n" major-mode))
    (goto-char (point-min))
    (comment-region (line-beginning-position) (line-end-position))))

(defun jp-scratch--prepare-buffer (region &optional mode)
  "Add contents to scratch buffer and name it accordingly.

REGION is added to the contents to the new buffer.

Use the current buffer's major mode by default.  With optional
MODE use that major mode instead."
  (let ((major (or mode major-mode)))
    (with-current-buffer (pop-to-buffer (format "*%s scratch*" major))
      (funcall major)
      (jp-scratch--insert-comment)
      (goto-char (point-max))
      (unless (string-empty-p region)
        (when (jp-common-line-regexp-p 'non-empty)
          (insert "\n\n"))
        (insert region)))))

(defvar jp-scratch--major-mode-history nil
  "Minibuffer history of `jp-scratch--major-mode-prompt'.")

(defun jp-scratch--major-mode-prompt ()
  "Prompt for major mode and return the choice as a symbol."
  (intern
   (completing-read "Select major mode: "
                    (jp-scratch--scratch-list-modes)
                    nil
                    :require-match
                    nil
                    'jp-scratch--major-mode-history)))

(defun jp-scratch--capture-region ()
  "Capture active region, else return empty string."
  (if (region-active-p)
      (buffer-substring-no-properties (region-beginning) (region-end))
    ""))

;;;###autoload
(defun jp-scratch-buffer (&optional arg)
  "Produce a scratch buffer matching the current major mode.

With optional ARG as a prefix argument (\\[universal-argument]),
use `jp-scratch-default-mode'.

With ARG as a double prefix argument, prompt for a major mode
with completion.  Candidates are derivatives of `text-mode' or
`prog-mode'.

If region is active, copy its contents to the new scratch
buffer.

Buffers are named as *MAJOR-MODE scratch*.  If one already exists
for the given MAJOR-MODE, any text is appended to it."
  (interactive "P")
  (let ((region (jp-scratch--capture-region)))
    (pcase (prefix-numeric-value arg)
      (16 (jp-scratch--prepare-buffer region (jp-scratch--major-mode-prompt)))
      (4 (jp-scratch--prepare-buffer region jp-scratch-default-mode))
      (_ (jp-scratch--prepare-buffer region)))))

(provide 'jp-scratch)
;;; jp-scratch.el ends here
