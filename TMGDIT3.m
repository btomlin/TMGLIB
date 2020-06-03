TMGDIT3        ;SFISC/TKW - SILENT TRANSFER/MERGE ROUTINE ;3/15/13, 2/2/14
         ;;1.0;TMG-LIB;**1**;2/15/15
        ;;22.2V1;VA FILEMAN;;Jan 31, 2013
        ;"//kt Modified to add error reporting.
 ;
 ;"~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--
 ;"Copyright (c) 6/23/2015  Kevin S. Toppenberg MD
 ;"
 ;"This file is part of the TMG LIBRARY, and may only be used in accordence
 ;" to license terms outlined in separate file TMGLICNS.m, which should 
 ;" always be distributed with this file.
 ;"~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--~--
 ;
        
TRNMRG        ; TRANSFER OR MERGE RECORDS SILENTLY (CALLED FROM TRNMRG^DIT)
        N I,J,Z,DITYPM,DDF,DDT,DFR,DMRG,DKP,DTO,DFL,DTL,DA,DIZZ,DIK,DITF D CLEAN^DIEFU
        F I=1:1 S DITYPM=$E(DIFLG,I) Q:DITYPM=""  Q:"MOAR"[DITYPM
        I DITYPM="" G ERR0
        I '$G(DIFFNO),$G(DITFNO) S DFR=DIFFNO,DIFFNO=+DITFNO I $E(DFR,$L(DFR))=")" S DFR=$$OREF^DIQGU(DFR)
        I '$G(DIFFNO)!('$D(^DD(+$G(DIFFNO),.01,0))) S DIERRMSG=$$EZBLD^DIALOG(8082)_" "_$$EZBLD^DIALOG(8084) G ERR3
        S DITFNO=+$G(DITFNO) S:'DITFNO DITFNO=DIFFNO I DITFNO'=DIFFNO,'$D(^DD(DITFNO,.01,0)) S DIERRMSG=$$EZBLD^DIALOG(8083)_" "_$$EZBLD^DIALOG(8084) G ERR3
        I '$G(DIFIEN) S DIERRMSG=$$EZBLD^DIALOG(8082)_" "_$$EZBLD^DIALOG(8085) G ERR3
        F I=0:1 S J=$P(DIFIEN,",",I+1) Q:'J  S DA(I)=J,DFL=I*2+1
        S (I,J)=I-1 D  G:I'=J ERR5
        . I I=0,$D(^DD(DIFFNO,0,"UP")) S J=-1 Q
        . N Z S Z=DIFFNO,J=0 F  Q:'$D(^DD(Z,0,"UP"))  S J=J+1,Z=^("UP")
        . Q
        S J=0
SD0        N @("D"_J) S @("D"_J)=DA(I),I=I-1,J=J+1 I I>-1 G SD0
        S DA=DA(0) K DA(0)
        S DDF(DFL)=DIFFNO,DDT(DFL-1)=DITFNO S:DIFFNO=DITFNO DDT(DFL)=DITFNO
        S DFR(DFL)=$S($G(DFR)]"":DFR,1:$$ROOT^DIQGU(DIFFNO,DIFIEN,"",1))_+DIFIEN_"," Q:$D(DIERR)  G:'$D(@(DFR(DFL)_"0)")) ERR1 S DIZZ=^(0)
        S:$G(DITIEN)="" DITIEN="+?1,"_$P(DIFIEN,",",2,99)
        Q:'$$IENCHK(DITFNO,DITIEN)
        S (DTO(DFL-1),DIK)=$$ROOT^DIQGU(DITFNO,DITIEN,"",1) Q:$D(DIERR)
        I DITIEN S DTO(DFL)=DTO(DFL-1)_+DITIEN_"," I '$D(@(DTO(DFL)_"0)")) G ERR2
        I 'DITIEN,$D(^DD(DITFNO,0,"UP")) D  I '$D(DITIEN) G ERR2
        . N X,Y,Z S X=^DD(DITFNO,0,"UP"),Y=$P(DITIEN,",",2,99),Z=$$ROOT^DIQGU(X,Y) I $D(DIERR) K DITIEN Q
        . I '$D(@(Z_$P(Y,",")_",0)")) K DITIEN Q
        . I $P($G(^DD(DITFNO,.01,0)),U,2)["W" K DITIEN Q
        . I '$D(@(DTO(DFL-1)_"0)")) S Z=$O(^DD(X,"SB",DITFNO,0)) I Z S Z=$P($G(^DD(X,Z,0)),U,2) I Z S @(DTO(DFL-1)_"0)")="^"_Z_"^^"
        . Q
        I DIFFNO'=DITFNO D  I '$D(DITF) G ERR4
        . N %,A,L,V,X,Y,Z,DIC K ^UTILITY("DITR",$J)
        . S A=1,L=0,L(DDF(DFL))=DDT(DFL-1)
        . D MAP2^DIT Q
        S DMRG=$S(DIFLG["A":0,1:1),DKP=$S(DIFLG["M":1,1:0),DTO=$S(DIFFNO=DITFNO:0,1:1)
        N %,A,B,V,W,X,Y,DFN,DTN,DINUM,DIC,DIIX
        ;"Original --> I 'DITIEN D  Q:A
        I 'DITIEN D  GOTO:A ERR6   ;"//kt mod
        . S (DFL,DTL)=DFL-1,Z=DIZZ D ^DITR1 Q:A
        . S DFL=DFL+1,DITIEN=+Y_","_$P(DITIEN,",",2,99)
        . Q
        S DTL=DFL,DFN(DFL)=-1 D N^DITR
        I DIFLG'["X" Q
        K DA F I=1:1 S J=$P(DITIEN,",",I) Q:'J  S:I=1 DA=J I I>1 S DA(I-1)=J
        D IXALL^DIK
        Q
        ;
IENCHK(DIFILE,DIIEN)        ;EXTRINSIC FUNCTIO TO CHECK THAT IEN STRING AND FILE/SUBFILE NO. ARE IN SYNC
        ;DIFILE=file/subfile#, DIIEN=IEN string
        N I,J
        S I=$L($G(DIIEN),",") I I=1 G ERX
        S I=I-1,J=0 D  I I'=J G ERX
        . I I=1,$D(^DD(DIFILE,0,"UP")) Q
        . S J=1 F  Q:'$D(^DD(DIFILE,0,"UP"))  S J=J+1,DIFILE=^("UP")
        . Q
        Q 1
ERX        K I S I(1)=DIFILE,I("IENS")=DIIEN D BLD^DIALOG(205,.I) Q 0
        ;
ERR0        D BLD^DIALOG(301,DIFLG) Q
ERR1        S DIERRMSG=$$EZBLD^DIALOG(8082)_" "_$$EZBLD^DIALOG(8078) G ERR3
ERR2        S DIERRMSG=$$EZBLD^DIALOG(8083)_" "_$$EZBLD^DIALOG(8078)
ERR3        D BLD^DIALOG(202,DIERRMSG) Q
ERR4        D BLD^DIALOG(1504) Q
ERR5        K I S I(1)=DIFFNO,I("IENS")=DIFIEN D BLD^DIALOG(205,.I) Q
ERR6    D BLD^DIALOG(8077) Q   ;"//kt added.  Should be changed to a better error message describing generic save problem 
        ;202  The input param...that identifies...|1| is missing or invalid.
        ;205  File...number and IEN string represent different...levels.       
        ;301  The passed flag(s) '|1|' are unknown or inconsistent.
        ;1504  No matching .01 field names...Transfer/Merge cannot be done
        ;8082  Transfer FROM
        ;8083  Transfer TO
        ;8084  file number
        ;8085  IEN string
        ;8077  Changes not saved!  "//kt added
