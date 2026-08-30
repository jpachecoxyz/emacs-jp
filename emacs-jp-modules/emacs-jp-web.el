;;; emacs-jp-web.el --- Browsing, Eww, Elfeed and Rcirc -*- lexical-binding: t; -*-

;;; Commentary:

;; browse-url, goto-addr, shr, eww, elfeed/elfeed-org and Rcirc
;; configuration.

;;; Code:

;;;; `browse-url'
(setq browse-url-browser-function 'eww-browse-url)
(setq browse-url-secondary-browser-function 'browse-url-default-browser)

;;;; `goto-addr'
(add-hook 'text-mode-hook #'goto-address-mode)
(add-hook 'prog-mode-hook #'goto-address-prog-mode)
(setq goto-address-url-face 'link)
(setq goto-address-url-mouse-face 'highlight)
(setq goto-address-mail-face nil)
(setq goto-address-mail-mouse-face 'highlight)

;;;; `shr' (Simple HTML Renderer)
(setq shr-use-colors nil)             ; t is bad for accessibility
(setq shr-use-fonts nil)              ; t is superfluous, given `variable-pitch-mode'
(setq shr-max-image-proportion 0.6)
(setq shr-image-animate nil)          ; No GIFs, thank you!
(setq shr-width fill-column)
(setq shr-max-width fill-column)
(setq shr-discard-aria-hidden t)
(setq shr-fill-text nil)              ; Emacs 31
(setq shr-cookie-policy nil)

;;;; `url-cookie'
(setq url-cookie-untrusted-urls '(".*"))

;;;; `eww' (Emacs Web Wowser)
(with-eval-after-load 'eww
  (autoload #'jp-simple-buffers-major-mode "jp-simple")

  (define-key eww-mode-map (kbd "S") nil) ; unmap `eww-list-buffers'
  (define-key eww-mode-map (kbd "b") #'jp-simple-buffers-major-mode) ; general buffer-of-current-mode
  (define-key eww-mode-map (kbd "m") #'bookmark-set)

  (define-key eww-link-keymap (kbd "v") nil) ; stop overriding `eww-view-source'

  (with-eval-after-load 'dired
    (define-key dired-mode-map (kbd "E") #'eww-open-file)) ; to render local HTML files

  (setq eww-auto-rename-buffer 'title)
  (setq eww-header-line-format nil)
  (setq eww-bookmarks-directory (locate-user-emacs-file "eww-bookmarks/"))
  (setq eww-history-limit 150)
  (setq eww-use-external-browser-for-content-type
        "\\`\\(video/\\|audio\\)") ; On GNU/Linux check your mimeapps.list
  (setq eww-form-checkbox-selected-symbol "[X]")
  (setq eww-form-checkbox-symbol "[ ]")
  (setq eww-retrieve-command nil)

  ;; Emacs has a robust bookmark framework, which `eww' supports.
  ;; Here disable all the parallel `eww' bookmarks.
  (dolist (command '(eww-list-bookmarks eww-add-bookmark eww-bookmark-mode
                     eww-list-buffers eww-toggle-fonts eww-toggle-colors
                     eww-switch-to-buffer))
    (put command 'disabled t)))

;;;; `jp-eww' extras
(with-eval-after-load 'eww
  (require 'jp-eww)
  (define-key eww-mode-map (kbd "F") #'jp-eww-find-feed)
  (define-key eww-mode-map (kbd "o") #'jp-eww-open-in-other-window)
  (define-key eww-mode-map (kbd "j") #'jp-eww-jump-to-url-on-page)
  (define-key eww-mode-map (kbd "J") #'jp-eww-visit-url-on-page))

;;; Elfeed feed/RSS reader
(use-package elfeed
  :config
  (define-key global-map (kbd "C-c e") #'elfeed)

  (with-eval-after-load 'elfeed
    (add-hook 'elfeed-show-mode-hook #'visual-line-mode)

    (define-key elfeed-search-mode-map (kbd "w") #'elfeed-search-yank)
    (define-key elfeed-search-mode-map (kbd "g") #'elfeed-update)
    (define-key elfeed-search-mode-map (kbd "G") #'elfeed-search-update--force)

    (define-key elfeed-show-mode-map (kbd "w") #'elfeed-show-yank)

    (setq elfeed-use-curl nil)
    (setq elfeed-curl-max-connections 10)
    (setq elfeed-db-directory (expand-file-name "elfeed/" user-emacs-directory))
    (setq elfeed-enclosure-default-dir (expand-file-name "~/Downloads/"))
    (setq elfeed-search-filter "@2-weeks-ago +unread")
    (setq elfeed-sort-order 'descending)
    (setq elfeed-search-clipboard-type 'CLIPBOARD)
    (setq elfeed-search-title-max-width 100)
    (setq elfeed-search-title-min-width 30)
    (setq elfeed-search-trailing-width 25)
    (setq elfeed-show-truncate-long-urls t)
    (setq elfeed-show-unique-buffers t)
    (setq elfeed-search-date-format '("%F %R" 20 :left))
    ;; Make entries tagged as "personal" use the `bold-italic' face.
    (add-to-list 'elfeed-search-face-alist '(personal bold-italic))))

;;; Elfeed-org
(use-package elfeed-org
  :config
  (require 'elfeed-org)
  ;; is started with =M-x elfeed=
  (elfeed-org)

  ;; Optionally specify a number of files containing elfeed
  ;; configuration. If not set then the location below is used.
  (setq rmh-elfeed-org-files (list "~/.config/emacs/feeds.org")))

;;; Rcirc (IRC client)
(with-eval-after-load 'rcirc
  (setq rcirc-server-alist
        `(("irc.libera.chat"
           :channels ("#emacs")
           :port 6697
           :encryption tls
           :password ,(jp-common-auth-get-field "libera" :secret))))

  (setq rcirc-prompt "%t> ") ; Read the docs or use (customize-set-variable 'rcirc-prompt "%t> ")

  (setq rcirc-default-nick "jpachecoxyz"
        rcirc-default-user-name "jpachecoxyz"
        rcirc-default-full-name "Javier Pacheco")

  (setq rcirc-timeout-seconds most-positive-fixnum)

  (rcirc-track-minor-mode 1))

(provide 'emacs-jp-web)

;;; emacs-jp-web.el ends here
