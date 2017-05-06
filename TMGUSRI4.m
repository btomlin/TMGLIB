TMGUSRI4 ;TMG/kst/SACC-compliant USER INTERFACE API FUNCTIONS ;8/13/13, 2/2/14
         ;;1.0;TMG-LIB;**1,17**;6/26/13
 ;
 ;"TMG USER INTERFACE API FUNCTIONS
 ;"SACC-Compliant version
 ;
 ;"~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--
 ;"Copyright (c) 6/23/2015  Kevin S. Toppenberg MD
 ;"
 ;"This file is part of the TMG LIBRARY, and may only be used in accordence
 ;" to license terms outlined in separate file TMGLICNS.m, which should 
 ;" always be distributed with this file.
 ;"~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--
 ;
 ;"NOTE: This will contain SACC-compliant code.
 ;"=======================================================================
 ;" API -- Public Functions.
 ;"=======================================================================
 ;"FLDSEL(FILE,OPTION) --A GUI field name selector from specified file
 ;"RECSEL(FILE,IENS,OPTION) --A GUI record selector from specified file
 ;"LISTSEL(PARRAY,TMGLSOPT) -- Allow user to pick from list, in a dynamic fashion.
 ;
 ;"=======================================================================
 ;"Private Functions
 ;"=======================================================================
 ;"HNDLSEL(PARRAY,OPTION,INFO) -- Handle ON SELECTION event from Scroller, from LISTSEL
 ;"HNDLKP(PARRAY,OPTION,INFO) -- Handle ON KEYPRESS event from Scroller, from LISTSEL
 ;
 ;"=======================================================================
 ;"DEPENDENCIES:  TMGUSRIF <-- NOTE: not yet SACC compliant 
 ;"=======================================================================
 ;
RECSEL(FILE,IENS,OPTION) ;
        ;"Purpose: Provide a GUI record selector from specified file
        ;"Input: FILE -- name or number of fileman file
        ;"       IENS -- ignored unless FILE represents a subfile.  Format:
        ;"           e.g. IENS="?,456,123," for a sub-sub-file record selection
        ;"       OPTION PASS BY REFERENCE.  [OPTIONAL PARAMETER].  Array with options, as below
        ;"           OPTION("NCS")=0 If present, then search IS case sensitive.  Default is to be not case sensitive.
        ;"           OPTION("HEADER",#) -- OPTIONAL.  Header for displaying list
        ;"Results: returns IEN^Name in specified file, or 0 IF none chosen, or -1^Message IF error.
        NEW TMGRESULT SET TMGRESULT=0
        NEW FNUM SET FNUM=$GET(FILE)
        IF +FNUM'>0 SET FNUM=$$GETFNUM^TMGDBAP3(FNUM)
        SET OPTION("NCS")=$GET(OPTION("NCS"),1)
        NEW REFARR,TMGDA
        DO GETREFAR^TMGDBAP3(FNUM,.REFARR)
        IF $$ISSUBFIL^TMGDBAP3(FNUM) DO
        . NEW NUMNOD SET NUMNOD=$LENGTH(IENS,",")
        . NEW CT SET CT=1
        . NEW IDX FOR IDX=NUMNOD-1:-1:2 DO
        . . SET TMGDA(CT)=$PIECE(IENS,",",IDX),CT=CT+1
        NEW REF SET REF=$GET(REFARR(1,"GL"))_"""B"")"
        SET REF=$NAME(@REF)
        NEW REF2,IDX SET IDX=""
        FOR  SET IDX=$ORDER(@REF@(IDX)) QUIT:(IDX="")  DO
        . NEW IEN SET IEN=0 FOR  SET IEN=$ORDER(@REF@(IDX,IEN)) QUIT:(+IEN'>0)  DO
        . . NEW ROOTREF SET ROOTREF=REFARR(1,"GL")_IEN_")"
        . . NEW ZN SET ZN=$GET(@ROOTREF@(0))
        . . NEW NAME SET NAME=$PIECE(ZN,"^",1)
        . . SET REF2(NAME,IEN)=""
        SET OPTION("INDX")=1
        NEW Y SET Y=$$LISTSEL(REF,.OPTION)
        IF Y>0 SET Y=Y_"^"_$$GET1^DIQ(FNUM,Y,.01)
        SET TMGRESULT=Y
        QUIT TMGRESULT
        ;
FLDSEL(FILE,OPTION) ;
        ;"Purpose: Provide a GUI field name selector from specified file
        ;"Input: FILE -- name or number of fileman file
        ;"       OPTION PASS BY REFERENCE.  [OPTIONAL PARAMETER].  Array with options, as below
        ;"           OPTION("NCS")=1 If present, then search is NOT case sensitive.  Default is to be case sensitive.
        ;"           OPTION("HEADER",#) -- OPTIONAL.  Header for displaying list
        ;"Results: returns field number from specified file, or 0 IF none chosen, or -1^Message IF error.
        NEW TMGRESULT SET TMGRESULT=0
        NEW FNUM SET FNUM=$GET(FILE)
        IF +FNUM'>0 SET FNUM=$$GETFNUM^TMGDBAP3(FNUM)
        SET OPTION("INDX")=1
        SET TMGRESULT=$$LISTSEL($NAME(^DD(FNUM,"B")),.OPTION)
        QUIT TMGRESULT
        ;
LISTSEL(PARRAY,OPTION) ;
        ;"Purpose: given input array, allow user to pick from list, in a dynamic fashion.
        ;"         I.e., as they type, a list of of all matching items is shown,
        ;"         with list of matching items ever shrinking as the user types
        ;"         more and more matching characters.  Match can occur anywhere
        ;"         in the input string.  
        ;"Input: PARRAY.  PASS BY NAME.  Expected format:
        ;"         IF OPTION("INDX")=1 then
        ;"           @PARRAY@(<SearchableItem>,<ReturnValue>)="" (Only first node is significant, other nodes are allowed, but are ignored.)
        ;"           @PARRAY@(<SearchableItem>,<ReturnValue>)=""
        ;"         ELSE 
        ;"           @PARRAY@(<SearchableItem>, ... , ...)=<ReturnValue>  (Only first node is significant, other nodes are allowed, but are ignored.)
        ;"           @PARRAY@(<SearchableItem>, ... , ...)=<ReturnValue> (ReturnValue is optional)
        ;"       OPTION.  PASS BY REFERENCE.  [OPTIONAL PARAMETER].  Array with options, as below
        ;"           OPTION("INDX")=1 See PARRAY above.
        ;"           OPTION("NCS")=1 If present, then search is NOT case sensitive.  Default is to be case sensitive.
        ;"           OPTION("HEADER") -- OPTIONAL.  Header for displaying list
        ;"Result: Returns full string of selected item, or "" IF nothing selected (or ^ entered)
        NEW TMPLSARRAY,TMGMASTERARRAY
        NEW TMGRESULT SET TMGRESULT=""
        NEW CNT SET CNT=1
        NEW IDX SET IDX=""
        FOR  SET IDX=$ORDER(@PARRAY@(IDX)) QUIT:(IDX="")  DO
        . NEW RETURNVAL
        . IF $GET(OPTION("INDX"))=1 DO
        . . SET RETURNVAL=$ORDER(@PARRAY@(IDX,""))
        . . IF RETURNVAL="" SET RETURNVAL=0
        . ELSE  DO
        . . SET RETURNVAL=$GET(@PARRAY@(IDX))
        . . IF RETURNVAL="" SET RETURNVAL=IDX
        . SET TMPLSARRAY(CNT,IDX)=RETURNVAL,CNT=CNT+1
        MERGE TMGMASTERARRAY=TMPLSARRAY
        NEW TMGSCRLOPT MERGE TMGSCRLOPT=OPTION
        IF $GET(TMGSCRLOPT("HEADER",1))="" SET TMGSCRLOPT("HEADER",1)="Pick Item"
        SET IDX=+$ORDER(TMGSCRLOPT("FOOTER",""),-1)+1
        SET TMGSCRLOPT("FOOTER",IDX)="(Type letters to narrow selection list) (^ to abort)"
        SET TMGSCRLOPT("ON SELECT")="HNDLSEL^TMGUSRI4"
        IF $GET(TMGSCRLOPT("ON CMD"))="" SET TMGSCRLOPT("ON CMD")=TMGSCRLOPT("ON SELECT")
        SET TMGSCRLOPT("ON KEYPRESS")="HNDLKP^TMGUSRI4"
        DO SCROLLER^TMGUSRIF("TMPLSARRAY",.TMGSCRLOPT)  ;"Event handler(s) setup TMGRESULT
        QUIT TMGRESULT
        ;
HNDLSEL(PARRAY,OPTION,INFO) ;
        ;"Purpose: Handle ON SELECTION event from Scroller, from LISTSEL
        ;"Input: PARRAY -- PASSED BY NAME.  This is array that is displayed.  See SCROLLER^TMGUSRIF for documentation
        ;"       OPTION -- -- PASSED BY REFERENCE.  This is OPTION array.  See SCROLLER^TMGUSRIF for documentation
        ;"       INFO -- PASSED BY REFERENCE.  An Array with releventy information.
        ;"          INFO("CURRENT LINE","NUMBER")=number currently highlighted line
        ;"          INFO("CURRENT LINE","TEXT")=Text of currently highlighted line
        ;"          INFO("CURRENT LINE","RETURN")=return value of currently highlighted line
        ;"    Referenced globally scoped variables --
        ;"        TMGSCLRMSG,TMGRESULT
        ;"Result: NONE
        ;"Output: May affect globally-scoped variable TMGSCLRMSG to communicate back to Scroller
        ;"        May affect globally-scoped variable TMGRESULT
        SET TMGRESULT=$GET(INFO("CURRENT LINE","RETURN"))
        SET TMGSCLRMSG="^"
        QUIT
        ;
HNDLKP(PARRAY,OPTION,INFO) ;
        ;"Purpose: Handle ON KEYPRESS event from Scroller, from LISTSEL
        ;"Input: PARRAY -- PASSED BY NAME.  This is array that is displayed.  See SCROLLER^TMGUSRIF for documentation
        ;"       OPTION -- -- PASSED BY REFERENCE.  This is OPTION array.  See SCROLLER^TMGUSRIF for documentation
        ;"       INFO -- PASSED BY REFERENCE.  An Array with releventy information.
        ;"          INFO("USER INPUT")=Key pressed.
        ;"          INFO("CMD")=User full input command so far (being built up)
        ;"    Referenced globally scoped variables --
        ;"        TMGMASTERARRAY,TMGSCLRMSG,TMGRESULT,TMGSCRLOPT
        ;"Result: NONE
        ;"Output: May affect globally-scoped variable TMGSCLRMSG to communicate back to Scroller
        NEW FILTER SET FILTER=$GET(INFO("CMD"))
        NEW CASE SET CASE=$GET(TMGSCRLOPT("NCS"))
        NEW FILTARR
        NEW PNUM FOR PNUM=1:1:$LENGTH(FILTER," ") DO
        . NEW FILTERPART SET FILTERPART=$PIECE(FILTER," ",PNUM)
        . IF CASE=1 SET FILTERPART=$$UP^XLFSTR(FILTERPART)
        . IF FILTERPART="" SET FILTERPART=" "  ;"//KT 8/13/13
        . SET FILTARR(FILTERPART)=""
        IF CASE=1 SET FILTER=$$UP^XLFSTR(FILTER)
        NEW FILTEREDARR
        NEW CNT SET CNT=1
        NEW IDX SET IDX=0
        FOR  SET IDX=$ORDER(TMGMASTERARRAY(IDX)) QUIT:IDX=""  DO
        . NEW NAME,NAMEARR SET NAME=$ORDER(TMGMASTERARRAY(IDX,"")) QUIT:NAME=""
        . NEW ORIGNAME SET ORIGNAME=NAME
        . IF CASE=1 SET NAME=$$UP^XLFSTR(NAME)
        . NEW FILTERPART SET FILTERPART=""
        . NEW OK SET OK=1
        . FOR  SET FILTERPART=$ORDER(FILTARR(FILTERPART)) QUIT:(FILTERPART="")!(OK=0)  DO
        . . SET OK=(NAME[FILTERPART)
        . IF OK=0 QUIT
        . ;"IF NAME[FILTER SET FILTEREDARR(CNT,ORIGNAME)=$GET(TMGMASTERARRAY(IDX,ORIGNAME)),CNT=CNT+1
        . SET FILTEREDARR(CNT,ORIGNAME)=$GET(TMGMASTERARRAY(IDX,ORIGNAME)),CNT=CNT+1
        KILL @PARRAY
        MERGE @PARRAY=FILTEREDARR
        QUIT
        ;
TEST ;
        NEW TEMP MERGE TEMP=^DD(63.04,"B")
        NEW OPT SET OPT("NCS")=1
        SET OPT("HEADER",1)="PICK FIELD NAME"
        NEW RESULT SET RESULT=$$LISTSEL("TEMP",.OPT)
        W #
        WRITE RESULT
        QUIT
        ;        
READLEN(PROMPT,MAXLEN,INDENT) ;"Get input string from user, showing limiting length
        ;"Input: PROMPT -- instruction text to display
        ;"       MAXLEN -- the maximum length of allowed reply
        ;"       INDENT -- OPTIONAL.  Amount to indent. 
        NEW TMGRESULT SET TMGRESULT=""
        SET INDENT=+$GET(INDENT)
        NEW INDENTSTR SET INDENTSTR=""
        IF INDENT>0 SET INDENTSTR=$JUSTIFY(" ",INDENT)
        NEW LINE SET $PIECE(LINE,"-",MAXLEN)="" SET LINE=LINE_">|"
        NEW PROMPTLEN SET PROMPTLEN=$LENGTH(PROMPT)
        NEW LEN SET LEN=INDENT+PROMPTLEN+MAXLEN
        WRITE $JUSTIFY(" ",LEN),"|",!
        WRITE INDENTSTR,$JUSTIFY(" ",PROMPTLEN),LINE,!
        DO CUU^TMGTERM(2)
        WRITE INDENTSTR,PROMPT
        READ TMGRESULT#MAXLEN:$GET(DTIME,3600)
        WRITE !,INDENTSTR,$JUSTIFY(" ",LEN+2),!
        DO CUU^TMGTERM(1)
        QUIT TMGRESULT
        ;