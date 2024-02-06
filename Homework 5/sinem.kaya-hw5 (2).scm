(define get-op (lambda (operator-symbol env) 
 
 (cond 
 ((equal? operator-symbol '+) +) 
 ((equal? operator-symbol '-) -) 
 ((equal? operator-symbol '*) *) 
 ((equal? operator-symbol '/) /) 
 (else (get-val operator-symbol env))
 )))
 
(define all-bindings-valid? (lambda (bindings)
  (cond
    ((null? bindings) #t) ; An empty list of bindings is valid
    ((and (pair? (car bindings)) (= (length (car bindings)) 2)) 
     (all-bindings-valid? (cdr bindings)))
    (else #f))))

(define if-stmt? (lambda (e)
  (and (list? e) (equal? (car e) 'if) (= (length e) 4))))

(define letstar-stmt? (lambda (e)
  (and (list? e) (equal? (car e) 'let*) (= (length e) 3))))
  
(define let-stmt? (lambda (e)
  (and (list? e) 
       (equal? (car e) 'let) 
       (= (length e) 3)
       (list? (cadr e)) ; the second element is a list
       (all-bindings-valid? (cadr e)))))

(define define-stmt? (lambda (e)
  (and (list? e) (equal? (car e) 'define) (symbol? (cadr e)) (= (length e) 3))))

(define formal-list? (lambda (e)
  (and (list? e) (symbol? (car e)) (or (null? (cdr e)) (formal-list? (cdr e))))))
  
(define lambda-short-stmt? (lambda (e)
  (and (list? e) (equal? (car e) 'lambda) (formal-list? (cadr e)) (not (define-stmt? (caddr e))))))
  
(define is-optrue? (lambda (o)
  (cond 
   ((eq? o '+) "[PROCEDURE]")
   ((eq? o '-) "[PROCEDURE]")
   ((eq? o '/) "[PROCEDURE]")
   ((eq? o '*) "[PROCEDURE]")
   (else #f)
  )))


(define valid-function?
  (lambda (sym env)
    (cond
      ((null? env) #f) 
      ((eq? (caar env) sym) 
       (let ((val (cdar env)))
         (or (procedure? val)  ; 
             (and (pair? val) (eq? (car val) 'lambda)))))
      (else (valid-function? sym (cdr env)))))) 

 
(define get-val (lambda (var env)
	(cond 
	((null? env) "ERROR") 
	((equal? (caar env) var) (cdar env)) 
	(else (get-val var (cdr env))))))
	
(define extended-env (lambda (var val old-env) 
(cons (cons var val) old-env)))

(define repl (lambda (env) 
  (let* ((dummy1 (display "cs305> "))
         (expr (read))
         (new-env (if (define-stmt? expr) 
                      (extended-env (cadr expr) (s7-HW5 (caddr expr) env) env) 
                      env))
         (val (if (define-stmt? expr) 
                  (cadr expr) 
                  (s7-HW5 expr env)))
         (display-val (if (and (pair? val) (eq? (car val) 'lambda)) 
                           "[PROCEDURE]" 
                           val))
         (dummy2 (display "cs305: "))
         (dummy3 (display display-val))
         (dummy4 (newline))
         (dummy5 (newline)))
    (repl new-env))))


(define s7-HW5 (lambda (e env) 

(cond 
 
 ((number? e) e)
 ((symbol? e) (let ((normal (is-optrue? e)))
                (if normal normal (get-val e env))))
 ((not (list? e)) (error "ERROR" e))
 
 ((if-stmt? e) (if (eq? (s7-HW5 (cadr e) env) 0) 
                    (s7-HW5 (cadddr e) env) 
                    (s7-HW5 (caddr e) env)))
  ((let-stmt? e)
      (let ((names (map car  (cadr e)))
            (inits (map cadr (cadr e))))
        (let ((vals (map (lambda (init) (s7-HW5 init env)) inits)))
          (let ((new-env (append (map cons names vals) env)))
            (s7-HW5 (caddr e) new-env)
            )
          )
        )
      )
			
 
 ((letstar-stmt? e) (if (= (length (cadr e)) 1) 
		(let ((l (list 'let (cadr e) (caddr e))))    (let ((names (map car (cadr l))) (inits (map cadr (cadr l)))) 
																		(let ((vals (map (lambda (init) (s7-HW5 init env)) inits)))
																			(let ((new-env (append (map cons names vals) env)))
																				(s7-HW5 (caddr l) new-env)
                                        )
                                      )
                                    )
                                  )
		(let ((first (list 'let (list (caadr e)))) (rest (list 'let* (cdadr e) (caddr e)))) 
										(let ((l (append first (list rest)))) (let ((names (map car (cadr l))) (inits (map cadr (cadr l))))
														(let ((vals (map (lambda (init) (s7-HW5 init env)) inits)))
																		(let ((new-env (append (map cons names vals) env)))
																			(s7-HW5 (caddr l) new-env)
                                      )
                                    )
                                  )
                                )
                              )
                            )
                          )

 ((lambda-short-stmt? e) e)                       						
 (else
 
 (cond
	((lambda-short-stmt? (car e)) (if (= (length (cadar e)) (length (cdr e)))
											(let* ((par (map s7-HW5 (cdr e) (make-list (length (cdr e)) env))) (nenv (append (map cons (cadar e) par) env))) (s7-HW5 (caddar e) nenv))
											(error "ERROR")
                      )
                    )


	((is-optrue? (car e)) (let ((operands (map s7-HW5 (cdr e) (make-list (length (cdr e)) env))) (operator (get-op (car e) env)))
		(cond ;for the exceptions, write the cases
		                                          ((and (equal? operator '+) (= (length operands) 0)) 0) 
												  ((and (equal? operator '*) (= (length operands) 0)) 1) ;if no operands in multiplication, it is 1. 
												  ((and (or (equal? operator '-) (equal? operator '/)) (= (length operands) (or 0 1))) (error "ERROR" operator))
												  (else (apply operator operands))
												  )
                        )
                      )

    ((not (valid-function? (car e) env)) "ERROR")
  	(else (let* ((result (s7-HW5 (list (get-val (car e) env) (cadr e)) env))) result))))
    )
  )
)

(define cs305 (lambda () (repl '())))
