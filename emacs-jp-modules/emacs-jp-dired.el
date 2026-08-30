;;; emacs-jp-dired.el --- Dired file manager and jp-dired extras -*- lexical-binding: t; -*-

;;; Commentary:

;; Configuration for the Dired file manager, including the custom
;; jp-dired helpers plus the dired-subtree, dired-preview and trashed
;; packages.

;;; Code:

(setq dired-recursive-copies 'always)
(setq dired-recursive-deletes 'always)
(setq delete-by-moving-to-trash t)

;; kill dired buffers when opening a file.
(setq dired-kill-when-opening-new-dired-buffer t)

(setq dired-listing-switches "-AGFhlv --group-directories-first --time-style=long-iso")

(setq dired-dwim-target t)

(setq dired-guess-shell-alist-user ; suggestions for ! and & in Dired
      '(("\\.\\(png\\|jpe?g\\|tiff\\)" "feh *" "feh" "xdg-open")
        ("\\.\\(mp[34]\\|m4a\\|ogg\\|flac\\|webm\\|mkv\\)" "mpv *" "mpv" "xdg-open")
        (".*" "xdg-open")))

(with-eval-after-load 'dired
  (setq dired-auto-revert-buffer #'dired-directory-changed-p) ; also see `dired-do-revert-buffer'
  (setq dired-make-directory-clickable t) ; Emacs 29.1
  (setq dired-free-space nil) ; Emacs 29.1
  (setq dired-mouse-drag-files t) ; Emacs 29.1

  (add-hook 'dired-mode-hook #'dired-hide-details-mode)
  (add-hook 'dired-mode-hook #'hl-line-mode)

  ;; In Emacs 29 there is a binding for `repeat-mode' which lets you
  ;; repeat C-x C-j just by following it up with j.
  (define-key dired-jump-map (kbd "j") nil))

(with-eval-after-load 'dired
  (require 'dired-aux)

  (keymap-set dired-mode-map "C-+" #'dired-create-empty-file)
  (keymap-set dired-mode-map "M-s f" nil)
  (keymap-set dired-mode-map "C-<return>" #'dired-do-open) ; Emacs 30
  (keymap-set dired-mode-map "C-x v v" #'dired-vc-next-action) ; Emacs 28

  (setq dired-isearch-filenames 'dwim)
  (setq dired-create-destination-dirs 'ask) ; Emacs 27
  (setq dired-vc-rename-file t)             ; Emacs 27
  (setq dired-do-revert-buffer (lambda (dir) (not (file-remote-p dir)))) ; Emacs 28
  (setq dired-create-destination-dirs-on-trailing-dirsep t) ; Emacs 29

  (require 'dired-x)

  (define-key dired-mode-map (kbd "I") #'dired-info)

  (setq dired-clean-up-buffers-too t)
  (setq dired-clean-confirm-killing-deleted-buffers t)
  (setq dired-x-hands-off-my-keys t)    ; easier to show the keys I use
  (setq dired-bind-man nil)
  (setq dired-bind-info nil))

(with-eval-after-load 'dired
  (require 'jp-dired)
  (add-hook 'dired-mode #'jp-dired-setup-imenu)
  (keymap-set dired-mode-map "i" #'jp-dired-insert-subdir) ; override `dired-maybe-insert-subdir'
  (keymap-set dired-mode-map "/" #'jp-dired-limit-regexp)
  (keymap-set dired-mode-map "C-c C-l" #'jp-dired-limit-regexp)
  (keymap-set dired-mode-map "M-n" #'jp-dired-subdirectory-next)
  (keymap-set dired-mode-map "C-c C-s" #'jp-dired-search-flat-list)
  (keymap-set dired-mode-map "C-c C-n" #'jp-dired-subdirectory-next)
  (keymap-set dired-mode-map "C-c C-p" #'jp-dired-subdirectory-previous)
  (keymap-set dired-mode-map "M-s G" #'jp-dired-grep-marked-files) ; M-s g is `jp-search-grep'
  (keymap-set dired-mode-map "M-p" #'jp-dired-subdirectory-previous))

(use-package dired-subtree
  :config
  (with-eval-after-load 'dired
    (keymap-set dired-mode-map "<tab>" #'dired-subtree-toggle)
    (keymap-set dired-mode-map "TAB" #'dired-subtree-toggle)
    (keymap-set dired-mode-map "<backtab>" #'dired-subtree-remove)
    (keymap-set dired-mode-map "S-TAB" #'dired-subtree-remove)
    (setq dired-subtree-use-backgrounds nil)))

(setq wdired-allow-to-change-permissions t)
(setq wdired-create-parent-directories t)

(with-eval-after-load 'image-dired
  (define-key image-dired-thumbnail-mode-map (kbd "<return>") #'image-dired-thumbnail-display-external)
  (setq image-dired-thumbnail-storage 'standard)
  (setq image-dired-external-viewer "xdg-open")
  (setq image-dired-thumb-size 80)
  (setq image-dired-thumb-margin 2)
  (setq image-dired-thumb-relief 0)
  (setq image-dired-thumbs-per-row 4))

;;;; Automatically preview Dired file at point (dired-preview.el)
;; One of my packages: <https://protesilaos.com/emacs>
(use-package dired-preview
  :config
  (with-eval-after-load 'dired
    (require 'dired-preview)
    (add-hook 'dired-mode-hook (lambda ()
                                 (when (string-match-p "Pictures" default-directory)
                                   (dired-preview-mode 1))))
    (define-key dired-mode-map (kbd "V") #'dired-preview-mode)

    (setq dired-preview-trigger-on-start nil)
    (setq dired-preview-max-size (* (expt 2 20) 10))
    (setq dired-preview-delay 0.5)
    (setq dired-preview-ignored-extensions-regexp
          (concat "\\."
                  "\\(gz\\|"
                  "zst\\|"
                  "tar\\|"
                  "xz\\|"
                  "rar\\|"
                  "zip\\|"
                  "iso\\|"
                  "epub"
                  "\\)"))

    (setq dired-preview-display-action-alist #'dired-preview-display-action-alist-below)))

;;;; dired-like mode for the trash (trashed.el)
(use-package trashed
  :config
  (setq trashed-action-confirmer 'y-or-n-p)
  (setq trashed-use-header-line t)
  (setq trashed-sort-key '("Date deleted" . t))
  (setq trashed-date-format "%Y-%m-%d %H:%M:%S"))

(provide 'emacs-jp-dired)

;;; emacs-jp-dired.el ends here
