TMGCOD02 ;TMG/kst-Code reassembly  ;2/17/15
         ;;1.0;TMG-LIB;**1**;2/15/15
 ;
 ;"TMG CODE REASSEBLY OF PARSED CODE
 ;
 ;"~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--
 ;"Copyright (c) 6/23/2015  Kevin S. Toppenberg MD
 ;"
 ;"This file is part of the TMG LIBRARY, and may only be used in accordence
 ;" to license terms outlined in separate file TMGLICNS.m, which should 
 ;" always be distributed with this file.
 ;"~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--
 ;
 ;"This is putting code block, as created by PARSPOS^TMGCOD01 back into an 
 ;"  an external form.
 ;"=======================================================================
 ;"=======================================================================
 ;" API -- Public Functions.
 ;"=======================================================================
 ;"ASSEMBLE(REFBLK,REFROOT,REFOUT,OFFSET,OPTIONS) ;"ASSEMBLE BLOCK INTO OUTPUT FORM
 ; 
 ;"=======================================================================
 ;" API - Private Functions
 ;"=======================================================================
 ;"ASMLINE(BLK,REFROOT,REFOUT,OFFSET,OPTIONS) ;"ASSEMBLY ONE BLOCK OF CODE INTO OUTPUT FORMAT  
 ;"ASMCMD(BLK,STRINGS,OPTIONS,OFFSET) ;"Assemble one command + args block
 ;"ASMARGS(BLK,STRINGS,OPTIONS,OFFSET) ;"Assemble args expression(s)
 ;"ASMARGSEQ(BLK,STRINGS,OPTIONS,OFFSET) ;"Assemble 1 arg sequence
 ;"ASMPREFN(TYPE,SEQBLK,STRINGS,OPTIONS,OFFSET) ;"Handle one part: $$FN
 ;"ASMINTFN(TYPE,SEQBLK,STRINGS,OPTIONS,OFFSET) ;"Handle one part: $FN
 ;"ASMARGPC(TYPE,SEQBLK,STRINGS,OPTIONS,OFFSET) ;"Handle one part: POST COND
 ;"ASMARGVR(TYPE,SEQBLK,STRINGS,OPTIONS,OFFSET) ;"Handle one part: VAR
 ;"ASMARGST(TYPE,SEQBLK,STRINGS,OPTIONS) ;"Handle one part: STRING
 ;"ASMARG01(TYPE,SEQBLK,OPTIONS) ;"Handle one part: (Arbitrary type)
 ;"TAGVAL(VALUE,TYPE,SEQBLK,OPTIONS)  ;"Add tags etc from OPTIONS (if any)
 ;"WRAPAREN(VALUE,OPTIONS) ;"Wrap value in parentheses, with tags...
 ;
 ;"=======================================================================
 ;"Dependancies
 ;"=======================================================================
 ;" TMGSTUT3, TMGCOD01, XLFSTR, TMGUSRI2, XLFDT
 ;"=======================================================================
 ;
ASSEMBLE(REFBLK,REFROOT,REFOUT,OFFSET,OPTIONS) ;"ASSEMBLE BLOCK INTO OUTPUT FORM 
  ;"Input: REFBLK -- PASS BY NAME.  Name of variable containing parsed
  ;"               code, as output by PARSEPOS^TMGCOD01.  See format there.
  ;"       REFROOT -- PASS BY NAME.  Should be null ("") or equal to REFOUT on first
  ;"            call.  Used for recursive calls.  
  ;"       REFOUT -- PASS BY NAME.  An array.  Format: 
  ;"          @REFOUT@(OFFSET)=<line of code>
  ;"       OFFSET -- Used in recurvice calls.  PASS BY REFERENCE. **LEAVE BLANK ON FIRST CALL**
  ;"       OPTIONS -- PASS BY REFERENCE.  OPTIONAL
  ;"            OPTIONS("XPND")=1 -> return full length forms of functions and commands
  ;"            OPTIONS("ABVR")=1 -> return abrieviated forms of functions and commands
  ;"                 Note: if neither of above found, then original form returned.  
  ;"            OPTIONS(<TYPE>,"PRE")=<PREFIX TEXT>  NOTE: Ignored if "FN" node exists   
  ;"            OPTIONS(<TYPE>,"POST")=<POSTFIX TEXT> NOTE: Ignored if "FN" node exists
  ;"            OPTIONS(<TYPE>,"FN")=<Mumps function entry point>  
  ;"                  Example entry: '$$MyFn^MyMod' <-- must start with $$, no parameters
  ;"                  Actual function must declared to accept the following parameters:
  ;"                        (VALUE,TYPE,SEQBLK,OPTIONS), 
  ;"                    and must return resulting string
  ;"                  Example function: MyFn(AVALUE,ATYPE,ABLK,SOMEOPT) ;Located in MyMod routine
  ;"              Possible values for <TYPE> as follows:
  ;"                 "$$FN", "$FN", "POST COND", "NUM", "VAR", "COMP/ASSIGN",
  ;"                  "BOOL", ":", "@", "CONCAT", "STRING", "MATH", "DOT", 
  ;"                  "OTHER", "CMD", ",", "COMMENT", "TAG", "ROUTINE", "PARENS",
  ;"                  "CARET","LINEFEED","TAB","GLOBAL","INDENT","FULLLINE"
  ;"Results: none
  ;
  SET OFFSET=$GET(OFFSET)
  SET REFROOT=$GET(REFROOT) IF REFROOT="" SET REFROOT=REFBLK
  FOR  SET OFFSET=$ORDER(@REFBLK@(OFFSET)) QUIT:+OFFSET'=OFFSET  DO
  . NEW ASSEMBLEBLK MERGE ASSEMBLEBLK=@REFBLK@(OFFSET)
  . NEW LINE SET LINE=$$ASMLINE(.ASSEMBLEBLK,REFROOT,REFOUT,.OFFSET,.OPTIONS)
  . SET @REFOUT@(OFFSET)=LINE
  QUIT
  ;
ASMLINE(ASLBLK,REFROOT,REFOUT,OFFSET,OPTIONS) ;"ASSEMBLY ONE BLOCK OF CODE INTO OUTPUT FORMAT  
  ;"Input: ASLBLK -- PASS BY REFERENCE.  Array of parsed code for 1 line of mumps code
  ;"       REFROOT -- PASS BY NAME.  Name of ROOT of source array. 
  ;"       REFOUT -- PASS BY NAME.  Output array.   
  ;"       OFFSET -- PASS BY REFERENCE.
  ;"       OPTIONS -- PASS BY REFERENCE.  See ASSEMBLE for format
  NEW STRINGS MERGE STRINGS=ASLBLK("STRINGS")
  NEW TAG SET TAG=$GET(ASLBLK("TAG"))
  NEW PLAINTAG SET PLAINTAG=TAG
  SET TAG=$$TAGVAL(TAG,"TAG",,.OPTIONS)
  NEW ARGSPTR SET ARGSPTR=+$GET(ASLBLK("TAG","ARGS")) 
  NEW TAGARGS MERGE TAGARGS=@REFROOT@("ARGS",OFFSET,ARGSPTR)
  NEW TAGARGSTR SET TAGARGSTR=$GET(TAGARGS)
  IF (TAGARGSTR'="()"),$DATA(TAGARGS)>0 DO
  . SET TAGARGSTR=$$ASMARGS(.TAGARGS,.STRINGS,.OPTIONS,OFFSET) 
  . IF TAGARGSTR'="" DO WRAPAREN(.TAGARGSTR,.OPTIONS) ; 
  NEW INDENT SET INDENT=$GET(ASLBLK("INDENT"))
  NEW PREDOT SET PREDOT=$PIECE(INDENT,".",1)
  NEW DOTON SET DOTON=$EXTRACT(INDENT,$LENGTH(PREDOT)+1,$LENGTH(INDENT))
  SET PREDOT=$$TAGVAL(PREDOT_"^"_PLAINTAG,"INDENT",,.OPTIONS)  ;"Handler will use TAG in case indent holds a TAB char
  IF DOTON["." DO
  . NEW DOT SET DOT=$$TAGVAL(".","DOT",,.OPTIONS) QUIT:DOT="."
  . SET DOTON=$$REPLSTR^TMGSTUT3(DOTON,".",DOT)
  NEW RESULT SET RESULT=TAG_TAGARGSTR_PREDOT_DOTON
  ;"Cycle through each command for this line.
  NEW CODE SET CODE=""
  NEW CMDIDX SET CMDIDX=""
  FOR  SET CMDIDX=$ORDER(ASLBLK(CMDIDX)) QUIT:+CMDIDX'>0  DO
  . NEW CMDWARG MERGE CMDWARG=ASLBLK(CMDIDX)
  . IF $DATA(CMDWARG("."))>0 DO
  . . ;"NEW ASMLDOTBLK MERGE ASMLDOTBLK=CMDWARG(".")
  . . NEW ASMLDOTBLK MERGE ASMLDOTBLK=@REFROOT@(".",OFFSET)
  . . ;"This will add DO block entries below this line in output array, before this line is finished.
  . . DO ASSEMBLE("ASMLDOTBLK",REFROOT,REFOUT,OFFSET,.OPTIONS) 
  . NEW PART SET PART=$$ASMCMD(.CMDWARG,.STRINGS,.OPTIONS,OFFSET)
  . IF CODE'="" SET CODE=CODE_" "
  . SET CODE=CODE_PART
  ;
  SET RESULT=RESULT_CODE
  NEW TRAILING SET TRAILING=$GET(ASLBLK("TRAILING"))
  IF $E(RESULT,$LENGTH(RESULT))=" " SET TRAILING=$EXTRACT(TRAILING,2,$LENGTH(TRAILING))
  NEW COMMENT SET COMMENT=$GET(ASLBLK("COMMENT"))
  SET COMMENT=$$TAGVAL(COMMENT,"COMMENT",,.OPTIONS)
  SET COMMENT=TRAILING_COMMENT
  ;"IF COMMENT'="",$EXTRACT(RESULT,$LENGTH(RESULT))'=" " DO
  ;". SET COMMENT=COMMENT
  SET RESULT=RESULT_COMMENT
  SET RESULT=$$PROCLINE(RESULT,.ASLBLK,.OPTIONS)
  QUIT RESULT
  ;
ASMCMD(ASCBLK,STRINGS,OPTIONS,OFFSET) ;"Assemble one command + args block
  ;"Input: ASCBLK -- PASS BY REFERENCE.  Array of parsed code for command & args
  ;"       STRINGS -- PASS BY REFERENCE.  Array of strings for subsitution from ;#;
  ;"       OPTIONS -- PASS BY REFERENCE.  See ASSEMBLE for format
  NEW RESULT SET RESULT=""
  NEW LMODE SET LMODE="O"
  IF $GET(OPTIONS("XPND"))=1 SET LMODE="X"
  ELSE  IF $GET(OPTIONS("ABVR"))=1 SET LMODE="A"
  ;"Get Command name  
  NEW CMD SET CMD=$GET(ASCBLK("CMD"),"??")
  IF LMODE="X" SET CMD=$GET(ASCBLK("CMD","XPND"),"??")
  ELSE  IF LMODE="A" SET CMD=$GET(ASCBLK("CMD","ABVR"),"??")  
  SET RESULT=$GET(ASCBLK("CMD","PRECEEDING"))  ;"usually null, but not always.
  SET RESULT=RESULT_$$TAGVAL(CMD,"CMD",.ASCBLK,.OPTIONS)
  ;"Get post-conditional (if any)
  NEW ARGSPTR SET ARGSPTR=+$GET(ASCBLK("POST COND")) 
  NEW PCBLK MERGE PCBLK=@REFROOT@("ARGS",OFFSET,ARGSPTR)
  ;"NEW PCBLK MERGE PCBLK=ASCBLK("POST COND")
  IF $DATA(PCBLK) DO
  . NEW PCCODE SET PCCODE=$$ASMARGS(.PCBLK,.STRINGS,.OPTIONS,OFFSET)
  . IF PCCODE="" QUIT
  . SET RESULT=RESULT_":"_PCCODE  
  SET RESULT=RESULT_" "
  SET ARGSPTR=+$GET(ASCBLK("CMD ARGS")) 
  NEW ARGSBLK MERGE ARGSBLK=@REFROOT@("ARGS",OFFSET,ARGSPTR)
  ;"NEW ARGSBLK MERGE ARGSBLK=ASCBLK("CMD ARGS")
  SET RESULT=RESULT_$$ASMARGS(.ARGSBLK,.STRINGS,.OPTIONS,OFFSET)
  QUIT RESULT
  ;
ASMARGS(ASABLK,STRINGS,OPTIONS,OFFSET) ;"Assemble args expression(s)
  ;"Input: ASABLK -- PASS BY REFERENCE.  Array of parsed code for args
  ;"       STRINGS -- PASS BY REFERENCE.  Array of strings for subsitution from ;#;
  ;"       OPTIONS -- PASS BY REFERENCE.  See ASSEMBLE for format
  NEW RESULT SET RESULT=""
  NEW ARGIDX SET ARGIDX=0
  FOR  SET ARGIDX=$ORDER(ASABLK(ARGIDX)) QUIT:+ARGIDX'>0  DO
  . IF ARGIDX'=1 SET RESULT=RESULT_$$TAGVAL(",","COMMA",.ASABLK,.OPTIONS)
  . NEW ARGSEQBLK MERGE ARGSEQBLK=ASABLK(ARGIDX)
  . SET RESULT=RESULT_$$ASMARGSEQ(.ARGSEQBLK,.STRINGS,.OPTIONS,OFFSET)
  QUIT RESULT
  ;
ASMARGSEQ(ASASBLK,STRINGS,OPTIONS,OFFSET) ;"Assemble 1 arg sequence
  ;"Input: ASASBLK -- PASS BY REFERENCE.  Array of parsed code for args
  ;"       STRINGS -- PASS BY REFERENCE.  Array of strings for subsitution from ;#;
  ;"       OPTIONS -- PASS BY REFERENCE.  See ASSEMBLE for format
  NEW RESULT SET RESULT=""
  NEW SEQIDX SET SEQIDX=0
  NEW TYPESTR SET TYPESTR="^NUM^COMP/ASSIGN^BOOL^:^@^CONCAT^MATH^OTHER^CARET^"
  SET TYPESTR=TYPESTR_"GLOBAL^LINEFEED^TAB^"
  FOR  SET SEQIDX=$ORDER(ASASBLK(SEQIDX)) QUIT:+SEQIDX'>0  DO
  . NEW TEMP,TYPE SET TYPE=$ORDER(ASASBLK(SEQIDX,"")) QUIT:TYPE=""
  . NEW SEQBLK MERGE SEQBLK=ASASBLK(SEQIDX,TYPE)
  . DO
  . . IF TYPE="PROC" SET TEMP=$$ASMPREFN(TYPE,.SEQBLK,.STRINGS,.OPTIONS,OFFSET) QUIT
  . . IF TYPE="$$FN" SET TEMP=$$ASMPREFN(TYPE,.SEQBLK,.STRINGS,.OPTIONS,OFFSET) QUIT
  . . IF TYPE="$FN" SET TEMP=$$ASMINTFN(TYPE,.SEQBLK,.STRINGS,.OPTIONS,OFFSET) QUIT
  . . IF TYPE="$SV" SET TEMP=$$ASMSPVAR(TYPE,.SEQBLK,.STRINGS,.OPTIONS,OFFSET) QUIT
  . . IF TYPE="POST COND" SET TEMP=$$ASMARGPC(TYPE,.SEQBLK,.STRINGS,.OPTIONS,OFFSET) QUIT
  . . IF TYPE="STRING" SET TEMP=$$ASMARGST(TYPE,.SEQBLK,.STRINGS,.OPTIONS) QUIT
  . . IF TYPE="VAR" SET TEMP=$$ASMARGVR(TYPE,.SEQBLK,.STRINGS,.OPTIONS,OFFSET) QUIT
  . . IF TYPESTR["^"_TYPE_"^" DO  QUIT
  . . . SET TEMP=$$ASMARG01(TYPE,.SEQBLK,.OPTIONS)
  . . SET TEMP=""
  . SET RESULT=RESULT_TEMP
  QUIT RESULT
  ;
ASMPREFN(TYPE,SEQBLK,STRINGS,OPTIONS,OFFSET) ;"ASSEMBLE PROC OR EXTERNAL FN
  ;"Purpose: Handle one part: $$FN or procedure 
  NEW FNPNAME SET FNPNAME=$GET(SEQBLK("VALUE"))
  NEW FNPMODL SET FNPMODL=$GET(SEQBLK("ROUTINE"))
  IF FNPMODL="[LOCAL]" SET FNPMODL=""  ;"//kt
  IF FNPMODL'="" SET FNPMODL="^"_FNPMODL
  NEW ARGSPTR SET ARGSPTR=+$GET(SEQBLK("ARGS")) 
  NEW ARGSBLK MERGE ARGSBLK=@REFROOT@("ARGS",OFFSET,ARGSPTR)
  ;"NEW ARGSBLK MERGE ARGSBLK=SEQBLK("ARGS")
  NEW ARGS SET ARGS=""
  IF $DATA(ARGSBLK) DO
  . SET ARGS=$$ASMARGS(.ARGSBLK,.STRINGS,.OPTIONS,OFFSET)
  . DO WRAPAREN(.ARGS,.OPTIONS)
  NEW RESULT SET RESULT=$$TAGVAL(FNPNAME_FNPMODL,TYPE,.SEQBLK,.OPTIONS)
  SET RESULT=RESULT_ARGS
  QUIT RESULT
  ;
ASMINTFN(TYPE,SEQBLK,STRINGS,OPTIONS,OFFSET) ;"Handle one part: $FN
  NEW FNNAME SET FNNAME=$GET(SEQBLK("VALUE"))
  IF $GET(OPTIONS("XPND"))=1 SET FNNAME=$GET(SEQBLK("VALUE","XPND"),"?")
  IF $GET(OPTIONS("ABVR"))=1 SET FNNAME=$GET(SEQBLK("VALUE","ABVR"),"?")
  NEW ARGSPTR SET ARGSPTR=+$GET(SEQBLK("ARGS")) 
  NEW ARGSBLK MERGE ARGSBLK=@REFROOT@("ARGS",OFFSET,ARGSPTR)
  ;"NEW ARGSBLK MERGE ARGSBLK=SEQBLK("ARGS")
  NEW ARGS SET ARGS=""
  IF $DATA(ARGSBLK) DO
  . SET ARGS=$$ASMARGS(.ARGSBLK,.STRINGS,.OPTIONS,OFFSET)
  . DO WRAPAREN(.ARGS,.OPTIONS)
  NEW RESULT SET RESULT=FNNAME_ARGS
  SET RESULT=$$TAGVAL(RESULT,TYPE,.SEQBLK,.OPTIONS)
  QUIT RESULT
  ;
ASMSPVAR(TYPE,SEQBLK,STRINGS,OPTIONS,OFFSET) ;"Handle one part: $SV SPECIAL VARIABLES. 
  NEW SVNAME SET SVNAME=$GET(SEQBLK("VALUE"))
  IF $GET(OPTIONS("XPND"))=1 SET SVNAME=$GET(SEQBLK("VALUE","XPND"),"?")
  IF $GET(OPTIONS("ABVR"))=1 SET SVNAME=$GET(SEQBLK("VALUE","ABVR"),"?")
  NEW RESULT SET RESULT=$$TAGVAL(SVNAME,TYPE,.SEQBLK,.OPTIONS)
  QUIT RESULT
  ;
ASMARGPC(TYPE,SEQBLK,STRINGS,OPTIONS,OFFSET) ;"Handle one part: POST COND
  NEW ARGSPTR SET ARGSPTR=+$GET(SEQBLK) 
  MERGE SEQBLK=@REFROOT@("ARGS",OFFSET,ARGSPTR)  
  NEW RESULT SET RESULT=$$ASMARGS(.SEQBLK,.STRINGS,.OPTIONS,OFFSET)
  IF RESULT'="" SET RESULT=":"_RESULT
  SET RESULT=$$TAGVAL(RESULT,TYPE,.SEQBLK,.OPTIONS)
  QUIT RESULT
  ;
ASMARGVR(TYPE,SEQBLK,STRINGS,OPTIONS,OFFSET) ;"Handle one part: VAR
  NEW RESULT SET RESULT=$GET(SEQBLK("VALUE"))
  NEW TEMP SET TEMP=RESULT
  IF RESULT="<NULL>" DO
  . SET RESULT=""  ;"signal indicating '()'
  NEW ARGSPTR SET ARGSPTR=+$GET(SEQBLK("PARENS")) 
  NEW ARGSBLK MERGE ARGSBLK=@REFROOT@("ARGS",OFFSET,ARGSPTR)
  ;"NEW ARGSBLK MERGE ARGSBLK=SEQBLK("PARENS")
  NEW ARGS SET ARGS=""
  IF $DATA(ARGSBLK) DO
  . SET ARGS=$$ASMARGS(.ARGSBLK,.STRINGS,.OPTIONS,OFFSET)
  . DO WRAPAREN(.ARGS,.OPTIONS)
  SET RESULT=RESULT_ARGS  
  SET RESULT=$$TAGVAL(RESULT,TYPE,.SEQBLK,.OPTIONS)
  QUIT RESULT
  ;
ASMARGST(TYPE,SEQBLK,STRINGS,OPTIONS) ;"Handle one part: STRING
  NEW NUM SET NUM=+$GET(SEQBLK("NUM"))
  NEW RESULT SET RESULT=$GET(STRINGS(NUM))  
  SET RESULT=$$TAGVAL(RESULT,TYPE,.SEQBLK,.OPTIONS)
  QUIT RESULT
  ;
ASMARG01(TYPE,SEQBLK,OPTIONS) ;"Handle one part: (Arbitrary type)
  NEW VALUE SET VALUE=$GET(SEQBLK("VALUE"))
  NEW RESULT SET RESULT=$$TAGVAL(VALUE,TYPE,.SEQBLK,.OPTIONS)
  QUIT RESULT
  
TAGVAL(VALUE,TYPE,SEQBLK,OPTIONS)  ;"Add tags etc from OPTIONS (if any)
  NEW RESULT SET RESULT=$GET(VALUE)
  IF RESULT="" GOTO TVDN  ;"Don't add tags if value is empty.
  SET TYPE=$GET(TYPE,"?")
  NEW FN SET FN=$GET(OPTIONS(TYPE,"FN"))
  IF $EXTRACT(FN,1,2)="$$" DO
  . SET FNX="SET RESULT="_FN_"(VALUE,TYPE,.SEQBLK,.OPTIONS)"
  . XECUTE FNX
  ELSE  DO
  . NEW PRE SET PRE=$GET(OPTIONS(TYPE,"PRE"))
  . NEW POST SET POST=$GET(OPTIONS(TYPE,"POST"))
  . SET RESULT=PRE_VALUE_POST
TVDN ;  
  QUIT RESULT
  ;
WRAPAREN(VALUE,OPTIONS) ;"Wrap value in parentheses, with tags...
  SET VALUE=$GET(VALUE) ;" QUIT:VALUE=""
  NEW PRE SET PRE=$GET(OPTIONS("PARENS","PRE"))
  NEW POST SET POST=$GET(OPTIONS("PARENS","POST"))
  SET VALUE=PRE_"("_POST_VALUE_PRE_")"_POST
  QUIT
  ;
PROCLINE(VALUE,BLK,OPTIONS)  ;"Process entire line, after assembled  
  NEW RESULT SET RESULT=$GET(VALUE)
  NEW FN SET FN=$GET(OPTIONS("FULLLINE","FN"))
  IF $EXTRACT(FN,1,2)="$$" DO
  . SET FNX="SET RESULT="_FN_"(VALUE,,.BLK,.OPTIONS)"
  . XECUTE FNX
  QUIT RESULT
    
  