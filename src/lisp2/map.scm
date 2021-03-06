(define (map f l)
  (cond ((= l nil) nil)
        (true (cons ((car l)
                     (call (@ f)))
                    (recurse f (cdr l))))))
(define (square x) (* x x))
(map 'square (tree 1 2 3 4))

(define (fold f a l)
  (cond ((= l nil) a)
        (true (fold f ((car l)
                       a
                       (call (@ f)))
                    (cdr l)))))
(define (sum a b) (+ a b))
(fold 'sum 0 (tree 1 2 3 4 5))

(define (or_up a b) (or b (= a 3)))
(fold 'or_up 0 (tree 1 3 10 2))

(define (filter f l)
  (cond ((= l nil) nil)
        (((car l) (call (@ f)))
         (cons (car l)
               (filter f (cdr l))))
        (true (filter f (cdr l)))))
(define (odd? x) (rem x 2))
(filter 'odd? (tree 0 1 2 3 4 5))
