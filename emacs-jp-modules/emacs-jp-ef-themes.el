;;; emacs-jp-ef-themes.el --- The Ef (εὖ) themes -*- lexical-binding: t; -*-

;;; Commentary:

;; Installs, configures and loads the Ef themes (and the Pixel Themes).

;;; Code:

(use-package ef-themes
  :config
  (ef-themes-take-over-modus-themes-mode 1)

  (setq modus-themes-variable-pitch-ui t
        modus-themes-mixed-fonts t
        modus-themes-bold-constructs t
        modus-themes-italic-constructs t
        modus-themes-to-rotate nil ; defaults to the return value of `modus-themes-get-themes'
        modus-themes-headings ; read the manual's entry of the doc string
        '((0 . (variable-pitch light italic 1.8))
          (1 . (variable-pitch regular 1.0))
          (2 . (variable-pitch regular 1.0))
          (3 . (variable-pitch regular 1.0))
          (4 . (variable-pitch regular 1.0))
          (5 . (variable-pitch 1.0)) ; absence of weight means `bold'
          (6 . (variable-pitch 1.0))
          (7 . (variable-pitch 1.0))
          (agenda-date . (semilight 1.0))
          (agenda-structure . (variable-pitch light 1.0))
          (t . (variable-pitch 1.0))))

  (load-theme 'pixel-themes-miri16))

(provide 'emacs-jp-ef-themes)

;;; emacs-jp-ef-themes.el ends here
