;;; emacs-jp-email.el --- Email-related settings (auth, message, mml) -*- lexical-binding: t; -*-

;;; Commentary:

;; Mail user agent, message composition, electronic mail privacy
;; settings (`mml-secure') and authentication sources.

;;; Code:

;;;; File with authentication credentials (`auth-source')
(setq auth-sources '("~/.authinfo")
      user-full-name "Javier Pacheco"
      user-mail-address "jpacheco@disroot.org")

;;;; Encryption settings (`mm-encode' and `mml-sec')
(setq mm-encrypt-option nil ; use 'guided for both if you need more control
      mm-sign-option nil)

(setq mml-secure-openpgp-encrypt-to-self t
      mml-secure-openpgp-sign-with-sender t
      mml-secure-smime-encrypt-to-self t
      mml-secure-smime-sign-with-sender t)

;;;; Message composition (`message')
(add-hook 'message-setup-hook #'message-sort-headers)

(setq mail-user-agent 'message-user-agent
      message-mail-user-agent t) ; use `mail-user-agent'
(setq mail-header-separator "--text follows this line--")
(setq message-elide-ellipsis "\n> [... %l lines elided]\n")
(setq compose-mail-user-agent-warnings nil)
(setq message-signature "Ing. Jaier Pacheco\nhttps://jpachecoxyz.github.io\n"
      mail-signature message-signature)
(setq message-citation-line-function #'message-insert-formatted-citation-line)
(setq message-citation-line-format (concat "> From: %f\n"
                                           "> Date: %a, %e %b %Y %T %z\n"
                                           ">")
      message-ignored-cited-headers "") ; default is "." for all headers
(setq message-confirm-send nil)
(setq message-kill-buffer-on-exit t)
(setq message-forward-as-mime t)
(setq message-wide-reply-confirm-recipients nil)

;;;; Add attachments from Dired (`gnus-dired' does not require `gnus')
(add-hook 'dired-mode-hook #'turn-on-gnus-dired-mode)

;;;; `sendmail' (mail transfer agent)
(with-eval-after-load 'message
  (setq send-mail-function #'smtpmail-send-it)
  (setq smtpmail-smtp-server "disroot.org")
  (setq smtpmail-smtp-service 587)
  (setq smtpmail-stream-type 'starttls))

(when (executable-find "notmuch")
  (require 'emacs-jp-notmuch))

(provide 'emacs-jp-email)

;;; emacs-jp-email.el ends here
