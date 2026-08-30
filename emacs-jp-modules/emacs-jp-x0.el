;;; emacs-jp-x0.el --- Upload to x0.at -*- lexical-binding: t; -*-

;;; Commentary:

;; Commands to upload text or files to the x0.at paste service.

;;; Code:

(defun jp/x0-upload-text ()
  "Upload region or buffer contents to https://x0.at."
  (interactive)
  (let* ((contents (if (use-region-p)
                       (buffer-substring-no-properties
                        (region-beginning)
                        (region-end))
                     (buffer-string)))
         (temp-file (make-temp-file "x0" nil ".txt" contents)))
    (message "Sending %s to x0.at..." temp-file)
    (let ((url (string-trim-right
                (shell-command-to-string
                 (format "curl -s -F'file=@%s' https://x0.at" temp-file)))))
      (message "The URL is %s" url)
      (kill-new url)
      (delete-file temp-file))))

(defun jp/x0-upload-file (file-path)
  "Upload FILE-PATH to https://x0.at."
  (interactive "fSelect a file to upload: ")
  (message "Sending %s to x0.at..." file-path)
  (let ((url (string-trim-right
              (shell-command-to-string
               (format "curl -s -F'file=@%s' https://x0.at"
                       (expand-file-name file-path))))))
    (message "The URL is %s" url)
    (kill-new url)))

(provide 'emacs-jp-x0)

;;; emacs-jp-x0.el ends here
