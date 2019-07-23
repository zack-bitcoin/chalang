
                                        ;(tree ((1) 2))
;(= 6
;   (let (((_ _ _ d) (1 2 3 4))
;         ((a b c) (5 6 7)))
;     (+ d 2)))

;(
; (var (Z 3))
; (define (f) (@ Z))
; (f)
; )
;(f) <-- this returns an error because function f does not exist here. Z doesn't exist either.
;(var (Z 4) A)
;(define (f) (@ Z))
;(= (+ 1
;      (@ A))
;   (f))

(define (f2)
  ((var (C 7))))
;   (@ C)))
;(f2)
(define (f1)
  (
   (var (C 6))
   (f2)
   (@ C)))
(f1)


;(forth and and)
