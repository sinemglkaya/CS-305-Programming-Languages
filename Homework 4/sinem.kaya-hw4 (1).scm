; will not take division or multiplier operator 
; + − when they are together there is no operator just operands
(define (twoOperatorCalculator list_input)
  (cond ((null? list_input) 0)
        ((equal? '+ (car list_input)) (twoOperatorCalculator (cdr list_input)))
        ((equal? '- (car list_input)) (twoOperatorCalculator (cons (- (cadr list_input)) (cddr list_input))))
        (else (+ (car list_input) (twoOperatorCalculator (cdr list_input))))))


; evaluate left-associative infix multiplication (*) and division (/) operations

(define fourOperatorCalculator 
	(lambda(list_input) 
		(cond 
		  ((null? list_input) #f)
			((eq? (length list_input) 2) #f)
			((and (eq? (length list_input) 1) (number? (car list_input))) (list (car list_input)))
			((not (number? (car list_input))) #f)
			((not (number? (caddr list_input))) #f)
			((or (eq? (cadr list_input) '+) (eq? (cadr list_input) '-)) 
				(cons (car list_input) (cons (cadr list_input) (fourOperatorCalculator (cddr list_input))))
			)
			((eq? (cadr list_input) '*) 
				(fourOperatorCalculator (cons (* (car list_input) (caddr list_input)) (cdddr list_input)))
			)
			((eq? (cadr list_input) '/) 
				(if (eq? (caddr list_input) 0)
					#f
					(fourOperatorCalculator (cons (/ (car list_input) (caddr list_input)) (cdddr list_input)))
				)
			)
			(else #f)
		)
	)
)


; handle operations within nested lists
(define (resolve_nested x)
  (if (pair? x)
      (twoOperatorCalculator (fourOperatorCalculator (calculatorNested x)))
      x))


(define (calculatorNested list_input)
	(map resolve_nested list_input)
)

; only allowed operations (addition, subtraction, multiplication, division, and nested lists).
(define checkOperators
  (lambda (list_input)
    (if (and (not (list? list_input)) (number? list_input))
        #f
        (if (and (not (list? list_input)) (symbol? list_input))
            #f
            (if (null? list_input)
                #f
                (if (and (list? (car list_input)) (null? (cdr list_input)))
                    (checkOperators (car list_input))
                    (if (and (list? (car list_input)) (not (null? (cdr list_input))))
                        (and (checkOperators (car list_input)) (checkOperators (cdr list_input)))
                        (if (and (number? (car list_input)) (null? (cdr list_input)))
                            #t
                            (if (and (number? (car list_input)) (not (null? (cdr list_input))))
                                (if (not (number? (cadr list_input)))
                                    (checkOperators (cdr list_input))
                                    #f
                                )
                                (if (and (number? (car list_input)) (null? (cdr list_input)))
                                    #t
                                    (if (not (and (or (eq? '+ (car list_input)) 
                                                      (eq? '- (car list_input)) 
                                                      (eq? '* (car list_input)) 
                                                      (eq? '/ (car list_input)))
                                                 (not (number? (car list_input)))))
                                        #f
                                        (if (and (or (eq? '+ (car list_input)) 
                                                     (eq? '- (car list_input)) 
                                                     (eq? '* (car list_input)) 
                                                     (eq? '/ (car list_input))) 
                                                (not (null? (cdr list_input))))
                                            (checkOperators (cdr list_input))
                                            (if (and (or (eq? '+ (car list_input)) 
                                                         (eq? '- (car list_input)) 
                                                         (eq? '* (car list_input)) 
                                                         (eq? '/ (car list_input))) 
                                                    (null? (cdr list_input)))
                                                #f
                                                #t
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
    )
)

(define (calculator list_input)
	(if (checkOperators list_input)
		(twoOperatorCalculator (fourOperatorCalculator (calculatorNested list_input)))
		#f))
