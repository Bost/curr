#lang curr/lib
@declare-tags[management]

@title{Unit 5: Game Animation}

@unit-overview/auto[#:lang-table (list (list "Number" @code{+ - * / sq sqrt expt})
                                       (list "String" @code{string-append string-length})
                                       (list "Image"  @code{rectangle circle triangle ellipse star text scale rotate put-image}))]{
@unit-descr{Students define functions that map attributes of their game from one frame to the next, allowing them to move their dangers, targets, and projectiles.}
}
@lesson/studteach[
     #:title "Bug Hunting"
     #:duration "20 minutes"
     #:overview ""
     #:learning-objectives @itemlist[@item{Gain more experience understanding and correcting programming errors}]
     #:evidence-statements @itemlist[@item{Students will be able to read error messages for basic syntax errors}
                                     @item{Students will be able to edit programs to eliminate basic syntax errors}]
     #:product-outcomes @itemlist[]
     #:standards (list)
     #:materials @itemlist[@item{Pens/pencils for the students, fresh whiteboard markers for teachers}
                            @item{Class poster (List of rules, language table, course calendar)}
                            @item{Language Table (see below)}
                            @item{Bug Hunting [Bugs.rkt from @resource-link[#:path "source-files.zip" #:label "source-files.zip"] | @(hyperlink "http://www.wescheme.org/view?publicId=lQUC6RJArG" "WeScheme")] file preloaded on students' machines, in front}]
     #:preparation @itemlist[]
     #:pacings (list 
                @pacing[#:type "remediation"]{@itemlist[@item{}]}
                @pacing[#:type "misconception"]{@itemlist[@item{}]}
                @pacing[#:type "challenge"]{@itemlist[@item{}]}
                )
      ]{
        @points[@point{@student{Debugging (finding and correcting problems in code) is an important part of programming, so it's a good idea to practice finding bugs in code. 
                                @activity{Open the @(hyperlink "http://www.wescheme.org/view?publicId=lQUC6RJArG" "Bug Hunting") program in a new window, and see if you can find the bug in each expression. Click "Run" and read the error message carefully! After you fix each one, clicking Run will show you the error message for the next bug.}}
                        @teacher{Make sure students understand that the goal is not to FIX the bugs, but rather just to find them.}
                        }
                 ]}

@lesson/studteach[
     #:title "Danger and Target Movement"
     #:duration "30 minutes"
     #:overview "Students model animation in the coordinate plane, and write a simple linear function that animates their Danger."
     #:learning-objectives @itemlist[@item{Students learn to move game elements through functions that compute attributes in one frame from attributes in the previous frame}]
     #:evidence-statements @itemlist[@item{Students will be able to write functions that take in one dimension of a game element's coordinate and produce the next coordinate value in that dimension}
                                     @item{Students will learn how to control speed of movement through functions}]
     #:product-outcomes @itemlist[@item{Students will add danger movement to their games}
                                  @item{Students will add target movement to their games}]
     #:standards (list "N-Q" "A-CED.1-4" "F-IF.1-3" "F.IF.7-9" "F-BF.1-2" "F-LE.5")
     #:materials @itemlist[@item{Pens/pencils for the students, fresh whiteboard markers for teachers}
                            @item{Student @(resource-link #:path "workbook/StudentWorkbook.pdf" #:label "workbook")}
                            @item{All student computers should have their game templates pre-loaded, with their image files linked in}
                            @item{Class poster (List of rules, language table, course calendar)}
                            @item{Language Table (see below)}]
     #:preparation @itemlist[]
     #:pacings (list 
                @pacing[#:type "remediation"]{At this point, students should be very comfortable with the Design Recipe. If they are struggling, try reviewing the Contract with them first, then having a student act out the function. Ask that student what their name is, what they are expecting to be given, and what they will produce. Have them simulate a function call by calling out their name ("update-danger") and giving them an x-coordinate (they should produce a number that is 50 fewer than what they were given). Then refer back to this skit when writing Examples: the call-and-response is exactly how the code should behave, with students only having to write the code for whatever work your volunteer was doing in their head.}
                @pacing[#:type "misconception"]{@itemlist[@item{}]}
                @pacing[#:type "challenge"]{@itemlist[@item{}]}
                )
      ]{
        @points[@point{@student{@bitmap{images/AnimationDiagram.png}The dimensions of your videogame are 640x480, and each character is placed on the screen at a set of (x,y) coordinates. Your Target (T), Player (P) and Danger (D) each move along the x- or y-axis, having their x- or y-coordinate changed according to an animation function. These animation functions will start off simple: they take in the current x- or y-coordinate, and produce the next x- or y-coordinate. Later on you'll be able to adapt them to create more sophisticated motion, using @italic{both} the x- and y-coordinates.}
                        @teacher{}
                        }
                 @point{@student{@activity{Turn to @worksheet-link[#:page 15 #:name "Design-Recipe-Update-Danger"] in your workbook for @code{update-danger}.
                                           @itemlist[@item{Read the word problem carefully, and pay attention to @italic{what the function takes in}.}
                                                      @item{Fill out the @vocab{Contract} and @vocab{Purpose Statement} for the function, using what you circled to help you choose the Domain.}
                                                      @item{Write two @vocab{Examples} for the function.}
                                                      @item{Circle and label what varies between those examples, and label it with a @vocab{variable} name.}
                                                      @item{Define the function.}]}}
                         @teacher{If students are working on their own, check their work to make sure every last step is being executed correctly. If the class is working through it together, be sure to ask students to justify each step in terms of a prior step. @management{Tip: tell students that they must get your permission before typing in their code, then use that expectation to check each student's paper carefully.}}
                         }
                 @point{@student{Putting all of these together, @code{update-danger} is defined by:
                                 @code[#:multi-line]{; update-danger : Number -> Number
                                                     ; subtract 50 from the danger's x-coordinate
                                                     (EXAMPLE (update-danger 171) (- 171 50))
                                                     (EXAMPLE (update-danger -90) (- -90 50))
                                                     (define (update-danger x) (- x 50))}
                                 (Note: you may have slightly different Examples or variable names.)}
                         @teacher{}
                         }
                 @point{@student{Now it's time to animate the Target, which moves in the opposite direction.
                                 @activity{Turn to @worksheet-link[#:page 16 #:name "Design-Recipe-Update-Target"] in your workbook for @code{update-target}.
                                           @itemlist[@item{Read the word problem carefully, and pay attention to @italic{what the function takes in}.}
                                                      @item{Fill out the @vocab{Contract} and @vocab{Purpose Statement} for the function, using what you circled to help you choose the Domain.}
                                                      @item{Write two @vocab{Examples} for the function.}
                                                      @item{Circle and label what varies between those examples, and label it with a @vocab{variable} name.}
                                                      @item{Define the function.}]}}
                         @teacher{For students who finish these quickly, have them experiment with making the Target and Danger move faster or slower, or change direction altogether. Be sure that they are typing in Examples, and updating those examples to keep up with any changes to their definition.}
                         }
     ]}

@lesson/studteach[
     #:title "Projectile Movement"
     #:duration "15 minutes"
     #:overview "OPTIONAL: students discover that the \"mystery\" definitions in the game are actually used to add projetiles, and adapt these definitions to add a custom projectile and projectile animation to their game."
     #:learning-objectives @itemlist[@item{Students learn to move game elements through functions that compute attributes in one frame from attributes in the previous frame}]
     #:evidence-statements @itemlist[@item{Students will be able to write functions that take in one dimension of a game element's coordinate and produce the next coordinate value in that dimension}]
     #:product-outcomes @itemlist[@item{Students will add projectile movement to their games}]
     #:standards (list "N-Q" "A-CED.1-4" "F-IF.1-3" "F.IF.7-9" "F-BF.1-2" "F-LE.5")
     #:materials @itemlist[]
     #:preparation @itemlist[]
     #:pacings (list 
                @pacing[#:type "remediation"]{@itemlist[@item{}]}
                @pacing[#:type "misconception"]{@itemlist[@item{}]}
                @pacing[#:type "challenge"]{@itemlist[@item{}]}
                )
      ]{
        @points[@point{@student{This game template also has a mystery object, which is defined at the very bottom of the screen. The "mystery" is actually a @italic{projectile}, which will be set to the Player's position whenever the spacebar is pressed. As you can see, @code{mystery} is defined to be a small gray star, but you can change that to be any image you like. If you have a game in which the player is a monkey, you could change the definition of @code{mystery} to be a bitmap of a banana, so that the monkey will throw bananas every time you hit the spacebar. A game that takes place in space could have an alien throwing crystals, or a sports game might involve an athlete thowing a ball.
                                @activity{@itemlist[@item{Change the definition for @code{mystery}, so that your projectile looks the way you want it to. Don't forget to use @code{scale} and @code{rotate} if you need to change the image slightly.}
                                                     @item{Use the Design Recipe to write @code{update-mystery}, so that the projectile moves to the left or right. Hint: this will be very similar to your solutions for @code{update-danger} and @code{update-target}!}]}}
                        @teacher{}
                         }]
         }
       
@lesson/studteach[
     #:title "Closing"
     #:duration "5 minutes"
     #:overview ""
     #:learning-objectives @itemlist[]
     #:evidence-statements @itemlist[]
     #:product-outcomes @itemlist[]
     #:standards (list)
     #:materials @itemlist[]
     #:preparation @itemlist[]
     #:pacings (list 
                @pacing[#:type "remediation"]{@itemlist[@item{}]}
                @pacing[#:type "misconception"]{@itemlist[@item{}]}
                @pacing[#:type "challenge"]{@itemlist[@item{}]}
                )
      ]{
        @points[@point{@student{Congratulations - you've got the beginnings of a working game! However, several things remain unfinished:
                                @itemlist[@item{The Player doesn't move}
                                           @item{When the Target and Danger move offscreen, they never come back}
                                           @item{Nothing happens when the Player collides with the Danger or Target}]
                                The next few lessons will extend what you know about functions, so that you can define functions to implement each of these features.}
                        @teacher{@management{@itemlist[@item{Have students volunteer what they learned in this lesson}
                                                        @item{Reward behaviors that you value: teamwork, note-taking, engagement, etc}
                                                        @item{Pass out exit slips, dismiss, clean up.}]}}
                        }]
         }


@copyright[]
