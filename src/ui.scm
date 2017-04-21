(import (chibi show) (chibi))

(define <v3> (register-simple-type "<v3>" #f '(x y z)))
(define make-v3 (make-constructor "make-v3" <v3>))
(define (v3-x v) (slot-ref <v3> v 0))
(define (v3-y v) (slot-ref <v3> v 1))
(define (v3-z v) (slot-ref <v3> v 2))
(define (v3-x! v x) (slot-set! <v3> v 0 x))
(define (v3-y! v y) (slot-set! <v3> v 1 y))
(define (v3-z! v z) (slot-set! <v3> v 2 z))
(define v3? (make-type-predicate "v3?" <v3>))
(define (v3 x y z) (let ((v (make-v3))) (v3-x! v x) (v3-y! v y) (v3-z! v z) v))

(define (init)
	(define v (v3 1 2 3))
	(define size (ui:screen-size))
	(show #t "*** screen size: "(v3-x size) "/" (v3-y size) nl)
	;; (ui:set-next-window-pos 0 (/ (ui:screen-height) 2))
	;; (ui:begin "test-chibi")
	;; (ui:text "Simulating universe evolution n billion years.")
	;; (ui:end)
	)

(define (game)
	3)
(display "Hello from Chibi")
(newline)
