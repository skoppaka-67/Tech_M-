CREATE OR REPLACE PACKAGE BODY RMKTGADM."RC_INV_OPEN_DELIVERABLES_PKG"
AS
   G_START_TIME   DATE;

   /*
  ****************************************************************************************************************
  * Object Name       :RC_INV_OPEN_DELIVERABLES_PKG
  *  Project Name : Refresh Central
   * Copy Rights:   Cisco Systems, INC., CALIFORNIA
  * Description       : This API for Open Deliverables UI Report.
  * Created Date: 4th June, 2018
  ===================================================================================================+
  * Version              Date                     Modified by                     Description
  ===================================================================================================+
   1.0                   04th Jun 2018            sridvasu                     Created for Open Deliverables UI Report.
   1.1                   13th Jul 2018            sridvasu                     Enabled access for BPM to see all data

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
                                  := 'RMKTGADM.RC_INV_OPEN_DELIVERABLES_PKG';
      lv_error_msg             VARCHAR2 (800);
   BEGIN
      BEGIN
         SELECT CRON_STATUS
           INTO lv_cron_status
           FROM RMKTGADM.CRON_CONTROL_INFO
          WHERE     1 = 1
                AND CRON_NAME = 'P_RC_INV_OPEN_DELIVER_LOAD'
                AND CRON_CONTACT_ID = 'OPEN_DELIVERABLES';
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
             WHERE NOTIFICATION_NAME = 'RC_INV_OPEN_DELIVER_ALERT_PRD';
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
             WHERE NOTIFICATION_NAME = 'RC_INV_OPEN_DELIVER_ALERT_STG';
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
             WHERE NOTIFICATION_NAME = 'RC_INV_OPEN_DELIVER_ALERT_DEV';
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
         '<HTML> In Open Deliverables Report is currently running. Please wait to run it again. <HTML/>';

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
         P_RC_INV_OPEN_DELIVER_LOAD;
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
            i_Error_Message     =>    'Error getting while loading open deliverables UI table '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => 'RC_INV_OPEN_DELIVERABLES_PKG',
            I_updated_by        => 'RC_INV_OPEN_DELIVERABLES_PKG');
   END RC_INV_MAIN;

   PROCEDURE P_RC_INV_OPEN_DELIVER_LOAD
   AS
      lv_count   NUMBER;
   BEGIN
      SELECT SYSDATE INTO G_START_TIME FROM DUAL;

      -->> Start entry into control table

      UPDATE RMKTGADM.CRON_CONTROL_INFO
         SET CRON_STATUS = 'STARTED', CRON_START_TIMESTAMP = SYSDATE
       WHERE     CRON_NAME = 'P_RC_INV_OPEN_DELIVER_LOAD'
             AND CRON_CONTACT_ID = 'OPEN_DELIVERABLES';

      COMMIT;


      SELECT COUNT (1)
        INTO lv_count
        FROM RC_INV_OPEN_DELIVERABLES_STG
       WHERE STATUS_FLAG = 'Y';

      IF lv_count > 0
      THEN
         UPDATE RC_INV_OPEN_DELIVERABLES_UI
            SET STATUS_FLAG = 'N'
          WHERE STATUS_FLAG = 'Y';


         INSERT INTO RC_INV_OPEN_DELIVERABLES_UI (INVENTORY_ITEM_ID,
                                                  PART_NUMBER,
                                                  ORDER_NUMBER,
                                                  RMA_LINE_NUMBER,
                                                  SHIPMENT_NUMBER,
                                                  FROM_ORG,
                                                  FROM_SUB_INV,
                                                  CREATE_DATE,
                                                  SCHEDULED_DATE,
                                                  ORDER_STATUS,
                                                  ORDER_TYPE,
                                                  QUANTITY_REQUESTED,
                                                  QUANTITY_SHIPPED,
                                                  SOURCE_THEATER,
                                                  VENDOR,
                                                  RELEASED_STATUS,
                                                  STATUS_FLAG,
                                                  REPORT_RUN_DATE,
                                                  CREATED_ON,
                                                  CREATED_BY,
                                                  UPDATED_ON,
                                                  UPDATED_BY)
            SELECT INVENTORY_ITEM_ID,
                   PART_NUMBER,
                   ORDER_NUMBER,
                   RMA_LINE_NUMBER,
                   SHIPMENT_NUMBER,
                   FROM_ORG,
                   FROM_SUB_INV,
                   CREATE_DATE,
                   SCHEDULED_DATE,
                   ORDER_STATUS,
                   ORDER_TYPE,
                   QUANTITY_REQUESTED,
                   QUANTITY_SHIPPED,
                   SOURCE_THEATER,
                   VENDOR,
                   RELEASED_STATUS,
                   STATUS_FLAG,
                   REPORT_RUN_DATE,
                   CREATED_ON,
                   CREATED_BY,
                   UPDATED_ON,
                   UPDATED_BY
              FROM RC_INV_OPEN_DELIVERABLES_STG
             WHERE STATUS_FLAG = 'Y';

         -->> Updating Aged days in UI table

         UPDATE RC_INV_OPEN_DELIVERABLES_UI
            SET AGED_DAYS =
                   ROUND (
                        (SYSDATE - create_date)
                      - 2 * FLOOR ( (SYSDATE - create_date) / 7)
                      - DECODE (
                           SIGN (
                                TO_CHAR (SYSDATE, 'D')
                              - TO_CHAR (create_date, 'D')),
                           -1, 2,
                           0)
                      + DECODE (TO_CHAR (create_date, 'D'), 7, 1, 0)
                      - DECODE (TO_CHAR (SYSDATE, 'D'), 7, 1, 0))
          WHERE STATUS_FLAG = 'Y';

         -->> Marking Aged order deliveries in UI table

         UPDATE RC_INV_OPEN_DELIVERABLES_UI
            SET AGED_ORDER = CASE WHEN AGED_DAYS > 3 THEN 'Y' ELSE 'N' END
          WHERE STATUS_FLAG = 'Y';

         -->> Updating order type in UI table

         UPDATE RC_INV_OPEN_DELIVERABLES_UI
            SET ORDER_TYPE =
                   CASE
                      WHEN ORDER_TYPE LIKE 'SONS%' THEN 'SONS'
                      WHEN ORDER_TYPE LIKE 'INV TRANSFER-RMKT%' THEN 'IR'
                   END
          WHERE STATUS_FLAG = 'Y';

         -->> Updating To Org in UI table

         UPDATE RC_INV_OPEN_DELIVERABLES_UI
            SET TO_ORG =
                   CASE
                      WHEN FROM_ORG = 'Z05' THEN 'LRO'
                      WHEN FROM_ORG IN ('Z29', 'Z26') THEN 'FVE'
                   END
          WHERE STATUS_FLAG = 'Y' AND ORDER_TYPE = 'SONS';
      END IF;

      -->> Success entry into control table

      UPDATE RMKTGADM.CRON_CONTROL_INFO
         SET CRON_STATUS = 'SUCCESS', CRON_START_TIMESTAMP = SYSDATE
       WHERE     CRON_NAME = 'P_RC_INV_OPEN_DELIVER_LOAD'
             AND CRON_CONTACT_ID = 'OPEN_DELIVERABLES';

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := SUBSTR (SQLERRM, 1, 200);

         P_RC_ERROR_LOG (
            I_module_name       => 'P_RC_INV_OPEN_DELIVER_LOAD',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while loading Open Deliverables UI table '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => 'RC_INV_OPEN_DELIVERABLES_PKG',
            I_updated_by        => 'RC_INV_OPEN_DELIVERABLES_PKG');
   END P_RC_INV_OPEN_DELIVER_LOAD;


   PROCEDURE P_RC_INV_FROM_TO_ORG_SUBINV (
      I_LOGIN_USER               VARCHAR2,
      I_USER_ROLE                VARCHAR2,
      O_FROM_ORG             OUT T_FROM_ORG_TBL,
      O_TO_ORG               OUT T_TO_ORG_TBL,
      O_TO_SUBINV            OUT T_TO_SUBINV_TBL,
      I_FROM_ORG                 VARCHAR2,
      I_TO_ORG                   VARCHAR2,
      I_SUB_INV                  VARCHAR2,
      o_report_run_message   OUT VARCHAR2)
   AS
      lv_from_org             T_FROM_ORG_TBL;
      lv_to_org               T_TO_ORG_TBL;
      lv_to_subinv            T_TO_SUBINV_TBL;
      lv_report_run_date      VARCHAR2 (50);
      lv_report_run_message   VARCHAR2 (100);
      ltab_user_z_sites       RC_VARCHAR_TAB := RC_VARCHAR_TAB ();
      ltab_site_codes         VARCHAR2 (32767);
      lv_r_partner_id         NUMBER;
   BEGIN
      lv_from_org := T_FROM_ORG_TBL ();
      lv_to_org := T_TO_ORG_TBL ();
      lv_to_subinv := T_TO_SUBINV_TBL ();
      ltab_user_z_sites := RC_VARCHAR_TAB ();

      IF     i_login_user IS NOT NULL
         AND (    UPPER (i_user_role) NOT LIKE '%ADMIN%'
              AND UPPER (i_user_role) NOT LIKE '%BPM%') -->>  Enabled access for BPM to see all data on 13th Jul 2018 by sridvasu
      THEN
         --             BEGIN
         --                SELECT REPAIR_PARTNER_ID
         --                  INTO lv_r_partner_id
         --                  FROM crpadm.RC_REPAIR_PARTNER_USER_MAP
         --                 WHERE user_name = i_login_user;
         --             EXCEPTION
         --                WHEN OTHERS
         --                THEN
         --                   lv_r_partner_id := NULL;
         --             END;
         --
         --             IF lv_r_partner_id IS NOT NULL
         --             THEN
         IF UPPER (i_user_role) LIKE '%BTS%'
         THEN
              SELECT DISTINCT from_org
                BULK COLLECT INTO ltab_user_z_sites
                FROM rc_inv_open_deliverables_ui
               WHERE    from_org IN
                           (SELECT zcode from_org
                              FROM crpadm.rc_product_repair_partner RP
                                   INNER JOIN
                                   CRPADM.RC_REPAIR_PARTNER_USER_MAP USR
                                      ON RP.REPAIR_PARTNER_ID =
                                            USR.REPAIR_PARTNER_ID
                             WHERE     ZCODE IS NOT NULL
                                   AND RP.ACTIVE_FLAG = 'Y'
                                   AND USR.ACTIVE_FLAG = 'Y'
                                   AND ZCODE <> 'Z32'
                                   AND USER_NAME = i_login_user)
                     OR to_org IN
                           (SELECT BTS_SITE_NAME to_org
                              FROM CRPADM.RC_BTS_USER_MAP USR
                             WHERE     BTS_SITE_NAME IS NOT NULL
                                   AND USR.ACTIVE_FLAG = 'Y'
                                   AND USER_ID = i_login_user)
            --                                        WHERE     repair_partner_id = lv_r_partner_id
            --                                              AND active_flag = 'Y')
            GROUP BY from_org
            ORDER BY from_org; -->> Added on 09-MAY-2018 by sridvasu to display zsites in acending order
         ELSE
              SELECT DISTINCT from_org
                BULK COLLECT INTO ltab_user_z_sites
                FROM rc_inv_open_deliverables_ui
               WHERE from_org IN
                        (SELECT zcode from_org
                           FROM crpadm.rc_product_repair_partner RP
                                INNER JOIN
                                CRPADM.RC_REPAIR_PARTNER_USER_MAP USR
                                   ON RP.REPAIR_PARTNER_ID =
                                         USR.REPAIR_PARTNER_ID
                          WHERE     ZCODE IS NOT NULL
                                AND RP.ACTIVE_FLAG = 'Y'
                                AND USR.ACTIVE_FLAG = 'Y'
                                AND ZCODE <> 'Z32'
                                AND USER_NAME = i_login_user)
            --                                        WHERE     repair_partner_id = lv_r_partner_id
            --                                              AND active_flag = 'Y')
            GROUP BY from_org
            ORDER BY from_org; -->> Added on 09-MAY-2018 by sridvasu to display zsites in acending order
         END IF;
      ELSE
           SELECT DISTINCT from_org
             BULK COLLECT INTO ltab_user_z_sites
             FROM rc_inv_open_deliverables_ui
         ORDER BY from_org; -->> Added on 09-MAY-2018 by sridvasu to display zsites in acending order
      END IF;

      SELECT LISTAGG (COLUMN_VALUE, ',')
                WITHIN GROUP (ORDER BY COLUMN_VALUE, ',')
        INTO ltab_site_codes
        FROM TABLE (CAST (ltab_user_z_sites AS RC_VARCHAR_TAB));


      IF I_FROM_ORG IS NULL AND I_TO_ORG IS NULL AND I_SUB_INV IS NULL
      THEN
         SELECT T_FROM_ORG_OBJ (CONFIG_NAME)
           BULK COLLECT INTO lv_from_org
           FROM (  SELECT DISTINCT FROM_ORG CONFIG_NAME
                     FROM RC_INV_OPEN_DELIVERABLES_UI
                    WHERE     STATUS_FLAG = 'Y'
                          AND FROM_ORG IN
                                 (    SELECT DISTINCT
                                             REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                sites
                                        FROM DUAL
                                  CONNECT BY REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                IS NOT NULL)
                 ORDER BY FROM_ORG);

         SELECT T_TO_ORG_OBJ (ZCODE)
           BULK COLLECT INTO lv_to_org
           FROM (  SELECT DISTINCT TO_ORG ZCODE
                     FROM RC_INV_OPEN_DELIVERABLES_UI
                    WHERE     STATUS_FLAG = 'Y'
                          AND TO_ORG IS NOT NULL
                          AND FROM_ORG IN
                                 (    SELECT DISTINCT
                                             REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                sites
                                        FROM DUAL
                                  CONNECT BY REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                IS NOT NULL)
                 ORDER BY TO_ORG);

         SELECT T_TO_SUBINV_OBJ (SUB_INVENTORY_LOCATION)
           BULK COLLECT INTO lv_to_subinv
           FROM (  SELECT DISTINCT FROM_SUB_INV SUB_INVENTORY_LOCATION
                     FROM RC_INV_OPEN_DELIVERABLES_UI
                    WHERE     STATUS_FLAG = 'Y'
                          AND FROM_ORG IN
                                 (    SELECT DISTINCT
                                             REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                sites
                                        FROM DUAL
                                  CONNECT BY REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                IS NOT NULL)
                 ORDER BY FROM_SUB_INV);
      ELSIF I_FROM_ORG IS NOT NULL AND I_TO_ORG IS NULL AND I_SUB_INV IS NULL
      THEN
         SELECT T_TO_ORG_OBJ (ZCODE)
           BULK COLLECT INTO lv_to_org
           FROM (  SELECT DISTINCT TO_ORG ZCODE
                     FROM RC_INV_OPEN_DELIVERABLES_UI
                    WHERE     STATUS_FLAG = 'Y'
                          AND FROM_ORG = I_FROM_ORG
                          AND FROM_ORG IN
                                 (    SELECT DISTINCT
                                             REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                sites
                                        FROM DUAL
                                  CONNECT BY REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                IS NOT NULL)
                 ORDER BY TO_ORG);


         SELECT T_TO_SUBINV_OBJ (SUB_INVENTORY_LOCATION)
           BULK COLLECT INTO lv_to_subinv
           FROM (  SELECT DISTINCT FROM_SUB_INV SUB_INVENTORY_LOCATION
                     FROM RC_INV_OPEN_DELIVERABLES_UI
                    WHERE     STATUS_FLAG = 'Y'
                          AND FROM_ORG = I_FROM_ORG
                          AND FROM_ORG IN
                                 (    SELECT DISTINCT
                                             REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                sites
                                        FROM DUAL
                                  CONNECT BY REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                IS NOT NULL)
                 ORDER BY FROM_SUB_INV);
      ELSIF I_FROM_ORG IS NULL AND I_TO_ORG IS NOT NULL AND I_SUB_INV IS NULL
      THEN
         SELECT T_FROM_ORG_OBJ (CONFIG_NAME)
           BULK COLLECT INTO lv_from_org
           FROM (  SELECT DISTINCT FROM_ORG CONFIG_NAME
                     FROM RC_INV_OPEN_DELIVERABLES_UI
                    WHERE     STATUS_FLAG = 'Y'
                          AND FROM_ORG IN
                                 (    SELECT DISTINCT
                                             REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                sites
                                        FROM DUAL
                                  CONNECT BY REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                IS NOT NULL)
                          AND TO_ORG = I_TO_ORG
                 ORDER BY FROM_ORG);

         SELECT T_TO_SUBINV_OBJ (SUB_INVENTORY_LOCATION)
           BULK COLLECT INTO lv_to_subinv
           FROM (  SELECT DISTINCT FROM_SUB_INV SUB_INVENTORY_LOCATION
                     FROM RC_INV_OPEN_DELIVERABLES_UI
                    WHERE     STATUS_FLAG = 'Y'
                          AND TO_ORG = I_TO_ORG
                          AND FROM_ORG IN
                                 (    SELECT DISTINCT
                                             REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                sites
                                        FROM DUAL
                                  CONNECT BY REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                IS NOT NULL)
                 ORDER BY FROM_SUB_INV);
      ELSIF I_FROM_ORG IS NULL AND I_TO_ORG IS NULL AND I_SUB_INV IS NOT NULL
      THEN
         SELECT T_FROM_ORG_OBJ (CONFIG_NAME)
           BULK COLLECT INTO lv_from_org
           FROM (  SELECT DISTINCT FROM_ORG CONFIG_NAME
                     FROM RC_INV_OPEN_DELIVERABLES_UI
                    WHERE     STATUS_FLAG = 'Y'
                          AND FROM_ORG IN
                                 (    SELECT DISTINCT
                                             REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                sites
                                        FROM DUAL
                                  CONNECT BY REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                IS NOT NULL)
                          AND FROM_SUB_INV = I_SUB_INV
                 ORDER BY FROM_ORG);

         SELECT T_TO_ORG_OBJ (ZCODE)
           BULK COLLECT INTO lv_to_org
           FROM (  SELECT DISTINCT TO_ORG ZCODE
                     FROM RC_INV_OPEN_DELIVERABLES_UI
                    WHERE     STATUS_FLAG = 'Y'
                          AND FROM_SUB_INV = I_SUB_INV
                          AND TO_ORG IS NOT NULL
                          AND FROM_ORG IN
                                 (    SELECT DISTINCT
                                             REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                sites
                                        FROM DUAL
                                  CONNECT BY REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                IS NOT NULL)
                 ORDER BY TO_ORG);
      ELSIF     I_FROM_ORG IS NOT NULL
            AND I_TO_ORG IS NOT NULL
            AND I_SUB_INV IS NULL
      THEN
         SELECT T_TO_SUBINV_OBJ (SUB_INVENTORY_LOCATION)
           BULK COLLECT INTO lv_to_subinv
           FROM (  SELECT DISTINCT FROM_SUB_INV SUB_INVENTORY_LOCATION
                     FROM RC_INV_OPEN_DELIVERABLES_UI
                    WHERE     STATUS_FLAG = 'Y'
                          AND FROM_ORG = I_FROM_ORG
                          AND TO_ORG = I_TO_ORG
                          AND FROM_ORG IN
                                 (    SELECT DISTINCT
                                             REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                sites
                                        FROM DUAL
                                  CONNECT BY REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                IS NOT NULL)
                 ORDER BY FROM_SUB_INV);
      ELSIF     I_FROM_ORG IS NULL
            AND I_TO_ORG IS NOT NULL
            AND I_SUB_INV IS NOT NULL
      THEN
         SELECT T_FROM_ORG_OBJ (CONFIG_NAME)
           BULK COLLECT INTO lv_from_org
           FROM (  SELECT DISTINCT FROM_ORG CONFIG_NAME
                     FROM RC_INV_OPEN_DELIVERABLES_UI
                    WHERE     STATUS_FLAG = 'Y'
                          AND TO_ORG = I_TO_ORG
                          AND FROM_ORG IN
                                 (    SELECT DISTINCT
                                             REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                sites
                                        FROM DUAL
                                  CONNECT BY REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                IS NOT NULL)
                          AND FROM_SUB_INV = I_SUB_INV
                 ORDER BY FROM_ORG);
      ELSIF     I_FROM_ORG IS NOT NULL
            AND I_TO_ORG IS NULL
            AND I_SUB_INV IS NOT NULL
      THEN
         SELECT T_TO_ORG_OBJ (ZCODE)
           BULK COLLECT INTO lv_to_org
           FROM (  SELECT DISTINCT TO_ORG ZCODE
                     FROM RC_INV_OPEN_DELIVERABLES_UI
                    WHERE     STATUS_FLAG = 'Y'
                          AND FROM_ORG = I_FROM_ORG
                          AND FROM_SUB_INV = I_SUB_INV
                          AND TO_ORG IS NOT NULL
                          AND FROM_ORG IN
                                 (    SELECT DISTINCT
                                             REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                sites
                                        FROM DUAL
                                  CONNECT BY REGEXP_SUBSTR (ltab_site_codes,
                                                            '[^,]+',
                                                            1,
                                                            LEVEL)
                                                IS NOT NULL)
                 ORDER BY TO_ORG);
      END IF;


      BEGIN
         SELECT MAX (
                   DISTINCT TO_CHAR (report_run_date,
                                     'MM/DD/YYYY HH:MI:SS AM'))
           INTO lv_report_run_date
           FROM RC_INV_OPEN_DELIVERABLES_UI
          WHERE STATUS_FLAG = 'Y';
      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 200);
            DBMS_OUTPUT.put_line (v_message);
      END;



      lv_report_run_message :=
         'Open Deliverables report was generated on ' || lv_report_run_date;



      O_FROM_ORG := lv_from_org;
      O_TO_ORG := lv_to_org;
      O_TO_SUBINV := lv_to_subinv;
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
            I_created_by        => 'RC_INV_OPEN_DELIVERABLES_PKG',
            I_updated_by        => 'RC_INV_OPEN_DELIVERABLES_PKG');
   END P_RC_INV_FROM_TO_ORG_SUBINV;

   PROCEDURE P_RC_INV_OPEN_DELIVER_LOAD_UI (
      i_login_user                               VARCHAR2,
      i_user_role                                VARCHAR2,
      i_part_number                              VARCHAR2,
      i_order_number                             VARCHAR2,
      i_shipment_number                          VARCHAR2,
      i_from_org                                 VARCHAR2,
      i_to_org                                   VARCHAR2,
      i_to_subinv                                VARCHAR2,
      i_aged_order                               VARCHAR2,
      i_min_row                                  NUMBER,
      i_max_row                                  NUMBER,
      i_sort_column_name                         VARCHAR2,
      i_sort_column_by                           VARCHAR2,
      o_inv_open_deliver_data         OUT NOCOPY RC_INV_OPEN_DELIVER_TAB,
      o_inv_open_deliver_alldata      OUT NOCOPY RC_INV_OPEN_DELIVER_TAB,
      o_count                         OUT NOCOPY NUMBER)
   IS
      lv_query                      VARCHAR2 (32767);
      lv_data_query                 VARCHAR2 (32767);
      lv_cnt_query                  VARCHAR2 (32767);
      lv_inv_open_deliver_data      RC_INV_OPEN_DELIVER_TAB
                                       := RC_INV_OPEN_DELIVER_TAB ();
      lv_inv_open_deliver_alldata   RC_INV_OPEN_DELIVER_TAB
                                       := RC_INV_OPEN_DELIVER_TAB ();
      lv_count                      NUMBER;
      lv_sort_column_name           VARCHAR2 (100);
      lv_sort_column_by             VARCHAR2 (100);
      lv_min_row                    NUMBER;
      lv_max_row                    NUMBER;
      lv_part_number                VARCHAR2 (32767);
      lv_part_numbers               VARCHAR2 (32767);
      ltab_site_codes               VARCHAR2 (32767);
      lv_rp_site_codes              RC_VARCHAR_TAB := RC_VARCHAR_TAB ();
   BEGIN
      lv_sort_column_name := UPPER (TRIM (i_sort_column_name));
      lv_sort_column_by := UPPER (TRIM (i_sort_column_by));
      lv_min_row := TO_NUMBER (i_min_row);
      lv_max_row := TO_NUMBER (i_max_row);


      lv_cnt_query :=
         'SELECT COUNT(*) FROM RC_INV_OPEN_DELIVERABLES_UI WHERE STATUS_FLAG = ''Y''';


      lv_query :=
         'SELECT RC_INV_OPEN_DELIVER_OBJ (INVENTORY_ITEM_ID,
                                                PART_NUMBER,
                                                ORDER_NUMBER,
                                                RMA_LINE_NUMBER,
                                                SHIPMENT_NUMBER,
                                                FROM_ORG,
                                                FROM_SUB_INV,
                                                TO_ORG,
                                                CREATE_DATE,
                                                SCHEDULED_DATE,
                                                ORDER_STATUS,
                                                ORDER_TYPE,
                                                QUANTITY_REQUESTED,
                                                QUANTITY_SHIPPED,
                                                AGED_DAYS,
                                                AGED_ORDER,
                                                COMMENTS,
                                                SOURCE_THEATER,
                                                VENDOR,
                                                STATUS_FLAG,
                                                REPORT_RUN_DATE,
                                                CREATED_ON,
                                                CREATED_BY,
                                                UPDATED_ON,
                                                UPDATED_BY,
                                                V_ATTR1,
                                                V_ATTR2,
                                                V_ATTR3,
                                                N_ATTR1,
                                                N_ATTR2,
                                                N_ATTR3,
                                                D_ATTR1,
                                                D_ATTR2,
                                                D_ATTR3
                                              ) 
                FROM
                (SELECT /*+ opt_param(''optimizer_mode'',''first_rows_10'') */ * FROM 
                (SELECT
                    INVENTORY_ITEM_ID,
                    PART_NUMBER,
                    ORDER_NUMBER,
                    RMA_LINE_NUMBER,
                    SHIPMENT_NUMBER,
                    FROM_ORG,
                    FROM_SUB_INV,
                    TO_ORG,
                    CREATE_DATE,
                    SCHEDULED_DATE,
                    ORDER_STATUS,
                    ORDER_TYPE,
                    QUANTITY_REQUESTED,
                    QUANTITY_SHIPPED,
                    AGED_DAYS,
                    AGED_ORDER,
                    COMMENTS,
                    SOURCE_THEATER,
                    VENDOR,
                    STATUS_FLAG,
                    REPORT_RUN_DATE,
                    CREATED_ON,
                    CREATED_BY,
                    UPDATED_ON,
                    UPDATED_BY,
                    NULL V_ATTR1,
                    NULL V_ATTR2,
                    NULL V_ATTR3,
                    NULL N_ATTR1,
                    NULL N_ATTR2,
                    NULL N_ATTR3,
                    NULL D_ATTR1,
                    NULL D_ATTR2,
                    NULL D_ATTR3,';


      lv_data_query := lv_query;

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
                            FROM RC_INV_OPEN_DELIVERABLES_UI 
                            WHERE 1 = 1
                            AND STATUS_FLAG = ''Y''';

         lv_data_query :=
               lv_data_query
            || 'ROW_NUMBER()  OVER (ORDER BY '
            || lv_sort_column_name
            || ' '
            || lv_sort_column_by
            || ' ) AS rnum 
                            FROM RC_INV_OPEN_DELIVERABLES_UI 
                            WHERE 1 = 1
                            AND STATUS_FLAG = ''Y''';
      ELSE
         lv_query :=
               lv_query
            || 'ROW_NUMBER() OVER (ORDER BY AGED_ORDER DESC) AS rnum 
                            FROM RC_INV_OPEN_DELIVERABLES_UI 
                            WHERE 1 = 1
                            AND STATUS_FLAG = ''Y''';

         lv_data_query := lv_data_query || 'ROWNUM AS rnum 
                            FROM RC_INV_OPEN_DELIVERABLES_UI 
                            WHERE 1 = 1
                            AND STATUS_FLAG = ''Y''';
      END IF;



      BEGIN
         lv_rp_site_codes := F_GET_USER_ZSITES (i_login_user, i_user_role);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      IF lv_rp_site_codes.EXISTS (1)
      THEN
         SELECT LISTAGG (COLUMN_VALUE, ',')
                   WITHIN GROUP (ORDER BY COLUMN_VALUE, ',')
           INTO ltab_site_codes
           FROM TABLE (CAST (lv_rp_site_codes AS RC_VARCHAR_TAB));

         IF UPPER (i_user_role) LIKE '%BTS%'
         THEN
            lv_query :=
                  lv_query
               || 'AND FROM_ORG IN (SELECT DISTINCT REGEXP_SUBSTR ('''
               || ltab_site_codes
               || ''',
                                                                                                         ''[^,]+'',
                                                                                                         1,
                                                                                                         LEVEL)
                                                                                             sites
                                                                            FROM DUAL
                                                                      CONNECT BY REGEXP_SUBSTR ('''
               || ltab_site_codes
               || ''',
                                                                                                ''[^,]+'',
                                                                                                1,
                                                                                                LEVEL)
                                                                                    IS NOT NULL) AND TO_ORG IS NOT NULL';

            lv_data_query :=
                  lv_data_query
               || 'AND FROM_ORG IN (SELECT DISTINCT REGEXP_SUBSTR ('''
               || ltab_site_codes
               || ''',
                                                                                                         ''[^,]+'',
                                                                                                         1,
                                                                                                         LEVEL)
                                                                                             sites
                                                                            FROM DUAL
                                                                      CONNECT BY REGEXP_SUBSTR ('''
               || ltab_site_codes
               || ''',
                                                                                                ''[^,]+'',
                                                                                                1,
                                                                                                LEVEL)
                                                                                    IS NOT NULL)  AND TO_ORG IS NOT NULL';

            lv_cnt_query :=
                  lv_cnt_query
               || 'AND FROM_ORG IN (SELECT DISTINCT REGEXP_SUBSTR ('''
               || ltab_site_codes
               || ''',
                                                                                                         ''[^,]+'',
                                                                                                         1,
                                                                                                         LEVEL)
                                                                                             sites
                                                                            FROM DUAL
                                                                      CONNECT BY REGEXP_SUBSTR ('''
               || ltab_site_codes
               || ''',
                                                                                                ''[^,]+'',
                                                                                                1,
                                                                                                LEVEL)
                                                                                    IS NOT NULL)  AND TO_ORG IS NOT NULL';
         ELSE
            lv_query :=
                  lv_query
               || 'AND FROM_ORG IN (SELECT DISTINCT REGEXP_SUBSTR ('''
               || ltab_site_codes
               || ''',
                                                                                                         ''[^,]+'',
                                                                                                         1,
                                                                                                         LEVEL)
                                                                                             sites
                                                                            FROM DUAL
                                                                      CONNECT BY REGEXP_SUBSTR ('''
               || ltab_site_codes
               || ''',
                                                                                                ''[^,]+'',
                                                                                                1,
                                                                                                LEVEL)
                                                                                    IS NOT NULL)';

            lv_data_query :=
                  lv_data_query
               || 'AND FROM_ORG IN (SELECT DISTINCT REGEXP_SUBSTR ('''
               || ltab_site_codes
               || ''',
                                                                                                         ''[^,]+'',
                                                                                                         1,
                                                                                                         LEVEL)
                                                                                             sites
                                                                            FROM DUAL
                                                                      CONNECT BY REGEXP_SUBSTR ('''
               || ltab_site_codes
               || ''',
                                                                                                ''[^,]+'',
                                                                                                1,
                                                                                                LEVEL)
                                                                                    IS NOT NULL)';

            lv_cnt_query :=
                  lv_cnt_query
               || 'AND FROM_ORG IN (SELECT DISTINCT REGEXP_SUBSTR ('''
               || ltab_site_codes
               || ''',
                                                                                                         ''[^,]+'',
                                                                                                         1,
                                                                                                         LEVEL)
                                                                                             sites
                                                                            FROM DUAL
                                                                      CONNECT BY REGEXP_SUBSTR ('''
               || ltab_site_codes
               || ''',
                                                                                                ''[^,]+'',
                                                                                                1,
                                                                                                LEVEL)
                                                                                    IS NOT NULL)';
         END IF;
      ELSE
         lv_query := lv_query || ' AND 1=2 ';

         lv_data_query := lv_data_query || ' AND 1=2 ';

         lv_cnt_query := lv_cnt_query || 'AND 1=2 ';
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
                        FROM RC_INV_OPEN_DELIVERABLES_UI
                       WHERE UPPER (part_number) LIKE '%' || rec.part || '%'
                    GROUP BY part_number);

            IF lv_count > 0
            THEN
               lv_part_numbers := lv_part_numbers || ',' || lv_part_number;
            ELSE
               lv_part_numbers := lv_part_number;
            END IF;

            lv_count := lv_count + 1;

            DBMS_OUTPUT.put_line (lv_part_numbers);
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
            lv_query || ' AND FROM_SUB_INV = ''' || i_to_subinv || '''';

         lv_data_query :=
            lv_data_query || ' AND FROM_SUB_INV = ''' || i_to_subinv || '''';

         lv_cnt_query :=
            lv_cnt_query || ' AND FROM_SUB_INV = ''' || i_to_subinv || '''';
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

      -- For Sorting based on the user selection
      IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
      THEN
         lv_query :=
               lv_query
            || ' )) RC_OPEN_DELIVER WHERE rnum >='
            || i_min_row
            || ' AND rnum <='
            || i_max_row;

         lv_query :=
               lv_query
            || ' ORDER BY RC_OPEN_DELIVER.'
            || lv_sort_column_name
            || ' '
            || lv_sort_column_by;
      ELSE
         lv_query :=
               lv_query
            || ' ORDER BY AGED_ORDER DESC, CREATE_DATE DESC) WHERE rnum <= '
            || i_max_row
            || ') WHERE rnum >='
            || i_min_row;
      END IF;

      lv_data_query :=
         lv_data_query || ')) ORDER BY AGED_ORDER DESC, CREATE_DATE ASC';


      DBMS_OUTPUT.put_line (lv_query);
      DBMS_OUTPUT.put_line (lv_data_query);
      DBMS_OUTPUT.put_line (lv_cnt_query);

      BEGIN
         EXECUTE IMMEDIATE lv_query
            BULK COLLECT INTO lv_inv_open_deliver_data;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 200);

            P_RC_ERROR_LOG (
               I_module_name       => 'P_RC_INV_OPEN_DELIVER_LOAD_UI',
               I_entity_name       => NULL,
               I_entity_id         => NULL,
               I_ext_entity_name   => NULL,
               I_ext_entity_id     => NULL,
               I_error_type        => 'EXCEPTION',
               i_Error_Message     =>    'Error getting while executing open deliverables report '
                                      || ' <> '
                                      || v_message
                                      || ' LineNo=> '
                                      || DBMS_UTILITY.Format_error_backtrace,
               I_created_by        => 'RC_INV_OPEN_DELIVERABLES_PKG',
               I_updated_by        => 'RC_INV_OPEN_DELIVERABLES_PKG');
      END;


      BEGIN
         EXECUTE IMMEDIATE lv_data_query
            BULK COLLECT INTO lv_inv_open_deliver_alldata;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 200);

            P_RC_ERROR_LOG (
               I_module_name       => 'P_RC_INV_OPEN_DELIVER_LOAD_UI',
               I_entity_name       => NULL,
               I_entity_id         => NULL,
               I_ext_entity_name   => NULL,
               I_ext_entity_id     => NULL,
               I_error_type        => 'EXCEPTION',
               i_Error_Message     =>    'Error getting while executing open deliverables report '
                                      || ' <> '
                                      || v_message
                                      || ' LineNo=> '
                                      || DBMS_UTILITY.Format_error_backtrace,
               I_created_by        => 'RC_INV_OPEN_DELIVERABLES_PKG',
               I_updated_by        => 'RC_INV_OPEN_DELIVERABLES_PKG');
      END;


      BEGIN
         EXECUTE IMMEDIATE lv_cnt_query INTO lv_count;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 200);

            P_RC_ERROR_LOG (
               I_module_name       => 'P_RC_INV_OPEN_DELIVER_LOAD_UI',
               I_entity_name       => NULL,
               I_entity_id         => NULL,
               I_ext_entity_name   => NULL,
               I_ext_entity_id     => NULL,
               I_error_type        => 'EXCEPTION',
               i_Error_Message     =>    'Error getting while executing open deliverables report '
                                      || ' <> '
                                      || v_message
                                      || ' LineNo=> '
                                      || DBMS_UTILITY.Format_error_backtrace,
               I_created_by        => 'RC_INV_OPEN_DELIVERABLES_PKG',
               I_updated_by        => 'RC_INV_OPEN_DELIVERABLES_PKG');
      END;

      o_inv_open_deliver_data := lv_inv_open_deliver_data;

      o_inv_open_deliver_alldata := lv_inv_open_deliver_alldata;

      o_count := lv_count;
   END P_RC_INV_OPEN_DELIVER_LOAD_UI;

   PROCEDURE P_RC_OPEN_DELIVER_AGED_MAIL
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
      FOR REC IN (SELECT DISTINCT FROM_ORG
                    FROM RC_INV_OPEN_DELIVERABLES_UI
                   WHERE STATUS_FLAG = 'Y' AND AGED_ORDER = 'Y')
      LOOP
         SELECT ora_database_name INTO lv_database_name FROM DUAL;

         SELECT MAX (
                   DISTINCT TO_CHAR (report_run_date,
                                     'MM/DD/YYYY HH:MI:SS AM'))
           INTO lv_report_run_date
           FROM RC_INV_OPEN_DELIVERABLES_UI
          WHERE     STATUS_FLAG = 'Y'
                AND AGED_ORDER = 'Y'
                AND FROM_ORG = REC.FROM_ORG;

         lv_filename :=
               'Aged Open Deliveries for '
            || rec.from_org
            || '_'
            || lv_report_run_date
            || ' PST';

         lv_msg_subject :=
               'Aged Open Deliveries for '
            || rec.from_org
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
                      'REFRESH_SITE_NOTIFICATIONS_PRD_' || rec.from_org || '';
         ELSIF (ora_database_name = 'FNTR2STG.CISCO.COM')
         THEN
            lv_msg_subject := 'STAGE : ' || lv_msg_subject;

            SELECT EMAIL_RECIPIENTS
              INTO lv_msg_to
              FROM CRPADM.RC_EMAIL_NOTIFICATIONS
             WHERE NOTIFICATION_NAME =
                      'REFRESH_SITE_NOTIFICATIONS_STG_' || rec.from_org || '';
         ELSE
            lv_msg_subject := 'DEV : ' || lv_msg_subject;

            SELECT EMAIL_RECIPIENTS
              INTO lv_msg_to
              FROM CRPADM.RC_EMAIL_NOTIFICATIONS
             WHERE NOTIFICATION_NAME =
                      'REFRESH_SITE_NOTIFICATIONS_DEV_' || rec.from_org || '';
         --            lv_msg_to := 'sridvasu@cisco.com';

         END IF;

         --      lv_msg_to:='sridvasu@cisco.com,satbanda@cisco.com';


         lv_msg_text :=
               '<HTML> Hi Team,'
            || '<br />'
            || '<br />'
            || 'Please find attached Aged Open Deliveries for '
            || rec.from_org
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
            || 'Shipment Number/Delivery ID'
            || ','
            || 'From Org'
            || ','
            || 'From Sub Inv'
            || ','
            || 'To Org'
            || ','
            || 'Creation Date'
            || ','
            || 'Scheduled Date'
            || ','
            || 'Order Status'
            || ','
            || 'Order Type'
            || ','
            || 'Quantity Requested'
            || ','
            || 'Quantity Shipped'
            || ','
            || 'Aged Days'
            || ','
            || 'Aged Order'
            || UTL_TCP.crlf;

         lv_count := 0;


         lv_output := NULL;

         lv_output1 := NULL;

         FOR rec1
            IN (SELECT *
                  FROM rc_inv_open_deliverables_ui
                 WHERE     status_flag = 'Y'
                       AND aged_order = 'Y'
                       AND from_org = rec.from_org)
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
                  || rec1.from_sub_inv
                  || ','
                  || rec1.to_org
                  || ','
                  || rec1.create_date
                  || ','
                  || rec1.scheduled_date
                  || ','
                  || rec1.order_status
                  || ','
                  || rec1.order_type
                  || ','
                  || rec1.quantity_requested
                  || ','
                  || rec1.quantity_shipped
                  || ','
                  || rec1.aged_days
                  || ','
                  || rec1.aged_order
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
                     || rec1.from_sub_inv
                     || ','
                     || rec1.to_org
                     || ','
                     || rec1.create_date
                     || ','
                     || rec1.scheduled_date
                     || ','
                     || rec1.order_status
                     || ','
                     || rec1.order_type
                     || ','
                     || rec1.quantity_requested
                     || ','
                     || rec1.quantity_shipped
                     || ','
                     || rec1.aged_days
                     || ','
                     || rec1.aged_order
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
            I_module_name       => 'P_RC_OPEN_DELIVER_AGED_MAIL',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while sending mail for Open Deliverables Aged Orders '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => 'RC_INV_OPEN_DELIVERABLES_PKG',
            I_updated_by        => 'RC_INV_OPEN_DELIVERABLES_PKG');
   END P_RC_OPEN_DELIVER_AGED_MAIL;

   FUNCTION F_GET_USER_ZSITES (i_login_user   IN VARCHAR2,
                               i_user_role    IN VARCHAR2)
      RETURN RC_VARCHAR_TAB
   IS
      lv_r_partner_id     NUMBER;
      ltab_user_z_sites   RC_VARCHAR_TAB := RC_VARCHAR_TAB ();
      v_message           VARCHAR2 (32767);
   BEGIN
      IF     i_login_user IS NOT NULL
         AND (    UPPER (i_user_role) NOT LIKE '%ADMIN%'
              AND UPPER (i_user_role) NOT LIKE '%BPM%') -->>  Enabled access for BPM to see all data on 13th Jul 2018 by sridvasu
      THEN
         --             BEGIN
         --                SELECT REPAIR_PARTNER_ID
         --                  INTO lv_r_partner_id
         --                  FROM crpadm.RC_REPAIR_PARTNER_USER_MAP
         --                 WHERE user_name = i_login_user;
         --             EXCEPTION
         --                WHEN OTHERS
         --                THEN
         --                   lv_r_partner_id := NULL;
         --             END;
         --
         --             IF lv_r_partner_id IS NOT NULL
         --             THEN
         IF UPPER (i_user_role) LIKE '%BTS%'
         THEN
              SELECT DISTINCT from_org
                BULK COLLECT INTO ltab_user_z_sites
                FROM rc_inv_open_deliverables_ui
               WHERE    from_org IN
                           (SELECT zcode from_org
                              FROM crpadm.rc_product_repair_partner RP
                                   INNER JOIN
                                   CRPADM.RC_REPAIR_PARTNER_USER_MAP USR
                                      ON RP.REPAIR_PARTNER_ID =
                                            USR.REPAIR_PARTNER_ID
                             WHERE     ZCODE IS NOT NULL
                                   AND RP.ACTIVE_FLAG = 'Y'
                                   AND USR.ACTIVE_FLAG = 'Y'
                                   AND ZCODE <> 'Z32'
                                   AND USER_NAME = i_login_user)
                     OR to_org IN
                           (SELECT BTS_SITE_NAME to_org
                              FROM CRPADM.RC_BTS_USER_MAP USR
                             WHERE     BTS_SITE_NAME IS NOT NULL
                                   AND USR.ACTIVE_FLAG = 'Y'
                                   AND USER_ID = i_login_user)
            --                                        WHERE     repair_partner_id = lv_r_partner_id
            --                                              AND active_flag = 'Y')
            GROUP BY from_org
            ORDER BY from_org; -->> Added on 09-MAY-2018 by sridvasu to display zsites in acending order
         ELSE
              SELECT DISTINCT from_org
                BULK COLLECT INTO ltab_user_z_sites
                FROM rc_inv_open_deliverables_ui
               WHERE from_org IN
                        (SELECT zcode from_org
                           FROM crpadm.rc_product_repair_partner RP
                                INNER JOIN
                                CRPADM.RC_REPAIR_PARTNER_USER_MAP USR
                                   ON RP.REPAIR_PARTNER_ID =
                                         USR.REPAIR_PARTNER_ID
                          WHERE     ZCODE IS NOT NULL
                                AND RP.ACTIVE_FLAG = 'Y'
                                AND USR.ACTIVE_FLAG = 'Y'
                                AND ZCODE <> 'Z32'
                                AND USER_NAME = i_login_user)
            --                                        WHERE     repair_partner_id = lv_r_partner_id
            --                                              AND active_flag = 'Y')
            GROUP BY from_org
            ORDER BY from_org; -->> Added on 09-MAY-2018 by sridvasu to display zsites in acending order
         END IF;
      ELSE
           SELECT DISTINCT from_org
             BULK COLLECT INTO ltab_user_z_sites
             FROM rc_inv_open_deliverables_ui
         ORDER BY from_org; -->> Added on 09-MAY-2018 by sridvasu to display zsites in acending order
      END IF;


      RETURN ltab_user_z_sites;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := v_message || ' - ' || SUBSTR (SQLERRM, 1, 100);

         DBMS_OUTPUT.PUT_LINE (v_message);
   END F_GET_USER_ZSITES;
END RC_INV_OPEN_DELIVERABLES_PKG;
/