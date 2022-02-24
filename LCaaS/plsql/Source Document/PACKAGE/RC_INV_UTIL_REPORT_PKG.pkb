CREATE OR REPLACE PACKAGE BODY CRPADM./*AppDB: 1045349*/
                                               "RC_INV_UTIL_REPORT_PKG"
AS
   /*
     ****************************************************************************************************************
     * Object Name       :RC_INV_UTIL_REPORT_PKG
     *  Project Name : lNVENTORY
      * Copy Rights:   Cisco Systems, INC., CALIFORNIA
     * Description       : This API for inventory Report  utility
     * Created Date:
     ===================================================================================================+
     * Date         Modified by     Bug/Case #           Revision                   Description
     ===================================================================================================+
       13-Sep-2017  satbanda                             1.0                       Created new version
       14-Sep-2017  sridvasu                             1.1                       Added RC_INV_PID_ASSIGN_EXCEPTN_RPT
       05-Oct-2017  satbanda  (Satyanarayana Bandaru)    1.2                       Modified GET_Z05_MOV_VALUE function for new requirement.
       06-Oct-2017  satbanda  (Satyanarayana Bandaru)    1.3                       Added function fn_get_alldgi_inv for calculating GDGI Quanity.
       25-Oct-2017  satbanda  (Satyanarayana Bandaru)    2.0                       Added procedure for Inventory transfer requests
       01-Feb-2018  sridvasu  (Sridevi Vasudevan)        2.1                       Added costing orgs 0ZU & 0ZB to RC_INV_PID_ASSIGN_EXCEPTN_RPT proc as part of US156757.
       27-Feb-2018  sridvasu  (Sridevi Vasudevan)        3.1                       Added this table RC_INV_ORG_ASSIGNMNT_EXCEPTION in RC_INV_PID_ASSIGN_EXCEPTN_RPT as part of R12 upgrade
       04-JUL-2018  csirigir  (Chandra S)                3.2                       Added this table RC_FIN_DEMAND_LIST in RC_INV_PID_ASSIGN_EXCEPTN_RPT as part of R12 upgrade
     ===================================================================================================+
    */

   PROCEDURE RC_INV_DISPOSITION_MAIL (i_mail_from   IN VARCHAR2,
                                      i_mail_to     IN VARCHAR2)
   IS
      g_error_msg        VARCHAR2 (2000);
      lv_msg_from        VARCHAR2 (500);
      lv_msg_to          VARCHAR2 (500);
      lv_msg_subject     VARCHAR2 (32767);
      lv_msg_text        VARCHAR2 (32767);
      lv_output_hdr      CLOB;
      lv_count           NUMBER := 0;
      lv_output          CLOB;
      lv_database_name   VARCHAR2 (50);
      lv_filename        VARCHAR2 (5000);
      lv_start_time      VARCHAR2 (100);
   BEGIN
      SELECT ora_database_name INTO lv_database_name FROM DUAL;

      lv_msg_from := TRIM (i_mail_from);

      lv_msg_to := TRIM (i_mail_to);

      SELECT TO_CHAR (SYSDATE, 'MM/DD/YYYY HH:MI:SS PM')
        INTO lv_start_time
        FROM DUAL;

      -- lv_filename:='Inventory_Disposition_Report_' || lv_start_time;

      lv_filename := 'NonEU_Inventory_Disposition_Report_' || lv_start_time;

      -- lv_msg_subject :=' Inventory Disposition Report from Z26/Z29 to Z05 - ' || lv_start_time;
      lv_msg_subject :=
         'NonEU_Inventory_Disposition_Report-' || lv_start_time;

      IF (lv_database_name = 'FNTR2DEV.CISCO.COM')
      THEN
         lv_msg_subject := 'DEV : ' || lv_msg_subject;
      ELSIF (lv_database_name = 'FNTR2STG.CISCO.COM')
      THEN
         lv_msg_subject := 'STAGE : ' || lv_msg_subject;
      ELSE
         lv_msg_subject := lv_msg_subject;
      END IF;

      lv_msg_text :=
            '<HTML> Hi Team,'
         || '<br />'
         || '<br />'
         || 'Please find attached Inventory Disposition Report from Z26/Z29 to Z05 for non EU orders fulfillment.'
         || '<br /><br />'
         || 'PLEASE DO NOT REPLY... This is an Auto generated Email.'
         || '<br /><br /> '
         || 'Thanks,'
         || '<br />'
         || 'Refresh Central Support team </HTML>';

      BEGIN
         DELETE FROM RC_INV_DISPOSITION_HIST_TEMP;

         INSERT INTO RC_INV_DISPOSITION_HIST_TEMP
              SELECT product_id,
                     noneu_backlog,
                     dist_noneu_orders,
                     non_eu_demand,
                     ROUND (noneu_backlog_value, 2),
                     eu_backlog,
                     eu_demand,
                     nonemea_backlog,
                     nam_demand,
                     dg_z29_z26,
                     available_to_reserve_fgi_fve,
                     dg_z05,
                     available_to_reserve_fgi_lro,
                     Backlog_Orders_Prior_to_Non_EU,
                     --Commented by satbanda for new changes on 3rd october while calculating move to Z05 <Start>
                     /*GET_Z05_MOV_VALUE (GREATEST(noneu_backlog,non_eu_demand),
                                   GREATEST(eu_backlog,eu_demand),GREATEST(nonemea_backlog,nam_demand),
                                   dg_z29_z26,
                                   available_to_reserve_fgi_fve,
                                   dg_z05,
                                   available_to_reserve_fgi_lro) "Suggested Qty move to Z05",*/
                     --Commented by satbanda for new changes on 3rd october while calculating move to Z05 <End>
                     --Added by satbanda for new changes on 3rd october while calculating move to Z05 <Start>
                     GET_Z05_MOV_VALUE (noneu_backlog,
                                        non_eu_demand,
                                        eu_backlog,
                                        eu_demand,
                                        nonemea_backlog,
                                        dg_z29_z26,
                                        available_to_reserve_fgi_fve,
                                        dg_z05,
                                        available_to_reserve_fgi_lro)
                        "Suggested Qty move to Z05",
                     --Added by satbanda for new changes on 3rd october while calculating move to Z05 <End>
                     repair_partner,
                     SYSDATE,
                     'Report Admin',
                     SYSDATE,
                     'Report Admin'
                FROM (SELECT ssot1.PRODUCT_ID,
                             ssot1.noneu_backlog,
                             ssot1.noneu_backlog_value,
                             eu_backlog,
                             nonemea_backlog,
                             ssot1.order_submission_date,
                             NVL (
                                fn_get_alldgi_inv (ssot1.repair_partner,
                                                   'Z26,Z29 ',
                                                   ssot1.product_id),
                                0)
                                dg_z29_z26,
                             available_to_reserve_fgi_fve,
                             NVL (
                                fn_get_alldgi_inv (ssot1.repair_partner,
                                                   'Z05 ',
                                                   ssot1.product_id),
                                0)
                                dg_z05,
                             available_to_reserve_fgi_lro,
                             NVL (ren.nam_demand, 0)  nam_demand,
                             NVL (ren.eu_demand, 0)   eu_demand,
                             NVL (ren.non_eu_demand, 0) non_eu_demand,
                             ssot1.repair_partner,
                               (SELECT NVL (
                                          SUM (
                                               ssot2.RESERVED_DGI
                                             + ssot2.S2S_DGI_QUANTITY),
                                          0)
                                  FROM RMKTGADM.RMK_SSOT_TRANSACTIONS ssot2,
                                       crpadm.ex_customer_address   address2,
                                       rmktgadm.RMK_COUNTRY_THEATER_MAP
                                       country_map2
                                 WHERE     ssot2.product_id = ssot1.product_id
                                       AND ssot2.ship_to_site_use_id =
                                              address2.ex_site_use_id
                                       AND country_map2.rctm_std_country_code =
                                              address2.ex_country
                                       AND NVL (country_map2.rohs_compliant,
                                                '-1') IN
                                              'YES'
                                       AND country_map2.rctm_theater = 'EMEA'
                                       AND NVL (ssot2.order_submission_date,
                                                SYSDATE) <=
                                              NVL (ssot1.order_submission_date,
                                                   SYSDATE)
                                       AND   NVL (ssot2.RESERVED_DGI, 0)
                                           + NVL (ssot2.S2S_DGI_QUANTITY, 0) >
                                              0)
                             + (SELECT NVL (
                                          SUM (
                                               ssot3.RESERVED_DGI
                                             + ssot3.S2S_DGI_QUANTITY),
                                          0)
                                  FROM RMKTGADM.RMK_SSOT_TRANSACTIONS ssot3,
                                       crpadm.ex_customer_address   address3,
                                       rmktgadm.RMK_COUNTRY_THEATER_MAP
                                       country_map3
                                 WHERE     ssot3.product_id = ssot1.product_id
                                       AND ssot3.ship_to_site_use_id =
                                              address3.ex_site_use_id
                                       AND country_map3.rctm_std_country_code =
                                              address3.ex_country
                                       AND country_map3.rctm_theater <> 'EMEA'
                                       AND NVL (ssot3.order_submission_date,
                                                SYSDATE) <=
                                              NVL (ssot1.order_submission_date,
                                                   SYSDATE)
                                       AND   NVL (ssot3.RESERVED_DGI, 0)
                                           + NVL (ssot3.S2S_DGI_QUANTITY, 0) >
                                              0)
                                Backlog_Orders_Prior_to_Non_EU,
                               (SELECT COUNT (DISTINCT ssot2.WEB_ORDER_ID)
                                  FROM RMKTGADM.RMK_SSOT_TRANSACTIONS ssot2,
                                       crpadm.ex_customer_address   address2,
                                       rmktgadm.RMK_COUNTRY_THEATER_MAP
                                       country_map2
                                 WHERE     ssot2.product_id = ssot1.product_id
                                       AND ssot2.ship_to_site_use_id =
                                              address2.ex_site_use_id
                                       AND country_map2.rctm_std_country_code =
                                              address2.ex_country
                                       AND NVL (country_map2.rohs_compliant,
                                                '-1') IN
                                              'YES'
                                       AND country_map2.rctm_theater = 'EMEA'
                                       AND NVL (ssot2.order_submission_date,
                                                SYSDATE) <=
                                              NVL (ssot1.order_submission_date,
                                                   SYSDATE)
                                       AND   NVL (ssot2.RESERVED_DGI, 0)
                                           + NVL (ssot2.S2S_DGI_QUANTITY, 0) >
                                              0)
                             + (SELECT COUNT (DISTINCT ssot3.WEB_ORDER_ID)
                                  FROM RMKTGADM.RMK_SSOT_TRANSACTIONS ssot3,
                                       crpadm.ex_customer_address   address3,
                                       rmktgadm.RMK_COUNTRY_THEATER_MAP
                                       country_map3
                                 WHERE     ssot3.product_id = ssot1.product_id
                                       AND ssot3.ship_to_site_use_id =
                                              address3.ex_site_use_id
                                       AND country_map3.rctm_std_country_code =
                                              address3.ex_country
                                       AND country_map3.rctm_theater <> 'EMEA'
                                       AND   NVL (ssot3.RESERVED_DGI, 0)
                                           + NVL (ssot3.S2S_DGI_QUANTITY, 0) >
                                              0
                                       AND NVL (ssot3.order_submission_date,
                                                SYSDATE) <=
                                              NVL (ssot1.order_submission_date,
                                                   SYSDATE))
                                DIST_NONEU_ORDERS
                        FROM (  SELECT ssot.PRODUCT_ID,
                                       SUM (
                                          (  ssot.RESERVED_DGI
                                           + ssot.S2S_DGI_QUANTITY))
                                          AS noneu_backlog,
                                       SUM (
                                          (  (  ssot.RESERVED_DGI
                                              + ssot.S2S_DGI_QUANTITY)
                                           * ssot.net_price))
                                          AS noneu_backlog_value,
                                       (SELECT NVL (
                                                  SUM (
                                                       ssot2.RESERVED_DGI
                                                     + ssot2.S2S_DGI_QUANTITY),
                                                  0)
                                          FROM RMKTGADM.RMK_SSOT_TRANSACTIONS
                                               ssot2,
                                               crpadm.ex_customer_address
                                               address2,
                                               rmktgadm.RMK_COUNTRY_THEATER_MAP
                                               country_map2
                                         WHERE     ssot2.product_id =
                                                      ssot.product_id
                                               AND ssot2.ship_to_site_use_id =
                                                      address2.ex_site_use_id
                                               AND country_map2.rctm_std_country_code =
                                                      address2.ex_country
                                               AND NVL (
                                                      country_map2.rohs_compliant,
                                                      '-1') IN
                                                      'YES'
                                               AND country_map2.rctm_theater =
                                                      'EMEA')
                                          eu_backlog,
                                       (SELECT NVL (
                                                  SUM (
                                                       ssot3.RESERVED_DGI
                                                     + ssot3.S2S_DGI_QUANTITY),
                                                  0)
                                          FROM RMKTGADM.RMK_SSOT_TRANSACTIONS
                                               ssot3,
                                               crpadm.ex_customer_address
                                               address3,
                                               rmktgadm.RMK_COUNTRY_THEATER_MAP
                                               country_map3
                                         WHERE     ssot3.product_id =
                                                      ssot.product_id
                                               AND ssot3.ship_to_site_use_id =
                                                      address3.ex_site_use_id
                                               AND country_map3.rctm_std_country_code =
                                                      address3.ex_country
                                               AND country_map3.rctm_theater <>
                                                      'EMEA')
                                          nonemea_backlog,
                                       (SELECT NVL (
                                                  SUM (
                                                     xrim.available_to_reserve_fgi),
                                                  0)
                                          FROM rmktgadm.xxcpo_rmk_inventory_master
                                               xrim
                                         WHERE     xrim.part_number =
                                                      ssot.product_id
                                               AND xrim.site_code = 'FVE')
                                          available_to_reserve_fgi_fve,
                                       (SELECT NVL (
                                                  SUM (
                                                     xrim.available_to_reserve_fgi),
                                                  0)
                                          FROM rmktgadm.xxcpo_rmk_inventory_master
                                               xrim
                                         WHERE     xrim.part_number =
                                                      ssot.product_id
                                               AND xrim.site_code = 'LRO')
                                          available_to_reserve_fgi_lro,
                                       MAX (ORDER_SUBMISSION_DATE)
                                          ORDER_SUBMISSION_DATE,
                                       (SELECT bpm_user_id
                                          FROM RC_PRODUCT_REPAIR_SETUP rpr
                                         WHERE     REFRESH_PART_NUMBER =
                                                      ssot.PRODUCT_ID
                                               AND (REPAIR_PARTNER_ID,
                                                    REFRESH_METHOD_ID) IN
                                                      (  SELECT rprp.REPAIR_PARTNER_ID,
                                                                MIN (
                                                                   REFRESH_METHOD_ID)
                                                           FROM RC_PRODUCT_REPAIR_SETUP
                                                                rprs,
                                                                RC_PRODUCT_REPAIR_PARTNER
                                                                rprp,
                                                                RC_PRODUCT_MASTER
                                                                rpm
                                                          WHERE     rprs.REFRESH_PART_NUMBER =
                                                                       rpr.REFRESH_PART_NUMBER
                                                                AND rprs.repair_partner_id =
                                                                       rprp.repair_partner_id
                                                                AND rpm.REFRESH_PART_NUMBER =
                                                                       rpr.REFRESH_PART_NUMBER
                                                                AND rprp.PROGRAM_TYPE =
                                                                       rpm.PROGRAM_TYPE
                                                                AND rprp.zcode IN
                                                                       ('Z29')
                                                       GROUP BY rprp.REPAIR_PARTNER_ID))
                                          repair_partner
                                  FROM RMKTGADM.RMK_SSOT_TRANSACTIONS ssot,
                                       crpadm.ex_customer_address address,
                                       rmktgadm.RMK_COUNTRY_THEATER_MAP
                                       country_map
                                 WHERE     1 = 1
                                       AND ssot.ship_to_site_use_id =
                                              ex_site_use_id
                                       AND country_map.rctm_std_country_code =
                                              address.ex_country
                                       AND country_map.rctm_theater IN ('EMEA')
                                       AND NVL (country_map.rohs_compliant, '-1') =
                                              'NO'
                                       AND ssot.TRANSACTION_TYPE IS NOT NULL
                                       AND ssot.transaction_type IN
                                              ('S2S_ORDER',
                                               'STANDALONE_ORDER',
                                               'WEB_ORDER')
                                       AND NVL (ssot.SO_LINE_STATUS, 'NA') NOT IN
                                              ('INVOICE_ELIGIBLE',
                                               'CANCELLED',
                                               'CISCOSHIPPED',
                                               'DELETED',
                                               'INVOICED')
                                       AND    ssot.WEB_ORDER_STATUS
                                           || '-'
                                           || SO_LINE_STATUS <>
                                              'CANCELLED-OO_ELIGIBLE'
                                       AND (    ssot.RESERVATION_HEADER_KEY
                                                   IS NOT NULL -- FETCHES ROWS WHICH HAS RESERVATIONS
                                            AND ssot.RESERVATION_DETAIL_KEY
                                                   IS NOT NULL -- FETCHES ROWS WHICH HAS RESERVATIONS
                                            AND (       ssot.RESERVATION_SITE_OBJECT_ID
                                                           IS NULL -- Do not consider S2S lines for non VSITE records
                                                    AND ssot.S2S_TRANSFER_REQUIRED =
                                                           'N'
                                                 OR ssot.RESERVATION_SITE_OBJECT_ID
                                                       IS NOT NULL))
                              GROUP BY ssot.PRODUCT_ID
                                HAVING SUM (
                                          (  ssot.RESERVED_DGI
                                           + ssot.S2S_DGI_QUANTITY)) > 0) ssot1,
                             crpsc.RC_FORECASTING_EU_NONEU_DTLS ren
                       WHERE ssot1.product_id = ren.refresh_part_number(+))
                     ssot
            ORDER BY 1, 2;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            v_message :=
                  'Error while inserting the dispostion data in temp :'
               || SUBSTR (SQLERRM, 1, 50);

            INSERT INTO CRPADM.RC_CRON_HISTORY_LOG (CHL_ID,
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
                         'RC_INV_DISPOSITION_MAIL',
                         v_message,
                         'RC_INV_UTIL_REPORT_PKG');
      END;

      lv_output_hdr :=
            'Part Number'
         || ','
         || 'Non EU Backlog'
         || ','
         || 'No.of Orders prior to Non EU'
         || ','
         || 'Non EU Demand'
         || ','
         || 'Non EU $ value'
         || ','
         || 'EU Backlog'
         || ','
         || 'EU Demand'
         || ','
         || 'NAM Backlog'
         || ','
         || 'NAM Demand'
         || ','
         || 'DGI in Z29/Z26'
         || ','
         || 'Avaialble to Reserve FG(FVE)'
         || ','
         || 'DGI in Z05'
         || ','
         || 'Available to Reserve FG(LRO)'
         || ','
         || 'Backlog Orders prior to Non EU'
         || ','
         || 'Suggested Qty move to Z05'
         || ','
         || 'Responsible Repair Partner'
         || UTL_TCP.crlf;

      lv_count := 0;

      FOR rec IN (SELECT *
                    FROM RC_INV_DISPOSITION_HIST_TEMP)
      LOOP
         IF lv_count = 0
         THEN
            lv_output :=
                  lv_output_hdr
               || rec.product_id
               || ','
               || rec.non_eu_backlog
               || ','
               || rec.dist_noneu_backlog
               || ','
               || rec.non_eu_demand
               || ','
               || rec.non_eu_backlog_v
               || ','
               || rec.eu_backlog
               || ','
               || rec.eu_demand
               || ','
               || rec.nonemea_backlog
               || ','
               || rec.nam_demand
               || ','
               || rec.dgi_z29_z26
               || ','
               || rec.available_to_res_fgi_fve
               || ','
               || rec.dgi_z05
               || ','
               || rec.available_to_res_fgi_lro
               || ','
               || rec.prior_backlog_orders
               || ','
               || rec.qty_move_to_z05
               || ','
               || rec.repair_partner
               || ','
               || UTL_TCP.crlf;
         ELSE
            lv_output :=
                  lv_output
               || rec.product_id
               || ','
               || rec.non_eu_backlog
               || ','
               || rec.dist_noneu_backlog
               || ','
               || rec.non_eu_demand
               || ','
               || rec.non_eu_backlog_v
               || ','
               || rec.eu_backlog
               || ','
               || rec.eu_demand
               || ','
               || rec.nonemea_backlog
               || ','
               || rec.nam_demand
               || ','
               || rec.dgi_z29_z26
               || ','
               || rec.available_to_res_fgi_fve
               || ','
               || rec.dgi_z05
               || ','
               || rec.available_to_res_fgi_lro
               || ','
               || rec.prior_backlog_orders
               || ','
               || rec.qty_move_to_z05
               || ','
               || rec.repair_partner
               || ','
               || UTL_TCP.crlf;
         END IF;

         lv_count := lv_count + 1;
      END LOOP;

      IF lv_count = 0
      THEN
         lv_output := lv_output_hdr;
      END IF;

      BEGIN
         RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (lv_msg_from,
                                                       lv_msg_to,
                                                       lv_msg_subject,
                                                       lv_msg_text,
                                                       lv_filename,
                                                       lv_output);

         INSERT INTO CRPADM.RC_CRON_HISTORY_LOG (CHL_ID,
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
                      'RC_INV_DISPOSITION_MAIL',
                      NULL,
                      'RC_INV_UTIL_REPORT_PKG');

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 50);

            INSERT INTO CRPADM.RC_CRON_HISTORY_LOG (CHL_ID,
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
                         'RC_INV_DISPOSITION_MAIL',
                         v_message,
                         'RC_INV_UTIL_REPORT_PKG');
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO CRPADM.RC_CRON_HISTORY_LOG (CHL_ID,
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
                      'RC_INV_DISPOSITION_MAIL',
                      v_message,
                      'RC_INV_UTIL_REPORT_PKG');


         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_DISPOSITION_MAIL;

   PROCEDURE RC_INV_TRANS_NOTIFY_MAIL
   IS
      g_error_msg        VARCHAR2 (2000);
      lv_msg_from        VARCHAR2 (500);
      lv_msg_to          VARCHAR2 (500);
      lv_msg_subject     VARCHAR2 (32767);
      lv_msg_text        VARCHAR2 (32767);
      lv_lro_msg_text    VARCHAR2 (32767);
      lv_fve_msg_text    VARCHAR2 (32767);
      lv_dgi_msg_text    VARCHAR2 (32767);
      lv_trn_msg_text    VARCHAR2 (32767);
      lv_output_hdr      CLOB;
      lv_count           NUMBER := 0;
      lv_output          CLOB;
      lv_database_name   VARCHAR2 (50);
      lv_filename        VARCHAR2 (5000);
      lv_start_time      VARCHAR2 (100);
      lv_request_ids     VARCHAR2 (300);
      lv_count_col       NUMBER := 0;
      lv_addon_link      VARCHAR2 (30);
   BEGIN
      lv_msg_from := 'remarketing-it@cisco.com';
      lv_msg_to := 'satbanda@cisco.com';         --i_created_by||'@cisco.com';

      SELECT ora_database_name INTO lv_database_name FROM DUAL;

      IF (lv_database_name = 'FNTR2PRD.CISCO.COM')
      THEN
         lv_msg_subject := NULL;
         lv_addon_link := NULL;
         -- lv_mail_notify:='INV_TRANSFER_ADJ_NOTIFY';
         lv_msg_to :=
               lv_msg_to
            || ','
            || 'refresh_inventory_admin@cisco.com'
            || ','
            || 'remarketing-it@cisco.com';
      ELSIF (lv_database_name = 'FNTR2STG.CISCO.COM')
      THEN
         lv_msg_subject := 'STAGE : ';
         lv_addon_link := '-stg';
         -- lv_mail_notify:='STAGE_NOTIFICATIONS';
         lv_msg_to :=
               lv_msg_to
            || ','
            || 'refreshcentral-support@cisco.com'
            || ','
            || 'satbanda@cisco.com'
            || ','
            || 'krseelam@cisco.com';
      ELSE
         lv_msg_subject := 'DEV : ';
         lv_addon_link := '-dev';
         -- lv_mail_notify:= 'DEV_NOTIFICATIONS';
         lv_msg_to :=
               lv_msg_to
            || ','
            || 'refreshcentral-support@cisco.com'
            || ','
            || 'krseelam@cisco.com';
      END IF;

      -- lv_msg_to:= 'satbanda@cisco.com';

      lv_msg_subject :=
         lv_msg_subject || 'BTS Inventory Transfer/Adjustment requests';

      lv_msg_text :=
            '<HTML>'
         || '<br /><br /> '
         || 'Inventory Transfer/Adjustments Requests given below.'
         || '<br /><br /> '
         || ' <head>
                <style>
                table {
                    font-family: arial, sans-serif;
                    border-collapse: collapse;
                    width: 100%;
                }

                td, th {
                    border: 1px solid black;
                    text-align: left;
                    padding: 8px;
                }
                </style>
                </head>
                <body>
                <table>
                     <tr>
                    <th>Request ID</th><th>Refresh ID</th><th>Transaction Type</th><th>Location</th><th>ROHS Compliant</th><th>Qty Requested</th><th>Qty Approved</th><th>Requested By</th><th>Requested Date</th><th>Processed By</th><th>Processed Date</th><th>Status</th><th>Requestor Comments</th><th>Approver Comments</th></tr>';


      lv_count_col := 0;

      lv_lro_msg_text := lv_msg_text;

      FOR rec
         IN (  SELECT *
                 FROM rmktgadm.rmk_adminui_invtransfer
                WHERE     site_code = 'LRO'
                      AND transaction_type = 'ADJUSTMENT'
                      AND (   approved_date IS NULL
                           OR approved_date >= SYSDATE - (1 / 24))
             ORDER BY process_status DESC, requested_date DESC, requested_by)
      LOOP
         IF MOD (lv_count_col, 2) = 0
         THEN
            lv_lro_msg_text :=
               lv_lro_msg_text || '<tr style="background-color: #dddddd">';
         ELSE
            lv_lro_msg_text := lv_lro_msg_text || '<tr>';
         END IF;

         lv_lro_msg_text :=
               lv_lro_msg_text
            || '
                        <td>'
            || rec.REQUEST_ID
            || '</td><td nowrap>'
            || rec.PART_NUMBER
            || '</td><td nowrap>'
            || rec.TRANSACTION_TYPE
            || '-'
            || rec.FROM_PROGRAM_TYPE
            || '</td><td>'
            || rec.SITE_CODE
            || '</td><td>'
            || rec.ROHS_COMPLIANT_FLAG
            || '</td><td>'
            || rec.QTY_TO_TRANSFER
            || '</td><td>'
            || rec.QTY_TO_PROCESS
            || '</td><td nowrap>'
            || rec.REQUESTED_BY
            || '</td><td nowrap>'
            || TO_CHAR (rec.REQUESTED_DATE, 'DD-Mon-YYYY HH:Mi:SS')
            || '</td><td nowrap>'
            || rec.APPROVED_BY
            || '</td><td nowrap>'
            || TO_CHAR (rec.APPROVED_DATE, 'DD-Mon-YYYY HH:Mi:SS')
            || '</td><td>'
            || rec.APROVAL_STATUS
            || '</td><td nowrap>'
            || rec.COMMENTS
            || '</td><td nowrap>'
            || rec.APPROVER_COMMENTS
            || '</td></tr>';


         lv_count_col := lv_count_col + 1;
      END LOOP;


      lv_lro_msg_text := lv_lro_msg_text || '</table> </body> </html>';

      IF lv_count_col > 0
      THEN
         BEGIN
            crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (
               lv_msg_from,
               lv_msg_to,
               lv_msg_subject,
               lv_lro_msg_text,
               NULL,                                            --lv_filename,
               NULL                                                --lv_output
                   );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_message := SUBSTR (SQLERRM, 1, 50);
         END;
      END IF;

      lv_count_col := 0;

      lv_fve_msg_text := lv_msg_text;

      FOR rec
         IN (  SELECT *
                 FROM rmktgadm.rmk_adminui_invtransfer
                WHERE     site_code = 'FVE'
                      AND transaction_type = 'ADJUSTMENT'
                      AND (   approved_date IS NULL
                           OR approved_date >= SYSDATE - (1 / 24))
             ORDER BY process_status DESC, requested_date DESC, requested_by)
      LOOP
         IF MOD (lv_count_col, 2) = 0
         THEN
            lv_fve_msg_text :=
               lv_fve_msg_text || '<tr style="background-color: #dddddd">';
         ELSE
            lv_fve_msg_text := lv_fve_msg_text || '<tr>';
         END IF;

         lv_fve_msg_text :=
               lv_fve_msg_text
            || '
                        <td>'
            || rec.REQUEST_ID
            || '</td><td nowrap>'
            || rec.PART_NUMBER
            || '</td><td nowrap>'
            || rec.TRANSACTION_TYPE
            || '-'
            || rec.FROM_PROGRAM_TYPE
            || '</td><td>'
            || rec.SITE_CODE
            || '</td><td>'
            || rec.ROHS_COMPLIANT_FLAG
            || '</td><td>'
            || rec.QTY_TO_TRANSFER
            || '</td><td>'
            || rec.QTY_TO_PROCESS
            || '</td><td nowrap>'
            || rec.REQUESTED_BY
            || '</td><td nowrap>'
            || TO_CHAR (rec.REQUESTED_DATE, 'DD-Mon-YYYY HH:Mi:SS')
            || '</td><td nowrap>'
            || rec.APPROVED_BY
            || '</td><td nowrap>'
            || TO_CHAR (rec.APPROVED_DATE, 'DD-Mon-YYYY HH:Mi:SS')
            || '</td><td>'
            || rec.APROVAL_STATUS
            || '</td><td nowrap>'
            || rec.COMMENTS
            || '</td><td nowrap>'
            || rec.APPROVER_COMMENTS
            || '</td></tr>';


         lv_count_col := lv_count_col + 1;
      END LOOP;


      lv_fve_msg_text := lv_fve_msg_text || '</table> </body> </html>';

      IF lv_count_col > 0
      THEN
         BEGIN
            crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (
               lv_msg_from,
               lv_msg_to,
               lv_msg_subject,
               lv_fve_msg_text,
               NULL,                                            --lv_filename,
               NULL                                                --lv_output
                   );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_message := SUBSTR (SQLERRM, 1, 50);
         END;
      END IF;

      lv_count_col := 0;

      lv_dgi_msg_text := lv_msg_text;

      FOR rec
         IN (  SELECT *
                 FROM rmktgadm.rmk_adminui_invtransfer
                WHERE     site_code = 'GDGI'
                      AND transaction_type = 'ADJUSTMENT'
                      AND (   approved_date IS NULL
                           OR approved_date >= SYSDATE - (1 / 24))
             ORDER BY process_status DESC, requested_date DESC, requested_by)
      LOOP
         IF MOD (lv_count_col, 2) = 0
         THEN
            lv_dgi_msg_text :=
               lv_dgi_msg_text || '<tr style="background-color: #dddddd">';
         ELSE
            lv_dgi_msg_text := lv_dgi_msg_text || '<tr>';
         END IF;

         lv_dgi_msg_text :=
               lv_dgi_msg_text
            || '
                        <td>'
            || rec.REQUEST_ID
            || '</td><td nowrap>'
            || rec.PART_NUMBER
            || '</td><td nowrap>'
            || rec.TRANSACTION_TYPE
            || '-'
            || rec.FROM_PROGRAM_TYPE
            || '</td><td>'
            || rec.SITE_CODE
            || '</td><td>'
            || rec.ROHS_COMPLIANT_FLAG
            || '</td><td>'
            || rec.QTY_TO_TRANSFER
            || '</td><td>'
            || rec.QTY_TO_PROCESS
            || '</td><td nowrap>'
            || rec.REQUESTED_BY
            || '</td><td nowrap>'
            || TO_CHAR (rec.REQUESTED_DATE, 'DD-Mon-YYYY HH:Mi:SS')
            || '</td><td nowrap>'
            || rec.APPROVED_BY
            || '</td><td nowrap>'
            || TO_CHAR (rec.APPROVED_DATE, 'DD-Mon-YYYY HH:Mi:SS')
            || '</td><td>'
            || rec.APROVAL_STATUS
            || '</td><td nowrap>'
            || rec.COMMENTS
            || '</td><td nowrap>'
            || rec.APPROVER_COMMENTS
            || '</td></tr>';


         lv_count_col := lv_count_col + 1;
      END LOOP;


      lv_dgi_msg_text := lv_dgi_msg_text || '</table> </body> </html>';

      IF lv_count_col > 0
      THEN
         BEGIN
            crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (
               lv_msg_from,
               lv_msg_to,
               lv_msg_subject,
               lv_dgi_msg_text,
               NULL,                                            --lv_filename,
               NULL                                                --lv_output
                   );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_message := SUBSTR (SQLERRM, 1, 50);
         END;
      END IF;

      lv_count_col := 0;

      lv_trn_msg_text := lv_msg_text;

      FOR rec
         IN (  SELECT *
                 FROM rmktgadm.rmk_adminui_invtransfer
                WHERE     transaction_type != 'ADJUSTMENT'
                      AND (   approved_date IS NULL
                           OR approved_date >= SYSDATE - (1 / 24))
             ORDER BY process_status DESC, requested_date DESC, requested_by)
      LOOP
         IF MOD (lv_count_col, 2) = 0
         THEN
            lv_trn_msg_text :=
               lv_trn_msg_text || '<tr style="background-color: #dddddd">';
         ELSE
            lv_trn_msg_text := lv_trn_msg_text || '<tr>';
         END IF;

         lv_trn_msg_text :=
               lv_trn_msg_text
            || '
                        <td>'
            || rec.REQUEST_ID
            || '</td><td nowrap>'
            || rec.PART_NUMBER
            || '</td><td nowrap>'
            || rec.TRANSACTION_TYPE
            || '</td><td>'
            || rec.SITE_CODE
            || '</td><td>'
            || rec.ROHS_COMPLIANT_FLAG
            || '</td><td>'
            || rec.QTY_TO_TRANSFER
            || '</td><td>'
            || rec.QTY_TO_PROCESS
            || '</td><td nowrap>'
            || rec.REQUESTED_BY
            || '</td><td nowrap>'
            || TO_CHAR (rec.REQUESTED_DATE, 'DD-Mon-YYYY HH:Mi:SS')
            || '</td><td nowrap>'
            || rec.APPROVED_BY
            || '</td><td nowrap>'
            || TO_CHAR (rec.APPROVED_DATE, 'DD-Mon-YYYY HH:Mi:SS')
            || '</td><td>'
            || rec.APROVAL_STATUS
            || '</td><td nowrap>'
            || rec.COMMENTS
            || '</td><td nowrap>'
            || rec.APPROVER_COMMENTS
            || '</td></tr>';


         lv_count_col := lv_count_col + 1;
      END LOOP;


      lv_trn_msg_text := lv_trn_msg_text || '</table> </body> </html>';

      IF lv_count_col > 0
      THEN
         BEGIN
            crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (
               lv_msg_from,
               lv_msg_to,
               lv_msg_subject,
               lv_trn_msg_text,
               NULL,                                            --lv_filename,
               NULL                                                --lv_output
                   );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_message := SUBSTR (SQLERRM, 1, 50);
         END;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO CRPADM.RC_CRON_HISTORY_LOG (CHL_ID,
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
                      'RC_INV_TRANS_NOTIFY_MAIL',
                      v_message,
                      'RC_INV_UTIL_REPORT_PKG');


         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_TRANS_NOTIFY_MAIL;

   --Commented by satbanda for new changes on 3rd october while calculating move to Z05 <Start>
   /* FUNCTION GET_Z05_MOV_VALUE    (NON_EU_B      NUMBER,
                                  EU_B          NUMBER,
                                  LRO_B         NUMBER,
                                  FG_Z29_Z26    NUMBER,
                                  FVE_FGI       NUMBER,
                                  FG_Z05        NUMBER,
                                  LRO_FGI       NUMBER)
   RETURN VARCHAR2
    AS
       ln_fg_z05_val       NUMBER := 0;
       l_fg_z05_move_val   VARCHAR2 (200) := NULL;
    BEGIN
       IF NVL (NON_EU_B, 0) > 0
       THEN
          ln_fg_z05_val := 0;

          IF NVL (FG_Z05, 0) + NVL (LRO_FGI, 0) >= NVL (NON_EU_B, 0)
          THEN
             ln_fg_z05_val := 0;
          ELSIF     NVL (FG_Z05, 0) + NVL (LRO_FGI, 0) < NVL (NON_EU_B, 0)
                AND NVL (FG_Z29_Z26, 0) > 0
          THEN
             ln_fg_z05_val :=
                FLOOR (
                     NVL (FG_Z29_Z26, 0)
                   * (NVL (NON_EU_B, 0) - (NVL (FG_Z05, 0) + NVL (LRO_FGI, 0)))
                   / (  NVL (NON_EU_B, 0)
                      + NVL (EU_B, 0)
                      - (NVL (FG_Z05, 0) + NVL (LRO_FGI, 0))));

             ln_fg_z05_val := LEAST (NON_EU_B - NVL (FG_Z05, 0) - NVL (LRO_FGI, 0), ln_fg_z05_val);
          ELSE
             ln_fg_z05_val := 0;
          END IF;
       ELSE
          l_fg_z05_move_val := 'NA';
       END IF;

       IF l_fg_z05_move_val IS NULL
       THEN
          l_fg_z05_move_val := TO_CHAR (ln_fg_z05_val);
       END IF;

       RETURN l_fg_z05_move_val;
    EXCEPTION
       WHEN OTHERS
       THEN
          l_fg_z05_move_val := 'ERROR';
          RETURN l_fg_z05_move_val;
    END GET_Z05_MOV_VALUE; */

   --Added by satbanda for new changes on 3rd october while calculating move to Z05 <End>

   --Added by satbanda for new changes on 3rd october while calculating move to Z05 <Start>
   FUNCTION GET_Z05_MOV_VALUE (NON_EU_B      NUMBER,
                               NON_EU_D      NUMBER,
                               EU_B          NUMBER,
                               EU_D          NUMBER,
                               LRO_B         NUMBER,
                               DG_Z29_Z26    NUMBER,
                               FVE_FGI       NUMBER,
                               DG_Z05        NUMBER,
                               LRO_FGI       NUMBER)
      RETURN VARCHAR2
   AS
      ln_fg_z05_val       NUMBER := 0;
      ln_fg_z05_Dval      NUMBER := 0;
      l_fg_z05_move_val   VARCHAR2 (2000) := NULL;
      lv_calc_mov_flag    VARCHAR2 (10) := 'Y';
      ln_dg_z05           NUMBER := 0;
      ln_dg_z29_z26       NUMBER := 0;
      ln_lro_fgi          NUMBER := 0;
      ln_non_eu_d         NUMBER := 0;
      ln_eu_d             NUMBER := 0;
   BEGIN
      IF NVL (NON_EU_B, 0) > 0
      THEN
         ln_fg_z05_val := 0;

         IF NVL (DG_Z05, 0) + NVL (LRO_FGI, 0) >= NVL (NON_EU_B, 0)
         THEN
            ln_fg_z05_val := 0;
         ELSIF     NVL (DG_Z05, 0) + NVL (LRO_FGI, 0) < NVL (NON_EU_B, 0)
               AND NVL (DG_Z29_Z26, 0) > 0
         THEN
            ln_fg_z05_val :=
               FLOOR (
                    NVL (DG_Z29_Z26, 0)
                  * (NVL (NON_EU_B, 0) - (NVL (DG_Z05, 0) + NVL (LRO_FGI, 0)))
                  / (  NVL (NON_EU_B, 0)
                     + NVL (EU_B, 0)
                     - (NVL (DG_Z05, 0) + NVL (LRO_FGI, 0))));

            ln_fg_z05_val :=
               LEAST (NON_EU_B - NVL (DG_Z05, 0) - NVL (LRO_FGI, 0),
                      ln_fg_z05_val);
         ELSE
            ln_fg_z05_val := 0;
         END IF;
      ELSIF NVL (NON_EU_D, 0) <= 0
      THEN
         l_fg_z05_move_val := 'NA';
      END IF;

      --
      IF (l_fg_z05_move_val = 'NA' OR NVL (NON_EU_D, 0) <= 0)
      THEN
         lv_calc_mov_flag := 'N';
      ELSIF ln_fg_z05_val > 0
      THEN
         IF ln_fg_z05_val <=
               NVL (non_eu_b, 0) - (NVL (dg_z05, 0) + NVL (lro_fgi, 0))
         THEN
            ln_dg_z29_z26 := dg_z29_z26 - ln_fg_z05_val;
            ln_dg_z05 := 0;
            ln_lro_fgi := 0;

            IF    ln_dg_z29_z26 <= 0
               OR (ln_fg_z05_val <
                        NVL (non_eu_b, 0)
                      - (NVL (dg_z05, 0) + NVL (lro_fgi, 0)))
            THEN
               lv_calc_mov_flag := 'N';
            ELSE
               lv_calc_mov_flag := 'Y';
               ln_non_eu_d := NVL (non_eu_d, 0) - NVL (non_eu_b, 0);
               ln_eu_d := NVL (eu_d, 0) - NVL (eu_b, 0);
            END IF;
         END IF;
      ELSIF ln_fg_z05_val = 0
      THEN
         ln_dg_z29_z26 := dg_z29_z26;


         IF NVL (dg_z05, 0) >= NVL (non_eu_b, 0)
         THEN
            ln_dg_z05 := NVL (dg_z05, 0) - NVL (non_eu_b, 0);

            ln_lro_fgi := NVL (lro_fgi, 0);
         ELSE
            ln_dg_z05 := 0;

            ln_lro_fgi :=
               NVL (lro_fgi, 0) + NVL (dg_z05, 0) - NVL (non_eu_b, 0);
         END IF;


         IF ln_dg_z29_z26 <= 0 AND ln_dg_z05 = 0 AND ln_lro_fgi = 0
         THEN
            lv_calc_mov_flag := 'N';
         ELSE
            lv_calc_mov_flag := 'Y';
            ln_non_eu_d := NVL (non_eu_d, 0) - NVL (non_eu_b, 0);
            ln_eu_d := NVL (eu_d, 0) - NVL (eu_b, 0);
         END IF;

         IF NVL (ln_dg_z05, 0) + NVL (ln_lro_fgi, 0) >= ln_non_eu_d
         THEN
            lv_calc_mov_flag := 'N';
         END IF;
      ELSE
         lv_calc_mov_flag := 'N';
         l_fg_z05_move_val := 'NA';
      END IF;

      IF ln_eu_d < 0
      THEN
         ln_eu_d := 0;
      END IF;

      IF lv_calc_mov_flag = 'Y' AND ln_non_eu_d > 0
      THEN
         ln_fg_z05_Dval := 0;

         IF ln_dg_z05 + ln_lro_fgi >= ln_non_eu_d
         THEN
            ln_fg_z05_Dval := 0;
         ELSIF ln_dg_z05 + ln_lro_fgi < ln_non_eu_d AND ln_dg_z29_z26 > 0
         THEN
            ln_fg_z05_Dval :=
               FLOOR (
                    ln_dg_z29_z26
                  * (ln_non_eu_d - (ln_dg_z05 + ln_lro_fgi))
                  / (ln_non_eu_d + ln_eu_d - (ln_dg_z05 + ln_lro_fgi)));

            ln_fg_z05_Dval :=
               LEAST (ln_non_eu_d - ln_dg_z05 - ln_lro_fgi, ln_fg_z05_Dval);
         ELSE
            ln_fg_z05_Dval := 0;
         END IF;
      END IF;



      IF NVL (l_fg_z05_move_val, '*') <> 'NA'
      THEN
         l_fg_z05_move_val := TO_CHAR (ln_fg_z05_val + ln_fg_z05_Dval);
      END IF;

      RETURN l_fg_z05_move_val;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_fg_z05_move_val :=
               SUBSTR (SQLERRM, 1, 100)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         RETURN l_fg_z05_move_val;
   END GET_Z05_MOV_VALUE;

   --Added by satbanda for new changes on 3rd october while calculating move to Z05 <End>

   --Added by satbanda for new changes on 6th october while calculating GDGI Bucket <Start>

   FUNCTION fn_get_alldgi_inv (i_user_id        VARCHAR2,
                               i_site_code      VARCHAR2, --comma seperated values if input is multiple sites
                               i_part_number    VARCHAR2,
                               i_yield_flag     VARCHAR2 DEFAULT 'N')
      RETURN VARCHAR2
   AS
      ln_dgi_qty      NUMBER := 0;
      lv_err_msg      VARCHAR2 (400);
      lv_part_num     VARCHAR2 (400);
      lv_site_code    VARCHAR2 (40);
      ld_start_time   DATE;
   BEGIN
      ld_start_time := SYSDATE;
      lv_site_code := UPPER (TRIM (i_site_code));
      lv_part_num := UPPER (TRIM (i_part_number));

      BEGIN
         IF UPPER (TRIM (i_yield_flag)) = 'N'
         THEN
              SELECT SUM (
                        NVL (
                           DECODE (
                              sub.udc_1,
                              'Y', SUM (
                                        c3.qty_in_trans_usebl
                                      + c3.qty_on_hand_usebl),
                              SUM (c3.qty_on_hand_usebl)),
                           0))
                INTO ln_dgi_qty
                FROM crpadm.rc_inv_c3_tbl         c3,
                     rmktgadm.rmk_inv_site_mappings map,
                     (SELECT pm.*,
                             (SELECT pc.config_name
                                FROM crpadm.rc_product_config pc
                               WHERE     pc.config_type = 'REFRESH_METHOD'
                                     AND (SELECT MIN (refresh_method_id)
                                            FROM crpadm.rc_product_repair_setup
                                                 irs
                                           WHERE     irs.refresh_inventory_item_id =
                                                        ANY (pm.refresh_inventory_item_id,
                                                             pm.xref_inventory_item_id)
                                                 AND irs.refresh_status =
                                                        'ACTIVE') =
                                            pc.config_id)
                                refurb_method
                        FROM crpadm.rc_product_master pm) rpm,
                     crpadm.rc_sub_inv_loc_mstr   sub
               WHERE     map.site_code = SUBSTR (c3.place_id, 1, 3)
                     AND c3.location = sub.sub_inventory_location
                     AND rpm.refresh_part_number = lv_part_num    --c3.part_id
                     AND c3.part_id =
                            ANY (rpm.refresh_part_number,
                                 rpm.xref_part_number,
                                 rpm.common_part_number)
                     AND map.inv_type = 'DGI'
                     AND map.rohs_site = 'YES'
                     AND map.status = 'ACTIVE'
                     AND (   (    rpm.refurb_method = 'REPAIR'
                              AND c3.LOCATION
                                      MEMBER OF crpadm.rc_get_subinventory_locations (
                                                  5,
                                                  DECODE (rpm.program_type,
                                                          0, 'RF_POE',
                                                          'WS_POE'),
                                                  'ALL',
                                                  1))
                          OR (    rpm.refurb_method = 'TEST'
                              AND c3.LOCATION
                                      MEMBER OF crpadm.rc_get_subinventory_locations (
                                                  6,
                                                  DECODE (rpm.program_type,
                                                          0, 'RF_POE',
                                                          'WS_POE'),
                                                  'ALL',
                                                  1))
                          OR (    rpm.refurb_method = 'SCREEN'
                              AND c3.LOCATION
                                      MEMBER OF crpadm.rc_get_subinventory_locations (
                                                  3,
                                                  DECODE (rpm.program_type,
                                                          0, 'RF_POE',
                                                          'WS_POE'),
                                                  'ALL',
                                                  1))
                          OR DECODE (rpm.program_type,
                                     0, sub.sub_inventory_location,
                                     '1') =
                                DECODE (rpm.program_type, 0, 'POE-LT', '2'))
                     AND rpm.program_type IN (0, 1)
                     --AND UPPER(c3.PART_ID) = lv_part_num
                     AND SUB.inventory_type <> 0                        -- FGI
                     AND SUB.Program_type IN (0, 1, 2) -- (0) Retail (1) Excess (2) POE
                     AND map.site_code IN
                            (    SELECT REGEXP_SUBSTR (lv_site_code,
                                                       '[^,]+',
                                                       1,
                                                       LEVEL)
                                   FROM DUAL
                             CONNECT BY REGEXP_SUBSTR (lv_site_code,
                                                       '[^,]+',
                                                       1,
                                                       LEVEL)
                                           IS NOT NULL)
            GROUP BY c3.part_id, sub.udc_1;
         ELSIF UPPER (TRIM (i_yield_flag)) = 'Y'
         THEN
              SELECT SUM (
                          NVL (
                             DECODE (
                                sub.udc_1,
                                'Y', SUM (
                                          c3.qty_in_trans_usebl
                                        + c3.qty_on_hand_usebl),
                                SUM (c3.qty_on_hand_usebl)),
                             0)
                        * NVL (refresh_yield, 0)
                        / 100)
                INTO ln_dgi_qty
                FROM crpadm.rc_inv_c3_tbl           c3,
                     rmktgadm.rmk_inv_site_mappings map,
                     (SELECT pm.*,
                             (SELECT pc.config_id
                                FROM crpadm.rc_product_config pc
                               WHERE     pc.config_type = 'REFRESH_METHOD'
                                     AND (SELECT MIN (refresh_method_id)
                                            FROM crpadm.rc_product_repair_setup
                                                 irs
                                           WHERE     irs.refresh_inventory_item_id =
                                                        ANY (pm.refresh_inventory_item_id,
                                                             pm.xref_inventory_item_id)
                                                 AND irs.refresh_status =
                                                        'ACTIVE') =
                                            pc.config_id)
                                refurb_method_id,
                             (SELECT pc.config_name
                                FROM crpadm.rc_product_config pc
                               WHERE     pc.config_type = 'REFRESH_METHOD'
                                     AND (SELECT MIN (refresh_method_id)
                                            FROM crpadm.rc_product_repair_setup
                                                 irs
                                           WHERE     irs.refresh_inventory_item_id =
                                                        pm.refresh_inventory_item_id
                                                 AND irs.refresh_status =
                                                        'ACTIVE') =
                                            pc.config_id)
                                refurb_method
                        FROM crpadm.rc_product_master pm) rpm,
                     crpadm.rc_sub_inv_loc_mstr     sub,
                     crpadm.rc_product_repair_setup rs,
                     crpadm.rc_product_repair_partner rp
               WHERE     map.site_code = SUBSTR (c3.place_id, 1, 3)
                     AND c3.location = sub.sub_inventory_location
                     AND rpm.refresh_part_number = lv_part_num    --c3.part_id
                     AND c3.part_id =
                            ANY (rpm.refresh_part_number,
                                 rpm.xref_part_number,
                                 rpm.common_part_number)
                     AND rpm.refresh_inventory_item_id =
                            rs.refresh_inventory_item_id
                     AND rs.repair_partner_id = rp.repair_partner_id
                     AND rp.active_flag = 'Y'
                     AND rs.theater_id =
                            DECODE (map.region,  'NAM', 1,  'EMEA', 3)
                     AND rp.zcode = map.site_code
                     AND rs.refresh_status = 'ACTIVE'
                     AND rs.refresh_method_id = rpm.refurb_method_id
                     AND rp.program_type = rpm.program_type
                     AND map.inv_type = 'DGI'
                     AND map.rohs_site = 'YES'
                     AND map.status = 'ACTIVE'
                     AND (   (    rpm.refurb_method = 'REPAIR'
                              AND c3.LOCATION
                                      MEMBER OF crpadm.rc_get_subinventory_locations (
                                                  5,
                                                  DECODE (rpm.program_type,
                                                          0, 'RF_POE',
                                                          'WS_POE'),
                                                  'ALL',
                                                  1))
                          OR (    rpm.refurb_method = 'TEST'
                              AND c3.LOCATION
                                      MEMBER OF crpadm.rc_get_subinventory_locations (
                                                  6,
                                                  DECODE (rpm.program_type,
                                                          0, 'RF_POE',
                                                          'WS_POE'),
                                                  'ALL',
                                                  1))
                          OR (    rpm.refurb_method = 'SCREEN'
                              AND c3.LOCATION
                                      MEMBER OF crpadm.rc_get_subinventory_locations (
                                                  3,
                                                  DECODE (rpm.program_type,
                                                          0, 'RF_POE',
                                                          'WS_POE'),
                                                  'ALL',
                                                  1))
                          OR DECODE (rpm.program_type,
                                     0, sub.sub_inventory_location,
                                     '1') =
                                DECODE (rpm.program_type, 0, 'POE-LT', '2'))
                     AND rpm.program_type IN (0, 1)
                     --  AND UPPER(c3.PART_ID) = lv_part_num
                     AND SUB.inventory_type <> 0                        -- FGI
                     AND SUB.Program_type IN (0, 1, 2) -- (0) Retail (1) Excess (2) POE
                     AND map.site_code IN
                            (    SELECT REGEXP_SUBSTR (lv_site_code,
                                                       '[^,]+',
                                                       1,
                                                       LEVEL)
                                   FROM DUAL
                             CONNECT BY REGEXP_SUBSTR (lv_site_code,
                                                       '[^,]+',
                                                       1,
                                                       LEVEL)
                                           IS NOT NULL)
            GROUP BY c3.part_id, sub.udc_1, refresh_yield;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            ln_dgi_qty := 0;
         WHEN OTHERS
         THEN
            lv_err_msg := 'Error Getting :' || SUBSTR (SQLERRM, 1, 200);

            INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                   CHL_STATUS,
                                                   CHL_START_TIMESTAMP,
                                                   CHL_END_TIMESTAMP,
                                                   CHL_CRON_NAME,
                                                   CHL_COMMENTS,
                                                   CHL_CREATED_BY)
                 VALUES (SEQ_CHL_ID.NEXTVAL,
                         'FAILED',
                         ld_start_time,
                         SYSDATE,
                         'FN_GET_ALLDGI_INV',
                         i_part_number || '-' || lv_err_msg,
                         i_user_id);


            COMMIT;
            RAISE_APPLICATION_ERROR (-20000, SQLERRM);
            ln_dgi_qty := 0;
      END;

      RETURN ln_dgi_qty;
   EXCEPTION
      WHEN OTHERS
      THEN
         lv_err_msg := 'Error Getting :' || SUBSTR (SQLERRM, 1, 200);

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'FAILED',
                      ld_start_time,
                      SYSDATE,
                      'FN_GET_ALLDGI_INV',
                      i_part_number || '-' || lv_err_msg,
                      i_user_id);


         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
         ln_dgi_qty := 0;
         RETURN ln_dgi_qty;
   END fn_get_alldgi_inv;

   --Added by satbanda for new changes on 6th october while calculating GDGI Bucket <End>

   /*
  ****************************************************************************************************************
  * Object Name       :RC_INV_PID_ASSIGN_EXCEPTN_RPT
  ===================================================================================================+
  * Date         Modified by     Enhancement/Case #
  ===================================================================================================+
    30-Oct-2019  ramaanan         US356239

    Description:
    procedure RC_INV_PID_ASSIGN_EXCEPTN_RPT is obsolete and is replaced by INV_PID_ASSIGN_EXCEPTN_RPT_V2.
    INV_PID_ASSIGN_EXCEPTN_RPT_V2 is executed by a JAR executed by TES job.

  ===================================================================================================+
 */

   PROCEDURE RC_INV_PID_ASSIGN_EXCEPTN_RPT
   IS
      g_error_msg        VARCHAR2 (2000);
      lv_msg_from        VARCHAR2 (500) := 'remarketing-it@cisco.com';
      lv_msg_to          VARCHAR2 (500);
      lv_msg_subject     VARCHAR2 (32767);
      lv_msg_text        VARCHAR2 (32767);
      lv_output_hdr      CLOB;
      lv_mailhost        VARCHAR2 (100) := 'outbound.cisco.com';
      lv_conn            UTL_SMTP.CONNECTION;
      lv_message_type    VARCHAR2 (100) := 'text/html; charset="iso-8859-1"';
      lv_crlf            VARCHAR2 (5) := CHR (13) || CHR (10);
      lv_count           NUMBER := 0;
      lv_output          CLOB;
      lv_database_name   VARCHAR2 (50);
      lv_filename        VARCHAR2 (100);
      lv_start_time      VARCHAR2 (50);
      l_start_time       VARCHAR2 (50);

      /* Start 27-Feb-2018 added RC_INV_ORG_ASSIGNMNT_EXCEPTION as part of R12 upgrade by sridvasu */

      CURSOR PID_EXCEPTION_DATA
      IS
         SELECT *
           FROM (SELECT common_part_number part_number, 'Z05' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        AND NVL (common_inventory_item_id, 0) <> 0
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.common_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = 'Z05')
                 UNION
                 SELECT xref_part_number part_number, 'Z05' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        AND NVL (xref_inventory_item_id, 0) <> 0
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.xref_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = 'Z05')
                 UNION
                 --below query to verify if the assignment exists for Z32 site
                 SELECT common_part_number part_number, 'Z32' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        AND NVL (common_inventory_item_id, 0) <> 0
                        AND common_part_number NOT LIKE '40%.%' -- ADDED TO FIX INVALID PARTS COMING UP FOR Z32
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.common_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = 'Z32')
                 UNION
                 SELECT xref_part_number part_number, 'Z32' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        AND NVL (xref_inventory_item_id, 0) <> 0
                        AND xref_part_number NOT LIKE '40%.%' -- ADDED TO FIX INVALID PARTS COMING UP FOR Z32
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.xref_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = 'Z32')
                 UNION
                 --below query to verify if the assignment exists for Z29 site
                 SELECT common_part_number part_number, 'Z29' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NVL (common_inventory_item_id, 0) <> 0
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.common_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = 'Z29')
                 UNION
                 SELECT xref_part_number part_number, 'Z29' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        AND NVL (xref_inventory_item_id, 0) <> 0
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.xref_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = 'Z29')
                 /* Start Added as part of US156757 by sridvasu on 01-Feb-2018 */
                 UNION
                 --below query to verify if the assignment exists for 0ZU site
                 SELECT common_part_number part_number, '0ZU' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NVL (common_inventory_item_id, 0) <> 0
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.common_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = '0ZU')
                 UNION
                 SELECT xref_part_number part_number, '0ZU' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        AND NVL (xref_inventory_item_id, 0) <> 0
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.xref_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = '0ZU')
                 UNION
                 --below query to verify if the assignment exists for 0ZB site
                 SELECT common_part_number part_number, '0ZB' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NVL (common_inventory_item_id, 0) <> 0
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.common_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = '0ZB')
                 UNION
                 SELECT xref_part_number part_number, '0ZB' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        AND NVL (xref_inventory_item_id, 0) <> 0
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.xref_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = '0ZB')
                 /* End Added as part of US156757 by sridvasu on 01-Feb-2018 */
                 UNION
                 --when refresh pid exists, then check whether Refresh PID org assignment for all applicable re-mfg site
                 SELECT rpm.refresh_part_number, zcode
                   FROM RC_PRODUCT_REPAIR_SETUP   setup,
                        RC_PRODUCT_REPAIR_PARTNER partner,
                        rc_product_master         rpm
                  WHERE     setup.repair_partner_id =
                               partner.repair_partner_id
                        AND setup.refresh_status <> 'DEACTIVATED' -->> Added as part of US156757 by sridvasu
                        AND rpm.refresh_life_cycle_id NOT IN (6)
                        AND rpm.refresh_inventory_item_id =
                               setup.refresh_inventory_item_id
                        --and partner.zcode not in ('Z05', 'Z29')
                        AND partner.zcode NOT IN ('Z13') --- NOT TO PULL Z13 ORG AS IT IS NOT AN ACTIVE REFRESH ORG
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     setup.refresh_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code =
                                              partner.zcode)
                 UNION
                 --when refresh pid exists, then check whether mfg pid org assignment for all applicable re-mfg site
                 SELECT common_part_number, zcode
                   FROM RC_PRODUCT_REPAIR_SETUP   setup,
                        RC_PRODUCT_REPAIR_PARTNER partner,
                        RC_PRODUCT_MASTER         rpm
                  WHERE     setup.repair_partner_id =
                               partner.repair_partner_id
                        AND setup.refresh_status <> 'DEACTIVATED' -->> Added as part of US156757 by sridvasu
                        AND rpm.refresh_inventory_item_id =
                               setup.refresh_inventory_item_id
                        AND rpm.refresh_life_cycle_id NOT IN (6)
                        --and partner.zcode not in ('Z05', 'Z29')
                        AND partner.zcode NOT IN ('Z13') --- NOT TO PULL Z13 ORG AS IT IS NOT AN ACTIVE REFRESH ORG
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     rpm.common_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code =
                                              partner.zcode)
                 UNION
                 --when refresh pid exists, then check whether service(xref) pid org assignment for all applicable re-mfg site
                 SELECT xref_part_number, zcode
                   FROM RC_PRODUCT_REPAIR_SETUP   setup,
                        RC_PRODUCT_REPAIR_PARTNER partner,
                        RC_PRODUCT_MASTER         rpm
                  WHERE     setup.repair_partner_id =
                               partner.repair_partner_id
                        AND setup.refresh_status <> 'DEACTIVATED' -->> Added as part of US156757 by sridvasu
                        AND rpm.refresh_inventory_item_id =
                               setup.refresh_inventory_item_id
                        AND rpm.refresh_life_cycle_id NOT IN (6)
                        --and partner.zcode not in ('Z05', 'Z29')
                        AND partner.zcode NOT IN ('Z13') --- NOT TO PULL Z13 ORG AS IT IS NOT AN ACTIVE REFRESH ORG
                        AND rpm.xref_inventory_item_id IS NOT NULL
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     rpm.xref_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code =
                                              partner.zcode)
                 --(start) added by hkarka as part of US156757 on 15-FEB-2018
                 UNION
                 --when refresh pid exists, then check whether Refresh PID org assignment for all applicable re-mfg site
                 SELECT rpm.refresh_part_number,
                        DECODE (partner.zcode,  'Z05', '0ZU',  'Z29', '0ZB')
                   FROM RC_PRODUCT_REPAIR_SETUP   setup,
                        RC_PRODUCT_REPAIR_PARTNER partner,
                        rc_product_master         rpm
                  WHERE     setup.repair_partner_id =
                               partner.repair_partner_id
                        AND setup.refresh_status <> 'DEACTIVATED' -->> Added as part of US156757 by sridvasu
                        AND rpm.refresh_life_cycle_id NOT IN (6)
                        AND rpm.refresh_inventory_item_id =
                               setup.refresh_inventory_item_id
                        AND partner.zcode IN ('Z05', 'Z29')
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     org.organization_code =
                                              DECODE (partner.zcode,
                                                      'Z05', '0ZU',
                                                      'Z29', '0ZB')
                                       --and msib.enabled_flag = 'Y'
                                       AND setup.refresh_inventory_item_id =
                                              org.inventory_item_id)
                 --(end) added by hkarka as part of US156757 on 15-FEB-2018
                 /* End Added as part of US156757 by sridvasu on 01-Feb-2018 */
                 UNION                    /* 04-JUL-2018 Code changes start */
                 SELECT product_name part_number, 'Z05' site_code
                   FROM rc_fin_demand_list mv
                  WHERE     1 = 1
                        -- AND include_or_exclude = 'INCLUDE'
                        --AND NVL(common_inventory_item_id, 0) <> 0
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM rc_inv_org_assignmnt_exception org
                                 WHERE     org.part_number = mv.product_name
                                       AND org.organization_code = 'Z05')
                 UNION
                 --Below query to verify if the assignment exists for Z32 site
                 SELECT product_name part_number, 'Z32' site_code
                   FROM rc_fin_demand_list mv
                  WHERE     1 = 1
                        --AND include_or_exclude = 'INCLUDE'
                        AND product_name NOT LIKE '40%.%' -- ADDED TO FIX INVALID PARTS COMING UP FOR Z32
                        --AND NVL(common_inventory_item_id, 0) <> 0
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM rc_inv_org_assignmnt_exception org
                                 WHERE     org.part_number = mv.product_name
                                       AND org.organization_code = 'Z32')
                 UNION
                 --Below query to verify if the assignment exists for Z29 site
                 SELECT product_name part_number, 'Z29' site_code
                   FROM rc_fin_demand_list mv
                  WHERE     1 = 1
                        -- AND include_or_exclude = 'INCLUDE'
                        --AND NVL(common_inventory_item_id, 0) <> 0
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM rc_inv_org_assignmnt_exception org
                                 WHERE     org.part_number = mv.product_name
                                       AND org.organization_code = 'Z29')
                 UNION
                 --Below query to verify if the assignment exists for 0ZU site
                 SELECT product_name part_number, '0ZU' site_code
                   FROM rc_fin_demand_list mv
                  WHERE     1 = 1
                        --AND include_or_exclude = 'INCLUDE'
                        --AND NVL(common_inventory_item_id, 0) <> 0
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM rc_inv_org_assignmnt_exception org
                                 WHERE     org.part_number = mv.product_name
                                       AND org.organization_code = '0ZU')
                 UNION
                 --Below query to verify if the assignment exists for 0ZB site
                 SELECT product_name part_number, '0ZB' site_code
                   FROM rc_fin_demand_list mv
                  WHERE     1 = 1
                        --AND include_or_exclude = 'INCLUDE'
                        --AND NVL(common_inventory_item_id, 0) <> 0
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM rc_inv_org_assignmnt_exception org
                                 WHERE     org.part_number = mv.product_name
                                       AND org.organization_code = '0ZB') /* 04-JUL-2018 Code changes End */
                                                                         )
          WHERE part_number IS NOT NULL;


      /* End 27-Feb-2018 added RC_INV_ORG_ASSIGNMNT_EXCEPTION as part of R12 upgrade by sridvasu */

      RC_INV_PID_DATA    PID_EXCEPTION_DATA%ROWTYPE;
   BEGIN
      SELECT ora_database_name INTO lv_database_name FROM DUAL;

      SELECT TO_CHAR (SYSDATE, 'MM/DD/YYYY HH:MI:SS PM')
        INTO lv_start_time
        FROM DUAL;

      SELECT TO_CHAR (SYSDATE, 'MM/DD/YYYY HH.MI.SS PM')
        INTO l_start_time
        FROM DUAL;

      -- lv_msg_from := 'refreshcentral-support@cisco.com';

      lv_filename := 'Org Assignment Exception Report_' || l_start_time;

      lv_msg_subject :=
         ' Org Assignment Exception Report - ' || lv_start_time;

      IF (ora_database_name = 'FNTR2DEV.CISCO.COM')
      THEN
         lv_msg_subject := 'DEV : ' || lv_msg_subject;
         lv_msg_to :=
            'mohamms2@cisco.com, refreshcentral-support@cisco.com, csirigir@cisco.com';
      ELSIF (ora_database_name = 'FNTR2STG.CISCO.COM')
      THEN
         lv_msg_subject := 'STAGE : ' || lv_msg_subject;
         -- lv_msg_to := 'mohamms2@cisco.com, refreshcentral-support@cisco.com, csirigir@cisco.com';
         lv_msg_to := 'ramaanan@cisco.com, shashred@cisco.com';
      ELSE
         lv_msg_subject := lv_msg_subject;
         lv_msg_to :=
            'refreshcentral-support@cisco.com, refresh_inventory_admin@cisco.com';
      END IF;


      lv_msg_text :=
            '<HTML> Hi Team,'
         || '<br />'
         || '<br />'
         || 'Please find attached PIDs missing organization assignments.'
         || '<br /><br />'
         || 'PLEASE DO NOT REPLY... This is an Auto generated Email.'
         || '<br /><br /> '
         || 'Thanks,'
         || '<br />'
         || 'Refresh Central Support team </HTML>';


      lv_output_hdr :=
         'Part Number' || ',' || 'Missing Location' || UTL_TCP.crlf;

      lv_count := 0;

      FOR rec IN PID_EXCEPTION_DATA
      LOOP
         IF lv_count = 0
         THEN
            lv_output :=
                  lv_output_hdr
               || rec.part_number
               || ','
               || rec.site_code
               || ','
               || UTL_TCP.crlf;
         ELSE
            lv_output :=
                  lv_output
               || rec.part_number
               || ','
               || rec.site_code
               || ','
               || UTL_TCP.crlf;
         END IF;

         lv_count := lv_count + 1;
      END LOOP;

      RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (lv_msg_from,
                                                    lv_msg_to,
                                                    lv_msg_subject,
                                                    lv_msg_text,
                                                    lv_filename,
                                                    lv_output);

      INSERT INTO CRPADM.RC_CRON_HISTORY_LOG (CHL_ID,
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
                   'RC_INV_PID_ASSIGN_EXCEPTN_RPT',             --G_PROC_NAME,
                   NULL,
                   'RC_INV_UTIL_REPORT_PKG');

      COMMIT;
   -- G_PROC_NAME := 'RC_INV_RF_DGI_HISTORY';
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO CRPADM.RC_CRON_HISTORY_LOG (CHL_ID,
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
                      'RC_INV_PID_ASSIGN_EXCEPTN_RPT',          --G_PROC_NAME,
                      G_ERROR_MSG,
                      'RC_INV_UTIL_REPORT_PKG');

         --   G_PROC_NAME := 'RC_INV_RF_DGI_HISTORY';

         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END RC_INV_PID_ASSIGN_EXCEPTN_RPT;

   /*
    ****************************************************************************************************************
    * Object Name       :INV_PID_ASSIGN_EXCEPTN_RPT_V2
    ===================================================================================================+
    * Date         Modified by     Enhancement/Case #
    ===================================================================================================+
      30-Oct-2019  ramaanan         US356239

      Description:

      INV_PID_ASSIGN_EXCEPTN_RPT_V2 is executed by a JAR executed by TES job.
      procedure will fetch latest org assignment report and put data into following tables:
      ORG_EXCEPTON_REC_LAST_RUN - delete old + this run
      ORG_EXCEPTON_REC_FAILED_API - delete old + mail (not present in history)
      ORG_EXCEPTON_REC_HISTORY - this run + old run
      mail - common in ORG_EXCEPTON_REC_LAST_RUN + ORG_EXCEPTON_REC_HISTORY

    ===================================================================================================+
   */

   PROCEDURE INV_PID_ASSIGN_EXCEPTN_RPT_V2 (STATUS OUT VARCHAR2)
   IS
      g_error_msg                 VARCHAR2 (2000);
      lv_msg_from                 VARCHAR2 (500) := 'remarketing-it@cisco.com';
      lv_msg_to                   VARCHAR2 (500);
      lv_msg_subject              VARCHAR2 (32767);
      lv_msg_text                 VARCHAR2 (32767);
      lv_output_hdr               CLOB;
      lv_mailhost                 VARCHAR2 (100) := 'outbound.cisco.com';
      lv_conn                     UTL_SMTP.CONNECTION;
      lv_message_type             VARCHAR2 (100) := 'text/html; charset="iso-8859-1"';
      lv_crlf                     VARCHAR2 (5) := CHR (13) || CHR (10);
      lv_count                    NUMBER := 0;
      lv_output                   CLOB;
      lv_output_two               CLOB;
      lv_database_name            VARCHAR2 (50);
      lv_filename                 VARCHAR2 (100);
      lv_filename_two             VARCHAR2 (100);
      lv_start_time               VARCHAR2 (50);
      l_start_time                VARCHAR2 (50);
      is_present                  NUMBER := 0;
      isFailed                    NUMBER := 0;
      pid_status                  VARCHAR2 (255);
      first_run                   NUMBER := 0;
      part_number_already_found   NUMBER := 0;

      /* Start 27-Feb-2018 added RC_INV_ORG_ASSIGNMNT_EXCEPTION as part of R12 upgrade by sridvasu */

      CURSOR PID_EXCEPTION_DATA
      IS
         SELECT *
           FROM (SELECT common_part_number part_number, 'Z05' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        AND NVL (common_inventory_item_id, 0) <> 0
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.common_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = 'Z05')
                 UNION
                 SELECT xref_part_number part_number, 'Z05' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        AND NVL (xref_inventory_item_id, 0) <> 0
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.xref_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = 'Z05')
                 UNION
                 --below query to verify if the assignment exists for Z32 site
                 SELECT common_part_number part_number, 'Z32' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        AND NVL (common_inventory_item_id, 0) <> 0
                        AND common_part_number NOT LIKE '40%.%' -- ADDED TO FIX INVALID PARTS COMING UP FOR Z32
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.common_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = 'Z32')
                 UNION
                 SELECT xref_part_number part_number, 'Z32' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        AND NVL (xref_inventory_item_id, 0) <> 0
                        AND xref_part_number NOT LIKE '40%.%' -- ADDED TO FIX INVALID PARTS COMING UP FOR Z32
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.xref_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = 'Z32')
                 UNION
                 --below query to verify if the assignment exists for Z29 site
                 SELECT common_part_number part_number, 'Z29' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NVL (common_inventory_item_id, 0) <> 0
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.common_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = 'Z29')
                 UNION
                 SELECT xref_part_number part_number, 'Z29' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        AND NVL (xref_inventory_item_id, 0) <> 0
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.xref_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = 'Z29')
                 /* Start Added as part of US156757 by sridvasu on 01-Feb-2018 */
                 UNION
                 --below query to verify if the assignment exists for 0ZU site
                 SELECT common_part_number part_number, '0ZU' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NVL (common_inventory_item_id, 0) <> 0
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.common_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = '0ZU')
                 UNION
                 SELECT xref_part_number part_number, '0ZU' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        AND NVL (xref_inventory_item_id, 0) <> 0
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.xref_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = '0ZU')
                 UNION
                 --below query to verify if the assignment exists for 0ZB site
                 SELECT common_part_number part_number, '0ZB' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NVL (common_inventory_item_id, 0) <> 0
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.common_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = '0ZB')
                 UNION
                 SELECT xref_part_number part_number, '0ZB' site_code
                   FROM crprep.RC_SCRAP_REPORT mv
                  WHERE     1 = 1
                        AND NVL (xref_inventory_item_id, 0) <> 0
                        --and part_number not in (select refresh_part_number from rc_product_master)
                        --and part_number not like '%RF'
                        --and part_number not like '%WS'
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     mv.xref_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code = '0ZB')
                 /* End Added as part of US156757 by sridvasu on 01-Feb-2018 */
                 UNION
                 --when refresh pid exists, then check whether Refresh PID org assignment for all applicable re-mfg site
                 SELECT rpm.refresh_part_number, zcode
                   FROM RC_PRODUCT_REPAIR_SETUP   setup,
                        RC_PRODUCT_REPAIR_PARTNER partner,
                        rc_product_master         rpm
                  WHERE     setup.repair_partner_id =
                               partner.repair_partner_id
                        AND setup.refresh_status <> 'DEACTIVATED' -->> Added as part of US156757 by sridvasu
                        AND rpm.refresh_life_cycle_id NOT IN (6)
                        AND rpm.refresh_inventory_item_id =
                               setup.refresh_inventory_item_id
                        --and partner.zcode not in ('Z05', 'Z29')
                        AND partner.zcode NOT IN ('Z13') --- NOT TO PULL Z13 ORG AS IT IS NOT AN ACTIVE REFRESH ORG
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     setup.refresh_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code =
                                              partner.zcode)
                 UNION
                 --when refresh pid exists, then check whether mfg pid org assignment for all applicable re-mfg site
                 SELECT common_part_number, zcode
                   FROM RC_PRODUCT_REPAIR_SETUP   setup,
                        RC_PRODUCT_REPAIR_PARTNER partner,
                        RC_PRODUCT_MASTER         rpm
                  WHERE     setup.repair_partner_id =
                               partner.repair_partner_id
                        AND setup.refresh_status <> 'DEACTIVATED' -->> Added as part of US156757 by sridvasu
                        AND rpm.refresh_inventory_item_id =
                               setup.refresh_inventory_item_id
                        AND rpm.refresh_life_cycle_id NOT IN (6)
                        --and partner.zcode not in ('Z05', 'Z29')
                        AND partner.zcode NOT IN ('Z13') --- NOT TO PULL Z13 ORG AS IT IS NOT AN ACTIVE REFRESH ORG
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     rpm.common_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code =
                                              partner.zcode)
                 UNION
                 --when refresh pid exists, then check whether service(xref) pid org assignment for all applicable re-mfg site
                 SELECT xref_part_number, zcode
                   FROM RC_PRODUCT_REPAIR_SETUP   setup,
                        RC_PRODUCT_REPAIR_PARTNER partner,
                        RC_PRODUCT_MASTER         rpm
                  WHERE     setup.repair_partner_id =
                               partner.repair_partner_id
                        AND setup.refresh_status <> 'DEACTIVATED' -->> Added as part of US156757 by sridvasu
                        AND rpm.refresh_inventory_item_id =
                               setup.refresh_inventory_item_id
                        AND rpm.refresh_life_cycle_id NOT IN (6)
                        --and partner.zcode not in ('Z05', 'Z29')
                        AND partner.zcode NOT IN ('Z13') --- NOT TO PULL Z13 ORG AS IT IS NOT AN ACTIVE REFRESH ORG
                        AND rpm.xref_inventory_item_id IS NOT NULL
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     rpm.xref_inventory_item_id =
                                              org.inventory_item_id
                                       AND org.organization_code =
                                              partner.zcode)
                 --(start) added by hkarka as part of US156757 on 15-FEB-2018
                 UNION
                 --when refresh pid exists, then check whether Refresh PID org assignment for all applicable re-mfg site
                 SELECT rpm.refresh_part_number,
                        DECODE (partner.zcode,  'Z05', '0ZU',  'Z29', '0ZB')
                   FROM RC_PRODUCT_REPAIR_SETUP   setup,
                        RC_PRODUCT_REPAIR_PARTNER partner,
                        rc_product_master         rpm
                  WHERE     setup.repair_partner_id =
                               partner.repair_partner_id
                        AND setup.refresh_status <> 'DEACTIVATED' -->> Added as part of US156757 by sridvasu
                        AND rpm.refresh_life_cycle_id NOT IN (6)
                        AND rpm.refresh_inventory_item_id =
                               setup.refresh_inventory_item_id
                        AND partner.zcode IN ('Z05', 'Z29')
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM RC_INV_ORG_ASSIGNMNT_EXCEPTION org
                                 WHERE     org.organization_code =
                                              DECODE (partner.zcode,
                                                      'Z05', '0ZU',
                                                      'Z29', '0ZB')
                                       --and msib.enabled_flag = 'Y'
                                       AND setup.refresh_inventory_item_id =
                                              org.inventory_item_id)
                 --(end) added by hkarka as part of US156757 on 15-FEB-2018
                 /* End Added as part of US156757 by sridvasu on 01-Feb-2018 */
                 UNION                    /* 04-JUL-2018 Code changes start */
                 SELECT product_name part_number, 'Z05' site_code
                   FROM rc_fin_demand_list mv
                  WHERE     1 = 1
                        -- AND include_or_exclude = 'INCLUDE'
                        --AND NVL(common_inventory_item_id, 0) <> 0
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM rc_inv_org_assignmnt_exception org
                                 WHERE     org.part_number = mv.product_name
                                       AND org.organization_code = 'Z05')
                 UNION
                 --Below query to verify if the assignment exists for Z32 site
                 SELECT product_name part_number, 'Z32' site_code
                   FROM rc_fin_demand_list mv
                  WHERE     1 = 1
                        --AND include_or_exclude = 'INCLUDE'
                        AND product_name NOT LIKE '40%.%' -- ADDED TO FIX INVALID PARTS COMING UP FOR Z32
                        --AND NVL(common_inventory_item_id, 0) <> 0
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM rc_inv_org_assignmnt_exception org
                                 WHERE     org.part_number = mv.product_name
                                       AND org.organization_code = 'Z32')
                 UNION
                 --Below query to verify if the assignment exists for Z29 site
                 SELECT product_name part_number, 'Z29' site_code
                   FROM rc_fin_demand_list mv
                  WHERE     1 = 1
                        -- AND include_or_exclude = 'INCLUDE'
                        --AND NVL(common_inventory_item_id, 0) <> 0
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM rc_inv_org_assignmnt_exception org
                                 WHERE     org.part_number = mv.product_name
                                       AND org.organization_code = 'Z29')
                 UNION
                 --Below query to verify if the assignment exists for 0ZU site
                 SELECT product_name part_number, '0ZU' site_code
                   FROM rc_fin_demand_list mv
                  WHERE     1 = 1
                        --AND include_or_exclude = 'INCLUDE'
                        --AND NVL(common_inventory_item_id, 0) <> 0
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM rc_inv_org_assignmnt_exception org
                                 WHERE     org.part_number = mv.product_name
                                       AND org.organization_code = '0ZU')
                 UNION
                 --Below query to verify if the assignment exists for 0ZB site
                 SELECT product_name part_number, '0ZB' site_code
                   FROM rc_fin_demand_list mv
                  WHERE     1 = 1
                        --AND include_or_exclude = 'INCLUDE'
                        --AND NVL(common_inventory_item_id, 0) <> 0
                        AND NOT EXISTS
                               (SELECT 1
                                  FROM rc_inv_org_assignmnt_exception org
                                 WHERE     org.part_number = mv.product_name
                                       AND org.organization_code = '0ZB') /* 04-JUL-2018 Code changes End */
                                                                         )
          WHERE part_number IS NOT NULL;


      /* End 27-Feb-2018 added RC_INV_ORG_ASSIGNMNT_EXCEPTION as part of R12 upgrade by sridvasu */

      RC_INV_PID_DATA             PID_EXCEPTION_DATA%ROWTYPE;
   BEGIN
      STATUS := 'SUCCESS';

      DELETE ORG_EXCEPTON_REC_FAILED_API;

      --check if first run then no need to send FAILED API attachment
      SELECT COUNT (*) INTO first_run FROM ORG_EXCEPTON_REC_HISTORY;

      DELETE ORG_EXCEPTON_REC_LAST_RUN;

      FOR rec IN PID_EXCEPTION_DATA
      LOOP
         INSERT INTO ORG_EXCEPTON_REC_LAST_RUN (PART_NUMBER,
                                                MISSING_LOCATION,
                                                STATUS,
                                                INVENTORY_ITEM_ID)
                 VALUES (
                           rec.part_number,
                           rec.site_code,
                           'LATEST RUN',
                           (SELECT RC_UTILITY.GET_INVENTORY_ITEM_ID_V2 (
                                                      rec.part_number)
                                              FROM DUAL));

         COMMIT;
      END LOOP;

      COMMIT;
      lv_output_hdr :=
         'Part Number' || ',' || 'Missing Location' || UTL_TCP.crlf;

      FOR rec IN PID_EXCEPTION_DATA
      LOOP
         --if record found in history do not place into FAILED API table to prepare mail
         SELECT COUNT (*)
           INTO part_number_already_found
           FROM CRPADM.ORG_EXCEPTON_REC_HISTORY
          WHERE     PART_NUMBER = rec.part_number
                AND MISSING_LOCATION = rec.site_code;

         IF part_number_already_found = 0
         THEN
            INSERT
              INTO ORG_EXCEPTON_REC_FAILED_API (PART_NUMBER,
                                                MISSING_LOCATION,
                                                INVENTORY_ITEM_ID)
               VALUES (
                         rec.part_number,
                         rec.site_code,
                         (SELECT RC_UTILITY.GET_INVENTORY_ITEM_ID_V2 (
                                    rec.part_number)
                            FROM DUAL));
         END IF;

         IF part_number_already_found > 0
         THEN
            IF lv_count = 0
            THEN
               lv_output_two :=
                     lv_output_hdr
                  || rec.part_number
                  || ','
                  || rec.site_code
                  || ','
                  || UTL_TCP.crlf;
            ELSE
               lv_output_two :=
                     lv_output_two
                  || rec.part_number
                  || ','
                  || rec.site_code
                  || ','
                  || UTL_TCP.crlf;
            END IF;

            lv_count := lv_count + 1;
         END IF;

         INSERT
           INTO CRPADM.ORG_EXCEPTON_REC_HISTORY (PART_NUMBER,
                                                 MISSING_LOCATION,
                                                 STATUS)
            VALUES (
                      rec.part_number,
                      rec.site_code,
                      'FOUND UNASSIGNED ON - ' || SYSDATE);

         COMMIT;
      END LOOP;

      lv_count := 0;


      --sending email with 2 attachments (latest PID org assignment report and Failed API call report)
      SELECT ora_database_name INTO lv_database_name FROM DUAL;

      SELECT TO_CHAR (SYSDATE, 'MM/DD/YYYY HH:MI:SS PM')
        INTO lv_start_time
        FROM DUAL;

      SELECT TO_CHAR (SYSDATE, 'MM/DD/YYYY HH.MI.SS PM')
        INTO l_start_time
        FROM DUAL;

      -- lv_msg_from := 'refreshcentral-support@cisco.com';

      lv_filename := 'Org Assignment Exception Report_' || l_start_time;
      lv_filename_two :=
         'API Failed PIDs Org Assignment Report_' || l_start_time;

      lv_msg_subject :=
         ' Org Assignment Exception Report - ' || lv_start_time;

      IF (ora_database_name = 'FNTR2DEV.CISCO.COM')
      THEN
         lv_msg_subject := 'DEV : ' || lv_msg_subject;
         lv_msg_to :=
            'mohamms2@cisco.com, refreshcentral-support@cisco.com, csirigir@cisco.com';
      ELSIF (ora_database_name = 'FNTR2STG.CISCO.COM')
      THEN
         lv_msg_subject := 'STAGE : ' || lv_msg_subject;
         lv_msg_to :=
            'mohamms2@cisco.com, refreshcentral-support@cisco.com, csirigir@cisco.com';
      ELSE
         lv_msg_subject := lv_msg_subject;
         lv_msg_to :=
            'refreshcentral-support@cisco.com, refresh_inventory_admin@cisco.com';
      END IF;


      lv_msg_text :=
            '<HTML> Hi Team,'
         || '<br />'
         || '<br />'
         || 'Please find attached PIDs missing organization assignments.'
         || '<br /><br />'
         || 'PLEASE DO NOT REPLY... This is an Auto generated Email.'
         || '<br /><br />'
         || 'Find attached latest Org assignment report and failed API call report.'
         || '<br /><br /> '
         || 'Thanks,'
         || '<br />'
         || 'Refresh Central Support team </HTML>';


      lv_output_hdr :=
         'Part Number' || ',' || 'Missing Location' || UTL_TCP.crlf;

      FOR rec IN (SELECT *
                    FROM ORG_EXCEPTON_REC_LAST_RUN)
      LOOP
         IF lv_count = 0
         THEN
            lv_output :=
                  lv_output_hdr
               || rec.part_number
               || ','
               || rec.missing_location
               || ','
               || UTL_TCP.crlf;
         ELSE
            lv_output :=
                  lv_output
               || rec.part_number
               || ','
               || rec.missing_location
               || ','
               || UTL_TCP.crlf;
         END IF;

         lv_count := lv_count + 1;
      END LOOP;

      RC_INV_UTIL_GENERIC_MAIL.RC_GENERIC_MAIL_TWO_ATCHMNT (lv_msg_from,
                                                            lv_msg_to,
                                                            lv_msg_subject,
                                                            lv_msg_text,
                                                            lv_filename,
                                                            lv_filename_two,
                                                            lv_output,
                                                            lv_output_two);

      INSERT INTO CRPADM.RC_CRON_HISTORY_LOG (CHL_ID,
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
                   'INV_PID_ASSIGN_EXCEPTN_RPT_V2',             --G_PROC_NAME,
                   NULL,
                   'RC_INV_UTIL_REPORT_PKG');

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         STATUS := 'FAILED';
         ROLLBACK;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO CRPADM.RC_CRON_HISTORY_LOG (CHL_ID,
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
                      'INV_PID_ASSIGN_EXCEPTN_RPT_V2',          --G_PROC_NAME,
                      G_ERROR_MSG,
                      'RC_INV_UTIL_REPORT_PKG');

         --   G_PROC_NAME := 'RC_INV_RF_DGI_HISTORY';

         COMMIT;
         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
   END INV_PID_ASSIGN_EXCEPTN_RPT_V2;
END RC_INV_UTIL_REPORT_PKG;
/