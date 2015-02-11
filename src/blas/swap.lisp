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
(in-package #:matlisp)

(deft/generic (t/blas-swap-func #'subfieldp) sym ())
(deft/method t/blas-swap-func (sym real-tensor) ()
  'dswap)
(deft/method t/blas-swap-func (sym complex-tensor) ()
  'zswap)
;;
(deft/generic (t/blas-swap! #'subtypep) sym (x st-x y st-y))
(deft/method t/blas-swap! (sym blas-numeric-tensor) (x st-x y st-y)
  (let ((ftype (field-type sym)))
    (using-gensyms (decl (x y))
      `(let (,@decl)
	 (declare (type ,sym ,x ,y))
	 (ffuncall ,(blas-func "swap" ftype)
		   (:& :integer) (size ,y)
		   (:* ,(lisp->ffc ftype) :+ (head ,x)) (the ,(store-type sym) (store ,x)) (:& :integer) ,st-x
		   (:* ,(lisp->ffc ftype) :+ (head ,y)) (the ,(store-type sym) (store ,y)) (:& :integer) ,st-y)
	 ,y))))
  
(deft/generic (t/swap! #'subtypep) sym (x y))
(deft/method t/swap! (sym standard-tensor) (x y)
  (using-gensyms (decl (x y) (idx sto-x sto-y of-x of-y y-val))
    `(let* (,@decl
	    (,sto-x (store ,x))
	    (,sto-y (store ,y)))
       (declare (type ,sym ,x ,y)
		(type ,(store-type sym) ,sto-x ,sto-y))
       (very-quickly
	 (iter (for-mod ,idx from 0 below (dimensions ,x) with-strides ((,of-x (strides ,x) (head ,x))
									(,of-y (strides ,y) (head ,y))))
	       (let-typed ((,y-val (t/store-ref ,sym ,sto-y ,of-y) :type ,(field-type sym)))
		 (t/store-set ,sym (t/store-ref ,sym ,sto-x ,of-x) ,sto-y ,of-y)
		 (t/store-set ,sym ,y-val ,sto-x ,of-x)))
	 ,y))))
;;---------------------------------------------------------------;;
(defmethod swap! :before ((x standard-tensor) (y standard-tensor))
  (assert (very-quickly (lvec-eq (the index-store-vector (dimensions x)) (the index-store-vector (dimensions y)) #'=)) nil
	  'tensor-dimension-mismatch))

(defmethod swap! ((x standard-tensor) (y standard-tensor))
  (let ((clx (class-name (class-of x)))
	(cly (class-name (class-of y))))
    (assert (and (member clx *tensor-type-leaves*)
		 (member cly *tensor-type-leaves*))
	    nil 'tensor-abstract-class :tensor-class (list clx cly))
    (if (eq clx cly)
	(progn
	  (compile-and-eval
	   `(defmethod swap! ((x ,clx) (y ,cly))
	      ,(recursive-append
		(when (subtypep clx 'blas-numeric-tensor)
		  `(if-let (strd (and (call-fortran? x (t/l1-lb ,clx)) (blas-copyablep x y)))
		     (t/blas-swap! ,clx x (first strd) y (second strd))))
		`(t/swap! ,clx x y))
	      y))
	  (swap! x y))
	;;It is silly to swap a real vector with a complex one, no?
	(error "Don't know how to swap ~a and ~a." clx cly))))
