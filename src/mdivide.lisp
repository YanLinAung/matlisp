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
;;; $Id: mdivide.lisp,v 1.1 2000/04/14 00:11:12 simsek Exp $
;;;
;;; $Log: mdivide.lisp,v $
;;; Revision 1.1  2000/04/14 00:11:12  simsek
;;; o This file is adapted from obsolete files 'matrix-float.lisp'
;;;   'matrix-complex.lisp' and 'matrix-extra.lisp'
;;; o Initial revision.
;;;
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "MATLISP")

(use-package "BLAS")
(use-package "LAPACK")
(use-package "FORTRAN-FFI-ACCESSORS")

(export '(m/
	  m./
	  m/!
	  m./!))

(defgeneric m/ (a &optional b)
  (:documentation
   "
  Syntax
  ======
  (M/ a [b])

  Purpose
  =======

  Equivalent to inv(A) * B, but far more efficient and accurate.
  If A is not given, the inverse of B is returned. 

  A is an NxN square matrix and B is NxM.

  B may be a scalar in which case M/ is equivalent to M./

  See M/!, M./, M./!, GESV
"))

(defgeneric m/! (a &optional b)
  (:documentation
   "
  Syntax
  ======
  (M/! a [b])

  Purpose
  =======
  Destructive version of M/

           B <- (M/ A B)

      or 
 
           A <- (M/ A)

  See M/, M./, M./!, GESV
"))

(defgeneric m./ (a b)
  (:documentation
   "
  Syntax
  ======
  (M./ a b)

  Purpose
  =======
  Create a new matrix which is the element by
  element division of A by B.

  A and/or B may be scalars.

  If A and B are matrices they need not be of
  the same dimension, however, they must have
  the same number of total elements.

  See M./!, M/, M/!, GESV
"))

(defgeneric m./! (a b)
  (:documentation
   "
  Syntax
  ======
  (M./! a b)

  Purpose
  =======
  Destructive version of M./

            B <- (M./ A B)

  If B is a scalar then the result overrides A, not B.
  
  See M./, M/, M/!, GESV
"))


(defmethod m/ :before ((a standard-matrix) &optional b)

  (if b
      (typecase b
	(number t)
	(standard-matrix (if (not 
			      (and 
			       (square-matrix-p a)
			       (= (n b) (n a))))
			     (error "dimensions of A,B given to M/ do not match")))
	(t (error "argument B given to M/ is not a matrix or a number")))

    (if (not (square-matrix-p a))
	(error "argument A given to M/ is not a square matrix"))))


(defmethod m/ ((a standard-matrix) &optional b)
  (if b
      (typecase b
	(number (m./ a b))
	(standard-matrix (multiple-value-bind (x ipiv f info)
			     (gesv a b)
			   (declare (ignore ipiv f))
			   (if (numberp info)		     
			       (error "argument A given to M/ is singular to working machine precision")
			     x))))
    (multiple-value-bind (x ipiv f info)
	(gesv a (eye (n a)))
      (declare (ignore ipiv f))
      (if (numberp info)
	(error "argument A given to M/ is singular to working machine precision")
	x))))

(defmethod m/! :before ((a standard-matrix) &optional b)

  (if b
      (typecase b
	(number t)
	(standard-matrix (if (not 
			      (and 
			       (square-matrix-p a)
			       (= (n b) (n a))))
			     (error "dimensions of A,B given to M/ do not match")))
	(t (error "argument B given to M/! is not a matrix or a number")))

    (if (not (square-matrix-p a))
	(error "argument A given to M/! is not a square matrix"))))


(defmethod m/! ((a standard-matrix) &optional b)
  (if b
      (typecase b
	(number (m./! a b))
	(standard-matrix (multiple-value-bind (x ipiv f info)
			     (gesv! (copy a) b)
			   (declare (ignore ipiv f))
			   (if (numberp info)		     
			       (error "argument A given to M/! is singular to working machine precision")
			     x))))
    (multiple-value-bind (x ipiv f info)
	(gesv! (copy a) (eye (n a)))
      (declare (ignore ipiv f))
      (if (numberp info)
	(error "argument A given to M/! is singular to working machine precision")
	x))))

(defmethod m./ :before ((a standard-matrix) (b standard-matrix))
  (let ((nxm-a (nxm a))
	(nxm-b (nxm b)))
    (declare (type fixnum nxm-a nxm-b))
    (unless (= nxm-a nxm-b)
      (error "arguments A,B given to M./ are not the same size"))))

(defmethod m./! :before ((a standard-matrix) (b standard-matrix))
  (let ((nxm-a (nxm a))
	(nxm-b (nxm b)))
    (declare (type fixnum nxm-a nxm-b))
    (unless (= nxm-a nxm-b)
      (error "arguments A,B given to M./! are not the same size"))))

  
(defmethod m./ ((a real-matrix) (b real-matrix))
  (let* ((n (n b))
	 (m (m b))
	 (nxm (nxm b))
	 (result (make-real-matrix-dim n m)))
    (declare (type fixnum n m nxm))

    (dotimes (k nxm result)
      (declare (type fixnum k))
      (let ((a-val (matrix-ref a k))
	    (b-val (matrix-ref b k)))
	(declare (type real-matrix-element-type a-val b-val))
	(setf (matrix-ref result k) (/ a-val b-val))))))

(defmethod m./ ((a complex-matrix) (b complex-matrix))
  (let* ((n (n b))
	 (m (m b))
	 (nxm (nxm b))
	 (result (make-complex-matrix-dim n m)))
    (declare (type fixnum n m nxm))

    (dotimes (k nxm result)
      (declare (type fixnum k))
      (let ((a-val (matrix-ref a k))
	    (b-val (matrix-ref b k)))
	(declare (type (complex complex-matrix-element-type) a-val b-val))
	(setf (matrix-ref result k) (/ a-val b-val))))))

(defmethod m./ ((a real-matrix) (b complex-matrix))
  (let* ((n (n b))
	 (m (m b))
	 (nxm (nxm b))
	 (result (make-complex-matrix-dim n m)))
    (declare (type fixnum n m nxm))

    (dotimes (k nxm result)
      (declare (type fixnum k))
      (let ((a-val (matrix-ref a k))
	    (b-val (matrix-ref b k)))
	(declare (type (complex complex-matrix-element-type)  b-val)
		 (type real-matrix-element-type a-val))
	(setf (matrix-ref result k) (/ a-val b-val))))))

(defmethod m./ ((a complex-matrix) (b real-matrix))
  (m./ b a))
  
(defmethod m./! ((a real-matrix) (b real-matrix))
  (let* ((nxm (nxm b)))
    (declare (type fixnum nxm))

    (dotimes (k nxm b)
      (declare (type fixnum k))
      (let ((a-val (matrix-ref a k))
	    (b-val (matrix-ref b k)))
	(declare (type real-matrix-element-type a-val b-val))
	(setf (matrix-ref b k) (/ a-val b-val))))))

(defmethod m./! ((a complex-matrix) (b complex-matrix))
  (let* ((nxm (nxm b)))
    (declare (type fixnum nxm))

    (dotimes (k nxm b)
      (declare (type fixnum k))
      (let ((a-val (matrix-ref a k))
	    (b-val (matrix-ref b k)))
	(declare (type (complex complex-matrix-element-type) a-val b-val))
	(setf (matrix-ref b k) (/ a-val b-val))))))

(defmethod m./! ((a real-matrix) (b complex-matrix))
  (let* ((nxm (nxm b)))
    (declare (type fixnum nxm))

    (dotimes (k nxm b)
      (declare (type fixnum k))
      (let ((a-val (matrix-ref a k))
	    (b-val (matrix-ref b k)))
	(declare (type (complex complex-matrix-element-type)  b-val)
		 (type real-matrix-element-type a-val))
	(setf (matrix-ref b k) (/ a-val b-val))))))

(defmethod m./! ((a complex-matrix) (b real-matrix))
  (error "cannot M./! a COMPLEX-MATRIX into a REAL-MATRIX,
don't know how to coerce COMPLEX to REAL"))

(defmethod m./ ((a number) (b number))
  (/ a b))

(defmethod m./! ((a number) (b number))
  (/ a b))

(defmethod m./ ((a standard-matrix) (b number))
  (scal (/ b) a))

(defmethod m./! ((a standard-matrix) (b number))
  (scal! (/ b) a))

(defmethod m./ ((a number) (b standard-matrix))
  (scal! a (map-matrix! #'/ (copy b))))

(defmethod m./! ((a number) (b standard-matrix))
  (scal! a (map-matrix! #'/ b)))


