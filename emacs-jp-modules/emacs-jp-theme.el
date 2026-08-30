;;; emacs-jp-theme.el --- Theme setup and related -*- lexical-binding: t; -*-

;;; Commentary:

;; Load the desired theme family (default: ef) and configure the
;; supporting packages pulsar, lin, spacious-padding and fontaine.

;;; Code:

;;;; Load the desired theme module
;; These all reference my packages: `modus-themes', `ef-themes',
;; `doric-themes', `standard-themes'.
(when jp-emacs-load-theme-family
  (require
   (pcase jp-emacs-load-theme-family
     ('modus 'emacs-jp-modus-themes)
     ('ef 'emacs-jp-ef-themes)
     ('doric 'emacs-jp-doric-themes)
     ('standard 'emacs-jp-standard-themes))))

;;;; Pulsar
(use-package pulsar
  :demand t
  :config
  (pulsar-global-mode 1)

  (add-hook 'next-error-hook #'pulsar-pulse-line-red)
  (add-hook 'minibuffer-setup-hook #'pulsar-pulse-line-red)
  (add-hook 'next-error-hook #'pulsar-recenter-top)
  (add-hook 'minibuffer-setup-hook #'pulsar-recenter-top)
  (add-hook 'next-error-hook #'pulsar-reveal-entry)
  (add-hook 'minibuffer-setup-hook #'pulsar-reveal-entry)

  (setq pulsar-delay 0.055)
  (setq pulsar-iterations 5)
  (setq pulsar-face 'pulsar-green)
  (setq pulsar-region-face 'pulsar-yellow)
  (setq pulsar-highlight-face 'pulsar-magenta)

  :bind (("C-x l" . pulsar-pulse-line)          ; override `count-lines-page'
         ("C-x L" . pulsar-highlight-permanently-dwim)))

;;;; Lin
(use-package lin
  :config
  (setq lin-face 'lin-cyan)
  (lin-global-mode 1))

;;;; Increase padding of windows/frames
(use-package spacious-padding
  :config
  (spacious-padding-mode 1)

  ;; NOTE: In a PGTK/Wayland daemon, `spacious-padding-mode' breaks
  ;; client frame creation for two reasons: see the original comments.
  (remove-hook 'server-after-make-frame-hook #'spacious-padding-set-parameters-of-selected-frame)
  (remove-hook 'enable-theme-functions #'spacious-padding-set-faces)

  (setq spacious-padding-widths
        `(:internal-border-width 15
          :header-line-width 4
          :mode-line-width 6
          :tab-width 4
          :right-divider-width 15
          :scroll-bar-width ,(if jp-pgtk-p 12 6)
          :left-fringe-width 20
          :right-fringe-width 20))

  (setq spacious-padding-subtle-frame-lines
        '( :mode-line-active spacious-padding-line-active
           :mode-line-inactive spacious-padding-line-inactive
           :header-line-active spacious-padding-line-active
           :header-line-inactive spacious-padding-line-inactive))

  (when (< emacs-major-version 29)
    (setq x-underline-at-descent-line (when spacious-padding-subtle-frame-lines t))))

;;;; Fontaine (font configurations)
;; `:demand t' so the preset is applied eagerly at startup.  Without it,
;; the `:bind' keyword defers loading, so `:config' (which calls
;; `fontaine-set-preset') never runs and the configured font is not set.
(use-package fontaine
  :demand t
  :config
  (fontaine-mode 1)

  (setq-default text-scale-remap-header-line t) ; Emacs 28

  (setq fontaine-presets
        '((small
           :default-family "JetBrains Mono NF"
           :fixed-pitch-family "IBM Plex Mono"
           :variable-pitch-family "JetBrains Mono NF"
           :default-height 80)

          (regular
           :default-family "JetBrains Mono NF"
           :fixed-pitch-family "IBM Plex Mono"
           :variable-pitch-family "JetBrains Mono NF"
           :default-height 110)

          (medium
           :default-family "JetBrains Mono NF"
           :fixed-pitch-family "IBM Plex Mono"
           :variable-pitch-family "JetBrains Mono NF"
           :default-height 145)

          (large
           :default-family "JetBrains Mono NF"
           :fixed-pitch-family "IBM Plex Mono"
           :variable-pitch-family "JetBrains Mono NF"
           :default-height 160)

          (presentation
           :default-family "JetBrains Mono NF"
           :fixed-pitch-family "IBM Plex Mono"
           :variable-pitch-family "JetBrains Mono NF"
           :default-height 180)

          (jumbo
           :inherit medium
           :default-height 260)

          (t
           :default-family "JetBrains Mono NF"
           :fixed-pitch-family "IBM Plex Mono"
           :variable-pitch-family "JetBrains Mono NF"
           :default-height 110)))

  (fontaine-set-preset (or (fontaine-restore-latest-preset) 'regular))

  (with-eval-after-load 'pulsar
    (add-hook 'fontaine-set-preset-hook #'pulsar-pulse-line))

  :bind (("C-c f" . fontaine-set-preset)
         ("C-c F" . fontaine-toggle-preset)))

(defun jp/enable-variable-pitch ()
  (unless (derived-mode-p 'mhtml-mode 'nxml-mode 'yaml-mode)
    (when (bound-and-true-p modus-themes-mixed-fonts)
      (variable-pitch-mode 1))))

(add-hook 'text-mode-hook #'jp/enable-variable-pitch)
(add-hook 'notmuch-show-mode-hook #'jp/enable-variable-pitch)
(add-hook 'elfeed-show-mode-hook #'jp/enable-variable-pitch)

;;;; Resize keys with global effect

;; Emacs 29 introduces commands that resize the font across all
;; buffers (including the minibuffer), which is what I want.  The keys
;; are the same as the defaults.
(keymap-global-set "C-x C-=" #'global-text-scale-adjust)
(keymap-global-set "C-x C-+" #'global-text-scale-adjust)
(keymap-global-set "C-x C-0" #'global-text-scale-adjust)
(global-visual-line-mode 1)

(provide 'emacs-jp-theme)

;;; emacs-jp-theme.el ends here
