;;; yatexprc.el --- YaTeX process handler -*- coding: sjis -*-
;;; 
;;; (c)1993-2017 by HIROSE Yuuji.[yuuji@yatex.org]
;;; Last modified Tue Jan  2 23:31:34 2018 on firestorm
;;; $Id$

;;; Code:
;(require 'yatex)
(require 'yatexlib)

(defvar YaTeX-typeset-process nil
  "Process identifier for latex")

(defvar YaTeX-typeset-buffer "*YaTeX-typesetting*"
  "Process buffer for latex")

(defvar YaTeX-typeset-buffer-syntax nil
  "*Syntax table for typesetting buffer")

(defvar YaTeX-current-TeX-buffer nil
  "Keeps the buffer on which recently typeset run.")

(defvar YaTeX-shell-command-option
  (or (and (boundp 'shell-command-option) shell-command-option)
      (and (boundp 'shell-command-switch) shell-command-switch)
      (if YaTeX-dos "/c" "-c"))
  "Shell option for command execution.")

(defvar YaTeX-latex-message-code
;;   (cond
;;    (YaTeX-dos (cdr (assq 1 YaTeX-kanji-code-alist)))
;;    ((and YaTeX-emacs-20 (member 'undecided (coding-system-list))
;; 	 'undecided))
;;    ((featurep 'mule)
;;     (or (and (boundp '*autoconv*) *autoconv*)
;; 	(and (fboundp 'coding-system-list) 'automatic-conversion)))
;;    ((boundp 'NEMACS)
;;     (cdr (assq (if YaTeX-dos 1 2) YaTeX-kanji-code-alist))))
  (cond
   (YaTeX-dos (cdr (assq 1 YaTeX-kanji-code-alist)))
   (YaTeX-emacs-20
    (cdr (assoc latex-message-kanji-code YaTeX-kanji-code-alist)))
   ((boundp 'MULE)
    (symbol-value
     (cdr (assoc latex-message-kanji-code YaTeX-kanji-code-alist))))
   ((boundp 'NEMACS)
    latex-message-kanji-code))
  "Process coding system for LaTeX.")

(if YaTeX-typeset-buffer-syntax nil
  (setq YaTeX-typeset-buffer-syntax
	(make-syntax-table (standard-syntax-table)))
  (modify-syntax-entry ?\{ "w" YaTeX-typeset-buffer-syntax)
  (modify-syntax-entry ?\} "w" YaTeX-typeset-buffer-syntax)
  (modify-syntax-entry ?\[ "w" YaTeX-typeset-buffer-syntax)
  (modify-syntax-entry ?\] "w" YaTeX-typeset-buffer-syntax))

(defvar YaTeX-typeset-marker nil)
(defvar YaTeX-typeset-consumption nil)
(make-variable-buffer-local 'YaTeX-typeset-consumption)
(defun YaTeX-typeset (command buffer &optional prcname modename ppcmd)
  "Execute latex command (or other) to LaTeX typeset."
  (interactive)
  (save-excursion
    (let ((p (point)) (window (selected-window)) execdir (cb (current-buffer))
	  (map YaTeX-typesetting-mode-map)
	  (background (string-match "\\*bg:" buffer))
	  (outcode
	   (cond ((eq major-mode 'yatex-mode) YaTeX-coding-system)
		 ((eq major-mode 'yahtml-mode) yahtml-kanji-code))))
      (if (and YaTeX-typeset-process
	       (eq (process-status YaTeX-typeset-process) 'run))
	  ;; if tex command is halting.
	  (YaTeX-kill-typeset-process YaTeX-typeset-process))
      (YaTeX-put-nonstopmode)
      (setq prcname (or prcname "LaTeX")
	    modename (or modename "typeset"))
      (if (eq major-mode 'yatex-mode) (YaTeX-visit-main t)) ;;execution dir
      (setq execdir default-directory)
      ;;Select lower-most window if there are more than 2 windows and
      ;;typeset buffer not seen.
      (if background
	  nil				;do not showup
	(YaTeX-showup-buffer
	 buffer 'YaTeX-showup-buffer-bottom-most))
      (set-buffer (get-buffer-create buffer))
      (setq default-directory execdir)
      (cd execdir)
      (erase-buffer)
      (cond
       ((not (fboundp 'start-process)) ;YaTeX-dos;if MS-DOS
	(call-process
	 shell-file-name nil buffer nil YaTeX-shell-command-option command))
       (t				;if UNIX
	(set-process-buffer
	 (setq YaTeX-typeset-process
	       (start-process prcname buffer shell-file-name
			      YaTeX-shell-command-option command))
	 (get-buffer buffer))
	(set-process-sentinel YaTeX-typeset-process 'YaTeX-typeset-sentinel)
	(put 'YaTeX-typeset-process 'thiscmd command)
	(put 'YaTeX-typeset-process 'name prcname)
	(if (fboundp 'current-time)
	    (setq YaTeX-typeset-consumption
		  (cons (cons 'time (current-time))
			(delq 'time YaTeX-typeset-consumption))))
	(let ((ppprop (get 'YaTeX-typeset-process 'ppcmd)))
	  (setq ppprop (delq (assq YaTeX-typeset-process ppprop) ppprop))
	  (if ppcmd
	      (setq ppprop (cons (cons YaTeX-typeset-process ppcmd) ppprop)))
	  (put 'YaTeX-typeset-process 'ppcmd ppprop))
	(if (and (boundp 'bibcmd) bibcmd)
	    (let ((bcprop (get 'YaTeX-typeset-process 'bibcmd)))
	      (setq bcprop (cons
			    (cons YaTeX-typeset-process bibcmd)
			    (delq (assq YaTeX-typeset-process bcprop) bcprop)))
	      (put 'YaTeX-typeset-process 'bibcmd bcprop)))))
      (message (format "Calling `%s'..." command))
      (setq YaTeX-current-TeX-buffer (buffer-name))
      (use-local-map map)		;map may be localized
      (set-syntax-table YaTeX-typeset-buffer-syntax)
      (setq mode-name modename)
      (if YaTeX-typeset-process		;if process is running (maybe on UNIX)
	  (cond ((fboundp 'set-current-process-coding-system)
		 (set-current-process-coding-system
		  YaTeX-latex-message-code outcode))
		((fboundp 'set-process-coding-system)
		 (set-process-coding-system
		  YaTeX-typeset-process YaTeX-latex-message-code outcode))
		(YaTeX-emacs-20
		 (set-buffer-process-coding-system
		  YaTeX-latex-message-code outcode))
		((boundp 'NEMACS)
		 (set-kanji-process-code YaTeX-latex-message-code))))
      (set-marker (or YaTeX-typeset-marker
		      (setq YaTeX-typeset-marker (make-marker)))
		  (point))
      (insert (format "Call `%s'\n" command))
      (cond
       ((fboundp 'start-process)
	(insert " ")
	(set-marker (process-mark YaTeX-typeset-process) (1- (point))))
       (t (message "Done.")))
      (if (bolp) (forward-line -1))	;what for?
      (cond
       (background nil)
       ((and YaTeX-emacs-19 window-system)
	(let ((win (get-buffer-window buffer t)) owin)
	  (select-frame (window-frame win))
	  (setq owin (selected-window))
	  (select-window win)
	  (goto-char (point-max))
	  (recenter -1)
	    (select-window owin)))
       (t (select-window (get-buffer-window buffer))
	  (goto-char (point-max))
	  (recenter -1)))
      (select-window window)
      (switch-to-buffer cb)
      (YaTeX-remove-nonstopmode))))

(defvar YaTeX-typeset-auto-rerun t
  "*Non-nil automatically reruns typesetter when cross-refs update found.
This is a toy mechanism.  DO NOT RELY ON THIS MECHANISM.
You SHOULD check the integrity of cross-references with your eyes!!
Supplying an integer to this variable inhibit compulsory call of bibtex,
thus, it call bibtex only if warning messages about citation are seen.")
(defvar YaTeX-typeset-rerun-msg "Rerun to get cross-references right.")
(defvar YaTeX-typeset-citation-msg
  "Warning: Citation \`")
(defun YaTeX-typeset-sentinel (proc mes)
  (cond ((null (buffer-name (process-buffer proc)))
         ;; buffer killed
         (set-process-buffer proc nil))
        ((memq (process-status proc) '(signal exit))
         (let* ((obuf (current-buffer)) (pbuf (process-buffer proc))
		(pwin (get-buffer-window pbuf))
		(owin (selected-window)) win
		tobecalled shortname
		(thiscmd (get 'YaTeX-typeset-process 'thiscmd))
		(ppprop (get 'YaTeX-typeset-process 'ppcmd))
		(ppcmd (cdr (assq proc ppprop)))
		(bcprop (get 'YaTeX-typeset-process 'bibcmd))
		(bibcmd (cdr (assq proc bcprop))))
	   (put 'YaTeX-typeset-process 'ppcmd ;erase ppcmd
		(delq (assq proc ppprop) ppprop))
	   (put 'YaTeX-typeset-process 'bibcmd ;erase bibcmd
		(delq (assq proc bcprop) bcprop))
           ;; save-excursion isn't the right thing if
           ;;  process-buffer is current-buffer
           (unwind-protect
               (progn
                 ;; Write something in *typesetting* and hack its mode line
		 (if pwin
		     (select-window pwin)
		   (set-buffer pbuf))
		 ;;(YaTeX-showup-buffer pbuf nil t)
                 (goto-char (point-max))
		 (if pwin (recenter -3))
                 (insert ?\n mode-name " " mes)
                 (forward-char -1)
                 (insert
		  (format " at %s%s\n"
			  (substring (current-time-string) 0 -5)
			  (if (and (fboundp 'current-time) (fboundp 'float)
				   (assq 'time YaTeX-typeset-consumption))
			      (format
			       " (%.2f secs)"
			       (YaTeX-elapsed-time
				(cdr (assq 'time YaTeX-typeset-consumption))
				(current-time))))))
                 (setq mode-line-process
                       (concat ": "
                               (symbol-name (process-status proc))))
		 (message "%s %s" mode-name
			  (if (eq (process-status proc) 'exit)
			      "done" "ceased"))
                 ;; If buffer and mode line shows that the process
                 ;; is dead, we can delete it now.  Otherwise it
                 ;; will stay around until M-x list-processes.
                 (delete-process proc)
		 (if (cond
		      ((or (not YaTeX-typeset-auto-rerun)
			   (string-match "latexmk" thiscmd))
		       nil)
		      ((and bibcmd     ;Call bibtex if bibcmd defined &&
			    (or	       ;  (1st call  || warning found)
			     (and (not (numberp YaTeX-typeset-auto-rerun))
				  ; cancel call at 1st, if value is a number.
				  (not (string-match "bibtex" mode-name)))
			     (re-search-backward
			      YaTeX-typeset-citation-msg
			      YaTeX-typeset-marker t))
			    (save-excursion ; && using .bbl files.
			      (search-backward
			       ".bbl" YaTeX-typeset-marker t)))
		       ;; Always call bibtex after the first typesetting,
		       ;; because bibtex doesn't warn disappeared \cite.
		       ;; (Suggested by ryseto. 2012)
		       ;; It is more efficient to call bibtex directly than
		       ;; to call it after deep inspection on the balance
		       ;; of \cite vs. \bib*'s referring all *.aux files.
		       (insert "\n" YaTeX-typeset-rerun-msg "\n")
		       (setq tobecalled bibcmd shortname "+bibtex"))
		      ((or
			(save-excursion
			  (search-backward
			   YaTeX-typeset-rerun-msg YaTeX-typeset-marker t))
			(save-excursion
			  (re-search-backward
			   "natbib.*Rerun to get citations correct"
			   YaTeX-typeset-marker t)))
		       (if bibcmd
			   (put 'YaTeX-typeset-process 'bibcmd
				(cons (cons (get-buffer-process pbuf) bibcmd)
				      bcprop)))
		       (setq tobecalled thiscmd shortname "+typeset"))
		      (t
		       nil))			  ;no need to call any process
		     (progn ;;Something occurs to call next command
		       (insert
			(format
			 "===!!! %s !!!===\n"
			 (message "Rerun `%s' to get cross-references right"
				  tobecalled)))
		       (if (equal tobecalled thiscmd)
			   (set-marker YaTeX-typeset-marker (point)))
		       (set-process-sentinel
			(start-process
			 (setq mode-name (concat mode-name shortname))
			 pbuf
			 shell-file-name YaTeX-shell-command-option tobecalled)
			'YaTeX-typeset-sentinel)
		       (if ppcmd
			   (put 'YaTeX-typeset-process 'ppcmd
				(cons (cons (get-buffer-process pbuf) ppcmd)
				      ppprop)))
		       (if thiscmd
			   (put 'YaTeX-typeset-process 'thiscmd thiscmd)))
		   ;; If ppcmd is active, call it.
		   (cond
		    ((and ppcmd (symbolp ppcmd) (fboundp ppcmd))
		     ;; If ppcmd is set and it is a function symbol,
		     ;; call it whenever command succeeded or not
		     (funcall ppcmd))
		    ((and ppcmd (string-match "finish" mes))
		     (insert (format "=======> Success! Calling %s\n" ppcmd))
		     (setq mode-name	; set process name
			   (concat
			    mode-name "+"
			    (substring ppcmd 0 (string-match " " ppcmd))))
					; to reach here, 'start-process exists on this emacsen
		     (set-process-sentinel
		      (start-process
		       mode-name
		       pbuf		; Use this buffer twice.
		       shell-file-name YaTeX-shell-command-option
		       ppcmd)
		      'YaTeX-typeset-sentinel))
		    (t 
		     (if (equal 0 (process-exit-status proc))
			 ;; Successful typesetting done
			 (if (save-excursion
			       (re-search-backward
				(concat
				 "^Output written on .*\\.pdf (.*page,"
				 "\\|\\.dvi -> .*\\.pdf$")
				nil t))
			     ;; If PDF output log found in buffer,
			     ;; set next default previewer to 'pdf viewer
			     (put 'dvi2-command 'format 'pdf))
		       ;;Confirm process buffer to be shown when error
		       (YaTeX-showup-buffer
			pbuf 'YaTeX-showup-buffer-bottom-most)
		       (message "Command FAILED!"))
		     ;;pull back original mode-name
		     (setq mode-name "typeset"))))
		 (forward-char 1))
	     (setq YaTeX-typeset-process nil)
             ;; Force mode line redisplay soon
             (set-buffer-modified-p (buffer-modified-p))
	     )
	   (select-window owin)
	   (set-buffer obuf)))))

(defvar YaTeX-texput-file "texput.tex"
  "*File name for temporary file of typeset-region.")

(defun YaTeX-typeset-region (&optional pp)
  "Paste the region to the file `texput.tex' and execute typesetter.
The region is specified by the rule:
	(1)If keyword `%#BEGIN' is found in the upper direction from (point).
	  (1-1)if the keyword `%#END' is found after `%#BEGIN',
		->Assume the text between `%#BEGIN' and `%#END' as region.
	  (1-2)if the keyword `%#END' is not found anywhere after `%#BEGIN',
		->Assume the text after `%#BEGIN' as region.
	(2)If no `%#BEGIN' usage is found before the (point),
		->Assume the text between current (point) and (mark) as region.
DON'T forget to eliminate the `%#BEGIN/%#END' notation after editing
operation to the region.
Optional second argument PP specifies post-processor command which will be
called with one argument of current file name whitout extension."
  (interactive)
  (save-excursion
    (let*
	((end "") typeout ;Type out message that tells the method of cutting.
	 (texput YaTeX-texput-file)
	 (texputroot (substring texput 0 (string-match "\\.tex$" texput)))
	 (cmd (concat (YaTeX-get-latex-command nil) " " texput))
	 (buffer (current-buffer)) opoint preamble (subpreamble "") main
	 (hilit-auto-highlight nil)	;for Emacs19 with hilit19
	 ppcmd
	 reg-begin reg-end lineinfo)
      (setq ppcmd (if (stringp pp) (concat pp " " texputroot) pp))
      (save-excursion
	(if (search-backward "%#BEGIN" nil t)
	    (progn
	      (setq typeout "--- Region from BEGIN to "
		    end "the end of the buffer ---"
		    reg-begin (match-end 0))
	      (if (search-forward "%#END" nil t)
		  (setq reg-end (match-beginning 0)
			end "END ---")
		(setq reg-end (point-max))))
	  (setq typeout "=== Region from (point) to (mark) ==="
		reg-begin (point) reg-end (mark)))
	(goto-char (min reg-begin reg-end))
	(setq lineinfo (count-lines (point-min) (point-end-of-line)))
	(goto-char (point-min))
	(while (search-forward "%#REQUIRE" nil t)
	  (setq subpreamble
		(concat subpreamble
			(cond
			 ((eolp)
			  (buffer-substring
			   (match-beginning 0)
			   (point-beginning-of-line)))
			 (t (buffer-substring
			     (match-end 0)
			     (point-end-of-line))))
			"\n"))
	  (goto-char (match-end 0))))
      (YaTeX-visit-main t)
      (setq main (current-buffer))
      (setq opoint (point))
      (goto-char (point-min))
      (setq
       preamble
       (if (re-search-forward "^[ 	]*\\\\begin.*{document}" nil t)
	   (buffer-substring (point-min) (match-end 0))
	 (concat
	  (if YaTeX-use-LaTeX2e "\\documentclass{" "\\documentstyle{")
	  YaTeX-default-document-style "}\n"
	  "\\begin{document}")))
      (goto-char opoint)
      ;;(set-buffer buffer)		;for clarity
      (let ((hilit-auto-highlight nil) (auto-mode-alist nil)
	    (magic-mode-alist nil))	;Do not activate yatex-mode here
	(set-buffer (find-file-noselect texput)))
      ;;(find-file YaTeX-texput-file)
      (erase-buffer)
      (YaTeX-set-file-coding-system YaTeX-kanji-code YaTeX-coding-system)
      (if (and (eq major-mode 'yatex-mode) YaTeX-need-nonstop)
	  (insert "\\nonstopmode{}\n"))
      (insert preamble "\n" subpreamble "\n"
	      "\\pagestyle{empty}\n\\thispagestyle{empty}\n")
      (setq lineinfo (list (count-lines 1 (point-end-of-line)) lineinfo))
      (insert-buffer-substring buffer reg-begin reg-end)
      (insert "\\typeout{" typeout end "}\n") ;Notice the selected method.
      (insert "\n\\end{document}\n")
      (basic-save-buffer)
      (kill-buffer (current-buffer))
      (set-buffer main)		;return to parent file or itself.
      (YaTeX-typeset cmd YaTeX-typeset-buffer nil nil ppcmd)
      (switch-to-buffer buffer)		;for Emacs-19
      (put 'dvi2-command 'region t)
      (put 'dvi2-command 'file buffer)
      (put 'dvi2-command 'offset lineinfo))))

(defvar YaTeX-use-image-preview "png"
  "*Nil means not using image preview by [prefix] t e.
Acceptable value is one of \"jpg\" or \"png\", which specifies
format of preview image.  NOTE that if your system has /usr/bin/sips
while not having convert(ImageMagick), jpeg format is automatically taken
for conversion.")
(defvar YaTeX-preview-image-mode-map nil
  "Keymap used in YaTeX-preview-image-mode")
(defun YaTeX-preview-image-mode ()
  (interactive)
  (if YaTeX-preview-image-mode-map
      nil
    (let ((map (setq YaTeX-preview-image-mode-map (make-sparse-keymap))))
      (define-key map "q" (lambda()(interactive)
			    (kill-buffer)
			    (select-window
			     (or (get 'YaTeX-typeset-process 'win)
				 (selected-window)))))
      (define-key map "j" (lambda()(interactive) (scroll-up 1)))
      (define-key map "k" (lambda()(interactive) (scroll-up -1)))))
  (use-local-map YaTeX-preview-image-mode-map))

(defvar YaTeX-typeset-pdf2image-chain
  (cond
   ((YaTeX-executable-find "pdfcrop")	;Mac OS X
    (list
     "pdfcrop --clip %b.pdf tmp.pdf"
     (if (YaTeX-executable-find "convert")
	 "convert -density %d tmp.pdf %b.%f"
       ;; If we use sips, specify jpeg as format
       "sips -s format jpeg -s dpiWidth %d -s dpiHeight %d %b.pdf --out %b.jpg")
     "rm -f tmp.pdf")))
  "*Pipe line of command as a list to create image file from PDF.
See also doc-string of YaTeX-typeset-dvi2image-chain.")

(defvar YaTeX-typeset-dvi2image-chain
  (cond
   ((YaTeX-executable-find YaTeX-cmd-dvips)
    (list
     (format "%s -E -o %%b.eps %%b.dvi" YaTeX-cmd-dvips)
     "convert -alpha off -density %d %b.eps %b.%f"))
   ((and (equal YaTeX-use-image-preview "png")
	 (YaTeX-executable-find "dvipng"))
    (list "dvipng %b.dvi")))
  "*Pipe line of command as a list to create png file from DVI or PDF.
%-notation rewritten list:
 %b	basename of target file(\"texput\")
 %f	Output format(\"png\")
 %d	DPI
")

(defvar YaTeX-typeset-conv2image-chain-alist
  (list (cons 'pdf YaTeX-typeset-pdf2image-chain)
	(cons 'dvi YaTeX-typeset-dvi2image-chain))
  "Default alist for creating image files from DVI/PDF.
The value is generated from YaTeX-typeset-pdf2image-chain and
YaTeX-typeset-dvi2image-chain.")

(defvar YaTeX-typeset-conv2image-process nil "Process of conv2image chain")
(defun YaTeX-typeset-conv2image-chain ()
  (let*((proc (or YaTeX-typeset-process YaTeX-typeset-conv2image-process))
	(prevname (process-name proc))
	(texput "texput")
	(format YaTeX-use-image-preview)
	(target (concat texput "." format))
	(math (get 'YaTeX-typeset-conv2image-chain 'math))
	(dpi  (get 'YaTeX-typeset-conv2image-chain 'dpi))
	(srctype (or (get 'YaTeX-typeset-conv2image-chain 'srctype)
		     (if (file-newer-than-file-p
			  (concat texput ".pdf")
			  (concat texput ".dvi"))
			 'pdf 'dvi)))
	(chain (cdr (assq srctype YaTeX-typeset-conv2image-chain-alist)))
	;; This function is the first evaluation code.
	;; If you find these command line does not work
	;; on your system, please tell the author
	;; which commands should be taken to achieve
	;; one-shot png previewing on your system
	;; before publishing patch on the Web.
	;; Please please please please please.
	(curproc (member prevname chain))
	(w (get 'YaTeX-typeset-conv2image-chain 'win))
	(pwd default-directory)
	img)
    (if (not (= (process-exit-status proc) 0))
	(progn
	  (YaTeX-showup-buffer		;never comes here(?)
	   (current-buffer) 'YaTeX-showup-buffer-bottom-most)
	  (message "Region typesetting FAILED"))
      (setq command
	    (if curproc (car (cdr-safe curproc)) (car chain)))
      (if command
	  (let ((cmdline (YaTeX-replace-formats
			  command
			  (list (cons "b" "texput")
				(cons "f" format)
				(cons "d" dpi)))))
	    (insert (format "Calling `%s'...\n" cmdline))
	    (set-process-sentinel
	     (setq YaTeX-typeset-conv2image-process
		   (start-process
		    command
		    (current-buffer)
		    shell-file-name YaTeX-shell-command-option
		    cmdline))
	     'YaTeX-typeset-sentinel)
	    (put 'YaTeX-typeset-process 'ppcmd
		 (cons (cons (get-buffer-process (current-buffer))
			     'YaTeX-typeset-conv2image-chain)
		       (get 'YaTeX-typeset-process 'ppcmd))))
	;; After all chain executed, display image in current window
	(cond
	 ((and (featurep 'image) window-system)
	  ;; If direct image displaying available in running Emacs,
	  ;; display target image into the next window in Emacs.
	  (select-window w)
	  ;(setq foo (selected-window))
	  (YaTeX-showup-buffer
	   (get-buffer-create " *YaTeX-region-image*")
	   'YaTeX-showup-buffer-bottom-most t)
	  (remove-images (point-min) (point-max))
	  (erase-buffer)
	  (cd pwd)			;when reuse from other source
					;(put-image (create-image (expand-file-name target)) (point))
	  (insert-image-file target)
	  (setq img (plist-get (text-properties-at (point)) 'intangible))
	  (YaTeX-preview-image-mode)
	  (if img
	      (let ((height (1+ (cdr (image-size img)))))
		(enlarge-window
		 (- (ceiling (min height (/ (frame-height) 2)))
		    (window-height)))))
	  ;; Remember elapsed time, which will be threshold in onthefly-preview
	  (put 'YaTeX-typeset-conv2image-chain 'elapse
	       (YaTeX-elapsed-time
		(get 'YaTeX-typeset-conv2image-chain 'start) (current-time))))
	 (t
	  ;; Without direct image, display image with image viewer
	  (YaTeX-system
	   (format "%s %s" YaTeX-cmd-view-images target)
	   "YaTeX-region-image"
	   'noask)
	  )
	 )))))


(defvar YaTeX-typeset-environment-timer nil)
(defun YaTeX-typeset-environment-timer ()
  "Update preview image in the 
Plist: '(buf begPoint endPoint precedingChar 2precedingChar Substring time)"
  (let*((plist (get 'YaTeX-typeset-environment-timer 'laststate))
	(b (nth 0 plist))
	(s (nth 1 plist))
	(e (nth 2 plist))
	(p (nth 3 plist))
	(q (nth 4 plist))
	(st (nth 5 plist))
	(tm (nth 6 plist))
	(overlay YaTeX-on-the-fly-overlay)
	(thresh (* 2 (or (get 'YaTeX-typeset-conv2image-chain 'elapse) 1))))
    (cond
     ;; In minibuffer, do nothing
     ((minibuffer-window-active-p (selected-window)) nil)
     ;; If point went out from last environment, cancel timer
     ;;;((and (message "s=%d, e=%d, p=%d" s e (point)) nil))
     ((null (buffer-file-name)) nil) ;;At momentary-string-display, it's nil.
     ((or (not (eq b (window-buffer (selected-window))))
	  (< (point) s)
	  (not (overlayp overlay))
	  (not (eq (overlay-buffer overlay) (current-buffer)))
	  (> (point) (overlay-end overlay)))
      (YaTeX-typeset-environment-cancel-auto))
     ;;;((and (message "e=%d, p=%d t=%s" e (point) (current-time)) nil))
     ;; If recently called, hold
     ;;; ((< (YaTeX-elapsed-time tm (current-time)) thresh) nil)
     ;; If condition changed from last call, do it
     ((not (string= st (YaTeX-buffer-substring s (overlay-end overlay))))
      (YaTeX-typeset-environment)))))


(defun YaTeX-typeset-environment-by-lmp ()
  (save-excursion
    (let ((sw (selected-window)))
      (goto-char opoint)
      (latex-math-preview-expression)
      (select-window sw))))

(defun YaTeX-typeset-environment-by-builtin ()
  (save-excursion
    (YaTeX-typeset-region 'YaTeX-typeset-conv2image-chain)))

(defvar YaTeX-on-the-fly-math-preview-engine
  (if (fboundp 'latex-math-preview-expression)
      'YaTeX-typeset-environment-by-lmp
    'YaTeX-typeset-environment-by-builtin)
  "Function symbol to use math-preview.
'YaTeX-typeset-environment-by-lmp for using latex-math-preview,
'YaTeX-typeset-environment-by-builtin for using yatex-builtin.")

(defun YaTeX-typeset-environment-1 ()
  (require 'yatex23)
  (let*((math (YaTeX-in-math-mode-p))
	(dpi (or (YaTeX-get-builtin "IMAGEDPI") (if math "300" "200")))
	(opoint (point))
	usetimer)
    (cond
     ((and YaTeX-on-the-fly-overlay (overlayp YaTeX-on-the-fly-overlay)
	   (member YaTeX-on-the-fly-overlay (overlays-at (point))))
      ;; If current position is in on-the-fly overlay,
      ;; use that region again
      (setq math (get 'YaTeX-typeset-conv2image-chain 'math))
      (push-mark (overlay-start YaTeX-on-the-fly-overlay))
      (goto-char (overlay-end YaTeX-on-the-fly-overlay)))
     ((YaTeX-region-active-p)
      nil)				;if region is active, use it
     (math (setq usetimer t) (YaTeX-mark-environment))
     ((equal (or (YaTeX-inner-environment t) "document") "document")
      (mark-paragraph))
     (t (setq usetimer t) (YaTeX-mark-environment)))
    (if YaTeX-use-image-preview
	(let ((YaTeX-typeset-buffer (concat "*bg:" YaTeX-typeset-buffer))
	      (b (region-beginning)) (e (region-end)))
	  (put 'YaTeX-typeset-conv2image-chain 'math math)
	  (put 'YaTeX-typeset-conv2image-chain 'dpi dpi)
	  (put 'YaTeX-typeset-conv2image-chain 'srctype nil)
	  (put 'YaTeX-typeset-conv2image-chain 'win (selected-window))
	  (put 'YaTeX-typeset-conv2image-chain 'start (current-time))
	  (put 'YaTeX-typeset-environment-timer 'laststate
	       (list (current-buffer) b e (preceding-char)
		     (char-after (- (point) 2))
		     (YaTeX-buffer-substring b e)
		     (current-time)))
	  (if math (funcall YaTeX-on-the-fly-math-preview-engine)
	    (YaTeX-typeset-region 'YaTeX-typeset-conv2image-chain))
	  (if usetimer (YaTeX-typeset-environment-auto b e)))
      (YaTeX-typeset-region))))

(defun YaTeX-typeset-environment ()
  "Typeset current environment or paragraph.
If region activated, use it."
  (interactive)
  (let ((md (match-data)))
    (unwind-protect
	(save-excursion
	  (YaTeX-typeset-environment-1))
      (store-match-data md))))


(defvar YaTeX-on-the-fly-preview-interval (string-to-number "0.9")
  "*Control the on-the-fly update of preview environment by an image.
Nil disables on-the-fly update.  Otherwise on-the-fly update is enabled
with update interval specified by this value.")

(defun YaTeX-typeset-environment-auto (beg end)
  "Turn on on-the-fly preview-image"
  (if YaTeX-typeset-environment-timer
      (cancel-timer YaTeX-typeset-environment-timer))
  (if YaTeX-on-the-fly-overlay
      (move-overlay YaTeX-on-the-fly-overlay beg end)
    (overlay-put
     (setq YaTeX-on-the-fly-overlay (make-overlay beg end))
     'face 'YaTeX-on-the-fly-activated-face))
  (setq YaTeX-typeset-environment-timer
	(run-with-idle-timer
	 (max (string-to-number "0.1")
	      (cond
	       ((numberp YaTeX-on-the-fly-preview-interval) 
		YaTeX-on-the-fly-preview-interval)
	       ((stringp YaTeX-on-the-fly-preview-interval)
		(string-to-number YaTeX-on-the-fly-preview-interval))
	       (t 1)))
	 t 'YaTeX-typeset-environment-timer)))

(defun YaTeX-typeset-environment-activate-onthefly ()
  (if (get-text-property (point) 'onthefly)
      (save-excursion
	(if YaTeX-typeset-environment-timer
	    (progn
	      (cancel-timer YaTeX-typeset-environment-timer)
	      (setq YaTeX-typeset-environment-timer nil)))
	(if (YaTeX-on-begin-end-p)
	    (if (or (match-beginning 1) (match-beginning 3)) ;on beginning
		(goto-char (match-end 0))
	      (goto-char (match-beginning 0))))
	(YaTeX-typeset-environment))))

(defun YaTeX-on-the-fly-cancel ()
  "Reset on-the-fly stickiness"
  (interactive)
  (YaTeX-typeset-environment-cancel-auto 'stripoff)
  t)					;t for kill-*
  
(defun YaTeX-typeset-environment-cancel-auto (&optional stripoff)
  "Cancel typeset-environment timer."
  (interactive)
  (if YaTeX-typeset-environment-timer
      (cancel-timer YaTeX-typeset-environment-timer))
  (setq YaTeX-typeset-environment-timer
	(run-with-idle-timer
	 (string-to-number "0.1")
	 t
	 'YaTeX-typeset-environment-activate-onthefly))
  (let ((ov YaTeX-on-the-fly-overlay))
    (if stripoff
	(remove-text-properties (overlay-start ov)
				(1- (overlay-end ov))
				'(onthefly))
      (put-text-property (overlay-start YaTeX-on-the-fly-overlay)
			 (1- (overlay-end YaTeX-on-the-fly-overlay))
			 'onthefly
			 t))
    (delete-overlay ov)
    (message "On-the-fly preview deactivated")))

(defun YaTeX-typeset-buffer (&optional pp)
  "Typeset whole buffer.
If %#! usage says other buffer is main text,
visit main buffer to confirm if its includeonly list contains current
buffer's file.  And if it doesn't contain editing text, ask user which
action wants to be done, A:Add list, R:Replace list, %:comment-out list.
If optional argument PP given as string, PP is considered as post-process
command and call it with the same command argument as typesetter without
last extension.
eg. if PP is \"dvipdfmx\", called commands as follows.
  platex foo.tex
  dvipdfmx foo
PP command will be called iff typeset command exit successfully"
  (interactive)
  (YaTeX-save-buffers)
  (let*((me (substring (buffer-name) 0 (rindex (buffer-name) ?.)))
	(mydir (file-name-directory (buffer-file-name)))
	(cmd (YaTeX-get-latex-command t)) pparg ppcmd bibcmd
	(cb (current-buffer)))
    (setq pparg (substring cmd 0 (string-match "[;&]" cmd)) ;rm multistmt
	  pparg (substring pparg (rindex pparg ? ))	 ;get last arg
	  pparg (substring pparg 0 (rindex pparg ?.))	 ;rm ext
	  bibcmd (YaTeX-replace-format
		  (or (YaTeX-get-builtin "BIBTEX") bibtex-command)
		  "k" (YaTeX-kanji-ptex-mnemonic)))
    (or (string-match "\\s [^-]" bibcmd)	;if bibcmd has no argument,
	(setq bibcmd (concat bibcmd pparg)))	;append argument(== %#!)
    (and pp
	 (stringp pp)
	 (setq ppcmd (concat pp pparg)))
    (if (YaTeX-main-file-p) nil
      (save-excursion
	(YaTeX-visit-main t)	;search into main buffer
	(save-excursion
	  (push-mark (point) t)
	  (goto-char (point-min))
	  (if (and (re-search-forward "^[ 	]*\\\\begin{document}" nil t)
		   (re-search-backward "^[ 	]*\\\\includeonly{" nil t))
	      (let*
		  ((b (progn (skip-chars-forward "^{") (point)))
		   (e (progn (skip-chars-forward "^}") (1+ (point))))
		   (s (buffer-substring b e)) c
		   (pardir (file-name-directory (buffer-file-name))))
		(if (string-match (concat "[{,/]" me "[,}]") s)
		    nil ; Nothing to do when it's already in includeonly.
		  (ding)
		  (switch-to-buffer (current-buffer));Display this buffer.
		  (setq
		   me	  ;;Rewrite my name(me) to contain sub directory name.
		   (concat
		    (if (string-match pardir mydir) ;if mydir is child of main
			(substring mydir (length pardir)) ;cut absolute path
		      mydir) ;else concat absolute path name.
		    me))
		  (message
		   "`%s' is not in \\includeonly. A)dd R)eplace %%)comment? "
		   me)
		  (setq c (read-char))
		  (cond
		   ((= c ?a)
		    (goto-char (1+ b))
		    (insert me (if (string= s "{}") "" ",")))
		   ((= c ?r)
		    (delete-region (1+ b) (1- e)) (insert me))
		   ((= c ?%)
		    (beginning-of-line) (insert "%"))
		   (t nil))
		  (basic-save-buffer))))
	  (exchange-point-and-mark)))
      (switch-to-buffer cb))		;for 19
    (YaTeX-typeset cmd YaTeX-typeset-buffer nil nil ppcmd)
    (put 'dvi2-command 'region nil)))

(defvar YaTeX-call-command-history nil
  "Holds history list of YaTeX-call-command-on-file.")
(put 'YaTeX-call-command-history 'no-default t)
(defun YaTeX-call-command-on-file (base-cmd buffer &optional file)
  "Call external command BASE-CMD in the BUFFER.
By default, pass the basename of current file.  Optional 3rd argument
FILE changes the default file name."
  (YaTeX-save-buffers)
  (let ((default (concat base-cmd " "
			 (let ((me (file-name-nondirectory
				    (or file buffer-file-name))))
			   (if (string-match "\\.tex" me)
			       (substring me 0 (match-beginning 0))
			     me)))))
    (or YaTeX-call-command-history
	(setq YaTeX-call-command-history (list default)))
    (YaTeX-typeset
     (read-string-with-history
      "Call command: "
      (car YaTeX-call-command-history)
      'YaTeX-call-command-history)
     buffer)))

(defvar YaTeX-call-builtin-on-file)
(make-variable-buffer-local 'YaTeX-call-builtin-on-file)
(defun YaTeX-call-builtin-on-file (builtin-type &optional default update)
  "Call command on file specified by BUILTIN-TYPE."
  (YaTeX-save-buffers)
  (let*((main (or YaTeX-parent-file
		  (save-excursion (YaTeX-visit-main t) buffer-file-name)))
	(mainroot (file-name-nondirectory (substring main 0 (rindex main ?.))))
	(alist YaTeX-call-builtin-on-file)
	(b-in (YaTeX-replace-format
	       (or (YaTeX-get-builtin builtin-type)
		   (cdr (assoc builtin-type alist)))
	       "k" (YaTeX-kanji-ptex-mnemonic)))
	(command b-in))
    (if (or update (null b-in))
	(progn
	  (setq command (read-string-with-history
			 (format "%s command: " builtin-type)
			 (or b-in
			     (format "%s %s" default mainroot))
			 'YaTeX-call-command-history))
	  (if (or update (null b-in))
	      (if (y-or-n-p "Memorize this command line in this file? ")
		  (YaTeX-getset-builtin builtin-type command) ;keep in a file
		(setq YaTeX-call-builtin-on-file	      ;keep in memory
		      (cons (cons builtin-type command)
			    (delete (assoc builtin-type alist) alist)))
		(message "`%s' kept in memory.  Type `%s %s' to override."
			 command
			 (key-description
			  (car (where-is-internal 'universal-argument)))
			 (key-description (this-command-keys)))
		(sit-for 2)))))
    (YaTeX-typeset
     command
     (format " *YaTeX-%s*" (downcase builtin-type))
     builtin-type builtin-type)))

(defun YaTeX-kill-typeset-process (proc)
  "Kill process PROC after sending signal to PROC.
PROC should be process identifier."
  (cond
   ((not (fboundp 'start-process))
    (error "This system can't have concurrent process."))
   ((or (null proc) (not (eq (process-status proc) 'run)))
    (message "Typesetting process is not running."))
   (t
    (save-excursion
      (set-buffer (process-buffer proc))
      (save-excursion
	(goto-char (point-max))
	(beginning-of-line)
	(if (looking-at "\\? +$")
	    (let ((mp (point-max)))
	      (process-send-string proc "x\n")
	      (while (= mp (point-max)) (sit-for 1))))))
    (if (eq (process-status proc) 'run)
	(progn
	  (interrupt-process proc)
	  (delete-process proc))))))

(defun YaTeX-system (command name &optional noask basedir)
  "Execute some COMMAND with process name `NAME'.  Not a official function.
Optional second argument NOASK skip query when privious process running.
Optional third argument BASEDIR changes default-directory there."
  (save-excursion
    (let ((df default-directory)
	  (buffer (get-buffer-create (format " *%s*" name)))
	  proc status)
      (set-buffer buffer)
      (setq default-directory (cd (or basedir df)))
      (erase-buffer)
      (insert (format "Calling `%s'...\n" command)
	      "==Kill this buffer to STOP process==")
      (YaTeX-showup-buffer buffer 'YaTeX-showup-buffer-bottom-most)
      (if (not (fboundp 'start-process))
	  (call-process
	   shell-file-name nil buffer nil YaTeX-shell-command-option command)
	(if (and (setq proc (get-buffer-process buffer))
		 (setq status (process-status proc))
		 (eq status 'run)
		 (not noask)
		 (not
		  (y-or-n-p (format "Process %s is running. Continue?" buffer))))
	    nil
	  (if (eq status 'run)
	      (progn (interrupt-process proc) (delete-process proc)))
	  (set-process-buffer
	   (start-process
	    name buffer shell-file-name YaTeX-shell-command-option command)
	   (get-buffer buffer)))))))

(defvar YaTeX-default-paper-type "a4"
  "*Default paper type.")
(defconst YaTeX-paper-type-alist
  '(("a4paper" . "a4")
    ("a5paper" . "a5")
    ("b4paper" . "b4")
    ("b5paper" . "b5"))
  "Holds map of options and paper types.")
(defconst YaTeX-dvips-paper-option-alist
  '(("a4" . "-t a4")
    ("a5" . "-t a5")
    ("b4" . "-t b4")
    ("b5" . "-t b5")
    ("a4r" . "-t landscape"); Can't specify options, `-t a4' and `-t landscape', at the same time.
    ("a5r" . "-t landscape")
    ("b4r" . "-t landscape")
    ("b5r" . "-t landscape"))
  "Holds map of dvips options and paper types.")
(defun YaTeX-get-paper-type ()
  "Search options in header and return a paper type, such as \"a4\", \"a4r\", etc."
  (save-excursion
    (YaTeX-visit-main t)
    (goto-char (point-min))
    (let ((opts
	   (if (re-search-forward
		"^[ \t]*\\\\document\\(style\\|class\\)[ \t]*\\[\\([^]]*\\)\\]" nil t)
	       (YaTeX-split-string (YaTeX-match-string 2) "[ \t]*,[ \t]*"))))
      (concat
       (catch 'found-paper
	 (mapcar (lambda (pair)
		   (if (YaTeX-member (car pair) opts)
		       (throw 'found-paper (cdr pair))))
		 YaTeX-paper-type-alist)
	 YaTeX-default-paper-type)
       (if (YaTeX-member "landscape" opts) (if YaTeX-dos "L" "r") "")))))

(defvar YaTeX-preview-command-history nil
  "Holds minibuffer history of preview command.")
(put 'YaTeX-preview-command-history 'no-default t)
(defvar YaTeX-preview-file-history nil
  "Holds minibuffer history of file to preview.")
(put 'YaTeX-preview-file-history 'no-default t)
(defun YaTeX-preview-default-previewer ()
  "Return default previewer for this document"
  (YaTeX-replace-format
   (if (eq (get 'dvi2-command 'format) 'pdf)
       (or (YaTeX-get-builtin "PDFVIEW")
	   tex-pdfview-command)
     (or (YaTeX-get-builtin "PREVIEW")
	 dvi2-command))
   "p" (format (cond
		(YaTeX-dos "-y:%s")
		(t "-paper %s"))
	       (YaTeX-get-paper-type))))
(defun YaTeX-preview-default-main (command)
  "Return default preview target file"
  (if (get 'dvi2-command 'region)
		     (substring YaTeX-texput-file
				0 (rindex YaTeX-texput-file ?.))
		   (YaTeX-get-preview-file-name command)))
(defun YaTeX-preview (preview-command preview-file &optional as-default)
  "Execute xdvi (or other) to tex-preview."
  (interactive
   (let* ((previewer (YaTeX-preview-default-previewer))
	  (as-default current-prefix-arg)
	  (command (if as-default
		       previewer
		     (read-string-with-history
		      "Preview command: "
		      previewer
		      'YaTeX-preview-command-history)))
	  (target (YaTeX-preview-default-main command))
	  (file (if as-default
		    target
		  (read-string-with-history
		   "Preview file: "
		   target
		   'YaTeX-preview-file-history))))
     (list command file)))
  (setq dvi2-command preview-command)	;`dvi2-command' is buffer local
  (save-excursion
    (YaTeX-visit-main t)
    (if YaTeX-dos (setq preview-file (expand-file-name preview-file)))
    (let ((pbuffer "*dvi-preview*") (dir default-directory))
      (YaTeX-showup-buffer
       pbuffer 'YaTeX-showup-buffer-bottom-most)
      (set-buffer (get-buffer-create pbuffer))
      (erase-buffer)
      (setq default-directory dir)	;for 18
      (cd dir)				;for 19
      (cond
       ((not (fboundp 'start-process))	;if MS-DOS
	(send-string-to-terminal "\e[2J\e[>5h") ;CLS & hide cursor
	(call-process shell-file-name "con" "*dvi-preview*" nil
		      YaTeX-shell-command-option
		      (concat preview-command " " preview-file))
	(send-string-to-terminal "\e[>5l") ;show cursor
	(redraw-display))
       ((and (string-match "dviout" preview-command)	;maybe on `kon' 
	     (stringp (getenv "TERM"))
	     (string-match "^kon" (getenv "TERM")))
	(call-process shell-file-name "con" "*dvi-preview*" nil
		      YaTeX-shell-command-option
		      (concat preview-command " " preview-file)))
       (t				;if UNIX
	(set-process-buffer
	 (let ((process-connection-type nil))
	   (start-process "preview" "*dvi-preview*" shell-file-name
			  YaTeX-shell-command-option
			  (concat preview-command " " preview-file)))
	 (get-buffer pbuffer))
	(message
	 (concat "Starting " preview-command
		 " to preview " preview-file)))))))

(defvar YaTeX-xdvi-remote-program "xdvi")
(defun YaTeX-xdvi-remote-search (&optional region-mode)
  "Search string at the point on xdvi -remote window.
Non-nil for optional argument REGION-MODE specifies the search string
by region."
  (interactive "P")
  (let ((pb " *xdvi*") str proc)
    (save-excursion
      (if region-mode
	  (setq str (buffer-substring (region-beginning) (region-end)))
	(setq str (buffer-substring
		   (point)
		   (progn (skip-chars-forward "^\n\\\\}") (point)))))
      (message "Searching `%s'..." str)
      (if (boundp 'MULE)
	  (define-program-coding-system
	    (regexp-quote pb) (regexp-quote YaTeX-xdvi-remote-program)
	    *euc-japan*))
      (setq proc
	    (start-process
	     "xdvi" pb YaTeX-xdvi-remote-program
	     "-remote"  (format "SloppySearch(%s) " str)
	     (concat (YaTeX-get-preview-file-name) ".dvi")))
      (message "Searching `%s'...Done" str))))

(defun YaTeX-preview-jlfmt-xdvi ()
  "Call xdvi -sourceposition to DVI corresponding to current main file"
  (interactive))

(defun YaTeX-preview-jump-line ()
  "Call jump-line function of various previewer on current main file"
  (interactive)
  (save-excursion
    (save-restriction
      (widen)
      (let*((pf (or YaTeX-parent-file
		    (save-excursion (YaTeX-visit-main t) (buffer-file-name))))
	    (pdir (file-name-directory pf))
	    (bnr (substring pf 0 (string-match "\\....$" pf)))
	    ;(cf (file-relative-name (buffer-file-name) pdir))
	    (cf (buffer-file-name)) ;2016-01-08
	    (buffer (get-buffer-create " *preview-jump-line*"))
	    (line (count-lines (point-min) (point-end-of-line)))
	    (previewer (YaTeX-preview-default-previewer))
	    (cmd (cond
		  ((string-match "xdvi" previewer)
		   (format "%s -nofork -sourceposition '%d %s' %s.dvi"
			   YaTeX-xdvi-remote-program
			   line cf bnr))
		  ((string-match "Skim" previewer)
		   (format "%s %d '%s.pdf' '%s'"
			   YaTeX-cmd-displayline line bnr cf))
		  ((string-match "evince" previewer)
		   (format "%s '%s.pdf' %d '%s'"
			   "fwdevince" bnr line cf))
		  ;;
		  ;; These lines below for other PDF viewer is not confirmed
		  ;; yet. If you find correct command line, PLEASE TELL
		  ;; IT TO THE AUTHOR before publishing patch on the web.
		  ;; ..PLEASE PLEASE PLEASE PLEASE PLEASE PLEASE PLEASE..
		  ((string-match "sumatra" previewer)	;;??
		   (format "%s \"%s.pdf\" -forward-search \"%s\" %d"
			   ;;Send patch to the author, please
			   previewer bnr cf line))
		  ((string-match "qpdfview" previewer)	;;??
		   (format "%s '%s.pdf#src:%s:%d:0'"
			   ;;Send patch to the author, please
		  	   previewer bnr cf line))
		  ((string-match "okular" previewer)	;;??
		   (format "%s '%s.pdf#src:%d' '%s'"
			   ;;Send patch to the author, please
		  	   previewer bnr line cf))
		  )))
	(YaTeX-system cmd "jump-line" 'noask pdir)))))

(defun YaTeX-goto-corresponding-viewer ()
  (let ((cmd (or (YaTeX-get-builtin "!") tex-command)))
    (if (string-match "-src\\|synctex=" cmd)
	(progn
	  (YaTeX-preview-jump-line)
	  t)				;for YaTeX-goto-corresponding-*
      nil)))

(defun YaTeX-set-virtual-error-position (file-sym line-sym)
  "Replace the value of FILE-SYM, LINE-SYM by virtual error position."
  (cond
   ((and (get 'dvi2-command 'region)
	 (> (symbol-value line-sym) (car (get 'dvi2-command 'offset))))
    (set file-sym (get 'dvi2-command 'file))
    (set line-sym
	 (+ (- (apply '- (get 'dvi2-command 'offset)))
	    (symbol-value line-sym)
	    -1)))))

(defun YaTeX-prev-error ()
  "Visit position of previous typeset error or warning.
  To avoid making confliction of line numbers by editing, jump to
error or warning lines in reverse order."
  (interactive)
  (let ((cur-buf (save-excursion (YaTeX-visit-main t) (buffer-name)))
	(cur-win (selected-window))
	tsb-frame-selwin
	b0 bound errorp error-line typeset-win error-buffer error-win)
    (if (null (get-buffer YaTeX-typeset-buffer))
	(error "There is no typesetting buffer."))
    (and (fboundp 'selected-frame)
	 (setq typeset-win (get-buffer-window YaTeX-typeset-buffer t))
	 (setq tsb-frame-selwin (frame-selected-window typeset-win)))

    (YaTeX-showup-buffer YaTeX-typeset-buffer nil t)
    (if (and (markerp YaTeX-typeset-marker)
	     (eq (marker-buffer YaTeX-typeset-marker) (current-buffer)))
	(setq bound YaTeX-typeset-marker))
    (setq typeset-win (selected-window))
    (if (re-search-backward
	 (concat "\\(" latex-error-regexp "\\)\\|\\("
		 latex-warning-regexp "\\)")
	 bound t)
	(setq errorp (match-beginning 1))
      (select-window cur-win)
      (error "No more errors on %s" cur-buf))
    (goto-char (setq b0 (match-beginning 0)))
    (skip-chars-forward "^0-9" (match-end 0))
    (setq error-line
	  (YaTeX-str2int
	   (buffer-substring
	    (point)
	    (progn (skip-chars-forward "0-9" (match-end 0)) (point))))
	  error-buffer (expand-file-name (YaTeX-get-error-file cur-buf)))
    (if (or (null error-line) (equal 0 error-line))
	(error "Can't detect error position."))
    (YaTeX-set-virtual-error-position 'error-buffer 'error-line)

    (select-window typeset-win)
    (skip-chars-backward "0-9")
    (recenter (/ (window-height) 2))
    (sit-for 1)
    (goto-char b0)
    (and tsb-frame-selwin (select-window tsb-frame-selwin)) ;restore selwin

    (setq error-win (get-buffer-window error-buffer))
    (select-window cur-win)
    (cond
     (t (goto-buffer-window error-buffer)
	(if (fboundp 'raise-frame)
	    (let ((edit-frame (window-frame (selected-window))))
	      (raise-frame edit-frame)
	      (select-frame edit-frame)))
	)
     (error-win (select-window error-win))
     ((eq (get-lru-window) typeset-win)
      (YaTeX-switch-to-buffer error-buffer))
     (t (select-window (get-lru-window))
	(YaTeX-switch-to-buffer error-buffer)))
    (setq error-win (selected-window))
    (goto-line error-line)
    (message "LaTeX %s in `%s' on line: %d."
	     (if errorp "error" "warning")
	     error-buffer error-line)
    (select-window error-win)))

(defun YaTeX-jump-error-line ()
  "Jump to corresponding line on latex command's error message."
  (interactive)
  (let (error-line error-file error-buf)
    (save-excursion
      (beginning-of-line)
      (setq error-line (re-search-forward "l[ ines]*\\.?\\([1-9][0-9]*\\)"
					  (point-end-of-line) t)))
    (if (null error-line)
	(if (eobp) (insert (this-command-keys))
	  (error "No line number expression."))
      (goto-char (match-beginning 0))
      (setq error-line (YaTeX-str2int
			(buffer-substring (match-beginning 1) (match-end 1)))
	    error-file (expand-file-name
			(YaTeX-get-error-file YaTeX-current-TeX-buffer)))
      (YaTeX-set-virtual-error-position 'error-file 'error-line)
      (setq error-buf (YaTeX-switch-to-buffer error-file t)))
      (if (null error-buf)
	  (error "`%s' is not found in this directory." error-file))
      (YaTeX-showup-buffer error-buf nil t)
      (goto-line error-line)))

(defun YaTeX-send-string ()
  "Send string to current typeset process."
  (interactive)
  (if (and (eq (process-status YaTeX-typeset-process) 'run)
	   (>= (point) (process-mark YaTeX-typeset-process)))
      (let ((b (process-mark YaTeX-typeset-process))
	    (e (point-end-of-line)))
	(goto-char b)
	(skip-chars-forward " \t" e)
	(setq b (point))
	(process-send-string
	 YaTeX-typeset-process (concat (buffer-substring b e) "\n"))
	(goto-char e)
	(insert "\n")
	(set-marker (process-mark YaTeX-typeset-process) (point))
	(insert " "))
    (ding)))

(defun YaTeX-view-error ()
  (interactive)
  (if (null (get-buffer YaTeX-typeset-buffer))
      (message "No typeset buffer found.")
    (let ((win (selected-window)))
      (YaTeX-showup-buffer YaTeX-typeset-buffer nil t)
      ;; Next 3 lines are obsolete because YaTeX-typesetting-buffer is
      ;; automatically scrolled up at typesetting.
      ;;(goto-char (point-max))
      ;;(forward-line -1)
      ;;(recenter -1)
      (select-window win))))

(defun YaTeX-get-error-file (default)
  "Get current processing file from typesetting log."
  (save-excursion
    (let(s)
      (condition-case () (up-list -1)
	(error
	 (let ((list 0) found)
	   (while
	       (and (<= list 0) (not found)
		    (re-search-backward "\\((\\)\\|\\()\\)" nil t))
	     (if (equal (match-beginning 0) (match-beginning 2)) ;close paren.
		 (setq list (1- list)) ;open paren
	       (setq list (1+ list))
	       (if (= list 1)
		   (if (looking-at "\\([^,{}%]+\.\\)tex\\|sty")
		       (setq found t)
		     (setq list (1- list)))))))))
      (setq s
	    (buffer-substring
	     (progn (forward-char 1) (point))
	     (if (re-search-forward
		  "\\.\\(tex\\|sty\\|ltx\\)\\>" nil (point-end-of-line))
		 (match-end 0)
	       (skip-chars-forward "^ \n" (point-end-of-line))
	       (point))))
      (if (string= "" s) default s))))
      
(defun YaTeX-put-nonstopmode ()
  (if (and (eq major-mode 'yatex-mode) YaTeX-need-nonstop)
      (if (re-search-backward "\\\\nonstopmode{}" (point-min) t)
	  nil                    ;if already written in text then do nothing
	(save-excursion
	  (YaTeX-visit-main t)
	  (goto-char (point-min))
	  (insert "\\nonstopmode{}%_YaTeX_%\n")
	  (if (buffer-file-name) (basic-save-buffer))))))

(defun YaTeX-remove-nonstopmode ()
  (if (and (eq major-mode 'yatex-mode) YaTeX-need-nonstop) ;for speed
      (save-excursion
	(YaTeX-visit-main t)
	(goto-char (point-min))
	(forward-line 1)
	(narrow-to-region (point-min) (point))
	(goto-char (point-min))
	(delete-matching-lines "^\\\\nonstopmode\\{\\}%_YaTeX_%$")
	(widen))))

(defvar YaTeX-dvi2-command-ext-alist
 '(("[agxk]dvi\\|dviout" . ".dvi")
   ("ghostview\\|gv" . ".ps")
   ("acroread\\|[xk]pdf\\|pdfopen\\|Preview\\|TeXShop\\|Skim\\|evince\\|atril\\|xreader\\|mupdf\\|zathura\\|okular" . ".pdf")))

(defun YaTeX-get-preview-file-name (&optional preview-command)
  "Get file name to preview by inquiring YaTeX-get-latex-command"
  (if (null preview-command) (setq preview-command dvi2-command))
  (let* ((latex-cmd (YaTeX-get-latex-command t))
	 (rin (rindex latex-cmd ? ))
	 (fname (if rin (substring latex-cmd (1+ rin)) ""))
	 (r (YaTeX-assoc-regexp preview-command YaTeX-dvi2-command-ext-alist))
	 (ext (if r (cdr r) "")))
    (and (null r)
	 (eq (get 'dvi2-command 'format) 'pdf)
	 (setq ext ".pdf"))
    (concat
     (if (string= fname "")
	 (setq fname (substring (file-name-nondirectory
				 (buffer-file-name))
				0 -4))
       (setq fname (substring fname 0 (rindex fname ?.))))
     ext)))

(defun YaTeX-get-latex-command (&optional switch)
  "Specify the latex-command name and its argument.
If there is a line which begins with string: \"%#!\", the following
strings are assumed to be the latex-command and arguments.  The
default value of latex-command is:
	tex-command FileName
and if you write \"%#!platex\" in the beginning of certain line.
	\"platex \" FileName
will be the latex-command,
and you write \"%#!platex main.tex\" on some line and argument SWITCH
is non-nil, then
	\"platex main.tex\"

will be given to the shell."
  (let (parent tparent magic)
    (setq parent
	  (cond
	   (YaTeX-parent-file
	    (if YaTeX-dos (expand-file-name YaTeX-parent-file)
	      YaTeX-parent-file))
	   (t (save-excursion
		(YaTeX-visit-main t)
		(file-name-nondirectory (buffer-file-name)))))
	  magic (YaTeX-get-builtin "!")
	  tparent (file-name-nondirectory parent))
    (YaTeX-replace-formats
     (cond
      (magic
       (cond
	(switch (if (string-match "\\s [^-]\\S *$" magic) magic
		  (concat magic " " parent)))
	(t (concat (substring magic 0 (string-match "\\s [^-]\\S *$" magic)) " "))))
      (t (concat tex-command " " (if switch parent))))
     (list (cons "f" tparent)
	   (cons "r" (substring tparent 0 (rindex tparent ?.)))
	   (cons "k" (YaTeX-kanji-ptex-mnemonic))))))

(defvar YaTeX-lpr-command-history nil
  "Holds command line history of YaTeX-lpr.")
(put 'YaTeX-lpr-command-history 'no-default t)
(defvar YaTeX-lpr-ask-page-range-default t)
(defun YaTeX-lpr (arg)
  "Print out.
If prefix arg ARG is non nil, call print driver without
page range description."
  (interactive "P")
  (or YaTeX-lpr-ask-page-range-default (setq arg (not arg)))
  (let*((cmd (or (YaTeX-get-builtin "LPR") dviprint-command-format))
	from to (lbuffer "*dvi-printing*") dir)
    (setq
     cmd 
     (YaTeX-replace-format
      cmd "f"
      (if (or arg (not (string-match "%f" cmd)))
	      ""
	    (YaTeX-replace-format
	     dviprint-from-format
	     "b"
	     (if (string=
		  (setq from (read-string "From page(default 1): ")) "")
		 "1" from))))
       )
    (setq
     cmd
     (YaTeX-replace-format
      cmd "t"
      (if (or arg (not (string-match "%t" cmd))
	      (string= 
	       (setq to (read-string "To page(default none): ")) ""))
	  ""
	(YaTeX-replace-format dviprint-to-format "e" to)))
     )
    (setq
     cmd
     (YaTeX-replace-format
      cmd "p"
      (cdr (assoc (YaTeX-get-paper-type) YaTeX-dvips-paper-option-alist))))
    (setq cmd
	  (read-string-with-history
	   "Edit command line: "
	   (format cmd
		   (if (get 'dvi2-command 'region)
		       (substring YaTeX-texput-file
				  0 (rindex YaTeX-texput-file ?.))
		     (YaTeX-get-preview-file-name)))
	   'YaTeX-lpr-command-history))
    (save-excursion
      (YaTeX-visit-main t) ;;change execution directory
      (setq dir default-directory)
      (YaTeX-showup-buffer
       lbuffer 'YaTeX-showup-buffer-bottom-most)
      (set-buffer (get-buffer-create lbuffer))
      (erase-buffer)
      (cd dir)				;for 19
      (cond
       ((not (fboundp 'start-process))
	(call-process shell-file-name "con" "*dvi-printing*" nil
		      YaTeX-shell-command-option cmd))
       (t
	(set-process-buffer
	 (let ((process-connection-type nil))
	   (start-process "print" "*dvi-printing*" shell-file-name
			  YaTeX-shell-command-option cmd))
	 (get-buffer lbuffer))
	(message "Starting printing command: %s..." cmd))))))

(defun YaTeX-main-file-p ()
  "Return if current buffer is main LaTeX source."
  (cond
   (YaTeX-parent-file
    (eq (get-file-buffer YaTeX-parent-file) (current-buffer)))
   ((YaTeX-get-builtin "!")
    (string-match
     (concat "^" (YaTeX-guess-parent (YaTeX-get-builtin "!")))
     (buffer-name)))
   (t
    (save-excursion
      (let ((latex-main-id
	     (concat "^\\s *" YaTeX-ec-regexp "document\\(style\\|class\\)")))
	(or (re-search-backward latex-main-id nil t)
	    (re-search-forward latex-main-id nil t)))))))

(defun YaTeX-visit-main (&optional setbuf)
  "Switch buffer to main LaTeX source.
Use set-buffer instead of switch-to-buffer if the optional argument
SETBUF is t(Use it only from Emacs-Lisp program)."
  (interactive "P")
  (if (and (interactive-p) setbuf) (setq YaTeX-parent-file nil))
  (let ((ff (function (lambda (f)
			(if setbuf (set-buffer (find-file-noselect f))
			  (find-file f)))))
	b-in main-file mfa YaTeX-create-file-prefix-g
	(hilit-auto-highlight (not setbuf)))
    (if (setq b-in (YaTeX-get-builtin "!"))
	(setq main-file (YaTeX-guess-parent b-in)))
    (if YaTeX-parent-file
	(setq main-file ;;(get-file-buffer YaTeX-parent-file)
	      YaTeX-parent-file))
    (if (YaTeX-main-file-p)
	(if (interactive-p) (message "I think this is main LaTeX source.") nil)
      (cond
       ((and ;;(interactive-p) 
	     main-file
	     (cond ((get-file-buffer main-file)
		    (cond
		     (setbuf (set-buffer (get-file-buffer main-file)))
		     ((get-buffer-window (get-file-buffer main-file))
		      (select-window
		       (get-buffer-window (get-file-buffer main-file))))
		     (t (switch-to-buffer (get-file-buffer main-file)))))
		   ((file-exists-p main-file)
		    (funcall ff main-file)))))
       ;;((and main-file (YaTeX-switch-to-buffer main-file setbuf)))
       ((and main-file
	     (file-exists-p (setq main-file (concat "../" main-file)))
	     (or b-in
		 (y-or-n-p (concat (setq mfa (expand-file-name main-file))
				   " is main file?:"))))
	(setq YaTeX-parent-file mfa)
	;(YaTeX-switch-to-buffer main-file setbuf)
	(funcall ff main-file)
	)
       (t (setq main-file (read-file-name "Enter your main text: " nil nil 1))
	  (setq YaTeX-parent-file (expand-file-name main-file))
	 ; (YaTeX-switch-to-buffer main-file setbuf))
	  (funcall ff main-file))
       )))
  nil)

(defun YaTeX-guess-parent (command-line)
  (setq command-line
	(if (string-match "\\s \\([^-]\\S *\\)$" command-line)
	    (substring command-line (match-beginning 1))
	  (file-name-nondirectory (buffer-file-name)))
	command-line
	(concat (if (string-match "\\(.*\\)\\." command-line)
		    (substring command-line (match-beginning 1) (match-end 1))
		  command-line)
		".tex")))

(defun YaTeX-visit-main-other-window ()
  "Switch to buffer main LaTeX source in other window."
  (interactive)
  (if (YaTeX-main-file-p) (message "I think this is main LaTeX source.")
      (YaTeX-switch-to-buffer-other-window
       (concat (YaTeX-get-preview-file-name) ".tex"))))

(defun YaTeX-save-buffers ()
  "Save buffers whose major-mode is equal to current major-mode."
  (basic-save-buffer)
  (let ((cmm major-mode))
    (save-excursion
      (mapcar (function
	       (lambda (buf)
		 (set-buffer buf)
		 (if (and (buffer-file-name buf)
			  (eq major-mode cmm)
			  (buffer-modified-p buf)
			  (y-or-n-p (format "Save %s" (buffer-name buf))))
		     (save-buffer buf))))
	      (buffer-list)))))

(provide 'yatexprc)
