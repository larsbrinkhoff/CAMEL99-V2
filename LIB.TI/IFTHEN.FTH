CR .( Compiler extensions...)
\ part of the kernel. Here for reference or if you need them

\ branch calculators/compilers help me understand this code better
: AHEAD   ( -- addr)  HERE   0 , ;
: BACK    ( addr -- ) HERE   - , ;
: RESOLVE ( addr -- ) HERE OVER - SWAP ! ;

CR .( branching)
: IF     ( ? -- ) POSTPONE ?BRANCH AHEAD 2 ;        IMMEDIATE
: THEN   ( -- )  ?COMP  2 ?PAIRS RESOLVE ;          IMMEDIATE
: ELSE   ( -- )  2 ?PAIRS  POSTPONE BRANCH AHEAD SWAP 2
                      POSTPONE THEN 2 ;             IMMEDIATE

CR .( infinite loop compilers)
: BEGIN  ( -- addr n) ?COMP HERE  1  ;              IMMEDIATE
: AGAIN  ( -- )   1 ?PAIRS POSTPONE BRANCH BACK   ; IMMEDIATE
: UNTIL  ( ? -- ) 1 ?PAIRS POSTPONE ?BRANCH BACK  ; IMMEDIATE
: WHILE  ( ? -- ) POSTPONE IF  2+  ;                IMMEDIATE
: REPEAT ( -- ) 2>R  POSTPONE AGAIN  2R> 2- 
                POSTPONE THEN ; IMMEDIATE
