;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))

(setq doom-font (font-spec :family "YaHei Consolas Hybrid" :size 30)
      doom-symbol-font (font-spec :family "TsangerJinKai03" :size 30))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(setq nerd-icons-font-names '("SymbolsNerdFont-Regular.ttf"))

(setq doom-localleader-key ",")

(setq confirm-kill-emacs nil)
(setq gdb-debuginfod-enable-setting nil)

;; (use-package! lsp-bridge
;;   :config
;;   (setq lsp-bridge-enable-log nil)
;;   (setq acm-candidate-match-function 'orderless-flex)
;;   (setq lsp-bridge-find-def-fallback-function 'citre-jump)
;;   (setq lsp-bridge-find-ref-fallback-function 'citre-jump-to-reference)
;;   (setq lsp-bridge-default-mode-hooks
;;         (remove 'org-mode-hook lsp-bridge-default-mode-hooks))
;;   (setq lsp-bridge-default-mode-hooks
;;         (remove 'emacs-lisp-mode-hook lsp-bridge-default-mode-hooks))
;;   (add-hook! 'lsp-bridge-mode-hook (lambda () (corfu-mode -1)))
;;   (global-lsp-bridge-mode))

;;TODO
;;https://www.skfwe.cn/p/citre-%E5%9C%A8emacs-%E4%B8%AD%E7%9A%84%E4%BD%BF%E7%94%A8/
(use-package! citre
  :config
  (map!
   (:map prog-mode-map
         "M-]" #'citre-jump
         "M-[" #'citre-jump-back)))

(after! doom-modeline
  (setq  doom-modeline-buffer-file-name-style 'file-name)
  )


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
   :preview-key '(:debounce 0.2 any))
  )

(map! :leader
  (:prefix "c" ;code
  :desc "Comment line" "l" #'comment-line
  :desc "Comment/Copy line" "y" #'evilnc-copy-and-comment-lines )
  (:prefix "i" ;insert
           "o" #'symbol-overlay-put
           "q" #'symbol-overlay-remove-all)
  )

(map!
 (:after lsp-bridge
         (:map lsp-bridge-peek-keymap
               "C-h" #'lsp-bridge-peek-tree-previous-node
               "C-j" #'lsp-bridge-peek-file-content-next-line
               "C-k" #'lsp-bridge-peek-file-content-prev-line
               "C-l" #'lsp-bridge-peek-tree-next-node
               "C-n" #'lsp-bridge-peek-list-next-line
               "C-p" #'lsp-bridge-peek-list-prev-line
               "M-n" #'lsp-bridge-peek-tree-next-branch
               "M-p" #'lsp-bridge-peek-tree-previous-branch
               )

         (
          :map lsp-bridge-mode-map
          "C-c C-p" #'lsp-bridge-peek-through
          "C-c C-t" #'lsp-bridge-peek
          )
         )
 ;; (:after minibuffer
         ;; :map minibuffer-local-map
         ;; "C-k" #'kill-line)
 ;; (:after cc-mode
 ;;         (:map c-mode-map
 ;;          :localleader :prefix ("=" "format")
 ;;          :desc "Format all region" "f" #'format-all-region
 ;;          )
 ;;         (:map c-ts-mode-map
 ;;          :localleader :prefix ("=" "format")
 ;;          :desc "Format all region" "f" #'format-all-region
 ;;          )
 ;;         )
 )

;; (evil-define-key 'motion 'lsp-bridge-mode (kbd "C-]") 'lsp-bridge-find-def)
(evil-define-key 'normal 'lsp-bridge-mode (kbd "g d") 'lsp-bridge-find-def)
(evil-define-key 'normal 'lsp-bridge-mode (kbd "C-t") 'lsp-bridge-find-def-return)
(evil-define-key 'normal 'lsp-bridge-mode (kbd "g r") 'lsp-bridge-find-references)
(evil-define-key 'normal 'lsp-bridge-mode (kbd "K") 'lsp-bridge-popup-documentation)
(evil-define-key 'insert 'lsp-bridge-mode (kbd "C-j") 'acm-select-next)
(evil-define-key 'insert 'lsp-bridge-mode (kbd "C-k") 'acm-select-prev)

(defun my-c-mode-font-lock-if0 (limit)
  (save-restriction
    (widen)
    (save-excursion
      (goto-char (point-min))
      (let ((depth 0) str start start-depth)
        (while (re-search-forward "^\\s-*#\\s-*\\(if\\|else\\|endif\\)" limit 'move)
          (setq str (match-string 1))
          (if (string= str "if")
              (progn
                (setq depth (1+ depth))
                (when (and (null start) (looking-at "\\s-+0"))
                  (setq start (match-end 0)
                        start-depth depth)))
            (when (and start (= depth start-depth))
              (c-put-font-lock-face start (match-beginning 0) 'font-lock-comment-face)
              (setq start nil))
            (when (string= str "endif")
              (setq depth (1- depth)))))
        (when (and start (> depth 0))
          (c-put-font-lock-face start (point) 'font-lock-comment-face)))))
  nil)
(defun my-c-mode-common-hook ()
  (font-lock-add-keywords
   nil
   '((my-c-mode-font-lock-if0 (0 font-lock-comment-face prepend))) 'add-to-end))
(add-hook 'c-mode-common-hook 'my-c-mode-common-hook)

(add-hook 'prog-mode-hook #'symbol-overlay-mode)

(use-package! auto-save
  :config
  (auto-save-enable)
  (setq auto-save-slient t)
  )
;; (use-package! super-save
;;   :ensure t
;;   :config
;;   (setq auto-save-default nil)
;;   ;; (setq super-save-idle-duration 1)
;;   ;; (setq super-save-auto-save-when-idle t)
;;   (add-to-list 'super-save-triggers 'evil-normal-state)
;;   (add-to-list 'super-save-triggers 'ace-window)
;;   (setq super-save-silent t)
;;   (setq super-save-all-buffers t)
;;   (setq super-save-delete-trailing-whitespace 'except-current-line)
;;   (super-save-mode +1)
;;   )

(after! evil-escape
  (setq evil-escape-key-sequence "kj")
  ;; Allow to escape from the visual state as from insert.
  (delete 'visual evil-escape-excluded-states)
  (setq-default evil-escape-delay 0.5)
  (setq evil-escape-excluded-major-modes '(dired-mode))
  (setq evil-escape-excluded-major-modes (list 'magit-status-mode 'magit-refs-mode 'magit-log-mode 'magit-revision-mode 'compilation-mode 'magit-stash-mode))
  (evil-escape-mode 1)
  )

(setq smart-compile-alist
      '(("\\.c\\'" . "gcc -g -Wall %f -o %n.bin")
        ("\\.[Cc]+[Pp]*\\'" . "g++ -g -Wall %f  -o %n.bin")
        )
      )

(after! quickrun
  (quickrun-add-command "c/gcc"
    '((:exec . ("%c -x c -Wall -Werror %o -o %e %s"
                "%e %a")))
    :override t))

(add-hook 'emacs-startup-hook
          (lambda ()
            (require 'yasnippet)
            (yas-global-mode 1)

            ;; (require 'lsp-bridge)
            ;; (global-lsp-bridge-mode)

            ;; (unless (display-graphic-p)
            ;;   (with-eval-after-load 'acm
            ;;     (require 'acm-terminal)))
	    ))

;; bury compilation windown
(defun bury-compile-buffer-if-successful (buffer string)
  "Bury a compilation buffer if it succeeded without warnings or errors."
  (when (and (buffer-live-p buffer)
             (string-match-p "compilation" (buffer-name buffer))
             (string-match-p "finished" string)
             (not (with-current-buffer buffer
                    (goto-char (point-min))
                    (or(search-forward "warning" nil t)
                       (search-forward "error" nil t)))))
    (run-with-timer
     1 nil
     (lambda ()
       (let ((compilation-window (get-buffer-window buffer)))
         (when (and compilation-window (window-live-p compilation-window))
           (delete-window compilation-window)))))
    (message "No Compilation Warnings or Errors!")))

(add-hook 'compilation-finish-functions #'bury-compile-buffer-if-successful)


(use-package dired-hide-dotfiles
  :hook (dired-mode . dired-hide-dotfiles-mode)
  :config
  (evil-collection-define-key 'normal 'dired-mode-map
    "H" 'dired-hide-dotfiles-mode))

;; (set-lookup-handlers! 'c-mode :async t
;;     :definition #'lsp-bridge-find-def
;;     ;;:implementations #'lsp-bridge-find-impl
;;     )

 (global-auto-revert-mode 1)


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
                                 "* %^{heading}  %^g\n  %?\n")
                                ))
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
    "My strike-through emphasis for Org.")
  )

(use-package! rime
  :defer t
  :custom
  (rime-user-data-dir (expand-file-name "~/.config/emacs-rime/"))
  (default-input-method "rime")
  (rime-show-candidate 'posframe)
  ;; (setq rime-disable-predicates
  ;;  '(rime-predicate-evil-mode-p
  ;;    rime-predicate-after-alphabet-char-p
  ;;    rime-predicate-prog-in-code-p))
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
      (let (
            (fkey (elt evil-escape-key-sequence 0))
            (skey (elt evil-escape-key-sequence 1))
            )
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
                  (setq unread-command-events (append unread-command-events (list evt))))))
              )
          (apply orig-fun (list key)))))))

(advice-add 'rime-input-method :around #'rime-evil-escape-advice)
  )

;;org
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
  ;; hides the emphasis markers
  ;; (setq org-hide-emphasis-markers t)
  (defun org-roam-node-insert-immediate (arg &rest args)
    (interactive "P")
    (let ((args (cons arg args))
          (org-roam-capture-templates (list (append (car org-roam-capture-templates)
                                                    '(:immediate-finish t)))))
      (apply #'org-roam-node-insert args)))


;; (setq org-roam-mode-sections
;;       '((org-roam-backlinks-section :unique t)
;;         org-roam-reflinks-section))

(setq org-roam-mode-sections
      (list #'org-roam-backlinks-section
            #'org-roam-reflinks-section
            'org-roam-unlinked-references-section
            ))
  )

(defun my/open-org-inbox-file()
  "Open ~/Dropbox/org/inbox.org file"
  (interactive)
  (find-file "~/Dropbox/org/inbox.org"))
(global-set-key (kbd "<f12>") 'my/open-org-inbox-file)

(defun my/open-org-journal-file()
  "Open ~/Dropbox/org/journal/journal-2025.org file"
  (interactive)
  (find-file "~/Dropbox/org/journal/journal-2025.org"))
(global-set-key (kbd "<f9>") 'my/open-org-journal-file)


(after! deft
  (setq deft-recursive t
        deft-directory "~/Dropbox/org/roam/"
        deft-strip-summary-regexp ":PROPERTIES:\n\\(.+\n\\)+:END:\n"
        deft-use-filename-as-title 't
        )
  )

;; (use-package! treesit
;;   :config (setq treesit-font-lock-level 4)
;;   :init
;;   (setq treesit-language-source-alist
;;     '((elisp      . ("https://github.com/Wilfred/tree-sitter-elisp"))
;;       (bash       . ("https://github.com/tree-sitter/tree-sitter-bash"))
;;       (c       . ("https://github.com/tree-sitter/tree-sitter-c"))
;;       (cpp       . ("https://github.com/tree-sitter/tree-sitter-cpp"))
;;       ))
;;   (add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode))
;;   (add-to-list 'auto-mode-alist '("\\.c\\'" . c-ts-mode))
;;   )

;; (use-package! treesit-auto
;;   :demand
;;   :init
;;   (progn
;;     (setq treesit-font-lock-level 4)
;;     (setq c-ts-mode-hook c-mode-common-hook)
;; ;;    (add-to-list 'major-mode-remap-alist '(c-mode . c-ts-mode))
;;     )
;;   :config
;;   (global-treesit-auto-mode)
;;   )

(use-package! expand-region
  :config
  (setq expand-region-contract-fast-key "z")
  ;; Bind in visual mode using map!
  (map! :v "v" #'er/expand-region))


(use-package! clang-format
  :defer t
  ;; :config
  ;; (setq clang-format-style "llvm")
  )

  ;; Keybindings for formatting in C/C++ modes
  (map! :map c-mode-map
        :localleader
        :desc "Format region or buffer" "=r" #'doom/clang-format-region-or-buffer
        :desc "Format function" "=f" #'doom/clang-format-function)
  (map! :map c++-mode-map
        :localleader
        :desc "Format region or buffer" "=r" #'doom/clang-format-region-or-buffer
        :desc "Format function" "=f" #'doom/clang-format-function)

(defun doom/clang-format-function (&optional style)
  "Format the current function with clang-format according to STYLE."
  (interactive)
  (save-excursion
    (c-mark-function)
    (clang-format (region-beginning) (region-end) style)
    (deactivate-mark)
    (message "Formatted function %s" (c-defun-name))))

(defun doom/clang-format-region-or-buffer ()
  "Format the region if active, otherwise format the buffer."
  (interactive)
  (if (use-region-p)
      (clang-format-region (region-beginning) (region-end))
    (clang-format-buffer)))

(add-hook 'after-init-hook #'breadcrumb-mode)
(require 'org-tempo)

(add-hook 'gud-mode-hook
              (lambda ()
                (local-set-key (kbd "q") 'my-gud-mode-exit)))
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

(defun my/asm-comment-tweak ()
  (setq-local comment-start "// "))

(eval-after-load "asm"
  (add-hook 'asm-mode-hook #'my/asm-comment-tweak))

(use-package! ace-window
  :config
  (global-set-key (kbd "M-o") 'ace-window)
  )

(use-package! org-media-note
  :hook (org-mode .  org-media-note-mode)
  :bind (
         ("M-m" . org-media-note-show-interface))  ;; 主功能入口
  :config
  (setq org-media-note-screenshot-image-dir "~/Dropbox/org/roam/org-media-imgs/")  ;; 用于存储视频截图的目录
  (add-to-list 'org-media-note-mpv-online-website-options-alist
               '("\\(youtube\\.com\\|youtu\\.be\\)"
                 "--ytdl-raw-options=proxy=http://127.0.0.1:7788"
                 ))
  (add-to-list 'org-media-note-mpv-online-website-options-alist
               '("\\(bilibili\\.com\\)"
                 "--referrer=https://www.bilibili.com"
                 "--ytdl-raw-options=cookies-from-browser=[chrome]"))
  ;; (add-to-list 'org-media-note-mpv-general-options
  ;;              "--log-file=/tmp/mpv.log")

  )

(use-package! org-roam-ui
    :after org-roam
    :config
    (setq
     org-roam-ui-sync-theme nil
          org-roam-ui-follow t
          org-roam-ui-update-on-save t
          org-roam-ui-open-on-start t))

;; (use-package! go-translate
;;   :config
;;   (map! (:map gt-overlay-render-map
;;               "C-g" #'gt-delete-render-overlays
;;               ))
;;   (setq gt-source-text-transformer
;;         (lambda (c engine )
;;           (string-replace "\n" " " c)))
;;   (setq gt-langs '(en zh))
;;   (setq gt-default-translator
;;         (gt-translator
;;          :taker   (list (gt-taker :pick nil :if 'selection)
;;                         (gt-taker :text 'paragraph :if '(Info-mode help-mode))
;;                         (gt-taker :text 'buffer :pick 'fresh-word :if 'read-only)
;;                         (gt-taker :text 'word))
;;          :engines (list (gt-youdao-dict-engine :if 'word)
;;                         (gt-bing-engine :if 'no-word))
;;          :render  (list (gt-overlay-render :if 'selection)
;;                         (gt-overlay-render :if 'read-only)
;;                         (gt-insert-render :if (lambda (translator) (member (buffer-name) '("COMMIT_EDITMSG"))))
;;                         ;; (gt-alert-render :if '(and xxx-mode (or not-selection (and read-only parts))))
;;                         (gt-buffer-render :if 'word))))
;;   )

(use-package! dape
  :config
  ;; (setq dape-buffer-window-arrangement 'right)
(add-hook 'dape-display-source-hook 'pulse-momentary-highlight-one-line)
  )

(use-package! leetcode
  :config
(setq leetcode-prefer-language "c")
  )

(use-package! eglot
  :config
  (map! :map eglot-mode-map
         :n "gr"  #'xref-find-references)
  (add-to-list 'eglot-server-programs
               '((c-mode c-ts-mode c++-mode c++-ts-mode) .
                 ("clangd"
                  "--clang-tidy"
                  "--all-scopes-completion"
                  "--header-insertion=never"
                  "--header-insertion-decorators=0"))))
