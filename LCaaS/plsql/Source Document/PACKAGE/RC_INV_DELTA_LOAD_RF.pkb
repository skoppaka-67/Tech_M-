CREATE OR REPLACE PACKAGE BODY RMKTGADM."RC_INV_DELTA_LOAD_RF"
IS
   /*===================================================================================================+
   |                                 Cisco Systems, INC., CALIFORNIA                                   |
   +====================================================================================================+
   | Object Name    RMKTGADM.RC_INV_DELTA_LOAD_RF
   |
   | Module        :

   | Description   :
   |
   | Revision History:
   | -----------------
   | Date        Updated By                               Bug/Case#                  Rev   Comments
   |==========  ================                         ===========                ==== ================================================
   | 23-Jun-16  mohamms2(Mohammed reyaz Shaik)              ACT                      1.0  Created                                    |
   | 17-Mar-17 mohamms2(Mohammed Reyaz Shaik)         Apr-17 Release changes         1.1  As part of April 17 Release modified the DGI PUT and GET PROC's for
   |                                                                                     getting reminders at product level.    |
   |20-Mar-17  mohamms2(Mohammed Reyaz Shaik)         Apr-17 Release Changes         1.2  As part of April17 Release modified the DGI_FGI LOAD Proc for DGI mutiple rows
                                                                                               insert fix |
   |31-Mar-17  mohamms2(Mohammed Reyaz Shaik)         Apr-17 Release Changes         1.3    As part of April17 Release added the logic to verify the Stage and CG1 quantities adn
                                                                                            to process the FG qty  to CCW  |
   |03-Apr-17  mohamms2(Mohammed Reyaz Shaik)         Apr-17 Release Changes         1.4  As part of April17 Release added Yield calculation function to get the yield.  |

   |12-May-17  mohamms2(Mohammed Reyaz Shaik)         May-17 Release Changes         1.5  Control Table for CG1 Exception Quantity

   |05-OCT-2017  mohamms2(Mohammed Reyaz Shaik )       User Story  US134524          1.6  PID Deactivation changes - restrict DGI for T-4 PIDs

   |03-NOV-2017  mohamms2(Mohammed Reyaz Shaik )       Sprint16 Release              1.7  C3 table schema changes from RMKTGADM to CRPADM

   |15-JAN-2018  mohamms2(Mohammed Reyaz Shaik )       Sprint#18 Release             1.8  VAVNI schema objects  references changes to CRPADM schema objects.
   |02-APR-2018  sridvasu(Sridevi Vasudevan)           Sprint#19 Release             2.1  As part of US164572 Rohs/NRohs Automation
   |09-APR-2018  sridvasu(Sridevi Vasudevan)           Sprint#19 Release             2.2  Added to send mail to inventory admins when shortage in RoHS/NRoHS adjustments as part of US164572
   |04-MAY-2018  sridvasu(Sridevi Vasudevan)           Sprint#19 Release             2.3  Added update statement to flag all the records to Y and Summing up the quantity for the PIDs which are having from and to locations are same
   |10-MAY-2018  sridvasu(Sridevi Vasudevan)           Sprint#20 Release             2.4  Added condition for Negative manual adjustments should not be performed for the PIDs which are having same day shipment
  |30-MAY-2018  sridvasu(Sridevi Vasudevan)           Sprint#20 Release              2.5  Rolled back same day shipping changes
  |03-AUG-2018  sridvasu(Sridevi Vasudevan)            Sept Release                 2.6  Modified Cursor query in RC_INV_EX_FGI_ROHS_NROHS_MOVE
  |27-AUG-2018  sridvasu(Sridevi Vasudevan)            Sept Release                 2.7  Commented Adhoc script to clear -VE FG in the main procedure and created new procedure
  |19-JUN-2018  mohamms2(Mohammed Reyaz Shaik)        UserStory#US193034(Sprint#21)  2.8  As part of Yield - Zero percent yield issue
  |24-JUN-2018  mohamms2(Mohammed Reyaz Shaik)        UserStory#US193036(Sprint#21)  2.9  As part of yield calculation ligic changes for considering refresh_yield.
  |15-OCT-2018  sridvasu(Sridevi Vasudevan)           UserStory#US193036(Sprint#21)  3.0  Stop publishing DGI to CCW for Retail
  |15-OCT-2018  csirigir(Chandra Shekar Reddy )      US193036(Sprint#21)             3.1  Commented Existing Outlet procedure and added new procedure as part of Selling FGI only requirements for Oct 27 Release
  |30-OCT-2018  csirigir(Chandra)                     Nov-18 Release Changes         3.2  Added instance name in the subject line for non-prod instances as part of Nov'18 release.
  |17-JAN-2019  sridvasu(Sridevi Vasudevan)                                          3.3  Added new procedure RC_INV_RF_MAIN to check delta job dependency
  |08-MAR-2019  sridvasu(Sridevi Vasudevan)                                          3.3  Modified FG load as part of Block FGI Q3FY19 Orders
  |14-MAY-2019  karsivak(Karthick Sivakumar)                                         3.4  Modified code to hold LRO Rohs/Nrohs
  |11-MAY-2020  sneyadav(Snehalata Yadav)              US390864                      3.5  Modified FVE FC01 feed processing
  |11-MAY-2020  sumravik(Sumesh Ravikumar)             US390864                      3.5  Added Mail notification for FVE FC01 feed processing
  |24-AUG-2020  sumravik(Sumesh Ravikumar)             US438804                      3.6  Commented the existing mail notification code present in RC_INV_RF_DGI_FGI_LOAD
 ==================================================================================================*/
   G_STEP                    VARCHAR2 (5000);
   G_FETCH_LIMIT             NUMBER;
   G_UPDATED_BY              VARCHAR2 (100);
   G_TO                      VARCHAR2 (200) := 'refreshcentral-support@cisco.com';
   G_ERROR_MSG               VARCHAR2 (300);
   G_PROC_NAME               VARCHAR2 (100);
   G_START_TIME              DATE;
   G_ACT_SUPPORT             VARCHAR2 (100) := 'remarketing-support@cisco.com';
   G_OUTLET_ALLOC_REQUIRED   VARCHAR2 (2) := 'N'; -->> Changed Outlet flag from Y to N as part of Selling FGI only requirements for Oct 27 Release
   lv_status                 VARCHAR2 (25);
   v_message                 VARCHAR2 (32767);

   PROCEDURE RF_MAIN (P_STATUS_MESSAGE OUT VARCHAR2, P_SITE_CODE IN VARCHAR2)
   IS
      L_PROCESS_ID                     VARCHAR2 (100);
      L_START_TIME                     DATE;
      L_END_TIME                       DATE;
      L_INTRANSIT_FLAG                 VARCHAR2 (10) := 'N';
      L_DELTA_PREV_EXE_TIME            TIMESTAMP;
      L_UNPRO_CNT                      NUMBER;
      L_LRO_UNPRO_CNT                  NUMBER;
      L_PROCEDURE_NAME                 VARCHAR2 (300);
      L_WARNING_MSG                    VARCHAR2 (800);
      L_CONS_REM_DELTA_LAST_EXE_TIME   TIMESTAMP;
      L_LAST_CONS_REMIN                NUMBER (10, 8);
      L_C3_RECORD_COUNT                NUMBER;
      L_FGI_RECORD_COUNT               NUMBER;
      L_C3_MIN_REC_COUNT               NUMBER := 1000;
      L_FVE_CG1_QUANTITY               NUMBER;    -- Added as part of US390864
      L_LRO_CG1_QUANTITY               NUMBER; -- Added as part of Apr17 Sprint Release
      L_LRO_FGI_QUANTITY               NUMBER; -- Added as part of Apr17 Sprint Release
      -- L_FVE_FGI_QUANTITY               NUMBER; -- Added as part of Apr17 Sprint Release -- commented as part of US390864
      L_LRO_CG1_EXCEPTION_QTY          NUMBER; -- Added as part of May-17 Sprint Release
      L_FVE_REC_QUANTITY               NUMBER;    -- Added as part of US390864
      LV_CHL_CNT                       NUMBER; -- Added as part of Sept Release
      /* Start Added as part of LRO Rohs/NRohs hold */
      LV_RHS_NRHS_PR_FLAG              VARCHAR2 (10);
      lv_hold                          VARCHAR2 (20);
      lv_rohs_feed_date                DATE;
      lv_lro_process_date              DATE;
      lv_prev_rohs_process_date        DATE;
      L_LRO_START_TIME                 DATE;
      L_LRO_HOLD_TIME_CROSSED          VARCHAR2 (10);
      lv_hold_time                     DATE;
      L_CG1_START_DATE                 NUMBER;    -- Added as part of US390864
      L_CG1_END_DATE                   NUMBER;    -- Added as part of US390864
   /* End Added as part of LRO Rohs/NRohs hold */
   BEGIN
      G_PROC_NAME := 'RMKTGADM.RC_INV_DELTA_LOAD_RF.RF_MAIN';

      -- get the process start time
      SELECT SYSDATE INTO G_START_TIME FROM DUAL;

      -->> Start Added update statement to cron control info table for delta job dependency checks on 17-Jan-2019

      UPDATE RMKTGADM.CRON_CONTROL_INFO
         SET CRON_START_TIMESTAMP = G_START_TIME,
             CRON_END_TIMESTAMP = SYSDATE,
             CRON_STATUS = 'STARTED'
       WHERE     CRON_NAME = 'RF_MAIN'
             AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'RF_MAIN';

      COMMIT;

      -->> End Added update statement to cron control info table for delta job dependency checks on 17-Jan-2019

      -- get In transit included property flag
      SELECT PROPERTY_VALUE
        INTO L_INTRANSIT_FLAG
        FROM RMKTGADM.CCW_SSOT_COMMON_PROPERTIES
       WHERE PROPERTY_TYPE = 'INTRANSIT_INCLUDED';

      -- get global value for cursor fetch limit
      SELECT PROPERTY_VALUE
        INTO G_FETCH_LIMIT
        FROM RMKTGADM.CCW_SSOT_COMMON_PROPERTIES
       WHERE PROPERTY_TYPE = 'CURSOR_FETCH_LIMIT';

      -- get the UPDATED_BY value
      SELECT PROPERTY_VALUE
        INTO G_UPDATED_BY
        FROM RMKTGADM.CCW_SSOT_COMMON_PROPERTIES
       WHERE PROPERTY_TYPE = 'UPDATED_BY';

      -- get the last successful execution CRON TIMESTAMP FOR CCW_INV_DELTA_FEED
      BEGIN
         SELECT CRON_START_TIMESTAMP
           INTO L_DELTA_PREV_EXE_TIME
           FROM RMKTGADM.CRON_CONTROL_INFO
          WHERE     CRON_NAME = 'RF_MAIN'
                AND CRON_STATUS = 'SUCCESS'
                AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'RF_MAIN';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            SELECT MAX (CHL_END_TIMESTAMP)
              INTO L_DELTA_PREV_EXE_TIME
              FROM RMKTGADM.CRON_HISTORY_LOG
             WHERE CHL_CRON_NAME = 'RF_MAIN' AND CHL_STATUS = 'SUCCESS';
      END;

      --get the last successful execution time of CONS_RMINDRS_DELTA_DGI_PROC

      SELECT NVL (MAX (CHL_START_TIMESTAMP), SYSDATE - 2) -- NVL to handle the first time load
        INTO L_CONS_REM_DELTA_LAST_EXE_TIME
        FROM RMKTGADM.CRON_HISTORY_LOG
       WHERE     CHL_CRON_NAME = 'RC_INV_RF_DGI_GET_REMINDERS'
             AND CHL_STATUS = 'SUCCESS';

      /* Start Commented to stop publishing DGI to CCW for Retail on 15-OCT-2018 */

      -->> Check for the DG Inventory Availability
      --      SELECT COUNT (1)
      --        INTO L_C3_RECORD_COUNT
      --        FROM CRPADM.RC_INV_C3_TBL --VAVNI_CISCO_RSCM_TEMP.RSCM_TMP_C3_INV_TBL --RSCM_TMP_C3_INV_TBL_TEST
      --       WHERE     PART_ID LIKE '%RF'
      --             AND PART_ID NOT IN (SELECT REFRESH_PART_NUMBER
      --                                   FROM RC_INV_EXCLUDE_PIDS);

      /* End Commented to stop publishing DGI to CCW for Retail on 15-OCT-2018 */

      -->> Check for the FG Inventory Availability


      SELECT COUNT (*)
        INTO L_FGI_RECORD_COUNT
        FROM (SELECT REFRESH_PART_NUMBER, PROCESSED_STATUS, HUB_LOCATION
                FROM CRPSC.SC_FC01_OH_DELTA_LRO_HIST
               WHERE RECEIVED_QTY > 0
              UNION ALL
              SELECT REFRESH_PART_NUMBER, PROCESSED_STATUS, HUB_LOCATION
                FROM CRPSC.RC_FC01_OH_DELTA_FVE_HIST --changed as part of US390864
               WHERE RECEIVED_QTY > 0            /*AND PO_NUMBER LIKE 'CSC%'*/
                                     ) HIST    --commented as part of US390864
             INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                ON (    HIST.REFRESH_PART_NUMBER = PM.REFRESH_PART_NUMBER
                    AND PM.PROGRAM_TYPE = 0)
       WHERE     HIST.PROCESSED_STATUS = 'N'
             AND HIST.HUB_LOCATION = P_SITE_CODE
             AND HIST.REFRESH_PART_NUMBER NOT IN (SELECT REFRESH_PART_NUMBER
                                                    FROM RC_INV_EXCLUDE_PIDS);


      IF P_SITE_CODE = 'LRO'
      THEN
         /*** Start Added as part of Apr-17 Sprint Release***/

         SELECT NVL (SUM (LN.PO_RECEIVED_QTY), 0) --changed as part of US390864
           INTO L_LRO_CG1_QUANTITY
           FROM XXSCM.XXSCM_MK_4B2_LN_IB_IFACE@CG1PRD.CISCO.COM LN
                INNER JOIN
                XXSCM.XXSCM_MK_4B2_HDR_IB_IFACE@CG1PRD.CISCO.COM HD
                   ON (LN.MESSAGE_ID = HD.MESSAGE_ID)
                INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                   ON (LN.END_USER_PRODUCT_ID = PM.TAN_ID) -- AND PM.PROGRAM_TYPE = 0)
          WHERE     1 = 1
                AND PM.PROGRAM_TYPE = 0
                AND LN.MESSAGE_ID LIKE 'LRO%'
                AND TRUNC (LN.CREATION_DATE) BETWEEN --             '03-SEP-2019'  AND '04-SEP-2019' --Added for testing
                                                     (SELECT MAX (
                                                                TRUNC (
                                                                   RECORD_CREATED_ON))
                                                        FROM CRPSC.SC_FC01_OH_DELTA_LRO_HIST
                                                       WHERE     PROCESSED_STATUS =
                                                                    'Y'
                                                             AND REFRESH_PART_NUMBER NOT IN
                                                                    (SELECT REFRESH_PART_NUMBER
                                                                       FROM RC_INV_EXCLUDE_PIDS)
                                                             AND REFRESH_PART_NUMBER LIKE
                                                                    '%RF')
                                                 AND TRUNC (SYSDATE - 1)  
                AND HD.MESSAGE_TYPE IN ('R2AS')
                AND END_USER_PRODUCT_ID IN
                       (SELECT TAN_ID
                          FROM CRPADM.RC_PRODUCT_MASTER
                         WHERE REFRESH_PART_NUMBER NOT IN
                                  (SELECT REFRESH_PART_NUMBER
                                     FROM RC_INV_EXCLUDE_PIDS));
      END IF;

      /*** Start Added as part of US390864***/
      --      IF P_SITE_CODE = 'FVE'
      --      THEN
      --         SELECT NVL (SUM (LN.PO_RECEIVED_QTY), 0)
      --           INTO L_FVE_CG1_QUANTITY
      --           FROM XXSCM.XXSCM_MK_4B2_LN_IB_IFACE@CG1PRD.CISCO.COM LN
      --                INNER JOIN XXSCM.XXSCM_MK_4B2_HDR_IB_IFACE@CG1PRD.CISCO.COM HD
      --                   ON (LN.MESSAGE_ID = HD.MESSAGE_ID)
      --                INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
      --                   ON (LN.END_USER_PRODUCT_ID = PM.TAN_ID)
      --          WHERE     1 = 1
      --                AND PM.PROGRAM_TYPE = 0
      --                AND LN.MESSAGE_ID LIKE 'FVE%'
      --                AND TRUNC (LN.CREATION_DATE) BETWEEN (SELECT MAX (
      --                                                                TRUNC (
      --                                                                   RECORD_CREATED_ON))
      --                                                        FROM CRPSC.RC_FC01_OH_DELTA_FVE_HIST
      --                                                       WHERE     PROCESSED_STATUS =
      --                                                                    'Y'
      --                                                             AND REFRESH_PART_NUMBER NOT IN
      --                                                                    (SELECT REFRESH_PART_NUMBER
      --                                                                       FROM RC_INV_EXCLUDE_PIDS)
      --                                                             AND REFRESH_PART_NUMBER LIKE
      --                                                                    '%RF')
      --                                                 AND TRUNC (SYSDATE - 1)
      --                AND HD.MESSAGE_TYPE IN ('R2AS')
      --                AND END_USER_PRODUCT_ID IN
      --                       (SELECT TAN_ID
      --                          FROM CRPADM.RC_PRODUCT_MASTER
      --                         WHERE REFRESH_PART_NUMBER NOT IN
      --                                  (SELECT REFRESH_PART_NUMBER
      --                                     FROM RC_INV_EXCLUDE_PIDS));
      --      END IF;
      /*** Start Added as part of US390864***/
      IF P_SITE_CODE = 'FVE'
      THEN
         SELECT PROPERTY_VALUE
           INTO L_CG1_START_DATE
           FROM rmktgadm.ccw_ssot_common_properties
          WHERE PROPERTY_TYPE = 'FVE_FC01_CG1_START_DATE';

         SELECT PROPERTY_VALUE
           INTO L_CG1_END_DATE
           FROM rmktgadm.ccw_ssot_common_properties
          WHERE PROPERTY_TYPE = 'FVE_FC01_CG1_END_DATE';

         SELECT NVL (SUM (po_received_qty), 0)
           INTO L_FVE_CG1_QUANTITY
           FROM XXSCM.XXSCM_MK_4B2_LN_IB_IFACE@CG1PRD.CISCO.COM LN
                INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                   ON (LN.END_USER_PRODUCT_ID = PM.TAN_ID)
          WHERE     PM.PROGRAM_TYPE = 0
                AND message_id LIKE 'FVE%'
                AND creation_date >=
                       (SELECT dat + L_CG1_START_DATE / 24
                          FROM (SELECT TRUNC (SYSDATE - 1) dat FROM DUAL))
                AND CREATION_DATE <=
                       (SELECT dat + L_CG1_END_DATE / 24
                          FROM (SELECT TRUNC (SYSDATE) dat FROM DUAL))
                AND END_USER_PRODUCT_ID LIKE '74%'
                AND PO_NUMBER LIKE 'CSC%';
      END IF;

      /*** End Added as part of US390864***/

      --              SELECT NVL(SUM (decode( HD.MESSAGE_TYPE, 'R2AS', LN.PO_RECEIVED_QTY , 'SRTV' , LN.PO_REQUIRED_QTY ) ), 0 )
      --                INTO L_LRO_CG1_QUANTITY
      --                FROM XXSCM.XXSCM_MK_4B2_LN_IB_IFACE@TS1CG1.CISCO.COM LN--DV1CG1.CISCO.COM LN--CG1PRD.CISCO.COM LN
      --                    INNER JOIN XXSCM.XXSCM_MK_4B2_HDR_IB_IFACE@TS1CG1.CISCO.COM HD--CG1PRD.CISCO.COM HD
      --                       ON (LN.MESSAGE_ID = HD.MESSAGE_ID)
      --                    INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
      --                       ON (LN.END_USER_PRODUCT_ID = PM.TAN_ID) -- AND PM.PROGRAM_TYPE = 0)
      --              WHERE     1 = 1
      --                    AND PM.PROGRAM_TYPE = 0
      --                    AND LN.MESSAGE_ID LIKE 'LRO%'
      --                    AND TRUNC (LN.CREATION_DATE)
      --                    BETWEEN '06-OCT-2016' and '06-OCT-2016'
      ----                        (   select max(trunc(record_created_on)) from CRPSC.SC_FC01_OH_DELTA_LRO_HIST
      ----                            where processed_status = 'Y'
      ----                            and REFRESH_PART_NUMBER NOT IN (SELECT REFRESH_PART_NUMBER FROM RC_INV_EXCLUDE_PIDS)
      ----                            and REFRESH_PART_NUMBER like '%RF'
      ----                        )
      ----                    AND trunc(SYSDATE - 1 )
      --                    AND HD.MESSAGE_TYPE IN ('R2AS','SRTV')
      --                    AND END_USER_PRODUCT_ID IN (SELECT TAN_ID FROM CRPADM.RC_PRODUCT_MASTER
      --                                                        where REFRESH_PART_NUMBER NOT IN (SELECT REFRESH_PART_NUMBER
      --                                                                                            FROM RC_INV_EXCLUDE_PIDS  ));

      /*** End Added as part of Apr-17 Sprint Release***/

      IF P_SITE_CODE = 'LRO'
      THEN
         /*** Start Added as part of Apr-17 Sprint Release***/
         SELECT NVL (SUM (RECEIVED_QTY), 0)
           INTO L_LRO_FGI_QUANTITY
           FROM CRPSC.SC_FC01_OH_DELTA_LRO_HIST HIST
          WHERE     HIST.PROCESSED_STATUS = 'N'
                AND HIST.RECEIVED_QTY > 0
                AND HIST.REFRESH_PART_NUMBER LIKE '%RF'
                --             AND TRUNC (RCT_CREATION_DATE) >=
                --                    (SELECT TRUNC (CRON_END_TIMESTAMP)
                --                       FROM RMKTGADM.CRON_CONTROL_INFO
                --                      WHERE CRON_NAME = 'RF_MAIN' AND CRON_STATUS = 'SUCCESS')
                AND HIST.REFRESH_PART_NUMBER NOT IN
                       (SELECT REFRESH_PART_NUMBER
                          FROM RC_INV_EXCLUDE_PIDS);
      /*** End Added as part of Apr-17 Sprint Release***/
      END IF;

      IF P_SITE_CODE = 'FVE'
      THEN
         /*** Start Added as part of US390864***/
         SELECT NVL (SUM (RECEIVED_QTY), 0)
           INTO L_FVE_REC_QUANTITY
           FROM CRPSC.RC_FC01_OH_DELTA_FVE_HIST HIST
          WHERE     HIST.PROCESSED_STATUS = 'N'
                AND HIST.RECEIVED_QTY > 0
                AND HIST.REFRESH_PART_NUMBER LIKE '%RF'
                AND HIST.REFRESH_PART_NUMBER NOT IN
                       (SELECT REFRESH_PART_NUMBER
                          FROM RC_INV_EXCLUDE_PIDS);
      /*** End Added as part of US390864***/
      END IF;

      -- commented as part of US390864
      /*** Start Added as part of Apr-17 Sprint Release***/

      --      SELECT NVL (SUM (RECEIVED_QTY), 0)
      --        INTO L_FVE_FGI_QUANTITY
      --        FROM CRPSC.SC_FB02_DELTA_FVE_HIST HIST
      --       WHERE     HIST.PROCESSED_STATUS = 'N'
      --             AND HIST.RECEIVED_QTY > 0
      --             AND HIST.PO_NUMBER LIKE 'CSC%'
      --             AND REFRESH_PART_NUMBER LIKE '%RF'
      --             --                         AND TRUNC (RECORD_CREATED_ON) >=
      --             --                                        (SELECT TRUNC (CRON_END_TIMESTAMP)
      --             --                                           FROM RMKTGADM.CRON_CONTROL_INFO
      --             --                                          WHERE CRON_NAME = 'RF_MAIN'
      --             --                                            AND CRON_STATUS = 'SUCCESS')
      --             AND HIST.REFRESH_PART_NUMBER NOT IN (SELECT REFRESH_PART_NUMBER
      --                                                    FROM RC_INV_EXCLUDE_PIDS);

      /*** End Added as part of Apr-17 Sprint Release***/


      /***   Start Added As part of May-17 Sprint Release LRO CG1 Exception Qty           ***/

      SELECT RC_INV_CONTROL_VALUE
        INTO L_LRO_CG1_EXCEPTION_QTY
        FROM RC_INV_CONTROL
       WHERE RC_INV_CONTROL_ID = 9; --RC_INV_CONTROL_NAME = 'LRO CG1 EXCEPTION QTY'; --commented as part of sprint14(Aug Release)and added RC_INV_CONTROL_ID


      /***   End Added As part of May-17 Sprint Release LRO CG1 Exception Qty           ***/

      /* Start Added as part of LRO Rohs/NRohs hold */

      BEGIN
         SELECT 'Y'
           INTO LV_RHS_NRHS_PR_FLAG
           FROM CRPSC.RC_SCD_LRO_ROHS_FILE_LOG
          WHERE     STATUS = 'SUCCESS'
                AND RECORD_CREATED_ON > TRUNC (SYSDATE)
                AND RECORD_CREATED_ON =
                       (SELECT MAX (RECORD_CREATED_ON)
                          FROM CRPSC.RC_SCD_LRO_ROHS_FILE_LOG);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            LV_RHS_NRHS_PR_FLAG := 'N';
      END;

      SELECT CHL_STATUS
        INTO lv_hold
        FROM RMKTGADM.CRON_HISTORY_LOG
       WHERE     CHL_CRON_NAME = 'RC_INV_RF_FGI_EXTRACT'
             AND CHL_COMMENTS = P_SITE_CODE
             AND CHL_ID =
                    (SELECT MAX (CHL_ID)
                       FROM RMKTGADM.CRON_HISTORY_LOG
                      WHERE     CHL_CRON_NAME = 'RC_INV_RF_FGI_EXTRACT'
                            AND CHL_COMMENTS = P_SITE_CODE);


      SELECT TO_DATE (
                   TO_CHAR (TO_CHAR (TRUNC (SYSDATE), 'mm/dd/yyyy'))
                || ' '
                || TO_CHAR ('07:00:00'),
                'mm/dd/yyyy hh24:mi:ss')
        INTO lv_hold_time
        FROM DUAL;

      IF SYSDATE >= lv_hold_time
      THEN
         L_LRO_HOLD_TIME_CROSSED := 'Y';
      ELSE
         L_LRO_HOLD_TIME_CROSSED := 'N';
      END IF;

      /* End Added as part of LRO Rohs/NRohs hold */

      /*-----------------------------------------------------------------------------------------*/
      -- IF     IF L_C3_RECORD_COUNT > 0 AND (L_FGI_RECORD_COUNT < = L_CGI_RECORD_COUNT+20)

      IF -- L_C3_RECORD_COUNT > 0  AND  -- Commented to stop publishing DGI to CCW for Retail on 15-OCT-2018
        L_FGI_RECORD_COUNT < 7000
         AND (   (L_FVE_REC_QUANTITY > 0)          --added as part of US390864
              OR (    L_LRO_FGI_QUANTITY > 0
                  AND L_LRO_FGI_QUANTITY <=
                         L_LRO_CG1_QUANTITY + L_LRO_CG1_EXCEPTION_QTY))  
      THEN
         /* Start Commented to stop publishing DGI to CCW for Retail on 15-OCT-2018 */

         -- DGI
         --         RC_INV_RF_DGI_EXTRACT (L_INTRANSIT_FLAG, P_SITE_CODE);
         --         RC_INV_RF_DGI_HISTORY (P_SITE_CODE);
         --         RC_INV_RF_DGI_DELTA (P_SITE_CODE);
         --         RC_INV_RF_DGI_PUT_REMINDERS;
         --         RC_INV_RF_DGI_GET_REMINDERS;

         /* End Commented to stop publishing DGI to CCW for Retail on 15-OCT-2018 */
         IF (L_FVE_REC_QUANTITY > L_FVE_CG1_QUANTITY) AND P_SITE_CODE = 'FVE'
         THEN
            G_ERROR_MSG :=
                  '<HTML>FVE FGI Quantity is more than the FVE CG1 Quantity:
                        <br/> <br/>
                        <b>FVE FGI Quantity :</b>
                         <HTML/>'
               || L_FVE_REC_QUANTITY
               || '<HTML> <br/><b>FVE CG1 Quantity :</b> <HTML/>'
               || L_FVE_CG1_QUANTITY;
            RC_INV_RF_SEND_ERROR_EMAIL (G_PROC_NAME, G_ERROR_MSG);
         END IF;

         -- FGI
         IF    LV_RHS_NRHS_PR_FLAG = 'Y'
            OR P_SITE_CODE = 'FVE'
            OR L_LRO_HOLD_TIME_CROSSED = 'Y'
         THEN
            RC_INV_RF_FGI_EXTRACT (P_SITE_CODE);
            RC_INV_RF_DGI_FGI_LOAD (P_SITE_CODE);
         ELSE
            INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                   CHL_STATUS,
                                                   CHL_START_TIMESTAMP,
                                                   CHL_END_TIMESTAMP,
                                                   CHL_CRON_NAME,
                                                   CHL_COMMENTS,
                                                   CHL_CREATED_BY)
                 VALUES (SEQ_CHL_ID.NEXTVAL,
                         'HOLD',
                         SYSDATE,
                         SYSDATE,
                         'RC_INV_RF_FGI_EXTRACT',
                         P_SITE_CODE,                                  --NULL,
                         'RC_INV_DELTA_LOAD_RF');
         END IF;
      ELSIF --  L_C3_RECORD_COUNT > 0 AND  -- Commented to stop publishing DGI to CCW for Retail on 15-OCT-2018
            (      (L_LRO_FGI_QUANTITY >
                       L_LRO_CG1_QUANTITY + L_LRO_CG1_EXCEPTION_QTY)
                OR L_FGI_RECORD_COUNT > 7000)
            AND P_SITE_CODE = 'LRO'
      THEN
         /* Start Commented to stop publishing DGI to CCW for Retail on 15-OCT-2018 */

         -- DGI
         --         RC_INV_RF_DGI_EXTRACT (L_INTRANSIT_FLAG, P_SITE_CODE);
         --         RC_INV_RF_DGI_HISTORY (P_SITE_CODE);
         --         RC_INV_RF_DGI_DELTA (P_SITE_CODE);
         --         RC_INV_RF_DGI_PUT_REMINDERS;
         --         RC_INV_RF_DGI_GET_REMINDERS;
         --         RC_INV_RF_DGI_FGI_LOAD (P_SITE_CODE);

         /* End Commented to stop publishing DGI to CCW for Retail on 15-OCT-2018 */

         -->> updating non-matched recs to E

         UPDATE CRPSC.SC_FC01_OH_DELTA_LRO_HIST
            SET PROCESSED_STATUS = 'E'
          WHERE     PROCESSED_STATUS = 'N'
                AND REFRESH_PART_NUMBER LIKE '%RF'
                AND REFRESH_PART_NUMBER NOT IN (SELECT REFRESH_PART_NUMBER
                                                  FROM RC_INV_EXCLUDE_PIDS);

         -- AND TRUNC (RECORD_UPDATED_ON) = TRUNC (SYSDATE);

         COMMIT;

         -->>

         --         L_PROCEDURE_NAME := 'RMKTGADM.RC_DELTA_INVENTORY_LOAD_RF.RF_MAIN';

         G_ERROR_MSG :=
               '<HTML>LRO FGI Quantity is more than the LRO CG1 Quantity:
                <br/> <br/>
                <b>LRO FGI Quantity :</b>
                 <HTML/>'
            || L_LRO_FGI_QUANTITY
            || '<HTML> <br/><b>LRO CG1 Quantity :</b> <HTML/>'
            || L_LRO_CG1_QUANTITY;
         RC_INV_RF_SEND_ERROR_EMAIL (G_PROC_NAME, G_ERROR_MSG);
      /* Start Commented to stop publishing DGI to CCW for Retail on 15-OCT-2018 */

      --      ELSIF L_C3_RECORD_COUNT > 0 AND L_FGI_RECORD_COUNT = 0
      --      THEN
      --         -- DGI
      --         RC_INV_RF_DGI_EXTRACT (L_INTRANSIT_FLAG, P_SITE_CODE);
      --         RC_INV_RF_DGI_HISTORY (P_SITE_CODE);
      --         RC_INV_RF_DGI_DELTA (P_SITE_CODE);
      --         RC_INV_RF_DGI_PUT_REMINDERS;
      --         RC_INV_RF_DGI_GET_REMINDERS;
      --         RC_INV_RF_DGI_FGI_LOAD (P_SITE_CODE);
      --
      --         --send warning mail to support team
      --         L_PROCEDURE_NAME :=
      --               'RMKTGADM.RC_INV_DELTA_LOAD_RF.RF_MAIN '
      --            || P_SITE_CODE
      --            || '-FG Inventory not received,';
      --
      --         L_WARNING_MSG :=
      --               'POE has not received the RETAIL Detla FGI feed from <b> BTS '
      --            || P_SITE_CODE
      --            || ' </b> Node, Since <b> '
      --            || TO_CHAR (L_DELTA_PREV_EXE_TIME, 'DD-Mon-YYYY HH:MI:SS PM')
      --            || '</b>';
      --      --  RC_INV_RF_SEND_WARNING_EMAIL (L_PROCEDURE_NAME, L_WARNING_MSG);  --commented as part of Sprint14 release (Handling alert mechanism in scheduled ETL itself)

      /* End Commented to stop publishing DGI to CCW for Retail on 15-OCT-2018 */

      /* Start Commented to stop publishing DGI to CCW for Retail on 15-OCT-2018 as this scenario is already covered */

      --      ELSIF    L_C3_RECORD_COUNT = 0 AND
      --         L_FGI_RECORD_COUNT < 7000
      --            AND (   L_FVE_FGI_QUANTITY > 0
      --                 OR (    L_LRO_FGI_QUANTITY > 0
      --                     AND L_LRO_FGI_QUANTITY <=
      --                            L_LRO_CG1_QUANTITY + L_LRO_CG1_EXCEPTION_QTY))
      --      THEN
      --         -- FGI
      --         RC_INV_RF_FGI_EXTRACT (P_SITE_CODE);
      --         RC_INV_RF_DGI_FGI_LOAD (P_SITE_CODE);

      --send warning mail to support team
      --         L_PROCEDURE_NAME := 'RMKTGADM.RC_INV_DELTA_LOAD_RF.RF_MAIN';
      --
      --         L_WARNING_MSG :=
      --               'POE has not received data in <b>C3 Inventory</b> to Prcocess for <b>CCW</b> Delta Feed '
      --            || TO_CHAR (L_DELTA_PREV_EXE_TIME, 'DD-Mon-YYYY HH:MI:SS PM');
      --         RC_INV_RF_SEND_WARNING_EMAIL (L_PROCEDURE_NAME, L_WARNING_MSG);
      --      ELSIF L_C3_RECORD_COUNT = 0 AND L_FGI_RECORD_COUNT = 0
      --      THEN
      --         -- DBMS_OUTPUT.put_line (' When No C3 and No  BTS  (5)');
      --
      --         G_ERROR_MSG :=
      --            '<b>POE</b> has not received data from <b>BTS</b> and <b>C3 Inventory</b>  to Prcocess for <b> CCW Delta</b> Feed ';
      --
      --         --         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
      --         --                                                CHL_STATUS,
      --         --                                                CHL_START_TIMESTAMP,
      --         --                                                CHL_END_TIMESTAMP,
      --         --                                                CHL_CRON_NAME,
      --         --                                                CHL_COMMENTS,
      --         --                                                CHL_CREATED_BY)
      --         --              VALUES (SEQ_CHL_ID.NEXTVAL,
      --         --                      'FAILED',
      --         --                      G_START_TIME,
      --         --                      SYSDATE,
      --         --                      'RF_MAIN',
      --         --                      G_ERROR_MSG,
      --         --                      'RC_INV_DELTA_LOAD_RF');
      --         --
      --         --
      --         --
      --         --         UPDATE RMKTGADM.CRON_CONTROL_INFO
      --         --            SET CRON_END_TIMESTAMP = SYSDATE, CRON_STATUS = 'FAILED'
      --         --          WHERE CRON_NAME = 'RF_MAIN'
      --         --            AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'RF_MAIN';
      --         --
      --         --         COMMIT;
      --
      --         RC_INV_RF_SEND_WARNING_EMAIL (G_PROC_NAME, G_ERROR_MSG);

      /* End Commented to stop publishing DGI to CCW for Retail on 15-OCT-2018 as this scenario is already covered */

      --ROLLBACK;commented 28-Jun-17

      /*** End Added as part of US390864***/
      /* ELSIF     (   (L_FVE_REC_QUANTITY >
                         L_FVE_CG1_QUANTITY + L_LRO_CG1_EXCEPTION_QTY)
                  OR L_FGI_RECORD_COUNT > 7000)
             AND P_SITE_CODE = 'FVE'
       THEN
          --updating non-matched recs to E

          UPDATE CRPSC.RC_FC01_OH_DELTA_FVE_HIST
             SET PROCESSED_STATUS = 'E'
           WHERE     PROCESSED_STATUS = 'N'
                 AND REFRESH_PART_NUMBER LIKE '%RF'
                 AND REFRESH_PART_NUMBER NOT IN (SELECT REFRESH_PART_NUMBER
                                                   FROM RC_INV_EXCLUDE_PIDS);

          COMMIT;

          G_ERROR_MSG :=
                '<HTML>FVE FGI Quantity is more than the FVE CG1 Quantity:
                         <br/> <br/>
                         <b>FVE FGI Quantity :</b>
                          <HTML/>'
             || L_FVE_REC_QUANTITY
             || '<HTML> <br/><b>FVE CG1 Quantity :</b> <HTML/>'
             || L_FVE_CG1_QUANTITY;
          RC_INV_RF_SEND_ERROR_EMAIL (G_PROC_NAME, G_ERROR_MSG);
       /*** End Added as part of US390864***/

      /* Start Added as part of LRO Rohs/NRohs hold */
      ELSIF L_LRO_FGI_QUANTITY = 0
      THEN
         SELECT MAX (CREATED_ON)
           INTO lv_rohs_feed_date
           FROM CRPSC.RC_DLP_ROHS_NONROHS
          WHERE PROCESSED_FLAG = 'N';

         SELECT MAX (CREATED_ON)
           INTO lv_lro_process_date
           FROM RC_INV_DELTA_SPLIT_LOG_HIST
          WHERE PRODUCT_TYPE = 'R' AND SOURCE_SYSTEM = 'SC-FC01-RECEIPTS-LRO';

         SELECT MAX (CREATED_ON)
           INTO lv_prev_rohs_process_date
           FROM RMK_INVENTORY_LOG_STG
          WHERE POE_BATCH_ID = 'RC_INV_RF_FGI_ROHS_NROHS_MOVE';


         IF     lv_prev_rohs_process_date < lv_lro_process_date
            AND TRUNC (lv_rohs_feed_date) = TRUNC (lv_lro_process_date)
         THEN
            RC_INV_RF_FGI_ROHS_NROHS_MOVE;
            RC_STR_INV_MASK_ADJ ('ROHS_NONROHS_ADJUSTMENT', lv_status);
         END IF;
      /* End Added as part of LRO Rohs/NRohs hold */
      END IF;

      -->> Start commented below update statement and place after execution of RC_INV_EX_EOS_PID_QTY_REVOKE on 17-Jan-2019

      --      UPDATE RMKTGADM.CRON_CONTROL_INFO
      --         SET CRON_START_TIMESTAMP = G_START_TIME,
      --             CRON_END_TIMESTAMP = SYSDATE,
      --             CRON_STATUS = 'SUCCESS'
      --       WHERE     CRON_NAME = 'RF_MAIN'
      --             AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'RF_MAIN';

      -->> End commented below update statement and place after execution of RC_INV_EX_EOS_PID_QTY_REVOKE on 17-Jan-2019

      INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                             CHL_STATUS,
                                             CHL_START_TIMESTAMP,
                                             CHL_END_TIMESTAMP,
                                             CHL_CRON_NAME,
                                             CHL_COMMENTS,
                                             CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'SUCCESS',
                   G_START_TIME,
                   SYSDATE,
                   'RF_MAIN',
                   P_SITE_CODE,                                       -- NULL,
                   'RC_INV_DELTA_LOAD_RF');


      -- adhoc script to negate available to reserve dgi for T-4 pids (End of Support in next 4 months)
      --      RC_INV_RF_EOS_PID_QTY_REVOKE; -- added by mohamms2 as on 05-OCT-2017 for User Story US134524 in Sprint 15 -- Commented to stop publishing DGI to CCW for Retail on 15-OCT-2018

      /* Start Commenting Adhoc script to clear -VE FG in the main procedure and created new procedure on 27th Aug 2018 by sridvasu */

      --->> Adhoc Script to Clear -VE FG :

      --      INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG (INVENTORY_LOG_ID,
      --                                                  PART_NUMBER,
      --                                                  NEW_FGI,
      --                                                  NEW_DGI,
      --                                                  ROHS_COMPLIANT,
      --                                                  SITE_CODE,
      --                                                  PROCESS_STATUS,
      --                                                  UPDATED_ON,
      --                                                  UPDATED_BY,
      --                                                  CREATED_ON,
      --                                                  CREATED_BY,
      --                                                  POE_BATCH_ID,
      --                                                  PROGRAM_TYPE)
      --         SELECT RC_INV_LOG_PK_SEQ.NEXTVAL,
      --                PART_NUMBER,
      --                AVAILABLE_FGI * -1 NEW_FGI,
      --                0                  NEW_DGI,
      --                ROHS_COMPLIANT,
      --                SITE_CODE,
      --                'N'                PROCESS_STATUS,
      --                SYSDATE            UPDATED_ON,
      --                'POEADMIN'         UPDATED_BY,
      --                SYSDATE            CREATED_ON,
      --                'POEADMIN'         CREATED_BY,
      --                'NEGATIVE INVENTORY MANUAL ADJ',
      --                DECODE (INVENTORY_FLOW,
      --                        'Excess', 'E',
      --                        'Retail', 'R',
      --                        'Outlet', 'O')
      --           FROM XXCPO_RMK_INVENTORY_MASTER
      --          WHERE AVAILABLE_FGI < 0; -- AND site_code = P_SITE_CODE -->> commented on 30th May 2018
      --
      --      -->> Added below condition on 10-MAY-2018 Negative manual adjustments should not be performed for the PIDs which are having same day shipment
      --      --            AND part_number NOT IN (SELECT part_number FROM rc_inv_3b2_lro_fve_quantity ship
      --      --                                     WHERE ship.line_process_status = 'SHIPPED' AND ship.MESSAGE_TYPE = '3B2SC' AND ship.slc_site_name = P_SITE_CODE AND TRUNC(ship.line_last_update_date) >= TRUNC(SYSDATE)-1)
      --      --            AND part_number NOT IN (SELECT refresh_part_number FROM rc_inv_4b2_lro_fve_quantity WHERE message_id LIKE ''''||P_SITE_CODE||'%''' AND TRUNC(ln_last_update_date) = TRUNC(SYSDATE));
      --
      --
      --
      --      COMMIT;

      /* End Commenting Adhoc script to clear -VE FG in the main procedure and created new procedure on 27th Aug 2018 by sridvasu */

      -- DGI:

      --            Insert into RMKTGADM.RMK_INVENTORY_LOG_STG
      --            (INVENTORY_LOG_ID, PART_NUMBER, NEW_FGI, NEW_DGI, ROHS_COMPLIANT,  SITE_CODE, PROCESS_STATUS, UPDATED_ON, UPDATED_BY, CREATED_ON, CREATED_BY, POE_BATCH_ID, PROGRAM_TYPE)
      --            select
      --            RC_INV_LOG_PK_SEQ.NEXTVAL,
      --            Part_number,
      --            0 New_FGI,
      --            Available_DGI * -1 New_DGI,
      --            'YES' Rohs_Compliant,
      --            'GDGI' Site_Code,
      --            'N' Process_Status,
      --            sysdate updated_on,
      --            'POEADMIN' updated_By,
      --            sysdate created_on,
      --            'POEADMIN' Created_By,
      --            'NEGATIVE INVENTORY MANUAL ADJ',
      --            decode(Inventory_flow, 'Excess','E','Retail','R','Outlet','O')
      --            from
      --            xxcpo_rmk_inventory_master
      --            where available_dgi < 0 and site_code = 'GDGI';

      -- Commit;

      -- COMMIT;

      /* Start Added to check whether to clear -VE FG script has already processed in last 90 mins, on 27th Aug 2018 by sridvasu */

      LV_CHL_CNT := 0;

      SELECT COUNT (1)
        INTO LV_CHL_CNT
        FROM RMKTGADM.CRON_HISTORY_LOG CHL
       WHERE     1 = 1
             AND CHL.CHL_CRON_NAME = 'RC_INV_NEG_MANUAL_ADJ'
             AND CHL.CHL_CREATED_BY = 'RC_INV_DELTA_LOAD_RF'
             AND CHL.CHL_START_TIMESTAMP >= SYSDATE - 90 / (24 * 60);

      IF LV_CHL_CNT = 0
      THEN
         RC_INV_NEG_MANUAL_ADJ (P_SITE_CODE);
      END IF;

      /* End Added to check whether to clear -VE FG script has already processed in last 90 mins, on 27th Aug 2018 by sridvasu */

      -->> Start added update statement after execution of RC_INV_EX_EOS_PID_QTY_REVOKE on 17-Jan-2019

      UPDATE RMKTGADM.CRON_CONTROL_INFO
         SET CRON_START_TIMESTAMP = G_START_TIME,
             CRON_END_TIMESTAMP = SYSDATE,
             CRON_STATUS = 'SUCCESS'
       WHERE     CRON_NAME = 'RF_MAIN'
             AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'RF_MAIN';

      COMMIT;
   -->> End added update statement after execution of RC_INV_EX_EOS_PID_QTY_REVOKE on 17-Jan-2019

   EXCEPTION
      WHEN OTHERS
      THEN
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         --Commented as on 20-Jun-17

         --         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
         --                                                CHL_STATUS,
         --                                                CHL_START_TIMESTAMP,
         --                                                CHL_END_TIMESTAMP,
         --                                                CHL_CRON_NAME,
         --                                                CHL_COMMENTS,
         --                                                CHL_CREATED_BY)
         --              VALUES (SEQ_CHL_ID.NEXTVAL,
         --                      'FAILED',
         --                      G_START_TIME,
         --                      SYSDATE,
         --                      'RF_MAIN',
         --                      G_ERROR_MSG,
         --                      'RC_INV_DELTA_LOAD_RF');
         --
         --         UPDATE RMKTGADM.CRON_CONTROL_INFO
         --            SET CRON_END_TIMESTAMP = SYSDATE, CRON_STATUS = 'FAILED'
         --          WHERE CRON_NAME = 'RC_INV_DELTA_LOAD_RF';
         --End Commented as on 20-Jun-17

         RC_INV_RF_SEND_ERROR_EMAIL (G_PROC_NAME, G_ERROR_MSG);

         ROLLBACK;

         ---Added on 20-Jun-17        ---->>Added

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'FAILED',
                      G_START_TIME,
                      SYSDATE,
                      'RF_MAIN',
                      P_SITE_CODE || '-' || G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_RF');

         UPDATE RMKTGADM.CRON_CONTROL_INFO
            SET CRON_START_TIMESTAMP = G_START_TIME,
                CRON_END_TIMESTAMP = SYSDATE,
                CRON_STATUS = 'FAILED'
          WHERE     CRON_NAME = 'RF_MAIN'
                AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'RF_MAIN';



         COMMIT;

         ---End added on 20-Jun-17

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RF_MAIN;


   PROCEDURE RC_INV_RF_DGI_EXTRACT (P_INTRANS_FLAG      VARCHAR2 DEFAULT 'N',
                                    P_SITE_CODE      IN VARCHAR2)
   IS
      LV_TOTAL_QTY   NUMBER;
      L_START_TIME   DATE;
   BEGIN
      G_PROC_NAME := 'RC_INV_RF_DGI_EXTRACT';
      -->>
      L_START_TIME := SYSDATE;


      -->>


      -- update the cron info
      --      UPDATE RMKTGADM.CRON_HISTORY_LOG
      --         SET CHL_START_TIMESTAMP = SYSDATE, CHL_STATUS = 'STARTED'
      --       WHERE CHL_CRON_NAME = 'RC_INV_RF_DGI_EXTRACT';

      --Deleting previous run data from Stage table
      DELETE FROM RMKTGADM.RC_INV_DGI_STG
            WHERE PRODUCT_TYPE = 'R';

      COMMIT;

      -- Load the nettable c3 inventory data into stage
      -- along with the other support info like refurbish method, yield and Rohs flag

      INSERT INTO RMKTGADM.RC_INV_DGI_STG (PART_ID,
                                           PRD_FAMILY,
                                           REGION,
                                           PLACE_ID,
                                           SITE_CODE,
                                           LOCATION,
                                           QTY_ON_HAND_USEBL,
                                           QTY_IN_TRANS_USEBL,
                                           ROHS_PID,
                                           ROHS_SUBINV,
                                           REFURB_METHOD,
                                           YIELD,
                                           APPLY_YIELD,
                                           STATUS,
                                           CREATION_DATE,
                                           LAST_UPDATED_DATE,
                                           LAST_UPDATED_BY,
                                           PRODUCT_TYPE,
                                           INVENTORY_TYPE,
                                           SOURCE_SYSTEM,
                                           REFRESH_PART_NUMBER)
         (SELECT DISTINCT
                 C3.PART_ID,
                 C3.PRD_FAMILY,
                 MAP.REGION     REGION_NAME,
                 --RP.THEATER_NAME REGION_NAME,
                 C3.PLACE_ID,
                 SUBSTR (C3.PLACE_ID, 1, 3),
                 C3.LOCATION,
                 TO_NUMBER (C3.QTY_ON_HAND_USEBL), --Added TO_NUMBER as part of Sprint16 Release by mohamms2
                 DECODE (M.UDC_1, 'Y', C3.QTY_IN_TRANS_USEBL, 0),
                 DECODE (PM.ROHS_CHECK_NEEDED,
                         'N', 'NO',
                         'Y', 'YES',
                         'NO')
                    AS ROHS_PID,
                 NULL           AS ROHS_LOC,
                 /* Start Commented as part of userstory US193036 to modify yield calculation ligic */
                 --                 (SELECT PC.CONFIG_NAME
                 --                    FROM CRPADM.RC_PRODUCT_CONFIG PC
                 --                   WHERE     PC.CONFIG_TYPE = 'REFRESH_METHOD'
                 --                         AND (SELECT MIN (REFRESH_METHOD_ID)
                 --                                FROM CRPADM.RC_PRODUCT_REPAIR_SETUP IRS
                 --                               WHERE     IRS.REFRESH_INVENTORY_ITEM_ID =
                 --                                            PM.REFRESH_INVENTORY_ITEM_ID
                 --                                     AND IRS.REFRESH_STATUS = 'ACTIVE') =
                 --                                PC.CONFIG_ID)
                 --                    REFRESH_METHOD,
                 /*End commented as part of userstory US193036 to modify yield calculation ligic*/
                 /* Start Added as part of userstory US193036 to modify yield calculation ligic */
                 (SELECT PC.CONFIG_NAME
                    FROM CRPADM.RC_PRODUCT_CONFIG PC
                   WHERE     PC.CONFIG_TYPE = 'REFRESH_METHOD'
                         AND (SELECT RMKTGADM.RC_INV_DELTA_LOAD_RF.RC_INV_GET_REFURB_METHOD (
                                        PM.REFRESH_INVENTORY_ITEM_ID,
                                        (SUBSTR (C3.PLACE_ID, 1, 3)),
                                        C3.LOCATION)
                                FROM DUAL) = PC.CONFIG_ID)
                    REFRESH_METHOD,
                 /* End Added as part of userstory US193036 to modify yield calculation ligic */
                 --NVL (RS_RY.REFRESH_YIELD, 0),
                 --                 (  select max(rrsy.REFRESH_YIELD) from crpadm.rc_product_repair_setup rrsy
                 --                    where rrsy.refresh_inventory_item_id = pm.refresh_inventory_item_id
                 --                    and rrsy.refresh_method_id = RMKTGADM.RC_INV_DELTA_LOAD_RF.RC_INV_GET_REFURB_METHOD (rrsy.refresh_inventory_item_id)
                 --                    and rrsy.theater_id = MAP.Theater_ID
                 --                    and rrsy.REFRESH_STATUS = 'ACTIVE'
                 --                    and rrsy.refresh_part_number <> 'UCS-CPU-E52695D-WS'
                 --                 ) Yield,
                 --                 RMKTGADM.RC_INV_GET_YIELD(pm.program_type,
                 --                                   pm.refresh_inventory_item_id,
                 --                                   decode(map.region,'NAM',1,'EMEA',3),
                 --                                   (SUBSTR (C3.PLACE_ID, 1,3)),
                 --                                   (RMKTGADM.RC_INV_DELTA_LOAD_RF.RC_INV_GET_REFURB_METHOD(pm.refresh_inventory_item_id))) Yield
                 --/* Start Removed 80% pct logic as part of US193034  Yield - Zero percent yield issue on 19-JUN-2019 by mohamms2 */                 ,
                 --                 DECODE (RMKTGADM.RC_INV_DELTA_LOAD_RF.RC_INV_GET_YIELD (
                 --                            pm.program_type,
                 --                            pm.refresh_inventory_item_id,
                 --                            DECODE (map.region,  'NAM', 1,  'EMEA', 3),
                 --                            (SUBSTR (C3.PLACE_ID, 1, 3)),
                 --                            (RMKTGADM.RC_INV_DELTA_LOAD_RF.RC_INV_GET_REFURB_METHOD (
                 --                                pm.refresh_inventory_item_id))),
                 --                         0, 80,
                 --                         RMKTGADM.RC_INV_DELTA_LOAD_RF.RC_INV_GET_YIELD (
                 --                            pm.program_type,
                 --                            pm.refresh_inventory_item_id,
                 --                            DECODE (map.region,  'NAM', 1,  'EMEA', 3),
                 --                            (SUBSTR (C3.PLACE_ID, 1, 3)),
                 --                            (RMKTGADM.RC_INV_DELTA_LOAD_RF.RC_INV_GET_REFURB_METHOD (
                 --                                pm.refresh_inventory_item_id))))
                 --                    Yield,
                 /* End Removed 80% pct logic as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019 by mohamms2 */
                 /* Start Added as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019 by mohamms2 */
                 NVL (
                    RMKTGADM.RC_INV_DELTA_LOAD_RF.RC_INV_GET_YIELD (
                       PM.REFRESH_INVENTORY_ITEM_ID,
                       SUBSTR (C3.PLACE_ID, 1, 3),
                       C3.LOCATION),
                    0)
                    YIELD,
                 /* End Added as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019 by mohamms2 */
                 'N',
                 C3.STATUS,
                 C3.CREATION_DATE,
                 SYSDATE,
                 G_UPDATED_BY   LAST_UPDATED_BY,
                 'R'            PRODUCT_TYPE,
                 M.PROGRAM_TYPE INVENTORY_TYPE,
                 'C3',
                 PM.REFRESH_PART_NUMBER
            FROM CRPADM.RC_INV_C3_TBL C3 -- Removed VAVNI_CISCO_RSCM_TEMP.RSCM_TMP_C3_INV_TBL table and Added CRPADM table as part of Sprint16 Release by mohamms2
                 INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                    ON (   C3.INVENTORY_ITEM_ID =
                              PM.REFRESH_INVENTORY_ITEM_ID
                        OR C3.INVENTORY_ITEM_ID = PM.COMMON_INVENTORY_ITEM_ID
                        OR C3.INVENTORY_ITEM_ID = PM.XREF_INVENTORY_ITEM_ID)
                 INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR M
                    ON (C3.LOCATION = M.SUB_INVENTORY_LOCATION)
                 --                 INNER JOIN CRPADM.RC_PRODUCT_REPAIR_PARTNER RP ON (    SUBSTR (C3.PLACE_ID, 1, 3) = RP.ZCODE  AND RP.ACTIVE_FLAG = 'Y' AND RP.PROGRAM_TYPE = 0)
                 INNER JOIN
                 (SELECT DISTINCT
                         SM.SITE_CODE,
                         SM.REGION,
                         (SELECT PC.CONFIG_ID
                            FROM CRPADM.RC_PRODUCT_CONFIG PC
                           WHERE     PC.CONFIG_TYPE = 'THEATER'
                                 AND SM.REGION = PC.CONFIG_NAME
                                 AND PC.ACTIVE_FLAG = 'Y')
                            THEATER_ID
                    FROM RMKTGADM.RMK_INV_SITE_MAPPINGS SM
                   WHERE SM.INV_TYPE = 'DGI' AND SM.STATUS = 'ACTIVE') MAP
                    ON (SUBSTR (C3.PLACE_ID, 1, 3) = MAP.SITE_CODE)
           --                 LEFT OUTER JOIN
           --                 (SELECT *
           --                    FROM CRPADM.RC_PRODUCT_REPAIR_SETUP RS
           --                   WHERE RS.REFRESH_METHOD_ID =
           --                            (SELECT MIN (IRS.REFRESH_METHOD_ID)
           --                               FROM CRPADM.RC_PRODUCT_REPAIR_SETUP IRS
           --                              WHERE     RS.REFRESH_INVENTORY_ITEM_ID =
           --                                           IRS.REFRESH_INVENTORY_ITEM_ID
           --                                    AND IRS.REFRESH_STATUS = 'ACTIVE')) RS_RY ON (    RS_RY.REFRESH_INVENTORY_ITEM_ID = PM.REFRESH_INVENTORY_ITEM_ID AND RS_RY.THEATER_ID = RP.THEATER_ID)
           WHERE     1 = 1
                 AND M.NETTABLE_FLAG = 1
                 AND M.PROGRAM_TYPE IN (0, 2)     -- Inventory Type / Location
                 AND PM.PROGRAM_TYPE = 0      --  (Program Type 0:RF 1:WS) -RF
                 AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                 -- AND C3.QTY_ON_HAND_USEBL <> 0
                 AND PM.REFRESH_PART_NUMBER NOT IN
                        (SELECT REFRESH_PART_NUMBER
                           FROM RC_INV_EXCLUDE_PIDS)
          UNION ALL
            -->>  FVE
            SELECT PM.REFRESH_PART_NUMBER,
                   NULL,
                   DECODE (FVE.PL_PLANNING_DIVISION,
                           'FVE', 'EMEA',
                           'LRO', 'NAM'),
                   'FVE',
                   'FVE',
                   'RF-DGI',
                   SUM (FVE.PD_REMAINING_QTY), --TO_CHAR (SUM (FVE.PD_REMAINING_QTY)) Removed TO_CHAR as part of sprit16 Release by mohamms2
                   NULL,
                   'YES',
                   'YES',
                   NULL,
                   NULL,
                   'N',
                   'NEW',
                   SYSDATE,
                   SYSDATE,
                   G_UPDATED_BY LAST_UPDATED_BY,
                   'R'        PRODUCT_TYPE,
                   NULL,
                   'FC01-FVE',
                   PM.REFRESH_PART_NUMBER
              FROM CRPSC.SC_FC01_SNAPSHOT_FVE FVE
                   INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                      ON (PM.REFRESH_PART_NUMBER = FVE.REFRESH_PART_NUMBER)
             WHERE     1 = 1
                   AND PM.PROGRAM_TYPE = 0
                   AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                   AND FVE.PD_REMAINING_QTY > 0
                   AND UPPER (PL_LINE_STATUS_CODE) NOT IN
                          ('CLOSED', 'CANCELLED')
                   AND PM.REFRESH_PART_NUMBER NOT IN
                          (SELECT REFRESH_PART_NUMBER
                             FROM RC_INV_EXCLUDE_PIDS)
          GROUP BY PM.REFRESH_PART_NUMBER,
                   NULL,
                   DECODE (FVE.PL_PLANNING_DIVISION,
                           'FVE', 'EMEA',
                           'LRO', 'NAM'),
                   'FVE',
                   'FVE',
                   'RF-DGI',
                   --TO_CHAR (sum(FVE.PD_REMAINING_QTY)),
                   NULL,
                   'YES',
                   'YES',
                   NULL,
                   NULL,
                   'N',
                   'NEW',
                   SYSDATE,
                   SYSDATE,
                   G_UPDATED_BY,
                   'R',
                   NULL,
                   'FC01-FVE',
                   PM.REFRESH_PART_NUMBER
          UNION ALL
            -- > LRO
            SELECT PM.REFRESH_PART_NUMBER,
                   NULL,
                   DECODE (LRO.PL_PLANNING_DIVISION,
                           'FVE', 'EMEA',
                           'LRO', 'NAM'),
                   'LRO',
                   'LRO',
                   'RF-DGI',
                   SUM (LRO.PD_REMAINING_QTY), --TO_CHAR (SUM (LRO.PD_REMAINING_QTY)),Removed TO_CHAR as part of Sprint16 release by mohamms2
                   NULL,
                   'YES',
                   'YES',
                   NULL,
                   NULL,
                   'N',
                   'NEW',
                   SYSDATE,
                   SYSDATE,
                   G_UPDATED_BY LAST_UPDATED_BY,
                   'R'        PRODUCT_TYPE,
                   NULL,
                   'FC01-LRO',
                   PM.REFRESH_PART_NUMBER
              FROM CRPSC.SC_FC01_SNAPSHOT_LRO LRO
                   INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                      ON (PM.REFRESH_PART_NUMBER = LRO.REFRESH_PART_NUMBER)
             WHERE     1 = 1
                   AND PM.PROGRAM_TYPE = 0
                   AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                   AND LRO.PD_REMAINING_QTY <> 0
                   AND UPPER (PL_LINE_STATUS_CODE) NOT IN
                          ('CLOSED', 'CANCELLED')
                   AND PM.REFRESH_PART_NUMBER NOT IN
                          (SELECT REFRESH_PART_NUMBER
                             FROM RC_INV_EXCLUDE_PIDS)
          GROUP BY PM.REFRESH_PART_NUMBER,
                   NULL,
                   DECODE (LRO.PL_PLANNING_DIVISION,
                           'FVE', 'EMEA',
                           'LRO', 'NAM'),
                   'LRO',
                   'LRO',
                   'RF-DGI',
                   --TO_CHAR (sum(LRO.PD_REMAINING_QTY)),
                   NULL,
                   'YES',
                   'YES',
                   NULL,
                   NULL,
                   'N',
                   'NEW',
                   SYSDATE,
                   SYSDATE,
                   G_UPDATED_BY,
                   'R',
                   NULL,
                   'FC01-LRO',
                   PM.REFRESH_PART_NUMBER);

      COMMIT;

      -- update Apply field flag depending the sub inventory location
      UPDATE RMKTGADM.RC_INV_DGI_STG
         SET APPLY_YIELD = 'Y'
       WHERE     1 = 1
             AND SOURCE_SYSTEM NOT IN ('FC01-FVE', 'FC01-LRO')
             AND SITE_CODE NOT IN ('FVE', 'LRO')
             AND PRODUCT_TYPE = 'R'                      -- To Process only RF
             -->>
             AND LOCATION IN
                    (SELECT M.SUB_INVENTORY_LOCATION
                       FROM CRPADM.RC_SUB_INV_LOC_MSTR M
                            INNER JOIN CRPADM.RC_SUB_INV_LOC_FLG_DTLS D
                               ON (M.SUB_INVENTORY_ID = D.SUB_INVENTORY_ID)
                      WHERE     M.NETTABLE_FLAG = 1 -- AND m.INVENTORY_TYPE IN (0, 2) -- RF and POE
                            AND M.PROGRAM_TYPE IN (0, 2) -->> Inventory Types 0 = RF ; 2 = POE
                            AND D.YIELD_RF = 'Y');

      -- update the quantity     after yield values depending in the apply yield flag
      /* Start Removed 80% pct logic as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019 by mohamms2 */

      --      UPDATE RMKTGADM.RC_INV_DGI_STG
      --         SET QTY_AFTER_YIELD =
      --                DECODE (
      --                   APPLY_YIELD,
      --                   'Y',   (DECODE (NVL (YIELD, 0), 0, 80, YIELD) / 100) --Added 80 pct logic for yield is zero as part of Apr17 Release
      --                        * (QTY_ON_HAND_USEBL + QTY_IN_TRANS_USEBL),
      --                   'N', (QTY_ON_HAND_USEBL + NVL (QTY_IN_TRANS_USEBL, 0)),
      --                   (QTY_ON_HAND_USEBL + NVL (QTY_IN_TRANS_USEBL, 0)))
      --       WHERE PRODUCT_TYPE = 'R';

      /* End Removed 80% pct logic as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019 by mohamms2 */

      /* Start Added as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019 by mohamms2 */

      UPDATE RMKTGADM.RC_INV_DGI_STG
         SET QTY_AFTER_YIELD =
                DECODE (
                   APPLY_YIELD,
                   'Y',   (YIELD / 100)
                        * (QTY_ON_HAND_USEBL + QTY_IN_TRANS_USEBL),
                   'N', (QTY_ON_HAND_USEBL + NVL (QTY_IN_TRANS_USEBL, 0)),
                   (QTY_ON_HAND_USEBL + NVL (QTY_IN_TRANS_USEBL, 0)))
       WHERE PRODUCT_TYPE = 'R';

      /* End Added as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019 by mohamms2 */

      G_PROC_NAME := 'RC_INV_RF_DGI_EXTRACT';



      INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                             CHL_STATUS,
                                             CHL_START_TIMESTAMP,
                                             CHL_END_TIMESTAMP,
                                             CHL_CRON_NAME,
                                             CHL_COMMENTS,
                                             CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'SUCCESS',
                   L_START_TIME,
                   SYSDATE,
                   G_PROC_NAME,
                   P_SITE_CODE,                                       -- NULL,
                   'RC_INV_DELTA_LOAD_RF');


      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'FAILED',
                      L_START_TIME,
                      SYSDATE,
                      G_PROC_NAME,
                      P_SITE_CODE || '-' || G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_RF');

         G_PROC_NAME := 'RC_INV_RF_DGI_EXTRACT';

         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_RF_DGI_EXTRACT;

   PROCEDURE RC_INV_RF_DGI_HISTORY (P_SITE_CODE IN VARCHAR2)
   IS
      L_START_TIME   DATE;
   BEGIN
      G_PROC_NAME := 'RC_INV_RF_DGI_HISTORY';

      L_START_TIME := SYSDATE;

      --consolidate the inventory to Zlocation level
      INSERT INTO RMKTGADM.RC_INV_DGI_HIST (PART_ID,
                                            PRD_FAMILY,
                                            ZLOCATION,
                                            ZCODE,
                                            QTY_AFTER_YIELD,
                                            ROHS_PID,
                                            LOCATION, -- PRODUCT_NAME_STRIPPED,
                                            STATUS,
                                            SITE_SHORTNAME,
                                            CREATED_ON,
                                            UPDATED_ON,
                                            PRODUCT_TYPE,
                                            INVENTORY_TYPE,
                                            SOURCE_SYSTEM)
           SELECT DISTINCT REFRESH_PART_NUMBER,
                           PRD_FAMILY,
                           PLACE_ID,
                           STG.SITE_CODE,
                           SUM (QTY_AFTER_YIELD) QTY,
                           ROHS_PID,
                           LOCATION,                 -- PRODUCT_NAME_STRIPPED,
                           'CURRENT'           AS STATUS,
                           MAP.SITE_SHORTNAME,
                           SYSDATE,
                           SYSDATE,
                           PRODUCT_TYPE,
                           STG.INVENTORY_TYPE,
                           SOURCE_SYSTEM
             FROM RMKTGADM.RC_INV_DGI_STG      STG,
                  RMKTGADM.RMK_INV_SITE_MAPPINGS MAP,
                  CRPADM.RC_SUB_INV_LOC_MSTR   SUB
            WHERE     MAP.SITE_CODE = STG.SITE_CODE
                  AND STG.LOCATION = SUB.SUB_INVENTORY_LOCATION
                  AND MAP.INV_TYPE = 'DGI'
                  AND MAP.ROHS_SITE = 'YES'
                  AND MAP.STATUS = 'ACTIVE'
                  /* Start Removed sub inv condition
                              AND (   (    STG.REFURB_METHOD = 'REPAIR'
                                       AND STG.LOCATION
                                               MEMBER OF CRPADM.RC_GET_SUBINVENTORY_LOCATIONS (
                                                           5,
                                                           'RF_POE',
                                                           'ALL',
                                                           1))
                                   OR (    STG.REFURB_METHOD = 'TEST'
                                       AND STG.LOCATION
                                               MEMBER OF CRPADM.RC_GET_SUBINVENTORY_LOCATIONS (
                                                           6,
                                                           'RF_POE',
                                                           'ALL',
                                                           1))
                                   OR (    STG.REFURB_METHOD = 'SCREEN'
                                       AND STG.LOCATION
                                               MEMBER OF CRPADM.RC_GET_SUBINVENTORY_LOCATIONS (
                                                           3,
                                                           'RF_POE',
                                                           'ALL',
                                                           1))
                                   OR (STG.SOURCE_SYSTEM = 'FC01-FVE')
                                   OR (STG.SOURCE_SYSTEM = 'FC01-LRO'))
                            End Removed sub inv condition        */
                  AND SUB.INVENTORY_TYPE <> 0                           -- FGI
                  AND SUB.PROGRAM_TYPE IN (0, 2) -- (0) Retail (1) Excess (2) POE
                  AND PRODUCT_TYPE = 'R'
         GROUP BY REFRESH_PART_NUMBER,
                  PRD_FAMILY,
                  PLACE_ID,
                  STG.SITE_CODE,
                  ROHS_PID,
                  LOCATION,                          -- PRODUCT_NAME_STRIPPED,
                  'CURRENT',
                  MAP.SITE_SHORTNAME,
                  PRODUCT_TYPE,
                  STG.INVENTORY_TYPE,
                  SOURCE_SYSTEM
         UNION            -->> FOR FG Locations irrespective of Refurb Methods
           SELECT DISTINCT STG.REFRESH_PART_NUMBER,
                           STG.PRD_FAMILY,
                           STG.PLACE_ID,
                           STG.SITE_CODE,
                           SUM (QTY_AFTER_YIELD) QTY,
                           STG.ROHS_PID,
                           STG.LOCATION,         -- stg.PRODUCT_NAME_STRIPPED,
                           'CURRENT'           AS STATUS,
                           MAP.SITE_SHORTNAME,
                           SYSDATE,
                           SYSDATE,
                           STG.PRODUCT_TYPE,
                           STG.INVENTORY_TYPE,
                           STG.SOURCE_SYSTEM
             FROM RMKTGADM.RC_INV_DGI_STG      STG,
                  RMKTGADM.RMK_INV_SITE_MAPPINGS MAP,
                  CRPADM.RC_SUB_INV_LOC_MSTR   SUB
            WHERE     MAP.SITE_CODE = STG.SITE_CODE
                  AND STG.LOCATION = SUB.SUB_INVENTORY_LOCATION
                  AND MAP.INV_TYPE = 'DGI'
                  AND MAP.ROHS_SITE = 'YES'
                  AND MAP.STATUS = 'ACTIVE'
                  AND SUB.INVENTORY_TYPE = 0                            -- FGI
                  AND SUB.PROGRAM_TYPE = 0  -- (0)  Retail (1) Excess  (2) POE
                  AND STG.PRODUCT_TYPE = 'R'
         --AND STG.REFURB_METHOD <> 'REPAIR'
         --and STG.part_id = '1030036-RF'
         GROUP BY STG.REFRESH_PART_NUMBER,
                  STG.PRD_FAMILY,
                  STG.PLACE_ID,
                  STG.SITE_CODE,
                  STG.ROHS_PID,
                  STG.LOCATION,                  -- stg.PRODUCT_NAME_STRIPPED,
                  'CURRENT',
                  MAP.SITE_SHORTNAME,
                  SYSDATE,
                  SYSDATE,
                  STG.PRODUCT_TYPE,
                  STG.INVENTORY_TYPE,
                  STG.SOURCE_SYSTEM;

      COMMIT;


      INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                             CHL_STATUS,
                                             CHL_START_TIMESTAMP,
                                             CHL_END_TIMESTAMP,
                                             CHL_CRON_NAME,
                                             CHL_COMMENTS,
                                             CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'SUCCESS',
                   L_START_TIME,
                   SYSDATE,
                   G_PROC_NAME,
                   P_SITE_CODE,                                        --NULL,
                   'RC_INV_DELTA_LOAD_RF');

      G_PROC_NAME := 'RC_INV_RF_DGI_HISTORY';
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'FAILED',
                      L_START_TIME,
                      SYSDATE,
                      G_PROC_NAME,
                      P_SITE_CODE || '-' || G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_RF');

         G_PROC_NAME := 'RC_INV_RF_DGI_HISTORY';

         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_RF_DGI_HISTORY;

   PROCEDURE RC_INV_RF_DGI_DELTA (P_SITE_CODE IN VARCHAR2)
   IS
      LAST_VALUE     NUMBER;
      V_DGI_DELTA    NUMBER;



      --DeltaAgg-->> Delta Aggretation at Program Type, Product and Source System Level.

      CURSOR DGI_CURSOR_DELTA
      IS
         SELECT T1.POE_BATCH_ID,
                T1.PART_ID,
                T1.QTY_AFTER_YIELD,
                T1.ROHS_PID,
                --T1.SITE_SHORTNAME,   --DeltaAgg-->
                T1.PRODUCT_TYPE,
                -- T1.INVENTORY_TYPE,   --DeltaAgg-->
                T1.SOURCE_SYSTEM
           FROM (  SELECT POE_BATCH_ID,
                          PART_ID,
                          SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                          ROHS_PID,
                          --SITE_SHORTNAME,  --DeltaAgg-->
                          PRODUCT_TYPE,
                          -- INVENTORY_TYPE,  --DeltaAgg-->
                          SOURCE_SYSTEM
                     FROM RMKTGADM.RC_INV_DGI_HIST
                    WHERE PRODUCT_TYPE = 'R' AND STATUS = 'CURRENT'
                 GROUP BY POE_BATCH_ID,
                          PART_ID,
                          ROHS_PID,
                          --SITE_SHORTNAME,  --DeltaAgg-->
                          PRODUCT_TYPE,
                          -- INVENTORY_TYPE,  --DeltaAgg-->
                          SOURCE_SYSTEM) T1
                INNER JOIN (  SELECT PART_ID,
                                     SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                                     ROHS_PID,
                                     --SITE_SHORTNAME,  --DeltaAgg-->
                                     PRODUCT_TYPE,
                                     -- INVENTORY_TYPE,  --DeltaAgg-->
                                     SOURCE_SYSTEM
                                FROM RMKTGADM.RC_INV_DGI_HIST
                               WHERE PRODUCT_TYPE = 'R' AND STATUS = 'LASTRUN'
                            GROUP BY POE_BATCH_ID,
                                     PART_ID,
                                     ROHS_PID,
                                     --SITE_SHORTNAME,  --DeltaAgg-->
                                     PRODUCT_TYPE,
                                     -- INVENTORY_TYPE,  --DeltaAgg-->
                                     SOURCE_SYSTEM) T2
                   ON     T1.PART_ID = T2.PART_ID
                      -- AND T1.SITE_SHORTNAME = T2.SITE_SHORTNAME
                      -- AND (   T1.INVENTORY_TYPE = T2.INVENTORY_TYPE OR T1.SOURCE_SYSTEM IN ('FC01-FVE', 'FC01-LRO'));
                      -->>
                      AND T1.PRODUCT_TYPE = T2.PRODUCT_TYPE
                      AND T1.SOURCE_SYSTEM = T2.SOURCE_SYSTEM; -- OR T1.SOURCE_SYSTEM IN ('FC01-FVE', 'FC01-LRO')) ;

      CURSOR DGI_CURSOR_CURRENT
      IS
           SELECT PART_ID,
                  SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                  ROHS_PID,
                  -->> SITE_SHORTNAME,  --DeltaAgg-->
                  PRODUCT_TYPE,
                  -->> INVENTORY_TYPE,  --DeltaAgg-->
                  SOURCE_SYSTEM
             FROM RMKTGADM.RC_INV_DGI_HIST
            WHERE PRODUCT_TYPE = 'R' AND STATUS = 'CURRENT'
         GROUP BY POE_BATCH_ID,
                  PART_ID,
                  ROHS_PID,
                  -->> SITE_SHORTNAME,  --DeltaAgg-->
                  PRODUCT_TYPE,
                  -->> INVENTORY_TYPE,  --DeltaAgg-->
                  SOURCE_SYSTEM
         MINUS
         SELECT T1.PART_ID,
                T1.QTY_AFTER_YIELD,
                T1.ROHS_PID,
                -->> T1.SITE_SHORTNAME,  --DeltaAgg-->
                T1.PRODUCT_TYPE,
                -->> T1.INVENTORY_TYPE,  --DeltaAgg-->
                T1.SOURCE_SYSTEM
           FROM (  SELECT POE_BATCH_ID,
                          PART_ID,
                          SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                          ROHS_PID,
                          -->> SITE_SHORTNAME,  --DeltaAgg-->
                          PRODUCT_TYPE,
                          -->> INVENTORY_TYPE,  --DeltaAgg-->
                          SOURCE_SYSTEM
                     FROM RMKTGADM.RC_INV_DGI_HIST
                    WHERE PRODUCT_TYPE = 'R' AND STATUS = 'CURRENT'
                 GROUP BY POE_BATCH_ID,
                          PART_ID,
                          ROHS_PID,
                          -->> SITE_SHORTNAME,  --DeltaAgg-->
                          PRODUCT_TYPE,
                          -->> INVENTORY_TYPE,  --DeltaAgg-->
                          SOURCE_SYSTEM) T1
                INNER JOIN (  SELECT PART_ID,
                                     SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                                     ROHS_PID,
                                     -->> SITE_SHORTNAME,  --DeltaAgg-->
                                     PRODUCT_TYPE,
                                     -->> INVENTORY_TYPE,  --DeltaAgg-->
                                     SOURCE_SYSTEM
                                FROM RMKTGADM.RC_INV_DGI_HIST
                               WHERE PRODUCT_TYPE = 'R' AND STATUS = 'LASTRUN'
                            GROUP BY POE_BATCH_ID,
                                     PART_ID,
                                     ROHS_PID,
                                     -->> SITE_SHORTNAME,  --DeltaAgg-->
                                     PRODUCT_TYPE,
                                     -->> INVENTORY_TYPE,  --DeltaAgg-->
                                     SOURCE_SYSTEM) T2
                   ON     T1.PART_ID = T2.PART_ID
                      -->> AND T1.SITE_SHORTNAME = T2.SITE_SHORTNAME   --DeltaAgg-->
                      -->> AND (   T1.INVENTORY_TYPE = T2.INVENTORY_TYPE OR T1.SOURCE_SYSTEM IN ('FC01-FVE', 'FC01-LRO'));  --DeltaAgg-->
                      -->>
                      AND T1.PRODUCT_TYPE = T2.PRODUCT_TYPE
                      AND T1.SOURCE_SYSTEM = T2.SOURCE_SYSTEM; -- OR T1.SOURCE_SYSTEM IN ('FC01-FVE', 'FC01-LRO') ) ;

      CURSOR DGI_CURSOR_LAST
      IS
           SELECT PART_ID,
                  SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                  ROHS_PID,
                  -->> SITE_SHORTNAME,   --DeltaAgg-->
                  PRODUCT_TYPE,
                  -->> INVENTORY_TYPE,  --DeltaAgg-->
                  SOURCE_SYSTEM
             FROM RMKTGADM.RC_INV_DGI_HIST
            WHERE PRODUCT_TYPE = 'R' AND STATUS = 'LASTRUN'
         GROUP BY POE_BATCH_ID,
                  PART_ID,
                  ROHS_PID,
                  -->> SITE_SHORTNAME,  --DeltaAgg-->
                  PRODUCT_TYPE,
                  -->> INVENTORY_TYPE,  --DeltaAgg-->
                  SOURCE_SYSTEM
         MINUS
         SELECT T2.PART_ID,
                T2.QTY_AFTER_YIELD,
                T2.ROHS_PID,
                -->> T2.SITE_SHORTNAME,  --DeltaAgg-->
                T2.PRODUCT_TYPE,
                -->> T2.INVENTORY_TYPE,  --DeltaAgg-->
                T2.SOURCE_SYSTEM
           FROM (  SELECT PART_ID,
                          SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                          ROHS_PID,
                          -->> SITE_SHORTNAME,  --DeltaAgg-->
                          PRODUCT_TYPE,
                          -->> INVENTORY_TYPE,  --DeltaAgg-->
                          SOURCE_SYSTEM
                     FROM RMKTGADM.RC_INV_DGI_HIST
                    WHERE PRODUCT_TYPE = 'R' AND STATUS = 'CURRENT'
                 GROUP BY POE_BATCH_ID,
                          PART_ID,
                          ROHS_PID,
                          -->> SITE_SHORTNAME,  --DeltaAgg-->
                          PRODUCT_TYPE,
                          -->> INVENTORY_TYPE,  --DeltaAgg-->
                          SOURCE_SYSTEM) T1
                INNER JOIN (  SELECT POE_BATCH_ID,
                                     PART_ID,
                                     SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                                     ROHS_PID,
                                     -->> SITE_SHORTNAME,  --DeltaAgg-->
                                     PRODUCT_TYPE,
                                     -->> INVENTORY_TYPE,  --DeltaAgg-->
                                     SOURCE_SYSTEM
                                FROM RMKTGADM.RC_INV_DGI_HIST
                               WHERE PRODUCT_TYPE = 'R' AND STATUS = 'LASTRUN'
                            GROUP BY POE_BATCH_ID,
                                     PART_ID,
                                     ROHS_PID,
                                     -->> SITE_SHORTNAME,  --DeltaAgg-->
                                     PRODUCT_TYPE,
                                     -->> INVENTORY_TYPE,
                                     SOURCE_SYSTEM) T2
                   ON     T1.PART_ID = T2.PART_ID
                      -->> AND T1.SITE_SHORTNAME = T2.SITE_SHORTNAME  --DeltaAgg-->
                      -->> AND (   T1.INVENTORY_TYPE = T2.INVENTORY_TYPE OR T1.SOURCE_SYSTEM IN ('FC01-FVE', 'FC01-LRO'));    --DeltaAgg-->
                      -->>
                      AND T1.PRODUCT_TYPE = T2.PRODUCT_TYPE
                      AND T1.SOURCE_SYSTEM = T2.SOURCE_SYSTEM; -- OR T1.SOURCE_SYSTEM IN ('FC01-FVE', 'FC01-LRO') );

      DGI_RECORD     DGI_CURSOR_DELTA%ROWTYPE;
      DGI_RECORD_C   DGI_CURSOR_CURRENT%ROWTYPE;
      DGI_RECORD_L   DGI_CURSOR_CURRENT%ROWTYPE;
      L_START_TIME   DATE;
   BEGIN
      G_PROC_NAME := 'RC_INV_RF_DGI_DELTA';
      L_START_TIME := SYSDATE;


      DELETE FROM RMKTGADM.RC_INV_DGI_DELTA
            WHERE PRODUCT_TYPE = 'R';

      COMMIT;


      OPEN DGI_CURSOR_DELTA;

      LOOP
         FETCH DGI_CURSOR_DELTA INTO DGI_RECORD;

         EXIT WHEN DGI_CURSOR_DELTA%NOTFOUND;

         SELECT SUM (QTY_AFTER_YIELD)
           INTO LAST_VALUE
           FROM RMKTGADM.RC_INV_DGI_HIST
          WHERE     PRODUCT_TYPE = 'R'
                AND PART_ID = DGI_RECORD.PART_ID
                --AND SITE_SHORTNAME = DGI_RECORD.SITE_SHORTNAME  --DeltaAgg-->
                AND PRODUCT_TYPE = DGI_RECORD.PRODUCT_TYPE  -->> --DeltaAgg-->
                AND SOURCE_SYSTEM = DGI_RECORD.SOURCE_SYSTEM -- OR SOURCE_SYSTEM IN ('FC01-FVE', 'FC01-LRO'))  --DeltaAgg-->
                --AND (   INVENTORY_TYPE = DGI_RECORD.INVENTORY_TYPE OR SOURCE_SYSTEM IN ('FC01-FVE', 'FC01-LRO'))  --DeltaAgg-->
                AND STATUS = 'LASTRUN';

         V_DGI_DELTA := DGI_RECORD.QTY_AFTER_YIELD - LAST_VALUE;

         IF V_DGI_DELTA != 0
         THEN
            INSERT INTO RMKTGADM.RC_INV_DGI_DELTA (INV_LOG_PK,
                                                   PRODUCT_ID,
                                                   DELTA_DGI,
                                                   IS_ROHS,
                                                   -->> SITE_SHORTNAME,  --DeltaAgg-->
                                                   CREATED_ON,
                                                   CREATED_BY,
                                                   PRODUCT_TYPE,
                                                   -->> INVENTORY_TYPE,  --DeltaAgg-->
                                                   SOURCE_SYSTEM,
                                                   POE_BATCH_ID)
                 VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                         DGI_RECORD.PART_ID,
                         V_DGI_DELTA,
                         DGI_RECORD.ROHS_PID,
                         -->> DGI_RECORD.SITE_SHORTNAME,  --DeltaAgg-->
                         SYSDATE,
                         'POEADMIN',
                         DGI_RECORD.PRODUCT_TYPE,
                         -->> DGI_RECORD.INVENTORY_TYPE,  --DeltaAgg-->
                         DGI_RECORD.SOURCE_SYSTEM,
                         'DGI_DELTA != 0');
         END IF;
      END LOOP;


      ---------------------------------------------------------------CURRENT-------------------------------------

      OPEN DGI_CURSOR_CURRENT;

      LOOP
         FETCH DGI_CURSOR_CURRENT INTO DGI_RECORD_C;

         EXIT WHEN DGI_CURSOR_CURRENT%NOTFOUND;

         IF DGI_RECORD_C.QTY_AFTER_YIELD <> 0
         THEN
            INSERT INTO RMKTGADM.RC_INV_DGI_DELTA (INV_LOG_PK,
                                                   PRODUCT_ID,
                                                   DELTA_DGI,
                                                   IS_ROHS,
                                                   -->> SITE_SHORTNAME,  --DeltaAgg-->
                                                   CREATED_ON,
                                                   CREATED_BY,
                                                   PRODUCT_TYPE,
                                                   -->> INVENTORY_TYPE,  --DeltaAgg-->
                                                   SOURCE_SYSTEM,
                                                   POE_BATCH_ID)
                 VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                         DGI_RECORD_C.PART_ID,
                         DGI_RECORD_C.QTY_AFTER_YIELD,
                         DGI_RECORD_C.ROHS_PID,
                         -->> DGI_RECORD_C.SITE_SHORTNAME,  --DeltaAgg-->
                         SYSDATE,
                         'POEADMIN',
                         DGI_RECORD_C.PRODUCT_TYPE,
                         -->> DGI_RECORD_C.INVENTORY_TYPE,  --DeltaAgg-->
                         DGI_RECORD_C.SOURCE_SYSTEM,
                         'DGI_CURRENT');
         END IF;
      END LOOP;

      CLOSE DGI_CURSOR_CURRENT;

      ---------------------------------------------------------Lastrun--------------------------------------------------

      OPEN DGI_CURSOR_LAST;

      LOOP
         FETCH DGI_CURSOR_LAST INTO DGI_RECORD_L;

         EXIT WHEN DGI_CURSOR_LAST%NOTFOUND;

         IF DGI_RECORD_L.QTY_AFTER_YIELD <> 0
         THEN
            INSERT INTO RMKTGADM.RC_INV_DGI_DELTA (INV_LOG_PK,
                                                   PRODUCT_ID,
                                                   DELTA_DGI,
                                                   IS_ROHS,
                                                   -->> SITE_SHORTNAME,  --DeltaAgg-->
                                                   CREATED_ON,
                                                   CREATED_BY,
                                                   PRODUCT_TYPE,
                                                   -->> INVENTORY_TYPE,  --DeltaAgg-->
                                                   SOURCE_SYSTEM,
                                                   POE_BATCH_ID)
                 VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                         DGI_RECORD_L.PART_ID,
                         - (DGI_RECORD_L.QTY_AFTER_YIELD),
                         DGI_RECORD_L.ROHS_PID,
                         -->> DGI_RECORD_L.SITE_SHORTNAME,  --DeltaAgg-->
                         SYSDATE,
                         'POEADMIN',
                         DGI_RECORD_L.PRODUCT_TYPE,
                         -->> DGI_RECORD_L.INVENTORY_TYPE,  --DeltaAgg-->
                         DGI_RECORD_L.SOURCE_SYSTEM,
                         'DGI_LASTRUN');
         END IF;
      END LOOP;

      CLOSE DGI_CURSOR_LAST;

      UPDATE RMKTGADM.RC_INV_DGI_HIST
         SET STATUS = 'HISTORY'
       WHERE PRODUCT_TYPE = 'R' AND STATUS = 'LASTRUN';

      UPDATE RMKTGADM.RC_INV_DGI_HIST
         SET STATUS = 'LASTRUN'
       WHERE PRODUCT_TYPE = 'R' AND STATUS = 'CURRENT';

      COMMIT;



      INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                             CHL_STATUS,
                                             CHL_START_TIMESTAMP,
                                             CHL_END_TIMESTAMP,
                                             CHL_CRON_NAME,
                                             CHL_COMMENTS,
                                             CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'SUCCESS',
                   L_START_TIME,
                   SYSDATE,
                   G_PROC_NAME,
                   P_SITE_CODE,                                        --NULL,
                   'RC_INV_DELTA_LOAD_RF');

      G_PROC_NAME := 'RC_INV_RF_DGI_DELTA';
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'FAILED',
                      L_START_TIME,
                      SYSDATE,
                      G_PROC_NAME,
                      P_SITE_CODE || '-' || G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_RF');

         G_PROC_NAME := 'RC_INV_RF_DGI_DELTA';

         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_RF_DGI_DELTA;

   PROCEDURE RC_INV_RF_FGI_EXTRACT (P_SITE_CODE IN VARCHAR2)
   IS
      CURSOR FGI_CURSOR_DELTA
      IS
         --         SELECT TO_CHAR (LRO.TRANSACTION_ID) POE_BATCH_ID,
         --                LRO.REFRESH_PART_NUMBER PRODUCT_ID,
         --                LRO.TOTAL_QTY DELTA_FGI,
         --                --'YES' IS_ROHS,
         --                decode(LRO.ROHS_FLAG, 'Y','YES','N','NO','YES') IS_ROHS,
         --                LRO.HUB_LOCATION SITE_SHORTNAME,
         --                --RECORD_CREATED_ON CREATED_ON,
         --                sysdate CREATED_ON,
         --                LRO.RECORD_CREATED_BY CREATED_BY,
         --                TO_NUMBER (LRO.PO_LINE_NUMBER) LINE_NO,
         --                'SC-RETAIL-FB02-LRO' SOURCE_SYSTEM,
         --                'R' PRODUCT_TYPE
         --           FROM CRPSC.SC_FB02_DELTA_LRO_HIST LRO
         --                INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
         --                   ON (LRO.REFRESH_PART_NUMBER = PM.REFRESH_PART_NUMBER)
         --          WHERE     1 = 1
         --                AND PM.PROGRAM_TYPE = 0
         --                AND LRO.PROCESSED_STATUS = 'N'
         --                AND LRO.TOTAL_QTY > 0
         --                AND PM.REFRESH_PART_NUMBER NOT IN (SELECT REFRESH_PART_NUMBER
         --                                                     FROM RC_INV_EXCLUDE_PIDS)
         --         UNION ALL
         -->> FVE
         SELECT TO_CHAR (FVE.TRANSACTION_ID)   POE_BATCH_ID,
                FVE.REFRESH_PART_NUMBER        PRODUCT_ID,
                FVE.RECEIVED_QTY               DELTA_FGI,
                'YES'                          IS_ROHS,
                FVE.HUB_LOCATION               SITE_SHORTNAME,
                --RECORD_CREATED_ON CREATED_ON,
                SYSDATE                        CREATED_ON,
                FVE.RECORD_CREATED_BY          CREATED_BY,
                TO_NUMBER (FVE.PO_LINE_NUMBER) LINE_NO,
                'SC-RETAIL-FC01-FVE'           SOURCE_SYSTEM,
                'R'                            PRODUCT_TYPE
           FROM --CRPSC.SC_FB02_DELTA_FVE_HIST FVE -- commented as part of US390864
               CRPSC.RC_FC01_OH_DELTA_FVE_HIST  FVE
                INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                   ON (FVE.REFRESH_PART_NUMBER = PM.REFRESH_PART_NUMBER)
          WHERE     1 = 1
                AND PM.PROGRAM_TYPE = 0
                AND FVE.PROCESSED_STATUS = 'N'
                AND FVE.RECEIVED_QTY > 0 -- Temporarily Removed to Send -VE FVE Quantities to CCW.
                AND FVE.PO_NUMBER LIKE 'CSC%'
                AND FVE.HUB_LOCATION = P_SITE_CODE
                AND PM.REFRESH_PART_NUMBER NOT IN
                       (SELECT REFRESH_PART_NUMBER
                          FROM RC_INV_EXCLUDE_PIDS)
         UNION ALL
         --  >> LRO                                                                     -->> (Integrating LRO FC01 Receipts OH)
         SELECT TO_CHAR (LRO.TRANSACTION_ID)   POE_BATCH_ID,
                LRO.REFRESH_PART_NUMBER        PRODUCT_ID,
                LRO.RECEIVED_QTY               DELTA_FGI,
                ROHS_FLAG,
                LRO.HUB_LOCATION               SITE_SHORTNAME,
                --RECORD_CREATED_ON CREATED_ON,
                SYSDATE                        CREATED_ON,
                LRO.RECORD_CREATED_BY          CREATED_BY,
                TO_NUMBER (LRO.PO_LINE_NUMBER) LINE_NO,
                'SC-FC01-RECEIPTS-LRO'         SOURCE_SYSTEM,
                'R'                            PRODUCT_TYPE
           FROM CRPSC.SC_FC01_OH_DELTA_LRO_HIST LRO
                INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                   ON (LRO.REFRESH_PART_NUMBER = PM.REFRESH_PART_NUMBER)
          WHERE     1 = 1
                AND PM.PROGRAM_TYPE = 0
                AND LRO.PROCESSED_STATUS = 'N'
                AND LRO.RECEIVED_QTY > 0
                AND LRO.HUB_LOCATION = P_SITE_CODE
                AND PM.REFRESH_PART_NUMBER NOT IN
                       (SELECT REFRESH_PART_NUMBER
                          FROM RC_INV_EXCLUDE_PIDS);

      FGI_INV_RECORD     FGI_CURSOR_DELTA%ROWTYPE;
      L_PROCESSED_FLAG   VARCHAR2 (10);
      L_INV_LOG_PK       NUMBER;
      L_START_TIME       DATE;
   BEGIN
      G_PROC_NAME := 'RC_INV_RF_FGI_EXTRACT';
      L_START_TIME := SYSDATE;


      --      DELETE FROM RC_INV_FGI_DELTA
      --            WHERE PRODUCT_TYPE = 'R';


      OPEN FGI_CURSOR_DELTA;

      LOOP
         FETCH FGI_CURSOR_DELTA INTO FGI_INV_RECORD;

         EXIT WHEN FGI_CURSOR_DELTA%NOTFOUND;


         BEGIN
            INSERT INTO RMKTGADM.RC_INV_FGI_DELTA (POE_BATCH_ID,
                                                   PRODUCT_ID,
                                                   DELTA_FGI,
                                                   IS_ROHS,
                                                   SITE_SHORTNAME,
                                                   CREATED_ON,
                                                   CREATED_BY,
                                                   UPDATED_ON,
                                                   UPDATED_BY,
                                                   PRODUCT_TYPE,
                                                   SOURCE_SYSTEM)
                 VALUES (FGI_INV_RECORD.POE_BATCH_ID,
                         FGI_INV_RECORD.PRODUCT_ID,
                         FGI_INV_RECORD.DELTA_FGI,
                         FGI_INV_RECORD.IS_ROHS,
                         FGI_INV_RECORD.SITE_SHORTNAME,
                         FGI_INV_RECORD.CREATED_ON,
                         FGI_INV_RECORD.CREATED_BY,
                         SYSDATE,
                         G_UPDATED_BY,
                         FGI_INV_RECORD.PRODUCT_TYPE,
                         FGI_INV_RECORD.SOURCE_SYSTEM);

            L_PROCESSED_FLAG := 'Y';
         EXCEPTION
            WHEN OTHERS
            THEN
               DBMS_OUTPUT.PUT_LINE ('ERROR' || FGI_INV_RECORD.POE_BATCH_ID);
               L_PROCESSED_FLAG := 'N';


               RAISE_APPLICATION_ERROR (-20000, SQLERRM);
         END;

         COMMIT;

         --dbms_output.put_line('FGI_INV_RECORD.LINE_NO=> '||FGI_INV_RECORD.LINE_NO||' <<FGI_INV_RECORD.TRANSACTION_ID => '||FGI_INV_RECORD.TRANSACTION_ID);


         ------------------------------------------------------------------Not complete-----------------------------------------------------
         IF L_PROCESSED_FLAG = 'Y'
         THEN
            /*----------------------Updating PROCESSED_STATUS as 'Y' in SC_FB02_DELTA_LRO table--------------------------------------------*/
            UPDATE CRPSC.SC_FC01_OH_DELTA_LRO_HIST
               SET PROCESSED_STATUS = 'Y'
             WHERE     PROCESSED_STATUS = 'N'
                   AND TO_NUMBER (PO_LINE_NUMBER) = FGI_INV_RECORD.LINE_NO
                   AND TO_CHAR (TRANSACTION_ID) = FGI_INV_RECORD.POE_BATCH_ID
                   AND REFRESH_PART_NUMBER = FGI_INV_RECORD.PRODUCT_ID
                   AND REFRESH_PART_NUMBER IN
                          (SELECT REFRESH_PART_NUMBER
                             FROM CRPADM.RC_PRODUCT_MASTER
                            WHERE PROGRAM_TYPE = 0);

            /*----------------------Updating PROCESSED_STATUS as 'Y' in SC_FB02_DELTA_FVE table--------------------------------------------*/
            --Commented as part of US390864
            --            UPDATE CRPSC.SC_FB02_DELTA_FVE_HIST
            --               SET PROCESSED_STATUS = 'Y'
            --             WHERE     PROCESSED_STATUS = 'N'
            --                   AND TO_NUMBER (PO_LINE_NUMBER) = FGI_INV_RECORD.LINE_NO
            --                   AND TO_CHAR (TRANSACTION_ID) = FGI_INV_RECORD.POE_BATCH_ID
            --                   AND REFRESH_PART_NUMBER = FGI_INV_RECORD.PRODUCT_ID
            --                   AND REFRESH_PART_NUMBER IN
            --                          (SELECT REFRESH_PART_NUMBER
            --                             FROM CRPADM.RC_PRODUCT_MASTER
            --                            WHERE PROGRAM_TYPE = 0);
            --Added as part of US390864
            UPDATE CRPSC.RC_FC01_OH_DELTA_FVE_HIST
               SET PROCESSED_STATUS = 'Y'
             WHERE     PROCESSED_STATUS = 'N'
                   AND TO_NUMBER (PO_LINE_NUMBER) = FGI_INV_RECORD.LINE_NO
                   AND TO_CHAR (TRANSACTION_ID) = FGI_INV_RECORD.POE_BATCH_ID
                   AND REFRESH_PART_NUMBER = FGI_INV_RECORD.PRODUCT_ID
                   AND REFRESH_PART_NUMBER IN
                          (SELECT REFRESH_PART_NUMBER
                             FROM CRPADM.RC_PRODUCT_MASTER
                            WHERE PROGRAM_TYPE = 0);
         END IF;
      END LOOP;

      CLOSE FGI_CURSOR_DELTA;


      INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                             CHL_STATUS,
                                             CHL_START_TIMESTAMP,
                                             CHL_END_TIMESTAMP,
                                             CHL_CRON_NAME,
                                             CHL_COMMENTS,
                                             CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'SUCCESS',
                   L_START_TIME,
                   SYSDATE,
                   G_PROC_NAME,
                   P_SITE_CODE,                                        --NULL,
                   'RC_INV_DELTA_LOAD_RF');

      UPDATE RMKTGADM.CRON_CONTROL_INFO
         SET CRON_START_TIMESTAMP = G_START_TIME,
             CRON_END_TIMESTAMP = SYSDATE,
             CRON_STATUS = 'SUCCESS'
       WHERE     CRON_NAME = 'RC_INV_RF_FGI_EXTRACT'
             AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'RF_MAIN';


      G_PROC_NAME := 'RC_INV_RF_FGI_EXTRACT';

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'FAILED',
                      L_START_TIME,
                      SYSDATE,
                      G_PROC_NAME,
                      P_SITE_CODE || '-' || G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_RF');

         --  G_PROC_NAME := 'RC_INV_RF_FGI_EXTRACT';

         UPDATE RMKTGADM.CRON_CONTROL_INFO
            SET CRON_START_TIMESTAMP = G_START_TIME,
                CRON_END_TIMESTAMP = SYSDATE,
                CRON_STATUS = 'FAILED'
          WHERE     CRON_NAME = 'RC_INV_RF_FGI_EXTRACT'
                AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'RF_MAIN';


         COMMIT;

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_RF_FGI_EXTRACT;

   /* Start Modified RC_INV_RF_FGI_ROHS_NROHS_MOVE as there was RoHS/Non RoHS Movements Issue on 3rd Aug 2018 by sridvasu */

   /* Start Rohs/NRohs move as part of US164572 on 02-APR-2018 */

   PROCEDURE RC_INV_RF_FGI_ROHS_NROHS_MOVE
   IS
      CURSOR ROHS_NROHS_ADJ
      IS
         SELECT DISTINCT
                pm.refresh_part_number,
                mv.part_no,
                'LRO' Site_Code,
                --                  DECODE (SUBSTR (MOVE_FROM_LOC, 1, 10),'LRO-INV.RH', 'YES','LRO-INV.NR', 'NO') ROHS_COMPLIANT,
                'NO'  ROHS_COMPLIANT,
                  --
                  --                  NVL ((  SELECT SUM (imv.quantity) FROM CRPSC.RC_DLP_ROHS_NONROHS imv
                  --                         WHERE     mv.part_no = imv.part_no
                  --                               AND SUBSTR (mv.MOVE_FROM_LOC, 1, 10) = SUBSTR (imv.MOVE_FROM_LOC, 1, 10) AND trunc(created_on) = '26-JUL-2018'--PROCESSED_FLAG = 'N'
                  --                               AND imv.direction = '-'
                  --                               GROUP BY part_no), 0) Adjustment_Qty,
                  --
                  NVL (
                     (SELECT SUM (quantity)
                        FROM crpsc.RC_DLP_ROHS_NONROHS imv
                       WHERE     imv.part_no = mv.part_no
                             AND processed_flag = 'N'
                             AND SUBSTR (move_from_loc, 1, 10) = 'LRO-INV.NR'),
                     0)
                - NVL (
                     (SELECT SUM (quantity)
                        FROM crpsc.RC_DLP_ROHS_NONROHS imv
                       WHERE     imv.part_no = mv.part_no
                             AND processed_flag = 'N'
                             AND SUBSTR (move_from_loc, 1, 10) = 'LRO-INV.RH'),
                     0)
                   Adjustment_Qty,
                  NVL (
                     (SELECT SUM (available_to_reserve_fgi)
                        FROM xxcpo_rmk_inventory_master im
                       WHERE     im.part_number = pm.refresh_part_number
                             AND im.site_code = 'LRO'
                             AND im.rohs_compliant = 'YES'
                             AND im.available_fgi > 0
                             AND im.Inventory_Flow =
                                    DECODE (
                                       SUBSTR (
                                          refresh_part_number,
                                          LENGTH (refresh_part_number) - 1,
                                          2),
                                       'RF', 'Retail')
                             AND mv.direction = '-'),
                     0)
                + NVL (
                     (SELECT SUM (new_fgi)
                        FROM rc_inv_delta_split_log fgi
                       WHERE     fgi.part_number = pm.refresh_part_number
                             AND fgi.site_code = 'LRO'
                             AND fgi.rohs_compliant = 'YES' --and fgi.is_rohs = decode( substr(mv.MOVE_FROM_LOC,1,10), 'LRO-INV.RH' ,'YES', 'LRO-INV.NR', 'NO')
                             AND fgi.product_type = 'R'
                             AND mv.direction = '-'),
                     0)
                   Rohs_Retail_Qty,
                NVL (
                   (SELECT SUM (reserved_fgi)
                      FROM xxcpo_rmk_inventory_master im
                     WHERE     im.part_number = pm.refresh_part_number
                           AND im.site_code = 'LRO'
                           AND im.rohs_compliant = 'YES'
                           AND im.available_fgi > 0
                           AND im.Inventory_Flow =
                                  DECODE (
                                     SUBSTR (
                                        refresh_part_number,
                                        LENGTH (refresh_part_number) - 1,
                                        2),
                                     'RF', 'Retail')
                           AND mv.direction = '-'),
                   0)
                   Rohs_Retail_Res_Qty,
                  --
                  NVL (
                     (SELECT SUM (available_to_reserve_fgi)
                        FROM xxcpo_rmk_inventory_master im
                       WHERE     im.part_number = pm.refresh_part_number
                             AND im.site_code = 'LRO'
                             AND im.rohs_compliant = 'NO'
                             AND im.available_fgi > 0
                             AND im.Inventory_Flow =
                                    DECODE (
                                       SUBSTR (
                                          refresh_part_number,
                                          LENGTH (refresh_part_number) - 1,
                                          2),
                                       'RF', 'Retail')
                             AND mv.direction = '-'),
                     0)
                + NVL (
                     (SELECT SUM (new_fgi)
                        FROM rc_inv_delta_split_log fgi
                       WHERE     fgi.part_number = pm.refresh_part_number
                             AND fgi.site_code = 'LRO'
                             AND fgi.rohs_compliant = 'NO' --and fgi.is_rohs = decode( substr(mv.MOVE_FROM_LOC,1,10), 'LRO-INV.RH' ,'YES', 'LRO-INV.NR', 'NO')
                             AND fgi.product_type = 'R'
                             AND mv.direction = '-'),
                     0)
                   NRohs_Retail_Qty,
                NVL (
                   (SELECT SUM (reserved_fgi)
                      FROM xxcpo_rmk_inventory_master im
                     WHERE     im.part_number = pm.refresh_part_number
                           AND im.site_code = 'LRO'
                           AND im.rohs_compliant = 'NO'
                           AND im.available_fgi > 0
                           AND im.Inventory_Flow =
                                  DECODE (
                                     SUBSTR (
                                        refresh_part_number,
                                        LENGTH (refresh_part_number) - 1,
                                        2),
                                     'RF', 'Retail')
                           AND mv.direction = '-'),
                   0)
                   NRohs_Retail_res_Qty,
                  --
                  NVL (
                     (SELECT SUM (available_to_reserve_fgi)
                        FROM xxcpo_rmk_inventory_master im
                       WHERE     im.part_number = pm.refresh_part_number
                             AND im.site_code = 'LRO'
                             AND im.rohs_compliant = 'YES'
                             AND im.available_fgi > 0
                             AND im.Inventory_Flow =
                                    DECODE (
                                       SUBSTR (
                                          refresh_part_number,
                                          LENGTH (refresh_part_number) - 1,
                                          2),
                                       'RF', 'Outlet')
                             AND mv.direction = '-'),
                     0)
                + NVL (
                     (SELECT SUM (new_fgi)
                        FROM rc_inv_delta_split_log fgi
                       WHERE     fgi.part_number = pm.refresh_part_number
                             AND fgi.site_code = 'LRO'
                             AND fgi.rohs_compliant = 'YES' --and fgi.is_rohs = decode( substr(mv.MOVE_FROM_LOC,1,10), 'LRO-INV.RH' ,'YES', 'LRO-INV.NR', 'NO')
                             AND fgi.product_type = 'O'
                             AND mv.direction = '-'),
                     0)
                   Rohs_Outlet_Qty,
                NVL (
                   (SELECT SUM (Reserved_FGI)
                      FROM xxcpo_rmk_inventory_master im
                     WHERE     im.part_number = pm.refresh_part_number
                           AND im.site_code = 'LRO'
                           AND im.rohs_compliant = 'YES'
                           AND im.available_fgi > 0
                           AND im.Inventory_Flow =
                                  DECODE (
                                     SUBSTR (
                                        refresh_part_number,
                                        LENGTH (refresh_part_number) - 1,
                                        2),
                                     'RF', 'Outlet')
                           AND mv.direction = '-'),
                   0)
                   Rohs_Outlet_Res_Qty,
                  --
                  NVL (
                     (SELECT SUM (available_to_reserve_fgi)
                        FROM xxcpo_rmk_inventory_master im
                       WHERE     im.part_number = pm.refresh_part_number
                             AND im.site_code = 'LRO'
                             AND im.rohs_compliant = 'NO'
                             AND im.available_fgi > 0
                             AND im.Inventory_Flow =
                                    DECODE (
                                       SUBSTR (
                                          refresh_part_number,
                                          LENGTH (refresh_part_number) - 1,
                                          2),
                                       'RF', 'Outlet')
                             AND mv.direction = '-'),
                     0)
                + NVL (
                     (SELECT SUM (new_fgi)
                        FROM rc_inv_delta_split_log fgi
                       WHERE     fgi.part_number = pm.refresh_part_number
                             AND fgi.site_code = 'LRO'
                             AND fgi.rohs_compliant = 'NO' --and fgi.is_rohs = decode( substr(mv.MOVE_FROM_LOC,1,10), 'LRO-INV.RH' ,'YES', 'LRO-INV.NR', 'NO')
                             AND fgi.product_type = 'O'
                             AND mv.direction = '-'),
                     0)
                   NRohs_Outlet_Qty,
                NVL (
                   (SELECT SUM (reserved_fgi)
                      FROM xxcpo_rmk_inventory_master im
                     WHERE     im.part_number = pm.refresh_part_number
                           AND im.site_code = 'LRO'
                           AND im.rohs_compliant = 'NO'
                           AND im.available_fgi > 0
                           AND im.Inventory_Flow =
                                  DECODE (
                                     SUBSTR (
                                        refresh_part_number,
                                        LENGTH (refresh_part_number) - 1,
                                        2),
                                     'RF', 'Outlet')
                           AND mv.direction = '-'),
                   0)
                   NRohs_Outlet_Res_Qty,
                NVL ( (SELECT LRO_RHS_QUANTITY
                         FROM RC_INV_STR_INV_MASK_MV
                        WHERE PARTNUMBER = pm.refresh_part_number),
                     0)                             --added NVL for PRB0066469
                   Rohs_Masked_Qty,
                NVL ( (SELECT LRO_NRHS_QUANTITY
                         FROM RC_INV_STR_INV_MASK_MV
                        WHERE PARTNUMBER = pm.refresh_part_number),
                     0)                             --added NVL for PRB0066469
                   NRohs_Masked_Qty
           FROM CRPSC.RC_DLP_ROHS_NONROHS mv
                INNER JOIN crpadm.rc_product_master pm
                   ON (mv.part_no = pm.tan_id)
          WHERE     1 = 1
                AND pm.refresh_part_number LIKE '%RF'
                AND processed_flag = 'N';

      --                              and pm.tan_id not in (select y.part_no
      --                                                            from
      --                                                            ( select part_no, sum(quantity) adjustment_qty from CRPSC.RC_DLP_ROHS_NONROHS where substr(MOVE_FROM_LOC,1,10) = 'LRO-INV.RH' and processed_flag = 'N' group by part_no) y ,
      --                                                            ( select part_no, sum(quantity) adjustment_qty from CRPSC.RC_DLP_ROHS_NONROHS where SUBSTR (MOVE_FROM_LOC, 1, 10) = 'LRO-INV.NR' and processed_flag = 'N' group by part_no) n
      --                                                            where y.part_no = n.part_no
      --                                                            and y.adjustment_qty - n.adjustment_qty = 0
      --                                                            ); -->> Summing up the quantity for the PIDs which are having from and to locations are same on 04-MAY-2018

      ROHS_NROHS_REC         ROHS_NROHS_ADJ%ROWTYPE;

      L_START_TIME           DATE;

      NROHS_RETAIL_ADJ_QTY   NUMBER;
      ROHS_RETAIL_ADJ_QTY    NUMBER;
      ROHS_OUTLET_ADJ_QTY    NUMBER;
      NROHS_OUTLET_ADJ_QTY   NUMBER;
      ROHS_MASK_ADJ_QTY      NUMBER;
      NROHS_MASK_ADJ_QTY     NUMBER;
      V_ADJUSTMENT_QTY       NUMBER;
      V_ROHS_COMPLIANT       VARCHAR2 (10);
   BEGIN
      G_PROC_NAME := 'RC_INV_RF_FGI_ROHS_NROHS_MOVE';

      L_START_TIME := SYSDATE;

      OPEN ROHS_NROHS_ADJ;

      LOOP
         FETCH ROHS_NROHS_ADJ INTO ROHS_NROHS_REC;

         EXIT WHEN ROHS_NROHS_ADJ%NOTFOUND;

         IF ROHS_NROHS_REC.ADJUSTMENT_QTY < 0
         THEN
            V_ROHS_COMPLIANT := 'YES';

            V_ADJUSTMENT_QTY := ABS (ROHS_NROHS_REC.ADJUSTMENT_QTY);

            IF ROHS_NROHS_REC.ROHS_OUTLET_QTY >= V_ADJUSTMENT_QTY
            THEN
               NROHS_RETAIL_ADJ_QTY := 0;
               ROHS_RETAIL_ADJ_QTY := 0;
               ROHS_MASK_ADJ_QTY := 0;
               NROHS_MASK_ADJ_QTY := 0;

               NROHS_OUTLET_ADJ_QTY := V_ADJUSTMENT_QTY;
               ROHS_OUTLET_ADJ_QTY := -V_ADJUSTMENT_QTY;
            ELSE
               NROHS_OUTLET_ADJ_QTY := ROHS_NROHS_REC.ROHS_OUTLET_QTY;
               ROHS_OUTLET_ADJ_QTY := -ROHS_NROHS_REC.ROHS_OUTLET_QTY;

               IF ROHS_NROHS_REC.ROHS_RETAIL_QTY >=
                     (V_ADJUSTMENT_QTY - ROHS_NROHS_REC.ROHS_OUTLET_QTY)
               THEN
                  ROHS_MASK_ADJ_QTY := 0;
                  NROHS_MASK_ADJ_QTY := 0;

                  NROHS_RETAIL_ADJ_QTY :=
                     V_ADJUSTMENT_QTY - ROHS_NROHS_REC.ROHS_OUTLET_QTY;
                  ROHS_RETAIL_ADJ_QTY :=
                     - (V_ADJUSTMENT_QTY - ROHS_NROHS_REC.ROHS_OUTLET_QTY);
               ELSIF (ROHS_NROHS_REC.ROHS_MASKED_QTY) >=
                        (  V_ADJUSTMENT_QTY
                         - ROHS_NROHS_REC.ROHS_OUTLET_QTY
                         - ROHS_NROHS_REC.ROHS_RETAIL_QTY)
               THEN
                  NROHS_RETAIL_ADJ_QTY := ROHS_NROHS_REC.ROHS_RETAIL_QTY;
                  ROHS_RETAIL_ADJ_QTY := -ROHS_NROHS_REC.ROHS_RETAIL_QTY;

                  ROHS_MASK_ADJ_QTY :=
                     - (  V_ADJUSTMENT_QTY
                        - ROHS_NROHS_REC.ROHS_OUTLET_QTY
                        - ROHS_NROHS_REC.ROHS_RETAIL_QTY);
               ELSIF (ROHS_NROHS_REC.ROHS_OUTLET_RES_QTY) >=
                        (  V_ADJUSTMENT_QTY
                         - ROHS_NROHS_REC.ROHS_OUTLET_QTY
                         - ROHS_NROHS_REC.ROHS_RETAIL_QTY
                         - ROHS_NROHS_REC.ROHS_MASKED_QTY)
               THEN
                  NROHS_RETAIL_ADJ_QTY := ROHS_NROHS_REC.ROHS_RETAIL_QTY;
                  ROHS_RETAIL_ADJ_QTY := -ROHS_NROHS_REC.ROHS_RETAIL_QTY;
                  ROHS_MASK_ADJ_QTY := ROHS_NROHS_REC.ROHS_MASKED_QTY;
                  NROHS_OUTLET_ADJ_QTY :=
                       NROHS_OUTLET_ADJ_QTY
                     + (  V_ADJUSTMENT_QTY
                        - ROHS_NROHS_REC.ROHS_OUTLET_QTY
                        - ROHS_NROHS_REC.ROHS_RETAIL_QTY
                        - ROHS_NROHS_REC.ROHS_MASKED_QTY);
                  ROHS_OUTLET_ADJ_QTY :=
                     - (  ROHS_OUTLET_ADJ_QTY
                        + (  V_ADJUSTMENT_QTY
                           - ROHS_NROHS_REC.ROHS_OUTLET_QTY
                           - ROHS_NROHS_REC.ROHS_RETAIL_QTY
                           - ROHS_NROHS_REC.ROHS_MASKED_QTY));
               ELSIF (ROHS_NROHS_REC.ROHS_RETAIL_RES_QTY) >=
                        (  V_ADJUSTMENT_QTY
                         - ROHS_NROHS_REC.ROHS_OUTLET_QTY
                         - ROHS_NROHS_REC.ROHS_RETAIL_QTY
                         - ROHS_NROHS_REC.ROHS_MASKED_QTY
                         - ROHS_NROHS_REC.ROHS_OUTLET_RES_QTY)
               THEN
                  ROHS_MASK_ADJ_QTY := ROHS_NROHS_REC.ROHS_MASKED_QTY;
                  NROHS_OUTLET_ADJ_QTY :=
                       NROHS_OUTLET_ADJ_QTY
                     + ROHS_NROHS_REC.ROHS_OUTLET_RES_QTY;
                  ROHS_OUTLET_ADJ_QTY :=
                     - (  ROHS_OUTLET_ADJ_QTY
                        + ROHS_NROHS_REC.ROHS_OUTLET_RES_QTY);
                  NROHS_RETAIL_ADJ_QTY :=
                       ROHS_NROHS_REC.ROHS_RETAIL_QTY
                     + (  V_ADJUSTMENT_QTY
                        - ROHS_NROHS_REC.ROHS_OUTLET_QTY
                        - ROHS_NROHS_REC.ROHS_RETAIL_QTY
                        - ROHS_NROHS_REC.ROHS_MASKED_QTY
                        - ROHS_NROHS_REC.ROHS_OUTLET_RES_QTY);
                  ROHS_RETAIL_ADJ_QTY :=
                     - (  ROHS_NROHS_REC.ROHS_RETAIL_QTY
                        + (  V_ADJUSTMENT_QTY
                           - ROHS_NROHS_REC.ROHS_OUTLET_QTY
                           - ROHS_NROHS_REC.ROHS_RETAIL_QTY
                           - ROHS_NROHS_REC.ROHS_MASKED_QTY
                           - ROHS_NROHS_REC.ROHS_OUTLET_RES_QTY));
               ELSE
                  NROHS_RETAIL_ADJ_QTY :=
                       ROHS_NROHS_REC.ROHS_RETAIL_QTY
                     + ROHS_NROHS_REC.ROHS_RETAIL_RES_QTY;
                  ROHS_RETAIL_ADJ_QTY :=
                     - (  ROHS_NROHS_REC.ROHS_RETAIL_QTY
                        + ROHS_NROHS_REC.ROHS_RETAIL_RES_QTY);
                  NROHS_OUTLET_ADJ_QTY :=
                       NROHS_OUTLET_ADJ_QTY
                     + ROHS_NROHS_REC.ROHS_OUTLET_RES_QTY;
                  ROHS_OUTLET_ADJ_QTY :=
                     - (  ROHS_OUTLET_ADJ_QTY
                        + ROHS_NROHS_REC.ROHS_OUTLET_RES_QTY);

                  ROHS_MASK_ADJ_QTY := -ROHS_NROHS_REC.ROHS_MASKED_QTY;

                  INSERT
                    INTO RC_INV_ROHS_MOVE_SHORT_ENTRIES (TAN_ID,
                                                         REFRESH_PART_NUMBER,
                                                         SITE_CODE,
                                                         ROHS_COMPLIANT,
                                                         SUGGESTED_ADJUSTMENT,
                                                         PROCESSED_ADJUSTMENT,
                                                         STATUS_FLAG,
                                                         CREATED_ON,
                                                         CREATED_BY,
                                                         UPDATED_ON,
                                                         UPDATED_BY)
                  VALUES (ROHS_NROHS_REC.PART_NO,
                          ROHS_NROHS_REC.REFRESH_PART_NUMBER,
                          ROHS_NROHS_REC.SITE_CODE,
                          V_ROHS_COMPLIANT,
                          V_ADJUSTMENT_QTY,
                          NROHS_OUTLET_ADJ_QTY + NROHS_RETAIL_ADJ_QTY,
                          'Y',
                          SYSDATE,
                          'RC_INV_RF_FGI_ROHS_NROHS_MOVE',
                          SYSDATE,
                          'RC_INV_RF_FGI_ROHS_NROHS_MOVE');
               END IF;
            END IF;


            INSERT INTO ROHS_NROHS_MOVE_ADJ_RF
                 VALUES (ROHS_NROHS_REC.REFRESH_PART_NUMBER,
                         ROHS_NROHS_REC.PART_NO,
                         ROHS_NROHS_REC.SITE_CODE,
                         ROHS_NROHS_REC.ROHS_COMPLIANT,
                         ROHS_NROHS_REC.ADJUSTMENT_QTY,
                         ROHS_NROHS_REC.ROHS_RETAIL_QTY,
                         ROHS_NROHS_REC.NROHS_RETAIL_QTY,
                         ROHS_NROHS_REC.ROHS_OUTLET_QTY,
                         ROHS_NROHS_REC.NROHS_OUTLET_QTY,
                         ROHS_RETAIL_ADJ_QTY,
                         NROHS_RETAIL_ADJ_QTY,
                         ROHS_OUTLET_ADJ_QTY,
                         NROHS_OUTLET_ADJ_QTY,
                         SYSDATE,
                         'RC_INV_RF_FGI_ROHS_NROHS_MOVE',
                         SYSDATE,
                         'RC_INV_RF_FGI_ROHS_NROHS_MOVE');

            -->> Insert for Rohs Retail

            INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG (INVENTORY_LOG_ID,
                                                        PART_NUMBER,
                                                        NEW_FGI,
                                                        NEW_DGI,
                                                        ROHS_COMPLIANT,
                                                        SITE_CODE,
                                                        PROCESS_STATUS,
                                                        UPDATED_ON,
                                                        UPDATED_BY,
                                                        CREATED_ON,
                                                        CREATED_BY,
                                                        POE_BATCH_ID,
                                                        PROGRAM_TYPE)
                 VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                         ROHS_NROHS_REC.REFRESH_PART_NUMBER,
                         ROHS_RETAIL_ADJ_QTY,
                         0,
                         'YES',
                         ROHS_NROHS_REC.SITE_CODE,
                         'N',
                         SYSDATE,
                         'POEADMIN',
                         SYSDATE,
                         'POEADMIN',
                         'RC_INV_RF_FGI_ROHS_NROHS_MOVE',
                         'R');

            -->> Insert for Non-Rohs Retail

            INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG (INVENTORY_LOG_ID,
                                                        PART_NUMBER,
                                                        NEW_FGI,
                                                        NEW_DGI,
                                                        ROHS_COMPLIANT,
                                                        SITE_CODE,
                                                        PROCESS_STATUS,
                                                        UPDATED_ON,
                                                        UPDATED_BY,
                                                        CREATED_ON,
                                                        CREATED_BY,
                                                        POE_BATCH_ID,
                                                        PROGRAM_TYPE)
                 VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                         ROHS_NROHS_REC.REFRESH_PART_NUMBER,
                         NROHS_RETAIL_ADJ_QTY + ABS (ROHS_MASK_ADJ_QTY),
                         0,
                         'NO',
                         ROHS_NROHS_REC.SITE_CODE,
                         'N',
                         SYSDATE,
                         'POEADMIN',
                         SYSDATE,
                         'POEADMIN',
                         'RC_INV_RF_FGI_ROHS_NROHS_MOVE',
                         'R');

            -->> Insert for Rohs Outlet

            INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG (INVENTORY_LOG_ID,
                                                        PART_NUMBER,
                                                        NEW_FGI,
                                                        NEW_DGI,
                                                        ROHS_COMPLIANT,
                                                        SITE_CODE,
                                                        PROCESS_STATUS,
                                                        UPDATED_ON,
                                                        UPDATED_BY,
                                                        CREATED_ON,
                                                        CREATED_BY,
                                                        POE_BATCH_ID,
                                                        PROGRAM_TYPE)
                 VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                         ROHS_NROHS_REC.REFRESH_PART_NUMBER,
                         ROHS_OUTLET_ADJ_QTY,
                         0,
                         'YES',
                         ROHS_NROHS_REC.SITE_CODE,
                         'N',
                         SYSDATE,
                         'POEADMIN',
                         SYSDATE,
                         'POEADMIN',
                         'RC_INV_RF_FGI_ROHS_NROHS_MOVE',
                         'O');

            -->> Insert for Non-Rohs Outlet
            -- Insert for modifications in masked quantity for LRO ROHS based on adjustments
            INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG (INVENTORY_LOG_ID,
                                                        PART_NUMBER,
                                                        NEW_FGI,
                                                        NEW_DGI,
                                                        ROHS_COMPLIANT,
                                                        SITE_CODE,
                                                        PROCESS_STATUS,
                                                        UPDATED_ON,
                                                        UPDATED_BY,
                                                        CREATED_ON,
                                                        CREATED_BY,
                                                        POE_BATCH_ID,
                                                        PROGRAM_TYPE)
                 VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                         ROHS_NROHS_REC.REFRESH_PART_NUMBER,
                         NROHS_OUTLET_ADJ_QTY,
                         0,
                         'NO',
                         ROHS_NROHS_REC.SITE_CODE,
                         'N',
                         SYSDATE,
                         'POEADMIN',
                         SYSDATE,
                         'POEADMIN',
                         'RC_INV_RF_FGI_ROHS_NROHS_MOVE',
                         'O');

            IF ABS (ROHS_MASK_ADJ_QTY) > 0
            THEN
               INSERT INTO RC_INV_STR_INV_MASK_STG (PARTNUMBER,
                                                    SITE,
                                                    ROHS,
                                                    MASKED_QTY,
                                                    CREATED_BY,
                                                    CREATED_AT,
                                                    PROCESSED_STATUS)
                    VALUES (ROHS_NROHS_REC.REFRESH_PART_NUMBER,
                            ROHS_NROHS_REC.SITE_CODE,
                            'YES',
                            ABS (ROHS_MASK_ADJ_QTY),
                            'ROHS_NONROHS_ADJUSTMENT',
                            SYSDATE,
                            'N');
            END IF;
         ELSIF ROHS_NROHS_REC.ADJUSTMENT_QTY > 0
         THEN
            V_ROHS_COMPLIANT := 'NO';

            V_ADJUSTMENT_QTY := ROHS_NROHS_REC.ADJUSTMENT_QTY;

            IF ROHS_NROHS_REC.NROHS_OUTLET_QTY >= V_ADJUSTMENT_QTY
            THEN
               ROHS_MASK_ADJ_QTY := 0;
               NROHS_MASK_ADJ_QTY := 0;
               NROHS_RETAIL_ADJ_QTY := 0;
               ROHS_RETAIL_ADJ_QTY := 0;
               ROHS_OUTLET_ADJ_QTY := V_ADJUSTMENT_QTY;
               NROHS_OUTLET_ADJ_QTY := -V_ADJUSTMENT_QTY;
            ELSE
               ROHS_OUTLET_ADJ_QTY := ROHS_NROHS_REC.NROHS_OUTLET_QTY;
               NROHS_OUTLET_ADJ_QTY := -ROHS_NROHS_REC.NROHS_OUTLET_QTY;

               IF ROHS_NROHS_REC.NROHS_RETAIL_QTY >=
                     (V_ADJUSTMENT_QTY - ROHS_NROHS_REC.NROHS_OUTLET_QTY)
               THEN
                  ROHS_MASK_ADJ_QTY := 0;
                  NROHS_MASK_ADJ_QTY := 0;

                  ROHS_RETAIL_ADJ_QTY :=
                     V_ADJUSTMENT_QTY - ROHS_NROHS_REC.NROHS_OUTLET_QTY;
                  NROHS_RETAIL_ADJ_QTY :=
                     - (V_ADJUSTMENT_QTY - ROHS_NROHS_REC.NROHS_OUTLET_QTY);
               ELSIF (ROHS_NROHS_REC.NROHS_MASKED_QTY) >=
                        (  V_ADJUSTMENT_QTY
                         - ROHS_NROHS_REC.NROHS_OUTLET_QTY
                         - ROHS_NROHS_REC.NROHS_RETAIL_QTY)
               THEN
                  ROHS_RETAIL_ADJ_QTY := ROHS_NROHS_REC.NROHS_RETAIL_QTY;
                  NROHS_RETAIL_ADJ_QTY := -ROHS_NROHS_REC.NROHS_RETAIL_QTY;

                  NROHS_MASK_ADJ_QTY :=
                     - (  V_ADJUSTMENT_QTY
                        - ROHS_NROHS_REC.NROHS_OUTLET_QTY
                        - ROHS_NROHS_REC.NROHS_RETAIL_QTY);
               ELSIF (ROHS_NROHS_REC.NROHS_OUTLET_RES_QTY) >=
                        (  V_ADJUSTMENT_QTY
                         - ROHS_NROHS_REC.NROHS_OUTLET_QTY
                         - ROHS_NROHS_REC.NROHS_RETAIL_QTY
                         - ROHS_NROHS_REC.NROHS_MASKED_QTY)
               THEN
                  NROHS_RETAIL_ADJ_QTY := -ROHS_NROHS_REC.NROHS_RETAIL_QTY;
                  ROHS_RETAIL_ADJ_QTY := ROHS_NROHS_REC.NROHS_RETAIL_QTY;
                  NROHS_MASK_ADJ_QTY := ROHS_NROHS_REC.NROHS_MASKED_QTY;
                  ROHS_OUTLET_ADJ_QTY :=
                       ROHS_OUTLET_ADJ_QTY
                     + (  V_ADJUSTMENT_QTY
                        - ROHS_NROHS_REC.NROHS_OUTLET_QTY
                        - ROHS_NROHS_REC.NROHS_RETAIL_QTY
                        - ROHS_NROHS_REC.NROHS_MASKED_QTY);
                  NROHS_OUTLET_ADJ_QTY :=
                     - (  NROHS_OUTLET_ADJ_QTY
                        + (  V_ADJUSTMENT_QTY
                           - ROHS_NROHS_REC.NROHS_OUTLET_QTY
                           - ROHS_NROHS_REC.NROHS_RETAIL_QTY
                           - ROHS_NROHS_REC.NROHS_MASKED_QTY));
               ELSIF (ROHS_NROHS_REC.NROHS_RETAIL_RES_QTY) >=
                        (  V_ADJUSTMENT_QTY
                         - ROHS_NROHS_REC.NROHS_OUTLET_QTY
                         - ROHS_NROHS_REC.NROHS_RETAIL_QTY
                         - ROHS_NROHS_REC.NROHS_MASKED_QTY
                         - ROHS_NROHS_REC.NROHS_OUTLET_RES_QTY)
               THEN
                  NROHS_MASK_ADJ_QTY := ROHS_NROHS_REC.NROHS_MASKED_QTY;
                  ROHS_OUTLET_ADJ_QTY :=
                       ROHS_OUTLET_ADJ_QTY
                     + ROHS_NROHS_REC.NROHS_OUTLET_RES_QTY;
                  NROHS_OUTLET_ADJ_QTY :=
                     - (  ROHS_OUTLET_ADJ_QTY
                        + ROHS_NROHS_REC.NROHS_OUTLET_RES_QTY);
                  ROHS_RETAIL_ADJ_QTY :=
                       ROHS_NROHS_REC.NROHS_RETAIL_QTY
                     + (  V_ADJUSTMENT_QTY
                        - ROHS_NROHS_REC.NROHS_OUTLET_QTY
                        - ROHS_NROHS_REC.NROHS_RETAIL_QTY
                        - ROHS_NROHS_REC.NROHS_MASKED_QTY
                        - ROHS_NROHS_REC.NROHS_OUTLET_RES_QTY);
                  NROHS_RETAIL_ADJ_QTY :=
                     - (  ROHS_NROHS_REC.NROHS_RETAIL_QTY
                        + (  V_ADJUSTMENT_QTY
                           - ROHS_NROHS_REC.NROHS_OUTLET_QTY
                           - ROHS_NROHS_REC.NROHS_RETAIL_QTY
                           - ROHS_NROHS_REC.NROHS_MASKED_QTY
                           - ROHS_NROHS_REC.NROHS_OUTLET_RES_QTY));
               ELSE
                  ROHS_RETAIL_ADJ_QTY :=
                       ROHS_NROHS_REC.NROHS_RETAIL_QTY
                     + ROHS_NROHS_REC.NROHS_RETAIL_RES_QTY;
                  NROHS_RETAIL_ADJ_QTY :=
                     - (  ROHS_NROHS_REC.NROHS_RETAIL_QTY
                        + ROHS_NROHS_REC.NROHS_RETAIL_RES_QTY);
                  ROHS_OUTLET_ADJ_QTY :=
                       ROHS_OUTLET_ADJ_QTY
                     + ROHS_NROHS_REC.NROHS_OUTLET_RES_QTY;
                  NROHS_OUTLET_ADJ_QTY :=
                     - (  NROHS_OUTLET_ADJ_QTY
                        + ROHS_NROHS_REC.NROHS_OUTLET_RES_QTY);

                  NROHS_MASK_ADJ_QTY := ROHS_NROHS_REC.NROHS_MASKED_QTY;


                  INSERT
                    INTO RC_INV_ROHS_MOVE_SHORT_ENTRIES (TAN_ID,
                                                         REFRESH_PART_NUMBER,
                                                         SITE_CODE,
                                                         ROHS_COMPLIANT,
                                                         SUGGESTED_ADJUSTMENT,
                                                         PROCESSED_ADJUSTMENT,
                                                         STATUS_FLAG,
                                                         CREATED_ON,
                                                         CREATED_BY,
                                                         UPDATED_ON,
                                                         UPDATED_BY)
                  VALUES (ROHS_NROHS_REC.PART_NO,
                          ROHS_NROHS_REC.REFRESH_PART_NUMBER,
                          ROHS_NROHS_REC.SITE_CODE,
                          V_ROHS_COMPLIANT,
                          V_ADJUSTMENT_QTY,
                          ROHS_OUTLET_ADJ_QTY + ROHS_RETAIL_ADJ_QTY,
                          'Y',
                          SYSDATE,
                          'RC_INV_RF_FGI_ROHS_NROHS_MOVE',
                          SYSDATE,
                          'RC_INV_RF_FGI_ROHS_NROHS_MOVE');
               END IF;
            END IF;

            INSERT INTO ROHS_NROHS_MOVE_ADJ_RF
                 VALUES (ROHS_NROHS_REC.REFRESH_PART_NUMBER,
                         ROHS_NROHS_REC.PART_NO,
                         ROHS_NROHS_REC.SITE_CODE,
                         ROHS_NROHS_REC.ROHS_COMPLIANT,
                         ROHS_NROHS_REC.ADJUSTMENT_QTY,
                         ROHS_NROHS_REC.ROHS_RETAIL_QTY,
                         ROHS_NROHS_REC.NROHS_RETAIL_QTY,
                         ROHS_NROHS_REC.ROHS_OUTLET_QTY,
                         ROHS_NROHS_REC.NROHS_OUTLET_QTY,
                         ROHS_RETAIL_ADJ_QTY,
                         NROHS_RETAIL_ADJ_QTY,
                         ROHS_OUTLET_ADJ_QTY,
                         NROHS_OUTLET_ADJ_QTY,
                         SYSDATE,
                         'RC_INV_RF_FGI_ROHS_NROHS_MOVE',
                         SYSDATE,
                         'RC_INV_RF_FGI_ROHS_NROHS_MOVE');

            -->> Insert for Rohs Retail

            INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG (INVENTORY_LOG_ID,
                                                        PART_NUMBER,
                                                        NEW_FGI,
                                                        NEW_DGI,
                                                        ROHS_COMPLIANT,
                                                        SITE_CODE,
                                                        PROCESS_STATUS,
                                                        UPDATED_ON,
                                                        UPDATED_BY,
                                                        CREATED_ON,
                                                        CREATED_BY,
                                                        POE_BATCH_ID,
                                                        PROGRAM_TYPE)
                 VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                         ROHS_NROHS_REC.REFRESH_PART_NUMBER,
                         ROHS_RETAIL_ADJ_QTY + ABS (NROHS_MASK_ADJ_QTY),
                         0,
                         'YES',
                         ROHS_NROHS_REC.SITE_CODE,
                         'N',
                         SYSDATE,
                         'POEADMIN',
                         SYSDATE,
                         'POEADMIN',
                         'RC_INV_RF_FGI_ROHS_NROHS_MOVE',
                         'R');

            -->> Insert for Non-Rohs Retail

            INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG (INVENTORY_LOG_ID,
                                                        PART_NUMBER,
                                                        NEW_FGI,
                                                        NEW_DGI,
                                                        ROHS_COMPLIANT,
                                                        SITE_CODE,
                                                        PROCESS_STATUS,
                                                        UPDATED_ON,
                                                        UPDATED_BY,
                                                        CREATED_ON,
                                                        CREATED_BY,
                                                        POE_BATCH_ID,
                                                        PROGRAM_TYPE)
                 VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                         ROHS_NROHS_REC.REFRESH_PART_NUMBER,
                         NROHS_RETAIL_ADJ_QTY,
                         0,
                         'NO',
                         ROHS_NROHS_REC.SITE_CODE,
                         'N',
                         SYSDATE,
                         'POEADMIN',
                         SYSDATE,
                         'POEADMIN',
                         'RC_INV_RF_FGI_ROHS_NROHS_MOVE',
                         'R');


            -->> Insert for Rohs Outlet

            INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG (INVENTORY_LOG_ID,
                                                        PART_NUMBER,
                                                        NEW_FGI,
                                                        NEW_DGI,
                                                        ROHS_COMPLIANT,
                                                        SITE_CODE,
                                                        PROCESS_STATUS,
                                                        UPDATED_ON,
                                                        UPDATED_BY,
                                                        CREATED_ON,
                                                        CREATED_BY,
                                                        POE_BATCH_ID,
                                                        PROGRAM_TYPE)
                 VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                         ROHS_NROHS_REC.REFRESH_PART_NUMBER,
                         ROHS_OUTLET_ADJ_QTY,
                         0,
                         'YES',
                         ROHS_NROHS_REC.SITE_CODE,
                         'N',
                         SYSDATE,
                         'POEADMIN',
                         SYSDATE,
                         'POEADMIN',
                         'RC_INV_RF_FGI_ROHS_NROHS_MOVE',
                         'O');

            -->> Insert for Non-Rohs Outlet

            INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG (INVENTORY_LOG_ID,
                                                        PART_NUMBER,
                                                        NEW_FGI,
                                                        NEW_DGI,
                                                        ROHS_COMPLIANT,
                                                        SITE_CODE,
                                                        PROCESS_STATUS,
                                                        UPDATED_ON,
                                                        UPDATED_BY,
                                                        CREATED_ON,
                                                        CREATED_BY,
                                                        POE_BATCH_ID,
                                                        PROGRAM_TYPE)
                 VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                         ROHS_NROHS_REC.REFRESH_PART_NUMBER,
                         NROHS_OUTLET_ADJ_QTY,
                         0,
                         'NO',
                         ROHS_NROHS_REC.SITE_CODE,
                         'N',
                         SYSDATE,
                         'POEADMIN',
                         SYSDATE,
                         'POEADMIN',
                         'RC_INV_RF_FGI_ROHS_NROHS_MOVE',
                         'O');


            -- Insert for modifications in masked quantity for LRO NONROHS based on adjustments
            IF ABS (NROHS_MASK_ADJ_QTY) > 0
            THEN
               INSERT INTO RC_INV_STR_INV_MASK_STG (PARTNUMBER,
                                                    SITE,
                                                    ROHS,
                                                    MASKED_QTY,
                                                    CREATED_BY,
                                                    CREATED_AT,
                                                    PROCESSED_STATUS)
                    VALUES (ROHS_NROHS_REC.REFRESH_PART_NUMBER,
                            ROHS_NROHS_REC.SITE_CODE,
                            'NO',
                            ABS (NROHS_MASK_ADJ_QTY),
                            'ROHS_NONROHS_ADJUSTMENT',
                            SYSDATE,
                            'N');
            END IF;
         ELSIF ROHS_NROHS_REC.ADJUSTMENT_QTY = 0
         THEN
            ROHS_RETAIL_ADJ_QTY := 0;
            NROHS_RETAIL_ADJ_QTY := 0;
            ROHS_OUTLET_ADJ_QTY := 0;
            NROHS_OUTLET_ADJ_QTY := 0;
            ROHS_MASK_ADJ_QTY := 0;
            NROHS_MASK_ADJ_QTY := 0;
         END IF;

         -->> Updating processed flag to Y

         UPDATE CRPSC.RC_DLP_ROHS_NONROHS
            SET PROCESSED_FLAG = 'Y'
          WHERE PART_NO = ROHS_NROHS_REC.PART_NO;
      END LOOP;

      CLOSE ROHS_NROHS_ADJ;


      /* Start Added update statement to flag the records which are having same location same qty adjustment to Y on 04-MAY-2018 */

      --    update crpsc.rc_dlp_rohs_nonrohs
      --    set processed_flag = 'Y'
      --        where processed_flag = 'N'
      --              and part_no in (select y.part_no
      --                                            from
      --                                            ( select part_no, sum(quantity) adjustment_qty from CRPSC.RC_DLP_ROHS_NONROHS where substr(MOVE_FROM_LOC,1,10) = 'LRO-INV.RH' and processed_flag = 'N' group by part_no) y ,
      --                                            ( select part_no, sum(quantity) adjustment_qty from CRPSC.RC_DLP_ROHS_NONROHS where SUBSTR (MOVE_FROM_LOC, 1, 10) = 'LRO-INV.NR' and processed_flag = 'N' group by part_no) n
      --                                            where y.part_no = n.part_no
      --                                            and y.adjustment_qty - n.adjustment_qty = 0
      --                                                    )
      --              and part_no in (select tan_id from crpadm.rc_product_master where refresh_part_number like '%RF');
      --
      --    COMMIT;

      /* End Added update statement to flag the records which are having same location same qty adjustment to Y on 04-MAY-2018 */


      DELETE FROM RMK_INVENTORY_LOG_STG
            WHERE     NEW_FGI = 0
                  AND POE_BATCH_ID = 'RC_INV_RF_FGI_ROHS_NROHS_MOVE';

      --      to Insert the Delta inv into  rmk_inventory_log from  rmk_inventory_log_stg


      INSERT INTO RMK_INVENTORY_LOG
         SELECT *
           FROM RMK_INVENTORY_LOG_STG
          WHERE     ATTRIBUTE1 IS NULL
                AND POE_BATCH_ID = 'RC_INV_RF_FGI_ROHS_NROHS_MOVE';

      --      Updating the rmk_inventory_log_stg table after processing the Delta Inv.
      UPDATE RMK_INVENTORY_LOG_STG
         SET ATTRIBUTE1 = 'PROCESSED'
       WHERE     ATTRIBUTE1 IS NULL
             AND POE_BATCH_ID = 'RC_INV_RF_FGI_ROHS_NROHS_MOVE';


      COMMIT;

      -->> Success entry for the proc

      INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                             CHL_STATUS,
                                             CHL_START_TIMESTAMP,
                                             CHL_END_TIMESTAMP,
                                             CHL_CRON_NAME,
                                             CHL_COMMENTS,
                                             CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'SUCCESS',
                   L_START_TIME,
                   SYSDATE,
                   G_PROC_NAME,
                   NULL,
                   'RC_INV_DELTA_LOAD_RF');
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'FAILED',
                      L_START_TIME,
                      SYSDATE,
                      G_PROC_NAME,
                      G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_RF');

         G_PROC_NAME := 'RC_INV_RF_FGI_ROHS_NROHS_MOVE';

         COMMIT;

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_RF_FGI_ROHS_NROHS_MOVE;

   /* End Rohs/NRohs move as part of US164572 on 02-APR-2018 */

   /* End Modified RC_INV_RF_FGI_ROHS_NROHS_MOVE as there was RoHS/Non RoHS Movements Issue on 3rd Aug 2018 by sridvasu */

   PROCEDURE RC_INV_RF_DGI_PUT_REMINDERS
   IS
      V_REMINDER_VALUE   NUMBER (10, 2);
      V_SEQ              NUMBER;


      CURSOR DGI_CURSOR_DELTA
      IS
           /**Start modified cursor as part of Apr 17 Release for Rounding at product level**/
           SELECT PRODUCT_ID,
                  PRODUCT_TYPE,
                  SOURCE_SYSTEM,
                  SUM (DELTA_DGI) DELTA_DGI
             -->> SITE_SHORTNAME,
             -->> INVENTORY_TYPE
             FROM RMKTGADM.RC_INV_DGI_DELTA
            WHERE PRODUCT_TYPE = 'R'
         GROUP BY PRODUCT_ID, PRODUCT_TYPE,               -->> SITE_SHORTNAME,
                                           SOURCE_SYSTEM;

      -->>INVENTORY_TYPE;

      /**End modified cursor as part of Apr 17 Release for Rounding at product level**/


      DGI_INV_RECORD     DGI_CURSOR_DELTA%ROWTYPE;
      V_INV_LOG_PK       NUMBER; --Added as part of Apr 17 Release for Rounding at product level
      L_START_TIME       DATE;
   BEGIN
      G_PROC_NAME := 'RC_INV_RF_DGI_PUT_REMINDERS';
      L_START_TIME := SYSDATE;


      OPEN DGI_CURSOR_DELTA;

      LOOP
         FETCH DGI_CURSOR_DELTA INTO DGI_INV_RECORD;

         EXIT WHEN DGI_CURSOR_DELTA%NOTFOUND;



         V_REMINDER_VALUE :=
            ROUND (DGI_INV_RECORD.DELTA_DGI) - DGI_INV_RECORD.DELTA_DGI;

         IF (V_REMINDER_VALUE) != 0
         THEN
            V_INV_LOG_PK := RC_INV_LOG_PK_SEQ.NEXTVAL; --Added as part of Apr 17 Release for Rounding at product level

            INSERT
              INTO RMKTGADM.RC_INV_DGI_ROUNDED_VALUES (INV_LOG_PK,
                                                       PRODUCT_ID,
                                                       -->> SITE_SHORTNAME,
                                                       REMINDER_VALUE,
                                                       PROCESSED_STATUS,
                                                       CREATED_BY,
                                                       CREATION_DATE,
                                                       LAST_UPDATED_DATE,
                                                       LAST_UPDATED_BY,
                                                       PRODUCT_TYPE,
                                                       SOURCE_SYSTEM)
            --  SOURCE_SYSTEM, -- Commented as part of Apr 17 Release for Rounding at product level
            --  INVENTORY_TYPE)-- Commented as part of Apr 17 Release for Rounding at product level
            VALUES (V_INV_LOG_PK,
                    DGI_INV_RECORD.PRODUCT_ID,
                    -->> DGI_INV_RECORD.SITE_SHORTNAME,
                    - (V_REMINDER_VALUE),
                    'N',
                    'POEADMIN',
                    SYSDATE,
                    SYSDATE,
                    'POEADMIN',
                    DGI_INV_RECORD.PRODUCT_TYPE,
                    DGI_INV_RECORD.SOURCE_SYSTEM);

            --   DGI_INV_RECORD.SOURCE_SYSTEM,  -- Commented as part of Apr 17 Release for Rounding at product level
            --   DGI_INV_RECORD.INVENTORY_TYPE);-- Commented as part of Apr 17 Release for Rounding at product level


            UPDATE RMKTGADM.RC_INV_DGI_DELTA
               SET DELTA_DGI = ROUND (DGI_INV_RECORD.DELTA_DGI)
             WHERE     1 = 1
                   AND PRODUCT_ID = DGI_INV_RECORD.PRODUCT_ID
                   -->> AND SITE_SHORTNAME = DGI_INV_RECORD.SITE_SHORTNAME
                   AND PRODUCT_TYPE = DGI_INV_RECORD.PRODUCT_TYPE
                   AND SOURCE_SYSTEM = DGI_INV_RECORD.SOURCE_SYSTEM;

            -->> AND INVENTORY_TYPE = DGI_INV_RECORD.INVENTORY_TYPE;-- Commented as part of Apr 17 Release for Rounding at product level
            COMMIT;
         END IF;
      END LOOP;

      CLOSE DGI_CURSOR_DELTA;

      INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                             CHL_STATUS,
                                             CHL_START_TIMESTAMP,
                                             CHL_END_TIMESTAMP,
                                             CHL_CRON_NAME,
                                             CHL_COMMENTS,
                                             CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'SUCCESS',
                   L_START_TIME,
                   SYSDATE,
                   G_PROC_NAME,
                   NULL,
                   'RC_INV_DELTA_LOAD_RF');

      G_PROC_NAME := 'RC_INV_RF_DGI_PUT_REMINDERS';
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'FAILED',
                      L_START_TIME,
                      SYSDATE,
                      G_PROC_NAME,
                      G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_RF');

         G_PROC_NAME := 'RC_INV_RF_DGI_PUT_REMINDERS';

         COMMIT;

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_RF_DGI_PUT_REMINDERS;


   PROCEDURE RC_INV_RF_DGI_GET_REMINDERS
   IS
      V_ROUND_VALUE      NUMBER (10, 2);
      V_REMINDER_VALUE   NUMBER (10, 2);
      V_DELTA_DGI        NUMBER (10, 2);
      V_INV_LOG_PK       NUMBER;
      V_ROHS_SITE        VARCHAR (3);
      L_START_TIME       DATE;



      CURSOR DGI_CURSOR_RND
      IS
           SELECT PRODUCT_ID, PRODUCT_TYPE, SUM (REMINDER_VALUE) AS DELTA_DGI
             --     SITE_SHORTNAME
             --    INVENTORY_TYPE,  --Commented as part of Apr 17 Release for Rounding at product level
             --     SOURCE_SYSTEM    --Commented as part of Apr 17 Release for Rounding at product level
             FROM RMKTGADM.RC_INV_DGI_ROUNDED_VALUES
            WHERE PROCESSED_STATUS = 'N' AND PRODUCT_TYPE = 'R'
         GROUP BY PRODUCT_ID, PRODUCT_TYPE              -->>> , SITE_SHORTNAME
           --      INVENTORY_TYPE,   --Commented as part of Apr 17 Release for Rounding at product level
           --      SOURCE_SYSTEM     --Commented as part of Apr 17 Release for Rounding at product level
           HAVING SUM (REMINDER_VALUE) >= 1 OR SUM (REMINDER_VALUE) <= -1;

      DGI_RND_REC        DGI_CURSOR_RND%ROWTYPE;
   BEGIN
      G_PROC_NAME := 'RC_INV_RF_DGI_GET_REMINDERS';
      L_START_TIME := SYSDATE;


      OPEN DGI_CURSOR_RND;

      LOOP
         FETCH DGI_CURSOR_RND INTO DGI_RND_REC;

         EXIT WHEN DGI_CURSOR_RND%NOTFOUND;



         V_ROUND_VALUE := ROUND (DGI_RND_REC.DELTA_DGI);


         IF (V_ROUND_VALUE <= -1) OR (V_ROUND_VALUE >= 1)
         THEN
            UPDATE RMKTGADM.RC_INV_DGI_ROUNDED_VALUES
               SET PROCESSED_STATUS = 'Y', LAST_UPDATED_DATE = SYSDATE
             WHERE     PRODUCT_ID = DGI_RND_REC.PRODUCT_ID
                   --   AND SITE_SHORTNAME = DGI_RND_REC.SITE_SHORTNAME
                   AND PROCESSED_STATUS = 'N'
                   AND PRODUCT_TYPE = DGI_RND_REC.PRODUCT_TYPE;



            V_INV_LOG_PK := RC_INV_LOG_PK_SEQ.NEXTVAL;


            INSERT INTO RMKTGADM.RC_INV_DGI_DELTA (INV_LOG_PK,
                                                   PRODUCT_ID,
                                                   DELTA_DGI,
                                                   IS_ROHS,
                                                   --      SITE_SHORTNAME,
                                                   CREATED_ON,
                                                   CREATED_BY,
                                                   UPDATED_ON,
                                                   UPDATED_BY,
                                                   PRODUCT_TYPE,
                                                   SOURCE_SYSTEM)
                 --  INVENTORY_TYPE)   --Commented as part of Apr 17 Release for Rounding at product level
                 VALUES (V_INV_LOG_PK,
                         DGI_RND_REC.PRODUCT_ID,
                         ROUND (V_ROUND_VALUE),
                         'YES',
                         --       DGI_RND_REC.SITE_SHORTNAME,
                         SYSDATE,
                         'POEADMIN',
                         SYSDATE,
                         'POEADMIN',
                         DGI_RND_REC.PRODUCT_TYPE,
                         'RC_INV_RF_DGI_GET_REMINDERS'); --Added  as part of Apr 17 Release for Rounding at product level

            --DGI_RND_REC.INVENTORY_TYPE);

            V_REMINDER_VALUE :=
               ROUND (DGI_RND_REC.DELTA_DGI) - DGI_RND_REC.DELTA_DGI;

            IF V_REMINDER_VALUE != 0
            THEN
               INSERT
                 INTO RMKTGADM.RC_INV_DGI_ROUNDED_VALUES (INV_LOG_PK,
                                                          PRODUCT_ID,
                                                          --        SITE_SHORTNAME,
                                                          REMINDER_VALUE,
                                                          PROCESSED_STATUS,
                                                          CREATED_BY,
                                                          CREATION_DATE,
                                                          LAST_UPDATED_DATE,
                                                          LAST_UPDATED_BY,
                                                          PRODUCT_TYPE)
               --SOURCE_SYSTEM,  --Commented as part of Apr 17 Release for Rounding at product level
               --INVENTORY_TYPE)  --Commented as part of Apr 17 Release for Rounding at product level
               VALUES (V_INV_LOG_PK,
                       DGI_RND_REC.PRODUCT_ID,
                       --    DGI_RND_REC.SITE_SHORTNAME,
                       - (V_REMINDER_VALUE),
                       'N',
                       'POEADMIN',
                       G_START_TIME,
                       SYSDATE,
                       'POEADMIN',
                       DGI_RND_REC.PRODUCT_TYPE);
            --DGI_RND_REC.SOURCE_SYSTEM,   --Commented as part of Apr 17 Release for Rounding at product level
            --DGI_RND_REC.INVENTORY_TYPE); --Commented as part of Apr 17 Release for Rounding at product level
            END IF;
         END IF;
      END LOOP;

      CLOSE DGI_CURSOR_RND;

      INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                             CHL_STATUS,
                                             CHL_START_TIMESTAMP,
                                             CHL_END_TIMESTAMP,
                                             CHL_CRON_NAME,
                                             CHL_COMMENTS,
                                             CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'SUCCESS',
                   L_START_TIME,
                   SYSDATE,
                   G_PROC_NAME,
                   NULL,
                   'RC_INV_DELTA_LOAD_RF');

      G_PROC_NAME := 'RC_INV_RF_DGI_GET_REMINDERS';
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'FAILED',
                      L_START_TIME,
                      SYSDATE,
                      G_PROC_NAME,
                      G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_RF');

         G_PROC_NAME := 'RC_INV_RF_DGI_GET_REMINDERS';

         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_RF_DGI_GET_REMINDERS;

   /* Start Commented as part of Selling FGI only requirement for Oct 27 Release on 15-OCT-2018 */

   --   PROCEDURE RC_INV_OUTLET_BTS_SPLIT
   --   --->> Regular Outlet Allocation
   --   AS
   --      V_REQUIRED_OUTLET    NUMBER;
   --      V_REQUIRED_RETAIL    NUMBER;
   --      V_RETAIL_ALLOC_QTY   NUMBER;
   --      V_OUTLET_ALLOC_QTY   NUMBER;
   --      V_LRO_ROHS_OUTLET    NUMBER;
   --      V_LRO_NROHS_OUTLET   NUMBER;
   --      V_FVE_ROHS_OUTLET    NUMBER;
   --      V_LRO_ROHS_RETAIL    NUMBER;
   --      V_LRO_NROHS_RETAIL   NUMBER;
   --      V_FVE_ROHS_RETAIL    NUMBER;
   --      V_OUTLET_CAP         NUMBER;
   --      L_START_TIME         DATE;
   --
   --      CURSOR REG_OUT
   --      IS
   --           SELECT DISTINCT
   --                  SYSDATE                        AS RECORD_CREATED_DATE,
   --                  PM.REFRESH_PART_NUMBER,
   --                  TRUNC (PM.NPI_CREATION_DATE)   NPI_CREATION_DATE,
   --                  NVL (MOS.MOS, 0)               MOS,
   --                  --                  NVL (CM.RF_GLOBAL_CUR_MAX, 0) RETAIL_MAX, -- commented as part of August Sprint
   --                  --                     CASE
   --                  --                        WHEN MSR.YTD_AVG_SALES_PRICE <= 750 THEN 250 -- Same
   --                  --                        WHEN MSR.YTD_AVG_SALES_PRICE BETWEEN 751 AND 5000 THEN 50 -- Old Value: 10
   --                  --                        WHEN MSR.YTD_AVG_SALES_PRICE BETWEEN 5001 AND 10000 THEN 25 -- Old Value: 5
   --                  --                        WHEN MSR.YTD_AVG_SALES_PRICE BETWEEN 10001 AND 25000 THEN 10 -- Old Value: 3
   --                  --                        WHEN MSR.YTD_AVG_SALES_PRICE > 25000 THEN 5 -- Old Value: 1
   --                  --                        WHEN YTD_AVG_SALES_PRICE  IS NULL THEN 10 -- Old 0
   --                  --                     END
   --                  /* AVG SALES PRICE Control as part of August Sprint */
   --                  CASE
   --                     WHEN MSR.YTD_AVG_SALES_PRICE <= 750
   --                     THEN
   --                        (SELECT RC_INV_CONTROL_VALUE
   --                           FROM RC_INV_CONTROL
   --                          WHERE     RC_INV_CONTROL_ID = 10
   --                                AND RC_INV_CONTROL_ACTIVE = 'Y') --250 -- Same
   --                     WHEN MSR.YTD_AVG_SALES_PRICE BETWEEN 751 AND 5000
   --                     THEN
   --                        (SELECT RC_INV_CONTROL_VALUE
   --                           FROM RC_INV_CONTROL
   --                          WHERE     RC_INV_CONTROL_ID = 11
   --                                AND RC_INV_CONTROL_ACTIVE = 'Y') --50 -- Old Value: 10
   --                     WHEN MSR.YTD_AVG_SALES_PRICE BETWEEN 5001 AND 10000
   --                     THEN
   --                        (SELECT RC_INV_CONTROL_VALUE
   --                           FROM RC_INV_CONTROL
   --                          WHERE     RC_INV_CONTROL_ID = 12
   --                                AND RC_INV_CONTROL_ACTIVE = 'Y') --25 -- Old Value: 5
   --                     WHEN MSR.YTD_AVG_SALES_PRICE BETWEEN 10001 AND 25000
   --                     THEN
   --                        (SELECT RC_INV_CONTROL_VALUE
   --                           FROM RC_INV_CONTROL
   --                          WHERE     RC_INV_CONTROL_ID = 13
   --                                AND RC_INV_CONTROL_ACTIVE = 'Y') --10 -- Old Value: 3
   --                     WHEN MSR.YTD_AVG_SALES_PRICE > 25000
   --                     THEN
   --                        (SELECT RC_INV_CONTROL_VALUE
   --                           FROM RC_INV_CONTROL
   --                          WHERE     RC_INV_CONTROL_ID = 14
   --                                AND RC_INV_CONTROL_ACTIVE = 'Y') --5 -- Old Value: 1
   --                     WHEN YTD_AVG_SALES_PRICE IS NULL
   --                     THEN
   --                        (SELECT RC_INV_CONTROL_VALUE
   --                           FROM RC_INV_CONTROL
   --                          WHERE     RC_INV_CONTROL_ID = 15
   --                                AND RC_INV_CONTROL_ACTIVE = 'Y') --10 -- Old 0
   --                  END
   --                     OUTLET_CAP,
   --                  /* AVG SALES PRICE Control as part of August Sprint */
   --                  NVL (MSR.YTD_AVG_SALES_PRICE, 0) YTD_AVG_SALES_PRICE,
   --                  (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
   --                             AVAILABLE_TO_RESERVE_FGI
   --                     FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
   --                    WHERE     IM.INVENTORY_FLOW = 'Retail'
   --                          AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
   --                          AND IM.SITE_CODE IN ('LRO', 'FVE')
   --                          AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
   --                     CCW_FG_R_TOTAL,
   --                  (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
   --                             AVAILABLE_TO_RESERVE_FGI
   --                     FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
   --                    WHERE     IM.INVENTORY_FLOW = 'Retail'
   --                          AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
   --                          AND IM.SITE_CODE IN ('FVE')
   --                          AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
   --                     CCW_FG_R_FVE_ROHS,
   --                  (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
   --                             AVAILABLE_TO_RESERVE_FGI
   --                     FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
   --                    WHERE     IM.INVENTORY_FLOW = 'Retail'
   --                          AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
   --                          AND IM.SITE_CODE IN ('LRO')
   --                          AND IM.ROHS_COMPLIANT = 'YES'
   --                          AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
   --                     CCW_FG_R_LRO_ROHS,
   --                  (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
   --                             AVAILABLE_TO_RESERVE_FGI
   --                     FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
   --                    WHERE     IM.INVENTORY_FLOW = 'Retail'
   --                          AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
   --                          AND IM.SITE_CODE IN ('LRO')
   --                          AND IM.ROHS_COMPLIANT = 'NO'
   --                          AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
   --                     CCW_FG_R_LRO_NROHS,
   --                  (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
   --                             AVAILABLE_TO_RESERVE_FGI
   --                     FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
   --                    WHERE     1 = 1
   --                          AND IM.INVENTORY_FLOW = 'Outlet'
   --                          AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
   --                          AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
   --                     CCW_FG_O_TOTAL,
   --                  (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
   --                             AVAILABLE_TO_RESERVE_FGI
   --                     FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
   --                    WHERE     IM.INVENTORY_FLOW = 'Outlet'
   --                          AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
   --                          AND IM.SITE_CODE IN ('FVE')
   --                          AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
   --                     CCW_FG_O_FVE_ROHS,
   --                  (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
   --                             AVAILABLE_TO_RESERVE_FGI
   --                     FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
   --                    WHERE     IM.INVENTORY_FLOW = 'Outlet'
   --                          AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
   --                          AND IM.SITE_CODE IN ('LRO')
   --                          AND IM.ROHS_COMPLIANT = 'YES'
   --                          AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
   --                     CCW_FG_O_LRO_ROHS,
   --                  (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
   --                             AVAILABLE_TO_RESERVE_FGI
   --                     FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
   --                    WHERE     IM.INVENTORY_FLOW = 'Outlet'
   --                          AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
   --                          AND IM.SITE_CODE IN ('LRO')
   --                          AND IM.ROHS_COMPLIANT = 'NO'
   --                          AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
   --                     CCW_FG_O_LRO_NROHS,
   --                  (SELECT NVL (SUM (IM.RESERVED_DGI), 0)
   --                     FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
   --                    WHERE     PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
   --                          AND IM.INVENTORY_FLOW = 'Retail'
   --                          AND IM.RESERVED_DGI > 0)
   --                     RESERVED_DGI,
   --                  (SELECT NVL (SUM (DELTA_FGI_R_LRO_TOTAL.DELTA_FGI), 0)
   --                     FROM RMKTGADM.RC_INV_FGI_DELTA DELTA_FGI_R_LRO_TOTAL
   --                    WHERE     DELTA_FGI_R_LRO_TOTAL.PRODUCT_ID = IM.PART_NUMBER
   --                          AND DELTA_FGI_R_LRO_TOTAL.PRODUCT_TYPE = 'R' --AND TRUNC (DELTA_FGI_R_LRO_TOTAL.UPDATED_ON) = '12-OCT-16'
   --                                                                      )
   --                     DELTA_FG_R_TOTAL,
   --                  (SELECT NVL (SUM (DELTA_FGI_R_FVE_ROHS.DELTA_FGI), 0)
   --                     FROM RMKTGADM.RC_INV_FGI_DELTA DELTA_FGI_R_FVE_ROHS
   --                    WHERE     DELTA_FGI_R_FVE_ROHS.PRODUCT_ID = IM.PART_NUMBER
   --                          AND DELTA_FGI_R_FVE_ROHS.SITE_SHORTNAME = 'FVE'
   --                          AND DELTA_FGI_R_FVE_ROHS.PRODUCT_TYPE = 'R')
   --                     DELTA_FG_R_FVE_ROHS,
   --                  (SELECT NVL (SUM (DELTA_FGI_R_LRO_ROHS.DELTA_FGI), 0)
   --                     FROM RMKTGADM.RC_INV_FGI_DELTA DELTA_FGI_R_LRO_ROHS
   --                    WHERE     DELTA_FGI_R_LRO_ROHS.PRODUCT_ID = IM.PART_NUMBER
   --                          AND DELTA_FGI_R_LRO_ROHS.SITE_SHORTNAME = 'LRO'
   --                          AND DELTA_FGI_R_LRO_ROHS.PRODUCT_TYPE = 'R'
   --                          AND UPPER (DELTA_FGI_R_LRO_ROHS.IS_ROHS) = 'YES' --AND DELTA_FGI_R_LRO_ROHS.POE_BATCH_ID LIKE '%ROHS'   -- >> NQ
   --                                                                          --AND TRUNC (DELTA_FGI_R_LRO_ROHS.UPDATED_ON) = '12-OCT-16' -->> NQ
   --                  )
   --                     DELTA_FG_R_LRO_ROHS,
   --                  (SELECT NVL (SUM (DELTA_FG_R_LRO_NROHS.DELTA_FGI), 0)
   --                     FROM RMKTGADM.RC_INV_FGI_DELTA DELTA_FG_R_LRO_NROHS
   --                    WHERE     DELTA_FG_R_LRO_NROHS.PRODUCT_ID = IM.PART_NUMBER
   --                          AND DELTA_FG_R_LRO_NROHS.SITE_SHORTNAME = 'LRO'
   --                          AND DELTA_FG_R_LRO_NROHS.PRODUCT_TYPE = 'R'
   --                          AND UPPER (DELTA_FG_R_LRO_NROHS.IS_ROHS) = 'NO' --AND DELTA_FG_R_LRO_NROHS.POE_BATCH_ID LIKE '%ROHS'   -- >> NQ
   --                                                                         --AND TRUNC (DELTA_FG_R_LRO_NROHS.UPDATED_ON) = '12-OCT-16' -->> NQ
   --                  )
   --                     DELTA_FG_R_LRO_NROHS
   --             FROM CRPADM.RC_PRODUCT_MASTER PM       -- RF part number is setup
   --                  -- Inventory Master
   --                  INNER JOIN RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
   --                     ON (    PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
   --                         AND IM.SITE_CODE IN ('LRO', 'FVE'))
   --                  -- Average Sales Price
   --                  LEFT OUTER JOIN
   --                  (  SELECT RSH.REFRESH_INVENTORY_ITEM_ID,
   --                            ROUND (MAX (RSH.YTD_AVG_SALES_PRICE), 0)
   --                               YTD_AVG_SALES_PRICE
   --                       FROM CRPSC.RC_R12_SHIPMENT_HISTORY RSH
   --                   GROUP BY RSH.REFRESH_INVENTORY_ITEM_ID) MSR
   --                     ON (PM.REFRESH_INVENTORY_ITEM_ID =
   --                            MSR.REFRESH_INVENTORY_ITEM_ID)
   --                  -- MOS
   --                  LEFT OUTER JOIN
   --                  --                  (SELECT DISTINCT MAP.REFRESH_INVENTORY_ITEM_ID, MOS.MOS
   --                  --                     FROM VAVNI_CISCO_RSCM_BP.VV_BP_MON_ROLLING_SHIP_DATA_VW MOS
   --                  --                          INNER JOIN CRPADM.RC_PRODUCT_MAPID_MAPPING MAP
   --                  --                             ON (MAP.PRODUCT_MAP_ID = MOS.PRODUCT_ID)) MOS
   --                  --                     ON (MOS.REFRESH_INVENTORY_ITEM_ID =
   --                  --                            PM.REFRESH_INVENTORY_ITEM_ID)
   --                  (  SELECT DISTINCT
   --                            REFRESH_INVENTORY_ITEM_ID, NVL (SUM (MOS), 0) MOS
   --                       FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
   --                      WHERE PROGRAM_TYPE = 'RETAIL'
   --                   GROUP BY REFRESH_INVENTORY_ITEM_ID) MOS
   --                     ON (MOS.REFRESH_INVENTORY_ITEM_ID =
   --                            PM.REFRESH_INVENTORY_ITEM_ID)
   --                  -- Current Max
   --                  --                  LEFT OUTER JOIN
   --                  --                  (  SELECT RGCM.REFRESH_INVENTORY_ITEM_ID,
   --                  --                            SUM (RGCM.CURRENT_MAX) RF_GLOBAL_CUR_MAX
   --                  --                       FROM CRPSC.RC_GBP_CURRENT_MAX_PRIORITY RGCM
   --                  --                   GROUP BY RGCM.REFRESH_INVENTORY_ITEM_ID) CM
   --                  --                     ON (PM.REFRESH_INVENTORY_ITEM_ID =
   --                  --                            CM.REFRESH_INVENTORY_ITEM_ID)  -- commented as part of August Sprint
   --                  LEFT OUTER JOIN RMKTGADM.RC_INV_DGI_DELTA SD
   --                     ON (    SD.PRODUCT_ID = IM.PART_NUMBER
   --                         AND SD.SITE_SHORTNAME = IM.SITE_CODE
   --                         AND SD.IS_ROHS = IM.ROHS_COMPLIANT)
   --            WHERE     1 = 1
   --                  AND PM.PROGRAM_TYPE =
   --                         (SELECT RIC.RC_INV_CONTROL_VALUE
   --                            FROM RMKTGADM.RC_INV_CONTROL RIC
   --                           WHERE     RC_INV_CONTROL_ID = 8 --   RIC.RC_INV_CONTROL_NAME = 'RETAIL' --commented as part of sprint14(Aug Release)and added RC_INV_CONTROL_ID
   --                                 AND RIC.RC_INV_CONTROL_FLAG = 'Y')
   --                  AND NVL (MOS.MOS, 0) NOT BETWEEN (SELECT RIC_SUB.RC_INV_CONTROL_VALUE
   --                                                      FROM RMKTGADM.RC_INV_CONTROL
   --                                                           RIC_SUB
   --                                                     WHERE     RIC_SUB.RC_INV_CONTROL_ID =
   --                                                                  6 --RC_INV_CONTROL_NAME ='MIN MOS'  --commented as part of sprint14(Aug Release)and added RC_INV_CONTROL_ID
   --                                                           AND RIC_SUB.RC_INV_CONTROL_FLAG =
   --                                                                  'Y')
   --                                               AND (SELECT RIC_SUB1.RC_INV_CONTROL_VALUE
   --                                                      FROM RMKTGADM.RC_INV_CONTROL
   --                                                           RIC_SUB1
   --                                                     WHERE     RIC_SUB1.RC_INV_CONTROL_ID =
   --                                                                  7 --RC_INV_CONTROL_NAME ='MIN MOS'  --commented as part of sprint14(Aug Release)and added RC_INV_CONTROL_ID
   --                                                           AND RIC_SUB1.RC_INV_CONTROL_FLAG =
   --                                                                  'Y') -- -- Include PID?s that have over 6 months? supply of (Inclusive of) FGI and DGI
   --                  AND TRUNC (PM.NPI_CREATION_DATE) <
   --                           TRUNC (SYSDATE)
   --                         - (SELECT RIC_NPI.RC_INV_CONTROL_VALUE
   --                              FROM RMKTGADM.RC_INV_CONTROL RIC_NPI
   --                             WHERE     RIC_NPI.RC_INV_CONTROL_ID = 5 ---RC_INV_CONTROL_NAME = 'PRODUCT AGE'  --commented as part of sprint14(Aug Release)and added RC_INV_CONTROL_ID
   --                                   AND RIC_NPI.RC_INV_CONTROL_FLAG = 'Y') -- Exclude PID?s setup for RF in prior 3 months
   --                  AND NVL (TRUNC (PM.MFG_EOS_DATE), SYSDATE + 1) >
   --                         TRUNC (SYSDATE)     -- Added as part of August Sprint
   --         ORDER BY 2;
   --
   --      BASE                 REG_OUT%ROWTYPE;
   --   BEGIN
   --      L_START_TIME := SYSDATE;
   --
   --      DELETE FROM RMKTGADM.RC_INV_OUTLET_SPLIT;
   --
   --      DELETE FROM RMKTGADM.RC_INV_DELTA_SPLIT_LOG;
   --
   --      COMMIT;
   --
   --      OPEN REG_OUT;
   --
   --      LOOP
   --         FETCH REG_OUT INTO BASE;
   --
   --         EXIT WHEN REG_OUT%NOTFOUND;
   --
   --
   --         V_OUTLET_CAP :=
   --            LEAST (FLOOR ( (BASE.DELTA_FG_R_TOTAL * 50) / 100),
   --                   BASE.OUTLET_CAP); -- To Calculate min of 50% of Retail FG and Outlet cap for all buckets
   --
   --         V_REQUIRED_OUTLET :=
   --            NVL (V_OUTLET_CAP, 0) - NVL (BASE.CCW_FG_O_TOTAL, 0);
   --
   --         V_REQUIRED_RETAIL := BASE.RESERVED_DGI; -- >> Added to consider DGI Reservations
   --
   --         IF V_REQUIRED_RETAIL > 0
   --         THEN
   --            IF BASE.DELTA_FG_R_TOTAL >= V_REQUIRED_RETAIL
   --            THEN
   --               IF BASE.CCW_FG_O_TOTAL >= V_OUTLET_CAP
   --               THEN
   --                  V_OUTLET_ALLOC_QTY := 0;
   --               ELSE
   --                  IF (BASE.DELTA_FG_R_TOTAL - V_REQUIRED_RETAIL) >=
   --                        V_REQUIRED_OUTLET
   --                  THEN
   --                     V_OUTLET_ALLOC_QTY := V_REQUIRED_OUTLET;
   --                  ELSE
   --                     V_OUTLET_ALLOC_QTY :=
   --                        BASE.DELTA_FG_R_TOTAL - V_REQUIRED_RETAIL;
   --                  END IF;
   --               END IF;
   --            ELSE
   --               V_OUTLET_ALLOC_QTY := 0;
   --            END IF;
   --         ELSIF V_REQUIRED_RETAIL = 0
   --         THEN
   --            IF BASE.CCW_FG_O_TOTAL >= V_OUTLET_CAP
   --            THEN
   --               V_OUTLET_ALLOC_QTY := 0;
   --            ELSE
   --               IF BASE.DELTA_FG_R_TOTAL >= V_REQUIRED_OUTLET
   --               THEN
   --                  V_OUTLET_ALLOC_QTY := V_REQUIRED_OUTLET;
   --               ELSE
   --                  V_OUTLET_ALLOC_QTY := BASE.DELTA_FG_R_TOTAL;
   --               END IF;
   --            END IF;
   --         END IF;
   --
   --         V_RETAIL_ALLOC_QTY := BASE.DELTA_FG_R_TOTAL - V_OUTLET_ALLOC_QTY;
   --
   --         IF     BASE.DELTA_FG_R_LRO_ROHS > 0
   --            AND BASE.DELTA_FG_R_LRO_ROHS >= V_OUTLET_ALLOC_QTY
   --         THEN
   --            V_LRO_ROHS_OUTLET := V_OUTLET_ALLOC_QTY;
   --            V_LRO_NROHS_OUTLET := 0;
   --            V_FVE_ROHS_OUTLET := 0;
   --         ELSE
   --            V_LRO_ROHS_OUTLET := BASE.DELTA_FG_R_LRO_ROHS;
   --
   --            IF BASE.DELTA_FG_R_LRO_NROHS >=
   --                  (V_OUTLET_ALLOC_QTY - V_LRO_ROHS_OUTLET)
   --            THEN
   --               V_LRO_NROHS_OUTLET := V_OUTLET_ALLOC_QTY - V_LRO_ROHS_OUTLET;
   --               V_FVE_ROHS_OUTLET := 0;
   --            ELSE
   --               V_LRO_NROHS_OUTLET := BASE.DELTA_FG_R_LRO_NROHS;
   --
   --               IF BASE.DELTA_FG_R_FVE_ROHS >=
   --                     (  V_OUTLET_ALLOC_QTY
   --                      - V_LRO_ROHS_OUTLET
   --                      - V_LRO_NROHS_OUTLET)
   --               THEN
   --                  V_FVE_ROHS_OUTLET :=
   --                       V_OUTLET_ALLOC_QTY
   --                     - V_LRO_ROHS_OUTLET
   --                     - V_LRO_NROHS_OUTLET;
   --               ELSE
   --                  V_FVE_ROHS_OUTLET := BASE.DELTA_FG_R_FVE_ROHS;
   --               END IF;
   --            END IF;
   --         END IF;
   --
   --         V_LRO_ROHS_RETAIL := BASE.DELTA_FG_R_LRO_ROHS - V_LRO_ROHS_OUTLET;
   --
   --         V_LRO_NROHS_RETAIL := BASE.DELTA_FG_R_LRO_NROHS - V_LRO_NROHS_OUTLET;
   --
   --         V_FVE_ROHS_RETAIL := BASE.DELTA_FG_R_FVE_ROHS - V_FVE_ROHS_OUTLET;
   --
   --
   --         -->> insert for outlet split
   --         INSERT INTO RMKTGADM.RC_INV_OUTLET_SPLIT (RECORD_CREATED_DATE,
   --                                                   REFRESH_PART_NUMBER,
   --                                                   NPI_CREATION_DATE,
   --                                                   MOS,
   --                                                   --                                                   RETAIL_MAX,
   --                                                   OUTLET_CAP,
   --                                                   YTD_AVG_SALES_PRICE,
   --                                                   CCW_FG_R_TOTAL,
   --                                                   CCW_FG_R_FVE_ROHS,
   --                                                   CCW_FG_R_LRO_ROHS,
   --                                                   CCW_FG_R_LRO_NROHS,
   --                                                   CCW_FG_O_TOTAL,
   --                                                   CCW_FG_O_FVE_ROHS,
   --                                                   CCW_FG_O_LRO_ROHS,
   --                                                   CCW_FG_O_LRO_NROHS,
   --                                                   --                                                   CCW_R_DGI,
   --                                                   --                                                   DELTA_R_DGI,
   --                                                   DELTA_FG_R_TOTAL,
   --                                                   DELTA_FG_R_FVE_ROHS,
   --                                                   DELTA_FG_R_LRO_ROHS,
   --                                                   DELTA_FG_R_LRO_NROHS,
   --                                                   TOTAL_OUTLET,
   --                                                   OUTLET_LRO_ROHS_SPLIT,
   --                                                   OUTLET_LRO_NROHS_SPLIT,
   --                                                   OUTLET_FVE_SPLIT,
   --                                                   TOTAL_RETAIL,
   --                                                   RETAIL_LRO_ROHS_SPLIT,
   --                                                   RETAIL_LRO_NROHS_SPLIT,
   --                                                   RETAIL_FVE_SPLIT,
   --                                                   OUTLET_CAP_50_PCT,
   --                                                   RESERVED_DGI)
   --              --                                                   RETAIL_MAX_PLUS_DGI_RES)
   --              VALUES (BASE.RECORD_CREATED_DATE,
   --                      BASE.REFRESH_PART_NUMBER,
   --                      BASE.NPI_CREATION_DATE,
   --                      BASE.MOS,
   --                      --                      BASE.RETAIL_MAX,
   --                      BASE.OUTLET_CAP,
   --                      BASE.YTD_AVG_SALES_PRICE,
   --                      BASE.CCW_FG_R_TOTAL,
   --                      BASE.CCW_FG_R_FVE_ROHS,
   --                      BASE.CCW_FG_R_LRO_ROHS,
   --                      BASE.CCW_FG_R_LRO_NROHS,
   --                      BASE.CCW_FG_O_TOTAL,
   --                      BASE.CCW_FG_O_FVE_ROHS,
   --                      BASE.CCW_FG_O_LRO_ROHS,
   --                      BASE.CCW_FG_O_LRO_NROHS,
   --                      --                      BASE.CCW_R_DGI,
   --                      --                      BASE.DELTA_R_DGI,
   --                      BASE.DELTA_FG_R_TOTAL,
   --                      BASE.DELTA_FG_R_FVE_ROHS,
   --                      BASE.DELTA_FG_R_LRO_ROHS,
   --                      BASE.DELTA_FG_R_LRO_NROHS,
   --                      V_OUTLET_ALLOC_QTY,
   --                      V_LRO_ROHS_OUTLET,
   --                      V_LRO_NROHS_OUTLET,
   --                      V_FVE_ROHS_OUTLET,
   --                      V_RETAIL_ALLOC_QTY,
   --                      V_LRO_ROHS_RETAIL,
   --                      V_LRO_NROHS_RETAIL,
   --                      V_FVE_ROHS_RETAIL,
   --                      V_OUTLET_CAP,
   --                      BASE.RESERVED_DGI);
   --
   --         --                      V_RETAIL_MAX_PLUS_DGI_RES);
   --
   --         -->> insert for retail LRO Rohs
   --         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
   --                                                      PART_NUMBER,
   --                                                      NEW_FGI,
   --                                                      ROHS_COMPLIANT,
   --                                                      SITE_CODE,
   --                                                      PROCESS_STATUS,
   --                                                      --                                                 AVAILABLE_TO_RESERVE_FGI,
   --                                                      --                                                 GLOBAL_CUR_MAX,
   --                                                      UPDATED_ON,
   --                                                      UPDATED_BY,
   --                                                      CREATED_ON,
   --                                                      CREATED_BY,
   --                                                      --POE_BATCH_ID,
   --                                                      PRODUCT_TYPE)
   --              --SOURCE_SYSTEM)
   --              VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL, -- added on 07/25/2016
   --                      BASE.REFRESH_PART_NUMBER,
   --                      V_LRO_ROHS_RETAIL,
   --                      'YES',
   --                      'LRO',
   --                      'N',
   --                      --                 BASE.CCW_FG_R_TOTAL,
   --                      --                 BASE.RETAIL_MAX,
   --                      SYSDATE,
   --                      'RC_INV_OUTLET_BTS_SPLIT',
   --                      SYSDATE,
   --                      'RC_INV_OUTLET_BTS_SPLIT',
   --                      --BASE.POE_BATCH_ID,
   --                      'R');
   --
   --         --BASE.SOURCE_SYSTEM);
   --
   --         -->> insert for retail LRO Non-Rohs
   --         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
   --                                                      PART_NUMBER,
   --                                                      NEW_FGI,
   --                                                      ROHS_COMPLIANT,
   --                                                      SITE_CODE,
   --                                                      PROCESS_STATUS,
   --                                                      --                                                 AVAILABLE_TO_RESERVE_FGI,
   --                                                      --                                                 GLOBAL_CUR_MAX,
   --                                                      UPDATED_ON,
   --                                                      UPDATED_BY,
   --                                                      CREATED_ON,
   --                                                      CREATED_BY,
   --                                                      --POE_BATCH_ID,
   --                                                      PRODUCT_TYPE)
   --              --SOURCE_SYSTEM)
   --              VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL, -- added on 07/25/2016
   --                      BASE.REFRESH_PART_NUMBER,
   --                      V_LRO_NROHS_RETAIL,
   --                      'NO',
   --                      'LRO',
   --                      'N',
   --                      --                 BASE.CCW_FG_R_TOTAL,
   --                      --                 BASE.RETAIL_MAX,
   --                      SYSDATE,
   --                      'RC_INV_OUTLET_BTS_SPLIT',
   --                      SYSDATE,
   --                      'RC_INV_OUTLET_BTS_SPLIT',
   --                      --BASE.POE_BATCH_ID,
   --                      'R');
   --
   --         --BASE.SOURCE_SYSTEM);
   --
   --         -->> insert for retail FVE Rohs
   --         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
   --                                                      PART_NUMBER,
   --                                                      NEW_FGI,
   --                                                      ROHS_COMPLIANT,
   --                                                      SITE_CODE,
   --                                                      PROCESS_STATUS,
   --                                                      --                                                 AVAILABLE_TO_RESERVE_FGI,
   --                                                      --                                                 GLOBAL_CUR_MAX,
   --                                                      UPDATED_ON,
   --                                                      UPDATED_BY,
   --                                                      CREATED_ON,
   --                                                      CREATED_BY,
   --                                                      --POE_BATCH_ID,
   --                                                      PRODUCT_TYPE)
   --              --SOURCE_SYSTEM)
   --              VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL, -- added on 07/25/2016
   --                      BASE.REFRESH_PART_NUMBER,
   --                      V_FVE_ROHS_RETAIL,
   --                      'YES',
   --                      'FVE',
   --                      'N',
   --                      --                 BASE.CCW_FG_R_TOTAL,
   --                      --                 BASE.RETAIL_MAX,
   --                      SYSDATE,
   --                      'RC_INV_OUTLET_BTS_SPLIT',
   --                      SYSDATE,
   --                      'RC_INV_OUTLET_BTS_SPLIT',
   --                      --BASE.POE_BATCH_ID,
   --                      'R');
   --
   --         --BASE.SOURCE_SYSTEM);
   --
   --
   --         -->> insert for Outlet LRO Rohs
   --         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
   --                                                      PART_NUMBER,
   --                                                      NEW_FGI,
   --                                                      ROHS_COMPLIANT,
   --                                                      SITE_CODE,
   --                                                      PROCESS_STATUS,
   --                                                      --                                                 AVAILABLE_TO_RESERVE_FGI,
   --                                                      --                                                 GLOBAL_CUR_MAX,
   --                                                      UPDATED_ON,
   --                                                      UPDATED_BY,
   --                                                      CREATED_ON,
   --                                                      CREATED_BY,
   --                                                      --POE_BATCH_ID,
   --                                                      PRODUCT_TYPE)
   --              --SOURCE_SYSTEM)
   --              VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL, -- added on 07/25/2016
   --                      BASE.REFRESH_PART_NUMBER,
   --                      V_LRO_ROHS_OUTLET,
   --                      'YES',
   --                      'LRO',
   --                      'N',
   --                      --                 BASE.CCW_FG_R_TOTAL,
   --                      --                 BASE.RETAIL_MAX,
   --                      SYSDATE,
   --                      'RC_INV_OUTLET_BTS_SPLIT',
   --                      SYSDATE,
   --                      'RC_INV_OUTLET_BTS_SPLIT',
   --                      --BASE.POE_BATCH_ID,
   --                      'O');
   --
   --         --BASE.SOURCE_SYSTEM);
   --
   --         -->> insert for Outlet LRO Non-Rohs
   --         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
   --                                                      PART_NUMBER,
   --                                                      NEW_FGI,
   --                                                      ROHS_COMPLIANT,
   --                                                      SITE_CODE,
   --                                                      PROCESS_STATUS,
   --                                                      --                                                 AVAILABLE_TO_RESERVE_FGI,
   --                                                      --                                                 GLOBAL_CUR_MAX,
   --                                                      UPDATED_ON,
   --                                                      UPDATED_BY,
   --                                                      CREATED_ON,
   --                                                      CREATED_BY,
   --                                                      --POE_BATCH_ID,
   --                                                      PRODUCT_TYPE)
   --              --SOURCE_SYSTEM)
   --              VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL, -- added on 07/25/2016
   --                      BASE.REFRESH_PART_NUMBER,
   --                      V_LRO_NROHS_OUTLET,
   --                      'NO',
   --                      'LRO',
   --                      'N',
   --                      --                 BASE.CCW_FG_R_TOTAL,
   --                      --                 BASE.RETAIL_MAX,
   --                      SYSDATE,
   --                      'RC_INV_OUTLET_BTS_SPLIT',
   --                      SYSDATE,
   --                      'RC_INV_OUTLET_BTS_SPLIT',
   --                      --BASE.POE_BATCH_ID,
   --                      'O');
   --
   --         --BASE.SOURCE_SYSTEM);
   --
   --         -->> insert for Outlet FVE Rohs
   --         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
   --                                                      PART_NUMBER,
   --                                                      NEW_FGI,
   --                                                      ROHS_COMPLIANT,
   --                                                      SITE_CODE,
   --                                                      PROCESS_STATUS,
   --                                                      --                                                 AVAILABLE_TO_RESERVE_FGI,
   --                                                      --                                                 GLOBAL_CUR_MAX,
   --                                                      UPDATED_ON,
   --                                                      UPDATED_BY,
   --                                                      CREATED_ON,
   --                                                      CREATED_BY,
   --                                                      --POE_BATCH_ID,
   --                                                      PRODUCT_TYPE)
   --              --SOURCE_SYSTEM)
   --              VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL, -- added on 07/25/2016
   --                      BASE.REFRESH_PART_NUMBER,
   --                      V_FVE_ROHS_OUTLET,
   --                      'YES',
   --                      'FVE',
   --                      'N',
   --                      --                 BASE.CCW_FG_R_TOTAL,
   --                      --                 BASE.RETAIL_MAX,
   --                      SYSDATE,
   --                      'RC_INV_OUTLET_BTS_SPLIT',
   --                      SYSDATE,
   --                      'RC_INV_OUTLET_BTS_SPLIT',
   --                      --BASE.POE_BATCH_ID,
   --                      'O');
   --      --BASE.SOURCE_SYSTEM);
   --      END LOOP;
   --
   --      COMMIT;
   --
   --      --- >> If PIDs are not in Outlet List, to be sent as Retail:
   --
   --      INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
   --                                                   PART_NUMBER,
   --                                                   NEW_FGI,
   --                                                   ROHS_COMPLIANT,
   --                                                   SITE_CODE,
   --                                                   PROCESS_STATUS,
   --                                                   --                                                   AVAILABLE_TO_RESERVE_FGI,
   --                                                   --                                                   GLOBAL_CUR_MAX,
   --                                                   UPDATED_ON,
   --                                                   UPDATED_BY,
   --                                                   CREATED_ON,
   --                                                   CREATED_BY,
   --                                                   -- POE_BATCH_ID,
   --                                                   PRODUCT_TYPE)
   --         --SOURCE_SYSTEM)
   --         SELECT RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
   --                PRODUCT_ID,
   --                DELTA_FGI,
   --                IS_ROHS,
   --                SITE_SHORTNAME,
   --                'N' AS PROCESS_STATUS,
   --                --                0 AVAILABLE_TO_RESERVE_FGI,
   --                --                0 GLOBAL_CUR_MAX,
   --                UPDATED_ON,
   --                UPDATED_BY,
   --                CREATED_ON,
   --                CREATED_BY,
   --                PRODUCT_TYPE
   --           FROM RMKTGADM.RC_INV_FGI_DELTA
   --          WHERE     PRODUCT_ID NOT IN (SELECT REFRESH_PART_NUMBER
   --                                         FROM RMKTGADM.RC_INV_OUTLET_SPLIT)
   --                --                   FROM RMKTGADM.RC_INV_OUTLET_BASE)
   --                AND PRODUCT_TYPE = 'R';
   --
   --
   --      -->> Added New Condition to delete records for New FGI = 0
   --      DELETE FROM RMKTGADM.RC_INV_DELTA_SPLIT_LOG
   --            WHERE NEW_FGI = 0;
   --
   --      -->>
   --
   --      -->> Hist table for RC_INV_OUTLET_SPLIT table
   --      INSERT INTO RMKTGADM.RC_INV_OUTLET_SPLIT_HIST
   --         SELECT * FROM RMKTGADM.RC_INV_OUTLET_SPLIT;
   --
   --      -->>
   --      COMMIT;
   --
   --
   --      INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
   --                                             CHL_STATUS,
   --                                             CHL_START_TIMESTAMP,
   --                                             CHL_END_TIMESTAMP,
   --                                             CHL_CRON_NAME,
   --                                             CHL_COMMENTS,
   --                                             CHL_CREATED_BY)
   --           VALUES (SEQ_CHL_ID.NEXTVAL,
   --                   'SUCCESS',
   --                   L_START_TIME,
   --                   SYSDATE,
   --                   'RC_INV_OUTLET_BTS_SPLIT',
   --                   NULL,
   --                   'RC_INV_DELTA_LOAD_RF');
   --
   --      G_PROC_NAME := 'RC_INV_OUTLET_BTS_SPLIT';
   --      COMMIT;
   --   EXCEPTION
   --      WHEN OTHERS
   --      THEN
   --         ROLLBACK;
   --         G_ERROR_MSG :=
   --               SUBSTR (SQLERRM, 1, 200)
   --            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
   --
   --         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
   --                                                CHL_STATUS,
   --                                                CHL_START_TIMESTAMP,
   --                                                CHL_END_TIMESTAMP,
   --                                                CHL_CRON_NAME,
   --                                                CHL_COMMENTS,
   --                                                CHL_CREATED_BY)
   --              VALUES (SEQ_CHL_ID.NEXTVAL,
   --                      'FAILED',
   --                      G_START_TIME,
   --                      SYSDATE,
   --                      G_PROC_NAME,
   --                      G_ERROR_MSG,
   --                      'RC_INV_DELTA_LOAD_RF');
   --
   --         G_PROC_NAME := 'RC_INV_OUTLET_BTS_SPLIT';
   --
   --         COMMIT;
   --
   --         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   --   END RC_INV_OUTLET_BTS_SPLIT;

   /* End Commented as part of Selling FGI only requirement for Oct 27 Release on 15-OCT-2018 */

   /* Start Added as part of Selling FGI only requirement for Oct 27 Release on 15-OCT-2018 */

   PROCEDURE RC_INV_OUTLET_FORWARD_ALLOC
   --->> Forward Outlet Allocation
   AS
      V_LRO_ROHS_OUTLET    NUMBER;
      V_LRO_NROHS_OUTLET   NUMBER;
      V_FVE_ROHS_OUTLET    NUMBER;
      V_LRO_ROHS_RETAIL    NUMBER;
      V_LRO_NROHS_RETAIL   NUMBER;
      V_FVE_ROHS_RETAIL    NUMBER;
      L_START_TIME         DATE;
      V_TOTAL_RETAIL       NUMBER;
      V_TOTAL_OUTLET       NUMBER;

      CURSOR REG_OUT
      IS
         SELECT DISTINCT
                SYSDATE AS RECORD_CREATED_DATE,
                PM.REFRESH_PART_NUMBER,
                (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
                           AVAILABLE_TO_RESERVE_FGI
                   FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
                  WHERE     IM.INVENTORY_FLOW = 'Retail'
                        AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
                        AND IM.SITE_CODE IN ('LRO', 'FVE')
                        AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
                   CCW_FG_R_TOTAL,
                (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
                           AVAILABLE_TO_RESERVE_FGI
                   FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
                  WHERE     IM.INVENTORY_FLOW = 'Retail'
                        AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
                        AND IM.SITE_CODE IN ('FVE')
                        AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
                   CCW_FG_R_FVE_ROHS,
                (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
                           AVAILABLE_TO_RESERVE_FGI
                   FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
                  WHERE     IM.INVENTORY_FLOW = 'Retail'
                        AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
                        AND IM.SITE_CODE IN ('LRO')
                        AND IM.ROHS_COMPLIANT = 'YES'
                        AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
                   CCW_FG_R_LRO_ROHS,
                (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
                           AVAILABLE_TO_RESERVE_FGI
                   FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
                  WHERE     IM.INVENTORY_FLOW = 'Retail'
                        AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
                        AND IM.SITE_CODE IN ('LRO')
                        AND IM.ROHS_COMPLIANT = 'NO'
                        AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
                   CCW_FG_R_LRO_NROHS,
                FGI.OUTLET_ALLOC_QUANTITY
           FROM CRPADM.RC_PRODUCT_MASTER PM         -- RF part number is setup
                -- Inventory Master
                INNER JOIN RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
                   ON (    PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
                       AND IM.SITE_CODE IN ('LRO', 'FVE'))
                INNER JOIN CRPSC.RC_AE_FGI_REQUIREMENT FGI
                   ON (PM.REFRESH_PART_NUMBER = FGI.REFRESH_PART_NUMBER)
          WHERE     1 = 1
                AND PM.REFRESH_PART_NUMBER LIKE '%RF'
                AND NVL (FGI.OUTLET_ALLOC_QUANTITY, 0) <> 0;

      BASE                 REG_OUT%ROWTYPE;
   BEGIN
      L_START_TIME := SYSDATE;

      DELETE FROM RMKTGADM.RC_INV_OUTLET_FWD_ALLOCATION;

      DELETE FROM RMKTGADM.RC_INV_DELTA_SPLIT_LOG;

      COMMIT;

      OPEN REG_OUT;

      LOOP
         FETCH REG_OUT INTO BASE;

         EXIT WHEN REG_OUT%NOTFOUND;

         --            IF BASE.OUTLET_ALLOC_QUANTITY > BASE.CCW_FG_R_TOTAL THEN
         --
         --              V_TOTAL_OUTLET:= NVL(BASE.CCW_FG_R_TOTAL,0);
         --
         --           ELSIF BASE.OUTLET_ALLOC_QUANTITY <= BASE.CCW_FG_R_TOTAL THEN
         --
         --              V_TOTAL_OUTLET:= BASE.OUTLET_ALLOC_QUANTITY;
         --
         --           END IF;

         V_TOTAL_OUTLET := BASE.OUTLET_ALLOC_QUANTITY;

         IF     BASE.CCW_FG_R_LRO_ROHS > 0
            AND BASE.CCW_FG_R_LRO_ROHS >= V_TOTAL_OUTLET
         THEN
            V_LRO_ROHS_OUTLET := V_TOTAL_OUTLET;
            V_LRO_NROHS_OUTLET := 0;
            V_FVE_ROHS_OUTLET := 0;
         ELSE
            V_LRO_ROHS_OUTLET := BASE.CCW_FG_R_LRO_ROHS;

            IF BASE.CCW_FG_R_LRO_NROHS >=
                  (V_TOTAL_OUTLET - V_LRO_ROHS_OUTLET)
            THEN
               V_LRO_NROHS_OUTLET := V_TOTAL_OUTLET - V_LRO_ROHS_OUTLET;
               V_FVE_ROHS_OUTLET := 0;
            ELSE
               V_LRO_NROHS_OUTLET := BASE.CCW_FG_R_LRO_NROHS;

               IF BASE.CCW_FG_R_FVE_ROHS >=
                     (V_TOTAL_OUTLET - V_LRO_ROHS_OUTLET - V_LRO_NROHS_OUTLET)
               THEN
                  V_FVE_ROHS_OUTLET :=
                     V_TOTAL_OUTLET - V_LRO_ROHS_OUTLET - V_LRO_NROHS_OUTLET;
               ELSE
                  V_FVE_ROHS_OUTLET := BASE.CCW_FG_R_FVE_ROHS;
               END IF;
            END IF;
         END IF;

         V_LRO_ROHS_RETAIL := -V_LRO_ROHS_OUTLET;

         V_LRO_NROHS_RETAIL := -V_LRO_NROHS_OUTLET;

         V_FVE_ROHS_RETAIL := -V_FVE_ROHS_OUTLET;

         V_TOTAL_RETAIL :=
            V_LRO_ROHS_RETAIL + V_LRO_NROHS_RETAIL + V_FVE_ROHS_RETAIL;

         -->> insert for outlet forward allocation table
         INSERT
           INTO RMKTGADM.RC_INV_OUTLET_FWD_ALLOCATION (REFRESH_PART_NUMBER,
                                                       OUTLET_ALLOC_QUANTITY,
                                                       CCW_FG_R_TOTAL,
                                                       CCW_FG_R_FVE_ROHS,
                                                       CCW_FG_R_LRO_ROHS,
                                                       CCW_FG_R_LRO_NROHS,
                                                       TOTAL_OUTLET,
                                                       OUTLET_LRO_ROHS_SPLIT,
                                                       OUTLET_LRO_NROHS_SPLIT,
                                                       OUTLET_FVE_SPLIT,
                                                       TOTAL_RETAIL,
                                                       RETAIL_LRO_ROHS_SPLIT,
                                                       RETAIL_LRO_NROHS_SPLIT,
                                                       RETAIL_FVE_SPLIT,
                                                       RECORD_CREATED_ON,
                                                       RECORD_CREATED_BY,
                                                       RECORD_UPDATED_ON,
                                                       RECORD_UPDATED_BY)
         VALUES (BASE.REFRESH_PART_NUMBER,
                 BASE.OUTLET_ALLOC_QUANTITY,
                 BASE.CCW_FG_R_TOTAL,
                 BASE.CCW_FG_R_FVE_ROHS,
                 BASE.CCW_FG_R_LRO_ROHS,
                 BASE.CCW_FG_R_LRO_NROHS,
                 V_TOTAL_OUTLET,
                 V_LRO_ROHS_OUTLET,
                 V_LRO_NROHS_OUTLET,
                 V_FVE_ROHS_OUTLET,
                 V_TOTAL_RETAIL,
                 V_LRO_ROHS_RETAIL,
                 V_LRO_NROHS_RETAIL,
                 V_FVE_ROHS_RETAIL,
                 SYSDATE,
                 'RC_INV_OUTLET_FORWARD_ALLOC',
                 SYSDATE,
                 'RC_INV_OUTLET_FORWARD_ALLOC');

         -->> insert for retail LRO Rohs
         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
                                                      PART_NUMBER,
                                                      NEW_FGI,
                                                      ROHS_COMPLIANT,
                                                      SITE_CODE,
                                                      PROCESS_STATUS,
                                                      -- AVAILABLE_TO_RESERVE_FGI,
                                                      -- GLOBAL_CUR_MAX,
                                                      UPDATED_ON,
                                                      UPDATED_BY,
                                                      CREATED_ON,
                                                      CREATED_BY,
                                                      --POE_BATCH_ID,
                                                      PRODUCT_TYPE)
              VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL, -- added on 07/25/2016
                      BASE.REFRESH_PART_NUMBER,
                      V_LRO_ROHS_RETAIL,
                      'YES',
                      'LRO',
                      'N',
                      -- BASE.CCW_FG_R_TOTAL,
                      -- BASE.RETAIL_MAX,
                      SYSDATE,
                      'RC_INV_OUTLET_FORWARD_ALLOC',
                      SYSDATE,
                      'RC_INV_OUTLET_FORWARD_ALLOC',
                      --BASE.POE_BATCH_ID,
                      'R');

         -->> insert for retail LRO Non-Rohs
         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
                                                      PART_NUMBER,
                                                      NEW_FGI,
                                                      ROHS_COMPLIANT,
                                                      SITE_CODE,
                                                      PROCESS_STATUS,
                                                      -- AVAILABLE_TO_RESERVE_FGI,
                                                      -- GLOBAL_CUR_MAX,
                                                      UPDATED_ON,
                                                      UPDATED_BY,
                                                      CREATED_ON,
                                                      CREATED_BY,
                                                      --POE_BATCH_ID,
                                                      PRODUCT_TYPE)
              VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL, -- added on 07/25/2016
                      BASE.REFRESH_PART_NUMBER,
                      V_LRO_NROHS_RETAIL,
                      'NO',
                      'LRO',
                      'N',
                      -- BASE.CCW_FG_R_TOTAL,
                      -- BASE.RETAIL_MAX,
                      SYSDATE,
                      'RC_INV_OUTLET_FORWARD_ALLOC',
                      SYSDATE,
                      'RC_INV_OUTLET_FORWARD_ALLOC',
                      --BASE.POE_BATCH_ID,
                      'R');

         -->> insert for retail FVE Rohs
         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
                                                      PART_NUMBER,
                                                      NEW_FGI,
                                                      ROHS_COMPLIANT,
                                                      SITE_CODE,
                                                      PROCESS_STATUS,
                                                      -- AVAILABLE_TO_RESERVE_FGI,
                                                      -- GLOBAL_CUR_MAX,
                                                      UPDATED_ON,
                                                      UPDATED_BY,
                                                      CREATED_ON,
                                                      CREATED_BY,
                                                      --POE_BATCH_ID,
                                                      PRODUCT_TYPE)
              VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL, -- added on 07/25/2016
                      BASE.REFRESH_PART_NUMBER,
                      V_FVE_ROHS_RETAIL,
                      'YES',
                      'FVE',
                      'N',
                      -- BASE.CCW_FG_R_TOTAL,
                      -- BASE.RETAIL_MAX,
                      SYSDATE,
                      'RC_INV_OUTLET_FORWARD_ALLOC',
                      SYSDATE,
                      'RC_INV_OUTLET_FORWARD_ALLOC',
                      --BASE.POE_BATCH_ID,
                      'R');

         -->> insert for Outlet LRO Rohs
         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
                                                      PART_NUMBER,
                                                      NEW_FGI,
                                                      ROHS_COMPLIANT,
                                                      SITE_CODE,
                                                      PROCESS_STATUS,
                                                      --AVAILABLE_TO_RESERVE_FGI,
                                                      --GLOBAL_CUR_MAX,
                                                      UPDATED_ON,
                                                      UPDATED_BY,
                                                      CREATED_ON,
                                                      CREATED_BY,
                                                      --POE_BATCH_ID,
                                                      PRODUCT_TYPE)
              VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL, -- added on 07/25/2016
                      BASE.REFRESH_PART_NUMBER,
                      V_LRO_ROHS_OUTLET,
                      'YES',
                      'LRO',
                      'N',
                      --BASE.CCW_FG_R_TOTAL,
                      --BASE.RETAIL_MAX,
                      SYSDATE,
                      'RC_INV_OUTLET_FORWARD_ALLOC',
                      SYSDATE,
                      'RC_INV_OUTLET_FORWARD_ALLOC',
                      --BASE.POE_BATCH_ID,
                      'O');

         -->> insert for Outlet LRO Non-Rohs
         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
                                                      PART_NUMBER,
                                                      NEW_FGI,
                                                      ROHS_COMPLIANT,
                                                      SITE_CODE,
                                                      PROCESS_STATUS,
                                                      --AVAILABLE_TO_RESERVE_FGI,
                                                      --GLOBAL_CUR_MAX,
                                                      UPDATED_ON,
                                                      UPDATED_BY,
                                                      CREATED_ON,
                                                      CREATED_BY,
                                                      --POE_BATCH_ID,
                                                      PRODUCT_TYPE)
              VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL, -- added on 07/25/2016
                      BASE.REFRESH_PART_NUMBER,
                      V_LRO_NROHS_OUTLET,
                      'NO',
                      'LRO',
                      'N',
                      --                 BASE.CCW_FG_R_TOTAL,
                      --                 BASE.RETAIL_MAX,
                      SYSDATE,
                      'RC_INV_OUTLET_FORWARD_ALLOC',
                      SYSDATE,
                      'RC_INV_OUTLET_FORWARD_ALLOC',
                      --BASE.POE_BATCH_ID,
                      'O');

         -->> insert for Outlet FVE Rohs
         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
                                                      PART_NUMBER,
                                                      NEW_FGI,
                                                      ROHS_COMPLIANT,
                                                      SITE_CODE,
                                                      PROCESS_STATUS,
                                                      --AVAILABLE_TO_RESERVE_FGI,
                                                      --GLOBAL_CUR_MAX,
                                                      UPDATED_ON,
                                                      UPDATED_BY,
                                                      CREATED_ON,
                                                      CREATED_BY,
                                                      --POE_BATCH_ID,
                                                      PRODUCT_TYPE)
              VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL, -- added on 07/25/2016
                      BASE.REFRESH_PART_NUMBER,
                      V_FVE_ROHS_OUTLET,
                      'YES',
                      'FVE',
                      'N',
                      --                 BASE.CCW_FG_R_TOTAL,
                      --                 BASE.RETAIL_MAX,
                      SYSDATE,
                      'RC_INV_OUTLET_FORWARD_ALLOC',
                      SYSDATE,
                      'RC_INV_OUTLET_FORWARD_ALLOC',
                      --BASE.POE_BATCH_ID,
                      'O');
      END LOOP;

      COMMIT;

      -->> Added New Condition to delete records for New FGI = 0
      DELETE FROM RMKTGADM.RC_INV_DELTA_SPLIT_LOG
            WHERE NEW_FGI = 0;

      -->> Hist table for RC_INV_OUTLET_FWD_ALLOCATION table
      INSERT INTO RMKTGADM.RC_INV_OUTLET_FWD_ALLOC_HIST
         SELECT * FROM RMKTGADM.RC_INV_OUTLET_FWD_ALLOCATION;

      INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG (INVENTORY_LOG_ID,
                                                  PART_NUMBER,
                                                  NEW_FGI,
                                                  NEW_DGI,
                                                  ROHS_COMPLIANT,
                                                  SITE_CODE,
                                                  PROCESS_STATUS,
                                                  PROGRAM_TYPE,
                                                  UPDATED_ON,
                                                  UPDATED_BY,
                                                  CREATED_ON,
                                                  CREATED_BY,
                                                  POE_BATCH_ID)
         SELECT OULOG.INVENTORY_LOG_ID,
                OULOG.PART_NUMBER,
                OULOG.NEW_FGI,
                0   NEW_DGI,
                OULOG.ROHS_COMPLIANT,
                OULOG.SITE_CODE,
                'N' PROCESS_STATUS,
                PRODUCT_TYPE,
                SYSDATE,
                G_UPDATED_BY,
                SYSDATE,
                G_UPDATED_BY,
                'OUTLET_FORWARD_ALLOCATION'
           FROM RMKTGADM.RC_INV_DELTA_SPLIT_LOG OULOG;

      --to Insert the Delta inv into  rmk_inventory_log from  rmk_inventory_log_stg

      INSERT INTO RMK_INVENTORY_LOG
         SELECT *
           FROM RMK_INVENTORY_LOG_STG
          WHERE     ATTRIBUTE1 IS NULL
                AND POE_BATCH_ID = 'OUTLET_FORWARD_ALLOCATION';

      --Updating the rmk_inventory_log_stg table after processing the Delta Inv.
      UPDATE RMK_INVENTORY_LOG_STG
         SET ATTRIBUTE1 = 'PROCESSED'
       WHERE     ATTRIBUTE1 IS NULL
             AND POE_BATCH_ID = 'OUTLET_FORWARD_ALLOCATION';

      COMMIT;

      INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                             CHL_STATUS,
                                             CHL_START_TIMESTAMP,
                                             CHL_END_TIMESTAMP,
                                             CHL_CRON_NAME,
                                             CHL_COMMENTS,
                                             CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'SUCCESS',
                   L_START_TIME,
                   SYSDATE,
                   'RC_INV_OUTLET_FORWARD_ALLOC',
                   NULL,
                   'RC_INV_DELTA_LOAD_RF');

      G_PROC_NAME := 'RC_INV_OUTLET_FORWARD_ALLOC';

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'FAILED',
                      G_START_TIME,
                      SYSDATE,
                      G_PROC_NAME,
                      G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_RF');

         G_PROC_NAME := 'RC_INV_OUTLET_FORWARD_ALLOC';

         COMMIT;

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_OUTLET_FORWARD_ALLOC;

   /* End Added as part of Selling FGI only requirement for Oct 27 Release on 15-OCT-2018 */

   PROCEDURE RC_INV_RF_DGI_FGI_LOAD (P_SITE_CODE IN VARCHAR2)
   IS
      /*** Start added as part of multiple rows fix(inserting multiple rows for same product) as part of APR 17 Sprint release***/
      /** commented as part of US390864 **/
      --      CURSOR DGI_DELTA
      --      IS
      --           SELECT DGI.PRODUCT_ID,
      --                  SUM (DGI.DELTA_DGI) DELTA_DGI,
      --                  DGI.PRODUCT_TYPE,
      --                  DGI.SOURCE_SYSTEM
      --             FROM RMKTGADM.RC_INV_DGI_DELTA DGI
      --            WHERE 1 = 1 AND DGI.PRODUCT_TYPE = 'R'
      --         GROUP BY DGI.PRODUCT_ID, DGI.PRODUCT_TYPE, DGI.SOURCE_SYSTEM;
      --
      --      DGI_DELTA_REC             DGI_DELTA%ROWTYPE;

      LV_RC_INV_FGI_DELTA_CNT   NUMBER;
      L_START_TIME              DATE;
      PROCESSED_COUNT           NUMBER := 0;
   ---commented as part of US438804 by Sumesh--
   --      email_msg_from            VARCHAR2 (100)     --added as part of US390864
   --                                   := 'refreshcentral-support@cisco.com'; --added as part of US390864
   --      email_receipient          VARCHAR2 (100)
   --         := 'daily_fg_addition_notifications@external.cisco.com'; --added as part of US390864
   --      email_msg_subject         VARCHAR2 (32767);  --added as part of US390864
   --      email_msg_body            VARCHAR2 (32767);  --added as part of US390864
   /*** End added as part of multiple rows fix(inserting multiple rows for same product) as part of APR 17 Sprint release***/

   --(Start) added by mohamms2 as on 05-OCT-2017 for User Story US134524 -> PID Deactivation changes - restrict DGI for T-4 PIDs
   --      L_AVAL_TO_RESERVE_DGI     NUMBER := 0;
   --      L_EOS_FLAG                VARCHAR2 (10) := 'N';
   --      L_DELTA_DGI               NUMBER := 0;
   --      L_AVAL_DGI                NUMBER := 0;
   --(End) added by mohamms2 as on 05-OCT-2017 for User Story US134524 -> PID Deactivation changes - restrict DGI for T-4 PIDs

   BEGIN
      G_PROC_NAME := 'RC_INV_RF_DGI_FGI_LOAD';

      L_START_TIME := SYSDATE;

      /** commented as part of US390864 **/
      --  ======>>>>>

      --      OPEN DGI_DELTA;
      --
      --      LOOP
      --         FETCH DGI_DELTA INTO DGI_DELTA_REC;
      --
      --         EXIT WHEN DGI_DELTA%NOTFOUND;
      --
      --         --(Start) added by mohamms2 as on 05-OCT-2017 for PID Deactivation changes - restrict DGI for T-4 PIDs
      --         --check if dgi_delta.product_id is in T-4, if yes pull the aval to reserve dgi
      --         --check how much to be processed to ccw in case of T-4 PID
      --         BEGIN
      --            L_DELTA_DGI := 0;
      --            L_EOS_FLAG := 'N';
      --            L_AVAL_TO_RESERVE_DGI := 0;
      --            L_AVAL_DGI := 0;
      --
      --            SELECT 'Y' EOS_FLAG,
      --                   (SELECT SUM (AVAILABLE_TO_RESERVE_DGI)
      --                      FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
      --                     WHERE     PART_NUMBER = PM.REFRESH_PART_NUMBER
      --                           AND INVENTORY_FLOW = 'Retail'
      --                           AND SITE_CODE = 'GDGI'
      --                           AND ROHS_COMPLIANT = 'YES')
      --                      AVAILABLE_TO_RESERVE_DGI,
      --                   (SELECT SUM (AVAILABLE_DGI)
      --                      FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
      --                     WHERE     PART_NUMBER = PM.REFRESH_PART_NUMBER
      --                           AND INVENTORY_FLOW = 'Retail'
      --                           AND SITE_CODE = 'GDGI'
      --                           AND ROHS_COMPLIANT = 'YES')
      --                      AVAILABLE_DGI,
      --                   (SELECT NVL (SUM (DGI.DELTA_DGI), 0)
      --                      FROM RMKTGADM.RC_INV_DGI_DELTA DGI
      --                     WHERE     DGI.PRODUCT_TYPE = 'R'
      --                           AND DGI.PRODUCT_ID = DGI_DELTA_REC.PRODUCT_ID
      --                           --  AND dgi.is_rohs = 'YES'
      --                           --AND dgi.site_shortname = 'GDGI'
      --                           AND NOT EXISTS
      --                                  (SELECT 1
      --                                     FROM RMKTGADM.RMK_INVENTORY_LOG_STG STG
      --                                    WHERE     STG.PART_NUMBER =
      --                                                 DGI.PRODUCT_ID
      --                                          -- AND stg.rohs_compliant = 'YES'
      --                                          AND STG.SITE_CODE = 'GDGI' --dgi.site_shortname
      --                                          AND PROGRAM_TYPE = DGI.PRODUCT_TYPE
      --                                          AND CREATED_ON >
      --                                                 SYSDATE - 1 / 24 * 0.5 --SYSDATE-1/24*0.5
      --                                                                       ))
      --                      DELTA_DGI
      --              INTO L_EOS_FLAG,
      --                   L_AVAL_TO_RESERVE_DGI,
      --                   L_AVAL_DGI,
      --                   L_DELTA_DGI
      --              FROM CRPADM.RC_PRODUCT_MASTER PM
      --             WHERE     PM.REFRESH_PART_NUMBER = DGI_DELTA_REC.PRODUCT_ID
      --                   AND PROGRAM_TYPE = 0
      --                   AND NVL (PM.MFG_EOS_DATE, SYSDATE + 130) <=
      --                          ADD_MONTHS (TRUNC (SYSDATE), 4);
      --         EXCEPTION
      --            WHEN OTHERS
      --            THEN
      --               L_EOS_FLAG := 'N';
      --               L_AVAL_TO_RESERVE_DGI := 0;
      --               L_DELTA_DGI := 0;
      --         END;
      --
      --         BEGIN
      --            IF (L_EOS_FLAG = 'Y' AND L_DELTA_DGI <> 0)
      --            THEN
      --               IF L_AVAL_TO_RESERVE_DGI > 0
      --               THEN
      --                  IF (-L_DELTA_DGI > L_AVAL_TO_RESERVE_DGI)
      --                  THEN
      --                     L_DELTA_DGI := L_DELTA_DGI;
      --                  ELSE
      --                     L_DELTA_DGI := -L_AVAL_TO_RESERVE_DGI;
      --                  END IF;
      --               ELSIF L_AVAL_TO_RESERVE_DGI = 0
      --               THEN
      --                  IF L_DELTA_DGI < 0
      --                  THEN
      --                     L_DELTA_DGI := L_DELTA_DGI;
      --                  ELSE
      --                     L_DELTA_DGI := 0;
      --                  END IF;
      --               ELSIF L_AVAL_TO_RESERVE_DGI < 0
      --               THEN
      --                  IF L_DELTA_DGI >= 0
      --                  THEN
      --                     L_DELTA_DGI :=
      --                        LEAST (-L_AVAL_TO_RESERVE_DGI, L_DELTA_DGI);
      --                  ELSE
      --                     L_DELTA_DGI := L_DELTA_DGI;
      --                  END IF;
      --               END IF;                    --l_aval_to_reserve_dgi if condition
      --
      --               IF (L_DELTA_DGI < 0)
      --               THEN
      --                  L_DELTA_DGI := -LEAST (L_AVAL_DGI, -L_DELTA_DGI);
      --               END IF;
      --
      --               DGI_DELTA_REC.DELTA_DGI := L_DELTA_DGI;
      --            ELSIF (L_EOS_FLAG = 'Y' AND L_DELTA_DGI = 0)
      --            THEN
      --               DGI_DELTA_REC.DELTA_DGI := L_DELTA_DGI;
      --            END IF;                                    --eos flag IF condition
      --         EXCEPTION
      --            WHEN OTHERS
      --            THEN
      --               NULL;
      --         END;
      --      --(End) added by mohamms2 as on 05-OCT-2017 for PID Deactivation changes - restrict DGI for T-4 PIDs

      /* Start Commented as part of Stop publishing DGI to CCW for Retail on 15-OCT-2018 by sridvasu */

      --         IF (DGI_DELTA_REC.DELTA_DGI <> 0)
      --         THEN --added by mohamms2 as on 05-OCT-2017 for PID Deactivation changes - restrict DGI for T-4 PIDs
      --            BEGIN
      --               INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG (INVENTORY_LOG_ID,
      --                                                           PART_NUMBER,
      --                                                           NEW_FGI,
      --                                                           NEW_DGI,
      --                                                           ROHS_COMPLIANT,
      --                                                           SITE_CODE,
      --                                                           PROCESS_STATUS,
      --                                                           PROGRAM_TYPE,
      --                                                           UPDATED_ON,
      --                                                           UPDATED_BY,
      --                                                           CREATED_ON,
      --                                                           CREATED_BY,
      --                                                           POE_BATCH_ID)
      --                    VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
      --                            DGI_DELTA_REC.PRODUCT_ID,
      --                            0,
      --                            DGI_DELTA_REC.DELTA_DGI,
      --                            'YES',
      --                            'GDGI',
      --                            'N',
      --                            DGI_DELTA_REC.PRODUCT_TYPE,
      --                            SYSDATE,
      --                            G_UPDATED_BY,
      --                            SYSDATE,
      --                            G_UPDATED_BY,
      --                            DGI_DELTA_REC.SOURCE_SYSTEM);
      --            EXCEPTION
      --               WHEN OTHERS
      --               THEN
      --                  RAISE_APPLICATION_ERROR (-20000, SQLERRM);
      --            END;
      --         END IF; --added by mohamms2 as on 05-OCT-2017 for PID Deactivation changes - restrict DGI for T-4 PIDs

      /* End Commented as part of Stop publishing DGI to CCW for Retail on 15-OCT-2018 by sridvasu */

      --      END LOOP;
      --
      --      CLOSE DGI_DELTA;
      --
      --      COMMIT;
      --
      --      COMMIT;

      SELECT RC_INV_CONTROL_FLAG
        INTO G_OUTLET_ALLOC_REQUIRED
        FROM RC_INV_CONTROL
       WHERE RC_INV_CONTROL_ID = 2; --RC_INV_CONTROL_NAME = 'REGULAR OUTLET ALLOCATION FLAG';--commented as part of sprint14(Aug Release)and added RC_INV_CONTROL_ID

      SELECT COUNT (1)
        INTO LV_RC_INV_FGI_DELTA_CNT
        FROM RMKTGADM.RC_INV_FGI_DELTA;

      -->> FGI Load

      IF G_OUTLET_ALLOC_REQUIRED = 'Y' AND LV_RC_INV_FGI_DELTA_CNT > 0
      THEN
         --         RC_INV_REGULAR_OUTLET_BASE;

         --         RC_INV_OUTLET_BTS_SPLIT; -- Commented existing Outlet proc as part of Selling FGI only requirement for Oct 27 Release on 15-OCT-2018

         RC_INV_OUTLET_FORWARD_ALLOC; -- Added new Outlet proc as part of Selling FGI only requirement for Oct 27 Release on 15-OCT-2018

         /** commented as part of US390864 **/
         --         INSERT INTO RMKTGADM.RC_INV_DGI_DELTA_HIST
         --            SELECT *
         --              FROM RMKTGADM.RC_INV_DGI_DELTA
         --             WHERE PRODUCT_TYPE = 'R';
         --
         --
         --
         --         DELETE FROM RMKTGADM.RC_INV_DGI_DELTA
         --               WHERE PRODUCT_TYPE = 'R'; --Added to avoid duplicate issue while calling RMK log for FGI insert


         INSERT INTO RC_INV_FGI_DELTA_HIST
            SELECT *
              FROM RMKTGADM.RC_INV_FGI_DELTA
             WHERE PRODUCT_TYPE = 'R';

         --         DELETE FROM RC_INV_FGI_DELTA
         --               WHERE PRODUCT_TYPE = 'R';

         COMMIT;
      ELSE                            -- when Outlet Allocation Required = 'N'
         DELETE FROM RMKTGADM.RC_INV_DELTA_SPLIT_LOG;

         COMMIT;

         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
                                                      PART_NUMBER,
                                                      NEW_FGI,
                                                      NEW_DGI,
                                                      ROHS_COMPLIANT,
                                                      SITE_CODE,
                                                      UPDATED_ON,
                                                      UPDATED_BY,
                                                      CREATED_ON,
                                                      CREATED_BY,
                                                      PRODUCT_TYPE,
                                                      SOURCE_SYSTEM,
                                                      PROCESS_STATUS)
            SELECT RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                   PRODUCT_ID,
                   DELTA_FGI,
                   0   NEW_DGI,
                   IS_ROHS,
                   SITE_SHORTNAME,
                   UPDATED_ON,
                   UPDATED_BY,
                   CREATED_ON,
                   CREATED_BY,
                   PRODUCT_TYPE,
                   SOURCE_SYSTEM,
                   'N' AS PROCESS_STATUS
              FROM RMKTGADM.RC_INV_FGI_DELTA;

         COMMIT;
      END IF;



      INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG (INVENTORY_LOG_ID,
                                                  PART_NUMBER,
                                                  NEW_FGI,
                                                  NEW_DGI,
                                                  ROHS_COMPLIANT,
                                                  SITE_CODE,
                                                  PROCESS_STATUS,
                                                  PROGRAM_TYPE,
                                                  UPDATED_ON,
                                                  UPDATED_BY,
                                                  CREATED_ON,
                                                  CREATED_BY,
                                                  POE_BATCH_ID)
         SELECT OULOG.INVENTORY_LOG_ID,
                OULOG.PART_NUMBER,
                OULOG.NEW_FGI,
                0 NEW_DGI,
                OULOG.ROHS_COMPLIANT,
                OULOG.SITE_CODE,
                --                'N' PROCESS_STATUS, -->> Commented on 08-MAR-2019
                CASE
                   WHEN OULOG.PART_NUMBER IN
                           (SELECT PART_NUMBER
                              FROM RC_INV_BLOCK_FGI_Q3FY19_ORDERS --RC_INV_MASK_STTG_FGI_MANUAL --RC_INV_BLOCK_FGI_Q3FY19_ORDERS
                             WHERE mask_inventory = 'Y')
                   THEN
                      'Y'
                   ELSE
                      'N'
                END
                   PROCESS_STATUS, -->> Added as part of Block FGI Q3FY19 Order on 08-MAR-2019
                PRODUCT_TYPE,
                SYSDATE,
                G_UPDATED_BY,
                SYSDATE,
                G_UPDATED_BY,
                SOURCE_SYSTEM
           FROM RMKTGADM.RC_INV_DELTA_SPLIT_LOG OULOG
          WHERE OULOG.NEW_FGI > 0; -->> Consider only Positive Outlet FG Record



      INSERT INTO RC_INV_DELTA_SPLIT_LOG_HIST
         SELECT * FROM RC_INV_DELTA_SPLIT_LOG;


      --      DELETE FROM RC_INV_DELTA_SPLIT_LOG;


      ---->>

      --to Insert the Delta inv into  rmk_inventory_log from  rmk_inventory_log_stg

      INSERT INTO RMK_INVENTORY_LOG
         SELECT *
           FROM RMK_INVENTORY_LOG_STG
          WHERE ATTRIBUTE1 IS NULL AND SITE_CODE IN ('FVE', 'LRO');

      --Updating the rmk_inventory_log_stg table after processing the Delta Inv.
      UPDATE RMK_INVENTORY_LOG_STG
         SET ATTRIBUTE1 = 'PROCESSED'
       WHERE ATTRIBUTE1 IS NULL AND SITE_CODE IN ('FVE', 'LRO');

      COMMIT;

      ---->>

      -->> Calling Rohs/Non-Rohs move procedure as part of US164572 on 02-APR-2018

      IF P_SITE_CODE = 'LRO'                     --added as part of PRB0063316
      THEN
         RC_INV_RF_FGI_ROHS_NROHS_MOVE;
         RC_STR_INV_MASK_ADJ ('ROHS_NONROHS_ADJUSTMENT', lv_status);
      END IF;

      --commented as part of US438804 by sumesh----
      ----ADDED AS PART OF US390864 BY SUMESH---

      --      SELECT COUNT (*)
      --        INTO PROCESSED_COUNT
      --        FROM RMKTGADM.RC_INV_DELTA_SPLIT_LOG OULOG
      --       WHERE OULOG.NEW_FGI > 0;
      --
      --      email_msg_subject :=
      --            'Retail quantities for '
      --         || TO_CHAR (P_SITE_CODE)
      --         || ' site is processed for '
      --         || TO_CHAR (SYSDATE);
      --      email_msg_body :=
      --            '<body>
      --                       Hi Team,<br><br>Retail quantities for '
      --         || TO_CHAR (P_SITE_CODE)
      --         || ' site is processed for '
      --         || TO_CHAR (SYSDATE)
      --         || '<br><br>
      --                       For any queries please contact Refresh Support Team:  refreshcentral-support@cisco.com.<br><br>
      --                       Thanks,<br>
      --                       Cisco Refresh Team.</body>';
      --
      --      IF (PROCESSED_COUNT >= 1)
      --      THEN
      --         BEGIN
      --            crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (
      --               email_msg_from,
      --               email_receipient,
      --               email_msg_subject,
      --               email_msg_body,
      --               NULL,
      --               NULL);
      --         EXCEPTION
      --            WHEN OTHERS
      --            THEN
      --               v_message := SUBSTR (SQLERRM, 1, 50);
      --         END;
      --      END IF;

      ---added as part of US438804 to send email notifications---
      INSERT INTO RC_INV_FG_VALUES
         SELECT PRODUCT_ID, SITE_SHORTNAME, DELTA_FGI
           FROM RMKTGADM.RC_INV_FGI_DELTA
          WHERE PRODUCT_TYPE = 'R' AND SOURCE_SYSTEM != 'POE';

      COMMIT;

      DELETE FROM RC_INV_FGI_DELTA
            WHERE PRODUCT_TYPE = 'R'; -->> Deleting Delta FG table after rohs move as part of US164572 on 02-APR-2018

      DELETE FROM RC_INV_DELTA_SPLIT_LOG; -->> Delta split log data after rohs move as part of US164572 on 02-APR-2018

      INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                             CHL_STATUS,
                                             CHL_START_TIMESTAMP,
                                             CHL_END_TIMESTAMP,
                                             CHL_CRON_NAME,
                                             CHL_COMMENTS,
                                             CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'SUCCESS',
                   L_START_TIME,
                   SYSDATE,
                   G_PROC_NAME,
                   NULL,
                   'RC_INV_DELTA_LOAD_RF');


      UPDATE RMKTGADM.CRON_CONTROL_INFO
         SET CRON_START_TIMESTAMP = G_START_TIME,
             CRON_END_TIMESTAMP = SYSDATE,
             CRON_STATUS = 'SUCCESS'
       WHERE     CRON_NAME = 'RC_INV_RF_DGI_FGI_LOAD'
             AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'RF_MAIN';



      G_PROC_NAME := 'RC_INV_RF_DGI_FGI_LOAD';

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'FAILED',
                      L_START_TIME,
                      SYSDATE,
                      G_PROC_NAME,
                      G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_RF');

         G_PROC_NAME := 'RC_INV_RF_DGI_FGI_LOAD';

         UPDATE RMKTGADM.CRON_CONTROL_INFO
            SET CRON_START_TIMESTAMP = G_START_TIME,
                CRON_END_TIMESTAMP = SYSDATE,
                CRON_STATUS = 'FAILED'
          WHERE     CRON_NAME = 'RC_INV_RF_DGI_FGI_LOAD'
                AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'RF_MAIN'; -->>Added

         COMMIT;

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_RF_DGI_FGI_LOAD;

   FUNCTION RC_INV_GET_REFURB_METHOD (I_RID                 NUMBER,
                                      I_ZCODE               VARCHAR2, --Added  parameter as part of userstory US193036 to modify yield calculation ligic
                                      I_SUB_INV_LOCATION    VARCHAR2) --Added  parameter as part of userstory US193036 to modify yield calculation ligic
      RETURN NUMBER
   IS
      LV_REFRESH_METHOD   NUMBER;
   BEGIN
      /* --Start Commented as part of userstory US193036 to modify yield calculation ligic

         SELECT MIN (RS.REFRESH_METHOD_ID)
           INTO LV_GLOBAL_REFRESH_METHOD
           FROM CRPADM.RC_PRODUCT_REPAIR_SETUP RS
          WHERE     RS.REFRESH_INVENTORY_ITEM_ID = I_RID
                AND RS.REFRESH_STATUS = 'ACTIVE';

         RETURN LV_GLOBAL_REFRESH_METHOD;

         --End Commented as part of userstory US193036 to modify yield calculation ligic
         */
      --Start Added as part of userstory US193036 to modify yield calculation ligic
      IF I_ZCODE IN ('Z05', 'Z29')
      THEN
         BEGIN
            SELECT NVL (RS.REFRESH_METHOD_ID, 0)
              INTO LV_REFRESH_METHOD
              FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                   CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
             WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                   AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                   AND RS.REFRESH_METHOD_ID IN
                          (SELECT DTLS.REFRESH_METHOD_ID
                             FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                  CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                            WHERE     MSTR.SUB_INVENTORY_ID =
                                         DTLS.SUB_INVENTORY_ID
                                  AND MSTR.SUB_INVENTORY_LOCATION =
                                         I_SUB_INV_LOCATION)
                   AND RP.ZCODE = I_ZCODE
                   AND RS.REFRESH_METHOD_ID = 3
                   AND RS.REFRESH_STATUS = 'ACTIVE'
                   AND RP.ACTIVE_FLAG = 'Y';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               LV_REFRESH_METHOD := 0;
            WHEN OTHERS
            THEN
               NULL;                                    -- need to be reviewed
         END;

         IF LV_REFRESH_METHOD = 0 OR LV_REFRESH_METHOD IS NULL
         THEN
            BEGIN
               SELECT NVL (MIN (RS.REFRESH_METHOD_ID), 0)
                 INTO LV_REFRESH_METHOD
                 FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                      CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                      AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                      AND RS.REFRESH_METHOD_ID IN
                             (SELECT DTLS.REFRESH_METHOD_ID
                                FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                     CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                               WHERE     MSTR.SUB_INVENTORY_ID =
                                            DTLS.SUB_INVENTORY_ID
                                     AND MSTR.SUB_INVENTORY_LOCATION =
                                            I_SUB_INV_LOCATION)
                      AND RP.ZCODE = I_ZCODE
                      AND RS.REFRESH_STATUS = 'ACTIVE'
                      AND RP.ACTIVE_FLAG = 'Y';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  LV_REFRESH_METHOD := 0;
               WHEN OTHERS
               THEN
                  NULL;                                 -- need to be reviewed
            END;

            IF LV_REFRESH_METHOD = 0 OR LV_REFRESH_METHOD IS NULL
            THEN
               BEGIN
                  SELECT NVL (MIN (RS.REFRESH_METHOD_ID), 0)
                    INTO LV_REFRESH_METHOD
                    FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                         CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                   WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                         AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                         AND RS.REFRESH_METHOD_ID IN
                                (SELECT DTLS.REFRESH_METHOD_ID
                                   FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                        CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                                  WHERE     MSTR.SUB_INVENTORY_ID =
                                               DTLS.SUB_INVENTORY_ID
                                        AND MSTR.SUB_INVENTORY_LOCATION =
                                               I_SUB_INV_LOCATION)
                         --              AND RP.ZCODE = I_ZCODE
                         AND RS.REFRESH_METHOD_ID <> 3
                         AND RS.REFRESH_STATUS = 'ACTIVE'
                         AND RP.ACTIVE_FLAG = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     LV_REFRESH_METHOD := 0;
                  WHEN OTHERS
                  THEN
                     NULL;                              -- need to be reviewed
               END;
            END IF;
         END IF;
      ELSE
         BEGIN
            SELECT NVL (MIN (RS.REFRESH_METHOD_ID), 0)
              INTO LV_REFRESH_METHOD
              FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                   CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
             WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                   AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                   AND RS.REFRESH_METHOD_ID IN
                          (SELECT DTLS.REFRESH_METHOD_ID
                             FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                  CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                            WHERE     MSTR.SUB_INVENTORY_ID =
                                         DTLS.SUB_INVENTORY_ID
                                  AND MSTR.SUB_INVENTORY_LOCATION =
                                         I_SUB_INV_LOCATION)
                   AND RP.ZCODE = I_ZCODE
                   AND RS.REFRESH_METHOD_ID <> 3
                   AND RS.REFRESH_STATUS = 'ACTIVE'
                   AND RP.ACTIVE_FLAG = 'Y';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               LV_REFRESH_METHOD := 0;
            WHEN OTHERS
            THEN
               NULL;                                    -- need to be reviewed
         END;

         IF LV_REFRESH_METHOD = 0 OR LV_REFRESH_METHOD IS NULL
         THEN
            BEGIN
               SELECT NVL (MIN (RS.REFRESH_METHOD_ID), 0)
                 INTO LV_REFRESH_METHOD
                 FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                      CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                      AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                      AND RS.REFRESH_METHOD_ID IN
                             (SELECT DTLS.REFRESH_METHOD_ID
                                FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                     CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                               WHERE     MSTR.SUB_INVENTORY_ID =
                                            DTLS.SUB_INVENTORY_ID
                                     AND MSTR.SUB_INVENTORY_LOCATION =
                                            I_SUB_INV_LOCATION)
                      --          AND RP.ZCODE = I_ZCODE
                      AND RS.REFRESH_METHOD_ID <> 3
                      AND RS.REFRESH_STATUS = 'ACTIVE'
                      AND RP.ACTIVE_FLAG = 'Y';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  LV_REFRESH_METHOD := 0;
               WHEN OTHERS
               THEN
                  NULL;                                 -- need to be reviewed
            END;
         END IF;
      END IF;

      RETURN LV_REFRESH_METHOD;
   --End Added as part of userstory US193036 to modify yield calculation ligic

   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0; ---Added as part of userstory US193036 to modify yield calculation ligic

         DBMS_OUTPUT.PUT_LINE (
            'NO DATA in RC_PRODUCT_REPAIR_SETUP for ' || I_RID);
      WHEN OTHERS
      THEN
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         DBMS_OUTPUT.PUT_LINE (G_ERROR_MSG);


         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'FAILED',
                      G_START_TIME,
                      SYSDATE,
                      'RC_INV_GET_REFURB_METHOD',
                      G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_RF');

         G_PROC_NAME := 'RC_INV_GET_REFURB_METHOD';

         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_GET_REFURB_METHOD;

   FUNCTION RC_INV_GET_YIELD ( /*I_PRODUCT_TYPE                 NUMBER,  --Removing  parameter as part of userstory US193036 to modify yield calculation ligic */
                              /* I_THEATER_ID                   NUMBER,  --Removing  parameter as part of userstory US193036 to modify yield calculation ligic */
                              /* I_REFRESH_METHOD_ID            NUMBER,  --Removing  parameter as part of userstory US193036 to modify yield calculation ligic */
                              I_RID                 INTEGER, -- Added  parameter as part of userstory US193036 to modify yield calculation ligic
                              I_ZCODE               VARCHAR2,
                              I_SUB_INV_LOCATION    VARCHAR2) -- Added  parameter as part of userstory US193036 to modify yield calculation ligic
      RETURN NUMBER
   IS
      LV_YIELD   NUMBER;
   BEGIN
      /*  Start Commented as part of userstory US193036 to modify yield calculation ligic
         SELECT NVL (REFRESH_YIELD, 0)
           INTO LV_YIELD
           FROM CRPADM.RC_PRODUCT_REPAIR_SETUP RS
                INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                   ON (PM.REFRESH_INVENTORY_ITEM_ID =
                          RS.REFRESH_INVENTORY_ITEM_ID)
                INNER JOIN CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                   ON (    RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                       AND RP.ACTIVE_FLAG = 'Y')
          WHERE     PM.PROGRAM_TYPE = I_PRODUCT_TYPE --0                  -- (paramer 1) pm.product_type
                AND RS.REFRESH_INVENTORY_ITEM_ID = I_REFRESH_INVENTORY_ITEM_ID --4210960 -- (Parameter 2)  pm.refresh_inventory_item_id
                AND RS.THEATER_ID = I_THEATER_ID --1   --,3  -- (Parameter 3) Map.REGION  (NAM , EMEA)
                AND RP.ZCODE = I_ZCODE --'Z05'       -- (parameter 4)  SUBSTR (C3.PLACE_ID, 1, 3)
                AND RS.REFRESH_STATUS = 'ACTIVE'
                AND RS.REFRESH_METHOD_ID = I_REFRESH_METHOD_ID --RMKTGADM.RC_INV_DELTA_LOAD_RF.RC_INV_GET_REFURB_METHOD(pm.refresh_inventory_item_id)
                AND RP.PROGRAM_TYPE = I_PRODUCT_TYPE;
        End Commented as part of userstory US193036 to modify yield calculation ligic */

      /*  Start Added as part of userstory US193036 to modify yield calculation ligic */

      IF I_ZCODE IN ('Z05', 'Z29')
      THEN
         BEGIN
            SELECT NVL (RS.REFRESH_YIELD, 0)
              INTO LV_YIELD
              FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                   CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
             WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                   AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                   AND RS.REFRESH_METHOD_ID IN
                          (SELECT DTLS.REFRESH_METHOD_ID
                             FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                  CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                            WHERE     MSTR.SUB_INVENTORY_ID =
                                         DTLS.SUB_INVENTORY_ID
                                  AND MSTR.SUB_INVENTORY_LOCATION =
                                         I_SUB_INV_LOCATION)
                   AND RP.ZCODE = I_ZCODE
                   AND RS.REFRESH_METHOD_ID = 3
                   AND RS.REFRESH_STATUS = 'ACTIVE'
                   AND RP.ACTIVE_FLAG = 'Y';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               LV_YIELD := 0;
            WHEN OTHERS
            THEN
               LV_YIELD := 0;                           -- need to be reviewed
         END;

         IF LV_YIELD = 0 OR LV_YIELD IS NULL
         THEN
            BEGIN
               SELECT NVL (MIN (RS.REFRESH_YIELD), 0)
                 INTO LV_YIELD
                 FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                      CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                      AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                      AND RS.REFRESH_METHOD_ID IN
                             (SELECT DTLS.REFRESH_METHOD_ID
                                FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                     CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                               WHERE     MSTR.SUB_INVENTORY_ID =
                                            DTLS.SUB_INVENTORY_ID
                                     AND MSTR.SUB_INVENTORY_LOCATION =
                                            I_SUB_INV_LOCATION)
                      AND RP.ZCODE = I_ZCODE
                      AND RS.REFRESH_STATUS = 'ACTIVE'
                      AND RP.ACTIVE_FLAG = 'Y';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  LV_YIELD := 0;
               WHEN OTHERS
               THEN
                  LV_YIELD := 0;                        -- need to be reviewed
            END;

            IF LV_YIELD = 0 OR LV_YIELD IS NULL
            THEN
               BEGIN
                  SELECT NVL (MIN (RS.REFRESH_YIELD), 0)
                    INTO LV_YIELD
                    FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                         CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                   WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                         AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                         AND RS.REFRESH_METHOD_ID IN
                                (SELECT DTLS.REFRESH_METHOD_ID
                                   FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                        CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                                  WHERE     MSTR.SUB_INVENTORY_ID =
                                               DTLS.SUB_INVENTORY_ID
                                        AND MSTR.SUB_INVENTORY_LOCATION =
                                               I_SUB_INV_LOCATION)
                         --              AND RP.ZCODE = I_ZCODE
                         AND RS.REFRESH_METHOD_ID <> 3
                         AND RS.REFRESH_STATUS = 'ACTIVE'
                         AND RP.ACTIVE_FLAG = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     LV_YIELD := 0;
                  WHEN OTHERS
                  THEN
                     LV_YIELD := 0;                     -- need to be reviewed
               END;
            END IF;
         END IF;
      ELSE
         BEGIN
            SELECT NVL (MIN (RS.REFRESH_YIELD), 0)
              INTO LV_YIELD
              FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                   CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
             WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                   AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                   AND RS.REFRESH_METHOD_ID IN
                          (SELECT DTLS.REFRESH_METHOD_ID
                             FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                  CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                            WHERE     MSTR.SUB_INVENTORY_ID =
                                         DTLS.SUB_INVENTORY_ID
                                  AND MSTR.SUB_INVENTORY_LOCATION =
                                         I_SUB_INV_LOCATION)
                   AND RP.ZCODE = I_ZCODE
                   AND RS.REFRESH_METHOD_ID <> 3
                   AND RS.REFRESH_STATUS = 'ACTIVE'
                   AND RP.ACTIVE_FLAG = 'Y';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               LV_YIELD := 0;
            WHEN OTHERS
            THEN
               LV_YIELD := 0;                           -- need to be reviewed
         END;

         IF LV_YIELD = 0 OR LV_YIELD IS NULL
         THEN
            BEGIN
               SELECT NVL (MIN (RS.REFRESH_YIELD), 0)
                 INTO LV_YIELD
                 FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                      CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                      AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                      AND RS.REFRESH_METHOD_ID IN
                             (SELECT DTLS.REFRESH_METHOD_ID
                                FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                     CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                               WHERE     MSTR.SUB_INVENTORY_ID =
                                            DTLS.SUB_INVENTORY_ID
                                     AND MSTR.SUB_INVENTORY_LOCATION =
                                            I_SUB_INV_LOCATION)
                      --          AND RP.ZCODE = I_ZCODE
                      AND RS.REFRESH_METHOD_ID <> 3
                      AND RS.REFRESH_STATUS = 'ACTIVE'
                      AND RP.ACTIVE_FLAG = 'Y';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  LV_YIELD := 0;
               WHEN OTHERS
               THEN
                  LV_YIELD := 0;                        -- need to be reviewed
            END;
         END IF;
      END IF;

      /* End Added as part of userstory US193036 to modify yield calculation ligic */


      RETURN LV_YIELD;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0;
      ----      DBMS_OUTPUT.PUT_LINE (
      ----         'NO DATA in RC_PRODUCT_REPAIR_SETUP for ');-- I_RID);
      WHEN OTHERS
      THEN
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'FAILED',
                      G_START_TIME,
                      SYSDATE,
                      'RC_INV_GET_YIELD',
                      G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_RF');

         G_PROC_NAME := 'RC_INV_GET_YIELD';

         COMMIT;

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_GET_YIELD;

   PROCEDURE RC_INV_RF_SEND_WARNING_EMAIL (I_PROCEDURE_NAME    VARCHAR2,
                                           I_ERROR_MSG         VARCHAR2)
   IS
      L_SUBJECT          VARCHAR2 (250);
      O_CONTENT          VARCHAR2 (1500);
      lv_database_name   VARCHAR2 (50); --Added as part of Nov'2018 release by csirigir on 30-OCT-2018
   BEGIN
      O_CONTENT :=
            '<HTML>Hello,<br /><br /> Warning Message from <b> '
         || SUBSTR (I_PROCEDURE_NAME, 1, 37)
         || '</b> Procedure.  Please take corrective action.
        <br/>
        <br/>
        <font color="red"><b>Warning Message : </b></font> '
         || I_ERROR_MSG
         || ' <br /><br />
        <br /> Thanks '
         || CHR (38)
         || ' Regards, <br />
        Cisco Refresh Support Team
      </HTML>';

      /* L_SUBJECT :=             --Commented as part of Nov'2018 release by csirigir on 30-OCT-2018
            'Warning : '
         || I_PROCEDURE_NAME
         || '  procedure executed with Warning'; */

      --<Start> Added as part of Nov'2018 release by csirigir on 30-OCT-2018

      SELECT ora_database_name INTO lv_database_name FROM DUAL;

      IF (lv_database_name = 'FNTR2PRD.CISCO.COM')
      THEN
         l_subject :=
               'Warning :  '
            || I_PROCEDURE_NAME
            || '  procedure executed with Warning';
      ELSIF (lv_database_name = 'FNTR2STG.CISCO.COM')
      THEN
         l_subject :=
               'STAGE : '
            || 'Warning :  '
            || I_PROCEDURE_NAME
            || '  procedure executed with Warning';
      ELSE
         l_subject :=
               'DEV : '
            || 'Warning :  '
            || I_PROCEDURE_NAME
            || '  procedure executed with Warning';
      END IF;

      --<End> Added as part of Nov'2018 release by csirigir on 30-OCT-2018

      /* Start added as part of RSCM object references changes in Sprint#18 Release as on 15-Jan-18*/
      CRPADM.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (G_ACT_SUPPORT, --i_mail_from
                                                           G_TO,   --i_mail_to
                                                           L_SUBJECT, --i_mail_sub
                                                           O_CONTENT, --i_html_msg
                                                           NULL, --i_file_name
                                                           NULL); --i_attach_lob
   /* End added as part of RSCM object references changes in Sprint#18 Release as on 15-Jan-18*/


   /* commented as part of RSCM object references changes in Sprint#18 Release as on 15-Jan-18
     VAVNI_CISCO_RSCM_ADMIN.VV_RSCM_UTIL.GENERIC_EMAIL_UTIL (G_TO,
                                                             G_ACT_SUPPORT,
                                                             L_SUBJECT,
                                                             O_CONTENT);
   */

   END RC_INV_RF_SEND_WARNING_EMAIL;

   PROCEDURE RC_INV_RF_SEND_ERROR_EMAIL (I_PROCEDURE_NAME    VARCHAR2,
                                         I_ERROR_MSG         VARCHAR2)
   IS
      L_SUBJECT          VARCHAR2 (250);
      O_CONTENT          VARCHAR2 (1500);
      lv_database_name   VARCHAR2 (50); --Added as part of Nov'2018 release by csirigir on 30-OCT-2018
   BEGIN
      O_CONTENT :=
            '<HTML>Hello,<br /><br /> Error occured in <b>'
         || I_PROCEDURE_NAME
         || '</b> procedure . Please take corrective action.
        <br />
        <br />
        <font color="red"><b>Error Messsage :</b></font>  '
         || I_ERROR_MSG
         || ' <br /><br />
        <br /> Thanks '
         || CHR (38)
         || ' Regards, <br />
        Cisco Refresh Support Team
      </HTML>';

      /* L_SUBJECT :=          --Commented as part of Nov'2018 release by csirigir on 30-OCT-2018
             'Warning : '
          || I_PROCEDURE_NAME
          || '  procedure executed with errors ';  */

      --<Start> Added as part of Nov'2018 release by csirigir on 30-OCT-2018

      SELECT ora_database_name INTO lv_database_name FROM DUAL;

      IF (lv_database_name = 'FNTR2PRD.CISCO.COM')
      THEN
         l_subject :=
               'Warning :  '
            || I_PROCEDURE_NAME
            || '  procedure executed with errors ';
      ELSIF (lv_database_name = 'FNTR2STG.CISCO.COM')
      THEN
         l_subject :=
               'STAGE : '
            || 'Warning :  '
            || I_PROCEDURE_NAME
            || '  procedure executed with errors ';
      ELSE
         l_subject :=
               'DEV : '
            || 'Warning :  '
            || I_PROCEDURE_NAME
            || '  procedure executed with errors ';
      END IF;

      --<End> Added as part of Nov'2018 release by csirigir on 30-OCT-2018


      /* Start added as part of RSCM object references changes in Sprint#18 Release as on 15-Jan-18*/
      CRPADM.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (G_ACT_SUPPORT, --i_mail_from
                                                           G_TO,   --i_mail_to
                                                           L_SUBJECT, --i_mail_sub
                                                           O_CONTENT, --i_html_msg
                                                           NULL, --i_file_name
                                                           NULL); --i_attach_lob
   /* End added as part of RSCM object references changes in Sprint#18 Release as on 15-Jan-18*/


   /* Commented as part of RSCM object references changes in Sprint#18 Release as on 15-Jan-18
  VAVNI_CISCO_RSCM_ADMIN.VV_RSCM_UTIL.GENERIC_EMAIL_UTIL (G_TO,
                G_ACT_SUPPORT,
                L_SUBJECT,
                O_CONTENT);
     */

   END RC_INV_RF_SEND_ERROR_EMAIL;

   --(Start) added by mohamms2 as on 05-OCT-2017 for User Story US134524 -> PID Deactivation changes - restrict DGI for T-4 PIDs
   PROCEDURE RC_INV_RF_EOS_PID_QTY_REVOKE
   IS
      CURSOR EOS_REVOKE
      IS
           SELECT XIM.PART_NUMBER,
                  XIM.SITE_CODE,
                  XIM.ROHS_COMPLIANT,
                  SUM (XIM.AVAILABLE_TO_RESERVE_DGI) AVAILABLE_TO_RESERVE_DGI
             FROM XXCPO_RMK_INVENTORY_MASTER XIM, CRPADM.RC_PRODUCT_MASTER PM
            WHERE     1 = 1
                  AND XIM.PART_NUMBER = PM.REFRESH_PART_NUMBER
                  AND XIM.SITE_CODE = 'GDGI'
                  AND XIM.INVENTORY_FLOW = 'Retail'
                  AND XIM.ROHS_COMPLIANT = 'YES'
                  AND PM.REFRESH_LIFE_CYCLE_ID <> 6 -- ignore deactivated pids
                  AND XIM.AVAILABLE_TO_RESERVE_DGI > 0
                  AND PM.PROGRAM_TYPE = 0
                  AND NVL (PM.MFG_EOS_DATE, SYSDATE + 130) <=
                         ADD_MONTHS (TRUNC (SYSDATE), 4)
                  AND XIM.PART_NUMBER NOT IN
                         (SELECT PRODUCT_ID
                            FROM RC_INV_DGI_DELTA_HIST
                           WHERE     PRODUCT_TYPE = 'R'
                                 AND CREATED_ON > SYSDATE - 0.5 / 24)
         GROUP BY XIM.PART_NUMBER, XIM.SITE_CODE, XIM.ROHS_COMPLIANT;

      REV_RETAIL     EOS_REVOKE%ROWTYPE;
      L_START_TIME   DATE;
      G_ERROR_MSG    VARCHAR2 (300);
      SYSTIME        NUMBER;
      RUNCOUNT       NUMBER;
   BEGIN
      L_START_TIME := SYSDATE;

      SELECT CONFIG_ID
        INTO SYSTIME
        FROM RMKTGADM.RC_INV_CONFIG
       WHERE CONFIG_NAME = 'T90';

      SELECT COUNT (*)
        INTO RUNCOUNT
        FROM RMKTGADM.CRON_HISTORY_LOG L
       WHERE     1 = 1
             AND CHL_CRON_NAME = 'RC_INV_RF_EOS_PID_QTY_REVOKE'
             AND CHL_CREATED_BY = 'RC_INV_DELTA_LOAD_RF'
             AND CHL_START_TIMESTAMP >= SYSDATE - SYSTIME / (24 * 60);

      -- DELETE FROM RMKTGADM.RC_INV_EOS_R_REVOKE;
      IF (RUNCOUNT = 0)
      THEN
         DELETE FROM RMKTGADM.RC_INV_EOS_QTY_R_REVOKE;

         COMMIT;

         OPEN EOS_REVOKE;

         LOOP
            FETCH EOS_REVOKE INTO REV_RETAIL;

            EXIT WHEN EOS_REVOKE%NOTFOUND;

            --      INSERT INTO RMKTGADM.RC_INV_EOS_R_REVOKE
            --           VALUES (REV_RETAIL.PART_NUMBER,
            --                   REV_RETAIL.AVAILABLE_TO_RESERVE_DGI,
            --                   REV_RETAIL.SITE_CODE,
            --                   REV_RETAIL.ROHS_COMPLIANT,
            --                   REV_RETAIL.INVENTORY_FLOW,
            --                   SYSDATE);


            INSERT INTO RMKTGADM.RC_INV_EOS_QTY_R_REVOKE (INVENTORY_LOG_ID,
                                                          PART_NUMBER,
                                                          NEW_FGI,
                                                          NEW_DGI,
                                                          ROHS_COMPLIANT,
                                                          SITE_CODE,
                                                          PROCESS_STATUS,
                                                          UPDATED_ON,
                                                          UPDATED_BY,
                                                          CREATED_ON,
                                                          CREATED_BY,
                                                          POE_BATCH_ID,
                                                          PROGRAM_TYPE)
                 VALUES (RC_INV_LOG_PK_SEQ.NEXTVAL,
                         REV_RETAIL.PART_NUMBER,
                         0,
                         REV_RETAIL.AVAILABLE_TO_RESERVE_DGI * -1,
                         REV_RETAIL.ROHS_COMPLIANT,
                         REV_RETAIL.SITE_CODE,
                         'N',
                         SYSDATE,
                         'POEADMIN',
                         SYSDATE,
                         'POEADMIN',
                         'RC_INV_RF_EOS_PID_QTY_REVOKE',
                         'R');
         END LOOP;

         CLOSE EOS_REVOKE;

         INSERT INTO RMKTGADM.RC_INV_EOS_QTY_REVOKE_HIST
            SELECT * FROM RMKTGADM.RC_INV_EOS_QTY_R_REVOKE;

         /* Start Commented as part of Stop publishing DGI to CCW for Retail on 15-OCT-2018 by sridvasu */

         --         INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG
         --            SELECT * FROM RMKTGADM.RC_INV_EOS_QTY_R_REVOKE;
         --
         --
         --         INSERT INTO RMKTGADM.RMK_INVENTORY_LOG
         --            SELECT *
         --              FROM RMKTGADM.RMK_INVENTORY_LOG_STG
         --             WHERE     ATTRIBUTE1 IS NULL
         --                   AND POE_BATCH_ID LIKE 'RC_INV_RF_EOS_PID_QTY_REVOKE';
         --
         --
         --         UPDATE RMK_INVENTORY_LOG_STG
         --            SET ATTRIBUTE1 = 'PROCESSED'
         --          WHERE     ATTRIBUTE1 IS NULL
         --                AND POE_BATCH_ID LIKE 'RC_INV_RF_EOS_PID_QTY_REVOKE';

         /* End Commented as part of Stop publishing DGI to CCW for Retail on 15-OCT-2018 by sridvasu */

         COMMIT;

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'SUCCESS',
                      L_START_TIME,
                      SYSDATE,
                      'RC_INV_RF_EOS_PID_QTY_REVOKE',
                      NULL,
                      'RC_INV_DELTA_LOAD_RF');


         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'FAILED',
                      L_START_TIME,
                      SYSDATE,
                      'RC_INV_RF_EOS_PID_QTY_REVOKE',
                      G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_RF');

         COMMIT;
   --END IF;
   END RC_INV_RF_EOS_PID_QTY_REVOKE;

   --(End) added by mohamms2 as on 05-OCT-2017 for User Story US134524 -> PID Deactivation changes - restrict DGI for T-4 PIDs Sprint

   /* Start Added to send mail to inventory admins when shortage in RoHS/NRoHS adjustments as part of US164572 as on 09-APR-2018 */

   PROCEDURE RC_INV_ROHS_NROHS_SEND_MAIL
   IS
      LV_CHL_START_TIME_STAMP   TIMESTAMP;
      LV_SUBJECT                VARCHAR2 (150);
      LV_MSG_CONTENT            VARCHAR2 (9000);
      LV_DATABASE_NAME          VARCHAR2 (300);
      LV_MAIL_TO                CRPADM.RC_EMAIL_NOTIFICATIONS.EMAIL_RECIPIENTS%TYPE;
      LV_DEV_MAIL_RECEIPENTS    CRPADM.RC_EMAIL_NOTIFICATIONS.EMAIL_RECIPIENTS%TYPE;
      LV_STG_MAIL_RECEIPENTS    CRPADM.RC_EMAIL_NOTIFICATIONS.EMAIL_RECIPIENTS%TYPE;
      LV_PRD_MAIL_RECEIPENTS    CRPADM.RC_EMAIL_NOTIFICATIONS.EMAIL_RECIPIENTS%TYPE;
      LV_MAIL_SENDER            VARCHAR2 (100);
      LV_MAIL_FROM              VARCHAR2 (100);
      LV_ERROR_MSG              VARCHAR2 (800);
      G_ERROR_MSG               VARCHAR2 (1000);
      LV_MSG_CONTENT1           VARCHAR2 (1000);
      LV_MSG_CONTENT2           VARCHAR2 (1000);
      LV_MSG_TEXT               VARCHAR2 (10000);
      LV_SYSDATE                DATE;
      LV_COUNT                  NUMBER;
   BEGIN
      BEGIN
         SELECT MAX (CHL.CHL_START_TIMESTAMP)
           INTO LV_CHL_START_TIME_STAMP
           FROM RMKTGADM.CRON_HISTORY_LOG CHL
          WHERE     1 = 1
                AND CHL.CHL_CRON_NAME IN ('RF_MAIN', 'EX_MAIN')
                AND CHL.CHL_CREATED_BY IN
                       ('RC_INV_DELTA_LOAD_RF', 'RC_INV_DELTA_LOAD_EX')
                AND TRUNC (CHL.CHL_START_TIMESTAMP) = TRUNC (SYSDATE)
                AND CHL_COMMENTS = 'LRO';
      EXCEPTION
         WHEN OTHERS
         THEN
            LV_ERROR_MSG :=
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
      END;


      BEGIN
         SELECT ORA_DATABASE_NAME, SYSDATE
           INTO LV_DATABASE_NAME, LV_SYSDATE
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            LV_ERROR_MSG :=
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
      END;



      LV_SUBJECT :=
            'RoHS/Non-RoHS Inventory Movements-'
         || TO_CHAR (LV_SYSDATE, 'DD-MON-YYYY HH24:MI:SS AM')
         || ' PST';


      IF (ORA_DATABASE_NAME = 'FNTR2DEV.CISCO.COM')
      THEN
         BEGIN
            SELECT EMAIL_SENDER, EMAIL_RECIPIENTS
              INTO LV_MAIL_SENDER, LV_DEV_MAIL_RECEIPENTS
              FROM CRPADM.RC_EMAIL_NOTIFICATIONS
             WHERE NOTIFICATION_NAME = 'RC_INV_ROHS_NROHS_MOVE_DEV';
         EXCEPTION
            WHEN OTHERS
            THEN
               LV_ERROR_MSG :=
                     SUBSTR (SQLERRM, 1, 200)
                  || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         END;

         LV_MAIL_FROM := LV_MAIL_SENDER;
         LV_SUBJECT := 'DEV : ' || LV_SUBJECT;
         LV_MAIL_TO := LV_DEV_MAIL_RECEIPENTS;
      ELSIF (ORA_DATABASE_NAME = 'FNTR2STG.CISCO.COM')
      THEN
         BEGIN
            SELECT EMAIL_SENDER, EMAIL_RECIPIENTS
              INTO LV_MAIL_SENDER, LV_STG_MAIL_RECEIPENTS
              FROM CRPADM.RC_EMAIL_NOTIFICATIONS
             WHERE 1 = 1 AND NOTIFICATION_NAME = 'RC_INV_ROHS_NROHS_MOVE_STG';
         EXCEPTION
            WHEN OTHERS
            THEN
               LV_ERROR_MSG :=
                     SUBSTR (SQLERRM, 1, 200)
                  || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         END;

         LV_MAIL_FROM := LV_MAIL_SENDER;
         LV_SUBJECT := 'STAGE : ' || LV_SUBJECT;
         LV_MAIL_TO := LV_STG_MAIL_RECEIPENTS;
      ELSIF (ORA_DATABASE_NAME = 'FNTR2PRD.CISCO.COM')
      THEN
         BEGIN
            SELECT EMAIL_SENDER, EMAIL_RECIPIENTS
              INTO LV_MAIL_SENDER, LV_PRD_MAIL_RECEIPENTS
              FROM CRPADM.RC_EMAIL_NOTIFICATIONS
             WHERE 1 = 1 AND NOTIFICATION_NAME = 'RC_INV_ROHS_NROHS_MOVE_PRD';
         EXCEPTION
            WHEN OTHERS
            THEN
               LV_ERROR_MSG :=
                     SUBSTR (SQLERRM, 1, 200)
                  || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         END;

         LV_MAIL_FROM := LV_MAIL_SENDER;
         LV_SUBJECT := LV_SUBJECT;
         LV_MAIL_TO := LV_PRD_MAIL_RECEIPENTS;
      END IF;

      -- width: 50%;

      LV_MSG_CONTENT1 :=
         ' <head>
                 <style>
                    table {
                          border-collapse: collapse;

                        }
                        th, td {
                          padding: 0.25rem;
                          text-align: left;
                          border: 1px solid #ccc;
                        }
                  </style>
                    </head>
                    <body>
                    <table>
                         <tr>
                         <th>Tan ID</th><th>Part Number</th><th>Site Code</th><th>Rohs Flag</th><th>Suggested Adjustments</th><th>Processed Adjustments</th></tr>';

      LV_MSG_CONTENT2 :=
         '<HTML><br> PLEASE DO NOT REPLY... This is an Auto generated Email.
                          </br>
                          <br>
                          Thanks ' || CHR (38) || ' Regards, <br />
                         Refresh Central Support Team
                        </HTML>';


      LV_MSG_CONTENT :=
            '<HTML>Hi Team,
                            <br>
                                <br>Insufficient inventory to process RoHS/Non-RoHS Inventory Movements.
                                    <br><br>
                  </HTML> '
         || LV_MSG_CONTENT1; --||'<HTML> <br>'||LV_MSG_CONTENT2||'</br> </HTML>';


      SELECT COUNT (1)
        INTO LV_COUNT
        FROM RMKTGADM.RC_INV_ROHS_MOVE_SHORT_ENTRIES --RMKTGADM.RC_INV_ROHS_MOVE_SHORT_ENTRIES
       WHERE STATUS_FLAG = 'Y';

      IF LV_COUNT > 0
      THEN
         FOR REC IN (SELECT TAN_ID,
                            REFRESH_PART_NUMBER PART_NUMBER,
                            SITE_CODE,
                            ROHS_COMPLIANT      ROHS_FLAG,
                            SUGGESTED_ADJUSTMENT,
                            PROCESSED_ADJUSTMENT
                       FROM RMKTGADM.RC_INV_ROHS_MOVE_SHORT_ENTRIES --RMKTGADM.RC_INV_ROHS_MOVE_SHORT_ENTRIES
                      WHERE STATUS_FLAG = 'Y')
         --      LV_MSG_BODY :=
         --            '<HTML> As part of LRO Load as on <HTML/><b> '|| TO_CHAR (LV_CHL_START_TIME_STAMP, 'DD-MM-YYYY HH:MI:SS AM') ||'</b><HTML> ,not received any<b> ROHS/NROHS movements</b>. <HTML/>' ;
         --
         --      LV_MSG_CONTENT :=
         --            '<HTML>Hello,<br /><br /> Warning Message from <b> '
         --         || SUBSTR (LV_PKG_NAME, 1, 37)
         --         || '</b> Package.
         --        <br/>
         --        <br/>
         --        <font color="red"><b>Warning Message : </b></font> '
         --         || LV_MSG_BODY
         --         || ' <br /><br />
         --        <br /> Thanks '
         --         || CHR (38)
         --         || ' Regards, <br />
         --        Cisco Refresh Support Team
         --      </HTML>';


         LOOP
            --       LV_MSG_CONTENT :=
            --                LV_MSG_CONTENT || '<tr>';


            LV_MSG_TEXT :=
               LV_MSG_TEXT || '<tr> <td>' || REC.TAN_ID || '</td>
                <td>' || REC.PART_NUMBER || '</td>
                <td>' || REC.SITE_CODE || '</td>
                <td>' || REC.ROHS_FLAG || '</td>
                <td>' || REC.SUGGESTED_ADJUSTMENT || '</td>
                <td>' || REC.PROCESSED_ADJUSTMENT || '</td></tr>';
         END LOOP;

         LV_MSG_TEXT :=
               LV_MSG_CONTENT
            || LV_MSG_TEXT
            || ' </table><br>'
            || LV_MSG_CONTENT2;


         CRPADM.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (LV_MAIL_FROM,
                                                              LV_MAIL_TO,
                                                              LV_SUBJECT,
                                                              LV_MSG_TEXT,
                                                              NULL,
                                                              NULL);

         -->> Updating flag after sending mail

         UPDATE RC_INV_ROHS_MOVE_SHORT_ENTRIES
            SET STATUS_FLAG = 'N';

         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         --  ROLLBACK;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'FAILED',
                      SYSDATE,
                      SYSDATE,
                      'RC_INV_ROHS_NROHS_SEND_MAIL',
                      G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_RF');



         COMMIT;
   END RC_INV_ROHS_NROHS_SEND_MAIL;

   /* End Added to send mail to inventory admins when shortage in RoHS/NRoHS adjustments as part of US164572 as on 09-APR-2018 */

   /* Start created new procedure to clear -VE FG on 27th Aug 2018 by sridvasu */

   PROCEDURE RC_INV_NEG_MANUAL_ADJ (P_SITE_CODE IN VARCHAR2)
   AS
      L_START_TIME   DATE;
   BEGIN
      L_START_TIME := SYSDATE;

      G_PROC_NAME := 'RC_INV_NEG_MANUAL_ADJ';

      INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG (INVENTORY_LOG_ID,
                                                  PART_NUMBER,
                                                  NEW_FGI,
                                                  NEW_DGI,
                                                  ROHS_COMPLIANT,
                                                  SITE_CODE,
                                                  PROCESS_STATUS,
                                                  UPDATED_ON,
                                                  UPDATED_BY,
                                                  CREATED_ON,
                                                  CREATED_BY,
                                                  POE_BATCH_ID,
                                                  PROGRAM_TYPE)
         SELECT RC_INV_LOG_PK_SEQ.NEXTVAL,
                Part_number,
                Available_FGI * -1 new_fgi,
                0                  New_DGI,
                Rohs_Compliant,
                Site_Code,
                'N'                Process_Status,
                SYSDATE            updated_on,
                'POEADMIN'         updated_By,
                SYSDATE            created_on,
                'POEADMIN'         Created_By,
                'NEGATIVE INVENTORY MANUAL ADJ',
                DECODE (Inventory_flow,
                        'Excess', 'E',
                        'Retail', 'R',
                        'Outlet', 'O')
           FROM xxcpo_rmk_inventory_master
          WHERE available_fgi < 0;

      INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                             CHL_STATUS,
                                             CHL_START_TIMESTAMP,
                                             CHL_END_TIMESTAMP,
                                             CHL_CRON_NAME,
                                             CHL_COMMENTS,
                                             CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'SUCCESS',
                   L_START_TIME,
                   SYSDATE,
                   'RC_INV_NEG_MANUAL_ADJ',
                   P_SITE_CODE,
                   'RC_INV_DELTA_LOAD_RF');

      COMMIT;

      G_PROC_NAME := 'RC_INV_NEG_MANUAL_ADJ';
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'FAILED',
                      L_START_TIME,
                      SYSDATE,
                      G_PROC_NAME,
                      P_SITE_CODE || '-' || G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_RF');


         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_NEG_MANUAL_ADJ;

   /* End created new procedure to clear -VE FG on 27th Aug 2018 by sridvasu */

   -->> Start Created new procedure for Delta job dependency check on 17-Jan-2019

   PROCEDURE RC_INV_RF_MAIN (P_STATUS_MESSAGE      OUT VARCHAR2,
                             P_SITE_CODE        IN     VARCHAR2)
   IS
      lv_subject         VARCHAR2 (250);
      lv_msg_content     VARCHAR2 (1500);
      lv_database_name   VARCHAR2 (50);
      lv_cron_cnt        NUMBER;
      lv_pkg_name        VARCHAR2 (50) := 'RMKTGADM.RC_INV_DELTA_LOAD_RF';
      lv_msg_body        VARCHAR2 (300);
      l_message          VARCHAR2 (2000);
      l_site_code        VARCHAR2 (10);
   BEGIN
      SELECT SYSDATE INTO G_START_TIME FROM DUAL;

      l_site_code := p_site_code;

      BEGIN
         SELECT COUNT (*)
           INTO lv_cron_cnt
           FROM RMKTGADM.CRON_CONTROL_INFO
          WHERE     1 = 1
                AND CRON_NAME IN ('EX_MAIN', 'RF_MAIN')
                AND CRON_STATUS = 'STARTED';
      EXCEPTION
         WHEN OTHERS
         THEN
            lv_cron_cnt := -1;

            G_PROC_NAME := 'RC_INV_RF_MAIN';

            G_ERROR_MSG :=
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

            RC_INV_RF_SEND_ERROR_EMAIL (G_PROC_NAME, G_ERROR_MSG);

            ROLLBACK;

            INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                   CHL_STATUS,
                                                   CHL_START_TIMESTAMP,
                                                   CHL_END_TIMESTAMP,
                                                   CHL_CRON_NAME,
                                                   CHL_COMMENTS,
                                                   CHL_CREATED_BY)
                 VALUES (SEQ_CHL_ID.NEXTVAL,
                         'EXCEPTION',
                         G_START_TIME,
                         SYSDATE,
                         'RC_INV_RF_MAIN',
                         P_SITE_CODE || ' - ' || G_ERROR_MSG,          --NULL,
                         'RC_INV_DELTA_LOAD_RF');

            COMMIT;
      END;


      IF lv_cron_cnt >= 1
      THEN
         lv_msg_body :=
            'Delta RF/EX package execution is currently in progress. Please wait to run it again.';

         lv_msg_content :=
               '<HTML>Hello,<br /><br /> Warning Message from <b> '
            || lv_pkg_name
            || '</b> Package.
            <br/>
            <br/>
            <font color="red"><b>Warning Message : </b></font> '
            || lv_msg_body
            || ' <br /><br />
            <br /> Thanks '
            || CHR (38)
            || ' Regards, <br />
            Cisco Refresh Support Team               
          </HTML>';

         SELECT ora_database_name INTO lv_database_name FROM DUAL;

         IF (lv_database_name = 'FNTR2PRD.CISCO.COM')
         THEN
            lv_subject :=
               'Warning :  ' || lv_pkg_name || '  package Warning message ';
         ELSIF (lv_database_name = 'FNTR2STG.CISCO.COM')
         THEN
            lv_subject :=
                  'STAGE : '
               || 'Warning :  '
               || lv_pkg_name
               || '  package Warning message ';
         ELSE
            lv_subject :=
                  'DEV : '
               || 'Warning :  '
               || lv_pkg_name
               || '  package Warning message ';
         END IF;

         CRPADM.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (G_ACT_SUPPORT,
                                                              G_TO,
                                                              LV_SUBJECT,
                                                              LV_MSG_CONTENT,
                                                              NULL,
                                                              NULL);
      ELSE
         RF_MAIN (l_message, l_site_code);
      END IF;

      -->> Success entry of the procedure to cron history log

      INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                             CHL_STATUS,
                                             CHL_START_TIMESTAMP,
                                             CHL_END_TIMESTAMP,
                                             CHL_CRON_NAME,
                                             CHL_COMMENTS,
                                             CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'SUCCESS',
                   G_START_TIME,
                   SYSDATE,
                   'RC_INV_RF_MAIN',
                   P_SITE_CODE,                                        --NULL,
                   'RC_INV_DELTA_LOAD_RF');

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;

         G_PROC_NAME := 'RC_INV_RF_MAIN';

         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'FAILED',
                      G_START_TIME,
                      SYSDATE,
                      G_PROC_NAME,
                      P_SITE_CODE || '-' || G_ERROR_MSG,        --G_ERROR_MSG,
                      'RC_INV_RF_MAIN');

         G_PROC_NAME := 'RC_INV_RF_MAIN';

         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_RF_MAIN;
-->> End Created new procedure for Delta job dependency check on 17-Jan-2019

END RC_INV_DELTA_LOAD_RF;
/