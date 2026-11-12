;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Private Doom configuration. Changes to this file do not require doom sync.

(defvar my/lab-proxy
  (when (string-suffix-p ".metax-tech.com" (system-name))
    "http://proxy.swlab.metax-tech.com:1080")
  "HTTP proxy for the lab network, or nil on machines that need none.")

;;; Appearance and core settings

(setq doom-font (font-spec :family "YaHei Consolas Hybrid" :size 30)
      doom-symbol-font (font-spec :family "TsangerJinKai03" :size 30))

(setq doom-theme 'doom-one)

(setq doom-themes-enable-italic nil)

(setq display-line-numbers-type t)

(setq nerd-icons-font-names '("SymbolsNerdFont-Regular.ttf"))

(setq doom-localleader-key ",")

;; Show prefix menus promptly
(setq which-key-idle-delay 0.3
      which-key-idle-secondary-delay 0.1)

(setq confirm-kill-emacs nil)

(after! doom-modeline
  (setq doom-modeline-buffer-file-name-style 'relative-to-project))


;;; Editing, navigation, and files

(defun my/gt-overlay-dismiss-keys (translator)
  "Make TRANSLATOR's inline results dismissible with q or C-g."
  (let* ((source (car (oref translator bounds)))
         (dismiss (lambda ()
                    (interactive)
                    (when (buffer-live-p source)
                      (with-current-buffer source
                        (save-restriction
                          (widen)
                          (gt-delete-render-overlays (point-min) (point-max)))))))
         (map (make-sparse-keymap)))
    (define-key map (kbd "q") dismiss)
    (define-key map (kbd "C-g") dismiss)
    (set-transient-map
     map
     (lambda ()
       (and (eq (current-buffer) source)
            (save-restriction
              (widen)
              (gt-overlay-render-get-overlays (point-min) (point-max)))))
     dismiss)))

(use-package! gt
  :commands gt-translate
  :init
  (map! :leader :desc "Translate English/Chinese" "o g" #'gt-translate)
  :config
  (setq gt-langs '(en zh)
        gt-http-backend (pdd-url-backend)
        gt-http-proxy my/lab-proxy
        gt-default-translator
        (gt-translator
         :taker (gt-taker :text 'word :pick nil :prompt nil)
         :engines (gt-google-engine)
         :render (gt-overlay-render :type 'after :sface nil
                                    :then #'my/gt-overlay-dismiss-keys))))
(setq gt-source-text-transformer
      (lambda (c engine )
        (string-replace "\n" " " c)))

(defun my/gt-overlay-fill-a (orig render src res prefix)
  "Fill paragraph translations from ORIG to `fill-column'.
Google returns one line per paragraph, and an overlay string is not
filled, so long results become very long lines.  Words are left as is."
  (let ((str (funcall orig render src res prefix))
        (width fill-column))
    (if (gt-word-p nil src)
        str
      (with-temp-buffer
        (insert str)
        (let ((fill-column width))
          (fill-region (point-min) (point-max)))
        (buffer-string)))))
(advice-add 'gt-overlay-render-format :around #'my/gt-overlay-fill-a)

(use-package! consult
  :config
  (add-to-list 'consult-preview-allowed-hooks 'breadcrumb-mode)
  (map! "C-s" #'consult-line)
  (map! :map minibuffer-local-map "C-r" #'consult-history)
  (consult-customize
   +default/search-project +default/search-other-project
   +default/search-project-for-symbol-at-point
   +default/search-cwd +default/search-other-cwd
   +default/search-notes-for-symbol-at-point
   +default/search-emacsd
   :preview-key '(:debounce 0.2 any)))

(map! :leader
  (:prefix "c" ;; Code
           :desc "Comment line" "l" #'comment-line
           :desc "Comment/Copy line" "y" #'evilnc-copy-and-comment-lines))

(use-package! auto-save
  :config
  (auto-save-enable)
  (setq auto-save-slient t))

(after! evil-escape
  (setq evil-escape-key-sequence "kj")
  ;; Allow to escape from the visual state as from insert.
  (delete 'visual evil-escape-excluded-states)
  (setq-default evil-escape-delay 0.5)
  (setq evil-escape-excluded-major-modes '(dired-mode))
  (setq evil-escape-excluded-major-modes
        (list 'magit-status-mode
              'magit-refs-mode
              'magit-log-mode
              'magit-revision-mode
              'compilation-mode
              'magit-stash-mode))
  (evil-escape-mode 1))

(add-hook 'emacs-startup-hook
          (lambda ()
            (require 'yasnippet)
            (yas-global-mode 1)))

(after! yasnippet
  (setq yas-snippet-dirs
        (list (expand-file-name "snippets/" doom-user-dir)))
  (yas-reload-all))

(use-package dired-hide-dotfiles
  :hook (dired-mode . dired-hide-dotfiles-mode)
  :config
  (evil-collection-define-key 'normal 'dired-mode-map
    "H" 'dired-hide-dotfiles-mode))

(global-auto-revert-mode 1)

(after! autorevert
  (setq auto-revert-avoid-polling t)
  (setq auto-revert-use-notify t))

(use-package! expand-region
  :config
  (setq expand-region-contract-fast-key "z")
  ;; Bind in visual mode using map!
  (map! :v "v" #'er/expand-region))

(use-package! ace-window
  :config
  (global-set-key (kbd "M-o") 'ace-window))

(use-package! symbol-overlay
  :hook (prog-mode . symbol-overlay-mode)
  :init
  (map! :leader
    :desc "Toggle symbol overlay"
    "i o" #'symbol-overlay-put
    :desc "Remove all symbol overlay"
    "i q" #'symbol-overlay-remove-all)
  :config
  (map! :map symbol-overlay-map
    "h" nil))


;;; C/C++, compilation, and code navigation

(use-package! citre
  :config
  (map!
    (:map prog-mode-map
          "M-]" #'citre-jump
          ;; "M-[" #'citre-jump-back
          "C-x c p" #'citre-peek)
    (:map citre-peek-keymap
          "C-l" #'citre-peek-next-tag
          "C-h" #'citre-peek-prev-tag))
  (setq citre-project-root-function #'projectile-project-root)
  (custom-set-variables '(citre-find-definition-backends '(tags eglot))))

(setq smart-compile-alist
      '(("\\.c\\'" . "gcc -g -Wall %f -o %n.bin")
        ("\\.[Cc]+[Pp]*\\'" . "g++ -g -Wall %f  -o %n.bin")))

(after! quickrun
  (quickrun-add-command "c/gcc"
    '((:exec . ("%c -x c -Wall -Werror %o -o %e %s"
                "%e %a")))
    :override t)
  (quickrun-add-command "cuda/nvcc"
    '((:command . "/usr/local/cuda/bin/nvcc")
      (:exec    . ("%c %o -o %e %s"
                   "%e %a"))
      (:remove  . ("%e")))
    :default "cuda")

  (add-to-list 'quickrun-file-alist '("\\.cu$" . "cuda/nvcc")))

(defun bury-compile-buffer-if-successful (buffer string)
  "Bury a compilation buffer if it succeeded without warnings or errors."
  (when (and (buffer-live-p buffer)
             (string-match-p "compilation" (buffer-name buffer))
             (string-match-p "finished" string)
             (not (with-current-buffer buffer
                    (goto-char (point-min))
                    (or (search-forward "warning" nil t)
                        (search-forward "error" nil t)))))
    (run-with-timer
     1 nil
     (lambda ()
       (let ((compilation-window (get-buffer-window buffer)))
         (when (and compilation-window (window-live-p compilation-window))
           (delete-window compilation-window)))))
    (message "No Compilation Warnings or Errors!")))

(add-hook 'compilation-finish-functions #'bury-compile-buffer-if-successful)

(use-package! clang-format
  :defer t)

(map! :map c-mode-map
  :localleader
  :desc "Format region or buffer" "=r" #'doom/clang-format-region-or-buffer
  :desc "Format function" "=f" #'doom/clang-format-function)

(map! :map c-ts-mode-map
  :localleader
  :desc "Format region or buffer" "=r" #'doom/clang-format-region-or-buffer
  :desc "Format function" "=f" #'doom/clang-format-function)

(map! :map c++-mode-map
  :localleader
  :desc "Format region or buffer" "=r" #'doom/clang-format-region-or-buffer
  :desc "Format function" "=f" #'doom/clang-format-function)

(map! :map c++-ts-mode-map
  :localleader
  :desc "Format region or buffer" "=r" #'doom/clang-format-region-or-buffer
  :desc "Format function" "=f" #'doom/clang-format-function)

(defun doom/clang-format-function (&optional style)
  "Format the current function with clang-format according to STYLE.
Works for standard C/C++ modes and Tree-sitter modes."
  (interactive)
  (save-excursion
    (if (or (eq major-mode 'c-ts-mode)
            (eq major-mode 'c++-ts-mode))
        ;; Tree-sitter logic: Use treesit-defun-at-point
        (let ((defun-node (treesit-defun-at-point)))
          (if defun-node
              (let ((start (treesit-node-start defun-node))
                    (end (treesit-node-end defun-node)))
                (clang-format start end style)
                (message "Formatted function (Tree-sitter mode)"))
            (user-error "Could not find function boundary (Tree-sitter)")))

      ;; Standard C/C++ mode logic: Use c-mark-function
      (c-mark-function)
      (clang-format (region-beginning) (region-end) style)
      (deactivate-mark)
      (message "Formatted function %s" (c-defun-name)))))

(defun doom/clang-format-region-or-buffer ()
  "Format the region if active, otherwise format the buffer."
  (interactive)
  (if (use-region-p)
      (clang-format-region (region-beginning) (region-end))
    (clang-format-buffer)))

(add-hook 'after-init-hook #'breadcrumb-mode)

(defun my/breadcrumb-refresh-after-eglot ()
  "Invalidate breadcrumb's index when Eglot changes the Imenu provider."
  (when (bound-and-true-p breadcrumb-local-mode)
    (setq-local imenu--index-alist nil
                breadcrumb--ipath-plain-cache nil
                breadcrumb--last-update-tick 0)
    ;; Let breadcrumb rebuild the index on idle, after Eglot finishes setup.
    (force-mode-line-update t)))

(add-hook 'eglot-managed-mode-hook #'my/breadcrumb-refresh-after-eglot)

(defun my/asm-comment-tweak ()
  (setq-local comment-start "// "))

(eval-after-load "asm"
  (add-hook 'asm-mode-hook #'my/asm-comment-tweak))

(use-package! eglot
  :config
  (add-hook 'eglot-managed-mode-hook
            (lambda ()
              (map! :map eglot-mode-map
                :n "gr"  #'xref-find-references
                :n "C-t" #'better-jumper-jump-backward
                :n "C-i" #'better-jumper-jump-forward
                :i "C-i" #'complete-symbol)
              (evil-normalize-keymaps))
            100)
  (setq eglot-ignored-server-capabilities
        '(:hoverProvider
          ;; :documentSymbolProvider
          :workspaceSymbolProvider
          :documentLinkProvider
          :executeCommandProvider
          :inlayHintProvider))
  (add-to-list 'eglot-server-programs
               '((c-mode c-ts-mode c++-mode c++-ts-mode) .
                 ("clangd"
                  "--clang-tidy"
                  "--all-scopes-completion"
                  "--header-insertion=never"
                  "--completion-style=detailed"
                  "--header-insertion-decorators=0"))))

(use-package! eglot-inactive-regions
  :custom
  (eglot-inactive-regions-style 'darken-foreground)
  (eglot-inactive-regions-opacity 0.4)
  :config
  (eglot-inactive-regions-mode 1))

(use-package! c-ts-mode
  :config
  (add-to-list 'auto-mode-alist '("\\.cu[h]?\\'" . c++-ts-mode))
  (add-hook 'c++-ts-mode-hook
            (lambda ()
              (when (string-match-p "\\.cu[h]?\\'" buffer-file-name)
                (setq-local treesit-language-remap-alist '((cpp . cuda)))))))

(setq c-ts-mode-indent-style 'linux)
;; Doom guesses `c-basic-offset' as the indent var for c-ts-mode. Once helpful
;; loads cc-vars without cc-mode, that is still `set-from-style', and copying
;; it into `tab-width' breaks opening C files. Keep `tab-width' as is.
(set-indent-vars! '(c-ts-mode c++-ts-mode) 'tab-width)

(defun my/c-kernel-indent-h ()
  "Use Linux kernel indentation: 8-column tabs for each level."
  (setq-local c-ts-mode-indent-offset 8
              tab-width 8
              standard-indent 8
              indent-tabs-mode t))
(add-hook 'c-ts-mode-hook #'my/c-kernel-indent-h)

(defun my/quickrun-c-snippet ()
  "Wrap the selected region (or current line) in a minimal C program,
run it with quickrun, and keep the temp buffer invisible/cleaned up."
  (interactive)
  (let* ((code (if (use-region-p)
                   (buffer-substring-no-properties (region-beginning) (region-end))
                 (thing-at-point 'line t)))
         (wrapped (concat "#include <stdio.h>\n"
                          "#include <string.h>\n"
                          "#include <stdlib.h>\n\n"
                          "int main(void) {\n"
                          code
                          "\n    return 0;\n}\n"))
         (tmpfile (make-temp-file "qr_snippet" nil ".c"))
         (tmpbuf (find-file-noselect tmpfile)))
    (with-current-buffer tmpbuf
      (insert wrapped)
      (save-buffer)
      ;; Hide from buffer list: leading space = internal buffer
      (rename-buffer (concat " *qr-snippet-" (file-name-nondirectory tmpfile) "*") t)
      (quickrun)
      ;; Clean up buffer + file once quickrun's process finishes
      (letrec ((cleanup
                (lambda (&rest _)
                  (when (buffer-live-p tmpbuf)
                    (kill-buffer tmpbuf))
                  (when (file-exists-p tmpfile)
                    (delete-file tmpfile))
                  (remove-hook 'quickrun-after-run-hook cleanup))))
        (add-hook 'quickrun-after-run-hook cleanup)))))

(map! :leader
  :desc "Quickrun C snippet"
  "c q" #'my/quickrun-c-snippet)

(use-package! leetcode
  :config
  (setq leetcode-prefer-language "c"))


;;; Debugging

(setq gdb-debuginfod-enable-setting nil)

(defun my-gud-mode-exit ()
  "Exit GUD mode and delete the window."
  (interactive)
  (let ((debugger-buffer (current-buffer))
        (debugger-window (selected-window)))
    (quit-window)
    (delete-window debugger-window)
    (kill-buffer debugger-buffer)
    (gud-basic-call "quit")))

(add-hook 'gud-mode-hook
          (lambda ()
            (local-set-key (kbd "q") 'my-gud-mode-exit)))

(use-package! dape
  :config
  ;; (setq dape-buffer-window-arrangement 'right)
  (add-hook 'dape-display-source-hook 'pulse-momentary-highlight-one-line)
  (setq completion-in-region-function #'corfu--in-region))


;;; Markdown

(use-package! markdown-ts-appear
  :hook (markdown-ts-mode . markdown-ts-appear-mode))


;;; Org, capture, and notes

(setq org-directory "~/org/")

(after! org
  (setq org-todo-keyword-faces '(("TODO" . "red")
                                 ("DOING" . "yellow")
                                 ("DONE" . "green")))
  (setq org-todo-keywords '((sequence "TODO(t!)" "DOING(i!)" "|" "DONE(d!)" "ABORT(a!)")))
  (setq org-capture-templates '(("t" "Todo [inbox]" entry
                                 (file+headline "~/Dropbox/org/gtd.org" "Tasks")
                                 "* TODO %i%?")
                                ("j" "Journal"  entry
                                 (file+datetree "~/Dropbox/org/journal/journal-2025.org")
                                 "* %U - %^{heading} %^g\n %?\n")
                                ("n" "Notes" entry (file "~/Dropbox/org/inbox.org")
                                 "* %^{heading}  %^g\n  %?\n")))
  (add-hook 'org-mode-hook 'org-download-enable)
  ;; hidden org-download annotation
  (setq org-download-annotate-function (lambda (_link) ""))
  (setq-default org-download-heading-lvl nil)
  (setq-default org-download-image-dir "./img")

  ;; https://zzamboni.org/post/beautifying-org-mode-in-emacs/
  (defun my-org-faces ()
    ;; (set-face-attribute 'org-todo nil :height 0.8)
    (set-face-attribute 'org-level-1 nil :height 1.75)
    (set-face-attribute 'org-level-2 nil :height 1.5)
    (set-face-attribute 'org-level-3 nil :height 1.25)
    (set-face-attribute 'org-level-4 nil :height 1.1))
  (add-hook 'org-mode-hook #'my-org-faces)

  (font-lock-add-keywords 'org-mode
                          '(("^ +\\([-*]\\) "
                             (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

  (setq org-hide-emphasis-markers t)
  (add-hook 'org-mode-hook 'org-appear-mode)

  (setq org-emphasis-alist
        '(("*" my-org-emphasis-bold)
          ("/" my-org-emphasis-italic)
          ("_" my-org-emphasis-underline)
          ("=" org-verbatim verbatim)
          ("~" org-code verbatim)
          ("+" my-org-emphasis-strike-through)))
  (defface my-org-emphasis-bold
    '((default :inherit bold)
      (((class color) (min-colors 88) (background light))
       :foreground "#a60000")
      (((class color) (min-colors 88) (background dark))
       :foreground "#ffb259"))
    "My bold emphasis for Org.")
  (defface my-org-emphasis-italic
    '((default :inherit italic)
      (((class color) (min-colors 88) (background light))
       :foreground "#005e00")
      (((class color) (min-colors 88) (background dark))
       :foreground "#44bc44"))
    "My italic emphasis for Org.")

  (defface my-org-emphasis-underline
    '((default :inherit underline)
      (((class color) (min-colors 88) (background light))
       :foreground "#813e00")
      (((class color) (min-colors 88) (background dark))
       :foreground "#d0bc00"))
    "My underline emphasis for Org.")
  (defface my-org-emphasis-strike-through
    '((((class color) (min-colors 88) (background light))
       :strike-through "#972500" :foreground "#505050")
      (((class color) (min-colors 88) (background dark))
       :strike-through "#ef8b50" :foreground "#a8a8a8"))
    "My strike-through emphasis for Org."))

(require 'org-tempo)

(after! org-roam
  (setq org-roam-directory "~/Dropbox/org/roam/")
  (setq org-agenda-files '("~/Dropbox/org/gtd.org"))
  (setq org-roam-db-update-on-save nil)
  (run-with-idle-timer 10 t 'org-roam-db-sync)
  (cl-defmethod org-roam-node-directories ((node org-roam-node))
    (if-let ((dirs (file-name-directory (file-relative-name (org-roam-node-file node) org-roam-directory))))
        (format "(%s)" (car (f-split dirs)))
      ""))

  (cl-defmethod org-roam-node-backlinkscount ((node org-roam-node))
    (let* ((count (caar (org-roam-db-query
                         [:select (funcall count source)
                                  :from links
                                  :where (= dest $s1)
                                  :and (= type "id")]
                         (org-roam-node-id node)))))
      (format "[%d]" count)))
  (setq org-roam-node-display-template "${directories:10} ${tags:10} ${title:50} ${backlinkscount:6}")
  (defun org-roam-node-insert-immediate (arg &rest args)
    (interactive "P")
    (let ((args (cons arg args))
          (org-roam-capture-templates (list (append (car org-roam-capture-templates)
                                                    '(:immediate-finish t)))))
      (apply #'org-roam-node-insert args)))

  (setq org-roam-mode-sections
        (list #'org-roam-backlinks-section
              #'org-roam-reflinks-section
              'org-roam-unlinked-references-section)))

(defun my/open-org-inbox-file ()
  "Open ~/Dropbox/org/inbox.org file"
  (interactive)
  (find-file "~/Dropbox/org/inbox.org"))

(global-set-key (kbd "<f12>") 'my/open-org-inbox-file)

(defun my/open-org-journal-file ()
  "Open ~/Dropbox/org/journal/journal-2025.org file"
  (interactive)
  (find-file "~/Dropbox/org/journal/journal-2025.org"))

(global-set-key (kbd "<f9>") 'my/open-org-journal-file)

(after! deft
  (setq deft-recursive t
        deft-directory "~/Dropbox/org/roam/"
        deft-strip-summary-regexp ":PROPERTIES:\n\\(.+\n\\)+:END:\n"
        deft-use-filename-as-title 't))

(use-package! org-media-note
  :hook (org-mode . org-media-note-mode)
  :bind (("M-m" . org-media-note-show-interface))  ;; 主功能入口
  :config
  (setq org-media-note-screenshot-image-dir "~/Dropbox/org/roam/org-media-imgs/")  ;; 用于存储视频截图的目录
  (add-to-list 'org-media-note-mpv-online-website-options-alist
               '("\\(youtube\\.com\\|youtu\\.be\\)"
                 "--ytdl-raw-options=proxy=http://127.0.0.1:7788"))
  (add-to-list 'org-media-note-mpv-online-website-options-alist
               '("\\(bilibili\\.com\\)"
                 "--referrer=https://www.bilibili.com"
                 "--ytdl-raw-options=cookies-from-browser=[chrome]")))


;;; Input method

(use-package! rime
  :defer t
  :custom
  (rime-user-data-dir (expand-file-name "~/.config/emacs-rime/"))
  (default-input-method "rime")
  (rime-show-candidate 'posframe)
  (rime-disable-predicates
   '(rime-predicate-prog-in-code-p
     rime-predicate-auto-english-p
     rime-predicate-punctuation-after-ascii-p
     rime-predicate-punctuation-line-begin-p
     rime-predicate-current-uppercase-letter-p))
  :config
  (custom-set-faces!
    `(rime-default-face :background ,(doom-blend 'blue 'base0 0.15)))
  (define-key rime-mode-map (kbd "C-;") 'rime-force-enable)
  (defun rime-evil-escape-advice (orig-fun key)
    "advice for `rime-input-method' to make it work together with `evil-escape'.
        Mainly modified from `evil-escape-pre-command-hook'"
    (if rime--preedit-overlay
        ;; if `rime--preedit-overlay' is non-nil, then we are editing something, do not abort
        (apply orig-fun (list key))
      (when (featurep 'evil-escape)
        (let ((fkey (elt evil-escape-key-sequence 0))
              (skey (elt evil-escape-key-sequence 1)))
          (if (or (char-equal key fkey)
                  (and evil-escape-unordered-key-sequence
                       (char-equal key skey)))
              (let ((evt (read-event nil nil evil-escape-delay)))
                (cond
                 ((and (characterp evt)
                       (or (and (char-equal key fkey) (char-equal evt skey))
                           (and evil-escape-unordered-key-sequence
                                (char-equal key skey) (char-equal evt fkey))))
                  (evil-repeat-stop)
                  (evil-normal-state))
                 ((null evt) (apply orig-fun (list key)))
                 (t
                  (apply orig-fun (list key))
                  (if (numberp evt)
                      (apply orig-fun (list evt))
                    (setq unread-command-events (append unread-command-events (list evt)))))))
            (apply orig-fun (list key)))))))

  (advice-add 'rime-input-method :around #'rime-evil-escape-advice))


;;; Version control and diffs

(defun my/gerrit-evil-dashboard-keys (mode map keys)
  "Keep dashboard MAP's KEYS accessible in Evil for MODE."
  (evil-set-initial-state mode 'motion)
  (dolist (key keys)
    (evil-define-key* '(normal motion) map (kbd key) (lookup-key map (kbd key)))))

(defun my/egerrit-publish-comments ()
  "Send and publish comments before closing the Egerrit review once."
  (interactive)
  (unless (and (boundp 'egerrit--current-change)
               (egerrit-change-p egerrit--current-change)
               (boundp 'egerrit--current-revision)
               (egerrit-revision-p egerrit--current-revision))
    (user-error "Publish comments from an active Egerrit review or conversation buffer"))
  (let ((change egerrit--current-change)
        (revision egerrit--current-revision))
    ;; Egerrit's requests are synchronous; no timer or intermediate quit needed.
    (egerrit-send-draft-comments)
    (egerrit-post-draft-comments change revision)
    (egerrit-quit-review-or-feedback)))

(defvar my/egerrit-comment-change-id nil
  "Unambiguous Gerrit change identifier for the current detail request.")

(defun my/egerrit-with-comment-change-id (original data)
  "Scope comment lookups to the full change identifier in DATA."
  (let ((my/egerrit-comment-change-id (alist-get 'id data)))
    (funcall original data)))

(defun my/egerrit-read-comments (original change-id)
  "Avoid ambiguous bare Change-Ids when retrieving comments."
  (funcall original (or my/egerrit-comment-change-id change-id)))

(defun my/egerrit-hide-windows ()
  "Hide Egerrit windows on this frame, preserving buffers and comments."
  (interactive)
  (dolist (window (window-list))
    (when (and (window-live-p window)
               (with-current-buffer (window-buffer window)
                 (string-prefix-p "egerrit-" (symbol-name major-mode))))
      (quit-window nil window)
      ;; A window's previous buffer can also belong to Egerrit.
      (when (and (window-live-p window)
                 (with-current-buffer (window-buffer window)
                   (string-prefix-p "egerrit-" (symbol-name major-mode))))
        (set-window-buffer window (get-buffer-create "*scratch*"))))))

(use-package! egerrit
  :commands egerrit-dashboard
  :init
  (setq egerrit-request-url "codereview.sh.metax-internal.com")
  (map! :leader
        (:prefix ("g /" . "Gerrit")
         :desc "Egerrit dashboard" "e" #'egerrit-dashboard))
  :config
  (advice-add 'egerrit--create-detailed-change :around #'my/egerrit-with-comment-change-id)
  (advice-add 'egerrit--read-comments :around #'my/egerrit-read-comments)
  ;; Upstream's publisher quits twice and loses buffer-local review context.
  (advice-add 'egerrit-publish-comments :override #'my/egerrit-publish-comments)
  ;; The internal Gerrit server is reachable directly, not via the web proxy.
  (setq egerrit--request-curl-options
        '("--silent" "--show-error" "--noproxy" "codereview.sh.metax-internal.com"))
  ;; Use queries supported by this server; omit is:ignored and assignee filters.
  (setf (alist-get "Gerrit Dashboard" egerrit-changes-queries nil nil #'equal)
        '(("Has draft comments" . ("has:draft"))
          ("Your turn" . ("attention:self"))
          ("Work in progress" . ("is:open owner:self is:wip"))
          ("Outgoing reviews" . ("is:open owner:self -is:wip"))
          ("Incoming reviews" . ("is:open -owner:self -is:wip reviewer:self"))
          ("CCed on" . ("is:open cc:self"))
          ("Recently closed" . ("is:closed (owner:self OR reviewer:self OR cc:self)" 20))))
  (add-to-list 'egerrit-project-configs
               '(:name "MACA/driver/metax"
                 :code-repo "~/work/maca/driver/metax"))
  (my/gerrit-evil-dashboard-keys
   'egerrit-dashboard-mode egerrit-dashboard-mode-map
   '("a" "B" "c" "g" "i" "r" "s" "v" "y" "<return>" "S-<return>" "?"))
  (evil-define-key* '(normal motion) egerrit-dashboard-mode-map
    (kbd "q") #'my/egerrit-hide-windows)
  ;; Terminal Enter can generate RET instead of the GUI <return> event.
  (evil-define-key '(normal motion) egerrit-dashboard-mode-map
    (kbd "RET") #'egerrit-author-review-change)
  (transient-suffix-put 'egerrit-reviewer-dispatch 'egerrit-review-change :key "RET")
  (transient-suffix-put 'egerrit-dispatch 'egerrit-author-review-change :key "RET")
  (dolist (mode '(egerrit-conversation-mode egerrit-diff-mode))
    (evil-set-initial-state mode 'normal))
  (dolist (map (list egerrit-diff-mode-map egerrit-conversation-mode-map))
    (evil-define-key* '(normal motion visual) map
      (kbd "C-c") (lookup-key map (kbd "C-c"))))
  (evil-define-key* '(normal motion) egerrit-conversation-mode-map
    (kbd "RET") #'egerrit-visit-conversation
    (kbd "<return>") #'egerrit-visit-conversation))

(use-package! magit
  :config
  (setq magit-revision-insert-related-refs nil)
  (remove-hook 'magit-status-sections-hook 'magit-insert-status-headers)

  (defun run-projectile-invalidate-cache (&rest _args)
    ;; We ignore the args to `magit-checkout'.
    (projectile-invalidate-cache nil))
  (advice-add 'magit-checkout
              :after #'run-projectile-invalidate-cache)
  (advice-add 'magit-branch-and-checkout ; This is `b c'.
              :after #'run-projectile-invalidate-cache)
  (advice-add 'magit-branch-checkout ; This is `b l'.
              :after #'run-projectile-invalidate-cache)
  (advice-add 'magit-pull-from-upstream ; This is `F u'.
              :after #'run-projectile-invalidate-cache))

(defun disable-y-or-n-p (orig-fun &rest args)
  (cl-letf (((symbol-function 'y-or-n-p) (lambda (prompt) t)))
    (apply orig-fun args)))

(advice-add 'ediff-quit :around #'disable-y-or-n-p)


;;; Terminals and Codex

(defun my-codex-proxy-environment (_buffer-name _directory)
  "Give Codex the proxy required for account and workspace discovery."
  (when my/lab-proxy
    (mapcar (lambda (var) (concat var "=" my/lab-proxy))
            '("HTTP_PROXY" "HTTPS_PROXY" "http_proxy" "https_proxy"))))

(defun my/ghostel-insert-on-select (win)
  "Enter insert state when WIN, showing this ghostel buffer, is selected.
Skip it while point is away from the live prompt (scrolled up, copy mode),
because insert-state entry snaps point back to the terminal cursor."
  (when (and (eq (window-buffer win) (current-buffer))
             (eq ghostel--input-mode 'semi-char)
             (ghostel-point-on-cursor-row-p))
    (evil-insert-state)))

(add-hook 'ghostel-mode-hook
          (lambda ()
            (add-hook 'window-selection-change-functions
                      #'my/ghostel-insert-on-select nil t)))

(defun my-codex-ide-proxy-environment (environment)
  "Add the working Codex proxy settings to ENVIRONMENT."
  (append (my-codex-proxy-environment nil nil) environment))

(use-package! codex-ide
  :commands (codex-ide codex-ide-menu)
  :init
  (setq codex-ide-new-session-split 'vertical)
  (map! :leader :desc "Codex IDE menu" "o X" #'codex-ide-menu)
  :config
  (advice-add 'codex-ide--app-server-process-environment :filter-return
              #'my-codex-ide-proxy-environment))

(defun my/claude-code-ide-with-proxy (original &rest args)
  "Start Claude with the working proxy and direct access to local MCP servers."
  (let* ((bypass (mapconcat #'identity
                           (delq nil (list "localhost,127.0.0.1,::1"
                                           (getenv "NO_PROXY") (getenv "no_proxy")))
                           ","))
         (environment (append (my-codex-proxy-environment nil nil)
                              (list (concat "NO_PROXY=" bypass)
                                    (concat "no_proxy=" bypass))))
         (process-environment (append environment process-environment)))
    (apply original args)))

(use-package! ghostel
  :defer t
  :init
  ;; Keep the native module out of straight's build dir so `doom sync'
  ;; rebuilds don't delete it while Emacs has it loaded.
  (setq ghostel-module-directory (expand-file-name "ghostel/" doom-data-dir)
        ghostel-module-auto-install 'download)
  :config
  ;; Let M-o (`ace-window') and M-0..M-9 (`+workspace/switch-to-N') reach
  ;; Emacs instead of the terminal.  `setopt' runs the :set function, which
  ;; rebuilds `ghostel-semi-char-mode-map'.
  (setopt ghostel-keymap-exceptions
          (append '("M-o" "M-0" "M-1" "M-2" "M-3" "M-4"
                    "M-5" "M-6" "M-7" "M-8" "M-9")
                  ghostel-keymap-exceptions)))

;;; Terminal in a window on the right, e.g. for ssh next to the source.

(defvar-local my/ghostel-side-root nil
  "Project root that this side terminal belongs to, or nil if it isn't one.")
(put 'my/ghostel-side-root 'permanent-local t)

(defun my/ghostel-side--buffer (root)
  "Return the live side terminal that belongs to ROOT, or nil."
  (seq-find (lambda (b) (equal (buffer-local-value 'my/ghostel-side-root b) root))
            (buffer-list)))

(defun my/ghostel-side--window ()
  "Return a window in the selected frame that shows any side terminal."
  (seq-find (lambda (w) (buffer-local-value 'my/ghostel-side-root (window-buffer w)))
            (window-list)))

(defun my/ghostel-side--mark (win)
  "Remember whether WIN was split off for a side terminal."
  (when (window-live-p win)
    (set-window-parameter
     win 'my/ghostel-side-split
     (eq (nth 1 (window-parameter win 'quit-restore)) 'window))))

(defun my/ghostel-side ()
  "Toggle this project's side terminal in a window to the right.
Each project root gets its own `*ghostel:side:NAME*' terminal; buffers
outside any project share the one for \"~/\".  If the terminal is
visible, hide its window (the shell keeps running).  If another
project's side terminal is visible, show this one in its window.
Otherwise show it, creating the terminal on first use."
  (interactive)
  (require 'ghostel)                    ; `ghostel-create' isn't autoloaded
  (let* ((root (or my/ghostel-side-root  ; inside a side terminal: that one
                   (doom-project-root)
                   (expand-file-name "~/")))
         (action '((display-buffer-reuse-window display-buffer-in-direction)
                   (direction . right)
                   (window-width . 0.5)))
         (buf (my/ghostel-side--buffer root))
         (win (and buf (get-buffer-window buf)))
         (other-win (and (not win) (my/ghostel-side--window))))
    (cond
     ;; Delete the window we split off.  `quit-window' alone would not
     ;; after a project swap: its quit-restore check wants the original
     ;; buffer and no previous buffer, so it would show the old terminal.
     ;; A window the terminal reused instead gets its old buffer back.
     (win (if (and (window-parameter win 'my/ghostel-side-split)
                   (not (eq win (frame-root-window win))))
              (delete-window win)
            (quit-window nil win)))
     ;; Another project's terminal is on the right: swap ours into it.
     ((and other-win (buffer-live-p buf))
      (set-window-buffer other-win buf)
      (select-window other-win))
     ((buffer-live-p buf)
      (my/ghostel-side--mark (pop-to-buffer buf action)))
     (t
      ;; From a TRAMP buffer, start the shell locally rather than remotely.
      (let* ((default-directory (if (file-remote-p root)
                                    (expand-file-name "~/")
                                  root))
             (name (format "*ghostel:side:%s*" (doom-project-name root)))
             (new (ghostel-create name (unless other-win action))))
        (with-current-buffer new
          (setq my/ghostel-side-root root))
        (if other-win
            (progn (set-window-buffer other-win new)
                   (select-window other-win))
          (my/ghostel-side--mark (get-buffer-window new))))))))

;; Replaces Doom's "Open ghostel here" (`+ghostel/here'); still on M-x ghostel.
(map! :leader :desc "Terminal on the right" "o T" #'my/ghostel-side)

(use-package! claude-code-ide
  :commands (claude-code-ide claude-code-ide-menu)
  :init
  (setq claude-code-ide-terminal-backend 'ghostel
        claude-code-ide-window-side 'right)
  (map! :leader :desc "Claude Code IDE menu" "o c" #'claude-code-ide-menu)
  :config
  (advice-add 'claude-code-ide--create-terminal-session :around
              #'my/claude-code-ide-with-proxy)
  (claude-code-ide-emacs-tools-setup))

(after! codex-ide-status-mode
  (map! :map codex-ide-status-mode-map
        :nm "RET" #'codex-ide-status-mode-display-session-at-point
        :nm "<return>" #'codex-ide-status-mode-display-session-at-point
        :nm "M-RET" #'codex-ide-status-mode-display-session-at-point-other-window
        :nm "M-<return>" #'codex-ide-status-mode-display-session-at-point-other-window))

(defun my/magit-push-gerrit (branch)
  "Push HEAD to refs/for/BRANCH on origin for review."
  (interactive
   (list (magit-completing-read
          "Target branch"
          (magit-list-remote-branch-names "origin" t)
          nil nil nil nil "dev")))
  (magit-run-git-async
   "push" "origin" (format "HEAD:refs/for/%s" branch)))

(transient-append-suffix 'magit-push "p"
  '("g" "Gerrit review" my/magit-push-gerrit
    :if (lambda ()
          (file-exists-p
           (expand-file-name "hooks/commit-msg" (magit-gitdir))))))

;; (setopt markdown-ts-appear-table-reveal 'table)

