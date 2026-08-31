;;; emacs-jp-utils.el --- Some useful utilities -*- lexical-binding: t; -*-

;;; Commentary:

;; Assorted helper commands (scratch buffers, eshell/vterm toggles,
;; org helpers, presentation mode, fzf, pdf-tools).

;;; Code:

(defun new-scratch-pad ()
  "Create a new org-mode buffer for random stuff with metadata."
  (interactive)
  (let ((buffer (generate-new-buffer "Org-scratch-buffer")))
    (switch-to-buffer buffer)
    (setq buffer-offer-save t)

    ;; Insert metadata
    (insert "#+title: Org Buffer\n")
    (insert "#+author: Ing. Javier Pacheco\n")
    (insert "#+email: jpacheco@disroot.org\n")
    (insert (format "#+date: %s\n\n\n" (format-time-string "%Y-%m-%d %H:%M")))
    ;; Move cursor to end and enter insert mode
    (goto-char (point-max))
    (when (fboundp 'evil-insert-state)
      (evil-insert-state)
      (org-mode))))

;; Toggle *scratch* buffer.
(defun jp/scratch-buffer ()
  "Return the *scratch* buffer, inserting a fresh welcome message if it is empty."
  (let ((scratch (get-buffer-create "*scratch*")))
    (with-current-buffer scratch
      (when (string-empty-p (buffer-string))
        (funcall (or initial-major-mode 'lisp-interaction-mode))
        (insert (jp/scratch-message))))
    scratch))

(defun toggle-scratch-buffer ()
  "Toggle the *scratch* buffer"
  (interactive)
  (if (string= (buffer-name) "*scratch*")
      (bury-buffer)
    (switch-to-buffer (jp/scratch-buffer))))

(defun toggle-org-buffer ()
  "Toggle the Org-scratch-buffer buffer"
  (interactive)
  (if (equal (buffer-name (current-buffer)) "Org-scratch-buffer")
      (if (one-window-p t)
          (switch-to-buffer (other-buffer))
        (delete-window))
    (if (get-buffer "Org-scratch-buffer")
        (if (get-buffer-window "Org-scratch-buffer")
            (progn
              (bury-buffer "Org-scratch-buffer")
              (delete-window (get-buffer-window "Org-scratch-buffer")))
          (switch-to-buffer "Org-scratch-buffer"))
      (new-scratch-pad))))

;; Toggle *eshell* buffer.
(defun toggle-eshell-buffer ()
  "Toggle the visibility of the *eshell* buffer.
If already in the buffer, bury it. Otherwise, switch to it or launch Eshell."
  (interactive)
  (let ((buf (get-buffer "*eshell*")))
    (if (string= (buffer-name) "*eshell*")
        (bury-buffer)
      (if buf
          (switch-to-buffer buf)
        (eshell)))))

(defun my-show-doc-or-describe-symbol ()
  "Show LSP UI doc if LSP is active, otherwise describe symbol at point."
  (interactive)
  (if (bound-and-true-p lsp-mode)
      (lsp-ui-doc-glance)
    (describe-symbol-at-point)))

(defun duplicate-line ()
  (interactive)
  (let ((line-text (thing-at-point 'line t)))
    (save-excursion
      (move-end-of-line 1)
      (newline)
      (insert line-text)))
  (forward-line 1))

(defun move-line-up ()
  (interactive)
  (when (not (= (line-number-at-pos) 1))
    (transpose-lines 1)
    (forward-line -2)))

(defun move-line-down ()
  (interactive)
  (forward-line 1)
  (when (not (= (line-number-at-pos) (point-max)))
    (transpose-lines 1))
  (forward-line -1))

;; Define a custom face for the highlight
(defface my-highlight-face
  '((t (:foreground "gray")))
  "Face for highlighting !!word!! patterns.")

;; Function to replace matched text with asterisks
(defun replace-with-asterisks (limit)
  "Replace !!word!! with asterisks up to LIMIT."
  (while (re-search-forward "!!\\(.*?\\)!!" limit t)
    (let* ((match (match-string 1))
           (start (match-beginning 0))
           (end (match-end 0))
           (asterisks (make-string (length match) ?*)))
      (add-text-properties start end `(display ,asterisks face my-highlight-face)))))

;; Add custom keyword for font-lock in org-mode
(defun my/org-mode-custom-font-lock ()
  "Add custom font-lock keywords for org-mode."
  (font-lock-add-keywords nil
                          '((replace-with-asterisks))))

;; Hook the custom font-lock configuration into org-mode
(add-hook 'org-mode-hook 'my/org-mode-custom-font-lock)

(defun describe-symbol-at-point ()
  "Display the documentation of the symbol at point, if it exists."
  (interactive)
  (let ((symbol (symbol-at-point)))
    (if symbol
        (cond
         ((fboundp symbol) (describe-function symbol))
         ((boundp symbol) (describe-variable symbol))
         (t (message "No documentation found for symbol at point: %s" symbol)))
      (message "No symbol at point"))))

;; Open files in the lisp folder
(require 'find-lisp)
(defun open-lisp-and-org-files ()
  "Open a Lisp or Org file from ~/.emacs.d/lisp directory, including subfolders."
  (interactive)
  (let* ((directory "~/.emacs.d/lisp")
         (el-files (find-lisp-find-files directory ".*\\.el$"))
         (org-files (find-lisp-find-files directory ".*\\.org$"))
         (all-files (append el-files org-files))
         (file (completing-read "Select file: " all-files nil t)))
    (find-file file)))

(defun open-org-files ()
  "Open a Lisp or Org file from my docs directory, including subfolders."
  (interactive)
  (let* ((directory "~/Documents/Emacs/org")
         (org-files (find-lisp-find-files directory ".*\\.org$"))
         (all-files (append org-files))
         (file (completing-read "Select file: " all-files nil t)))
    (find-file file)))

;; Follow urls in the buffer
(defun list-and-open-url-in-buffer ()
  "List all URLs in the current buffer, display them in the minibuffer, and open a selected URL in the browser."
  (interactive)
  (let (urls)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "\\(http\\|https\\|ftp\\|file\\|mailto\\):[^ \t\n]+" nil t)
        (push (match-string 0) urls)))
    (if urls
        (let ((url (completing-read "Select URL to open: " (reverse urls) nil t)))
          (browse-url url))
      (message "No URLs found in the buffer."))))

;; Export org files to pdf using tectonic
(defun org-export-to-latex-and-compile-with-tectonic ()
  "Export the current Org file to LaTeX, compile with tectonic using shell-escape,
   delete the .tex file, and move the generated PDF to the pdf/ directory."
  (interactive)
  (let* ((org-file (buffer-file-name))
         (tex-file (concat (file-name-sans-extension org-file) ".tex"))
         (pdf-file (concat (file-name-sans-extension org-file) ".pdf"))
         (tectonic-command (concat "tectonic -Z shell-escape " tex-file))
         (pdf-dir "~/docs/pdf/"))
    ;; Export Org file to LaTeX
    (org-latex-export-to-latex)
    ;; Run tectonic command in a temporary buffer
    (with-temp-buffer
      (shell-command tectonic-command (current-buffer)))
    ;; Check if the PDF was successfully generated
    (if (file-exists-p pdf-file)
        (progn
          (delete-file tex-file)
          (unless (file-directory-p pdf-dir)
            (make-directory pdf-dir))
          (rename-file pdf-file (concat pdf-dir (file-name-nondirectory pdf-file)) t)
          (message "Compiled %s to PDF and moved to pdf folder." tex-file))
      (message "PDF generation failed."))))

;; Update my web-page
(defun publish-my-blog ()
  "Run the publish blog script within Emacs and display a success message in the minibuffer."
  (interactive)
  (let ((commit-msg (read-string "Enter commit message: ")))
    (let ((process (start-process-shell-command
                    "publish-blog"                       ; Process name
                    "*publish-blog-output*"              ; Output buffer
                    (format "~/webdev/jpachecoxyz/publish.sh \"%s\"" commit-msg))))
      (set-process-sentinel
       process
       (lambda (process event)
         (when (string= event "finished\n")
           (message "jpacheco.xyz was correctly updated!")))))))

(keymap-global-set "C-c u b" 'publish-my-blog)

;; A function to toggle between org-edit-special and org-edit-src-exit
(defun my/org-edit-toggle ()
  "Toggle between org-edit-special and org-edit-src-exit."
  (interactive)
  (if (org-src-edit-buffer-p)  ; Check if we're in the special edit buffer
      (org-edit-src-exit)      ; If inside the edit buffer, exit
    (if (org-in-src-block-p)   ; Check if we're in a source block in org-mode
        (org-edit-special)     ; If in a source block, edit it
      (message "Not in a source block."))))

;; open dired in to specific directories
(defun open-specific-dired ()
  "Ask whether to open config, scripts, or nix config in Dired."
  (interactive)
  (let ((choice (completing-read "Choose an option: " '("config" "scripts" "notes" "pdf's" "books" "docs"))))
    (cond
     ((string= choice "config")
      (fzf-find-file "~/.config/"))
     ((string= choice "scripts")
      (fzf-find-file "~/.local/bin/"))
     ((string= choice "notes")
      (consult-find "~/Documents/Emacs/notes/"))
     ((string= choice "pdf's")
      (consult-find "~/Documents/Emacs/notes/pdf/"))
     ((string= choice "books")
      (consult-find "~/Documents/Emacs/books/"))
     ((string= choice "docs")
      (consult-find "~/Documents/Emacs/org/"))
     (t
      (message "Invalid choice")))))

;; Insert block code:
(defun org-mode-insert-code (language results export)
  "Insert a code block in Org mode with specified LANGUAGE, RESULTS, and EXPORT options."
  (interactive
   (list
    (read-string "Language: ")
    (read-string "Results: " "output")
    (read-string "Export: " "both")))
  (insert (format "#+BEGIN_SRC %s :results %s :exports %s\n\n#+END_SRC\n"
                  language results export))
  (forward-line -2)
  (when (bound-and-true-p evil-mode)
    (evil-insert-state)))
(keymap-global-set "C-c i c" #'org-mode-insert-code)

;; Yank the content of a src org block.
(defun yank-org-src-block-content ()
  "Yank the content of the source block at point."
  (interactive)
  (when (org-in-src-block-p)
    (let* ((element (org-element-at-point))
           (begin (org-element-property :begin element))
           (end (org-element-property :end element)))
      (save-excursion
        (goto-char begin)
        (re-search-forward "^[ \t]*#\\+begin_src[^\n]*\n" end t)
        (let ((content-start (point)))
          (re-search-forward "^[ \t]*#\\+end_src" end t)
          (kill-ring-save content-start (match-beginning 0))))
      (message "Yanked source block content!"))))
(keymap-global-set "C-c i y" #'yank-org-src-block-content)

(require 'transient)
(prog1 'my/transient-goto-file-buffer
  (setq my/goto-file-buffer-alist
        '(("s" "*scratch*"    (switch-to-buffer (jp/scratch-buffer)))
          ("h" "home.nix"       (find-file "~/.dotfiles/nix/home.nix"))
          ("c" "configuration.nix"       (find-file "~/.dotfiles/nix/configuration.nix"))
          ("u" "utilities.org"       (find-file "~/.emacs.d/lisp/utilities.org"))
          ("j" "Journal"      (find-file (expand-file-name "agenda/journal.org" org-directory)))
          ("n" "Notes"        (find-file (expand-file-name "agenda/notes.org" org-directory)))))
  (defun my/goto-file-buffer ()
    "Jump to a file or buffer based on the key used to invoke this command."
    (interactive)
    (let* ((key (this-command-keys))
           (choice (assoc key my/goto-file-buffer-alist))
           (form (caddr choice)))
      (eval form)))
  (eval
   `(transient-define-prefix my/transient-goto-file-buffer ()
      [,(apply 'vector
               "Goto Files & Buffers"
               (mapcar (lambda (x) (list (car x) (cadr x) 'my/goto-file-buffer))
                       my/goto-file-buffer-alist))])))

;;; Presentation-mode
(defvar jp-presentation-mode nil
  "Non-nil when presentation mode is active.")

(defun jp-toggle-presentation-mode ()
  "Toggle presentation mode."
  (interactive)
  (if jp-presentation-mode
      (progn
        ;; Disable presentation
        (logos-focus-mode -1)
        (fontaine-set-preset 'medium)
        (widen)
        (setq jp-presentation-mode nil)
        (message "Presentation mode disabled"))
    ;; Enable presentation
    (logos-narrow-dwim)
    (fontaine-set-preset 'jumbo)
    (logos-focus-mode 1)
    (setq jp-presentation-mode t)
    (message "Presentation mode enabled")))

;;; Rainbow-parens:
(defun jp-simple-rainbow-delimiters ()
"Apply simple rainbow coloring to parentheses, brackets, and braces in the current buffer.
Opening and closing delimiters will have matching colors."
(interactive)
(let ((colors '(font-lock-keyword-face
                font-lock-type-face
                font-lock-function-name-face
                font-lock-variable-name-face
                font-lock-constant-face
                font-lock-builtin-face
                font-lock-string-face
                )))
    (font-lock-add-keywords
    nil
    `((,(rx (or "(" ")" "[" "]" "{" "}"))
        (0 (let* ((char (char-after (match-beginning 0)))
                (depth (save-excursion
                            ;; Move to the correct position based on opening/closing delimiter
                            (if (member char '(?\) ?\] ?\}))
                                (progn
                                (backward-char) ;; Move to the opening delimiter
                                (car (syntax-ppss)))
                            (car (syntax-ppss)))))
                (face (nth (mod depth ,(length colors)) ',colors)))
            (list 'face face)))))))
(font-lock-flush)
(font-lock-ensure))

(add-hook 'prog-mode-hook #'jp-simple-rainbow-delimiters)

(defun jp-toggle-vterm ()
  "Toggle vterm buffer."
  (interactive)
  (if (derived-mode-p 'vterm-mode)
      (previous-buffer)
    (let ((buf (get-buffer "*vterm*")))
      (if buf
          (switch-to-buffer buf)
        (vterm)))))

;;; Webjump
(keymap-global-set "C-x /" #'webjump)
(setq browse-url-browser-function #'browse-url-xdg-open)
(setq webjump-sites
      '(("Google" . [simple-query "www.google.com" "www.google.com/search?q=" ""])
        ("YouTube" . [simple-query "www.youtube.com/feed/subscriptions" "www.youtube.com/results?search_query=" ""])
        ("ChatGPT" . [simple-query "https://chatgpt.com" "https://chatgpt.com/?q=" ""])
        ("(λ jpachecoxyz)" . "https://jpachecoxyz.github.io")))

;;; fzf
(use-package fzf
  :config
  (setq fzf/args
        "--color=fg:-1,fg+:#d0d0d0,bg:-1,bg+:#282828 --color=hl:#5f87af,hl+:#5fd7ff,info:#afaf87,marker:#87ff00 --color=prompt:#458588,spinner:#af5fff,pointer:#af5fff,header:#87afaf --color=gutter:-1,border:#262626,label:#aeaeae,query:#d9d9d9 --border='bold' --border-label='' --preview-window='border-bold' --prompt='❯❯ ' --marker='*' --pointer='->' --separator='─' --scrollbar='│' --layout='reverse-list' --info='right' --height 30"
        fzf/executable "fzf"
        fzf/git-grep-args "-i --line-number %s"
        fzf/grep-command "grep -nrH"
        fzf/position-bottom t
        fzf/window-height 30)

  ;; Skip the prompt for deleting the buffer.
  (defun my/always-kill-buffer-with-process ()
    "Override to always kill buffer with a running process without prompt." t)

  (advice-add 'process-kill-buffer-query-function :override #'my/always-kill-buffer-with-process)

  (defun fzf-find-file (&optional directory)
    "Find a file using fzf. Optionally start from DIRECTORY."
    (interactive "DDirectory: ")
    (let ((d (or directory default-directory)))
      (let ((default-directory (expand-file-name d)))
        (fzf default-directory))
      (with-current-buffer "*fzf*"
        (local-set-key (kbd "<escape>") 'fzf-quit))))

  (defun fzf-quit ()
    "Quit the fzf process, clean up the buffer, and close the window."
    (interactive)
    (let ((buffer (get-buffer "*fzf*"))
          (window (get-buffer-window "*fzf*")))
      (when buffer
        (kill-buffer buffer))
      (when window
        (delete-window window)))))

;;; pdf-tools
;; `pdf-loader-install' (which is autoloaded) makes Emacs load PDF
;; Tools lazily, only once a PDF file is actually opened.
(pdf-loader-install)

(provide 'emacs-jp-utils)

;;; emacs-jp-utils.el ends here
