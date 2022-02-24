CREATE OR REPLACE PACKAGE CRPADM./*AppDB: 1039852*/          "RC_INV_BTS_C3_PKG"                                                                          
IS
   /*===================================================================================================+
    Object Name    : RC_INV_BTS_C3_PKG
    Module         : C3 and FGI Interface 2 Hourly Refresh SSOT
    Description    : C3 AND FGI AUTOMATION PROCESS 2 Hourly Refresh SSOT
    Revision History:
    -----------------
    Date        Updated By       Bug/Case#   Rev   Comments
   ========= ================ =========== ==== ======================================================
   8 Apr 2013  radwived                           1.0     First Draft
 14 Jun 2013  Seshadri                            2.0     WS Enablement Changes, Common DGI Consolidation and Sreen Only Part Changes
 02 Sep 2013 ruchhabr                            3.0     Procedure added to refresh the table RSCM_TMP_ML_C3_INV_TBL used by 1CT,WCT
 28 Sep 2018 sridvasu                            3.1     Added new procedure RC_INV_C3_QTY_YIELD_CALC to calculate qty after yield  
   ==============================================================================================*/

    PROCEDURE BTS_MAIN;
    PROCEDURE REFRESH_BTS_C3_INV_DATA;
    PROCEDURE REFRESH_BTS_C3_INV_MV;
    PROCEDURE RC_INV_C3_QTY_YIELD_CALC;
    FUNCTION RC_INV_GET_REFURB_METHOD (I_RID                 NUMBER,
                                      I_ZCODE               VARCHAR2, --Added  parameter as part of userstory US193036 to modify yield calculation ligic
                                      I_SUB_INV_LOCATION    VARCHAR2) RETURN NUMBER; --Added  parameter as part of userstory US193036 to modify yield calculation ligic
    FUNCTION RC_INV_GET_YIELD ( /*I_PRODUCT_TYPE                 NUMBER,  --Removing  parameter as part of userstory US193036 to modify yield calculation ligic */
                              /* I_THEATER_ID                   NUMBER,  --Removing  parameter as part of userstory US193036 to modify yield calculation ligic */
                              /* I_REFRESH_METHOD_ID            NUMBER,  --Removing  parameter as part of userstory US193036 to modify yield calculation ligic */
                              I_RID                 INTEGER, -- Added  parameter as part of userstory US193036 to modify yield calculation ligic
                              I_ZCODE               VARCHAR2,
                              I_SUB_INV_LOCATION    VARCHAR2) RETURN NUMBER;
    
END RC_INV_BTS_C3_PKG;
/