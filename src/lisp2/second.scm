
                                        ;(tree ((1) 2))
(let (((_ _ _ d) (1 2 3 4))
      ((a b c) (5 6 7)))
  (+ d 2))

(
 (var (Z 3))
 (define (f) (@ Z))
 (f)
 )
;(f) <-- this returns an error because function f does not exist here.
(var (Z 4))
(define (f) (@ Z))
(f)
