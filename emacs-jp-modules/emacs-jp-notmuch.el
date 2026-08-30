;;; emacs-jp-notmuch.el --- Notmuch (mail indexer and MUA) -*- lexical-binding: t; -*-

;;; Commentary:

;; Configuration for the notmuch mail reader.  Notmuch is installed
;; from the distro repositories (its CLI is independent of Emacs), so
;; only the Emacs Lisp side is set up here.

;;; Code:

;; Notmuch lives in the distro's site-lisp directory.
(add-to-list 'load-path "/usr/share/emacs/site-lisp/")

;;; Account settings
(with-eval-after-load 'jp-common
  (let ((prv (jp-common-auth-get-field "jpacheco" :user))
        (pub (jp-common-auth-get-field "jpacheco" :user))
        (inf (jp-common-auth-get-field "jpacheco" :user))
        (box (jp-common-auth-get-field "jpacheco" :user)))
    (setq notmuch-identities
          (mapcar (lambda (str)
                    (format "%s <%s>" user-full-name str))
                  (list prv pub inf box))
          notmuch-fcc-dirs `((".*" . "disroot/Sent")))))

;;;; General UI
(setq notmuch-show-logo nil
      notmuch-column-control 1.0
      notmuch-hello-auto-refresh t
      notmuch-hello-recent-searches-max 20
      notmuch-hello-thousands-separator ""
      notmuch-hello-sections '(notmuch-hello-insert-saved-searches)
      notmuch-show-all-tags-list t)

;;;; Search
(setq notmuch-search-oldest-first nil)
(setq notmuch-search-result-format
      '(("date" . "%12s  ")
        ("count" . "%-7s  ")
        ("authors" . "%-20s  ")
        ("subject" . "%-80s  ")
        ("tags" . "(%s)")))
(setq notmuch-tree-result-format
      '(("date" . "%12s  ")
        ("authors" . "%-20s  ")
        ((("tree" . "%s")
          ("subject" . "%s"))
         . " %-80s  ")
        ("tags" . "(%s)")))
(setq notmuch-search-line-faces
      '(("unread" . notmuch-search-unread-face)
        ("flag" . italic)))
(setq notmuch-show-empty-saved-searches t)
(setq notmuch-saved-searches
      `(( :name "📥 inbox"
          :query "tag:inbox"
          :sort-order newest-first
          :key ,(kbd "i"))
        ( :name "💬 all unread (inbox)"
          :query "tag:unread and tag:inbox"
          :sort-order newest-first
          :key ,(kbd "u"))
        ( :name "🛠️ unread packages"
          :query "tag:unread and tag:package"
          :sort-order newest-first
          :key ,(kbd "p"))
        ( :name "🏆 unread coaching"
          :query "tag:unread and tag:coach"
          :sort-order newest-first
          :key ,(kbd "c"))))

;;;; Tags
(setq notmuch-archive-tags nil ; I do not archive email
      notmuch-message-replied-tags '("+replied")
      notmuch-message-forwarded-tags '("+forwarded")
      notmuch-show-mark-read-tags '("-unread")
      notmuch-draft-tags '("+draft")
      notmuch-draft-folder "drafts"
      notmuch-draft-save-plaintext 'ask)

;; The emoji are cosmetic.  The tags are just the text.
(setq notmuch-tag-formats
      '(("unread" (propertize tag 'face 'notmuch-tag-unread))
        ("flag" (propertize tag 'face 'notmuch-tag-flagged)
         (concat tag "🚩")))
      notmuch-tag-deleted-formats
      '(("unread" (notmuch-apply-face bare-tag 'notmuch-tag-deleted)
         (concat "👁️‍🗨️" tag))
        (".*" (notmuch-apply-face tag 'notmuch-tag-deleted)
         (concat "🚫" tag)))
      notmuch-tag-added-formats
      '(("del" (notmuch-apply-face tag 'notmuch-tag-added)
         (concat "💥" tag))
        (".*" (notmuch-apply-face tag 'notmuch-tag-added)
         (concat "🏷️" tag))))

;;;; Email composition
(setq notmuch-mua-compose-in 'current-window)
(setq notmuch-mua-hidden-headers nil)
(setq notmuch-address-command 'internal)
(setq notmuch-address-use-company nil)
(setq notmuch-always-prompt-for-sender t)
(setq notmuch-mua-cite-function 'message-cite-original-without-signature)
(setq notmuch-mua-reply-insert-header-p-function 'notmuch-show-reply-insert-header-p-never)
(setq notmuch-mua-user-agent-function nil)
(setq notmuch-maildir-use-notmuch-insert t)
(setq notmuch-crypto-process-mime t)
(setq notmuch-crypto-get-keys-asynchronously t)
(setq notmuch-mua-attachment-regexp   ; see `notmuch-mua-send-hook'
      (concat "\\b\\(attache\?ment\\|attached\\|attach\\|"
              "pi[èe]ce\s+jointe?\\|"
              "συνημμ[εέ]νο\\|επισυν[αά]πτω\\)\\b"))

(with-eval-after-load 'message
  (defun jp-notmuch-message-tab ()
    "Override for `message-tab' to enforce header line check."
    (interactive nil message-mode)
    (cond
     ((save-excursion
        (goto-char (line-beginning-position))
        (looking-at notmuch-address-completion-headers-regexp))
      (notmuch-address-expand-name)
      nil)
     (message-tab-body-function (funcall message-tab-body-function))
     (t (funcall (or (lookup-key text-mode-map "\t")
                     (lookup-key global-map "\t")
                     'indent-relative)))))

  (advice-add #'message-tab :override #'jp-notmuch-message-tab))

;;;; Reading messages
(setq notmuch-show-relative-dates t)
(setq notmuch-show-all-multipart/alternative-parts nil)
(setq notmuch-show-indent-messages-width 0)
(setq notmuch-show-indent-multipart nil)
(setq notmuch-show-part-button-default-action 'notmuch-show-view-part)
(setq notmuch-show-text/html-blocked-images ".") ; block everything
(setq notmuch-wash-wrap-lines-length 120)
(setq notmuch-unthreaded-show-out nil)
(setq notmuch-message-headers '("To" "Cc" "Subject" "Date"))
(setq notmuch-message-headers-visible t)

(let ((count most-positive-fixnum)) ; no buttonisation of long quotes
  (setq notmuch-wash-citation-lines-prefix count
        notmuch-wash-citation-lines-suffix count))

;;;; Hooks and key bindings
(add-hook 'notmuch-mua-send-hook #'notmuch-mua-attachment-check)
(add-hook 'notmuch-show-hook (lambda () (setq-local header-line-format nil)))
(remove-hook 'notmuch-show-hook #'notmuch-show-turn-on-visual-line-mode)
(remove-hook 'notmuch-search-hook #'notmuch-hl-line-mode) ; Check my `lin' package

(with-eval-after-load 'notmuch
  (keymap-set notmuch-search-mode-map "a" nil)
  (keymap-set notmuch-search-mode-map "A" nil)
  (keymap-set notmuch-search-mode-map "/" #'notmuch-search-filter) ; alias for l
  (keymap-set notmuch-search-mode-map "r" #'notmuch-search-reply-to-thread)
  (keymap-set notmuch-search-mode-map "R" #'notmuch-search-reply-to-thread-sender)

  (keymap-set notmuch-show-mode-map "a" nil)
  (keymap-set notmuch-show-mode-map "A" nil)
  (keymap-set notmuch-show-mode-map "r" #'notmuch-show-reply)
  (keymap-set notmuch-show-mode-map "R" #'notmuch-show-reply-sender)

  (define-key notmuch-hello-mode-map (kbd "C-<tab>") nil))

;;;; My own tweaks for notmuch (jp-notmuch.el)
(with-eval-after-load 'notmuch
  (require 'jp-notmuch)

  (keymap-set notmuch-search-mode-map "D" #'jp-notmuch-search-delete-thread)
  (keymap-set notmuch-search-mode-map "S" #'jp-notmuch-search-spam-thread)
  (keymap-set notmuch-search-mode-map "g" #'jp-notmuch-refresh-buffer)

  (keymap-set notmuch-show-mode-map "D" #'jp-notmuch-show-delete-message)
  (keymap-set notmuch-show-mode-map "S" #'jp-notmuch-show-spam-message)

  (define-key notmuch-show-stash-map (kbd "S") #'jp-notmuch-stash-sourcehut-link)

  ;; Actions available after pressing 'k' (`notmuch-tag-jump').
  (setq notmuch-tagging-keys
        `((,(kbd "d") jp-notmuch-mark-delete-tags "💥 Mark for deletion")
          (,(kbd "f") jp-notmuch-mark-flag-tags "🚩 Flag as important")
          (,(kbd "s") jp-notmuch-mark-spam-tags "🔥 Mark as spam")
          (,(kbd "r") ("-unread") "👁️‍🗨️ Mark as read")
          (,(kbd "u") ("+unread") "🗨️ Mark as unread")))

  ;; These emoji are purely cosmetic.  The tag remains the same.
  (add-to-list 'notmuch-tag-formats '("encrypted" (concat tag "🔒")))
  (add-to-list 'notmuch-tag-formats '("attachment" (concat tag "📎")))
  (add-to-list 'notmuch-tag-formats '("coach" (concat tag "🏆")))
  (add-to-list 'notmuch-tag-formats '("package" (concat tag "🗂️"))))

;;;; Glue code for notmuch and org-link (ol-notmuch.el)
(use-package ol-notmuch
  :config
  (with-eval-after-load 'notmuch
    (require 'ol-notmuch)))

;;;; notmuch-indicator (another package of mine)
(use-package notmuch-indicator
  :config
  (with-eval-after-load 'notmuch
    (setq notmuch-indicator-args
          '(( :terms "tag:unread and tag:inbox"
              :label "[U] "
              :label-face jp-modeline-indicator-cyan
              :counter-face jp-modeline-indicator-cyan)
            ( :terms "tag:unread and tag:package"
              :label "[P] "
              :label-face jp-modeline-indicator-magenta
              :counter-face jp-modeline-indicator-magenta)
            ( :terms "tag:unread and tag:coach"
              :label "[C] "
              :label-face jp-modeline-indicator-red
              :counter-face jp-modeline-indicator-red))

          notmuch-indicator-refresh-count (* 60 3)
          notmuch-indicator-hide-empty-counters t
          notmuch-indicator-force-refresh-commands '(notmuch-refresh-this-buffer))

    ;; I control its placement myself.  See emacs-jp-modeline.el where
    ;; I set the `mode-line-format'.
    (setq notmuch-indicator-add-to-mode-line-misc-info nil)

    (notmuch-indicator-mode 1)))

(provide 'emacs-jp-notmuch)

;;; emacs-jp-notmuch.el ends here
