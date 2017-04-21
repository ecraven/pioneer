;; (put 'with-font 'scheme-indent-function 2)
;; (put 'with-window 'scheme-indent-function 2)
;; (put 'with-style-colors 'scheme-indent-function 1)
(define (with-output-to-string thunk)
  (call-with-output-string
    (lambda (out)
      (let ((old-out (current-output-port)))
        (current-output-port out)
        (thunk)
        (current-output-port old-out)))))

(import (chibi show) (chibi))
;; c++?
(define <v3> (register-simple-type "<v3>" #f '(x y z)))
(define make-v3 (make-constructor "make-v3" <v3>))
(define (v3-x v) (slot-ref <v3> v 0))
(define (v3-y v) (slot-ref <v3> v 1))
(define (v3-z v) (slot-ref <v3> v 2))
(define (v3-x! v x) (slot-set! <v3> v 0 x))
(define (v3-y! v y) (slot-set! <v3> v 1 y))
(define (v3-z! v z) (slot-set! <v3> v 2 z))
(define v3? (make-type-predicate "v3?" <v3>))
;; c++?

(define (v3 x y z) (let ((v (make-v3))) (v3-x! v x) (v3-y! v y) (v3-z! v z) v))
(define (v2 x y) (let ((v (make-v3))) (v3-x! v x) (v3-y! v y) (v3-z! v 0) v))
(define-syntax with-window
	(syntax-rules ()
		((with-window name options body0 body ...)
		 (begin (ui:begin name options)
						body0 body ...
						(ui:end)))))
(define-syntax with-font
	(syntax-rules ()
		((with-font name size body0 body ...)
		 (begin (ui:push-font name size)
						body0 body ...
						(ui:pop-font)))))
(define-syntax with-style-colors
	(syntax-rules ()
		((with-style-colors ((name value) ...) body0 body ...)
		 (begin (ui:push-style-color 'name value)
						...
						body0 body ...
						(ui:pop-style-color (length '(name ...)))))))
(define (rgb r g b)
	(+ r
		 (* 256 g)
		 (* 256 256 b)
		 (* 256 256 256 255)))
(define highlight (rgb 0 63 112))
(define base (rgb 0 1 33))
(define (init frac)
	(define screen-size (ui:screen-size))
	(define screen-width (v3-x screen-size))
	(define screen-height (v3-y screen-size))
	(ui:set-next-window-pos (v2 0 (/ screen-height 2)))
	;; (ui:set-next-window-size (v3 (ui:screen-width) (ui:screen-height) 0))
	(with-font "orbiteer" 18
		(with-window "test-chibi" '(no-title-bar no-resize no-move)

			(let* ((age (exact->inexact (/ (inexact->exact (round (* 137 frac))) 10)))
						 (str (string-append "Simulating evolution of the universe: " (number->string age) " billion years ;-)")) ;; 
						 (size (ui:calc-text-size str)))
				(ui:dummy (v2 (/ (- screen-width (v3-x size)) 2) 0))
				(ui:same-line)
				(ui:text str)
				(ui:dummy (v2 15 15))
				(ui:dummy (v2 (/ screen-width 4) 0))
				(ui:same-line)
				(with-style-colors ((plot-histogram highlight)
														(frame-bg base))
					(ui:progress-bar frac (v2 (/ screen-width 2) 25) ""))))))

(define (game)
	(show #t (ui:player-max-delta-v) "  " (ui:player-current-delta-v) "  " (ui:player-remaining-delta-v) nl)
	)

(display "Hello from Chibi")
(newline)
