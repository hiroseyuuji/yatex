;;; -*- Emacs-Lisp -*-
;;; YaTeX add-in functions.
;;; yatexadd.el rev.14
;;; (c )1991-2000 by HIROSE Yuuji.[yuuji@yatex.org]
;;; Last modified Sat Sep 29 23:17:06 2001 on duke
;;; $Id$

;;;
;;Sample functions for LaTeX environment.
;;;
(defvar YaTeX:tabular-default-rule
  "@{\\vrule width 1pt\\ }c|c|c@{\\ \\vrule width 1pt}"
  "*Your favorite default rule format.")

(defvar YaTeX:tabular-thick-vrule "\\vrule width %s"
  "*Vertical thick line format (without @{}). %s'll be replaced by its width.")

(defvar YaTeX:tabular-thick-hrule "\\noalign{\\hrule height %s}"
  "*Horizontal thick line format.  %s will be replaced by its width.")

(defun YaTeX:tabular ()
  "YaTeX add-in function for tabular environment.
Notice that this function refers the let-variable `env' in
YaTeX-make-begin-end."
  (let ((width "") bars (rule "") (and "") (j 1) loc ans (hline "\\hline"))
    (if (string= YaTeX-env-name "tabular*")
	(setq width (concat "{" (read-string "Width: ") "}")))
    (setq loc (YaTeX:read-position "tb")
	  bars (string-to-int
		(read-string "Number of columns(0 for default format): " "3")))
    (if (<= bars 0)
	(setq				;if 0, simple format
	 rule YaTeX:tabular-default-rule
	 and "& &")
      (while (< j bars)			;repeat bars-1 times
	(setq rule (concat rule "c|")
	      and (concat and "& ")
	      j (1+ j)))
      (setq rule (concat rule "c"))
      (message "(N)ormal-frame or (T)hick frame? [nt]")
      (setq ans (read-char))
      (cond
       ((or (equal ans ?t) (equal ans ?T))
	(setq ans (read-string "Rule width: " "1pt")
	      rule (concat
		    "@{" (format YaTeX:tabular-thick-vrule ans) "}"
		    rule
		    "@{\\ " (format YaTeX:tabular-thick-vrule ans) "}")
	      hline (format YaTeX:tabular-thick-hrule ans)))
       (t (setq rule (concat "|" rule "|")
		hline "\\hline"))))

    (setq rule (read-string "rule format: " rule))
    (setq YaTeX-single-command "hline")

    (format "%s%s{%s}" width loc rule)))

(fset 'YaTeX:tabular* 'YaTeX:tabular)
(defun YaTeX:array ()
  (concat (YaTeX:read-position "tb")
	  "{" (read-string "Column format: ") "}"))

(defun YaTeX:read-oneof (oneof)
  (let ((pos "") loc (guide ""))
    (and (boundp 'name) name (setq guide (format "%s " name)))
    (while (not (string-match
		 (setq loc (read-key-sequence
			    (format "%s position (`%s') [%s]: "
				    guide oneof pos));name is in YaTeX-addin
		       loc (if (fboundp 'events-to-keys)
			       (events-to-keys loc) loc))
		 "\r\^g\n"))
      (cond
       ((string-match loc oneof)
	(if (not (string-match loc pos))
	    (setq pos (concat pos loc))))
       ((and (string-match loc "\C-h\C-?") (> (length pos) 0))
	(setq pos (substring pos 0 (1- (length pos)))))
       (t
	(ding)
	(message "Please input one of `%s'." oneof)
	(sit-for 3))))
    (message "")
    pos))

(defun YaTeX:read-position (oneof)
  "Read a LaTeX (optional) position format such as `[htbp]'."
  (let ((pos (YaTeX:read-oneof oneof)))
    (if (string= pos "")  "" (concat "[" pos "]"))))

(defun YaTeX:table ()
  "YaTeX add-in function for table environment."
  (cond
   ((eq major-mode 'yatex-mode)
    (setq YaTeX-env-name "tabular"
	  YaTeX-section-name "caption")
    (YaTeX:read-position "htbp"))
   ((eq major-mode 'texinfo-mode)
    (concat " "
	    (completing-read
	     "Highlights with: "
	     '(("@samp")("@kbd")("@code")("@asis")("@file")("@var"))
	     nil nil "@")))))

(fset 'YaTeX:figure 'YaTeX:table)
(fset 'YaTeX:figure* 'YaTeX:table)


(defun YaTeX:description ()
  "Truly poor service:-)"
  (setq YaTeX-single-command "item[]")
  "")

(defun YaTeX:itemize ()
  "It's also poor service."
  (setq YaTeX-single-command "item")
  "")

(fset 'YaTeX:enumerate 'YaTeX:itemize)

(defun YaTeX:picture ()
  "Ask the size of coordinates of picture environment."
  (concat (YaTeX:read-coordinates "Picture size")
	  (YaTeX:read-coordinates "Initial position")))

(defun YaTeX:equation ()
  (YaTeX-jmode-off)
  (if (fboundp 'YaTeX-toggle-math-mode)
      (YaTeX-toggle-math-mode t)))		;force math-mode ON.

(mapcar '(lambda (f) (fset f 'YaTeX:equation))
	'(YaTeX:eqnarray YaTeX:eqnarray* YaTeX:align YaTeX:align*
	  YaTeX:split YaTeX:multline YaTeX:multline* YaTeX:gather YaTeX:gather*
	  YaTeX:aligned* YaTeX:gathered YaTeX:gathered*
	  YaTeX:alignat YaTeX:alignat* YaTeX:xalignat YaTeX:xalignat*
	  YaTeX:xxalignat YaTeX:xxalignat*))

(defun YaTeX:list ()
  "%\n{} %default label\n{} %formatting parameter")

(defun YaTeX:minipage ()
  (concat (YaTeX:read-position "cbt")
	  "{" (read-string "Width: ") "}"))

(defun YaTeX:thebibliography ()
  (setq YaTeX-section-name "bibitem")
  "")

;;;
;;Sample functions for section-type command.
;;;
(defun YaTeX:multiput ()
  (concat (YaTeX:read-coordinates "Pos")
	  (YaTeX:read-coordinates "Step")
	  "{" (read-string "How many times: ") "}"))

(defun YaTeX:put ()
  (YaTeX:read-coordinates "Pos"))

(defun YaTeX:makebox ()
  (cond
   ((YaTeX-in-environment-p "picture")
    (concat (YaTeX:read-coordinates "Dimension")
	    (YaTeX:read-position "lrtb")))
   (t
    (let ((width (read-string "Width: ")))
      (if (string< "" width)
	  (progn
	    (or (equal (aref width 0) ?\[)
		(setq width (concat "[" width "]")))
	    (concat width (YaTeX:read-position "lr"))))))))

(defun YaTeX:framebox ()
  (if (YaTeX-quick-in-environment-p "picture")
      (YaTeX:makebox)))

(defun YaTeX:dashbox ()
  (concat "{" (read-string "Dash dimension: ") "}"
	  (YaTeX:read-coordinates "Dimension")))

(defvar YaTeX-minibuffer-quick-map nil)
(if YaTeX-minibuffer-quick-map nil
  (setq YaTeX-minibuffer-quick-map
	(copy-keymap minibuffer-local-completion-map))
  (let ((ch (1+ ? )))
    (while (< ch 127)
      (define-key YaTeX-minibuffer-quick-map (char-to-string ch)
	'YaTeX-minibuffer-quick-complete)
      (setq ch (1+ ch)))))

(defvar YaTeX:left-right-delimiters
   '(("(" . ")") (")" . "(") ("[" . "]") ("]" . "[")
     ("\\{" . "\\}") ("\\}" . "\\{") ("|") ("\\|")
     ("\\lfloor" . "\\rfloor") ("\\lceil" . "\\rceil")
     ("\\langle" . "\\rangle") ("/") (".")
     ("\\rfloor" . "\\rfloor") ("\\rceil" . "\\lceil")
     ("\\rangle" . "\\langle") ("\\backslash")
     ("\\uparrow") ("\\downarrow") ("\\updownarrow") ("\\Updownarrow"))
   "TeX math delimiter, which can be completed after \\right or \\left.")

(defvar YaTeX:left-right-default nil "Default string of YaTeX:right.")

(defun YaTeX:left ()
  (let ((minibuffer-completion-table YaTeX:left-right-delimiters)
	delimiter (leftp (string= YaTeX-single-command "left")))
    (setq delimiter
	  (read-from-minibuffer
	   (format "Delimiter%s: "
		   (if YaTeX:left-right-default
		       (format "(default=`%s')" YaTeX:left-right-default)
		     "(SPC for menu)"))
	   nil YaTeX-minibuffer-quick-map))
    (if (string= "" delimiter) (setq delimiter YaTeX:left-right-default))
    (setq YaTeX-single-command (if leftp "right" "left")
	  YaTeX:left-right-default
	  (or (cdr (assoc delimiter YaTeX:left-right-delimiters)) delimiter))
    delimiter))

(fset 'YaTeX:right 'YaTeX:left)


(defun YaTeX:read-coordinates (&optional mes varX varY)
  (concat
   "("
   (read-string (format "%s %s: " (or mes "Dimension") (or varX "X")))
   ","
   (read-string (format "%s %s: " (or mes "Dimension") (or varY "Y")))
   ")"))

;;;
;;Sample functions for maketitle-type command.
;;;
(defun YaTeX:sum ()
  "Read range of summation."
  (YaTeX:check-completion-type 'maketitle)
  (concat (YaTeX:read-boundary "_") (YaTeX:read-boundary "^")))

(fset 'YaTeX:int 'YaTeX:sum)

(defun YaTeX:lim ()
  "Insert limit notation of \\lim."
  (YaTeX:check-completion-type 'maketitle)
  (let ((var (read-string "Variable: ")) limit)
    (if (string= "" var) ""
      (setq limit (read-string "Limit ($ means infinity): "))
      (if (string= "$" limit) (setq limit "\\infty"))
      (concat "_{" var " \\rightarrow " limit "}"))))

(defun YaTeX:gcd ()
  "Add-in function for \\gcd(m,n)."
  (YaTeX:check-completion-type 'maketitle)
  (YaTeX:read-coordinates "\\gcd" "(?,)" "(,?)"))

(defun YaTeX:read-boundary (ULchar)
  "Read boundary usage by _ or ^.  _ or ^ is indicated by argument ULchar."
  (let ((bndry (read-string (concat ULchar "{???} ($ for infinity): "))))
    (if (string= bndry "") ""
      (if (string= bndry "$") (setq bndry "\\infty"))
      (concat ULchar "{" bndry "}"))))

(defun YaTeX:verb ()
  "Enclose \\verb's contents with the same characters."
  (let ((quote-char (read-string "Quoting char: " "|"))
	(contents (read-string "Quoted contents: ")))
    (concat quote-char contents quote-char)))

(fset 'YaTeX:verb* 'YaTeX:verb)

(defun YaTeX:footnotemark ()
  (setq YaTeX-section-name "footnotetext")
  nil)

(defun YaTeX:cite ()
  (let ((comment (read-string "Comment for citation: ")))
    (if (string= comment "") ""
      (concat "[" comment "]"))))

(defun YaTeX:bibitem ()
  (let ((label (read-string "Citation label for bibitem: ")))
    (if (string= label "") ""
      (concat "[" label "]"))))

(defun YaTeX:item ()
  (cond
   ((eq major-mode 'yatex-mode)
    (YaTeX-indent-line)
    (setq YaTeX-section-name "label"))
   ((eq major-mode 'texinfo-mode)
    (setq YaTeX-section-name "dots"))) ;??
  " ")
(fset 'YaTeX:item\[\] 'YaTeX:item)
(fset 'YaTeX:subitem 'YaTeX:item)
(fset 'YaTeX:subsubitem 'YaTeX:item)

(defun YaTeX:linebreak ()
  (let (obl)
    (message "Break strength 0,1,2,3,4 (default: 4): ")
    (setq obl (char-to-string (read-char)))
    (if (string-match "[0-4]" obl)
	(concat "[" obl "]")
      "")))
(fset 'YaTeX:pagebreak 'YaTeX:linebreak)

;;;
;;Subroutine
;;;

(defun YaTeX:check-completion-type (type)
  "Check valid completion type."
  (if (not (eq type YaTeX-current-completion-type))
      (error "This should be completed with %s-type completion." type)))


;;;
;;;		[[Add-in functions for reading section arguments]]
;;;
;; All of add-in functions for reading sections arguments should
;; take an argument ARGP that specify the argument position.
;; If argument position is out of range, nil should be returned,
;; else nil should NOT be returned.

;;
; Label selection
;;
(defvar YaTeX-label-menu-other
  (if YaTeX-japan "':他のバッファのラベル\n" "':LABEL IN OTHER BUFFER.\n"))
(defvar YaTeX-label-menu-repeat
  (if YaTeX-japan ".:直前の\\refと同じ\n" "/:REPEAT LAST \ref{}\n"))
(defvar YaTeX-label-menu-any
  (if YaTeX-japan "*:任意の文字列\n" "*:ANY STRING.\n"))
(defvar YaTeX-label-buffer "*Label completions*")
(defvar YaTeX-label-guide-msg "Select label and hit RETURN.")
(defvar YaTeX-label-select-map nil
  "Key map used in label selection buffer.")
(defun YaTeX::label-setup-key-map ()
  (if YaTeX-label-select-map nil
    (message "Setting up label selection mode map...")
    ;(setq YaTeX-label-select-map (copy-keymap global-map))
    (setq YaTeX-label-select-map (make-keymap))
    (suppress-keymap YaTeX-label-select-map)
    (substitute-all-key-definition
     'previous-line 'YaTeX::label-previous YaTeX-label-select-map)
    (substitute-all-key-definition
     'next-line 'YaTeX::label-next YaTeX-label-select-map)
    (define-key YaTeX-label-select-map "\C-n"	'YaTeX::label-next)
    (define-key YaTeX-label-select-map "\C-p"	'YaTeX::label-previous)
    (define-key YaTeX-label-select-map "<"	'beginning-of-buffer)
    (define-key YaTeX-label-select-map ">"	'end-of-buffer)
    (define-key YaTeX-label-select-map "\C-m"	'exit-recursive-edit)
    (define-key YaTeX-label-select-map "\C-j"	'exit-recursive-edit)
    (define-key YaTeX-label-select-map " "	'exit-recursive-edit)
    (define-key YaTeX-label-select-map "\C-g"	'abort-recursive-edit)
    (define-key YaTeX-label-select-map "/"	'isearch-forward)
    (define-key YaTeX-label-select-map "?"	'isearch-backward)
    (define-key YaTeX-label-select-map "'"	'YaTeX::label-search-tag)
    (define-key YaTeX-label-select-map "."	'YaTeX::label-search-tag)
    (define-key YaTeX-label-select-map "*"	'YaTeX::label-search-tag)
    (message "Setting up label selection mode map...Done")
    (let ((key ?A))
      (while (<= key ?Z)
	(define-key YaTeX-label-select-map (char-to-string key)
	  'YaTeX::label-search-tag)
	(define-key YaTeX-label-select-map (char-to-string (+ key (- ?a ?A)))
	  'YaTeX::label-search-tag)
	(setq key (1+ key))))))

(defun YaTeX::label-next ()
  (interactive) (forward-line 1) (message YaTeX-label-guide-msg))
(defun YaTeX::label-previous ()
  (interactive) (forward-line -1) (message YaTeX-label-guide-msg))
(defun YaTeX::label-search-tag ()
  (interactive)
  (let ((case-fold-search t)
	(tag (regexp-quote (char-to-string last-command-char))))
    (cond
     ((save-excursion
	(forward-char 1)
	(re-search-forward (concat "^" tag) nil t))
      (goto-char (match-beginning 0)))
     ((save-excursion
	(goto-char (point-min))
	(re-search-forward (concat "^" tag) nil t))
      (goto-char (match-beginning 0))))
    (message YaTeX-label-guide-msg)))

; (defun YaTeX::ref (argp &optional labelcmd refcmd)
;   (cond
;    ((= argp 1)
;     (let ((lnum 0) e0 label label-list (buf (current-buffer))
; 	  (labelcmd (or labelcmd "label")) (refcmd (or refcmd "ref"))
; 	  (p (point)) initl line cf)
;       (message "Collecting labels...")
;       (save-window-excursion
; 	(YaTeX-showup-buffer
; 	 YaTeX-label-buffer (function (lambda (x) (window-width x))))
; 	(if (fboundp 'select-frame) (setq cf (selected-frame)))
; 	(if (eq (window-buffer (minibuffer-window)) buf)
; 	    (progn
; 	      (other-window 1)
; 	      (setq buf (current-buffer))
; 	      (set-buffer buf)
; 	      ;(message "cb=%s" buf)(sit-for 3)
; 	      ))
; 	(save-excursion
; 	  (set-buffer (get-buffer-create YaTeX-label-buffer))
; 	  (setq buffer-read-only nil)
; 	  (erase-buffer))
; 	(save-excursion
; 	  (goto-char (point-min))
; 	  (let ((standard-output (get-buffer YaTeX-label-buffer)))
; 	    (princ (format "=== LABELS in [%s] ===\n" (buffer-name buf)))
; 	    (while (YaTeX-re-search-active-forward
; 		    (concat "\\\\" labelcmd "\\b")
; 		    (regexp-quote YaTeX-comment-prefix) nil t)
; 	      (goto-char (match-beginning 0))
; 	      (skip-chars-forward "^{")
; 	      (setq label
; 		    (buffer-substring
; 		     (1+ (point))
; 		     (prog2 (forward-list 1) (setq e0 (1- (point)))))
; 		    label-list (cons label label-list))
; 	      (or initl
; 		  (if (< p (point)) (setq initl lnum)))
; 	      (beginning-of-line)
; 	      (skip-chars-forward " \t\n" nil)
; 	      (princ (format "%c:{%s}\t<<%s>>\n" (+ (% lnum 26) ?A) label
; 			     (buffer-substring (point) (point-end-of-line))))
; 	      (setq lnum (1+ lnum))
; 	      (message "Collecting \\%s{}... %d" labelcmd lnum)
; 	      (goto-char e0))
; 	    (princ YaTeX-label-menu-other)
; 	    (princ YaTeX-label-menu-repeat)
; 	    (princ YaTeX-label-menu-any)
; 	    );standard-output
; 	  (goto-char p)
; 	  (or initl (setq initl lnum))
; 	  (message "Collecting %s...Done" labelcmd)
; 	  (if (fboundp 'select-frame) (select-frame cf))
; 	  (YaTeX-showup-buffer YaTeX-label-buffer nil t)
; 	  (YaTeX::label-setup-key-map)
; 	  (setq truncate-lines t)
; 	  (setq buffer-read-only t)
; 	  (use-local-map YaTeX-label-select-map)
; 	  (message YaTeX-label-guide-msg)
; 	  (goto-line (1+ initl)) ;goto recently defined label line
; 	  (switch-to-buffer (current-buffer))
; 	  (unwind-protect
; 	      (progn
; 		(recursive-edit)
; 		(set-buffer (get-buffer YaTeX-label-buffer)) ;assertion
; 		(beginning-of-line)
; 		(setq line (1- (count-lines (point-min)(point))))
; 		(cond
; 		 ((= line -1) (setq label ""))
; 		 ((= line lnum) (setq label (YaTeX-label-other)))
; 		 ((= line (1+ lnum))
; 		  (save-excursion
; 		    (switch-to-buffer buf)
; 		    (goto-char p)
; 		    (if (re-search-backward
; 			 (concat "\\\\" refcmd "{\\([^}]+\\)}") nil t)
; 			(setq label (YaTeX-match-string 1))
; 		      (setq label ""))))
; 		 ((>= line (+ lnum 2))
; 		  (setq label (read-string (format "\\%s{???}: " refcmd))))
; 		 (t (setq label (nth (- lnum line 1) label-list)))))
; 	    (bury-buffer YaTeX-label-buffer)))
; 	label)))))

(defun YaTeX::ref-generate-label ()
  "Generate a label string which is unique in current buffer."
  (let ((default (substring (current-time-string) 4)))
    (read-string "Give a label for this line: "
		 (if YaTeX-emacs-19 (cons default 1) default))))

(defun YaTeX::ref-getset-label (buffer point)
  "Get label string in the BUFFER near the POINT.
Make \\label{xx} if no label."
  ;;Here, we rewrite the LaTeX source.  Therefore we should be careful
  ;;to decide the location suitable for \label.  Do straightforward!
  (let (boundary inspoint cc newlabel (labelholder "label") mathp env
       (r-escape (regexp-quote YaTeX-comment-prefix)))
    ;;(set-buffer buffer)
    (switch-to-buffer buffer)
    (save-excursion
      (goto-char point)
      (setq cc (current-column))
      (if (= (char-after (point)) ?\\) (forward-char 1))
      (cond
       ((looking-at YaTeX-sectioning-regexp)
	(skip-chars-forward "^{")
	(forward-list 1)
	(skip-chars-forward " \t\n")
	;(setq boundary "[^\\]")
	(setq boundary
	      (save-excursion
		(if (YaTeX-re-search-active-forward "[^\\]" r-escape nil 1)
		    (match-beginning 0)
		  (1- (point))))))
       ((looking-at "item\\s ")
	(setq cc (+ cc 6))
	;(setq boundary (concat YaTeX-ec-regexp "\\(item\\|begin\\|end\\)\\b"))
	(setq boundary
	      (save-excursion
		(if (YaTeX-re-search-active-forward
		     (concat YaTeX-ec-regexp "\\(item\\|begin\\|end\\)\\b")
		     r-escape nil 1)
		    (match-beginning 0)
		  (1- (point))))))
       ((looking-at "bibitem")
	(setq labelholder "bibitem")	; label holder is bibitem itself
	(setq boundary
	      (save-excursion
		(if (YaTeX-re-search-active-forward
		     (concat YaTeX-ec-regexp "\\(bibitem\\|end\\)\\b")
		     r-escape nil 1)
		    (match-beginning 0)
		  (1- (point))))))
       ((string-match YaTeX::ref-mathenv-regexp
		      (setq env (or (YaTeX-inner-environment t) "document")))
	(setq mathp t)
	;;(setq boundary (concat YaTeX-ec-regexp "\\(\\\\\\|end{" env "}\\)"))
	(setq boundary
	      (save-excursion
		(if (YaTeX-re-search-active-forward
		     (concat YaTeX-ec-regexp "\\(\\\\\\|end{" env "}\\)")
		     r-escape nil 1)
		    (match-beginning 0)
		  (1- (point))))))
       ((looking-at "footnote\\s *{")
	(skip-chars-forward "^{")	;move onto `{'
	(setq boundary
	      (save-excursion
		(condition-case err
		    (forward-list 1)
		  (error (error "\\\\footnote at point %s's brace not closed"
				(point))))
		(1- (point)))))
       ((looking-at "caption\\|\\(begin\\)")
	(skip-chars-forward "^{")
	(if (match-beginning 1) (forward-list 1))
	;;(setq boundary (concat YaTeX-ec-regexp "\\(begin\\|end\\)\\b"))
	(setq boundary
	      (save-excursion
		(if (YaTeX-re-search-active-forward
		     (concat YaTeX-ec-regexp "\\(begin\\|end\\)\\b")
		     r-escape nil 1)
		    (match-beginning 0)
		(1- (point))))))
       (t ))
      (if (save-excursion (skip-chars-forward " \t") (looking-at "%"))
	  (forward-line 1))
      (if (and (save-excursion
		 (YaTeX-re-search-active-forward
		  ;;(concat "\\(" labelholder "\\)\\|\\(" boundary "\\)")
		  labelholder
		  (regexp-quote YaTeX-comment-prefix)
		  boundary 1))
	       (match-beginning 0))
	  ;; if \label{hoge} found, return it
	  (buffer-substring
	   (progn
	     (goto-char (match-end 0))
	     (skip-chars-forward "^{") (1+ (point)))
	   (progn
	     (forward-sexp 1) (1- (point))))
	;;else make a label
	;(goto-char (match-beginning 0))
	(goto-char boundary)
	(skip-chars-backward " \t\n")
	(save-excursion (setq newlabel (YaTeX::ref-generate-label)))
	(delete-region (point) (progn (skip-chars-backward " \t") (point)))
	(if mathp nil 
	  (insert "\n")
	  (YaTeX-reindent cc))
	(insert (format "\\label{%s}" newlabel))
	newlabel))))

(defvar YaTeX::ref-labeling-regexp-alist
  '(("\\\\begin{java}{\\([^}]+\\)}" . 1)
    ("\\\\elabel{\\([^}]+\\)}" . 1)))
(defvar YaTeX::ref-labeling-regexp
  (mapconcat 'car YaTeX::ref-labeling-regexp-alist "\\|"))
(defvar YaTeX::ref-mathenv-regexp
  "equation\\|eqnarray\\|align\\|gather\\|alignat\\|xalignat")
(defvar YaTeX::ref-enumerateenv-regexp
  "enumerate")

(defvar YaTeX::ref-labeling-section-level 2
  "*ref補完で収集するセクショニングコマンドの下限レベル
YaTeX-sectioning-levelの数値で指定.")

(defun YaTeX::ref (argp &optional labelcmd refcmd)
  (setplist 'YaTeX::ref-labeling-regexp nil) ;erase memory cache
  (require 'yatexsec)
  (cond
   ((= argp 1)
    (let*((lnum 0) e0 x cmd label match-point point-list boundary
	  (buf (current-buffer))
	  (llv YaTeX::ref-labeling-section-level)
	  (mathenvs YaTeX::ref-mathenv-regexp)
	  (enums YaTeX::ref-enumerateenv-regexp)
	  (counter
	   (or labelcmd
	       (concat
		YaTeX-ec-regexp "\\(\\("
		(mapconcat
		 'concat
		 (delq nil
		       (mapcar
			(function
			 (lambda (s)
			   (if (>= llv (cdr s))
			       (car s))))
			YaTeX-sectioning-level))
		 "\\|")
		"\\|caption\\|footnote\\){"
		"\\|\\(begin{\\(" mathenvs "\\|" enums  "\\)\\)\\)")))
	  (regexp (concat "\\(" counter
			  "\\)\\|\\(" YaTeX::ref-labeling-regexp "\\)"))
	  (itemsep (concat YaTeX-ec-regexp
			   "\\(\\(bib\\)?item\\|begin\\|end\\)"))
	  (refcmd (or refcmd "ref"))
	  (p (point)) initl line cf
	  (percent (regexp-quote YaTeX-comment-prefix))
	  (output
	   (function
	    (lambda (label p)
	      (while (setq x (string-match "\n" label))
		(aset label x ? ))
	      (while (setq x (string-match "[ \t\n][ \t\n]+" label))
		(setq label (concat
			     (substring label 0 (1+ (match-beginning 0)))
			     (substring label (match-end 0)))))
	      (princ (format "%c: <<%s>>\n" (+ (% lnum 26) ?A) label))
	      (setq point-list (cons p point-list))
	      (message "Collecting labels... %d" lnum)
	      (setq lnum (1+ lnum)))))
	  )
      (message "Collecting labels...")
      (save-window-excursion
	(YaTeX-showup-buffer
	 YaTeX-label-buffer (function (lambda (x) (window-width x))))
	(if (fboundp 'select-frame) (setq cf (selected-frame)))
	(if (eq (window-buffer (minibuffer-window)) buf)
	    (progn
	      (other-window 1)
	      (setq buf (current-buffer))
	      (set-buffer buf)))
	(save-excursion
	  (set-buffer (get-buffer-create YaTeX-label-buffer))
	  (setq buffer-read-only nil)
	  (erase-buffer))
	(save-excursion
	  (set-buffer buf)
	  (goto-char (point-min))
	  (let ((standard-output (get-buffer YaTeX-label-buffer)))
	    (princ (format "=== LABELS in [%s] ===\n" (buffer-name buf)))
	    (while (YaTeX-re-search-active-forward
		    regexp ;;counter
		    percent nil t)
	      ;(goto-char (match-beginning 0))
	      (setq e0 (match-end 0))
	      (cond
	       ((YaTeX-literal-p) nil)
	       ((YaTeX-match-string 1)
		;;if standard counter commands found 
		(setq cmd (YaTeX-match-string 2))
		(setq match-point (match-beginning 0))
		(or initl
		    (if (< p (point)) (setq initl lnum)))
		(cond
		 ((string-match mathenvs cmd) ;;if matches mathematical env
		  ;(skip-chars-forward "} \t\n")
		  (forward-line 1)
		  (setq x (point))
		  (catch 'scan
		    (while (YaTeX-re-search-active-forward
			    (concat "\\\\\\\\$\\|\\\\end{\\(" mathenvs "\\)")
			    percent nil t)
		      (let ((quit (match-beginning 1)))
			(funcall output
				 (buffer-substring x (match-beginning 0))
				 x)
			(if quit (throw 'scan t)))
		      (setq x (point))))
		  (setq e0 (point)))
		 ((string-match enums cmd)
		  ;(skip-chars-forward "} \t\n")
		  (save-restriction
		    (narrow-to-region
		     (point)
		     (save-excursion
		       (YaTeX-goto-corresponding-environment) (point)))
		    (forward-line 1)
		    (while (YaTeX-re-search-active-forward
			    (concat YaTeX-ec-regexp "item\\s ")
			    percent nil t)
		      (setq x (match-beginning 0))
		      (funcall
		       output
		       (buffer-substring
			(match-beginning 0)
			(if (re-search-forward itemsep nil t)
			    (progn (goto-char (match-beginning 0))
				   (skip-chars-backward " \t")
				   (1- (point)))
			  (point-end-of-line)))
		       x))))

		 ((= (char-after (1- (point))) ?{)
		  (setq label (buffer-substring
			       (match-beginning 0)
			       (progn (forward-char -1)
				      (forward-list 1)
				      (point))))
		  (funcall output label match-point))
		 (t
		  (skip-chars-forward " \t")
		  (setq label (buffer-substring
			       (match-beginning 0)
			       (if (re-search-forward
				    itemsep
				    nil t)
				   (progn
				     (goto-char (match-beginning 0))
				     (skip-chars-backward " \t")
				     (1- (point)))
				 (point-end-of-line))))
		  (funcall output label match-point)
		  ))
		) ;;put label buffer
	       ;;
	       ;; if user defined label found
	       (t
		;; memorize line number and label into property
		(goto-char (match-beginning 0))
		(let ((list YaTeX::ref-labeling-regexp-alist)
		      (cache (symbol-plist 'YaTeX::ref-labeling-regexp)))
		  (while list
		    (if (looking-at (car (car list)))
			(progn
			  (setq label (YaTeX-match-string 0))
			  (put 'YaTeX::ref-labeling-regexp lnum
			       (YaTeX-match-string (cdr (car list))))
			  (funcall output label 0) ;;0 is dummy, never used
			  (setq list nil)))
		    (setq list (cdr list))))
		))
	      (goto-char e0))
	    (princ YaTeX-label-menu-other)
	    (princ YaTeX-label-menu-repeat)
	    (princ YaTeX-label-menu-any)
	    );standard-output
	  (goto-char p)
	  (or initl (setq initl lnum))
	  (message "Collecting labels...Done")
	  (if (fboundp 'select-frame) (select-frame cf))
	  (YaTeX-showup-buffer YaTeX-label-buffer nil t)
	  (YaTeX::label-setup-key-map)
	  (setq truncate-lines t)
	  (setq buffer-read-only t)
	  (use-local-map YaTeX-label-select-map)
	  (message YaTeX-label-guide-msg)
	  (goto-line (1+ initl)) ;goto recently defined label line
	  (switch-to-buffer (current-buffer))
	  (unwind-protect
	      (progn
		(recursive-edit)

		(set-buffer (get-buffer YaTeX-label-buffer)) ;assertion
		(beginning-of-line)
		(setq line (1- (count-lines (point-min)(point))))
		(cond
		 ((= line -1) (setq label ""))
		 ((= line lnum) (setq label (YaTeX-label-other)))
		 ((= line (1+ lnum))
		  (save-excursion
		    (switch-to-buffer buf)
		    (goto-char p)
		    (if (re-search-backward
			 (concat "\\\\" refcmd "{\\([^}]+\\)}") nil t)
			(setq label (YaTeX-match-string 1))
		      (setq label ""))))
		 ((>= line (+ lnum 2))
		  (setq label (read-string (format "\\%s{???}: " refcmd))))
		 (t ;(setq label (nth (- lnum line 1) label-list))
		  (setq label
			(or (get 'YaTeX::ref-labeling-regexp line)
			    (YaTeX::ref-getset-label
			     buf (nth (- lnum line 1) point-list))))
		  )))
	    (bury-buffer YaTeX-label-buffer)))
	label)))))

(fset 'YaTeX::pageref 'YaTeX::ref)

(defun YaTeX::cite-collect-bibs-external (&rest files)
  "Collect bibentry from FILES(variable length argument);
and print them to standard output."
  ;;Thanks; http://icarus.ilcs.hokudai.ac.jp/comp/biblio.html
  (let ((tb (get-buffer-create " *bibtmp*")))
    (save-excursion
      (set-buffer tb)
      (while files
	(erase-buffer)
	(cond
	 ((file-exists-p (car files))
	  (insert-file-contents (car files)))
	 ((file-exists-p (concat (car files) ".bib"))
	  (insert-file-contents (concat (car files) ".bib"))))
	(save-excursion
	  (goto-char (point-min))
	  (while (re-search-forward "^\\s *@[A-Za-z]" nil t)
	    (skip-chars-forward "^{,")
	    (if (= (char-after (point)) ?{)
		(princ (format "%sbibitem{%s}%s\n"
			       YaTeX-ec
			       (buffer-substring
				(1+ (point))
				(progn (skip-chars-forward "^,\n")
				       (point)))
			       (if (re-search-forward "title\\s *=" nil t)
				   (buffer-substring
				    (progn
				      (goto-char (match-end 0))
				      (skip-chars-forward " \t\n")
				      (point))
				    (progn
				      (if (looking-at "[{\"]")
					  (forward-sexp 1)
					(forward-char 1)
					(skip-chars-forward "^,"))
				      (point)))))))))
	(setq files (cdr files))))))

(defun YaTeX::cite-collect-bibs-internal ()
  "Collect bibentry in the current buffer and print them to standard output."
  (let ((ptn (concat YaTeX-ec-regexp "bibitem\\b"))
	(pcnt (regexp-quote YaTeX-comment-prefix)))
    (save-excursion
      (while (YaTeX-re-search-active-forward ptn pcnt nil t)
	(skip-chars-forward "^{\n")
	(or (eolp)
	    (princ (format "%sbibitem{%s}\n"
			   YaTeX-ec
			   (buffer-substring
			    (1+ (point))
			    (progn (forward-sexp 1) (point))))))))))

(defun YaTeX::cite (argp)
  (cond
   ((eq argp 1)
    (let* ((cb (current-buffer))
	   (f (file-name-nondirectory buffer-file-name))
	   (d default-directory)
	   (hilit-auto-highlight nil)
	   (pcnt (regexp-quote YaTeX-comment-prefix))
	   (bibrx (concat YaTeX-ec-regexp "bibliography{\\([^}]+\\)}"))
	   (bbuf (get-buffer-create " *bibitems*"))
	   (standard-output bbuf)
	   bibs files)
      (set-buffer bbuf)(erase-buffer)(set-buffer cb)
      (save-excursion
	(goto-char (point-min))
	;;(1)search external bibdata
	(while (YaTeX-re-search-active-forward bibrx pcnt nil t)
	  (apply 'YaTeX::cite-collect-bibs-external
		 (YaTeX-split-string
		  (YaTeX-match-string 1) ",")))
	;;(2)search direct \bibitem usage
	(YaTeX::cite-collect-bibs-internal)
	(if (progn
	      (YaTeX-visit-main t)
	      (not (eq (current-buffer) cb)))
	    (save-excursion
	      (goto-char (point-min))
	      ;;(1)search external bibdata
	      (while (YaTeX-re-search-active-forward bibrx pcnt nil t)
		(apply 'YaTeX::cite-collect-bibs-external
		       (YaTeX-split-string
			(YaTeX-match-string 1) ",")))
	      ;;(2)search internal
	      (YaTeX::cite-collect-bibs-internal)))
	;;Now bbuf holds the list of bibitem
	(set-buffer bbuf)
	(YaTeX::ref argp "\\\\\\(bibitem\\)\\(\\[.*\\]\\)?" "cite"))))
  
   (t nil)))

(and YaTeX-use-AMS-LaTeX (fset 'YaTeX::eqref 'YaTeX::ref))

(defun YaTeX-yatex-buffer-list ()
  (save-excursion
    (delq nil (mapcar (function (lambda (buf)
				  (set-buffer buf)
				  (if (eq major-mode 'yatex-mode) buf)))
		      (buffer-list)))))

(defun YaTeX-select-other-yatex-buffer ()
  "Select buffer from all yatex-mode's buffers interactivelly."
  (interactive)
  (let ((lbuf "*YaTeX mode buffers*") (blist (YaTeX-yatex-buffer-list))
	(lnum -1) buf rv
	(ff "**find-file**"))
    (YaTeX-showup-buffer
     lbuf (function (lambda (x) 1)))	;;Select next window surely.
    (save-excursion
      (set-buffer (get-buffer lbuf))
      (setq buffer-read-only nil)
      (erase-buffer))
    (let ((standard-output (get-buffer lbuf)))
      (while blist
	(princ
	 (format "%c:{%s}\n" (+ (% (setq lnum (1+ lnum)) 26) ?A)
		 (buffer-name (car blist))))
	(setq blist (cdr blist)))
      (princ (format "':{%s}" ff)))
    (YaTeX-showup-buffer lbuf nil t)
    (YaTeX::label-setup-key-map)
    (setq buffer-read-only t)
    (use-local-map YaTeX-label-select-map)
    (message YaTeX-label-guide-msg)
    (unwind-protect
	(progn
	  (recursive-edit)
	  (set-buffer lbuf)
	  (beginning-of-line)
	  (setq rv
		(if (re-search-forward "{\\([^\\}]+\\)}" (point-end-of-line) t)
		    (buffer-substring (match-beginning 1) (match-end 1)) nil)))
      (kill-buffer lbuf))
    (if (string= rv ff)
	(progn
	  (call-interactively 'find-file)
	  (current-buffer))
      rv)))

(defun YaTeX-label-other ()
  (let ((rv (YaTeX-select-other-yatex-buffer)))
    (cond
     ((null rv) "")
     (t
      (set-buffer rv)
      (YaTeX::ref argp labelcmd refcmd)))))

;;
; completion for the arguments of \newcommand
;;
(defun YaTeX::newcommand (&optional argp)
  (cond
   ((= argp 1)
    (let ((command (read-string "Define newcommand: " "\\")))
      (put 'YaTeX::newcommand 'command (substring command 1))
      command))
   ((= argp 2)
    (let ((argc
	   (string-to-int (read-string "Number of arguments(Default 0): ")))
	  (def (read-string "Definition: "))
	  (command (get 'YaTeX::newcommand 'command)))
      ;;!!! It's illegal to insert string in the add-in function !!!
      (if (> argc 0) (insert (format "[%d]" argc)))
      (if (and (stringp command)
	       (string< "" command)
	       (y-or-n-p "Update dictionary?"))
	  (cond
	   ((= argc 0)
	    (YaTeX-update-table
	     (list command)
	     'singlecmd-table 'user-singlecmd-table 'tmp-singlecmd-table))
	   ((= argc 1)
	    (YaTeX-update-table
	     (list command)
	     'section-table 'user-section-table 'tmp-section-table))
	   (t (YaTeX-update-table
	       (list command argc)
	       'section-table 'user-section-table 'tmp-section-table))))
      (message "")
      def				;return command name
      ))
   (t "")))

;;
; completion for the arguments of \pagestyle
;;
(defun YaTeX::pagestyle (&optional argp)
  "Read the pagestyle with completion."
  (completing-read
   "Page style: "
   '(("plain") ("empty") ("headings") ("myheadings") ("normal") nil)))

(fset 'YaTeX::thispagestyle 'YaTeX::pagestyle)

;;
; completion for the arguments of \pagenumbering
;;
(defun YaTeX::pagenumbering (&optional argp)
  "Read the numbering style."
  (completing-read
   "Page numbering style: "
   '(("arabic") ("Alpha") ("alpha") ("Roman") ("roman"))))

;;
; Length
;;
(defvar YaTeX:style-parameters-default
  '(("\\arraycolsep")
    ("\\arrayrulewidth")
    ("\\baselineskip")
    ("\\columnsep")
    ("\\columnseprule")
    ("\\doublerulesep")
    ("\\evensidemargin")
    ("\\footheight")
    ("\\footskip")
    ("\\headheight")
    ("\\headsep")
    ("\\itemindent")
    ("\\itemsep")
    ("\\labelsep")
    ("\\labelwidth")
    ("\\leftmargin")
    ("\\linewidth")
    ("\\listparindent")
    ("\\marginparsep")
    ("\\marginparwidth")
    ("\\mathindent")
    ("\\oddsidemargin")
    ("\\parindent")
    ("\\parsep")
    ("\\parskip")
    ("\\partopsep")
    ("\\rightmargin")
    ("\\tabcolsep")
    ("\\textheight")
    ("\\textwidth")
    ("\\topmargin")
    ("\\topsep")
    ("\\topskip")
    )
  "Alist of LaTeX style parameters.")
(defvar YaTeX:style-parameters-private nil
  "*User definable alist of style parameters.")
(defvar YaTeX:style-parameters-local nil
  "*User definable alist of local style parameters.")

(defvar YaTeX:length-history nil "Holds history of length.")
(put 'YaTeX:length-history 'no-default t)
(defun YaTeX::setlength (&optional argp)
  "YaTeX add-in function for arguments of \\setlength."
  (cond
   ((equal 1 argp)
    ;;(completing-read "Length variable: " YaTeX:style-parameters nil nil "\\")
    (YaTeX-cplread-with-learning
     "Length variable: "
     'YaTeX:style-parameters-default
     'YaTeX:style-parameters-private
     'YaTeX:style-parameters-local
     nil nil "\\")
    )
   ((equal 2 argp)
    (read-string-with-history "Length: " nil 'YaTeX:length-history))))

(fset 'YaTeX::addtolength 'YaTeX::setlength)

(defun YaTeX::settowidth (&optional argp)
  "YaTeX add-in function for arguments of \\settowidth."
  (cond
   ((equal 1 argp)
    (YaTeX-cplread-with-learning
     "Length variable: "
     'YaTeX:style-parameters-default
     'YaTeX:style-parameters-private
     'YaTeX:style-parameters-local
     nil nil "\\"))
   ((equal 2 argp)
    (read-string "Text: "))))

(defun YaTeX::newlength (&optional argp)
  "YaTeX add-in function for arguments of \\newlength"
  (cond
   ((equal argp 1)
    (let ((length (read-string "Length variable: " "\\")))
      (if (string< "" length)
	  (YaTeX-update-table
	   (list length)
	   'YaTeX:style-parameters-default
	   'YaTeX:style-parameters-private
	   'YaTeX:style-parameters-local))
      length))))

;; \multicolumn's arguments
(defun YaTeX::multicolumn (&optional argp)
  "YaTeX add-in function for arguments of \\multicolumn."
  (cond
   ((equal 1 argp)
    (read-string "Number of columns: "))
   ((equal 2 argp)
    (let (c)
      (while (not (string-match
		   (progn (message "Format(one of l,r,c): ")
			  (setq c (char-to-string (read-char))))
		   "lrc")))
      c))
   ((equal 3 argp)
    (read-string "Item: "))))

(defvar YaTeX:documentstyles-default
  '(("article") ("jarticle") ("j-article")
    ("book") ("jbook") ("j-book")
    ("report") ("jreport") ("j-report")
    ("letter") ("ascjletter"))
  "List of LaTeX documentstyles.")
(defvar YaTeX:documentstyles-private nil
  "*User defined list of LaTeX documentstyles.")
(defvar YaTeX:documentstyles-local nil
  "*User defined list of local LaTeX documentstyles.")
(defvar YaTeX:documentstyle-options-default
  '(("a4j") ("a5j") ("b4j") ("b5j")
    ("twocolumn") ("jtwocolumn") ("epsf") ("epsfig") ("epsbox") ("nfig"))
  "List of LaTeX documentstyle options.")
(defvar YaTeX:documentstyle-options-private nil
  "*User defined list of LaTeX documentstyle options.")
(defvar YaTeX:documentstyle-options-local nil
  "List of LaTeX local documentstyle options.")

(defvar YaTeX-minibuffer-completion-map nil
  "Minibuffer completion key map that allows comma completion.")
(if YaTeX-minibuffer-completion-map nil
  (setq YaTeX-minibuffer-completion-map
	(copy-keymap minibuffer-local-completion-map))
  (define-key YaTeX-minibuffer-completion-map " "
    'YaTeX-minibuffer-complete)
  (define-key YaTeX-minibuffer-completion-map "\t"
    'YaTeX-minibuffer-complete))

(defun YaTeX:documentstyle ()
  (let*((delim ",")
	(dt (append YaTeX:documentstyle-options-local
		    YaTeX:documentstyle-options-private
		    YaTeX:documentstyle-options-default))
	(minibuffer-completion-table dt)
	(opt (read-from-minibuffer
	      "Style options ([opt1,opt2,...]): "
	      nil YaTeX-minibuffer-completion-map nil))
	(substr opt) o)
    (if (string< "" opt)
	(progn
	  (while substr
	    (setq o (substring substr 0 (string-match delim substr)))
	    (or (assoc o dt)
		(YaTeX-update-table
		 (list o)
		 'YaTeX:documentstyle-options-default
		 'YaTeX:documentstyle-options-private
		 'YaTeX:documentstyle-options-local))
	    (setq substr
		  (if (string-match delim substr)
		      (substring substr (1+ (string-match delim substr))))))
	  (concat "[" opt "]"))
      "")))

(defun YaTeX::documentstyle (&optional argp)
  "YaTeX add-in function for arguments of \\documentstyle."
  (cond
   ((equal argp 1)
    (setq YaTeX-env-name "document")
    (let ((sname
	   (YaTeX-cplread-with-learning
	    (format "Documentstyle (default %s): "
		    YaTeX-default-document-style)
	    'YaTeX:documentstyles-default
	    'YaTeX:documentstyles-private
	    'YaTeX:documentstyles-local)))
      (if (string= "" sname) (setq sname YaTeX-default-document-style))
      (setq YaTeX-default-document-style sname)))))

;;; -------------------- LaTeX2e stuff --------------------
(defvar YaTeX:documentclass-options-default
  '(("a4paper") ("a5paper") ("b4paper") ("b5paper") ("10pt") ("11pt") ("12pt")
    ("latterpaper") ("legalpaper") ("executivepaper") ("landscape")
    ("oneside") ("twoside") ("draft") ("final") ("leqno") ("fleqn") ("openbib")
    ("tombow") ("titlepage") ("notitlepage") ("dvips")
    ("clock")				;for slides class only
    )
    "Default options list for documentclass")
(defvar YaTeX:documentclass-options-private nil
  "*User defined options list for documentclass")
(defvar YaTeX:documentclass-options-local nil
  "*User defined options list for local documentclass")

(defun YaTeX:documentclass ()
  (let*((delim ",")
	(dt (append YaTeX:documentclass-options-local
		    YaTeX:documentclass-options-private
		    YaTeX:documentclass-options-default))
	(minibuffer-completion-table dt)
	(opt (read-from-minibuffer
	      "Documentclass options ([opt1,opt2,...]): "
	      nil YaTeX-minibuffer-completion-map nil))
	(substr opt) o)
    (if (string< "" opt)
	(progn
	  (while substr

	    (setq o (substring substr 0 (string-match delim substr)))
	    (or (assoc o dt)
		(YaTeX-update-table
		 (list o)
		 'YaTeX:documentclass-options-default
		 'YaTeX:documentclass-options-private
		 'YaTeX:documentclass-options-local))
	    (setq substr
		  (if (string-match delim substr)
		      (substring substr (1+ (string-match delim substr))))))
	  (concat "[" opt "]"))
      "")))

(defvar YaTeX:documentclasses-default
  '(("article") ("jarticle") ("report") ("jreport") ("book") ("jbook")
    ("j-article") ("j-report") ("j-book")
    ("letter") ("slides") ("ltxdoc") ("ltxguide") ("ltnews") ("proc"))
  "Default documentclass alist")
(defvar YaTeX:documentclasses-private nil
  "*User defined documentclass alist")
(defvar YaTeX:documentclasses-local nil
  "*User defined local documentclass alist")
(defvar YaTeX-default-documentclass (if YaTeX-japan "jarticle" "article")
  "*Default documentclass")

(defun YaTeX::documentclass (&optional argp)
  (cond
   ((equal argp 1)
    (setq YaTeX-env-name "document")
    (let ((sname
	   (YaTeX-cplread-with-learning
	    (format "Documentclass (default %s): " YaTeX-default-documentclass)
	    'YaTeX:documentclasses-default
	    'YaTeX:documentclasses-private
	    'YaTeX:documentclasses-local)))
      (if (string= "" sname) (setq sname YaTeX-default-documentclass))
      (setq YaTeX-default-documentclass sname)))))

(defvar YaTeX:latex2e-named-color-alist
  '(("GreenYellow") ("Yellow") ("Goldenrod") ("Dandelion") ("Apricot")
    ("Peach") ("Melon") ("YellowOrange") ("Orange") ("BurntOrange")
    ("Bittersweet") ("RedOrange") ("Mahogany") ("Maroon") ("BrickRed")
    ("Red") ("OrangeRed") ("RubineRed") ("WildStrawberry") ("Salmon")
    ("CarnationPink") ("Magenta") ("VioletRed") ("Rhodamine") ("Mulberry")
    ("RedViolet") ("Fuchsia") ("Lavender") ("Thistle") ("Orchid")("DarkOrchid")
    ("Purple") ("Plum") ("Violet") ("RoyalPurple") ("BlueViolet")
    ("Periwinkle") ("CadetBlue") ("CornflowerBlue") ("MidnightBlue")
    ("NavyBlue") ("RoyalBlue") ("Blue") ("Cerulean") ("Cyan") ("ProcessBlue")
    ("SkyBlue") ("Turquoise") ("TealBlue") ("Aquamarine") ("BlueGreen")
    ("Emerald") ("JungleGreen") ("SeaGreen") ("Green") ("ForestGreen")
    ("PineGreen") ("LimeGreen") ("YellowGreen") ("SpringGreen") ("OliveGreen")
    ("RawSienna") ("Sepia") ("Brown") ("Tan") ("Gray") ("Black") ("White"))
  "Colors defined in $TEXMF/tex/plain/colordvi.tex")

(defvar YaTeX:latex2e-basic-color-alist
  '(("black") ("white") ("red") ("blue") ("yellow") ("green") ("cyan")
    ("magenta"))
  "Basic colors")

(defun YaTeX:textcolor ()
  "Add-in for \\color's option"
  (if (y-or-n-p "Use `named' color? ")
      "[named]"))

(defun YaTeX::color-completing-read (prompt)
  (let ((completion-ignore-case t)
	(namedp (save-excursion
		  (skip-chars-backward "^\n\\[\\\\")
		  (looking-at "named"))))
    (completing-read
     prompt
     (if namedp
	 YaTeX:latex2e-named-color-alist
       YaTeX:latex2e-basic-color-alist)
     nil t)))

(defun YaTeX::textcolor (argp)
  "Add-in for \\color's argument"
  (cond
   ((= argp 1) (YaTeX::color-completing-read "Color: "))
   ((= argp 2) (read-string "Colored string: "))))

(fset 'YaTeX:color 'YaTeX:textcolor)
(fset 'YaTeX::color 'YaTeX::textcolor)
(fset 'YaTeX:colorbox 'YaTeX:textcolor)
(fset 'YaTeX::colorbox 'YaTeX::textcolor)
(fset 'YaTeX:fcolorbox 'YaTeX:textcolor)

(defun YaTeX::fcolorbox (argp)
  (cond
   ((= argp 1) (YaTeX::color-completing-read "Frame color: "))
   ((= argp 2) (YaTeX::color-completing-read "Inner color: "))
   ((= argp 3) (read-string "Colored string: "))))

(defun YaTeX:scalebox ()
  "Add-in for \\rotatebox"
  (let ((vmag (read-string (if YaTeX-japan "倍率: " "Magnification: ")))
	(hmag (read-string (if YaTeX-japan "横倍率(省略可): "
			     "Horizontal magnification(Optional): "))))
    (if (and hmag (string< "" hmag))
	(format "{%s}[%s]" vmag hmag)
      (format "{%s}" vmag))))

(defun YaTeX:includegraphics ()
  "Add-in for \\includegraphics's option"
  (let (width height (scale "") angle str)
    (setq width (read-string "Width: ")
	  height (read-string "Height: "))
    (or (string< width "") (string< "" height)
	(setq scale (read-string "Scale: ")))
    (setq angle (read-string "Angle(0-359): "))
    (setq str
	  (mapconcat
	   'concat
	   (delq nil
		 (mapcar '(lambda (s)
			    (and (stringp (symbol-value s))
				 (string< "" (symbol-value s))
				 (format "%s=%s" s (symbol-value s))))
			 '(width height scale angle)))
	   ","))
    (if (string= "" str) ""
      (concat "[" str "]"))))

(defun YaTeX::includegraphics (argp)
  "Add-in for \\includegraphics"
  (cond
   ((= argp 1)
    (read-file-name "EPS File: " ""))))
 
(defun YaTeX:caption ()
  (setq YaTeX-section-name "label")
  nil)

;;; -------------------- math-mode stuff --------------------
(defun YaTeX::tilde (&optional pos)
  "For accent macros in mathmode"
  (cond
   ((equal pos 1)
    (message "Put accent on variable: ")
    (let ((v (char-to-string (read-char))) (case-fold-search nil))
      (message "")
      (cond
       ((string-match "i\\|j" v)
	(concat "\\" v "math"))
       ((string-match "[\r\n\t ]" v)
	"")
       (t v))))
   (nil "")))

(fset 'YaTeX::hat	'YaTeX::tilde)
(fset 'YaTeX::check	'YaTeX::tilde)
(fset 'YaTeX::bar	'YaTeX::tilde)
(fset 'YaTeX::dot	'YaTeX::tilde)
(fset 'YaTeX::ddot	'YaTeX::tilde)
(fset 'YaTeX::vec	'YaTeX::tilde)

(defun YaTeX::widetilde (&optional pos)
  "For multichar accent macros in mathmode"
  (cond
   ((equal pos 1)
    (let ((m "Put over chars[%s ]: ") v v2)
      (message m " ")
      (setq v (char-to-string (read-char)))
      (message "")
      (if (string-match "[\r\n\t ]" v)
	  ""
	(message m v)
	(setq v2 (char-to-string (read-char)))
	(message "")
	(if (string-match "[\r\n\t ]" v2)
	    v
	  (concat v v2)))))
   (nil "")))

(fset 'YaTeX::widehat		'YaTeX::widetilde)
(fset 'YaTeX::overline		'YaTeX::widetilde)
(fset 'YaTeX::overrightarrow	'YaTeX::widetilde)
	

;;;
;; Add-in functions for large-type command.
;;;
(defun YaTeX:em ()
  (cond
   ((eq YaTeX-current-completion-type 'large) "\\/")
   (t nil)))
(fset 'YaTeX:it 'YaTeX:em)

;;; -------------------- End of yatexadd --------------------
(provide 'yatexadd)
; Local variables:
; fill-prefix: ";;; "
; paragraph-start: "^$\\|\\|;;;$"
; paragraph-separate: "^$\\|\\|;;;$"
; buffer-file-coding-system: sjis
; End:
