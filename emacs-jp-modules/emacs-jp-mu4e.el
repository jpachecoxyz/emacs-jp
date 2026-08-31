;;; emacs-jp-mu4e.el --- mu4e configuration -*- lexical-binding: t; -*-

;;; Commentary:

;; Email client based on mu4e (mu/mbsync), with mu4e-alert
;; notifications and org-contacts autocompletion.

;;; Code:

;; NOTE: mu4e is deliberately NOT required up front: it is a heavy
;; package (plus gnus/message/org exporters) that is only needed when
;; composing or reading mail.  All the mu4e-* options below are plain
;; `setq' calls, which are cheap and effective before mu4e is ever
;; loaded.  The heavy `require' and the notifications/modeline setup
;; happen in the `with-eval-after-load 'mu4e' block near the bottom.

;;;; Mail sync
(setq mu4e-get-mail-command "mbsync -a")
(setq mu4e-update-interval (* 10 60))

;;;; Maildir
(setq mu4e-maildir (expand-file-name "~/Mail"))

(setq mu4e-contacts-file "~/Documents/Emacs/org/agenda/contacts.org")

;; Autocompletado para org-contacts file
(setq mu4e-compose-complete-addresses nil)

;;;; Identity
(setq user-mail-address "jpacheco@disroot.org"
      user-full-name    "Javier Pacheco")

;;;; Sending mail (msmtp)
(setq sendmail-program "msmtp"
      send-mail-function 'sendmail-send-it
      message-send-mail-function 'sendmail-send-it)

;;;; SMTP (fallback)
(setq smtpmail-smtp-server  "disroot.org"
      smtpmail-smtp-service 587
      smtpmail-stream-type  'starttls
      smtpmail-smtp-user    "jpacheco@disroot.org")

;;;; Composition
(setq mu4e-compose-dont-reply-to-self t)
(setq mu4e-compose-keep-self-cc nil)
(setq message-kill-buffer-on-exit t)

;;;; Important for mbsync
(setq mu4e-change-filenames-when-moving t)

;;;; Visual
(setq mu4e-view-show-images t)
(setq mu4e-view-show-addresses t)

;;;; Mail folders
(setq mu4e-maildir "/disroot"
      mu4e-drafts-folder  "/disroot/Drafts"
      mu4e-sent-folder    "/disroot/Sent"
      mu4e-refile-folder  "/disroot/Archive"
      mu4e-trash-folder   "/disroot/Trash")

;;;; Inbox query
(setq m/mu4e-inbox-query
      "(maildir:/disroot/INBOX) AND flag:unread")

;;;; Shortcuts
(setq mu4e-maildir-shortcuts
      '((:maildir "/disroot/INBOX"  :key ?i)
        (:maildir "/disroot/Sent"   :key ?s)
        (:maildir "/disroot/Trash"  :key ?t)
        (:maildir "/disroot/Drafts" :key ?d)))

;;;; Bookmarks
(setq mu4e-bookmarks
      '((:name "Unread messages"
               :query "flag:unread AND NOT flag:trashed"
               :key ?i)

        (:name "Today's messages"
               :query "date:today..now"
               :key ?t)

        (:name "Last 7 days"
               :query "date:7d..now"
               :hide-unread t
               :key ?w)

        (:name "Messages with images"
               :query "mime:image/*"
               :key ?p)))

;;;; Quick inbox
(defun jp/mu4e-go-to-inbox ()
  (interactive)
  (mu4e-headers-search m/mu4e-inbox-query))

(defun jp/mu4e-direct-inbox ()
  "Abrir el Inbox de Disroot directamente en la ventana actual."
  (interactive)
  ;; Esta función salta directamente a los encabezados con el query de tu inbox
  (mu4e-headers-search "maildir:/disroot/INBOX"))

;;;; Keybindings
;; `mu4e' is a built-in package that is NOT autoloaded by itself, so a
;; plain global binding would fail with "wrong command" until mu4e is
;; loaded.  Declare the commands as autoloaded from the `mu4e' file and
;; bind them: pressing C-c m / C-x m loads mu4e on demand (which then
;; runs the `with-eval-after-load 'mu4e' block below).
(autoload 'mu4e "mu4e" nil t)
(autoload 'mu4e-compose-new "mu4e" nil t)
(keymap-global-set "C-c m" #'mu4e)
(keymap-global-set "C-x m" #'mu4e-compose-new)

;;;; Modeline
(setq mu4e-modeline-support nil)

;;;; General settings
(setq mu4e-confirm-quit nil)

;; Everything that pulls in mu4e (and the gnus/message machinery behind
;; it) is deferred until the mail client is actually used.
(with-eval-after-load 'mu4e
  ;;;; Mu4e Alert
  (require 'mu4e-alert)

  ;; estilo de notificación
  (setq mu4e-alert-style 'notifications)

  ;; activar notificaciones
  (mu4e-alert-enable-notifications)

  ;; actualizar correo automáticamente
  (setq mu4e-update-interval 300) ;; 5 minutos
  (mu4e-alert-enable-mode-line-display)

  ;; 1. Define la consulta para los mensajes no leídos (solo INBOX)
  (setq mu4e-alert-interesting-query "flag:unread AND maildir:/disroot/INBOX")

  ;; 2. Personaliza el formato de la mode-line
  (setq mu4e-alert-modeline-formatter
        (lambda (count)
          (if (> count 0)
              "📥"   ; Solo el icono si hay 1 o más
            "")))     ; Nada si está vacío

  ;; 3. Asegúrate de que el refresco sea constante
  (mu4e-alert-enable-mode-line-display)

  ;;;; Org-contacts
  (require 'org-contacts)

  (setq org-contacts-files '("~/Documents/Emacs/org/agenda/contacts.org"))

  (add-to-list 'mu4e-headers-actions
               '("org-contact-add" . mu4e-action-add-org-contact) t)
  (add-to-list 'mu4e-view-actions
               '("org-contact-add" . mu4e-action-add-org-contact) t)

  ;; Backend de autocompletado
  (setq mu4e-compose-complete-addresses-function #'mu4e--compose-complete-handler)
  (add-to-list 'completion-at-point-functions #'org-contacts-message-complete-function)

  ;;;; Modeline (mail unread counter)
  (mu4e-modeline-mode 1)
  ;; Si quieres que solo te avise de los correos en el INBOX:
  (setq mu4e-modeline-unread-items-query "flag:unread AND maildir:/disroot/INBOX"))

(provide 'emacs-jp-mu4e)

;;; emacs-jp-mu4e.el ends here
