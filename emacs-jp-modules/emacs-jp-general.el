;;; emacs-jp-general.el --- General keybindings with the general package -*- lexical-binding: t; -*-

;;; Commentary:

;; Leader key (SPC) bindings and misc keybindings built on top of the
;; `general' package.  This relies on evil, org, consult, magit, denote
;; and friends; the commands are resolved lazily at call time, so no
;; extra `use-package' declarations are required here.

;;; Code:

(use-package general
  :config
  (require 'general)
  ;; (general-evil-setup)

  (with-eval-after-load 'org
    (define-key org-mode-map (kbd "C-j") nil)
    (define-key org-mode-map (kbd "C-k") nil)
    (define-key org-mode-map (kbd "M-l") nil))

  (general-define-key
   :states '(normal insert motion)
   "C-h" #'evil-window-left
   "C-j" #'evil-window-down
   "C-k" #'evil-window-up
   "M-j" #'move-line-down
   "M-k" #'move-line-up
   "C-l" #'evil-window-right
   "M-l" #'org-make-olist)

  (general-define-key
   :states '(normal)
   "SPC SPC" #'my/org-edit-toggle
   "g V" #'cycle-region-preview
   "C-;" #'devdocs-lookup
   "C-\\" #'ispell-comment-or-string-at-point
   "<backspace>" #'org-mark-ring-goto
   "K" #'my-show-doc-or-describe-symbol)

  (general-define-key
   :states '(normal visual)
   "<" "<gv"
   ">" ">gv")

  (define-key evil-insert-state-map (kbd "C-c C-c") #'evil-normal-state)

  (define-key evil-visual-state-map (kbd "<")
    (lambda ()
      (interactive)
      (evil-shift-left (region-beginning) (region-end))
      (evil-normal-state)
      (evil-visual-restore)))

  (define-key evil-visual-state-map (kbd ">")
    (lambda ()
      (interactive)
      (evil-shift-right (region-beginning) (region-end))
      (evil-normal-state)
      (evil-visual-restore)))

  ;; Leader key
  (general-create-definer user/leader-keys
    :states '(normal insert visual emacs)
    :keymaps 'override
    :prefix "SPC"
    :global-prefix "C-SPC")

  (user/leader-keys
    "." '(find-file :wk "Find file")
    "u" '(universal-argument :wk "Universal argument"))

  (evil-define-key '(normal visual) 'global
    (kbd "g c c") #'evilnc-comment-or-uncomment-lines)

  (evil-define-key '(visual) 'global
    (kbd "g c") #'evilnc-comment-or-uncomment-lines)

  (user/leader-keys
    "a" '(:ignore t :wk "Ellama A.I.")
    "a a" '(ellama-ask-about :wk "Ask ellama about region")
    "a e" '(:ignore t :wk "Ellama enhance")
    "a e g" '(ellama-improve-grammar :wk "Improve grammar")
    "a e w" '(ellama-improve-wording :wk "Improve wording")
    "a c a" '(ellama-code-add :wk "Code add")
    "a c i" '(ellama-code-improve :wk "Code improve")
    "a i" '(ellama-chat :wk "Chat")
    "a p" '(ellama-provider-select :wk "Select provider")
    "a s" '(ellama-summarize :wk "Summarize region")
    "a t" '(ellama-translate :wk "Translate region"))

  (user/leader-keys
    "j" '(:ignore t :wk "Jump")
    "j l" '(avy-goto-line :wk "Goto line")
    "j w" '(avy-goto-char-2 :wk "Goto word"))

  (user/leader-keys
    "b" '(:ignore t :wk "Buffers")
    "b b" '(consult-buffer :wk "Switch buffer")
    "b c" '(ispell-buffer :wk "Spell check buffer")
    "b C" '(clone-indirect-buffer-other-window :wk "Clone buffer")
    "b d" '(bookmark-delete :wk "Delete bookmark")
    "b i" '(ibuffer :wk "Ibuffer")
    "b k" '(kill-current-buffer :wk "Kill buffer")
    "b K" '(kill-some-buffers :wk "Kill multiple buffers")
    "b l" '(list-bookmarks :wk "List bookmarks")
    "b m" '(bookmark-set :wk "Set bookmark")
    "b n" '(next-buffer :wk "Next buffer")
    "b p" '(previous-buffer :wk "Previous buffer")
    "b r" '(revert-buffer :wk "Reload buffer")
    "b R" '(rename-buffer :wk "Rename buffer")
    "b s" '(consult-org-heading :wk "Save buffer")
    "b S" '(save-some-buffers :wk "Save buffers")
    "b w" '(bookmark-save :wk "Save bookmarks"))

  (user/leader-keys
    "d" '(:ignore t :wk "Dired")
    "d d" '(dired :wk "Open dired")
    "d f" '(wdired-finish-edit :wk "Finish wdired")
    "d p" '(peep-dired :wk "Peep dired")
    "d w" '(wdired-change-to-wdired-mode :wk "Writable dired"))

  (user/leader-keys
    "e" '(:ignore t :wk "Eval / Eshell / EWW")
    "e b" '(eval-buffer :wk "Eval buffer")
    "e d" '(eval-defun :wk "Eval defun")
    "e e" '(eval-expression :wk "Eval expression")
    "e f" '(open-specific-dired :wk "Edit config files")
    "e o" '(open-org-files :wk "Open org files")
    "e l" '(eval-last-sexp :wk "Eval last sexp")
    "e r" '(eval-region :wk "Eval region")
    "e R" '(eww-reload :wk "Reload EWW")
    "e s" '(term-toggle-eshell :wk "Eshell")
    "e w" '(eww :wk "EWW"))

  (user/leader-keys
    "f" '(:ignore t :wk "Files")
    "f e" '((lambda () (interactive) (dired "~/.emacs.d")) :wk "Open config dir")
    "f d" '(find-grep-dired :wk "Search string in DIR")
    "f f" '(my/transient-goto-file-buffer :wk "Find file/buffer")
    "f g" '(counsel-grep-or-swiper :wk "Search in file")
    "f r" '(recentf :wk "Recent files")
    "f u" '(sudo-edit-find-file :wk "Sudo find file")
    "f n" '(consult-denote-find :wk "Find denote")
    "f U" '(sudo-edit :wk "Sudo edit"))

  (user/leader-keys
    "g" '(:ignore t :wk "Git")
    "g g" '(magit-status :wk "Magit status")
    "g b" '(magit-branch-checkout :wk "Checkout branch")
    "g c c" '(magit-commit-create :wk "Commit")
    "g d" '(magit-diff-buffer-file :wk "Diff file")
    "g F" '(magit-fetch :wk "Fetch")
    "g l" '(magit-log-buffer-file :wk "Log buffer")
    "g r" '(vc-revert :wk "Revert file")
    "g s" '(magit-stage-file :wk "Stage file")
    "g t" '(git-timemachine :wk "Time machine"))

  ;; Dired vim-like navigation
  (user/leader-keys
    :keymaps 'dired-mode-map
    :prefix "g"
    "h" '((lambda () (interactive) (dired "~/")) :wk "Go to Home")
    "c" '((lambda () (interactive) (dired "~/.config/")) :wk "Go to .config")
    "d" '((lambda () (interactive) (dired "~/.dotfiles")) :wk "Go to dotfiles")
    "f" '((lambda () (interactive) (dired "~/.config/emacs/")) :wk "Go to Emacs config")
    "e" '((lambda () (interactive) (dired "~/Documents/Emacs/")) :wk "Go to Documents")
    "s" '((lambda () (interactive) (dired "~/.local/src/")) :wk "Go to local src")
    "t" '((lambda () (interactive) (dired "~/.local/share/Trash/")) :wk "Go to Trash")
    "g" '(evil-goto-first-line :wk "Go to first line")
    "G" '(evil-goto-line       :wk "Go to last line"))

  (user/leader-keys
    "h" '(:ignore t :wk "Help")
    "h b" '(describe-bindings :wk "Describe bindings")
    "h c" '(describe-char :wk "Describe char")
    "h f" '(describe-function :wk "Describe function")
    "h F" '(describe-face :wk "Describe face")
    "h i" '(info :wk "Info")
    "h k" '(describe-key :wk "Describe key")
    "h m" '(describe-mode :wk "Describe mode")
    "h v" '(describe-variable :wk "Describe variable"))

  (user/leader-keys
    "m" '(:ignore t :wk "Org")
    "m a" '(org-agenda :wk "Org agenda")
    "m e" '(org-export-dispatch :wk "Org export")
    "m i" '(org-toggle-item :wk "Toggle item")
    "m t" '(org-todo :wk "Todo")
    "m B" '(org-babel-tangle :wk "Tangle")
    "m T" '(org-todo-list :wk "Todo list"))

  (user/leader-keys
    "o" '(:ignore t :wk "Open")
    "o -" '(dired-jump :wk "Jump to dired")
    "o f" '(make-frame :wk "New frame")
    "o i" '(jp/mu4e-direct-inbox :wk "Open Mail INBOX")
    "o t" '(jp-toggle-vterm :wk "Toggle terminal")
    "o s" '(toggle-scratch-buffer :wk "Toggle scratch")
    "o e" '(toggle-org-buffer :wk "Toggle org"))

  (user/leader-keys
    "p" '(:ignore t :wk "Projectile")
    "p a" '(projectile-add-known-project :wk "Add project"))

  (user/leader-keys
    "r" '(:ignore t :wk "Denote")
    "r f" '(denote-open-or-create :wk "Open note")
    "r u" '(denote-explore-network :wk "Explore network")
    "r m" '(denote-menu-list-notes :wk "Denote menu")
    "r i" '(denote-insert-link :wk "Insert link"))

  (user/leader-keys
    "s" '(:ignore t :wk "Search")
    "s d" '(dictionary-search :wk "Dictionary")
    "s m" '(man :wk "Man page")
    "s t" '(tldr :wk "TLDR docs")
    "s w" '(woman :wk "Woman docs"))

  (user/leader-keys
    "t" '(:ignore t :wk "Toggle")
    "t f" '(flycheck-mode :wk "Flycheck")
    "t l" '(display-line-numbers-mode :wk "Line numbers")
    "t r" '(rainbow-mode :wk "Rainbow")
    "t t" '(vterm-toggle :wk "Terminal"))

  (user/leader-keys
    "w" '(:ignore t :wk "Windows")
    "w c" '(evil-window-delete :wk "Close window")
    "w n" '(evil-window-new :wk "New window")
    "w s" '(evil-window-split :wk "Split horizontal")
    "w v" '(evil-window-vsplit :wk "Split vertical")
    "w h" '(evil-window-left :wk "Left")
    "w j" '(evil-window-down :wk "Down")
    "w k" '(evil-window-up :wk "Up")
    "w l" '(evil-window-right :wk "Right")
    "w w" '(evil-window-next :wk "Next window"))

  (user/leader-keys
    "q" '(:ignore t :wk "Quit")
    "q r" '(restart-emacs :wk "Restart Emacs")
    "q q" '(kill-emacs :wk "Exit Emacs")))

(provide 'emacs-jp-general)

;;; emacs-jp-general.el ends here
