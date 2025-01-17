#lang curr/lib

@(design-recipe-exercise "lawn-area" "Use the Design Recipe to write a function 'lawn-area', which takes in the width and length of a lawn, and returns the area of the lawn. (Don't forget: area = length * width!)"
        #:lang 'pyret
			 #:domain-list (list "Number" "Number")
			 #:range "Number"
			 #:purpose "Produce area of lawn with given length and width"
                         #:num-examples 2
			 #:example-list (list (list 10 20 "10 * 20") (list 50 5 "50 * 5"))
                         #:param-list (list "length" "width")
                         #:show-params? #f
                         #:body "length * width"
                         #:show-body? #f
                         )
