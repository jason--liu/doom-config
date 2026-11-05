;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;; To install a package with Doom you must declare them here and run 'doom sync'
;; on the command line, then restart Emacs for the changes to take effect -- or
;; use 'M-x doom/reload'.


;; To install SOME-PACKAGE from MELPA, ELPA or emacsmirror:
(package! evil-escape)
(package! symbol-overlay)
(package! posframe)
(package! smart-compile)
(package! dired-hide-dotfiles)
(package! org-download)
(package! citre)
(package! clang-format)
(package! super-save)
(package! breadcrumb)
(package! egerrit
  :recipe (:type git :repo "https://git.sr.ht/~niklaseklund/egerrit"
           :local-repo "/home/qliu/work/tools/egerrit"))
(package! auto-save :recipe (:host github :repo "manateelazycat/auto-save"))
(package! doom-snippets :disable t)
(package! org-appear)
(package! markdown-ts-appear
  :recipe (:host github :repo "Thysrael/markdown-ts-appear"))
(package! org-media-note :recipe (:host github :repo "yuchen-lea/org-media-note"))
(package! leetcode)
(package! gt :recipe (:host github :repo "lorniu/gt.el"))
(package! eglot-inactive-regions :recipe (:host github :repo "fargiolas/eglot-inactive-regions"))
;; (package! treesit-auto)


(package! rime :recipe (:host github :repo "DogLooksGood/emacs-rime" :files ("*.el" "Makefile" "lib.c")))
(package! codex-ide
  :recipe (:host github :repo "dgillis/emacs-codex-ide"
           :files (:defaults "bin")))
(package! claude-code-ide
  :recipe (:host github :repo "manzaltu/claude-code-ide.el"))
;; skeeto/emacs-web-server (simple-httpd) shares this repo name; keep a
;; distinct clone so straight never builds web-server from simple-httpd.
(package! web-server
  :recipe (:host github :repo "eschulte/emacs-web-server"
           :local-repo "eschulte-emacs-web-server"))
;; Override :term ghostel's older pin with v0.60.0.  The native module in
;; .local/etc/ghostel/ must be the same release (see ghostel-module.version).
;; Both packages come from one repo, so keep the pins identical.
(package! ghostel :pin "2c13feaa31da8a55a0471210cd26414d7265ee1e")
(package! evil-ghostel :pin "2c13feaa31da8a55a0471210cd26414d7265ee1e")


;; To install a package directly from a remote git repo, you must specify a
;; `:recipe'. You'll find documentation on what `:recipe' accepts here:
;; https://github.com/radian-software/straight.el#the-recipe-format
;; (package! another-package
;;   :recipe (:host github :repo "username/repo"))

;; If the package you are trying to install does not contain a PACKAGENAME.el
;; file, or is located in a subdirectory of the repo, you'll need to specify
;; `:files' in the `:recipe':
;; (package! this-package
;;   :recipe (:host github :repo "username/repo"
;;            :files ("some-file.el" "src/lisp/*.el")))

;; If you'd like to disable a package included with Doom, you can do so here
;; with the `:disable' property:
;; (package! builtin-package :disable t)

;; You can override the recipe of a built in package without having to specify
;; all the properties for `:recipe'. These will inherit the rest of its recipe
;; from Doom or MELPA/ELPA/Emacsmirror:
;; (package! builtin-package :recipe (:nonrecursive t))
;; (package! builtin-package-2 :recipe (:repo "myfork/package"))

;; Specify a `:branch' to install a package from a particular branch or tag.
;; This is required for some packages whose default branch isn't 'master' (which
;; our package manager can't deal with; see radian-software/straight.el#279)
;; (package! builtin-package :recipe (:branch "develop"))

;; Use `:pin' to specify a particular commit to install.
;; (package! builtin-package :pin "1a2b3c4d5e")


;; Doom's packages are pinned to a specific commit and updated from release to
;; release. The `unpin!' macro allows you to unpin single packages...
;; (unpin! pinned-package)
;; ...or multiple packages
;; (unpin! pinned-package another-pinned-package)
;; ...Or *all* packages (NOT RECOMMENDED; will likely break things)
;; (unpin! t)
;; (when (package! lsp-bridge
;;         :recipe (:host github
;;                  :repo "manateelazycat/lsp-bridge"
;;                  :branch "master"
;;                  :files ("*.el" "*.py" "acm" "core" "langserver" "multiserver" "resources")
;;                  ;; do not perform byte compilation or native compilation for lsp-bridge
;;                  :build (:not compile)))
;;   (package! markdown-mode)
;;   (package! yasnippet))

;;   (straight-use-package
;;  '(popon :type git :repo "https://codeberg.org/akib/emacs-popon.git"))


;; (unless (display-graphic-p)
;;   (package! popon
;;     :recipe (:host nil :repo "https://codeberg.org/akib/emacs-popon.git"))
;;   (package! acm-terminal
;;     :recipe (:host github :repo "twlz0ne/acm-terminal")))
