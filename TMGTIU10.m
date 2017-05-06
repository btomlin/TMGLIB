TMGTIU10 ;TMG/kst-Scanning notes for followups ; 11/12/14
         ;;1.0;TMG-LIB;**1,17**;10/21/14
 ;
 ;"Kevin Toppenberg MD
 ;
 ;"~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--
 ;"Copyright (c) 6/23/2015  Kevin S. Toppenberg MD
 ;"
 ;"This file is part of the TMG LIBRARY, and may only be used in accordence
 ;" to license terms outlined in separate file TMGLICNS.m, which should 
 ;" always be distributed with this file.
 ;"~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--
 ;
 ;"=======================================================================
 ;"PUBLIC FUNCTIONS
 ;"=======================================================================
 ;"RPCCKDUE(TMGRESULT,TMGDFN)-- RPC Entry point to check if patient is overdue for appt
 ;"$$SCANNOTE(DFN,TIUIEN,REFOUT) - To scan one note and get back info about followup
 ;"$$SCANPT(DFN,REFOUT,SDT,EDT,SCREEN,TITLEARR) -- Scan one patient during specified date range, and compile followup info
 ;"SCANTIU  -- scan all TIU documents, to pre-parse them for faster access later 
 ;"$$SCANALL(REFOUT,SDT,EDT,SCREEN,TITLEARR) -- Scan all patients during specified date range, and compile followup info
 ;"SELSHOW  -- scan all patients, and then allow inspection of details.
 ;"LISTDUE -- scan all patients, and then list due status.  Output to printer
 ;"
 ;"=======================================================================
 ;"PRIVATE FUNCTIONS
 ;"======================================================================= 
 ;"TST1NOTE ;
 ;"HASFUTXT(REF,IDX,TAG,LINETEXT)  
 ;"RESOLVDT(TIUDATE,S)  -- Read S, determine date, and add to TIUDATE
 ;"DELIDX(WORDARR,IDX,IDX2)  ;"Delete Index, or index range from WORDARR, and renumber entries
 ;"DATEIDX(WORDARR)  ;"Return index in WORDARR of entry with ##/##/##(##) format, or ##/##(##) format 
 ;"MONTHIDX(WORDARR)  ;"Return index in WORDARR of any month
 ;"WORDIDX(WORDARR,AWORD,LOOSE) ;"Return index in WORDARR of AWORD, or -1 if not found
 ;"INRANGE(NUM,LO,HI)  ;"Check if Num is in between LO and HI (inclusive) 
 ;"ISPREV(S) ;"Check for 'previously' and all it's misspellings
 ;"ISSCHED(S)  ;"Check for 'scheduled' and all it's misspellings
 ;"ISWKDAY(S) ; "Is string a week day name?  Assumes S is upper case
 ;"MONTHNUM(S) ; "Is string a month name?  Assumes S is upper case
 ;"GETMNDT(BASEDATE,MONTHNUM) ;"Return date for month number after basedate
 ;"GETFMDT(S) ;TURN S INTO FILEMAN DATE IF POSSIBLE
 ;"ASMBLEDT(YR,MONTH,DAY) ;"ASSEMBLE DATE.  Input YR must be 4 digits.
 ;"GETDT(BASEDT,NUM,TYPE) -- Return a date, based on basedate + offset 
 ;"DISPINFO(DFN,INFO) -- display info from scanned array
 ;"PTCOLOR(STATUS,MONTHS) ;"Get color for patient status
 ;"=======================================================================
 ;"Dependancies : TMGHTM1, XLFSTR, TMGSTUTL, XLFDT, TMGPXR03
 ;"=======================================================================
 ;
TST1NOTE ;
  NEW TIUIEN,OUT
  READ "Enter TIU IEN: ",TIUIEN:$GET(DTIME,3600),!
  NEW ZN SET ZN=$GET(^TIU(8925,TIUIEN,0))
  NEW DFN SET DFN=+$PIECE(ZN,"^",2)  
  NEW TMGRESULT SET TMGRESULT=$$SCANNOTE(DFN,TIUIEN,"OUT",1)
  IF $DATA(OUT) DO ZWRITE^TMGZWR("OUT")
  ELSE  WRITE "NOTHING FOUND",!
  QUIT
  ;
SCANNOTE(DFN,TIUIEN,REFOUT,NOPRIOR) ;
  ;"Purpose: To scan one note and get back info about followup
  ;"Input: DFN -- PATIENT IEN
  ;"       TIUIEN-- IEN in 8925
  ;"       REFOUT -- PASS BY NAME.  An OUT PARAMETER  (prior contents not deleted)
  ;"       NOPRIOR -- OPTIONAL.  If 1 then prior stored results will be ignored. 
  ;"Result: 1^OK, or 0^None or -1^Message
  ;"Output:  @REFOUT@ is filled as follows
  ;"         @REFOUT@(DFN,TIUIEN,F/U_TEXT)=""
  ;"         @REFOUT@(DFN,TIUIEN,F/U_FMDATE)=""  <-- e.g. if 3 month followup on 7/4/14, will return 10/4/14 in FM format
  ;"         @REFOUT@("B",DFN,GREATEST_FOLLOWUP_DATE)=NOTE_DATE
  ;"         @REFOUT@("C",DFN,NOTE_DATE)=FOLLOWUP_DATE
  ;"         @REFOUT@("D",DFN)=GREATEST_FOLLOWUP_DATE
  ;"         @REFOUT@("E",DFN,NOTE_FM_DATE,FU_DATE)=F/U_TEXT
  ;"     ALSO, fields 22712,22713 in file 8925 may be filled with findings 
  NEW TMGRESULT SET TMGRESULT="0^None"
  NEW LINETEXT SET LINETEXT=""
  NEW FUDATE SET FUDATE=-1
  NEW FUTEXT SET FUTEXT="FOLLOW UP APPT:"
  NEW TIUDATE SET TIUDATE=0
  NEW TEMP,FOUND SET FOUND=0  
  SET NOPRIOR=$GET(NOPRIOR)   
  IF NOPRIOR'=1 DO
  . SET TEMP=$$READINFO(DFN,TIUIEN,.FUDATE,.LINETEXT,.TIUDATE) 
  . IF TEMP>0 SET FOUND=2
  IF FOUND=0 DO
  . SET TEMP=$$GETINFO(TIUIEN,.FUDATE,.LINETEXT,.TIUDATE) 
  . SET FOUND=$PIECE(TEMP,"^",1)
  SET LINETEXT=$$TRIM^XLFSTR($EXTRACT(LINETEXT,1,128)) 
  IF FOUND=0 SET LINETEXT=""
  IF FOUND>0 DO
  . SET TMGRESULT="1^OK"
  . SET @REFOUT@(DFN,TIUIEN)=TIUDATE_"^"_FUDATE
  . SET @REFOUT@("C",DFN,+TIUDATE)=FUDATE
  . NEW PRIORFU SET PRIORFU=+$GET(@REFOUT@("D",DFN))
  . IF FUDATE>PRIORFU DO
  . . SET @REFOUT@("D",DFN)=FUDATE
  . . KILL @REFOUT@("B",DFN) SET @REFOUT@("B",DFN,+FUDATE)=TIUDATE  
  . IF LINETEXT'="" SET @REFOUT@(DFN,TIUIEN,LINETEXT)=""
  . IF FUDATE'=-1 SET @REFOUT@("E",DFN,TIUDATE,FUDATE)=LINETEXT
  . IF FOUND'=2 DO    ;"Store data for faster access next time. 
  . . SET TMGRESULT=$$SAVEINFO(DFN,TIUIEN,FUDATE,LINETEXT,TIUDATE) 
  QUIT TMGRESULT
  ;"
GETINFO(TIUIEN,FUDATE,LINETEXT,TIUDATE) ;
  ;"Purpose: To scan one note and get back info about followup
  ;"Input: TIUIEN-- IEN in 8925
  ;"       FUDATE -- PASS BY REFERENCE.  An OUT PARAMETER
  ;"       LINETEXT-- PASS BY REFERENCE.  An OUT PARAMETER
  ;"       TIUDATE-- PASS BY REFERENCE.  An OUT PARAMETER
  ;"Result: 1^OK, or 0^None or -1^Message
  ;"Output:  FUDATE follow up date found in document. FM format.
  ;"         LINETEXT follow up text found in document.
  ;"         TIUDATE the episode begin date of the document.  
  ;"NOTE: This assumes that note is COMPLETED etc, and is ready for scanning.  
  NEW TMGRESULT SET TMGRESULT="0^None"
  SET LINETEXT=""
  SET FUDATE=-1
  NEW ZN SET ZN=$GET(^TIU(8925,TIUIEN,0))
  ;"NEW DFN SET DFN=+$PIECE(ZN,"^",2)
  SET TIUDATE=$PIECE(ZN,"^",7)
  NEW DOCIEN SET DOCIEN=$PIECE(ZN,"^",1)
  NEW FOUND SET FOUND=0
  NEW FUTEXT SET FUTEXT="FOLLOW UP APPT:"
  NEW TEXTIEN SET TEXTIEN=0
  FOR  SET TEXTIEN=$ORDER(^TIU(8925,TIUIEN,"TEXT",TEXTIEN)) QUIT:(TEXTIEN'>0)!(FOUND>0)  DO
  . SET LINETEXT=$GET(^TIU(8925,TIUIEN,"TEXT",TEXTIEN,0))
  . IF $$HASFUTXT($NAME(^TIU(8925,TIUIEN,"TEXT")),TEXTIEN,FUTEXT,.LINETEXT)=1 DO
  . . IF $$ISHTML^TMGHTM1(TIUIEN) DO
  . . . SET LINETEXT=LINETEXT_$GET(^TIU(8925,TIUIEN,"TEXT",TEXTIEN+1,0)) ;"Sometimes line wraps
  . . . SET LINETEXT=$PIECE(LINETEXT,"<BR>",1)
  . . . SET LINETEXT=$$HTML2TXS^TMGHTM1(LINETEXT)
  . . IF LINETEXT["NON-FASTING" SET LINETEXT=$PIECE(LINETEXT,"NON-FASTING",1)
  . . IF LINETEXT["FASTING LABS" SET LINETEXT=$PIECE(LINETEXT,"FASTING LABS",1)
  . . SET LINETEXT=$$TRIM^XLFSTR($PIECE(LINETEXT,FUTEXT,2))
  . . IF LINETEXT="" QUIT
  . . SET FUDATE=$$RESOLVDT(TIUDATE,LINETEXT)
  . . SET FOUND=1
  SET LINETEXT=$$TRIM^XLFSTR($EXTRACT(LINETEXT,1,128)) 
  IF FOUND=0 SET LINETEXT=""
  IF FOUND>0 SET TMGRESULT="1^OK"
  QUIT TMGRESULT
  ;"
  ;"-----------------------------------------------------  
  ;"DOSCAN(TIUIEN,REFOUT,NOPRIOR) ;
  ;"  ;"Purpose: To scan one note and get back info about followup
  ;"  ;"Input: TIUIEN-- IEN in 8925
  ;"  ;"       REFOUT -- PASS BY NAME.  An OUT PARAMETER  (prior contents not deleted)
  ;"  ;"       NOPRIOR -- OPTIONAL.  If 1 then prior stored results will be ignored. 
  ;"  ;"Result: 1^OK, or 0^None or -1^Message
  ;"  ;"Output:  @REFOUT@ is filled as follows
  ;"  ;"         @REFOUT@(DFN,TIUIEN,F/U_TEXT)=""
  ;"  ;"         @REFOUT@(DFN,TIUIEN,F/U_FMDATE)=""  <-- e.g. if 3 month followup on 7/4/14, will return 10/4/14 in FM format
  ;"  ;"         @REFOUT@("A",DFN,NOTE_TITLE_IEN,MOST_RECENT_REQUESTED_FOLLOWUP_FM_DATE)=""
  ;"  ;"         @REFOUT@("B",DFN,GREATEST_FOLLOWUP_DATE)=NOTE_DATE
  ;"  ;"         @REFOUT@("C",DFN,NOTE_DATE)=FOLLOWUP_DATE
  ;"  ;"         @REFOUT@("D",DFN)=GREATEST_FOLLOWUP_DATE
  ;"  ;"         @REFOUT@("E",DFN,NOTE_FM_DATE,FU_DATE)=F/U_TEXT
  ;"  ;"     ALSO, fields 22712,22713 in file 8925 may be filled with findings 
  ;"  NEW TMGRESULT SET TMGRESULT="0^None"
  ;"  NEW LINETEXT SET LINETEXT=""
  ;"  NEW FUDATE SET FUDATE=-1
  ;"  NEW ZN SET ZN=$GET(^TIU(8925,TIUIEN,0))
  ;"  NEW DFN SET DFN=+$PIECE(ZN,"^",2)
  ;"  NEW TIUDATE SET TIUDATE=$PIECE(ZN,"^",7)
  ;"  NEW DOCIEN SET DOCIEN=$PIECE(ZN,"^",1)
  ;"  SET NOPRIOR=$GET(NOPRIOR)   
  ;"  NEW TMG SET TMG=$GET(^TIU(8925,TIUIEN,"TMG"))
  ;"  NEW FOUND SET FOUND=0
  ;"  IF ($PIECE(TMG,"^",3)'="")&(NOPRIOR'=1) DO  GOTO SNDN
  ;"  . SET FUDATE=$PIECE(TMG,"^",3)
  ;"  . IF FUDATE>4000000 SET FUDATE=-1  ;"IF YEAR IS GREATER THAN 2100 ASSUME ERROR
  ;"  . SET LINETEXT=$PIECE(TMG,"^",4)
  ;"  . SET FOUND=2
  ;"  NEW FUTEXT SET FUTEXT="FOLLOW UP APPT:"
  ;"  NEW TEXTIEN SET TEXTIEN=0
  ;"  FOR  SET TEXTIEN=$ORDER(^TIU(8925,TIUIEN,"TEXT",TEXTIEN)) QUIT:(TEXTIEN'>0)!(FOUND>0)  DO
  ;"  . SET LINETEXT=$GET(^TIU(8925,TIUIEN,"TEXT",TEXTIEN,0))
  ;"  . IF $$HASFUTXT($NAME(^TIU(8925,TIUIEN,"TEXT")),TEXTIEN,FUTEXT,.LINETEXT)=1 DO
  ;"  . . IF $$ISHTML^TMGHTM1(TIUIEN) DO
  ;"  . . . SET LINETEXT=LINETEXT_$GET(^TIU(8925,TIUIEN,"TEXT",TEXTIEN+1,0)) ;"Sometimes line wraps
  ;"  . . . SET LINETEXT=$PIECE(LINETEXT,"<BR>",1)
  ;"  . . . SET LINETEXT=$$HTML2TXS^TMGHTM1(LINETEXT)
  ;"  . . IF LINETEXT["NON-FASTING" SET LINETEXT=$PIECE(LINETEXT,"NON-FASTING",1)
  ;"  . . IF LINETEXT["FASTING LABS" SET LINETEXT=$PIECE(LINETEXT,"FASTING LABS",1)
  ;"  . . SET LINETEXT=$$TRIM^XLFSTR($PIECE(LINETEXT,FUTEXT,2))
  ;"  . . IF LINETEXT="" QUIT
  ;"  . . SET FUDATE=$$RESOLVDT(TIUDATE,LINETEXT)
  ;"  . . SET FOUND=1
  ;"SNDN ;  
  ;"  SET LINETEXT=$$TRIM^XLFSTR($EXTRACT(LINETEXT,1,128)) 
  ;"  IF FOUND=0 SET LINETEXT=""
  ;"  ;"IF LINETEXT="" SET LINETEXT="?"
  ;"  IF FOUND>0 DO
  ;"  . SET TMGRESULT="1^OK"
  ;"  . SET @REFOUT@(DFN,TIUIEN)=TIUDATE_"^"_FUDATE
  ;"  . SET @REFOUT@("A",DFN,DOCIEN,FUDATE)=""
  ;"  . SET @REFOUT@("C",DFN,TIUDATE)=FUDATE
  ;"  . NEW PRIORFU SET PRIORFU=+$GET(@REFOUT@("D",DFN))
  ;"  . IF FUDATE>PRIORFU DO
  ;"  . . SET @REFOUT@("D",DFN)=FUDATE
  ;"  . . KILL @REFOUT@("B",DFN) SET @REFOUT@("B",DFN,FUDATE)=TIUDATE  
  ;"  . IF LINETEXT'="" SET @REFOUT@(DFN,TIUIEN,LINETEXT)=""
  ;"  . IF FUDATE'=-1 SET @REFOUT@("E",DFN,TIUDATE,FUDATE)=LINETEXT
  ;"  IF FOUND'=2 DO    ;"STORE VALUES IN FIELD 22712,22713   
  ;"  . NEW TMGFDA,TMGMSG,IENS SET IENS=TIUIEN_","
  ;"  . SET TMGFDA(8925,IENS,22712)=FUDATE
  ;"  . NEW STR SET STR=LINETEXT IF STR="?" SET STR=""
  ;"  . SET TMGFDA(8925,IENS,22713)=STR
  ;"  . DO FILE^DIE("","TMGFDA","TMGMSG")
  ;"  . IF $DATA(TMGMSG("DIERR")) SET TMGRESULT="-1^"_$$GETERRST^TMGDEBU2(.TMGMSG)  
  ;"  IF 1=0,(FOUND'=0),(FUDATE=-1),(LINETEXT'="") DO  ;"DEBUG BLOCK, DISABLED...
  ;"  . IF LINETEXT="in  months for a recheck, sooner if any problems." QUIT
  ;"  . WRITE !,DFN," ",TIUIEN," NOTE: ",$$FMTE^XLFDT(TIUDATE,"5D")," --> "
  ;"  . ;"IF FOUND=0 WRITE "(no ",FUTEXT," tag found)",! QUIT
  ;"  . IF FUDATE=-1 WRITE "??/??/????"
  ;"  . ELSE  WRITE $$FMTE^XLFDT(FUDATE,"5D")
  ;"  . WRITE " <-- ",LINETEXT,".",!
  ;"  QUIT TMGRESULT
  ;"  ;"
  ;"-----------------------------------------------------  
SAVEINFO(DFN,IEN8925,FUDT,FUTEXT,TIUDATE) ;
  ;"Purpose: Store gathered information for faster access in future
  ;"Input: DFN -- patient IEN 
  ;"       IEN8925 -- IEN in 8925
  ;"       FUDT -- the follow up date found in narrative, to be stored, in FM format
  ;"       FUTEXT -- the raw follow up narrative found in text, to be stored.  
  ;"Result: 1^OK, or -1^Error message
  NEW TMGRESULT SET TMGRESULT="1^OK"
  SET IEN8925=+$GET(IEN8925) IF IEN8925'>0 DO  GOTO SIDN
  . SET TMGRESULT="-1^IEN in file 8925 not provided to SAVEINFO^TMGTIU10"
  SET FUDT=+$GET(FUDT) IF (FUDT'>0)&(FUDT'=-1) DO  GOTO SIDN
  . SET TMGRESULT="-1^Follow up date not provided to SAVEINFO^TMGTIU10"
  SET FUTEXT=$GET(FUTEXT) 
  SET DFN=+$GET(DFN) IF DFN'>0 DO  GOTO SIDN
  . SET TMGRESULT="-1^DFN not provided to SAVEINFO^TMGTIU10"
  NEW TMGFDA,TMGIEN,TMGIENS,TMGMSG  
  IF $DATA(^TMG(22731,DFN))>0 GOTO SI2   ;"Skip if Pt already has entry
  SET TMGIEN(1)=DFN
  SET TMGFDA(22731,"+1,",.01)=DFN
  DO UPDATE^DIE("","TMGFDA","TMGIEN","TMGMSG")
  IF $DATA(TMGMSG("DIERR")) DO  GOTO SIDN
  . SET TMGRESULT="-1^"_$$GETERRST^TMGDEBU2(.TMGMSG) 
  IF $DATA(^TMG(22731,DFN))=0 DO  GOTO SIDN
  . SET TMGRESULT="-1^Unable to find record in 22731 for DFN="_DFN 
SI2 ;  
  KILL TMGFDA,TMGMSG,TMGIEN
  IF $DATA(^TMG(22731,DFN,"DOC",IEN8925))>0 SET TMGIENS=IEN8925_","_DFN_","
  ELSE  SET TMGIENS="+1,"_DFN_","
  SET TMGFDA(22731.01,TMGIENS,.01)=IEN8925
  SET TMGFDA(22731.01,TMGIENS,.02)=FUDT
  SET TMGFDA(22731.01,TMGIENS,.03)=FUTEXT
  SET TMGFDA(22731.01,TMGIENS,.04)=TIUDATE
  IF TMGIENS["+" DO
  . SET TMGIEN(1)=IEN8925
  . DO UPDATE^DIE("","TMGFDA","TMGIEN","TMGMSG")
  ELSE  DO
  . DO FILE^DIE("","TMGFDA","TMGMSG")
  IF $DATA(TMGMSG("DIERR")) DO  GOTO SIDN
  . SET TMGRESULT="-1^"_$$GETERRST^TMGDEBU2(.TMGMSG) 
SIDN ;  
  QUIT TMGRESULT
  ;
READINFO(DFN,IEN8925,FUDT,FUTEXT,TIUDATE) ;"Gather stored information from prior scan
  ;"Input: DFN -- patient IEN 
  ;"       IEN8925 -- IEN in 8925
  ;"       FUDT -- PASS BY REFERENCE.  AN OUT PARAMETER. 
  ;"       FUTEXT -- PASS BY REFERENCE.  AN OUT PARAMETER.  
  ;"       TIUDATE -- PASS BY REFERENCE.  AN OUT PARAMETER.  
  ;"Result: 1 if date found, or 0 if not found. 
  NEW ZN SET ZN=$GET(^TMG(22731,DFN,"DOC",IEN8925,0))
  SET FUDT=$PIECE(ZN,"^",2),FUTEXT=$PIECE(ZN,"^",3),TIUDATE=$PIECE(ZN,"^",4)
  QUIT (FUDT'="")
  ;
HASFUTXT(REF,IDX,TAG,LINETEXT)  ;
  NEW TMGRESULT SET TMGRESULT=0
  NEW WORDS DO SPLIT2AR^TMGSTUT2(TAG," ",.WORDS)  
  NEW TEMPSTRING SET TEMPSTRING=$GET(@REF@(IDX,0))
  IF (TEMPSTRING[WORDS(1))&(TEMPSTRING'[WORDS(WORDS("MAXNODE"))) DO
  . SET TEMPSTRING=TEMPSTRING_$GET(@REF@(IDX+1,0))
  IF TEMPSTRING[TAG DO
  . ;"SET LINETEXT=TEMPSTRING
  . SET TMGRESULT=1
  QUIT TMGRESULT
  ;" 
RESOLVDT(TIUDATE,S)   ;
  ;"Purpose: Read S, determine date, and add to TIUDATE
  ;"Input: TIUDATE -- FM date of note (Episode Begin Date)
  ;"       S -- Line of text from TIU Note, with followup timeframe
  ;"Output : none
  ;"Result: FM Date if found
  ;"        1 if 'PRN' type of followup
  ;"        -1 if can't determine
  NEW TMGRESULT SET TMGRESULT=-1
  NEW APPROX SET APPROX=0
  SET S=$$UP^XLFSTR(S)
  IF $EXTRACT(S,1)="~" SET APPROX=1 SET S=$EXTRACT(S,2,999)
  NEW WORDS
  DO SPLIT2AR^TMGSTUT2(S," ",.WORDS)
  NEW IDX SET IDX=""
  FOR  SET IDX=$ORDER(WORDS(IDX)) QUIT:(IDX="")  DO
  . IF WORDS(IDX)["." DO
  . . IF $LENGTH(WORDS(IDX),".")>2 QUIT
  . . IF +$PIECE(WORDS(IDX),".",1)'>0 QUIT
  . . IF +$PIECE(WORDS(IDX),".",2)'>0 QUIT
  . . SET WORDS(IDX)=$$REPLSTR^TMGSTUT3(WORDS(IDX),".","^&^")  
  . SET WORDS(IDX)=$TRANSLATE($GET(WORDS(IDX)),".,;","")
  . IF WORDS(IDX)["^&^" SET WORDS(IDX)=$$REPLSTR^TMGSTUT3(WORDS(IDX),"^&^",".")  
  . IF WORDS(IDX)="" KILL WORDS(IDX) QUIT
  . IF WORDS(IDX)="IN",IDX=$ORDER(WORDS("")) KILL WORDS(IDX) QUIT
  . IF WORDS(IDX)="RETURN",IDX=$ORDER(WORDS("")) KILL WORDS(IDX) QUIT
  . IF WORDS(IDX)="ABOUT",IDX=$ORDER(WORDS("")) SET APPROX=1 KILL WORDS(IDX) QUIT
  . IF WORDS(IDX)="AROUND",IDX=$ORDER(WORDS("")) SET APPROX=1 KILL WORDS(IDX) QUIT
  . IF WORDS(IDX)["APPROX",IDX=$ORDER(WORDS("")) SET APPROX=1 KILL WORDS(IDX) QUIT
  . IF WORDS(IDX)["/B" KILL WORDS(IDX) QUIT
  . IF WORDS(IDX)="ONE" SET WORDS(IDX)="1" QUIT
  . IF WORDS(IDX)="TWO" SET WORDS(IDX)="2" QUIT
  . IF WORDS(IDX)="SIX" SET WORDS(IDX)="6" QUIT
  . IF WORDS(IDX)="FEW" SET WORDS(IDX)="6" QUIT
  . IF WORDS(IDX)="APPOINTMENT" SET WORDS(IDX)="APPT" QUIT
  . IF (WORDS(IDX)="MOTH")!(WORDS(IDX)="MOTHS") SET WORDS(IDX)="MONTH" QUIT
  . IF $$ISPREV(WORDS(IDX)) SET WORDS(IDX)="PREVIOUS" QUIT
  . IF $$ISSCHED(WORDS(IDX)) SET WORDS(IDX)="SCHEDULE" QUIT
  NEW TMP,TMPIDX SET TMPIDX=1,IDX=0
  FOR  SET IDX=$ORDER(WORDS(IDX)) Q:(+IDX'>0)  SET TMP(TMPIDX)=WORDS(IDX),TMPIDX=TMPIDX+1
  KILL WORDS MERGE WORDS=TMP KILL TMP
  NEW MAXIDX SET MAXIDX=+$ORDER(WORDS(""),-1)
  NEW PRNFOUND SET PRNFOUND=0
  NEW RESTART
L1 ;  
  SET RESTART=0
  SET S="",IDX=0 FOR  SET IDX=$ORDER(WORDS(IDX)) QUIT:+IDX'>0  SET S=S_$GET(WORDS(IDX))_" "
  FOR IDX=MAXIDX+1:1:3 SET WORDS(IDX)="X"
  IF $$POS^TMGSTUT3("TO BE DETERMINED",S)=1 SET TMGRESULT=1 GOTO RSLDTDN
  NEW W1,W1IDX SET W1IDX=1,W1=$GET(WORDS(W1IDX))
  NEW W2,W2IDX SET W2IDX=2,W2=$GET(WORDS(W2IDX))
  NEW W3,W3IDX SET W3IDX=3,W3=$GET(WORDS(W3IDX))
  ;"IF (W1["PRN")!($$POS^TMGSTUT3("PRN",S)=1) SET TMGRESULT=1 GOTO RSLDTDN
  IF (W1["PRN")!($$POS^TMGSTUT3("PRN",S)=1) DO  GOTO L1
  . SET PRNFOUND=1,RESTART=1 DO DELIDX(.WORDS,1)
  IF W1="NEXT" DO  GOTO:(RESTART=1) L1 GOTO:(TMGRESULT>0) RSLDTDN 
  . IF W2["MONTH" SET TMGRESULT=$$GETDT(TIUDATE,1,"M") QUIT
  . IF W2["WEEK" SET TMGRESULT=$$GETDT(TIUDATE,1,"W") QUIT
  . IF (W2["YEAR")!(W2["YR") SET TMGRESULT=$$GETDT(TIUDATE,1,"Y") QUIT
  . IF $$ISWKDAY(W2) SET TMGRESULT=$$GETDT(TIUDATE,1,"W") QUIT
  . SET MONTHNUM=$$MONTHNUM(W2)
  . IF MONTHNUM>0 SET TMGRESULT=$$GETMNDT(TIUDATE,MONTHNUM) QUIT
  . DO DELIDX(.WORDS,1) SET RESTART=1 QUIT
  . ;"IF +W2>0 SET W1=W2,W2=W3,W3=$GET(WORDS(4)) QUIT  
  IF W1="ON",$$ISWKDAY(W2) SET TMGRESULT=$$GETDT(TIUDATE,1,"W") GOTO RSLDTDN
  IF W1="THIS" DO  GOTO:(TMGRESULT>0) RSLDTDN
  . IF W2["COMING" SET W2=W3,W3=""
  . IF $$ISWKDAY(W2) SET TMGRESULT=$$GETDT(TIUDATE,1,"W") QUIT
  IF $$ISWKDAY(W1) SET TMGRESULT=$$GETDT(TIUDATE,1,"W") GOTO RSLDTDN
  IF (W1["HAS"),(W2["APPT")!(W2["APPOINT") DO  GOTO:(RESTART=1) L1 GOTO:(TMGRESULT>0) RSLDTDN
  . SET MONTHNUM=$$MONTHNUM(W3)
  . IF MONTHNUM=0 DO
  . . NEW IDX SET IDX=$$MONTHIDX(.WORDS)
  . . IF IDX>2 SET MONTHNUM=$$MONTHNUM(WORDS(IDX))
  . IF MONTHNUM>0 SET TMGRESULT=$$GETMNDT(TIUDATE,MONTHNUM) QUIT
  . SET PRNFOUND=1,RESTART=1 DO DELIDX(.WORDS,1,2) QUIT
  . ;"NEW DTIDX SET DTIDX=$$DATEIDX(.WORDS) IF DTIDX>0 DO  QUIT:(TMGRESULT>0) 
  . ;". NEW S SET S=$GET(WORDS(DTIDX))
  . ;". SET TMGRESULT=$$GETFMDT(S)    
  . ;"SET TMGRESULT=1 QUIT
  IF W1["LATER",W2["THIS" DO  GOTO:(TMGRESULT>0) RSLDTDN
  . IF W3["MONTH" SET TMGRESULT=$$GETDT(TIUDATE,1,"M") QUIT
  . IF W3["WEEK" SET TMGRESULT=$$GETDT(TIUDATE,1,"W") QUIT
  IF (+W1>0)&(W2["MONTH") SET TMGRESULT=$$GETDT(TIUDATE,+W1,"M") GOTO RSLDTDN
  IF (+W1>0)&(W1["MONTH") SET TMGRESULT=$$GETDT(TIUDATE,+W1,"M") GOTO RSLDTDN
  IF (+W1>0)&((W2["YEAR")!(W2["YR")) SET TMGRESULT=$$GETDT(TIUDATE,+W1,"Y") GOTO RSLDTDN
  IF (+W1>0)&((W1["YEAR")!(W2["YR")) SET TMGRESULT=$$GETDT(TIUDATE,+W1,"Y") GOTO RSLDTDN
  IF (+W1>0)&(W2["WEEK") SET TMGRESULT=$$GETDT(TIUDATE,+W1,"W") GOTO RSLDTDN
  IF (+W1>0)&(W1["WEEK") SET TMGRESULT=$$GETDT(TIUDATE,+W1,"W") GOTO RSLDTDN
  IF (+W1>0)&(W2["DAY") SET TMGRESULT=$$GETDT(TIUDATE,+W1,"D") GOTO RSLDTDN
  IF (+W1>0)&(W1["DAY") SET TMGRESULT=$$GETDT(TIUDATE,+W1,"D") GOTO RSLDTDN
  IF (W1["/")&(+W1>0)&(+$PIECE(W1,"/",2)>0) SET TMGRESULT=$$GETFMDT(W1) GOTO:(TMGRESULT>0) RSLDTDN
  IF (+W1>0) SET TMGRESULT=$$GETDT(TIUDATE,+W1,"M") GOTO RSLDTDN
  IF $$WORDIDX(.WORDS,"ASAP")>0 SET TMGRESULT=$$GETDT(TIUDATE,1,"M") GOTO RSLDTDN
  SET IDX=$$WORDIDX(.WORDS,"AFTER") IF IDX>0 DO  GOTO:(TMGRESULT>0) RSLDTDN
  . NEW DTWORD SET DTWORD=$GET(WORDS(IDX+1))
  . SET MONTHNUM=$$MONTHNUM(DTWORD)
  . IF MONTHNUM>0 DO
  . . NEW DY SET DY=$GET(WORDS(IDX+2))
  . . NEW YR SET YR=$GET(WORDS(IDX+3))
  . . IF (+DY>0)&(+YR>0) SET DTWORD=MONTHNUM_"/"_DY_"/"_YR
  . IF DTWORD["/" SET TMGRESULT=$$GETFMDT(DTWORD) QUIT:(TMGRESULT>0)
  SET IDX=$$WORDIDX(.WORDS,"IN") 
  IF IDX=1 SET PRNFOUND=1,RESTART=1 DO DELIDX(.WORDS,1) GOTO L1  
  IF IDX>0 DO  GOTO:(TMGRESULT>0) RSLDTDN
  . NEW DTWORD SET DTWORD=$GET(WORDS(IDX+1))
  . SET MONTHNUM=$$MONTHNUM(DTWORD)
  . IF MONTHNUM>0 SET TMGRESULT=$$GETMNDT(TIUDATE,MONTHNUM) QUIT
  IF $$WORDIDX(.WORDS,"TOMORROW")>0 SET TMGRESULT=$$GETDT(TIUDATE,1,"D") GOTO RSLDTDN
  IF $$POS^TMGSTUT3("NEXT AVAIL",S)>0 SET TMGRESULT=$$GETDT(TIUDATE,3,"M") GOTO RSLDTDN
  NEW DTIDX SET DTIDX=$$DATEIDX(.WORDS) IF DTIDX>0 DO  GOTO:(TMGRESULT>0) RSLDTDN
  . NEW S SET S=$GET(WORDS(DTIDX))
  . SET TMGRESULT=$$GETFMDT(S)    
  SET IDX=$$WORDIDX(.WORDS,"MONTH",1) IF IDX>0 DO  GOTO:(TMGRESULT>0) RSLDTDN
  . NEW NUM SET NUM=$GET(WORDS(IDX-1))
  . IF (NUM["FEW")!(NUM["SEVER") SET NUM=3
  . IF +NUM>0 SET TMGRESULT=$$GETDT(TIUDATE,+NUM,"M") QUIT
  SET IDX=$$WORDIDX(.WORDS,"WEEK",1) IF IDX>0 DO  GOTO:(TMGRESULT>0) RSLDTDN
  . NEW NUM SET NUM=$GET(WORDS(IDX-1))
  . IF (NUM["FEW")!(NUM["SEVER") SET NUM=3
  . IF +NUM>0 SET TMGRESULT=$$GETDT(TIUDATE,+NUM,"W") QUIT
  SET IDX=$$WORDIDX(.WORDS,"YR",1) IF IDX>0 DO  GOTO:(TMGRESULT>0) RSLDTDN
  . NEW NUM SET NUM=$GET(WORDS(IDX-1))
  . IF +NUM>0 SET TMGRESULT=$$GETDT(TIUDATE,+NUM,"Y") QUIT
  IF W1="AS",W2="PER" SET TMGRESULT=1 GOTO RSLDTDN
  SET IDX=$$WORDIDX(.WORDS,"PRN",1) IF IDX>0 SET TMGRESULT=1 GOTO RSLDTDN
  SET IDX=$$MONTHIDX(.WORDS) IF IDX>0 DO  GOTO:(TMGRESULT>0) RSLDTDN
  . NEW MONTH SET MONTH=$$MONTHNUM(WORDS(IDX))
  . NEW NEXT SET NEXT=$GET(WORDS(IDX+1))
  . NEW YR,DAY SET (YR,DAY)=0
  . IF $$INRANGE(NEXT,1,31) SET DAY=NEXT,NEXT=+$GET(WORDS(IDX+2))
  . IF $$INRANGE(NEXT,2000,2100) SET YR=NEXT
  . IF (MONTH>0)&(YR>0) SET TMGRESULT=$$ASMBLEDT(YR,MONTH,DAY) QUIT:(TMGRESULT>0)
  . SET TMGRESULT=$$GETMNDT(TIUDATE,IDX) 
  SET IDX=$$WORDIDX(.WORDS,"REGULAR",1) IF IDX>0 DO  GOTO:(TMGRESULT>0) RSLDTDN
  . NEW S SET S=$GET(WORDS(IDX+1))
  . IF S="APPT" SET TMGRESULT=1 QUIT
  IF $$POS^TMGSTUT3("AS SOON AS POSSIBLE",S)>0 SET TMGRESULT=$$GETDT(TIUDATE,3,"M") GOTO RSLDTDN
  NEW MONTHNUM SET MONTHNUM=$$MONTHNUM(W1)
  IF MONTHNUM>0 SET TMGRESULT=$$GETMNDT(TIUDATE,MONTHNUM) GOTO RSLDTDN  
  SET IDX=$$WORDIDX(.WORDS,"AS") 
  IF IDX=1 DO  GOTO:(RESTART=1) L1 GOTO:(TMGRESULT>0) RSLDTDN
  . NEW W2 SET W2=$GET(WORDS(IDX+1))
  . NEW W3 SET W3=$GET(WORDS(IDX+2))
  . NEW DELIDX1,DELIDX2 SET DELIDX1=IDX,DELIDX2=IDX
  . IF (W2["ALREADY")!(W2["REGULAR")!(W2["PREVIOUS") DO
  . . SET W2=W3,W3="",DELIDX2=IDX+1
  . IF W2["SCHEDULE" DO  QUIT 
  . . SET DELIDX2=DELIDX2+1
  . . SET PRNFOUND=1,RESTART=1 DO DELIDX(.WORDS,DELIDX1,DELIDX2) QUIT
  . IF W2["NEEDED" SET TMGRESULT=1 QUIT
  ;"IF IDX>0 DO  GOTO:(RESTART=1) L1 GOTO:(TMGRESULT>0) RSLDTDN
  ;". NEW W2 SET W2=$GET(WORDS(IDX+1))
  ;". NEW W3 SET W3=$GET(WORDS(IDX+2))
  ;". IF W2["PREVIOUS",W3["SCHEDULE" SET TMGRESULT=1 QUIT
  ;". IF (W2["ALREADY")!(W2["REGULAR"),W3["SCHEDULE" SET TMGRESULT=1 QUIT
  ;". IF W2["SCHEDULE" SET TMGRESULT=1 QUIT
  ;". IF W2["NEEDED" SET TMGRESULT=1 QUIT    
  ;"....
RSLDTDN ;  
  IF TMGRESULT=-1,PRNFOUND=1 SET TMGRESULT=1
  QUIT TMGRESULT
  ;
DELIDX(WORDARR,IDX,IDX2)  ;"Delete Index, or index range from WORDARR, and renumber entries
  SET IDX=+$GET(IDX)
  SET IDX2=$GET(IDX2,IDX)
  NEW TEMPARR,CT SET CT=0
  NEW J SET J=0
  FOR  SET J=$ORDER(WORDARR(J)) QUIT:+J'>0  DO
  . IF (J'<IDX)&(J'>IDX2) QUIT
  . SET CT=CT+1,TEMPARR(CT)=$GET(WORDARR(J))
  KILL WORDARR MERGE WORDARR=TEMPARR
  QUIT
  ;
DATEIDX(WORDARR)  ;"Return index in WORDARR of entry with ##/##/##(##) format, or ##/##(##) format
  NEW TMGRESULT SET TMGRESULT=-1
  NEW IDX SET IDX="" FOR  SET IDX=$ORDER(WORDARR(IDX)) QUIT:(IDX="")!(TMGRESULT>-1)  DO
  . NEW S SET S=$GET(WORDARR(IDX))
  . NEW L SET L=$LENGTH(S,"/") QUIT:L<2
  . NEW ABORT SET ABORT=0
  . NEW I2 FOR I2=1:1:L QUIT:ABORT=1  DO
  . . NEW PART SET PART=$PIECE(S,"/",I2)
  . . SET ABORT=(+PART'=PART)
  . IF ABORT=0 SET TMGRESULT=IDX
  QUIT TMGRESULT
  ;
MONTHIDX(WORDARR)  ;"Return index in WORDARR of any month
  NEW TMGRESULT SET TMGRESULT=-1
  NEW IDX SET IDX="" FOR  SET IDX=$ORDER(WORDARR(IDX)) QUIT:(IDX="")!(TMGRESULT>-1)  DO
  . NEW S SET S=$GET(WORDARR(IDX))
  . IF $$MONTHNUM(S)>0 SET TMGRESULT=IDX
  QUIT TMGRESULT
  ;
WORDIDX(WORDARR,AWORD,LOOSE) ;"Return index in WORDARR of AWORD, or -1 if not found
  NEW TMGRESULT SET TMGRESULT=-1
  SET LOOSE=+$GET(LOOSE)
  IF $GET(AWORD)="" GOTO WIDN
  NEW IDX SET IDX="" FOR  SET IDX=$ORDER(WORDARR(IDX)) QUIT:(IDX="")!(TMGRESULT>-1)  DO
  . IF LOOSE,$GET(WORDARR(IDX))[AWORD SET TMGRESULT=IDX QUIT
  . IF $GET(WORDARR(IDX))=AWORD SET TMGRESULT=IDX QUIT
WIDN ;  
  QUIT TMGRESULT
  ;
INRANGE(NUM,LO,HI)  ;"Check if Num is in between LO and HI (inclusive)
  QUIT (NUM'<LO)&(NUM'>HI)
  ;
ISPREV(S) ;"Check for 'previously' and all it's misspellings
  NEW TMGRESULT
  SET TMGRESULT=((S["PREV")!(S["PRESIOUSLY")!(S["PRESIOUS")!(S["PRIVIO"))
  QUIT TMGRESULT
  ;
ISSCHED(S)  ;"Check for 'scheduled' and all it's misspellings
  NEW TMGRESULT
  SET TMGRESULT=((S["SCHEDUL")!(S["SCHEDUL")!(S["SCEDU")!(S["SCHEU")!(S["SHCED")!(S["SCHEDL")!(S["SCEHD"))  
  QUIT TMGRESULT
  ;
ISWKDAY(S) ; "Is string a week day name?  Assumes S is upper case
  NEW TMGRESULT SET TMGRESULT=0
  NEW NAME FOR NAME="MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY","SATURDAY" DO  QUIT:(TMGRESULT=1)
  . IF (NAME[S)&(S'="DAY")&($LENGTH(S)'<3) SET TMGRESULT=1 
  QUIT TMGRESULT
  ;
MONTHNUM(S) ; "Is string a month name?  Assumes S is upper case
  ;"Result is month number (e.g. 5 for MAY, or 0 if not found)
  NEW NAME,MONTH,IDX SET IDX=1
  FOR NAME="JANUARY","FEBRUARY","MARCH","APRIL","MAY","JUNE" SET MONTH(IDX)=NAME,IDX=IDX+1 
  FOR NAME="JULY","AUGUST","SEPTEMBER","OCTOBER","NOVEMBER","DECEMBER" SET MONTH(IDX)=NAME,IDX=IDX+1 
  NEW TMGRESULT SET TMGRESULT=0
  FOR IDX=1:1:12 IF ($LENGTH(S)>2)&(MONTH(IDX)[S) SET TMGRESULT=IDX QUIT 
  QUIT TMGRESULT
  ;
GETMNDT(BASEDATE,MONTHNUM) ;"Return date for month number after basedate
  NEW TMGRESULT SET TMGRESULT=0
  NEW BASEY SET BASEY=$EXTRACT(BASEDATE,1,3)
  NEW BASEM SET BASEM=$EXTRACT(BASEDATE,4,5)
  ;"NEW BASE2 SET BASE2=$EXTRACT(BASEDATE,6,999)
  NEW BASE2 SET BASE2="28"  ;"Non-specific month date will be set to 28th day of month (greatest day avail for all months)
  IF +MONTHNUM>+BASEM DO
  . SET TMGRESULT=BASEY_$$RJ^XLFSTR(+MONTHNUM,2,"0")_BASE2
  ELSE  DO
  . SET TMGRESULT=(BASEY+1)_$$RJ^XLFSTR(+MONTHNUM,2,"0")_BASE2
  QUIT TMGRESULT
  ;
GETFMDT(S) ;TURN S INTO FILEMAN DATE IF POSSIBLE
  NEW TMGRESULT SET TMGRESULT=-1
  NEW %DT,X,Y SET %DT="F",X=S
  DO ^%DT SET TMGRESULT=Y
  QUIT TMGRESULT
  ;
ASMBLEDT(YR,MONTH,DAY) ;"ASSEMBLE DATE.  Input YR must be 4 digits.
  NEW DTYR SET DTYR=YR-1700 IF DTYR<0 QUIT -1
  SET MONTH=$$RJ^XLFSTR($GET(MONTH),2,"0") IF $LENGTH(MONTH)>2 QUIT -1
  SET DAY=$$RJ^XLFSTR($GET(DAY),2,"0") IF $LENGTH(DAY)>2 QUIT -1
  QUIT DTYR_MONTH_DAY
  ;
GETDT(BASEDT,NUM,TYPE) ;
  ;"Input: BASEDT -- FM base date
  ;"       Num -- a number
  ;"       TYPE -- "M" - month; "W" - week; "Y" - year; "D" - day
  NEW DY SET DY=$SELECT(TYPE="Y":(NUM*365),TYPE="M":(NUM*30),TYPE="W":(NUM*7),TYPE="D":NUM,1:0)
  QUIT $$FMADD^XLFDT(BASEDT,DY,0,0,0)
  ;
SCANPT(DFN,REFOUT,SDT,EDT,SCREEN,TITLEARR) ;
  ;"Purpose: Scan one patient during specified date range, and compile followup info
  ;"Input: DFN -- IEN of the patient
  ;"       REFOUT -- PASS BY NAME.  An OUT PARAMETER -- Format:
  ;"         @REFOUT@("INACTIVE",DFN)=<PATIENT NAME> <-- if inactive patient
  ;"         @REFOUT@(DFN,TIUIEN,F/U_TEXT)=""
  ;"         @REFOUT@(DFN,TIUIEN,F/U_FMDATE)=""  <-- e.g. if 3 month followup on 7/4/14, will return 10/4/14 in FM format
  ;"         old --> @REFOUT@("A",DFN,NOTE_TITLE_IEN,MOST_RECENT_REQUESTED_FOLLOWUP_FM_DATE)=""
  ;"         @REFOUT@("B",DFN,GREATEST_FOLLOWUP_DATE)=NOTE_DATE
  ;"         @REFOUT@("C",DFN,NOTE_DATE)=FOLLOWUP_DATE
  ;"         @REFOUT@("D",DFN)=GREATEST_FOLLOWUP_DATE
  ;"         @REFOUT@("E",DFN,NOTE_FM_DATE,FU_DATE)=F/U_TEXT
  ;"         @REFOUT@("OK",DFN)=NAME^Upcoming FMDate^NumMonthsTillAppt      
  ;"         @REFOUT@("DUE",DFN)=NAME^FOLLOW_UP_DATE^NumMonthsOverdue
  ;"         @REFOUT@("GDT",GREATEST_FOLLOWUP_DATE,DFN)=""
  ;"         @REFOUT@("NAME",DFN")=PatientName
  ;"       SDT -- START DATE (FM FORMAT).  OPTIONAL.  If not provided, then earliest date is default
  ;"       EDT -- END DATE (FM FORMAT).  OPTIONAL.  If not provided, then latest possible date is default
  ;"       SCREEN -- MUMPS CODE.  See description in SCANALL()
  ;"       TITLEARR -- Optional.  If provided, then only titles with matching IEN's
  ;"              will be considered.  Format:
  ;"              TITLEARR(TIUDOCIEN)=""
  ;"Result: 1^OK, or -1^Message
  NEW TMGRESULT SET TMGRESULT="1^OK"
  NEW TIUIEN,TIUDATE,TIUDOCIEN,ZN,SKIP
  NEW NAME SET NAME=$$LJ^XLFSTR($PIECE($GET(^DPT(DFN,0)),"^",1),20," ")
  SET @REFOUT@("NAME",DFN)=NAME
  SET SDT=+$GET(SDT),EDT=+$GET(EDT)
  IF EDT=0 SET EDT=9999999
  SET SCREEN=$GET(SCREEN)
  IF SCREEN="" SET SCREEN="IF $$ACTIVEPT^TMGPXR03(DFN,3)<1 SET Y=-1"
  NEW Y SET Y=1
  IF SCREEN'="" XECUTE SCREEN
  IF Y=-1 DO  GOTO SCPTDN
  . SET @REFOUT@("INACTIVE",DFN)=NAME
  ;"NEW COMPIEN SET COMPIEN=+$ORDER(^TIU(8925.6,"B","COMPLETED",0))
  ;"IF COMPIEN'>0 DO  GOTO SCPTDN
  ;". SET TMGRESULT="-1^Unable to find IEN for 'COMPLETED' in file 8925.6"
  SET TIUIEN=0
  FOR  SET TIUIEN=$ORDER(^TMG(22731,DFN,"DOC",TIUIEN)) QUIT:(TIUIEN'>0)!(+TMGRESULT'>0)  DO
  . SET ZN=$GET(^TMG(22731,DFN,"DOC",TIUIEN,0))
  . SET TIUDATE=$PIECE(ZN,"^",4)
  . SET SKIP=0
  . IF (TIUDATE<SDT)!(TIUDATE>EDT) QUIT
  . IF $DATA(TITLEARR) DO
  . . IF $DATA(TITLEARR(TIUDOCIEN)) SET SKIP=0
  . . ELSE  SET SKIP=1
  . IF SKIP=1 QUIT  
  . SET TMGRESULT=$$SCANNOTE(DFN,TIUIEN,REFOUT)
  . IF +TMGRESULT=0 SET TMGRESULT="1^OK"  ;"0 means nothing found.  That is not an error
  ;"SET TIUIEN=0
  ;"FOR  SET TIUIEN=$ORDER(^TIU(8925,"C",DFN,TIUIEN)) QUIT:(TIUIEN'>0)!(+TMGRESULT'>0)  DO
  ;". SET ZN=$GET(^TIU(8925,TIUIEN,0))
  ;". SET TIUDATE=$PIECE(ZN,"^",7),TIUDOCIEN=$PIECE(ZN,"^",1)
  ;". SET SKIP=0
  ;". IF (TIUDATE<SDT)!(TIUDATE>EDT) QUIT
  ;". IF $PIECE(ZN,"^",5)'=COMPIEN QUIT  ;"Skip any note without 'COMPLETED' status
  ;". IF $DATA(TITLEARR) DO
  ;". . IF $DATA(TITLEARR(TIUDOCIEN)) SET SKIP=0
  ;". . ELSE  SET SKIP=1
  ;". IF SKIP=1 QUIT
  ;". SET TMGRESULT=$$SCANNOTE(TIUIEN,REFOUT)
  ;". IF +TMGRESULT=0 SET TMGRESULT="1^OK"  ;"0 means nothing found.  That is not an error
  IF +TMGRESULT'>0 GOTO SCPTDN
  NEW NOW SET NOW=$$NOW^XLFDT
  NEW FUDATE SET FUDATE=+$GET(@REFOUT@("D",DFN))
  IF FUDATE=0 GOTO SCPTDN
  IF FUDATE>NOW DO  
  . NEW DIFF SET DIFF=$J($$FMDIFF^XLFDT(FUDATE,NOW)/30,0,1) ;"round to 1 digit
  . SET @REFOUT@("OK",DFN)=NAME_"^"_FUDATE_"^"_DIFF      
  ELSE  DO
  . NEW DIFF SET DIFF=$J($$FMDIFF^XLFDT(NOW,FUDATE)/30,0,1) ;"round to 1 digit
  . SET @REFOUT@("DUE",DFN)=NAME_"^"_FUDATE_"^"_DIFF
  SET @REFOUT@("GDT",FUDATE,DFN)=""  
SCPTDN ;  
  QUIT TMGRESULT
  ;"
SCANTIU  ;"SCAN ALL TIU DOCUMENTS
  ;"Purpose: to scan all TIU documents, to pre-parse them for faster access later
  ;"Output: none.  Just progress on the screen. 
  NEW STARTT SET STARTT=$H
  NEW SHOWPROG SET SHOWPROG=1
  NEW TIUIEN,COUNTER,NAME 
  SET TIUIEN=0,COUNTER=-1
  NEW COMPIEN SET COMPIEN=+$ORDER(^TIU(8925.6,"B","COMPLETED",0))
  IF COMPIEN'>0 DO  GOTO SCTDN
  . WRITE "Unable to find IEN for 'COMPLETED' in file 8925.6"
  NEW OUT
  NEW MAXDFN SET MAXDFN=$ORDER(^TIU(8925,"A"),-1)
  FOR  SET TIUIEN=$ORDER(^TIU(8925,TIUIEN)) QUIT:(TIUIEN'>0)  DO   
  . SET COUNTER=COUNTER+1
  . NEW TMGDFN SET TMGDFN=+$PIECE($GET(^TIU(8925,TIUIEN,0)),"^",2)
  . IF (SHOWPROG=1),COUNTER#1000=0 DO
  . . SET NAME=$$LJ^XLFSTR($PIECE($GET(^DPT(TMGDFN,0)),"^",1),20," ")
  . . DO PROGBAR^TMGUSRI2(TIUIEN,NAME,1,MAXDFN,60,STARTT)
  . NEW ZN SET ZN=$GET(^TIU(8925,TIUIEN,0))  
  . ;"NEW TIUDOCIEN SET TIUDOCIEN=$PIECE(ZN,"^",1)  ;"could screen by doc type  
  . IF $PIECE(ZN,"^",5)'=COMPIEN QUIT  ;"Skip any note without 'COMPLETED' status
  . KILL OUT 
  . NEW TEMP SET TEMP=$$SCANNOTE(TMGDFN,TIUIEN,"OUT",1) 
  . IF +TEMP=-1 WRITE !,$PIECE(TEMP,"^",2),!
SCTDN ;  
  QUIT
  ;  
SCANALL(REFOUT,SDT,EDT,SCREEN,TITLEARR) ;
  ;"Purpose: Scan all patients during specified date range, and compile followup info
  ;"       REFOUT -- PASS BY NAME.  An OUT PARAMETER -- Format: 
  ;"         @REFOUT@("INACTIVE",DFN)=<PATIENT NAME> <-- if inactive patient
  ;"         @REFOUT@(DFN,TIUIEN,F/U_TEXT)=""
  ;"         @REFOUT@(DFN,TIUIEN,F/U_FMDATE)=""  <-- e.g. if 3 month followup on 7/4/14, will return 10/4/14 in FM format
  ;"     old-->   @REFOUT@("A",DFN,NOTE_TITLE_IEN,MOST_RECENT_REQUESTED_FOLLOWUP_FM_DATE)=""
  ;"         @REFOUT@("B",DFN,GREATEST_FOLLOWUP_DATE)=NOTE_DATE
  ;"         @REFOUT@("C",DFN,NOTE_DATE)=FOLLOWUP_DATE
  ;"         @REFOUT@("D",DFN)=GREATEST_FOLLOWUP_DATE
  ;"         @REFOUT@("E",DFN,NOTE_FM_DATE,FU_DATE)=F/U_TEXT
  ;"         @REFOUT@("OK",DFN)=NAME^Upcoming FMDate^NumMonthsTillAppt      
  ;"         @REFOUT@("DUE",DFN)=NAME^FOLLOW_UP_DATE^NumMonthsOverdue
  ;"         @REFOUT@("GDT",GREATEST_FOLLOWUP_DATE,DFN)=""
  ;"         @REFOUT@("NAME",DFN")=PatientName
  ;"       SDT -- START DATE (FM FORMAT).  OPTIONAL.  If not provided, then earliest date is default
  ;"       EDT -- END DATE (FM FORMAT).  OPTIONAL.  If not provided, then latest possible date is default
  ;"       SCREEN -- OPTIONAL.  Mumps code that can be used to screen each patient. Default is screen for active patients
  ;"          Screen code will be able to depend on the following variables:
  ;"             TMGDFN -- the current patient being considered
  ;"             SDT, EDT --  The start and end dates (FM format) being scanned. 
  ;"             Code should set the variable Y as follows: 1 = OK, -1 = skip patient
  ;"       TITLEARR -- Optional.  If provided, then only titles with matching IEN's
  ;"              will be considered.  Format:
  ;"              TITLEARR(TIUDOCIEN)=""
  ;"Result: 1^OK, or -1^Message
  KILL @REFOUT
  NEW TMGRESULT SET TMGRESULT="1^OK" 
  NEW STARTT SET STARTT=$H
  NEW SHOWPROG SET SHOWPROG=1
  NEW TMGDFN,COUNTER,NAME 
  SET TMGDFN=0,COUNTER=-1
  NEW MAXDFN SET MAXDFN=$ORDER(^DPT("A"),-1)
  ;"NOTE: will abort scan with any error
  FOR  SET TMGDFN=$ORDER(^DPT(TMGDFN)) QUIT:(TMGDFN'>0)!(+TMGRESULT'>0)  DO   
  . SET COUNTER=COUNTER+1
  . IF (SHOWPROG=1),COUNTER#10=0 DO
  . . SET NAME=$$LJ^XLFSTR($PIECE($GET(^DPT(TMGDFN,0)),"^",1),20," ")
  . . D PROGBAR^TMGUSRI2(TMGDFN,NAME,1,MAXDFN,60,STARTT)
  . IF (SHOWPROG=0) WRITE !,"TMGDFN= ",TMGDFN," " 
  . SET TMGRESULT=$$SCANPT(TMGDFN,REFOUT,.SDT,.EDT,.SCREEN,.TITLEARR)
  QUIT TMGRESULT
  ;"
DISPINFO(DFN,INFO) ;
  NEW NOTEDT,FUDT
  WRITE $$LJ^XLFSTR($PIECE($GET(^DPT(DFN,0)),"^",1),20," ")," (",DFN,")",!
  SET NOTEDT=0 FOR  SET NOTEDT=$ORDER(INFO("E",DFN,NOTEDT)) QUIT:+NOTEDT'>0  DO
  . NEW FUDATE SET FUDATE=$ORDER(INFO("E",DFN,NOTEDT,"")) QUIT:FUDATE'>0
  . NEW LINETEXT SET LINETEXT=$GET(INFO("E",DFN,NOTEDT,FUDATE))
  . IF $LENGTH(LINETEXT)>60 SET LINETEXT=$EXTRACT(LINETEXT,1,60)_"..."
  . WRITE " Note on date: ",$$FMTE^XLFDT(NOTEDT,"1D")
  . WRITE " --> f/u due: ",$$FMTE^XLFDT(FUDATE,"1D"),!
  . WRITE "   '",LINETEXT,"'",!
  WRITE "--------------------",!
  QUIT
  ;  
SELSHOW ;
  ;"Purpose: to scan all patients, and then allow inspection of details.
  NEW ARR,TMGDFN,%
  NEW OUTREF SET OUTREF=$NAME(^TMP($J,"TMGTIU10"))
  NEW TMGRESULT SET TMGRESULT=$$SCANALL(OUTREF)
  IF +TMGRESULT'>0 DO  GOTO SSDN
  . WRITE "ERROR: ",$PIECE(TMGRESULT,"^",2),!
  NEW TMGDFN SET TMGDFN="" FOR  SET TMGDFN=$ORDER(@OUTREF@("DUE",TMGDFN)) QUIT:(TMGDFN="")  DO
  . NEW TEMP SET TEMP=$GET(@OUTREF@("DUE",TMGDFN))
  . NEW NAME SET NAME=$PIECE(TEMP,"^",1)
  . NEW DUE SET DUE=$PIECE(TEMP,"^",2)
  . SET DUE="DUE: "_$$FMTE^XLFDT(DUE,"1D")
  . SET ARR(NAME_" "_DUE,TMGDFN)=""
SS1 ;
  KILL @OUTREF
  DO SELECTR2^TMGUSRI3("ARR",OUTREF,"Select patients to inspect.  Press <ESC><ESC> when done.")
  SET NAME="" FOR  SET NAME=$ORDER(@OUTREF@(NAME)) QUIT:NAME=""  DO
  . SET TMGDFN=+$ORDER(@OUTREF@(NAME,"")) QUIT:TMGDFN'>0
  . NEW PTINFO
  . SET TMGRESULT=$$SCANPT(TMGDFN,"PTINFO")
  . IF +TMGRESULT>0 DO
  . . DO DISPINFO(TMGDFN,.PTINFO) ;
  . ELSE  DO
  . . WRITE "ERROR: ",$PIECE(TMGRESULT,"^",2),!
  SET %=1 
  WRITE "View details for more" DO YN^DICN WRITE !
  IF %=1 GOTO SS1
SSDN ;  
  KILL @OUTREF
  QUIT
  ;
LISTDUE ; ;"Purpose: to scan all patients, and then list due status
  NEW ARR,TMGDFN,CT SET CT=0
  NEW OUTREF SET OUTREF=$NAME(^TMP($J,"TMGTIU10"))
  IF $$SCANALL(OUTREF,,,"Q")
  NEW NOW SET NOW=$$NOW^XLFDT
  NEW FUDT SET FUDT=0 
  FOR  SET FUDT=$ORDER(@OUTREF@("GDT",FUDT)) QUIT:(+FUDT'>0)!(FUDT>NOW)  DO
  . NEW TMGDFN SET TMGDFN="" FOR  SET TMGDFN=$ORDER(@OUTREF@("GDT",FUDT,TMGDFN)) QUIT:(TMGDFN="")  DO
  . . NEW NAME SET NAME=$GET(@OUTREF@("NAME",TMGDFN))
  . . NEW DTSTR
  . . IF FUDT=1 SET DTSTR="'PRN'"
  . . ELSE  SET DTSTR=$$FMTE^XLFDT(FUDT,"1D")
  . . SET CT=CT+1,ARR(CT)="DUE: "_DTSTR_" -- "_NAME
  ;
  NEW %ZIS,POP
  SET %ZIS("A")="Enter Output Device: "
  SET %ZIS("B")="HOME"
  DO ^%ZIS  ;"standard device call
  IF POP DO  GOTO LDDN
  . DO SHOWERR^TMGDEBU2(,"Error opening output.  Aborting.")
  USE IO
  ;"Do the output
  SET CT=0
  FOR  SET CT=$ORDER(ARR(CT)) QUIT:CT'>0  DO
  . WRITE $GET(ARR(CT)),!
  ;" Close the output device
  DO ^%ZISC
LDDN ;  
  KILL @OUTREF
  QUIT
  ;
RPCCKDUE(TMGRESULT,TMGDFN,MODE) ;"RPC CHECK DUE
  ;"Purpose: RPC Entry point to check if patient is overdue for appt
  ;"         Also used for a TIU TEXT OBJECT
  ;"Input: TMGRESULT -- PASS BY REFERENCE, an OUT PARAMETER.  Format as below. 
  ;"       TMGDFN -- the IEN of the patient to check
  ;"       MODE -- OPTIONAL.  If null or 0, then ALL data returned
  ;"                          If 1, then only recent data returned.  I.e. only
  ;"                      entries related-to, or after lastest follow up date
  ;"NOTE: This check depends on the exact way that FAMILY PHYSICIANS OF GREENEVILLE
  ;"      conduct business.  It will not be generally applicable to other sites,
  ;"      but others could implement their own business logic here...
  ;"Result: none                     
  ;"Output: TMGRESULT(0)="0^<num_months>^months util appt.", 
  ;"                     "0^-1^Inactive" 
  ;"                     "1^<num_months>^months overdue", or 
  ;"                     "-1^Message"
  ;"        TMGRESULT(1)=red^green^blue <-- patient color code. 0-255 each   
  ;"        TMGRESULT(#)=FMDATE-VISIT^FMDATE-F/U-DUE^Supporting narrative 
  ;"        NOTE: if follow-up date was "PRN" or "as previously schedule" etc, 
  ;"              then it's value will be "1"
  NEW PTINFO,TEMP SET TEMP=$$SCANPT(TMGDFN,"PTINFO")  
  SET MODE=+$GET(MODE)  
  IF +TEMP'>0 SET TMGRESULT(0)=TEMP GOTO RPDN
  IF $DATA(PTINFO("INACTIVE",TMGDFN))>0 DO  GOTO RPDN
  . SET TMGRESULT(0)="0^-1^Inactive"
  . SET TMGRESULT(1)=$$PTCOLOR("INACTIVE",0)
  NEW NODE,DESCR,VAL
  IF $DATA(PTINFO("OK",TMGDFN))>0 SET VAL=0,NODE="OK",DESCR="months until appt. due"
  ELSE  IF $DATA(PTINFO("DUE",TMGDFN))>0 SET VAL=1,NODE="DUE",DESCR="months overdue"
  ELSE  SET TMGRESULT(0)="-1^Problem with checking patient followup",TMGRESULT(1)="949495^Problem checking patient" QUIT
  NEW MAXFUDATE SET MAXFUDATE=+$ORDER(PTINFO("B",TMGDFN,""))
  NEW TIUDATEOFMAX SET TIUDATEOFMAX=$GET(PTINFO("B",TMGDFN,MAXFUDATE))
  NEW TEMP SET TEMP=$GET(PTINFO(NODE,TMGDFN))
  NEW MONTHS SET MONTHS=$PIECE(TEMP,"^",3)
  SET TMGRESULT(0)=VAL_"^"_MONTHS_"^"_DESCR
  SET TMGRESULT(1)=$$PTCOLOR(NODE,MONTHS)
  NEW IDX SET IDX=1
  NEW NOTEDT SET NOTEDT=0
  FOR  SET NOTEDT=$ORDER(PTINFO("E",TMGDFN,NOTEDT)) QUIT:NOTEDT=""  DO
  . NEW FUDT SET FUDT=$ORDER(PTINFO("E",TMGDFN,NOTEDT,""))
  . NEW TEXT SET TEXT=$GET(PTINFO("E",TMGDFN,NOTEDT,FUDT))
  . IF FUDT=-1 QUIT
  . IF MODE=1,NOTEDT<TIUDATEOFMAX QUIT
  . SET IDX=IDX+1,TMGRESULT(IDX)=NOTEDT_"^"_FUDT_"^"_TEXT
RPDN ;  
  QUIT
  ;
PTCOLOR(STATUS,MONTHS) ;"Get color for patient status
  ;"Input: STATUS -- "OK" -- patient not overdue.  Has upcoming appt
  ;"                 "DUE" -- patient overdue for appt
  ;"                 "INACTIVE" -- patient is inactive
  ;"       MONTHS -- number of months until appt, or overdue.
  ;"Result: RRGGBB, with each R,G,B being 2 digit hex number for color component
  ;  
  ;"NOTE: the following Delphi function can convert hexstring to TColor
  ;"   function HexToTColor(sColor : string) : TColor;
  ;"   begin
  ;"      Result := RGB( StrToInt('$'+Copy(sColor, 1, 2)),
  ;"                     StrToInt('$'+Copy(sColor, 3, 2)),
  ;"                     StrToInt('$'+Copy(sColor, 5, 2))  ) ;
  ;"   end;  
    
  NEW TMGRESULT SET TMGRESULT="000000"
  SET STATUS=$GET(STATUS)
  SET MONTHS=+MONTHS
  IF STATUS="OK" DO
  . IF MONTHS<4 SET TMGRESULT="FFFFCC^Appointment Due In Next 3 Months"  ;"light yellow
  . ELSE  SET TMGRESULT="9DFF9D^Appointment Due > 3 Months" ;"light green
  ELSE  IF STATUS="INACTIVE" DO
  . SET TMGRESULT="C9C9CB^Inactive Patient"  ;"light gray
  ELSE  DO  ;"due"
  . IF MONTHS>12 SET TMGRESULT="FF0000^1+ year overdue"
  . ELSE  IF MONTHS>6 SET TMGRESULT="FF8080^6-11 months overdue"  ;"light red
  . ELSE  IF MONTHS>1 SET TMGRESULT="FFB2B2^1-5 months overdue"  ;"lighter red
  . ELSE  SET TMGRESULT="FFEBEB^1-4 weeks overdue"  ;"Minimal red    
  QUIT TMGRESULT
  ;  
