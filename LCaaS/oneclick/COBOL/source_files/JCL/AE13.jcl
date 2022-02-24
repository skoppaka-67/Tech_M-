
//VFOAAE13 JOB (2062),
//             'VFO CREDITS',
//             CLASS=U,
//             PRTY=1,
//             MSGCLASS=H,
//             MSGLEVEL=(1,1)
//*
/*ROUTE PRINT LOCAL
//*
//********************************************************************
//*DESC:     VFO CREDITS
//*
//*UPDATES:  YES
//*
//*RUN FREQUENCY: DAILY
//*
//*RECOVERY: CORRECT PROBLEM, RESTART THE JOB AT APPROPRIATE STEP.
//********************************************************************
//*
//*     /*ROUTE XEQ CLPKR2  TO RUN ON TSO2 FOR TEST ONLY
//*
//SAR  OUTPUT CLASS=H,DEST=LOCAL
//SARF OUTPUT CLASS=H,DEST=LOCAL,FORMDEF=VFOIV1,PAGEDEF=VFOIV
//FAXA OUTPUT CLASS=A,DEST=VFORM007
//PRT1 OUTPUT CLASS=T,DEST=LOCAL,WRITER=VFOAE13A
//ARP1 OUTPUT CLASS=T,DEST=LOCAL,WRITER=VFOAE13B
//FCRD OUTPUT CLASS=T,DEST=LOCAL,WRITER=VFOAE13D
//*FCRD OUTPUT CLASS=A,DEST=VFORM007,FORMDEF=VFOIV1,PAGEDEF=VFOIV
//*PRT1 OUTPUT CLASS=A,DEST=VFORM007
//*ARPR OUTPUT CLASS=A,DEST=VFORM007
//*ARP1 OUTPUT CLASS=A,DEST=VFORM007
//*FAXA OUTPUT CLASS=H,DEST=LOCAL,WRITER=VFOAE13C
//*
//JOBLIB   DD  DISP=SHR,DSN=ALC.VFO.EMRG.LOADLIB
//         DD  DISP=SHR,DSN=ALC.VFO.PROD.LOADLIB
//         DD  DISP=SHR,DSN=ALC.MSS.EMRG.LOADLIB
//         DD  DISP=SHR,DSN=ALC.MSS.PROD.LOADLIB
//         DD  DISP=SHR,DSN=ALC.CIS.EMRG.LOADLIB
//         DD  DISP=SHR,DSN=ALC.CIS.PROD.LOADLIB
//*
//PROCLIB JCLLIB ORDER=(ALC.VFO.PROD.PROCLIB)
//*
//*********************************************************************
//* ADDED IDCAMS STEP TO DELETE DAILY CREDITS AND ADDBILLS TO CARMS   *
//* FILES FOR NEW EXTENDED LENGTH FILE                                *
//* THERE SHOULD BE A CCFAIL STATEMENT IN YOUR DAILY ESP EVENT IN CASE*
//* THE FOLLOWING FILES ARE NOT CATALOGUED TO DELETE SO THE JOB WON'T *
//* BOMB BECAUSE OF IT'S RETURN CODE. ALWAYS MAKE SURE BOTH STEP      *
//* NAMES MATCH BETWEEN HERE AND YOUR ESP STEP NAME.                  *
//*********************************************************************
//* DELETE DAILY A/R ACTIVITY FILES                                   *
//*-------------------------------------------------------------------*
//S000IDCA EXEC PGM=IDCAMS
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  *
   DELETE                            -
     VFO.DAILY.CREDITS.TO.CARMS.SEQ  -
     PURGE
     IF LASTCC = 8 THEN SET MAXCC = 0
   DELETE                            -
     VFO.DAILY.ADDBILLS.TO.CARMS.SEQ -
     PURGE
     IF LASTCC = 8 THEN SET MAXCC = 0
   DELETE                            -
     VFO.CREDIT.FILE                 -
     PURGE
     IF LASTCC = 8 THEN SET MAXCC = 0
   DELETE                            -
     VFO.ADDBILL.FILE                -
     PURGE
     IF LASTCC = 8 THEN SET MAXCC = 0
   DELETE  VFO.CREDIT.FAX.PARAM            -
     PURGE
     IF LASTCC = 8 THEN SET MAXCC = 0
   DELETE  VFO.CREDIT.FAX.DATA             -
     PURGE
     IF LASTCC = 8 THEN SET MAXCC = 0
/*
//*
//*===================================================================*
//* DELETE PREVIOUS VERSIONS OF EMAIL FILES.
//*===================================================================*
//S005DEL  EXEC PGM=IDCAMS
//SYSPRINT DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//SYSIN    DD  *
  DELETE (VFO.AE13.EMAIL)
   IF LASTCC = 8 THEN SET MAXCC = 0
/*
//*
//*-------------------------------------------------------------------*
//* SORTIN CONTROL CARD                                               *
//*-------------------------------------------------------------------*
//S010SORT EXEC PGM=SORT
//SORTIN   DD  DSN=VFO.DATALIB(VFOANITE),
//             DISP=SHR
//SORTOUT  DD  DSN=&&DATE1,DATACLAS=FDATA,
//             DISP=(NEW,PASS)
//SYSOUT   DD  SYSOUT=*
//SYSIN    DD  *
  MERGE FIELDS=COPY
//*
//*-------------------------------------------------------------------*
//* VFO BUILD FOR CREDITS                                             *
//*-------------------------------------------------------------------*
//S020AE12 EXEC PGM=A220AE12
//VFOCRED  DD  DSN=VFO.VFOCRED.OE.CREDITS.ONLKSDS,
//             DISP=SHR
//FINDER   DD  DSN=VFO.VFOFIND.FINDER.ONLKSDS,
//             DISP=SHR
//VFOVRB   DD  DSN=VFO.VFOVERB.VERB.FILE.ONLKSDS,
//             DISP=SHR
//CREDIT   DD  DSN=&&FDATA5,
//             DISP=(NEW,PASS),
//             LRECL=500,
//             SPACE=(500,(10,5),RLSE),AVGREC=K
//ADDBILL  DD  DSN=&&FDATA2,
//             DISP=(NEW,PASS),
//             LRECL=500,
//             SPACE=(500,(10,5),RLSE),AVGREC=K
//FINDUPDT DD  DSN=&&VDATAFN,
//             DISP=(NEW,PASS),
//             LRECL=1999,
//             SPACE=(1999,(1,1),RLSE),AVGREC=K
//SYSUDUMP DD  SYSOUT=*
//SYSABOUT DD  SYSOUT=*
//SYSDBOUT DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//SYSIN    DD  DSN=&&DATE1,
//             DISP=(OLD,PASS)
//*
//*-------------------------------------------------------------------*
//* SORT CREDIT INVOICE RECORDS                                       *
//*-------------------------------------------------------------------*
//S030SORT EXEC PGM=SORT
//SORTIN   DD  DSN=&&FDATA5,
//             DISP=(OLD,DELETE,DELETE)
//SORTOUT  DD  DSN=&&FDATA3,
//             DISP=(NEW,PASS),
//             LRECL=500,
//             SPACE=(500,(10,5),RLSE),AVGREC=K
//SYSOUT   DD  SYSOUT=*
//SYSIN    DD  *
 SORT      FIELDS=(1,12,A),FORMAT=CH
//*
//*-------------------------------------------------------------------*
//* VFO CREDIT PRINT                                                  *
//* MKS 393043 - STOP PRINTING AP REPORTS TO THE PRINTER (VFORM007)   *
//*              AND SEND IT ONLY TO ON-DEMAND                        *
//*-------------------------------------------------------------------*
//S040AE13 EXEC IMSDBB2,PROG=A220AE13,PSB=VFOPSBRR,HLQ=VFO
//G.DUMMY  DD  DUMMY
//CRPREMIT DD  DSN=CORP.COREMIT.REMIT.TO.LOCKBOX,
//             DISP=SHR
//ARMAST   DD  DSN=CORP.NAME.ADDR.FILE,
//             DISP=SHR
//MSSCRED  DD  DSN=&&FDATA3,
//             DISP=(OLD,PASS,DELETE)
//MSSVERB  DD  DSN=VFO.VFOVERB.VERB.FILE.ONLKSDS,
//             DISP=SHR
//RATES    DD  DSN=CIS.CISFCUR.EXCHANGE.ONLKSDS,DISP=SHR
//ARCARD   DD  DSN=VFO.DAILY.CREDITS.TO.CARMS.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             LRECL=100,SPACE=(100,(5,1),RLSE),AVGREC=K
//*
//FAXPARAM DD DSN=VFO.CREDIT.FAX.PARAM,
//             DISP=(NEW,CATLG,DELETE),
//             LRECL=500,SPACE=(500,(5,1),RLSE),AVGREC=K
//*
//FAXDATA  DD DSN=VFO.CREDIT.FAX.DATA,
//             DISP=(NEW,CATLG,DELETE),
//             LRECL=133,SPACE=(133,(5,1),RLSE),AVGREC=K
//*
//PRINTER  DD  SYSOUT=(,),OUTPUT=(*.SARF,*.FCRD,*.SAR)
//PRINTER3 DD  SYSOUT=(,),OUTPUT=(*.PRT1,*.SAR)
//ARPRINT  DD  SYSOUT=(,),OUTPUT=(*.SAR,*.ARP1)
//PRINTER2 DD  DSN=VFO.CREDIT.FILE,
//             DISP=(NEW,CATLG,DELETE),RECFM=FBA,
//             LRECL=102,SPACE=(102,(50,10),RLSE),AVGREC=K
//SYSUDUMP DD  SYSOUT=*
//SYSABOUT DD  SYSOUT=*
//SYSDBOUT DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//SYSIN    DD  DSN=&&DATE1,
//             DISP=(OLD,PASS)
//*
//*-------------------------------------------------------------------*
//* SORT ADDBILL INVOICE RECORDS                                      *
//*-------------------------------------------------------------------*
//S050SORT EXEC PGM=SORT
//SORTIN   DD  DSN=&&FDATA2,
//             DISP=(OLD,DELETE,DELETE)
//SORTOUT  DD  DSN=&&FDATA4,
//             DISP=(NEW,PASS),
//             LRECL=500,
//             SPACE=(500,(10,5),RLSE),AVGREC=K
//SYSOUT   DD  SYSOUT=*
//SYSIN    DD  *
 SORT      FIELDS=(1,12,A),FORMAT=CH
//*
//*-------------------------------------------------------------------*
//* VFO ADDBILL PRINT                                                 *
//* MKS 393043 - STOP PRINTING AP REPORTS TO THE PRINTER (VFORM007)   *
//*              AND SEND IT ONLY TO ON-DEMAND                        *
//*-------------------------------------------------------------------*
//S060AE13 EXEC IMSDBB2,PROG=A220AE13,PSB=VFOPSBRR,HLQ=VFO
//G.DUMMY  DD  DUMMY
//CRPREMIT DD  DSN=CORP.COREMIT.REMIT.TO.LOCKBOX,
//             DISP=SHR
//ARMAST   DD  DSN=CORP.NAME.ADDR.FILE,
//             DISP=SHR
//MSSCRED  DD  DSN=&&FDATA4,
//             DISP=(OLD,PASS,DELETE)
//MSSVERB  DD  DSN=VFO.VFOVERB.VERB.FILE.ONLKSDS,
//             DISP=SHR
//RATES    DD  DSN=CIS.CISFCUR.EXCHANGE.ONLKSDS,DISP=SHR
//ARCARD   DD  DSN=VFO.DAILY.ADDBILLS.TO.CARMS.SEQ,
//             DISP=(NEW,CATLG,DELETE),
//             LRECL=100,SPACE=(100,(5,1),RLSE),AVGREC=K
//*
//FAXPARAM DD DSN=VFO.CREDIT.FAX.PARAM,
//            DISP=MOD
//*
//FAXDATA  DD DSN=VFO.CREDIT.FAX.DATA,
//           DISP=MOD
//*
//PRINTER  DD  SYSOUT=(,),OUTPUT=(*.SARF,*.FCRD,*.SAR)
//PRINTER3 DD  SYSOUT=(,),OUTPUT=(*.PRT1,*.SAR)
//ARPRINT  DD  SYSOUT=(,),OUTPUT=(*.SAR,*.ARP1)
//PRINTER2 DD  DSN=VFO.ADDBILL.FILE,
//             DISP=(NEW,CATLG,DELETE),
//             LRECL=102,SPACE=(102,(50,10),RLSE),AVGREC=K
//SYSUDUMP DD  SYSOUT=*
//SYSABOUT DD  SYSOUT=*
//SYSDBOUT DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//SYSIN    DD  DSN=&&DATE1,
//             DISP=(OLD,PASS)
//*
//*-------------------------------------------------------------------*
//* S065    CHECK FAX FILES FOR EQUAL RECORD NOS. & CREDIT/ADDBILL NOS*
//*-------------------------------------------------------------------*
//S065AB2C EXEC PGM=A220AB2C
//EMAILNOT DD  DSN=VFO.AE13.EMAIL,
//             DISP=(NEW,CATLG,DELETE),
//             SPACE=(255,(10,5),RLSE),AVGREC=K,
//             LRECL=255
//EXCELPRM DD  DSN=ALC.VFO.PROD.PARMLIB(VFORAE13),DISP=SHR
//FAXPARAM DD  DSN=VFO.CREDIT.FAX.PARAM,
//             DISP=(OLD,KEEP,KEEP)
//FAXDATA  DD  DSN=VFO.CREDIT.FAX.DATA,
//             DISP=(OLD,KEEP,KEEP)
//SYSIN    DD  DSN=&&DATE1,
//             DISP=(OLD,PASS)
//SYSOUT   DD  SYSOUT=*
//SYSABOUT DD  SYSOUT=*
//SYSDBOUT DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//*
//*-------------------------------------------------------------------*
//*  SUBMIT SALES BATCH (CREDITS AND ADDBILLS) TO CARMS               *
//*  WRITE JCL FOR JOB FTXRSALE 'DAILY INVOICE INPUT'                 *
//*    TO INTERNAL READER FOR BATCH EXECUTION                         *
//*                                                                   *
//*  USE FTX.JCLLIB(ARINPUTT) INSTEAD OF FTX.JCLLIB(ARINPUT3)         *
//*      WHEN SENDING TESTS TO A/R                                    *
//*-------------------------------------------------------------------*
//*-----------WARNING----WARNING----WARNING------WARNING--------------*
//* DO NOT RUN THIS STEP WHEN TESTING, ONLY IF POINTING TO TEST       *
//*-----------WARNING----WARNING----WARNING------WARNING--------------*
//S070CARM EXEC PGM=IEBGENER
//SYSUT1   DD  DSN=ALC.FTX.PROD.JCLLIB(FTXIPUT1),DISP=SHR
//         DD  DSN=ALC.VFO.PROD.JCLLIB(VFOIPUT4),DISP=SHR
//         DD  DSN=ALC.FTX.PROD.JCLLIB(FTXIPUT3),DISP=SHR
//**TEST** DD  DSN=ALC.FTX.PROD.JCLLIB(FTXTPUT1),DISP=SHR
//**TEST** DD  DSN=ALC.FTX.PROD.JCLLIB(FTXIPUTT),DISP=SHR
//SYSUT2   DD  SYSOUT=(A,INTRDR)
//SYSIN    DD  DUMMY
//SYSPRINT DD  SYSOUT=(,),OUTPUT=(*.SAR)
//*
//*===================================================================*
//* MIMEBAT - EXECUTE BATCH SEND OF EMAIL NOTIFICATION IF RC NOT = 0.
//*===================================================================*
//  IF S065AB2C.RC > 0 THEN
//S075MAIL EXEC MIMEBAT
//INFILE DD  DSN=VFO.AE13.EMAIL,DISP=SHR
//  ENDIF
//*
//*-------------------------------------------------------------------*
//* FAX/EMAIL SEND PROC TO HOSTFAX OR HOSTFAX1.                       *
//*-----------  VFOTFAXC = TEST  -------------------------------------*
//  IF S065AB2C.RC = 0 THEN
//S080SEND EXEC VFOPFAXC,DIV=VFO,MODULE=CREDIT  ****PROD****
//  ENDIF
//*
//*-------------------------------------------------------------------*
//*  UPDATE CREDIT HEADER INVOICE PRINT FLAG                          *
//*     VIA BATCH-TO-ONLINE PROCESSING                                *
//*                                                                   *
//*  PROC LOADFIND IS IN DEFAULT LIBRARY EDP.PROD.PROCLIB             *
//*                                                                   *
//*  PROC WILL CLOSE BATCH FINDER FILE, WRITE DATA TO IT, AND OPEN IT *
//*  THEN IT WILL INITIATE BATCH-TO-ONLINE PROCESING                  *
//*     VIA STARTED TRANSACTION XXKW, OE MODULE, AE13 FUNCTION        *
//*                                                                   *
//*     HLQ=XXX   ===> DIVISIONAL HIGH-LEVEL-QUALIFIER                *
//*     ID=XXX    ===> MODULE NAME (IE: OE  EDC  PO   DIV   ETC)      *
//*     TR=XXXX   ===> TRANSACTION ID WITHIN MODULE                   *
//*     OPCL=X    ===> CLOSE/OPEN BATCH FINDER FILE       (Y OR N)    *
//*     SYS=X     ===> PRODUCTION/TEST CICS               (P OR T)    *
//*     FILETYP=X ===> PRODUCTION FILE NAME OR TEST FILE  (P OR T)    *
//*     FILE=XX.. ===> NAME OF TEMPORARY FILE PASSED                  *
//*                    IE: FILE=VDATA01  ======> DSN=&&VDATA01        *
//*-------------------------------------------------------------------*
//S085FIND EXEC LOADFIND,HLQ=VFO,ID=OE,TR=AE13,OPCL=Y,SYS=P,FILETYP=P,
//     FILE=VDATAFN
//*
//
//
//*
//************************************************************
//* TITLE: JCLU-CREDIT PRINT
//* CREATED IN LIBRFILE: 07/12/89
//*-------------------------------------------------------------------*
//*  HISTORY RECORDS FOR THIS MODULE:
//*  02/13/90  CHG BLKSIZES
//*  09/04/90 COPIED FROM WORK LIBRFILE: EXPANDED MODULE 09-04-90 RTG
//*                     00022
//*           COPIED FROM WORK LIBRFILE: EXPANDED MODULE 05-02-90 RTG
//*                     00022
//*  06/22/92 ADDED ARCHIVING TO ALL MODULES:  06-22-92 RTG
//*                   00000024
//*  05/18/93  #0135 CHANGE FOR BATCH SUBMISSION - UPDATE FOR SMS
//*  05/21/93  #0135 BATCH SUBMISSION UTILITY CHANGES
//*  02/16/94  0395 ADD FINDER FILE
//*  02/14/95  0779-ADD BATCH FINDER FILE PROCESSING
//*  02/24/05  NAH A/R REC TO 100 ZMOD MDUO-696M3P
//************************************************************
//*
//*-------------------------------------------------------------------*
//* RGAI-6B5HSV 04/05/2005 NAH ALCHEMIST MIGRATION                    *
//*-------------------------------------------------------------------*
//* CINL-6M4KAP 02/20/2006 KAK UPDATE FTX.JCLLIB STATEMENTS           *
//*-------------------------------------------------------------------*
//* TSCI-68QPLE FEB06Z OU5 FOREIGN CURRENCY CHANGES.                  *
//*-------------------------------------------------------------------*
//* DEC06 MSMH-6URHZK INFY FIX MSS DELIVERED BATCH JCL TO CONFORM     *
//*                        TO MSS AND CORPORATE STANDARDS             *
//*     DMA - USE PROC MSSLEFND INSTEAD OF LOADFIND WHICH IS OBSOLETE.*
//*-------------------------------------------------------------------*
//* AUG07 LMIA-4CNHT7    INFY FIX ADDED FAX/EMAIL STEPS               *
//*                                                                   *
//* FAXPARAM - THIS FILE IS ADDED TO PREAPARE DATA FOR FOR FAX/EMAIL. *
//* FAXDATA  - THIS FILE CONTAINS ACTUAL DATA TO BE FAXED (OR)        *
//*            EMAILED.                                               *
//* PRINTER3 - THIS IS A NEW REPORT LISTING ALL THE INVOICES THAT     *
//*            ARE TO BE FAXED OR EMAILED.                            *
//* S090SEND - IT IS THE NEW STEP ADDED TO EXECUTE THE PROC FOR       *
//*            FAX/EMAIL LOGIC.                                       *
//*-------------------------------------------------------------------*
//* DEC07  JLUG-76JJFY  COPY DOCS/REPORTS TO ONDEMAND  TP54236
//*-------------------------------------------------------------------*
//* JAN08  LMIA-4CNHT7  INFY REMOVED FORMDEF & PAGEDEF AND REPLACED   *
//*                          WITH FORMS=01S8 FOR PROD ISSUE: 1069     *
//*-------------------------------------------------------------------*
//*********************************************************************
//*JAN09 MKS-39833 TPB 01/06/2009 ENABLED FAXING AND EMAILING
//*********************************************************************
//* MKS 299683 - ADD ON-CALL DOCUMENTATION.  10/13/15; -MN54503-      *
//*********************************************************************
//* MKS 393043 - STOP PRINTING AP REPORTS TO THE PRINTER (VFORM007)   *
//*              AND SEND IT ONLY TO ON-DEMAND                        *
//*********************************************************************
//* MKS 394275 - COMMENT OUT ON DEMAND -Z992715-
//*********************************************************************
//* MKS 394884 - PRINT REPORTS TO ON-DEMAND
//*********************************************************************