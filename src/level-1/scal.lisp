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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package #:matlisp)

(defmacro generate-typed-scal! (func (tensor-class blas-func fortran-lb))
  (let ((opt (get-tensor-class-optimization tensor-class)))
    (assert opt nil 'tensor-cannot-find-optimization :tensor-class tensor-class)
    `(defun ,func (alpha to)
       (declare (type ,tensor-class to)
		(type ,(getf opt :element-type) alpha))
       (let ((min-stride (consecutive-store-p to))
	     (call-fortran? (> (number-of-elements to) ,fortran-lb)))
	 (cond
	   ((and min-stride call-fortran?)
	    (,blas-func (number-of-elements to) alpha (store to) min-stride (head to)))
	   (t
	    (let ((t-sto (store to)))
	      (declare (type ,(linear-array-type (getf opt :store-type)) t-sto))
	      (very-quickly
		(mod-dotimes (idx (dimensions to))
		  with (linear-sums
			(t-of (strides to) (head to)))
		  do (let ((scal-val (* ,(funcall (getf opt :reader) 't-sto 't-of) alpha)))
		       ,(funcall (getf opt :value-writer) 'scal-val 't-sto 't-of))))))))
       to)))

;;Real
(generate-typed-scal! real-typed-scal!
  (real-tensor dscal *real-l1-fcall-lb*))

;;Complex
(definline zordscal (nele alpha x incx &optional hd-x)
  (if (zerop (imagpart alpha))
      (zdscal nele (realpart alpha) x incx hd-x)
      (zscal nele alpha x incx hd-x)))

(generate-typed-scal! complex-typed-scal!
  (complex-tensor zordscal *complex-l1-fcall-lb*))
;;---------------------------------------------------------------;;

(defgeneric scal! (alpha x)
  (:documentation
"
  Syntax
  ======
  (SCAL! alpha x)

  Purpose
  =======
  X <- alpha .* X
"))

(defmethod scal! ((alpha number) (x real-tensor))
  (real-typed-scal! (coerce-real alpha) x))

(defmethod scal! ((alpha number) (x complex-tensor))
  (complex-typed-scal! (coerce-complex alpha) x))

;;
(defgeneric scal (alpha x)
  (:documentation
"
  Syntax
  ======
  (SCAL alpha x)

  Purpose
  =======
  Computes and returns a new tensor equal to

             alpha .* X

  where alpha is a scalar and X is a tensor.

"))

(defmethod scal ((alpha number) (x number))
  (* alpha x))

(defmethod scal ((alpha number) (x real-tensor))
  (let ((result (copy x)))
    (scal! alpha result)))

(defmethod scal ((alpha complex) (x real-tensor))
  (let* ((result (apply #'make-complex-tensor (idx->list (dimensions x)))))
    (declare (type complex-tensor result))
    (copy! x result)
    (scal! alpha result)))

(defmethod scal ((alpha number) (x complex-tensor))
  (let ((result (copy x)))
    (scal! alpha result)))
