
//VFOAAB20 JOB (2062AB20),
//             'VFO ORD ACKNLDG',
//             CLASS=B,
//             MSGCLASS=H,
//             MSGLEVEL=(1,1)
//*
/*ROUTE PRINT LOCAL
//*
//********************************************************************
//*DESC:     VFO ORD ACKNLDG
//*
//*UPDATES:  NO
//*
//*RECOVERY: CORRECT PROBLEM, RERUN THE JOB
//********************************************************************
//*
//SAR  OUTPUT CLASS=H,DEST=LOCAL
//RAB25 OUTPUT CLASS=T,DEST=LOCAL,WRITER=VFOAB25
//*PRNT OUTPUT CLASS=A,DEST=VFORM005
//TUCSON OUTPUT CLASS=A,DEST=IVDTU010
//WASHGT OUTPUT CLASS=A,DEST=VFOWN001
//LASER OUTPUT PRMODE=PAGE,CHARS=GT10,PAGEDEF=A06460,
//     FORMDEF=010110,DEST=LOCAL
//*
//JOBLIB   DD  DISP=SHR,DSN=ALC.VFO.EMRG.LOADLIB
//         DD  DISP=SHR,DSN=ALC.VFO.PROD.LOADLIB
//*
//*-------------------------------------------------------------------*
//*            SORTIN  CONTROL CARD
//*-------------------------------------------------------------------*
//SORT1    EXEC PGM=SORT
//SORTIN   DD  DSN=VFO.DATALIB(VFOANITE),
//             DISP=SHR
//SORTOUT  DD  DSN=&&DATE1,DATACLAS=FDATA,
//             DISP=(NEW,PASS)
//SYSOUT   DD  SYSOUT=*
//SYSIN    DD  *
 MERGE FIELDS=COPY
//*
//*===================================================================*
//*DESC  NEW-ORDER/CHANGE ACKNOWLEDGEMENTS.                           *
//*===================================================================*
//*   SORT FINDER FILE BY ORDER NO, DATE, FINDER FLAG (D), SEQ NO.    *
//*        INCLUDE ONLY 'OE ' TYPE RECORDS                            *
//*-------------------------------------------------------------------*
//S010SORT EXEC PGM=SORT
//SORTIN   DD  DSN=VFO.VFOFIND.FINDER.ONLKSDS,
//             DISP=SHR
//SORTOUT  DD  DSN=&&FDATA01,
//             DISP=(NEW,PASS,DELETE),
//             LRECL=100,DATACLAS=FEXTD,
//             SPACE=(100,(5,5),RLSE),AVGREC=K
//SYSOUT   DD  SYSOUT=*
//SYSIN    DD  *
  SORT FIELDS=(8,6,A,14,6,A,37,2,D,20,4,A),FORMAT=BI
  INCLUDE COND=(5,3,CH,EQ,C'OE ')
//*
//*-------------------------------------------------------------------*
//* S020    SEPARATE NEW ORDERS & CHANGE ORDERS IN FINDER FILE        *
//*-------------------------------------------------------------------*
//S020AB23 EXEC PGM=A220AB23
//FINDER   DD  DSN=&&FDATA01,
//             DISP=(OLD,DELETE)
//NEWORDS  DD  DSN=&&FDATANEW,
//             DISP=(NEW,PASS,DELETE),
//             LRECL=100,DATACLAS=FEXTD,
//             SPACE=(100,(5,5),RLSE),AVGREC=K
//CHGORDS  DD  DSN=&&FDATACHG,
//             DISP=(NEW,PASS,DELETE),
//             LRECL=100,DATACLAS=FEXTD,
//             SPACE=(100,(5,5),RLSE),AVGREC=K
//SYSIN    DD  DSN=&&DATE1,
//             DISP=(OLD,PASS)
//SYSOUT   DD  SYSOUT=*
//SYSABOUT DD  SYSOUT=*
//SYSDBOUT DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//*
//*-------------------------------------------------------------------*
//* S030  SORT CHANGE ORDER FILE BY DATE, ORDER NO, SEQ. NO.          *
//*-------------------------------------------------------------------*
//S030SORT EXEC PGM=SORT
//SORTIN   DD  DSN=&&FDATACHG,
//             DISP=(OLD,DELETE)
//SORTOUT  DD  DSN=&&FDATA10,
//             DISP=(NEW,PASS,DELETE),
//             LRECL=100,DATACLAS=FEXTD,
//             SPACE=(100,(5,5),RLSE),AVGREC=K
//SYSOUT   DD  SYSOUT=*
//SYSIN    DD  *
  SORT FIELDS=(8,6,A,14,6,A,37,2,D,20,4,A),FORMAT=BI
  INCLUDE COND=(5,3,CH,EQ,C'OE ')
//*
//*-------------------------------------------------------------------*
//* S035  SEPARATE TUCSON AND RICHMOND.                     MSK-213843*
//*-------------------------------------------------------------------*
//S035SORT EXEC PGM=SORT
//SYSOUT   DD  SYSOUT=*
//SORTIN   DD  DSN=&&FDATA10,
//             DISP=(OLD,PASS)
//SORTOF01 DD  DSN=&&FDATA18,
//             DISP=(NEW,PASS),
//             LRECL=100,DATACLAS=FEXTD,
//             SPACE=(100,(5,5),RLSE),AVGREC=K
//SORTOF02 DD DSN=&&FDATA20,
//             DISP=(NEW,PASS),
//             LRECL=100,DATACLAS=FEXTD,
//             SPACE=(100,(5,5),RLSE),AVGREC=K
//SORTOF03 DD DSN=&&FDATA21,
//             DISP=(NEW,PASS),
//             LRECL=100,DATACLAS=FEXTD,
//             SPACE=(100,(5,5),RLSE),AVGREC=K
//SYSIN    DD *
  SORT FIELDS=COPY
    OUTFIL FILES=01,INCLUDE=(3,2,CH,EQ,C'18')
    OUTFIL FILES=02,INCLUDE=(3,2,CH,EQ,C'20')
    OUTFIL FILES=03,INCLUDE=(3,2,CH,EQ,C'21')
/*
//*
//*-------------------------------------------------------------------*
//* S040   DELETE/DEFINE COS WORK FILE
//*-------------------------------------------------------------------*
//S040IDCM EXEC PGM=IDCAMS
//SYSIN    DD  DSN=ALC.VFO.PROD.PARMLIB(VFODCOSW),
//             DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//AMSDUMP  DD SYSOUT=*
//*
//*-------------------------------------------------------------------*
//*  S050  SORT COS (CHANGE & ENTRY)   TO WORK FILE REDEFINING KEY    *
//*-------------------------------------------------------------------*
//S050SORT EXEC PGM=SORT
//SORTIN   DD  DSN=VFO.VFOCOS.OE.COSTSALE.ONLKSDS,
//             DISP=SHR
//SORTOUT  DD  DSN=WORK.VFO.VFOCOS.OE.COSTSALE.ONLKSDS,
//             DISP=SHR
//SYSOUT   DD  SYSOUT=*
//SYSIN    DD  *
  SORT   FIELDS=(1,6,A,13,2,A,15,6,A,21,4,A,7,6,A),FORMAT=BI
  OUTREC FIELDS=(1,6,13,2,15,6,21,4,7,6,25,626)
  INCLUDE COND=(25,2,CH,EQ,C'1 ',OR,25,2,CH,EQ,C'2 ')
  RECORD TYPE=F
//*
//*-------------------------------------------------------------------*
//* S080      A824AB10  PRINT ORDER CHANGES SUMMARY                   *
//* MKS - 213843 TUCSON PRINT                                         *
//*-------------------------------------------------------------------*
//S080AB25 EXEC IMSDBB,PROG=A220AB25,PSB=VFOPSBRR,HLQ=VFO
//CHGORDS  DD  DSN=&&FDATA18,
//             DISP=(OLD,DELETE)
//COSFILE  DD  DSN=WORK.VFO.VFOCOS.OE.COSTSALE.ONLKSDS,
//             DISP=SHR
//ARMAST   DD  DSN=CORP.NAME.ADDR.FILE,
//             DISP=SHR
//PRINTER  DD  SYSOUT=(,),OUTPUT=(*.SAR,*.TUCSON)
//SYSIN    DD  DSN=&&DATE1,
//             DISP=(OLD,PASS)
//SYSOUT   DD  SYSOUT=*
//SYSABOUT DD  SYSOUT=*
//SYSDBOUT DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//*
//*-------------------------------------------------------------------*
//* S082      A824AB10  PRINT ORDER CHANGES SUMMARY    SAVE           *
//* MKS - 213843 RICHMOND PRINT                                       *
//*-------------------------------------------------------------------*
//S082AB25 EXEC IMSDBB,PROG=A220AB25,PSB=VFOPSBRR,HLQ=VFO
//CHGORDS  DD  DSN=&&FDATA20,
//             DISP=(OLD,DELETE)
//COSFILE  DD  DSN=WORK.VFO.VFOCOS.OE.COSTSALE.ONLKSDS,
//             DISP=SHR
//ARMAST   DD  DSN=CORP.NAME.ADDR.FILE,
//             DISP=SHR
//PRINTER  DD  SYSOUT=(,),OUTPUT=(*.SAR)
//SYSIN    DD  DSN=&&DATE1,
//             DISP=(OLD,PASS)
//SYSOUT   DD  SYSOUT=*
//SYSABOUT DD  SYSOUT=*
//SYSDBOUT DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//*
//*-------------------------------------------------------------------*
//* S083      A220AB25  PRINT ORDER CHANGES SUMMARY    SAVE           *
//* MKS - 311944 WASHINGTON PRINT                                     *
//*-------------------------------------------------------------------*
//S083AB25 EXEC IMSDBB,PROG=A220AB25,PSB=VFOPSBRR,HLQ=VFO
//CHGORDS  DD  DSN=&&FDATA21,
//             DISP=(OLD,DELETE)
//COSFILE  DD  DSN=WORK.VFO.VFOCOS.OE.COSTSALE.ONLKSDS,
//             DISP=SHR
//ARMAST   DD  DSN=CORP.NAME.ADDR.FILE,
//             DISP=SHR
//PRINTER  DD  SYSOUT=*
//SYSIN    DD  DSN=&&DATE1,
//             DISP=(OLD,PASS)
//SYSOUT   DD  SYSOUT=*
//SYSABOUT DD  SYSOUT=*
//SYSDBOUT DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//*
//*-------------------------------------------------------------------*
//* S085      A824AB10  PRINT ORDER CHANGES SUMMARY    SAVE           *
//* MKS - 213843 BOTH TUCSON & RICHMOND TO ONDEMAND                   *
//* MKS - 311944 ADDED WASHINGTON,PA    TO ONDEMAND                   *
//*-------------------------------------------------------------------*
//S085AB25 EXEC IMSDBB,PROG=A220AB25,PSB=VFOPSBRR,HLQ=VFO
//CHGORDS  DD  DSN=&&FDATA10,
//             DISP=(OLD,DELETE)
//COSFILE  DD  DSN=WORK.VFO.VFOCOS.OE.COSTSALE.ONLKSDS,
//             DISP=SHR
//ARMAST   DD  DSN=CORP.NAME.ADDR.FILE,
//             DISP=SHR
//PRINTER  DD  SYSOUT=(,),OUTPUT=(*.SAR,*.RAB25)
//SYSIN    DD  DSN=&&DATE1,
//             DISP=(OLD,PASS)
//SYSOUT   DD  SYSOUT=*
//SYSABOUT DD  SYSOUT=*
//SYSDBOUT DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//*
//*-------------------------------------------------------------------*
//* SCAMS1    DELETE COS WORK FILE                                    *
//*-------------------------------------------------------------------*
//SCAMS1   EXEC PGM=IDCAMS
//SYSPRINT DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//AMSDUMP  DD  SYSOUT=*
//SYSIN    DD  *
 DELETE (WORK.VFO.VFOCOS.OE.COSTSALE.ONLKSDS) CLUSTER PURGE NOERASE
//*
//*-------------------------------------------------------------------*
//* S090   DELETE 'OE' FINDER RECORDS - VFOFIND MUST BE CLOSED TO CICS*
//*        01/2014 INCLUDE DELETE OF PO FINDER RECORDS                *
//*        01/13/14 ADD DELETE OF TW1 FINDER RECORDS        MKS232564 *
//*-------------------------------------------------------------------*
//S090SORT EXEC PGM=SORT,PARM='RESET'
//SORTIN   DD  DSN=VFO.VFOFIND.FINDER.ONLKSDS,
//             DISP=SHR
//SORTOUT  DD  DSN=VFO.VFOFIND.FINDER.ONLKSDS,
//             DISP=SHR
//SYSOUT   DD  SYSOUT=*
//* OMIT COND=(5,2,CH,EQ,C'OE')  ADD PO RECORDS TO OMIT STATEMENT
//* OMIT COND=(5,2,CH,EQ,C'OE',OR,5,2,CH,EQ,C'PO') MKS232564
//SYSIN    DD  *
  SORT FIELDS=(1,33,A),FORMAT=BI
  OMIT COND=(5,2,CH,EQ,C'OE',OR,5,2,CH,EQ,C'PO',OR,5,3,CH,EQ,C'TW1')
  RECORD TYPE=F
//*
//*********************************************************************
//*   ARE THERE ANY RECORDS ON THE FINDER FILE?     JAN14             *
//*********************************************************************
//S100IDCM EXEC PGM=IDCAMS
//SYSIN    DD *
 PRINT INFILE (PRINTFL) COUNT (1)
//PRINTFL  DD  DISP=SHR,DSN=VFO.VFOFIND.FINDER.ONLKSDS
//SYSPRINT DD  SYSOUT=*
//*
//*********************************************************************
//*   EXECUTE INIT ONLY WHEN FILE IS EMPTY          JAN14             *
//*********************************************************************
//IF01 IF S100IDCM.RC = 0 THEN
//  ELSE
//*
//*====================================================================
//* INITIALIZE THE FINDER VSAM FILE
//*====================================================================
//S110INIT EXEC PGM=INITKSD2
//INITKSDS DD DSN=VFO.VFOFIND.FINDER.ONLKSDS,DISP=SHR
//SYSOUT   DD  SYSOUT=*
//SYSPRINT DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//*
// ENDIF
//
//************************************************************
//* TITLE: JCLU-NEW/CHG ORD ACKNOWL
//* CREATED IN LIBRFILE: 08/19/92
//*
//*  HISTORY RECORDS FOR THIS MODULE:
//*  02/04/93 TURNED ARCHIVING ON: 02-04-92; R. T. GRIFFIN
//*                   00000023
//*           TURNED ARCHIVING ON: 02-04-92; R. T. GRIFFIN
//*                   00000023
//*
//*
//*
//************************************************************
//*
//*-------------------------------------------------------------------*
//* RGAI-6B5HVF 04/12/2005 NAH ALCHEMIST MIGRATION                    *
//*-------------------------------------------------------------------*
//*FEB06Z*------------------------------------------------------------*
//*FEB06Z* TSCI-68QPLE OU5 FOREIGN CURRENCY CHANGES.                  *
//*FEB06Z*------------------------------------------------------------*
//*-------------------------------------------------------------------*
//* DEC06 MSMH-6URHZK INFY FIX VFO DELIVERED BATCH JCL TO CONFORM     *
//*                        TO VFO AND CORPORATE STANDARDS             *
//*-------------------------------------------------------------------*
//* MKS# 117321  PDW  SEND AB25 REPORT TO ONDEMAND                    *
//*-------------------------------------------------------------------*
//* MKS# 209377  AIT  06/2013                                         *
//*      STOP PRINTING REPORT AB25 ON DEVICE VFORM005                 *
//*-------------------------------------------------------------------*
//* MKS# 213843  PTM  07/2013  PMCKIERNAN  PM4573X                    *
//*      SEPARATE RICHMOND AND TUCSON REPORTS
//*-------------------------------------------------------------------*
//* MKS# 232368  AIT  01/2014  A.TOTINO                               *
//*      DELETE PO FINDER RECORDS FROM FINDER FILE
//*-------------------------------------------------------------------*
//* MKS232564 GS55158 01/13/2014 ADD TW1 TO S090SORT OMIT STATEMENT
//*-------------------------------------------------------------------*
//* MKS# 233786  AIT  01/2014  A.TOTINO                               *
//*      ADD STEP TO CHECK IF FINDER FILE IS EMPTY.  IF EMPTY, RUN
//*      INITIALIZE OF FILE TO PREVENT ABENDS IN SUBSEQUENT JOBS.
//*-------------------------------------------------------------------*
//* MKS# 298752  ADD ON-CALL DOCUMENTATION. 09/28/15;  -MN54503-      *
//*-------------------------------------------------------------------*
//* FEB16 MKS 311944  M. NEYMAN.                                      *
//*       MAKE CHANGES TO PROCESS NEW LOC 21:                         *
//*       1.CHANGED STEP S035SORT. 2. ADDED STEP S083AB25.            *
//*       3.ADDED EXTENDED ALLOC FOR OUTPUT FILES.                    *
//*-------------------------------------------------------------------*
//* MKS# 441271  GP 03/2020  REMOVED WASHINGTON PRINTER IN            *
//*                          STEP S083AB25                            *
//*-------------------------------------------------------------------*