
(define (sort_setup l)
  (cond ((= l nil) nil)
        (true (cons (cons (car l)
                          nil)
                    (sort_setup (cdr l))))))
;(sort_setup (tree 1 2 3 4))
(define (merge f l m)
  (cond ((= l nil) m)
        ((= m nil) l)
        (((car l) (car m) (call (@ f)))
         (cons (car l)
               (merge f (cdr l) m)))
        (true (cons (car m)
                    (merge f l (cdr m))))))
;(merge (tree 5 3 1) (tree 4 2 0))
(define (sort_improve f l)
  (cond ((= l nil) nil)
        ((= (cdr l) nil) l)
        (true (cons (merge f
                           (car l)
                           (car (cdr l)))
                    (sort_improve f (cdr (cdr l)))))))
;(sort_improve (sort_improve(sort_improve (tree (6) (5) (7) (3)))))
(define (sort2 f l)
  (cond ((= (cdr l) nil) (car l))
        (true (sort2 f (sort_improve f l)))))
;(sort2 (tree (6)(5)(7)(3)))

(define (sort f l)
  (sort2 f (sort_setup l)))
(define (lt a b) (< a b))
(define (gt a b) (> a b))

(var (L (tree 5 3 2 9 4 2)))
(= (sort 'lt (@ L))
   (reverse (sort 'gt (@ L))))
