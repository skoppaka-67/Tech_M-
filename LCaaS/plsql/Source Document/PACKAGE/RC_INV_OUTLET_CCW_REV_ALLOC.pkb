CREATE OR REPLACE PACKAGE BODY RMKTGADM./*AppDB: 1030339*/                                                                   "RC_INV_OUTLET_CCW_REV_ALLOC" 
IS
   /*===================================================================================================+
     |                                 Cisco Systems, INC., CALIFORNIA                                   |
     +====================================================================================================+
     | Object Name    RMKTGADM.RC_INV_OUTLET_CCW_REV_ALLOC
     |
     | Module        :

     | Description   :
     |
     | Revision History:
     | -----------------
     | Date        Updated By                               Bug/Case#                  Rev   Comments
     |==========  ================                         ===========                ==== ================================================
     | #######     mohamms2(Mohammed reyaz Shaik)               ACT                    1.0  Created                                                                |
     | 11-JAN-2018   mohamms2(Mohammed Reyaz Shaik)          User story# US159221         1.1  As part of Sprint#18 Release resticted to run if it aleady ran in 90mins |
     | 28-NOV-2018   sridvasu(Sridevi Vasudevan)                                       1.2  Added SF table to consider M2 Forecast PIDs |
     | 05-JAN-2018   hkarka (Hanish Karka)                                             1.3 PID restriction for M2/M3 is no more required
     | 11-FEB-2021   sumravik(Sumesh Ravikumar)             User Story# US456837       1.4 Added backup tables for delta outlet user story 
      =================================================================================================== */

   G_ERROR_MSG    VARCHAR2 (300);
   G_PROC_NAME    VARCHAR2 (100);
   G_START_TIME   DATE;
 

   /*Start added below procedure as part of user story# US159221 to Restrict Outlet Reverse allocation   as part of Sprint#18 on 11-Jan-18*/
 PROCEDURE RC_INV_MAIN
   IS
      LV_CHL_END_TIME_STAMP    TIMESTAMP;
      LV_CHL_CNT               NUMBER;
      LV_SUBJECT               VARCHAR2 (150);
      LV_MSG_CONTENT           VARCHAR2 (600);
      LV_DATABASE_NAME         VARCHAR2 (300);
      LV_MAIL_TO               VARCHAR2 (100);
      LV_DEV_MAIL_RECEIPENTS   VARCHAR2 (100);
      LV_STG_MAIL_RECEIPENTS   VARCHAR2 (100);
      LV_PRD_MAIL_RECEIPENTS   VARCHAR2 (100);
      LV_MSG_BODY              VARCHAR2 (300);
      LV_MAIL_SENDER           VARCHAR2 (100);
      LV_MAIL_FROM             VARCHAR2 (100);
      LV_PKG_NAME              VARCHAR2 (100) := 'RMKTGADM.RC_INV_OUTLET_CCW_REV_ALLOC';
      LV_ERROR_MSG             VARCHAR2 (800);
--      LV_ERROR_CONTENT         VARCHAR2 (800);
--      LV_ERR_SUBJECT           VARCHAR2 (100);
--      LV_PROC_NAME             VARCHAR2 (100) := 'RC_INV_MAIN';
      LV_REV_REALLOC_TIME      NUMBER;
   BEGIN
      --NULL;
      
      BEGIN
      SELECT CONFIG_ID
        INTO LV_REV_REALLOC_TIME
        FROM RMKTGADM.RC_INV_CONFIG
       WHERE CONFIG_NAME = 'REV_REALLOC_RESTRICT'
         AND CONFIG_TYPE = 'CCW_REV_REALLOC';
      EXCEPTION  
         WHEN OTHERS
         THEN
            LV_ERROR_MSG :=
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
      END;


      BEGIN
         SELECT COUNT (1)
           INTO LV_CHL_CNT
           FROM RMKTGADM.CRON_HISTORY_LOG CHL
          WHERE     1 = 1
                AND CHL.CHL_CRON_NAME in ('RC_INV_OUTLET_CCW_PROCESS','RC_INV_OUTLET_CCW_REVERSE')
                AND CHL.CHL_CREATED_BY in ('RC_INV_OUTLET_CCW_REALLOC','RC_INV_OUTLET_CCW_REV_ALLOC')
                AND CHL.CHL_START_TIMESTAMP >= SYSDATE - LV_REV_REALLOC_TIME / (24 * 60);
      EXCEPTION
         WHEN OTHERS
         THEN
            LV_ERROR_MSG :=
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
      END;

      IF LV_CHL_CNT >= 1
      THEN
         BEGIN
            SELECT CHL.CHL_END_TIMESTAMP
              INTO LV_CHL_END_TIME_STAMP
              FROM RMKTGADM.CRON_HISTORY_LOG CHL
             WHERE     1 = 1
                   AND CHL.CHL_CRON_NAME in ('RC_INV_OUTLET_CCW_PROCESS','RC_INV_OUTLET_CCW_REVERSE')
                AND CHL.CHL_CREATED_BY in ('RC_INV_OUTLET_CCW_REALLOC','RC_INV_OUTLET_CCW_REV_ALLOC')
                   AND CHL.CHL_START_TIMESTAMP >= SYSDATE - LV_REV_REALLOC_TIME / (24 * 60);
         EXCEPTION
            WHEN OTHERS
            THEN
               LV_ERROR_MSG :=
                     SUBSTR (SQLERRM, 1, 200)
                  || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         END;
      END IF;

           
         
    BEGIN    
    SELECT ORA_DATABASE_NAME INTO LV_DATABASE_NAME FROM DUAL; 
    EXCEPTION
    WHEN OTHERS
            THEN
               LV_ERROR_MSG :=
                     SUBSTR (SQLERRM, 1, 200)
                  || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
    END;
      
    LV_SUBJECT :=
         'Warning - ' || LV_PKG_NAME || '  package Warning message';
 

      IF (ORA_DATABASE_NAME = 'FNTR2DEV.CISCO.COM')
      THEN
         BEGIN
            SELECT EMAIL_SENDER, EMAIL_RECIPIENTS
              INTO LV_MAIL_SENDER, LV_DEV_MAIL_RECEIPENTS
              FROM CRPADM.RC_EMAIL_NOTIFICATIONS
             WHERE NOTIFICATION_NAME = 'RC_INV_REVALLOC_ALERT_DEV';
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
             WHERE NOTIFICATION_NAME = 'RC_INV_REVALLOC_ALERT_STG';
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
             WHERE NOTIFICATION_NAME = 'RC_INV_REVALLOC_ALERT_PRD';
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

      

      LV_MSG_BODY :=
            '<HTML><b> Outlet Reverse/Re-Allocation</b> has been run at
                 <HTML/> <b>'
         || TO_CHAR (LV_CHL_END_TIME_STAMP, 'DD-MM-YYYY HH:MI:SS AM')
         || ' PST </b> <HTML/>'
         || '<HTML> please wait for <b>' ||LV_REV_REALLOC_TIME ||' </b> minutes to run it again. <HTML/>';

      LV_MSG_CONTENT :=
            '<HTML>Hello,<br /><br /> Warning Message from <b> '
         || SUBSTR (LV_PKG_NAME, 1, 37)
         || '</b> Package.
        <br/>
        <br/>
        <font color="red"><b>Warning Message : </b></font> '
         || LV_MSG_BODY
         || ' <br /><br />
        <br /> Thanks '
         || CHR (38)
         || ' Regards, <br />
        Cisco Refresh Support Team               
      </HTML>';



      IF LV_CHL_CNT = 0
      
      THEN
         RC_INV_OUTLET_CCW_REVERSE;
         
      ELSIF LV_CHL_CNT >= 1
      
      THEN
         CRPADM.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (LV_MAIL_FROM, 
                                                              LV_MAIL_TO, 
                                                              LV_SUBJECT, 
                                                              LV_MSG_CONTENT, 
                                                              NULL, 
                                                              NULL);
                                                      
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         --  ROLLBACK;
         LV_ERROR_MSG :=
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
                      'RC_INV_MAIN',
                      LV_ERROR_MSG,
                      'RC_INV_OUTLET_CCW_REALLOC');


         COMMIT;
   END RC_INV_MAIN;

   /*End added procedure as part of user story# US159221 to Restrict Outlet Reverse allocation   as part of Sprint#18 on 11-Jan-18*/

   PROCEDURE RC_INV_OUTLET_CCW_REVERSE
   IS
   TRUNC_RMK_INV_MASTER1   VARCHAR2 (32767)
            := 'TRUNCATE TABLE RMKTGADM.RC_XXCPO_RMK_INV_MSTR_B4_RALLOC';
      CURSOR REV_OUTLET IS
            SELECT *
              FROM xxcpo_rmk_inventory_master im
             WHERE     inventory_flow = 'Outlet'
                   AND available_to_reserve_fgi > 0
                   AND im.part_number =
                       (SELECT refresh_part_number
                          FROM crpadm.rc_product_master pm
                         WHERE     pm.refresh_part_number = im.part_number
                               AND pm.refresh_part_number =
                                   (SELECT refresh_part_number
                                      FROM crpsc.RC_AE_FGI_REQUIREMENT fgi
                                     WHERE fgi.refresh_part_number =
                                           pm.refresh_part_number)); ---(SELECT rf_pid FROM crpsc.rc_m2_sales_forecast m2 WHERE m2.rf_pid = im.part_number); -->> Added to consider M2 Forecast PIDs on 28-Nov-2018 by sridvasu

      REV_OUT   REV_OUTLET%ROWTYPE;
   BEGIN
      SELECT SYSDATE INTO G_START_TIME FROM DUAL;
      
      EXECUTE IMMEDIATE TRUNC_RMK_INV_MASTER1;
        
        INSERT INTO RC_XXCPO_RMK_INV_MSTR_B4_RALLOC (
                        INVENTORY_MASTER_ID,
                        PART_NUMBER,
                        AVAILABLE_FGI,
                        NEW_FGI,
                        AVAILABLE_DGI,
                        NEW_DGI,
                        AVAILABLE_TO_RESERVE_FGI,
                        AVAILABLE_TO_RESERVE_DGI,
                        RESERVED_FGI,
                        RESERVED_DGI,
                        SITE_CODE,
                        ROHS_COMPLIANT,
                        AUTO_RESERVATION_FLAG,
                        CREATED_ON,
                        CREATED_BY,
                        UPDATED_ON,
                        UPDATED_BY,
                        PROCESS_NAME,
                        INVENTORY_FLOW)
            (SELECT INVENTORY_MASTER_ID,
                    PART_NUMBER,
                    AVAILABLE_FGI,
                    NEW_FGI,
                    AVAILABLE_DGI,
                    NEW_DGI,
                    AVAILABLE_TO_RESERVE_FGI,
                    AVAILABLE_TO_RESERVE_DGI,
                    RESERVED_FGI,
                    RESERVED_DGI,
                    SITE_CODE,
                    ROHS_COMPLIANT,
                    AUTO_RESERVATION_FLAG,
                    CREATED_ON,
                    CREATED_BY,
                    UPDATED_ON,
                    UPDATED_BY,
                    PROCESS_NAME,
                    INVENTORY_FLOW
               FROM XXCPO_RMK_INVENTORY_MASTER);

        COMMIT;

      DELETE FROM RMKTGADM.REV_OUTLET_ALLOC;

      DELETE FROM RMKTGADM.RC_INV_REVERSE_OUTLET;

      COMMIT;

      OPEN REV_OUTLET;

      LOOP
         FETCH REV_OUTLET INTO REV_OUT;

         EXIT WHEN REV_OUTLET%NOTFOUND;

         INSERT INTO RMKTGADM.REV_OUTLET_ALLOC
              VALUES (REV_OUT.PART_NUMBER,
                      REV_OUT.AVAILABLE_TO_RESERVE_FGI,
                      REV_OUT.SITE_CODE,
                      REV_OUT.ROHS_COMPLIANT,
                      REV_OUT.INVENTORY_FLOW);

         INSERT INTO RMKTGADM.RC_INV_REVERSE_OUTLET (INVENTORY_LOG_ID,
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
                      REV_OUT.part_number,
                      REV_OUT.Available_To_Reserve_FGI,
                      0,
                      REV_OUT.Rohs_Compliant,
                      REV_OUT.Site_Code,
                      'N',
                      SYSDATE,
                      'POEADMIN',
                      SYSDATE,
                      'POEADMIN',
                      'RC_INV_OUTLET_CCW_REVERSE',
                      'R');

         INSERT INTO RMKTGADM.RC_INV_REVERSE_OUTLET (INVENTORY_LOG_ID,
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
                      REV_OUT.part_number,
                      REV_OUT.Available_To_Reserve_FGI * -1,
                      0,
                      REV_OUT.Rohs_Compliant,
                      REV_OUT.Site_Code,
                      'N',
                      SYSDATE,
                      'POEADMIN',
                      SYSDATE,
                      'POEADMIN',
                      'RC_INV_OUTLET_CCW_REVERSE',
                      'O');
      END LOOP;

      CLOSE REV_OUTLET;

      INSERT INTO RMKTGADM.RC_INV_REVERSE_OUTLET_HIST
         SELECT * FROM RMKTGADM.RC_INV_REVERSE_OUTLET;


      INSERT INTO RMKTGADM.RMK_INVENTORY_LOG
         SELECT *
           FROM RMKTGADM.RC_INV_REVERSE_OUTLET; -- DELETE FROM RC_INV_REVERSE_OUTLET;
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
                   G_START_TIME,
                   SYSDATE,
                   'RC_INV_OUTLET_CCW_REVERSE',
                   NULL,
                   'RC_INV_OUTLET_CCW_REV_ALLOC');

      G_PROC_NAME := 'RC_INV_OUTLET_CCW_REVERSE';
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
                      'RC_INV_OUTLET_CCW_REV_ALLOC');

         --  G_PROC_NAME := 'RC_INV_OUTLET_CCW_REVERSE';

         COMMIT;
   END RC_INV_OUTLET_CCW_REVERSE;
END RC_INV_OUTLET_CCW_REV_ALLOC;
/