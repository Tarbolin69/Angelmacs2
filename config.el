(defvar elpaca-installer-version 0.5)
  (defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
  (defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
  (defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
  (defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                                :ref nil
                                :files (:defaults (:exclude "extensions"))
                                :build (:not elpaca--activate-package)))
  (let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
         (build (expand-file-name "elpaca/" elpaca-builds-directory))
         (order (cdr elpaca-order))
         (default-directory repo))
    (add-to-list 'load-path (if (file-exists-p build) build repo))
    (unless (file-exists-p repo)
      (make-directory repo t)
      (when (< emacs-major-version 28) (require 'subr-x))
      (condition-case-unless-debug err
          (if-let ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                   ((zerop (call-process "git" nil buffer t "clone"
                                         (plist-get order :repo) repo)))
                   ((zerop (call-process "git" nil buffer t "checkout"
                                         (or (plist-get order :ref) "--"))))
                   (emacs (concat invocation-directory invocation-name))
                   ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                         "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                   ((require 'elpaca))
                   ((elpaca-generate-autoloads "elpaca" repo)))
              (progn (message "%s" (buffer-string)) (kill-buffer buffer))
            (error "%s" (with-current-buffer buffer (buffer-string))))
        ((error) (warn "%s" err) (delete-directory repo 'recursive))))
    (unless (require 'elpaca-autoloads nil t)
      (require 'elpaca)
      (elpaca-generate-autoloads "elpaca" repo)
      (load "./elpaca-autoloads")))
  (add-hook 'after-init-hook #'elpaca-process-queues)
  (elpaca `(,@elpaca-order))

  ;; Install use-package support
(elpaca elpaca-use-package
  (elpaca-use-package-mode)
  (setq elpaca-use-package-by-default t))

(elpaca-wait)

(use-package evil
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-vsplit-window-right t)
  (setq evil-split-window-below t)
  (setq evil-undo-system 'undo-tree)
  (evil-mode))
(use-package evil-collection
  :after evil
  :config
  (setq evil-collection-mode-list '(dashboard dired ibuffer))
  (evil-collection-init))
(use-package evil-tutor)

(use-package general
  :config
  (general-evil-setup)

  (general-define-key ;; Just a better way to escape stuff
    "<escape>" 'keyboard-escape-quit)  

  (general-create-definer angl/leader-keys
     :states '(normal insert visual emacs)
     :keymaps 'override
     :prefix "SPC"
     :global-prefix "M-SPC")

  (angl/leader-keys
    "f" '(:ignore t :wk "Files")
    "ff" '(find-file :wk "Find files")
    "fr" '(consult-recent-file :wk "Find recent files")
    "fc" '((lambda () (interactive) (find-file "~/.config/emacs/config.org")) :wk "Emacs config file")
    "TAB TAB" '(comment-line :wk "Comment lines"))

  (angl/leader-keys
    "h" '(:ignore t :wk "Help/Embark")
    "hf" '(describe-function :wk "Describe function")
    "hv" '(describe-variable :wk "Describe variable")
    "ha" '(embark-act :wk "Embark act")
    "hd" '(embark-dwim :wk "Embark current target")
    "hb" '(embark-bindings :wk "Embark bindings"))

  (angl/leader-keys
    "d" '(:ignore t :wk "Dired")
    "dd" '(dired :wk "Open dired")
    "dj" '(dired-jump :wk "Dired jump to current")
    "dn" '(neotree-dir :wk "Open directory in neotree")
    "dp" '(peep-dired :wk "Peep-dired"))

  (angl/leader-keys
    "m" '(:ignore t :wk "Org")
    "mc" '(org-cliplink :wk "Org cliplink")
    "ma" '(org-agenda :wk "Org agenda")
    "me" '(org-export-dispatch :wk "Org export dispatch")
    "mi" '(org-toggle-item :wk "Org toggle item")
    "mt" '(org-todo :wk "Org todo")
    "mB" '(org-babel-tangle :wk "Org babel tangle")
    "mT" '(org-todo-list :wk "Org todo list"))

  (general-define-key ;;ROAM
   :prefix "C-c"
   "n" '(:ignore t :wk "Org Roam")
   "nb" '(org-roam-buffer-toggle :wk "Roam buffer toggle")
   "nf" '(org-roam-node-find :wk "Roam find node")
   "ni" '(org-roam-node-insert :wk "Roam insert node"))

  (angl/leader-keys
    "mb" '(:ignore t :wk "Tables")
    "mb-" '(org-table-insert-hline :wk "Insert hline in table"))

  (angl/leader-keys
    "md" '(:ignore t :wk "Date/Deadline")
    "mdt" '(org-time-stamp :wk "Org time stamp"))

  (angl/leader-keys
    "b" '(:ignore t :wk "Buffers")
    "bb" '(switch-to-buffer :wk "Switch buffer")
    "bi" '(ibuffer :wk "Ibuffer")
    "bk" '(kill-this-buffer :wk "Kill this buffer")
    "bn" '(next-buffer :wk "Next buffer")
    "bp" '(previous-buffer :wk "Previous buffer")
    "br" '(revert-buffer :wk "Reload buffer"))

  (angl/leader-keys
    "t" '(:ignore t :wk "Toggle")
    "tt" '(visual-line-mode :wk "Toggle truncated lines")
    "tn" '(neotree-toggle :wk "Toggle neotree")
    "tv" '(vterm-toggle :wk "Toggle vterm"))

  (angl/leader-keys
    "w" '(:ignore t :wk "Windows")
    ;; Window splits
    "wc" '(evil-window-delete :wk "Close window")
    "wn" '(evil-window-new :wk "New window")
    "ws" '(evil-window-split :wk "Horizontal split window")
    "wv" '(evil-window-vsplit :wk "Vertical split window")
    ;; Window motions
    "wh" '(evil-window-left :wk "Window left")
    "wj" '(evil-window-down :wk "Window down")
    "wk" '(evil-window-up :wk "Window up")
    "wl" '(evil-window-right :wk "Window right")
    "ww" '(evil-window-next :wk "Goto next window")
    ;;Move windows
    "wH" '(buf-move-left :wk "Buffer move left")
    "wJ" '(buf-move-left :wk "Buffer move down")
    "wK" '(buf-move-left :wk "Buffer move up")
    "wL" '(buf-move-left :wk "Buffer move right"))

  (angl/leader-keys
    "p" '(:ignore t :wk "Projects")
    "pm" '(magit :wk "Open Magit"))

  (angl/leader-keys
    "e" '(:ignore t :wk "Evaluate")
    "eb" '(eval-buffer :wk "Evaluate elips in buffer")
    "ed" '(eval-defun :wk "Evaluate defun in or after point")
    "ee" '(eval-expression :wk "Evaluate elisp expression")
    "el" '(eval-lasp-sexp :wk "Evaluate elips before point")
    "er" '(eval-region :wk "Evaluate elisp in region"))
)

(use-package which-key
  :init
  (which-key-mode 1)
  :config
  (setq which-key-side-window-location 'bottom
        which-key-sort-order #'which-key-key-order-alpha
        which-key-sort-uppercase-first nil
        which-key-add-column-padding 1
        which-key-max-display-columns nil
        which-key-min-display-lines 6
        which-key-side-window-slot -10
        which-key-side-window-max-height 0.25
        which-key-idle-delay 0.8
        which-key-max-description-lenght 25
        which-key-allow-imprecise-window-fit nil
        which-key-separator " → " ))

(use-package sudo-edit
  :config
    (angl/leader-keys
      "fu" '(sudo-edit-find-file :wk "Sudo find file")
      "fU" '(sudo-edit :wk "Sudo edit file")))

(setq make-backup-files nil)
(setq auto-save-default nil)
(setq create-lockfiles nil)

(defalias 'yes-or-no-p 'y-or-n-p)

(use-package doom-themes
  :ensure t
  :config
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
  (doom-themes-org-config))

(add-to-list 'custom-theme-load-path "~/.config/emacs/themes/")
(load-theme 'operandas t)

(add-to-list 'default-frame-alist '(alpha-background . 90))
;; ADD THIS WHEN YOU UPDATE TO EMACS 29

(use-package dashboard
  :ensure t
  :init
  (setq initial-buffer-choice 'dashboard-open)
  (setq dashboard-set-heading-icons t)
  (setq dashboard-set-file-icons t)
  (setq dashboard-banner-logo-title "A man's Emacs is his tempel...")
  ;(setq dashboard-startup-banner "~/.config/emacs/images/KEC_Dark_BK.png")
  (setq dashboard-startup-banner "~/.config/emacs/images/angelmacs-banner.txt")
  (setq dashboard-center-content t)
  (setq dashboard-items '((recents . 3)
                          (projects . 3)))
  :config
  (dashboard-setup-startup-hook))

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(global-display-line-numbers-mode 1)
(global-visual-line-mode 1)
(setq display-line-numbers-type 'relative)

(dolist (mode '(org-mode-hook
                term-mode-hook
                shell-mode-hook
                vterm-mode-hook
                pdf-view-mode-hook
                markdown-mode-hook
                neotree-mode-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(set-face-attribute 'default nil
  :font "Iosevka"
  :height 110
  :weight 'medium)
(set-face-attribute 'variable-pitch nil
  :font "Iosevka Comfy Duo"
  :height 120
  :weight 'medium)
(set-face-attribute 'fixed-pitch nil
  :font "Iosevka"
  :height 110
  :weight 'medium)

(set-face-attribute 'font-lock-comment-face nil
  :slant 'italic)
(set-face-attribute 'font-lock-keyword-face nil
  :slant 'italic)

(add-to-list 'default-frame-alist '(font . "Iosevka 11"))

(setq-default line-spacing 0.12)

(use-package ligature
  :load-path "path-to-ligature-repo"
  :config
  (ligature-set-ligatures 'prog-mode '("<---" "<--"  "<<-" "<-" "->" "-->" "--->" "<->" "<-->" "<--->" "<---->" "<!--"
                                       "<==" "<===" "<=" "=>" "=>>" "==>" "===>" ">=" "<=>" "<==>" "<===>" "<====>" "<!---"
                                       "<~~" "<~" "~>" "~~>" "::" ":::" "==" "!=" "===" "!=="
                                       ":=" ":-" ":+" "<*" "<*>" "*>" "<|" "<|>" "|>" "+:" "-:" "=:" "<******>" "++" "+++"))
  (global-ligature-mode t))

(use-package flyspell-correct
  :after flyspell)

(use-package flyspell-correct-ivy
  :after flyspell-correct)

(dolist (hook '(text-mode-hook))
  (add-hook hook (lambda () (flyspell-mode 1))))
(setq ispell-program-name "hunspell")
(setq ispell-dictionary "es_AR")

(require 'windmove)

;;;###autoload
(defun buf-move-up ()
  "Swap the current buffer and the buffer above the split.
If there is no split, ie now window above the current one, an
error is signaled."
;;  "Switches between the current buffer, and the buffer above the
;;  split, if possible."
  (interactive)
  (let* ((other-win (windmove-find-other-window 'up))
         (buf-this-buf (window-buffer (selected-window))))
    (if (null other-win)
        (error "No window above this one")
      ;; swap top with this one
      (set-window-buffer (selected-window) (window-buffer other-win))
      ;; move this one to top
      (set-window-buffer other-win buf-this-buf)
      (select-window other-win))))

;;;###autoload
(defun buf-move-down ()
"Swap the current buffer and the buffer under the split.
If there is no split, ie now window under the current one, an
error is signaled."
  (interactive)
  (let* ((other-win (windmove-find-other-window 'down))
         (buf-this-buf (window-buffer (selected-window))))
    (if (or (null other-win) 
            (string-match "^ \\*Minibuf" (buffer-name (window-buffer other-win))))
        (error "No window under this one")
      ;; swap top with this one
      (set-window-buffer (selected-window) (window-buffer other-win))
      ;; move this one to top
      (set-window-buffer other-win buf-this-buf)
      (select-window other-win))))

;;;###autoload
(defun buf-move-left ()
"Swap the current buffer and the buffer on the left of the split.
If there is no split, ie now window on the left of the current
one, an error is signaled."
  (interactive)
  (let* ((other-win (windmove-find-other-window 'left))
         (buf-this-buf (window-buffer (selected-window))))
    (if (null other-win)
        (error "No left split")
      ;; swap top with this one
      (set-window-buffer (selected-window) (window-buffer other-win))
      ;; move this one to top
      (set-window-buffer other-win buf-this-buf)
      (select-window other-win))))

;;;###autoload
(defun buf-move-right ()
"Swap the current buffer and the buffer on the right of the split.
If there is no split, ie now window on the right of the current
one, an error is signaled."
  (interactive)
  (let* ((other-win (windmove-find-other-window 'right))
         (buf-this-buf (window-buffer (selected-window))))
    (if (null other-win)
        (error "No right split")
      ;; swap top with this one
      (set-window-buffer (selected-window) (window-buffer other-win))
      ;; move this one to top
      (set-window-buffer other-win buf-this-buf)
      (select-window other-win))))

(use-package all-the-icons
  :ensure t
  :if (display-graphic-p))

(use-package all-the-icons-dired
  :hook (dired-mode . (lambda () (all-the-icons-dired-mode t))))

(use-package all-the-icons-completion
  :after (marginalia all-the-icons)
  :hook (marginalia-mode . all-the-icons-completion-marginalia-setup)
  :init
  (all-the-icons-completion-mode))

(use-package mood-line
  :init
  (mood-line-mode))

(use-package rainbow-mode
  :hook org-mode prog-mode)

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package highlight-indent-guides
  :custom
  (highlight-indent-guides-delay 0)
  (highlight-indent-guides-responsive t)
  (highlight-indent-guides-method 'character)
  ;; (highlight-indent-guides-auto-enabled t)
  ;; (highlight-indent-guides-character ?\┆)
  (highlight-indent-guides-auto-enabled nil)
  :commands highlight-indent-guides-mode
  :hook (prog-mode  . highlight-indent-guides-mode))

(elpaca (screenshot :host github :repo "tecosaur/screenshot"))

(use-package pdf-tools
  :ensure t
  :config
  (pdf-tools-install)
  (setq-default pdf-view-display-size 'fit-page))

(setq org-hide-emphasis-markers t
      org-pretty-entities t
      org-ellipsis "…"
      org-auto-align-tags nil
      org-tags-column 0
      org-insert-heading-respect-content t)

(use-package toc-org
  :commands toc-org-enable
  :init (add-hook 'org-mode-hook 'toc-org-enable))

(elpaca (org-cliplink :host github :repo "rexim/org-cliplink"))

(use-package org-superstar)
(setq org-superstar-configure-like-org-bullets t)
(add-hook 'org-mode-hook (lambda () (org-superstar-mode 1)))
(setq org-superstar-headline-bullets-list '("✢" "✿" "❁" "✾" "❀" "✤" "❖"))
(setq org-superstar-special-todo-items t)
(setq org-hide-leading-stars nil)
(setq org-superstar-leading-bullet ?\s)
(setq org-indent-mode-turns-on-hiding-stars nil)
(add-hook 'org-mode-hook 'org-indent-mode)

(use-package org-fancy-priorities
  :ensure t
  :hook
  (org-mode . org-fancy-priorities-mode)
  :config
  (setq org-fancy-priorities-list '("⚠" "‼" "❗")))

(setq org-edit-src-content-indentation 0)

(require 'org-tempo)
(add-to-list 'org-structure-template-alist '("sh" . "src shell"))
(add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
(add-to-list 'org-structure-template-alist '("py" . "src python"))
(add-to-list 'org-structure-template-alist '("s" . "src"))

(add-to-list 'org-link-frame-setup '(file . find-file))
(use-package org-roam
  :ensure t
  :custom
  (org-roam-directory "~/Documents/RoamNotes")
  :config
  (org-roam-setup))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defualts nil)
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package vertico
  :ensure t
  :bind (:map vertico-map
         ("C-j" . vertico-next)
         ("C-k" . vertico-previous)
         ("C-f" . vertico-exit)
         :map minibuffer-local-map
         ("M-h" . backward-kill-word))
  :custom
  (vertico-cycle t)
  :init
  (vertico-mode))

(use-package savehist
  :elpaca nil
  :config
  (setq history-lenght 25)
  :init
  (savehist-mode))

(recentf-mode 1)
(setq recentf-max-menu-items 25)
(setq recentf-max-saved-items 25) 

(use-package marginalia
  :after vertico
  :ensure t
  :custom
  (marginalia-annotators '(marginalia-annotators-heavy marginalia-annotators-light nil))
  (marginalia-max-relative-age 0)
  (marginalia-align 'right)
  :init
  (marginalia-mode))

(use-package consult
  :ensure t
  :bind (("C-s" . consult-line)
         ("C-M-l" . consult-imenu)
         ("C-M-j" . consult-buffer)
         ("C-c M-x" . consult-mode-command)
         ("C-c h" . consult-history)
         ("C-c k" . consult-kmacro)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
         ([remap Info-search] . consult-info)
         ;; C-x bindings in `ctl-x-map'
         ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
         ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
         ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
         ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
         ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
         ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
         ;; Custom M-# bindings for fast register access
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
         ("C-M-#" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)                ;; orig. yank-pop
         ;; M-g bindings in `goto-map'
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flymake)               ;; Alternative: consult-flycheck
         ("M-g g" . consult-goto-line)             ;; orig. goto-line
         ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
         ("M-g o" . consult-outline)               ;; Alternative: consult-org-heading
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings in `search-map'
         ("M-s d" . consult-find)
         ("M-s D" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ;; Isearch integration
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
         ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
         ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
         ("M-s L" . consult-line-multi)            ;; needed by consult-line to detect isearch
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history)                 ;; orig. next-matching-history-element
         ("M-r" . consult-history)))

;; UNTIL I CAN FIX THE INCORRECT WINDOW SPLITS
(use-package embark
  :ensure t
  :init
  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)
  (add-hook 'eldoc-documentation-functions #'embark-eldoc-first-target)
  :config
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))


(use-package embark-consult
  :ensure t ; only need to install it, embark loads it after consult if found
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(defun embark-which-key-indicator ()
  "An embark indicator that displays keymaps using which-key.
The which-key help message will show the type and value of the
current target followed by an ellipsis if there are further
targets."
  (lambda (&optional keymap targets prefix)
    (if (null keymap)
        (which-key--hide-popup-ignore-command)
      (which-key--show-keymap
       (if (eq (plist-get (car targets) :type) 'embark-become)
           "Become"
         (format "Act on %s '%s'%s"
                 (plist-get (car targets) :type)
                 (embark--truncate-target (plist-get (car targets) :target))
                 (if (cdr targets) "…" "")))
       (if prefix
           (pcase (lookup-key keymap prefix 'accept-default)
             ((and (pred keymapp) km) km)
             (_ (key-binding prefix 'accept-default)))
         keymap)
       nil nil t (lambda (binding)
                   (not (string-suffix-p "-argument" (cdr binding))))))))

(setq embark-indicators
  '(embark-which-key-indicator
    embark-highlight-indicator
    embark-isearch-highlight-indicator))

(defun embark-hide-which-key-indicator (fn &rest args)
  "Hide the which-key indicator immediately when using the completing-read prompter."
  (which-key--hide-popup-ignore-command)
  (let ((embark-indicators
         (remq #'embark-which-key-indicator embark-indicators)))
      (apply fn args)))

(advice-add #'embark-completing-read-prompter
            :around #'embark-hide-which-key-indicator)

(use-package corfu
  ;; Optional customizations
  :custom
  (corfu-cycle t)                 ; Allows cycling through candidates
  (corfu-auto t)                  ; Enable auto completion
  (corfu-auto-prefix 2)
  (corfu-auto-delay 0.0)
  (corfu-popupinfo-delay '(0.5 . 0.2))
  (corfu-preview-current 'insert) ; Do not preview current candidate
  (corfu-preselect 'prompt)
  (corfu-on-exact-match nil)      ; Don't auto expand tempel snippets

  ;; Optionally use TAB for cycling, default is `corfu-complete'.
  :bind (:map corfu-map
              ("M-SPC"      . corfu-insert-separator)
              ("TAB"        . corfu-next)
              ([tab]        . corfu-next)
              ("S-TAB"      . corfu-previous)
              ([backtab]    . corfu-previous)
              ("S-<return>" . corfu-insert)
              ("RET"        . nil))

  :init
  (global-corfu-mode)
  (corfu-history-mode)
  (corfu-popupinfo-mode)
  :config
  (add-hook 'eshell-mode-hook
            (lambda () (setq-local corfu-quit-at-boundary t
                              corfu-quit-no-match t
                              corfu-auto nil)
              (corfu-mode))))

(use-package kind-icon
  :ensure t
  :after corfu
  :custom
  (kind-icon-default-face 'corfu-default) ; to compute blended backgrounds correctly
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

(use-package eshell-syntax-highlighting
  :after esh-mode
  :config
  (eshell-syntax-highlighting-global-mode +1))

(setq eshell-rc-script (concat user-emacs-directory "eshell/profile")
      eshell-history-size 5000
      eshell-buffer-maximum-lines 5000
      eshell-hist-ignoredups t
      eshell-scroll-to-bottom-on-input t
      eshell-destroy-buffer-when-process-dies t
      eshell-visual-commands'("bash" "zsh" "htop" "ssh" "top" "fish"))

(use-package vterm
  :commands vterm
  :config
  (setq term-prompt-regexp "%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b")
  (setq vterm-shell "zsh")
  (setq vterm-max-scrollback 10000))

(use-package vterm-toggle
  :after vterm
  :config
  (setq vterm-toggle-fullscreen-p nil)
  (setq vterm-toggle-scope 'project)
  (add-to-list 'display-buffer-alist
               '((lambda (buffer-or-name _)
                     (let ((buffer (get-buffer buffer-or-name)))
                       (with-current-buffer buffer
                         (or (equal major-mode 'vterm-mode)
                             (string-prefix-p vterm-buffer-name (buffer-name buffer))))))
                  (display-buffer-reuse-window display-buffer-at-bottom)
                  ;;(display-buffer-reuse-window display-buffer-in-direction)
                  ;;display-buffer-in-direction/direction/dedicated is added in emacs27
                  ;;(direction . bottom)
                  ;;(dedicated . t) ;dedicated is supported in emacs27
                  (reusable-frames . visible)
                  (window-height . 0.3))))

(use-package projectile
  :config
  (projectile-mode 1))

(use-package magit)

(use-package undo-tree
  :bind ("C-x u" . undo-tree-visualize)
  :init (global-undo-tree-mode))
(setq undo-tree-history-directory-alist '(("." . "~/.config/emacs/undo")))

(use-package dired-open
  :config
  (setq dired-open-extensions '(("gif" . "sxiv")
				    ("jpg" . "sxiv")
				    ("png" . "sxiv")
				    ("mkv" . "mpv")
				    ("mp4" . "mpv"))))
(use-package peep-dired
  :after dired
  :hook (evil-normalize-keymaps . peep-dired-hook)
  :config 
    (general-define-key
      :states 'normal
      :keymaps dired-mode-map
      "h" 'dired-up-directory
      "l" 'dired-open-file)
    (general-define-key
      :states 'normal
      :keymaps peep-dired-mode-map
      "j" 'peep-dired-next-file
      "k" 'peep-dired-prev-file))

(use-package neotree
  :config
  (setq neo-smart-open t
        neo-show-hidden-files t
        neo-window-width 35
        neo-window-fixed-size nil
        inhibit-compacting-font-caches t
        projectile-switch-project-action 'neotree-projectile-action) 
        ;; truncate long file names in neotree
        (add-hook 'neo-after-create-hook
           #'(lambda (_)
               (with-current-buffer (get-buffer neo-buffer-name)
                 (setq truncate-lines t)
                 (setq word-wrap nil)
                 (make-local-variable 'auto-hscroll-mode)
                 (setq auto-hscroll-mode nil)))))

(use-package flycheck
  :ensure t
  :defer t
  :diminish 
  :init (global-flycheck-mode))

(use-package apheleia
  :init
  (apheleia-global-mode +1))

;; Configure Tempel
(use-package tempel
  ;; Require trigger prefix before template name when completing.
  ;; :custom
  ;; (tempel-trigger-prefix "<")
  :bind (("M-+" . tempel-complete) ;; Alternative tempel-expand
         ("M-*" . tempel-insert))
  :init
  (defun tempel-setup-capf ()
    ;; Add the Tempel Capf to `completion-at-point-functions'.
    ;; `tempel-expand' only triggers on exact matches. Alternatively use
    ;; `tempel-complete' if you want to see all matches, but then you
    ;; should also configure `tempel-trigger-prefix', such that Tempel
    ;; does not trigger too often when you don't expect it. NOTE: We add
    ;; `tempel-expand' *before* the main programming mode Capf, such
    ;; that it will be tried first.
    (setq-local completion-at-point-functions
                (cons #'tempel-expand
                      completion-at-point-functions)))
  (add-hook 'conf-mode-hook 'tempel-setup-capf)
  (add-hook 'prog-mode-hook 'tempel-setup-capf)
  (add-hook 'text-mode-hook 'tempel-setup-capf)
  ;; Optionally make the Tempel templates available to Abbrev,
  ;; either locally or globally. `expand-abbrev' is bound to C-x '.
  ;; (add-hook 'prog-mode-hook #'tempel-abbrev-mode)
  ;; (global-tempel-abbrev-mode)
)

(use-package tempel-collection)

(use-package yasnippet
  :ensure t
  :bind
  ("C-c y s" . yas-insert-snippet)
  ("C-c y v" . yas-visit-snippet-file)
  :config
  (add-to-list 'yas-snippet-dirs "~/.config/emacs/snippets")
  (yas-global-mode 1))

(use-package eglot
  :ensure t
  :hook 
  (python-ts-mode . eglot-ensure)
  (rust-ts-mode . eglot-ensure))

(setq read-process-output-max (* 3 1024 1024)) ;; 1mb
(setq gc-cons-threshold 100000000)

(use-package treesit-auto
  :demand t
  :config
  (global-treesit-auto-mode))

(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-ts-mode)
                              '("\\.py\\'" . python-ts-mode))
