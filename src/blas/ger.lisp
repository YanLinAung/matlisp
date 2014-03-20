(in-package #:matlisp)

(deft/generic (t/blas-ger-func #'subfieldp) sym (&optional conjp))
(deft/method t/blas-ger-func (sym real-tensor) (&optional conjp)
  'dger)
(deft/method t/blas-ger-func (sym complex-tensor) (&optional (conjp t))
  (if conjp 'zgerc 'zdotu))
;;
(deft/generic (t/blas-ger! #'subtypep) sym (alpha x st-x y st-y A lda &optional conjp))

(deft/method t/blas-ger! (sym blas-numeric-tensor) (alpha x st-x y st-y A lda &optional (conjp t))
  (using-gensyms (decl (alpha x st-x y st-y A lda))
    (with-gensyms (m n)
      `(let (,@decl)
	 (declare (type ,sym ,A ,x ,y)
		  (type ,(field-type sym) ,alpha)
		  (type index-type ,st-x ,st-y ,lda))
	 (let ((,m (aref (the index-store-vector (dimensions ,A)) 0))
	       (,n (aref (the index-store-vector (dimensions ,A)) 1)))
	   (declare (type index-type  ,m ,n))
	   (,(macroexpand-1 `(t/blas-ger-func ,sym conjp))
	     ,m ,n
	     ,alpha
	     (the ,(store-type sym) (store ,x)) (the index-type ,st-x)
	     (the ,(store-type sym) (store ,y)) (the index-type ,st-y)
	     (the ,(store-type sym) (store ,A)) ,lda
	     (the index-type (head ,x)) (the index-type (head ,y)) (the index-type (head ,A))))
	 ,A))))

;;
(deft/generic (t/ger! #'subtypep) sym (alpha x y A &optional conjp))

(deft/method t/ger! (sym standard-tensor) (alpha x y A &optional (conjp t))
  (using-gensyms (decl (alpha A x y))
   `(let (,@decl)
      (declare (type ,sym ,A ,x ,y)
	       (type ,(field-type sym) ,alpha))
      ;;These loops are optimized for column major matrices
      (unless (t/f= ,(field-type sym) ,alpha (t/fid+ ,(field-type sym)))
	(einstein-sum ,sym (j i) (ref ,A i j) (* ,alpha (ref ,x i)
						 ,(recursive-append
						   (when conjp `(t/fc ,(field-type sym)))
						   `(ref ,y j)))
		      nil))
      ,A)))
;;---------------------------------------------------------------;;
(defgeneric ger! (alpha x y A &optional conjugate-p)
  (:documentation
   "
  Syntax
  ======
  (GER! alpha x y A [job])

  Purpose
  =======
  Performs the GEneral matrix Rank-1 update given by
	       --             -

	    A <- alpha * x * op(y) + A

  and returns A.

  alpha is a scalars,
  x,y are vectors.
  A is a matrix.

  If conjugate-p is nil, then op(y) = y^T, else op(y) = y^H.
")
  (:method :before (alpha (x standard-tensor) (y standard-tensor) (A standard-tensor) &optional conjugate-p)
    (declare (ignore conjugate-p))
    (assert (and
	     (tensor-vectorp x) (tensor-vectorp y) (tensor-matrixp A)
	     (= (aref (the index-store-vector (dimensions x)) 0)
		(aref (the index-store-vector (dimensions A)) 0))
	     (= (aref (the index-store-vector (dimensions y)) 0)
		(aref (the index-store-vector (dimensions A)) 1)))
	    nil 'tensor-dimension-mismatch)))

(define-tensor-method ger! (alpha (x standard-tensor :input) (y standard-tensor :input) (A standard-tensor :output) &optional (conjugate-p t))
  `(let ((alpha (t/coerce ,(field-type (cl x)) alpha)))
     (declare (type ,(field-type (cl x)) alpha))
     ,(recursive-append
       (when (subtypep (cl x) 'blas-numeric-tensor)
	 `(if (call-fortran? A (t/l2-lb ,(cl a)))
	      (with-columnification (() (A))		  
		(if conjugate-p 
		    (t/blas-ger! ,(cl a)
				 alpha
				 x (aref (the index-store-vector (strides x)) 0)
				 y (aref (the index-store-vector (strides y)) 0)
				 A (or (blas-matrix-compatiblep A #\N) 0)
				 t)
		    (t/blas-ger! ,(cl a)
				 alpha
				 x (aref (the index-store-vector (strides x)) 0)
				 y (aref (the index-store-vector (strides y)) 0)
				 A (or (blas-matrix-compatiblep A #\N) 0)
				 nil)))))
       `(if conjugate-p
	    (t/ger! ,(cl a) alpha x y A t)
	    (t/ger! ,(cl a) alpha x y A nil))))
  'A)
;;---------------------------------------------------------------;;
(defgeneric ger (alpha x y A &optional conjugate-p)
  (:documentation
   "
  Syntax
  ======
  (GER alpha x y A [job])

  Purpose
  =======
  Performs the GEneral matrix Rank-1 update given by
	       --             -

	     alpha * x * op(y) + A

  and returns A.

  alpha is a scalars,
  x,y are vectors.
  A is a matrix.

  If conjugate-p is nil, then op(y) = y^T, else op(y) = y^H.
"))

(defmethod ger (alpha (x standard-tensor) (y standard-tensor)
		(A standard-tensor) &optional conjugate-p)
  (ger! alpha x y (copy A) conjugate-p))
