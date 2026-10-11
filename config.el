;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Private Doom configuration. Changes to this file do not require doom sync.

;;; Appearance and core settings

(setq doom-font (font-spec :family "YaHei Consolas Hybrid" :size 30)
      doom-symbol-font (font-spec :family "TsangerJinKai03" :size 30))

(setq doom-theme 'doom-one)

(setq doom-themes-enable-italic nil)

(setq display-line-numbers-type t)

(setq nerd-icons-font-names '("SymbolsNerdFont-Regular.ttf"))

(setq doom-localleader-key ",")

(setq confirm-kill-emacs nil)

(after! doom-modeline
  (setq doom-modeline-buffer-file-name-style 'relative-to-project))


;;; Editing, navigation, and files

(use-package! consult
  :config
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
          :documentSymbolProvider
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

(use-package! org-roam-ui
  :after org-roam
  :config
  (setq org-roam-ui-sync-theme nil
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))


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

(add-hook 'vterm-mode-hook
          (lambda ()
            (add-hook 'window-selection-change-functions
                      (lambda (win)
                        (when (eq (window-buffer win) (current-buffer))
                          (evil-insert-state)))
                      nil t)))

(use-package! codex
  :demand t
  :init
  (setq codex-terminal-backend 'vterm)
  :config
  (global-set-key (kbd "C-c x") codex-command-map))
