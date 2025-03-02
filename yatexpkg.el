;;; yatexpkg.el --- YaTeX package manager -*- coding: sjis -*-
;;; 
;;; (c)2003-2022 by HIROSE, Yuuji [yuuji@yatex.org]
;;; Last modified Sun Nov 24 20:43:19 2024 on firestorm
;;; $Id$

;;; Code:
(defvar YaTeX-package-ams-envs
  (mapcar 'car YaTeX-ams-env-table))

(defvar YaTeX-package-alist-default
  '(("version"	(env "comment")		;by tsuchiya<at>pine.kuee.kyoto-u.ac.jp
     		(section "includeversion" "excludeversion"))

    ("plext"	(section "bou"))	;by yas.axis<at>ma.mni.ne.jp

    ("url"	(section "url"))	;by fujieda<at>jaist.ac.jp

    ("fancybox"	(section "shadowbox" "doublebox" "ovalbox" "Ovalbox"))
    ("slashbox"	(section "slashbox" "backslashbox"))
    ("pifont"	(section "ding"))
    ("longtable" (env "longtable"))
    ("ascmac"	(env "screen" "boxnote" "shadebox" "itembox")
		(maketitle "return" "Return" "yen")
     		(section "keytop") ("mask") ("maskbox"))
    ("bm"	(section "bm"))		;by aoyama<at>le.chiba-u.ac.jp

    ("alltt"	(env "alltt"))
    ("misc"	(section "verbfile" "listing"))
    ("verbatim"	(section "verbatiminput"))
    ("moreverb"	(env "verbatimtab" "listing" "listingcont")
		(section "verbattabiminput" "listinginput"))
    ("boites"	(env "breakbox"))
    ;;("eclbkbox"	(env "breakbox"))
    ("supertabular" (env "supertabular"))
    ("tabularx" (env "tabularx"))
    ("amsmath"	(env . YaTeX-package-ams-envs)
     		(section "tag" "tag*"))
    ("amsart"	(same-as . "amsmath"))
    ("amsbook"	(same-as . "amsmath"))
    ("amsproc"	(same-as . "amsmath"))
    ("amssymb"	(maketitle "leqq" "geqq" "mathbb" "mathfrak"
			   "fallingdotseq" "therefore" "because"
			   "varDelta" "varTheta" "varLambda" "varXi" "varPi"
			   "varSigma" "varUpsilon" "varPhi" "varPsi" "varOmega"
			   "lll" "ggg")) ;very few.  Please tell us!
    ("latexsym"	(maketitle "mho" "Join" "Box" "Diamond" "leadsto"
			   "sqsubset" "sqsupset" "lhd" "unlhd" "rhd" "unrhd"))
    ("mathrsfs"	(section "mathscr"))
    ("fleqn"	(env "nccmath"))
    ("graphicx" (section "includegraphics"
			 "rotatebox" "scalebox" "resizebox" "reflectbox")
     		(option . YaTeX-package-graphics-driver-alist))
    ("xymtex"	(section "Ycyclohexaneh"))	;;XXX we need more and more...
    ("chemist"	nil)				;;XXX we need completions...
    ("a4j"	nil)
    ("array"	nil)
    ("times"	nil)
    ("newtx"	nil)
    ("makeidx"	nil)
    ("geometry"	(section "geometry"))
    ("lscape"	(env "landscape"))
    ("path"	(section "path"))
    ("epsf"	(section "epsfbox"))
    ("epsfig"	(section "epsfig"))
    ("floatflt"	(env "floatingfigure"))
    ("type1cm"	(section "fontsize"))
    ("svg"	(section "includesvg"))
    ("color"	(section "textcolor" "colorbox" "pagecolor" "color")
     		(option . YaTeX-package-graphics-driver-alist)
		(default-option . "usenames,dvipsnames"))
    ("xcolor"	(same-as . "color"))
    ("ulem"	(section "uline" "uuline" "uwave")
		(option ("normalem")))
    ("multicol"	(env "multicols"))
    ("cleveref"	(section "cref" "crefrange" "cpageref" "labelcref"
			 "labelpageref"))
    ("wrapfig"	(env "wrapfigure" "wraptable"))
    ("setspace"	(env "spacing") (section "setstretch"))
    ("cases"	(env "numcases" "subnumcases"))
    ("subfigure"	(section "subfigure"))
    ("okumacro"	(section "ruby" "kenten"))
    ("colortbl"	(section "columncolor" "rowcolor"))
    ("booktab"	(section "toprule" "midrule" "bottomrule" "cmidrule"
			 "addlinespace" "specialrule"))
    ("pxbase"	(section "UI"))
    ("hyperref"	(section "hyperref" "url" "nolinkurl" "href" "hyperref")
		(option "dvipdfmx" "luatex" "xetex" "hidelinks"))
    )
  "Default package vs. macro list.
Alists contains '(PACKAGENAME . MACROLIST)
PACKAGENAME     Basename of package(String).
MACROLIST	List of '(TYPE . MACROS)
TYPE	One of 'env, 'section or 'maketitle according to completion-type
MACROS	List of macros

If TYPE is 'option, its cdr is alist of completion candidates for that
package.  Its cdr can be a symbol whose value is alist.

An good example is the value of YaTeX-package-alist-default.")

(defvar YaTeX-package-graphics-driver-alist
  '(("dvips") ("dvipsnames") ("usenames")
    ("xdvi") ("dvipdfmx") ("pdftex") ("dvipsone") ("dviwindo")
    ("emtex") ("dviwin") ("oztex") ("textures") ("pctexps") ("pctexwin")
    ("pctexhp") ("pctex32") ("truetex") ("tcidvi") ("vtex"))
  "Drivers alist of graphics/color stylefile's supporting devices.
This list is taken from
%% graphics.dtx Copyright (C) 1994      David Carlisle Sebastian Rahtz
%%              Copyright (C) 1995 1996 1997 1998 David Carlisle
as of 2004/1/19.  Thanks.")

(defvar YaTeX-package-alist-private nil
  "*User defined package vs. macro list. See also YaTeX-package-alist-default")

(defun YaTeX-package-lookup (macro &optional type)
  "Look up a package which contains a definition of MACRO.
Optional second argument TYPE limits the macro type.
TYPE is a symbol, one of 'env, 'section, 'maketitle."
  (let ((list (append YaTeX-package-alist-private YaTeX-package-alist-default))
	origlist element x sameas val pkg pkglist r)
    (setq origlist list)
    (while list
      (setq element (car list)
	    pkg (car element)
	    element (cdr element))
      (if (setq sameas (assq 'same-as element)) ;non-recursive retrieval
	  (setq element (cdr (assoc (cdr sameas) origlist))))
      (if (setq r (catch 'found
		    (while element
		      (setq x (car element)
			    val (cdr x))
		      (if (symbolp val) (setq val (symbol-value val)))
		      (and (or (null type)
			       (eq type (car x)))
			   (YaTeX-member macro val)
			   (throw 'found (car x)))	;car x is type
		      (setq element (cdr element)))))
	  (setq pkglist (cons (cons pkg r) pkglist)))
      (setq list (cdr list)))
    pkglist))

(defun YaTeX-package-option-lookup (pkg &optional key)
  "Look up options for specified pkg and returne them in alist form.
Just only associng against the alist of YaTeX-package-alist-*"
  (let*((list (append YaTeX-package-alist-private YaTeX-package-alist-default))
	(l (cdr (assq (or key 'option) (assoc pkg list))))
	(recur (cdr (assq 'same-as (assoc pkg list)))))
    (cond
     (recur (YaTeX-package-option-lookup recur key))
     ((symbolp l) (symbol-value l))
     (t l))))

(defvar YaTeX-package-resolved-list nil
  "List of macros whose package is confirmed to be loaded.")

(defun YaTeX-package-auto-usepackage (macro type &optional autopkg autoopt)
  "(Semi)Automatically add the \\usepackage line to main-file.
Search the usepackage for MACRO of the TYPE.
Optional second and third argument AUTOPKG, AUTOOPT are selected
without query.  Thus those two argument (Full)automatically add
a \\usepackage line."
  (let ((cb (current-buffer))
	(wc (current-window-configuration))
	(usepackage (concat YaTeX-ec "usepackage"))
	(pkglist (YaTeX-package-lookup macro type))
	(usepkgrx (concat
		   YaTeX-ec-regexp
		   "\\(usepackage\\|include\\|documentclass\\)\\b"))
	(register (function
		   (lambda () (set-buffer cb)
		     (set (make-local-variable 'YaTeX-package-resolved-list)
			  (cons macro YaTeX-package-resolved-list)))))
	(begdoc (concat YaTeX-ec "begin{document}"))
	pb pkg optlist (option "") mb0 uspkgargs)
    (if (or (YaTeX-member macro YaTeX-package-resolved-list)
	    (null pkglist))
	nil				;nothing to do
      ;; Search `usepackage' into main-file
      (YaTeX-visit-main t)		;set buffer to parent file
      (setq pb (current-buffer))
      (save-excursion
	(save-restriction
	  (if (catch 'found
		(goto-char (point-min))
		(YaTeX-search-active-forward	;if search fails, goto eob
		 begdoc YaTeX-comment-prefix nil 1)
		(while (re-search-backward usepkgrx nil t)
		  ;;allow commented out \usepackages
		  (setq mb0 (match-beginning 0))
		  (skip-chars-forward "^{")
		  (setq uspkgargs (YaTeX-buffer-substring
				   (point)
				   (progn
				     ;;(forward-list 1) is more precise,
				     ;; but higher risk.
				     (skip-chars-forward "^}\n")(point))))
		  (let ((pl pkglist))
		    (while pl		;(car pl)'s car is package, cdr is type
		      (if (string-match
			   (concat "[{,]\\s *"
				   (regexp-quote (car (car pl)))
				   "\\>")
			   uspkgargs)
			  (throw 'found t))
		      (setq pl (cdr pl)))
		    (goto-char mb0))))
	      ;;corresponding \usepackage found
	      (funcall register)
	    ;; not found, insert it.
	    (if (or
		 autopkg
		 (y-or-n-p
		  (format "`%s' requires package. Put \\usepackage now?"
			  macro)))
		(progn
		  (require 'yatexadd)
		  (setq pkg
			(or autopkg
			    (completing-read
			     "Load which package?(TAB for list): "
			     pkglist nil nil
			     ;;initial input
			     (if (= (length pkglist) 1)
				 (let ((w (car (car pkglist))))
				   (if YaTeX-emacs-19 (cons w 0) w)))))
			optlist
			(YaTeX-package-option-lookup pkg))
		  (if optlist
		      (let ((minibuffer-completion-table optlist)
			    (delim ",") (w (car (car optlist)))
			    (dflt (YaTeX-package-option-lookup
				   pkg 'default-option)))
			(setq option
			      (or
			       autoopt
			       (read-from-minibuffer
				(format "Any option for {%s}?: " pkg)
				(let ((v (or dflt
					     (and (= (length optlist) 1) w))))
				  (and v (if YaTeX-emacs-19 (cons v 0) v)))
				YaTeX-minibuffer-completion-map))
			      option (if (string< "" option)
					 (concat "[" option "]")
				       ""))))
		  (set-buffer pb)
		  (goto-char (point-min))
		  (if (YaTeX-re-search-active-forward
		       (concat YaTeX-ec-regexp
			       "document\\(style\\|class\\){")
		       YaTeX-comment-prefix nil t)
		      (forward-line 1))
		  (if (YaTeX-search-active-forward
		       begdoc YaTeX-comment-prefix nil t)
		      (goto-char (match-beginning 0)))
		  (insert
		   usepackage
		   (format "%s{%s}\t%% required for `\\%s' (yatex added)\n"
			   option pkg macro))
		  (funcall register))
	      (funcall register)
	      (message "Don't forget to put \\usepackage{%s} yourself later"
		       (car (car pkglist)))) ;doing car car is negligence...
	    ))))))

(defvar YaTeX::usepackage-alist-private nil
  "*Private completion list of the argument for usepackage")

(defvar YaTeX::usepackage-alist-local nil
  "Directory local  completion list of the argument for usepackage")

(defun YaTeX::usepackage (&optional argp)
  (cond
   ((equal argp 1)
    (setq YaTeX-env-name "document")
    (let ((minibuffer-local-completion-map YaTeX-minibuffer-completion-map)
	  (delim ","))
      (YaTeX-cplread-with-learning
       (if YaTeX-japan "Use package(カンマで区切ってOK): "
	 "Use package(delimitable by comma): ")
       ;; 'YaTeX::usepackage-alist-default	;; OBSOLETED at 1.82
       'YaTeX-package-alist-default
       'YaTeX::usepackage-alist-private
       'YaTeX::usepackage-alist-local)))))


;;;
;; Add-ins for auxiliary package handled here
;;;
(defun YaTeX:floatingfigure ()
  (concat (YaTeX:read-position "rlpv")
	  (YaTeX:read-length "Width: ")))

(defvar YaTeX:geometry-default "margin=1.5cm,includeheadfoot,includemp"
  "*Default options for \\geometry{}")
(defun YaTeX::geometry (argp)
  "Add-in for \\geometry's option"
  ;; cf. https://dayinthelife.at.webry.info/201401/article_2.html
  (cond
   ((= argp 1)
    (YaTeX-help "geometry")
    (message "Change default by setting YaTeX:geometry-default")
    (if (string= YaTeX:geometry-default "") ""
      YaTeX:geometry-default))))

(provide 'yatexpkg)
