CREATE OR REPLACE PACKAGE RMKTGADM./*AppDB: 1049381*/
                                  "RC_INV_DELTA_LOAD_EX"
IS
   /*===================================================================================================+
 |                                 Cisco Systems, INC., CALIFORNIA                                   |
 +====================================================================================================+
 | Object Name    RC_RF_PKG_CCW_INV_DELTA_LOAD
 |
 | Module        :

 | Description   :
 |
 | Revision History:
 | -----------------
 | Date         Updated By                           Bug/Case#                      Rev  Comments
 |==========    ================                     ===========                    ==== ================================================
 | 23-Jun-2016  mohamms2(Mohammed reyaz Shaik)       ACT                            1.0  Created
 | 07-Jun-2016  mohamms2(Mohammed Reyaz Shaik )      Jul-17 release                 1.1  Added parameter to the FGI Extracion Proc             |
 | 05-OCT-2017  mohamms2(Mohammed Reyaz Shaik )      User Story  US134524           1.2  PID Deactivation changes - restrict DGI for T-4 PIDs
 | 02-APR-2018  sridvasu(Sridevi Vasudevan)          Sprint#19 Release              1.3  As part of US164572 Rohs/NRohs Automation add a new procedure and function
 | 02-JUL-2017  mohamms2(Mohammed Reyaz Shaik )      US193036(Sprint#21)            1.4  Added as part of  yield logic changes.
 |17-JAN-2019  sridvasu(Sridevi Vasudevan)                                         1.5  Added new procedure RC_INV_EX_MAIN to check delta job dependency
 |11-MAY-2020  sneyadav(Snehalata Yadav)              US390864                      3.3  Modified FVE FC01 feed processing
 ==================================================================================================*/
   PROCEDURE EX_MAIN (P_STATUS_MESSAGE OUT VARCHAR2, P_SITE_CODE IN VARCHAR2);

   PROCEDURE RC_INV_EX_DGI_EXTRACT (P_INTRANS_FLAG      VARCHAR2 DEFAULT 'N',
                                    P_SITE_CODE      IN VARCHAR2);

   PROCEDURE RC_INV_EX_DGI_HISTORY (P_SITE_CODE IN VARCHAR2);

   --
   FUNCTION RC_INV_GET_REFURB_METHOD (I_RID                 NUMBER,
                                      I_ZCODE               VARCHAR2, --Added  parameter as part of userstory US193036 to modify yield calculation ligic
                                      I_SUB_INV_LOCATION    VARCHAR2) --Added  parameter as part of userstory US193036 to modify yield calculation ligic
      RETURN NUMBER;

   --
   FUNCTION RC_INV_GET_YIELD /*(i_product_type        NUMBER,                    -- Removing  parameter as part of userstory US193036 to modify yield calculation ligic */
                             (I_RID                 INTEGER,
                              /*   i_theater_id          NUMBER,   -- Removing  parameter as part of userstory US193036 to modify yield calculation ligic */
                              I_ZCODE               VARCHAR2,
                              /*   i_refresh_method_id   NUMBER)   -- Removing parameter as part of userstory US193036 to modify yield calculation ligic */
                              I_SUB_INV_LOCATION    VARCHAR2) -- Added  parameter as part of userstory US193036 to modify yield calculation ligic
      RETURN NUMBER;

   --
   FUNCTION RC_INV_PID_VALIDATION (I_PID IN VARCHAR2)
      RETURN VARCHAR2;

   --
   PROCEDURE RC_INV_EX_DGI_DELTA (P_SITE_CODE IN VARCHAR2);

   --
   PROCEDURE RC_INV_EX_FGI_EXTRACT (P_SITE_CODE IN VARCHAR2);

   --added as part of US390864
   PROCEDURE RC_INV_EX_DGI_LOAD (P_SITE_CODE IN VARCHAR2);

   --added as part of US390864
   PROCEDURE RC_INV_EX_FGI_LOAD (P_SITE_CODE IN VARCHAR2);

   PROCEDURE RC_INV_EX_FGI_ROHS_NROHS_MOVE;

   PROCEDURE RC_INV_EX_DGI_PUT_REMINDERS;

   --
   PROCEDURE RC_INV_EX_DGI_GET_REMINDERS;

   --
   PROCEDURE RC_INV_EX_SEND_ERROR_EMAIL (I_PROCEDURE_NAME    VARCHAR2,
                                         I_ERROR_MSG         VARCHAR2);

   --
   PROCEDURE RC_INV_EX_SEND_WARNING_EMAIL (I_PROCEDURE_NAME    VARCHAR2,
                                           I_ERROR_MSG         VARCHAR2);

   --Added by mohamms2 as on 05-OCT-2017 for User Story US134524 -> PID Deactivation changes - restrict DGI for T-4 PIDs sprint15
   PROCEDURE RC_INV_EX_EOS_PID_QTY_REVOKE;

   --Added as part of  US198778 For updateing SONS order received and pending qty
   PROCEDURE RC_SONS_DATA_UPDATE;

   --Created new procedure for Delta job dependency check on 17-Jan-2019
   PROCEDURE RC_INV_EX_MAIN (P_STATUS_MESSAGE      OUT VARCHAR2,
                             P_SITE_CODE        IN     VARCHAR2);

   /***Start*************** POE Delta Process to CCW *************************/

   FUNCTION RC_INV_POE_GET_REFURB_METHOD (I_RID                 NUMBER,
                                          I_ZCODE               VARCHAR2,
                                          I_SUB_INV_LOCATION    VARCHAR2)
      RETURN NUMBER;

   --
   FUNCTION RC_INV_POE_GET_YIELD (I_RID                 INTEGER,
                                  I_REFRESHPIDNAME      VARCHAR2,
                                  I_C3_PART_ID          VARCHAR2,
                                  I_ZCODE               VARCHAR2,
                                  I_SUB_INV_LOCATION    VARCHAR2)
      RETURN NUMBER;

   PROCEDURE ALLOC_C3_POE_YIELD_CALC;

   PROCEDURE RC_INV_POE_EXTRACT (P_INTRANS_FLAG      VARCHAR2 DEFAULT 'N',
                                 P_SITE_CODE      IN VARCHAR2);

   PROCEDURE RC_INV_POE_HISTORY (P_SITE_CODE IN VARCHAR2);

   PROCEDURE RC_INV_POE_DELTA_PROCESS (P_SITE_CODE IN VARCHAR2);

   PROCEDURE RC_INV_POE_PUT_REMINDERS;

   PROCEDURE RC_INV_POE_GET_REMINDERS;

   PROCEDURE RC_INV_POETOINVLOG_LOAD (P_SITE_CODE IN VARCHAR2);

   PROCEDURE RC_MAIN;
/***End*************** POE Delta Process to CCW *************************/

END RC_INV_DELTA_LOAD_EX;
/