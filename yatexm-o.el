;;; -*- Emacs-Lisp -*-
;;; Sample startup file to invoke yatex-mode with outline-minor mode.
;;; (c )1993 by HIROSE Yuuji [yuuji@ae.keio.ac.jp]
;;; Last modified Wed May  4 19:44:53 1994 on 98fa

;;;
;; outline-minor-mode(使用しない場合は不要です)
;;; 
(autoload 'outline-minor-mode "min-out" t)
(make-variable-buffer-local 'outline-prefix-char)
(make-variable-buffer-local 'outline-regexp)
(setq  default-outline-regexp "[*\^l]+")
(make-variable-buffer-local 'outline-level-function)
(setq-default outline-level-function 'outline-level-default)
(defvar LaTeX-outline-regexp
  (concat "[ \t]*" (regexp-quote "\\")
	  "\\(appendix\\|documentstyle\\|part\\|chapter\\|section\\|"
	  "subsection\\|subsubsection\\|paragraph\\|subparagraph\\)"))

;;;
;; yatex-mode
;;;
(setq auto-mode-alist (cons '("\\.tex$" . yatex-mode) auto-mode-alist))
(autoload 'yatex-mode "yatex" "Yet Another LaTeX mode" t)
;;↓min-outを使用しない場合、;;@ の行は不要です。
(defvar yatex-mode-hook
  '(lambda ()
     (setq outline-regexp LaTeX-outline-regexp)			    ;;@
     (outline-minor-mode 1)					    ;;@
     ))
(defvar yatex-mode-load-hook
  '(lambda ()
     (setq-default outline-prefix-char (concat YaTeX-prefix "\C-o"));;@
     (require 'min-out)						    ;;@
     (define-key outline-minor-keymap "\C-?" 'hide-subtree)	    ;;@
     (YaTeX-define-begend-key "ba" "abstract")
     ))
