
//VFOAAD01 JOB (2062AD01),
//             'BO REL-FIILL-PEND',
//             CLASS=U,
//             PRTY=5,
//             MSGCLASS=H,
//             MSGLEVEL=(1,1)
//*
/*ROUTE PRINT LOCAL
//*
//********************************************************************
//*DESC:     BO REL-FIILL-PEND
//*
//*UPDATES:  YES
//*
//*RUN FREQUENCY: DAILY
//*
//*RECOVERY: CORRECT PROBLEM, RERUN THE JOB.
//********************************************************************
//*
//SAR  OUTPUT CLASS=H,DEST=LOCAL
//PRNT OUTPUT CLASS=A,DEST=VFORM005
//*
//JOBLIB   DD  DISP=SHR,DSN=ALC.VFO.EMRG.LOADLIB
//         DD  DISP=SHR,DSN=ALC.VFO.PROD.LOADLIB
//         DD  DISP=SHR,DSN=ALC.MSS.EMRG.LOADLIB
//         DD  DISP=SHR,DSN=ALC.MSS.PROD.LOADLIB
//         DD  DISP=SHR,DSN=ALC.CIS.EMRG.LOADLIB
//         DD  DISP=SHR,DSN=ALC.CIS.PROD.LOADLIB
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
//*-------------------------------------------------------------------*
//* CHECK ORDERS TO SEE IF THEY SHOULD BE RELEASED                    *
//*-------------------------------------------------------------------*
//S010AD01 EXEC IMSDBB2,PROG=A220AD01,PSB=VFOPSB08,HLQ=VFO
//G.DUMMY  DD DUMMY
//VFOVERB  DD  DSN=VFO.VFOVERB.VERB.FILE.ONLKSDS,
//             DISP=SHR
//VFOEDIM  DD  DSN=VFO.VFOEDIM.EDI.CUSTOPT.ONLKSDS,
//             DISP=SHR
//****** OCT16  **** START *****
//OEDMFILE DD  DSN=VFO.VFOCIDMT.OE2DMART.ONLKSDS,
//             DISP=SHR
//****** OCT16  ***** END ******
//SYSIN    DD  DSN=&&DATE1,
//             DISP=(OLD,PASS)
//SYSUDUMP DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//*
//*---------------------------------------------------------------
//*        BUILD FOR FILLABLES
//*---------------------------------------------------------------
//SAA01    EXEC IMSDBB,PROG=A220AA01,PSB=VFOPSBYY,HLQ=VFO
//SYSIN    DD  DSN=&&DATE1,
//             DISP=(OLD,PASS)
//DISKOUT  DD  DSN=&&FDATA01,
//             DISP=(NEW,PASS)
//SYSOUT   DD  SYSOUT=*
//*
//*---------------------------------------------------------------
//*       VFO FILLABLES PROGRAM
//*---------------------------------------------------------------
//SAA02    EXEC IMSDBB,PROG=A220AA02,PSB=VFOPSB08,HLQ=VFO
//SYSIN    DD  DSN=&&DATE1,
//             DISP=(OLD,PASS)
//DISKIN   DD  DSN=&&FDATA01,
//             DISP=(OLD,PASS)
//VFOVERB  DD  DSN=VFO.VFOVERB.VERB.FILE.ONLKSDS,
//             DISP=SHR
//VFOSHPP  DD  DSN=VFO.VFOSHPP.SHIP.PICK.ONLKSDS,
//             DISP=SHR
//VFOCRSTA DD  DSN=VFO.VFOCRSTA.OE.CREDSTAT.ONLKSDS,
//             DISP=SHR
//ARMAST   DD  DSN=CORP.NAME.ADDR.FILE,
//             DISP=SHR
//UOMFILE  DD  DSN=VFO.VFOUOM.UOM.ONLKSDS,
//             DISP=SHR
//DISKOUT  DD  DSN=&&FDATA02,
//             DISP=(NEW,PASS)
//****** OCT16  **** START *****
//OEDMFILE DD  DSN=VFO.VFOCIDMT.OE2DMART.ONLKSDS,
//             DISP=SHR
//****** OCT16  ***** END ******
//SYSOUT   DD  SYSOUT=*
//*
//*---------------------------------------------------------------
//*     SORT TO INCLUDE FILLABLES AUDIT RECORDS - LOCATION ??
//*---------------------------------------------------------------
//SORT1    EXEC PGM=SORT
//SORTIN   DD  DSN=&&FDATA02,
//             DISP=(OLD,PASS)
//SORTOUT  DD  DSN=&&FDATA03,
//             DISP=(NEW,PASS)
//SYSOUT   DD  SYSOUT=*
//SYSIN    DD  *
 MERGE FIELDS=COPY
//* INCLUDE COND=(1,2,CH,EQ,C'??')
//*
//*---------------------------------------------------------------
//*     PRINT FILLABLES AUDIT TRAIL - LOCATION ??
//*---------------------------------------------------------------
//SAA03    EXEC PGM=A220AA03
//UOMFILE  DD  DSN=VFO.VFOUOM.UOM.ONLKSDS,
//             DISP=SHR
//SYSIN    DD  DSN=&&DATE1,
//             DISP=(OLD,PASS)
//DISKIN   DD  DSN=&&FDATA03,
//             DISP=(OLD,PASS)
//PRINT1   DD  SYSOUT=(,),OUTPUT=(*.SAR,*.PRNT)
//SYSOUT   DD  SYSOUT=*
//SYSDBOUT DD  SYSOUT=*
//*
//*-------------------------------------------------------------------*
//* BACKLOG PULL OFF                                                  *
//*-------------------------------------------------------------------*
//S020AI01 EXEC IMSDBB,PROG=A220AI01,PSB=VFOPSBRR,HLQ=VFO
//ARMAST   DD  DSN=CORP.NAME.ADDR.FILE,
//             DISP=SHR
//VFOVERB  DD  DSN=VFO.VFOVERB.VERB.FILE.ONLKSDS,
//             DISP=SHR
//UOMFILE  DD  DSN=VFO.VFOUOM.UOM.ONLKSDS,
//             DISP=SHR
//SYSIN    DD  DSN=&&DATE1,
//             DISP=(OLD,PASS)
//WORK1    DD  DSN=&&FDATA04,
//             DISP=(NEW,PASS),
//             LRECL=510,
//             SPACE=(510,(50,10),RLSE),AVGREC=K
//*
//*-------------------------------------------------------------------*
//* SORT  BY PART NUMBER AND MFG DIVISION                             *
//*-------------------------------------------------------------------*
//S030SORT EXEC PGM=SORT
//SORTIN   DD  DSN=&&FDATA04,
//             DISP=(OLD,DELETE,DELETE)
//SORTOUT  DD  DSN=&&FDATA05,
//             DISP=(NEW,PASS),
//             LRECL=510,
//             SPACE=(510,(50,10),RLSE),AVGREC=K
//SYSOUT   DD  SYSOUT=*
//SYSIN    DD  *
  SORT FORMAT=BI,WORK=1,FIELDS=(292,2,A,13,25,A)
//*
//*-------------------------------------------------------------------*
//* ADD PART DESC AND PROD CODE TO FILE                               *
//*-------------------------------------------------------------------*
//S040AI02 EXEC IMSDBB,PROG=A220AI02,PSB=VFOPSBRR,HLQ=VFO
//WORK1    DD  DSN=&&FDATA05,
//             DISP=(OLD,PASS)
//*
//*-------------------------------------------------------------------*
//* SORT BY PART, ORDER & SEQ                                         *
//*-------------------------------------------------------------------*
//S050SORT EXEC PGM=SORT
//SORTIN   DD  DSN=&&FDATA05,
//             DISP=(OLD,PASS,DELETE)
//SORTOUT  DD  DSN=&&FDATA06,
//             DISP=(NEW,PASS),
//             LRECL=510,
//             SPACE=(510,(50,10),RLSE),AVGREC=K
//SYSOUT   DD  SYSOUT=*
//SYSIN    DD  *
  SORT FORMAT=BI,WORK=1,FIELDS=(13,25,A,3,6,A,9,4,A)
//*
//*-------------------------------------------------------------------*
//* ALLOC NOT PRINTED                                                 *
//*-------------------------------------------------------------------*
//S060AI50 EXEC IMSDBB2,PROG=MSSZAI50,PSB=VFOPSBRR,HLQ=VFO
//G.UOMFILE  DD  DSN=VFO.VFOUOM.UOM.ONLKSDS,DISP=SHR
//G.RATES    DD  DSN=CIS.CISFCUR.EXCHANGE.ONLKSDS,DISP=SHR
//G.SYSUDUMP DD  SYSOUT=*
//G.SYSOUT   DD  SYSOUT=*
//G.SYS012   DD  SYSOUT=(,),OUTPUT=(*.SAR,*.PRNT)
//G.SORTIO   DD  DSN=&&FDATA06,DISP=(OLD,DELETE)
//*
//*-------------------------------------------------------------------*
//* OMIT PROCESSING DIVISION'S PENDING RECORDS                        *
//*-------------------------------------------------------------------*
//S070AI62 EXEC PGM=A220AI62
//VFOPEND  DD  DSN=VFO.VFOPEND.OE.PENDPART.ONLKSDS,
//             DISP=SHR
//SYSOUT   DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//SYSABOUT DD  SYSOUT=*
//SYSDBOUT DD  SYSOUT=*
//SYSIN    DD  DSN=&&DATE1,
//             DISP=(OLD,PASS)
//*
//*-------------------------------------------------------------------*
//* SORT BY PART, PRIORITY, PROM DATE, ORDER & SEQ                    *
//* 0002 - TWU - YEAR 2000 CHANGES                                    *
//*-------------------------------------------------------------------*
//S080SORT EXEC PGM=SORT
//SORTIN   DD  DSN=&&FDATA05,
//             DISP=(OLD,PASS,DELETE)
//SORTOUT  DD  DSN=&&FDATA07,
//             DISP=(NEW,PASS),
//             LRECL=510,
//             SPACE=(510,(50,10),RLSE),AVGREC=K
//SYSOUT   DD  SYSOUT=*
//SYSIN    DD  *
  SORT WORK=1,FIELDS=(13,25,BI,A,252,1,BI,A,291,1,BI,A,320,2,Y2C,A,    X
               322,2,BI,A,324,2,BI,A,1,8,BI,A,9,4,BI,A)
//*
//*-------------------------------------------------------------------*
//* BACKORDER PENDING REPORT                                          *
//*-------------------------------------------------------------------*
//S090AI60 EXEC PGM=A220AI60
//SORTIO   DD  DSN=&&FDATA07,
//             DISP=(OLD,DELETE)
//VFOPEND  DD  DSN=VFO.VFOPEND.OE.PENDPART.ONLKSDS,
//             DISP=SHR
//SYS012   DD  SYSOUT=(,),OUTPUT=(*.SAR)
//SYSABOUT DD  SYSOUT=*
//SYSDBOUT DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//*
//*-------------------------------------------------------------------*
//* SORT BY CUST, PRIORITY, PROM DATE, ORDER & SEQ                    *
//* 0002 - TWU - YEAR 2000 CHANGES                                    *
//*-------------------------------------------------------------------*
//S100SORT EXEC PGM=SORT
//SORTIN   DD  DSN=&&FDATA05,
//             DISP=(OLD,PASS,DELETE)
//SORTOUT  DD  DSN=&&FDATA08,
//             DISP=(NEW,PASS),
//             LRECL=510,
//             SPACE=(510,(50,10),RLSE),AVGREC=K
//SYSOUT   DD  SYSOUT=*
//SYSIN    DD  *
  SORT WORK=1,FIELDS=(84,10,BI,A,252,1,BI,A,291,1,BI,A,320,2,Y2C,A,    X
               322,2,BI,A,324,2,BI,A,1,8,BI,A,9,4,BI,A)
//*
//*-------------------------------------------------------------------*
//* BACKORDER PENDING REPORT BY CUSTOMER                              *
//*-------------------------------------------------------------------*
//S110AI65 EXEC PGM=A220AI65
//SORTIO   DD  DSN=&&FDATA08,
//             DISP=(OLD,DELETE)
//SYSIN    DD  DSN=&&DATE1,
//             DISP=(OLD,PASS)
//SYS012   DD  SYSOUT=(,),OUTPUT=(*.PRNT)
//SYSABOUT DD  SYSOUT=*
//SYSDBOUT DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//
//************************************************************
//* TITLE: JCLU-BACKORDERS RELEASE
//* CREATED IN LIBRFILE: 07/12/89
//*
//*  HISTORY RECORDS FOR THIS MODULE:
//*  09/04/90 COPIED FROM WORK LIBRFILE: EXPANDED MODULE 09-04-90 RTG
//*                     00022
//*           COPIED FROM WORK LIBRFILE: EXPANDED MODULE 05-02-90 RTG
//*                     00022
//*  03/02/92  ADD FILLABLES JCL
//*  06/22/92 ADDED ARCHIVING TO ALL MODULES:  06-22-92 RTG
//*                   00000024
//*  05/21/93  #0135 BATCH SUBMISSION UTILITY CHANGES
//*  10/21/94  0462 10/21/94 ADDED CREDIT CHECK PROCESSING LOGIC -- TBT
//*  01/04/96  ADDED UOMFILE TO JOBSTEPS WITH UOM CONVERSION
//*  10/22/97  TWU - YEAR 2000 CHANGES
//*  11/24/04 CXG- EDI862 PROJECT CHANGES
//*  04/05/05 RGAI-6B5HMG NAH ALCHEMIST MIGRATION
//*  05/22/05 THOG-5WRQ9T SRN UOM FIELD EXPANDED FROM 2 TO 4 DECIMALS
//*  10/19/05 RGAI-6B5HMG NAH ALCHEMIST MIGRATION - FINAL CHANGES
//*-------------------------------------------------------------------*
//* TSCI-68QPLE FEB06Z OU5 FOREIGN CURRENCY CHANGES.                  *
//*-------------------------------------------------------------------*
//* DEC06 MSMH-6URHZK INFY FIX MSS DELIVERED BATCH JCL TO CONFORM     *
//*                        TO MSS AND CORPORATE STANDARDS             *
//*-------------------------------------------------------------------*
//* DEC07 RGAI-6U2N8F INFY CHANGED PROGRAM REFERENCES FROM MSSZAI01 & *
//*                        MSSZAI02 TO MSSXAI01 AND MSSXAI02          *
//*                        RESPECTIVELY.                              *
//*********************************************************************
//*-------------------------------------------------------------------*
//* NOV08 RGAI-6U2N8F INFY  MSS STANDARDIZATION TASKS                 *
//*-------------------------------------------------------------------*
//*********************************************************************
//*-------------------------------------------------------------------*
//* OCT16 SS  MKS#384564 - CREATE EXTRACT FOR OE TO DATA MART         *
//*-------------------------------------------------------------------*
//* MAR18 SS  MKS#385450 - CHANGED PROGRAM TO MSSZAI50.               *
//*-------------------------------------------------------------------*