;;; init.el --- Emacs configuration (use-package native) -*- lexical-binding: t; -*-

;;; Commentary:

;; This is a from-scratch reorganisation of my Emacs setup, migrating
;; from the Protesilaos-style custom macros (jp-emacs-install,
;; jp-emacs-hook, jp-emacs-keybind, ...) to the native, standard Emacs
;; way of doing things: use-package everywhere, package archives for
;; installation and `use-package :vc' for packages fetched from git.

;; The configuration lives in two places:
;;
;;   emacs-jp-lisp/    my own Emacs Lisp helpers (jp-* files) - kept
;;                     as-is, they are not installation concerns.
;;   emacs-jp-modules/ the per-area modules (emacs-jp-<area>.el) that
;;                     do the actual configuration with use-package.

;;; Code:

;; ---------------------------------------------------------------------
;; Global settings that do not belong to any specific package
;; ---------------------------------------------------------------------

(setq make-backup-files nil)
(setq backup-inhibited nil)
(setq create-lockfiles nil)

;; Make native compilation silent.
(when (native-comp-available-p)
  (setq native-comp-async-report-warnings-errors 'silent))

;; Disable the damn thing by making it disposable.
(setq custom-file (make-temp-file "emacs-custom-"))

(setq default-input-method "spanish-prefix") ; also check "greek-postfix"
(setq default-transient-input-method "spanish-prefix")

;; Enable these
(mapc
 (lambda (command)
   (put command 'disabled nil))
 '(list-timers narrow-to-region narrow-to-page upcase-region downcase-region diff-restrict-view))

;; And disable these
(mapc
 (lambda (command)
   (put command 'disabled t))
 '(eshell project-eshell overwrite-mode iconify-frame diary))

(setq initial-buffer-choice t)
(setq initial-major-mode 'lisp-interaction-mode)

(defvar kiss-quotes
  '("Simplicity is the ultimate sophistication."
    "Everything should be made as simple as possible, but not simpler."
    "The best code is no code at all."
    "If you can't explain it simply, you don't understand it well enough."
    "Deleted code is debugged code."
    "KISS: Keep It Simple, Stupid.")
  "A list of KISS-themed quotes.")

(defun jp/scratch-message ()
  "Return a welcome message for the *scratch* buffer with a random KISS quote."
  (let ((chosen-quote (nth (random (length kiss-quotes)) kiss-quotes)))
    (concat
     (format ";; This is `%s'. Type `%s' to evaluate and print results.\n\n"
             'lisp-interaction-mode
             (propertize "C-j" 'face 'help-key-binding))
     (format ";; %s\n\n" chosen-quote))))

(setq initial-scratch-message (jp/scratch-message))

;; ---------------------------------------------------------------------
;; Load path: my own lisp library and the per-area modules.  The
;; library files keep their internal `jp-*' symbol naming, so all the
;; `(require 'jp-...)' they use keep working.
;; ---------------------------------------------------------------------

(defvar emacs-jp-user-dir
  (file-name-directory (or load-file-name buffer-file-name))
  "Directory of the active Emacs configuration.")

(add-to-list 'load-path (expand-file-name "emacs-jp-lisp/" emacs-jp-user-dir))
(add-to-list 'load-path (expand-file-name "emacs-jp-modules/" emacs-jp-user-dir))

;; Apply the same idea to `user-lisp-directory' used by early-init.el.
(setq user-lisp-directory (expand-file-name "emacs-jp-lisp/" emacs-jp-user-dir))

;; ---------------------------------------------------------------------
;; Packages: ELPA archives, priorities and `use-package'.  Installation
;; is handled by `use-package' (with `use-package-always-ensure' set),
;; while packages that must come from a git repository use `:vc'.
;; ---------------------------------------------------------------------

(require 'package)
(setq package-archives
      '(("gnu-elpa" . "https://elpa.gnu.org/packages/")
        ("gnu-elpa-devel" . "https://elpa.gnu.org/devel/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))

;; Highest number gets priority (what is not mentioned has priority 0)
(setq package-archive-priorities
      '(("gnu-elpa" . 4)
        ("melpa" . 3)
        ("gnu-elpa-devel" . 2)
        ("nongnu" . 1)))

(setq package-install-upgrade-built-in nil)
(setq package-vc-register-as-project nil) ; Emacs 30

;; Refresh the package index lazily and initialise packages.
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; ---------------------------------------------------------------------
;; use-package: the standard declarative macro.  Everything after this
;; point relies on it.  With `use-package-always-ensure' set, a bare
;; (use-package foo ...) will install FOO if it is missing.  Packages
;; fetched from git list :vc instead.
;; ---------------------------------------------------------------------

(require 'use-package)
(setq use-package-always-ensure t)
(setq use-package-verbose t)
(setq use-package-compute-statistics t)

;; Make native compilation silent also for use-package.
(setq native-comp-async-report-warnings-errors 'silent)

;; ---------------------------------------------------------------------
;; Toggle user options for the module set.  These were `defcustom's in
;; the old init.el; keep the same names and defaults so the modules are
;; untouched in that regard.
;; ---------------------------------------------------------------------

(defcustom jp-emacs-load-theme-family 'ef
  "Set of themes to load (see the old 'defcustom' for values)."
  :group 'jp-emacs
  :type 'symbol)

(defcustom jp-emacs-completion-ui 'vertico
  "Choose minibuffer completion UI (`mct', `vertico' or nil)."
  :group 'jp-emacs
  :type 'symbol)

(defcustom jp-emacs-completion-extras t
  "When non-nil load extras for minibuffer completion."
  :group 'jp-emacs
  :type 'boolean)

(defcustom jp-emacs-enable-transparency t
  "Non-nil means to enable transparency support for the Emacs frame."
  :group 'jp-emacs
  :type 'boolean)

;; The purpose of this file is for the user to define their
;; preferences BEFORE loading any of the modules.
(load (expand-file-name "emacs-jp-pre-custom.el" emacs-jp-user-dir) :no-error :no-message)

;; ---------------------------------------------------------------------
;; Load the per-area modules.  Each of them relies on `use-package'
;; internally; loading order matters mostly for shared hooks and
;; variables defined in emacs-jp-lisp, so keep the historical order.
;; ---------------------------------------------------------------------

(require 'emacs-jp-00-requirements)

(require 'emacs-jp-theme)
(require 'emacs-jp-essentials)
(require 'emacs-jp-ef-themes)
(require 'emacs-jp-evil)
(require 'emacs-jp-modeline)
(require 'emacs-jp-completion)
(require 'emacs-jp-search)
(require 'emacs-jp-dired)
(require 'emacs-jp-window)
(require 'emacs-jp-git)
(require 'emacs-jp-org)
(require 'emacs-jp-langs)
(when (not (eq system-type 'windows-nt))
  (require 'emacs-jp-spell))
(when (not (eq system-type 'windows-nt))
  (require 'emacs-jp-mu4e))
(require 'emacs-jp-web)
(require 'emacs-jp-which-key)
(require 'emacs-jp-icons)
(require 'emacs-jp-general)
(require 'emacs-jp-code)
(require 'emacs-jp-utils)
(require 'emacs-jp-x0)
(require 'emacs-jp-yasnippets)
(when (not (eq system-type 'windows-nt))
  (require 'emacs-jp-telega))

;; The purpose of the "post customisations" is to evaluate arbitrary
;; code AFTER loading all my configurations.
(load (expand-file-name "emacs-jp-post-custom.el" emacs-jp-user-dir) :no-error :no-message)

(provide 'init)

;;; init.el ends here
