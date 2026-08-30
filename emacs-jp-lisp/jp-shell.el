;;; jp-shell.el --- M-x shell extensions for my dotemacs -*- lexical-binding: t -*-

;; Copyright (C) 2023-2026  Javier Pacheco

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
;; This covers my shell.el extensions, for use in my Emacs setup:
;; <https://jpachecoxyz.github.io>.

;;; Code:

(require 'shell)

;;;; Helper functions

(defun jp-shell--beginning-of-prompt-p ()
  "Return non-nil if point is at the beginning of a shell prompt."
  (if comint-use-prompt-regexp
      (looking-back comint-prompt-regexp (line-beginning-position))
    (eq (point) (comint-line-beginning-position))))

(defun jp-shell--insert-and-send (&rest args)
  "Insert and execute ARGS in the last shell prompt.
ARGS is a list of strings."
  (if (jp-shell--beginning-of-prompt-p)
      (progn
        (insert (mapconcat #'identity args " "))
        (comint-send-input))
    (user-error "Not at the beginning of prompt; won't insert: %s" args)))

(defun jp-shell--last-input ()
  "Return last input as a string."
  (buffer-substring-no-properties
   comint-last-input-start
   comint-last-input-end))

;;;; Input from shell command history using completion

(defun jp-shell--build-input-history ()
  "Return `comint-input-ring' as a list."
  (when (and (ring-p comint-input-ring)
	         (not (ring-empty-p comint-input-ring)))
    (let (history)
      ;; We have to build up a list ourselves from the ring vector.
      (dotimes (index (ring-length comint-input-ring))
        (push (ring-ref comint-input-ring index) history))
      (delete-dups history))))

(defvar jp-shell--input-history-completion-history nil
  "Minibuffer history of `jp-shell--input-history-prompt'.
Not to be confused with the shell input history, which is stored
in the `comint-input-ring' (see `jp-shell--build-input-history').")

(defun jp-shell--input-history-prompt ()
  "Prompt for completion against `jp-shell--build-input-history'."
  (let* ((history (jp-shell--build-input-history))
         (default (car history)))
    (completing-read
     (format-prompt "Insert input from history" default)
     history nil :require-match nil
     'jp-shell--input-history-completion-history
     default)))

;;;###autoload
(defun jp-shell-input-from-history ()
  "Insert command from shell input history.
Only account for the history Emacs knows about, ignoring
`comint-input-ring-file-name' (e.g. ~/.bash_history)."
  (declare (interactive-only t))
  (interactive)
  (jp-shell--insert-and-send
   (jp-shell--input-history-prompt)))

;;;; Directory navigation

;;;;; Directory tracking

(defvar jp-shell-cd-directories nil
  "List of accumulated `shell-last-dir'.")

(with-eval-after-load 'savehist
  (add-to-list 'savehist-additional-variables 'jp-shell-cd-directories))

(defun jp-shell-track-cd (&rest _)
  "Track shell input of cd commands.
Push `shell-last-dir' to `jp-shell-cd-directories'."
  (when-let* ((input (jp-shell--last-input))
              ((string-match-p "cd " input)))
    (push shell-last-dir jp-shell-cd-directories)))

(defun jp-shell-update-name-on-cd (&rest _)
  "Update the shell buffer name after a cd for use in `jp-shell'."
  (when-let* ((input (jp-shell--last-input))
              ((string-match-p "cd " input)))
    (rename-buffer (format "*jp-shell in %s*" default-directory) :make-unique)))

(defvar jp-shell--cd-history nil
  "Minibuffer history for `jp-shell-cd'.")

(defun jp-shell--cd-prompt ()
  "Prompt for a directory among `jp-shell-cd-directories'."
  (if-let* ((history jp-shell-cd-directories)
            (dirs (cons default-directory history))
            (def (if (listp dirs) (car dirs) shell-last-dir)))
      (completing-read
       (format-prompt "Select directory" def)
       dirs nil :require-match nil 'jp-shell--cd-history def)
    (user-error "No directories have been tracked")))

;;;###autoload
(defun jp-shell-cd ()
  "Switch to `jp-shell-cd-directories' using minibuffer completion."
  (declare (interactive-only t))
  (interactive)
  (jp-shell--insert-and-send
   "cd"
   (jp-shell--cd-prompt)))

;;;;; VC root directory

(defun jp-shell--get-vc-root-dir ()
  "Return `vc-root-dir' or root of present Git repository."
  (or (vc-root-dir)
      (locate-dominating-file "." ".git")))

;;;###autoload
(defun jp-shell-cd-vc-root-dir ()
  "Change into the `vc-root-dir'."
  (interactive)
  (if-let* ((root (jp-shell--get-vc-root-dir)))
      (jp-shell--insert-and-send "cd" root)
    (user-error "Cannot find the VC root of `%s'" default-directory)))

;; NOTE 2025-06-23: Emacs 31 supports shell bookmarks, so I no longer
;; need this.  I am keeping it here for reference.

;; ;;;; Bookmark support
;;
;; ;; NOTE 2023-08-18: I sent this to the Emacs maintainers as a patch
;; ;; (bug#65039).  I received approval to proceed with the change, but I
;; ;; did not do it because a user reported an issue with SSH (TRAMP).  I
;; ;; do not have access to SSH and am not familiar with such workflows.
;; ;; If/when that changes, I will try again.  In the meantime, this is
;; ;; good code and it works for me.
;;
;; ;; Adapted from esh-mode.el
;; (declare-function bookmark-prop-get "bookmark" (bookmark prop))
;;
;; (defun jp-shell-bookmark-name ()
;;   "Return name of bookmark based on currect directory."
;;   (format "jp-shell-%s"
;;           (file-name-nondirectory
;;            (directory-file-name
;;             (file-name-directory default-directory)))))
;;
;; (defvar sh-shell-file)
;;
;; (defun jp-shell-bookmark-make-record ()
;;   "Create a bookmark for the current Shell buffer."
;;   `(,(jp-shell-bookmark-name)
;;     (location . ,default-directory)
;;     (shell-file-name . ,sh-shell-file)
;;     (handler . jp-shell-bookmark-jump)))
;;
;; ;;;###autoload
;; (defun jp-shell-bookmark-jump (bookmark)
;;   "Default BOOKMARK handler for Shell buffers."
;;   (let ((default-directory (bookmark-prop-get bookmark 'location))
;;         (explicit-shell-file-name (bookmark-prop-get bookmark 'shell-file-name)))
;;     (shell (get-buffer-create (car bookmark)))))
;;
;; (put 'jp-shell-bookmark-jump 'bookmark-handler-type "Shell")

;; ;;;; Convert YouTube links to Invidious
;;
;; (defvar jp-shell-invidious-domains
;;   '("invidious.io.lol"
;;     "invidious.lunar.icu"
;;     "iv.nboeck.de"
;;     "vid.priv.au"
;;     "invidious.tiekoetter.com"
;;     "inv.in.projectsegfau.lt"
;;     "onion.tube"
;;     "yt.artemislena.eu"
;;     "invidious.no-logs.com"
;;     "yewtu.be"
;;     "invidious.projectsegfau.lt"
;;     "yt.oelrichsgarcia.de"
;;     "invidious.0011.lt"
;;     "inv.zzls.xyz"
;;     "inv.bp.projectsegfau.lt"
;;     "invidious.flokinet.to"
;;     "iv.ggtyler.dev"
;;     "invidious.slipfox.xyz"
;;     "vid.puffyan.us"
;;     "inv.pistasjis.net"
;;     "inv.citw.lgbt"
;;     "invidious.protokolla.fi"
;;     "inv.makerlab.tech"
;;     "inv.tux.pizza"
;;     "invidious.privacydev.net")
;;   "List of Invidious domains.")
;;
;; (defvar jp-shell-youtube-domains
;;   '("www.youtube.com"
;;     "youtu.be")
;;   "List of YouTube domains.")
;;
;; (defvar jp-shell-yt-invidious-domains
;;   (append jp-shell-youtube-domains
;;           jp-shell-invidious-domains)
;;   "List of YouTube and Invidious domains.")
;;
;; (defun jp-shell--get-random-invidious-instance ()
;;   "Return `random' index from `jp-shell-invidious-domains'."
;;   (nth
;;    (random (length jp-shell-invidious-domains))
;;    jp-shell-invidious-domains))
;;
;; ;;;###autoload
;; (defun jp-shell-invidious ()
;;   "Convert `jp-shell-yt-invidious-domains' into a random Invidious instance."
;;   (interactive)
;;   (save-excursion
;;     (goto-char (line-beginning-position))
;;     (while (re-search-forward (regexp-opt jp-shell-yt-invidious-domains) (line-end-position) :no-error)
;;       (replace-match (jp-shell--get-random-invidious-instance)))))

;;;; Built-in Emacs commands

;; ;; `comint-input-filter-functions'
;; (defun jp-shell--intercept-input (input)
;;   (when (string-match-p "man " input)
;;     (comint-interrupt-subjob)
;;     ;; TODO 2023-08-18: The idea is to interrupt the input, and split
;;     ;; it such that, say, "man echo" becomes (man "echo")
;;     ;;
;;     ;; (let ((proc (get-buffer-process (current-buffer)))
;; 	;;       (inhibit-read-only t)
;; 	;;       replacement)
;;     ;;   (save-excursion
;;     ;;     (let ((pmark (progn (goto-char (process-mark proc))
;; 	;; 		                (forward-line 0)
;; 	;; 		                (point-marker))))
;; 	;;       (delete-region comint-last-input-end pmark)
;; 	;;       (goto-char (process-mark proc))
;; 	;;       (setq replacement (concat "*** Called command externally ***\n"
;; 	;; 			                    (buffer-substring pmark (point))))
;; 	;;       (delete-region pmark (point))))
;;     ;;   (comint-output-filter proc replacement))
;;     ))
;;
;; (add-hook 'comint-input-filter-functions #'jp-shell--intercept-input)

;;;; General commands

(defun jp-shell--history-or-motion (history-fn motion-fn arg)
  "Call HISTORY-FN or MOTION-FN with ARG depending on where point is.
If `jp-shell--beginning-of-prompt-p' returns non-nil call
HISTORY-FN, else MOTION-FN."
  (let ((fn (if (or (jp-shell--beginning-of-prompt-p)
                    (eq last-command 'comint-next-input)
                    (eq last-command 'comint-previous-input))
                history-fn
              motion-fn)))
    (funcall-interactively fn arg)
    (setq this-command fn)))

;;;###autoload
(defun jp-shell-up-dwim (arg)
  "Return previous ARGth history input or go ARGth lines up.
If point is at the beginning of a shell prompt, return previous
input, otherwise perform buffer motion."
  (interactive "^p")
  (jp-shell--history-or-motion 'comint-previous-input 'previous-line arg))

;;;###autoload
(defun jp-shell-down-dwim (arg)
  "Return next ARGth history input or or go ARGth lines down.
If point is at the beginning of a shell prompt, return previous
input, otherwise perform buffer motion."
  (interactive "^p")
  (jp-shell--history-or-motion 'comint-next-input 'next-line arg))

;;;###autoload
(defun jp-shell ()
  "Like `shell' but always start a new shell.
Name the shell buffer after the `default-directory'.  If the name of
that buffer already exists, then reuse it."
  (interactive)
  (with-current-buffer (shell (format "*jp-shell in %s*" default-directory))
    (add-hook 'comint-output-filter-functions #'jp-shell-update-name-on-cd nil :local)))

;;;; Minor mode setup

(defvar-keymap jp-shell-mode-map
  :doc "Key map for `jp-shell-mode'."
  "<up>" #'jp-shell-up-dwim
  "<down>" #'jp-shell-down-dwim
  "C-c C-d" #'jp-shell-cd
  ;; "C-c C-i" #'jp-shell-invidious
  "C-c C-j" #'jp-shell-input-from-history
  "C-c C-." #'jp-shell-cd-vc-root-dir
  "C-c C-r" #'jp-shell-cd-vc-root-dir)

(define-minor-mode jp-shell-mode
  "Provide extra functionality for the Emacs `shell'.
Add a bookmark handler for shell buffer and activate the
`jp-shell-mode-map':
\\{jp-shell-mode-map}"
  :init-value nil
  :global nil
  (if jp-shell-mode
      (progn
        (add-hook 'comint-output-filter-functions #'jp-shell-track-cd nil :local)
        (setq-local bookmark-make-record-function #'jp-shell-bookmark-make-record))
    (remove-hook 'comint-output-filter-functions #'jp-shell-track-cd :local)
    (setq-local bookmark-make-record-function nil)))

(provide 'jp-shell)
;;; jp-shell.el ends here
