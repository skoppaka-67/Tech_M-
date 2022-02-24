CREATE OR REPLACE PACKAGE BODY RMKTGADM./*AppDB: 1045364*/
                                   "RC_INV_RECON_ADJ_PKG"
AS
   /*
  ****************************************************************************************************************
  * Object Name       :RC_INV_RECON_ADJ_PKG
  *  Project Name : Refresh Central
   * Copy Rights:   Cisco Systems, INC., CALIFORNIA
  * Description       : This API for Inventory Adjustment reconcialiation
  * Created Date: 2nd May, 2017
  ===================================================================================================+
  * Version              Date                     Modified by                     Description
  ===================================================================================================+
   1.0                   2nd May, 2017            satbanda                     Created for Inventory Adjustment Reconciliation
   1.1                   15th May, 2017           satbanda                     Added the logic for batching process
   1.2                   18th May, 2017           satbanda                     Modified the logic for Adjustment process
   1.3                   29th May, 2017           satbanda                     Modified for FB02 data and Refresh time validation.
   1.4                   20th July,2017           satbanda                     Modified for US122733 (Sorting and Advanced Filter)
   1.5                   31st Aug, 2017           satbanda                     Modified for US134969 (Searching capability for Multiple requests at a time)
   2.0                   17th Oct,2017            satbanda                     Modified for Negative Recon inventory Adjustment issue
   2.1                   17th Oct,2017            satbanda                     Modified for populating requestId in download report.
   3.0                   29th Nov,2017            satbanda                     Modified for US153769 - Recon Enhancements
   4.0                   12th Jan,2017            satbanda                     Modified for US148664 - displaying the Recon History
   4.1                   14-Mar-2017              satbanda                     Modified for US170475 - Extension of the FVE received Quantity Check to Five Days
   4.2                   20-MAR-2017              hkarka                       modified the code for case # INC0417150 - consider always today's transactions for LRO
   4.3                   29-OCT-2018              sridvasu                     As part of US204871 modified the code to consider more PO's
   4.4                  13-NOV-2018              sridvasu                     Added a new variable because of length issue
   4.5                   12-APR-2019              sridvasu                     As part of US293797 modified the code to consider more PO's CSY, CSX, CSR, CSP and CSQ Recon restriction from 7 days to 2 days
   4.6                   17-APR-2019              sridvasu                     As part of US293797 modified the code to look sum of qty of TAN and PID
   4.7                   19-AUG-2019              sneyadav                     As part of US333206 modified code to substract CSQ qty from CDC qty
   4.8                   27-AUG-2019              abhat2                       As part of US333352 modified code to include strategic pid quantity when recon runs
   4.9                   25-Sep-2019              sneyadav                     As part of INC1882261 modified code to include 914 series for FVE on hand qty
  ===================================================================================================+
   **************************************************************************************************************** */


   v_message   VARCHAR2 (32767);

   PROCEDURE P_RCEC_ERROR_LOG (i_Module_Name        VARCHAR2,
                               i_Entity_Name        VARCHAR2 DEFAULT NULL,
                               i_Entity_ID          VARCHAR2 DEFAULT NULL,
                               i_EXT_Entity_Name    VARCHAR2 DEFAULT NULL,
                               i_EXT_Entity_ID      VARCHAR2 DEFAULT NULL,
                               i_Error_Type         VARCHAR2,
                               i_Error_Message      VARCHAR2,
                               i_Created_by         VARCHAR2,
                               i_UPDATED_BY         VARCHAR2)
   AS
      l_errid   NUMBER;
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      v_message := NULL;

      SELECT RMK_INV_ERROR_S.NEXTVAL INTO l_errid FROM DUAL;

      INSERT INTO RMK_INV_ERROR_LOG (ERR_ID,
                                     Module_Name,
                                     Entity_Name,
                                     Entity_ID,
                                     EXT_Entity_Name,
                                     EXT_Entity_ID,
                                     ERROR_TYPE,
                                     Error_Message,
                                     CREATED_BY,
                                     CREATION_DATE,
                                     LAST_UPDATED_BY,
                                     LAST_UPDATE_DATE)
           VALUES (l_errid,
                   i_Module_Name,
                   i_Entity_Name,
                   i_Entity_ID,
                   i_EXT_Entity_Name,
                   i_EXT_Entity_ID,
                   i_Error_Type,
                   i_Error_Message,
                   i_CREATED_BY,
                   SYSDATE,
                   i_UPDATED_BY,
                   SYSDATE);

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message :=
               SUBSTR (SQLERRM, 1, 200)
            || ' i_Module_Name->'
            || i_Module_Name
            || ' i_Entity_Name->'
            || i_Entity_Name
            || ' i_Entity_ID->'
            || i_Entity_ID
            || ' i_EXT_Entity_Name->'
            || i_EXT_Entity_Name
            || ' i_EXT_Entity_ID->'
            || i_EXT_Entity_ID
            || ' i_Error_Type->'
            || i_Error_Type
            || ' i_Error_Message->'
            || i_Error_Message
            || ' i_CREATED_BY->'
            || i_CREATED_BY
            || ' i_UPDATED_BY->'
            || i_UPDATED_BY;

         SELECT RMK_INV_ERROR_S.NEXTVAL INTO l_errid FROM DUAL;

         INSERT INTO RMK_INV_ERROR_LOG (ERR_ID,
                                        Module_Name,
                                        Error_Message,
                                        CREATION_DATE)
              VALUES (l_errid,
                      'ERROR_LOG',
                      v_message,
                      SYSDATE);

         COMMIT;
   END P_RCEC_ERROR_LOG;

   PROCEDURE P_INV_LOC_RECONCILIATION (
      i_site_loc            IN            VARCHAR2,
      i_reconcile_flag      IN            VARCHAR2,
      i_recon_batch_id      IN            VARCHAR2, --Added by satbanda on 12th Jan,2018 for US148664 Recon History
      i_user_id             IN            VARCHAR2,
      i_min_row                           VARCHAR2,
      i_max_row                           VARCHAR2,
      o_last_loc_run           OUT NOCOPY VARCHAR2,
      o_display_count          OUT NOCOPY NUMBER,
      o_inv_recon_tab          OUT NOCOPY RC_INV_RECON_ADJ_TAB,
      o_inv_recon_all_tab      OUT NOCOPY RC_INV_RECON_ADJ_TAB,
      o_process_check_msg      OUT NOCOPY RC_INV_MESSAGE_TAB)
   AS
      lv_site_loc              VARCHAR2 (30);
      lv_query                 CLOB;
      lv_query_wh              CLOB;
      lv_query1                VARCHAR2 (32767); -- added on 13-Nov-2018 by sridvasu
      lv_excess_query          VARCHAR2 (32767);
      lv_stg_query             CLOB;
      lv_fb02_stg_table        VARCHAR2 (100);
      lv_min_row               NUMBER;
      lv_max_row               NUMBER;
      lv_count_query           CLOB;
      lv_display_count         NUMBER;
      lv_lastrun_min           VARCHAR2 (10);
      lv_reconui_batch_id      VARCHAR2 (200);
      lv_last_loc_run          VARCHAR2 (32767);
      type_inv_recon_tab       RC_INV_RECON_ADJ_TAB := RC_INV_RECON_ADJ_TAB ();
      type_inv_recon_tab1      RC_INV_RECON_ADJ_TAB := RC_INV_RECON_ADJ_TAB ();
      type_inv_recon_all_tab   RC_INV_RECON_ADJ_TAB
                                  := RC_INV_RECON_ADJ_TAB ();
      lv_process_check_tab     RC_INV_MESSAGE_TAB := RC_INV_MESSAGE_TAB ();
      lv_recon_start_time      DATE;
      lv_recon_end_time        DATE;
      lv_adj_start_time        DATE;
      lv_adj_end_time          DATE;
      lv_adj_job_status        VARCHAR2 (20);
      --Added for US153769 <Start>
      lv_restrict_min          NUMBER;
      lv_report_older_time     NUMBER;
      --Added for US153769 <End>
      --Added by satbanda for US148664 (Recon Histroy) <Start>
      lv_recon_his_batch_id    VARCHAR2 (50);
      lv_recon_status          VARCHAR2 (50);
      lv_process_cnt           NUMBER;
      lv_err_count             NUMBER := 0;
      --Added by satbanda for US148664 (Recon Histroy) <End>
      -- lv_db_linkcon_cnt NUMBER:=0; --FVE Recon Received Qty Changes on 2nd March,2018
      --FVE Recon Received Qty Changes on 14th March,2018 <start>
      lv_received_cnt          NUMBER := 0;
      lv_run_flag              VARCHAR2 (50);
      lv_received_qtymsg       VARCHAR2 (2000);
   --FVE Recon Received Qty Changes on 14th March,2018 <End>
   BEGIN
      lv_site_loc := UPPER (TRIM (i_site_loc));
      lv_min_row := i_min_row;
      lv_max_row := i_max_row;
      lv_recon_his_batch_id := TRIM (i_recon_batch_id); --Added by satbanda for US148664 (Recon Histroy)

      lv_reconui_batch_id := NULL;

      --      DBMS_MVIEW.REFRESH ('RC_STRATEGIC_PIDS_ORDERS_MV'); -- Refreshing Strategic Pids MV

      IF lv_site_loc = v_FVE
      THEN
         lv_fb02_stg_table := 'SC_FB02_STG_FVE';
      ELSIF lv_site_loc = v_LRO
      THEN
         lv_fb02_stg_table := 'SC_FB02_STG_LRO';
      END IF;

      --FVE Recon Received Qty Changes on 14th March,2018 <Start>
      IF lv_site_loc = v_FVE
      THEN
         lv_run_flag := NULL;

         BEGIN
            SELECT COUNT (1)
              INTO lv_received_cnt
              FROM RC_INV_4B2_LRO_FVE_QUANTITY
             WHERE     STATUS_FLAG IN ('CURRENT')
                   AND UPPER (MESSAGE_ID) LIKE 'FVE%'
                   AND TRUNC (CREATE_DATE) >= TRUNC (SYSDATE);

            IF lv_received_cnt = 0
            THEN
               SELECT COUNT (1)
                 INTO lv_received_cnt
                 FROM RC_INV_4B2_LRO_FVE_QUANTITY
                WHERE     STATUS_FLAG IN ('LASTRUN')
                      AND UPPER (MESSAGE_ID) LIKE 'FVE%'
                      AND TRUNC (CREATE_DATE) >= TRUNC (SYSDATE);

               IF lv_received_cnt <> 0
               THEN
                  lv_run_flag := 'LASTRUN';
               ELSE
                  lv_run_flag := 'NORUN';
               END IF;
            ELSE
               lv_run_flag := 'CURRENT';
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_received_cnt := 0;
         END;


         lv_received_qtymsg := NULL;

         IF lv_received_cnt = 0
         THEN
            lv_received_qtymsg :=
                  ' <br>'
               || ' Pealse note, CG1 Received Quantity is not found/available and hence received quantity is not considered in current FVE reconciliation';
         END IF;
      END IF;

      --FVE Recon Received Qty Changes on 14th March,2018 <End>


      --Added by satbanda on 12th Jan,2018 for US148664 (Recon Histroy) <Start>


      IF lv_recon_his_batch_id IS NOT NULL
      THEN
         BEGIN
            SELECT START_DATE,
                   COMPLETION_DATE,
                   ATTRIBUTE1,
                   STATUS
              INTO lv_recon_start_time,
                   lv_recon_end_time,
                   lv_reconui_batch_id,
                   lv_recon_status
              FROM RC_INV_RECONUI_SETUP
             WHERE     MODULE_NAME = v_recon_job
                   AND ATTRIBUTE1 = lv_recon_his_batch_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_recon_start_time := NULL;
               lv_recon_end_time := NULL;
               lv_reconui_batch_id := NULL;
         END;

         BEGIN
            SELECT START_DATE, COMPLETION_DATE, STATUS
              INTO lv_adj_start_time, lv_adj_end_time, lv_adj_job_status
              FROM RC_INV_RECONUI_SETUP
             WHERE     MODULE_NAME = v_adjmnt_job
                   AND ATTRIBUTE1 = lv_reconui_batch_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_adj_start_time := NULL;
               lv_adj_end_time := NULL;
               lv_adj_job_status := NULL;
         END;
      ELSE
         --Added by satbanda on 12th Jan,2018 for US148664 (Recon Histroy) <End>
         BEGIN
            SELECT START_DATE, COMPLETION_DATE, ATTRIBUTE1
              INTO lv_recon_start_time,
                   lv_recon_end_time,
                   lv_reconui_batch_id
              FROM RC_INV_RECONUI_SETUP
             WHERE     ATTRIBUTE2 = lv_site_loc
                   AND MODULE_NAME = v_recon_job
                   AND START_DATE =
                          (SELECT MAX (START_DATE)
                             FROM RC_INV_RECONUI_SETUP
                            WHERE     ATTRIBUTE2 = lv_site_loc
                                  AND MODULE_NAME = v_recon_job);
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_recon_start_time := NULL;
               lv_recon_end_time := NULL;
               lv_reconui_batch_id := NULL;
         END;

         BEGIN
            SELECT START_DATE, COMPLETION_DATE, STATUS
              INTO lv_adj_start_time, lv_adj_end_time, lv_adj_job_status
              FROM RC_INV_RECONUI_SETUP
             WHERE     ATTRIBUTE2 = lv_site_loc
                   AND MODULE_NAME = v_adjmnt_job
                   AND ATTRIBUTE1 = lv_reconui_batch_id;
         /*       AND START_DATE = (SELECT MAX(START_DATE)
                                   FROM RC_INV_RECONUI_SETUP
                                  WHERE ATTRIBUTE2 = lv_site_loc
                                    AND MODULE_NAME = v_adjmnt_job); */
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_adj_start_time := NULL;
               lv_adj_end_time := NULL;
               lv_adj_job_status := NULL;
         END;
      --Added by satbanda on 12th Jan,2018 for US148664 (Recon Histroy) <Start>
      END IF;

      SELECT COUNT (1)
        INTO lv_process_cnt
        FROM RC_INV_RECONUI_SETUP
       WHERE     ATTRIBUTE2 = lv_site_loc
             AND MODULE_NAME = v_adjmnt_job
             AND ATTRIBUTE1 = lv_reconui_batch_id;

      --Added by satbanda on 12th Jan,2018 for US148664 (Recon Histroy) <End>

      IF i_reconcile_flag = 'N' OR lv_recon_his_batch_id IS NOT NULL --Added by satbanda on 12th Jan,2018 for US148664 (Recon Histroy)
      THEN
         --Added for US153769 <Start>
         BEGIN
            SELECT UDC_1
              INTO lv_restrict_min
              FROM crpexcess.RCEC_EXCESS_CONFIG
             WHERE config_id = 10 AND CONFIG_TYPE = v_restrict_conf_type;
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_restrict_min := 120;
         END;

         lv_report_older_time :=
              (  SYSDATE
               - TO_DATE ('' || SUBSTR (lv_reconui_batch_id, 14) || '',
                          'MMDDYYYYHH24MISS'))
            * 24
            * 60;


         --Added for US153769 <End>

         IF lv_recon_start_time IS NOT NULL AND lv_recon_end_time IS NULL
         THEN
            v_message :=
               'Reconciliation for this location in progress, please wait for the Reconciliation Process to complete';
            lv_err_count := lv_err_count + 1;

            lv_process_check_tab.EXTEND;
            lv_process_check_tab (lv_err_count) :=
               RC_INV_MESSAGE_OBJ ('RECONUI',
                                   NULL,
                                   NULL,
                                   NULL,
                                   'ERROR',
                                   v_message);
         --Added for US153769 <Start>
         ELSIF     lv_report_older_time > lv_restrict_min
               AND lv_recon_his_batch_id IS NULL --Added by satbanda on 12th Jan,2018 for US148664 (Recon Histroy)
               AND NVL (lv_recon_status, '*') = v_processed
               AND NVL (lv_process_cnt, 0) = 0
         THEN
            BEGIN
               UPDATE RC_INV_RECONUI_SETUP
                  SET STATUS = v_ignored,
                      LAST_UPDATED_BY = i_user_id,
                      LAST_UPDATED_DATE = SYSDATE
                WHERE     ATTRIBUTE2 = lv_site_loc
                      AND MODULE_NAME = v_recon_job
                      AND STATUS = v_reconciled
                      AND ATTRIBUTE1 = lv_reconui_batch_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_message := SUBSTR (SQLERRM, 1, 200);

                  P_RCEC_ERROR_LOG (
                     I_module_name       => 'P_INV_LOC_RECONCILIATION',
                     I_entity_name       => NULL,
                     I_entity_id         => NULL,
                     I_ext_entity_name   => NULL,
                     I_ext_entity_id     => NULL,
                     I_error_type        => 'EXCEPTION',
                     i_Error_Message     =>    'Error getting while updating RC_INV_RECONUI_SETUP table '
                                            || ' <> '
                                            || v_message
                                            || ' LineNo=> '
                                            || DBMS_UTILITY.Format_error_backtrace,
                     I_created_by        => i_user_id,
                     I_updated_by        => i_user_id);
            END;

            v_message :=
                  'Reconciliation for '
               || lv_site_loc
               || ' was last run at '
               || TO_CHAR (
                     TO_DATE ('' || SUBSTR (lv_reconui_batch_id, 14) || '',
                              'MMDDYYYYHH24MISS'),
                     'HH:Mi AM "PST on "Day Ddth Mon, YYYY.')
               || ' which is older than '
               || lv_restrict_min
               || ' minutes. Please rerun reconciliation';

            lv_err_count := lv_err_count + 1;


            lv_process_check_tab.EXTEND;
            lv_process_check_tab (lv_err_count) :=
               RC_INV_MESSAGE_OBJ ('RECONUI',
                                   NULL,
                                   NULL,
                                   NULL,
                                   'ERROR',
                                   v_message);
         --Added for US153769 <End>
         ELSIF lv_recon_start_time IS NULL AND lv_recon_end_time IS NULL
         THEN
            GOTO Display_output;
         ELSE
            --Added by satbanda on 18th Jan,2018 for US148664 (Recon Histroy) <Start>

            IF     lv_report_older_time > lv_restrict_min
               AND lv_recon_his_batch_id IS NOT NULL
               AND lv_process_cnt = 0
               AND NVL (lv_recon_status, '*') = v_processed
            THEN
               BEGIN
                  UPDATE RC_INV_RECONUI_SETUP ris
                     SET STATUS = v_ignored,
                         LAST_UPDATED_BY = i_user_id,
                         LAST_UPDATED_DATE = SYSDATE
                   WHERE     ATTRIBUTE2 = lv_site_loc
                         AND MODULE_NAME = v_recon_job
                         AND STATUS IN (v_reconciled, v_processed)
                         AND ATTRIBUTE1 = lv_reconui_batch_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_message := SUBSTR (SQLERRM, 1, 200);

                     P_RCEC_ERROR_LOG (
                        I_module_name       => 'P_INV_LOC_RECONCILIATION',
                        I_entity_name       => NULL,
                        I_entity_id         => NULL,
                        I_ext_entity_name   => NULL,
                        I_ext_entity_id     => NULL,
                        I_error_type        => 'EXCEPTION',
                        i_Error_Message     =>    'Error getting while updating RC_INV_RECONUI_SETUP table '
                                               || ' <> '
                                               || v_message
                                               || ' LineNo=> '
                                               || DBMS_UTILITY.Format_error_backtrace,
                        I_created_by        => i_user_id,
                        I_updated_by        => i_user_id);
               END;


               v_message :=
                     'Reconciliation completion time of the batch '
                  || lv_reconui_batch_id
                  || ' is older than '
                  || lv_restrict_min
                  || ' minutes. Status has been modified. Please refresh the History';

               lv_err_count := lv_err_count + 1;
               lv_process_check_tab.EXTEND;
               lv_process_check_tab (lv_err_count) :=
                  RC_INV_MESSAGE_OBJ ('RECONUI',
                                      NULL,
                                      NULL,
                                      NULL,
                                      'ERROR',
                                      v_message);
            END IF;

            --Added by satbanda on 18th Jan,2018 for US148664 (Recon Histroy) <End>

            SELECT COUNT (*)
              INTO lv_display_count
              FROM RC_INV_ADMINUI_RECON_ADJ
             WHERE     SITE_CODE = lv_site_loc
                   AND RECON_ADJ_BATCH_ID = lv_reconui_batch_id;

            IF lv_min_row IS NULL
            THEN
               lv_min_row := 1;
               lv_max_row := lv_display_count;
            END IF;

            IF     NVL (lv_adj_job_status, '*') = v_processed
               AND lv_recon_his_batch_id IS NULL
            THEN
               lv_display_count := 0;
            END IF;

            BEGIN
               SELECT RC_INV_RECON_ADJ_OBJECT (REFRESH_PART_NUMBER,
                                               PROGRAM_TYPE,
                                               SITE_CODE,
                                               ROHS_COMPLIANT,
                                               CDC_AWAITING_SHIPMENT,
                                               CC_AWAITING_SHIPMENT,
                                               FB02_ON_HAND_QTY,
                                               TOTAL_FB02_CDC_CC_QTY,
                                               CCW_E_RESERVE_QTY,
                                               CCW_E_AVAIL_TO_RES_QTY,
                                               CCW_E_AVAILABLE_QTY,
                                               CCW_R_RESERVE_QTY,
                                               CCW_R_AVAIL_TO_RES_QTY,
                                               CCW_R_AVAILABLE_QTY,
                                               CCW_O_RESERVE_QTY,
                                               CCW_O_AVAIL_TO_RES_QTY,
                                               CCW_O_AVAILABLE_QTY,
                                               TOTAL_CCW_QTY,
                                               TOTAL_ADJUSTMENT,
                                               TOTAL_ADJUSTMENT_NEW,
                                               CDC_AWAITING_SHIPMENT_NEW,
                                               CC_AWAITING_SHIPMENT_NEW,
                                               USER_COMMENTS,
                                               NULL,
                                               V_ATTR2,
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               N_ATTR3,
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               REQUEST_ID,
                                               RECON_ADJ_BATCH_ID,
                                               ALLOW_ADJ_FLAG,
                                               ALLOW_ADJ_FLAG_NEW,
                                               APPROVAL_FLAG,
                                               STRATEGIC_MASKED_QTY)
                 BULK COLLECT INTO type_inv_recon_tab
                 FROM (SELECT *
                         FROM (SELECT REQUEST_ID,
                                      REFRESH_PART_NUMBER,
                                      PROGRAM_TYPE,
                                      SITE_CODE,
                                      ROHS_COMPLIANT,
                                      CDC_AWAITING_SHIPMENT,
                                      CC_AWAITING_SHIPMENT,
                                      FB02_ON_HAND_QTY,
                                      TOTAL_FB02_CDC_CC_QTY,
                                      CCW_E_RESERVE_QTY,
                                      CCW_E_AVAIL_TO_RES_QTY,
                                      CCW_E_AVAILABLE_QTY,
                                      CCW_R_RESERVE_QTY,
                                      CCW_R_AVAIL_TO_RES_QTY,
                                      CCW_R_AVAILABLE_QTY,
                                      CCW_O_RESERVE_QTY,
                                      CCW_O_AVAIL_TO_RES_QTY,
                                      CCW_O_AVAILABLE_QTY,
                                      TOTAL_CCW_QTY,
                                      TOTAL_ADJUSTMENT,
                                      CDC_AWAITING_SHIPMENT_NEW,
                                      CC_AWAITING_SHIPMENT_NEW,
                                      DECODE (PROCESS_STATUS,
                                              v_ignored, 0,
                                              TOTAL_ADJUSTMENT_NEW)
                                         TOTAL_ADJUSTMENT_NEW,
                                      USER_COMMENTS,
                                      RECON_ADJ_BATCH_ID,
                                      ALLOW_ADJ_FLAG,
                                      ALLOW_ADJ_FLAG_NEW,
                                      APPROVAL_FLAG,
                                      STRATEGIC_MASKED_QTY,
                                      V_ATTR2,                      --US153769
                                      N_ATTR3,            -- Recieved Quantity
                                      ROWNUM RNUM
                                 FROM (  SELECT *
                                           FROM RC_INV_ADMINUI_RECON_ADJ
                                          WHERE     SITE_CODE = lv_site_loc
                                                AND RECON_ADJ_BATCH_ID =
                                                       lv_reconui_batch_id
                                                --Added by satbanda on 18th Jan,2018 for US148664 (Recon Histroy) <Start>
                                                AND (   lv_recon_his_batch_id
                                                           IS NOT NULL
                                                     OR (    process_status NOT IN
                                                                (v_processed,
                                                                 v_ignored)
                                                         AND NVL (
                                                                lv_adj_job_status,
                                                                '*') NOT IN
                                                                (v_processed,
                                                                 v_ignored)))
                                       /*  AND process_status NOT IN ( v_processed, v_ignored)
                                        AND NVL(lv_adj_job_status,'*') NOT IN ( v_processed, v_ignored) */
                                       --Added by satbanda on 18th Jan,2018 for US148664 (Recon Histroy) <End>
                                       ORDER BY REQUEST_ID,
                                                REFRESH_PART_NUMBER,
                                                PROGRAM_TYPE DESC,
                                                ROHS_COMPLIANT DESC)
                                WHERE ROWNUM <= lv_max_row)
                        WHERE RNUM >= lv_min_row);

               --Added by satbanda on 22nd Jan,2018 for US148664 (Recon Histroy) <Start>
               IF type_inv_recon_tab.EXISTS (1)
               THEN
                  type_inv_recon_tab :=
                     F_GET_ADJINV_RETAIL_OUTLET (type_inv_recon_tab);
               END IF;

               --Added by satbanda on 22nd Jan,2018 for US148664 (Recon Histroy) <End>


               --for all records
               SELECT RC_INV_RECON_ADJ_OBJECT (REFRESH_PART_NUMBER,
                                               PROGRAM_TYPE,
                                               SITE_CODE,
                                               ROHS_COMPLIANT,
                                               CDC_AWAITING_SHIPMENT,
                                               CC_AWAITING_SHIPMENT,
                                               FB02_ON_HAND_QTY,
                                               TOTAL_FB02_CDC_CC_QTY,
                                               CCW_E_RESERVE_QTY,
                                               CCW_E_AVAIL_TO_RES_QTY,
                                               CCW_E_AVAILABLE_QTY,
                                               CCW_R_RESERVE_QTY,
                                               CCW_R_AVAIL_TO_RES_QTY,
                                               CCW_R_AVAILABLE_QTY,
                                               CCW_O_RESERVE_QTY,
                                               CCW_O_AVAIL_TO_RES_QTY,
                                               CCW_O_AVAILABLE_QTY,
                                               TOTAL_CCW_QTY,
                                               TOTAL_ADJUSTMENT,
                                               TOTAL_ADJUSTMENT_NEW,
                                               CDC_AWAITING_SHIPMENT_NEW,
                                               CC_AWAITING_SHIPMENT_NEW,
                                               USER_COMMENTS,
                                               NULL,
                                               V_ATTR2,
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               N_ATTR3,
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               REQUEST_ID,
                                               RECON_ADJ_BATCH_ID,
                                               ALLOW_ADJ_FLAG,
                                               ALLOW_ADJ_FLAG_NEW,
                                               APPROVAL_FLAG,
                                               STRATEGIC_MASKED_QTY)
                 BULK COLLECT INTO type_inv_recon_all_tab
                 FROM (SELECT *
                         FROM (SELECT REQUEST_ID,
                                      REFRESH_PART_NUMBER,
                                      PROGRAM_TYPE,
                                      SITE_CODE,
                                      ROHS_COMPLIANT,
                                      CDC_AWAITING_SHIPMENT,
                                      CC_AWAITING_SHIPMENT,
                                      FB02_ON_HAND_QTY,
                                      TOTAL_FB02_CDC_CC_QTY,
                                      CCW_E_RESERVE_QTY,
                                      CCW_E_AVAIL_TO_RES_QTY,
                                      CCW_E_AVAILABLE_QTY,
                                      CCW_R_RESERVE_QTY,
                                      CCW_R_AVAIL_TO_RES_QTY,
                                      CCW_R_AVAILABLE_QTY,
                                      CCW_O_RESERVE_QTY,
                                      CCW_O_AVAIL_TO_RES_QTY,
                                      CCW_O_AVAILABLE_QTY,
                                      TOTAL_CCW_QTY,
                                      TOTAL_ADJUSTMENT,
                                      CDC_AWAITING_SHIPMENT_NEW,
                                      CC_AWAITING_SHIPMENT_NEW,
                                      DECODE (PROCESS_STATUS,
                                              v_ignored, 0,
                                              TOTAL_ADJUSTMENT_NEW)
                                         TOTAL_ADJUSTMENT_NEW,
                                      USER_COMMENTS,
                                      RECON_ADJ_BATCH_ID,
                                      ALLOW_ADJ_FLAG,
                                      ALLOW_ADJ_FLAG_NEW,
                                      APPROVAL_FLAG,
                                      STRATEGIC_MASKED_QTY,
                                      V_ATTR2,                      --US153769
                                      N_ATTR3,            -- Recieved Quantity
                                      ROWNUM RNUM
                                 FROM (  SELECT *
                                           FROM RC_INV_ADMINUI_RECON_ADJ
                                          WHERE     SITE_CODE = lv_site_loc
                                                AND RECON_ADJ_BATCH_ID =
                                                       lv_reconui_batch_id
                                                --Added by satbanda on 18th Jan,2018 for US148664 (Recon Histroy) <Start>
                                                AND (   lv_recon_his_batch_id
                                                           IS NOT NULL
                                                     OR (    process_status NOT IN
                                                                (v_processed,
                                                                 v_ignored)
                                                         AND NVL (
                                                                lv_adj_job_status,
                                                                '*') NOT IN
                                                                (v_processed,
                                                                 v_ignored)))
                                       /*  AND process_status NOT IN ( v_processed, v_ignored)
                                        AND NVL(lv_adj_job_status,'*') NOT IN ( v_processed, v_ignored) */
                                       --Added by satbanda on 18th Jan,2018 for US148664 (Recon Histroy) <End>
                                       ORDER BY REQUEST_ID,
                                                REFRESH_PART_NUMBER,
                                                PROGRAM_TYPE DESC,
                                                ROHS_COMPLIANT DESC)
                                WHERE ROWNUM <= lv_display_count)
                        WHERE RNUM >= 1);

               --Added by satbanda on 22nd Jan,2018 for US148664 (Recon Histroy) <Start>
               IF type_inv_recon_all_tab.EXISTS (1)
               THEN
                  type_inv_recon_all_tab :=
                     F_GET_ADJINV_RETAIL_OUTLET (type_inv_recon_all_tab);
               END IF;
            --Added by satbanda on 22nd Jan,2018 for US148664 (Recon Histroy) <End>

            EXCEPTION
               WHEN OTHERS
               THEN
                  v_message := SUBSTR (SQLERRM, 1, 200);

                  P_RCEC_ERROR_LOG (
                     I_module_name       => 'P_INV_LOC_RECONCILIATION',
                     I_entity_name       => NULL,
                     I_entity_id         => NULL,
                     I_ext_entity_name   => NULL,
                     I_ext_entity_id     => NULL,
                     I_error_type        => 'EXCEPTION',
                     i_Error_Message     =>    'Error getting while fetching all data from  RC_INV_ADMINUI_RECON_ADJ table '
                                            || ' <> '
                                            || v_message
                                            || ' LineNo=> '
                                            || DBMS_UTILITY.Format_error_backtrace,
                     I_created_by        => i_user_id,
                     I_updated_by        => i_user_id);

                  v_message :=
                     'Error getting due to technical issues: ' || v_message;

                  lv_err_count := lv_err_count + 1;

                  lv_process_check_tab.EXTEND;
                  lv_process_check_tab (lv_err_count) :=
                     RC_INV_MESSAGE_OBJ ('RECONUI',
                                         NULL,
                                         NULL,
                                         NULL,
                                         'ERROR',
                                         v_message);
            END;
         END IF;

         GOTO Display_output;
      ELSE
         IF lv_adj_start_time IS NOT NULL AND lv_adj_end_time IS NULL
         THEN
            v_message :=
               'Process Adjustment for this location in progress, please wait for the Adjustment Process to complete';
            lv_err_count := lv_err_count + 1;

            lv_process_check_tab.EXTEND;
            lv_process_check_tab (lv_err_count) :=
               RC_INV_MESSAGE_OBJ ('RECONUI',
                                   NULL,
                                   NULL,
                                   NULL,
                                   'ERROR',
                                   v_message);
            GOTO Display_output;
         END IF;


         IF lv_min_row = 1 OR lv_min_row IS NULL
         THEN
            lv_reconui_batch_id :=
                  'RECONCIL_'
               || lv_site_loc
               || '_'
               || TO_CHAR (SYSDATE, 'MMDDYYYYHH24MISS');

            INSERT INTO RC_INV_RECONUI_SETUP (EXECUTABLE_ID,
                                              MODULE_NAME,
                                              ATTRIBUTE1,
                                              ATTRIBUTE2,
                                              START_DATE,
                                              ACTIVE_FLAG,
                                              STATUS,
                                              CREATED_BY,
                                              CREATED_DATE)
                 VALUES (RC_INV_RECONUI_SETUP_SEQ.NEXTVAL,
                         v_recon_job,
                         lv_reconui_batch_id,
                         lv_site_loc,
                         SYSDATE,
                         v_y_flag,
                         v_running_sts,
                         i_user_id,
                         SYSDATE);
         END IF;

         lv_query :=
               'WITH FVE_RECON
                AS
                (SELECT refresh_part_number,
                        ''Retail+Outlet'' PROGRAM_TYPE,'''
            || lv_site_loc
            || '''SITE_CODE,
                        ROHS_COMPLIANT,
                        TAN_ID, --Added for US153769
                        TOTAL_FB02_CDC_CC_QTY,
                       CCW_TOTAL_QTY,
                       FB02_ON_HAND_QTY,
                       INTRANSIT_SHIP_QTY,
                       ABS_CCW_TOTAL_QTY,
                       ABS_FB02_TOTAL_QTY,
                       CDC_AWAITING_SHIPMENT,
                       CDC_AWAITING_SHIPMENT_OLD,
                       CC_AWAITING_SHIPMENT,
                       DIFF,
                       CCW_R_AVAILABLE_QTY,
                       CCW_R_RESERVE_QTY,
                       CCW_R_AVAIL_TO_RES_QTY,
                       CCW_O_AVAILABLE_QTY,
                       CCW_O_RESERVE_QTY,
                       CCW_O_AVAIL_TO_RES_QTY,
                       DIFF TOTAL_ADJUSTMENT,
                       DIFF_OLD TOTAL_ADJUSTMENT_OLD,
                       ENABLE_FLAG
                       ,RECEIVED_QTY,  --Added by satbanda for Received Qty Validation
                       MASKED_QTY STRATEGIC_MASKED_QTY
                FROM
                (SELECT pm.refresh_part_number,
                        pm.TAN_ID, --Added for US153769
                         rohs.ROHS_COMPLIANT,
                       (nvl( im_r.Available_FGI,0) + nvl( im_o.Available_FGI,0)) CCW_TOTAL_QTY,
                       NVL (fb02.FB02_Total_Available_Qty, 0) FB02_ON_HAND_QTY,
                       NVL (cdc.CDC_AWAITING_SHIPMENT, 0) CDC_AWAITING_SHIPMENT,
                       NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) CDC_AWAITING_SHIPMENT_OLD,
                       NVL (cc.CC_AWAITING_SHIPMENT, 0) CC_AWAITING_SHIPMENT,
                       DECODE('''
            || lv_site_loc
            || ''','''
            || v_FVE
            || ''', NVL (cc.CC_AWAITING_SHIPMENT, 0),0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) INTRANSIT_SHIP_QTY,
                       NVL (fb02.FB02_Total_Available_Qty, 0) +  NVL (cdc.CDC_AWAITING_SHIPMENT, 0)  TOTAL_FB02_CDC_CC_QTY,
                       CASE
                         WHEN '''
            || lv_site_loc
            || '''='''
            || v_LRO
            || ''' 
                         AND rohs.ROHS_COMPLIANT = ''YES'' THEN
                            NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) - (NVL (im.CCW_Available_FGI_RO, 0) + NVL (rspo.LRO_RHS_QUANTITY, 0))
                         WHEN '''
            || lv_site_loc
            || '''='''
            || v_LRO
            || ''' 
                         AND rohs.ROHS_COMPLIANT = ''NO'' THEN
                            NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) - (NVL (im.CCW_Available_FGI_RO, 0) + NVL (rspo.LRO_NRHS_QUANTITY, 0))   
                         WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' 
                         AND rohs.ROHS_COMPLIANT = ''YES'' AND 
                         (NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) - NVL (im.CCW_Available_FGI_RO, 0) >=0)  THEN
                            NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) - (NVL (im.CCW_Available_FGI_RO, 0) + NVL (rspo.FVE_RHS_QUANTITY, 0))
                         WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' 
                         AND rohs.ROHS_COMPLIANT = ''NO'' AND 
                         (NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) - NVL (im.CCW_Available_FGI_RO, 0) >=0)  THEN
                            NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) - (NVL (im.CCW_Available_FGI_RO, 0))      
                         WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' 
                         AND rohs.ROHS_COMPLIANT = ''YES'' AND ABS(NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) - NVL (im.CCW_Available_FGI_RO, 0) )> NVL (cc.CC_AWAITING_SHIPMENT, 0) THEN
                            NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) +  NVL (cc.CC_AWAITING_SHIPMENT, 0) - (NVL (im.CCW_Available_FGI_RO, 0) + NVL (rspo.FVE_RHS_QUANTITY, 0))
                         WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' 
                         AND rohs.ROHS_COMPLIANT = ''NO'' AND ABS(NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) - NVL (im.CCW_Available_FGI_RO, 0) )> NVL (cc.CC_AWAITING_SHIPMENT, 0) THEN
                            NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) +  NVL (cc.CC_AWAITING_SHIPMENT, 0) - (NVL (im.CCW_Available_FGI_RO, 0))
                         WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' 
                         AND rohs.ROHS_COMPLIANT = ''YES'' THEN
                             NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) - (NVL (im.CCW_Available_FGI_RO, 0) + NVL (rspo.FVE_RHS_QUANTITY, 0))         
                         ELSE
                             NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) - (NVL (im.CCW_Available_FGI_RO, 0))
                       END DIFF,
                       CASE
                         WHEN '''
            || lv_site_loc
            || '''='''
            || v_LRO
            || ''' 
                         AND rohs.ROHS_COMPLIANT = ''YES'' THEN
                            NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) - (NVL (im.CCW_Available_FGI_RO, 0) + NVL (rspo.LRO_RHS_QUANTITY, 0))
                         WHEN '''
            || lv_site_loc
            || '''='''
            || v_LRO
            || ''' 
                         AND rohs.ROHS_COMPLIANT = ''NO'' THEN
                            NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) - (NVL (im.CCW_Available_FGI_RO, 0) + NVL (rspo.LRO_NRHS_QUANTITY, 0))   
                         WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' 
                         AND rohs.ROHS_COMPLIANT = ''YES'' AND (NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) - NVL (im.CCW_Available_FGI_RO, 0) >=0)  THEN
                            NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) - (NVL (im.CCW_Available_FGI_RO, 0) + NVL (rspo.FVE_RHS_QUANTITY, 0))
                         WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' 
                         AND rohs.ROHS_COMPLIANT = ''NO'' AND (NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) - NVL (im.CCW_Available_FGI_RO, 0) >=0)  THEN
                            NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) - (NVL (im.CCW_Available_FGI_RO, 0))      
                         WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' 
                         AND rohs.ROHS_COMPLIANT = ''YES'' AND ABS(NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) - NVL (im.CCW_Available_FGI_RO, 0) )> NVL (cc.CC_AWAITING_SHIPMENT, 0) THEN
                            NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) +  NVL (cc.CC_AWAITING_SHIPMENT, 0) - (NVL (im.CCW_Available_FGI_RO, 0) + NVL (rspo.FVE_RHS_QUANTITY, 0))
                         WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' 
                         AND rohs.ROHS_COMPLIANT = ''NO'' AND ABS(NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) - NVL (im.CCW_Available_FGI_RO, 0) )> NVL (cc.CC_AWAITING_SHIPMENT, 0) THEN
                            NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) +  NVL (cc.CC_AWAITING_SHIPMENT, 0) - (NVL (im.CCW_Available_FGI_RO, 0))
                         WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' 
                         AND rohs.ROHS_COMPLIANT = ''YES'' THEN
                             NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) - (NVL (im.CCW_Available_FGI_RO, 0) + NVL (rspo.FVE_RHS_QUANTITY, 0))  
                         ELSE
                             NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) - (NVL (im.CCW_Available_FGI_RO, 0))
                       END DIFF_OLD,
                      CASE
                         WHEN (NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) - NVL (im.CCW_Available_FGI_RO, 0) >=0) OR '''
            || lv_site_loc
            || '''='''
            || v_LRO
            || ''' THEN
                            ''Y''
                         WHEN ABS(NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) - NVL (im.CCW_Available_FGI_RO, 0) )> NVL (cc.CC_AWAITING_SHIPMENT, 0) THEN
                            ''Y''
                         ELSE
                            ''N''
                       END ENABLE_FLAG,
                       NVL (im_o.Available_FGI, 0) im_o_available_fgi,
                       ABS (NVL (fb02.FB02_Total_Available_Qty, 0)) ABS_FB02_TOTAL_QTY,
                       ABS (NVL (im.CCW_Available_FGI_RO, 0)) ABS_CCW_TOTAL_QTY,
                       NVL (im_r.Available_FGI, 0) CCW_R_AVAILABLE_QTY,
                       NVL( im_o.available_fgi,0) CCW_O_AVAILABLE_QTY,
                       NVL (im_r.reserved_fgi, 0) CCW_R_RESERVE_QTY,
                       NVL( im_o.reserved_fgi,0) CCW_O_RESERVE_QTY,
                       NVL (im_r.available_to_reserve_fgi, 0) CCW_R_AVAIL_TO_RES_QTY,
                       NVL( im_o.available_to_reserve_fgi,0) CCW_O_AVAIL_TO_RES_QTY,
                       CASE
                            WHEN NVL( fb02.FB02_Total_Available_Qty,0) + DECODE('''
            || lv_site_loc
            || ''','''
            || v_FVE
            || ''', NVL (cc.CC_AWAITING_SHIPMENT, 0),0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) <> NVL( im.CCW_Available_FGI_RO,0)
                            THEN ''DIFF''
                            WHEN NVL( fb02.FB02_Total_Available_Qty,0) + DECODE('''
            || lv_site_loc
            || ''','''
            || v_FVE
            || ''', NVL (cc.CC_AWAITING_SHIPMENT, 0),0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) = NVL( im.CCW_Available_FGI_RO,0)
                            THEN ''SAME''
                       END STATUS
                        --Added by satbanda for Received Qty Validation <Start>
                       ,
                       CASE
                            WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' AND '''
            || lv_run_flag
            || '''<> ''NORUN'' THEN
                               (SELECT  NVL(SUM(po_received_qty),0)
                                FROM RC_INV_4B2_LRO_FVE_QUANTITY a
--                               WHERE (po_number LIKE ''CSC%'' OR po_number LIKE ''TRF%'') -->> Commented to consider more POs on 29-OCT-2018 by sridvasu 
                                 WHERE REGEXP_LIKE (PO_NUMBER, ''^(TR|CSC7|907|904|909|900|700|C20|C10|CSY|CSX|CSR|CSP|CSQ)'') -->> Added to consider more POs on 29-OCT-2018 by sridvasu -->> Added POs CSY , CSX , CSR , CSP and CSQ on 12-APR-2019 by sridvasu
                                 AND TRUNC(LN_CREATION_DATE) BETWEEN TRUNC (SYSDATE-5) AND TRUNC (SYSDATE-1)
                                 AND TRUNC(CREATE_DATE)=TRUNC(SYSDATE)
                                 AND UPPER(MESSAGE_ID) LIKE ''FVE%''
                                 AND END_USER_PRODUCT_ID=  PM.TAN_ID
                                 AND STATUS_FLAG = '''
            || lv_run_flag
            || ''' )
                            ELSE 0
                       END RECEIVED_QTY,
                      --Added by satbanda for Received Qty Validation <End>
                      CASE
                         WHEN '''
            || lv_site_loc
            || '''='''
            || v_LRO
            || ''' 
                         AND rohs.ROHS_COMPLIANT = ''YES'' THEN NVL (rspo.LRO_RHS_QUANTITY, 0)
                       WHEN '''
            || lv_site_loc
            || '''='''
            || v_LRO
            || ''' 
                         AND rohs.ROHS_COMPLIANT = ''NO'' THEN NVL (rspo.LRO_NRHS_QUANTITY, 0)
                        WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' 
                         AND rohs.ROHS_COMPLIANT = ''YES'' THEN NVL (rspo.FVE_RHS_QUANTITY, 0)     
                         ELSE 0
                       END MASKED_QTY
                  FROM crpadm.rc_product_master pm
                       LEFT OUTER JOIN
                       (SELECT REGEXP_SUBSTR (''YES,NO'', ''[^,]+'',1, LEVEL) ROHS_COMPLIANT
                        FROM DUAL
                        CONNECT BY REGEXP_SUBSTR (''YES,NO'', ''[^,]+'',1, LEVEL)  IS NOT NULL) Rohs
                        on (pm.REFRESH_PART_NUMBER = pm.REFRESH_PART_NUMBER)
                       LEFT OUTER JOIN
                       --INNER JOIN
                       (  SELECT part_number part,rohs_compliant,
                                 SUM (NVL(available_fgi,0)) CCW_Available_FGI_RO
                            FROM xxcpo_rmk_inventory_master
                           WHERE Inventory_flow in ( ''Retail'',''Outlet'')
                             AND site_code = '''
            || lv_site_loc
            || '''
                             --AND NVL(available_fgi,0)<>0
                        GROUP BY part_number,rohs_compliant) im
                          ON (pm.REFRESH_PART_NUMBER = im.part AND im.ROHS_COMPLIANT=rohs.ROHS_COMPLIANT)
                       LEFT OUTER JOIN
                       (  SELECT REFRESH_PART_NUMBER,
--                                 PRODUCT_ID, -->> Commented as part of US293797 modified the code to look sum of qty of TAN and PID on 17-APR-2019 by sridvasu
                                 CASE WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' THEN '''
            || v_yes_flag
            || '''
                                 ELSE DECODE(ROHS_FLAG,''NON-ROHS'','''
            || v_no_flag
            || ''','''
            || v_yes_flag
            || ''')
                                 END ROHS_COMPLIANT,
                                 SUM (AVAILABLE_QTY + Allocated_Qty + Picked_Qty)
                                    FB02_Total_Available_Qty
                            FROM crpsc.'
            || lv_fb02_stg_table
            || '
                           WHERE  1=1 ';

         IF lv_site_loc = v_FVE
         THEN
            lv_query :=
                  lv_query
               || ' --AND (po_number LIKE ''CSC%'' OR po_number LIKE ''TRF%'') -->> Commented to consider more POs on 29-OCT-2018 by sridvasu
                                                       AND REGEXP_LIKE (PO_NUMBER, ''^(TR|CSC7|907|904|900|909|700|C20|C10|CSY|CSX|CSR|CSP|CSQ|914)'') -->> Added to consider more POs on 29-OCT-2018 by sridvasu -->> Added POs CSY , CSX , CSR , CSP and CSQ on 12-APR-2019 by sridvasu
                                                       AND TRUNC (line_creation_date) =
                                                                (SELECT TRUNC (MAX (line_creation_date))
                                                                   FROM crpsc.'
               || lv_fb02_stg_table
               || ' )';
         ELSIF lv_site_loc = v_LRO
         THEN
            lv_query :=
               lv_query || ' AND UPPER(ROHS_FLAG)  NOT LIKE ''OTH%'' ';
            lv_query :=
               lv_query || ' AND TRUNC(INV_CREATION_DATE) = TRUNC(SYSDATE) '; --added by hkarka on 20-MAR-2018
         END IF;


         lv_query :=
               lv_query
            || '
--                        GROUP BY REFRESH_PART_NUMBER, PRODUCT_ID , ROHS_FLAG) fb02 -->> Commented as part of US293797 modified the code to look sum of qty of TAN and PID on 17-APR-2019 by sridvasu
                         GROUP BY REFRESH_PART_NUMBER,ROHS_FLAG) fb02 -->> Added as part of US293797 modified the code to look sum of qty of TAN and PID on 17-APR-2019 by sridvasu
                          ON (pm.refresh_part_number = fb02.refresh_part_number AND fb02.ROHS_COMPLIANT=rohs.ROHS_COMPLIANT)
                        LEFT OUTER JOIN
                           (SELECT PRODUCT_ID,
                                   CD.ROHS_COMPLIANT ROHS_COMPLIANT,
                                   CASE WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' THEN
                                   (CASE
                                      WHEN (NVL (CD.CDC_AWAITING_SHIPMENT, 0) - NVL (CSQ_QTY, 0)) > 0
                                      THEN
                                         NVL (CD.CDC_AWAITING_SHIPMENT, 0) - NVL (CSQ_QTY, 0)
                                      ELSE
                                         0
                                   END)
                                   ELSE
                                    CD.CDC_AWAITING_SHIPMENT
                                   END
                                      AS CDC_AWAITING_SHIPMENT,
                                   CD.CDC_AWAITING_SHIPMENT AS CDC_AWAITING_SHIPMENT_OLD
                              FROM (SELECT PRODUCT_ID,ROHS_COMPLIANT,SUM (ORDERED_QUANTITY) CDC_AWAITING_SHIPMENT
                                    FROM (SELECT R3R.PRODUCT_ID,
                                    CASE WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' THEN '''
            || v_yes_flag
            || '''
                                    WHEN (SELECT count(*)
                                    FROM RMK_SSOT_TRANSACTIONS RST
                                    WHERE     SALES_ORDER_NUMBER = TO_CHAR (R3R.ORDER_NUMBER)
                                              AND PRODUCT_ID = R3R.PRODUCT_ID
                                              AND SALES_ORDER_LINE_NUMBER = R3R.line_number )>0
                                              THEN
                                               (SELECT ROHS_COMPLIANT
                                               FROM RMK_SSOT_TRANSACTIONS RST
                                               WHERE     SALES_ORDER_NUMBER = TO_CHAR (R3R.ORDER_NUMBER)
                                                         AND PRODUCT_ID = R3R.PRODUCT_ID
                                                         AND SALES_ORDER_LINE_NUMBER = R3R.line_number
                                                         AND ROWNUM < 2)
                                              ELSE
                                                (SELECT ROHS_COMPLIANT
                                                 FROM RMK_SSOT_TRANSACTIONS RST
                                                 WHERE     SALES_ORDER_NUMBER = TO_CHAR (R3R.ORDER_NUMBER)
                                                           AND PRODUCT_ID = R3R.PRODUCT_ID
                                                           AND ROWNUM < 2)
                                              END ROHS_COMPLIANT,
                                              R3R.ORDERED_QUANTITY
                                              FROM RC_SSOT_3A4_BACKLOG R3R
                                              WHERE     1 = 1
                                                        AND R3R.PRODUCTION_RESULT_CODE = ''AWAITING_SHIPPING''
                                                        AND ORDER_HOLDS IS NULL --Added for US153769
                                                        AND OTM_SHIPPING_ROUTE_CODE LIKE ''CDC%''
                                                        AND R3R.ORGANIZATION_CODE = '''
            || lv_site_loc
            || ''')
                                              GROUP BY PRODUCT_ID,ROHS_COMPLIANT) CD
                                   LEFT OUTER JOIN
                                   (SELECT REFRESH_PART_NUMBER,
                                           CASE
                                              WHEN '''
            || lv_site_loc
            || ''' = '''
            || v_FVE
            || '''
                                              THEN
                                                     '''
            || v_yes_flag
            || '''
                                           ELSE
                                              DECODE (ROHS_FLAG, ''NON-ROHS'','''
            || v_no_flag
            || ''','''
            || v_yes_flag
            || ''')
                                           END ROHS_COMPLIANT,
                                           SUM (AVAILABLE_QTY + Allocated_Qty + Picked_Qty) CSQ_QTY
                                        FROM crpsc.'
            || lv_fb02_stg_table
            || '
                                        WHERE  1=1
                                        AND REGEXP_LIKE (PO_NUMBER, ''^(CSQ)'')
                                        AND TRUNC (line_creation_date) =
                                            (SELECT TRUNC (MAX (line_creation_date))
                                              FROM crpsc.'
            || lv_fb02_stg_table
            || ' )
                                        GROUP BY REFRESH_PART_NUMBER,ROHS_FLAG) CS
                                      ON    ( CD.PRODUCT_ID = CS.REFRESH_PART_NUMBER
                                         AND CD.ROHS_COMPLIANT = CS.ROHS_COMPLIANT )) CDC
                            ON (pm.REFRESH_PART_NUMBER = cdc.PRODUCT_ID AND cdc.ROHS_COMPLIANT=rohs.ROHS_COMPLIANT)
                            LEFT OUTER JOIN
                               (SELECT PRODUCT_ID,ROHS_COMPLIANT,SUM (ORDERED_QUANTITY) CC_AWAITING_SHIPMENT
                                FROM (SELECT R3R.PRODUCT_ID,
                                         CASE WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' THEN '''
            || v_yes_flag
            || '''
                                         WHEN (SELECT count(*)
                                                FROM RMK_SSOT_TRANSACTIONS RST
                                               WHERE     SALES_ORDER_NUMBER = TO_CHAR (R3R.ORDER_NUMBER)
                                                     AND PRODUCT_ID = R3R.PRODUCT_ID
                                                     AND SALES_ORDER_LINE_NUMBER = R3R.line_number )>0
                                          THEN
                                             (SELECT ROHS_COMPLIANT
                                                FROM RMK_SSOT_TRANSACTIONS RST
                                               WHERE     SALES_ORDER_NUMBER = TO_CHAR (R3R.ORDER_NUMBER)
                                                     AND PRODUCT_ID = R3R.PRODUCT_ID
                                                     AND SALES_ORDER_LINE_NUMBER = R3R.line_number
                                                     AND ROWNUM < 2)
                                          ELSE
                                             (SELECT ROHS_COMPLIANT
                                                FROM RMK_SSOT_TRANSACTIONS RST
                                               WHERE     SALES_ORDER_NUMBER = TO_CHAR (R3R.ORDER_NUMBER)
                                                     AND PRODUCT_ID = R3R.PRODUCT_ID
                                                     AND ROWNUM < 2)
                                                END ROHS_COMPLIANT,
                                         R3R.ORDERED_QUANTITY
                                    FROM RC_SSOT_3A4_BACKLOG R3R
                                   WHERE     1 = 1
                                         AND R3R.PRODUCTION_RESULT_CODE = ''AWAITING_SHIPPING''
                                         AND OTM_SHIPPING_ROUTE_CODE LIKE ''CC%''
                                         AND R3R.ORGANIZATION_CODE = '''
            || lv_site_loc
            || ''')
                                GROUP BY PRODUCT_ID,ROHS_COMPLIANT) CC
                                ON (pm.REFRESH_PART_NUMBER = cc.PRODUCT_ID AND cc.ROHS_COMPLIANT=rohs.ROHS_COMPLIANT)
                                LEFT OUTER JOIN
                       (  SELECT part_number part,rohs_compliant,
                                 SUM (NVL(available_fgi,0)) available_fgi,
                                 SUM (NVL(reserved_fgi,0)) reserved_fgi,
                                 SUM (NVL(available_to_reserve_fgi,0)) available_to_reserve_fgi
                            FROM xxcpo_rmk_inventory_master
                           WHERE Inventory_flow in ( ''Retail'')
                             --AND NVL(available_fgi,0)<>0
                             AND site_code = '''
            || lv_site_loc
            || '''
                        GROUP BY part_number,rohs_compliant) im_r
                          ON (pm.REFRESH_PART_NUMBER = im_r.part AND im_r.rohs_compliant=im.rohs_compliant)
                        LEFT OUTER JOIN
                       (  SELECT part_number part,rohs_compliant,
                                 SUM (NVL(available_fgi,0)) available_fgi,
                                 SUM (NVL(reserved_fgi,0)) reserved_fgi,
                                 SUM (NVL(available_to_reserve_fgi,0)) available_to_reserve_fgi
                            FROM xxcpo_rmk_inventory_master
                           WHERE Inventory_flow in ( ''Outlet'')
                             --AND NVL(available_fgi,0)<>0
                             AND site_code = '''
            || lv_site_loc
            || '''
                        GROUP BY part_number,rohs_compliant) im_o
                          ON (pm.REFRESH_PART_NUMBER = im_o.part AND im_o.rohs_compliant=im.rohs_compliant)
                        LEFT OUTER JOIN
                        ( SELECT partnumber part,
                                   LRO_RHS_QUANTITY,
                                   LRO_NRHS_QUANTITY,
                                   FVE_RHS_QUANTITY,
                                   TOTAL_QUANTITY,
                                   CREATED_ON
                              FROM RC_INV_STR_INV_MASK_MV
                             WHERE TRUNC (CREATED_ON) =
                                      (SELECT TRUNC (MAX (CREATED_ON)) FROM RC_INV_STR_INV_MASK_MV)) rspo
                          ON (pm.REFRESH_PART_NUMBER = rspo.part)  
                 WHERE     1 = 1
                       AND pm.PROGRAM_TYPE = 0
                       AND pm.TAN_ID IS NOT NULL ';

         lv_query :=
               lv_query
            || '
                       ) )
                 SELECT
                       refresh_part_number,
                       TAN_ID, --Added for US153769
                       PROGRAM_TYPE,
                       SITE_CODE,
                       ROHS_COMPLIANT,
                       CDC_AWAITING_SHIPMENT,
                       CDC_AWAITING_SHIPMENT_OLD,
                       CC_AWAITING_SHIPMENT,
                       FB02_ON_HAND_QTY,
                       TOTAL_FB02_CDC_CC_QTY,
                       0 CCW_E_RESERVE_QTY,
                       0 CCW_E_AVAIL_TO_RES_QTY,
                       0 CCW_E_AVAILABLE_QTY,
                       CCW_R_RESERVE_QTY,
                       CCW_R_AVAIL_TO_RES_QTY,
                       CCW_R_AVAILABLE_QTY,
                       CCW_O_RESERVE_QTY,
                       CCW_O_AVAIL_TO_RES_QTY,
                       CCW_O_AVAILABLE_QTY,
                       CCW_TOTAL_QTY,
                       TOTAL_ADJUSTMENT,
                       TOTAL_ADJUSTMENT_OLD,
                       ENABLE_FLAG
                       ,RECEIVED_QTY,--Added by satbanda for Received Qty Validation
                       STRATEGIC_MASKED_QTY
                FROM FVE_RECON
                WHERE TOTAL_ADJUSTMENT<>0 ';


         lv_excess_query :=
               'SELECT REFRESH_PART_NUMBER,
                        TAN_ID, --Added for US153769
                       PROGRAM_TYPE,
                       SITE_CODE,
                       ROHS_COMPLIANT,
                       CDC_AWAITING_SHIPMENT,
                       CDC_AWAITING_SHIPMENT_OLD,
                       CC_AWAITING_SHIPMENT,
                       FB02_ON_HAND_QTY,
                       TOTAL_FB02_CDC_CC_QTY,
                       CCW_E_RESERVE_QTY,
                       CCW_E_AVAIL_TO_RES_QTY,
                       CCW_E_AVAILABLE_QTY,
                       CCW_R_RESERVE_QTY,
                       CCW_R_AVAIL_TO_RES_QTY,
                       CCW_R_AVAILABLE_QTY,
                       CCW_O_RESERVE_QTY,
                       CCW_O_AVAIL_TO_RES_QTY,
                       CCW_O_AVAILABLE_QTY,
                       CCW_TOTAL_QTY,
                       TOTAL_ADJUSTMENT,
                       TOTAL_ADJUSTMENT_OLD,
                       ENABLE_FLAG
                       ,RECEIVED_QTY, --Added by satbanda for Received Qty Validation
                       MASKED_QTY STRATEGIC_MASKED_QTY
                  FROM (SELECT pm.REFRESH_PART_NUMBER,
                                --Inventory_flow PROGRAM_TYPE,
                               ''Excess'' PROGRAM_TYPE,'''
            || lv_site_loc
            || '''SITE_CODE,
                               PM.TAN_ID, --Added for US153769
                              -- SITE_CODE,
                               rohs.rohs_compliant,
                               NVL (cdc.CDC_AWAITING_SHIPMENT, 0) CDC_AWAITING_SHIPMENT,
                               NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) CDC_AWAITING_SHIPMENT_OLD,
                               NVL (cc.CC_AWAITING_SHIPMENT, 0) CC_AWAITING_SHIPMENT,
                               NVL (fb02.FB02_Total_Available_Qty, 0) FB02_ON_HAND_QTY,
                               NVL (fb02.FB02_Total_Available_Qty, 0)+ NVL (cdc.CDC_AWAITING_SHIPMENT, 0)  TOTAL_FB02_CDC_CC_QTY,
                               --NVL (fb02.FB02_Total_Available_Qty, 0)+DECODE('''
            || lv_site_loc
            || ''','''
            || v_FVE
            || ''', NVL (cc.CC_AWAITING_SHIPMENT, 0),0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0)  TOTAL_FB02_CDC_CC_QTY,
                               NVL( im.reserved_fgi,0) CCW_E_RESERVE_QTY,
                               NVL (im.available_to_reserve_fgi, 0) CCW_E_AVAIL_TO_RES_QTY,
                               NVL (im.available_fgi, 0) CCW_E_AVAILABLE_QTY,
                               0 CCW_R_RESERVE_QTY,
                               0 CCW_R_AVAIL_TO_RES_QTY,
                               0 CCW_R_AVAILABLE_QTY,
                               0 CCW_O_RESERVE_QTY,
                               0 CCW_O_AVAIL_TO_RES_QTY,
                               0 CCW_O_AVAILABLE_QTY,
                               NVL (im.available_fgi, 0) CCW_TOTAL_QTY,
                               CASE
                                 WHEN (NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) - NVL (im.available_fgi, 0) >=0) OR '''
            || lv_site_loc
            || '''='''
            || v_LRO
            || ''' THEN
                                    NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) - NVL (im.available_fgi, 0)
                                 WHEN ABS(NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) - NVL (im.available_fgi, 0) )> NVL (cc.CC_AWAITING_SHIPMENT, 0) THEN
                                    NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) +  NVL (cc.CC_AWAITING_SHIPMENT, 0) - NVL (im.available_fgi, 0)
                                 ELSE
                                    NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) - NVL (im.available_fgi, 0)
                               END TOTAL_ADJUSTMENT
                               ,CASE
                                 WHEN (NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) - NVL (im.available_fgi, 0) >=0) OR '''
            || lv_site_loc
            || '''='''
            || v_LRO
            || ''' THEN
                                    NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) - NVL (im.available_fgi, 0)
                                 WHEN ABS(NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) - NVL (im.available_fgi, 0) )> NVL (cc.CC_AWAITING_SHIPMENT, 0) THEN
                                    NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) +  NVL (cc.CC_AWAITING_SHIPMENT, 0) - NVL (im.available_fgi, 0)
                                 ELSE
                                    NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT_OLD, 0) - NVL (im.available_fgi, 0)
                               END TOTAL_ADJUSTMENT_OLD
                               ,CASE
                                 WHEN (NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) - NVL (im.available_fgi, 0) >=0) OR '''
            || lv_site_loc
            || '''='''
            || v_LRO
            || ''' THEN
                                    ''Y''
                                 WHEN ABS(NVL (fb02.FB02_Total_Available_Qty, 0)+NVL (cdc.CDC_AWAITING_SHIPMENT, 0) - NVL (im.available_fgi, 0) )> NVL (cc.CC_AWAITING_SHIPMENT, 0) THEN
                                    ''Y''
                                 ELSE
                                    ''N''
                               END ENABLE_FLAG
                               --Added by satbanda for Received Qty Validation <Start>
                               ,  CASE
                                    WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' AND '''
            || lv_run_flag
            || '''<> ''NORUN'' THEN
                                         (SELECT  NVL(SUM(po_received_qty),0)
                                            FROM RC_INV_4B2_LRO_FVE_QUANTITY a
--                                           WHERE (po_number LIKE ''CSC%'' OR po_number LIKE ''TRF%'') -->> Commented to consider more POs on 29-OCT-2018 by sridvasu
                                           WHERE REGEXP_LIKE (PO_NUMBER, ''^(TR|CSC7|907|904|900|700|909|C20|C10|CSY|CSX|CSR|CSP|CSQ)'') -->> Added to consider more POs on 29-OCT-2018 by sridvasu -->> Added POs CSY , CSX , CSR , CSP and CSQ on 12-APR-2019 by sridvasu
                                             AND TRUNC(LN_CREATION_DATE) BETWEEN TRUNC (SYSDATE-5) AND TRUNC (SYSDATE-1)
                                             AND TRUNC(CREATE_DATE)=TRUNC(SYSDATE)
                                             AND UPPER(MESSAGE_ID) LIKE ''FVE%''
                                             AND END_USER_PRODUCT_ID=  PM.TAN_ID
                                             AND STATUS_FLAG = '''
            || lv_run_flag
            || ''' )
                                    ELSE 0
                                  END RECEIVED_QTY,
                              --Added by satbanda for Received Qty Validation <End>
                              0 MASKED_QTY
                          FROM CRPADM.RC_PRODUCT_MASTER PM
                               LEFT OUTER JOIN
                               (SELECT REGEXP_SUBSTR (''YES,NO'', ''[^,]+'',1, LEVEL) ROHS_COMPLIANT
                                FROM DUAL
                                CONNECT BY REGEXP_SUBSTR (''YES,NO'', ''[^,]+'',1, LEVEL)  IS NOT NULL) Rohs
                                on (pm.REFRESH_PART_NUMBER = pm.REFRESH_PART_NUMBER )
                               LEFT OUTER JOIN
                               --INNER JOIN
                               (  SELECT part_number part,Inventory_flow,site_code,rohs_compliant, SUM (NVL(available_fgi,0)) available_fgi,
                                         SUM (NVL(reserved_fgi,0)) reserved_fgi,
                                         SUM (NVL(available_to_reserve_fgi,0)) available_to_reserve_fgi
                                    FROM xxcpo_rmk_inventory_master
                                   WHERE Inventory_flow = ''Excess''
                                     --AND NVL(available_fgi,0)<>0
                                     AND site_code = '''
            || lv_site_loc
            || '''
                                GROUP BY part_number,Inventory_flow,site_code,rohs_compliant) im
                                  ON (pm.REFRESH_PART_NUMBER = im.part AND im.ROHS_COMPLIANT=rohs.ROHS_COMPLIANT)
                               LEFT OUTER JOIN
                               (  SELECT REFRESH_PART_NUMBER,
--                                         PRODUCT_ID, -->> Commented as part of US293797 modified the code to look sum of qty of TAN and PID on 17-APR-2019 by sridvasu
                                         SUM (AVAILABLE_QTY + Allocated_Qty + Picked_Qty)
                                            FB02_Total_Available_Qty,
                                         CASE WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' THEN '''
            || v_yes_flag
            || '''
                                             ELSE DECODE(ROHS_FLAG,''NON-ROHS'','''
            || v_no_flag
            || ''','''
            || v_yes_flag
            || ''')
                                             END ROHS_COMPLIANT
                                    FROM crpsc.'
            || lv_fb02_stg_table
            || '
                                   WHERE  1=1   ';

         IF lv_site_loc = v_FVE
         THEN
            lv_excess_query :=
                  lv_excess_query
               || ' --AND (po_number LIKE ''CSC%'' OR po_number LIKE ''TRF%'')  -->> Commented to consider more POs on 29-OCT-2018 by sridvasu
                                                                     AND REGEXP_LIKE (PO_NUMBER, ''^(TR|CSC7|907|904|900|909|700|C20|C10|CSY|CSX|CSR|CSP|CSQ|914)'') -->> Added to consider more POs on 29-OCT-2018 by sridvasu -->> Added POs CSY , CSX , CSR , CSP and CSQ on 12-APR-2019 by sridvasu
                                                                     AND TRUNC (line_creation_date) =
                                                                            (SELECT TRUNC (MAX (line_creation_date))
                                                                               FROM crpsc.'
               || lv_fb02_stg_table
               || ' )';
         ELSIF lv_site_loc = v_LRO
         THEN
            lv_excess_query :=
                  lv_excess_query
               || '
                                             AND UPPER(ROHS_FLAG)  NOT LIKE ''OTH%'' ';
            lv_excess_query :=
                  lv_excess_query
               || ' AND TRUNC(INV_CREATION_DATE) = TRUNC(SYSDATE) '; --added by hkarka on 20-MAR-2018
         END IF;

         lv_excess_query :=
               lv_excess_query
            || '
--                        GROUP BY REFRESH_PART_NUMBER, PRODUCT_ID,ROHS_FLAG) fb02 -->> Commented as part of US293797 modified the code to look sum of qty of TAN and PID on 17-APR-2019 by sridvasu
                        GROUP BY REFRESH_PART_NUMBER,ROHS_FLAG) fb02 -->> Added as part of US293797 modified the code to look sum of qty of TAN and PID on 17-APR-2019 by sridvasu
                          ON (pm.refresh_part_number = fb02.refresh_part_number AND fb02.ROHS_COMPLIANT=rohs.ROHS_COMPLIANT)
                       LEFT OUTER JOIN
                           (SELECT PRODUCT_ID,
                                   CD.ROHS_COMPLIANT ROHS_COMPLIANT,
                                   CASE WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' THEN
                                   (CASE
                                      WHEN (NVL (CD.CDC_AWAITING_SHIPMENT, 0) - NVL (CSQ_QTY, 0)) > 0
                                      THEN
                                         NVL (CD.CDC_AWAITING_SHIPMENT, 0) - NVL (CSQ_QTY, 0)
                                      ELSE
                                         0
                                   END)
                                   ELSE
                                    CD.CDC_AWAITING_SHIPMENT
                                   END
                                      AS CDC_AWAITING_SHIPMENT,
                                   CD.CDC_AWAITING_SHIPMENT AS CDC_AWAITING_SHIPMENT_OLD
                              FROM (SELECT PRODUCT_ID,ROHS_COMPLIANT,SUM (ORDERED_QUANTITY) CDC_AWAITING_SHIPMENT
                                    FROM (SELECT R3R.PRODUCT_ID,
                                    CASE WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' THEN '''
            || v_yes_flag
            || '''
                                    WHEN (SELECT count(*)
                                    FROM RMK_SSOT_TRANSACTIONS RST
                                    WHERE     SALES_ORDER_NUMBER = TO_CHAR (R3R.ORDER_NUMBER)
                                              AND PRODUCT_ID = R3R.PRODUCT_ID
                                              AND SALES_ORDER_LINE_NUMBER = R3R.line_number )>0
                                              THEN
                                               (SELECT ROHS_COMPLIANT
                                               FROM RMK_SSOT_TRANSACTIONS RST
                                               WHERE     SALES_ORDER_NUMBER = TO_CHAR (R3R.ORDER_NUMBER)
                                                         AND PRODUCT_ID = R3R.PRODUCT_ID
                                                         AND SALES_ORDER_LINE_NUMBER = R3R.line_number
                                                         AND ROWNUM < 2)
                                              ELSE
                                                (SELECT ROHS_COMPLIANT
                                                 FROM RMK_SSOT_TRANSACTIONS RST
                                                 WHERE     SALES_ORDER_NUMBER = TO_CHAR (R3R.ORDER_NUMBER)
                                                           AND PRODUCT_ID = R3R.PRODUCT_ID
                                                           AND ROWNUM < 2)
                                              END ROHS_COMPLIANT,
                                              R3R.ORDERED_QUANTITY
                                              FROM RC_SSOT_3A4_BACKLOG R3R
                                              WHERE     1 = 1
                                                        AND R3R.PRODUCTION_RESULT_CODE = ''AWAITING_SHIPPING''
                                                        AND ORDER_HOLDS IS NULL --Added for US153769
                                                        AND OTM_SHIPPING_ROUTE_CODE LIKE ''CDC%''
                                                        AND R3R.ORGANIZATION_CODE = '''
            || lv_site_loc
            || ''')
                                              GROUP BY PRODUCT_ID,ROHS_COMPLIANT) CD
                                   LEFT OUTER JOIN
                                   (SELECT REFRESH_PART_NUMBER,
                                           CASE
                                              WHEN '''
            || lv_site_loc
            || ''' = '''
            || v_FVE
            || '''
                                              THEN
                                                     '''
            || v_yes_flag
            || '''
                                           ELSE
                                              DECODE (ROHS_FLAG, ''NON-ROHS'','''
            || v_no_flag
            || ''','''
            || v_yes_flag
            || ''')
                                           END ROHS_COMPLIANT,
                                           SUM (AVAILABLE_QTY + Allocated_Qty + Picked_Qty) CSQ_QTY
                                        FROM crpsc.'
            || lv_fb02_stg_table
            || '
                                        WHERE  1=1
                                        AND REGEXP_LIKE (PO_NUMBER, ''^(CSQ)'')
                                        AND TRUNC (line_creation_date) =
                                            (SELECT TRUNC (MAX (line_creation_date))
                                              FROM crpsc.'
            || lv_fb02_stg_table
            || ' )
                                        GROUP BY REFRESH_PART_NUMBER,ROHS_FLAG) CS
                                      ON    ( CD.PRODUCT_ID = CS.REFRESH_PART_NUMBER
                                         AND CD.ROHS_COMPLIANT = CS.ROHS_COMPLIANT )) CDC
                            ON (pm.REFRESH_PART_NUMBER = cdc.PRODUCT_ID AND cdc.ROHS_COMPLIANT=rohs.ROHS_COMPLIANT)
                            LEFT OUTER JOIN
                               (SELECT PRODUCT_ID,ROHS_COMPLIANT,SUM (ORDERED_QUANTITY) CC_AWAITING_SHIPMENT
                                FROM (SELECT R3R.PRODUCT_ID,
                                         CASE WHEN '''
            || lv_site_loc
            || '''='''
            || v_FVE
            || ''' THEN '''
            || v_yes_flag
            || '''
                                         WHEN (SELECT count(*)
                                                FROM RMK_SSOT_TRANSACTIONS RST
                                               WHERE     SALES_ORDER_NUMBER = TO_CHAR (R3R.ORDER_NUMBER)
                                                     AND PRODUCT_ID = R3R.PRODUCT_ID
                                                     AND SALES_ORDER_LINE_NUMBER = R3R.line_number )>0
                                          THEN
                                             (SELECT ROHS_COMPLIANT
                                                FROM RMK_SSOT_TRANSACTIONS RST
                                               WHERE     SALES_ORDER_NUMBER = TO_CHAR (R3R.ORDER_NUMBER)
                                                     AND PRODUCT_ID = R3R.PRODUCT_ID
                                                     AND SALES_ORDER_LINE_NUMBER = R3R.line_number
                                                     AND ROWNUM < 2)
                                          ELSE
                                             (SELECT ROHS_COMPLIANT
                                                FROM RMK_SSOT_TRANSACTIONS RST
                                               WHERE     SALES_ORDER_NUMBER = TO_CHAR (R3R.ORDER_NUMBER)
                                                     AND PRODUCT_ID = R3R.PRODUCT_ID
                                                     AND ROWNUM < 2)
                                                END ROHS_COMPLIANT,
                                         R3R.ORDERED_QUANTITY
                                    FROM RC_SSOT_3A4_BACKLOG R3R
                                   WHERE     1 = 1
                                         AND R3R.PRODUCTION_RESULT_CODE = ''AWAITING_SHIPPING''
                                         AND OTM_SHIPPING_ROUTE_CODE LIKE ''CC%''
                                         AND R3R.ORGANIZATION_CODE = '''
            || lv_site_loc
            || ''')
                                GROUP BY PRODUCT_ID,ROHS_COMPLIANT) CC
                                ON (pm.REFRESH_PART_NUMBER = cc.PRODUCT_ID AND cc.ROHS_COMPLIANT=rohs.ROHS_COMPLIANT)
                              WHERE     1 = 1
                               AND pm.PROGRAM_TYPE = 1
                               AND pm.TAN_ID IS NOT NULL';

         lv_excess_query := lv_excess_query || '
                               ) WHERE TOTAL_ADJUSTMENT<>0 ';


         lv_query := lv_query || ' UNION
                             ' || lv_excess_query;

         /*INSERT INTO temp
              VALUES (lv_query);*/

         lv_count_query := '  SELECT COUNT (*)
                                            FROM (' || lv_query || ')';

         lv_query :=
               'SELECT REFRESH_PART_NUMBER,
                                                      PROGRAM_TYPE,
                                                      TAN_ID, --Added for US153769
                                                      SITE_CODE,
                                                      ROHS_COMPLIANT,
                                                      CDC_AWAITING_SHIPMENT,
                                                      CDC_AWAITING_SHIPMENT_OLD,
                                                      CC_AWAITING_SHIPMENT,
                                                      FB02_ON_HAND_QTY,
                                                      TOTAL_FB02_CDC_CC_QTY,
                                                      CCW_E_RESERVE_QTY,
                                                      CCW_E_AVAIL_TO_RES_QTY,
                                                      CCW_E_AVAILABLE_QTY,
                                                      CCW_R_RESERVE_QTY,
                                                      CCW_R_AVAIL_TO_RES_QTY,
                                                      CCW_R_AVAILABLE_QTY,
                                                      CCW_O_RESERVE_QTY,
                                                      CCW_O_AVAIL_TO_RES_QTY,
                                                      CCW_O_AVAILABLE_QTY,
                                                      CCW_TOTAL_QTY,
                                                      TOTAL_ADJUSTMENT,
                                                      TOTAL_ADJUSTMENT_OLD,
                                                        --Added by satbanda for Received Qty Validation <Start>
                                                      CASE WHEN '''
            || lv_site_loc
            || '''='''
            || v_LRO
            || '''  THEN
                                                      ''Y''
                                                      WHEN  (TOTAL_ADJUSTMENT <0 AND ABS(TOTAL_ADJUSTMENT)<=RECEIVED_QTY) OR ENABLE_FLAG= ''N'' THEN ''N''
                                                      ELSE ''Y''
                                                      END ENABLE_FLAG,
                                                       --Added by satbanda for Received Qty Validation <End>
                                                      RECEIVED_QTY, --Added by satbanda for Received Qty Validation
                                                      STRATEGIC_MASKED_QTY,
                                                      ROWNUM  rnum FROM ('
            || lv_query
            || ')';

         /* Start Commented and added new variable for length issue on 13-Nov-2018 by sridvasu*/

         --           lv_query :=
         lv_query1 :=
               'SELECT RC_INV_RECON_ADJ_OBJECT
                                                     (REFRESH_PART_NUMBER,
                                                      PROGRAM_TYPE,
                                                      SITE_CODE,
                                                      ROHS_COMPLIANT,
                                                      CDC_AWAITING_SHIPMENT_OLD,
                                                      CC_AWAITING_SHIPMENT,
                                                      FB02_ON_HAND_QTY,
                                                      TOTAL_FB02_CDC_CC_QTY,
                                                      CCW_E_RESERVE_QTY,
                                                      CCW_E_AVAIL_TO_RES_QTY,
                                                      CCW_E_AVAILABLE_QTY,
                                                      CCW_R_RESERVE_QTY,
                                                      CCW_R_AVAIL_TO_RES_QTY,
                                                      CCW_R_AVAILABLE_QTY,
                                                      CCW_O_RESERVE_QTY,
                                                      CCW_O_AVAIL_TO_RES_QTY,
                                                      CCW_O_AVAILABLE_QTY,
                                                      CCW_TOTAL_QTY,
                                                      TOTAL_ADJUSTMENT_OLD,
                                                      TOTAL_ADJUSTMENT, --TOTAL_ADJUSTMENT_NEW
                                                      CDC_AWAITING_SHIPMENT, --CDC_AWAITING_SHIPMENT_NEW
                                                      CC_AWAITING_SHIPMENT, --CC_AWAITING_SHIPMENT_NEW
                                                      NULL,NULL,TAN_ID,NULL,NULL,NULL,NULL,RECEIVED_QTY,
                                                      NULL,NULL,NULL,NULL,NULL,
                                                      NULL,'''
            || lv_reconui_batch_id
            || ''',ENABLE_FLAG,
                                                      ENABLE_FLAG,NULL,STRATEGIC_MASKED_QTY)
                          FROM (';                             -- || lv_query ;

         /* End Commented and added new variable for length issue on 13-Nov-2018 by sridvasu*/

         lv_stg_query :=
               lv_query
            || ' ORDER BY REFRESH_PART_NUMBER,PROGRAM_TYPE DESC ,ROHS_COMPLIANT DESC)';

         /*INSERT INTO temp
              VALUES (lv_stg_query);

         INSERT INTO temp
              VALUES (lv_query);*/

         --insert into temp values('lv_max_row '||lv_max_row||' lv_min_row'||lv_min_row);
         IF lv_max_row IS NOT NULL AND lv_min_row IS NOT NULL
         THEN
            lv_query_wh :=
                  'WHERE ROWNUM <= '
               || lv_max_row
               || ' ORDER BY REFRESH_PART_NUMBER,PROGRAM_TYPE DESC ,ROHS_COMPLIANT DESC) WHERE rnum >='
               || lv_min_row;
            lv_query := lv_query || lv_query_wh;
         /*INSERT INTO temp
              VALUES (lv_query);*/
         ELSE
            lv_query := lv_query || ')';
         END IF;

         /*INSERT INTO temp
              VALUES (lv_query);*/

         -- EXECUTE IMMEDIATE lv_query BULK COLLECT INTO type_inv_recon_tab;


         EXECUTE IMMEDIATE lv_count_query INTO lv_display_count;

         --  insert into temp values(lv_query1 || lv_stg_query);

         IF lv_stg_query IS NOT NULL
         THEN
            IF lv_min_row = 1 OR lv_min_row IS NULL
            THEN
               /*INSERT INTO temp
                    VALUES (lv_query1 || lv_stg_query);*/

               --                 EXECUTE IMMEDIATE lv_stg_query BULK COLLECT INTO type_inv_recon_tab1; -- commented on 13-Nov-2018 by sridvasu
               EXECUTE IMMEDIATE lv_query1 || lv_stg_query
                  BULK COLLECT INTO type_inv_recon_tab1; --  added new variable because of length issue on 13-Nov-2018 by sridvasu
            END IF;
         -- EXECUTE IMMEDIATE lv_stg_query BULK COLLECT INTO type_inv_recon_all_tab; --Commented by satbanda for dsiplaying request id in download report on 17th Oct,2017.

         END IF;

         IF type_inv_recon_tab1.EXISTS (1)
         THEN
            INSERT INTO RC_INV_ADMINUI_RECON_ADJ (request_id,
                                                  program_type,
                                                  refresh_part_number,
                                                  site_code,
                                                  rohs_compliant,
                                                  cdc_awaiting_shipment,
                                                  cc_awaiting_shipment,
                                                  fb02_on_hand_qty,
                                                  total_fb02_cdc_cc_qty,
                                                  ccw_e_reserve_qty,
                                                  ccw_e_avail_to_res_qty,
                                                  ccw_e_available_qty,
                                                  ccw_r_reserve_qty,
                                                  ccw_r_avail_to_res_qty,
                                                  ccw_r_available_qty,
                                                  ccw_o_reserve_qty,
                                                  ccw_o_avail_to_res_qty,
                                                  ccw_o_available_qty,
                                                  total_ccw_qty,
                                                  total_adjustment,
                                                  total_adjustment_new,
                                                  cdc_awaiting_shipment_new,
                                                  cc_awaiting_shipment_new,
                                                  status,
                                                  approval_flag,
                                                  user_comments,
                                                  requested_date,
                                                  requested_by,
                                                  process_status,
                                                  last_updated_by,
                                                  last_updated_date,
                                                  created_by,
                                                  created_date,
                                                  v_attr1,
                                                  v_attr2,
                                                  v_attr3,
                                                  v_attr4,
                                                  n_attr1,
                                                  n_attr2,
                                                  n_attr3,
                                                  n_attr4,
                                                  d_attr1,
                                                  d_attr2,
                                                  d_attr3,
                                                  d_attr4,
                                                  recon_adj_batch_id,
                                                  allow_adj_flag,
                                                  allow_adj_flag_new,
                                                  strategic_masked_qty)
               SELECT rc_adminui_recon_seq.NEXTVAL,
                      program_type,
                      refresh_part_number,
                      site_code,
                      rohs_compliant,
                      cdc_awaiting_shipment,
                      cc_awaiting_shipment,
                      fb02_on_hand_qty,
                      total_fb02_cdc_cc_qty,
                      ccw_e_reserve_qty,
                      ccw_e_avail_to_res_qty,
                      ccw_e_available_qty,
                      ccw_r_reserve_qty,
                      ccw_r_avail_to_res_qty,
                      ccw_r_available_qty,
                      ccw_o_reserve_qty,
                      ccw_o_avail_to_res_qty,
                      ccw_o_available_qty,
                      total_ccw_qty,
                      total_adjustment,
                      total_adjustment_new,
                      cdc_awaiting_shipment_new,
                      cc_awaiting_shipment_new,
                      'DIFF',
                      v_n_flag,                                    --v_y_flag,
                      user_comments,
                      SYSDATE,            --                   REQUESTED_DATE,
                      i_user_id,                              -- REQUESTED_BY,
                      v_reconciled,                         -- PROCESS_STATUS,
                      i_user_id,                           -- LAST_UPDATED_BY,
                      SYSDATE,                           -- LAST_UPDATED_DATE,
                      i_user_id,                                -- CREATED_BY,
                      SYSDATE,                                -- CREATED_DATE,
                      v_attr1,                          --lv_reconui_batch_id,
                      v_attr2,                                        --TAN ID
                      v_attr3,                                  -- Enable flag
                      v_attr4,                              -- Enable flag New
                      n_attr1,                                --Retail Adj Qty
                      n_attr2,                                --Outlet Adj Qty
                      n_attr3,                                  --Recieved Qty
                      n_attr4,
                      d_attr1,
                      d_attr2,
                      d_attr3,
                      d_attr4,
                      recon_adj_batch_id,
                      allow_adj_flag,
                      allow_adj_flag_new,
                      strategic_masked_qty
                 FROM TABLE (
                         CAST (type_inv_recon_tab1 AS RC_INV_RECON_ADJ_TAB));

            BEGIN
               UPDATE RC_INV_RECONUI_SETUP
                  SET COMPLETION_DATE = SYSDATE,
                      STATUS = v_processed,
                      LAST_UPDATED_BY = i_user_id,
                      LAST_UPDATED_DATE = SYSDATE
                WHERE     ATTRIBUTE2 = lv_site_loc
                      AND MODULE_NAME = v_recon_job
                      AND ATTRIBUTE1 = lv_reconui_batch_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_message := SUBSTR (SQLERRM, 1, 200);

                  P_RCEC_ERROR_LOG (
                     I_module_name       => 'P_INV_LOC_RECONCILIATION',
                     I_entity_name       => NULL,
                     I_entity_id         => NULL,
                     I_ext_entity_name   => NULL,
                     I_ext_entity_id     => NULL,
                     I_error_type        => 'EXCEPTION',
                     i_Error_Message     =>    'Error getting while updating RC_INV_RECONUI_SETUP table '
                                            || ' <> '
                                            || v_message
                                            || ' LineNo=> '
                                            || DBMS_UTILITY.Format_error_backtrace,
                     I_created_by        => i_user_id,
                     I_updated_by        => i_user_id);
            END;

            BEGIN
               UPDATE RC_INV_RECONUI_SETUP rirs
                  SET STATUS = v_ignored,
                      LAST_UPDATED_BY = i_user_id,
                      LAST_UPDATED_DATE = SYSDATE
                WHERE     ATTRIBUTE2 = lv_site_loc
                      AND MODULE_NAME = v_recon_job
                      AND ATTRIBUTE1 != lv_reconui_batch_id
                      AND NOT EXISTS
                             (SELECT 1
                                FROM RC_INV_RECONUI_SETUP
                               WHERE     MODULE_NAME = v_adjmnt_job
                                     AND rirs.executable_id = executable_id)
                      AND STATUS = v_processed;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_message := SUBSTR (SQLERRM, 1, 200);

                  P_RCEC_ERROR_LOG (
                     I_module_name       => 'P_INV_LOC_RECONCILIATION',
                     I_entity_name       => NULL,
                     I_entity_id         => NULL,
                     I_ext_entity_name   => NULL,
                     I_ext_entity_id     => NULL,
                     I_error_type        => 'EXCEPTION',
                     i_Error_Message     =>    'Error getting while updating RC_INV_RECONUI_SETUP table '
                                            || ' <> '
                                            || v_message
                                            || ' LineNo=> '
                                            || DBMS_UTILITY.Format_error_backtrace,
                     I_created_by        => i_user_id,
                     I_updated_by        => i_user_id);
            END;

            BEGIN
               UPDATE RC_INV_ADMINUI_RECON_ADJ
                  SET PROCESS_STATUS = v_ignored
                WHERE     SITE_CODE = lv_site_loc
                      AND PROCESS_STATUS = v_reconciled
                      AND RECON_ADJ_BATCH_ID != lv_reconui_batch_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_message := SUBSTR (SQLERRM, 1, 200);

                  P_RCEC_ERROR_LOG (
                     I_module_name       => 'P_INV_LOC_RECONCILIATION',
                     I_entity_name       => NULL,
                     I_entity_id         => NULL,
                     I_ext_entity_name   => NULL,
                     I_ext_entity_id     => NULL,
                     I_error_type        => 'EXCEPTION',
                     i_Error_Message     =>    'Error getting while updating RC_INV_ADMINUI_RECON_ADJ table '
                                            || ' <> '
                                            || v_message
                                            || ' LineNo=> '
                                            || DBMS_UTILITY.Format_error_backtrace,
                     I_created_by        => i_user_id,
                     I_updated_by        => i_user_id);
            END;
         END IF;

         BEGIN
            SELECT RC_INV_RECON_ADJ_OBJECT (REFRESH_PART_NUMBER,
                                            PROGRAM_TYPE,
                                            SITE_CODE,
                                            ROHS_COMPLIANT,
                                            CDC_AWAITING_SHIPMENT,
                                            CC_AWAITING_SHIPMENT,
                                            FB02_ON_HAND_QTY,
                                            TOTAL_FB02_CDC_CC_QTY,
                                            CCW_E_RESERVE_QTY,
                                            CCW_E_AVAIL_TO_RES_QTY,
                                            CCW_E_AVAILABLE_QTY,
                                            CCW_R_RESERVE_QTY,
                                            CCW_R_AVAIL_TO_RES_QTY,
                                            CCW_R_AVAILABLE_QTY,
                                            CCW_O_RESERVE_QTY,
                                            CCW_O_AVAIL_TO_RES_QTY,
                                            CCW_O_AVAILABLE_QTY,
                                            TOTAL_CCW_QTY,
                                            TOTAL_ADJUSTMENT,
                                            TOTAL_ADJUSTMENT_NEW,
                                            CDC_AWAITING_SHIPMENT_NEW,
                                            CC_AWAITING_SHIPMENT_NEW,
                                            USER_COMMENTS,
                                            NULL,
                                            V_ATTR2,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            N_ATTR3,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            REQUEST_ID,
                                            RECON_ADJ_BATCH_ID,
                                            ALLOW_ADJ_FLAG,
                                            ALLOW_ADJ_FLAG_NEW,
                                            APPROVAL_FLAG,
                                            STRATEGIC_MASKED_QTY)
              BULK COLLECT INTO type_inv_recon_tab
              FROM (SELECT *
                      FROM (SELECT REQUEST_ID,
                                   REFRESH_PART_NUMBER,
                                   PROGRAM_TYPE,
                                   SITE_CODE,
                                   ROHS_COMPLIANT,
                                   CDC_AWAITING_SHIPMENT,
                                   CC_AWAITING_SHIPMENT,
                                   FB02_ON_HAND_QTY,
                                   TOTAL_FB02_CDC_CC_QTY,
                                   CCW_E_RESERVE_QTY,
                                   CCW_E_AVAIL_TO_RES_QTY,
                                   CCW_E_AVAILABLE_QTY,
                                   CCW_R_RESERVE_QTY,
                                   CCW_R_AVAIL_TO_RES_QTY,
                                   CCW_R_AVAILABLE_QTY,
                                   CCW_O_RESERVE_QTY,
                                   CCW_O_AVAIL_TO_RES_QTY,
                                   CCW_O_AVAILABLE_QTY,
                                   TOTAL_CCW_QTY,
                                   TOTAL_ADJUSTMENT,
                                   CDC_AWAITING_SHIPMENT_NEW,
                                   CC_AWAITING_SHIPMENT_NEW,
                                   DECODE (PROCESS_STATUS,
                                           v_ignored, 0,
                                           TOTAL_ADJUSTMENT_NEW)
                                      TOTAL_ADJUSTMENT_NEW,
                                   USER_COMMENTS,
                                   RECON_ADJ_BATCH_ID,
                                   ALLOW_ADJ_FLAG,
                                   ALLOW_ADJ_FLAG_NEW,
                                   APPROVAL_FLAG,
                                   STRATEGIC_MASKED_QTY,
                                   V_ATTR2,                         --US153769
                                   N_ATTR3,               -- Recieved Quantity
                                   ROWNUM RNUM
                              FROM (  SELECT *
                                        FROM RC_INV_ADMINUI_RECON_ADJ
                                       WHERE     SITE_CODE = lv_site_loc
                                             AND RECON_ADJ_BATCH_ID =
                                                    lv_reconui_batch_id
                                             AND process_status NOT IN
                                                    (v_processed, v_ignored)
                                             AND NVL (lv_adj_job_status, '*') NOT IN
                                                    (v_processed, v_ignored)
                                    ORDER BY REQUEST_ID,
                                             REFRESH_PART_NUMBER,
                                             PROGRAM_TYPE DESC,
                                             ROHS_COMPLIANT DESC)
                             WHERE ROWNUM <= lv_max_row)
                     WHERE RNUM >= lv_min_row);
         EXCEPTION
            WHEN OTHERS
            THEN
               v_message := SUBSTR (SQLERRM, 1, 200);
               P_RCEC_ERROR_LOG (
                  I_module_name       => 'P_INV_LOC_RECONCILIATION',
                  I_entity_name       => NULL,
                  I_entity_id         => NULL,
                  I_ext_entity_name   => NULL,
                  I_ext_entity_id     => NULL,
                  I_error_type        => 'EXCEPTION',
                  i_Error_Message     =>    'Error getting while loading the data: '
                                         || ' <> '
                                         || v_message
                                         || ' LineNo=> '
                                         || DBMS_UTILITY.Format_error_backtrace,
                  I_created_by        => i_user_id,
                  I_updated_by        => i_user_id);
         END;

         --Added by satbanda on 22nd Jan,2018 for US148664 (Recon Histroy) <Start>
         IF type_inv_recon_tab.EXISTS (1)
         THEN
            type_inv_recon_tab :=
               F_GET_ADJINV_RETAIL_OUTLET (type_inv_recon_tab);
         END IF;

         --Added by satbanda on 22nd Jan,2018 for US148664 (Recon Histroy) <End>

         --Added by satbanda for dsiplaying request id in download report on 17th Oct,2017 <Start>
         BEGIN
            SELECT RC_INV_RECON_ADJ_OBJECT (REFRESH_PART_NUMBER,
                                            PROGRAM_TYPE,
                                            SITE_CODE,
                                            ROHS_COMPLIANT,
                                            CDC_AWAITING_SHIPMENT,
                                            CC_AWAITING_SHIPMENT,
                                            FB02_ON_HAND_QTY,
                                            TOTAL_FB02_CDC_CC_QTY,
                                            CCW_E_RESERVE_QTY,
                                            CCW_E_AVAIL_TO_RES_QTY,
                                            CCW_E_AVAILABLE_QTY,
                                            CCW_R_RESERVE_QTY,
                                            CCW_R_AVAIL_TO_RES_QTY,
                                            CCW_R_AVAILABLE_QTY,
                                            CCW_O_RESERVE_QTY,
                                            CCW_O_AVAIL_TO_RES_QTY,
                                            CCW_O_AVAILABLE_QTY,
                                            TOTAL_CCW_QTY,
                                            TOTAL_ADJUSTMENT,
                                            TOTAL_ADJUSTMENT_NEW,
                                            CDC_AWAITING_SHIPMENT_NEW,
                                            CC_AWAITING_SHIPMENT_NEW,
                                            USER_COMMENTS,
                                            NULL,
                                            V_ATTR2,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            N_ATTR3,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            REQUEST_ID,
                                            RECON_ADJ_BATCH_ID,
                                            ALLOW_ADJ_FLAG,
                                            ALLOW_ADJ_FLAG_NEW,
                                            APPROVAL_FLAG,
                                            STRATEGIC_MASKED_QTY)
              BULK COLLECT INTO type_inv_recon_all_tab
              FROM (SELECT *
                      FROM (SELECT REQUEST_ID,
                                   REFRESH_PART_NUMBER,
                                   PROGRAM_TYPE,
                                   SITE_CODE,
                                   ROHS_COMPLIANT,
                                   CDC_AWAITING_SHIPMENT,
                                   CC_AWAITING_SHIPMENT,
                                   FB02_ON_HAND_QTY,
                                   TOTAL_FB02_CDC_CC_QTY,
                                   CCW_E_RESERVE_QTY,
                                   CCW_E_AVAIL_TO_RES_QTY,
                                   CCW_E_AVAILABLE_QTY,
                                   CCW_R_RESERVE_QTY,
                                   CCW_R_AVAIL_TO_RES_QTY,
                                   CCW_R_AVAILABLE_QTY,
                                   CCW_O_RESERVE_QTY,
                                   CCW_O_AVAIL_TO_RES_QTY,
                                   CCW_O_AVAILABLE_QTY,
                                   TOTAL_CCW_QTY,
                                   TOTAL_ADJUSTMENT,
                                   CDC_AWAITING_SHIPMENT_NEW,
                                   CC_AWAITING_SHIPMENT_NEW,
                                   DECODE (PROCESS_STATUS,
                                           v_ignored, 0,
                                           TOTAL_ADJUSTMENT_NEW)
                                      TOTAL_ADJUSTMENT_NEW,
                                   USER_COMMENTS,
                                   RECON_ADJ_BATCH_ID,
                                   ALLOW_ADJ_FLAG,
                                   ALLOW_ADJ_FLAG_NEW,
                                   APPROVAL_FLAG,
                                   STRATEGIC_MASKED_QTY,
                                   V_ATTR2,                         --US153769
                                   N_ATTR3,               -- Recieved Quantity
                                   ROWNUM RNUM
                              FROM (  SELECT *
                                        FROM RC_INV_ADMINUI_RECON_ADJ
                                       WHERE     SITE_CODE = lv_site_loc
                                             AND RECON_ADJ_BATCH_ID =
                                                    lv_reconui_batch_id
                                             AND process_status NOT IN
                                                    (v_processed, v_ignored)
                                             AND NVL (lv_adj_job_status, '*') NOT IN
                                                    (v_processed, v_ignored)
                                    ORDER BY REQUEST_ID,
                                             REFRESH_PART_NUMBER,
                                             PROGRAM_TYPE DESC,
                                             ROHS_COMPLIANT DESC)));

            --Added by satbanda on 22nd Jan,2018 for US148664 (Recon Histroy) <Start>
            IF type_inv_recon_all_tab.EXISTS (1)
            THEN
               type_inv_recon_all_tab :=
                  F_GET_ADJINV_RETAIL_OUTLET (type_inv_recon_all_tab);
            END IF;
         --Added by satbanda on 22nd Jan,2018 for US148664 (Recon Histroy) <End>

         EXCEPTION
            WHEN OTHERS
            THEN
               v_message := SUBSTR (SQLERRM, 1, 200);
               P_RCEC_ERROR_LOG (
                  I_module_name       => 'P_INV_LOC_RECONCILIATION',
                  I_entity_name       => NULL,
                  I_entity_id         => NULL,
                  I_ext_entity_name   => NULL,
                  I_ext_entity_id     => NULL,
                  I_error_type        => 'EXCEPTION',
                  i_Error_Message     =>    'Error getting while loading the data: '
                                         || ' <> '
                                         || v_message
                                         || ' LineNo=> '
                                         || DBMS_UTILITY.Format_error_backtrace,
                  I_created_by        => i_user_id,
                  I_updated_by        => i_user_id);
         END;
      --Added by satbanda for dsiplaying request id in download report on 17th Oct,2017 <End>


      END IF;


     <<Display_output>>
      IF lv_reconui_batch_id IS NOT NULL
      THEN
         BEGIN
            SELECT    'Reconciliation for '
                   || lv_site_loc
                   || ' was last run at '
                   || TO_CHAR (
                         TO_DATE (
                            '' || SUBSTR (lv_reconui_batch_id, 14) || '',
                            'MMDDYYYYHH24MISS'),
                         'HH:Mi AM "PST on "Day Ddth Mon, YYYY')
                   || lv_received_qtymsg
              INTO lv_last_loc_run
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_message := SUBSTR (SQLERRM, 1, 200);
               P_RCEC_ERROR_LOG (
                  I_module_name       => 'P_INV_LOC_RECONCILIATION',
                  I_entity_name       => NULL,
                  I_entity_id         => NULL,
                  I_ext_entity_name   => NULL,
                  I_ext_entity_id     => NULL,
                  I_error_type        => 'EXCEPTION',
                  i_Error_Message     =>    'Error getting while executing Last run time '
                                         || ' <> '
                                         || v_message
                                         || ' LineNo=> '
                                         || DBMS_UTILITY.Format_error_backtrace,
                  I_created_by        => i_user_id,
                  I_updated_by        => i_user_id);
         END;
      END IF;


      o_inv_recon_tab := type_inv_recon_tab;

      o_inv_recon_all_tab := type_inv_recon_all_tab;

      o_display_count := lv_display_count;

      o_process_check_msg := lv_process_check_tab;

      o_last_loc_run := lv_last_loc_run;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := SUBSTR (SQLERRM, 1, 200);

         P_RCEC_ERROR_LOG (
            I_module_name       => 'P_INV_LOC_RECONCILIATION',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while executing P_INV_LOC_RECONCILIATION '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => i_user_id,
            I_updated_by        => i_user_id);

         v_message := 'Error getting due to technical issues: ' || v_message;

         lv_process_check_tab.EXTEND;
         lv_process_check_tab (1) :=
            RC_INV_MESSAGE_OBJ ('RECONUI',
                                NULL,
                                NULL,
                                NULL,
                                'ERROR',
                                v_message);
   END P_INV_LOC_RECONCILIATION;

   PROCEDURE P_INV_RECON_ADJ_PROCESS (
      i_inv_recon_tab       IN            RC_INV_RECON_ADJ_TAB,
      i_user_id             IN            VARCHAR2,
      o_status                 OUT NOCOPY VARCHAR2,
      o_process_check_msg      OUT NOCOPY RC_INV_MESSAGE_TAB)
   AS
      lv_adj_qty_r           NUMBER;
      lv_adj_qty_o           NUMBER;
      lv_adj_qty             NUMBER;
      lv_adj_qty_smq         NUMBER;
      lv_inv_Log_seq         NUMBER;
      lv_inv_recon_seq       NUMBER;
      lv_rec_batch_id        VARCHAR2 (300);
      lv_status              VARCHAR2 (20);
      lv_recon_status        VARCHAR2 (20);
      lv_messages            VARCHAR2 (2000);
      lv_last_reconcil       VARCHAR2 (300);
      lv_request_id          NUMBER;
      lv_batch_proc_id       VARCHAR2 (300);
      lv_site_loc            VARCHAR2 (10);
      lv_restrict_min        NUMBER;
      lv_report_older_time   NUMBER;
      lv_last_processed      VARCHAR2 (300);
      lv_process_check_tab   RC_INV_MESSAGE_TAB := RC_INV_MESSAGE_TAB ();
      type_inv_recon_tab     RC_INV_RECON_ADJ_TAB := RC_INV_RECON_ADJ_TAB ();
   BEGIN
      IF i_inv_recon_tab.EXISTS (1)
      THEN
         type_inv_recon_tab := i_inv_recon_tab;

         FOR rec_upd IN type_inv_recon_tab.FIRST .. type_inv_recon_tab.LAST
         LOOP
            BEGIN
               UPDATE RC_INV_ADMINUI_RECON_ADJ
                  SET approval_flag = v_y_flag,
                      cdc_awaiting_shipment_new =
                         type_inv_recon_tab (rec_upd).cdc_awaiting_shipment_new,
                      cc_awaiting_shipment_new =
                         type_inv_recon_tab (rec_upd).cc_awaiting_shipment_new,
                      total_adjustment_new =
                         type_inv_recon_tab (rec_upd).total_adjustment_new,
                      allow_adj_flag_new =
                         type_inv_recon_tab (rec_upd).allow_adj_flag_new, -- Adustment allow flag Y or N
                      user_comments =
                         type_inv_recon_tab (rec_upd).user_comments,
                      total_fb02_cdc_cc_qty =
                         type_inv_recon_tab (rec_upd).total_fb02_cdc_cc_qty,
                      last_updated_date = SYSDATE,
                      last_updated_by = i_user_id
                WHERE     recon_adj_batch_id =
                             type_inv_recon_tab (rec_upd).recon_adj_batch_id --Recon Batch Id
                      AND request_id =
                             type_inv_recon_tab (rec_upd).request_id; -- Request Id
            EXCEPTION
               WHEN OTHERS
               THEN
                  lv_messages :=
                        SUBSTR (SQLERRM, 1, 200)
                     || ' for request id: '
                     || type_inv_recon_tab (rec_upd).request_id;    --v_attr2;

                  P_RCEC_ERROR_LOG (
                     i_module_name       => 'P_INV_RECON_ADJ_PROCESS',
                     i_entity_name       => NULL,
                     i_entity_id         => NULL,
                     i_ext_entity_name   => NULL,
                     i_ext_entity_id     => NULL,
                     i_error_type        => 'EXCEPTION',
                     i_Error_Message     =>    'Error getting while inserting Adjustment Process batch in RC_INV_RECONUI_SETUP '
                                            || ' <> '
                                            || lv_messages
                                            || ' LineNo=> '
                                            || DBMS_UTILITY.Format_error_backtrace,
                     I_created_by        => i_user_id,
                     I_updated_by        => i_user_id);
            END;
         END LOOP;
      END IF;

      /* v_message:= 'Process Adjustments are disabled for the first few weeks, please follow the manual process';

        lv_process_check_tab.EXTEND;
          lv_process_check_tab (1) :=
             RC_INV_MESSAGE_OBJ ('RECONUI',
                              NULL,
                              NULL,
                              NULL,
                              'ERROR',
                              v_message);

       lv_status := 'ERROR';

      IF v_message IS NOT NULL
      THEN

        GOTO Process_Stop;

      END IF;*/

      BEGIN
         SELECT UDC_1
           INTO lv_restrict_min
           FROM crpexcess.RCEC_EXCESS_CONFIG
          WHERE config_id = 10 AND CONFIG_TYPE = v_restrict_conf_type;
      EXCEPTION
         WHEN OTHERS
         THEN
            lv_restrict_min := 120;                --60; Modified for US153769
      END;

      IF i_inv_recon_tab.EXISTS (1)
      THEN
         lv_batch_proc_id := i_inv_recon_tab (1).RECON_ADJ_BATCH_ID;

         lv_site_loc := i_inv_recon_tab (1).site_code;


         BEGIN
            SELECT ATTRIBUTE1
              INTO lv_last_processed
              FROM RC_INV_RECONUI_SETUP
             WHERE     START_DATE =
                          (SELECT MAX (START_DATE)
                             FROM RC_INV_RECONUI_SETUP
                            WHERE     ATTRIBUTE2 = lv_site_loc
                                  AND MODULE_NAME = v_adjmnt_job)
                   AND MODULE_NAME = v_adjmnt_job
                   AND ATTRIBUTE2 = lv_site_loc;
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_last_processed := NULL;
         END;


         --        IF (TRUNC(to_date (''||SUBSTR(lv_last_processed,14)||'','MMDDYYYYHH24MISS')+7)> TRUNC(SYSDATE)) AND -->> Commented on 12-APR-2019 changing Recon restriction from 7 days to 2 days
         IF     (TRUNC (
                      TO_DATE ('' || SUBSTR (lv_last_processed, 14) || '',
                               'MMDDYYYYHH24MISS')
                    + 2) > TRUNC (SYSDATE))
            AND -->> Added on 12-APR-2019 changing Recon restriction from 7 days to 2 days by sridvasu
               lv_last_processed IS NOT NULL
         THEN
            v_message :=
                  'Process Adjustment for '
               || lv_site_loc
               || ' was last run in this week at '
               || TO_CHAR (
                     TO_DATE ('' || SUBSTR (lv_last_processed, 14) || '',
                              'MMDDYYYYHH24MISS'),
                     'HH:Mi AM "PST on "Day Ddth Mon, YYYY,')
               || ' system will not allow user to process it again';

            lv_process_check_tab.EXTEND;
            lv_process_check_tab (1) :=
               RC_INV_MESSAGE_OBJ ('RECONUI',
                                   NULL,
                                   NULL,
                                   NULL,
                                   'ERROR',
                                   v_message);
            lv_status := 'ERROR';

            GOTO Process_Stop;
         END IF;

         lv_report_older_time :=
              (  SYSDATE
               - TO_DATE ('' || SUBSTR (lv_batch_proc_id, 14) || '',
                          'MMDDYYYYHH24MISS'))
            * 24
            * 60;


         IF lv_report_older_time > lv_restrict_min
         THEN
            v_message :=
                  'Reconciliation for '
               || lv_site_loc
               || ' was last run at '
               || TO_CHAR (
                     TO_DATE ('' || SUBSTR (lv_batch_proc_id, 14) || '',
                              'MMDDYYYYHH24MISS'),
                     'HH:Mi AM "PST on "Day Ddth Mon, YYYY.')
               || ' System will not allow user to Process Adjustment if the reconciliation report is older than '
               || lv_restrict_min
               || ' minutes. Please rerun reconciliation';


            lv_process_check_tab.EXTEND;
            lv_process_check_tab (1) :=
               RC_INV_MESSAGE_OBJ ('RECONUI',
                                   NULL,
                                   NULL,
                                   NULL,
                                   'ERROR',
                                   v_message);
            lv_status := 'ERROR';

            GOTO Process_Stop;
         END IF;


         BEGIN
            INSERT INTO RC_INV_RECONUI_SETUP (EXECUTABLE_ID,
                                              MODULE_NAME,
                                              ATTRIBUTE1,
                                              ATTRIBUTE2,
                                              START_DATE,
                                              ACTIVE_FLAG,
                                              STATUS,
                                              CREATED_BY,
                                              CREATED_DATE)
               SELECT executable_id,
                      v_adjmnt_job,
                      attribute1,
                      attribute2,
                      SYSDATE,
                      v_y_flag,
                      v_running_sts,
                      i_user_id,
                      SYSDATE
                 FROM RC_INV_RECONUI_SETUP
                WHERE     ATTRIBUTE1 = lv_batch_proc_id
                      AND STATUS = v_processed
                      AND ATTRIBUTE2 = lv_site_loc;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_message := SUBSTR (SQLERRM, 1, 200);

               P_RCEC_ERROR_LOG (
                  i_module_name       => 'P_INV_RECON_ADJ_PROCESS',
                  i_entity_name       => NULL,
                  i_entity_id         => NULL,
                  i_ext_entity_name   => NULL,
                  i_ext_entity_id     => NULL,
                  i_error_type        => 'EXCEPTION',
                  i_Error_Message     =>    'Error getting while inserting Adjustment Process batch in RC_INV_RECONUI_SETUP '
                                         || ' <> '
                                         || v_message
                                         || ' LineNo=> '
                                         || DBMS_UTILITY.Format_error_backtrace,
                  I_created_by        => i_user_id,
                  I_updated_by        => i_user_id);
         END;

         --Commented for Adjust process disbaling until customer sign off for Reconciliation
         FOR rec_inv IN 1 .. i_inv_recon_tab.COUNT
         LOOP
            lv_request_id := i_inv_recon_tab (rec_inv).request_id;  --v_attr2;

            lv_rec_batch_id := 'RECONUI_' || lv_request_id;

            /* BEGIN
                SELECT request_id,'RECONUI_'||request_id
                 INTO lv_request_id,lv_rec_batch_id
                 FROM RC_INV_ADMINUI_RECON_ADJ
                WHERE refresh_part_number = i_inv_recon_tab (rec_inv).refresh_part_number
                  AND program_type = i_inv_recon_tab (rec_inv).program_type
                  AND site_code = i_inv_recon_tab (rec_inv).site_code
                  AND rohs_compliant = i_inv_recon_tab (rec_inv).rohs_compliant
                  AND RECON_ADJ_BATCH_ID = i_inv_recon_tab (rec_inv).RECON_ADJ_BATCH_ID;
            EXCEPTION
             WHEN OTHERS
             THEN
                v_message:='Data does not exists for refresh_part_number: '||i_inv_recon_tab (rec_inv).refresh_part_number||
                ' for program type: '||i_inv_recon_tab (rec_inv).program_type||' location:'||i_inv_recon_tab (rec_inv).site_code||
                ' rohs_compliant: '||i_inv_recon_tab (rec_inv).rohs_compliant||' batch id: '||i_inv_recon_tab (rec_inv).RECON_ADJ_BATCH_ID
                ;

                lv_process_check_tab.EXTEND;
               lv_process_check_tab (1) :=
                  RC_INV_MESSAGE_OBJ ('RECONUI',
                                   NULL,
                                   NULL,
                                   NULL,
                                   'ERROR',
                                   v_message);
            lv_status := 'ERROR';

                EXIT;
            END; */


            IF     UPPER (i_inv_recon_tab (rec_inv).program_type) = v_Excess
               AND i_inv_recon_tab (rec_inv).total_adjustment_new <> 0
            THEN
               SELECT RC_INV_LOG_PK_SEQ.NEXTVAL INTO lv_inv_Log_seq FROM DUAL;

               INSERT INTO RMK_INVENTORY_LOG (INVENTORY_LOG_ID,
                                              PART_NUMBER,
                                              NEW_FGI,
                                              NEW_DGI,
                                              ROHS_COMPLIANT,
                                              SITE_CODE,
                                              PROCESS_STATUS,
                                              UPDATED_BY,
                                              UPDATED_ON,
                                              CREATED_BY,
                                              CREATED_ON,
                                              POE_BATCH_ID,
                                              PROGRAM_TYPE)
                    VALUES (lv_inv_Log_seq,
                            i_inv_recon_tab (rec_inv).refresh_part_number,
                            i_inv_recon_tab (rec_inv).total_adjustment_new,
                            0,
                            i_inv_recon_tab (rec_inv).rohs_compliant,
                            i_inv_recon_tab (rec_inv).site_code,
                            'N',
                            i_user_id,
                            SYSDATE,
                            i_user_id,
                            SYSDATE,
                            lv_rec_batch_id,                --lv_poe_batch_id,
                            'E');
            ELSIF     UPPER (i_inv_recon_tab (rec_inv).PROGRAM_TYPE) !=
                         v_Excess
                  AND i_inv_recon_tab (rec_inv).total_adjustment_new <> 0
            THEN
               lv_adj_qty_r := 0;
               lv_adj_qty_o := 0;
               lv_adj_qty := 0;
               lv_adj_qty_smq := 0;

               IF    i_inv_recon_tab (rec_inv).total_adjustment_new > 0
                  OR i_inv_recon_tab (rec_inv).ccw_o_available_qty <= 0
               THEN
                  IF i_inv_recon_tab (rec_inv).total_adjustment_new < 0
                  THEN
                     IF i_inv_recon_tab (rec_inv).CCW_R_AVAILABLE_QTY > 0
                     THEN
                        IF i_inv_recon_tab (rec_inv).ccw_r_avail_to_res_qty >=
                              ABS (
                                 i_inv_recon_tab (rec_inv).total_adjustment_new)
                        THEN
                           lv_adj_qty_r :=
                              i_inv_recon_tab (rec_inv).total_adjustment_new;
                        ELSE
                           lv_adj_qty_r :=
                              -i_inv_recon_tab (rec_inv).ccw_r_avail_to_res_qty;
                           lv_adj_qty :=
                                ABS (
                                   i_inv_recon_tab (rec_inv).total_adjustment_new)
                              - i_inv_recon_tab (rec_inv).ccw_r_avail_to_res_qty;

                           IF i_inv_recon_tab (rec_inv).STRATEGIC_MASKED_QTY >=
                                 lv_adj_qty
                           THEN
                              lv_adj_qty_smq := lv_adj_qty_smq - lv_adj_qty;
                           ELSE
                              lv_adj_qty_smq :=
                                   lv_adj_qty_smq
                                 - i_inv_recon_tab (rec_inv).STRATEGIC_MASKED_QTY;
                              lv_adj_qty :=
                                   lv_adj_qty
                                 - i_inv_recon_tab (rec_inv).STRATEGIC_MASKED_QTY;

                              IF i_inv_recon_tab (rec_inv).ccw_r_reserve_qty >=
                                    lv_adj_qty
                              THEN
                                 lv_adj_qty_r := lv_adj_qty_r - lv_adj_qty;
                              ELSE
                                 lv_adj_qty_r :=
                                      lv_adj_qty_r
                                    - i_inv_recon_tab (rec_inv).ccw_r_reserve_qty;
                                 lv_adj_qty :=
                                      lv_adj_qty
                                    - i_inv_recon_tab (rec_inv).ccw_r_reserve_qty; --ccw_r_avail_to_res_qty; --Modified by satbanda for Negative Recon inventory Adjustment issue on 17th Oct,2017.

                                 IF ABS (lv_adj_qty) > 0
                                 THEN
                                    CONTINUE;
                                 END IF;
                              END IF;
                           END IF;
                        END IF;
                     ELSE
                        IF i_inv_recon_tab (rec_inv).STRATEGIC_MASKED_QTY >=
                              ABS (
                                 i_inv_recon_tab (rec_inv).total_adjustment_new)
                        THEN
                           lv_adj_qty_smq :=
                              i_inv_recon_tab (rec_inv).total_adjustment_new;
                        ELSE
                           lv_adj_qty_smq :=
                              -i_inv_recon_tab (rec_inv).STRATEGIC_MASKED_QTY;
                           lv_adj_qty :=
                                ABS (
                                   i_inv_recon_tab (rec_inv).total_adjustment_new)
                              - i_inv_recon_tab (rec_inv).STRATEGIC_MASKED_QTY;

                           --ccw_r_avail_to_res_qty; --Modified by satbanda for Negative Recon inventory Adjustment issue on 17th Oct,2017.

                           IF ABS (lv_adj_qty) > 0
                           THEN
                              CONTINUE;
                           END IF;
                        END IF;
                     END IF;
                  ELSE
                     lv_adj_qty_r :=
                        i_inv_recon_tab (rec_inv).total_adjustment_new;
                  END IF;
               ELSIF     i_inv_recon_tab (rec_inv).ccw_o_available_qty > 0
                     AND i_inv_recon_tab (rec_inv).total_adjustment_new < 0
               THEN
                  IF i_inv_recon_tab (rec_inv).ccw_o_avail_to_res_qty >=
                        ABS (i_inv_recon_tab (rec_inv).total_adjustment_new)
                  THEN
                     lv_adj_qty_o :=
                        i_inv_recon_tab (rec_inv).total_adjustment_new;
                  ELSE
                     lv_adj_qty_o :=
                        -i_inv_recon_tab (rec_inv).ccw_o_avail_to_res_qty;

                     lv_adj_qty :=
                          ABS (
                             i_inv_recon_tab (rec_inv).total_adjustment_new)
                        - i_inv_recon_tab (rec_inv).ccw_o_avail_to_res_qty;

                     IF i_inv_recon_tab (rec_inv).ccw_r_avail_to_res_qty >=
                           lv_adj_qty
                     THEN
                        lv_adj_qty_r := - (lv_adj_qty);
                     ELSE
                        lv_adj_qty_r :=
                           - (i_inv_recon_tab (rec_inv).ccw_r_avail_to_res_qty);
                        lv_adj_qty :=
                             lv_adj_qty
                           - i_inv_recon_tab (rec_inv).ccw_r_avail_to_res_qty;

                        IF i_inv_recon_tab (rec_inv).STRATEGIC_MASKED_QTY >=
                              lv_adj_qty
                        THEN
                           lv_adj_qty_smq := lv_adj_qty_smq - lv_adj_qty;
                        ELSE
                           lv_adj_qty_smq :=
                                lv_adj_qty_smq
                              - i_inv_recon_tab (rec_inv).STRATEGIC_MASKED_QTY;
                           lv_adj_qty :=
                                lv_adj_qty
                              - i_inv_recon_tab (rec_inv).STRATEGIC_MASKED_QTY;

                           IF i_inv_recon_tab (rec_inv).ccw_o_reserve_qty >=
                                 lv_adj_qty
                           THEN
                              lv_adj_qty_o := lv_adj_qty_o - lv_adj_qty;
                           ELSE
                              lv_adj_qty_o :=
                                   lv_adj_qty_o
                                 - i_inv_recon_tab (rec_inv).ccw_o_reserve_qty;
                              lv_adj_qty :=
                                   lv_adj_qty
                                 - i_inv_recon_tab (rec_inv).ccw_o_reserve_qty; --ccw_r_avail_to_res_qty; --Modified by satbanda for Negative Recon inventory Adjustment issue on 17th Oct,2017.

                              --                              lv_adj_qty_r := lv_adj_qty_r - lv_adj_qty;

                              IF i_inv_recon_tab (rec_inv).ccw_r_reserve_qty >=
                                    lv_adj_qty
                              THEN
                                 lv_adj_qty_r := lv_adj_qty_r - lv_adj_qty;
                              ELSE
                                 lv_adj_qty_r :=
                                      lv_adj_qty_r
                                    - i_inv_recon_tab (rec_inv).ccw_r_reserve_qty;
                                 lv_adj_qty :=
                                      lv_adj_qty
                                    - i_inv_recon_tab (rec_inv).ccw_r_reserve_qty; --ccw_r_avail_to_res_qty; --Modified by satbanda for Negative Recon inventory Adjustment issue on 17th Oct,2017.

                                 IF ABS (lv_adj_qty) > 0
                                 THEN
                                    CONTINUE;
                                 END IF;
                              END IF;
                           END IF;
                        END IF;
                     END IF;
                  END IF;
               END IF;

               IF lv_adj_qty_r <> 0
               THEN
                  SELECT RC_INV_LOG_PK_SEQ.NEXTVAL
                    INTO lv_inv_Log_seq
                    FROM DUAL;

                  INSERT INTO RMK_INVENTORY_LOG (INVENTORY_LOG_ID,
                                                 PART_NUMBER,
                                                 NEW_FGI,
                                                 NEW_DGI,
                                                 ROHS_COMPLIANT,
                                                 SITE_CODE,
                                                 PROCESS_STATUS,
                                                 UPDATED_BY,
                                                 UPDATED_ON,
                                                 CREATED_BY,
                                                 CREATED_ON,
                                                 POE_BATCH_ID,
                                                 PROGRAM_TYPE)
                       VALUES (lv_inv_Log_seq,
                               i_inv_recon_tab (rec_inv).refresh_part_number,
                               lv_adj_qty_r,
                               0,
                               i_inv_recon_tab (rec_inv).rohs_compliant,
                               i_inv_recon_tab (rec_inv).site_code,
                               'N',
                               i_user_id,
                               SYSDATE,
                               i_user_id,
                               SYSDATE,
                               lv_rec_batch_id,             --lv_poe_batch_id,
                               'R');
               END IF;

               IF lv_adj_qty_o <> 0
               THEN
                  SELECT RC_INV_LOG_PK_SEQ.NEXTVAL
                    INTO lv_inv_Log_seq
                    FROM DUAL;

                  INSERT INTO RMK_INVENTORY_LOG (INVENTORY_LOG_ID,
                                                 PART_NUMBER,
                                                 NEW_FGI,
                                                 NEW_DGI,
                                                 ROHS_COMPLIANT,
                                                 SITE_CODE,
                                                 PROCESS_STATUS,
                                                 UPDATED_BY,
                                                 UPDATED_ON,
                                                 CREATED_BY,
                                                 CREATED_ON,
                                                 POE_BATCH_ID,
                                                 PROGRAM_TYPE)
                       VALUES (lv_inv_Log_seq,
                               i_inv_recon_tab (rec_inv).refresh_part_number,
                               lv_adj_qty_o,
                               0,
                               i_inv_recon_tab (rec_inv).rohs_compliant,
                               i_inv_recon_tab (rec_inv).site_code,
                               'N',
                               i_user_id,
                               SYSDATE,
                               i_user_id,
                               SYSDATE,
                               lv_rec_batch_id,
                               'O');
               END IF;

               IF ABS (lv_adj_qty_smq) <> 0
               THEN
                  INSERT INTO RC_INV_STR_INV_MASK_STG (PARTNUMBER,
                                                       SITE,
                                                       ROHS,
                                                       MASKED_QTY,
                                                       CREATED_BY,
                                                       CREATED_AT,
                                                       PROCESSED_STATUS)
                       VALUES (i_inv_recon_tab (rec_inv).refresh_part_number,
                               i_inv_recon_tab (rec_inv).site_code,
                               i_inv_recon_tab (rec_inv).rohs_compliant,
                               ABS (lv_adj_qty_smq),
                               'RECON',
                               SYSDATE,
                               'N');
               END IF;
            END IF;

            UPDATE RC_INV_ADMINUI_RECON_ADJ
               SET PROCESS_STATUS = v_adjusted,
                   last_updated_date = SYSDATE,
                   last_updated_by = i_user_id
             WHERE REQUEST_ID = lv_request_id;
         END LOOP;

         BEGIN
            UPDATE RC_INV_RECONUI_SETUP
               SET                                  --COMPLETION_DATE=SYSDATE,
                  COMPLETION_DATE = SYSDATE,                      --INC0417145
                   STATUS = v_processed,
                   LAST_UPDATED_BY = i_user_id,
                   LAST_UPDATED_DATE = SYSDATE
             WHERE     ATTRIBUTE2 = lv_site_loc
                   AND MODULE_NAME = v_adjmnt_job
                   AND ATTRIBUTE1 = lv_batch_proc_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_message := SUBSTR (SQLERRM, 1, 200);

               P_RCEC_ERROR_LOG (
                  I_module_name       => 'P_INV_LOC_RECONCILIATION',
                  I_entity_name       => NULL,
                  I_entity_id         => NULL,
                  I_ext_entity_name   => NULL,
                  I_ext_entity_id     => NULL,
                  I_error_type        => 'EXCEPTION',
                  i_Error_Message     =>    'Error getting while updating RC_INV_RECONUI_SETUP table '
                                         || ' <> '
                                         || v_message
                                         || ' LineNo=> '
                                         || DBMS_UTILITY.Format_error_backtrace,
                  I_created_by        => i_user_id,
                  I_updated_by        => i_user_id);
         END;

         UPDATE RC_INV_ADMINUI_RECON_ADJ
            SET PROCESS_STATUS = v_ignored,
                last_updated_date = SYSDATE,
                last_updated_by = i_user_id
          WHERE PROCESS_STATUS = v_reconciled;

         COMMIT;

         lv_status := v_processed;
      END IF;


      RC_STR_INV_MASK_ADJ ('RECON', lv_recon_status);

     <<Process_Stop>>
      o_status := lv_status;

      o_process_check_msg := lv_process_check_tab;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := SUBSTR (SQLERRM, 1, 200);
         P_RCEC_ERROR_LOG (
            I_module_name       => 'P_INV_RECON_ADJ_PROCESS',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while executing P_INV_RECON_ADJ_PROCESS '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => i_user_id,
            I_updated_by        => i_user_id);

         v_message := 'Error getting due to technical issues: ' || v_message;

         lv_process_check_tab.EXTEND;
         lv_process_check_tab (1) :=
            RC_INV_MESSAGE_OBJ ('RECONUI',
                                NULL,
                                NULL,
                                NULL,
                                'ERROR',
                                v_message);
   END P_INV_RECON_ADJ_PROCESS;

   PROCEDURE P_INV_RECON_FB02_INFO (
      i_user_id            IN            VARCHAR2,
      o_refresh_lro_dt        OUT NOCOPY VARCHAR2,
      o_refresh_fve_dt        OUT NOCOPY VARCHAR2,
      o_refresh_3a4_dt        OUT NOCOPY VARCHAR2,
      o_restrict_3A4_msg      OUT NOCOPY VARCHAR2,
      o_restrict_lro_msg      OUT NOCOPY VARCHAR2,
      o_restrict_fve_msg      OUT NOCOPY VARCHAR2)
   IS
      lv_refresh_lro_dt      VARCHAR2 (50);
      lv_refresh_fve_dt      VARCHAR2 (50);
      lv_refresh_3a4_dt      VARCHAR2 (50);
      lv_restrict_3a4_msg    VARCHAR2 (300);
      lv_restrict_lro_msg    VARCHAR2 (300);
      lv_restrict_fve_msg    VARCHAR2 (300);
      lv_todate              VARCHAR2 (30);
      lv_date_3a4            DATE;                         --    VARCHAR2(30);
      lv_date_lro            DATE;                         --    VARCHAR2(30);
      lv_date_fve            DATE;                         --    VARCHAR2(30);
      v_message              VARCHAR2 (200);
      lv_chl_cron_name       VARCHAR2 (50) := 'LOAD_SSOT_3A4_BACKLOG';
      lv_success_msg         VARCHAR2 (10) := 'SUCCESS';
      lv_process_check_tab   RC_INV_MESSAGE_TAB := RC_INV_MESSAGE_TAB ();
      lv_msg_cnt             NUMBER := 0;
      lv_chl_job_count       NUMBER;
      lv_chl_job_date        DATE;
      lv_delta_err_cnt       NUMBER;
      lv_fve_s_flag          VARCHAR2 (1) := 'Y';
      lv_lro_s_flag          VARCHAR2 (1) := 'Y';
   BEGIN
      --lv_todate:= TRUNC(SYSDATE);


      BEGIN
         /* SELECT TO_CHAR(MAX (line_creation_date),'Mon DD, YYYY HH24:Mi:SS'),TRUNC(MAX (line_creation_date))
            INTO lv_refresh_3a4_dt,lv_date_3a4
            FROM rc_ssot_3a4_backlog ;*/
         SELECT TO_CHAR (MAX (chl_end_timestamp), 'Mon DD, YYYY HH24:Mi:SS'),
                MAX (chl_end_timestamp)
           INTO lv_refresh_3a4_dt, lv_date_3a4
           FROM cron_history_log
          WHERE     chl_cron_name = lv_chl_cron_name
                AND chl_status = lv_success_msg;
      EXCEPTION
         WHEN OTHERS
         THEN
            lv_date_3a4 := NULL;
      END;

      o_refresh_3a4_dt := lv_refresh_3a4_dt;

      BEGIN
         --SELECT TO_CHAR (MAX (record_created_on),'Mon DD, YYYY HH24:Mi:SS'),MAX (record_created_on)
         SELECT TO_CHAR (MAX (line_creation_date), 'Mon DD, YYYY HH24:Mi:SS'),
                MAX (line_creation_date) --added by hkarka on 15-JUL-2017 to check whether refresh done in ESMPRD
           INTO lv_refresh_lro_dt, lv_date_lro
           FROM crpsc.sc_fb02_stg_lro;
      EXCEPTION
         WHEN OTHERS
         THEN
            lv_date_lro := NULL;
            lv_restrict_lro_msg :=
               'LRO refresh data doesn''t exists,it should be run today to perform Reconciliation';
      END;

      o_refresh_lro_dt := lv_refresh_lro_dt;

      BEGIN
         --SELECT TO_CHAR (MAX (record_created_on),'Mon DD, YYYY HH24:Mi:SS'),MAX (record_created_on)
         SELECT TO_CHAR (MAX (line_creation_date), 'Mon DD, YYYY HH24:Mi:SS'),
                MAX (line_creation_date) --added by hkarka on 15-JUL-2017 to check whether refresh done in ESMPRD
           INTO lv_refresh_fve_dt, lv_date_fve
           FROM crpsc.sc_fb02_stg_fve
          --           WHERE (po_number like 'CSC%'  OR po_number like 'TRF%'); --added by hkarka on 15-JUL-2017 to consider only Refresh POs -->> Commented to consider more POs on 29-OCT-2018 by sridvasu
          WHERE REGEXP_LIKE (
                   PO_NUMBER,
                   '^(TR|CSC7|907|904|900|909|700|C20|C10|CSY|CSX|CSR|CSP|CSQ)'); -->> Added to consider more POs on 29-OCT-2018 by sridvasu -->> Added POs CSY , CSX , CSR , CSP and CSQ on 12-APR-2019 by sridvasu
      EXCEPTION
         WHEN OTHERS
         THEN
            lv_date_fve := NULL;

            --lv_restrict_lro_msg:='FVE refresh data doesn''t exists,it should be run today to perform Reconciliation';
            lv_restrict_fve_msg :=
               'FVE refresh data doesn''t exists,it should be run today to perform Reconciliation'; --changed by hkarka on 15-JUL-2017
      END;

      o_refresh_fve_dt := lv_refresh_fve_dt;

      IF lv_date_3a4 IS NULL
      THEN
         lv_restrict_3a4_msg :=
            '3A4 refresh data doesn''t exists,it should be run today to perform Reconciliation';

         lv_fve_s_flag := 'N';

         lv_lro_s_flag := 'N';
      ELSIF NVL (lv_date_3a4, SYSDATE - 2) <= SYSDATE - 1
      THEN
         lv_restrict_3a4_msg :=
               '3A4 Refresh was last run on '
            || TO_CHAR (TO_DATE (lv_date_3a4), 'MM/DD/YYYY')
            || ',it should be run to perform Reconciliation';

         lv_fve_s_flag := 'N';

         lv_lro_s_flag := 'N';
      ELSE
         IF lv_date_lro IS NULL
         THEN
            lv_restrict_lro_msg :=
               'LRO refresh data doesn''t exists, it should be run today to perform Reconciliation';

            lv_lro_s_flag := 'N';
         ELSIF NVL (lv_date_lro, SYSDATE - 2) <= SYSDATE - 1
         THEN
            --lv_restrict_lro_msg:='LRO Refresh was last run on '|| TO_CHAR(TO_DATE(lv_date_lro),'MM/DD/YYYY')|| ',it should be run to perform Reconciliation';
            lv_restrict_lro_msg :=
                  'LRO Refresh was either last run on '
               || TO_CHAR (TO_DATE (lv_date_lro), 'MM/DD/YYYY')
               || ' or refreshed with old data, it should be run today to perform Reconciliation';

            lv_lro_s_flag := 'N';
         END IF;

         IF lv_date_fve IS NULL
         THEN
            lv_restrict_fve_msg :=
               'FVE refresh data doesn''t exists,it should be run today to perform Reconciliation';

            lv_fve_s_flag := 'N';
         ELSIF NVL (lv_date_fve, SYSDATE - 2) <= SYSDATE - 1
         THEN
            --lv_restrict_fve_msg:='FVE Refresh was last run on '||TO_CHAR(TO_DATE(lv_date_fve),'MM/DD/YYYY')||',it should be run to perform Reconciliation';
            lv_restrict_fve_msg :=
                  'FVE Refresh was either last run on '
               || TO_CHAR (TO_DATE (lv_date_fve), 'MM/DD/YYYY')
               || ' or refreshed with  old data, it should be run today to perform Reconciliation';

            lv_fve_s_flag := 'N';
         END IF;
      END IF;

      IF lv_fve_s_flag = 'Y'
      THEN
         SELECT COUNT (1)
           INTO lv_chl_job_count
           FROM CRON_CONTROL_INFO
          WHERE     CRON_CONTACT_ID IN ('FVE-RF_MAIN', 'FVE-EX_MAIN')
                AND CRON_STATUS != 'SUCCESS';

         IF lv_chl_job_count = 0
         THEN
            lv_chl_job_date := NULL;

            SELECT MAX (cron_end_timestamp)
              INTO lv_chl_job_date
              FROM CRON_CONTROL_INFO
             WHERE     CRON_CONTACT_ID IN ('FVE-RF_MAIN', 'FVE-EX_MAIN')
                   AND CRON_STATUS = 'SUCCESS';

            IF NVL (lv_chl_job_date, SYSDATE - 2) <= SYSDATE - 1
            THEN
               lv_restrict_fve_msg :=
                     'FVE Cron job was last run on '
                  || TO_CHAR (TO_DATE (lv_chl_job_date), 'MM/DD/YYYY')
                  || ',it should be run to perform Reconciliation';

               lv_fve_s_flag := 'N';
            END IF;
         ELSE
            SELECT MAX (cron_end_timestamp)
              INTO lv_chl_job_date
              FROM CRON_CONTROL_INFO
             WHERE     CRON_CONTACT_ID IN ('FVE-RF_MAIN', 'FVE-EX_MAIN')
                   AND CRON_STATUS != 'SUCCESS';

            lv_restrict_fve_msg :=
                  'FVE Cron job was failed on '
               || TO_CHAR (TO_DATE (lv_chl_job_date), 'MM/DD/YYYY')
               || ',it should be run to perform Reconciliation';

            lv_fve_s_flag := 'N';
         END IF;

         IF lv_fve_s_flag = 'Y'
         THEN
            lv_delta_err_cnt := 0;

            SELECT COUNT (1)
              INTO lv_delta_err_cnt
              FROM crpsc.sc_fb02_delta_fve_hist
             WHERE     processed_status = 'E'
                   AND refresh_part_number NOT IN
                          (SELECT refresh_part_number
                             FROM rc_inv_exclude_pids);

            IF lv_delta_err_cnt != 0
            THEN
               lv_restrict_fve_msg :=
                  'Unprocessed/Errored BTS FVE FG Inventory exist, Please reprocess them to run the reconciliation.';

               lv_fve_s_flag := 'N';
            END IF;
         END IF;
      END IF;

      IF lv_lro_s_flag = 'Y'
      THEN
         SELECT COUNT (1)
           INTO lv_chl_job_count
           FROM CRON_CONTROL_INFO
          WHERE     CRON_CONTACT_ID IN ('LRO-RF_MAIN', 'LRO-EX_MAIN')
                AND CRON_STATUS != 'SUCCESS';

         IF lv_chl_job_count = 0
         THEN
            SELECT MAX (cron_end_timestamp)
              INTO lv_chl_job_date
              FROM CRON_CONTROL_INFO
             WHERE     CRON_CONTACT_ID IN ('LRO-RF_MAIN', 'LRO-EX_MAIN')
                   AND CRON_STATUS = 'SUCCESS';

            IF NVL (lv_chl_job_date, SYSDATE - 2) <= SYSDATE - 1
            THEN
               lv_restrict_lro_msg :=
                     'LRO Cron job was last run on '
                  || TO_CHAR (TO_DATE (lv_chl_job_date), 'MM/DD/YYYY')
                  || ',it should be run to perform Reconciliation';

               lv_lro_s_flag := 'N';
            END IF;
         ELSE
            SELECT MAX (cron_end_timestamp)
              INTO lv_chl_job_date
              FROM CRON_CONTROL_INFO
             WHERE     CRON_CONTACT_ID IN ('LRO-RF_MAIN', 'LRO-EX_MAIN')
                   AND CRON_STATUS != 'SUCCESS';

            lv_restrict_lro_msg :=
                  'LRO Cron job was failed on '
               || TO_CHAR (TO_DATE (lv_chl_job_date), 'MM/DD/YYYY')
               || ',it should be run to perform Reconciliation';

            lv_lro_s_flag := 'N';
         END IF;

         IF lv_lro_s_flag = 'Y'
         THEN
            lv_delta_err_cnt := 0;

            SELECT COUNT (1)
              INTO lv_delta_err_cnt
              FROM crpsc.sc_fc01_oh_delta_lro_hist
             WHERE     processed_status = 'E'
                   AND refresh_part_number NOT IN
                          (SELECT refresh_part_number
                             FROM rc_inv_exclude_pids);

            IF lv_delta_err_cnt != 0
            THEN
               lv_restrict_lro_msg :=
                  'Unprocessed/Errored BTS LRO FG Inventory exist, Please reprocess them to run the reconciliation.';

               lv_lro_s_flag := 'N';
            END IF;
         END IF;
      END IF;



      o_restrict_3A4_msg := lv_restrict_3a4_msg;

      o_restrict_lro_msg := lv_restrict_lro_msg;

      o_restrict_fve_msg := lv_restrict_fve_msg;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := SUBSTR (SQLERRM, 1, 200);

         P_RCEC_ERROR_LOG (
            I_module_name       => 'P_INV_RECON_FB02_INFO',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while executing P_INV_RECON_FB02_INFO '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => i_user_id,
            I_updated_by        => i_user_id);
   END P_INV_RECON_FB02_INFO;

   PROCEDURE P_INV_RECON_SAVE_DATA (
      i_inv_recon_tab   IN            RC_INV_RECON_ADJ_TAB,
      i_user_id         IN            VARCHAR2,
      o_status             OUT NOCOPY VARCHAR2)
   IS
      lv_messages          VARCHAR2 (2000);
      type_inv_recon_tab   RC_INV_RECON_ADJ_TAB := RC_INV_RECON_ADJ_TAB ();
      lv_status            VARCHAR2 (2000);
   BEGIN
      IF i_inv_recon_tab.EXISTS (1)
      THEN
         type_inv_recon_tab := i_inv_recon_tab;

         FOR rec_upd IN type_inv_recon_tab.FIRST .. type_inv_recon_tab.LAST
         LOOP
            BEGIN
               UPDATE RC_INV_ADMINUI_RECON_ADJ
                  SET cdc_awaiting_shipment_new =
                         type_inv_recon_tab (rec_upd).cdc_awaiting_shipment_new,
                      cc_awaiting_shipment_new =
                         type_inv_recon_tab (rec_upd).cc_awaiting_shipment_new,
                      total_adjustment_new =
                         type_inv_recon_tab (rec_upd).total_adjustment_new,
                      allow_adj_flag_new =
                         type_inv_recon_tab (rec_upd).allow_adj_flag_new, -- Adustment allow flag Y or N
                      user_comments =
                         type_inv_recon_tab (rec_upd).user_comments,
                      total_fb02_cdc_cc_qty =
                         type_inv_recon_tab (rec_upd).total_fb02_cdc_cc_qty,
                      last_updated_date = SYSDATE,
                      last_updated_by = i_user_id
                WHERE     recon_adj_batch_id =
                             type_inv_recon_tab (rec_upd).recon_adj_batch_id --Recon Batch Id
                      AND request_id =
                             type_inv_recon_tab (rec_upd).request_id; -- Request Id
            EXCEPTION
               WHEN OTHERS
               THEN
                  lv_messages :=
                        SUBSTR (SQLERRM, 1, 200)
                     || ' for request id: '
                     || type_inv_recon_tab (rec_upd).request_id;

                  EXIT;
            END;
         END LOOP;

         IF lv_messages IS NOT NULL
         THEN
            lv_status := 'Unable to processed due to :' || lv_messages;

            ROLLBACK;
         ELSE
            lv_status := 'Records are Succesfully Updated';
         END IF;
      ELSE
         lv_status := 'Records were not provided';
      END IF;

      o_status := lv_status;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := SUBSTR (SQLERRM, 1, 200);

         P_RCEC_ERROR_LOG (
            I_module_name       => 'P_INV_RECON_SAVE_DATA',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while executing P_INV_RECON_SAVE_DATA '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => i_user_id,
            I_updated_by        => i_user_id);
   END P_INV_RECON_SAVE_DATA;

   --Added by satbanda on 20th July, 2017 for US122733 (Sorting and Advanced Filter) <Start>
   PROCEDURE P_INV_LOC_RECON_VIEW (
      i_site_loc                             VARCHAR2,
      i_batch_proc_id                        VARCHAR2,
      i_user_id                              VARCHAR2,
      i_min_row                              VARCHAR2,
      i_max_row                              VARCHAR2,
      i_sort_column_name                     VARCHAR2,
      i_sort_column_by                       VARCHAR2,
      i_request_id                           VARCHAR2, --NUMBER,-Modified by satbanda for US134969
      i_program_type                         VARCHAR2, -- item type Retail+Outlet / Excess
      i_refresh_part_number                  CLOB,
      i_rohs_compliant                       VARCHAR2,
      i_total_actual_qty                     NUMBER,
      i_total_ccw_qty                        NUMBER,
      i_total_adjustment                     NUMBER,
      i_total_adjustment_new                 NUMBER,
      i_cdc_shipment_qty                     NUMBER,
      i_cdc_shipment_qty_new                 NUMBER,
      i_cc_shipment_qty                      NUMBER,
      i_cc_shipment_qty_new                  NUMBER,
      i_fb02_on_hand_qty                     NUMBER,
      i_adjustment_allow                     VARCHAR2,
      i_adjustment_allow_new                 VARCHAR2,
      o_inv_recon_tab             OUT NOCOPY RC_INV_RECON_ADJ_TAB,
      o_inv_allrecon_tab          OUT NOCOPY RC_INV_RECON_ADJ_TAB, --Added by satbanda for US134969
      o_search_count              OUT NOCOPY NUMBER,
      o_process_check_msg         OUT NOCOPY RC_INV_MESSAGE_TAB)
   IS
      lv_query                   CLOB;
      lv_cnt_query               CLOB;
      lv_common_query            CLOB;
      lv_idx                     NUMBER;
      lv_cur_part_number         CLOB;
      lv_i_refresh_part_number   CLOB;
      type_inv_recon_tab         RC_INV_RECON_ADJ_TAB
                                    := RC_INV_RECON_ADJ_TAB ();
      --Added by satbanda for US134969 <Start>
      lv_allrecon_data        CLOB;
      type_allinv_recon_tab   RC_INV_RECON_ADJ_TAB := RC_INV_RECON_ADJ_TAB ();
      --Added by satbanda for US134969 <End>
      lv_search_cnt           NUMBER;
      lv_sort_column_name     VARCHAR2 (100);
      lv_sort_column_by       VARCHAR2 (100);
      lv_min_row              NUMBER;
      lv_max_row              NUMBER;
   BEGIN
      lv_sort_column_name := UPPER (TRIM (i_sort_column_name));
      lv_sort_column_by := UPPER (TRIM (i_sort_column_by));
      lv_min_row := TO_NUMBER (i_min_row);
      lv_max_row := TO_NUMBER (i_max_row);

      lv_cnt_query :=
            '  SELECT count(*)
                            FROM RC_INV_ADMINUI_RECON_ADJ
                           WHERE SITE_CODE = '''
         || i_site_loc
         || '''
                             AND RECON_ADJ_BATCH_ID = '''
         || i_batch_proc_id
         || '''
                             ---AND process_status NOT IN ('''
         || v_processed
         || ''','''
         || v_ignored
         || ''')
                             ';


      lv_query :=
            'SELECT RC_INV_RECON_ADJ_OBJECT (REFRESH_PART_NUMBER,
                                                  PROGRAM_TYPE,
                                                  SITE_CODE,
                                                  ROHS_COMPLIANT,
                                                  CDC_AWAITING_SHIPMENT,
                                                  CC_AWAITING_SHIPMENT,
                                                  FB02_ON_HAND_QTY,
                                                  TOTAL_FB02_CDC_CC_QTY,
                                                  CCW_E_RESERVE_QTY,
                                                  CCW_E_AVAIL_TO_RES_QTY,
                                                  CCW_E_AVAILABLE_QTY,
                                                  CCW_R_RESERVE_QTY,
                                                  CCW_R_AVAIL_TO_RES_QTY,
                                                  CCW_R_AVAILABLE_QTY,
                                                  CCW_O_RESERVE_QTY,
                                                  CCW_O_AVAIL_TO_RES_QTY,
                                                  CCW_O_AVAILABLE_QTY,
                                                  TOTAL_CCW_QTY,
                                                  TOTAL_ADJUSTMENT,
                                                  TOTAL_ADJUSTMENT_NEW,
                                                  CDC_AWAITING_SHIPMENT_NEW,
                                                  CC_AWAITING_SHIPMENT_NEW,
                                                  USER_COMMENTS,
                                                  NULL,V_ATTR2,NULL,NULL,
                                                  NULL,NULL,N_ATTR3,NULL,
                                                  NULL,NULL,NULL,NULL,
                                                  REQUEST_ID,RECON_ADJ_BATCH_ID,
                                                  ALLOW_ADJ_FLAG,ALLOW_ADJ_FLAG_NEW,APPROVAL_FLAG,STRATEGIC_MASKED_QTY)
               FROM (SELECT * FROM (SELECT REQUEST_ID,REFRESH_PART_NUMBER,
                                                  PROGRAM_TYPE,
                                                  SITE_CODE,
                                                  ROHS_COMPLIANT,
                                                  CDC_AWAITING_SHIPMENT,
                                                  CC_AWAITING_SHIPMENT,
                                                  FB02_ON_HAND_QTY,
                                                  TOTAL_FB02_CDC_CC_QTY,
                                                  CCW_E_RESERVE_QTY,
                                                  CCW_E_AVAIL_TO_RES_QTY,
                                                  CCW_E_AVAILABLE_QTY,
                                                  CCW_R_RESERVE_QTY,
                                                  CCW_R_AVAIL_TO_RES_QTY,
                                                  CCW_R_AVAILABLE_QTY,
                                                  CCW_O_RESERVE_QTY,
                                                  CCW_O_AVAIL_TO_RES_QTY,
                                                  CCW_O_AVAILABLE_QTY,
                                                  TOTAL_CCW_QTY,
                                                  TOTAL_ADJUSTMENT,
                                                  CDC_AWAITING_SHIPMENT_NEW,
                                                  CC_AWAITING_SHIPMENT_NEW,
                                                  DECODE(PROCESS_STATUS,'''
         || v_ignored
         || ''',0,TOTAL_ADJUSTMENT_NEW) TOTAL_ADJUSTMENT_NEW,
                                                  USER_COMMENTS,
                                                  RECON_ADJ_BATCH_ID,
                                                  ALLOW_ADJ_FLAG,
                                                  ALLOW_ADJ_FLAG_NEW,
                                                  APPROVAL_FLAG,
                                                  STRATEGIC_MASKED_QTY,
                                                  V_ATTR2, --US153769
                                                  N_ATTR3, --Recieved Qty
                                                  ';

      --insert into recon_details values('Inside recon view proc',sysdate);
      IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
      THEN
         --insert into recon_details values('Inside lv_sort column and by is not null'||lv_sort_column_name||'and'||lv_sort_column_by,sysdate);
         lv_query :=
               lv_query
            || 'ROW_NUMBER()  OVER (ORDER BY '
            || lv_sort_column_name
            || ' '
            || lv_sort_column_by
            || ' ) AS rnum
                FROM (SELECT *
                        FROM RC_INV_ADMINUI_RECON_ADJ
                       WHERE SITE_CODE = '''
            || i_site_loc
            || '''
                         AND RECON_ADJ_BATCH_ID = '''
            || i_batch_proc_id
            || '''
                        -- AND process_status NOT IN ('''
            || v_processed
            || ''','''
            || v_ignored
            || ''')
                         ';
      ELSE
         --insert into recon_details values('Inside else of lv_sort column and by is not null'||lv_sort_column_name||'and'||lv_sort_column_by,sysdate);
         lv_query :=
               lv_query
            || '
                          ROWNUM RNUM
                    FROM (SELECT *
                    FROM RC_INV_ADMINUI_RECON_ADJ
                   WHERE SITE_CODE = '''
            || i_site_loc
            || '''
                     AND RECON_ADJ_BATCH_ID = '''
            || i_batch_proc_id
            || '''
                    -- AND process_status NOT IN ('''
            || v_processed
            || ''','''
            || v_ignored
            || ''')
                     ';
      END IF;

      IF i_request_id IS NOT NULL
      THEN
         --Commented by satbanda for US134969 <Start>
         /*  lv_query := lv_query||' AND request_id = '||i_request_id;

          lv_cnt_query:=lv_cnt_query||' AND request_id = '||i_request_id;
           */
         --Commented by satbanda for US134969 <End>

         --Added by satbanda for US134969 <Start>
         -- insert into recon_details values('Inside if of i_request_id NOT NULL'||i_request_id,sysdate);
         lv_query :=
               lv_query
            || ' AND request_id IN  ( SELECT TO_NUMBER(REGEXP_SUBSTR ( '''
            || i_request_id
            || ''''
            || ','
            || '''[^,]+'''
            || ',1, LEVEL))
                                                                         FROM DUAL
                                                                   CONNECT BY REGEXP_SUBSTR ('''
            || i_request_id
            || ''''
            || ','
            || '''[^,]+'''
            || ',1, LEVEL)  IS NOT NULL)';

         lv_cnt_query :=
               lv_cnt_query
            || ' AND request_id IN  ( SELECT TO_NUMBER(REGEXP_SUBSTR ( '''
            || i_request_id
            || ''''
            || ','
            || '''[^,]+'''
            || ',1, LEVEL))
                                                                         FROM DUAL
                                                                   CONNECT BY REGEXP_SUBSTR ('''
            || i_request_id
            || ''''
            || ','
            || '''[^,]+'''
            || ',1, LEVEL)  IS NOT NULL)';
      --Added by satbanda for US134969 <End>
      END IF;

      IF i_program_type IS NOT NULL
      THEN
         --insert into recon_details values('Inside if of i_program_type NOT NULL'||i_program_type,sysdate);
         lv_query :=
            lv_query || ' AND program_type = ''' || i_program_type || '''';

         lv_cnt_query :=
               lv_cnt_query
            || ' AND program_type = '''
            || i_program_type
            || '''';
      END IF;

      IF i_refresh_part_number IS NOT NULL
      THEN
         -- insert into recon_details values('Inside if of i_refresh_part_number NOT NULL'||i_refresh_part_number,sysdate);
         lv_common_query := lv_common_query || ' AND ( ';
         lv_i_refresh_part_number := i_refresh_part_number;
         lv_idx := INSTR (lv_i_refresh_part_number, ',');

         IF lv_idx = 0
         THEN
            lv_i_refresh_part_number :=
               REPLACE (lv_i_refresh_part_number, '*', '');
            lv_common_query :=
                  lv_common_query
               || 'UPPER(refresh_part_number) LIKE UPPER(''%'
               || lv_i_refresh_part_number
               || '%'')';
         ELSE
            lv_cur_part_number :=
               SUBSTR (lv_i_refresh_part_number,
                       1,
                       INSTR (lv_i_refresh_part_number, ',') - 1);
            lv_cur_part_number := REPLACE (lv_cur_part_number, '*', '');

            lv_common_query :=
                  lv_common_query
               || 'UPPER(refresh_part_number) LIKE UPPER(''%'
               || lv_cur_part_number
               || '%'')';
            lv_i_refresh_part_number :=
               SUBSTR (lv_i_refresh_part_number, lv_idx + LENGTH (','));
         END IF;


         IF lv_idx > 0
         THEN
            LOOP
               lv_idx := INSTR (lv_i_refresh_part_number, ',');

               IF lv_idx > 0
               THEN
                  lv_cur_part_number :=
                     SUBSTR (lv_i_refresh_part_number,
                             1,
                             INSTR (lv_i_refresh_part_number, ',') - 1);

                  lv_i_refresh_part_number :=
                     SUBSTR (lv_i_refresh_part_number, lv_idx + LENGTH (','));
                  lv_cur_part_number := REPLACE (lv_cur_part_number, '*', '');
                  lv_common_query :=
                        lv_common_query
                     || ' OR UPPER(REFRESH_PART_NUMBER) LIKE  UPPER(''%'
                     || lv_cur_part_number
                     || '%'')';
               ELSE
                  lv_i_refresh_part_number :=
                     REPLACE (lv_i_refresh_part_number, '*', '');
                  lv_common_query :=
                        lv_common_query
                     || ' OR UPPER(REFRESH_PART_NUMBER) LIKE  UPPER(''%'
                     || lv_i_refresh_part_number
                     || '%'')';
                  EXIT;
               END IF;
            END LOOP;
         END IF;

         lv_query := lv_query || lv_common_query || ')';
         lv_cnt_query := lv_cnt_query || lv_common_query || ')';

         INSERT INTO recon_details
              VALUES ('lv_query ' || lv_query, SYSDATE);

         INSERT INTO recon_details
              VALUES ('lv_cnt_query ' || lv_cnt_query, SYSDATE);
      END IF;

      IF i_rohs_compliant IS NOT NULL
      THEN
         --insert into recon_details values('Inside if of i_rohs_compliant NOT NULL'||i_rohs_compliant,sysdate);
         lv_query :=
               lv_query
            || ' AND rohs_compliant = '''
            || i_rohs_compliant
            || '''';

         lv_cnt_query :=
               lv_cnt_query
            || ' AND rohs_compliant = '''
            || i_rohs_compliant
            || '''';
      END IF;

      --Commented by satbanda on 3rd Aug,2017 as per hkarka's mail dated on 1st Aug,2017 <start>
      /*  IF i_total_actual_qty IS NOT NULL
        THEN

           lv_query := lv_query||' AND total_fb02_cdc_cc_qty =  '||i_total_actual_qty;

           lv_cnt_query:=lv_cnt_query||' AND total_fb02_cdc_cc_qty = '||i_total_actual_qty;

        END IF;

        IF i_total_ccw_qty IS NOT NULL
        THEN

           lv_query := lv_query||' AND total_ccw_qty = '||i_total_ccw_qty;

           lv_cnt_query:=lv_cnt_query||' AND total_ccw_qty = '||i_total_ccw_qty;

        END IF;

        IF i_total_adjustment IS NOT NULL
        THEN

           lv_query := lv_query||' AND total_adjustment = '||i_total_adjustment;

           lv_cnt_query:=lv_cnt_query||' AND total_adjustment = '||i_total_adjustment;

        END IF;

        IF i_total_adjustment_new IS NOT NULL
        THEN

           lv_query := lv_query||' AND total_adjustment_new = '||i_total_adjustment_new;

           lv_cnt_query:=lv_cnt_query||' AND total_adjustment_new = '||i_total_adjustment_new;

        END IF;

        IF i_cdc_shipment_qty IS NOT NULL
        THEN

           lv_query := lv_query||' AND cdc_awaiting_shipment = '||i_cdc_shipment_qty;

           lv_cnt_query:=lv_cnt_query||' AND cdc_awaiting_shipment = '||i_cdc_shipment_qty;

        END IF;

        IF i_cdc_shipment_qty_new IS NOT NULL
        THEN

           lv_query := lv_query||' AND cdc_awaiting_shipment_new = '||i_cdc_shipment_qty_new;

           lv_cnt_query:=lv_cnt_query||' AND cdc_awaiting_shipment_new = '||i_cdc_shipment_qty_new;

        END IF;

        IF i_cc_shipment_qty IS NOT NULL
        THEN

           lv_query := lv_query||' AND cc_awaiting_shipment = '||i_cc_shipment_qty;

           lv_cnt_query:=lv_cnt_query||' AND cc_awaiting_shipment = '||i_cc_shipment_qty;

        END IF;

        IF i_cc_shipment_qty_new IS NOT NULL
        THEN

           lv_query := lv_query||' AND cc_awaiting_shipment_new = '||i_cc_shipment_qty_new;

           lv_cnt_query:=lv_cnt_query||' AND cc_awaiting_shipment_new = '||i_cc_shipment_qty_new;

        END IF;

        IF i_fb02_on_hand_qty IS NOT NULL
        THEN

           lv_query := lv_query||' AND fb02_on_hand_qty = '||i_fb02_on_hand_qty;

           lv_cnt_query:=lv_cnt_query||' AND fb02_on_hand_qty = '||i_fb02_on_hand_qty;

        END IF;*/
      --Commented by satbanda on 3rd Aug,2017 as per hkarka's mail dated on 1st Aug,2017 <End>

      IF i_adjustment_allow IS NOT NULL
      THEN
         --insert into recon_details values('Inside if of i_adjustment_allow NOT NULL'||i_adjustment_allow,sysdate);
         lv_query :=
               lv_query
            || ' AND ALLOW_ADJ_FLAG = '''
            || i_adjustment_allow
            || '''';

         lv_cnt_query :=
               lv_cnt_query
            || ' AND ALLOW_ADJ_FLAG = '''
            || i_adjustment_allow
            || '''';
      END IF;

      IF i_adjustment_allow_new IS NOT NULL
      THEN
         --insert into recon_details values('Inside if of i_adjustment_allow_new NOT NULL'||i_adjustment_allow_new,sysdate);
         lv_query :=
               lv_query
            || ' AND ALLOW_ADJ_FLAG_NEW = '''
            || i_adjustment_allow_new
            || '''';

         lv_cnt_query :=
               lv_cnt_query
            || ' AND ALLOW_ADJ_FLAG_NEW = '''
            || i_adjustment_allow_new
            || '''';
      END IF;

      IF lv_sort_column_name IS NOT NULL
      THEN
         --insert into recon_details values('Inside if of lv_sort_column_name NOT NULL'||lv_sort_column_name,sysdate);
         lv_allrecon_data :=
               lv_query
            || ' ))  ORDER BY '
            || lv_sort_column_name
            || ' '
            || lv_sort_column_by
            || ')';                           --Added by satbanda for US134969

         lv_query :=
               lv_query
            || ' ))  WHERE RNUM <= '
            || i_max_row
            || ' AND RNUM >= '
            || i_min_row
            || ' ORDER BY '
            || lv_sort_column_name
            || ' '
            || lv_sort_column_by
            || ')';
      ELSE
         --insert into recon_details values('Inside else of lv_sort_column_name NOT NULL'||lv_sort_column_name,sysdate);
         lv_allrecon_data := lv_query || ' ) ) )'; --Added by satbanda for US134969

         lv_query :=
               lv_query
            || ' ) ) WHERE RNUM <= '
            || lv_max_row
            || ' AND RNUM >= '
            || lv_min_row
            || ' )';
      END IF;

      BEGIN
         EXECUTE IMMEDIATE lv_query BULK COLLECT INTO type_inv_recon_tab;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 200);

            P_RCEC_ERROR_LOG (
               I_module_name       => 'P_INV_LOC_RECON_VIEW',
               I_entity_name       => NULL,
               I_entity_id         => NULL,
               I_ext_entity_name   => NULL,
               I_ext_entity_id     => NULL,
               I_error_type        => 'EXCEPTION',
               i_Error_Message     =>    'Error getting while executing limited Recondata search query '
                                      || ' <> '
                                      || v_message
                                      || ' LineNo=> '
                                      || DBMS_UTILITY.Format_error_backtrace,
               I_created_by        => i_user_id,
               I_updated_by        => i_user_id);
      END;


      --Added by satbanda for US134969 <Start>
      BEGIN
         EXECUTE IMMEDIATE lv_allrecon_data
            BULK COLLECT INTO type_allinv_recon_tab;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 200);

            P_RCEC_ERROR_LOG (
               I_module_name       => 'P_INV_LOC_RECON_VIEW',
               I_entity_name       => NULL,
               I_entity_id         => NULL,
               I_ext_entity_name   => NULL,
               I_ext_entity_id     => NULL,
               I_error_type        => 'EXCEPTION',
               i_Error_Message     =>    'Error getting while executing Recondata search query '
                                      || ' <> '
                                      || v_message
                                      || ' LineNo=> '
                                      || DBMS_UTILITY.Format_error_backtrace,
               I_created_by        => i_user_id,
               I_updated_by        => i_user_id);
      END;

      --Added by satbanda for US134969 <End>

      BEGIN
         EXECUTE IMMEDIATE lv_cnt_query INTO lv_search_cnt;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 200);

            P_RCEC_ERROR_LOG (
               I_module_name       => 'P_INV_LOC_RECON_VIEW',
               I_entity_name       => NULL,
               I_entity_id         => NULL,
               I_ext_entity_name   => NULL,
               I_ext_entity_id     => NULL,
               I_error_type        => 'EXCEPTION',
               i_Error_Message     =>    'Error getting while executing Count Search query '
                                      || ' <> '
                                      || v_message
                                      || ' LineNo=> '
                                      || DBMS_UTILITY.Format_error_backtrace,
               I_created_by        => i_user_id,
               I_updated_by        => i_user_id);
      END;



      o_inv_recon_tab := type_inv_recon_tab;

      o_search_count := lv_search_cnt;
      o_inv_allrecon_tab := type_allinv_recon_tab; --Added by satbanda for US134969
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := SUBSTR (SQLERRM, 1, 200);

         P_RCEC_ERROR_LOG (
            I_module_name       => 'P_INV_LOC_RECON_VIEW',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while executing P_INV_LOC_RECON_VIEW '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => i_user_id,
            I_updated_by        => i_user_id);
   END P_INV_LOC_RECON_VIEW;

   --Added by satbanda on 20th July, 2017 for US122733 (Sorting and Advanced Filter) <End>

   --Added by satbanda on 12th Jan,2018 for US148664 (Recon Histroy) <Start>
   PROCEDURE P_INV_LOC_RECON_HISTORY (
      i_login_user           IN            VARCHAR2,
      o_recon_fve_hist_obj      OUT NOCOPY RC_INV_RECON_HIST_OBJECT,
      o_recon_lro_hist_obj      OUT NOCOPY RC_INV_RECON_HIST_OBJECT)
   IS
      ltype_recon_hist      RC_INV_RECON_HIST_OBJECT;
      ltab_recon_fve_hist   RC_INV_RECON_HIST_DTL_TAB
                               := RC_INV_RECON_HIST_DTL_TAB ();
      ltab_recon_lro_hist   RC_INV_RECON_HIST_DTL_TAB
                               := RC_INV_RECON_HIST_DTL_TAB ();
   BEGIN
      BEGIN
         SELECT RC_INV_RECON_HIST_DTL_OBJECT (ATTRIBUTE1,
                                              STATUS,
                                              COMPLETION_DATE,
                                              ADJUSTEDDATE,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL)
           BULK COLLECT INTO ltab_recon_fve_hist
           FROM (  SELECT ATTRIBUTE1,
                          CASE
                             WHEN     STATUS = v_processed
                                  AND (SELECT COUNT (1)
                                         FROM RC_INV_RECONUI_SETUP
                                        WHERE     ATTRIBUTE1 = ris.ATTRIBUTE1
                                              AND MODULE_NAME = v_adjmnt_job) =
                                         1
                             THEN
                                v_reconciled
                             WHEN STATUS = v_processed
                             THEN
                                'IN REVIEW'
                             ELSE
                                v_ignored
                          END
                             STATUS,
                          COMPLETION_DATE,
                          CASE
                             WHEN STATUS = v_processed
                             THEN
                                (SELECT COMPLETION_DATE
                                   FROM RC_INV_RECONUI_SETUP
                                  WHERE     ATTRIBUTE1 = ris.ATTRIBUTE1
                                        AND MODULE_NAME = v_adjmnt_job
                                        AND ROWNUM < 2)
                          END
                             ADJUSTEDDATE
                     FROM RC_INV_RECONUI_SETUP ris
                    WHERE     ATTRIBUTE2 = v_FVE
                          AND MODULE_NAME = v_recon_job
                          AND EXISTS
                                 (SELECT 1
                                    FROM CDM_TIME_HIERARCHY_DIM a
                                   WHERE     1 = 1
                                         AND TRUNC (SYSDATE) =
                                                TRUNC (CALENDAR_DATE)
                                         AND TRUNC (ris.COMPLETION_DATE) BETWEEN (SELECT CALENDAR_QTR_START_DATE
                                                                                    FROM CDM_TIME_HIERARCHY_DIM
                                                                                   WHERE TRUNC (
                                                                                              a.CALENDAR_QTR_START_DATE
                                                                                            - 1) =
                                                                                            TRUNC (
                                                                                               CALENDAR_DATE))
                                                                             AND CALENDAR_QTR_END_DATE)
                 ORDER BY COMPLETION_DATE DESC);

         ltype_recon_hist :=
            RC_INV_RECON_HIST_OBJECT (v_FVE, ltab_recon_fve_hist);
         o_recon_fve_hist_obj := ltype_recon_hist;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         SELECT RC_INV_RECON_HIST_DTL_OBJECT (ATTRIBUTE1,
                                              STATUS,
                                              COMPLETION_DATE,
                                              ADJUSTEDDATE,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL)
           BULK COLLECT INTO ltab_recon_lro_hist
           FROM (  SELECT ATTRIBUTE1,
                          CASE
                             WHEN     STATUS = v_processed
                                  AND (SELECT COUNT (1)
                                         FROM RC_INV_RECONUI_SETUP
                                        WHERE     ATTRIBUTE1 = ris.ATTRIBUTE1
                                              AND MODULE_NAME = v_adjmnt_job) =
                                         1
                             THEN
                                v_reconciled
                             WHEN STATUS = v_processed
                             THEN
                                'IN REVIEW'
                             ELSE
                                v_ignored
                          END
                             STATUS,
                          COMPLETION_DATE,
                          CASE
                             WHEN STATUS = v_processed
                             THEN
                                (SELECT COMPLETION_DATE
                                   FROM RC_INV_RECONUI_SETUP
                                  WHERE     ATTRIBUTE1 = ris.ATTRIBUTE1
                                        AND MODULE_NAME = v_adjmnt_job
                                        AND ROWNUM < 2)
                          END
                             ADJUSTEDDATE
                     FROM RC_INV_RECONUI_SETUP ris
                    WHERE     ATTRIBUTE2 = v_LRO
                          AND MODULE_NAME = v_recon_job
                          AND EXISTS
                                 (SELECT 1
                                    FROM CDM_TIME_HIERARCHY_DIM a
                                   WHERE     1 = 1
                                         AND TRUNC (SYSDATE) =
                                                TRUNC (CALENDAR_DATE)
                                         AND TRUNC (ris.COMPLETION_DATE) BETWEEN (SELECT CALENDAR_QTR_START_DATE
                                                                                    FROM CDM_TIME_HIERARCHY_DIM
                                                                                   WHERE TRUNC (
                                                                                              a.CALENDAR_QTR_START_DATE
                                                                                            - 1) =
                                                                                            TRUNC (
                                                                                               CALENDAR_DATE))
                                                                             AND CALENDAR_QTR_END_DATE)
                 ORDER BY COMPLETION_DATE DESC);

         ltype_recon_hist :=
            RC_INV_RECON_HIST_OBJECT (v_LRO, ltab_recon_lro_hist);
         o_recon_lro_hist_obj := ltype_recon_hist;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END P_INV_LOC_RECON_HISTORY;

   FUNCTION F_GET_ADJINV_RETAIL_OUTLET (
      i_tab_recon_inv_data   IN RC_INV_RECON_ADJ_TAB)
      RETURN RC_INV_RECON_ADJ_TAB
   IS
      lv_adj_qty_r          NUMBER := 0;
      lv_adj_qty_o          NUMBER := 0;
      lv_adj_qty            NUMBER := 0;
      ltab_recon_inv_data   RC_INV_RECON_ADJ_TAB := RC_INV_RECON_ADJ_TAB ();
   BEGIN
      ltab_recon_inv_data := i_tab_recon_inv_data;

      FOR rec_inv IN i_tab_recon_inv_data.FIRST .. ltab_recon_inv_data.LAST
      LOOP
         IF     UPPER (ltab_recon_inv_data (rec_inv).PROGRAM_TYPE) !=
                   v_Excess
            AND ltab_recon_inv_data (rec_inv).total_adjustment_new <> 0
         THEN
            lv_adj_qty_r := 0;
            lv_adj_qty_o := 0;
            lv_adj_qty := 0;

            IF    ltab_recon_inv_data (rec_inv).total_adjustment_new > 0
               OR ltab_recon_inv_data (rec_inv).ccw_o_available_qty <= 0
            THEN
               lv_adj_qty_r :=
                  ltab_recon_inv_data (rec_inv).total_adjustment_new;
            ELSIF     ltab_recon_inv_data (rec_inv).ccw_o_available_qty > 0
                  AND ltab_recon_inv_data (rec_inv).total_adjustment_new < 0
            THEN
               IF ltab_recon_inv_data (rec_inv).ccw_o_avail_to_res_qty >=
                     ABS (ltab_recon_inv_data (rec_inv).total_adjustment_new)
               THEN
                  lv_adj_qty_o :=
                     ltab_recon_inv_data (rec_inv).total_adjustment_new;
               ELSE
                  lv_adj_qty_o :=
                     -ltab_recon_inv_data (rec_inv).ccw_o_avail_to_res_qty;

                  lv_adj_qty :=
                       ABS (
                          ltab_recon_inv_data (rec_inv).total_adjustment_new)
                     - ltab_recon_inv_data (rec_inv).ccw_o_avail_to_res_qty;

                  IF ltab_recon_inv_data (rec_inv).ccw_r_avail_to_res_qty >=
                        lv_adj_qty
                  THEN
                     lv_adj_qty_r := - (lv_adj_qty);
                  ELSE
                     lv_adj_qty_r :=
                        - (ltab_recon_inv_data (rec_inv).ccw_r_avail_to_res_qty);
                     lv_adj_qty :=
                          lv_adj_qty
                        - ltab_recon_inv_data (rec_inv).ccw_r_avail_to_res_qty;

                     IF ltab_recon_inv_data (rec_inv).ccw_o_reserve_qty >=
                           lv_adj_qty
                     THEN
                        lv_adj_qty_o := lv_adj_qty_o - lv_adj_qty;
                     ELSE
                        lv_adj_qty_o :=
                             lv_adj_qty_o
                           - ltab_recon_inv_data (rec_inv).ccw_o_reserve_qty;
                        lv_adj_qty :=
                             lv_adj_qty
                           - ltab_recon_inv_data (rec_inv).ccw_o_reserve_qty;
                        lv_adj_qty_r := lv_adj_qty_r - lv_adj_qty;
                     END IF;
                  END IF;
               END IF;
            END IF;
         END IF;

         ltab_recon_inv_data (rec_inv).n_attr1 := lv_adj_qty_r;
         ltab_recon_inv_data (rec_inv).n_attr2 := lv_adj_qty_o;
      END LOOP;

      RETURN ltab_recon_inv_data;
   END F_GET_ADJINV_RETAIL_OUTLET;
--Added by satbanda on 22nd Jan,2018 for US148664 (Recon Histroy) <End>

END RC_INV_RECON_ADJ_PKG;
/