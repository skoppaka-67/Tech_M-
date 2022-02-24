CREATE OR REPLACE PACKAGE BODY CRPREP./*AppDB: 1041363*/           "RC_SCRAP_PART_REDUCTION" 

AS
    PROCEDURE RC_UPLOAD_SCRAP_DETAILS (
        i_user_id              IN     VARCHAR2,
        i_user_role            IN     VARCHAR2,
        i_scrap_details_list   IN     RC_SCRAP_DETAILS_LIST,
        i_excel_file           IN     BLOB,
        o_upload_status           OUT NUMBER)
    IS
        lv_scrap_details_list   RC_SCRAP_DETAILS_LIST;
        lv_err_msg              VARCHAR2 (1000);
        lv_user_id              VARCHAR2 (100);
        lv_last_name            VARCHAR2 (200);
        lv_first_name           VARCHAR2 (200);
        lv_status               NUMBER;
        lv_upload_seq           NUMBER;
    BEGIN
        lv_scrap_details_list := RC_SCRAP_DETAILS_LIST ();
        lv_scrap_details_list := i_scrap_details_list;
        lv_user_id := i_user_id;
        lv_status := 1;
        lv_first_name := NULL;
        lv_last_name := NULL;

        IF    lv_scrap_details_list IS NOT EMPTY
           OR lv_scrap_details_list IS NOT NULL
        THEN
            IF lv_scrap_details_list.COUNT > 0
            THEN
                FOR idx IN 1 .. lv_scrap_details_list.COUNT
                LOOP
                    --            IF lv_scrap_details_list (idx).PART_NUMBER IS NOT NULL
                    --            THEN
                    INSERT INTO RC_SCRAP_REDUCTION
                         VALUES (lv_scrap_details_list (idx).PART_NUMBER,
                                 lv_scrap_details_list (idx).QTY_TO_REDUCE,
                                 SYSDATE,
                                 lv_user_id);
                --                                 END IF;
                END LOOP;

                COMMIT;
            END IF;

            BEGIN
                SELECT LAST_NAME, FIRST_NAME
                  INTO lv_last_name, lv_first_name
                  FROM SBTFADM.EMP
                 WHERE CS_EMAIL_ADDR = i_user_id;
            EXCEPTION
                WHEN OTHERS
                THEN
                    lv_last_name := ' ';
                    lv_first_name := ' ';
            END;

            SELECT CRPADM.UPLOAD_ID_SEQ.NEXTVAL INTO lv_upload_seq FROM DUAL;

            INSERT INTO CRPADM.RC_GU_PRODUCT_REFRESH_SETUP (UPDATED_BY,
                                                            IMPORTED_DATA,
                                                            UPDATED_ON,
                                                            ACTIVE_FLAG,
                                                            MODULE,
                                                            USER_NAME,
                                                            USER_EMAIL,
                                                            USER_ROLE,
                                                            UPLOAD_ID,
                                                            EXCEL_FILE)
                 VALUES (i_user_id,
                         NULL,
                         SYSDATE,
                         'R',
                         'SCRAP_REDUCTION',
                         lv_first_name || ' ' || lv_last_name,
                         i_user_id || '@cisco.com',
                         i_user_role,
                         lv_upload_seq,
                         i_excel_file);

            COMMIT;
        END IF;

        IF lv_status = 1
        THEN
            o_upload_status := lv_upload_seq;
        END IF;


        /* For Bell Notification in RC Home*/

        INSERT INTO CRPADM.RC_JOBS_NOTIFICATION_HISTORY (NOTIFICATION_ID,
                                                         TIME_STAMP,
                                                         STATUS)
             VALUES (13, SYSDATE, 'successful');



        /* Log the process END timestamp */
        INSERT INTO CRPADM.RC_PROCESS_LOG
             VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                     'CRPREP.RC_SCRAP_PART_REDUCTION',
                     'END',
                     SYSDATE);

        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            lv_status := 0;
            lv_err_msg :=
                   SUBSTR (SQLERRM, 1, 200)
                || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
            CRPADM.RC_GLOBAL_ERROR_LOGGING (
                'OTHERS',
                lv_err_msg,
                NULL,
                'CRPADM.RC_SCRAP_PART_REDUCTION.RC_UPLOAD_SCRAP_DETAILS',
                'PACKAGE',
                lv_user_id,
                'Y');


            --Insert into job notification table for notifying the failure
            INSERT INTO CRPADM.RC_JOBS_NOTIFICATION_HISTORY (NOTIFICATION_ID,
                                                             TIME_STAMP,
                                                             STATUS)
                 VALUES (13, SYSDATE, 'failed');

            COMMIT;
    END;

    PROCEDURE RC_SCRAP_DATA_EXTRACT (
        i_user_id                 VARCHAR2,
        i_min                     NUMBER,
        i_max                     NUMBER,
        o_execution_date      OUT VARCHAR2,
        o_total_row_count     OUT NUMBER,
        o_scrap_reduce_list   OUT RC_SCRAP_REDUCE_LIST)
    IS
        lv_scrap_reduce_list   RC_SCRAP_REDUCE_LIST;
        lv_execution_date      DATE;
        lv_err_msg             VARCHAR2 (1000);
    BEGIN
        lv_scrap_reduce_list := RC_SCRAP_REDUCE_LIST ();

        SELECT RC_SCRAP_REDUCE_OBJ (PART_NUMBER,
                                    SITE,
                                    LOCATION,
                                    QUANTITY)
          BULK COLLECT INTO lv_scrap_reduce_list
          FROM (SELECT PART_NUMBER,
                       SITE,
                       LOCATION,
                       QUANTITY
                  FROM (  SELECT PART_NUMBER,
                                 SITE,
                                 LOCATION,
                                 QUANTITY,
                                 ROW_NUMBER ()
                                 OVER (
                                     ORDER BY
                                         UPLD_COMMON_PART_NUMBER, priority ASC)
                                     RNUM
                            FROM RC_SCRAP_REDUCTION_OUTPUT
                        ORDER BY UPLD_COMMON_PART_NUMBER, priority)
                 WHERE RNUM > i_min AND RNUM <= i_max);

        SELECT MAX (EXECUTION_DATE)
          INTO lv_execution_date
          FROM RC_SCRAP_REDUCTION_OUTPUT;

        SELECT COUNT (*)
          INTO o_total_row_count
          FROM RC_SCRAP_REDUCTION_OUTPUT;

        o_execution_date :=
            TO_CHAR (lv_execution_date, 'mm/dd/yyyy hh:mi:ss AM');
        o_scrap_reduce_list := lv_scrap_reduce_list;
    EXCEPTION
        WHEN OTHERS
        THEN
            lv_err_msg :=
                   SUBSTR (SQLERRM, 1, 200)
                || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
            CRPADM.RC_GLOBAL_ERROR_LOGGING (
                'OTHERS',
                lv_err_msg,
                NULL,
                'CRPADM.RC_SCRAP_PART_REDUCTION.RC_SCRAP_DATA_EXTRACT',
                'PACKAGE',
                i_user_id,
                'Y');
    END;

    PROCEDURE RC_SCRAP_REDUCTION_CALC (i_upload_id IN NUMBER)
    IS
        lv_err_msg             VARCHAR2 (1000);
        lv_upload_id           NUMBER;
        lv_status              NUMBER;
        cust_exception         EXCEPTION;

        PRAGMA EXCEPTION_INIT (cust_exception, -20001);

        TYPE RC_SCRAP_REDUCTION_OBJ IS RECORD
        (
            PART_NUMBER      VARCHAR2 (500),
            QTY_TO_REDUCE    NUMBER
        );

        TYPE RC_SCRAP_REDUCTION_LIST IS TABLE OF RC_SCRAP_REDUCTION_OBJ;

        TYPE RC_QTY_AVAILABLE_OBJ IS RECORD
        (
            PART_NUMBER    VARCHAR2 (500),
            SITE           VARCHAR2 (500),
            LOCATION       VARCHAR2 (500),
            QUANTITY       NUMBER
        );

        TYPE RC_QTY_AVAILABLE_LIST IS TABLE OF RC_QTY_AVAILABLE_OBJ;

        lv_scrap_reduction     RC_SCRAP_REDUCTION_LIST;
        lv_qty_available       RC_QTY_AVAILABLE_LIST;
        lv_part_number         VARCHAR2 (500);
        lv_rf_part_number      VARCHAR2 (500);
        lv_ws_part_number      VARCHAR2 (500);
        lv_mfg_part_number     VARCHAR2 (500);
        lv_spare_part_number   VARCHAR2 (500);
        lv_qty_to_scrap        NUMBER;
        lv_count               NUMBER;
        lv_count_2             NUMBER;
        lv_part_number_2       VARCHAR2 (500);

        CURSOR c_qty_avilable (
            lv_part_number    VARCHAR2)
        IS
              SELECT PART_NUMBER,
                     INV.SITE,
                     INV.LOCATION,
                     QUANTITY
                FROM (  SELECT PART_NUMBER,
                               SITE,
                               LOCATION,
                               SUM (QTY_ON_HAND) QUANTITY
                          FROM CRPADM.RC_INV_BTS_C3_MV
                         WHERE     1 = 1
                               AND SITE NOT LIKE
                                       'Z32 - TELEPLAN SERVICE SOLUTIONS ASIA B.V.'
                      GROUP BY PART_NUMBER, SITE, LOCATION) INV
                     INNER JOIN RC_SCRAP_LOCATION_PRIORITY LOC
                         ON INV.LOCATION = LOC.SUB_INVENTORY_LOCATION
                     INNER JOIN RC_SCRAP_SITE_PRIORITY SIT
                         ON     INV.SITE = SIT.SITE
                            AND INV.PART_NUMBER IN (lv_part_number)
                            AND NOT EXISTS
                                    (SELECT 1
                                       FROM RC_SCRAP_REDUCTION_OUTPUT_STG a
                                      WHERE     a.part_number = INV.PART_NUMBER
                                            AND a.LOCATION = INV.LOCATION
                                            AND a.QUANTITY = QUANTITY
                                            AND a.site = site)
            ORDER BY LOC.PRIORITY, SIT.PRIORITY; ----removed part number in group by to fix FG showing to scrap when DG is present

        CURSOR c_qty_avilable_fg (
            lv_rf_part_number    VARCHAR2,
            lv_ws_part_number    VARCHAR2)
        IS
              SELECT PART_NUMBER,
                     INV.SITE,
                     INV.LOCATION,
                     QUANTITY
                FROM (  SELECT PART_NUMBER,
                               SITE,
                               LOCATION,
                               SUM (QTY_ON_HAND) QUANTITY
                          FROM CRPADM.RC_INV_BTS_C3_MV
                         WHERE     1 = 1
                               AND SITE NOT LIKE
                                       'Z32 - TELEPLAN SERVICE SOLUTIONS ASIA B.V.'
                      GROUP BY PART_NUMBER, SITE, LOCATION) INV
                     INNER JOIN RC_SCRAP_LOCATION_PRIORITY LOC
                         ON INV.LOCATION = LOC.SUB_INVENTORY_LOCATION
                     INNER JOIN RC_SCRAP_SITE_PRIORITY SIT
                         ON     INV.SITE = SIT.SITE
                            AND INV.PART_NUMBER IN
                                    (lv_rf_part_number, lv_ws_part_number)
                            AND NOT EXISTS
                                    (SELECT 1
                                       FROM RC_SCRAP_REDUCTION_OUTPUT_STG a
                                      WHERE     a.part_number = INV.PART_NUMBER
                                            AND a.LOCATION = INV.LOCATION
                                            AND a.QUANTITY = QUANTITY
                                            AND a.site = site)
            ORDER BY LOC.PRIORITY, SIT.PRIORITY;
    BEGIN
        lv_upload_id := i_upload_id;
        lv_status := 1;

        INSERT INTO RC_SCRAP_REDUCTION_HISTORY (PART_NUMBER,
                                                LOCATION,
                                                SITE,
                                                QUANTITY,
                                                HISTORY_DATE,
                                                PRIORITY,
                                                UPLD_COMMON_PART_NUMBER)
            (SELECT PART_NUMBER,
                    LOCATION,
                    SITE,
                    QUANTITY,
                    execution_DATE,
                    PRIORITY,
                    UPLD_COMMON_PART_NUMBER
               FROM RC_SCRAP_REDUCTION_OUTPUT);

        EXECUTE IMMEDIATE 'TRUNCATE TABLE RC_SCRAP_REDUCTION_OUTPUT_STG';

        SELECT COUNT (*) INTO lv_count FROM RC_SCRAP_REDUCTION_HISTORY;

        IF lv_count > 0
        THEN
              SELECT PART_NUMBER, SUM (QTY_TO_REDUCE)
                BULK COLLECT INTO lv_scrap_reduction
                FROM CRPREP.RC_SCRAP_REDUCTION
               WHERE UPLOADED_DATE >
                     (SELECT MAX (HISTORY_DATE) FROM RC_SCRAP_REDUCTION_HISTORY)
            GROUP BY PART_NUMBER;
        ELSE
              SELECT PART_NUMBER, SUM (QTY_TO_REDUCE)
                BULK COLLECT INTO lv_scrap_reduction
                FROM CRPREP.RC_SCRAP_REDUCTION
            GROUP BY PART_NUMBER;
        END IF;



        FOR master_idx IN 1 .. lv_scrap_reduction.COUNT
        LOOP
            lv_part_number := lv_scrap_reduction (master_idx).PART_NUMBER;
            lv_qty_to_scrap := lv_scrap_reduction (master_idx).QTY_TO_REDUCE;
            lv_count_2 := 0;

            IF (lv_qty_to_scrap > 0)
            THEN
                IF NOT (c_qty_avilable%ISOPEN)
                THEN
                    OPEN c_qty_avilable (lv_part_number);
                END IF;

                LOOP
                    FETCH c_qty_avilable
                        BULK COLLECT INTO lv_qty_available
                        LIMIT 1000;


                    FOR idx1 IN 1 .. lv_qty_available.COUNT ()
                    LOOP
                        IF (    lv_qty_to_scrap > 0
                            AND lv_qty_available (idx1).QUANTITY > 0)
                        THEN
                            IF (lv_qty_to_scrap <=
                                lv_qty_available (idx1).QUANTITY)
                            THEN
                                INSERT INTO CRPREP.RC_SCRAP_REDUCTION_OUTPUT_STG (
                                                UPLD_COMMON_PART_NUMBER,
                                                PART_NUMBER,
                                                LOCATION,
                                                SITE,
                                                QUANTITY,
                                                EXECUTION_DATE)
                                         VALUES (
                                                    lv_part_number,
                                                    lv_qty_available (idx1).PART_NUMBER,
                                                    lv_qty_available (idx1).LOCATION,
                                                    lv_qty_available (idx1).SITE,
                                                    lv_qty_to_scrap,
                                                    SYSDATE);

                                COMMIT;
                                lv_qty_to_scrap := 0;
                            ELSE
                                INSERT INTO CRPREP.RC_SCRAP_REDUCTION_OUTPUT_STG (
                                                UPLD_COMMON_PART_NUMBER,
                                                PART_NUMBER,
                                                LOCATION,
                                                SITE,
                                                QUANTITY,
                                                EXECUTION_DATE)
                                         VALUES (
                                                    lv_part_number,
                                                    lv_qty_available (idx1).PART_NUMBER,
                                                    lv_qty_available (idx1).LOCATION,
                                                    lv_qty_available (idx1).SITE,
                                                    lv_qty_available (idx1).QUANTITY,
                                                    SYSDATE);

                                COMMIT;
                                lv_qty_to_scrap :=
                                      lv_qty_to_scrap
                                    - lv_qty_available (idx1).QUANTITY;
                            END IF;
                        END IF;
                    END LOOP;

                    EXIT WHEN c_qty_avilable%NOTFOUND;
                END LOOP;

                CLOSE c_qty_avilable;
            END IF;



            IF (lv_qty_to_scrap > 0)
            THEN
                IF NOT (c_qty_avilable%ISOPEN)
                THEN
                    lv_part_number_2 := ' ';

                    SELECT DECODE (SUBSTR (lv_part_number, -1, 1),
                                   '=', REPLACE (lv_part_number, '='),
                                   CONCAT (lv_part_number, '='))
                      INTO lv_part_number_2
                      FROM DUAL;

                    OPEN c_qty_avilable (lv_part_number_2);
                END IF;

                LOOP
                    FETCH c_qty_avilable
                        BULK COLLECT INTO lv_qty_available
                        LIMIT 1000;


                    FOR idx1 IN 1 .. lv_qty_available.COUNT ()
                    LOOP
                        IF (    lv_qty_to_scrap > 0
                            AND lv_qty_available (idx1).QUANTITY > 0)
                        THEN
                            IF (lv_qty_to_scrap <=
                                lv_qty_available (idx1).QUANTITY)
                            THEN
                                INSERT INTO CRPREP.RC_SCRAP_REDUCTION_OUTPUT_STG (
                                                UPLD_COMMON_PART_NUMBER,
                                                PART_NUMBER,
                                                LOCATION,
                                                SITE,
                                                QUANTITY,
                                                EXECUTION_DATE)
                                         VALUES (
                                                    lv_part_number,
                                                    lv_qty_available (idx1).PART_NUMBER,
                                                    lv_qty_available (idx1).LOCATION,
                                                    lv_qty_available (idx1).SITE,
                                                    lv_qty_to_scrap,
                                                    SYSDATE);

                                COMMIT;
                                lv_qty_to_scrap := 0;
                            ELSE
                                INSERT INTO CRPREP.RC_SCRAP_REDUCTION_OUTPUT_STG (
                                                UPLD_COMMON_PART_NUMBER,
                                                PART_NUMBER,
                                                LOCATION,
                                                SITE,
                                                QUANTITY,
                                                EXECUTION_DATE)
                                         VALUES (
                                                    lv_part_number,
                                                    lv_qty_available (idx1).PART_NUMBER,
                                                    lv_qty_available (idx1).LOCATION,
                                                    lv_qty_available (idx1).SITE,
                                                    lv_qty_available (idx1).QUANTITY,
                                                    SYSDATE);

                                COMMIT;
                                lv_qty_to_scrap :=
                                      lv_qty_to_scrap
                                    - lv_qty_available (idx1).QUANTITY;
                            END IF;
                        END IF;
                    END LOOP;

                    EXIT WHEN c_qty_avilable%NOTFOUND;
                END LOOP;

                CLOSE c_qty_avilable;
            END IF;



            IF (lv_qty_to_scrap > 0)
            THEN
                lv_rf_part_number := ' ';
                lv_ws_part_number := ' ';
                lv_mfg_part_number := ' ';
                lv_spare_part_number := ' ';



                --To get the all types of products for the provided part_number
                SELECT COUNT (*)
                  INTO lv_count_2
                  FROM CRPADM.RC_PRODUCT_MASTER
                 WHERE (   COMMON_PART_NUMBER = LV_PART_NUMBER
                        OR XREF_PART_NUMBER = LV_PART_NUMBER);

                IF lv_count_2 > 0
                THEN
                    BEGIN
                        SELECT REFRESH_PART_NUMBER,
                               COMMON_PART_NUMBER,
                               XREF_PART_NUMBER
                          INTO lv_rf_part_number,
                               lv_mfg_part_number,
                               lv_spare_part_number
                          FROM CRPADM.RC_PRODUCT_MASTER
                         WHERE     (   COMMON_PART_NUMBER = LV_PART_NUMBER
                                    OR XREF_PART_NUMBER = LV_PART_NUMBER)
                               AND PROGRAM_TYPE = 0;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            lv_mfg_part_number := lv_part_number;
                    END;

                    BEGIN
                        SELECT REFRESH_PART_NUMBER,
                               COMMON_PART_NUMBER,
                               XREF_PART_NUMBER
                          INTO lv_ws_part_number,
                               lv_mfg_part_number,
                               lv_spare_part_number
                          FROM CRPADM.RC_PRODUCT_MASTER
                         WHERE     (   COMMON_PART_NUMBER = LV_PART_NUMBER
                                    OR XREF_PART_NUMBER = LV_PART_NUMBER)
                               AND PROGRAM_TYPE = 1;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            lv_mfg_part_number := lv_part_number;
                    END;
                END IF;

                IF NOT (c_qty_avilable_fg%ISOPEN)
                THEN
                    OPEN c_qty_avilable_fg (lv_rf_part_number,
                                            lv_ws_part_number);
                END IF;

                LOOP
                    FETCH c_qty_avilable_fg
                        BULK COLLECT INTO lv_qty_available
                        LIMIT 1000;


                    FOR idx1 IN 1 .. lv_qty_available.COUNT ()
                    LOOP
                        IF (    lv_qty_to_scrap > 0
                            AND lv_qty_available (idx1).QUANTITY > 0)
                        THEN
                            IF (lv_qty_to_scrap <=
                                lv_qty_available (idx1).QUANTITY)
                            THEN
                                INSERT INTO CRPREP.RC_SCRAP_REDUCTION_OUTPUT_STG (
                                                UPLD_COMMON_PART_NUMBER,
                                                PART_NUMBER,
                                                LOCATION,
                                                SITE,
                                                QUANTITY,
                                                EXECUTION_DATE)
                                         VALUES (
                                                    lv_part_number,
                                                    lv_qty_available (idx1).PART_NUMBER,
                                                    lv_qty_available (idx1).LOCATION,
                                                    lv_qty_available (idx1).SITE,
                                                    lv_qty_to_scrap,
                                                    SYSDATE);

                                COMMIT;
                                lv_qty_to_scrap := 0;
                            ELSE
                                INSERT INTO CRPREP.RC_SCRAP_REDUCTION_OUTPUT_STG (
                                                UPLD_COMMON_PART_NUMBER,
                                                PART_NUMBER,
                                                LOCATION,
                                                SITE,
                                                QUANTITY,
                                                EXECUTION_DATE)
                                         VALUES (
                                                    lv_part_number,
                                                    lv_qty_available (idx1).PART_NUMBER,
                                                    lv_qty_available (idx1).LOCATION,
                                                    lv_qty_available (idx1).SITE,
                                                    lv_qty_available (idx1).QUANTITY,
                                                    SYSDATE);

                                COMMIT;
                                lv_qty_to_scrap :=
                                      lv_qty_to_scrap
                                    - lv_qty_available (idx1).QUANTITY;
                            END IF;
                        END IF;
                    END LOOP;

                    EXIT WHEN c_qty_avilable_fg%NOTFOUND;
                END LOOP;

                CLOSE c_qty_avilable_fg;
            END IF;
        END LOOP;

        UPDATE RC_SCRAP_REDUCTION_OUTPUT_STG
           SET priority =
                   (SELECT priority
                      FROM RC_SCRAP_LOCATION_PRIORITY
                     WHERE location = sub_inventory_location);

        BEGIN
            EXECUTE IMMEDIATE 'TRUNCATE TABLE RC_SCRAP_REDUCTION_OUTPUT';

            INSERT INTO RC_SCRAP_REDUCTION_OUTPUT (PART_NUMBER,
                                                   LOCATION,
                                                   SITE,
                                                   QUANTITY,
                                                   EXECUTION_DATE,
                                                   PRIORITY,
                                                   UPLD_COMMON_PART_NUMBER)
                (SELECT PART_NUMBER,
                        LOCATION,
                        SITE,
                        QUANTITY,
                        EXECUTION_DATE,
                        PRIORITY,
                        UPLD_COMMON_PART_NUMBER
                   FROM RC_SCRAP_REDUCTION_OUTPUT_STG);

            COMMIT;
        EXCEPTION
            WHEN OTHERS
            THEN
                lv_status := 0;
                lv_err_msg :=
                       SUBSTR (SQLERRM, 1, 200)
                    || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
                CRPADM.RC_GLOBAL_ERROR_LOGGING (
                    'OTHERS',
                    lv_err_msg,
                    NULL,
                    'CRPADM.RC_SCRAP_PART_REDUCTION.RC_SCRAP_REDUCTION_CALC',
                    'PACKAGE',
                    NULL,
                    'Y');

                GLOBAL_UPLOADER_EMAIL (lv_upload_id, lv_status);
                raise_application_error (-20001,
                                         'Exception in Scrap Reduction Calc');
        END;

        GLOBAL_UPLOADER_EMAIL (lv_upload_id, lv_status);
    EXCEPTION
        WHEN OTHERS
        THEN
            lv_status := 0;
            lv_err_msg :=
                   SUBSTR (SQLERRM, 1, 200)
                || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
            CRPADM.RC_GLOBAL_ERROR_LOGGING (
                'OTHERS',
                lv_err_msg,
                NULL,
                'CRPADM.RC_SCRAP_PART_REDUCTION.RC_SCRAP_REDUCTION_CALC',
                'PACKAGE',
                NULL,
                'Y');

            GLOBAL_UPLOADER_EMAIL (lv_upload_id, lv_status);
            raise_application_error (-20001,
                                     'Exception in Scrap Reduction Calc');
    END RC_SCRAP_REDUCTION_CALC;

    PROCEDURE GLOBAL_UPLOADER_EMAIL (i_uploadId   IN NUMBER,
                                     i_status     IN NUMBER)
    AS
        lv_user_id         VARCHAR2 (50);
        lv_username        VARCHAR2 (100);
        lv_uploadId        NUMBER;

        g_error_msg        VARCHAR2 (2000);
        lv_msg_from        VARCHAR2 (500);
        lv_msg_to          VARCHAR2 (500);
        lv_msg_subject     VARCHAR2 (32767);
        lv_msg_body        VARCHAR2 (32767);
        lv_msg_text        VARCHAR2 (32767);
        lv_output_hdr      LONG;
        lv_mailhost        VARCHAR2 (100) := 'outbound.cisco.com';
        lv_conn            UTL_SMTP.CONNECTION;
        lv_message_type    VARCHAR2 (100) := 'text/html; charset="iso-8859-1"';
        lv_crlf            VARCHAR2 (5) := CHR (13) || CHR (10);
        lv_count           NUMBER := 0;
        lv_output          LONG;
        lv_database_name   VARCHAR2 (50);
        lv_status          NUMBER;
    BEGIN
        lv_uploadId := i_uploadId;
        lv_status := i_status;

        SELECT ora_database_name INTO lv_database_name FROM DUAL;

        SELECT UPDATED_BY, USER_NAME, USER_EMAIL
          INTO lv_user_id, lv_username, lv_msg_to
          FROM CRPADM.RC_GU_PRODUCT_REFRESH_SETUP
         WHERE UPLOAD_ID = lv_uploadId;

        lv_msg_from := 'refreshcentral-support@cisco.com';

        IF (lv_status = 0)
        THEN
            lv_msg_subject :=
                   'Processing not completed due to exception for Upload Id: '
                || lv_uploadId;
            lv_msg_body :=
                'Processing not completed due to exception, please try again.';
        ELSIF (lv_status = 1)
        THEN
            lv_msg_subject :=
                   'Processing completed successfully for Upload Id: '
                || lv_uploadId;
            lv_msg_body :=
                'Processing completed successfully, please check Scrap Reduction Report for latest details.';
        ELSE
            lv_msg_subject :=
                   'Processing completed successfully for Upload Id: '
                || lv_uploadId;
            lv_msg_body :=
                'Processing completed successfully, Scrap Reduction data has been refreshed with manual upload.';
        END IF;

        IF (ora_database_name = 'FNTR2DEV.CISCO.COM')
        THEN
            lv_msg_subject := 'DEV : ' || lv_msg_subject;
        ELSIF (ora_database_name = 'FNTR2STG.CISCO.COM')
        THEN
            lv_msg_subject := 'STAGE : ' || lv_msg_subject;
        ELSE
            lv_msg_subject := lv_msg_subject;
        END IF;

        lv_msg_text :=
               ' <HTML> Hi '
            || lv_username
            || ','
            || '<br /><br /> '
            || CHR (10)
            || CHR (10)
            || lv_msg_body
            || CHR (10)
            || CHR (10)
            || '<br /><br /> '
            || 'PLEASE DO NOT REPLY .. This is an Auto generated Email. '
            || CHR (10)
            || CHR (10)
            || '<br /><br /> '
            || '<br /><br /> '
            || 'Thanks & Regards,'
            || '<br />'
            || 'Refresh Central Support team </HTML>';

        -- Open the SMTP connection ...
        lv_conn := UTL_SMTP.OPEN_CONNECTION (lv_mailhost, 25);
        UTL_SMTP.HELO (lv_conn, lv_mailhost);
        UTL_SMTP.MAIL (lv_conn, lv_msg_from);
        UTL_SMTP.RCPT (lv_conn, lv_msg_to);

        -- Open data
        UTL_SMTP.OPEN_DATA (lv_conn);

        -- Message info
        UTL_SMTP.WRITE_DATA (lv_conn, 'To: ' || lv_msg_to || lv_crlf);
        UTL_SMTP.WRITE_DATA (lv_conn, 'From: ' || lv_msg_from || lv_crlf);
        UTL_SMTP.WRITE_DATA (lv_conn,
                             'Subject: ' || lv_msg_subject || lv_crlf);
        UTL_SMTP.WRITE_DATA (lv_conn, 'MIME-Version: 1.0' || lv_crlf);
        UTL_SMTP.WRITE_DATA (
            lv_conn,
               'Content-Type: multipart/mixed; boundary="SECBOUND"'
            || lv_crlf
            || ' boundary="SECBOUND"'
            || lv_crlf);

        -- Message body
        UTL_SMTP.WRITE_DATA (lv_conn, '--SECBOUND' || lv_crlf);
        UTL_SMTP.WRITE_DATA (
            lv_conn,
               'Content-Type: text/html;'
            || lv_crlf
            || 'Content-Transfer_Encoding: 8bit'
            || lv_crlf
            || lv_message_type
            || lv_crlf
            || lv_crlf);

        UTL_SMTP.WRITE_DATA (lv_conn, lv_msg_text || lv_crlf); --||'Content-Transfer_Encoding: 7bit'|| lv_crlf);

        -- Close data
        UTL_SMTP.CLOSE_DATA (lv_conn);
        UTL_SMTP.QUIT (lv_conn);
    EXCEPTION
        WHEN OTHERS
        THEN
            g_error_msg :=
                   SUBSTR (SQLERRM, 1, 200)
                || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
            CRPADM.RC_GLOBAL_ERROR_LOGGING ('OTHERS',
                                            g_error_msg,
                                            NULL,
                                            'GLOBAL_UPLOADER_EMAIL',
                                            'PROCEDURE',
                                            lv_user_id,
                                            'N');
    END GLOBAL_UPLOADER_EMAIL;
END RC_SCRAP_PART_REDUCTION;
/