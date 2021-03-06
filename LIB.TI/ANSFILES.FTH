CR .( ANSFILES  for CAMEL99 V2 BJF 02APR2018)

\ Requires CAMEL99 V2 with DISKDSR4 and FILESYSD

\ A subset of ANS Forth files wordset with TI-99 specific file control words

\ Dependancy:
\ TI-99 file system is record oriented not byte oriented
\ therefore READ-FILE and WRITE-FILE are NOT part of this lexicon.

\ ANS/ISO Forth Definitions used in this code:
\         fid -  file identifier (a file handle)
\         ior -  input/output response (the error number)
\         fam -  file access mode. see code for details

\ primitive file sys. commands for reference
\ : OPEN    ( -- ior)  0 FILEOP ;
\ : CLOSE   ( -- ior)  1 FILEOP ;
\ : READ    ( -- ior)  2 FILEOP ;
\ : WRITE   ( -- ior)  3 FILEOP ;
\ : REWIND  ( -- ior)  4 FILEOP ;
\ : LOAD    ( -- ior)  5 FILEOP ;
\ : SAVE    ( -- ior)  6 FILEOP ;
\ : DELETE  ( -- ior)  7 FILEOP ;
\ : SCRATCH ( -- ior)  8 FILEOP ;

CR .( ..)
\ File handle server
HEX
VARIABLE #FILES

CREATE PABS ( -- addr)   \ table for 8 potential PABs
             0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,

\ PTAB exposes PABS as an array
: ]PTAB   ( n -- addr )  2* PABS + ;

\ compute the VDP address for any PAB(n)
: PAB[N]  ( n -- VDPadr) 120 * 3FFF SWAP - ;

: ?FILES  ( n -- )  #FILES @ > ABORT" No more files" ;

: NEWHNDL ( -- hndl) \ returns first free handle
         0           \ start at handle=0
         BEGIN
           1+
           DUP ?FILES    \ have we exceeded #files allowed
           DUP ]PTAB @   \ fetch pab table contents
         0= UNTIL ;      \ loop until we find an empty location

\ the file handle selects the active PAB
: SELECT  ( hndl -- )
           DUP ?FILES
           ]PTAB @ DUP 0= ABORT" Null handle"
           ^PAB ! ;

: ASSIGN  ( hndl -- ) \ assign a new handle and SELECT it.
          DUP  
          DUP PAB[N] SWAP ]PTAB !
          SELECT ;

: RELEASE ( hndl -- ) 
          ]PTAB OFF  
          3FFF ^PAB ! ; \ INCLUDE assumes ^PAB starts at 3FFF.

\ user level command.
: FILES   ( n -- )
          DUP 8 > ABORT" too many files"
          #FILES ! ;
.( ..)
\ ===================================
\ file access mode configuration

VARIABLE FAM  \ we build the file access mode in a variable

\ and/or the contents of a variable with mask
 : AND!   ( mask addr -- ) TUCK @ AND SWAP ! ;
 : OR!    ( mask addr -- ) TUCK @  OR SWAP ! ;

\ TI-99 file access mode modifiers
 2 BASE !  \        *ctrl bits*
 : DISPLAY    ( -- ) 11110111 FAM AND! ;
 : SEQUENTIAL ( -- ) 11111110 FAM AND! ;
 : RELATIVE   ( -- ) 00000001 FAM OR! ;

 : UPDATE     ( -- ) 11111001 FAM AND! ;
 : INPUT      ( -- ) 00000100 FAM OR! ;
 : OUTPUT     ( -- ) 00000010 FAM OR! ;
 : APPEND     ( -- ) 00000110 FAM OR! ;

VARIABLE B/REC    \ bytes per record
 : VARI  ( size -- fam) B/REC ! 00010000 FAM  OR! ;
 : FIXED ( size -- fam) B/REC ! 11101111 FAM AND! ;

\ set fam on stack to default file format 
\ (in case the op forgets to set it up)
.( ..)
 HEX
\ These ANS word adjust and return the FAM variable
 : R/W   ( -- fam)  UPDATE  FAM @ ;
 : R/O   ( -- fam)  INPUT   FAM @ ;
 : W/O   ( -- fam)  OUTPUT  FAM @ ;

\ ANS Forth word replaces INTERNAL
 : BIN   ( fam -- fam') 8 OR ;  \ modify FAM on stack

\ needed to test for file args on stack
: DEPTH   ( -- n ) SP0 SP@ 2+ - 2/ ;

\ : ?EXISTS  ( -- )
\             FSTAT 8 AND
\             IF DISKOFF TRUE ABORT" No such file"
\             THEN ;

.( ..)
HEX
\ build the PAB from all the pieces, error checking
: OPEN-FILE ( $addr len fam -- fid ior)
             DEPTH 3 < ABORT" file args"
             NEWHNDL DUP >R ASSIGN    \ copy handle & assign PAB
             [PAB PSIZE 0 VFILL        \ erase the VDP PAB to be safe.

             ?DUP 0=                  \ is FAM 0
             IF    14
             THEN  [PAB FLG] VC!       \ write file access mode

             B/REC @ ?DUP 0=          \ test for new record length
             IF  50                   \ if not default to 80 bytes (>50)
             THEN [PAB RECLEN] VC!     \ store reclen in PAB
                  B/REC OFF           \ reset the B/REC variable

             2DUP MAKEPAB             \
             NEWFILE                  \ setup new file
             0 FILEOP ( -- err#)      \ call O/S OPEN
             DUP                      \ test for error
             IF   R> RELEASE 0 SWAP   \ release hndl. return 0
             ELSE R> SWAP
             THEN ;

: CLOSE-FILE  ( fid -- ?)
               DUP SELECT
               1 FILEOP
               SWAP RELEASE ;

: READ-LINE ( c-addr u1 fid -- u2 flag ior )
            SELECT
            2 FILEOP DUP >R               \ read operation, rpush error#
            IF                            \ if err#<>0
               0 FSTAT R>                 \ fatal error, don't read data
            ELSE
               ( -- adr u1)
               [PAB CHARS] VC@             \ get no. chars read
               MIN  >R                    \ MIN(u1,chars)= u2, rpush
               [PAB FBUFF] V@ SWAP R@  VREAD   \ move VDP fbuff to c-addr
               R>                         \ get u2 (chars actually read)
               EOF 0=                     \ test  EOF = 0
               R>                         \ bring back error#
            THEN ;

: WRITE-LINE ( c-addr u fileid -- ior )
             SELECT
             DUP [PAB CHARS] VC!         \ # chars to write ->PAB
             [PAB FBUFF] V@ SWAP VWRITE  \ write CPU RAM to VDP file buffer
             3 FILEOP                   \ call write operation
             FSTAT 2 AND FUSE           \ fuse EOF and general file errors
;
.( ..)
: CREATE-FILE ( caddr len fam -- fid ior )
\ OUTPUT mode forces new file creation in TI-99 O/S
               2 OR                     \ modify 'fam' bits to OUTPUT mode
               OPEN-FILE ;

: FILE-POSITION   ( fid -- n)   SELECT  [PAB REC#] V@ ;
: REPOSITION-FILE ( fid -- ior) SELECT  [PAB REC#] V!  4 FILEOP ;

: DELETE-FILE     ( caddr len -- ior ) R/W OPEN-FILE ?FILERR 7 FILEOP DROP ;

\ ===================================
8 FILES             \ set the #FILES now

DECIMAL

CR .( Max files set to ) #FILES @ .
( About 1080 bytes)
HEX


