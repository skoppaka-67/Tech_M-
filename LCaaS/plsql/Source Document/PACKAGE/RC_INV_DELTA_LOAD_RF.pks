CREATE OR REPLACE PACKAGE RMKTGADM./*AppDB: 1040770*/            "RC_INV_DELTA_LOAD_RF"                               
IS
   /*===================================================================================================+
 |                                 Cisco Systems, INC., CALIFORNIA                                   |
 +====================================================================================================+
 | Object Name    RC_INV_DELTA_LOAD_RF
 |
 | Module        :

 | Description   :
 |
 | Revision History:
 | -----------------
 | Date         Updated By                          Bug/Case#              Rev   Comments
 |==========    ================                    ===========           ==== ================================================
 | 23-Jun-2016  mohamms2(Mohammed reyaz Shaik)      ACT                   1.0  Created                                    |
 | 24-Mar-2017  mohamms2(Mohammed reyaz Shaik)      release               1.1  Added Yiled fundtion as part APR17 Release  |
 | 05-OCT-2017  mohamms2(Mohammed Reyaz Shaik )     US134524              1.2  PID Deactivation changes - restrict DGI for T-4 PIDs
 | 09-APR-2018  sridvasu(Sridevi Vasudevan)           Sprint#19 Release    2.0  Added to send mail to inventory admins when shortage in RoHS/NRoHS adjustments as part of US164572
 | 27-AUG-2018  sridvasu(Sridevi Vasudevan)           Sept Release         2.1  Created new procedure RC_INV_NEG_MANUAL_ADJ to clear -VE FG  
 | 02-JUL-2018  mohamms2(Mohammed Reyaz Shaik )     US193036(Sprint#21)   2.2  Added as part of  yield logic changes
 | 15-OCT-2018  csirigir(Chandra Shekar Reddy )     US193036(Sprint#21)   2.3  Commented Existing Outlet procedure and added new procedure as part of Selling FGI only requirements for Oct 27 Release
  |17-JAN-2019  sridvasu(Sridevi Vasudevan)                               2.4  Added new procedure RC_INV_RF_MAIN to check delta job dependency   
  +==================================================================================================*/
   PROCEDURE RF_MAIN (P_STATUS_MESSAGE OUT VARCHAR2, P_SITE_CODE IN VARCHAR2);

   PROCEDURE RC_INV_RF_DGI_EXTRACT (P_INTRANS_FLAG      VARCHAR2 DEFAULT 'N',
                                    P_SITE_CODE      IN VARCHAR2);

   PROCEDURE RC_INV_RF_DGI_HISTORY (P_SITE_CODE IN VARCHAR2);

   --
   FUNCTION RC_INV_GET_REFURB_METHOD (I_RID                 NUMBER,
                                      I_ZCODE               VARCHAR2, --Added  parameter as part of userstory US193036 to modify yield calculation ligic
                                      I_SUB_INV_LOCATION    VARCHAR2) --Added  parameter as part of userstory US193036 to modify yield calculation ligic
      RETURN NUMBER;

   FUNCTION RC_INV_GET_YIELD/*(i_product_type NUMBER,                    -- Removing  parameter as part of userstory US193036 to modify yield calculation ligic */
                              (I_RID                          INTEGER,
              /*               i_theater_id                   NUMBER,   -- Removing  parameter as part of userstory US193036 to modify yield calculation ligic */
                               I_ZCODE                        VARCHAR2,
              /*               i_refresh_method_id            NUMBER)   -- Removing parameter as part of userstory US193036 to modify yield calculation ligic */
                               I_SUB_INV_LOCATION             VARCHAR2) -- Added  parameter as part of userstory US193036 to modify yield calculation ligic
      RETURN NUMBER;

   --
   PROCEDURE RC_INV_RF_DGI_DELTA (P_SITE_CODE IN VARCHAR2);

   --
   PROCEDURE RC_INV_RF_FGI_EXTRACT (P_SITE_CODE IN VARCHAR2);

   --
   PROCEDURE RC_INV_RF_FGI_ROHS_NROHS_MOVE;

   --
   PROCEDURE RC_INV_RF_DGI_FGI_LOAD (P_SITE_CODE IN VARCHAR2); --LOAD_RMK_INVENTORY_LOG_PROC;

   --   PROCEDURE MAIN (P_STATUS_MESSAGE OUT VARCHAR2);
   --
   PROCEDURE RC_INV_RF_DGI_PUT_REMINDERS;

   --
   PROCEDURE RC_INV_RF_DGI_GET_REMINDERS;

   --
   PROCEDURE RC_INV_RF_SEND_ERROR_EMAIL (I_PROCEDURE_NAME    VARCHAR2,
                                         I_ERROR_MSG         VARCHAR2);

   --
   PROCEDURE RC_INV_RF_SEND_WARNING_EMAIL (I_PROCEDURE_NAME    VARCHAR2,
                                           I_ERROR_MSG         VARCHAR2);

   --   PROCEDURE RC_INV_REGULAR_OUTLET_BASE;

--   PROCEDURE RC_INV_OUTLET_BTS_SPLIT; -- Commented this procedure as part of selling FGI only requirements for Oct 27 Release on 15-OCT-2018

   --
   --FUNCTION GET_ACTIVE_PID (pns VARCHAR2) RETURN VARCHAR2;

   --FUNCTION GET_ACTIVE_PNS (pns VARCHAR2) RETURN VARCHAR2;

   --Added by mohamms2 as on 05-OCT-2017 for User Story US134524 -> PID Deactivation changes - restrict DGI for T-4 PIDs srpint
   PROCEDURE RC_INV_RF_EOS_PID_QTY_REVOKE;

   -- Added to send mail on inventory shortages for Rohs/NRohs adjustments
   PROCEDURE RC_INV_ROHS_NROHS_SEND_MAIL;
   
   -- Created new procedure to clear -VE FG
   PROCEDURE RC_INV_NEG_MANUAL_ADJ (P_SITE_CODE IN VARCHAR2);  
   
   -- Created new procedure as part of selling FGI only requirements for Oct 27 Release on 15-OCT-2018
   PROCEDURE RC_INV_OUTLET_FORWARD_ALLOC;
   
   --Created new procedure for Delta job dependency check on 17-Jan-2019
   PROCEDURE RC_INV_RF_MAIN (P_STATUS_MESSAGE OUT VARCHAR2, P_SITE_CODE IN VARCHAR2);
     
END RC_INV_DELTA_LOAD_RF;
/