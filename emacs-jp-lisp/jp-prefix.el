;;; jp-prefix.el --- Prefix keymap for my dotemacs -*- lexical-binding: t -*-

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
;; Prefix keymap for my custom keymaps.

;;; Code:

(declare-function jp-simple-kill-buffer-current "jp-simple" (&optional arg))
(declare-function jp-simple-rename-file-and-buffer "jp-simple" (name))
(declare-function jp-simple-buffers-major-mode "jp-simple")
(declare-function jp-simple-buffers-vc-root "jp-simple")
(declare-function beframe-buffer-menu "beframe" (&optional frame &key sort))

(defvar-keymap jp-prefix-buffer-map
  :doc "Prefix keymap for buffers."
  :name "Buffer"
  :prefix 'jp-prefix-buffer
  "m" #'beframe-buffer-menu
  "b" #'switch-to-buffer
  "B" #'jp-simple-buffers-major-mode
  "c" #'clone-indirect-buffer-other-window
  "f" #'fit-window-to-buffer
  "k" #'jp-simple-kill-buffer-current
  "g" #'revert-buffer-quick
  "r" #'jp-simple-rename-file-and-buffer
  "n" #'next-buffer
  "p" #'previous-buffer
  "v" #'jp-simple-buffers-vc-root)

(defvar-keymap jp-prefix-file-map
  :doc "Prefix keymaps for files."
  :name "File"
  :prefix 'jp-prefix-file
  "f" #'find-file
  "F" #'find-file-other-window
  "b" #'bookmark-jump
  "d" #'dired
  "l" #'find-library
  "m" #'man)

(defvar-keymap jp-prefix-insert-map
  :doc "Prefix keymap for character insertion."
  :name "Insert"
  :prefix 'jp-prefix-insert
  "i" #'insert-char
  "e" #'emoji-search
  "q" #'quoted-insert
  "s" #'emoji-search
  "l" #'emoji-list)

(declare-function logos-focus-mode "logos")
(declare-function keycast-mode-line-mode "keycast")
(declare-function rainbow-mode "rainbow")
(declare-function spacious-padding-mode "spacious-padding")

(defvar-keymap jp-prefix-mode-map
  :doc "Prefix keymap for minor mode toggles."
  :name "Toggle"
  :prefix 'jp-prefix-mode
  "f" #'flymake-mode
  "h" #'hl-line-mode
  "k" #'keycast-mode-line-mode
  "l" #'logos-focus-mode
  "m" #'menu-bar-mode
  "n" #'display-line-numbers-mode
  "t" #'toggle-truncate-lines
  "s" #'spacious-padding-mode
  "r" #'rainbow-mode
  "v" #'variable-pitch-mode)

(defvar-keymap jp-prefix-window-map
  :doc "Prefix keymap for windows."
  :name "Window"
  :prefix 'jp-prefix-window
  "u" #'winner-undo
  "r" #'winner-redo
  "b" #'balance-windows-area
  "d" #'toggle-window-dedicated
  "0" #'delete-window
  "1" #'delete-other-windows
  "!" #'delete-other-windows-vertically
  "2" #'split-window-below
  "@" #'split-root-window-below
  "3" #'split-window-right
  "#" #'split-root-window-right
  "o" #'other-window
  "^" #'tear-off-window
  "h" #'windmove-left
  "j" #'windmove-down
  "k" #'windmove-up
  "l" #'windmove-right
  "H" #'windmove-swap-states-left
  "J" #'windmove-swap-states-down
  "K" #'windmove-swap-states-up
  "L" #'windmove-swap-states-right)

(declare-function consult-find "consult" (&optional dir initial))
(declare-function consult-ripgrep "consult" (&optional dir initial))
(declare-function jp-search-grep "jp-search" (regexp &optional recursive))
(declare-function jp-search-grep-todo-keywords "jp-search" (&optional arg))
(declare-function jp-search-occur-browse-url "jp-search")
(declare-function jp-search-occur-outline "jp-search" (&optional arg))
(declare-function jp-simple-flush-and-diff "jp-simple" (regexp beg end))

(defvar-keymap jp-prefix-search-map
  :doc "Prefix keymap for search (and replace) commands."
  :name "Search"
  :prefix 'jp-prefix-search
  "f" #'consult-find
  "d" #'jp-simple-flush-and-diff
  "g" #'jp-search-grep
  "o" #'jp-search-occur-outline
  "r" #'consult-ripgrep
  "t" #'jp-search-grep-todo-keywords
  "u" #'jp-search-occur-browse-url)

(declare-function jp-simple-transpose-chars "jp-simple")
(declare-function jp-simple-transpose-lines "jp-simple" (arg))
(declare-function jp-simple-transpose-paragraphs "jp-simple" (arg))
(declare-function jp-simple-transpose-sentences "jp-simple" (arg))
(declare-function jp-simple-transpose-words "jp-simple" (arg))
(declare-function jp-simple-transpose-sexps "jp-simple" (arg))

(defvar-keymap jp-prefix-transpose-map
  :doc "Prefix keymap for object transposition."
  :name "Transpose"
  :prefix 'jp-prefix-transpose
  "c" #'jp-simple-transpose-chars
  "l" #'jp-simple-transpose-lines
  "p" #'jp-simple-transpose-paragraphs
  "s" #'jp-simple-transpose-sentences
  "w" #'jp-simple-transpose-words
  "x" #'jp-simple-transpose-sexps)

(defvar-keymap jp-prefix-expression-map
  :doc "Prefix keymap for s-expression motions."
  :name "S-EXP"
  :prefix 'jp-prefix-expression
  "a" #'beginning-of-defun
  "e" #'end-of-defun
  "f" #'forward-sexp
  "b" #'backward-sexp
  "n" #'forward-list
  "p" #'backward-list
  "d" #'up-list ; confusing name for what looks "out and down" to me
  "t" #'transpose-sexps
  "u" #'backward-up-list ; the actual "up"
  "k" #'kill-sexp
  "DEL" #'backward-kill-sexp)

(declare-function winner-undo "winner")
(declare-function winner-redo "winner")
(declare-function magit-status "magit" (&optional directory cache))
(declare-function jp-simple-other-windor-or-frame "jp-simple")

;; NOTE 2024-02-17: Some cons cells here have a symbol as a `cdr' and
;; some do not.  The former are those which define a prefix command
;; (per `define-prefix-command').  This is a symbol that references
;; the keymaps, thus making our binding an indirection: if we update
;; the key map, we automatically get the new key bindings.  Whereas
;; when we bind a key to the value of a variable, we have to update
;; the key map and then the binding for changes to propagate.
(defvar-keymap jp-prefix-map
  :doc "Prefix keymap with multiple subkeymaps."
  :name "Prot Prefix"
  :prefix 'jp-prefix
  "0" #'delete-window
  "1" #'delete-other-windows
  "!" #'delete-other-windows-vertically
  "^" #'tear-off-window
  "2" #'split-window-below
  "@" #'split-root-window-below
  "3" #'split-window-right
  "#" #'split-root-window-right
  "o" #'other-window
  "O" #'jp-simple-other-windor-or-frame
  "Q" #'save-buffers-kill-emacs
  "b" (cons "Buffer" 'jp-prefix-buffer)
  "c" #'world-clock
  "f" (cons "File" 'jp-prefix-file)
  "g" #'magit-status
  "h" (cons "Help" help-map)
  "i" (cons "Insert" 'jp-prefix-insert)
  "j" #'dired-jump
  "m" (cons "Minor modes" 'jp-prefix-mode)
  "n" (cons "Narrow" narrow-map)
  "p" (cons "Project" project-prefix-map)
  "r" (cons "Rect/Registers" ctl-x-r-map)
  "s" (cons "Search" 'jp-prefix-search)
  "t" (cons "Transpose" 'jp-prefix-transpose)
  "u" #'universal-argument
  "v" (cons "Version Control" 'vc-prefix-map)
  "w" (cons "Window" 'jp-prefix-window)
  "x" (cons "S-EXP" 'jp-prefix-expression))

;; ;; NOTE 2024-02-17: This is not needed anymore, because I bind a cons
;; ;; cell to the key.  The `car' of it is the description, which
;; ;; `which-key-mode' understands.
;;
;; (with-eval-after-load 'which-key
;;   (which-key-add-keymap-based-replacements jp-prefix-map
;;     "b" `("Buffer" . ,jp-prefix-buffer-map)
;;     "f" `("File" . ,jp-prefix-file-map)
;;     "h" `("Help" . ,help-map)
;;     "i" `("Insert" . ,jp-prefix-insert-map)
;;     "m" `("Mode" . ,jp-prefix-mode-map)
;;     "n" `("Narrow" . ,narrow-map)
;;     "p" `("Project" . ,project-prefix-map)
;;     "r" `("C-x r" . ,ctl-x-r-map)
;;     "s" `("Search" . ,jp-prefix-search-map)
;;     "t" `("Transpose" . ,jp-prefix-transpose-map)
;;     "v" `("C-x v" . ,vc-prefix-map)
;;     "w" `("Window" . ,jp-prefix-window-map)
;;     "x" `("S-EXP" . ,jp-prefix-expression-map)))

;; What follows is an older experiment with transient.  I like its
;; visuals, though find it hard to extend.  Keymaps are easier for me,
;; as I can add commands to one of the subkeymaps and they are readily
;; available without evaluating anything else.  Probably transient can
;; do this, though it is not obvious to me as to how.

;; (require 'transient)
;;
;; (transient-define-prefix jp-prefix-file nil
;;   "Transient with file commands."
;;   [["File or directory"
;;     ("f" "find-file" find-file)
;;     ("F" "find-file-other-window" find-file-other-window)]
;;    ["Directory only"
;;     ("d" "dired" dired)
;;     ("D" "dired-other-window" dired-other-window)]
;;    ["Documentation"
;;     ("l" "find-library" find-library)
;;     ("m" "man" man)]])
;;
;; (transient-define-prefix jp-prefix-buffer nil
;;   "Transient with buffer commands."
;;   [["Switch"
;;     ("b" "switch buffer" switch-to-buffer)
;;     ("B" "switch buf other window" switch-to-buffer-other-window)
;;     ("n" "next-buffer" next-buffer)
;;     ("p" "previous-buffer" previous-buffer)
;;     ("m" "buffer-menu" buffer-menu)
;;     ("q" "bury-buffer" bury-buffer)]
;;    ["Persist"
;;     ("c" "clone buffer" clone-indirect-buffer)
;;     ("C" "clone buf other window" clone-indirect-buffer-other-window)
;;     ("r" "rename-buffer" rename-buffer)
;;     ("R" "rename-uniquely" rename-uniquely)
;;     ("s" "save-buffer" save-buffer)
;;     ("w" "write-file" write-file)]
;;    ["Destroy"
;;     ("k" "kill-current-buffer" kill-current-buffer)
;;     ("K" "kill-buffer-and-window" kill-buffer-and-window)
;;     ("r" "revert-buffer" revert-buffer)]])
;;
;; (transient-define-prefix jp-prefix-search nil
;;   "Transient with search commands."
;;   [["Search"
;;     ("s" "isearch-forward" isearch-forward)
;;     ("S" "isearch-forward-regexp" isearch-forward-regexp)
;;     ("r" "isearch-backward" isearch-backward)
;;     ("R" "isearch-backward-regexp" isearch-backward-regexp)
;;     ("o" "occur" occur)]
;;    ["Edit"
;;     ("f" "flush-lines" flush-lines)
;;     ("k" "keep-lines" keep-lines)
;;     ("q" "query-replace" query-replace)
;;     ("Q" "query-replace-regexp" query-replace-regexp)]])
;;
;; (transient-define-prefix jp-prefix-window nil
;;   "Transient with window commands."
;;   [["Manage"
;;     ("b" "balance-windows" balance-windows)
;;     ("f" "fit-window-to-buffer" fit-window-to-buffer)
;;     ("t" "tear-off-window" tear-off-window)]
;;    ["Popup"
;;     ("c" "calc" calc)
;;     ("f" "list-faces-display" list-faces-display)
;;     ("r" "re-builder" re-builder)
;;     ("w" "world-clock" world-clock)]])
;;
;; ;; This is independent of the transient, though still useful.
;; (defvar-keymap jp-prefix-repeat-map
;;   :doc "Global prefix map for repeatable keybindings (per `repeat-mode')."
;;   :name "Repeat"
;;   :repeat t
;;   "n" #'next-buffer
;;   "p" #'previous-buffer
;;   "<down>" #'enlarge-window
;;   "<right>" #'enlarge-window-horizontally
;;   "<up>" #'shrink-window
;;   "<left>" #'shrink-window-horizontally)
;;
;; (transient-define-prefix jp-prefix-toggle nil
;;   "Transient with minor mode toggles."
;;   [["Interface"
;;     ("c" "context-menu-mode" context-menu-mode)
;;     ("m" "menu-bar-mode" menu-bar-mode)
;;     ("s" "scroll-bar-mode" scroll-bar-mode)
;;     ("C-t" "tool-bar-mode" tool-bar-mode)]
;;    ["Tools"
;;     ("d" "toggle-debug-on-error" toggle-debug-on-error)
;;     ("f" "follow-mode" follow-mode)
;;     ("l" "visual-line-mode" visual-line-mode)
;;     ("v" "variable-pitch-mode" variable-pitch-mode)
;;     ("t" "toggle-truncate-lines" toggle-truncate-lines)
;;     ("C-s" "window-toggle-side-windows" window-toggle-side-windows)]])
;;
;; (transient-define-prefix jp-prefix nil
;;   "Transient with common commands.
;; Commands that bring up transients have ... in their description."
;;   [["Common"
;;     ("b" "Buffer..." jp-prefix-buffer)
;;     ("f" "File..." jp-prefix-file)
;;     ("s" "Search..." jp-prefix-search)
;;     ("w" "Window..." jp-prefix-window)
;;     ("t" "Toggle..." jp-prefix-toggle)]
;;    ["Resize"
;;     ("   <up>" "Shrink vertically" shrink-window)
;;     (" <down>" "Enlarge vertically" enlarge-window)
;;     (" <left>" "Shrink horizontally" shrink-window-horizontally)
;;     ("<right>" "Enlarge horizontally" enlarge-window-horizontally)]
;;    ["Misc"
;;     ("e" "Emoji transient..." emoji-insert)
;;     ("E" "Emoji search" emoji-search)
;;     ("C-e" "Emoji buffer" emoji-list)
;;     ("RET" "Insert unicode" insert-char)
;;     ("\\" "toggle-input-method" toggle-input-method)]])

(provide 'jp-prefix)
;;; jp-prefix.el ends here
