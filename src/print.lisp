;;; -*- Mode: lisp; Syntax: ansi-common-lisp; Package: :matlisp; Base: 10 -*-
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Copyright (c) 2000 The Regents of the University of California.
;;; All rights reserved. 
;;; 
;;; Permission is hereby granted, without written agreement and without
;;; license or royalty fees, to use, copy, modify, and distribute this
;;; software and its documentation for any purpose, provided that the
;;; above copyright notice and the following two paragraphs appear in all
;;; copies of this software.
;;; 
;;; IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY
;;; FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
;;; ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
;;; THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
;;; SUCH DAMAGE.
;;;
;;; THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
;;; INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
;;; MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE
;;; PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
;;; CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
;;; ENHANCEMENTS, OR MODIFICATIONS.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; $Id: print.lisp,v 1.1 2000/04/14 00:11:12 simsek Exp $
;;;
;;; $Log: print.lisp,v $
;;; Revision 1.1  2000/04/14 00:11:12  simsek
;;; o This file is adapted from obsolete files 'matrix-float.lisp'
;;;   'matrix-complex.lisp' and 'matrix-extra.lisp'
;;; o Initial revision.
;;;
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Routines for printing a matrix nicely.

(in-package "MATLISP")

(export '(*print-matrix*
	  print-element))

(defvar *print-matrix*
  5
  "Maximum number of columns and/or rows to print.  Set this to NIL to
  print no elements (same as *PRINT-ARRAY* set to NIL).  Set this to T
  to print all elements of the matrix.

  This is useful for preventing printing of huge matrices by accident.")

(defun set-print-limits-for-matrix (n m)
  (declare (type fixnum n m))
  (if (eq *print-matrix* t)
      (values n m)
    (if (eq *print-matrix* nil)
	(values 0 0)
      (if (and (integerp *print-matrix*)
	       (> *print-matrix* 0))
	  (values (min n *print-matrix*)
		  (min m *print-matrix*))
	(error "Cannot set the print limits for matrix.
Required that *PRINT-MATRIX* be T,NIL or a positive INTEGER,
but got *PRINT-MATRIX* of type ~a"
	       (type-of *print-matrix*))))))
      

(defgeneric print-element (matrix
			    element
			    stream)
  (:documentation "
 Syntax
 ======
 (PRINT-ELEMENT matrix element stream)

 Purpose
 =======
 This generic function is specialized to MATRIX to
 print ELEMENT to STREAM.  Called by PRINT-MATRIX
 to format a matrix to STREAM.
"))

(defmethod print-element ((matrix standard-matrix)
			  element
			  stream)
  (format stream "~a" element))

(defmethod print-element ((matrix real-matrix)
			  element
			  stream)
  (format stream "~11,5,,,'*,,'Eg" element))

(defmethod print-element ((matrix complex-matrix)
			  element
			  stream)
  
  (let ((realpart (realpart element))
	(imagpart (imagpart element)))

    (if (zerop imagpart)
	(format stream "      ~11,5,,,'*,,'Eg      " realpart)
      (format stream "#~a(~9,3,,,,,'Ee ~9,3,,,,,'Ee)" 
	      'c 
	      realpart
	      imagpart))))

(defun print-matrix (matrix stream)
  (with-slots (n m) matrix
      (multiple-value-bind (max-n max-m)
	     (set-print-limits-for-matrix n m)
	 (declare (type fixnum max-n max-m))
	 (format stream " ~d x ~d" n m)

	 (decf max-n)
	 (decf max-m)  
	 (flet ((print-row (i)
		  (format stream "~%   ")
		  (dotimes (j max-m)
		    (declare (type fixnum j))
		    (print-element matrix 
				   (matrix-ref matrix i j)
				   stream)
		    (format stream " "))
		  (if (< max-m (1- m))
		      (progn
			(format stream "... ")
			(print-element matrix 
				       (matrix-ref matrix i (1- m))
				       stream)
			(format stream " "))
		    (if (< max-m m)
			(progn
			  (print-element matrix 
					 (matrix-ref matrix i (1- m))
					 stream)
			  (format stream " "))))))
	   
	   (dotimes (i max-n)
	     (declare (type fixnum i))
	     (print-row i))
	   
	   (if (< max-n (1- n))
	       (progn
		 (format stream "~%     :")
		 (print-row (1- n)))
	     (if (< max-n n)
		 (print-row (1- n))))))))

(defmethod print-object ((matrix standard-matrix) stream)
  (format stream "#<~a" (type-of matrix))
  (if *print-matrix*
      (print-matrix matrix stream)
    (format stream "{~x}" (kernel:get-lisp-obj-address matrix)))
  (format stream " >~%"))



(defmethod print-object ((matrix real-matrix) stream)
  (format stream "#<~a" (type-of matrix))
  (if *print-matrix*
      (print-matrix matrix stream)
    (format stream "{~x}" (kernel:get-lisp-obj-address matrix)))
  (format stream " >~%"))


(defmethod print-object ((matrix complex-matrix) stream)
  (format stream "#<~a" (type-of matrix))
  (if *print-matrix*
      (print-matrix matrix stream)
    (format stream "{~x}" (kernel:get-lisp-obj-address matrix)))
  (format stream " >~%"))
