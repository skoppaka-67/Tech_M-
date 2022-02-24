CREATE OR REPLACE PACKAGE BODY RMKTGADM."RC_INV_DELTA_LOAD_EX"
IS
   /*===================================================================================================+
   |                                 Cisco Systems, INC., CALIFORNIA                                   |
   +====================================================================================================+
   | Object Name    RC_INV_DELTA_LOAD_EX
   |
   | Module        :
   | Description   :
   |
   | Revision History:
   | -----------------
   | Date         Updated By                           Bug/Case#                  Rev   Comments
   |==========    ================                     ===========                ====  ================================================
   | 23-Jun-2016  mohamms2(Mohammed reyaz Shaik)       ACT                        1.0   Created                                    |
   | 17-Mar-2017  mohamms2(Mohammed Reyaz Shaik)       Apr-17 Release changes     1.1   As part of April 17 Release modified the DGI PUT and GET PROC's for
   |                                                                                     getting reminders at product level.    |
   |20-Mar-2017   mohamms2(Mohammed Reyaz Shaik)       Apr-17 Release Changes     1.2   As part of April17 Release modified the DGI_FGI LOAD Proc for DGI mutiple rows
                                                                                               insert fix |
   |31-Mar-2017   mohamms2(Mohammed Reyaz Shaik)       Apr-17 Release Changes     1.3   As part of April17 Release added the logic to verify the Stage and CG1 quantities adn
                                                                                            to process the FG qty  to CCW  |
   |03-Apr-2017   mohamms2(Mohammed Reyaz Shaik)       Apr-17 Release Changes     1.4   As part of April17 Release added Yield calculation function to get the yield.  |

   |12-May-2017   mohamms2(Mohammed Reyaz Shaik)       May-17 Release Changes     1.6   Control Table for CG1 Exception Quantity

   |07-Jun-2016   mohamms2(Mohammed Reyaz Shaik )      Jul-17 release             1.7   Added parameter to the FGI Extracion Proc             |

   |05-OCT-2017   mohamms2(Mohammed Reyaz Shaik )      US134524                   1.8   PID Deactivation changes - restrict DGI for T-4 PIDs

   |03-NOV-2017  mohamms2(Mohammed Reyaz Shaik )       Sprint16 Release           1.9  C3 table schema changes from RMKTGADM to CRPADM

   |15-JAN-2018  mohamms2(Mohammed Reyaz Shaik )       Sprint#18 Release          2.0  VAVNI schema objects  references changes to CRPADM schema objects.

   |02-APR-2018  sridvasu(Sridevi Vasudevan)           Sprint#19 Release          2.1  As part of US164572 Rohs/NRohs Automation added new procedure and function
   |04-MAY-2018  sridvasu(Sridevi Vasudevan)           Sprint#19 Release          2.2  Added update statement to flag all the records to Y and Summing up the quantity for the PIDs which are having from and to locations are same
  |03-AUG-2018  sridvasu(Sridevi Vasudevan)            Sept Release               2.3  Modified Cursor query in RC_INV_EX_FGI_ROHS_NROHS_MOVE
  |19-JUN-2018  mohamms2(Mohammed Reyaz Shaik)        UserStory#US193034(Sprint#21)  2.4  As part of Yield - Zero percent yield issue
  |24-JUN-2018  mohamms2(Mohammed Reyaz Shaik)        UserStory#US193036(Sprint#21)  2.5  As part of yield calculation ligic changes for considering refresh_yield.
  |15-OCT-2018  sridvasu(Sridevi Vasudevan)           UserStory#US193036(Sprint#21)  2.6  As part of US considering WS locations and not considering common inventory (POE locations)
  |30-OCT-2018  csirigir(Chandra)                     Nov-18 Release Changes         2.7  Added instance name in the subject line for non-prod instances as part of Nov'18 release.
  |09-JAN-2019  sridvasu(Sridevi Vasudevan)                                          2.8  Modified RC_INV_EX_DGI_EXTRACT to refer yield columns from C3 system
  |17-JAN-2019  sridvasu(Sridevi Vasudevan)                                          2.9  Added new procedure RC_INV_EX_MAIN to check delta job dependency
  |01-FEB-2019  sridvasu(Sridevi Vasudevan)                                          3.0  Referring RC_INV_BTS_C3_MV instead of RC_INV_C3_TBL table for C3 inventory
  |04-FEB-2019  sridvasu(Sridevi Vasudevan)                                          3.1  Modified Reminder logic for Negative DGI
  |27-FEB-2019  sridvasu(Sridevi Vasudevan)                                          3.2  Modified DGI Extract procedure to restrict Z32
  |11-MAY-2020  sneyadav(Snehalata Yadav)              US390864                      3.3  Modified FVE FC01 feed processing
  |06-JUN-2020  sumravik(Sumesh Ravikumar)             US390864                      3.3  Added Mail notification for FVE FC01 feed processing
  |03-JUL-2020 sumravik(Sumesh Ravikumar)              US438804                      3.6  Commented the existing mail notification code present in RC_INV_EX_DGI_LOAD,RC_INV_EX_FGI_LOAD
  |08-JUL-2020 sumravik(Sumesh Ravikumar)              US438804                      3.7  Added insert statement to add data into RC_INV_DG_Values in RC_INV_EX_DGI_LOAD and added statements to call RC_INV_FG_DG_EMAIL_PKG IN EX_MAIN PROC
  |08-JUL-2020 sneyadav(Snehalata Yadav)               US198778                      3.8  Added SONS DGI delta calculation for US198778
  |18-Sep-2020 sumravik(Sumesh ravikumar)                                            3.8  Added site code as 'GDGI' while calling DG report
  ==================================================================================================*/

   G_STEP            VARCHAR2 (100);
   G_FETCH_LIMIT     NUMBER;
   G_UPDATED_BY      VARCHAR2 (100);
   G_TO              VARCHAR2 (200) := 'refreshcentral-support@cisco.com';
   G_ERROR_MSG       VARCHAR2 (300);
   G_PROC_NAME       VARCHAR2 (100);
   G_START_TIME      DATE;
   G_ACT_SUPPORT     VARCHAR2 (100) := 'refreshcentral-support@cisco.com';
   G_RHS_NRHS_FLAG   VARCHAR2 (10) := 'Y';
   v_message         VARCHAR2 (32767);

   PROCEDURE EX_MAIN (P_STATUS_MESSAGE OUT VARCHAR2, P_SITE_CODE IN VARCHAR2)
   IS
      L_PROCESS_ID                VARCHAR2 (100);
      L_START_TIME                DATE;
      L_END_TIME                  DATE;
      L_INTRANSIT_FLAG            VARCHAR2 (10) := 'N';
      L_DELTA_PREV_EXE_TIME       TIMESTAMP;
      L_UNPRO_CNT                 NUMBER;
      L_LRO_UNPRO_CNT             NUMBER;
      L_PROCEDURE_NAME            VARCHAR2 (300);
      L_WARNING_MSG               VARCHAR2 (800);
      --L_CONS_REM_DELTA_LAST_EXE_TIME   TIMESTAMP;
      L_LAST_CONS_REMIN           NUMBER (10, 8);
      L_C3_RECORD_COUNT           NUMBER;
      L_FGI_RECORD_COUNT          NUMBER;
      L_C3_MIN_REC_COUNT          NUMBER := 1000;
      L_LRO_CG1_QUANTITY          NUMBER; -- Added as part of Apr17 Sprint Release
      L_LRO_FGI_QUANTITY          NUMBER; -- Added as part of Apr17 Sprint Release
      L_FVE_FGI_QUANTITY          NUMBER; -- Added as part of Apr17 Sprint Release
      L_LRO_CG1_EXCEPTION_QTY     NUMBER; -- Added as part of May-17 sprint Release
      L_FVE_CG1_QUANTITY          NUMBER;         -- Added as part of US390864
      L_FVE_REC_QUANTITY          NUMBER;         -- Added as part of US390864
      L_LRO_FGI_FEED_COUNT        NUMBER;
      L_LRO_RHS_NRHS_COUNT        NUMBER;
      L_LRO_HOLD_TIME             DATE;
      lv_rohs_feed_date           DATE;
      lv_lro_process_date         DATE;
      lv_prev_rohs_process_date   DATE;
      LV_RHS_NRHS_PR_FLAG         VARCHAR2 (3);
      L_CG1_START_DATE            NUMBER;         -- Added as part of US390864
      L_CG1_END_DATE              NUMBER;         -- Added as part of US390864
      V_LAST_RECORD_DATE          DATE;
   BEGIN
      G_PROC_NAME := 'RMKTGADM.RC_INV_DELTA_LOAD_EX.EX_MAIN';

      IF P_SITE_CODE = 'GDGI'
      THEN
         --POE process logic
         RC_MAIN;
      END IF;

      -- get the process start time
      SELECT SYSDATE INTO G_START_TIME FROM DUAL;

      -->> Start Added update statement to cron control info table for delta job dependency checks on 17-Jan-2019

      UPDATE RMKTGADM.CRON_CONTROL_INFO
         SET CRON_START_TIMESTAMP = G_START_TIME,
             CRON_END_TIMESTAMP = SYSDATE,
             CRON_STATUS = 'STARTED'
       WHERE     CRON_NAME = 'EX_MAIN'
             AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'EX_MAIN';

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
          WHERE     CRON_NAME = 'EX_MAIN'
                AND CRON_STATUS = 'SUCCESS'
                AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'EX_MAIN';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            SELECT MAX (CHL_END_TIMESTAMP)
              INTO L_DELTA_PREV_EXE_TIME
              FROM RMKTGADM.CRON_HISTORY_LOG
             WHERE CHL_CRON_NAME = 'EX_MAIN' AND CHL_STATUS = 'SUCCESS';
      END;

      --      --get the last successful execution time of CONS_RMINDRS_DELTA_DGI_PROC
      --      SELECT NVL (MAX (CHL_START_TIMESTAMP), SYSDATE - 2) -- NVL to handle the first time load
      --        INTO L_CONS_REM_DELTA_LAST_EXE_TIME
      --        FROM RMKTGADM.CRON_HISTORY_LOG
      --       WHERE     CHL_CRON_NAME = 'RC_INV_EX_DGI_GET_REMINDERS'
      --             AND CHL_STATUS = 'SUCCESS';


      -->> Check for the DG Inventory Availability
      SELECT COUNT (1)
        INTO L_C3_RECORD_COUNT
        --        FROM CRPADM.RC_INV_C3_TBL  --VAVNI_CISCO_RSCM_TEMP.RSCM_TMP_C3_INV_TBL
        FROM CRPADM.RC_INV_BTS_C3_MV -- Added on 01-FEB-2019 to refer RC_INV_BTS_C3_MV instead of RC_INV_C3_TBL table for C3 inventory
       WHERE -- PART_ID LIKE '%WS' -- Commented on 01-FEB-2019 since we have mfg and service parts
            LOCATION LIKE 'WS%' -- Added on 01-FEB-2019 to look only for WS locations
             AND SITE NOT LIKE 'Z32%' -->> Added to restrict Z32 data on 27-FEB-2019
             AND PART_NUMBER NOT IN (SELECT REFRESH_PART_NUMBER
                                       FROM RC_INV_EXCLUDE_PIDS);

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
                                     ) HIST -- added 'CSC%' condition on 25-Jun-17 --commented as part of US390864
             INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                ON (    HIST.REFRESH_PART_NUMBER = PM.REFRESH_PART_NUMBER
                    AND PM.PROGRAM_TYPE = 1) --  To check for the presence on Excess Invenotry Only.
       WHERE     HIST.PROCESSED_STATUS = 'N'
             AND HIST.HUB_LOCATION = P_SITE_CODE
             AND HIST.REFRESH_PART_NUMBER NOT IN (SELECT REFRESH_PART_NUMBER
                                                    FROM RC_INV_EXCLUDE_PIDS);


      /*** Start Added as part of Apr-17 Sprint Release***/

      IF P_SITE_CODE = 'LRO'
      THEN
         SELECT NVL (SUM ( /*DECODE (HD.MESSAGE_TYPE,
                                   'R2AS', */
                          LN.PO_RECEIVED_QTY /*,      --changed as part of US390864
                 'SRTV', LN.PO_REQUIRED_QTY)*/
                                            ), 0)
           INTO L_LRO_CG1_QUANTITY
           FROM XXSCM.XXSCM_MK_4B2_LN_IB_IFACE@CG1PRD.CISCO.COM LN
                INNER JOIN
                XXSCM.XXSCM_MK_4B2_HDR_IB_IFACE@CG1PRD.CISCO.COM HD
                   ON (LN.MESSAGE_ID = HD.MESSAGE_ID)
                INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                   ON (LN.END_USER_PRODUCT_ID = PM.TAN_ID) -- AND PM.PROGRAM_TYPE = 1)
          WHERE     1 = 1
                AND PM.PROGRAM_TYPE = 1
                AND LN.MESSAGE_ID LIKE 'LRO%'
                AND TRUNC (LN.CREATION_DATE)   BETWEEN   --  '05-APR-2021'  AND '07-APR-2021'
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
                                                                    '%WS')
                                                 AND TRUNC (SYSDATE - 1)  
                AND HD.MESSAGE_TYPE IN ('R2AS'                    /*, 'SRTV'*/
                                              ) --commented as part of US390864
                AND END_USER_PRODUCT_ID IN (SELECT TAN_ID
                                              FROM CRPADM.RC_PRODUCT_MASTER);

         --        SELECT NVL(SUM (decode( HD.MESSAGE_TYPE, 'R2AS', LN.PO_RECEIVED_QTY , 'SRTV' , LN.PO_REQUIRED_QTY ) ), 0 )
         --          INTO L_LRO_CG1_QUANTITY
         --          FROM XXSCM.XXSCM_MK_4B2_LN_IB_IFACE@TS1CG1.CISCO.COM LN  --DV1CG1.CISCO.COM LN -- CG1PRD.CISCO.COM LN
         --              INNER JOIN XXSCM.XXSCM_MK_4B2_HDR_IB_IFACE@TS1CG1.CISCO.COM HD-- DV1CG1.CISCO.COM HD -- CG1PRD.CISCO.COM HD
         --                 ON (LN.MESSAGE_ID = HD.MESSAGE_ID)
         --              INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
         --                 ON (LN.END_USER_PRODUCT_ID = PM.TAN_ID)-- AND PM.PROGRAM_TYPE = 1)
         --        WHERE     1 = 1
         --              AND PM.PROGRAM_TYPE = 1
         --              AND LN.MESSAGE_ID LIKE 'LRO%'
         --              AND TRUNC (LN.CREATION_DATE) BETWEEN '07-OCT-2016' and '07-OCT-2016'
         ----              (   select max(trunc(record_created_on)) from CRPSC.SC_FC01_OH_DELTA_LRO_HIST
         ----                            where processed_status = 'Y'
         ----                            and REFRESH_PART_NUMBER NOT IN (SELECT REFRESH_PART_NUMBER FROM RC_INV_EXCLUDE_PIDS)
         ----                            and REFRESH_PART_NUMBER like '%WS'
         ----              )  AND trunc(SYSDATE - 1 )
         --              AND HD.MESSAGE_TYPE IN ('R2AS','SRTV')
         --              AND END_USER_PRODUCT_ID IN (SELECT TAN_ID
         --                                                 FROM CRPADM.RC_PRODUCT_MASTER
         --                                                WHERE REFRESH_PART_NUMBER NOT IN (SELECT REFRESH_PART_NUMBER
         --                                                                                    FROM RC_INV_EXCLUDE_PIDS));

         /*** End Added as part of Apr-17 Sprint Release***/


         /*** Start Added as part of Apr-17 Sprint Release***/
         SELECT NVL (SUM (RECEIVED_QTY), 0)
           INTO L_LRO_FGI_QUANTITY
           FROM CRPSC.SC_FC01_OH_DELTA_LRO_HIST HIST
          WHERE     HIST.PROCESSED_STATUS = 'N'
                AND HIST.RECEIVED_QTY > 0
                AND HIST.REFRESH_PART_NUMBER LIKE '%WS'
                --         AND TRUNC (RCT_CREATION_DATE) >=
                --                           (SELECT TRUNC (CRON_END_TIMESTAMP)
                --                              FROM RMKTGADM.CRON_CONTROL_INFO
                --                             WHERE CRON_NAME = 'RF_MAIN'
                --                               AND CRON_STATUS = 'SUCCESS')
                AND HIST.REFRESH_PART_NUMBER NOT IN
                       (SELECT REFRESH_PART_NUMBER
                          FROM RC_INV_EXCLUDE_PIDS);
      /*** End Added as part of Apr-17 Sprint Release***/
      END IF;

      /*** Start Added as part of US390864***/
      IF P_SITE_CODE = 'FVE'
      THEN
         --         SELECT NVL (SUM (LN.PO_RECEIVED_QTY), 0)
         --           INTO L_FVE_CG1_QUANTITY
         --           FROM XXSCM.XXSCM_MK_4B2_LN_IB_IFACE@CG1PRD.CISCO.COM LN
         --                INNER JOIN
         --                XXSCM.XXSCM_MK_4B2_HDR_IB_IFACE@CG1PRD.CISCO.COM HD
         --                   ON (LN.MESSAGE_ID = HD.MESSAGE_ID)
         --                INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
         --                   ON (LN.END_USER_PRODUCT_ID = PM.TAN_ID)
         --          WHERE     1 = 1
         --                AND PM.PROGRAM_TYPE = 1
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
         --                                                                    '%WS')
         --                                                 AND TRUNC (SYSDATE - 1)
         --                AND HD.MESSAGE_TYPE IN ('R2AS')
         --                AND END_USER_PRODUCT_ID IN
         --                       (SELECT TAN_ID
         --                          FROM CRPADM.RC_PRODUCT_MASTER
         --                         WHERE REFRESH_PART_NUMBER NOT IN
         --                                  (SELECT REFRESH_PART_NUMBER
         --                                     FROM RC_INV_EXCLUDE_PIDS));

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
          WHERE     PM.PROGRAM_TYPE = 1
                AND message_id LIKE 'FVE%'
                AND creation_date >=
                       (SELECT dat + L_CG1_START_DATE / 24
                          FROM (SELECT TRUNC (SYSDATE - 1) dat FROM DUAL))
                AND CREATION_DATE <=
                       (SELECT dat + L_CG1_END_DATE / 24
                          FROM (SELECT TRUNC (SYSDATE) dat FROM DUAL))
                AND END_USER_PRODUCT_ID LIKE '74%'
                AND PO_NUMBER LIKE 'CSC%';

         SELECT NVL (SUM (RECEIVED_QTY), 0)
           INTO L_FVE_REC_QUANTITY
           FROM CRPSC.RC_FC01_OH_DELTA_FVE_HIST HIST
          WHERE     HIST.PROCESSED_STATUS = 'N'
                AND HIST.RECEIVED_QTY > 0
                AND HIST.REFRESH_PART_NUMBER LIKE '%WS'
                AND HIST.REFRESH_PART_NUMBER NOT IN
                       (SELECT REFRESH_PART_NUMBER
                          FROM RC_INV_EXCLUDE_PIDS);
      /*** End Added as part of US390864***/
      END IF;

      /*** Commented as part of US390864***/
      /*** Start Added as part of Apr-17 Sprint Release***/

      --      SELECT NVL (SUM (RECEIVED_QTY), 0)
      --        INTO L_FVE_FGI_QUANTITY
      --        FROM CRPSC.SC_FB02_DELTA_FVE_HIST HIST
      --       WHERE     HIST.PROCESSED_STATUS = 'N'
      --             AND HIST.RECEIVED_QTY > 0
      --             AND HIST.PO_NUMBER LIKE 'CSC%'     ---Added conditon on 25-Jun-17
      --             AND HIST.REFRESH_PART_NUMBER LIKE '%WS'
      --             --            AND TRUNC (RECORD_CREATED_ON) >=
      --             --                           (SELECT TRUNC (CRON_END_TIMESTAMP)
      --             --                              FROM RMKTGADM.CRON_CONTROL_INFO
      --             --                             WHERE CRON_NAME = 'RF_MAIN'
      --             --                               AND CRON_STATUS = 'SUCCESS')
      --             AND HIST.REFRESH_PART_NUMBER NOT IN (SELECT REFRESH_PART_NUMBER
      --                                                    FROM RC_INV_EXCLUDE_PIDS);

      /*** End Added as part of Apr-17 Sprint Release***/

      /***   Start Added As part of May-17 Sprint Release LRO CG1 Exception Qty           ***/

      SELECT RC_INV_CONTROL_VALUE
        INTO L_LRO_CG1_EXCEPTION_QTY
        FROM RC_INV_CONTROL
       WHERE RC_INV_CONTROL_ID = 9; -- ( 9 = LRO CG1 EXCEPTION QTY) --RC_INV_CONTROL_NAME = 'LRO CG1 EXCEPTION QTY'; --commented as part of sprint14(Aug Release)and added RC_INV_CONTROL_ID


      /***   End Added As part of May-17 Sprint Release LRO CG1 Exception Qty           ***/

      /*Inventory Frequency increase changes start*/
      SELECT COUNT (*)
        INTO L_LRO_FGI_FEED_COUNT
        FROM CRPSC.SC_FC01_OH_DELTA_LRO_HIST HIST
       WHERE     HIST.PROCESSED_STATUS = 'N'
             AND HIST.RECEIVED_QTY > 0
             AND HIST.REFRESH_PART_NUMBER LIKE '%WS'
             AND HIST.REFRESH_PART_NUMBER NOT IN (SELECT REFRESH_PART_NUMBER
                                                    FROM RC_INV_EXCLUDE_PIDS);

      SELECT COUNT (*)
        INTO L_LRO_RHS_NRHS_COUNT
        FROM CRPSC.RC_DLP_ROHS_NONROHS MV
             INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                ON (MV.PART_NO = PM.TAN_ID)
       WHERE REFRESH_PART_NUMBER LIKE '%WS' AND PROCESSED_FLAG = 'N';

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


      SELECT TO_DATE (
                   TO_CHAR (TO_CHAR (TRUNC (SYSDATE), 'mm/dd/yyyy'))
                || ' '
                || TO_CHAR ('07:00:00'),
                'mm/dd/yyyy hh24:mi:ss')
        INTO L_LRO_HOLD_TIME
        FROM DUAL;

      --        SELECT CRON_START_TIMESTAMP + 4 / 24
      --          INTO L_LRO_HOLD_TIME
      --          FROM RMKTGADM.CRON_CONTROL_INFO
      --         WHERE     CRON_NAME = 'RC_INV_EX_FGI_EXTRACT'
      --               AND CRON_CONTACT_ID = 'LRO-EX_MAIN'
      --               AND CRON_STATUS = 'SUCCESS';

      SELECT MAX (CREATED_ON)
        INTO lv_rohs_feed_date
        FROM CRPSC.RC_DLP_ROHS_NONROHS
       WHERE PROCESSED_FLAG = 'N';

      SELECT CRON_END_TIMESTAMP
        INTO lv_lro_process_date
        FROM RMKTGADM.CRON_CONTROL_INFO
       WHERE     CRON_NAME = 'RC_INV_EX_FGI_EXTRACT'
             AND CRON_CONTACT_ID = 'LRO-EX_MAIN'
             AND CRON_STATUS = 'SUCCESS';

      SELECT MAX (CREATED_ON)
        INTO lv_prev_rohs_process_date
        FROM RMK_INVENTORY_LOG_STG
       WHERE POE_BATCH_ID = 'RC_INV_RF_FGI_ROHS_NROHS_MOVE';

      /*Inventory Frequency increase changes end*/
      --Start Added as part of US198778 for updating SONS order pending and received qty
      IF P_SITE_CODE = 'GDGI'
      THEN
         RC_SONS_DATA_UPDATE;
      END IF;

      SELECT MAX (TRUNC (RECORD_CREATED_ON))
        INTO V_LAST_RECORD_DATE
        FROM CRPSC.SC_FC01_OH_DELTA_LRO_HIST
       WHERE PROCESSED_STATUS = 'Y';

      IF P_SITE_CODE = 'LRO'
      THEN
         INSERT INTO RC_INV_CG1_VALUES (END_USER_PRODUCT_ID, RECEIVED_QTY)
            (  SELECT end_user_product_id, SUM (po_received_qty)
                 FROM XXSCM.XXSCM_MK_4B2_LN_IB_IFACE@CG1PRD.CISCO.COM LN
                      INNER JOIN
                      XXSCM.XXSCM_MK_4B2_HDR_IB_IFACE@CG1PRD.CISCO.COM HD
                         ON (LN.MESSAGE_ID = HD.MESSAGE_ID)
                WHERE     1 = 1
                      AND LN.MESSAGE_ID LIKE 'LRO%'
                      AND TRUNC (LN.CREATION_DATE) BETWEEN V_LAST_RECORD_DATE
                                                       AND TRUNC (SYSDATE - 1)
                      AND HD.MESSAGE_TYPE IN ('R2AS')
                      AND END_USER_PRODUCT_ID IN
                             (SELECT TAN_ID
                                FROM CRPADM.RC_PRODUCT_MASTER)
             GROUP BY end_user_product_id);

         COMMIT;
      ELSIF P_SITE_CODE = 'FVE'
      THEN
         INSERT INTO RC_INV_CG1_VALUES (END_USER_PRODUCT_ID, RECEIVED_QTY)
            (  SELECT end_user_product_id, SUM (po_received_qty)
                 FROM XXSCM.XXSCM_MK_4B2_LN_IB_IFACE@CG1PRD.CISCO.COM LN
                      INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                         ON (LN.END_USER_PRODUCT_ID = PM.TAN_ID)
                WHERE     message_id LIKE 'FVE%'
                      AND creation_date >=
                             (SELECT dat + L_CG1_START_DATE / 24
                                FROM (SELECT TRUNC (SYSDATE - 1) dat FROM DUAL))
                      AND CREATION_DATE <=
                             (SELECT dat + L_CG1_END_DATE / 24
                                FROM (SELECT TRUNC (SYSDATE) dat FROM DUAL))
                      AND END_USER_PRODUCT_ID LIKE '74%'
                      AND PO_NUMBER LIKE 'CSC%'
             GROUP BY end_user_product_id);

         COMMIT;
      END IF;

      --End Added as part of US198778

      /*-----------------------------------------------------------------------------------------*/

      -- IF     IF L_C3_RECORD_COUNT > 0 AND (L_FGI_RECORD_COUNT < = L_CGI_RECORD_COUNT+20)

      IF /* L_C3_RECORD_COUNT > 0        --commented as part of US390864
      AND */
        L_FGI_RECORD_COUNT < 7000
        AND (   (P_SITE_CODE = 'FVE' AND L_FVE_REC_QUANTITY > 0) --L_FVE_FGI_QUANTITY > 0     --commented as part of US390864
              OR (    P_SITE_CODE = 'LRO'
                  AND L_LRO_FGI_QUANTITY > 0
                  AND L_LRO_FGI_QUANTITY <=
                         L_LRO_CG1_QUANTITY + L_LRO_CG1_EXCEPTION_QTY))
      THEN
         -- DGI
         /* RC_INV_EX_DGI_EXTRACT (L_INTRANSIT_FLAG, P_SITE_CODE);
          RC_INV_EX_DGI_HISTORY (P_SITE_CODE);
          RC_INV_EX_DGI_DELTA (P_SITE_CODE);
          RC_INV_EX_DGI_PUT_REMINDERS;
          RC_INV_EX_DGI_GET_REMINDERS;*/
         --commented as part of US390864
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
            RC_INV_EX_SEND_ERROR_EMAIL (G_PROC_NAME, G_ERROR_MSG);
         END IF;

         IF (   P_SITE_CODE = 'FVE'
             OR (    P_SITE_CODE = 'LRO'
                 AND L_LRO_FGI_FEED_COUNT > 0
                 AND (L_LRO_RHS_NRHS_COUNT > 0 OR LV_RHS_NRHS_PR_FLAG = 'Y')))
         THEN
            RC_INV_EX_FGI_EXTRACT (P_SITE_CODE);
            RC_INV_EX_FGI_LOAD (P_SITE_CODE);
         ELSIF (    P_SITE_CODE = 'LRO'
                AND L_LRO_FGI_FEED_COUNT > 0
                AND L_LRO_RHS_NRHS_COUNT = 0
                AND LV_RHS_NRHS_PR_FLAG = 'N')
         THEN
            IF SYSDATE >= L_LRO_HOLD_TIME
            THEN
               G_RHS_NRHS_FLAG := 'N';
               RC_INV_EX_FGI_EXTRACT (P_SITE_CODE);
               RC_INV_EX_FGI_LOAD (P_SITE_CODE);
            /* ELSE
                G_RHS_NRHS_FLAG := 'N';
                RC_INV_EX_DGI_FGI_LOAD (P_SITE_CODE);*/
            --commented as part of US390864
            END IF;
         END IF;
      ELSIF /*L_C3_RECORD_COUNT > 0     --commented as part of US390864
        AND*/
            (      L_LRO_FGI_QUANTITY >
                      L_LRO_CG1_QUANTITY + L_LRO_CG1_EXCEPTION_QTY
                OR L_FGI_RECORD_COUNT > 7000)
            AND P_SITE_CODE = 'LRO'
      THEN
         /* RC_INV_EX_DGI_EXTRACT (L_INTRANSIT_FLAG, P_SITE_CODE);
          RC_INV_EX_DGI_HISTORY (P_SITE_CODE);
          RC_INV_EX_DGI_DELTA (P_SITE_CODE);
          RC_INV_EX_DGI_PUT_REMINDERS;
          RC_INV_EX_DGI_GET_REMINDERS;

          G_RHS_NRHS_FLAG := 'N'; ---RHS/NRHS feed cannot be processed without LRO feed.
          RC_INV_EX_DGI_FGI_LOAD (P_SITE_CODE);  */
         --commented as part of US390864

         -->> updating non-matched recs to E

         UPDATE CRPSC.SC_FC01_OH_DELTA_LRO_HIST
            SET PROCESSED_STATUS = 'E'
          WHERE     PROCESSED_STATUS = 'N'
                AND REFRESH_PART_NUMBER LIKE '%WS'
                AND REFRESH_PART_NUMBER NOT IN (SELECT REFRESH_PART_NUMBER
                                                  FROM RC_INV_EXCLUDE_PIDS);

         -- AND TRUNC (RECORD_UPDATED_ON) = TRUNC (SYSDATE);

         COMMIT;

         --send warning mail to support team
         --            L_PROCEDURE_NAME := 'RMKTGADM.RC_INV_DELTA_LOAD_EX.EX_MAIN';

         G_ERROR_MSG :=
               '<HTML>LRO FGI Quantity is more than the LRO CG1 Quantity: 
                <br/> <br/>
                <b>LRO FGI Quantity :</b>
                 <HTML/>'
            || L_LRO_FGI_QUANTITY
            || '<HTML> <br/><b>LRO CG1 Quantity :</b> <HTML/>'
            || L_LRO_CG1_QUANTITY;

         RC_INV_EX_SEND_ERROR_EMAIL (G_PROC_NAME, G_ERROR_MSG);
      --            RAISE_APPLICATION_ERROR (-20000, SQLERRM);
      /*ELSIF     (   (L_FVE_REC_QUANTITY >
                        L_FVE_CG1_QUANTITY + L_LRO_CG1_EXCEPTION_QTY)
                 OR L_FGI_RECORD_COUNT > 7000)
            AND P_SITE_CODE = 'FVE'
      THEN
         --updating non-matched recs to E

         UPDATE CRPSC.RC_FC01_OH_DELTA_FVE_HIST
            SET PROCESSED_STATUS = 'E'
          WHERE     PROCESSED_STATUS = 'N'
                AND REFRESH_PART_NUMBER LIKE '%WS'
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
         RC_INV_EX_SEND_ERROR_EMAIL (G_PROC_NAME, G_ERROR_MSG);
      /*** End Added as part of US390864***/

      ELSIF L_C3_RECORD_COUNT > 0 AND P_SITE_CODE = 'GDGI' --AND L_FGI_RECORD_COUNT = 0   --commented as part of US390864
      THEN
         -- DGI
         RC_INV_EX_DGI_EXTRACT (L_INTRANSIT_FLAG, P_SITE_CODE);
         RC_INV_EX_DGI_HISTORY (P_SITE_CODE);
         RC_INV_EX_DGI_DELTA (P_SITE_CODE);
         RC_INV_EX_DGI_PUT_REMINDERS;

         --         RC_INV_EX_DGI_GET_REMINDERS;

         IF     lv_prev_rohs_process_date < lv_lro_process_date
            AND (   TRUNC (lv_rohs_feed_date) = TRUNC (lv_lro_process_date)
                 OR LV_RHS_NRHS_PR_FLAG = 'Y')
         THEN
            RC_INV_EX_DGI_LOAD (P_SITE_CODE);
         ELSE
            G_RHS_NRHS_FLAG := 'N'; ---RHS/NRHS feed cannot be processed without LRO feed.
            RC_INV_EX_DGI_LOAD (P_SITE_CODE);
         END IF;

         --send warning mail to support team
         L_PROCEDURE_NAME :=
               'RMKTGADM.RC_INV_DELTA_LOAD_EX.EX_MAIN '
            || P_SITE_CODE
            || '-FG Inventory not received,';
         L_WARNING_MSG :=
               'POE has not received the EXCESS Detla FGI feed from <b> BTS '
            || P_SITE_CODE
            || ' </b>  Node, Since <b>'
            || TO_CHAR (L_DELTA_PREV_EXE_TIME, 'DD-Mon-YYYY HH:MI:SS PM')
            || '</b>';
      --   RC_INV_EX_SEND_WARNING_EMAIL (L_PROCEDURE_NAME, L_WARNING_MSG);  --commented as part of Sprint14 release (Handling alert mechanism in scheduled ETL itself)

      ELSIF L_C3_RECORD_COUNT = 0 AND P_SITE_CODE = 'GDGI'
      /*AND L_FGI_RECORD_COUNT < 7000
      AND (   L_FVE_FGI_QUANTITY > 0
           OR (    L_LRO_FGI_QUANTITY > 0
               AND L_LRO_FGI_QUANTITY <=
                      L_LRO_CG1_QUANTITY + L_LRO_CG1_EXCEPTION_QTY))*/
      --commented as part of US390864
      THEN
         -- FGI
         /* IF (   P_SITE_CODE = 'FVE'
              OR (    P_SITE_CODE = 'LRO'
                  AND L_LRO_FGI_FEED_COUNT > 0
                  AND (L_LRO_RHS_NRHS_COUNT > 0
                  OR LV_RHS_NRHS_PR_FLAG='Y')))
          THEN
             RC_INV_EX_FGI_EXTRACT (P_SITE_CODE);
             RC_INV_EX_DGI_FGI_LOAD (P_SITE_CODE);
          ELSIF (    P_SITE_CODE = 'LRO'
                 AND L_LRO_FGI_FEED_COUNT > 0
                 AND L_LRO_RHS_NRHS_COUNT = 0
                 AND  LV_RHS_NRHS_PR_FLAG='N')
          THEN
             IF SYSDATE >= L_LRO_HOLD_TIME
             THEN
                G_RHS_NRHS_FLAG := 'N';
                RC_INV_EX_FGI_EXTRACT (P_SITE_CODE);
                RC_INV_EX_DGI_FGI_LOAD (P_SITE_CODE);
             END IF;
          END IF;*/
         --commented as part of US390864

         --send warning mail to support team
         L_PROCEDURE_NAME := 'RMKTGADM.RC_INV_DELTA_LOAD_EX.EX_MAIN';
         L_WARNING_MSG :=
               'POE has not received the EXCESS Detla DGI feed from C3 system, Since '
            || TO_CHAR (L_DELTA_PREV_EXE_TIME, 'DD-Mon-YYYY HH:MI:SS PM');
         RC_INV_EX_SEND_WARNING_EMAIL (L_PROCEDURE_NAME, L_WARNING_MSG);
      ELSIF L_C3_RECORD_COUNT = 0 AND L_FGI_RECORD_COUNT = 0
      THEN
         G_ERROR_MSG :=
            '<b>POE</b> has not received data from <b>BTS</b> and <b>C3 Inventory</b>  to Prcocess for <b> CCW Delta</b> Feed ';

         --           INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
         --                                                  CHL_STATUS,
         --                                                  CHL_START_TIMESTAMP,
         --                                                  CHL_END_TIMESTAMP,
         --                                                  CHL_CRON_NAME,
         --                                                  CHL_COMMENTS,
         --                                                  CHL_CREATED_BY)
         --                VALUES (SEQ_CHL_ID.NEXTVAL,
         --                        'FAILED',
         --                        G_START_TIME,
         --                        SYSDATE,
         --                        'EX_MAIN',
         --                        G_ERROR_MSG,
         --                        'RC_INV_DELTA_LOAD_EX');
         --
         --           UPDATE RMKTGADM.CRON_CONTROL_INFO
         --              SET CRON_END_TIMESTAMP = SYSDATE,
         --                  CRON_STATUS = 'FAILED'
         --            WHERE CRON_NAME = 'EX_MAIN'
         --                  AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'EX_MAIN';

         RC_INV_EX_SEND_ERROR_EMAIL (G_PROC_NAME, G_ERROR_MSG);
      --           ROLLBACK; commented 28-Jun-17

      --      ELSIF L_FGI_RECORD_COUNT = 0
      --      THEN
      --         IF     lv_prev_rohs_process_date < lv_lro_process_date
      --            AND (TRUNC (lv_rohs_feed_date) = TRUNC (lv_lro_process_date) OR LV_RHS_NRHS_PR_FLAG='Y')
      --            AND P_SITE_CODE = 'LRO'
      --         THEN
      --            RC_INV_EX_DGI_FGI_LOAD (P_SITE_CODE);
      --         END IF;
      END IF;

      -->> Start commented below update statement and place after execution of RC_INV_EX_EOS_PID_QTY_REVOKE on 17-Jan-2019

      --      UPDATE RMKTGADM.CRON_CONTROL_INFO
      --         SET CRON_START_TIMESTAMP = G_START_TIME,
      --             CRON_END_TIMESTAMP = SYSDATE,
      --             CRON_STATUS = 'SUCCESS'
      --       WHERE     CRON_NAME = 'EX_MAIN'
      --             AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'EX_MAIN';

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
                   'EX_MAIN',
                   P_SITE_CODE,                                        --NULL,
                   'RC_INV_DELTA_LOAD_EX');

      -- adhoc script to negate available to reserve dgi for T-4 pids (End of Support in next 4 months)
      RC_INV_EX_EOS_PID_QTY_REVOKE; -- added by mohamms2 as on 05-OCT-2017 for User Story US134524 in Sprint 15

      -->> Start added update statement after execution of RC_INV_EX_EOS_PID_QTY_REVOKE on 17-Jan-2019

      UPDATE RMKTGADM.CRON_CONTROL_INFO
         SET CRON_START_TIMESTAMP = G_START_TIME,
             CRON_END_TIMESTAMP = SYSDATE,
             CRON_STATUS = 'SUCCESS'
       WHERE     CRON_NAME = 'EX_MAIN'
             AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'EX_MAIN';

      -->> End added update statement after execution of RC_INV_EX_EOS_PID_QTY_REVOKE on 17-Jan-2019

      COMMIT;
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
         --                      'EX_MAIN',
         --                      G_ERROR_MSG,
         --                      'RC_INV_DELTA_LOAD_EX');
         --
         --         UPDATE RMKTGADM.CRON_CONTROL_INFO
         --            SET CRON_END_TIMESTAMP = SYSDATE, CRON_STATUS = 'FAILED'
         --          WHERE CRON_NAME = 'EX_MAIN';

         --End Commented as on 20-Jun-17

         RC_INV_EX_SEND_ERROR_EMAIL (G_PROC_NAME, G_ERROR_MSG);

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
                      'EX_MAIN',
                      P_SITE_CODE || '-' || G_ERROR_MSG,       -- G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_EX');

         UPDATE RMKTGADM.CRON_CONTROL_INFO
            SET CRON_START_TIMESTAMP = G_START_TIME,
                CRON_END_TIMESTAMP = SYSDATE,
                CRON_STATUS = 'FAILED'
          WHERE     CRON_NAME = 'EX_MAIN'
                AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'EX_MAIN';

         COMMIT;

         ---End added on 20-Jun-17

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END EX_MAIN;


   PROCEDURE RC_INV_EX_DGI_EXTRACT (P_INTRANS_FLAG      VARCHAR2 DEFAULT 'N',
                                    P_SITE_CODE      IN VARCHAR2)
   IS
      LV_TOTAL_QTY   NUMBER;
      L_START_TIME   DATE;
   BEGIN
      G_PROC_NAME := 'RC_INV_EX_DGI_EXTRACT';

      -->>

      L_START_TIME := SYSDATE;

      -- update the cron info

      -- UPDATE RMKTGADM.CRON_HISTORY_LOG
      --      SET CHL_START_TIMESTAMP = SYSDATE, CHL_STATUS = 'STARTED'
      --    WHERE CHL_CRON_NAME = 'RC_INV_EX_DGI_EXTRACT';


      DELETE FROM RMKTGADM.RC_INV_DGI_STG
            WHERE PRODUCT_TYPE = 'E' AND SOURCE_SYSTEM != 'POE'; --Added this condition part of US398932 by Satyredd on 11th Aug 2020

      COMMIT;

      -- Load the nettable c3 inventory data into stage
      -- along with the other support info like refurbish method, yield and Rohs flag
      -- Commented as part of US198778
      --      INSERT INTO RMKTGADM.RC_INV_DGI_STG (PART_ID,
      --                                           PRD_FAMILY,
      --                                           REGION,
      --                                           PLACE_ID,
      --                                           SITE_CODE,
      --                                           LOCATION,
      --                                           QTY_ON_HAND_USEBL,
      --                                           QTY_IN_TRANS_USEBL,
      --                                           ROHS_PID,
      --                                           ROHS_SUBINV,
      --                                           REFURB_METHOD,
      --                                           YIELD,
      --                                           APPLY_YIELD,
      --                                           QTY_AFTER_YIELD, -- Added qty after yield column to refer from C3 system on 09-Jan-2019
      --                                           STATUS,
      --                                           CREATION_DATE,
      --                                           LAST_UPDATED_DATE,
      --                                           LAST_UPDATED_BY,
      --                                           PRODUCT_TYPE,
      --                                           INVENTORY_TYPE,
      --                                           SOURCE_SYSTEM,
      --                                           REFRESH_PART_NUMBER)
      --         (SELECT DISTINCT
      --                 C3.PART_NUMBER, --C3.PART_ID,       -->> Replaced columns of RC_INV_C3_TBL with RC_INV_BTS_C3_MV columns on 01-FEB-2019
      --                 C3.PRODUCT_FAMILY, --C3.PRD_FAMILY, -->> Replaced columns of RC_INV_C3_TBL with RC_INV_BTS_C3_MV columns on 01-FEB-2019
      --                 MAP.REGION     REGION_NAME,
      --                 RP.THEATER_NAME REGION_NAME,
      --                 C3.SITE, --C3.PLACE_ID,             -->> Replaced columns of RC_INV_C3_TBL with RC_INV_BTS_C3_MV columns on 01-FEB-2019
      --                 SUBSTR (C3.SITE, 1, 3), --SUBSTR (C3.PLACE_ID, 1, 3), -- Replaced columns of RC_INV_C3_TBL with RC_INV_BTS_C3_MV columns on 01-FEB-2019
      --                 C3.LOCATION,
      --                 TO_NUMBER (C3.QTY_ON_HAND), --TO_NUMBER (C3.QTY_ON_HAND_USEBL), --Added TO_NUMBER as part of Sprint16 Release by mohamms2  -->> Replaced columns of RC_INV_C3_TBL with RC_INV_BTS_C3_MV columns on 01-FEB-2019
      --                 DECODE (M.UDC_1, 'Y', C3.QTY_IN_TRANSIT, 0), --DECODE (M.UDC_1, 'Y', C3.QTY_IN_TRANS_USEBL, 0), -->> Replaced columns of RC_INV_C3_TBL with RC_INV_BTS_C3_MV columns on 01-FEB-2019
      --                 DECODE (PM.ROHS_CHECK_NEEDED,
      --                         'N', 'NO',
      --                         'Y', 'YES',
      --                         'NO')
      --                    AS ROHS_PID,
      --                 NULL           AS ROHS_LOC,
      --                 /* Start Commented as part of userstory US193036 to modify yield calculation ligic */
      --                                  (SELECT PC.CONFIG_NAME
      --                                     FROM CRPADM.RC_PRODUCT_CONFIG PC
      --                                    WHERE     PC.CONFIG_TYPE = 'REFRESH_METHOD'
      --                                          AND (SELECT MIN (REFRESH_METHOD_ID)
      --                                                 FROM CRPADM.RC_PRODUCT_REPAIR_SETUP IRS
      --                                                WHERE     IRS.REFRESH_INVENTORY_ITEM_ID =
      --                                                             PM.REFRESH_INVENTORY_ITEM_ID
      --                                                      AND IRS.REFRESH_STATUS = 'ACTIVE') =
      --                                                 PC.CONFIG_ID)
      --                                     REFRESH_METHOD,
      --                 /* End Commented as part of userstory US193036 to modify yield calculation ligic */
      --                 /* Start Added as part of userstory US193036 to modify yield calculation ligic */
      --                 /* Start commented to refer yield columns from C3 system on 09-Jan-2019*/
      --                                  (SELECT PC.CONFIG_NAME
      --                                     FROM CRPADM.RC_PRODUCT_CONFIG PC
      --                                    WHERE     PC.CONFIG_TYPE = 'REFRESH_METHOD'
      --                                          AND (SELECT RMKTGADM.RC_INV_DELTA_LOAD_EX.RC_INV_GET_REFURB_METHOD (
      --                                                         PM.REFRESH_INVENTORY_ITEM_ID,
      --                                                         (SUBSTR (C3.PLACE_ID, 1, 3)),
      --                                                         C3.LOCATION)
      --                                                 FROM DUAL) = PC.CONFIG_ID)
      --                                     REFRESH_METHOD,
      --                 /* End commented to refer yield columns from C3 system on 09-Jan-2019*/
      --                 C3.WS_REFURB_METHOD, -- Added to refer yield columns from C3 system on 09-Jan-2019
      --                 /* End Added as part of userstory US193036 to modify yield calculation ligic */
      --                 NVL (RS_RY.REFRESH_YIELD, 0),
      --                               (SELECT MAX (rrsy.REFRESH_YIELD)
      --                                  FROM crpadm.rc_product_repair_setup rrsy
      --                                 WHERE     rrsy.refresh_inventory_item_id =
      --                                              pm.refresh_inventory_item_id
      --                                       AND rrsy.refresh_method_id =
      --                                              RMKTGADM.RC_INV_DELTA_LOAD_RF.RC_INV_GET_REFURB_METHOD (
      --                                                 rrsy.refresh_inventory_item_id)
      --                                       AND rrsy.theater_id = MAP.Theater_ID
      --                                       AND rrsy.REFRESH_STATUS = 'ACTIVE'--and rrsy.refresh_part_number <> 'UCS-CPU-E52695D-WS'
      --                               )
      --                                  Yield,
      --                 /* Start Removed 80% pct logic as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019 */
      --                                  DECODE (RMKTGADM.RC_INV_DELTA_LOAD_EX.RC_INV_GET_YIELD (
      --                                             pm.program_type,
      --                                             pm.refresh_inventory_item_id,
      --                                             DECODE (map.region,  'NAM', 1,  'EMEA', 3),
      --                                             (SUBSTR (C3.PLACE_ID, 1, 3)),
      --                                             (RMKTGADM.RC_INV_DELTA_LOAD_EX.RC_INV_GET_REFURB_METHOD (
      --                                                 pm.refresh_inventory_item_id))),
      --                                          0, 80,
      --                                          RMKTGADM.RC_INV_DELTA_LOAD_EX.RC_INV_GET_YIELD (
      --                                             pm.program_type,
      --                                             pm.refresh_inventory_item_id,
      --                                             DECODE (map.region,  'NAM', 1,  'EMEA', 3),
      --                                             (SUBSTR (C3.PLACE_ID, 1, 3)),
      --                                             (RMKTGADM.RC_INV_DELTA_LOAD_EX.RC_INV_GET_REFURB_METHOD (
      --                                                 pm.refresh_inventory_item_id))))
      --                                     Yield,
      --                 /* End Removed 80% pct logic as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019 */
      --                 /* Start Added as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019 */
      --                 /* Start commented to refer yield columns from C3 system on 09-Jan-2019*/
      --                                  NVL (
      --                                     RMKTGADM.RC_INV_DELTA_LOAD_EX.RC_INV_GET_YIELD (
      --                                        PM.REFRESH_INVENTORY_ITEM_ID,
      --                                        SUBSTR (C3.PLACE_ID, 1, 3),
      --                                        C3.LOCATION),
      --                                     0)
      --                                     YIELD,
      --                 /* End commented to refer yield columns from C3 system on 09-Jan-2019*/
      --                 /* End Added as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019 */
      --                 C3.WS_YIELD_PERCENT, -- Added to refer yield columns from C3 system on 09-Jan-2019
      --                 'N',
      --                 C3.WS_QTY_AFTER_YIELD + C3.YIELDED_WS_QTY_IN_TRANSIT
      --                    QTY_AFTER_YIELD, -- Added to refer yield columns from C3 system on 09-Jan-2019
      --                 C3.PART_STATUS, --C3.STATUS,  -->> Replaced columns of RC_INV_C3_TBL with RC_INV_BTS_C3_MV columns on 01-FEB-2019
      --                 SYSDATE        CREATION_DATE, --C3.CREATION_DATE, -->> Replaced columns of RC_INV_C3_TBL with RC_INV_BTS_C3_MV columns on 01-FEB-2019
      --                 SYSDATE,
      --                 G_UPDATED_BY   LAST_UPDATED_BY,
      --                 'E'            PRODUCT_TYPE,
      --                 M.PROGRAM_TYPE INVENTORY_TYPE,
      --                 'C3',
      --                 PM.REFRESH_PART_NUMBER
      --                        FROM CRPADM.RC_INV_C3_TBL C3 -- Removed VAVNI_CISCO_RSCM_TEMP.RSCM_TMP_C3_INV_TBL table and Added CRPADM table as part of Sprint16 Release by mohamms2 -->> Commented to stop referring RC_INV_C3_TBL for C3 inventory on 01-FEB-2019
      --            FROM CRPADM.RC_INV_BTS_C3_MV C3 -->> Added RC_INV_BTS_C3_MV instead of RC_INV_C3_TBL for c3 Inventory on 01-FEB-2019
      --                 INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
      --                    ON (   C3.INVENTORY_ITEM_ID =
      --                              PM.REFRESH_INVENTORY_ITEM_ID
      --                        OR C3.INVENTORY_ITEM_ID = PM.COMMON_INVENTORY_ITEM_ID
      --                        OR C3.INVENTORY_ITEM_ID = PM.XREF_INVENTORY_ITEM_ID)
      --                 INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR M
      --                    ON (C3.LOCATION = M.SUB_INVENTORY_LOCATION)
      --                                  INNER JOIN CRPADM.RC_PRODUCT_REPAIR_PARTNER RP ON (    SUBSTR (C3.PLACE_ID, 1, 3) = RP.ZCODE  AND RP.ACTIVE_FLAG = 'Y' AND RP.PROGRAM_TYPE = 0)
      --                 INNER JOIN
      --                 (SELECT DISTINCT
      --                         SM.SITE_CODE,
      --                         SM.REGION,
      --                         (SELECT PC.CONFIG_ID
      --                            FROM CRPADM.RC_PRODUCT_CONFIG PC
      --                           WHERE     PC.CONFIG_TYPE = 'THEATER'
      --                                 AND SM.REGION = PC.CONFIG_NAME
      --                                 AND PC.ACTIVE_FLAG = 'Y')
      --                            THEATER_ID
      --                    FROM RMKTGADM.RMK_INV_SITE_MAPPINGS SM
      --                   WHERE SM.INV_TYPE = 'DGI' AND SM.STATUS = 'ACTIVE') MAP
      --                    ON (SUBSTR (C3.SITE, 1, 3) = MAP.SITE_CODE) --ON (SUBSTR (C3.PLACE_ID, 1, 3) = MAP.SITE_CODE)  -->> Replaced columns of RC_INV_C3_TBL with RC_INV_BTS_C3_MV columns on 01-FEB-2019
      --                            LEFT OUTER JOIN
      --                            (SELECT *
      --                               FROM CRPADM.RC_PRODUCT_REPAIR_SETUP RS
      --                              WHERE RS.REFRESH_METHOD_ID =
      --                                       (SELECT MIN (IRS.REFRESH_METHOD_ID)
      --                                          FROM CRPADM.RC_PRODUCT_REPAIR_SETUP IRS
      --                                         WHERE     RS.REFRESH_INVENTORY_ITEM_ID =
      --                                                      IRS.REFRESH_INVENTORY_ITEM_ID
      --                                               AND IRS.REFRESH_STATUS = 'ACTIVE')) RS_RY ON (    RS_RY.REFRESH_INVENTORY_ITEM_ID = PM.REFRESH_INVENTORY_ITEM_ID AND RS_RY.THEATER_ID = RP.THEATER_ID)
      --           WHERE     1 = 1
      --                 AND M.NETTABLE_FLAG = 1
      --                                  AND M.PROGRAM_TYPE IN (1, 2)     -- Inventory Type / Location -->> Commented not to consider POE Locations on 15-OCT-2018 by sridvasu
      --               AND M.PROGRAM_TYPE = 1 --Commented by csirigir on 01-JUL-2020 as part of US398932 -->> Added to consider WS Locations only on 15-OCT-2018 by sridvasu
      --     AND (G_PROGRAM_TYPE = 'N' AND M.PROGRAM_TYPE IN(1,2) OR G_PROGRAM_TYPE = 'Y' AND M.PROGRAM_TYPE = 1)  --Added by csirigir on 01-JUL-2020 as part of US398932
      --                 AND PM.PROGRAM_TYPE = 1      --  (Program Type 0:RF 1:WS) -RF
      --                 AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
      --                  AND C3.QTY_ON_HAND_USEBL <> 0
      --                 AND SUBSTR (C3.SITE, 1, 3) <> 'Z32' -->> Added to restrict Z32 data on 27-FEB-2019
      --                 AND PM.REFRESH_PART_NUMBER NOT IN
      --                        (SELECT REFRESH_PART_NUMBER
      --                           FROM RC_INV_EXCLUDE_PIDS)
      --          UNION ALL
      --            >> FC01/FVE
      --            SELECT FVE.REFRESH_PART_NUMBER,
      --                   NULL,
      --                   DECODE (FVE.PL_PLANNING_DIVISION,
      --                           'FVE', 'EMEA',
      --                           'LRO', 'NAM'),
      --                   'FVE',
      --                   'FVE',
      --                   'WS-DGI',
      --                   SUM (FVE.PD_REMAINING_QTY), --TO_CHAR (SUM (FVE.PD_REMAINING_QTY)) Removed TO_CHAR as part of sprit16 Release by mohamms2
      --                   NULL,
      --                   'YES',
      --                   'YES',
      --                   NULL,
      --                   NULL,
      --                   'N',
      --                   SUM (FVE.PD_REMAINING_QTY) Qty_after_yield, -- Added to refer yield columns from C3 system on 09-Jan-2019
      --                   'NEW',
      --                   SYSDATE,
      --                   SYSDATE,
      --                   G_UPDATED_BY             LAST_UPDATED_BY,
      --                   'E'                      PRODUCT_TYPE,
      --                   NULL,
      --                   'FC01-FVE'               SOURCE_SYSTEM,
      --                   FVE.REFRESH_PART_NUMBER
      --              FROM CRPSC.SC_FC01_SNAPSHOT_FVE FVE
      --                   INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
      --                      ON (PM.REFRESH_PART_NUMBER = FVE.REFRESH_PART_NUMBER)
      --             WHERE     1 = 1
      --                   AND PM.PROGRAM_TYPE = 1
      --                   AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
      --                   AND FVE.PD_REMAINING_QTY > 0
      --                   AND UPPER (PL_LINE_STATUS_CODE) NOT IN
      --                          ('CLOSED', 'CANCELLED')
      --                   AND PM.REFRESH_PART_NUMBER NOT IN
      --                          (SELECT REFRESH_PART_NUMBER
      --                             FROM RC_INV_EXCLUDE_PIDS)
      --          GROUP BY FVE.REFRESH_PART_NUMBER,
      --                   NULL,
      --                   DECODE (FVE.PL_PLANNING_DIVISION,
      --                           'FVE', 'EMEA',
      --                           'LRO', 'NAM'),
      --                   'FVE',
      --                   'FVE',
      --                   'WS-DGI',
      --                   TO_CHAR (sum(FVE.PD_REMAINING_QTY)),
      --                   NULL,
      --                   'YES',
      --                   'YES',
      --                   NULL,
      --                   NULL,
      --                   'N',
      --                   'NEW',
      --                   SYSDATE,
      --                   SYSDATE,
      --                   G_UPDATED_BY,
      --                   'E',
      --                   NULL,
      --                   'FC01-FVE',
      --                   FVE.REFRESH_PART_NUMBER
      --          UNION ALL
      --            >> FC01/LRO
      --            SELECT PM.REFRESH_PART_NUMBER,
      --                   NULL,
      --                   DECODE (LRO.PL_PLANNING_DIVISION,
      --                           'FVE', 'EMEA',
      --                           'LRO', 'NAM'),
      --                   'LRO',
      --                   'LRO',
      --                   'WS-DGI',
      --                   SUM (LRO.PD_REMAINING_QTY), --TO_CHAR (SUM (LRO.PD_REMAINING_QTY)),Removed TO_CHAR as part of Sprint16 release by mohamms2
      --                   NULL,
      --                   'YES',
      --                   'YES',
      --                   NULL,
      --                   NULL,
      --                   'N',
      --                   SUM (LRO.PD_REMAINING_QTY) Qty_after_yield, -- Added to refer yield columns from C3 system on 09-Jan-2019
      --                   'NEW',
      --                   SYSDATE,
      --                   SYSDATE,
      --                   G_UPDATED_BY             LAST_UPDATED_BY,
      --                   'E'                      PRODUCT_TYPE,
      --                   NULL,
      --                   'FC01-LRO'               SOURCE_SYSTEM,
      --                   PM.REFRESH_PART_NUMBER
      --              FROM CRPSC.SC_FC01_SNAPSHOT_LRO LRO
      --                   INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
      --                      ON (PM.REFRESH_PART_NUMBER = LRO.REFRESH_PART_NUMBER)
      --             WHERE     1 = 1
      --                   AND PM.PROGRAM_TYPE = 1
      --                   AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
      --                   AND LRO.PD_REMAINING_QTY > 0
      --                   AND UPPER (PL_LINE_STATUS_CODE) NOT IN
      --                          ('CLOSED', 'CANCELLED')
      --                   AND PM.REFRESH_PART_NUMBER NOT IN
      --                          (SELECT REFRESH_PART_NUMBER
      --                             FROM RC_INV_EXCLUDE_PIDS)
      --          GROUP BY PM.REFRESH_PART_NUMBER,
      --                   NULL,
      --                   DECODE (LRO.PL_PLANNING_DIVISION,
      --                           'FVE', 'EMEA',
      --                           'LRO', 'NAM'),
      --                   'LRO',
      --                   'LRO',
      --                   'WS-DGI',
      --                   TO_CHAR (sum(LRO.PD_REMAINING_QTY)),
      --                   NULL,
      --                   'YES',
      --                   'YES',
      --                   NULL,
      --                   NULL,
      --                   'N',
      --                   'NEW',
      --                   SYSDATE,
      --                   SYSDATE,
      --                   G_UPDATED_BY,
      --                   'E',
      --                   NULL,
      --                   'FC01-LRO',
      --                   PM.REFRESH_PART_NUMBER);
      --End comment US198778
      --Start SONS DGI DELTA CHANGES US198778
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
                                           QTY_AFTER_YIELD, -- Added qty after yield column to refer from C3 system on 09-Jan-2019
                                           STATUS,
                                           CREATION_DATE,
                                           LAST_UPDATED_DATE,
                                           LAST_UPDATED_BY,
                                           PRODUCT_TYPE,
                                           INVENTORY_TYPE,
                                           SOURCE_SYSTEM,
                                           REFRESH_PART_NUMBER)
         (SELECT DISTINCT
                 C3.PART_NUMBER, --C3.PART_ID,       -->> Replaced columns of RC_INV_C3_TBL with RC_INV_BTS_C3_MV columns on 01-FEB-2019
                 C3.PRODUCT_FAMILY, --C3.PRD_FAMILY, -->> Replaced columns of RC_INV_C3_TBL with RC_INV_BTS_C3_MV columns on 01-FEB-2019
                 MAP.REGION     REGION_NAME,
                 --RP.THEATER_NAME REGION_NAME,
                 C3.SITE, --C3.PLACE_ID,             -->> Replaced columns of RC_INV_C3_TBL with RC_INV_BTS_C3_MV columns on 01-FEB-2019
                 SUBSTR (C3.SITE, 1, 3), --SUBSTR (C3.PLACE_ID, 1, 3), -- Replaced columns of RC_INV_C3_TBL with RC_INV_BTS_C3_MV columns on 01-FEB-2019
                 C3.LOCATION,
                 TO_NUMBER (C3.QTY_ON_HAND), --TO_NUMBER (C3.QTY_ON_HAND_USEBL), --Added TO_NUMBER as part of Sprint16 Release by mohamms2  -->> Replaced columns of RC_INV_C3_TBL with RC_INV_BTS_C3_MV columns on 01-FEB-2019
                 DECODE (M.UDC_1, 'Y', C3.QTY_IN_TRANSIT, 0), --DECODE (M.UDC_1, 'Y', C3.QTY_IN_TRANS_USEBL, 0), -->> Replaced columns of RC_INV_C3_TBL with RC_INV_BTS_C3_MV columns on 01-FEB-2019
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
                 /* End Commented as part of userstory US193036 to modify yield calculation ligic */
                 /* Start Added as part of userstory US193036 to modify yield calculation ligic */
                 /* Start commented to refer yield columns from C3 system on 09-Jan-2019*/
                 --                 (SELECT PC.CONFIG_NAME
                 --                    FROM CRPADM.RC_PRODUCT_CONFIG PC
                 --                   WHERE     PC.CONFIG_TYPE = 'REFRESH_METHOD'
                 --                         AND (SELECT RMKTGADM.RC_INV_DELTA_LOAD_EX.RC_INV_GET_REFURB_METHOD (
                 --                                        PM.REFRESH_INVENTORY_ITEM_ID,
                 --                                        (SUBSTR (C3.PLACE_ID, 1, 3)),
                 --                                        C3.LOCATION)
                 --                                FROM DUAL) = PC.CONFIG_ID)
                 --                    REFRESH_METHOD,
                 /* End commented to refer yield columns from C3 system on 09-Jan-2019*/
                 C3.WS_REFURB_METHOD, -- Added to refer yield columns from C3 system on 09-Jan-2019
                 /* End Added as part of userstory US193036 to modify yield calculation ligic */
                 --NVL (RS_RY.REFRESH_YIELD, 0),
                 --              (SELECT MAX (rrsy.REFRESH_YIELD)
                 --                 FROM crpadm.rc_product_repair_setup rrsy
                 --                WHERE     rrsy.refresh_inventory_item_id =
                 --                             pm.refresh_inventory_item_id
                 --                      AND rrsy.refresh_method_id =
                 --                             RMKTGADM.RC_INV_DELTA_LOAD_RF.RC_INV_GET_REFURB_METHOD (
                 --                                rrsy.refresh_inventory_item_id)
                 --                      AND rrsy.theater_id = MAP.Theater_ID
                 --                      AND rrsy.REFRESH_STATUS = 'ACTIVE'--and rrsy.refresh_part_number <> 'UCS-CPU-E52695D-WS'
                 --              )
                 --                 Yield,
                 /* Start Removed 80% pct logic as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019 */
                 --                 DECODE (RMKTGADM.RC_INV_DELTA_LOAD_EX.RC_INV_GET_YIELD (
                 --                            pm.program_type,
                 --                            pm.refresh_inventory_item_id,
                 --                            DECODE (map.region,  'NAM', 1,  'EMEA', 3),
                 --                            (SUBSTR (C3.PLACE_ID, 1, 3)),
                 --                            (RMKTGADM.RC_INV_DELTA_LOAD_EX.RC_INV_GET_REFURB_METHOD (
                 --                                pm.refresh_inventory_item_id))),
                 --                         0, 80,
                 --                         RMKTGADM.RC_INV_DELTA_LOAD_EX.RC_INV_GET_YIELD (
                 --                            pm.program_type,
                 --                            pm.refresh_inventory_item_id,
                 --                            DECODE (map.region,  'NAM', 1,  'EMEA', 3),
                 --                            (SUBSTR (C3.PLACE_ID, 1, 3)),
                 --                            (RMKTGADM.RC_INV_DELTA_LOAD_EX.RC_INV_GET_REFURB_METHOD (
                 --                                pm.refresh_inventory_item_id))))
                 --                    Yield,
                 /* End Removed 80% pct logic as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019 */
                 /* Start Added as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019 */
                 /* Start commented to refer yield columns from C3 system on 09-Jan-2019*/
                 --                 NVL (
                 --                    RMKTGADM.RC_INV_DELTA_LOAD_EX.RC_INV_GET_YIELD (
                 --                       PM.REFRESH_INVENTORY_ITEM_ID,
                 --                       SUBSTR (C3.PLACE_ID, 1, 3),
                 --                       C3.LOCATION),
                 --                    0)
                 --                    YIELD,
                 /* End commented to refer yield columns from C3 system on 09-Jan-2019*/
                 /* End Added as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019 */
                 C3.WS_YIELD_PERCENT, -- Added to refer yield columns from C3 system on 09-Jan-2019
                 'N',
                 C3.WS_QTY_AFTER_YIELD + C3.YIELDED_WS_QTY_IN_TRANSIT
                    QTY_AFTER_YIELD, -- Added to refer yield columns from C3 system on 09-Jan-2019
                 C3.PART_STATUS, --C3.STATUS,  -->> Replaced columns of RC_INV_C3_TBL with RC_INV_BTS_C3_MV columns on 01-FEB-2019
                 SYSDATE        CREATION_DATE, --C3.CREATION_DATE, -->> Replaced columns of RC_INV_C3_TBL with RC_INV_BTS_C3_MV columns on 01-FEB-2019
                 SYSDATE,
                 G_UPDATED_BY   LAST_UPDATED_BY,
                 'E'            PRODUCT_TYPE,
                 M.PROGRAM_TYPE INVENTORY_TYPE,
                 'C3',
                 PM.REFRESH_PART_NUMBER
            --            FROM CRPADM.RC_INV_C3_TBL C3 -- Removed VAVNI_CISCO_RSCM_TEMP.RSCM_TMP_C3_INV_TBL table and Added CRPADM table as part of Sprint16 Release by mohamms2 -->> Commented to stop referring RC_INV_C3_TBL for C3 inventory on 01-FEB-2019
            FROM CRPADM.RC_INV_BTS_C3_MV C3 -->> Added RC_INV_BTS_C3_MV instead of RC_INV_C3_TBL for c3 Inventory on 01-FEB-2019
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
                    ON (SUBSTR (C3.SITE, 1, 3) = MAP.SITE_CODE) --ON (SUBSTR (C3.PLACE_ID, 1, 3) = MAP.SITE_CODE)  -->> Replaced columns of RC_INV_C3_TBL with RC_INV_BTS_C3_MV columns on 01-FEB-2019
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
                 --                 AND M.PROGRAM_TYPE IN (1, 2)     -- Inventory Type / Location -->> Commented not to consider POE Locations on 15-OCT-2018 by sridvasu
                 AND M.PROGRAM_TYPE = 1 -->> Added to consider WS Locations only on 15-OCT-2018 by sridvasu
                 AND PM.PROGRAM_TYPE = 1      --  (Program Type 0:RF 1:WS) -RF
                 AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                 -- AND C3.QTY_ON_HAND_USEBL <> 0
                 AND SUBSTR (C3.SITE, 1, 3) <> 'Z32' -->> Added to restrict Z32 data on 27-FEB-2019
                 AND PM.REFRESH_PART_NUMBER NOT IN
                        (SELECT REFRESH_PART_NUMBER
                           FROM RC_INV_EXCLUDE_PIDS));


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
                                           QTY_AFTER_YIELD, -- Added qty after yield column to refer from C3 system on 09-Jan-2019
                                           STATUS,
                                           CREATION_DATE,
                                           LAST_UPDATED_DATE,
                                           LAST_UPDATED_BY,
                                           PRODUCT_TYPE,
                                           INVENTORY_TYPE,
                                           SOURCE_SYSTEM,
                                           REFRESH_PART_NUMBER)
         (  SELECT SONS.PART_NUMBER,
                   NULL,
                   DECODE (SONS.TO_ORG,  'FVE', 'EMEA',  'LRO', 'NAM'),
                   SONS.TO_ORG,
                   SONS.TO_ORG,
                   'WS-DGI',
                   SUM (SONS.PENDING_QTY), --TO_CHAR (SUM (FVE.PD_REMAINING_QTY)) Removed TO_CHAR as part of sprit16 Release by mohamms2
                   NULL,
                   'YES',
                   'YES',
                   NULL,
                   NULL,
                   'N',
                   SUM (SONS.PENDING_QTY) Qty_after_yield, -- Added to refer yield columns from C3 system on 09-Jan-2019
                   'NEW',
                   SYSDATE,
                   SYSDATE,
                   G_UPDATED_BY         LAST_UPDATED_BY,
                   'E'                  PRODUCT_TYPE,
                   NULL,
                   'INTRANSIT-SONS'     SOURCE_SYSTEM,
                   SONS.REFRESH_PID
              FROM RC_SONS_INTRANS_SHIPMTS_STG SONS
                   INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                      ON (PM.REFRESH_PART_NUMBER = SONS.REFRESH_PID)
             WHERE     1 = 1
                   AND PM.PROGRAM_TYPE = 1
                   AND SONS.ORDER_TYPE LIKE 'SONS%'
                   AND TO_ORG IN ('LRO', 'FVE')
                   AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                   AND SONS.PENDING_QTY > 0
                   AND FULLY_RECEIVED_FLAG = 'N'
                   AND TRUNC (SONS.SHIPPED_DATE) >
                          TO_DATE ('08/22/2020', 'mm/dd/yyyy')
                   AND SEQ_ID = (SELECT MAX (SEQ_ID)
                                   FROM RC_SONS_INTRANS_SHIPMTS_STG
                                  WHERE SHIPMENT_NUMBER = SONS.SHIPMENT_NUMBER)
                   AND PM.REFRESH_PART_NUMBER NOT IN
                          (SELECT REFRESH_PART_NUMBER
                             FROM RC_INV_EXCLUDE_PIDS)
          GROUP BY SONS.PART_NUMBER,
                   NULL,
                   DECODE (SONS.TO_ORG,  'FVE', 'EMEA',  'LRO', 'NAM'),
                   SONS.TO_ORG,
                   SONS.TO_ORG,
                   'WS-DGI',
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
                   'E',
                   NULL,
                   'INTRANSIT-SONS',
                   SONS.REFRESH_PID);

      --UNION ALL
      -->> FC01/FVE

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
                                           QTY_AFTER_YIELD, -- Added qty after yield column to refer from C3 system on 09-Jan-2019
                                           STATUS,
                                           CREATION_DATE,
                                           LAST_UPDATED_DATE,
                                           LAST_UPDATED_BY,
                                           PRODUCT_TYPE,
                                           INVENTORY_TYPE,
                                           SOURCE_SYSTEM,
                                           REFRESH_PART_NUMBER)
         (SELECT FVE.REFRESH_PART_NUMBER,
                 NULL,
                 DECODE (FVE.PL_PLANNING_DIVISION,
                         'FVE', 'EMEA',
                         'LRO', 'NAM'),
                 'FVE',
                 'FVE',
                 'WS-DGI',
                 FVE.PD_REMAINING_QTY, --TO_CHAR (SUM (FVE.PD_REMAINING_QTY)) Removed TO_CHAR as part of sprit16 Release by mohamms2
                 NULL,
                 'YES',
                 'YES',
                 NULL,
                 NULL,
                 'N',
                 FVE.PD_REMAINING_QTY Qty_after_yield, -- Added to refer yield columns from C3 system on 09-Jan-2019
                 'NEW',
                 SYSDATE,
                 SYSDATE,
                 G_UPDATED_BY         LAST_UPDATED_BY,
                 'E'                  PRODUCT_TYPE,
                 NULL,
                 'FC01-FVE'           SOURCE_SYSTEM,
                 FVE.REFRESH_PART_NUMBER
            FROM (  SELECT REFRESH_PART_NUMBER,
                           PL_LINE_STATUS_CODE,
                           PL_PLANNING_DIVISION,
                           SUM (PD_REMAINING_QTY) PD_REMAINING_QTY,
                           PO_BUYER
                      FROM CRPSC.SC_FC01_SNAPSHOT_FVE
                  GROUP BY REFRESH_PART_NUMBER,
                           PL_LINE_STATUS_CODE,
                           PL_PLANNING_DIVISION,
                           PO_BUYER) FVE
                 LEFT OUTER JOIN RC_SONS_INTRANS_SHIPMTS_STG
                    ON     SHIPMENT_NUMBER = PO_BUYER
                       AND (   PENDING_QTY = PD_REMAINING_QTY
                            OR FULLY_RECEIVED_FLAG = 'Y')
                 INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                    ON (PM.REFRESH_PART_NUMBER = FVE.REFRESH_PART_NUMBER)
           WHERE     1 = 1
                 AND PM.PROGRAM_TYPE = 1
                 AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                 AND FVE.PD_REMAINING_QTY > 0
                 AND UPPER (PL_LINE_STATUS_CODE) NOT IN
                        ('CLOSED', 'CANCELLED')
                 AND PM.REFRESH_PART_NUMBER NOT IN
                        (SELECT REFRESH_PART_NUMBER
                           FROM RC_INV_EXCLUDE_PIDS)
                 AND REFRESH_PID IS NULL
          UNION ALL
          -->> FC01/LRO
          SELECT PM.REFRESH_PART_NUMBER,
                 NULL,
                 DECODE (LRO.PL_PLANNING_DIVISION,
                         'FVE', 'EMEA',
                         'LRO', 'NAM'),
                 'LRO',
                 'LRO',
                 'WS-DGI',
                 LRO.PD_REMAINING_QTY, --TO_CHAR (SUM (LRO.PD_REMAINING_QTY)),Removed TO_CHAR as part of Sprint16 release by mohamms2
                 NULL,
                 'YES',
                 'YES',
                 NULL,
                 NULL,
                 'N',
                 LRO.PD_REMAINING_QTY Qty_after_yield, -- Added to refer yield columns from C3 system on 09-Jan-2019
                 'NEW',
                 SYSDATE,
                 SYSDATE,
                 G_UPDATED_BY         LAST_UPDATED_BY,
                 'E'                  PRODUCT_TYPE,
                 NULL,
                 'FC01-LRO'           SOURCE_SYSTEM,
                 PM.REFRESH_PART_NUMBER
            FROM (  SELECT REFRESH_PART_NUMBER,
                           PL_LINE_STATUS_CODE,
                           PL_PLANNING_DIVISION,
                           SUM (PD_REMAINING_QTY) PD_REMAINING_QTY,
                           PO_BUYER
                      FROM CRPSC.SC_FC01_SNAPSHOT_LRO
                  GROUP BY REFRESH_PART_NUMBER,
                           PL_LINE_STATUS_CODE,
                           PL_PLANNING_DIVISION,
                           PO_BUYER) LRO
                 LEFT OUTER JOIN RC_SONS_INTRANS_SHIPMTS_STG
                    ON     SHIPMENT_NUMBER = PO_BUYER
                       AND (   PENDING_QTY = PD_REMAINING_QTY
                            OR FULLY_RECEIVED_FLAG = 'Y')
                       AND TRUNC (SHIPPED_DATE) >
                              TO_DATE ('08/22/2020', 'mm/dd/yyyy')
                 INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                    ON (PM.REFRESH_PART_NUMBER = LRO.REFRESH_PART_NUMBER)
           WHERE     1 = 1
                 AND PM.PROGRAM_TYPE = 1
                 AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                 AND LRO.PD_REMAINING_QTY > 0
                 AND UPPER (PL_LINE_STATUS_CODE) NOT IN
                        ('CLOSED', 'CANCELLED')
                 AND PM.REFRESH_PART_NUMBER NOT IN
                        (SELECT REFRESH_PART_NUMBER
                           FROM RC_INV_EXCLUDE_PIDS)
                 AND REFRESH_PID IS NULL);

      --End SONS DGI DELTA CHANGES US198778
      COMMIT;

      -- update Apply field flag depending the sub inventory location
      UPDATE RMKTGADM.RC_INV_DGI_STG
         SET APPLY_YIELD = 'Y'
       WHERE     1 = 1
             AND SOURCE_SYSTEM != 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
             --  and ( SOURCE_SYSTEM <> 'FC01-FVE' OR SOURCE_SYSTEM <> 'FC01-LRO' )  -->> To avoid Yield Calc on FC01 Inventory.
             AND SOURCE_SYSTEM NOT IN ('FC01-FVE', 'FC01-LRO')
             AND SITE_CODE NOT IN ('FVE', 'LRO')
             AND PRODUCT_TYPE = 'E'
             -->>
             AND LOCATION IN
                    (SELECT M.SUB_INVENTORY_LOCATION
                       FROM CRPADM.RC_SUB_INV_LOC_MSTR M
                            INNER JOIN CRPADM.RC_SUB_INV_LOC_FLG_DTLS D
                               ON (M.SUB_INVENTORY_ID = D.SUB_INVENTORY_ID)
                      WHERE M.NETTABLE_FLAG = 1 -- AND m.INVENTORY_TYPE IN (0, 2) -- RF and POE
                                                --                            AND M.PROGRAM_TYPE IN (1, 2) -->> Inventory Types 0 = RF ; 2 = POE -->> Commented not to consider common (POE) Locations on 15-OCT-2018 by sridvasu
                            AND M.PROGRAM_TYPE = 1 -->> Added to consider only WS Locations on 15-OCT-2018 by sridvasu
                                                  AND D.YIELD_WS = 'Y');

      -- update the quantity     after yield values depending in the apply yield flag
      /* Start Removed 80% pct logic as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019 */

      --      UPDATE RMKTGADM.RC_INV_DGI_STG
      --         SET QTY_AFTER_YIELD =
      --                DECODE (
      --                   APPLY_YIELD,
      --                   'Y',   (DECODE (NVL (YIELD, 0), 0, 80, YIELD) / 100)
      --                        * (QTY_ON_HAND_USEBL + QTY_IN_TRANS_USEBL),
      --                   'N', (QTY_ON_HAND_USEBL + NVL (QTY_IN_TRANS_USEBL, 0)),
      --                   (QTY_ON_HAND_USEBL + NVL (QTY_IN_TRANS_USEBL, 0)))
      --       WHERE PRODUCT_TYPE = 'E';                         -- To Process only WS

      /* End Removed 80% pct logic as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019 */

      /* Start commented to refer yield columns from C3 system on 09-Jan-2019*/

      /* Start Added as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019 */

      --      UPDATE RMKTGADM.RC_INV_DGI_STG
      --         SET QTY_AFTER_YIELD =
      --                DECODE (
      --                   APPLY_YIELD,
      --                   'Y',   (YIELD / 100)
      --                        * (QTY_ON_HAND_USEBL + QTY_IN_TRANS_USEBL),
      --                   'N', (QTY_ON_HAND_USEBL + NVL (QTY_IN_TRANS_USEBL, 0)),
      --                   (QTY_ON_HAND_USEBL + NVL (QTY_IN_TRANS_USEBL, 0)))
      --       WHERE PRODUCT_TYPE = 'E';                         -- To Process only WS

      /* End Added as part of US193034 Yield - Zero percent yield issue on 19-JUN-2019  */

      /* End commented to refer yield columns from C3 system on 09-Jan-2019*/

      G_PROC_NAME := 'RC_INV_EX_DGI_EXTRACT';



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
                   'RC_INV_DELTA_LOAD_EX');


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
                      P_SITE_CODE || '-' || G_ERROR_MSG,        --G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_EX');

         G_PROC_NAME := 'RC_INV_EX_DGI_EXTRACT';

         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_EX_DGI_EXTRACT;

   PROCEDURE RC_INV_EX_DGI_HISTORY (P_SITE_CODE IN VARCHAR2)
   IS
      L_START_TIME   DATE;
   BEGIN
      G_PROC_NAME := 'RC_INV_EX_DGI_HISTORY';

      L_START_TIME := SYSDATE;

      --consolidate the inventory to Zlocation level
      INSERT INTO RMKTGADM.RC_INV_DGI_HIST (PART_ID,
                                            PRD_FAMILY,
                                            ZLOCATION,
                                            ZCODE,
                                            QTY_AFTER_YIELD,
                                            ROHS_PID,
                                            LOCATION, --PRODUCT_NAME_STRIPPED,
                                            STATUS,
                                            SITE_SHORTNAME,
                                            CREATED_ON,
                                            UPDATED_ON,
                                            PRODUCT_TYPE,
                                            INVENTORY_TYPE,
                                            SOURCE_SYSTEM)
           SELECT DISTINCT REFRESH_PART_NUMBER,                     --PART_ID,
                           PRD_FAMILY,
                           PLACE_ID,
                           STG.SITE_CODE,
                           SUM (QTY_AFTER_YIELD) QTY,
                           ROHS_PID,
                           LOCATION,                  --PRODUCT_NAME_STRIPPED,
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
                                               'WS_POE',
                                               'ALL',
                                               1))
                       OR (    STG.REFURB_METHOD = 'TEST'
                           AND STG.LOCATION
                                   MEMBER OF CRPADM.RC_GET_SUBINVENTORY_LOCATIONS (
                                               6,
                                               'WS_POE',
                                               'ALL',
                                               1))
                       OR (    STG.REFURB_METHOD = 'SCREEN'
                           AND STG.LOCATION
                                   MEMBER OF CRPADM.RC_GET_SUBINVENTORY_LOCATIONS (
                                               3,
                                               'WS_POE',
                                               'ALL',
                                               1))
                       --> Include POE-LT as Nettable for Excess
                       OR SUB.SUB_INVENTORY_LOCATION = 'POE-LT'
                       -->
                       OR (STG.SOURCE_SYSTEM = 'FC01-FVE')
                       OR (STG.SOURCE_SYSTEM = 'FC01-LRO'))
                     End Removed sub inv condition */
                  AND SUB.INVENTORY_TYPE <> 0              -- Not consider FGI
                  --                  AND SUB.PROGRAM_TYPE IN (1, 2)  -- Retail (1) Excess (2) POE -->> Commented not to consider common (POE) Locations on 15-OCT-2018 by sridvasu
                  AND SUB.PROGRAM_TYPE = 1 -->> Added to consider only WS Locations on 15-OCT-2018 by sridvasu
                  AND PRODUCT_TYPE = 'E'
                  AND stg.SOURCE_SYSTEM != 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
         GROUP BY REFRESH_PART_NUMBER,
                  PRD_FAMILY,
                  PLACE_ID,
                  STG.SITE_CODE,
                  ROHS_PID,
                  LOCATION,                           --PRODUCT_NAME_STRIPPED,
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
                           STG.LOCATION,          --stg.PRODUCT_NAME_STRIPPED,
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
                  AND SUB.PROGRAM_TYPE = 1            -- (0) Retail (1) Excess
                  AND STG.PRODUCT_TYPE = 'E'
                  AND stg.SOURCE_SYSTEM != 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
         --                  AND STG.REFURB_METHOD <> 'REPAIR'
         --and STG.part_id = '1030036-RF'
         GROUP BY STG.REFRESH_PART_NUMBER,
                  STG.PRD_FAMILY,
                  STG.PLACE_ID,
                  STG.SITE_CODE,
                  STG.ROHS_PID,
                  STG.LOCATION,                   --stg.PRODUCT_NAME_STRIPPED,
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
                   P_SITE_CODE,                                       -- NULL,
                   'RC_INV_DELTA_LOAD_EX');

      G_PROC_NAME := 'RC_INV_EX_DGI_HISTORY';
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
                      P_SITE_CODE || '-' || G_ERROR_MSG,       -- G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_EX');

         G_PROC_NAME := 'RC_INV_EX_DGI_HISTORY';

         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_EX_DGI_HISTORY;

   PROCEDURE RC_INV_EX_DGI_DELTA (P_SITE_CODE IN VARCHAR2)
   IS
      LAST_VALUE         NUMBER;
      V_DGI_DELTA        NUMBER;
      TOTAL_QTY_DGI      NUMBER;
      TOTAL_ONHAND_DGI   NUMBER;
      C3_ONHAND_DGI      NUMBER;
      C3_QTY_DGI         NUMBER;
      v_status           VARCHAR2 (2);
      v_ccw_inv          NUMBER;


      CURSOR DGI_CURSOR_DELTA
      IS
         SELECT T1.POE_BATCH_ID,
                T1.PART_ID,
                T1.QTY_AFTER_YIELD,
                T1.ROHS_PID,
                --T1.SITE_SHORTNAME,    --DeltaAgg-->
                T1.PRODUCT_TYPE,
                --T1.INVENTORY_TYPE,    --DeltaAgg-->
                T1.SOURCE_SYSTEM
           FROM (  SELECT POE_BATCH_ID,
                          PART_ID,
                          SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                          ROHS_PID,
                          --SITE_SHORTNAME,       --DeltaAgg-->
                          PRODUCT_TYPE,
                          --INVENTORY_TYPE,        --DeltaAgg-->
                          SOURCE_SYSTEM
                     FROM RMKTGADM.RC_INV_DGI_HIST
                    WHERE     PRODUCT_TYPE = 'E'
                          AND STATUS = 'CURRENT'
                          AND SOURCE_SYSTEM != 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                 GROUP BY POE_BATCH_ID,
                          PART_ID,
                          ROHS_PID,
                          --SITE_SHORTNAME,       --DeltaAgg-->
                          PRODUCT_TYPE,
                          --INVENTORY_TYPE,       --DeltaAgg-->
                          SOURCE_SYSTEM) T1
                INNER JOIN
                (  SELECT PART_ID,
                          SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                          ROHS_PID,
                          --SITE_SHORTNAME,      --DeltaAgg-->
                          PRODUCT_TYPE,
                          --INVENTORY_TYPE,      --DeltaAgg-->
                          SOURCE_SYSTEM
                     FROM RMKTGADM.RC_INV_DGI_HIST
                    WHERE     PRODUCT_TYPE = 'E'
                          AND STATUS = 'LASTRUN'
                          AND SOURCE_SYSTEM != 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                 GROUP BY POE_BATCH_ID,
                          PART_ID,
                          ROHS_PID,
                          --SITE_SHORTNAME,       --DeltaAgg-->
                          PRODUCT_TYPE,
                          --INVENTORY_TYPE,       --DeltaAgg-->
                          SOURCE_SYSTEM) T2
                   ON     T1.PART_ID = T2.PART_ID
                      -- AND T1.SITE_SHORTNAME = T2.SITE_SHORTNAME
                      -- and (T1.INVENTORY_TYPE=T2.INVENTORY_TYPE OR T1.SOURCE_SYSTEM IN ('FC01-FVE','FC01-LRO'));
                      -->>
                      AND T1.PRODUCT_TYPE = T2.PRODUCT_TYPE
                      AND T1.SOURCE_SYSTEM = T2.SOURCE_SYSTEM; -- OR T1.SOURCE_SYSTEM IN ('FC01-FVE', 'FC01-LRO')) ;

      CURSOR DGI_CURSOR_CURRENT
      IS
           SELECT PART_ID,
                  SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                  ROHS_PID,
                  --SITE_SHORTNAME,      --DeltaAgg-->
                  PRODUCT_TYPE,
                  --INVENTORY_TYPE,      --DeltaAgg-->
                  SOURCE_SYSTEM
             FROM RMKTGADM.RC_INV_DGI_HIST
            WHERE     PRODUCT_TYPE = 'E'
                  AND STATUS = 'CURRENT'
                  AND SOURCE_SYSTEM != 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
         GROUP BY POE_BATCH_ID,
                  PART_ID,
                  ROHS_PID,
                  --SITE_SHORTNAME,      --DeltaAgg-->
                  PRODUCT_TYPE,
                  --INVENTORY_TYPE,       --DeltaAgg-->
                  SOURCE_SYSTEM
         MINUS
         SELECT T1.PART_ID,
                T1.QTY_AFTER_YIELD,
                T1.ROHS_PID,
                --T1.SITE_SHORTNAME,   --DeltaAgg-->
                T1.PRODUCT_TYPE,
                --T1.INVENTORY_TYPE,   --DeltaAgg-->
                T1.SOURCE_SYSTEM
           FROM (  SELECT POE_BATCH_ID,
                          PART_ID,
                          SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                          ROHS_PID,
                          --SITE_SHORTNAME,     --DeltaAgg-->
                          PRODUCT_TYPE,
                          --INVENTORY_TYPE,      --DeltaAgg-->
                          SOURCE_SYSTEM
                     FROM RMKTGADM.RC_INV_DGI_HIST
                    WHERE     PRODUCT_TYPE = 'E'
                          AND STATUS = 'CURRENT'
                          AND SOURCE_SYSTEM != 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                 GROUP BY POE_BATCH_ID,
                          PART_ID,
                          ROHS_PID,
                          --SITE_SHORTNAME,      --DeltaAgg-->
                          PRODUCT_TYPE,
                          --INVENTORY_TYPE,       --DeltaAgg-->
                          SOURCE_SYSTEM) T1
                INNER JOIN
                (  SELECT PART_ID,
                          SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                          ROHS_PID,
                          --SITE_SHORTNAME,     --DeltaAgg-->
                          PRODUCT_TYPE,
                          --INVENTORY_TYPE,      --DeltaAgg-->
                          SOURCE_SYSTEM
                     FROM RMKTGADM.RC_INV_DGI_HIST
                    WHERE     PRODUCT_TYPE = 'E'
                          AND STATUS = 'LASTRUN'
                          AND SOURCE_SYSTEM != 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                 GROUP BY POE_BATCH_ID,
                          PART_ID,
                          ROHS_PID,
                          --SITE_SHORTNAME,       --DeltaAgg-->
                          PRODUCT_TYPE,
                          --INVENTORY_TYPE,        --DeltaAgg-->
                          SOURCE_SYSTEM) T2
                   ON     T1.PART_ID = T2.PART_ID
                      --  AND T1.SITE_SHORTNAME = T2.SITE_SHORTNAME     --DeltaAgg-->
                      -- and (T1.INVENTORY_TYPE=T2.INVENTORY_TYPE OR T1.SOURCE_SYSTEM IN ('FC01-FVE','FC01-LRO'));     --DeltaAgg-->
                      -->>
                      AND T1.PRODUCT_TYPE = T2.PRODUCT_TYPE
                      AND T1.SOURCE_SYSTEM = T2.SOURCE_SYSTEM; -- OR T1.SOURCE_SYSTEM IN ('FC01-FVE', 'FC01-LRO') ) ;

      CURSOR DGI_CURSOR_LAST
      IS
           SELECT PART_ID,
                  SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                  ROHS_PID,
                  --SITE_SHORTNAME,       --DeltaAgg-->
                  PRODUCT_TYPE,
                  --INVENTORY_TYPE,        --DeltaAgg-->
                  SOURCE_SYSTEM
             FROM RMKTGADM.RC_INV_DGI_HIST
            WHERE     PRODUCT_TYPE = 'E'
                  AND STATUS = 'LASTRUN'
                  AND SOURCE_SYSTEM != 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
         GROUP BY POE_BATCH_ID,
                  PART_ID,
                  ROHS_PID,
                  --SITE_SHORTNAME,       --DeltaAgg-->
                  PRODUCT_TYPE,
                  --INVENTORY_TYPE,       --DeltaAgg-->
                  SOURCE_SYSTEM
         MINUS
         SELECT T2.PART_ID,
                T2.QTY_AFTER_YIELD,
                T2.ROHS_PID,
                --T2.SITE_SHORTNAME,   --DeltaAgg-->
                T2.PRODUCT_TYPE,
                --T2.INVENTORY_TYPE,    --DeltaAgg-->
                T2.SOURCE_SYSTEM
           FROM (  SELECT PART_ID,
                          SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                          ROHS_PID,
                          --SITE_SHORTNAME,      --DeltaAgg-->
                          PRODUCT_TYPE,
                          --INVENTORY_TYPE,      --DeltaAgg-->
                          SOURCE_SYSTEM
                     FROM RMKTGADM.RC_INV_DGI_HIST
                    WHERE     PRODUCT_TYPE = 'E'
                          AND STATUS = 'CURRENT'
                          AND SOURCE_SYSTEM != 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                 GROUP BY POE_BATCH_ID,
                          PART_ID,
                          ROHS_PID,
                          --SITE_SHORTNAME,       --DeltaAgg-->
                          PRODUCT_TYPE,
                          --INVENTORY_TYPE,        --DeltaAgg-->
                          SOURCE_SYSTEM) T1
                INNER JOIN
                (  SELECT POE_BATCH_ID,
                          PART_ID,
                          SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                          ROHS_PID,
                          --SITE_SHORTNAME,       --DeltaAgg-->
                          PRODUCT_TYPE,
                          --INVENTORY_TYPE,       --DeltaAgg-->
                          SOURCE_SYSTEM
                     FROM RMKTGADM.RC_INV_DGI_HIST
                    WHERE     PRODUCT_TYPE = 'E'
                          AND STATUS = 'LASTRUN'
                          AND SOURCE_SYSTEM != 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                 GROUP BY POE_BATCH_ID,
                          PART_ID,
                          ROHS_PID,
                          --SITE_SHORTNAME,      --DeltaAgg-->
                          PRODUCT_TYPE,
                          --INVENTORY_TYPE,      --DeltaAgg-->
                          SOURCE_SYSTEM) T2
                   ON     T1.PART_ID = T2.PART_ID
                      -->>   AND T1.SITE_SHORTNAME = T2.SITE_SHORTNAME      --DeltaAgg-->
                      -->>  and (T1.INVENTORY_TYPE=T2.INVENTORY_TYPE OR T1.SOURCE_SYSTEM IN ('FC01-FVE','FC01-LRO'));     --DeltaAgg-->
                      -->>
                      AND T1.PRODUCT_TYPE = T2.PRODUCT_TYPE
                      AND T1.SOURCE_SYSTEM = T2.SOURCE_SYSTEM; -- OR T1.SOURCE_SYSTEM IN ('FC01-FVE', 'FC01-LRO') );

      DGI_RECORD         DGI_CURSOR_DELTA%ROWTYPE;
      DGI_RECORD_C       DGI_CURSOR_CURRENT%ROWTYPE;
      DGI_RECORD_L       DGI_CURSOR_CURRENT%ROWTYPE;
      L_START_TIME       DATE;
   BEGIN
      G_PROC_NAME := 'RC_INV_EX_DGI_DELTA';

      L_START_TIME := SYSDATE;

      DELETE FROM RMKTGADM.RC_INV_DGI_DELTA
            WHERE PRODUCT_TYPE = 'E' AND SOURCE_SYSTEM != 'POE'; --Added this condition part of US398932 by Satyredd on 11th Aug 2020;

      COMMIT;


      OPEN DGI_CURSOR_DELTA;

      LOOP
         FETCH DGI_CURSOR_DELTA INTO DGI_RECORD;

         EXIT WHEN DGI_CURSOR_DELTA%NOTFOUND;

         SELECT SUM (QTY_AFTER_YIELD)
           INTO LAST_VALUE
           FROM RMKTGADM.RC_INV_DGI_HIST
          WHERE     PRODUCT_TYPE = 'E'
                AND SOURCE_SYSTEM != 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                AND PART_ID = DGI_RECORD.PART_ID
                --AND SITE_SHORTNAME = DGI_RECORD.SITE_SHORTNAME   --DeltaAgg-->
                AND PRODUCT_TYPE = DGI_RECORD.PRODUCT_TYPE  -->> --DeltaAgg-->
                AND SOURCE_SYSTEM = DGI_RECORD.SOURCE_SYSTEM -- OR SOURCE_SYSTEM IN ('FC01-FVE', 'FC01-LRO'))  --DeltaAgg-->
                --AND (   INVENTORY_TYPE = DGI_RECORD.INVENTORY_TYPE OR SOURCE_SYSTEM IN ('FC01-FVE', 'FC01-LRO'))  --DeltaAgg-->
                AND STATUS = 'LASTRUN';

         SELECT SUM (QTY_AFTER_YIELD)
           INTO TOTAL_QTY_DGI
           FROM RMKTGADM.RC_INV_DGI_HIST
          WHERE     PRODUCT_TYPE = 'E'
                AND PART_ID = DGI_RECORD.PART_ID
                AND STATUS = 'CURRENT';

         SELECT SUM (QTY_ON_HAND_USEBL)
           INTO TOTAL_ONHAND_DGI
           FROM RMKTGADM.RC_INV_DGI_STG
          WHERE     PRODUCT_TYPE = 'E'
                AND REFRESH_PART_NUMBER = DGI_RECORD.PART_ID;

         SELECT SUM (QTY_AFTER_YIELD)
           INTO C3_QTY_DGI
           FROM RMKTGADM.RC_INV_DGI_HIST
          WHERE     PRODUCT_TYPE = 'E'
                AND SOURCE_SYSTEM != 'POE'
                AND PART_ID = DGI_RECORD.PART_ID
                AND STATUS = 'CURRENT';

         SELECT SUM (QTY_ON_HAND_USEBL)
           INTO C3_ONHAND_DGI
           FROM RMKTGADM.RC_INV_DGI_STG
          WHERE     PRODUCT_TYPE = 'E'
                AND SOURCE_SYSTEM != 'POE'
                AND REFRESH_PART_NUMBER = DGI_RECORD.PART_ID;

         SELECT NVL (SUM (AVAILABLE_DGI), 0)
           INTO v_ccw_inv
           FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
          WHERE     PART_NUMBER = DGI_RECORD.PART_ID
                AND INVENTORY_FLOW = 'Excess'
                AND SITE_CODE = 'GDGI';

         SELECT NVL (MIN (STATUS), 'Y')
           INTO v_status
           FROM RC_INV_MIN_DGI
          WHERE     PRODUCT_TYPE = 'E'
                AND SOURCE_SYSTEM != 'POE'
                AND STATUS = 'N'
                AND REFRESH_PART_NUMBER = DGI_RECORD.PART_ID;

         IF     TOTAL_QTY_DGI < 0.5
            AND TOTAL_QTY_DGI > 0
            AND TOTAL_ONHAND_DGI >= 1
            AND C3_QTY_DGI < 0.5
            AND C3_QTY_DGI > 0
            AND C3_ONHAND_DGI >= 1
            AND v_status <> 'N'
            AND LAST_VALUE < 0.5
            AND v_ccw_inv < 1
         THEN
            V_DGI_DELTA := 1;

            /* table to insert DGI for qty less than 1 and track */
            INSERT INTO RC_INV_MIN_DGI (REFRESH_PART_NUMBER,
                                        QTY_ON_HAND_USEBL,
                                        QTY_AFTER_YIELD,
                                        QTY_ADDED,
                                        STATUS,
                                        CREATION_DATE,
                                        LAST_UPDATED_DATE,
                                        LAST_UPDATED_BY,
                                        SOURCE_SYSTEM,
                                        PRODUCT_TYPE)
                 VALUES (DGI_RECORD.PART_ID,
                         C3_ONHAND_DGI,
                         C3_QTY_DGI,
                         V_DGI_DELTA,
                         'N',
                         SYSDATE,
                         SYSDATE,
                         'GDGI DELTA',
                         'C3',
                         'E');
         ELSIF     TOTAL_QTY_DGI < 0.5
               AND TOTAL_QTY_DGI > 0
               AND TOTAL_ONHAND_DGI >= 1
               AND C3_QTY_DGI < 0.5
               AND C3_QTY_DGI > 0
               AND C3_ONHAND_DGI >= 1
               AND v_status <> 'N'
               AND LAST_VALUE > 0.5
               AND v_ccw_inv < 1
         THEN
            V_DGI_DELTA := DGI_RECORD.QTY_AFTER_YIELD - LAST_VALUE + 1;

            INSERT INTO RC_INV_MIN_DGI (REFRESH_PART_NUMBER,
                                        QTY_ON_HAND_USEBL,
                                        QTY_AFTER_YIELD,
                                        QTY_ADDED,
                                        STATUS,
                                        CREATION_DATE,
                                        LAST_UPDATED_DATE,
                                        LAST_UPDATED_BY,
                                        SOURCE_SYSTEM,
                                        PRODUCT_TYPE)
                 VALUES (DGI_RECORD.PART_ID,
                         C3_ONHAND_DGI,
                         C3_QTY_DGI,
                         V_DGI_DELTA,
                         'N',
                         SYSDATE,
                         SYSDATE,
                         'GDGI DELTA',
                         'C3',
                         'E');
         ELSE
            IF     v_status = 'N'
               AND (DGI_RECORD.QTY_AFTER_YIELD - LAST_VALUE) > 0
            THEN
               V_DGI_DELTA := DGI_RECORD.QTY_AFTER_YIELD - LAST_VALUE - 1;

               UPDATE RC_INV_MIN_DGI
                  SET STATUS = 'Y', LAST_UPDATED_DATE = SYSDATE
                WHERE     PRODUCT_TYPE = 'E'
                      AND SOURCE_SYSTEM != 'POE'
                      AND STATUS = 'N'
                      AND REFRESH_PART_NUMBER = DGI_RECORD.PART_ID;
            ELSE
               V_DGI_DELTA := DGI_RECORD.QTY_AFTER_YIELD - LAST_VALUE;
            END IF;
         END IF;

         IF V_DGI_DELTA != 0
         THEN
            INSERT INTO RMKTGADM.RC_INV_DGI_DELTA (INV_LOG_PK,
                                                   PRODUCT_ID,
                                                   DELTA_DGI,
                                                   IS_ROHS,
                                                   --SITE_SHORTNAME,--DeltaAgg-->
                                                   CREATED_ON,
                                                   CREATED_BY,
                                                   PRODUCT_TYPE,
                                                   --INVENTORY_TYPE,--DeltaAgg-->
                                                   SOURCE_SYSTEM,
                                                   POE_BATCH_ID)
                 VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                         -- RMKTGADM.RMK_INV_LOG_PK_SEQ.NEXTVAL,
                         DGI_RECORD.PART_ID,
                         V_DGI_DELTA,
                         DGI_RECORD.ROHS_PID,
                         --DGI_RECORD.SITE_SHORTNAME,  --DeltaAgg-->
                         SYSDATE,
                         'POEADMIN',
                         DGI_RECORD.PRODUCT_TYPE,
                         --DGI_RECORD.INVENTORY_TYPE,     --DeltaAgg-->
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
                                                   --SITE_SHORTNAME,     --DeltaAgg-->
                                                   CREATED_ON,
                                                   CREATED_BY,
                                                   PRODUCT_TYPE,
                                                   --INVENTORY_TYPE,      --DeltaAgg-->
                                                   SOURCE_SYSTEM,
                                                   POE_BATCH_ID)
                 VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                         -- RMKTGADM.RMK_INV_LOG_PK_SEQ.NEXTVAL,
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
                                                   --SITE_SHORTNAME,    --DeltaAgg-->
                                                   CREATED_ON,
                                                   CREATED_BY,
                                                   PRODUCT_TYPE,
                                                   --INVENTORY_TYPE,     --DeltaAgg-->
                                                   SOURCE_SYSTEM,
                                                   POE_BATCH_ID)
                 VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                         -- RMKTGADM.RMK_INV_LOG_PK_SEQ.NEXTVAL,
                         DGI_RECORD_L.PART_ID,
                         - (DGI_RECORD_L.QTY_AFTER_YIELD),
                         DGI_RECORD_L.ROHS_PID,
                         --DGI_RECORD_L.SITE_SHORTNAME,     --DeltaAgg-->
                         SYSDATE,
                         'POEADMIN',
                         DGI_RECORD_L.PRODUCT_TYPE,
                         --DGI_RECORD_L.INVENTORY_TYPE,      --DeltaAgg-->
                         DGI_RECORD_L.SOURCE_SYSTEM,
                         'DGI_LASTRUN');
         END IF;
      END LOOP;

      CLOSE DGI_CURSOR_LAST;

      UPDATE RMKTGADM.RC_INV_DGI_HIST
         SET STATUS = 'HISTORY'
       WHERE     PRODUCT_TYPE = 'E'
             AND STATUS = 'LASTRUN'
             AND SOURCE_SYSTEM != 'POE'; --Added this condition part of US398932 by Satyredd on 11th Aug 2020;

      UPDATE RMKTGADM.RC_INV_DGI_HIST
         SET STATUS = 'LASTRUN'
       WHERE     PRODUCT_TYPE = 'E'
             AND STATUS = 'CURRENT'
             AND SOURCE_SYSTEM != 'POE'; --Added this condition part of US398932 by Satyredd on 11th Aug 2020;

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
                   P_SITE_CODE,                                       -- NULL,
                   'RC_INV_DELTA_LOAD_EX');

      G_PROC_NAME := 'RC_INV_EX_DGI_DELTA';
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
                      P_SITE_CODE || '-' || G_ERROR_MSG,     --   G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_EX');

         G_PROC_NAME := 'RC_INV_EX_DGI_DELTA';

         COMMIT;

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_EX_DGI_DELTA;

   PROCEDURE RC_INV_EX_FGI_EXTRACT (P_SITE_CODE IN VARCHAR2)
   IS
      CURSOR FGI_CURSOR_DELTA
      IS
         --         SELECT TO_CHAR (LRO.TRANSACTION_ID) TRANSACTION_ID,
         --                LRO.REFRESH_PART_NUMBER,
         --                LRO.TOTAL_QTY,
         --                decode(LRO.ROHS_FLAG, 'Y','YES','N','NO','YES') IS_ROHS,
         --                --'YES' IS_ROHS,
         --                LRO.HUB_LOCATION INVENTORY_SITE,
         --                --RECORD_CREATED_ON CREATION_DATE,
         --                sysdate CREATION_DATE,
         --                LRO.RECORD_CREATED_BY CREATED_BY,
         --                TO_NUMBER (LRO.PO_LINE_NUMBER) LINE_NO,
         --                'SC-EXCESS-FB02-LRO' SOURCE_SYSTEM,
         --                'E' PRODUCT_TYPE
         --           FROM CRPSC.SC_FB02_DELTA_LRO_HIST LRO
         --                INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
         --                   ON (LRO.REFRESH_PART_NUMBER = PM.REFRESH_PART_NUMBER)
         --          WHERE     1 = 1
         --                AND PM.PROGRAM_TYPE = 1
         --                AND LRO.PROCESSED_STATUS = 'N'
         --                AND LRO.TOTAL_QTY > 0
         --                AND LRO.REFRESH_PART_NUMBER NOT IN (SELECT REFRESH_PART_NUMBER FROM RC_INV_EXCLUDE_PIDS)
         --         UNION ALL
         -- >> FVE
         SELECT TO_CHAR (FVE.TRANSACTION_ID)   TRANSACTION_ID,
                FVE.REFRESH_PART_NUMBER,
                FVE.RECEIVED_QTY               TOTAL_QTY,
                'YES'                          IS_ROHS,
                FVE.HUB_LOCATION               INVENTORY_SITE,
                -- RECORD_CREATED_ON CREATION_DATE,
                SYSDATE                        CREATION_DATE,
                FVE.RECORD_CREATED_BY          CREATED_BY,
                TO_NUMBER (FVE.PO_LINE_NUMBER) LINE_NO,
                'SC-EXCESS-FC01-FVE'           SOURCE_SYSTEM,
                'E'                            PRODUCT_TYPE
           FROM                             --CRPSC.SC_FB02_DELTA_FVE_HIST FVE
               CRPSC.RC_FC01_OH_DELTA_FVE_HIST  FVE --Added as part of US390864
                INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                   ON (FVE.REFRESH_PART_NUMBER = PM.REFRESH_PART_NUMBER)
          WHERE     1 = 1
                AND PM.PROGRAM_TYPE = 1
                AND FVE.PROCESSED_STATUS = 'N'
                AND FVE.RECEIVED_QTY > 0 -- Temporarily commented to Process -VE FVE Feed to CCW
                --AND FVE.PO_NUMBER LIKE 'CSC%'     --commented as part of US390864
                AND FVE.HUB_LOCATION = P_SITE_CODE
                AND PM.REFRESH_PART_NUMBER NOT IN
                       (SELECT REFRESH_PART_NUMBER
                          FROM RC_INV_EXCLUDE_PIDS)
         UNION ALL
         -->> LRO                                               -->> (Integrating LRO FC01 Receipts OH)
         SELECT TO_CHAR (LRO.TRANSACTION_ID)   POE_BATCH_ID,
                LRO.REFRESH_PART_NUMBER        PRODUCT_ID,
                LRO.RECEIVED_QTY               TOTAL_QTY,
                ROHS_FLAG,
                LRO.HUB_LOCATION               INVENTORY_SITE,
                --RECORD_CREATED_ON CREATED_ON,
                SYSDATE                        CREATION_DATE,
                LRO.RECORD_CREATED_BY          CREATED_BY,
                TO_NUMBER (LRO.PO_LINE_NUMBER) LINE_NO,
                'SC-FC01-RECEIPTS-LRO'         SOURCE_SYSTEM,
                'E'                            PRODUCT_TYPE
           FROM CRPSC.SC_FC01_OH_DELTA_LRO_HIST LRO
                INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                   ON (LRO.REFRESH_PART_NUMBER = PM.REFRESH_PART_NUMBER)
          WHERE     1 = 1
                AND PM.PROGRAM_TYPE = 1
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
      G_PROC_NAME := 'RC_INV_EX_FGI_EXTRACT';

      L_START_TIME := SYSDATE;


      DELETE FROM RC_INV_FGI_DELTA
            WHERE PRODUCT_TYPE = 'E';


      OPEN FGI_CURSOR_DELTA;

      LOOP
         FETCH FGI_CURSOR_DELTA INTO FGI_INV_RECORD;

         EXIT WHEN FGI_CURSOR_DELTA%NOTFOUND;


         BEGIN
            INSERT INTO RMKTGADM.RC_INV_FGI_DELTA (PRODUCT_ID,
                                                   DELTA_FGI,
                                                   IS_ROHS,
                                                   SITE_SHORTNAME,
                                                   CREATED_ON,
                                                   CREATED_BY,
                                                   UPDATED_ON,
                                                   UPDATED_BY,
                                                   PRODUCT_TYPE,
                                                   SOURCE_SYSTEM)
                 VALUES (FGI_INV_RECORD.REFRESH_PART_NUMBER,
                         FGI_INV_RECORD.TOTAL_QTY,
                         FGI_INV_RECORD.IS_ROHS,
                         FGI_INV_RECORD.INVENTORY_SITE,
                         FGI_INV_RECORD.CREATION_DATE,
                         FGI_INV_RECORD.CREATED_BY,
                         SYSDATE,
                         G_UPDATED_BY,
                         FGI_INV_RECORD.PRODUCT_TYPE,
                         FGI_INV_RECORD.SOURCE_SYSTEM);

            L_PROCESSED_FLAG := 'Y';
         EXCEPTION
            WHEN OTHERS
            THEN
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
                   AND TO_CHAR (TRANSACTION_ID) =
                          FGI_INV_RECORD.TRANSACTION_ID
                   AND REFRESH_PART_NUMBER =
                          FGI_INV_RECORD.REFRESH_PART_NUMBER
                   AND REFRESH_PART_NUMBER IN
                          (SELECT REFRESH_PART_NUMBER
                             FROM CRPADM.RC_PRODUCT_MASTER
                            WHERE PROGRAM_TYPE = 1);

            /*----------------------Updating PROCESSED_STATUS as 'Y' in SC_FB02_DELTA_FVE table--------------------------------------------*/
            --commented as part of US390864
            --            UPDATE CRPSC.SC_FB02_DELTA_FVE_HIST
            --               SET PROCESSED_STATUS = 'Y'
            --             WHERE     PROCESSED_STATUS = 'N'
            --                   AND TO_NUMBER (PO_LINE_NUMBER) = FGI_INV_RECORD.LINE_NO
            --                   AND TO_CHAR (TRANSACTION_ID) =
            --                          FGI_INV_RECORD.TRANSACTION_ID
            --                   AND REFRESH_PART_NUMBER =
            --                          FGI_INV_RECORD.REFRESH_PART_NUMBER
            --                   AND REFRESH_PART_NUMBER IN
            --                          (SELECT REFRESH_PART_NUMBER
            --                             FROM CRPADM.RC_PRODUCT_MASTER
            --                            WHERE PROGRAM_TYPE = 1);
            --Added as part of US390864
            UPDATE CRPSC.RC_FC01_OH_DELTA_FVE_HIST
               SET PROCESSED_STATUS = 'Y'
             WHERE     PROCESSED_STATUS = 'N'
                   AND TO_NUMBER (PO_LINE_NUMBER) = FGI_INV_RECORD.LINE_NO
                   AND TO_CHAR (TRANSACTION_ID) =
                          FGI_INV_RECORD.TRANSACTION_ID
                   AND REFRESH_PART_NUMBER =
                          FGI_INV_RECORD.REFRESH_PART_NUMBER
                   AND REFRESH_PART_NUMBER IN
                          (SELECT REFRESH_PART_NUMBER
                             FROM CRPADM.RC_PRODUCT_MASTER
                            WHERE PROGRAM_TYPE = 1);
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
                   P_SITE_CODE,                                       -- NULL,
                   'RC_INV_DELTA_LOAD_EX');

      UPDATE RMKTGADM.CRON_CONTROL_INFO
         SET CRON_START_TIMESTAMP = G_START_TIME,
             CRON_END_TIMESTAMP = SYSDATE,
             CRON_STATUS = 'SUCCESS'
       WHERE     CRON_NAME = 'RC_INV_EX_FGI_EXTRACT'
             AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'EX_MAIN';

      G_PROC_NAME := 'RC_INV_EX_FGI_EXTRACT';

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
                      'RC_INV_DELTA_LOAD_EX');

         --         G_PROC_NAME := 'RC_INV_EX_FGI_EXTRACT';

         UPDATE RMKTGADM.CRON_CONTROL_INFO
            SET CRON_START_TIMESTAMP = G_START_TIME,
                CRON_END_TIMESTAMP = SYSDATE,
                CRON_STATUS = 'FAILED'
          WHERE     CRON_NAME = 'RC_INV_EX_FGI_EXTRACT'
                AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'EX_MAIN'; -->>Added

         COMMIT;

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_EX_FGI_EXTRACT;

   /* Start Modified RC_INV_EX_FGI_ROHS_NROHS_MOVE as there was RoHS/Non RoHS Movements Issue on 3rd Aug 2018 by sridvasu */

   /* Start Rohs/NRohs move as part of US164572 on 02-APR-2018 */

   PROCEDURE RC_INV_EX_FGI_ROHS_NROHS_MOVE
   IS
      CURSOR ROHS_NROHS_ADJ
      IS
         SELECT DISTINCT
                pm.refresh_part_number,
                mv.part_no,
                'LRO' Site_Code,
                'NO'  ROHS_COMPLIANT,
                  --
                  NVL (
                     (SELECT SUM (available_fgi)
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
                                       'WS', 'Excess')
                             AND mv.direction = '-'),
                     0)
                + NVL (
                     (SELECT SUM (delta_fgi)
                        FROM rc_inv_fgi_delta fgi
                       WHERE     fgi.product_id = pm.refresh_part_number
                             AND fgi.site_shortname = 'LRO'
                             AND fgi.is_rohs = 'YES' --and fgi.is_rohs = decode( substr(mv.MOVE_FROM_LOC,1,10), 'LRO-INV.RH' ,'YES', 'LRO-INV.NR', 'NO')
                             AND fgi.product_type =
                                    DECODE (
                                       SUBSTR (
                                          refresh_part_number,
                                          LENGTH (refresh_part_number) - 1,
                                          2),
                                       'WS', 'E')
                             AND mv.direction = '-'),
                     0)
                   rohs_excess_qty,
                  --
                  NVL (
                     (SELECT SUM (available_fgi)
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
                                       'WS', 'Excess')
                             AND mv.direction = '-'),
                     0)
                + NVL (
                     (SELECT SUM (delta_fgi)
                        FROM rc_inv_fgi_delta fgi
                       WHERE     fgi.product_id = pm.refresh_part_number
                             AND fgi.site_shortname = 'LRO'
                             AND fgi.is_rohs = 'NO' --and fgi.is_rohs = decode( substr(mv.MOVE_FROM_LOC,1,10), 'LRO-INV.RH' ,'YES', 'LRO-INV.NR', 'NO')
                             AND fgi.product_type =
                                    DECODE (
                                       SUBSTR (
                                          refresh_part_number,
                                          LENGTH (refresh_part_number) - 1,
                                          2),
                                       'WS', 'E')
                             AND mv.direction = '-'),
                     0)
                   nrohs_excess_qty,
                  --
                  --               NVL (
                  --                  (  SELECT SUM (imv.quantity)
                  --                       FROM CRPSC.RC_DLP_ROHS_NONROHS imv
                  --                      WHERE     mv.part_no = imv.part_no
                  --                            AND SUBSTR (mv.MOVE_FROM_LOC, 1, 10) =
                  --                                   SUBSTR (imv.MOVE_FROM_LOC, 1, 10) AND PROCESSED_FLAG = 'N'
                  --                            AND imv.direction = '-'
                  --                   GROUP BY part_no),
                  --                  0)
                  --                  Adjustment_Qty
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
                   Adjustment_Qty
           FROM CRPSC.RC_DLP_ROHS_NONROHS mv
                INNER JOIN crpadm.rc_product_master pm
                   ON (mv.part_no = pm.tan_id)
          WHERE refresh_part_number LIKE '%WS' AND processed_flag = 'N';

      --               and pm.tan_id not in (select y.part_no
      --                                            from
      --                                            ( select part_no, sum(quantity) adjustment_qty from CRPSC.RC_DLP_ROHS_NONROHS where substr(MOVE_FROM_LOC,1,10) = 'LRO-INV.RH' and processed_flag = 'N' group by part_no) y ,
      --                                            ( select part_no, sum(quantity) adjustment_qty from CRPSC.RC_DLP_ROHS_NONROHS where SUBSTR (MOVE_FROM_LOC, 1, 10) = 'LRO-INV.NR' and processed_flag = 'N' group by part_no) n
      --                                            where y.part_no = n.part_no
      --                                            and y.adjustment_qty - n.adjustment_qty = 0
      --                                            );  -->> Summing up the quantity for the PIDs which are having from and to locations are same on 04-MAY-2018
      -->> if the from and to loc are matched with quantity then ignoring those pids.
      --               and (pm.refresh_part_number NOT IN (SELECT PRODUCT_ID
      --                                                   FROM rc_inv_fgi_delta fgi
      --                                                  WHERE     fgi.PRODUCT_ID =
      --                                                               pm.refresh_part_number
      --                                                        AND is_rohs = 'YES' AND site_shortname = 'LRO')
      --               OR pm.refresh_part_number NOT IN (SELECT PRODUCT_ID
      --                                                   FROM rc_inv_fgi_delta fgi
      --                                                  WHERE  fgi.PRODUCT_ID =
      --                                                               pm.refresh_part_number
      --                                                        AND is_rohs = 'NO' AND site_shortname = 'LRO') );

      ROHS_NROHS_REC     ROHS_NROHS_ADJ%ROWTYPE;

      L_START_TIME       DATE;
      NROHS_ADJ_QTY      NUMBER;
      ROHS_ADJ_QTY       NUMBER;
      V_ROHS_COMPLIANT   VARCHAR2 (100);
      V_ADJUSTMENT_QTY   NUMBER;
   BEGIN
      G_PROC_NAME := 'RC_INV_EX_FGI_ROHS_NROHS_MOVE';

      L_START_TIME := SYSDATE;

      OPEN ROHS_NROHS_ADJ;

      LOOP
         FETCH ROHS_NROHS_ADJ INTO ROHS_NROHS_REC;

         EXIT WHEN ROHS_NROHS_ADJ%NOTFOUND;


         IF ROHS_NROHS_REC.ADJUSTMENT_QTY < 0
         THEN
            V_ROHS_COMPLIANT := 'YES';

            V_ADJUSTMENT_QTY := ABS (ROHS_NROHS_REC.ADJUSTMENT_QTY);

            IF ROHS_NROHS_REC.ROHS_EXCESS_QTY >= V_ADJUSTMENT_QTY
            THEN
               NROHS_ADJ_QTY := V_ADJUSTMENT_QTY;                        -- 17
               ROHS_ADJ_QTY := -V_ADJUSTMENT_QTY;
            ELSE
               NROHS_ADJ_QTY := ROHS_NROHS_REC.ROHS_EXCESS_QTY;
               ROHS_ADJ_QTY := -ROHS_NROHS_REC.ROHS_EXCESS_QTY;

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
                       NROHS_ADJ_QTY,
                       'Y',
                       SYSDATE,
                       'RC_INV_EX_FGI_ROHS_NROHS_MOVE',
                       SYSDATE,
                       'RC_INV_EX_FGI_ROHS_NROHS_MOVE');
            END IF;


            INSERT INTO ROHS_NROHS_MOVE_ADJ_EX
                 VALUES (ROHS_NROHS_REC.REFRESH_PART_NUMBER,
                         ROHS_NROHS_REC.PART_NO,
                         ROHS_NROHS_REC.SITE_CODE,
                         ROHS_NROHS_REC.ROHS_COMPLIANT,
                         ROHS_NROHS_REC.ADJUSTMENT_QTY,
                         ROHS_NROHS_REC.ROHS_EXCESS_QTY,
                         ROHS_NROHS_REC.NROHS_EXCESS_QTY,
                         ROHS_ADJ_QTY,
                         NROHS_ADJ_QTY,
                         SYSDATE,
                         'RC_INV_EX_FGI_ROHS_NROHS_MOVE',
                         SYSDATE,
                         'RC_INV_EX_FGI_ROHS_NROHS_MOVE');

            -->> insert for Excess ROHS adjustment

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
                         ROHS_ADJ_QTY,
                         0,
                         'YES',
                         ROHS_NROHS_REC.SITE_CODE,
                         'N',
                         SYSDATE,
                         'POEADMIN',
                         SYSDATE,
                         'POEADMIN',
                         'RC_INV_EX_FGI_ROHS_NROHS_MOVE',
                         'E');

            -->> insert for Excess NON ROHS adjustment

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
                         NROHS_ADJ_QTY,
                         0,
                         'NO',
                         ROHS_NROHS_REC.SITE_CODE,
                         'N',
                         SYSDATE,
                         'POEADMIN',
                         SYSDATE,
                         'POEADMIN',
                         'RC_INV_EX_FGI_ROHS_NROHS_MOVE',
                         'E');
         ELSIF ROHS_NROHS_REC.ADJUSTMENT_QTY > 0
         THEN
            V_ROHS_COMPLIANT := 'NO';

            V_ADJUSTMENT_QTY := ROHS_NROHS_REC.ADJUSTMENT_QTY;

            IF ROHS_NROHS_REC.NROHS_EXCESS_QTY >= V_ADJUSTMENT_QTY
            THEN
               ROHS_ADJ_QTY := V_ADJUSTMENT_QTY;                         -- 17
               NROHS_ADJ_QTY := -V_ADJUSTMENT_QTY;
            ELSE
               ROHS_ADJ_QTY := ROHS_NROHS_REC.NROHS_EXCESS_QTY;
               NROHS_ADJ_QTY := -ROHS_NROHS_REC.NROHS_EXCESS_QTY;

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
                       ROHS_ADJ_QTY,
                       'Y',
                       SYSDATE,
                       'RC_INV_EX_FGI_ROHS_NROHS_MOVE',
                       SYSDATE,
                       'RC_INV_EX_FGI_ROHS_NROHS_MOVE');
            END IF;


            INSERT INTO ROHS_NROHS_MOVE_ADJ_EX
                 VALUES (ROHS_NROHS_REC.REFRESH_PART_NUMBER,
                         ROHS_NROHS_REC.PART_NO,
                         ROHS_NROHS_REC.SITE_CODE,
                         ROHS_NROHS_REC.ROHS_COMPLIANT,
                         ROHS_NROHS_REC.ADJUSTMENT_QTY,
                         ROHS_NROHS_REC.ROHS_EXCESS_QTY,
                         ROHS_NROHS_REC.NROHS_EXCESS_QTY,
                         ROHS_ADJ_QTY,
                         NROHS_ADJ_QTY,
                         SYSDATE,
                         'RC_INV_EX_FGI_ROHS_NROHS_MOVE',
                         SYSDATE,
                         'RC_INV_EX_FGI_ROHS_NROHS_MOVE');


            -->> insert for Excess ROHS adjustment

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
                         ROHS_ADJ_QTY,
                         0,
                         'YES',
                         ROHS_NROHS_REC.SITE_CODE,
                         'N',
                         SYSDATE,
                         'POEADMIN',
                         SYSDATE,
                         'POEADMIN',
                         'RC_INV_EX_FGI_ROHS_NROHS_MOVE',
                         'E');


            -->> insert for Excess NON ROHS adjustment

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
                         NROHS_ADJ_QTY,
                         0,
                         'NO',
                         ROHS_NROHS_REC.SITE_CODE,
                         'N',
                         SYSDATE,
                         'POEADMIN',
                         SYSDATE,
                         'POEADMIN',
                         'RC_INV_EX_FGI_ROHS_NROHS_MOVE',
                         'E');
         ELSIF ROHS_NROHS_REC.ADJUSTMENT_QTY > 0
         THEN
            ROHS_ADJ_QTY := 0;
            NROHS_ADJ_QTY := 0;
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
      --                                            )
      --              and part_no in (select tan_id from crpadm.rc_product_master where refresh_part_number like '%WS');
      --
      --    COMMIT;

      /* End Added update statement to flag the records which are having same location same qty adjustment to Y on 04-MAY-2018 */


      DELETE FROM RMKTGADM.RMK_INVENTORY_LOG_STG
            WHERE     NEW_FGI = 0
                  AND POE_BATCH_ID = 'RC_INV_EX_FGI_ROHS_NROHS_MOVE';

      --to Insert the Delta inv into  rmk_inventory_log from  rmk_inventory_log_stg
      INSERT INTO RMK_INVENTORY_LOG
         SELECT *
           FROM RMK_INVENTORY_LOG_STG
          WHERE     ATTRIBUTE1 IS NULL
                AND POE_BATCH_ID = 'RC_INV_EX_FGI_ROHS_NROHS_MOVE';

      --Updating the rmk_inventory_log_stg table after processing the Delta Inv.
      UPDATE RMK_INVENTORY_LOG_STG
         SET ATTRIBUTE1 = 'PROCESSED'
       WHERE     ATTRIBUTE1 IS NULL
             AND POE_BATCH_ID = 'RC_INV_EX_FGI_ROHS_NROHS_MOVE';

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
                   'RC_INV_DELTA_LOAD_EX');
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
                      'RC_INV_DELTA_LOAD_EX');

         G_PROC_NAME := 'RC_INV_EX_FGI_ROHS_NROHS_MOVE';

         COMMIT;

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_EX_FGI_ROHS_NROHS_MOVE;

   /* End Rohs/NRohs move as part of US164572 on 02-APR-2018 */

   /* End Modified RC_INV_EX_FGI_ROHS_NROHS_MOVE as there was RoHS/Non RoHS Movements Issue on 3rd Aug 2018 by sridvasu */

   PROCEDURE RC_INV_EX_DGI_PUT_REMINDERS
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
            WHERE PRODUCT_TYPE = 'E' AND SOURCE_SYSTEM != 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
         GROUP BY PRODUCT_ID, PRODUCT_TYPE,               -->> SITE_SHORTNAME,
                                           SOURCE_SYSTEM;

      -->>INVENTORY_TYPE;

      /**End modified cursor as part of Apr 17 Release for Rounding at product level**/


      DGI_INV_RECORD     DGI_CURSOR_DELTA%ROWTYPE;
      V_INV_LOG_PK       NUMBER; --Added as part of Apr 17 Release for Rounding at product level
      L_START_TIME       DATE;
   BEGIN
      G_PROC_NAME := 'RC_INV_EX_DGI_PUT_REMINDERS';

      L_START_TIME := SYSDATE;

      OPEN DGI_CURSOR_DELTA;

      LOOP
         FETCH DGI_CURSOR_DELTA INTO DGI_INV_RECORD;

         EXIT WHEN DGI_CURSOR_DELTA%NOTFOUND;

         --select  delta_dgi,Round(delta_dgi), Round(delta_dgi)-delta_dgi from RC_INV_DGI_DELTA

         /* Start Modified logic for Negative DGI Scenario on 04-FEB-2019 */

         IF DGI_INV_RECORD.DELTA_DGI >= 0
         THEN
            V_REMINDER_VALUE :=
               ROUND (DGI_INV_RECORD.DELTA_DGI) - DGI_INV_RECORD.DELTA_DGI;

            IF (V_REMINDER_VALUE) != 0
            THEN
               INSERT
                 INTO RMKTGADM.RC_INV_DGI_ROUNDED_VALUES (INV_LOG_PK,
                                                          PRODUCT_ID,
                                                          --SITE_SHORTNAME,
                                                          REMINDER_VALUE,
                                                          PROCESSED_STATUS,
                                                          CREATED_BY,
                                                          CREATION_DATE,
                                                          LAST_UPDATED_DATE,
                                                          LAST_UPDATED_BY,
                                                          PRODUCT_TYPE,
                                                          --INVENTORY_TYPE,
                                                          SOURCE_SYSTEM)
               VALUES (V_INV_LOG_PK,
                       DGI_INV_RECORD.PRODUCT_ID,
                       -- DGI_INV_RECORD.SITE_SHORTNAME,
                       - (V_REMINDER_VALUE),
                       'N',
                       'POEADMIN',
                       SYSDATE,
                       SYSDATE,
                       'POEADMIN',
                       DGI_INV_RECORD.PRODUCT_TYPE,
                       --DGI_INV_RECORD.INVENTORY_TYPE,
                       DGI_INV_RECORD.SOURCE_SYSTEM);

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
         ELSIF DGI_INV_RECORD.DELTA_DGI < 0
         THEN
            V_REMINDER_VALUE :=
                 - (FLOOR (ABS (DGI_INV_RECORD.DELTA_DGI)))
               - DGI_INV_RECORD.DELTA_DGI;

            IF (V_REMINDER_VALUE) != 0
            THEN
               INSERT
                 INTO RMKTGADM.RC_INV_DGI_ROUNDED_VALUES (INV_LOG_PK,
                                                          PRODUCT_ID,
                                                          --SITE_SHORTNAME,
                                                          REMINDER_VALUE,
                                                          PROCESSED_STATUS,
                                                          CREATED_BY,
                                                          CREATION_DATE,
                                                          LAST_UPDATED_DATE,
                                                          LAST_UPDATED_BY,
                                                          PRODUCT_TYPE,
                                                          --INVENTORY_TYPE,
                                                          SOURCE_SYSTEM)
               VALUES (V_INV_LOG_PK,
                       DGI_INV_RECORD.PRODUCT_ID,
                       -- DGI_INV_RECORD.SITE_SHORTNAME,
                       - (V_REMINDER_VALUE),
                       'N',
                       'POEADMIN',
                       SYSDATE,
                       SYSDATE,
                       'POEADMIN',
                       DGI_INV_RECORD.PRODUCT_TYPE,
                       --DGI_INV_RECORD.INVENTORY_TYPE,
                       DGI_INV_RECORD.SOURCE_SYSTEM);

               UPDATE RMKTGADM.RC_INV_DGI_DELTA
                  SET DELTA_DGI = - (FLOOR (ABS (DGI_INV_RECORD.DELTA_DGI)))
                WHERE     1 = 1
                      AND PRODUCT_ID = DGI_INV_RECORD.PRODUCT_ID
                      -->> AND SITE_SHORTNAME = DGI_INV_RECORD.SITE_SHORTNAME
                      AND PRODUCT_TYPE = DGI_INV_RECORD.PRODUCT_TYPE
                      AND SOURCE_SYSTEM = DGI_INV_RECORD.SOURCE_SYSTEM;

               -->> AND INVENTORY_TYPE = DGI_INV_RECORD.INVENTORY_TYPE;-- Commented as part of Apr 17 Release for Rounding at product level
               COMMIT;
            END IF;
         END IF;
      /* End Modified logic for Negative DGI Scenario on 04-FEB-2019 */

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
                   'RC_INV_DELTA_LOAD_EX');

      G_PROC_NAME := 'RC_INV_EX_DGI_PUT_REMINDERS';
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
                      'RC_INV_DELTA_LOAD_EX');

         G_PROC_NAME := 'RC_INV_EX_DGI_PUT_REMINDERS';

         COMMIT;

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_EX_DGI_PUT_REMINDERS;

   PROCEDURE RC_INV_EX_DGI_GET_REMINDERS
   IS
      V_ROUND_VALUE      NUMBER (10, 2);
      V_REMINDER_VALUE   NUMBER (10, 2);
      V_DELTA_DGI        NUMBER (10, 2);
      V_INV_LOG_PK       NUMBER;
      V_ROHS_SITE        VARCHAR (3);
      L_START_TIME       DATE;

      --V_POE_BATCH_ID     VARCHAR2 (100);

      CURSOR DGI_CURSOR_RND
      IS
           SELECT PRODUCT_ID, PRODUCT_TYPE, SUM (REMINDER_VALUE) AS DELTA_DGI
             --     SITE_SHORTNAME
             --    INVENTORY_TYPE,  --Commented as part of Apr 17 Release for Rounding at product level
             --     SOURCE_SYSTEM    --Commented as part of Apr 17 Release for Rounding at product level
             FROM RMKTGADM.RC_INV_DGI_ROUNDED_VALUES
            WHERE     PROCESSED_STATUS = 'N'
                  AND PRODUCT_TYPE = 'E'
                  AND SOURCE_SYSTEM != 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
         GROUP BY PRODUCT_ID, PRODUCT_TYPE              -->>> , SITE_SHORTNAME
           --      INVENTORY_TYPE,   --Commented as part of Apr 17 Release for Rounding at product level
           --      SOURCE_SYSTEM     --Commented as part of Apr 17 Release for Rounding at product level
           HAVING SUM (REMINDER_VALUE) >= 1 OR SUM (REMINDER_VALUE) <= -1;

      DGI_RND_REC        DGI_CURSOR_RND%ROWTYPE;
   BEGIN
      G_PROC_NAME := 'RC_INV_EX_DGI_GET_REMINDERS';

      L_START_TIME := SYSDATE;

      OPEN DGI_CURSOR_RND;

      LOOP
         FETCH DGI_CURSOR_RND INTO DGI_RND_REC;

         EXIT WHEN DGI_CURSOR_RND%NOTFOUND;

         /* Start Modified logic for Negative DGI Scenario on 04-FEB-2019 */

         IF DGI_RND_REC.DELTA_DGI >= 0
         THEN
            V_ROUND_VALUE := ROUND (DGI_RND_REC.DELTA_DGI);
         ELSIF DGI_RND_REC.DELTA_DGI < 0
         THEN
            V_ROUND_VALUE := - (FLOOR (ABS (DGI_RND_REC.DELTA_DGI)));
         END IF;

         /* End Modified logic for Negative DGI Scenario on 04-FEB-2019 */

         IF (V_ROUND_VALUE <= -1) OR (V_ROUND_VALUE >= 1)
         THEN
            UPDATE RMKTGADM.RC_INV_DGI_ROUNDED_VALUES
               SET PROCESSED_STATUS = 'Y', LAST_UPDATED_DATE = SYSDATE
             WHERE     PRODUCT_ID = DGI_RND_REC.PRODUCT_ID
                   --   AND SITE_SHORTNAME = DGI_RND_REC.SITE_SHORTNAME
                   AND PROCESSED_STATUS = 'N'
                   AND SOURCE_SYSTEM != 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                   AND PRODUCT_TYPE = DGI_RND_REC.PRODUCT_TYPE;



            V_INV_LOG_PK := RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL; -- RMK_INV_LOG_PK_SEQ.NEXTVAL;


            INSERT INTO RMKTGADM.RC_INV_DGI_DELTA (INV_LOG_PK,
                                                   PRODUCT_ID,
                                                   DELTA_DGI,
                                                   IS_ROHS,
                                                   --   SITE_SHORTNAME,
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

            /* Start Modified logic for Negative DGI Scenario on 04-FEB-2019 */

            IF DGI_RND_REC.DELTA_DGI >= 0
            THEN
               V_REMINDER_VALUE :=
                  ROUND (DGI_RND_REC.DELTA_DGI) - DGI_RND_REC.DELTA_DGI;
            ELSIF DGI_RND_REC.DELTA_DGI < 0
            THEN
               V_REMINDER_VALUE :=
                    -FLOOR (ABS (DGI_RND_REC.DELTA_DGI))
                  - DGI_RND_REC.DELTA_DGI;
            END IF;

            /* End Modified logic for Negative DGI Scenario on 04-FEB-2019 */

            IF V_REMINDER_VALUE != 0
            THEN
               INSERT
                 INTO RMKTGADM.RC_INV_DGI_ROUNDED_VALUES (INV_LOG_PK,
                                                          PRODUCT_ID,
                                                          --       SITE_SHORTNAME,
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
                       --         DGI_RND_REC.SITE_SHORTNAME,
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
                   'RC_INV_DELTA_LOAD_EX');

      G_PROC_NAME := 'RC_INV_EX_DGI_GET_REMINDERS';
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
                      'RC_INV_DELTA_LOAD_EX');

         G_PROC_NAME := 'RC_INV_EX_DGI_GET_REMINDERS';

         COMMIT;

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_EX_DGI_GET_REMINDERS;

   --Commented as part of US390864
   ---------------------------------------------------------------------------------------------------------------------------------------
   --   PROCEDURE RC_INV_EX_DGI_FGI_LOAD (P_SITE_CODE IN VARCHAR2)
   --   IS
   --      /*** Start added as part of multiple rows fix(inserting multiple rows for same product) as part of APR 17 Sprint release***/
   --      CURSOR DGI_DELTA
   --      IS
   --           SELECT DGI.PRODUCT_ID,
   --                  SUM (DGI.DELTA_DGI) DELTA_DGI,
   --                  DGI.PRODUCT_TYPE,
   --                  DGI.SOURCE_SYSTEM
   --             FROM RMKTGADM.RC_INV_DGI_DELTA DGI
   --            WHERE 1 = 1 AND DGI.PRODUCT_TYPE = 'E'
   --         GROUP BY DGI.PRODUCT_ID, DGI.PRODUCT_TYPE, DGI.SOURCE_SYSTEM;
   --
   --      DGI_DELTA_REC           DGI_DELTA%ROWTYPE;
   --      L_START_TIME            DATE;
   --      /*** End added as part of multiple rows fix(inserting multiple rows for same product) as part of APR 17 Sprint release***/
   --
   --      --(Start) added by mohamms2 as on 05-OCT-2017 for User Story US134524 -> PID Deactivation changes - restrict DGI for T-4 PIDs
   --      L_AVAL_TO_RESERVE_DGI   NUMBER := 0;
   --      L_EOS_FLAG              VARCHAR2 (10) := 'N';
   --      L_DELTA_DGI             NUMBER := 0;
   --      L_AVAL_DGI              NUMBER := 0;
   --   --(End) added by mohamms2 as on 05-OCT-2017 for User Story US134524 -> PID Deactivation changes - restrict DGI for T-4 PIDs
   --
   --   BEGIN
   --      G_PROC_NAME := 'RC_INV_EX_DGI_FGI_LOAD';
   --
   --      L_START_TIME := SYSDATE;
   --
   --
   --      ---Start Added as part of APR 17 Sprint Release
   --
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
   --                           AND INVENTORY_FLOW = 'Excess'
   --                           AND SITE_CODE = 'GDGI'
   --                           AND ROHS_COMPLIANT = 'YES')
   --                      AVAILABLE_TO_RESERVE_DGI,
   --                   (SELECT SUM (AVAILABLE_DGI)
   --                      FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
   --                     WHERE     PART_NUMBER = PM.REFRESH_PART_NUMBER
   --                           AND INVENTORY_FLOW = 'Excess'
   --                           AND SITE_CODE = 'GDGI'
   --                           AND ROHS_COMPLIANT = 'YES')
   --                      AVAILABLE_DGI,
   --                   (SELECT NVL (SUM (DGI.DELTA_DGI), 0)
   --                      FROM RMKTGADM.RC_INV_DGI_DELTA DGI
   --                     WHERE     DGI.PRODUCT_TYPE = 'E'
   --                           AND DGI.PRODUCT_ID = DGI_DELTA_REC.PRODUCT_ID
   --                           AND DGI.PRODUCT_TYPE = 'E'
   --                           --   AND dgi.is_rohs = 'YES'
   --                           --   AND dgi.site_shortname = 'GDGI'
   --                           AND NOT EXISTS
   --                                  (SELECT 1
   --                                     FROM RMKTGADM.RMK_INVENTORY_LOG_STG STG
   --                                    WHERE     STG.PART_NUMBER =
   --                                                 DGI.PRODUCT_ID
   --                                          AND STG.ROHS_COMPLIANT = 'YES'
   --                                          AND STG.SITE_CODE = 'GDGI' --dgi.site_shortname
   --                                          AND PROGRAM_TYPE = DGI.PRODUCT_TYPE
   --                                          AND CREATED_ON >
   --                                                 SYSDATE - 1 / 24 * 0.5))
   --                      DELTA_DGI
   --              INTO L_EOS_FLAG,
   --                   L_AVAL_TO_RESERVE_DGI,
   --                   L_AVAL_DGI,
   --                   L_DELTA_DGI
   --              FROM CRPADM.RC_PRODUCT_MASTER PM
   --             WHERE     PM.REFRESH_PART_NUMBER = DGI_DELTA_REC.PRODUCT_ID
   --                   AND PROGRAM_TYPE = 1
   --                   AND NVL (PM.MFG_EOS_DATE, SYSDATE + 130) <=
   --                          ADD_MONTHS (TRUNC (SYSDATE), 4);
   --         EXCEPTION
   --            WHEN OTHERS
   --            THEN
   --               L_EOS_FLAG := 'N';
   --               L_AVAL_TO_RESERVE_DGI := 0;
   --               L_DELTA_DGI := 0;
   --               L_AVAL_DGI := 0;
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
   --
   --         --(End) added by mohamms2 as on 05-OCT-2017 for PID Deactivation changes - restrict DGI for T-4 PIDs
   --
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
   --      END LOOP;
   --
   --      CLOSE DGI_DELTA;
   --
   --      COMMIT;
   --
   --      ---End Added as part of APR 17 Sprint Release
   --
   --      -->> DGI Insert, Required.
   --
   --      ---->>>Commented as part of multiple rows inserting for single pid APR 17 Sprint Release<<<<---
   --
   --      --      INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG (INVENTORY_LOG_ID,
   --      --                                                  PART_NUMBER,
   --      --                                                  NEW_FGI,
   --      --                                                  NEW_DGI,
   --      --                                                  ROHS_COMPLIANT,
   --      --                                                  SITE_CODE,
   --      --                                                  PROCESS_STATUS,
   --      --                                                  PROGRAM_TYPE,
   --      --                                                  UPDATED_ON,
   --      --                                                  UPDATED_BY,
   --      --                                                  CREATED_ON,
   --      --                                                  CREATED_BY)
   --      --         SELECT DGI.INV_LOG_PK,
   --      --                DGI.PRODUCT_ID,
   --      --                0,
   --      --                DGI.DELTA_DGI,
   --      --                'YES',
   --      --                'GDGI',DGI.SITE_SHORTNAME,
   --      --                'N',
   --      --                DGI.PRODUCT_TYPE,
   --      --                SYSDATE,
   --      --                G_UPDATED_BY,
   --      --                SYSDATE,
   --      --                G_UPDATED_BY
   --      --           FROM RMKTGADM.RC_INV_DGI_DELTA DGI;
   --
   --      ---->>>Commented as part of multiple rows inserting for single pid APR 17 Sprint Release<<<<---
   --
   --
   --      INSERT INTO RMKTGADM.RC_INV_DGI_DELTA_HIST
   --         SELECT *
   --           FROM RMKTGADM.RC_INV_DGI_DELTA
   --          WHERE PRODUCT_TYPE = 'E';
   --
   --      COMMIT;
   --
   --      DELETE FROM RMKTGADM.RC_INV_DGI_DELTA
   --            WHERE PRODUCT_TYPE = 'E';
   --
   --      DELETE FROM RMKTGADM.RMK_INVENTORY_LOG_STG
   --            WHERE NEW_FGI = 0 AND NEW_DGI = 0;
   --
   --      -->> FGI Load
   --
   --
   --      INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG (INVENTORY_LOG_ID,
   --                                                  PART_NUMBER,
   --                                                  NEW_FGI,
   --                                                  NEW_DGI,
   --                                                  ROHS_COMPLIANT,
   --                                                  SITE_CODE,
   --                                                  UPDATED_ON,
   --                                                  UPDATED_BY,
   --                                                  CREATED_ON,
   --                                                  CREATED_BY,
   --                                                  PROGRAM_TYPE,
   --                                                  PROCESS_STATUS)
   --         SELECT RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
   --                --RMKTGADM.RMK_INV_LOG_PK_SEQ.NEXTVAL,
   --                PRODUCT_ID,
   --                DELTA_FGI,
   --                0       NEW_DGI,
   --                IS_ROHS,
   --                SITE_SHORTNAME,
   --                SYSDATE UPDATED_ON,
   --                UPDATED_BY,
   --                SYSDATE CREATED_ON,
   --                CREATED_BY,
   --                PRODUCT_TYPE,
   --                'N'     AS PROCESS_STATUS
   --           FROM RMKTGADM.RC_INV_FGI_DELTA;
   --
   --      COMMIT;
   --
   --      INSERT INTO RC_INV_FGI_DELTA_HIST
   --         SELECT *
   --           FROM RMKTGADM.RC_INV_FGI_DELTA
   --          WHERE PRODUCT_TYPE = 'E';
   --
   --      --      DELETE FROM RC_INV_FGI_DELTA
   --      --            WHERE PRODUCT_TYPE = 'E';   -->> commented as part of US164572 on 02-APR-2018
   --
   --
   --      --to Insert the Delta inv into  rmk_inventory_log from  rmk_inventory_log_stg
   --      INSERT INTO RMK_INVENTORY_LOG
   --         SELECT *
   --           FROM RMK_INVENTORY_LOG_STG
   --          WHERE ATTRIBUTE1 IS NULL;
   --
   --      --Updating the rmk_inventory_log_stg table after processing the Delta Inv.
   --      UPDATE RMK_INVENTORY_LOG_STG
   --         SET ATTRIBUTE1 = 'PROCESSED'
   --       WHERE ATTRIBUTE1 IS NULL;
   --
   --      COMMIT;
   --
   --      -->> Calling Rohs/Non-Rohs move procedure as part of US164572 on 02-APR-2018
   --      IF G_RHS_NRHS_FLAG <> 'N'
   --      THEN
   --         RC_INV_EX_FGI_ROHS_NROHS_MOVE;
   --      END IF;
   --
   --
   --      DELETE FROM RC_INV_FGI_DELTA
   --            WHERE PRODUCT_TYPE = 'E'; -->> Deleting Delta FG table after rohs move as part of US164572 on 02-APR-2018
   --
   --      -->> Filter PILOT PIDs Inventory
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
   --                   G_PROC_NAME,
   --                   NULL,
   --                   'RC_INV_DELTA_LOAD_EX');
   --
   --      UPDATE RMKTGADM.CRON_CONTROL_INFO
   --         SET CRON_START_TIMESTAMP = G_START_TIME,
   --             CRON_END_TIMESTAMP = SYSDATE,
   --             CRON_STATUS = 'SUCCESS'
   --       WHERE     CRON_NAME = 'RC_INV_EX_DGI_FGI_LOAD'
   --             AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'EX_MAIN';
   --
   --      G_PROC_NAME := 'RC_INV_EX_DGI_FGI_LOAD';
   --
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
   --                      L_START_TIME,
   --                      SYSDATE,
   --                      G_PROC_NAME,
   --                      G_ERROR_MSG,
   --                      'RC_INV_DELTA_LOAD_EX');
   --
   --         G_PROC_NAME := 'RC_INV_EX_DGI_FGI_LOAD';
   --
   --         UPDATE RMKTGADM.CRON_CONTROL_INFO
   --            SET CRON_START_TIMESTAMP = G_START_TIME,
   --                CRON_END_TIMESTAMP = SYSDATE,
   --                CRON_STATUS = 'FAILED'
   --          WHERE     CRON_NAME = 'RC_INV_EX_DGI_FGI_LOAD'
   --                AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'EX_MAIN'; -->>Added
   --
   --         COMMIT;
   --
   --         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   --   END RC_INV_EX_DGI_FGI_LOAD;
   -----------------------------------------------------------------------------------------------------------------------------------
   --added as part of US390864
   PROCEDURE RC_INV_EX_DGI_LOAD (P_SITE_CODE IN VARCHAR2)
   IS
      CURSOR DGI_DELTA
      IS
           SELECT DGI.PRODUCT_ID,
                  SUM (DGI.DELTA_DGI) DELTA_DGI,
                  DGI.PRODUCT_TYPE,
                  DGI.SOURCE_SYSTEM
             FROM RMKTGADM.RC_INV_DGI_DELTA DGI
            WHERE 1 = 1 AND DGI.PRODUCT_TYPE = 'E' AND SOURCE_SYSTEM != 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
         GROUP BY DGI.PRODUCT_ID, DGI.PRODUCT_TYPE, DGI.SOURCE_SYSTEM;

      DGI_DELTA_REC           DGI_DELTA%ROWTYPE;
      L_START_TIME            DATE;
      L_AVAL_TO_RESERVE_DGI   NUMBER := 0;
      L_EOS_FLAG              VARCHAR2 (10) := 'N';
      L_DELTA_DGI             NUMBER := 0;
      L_AVAL_DGI              NUMBER := 0;
   ----commented as part of US438804 by sumesh---
   --      email_msg_from          VARCHAR2 (100)
   --                                 := 'refreshcentral-support@cisco.com'; --added as part of US390864
   --      email_receipient        VARCHAR2 (100)
   --         := 'daily_gdgi_addition_notifications@external.cisco.com'; --added as part of US390864
   --      email_msg_subject       VARCHAR2 (32767);    --added as part of US390864
   --      email_msg_body          VARCHAR2 (32767);    --added as part of US390864
   --      processed_count         NUMBER := 0;         --added as part of US390864
   BEGIN
      G_PROC_NAME := 'RC_INV_EX_DGI_LOAD';

      L_START_TIME := SYSDATE;

      OPEN DGI_DELTA;

      LOOP
         FETCH DGI_DELTA INTO DGI_DELTA_REC;

         EXIT WHEN DGI_DELTA%NOTFOUND;

         --check if dgi_delta.product_id is in T-4, if yes pull the aval to reserve dgi
         --check how much to be processed to ccw in case of T-4 PID
         BEGIN
            L_DELTA_DGI := 0;
            L_EOS_FLAG := 'N';
            L_AVAL_TO_RESERVE_DGI := 0;
            L_AVAL_DGI := 0;

            SELECT 'Y' EOS_FLAG,
                   (SELECT SUM (AVAILABLE_TO_RESERVE_DGI)
                      FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                     WHERE     PART_NUMBER = PM.REFRESH_PART_NUMBER
                           AND INVENTORY_FLOW = 'Excess'
                           AND SITE_CODE = 'GDGI'
                           AND ROHS_COMPLIANT = 'YES')
                      AVAILABLE_TO_RESERVE_DGI,
                   (SELECT SUM (AVAILABLE_DGI)
                      FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                     WHERE     PART_NUMBER = PM.REFRESH_PART_NUMBER
                           AND INVENTORY_FLOW = 'Excess'
                           AND SITE_CODE = 'GDGI'
                           AND ROHS_COMPLIANT = 'YES')
                      AVAILABLE_DGI,
                   (SELECT NVL (SUM (DGI.DELTA_DGI), 0)
                      FROM RMKTGADM.RC_INV_DGI_DELTA DGI
                     WHERE     DGI.PRODUCT_TYPE = 'E'
                           AND DGI.PRODUCT_ID = DGI_DELTA_REC.PRODUCT_ID
                           AND DGI.PRODUCT_TYPE = 'E'
                           --   AND dgi.is_rohs = 'YES'
                           --   AND dgi.site_shortname = 'GDGI'
                           AND NOT EXISTS
                                  (SELECT 1
                                     FROM RMKTGADM.RMK_INVENTORY_LOG_STG STG
                                    WHERE     STG.PART_NUMBER =
                                                 DGI.PRODUCT_ID
                                          AND STG.ROHS_COMPLIANT = 'YES'
                                          AND STG.SITE_CODE = 'GDGI' --dgi.site_shortname
                                          AND POE_BATCH_ID != 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                                          AND PROGRAM_TYPE = DGI.PRODUCT_TYPE
                                          AND CREATED_ON >
                                                 SYSDATE - 1 / 24 * 0.5))
                      DELTA_DGI
              INTO L_EOS_FLAG,
                   L_AVAL_TO_RESERVE_DGI,
                   L_AVAL_DGI,
                   L_DELTA_DGI
              FROM CRPADM.RC_PRODUCT_MASTER PM
             WHERE     PM.REFRESH_PART_NUMBER = DGI_DELTA_REC.PRODUCT_ID
                   AND PROGRAM_TYPE = 1
                   AND NVL (PM.MFG_EOS_DATE, SYSDATE + 130) <=
                          ADD_MONTHS (TRUNC (SYSDATE), 4);
         EXCEPTION
            WHEN OTHERS
            THEN
               L_EOS_FLAG := 'N';
               L_AVAL_TO_RESERVE_DGI := 0;
               L_DELTA_DGI := 0;
               L_AVAL_DGI := 0;
         END;

         BEGIN
            IF (L_EOS_FLAG = 'Y' AND L_DELTA_DGI <> 0)
            THEN
               IF L_AVAL_TO_RESERVE_DGI > 0
               THEN
                  IF (-L_DELTA_DGI > L_AVAL_TO_RESERVE_DGI)
                  THEN
                     L_DELTA_DGI := L_DELTA_DGI;
                  ELSE
                     L_DELTA_DGI := -L_AVAL_TO_RESERVE_DGI;
                  END IF;
               ELSIF L_AVAL_TO_RESERVE_DGI = 0
               THEN
                  IF L_DELTA_DGI < 0
                  THEN
                     L_DELTA_DGI := L_DELTA_DGI;
                  ELSE
                     L_DELTA_DGI := 0;
                  END IF;
               ELSIF L_AVAL_TO_RESERVE_DGI < 0
               THEN
                  IF L_DELTA_DGI >= 0
                  THEN
                     L_DELTA_DGI :=
                        LEAST (-L_AVAL_TO_RESERVE_DGI, L_DELTA_DGI);
                  ELSE
                     L_DELTA_DGI := L_DELTA_DGI;
                  END IF;
               END IF;                    --l_aval_to_reserve_dgi if condition

               IF (L_DELTA_DGI < 0)
               THEN
                  L_DELTA_DGI := -LEAST (L_AVAL_DGI, -L_DELTA_DGI);
               END IF;

               DGI_DELTA_REC.DELTA_DGI := L_DELTA_DGI;
            ELSIF (L_EOS_FLAG = 'Y' AND L_DELTA_DGI = 0)
            THEN
               DGI_DELTA_REC.DELTA_DGI := L_DELTA_DGI;
            END IF;                                    --eos flag IF condition
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;

         --End PID Deactivation changes - restrict DGI for T-4 PIDs

         BEGIN
            IF DGI_DELTA_REC.DELTA_DGI = 0 OR DGI_DELTA_REC.DELTA_DGI IS NULL
            THEN
               UPDATE RMKTGADM.RC_INV_MIN_DGI
                  SET STATUS = 'Y',
                      LAST_UPDATED_DATE = SYSDATE,
                      LAST_UPDATED_BY = 'C3_LOAD'
                WHERE     REFRESH_PART_NUMBER = DGI_DELTA_REC.PRODUCT_ID
                      AND PRODUCT_TYPE = 'E'
                      AND SOURCE_SYSTEM <> 'POE'
                      AND STATUS = 'N';
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;

         IF (DGI_DELTA_REC.DELTA_DGI <> 0)
         THEN --added for PID Deactivation changes - restrict DGI for T-4 PIDs
            BEGIN
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
                    VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                            DGI_DELTA_REC.PRODUCT_ID,
                            0,
                            DGI_DELTA_REC.DELTA_DGI,
                            'YES',
                            'GDGI',
                            'N',
                            DGI_DELTA_REC.PRODUCT_TYPE,
                            SYSDATE,
                            G_UPDATED_BY,
                            SYSDATE,
                            G_UPDATED_BY,
                            DGI_DELTA_REC.SOURCE_SYSTEM);
            EXCEPTION
               WHEN OTHERS
               THEN
                  RAISE_APPLICATION_ERROR (-20000, SQLERRM);
            END;
         END IF; --added for PID Deactivation changes - restrict DGI for T-4 PIDs
      END LOOP;

      CLOSE DGI_DELTA;

      COMMIT;

      ---End

      -->> DGI Insert, Required.
      INSERT INTO RMKTGADM.RC_INV_DGI_DELTA_HIST
         SELECT *
           FROM RMKTGADM.RC_INV_DGI_DELTA
          WHERE PRODUCT_TYPE = 'E' AND SOURCE_SYSTEM != 'POE'; --Added this condition part of US398932 by Satyredd on 11th Aug 2020

      COMMIT;

      ---added as part of US438804 to send email notifications---
      INSERT INTO RC_INV_DG_VALUES
         SELECT PRODUCT_ID, SOURCE_SYSTEM, DELTA_DGI
           FROM RMKTGADM.RC_INV_DGI_DELTA
          WHERE PRODUCT_TYPE = 'E' AND SOURCE_SYSTEM != 'POE'; --Added this condition part of US398932 by Satyredd on 11th Aug 2020

      COMMIT;

      ----commented as part of US438804 by sumesh---
      ----ADDED AS PART OF US390864 BY SUMESH---

      --      SELECT COUNT (*)
      --        INTO PROCESSED_COUNT
      --        FROM RMKTGADM.RC_INV_DGI_DELTA
      --       WHERE PRODUCT_TYPE = 'E' AND SOURCE_SYSTEM != 'POE'; --Added this condition part of US398932 by Satyredd on 11th Aug 2020
      --
      --      email_msg_subject :=
      --            'Excess - DGI Quantities for '
      --         || TO_CHAR (P_SITE_CODE)
      --         || ' site is processed for '
      --         || TO_CHAR (SYSDATE);
      --      email_msg_body :=
      --            '<body>
      --                       Hi Team,<br><br>Excess-DGI Quantities for '
      --         || TO_CHAR (P_SITE_CODE)
      --         || ' SITE is processed for '
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

      DELETE FROM RMKTGADM.RC_INV_DGI_DELTA
            WHERE PRODUCT_TYPE = 'E' AND SOURCE_SYSTEM != 'POE'; --Added this condition part of US398932 by Satyredd on 11th Aug 2020

      DELETE FROM RMKTGADM.RMK_INVENTORY_LOG_STG
            WHERE NEW_FGI = 0 AND NEW_DGI = 0 AND POE_BATCH_ID != 'POE'; --Added this condition part of US398932 by Satyredd on 11th Aug 2020

      --to Insert the Delta inv into  rmk_inventory_log from  rmk_inventory_log_stg

      INSERT INTO RMK_INVENTORY_LOG
         SELECT *
           FROM RMK_INVENTORY_LOG_STG
          WHERE     ATTRIBUTE1 IS NULL
                AND POE_BATCH_ID != 'POE'
                AND SITE_CODE IN ('GDGI'); --Added this condition part of US398932 by Satyredd on 11th Aug 2020

      --      --Updating the rmk_inventory_log_stg table after processing the Delta Inv.


      UPDATE RMK_INVENTORY_LOG_STG
         SET ATTRIBUTE1 = 'PROCESSED'
       WHERE     ATTRIBUTE1 IS NULL
             AND POE_BATCH_ID != 'POE'
             AND SITE_CODE IN ('GDGI'); --Added this condition part of US398932 by Satyredd on 11th Aug 2020

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
                   NULL,
                   'RC_INV_DELTA_LOAD_EX');

      UPDATE RMKTGADM.CRON_CONTROL_INFO
         SET CRON_START_TIMESTAMP = G_START_TIME,
             CRON_END_TIMESTAMP = SYSDATE,
             CRON_STATUS = 'SUCCESS'
       WHERE     CRON_NAME = 'RC_INV_EX_DGI_LOAD'
             AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'EX_MAIN';

      G_PROC_NAME := 'RC_INV_EX_DGI_LOAD';

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
                      'RC_INV_DELTA_LOAD_EX');

         G_PROC_NAME := 'RC_INV_EX_DGI_LOAD';

         UPDATE RMKTGADM.CRON_CONTROL_INFO
            SET CRON_START_TIMESTAMP = G_START_TIME,
                CRON_END_TIMESTAMP = SYSDATE,
                CRON_STATUS = 'FAILED'
          WHERE     CRON_NAME = 'RC_INV_EX_DGI_LOAD'
                AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'EX_MAIN'; -->>Added

         COMMIT;

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_EX_DGI_LOAD;

   --added as part of US390864
   PROCEDURE RC_INV_EX_FGI_LOAD (P_SITE_CODE IN VARCHAR2)
   IS
      L_START_TIME   DATE;
   ----commented as part of US438804 by sumesh---
   --      email_msg_from      VARCHAR2 (100) := 'refreshcentral-support@cisco.com'; --added as part of US390864
   --      email_receipient    VARCHAR2 (100)
   --         := 'daily_fg_addition_notifications@external.cisco.com'; --added as part of US390864
   --      email_msg_subject   VARCHAR2 (32767);        --added as part of US390864
   --      email_msg_body      VARCHAR2 (32767);        --added as part of US390864
   --      PROCESSED_COUNT     NUMBER := 0;             --added as part of US390864
   BEGIN
      G_PROC_NAME := 'RC_INV_EX_FGI_LOAD';

      L_START_TIME := SYSDATE;

      -->> FGI Load

      INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG (INVENTORY_LOG_ID,
                                                  PART_NUMBER,
                                                  NEW_FGI,
                                                  NEW_DGI,
                                                  ROHS_COMPLIANT,
                                                  SITE_CODE,
                                                  UPDATED_ON,
                                                  UPDATED_BY,
                                                  CREATED_ON,
                                                  CREATED_BY,
                                                  PROGRAM_TYPE,
                                                  PROCESS_STATUS,
                                                  POE_BATCH_ID)
         SELECT RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                PRODUCT_ID,
                DELTA_FGI,
                0       NEW_DGI,
                IS_ROHS,
                SITE_SHORTNAME,
                SYSDATE UPDATED_ON,
                UPDATED_BY,
                SYSDATE CREATED_ON,
                CREATED_BY,
                PRODUCT_TYPE,
                'N'     AS PROCESS_STATUS,
                SOURCE_SYSTEM
           FROM RMKTGADM.RC_INV_FGI_DELTA;

      COMMIT;

      INSERT INTO RC_INV_FGI_DELTA_HIST
         SELECT *
           FROM RMKTGADM.RC_INV_FGI_DELTA
          WHERE PRODUCT_TYPE = 'E';

      INSERT INTO RMK_INVENTORY_LOG
         SELECT *
           FROM RMK_INVENTORY_LOG_STG
          WHERE ATTRIBUTE1 IS NULL AND SITE_CODE IN ('FVE', 'LRO');

      --Updating the rmk_inventory_log_stg table after processing the Delta Inv.
      UPDATE RMK_INVENTORY_LOG_STG
         SET ATTRIBUTE1 = 'PROCESSED'
       WHERE ATTRIBUTE1 IS NULL AND SITE_CODE IN ('FVE', 'LRO');

      COMMIT;

      -->> Calling Rohs/Non-Rohs move procedure as part of US164572 on 02-APR-2018
      IF G_RHS_NRHS_FLAG <> 'N' AND P_SITE_CODE = 'LRO' --added as part of PRB0063316
      THEN
         RC_INV_EX_FGI_ROHS_NROHS_MOVE;
      END IF;

      ----commented as part of US438804 by sumesh---
      ----ADDED AS PART OF US390864 BY SUMESH---

      --      SELECT COUNT (*)
      --        INTO PROCESSED_COUNT
      --        FROM RC_INV_FGI_DELTA
      --       WHERE PRODUCT_TYPE = 'E';
      --
      --      email_msg_subject :=
      --            'Excess-FGI Quantities for '
      --         || TO_CHAR (P_SITE_CODE)
      --         || ' site is processed for '
      --         || TO_CHAR (SYSDATE);
      --      email_msg_body :=
      --            '<body>
      --                       Hi Team,<br><br>Excess-FGI Quantities for '
      --         || TO_CHAR (P_SITE_CODE)
      --         || ' site is processed for '
      --         || TO_CHAR (SYSDATE)
      --         || '<br><br>
      --                       For any queries please contact Refresh Support Team:  refreshcentral-support@cisco.com<br><br>
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
          WHERE PRODUCT_TYPE = 'E' AND SITE_SHORTNAME = 'LRO';

      COMMIT;

      DELETE FROM RC_INV_FGI_DELTA -->> Deleting Delta FG table after rohs move as part of US164572 on 02-APR-2018
            WHERE PRODUCT_TYPE = 'E';


      -->> Filter PILOT PIDs Inventory

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
                   'RC_INV_DELTA_LOAD_EX');

      UPDATE RMKTGADM.CRON_CONTROL_INFO
         SET CRON_START_TIMESTAMP = G_START_TIME,
             CRON_END_TIMESTAMP = SYSDATE,
             CRON_STATUS = 'SUCCESS'
       WHERE     CRON_NAME = 'RC_INV_EX_FGI_LOAD'
             AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'EX_MAIN';

      G_PROC_NAME := 'RC_INV_EX_FGI_LOAD';

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
                      'RC_INV_DELTA_LOAD_EX');

         G_PROC_NAME := 'RC_INV_EX_FGI_LOAD';

         UPDATE RMKTGADM.CRON_CONTROL_INFO
            SET CRON_START_TIMESTAMP = G_START_TIME,
                CRON_END_TIMESTAMP = SYSDATE,
                CRON_STATUS = 'FAILED'
          WHERE     CRON_NAME = 'RC_INV_EX_FGI_LOAD'
                AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'EX_MAIN'; -->>Added

         COMMIT;

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_EX_FGI_LOAD;

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
                      'RC_INV_DELTA_LOAD_EX');

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
                      'RC_INV_DELTA_LOAD_EX');

         G_PROC_NAME := 'RC_INV_GET_YIELD';

         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_GET_YIELD;

   /* Start Rohs/NRohs PID validation move as part of US164572 on 02-APR-2018 */

   FUNCTION RC_INV_PID_VALIDATION (I_PID IN VARCHAR2)
      RETURN VARCHAR2
   IS
      LV_COUNT   NUMBER;
   BEGIN
      SELECT COUNT (1)
        INTO LV_COUNT
        FROM CRPADM.RC_PRODUCT_MASTER
       WHERE TAN_ID = I_PID;

      IF LV_COUNT >= 1
      THEN
         RETURN 'Y';
      ELSE
         RETURN 'N';
      END IF;
   EXCEPTION
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
                      'RC_INV_PID_VALIDATION',
                      G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_EX');

         G_PROC_NAME := 'RC_INV_PID_VALIDATION';

         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_PID_VALIDATION;

   /* End Rohs/NRohs PID validation move as part of US164572 on 02-APR-2018 */

   PROCEDURE RC_INV_EX_SEND_WARNING_EMAIL (I_PROCEDURE_NAME    VARCHAR2,
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

      /*L_SUBJECT :=                               --Commented as part of Nov'2018 release by csirigir on 30-OCT-2018
            'Warning :  '
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


   /* Commented as part of RSCM object references changes in Sprint#18 Release as on 15-Jan-18
    VAVNI_CISCO_RSCM_ADMIN.VV_RSCM_UTIL.GENERIC_EMAIL_UTIL (G_TO,
                  G_ACT_SUPPORT,
                  L_SUBJECT,
                  O_CONTENT);
   */



   END RC_INV_EX_SEND_WARNING_EMAIL;

   PROCEDURE RC_INV_EX_SEND_ERROR_EMAIL (I_PROCEDURE_NAME    VARCHAR2,
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

      /*L_SUBJECT :=                --Commented as part of Nov'2018 release by csirigir on 30-OCT-2018
            'Warning : '
         || I_PROCEDURE_NAME
         || '  procedure executed with errors '; */

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

   END RC_INV_EX_SEND_ERROR_EMAIL;

   --(Start) added by mohamms2 as on 05-OCT-2017 for User Story US134524 -> PID Deactivation changes - restrict DGI for T-4 PIDs
   PROCEDURE RC_INV_EX_EOS_PID_QTY_REVOKE
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
                  AND XIM.INVENTORY_FLOW = 'Excess'
                  AND XIM.ROHS_COMPLIANT = 'YES'
                  AND PM.REFRESH_LIFE_CYCLE_ID <> 6 -- ignore deactivated pids
                  AND XIM.AVAILABLE_TO_RESERVE_DGI > 0
                  AND PM.PROGRAM_TYPE = 1
                  AND NVL (PM.MFG_EOS_DATE, SYSDATE + 130) <=
                         ADD_MONTHS (TRUNC (SYSDATE), 4)
                  AND XIM.PART_NUMBER NOT IN
                         (SELECT PRODUCT_ID
                            FROM RC_INV_DGI_DELTA_HIST
                           WHERE     PRODUCT_TYPE = 'E'
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
             AND CHL_CRON_NAME = 'RC_INV_EX_EOS_PID_QTY_REVOKE'
             AND CHL_CREATED_BY = 'RC_INV_DELTA_LOAD_EX'
             AND CHL_START_TIMESTAMP >= SYSDATE - SYSTIME / (24 * 60);

      -- DELETE FROM RMKTGADM.RC_INV_EOS_R_REVOKE;
      IF (RUNCOUNT = 0)
      THEN
         DELETE FROM RMKTGADM.RC_INV_EOS_QTY_E_REVOKE;

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


            INSERT INTO RMKTGADM.RC_INV_EOS_QTY_E_REVOKE (INVENTORY_LOG_ID,
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
                         'RC_INV_EX_EOS_PID_QTY_REVOKE',
                         'E');
         END LOOP;

         CLOSE EOS_REVOKE;

         INSERT INTO RMKTGADM.RC_INV_EOS_QTY_REVOKE_HIST
            SELECT * FROM RMKTGADM.RC_INV_EOS_QTY_E_REVOKE;


         INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG
            SELECT * FROM RMKTGADM.RC_INV_EOS_QTY_E_REVOKE;


         INSERT INTO RMKTGADM.RMK_INVENTORY_LOG
            SELECT *
              FROM RMKTGADM.RMK_INVENTORY_LOG_STG
             WHERE     ATTRIBUTE1 IS NULL
                   AND POE_BATCH_ID LIKE 'RC_INV_EX_EOS_PID_QTY_REVOKE';


         UPDATE RMK_INVENTORY_LOG_STG
            SET ATTRIBUTE1 = 'PROCESSED'
          WHERE     ATTRIBUTE1 IS NULL
                AND POE_BATCH_ID LIKE 'RC_INV_EX_EOS_PID_QTY_REVOKE';

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
                      'RC_INV_EX_EOS_PID_QTY_REVOKE',
                      NULL,
                      'RC_INV_DELTA_LOAD_EX');


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
                      'RC_INV_EX_EOS_PID_QTY_REVOKE',
                      G_ERROR_MSG,
                      'RC_INV_DELTA_LOAD_EX');

         COMMIT;
   END RC_INV_EX_EOS_PID_QTY_REVOKE;

   --(End) added by mohamms2 as on 05-OCT-2017 for User Story US134524 -> PID Deactivation changes - restrict DGI for T-4 PIDs Sprint
   ---Start Added as part of  US198778 For updateing SONS order received and pending qty
   PROCEDURE RC_SONS_DATA_UPDATE
   IS
      CURSOR C_FC01
      IS
         SELECT REFRESH_PART_NUMBER, PO_BUYER
           FROM CRPSC.SC_FC01_SNAPSHOT_LRO
          WHERE     PO_BUYER LIKE 'POE%'
                AND PO_BUYER IN (SELECT DISTINCT SHIPMENT_NUMBER
                                   FROM RC_SONS_INTRANS_SHIPMTS_STG);

      TYPE FC01_TBL IS TABLE OF C_FC01%ROWTYPE;

      LV_FC01_TBL              FC01_TBL;
      LV_FC01_LIMIT   CONSTANT PLS_INTEGER DEFAULT 1000;

      CURSOR C_LRO_CANCELLED
      IS
         SELECT REFRESH_PART_NUMBER, PO_BUYER, PD_TOTAL_RECEIVED_QTY
           FROM CRPSC.SC_FC01_SNAPSHOT_LRO L
          WHERE     PO_BUYER LIKE 'POE%'
                AND UPPER (PL_LINE_STATUS_CODE) = 'CANCELLED'
                AND PO_BUYER IN (SELECT DISTINCT SHIPMENT_NUMBER
                                   FROM RC_SONS_INTRANS_SHIPMTS_STG
                                  WHERE NVL (FULLY_RECEIVED_FLAG, 'N') = 'N')
                AND PD_LAST_UPDATE_DATE =
                       (SELECT MAX (PD_LAST_UPDATE_DATE)
                          FROM CRPSC.SC_FC01_SNAPSHOT_LRO
                         WHERE     REFRESH_PART_NUMBER =
                                      L.REFRESH_PART_NUMBER
                               AND PO_BUYER = L.PO_BUYER);

      TYPE LRO_CAN IS TABLE OF C_LRO_CANCELLED%ROWTYPE;

      LV_LRO_CAN               LRO_CAN;

      CURSOR C_FVE_CANCELLED
      IS
         SELECT REFRESH_PART_NUMBER, PO_BUYER, PD_TOTAL_RECEIVED_QTY
           FROM CRPSC.SC_FC01_SNAPSHOT_FVE L
          WHERE     PO_BUYER LIKE 'POE%'
                AND UPPER (PL_LINE_STATUS_CODE) = 'CANCELLED'
                AND PO_BUYER IN (SELECT DISTINCT SHIPMENT_NUMBER
                                   FROM RC_SONS_INTRANS_SHIPMTS_STG
                                  WHERE NVL (FULLY_RECEIVED_FLAG, 'N') = 'N')
                AND PD_LAST_UPDATE_DATE =
                       (SELECT MAX (PD_LAST_UPDATE_DATE)
                          FROM CRPSC.SC_FC01_SNAPSHOT_FVE
                         WHERE     REFRESH_PART_NUMBER =
                                      L.REFRESH_PART_NUMBER
                               AND PO_BUYER = L.PO_BUYER);

      TYPE FVE_CAN IS TABLE OF C_FVE_CANCELLED%ROWTYPE;

      LV_FVE_CAN               FVE_CAN;

      CURSOR SONS_DATA
      IS
         SELECT PART_NUMBER,
                SHIPMENT_NUMBER,
                TO_ORG,
                SHIPPED_QUANTITY,
                RECEIVED_QUANTITY,
                PENDING_QTY
           FROM RC_SONS_INTRANS_SHIPMTS_STG
          WHERE NVL (FULLY_RECEIVED_FLAG, 'N') = 'N';

      TYPE SONS_TBL IS TABLE OF SONS_DATA%ROWTYPE;

      LV_SONS_TBL              SONS_TBL;
   BEGIN
      --      OPEN C_FC01;
      --
      --      LOOP
      --         FETCH C_FC01 BULK COLLECT INTO LV_FC01_TBL LIMIT LV_FC01_LIMIT;
      --
      --         FORALL i IN LV_FC01_TBL.FIRST .. LV_FC01_TBL.LAST
      --            UPDATE CRPSC.SC_FC01_SNAPSHOT_LRO
      --               SET PO_BUYER =
      --                      NVL (
      --                         (SELECT DISTINCT SHIPMENT_NUMBER
      --                            FROM RC_SONS_INTRANS_SHIPMTS_STG SH
      --                           WHERE     PART_NUMBER =
      --                                        LV_FC01_TBL (i).REFRESH_PART_NUMBER
      --                                 AND ORDER_NUMBER =
      --                                        (SELECT DISTINCT ORDER_NUMBER
      --                                           FROM RC_SONS_INTRANS_SHIPMTS_STG
      --                                          WHERE SHIPMENT_NUMBER =
      --                                                   LV_FC01_TBL (i).PO_BUYER)),
      --                         LV_FC01_TBL (i).PO_BUYER)
      --             WHERE     REFRESH_PART_NUMBER =
      --                          LV_FC01_TBL (i).REFRESH_PART_NUMBER
      --                   AND PO_BUYER = LV_FC01_TBL (i).PO_BUYER;
      --
      --         EXIT WHEN C_FC01%NOTFOUND;
      --      END LOOP;
      --
      --      CLOSE C_FC01;
      --
      --      COMMIT;

      OPEN C_LRO_CANCELLED;

      LOOP
         FETCH C_LRO_CANCELLED
            BULK COLLECT INTO LV_LRO_CAN
            LIMIT LV_FC01_LIMIT;

         FORALL i IN LV_LRO_CAN.FIRST .. LV_LRO_CAN.LAST
            UPDATE RC_SONS_INTRANS_SHIPMTS_STG
               SET PENDING_QTY = 0,
                   FULLY_RECEIVED_FLAG = 'C',
                   RECEIVED_QUANTITY = LV_LRO_CAN (i).PD_TOTAL_RECEIVED_QTY,
                   UPDATED_ON = SYSDATE,
                   UPDATED_BY = 'RC_INV_DELTA_LOAD_EX'
             WHERE     PART_NUMBER = LV_LRO_CAN (i).REFRESH_PART_NUMBER
                   AND SHIPMENT_NUMBER = LV_LRO_CAN (i).PO_BUYER;

         COMMIT;
         EXIT WHEN C_LRO_CANCELLED%NOTFOUND;
      END LOOP;

      COMMIT;

      CLOSE C_LRO_CANCELLED;

      OPEN C_FVE_CANCELLED;

      LOOP
         FETCH C_FVE_CANCELLED
            BULK COLLECT INTO LV_FVE_CAN
            LIMIT LV_FC01_LIMIT;

         FORALL i IN LV_FVE_CAN.FIRST .. LV_FVE_CAN.LAST
            UPDATE RC_SONS_INTRANS_SHIPMTS_STG
               SET PENDING_QTY = 0,
                   FULLY_RECEIVED_FLAG = 'C',
                   RECEIVED_QUANTITY = LV_FVE_CAN (i).PD_TOTAL_RECEIVED_QTY,
                   UPDATED_ON = SYSDATE,
                   UPDATED_BY = 'RC_INV_DELTA_LOAD_EX'
             WHERE     PART_NUMBER = LV_FVE_CAN (i).REFRESH_PART_NUMBER
                   AND SHIPMENT_NUMBER = LV_FVE_CAN (i).PO_BUYER;

         COMMIT;
         EXIT WHEN C_FVE_CANCELLED%NOTFOUND;
      END LOOP;

      COMMIT;

      CLOSE C_FVE_CANCELLED;


      OPEN SONS_DATA;

      LOOP
         FETCH SONS_DATA BULK COLLECT INTO LV_SONS_TBL LIMIT 2000;

         FORALL i IN LV_SONS_TBL.FIRST .. LV_SONS_TBL.LAST
            UPDATE RC_SONS_INTRANS_SHIPMTS_STG
               SET RECEIVED_QUANTITY =
                      (SELECT SUM (
                                 NVL (PD_TOTAL_RECEIVED_QTY,
                                      LV_SONS_TBL (i).RECEIVED_QUANTITY))
                         FROM CRPSC.SC_FC01_SNAPSHOT_LRO
                        WHERE     REFRESH_PART_NUMBER =
                                     LV_SONS_TBL (i).PART_NUMBER
                              AND PO_BUYER = LV_SONS_TBL (i).SHIPMENT_NUMBER
                              AND PL_PLANNING_DIVISION =
                                     LV_SONS_TBL (i).TO_ORG
                              AND PD_LAST_UPDATE_DATE =
                                     (SELECT MAX (PD_LAST_UPDATE_DATE)
                                        FROM CRPSC.SC_FC01_SNAPSHOT_LRO
                                       WHERE     REFRESH_PART_NUMBER =
                                                    LV_SONS_TBL (i).PART_NUMBER
                                             AND PO_BUYER =
                                                    LV_SONS_TBL (i).SHIPMENT_NUMBER))
             WHERE     PART_NUMBER = LV_SONS_TBL (i).PART_NUMBER
                   AND SHIPMENT_NUMBER = LV_SONS_TBL (i).SHIPMENT_NUMBER
                   AND TO_ORG = 'LRO';

         COMMIT;

         FORALL i IN LV_SONS_TBL.FIRST .. LV_SONS_TBL.LAST
            UPDATE RC_SONS_INTRANS_SHIPMTS_STG
               SET RECEIVED_QUANTITY =
                      (SELECT SUM (
                                 NVL (PD_TOTAL_RECEIVED_QTY,
                                      LV_SONS_TBL (i).RECEIVED_QUANTITY))
                         FROM CRPSC.SC_FC01_SNAPSHOT_FVE
                        WHERE     REFRESH_PART_NUMBER =
                                     LV_SONS_TBL (i).PART_NUMBER
                              AND PO_BUYER = LV_SONS_TBL (i).SHIPMENT_NUMBER
                              AND PL_PLANNING_DIVISION =
                                     LV_SONS_TBL (i).TO_ORG
                              AND PD_LAST_UPDATE_DATE =
                                     (SELECT MAX (PD_LAST_UPDATE_DATE)
                                        FROM CRPSC.SC_FC01_SNAPSHOT_FVE
                                       WHERE     REFRESH_PART_NUMBER =
                                                    LV_SONS_TBL (i).PART_NUMBER
                                             AND PO_BUYER =
                                                    LV_SONS_TBL (i).SHIPMENT_NUMBER))
             WHERE     PART_NUMBER = LV_SONS_TBL (i).PART_NUMBER
                   AND SHIPMENT_NUMBER = LV_SONS_TBL (i).SHIPMENT_NUMBER
                   AND TO_ORG = 'FVE';

         COMMIT;

         FORALL i IN LV_SONS_TBL.FIRST .. LV_SONS_TBL.LAST
            UPDATE RC_SONS_INTRANS_SHIPMTS_STG
               SET PENDING_QTY =
                      NVL (SHIPPED_QUANTITY, 0) - NVL (RECEIVED_QUANTITY, 0),
                   FULLY_RECEIVED_FLAG =
                      CASE
                         WHEN (  NVL (SHIPPED_QUANTITY, 0)
                               - NVL (RECEIVED_QUANTITY, 0)) = 0
                         THEN
                            'Y'
                         ELSE
                            'N'
                      END,
                   UPDATED_ON = SYSDATE,
                   UPDATED_BY = 'RC_INV_DELTA_LOAD_EX'
             WHERE     PART_NUMBER = LV_SONS_TBL (i).PART_NUMBER
                   AND SHIPMENT_NUMBER = LV_SONS_TBL (i).SHIPMENT_NUMBER;

         COMMIT;
         EXIT WHEN SONS_DATA%NOTFOUND;
      END LOOP;

      CLOSE SONS_DATA;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12),
            NULL,
            'RC_SONS_DATA_UPDATE',
            'PROCEDURE',
            NULL,
            'YES');
   END RC_SONS_DATA_UPDATE;

   ---End Added as part of  US198778
   -->> Start Created new procedure for Delta job dependency check on 17-Jan-2019

   PROCEDURE RC_INV_EX_MAIN (P_STATUS_MESSAGE      OUT VARCHAR2,
                             P_SITE_CODE        IN     VARCHAR2)
   IS
      lv_subject         VARCHAR2 (250);
      lv_msg_content     VARCHAR2 (1500);
      lv_database_name   VARCHAR2 (50);
      lv_cron_cnt        NUMBER;
      lv_pkg_name        VARCHAR2 (50) := 'RMKTGADM.RC_INV_DELTA_LOAD_EX';
      lv_msg_body        VARCHAR2 (300);
      l_message          VARCHAR2 (2000);
      l_site_code        VARCHAR2 (10);
      CURRENT_FG_DATE    DATE; ---added as part of US438804 to send email notifications---
      LAST_FG_DATE       DATE; ---added as part of US438804 to send email notifications---
      NOTIFY_COUNT_DG    NUMBER; ---added as part of US438804 to send email notifications---
      NOTIFY_COUNT_FG    NUMBER; ---added as part of US438804 to send email notifications---
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

            G_PROC_NAME := 'RC_INV_EX_MAIN';

            G_ERROR_MSG :=
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

            RC_INV_EX_SEND_ERROR_EMAIL (G_PROC_NAME, G_ERROR_MSG);

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
                         G_PROC_NAME,
                         P_SITE_CODE || '-' || G_ERROR_MSG,     --G_ERROR_MSG,
                         'RC_INV_EX_MAIN');

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
         EX_MAIN (l_message, l_site_code);
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
                   'RC_INV_EX_MAIN',
                   P_SITE_CODE,                                        --NULL,
                   'RC_INV_DELTA_LOAD_EX');

      COMMIT;

      ---added as part of US438804 to send email notifications---
      SELECT MAX (UPDATED_ON)
        INTO CURRENT_FG_DATE
        FROM RMK_INVENTORY_LOG
       WHERE     TRUNC (UPDATED_ON) = TO_DATE (SYSDATE)
             AND UPDATED_BY = 'POEADMIN'
             AND POE_BATCH_ID IN
                    ('SC-FC01-RECEIPTS-LRO', 'SC-RETAIL-FC01-FVE')
             AND SITE_CODE IN ('LRO', 'FVE');

      SELECT MAX (REPORT_DATE) INTO LAST_FG_DATE FROM INV_MAIL_REPORT;

      SELECT COUNT (*)
        INTO NOTIFY_COUNT_FG
        FROM RC_INV_FG_VALUES
       WHERE ORG = l_site_code;

      IF (    (CURRENT_FG_DATE > LAST_FG_DATE)
          AND l_site_code <> 'GDGI'
          AND NOTIFY_COUNT_FG > 0)
      THEN
         RC_INV_FG_DG_EMAIL_PKG.RC_INV_FG_REPORT (l_site_code);

         UPDATE INV_MAIL_REPORT
            SET REPORT_DATE = CURRENT_FG_DATE;

         COMMIT;
      END IF;

      SELECT COUNT (*) INTO NOTIFY_COUNT_DG FROM RC_INV_DG_VALUES;

      IF (NOTIFY_COUNT_DG > 0 AND l_site_code = 'GDGI')
      THEN
         RC_INV_FG_DG_EMAIL_PKG.RC_INV_DG_REPORT (l_site_code);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;

         G_PROC_NAME := 'RC_INV_EX_MAIN';

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
                      'RC_INV_EX_MAIN');

         G_PROC_NAME := 'RC_INV_EX_MAIN';

         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_EX_MAIN;

   -->> End Created new procedure for Delta job dependency check on 17-Jan-2019


   /***Start*************** POE Delta Process to CCW *************************/

   FUNCTION RC_INV_POE_GET_REFURB_METHOD (I_RID                 NUMBER,
                                          I_ZCODE               VARCHAR2,
                                          I_SUB_INV_LOCATION    VARCHAR2)
      RETURN NUMBER
   IS
      LV_REFRESH_METHOD   NUMBER;
      ERROR_MSG           VARCHAR2 (10000);
   BEGIN
      --DBMS_OUTPUT.PUT_LINE('RC_INV_POE_GET_REFURB_METHOD=> Start');
      G_PROC_NAME := 'RC_INV_POE_GET_REFURB_METHOD';

      --Start Added as part of userstory US193036 to modify yield calculation logic
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

         --DBMS_OUTPUT.PUT_LINE('1->LV_REFRESH_METHOD=> '||LV_REFRESH_METHOD);
         /* Start added Apply global screen yield for Z05,Z29 if local screen yield is not setup for Z05 or Z29 on 11-FEB-2019 */

         IF LV_REFRESH_METHOD = 0 OR LV_REFRESH_METHOD IS NULL
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
                      --                   AND RP.ZCODE = I_ZCODE
                      AND RS.REFRESH_METHOD_ID = 3
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

            --DBMS_OUTPUT.PUT_LINE('2->LV_REFRESH_METHOD=> '||LV_REFRESH_METHOD);
            /* End added Apply global screen yield for Z05,Z29 if local screen yield is not setup for Z05 or Z29 on 11-FEB-2019 */

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
                     NULL;                              -- need to be reviewed
               END;

               --DBMS_OUTPUT.PUT_LINE('3->LV_REFRESH_METHOD=> '||LV_REFRESH_METHOD);
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
                                      FROM CRPADM.RC_SUB_INV_LOC_MSTR MSTR,
                                           CRPADM.RC_SUB_INV_LOC_FLG_DTLS
                                           DTLS
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
                        NULL;                           -- need to be reviewed
                  END;
               -- DBMS_OUTPUT.PUT_LINE('4->LV_REFRESH_METHOD=> '||LV_REFRESH_METHOD);
               END IF;
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

         --DBMS_OUTPUT.PUT_LINE('5->LV_REFRESH_METHOD=> '||LV_REFRESH_METHOD);
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
         --DBMS_OUTPUT.PUT_LINE('6->LV_REFRESH_METHOD=> '||LV_REFRESH_METHOD);
         END IF;
      END IF;

      --DBMS_OUTPUT.PUT_LINE('RC_INV_POE_GET_REFURB_METHOD=> End');
      --DBMS_OUTPUT.PUT_LINE('FINIAL -> LV_REFRESH_METHOD=> '||LV_REFRESH_METHOD);
      RETURN LV_REFRESH_METHOD;
   --End Added as part of userstory US193036 to modify yield calculation ligic

   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0; ---Added as part of userstory US193036 to modify yield calculation ligic

         ERROR_MSG := 'NO DATA in RC_INV_POE_GET_REFURB_METHOD for ' || I_RID;

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'EXCEPTION',
                      SYSDATE,
                      SYSDATE,
                      'RC_INV_POE_GET_REFURB_METHOD',
                      'NULL VALUES',
                      'RMKTGADM');

         COMMIT;
      WHEN OTHERS
      THEN
         ERROR_MSG :=
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
                      'EXCEPTION',
                      SYSDATE,
                      SYSDATE,
                      'RC_INV_POE_GET_REFURB_METHOD',
                      ERROR_MSG,
                      'RMKTGADM');

         COMMIT;
   END RC_INV_POE_GET_REFURB_METHOD;


   FUNCTION RC_INV_POE_GET_YIELD (I_RID                 INTEGER,
                                  I_REFRESHPIDNAME      VARCHAR2,
                                  I_C3_PART_ID          VARCHAR2,
                                  I_ZCODE               VARCHAR2,
                                  I_SUB_INV_LOCATION    VARCHAR2)
      RETURN NUMBER
   IS
      LV_YIELD    NUMBER;
      ERROR_MSG   VARCHAR2 (10000);
   BEGIN
      G_PROC_NAME := 'RC_INV_POE_GET_YIELD';

      --DBMS_OUTPUT.PUT_LINE('RC_INV_POE_GET_YIELD=> Start');
      /* For POE-LT location should consider Yeild and Repir method for WS as Screen and get yield % from RC_QE_POE_Part_Yield table*/
      IF I_ZCODE IN ('Z05', 'Z29') AND I_SUB_INV_LOCATION = 'POE-LT'
      THEN
         BEGIN
            SELECT ws_yield
              INTO lv_yield
              FROM CRPSC.RC_AE_POE_PART_YIELD
             WHERE     c3_part_id = I_C3_PART_ID
                   AND zloc = i_zcode
                   AND location = REPLACE (i_sub_inv_location, '-', '_');
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lv_yield := 0;
            WHEN OTHERS
            THEN
               lv_yield := 0;
         END;
      --END IF;

      ELSIF I_ZCODE IN ('Z05', 'Z29') AND I_SUB_INV_LOCATION <> 'POE-LT'
      THEN
         --IF I_ZCODE IN ('Z05', 'Z29') THEN
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

         /* Start added Apply global screen yield for Z05,Z29 if local screen yield is not setup for Z05 or Z29 on 11-FEB-2019 */

         IF LV_YIELD = 0 OR LV_YIELD IS NULL
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
                      --                   AND RP.ZCODE = I_ZCODE
                      AND RS.REFRESH_METHOD_ID = 3
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

            /* End added Apply global screen yield for Z05,Z29 if local screen yield is not setup for Z05 or Z29 on 11-FEB-2019 */

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
                     LV_YIELD := 0;                     -- need to be reviewed
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
                                      FROM CRPADM.RC_SUB_INV_LOC_MSTR MSTR,
                                           CRPADM.RC_SUB_INV_LOC_FLG_DTLS
                                           DTLS
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
                        LV_YIELD := 0;                  -- need to be reviewed
                  END;
               END IF;
            END IF;
         END IF;
      ELSIF I_ZCODE NOT IN ('Z05', 'Z29') AND I_SUB_INV_LOCATION <> 'POE-LT'
      THEN
         --ELSE
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
      --DBMS_OUTPUT.PUT_LINE('RC_INV_POE_GET_YIELD=> End');

      RETURN LV_YIELD;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0;
      ----      DBMS_OUTPUT.PUT_LINE (
      ----         'NO DATA in RC_PRODUCT_REPAIR_SETUP for ');-- I_RID);
      WHEN OTHERS
      THEN
         ERROR_MSG :=
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
                      'EXCEPTION',
                      SYSDATE,
                      SYSDATE,
                      'RC_INV_POE_GET_YIELD',
                      ERROR_MSG,
                      'RMKTGADM');

         COMMIT;
   END RC_INV_POE_GET_YIELD;

   /* Start Added new procedure RC_INV_C3_QTY_YIELD_CALC to calculate qty after yield on 28th Sep 2018 by sridvasu */

   PROCEDURE ALLOC_C3_POE_YIELD_CALC
   AS
      ERROR_MSG          VARCHAR2 (10000);
      l_stage_truncate   VARCHAR2 (10000);
      LM1                VARCHAR2 (1000);
      LREFURB_METHOD     VARCHAR2 (1000);
   BEGIN
      G_PROC_NAME := 'ALLOC_C3_POE_YIELD_CALC';
      --DBMS_OUTPUT.PUT_LINE('ALLOC_C3_POE_YIELD_CALC=> Start');

      l_stage_truncate := 'Truncate table RC_ZLOCSTG_COLTOROW_STG';

      EXECUTE IMMEDIATE l_stage_truncate;

      -->> Inserting START entry to Log table
      INSERT INTO RC_ZLOCSTG_COLTOROW_STG (C3_PART_IDINVENTORY_ITEM_ID,
                                           XREF_PART_NUMBER,
                                           C3_PART_ID,
                                           REGION_NAME,
                                           SITE,
                                           ZLOC,
                                           LOCATION,
                                           POE_AFTER_ALLOC,
                                           POE_REFURB_METHOD,
                                           POE_YIELD_PERCENT,
                                           POE_YIELD_AFTER_ALLOC,
                                           STATUS,
                                           CREATED_BY,
                                           CREATED_DATE,
                                           UPDATED_BY,
                                           UPDATED_DATE)
         (SELECT NULL,
                 a.XREF_PART_NUMBER,
                 a.C3_PART_ID,
                 a.REGION_NAME,
                 NULL,
                 a.ZLOC,
                 a.COL,
                 a.VAL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL
            FROM crpsc.RC_POE_NETT_DGI_ZLOC_STG
                 UNPIVOT INCLUDE NULLS
                    (val
                    FOR col
                    IN (POE_DGI, POE_NEWX, POE_NEW, POE_NRHS, POE_LT)) a
           WHERE     1 = 1                -- and c3_part_id = 'HWIC-4SHDSL-E='
                 AND EXISTS
                        (SELECT 1
                           FROM CRPADM.RC_INV_BTS_C3_MV a
                          WHERE     1 = 1
                                AND a.PART_NUMBER = C3_PART_ID
                                AND SUBSTR (a.SITE, 1, 3) = zloc
                                AND NVL (a.Region, 'a') =
                                       NVL (region_name, 'a')));

      UPDATE RC_ZLOCSTG_COLTOROW_STG a
         SET C3_PART_IDINVENTORY_ITEM_ID =
                (SELECT MAX (INVENTORY_ITEM_ID)
                   FROM CRPADM.RC_INV_BTS_C3_MV b
                  WHERE b.part_number = a.c3_part_id);

      COMMIT;



      FOR C3 IN (SELECT C3_PART_IDINVENTORY_ITEM_ID,
                        XREF_PART_NUMBER,
                        C3_PART_ID,
                        REGION_NAME,
                        SITE,
                        ZLOC,
                        REPLACE (Location, '_', '-') LOCATION,
                        LOCATION                     AS LOCATION1,
                        POE_AFTER_ALLOC,
                        POE_REFURB_METHOD,
                        POE_YIELD_PERCENT,
                        POE_YIELD_AFTER_ALLOC,
                        STATUS,
                        CREATED_BY,
                        CREATED_DATE,
                        UPDATED_BY,
                        UPDATED_DATE
                   FROM RC_ZLOCSTG_COLTOROW_STG
                  WHERE ZLOC IN ('Z05', 'Z29'))
      -- and c3_part_id = 'HWIC-4SHDSL-E=')
      -- where POE_AFTER_ALLOC > 0 )
      --WHERE C3_PART_ID ='NIM-8-1GE-SFP')
      --and REGION_NAME =
      --and location = 'POE_DGI'
      --and zloc = 'Z29')--IN ('WAVE-7541-K9','SG350X-48MP-K9-NA','C3900-SPE250/K9','C3900-SPE250/K9','SF110D-08HP-NA','SF110D-08HP-NA','SF110D-08HP-NA','AIR-AP1852I-Z-K9C','AIR-AP1852I-Z-K9C','CS-ROOM70DG2-K9','SG100-24-NA','CHAS-RFGW-10=','CP-8861-W-K9=','CP-8861-W-K9=','CP-8861-W-K9=','AIR-CT5508-50-K9','UCS-SD400G123X-EP','UCS-SD400G123X-EP','FAN-MOD-09=','CBR-D30-US-MOD','NCS-1100W-ACFW','NXA-PDC-1100W-PI','NIM-8-1GE-SFP','DN1-SD19TBKSS-EV','WS-X6716-10G-3CXL=','UCSB-EX-M4-2E-U','C9200L-24P-4X-E=','C9200L-24P-4X-E=','SG100-24-EU','ASA5505-SEC-BUN-K8','SF352-08P-K9-NA','C9200L-24P-4G-A=','C9200L-24P-4G-A=','RACK-KIT-T1=','RACK-KIT-T1=','ASA5540-MEM-2GB=','CP-8841-3PCC-K9=','WS-C3650-24TD-L','WS-C3650-24TD-L','WS-C3650-24TD-L','IEM-3000-4PC-4TC=','SPA502G','C9500-24Y4C-A=','AIR-AP2802I-H-K9','SF350-24P-K9-EU','AIR-AP2802I-S-K9C','AIR-AP2802I-S-K9C','WAP351-E-K9','WAP351-E-K9','SLM2048PT-EU','CP-6841-3PW-UK-K9=','CP-6841-3PW-UK-K9=','UCS-SPR-C220M5-C2','PWR-C1-715WAC-P','PWR-C1-715WAC-P','ACS-4320-RM-19=','UCSB-HS-EP-M4-F','UCSB-HS-EP-M4-F='))
      --WHERE INVENTORY_ITEM_ID= 309880482)
      LOOP
         --     SELECT RC_INV_DELTA_LOAD_POE.RC_INV_GET_REFURB_METHOD(327828681, (SUBSTR (C3.zloc, 1, 3)), C3.LOCATION)
         --      iNTO LM1
         --    FROM DUAL;
         --        BEGIN
         --        SELECT PC.CONFIG_NAME,
         --        RC_INV_DELTA_LOAD_POE.RC_INV_GET_REFURB_METHOD(PM.REFRESH_INVENTORY_ITEM_ID, C3.zloc, C3.LOCATION) --C3.LOCATION,(SUBSTR (C3.zloc, 1, 3))) --
         --            INTO LM1,LREFURB_METHOD
         --                   FROM CRPADM.RC_PRODUCT_CONFIG PC
         --                        INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
         --                           ON (   C3.INVENTORY_ITEM_ID =
         --                                     PM.REFRESH_INVENTORY_ITEM_ID
         --                               OR C3.INVENTORY_ITEM_ID =
         --                                     PM.COMMON_INVENTORY_ITEM_ID
         --                               OR C3.INVENTORY_ITEM_ID =
         --                                     PM.XREF_INVENTORY_ITEM_ID)
         --                        INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR M
         --                           ON (C3.LOCATION = M.SUB_INVENTORY_LOCATION)
         --                  WHERE     1 = 1
         --                        AND PC.CONFIG_TYPE = 'REFRESH_METHOD'
         --                        AND (SELECT RC_INV_DELTA_LOAD_POE.RC_INV_GET_REFURB_METHOD(PM.REFRESH_INVENTORY_ITEM_ID, (SUBSTR (C3.zloc, 1, 3)), C3.LOCATION) --C3.LOCATION,(SUBSTR (C3.zloc, 1, 3))) --
         --                               FROM DUAL) = PC.CONFIG_ID
         --                            ---AND 1 = PC.CONFIG_ID
         --                        AND M.NETTABLE_FLAG = 1
         --                        AND M.PROGRAM_TYPE =2 --IN (1, 2)
         --                        AND PM.PROGRAM_TYPE = 1
         --                        AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
         --                        AND PM.REFRESH_PART_NUMBER NOT IN
         --                        (SELECT REFRESH_PART_NUMBER
         --                           FROM RMKTGADM.RC_INV_EXCLUDE_PIDS);
         --                           EXCEPTION
         --                                WHEN OTHERS THEN
         --                                 NULL;
         --                                END;

         --     DBMS_OUTPUT.PUT_LINE('XREF_PART_NUMBER=> '||C3.XREF_PART_NUMBER
         --                         ||'  <C3.INVENTORY_ITEM_ID=> '||C3.INVENTORY_ITEM_ID
         --                         ||' <C3.LOCATION =>  '||C3.LOCATION
         --                         ||' <LOCATION1=> '||C3.LOCATION1
         --                         ||' <C3.zloc=> '||C3.zloc
         --                         ||' <C3.POE_AFTER_ALLOC=> '||C3.POE_AFTER_ALLOC
         --                         ||' <REFURBMETHOD=> '||LM1
         --                         ||' <LREFURB_METHOD=> '||LREFURB_METHOD);


         BEGIN
            UPDATE RC_ZLOCSTG_COLTOROW_STG TBL             --RC_INV_C3_TBL TBL
               SET POE_REFURB_METHOD =
                      (SELECT PC.CONFIG_NAME
                         FROM CRPADM.RC_PRODUCT_CONFIG PC
                              INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                                 ON (   C3.C3_PART_IDINVENTORY_ITEM_ID =
                                           PM.REFRESH_INVENTORY_ITEM_ID
                                     OR C3.C3_PART_IDINVENTORY_ITEM_ID =
                                           PM.COMMON_INVENTORY_ITEM_ID
                                     OR C3.C3_PART_IDINVENTORY_ITEM_ID =
                                           PM.XREF_INVENTORY_ITEM_ID)
                              INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR M
                                 ON (C3.LOCATION = M.SUB_INVENTORY_LOCATION)
                        WHERE     1 = 1
                              AND PC.CONFIG_TYPE = 'REFRESH_METHOD'
                              AND ( (SELECT CASE
                                               WHEN     C3.LOCATION =
                                                           'POE-LT'
                                                    AND C3.ZLOC IN
                                                           ('Z05', 'Z29')
                                               THEN
                                                  3 --for POE-LT should consider SCREEN for WS pids --Added by csirigir
                                               ELSE
                                                  RC_INV_POE_GET_REFURB_METHOD (
                                                     PM.REFRESH_INVENTORY_ITEM_ID,
                                                     C3.zloc,
                                                     C3.LOCATION) --C3.LOCATION,(SUBSTR (C3.zloc, 1, 3))) --
                                            END
                                       FROM DUAL) = PC.CONFIG_ID)
                              --                        AND (SELECT RC_INV_DELTA_LOAD_POE.RC_INV_GET_REFURB_METHOD(PM.REFRESH_INVENTORY_ITEM_ID, C3.zloc, C3.LOCATION) --C3.LOCATION,(SUBSTR (C3.zloc, 1, 3))) --
                              --                               FROM DUAL) = PC.CONFIG_ID
                              ---AND 1 = PC.CONFIG_ID
                              AND M.NETTABLE_FLAG = 1
                              AND M.PROGRAM_TYPE = 2 --POE Locations--IN (1, 2)
                              AND PM.PROGRAM_TYPE = 1               -- WS pids
                              AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                              AND PM.REFRESH_PART_NUMBER NOT IN
                                     (SELECT REFRESH_PART_NUMBER
                                        FROM RMKTGADM.RC_INV_EXCLUDE_PIDS)),
                   POE_YIELD_AFTER_ALLOC =
                      NVL (
                         (SELECT NVL (
                                      RC_INV_POE_GET_YIELD (
                                         PM.REFRESH_INVENTORY_ITEM_ID,
                                         PM.REFRESH_PART_NUMBER,
                                         C3.C3_PART_ID,
                                         c3.zloc, --SUBSTR (C3.PLACE_ID, 1, 3),
                                         C3.LOCATION)
                                    --* (  NVL (CASE WHEN C3.QTY_ON_HAND_USEBL>0 THEN C3.QTY_ON_HAND_USEBL ELSE 0 END, 0)) -->> Added case to avoid negative qty_on_hand 09-Jan-2019
                                    * (NVL (
                                          CASE
                                             WHEN C3.POE_AFTER_ALLOC > 0
                                             THEN
                                                C3.POE_AFTER_ALLOC
                                             ELSE
                                                0
                                          END,
                                          0))
                                    --                                 + NVL (
                                    --                                      DECODE (M.UDC_1,
                                    --                                              'Y', C3.QTY_IN_TRANS_USEBL,
                                    --                                              0),
                                    --                                      0)),  --commented by hkarka on 01OCT2018
                                    / 100,      --added by hkarka on 01OCT2018
                                    0)
                            FROM DUAL
                                 INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                                    ON (   C3.C3_PART_IDINVENTORY_ITEM_ID =
                                              PM.REFRESH_INVENTORY_ITEM_ID
                                        OR C3.C3_PART_IDINVENTORY_ITEM_ID =
                                              PM.COMMON_INVENTORY_ITEM_ID
                                        OR C3.C3_PART_IDINVENTORY_ITEM_ID =
                                              PM.XREF_INVENTORY_ITEM_ID)
                                 INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR M
                                    ON (C3.LOCATION =
                                           M.SUB_INVENTORY_LOCATION)
                           WHERE     1 = 1
                                 AND M.NETTABLE_FLAG = 1
                                 AND M.PROGRAM_TYPE = 2
                                 AND PM.PROGRAM_TYPE = 1
                                 AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                                 AND PM.REFRESH_PART_NUMBER NOT IN
                                        (SELECT REFRESH_PART_NUMBER
                                           FROM RMKTGADM.RC_INV_EXCLUDE_PIDS)),
                         0),
                   POE_YIELD_PERCENT =
                      NVL (
                         (SELECT NVL (
                                    RC_INV_POE_GET_YIELD (
                                       PM.REFRESH_INVENTORY_ITEM_ID,
                                       PM.REFRESH_PART_NUMBER,
                                       C3.C3_PART_ID,
                                       C3.zloc,      --SUBSTR (C3.zloc, 1, 3),
                                       C3.LOCATION),
                                    0)
                            FROM DUAL
                                 INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                                    ON (   C3.C3_PART_IDINVENTORY_ITEM_ID =
                                              PM.REFRESH_INVENTORY_ITEM_ID
                                        OR C3.C3_PART_IDINVENTORY_ITEM_ID =
                                              PM.COMMON_INVENTORY_ITEM_ID
                                        OR C3.C3_PART_IDINVENTORY_ITEM_ID =
                                              PM.XREF_INVENTORY_ITEM_ID)
                                 INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR M
                                    ON (C3.LOCATION =
                                           M.SUB_INVENTORY_LOCATION)
                           WHERE     1 = 1
                                 AND M.NETTABLE_FLAG = 1
                                 AND M.PROGRAM_TYPE IN (1, 2)
                                 AND PM.PROGRAM_TYPE = 1
                                 AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                                 AND PM.REFRESH_PART_NUMBER NOT IN
                                        (SELECT REFRESH_PART_NUMBER
                                           FROM RMKTGADM.RC_INV_EXCLUDE_PIDS)),
                         0)
             WHERE     1 = 1
                   AND TBL.C3_PART_IDINVENTORY_ITEM_ID =
                          C3.C3_PART_IDINVENTORY_ITEM_ID
                   AND TBL.ZLOC = C3.ZLOC                        --C3.PLACE_ID
                   AND TBL.LOCATION = C3.LOCATION1; --C3.LOCATION; -- WHERE PART_ID = 'WSC2960XR48FPDI-RF'
         EXCEPTION
            WHEN OTHERS
            THEN
               ERROR_MSG :=
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
                            'EXCEPTION',
                            SYSDATE,
                            SYSDATE,
                            G_PROC_NAME,
                            G_ERROR_MSG,
                            'ALLOC_C3_POE_YIELD_CALC');

               COMMIT;
         END;
      END LOOP;

      COMMIT;

      -- CLOSE C3_DATA;

      -->> Inserting SUCCESS entry to Log table
      INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                             CHL_STATUS,
                                             CHL_START_TIMESTAMP,
                                             CHL_END_TIMESTAMP,
                                             CHL_CRON_NAME,
                                             CHL_COMMENTS,
                                             CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'SUCCESS',
                   SYSDATE,
                   SYSDATE,
                   G_PROC_NAME,
                   G_ERROR_MSG,
                   'ALLOC_C3_POE_YIELD_CALC');

      COMMIT;
   --DBMS_OUTPUT.PUT_LINE('ALLOC_C3_POE_YIELD_CALC=> End');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'EXCEPTION',
                      SYSDATE,
                      SYSDATE,
                      G_PROC_NAME,
                      G_ERROR_MSG,
                      'ALLOC_C3_POE_YIELD_CALC');

         COMMIT;
      WHEN OTHERS
      THEN
         ERROR_MSG :=
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
                      'EXCEPTION',
                      SYSDATE,
                      SYSDATE,
                      G_PROC_NAME,
                      G_ERROR_MSG,
                      'ALLOC_C3_POE_YIELD_CALC');

         COMMIT;
   --      RAISE_APPLICATION_ERROR (-20000, SQLERRM);

   END ALLOC_C3_POE_YIELD_CALC;

   PROCEDURE RC_INV_POE_EXTRACT (P_INTRANS_FLAG      VARCHAR2 DEFAULT 'N',
                                 P_SITE_CODE      IN VARCHAR2)
   IS
      LV_TOTAL_QTY   NUMBER;
      L_START_TIME   DATE;
   BEGIN
      --DBMS_OUTPUT.PUT_LINE('RC_INV_POE_EXTRACT=> Start');
      G_PROC_NAME := 'RC_INV_POE_EXTRACT';

      L_START_TIME := SYSDATE;

      DELETE FROM RMKTGADM.RC_INV_DGI_STG          --RMKTGADM.RC_INV_POE_STAGE
            WHERE PRODUCT_TYPE = 'E' AND SOURCE_SYSTEM = 'POE'; --Added this condition part of US398932 by Satyredd on 11th Aug 2020

      COMMIT;

      --INSERT INTO RMKTGADM.RC_INV_POE_STAGE (PART_ID,
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
                                           QTY_AFTER_YIELD,
                                           STATUS,
                                           CREATION_DATE,
                                           LAST_UPDATED_DATE,
                                           LAST_UPDATED_BY,
                                           PRODUCT_TYPE,
                                           INVENTORY_TYPE,
                                           SOURCE_SYSTEM,
                                           REFRESH_PART_NUMBER)
         (SELECT DISTINCT
                 C3.C3_PART_ID                   AS PART_NUMBER, --PART_NUMBER,
                 NULL                            AS PRODUCT_FAMILY, --C3.PRODUCT_FAMILY,
                 MAP.REGION                      AS REGION_NAME,
                 C3.ZLOC                         AS Site, --C3.SITE, --C3.PLACE_ID,
                 C3.ZLOC                         AS Site1, --SUBSTR (C3.SITE, 1, 3),
                 REPLACE (C3.LOCATION, '_', '-') LOCATION,      --C3.LOCATION,
                 POE_AFTER_ALLOC                 AS QTY_ON_HAND, --TO_NUMBER (C3.QTY_ON_HAND),
                 NULL                            QTY_IN_TRANSIT, --DECODE (M.UDC_1, 'Y', C3.QTY_IN_TRANSIT, 0),
                 DECODE (PM.ROHS_CHECK_NEEDED,
                         'N', 'NO',
                         'Y', 'YES',
                         'NO')
                    AS ROHS_PID,
                 NULL                            AS ROHS_LOC,
                 C3.POE_REFURB_METHOD,                  --C3.WS_REFURB_METHOD,
                 C3.POE_YIELD_PERCENT,                  --C3.WS_YIELD_PERCENT,
                 'N'                             AS APPLY_YIELD,
                 C3.POE_YIELD_AFTER_ALLOC, --C3.WS_QTY_AFTER_YIELD + C3.YIELDED_WS_QTY_IN_TRANSIT QTY_AFTER_YIELD,
                 NULL                            AS PART_STATUS, --C3.PART_STATUS,
                 SYSDATE                         CREATION_DATE,
                 SYSDATE                         LAST_UPDATED_DATE,
                 'ADMIN'                         LAST_UPDATED_BY,
                 'E'                             PRODUCT_TYPE,
                 M.PROGRAM_TYPE                  INVENTORY_TYPE,
                 'POE',                                                --'C3',
                 PM.REFRESH_PART_NUMBER
            FROM RMKTGADM.RC_ZLOCSTG_COLTOROW_STG C3
                 INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                    ON (   C3.C3_PART_IDINVENTORY_ITEM_ID =
                              PM.REFRESH_INVENTORY_ITEM_ID
                        OR C3.C3_PART_IDINVENTORY_ITEM_ID =
                              PM.COMMON_INVENTORY_ITEM_ID
                        OR C3.C3_PART_IDINVENTORY_ITEM_ID =
                              PM.XREF_INVENTORY_ITEM_ID)
                 INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR M
                    ON (REPLACE (c3.Location, '_', '-') =
                           M.SUB_INVENTORY_LOCATION)
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
                    ON (c3.zloc = MAP.SITE_CODE)
           WHERE     1 = 1
                 AND M.NETTABLE_FLAG = 1
                 AND M.PROGRAM_TYPE = 2                                 -- POE
                 AND PM.PROGRAM_TYPE = 1                              --WS/POE
                 AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                 AND c3.zloc <> 'Z32'
                 AND PM.REFRESH_PART_NUMBER NOT IN
                        (SELECT REFRESH_PART_NUMBER
                           FROM RC_INV_EXCLUDE_PIDS)
                 AND NOT EXISTS
                        (SELECT 1
                           FROM crpadm.rc_sales_forecast sf
                          WHERE     (   sf.refresh_inventory_item_id =
                                           c3.C3_PART_IDINVENTORY_ITEM_ID
                                     OR sf.common_inventory_item_id =
                                           c3.C3_PART_IDINVENTORY_ITEM_ID
                                     OR sf.xref_inventory_item_id =
                                           c3.C3_PART_IDINVENTORY_ITEM_ID)
                                AND NVL (
                                       NVL (adj_overridden_pid_priority,
                                            adjusted_pid_priority),
                                       pid_priority) = 'P1'));

      --);

      COMMIT;

      -- update Apply field flag depending the sub inventory location
      UPDATE RMKTGADM.RC_INV_DGI_STG               --RMKTGADM.RC_INV_POE_STAGE
         SET APPLY_YIELD = 'Y'
       WHERE     1 = 1
             AND SOURCE_SYSTEM = 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
             AND REPLACE (Location, '_', '-') IN
                    (SELECT M.SUB_INVENTORY_LOCATION
                       FROM CRPADM.RC_SUB_INV_LOC_MSTR M
                            INNER JOIN CRPADM.RC_SUB_INV_LOC_FLG_DTLS D
                               ON (M.SUB_INVENTORY_ID = D.SUB_INVENTORY_ID)
                      WHERE     M.NETTABLE_FLAG = 1
                            AND M.PROGRAM_TYPE = 2                      -- POE
                            AND D.YIELD_WS = 'Y');

      G_PROC_NAME := 'RC_INV_POE_EXTRACT';

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
                   'RC_INV_POE_EXTRACT');

      COMMIT;
   --DBMS_OUTPUT.PUT_LINE('RC_INV_POE_EXTRACT=> End');
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
                      'RC_INV_POE_EXTRACT');

         G_PROC_NAME := 'RC_INV_POE_EXTRACT';

         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_POE_EXTRACT;

   PROCEDURE RC_INV_POE_HISTORY (P_SITE_CODE IN VARCHAR2)
   IS
      L_START_TIME   DATE;
   BEGIN
      --DBMS_OUTPUT.PUT_LINE('RC_INV_POE_HISTORY=> Start');
      G_PROC_NAME := 'RC_INV_POE_HISTORY';

      L_START_TIME := SYSDATE;

      --consolidate the inventory to Zlocation level
      --INSERT INTO RMKTGADM.RC_INV_POE_STAGE_HIST (PART_ID,
      INSERT INTO RMKTGADM.RC_INV_DGI_HIST (PART_ID,
                                            PRD_FAMILY,
                                            ZLOCATION,
                                            ZCODE,
                                            QTY_AFTER_YIELD,
                                            ROHS_PID,
                                            LOCATION,
                                            STATUS,
                                            SITE_SHORTNAME,
                                            CREATED_ON,
                                            UPDATED_ON,
                                            PRODUCT_TYPE,
                                            INVENTORY_TYPE,
                                            SOURCE_SYSTEM)
         (  SELECT DISTINCT REFRESH_PART_NUMBER,
                            NULL                PRD_FAMILY,      --PRD_FAMILY,
                            PLACE_ID,
                            STG.SITE_CODE,
                            SUM (QTY_AFTER_YIELD) QTY,
                            --(QTY_AFTER_YIELD) QTY, --25699
                            ROHS_PID,
                            LOCATION,
                            'CURRENT'           AS STATUS,
                            MAP.SITE_SHORTNAME,
                            SYSDATE,
                            SYSDATE,
                            PRODUCT_TYPE,
                            STG.INVENTORY_TYPE,
                            SOURCE_SYSTEM
              --FROM RMKTGADM.RC_INV_POE_STAGE      STG,
              FROM RMKTGADM.RC_INV_DGI_STG      STG,
                   RMKTGADM.RMK_INV_SITE_MAPPINGS MAP,
                   CRPADM.RC_SUB_INV_LOC_MSTR   SUB
             WHERE     MAP.SITE_CODE = STG.SITE_CODE
                   AND stg.Location = SUB.SUB_INVENTORY_LOCATION
                   --REPLACE (stg.Location,'_','-') = SUB.SUB_INVENTORY_LOCATION
                   AND MAP.INV_TYPE = 'DGI'
                   AND MAP.ROHS_SITE = 'YES'
                   AND MAP.STATUS = 'ACTIVE'
                   AND SUB.INVENTORY_TYPE <> 0            --<>0 means DGI, WIP
                   AND SUB.PROGRAM_TYPE = 2                              --POE
                   AND PRODUCT_TYPE = 'E'
                   AND stg.SOURCE_SYSTEM = 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
          GROUP BY REFRESH_PART_NUMBER,
                   --PRD_FAMILY,
                   PLACE_ID,
                   STG.SITE_CODE,
                   ROHS_PID,
                   LOCATION,
                   'CURRENT',
                   MAP.SITE_SHORTNAME,
                   PRODUCT_TYPE,
                   STG.INVENTORY_TYPE,
                   SOURCE_SYSTEM);

      --      INSERT INTO nar (me, curdate)
      --           VALUES (SYSDATE || ' <RC_INV_POE_HISTORY=> ', SYSDATE);

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
                   P_SITE_CODE,                                       -- NULL,
                   'RC_INV_POE_HISTORY');

      G_PROC_NAME := 'RC_INV_POE_HISTORY';
   --DBMS_OUTPUT.PUT_LINE('RC_INV_POE_HISTORY=> End');
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
                      P_SITE_CODE || '-' || G_ERROR_MSG,       -- G_ERROR_MSG,
                      'RC_INV_POE_HISTORY');

         G_PROC_NAME := 'RC_INV_POE_HISTORY';

         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_POE_HISTORY;

   PROCEDURE RC_INV_POE_DELTA_PROCESS (P_SITE_CODE IN VARCHAR2)
   IS
      LAST_VALUE         NUMBER;
      V_DGI_DELTA        NUMBER;
      TOTAL_QTY_DGI      NUMBER;
      TOTAL_ONHAND_DGI   NUMBER;
      C3_ONHAND_DGI      NUMBER;
      C3_QTY_DGI         NUMBER;
      v_ccw_inv          NUMBER;
      v_status           VARCHAR2 (2);

      CURSOR DGI_CURSOR_DELTA
      IS
         SELECT T1.POE_BATCH_ID,
                T1.PART_ID,
                T1.QTY_AFTER_YIELD,
                T1.ROHS_PID,
                T1.PRODUCT_TYPE,
                T1.SOURCE_SYSTEM
           FROM (  SELECT POE_BATCH_ID,
                          PART_ID,
                          SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                          ROHS_PID,
                          PRODUCT_TYPE,
                          SOURCE_SYSTEM
                     FROM RMKTGADM.RC_INV_DGI_HIST --RMKTGADM.RC_INV_POE_STAGE_HIST --RC_INV_DGI_HIST
                    WHERE     PRODUCT_TYPE = 'E'
                          AND STATUS = 'CURRENT'
                          AND SOURCE_SYSTEM = 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                 GROUP BY POE_BATCH_ID,
                          PART_ID,
                          ROHS_PID,
                          PRODUCT_TYPE,
                          SOURCE_SYSTEM) T1
                INNER JOIN
                (  SELECT PART_ID,
                          SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                          ROHS_PID,
                          PRODUCT_TYPE,
                          SOURCE_SYSTEM
                     FROM RMKTGADM.RC_INV_DGI_HIST --RMKTGADM.RC_INV_POE_STAGE_HIST --RC_INV_DGI_HIST
                    WHERE     PRODUCT_TYPE = 'E'
                          AND STATUS = 'LASTRUN'
                          AND SOURCE_SYSTEM = 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                 GROUP BY POE_BATCH_ID,
                          PART_ID,
                          ROHS_PID,
                          PRODUCT_TYPE,
                          SOURCE_SYSTEM) T2
                   ON     T1.PART_ID = T2.PART_ID
                      AND T1.PRODUCT_TYPE = T2.PRODUCT_TYPE
                      AND T1.SOURCE_SYSTEM = T2.SOURCE_SYSTEM;

      CURSOR DGI_CURSOR_CURRENT
      IS
           SELECT PART_ID,
                  SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                  ROHS_PID,
                  PRODUCT_TYPE,
                  SOURCE_SYSTEM
             FROM RMKTGADM.RC_INV_DGI_HIST --RMKTGADM.RC_INV_POE_STAGE_HIST--RMKTGADM.RC_INV_DGI_HIST
            WHERE     PRODUCT_TYPE = 'E'
                  AND STATUS = 'CURRENT'
                  AND SOURCE_SYSTEM = 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
         GROUP BY POE_BATCH_ID,
                  PART_ID,
                  ROHS_PID,
                  PRODUCT_TYPE,
                  SOURCE_SYSTEM
         MINUS
         SELECT T1.PART_ID,
                T1.QTY_AFTER_YIELD,
                T1.ROHS_PID,
                T1.PRODUCT_TYPE,
                T1.SOURCE_SYSTEM
           FROM (  SELECT POE_BATCH_ID,
                          PART_ID,
                          SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                          ROHS_PID,
                          PRODUCT_TYPE,
                          SOURCE_SYSTEM
                     FROM RMKTGADM.RC_INV_DGI_HIST --RMKTGADM.RC_INV_POE_STAGE_HIST--RMKTGADM.RC_INV_DGI_HIST
                    WHERE     PRODUCT_TYPE = 'E'
                          AND STATUS = 'CURRENT'
                          AND SOURCE_SYSTEM = 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                 GROUP BY POE_BATCH_ID,
                          PART_ID,
                          ROHS_PID,
                          PRODUCT_TYPE,
                          SOURCE_SYSTEM) T1
                INNER JOIN
                (  SELECT PART_ID,
                          SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                          ROHS_PID,
                          PRODUCT_TYPE,
                          SOURCE_SYSTEM
                     FROM RMKTGADM.RC_INV_DGI_HIST --RMKTGADM.RC_INV_POE_STAGE_HIST--RMKTGADM.RC_INV_DGI_HIST
                    WHERE     PRODUCT_TYPE = 'E'
                          AND STATUS = 'LASTRUN'
                          AND SOURCE_SYSTEM = 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                 GROUP BY POE_BATCH_ID,
                          PART_ID,
                          ROHS_PID,
                          PRODUCT_TYPE,
                          SOURCE_SYSTEM) T2
                   ON     T1.PART_ID = T2.PART_ID
                      AND T1.PRODUCT_TYPE = T2.PRODUCT_TYPE
                      AND T1.SOURCE_SYSTEM = T2.SOURCE_SYSTEM; -- OR T1.SOURCE_SYSTEM IN ('FC01-FVE', 'FC01-LRO') ) ;

      CURSOR DGI_CURSOR_LAST
      IS
           SELECT PART_ID,
                  SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                  ROHS_PID,
                  PRODUCT_TYPE,
                  SOURCE_SYSTEM
             FROM RMKTGADM.RC_INV_DGI_HIST --RMKTGADM.RC_INV_POE_STAGE_HIST--RMKTGADM.RC_INV_DGI_HIST
            WHERE     PRODUCT_TYPE = 'E'
                  AND STATUS = 'LASTRUN'
                  AND SOURCE_SYSTEM = 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
         GROUP BY POE_BATCH_ID,
                  PART_ID,
                  ROHS_PID,
                  PRODUCT_TYPE,
                  SOURCE_SYSTEM
         MINUS
         SELECT T2.PART_ID,
                T2.QTY_AFTER_YIELD,
                T2.ROHS_PID,
                T2.PRODUCT_TYPE,
                T2.SOURCE_SYSTEM
           FROM (  SELECT PART_ID,
                          SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                          ROHS_PID,
                          PRODUCT_TYPE,
                          SOURCE_SYSTEM
                     FROM RMKTGADM.RC_INV_DGI_HIST --RMKTGADM.RC_INV_POE_STAGE_HIST--RMKTGADM.RC_INV_DGI_HIST
                    WHERE     PRODUCT_TYPE = 'E'
                          AND STATUS = 'CURRENT'
                          AND SOURCE_SYSTEM = 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                 GROUP BY POE_BATCH_ID,
                          PART_ID,
                          ROHS_PID,
                          PRODUCT_TYPE,
                          SOURCE_SYSTEM) T1
                INNER JOIN
                (  SELECT POE_BATCH_ID,
                          PART_ID,
                          SUM (QTY_AFTER_YIELD) QTY_AFTER_YIELD,
                          ROHS_PID,
                          PRODUCT_TYPE,
                          SOURCE_SYSTEM
                     FROM RMKTGADM.RC_INV_DGI_HIST --RMKTGADM.RC_INV_POE_STAGE_HIST--RMKTGADM.RC_INV_DGI_HIST
                    WHERE     PRODUCT_TYPE = 'E'
                          AND STATUS = 'LASTRUN'
                          AND SOURCE_SYSTEM = 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                 GROUP BY POE_BATCH_ID,
                          PART_ID,
                          ROHS_PID,
                          PRODUCT_TYPE,
                          SOURCE_SYSTEM) T2
                   ON     T1.PART_ID = T2.PART_ID
                      AND T1.PRODUCT_TYPE = T2.PRODUCT_TYPE
                      AND T1.SOURCE_SYSTEM = T2.SOURCE_SYSTEM; -- OR T1.SOURCE_SYSTEM IN ('FC01-FVE', 'FC01-LRO') );

      DGI_RECORD         DGI_CURSOR_DELTA%ROWTYPE;
      DGI_RECORD_C       DGI_CURSOR_CURRENT%ROWTYPE;
      DGI_RECORD_L       DGI_CURSOR_CURRENT%ROWTYPE;
      L_START_TIME       DATE;
   BEGIN
      --DBMS_OUTPUT.PUT_LINE('RC_INV_POE_DELTA_PROCESS=> Start');
      G_PROC_NAME := 'RC_INV_POE_DELTA_PROCESS';

      L_START_TIME := SYSDATE;

      --insert into RMKTGADM.RC_INV_POE_STAGE_HIST_ch select * from RMKTGADM.RC_INV_POE_STAGE_HIST;

      DELETE FROM RMKTGADM.RC_INV_DGI_DELTA --RMKTGADM.RC_INV_POE_DELTA --RC_INV_DGI_DELTA
            WHERE PRODUCT_TYPE = 'E' AND SOURCE_SYSTEM = 'POE'; --Added this condition part of US398932 by Satyredd on 11th Aug 2020

      COMMIT;

      OPEN DGI_CURSOR_DELTA;

      LOOP
         FETCH DGI_CURSOR_DELTA INTO DGI_RECORD;

         EXIT WHEN DGI_CURSOR_DELTA%NOTFOUND;

         SELECT SUM (QTY_AFTER_YIELD)
           INTO LAST_VALUE
           FROM RMKTGADM.RC_INV_DGI_HIST --RMKTGADM.RC_INV_POE_STAGE_HIST--RMKTGADM.RC_INV_DGI_HIST
          WHERE     PRODUCT_TYPE = 'E'
                AND SOURCE_SYSTEM = 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                AND PART_ID = DGI_RECORD.PART_ID
                AND PRODUCT_TYPE = DGI_RECORD.PRODUCT_TYPE  -->> --DeltaAgg-->
                AND SOURCE_SYSTEM = DGI_RECORD.SOURCE_SYSTEM
                AND STATUS = 'LASTRUN';

         SELECT SUM (QTY_AFTER_YIELD)
           INTO TOTAL_QTY_DGI
           FROM RMKTGADM.RC_INV_DGI_HIST
          WHERE     PRODUCT_TYPE = 'E'
                AND PART_ID = DGI_RECORD.PART_ID
                AND STATUS = 'CURRENT';

         SELECT SUM (QTY_ON_HAND_USEBL)
           INTO TOTAL_ONHAND_DGI
           FROM RMKTGADM.RC_INV_DGI_STG
          WHERE     PRODUCT_TYPE = 'E'
                AND REFRESH_PART_NUMBER = DGI_RECORD.PART_ID;

         SELECT SUM (QTY_AFTER_YIELD)
           INTO C3_QTY_DGI
           FROM RMKTGADM.RC_INV_DGI_HIST
          WHERE     PRODUCT_TYPE = 'E'
                AND SOURCE_SYSTEM = 'POE'
                AND PART_ID = DGI_RECORD.PART_ID
                AND STATUS = 'CURRENT';

         SELECT SUM (QTY_ON_HAND_USEBL)
           INTO C3_ONHAND_DGI
           FROM RMKTGADM.RC_INV_DGI_STG
          WHERE     PRODUCT_TYPE = 'E'
                AND SOURCE_SYSTEM = 'POE'
                AND REFRESH_PART_NUMBER = DGI_RECORD.PART_ID;

         SELECT NVL (SUM (AVAILABLE_DGI), 0)
           INTO v_ccw_inv
           FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
          WHERE     PART_NUMBER = DGI_RECORD.PART_ID
                AND INVENTORY_FLOW = 'Excess'
                AND SITE_CODE = 'GDGI';

         SELECT NVL (MIN (STATUS), 'Y')
           INTO v_status
           FROM RC_INV_MIN_DGI
          WHERE     PRODUCT_TYPE = 'E'
                AND SOURCE_SYSTEM = 'POE'
                AND STATUS = 'N'
                AND REFRESH_PART_NUMBER = DGI_RECORD.PART_ID;

         IF     TOTAL_QTY_DGI < 0.5
            AND TOTAL_QTY_DGI > 0
            AND TOTAL_ONHAND_DGI >= 1
            AND C3_QTY_DGI < 0.5
            AND C3_QTY_DGI > 0
            AND C3_ONHAND_DGI >= 1
            AND v_status <> 'N'
            AND LAST_VALUE < 0.5
            AND v_ccw_inv < 1
         THEN
            V_DGI_DELTA := 1;

            /* table to insert DGI for qty less than 1 and track */
            INSERT INTO RC_INV_MIN_DGI (REFRESH_PART_NUMBER,
                                        QTY_ON_HAND_USEBL,
                                        QTY_AFTER_YIELD,
                                        QTY_ADDED,
                                        STATUS,
                                        CREATION_DATE,
                                        LAST_UPDATED_DATE,
                                        LAST_UPDATED_BY,
                                        SOURCE_SYSTEM,
                                        PRODUCT_TYPE)
                 VALUES (DGI_RECORD.PART_ID,
                         C3_ONHAND_DGI,
                         C3_QTY_DGI,
                         V_DGI_DELTA,
                         'N',
                         SYSDATE,
                         SYSDATE,
                         'GDGI DELTA',
                         'POE',
                         'E');
         ELSIF     TOTAL_QTY_DGI < 0.5
               AND TOTAL_QTY_DGI > 0
               AND TOTAL_ONHAND_DGI >= 1
               AND C3_QTY_DGI < 0.5
               AND C3_QTY_DGI > 0
               AND C3_ONHAND_DGI >= 1
               AND v_status <> 'N'
               AND LAST_VALUE > 0.5
               AND v_ccw_inv < 1
         THEN
            V_DGI_DELTA := DGI_RECORD.QTY_AFTER_YIELD - LAST_VALUE + 1;

            INSERT INTO RC_INV_MIN_DGI (REFRESH_PART_NUMBER,
                                        QTY_ON_HAND_USEBL,
                                        QTY_AFTER_YIELD,
                                        QTY_ADDED,
                                        STATUS,
                                        CREATION_DATE,
                                        LAST_UPDATED_DATE,
                                        LAST_UPDATED_BY,
                                        SOURCE_SYSTEM,
                                        PRODUCT_TYPE)
                 VALUES (DGI_RECORD.PART_ID,
                         C3_ONHAND_DGI,
                         C3_QTY_DGI,
                         V_DGI_DELTA,
                         'N',
                         SYSDATE,
                         SYSDATE,
                         'GDGI DELTA',
                         'C3',
                         'E');
         ELSE
            IF     v_status = 'N'
               AND (DGI_RECORD.QTY_AFTER_YIELD - LAST_VALUE) > 0
            THEN
               V_DGI_DELTA := DGI_RECORD.QTY_AFTER_YIELD - LAST_VALUE - 1;

               UPDATE RC_INV_MIN_DGI
                  SET STATUS = 'Y', LAST_UPDATED_DATE = SYSDATE
                WHERE     PRODUCT_TYPE = 'E'
                      AND SOURCE_SYSTEM = 'POE'
                      AND STATUS = 'N'
                      AND REFRESH_PART_NUMBER = DGI_RECORD.PART_ID;
            ELSE
               V_DGI_DELTA := DGI_RECORD.QTY_AFTER_YIELD - LAST_VALUE;
            END IF;
         END IF;


         IF V_DGI_DELTA != 0
         THEN
            --DBMS_OUTPUT.PUT_LINE(DGI_RECORD.PART_ID||' <DGI_RECORD.PART_ID=DGI_CURSOR_DELTA=> '|| V_DGI_DELTA);
            --            INSERT INTO nar (me, curdate)
            --                    VALUES (
            --                                 DGI_RECORD.PART_ID
            --                              || ' <DGI_RECORD.PART_ID=DGI_CURSOR_DELTA=> '
            --                              || V_DGI_DELTA,
            --                              SYSDATE);

            --INSERT INTO RMKTGADM.RC_INV_DGI_DELTA
            --INSERT INTO RMKTGADM.RC_INV_POE_DELTA(INV_LOG_PK,
            INSERT INTO RMKTGADM.RC_INV_DGI_DELTA (INV_LOG_PK,
                                                   PRODUCT_ID,
                                                   DELTA_DGI, --DELTA-POE QTY_AFTER_YIELD
                                                   IS_ROHS,
                                                   CREATED_ON,
                                                   CREATED_BY,
                                                   PRODUCT_TYPE,
                                                   SOURCE_SYSTEM,
                                                   POE_BATCH_ID)
                 VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                         DGI_RECORD.PART_ID,
                         V_DGI_DELTA,
                         DGI_RECORD.ROHS_PID,
                         SYSDATE,
                         'POEADMINALLCON',
                         DGI_RECORD.PRODUCT_TYPE,
                         DGI_RECORD.SOURCE_SYSTEM,
                         'POE_DELTA != 0');
         END IF;
      END LOOP;


      ---------------------------------------------------------------CURRENT-------------------------------------

      OPEN DGI_CURSOR_CURRENT;

      LOOP
         FETCH DGI_CURSOR_CURRENT INTO DGI_RECORD_C;

         EXIT WHEN DGI_CURSOR_CURRENT%NOTFOUND;

         IF DGI_RECORD_C.QTY_AFTER_YIELD <> 0
         THEN
            --DBMS_OUTPUT.PUT_LINE(DGI_RECORD.PART_ID||' <DGI_RECORD.PART_ID=DGI_CURSOR_CURRENT=> '|| DGI_RECORD_C.QTY_AFTER_YIELD);
            --            INSERT INTO nar (me, curdate)
            --                    VALUES (
            --                                 DGI_RECORD.PART_ID
            --                              || ' <DGI_RECORD.PART_ID=DGI_CURSOR_CURRENT=> '
            --                              || V_DGI_DELTA,
            --                              SYSDATE);

            --INSERT INTO RMKTGADM.RC_INV_DGI_DELTA (INV_LOG_PK,
            --INSERT INTO RMKTGADM.RC_INV_POE_DELTA (INV_LOG_PK,
            INSERT INTO RMKTGADM.RC_INV_DGI_DELTA (INV_LOG_PK,
                                                   PRODUCT_ID,
                                                   DELTA_DGI,
                                                   IS_ROHS,
                                                   CREATED_ON,
                                                   CREATED_BY,
                                                   PRODUCT_TYPE,
                                                   SOURCE_SYSTEM,
                                                   POE_BATCH_ID)
                 VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                         DGI_RECORD_C.PART_ID,
                         DGI_RECORD_C.QTY_AFTER_YIELD,
                         DGI_RECORD_C.ROHS_PID,
                         SYSDATE,
                         'POEADMINALLCON',
                         DGI_RECORD_C.PRODUCT_TYPE,
                         DGI_RECORD_C.SOURCE_SYSTEM,
                         'POE_CURRENT');
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
            --DBMS_OUTPUT.PUT_LINE(DGI_RECORD.PART_ID||' <DGI_RECORD.PART_ID=DGI_CURSOR_DELTA=> '|| DGI_RECORD_L.QTY_AFTER_YIELD);
            --            INSERT INTO nar (me, curdate)
            --                    VALUES (
            --                                 DGI_RECORD.PART_ID
            --                              || ' <DGI_RECORD.PART_ID=DGI_CURSOR_DELTA=> '
            --                              || V_DGI_DELTA,
            --                              SYSDATE);

            --INSERT INTO RMKTGADM.RC_INV_DGI_DELTA (INV_LOG_PK,
            --INSERT INTO RMKTGADM.RC_INV_POE_DELTA (INV_LOG_PK,
            INSERT INTO RMKTGADM.RC_INV_DGI_DELTA (INV_LOG_PK,
                                                   PRODUCT_ID,
                                                   DELTA_DGI,
                                                   IS_ROHS,
                                                   CREATED_ON,
                                                   CREATED_BY,
                                                   PRODUCT_TYPE,
                                                   SOURCE_SYSTEM,
                                                   POE_BATCH_ID)
                 VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                         DGI_RECORD_L.PART_ID,
                         - (DGI_RECORD_L.QTY_AFTER_YIELD),
                         DGI_RECORD_L.ROHS_PID,
                         SYSDATE,
                         'POEADMINALLCON',
                         DGI_RECORD_L.PRODUCT_TYPE,
                         DGI_RECORD_L.SOURCE_SYSTEM,
                         'POE_LASTRUN');
         END IF;
      END LOOP;

      CLOSE DGI_CURSOR_LAST;

      UPDATE RMKTGADM.RC_INV_DGI_HIST --RMKTGADM.RC_INV_POE_STAGE_HIST--RC_INV_DGI_HIST
         SET STATUS = 'HISTORY'
       WHERE     PRODUCT_TYPE = 'E'
             AND STATUS = 'LASTRUN'
             AND SOURCE_SYSTEM = 'POE'; --Added this condition part of US398932 by Satyredd on 11th Aug 2020;

      UPDATE RMKTGADM.RC_INV_DGI_HIST --RMKTGADM.RC_INV_POE_STAGE_HIST--RC_INV_DGI_HIST
         SET STATUS = 'LASTRUN'
       WHERE     PRODUCT_TYPE = 'E'
             AND STATUS = 'CURRENT'
             AND SOURCE_SYSTEM = 'POE'; --Added this condition part of US398932 by Satyredd on 11th Aug 2020;

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
                   P_SITE_CODE,
                   'RC_INV_POE_DELTA_PROCESS');

      G_PROC_NAME := 'RC_INV_POE_DELTA_PROCESS';

      COMMIT;
   --DBMS_OUTPUT.PUT_LINE('RC_INV_POE_DELTA_PROCESS=> End');
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
                      P_SITE_CODE || '-' || G_ERROR_MSG,     --   G_ERROR_MSG,
                      'RC_INV_POE_DELTA_PROCESS');

         G_PROC_NAME := 'RC_INV_POE_DELTA_PROCESS';

         COMMIT;

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_POE_DELTA_PROCESS;

   PROCEDURE RC_INV_POE_PUT_REMINDERS
   IS
      V_REMINDER_VALUE   NUMBER (10, 2);
      V_SEQ              NUMBER;

      CURSOR DGI_CURSOR_DELTA
      IS
           SELECT PRODUCT_ID,
                  PRODUCT_TYPE,
                  SOURCE_SYSTEM,
                  SUM (DELTA_DGI) DELTA_DGI
             FROM RMKTGADM.RC_INV_DGI_DELTA --RMKTGADM.RC_INV_POE_DELTA--RC_INV_DGI_DELTA
            WHERE PRODUCT_TYPE = 'E' AND SOURCE_SYSTEM = 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
         GROUP BY PRODUCT_ID, PRODUCT_TYPE, SOURCE_SYSTEM;

      DGI_INV_RECORD     DGI_CURSOR_DELTA%ROWTYPE;
      V_INV_LOG_PK       NUMBER;
      L_START_TIME       DATE;
   BEGIN
      --DBMS_OUTPUT.PUT_LINE('RC_INV_POE_PUT_REMINDERS=> Start');
      G_PROC_NAME := 'RC_INV_POE_PUT_REMINDERS';

      L_START_TIME := SYSDATE;

      OPEN DGI_CURSOR_DELTA;

      LOOP
         FETCH DGI_CURSOR_DELTA INTO DGI_INV_RECORD;

         EXIT WHEN DGI_CURSOR_DELTA%NOTFOUND;

         /* Start Modified logic for Negative DGI Scenario on 04-FEB-2019 */

         IF DGI_INV_RECORD.DELTA_DGI >= 0
         THEN
            V_REMINDER_VALUE :=
               ROUND (DGI_INV_RECORD.DELTA_DGI) - DGI_INV_RECORD.DELTA_DGI;

            IF (V_REMINDER_VALUE) != 0
            THEN
               V_INV_LOG_PK := RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL;

               INSERT
                 --INTO RMKTGADM.RC_INV_DGI_ROUNDED_VALUES (INV_LOG_PK,
                 --INTO RMKTGADM.RC_INV_POE_ROUNDED_VALUES (INV_LOG_PK,
                 INTO RMKTGADM.RC_INV_DGI_ROUNDED_VALUES (INV_LOG_PK,
                                                          PRODUCT_ID,
                                                          REMINDER_VALUE,
                                                          PROCESSED_STATUS,
                                                          CREATED_BY,
                                                          CREATION_DATE,
                                                          LAST_UPDATED_DATE,
                                                          LAST_UPDATED_BY,
                                                          PRODUCT_TYPE,
                                                          SOURCE_SYSTEM)
               VALUES (V_INV_LOG_PK,
                       DGI_INV_RECORD.PRODUCT_ID,
                       - (V_REMINDER_VALUE),
                       'N',
                       '',
                       SYSDATE,
                       SYSDATE,
                       'POEADMINALLOCPUT>=0',
                       DGI_INV_RECORD.PRODUCT_TYPE,
                       DGI_INV_RECORD.SOURCE_SYSTEM);

               UPDATE RMKTGADM.RC_INV_DGI_DELTA --RMKTGADM.RC_INV_POE_DELTA--RC_INV_DGI_DELTA
                  SET DELTA_DGI = ROUND (DGI_INV_RECORD.DELTA_DGI)
                WHERE     1 = 1
                      AND PRODUCT_ID = DGI_INV_RECORD.PRODUCT_ID
                      AND PRODUCT_TYPE = DGI_INV_RECORD.PRODUCT_TYPE
                      AND SOURCE_SYSTEM = DGI_INV_RECORD.SOURCE_SYSTEM;

               COMMIT;
            END IF;
         ELSIF DGI_INV_RECORD.DELTA_DGI < 0
         THEN
            V_REMINDER_VALUE :=
                 - (FLOOR (ABS (DGI_INV_RECORD.DELTA_DGI)))
               - DGI_INV_RECORD.DELTA_DGI;

            IF (V_REMINDER_VALUE) != 0
            THEN
               V_INV_LOG_PK := RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL;

               INSERT
                 --INTO RMKTGADM.RC_INV_DGI_ROUNDED_VALUES (INV_LOG_PK,
                 --INTO RMKTGADM.RC_INV_POE_ROUNDED_VALUES (INV_LOG_PK,
                 INTO RMKTGADM.RC_INV_DGI_ROUNDED_VALUES (INV_LOG_PK,
                                                          PRODUCT_ID,
                                                          REMINDER_VALUE,
                                                          PROCESSED_STATUS,
                                                          CREATED_BY,
                                                          CREATION_DATE,
                                                          LAST_UPDATED_DATE,
                                                          LAST_UPDATED_BY,
                                                          PRODUCT_TYPE,
                                                          SOURCE_SYSTEM)
               VALUES (V_INV_LOG_PK,
                       DGI_INV_RECORD.PRODUCT_ID,
                       - (V_REMINDER_VALUE),
                       'N',
                       'POEADMINALLOCPUT<0',
                       SYSDATE,
                       SYSDATE,
                       'POEADMINALLOCPUT<0',
                       DGI_INV_RECORD.PRODUCT_TYPE,
                       DGI_INV_RECORD.SOURCE_SYSTEM);

               UPDATE RMKTGADM.RC_INV_DGI_DELTA --RMKTGADM.RC_INV_POE_DELTA --RC_INV_DGI_DELTA
                  SET DELTA_DGI = - (FLOOR (ABS (DGI_INV_RECORD.DELTA_DGI)))
                WHERE     1 = 1
                      AND PRODUCT_ID = DGI_INV_RECORD.PRODUCT_ID
                      AND PRODUCT_TYPE = DGI_INV_RECORD.PRODUCT_TYPE
                      AND SOURCE_SYSTEM = DGI_INV_RECORD.SOURCE_SYSTEM;

               COMMIT;
            END IF;
         END IF;
      /* End Modified logic for Negative DGI Scenario on 04-FEB-2019 */
      --      --
      --      INSERT INTO RC_ROUND_TRACK(product_id,
      --                                    DELTA_DGI,
      --                                    REMINDER_VALUE_put,
      --                                    round_DELTA_DGI ,
      --                                    REMINDER_VALUE_put_loor ,
      --                                    abs_DELTA_DGI ,
      --                                    created ,
      --                                    fun ,
      --                                    get_DELTA_DGI ,
      --                                    get_ROUND_VALUE ) VALUES
      --                                    (DGI_INV_RECORD.PRODUCT_ID,
      --                                    DGI_INV_RECORD.DELTA_DGI ,
      --                                    V_REMINDER_VALUE,
      --                                    ROUND (DGI_INV_RECORD.DELTA_DGI) - DGI_INV_RECORD.DELTA_DGI,
      --                                     - (FLOOR (ABS (DGI_INV_RECORD.DELTA_DGI))) - DGI_INV_RECORD.DELTA_DGI,
      --                                     NULL,
      --                                     SYSDATE,'PUT_REMINDER',NULL,NULL
      --                                    );
      --      COMMIT;
      --      --
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
                   'RC_INV_POE_PUT_REMINDERS');

      G_PROC_NAME := 'RC_INV_POE_PUT_REMINDERS';

      COMMIT;
   --DBMS_OUTPUT.PUT_LINE('RC_INV_POE_PUT_REMINDERS=> End');
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
                      'RC_INV_POE_PUT_REMINDERS');

         G_PROC_NAME := 'RC_INV_POE_PUT_REMINDERS';

         COMMIT;

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_POE_PUT_REMINDERS;

   PROCEDURE RC_INV_POE_GET_REMINDERS
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
             FROM RMKTGADM.RC_INV_DGI_ROUNDED_VALUES --RC_INV_POE_ROUNDED_VALUES --RC_INV_DGI_ROUNDED_VALUES
            WHERE     PROCESSED_STATUS = 'N'
                  AND PRODUCT_TYPE = 'E'
                  AND SOURCE_SYSTEM = 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
         GROUP BY PRODUCT_ID, PRODUCT_TYPE              -->>> , SITE_SHORTNAME
           HAVING SUM (REMINDER_VALUE) >= 1 OR SUM (REMINDER_VALUE) <= -1;

      DGI_RND_REC        DGI_CURSOR_RND%ROWTYPE;
   BEGIN
      --DBMS_OUTPUT.PUT_LINE('RC_INV_POE_GET_REMINDERS=> Start');
      G_PROC_NAME := 'RC_INV_POE_GET_REMINDERS';

      L_START_TIME := SYSDATE;

      OPEN DGI_CURSOR_RND;

      LOOP
         FETCH DGI_CURSOR_RND INTO DGI_RND_REC;

         EXIT WHEN DGI_CURSOR_RND%NOTFOUND;

         /* Start Modified logic for Negative DGI Scenario on 04-FEB-2019 */

         IF DGI_RND_REC.DELTA_DGI >= 0
         THEN
            V_ROUND_VALUE := ROUND (DGI_RND_REC.DELTA_DGI);
         ELSIF DGI_RND_REC.DELTA_DGI < 0
         THEN
            V_ROUND_VALUE := - (FLOOR (ABS (DGI_RND_REC.DELTA_DGI)));
         END IF;

         /* End Modified logic for Negative DGI Scenario on 04-FEB-2019 */

         IF (V_ROUND_VALUE <= -1) OR (V_ROUND_VALUE >= 1)
         THEN
            UPDATE RMKTGADM.RC_INV_DGI_ROUNDED_VALUES --RC_INV_POE_ROUNDED_VALUES --RC_INV_DGI_ROUNDED_VALUES
               SET PROCESSED_STATUS = 'Y', LAST_UPDATED_DATE = SYSDATE
             WHERE     PRODUCT_ID = DGI_RND_REC.PRODUCT_ID
                   AND PROCESSED_STATUS = 'N'
                   AND SOURCE_SYSTEM = 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                   AND PRODUCT_TYPE = DGI_RND_REC.PRODUCT_TYPE;

            V_INV_LOG_PK := RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL; -- RMK_INV_LOG_PK_SEQ.NEXTVAL;

            --INSERT INTO RMKTGADM.RC_INV_DGI_DELTA (INV_LOG_PK,
            --INSERT INTO RMKTGADM.RC_INV_POE_DELTA (INV_LOG_PK,
            INSERT INTO RMKTGADM.RC_INV_DGI_DELTA (INV_LOG_PK,
                                                   PRODUCT_ID,
                                                   DELTA_DGI,
                                                   IS_ROHS,
                                                   --   SITE_SHORTNAME,
                                                   CREATED_ON,
                                                   CREATED_BY,
                                                   UPDATED_ON,
                                                   UPDATED_BY,
                                                   PRODUCT_TYPE,
                                                   SOURCE_SYSTEM)
                 VALUES (V_INV_LOG_PK,
                         DGI_RND_REC.PRODUCT_ID,
                         ROUND (V_ROUND_VALUE),
                         'YES',
                         SYSDATE,
                         'POEADMINALLOCGET',
                         SYSDATE,
                         'POEADMINALLOCGET',
                         DGI_RND_REC.PRODUCT_TYPE,
                         'RC_INV_POE_GET_REMINDERS'); --Added  as part of Apr 17 Release for Rounding at product level

            /* Start Modified logic for Negative DGI Scenario on 04-FEB-2019 */

            IF DGI_RND_REC.DELTA_DGI >= 0
            THEN
               V_REMINDER_VALUE :=
                  ROUND (DGI_RND_REC.DELTA_DGI) - DGI_RND_REC.DELTA_DGI;
            ELSIF DGI_RND_REC.DELTA_DGI < 0
            THEN
               V_REMINDER_VALUE :=
                    -FLOOR (ABS (DGI_RND_REC.DELTA_DGI))
                  - DGI_RND_REC.DELTA_DGI;
            END IF;

            /* End Modified logic for Negative DGI Scenario on 04-FEB-2019 */

            IF V_REMINDER_VALUE != 0
            THEN
               INSERT
                 --INTO RMKTGADM.RC_INV_DGI_ROUNDED_VALUES (INV_LOG_PK,
                 --INTO RMKTGADM.RC_INV_POE_ROUNDED_VALUES (INV_LOG_PK,
                 INTO RMKTGADM.RC_INV_DGI_ROUNDED_VALUES (INV_LOG_PK,
                                                          PRODUCT_ID,
                                                          --       SITE_SHORTNAME,
                                                          REMINDER_VALUE,
                                                          PROCESSED_STATUS,
                                                          CREATED_BY,
                                                          CREATION_DATE,
                                                          LAST_UPDATED_DATE,
                                                          LAST_UPDATED_BY,
                                                          PRODUCT_TYPE,
                                                          SOURCE_SYSTEM)
               VALUES (V_INV_LOG_PK,
                       DGI_RND_REC.PRODUCT_ID,
                       - (V_REMINDER_VALUE),
                       'N',
                       'POEADMINALLOCGET!=0',
                       G_START_TIME,
                       SYSDATE,
                       'POEADMINALLOCGET!=0',
                       DGI_RND_REC.PRODUCT_TYPE,
                       'POE');
            END IF;
         END IF;

         --
         --      INSERT INTO RC_ROUND_TRACK(product_id,
         --                                    DELTA_DGI,
         --                                    REMINDER_VALUE_put,
         --                                    round_DELTA_DGI ,
         --                                    REMINDER_VALUE_put_loor ,
         --                                    abs_DELTA_DGI ,
         --                                    created ,
         --                                    fun ,
         --                                    get_DELTA_DGI ,
         --                                    get_ROUND_VALUE ) VALUES
         --                                    (DGI_RND_REC.PRODUCT_ID,
         --                                    DGI_RND_REC.DELTA_DGI ,
         --                                    V_REMINDER_VALUE,
         --                                    ROUND (DGI_RND_REC.DELTA_DGI),
         --                                     - (FLOOR (ABS (DGI_RND_REC.DELTA_DGI))),
         --                                     NULL,
         --                                     SYSDATE,'GET_REMINDER',
         --                                     ROUND (DGI_RND_REC.DELTA_DGI) - DGI_RND_REC.DELTA_DGI,
         --                                     -FLOOR (ABS (DGI_RND_REC.DELTA_DGI))- DGI_RND_REC.DELTA_DGI
         --                                    );
         COMMIT;
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
                   'RC_INV_POE_GET_REMINDERS');

      G_PROC_NAME := 'RC_INV_POE_GET_REMINDERS';
      COMMIT;
   --DBMS_OUTPUT.PUT_LINE('RC_INV_POE_GET_REMINDERS=> End');
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
                      'RC_INV_POE_GET_REMINDERS');

         G_PROC_NAME := 'RC_INV_POE_GET_REMINDERS';

         COMMIT;

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_POE_GET_REMINDERS;

   PROCEDURE RC_INV_POETOINVLOG_LOAD (P_SITE_CODE IN VARCHAR2)
   IS
      CURSOR DGI_DELTA
      IS
           SELECT DGI.PRODUCT_ID,
                  SUM (DGI.DELTA_DGI) DELTA_DGI,
                  DGI.PRODUCT_TYPE,
                  DGI.SOURCE_SYSTEM
             FROM RMKTGADM.RC_INV_DGI_DELTA DGI --RMKTGADM.RC_INV_POE_DELTA DGI --RC_INV_DGI_DELTA DGI
            WHERE 1 = 1 AND DGI.PRODUCT_TYPE = 'E' AND SOURCE_SYSTEM = 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
         GROUP BY DGI.PRODUCT_ID, DGI.PRODUCT_TYPE, DGI.SOURCE_SYSTEM;

      DGI_DELTA_REC           DGI_DELTA%ROWTYPE;
      L_START_TIME            DATE;
      L_AVAL_TO_RESERVE_DGI   NUMBER := 0;
      L_EOS_FLAG              VARCHAR2 (10) := 'N';
      L_DELTA_DGI             NUMBER := 0;
      L_AVAL_DGI              NUMBER := 0;
      email_msg_from          VARCHAR2 (100)
                                 := 'refreshcentral-support@cisco.com';
      email_receipient        VARCHAR2 (100)
                                 := 'refreshcentral-support@cisco.com'; --'daily_gdgi_addition_notifications@external.cisco.com';
      email_msg_subject       VARCHAR2 (32767);
      email_msg_body          VARCHAR2 (32767);
      processed_count         NUMBER := 0;
      l_XREF_PART_NUMBER      VARCHAR2 (100);
      l_COMMON_PART_NUMBER    VARCHAR2 (100);
      l_BTSC3_DGI             NUMBER;
      l_finial_ccw_quantity   NUMBER;
      l_curnprvrun_poedgi     NUMBER;
   BEGIN
      --DBMS_OUTPUT.PUT_LINE('RC_INV_POETOINVLOG_LOAD=> Start');

      DELETE FROM RMKTGADM.RC_INV_POE_DELTA;

      COMMIT;

      BEGIN
         INSERT INTO RMKTGADM.RC_INV_POE_DELTA (POE_BATCH_ID,
                                                INV_LOG_PK,
                                                PRODUCT_ID,
                                                DELTA_DGI,
                                                IS_ROHS,
                                                SITE_SHORTNAME,
                                                CREATED_ON,
                                                CREATED_BY,
                                                UPDATED_ON,
                                                UPDATED_BY,
                                                PRODUCT_TYPE,
                                                SOURCE_SYSTEM,
                                                INVENTORY_TYPE,
                                                BTSC3_QUANTITY,
                                                POE_QUANTITY,
                                                CCWPROCESS_QUANTITY)
            SELECT POE_BATCH_ID,
                   INV_LOG_PK,
                   PRODUCT_ID,
                   DELTA_DGI,
                   IS_ROHS,
                   SITE_SHORTNAME,
                   CREATED_ON,
                   CREATED_BY,
                   UPDATED_ON,
                   UPDATED_BY,
                   PRODUCT_TYPE,
                   SOURCE_SYSTEM,
                   INVENTORY_TYPE,
                   NULL BTSC3_QUANTITY,
                   NULL POE_QUANTITY,
                   NULL CCWPROCESS_QUANTITY
              FROM RMKTGADM.RC_INV_DGI_DELTA
             WHERE 1 = 1 AND PRODUCT_TYPE = 'E' AND SOURCE_SYSTEM = 'POE';
      EXCEPTION
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
                         L_START_TIME,
                         SYSDATE,
                         G_PROC_NAME,
                         P_SITE_CODE || '-' || G_ERROR_MSG,
                         'RC_INV_POETOINVLOG_LOAD_INSERT');
      END;

      COMMIT;

      G_PROC_NAME := 'RC_INV_POETOINVLOG_LOAD';

      L_START_TIME := SYSDATE;

      OPEN DGI_DELTA;

      LOOP
         FETCH DGI_DELTA INTO DGI_DELTA_REC;

         EXIT WHEN DGI_DELTA%NOTFOUND;

         --check if dgi_delta.product_id is in T-4, if yes pull the aval to reserve dgi
         --check how much to be processed to ccw in case of T-4 PID
         BEGIN
            L_DELTA_DGI := 0;
            L_EOS_FLAG := 'N';
            L_AVAL_TO_RESERVE_DGI := 0;
            L_AVAL_DGI := 0;
            l_XREF_PART_NUMBER := 0;
            l_COMMON_PART_NUMBER := NULL;
            l_BTSC3_DGI := 0;
            l_finial_ccw_quantity := 0;
            l_curnprvrun_poedgi := 0;

            SELECT 'Y' EOS_FLAG,
                   (SELECT SUM (AVAILABLE_TO_RESERVE_DGI)
                      FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                     WHERE     PART_NUMBER = PM.REFRESH_PART_NUMBER
                           AND INVENTORY_FLOW = 'Excess'
                           AND SITE_CODE = 'GDGI'
                           AND ROHS_COMPLIANT = 'YES')
                      AVAILABLE_TO_RESERVE_DGI,
                   (SELECT SUM (AVAILABLE_DGI)
                      FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                     WHERE     PART_NUMBER = PM.REFRESH_PART_NUMBER
                           AND INVENTORY_FLOW = 'Excess'
                           AND SITE_CODE = 'GDGI'
                           AND ROHS_COMPLIANT = 'YES')
                      AVAILABLE_DGI,
                   (SELECT NVL (SUM (DGI.DELTA_DGI), 0)
                      FROM RMKTGADM.RC_INV_DGI_DELTA DGI
                     WHERE     DGI.PRODUCT_TYPE = 'E'
                           AND DGI.PRODUCT_ID = DGI_DELTA_REC.PRODUCT_ID
                           AND DGI.PRODUCT_TYPE = 'E'
                           AND SOURCE_SYSTEM = 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                           --   AND dgi.is_rohs = 'YES'
                           --   AND dgi.site_shortname = 'GDGI'
                           AND NOT EXISTS
                                  (SELECT 1
                                     FROM RMKTGADM.RMK_INVENTORY_LOG_STG STG
                                    WHERE     STG.PART_NUMBER =
                                                 DGI.PRODUCT_ID
                                          AND STG.ROHS_COMPLIANT = 'YES'
                                          AND STG.SITE_CODE = 'GDGI' --dgi.site_shortname
                                          AND POE_BATCH_ID = 'POE' --Added this condition part of US398932 by Satyredd on 11th Aug 2020
                                          AND PROGRAM_TYPE = DGI.PRODUCT_TYPE
                                          AND CREATED_ON >
                                                 SYSDATE - 1 / 24 * 0.5))
                      DELTA_DGI
              INTO L_EOS_FLAG,
                   L_AVAL_TO_RESERVE_DGI,
                   L_AVAL_DGI,
                   L_DELTA_DGI
              FROM CRPADM.RC_PRODUCT_MASTER PM
             WHERE     PM.REFRESH_PART_NUMBER = DGI_DELTA_REC.PRODUCT_ID
                   AND PROGRAM_TYPE = 1
                   AND NVL (PM.MFG_EOS_DATE, SYSDATE + 130) <=
                          ADD_MONTHS (TRUNC (SYSDATE), 4);
         EXCEPTION
            WHEN OTHERS
            THEN
               L_EOS_FLAG := 'N';
               L_AVAL_TO_RESERVE_DGI := 0;
               L_DELTA_DGI := 0;
               L_AVAL_DGI := 0;
         END;

         BEGIN
            IF (L_EOS_FLAG = 'Y' AND L_DELTA_DGI <> 0)
            THEN
               IF L_AVAL_TO_RESERVE_DGI > 0
               THEN
                  IF (-L_DELTA_DGI > L_AVAL_TO_RESERVE_DGI)
                  THEN
                     L_DELTA_DGI := L_DELTA_DGI;
                  ELSE
                     L_DELTA_DGI := -L_AVAL_TO_RESERVE_DGI;
                  END IF;
               ELSIF L_AVAL_TO_RESERVE_DGI = 0
               THEN
                  IF L_DELTA_DGI < 0
                  THEN
                     L_DELTA_DGI := L_DELTA_DGI;
                  ELSE
                     L_DELTA_DGI := 0;
                  END IF;
               ELSIF L_AVAL_TO_RESERVE_DGI < 0
               THEN
                  IF L_DELTA_DGI >= 0
                  THEN
                     L_DELTA_DGI :=
                        LEAST (-L_AVAL_TO_RESERVE_DGI, L_DELTA_DGI);
                  ELSE
                     L_DELTA_DGI := L_DELTA_DGI;
                  END IF;
               END IF;

               IF (L_DELTA_DGI < 0)
               THEN
                  L_DELTA_DGI := -LEAST (L_AVAL_DGI, -L_DELTA_DGI);
               END IF;

               DGI_DELTA_REC.DELTA_DGI := L_DELTA_DGI;
            ELSIF (L_EOS_FLAG = 'Y' AND L_DELTA_DGI = 0)
            THEN
               DGI_DELTA_REC.DELTA_DGI := L_DELTA_DGI;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;

         --End PID Deactivation changes - restrict DGI for T-4 PIDs

         IF (DGI_DELTA_REC.DELTA_DGI <> 0)
         THEN --added for PID Deactivation changes - restrict DGI for T-4 PIDs
            -- Getting WS partnumer
            BEGIN
               SELECT COMMON_PART_NUMBER, XREF_PART_NUMBER
                 INTO l_COMMON_PART_NUMBER, l_XREF_PART_NUMBER
                 FROM CRPADM.RC_PRODUCT_MASTER PM
                WHERE     program_type = 1                                --ws
                      AND (   REFRESH_PART_NUMBER = DGI_DELTA_REC.PRODUCT_ID
                           OR PM.COMMON_PART_NUMBER =
                                 DGI_DELTA_REC.PRODUCT_ID
                           OR PM.XREF_PART_NUMBER = DGI_DELTA_REC.PRODUCT_ID);
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_COMMON_PART_NUMBER := 0;
                  l_XREF_PART_NUMBER := 0;
            END;

            l_BTSC3_DGI := 0;

            -- LATEEST VALUE FROM BTSC3
            BEGIN
               SELECT NVL (ROUND (SUM (e.WS_QTY_AFTER_YIELD)), 0)
                 INTO l_BTSC3_DGI
                 FROM CRPADM.RC_INV_BTS_C3_MV e
                      INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                         ON (   e.PART_NUMBER = PM.REFRESH_PART_NUMBER
                             OR e.PART_NUMBER = PM.COMMON_PART_NUMBER
                             OR e.PART_NUMBER = PM.XREF_PART_NUMBER)
                WHERE     pm.REFRESH_PART_NUMBER = DGI_DELTA_REC.PRODUCT_ID --Refresh part number --pm1.REFRESH_PART_NUMBER--a.PART_NUMBER
                      AND (   E.part_number = l_COMMON_PART_NUMBER --pm1.COMMON_PART_NUMBER     --new
                           OR E.part_number = l_XREF_PART_NUMBER) --pm1.XREF_PART_NUMBER)     --new
                      AND pm.program_type = 1
                      AND LOCATION IN ('POE-DGI',
                                       'POE-NEWX',
                                       'POE-NEW',
                                       'POE-NRHS',
                                       'POE-LT')
                      AND DECODE (
                             WS_REFURB_METHOD,
                             NULL, DECODE (LOCATION, 'POE-LT', 'SCREEN'),
                             WS_REFURB_METHOD)
                             IS NOT NULL                                 --NEW
                      AND SUBSTR (site, 1, 3) IN ('Z05', 'Z29');         --new
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_BTSC3_DGI := 0;
            END;

            l_curnprvrun_poedgi := DGI_DELTA_REC.DELTA_DGI;

            --f poe<c3 then
            IF DGI_DELTA_REC.DELTA_DGI < L_BTSC3_DGI
            THEN
               --dbms_output.put_line('POE qty LESS than C3 qty, Then process POE qty');
               l_finial_ccw_quantity := DGI_DELTA_REC.DELTA_DGI;
            --Elsif poe>c3 then
            ELSIF DGI_DELTA_REC.DELTA_DGI > L_BTSC3_DGI
            THEN
               --dbms_output.put_line('C3 qty is less than POE qty, Then process C3 qty');
               l_finial_ccw_quantity := L_BTSC3_DGI;
            ELSIF DGI_DELTA_REC.DELTA_DGI = L_BTSC3_DGI
            THEN
               --dbms_output.put_line('C3 qty is equal POE qty, Then process C3 qty');
               l_finial_ccw_quantity := DGI_DELTA_REC.DELTA_DGI;
            END IF;

            --Processing POEDGI into Inventory log table
            DGI_DELTA_REC.DELTA_DGI := l_finial_ccw_quantity;

            --                                    dbms_output.put_line('DGI_DELTA_REC.PRODUCT_ID=> '||DGI_DELTA_REC.PRODUCT_ID
            --                                                          ||' <DGI_DELTA_REC.DELTA_DGI=> '||DGI_DELTA_REC.DELTA_DGI
            --                                                          ||' <l_currentrun_lastrun_poedgi=> '||DGI_DELTA_REC.DELTA_DGI
            --                                                          ||' <L_BTSC3_DGI=> '||L_BTSC3_DGI);

            UPDATE RMKTGADM.RC_INV_POE_DELTA
               SET BTSC3_QUANTITY = L_BTSC3_DGI,
                   POE_QUANTITY = l_curnprvrun_poedgi,
                   CCWPROCESS_QUANTITY = l_finial_ccw_quantity
             WHERE     PRODUCT_ID = DGI_DELTA_REC.PRODUCT_ID
                   AND PRODUCT_TYPE = 'E';

            BEGIN
               IF    DGI_DELTA_REC.DELTA_DGI = 0
                  OR DGI_DELTA_REC.DELTA_DGI IS NULL
               THEN
                  UPDATE RMKTGADM.RC_INV_MIN_DGI
                     SET STATUS = 'Y',
                         LAST_UPDATED_DATE = SYSDATE,
                         LAST_UPDATED_BY = 'POE_LOAD'
                   WHERE     REFRESH_PART_NUMBER = DGI_DELTA_REC.PRODUCT_ID
                         AND PRODUCT_TYPE = 'E'
                         AND SOURCE_SYSTEM = 'POE'
                         AND STATUS = 'N';
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;

            COMMIT;

            BEGIN
               --INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG (INVENTORY_LOG_ID,
               --INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_POE_STG (INVENTORY_LOG_ID,
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
                    VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL,
                            DGI_DELTA_REC.PRODUCT_ID,
                            0,
                            DGI_DELTA_REC.DELTA_DGI,
                            'YES',
                            'GDGI',
                            'N',
                            DGI_DELTA_REC.PRODUCT_TYPE,
                            SYSDATE,
                            'POEADMIN',                        --G_UPDATED_BY,
                            SYSDATE,
                            'POEADMIN',                        --G_UPDATED_BY,
                            DGI_DELTA_REC.SOURCE_SYSTEM);
            EXCEPTION
               WHEN OTHERS
               THEN
                  G_ERROR_MSG :=
                        'Insert error'
                     || SUBSTR (SQLERRM, 1, 200)
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
                               'RMK_INVENTORY_LOG_STG');

                  COMMIT;
            END;
         END IF;
      END LOOP;

      CLOSE DGI_DELTA;

      COMMIT;

      ---End

      -->> DGI Insert, Required.
      INSERT INTO RMKTGADM.RC_INV_DGI_DELTA_HIST --RC_INV_POE_DELTA_HIST --RC_INV_DGI_DELTA_HIST
         SELECT *
           FROM RMKTGADM.RC_INV_DGI_DELTA --RC_INV_POE_DELTA --RC_INV_DGI_DELTA
          WHERE PRODUCT_TYPE = 'E' AND SOURCE_SYSTEM = 'POE'; --Added this condition part of US398932 by Satyredd on 11th Aug 2020

      COMMIT;

      SELECT COUNT (*)
        INTO PROCESSED_COUNT
        FROM RMKTGADM.RC_INV_DGI_DELTA    --RC_INV_POE_DELTA--RC_INV_DGI_DELTA
       WHERE PRODUCT_TYPE = 'E' AND SOURCE_SYSTEM = 'POE'; --Added this condition part of US398932 by Satyredd on 11th Aug 2020

      email_msg_subject :=
            'Excess - POE Quantities for '
         || TO_CHAR (P_SITE_CODE)
         || ' site is processed for '
         || TO_CHAR (SYSDATE);
      email_msg_body :=
            '<body>
                       Hi Team,<br><br>Excess-DGI Quantities for '
         || TO_CHAR (P_SITE_CODE)
         || ' SITE is processed for '
         || TO_CHAR (SYSDATE)
         || '<br><br>
                       For any queries please contact Refresh Support Team:  refreshcentral-support@cisco.com.<br><br>
                       Thanks,<br>
                       Cisco Refresh Team.</body>';

      IF (PROCESSED_COUNT >= 1)
      THEN
         BEGIN
            crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (
               email_msg_from,
               email_receipient,
               email_msg_subject,
               email_msg_body,
               NULL,
               NULL);
         EXCEPTION
            WHEN OTHERS
            THEN
               v_message := SUBSTR (SQLERRM, 1, 50);
         END;
      END IF;

      DELETE FROM RMKTGADM.RC_INV_DGI_DELTA                 --RC_INV_DGI_DELTA
            WHERE PRODUCT_TYPE = 'E' AND POE_BATCH_ID = 'POE';

      DELETE FROM RMKTGADM.RMK_INVENTORY_LOG_STG --RMK_INVENTORY_LOG_POE_STG --RMK_INVENTORY_LOG_STG
            WHERE NEW_FGI = 0 AND NEW_DGI = 0 AND POE_BATCH_ID = 'POE'; --Added this condition part of US398932 by Satyredd on 11th Aug 2020

      --to Insert the Delta inv into  rmk_inventory_log from  rmk_inventory_log_stg

      INSERT INTO RMK_INVENTORY_LOG                        --RMK_INVENTORY_LOG
         SELECT *
           FROM RMK_INVENTORY_LOG_STG --RMK_INVENTORY_LOG_POE_STG --RMK_INVENTORY_LOG_STG
          WHERE ATTRIBUTE1 IS NULL AND POE_BATCH_ID = 'POE'; --Added this condition part of US398932 by Satyredd on 11th Aug 2020

      --      --Updating the rmk_inventory_log_stg table after processing the Delta Inv.

      UPDATE RMK_INVENTORY_LOG_STG --RMK_INVENTORY_LOG_POE_STG --RMK_INVENTORY_LOG_STG
         SET ATTRIBUTE1 = 'PROCESSED'
       WHERE ATTRIBUTE1 IS NULL AND POE_BATCH_ID = 'POE'; --Added this condition part of US398932 by Satyredd on 11th Aug 2020

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
                   NULL,
                   'RC_INV_POETOINVLOG_LOAD');

      ----      UPDATE RMKTGADM.CRON_CONTROL_INFO
      ----         SET CRON_START_TIMESTAMP = G_START_TIME,
      ----             CRON_END_TIMESTAMP = SYSDATE,
      ----             CRON_STATUS = 'SUCCESS'
      ----       WHERE     CRON_NAME = 'RC_INV_POETOINVLOG_LOAD'
      ----             AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'EX_MAIN';

      G_PROC_NAME := 'RC_INV_POETOINVLOG_LOAD';

      COMMIT;
   --DBMS_OUTPUT.PUT_LINE('RC_INV_POETOINVLOG_LOAD=> End');
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
                      'RC_INV_POETOINVLOG_LOAD');

         G_PROC_NAME := 'RC_INV_POETOINVLOG_LOAD';

         --         UPDATE RMKTGADM.CRON_CONTROL_INFO
         --            SET CRON_START_TIMESTAMP = G_START_TIME,
         --                CRON_END_TIMESTAMP = SYSDATE,
         --                CRON_STATUS = 'FAILED'
         --          WHERE     CRON_NAME = 'RC_INV_POETOINVLOG_LOAD'
         --                AND CRON_CONTACT_ID = P_SITE_CODE || '-' || 'EX_MAIN'; -->>Added

         COMMIT;

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_POETOINVLOG_LOAD;

   PROCEDURE RC_MAIN
   IS
      P_SITE_CODE                 VARCHAR2 (20) := 'GDGI';
      l_cron_end_timestamp        DATE;
      l_delta_first_run           VARCHAR2 (1);
      l_c3_start                  NUMBER;
      l_c3_end                    NUMBER;
      ERROR_MSG                   VARCHAR2 (10000);
      l_POETOINVLOG_LOAD_count    NUMBER;
      G_AllocPOE_DeltaProcessed   VARCHAR2 (25);
   BEGIN
      BEGIN
         SELECT delta_first_run, cron_end_timestamp
           INTO l_delta_first_run, l_cron_end_timestamp
           FROM rmktgadm.cron_control_info
          WHERE     cron_name = 'RC_ALLOCATION_ENGINE.MAIN'
                AND cron_status = 'END'
                AND TRUNC (cron_end_timestamp) = TRUNC (SYSDATE);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_delta_first_run := 'E';
            l_cron_end_timestamp := SYSDATE;
         WHEN OTHERS
         THEN
            g_error_msg :=
                  'Error while getting status from cron_control_info: '
               || SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12);
      END;

      --  l_delta_first_run := 'N'; -------------------------------------------------------------------------

      IF l_delta_first_run = 'N'
      THEN
         BEGIN
            SELECT COUNT (*)
              INTO l_c3_start
              FROM CRPADM.RC_CRON_HISTORY_LOG
             WHERE     chl_cron_name = 'REFRESH_BTS_C3_INV_DATA'
                   AND chl_status = 'START'
                   AND chl_start_timestamp BETWEEN l_cron_end_timestamp
                                               AND SYSDATE;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_c3_start := 0;
            WHEN OTHERS
            THEN
               g_error_msg :=
                     'Error while getting C3 refresh START status from RC_CRON_HISTORY_LOG: '
                  || SUBSTR (SQLERRM, 1, 200)
                  || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12);
         END;

         BEGIN
            SELECT COUNT (*)
              INTO l_c3_end
              FROM CRPADM.RC_CRON_HISTORY_LOG            --RC_CRON_HISTORY_LOG
             WHERE     chl_cron_name = 'REFRESH_BTS_C3_INV_DATA'
                   AND chl_status = 'SUCCESS'
                   AND chl_end_timestamp BETWEEN l_cron_end_timestamp
                                             AND SYSDATE;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_c3_end := 0;
            WHEN OTHERS
            THEN
               g_error_msg :=
                     'Error while getting C3 refresh END status from RC_CRON_HISTORY_LOG: '
                  || SUBSTR (SQLERRM, 1, 200)
                  || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12);
         END;

         --l_c3_start:= 1;
         --l_c3_end:=1;
         --DBMS_OUTPUT.PUT_LINE(l_c3_start ||' <COUNTS> '||l_c3_end);
         IF l_c3_start <> 0 AND l_c3_end <> 0
         THEN
            G_AllocPOE_DeltaProcessed := 'N';

            EXECUTE IMMEDIATE 'TRUNCATE TABLE rc_inv_bts_c3_mv_poe';

            INSERT INTO rc_inv_bts_c3_mv_poe
               SELECT * FROM crpadm.rc_inv_bts_c3_mv;

            COMMIT;
         ELSE
            G_AllocPOE_DeltaProcessed := 'Y';
         END IF;
      ELSIF l_delta_first_run = 'E'
      THEN
         G_AllocPOE_DeltaProcessed := 'E';

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
                 VALUES (
                           SEQ_CHL_ID.NEXTVAL,
                           'Error',
                           SYSDATE,
                           SYSDATE,
                           'RC_MAIN',
                           'Allocation process failed due to that POE delta unable to process',
                           'RMKTGADM');

         COMMIT;
      END IF;

      --DBMS_OUTPUT.PUT_LINE('INSIDE=> '||G_AllocPOE_DeltaProcessed);
      IF G_AllocPOE_DeltaProcessed = 'N'
      THEN
         -- DBMS_OUTPUT.PUT_LINE ('INSIDE=> ' || G_AllocPOE_DeltaProcessed);

         ALLOC_C3_POE_YIELD_CALC;

         RC_INV_POE_EXTRACT (NULL, P_SITE_CODE);

         RC_INV_POE_HISTORY (P_SITE_CODE);

         RC_INV_POE_DELTA_PROCESS (P_SITE_CODE);

         RC_INV_POE_PUT_REMINDERS;

         -- RC_INV_POE_GET_REMINDERS;

         RC_INV_POETOINVLOG_LOAD (P_SITE_CODE);
      END IF;

      --Validating all process get completed or not
      BEGIN
         SELECT COUNT (*)
           INTO l_POETOINVLOG_LOAD_count
           FROM RMKTGADM.CRON_HISTORY_LOG
          WHERE     CHL_CREATED_BY = 'RC_INV_POETOINVLOG_LOAD'
                AND CHL_STATUS = 'SUCCESS'
                AND TRUNC (CHL_END_TIMESTAMP) = TRUNC (SYSDATE);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_POETOINVLOG_LOAD_count := 0;
      END;

      IF l_POETOINVLOG_LOAD_count > 0 AND G_AllocPOE_DeltaProcessed = 'N'
      THEN
         BEGIN
            UPDATE rmktgadm.cron_control_info
               SET delta_first_run = 'Y'
             WHERE     cron_name = 'RC_ALLOCATION_ENGINE.MAIN'
                   AND cron_status = 'END'
                   AND TRUNC (cron_end_timestamp) = TRUNC (SYSDATE);
         EXCEPTION
            WHEN OTHERS
            THEN
               g_error_msg :=
                     'Error while updating cron_control_info: '
                  || SUBSTR (SQLERRM, 1, 200)
                  || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12);
         END;
      END IF;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         --ERROR_MSG := 'Error while executing RC_MAIN';
         ERROR_MSG :=
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
                      'EXCEPTION',
                      SYSDATE,
                      SYSDATE,
                      'RC_MAIN',
                      ERROR_MSG,                              --'NULL VALUES',
                      'RMKTGADM');

         COMMIT;
   END RC_MAIN;
/***End*************** POE Delta Process to CCW *************************/

END RC_INV_DELTA_LOAD_EX;
/