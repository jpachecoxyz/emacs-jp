;;; emacs-jp-hugo.el --- Ox-hugo configuration -*- lexical-binding: t; -*-

;;; Commentary:

;; For writing my webpage posts with ox-hugo.

;;; Code:

(use-package ox-hugo
  :config
  (require 'ox-hugo)
  (with-eval-after-load 'ox
    (require 'ox-hugo)))

(setq org-hugo-base-dir "~/webdev/jpachecoxyz/")

(defun jp/create-hugo-post ()
  "Create a new Hugo post with metadata."
  (interactive)
  (let* ((title (read-string "Post title: "))
         (description (read-string "Post description: "))
         (tags (read-string "Tags (separated by spaces): "))
         (is-draft (y-or-n-p "Is this a draft? "))
         (slug (replace-regexp-in-string " " "-" (downcase title)))
         (file-name (concat slug ".org"))
         (file-path (expand-file-name
                     file-name
                     "~/webdev/jpachecoxyz/org/posts/"))
         (date (format-time-string "%Y-%m-%d"))
         (draft-string (if is-draft "true" "false")))

    (find-file file-path)

    (insert (format "#+title: %s\n" title))
    (insert (format "#+description: %s\n" description))
    (insert (format "#+date: %s\n" date))
    (insert (format "#+export_file_name: %s\n" slug))
    (insert "#+hugo_base_dir: ~/webdev/jpachecoxyz/\n")
    (insert "#+hugo_section: posts\n")
    (insert (format "#+hugo_tags: %s\n" tags))
    (insert "#+hugo_custom_front_matter: toc true\n")
    (insert "#+hugo_auto_set_lastmod: nil\n")
    (insert (format "#+hugo_draft: %s\n" draft-string))

    (goto-char (point-max))
    (insert "\n")
    (set-buffer-modified-p t)))

(global-set-key (kbd "C-c n p") #'jp/create-hugo-post)

(provide 'emacs-jp-hugo)

;;; emacs-jp-hugo.el ends here
