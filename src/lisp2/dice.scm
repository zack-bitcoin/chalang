;global variable
(var commit1
     commit2
     reveal1
     reveal2
     time_limit
     thr
     )
(forth
 --AHNhbHQ= reveal1 !
 --mLsUrLlcdD/h1PXMrWBMr1wyuByGLuvaIlevszzQxaQ= commit1 !
 --AXNhbHQ= reveal2 !
 --RxEPLwsUGfw5/sENnN90h7RY6oCyZKrnH9m+3CJXGRo= commit2 !
 5 time_limit !
 70 thr !)

(define (byte2int b)
  (++ --AAAA b))

(define (outcome r1 r2)
  (let (((_ x1) (split r1 1))
        ((_ x2) (split r2 1)))
    (> (@ thr)
       (rem (+ (byte2int x1)
               (byte2int x2))
            100))))

(define (valid_reveal r c)
  (= c (hash r)))

(define (main)
  (let ((v1 (valid_reveal (@ reveal1) (@ commit1)))
        (v2 (valid_reveal (@ reveal2) (@ commit2))))
    (cond ((and v1 v2)
            (return 0
                    2
                    (* 10000
                       (outcome (@ reveal1)
                             (@ reveal2)))))
           (v1 (return (@ time_limit)
                       1
                       0))
           (v2 (return (@ time_limit)
                       1
                       10000))
           (true print))))
(main)

;base64:encode(<<1, <<"salt">>/binary>>).
;<<"AXNhbHQ=">>
;base64:encode(hash:doit(<<1, <<"salt">>/binary>>)).
;<<"RxEPLwsUGfw5/sENnN90h7RY6oCyZKrnH9m+3CJXGRo=">>
;base64:encode(<<0, <<"salt">>/binary>>).
;<<"AHNhbHQ=">>
;base64:encode(hash:doit(<<0, <<"salt">>/binary>>)).
;<<"mLsUrLlcdD/h1PXMrWBMr1wyuByGLuvaIlevszzQxaQ=">>


