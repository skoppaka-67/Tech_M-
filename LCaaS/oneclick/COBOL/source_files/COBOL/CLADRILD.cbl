000100 IDENTIFICATION DIVISION.                                          
000200 PROGRAM-ID.    CLADRILD.                                          
000300 AUTHOR.        AMBICA                                             
000400 DATE-WRITTEN.  08/2010.                                           
000500                                                                   
000600****************************************************************** 
000700****************************************************************** 
000800*                                                                * 
000801*                   C  L  C  S  L  D  L  D                       * 
000802*                                                                * 
001030*  This program pulls all Address   merged into the BNSF master  * 
001040*  and sends them to the subprogram CLCSLALM to look for an      * 
001050*  existing location to merge it with.  This can be run regularly* 
001060*  to look for potential merges as new address are   created.    * 
001070*  An output report is created to show counts and results.       * 
001080*                                                                * 
001100****************************************************************** 
001110****************************************************************** 
001300                                                                   
001400 ENVIRONMENT DIVISION.                                             
001500 CONFIGURATION SECTION.                                            
001600 SOURCE-COMPUTER.          IBM-370.                                
001601 OBJECT-COMPUTER.          IBM-370.                                
001602 SPECIAL-NAMES.                                                    
001603 INPUT-OUTPUT SECTION.                                             
001604 FILE-CONTROL.                                                     
001605                                                                   
001607     SELECT OUTPUT-REPORT ASSIGN TO UT-S-REPORT.                   
001609                                                                   
001610 DATA DIVISION.                                                    
001611 FILE SECTION.                                                     
001612                                                                   
001630 FD  OUTPUT-REPORT                                                 
001631     RECORDING MODE IS F                                           
001632     RECORD CONTAINS 300 CHARACTERS                                
001633     LABEL RECORDS ARE STANDARD                                    
001634     BLOCK CONTAINS 0 RECORDS.                                     
001635                                                                   
001636 01  OUTPUT-REPORT-REC                PIC  X(300).                 
001637                                                                   
001638****************************************************************** 
001639****************************************************************** 
001640*                 W O R K I N G   S T O R A G E                  * 
001641****************************************************************** 
001642****************************************************************** 
001650                                                                   
001700 WORKING-STORAGE SECTION.                                          
001800                                                                   
011500 01 WE-EYE-CATCHER                    PIC  X(80) VALUE             
011600        'WORKING STORAGE FOR CLADRILD BEGINS HERE'.                
011700                                                                   
011701 01 WORKING-VARIABLES.                                             
011708    05 W-TIMESTAMP                    PIC  X(26) VALUE SPACES.     
011709    05 W-PROGRAM                      PIC  X(08) VALUE 'CLADRILD'. 
011710    05 W-CLCSLALM                     PIC  X(08) VALUE 'CLCSLALM'. 
011712    05 W-EOF                          PIC  X(01) VALUE 'N'.        
011713    05 W-COUNT                        PIC S9(06) COMP VALUE 0.     
011728    05 W-NULL-ULT-PARENT              PIC S9(04) COMP.             
011729    05 W-NULL-IMM-PARENT              PIC S9(04) COMP.             
011730                                                                   
011731 01 WORKING-COUNTERS.                                              
011732    05 W-PROCESSED-CNT                PIC  9(06) VALUE 0.          
011733    05 W-PROCESSED-CNT-D              PIC  ZZZ,ZZ9.                
011740    05 W-LOC-FOUND-CNT                PIC  9(06) VALUE 0.          
011741    05 W-LOC-FOUND-CNT-D              PIC  ZZZ,ZZ9.                
011742    05 W-LOC-NOT-FOUND-CNT            PIC  9(06) VALUE 0.          
011743    05 W-LOC-NOT-FOUND-CNT-D          PIC  ZZZ,ZZ9.                
011744    05 W-LOC-MERGED-CNT               PIC  9(06) VALUE 0.          
011745    05 W-LOC-MERGED-CNT-D             PIC  ZZZ,ZZ9.                
011746                                                                   
011747    05 W-ERRORS-CNT                   PIC  9(06) VALUE 0.          
011748    05 W-ERRORS-CNT-D                 PIC  ZZZ,ZZ9.                
011749    05 W-DB2-CONNECT                  PIC  9(06) VALUE 0.          
011750    05 W-DB2-CONNECT-D                PIC  ZZZ,ZZ9.                
011751    05 W-NO-CANDIDATE-FOUND           PIC  9(06) VALUE 0.          
011752    05 W-NO-CANDIDATE-FOUND-D         PIC  ZZZ,ZZ9.                
011753    05 W-ADR-ALREADY-EXISTS           PIC  9(06) VALUE 0.          
011754    05 W-ADR-ALREADY-EXISTS-D         PIC  ZZZ,ZZ9.                
011755    05 W-ADR-NOT-FOUND                PIC  9(06) VALUE 0.          
011756    05 W-ADR-NOT-FOUND-D              PIC  ZZZ,ZZ9.                
011757    05 W-PARENT-LOC-MISSING           PIC  9(06) VALUE 0.          
011758    05 W-PARENT-LOC-MISSING-D         PIC  ZZZ,ZZ9.                
011759    05 W-EXPIRE-VERSION               PIC  9(06) VALUE 0.          
011760    05 W-EXPIRE-VERSION-D             PIC  ZZZ,ZZ9.                
011761    05 W-LOOKUP-PARENT-CIF            PIC  9(06) VALUE 0.          
011762    05 W-LOOKUP-PARENT-CIF-D          PIC  ZZZ,ZZ9.                
011763    05 W-INSERT-MERGED-VRSN           PIC  9(06) VALUE 0.          
011764    05 W-INSERT-MERGED-VRSN-D         PIC  ZZZ,ZZ9.                
011766    05 W-ADDR-ADD-FAILURE             PIC  9(06) VALUE 0.          
011767    05 W-ADDR-ADD-FAILURE-D           PIC  ZZZ,ZZ9.                
011768                                                                   
011769 01 SUBLOCATION-VARIABLES.                                         
011770    05 W-CIF-ID                       PIC  X(09) VALUE SPACES.     
011780    05 W-CIF-SUB-LOCN-SFX-C           PIC  X(04) VALUE SPACES.     
011790                                                                   
011853****************************************************************** 
011854* SQL ERROR HANDLING VARIABLES                                   * 
011855****************************************************************** 
011856                                                                   
011857 01 ERROR-CODE.                                                    
011858    05 WD-SQL-CODE                    PIC  9(09) VALUE ZERO.       
011859    05 WD-ABEND-CODE                  PIC  9(04) VALUE ZERO.       
011860    05 WD-ERROR-MSG                   PIC  X(80) VALUE SPACES.     
011861    05 WD-RETURN-CODE                 PIC ---------9.              
011862    05 WD-DISPLAY-CODE REDEFINES                                   
011863       WD-RETURN-CODE                 PIC  X(10).                  
011864    05 WD-DB2-RETURN                  PIC S9(09) COMP VALUE +0.    
011865       88 DB2-OK                          VALUE   +0.              
011866       88 DB2-ERROR                       VALUE -999 THRU   -1     
011867                                                  +1 THRU  +99     
011868                                                +101 THRU +999.    
011869    05 DSNTIAR                        PIC  X(08) VALUE 'DSNTIAR'.  
011870    05 DSNTIAR-AREA.                                               
011871       10 DSNTIAR-ERROR-LEN           PIC S9(04) COMP VALUE +960.  
011872       10 DSNTIAR-ERROR-TEXT                                       
011873                     OCCURS 8 TIMES   PIC  X(120).                 
011874    05 DSNTIAR-ERROR-TEXT-LEN         PIC S9(09) COMP VALUE +120.  
011875                                                                   
011876 01 MESSAGES.                                                      
011877    05 WM-DB2-BAD-MESSAGE.                                         
011878       10 FILLER                      PIC  X(20) VALUE             
011879                                          'DB2 ACCESS ERROR ON '.  
011880       10 DB2-ACTION                  PIC  X(08).                  
011881       10 FILLER                      PIC  X(03) VALUE 'OF '.      
011882       10 DB2-TABLE                   PIC  X(25).                  
011884                                                                   
011890****************************************************************** 
011900*  COPY VARIABLES                                                * 
012000****************************************************************** 
012110                                                                   
012111 COPY CLFM060B.                                                    
                                                                         
000010 01  CLF0060M-PARMS.                                               
000020                                                                   
000030     05  CLM-CLF0060-FUNCTION PIC X(10).                           
000040         88 CLM-CLF0060-ADD VALUE 'ADD'.                           
000041         88 CLM-CLF0060-CHANGE VALUE 'CHANGE'.                     
000042         88 CLM-CLF0060-EXPIRE VALUE 'EXPIRE'.                     
000043         88 CLM-CLF0060-DELETE VALUE 'DELETE'.                     
000044         88 CLM-CLF0060-UNEXPIRE VALUE 'UNEXPIRE'.                 
000045         88 CLM-CLF0060-INQUIRY VALUE 'INQUIRY'.                   
000060                                                                   
000070     05  CLM-CLF0060-LOC-ID    PIC S9(9) COMP.                     
000080     05  CLM-CLF0060-EFF-TS    PIC X(26).                          
000091                                                                   
000093     05  CLM-CLF0060-STATUS    PIC X(15).                          
000094         88  CLF0060-STATUS-SUCCESSFUL VALUE 'SUCCESSFUL'.         
000095         88  CLF0060-STATUS-FAILED     VALUE 'FAILED'.             
000096     05  CLM-CLF0060-MESSAGE   PIC X(80).                          
000097     05  CLM-CLF0060-DB2-SQLCODE PIC S9(4) COMP.                   
000098     05  CLM-CLF0060-DB2-REASON-CD PIC X(8).                       
000100     05  CLM-CLF0060-REC.                                          
006600         10 LOC-ID               PIC S9(9) USAGE COMP.             
006700         10 CO-LOCN-EFF-TS       PIC X(26).                        
006800         10 ULT-PRNT-CO-LOCN-N   PIC S9(9) USAGE COMP.             
006900         10 IMD-PRNT-CO-LOCN-N   PIC S9(9) USAGE COMP.             
007000         10 NMFTA-SPL-C          PIC X(9).                         
007100         10 NMFTA-SPL-SFX-C      PIC X(3).                         
007200         10 EXP-TS               PIC X(26).                        
007300         10 LST-MAINT-TS         PIC X(26).                        
007400         10 LST-MAINT-USER-ID    PIC X(8).                         
007500         10 LOC-NM               PIC X(90).                        
007600         10 MAILING-ADV-BAR-C    PIC X(2).                         
007700         10 MAILING-CHK-DIGIT    PIC X(1).                         
007800         10 BOL-FAX-BK-N         PIC X(12).                        
007900         10 BOL-FAX-CNFRM-TXT    PIC X(40).                        
008000         10 BOL-FAX-CNFRM-C      PIC X(1).                         
008100         10 BOL-RELS-C           PIC X(1).                         
008200         10 BL-WC-EDI-IND        PIC X(1).                         
008300         10 RLINC-CUST-EDI-ID    PIC X(4).                         
008400         10 DIALIN-CUST-EDI-ID   PIC X(12).                        
008500         10 CORP-TP-C            PIC X(2).                         
008600         10 INFO-SRC-C           PIC X(2).                         
008700         10 MAINT-RSN-C          PIC X(2).                         
008800         10 PHYS-SRVC-C          PIC X(1).                         
008900         10 BS-STAT-C            PIC X(2).                         
009000         10 COMMENTS             PIC X(45).                        
009100         10 CO-ID                PIC S9(9) USAGE COMP.             
009200         10 CUST-633-ID          PIC X(12).                        
009300         10 CUST-CITY-333-C      PIC X(9).                         
009400         10 CUST-ST-C            PIC X(2).                         
009500         10 TRAFF-ACCT-N         PIC X(11).                        
009600         10 MAILING-CNTRY-C      PIC X(3).                         
009700         10 MAILING-ST-PRVNC-C   PIC X(2).                         
009800         10 MAILING-CNTY-NM      PIC X(30).                        
009900         10 MAILING-CITY         PIC X(30).                        
010000         10 MAILING-POSTAL-C     PIC X(9).                         
010100         10 MAILING-ADDR-1       PIC X(35).                        
010200         10 MAILING-ADDR-2       PIC X(35).                        
010300         10 MAILING-ADDR-3       PIC X(35).                        
010400         10 PHYS-CNTRY-C         PIC X(3).                         
010500         10 PHYS-ST-PRVNC-C      PIC X(2).                         
010600         10 PHYS-CNTY-NM         PIC X(30).                        
010700         10 PHYS-CITY            PIC X(30).                        
010800         10 PHYS-POSTAL-C        PIC X(9).                         
010900         10 PHYS-ADDR-1          PIC X(35).                        
011000         10 PHYS-ADDR-2          PIC X(35).                        
011100         10 PHYS-ADDR-3          PIC X(35).                        
011200         10 CIF-ID               PIC X(9).                         
011300         10 CIF-ID-TP-C          PIC X(1).                         
011400         10 MRGR-CIF-N           PIC X(9).                         
011500         10 TEMP-PERM-C          PIC X(2).                         
011600         10 CIF-ULT-PRNT-N       PIC X(9).                         
011700         10 CIF-IMD-PRNT-N       PIC X(9).                         
011800         10 ARI-LST-MAINT-DT     PIC X(10).                        
011900         10 ARI-EFF-DT           PIC X(10).                        
012000         10 ARI-EXP-DT           PIC X(10).                        
CM1189         10 NLOC-LOC-ID          PIC S9(9) USAGE COMP.             
CM1189         10 NLOC-CIF-ID          PIC X(9).                         
CM1288         10 CIF-DOM-PRNT-N       PIC X(9).                         
CM1288         10 CIF-TAX-ID-QLF       PIC X(2).                         
CM1288         10 CIF-TAX-ID.                                            
CM1288            49 CIF-TAX-ID-LEN    PIC S9(4) USAGE COMP.             
CM1288            49 CIF-TAX-ID-TEXT   PIC X(50).                        
CM1288         10 CIF-MAIL-POSTC       PIC X(11).                        
CM1288         10 CIF-PHYS-POSTC       PIC X(11).                        
CM1375         10 CIF-CMNT             PIC X(30).                        
CM1419         10 DBA-NME-CD           PIC X(1).                         
CM1419         10 BILL-ADDR-CD         PIC X(1).                         
CM1419         10 DELY-ADDR-CD         PIC X(1).                         
               10 CIF-SUB-CD           PIC X(4).                         
CM1189         10 NLOC-CIF-SUB-CD      PIC X(4).                         
                                                                         
012113 COPY CLF0060B.                                                    
                                                                         
000100****************************************************************** 
000200* COBOL DECLARATION FOR TABLE CL.TCLF_CO_LOCN_DTL                * 
000300****************************************************************** 
000400 01  CLF0060C-REC.                                                 
000500     10 LOC-ID               PIC S9(9) USAGE COMP.                 
000600     10 CO-LOCN-EFF-TS       PIC X(26).                            
000700     10 ULT-PRNT-CO-LOCN-N   PIC S9(9) USAGE COMP.                 
000800     10 IMD-PRNT-CO-LOCN-N   PIC S9(9) USAGE COMP.                 
000900     10 NMFTA-SPL-C          PIC X(9).                             
001000     10 NMFTA-SPL-SFX-C      PIC X(3).                             
001100     10 EXP-TS               PIC X(26).                            
001200     10 LST-MAINT-TS         PIC X(26).                            
001300     10 LST-MAINT-USER-ID    PIC X(8).                             
001400     10 LOC-NM               PIC X(90).                            
001500     10 MAILING-ADV-BAR-C    PIC X(2).                             
001600     10 MAILING-CHK-DIGIT    PIC X(1).                             
001700     10 BOL-FAX-BK-N         PIC X(12).                            
001800     10 BOL-FAX-CNFRM-TXT    PIC X(40).                            
001900     10 BOL-FAX-CNFRM-C      PIC X(1).                             
002000     10 BOL-RELS-C           PIC X(1).                             
002100     10 BL-WC-EDI-IND        PIC X(1).                             
002200     10 RLINC-CUST-EDI-ID    PIC X(4).                             
002300     10 DIALIN-CUST-EDI-ID   PIC X(12).                            
002400     10 CORP-TP-C            PIC X(2).                             
002500     10 INFO-SRC-C           PIC X(2).                             
002600     10 MAINT-RSN-C          PIC X(2).                             
002700     10 PHYS-SRVC-C          PIC X(1).                             
002800     10 BS-STAT-C            PIC X(2).                             
002900     10 COMMENTS             PIC X(45).                            
003000     10 CO-ID                PIC S9(9) USAGE COMP.                 
003100     10 CUST-633-ID          PIC X(12).                            
003200     10 CUST-CITY-333-C      PIC X(9).                             
003300     10 CUST-ST-C            PIC X(2).                             
003400     10 TRAFF-ACCT-N         PIC X(11).                            
003500     10 MAILING-CNTRY-C      PIC X(3).                             
003600     10 MAILING-ST-PRVNC-C   PIC X(2).                             
003700     10 MAILING-CNTY-NM      PIC X(30).                            
003800     10 MAILING-CITY         PIC X(30).                            
003900     10 MAILING-POSTAL-C     PIC X(9).                             
004000     10 MAILING-ADDR-1       PIC X(35).                            
004100     10 MAILING-ADDR-2       PIC X(35).                            
004200     10 MAILING-ADDR-3       PIC X(35).                            
004300     10 PHYS-CNTRY-C         PIC X(3).                             
004400     10 PHYS-ST-PRVNC-C      PIC X(2).                             
004500     10 PHYS-CNTY-NM         PIC X(30).                            
004600     10 PHYS-CITY            PIC X(30).                            
004700     10 PHYS-POSTAL-C        PIC X(9).                             
004800     10 PHYS-ADDR-1          PIC X(35).                            
004900     10 PHYS-ADDR-2          PIC X(35).                            
005000     10 PHYS-ADDR-3          PIC X(35).                            
005100     10 CIF-ID               PIC X(9).                             
005200     10 CIF-ID-TP-C          PIC X(1).                             
005300     10 MRGR-CIF-N           PIC X(9).                             
005400     10 TEMP-PERM-C          PIC X(2).                             
005500     10 CIF-ULT-PRNT-N       PIC X(9).                             
005600     10 CIF-IMD-PRNT-N       PIC X(9).                             
005700     10 ARI-LST-MAINT-DT     PIC X(10).                            
005800     10 ARI-EFF-DT           PIC X(10).                            
005900     10 ARI-EXP-DT           PIC X(10).                            
006000     10 NLOC-LOC-ID          PIC S9(9) USAGE COMP.                 
006100     10 NLOC-CIF-ID          PIC X(9).                             
006200     10 CIF-DOM-PRNT-N       PIC X(9).                             
006300     10 CIF-TAX-ID-QLF       PIC X(2).                             
006400     10 CIF-TAX-ID.                                                
006500        49 CIF-TAX-ID-LEN    PIC S9(4) USAGE COMP.                 
006600        49 CIF-TAX-ID-TEXT   PIC X(50).                            
006700     10 CIF-MAIL-POSTC       PIC X(11).                            
006800     10 CIF-PHYS-POSTC       PIC X(11).                            
006900     10 CIF-CMNT             PIC X(30).                            
007000     10 DBA-NME-CD           PIC X(01).                            
007100     10 BILL-ADDR-CD         PIC X(01).                            
007200     10 DELY-ADDR-CD         PIC X(01).                            
007210     10 CIF-SUB-CD           PIC X(04).                            
007210     10 NLOC-CIF-SUB-CD      PIC X(04).                            
007300****************************************************************** 
007400* THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 62      * 
007500****************************************************************** 
007600 01  CLF0060C-REC-DIFFERENCES PIC X(2000).                         
                                                                         
012114 COPY CLCSLALB.                                                    
                                                                         
000100****************************************************************** 
000200*                                                                * 
000300* LINKAGE VARIABLES FOR SUBPROGRAM CLCSLALM                      * 
000400*                                                                * 
000500* CL - Customer                                                  * 
000600* C  - CIF                                                       * 
000700* SL - Sublocation                                               * 
000800* D  - Dummy                                                     * 
000900* L  - Load                                                      * 
001000* B  - We Use B For Copybooks                                    * 
001100*                                                                * 
001200****************************************************************** 
001300                                                                   
001400 01 CLCSLALM-PARMS.                                                
001500    05 INPUT-TO-CLCSLALM.                                          
001600       10 CLCSLALM-CIF-ID              PIC  X(09) VALUE SPACES.    
001700       10 CLCSLALM-CIF-SUB-LOCN-SFX-C  PIC  X(04) VALUE SPACES.    
001800                                                                   
001900    05 RETURN-FROM-CLCSLALM.                                       
002000       10 CLCSLALM-MERGE-LOC-ID        PIC S9(09) USAGE COMP.      
002100       10 CLCSLALM-MERGE-CO-ID         PIC S9(09) USAGE COMP.      
002200       10 CLCSLALM-LOC-NME             PIC  X(90) VALUE SPACES.    
002300       10 CLCSLALM-CUST-633-ID         PIC  X(12) VALUE SPACES.    
002400       10 CLCSLALM-CUST-CITY-333-C     PIC  X(09) VALUE SPACES.    
002500       10 CLCSLALM-CUST-ST-C           PIC  X(02) VALUE SPACES.    
002510       10 CLCSLALM-ADDR-1             PIC X(35).                   
002520       10 CLCSLALM-ADDR-2             PIC X(35).                   
002530       10 CLCSLALM-ADDR-3             PIC X(35).                   
002540       10 CLCSLALM-ADDR-CITY          PIC X(30).                   
002550       10 CLCSLALM-ADDR-ST-PRVNC-C    PIC X(30).                   
002560       10 CLCSLALM-ADDR-CNTRY-C       PIC X(03).                   
002570       10 CLCSLALM-ADDR-CNTY-NM       PIC X(30).                   
002580       10 CLCSLALM-ADDR-POSTAL-C      PIC X(11).                   
002600       10 CLCSLALM-LOC-FOUND           PIC  X(01) VALUE SPACES.    
002700                                                                   
002800                                                                   
002900       10 CLCSLALM-STATUS              PIC  X(01).                 
003000          88 CLCSLALM-SUCCESSFUL                  VALUE '1'.       
003100          88 CLCSLALM-ERROR                       VALUE '2'.       
003200                                                                   
003300                                                                   
003400       10 ERROR-CODES                  PIC  X(02).                 
003500          88 CLCSLALM-DB2-CONNECT                 VALUE '1'.       
003600          88 CLCSLALM-ADR-NOT-FOUND               VALUE '2'.       
003700          88 CLCSLALM-NO-CANDIDATE-FOUND          VALUE '4'.       
003800          88 CLCSLALM-PARENT-LOC-MISSING          VALUE '4'.       
003900          88 CLCSLALM-EXPIRE-VERSION              VALUE '5'.       
004000          88 CLCSLALM-LOOKUP-PARENT-CIF           VALUE '6'.       
004100          88 CLCSLALM-INSERT-MERGED-VRSN          VALUE '7'.       
004200          88 CLCSLALM-ADDR-ADD-FAILURE            VALUE '8'.       
004300          88 CLCSLALM-ADR-ALREADY-EXISTS          VALUE '9'.       
004400                                                                   
004500       10 CLCSLALM-SQLCODE             PIC  9(09) VALUE ZERO.      
004600       10 CLCSLALM-ERROR-MESSAGE       PIC  X(50) VALUE SPACES.    
004700                                                                   
                                                                         
012115                                                                   
012116****************************************************************** 
012117*  DCLGENS                                                       * 
012118****************************************************************** 
012119                                                                   
012120     EXEC SQL                                                      
012130        INCLUDE CLF0060                                            
012140     END-EXEC.                                                     
                                                                         
      ****************************************************************** 
      * DCLGEN TABLE(CL.TCLF_CO_LOCN_DTL)                              * 
      *        LIBRARY(PLX1.WORK.BNSF.DCLGENS(CLF0060))                * 
      *        ACTION(REPLACE)                                         * 
      *        LANGUAGE(COBOL)                                         * 
      *        APOST                                                   * 
      *        DBCSDELIM(NO)                                           * 
      * ....IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING STATEMENTS   * 
      ****************************************************************** 
           EXEC SQL DECLARE CL.TCLF_CO_LOCN_DTL TABLE                    
           ( LOC_ID                         INTEGER NOT NULL,            
             CO_LOCN_EFF_TS                 TIMESTAMP NOT NULL,          
             ULT_PRNT_CO_LOCN_N             INTEGER,                     
             IMD_PRNT_CO_LOCN_N             INTEGER,                     
             NMFTA_SPL_C                    CHAR(09) NOT NULL,           
             NMFTA_SPL_SFX_C                CHAR(03) NOT NULL,           
             EXP_TS                         TIMESTAMP NOT NULL,          
             LST_MAINT_TS                   TIMESTAMP NOT NULL,          
             LST_MAINT_USER_ID              CHAR(08) NOT NULL,           
             LOC_NM                         CHAR(90) NOT NULL,           
             MAILING_ADV_BAR_C              CHAR(02) NOT NULL,           
             MAILING_CHK_DIGIT              CHAR(01) NOT NULL,           
             BOL_FAX_BK_N                   CHAR(12) NOT NULL,           
             BOL_FAX_CNFRM_TXT              CHAR(40) NOT NULL,           
             BOL_FAX_CNFRM_C                CHAR(01) NOT NULL,           
             BOL_RELS_C                     CHAR(01) NOT NULL,           
             BL_WC_EDI_IND                  CHAR(01) NOT NULL,           
             RLINC_CUST_EDI_ID              CHAR(04) NOT NULL,           
             DIALIN_CUST_EDI_ID             CHAR(12) NOT NULL,           
             CORP_TP_C                      CHAR(02) NOT NULL,           
             INFO_SRC_C                     CHAR(02) NOT NULL,           
             MAINT_RSN_C                    CHAR(02) NOT NULL,           
             PHYS_SRVC_C                    CHAR(01) NOT NULL,           
             BS_STAT_C                      CHAR(02) NOT NULL,           
             COMMENTS                       CHAR(45) NOT NULL,           
             CO_ID                          INTEGER NOT NULL,            
             CUST_633_ID                    CHAR(12) NOT NULL,           
             CUST_CITY_333_C                CHAR(09) NOT NULL,           
             CUST_ST_C                      CHAR(02) NOT NULL,           
             TRAFF_ACCT_N                   CHAR(11) NOT NULL,           
             MAILING_CNTRY_C                CHAR(03) NOT NULL,           
             MAILING_ST_PRVNC_C             CHAR(02) NOT NULL,           
             MAILING_CNTY_NM                CHAR(30) NOT NULL,           
             MAILING_CITY                   CHAR(30) NOT NULL,           
             MAILING_POSTAL_C               CHAR(09) NOT NULL,           
             MAILING_ADDR_1                 CHAR(35) NOT NULL,           
             MAILING_ADDR_2                 CHAR(35) NOT NULL,           
             MAILING_ADDR_3                 CHAR(35) NOT NULL,           
             PHYS_CNTRY_C                   CHAR(03) NOT NULL,           
             PHYS_ST_PRVNC_C                CHAR(02) NOT NULL,           
             PHYS_CNTY_NM                   CHAR(30) NOT NULL,           
             PHYS_CITY                      CHAR(30) NOT NULL,           
             PHYS_POSTAL_C                  CHAR(09) NOT NULL,           
             PHYS_ADDR_1                    CHAR(35) NOT NULL,           
             PHYS_ADDR_2                    CHAR(35) NOT NULL,           
             PHYS_ADDR_3                    CHAR(35) NOT NULL,           
             CIF_ID                         CHAR(09) NOT NULL,           
             CIF_ID_TP_C                    CHAR(01) NOT NULL,           
             MRGR_CIF_N                     CHAR(09) NOT NULL,           
             TEMP_PERM_C                    CHAR(02) NOT NULL,           
             CIF_ULT_PRNT_N                 CHAR(09) NOT NULL,           
             CIF_IMD_PRNT_N                 CHAR(09) NOT NULL,           
             ARI_LST_MAINT_DT               DATE NOT NULL,               
             ARI_EFF_DT                     DATE NOT NULL,               
             ARI_EXP_DT                     DATE NOT NULL,               
             NLOC_LOC_ID                    INTEGER NOT NULL,            
CM1288       NLOC_CIF_ID                    CHAR(09) NOT NULL,           
CM1288       CIF_DOM_PRNT_N                 CHAR(09) NOT NULL,           
CM1288       CIF_TAX_ID_QLF                 CHAR(02) NOT NULL,           
CM1288       CIF_TAX_ID                     VARCHAR(50) NOT NULL,        
CM1288       CIF_MAIL_POSTC                 CHAR(11) NOT NULL,           
CM1288       CIF_PHYS_POSTC                 CHAR(11) NOT NULL,           
CM1375       CIF_CMNT                       CHAR(30) NOT NULL,           
CM1419       DBA_NME_CD                     CHAR(01) NOT NULL,           
CM1419       BILL_ADDR_CD                   CHAR(01) NOT NULL,           
CM1419       DELY_ADDR_CD                   CHAR(01) NOT NULL,           
             CIF_SUB_CD                     CHAR(04) NOT NULL,           
             NLOC_CIF_SUB_CD                CHAR(04) NOT NULL            
           ) END-EXEC.                                                   
      ****************************************************************** 
      * COBOL DECLARATION FOR TABLE CL.TCLF_CO_LOCN_DTL                * 
      ****************************************************************** 
       01  CLF0060-REC.                                                  
           10 LOC-ID               PIC S9(09) USAGE COMP.                
           10 CO-LOCN-EFF-TS       PIC  X(26).                           
           10 ULT-PRNT-CO-LOCN-N   PIC S9(09) USAGE COMP.                
           10 IMD-PRNT-CO-LOCN-N   PIC S9(09) USAGE COMP.                
           10 NMFTA-SPL-C          PIC  X(09).                           
           10 NMFTA-SPL-SFX-C      PIC  X(03).                           
           10 EXP-TS               PIC  X(26).                           
           10 LST-MAINT-TS         PIC  X(26).                           
           10 LST-MAINT-USER-ID    PIC  X(08).                           
           10 LOC-NM               PIC  X(90).                           
           10 MAILING-ADV-BAR-C    PIC  X(02).                           
           10 MAILING-CHK-DIGIT    PIC  X(01).                           
           10 BOL-FAX-BK-N         PIC  X(12).                           
           10 BOL-FAX-CNFRM-TXT    PIC  X(40).                           
           10 BOL-FAX-CNFRM-C      PIC  X(01).                           
           10 BOL-RELS-C           PIC  X(01).                           
           10 BL-WC-EDI-IND        PIC  X(01).                           
           10 RLINC-CUST-EDI-ID    PIC  X(04).                           
           10 DIALIN-CUST-EDI-ID   PIC  X(12).                           
           10 CORP-TP-C            PIC  X(02).                           
           10 INFO-SRC-C           PIC  X(02).                           
           10 MAINT-RSN-C          PIC  X(02).                           
           10 PHYS-SRVC-C          PIC  X(01).                           
           10 BS-STAT-C            PIC  X(02).                           
           10 COMMENTS             PIC  X(45).                           
           10 CO-ID                PIC S9(09) USAGE COMP.                
           10 CUST-633-ID          PIC  X(12).                           
           10 CUST-CITY-333-C      PIC  X(09).                           
           10 CUST-ST-C            PIC  X(02).                           
           10 TRAFF-ACCT-N         PIC  X(11).                           
           10 MAILING-CNTRY-C      PIC  X(03).                           
           10 MAILING-ST-PRVNC-C   PIC  X(02).                           
           10 MAILING-CNTY-NM      PIC  X(30).                           
           10 MAILING-CITY         PIC  X(30).                           
           10 MAILING-POSTAL-C     PIC  X(09).                           
           10 MAILING-ADDR-1       PIC  X(35).                           
           10 MAILING-ADDR-2       PIC  X(35).                           
           10 MAILING-ADDR-3       PIC  X(35).                           
           10 PHYS-CNTRY-C         PIC  X(03).                           
           10 PHYS-ST-PRVNC-C      PIC  X(02).                           
           10 PHYS-CNTY-NM         PIC  X(30).                           
           10 PHYS-CITY            PIC  X(30).                           
           10 PHYS-POSTAL-C        PIC  X(09).                           
           10 PHYS-ADDR-1          PIC  X(35).                           
           10 PHYS-ADDR-2          PIC  X(35).                           
           10 PHYS-ADDR-3          PIC  X(35).                           
           10 CIF-ID               PIC  X(09).                           
           10 CIF-ID-TP-C          PIC  X(01).                           
           10 MRGR-CIF-N           PIC  X(09).                           
           10 TEMP-PERM-C          PIC  X(02).                           
           10 CIF-ULT-PRNT-N       PIC  X(09).                           
           10 CIF-IMD-PRNT-N       PIC  X(09).                           
           10 ARI-LST-MAINT-DT     PIC  X(10).                           
           10 ARI-EFF-DT           PIC  X(10).                           
           10 ARI-EXP-DT           PIC  X(10).                           
           10 NLOC-LOC-ID          PIC S9(09) USAGE COMP.                
           10 NLOC-CIF-ID          PIC  X(09).                           
CM1288     10 CIF-DOM-PRNT-N       PIC  X(09).                           
CM1288     10 CIF-TAX-ID-QLF       PIC  X(02).                           
CM1288     10 CIF-TAX-ID.                                                
CM1288        49 CIF-TAX-ID-LEN    PIC S9(04) USAGE COMP.                
CM1288        49 CIF-TAX-ID-TEXT   PIC  X(50).                           
CM1288     10 CIF-MAIL-POSTC       PIC  X(11).                           
CM1288     10 CIF-PHYS-POSTC       PIC  X(11).                           
CM1375     10 CIF-CMNT             PIC  X(30).                           
CM1419     10 DBA-NME-CD           PIC  X(01).                           
CM1419     10 BILL-ADDR-CD         PIC  X(01).                           
CM1419     10 DELY-ADDR-CD         PIC  X(01).                           
           10 CIF-SUB-CD           PIC  X(04).                           
           10 NLOC-CIF-SUB-CD      PIC  X(04).                           
      ****************************************************************** 
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 62      * 
      ****************************************************************** 
                                                                         
012150                                                                   
012160****************************************************************** 
012170*  SQL COMMUNICATIONS AREA                                       * 
012180****************************************************************** 
012190                                                                   
012191     EXEC SQL                                                      
012192        INCLUDE SQLCA                                              
012193     END-EXEC.                                                     
                                                                         
012194                                                                   
012200****************************************************************** 
012300*  SQL CURSORS                                                   * 
012400****************************************************************** 
013500                                                                   
013501* pull all potential sublocations                                  
013606     EXEC SQL                                                      
013607       DECLARE SUBLOCATION CURSOR FOR                              
013608        SELECT A.CIF_ID                                            
013609              ,A.CIF_SUB_LOCN_SFX_C                                
013610                                                                   
013620          FROM CL.TCLF_CO_LOCN_ADDR A                              
013630              ,CL.TCLF_CO_CIF_DTL B                                
013640                                                                   
013650         WHERE A.CO_LOCN_N       = B.LOC_ID                        
013660           AND B.CIF_APP_CD      = 'Y'                             
013670           AND (A.CIF_SUB_LOCN_SFX_C > '    ' AND                  
013671                A.CIF_SUB_LOCN_SFX_C > '0000'  )                   
013672           AND A.ADDR_EFF_TS    <= :W-TIMESTAMP                    
013673           AND A.EXP_TS         >= :W-TIMESTAMP                    
013674           AND B.CO_LOCN_EFF_TS <= :W-TIMESTAMP                    
013675           AND B.EXP_TS         >= :W-TIMESTAMP                    
013676           AND NOT EXISTS                                          
013677                                                                   
013678                (SELECT C.LOC_ID                                   
013679                   FROM CL.TCLF_CO_LOCN_DTL C                      
013680                   WHERE A.CIF_ID            =  C.CIF_ID           
013681                   AND A.CIF_SUB_LOCN_SFX_C  =  C.CIF_SUB_CD       
013682                   AND C.CO_LOCN_EFF_TS      <= :W-TIMESTAMP       
013683                   AND C.EXP_TS              >= :W-TIMESTAMP       
013684                       )                                           
013685                                                                   
013686         ORDER BY A.CIF_ID                                         
013687                 ,A.CIF_SUB_LOCN_SFX_C                             
013690                                                                   
013732       WITH UR                                                     
013733     END-EXEC.                                                     
013734                                                                   
013786****************************************************************** 
013790*  OUTPUT REPORTS                                                * 
013800****************************************************************** 
013900                                                                   
014000 01 BLANK-LINE                     PIC  X(80) VALUE SPACES.        
014100                                                                   
014110 01 DASHED-LINE.                                                   
014120    05 FILLER                      PIC  X(35) VALUE                
014130       '-----------------------------------'.                      
014131    05 FILLER                      PIC  X(35) VALUE                
014132       '-----------------------------------'.                      
014140                                                                   
014200 01 REPORT-HEADER-1.                                               
014610    05 FILLER                      PIC  X(01) VALUE SPACES.        
014755    05 WO-MONTH                    PIC  X(02) VALUE SPACES.        
014756    05 FILLER                      PIC  X(01) VALUE '/'.           
014757    05 WO-DAY                      PIC  X(02) VALUE SPACES.        
014758    05 FILLER                      PIC  X(01) VALUE '/'.           
014759    05 WO-YEAR                     PIC  X(04) VALUE SPACES.        
014760    05 FILLER                      PIC  X(03) VALUE SPACES.        
014761    05 WO-HOUR                     PIC  X(02) VALUE SPACES.        
014762    05 FILLER                      PIC  X(01) VALUE ':'.           
014763    05 WO-MINUTE                   PIC  X(02) VALUE SPACES.        
014764    05 FILLER                      PIC  X(05) VALUE SPACES.        
014765    05 FILLER                      PIC  X(50) VALUE                
014766               'Address MERGING TO LOCATIONS REPORT'.              
014767                                                                   
014768 01 REPORT-HEADER-2.                                               
014769    05 FILLER                      PIC  X(01) VALUE SPACES.        
014772    05 FILLER                      PIC  X(20) VALUE                
014773               'Program: CLADRILD'.                                
014774                                                                   
014775                                                                   
014776 01 REPORT-HEADER-3.                                               
014780    05 FILLER                      PIC  X(01) VALUE SPACES.        
014900    05 FILLER                      PIC  X(16) VALUE                
014991               'Cif Id'.                                           
014999    05 FILLER                      PIC  X(11) VALUE                
015000               'Loc Id'.                                           
015010    05 FILLER                      PIC  X(14) VALUE                
015100               '633'.                                              
015130    05 FILLER                      PIC  X(11) VALUE                
015200               '333'.                                              
015211    05 FILLER                      PIC  X(04) VALUE                
015220               'ST'.                                               
015310    05 FILLER                      PIC  X(92) VALUE                
015320               'NAME'.                                             
015390    05 FILLER                      PIC  X(05) VALUE                
015400               'CDI'.                                              
015410    05 FILLER                      PIC  X(05) VALUE                
015420               'SSI'.                                              
015500    05 FILLER                      PIC  X(05) VALUE                
015600               'ISA'.                                              
015700    05 FILLER                      PIC  X(08) VALUE                
015800               'PATRON'.                                           
017000    05 FILLER                      PIC  X(52) VALUE                
017001               'MSG'.                                              
017002                                                                   
017010 01 REPORT-DETAIL.                                                 
017020    05 FILLER                      PIC  X(01) VALUE SPACES.        
017100    05 WO-CIF-ID                   PIC  X(16) VALUE SPACES.        
017600    05 WO-LOC-ID                   PIC  ZZZZZZZZ9.                 
017700    05 FILLER                      PIC  X(02) VALUE SPACES.        
018000    05 WO-CUST-633                 PIC  X(14) VALUE SPACES.        
018400    05 WO-CUST-CITY-333-C          PIC  X(11) VALUE SPACES.        
018800    05 WO-CUST-ST-C                PIC  X(04) VALUE SPACES.        
019200    05 WO-LOC-NME                  PIC  X(92) VALUE SPACES.        
019300    05 WO-CDI                      PIC  X(05) VALUE SPACES.        
019400    05 WO-SSI                      PIC  X(05) VALUE SPACES.        
019500    05 WO-ISA                      PIC  X(05) VALUE SPACES.        
019510    05 WO-PATRON                   PIC  X(08) VALUE SPACES.        
019600    05 WO-ERROR-MESSAGE            PIC  X(52) VALUE SPACES.        
020400                                                                   
037000****************************************************************** 
037100****************************************************************** 
037200*               P R O C E D U R E  D I V I S I O N               * 
037300****************************************************************** 
037400****************************************************************** 
037500                                                                   
037600 PROCEDURE DIVISION.                                               
037700                                                                   
037800      PERFORM 0000-INITIALIZE THRU 0000-EXIT.                      
037810                                                                   
037900      PERFORM 1000-PROCESS    THRU 1000-EXIT                       
038000        UNTIL W-EOF      = 'Y'.                                    
038110                                                                   
038202      PERFORM 9000-STATS      THRU 9000-EXIT.                      
038204      PERFORM 9999-CLOSE      THRU 9999-EXIT.                      
038210                                                                   
038300      GOBACK.                                                      
038400                                                                   
038500****************************************************************** 
038600*  0000-INITIALIZE                                               * 
038700****************************************************************** 
038800                                                                   
038900 0000-INITIALIZE.                                                  
039200                                                                   
039210     OPEN OUTPUT OUTPUT-REPORT.                                    
039220                                                                   
039300     EXEC SQL                                                      
039400       SET :W-TIMESTAMP = CURRENT TIMESTAMP                        
039500     END-EXEC.                                                     
041000                                                                   
041001     MOVE 'N' TO W-EOF.                                            
041002                                                                   
041010     EVALUATE SQLCODE                                              
041020       WHEN +0                                                     
041040         MOVE W-TIMESTAMP(6:2)  TO WO-MONTH                        
041041         MOVE W-TIMESTAMP(9:2)  TO WO-DAY                          
041042         MOVE W-TIMESTAMP(1:4)  TO WO-YEAR                         
041043         MOVE W-TIMESTAMP(12:2) TO WO-HOUR                         
041044         MOVE W-TIMESTAMP(15:2) TO WO-MINUTE                       
041045        CONTINUE                                                   
041050       WHEN OTHER                                                  
041051         MOVE 'Y' TO W-EOF                                         
041052         MOVE SQLCODE TO WD-SQL-CODE                               
041060         DISPLAY WD-SQL-CODE ' ERROR ON SET TIMESTAMP'             
041097     END-EVALUATE.                                                 
041099                                                                   
041136     IF W-EOF = 'N'                                                
041137       PERFORM 0500-OPEN-CURSOR THRU 0500-EXIT                     
041138     END-IF.                                                       
041139                                                                   
041140     IF W-EOF = 'N'                                                
041141       PERFORM 0700-FETCH       THRU 0700-EXIT                     
041142     END-IF.                                                       
041143                                                                   
041144     IF W-EOF = 'N'                                                
041145       WRITE OUTPUT-REPORT-REC FROM REPORT-HEADER-1                
041146       WRITE OUTPUT-REPORT-REC FROM REPORT-HEADER-2                
041147       WRITE OUTPUT-REPORT-REC FROM BLANK-LINE                     
041149       WRITE OUTPUT-REPORT-REC FROM REPORT-HEADER-3                
041150     END-IF.                                                       
041151                                                                   
041160 0000-EXIT.                                                        
041200      EXIT.                                                        
041300                                                                   
045773****************************************************************** 
045774* 0500-OPEN-CURSOR                                               * 
045775****************************************************************** 
045776                                                                   
045777 0500-OPEN-CURSOR.                                                 
045778                                                                   
045779     EXEC SQL                                                      
045780       OPEN SUBLOCATION                                            
045781     END-EXEC.                                                     
045782                                                                   
045783     EVALUATE SQLCODE                                              
045784       WHEN +0                                                     
045785         CONTINUE                                                  
045786       WHEN OTHER                                                  
045787         MOVE 'Y' TO W-EOF                                         
045788         MOVE SQLCODE TO WD-SQL-CODE                               
045789         DISPLAY WD-SQL-CODE ' ERROR ON OPEN CURSOR'               
045790     END-EVALUATE.                                                 
045791                                                                   
045792 0500-EXIT.                                                        
045793      EXIT.                                                        
045794                                                                   
045795****************************************************************** 
045796* 0700-FETCH                                                     * 
045797****************************************************************** 
045798                                                                   
045799 0700-FETCH.                                                       
045800                                                                   
045801     EXEC SQL                                                      
045802       FETCH SUBLOCATION                                           
045803        INTO :W-CIF-ID                                             
045804            ,:W-CIF-SUB-LOCN-SFX-C                                 
045833     END-EXEC.                                                     
045834                                                                   
045835     EVALUATE SQLCODE                                              
045836       WHEN +0                                                     
045837         ADD 1 TO W-PROCESSED-CNT                                  
045838       WHEN +100                                                   
045839         MOVE 'Y' TO W-EOF                                         
045840       WHEN OTHER                                                  
045841         MOVE 'Y' TO W-EOF                                         
045842         MOVE SQLCODE TO WD-SQL-CODE                               
045843         DISPLAY WD-SQL-CODE ' ERROR ON FETCH CURSOR'              
045844     END-EVALUATE.                                                 
045845                                                                   
045846 0700-EXIT.                                                        
045847      EXIT.                                                        
045848                                                                   
045860****************************************************************** 
045861* 1000-PROCESS                                                   * 
045862****************************************************************** 
045863                                                                   
045864 1000-PROCESS.                                                     
045865                                                                   
045866     INITIALIZE CLCSLALM-PARMS.                                    
045893                                                                   
045900     MOVE W-CIF-ID             TO CLCSLALM-CIF-ID.                 
045901     MOVE W-CIF-SUB-LOCN-SFX-C TO CLCSLALM-CIF-SUB-LOCN-SFX-C.     
045906                                                                   
045907     CALL W-CLCSLALM USING CLCSLALM-PARMS.                         
045910                                                                   
045918     IF CLCSLALM-SUCCESSFUL                                        
045920       ADD 1 TO W-LOC-MERGED-CNT                                   
045922       PERFORM 2000-REPORT THRU 2000-EXIT                          
045962     ELSE                                                          
045963       ADD  1                           TO W-ERRORS-CNT            
045964       MOVE CLCSLALM-ERROR-MESSAGE      TO WO-ERROR-MESSAGE        
045965                                                                   
045966       EVALUATE TRUE                                               
045967         WHEN CLCSLALM-DB2-CONNECT                                 
045968           ADD 1 TO W-DB2-CONNECT                                  
045969                                                                   
045970         WHEN CLCSLALM-NO-CANDIDATE-FOUND                          
045971           ADD 1 TO W-NO-CANDIDATE-FOUND                           
045972                                                                   
045973         WHEN CLCSLALM-ADR-ALREADY-EXISTS                          
045974           ADD 1 TO W-ADR-ALREADY-EXISTS                           
045975                                                                   
045976         WHEN CLCSLALM-ADR-NOT-FOUND                               
045977           ADD 1 TO W-ADR-NOT-FOUND                                
045978                                                                   
045979         WHEN CLCSLALM-PARENT-LOC-MISSING                          
045980           ADD 1 TO W-PARENT-LOC-MISSING                           
045981                                                                   
045982         WHEN CLCSLALM-EXPIRE-VERSION                              
045983           ADD 1 TO W-EXPIRE-VERSION                               
045984                                                                   
045985         WHEN CLCSLALM-LOOKUP-PARENT-CIF                           
045986           ADD 1 TO W-LOOKUP-PARENT-CIF                            
045987                                                                   
045988         WHEN CLCSLALM-INSERT-MERGED-VRSN                          
045989           ADD 1 TO W-INSERT-MERGED-VRSN                           
045990                                                                   
045991         WHEN CLCSLALM-ADDR-ADD-FAILURE                            
045992           ADD 1 TO W-ADDR-ADD-FAILURE                             
045993       END-EVALUATE                                                
045994     END-IF.                                                       
045995                                                                   
045996     IF CLCSLALM-LOC-FOUND = 'Y'                                   
045997       ADD 1 TO W-LOC-FOUND-CNT                                    
045998     ELSE                                                          
045999       ADD 1 TO W-LOC-NOT-FOUND-CNT                                
046000     END-IF.                                                       
046141                                                                   
046142     PERFORM 1100-CLEAR-VARIABLES THRU 1100-EXIT.                  
046143                                                                   
046144     PERFORM 0700-FETCH           THRU 0700-EXIT.                  
046145                                                                   
046146 1000-EXIT.                                                        
046147      EXIT.                                                        
046150                                                                   
046932****************************************************************** 
046933* 1100-CLEAR-VARIABLES                                           * 
046934****************************************************************** 
046935                                                                   
046936 1100-CLEAR-VARIABLES.                                             
046937                                                                   
046938     MOVE 0      TO WO-LOC-ID                                      
046941                    CLCSLALM-MERGE-LOC-ID                          
046942                    CLCSLALM-MERGE-CO-ID                           
046943                    CLCSLALM-SQLCODE.                              
046947                                                                   
046948     MOVE SPACES TO W-CIF-ID                                       
046949                    W-CIF-SUB-LOCN-SFX-C                           
046950                    WO-CIF-ID                                      
046953                    WO-CUST-633                                    
046954                    WO-CUST-CITY-333-C                             
046955                    WO-CUST-ST-C                                   
046956                    WO-LOC-NME                                     
046957                    WO-CDI                                         
046958                    WO-SSI                                         
046959                    WO-ISA                                         
046960                    WO-PATRON                                      
046961                    WO-ERROR-MESSAGE                               
046970                    CLCSLALM-LOC-NME                               
046971                    CLCSLALM-CUST-633-ID                           
046972                    CLCSLALM-CUST-CITY-333-C                       
046973                    CLCSLALM-CUST-ST-C                             
046974                    CLCSLALM-LOC-FOUND                             
046975                    CLCSLALM-ERROR-MESSAGE.                        
046992                                                                   
046993 1100-EXIT.                                                        
046994      EXIT.                                                        
046995                                                                   
046996****************************************************************** 
046997* 2000-REPORT                                                    * 
046998****************************************************************** 
046999                                                                   
047000 2000-REPORT.                                                      
047014                                                                   
047015     MOVE CLCSLALM-CIF-ID             TO WO-CIF-ID(1:9).           
047016     MOVE '-'                         TO WO-CIF-ID(10:1).          
047017     MOVE CLCSLALM-CIF-SUB-LOCN-SFX-C TO WO-CIF-ID(11:4).          
047018     MOVE CLCSLALM-MERGE-LOC-ID       TO WO-LOC-ID                 
047019     MOVE CLCSLALM-LOC-NME            TO WO-LOC-NME                
047020     MOVE CLCSLALM-CUST-633-ID        TO WO-CUST-633               
047021     MOVE CLCSLALM-CUST-CITY-333-C    TO WO-CUST-CITY-333-C        
047022     MOVE CLCSLALM-CUST-ST-C          TO WO-CUST-ST-C              
047023     MOVE 'Merged'                    TO WO-ERROR-MESSAGE          
047030                                                                   
047031     MOVE 0 TO W-COUNT.                                            
047032                                                                   
047033     EXEC SQL                                                      
047034       SELECT COUNT(*)                                             
047035         INTO :W-COUNT                                             
047036         FROM CM.TDEST_INST                                        
047037        WHERE CUST_633 =:CLCSLALM-CUST-633-ID                      
047038          AND DEST_333 =:CLCSLALM-CUST-CITY-333-C                  
047039          AND DEST_ST  =:CLCSLALM-CUST-ST-C                        
047040     END-EXEC.                                                     
047041                                                                   
047042     IF W-COUNT > 0                                                
047043       MOVE 'Y' TO WO-CDI                                          
047044     ELSE                                                          
047045       MOVE 'N' TO WO-CDI                                          
047046     END-IF.                                                       
047047                                                                   
047052     MOVE 0 TO W-COUNT.                                            
047053                                                                   
047054     EXEC SQL                                                      
047055       SELECT COUNT(*)                                             
047056         INTO :W-COUNT                                             
047057         FROM CM.TCUST_SSI                                         
047058        WHERE CUST_633 =:CLCSLALM-CUST-633-ID                      
047059          AND DEST_333 =:CLCSLALM-CUST-CITY-333-C                  
047060          AND DEST_ST  =:CLCSLALM-CUST-ST-C                        
047061     END-EXEC.                                                     
047062                                                                   
047063     IF W-COUNT > 0                                                
047064       MOVE 'Y' TO WO-SSI                                          
047065     ELSE                                                          
047066       MOVE 'N' TO WO-SSI                                          
047067     END-IF.                                                       
047072                                                                   
047073     MOVE 0 TO W-COUNT.                                            
047074                                                                   
047075     EXEC SQL                                                      
047076       SELECT COUNT(*)                                             
047077         INTO :W-COUNT                                             
047078         FROM CM.TPATRON                                           
047079        WHERE CO_LOCN_N =:CLCSLALM-MERGE-LOC-ID                    
047080     END-EXEC.                                                     
047081                                                                   
047082     IF W-COUNT > 0                                                
047083       MOVE 'Y' TO WO-PATRON                                       
047084     ELSE                                                          
047085       MOVE 'N' TO WO-PATRON                                       
047086     END-IF.                                                       
047087                                                                   
047088     MOVE 0 TO W-COUNT.                                            
047089                                                                   
047090     EXEC SQL                                                      
047091       SELECT COUNT(*)                                             
047092         INTO :W-COUNT                                             
047093         FROM CL.TCLF_OPR_ASP                                      
047094        WHERE CO_LOCN_N       =:CLCSLALM-MERGE-LOC-ID              
047095          AND OPR_ASP_EFF_TS <=:W-TIMESTAMP                        
047096          AND EXP_TS         >=:W-TIMESTAMP                        
047097     END-EXEC.                                                     
047098                                                                   
047099     IF W-COUNT > 0                                                
047100       MOVE 'Y' TO WO-ISA                                          
047101     ELSE                                                          
047102       MOVE 'N' TO WO-ISA                                          
047103     END-IF.                                                       
047108                                                                   
047109     WRITE OUTPUT-REPORT-REC FROM REPORT-DETAIL.                   
047110                                                                   
047111 2000-EXIT.                                                        
047112      EXIT.                                                        
047113                                                                   
047114****************************************************************** 
047115* 9000-STATS                                                     * 
047116****************************************************************** 
047117                                                                   
047118 9000-STATS.                                                       
047119                                                                   
047120     MOVE W-PROCESSED-CNT      TO W-PROCESSED-CNT-D.               
047121     MOVE W-LOC-FOUND-CNT      TO W-LOC-FOUND-CNT-D.               
047122     MOVE W-LOC-NOT-FOUND-CNT  TO W-LOC-NOT-FOUND-CNT-D.           
047123     MOVE W-LOC-MERGED-CNT     TO W-LOC-MERGED-CNT-D.              
047124     MOVE W-ERRORS-CNT         TO W-ERRORS-CNT-D.                  
047125     MOVE W-DB2-CONNECT        TO W-DB2-CONNECT-D.                 
047126     MOVE W-NO-CANDIDATE-FOUND TO W-NO-CANDIDATE-FOUND-D.          
047127     MOVE W-ADR-ALREADY-EXISTS TO W-ADR-ALREADY-EXISTS-D.          
047128     MOVE W-ADR-NOT-FOUND      TO W-ADR-NOT-FOUND-D.               
047129     MOVE W-PARENT-LOC-MISSING TO W-PARENT-LOC-MISSING-D.          
047130     MOVE W-EXPIRE-VERSION     TO W-EXPIRE-VERSION-D.              
047131     MOVE W-LOOKUP-PARENT-CIF  TO W-LOOKUP-PARENT-CIF-D.           
047132     MOVE W-INSERT-MERGED-VRSN TO W-INSERT-MERGED-VRSN-D.          
047133     MOVE W-ADDR-ADD-FAILURE   TO W-ADDR-ADD-FAILURE-D.            
047134                                                                   
047135     DISPLAY 'ADR Candidates          : ' W-PROCESSED-CNT-D.       
047136     DISPLAY 'Dummy Location Found    : ' W-LOC-FOUND-CNT-D.       
047137     DISPLAY 'Dummy Location Not Found: ' W-LOC-NOT-FOUND-CNT-D.   
047138     DISPLAY 'ADR Merged with Location: ' W-LOC-MERGED-CNT-D.      
047139     DISPLAY 'Number of errors        : ' W-ERRORS-CNT-D.          
047140     DISPLAY '  DB2 Connection        : ' W-DB2-CONNECT-D.         
047141     DISPLAY '  No Candidate Found    : ' W-NO-CANDIDATE-FOUND-D.  
047142     DISPLAY '  ADR Already Exists    : ' W-ADR-ALREADY-EXISTS-D.  
047143     DISPLAY '  ADR Not Found         : ' W-ADR-NOT-FOUND-D.       
047144     DISPLAY '  Parent Loc Missing    : ' W-PARENT-LOC-MISSING-D.  
047145     DISPLAY '  Expire Version        : ' W-EXPIRE-VERSION-D.      
047146     DISPLAY '  Lookup Parent CIF     : ' W-LOOKUP-PARENT-CIF-D.   
047147     DISPLAY '  Insert Merged Version : ' W-INSERT-MERGED-VRSN-D.  
047148     DISPLAY '  Address Add Failure   : ' W-ADDR-ADD-FAILURE-D.    
047149                                                                   
047150 9000-EXIT.                                                        
047151      EXIT.                                                        
047152                                                                   
047153****************************************************************** 
047154* 9999-CLOSE                                                     * 
047155****************************************************************** 
047156                                                                   
047157 9999-CLOSE.                                                       
047158                                                                   
047159     EXEC SQL                                                      
047160       CLOSE SUBLOCATION                                           
047161     END-EXEC                                                      
047162                                                                   
047163     CLOSE OUTPUT-REPORT.                                          
047164                                                                   
047165 9999-EXIT.                                                        
047170      EXIT.                                                        
047200                                                                   
086500****************************************************************** 
086600****************************************************************** 
086700*                   E N D   O F   P R O G R A M                  * 
086800****************************************************************** 
086900****************************************************************** 
