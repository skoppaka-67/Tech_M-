CREATE OR REPLACE PACKAGE BODY RMKTGADM."RC_INV_INTRANS_SHIPMENTS"
AS
   G_START_TIME   DATE;

   /*
  ****************************************************************************************************************
  * Object Name       :RC_INV_INTRANS_SHIPMENTS
  *  Project Name : Refresh Central
   * Copy Rights:   Cisco Systems, INC., CALIFORNIA
  * Description       : This API for Inventory Adjustment reconcialiation
  * Created Date: 2nd May, 2017
  ===================================================================================================+
  * Version              Date                     Modified by                     Description
  ===================================================================================================+
   1.0                   07th Nov, 2017            sridvasu                     Created for Intransit Shipments Report.
   1.1                   16th Nov, 2017            sridvasu                     Added update stmt to set DAYS_PENDING,,WAYBILL_AIRBILL_NUM and REPORT_RUN_DATE column in P_RC_INV_INTRANS_SHIPMTS_LOAD
   1.2                   14th Feb 2018             sridvasu                     Added new procedure for email notification and log entries
   2.0                   21st Mar. 2018            sridvasu                     Created new procedure to send email for Aged Orders
   2.1                   18th Apr 2018             sridvasu                     Modification in P_RC_INTRANS_AGED_ORDERS_MAIL
   2.2                   24th Jun 2020             jhegdeka                     US198778 - Modification in procedures P_RC_INV_INTRANS_SHIPMTS_LOAD, P_RC_INV_INTRANS_SHIP_LOAD_UI
                                                                                 and P_RC_INV_FROM_TO_ORG_SUBINV to include and return data for SONS Orders
  ===================================================================================================+
   **************************************************************************************************************** */

   PROCEDURE P_RC_ERROR_LOG (i_Module_Name        VARCHAR2,
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
   END P_RC_ERROR_LOG;

   -->> Added new procedure for email notification on 14 Feb 2018 by sridvasu

   PROCEDURE RC_INV_MAIN
   AS
      lv_cron_status           VARCHAR2 (50);
      lv_subject               VARCHAR2 (150);
      lv_msg_content           VARCHAR2 (600);
      lv_database_name         VARCHAR2 (300);
      lv_mail_to               VARCHAR2 (100);
      lv_dev_mail_receipents   VARCHAR2 (100);
      lv_stg_mail_receipents   VARCHAR2 (100);
      lv_prd_mail_receipents   VARCHAR2 (100);
      lv_msg_body              VARCHAR2 (300);
      lv_mail_sender           VARCHAR2 (100);
      lv_mail_from             VARCHAR2 (100);
      lv_pkg_name              VARCHAR2 (100)
                                  := 'RMKTGADM.RC_INV_INTRANS_SHIPMENTS';
      lv_error_msg             VARCHAR2 (800);
   BEGIN
      BEGIN
         SELECT CRON_STATUS
           INTO lv_cron_status
           FROM RMKTGADM.CRON_CONTROL_INFO
          WHERE     1 = 1
                AND CRON_NAME = 'P_RC_INV_INTRANS_SHIPMTS_LOAD'
                AND CRON_CONTACT_ID = 'INTRANS_SHIPMTS';
      EXCEPTION
         WHEN OTHERS
         THEN
            lv_error_msg :=
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
      END;


      BEGIN
         SELECT ORA_DATABASE_NAME INTO lv_database_name FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            lv_error_msg :=
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
      END;

      lv_subject :=
         'Warning - ' || lv_pkg_name || '  package Warning message';


      IF (ORA_DATABASE_NAME = 'FNTR2PRD.CISCO.COM')
      THEN
         BEGIN
            SELECT EMAIL_SENDER, EMAIL_RECIPIENTS
              INTO lv_mail_sender, lv_dev_mail_receipents
              FROM CRPADM.RC_EMAIL_NOTIFICATIONS
             WHERE NOTIFICATION_NAME = 'RC_INV_INTRANS_SHIPMENT_ALERT_PRD';
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_error_msg :=
                     SUBSTR (SQLERRM, 1, 200)
                  || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         END;

         lv_mail_from := lv_mail_sender;
         lv_subject := lv_subject;
         lv_mail_to := lv_dev_mail_receipents;
      ELSIF (ORA_DATABASE_NAME = 'FNTR2STG.CISCO.COM')
      THEN
         BEGIN
            SELECT EMAIL_SENDER, EMAIL_RECIPIENTS
              INTO lv_mail_sender, lv_stg_mail_receipents
              FROM CRPADM.RC_EMAIL_NOTIFICATIONS
             WHERE NOTIFICATION_NAME = 'RC_INV_INTRANS_SHIPMENT_ALERT_STG';
         EXCEPTION
            WHEN OTHERS
            THEN
               LV_ERROR_MSG :=
                     SUBSTR (SQLERRM, 1, 200)
                  || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         END;

         lv_mail_from := lv_mail_sender;
         lv_subject := 'STAGE : ' || lv_subject;
         lv_mail_to := lv_stg_mail_receipents;
      ELSIF (ORA_DATABASE_NAME = 'FNTR2DEV.CISCO.COM')
      THEN
         BEGIN
            SELECT EMAIL_SENDER, EMAIL_RECIPIENTS
              INTO lv_mail_sender, lv_prd_mail_receipents
              FROM CRPADM.RC_EMAIL_NOTIFICATIONS
             WHERE NOTIFICATION_NAME = 'RC_INV_INTRANS_SHIPMENT_ALERT_DEV';
         EXCEPTION
            WHEN OTHERS
            THEN
               LV_ERROR_MSG :=
                     SUBSTR (SQLERRM, 1, 200)
                  || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         END;

         lv_mail_from := lv_mail_sender;
         lv_subject := 'DEV : ' || lv_subject;
         lv_mail_to := lv_prd_mail_receipents;
      END IF;

      lv_msg_body :=
         '<HTML> In Transit Shipments Report is currently running. Please wait to run it again. <HTML/>';

      lv_msg_content :=
            '<HTML>Hello,<br /><br /> Warning Message from <b> '
         || SUBSTR (lv_pkg_name, 1, 37)
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


      IF lv_cron_status = 'STARTED'
      THEN
         CRPADM.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (LV_MAIL_FROM,
                                                              LV_MAIL_TO,
                                                              LV_SUBJECT,
                                                              LV_MSG_CONTENT,
                                                              NULL,
                                                              NULL);
      ELSIF lv_cron_status = 'SUCCESS'
      THEN
         P_RC_INV_INTRANS_SHIPMTS_LOAD;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := SUBSTR (SQLERRM, 1, 200);

         P_RC_ERROR_LOG (
            I_module_name       => 'RC_INV_MAIN',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while loading intransit shipments UI table '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => 'RC_INV_INTRANS_SHIPMENTS',
            I_updated_by        => 'RC_INV_INTRANS_SHIPMENTS');
   END RC_INV_MAIN;

   PROCEDURE P_RC_INV_INTRANS_SHIPMTS_LOAD
   AS
      CURSOR INTRANS_SHIP
      IS
         SELECT *
           FROM RC_INV_INTRANSIT_SHIPMENTS
          WHERE STATUS_FLAG = 'Y';

      CURSOR FREIGHT_CONFIG
      IS
         SELECT * FROM RC_INV_FREIGHT_CARRIER_CONFIG;

      lv_count             NUMBER;
      --US198778 New Code Added
      lv_count_sons        NUMBER;
      lv_seq_id            NUMBER;
      lv_order_type_ir     VARCHAR2 (5) := 'IR';
      lv_order_type_sons   VARCHAR2 (5) := 'SONS';

      --      TYPE t_from_subinventory_obj IS RECORD
      --      (
      --      original_subinventory VARCHAR(30),
      --      inventory_item_id NUMBER,
      --      source_header_number VARCHAR2(450)
      --      );
      --
      --      TYPE t_from_subinventory_list IS TABLE OF t_from_subinventory_obj;
      --      t_from_subinventory_rec t_from_subinventory_list;
      --US198778 New Code End

      INTRANS_REC          INTRANS_SHIP%ROWTYPE;
   BEGIN
      SELECT SYSDATE INTO G_START_TIME FROM DUAL;

      -->> Start entry into control table added on 14 Feb 2018 by sridvasu

      --US198778 New Code Start
      SELECT cron_start_timestamp
        INTO v_start_date
        FROM RMKTGADM.CRON_CONTROL_INFO
       WHERE     CRON_NAME = 'P_RC_INV_INTRANS_SHIPMTS_LOAD'
             AND CRON_CONTACT_ID = 'INTRANS_SHIPMTS';

      --US198778 New Code End

      UPDATE RMKTGADM.CRON_CONTROL_INFO
         SET CRON_STATUS = 'STARTED', CRON_START_TIMESTAMP = SYSDATE
       WHERE     CRON_NAME = 'P_RC_INV_INTRANS_SHIPMTS_LOAD'
             AND CRON_CONTACT_ID = 'INTRANS_SHIPMTS';

      COMMIT;

      SELECT COUNT (1)
        INTO lv_count
        FROM RC_INV_INTRANS_SHIPMTS_STG
       WHERE STATUS_FLAG = 'Y';


      IF lv_count > 0
      THEN
         UPDATE RC_INV_INTRANSIT_SHIPMENTS
            SET STATUS_FLAG = 'N'
          WHERE STATUS_FLAG = 'Y' AND ORDER_TYPE = lv_order_type_ir; --US198778 New Code Added

         COMMIT;

         --US198778 New Code Start
         --         SELECT DISTINCT original_subinventory, inventory_item_id, source_header_number
         --         BULK COLLECT INTO t_from_subinventory_rec
         --         FROM APPS.WSH_DELIVERY_DETAILS@CSFPRD_DBL.CISCO.COM
         --         WHERE source_header_number IN (SELECT order_number FROM RC_INV_INTRANS_SHIPMTS_STG);
         --
         --         FORALL idx IN t_from_subinventory_rec.FIRST .. t_from_subinventory_rec.LAST
         --            UPDATE RC_INV_INTRANS_SHIPMTS_STG
         --               SET from_subinventory = t_from_subinventory_rec(idx).original_subinventory
         --             WHERE inventory_item_id = t_from_subinventory_rec(idx).inventory_item_id
         --               AND order_number = t_from_subinventory_rec(idx).source_header_number
         --               AND status_flag = 'Y';
         --         --US198778 New Code End

         INSERT INTO RC_INV_INTRANSIT_SHIPMENTS (SEQ_ID,
                                                 INVENTORY_ITEM_ID,
                                                 PART_NUMBER,
                                                 ORDER_NUMBER,
                                                 SHIPMENT_NUMBER,
                                                 WAYBILL_AIRBILL_NUM,
                                                 ADDITIONAL_SHIPMENT_INFO,
                                                 FROM_ORGANIZATION_ID,
                                                 FROM_ORG,
                                                 TO_ORGANIZATION_ID,
                                                 TO_ORG,
                                                 TO_SUBINVENTORY,
                                                 SHIP_TO_LOCATION_ID,
                                                 FREIGHT_CARRIER_CODE,
                                                 SHIPPED_DATE,
                                                 EXPECTED_RECEIPT_DATE,
                                                 SHIPPED_QUANTITY,
                                                 RECEIVED_QUANTITY,
                                                 VENDOR_ID,
                                                 STATUS_FLAG,
                                                 PENDING_QTY,
                                                 DAYS_PENDING,
                                                 COMMENTS,
                                                 REPORT_RUN_DATE,
                                                 CREATED_ON,
                                                 CREATED_BY,
                                                 UPDATED_ON,
                                                 UPDATED_BY,
                                                 ATTRIBUTE1,
                                                 ATTRIBUTE2,
                                                 ATTRIBUTE3,
                                                 ATTRIBUTE4,
                                                 ATTRIBUTE5,
                                                 ATTRIBUTE6,
                                                 ATTRIBUTE7,
                                                 ATTRIBUTE8,
                                                 ATTRIBUTE9,
                                                 LINE_NUM,
                                                 FREIGHT_CODE,
                                                 --US198778 New Code Added
                                                 FROM_SUBINVENTORY,
                                                 ORDER_TYPE)
            --US198778 New Code End
            SELECT SEQ_ID,
                   INVENTORY_ITEM_ID,
                   PART_NUMBER,
                   ORDER_NUMBER,
                   SHIPMENT_NUMBER,
                   TRIM (
                      REGEXP_REPLACE (
                         WAYBILL_AIRBILL_NUM,
                         '([[:space:]][[:space:]]+)|([[:cntrl:]]+)',
                         ' '))
                      WAYBILL_AIRBILL_NUM,
                   TRIM (
                      REGEXP_REPLACE (
                         additional_shipment_info,
                         '([[:space:]][[:space:]]+)|([[:cntrl:]]+)',
                         ' '))
                      additional_shipment_info,
                   FROM_ORGANIZATION_ID,
                   FROM_ORG,
                   TO_ORGANIZATION_ID,
                   TO_ORG,
                   TO_SUBINVENTORY,
                   SHIP_TO_LOCATION_ID,
                   FREIGHT_CARRIER_CODE,
                   SHIPPED_DATE,
                   EXPECTED_RECEIPT_DATE,
                   SHIPPED_QUANTITY,
                   RECEIVED_QUANTITY,
                   VENDOR_ID,
                   STATUS_FLAG,
                   PENDING_QTY,
                   DAYS_PENDING,
                   COMMENTS,
                   REPORT_RUN_DATE,
                   CREATED_ON,
                   CREATED_BY,
                   UPDATED_ON,
                   UPDATED_BY,
                   ATTRIBUTE1,
                   ATTRIBUTE2,
                   ATTRIBUTE3,
                   ATTRIBUTE4,
                   ATTRIBUTE5,
                   ATTRIBUTE6,
                   ATTRIBUTE7,
                   ATTRIBUTE8,
                   ATTRIBUTE9,
                   LINE_NUM,
                   FREIGHT_CODE,
                   --US198778 New Code Added
                   FROM_SUBINVENTORY,
                   lv_order_type_ir
              --US198778 New Code End
              FROM RC_INV_INTRANS_SHIPMTS_STG
             WHERE STATUS_FLAG = 'Y';
      END IF;                                        --US198778 New Code Added

      -->> updating DAYS_PENDING,,WAYBILL_AIRBILL_NUM and REPORT_RUN_DATE columns

      /* Start 16th Nov, 2017 Added update stmt to set DAYS_PENDING,,WAYBILL_AIRBILL_NUM and REPORT_RUN_DATE columns */

      UPDATE RC_INV_INTRANSIT_SHIPMENTS
         SET DAYS_PENDING =
                  --US198778 Code Changes Start
                  -- TRUNC (SYSDATE) - TRUNC (EXPECTED_RECEIPT_DATE),
                  (TRUNC (SYSDATE) - TRUNC (shipped_date))
                - 2 * FLOOR ( (TRUNC (SYSDATE) - TRUNC (shipped_date)) / 7)
                - DECODE (
                     SIGN (
                          TO_CHAR (TRUNC (SYSDATE), 'D')
                        - TO_CHAR (TRUNC (shipped_date), 'D')),
                     -1, 2,
                     0)
                - DECODE (TO_CHAR (TRUNC (shipped_date), 'D'), 1, 1, 0),
             --US198778 Code Changes End
             WAYBILL_AIRBILL_NUM = ADDITIONAL_SHIPMENT_INFO
       --WAYBILL_AIRBILL_NUM = NVL(WAYBILL_AIRBILL_NUM,ADDITIONAL_SHIPMENT_INFO)--commented to fix waybill_airbill_num update issue
       WHERE STATUS_FLAG = 'Y' AND ORDER_TYPE = lv_order_type_ir; --US198778 New Code Added

      /* End 16th Nov, 2017 Added update stmt to set DAYS_PENDING,,WAYBILL_AIRBILL_NUM and REPORT_RUN_DATE columns */


      UPDATE rc_inv_intransit_shipments ship
         SET (freight_code, waybill_airbill_num) =
                (SELECT freight_code, waybill_number
                   FROM XXCTS_CARRIER_DETAILS xcs
                  WHERE TO_CHAR (ship.shipment_number) =
                           xcs.r12_shipment_number)
       WHERE     status_flag = 'Y'
             AND Freight_code IS NULL
             AND TRUNC (shipped_date) < '11-MAR-2018'
             AND ORDER_TYPE = lv_order_type_ir;      --US198778 New Code Added

      COMMIT;

      /* Updating aged order column in intransit UI table */


      FOR REC IN FREIGHT_CONFIG
      LOOP
         UPDATE rc_inv_intransit_shipments
            SET AGED_ORDER =
                   (CASE
                       WHEN (    from_org = rec.from_org
                             AND to_org = rec.to_org
                             AND freight_code = rec.freight_carrier
                             AND days_pending > NVL (rec.transit_time_max, 0))
                       THEN
                          'Y'
                       ELSE
                          'N'
                    END)
          WHERE     status_flag = 'Y'
                AND from_org = rec.from_org
                AND to_org = rec.to_org
                AND freight_code = rec.freight_carrier
                AND days_pending > NVL (rec.transit_time_max, 0)
                AND ORDER_TYPE = lv_order_type_ir;   --US198778 New Code Added
      END LOOP;


      UPDATE rc_inv_intransit_shipments
         SET AGED_ORDER = 'N'
       WHERE     AGED_ORDER IS NULL
             AND status_flag = 'Y'
             AND ORDER_TYPE = lv_order_type_ir;      --US198778 New Code Added


      /* Updating MAX INTRANSIT PAD column in intransit UI table */

      UPDATE rc_inv_intransit_shipments ship
         SET max_intransit_pad =
                (SELECT transit_time_max
                   FROM RC_INV_FREIGHT_CARRIER_CONFIG config
                  WHERE     ship.from_org = config.from_org
                        AND ship.to_org = config.to_org
                        AND ship.freight_code = config.freight_carrier)
       WHERE status_flag = 'Y' AND ORDER_TYPE = lv_order_type_ir; --US198778 New Code Added


      /* Updating MAX INTRANSIT PAD default for NL6 to Z05 if waybill is SEA/OCEAN */

      UPDATE rc_inv_intransit_shipments
         SET max_intransit_pad = 50
       WHERE     status_flag = 'Y'
             AND from_org = 'NL6'
             AND to_org = 'Z05'
             AND waybill_airbill_num IN ('SEA', 'OCEAN')
             AND ORDER_TYPE = lv_order_type_ir;      --US198778 New Code Added


      --        update rc_inv_intransit_shipments
      --                  SET AGED_ORDER = 'Y'
      --                   where  status_flag = 'Y'
      --                          and from_org = 'NL6'
      --                          and to_org = 'Z05'
      --                          and waybill_airbill_num in ('SEA','OCEAN')
      --                          and days_pending > max_intransit_pad;

      UPDATE rc_inv_intransit_shipments
         SET AGED_ORDER =
                CASE
                   WHEN (    from_org = 'NL6'
                         AND to_org = 'Z05'
                         AND waybill_airbill_num IN ('SEA', 'OCEAN')
                         AND days_pending > max_intransit_pad)
                   THEN
                      'Y'
                   WHEN (    from_org = 'NL6'
                         AND to_org = 'Z05'
                         AND waybill_airbill_num IN ('SEA', 'OCEAN')
                         AND days_pending <= max_intransit_pad)
                   THEN
                      'N'
                END
       WHERE     status_flag = 'Y'
             AND from_org = 'NL6'
             AND to_org = 'Z05'
             AND waybill_airbill_num IN ('SEA', 'OCEAN')
             AND ORDER_TYPE = lv_order_type_ir;      --US198778 New Code Added


      /* Updating EXCEPTED_RECEIPT_DATE column in intransit UI table */

      UPDATE rc_inv_intransit_shipments ship
         SET expected_receipt_date = shipped_date + max_intransit_pad
       WHERE status_flag = 'Y' AND ORDER_TYPE = lv_order_type_ir; --US198778 New Code Added


      /* Updating freight code column in intransit UI table */

      FOR REC IN FREIGHT_CONFIG
      LOOP
         IF rec.exclude_shipping = 'Y' AND rec.transit_time_max = 3
         THEN
            UPDATE rc_inv_intransit_shipments ship
               SET freight_code = rec.freight_carrier,
                   max_intransit_pad = rec.transit_time_max,
                   waybill_airbill_num = '',
                   expected_receipt_date =
                      shipped_date + rec.transit_time_max
             WHERE     from_org = REC.FROM_ORG
                   AND to_org = REC.TO_ORG
                   AND status_flag = 'Y'
                   AND NOT EXISTS
                          (SELECT 1
                             FROM rc_inv_intransit_shipments
                            WHERE     ship.from_org = 'U30'
                                  AND ship.to_org = 'Z05'
                                  AND ship.freight_code = 'MORGAN')
                   AND ORDER_TYPE = lv_order_type_ir; --US198778 New Code Added
         END IF;
      END LOOP;

      /* Updating aged order for Telephan shuttle */

      UPDATE rc_inv_intransit_shipments
         SET AGED_ORDER =
                CASE
                   WHEN (    freight_code = 'Teleplan Shuttle'
                         AND days_pending > max_intransit_pad)
                   THEN
                      'Y'
                   WHEN (    freight_code = 'Teleplan Shuttle'
                         AND days_pending <= max_intransit_pad)
                   THEN
                      'N'
                END
       WHERE     status_flag = 'Y'
             AND freight_code = 'Teleplan Shuttle'
             AND ORDER_TYPE = lv_order_type_ir;      --US198778 New Code Added

      --US198778 - Commenting below update to improve performace since expected_receipt_date is already null for null max_intransit_pad
      /*UPDATE rc_inv_intransit_shipments
         SET Expected_receipt_date = ''
       WHERE max_intransit_pad IS NULL;*/



      --US198778 New Code Start

      UPDATE RC_INV_INTRANSIT_SHIPMENTS SHIP
         SET REFRESH_PID =
                NVL (
                   NVL (
                      (SELECT RC.REFRESH_PART_NUMBER
                         FROM CRPADM.RC_PRODUCT_MASTER RC
                        WHERE     TAN_ID IS NOT NULL
                              AND (   SHIP.PART_NUMBER =
                                         RC.COMMON_PART_NUMBER
                                   OR SHIP.PART_NUMBER = RC.XREF_PART_NUMBER)
                              AND PROGRAM_TYPE = 0
                              AND REFRESH_LIFE_CYCLE_ID <> 6
                              AND RC.REFRESH_PART_NUMBER IS NOT NULL
                              AND ROWNUM = 1),
                      (SELECT RC.REFRESH_PART_NUMBER
                         FROM CRPADM.RC_PRODUCT_MASTER RC
                        WHERE     TAN_ID IS NOT NULL
                              AND (   SHIP.PART_NUMBER =
                                         RC.COMMON_PART_NUMBER
                                   OR SHIP.PART_NUMBER = RC.XREF_PART_NUMBER)
                              AND PROGRAM_TYPE = 1
                              AND REFRESH_LIFE_CYCLE_ID <> 6
                              AND RC.REFRESH_PART_NUMBER IS NOT NULL
                              AND ROWNUM = 1)),
                   (SELECT RC.REFRESH_PART_NUMBER
                      FROM CRPADM.RC_PRODUCT_MASTER RC
                     WHERE     TAN_ID IS NOT NULL
                           AND SHIP.PART_NUMBER = RC.REFRESH_PART_NUMBER
                           AND REFRESH_LIFE_CYCLE_ID <> 6
                           AND RC.REFRESH_PART_NUMBER IS NOT NULL
                           AND ROWNUM = 1))
       WHERE STATUS_FLAG = 'Y' AND ORDER_TYPE = lv_order_type_ir;


      OPEN INTRANS_SHIP;

      LOOP
         FETCH INTRANS_SHIP INTO INTRANS_REC;

         EXIT WHEN INTRANS_SHIP%NOTFOUND;

         SELECT MAX (SEQ_ID)
           INTO lv_seq_id
           FROM RC_INV_INTRANSIT_SHIPMENTS
          WHERE     ORDER_NUMBER = INTRANS_REC.ORDER_NUMBER
                AND PART_NUMBER = INTRANS_REC.PART_NUMBER
                AND SHIPMENT_NUMBER = INTRANS_REC.SHIPMENT_NUMBER
                AND LINE_NUM = INTRANS_REC.LINE_NUM
                AND STATUS_FLAG = 'N'
                AND COMMENTS IS NOT NULL
                AND ORDER_TYPE = lv_order_type_ir;


         UPDATE RC_INV_INTRANSIT_SHIPMENTS
            SET COMMENTS =
                   (     SELECT DISTINCT COMMENTS
                           FROM RC_INV_INTRANSIT_SHIPMENTS
                          WHERE     SEQ_ID = lv_seq_id
                                AND ORDER_TYPE = lv_order_type_ir
                                AND COMMENTS IS NOT NULL
                       ORDER BY report_run_date DESC
                    FETCH FIRST 1 ROW ONLY)
          WHERE     STATUS_FLAG = 'Y'
                AND ORDER_NUMBER = INTRANS_REC.ORDER_NUMBER
                AND PART_NUMBER = INTRANS_REC.PART_NUMBER
                AND SHIPMENT_NUMBER = INTRANS_REC.SHIPMENT_NUMBER
                AND LINE_NUM = INTRANS_REC.LINE_NUM
                AND COMMENTS IS NULL
                AND ORDER_TYPE = lv_order_type_ir;
      END LOOP;

      CLOSE INTRANS_SHIP;

      --END IF;
      --US198778 New Code End

      --US198778 New Code Added
      SELECT COUNT (1)
        INTO lv_count_sons
        FROM RC_SONS_INTRANS_SHIPMTS_STG
       WHERE NVL (updated_on, created_on) >= v_start_date;

      IF lv_count_sons > 0
      THEN
         RC_INV_INTRANS_SHIPMENTS.P_RC_INSERT_SONSORDER_STG_HIST;

         MERGE INTO RC_INV_INTRANSIT_SHIPMENTS ship
              USING (SELECT *
                       FROM RC_SONS_INTRANS_SHIPMTS_STG
                      WHERE NVL (updated_on, created_on) >= v_start_date) stg
                 ON (ship.seq_id = stg.seq_id AND ship.order_type = 'SONS')
         WHEN MATCHED
         THEN
            UPDATE SET
               ship.INVENTORY_ITEM_ID = stg.INVENTORY_ITEM_ID,
               ship.PART_NUMBER = stg.PART_NUMBER,
               ship.REFRESH_PID = stg.REFRESH_PID,
               ship.ORDER_NUMBER = stg.ORDER_NUMBER,
               ship.SHIPMENT_NUMBER = stg.SHIPMENT_NUMBER,
               ship.WAYBILL_AIRBILL_NUM = stg.WAYBILL_AIRBILL_NUM,
               ship.FROM_ORG = stg.FROM_ORG,
               ship.TO_ORG = stg.TO_ORG,
               ship.FROM_SUBINVENTORY = stg.FROM_SUBINVENTORY,
               ship.TO_SUBINVENTORY = stg.TO_SUBINVENTORY,
               ship.FREIGHT_CARRIER_CODE = stg.FREIGHT_CARRIER_CODE,
               ship.SHIPPED_DATE = stg.SHIPPED_DATE,
               ship.EXPECTED_RECEIPT_DATE = stg.EXPECTED_RECEIPT_DATE,
               ship.SHIPPED_QUANTITY = stg.SHIPPED_QUANTITY,
               ship.RECEIVED_QUANTITY = stg.RECEIVED_QUANTITY,
               ship.PENDING_QTY = stg.PENDING_QTY,
               ship.DAYS_PENDING = stg.DAYS_PENDING,
               ship.CREATED_ON = stg.CREATED_ON,
               ship.CREATED_BY = stg.CREATED_BY,
               ship.UPDATED_ON = stg.UPDATED_ON,
               ship.UPDATED_BY = stg.UPDATED_BY,
               ship.LINE_NUM = stg.LINE_NUM,
               ship.FREIGHT_CODE = stg.FREIGHT_CARRIER_CODE,
               ship.STATUS_FLAG =
                  DECODE (NVL (stg.PENDING_QTY, 0), 0, 'N', 'Y')
         WHEN NOT MATCHED
         THEN
            INSERT     (SEQ_ID,
                        INVENTORY_ITEM_ID,
                        PART_NUMBER,
                        REFRESH_PID,
                        ORDER_NUMBER,
                        SHIPMENT_NUMBER,
                        WAYBILL_AIRBILL_NUM,
                        ADDITIONAL_SHIPMENT_INFO,
                        FROM_ORGANIZATION_ID,
                        FROM_ORG,
                        TO_ORGANIZATION_ID,
                        TO_ORG,
                        FROM_SUBINVENTORY,
                        TO_SUBINVENTORY,
                        SHIP_TO_LOCATION_ID,
                        FREIGHT_CARRIER_CODE,
                        SHIPPED_DATE,
                        EXPECTED_RECEIPT_DATE,
                        SHIPPED_QUANTITY,
                        RECEIVED_QUANTITY,
                        VENDOR_ID,
                        STATUS_FLAG,
                        PENDING_QTY,
                        DAYS_PENDING,
                        COMMENTS,
                        REPORT_RUN_DATE,
                        CREATED_ON,
                        CREATED_BY,
                        UPDATED_ON,
                        UPDATED_BY,
                        ATTRIBUTE1,
                        ATTRIBUTE2,
                        ATTRIBUTE3,
                        ATTRIBUTE4,
                        ATTRIBUTE5,
                        ATTRIBUTE6,
                        ATTRIBUTE7,
                        ATTRIBUTE8,
                        ATTRIBUTE9,
                        LINE_NUM,
                        FREIGHT_CODE,
                        ORDER_TYPE)
                VALUES (stg.SEQ_ID,
                        stg.INVENTORY_ITEM_ID,
                        stg.PART_NUMBER,
                        stg.REFRESH_PID,
                        stg.ORDER_NUMBER,
                        stg.SHIPMENT_NUMBER,
                        stg.WAYBILL_AIRBILL_NUM,
                        NULL,
                        stg.FROM_ORGANIZATION_ID,
                        stg.FROM_ORG,
                        stg.TO_ORGANIZATION_ID,
                        stg.TO_ORG,
                        stg.FROM_SUBINVENTORY,
                        stg.TO_SUBINVENTORY,
                        NULL,
                        stg.FREIGHT_CARRIER_CODE,
                        stg.SHIPPED_DATE,
                        stg.EXPECTED_RECEIPT_DATE,
                        stg.SHIPPED_QUANTITY,
                        stg.RECEIVED_QUANTITY,
                        NULL,
                        stg.STATUS_FLAG,
                        stg.PENDING_QTY,
                        stg.DAYS_PENDING,
                        stg.COMMENTS,
                        NVL (stg.UPDATED_ON, stg.CREATED_ON),
                        stg.CREATED_ON,
                        stg.CREATED_BY,
                        stg.UPDATED_ON,
                        stg.UPDATED_BY,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        stg.LINE_NUM,
                        stg.FREIGHT_CARRIER_CODE,
                        lv_order_type_sons);

         UPDATE RC_INV_INTRANSIT_SHIPMENTS
            SET STATUS_FLAG = 'N'
          WHERE     STATUS_FLAG = 'Y'
                AND ORDER_TYPE = lv_order_type_sons
                AND NVL (FROM_SUBINVENTORY, 'NA') NOT IN ('RF-FGI', 'WS-FGI');

         UPDATE RC_INV_INTRANSIT_SHIPMENTS
            SET status_flag = 'N'
          WHERE     status_flag = 'Y'
                AND order_type = lv_order_type_sons
                AND pending_qty = 0;
      END IF;

      UPDATE RC_INV_INTRANSIT_SHIPMENTS
         SET DAYS_PENDING =
                  (TRUNC (SYSDATE) - TRUNC (shipped_date))
                - 2 * FLOOR ( (TRUNC (SYSDATE) - TRUNC (shipped_date)) / 7)
                - DECODE (
                     SIGN (
                          TO_CHAR (TRUNC (SYSDATE), 'D')
                        - TO_CHAR (TRUNC (shipped_date), 'D')),
                     -1, 2,
                     0)
                - DECODE (TO_CHAR (TRUNC (shipped_date), 'D'), 1, 1, 0)
       WHERE STATUS_FLAG = 'Y' AND ORDER_TYPE = lv_order_type_sons;

      FOR REC IN FREIGHT_CONFIG
      LOOP
         UPDATE rc_inv_intransit_shipments ship
            SET AGED_ORDER =
                   (CASE
                       WHEN (    from_org = rec.from_org
                             AND to_org = rec.to_org
                             AND freight_code = rec.freight_carrier
                             AND days_pending > NVL (rec.transit_time_max, 0))
                       THEN
                          'Y'
                       ELSE
                          'N'
                    END)
          WHERE     status_flag = 'Y'
                AND from_org = rec.from_org
                AND to_org = rec.to_org
                AND freight_code = rec.freight_carrier
                AND days_pending > NVL (rec.transit_time_max, 0)
                AND ORDER_TYPE = lv_order_type_sons;
      END LOOP;

      FOR REC IN FREIGHT_CONFIG
      LOOP
         UPDATE rc_inv_intransit_shipments ship
            SET AGED_ORDER =
                   (CASE
                       WHEN (    from_org = rec.from_org
                             AND to_org = rec.to_org
                             AND rec.freight_carrier IS NULL
                             AND days_pending > NVL (rec.transit_time_max, 0))
                       THEN
                          'Y'
                       ELSE
                          'N'
                    END)
          WHERE     status_flag = 'Y'
                AND from_org = rec.from_org
                AND to_org = rec.to_org
                AND rec.freight_carrier IS NULL
                AND days_pending > NVL (rec.transit_time_max, 0)
                AND aged_order IS NULL
                AND ORDER_TYPE = lv_order_type_sons;
      END LOOP;

      UPDATE rc_inv_intransit_shipments
         SET AGED_ORDER = 'N'
       WHERE     AGED_ORDER IS NULL
             AND status_flag = 'Y'
             AND ORDER_TYPE = lv_order_type_sons;

      UPDATE rc_inv_intransit_shipments ship
         SET max_intransit_pad =
                (SELECT transit_time_max
                   FROM RC_INV_FREIGHT_CARRIER_CONFIG config
                  WHERE     ship.from_org = config.from_org
                        AND ship.to_org = config.to_org
                        AND ship.freight_code = config.freight_carrier)
       WHERE status_flag = 'Y' AND ORDER_TYPE = lv_order_type_sons;

      --update max intransit pad when given freight code is not available in config table
      UPDATE rc_inv_intransit_shipments ship
         SET max_intransit_pad =
                (SELECT transit_time_max
                   FROM RC_INV_FREIGHT_CARRIER_CONFIG config
                  WHERE     ship.from_org = config.from_org
                        AND ship.to_org = config.to_org
                        AND config.freight_carrier IS NULL)
       WHERE     status_flag = 'Y'
             AND ORDER_TYPE = lv_order_type_sons
             AND max_intransit_pad IS NULL;

      UPDATE RC_INV_INTRANSIT_SHIPMENTS SHIP
         SET expected_receipt_date = shipped_date + max_intransit_pad
       WHERE status_flag = 'Y' AND ORDER_TYPE = lv_order_type_sons;

      OPEN INTRANS_SHIP;

      LOOP
         FETCH INTRANS_SHIP INTO INTRANS_REC;

         EXIT WHEN INTRANS_SHIP%NOTFOUND;

         SELECT MAX (SEQ_ID)
           INTO lv_seq_id
           FROM RC_INV_INTRANSIT_SHIPMENTS
          WHERE     ORDER_NUMBER = INTRANS_REC.ORDER_NUMBER
                AND PART_NUMBER = INTRANS_REC.PART_NUMBER
                AND SHIPMENT_NUMBER = INTRANS_REC.SHIPMENT_NUMBER
                AND LINE_NUM = INTRANS_REC.LINE_NUM
                AND STATUS_FLAG = 'N'
                AND COMMENTS IS NOT NULL
                AND ORDER_TYPE = lv_order_type_sons;

         UPDATE RC_INV_INTRANSIT_SHIPMENTS
            SET COMMENTS =
                   (     SELECT DISTINCT COMMENTS
                           FROM RC_INV_INTRANSIT_SHIPMENTS
                          WHERE     SEQ_ID = lv_seq_id
                                AND ORDER_TYPE = lv_order_type_sons
                                AND COMMENTS IS NOT NULL
                       ORDER BY report_run_date DESC
                    FETCH FIRST 1 ROW ONLY)
          WHERE     STATUS_FLAG = 'Y'
                AND ORDER_NUMBER = INTRANS_REC.ORDER_NUMBER
                AND PART_NUMBER = INTRANS_REC.PART_NUMBER
                AND SHIPMENT_NUMBER = INTRANS_REC.SHIPMENT_NUMBER
                AND LINE_NUM = INTRANS_REC.LINE_NUM
                AND COMMENTS IS NULL
                AND ORDER_TYPE = lv_order_type_sons;
      END LOOP;

      CLOSE INTRANS_SHIP;

      --US198778 New Code End

      --US198778 Code Comment Start
      /*     OPEN INTRANS_SHIP;

           LOOP
              FETCH INTRANS_SHIP INTO INTRANS_REC;

              EXIT WHEN INTRANS_SHIP%NOTFOUND;

                       UPDATE RC_INV_INTRANSIT_SHIPMENTS
                          SET COMMENTS =
                                 (SELECT COMMENTS
                                    FROM RC_INV_INTRANSIT_SHIPMENTS
                                   WHERE SEQ_ID =
                                            (SELECT MAX (SEQ_ID)
                                               FROM RC_INV_INTRANSIT_SHIPMENTS
                                              WHERE     ORDER_NUMBER =
                                                           INTRANS_REC.ORDER_NUMBER
                                                    AND PART_NUMBER =
                                                           INTRANS_REC.PART_NUMBER
                                                    AND SHIPMENT_NUMBER =
                                                           INTRANS_REC.SHIPMENT_NUMBER
                                                    AND LINE_NUM = INTRANS_REC.LINE_NUM
                                                    AND STATUS_FLAG = 'N'
                                                    AND COMMENTS IS NOT NULL))
                        WHERE     STATUS_FLAG = 'Y'
                              AND ORDER_NUMBER = INTRANS_REC.ORDER_NUMBER
                              AND PART_NUMBER = INTRANS_REC.PART_NUMBER
                              AND SHIPMENT_NUMBER = INTRANS_REC.SHIPMENT_NUMBER
                              AND LINE_NUM = INTRANS_REC.LINE_NUM
                              AND COMMENTS IS NULL;

           END LOOP;  */
      --US198778 Code Comment End

      -->> Success entry into control table added on 14 Feb 2018 by sridvasu

      UPDATE RMKTGADM.CRON_CONTROL_INFO
         SET CRON_STATUS = 'SUCCESS', CRON_END_TIMESTAMP = SYSDATE
       WHERE     CRON_NAME = 'P_RC_INV_INTRANS_SHIPMTS_LOAD'
             AND CRON_CONTACT_ID = 'INTRANS_SHIPMTS';

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := SUBSTR (SQLERRM, 1, 200);

         P_RC_ERROR_LOG (
            I_module_name       => 'P_RC_INV_INTRANS_SHIPMTS_LOAD',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while loading intransit shipments table '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => 'RC_INV_INTRANS_SHIPMENTS',
            I_updated_by        => 'RC_INV_INTRANS_SHIPMENTS');

         CLOSE INTRANS_SHIP;
   END P_RC_INV_INTRANS_SHIPMTS_LOAD;


   PROCEDURE P_RC_INV_FROM_TO_ORG_SUBINV (
      O_FROM_ORG             OUT T_FROM_ORG_TBL,
      O_TO_ORG               OUT T_TO_ORG_TBL,
      O_TO_SUBINV            OUT T_TO_SUBINV_TBL,
      --US198778 New Code Start
      O_FROM_SUBINV          OUT T_FROM_SUBINV_TBL,
      O_FREIGHT_CODE         OUT T_FREIGHT_CODE_TBL,
      O_ORDER_TYPE           OUT T_ORDER_TYPE_TBL,
      --US198778 New Code End
      o_report_run_message   OUT VARCHAR2)
   AS
      lv_from_org             T_FROM_ORG_TBL;
      lv_to_org               T_TO_ORG_TBL;
      lv_to_subinv            T_TO_SUBINV_TBL;
      --US198778 New Code Start
      lv_from_subinv          T_FROM_SUBINV_TBL;
      lv_freight_code         T_FREIGHT_CODE_TBL;
      lv_order_type           T_ORDER_TYPE_TBL;
      --US198778 New Code End
      lv_report_run_date      VARCHAR2 (50);
      lv_report_run_message   VARCHAR2 (100);
   BEGIN
      lv_from_org := T_FROM_ORG_TBL ();
      lv_to_org := T_TO_ORG_TBL ();
      lv_to_subinv := T_TO_SUBINV_TBL ();

      /* Start 16th Nov, 2017 Added Exception for each select statement */

      BEGIN
         SELECT T_FROM_ORG_OBJ (CONFIG_NAME)
           BULK COLLECT INTO lv_from_org
           FROM (  SELECT DISTINCT FROM_ORG CONFIG_NAME
                     FROM RC_INV_INTRANSIT_SHIPMENTS
                    WHERE STATUS_FLAG = 'Y'
                 ORDER BY FROM_ORG);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 200);
            DBMS_OUTPUT.put_line (v_message);
      END;


      BEGIN
         SELECT T_TO_ORG_OBJ (ZCODE)
           BULK COLLECT INTO lv_to_org
           FROM (  SELECT DISTINCT TO_ORG ZCODE
                     FROM RC_INV_INTRANSIT_SHIPMENTS
                    WHERE STATUS_FLAG = 'Y'
                 ORDER BY TO_ORG);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 200);
            DBMS_OUTPUT.put_line (v_message);
      END;


      BEGIN
         SELECT T_TO_SUBINV_OBJ (SUB_INVENTORY_LOCATION)
           BULK COLLECT INTO lv_to_subinv
           FROM (  SELECT DISTINCT TO_SUBINVENTORY SUB_INVENTORY_LOCATION
                     FROM RC_INV_INTRANSIT_SHIPMENTS
                    WHERE STATUS_FLAG = 'Y'
                 ORDER BY TO_SUBINVENTORY);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 200);
            DBMS_OUTPUT.put_line (v_message);
      END;

      --US198778 New Code Start
      BEGIN
         SELECT T_FROM_SUBINV_OBJ (SUB_INVENTORY_LOCATION)
           BULK COLLECT INTO lv_from_subinv
           FROM (  SELECT DISTINCT FROM_SUBINVENTORY SUB_INVENTORY_LOCATION
                     FROM RC_INV_INTRANSIT_SHIPMENTS
                    WHERE STATUS_FLAG = 'Y' AND FROM_SUBINVENTORY IS NOT NULL
                 ORDER BY FROM_SUBINVENTORY);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 200);
            DBMS_OUTPUT.put_line (v_message);
      END;

      BEGIN
         SELECT T_FREIGHT_CODE_OBJ (FREIGHT_CODE)
           BULK COLLECT INTO lv_freight_code
           FROM (  SELECT DISTINCT FREIGHT_CARRIER_CODE FREIGHT_CODE
                     FROM RC_INV_INTRANSIT_SHIPMENTS
                    WHERE STATUS_FLAG = 'Y'
                 ORDER BY FREIGHT_CARRIER_CODE);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 200);
            DBMS_OUTPUT.put_line (v_message);
      END;

      BEGIN
         SELECT T_ORDER_TYPE_OBJ (ORDER_TYPE)
           BULK COLLECT INTO lv_order_type
           FROM (  SELECT DISTINCT ORDER_TYPE
                     FROM RC_INV_INTRANSIT_SHIPMENTS
                    WHERE STATUS_FLAG = 'Y'
                 ORDER BY ORDER_TYPE);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 200);
            DBMS_OUTPUT.put_line (v_message);
      END;

      --US198778 New Code End


      BEGIN
         /* Start 16th Nov, 2017 Added RC_INV_INTRANSIT_SHIPMENTS to get report run date instead of RC_INV_INTRANS_SHIPMTS_STG */

         SELECT TO_CHAR (MAX (report_run_date), 'MM/DD/YYYY HH:MI:SS AM') --modified by sanjay to show the time on UI as per actual job completion time
           INTO lv_report_run_date
           FROM RC_INV_INTRANSIT_SHIPMENTS
          WHERE STATUS_FLAG = 'Y';
      /* End 16th Nov, 2017 Added RC_INV_INTRANSIT_SHIPMENTS to get report run date instead of RC_INV_INTRANS_SHIPMTS_STG */

      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 200);
            DBMS_OUTPUT.put_line (v_message);
      END;

      /* End 16th Nov, 2017 Added Exception for each select statement */

      lv_report_run_message :=
            'In Transit Shipments report was generated on '
         || lv_report_run_date;



      O_FROM_ORG := lv_from_org;
      O_TO_ORG := lv_to_org;
      O_TO_SUBINV := lv_to_subinv;
      --US198778 New Code Start
      O_FROM_SUBINV := lv_from_subinv;
      O_FREIGHT_CODE := lv_freight_code;
      O_ORDER_TYPE := lv_order_type;
      --US198778 New Code End
      o_report_run_message := lv_report_run_message;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := SUBSTR (SQLERRM, 1, 200);

         P_RC_ERROR_LOG (
            I_module_name       => 'P_RC_INV_FROM_TO_ORG_SUBINV',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while getting from to orgs '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => 'RC_INV_INTRANS_SHIPMENTS',
            I_updated_by        => 'RC_INV_INTRANS_SHIPMENTS');
   END P_RC_INV_FROM_TO_ORG_SUBINV;

   PROCEDURE P_RC_INV_INTRANS_SHIP_LOAD_UI (
      i_part_number                                 VARCHAR2,
      i_order_number                                VARCHAR2,
      i_shipment_number                             VARCHAR2,
      i_from_org                                    VARCHAR2,
      i_to_org                                      VARCHAR2,
      i_to_subinv                                   VARCHAR2,
      i_aged_order                                  VARCHAR2,
      --US198778 New Code Start
      i_order_type                                  VARCHAR2,
      i_from_subinv                                 VARCHAR2,
      i_freight_code                                VARCHAR2,
      i_shipped_date_from                           VARCHAR2,
      i_shipped_date_to                             VARCHAR2,
      i_expected_received_date_from                 VARCHAR2,
      i_expected_received_date_to                   VARCHAR2,
      --US198778 New Code End
      i_min_row                                     NUMBER,
      i_max_row                                     NUMBER,
      i_sort_column_name                            VARCHAR2,
      i_sort_column_by                              VARCHAR2,
      o_inv_intrans_shipmts              OUT NOCOPY RC_INV_INTRANS_SHIPMTS_TAB,
      o_inv_intrans_shipmts_data         OUT NOCOPY RC_INV_INTRANS_SHIPMTS_TAB,
      o_count                            OUT NOCOPY NUMBER)
   IS
      lv_query                       VARCHAR2 (32767);
      lv_data_query                  VARCHAR2 (32767);
      lv_cnt_query                   VARCHAR2 (32767);
      lv_inv_intrans_ship_tab        RC_INV_INTRANS_SHIPMTS_TAB
                                        := RC_INV_INTRANS_SHIPMTS_TAB ();
      lv_inv_intrans_ship_data_tab   RC_INV_INTRANS_SHIPMTS_TAB
                                        := RC_INV_INTRANS_SHIPMTS_TAB ();
      lv_count                       NUMBER;
      lv_sort_column_name            VARCHAR2 (100);
      lv_sort_column_by              VARCHAR2 (100);
      lv_min_row                     NUMBER;
      lv_max_row                     NUMBER;
      lv_part_number                 VARCHAR2 (32767);
      lv_part_numbers                VARCHAR2 (32767);
   BEGIN
      lv_sort_column_name := UPPER (TRIM (i_sort_column_name));
      lv_sort_column_by := UPPER (TRIM (i_sort_column_by));
      lv_min_row := TO_NUMBER (i_min_row);
      lv_max_row := TO_NUMBER (i_max_row);

      lv_cnt_query :=
         'SELECT COUNT(*) FROM RC_INV_INTRANSIT_SHIPMENTS WHERE STATUS_FLAG = ''Y''';

      /*US198778 lv_query modified to comment REFRESH_PID from crpadm.rc_product_master,
      add REFRESH_PID from table rc_inv_intransit_shipments,
      add new columns LINE_NUM, FROM_SUBINVENTORY, ORDER_TYPE*/
      lv_query :=
         'SELECT RC_INV_INTRANS_SHIPMTS_OBJ (SEQ_ID,
                                    INVENTORY_ITEM_ID,
                                    PART_NUMBER,
                                    REFRESH_PID,
                                    ORDER_NUMBER,
                                    SHIPMENT_NUMBER,
                                    WAYBILL_AIRBILL_NUM,
                                    ADDITIONAL_SHIPMENT_INFO,
                                    FROM_ORGANIZATION_ID,
                                    FROM_ORG,
                                    TO_ORGANIZATION_ID,
                                    TO_ORG,
                                    TO_SUBINVENTORY,
                                    SHIP_TO_LOCATION_ID,
                                    FREIGHT_CARRIER_CODE,
                                    SHIPPED_DATE,
                                    EXPECTED_RECEIPT_DATE,
                                    SHIPPED_QUANTITY,
                                    RECEIVED_QUANTITY,
                                    VENDOR_ID,
                                    STATUS_FLAG,
                                    PENDING_QTY,
                                    DAYS_PENDING,
                                    COMMENTS,
                                    AGED_ORDER,
                                    CONFIG_URL,
                                    CREATED_ON,
                                    CREATED_BY,
                                    UPDATED_ON,
                                    UPDATED_BY,
                                    V_ATTR1,
                                    V_ATTR2,
                                    V_ATTR3,
                                    V_ATTR4,
                                    N_ATTR1,
                                    N_ATTR2,
                                    N_ATTR3,
                                    N_ATTR4,
                                    D_ATTR1,
                                    D_ATTR2,
                                    D_ATTR3,
                                    D_ATTR4,
									LINE_NUM,
									ORDER_TYPE,
									FROM_SUBINVENTORY
                                    ) 
                FROM
                (SELECT /*+ opt_param(''optimizer_mode'',''first_rows_10'') */ * FROM 
                (SELECT
                SEQ_ID,
                INVENTORY_ITEM_ID,
                PART_NUMBER,
                --(select /*+ opt_param(''optimizer_mode'',''first_rows_10'') */ rc.refresh_part_number from CRPADM.RC_PRODUCT_MASTER RC where TAN_ID IS NOT NULL AND (SHIP.PART_NUMBER = RC.COMMON_PART_NUMBER OR SHIP.PART_NUMBER = RC.XREF_PART_NUMBER) AND PROGRAM_TYPE = 0 AND REFRESH_LIFE_CYCLE_ID <> 6) REFRESH_PID,
                REFRESH_PID,
                ORDER_NUMBER,
                SHIPMENT_NUMBER,
                WAYBILL_AIRBILL_NUM,
                --NVL(WAYBILL_AIRBILL_NUM,ADDITIONAL_SHIPMENT_INFO) WAYBILL_AIRBILL_NUM,  
                ADDITIONAL_SHIPMENT_INFO,
                FROM_ORGANIZATION_ID,
                FROM_ORG,
                TO_ORGANIZATION_ID,
                TO_ORG,
                TO_SUBINVENTORY,
                SHIP_TO_LOCATION_ID,
                FREIGHT_CODE FREIGHT_CARRIER_CODE,                
                SHIPPED_DATE,
                EXPECTED_RECEIPT_DATE,                
                SHIPPED_QUANTITY,
                RECEIVED_QUANTITY,
                VENDOR_ID,
                STATUS_FLAG,
                PENDING_QTY,
                DAYS_PENDING,
                SHIP.COMMENTS COMMENTS,
                AGED_ORDER,
                (SELECT /*+ opt_param(''optimizer_mode'',''first_rows_10'') */ config_description
                        FROM RC_INV_CONFIG config
                    WHERE  ship.freight_code = config.config_name
                           AND config_type = ''TRACKING_URL'') CONFIG_URL,
                CREATED_ON,
                CREATED_BY,
                UPDATED_ON,
                UPDATED_BY,
                NULL V_ATTR1,
                NULL V_ATTR2,
                NULL V_ATTR3,
                NULL V_ATTR4,
                MAX_INTRANSIT_PAD N_ATTR1,
                NULL N_ATTR2,
                NULL N_ATTR3,
                NULL N_ATTR4,
                NULL D_ATTR1,
                NULL D_ATTR2,
                NULL D_ATTR3,
                NULL D_ATTR4,
				LINE_NUM,
				ORDER_TYPE,
				FROM_SUBINVENTORY,';

      /*US198778 lv_query modified to comment REFRESH_PID from crpadm.rc_product_master,
      add REFRESH_PID from table rc_inv_intransit_shipments,
      add new columns LINE_NUM, FROM_SUBINVENTORY, ORDER_TYPE*/
      lv_data_query :=
         'SELECT RC_INV_INTRANS_SHIPMTS_OBJ (SEQ_ID,
                                    INVENTORY_ITEM_ID,
                                    PART_NUMBER,
                                    REFRESH_PID,
                                    ORDER_NUMBER,
                                    SHIPMENT_NUMBER,
                                    WAYBILL_AIRBILL_NUM,
                                    ADDITIONAL_SHIPMENT_INFO,
                                    FROM_ORGANIZATION_ID,
                                    FROM_ORG,
                                    TO_ORGANIZATION_ID,
                                    TO_ORG,
                                    TO_SUBINVENTORY,
                                    SHIP_TO_LOCATION_ID,
                                    FREIGHT_CARRIER_CODE,
                                    SHIPPED_DATE,
                                    EXPECTED_RECEIPT_DATE,
                                    SHIPPED_QUANTITY,
                                    RECEIVED_QUANTITY,
                                    VENDOR_ID,
                                    STATUS_FLAG,
                                    PENDING_QTY,
                                    DAYS_PENDING,
                                    COMMENTS,
                                    AGED_ORDER,
                                    CONFIG_URL,
                                    CREATED_ON,
                                    CREATED_BY,
                                    UPDATED_ON,
                                    UPDATED_BY,
                                    V_ATTR1,
                                    V_ATTR2,
                                    V_ATTR3,
                                    V_ATTR4,
                                    N_ATTR1,
                                    N_ATTR2,
                                    N_ATTR3,
                                    N_ATTR4,
                                    D_ATTR1,
                                    D_ATTR2,
                                    D_ATTR3,
                                    D_ATTR4,
									LINE_NUM,
									ORDER_TYPE,
									FROM_SUBINVENTORY) 
                FROM
                (SELECT /*+ opt_param(''optimizer_mode'',''first_rows_10'') */ 
                SEQ_ID,
                INVENTORY_ITEM_ID,
                PART_NUMBER,
                --(select /*+ opt_param(''optimizer_mode'',''first_rows_10'') */ rc.refresh_part_number from CRPADM.RC_PRODUCT_MASTER RC where TAN_ID IS NOT NULL AND (SHIP.PART_NUMBER = RC.COMMON_PART_NUMBER OR SHIP.PART_NUMBER = RC.XREF_PART_NUMBER) AND PROGRAM_TYPE = 0 AND REFRESH_LIFE_CYCLE_ID <> 6) REFRESH_PID,
                REFRESH_PID,
                ORDER_NUMBER,
                SHIPMENT_NUMBER,
                WAYBILL_AIRBILL_NUM,
                --NVL(WAYBILL_AIRBILL_NUM,ADDITIONAL_SHIPMENT_INFO) WAYBILL_AIRBILL_NUM,  
                ADDITIONAL_SHIPMENT_INFO,
                FROM_ORGANIZATION_ID,
                FROM_ORG,
                TO_ORGANIZATION_ID,
                TO_ORG,
                TO_SUBINVENTORY,
                SHIP_TO_LOCATION_ID,
                FREIGHT_CODE FREIGHT_CARRIER_CODE,                
                SHIPPED_DATE,
                EXPECTED_RECEIPT_DATE,                
                SHIPPED_QUANTITY,
                RECEIVED_QUANTITY,
                VENDOR_ID,
                STATUS_FLAG,
                PENDING_QTY,
                DAYS_PENDING,
                SHIP.COMMENTS COMMENTS,
                AGED_ORDER,
                (SELECT /*+ opt_param(''optimizer_mode'',''first_rows_10'') */ config_description
                        FROM RC_INV_CONFIG config
                    WHERE  ship.freight_code = config.config_name
                           AND config_type = ''TRACKING_URL'') CONFIG_URL,
                CREATED_ON,
                CREATED_BY,
                UPDATED_ON,
                UPDATED_BY,
                NULL V_ATTR1,
                NULL V_ATTR2,
                NULL V_ATTR3,
                NULL V_ATTR4,
                MAX_INTRANSIT_PAD N_ATTR1,
                NULL N_ATTR2,
                NULL N_ATTR3,
                NULL N_ATTR4,
                NULL D_ATTR1,
                NULL D_ATTR2,
                NULL D_ATTR3,
                NULL D_ATTR4,
				LINE_NUM,
				ORDER_TYPE,
				FROM_SUBINVENTORY,';

      -- Code for adding the ROW_NUMBER()  OVER or ROWNUM based on whether the sorting is applied or not
      IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
      THEN
         lv_query :=
               lv_query
            || 'ROW_NUMBER()  OVER (ORDER BY '
            || lv_sort_column_name
            || ' '
            || lv_sort_column_by
            || ' ) AS rnum 
                            FROM RC_INV_INTRANSIT_SHIPMENTS SHIP
                            WHERE 1 = 1
                            AND STATUS_FLAG = ''Y''';

         lv_data_query :=
               lv_data_query
            || 'ROW_NUMBER()  OVER (ORDER BY '
            || lv_sort_column_name
            || ' '
            || lv_sort_column_by
            || ' ) AS rnum 
                            FROM RC_INV_INTRANSIT_SHIPMENTS SHIP
                            WHERE 1 = 1
                            AND STATUS_FLAG = ''Y''';
      ELSE
         lv_query :=
               lv_query
            || 'ROW_NUMBER() OVER (ORDER BY AGED_ORDER DESC) AS rnum 
                            FROM RC_INV_INTRANSIT_SHIPMENTS SHIP
                            WHERE 1 = 1
                            AND STATUS_FLAG = ''Y''';

         lv_data_query := lv_data_query || 'ROWNUM AS rnum 
                            FROM RC_INV_INTRANSIT_SHIPMENTS SHIP
                            WHERE 1 = 1
                            AND STATUS_FLAG = ''Y''';
      END IF;


      IF i_part_number IS NOT NULL
      THEN
         lv_count := 0;

         FOR REC
            IN (    SELECT DISTINCT UPPER (TRIM (REGEXP_SUBSTR (i_part_number,
                                                                '[^ ,]+',
                                                                1,
                                                                LEVEL)))
                                       AS part
                      FROM DUAL
                CONNECT BY REGEXP_SUBSTR (i_part_number,
                                          '[^ ,]+',
                                          1,
                                          LEVEL)
                              IS NOT NULL)
         LOOP
            SELECT LISTAGG (part_number, ',')
                      WITHIN GROUP (ORDER BY part_number, ',')
              INTO lv_part_number
              FROM (  SELECT part_number
                        FROM RC_INV_INTRANSIT_SHIPMENTS
                       WHERE     STATUS_FLAG = 'Y' --US198778 New Code Added to improve performance
                             AND (   UPPER (part_number) LIKE
                                        '%' || rec.part || '%'
                                  OR UPPER (refresh_pid) LIKE
                                        '%' || rec.part || '%') --US198778 New Code Added
                    GROUP BY part_number);

            IF lv_count > 0
            THEN
               lv_part_numbers := lv_part_numbers || ',' || lv_part_number;
            ELSE
               lv_part_numbers := lv_part_number;
            END IF;

            lv_count := lv_count + 1;
         --            DBMS_OUTPUT.put_line (lv_part_numbers);
         END LOOP;

         lv_count := 0;

         lv_query :=
               lv_query
            || ' AND UPPER(PART_NUMBER) IN (SELECT DISTINCT UPPER(TRIM(REGEXP_SUBSTR('''
            || lv_part_numbers
            || ''', ''[^ ,]+'', 1, LEVEL))) AS part
                        FROM DUAL
                            CONNECT BY REGEXP_SUBSTR ('''
            || lv_part_numbers
            || ''',''[^ ,]+'',1, LEVEL)  IS NOT NULL)';


         lv_data_query :=
               lv_data_query
            || ' AND UPPER(PART_NUMBER) IN (SELECT DISTINCT UPPER(TRIM(REGEXP_SUBSTR('''
            || lv_part_numbers
            || ''', ''[^ ,]+'', 1, LEVEL))) AS part
                        FROM DUAL
                            CONNECT BY REGEXP_SUBSTR ('''
            || lv_part_numbers
            || ''',''[^ ,]+'',1, LEVEL)  IS NOT NULL)';


         lv_cnt_query :=
               lv_cnt_query
            || ' AND UPPER(PART_NUMBER) IN (SELECT DISTINCT UPPER(TRIM(REGEXP_SUBSTR('''
            || lv_part_numbers
            || ''', ''[^ ,]+'', 1, LEVEL))) AS part
                        FROM DUAL
                            CONNECT BY REGEXP_SUBSTR ('''
            || lv_part_numbers
            || ''',''[^ ,]+'',1, LEVEL)  IS NOT NULL)';
      END IF;

      IF i_order_number IS NOT NULL
      THEN
         lv_query :=
               lv_query
            || ' AND ORDER_NUMBER IN ( SELECT REGEXP_SUBSTR ( '''
            || i_order_number
            || ''''
            || ','
            || '''[^,]+'''
            || ',1, LEVEL)
                                                                                     FROM DUAL
                                                                               CONNECT BY REGEXP_SUBSTR ('''
            || i_order_number
            || ''''
            || ','
            || '''[^,]+'''
            || ',1, LEVEL)  IS NOT NULL)';

         lv_data_query :=
               lv_data_query
            || ' AND ORDER_NUMBER IN ( SELECT REGEXP_SUBSTR ( '''
            || i_order_number
            || ''''
            || ','
            || '''[^,]+'''
            || ',1, LEVEL)
                                                                                     FROM DUAL
                                                                               CONNECT BY REGEXP_SUBSTR ('''
            || i_order_number
            || ''''
            || ','
            || '''[^,]+'''
            || ',1, LEVEL)  IS NOT NULL)';

         lv_cnt_query :=
               lv_cnt_query
            || ' AND ORDER_NUMBER IN ( SELECT REGEXP_SUBSTR ( '''
            || i_order_number
            || ''''
            || ','
            || '''[^,]+'''
            || ',1, LEVEL)
                                                                                     FROM DUAL
                                                                               CONNECT BY REGEXP_SUBSTR ('''
            || i_order_number
            || ''''
            || ','
            || '''[^,]+'''
            || ',1, LEVEL)  IS NOT NULL)';
      END IF;

      IF i_shipment_number IS NOT NULL
      THEN
         lv_query :=
               lv_query
            || ' AND SHIPMENT_NUMBER LIKE '''
            || '%'
            || i_shipment_number
            || '%'
            || '''';

         lv_data_query :=
               lv_data_query
            || ' AND SHIPMENT_NUMBER LIKE '''
            || '%'
            || i_shipment_number
            || '%'
            || '''';

         lv_cnt_query :=
               lv_cnt_query
            || ' AND SHIPMENT_NUMBER LIKE '''
            || '%'
            || i_shipment_number
            || '%'
            || '''';
      END IF;

      IF i_from_org IS NOT NULL
      THEN
         lv_query := lv_query || ' AND FROM_ORG = ''' || i_from_org || '''';

         lv_data_query :=
            lv_data_query || ' AND FROM_ORG = ''' || i_from_org || '''';

         lv_cnt_query :=
            lv_cnt_query || ' AND FROM_ORG = ''' || i_from_org || '''';
      END IF;

      IF i_to_org IS NOT NULL
      THEN
         lv_query := lv_query || ' AND TO_ORG = ''' || i_to_org || '''';

         lv_data_query :=
            lv_data_query || ' AND TO_ORG = ''' || i_to_org || '''';

         lv_cnt_query :=
            lv_cnt_query || ' AND TO_ORG = ''' || i_to_org || '''';
      END IF;

      IF i_to_subinv IS NOT NULL
      THEN
         lv_query :=
            lv_query || ' AND TO_SUBINVENTORY = ''' || i_to_subinv || '''';

         lv_data_query :=
               lv_data_query
            || ' AND TO_SUBINVENTORY = '''
            || i_to_subinv
            || '''';

         lv_cnt_query :=
               lv_cnt_query
            || ' AND TO_SUBINVENTORY = '''
            || i_to_subinv
            || '''';
      END IF;


      IF i_aged_order IS NOT NULL
      THEN
         lv_query :=
            lv_query || ' AND AGED_ORDER = ''' || i_aged_order || '''';

         lv_data_query :=
            lv_data_query || ' AND AGED_ORDER = ''' || i_aged_order || '''';

         lv_cnt_query :=
            lv_cnt_query || ' AND AGED_ORDER = ''' || i_aged_order || '''';
      END IF;

      --US198778 New Code Start
      IF i_order_type IS NOT NULL
      THEN
         lv_query :=
            lv_query || ' AND ORDER_TYPE = ''' || i_order_type || '''';

         lv_data_query :=
            lv_data_query || ' AND ORDER_TYPE = ''' || i_order_type || '''';

         lv_cnt_query :=
            lv_cnt_query || ' AND ORDER_TYPE = ''' || i_order_type || '''';
      END IF;

      IF i_from_subinv IS NOT NULL
      THEN
         lv_query :=
               lv_query
            || ' AND FROM_SUBINVENTORY = '''
            || i_from_subinv
            || '''';

         lv_data_query :=
               lv_data_query
            || ' AND FROM_SUBINVENTORY = '''
            || i_from_subinv
            || '''';

         lv_cnt_query :=
               lv_cnt_query
            || ' AND FROM_SUBINVENTORY = '''
            || i_from_subinv
            || '''';
      END IF;

      IF i_freight_code IS NOT NULL
      THEN
         lv_query :=
               lv_query
            || ' AND FREIGHT_CARRIER_CODE = '''
            || i_freight_code
            || '''';

         lv_data_query :=
               lv_data_query
            || ' AND FREIGHT_CARRIER_CODE = '''
            || i_freight_code
            || '''';

         lv_cnt_query :=
               lv_cnt_query
            || ' AND FREIGHT_CARRIER_CODE = '''
            || i_freight_code
            || '''';
      END IF;

      IF i_shipped_date_from IS NOT NULL
      THEN
         lv_query :=
               lv_query
            || ' AND TO_DATE(SHIPPED_DATE) >= '''
            || TO_DATE (i_shipped_date_from, 'MM/DD/YYYY')
            || '''';

         lv_data_query :=
               lv_data_query
            || ' AND TO_DATE(SHIPPED_DATE) >= '''
            || TO_DATE (i_shipped_date_from, 'MM/DD/YYYY')
            || '''';

         lv_cnt_query :=
               lv_cnt_query
            || ' AND TO_DATE(SHIPPED_DATE) >= '''
            || TO_DATE (i_shipped_date_from, 'MM/DD/YYYY')
            || '''';
      END IF;

      IF i_shipped_date_to IS NOT NULL
      THEN
         lv_query :=
               lv_query
            || ' AND TO_DATE(SHIPPED_DATE) <= '''
            || TO_DATE (i_shipped_date_to, 'MM/DD/YYYY')
            || '''';

         lv_data_query :=
               lv_data_query
            || ' AND TO_DATE(SHIPPED_DATE) <= '''
            || TO_DATE (i_shipped_date_to, 'MM/DD/YYYY')
            || '''';

         lv_cnt_query :=
               lv_cnt_query
            || ' AND TO_DATE(SHIPPED_DATE) <= '''
            || TO_DATE (i_shipped_date_to, 'MM/DD/YYYY')
            || '''';
      END IF;

      IF i_expected_received_date_from IS NOT NULL
      THEN
         lv_query :=
               lv_query
            || ' AND TO_DATE(EXPECTED_RECEIPT_DATE) >= '''
            || TO_DATE (i_expected_received_date_from, 'MM/DD/YYYY')
            || '''';

         lv_data_query :=
               lv_data_query
            || ' AND TO_DATE(EXPECTED_RECEIPT_DATE) >= '''
            || TO_DATE (i_expected_received_date_from, 'MM/DD/YYYY')
            || '''';

         lv_cnt_query :=
               lv_cnt_query
            || ' AND TO_DATE(EXPECTED_RECEIPT_DATE) >= '''
            || TO_DATE (i_expected_received_date_from, 'MM/DD/YYYY')
            || '''';
      END IF;

      IF i_expected_received_date_to IS NOT NULL
      THEN
         lv_query :=
               lv_query
            || ' AND TO_DATE(EXPECTED_RECEIPT_DATE) <= '''
            || TO_DATE (i_expected_received_date_to, 'MM/DD/YYYY')
            || '''';

         lv_data_query :=
               lv_data_query
            || ' AND TO_DATE(EXPECTED_RECEIPT_DATE) <= '''
            || TO_DATE (i_expected_received_date_to, 'MM/DD/YYYY')
            || '''';

         lv_cnt_query :=
               lv_cnt_query
            || ' AND TO_DATE(EXPECTED_RECEIPT_DATE) <= '''
            || TO_DATE (i_expected_received_date_to, 'MM/DD/YYYY')
            || '''';
      END IF;

      --US198778 New Code End

      -- For Sorting based on the user selection
      IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
      THEN
         lv_query :=
               lv_query
            || ' )) RC_INTRANS WHERE rnum >='
            || i_min_row
            || ' AND rnum <='
            || i_max_row;

         lv_query :=
               lv_query
            || ' ORDER BY RC_INTRANS.'
            || lv_sort_column_name
            || ' '
            || lv_sort_column_by;
      ELSE
         lv_query :=
               lv_query
            || ' ORDER BY AGED_ORDER DESC, SHIPPED_DATE DESC) WHERE rnum <= '
            || i_max_row
            || ') WHERE rnum >='
            || i_min_row;
      END IF;

      lv_data_query :=
         lv_data_query || ') ORDER BY AGED_ORDER DESC, SHIPPED_DATE ASC';


      BEGIN
         EXECUTE IMMEDIATE lv_query BULK COLLECT INTO lv_inv_intrans_ship_tab;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 200);

            P_RC_ERROR_LOG (
               I_module_name       => 'P_RC_INV_INTRANS_SHIP_LOAD_UI',
               I_entity_name       => NULL,
               I_entity_id         => NULL,
               I_ext_entity_name   => NULL,
               I_ext_entity_id     => NULL,
               I_error_type        => 'EXCEPTION',
               i_Error_Message     =>    'Error getting while executing intransit shipments '
                                      || ' <> '
                                      || v_message
                                      || ' LineNo=> '
                                      || DBMS_UTILITY.Format_error_backtrace,
               I_created_by        => 'RC_INV_INTRANS_SHIPMENTS',
               I_updated_by        => 'RC_INV_INTRANS_SHIPMENTS');
      END;


      BEGIN
         EXECUTE IMMEDIATE lv_data_query
            BULK COLLECT INTO lv_inv_intrans_ship_data_tab;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 200);

            P_RC_ERROR_LOG (
               I_module_name       => 'P_RC_INV_INTRANS_SHIP_LOAD_UI',
               I_entity_name       => NULL,
               I_entity_id         => NULL,
               I_ext_entity_name   => NULL,
               I_ext_entity_id     => NULL,
               I_error_type        => 'EXCEPTION',
               i_Error_Message     =>    'Error getting while executing intransit shipments '
                                      || ' <> '
                                      || v_message
                                      || ' LineNo=> '
                                      || DBMS_UTILITY.Format_error_backtrace,
               I_created_by        => 'RC_INV_INTRANS_SHIPMENTS',
               I_updated_by        => 'RC_INV_INTRANS_SHIPMENTS');
      END;


      BEGIN
         EXECUTE IMMEDIATE lv_cnt_query INTO lv_count;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 200);

            P_RC_ERROR_LOG (
               I_module_name       => 'P_RC_INV_INTRANS_SHIP_LOAD_UI',
               I_entity_name       => NULL,
               I_entity_id         => NULL,
               I_ext_entity_name   => NULL,
               I_ext_entity_id     => NULL,
               I_error_type        => 'EXCEPTION',
               i_Error_Message     =>    'Error getting while executing intransit shipments '
                                      || ' <> '
                                      || v_message
                                      || ' LineNo=> '
                                      || DBMS_UTILITY.Format_error_backtrace,
               I_created_by        => 'RC_INV_INTRANS_SHIPMENTS',
               I_updated_by        => 'RC_INV_INTRANS_SHIPMENTS');
      END;

      o_inv_intrans_shipmts := lv_inv_intrans_ship_tab;

      o_inv_intrans_shipmts_data := lv_inv_intrans_ship_data_tab;

      o_count := lv_count;
   --      DBMS_OUTPUT.put_line (lv_query);
   --DBMS_OUTPUT.put_line (lv_data_query);
   --      DBMS_OUTPUT.put_line (o_count);

   END P_RC_INV_INTRANS_SHIP_LOAD_UI;


   PROCEDURE P_RC_INV_INTRANS_SHIP_UPDATE (
      i_input_comments       RC_INV_INTRANS_SHIPMTS_TAB,
      i_user_id              VARCHAR2,
      error_status       OUT VARCHAR2)
   AS
   BEGIN
      FOR i IN i_input_comments.FIRST .. i_input_comments.LAST
      LOOP
         UPDATE RC_INV_INTRANSIT_SHIPMENTS
            SET COMMENTS = i_input_comments (i).COMMENTS,
                UPDATED_BY = i_user_id,
                UPDATED_ON = SYSDATE
          WHERE     SEQ_ID = i_input_comments (i).SEQ_ID
                AND ORDER_TYPE = i_input_comments (i).ORDER_TYPE; --US198778 New Code Added
      END LOOP;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := SUBSTR (SQLERRM, 1, 200);

         P_RC_ERROR_LOG (
            I_module_name       => 'P_RC_INV_INTRANS_SHIP_UPDATE',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while updating comments in intransit shipments table '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => 'RC_INV_INTRANS_SHIPMENTS',
            I_updated_by        => 'RC_INV_INTRANS_SHIPMENTS');

         error_status := v_message;
   END P_RC_INV_INTRANS_SHIP_UPDATE;

   PROCEDURE P_RC_INTRANS_AGED_ORDERS_MAIL
   AS
      lv_msg_from          VARCHAR2 (500) := 'remarketing-it@cisco.com';
      lv_msg_to            VARCHAR2 (500);
      lv_msg_subject       VARCHAR2 (32767);
      lv_msg_text          VARCHAR2 (32767);
      lv_output_hdr        CLOB;
      lv_count             NUMBER := 0;
      lv_output            CLOB;
      lv_output1           CLOB;
      lv_database_name     VARCHAR2 (50);
      lv_filename          VARCHAR2 (100);
      lv_report_run_date   VARCHAR2 (50);
      v_message            VARCHAR2 (500);
      v_msg                VARCHAR2 (500);
   BEGIN
      FOR REC IN (SELECT DISTINCT TO_ORG
                    FROM RC_INV_INTRANSIT_SHIPMENTS
                   WHERE STATUS_FLAG = 'Y' AND AGED_ORDER = 'Y')
      LOOP
         SELECT ora_database_name INTO lv_database_name FROM DUAL;

         SELECT MAX (
                   DISTINCT TO_CHAR (report_run_date,
                                     'MM/DD/YYYY HH:MI:SS AM'))
           INTO lv_report_run_date
           FROM RC_INV_INTRANSIT_SHIPMENTS
          WHERE     STATUS_FLAG = 'Y'
                AND AGED_ORDER = 'Y'
                AND TO_ORG = REC.TO_ORG;

         lv_filename :=
               'In Transit Aged Orders Report for '
            || rec.to_org
            || '_'
            || lv_report_run_date
            || ' PST';

         lv_msg_subject :=
               ' In Transit Aged Orders for '
            || rec.to_org
            || ' - '
            || lv_report_run_date
            || ' PST';

         IF (ora_database_name = 'FNTR2PRD.CISCO.COM')
         THEN
            lv_msg_subject := lv_msg_subject;

            SELECT EMAIL_RECIPIENTS
              INTO lv_msg_to
              FROM CRPADM.RC_EMAIL_NOTIFICATIONS
             WHERE NOTIFICATION_NAME =
                      'INTRANS_AGED_ORDERS_NOTIFY_PRD_' || rec.to_org || '';
         ELSIF (ora_database_name = 'FNTR2STG.CISCO.COM')
         THEN
            lv_msg_subject := 'STAGE : ' || lv_msg_subject;

            SELECT EMAIL_RECIPIENTS
              INTO lv_msg_to
              FROM CRPADM.RC_EMAIL_NOTIFICATIONS
             WHERE NOTIFICATION_NAME = 'INTRANS_AGED_ORDERS_NOTIFY_STG';
         ELSE
            lv_msg_subject := 'DEV : ' || lv_msg_subject;

            SELECT EMAIL_RECIPIENTS
              INTO lv_msg_to
              FROM CRPADM.RC_EMAIL_NOTIFICATIONS
             WHERE NOTIFICATION_NAME =
                      'INTRANS_AGED_ORDERS_NOTIFY_DEV_' || rec.to_org || '';
         --            lv_msg_to := 'sridvasu@cisco.com';

         END IF;

         --lv_msg_to:='jhegdeka@cisco.com';


         lv_msg_text :=
               '<HTML> Hi Team,'
            || '<br />'
            || '<br />'
            || 'Please find attached In Transit Aged Orders for '
            || rec.to_org
            || '.'
            || '<br /><br />'
            || 'PLEASE DO NOT REPLY... This is an Auto generated Email.'
            || '<br /><br /> '
            || 'Thanks,'
            || '<br />'
            || 'Refresh Central Support team </HTML>';


         lv_output_hdr :=
               'Part Number'
            || ','
            || 'Order Number'
            || ','
            || 'Shipment Number'
            || ','
            || 'From Org'
            || ','
            || 'To Org'
            || ','
            || 'To Sub Inv'
            || ','
            || 'Freight Carrier Code'
            || ','
            || 'Waybill'
            || ','
            || 'Shipped Quantity'
            || ','
            || 'Received Quantity'
            || ','
            || 'Pending Quantity'
            || ','
            || 'Shipped Date'
            || ','
            || 'Expected Received Date'
            || ','
            || 'Aged Days'
            || ','
            || 'Max Intransit Pads'
            || ','
            || 'Comments'
            || UTL_TCP.crlf;

         lv_count := 0;


         lv_output := NULL;

         lv_output1 := NULL;

         FOR rec1
            IN (SELECT part_number,
                       order_number,
                       shipment_number,
                       from_org,
                       to_org,
                       to_subinventory,
                       freight_code,
                       TO_CHAR (waybill_airbill_num) waybill_airbill_num,
                       shipped_quantity,
                       received_quantity,
                       pending_qty,
                       shipped_date,
                       expected_receipt_date,
                       days_pending,
                       max_intransit_pad,
                       comments
                  FROM rc_inv_intransit_shipments
                 WHERE     status_flag = 'Y'
                       AND aged_order = 'Y'
                       AND to_org = rec.to_org)
         LOOP
            IF lv_count = 0
            THEN
               lv_output :=
                     lv_output_hdr
                  || rec1.part_number
                  || ','
                  || rec1.order_number
                  || ','
                  || rec1.shipment_number
                  || ','
                  || rec1.from_org
                  || ','
                  || rec1.to_org
                  || ','
                  || rec1.to_subinventory
                  || ','
                  || rec1.freight_code
                  || ','
                  || '"'
                  || rec1.waybill_airbill_num
                  || '"'               -->> Added on 18th Apr 2018 by sridvasu
                  || ','
                  || rec1.shipped_quantity
                  || ','
                  || rec1.received_quantity
                  || ','
                  || rec1.pending_qty
                  || ','
                  || rec1.shipped_date
                  || ','
                  || rec1.expected_receipt_date
                  || ','
                  || rec1.days_pending
                  || ','
                  || rec1.max_intransit_pad
                  || ','
                  || rec1.comments
                  || ','
                  || UTL_TCP.crlf;
            ELSE
               BEGIN
                  lv_output1 :=
                        rec1.part_number
                     || ','
                     || rec1.order_number
                     || ','
                     || rec1.shipment_number
                     || ','
                     || rec1.from_org
                     || ','
                     || rec1.to_org
                     || ','
                     || rec1.to_subinventory
                     || ','
                     || rec1.freight_code
                     || ','
                     || '"'
                     || rec1.waybill_airbill_num
                     || '"'            -->> Added on 18th Apr 2018 by sridvasu
                     || ','
                     || rec1.shipped_quantity
                     || ','
                     || rec1.received_quantity
                     || ','
                     || rec1.pending_qty
                     || ','
                     || rec1.shipped_date
                     || ','
                     || rec1.expected_receipt_date
                     || ','
                     || rec1.days_pending
                     || ','
                     || rec1.max_intransit_pad
                     || ','
                     || rec1.comments
                     || ','
                     || UTL_TCP.crlf;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_msg := SUBSTR (SQLERRM, 1, 100);
               END;
            END IF;

            lv_count := lv_count + 1;

            lv_output := lv_output || lv_output1;
         --dbms_lob.append(lv_output, lv_output1);
         END LOOP;

         --lv_output:=lv_output||lv_output1;

         CRPADM.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (lv_msg_from,
                                                              lv_msg_to,
                                                              lv_msg_subject,
                                                              lv_msg_text,
                                                              lv_filename,
                                                              lv_output);
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message :=
               SUBSTR (SQLERRM, 1, 200)
            || ' -Line No. '
            || DBMS_UTILITY.Format_error_backtrace;

         P_RC_ERROR_LOG (
            I_module_name       => 'P_RC_INTRANS_AGED_ORDERS_MAIL',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while sending mail for In Transit Aged Orders '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => 'RC_INV_INTRANS_SHIPMENTS',
            I_updated_by        => 'RC_INV_INTRANS_SHIPMENTS');
   END P_RC_INTRANS_AGED_ORDERS_MAIL;

   --US198778 New Code Start
   PROCEDURE P_RC_INSERT_SONSORDER_STG_HIST
   IS
   BEGIN
      INSERT INTO RMKTGADM.RC_SONS_INTRANS_SHIP_STG_HIST (
                     SEQ_ID,
                     INVENTORY_ITEM_ID,
                     PART_NUMBER,
                     REFRESH_PID,
                     ORDER_NUMBER,
                     LINE_NUM,
                     ORDER_TYPE,
                     SHIPMENT_NUMBER,
                     FROM_ORGANIZATION_ID,
                     FROM_ORG,
                     TO_ORGANIZATION_ID,
                     TO_ORG,
                     FROM_SUB_INVENTORY,
                     TO_SUB_INVENTORY,
                     FREIGHT_CARRIER_CODE,
                     WAYBILL_AIRBILL_NUM,
                     SHIPPED_QUANTITY,
                     RECEIVED_QUANTITY,
                     PENDING_QTY,
                     SHIPPED_DATE,
                     EXPECTED_RECEIPT_DATE,
                     DAYS_PENDING,
                     MAX_TRANSIT_PAD,
                     AGED_ORDER,
                     COMMENTS,
                     STATUS_FLAG,
                     REPORT_RUN_DATE,
                     CREATED_ON,
                     CREATED_BY,
                     UPDATED_ON,
                     UPDATED_BY,
                     HISTORY_DATE)
         SELECT SEQ_ID,
                INVENTORY_ITEM_ID,
                PART_NUMBER,
                REFRESH_PID,
                ORDER_NUMBER,
                LINE_NUM,
                ORDER_TYPE,
                SHIPMENT_NUMBER,
                FROM_ORGANIZATION_ID,
                FROM_ORG,
                TO_ORGANIZATION_ID,
                TO_ORG,
                FROM_SUBINVENTORY,
                TO_SUBINVENTORY,
                FREIGHT_CARRIER_CODE,
                WAYBILL_AIRBILL_NUM,
                SHIPPED_QUANTITY,
                RECEIVED_QUANTITY,
                PENDING_QTY,
                SHIPPED_DATE,
                EXPECTED_RECEIPT_DATE,
                DAYS_PENDING,
                MAX_TRANSIT_PAD,
                AGED_ORDER,
                COMMENTS,
                STATUS_FLAG,
                REPORT_RUN_DATE,
                CREATED_ON,
                CREATED_BY,
                UPDATED_ON,
                UPDATED_BY,
                SYSDATE
           FROM RMKTGADM.RC_SONS_INTRANS_SHIPMTS_STG
          WHERE NVL (updated_on, created_on) >= v_start_date;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := SUBSTR (SQLERRM, 1, 200);

         P_RC_ERROR_LOG (
            I_module_name       => 'P_RC_INSERT_SONSORDER_STG_HIST',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => 'RC_INV_INTRANS_SHIPMENTS',
            I_updated_by        => 'RC_INV_INTRANS_SHIPMENTS');
   END;
--US198778 New Code End
END RC_INV_INTRANS_SHIPMENTS;
/