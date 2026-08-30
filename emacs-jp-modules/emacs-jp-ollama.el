;;; emacs-jp-ollama.el --- Simple ollama integration -*- lexical-binding: t; -*-

;;; Commentary:

;; Ellama for AI assistance and a helper to run a selected ollama model
;; in an ansi-term.

;;; Code:

(use-package ellama
  :config
  (defun jp/ollama-run-model ()
    "Run `ollama list', select a model and open it in ansi-term."
    (interactive)
    (let* ((output (shell-command-to-string "ollama list"))
           (models
            (let ((lines (split-string output "\n" t)))
              (mapcar (lambda (line)
                        (car (split-string line)))
                      (cdr lines))))
           (selected
            (completing-read "Select Ollama model: " models nil t))
           (region-text
            (when (use-region-p)
              (shell-quote-argument
               (replace-regexp-in-string
                "\n" " "
                (buffer-substring-no-properties
                 (region-beginning)
                 (region-end))))))
           (prompt
            (read-string
             "Ollama Prompt (leave blank for interactive): ")))

      (when (and selected (not (string-empty-p selected)))
        (ansi-term "/bin/sh")
        (sit-for 1)

        (let ((args (list (format "ollama run %s" selected))))

          (when (and prompt (not (string-empty-p prompt)))
            (setq args
                  (append args (list (format "\"%s\"" prompt)))))

          (when region-text
            (setq args
                  (append args (list (format "\"%s\"" region-text)))))

          (term-send-raw-string (string-join args " "))
          (term-send-raw-string "\n"))))))

(provide 'emacs-jp-ollama)

;;; emacs-jp-ollama.el ends here
