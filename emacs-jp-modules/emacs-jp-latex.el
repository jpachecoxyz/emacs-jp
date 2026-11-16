;;; emacs-jp-latex.el --- LaTeX editing (AUCTeX, RefTeX, Eglot/texlab) -*- lexical-binding: t; -*-

;;; Commentary:

;; LaTeX editing built on AUCTeX, with Language Server Protocol
;; features (completion, diagnostics, navigation, formatting) provided
;; by Eglot and the external `texlab' server.
;;
;; Eglot already knows how to launch texlab for the TeX modes: see
;; `eglot-server-programs', which offers it for `latex-mode', `tex-mode'
;; and friends.  AUCTeX registers `latex-mode' and `tex-mode' as extra
;; parents of `LaTeX-mode' (via `derived-mode-extra-parents'), so the
;; lookup succeeds without touching that variable.  What is missing is
;; starting Eglot automatically: TeX modes are text modes, so the
;; `prog-mode-hook' used in emacs-jp-code.el never reaches them.
;;
;; `texlab' is an external binary, not an Emacs package; install it
;; separately (e.g. `paru -S texlab').  Without it Eglot falls back to
;; the other candidate, `digestif', or asks interactively.
;;
;; The document is built with `latexmk' and previewed with PDF Tools
;; (set up in emacs-jp-utils.el): saving the master file recompiles in
;; the background and the PDF buffer refreshes itself, so the preview
;; follows the source.  SyncTeX keeps the two in sync in both
;; directions.
;;
;; Documents are built with LuaLaTeX by default (`TeX-engine' below), so
;; they can select any installed system font through `fontspec'.  A file
;; can opt into another engine with a `TeX-engine' local variable, e.g.
;; `%%% TeX-engine: xetex' or `%%% TeX-engine: default' for pdflatex.

;;; Code:

(declare-function TeX-command "tex" (name file-fn &optional override-confirm))
(declare-function TeX-master-file "tex" (&optional extension nondirectory ask))
(declare-function TeX-process "tex" (name))
(declare-function TeX-revert-document-buffer "tex" (file))

;; ---------------------------------------------------------------------
;; Build on save and refresh the PDF preview.
;; ---------------------------------------------------------------------

(defun jp/latex-compile-on-save ()
  "Build the LaTeX document with latexmk after saving.

The build runs asynchronously, so saving stays responsive, and it
is skipped while a previous build for the same document is still
running.  Only the master file triggers a build, so saving an
included fragment does nothing.  The preview is refreshed by
`jp/latex-view-after-compile'."
  (when (and (derived-mode-p 'LaTeX-mode)
             (buffer-file-name)
             (not (file-remote-p (buffer-file-name)))
             ;; Only the master file of the document triggers a build.
             (equal (file-truename (expand-file-name (TeX-master-file)))
                    (file-truename (file-name-sans-extension
                                    (buffer-file-name)))))
    (let ((process (TeX-process (TeX-master-file))))
      (unless (and process (eq (process-status process) 'run))
        ;; `TeX-command' leaves the *TeX output* buffer current, so
        ;; keep the saved buffer in place.
        (save-current-buffer
          (TeX-command "LaTeXMk" #'TeX-master-file))))))

(defun jp/latex-view-after-compile (pdf)
  "Show PDF in PDF Tools, refreshing it on every later build.

Meant for `TeX-after-compilation-finished-functions', which calls
it with the path of the PDF that has just been written."
  (if (find-buffer-visiting pdf)
      (TeX-revert-document-buffer pdf)
    (when (file-exists-p pdf)
      (find-file-other-window pdf))))

;; `jp/latex-compile-on-save' checks the major mode itself, so a global
;; hook is enough.  The other hook is AUCTeX's.
(add-hook 'after-save-hook #'jp/latex-compile-on-save)
(add-hook 'TeX-after-compilation-finished-functions #'jp/latex-view-after-compile)

;; ---------------------------------------------------------------------
;; AUCTeX: the LaTeX major mode (and friends).
;; ---------------------------------------------------------------------

(use-package auctex
  :defer t
  :init
  ;; Keep AUCTeX and RefTeX aware of the macros, labels and citations
  ;; used in the document by parsing it (and the packages it loads).
  (setq TeX-parse-self t
        TeX-auto-save t
        TeX-save-query nil
        TeX-PDF-mode t)
  ;; Build with latexmk: a single command takes care of reruns,
  ;; BibTeX/Biber and indexes.
  (setq TeX-command-default "LaTeXMk")
  ;; Compile with LuaLaTeX.  Unlike pdflatex it can use arbitrary
  ;; system fonts via `fontspec' (see the Commentary); AUCTeX turns this
  ;; into `latexmk -pdflua' for the LaTeXMk command above.  Files that
  ;; need another engine override it with a `TeX-engine' local variable.
  (setq TeX-engine 'luatex)
  ;; SyncTeX for forward and inverse search.  PDF Tools handles inverse
  ;; search inside Emacs, so no external server is needed (and setting
  ;; this to nil avoids AUCTeX asking about starting one).
  (setq TeX-source-correlate-mode t
        TeX-source-correlate-start-server nil)
  ;; Preview with PDF Tools, from `emacs-jp-utils.el'.
  (setq TeX-view-program-selection '((output-pdf "PDF Tools")
                                     (output-html "xdg-open")))
  :hook
  ;; TeX modes run `TeX-mode-hook' before their own hook, so this also
  ;; covers `LaTeX-mode', `plain-TeX-mode' and `ConTeXt-mode'.
  (TeX-mode . eglot-ensure))

;; ---------------------------------------------------------------------
;; RefTeX: labels, references and citations (bundled with AUCTeX).
;; ---------------------------------------------------------------------

(use-package reftex
  :ensure nil
  :defer t
  :init
  ;; Let RefTeX take over the label/reference/citation prompts in
  ;; AUCTeX, so `\ref', `\cite' and friends complete against the
  ;; document instead of using plain minibuffer input.
  (setq reftex-plug-into-AUCTeX t)
  :hook
  (LaTeX-mode . turn-on-reftex))

(provide 'emacs-jp-latex)

;;; emacs-jp-latex.el ends here
