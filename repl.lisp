;; Copyright (c) 2003 Nikodemus Siivola
;; 
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;; 
;; The above copyright notice and this permission notice shall be included
;; in all copies or substantial portions of the Software.
;; 
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
;; IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
;; CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
;; TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
;; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

(in-package :linedit)

(defun install-repl (&key use-wrapper)
  #+sbcl
  (when (linedit:tty-p)
    (let ((prompt-fun sb-int:*repl-prompt-fun*)
	  (read-form-fun sb-int:*repl-read-form-fun*))
      (declare (type function prompt-fun read-form-fun))
      (setf sb-int:*repl-prompt-fun* (constantly ""))
      (flet ((repl-reader (in out)
	       (declare (type stream out)
			(ignore in))
	       (fresh-line out)
	       (let ((prompt (with-output-to-string (s)
			       (funcall prompt-fun s))))
		 (handler-case
		     (linedit:formedit
		      :prompt prompt
		      :prompt2 (make-string (length prompt) 
					    :initial-element #\Space))
		   (end-of-file () (sb-ext:quit))))))
	(setf sb-int:*repl-read-form-fun*	      
	      (if use-wrapper
		  (lambda (in out)
		    (declare (type stream out in))
		    (with-input-from-string (in (repl-reader in out))
		      (terpri)
		      (funcall read-form-fun in out)))
		  (lambda (in out)
		    (declare (type stream out in))
		    (read-from-string (repl-reader in out))))))
      (push (lambda ()
	      (warn "Deinstalling linedit-repl before dumping core.")
	      (setf sb-int:*repl-read-form-fun* read-form-fun
		    sb-int:*repl-prompt-fun* prompt-fun))
	    sb-int:*before-save-initializations*)))
  #-sbcl (error "install-repl is SBCL only"))