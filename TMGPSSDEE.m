TMGPSSDEE  ;BIR/WRT-MASTER DRUG ENTER/EDIT ROUTINE ;01/21/00
        ;;1.0;PHARMACY DATA MANAGEMENT;**3,5,15,16,20,22,28,32,34,33,38,57,47,68,61**;9/30/97
        ;
        ;Reference to REACT1^PSNOUT supported by DBIA #2080
        ;Reference to $$UP^XLFSTR(X) supported by DBIA #10104
        ;Reference to $$PSJDF^PSNAPIS(P1,P3) supported by DBIA #2531
        ;
        ;"Custom version -- formatted for easier reading...  2/2/14
 ;
 ;"~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--
 ;"Copyright (c) 6/23/2015  Kevin S. Toppenberg MD
 ;"
 ;"This file is part of the TMG LIBRARY, and may only be used in accordence
 ;" to license terms outlined in separate file TMGLICNS.m, which should 
 ;" always be distributed with this file.
 ;"~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--
 ;
BEGIN   S PSSFLAG=0
        D ^PSSDEE2
        S PSSZ=1
        F PSSXX=1:1 DO  Q:PSSFLAG
        . K DA
        . D ASK
DONE    D ^PSSDEE2
        K PSSFLAG
        Q

ASK ;
        W !
        S DIC="^PSDRUG(",DIC(0)="QEALMNTV",DLAYGO=50,DIC("T")=""
        D ^DIC
        K DIC
        I Y<0 S PSSFLAG=1 Q
        S (FLG1,FLG2,FLG3,FLG4,FLG5,FLG6,FLG7,FLAG,FLGKY,FLGOI)=0
        K ^TMP($J,"ADD"),^TMP($J,"SOL")
        S DA=+Y
        S DISPDRG=DA
        L +^PSDRUG(DISPDRG):0
        I '$T W !,$C(7),"Another person is editing this one." Q
        S PSSHUIDG=1
        S PSSNEW=$P(Y,"^",3)
        D USE
        D NOPE
        D COMMON
        D DEA
        D MF
        K PSSHUIDG
        D DRG^PSSHUIDG(DISPDRG,PSSNEW)
        L -^PSDRUG(DISPDRG)
        K FLG3,PSSNEW
        Q

COMMON
        S DIE="^PSDRUG(",DR="[PSSCOMMON]"
        D ^DIE
        Q:$D(Y)!($D(DTOUT))
        W:'$D(Y) !,"PRICE PER DISPENSE UNIT: "
        S:'$D(^PSDRUG(DA,660)) $P(^PSDRUG(DA,660),"^",6)=""
        W:'$D(Y) $P(^PSDRUG(DA,660),"^",6)
        D DEA
        D CK
        D ASKND
        D OIKILL^PSSDEE1
        D COMMON1
        Q

COMMON1
        W !,"Just a reminder...you are editing ",$P(^PSDRUG(DISPDRG,0),"^"),"."
        S (PSSVVDA,DA)=DISPDRG
        D DOSN^PSSDOS
        S DA=PSSVVDA
        K PSSVVDA
        D USE
        D APP
        D ORDITM^PSSDEE1
        Q

CK
        D DSPY^PSSDEE1
        S FLGNDF=0
        Q

ASKND
        ;"Purpose: allow user to match to National Drug File
        S %=-1
        I $D(^XUSEC("PSNMGR",DUZ)) do
        . D MESSAGE^PSSDEE1
        . W !!,"Do you wish to match/rematch to NATIONAL DRUG file"
        . S %=1
        . S:FLGMTH=1 %=2
        . D YN^DICN
        I %=0 W !,"If you answer ""yes"", you will attempt to match to NDF." G ASKND
        I %=2 K X,Y Q
        I %<0 K X,Y Q
        I %=1 do
        . D EN1^PSSUTIL(DISPDRG,1)
        . D RSET^PSSDEE1
        . S X="PSNOUT"
        . X ^%ZOSF("TEST") I  D REACT1^PSNOUT
        . S DA=DISPDRG
        . I $D(^PSDRUG(DA,"ND")),$P(^PSDRUG(DA,"ND"),"^",2)]"" D ONE
        Q


ONE
        S PSNP=$G(^PSDRUG(DA,"I"))
        I PSNP,PSNP<DT Q
        W !,"You have just VERIFIED this match and MERGED the entry."
        D CKDF
        D EN2^PSSUTIL(DISPDRG,1)
        S:'$D(OLDDF) OLDDF=""
        I OLDDF'=NEWDF S FLGNDF=1 D WR
        Q

CKDF
        S NWND=^PSDRUG(DA,"ND")
        S NWPC1=$P(NWND,"^",1)
        S NWPC3=$P(NWND,"^",3)
        S DA=NWPC1
        S K=NWPC3
        S X=$$PSJDF^PSNAPIS(DA,K)
        S NEWDF=$P(X,"^",2)
        S DA=DISPDRG
        N PSSK
        D PKIND^PSSDDUT2
        Q

NOPE
        S ZAPFLG=0
        I '$D(^PSDRUG(DA,"ND")),$D(^PSDRUG(DA,2)),$P(^PSDRUG(DA,2),"^",1)']"" D DFNULL
        I '$D(^PSDRUG(DA,"ND")),'$D(^PSDRUG(DA,2)) D DFNULL
        I $D(^PSDRUG(DA,"ND")),$P(^PSDRUG(DA,"ND"),"^",2)']"",$D(^PSDRUG(DA,2)),$P(^PSDRUG(DA,2),"^",1)']"" D DFNULL
        Q

DFNULL
        S OLDDF=""
        S ZAPFLG=1
        Q

ZAPIT
        I $D(ZAPFLG),ZAPFLG=1,FLGNDF=1,OLDDF'=NEWDF D CKIV^PSSDEE1
        Q

APP
        W !!,"MARK THIS DRUG AND EDIT IT FOR: "
        D CHOOSE
        Q

CHOOSE
        I $D(^XUSEC("PSORPH",DUZ))!($D(^XUSEC("PSXCMOPMGR",DUZ))) W !,"O  - Outpatient" S FLG1=1
        I $D(^XUSEC("PSJU MGR",DUZ)) W !,"U  - Unit Dose" S FLG2=1
        I $D(^XUSEC("PSJI MGR",DUZ)) W !,"I  - IV" S FLG3=1
        I $D(^XUSEC("PSGWMGR",DUZ)) W !,"W  - Ward Stock" S FLG4=1
        I $D(^XUSEC("PSAMGR",DUZ))!($D(^XUSEC("PSA ORDERS",DUZ))) W !,"D  - Drug Accountability" S FLG5=1
        I $D(^XUSEC("PSDMGR",DUZ)) W !,"C  - Controlled Substances" S FLG6=1
        I $D(^XUSEC("PSORPH",DUZ)) W !,"X  - Non-VA Med" S FLG7=1
        I FLG1,FLG2,FLG3,FLG4,FLG5,FLG6 S FLAG=1
        I FLAG W !,"A  - ALL"
        W !
        I 'FLG1,'FLG2,'FLG3,'FLG4,'FLG5,'FLG6,'FLG7 DO  Q
        . W !,"You DO not have the proper keys to continue. Sorry, this concludes your editing session.",!
        . S FLGKY=1
        . K DIRUT,X
        I FLGKY'=1 D
        . K DIR
        . S DIR(0)="FO^1:30"
        . S DIR("A")="Enter your choice(s) separated by commas "
        . F  D ^DIR Q:$$CHECK($$UP^XLFSTR(X))
        . S PSSANS=X
        . S PSSANS=$$UP^XLFSTR(PSSANS)
        . D BRANCH
        . D BRANCH1
        Q

CHECK(X)        ;" Validates Application Use response
        N CHECK,I,C
        S CHECK=1
        I X=""!(Y["^")!($D(DIRUT)) Q CHECK
        F I=1:1:$L(X,",") D
        . S C=$P(X,",",I)
        . W !?43,C," - "
        . I C="O",FLG1 W "Outpatient" Q
        . I C="U",FLG2 W "Unit Dose" Q
        . I C="I",FLG3 W "IV" Q
        . I C="W",FLG4 W "Ward Stock" Q
        . I C="D",FLG5 W "Drug Accountability" Q
        . I C="C",FLG6 W "Controlled Substances" Q
        . I C="X",FLG7 W "Non-VA Med" Q
        . W "Invalid Entry",$C(7)
        . S CHECK=0
        Q CHECK

BRANCH
        D:PSSANS["O" OP
        D:PSSANS["U" UD
        D:PSSANS["I" IV
        D:PSSANS["W" WS
        D:PSSANS["D" DACCT
        D:PSSANS["C" CS
        D:PSSANS["X" NVM
        Q

BRANCH1
        I FLAG,PSSANS["A" do
        . D OP
        . D UD
        . D IV
        . D WS
        . D DACCT
        . D CS
        . D NVM
        Q

OP      I FLG1 D
        . W !,"** You are NOW editing OUTPATIENT fields. **"
        . S PSIUDA=DA,PSIUX="O^Outpatient Pharmacy"
        . D ^PSSGIU
        . I %=1 D
        . . S DIE="^PSDRUG(",DR="[PSSOP]"
        . . D ^DIE K DIR
        . . D OPEI,ASKCMOP
        . . D OPEI
        . . D ASKCMOP
        . . S X="PSOCLO1"
        . . X ^%ZOSF("TEST") I  D ASKCLOZ S FLGOI=1
        I FLG1 D CKCMOP
        Q

CKCMOP
        I $P($G(^PSDRUG(DISPDRG,2)),"^",3)'["O" do
        . S:$D(^PSDRUG(DISPDRG,3)) $P(^PSDRUG(DISPDRG,3),"^",1)=0
        . K:$D(^PSDRUG("AQ",DISPDRG)) ^PSDRUG("AQ",DISPDRG)
        . S DA=DISPDRG
        . D ^PSSREF
        Q

UD
        I FLG2 do
        . W !,"** You are NOW editing UNIT DOSE fields. **"
        . S PSIUDA=DA,PSIUX="U^Unit Dose"
        . D ^PSSGIU
        . I %=1 do
        . . S DIE="^PSDRUG(",DR="62.05;212.2"
        . . D ^DIE
        . . S DIE="^PSDRUG(",DR="212",DR(2,50.0212)=".01;1"
        . . D ^DIE
        . . S FLGOI=1
        Q

IV
        I FLG3 do
        . W !,"** You are NOW editing IV fields. **"
        . S (PSIUDA,PSSDA)=DA,PSIUX="I^IV"
        . D ^PSSGIU
        . I %=1 do
        . . D IV1
        . . S FLGOI=1
        Q

IV1
        K PSSIVOUT ;"This variable controls the selection process loop.
        W !,"Edit Additives or Solutions: "
        K DIR
        S DIR(0)="SO^A:ADDITIVES;S:SOLUTIONS;"
        D ^DIR Q:$D(DIRUT)
        S PSSASK=Y(0)
        D:PSSASK="ADDITIVES" ENA^PSSVIDRG
        D:PSSASK="SOLUTIONS" ENS^PSSVIDRG
        I '$D(PSSIVOUT) G IV1
        K PSSIVOUT
        Q

WS
        I FLG4 do
        . W !,"** You are NOW editing WARD STOCK fields. **"
        . S DIE="^PSDRUG(",DR="300;301;302"
        . D ^DIE
        Q

DACCT
        I FLG5 do
        . W !,"** You are NOW editing DRUG ACCOUNTABILITY fields. **"
        . S DIE="^PSDRUG(",DR="441"
        . D ^DIE
        . S DIE="^PSDRUG(",DR="9",DR(2,50.1)="1;2;400;401;402;403;404;405"
        . D ^DIE
        Q

CS
        I FLG6 do
        . W !,"** You are NOW Marking/Unmarking for CONTROLLED SUBS. **"
        . S PSIUDA=DA,PSIUX="N^Controlled Substances"
        . D ^PSSGIU
        Q

NVM
        I FLG7 do
        . W !,"** You are NOW Marking/Unmarking for NON-VA MEDS. **"
        . S PSIUDA=DA,PSIUX="X^Non-VA Med"
        . D ^PSSGIU
        Q

ASKCMOP
        I $D(^XUSEC("PSXCMOPMGR",DUZ)) do
        . W !!,"Do you wish to mark to transmit to CMOP? "
        . K DIR
        . S DIR(0)="Y"
        . S DIR("?")="If you answer ""yes"", you will attempt to mark this drug to transmit to CMOP."
        D ^DIR
        I "Nn"[X K X,Y,DIRUT Q
        I "Yy"[X do
        . S PSXFL=0
        . D TEXT^PSSMARK
        . H 7
        . N PSXUDA
        . S (PSXUM,PSXUDA)=DA
        . S PSXLOC=$P(^PSDRUG(DA,0),"^")
        . S PSXGOOD=0,PSXF=0,PSXBT=0
        . D BLD^PSSMARK
        . D PICK2^PSSMARK
        . S DA=PSXUDA
        Q

ASKCLOZ
        W !!,"Do you wish to mark/unmark as a LAB MONITOR or CLOZAPINE DRUG? "
        K DIR
        S DIR(0)="Y"
        S DIR("?")="If you answer ""yes"", you will have the opportunity to edit LAB MONITOR or CLOZAPINE fields."
        D ^DIR
        I "Nn"[X K X,Y,DIRUT Q
        I "Yy"[X do
        . S NFLAG=0
        . D MONCLOZ
        Q

MONCLOZ
        K PSSAST
        D FLASH
        W !,"Mark/Unmark for Lab Monitor or Clozapine: "
        K DIR
        S DIR(0)="S^L:LAB MONITOR;C:CLOZAPINE;"
        D ^DIR
        Q:$D(DIRUT)
        S PSSAST=Y(0)
        D:PSSAST="LAB MONITOR" ^PSSLAB
        D:PSSAST="CLOZAPINE" CLOZ
        Q

FLASH   K LMFLAG,CLFALG,WHICH S WHICH=$P($G(^PSDRUG(DISPDRG,"CLOZ1")),"^"),LMFLAG=0,CLFLAG=0
        I WHICH="PSOCLO1" S CLFLAG=1
        I WHICH'="PSOCLO1" S:WHICH'="" LMFLAG=1
        Q

CLOZ
        Q:NFLAG
        Q:$D(DTOUT)
        Q:$D(DIRUT)
        Q:$D(DUOUT)
        W !,"** You are NOW editing CLOZAPINE fields. **"
        D ^PSSCLDRG
        Q

USE
        K PACK
        S PACK=""
        S:$P($G(^PSDRUG(DISPDRG,"PSG")),"^",2)]"" PACK="W"
        I $D(^PSDRUG(DISPDRG,2)) S PACK=PACK_$P(^PSDRUG(DISPDRG,2),"^",3)
        I PACK'="" D
        .W $C(7)
        .N XX
        .W !!
        .F XX=1:1:79 W "*"
        .W !,"This entry is marked for the following PHARMACY packages: "
        .D USE1
        Q

USE1
        W:PACK["O" !," Outpatient"
        W:PACK["U" !," Unit Dose"
        W:PACK["I" !," IV"
        W:PACK["W" !," Ward Stock"
        W:PACK["D" !," Drug Accountability"
        W:PACK["N" !," Controlled Substances"
        W:PACK["X" !," Non-VA Med"
        W:'$D(PACK) !," NONE"
        I PACK'["O",PACK'["U",PACK'["I",PACK'["W",PACK'["D",PACK'["N",PACK'["X" W !," NONE"
        Q

WR
        I ^XMB("NETNAME")'["CMOP-" do
        . IF OLDDF="" QUIT
        . W !,"The dosage form has changed from "_OLDDF_" to "_NEWDF_" due to",!
        . W "You will need to rematch to Orderable Item.",!
        Q

PRIMDRG
        I $D(^PS(59.7,1,20)),$P(^PS(59.7,1,20),"^",1)=4!($P(^PS(59.7,1,20),"^",1)=4.5) do
        . I $D(^PSDRUG(DISPDRG,2)) do
        . . S VAR=$P(^PSDRUG(DISPDRG,2),"^",3)
        . . I VAR["U"!(VAR["I") D PRIM1
        Q

PRIM1
        W !!,"You need to match this drug to ""PRIMARY DRUG"" file as well.",!
        S DIE="^PSDRUG(",DR="64",DA=DISPDRG
        D ^DIE
        K VAR
        Q

MF
        I $P($G(^PS(59.7,1,80)),"^",2)>1 do
        . I $D(^PSDRUG(DISPDRG,2)) do
        . . S PSSOR=$P(^PSDRUG(DISPDRG,2),"^",1)
        . . I PSSOR]"" DO
        . . . DO EN^PSSPOIDT(PSSOR)
        . . . DO EN2^PSSHL1(PSSOR,"MUP")
        Q

MFA
        I $P($G(^PS(59.7,1,80)),"^",2)>1 do
        . S PSSOR=$P(^PS(52.6,ENTRY,0),"^",11)
        . S PSSDD=$P(^PS(52.6,ENTRY,0),"^",2)
        . I PSSOR]"" do
        . . D EN^PSSPOIDT(PSSOR)
        . . D EN2^PSSHL1(PSSOR,"MUP")
        . . D MFDD
        Q

MFS
        I $P($G(^PS(59.7,1,80)),"^",2)>1 do
        . S PSSOR=$P(^PS(52.7,ENTRY,0),"^",11)
        . S PSSDD=$P(^PS(52.7,ENTRY,0),"^",2)
        . I PSSOR]"" do
        . . D EN^PSSPOIDT(PSSOR)
        . . D EN2^PSSHL1(PSSOR,"MUP")
        . . D MFDD
        Q

MFDD
        I $D(^PSDRUG(PSSDD,2)) do
        . S PSSOR=$P(^PSDRUG(PSSDD,2),"^",1)
        . I PSSOR]"" do
        . . D EN^PSSPOIDT(PSSOR)
        . . DO EN2^PSSHL1(PSSOR,"MUP")
        Q

OPEI
        I $D(^PSDRUG(DISPDRG,"ND")),$P(^PSDRUG(DISPDRG,"ND"),"^",10)]"" do
        . S DIE="^PSDRUG(",DR="28",DA=DISPDRG
        . D ^DIE
        Q

DEA     ;
        I $P($G(^PSDRUG(DISPDRG,3)),"^")=1,($P(^PSDRUG(DISPDRG,0),"^",3)[1!($P(^(0),"^",3)[2)) do
        . D DSH
        Q

DSH
        W !!,"****************************************************************************"
        W !,"This entry contains a ""1"" or a ""2"" in the ""DEA, SPECIAL HDLG""",!
        W "field, therefore this item has been UNMARKED for CMOP transmission."
        W !,"****************************************************************************",!
        S $P(^PSDRUG(DISPDRG,3),"^")=0
        K ^PSDRUG("AQ",DISPDRG)
        S DA=DISPDRG
        N %
        D ^PSSREF
        Q
