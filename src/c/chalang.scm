#! /usr/bin/csi -script
(import
 (chicken process-context)
 (chicken io)
 (chicken string)
 srfi-69
 message-digest-primitive
 sha2
 message-digest-byte-vector
 string-hexadecimal
 elliptic-curves
 )

;elliptic curve says it also needs:

;    srfi-1
;    srfi-99
;    matchable
;    modular-arithmetic

; to install `sudo chicken-install elliptic-curves`


; cryptography tools
; the hash of a list of bytes
(define (number->string2 x)
  (let ((a (number->string x 16)))
    (cond ((eq? 1 (string-length a))
           (string-append "0" a))
          (else a))))
(define (bytes_to_hex b)
  (cond ((eq? b '()) "")
        (else (string-append
               (number->string2 (car b))
               (bytes_to_hex (cdr b))))))
(define (hex_to_bytes2 l)
  (cond ((eq? l '()) '())
        (else (cons (string->number (car l) 16)
                    (hex_to_bytes2 (cdr l))))))
(define (hex_to_bytes h)
  (hex_to_bytes2 (string-chop h 2)))
(define (hash-hex hex)
  (message-digest-string
   (sha256-primitive)
   (hex->string hex)))
(define (hash_binary bytes)
  (cons 'binary (hex_to_bytes
                 (hash-hex
                  (bytes_to_hex
                   (cdr bytes))))))

; elliptic curve stuff
(define-ec-parameters secp256k1
  "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F"
  "0000000000000000000000000000000000000000000000000000000000000000"
  "0000000000000000000000000000000000000000000000000000000000000007"
  "79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798"
  "483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8"
  "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141"
  "01"
  )

(define (verify_sig data sig pub)
  (write pub) (newline)
  (write data) (newline)
  (write sig) (newline)
;Given elliptic curve parameters, a signature verification procedure is generated that checks a signature given the public key P of the signer, the original message and the signature.
;The message is a number and the signature is a pair of two numbers.
                                        ;For practical applications, you should convert some message digest into a number with the same bit length as the base point order of the elliptic curve and pass it as the message argument.
                                        ; The public key is a point on the elliptic curve
  
  (write ((ecc-verify secp256k1) pub message sig))
  (newline)
  ;return a 1 if the signature is value, 0 otherwise.
  0)

;the opcodes
(define int4 0)
(define binary 2)
(define int1 3)
(define int2 4)
(define print_op 10)
(define return 11)
(define nop 12)
(define fail 13)
(define drop 20)
(define dup 21)
(define swap 22)
(define tuck 23)
(define rot 24)
(define ddup 25)
(define tuckn 26)
(define pickn 27)
(define to_r 30)
(define from_r 31)
(define r_fetch 32)
(define hash_op 40)
(define verify_sig 41)
(define add 50)
(define subtract 51)
(define mul 52)
(define divide 53)
(define gt 54)
(define lt 55)
(define pow 56)
(define rem 57)
(define eq 58)
(define eq2 59)
(define caseif 70)
(define caseelse 71)
(define casethen 72)
(define bool_flip 80)
(define bool_and 81)
(define bool_or 82)
(define bool_xor 83)
(define bin_and 84)
(define bin_or 85)
(define bin_xor 86)
(define stack_size 90)
(define height 94)
(define gas 96)
(define ram 97)
(define many_vars 100)
(define many_funs 101)
(define define_op 110)
(define define2 114)
(define fun_end 111)
(define recurse 112)
(define call 113)
(define set_op 120)
(define fetch_op 121)
(define cons_op 130)
(define car_op 131)
(define nil_op 132)
(define append_op 134)
(define split 135)
(define reverse_op 136)
(define is_list 137)

;integers need to be less than this max value.
(define max_value 4294967296)

;functions to build the database
(define (list_maker length default)
  (cond ((eq? length 0) '())
        (else (cons
               default
               (list_maker
                (- length 1)
                default)))))
(define (build_vars many)
  (list->vector (list_maker many 0)))

(define (build_state
         op_gas ram_limit fun_limit
         state_height many_vars)
  (vector '() '() op_gas ram_limit
          0 0 0 ;ram_current ram_most many_funs
          fun_limit state_height
          (build_vars many_vars)
          (make-hash-table)))

;functions to use the database
(define (get_stack state)
  (vector-ref state 0))
(define (set_stack stack state)
  (vector-set! state 0 stack))
(define (get_alt state)
  (vector-ref state 1))
(define (set_alt alt state)
  (vector-set! state 1 alt))
(define (get_op_gas state)
  (vector-ref state 2))
(define (set_op_gas gas state)
  (vector-set! state 2 gas))
(define (get_ram_limit state)
  (vector-ref state 3))
(define (get_ram_current state)
  (vector-ref state 4))
(define (set_ram_current ram state)
  (vector-set! state 4 ram))
(define (get_ram_most state)
  (vector-ref state 5))
(define (set_ram_most ram state)
  (vector-set! state 5 ram))
(define (get_many_funs state)
  (vector-ref state 6))
(define (set_many_funs many state)
  (vector-set! state 6 many))
(define (get_fun_limit state)
  (vector-ref state 7))
(define (get_state_height state)
  (vector-ref state 8))
(define (get_many_vars state)
  (vector-length (vector-ref state 9)))
(define (get_var n state)
  (vector-ref (vector-ref state 9) n))
(define (set_var val n state)
   (vector-set! (vector-ref state 9)
                n val))
(define (get_fun key state)
  (hash-table-ref (vector-ref state 10) key))
(define (set_fun key val state)
   (hash-table-set! (vector-ref state 10)
                    key val))

;functions to load command line arguments and start chalang.
(set! input '())
(define (read-byte2)
  (cond ((eq? input '()) (read-byte))
        (else (let ((x (car input)))
                (set! input (cdr input))
                x))))
(define cla (list->vector (command-line-arguments)))
(define (main)
  (set! op_gas 10000)
  (set! ram_limit 10000)
  (set! fun_limit 100)
  (set! many_vars_config 10)
  (set! state_height 200000)
  (cond ((> (vector-length cla) 0)
         (set! op_gas (string->number
                       (vector-ref cla 0)))))
  (cond ((> (vector-length cla) 1)
         (set! ram_limit (string->number
                       (vector-ref cla 1)))))
  (cond ((> (vector-length cla) 2)
         (set! fun_limit (string->number
                       (vector-ref cla 2)))))
  (cond ((> (vector-length cla) 3)
         (set! many_vars_config (string->number
                       (vector-ref cla 3)))))
  (cond ((> (vector-length cla) 4)
         (set! state_height (string->number
                       (vector-ref cla 4)))))
  (set! state
        (build_state op_gas ram_limit fun_limit
                     state_height many_vars_config))
  (chalang state))

;some integers and also quantities for how big
;binaries are, they are written as 4 byte integers.
(define (read_4_bytes_to_int)
  (+ (* 256
        (+ (* 256
              (+ (* 256 (read-byte2))
                 (read-byte2)))
           (read-byte2)))
     (read-byte2)))

(define (list_4_to_int l)
  (+ (* 256
        (+ (* 256
              (+ (* 256 (car l))
                 (car (cdr l))))
           (car (cdr (cdr l)))))
     (car (cdr (cdr (cdr l))))))

;reading a function from the source code
(define (read-fun)
  (let ((c (read-byte2)))
    (cond ((eq? c fun_end) '())
          (else (cons c (read-fun))))))

;tools for processing binaries
(define (read_binary2 x)
  (cond ((eq? x 0) '())
        (else
         (cons
          (read-byte2)
          (read_binary2 (- x 1))))))
(define (read_binary x)
  (cons 'binary (read_binary2 x)))
(define (is_binary l)
  (and (< 0 (length l))
       (eq? 'binary (car l))))
(define (split_helper n l l2)
  (cond ((eq? n 0) (cons (reverse l2)
                         (cons l '())))
        (else (split_helper
               (- n 1)
               (cdr l)
               (cons (car l) l2)))))
(define (split_list n l)
  (split_helper n l '()))
(define (split_binary n l)
  (let* ((pair (split_helper n (cdr l) '()))
         (a (cons 'binary (car pair)))
         (b (cons 'binary (car (cdr pair)))))
    (cons a (cons b '()))))


;tools for manipulating lists
(define (list_not_binary l)
  ;checks if it is a list
  (and (list? l)
       (or (eq? 0 (length l))
           (not (eq? (car l)
                     'binary)))))
(define (insert x position l)
  (cond ((eq? position 0) (cons x l))
        (else (cons (car l)
                    (insert x (- position 1)
                            (cdr l))))))
(define (nth n l)
  (cond ((eq? n 0) (car l))
        (else (nth (- n 1)
                   (cdr l)))))
(define (remove_nth n l)
  (cond ((eq? n 0) (cdr l))
        (else (cons (car l)
                    (remove_nth (- n 1)
                                (cdr l))))))

;skip unexecuted branch of a conditional.
(define (skip_passed x)
  (let ((c (read-byte2)))
    (cond ((eq? x c) 0);done
          ((eq? c caseif)
           (skip_passed casethen)
           (skip_passed x))
          ((eq? c int4)
           (read_4_bytes_to_int)
           (skip_passed x))
          ((eq? c int2)
           (read-byte2)
           (read-byte2)
           (skip_passed x))
          ((eq? c int1)
           (read-byte2)
           (skip_passed x))
          ((eq? c binary)
           (read_binary (read_4_bytes_to_int))
           (skip_passed x))
          (else (skip_passed x)))))

;end the program if things go wrong.
(define (fail message state)
  (write "failed: ")
  (write message)
  (newline)
  (set_stack '() state)
  (set_op_gas 0 state))

(define (replace old new code)
  (cond
   ((eq? code '()) '())
   (else
    (let* ((c (car code))
           (code2 (cdr code)))
      (cond ((eq? c int4)
             (let* ((pair (split_list 4 code2))
                    (a (car pair))
                    (b (car (cdr pair))))
               (cons
                c (append
                   a (replace old new b)))))
            ((eq? c int2)
             (let* ((pair (split_list 2 code2))
                    (a (car pair))
                    (b (car (cdr pair))))
               (cons
                c (append
                   a (replace old new b)))))
            ((eq? c int1)
             (cons
              c (cons
                 (car code2)
                 (replace old new (cdr code2)))))
            ((eq? c binary)
             (let* ((pair (split_list 4 code2))
                    (n (list_4_to_int (car pair)))
                    (pair2 (split_list n (car (cdr pair))))
                    (binary (car pair2))
                    (code3 (car (cdr pair2))))
               (cons
                c (append (car pair)
                          (append binary
                                  (replace old new code3))))))
            ((eq? c old)
             (append new (replace old new code2)))
            (else
             (cons c (replace old new code2))))))))


;chalang vm
(define (chalang state)
  (let* ((c (read-byte2))
         (s (get_stack state)))
    ;(write c)
    ;(newline)
    (cond
     ;termination cases
     ((eq? c #!eof)
      s)
     ((eq? c return)
      s)
     ((eq? c fail)
      (write "failed")
      (newline)
      (fail "fail opcode" state)
      s)
     (else
      (cond
       
       ;loading data into the stack
       ((eq? c binary)
        (set_stack
         (cons
          (read_binary (read_4_bytes_to_int))
          s)
         state))
      
       ((eq? c int4)
        (set_stack
         (cons
          (read_4_bytes_to_int)
          s)
         state))
       
       ((eq? c int2)
        (set_stack
         (cons
          (+ (* 256
                (read-byte2))
             (read-byte2))
          s)
         state))
       
       ((eq? c int1)
        (set_stack
         (cons
          (read-byte2)
          s)
         state))
       
       ((and (> c 139)
             (< c 176))
        (set_stack
         (cons
          (- c 140)
          s)
         state))

       ;conditionals
       ((and (eq? c caseif)
             (eq? 0 (car s)))
        (skip_passed caseelse)
        (set_stack (cdr s) state))

       ((eq? c caseif)
        (set_stack
         (cdr s)
         state))

       ((eq? c caseelse)
        (skip_passed casethen))

       ((eq? c casethen)
        0)

       ;functions
       ((eq? c call)
        ;tail call optimization
        (let ((d (read-byte2))
              (f_name (car s)))
          (cond ((eq? d fun_end) 0)
                (else (set! input (cons d input))))
        ;now call the function
          (set_stack (cdr s) state)
          (set! input (append (get_fun f_name state)
                              input))))

       ((eq? c define_op)
        (let* ((f (read-fun))
               (name (hash_binary
                      (cons 'binary f)))
               (f2 (replace recurse
                            (append
                             '(2 0 0 0 32)
                             (cdr name))
                            f)))
          (set_fun name f2 state)))

       ((eq? c define2)
        (let* ((f (read-fun))
               (name (hash_binary
                      (cons 'binary f)))
               (f2 (replace recurse
                            (append
                             '(2 0 0 0 32)
                             (cdr name))
                            f)))
          (set_fun name f2 state)
          (set_stack
           (cons name s)
           state)))

       ;boolean logic
       ((eq? c bool_and)
        (let* ((a (car s))
               (b (car (cdr s)))
               (result
                (cond ((eq? a 0) 0)
                      ((eq? b 0) 0)
                      (else 1))))
          (set_stack
           (cons
            result (cdr (cdr s)))
           state)))

       ((eq? c bool_or)
        (let* ((a (car s))
               (b (car (cdr s)))
               (result
                (cond ((and (eq? a 0)
                            (eq? b 0))
                       0)
                      (else 1))))
          (set_stack
           (cons
            result (cdr (cdr s)))
           state)))

       ((eq? c bool_xor)
        (let* ((a (car s))
               (b (car (cdr s)))
               (result
                (cond ((and (eq? a 0)
                            (eq? b 0))
                       0)
                      ((eq? a 0) 1)
                      ((eq? b 0) 1)
                      (else 0))))
          (set_stack
           (cons
            result (cdr (cdr s)))
           state)))

       ((eq? c bool_flip)
        (let* ((a (car s))
               (result
                (cond ((eq? a 0) 1)
                      (else 0))))
          (set_stack
           (cons
            result (cdr s))
           state)))

       ((eq? c eq2)
        (let* ((a (car s))
               (b (car (cdr s)))
               (result 
                (cond ((equal? a b) 1)
                      (else 0))))
          (set_stack
           (cons
            result (cdr (cdr s)))
           state)))

       ((eq? c eq)
        (let* ((a (car s))
               (b (car (cdr s)))
               (result 
                (cond ((equal? a b) 1)
                      (else 0))))
          (set_stack
           (cons result s)
           state)))

       ;operations on the stack
       ((eq? c drop)
        (set_stack (cdr s)
                   state))

       ((eq? c dup)
        (set_stack (cons (car s) s)
                   state))

       ((eq? c swap)
        (let* ((b (car (cdr s))))
          (set_stack
           (cons b (cons (car s)
                         (cdr (cdr s))))
           state)))

       ((eq? c tuck)
        (let* ((a1 (car s))
               (a2 (car (cdr s)))
               (a3 (car (cdr (cdr s)))))
          (set_stack
           (cons
            a2 (cons
                a3 (cons
                    a1 (cdr (cdr (cdr s))))))
           state)))

       ((eq? c rot)
        (let* ((a1 (car s))
               (a2 (car (cdr s)))
               (a3 (car (cdr (cdr s)))))
          (set_stack
           (cons 
            a3 (cons
                a1 (cons
                    a2 (cdr (cdr (cdr s))))))
           state)))

       ((eq? c ddup)
        (let* ((a (car s))
               (b (car (cdr s))))
          (set_stack
           (cons a (cons b s))
           state)))

       ((eq? c tuckn)
        (let* ((position (car s))
               (x (car (cdr s)))
               (s2 (cdr (cdr s))))
          (set_stack (insert x position s2)
                     state)))

       ((eq? c pickn)
        (let* ((position (car s))
               (s2 (cdr s))
               (a (nth position s2))
               (s3 (remove_nth position s2)))
          (set_stack (cons a s3)
                     state)))

     ;alt stack operations
       ((eq? c to_r)
        (let* ((alt (get_alt state)))
          (set_stack (cdr s) state)
          (set_alt (cons (car s) alt) state)))

       ((eq? c from_r)
        (let* ((alt (get_alt state)))
          (set_stack (cons (car alt) s) state)
          (set_alt (cdr alt) state)))

       ((eq? c r_fetch)
        (let* ((alt (get_alt state))
              (a (car alt)))
          (set_stack (cons a s) state)))

       ;crypto opcodes
       ((eq? c hash_op)
        (set_stack (cons (hash_binary (car s))
                         (cdr s))
                   state))

       ((eq? c verify_sig)
        (let* ((pub (car s))
               (data (car (cdr s)))
               (sig (car (cdr (cdr s))))
               (s2 (cdr (cdr (cdr s))))
               (result (verify_sig data sig pub)))
          (set_stack (cons result s2)
                     state)))
          
       ;arithmetic opcodes
       ((eq? c add)
        (let* ((a (car s))
               (b (car (cdr s)))
               (a2 (remainder (+ a b) max_value))
               (s2 (cdr (cdr s))))
          (set_stack (cons a2 s2)
                     state)))

       ((eq? c subtract)
        (let* ((a (car s))
               (b (car (cdr s)))
               (a2 (remainder (- b a) max_value))
               (s2 (cdr (cdr s))))
          (set_stack (cons a2 s2)
                     state)))
       
       ((eq? c mul)
        (let* ((a (car s))
               (b (car (cdr s)))
               (a2 (remainder (* b a) max_value))
               (s2 (cdr (cdr s))))
          (set_stack (cons a2 s2)
                     state)))

       ((eq? c divide)
        (let* ((a (car s))
               (b (car (cdr s)))
               (r (remainder b a))
               (a2 (/ (- b r) a))
               (s2 (cdr (cdr s))))
          (set_stack (cons a2 s2)
                     state)))

       ((eq? c gt)
        (let* ((a (car s))
               (b (car (cdr s)))
               (s2 (cdr (cdr s)))
               (result
                (cond ((> b a) 1)
                      (else 0))))
          (set_stack (cons result s2)
                     state)))

       ((eq? c lt)
        (let* ((a (car s))
               (b (car (cdr s)))
               (s2 (cdr (cdr s)))
               (result
                (cond ((< b a) 1)
                      (else 0))))
          (set_stack (cons result s2)
                     state)))

       ((eq? c pow)
        (let* ((a (car s))
               (b (car (cdr s)))
               (a2 (remainder (expt b a)
                              max_value))
               (s2 (cdr (cdr s))))
          (set_stack (cons a2 s2)
                     state)))
        
       ((eq? c rem)
        (let* ((a (car s))
               (b (car (cdr s)))
               (a2 (remainder b a))
               (s2 (cdr (cdr s))))
          (set_stack (cons a2 s2)
                     state)))

       ;meta data about vm
       ((eq? c stack_size)
        (set_stack
         (cons (length s) s)
         state))

       ((eq? c height)
        (set_stack
         (cons (get_state_height
                state) s)
         state))

       ((eq? c gas)
        (set_stack
         (cons (get_op_gas state)
               s)
         state))


       ((eq? c many_vars)
        (set_stack
         (cons (get_many_vars state)
               s)
         state))
       
       ((eq? c many_funs)
        (set_stack
         (cons (get_many_funs state)
               s)
         state))

       ((eq? c fun_end)
        0)


       ;variables
       ((eq? c set_op)
        (let* ((key (car s))
               (value (car (cdr s)))
               (s2 (cdr (cdr s))))
          (set_stack s2 state)
          (set_var value key state)))

       ((eq? c fetch_op)
        (let* ((key (car s)))
          (set_stack (cons (get_var key state)
                           (cdr s)) state)))

       ;operations on lists
       ((eq? c cons_op)
        (let* ((a (car s))
               (b (car (cdr s)))
               (s2 (cdr (cdr s))))
          (set_stack (cons (cons b a)
                           s2)
                     state)))

       ((eq? c car_op)
        (let* ((a1 (car s))
               (b (car a1))
               (a (cdr a1))
               (s2 (cdr s)))
          (set_stack (cons a (cons b s2))
                     state)))

       ((eq? c nil_op)
        (set_stack (cons '() s) state))

       ((eq? c append_op)
        (let* ((a (car s))
               (b (car (cdr s)))
               (pair
                (cond ((and (is_binary a)
                            (is_binary b))
                       (append b (cdr a)))
                      ((and (list_not_binary a)
                            (list_not_binary b))
                       (append b a))
                      (else (fail "cannot append those" state)
                            '(0 0)))))
          (set_stack (cons pair (cdr (cdr s)))
                     state)))
               

       ((eq? c split)
        (let* ((n (car s))
               (l (car (cdr s)))
               (pair (split_binary n l))
               (a (car pair))
               (b (car (cdr pair)))
               (s2 (cdr (cdr s))))
          (set_stack (cons a (cons b s2))
                     state)))

       ((eq? c reverse_op)
        (set_stack (cons (reverse (car s))
                         (cdr s))
                   state))

       ((eq? c is_list)
        (let ((a (car s))
              (result
               (cond
                ((list_not_binary a) 1)
                (else 0))))
          (set_stack (cons result s)
                     state)))

       ;other opcodes
       ((eq? c nop) 0)

       ((eq? c print_op)
        (write s)
        (newline)
        ;(write (get_alt state))
        ;(newline)
        ;(newline)
        )

       (else
        (write "undefined byte: " )
        (write c)
        (newline)
        (fail "undefined byte: " state)))
    (chalang state)))))


;turn it on
(main)

