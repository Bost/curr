#lang racket/base

(require racket/runtime-path
         ;(except-in racket/contract contract-exercise)
         racket/string
         scribble/base
         scribble/core
         scribble/decode
         scribble/basic
         scribble/html-properties
         (prefix-in xml: scribble/html/xml)
         scriblib/render-cond
         racket/path
         (for-syntax racket/base racket/syntax)
         2htdp/image
         racket/list
         net/uri-codec
         racket/match
         "compile-time-params.rkt"
         "system-parameters.rkt"
         "checker.rkt"
         "sxml.rkt"
         "paths.rkt"
         "scribble-helpers.rkt"
         "standards-csv-api.rkt"
         "standards-dictionary.rkt"
         "auto-format-within-strings.rkt"
         "workbook-index-api.rkt"
         "styles.rkt"
         "process-code.rkt"
         "design-recipe-generator.rkt"
         "exercise-generator.rkt"
	       "math-rendering.rkt"
         "wescheme.rkt"
         "translator.rkt"
         "warnings.rkt"
         (for-syntax syntax/parse)
         )
 
;; FIXME: must add contracts!
(provide vocab
         code
         math
         bannerline
         boxed-text
         new-paragraph
         animated-gif
         image-with-alt-text
         language-table
         build-table/cols
         design-recipe-exercise
         assess-design-recipe
         unit-summary/links
         summary-item/links
         summary-item/custom
         summary-item/unit-link
         summary-item/no-link
         matching-exercise
         matching-exercise-answers
         completion-exercise
         open-response-exercise
         questions-and-answers
         circeval-matching-exercise/code
         circeval-matching-exercise/math
         fill-in-blank-answers-exercise
         sexp
         sexp->math
         sexp->coe
         sexp->code
         make-exercise-locator
         make-exercise-locator/file
         exercise-handout
         exercise-answers
         exercise-evid-tags
         solutions-mode-on?
         create-itemlist
         create-exercise-itemlist
         create-exercise-itemlist/contract-answers
         create-exercise-sols-itemlist
         matching-exercise-sols
         three-col-exercise
         three-col-answers
         editor-link
         run-link
         login-link
         resource-link
         [rename-out [worksheet-link/src-path worksheet-link]]
         insert-comment
         insert-menu-ssi
         lulu-button
         logosplash
         embedded-wescheme
         new-tab
                
         ;; lesson formatting
         lesson/studteach
         pacing
         points
         point
         student
         teacher
         itemlist/splicing ;; need because algebra teachers-guide.scrbl using it (still in old lesson format)
         activity
         unit-descr
         main-contents
         slidebreak
         slideText
         noSlideText
         
         ;; Unit sections
         exercises
         materials
         objectives
         product-outcomes
         preparation
         agenda
         copyright

         
         ;; Include lesson/lesson link
         include-lesson
         lesson-link
         unit-link

         ;; Unit summaries
         unit-length
         unit-overview/auto
         unit-lessons
         length-of-lesson
         bootstrap-title
         augment-head
         
         ;; styles directly referenced in files
         bs-coursename-style
                  
         )        



;;;;;;;;;;;; Runtime paths and settings ;;;;;;;;;;;;;;;;;;;;;;;

(define-runtime-path worksheet-lesson-root (build-path 'up "lessons"))
(define-runtime-path logo.png "logo.png")

;; determine whether we are currently in solutions-generation mode
;; need two versions of this: one for syntax phase and one for runtime
(define (solutions-mode-on?)
  (let ([env (getenv "CURRENT-SOLUTIONS-MODE")])
    ;(printf "Solutions mode is ~a ~n" env)
    (and env (string=? env "on")))) 

;;;;;;;;;;;;;;;; Site Images ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;(define bootstrap.gif (bitmap "bootstrap.gif"))
(define bootstrap.logo (bitmap "logo-icon.png"))
(define creativeCommonsLogo (bitmap "creativeCommonsLogo.png"))

;;;;;;;;;;;;;;;; Styles ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define bs-header-style (bootstrap-paragraph-style "BootstrapHeader"))
(define bs-header-style/span (bootstrap-span-style "BootstrapHeader"))
(define bs-lesson-title-style (bootstrap-style "BootstrapLessonTitle"))
(define bs-lesson-name-style (bootstrap-style "BSLessonName"))
(define bs-lesson-duration-style (bootstrap-style "BSLessonDuration"))
(define bs-video-style (bootstrap-style "BootstrapVideo"))
(define bs-page-title-style (bootstrap-div-style "BootstrapPageTitle"))
(define bs-slide-title-style (bootstrap-style "BootstrapSlideTitle"))
(define bs-skipSlide-style (bootstrap-div-style "BS-Skip-Slide"))
(define bs-translation-buttons-style (bootstrap-a-style "TranslationButton"))

(define bs-time-style (bootstrap-span-style "time"))
(define bs-callout-style (bootstrap-div-style "callout"))
(define bs-student-style (bootstrap-div-style "student"))
(define bs-slideText-style (bootstrap-span-style "slideText"))
(define bs-noSlideText-style (bootstrap-span-style "noSlideText"))
(define bs-teacher-style (bootstrap-div-style "teacher"))
(define bs-logo-style (bootstrap-span-style "BootstrapLogo"))
(define bs-vocab-style (bootstrap-span-style "vocab"))
(define bs-banner-style (bootstrap-div-style "banner"))
(define bs-boxtext-style (bootstrap-div-style "boxedtext"))
(define bs-logosplash-style (bootstrap-div-style/id "logosplash"))

(define bs-handout-style (bootstrap-div-style/extra-id "segment" "exercises"))
(define bs-exercise-instr-style (bootstrap-div-style "exercise-instr"))

;;;;;;;;;;;;; Basic formatting ;;;;;;;;;;;;;;;;;;;

;; accumulate all vocab referenced in lesson so we can generate a glossary
(define (vocab body)
  (traverse-element
   (lambda (get set)
     (set 'vocab-used (cons body (get 'vocab-used '())))
     (elem #:style bs-vocab-style body))))

;; generate content to be styled as its own line in a block
(define (bannerline  . body)
  (elem #:style bs-banner-style body))

;; generate content to be styled in a framed box
(define (boxed-text  . body)
  (elem #:style bs-boxtext-style body))

;; add a paragraph break by inserting two linebreaks
(define (new-paragraph)
  (list (linebreak) (linebreak)))

;; insert animated gif into file
(define (animated-gif path-as-str)
  (let ([path-strs (string-split path-as-str "\\")])
    (image (apply build-path path-strs))))

;; insert image with alt-text into file.
;; if img-path is a url, leave as such, else try to build a path
(define (image-with-alt-text img-pathstr-or-url alt-text)
  (if (and (>= (string-length img-pathstr-or-url) 4)
           (string=? "http" (substring img-pathstr-or-url 0 4)))
      ;; image is at a URL
      (elem #:style (style #f
                           (list (alt-tag "img")
                                 (attributes (list (cons 'src img-pathstr-or-url)
                                                   (cons 'alt alt-text))))))
      ;; else img is at a path
      ;(let ([path-strs (string-split img-pathstr-or-url "\\")])
      ;  (elem #:style (style #f
      ;                     (list (alt-tag "img")
      ;                           (attributes (list (cons 'src (path->string (apply build-path path-strs)))
      ;                                             (cons 'alt alt-text))))))
      ;  )))
      (let ([path-strs (string-split img-pathstr-or-url "\\")])
        (image (apply build-path path-strs)
               alt-text))))

(define (http-image img-url alt-text)
  (elem #:style (style #f
                       (list (alt-tag "img")
                             (attributes (list (cons 'src img-url)
                                               (cons 'alt alt-text)))))))

  
;;;;;;;;;;;;;; Lesson structuring ;;;;;;;;;;;;;;;;;;;;;;;

(define (student #:title (title #f)
                 #:skipSlide? (skip? #f)
                 . content)

  
  (let ([title-filtered (if title title (if NEW-LESSON? (first CURRENT-LESSON-LIST) #f))])

  (set! NEW-LESSON? #f)
    
  (if skip?
      (nested #:style bs-student-style (nested #:style bs-skipSlide-style (interleave-parbreaks/select
                                    (if title-filtered (cons (slideText (elem #:style bs-slide-title-style title-filtered)) content)
                                        content))))
      (nested #:style bs-student-style (interleave-parbreaks/select
                                    (if title-filtered (cons (slideText (elem #:style bs-slide-title-style title-filtered)) content)
                                        content))))))

(define (teacher . content)
  (nested #:style bs-teacher-style (interleave-parbreaks/select content)))

(define (pacing #:type (type #f) . contents) 
  (nested #:style (bootstrap-span-style type)
          (nested #:style bs-callout-style (interleave-parbreaks/all contents))))

(define (points . contents)
   (apply itemlist/splicing contents #:style (make-style "lesson" '(compact))))

(define (point . contents)
  (interleave-parbreaks/select contents)) 

;auto generates copyright section
(define (copyright . body)
  (para #:style (bootstrap-div-style/id "copyright")
   (hyperlink #:style bootstrap-hyperlink-style "http://creativecommons.org/licenses/by-nc-nd/4.0/" creativeCommonsLogo)
   (cond
     [(string=? (current-course) "algebra") (translate 'copyright-names-alg)]
     [(string=? (current-course) "reactive") (translate 'copyright-names-reac)]
     [(string=? (current-course) "data-science") (translate 'copyright-names-data)]
     [(string=? (current-course) "physics") (translate 'copyright-names-phys)]
     [else (WARNING (format "no copyright tag found for course: ~a" (current-course)) 'copyright)])
   (hyperlink #:style bootstrap-hyperlink-style "http://creativecommons.org/licenses/by-nc-nd/4.0/" (translate 'copyright-license))
   (string-append ". " (translate 'copyright-based) " ") (hyperlink "https://www.bootstrapworld.org/" "www.BootstrapWorld.org")
   (string-append ". " (translate 'copyright-permissions) " ")
   (hyperlink "mailto:schanzer@BootstrapWorld.org" "schanzer@BootstrapWorld.org") "."))

;; activities that are interspersed into the notes
;; the style-tag argument is the html tag (string) for the div
(define (styled-activity #:forevidence (evidence #f) 
                         #:answer (answer #f)
                         #:show-answer? (show-answer? #f)
                         style-tag
                         . body)
  (traverse-block
   (lambda (get set!)
     ;; first, check that evidence tags on activity are valid
     (let* ([evidlist (cond [(list? evidence) evidence] [(not evidence) '()] [else (list evidence)])]
            [checked-evidlist (foldr (lambda (evidtag result-rest)
                                       (if (get-evid-statement/tag evidtag) 
                                           (cons evidtag result-rest)
                                           result-rest))
                                     '() evidlist)])
         (when evidence (set! 'activity-evid (append checked-evidlist (get 'activity-evid '()))))
         (nested #:style (bootstrap-div-style style-tag)
                 (interleave-parbreaks/select body))))))

;; activities that are interspersed into the notes, tagged as a generic activity
(define (activity #:forevidence (evidence #f) 
                  #:answer (answer #f)
                  #:show-answer? (show-answer? #f)
                  . body)
  (apply styled-activity #:forevidence evidence
                         #:answer answer
                         #:show-answer? show-answer?
                         "activity"
                         body))
  
;; language-table : list[list[elements]] -> table
;; produces table with the particular formatting for the Bootstrap language table
(define (language-table . rows)
  (nested #:style (bootstrap-div-style/id/nested "LanguageTable")    
          (table (style "thetable"
                        (list 
                         (table-columns
                          (list 
                           (style "BootstrapTable" '(center))
                           (style "BootstrapTable" '(center))
                           (style "BootstrapTable" '(center))))))   
                 (cons (list (para #:style "BootstrapTableHeader" (translate 'lang-table-types))
                             (para #:style "BootstrapTableHeader" (translate 'lang-table-func))
                             (para #:style "BootstrapTableHeader" (translate 'lang-table-vals)))
                       (map (lambda (r) (map para r)) rows)))))

;; build-table : list[string] list[list[element]] (number number -> element) 
;;               number number -> table
;; consumes column headers, contents for a prefix of the columns, a function to
;;          format each cell based on its row and col number, 
;;          and the number of columns and rows for the table
;;          (col-headers count as a row if they are provided)
;; produces a table (list of list of cell contents, row-major order)
;; ASSUMES: each list in col-contents has length height (which is the number of data rows)
(define (build-table/cols col-headers col-contents fmt-cell numCols numDataRows)
  ;; check assumption on col-contents lengths
  (for-each (lambda (col-content)
              (unless (or (null? col-content) (= (length col-content) numDataRows))
                (error 'build-table/cols 
                       (format "column contents ~a needs to have one entry for each of ~a rows" 
                               col-content numDataRows))))
            col-contents)
  (let* ([blank-column (lambda (col-num)
                         (build-list numDataRows (lambda (row-num) 
                                                   (fmt-cell row-num col-num))))]
         [data-columns 
          (build-list numCols
                      (lambda (col-num) 
                        (cond [(>= col-num (length col-contents)) (blank-column col-num)]
                              [(null? (list-ref col-contents col-num)) (blank-column col-num)]
                              [else (map para (list-ref col-contents col-num))])))]
         [all-columns (if (null? col-headers) data-columns
                          (map cons 
                               (map (lambda (h) (para (bold h))) col-headers)
                               data-columns))])   
    (table (style "datatable"
                  (list (table-columns
                         (build-list numCols
                                     (lambda (n) (style #f '(left)))))))
           ;; convert list of columns to list of rows
           (build-list (if (null? col-headers) numDataRows (add1 numDataRows))
                       (lambda (row-num) 
                         (map (lambda (col) (list-ref col row-num))
                              all-columns))))))
;;allows for text to be presented only when in slide mode
(define (slideText text) (elem #:style bs-slideText-style text))


;;uses slideText to give a newline break in slides
(define slidebreak (slideText "\n  \n"))

;;allows for text to appear only in standard display mode and not when in slide mode
(define (noSlideText text) (elem #:style bs-noSlideText-style text))



;;;;;;;;;; Sections of Units ;;;;;;;;;;;;;;;;;;;;;;

(define (materials . items)
  (list (compound-paragraph bs-header-style 
                            (decode-flow (list (string-append (translate 'iHeader-materials)":"))))
        (apply itemlist/splicing items #:style "BootstrapMaterialsList")))
  
(define (objectives . items)
  (list (compound-paragraph bs-header-style 
                            (decode-flow (list (string-append (translate 'iHeader-learning)":"))))
        (apply itemlist/splicing items #:style "BootstrapLearningObjectivesList")))

(define (evidence-statements . items)
  (list (compound-paragraph bs-header-style 
                            (decode-flow (list (string-append (translate 'iHeader-evidence)":"))))
        (apply itemlist/splicing items #:style "BootstrapEvidenceStatementsList")))

(define (product-outcomes . items)
  (list (compound-paragraph bs-header-style 
                            (decode-flow (list (string-append (translate 'iHeader-product)":"))))
        (apply itemlist/splicing items #:style "BootstrapProductOutcomesList")))

(define (exercises . content)
  (lesson-section (string-append (translate 'iHeader-exercises)":") content))

(define (preparation . items)
  (list (compound-paragraph bs-header-style 
                            (decode-flow (list (string-append (translate 'iHeader-preparation)":"))))
        (apply itemlist/splicing items #:style "BootstrapPreparationList")))
  
;; Cooperates with the Lesson tag.
(define (agenda . items)
  
  ;; extract-minutes: lesson-struct -> string
  ;; Extracts the number of minutes the lesson should take.
  (define (extract-minutes a-lesson)
    (first (regexp-match "[0-9]*" (lesson-struct-duration a-lesson))))
  
  (traverse-block
   (lambda (get set)
     (lambda (get set)
       (define (maybe-hyperlink elt anchor)
         (if anchor
             (hyperlink (string-append "#" anchor) elt)
             elt))
       
       (define lessons (reverse (get 'bootstrap-lessons '())))
      
       ;; compute total unit length to include in the unit overview
       (let ([unit-minutes (foldr (lambda (elt result)
                                    (let ([mins (string->number (extract-minutes elt))])
                                      (+ (if mins mins 0) result)))
                                  0 lessons)])
         ;(printf "Computed ~a minutes~n" unit-minutes)
         (set 'unit-length unit-minutes))
         
       (nested #:style bootstrap-agenda-style 
               (interleave-parbreaks/all
               (list (translate 'agenda-title)
                     (apply 
                      itemlist/splicing 
                      #:style "BootstrapAgendaList"
                      (for/list ([a-lesson lessons])
                        (item (para (elem #:style "BSLessonDuration"
                                          (format (string-append"~a "(translate 'agenda-min) )
                                                  (extract-minutes a-lesson)))
                                    (maybe-hyperlink
                                     (elem #:style "BSLessonName"
                                           (lesson-struct-title a-lesson))
                                     (lesson-struct-anchor a-lesson)))))))))))))

;; glossary-entry : string (string or #f) -> elem
;; generates markup for glossary entry; defn may be missing
(define (glossary-entry term defn)
  (let ([term-elem (elem #:style (bootstrap-span-style "vocab") term)])
    (if defn
        (elem term-elem ": " defn)
        term-elem)))

;; strips all spaces from a string
(define (rem-spaces str)
  (string-replace str " " ""))

;; determine whether "s" is last character of given string
(define (ends-in-s? str)
  (char=? #\s (string-ref str (sub1 (string-length str)))))

;; produces string with last character of given string removed
(define (rem-last-char str)
  (substring str 0 (sub1 (string-length str))))

;; replace words in strlist with singular versions that appear in dictionary
(define (singularize-vocab-terms strlist)
  (map (lambda (str) 
         (if (and (ends-in-s? str)
                  (assoc (rem-last-char str) (current-glossary-terms)))
             (rem-last-char str)
             str))
       strlist))

;; retrieves vocab terms used in document and generates block containing
;;   terms and their definitions from the dictionary file
(define (gen-glossary)
  (traverse-block
   (lambda (get set)
     (lambda (get set)
       (let* ([clean-terms (sort (remove-duplicates (singularize-vocab-terms (map string-downcase (get 'vocab-used '()))))
                                 string<=?)]
              [terms (lookup-tags clean-terms
                                  (current-glossary-terms) "Vocabulary term" #:show-unbound #t)])
         (if (empty? terms) (para)
             (nested #:style (bootstrap-div-style/id/nested "Glossary")
                     (interleave-parbreaks/all
                      (list
                       (para #:style bs-header-style/span (string-append (translate 'iHeader-glossary) ":"))
                       (apply itemlist/splicing
                              (for/list ([term terms])
                                (when (and (list? term) (string=? "" (second term)))
                                  (WARNING (format "Vocabulary term has empty definition in dictionary: ~a ~n" (first term)) 'vocab-terms))
                                (cond [(and (list? term) (string=? "" (second term)))
                                         (glossary-entry (first term) #f)]
                                      ;; if glossary entry indexed on multiple words for same defn, use first one
                                      [(and (list? term) (cons? (first term)))
                                       (glossary-entry (first (first term)) (second term))]
                                      ;; if get here, entry should be indexed on only a single word
                                      [(list? term)
                                       (glossary-entry (first term) (second term))]
                                      [else (glossary-entry term #f)]))))))))))))

;;;;;;;;;;;;;;; Lessons ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; lesson-struct records the outline of a structure: basically, its
;; title, how long it takes, and the anchor to get to it within the
;; current document.
(struct lesson-struct (title     ;; (U string #f)
                       duration  ;; string e.g. "15 min"
                       anchor)   ;; string
  #:transparent)

;;;;;;;;;;;;; CURRENT LESSON FORMAT ;;;;;;;;;;;;;;;;;;

;;says whether or not a new lesson has been found (for printing slide titles)
(define NEW-LESSON? #t)
;;holds the Current lesson name to print it in slide titles
(define CURRENT-LESSON-LIST '())

;;sets variables relevent to setting slide titles
(define (set-everything! title)
  (set! NEW-LESSON? #t)
  (set! CURRENT-LESSON-LIST (cons title CURRENT-LESSON-LIST)))

;;macro used to call set-everything! on the lesson title before the body of lesson/studteach is evaluated
; This was added on 07/20/17 to add automatic slide titles at the beginning of every new lesson
(define-syntax (lesson/studteach stx)
  (syntax-case stx ()
    [(_ #:title title opt ... . body) #'(begin
                                          (set-everything! title)
                                          (lesson/studteach/core #:title title opt ... . body))]))

;;main function used in bootstrap files to create a Bootstrap Lesson.
(define (lesson/studteach/core
         #:title (title #f)
         #:duration (duration #f)
         #:overview (overview "")
         #:prerequisites (prerequisites #f)
         #:learning-objectives (learning-objectives #f)
         #:evidence-statements (evidence-statements #f)
         #:product-outcomes (product-outcomes #f)
         #:standards (standards '())
         #:materials (materials #f)
         #:preparation (preparation #f)
         #:exercises (exercise-locs '())
         #:video (video #f)
         #:pacings (pacings #f)
         . body)

  (when prerequisites (for-each (lambda (prereq)
                                (when (not (member prereq CURRENT-LESSON-LIST))
                                  (WARNING (format "Could not find prerequisite ~a for lesson ~a in unit ~a of ~a\n"
                                                   prereq title (current-unit) (current-course)) 'prereq)))
                                prerequisites))
  
  (define the-lesson-name 
    (or (current-lesson-name) 
        (symbol->string (gensym (string->symbol (or title 'lesson))))))
  
  (define video-elem (cond [(and video (list? video))
                            (map (lambda (v) (elem #:style bs-video-style v)) video)]
                           [video (elem #:style bs-video-style video)]
                           [else (elem)]))
  (traverse-block
   (lambda (get set!)
     (define anchor (lesson-name->anchor-name the-lesson-name))
     ;(set! 'vocab-used '()) ; reset vocabulary list for each lesson
     ;; the map of get-evidtag-std allows either std names or full evidence tags to
     ;;   be included in the list of standards. Our current code uses only the names
     ;;   but we may want to have the full tags for more refined generation later
     (set! 'standard-names (remove-duplicates (append (map get-evidtag-std standards)
                                                      (get 'standard-names '()))))
     (set! 'exercise-locs (append (get 'exercise-locs '()) exercise-locs))
     (set! 'bootstrap-lessons (cons (lesson-struct title
                                                   duration
                                                   anchor)
                                    (get 'bootstrap-lessons '())))     
     (nested #:style "LessonBoundary"
      (para #:style bs-page-title-style title)
      "\n" "\n"
      (nested-flow 
       bs-content-style
       (list
        (nested #:style (bootstrap-sectioning-style "overview")
                (interleave-parbreaks/all
                 (list
                  (nested #:style bs-logo-style (image logo.png "bootstrap logo"))
                  ;; agenda would insert here
                  (nested #:style bs-lesson-title-style
                          (nested #:style bs-lesson-name-style (translate 'iHeader-overview)))
                  overview
                  (lesson-section (translate 'iHeader-learning) learning-objectives)
                  (lesson-section (translate 'iHeader-evidence) evidence-statements)
                  (lesson-section (translate 'iHeader-product) product-outcomes)
                  ; commented out to suppress warnings that aren't relevant with unit-level generation
                  ;(lesson-section "Standards" (expand-standards standards))
                  (lesson-section (translate 'iHeader-mat) materials)
                  (lesson-section (translate 'iHeader-preparation) preparation)
                  ;; look at unit-level glossary generation to build lesson-level glossary
                  ;(lesson-section "Glossary" (glossary get))
                  )))
        (nested #:style (bootstrap-div-style "segment")
                (interleave-parbreaks/all
                 (append
                  (list
                   (elem #:style (style #f (list (url-anchor anchor) (make-alt-tag "span"))))
                   (nested #:style bs-lesson-title-style
                           (interleave-parbreaks/all
                            (cons (para #:style bs-lesson-name-style 
                                        (interleave-parbreaks/all
                                         (list (elem #:style "Slide-Lesson-Title"  title)
                                               video-elem
                                               (cond [duration
                                                      (elem #:style bs-time-style (format (string-append "(" (translate 'sHeader-duration) " ~a)") duration))]
                                                     [else (elem)]))))
                                  (list (elem)))))) ;pacings))) -- reinclude later if desired
                   body
                   ;(list (insert-toggle-buttons))
                   )))
        ))))))
  
;; contents either an itemization or a traverse block
(define (lesson-section title contents)
  (traverse-block 
   (lambda (get set)
     ;;string-downcase: non-english errors?
     (let ([title-tag (string->symbol (string-downcase (string-replace title " " "-")))])
       (when (itemization? contents)
         (set title-tag (append/itemization (get title-tag '()) contents))))
     (if contents
         (nested #:style (bootstrap-div-style (string-append "Lesson" (rem-spaces title)))
          (interleave-parbreaks/all (list (bold title) contents)))
         (para)))))

;;;;;;;;;;;; generating standards ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
(define (expand-standards/csv standard-tags)
  (let ([known-stnds (foldl (lambda (t res-rest)
                              (let ([descr (get-standard-descr t)])
                                (if descr
                                    (cons (list t descr) res-rest)
                                    res-rest)))
                            empty standard-tags)])
    (apply itemlist/splicing
           (for/list ([stnd known-stnds])
             (item (elem (format "~a: ~a" (first stnd) (second stnd))))))))     

(define (expand-standards standard-tags)
  (let ([known-stnds (lookup-tags standard-tags commoncore-standards-dict "Standard")])
    (apply itemlist/splicing
           (for/list ([stnd known-stnds])
             (item (elem (format "~a: ~a" (first stnd) (second stnd))))))))

;;;;;;;;;;; evidence statements ;;;;;;;;;;;;;;;;;;;;;;;;;;

;; assumes no duplicates in the stdtaglist
;; do we want to suppress evidence for non-teachers, or will formatting effectively handle that?
;; NOTE: this function reflects an API weakness relative to standards-csv-api: the map in 
;;   tag-formatted-LOtree really shouldn't be looking into the first/second/third of lists or at indices
(define (learn-evid-from-standards)
  (traverse-block
   (lambda (get set)
     (lambda (get set)
       (let* ([evid-used (get 'activity-evid '())]
              [stdtaglist (get 'standard-names '())]
              [LOtree (apply append (map get-learnobj-tree stdtaglist))]
              [tag-formatted-LOtree
               (map (lambda (lo)
                      (let* ([usedevid (sort (get-used-evidnums/std (third lo) evid-used) <=)]
                             [keep-evid (map (lambda (keep-index) (list-ref (second lo) (sub1 keep-index))) usedevid)])
                        (when (empty? keep-evid)
                          (WARNING (format "Unit ~a of course ~a has no activities for evidence statments under listed standard ~a~n" (current-unit) (current-course) (third lo)) 'evidence-statements))
                        (list (elem (bold (third lo)) ": " (first lo))
                              keep-evid)))
                    ;; separately alphabetize Common Core and BS standards
                    (let loop [(Allobjs LOtree) (BSobjs empty) (Others empty)]
                      (cond [(empty? Allobjs) 
                             (append (sort Others (lambda (o1 o2) (string<=? (third o1) (third o2))))
                                     (sort BSobjs (lambda (o1 o2) (string<=? (third o1) (third o2)))))]
                            [(string=? "BS-" (substring (third (first Allobjs)) 0 3))
                             (loop (rest Allobjs) (cons (first Allobjs) BSobjs) Others)]
                            [else (loop (rest Allobjs) BSobjs (cons (first Allobjs) Others))])))])
         ;(printf "Have activity tags ~a~n" (get 'activity-evid '()))
         ;(for-each (lambda (std) (printf "Std ~a uses nums ~a ~n" std (get-used-evidnums/std std evid-used))) stdtaglist)
         ;(printf "~n")
         (if (empty? tag-formatted-LOtree)
             (nested)
             (nested #:style (bootstrap-div-style/id/nested "LearningObjectives")
                     (interleave-parbreaks/all
                      (list
                       (para #:style bs-header-style/span (string-append (translate 'iHeader-standards)":"))
                       (list (translate 'standards-stitle)
                             " "
                             (standards-link (translate 'standards-link)) 
                             " "
                             (translate 'standards-rest)
                             ". "
                             )
                       (list->itemization tag-formatted-LOtree 
                                          (list "LearningObjectivesList" "EvidenceStatementsList")))))))))))

;;;;; HTML elements for unit pages ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; the extra class "fixed" in the toolbar is for consistency with what gets
; generated when we add the toolbar id through a bootstrap-div-style/id
; for the student toolbar
(define (insert-teacher-toggle-button)
  (cond-element
   [html (sxml->element
          `(div (@ (class "fixed") (id "lessonToolbar"))
                (input (@ (type "button") 
                          (valueShow ,(translate 'btn-show))
                          (valueHide ,(translate 'btn-hide))
                          (value ,(translate 'btn-show))
                          (onclick "toggleTeacherNotes(this);")) "")
                (br)
                (input (@ (type "button")
                          (value ,(translate 'btn-group))
                          (onclick "showGroup()")))
                (br)
                (input (@ (type "button")
                          (value ,(translate 'btn-slide))
                          (onclick "showSlides()")))))]
   [else (elem)]))

(define (insert-student-buttons)
  (cond-element
   [html (sxml->element
          `(center
            (input (@ (type "button") (id "prev")   (value "<<")) "")
            (input (@ (type "button") (id "flip")   ,(value (translate 'btn-flip))) "")
            (input (@ (type "button") (id "next")   (value ">>")) "")
            ))]
   [else (elem "")]))

(define (insert-toolbar)
  (insert-teacher-toggle-button))

(define (insert-help-button)
  (para #:style (make-style #f (list (make-alt-tag "iframe") 
                                     (make-attributes (list (cons 'id "forum_embed"))))) 
        ""))
                                     
;;;;;;;;;;;;; Generating the Main Summary Page ;;;;;;;;;;;;;;;;;

;; to add HEAD or BODY-ID attributes, create an empty title element
(define (augment-head)
  (title #:style (make-style #f (list bs-head-additions (bs-body-id)))))

;; Used to generate the curriculum overview pages
;; Not sure why we have the dual nested here ...
(define (main-contents . body)
  (list ;(insert-menu-ssi) ;; this ends up in the wrong place in the file -- must figure out at some point
        (augment-head)
        (nested #:style (bootstrap-div-style/id/nested "translations")
                (include-language-links-main))
        (nested #:style (bootstrap-div-style/id/nested "body")
                (nested #:style (bootstrap-div-style "item") 
                        body))))

;; unit-descr : list[element] -> block
;; stores the unit description to use in building the summary, then generates the text
(define-syntax (unit-descr stx)
  (syntax-case stx ()
    [(_ body ...)
     (syntax/loc stx
       (begin
         (set! current-the-unit-description (list body ...))
         current-the-unit-description))]))

;; get-unit-descr : string -> pre-content
;; extract the content for the unit-descr from the unit with the given name
(define (get-unit-descr unit-name)
  (define result
    (dynamic-require (build-path (get-units-dir) unit-name "the-unit.scrbl")
                     'the-unit-description
                     (lambda ()
                       #f)))
  (unless result
    (WARNING (format "no unit-descr for ~a~n" unit-name) 'missing-unit-descr))
  (if result
      result
      ""))

;; summary-item/no-link : string -> block
;; produces an item for the unit summary with a title but no links
(define (summary-item/no-link name . descr)
  (para #:style "BSUnitSummary"
        (elem #:style "BSUnitTitle" name)
        descr))

;; summary-item/unit-link string string content -> block
;; generates summary entry in which unit name links to html version of lesson
;;   (contrast to summary-item/links, which links to both html and pdf versions)
(define (summary-item/unit-link name basefilename . descr)
  (para #:style "BSUnitSummary"
        (elem #:style "BSUnitTitle" (elem (hyperlink (format "~a.html" basefilename) name)))
        descr))

;; summary-item/links : string string content -> block
;; generate a summary entry links to html and pdf versions as
;;   used on the main page for a course
(define (summary-item/links name basefilename 
                            #:label1 (label1 "html") #:ext1 (ext1 "html") 
                            #:label2 (label2 "pdf") #:ext2 (ext2 "pdf") 
                            #:only-one-label? (only-one-label? #f)
                            . descr)
  (apply summary-item/custom name
         (if only-one-label?
             (list (hyperlink (format "~a.~a" basefilename ext1) label1)) 
             (list (hyperlink (format "~a.~a" basefilename ext1) label1)
                   (hyperlink (format "~a.~a" basefilename ext2) label2)))
         descr))

;; summary-item/custom : string list[hyperlink] pre-content -> block
;; generate a summary entry with given hyperlinks
;;   used on the main page for a course
;; CURRENTLY HANDLES ONLY TWO LINKS -- MUST GENERALIZE TO MORE
(define (summary-item/custom name links . descr)
  (if (= (length links) 2)
      (para #:style "BSUnitSummary"
            (elem #:style "BSUnitTitle" name)
            " ["
            (elem (first links))      
            " | "
            (elem (second links))
            "] - "
            descr)
      (para #:style "BSUnitSummary"
            (elem #:style "BSUnitTitle" name)
            " ["
            (elem (first links))      
            "] - "
            descr)))
      

;; unit-summary/links : number content -> block
;; generate the summary of a unit with links to html and pdf versions as
;;   used on the main page for the BS1 curriculum
;; previously used summary-item/links (for both html/pdf links)
(define (unit-summary/links num )
  ;; NOTE: This assumes every unit is of the form "Unit 1" or "Unit 2"
  ;(printf "\n\nchecking ~a against ~a\n\n\n" (format (string-append (translate 'unit)"~a") num) (units))
  (when (or (empty? (units)) (member (format (string-append "unit""~a") num) (units)))
    (summary-item/unit-link (format (string-append (translate 'unit)" ~a") num)
                          (format "units/unit~a/index" num)  ; index used to be "the-unit" 
                          (get-unit-descr (format "unit~a" num)))))

;; generates the logo and splash-screen markup for the main.scrbl pages
(define (logosplash splash-file logo-file)
  (nested #:style bs-logosplash-style
          (elem #:style (bootstrap-div-style "")
                (image-with-alt-text splash-file "splash image"))
          (elem #:style (bootstrap-div-style "top")
                (image-with-alt-text
                 (format "https://www.bootstrapworld.org/images/~a" logo-file)
                 "course logo"))
          ))

;;
;;@(define (comment . content)
;;   @literal[@list[" <!-- " content " --> "]])

;;@(define <!-- comment)

(define (insert-comment content)
  (literal (string-append "<!--" content " -->")))

(define (insert-menu-ssi)
  ;(xml:comment "menubar.ssi"))
  (literal "<!--#include virtual=\"/menubar.ssi\"-->"))

;;;;;;;;;; Unit summary generation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (unit-length timestr)
  (list (format "Length: ~a~n" (decode-flow timestr))))

;; used to pull summary data generated over an entire unit or lesson from the
;; traverse table
;; TODO: Weed out duplicates in the list
(define (summary-data/auto tag header . pre-content)
  (traverse-block
   (lambda (get set)
     (lambda (get set)
       (let ([items (get tag (itemlist))])
         (nested #:style (bootstrap-div-style/id/nested (rem-spaces header))
          (interleave-parbreaks/all
           (list
            (para #:style bs-header-style/span (format "~a:" header))
            (if (empty? pre-content) "" (first pre-content))
            (remdups/itemization items)))))))))

(define (unit-lessons . body)
  (interleave-parbreaks/all (append body (list (gen-exercises) (copyright)))))

(define (unit-overview/auto 
         #:objectives (objectivesItems #f)
         #:evidence-statments (evidenceItems #f)
         #:product-outcomes (product-outcomesItems #f)
         #:standards (standards #f)
         #:length (length #f)
         #:materials (materialsItems #f)
         #:preparation (preparationItems #f)
         #:lang-table (lang-table #f)
         #:gen-agenda? (gen-agenda? #t)
         #:provide-translation? (translation? #t)
         . description
         )
  (interleave-parbreaks/all
   (list (nested #:style (bootstrap-div-style/id "overviewDescr") 
               (interleave-parbreaks/all
                (list (para #:style bs-header-style/span "Unit Overview")
                      description                      
                      )))
         (nested #:style "OverviewBoundary"
                 (interleave-parbreaks/all
                  (list
                   (insert-help-button)
                   (nested #:style (bootstrap-sectioning-style "summary") 
                           (interleave-parbreaks/all
                            (list
                             (if gen-agenda? (agenda) "")

                             (include-language-links-units)
                             
                             ; moved these outside summary for code.org prep -- remove next two lines once E confirms
                             ;(para #:style bs-header-style/span "Unit Overview")
                             ;(para #:style (bootstrap-div-style/id "overviewDescr") description)
                             (if product-outcomesItems (product-outcomes product-outcomesItems) 
                                 (summary-data/auto 'product-outcomes (translate 'iHeader-product)))
                             (learn-evid-from-standards)
                             (if length (length-of-lesson length) (length-of-unit/auto))
                             (gen-glossary)
                             (if materialsItems (materials materialsItems) 
                                 (summary-data/auto 'materials (translate 'iHeader-mat)))
                             (if preparationItems (preparation preparationItems) 
                                 (summary-data/auto 'preparation (translate 'iHeader-preparation)))
                             (if lang-table 
                                 (if (list? (first lang-table))
                                     (apply language-table lang-table)
                                     (language-table lang-table))
                                 "")
                             (insert-toolbar)
                             )))))
                 ))
   ))
  
;creates the length of the lesson based on input
;input ONLY THE NUMBER!
(define (length-of-lesson l)
  (para #:style bs-header-style/span (format (string-append (translate 'length)": ~a "(translate 'minutes)) l)))

(define (length-of-unit/auto)
  (traverse-block
   (lambda (get set)
     (lambda (get set)
       (length-of-lesson (get 'unit-length "No value found for"))))))

;;;;;;;;; Including lessons ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; lesson-module-path->lesson-name: module-path -> string
(define (lesson-module-path->lesson-name mp)
  (match mp
    [(list 'lib path)
     (cond
       [(regexp-match #px"^curr/lessons/langs/([^/]+)/([^/]+)/lesson/lesson([^/]*).scrbl$" path)
        =>
        (lambda (result)
          (list-ref result 2))]
       [else
        (raise-lesson-error mp)])]
    [else
     (raise-lesson-error mp)]))

;; raise-lesson-error: module-path -> void
;; Raises a lesson-specific error.
(define (raise-lesson-error mp)
  (error 'extract-lesson "lesson module path ~e does not have expected shape (e.g. (lib curr/lessons/langs/LANGUAGE/FOO/lessonSUFFIX.scrbl)" mp))

;; extract-lesson: module-path -> (listof block)
;; Extracts the lesson from the documentation portion, and also
;; registers the use in the current document.
;; NOTE: currently assumes lesson placed within a file named index.html
(define (extract-lesson mp)
  (define lesson-name (lesson-module-path->lesson-name mp))
  (define a-doc (parameterize ([current-lesson-name lesson-name])
                  (dynamic-require mp 'doc)))
  
  (unless (part? a-doc)
    (error 'include-lesson "doc binding is not a part: ~e" a-doc))
  ;; the document-output-path uses the basename of the scrbl source file.
  ;; Edited here to use index.html as the generated page name.  Will need a
  ;;  new way to indicate when to use index.html vs the actual base name if
  ;;  our infrastructures moves from the current "all lessons linked to directory
  ;;  pages" organization.
  (hash-set! (current-lesson-xref)
             lesson-name
             (list lesson-name (build-path (path-only (current-document-output-path)) "index.html")))
  
  ;; using rest in next line to eliminate an otherwise empty <p> block 
  ;;   that was getting inserted into each lesson
  (interleave-parbreaks/all (rest (part-blocks a-doc))))

(define-syntax (include-lesson stx)
  (syntax-case stx ()
    [(_ mp)
     (with-syntax ([(temporary-name) (generate-temporaries #'(mp))])
       (syntax/loc stx
         (extract-lesson 'mp)))]))

;; lesson-name->anchor-name: string -> string
;; Given that the lesson names are unique, we can create an <a name="..."> anchor
;; for each included lesson.  We put a "lesson_" prefix in front of each name.
(define (lesson-name->anchor-name a-name)
  (uri-encode (rem-spaces (string-append "lesson_" a-name))))

;;;;;;;; EXERCISE HANDOUTS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Tried factoring into own module, but too much sharing of styles
;;  and other basics needed for units/lessons

(define exercise-evid-tags list)

;; info required to locate an exercise within the filesystem
;;   will be used to generate links
;; the first form (our original notion) uses exercise-handout which
;;   contains metadata about evidence statements.  The no-meta
;;   version supports exercises that won't carry this metadata
;;   (at least for now)
(define-struct exercise-locator (lesson filename))
(define-struct (exercise-locator/file exercise-locator) (descr))

;; breaks a string into a list of content, in which substrings in
;;  the given list have been italicized
(define (italicize-within-string str terms-to-ital)
  (format-key-terms str terms-to-ital italic))

(define exercise-terms-to-italicize 
  (list (translate 'c-eval)
        (translate 'cap-a-exp) 
        (translate 'low-a-exp)
        (translate 'exp)
        (translate 'example)
        (translate 'contract) 
        (translate 'code)))

(define (exercise-handout #:title [title #f]
                          #:instr [instr #f]
                          #:forevidence [forevidence #f]
                          . body)
  ;(printf "processing handout~n")
  ;(printf "evidence is ~a~n" forevidence)
  ;(printf "body has length ~a~n~n" (length body))
  (let ([full-title (if title (string-append (translate 'exercise) ": " title) (translate 'exercise))])
    (interleave-parbreaks/all
     (list (head-title-no-content full-title)
           (elem #:style (bootstrap-div-style/id "homeworkInfo") "")
           (elem #:style bs-title-style full-title)
           (nested #:style bs-content-style
                   (nested #:style bs-handout-style
                           (interleave-parbreaks/all
                            (cons (para #:style bs-exercise-instr-style (bold (string-append (translate 'directions) ": ")) 
                                        (italicize-within-string instr exercise-terms-to-italicize))
                                  body))))
           (copyright)))))

;; exercise-answers merely tags content.  The module reader will leave answers
;; in or remove them based on the solutions generation mode
(define (exercise-answers . body)
  body)

;; produces values for the title and forevidence arguments for given exercise locator
;;  either or both values will be false if not found in the file
(define (extract-exercise-data exloc)
  ;; because we had to stitch to deine instead of define-runtime path, the relative paths created are static and must be manually edited
  (let ([filepath (build-path 'up 'up 'up 'up 'up 'up(lessons-dir) (exercise-locator-lesson exloc) 
                              "exercises" (string-append (exercise-locator-filename exloc) ".scrbl"))]
        )
    (let ([data
           (with-input-from-file filepath
             (lambda ()
               (with-handlers ([(lambda (e) (eq? e 'local-break))
                                (lambda (e) (list #f #f))])
                 ;; check that file starts with a #lang
                 (let ([init-line (read-line)])
                   (unless (and (string? init-line) (string=? "#lang" (substring init-line 0 5)))
                     (WARNING (format "extract-exercise-data: ~a does not start with #lang~n" filepath) 'exercise-langstart)
                     (raise 'local-break)))
                 ;; loop until get to the exercise sexp
                 (let ([exercise-sexp
                        (let loop ()
                          (let ([next (read)])

                            (unless (or (eof-object? next) (eq? next '@))
                              (WARNING (format "extract-exercise-data: got non-@ term ~a~n" next) 'invalid-exercise))
                            (when (eof-object? next)
                                (WARNING "extract-exercise-data reached end of file without finding exercise-handout\n" 'exercise-end))
                            (cond [(eof-object? next) 
                                   (raise 'local-break)]
                                  [(eq? next '@)
                                   (let ([next-char-str (peek-string 1 0)])
                                     (if (string=? next-char-str ";")
                                         (loop) ;; found a comment, read on next loop pass will skip over
                                         (let ([next-sexp (read)])
                                           (if (and (cons? next-sexp) (equal? (first next-sexp) 'exercise-handout))
                                               next-sexp
                                               (loop)))))]
                                  [else
                                     (raise 'local-break)])))])
                   ;; dig into the exercise sexp to find the title and evidence tag
                   (let loop [(title #f) (evtag #f) (rem-sexp (rest exercise-sexp))]
                     (cond [(< (length rem-sexp) 2) (list title evtag)]
                           [(equal? (first rem-sexp) '#:title) (loop (second rem-sexp) evtag (rest (rest rem-sexp)))]
                           [(equal? (first rem-sexp) '#:forevidence) (loop title (second rem-sexp) (rest (rest rem-sexp)))]
                           [else (loop title evtag (rest (rest rem-sexp)))]))))))])
      ;(printf "extract-data got ~a ~n" data)
      (values (first data) (second data)))))


(define (include-language-links-units)
  (interleave-parbreaks/all
   ;TODO change interleave-parbreaks/all, can it access run-languages?
   (foldl (lambda (language rest)
            (cons (hyperlink #:style bs-translation-buttons-style
                                     ;(path->string (find-relative-path
                                     ;              (current-document-output-path)
                                     ;             (string-replace (path->string (current-document-output-path)) (getenv "LANGUAGE") language)))
                                     (string-append "../../../../" (current-course)"/" language "/units/" (current-unit) "/index.html")
                                     (translate (string->symbol language))) rest))
          ( list (hyperlink  #:style bs-translation-buttons-style 
                         "#"
                         "add translation"))
          (current-course-languages))))

(define (include-language-links-main)
   ;interleave-parbreaks/all
   ;TODO change interleave-parbreaks/all, can it access run-languages?
    (foldl (lambda (language rest)
             (cons (hyperlink  #:style bs-translation-buttons-style 
                                       ;(path->string (find-relative-path
                                       ;              (current-document-output-path)
                                       ;             (string-replace (path->string (current-document-output-path)) (getenv "LANGUAGE") language)))
                                       (string-append "../" language "/index.shtml")
                                       (translate (string->symbol language))) rest))
           ( list (hyperlink  #:style bs-translation-buttons-style 
                         "#"
                         "add translation"))
           (current-course-languages)))
             


                                     
;; generates the DOM for the additional exercises component of the unit page
;; the exercise-list.rkt file built up in this function gets used in the build
;;   process to identify which exercise files to copy over into the distribution
(define (gen-exercises)
  (traverse-block
   (lambda (get set)
     (lambda (get set)
       (with-output-to-file "exercise-list.rkt" (lambda () (printf "(")) #:exists 'replace)
       (let* ([unit-title (current-unit)]
              [exercise-locs (get 'exercise-locs '())]
              [exercise-output
               (if (empty? exercise-locs) (para)
                   (nested #:style (bootstrap-div-style "ExtraExercises")
                           (interleave-parbreaks/all
                            (list 
                             (para #:style bs-lesson-title-style (string-append (translate 'add-exer) ":"))
                             (apply itemlist/splicing 
                                    (map (lambda (exloc)
                                           (let-values ([(extitle exforevid) 
                                                         (if (exercise-locator/file? exloc)
                                                             (values (exercise-locator/file-descr exloc)
                                                                     #f)
                                                             (extract-exercise-data exloc)
                                                             )])
                                             (let ([descr (if extitle extitle (exercise-locator-filename exloc))]
                                                   [support (if exforevid
                                                                (let ([evidstmt (get-evid-summary exforevid)])
                                                                  (if evidstmt (format " [supports ~a]" evidstmt)
                                                                      ""))
                                                                "")]
                                                   [extension (if (exercise-locator/file? exloc) ".pdf" ".html")]
                                                   )
                                               (let ([exdirpath (if (current-deployment-dir)
                                                                    (build-path (current-deployment-dir) "lessons") 
                                                                    (build-path 'up (lessons-dir)))]
                                                     [expathname 
                                                      (build-path "lessons" (exercise-locator-lesson exloc) 
                                                                  "exercises" (string-append (exercise-locator-filename exloc) 
                                                                                             extension))])
                                                 (with-output-to-file "exercise-list.rkt" 
                                                   (lambda () (write (path->string expathname)) (printf " ")) 
                                                   #:exists 'append)
                                                 (elem (list (hyperlink #:style bootstrap-hyperlink-style
                                                                        (string-append "exercises/" (exercise-locator-lesson exloc) "/"
                                                                                       (exercise-locator-filename exloc) extension)
                                                                        descr)
                                                             ; uncomment next line when ready to bring evidence back in
                                                             ;(elem #:style (bootstrap-span-style "supports-evid") support)
                                                             ))))))
                                         exercise-locs))
                             (when (hash-has-key? current-teacher-contr-xref unit-title)
                             (para #:style bs-lesson-title-style (string-append (translate 'add-teacher-contr) ":")))                          
                             (when (hash-has-key? current-teacher-contr-xref unit-title)
                               (apply itemlist/splicing 
                                    (map (lambda (ex-spec)
                                           (let* ([name (first ex-spec)]
                                                 [school (second ex-spec)]
                                                 [grade (third ex-spec)]
                                                 [descr (fourth ex-spec)]
                                                 [link (fifth ex-spec)]
                                                 [label descr])
                                             (elem (list (hyperlink #:style bootstrap-hyperlink-style link label)
                                                         (string-append ": "(translate 'submitted-by)" " name ", " (translate 'teach-at) " " school ". "(translate 'grade-for)" " grade)))))
                                         (hash-ref current-teacher-contr-xref unit-title)))   )                                    

                                             
                             ))))])
         (with-output-to-file "exercise-list.rkt" (lambda () (printf ")")) #:exists 'append)
         exercise-output)))))







;;;;;;;; LINKING BETWEEN COMPONENTS ;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (escape-webstring-newlines str)
  (string-replace str (list->string (list #\newline)) "%0A"))

;; make a hyperlink that opens in a new tab
(define (new-tab url link-text)
  (cond-element
    [html (sxml->element `(a (@ (href ,url) (target "_blank")) ,link-text))]
    [else (elem)]))

;; create a link to a wescheme editor, possibly initialized with interactions/defn contents
(define (editor-link #:public-id (pid #f)
                     #:interactions-text (interactions-text #f)
                     #:definitions-text (definitions-text #f)
                     #:lang (lang (getenv "TARGET-LANG"))
                     #:cpo-version (cpo-version #f) ;"v0.5r852")
                     link-text)  
  (cond [(string=? lang "pyret") 
         (cond-element
          [html
           (sxml->element `(a (@ (href ,(if cpo-version 
                                           (format "https://code.pyret.org/editor#share=~a&v=~a" pid cpo-version)
                                           (format "https://code.pyret.org/editor#share=~a" pid)))
                                 (target "_blank"))
                              ,link-text))]
          [else (elem)])]
        [(string=? lang "racket") 
         (if (and definitions-text pid)
             (WARNING "creating wescheme link with both defns text and public id\n" 'weScheme-links)
             (let ([argstext (string-append (if pid (format "publicId=~a&" pid) "")
                                            (if interactions-text (format "interactionsText=~a&" interactions-text) "")
                                            (if definitions-text (format "definitionsText=~a" (escape-webstring-newlines definitions-text)) ""))])
               (cond-element
                [html
                 (sxml->element `(a (@ (href ,(format "https://www.wescheme.org/openEditor?~a" argstext))
                                       (target "embedded"))
                                    ,link-text))]
                [else (elem)])))]
        [else
         (WARNING (format "editor-link has unknown lang ~a in unit ~a of course ~a~n" lang (current-unit) (current-course)) 'editor-link-lang)]))

;; create a link to a particular program at wescheme.org, with the embedded target
(define (run-link #:public-id (pid #f) link-text)
  (if (not pid)
      (WARNING (format "run-link needs a public-id argument in unit ~a of course ~a"(current-unit) (current-course)) 'run-link)
      (cond-element
       [html
        (sxml->element `(a (@ (href ,(format "https://www.wescheme.org/view?publicId=~a" pid))
                              (target "embedded"))
                           ,link-text))]
       [else (elem)])))

;; create a link to wescheme.org's home page, with the embedded target
(define (login-link link-text)
  (cond-element
   [html
    (sxml->element `(a (@ (href "https://www.wescheme.org/")
                          (target "embedded"))
                       ,link-text))]
   [else (elem)]))


;; We need to do a little compile-time computation to get the file's source
;; where worksheet-link/src-path is used, since we want the path relative to
;; the usage, rather than to current-directory.
(define-syntax (worksheet-link/src-path stx)
  (syntax-case stx ()
    [(_ args ...)
     (with-syntax ([src-path (syntax-source stx)])
       (begin
         (syntax/loc stx
           (worksheet-link #:src-path src-path
                           args ...))))]))

;; Link to a particular resource by path.
;; resource-path should be a path string relative to the resources subdirectory.
;; The use of unit-to-resources-path reflects an assumption that all links are
;;  created within the-unit.html files.  Will need to add a param if other cases arise

;;TODO
(define (resource-link #:path resource-path
                       #:label [label #f])
  (let ([the-relative-path (build-path (unit-to-resources-path) resource-path)])
    (hyperlink #:style bootstrap-hyperlink-style
               (path->string the-relative-path)
               (if label label resource-path))))

;; produces a link to the standards documents
(define (standards-link descr)
  (hyperlink #:style bootstrap-hyperlink-style
             (translate 's-link)
             descr))

;; Creates a link to the worksheet.
;; Under development mode, the URL is relative to the development sources.
;; Under deployment mode, the URL assumes worksheets have been written 
(define (worksheet-link #:name (name #f)
                        #:page (page #f)
                        #:lesson (lesson #f)
                        #:src-path src-path)
  
  ;(define-values (base-path _ dir?) (split-path src-path))
  (define the-relative-path (build-path (unit-to-resources-path) "workbook" "StudentWorkbook.pdf"))
    ;; what follows (comments) is Danny's original code.  Commenting out to
    ;; update to new deployment parameters, assuming we always link to PDF (for now)
    ;    (find-relative-path (simple-form-path (current-directory))
    ;                        (cond 
    ;                          ;; FIXME: communicate parameter values via parameters.
    ;                          ;; The reason it's not working right now is because we're
    ;                          ;; calling into scribble with system*, which means we don't
    ;                          ;; get to preserve any parameters between the build script
    ;                          ;; and us.
    ;                          [(getenv "WORKSHEET-LINKS-TO-PDF")
    ;                           (simple-form-path (get-worksheet-pdf-path))]
    ;                          [lesson
    ;                           (simple-form-path (build-path worksheet-lesson-root
    ;                                                         lesson
    ;                                                         "worksheets"
    ;                                                         (format "~a.html" name)))]
    ;                          [else
    ;                           (simple-form-path (build-path base-path
    ;                                                         'up
    ;                                                         "worksheets"
    ;                                                         (format "~a.html" name)))])))
  
  (list (hyperlink #:style bootstrap-hyperlink-style
                   (path->string the-relative-path)
                   (string-append (translate 'page) " "
                                  (number->string 
                                   (cond [page page] 
                                         [name (let ([num (get-workbook-page/name name)])
                                                 (if num num (begin (WARNING (format "Unknown page name ~a" name) 'worksheet-link)
                                                     1))
                                                 ; (if (file-exists? (build-path (get-workbook-dir) "StudentWorkbook.pdf"))
                                                 ;    (WARNING (format "Unknown page name ~a" name) 'worksheet-link)
                                                 ;;TODO WHY WON'T THIS WORK RIGHT/IS IT OKAY TO HAVE MADE THIS FROM AN ERROR INTO A WARNING?
                                                 )]
                                         [else (begin (WARNING "worksheet link needs one of page or name\n" 'incomplete-worksheet)
                                               0)]))))))

;; Link to a particular lesson by name
;; lesson-link: #:name string #:label (U string #f) -> element
(define (lesson-link #:name lesson-name
                     #:label [label #f])
  ;; We make this a traverse-element so that we can re-evaluate this code at document-generation
  ;; time, rather than just at module-loading time.
  (traverse-element 
   (lambda (get set)
     (cond
       ;; First, check to see whether or not we can find the cross reference to the lesson.
       [(and (hash-has-key? (current-lesson-xref) lesson-name)
             (current-document-output-path))
        (define-values (unit-path anchor)
          (match (hash-ref (current-lesson-xref) lesson-name)
            [(list lesson-name unit-path)
             (values unit-path (lesson-name->anchor-name lesson-name))]))
        (define the-relative-path
          (find-relative-path (simple-form-path (path-only (current-document-output-path)))
                              (simple-form-path unit-path)))
        (hyperlink #:style bootstrap-hyperlink-style
                   (string-append (path->string the-relative-path) "#" anchor)
                   (if label label lesson-name))]       
       ;; If not, fail for now by producing a hyperlink that doesn't quite go to the right place.
       [else
        ;;current-output-port breaks
        ;;(WARNING (format (current-output-port) "could not find cross reference to ~a in unit ~a of course ~a\n" lesson-name (current-unit) (current-course)) 'lesson-refs) 
        (define the-relative-path
          (find-relative-path (simple-form-path (current-directory))
                              (simple-form-path (build-path worksheet-lesson-root lesson-name "lesson" "lesson.html"))))
        (hyperlink #:style bootstrap-hyperlink-style
                   (path->string the-relative-path)
                   (if label label lesson-name))]))))

(define (unit-link #:name unit-name
                     #:label [label #f]
                     #:course [course (current-course)])
  (hyperlink #:style bootstrap-hyperlink-style
             (path->string (simple-form-path (build-path (current-deployment-dir) "courses" course (getenv "LANGUAGE") "units" unit-name "index.html")))
             (if label label unit-name)))




; generates HTML for a link to the Lulu direct-buy button, using Lulu image icon
(define (lulu-button) 
  (cond-element
   [html
    (sxml->element
     `(div (@ (style "float: right"))
           (a (@ (href ,(translate 'lulu-link)))
              (img (@ (border "0") 
                      (alt "Support independent publishing: Buy this book on Lulu.")
                      (src "http://static.lulu.com/images/services/buy_now_buttons/en/book.gif?20140805085029"))))))]
   [(or latex pdf) (elem)]))

;;;;;;;;;;;; Page titles ;;;;;;;;;;;;;;;;;;;;;

;; generates the title, which includes the bootstrap logo in html but not in latex/pdf
;; the body-id for the page is set through head-title-no-content
(define (bootstrap-title #:single-line [single-line #f] . body)
  (define the-title (apply string-append body))
  (define unit+title (if single-line #f (regexp-match #px"^([^:]+):\\s*(.+)$" the-title))) 
  (define bootstrap-image (cond-element 
                           [html bootstrap.logo]
                           [(or latex pdf) (elem)]))
  (interleave-parbreaks/all
   (cond 
     [unit+title (list (head-title-no-content the-title)                                           
                       (nested #:style (bootstrap-div-style "headercontent")
                               (list (para #:style (bootstrap-span-style "BootstrapTitle")
                                           bootstrap-image
                                           (elem #:style (bootstrap-span-style "TitleUnitNum") (second unit+title)) 
                                           (third unit+title)
                                           ;(length-of-unit/auto)
                                           ))))]
     [else (list (head-title-no-content the-title)
                 (nested #:style (bootstrap-div-style "headercontent") 
                         (list (para #:style (bootstrap-span-style "BootstrapTitle") 
                                     (cons bootstrap-image body)))))])))

;;;;;;;;;;;;;; MISC HELPERS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; lookup-tags: list[string] assoc[(string or string-list), string] string -> element
;; looks up value associated with each string in taglist in 
;;    association list given as second arg
;; The assoc list can have single strings or string-lists as keys (mult terms map to one defn).
;; Optional arg controls whether undefined terms are displayed in output
;; Used to generate standards and glossary
(define (lookup-tags taglist in-dictionary tag-descr #:show-unbound (show-unbound #f))
  (foldr (lambda (elt result)
           (let ([lookup (assf (lambda (entry-key) (or (equal? elt entry-key)
                                                       (and (list? entry-key) (member elt entry-key))))
                               in-dictionary)])
             (unless lookup
               (WARNING (format "~a not in dictionary: ~a~n" tag-descr elt) 'lookup-tags))
             (if lookup (cons lookup result)                   
                   (if show-unbound (cons elt result) result))))
         '() taglist))
