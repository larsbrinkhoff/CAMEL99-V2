## CAMEL99 FORTH V2 Source files
This files must be compiled with XFC99.EXE under DOS.

See CAMEL99 V1.x /COMPILER for the program.

https://github.com/bfox9900/CAMEL99/tree/master/Compiler


### FOLDER Changes Required
In the file CAMEL2.HSF find the section that looks like this:

\ ADD-ONS

\ ** commment out everything to build the smallest kernel  **

 [CC] include CC9900\cclib\crusmall.hsf
 
 [CC] include CC9900\cclib\diskdsr4.hsf

[CC] include CC9900\cclib\filesysA.hsf

 You must either create the same folders in your DOSBOX or DOS system
 and copy the source code there.
                             -OR-
Change the paths to match the locations of the files in your system.

