;;; emacs-jp-evil.el --- Evil-modal keybindings -*- lexical-binding: t; -*-

;;; Commentary:

;; Vi emulation on top of Emacs, with evil-collection to bind evil
;; keys across the many major modes, plus a few extensions:
;; evil-nerd-commenter, evil-numbers and evil-surround.

;;; Code:

(use-package evil
  :config
  (evil-mode 1))

;;; `evil-collection' must be declared/loaded before any of the
;;; `evil-collection-define-key' calls below, otherwise those helpers
;;; are not yet defined when the associated `with-eval-after-load'
;;; handlers run.
(use-package evil-collection
  :config
  (evil-collection-init))

(setq evil-want-keybinding nil)
(setq evil-vsplit-window-right t)
(setq evil-split-window-below t)
(setq evil-mode-line-format nil)
(setq evil-undo-system 'undo-redo)

(defun jp/org-tab-dwim ()
  (interactive)
  (or (yas-expand)
      (org-cycle)))

(with-eval-after-load 'evil
  (evil-define-key '(normal insert) lisp-interaction-mode-map
    (kbd "C-j") #'jp-elisp-eval-and-print-last-sexp))

;;; Dired binds
(with-eval-after-load 'dired
  (evil-collection-define-key 'normal 'dired-mode-map
    "l" 'dired-find-file
    "h" 'dired-up-directory))

(with-eval-after-load 'org
  (evil-define-key '(normal insert) org-mode-map
    (kbd "TAB") #'jp/org-tab-dwim
    (kbd "<backtab>") #'org-shifttab))

(with-eval-after-load 'org-agenda
  (evil-define-key 'normal org-agenda-mode-map
    (kbd "<tab>")     #'org-agenda-next-item
    (kbd "TAB")       #'org-agenda-next-item
    (kbd "<backtab>") #'org-agenda-previous-item
    (kbd "S-TAB")     #'org-agenda-previous-item))

(use-package evil-nerd-commenter)

(use-package evil-numbers)

(use-package evil-surround
  :config
  (global-evil-surround-mode 1))

(with-eval-after-load 'evil
  (define-key evil-normal-state-map (kbd "C-a") #'evil-numbers/inc-at-pt)
  (define-key evil-normal-state-map (kbd "C-s") #'evil-numbers/dec-at-pt))

;; Using RETURN to follow links in Org/Evil
(with-eval-after-load 'evil-maps
  (define-key evil-motion-state-map (kbd "SPC") nil)
  (define-key evil-motion-state-map (kbd "RET") nil)
  (define-key evil-motion-state-map (kbd "TAB") nil))

(setq evil-normal-state-tag   (propertize " Normal " 'face 'jp-modeline-indicator-cyan-bg)
      evil-insert-state-tag   (propertize " Insert " 'face 'jp-modeline-indicator-yellow-bg)
      evil-visual-state-tag   (propertize " Visual " 'face 'jp-modeline-indicator-red-bg)
      evil-motion-state-tag   (propertize " Motion " 'face 'jp-modeline-indicator-cyan-bg)
      evil-replace-state-tag  (propertize " Replace " 'face 'jp-modeline-indicator-green-bg)
      evil-emacs-state-tag    (propertize " Emacs " 'face 'jp-modeline-indicator-magenta-bg)
      evil-operator-state-tag (propertize " Operator " 'face 'jp-modeline-indicator-blue-bg))

(setq evil-insert-state-message nil
      evil-visual-state-message nil
      evil-replace-state-message nil
      evil-motion-state-message nil)

(provide 'emacs-jp-evil)

;;; emacs-jp-evil.el ends here
