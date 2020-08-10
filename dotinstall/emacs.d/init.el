; someday maybe the following will be useful
(server-start)

(toggle-scroll-bar -1) ; i'm not a big scroll bar fan
(menu-bar-mode -1) ; just turns off the menu bar. use f10 for menu
(tool-bar-mode -1) ; turn off the toolbar. i seldom use this
(electric-pair-mode 1)
(show-paren-mode 1)
(global-display-line-numbers-mode 1)
(column-number-mode 1)
(toggle-truncate-lines 1)
;(add-to-list 'load-path "~/.emacs.d/priv")
;(load-theme 'tango-dark)

(require 'org)
(define-key global-map "\C-cl" 'org-store-link)
(define-key global-map "\C-ca" 'org-agenda)
(setq org-log-done t)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-faces-vector
   [default default default italic underline success warning error])
 '(ansi-color-names-vector
   ["#2e3436" "#a40000" "#4e9a06" "#c4a000" "#204a87" "#5c3566" "#729fcf" "#eeeeec"])
 '(custom-enabled-themes (quote (misterioso))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;(require 'package)
;(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
;(package-initialize)
