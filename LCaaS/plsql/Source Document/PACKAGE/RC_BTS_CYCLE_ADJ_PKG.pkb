CREATE OR REPLACE PACKAGE BODY RMKTGADM./*AppDB: 1045363*/             "RC_BTS_CYCLE_ADJ_PKG" 

AS
   /*
  ****************************************************************************************************************
  * Object Name       :RC_BTS_CYCLE_ADJ_PKG
  *  Project Name : Refresh Central
   * Copy Rights:   Cisco Systems, INC., CALIFORNIA
  * Description       : This API for BTS cycle count Adjustment
  * Created Date:  29th,Jan 2018
  ===================================================================================================+
  * Version              Date                     Modified by                     Description
  ===================================================================================================+
   1.0                  29th,Jan 2018            satbanda                     Created for  BTS cycle count Adjustment
   1.1                  14th,Mar 2018            satbanda                     Modified for Pack-Out quantity validation
  ===================================================================================================+
   **************************************************************************************************************** */
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
         -- Log Exception
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

   PROCEDURE P_BTS_DATA_UPLOAD (
      i_bts_cycle_data_tab   IN            RC_BTS_CYCLE_DATA_TAB,
      i_upload_id            IN            VARCHAR2,
      i_site_code            IN            VARCHAR2,                 --LRO/FVE
      i_login_user           IN            VARCHAR2,
      o_process_err_msg         OUT NOCOPY RC_INV_MESSAGE_TAB,
      o_status                  OUT NOCOPY VARCHAR2)
   IS
      ltab_bts_data_tab     RC_BTS_CYCLE_DATA_TAB := RC_BTS_CYCLE_DATA_TAB ();

      TYPE bts_data_tab IS TABLE OF RC_BTS_CYCLE_UPLOAD_DATA%ROWTYPE;

      lv_unmatched_cnt      NUMBER;
      v_message             VARCHAR2 (4000);
      lv_process_err_tab    RC_INV_MESSAGE_TAB := RC_INV_MESSAGE_TAB ();
      lv_record_num         NUMBER := 0;
      lv_unmatched_rec      VARCHAR2 (32767);
      lv_dataExists_flag    VARCHAR2 (3) := 'NO';
      lv_upld_rec_cnt       NUMBER := 0;
      lv_bts_files          VARCHAR2 (4000);
      lv_site_code          VARCHAR2 (5);
      lv_invalid_data_cnt   NUMBER;
      lv_status             VARCHAR2 (20) := 'SUCCESS';
      lv_file_name          VARCHAR2 (500);
      lv_upload_id          VARCHAR2 (100);
      lv_part_exists_cnt    NUMBER;
      lv_err_count          NUMBER := 0;

      CURSOR data_cur
      IS
         SELECT *
           FROM TABLE (CAST (ltab_bts_data_tab AS RC_BTS_CYCLE_DATA_TAB));
   BEGIN
      ltab_bts_data_tab := i_bts_cycle_data_tab;
      lv_unmatched_cnt := 0;
      lv_site_code := TRIM (i_site_code);
      lv_upload_id := TRIM (i_upload_id);

      IF ltab_bts_data_tab.EXISTS (1) AND lv_site_code IS NOT NULL
      THEN
         BEGIN
            SELECT COUNT (1)
              INTO lv_invalid_data_cnt
              FROM TABLE (CAST (ltab_bts_data_tab AS RC_BTS_CYCLE_DATA_TAB)) tab_data
             WHERE tab_data.SITE_ID != lv_site_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_invalid_data_cnt := 0;
         END;


         IF lv_invalid_data_cnt <> 0
         THEN
            v_message :=
                  'Please provide correct site id: '
               || lv_site_code
               || ' in file data';

            lv_process_err_tab.EXTEND;

            lv_err_count := lv_err_count + 1;

            lv_process_err_tab (lv_err_count) :=
               RC_INV_MESSAGE_OBJ ('BTS_ADJ',
                                   NULL,
                                   NULL,
                                   NULL,
                                   'ERROR',
                                   v_message);
            lv_status := 'ERROR';
            GOTO return_process;
         END IF;

         lv_upld_rec_cnt := ltab_bts_data_tab.COUNT;

         BEGIN
              SELECT LISTAGG (v_attr1, ',')
                        WITHIN GROUP (ORDER BY v_attr1, ',')
                INTO lv_bts_files
                FROM rc_bts_cycle_upload_data
               WHERE TRUNC (UPLOADED_DATE) = TRUNC (SYSDATE)
            GROUP BY v_attr1
              HAVING COUNT (*) = lv_upld_rec_cnt;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lv_bts_files := NULL;
            WHEN OTHERS
            THEN
               lv_bts_files := NULL;
         END;


         IF lv_bts_files IS NOT NULL
         THEN
            FOR rec IN (    SELECT DISTINCT REGEXP_SUBSTR (lv_bts_files,
                                                           '[^,]+',
                                                           1,
                                                           LEVEL)
                                               file_name
                              FROM DUAL
                        CONNECT BY REGEXP_SUBSTR (lv_bts_files,
                                                  '[^,]+',
                                                  1,
                                                  LEVEL)
                                      IS NOT NULL)
            LOOP
               BEGIN
                  SELECT DECODE (COUNT (1), 0, 'YES', 'NO')
                    INTO lv_dataExists_flag
                    FROM TABLE (
                            CAST (ltab_bts_data_tab AS RC_BTS_CYCLE_DATA_TAB)) tab_data
                   WHERE NOT EXISTS
                                (SELECT 1
                                   FROM rc_bts_cycle_upload_data rbc
                                  WHERE     1 = 1  --rbc.v_attr1=rec.file_name
                                        AND refresh_part_number =
                                               tab_data.refresh_part_number
                                        AND tan_id = tab_data.tan_id
                                        AND site_id = tab_data.site_id
                                        AND cycle_rohs_cnt =
                                               tab_data.cycle_rohs_cnt
                                        AND cycle_nrohs_cnt =
                                               tab_data.cycle_nrohs_cnt
                                        AND ifs_rohs_cnt =
                                               tab_data.ifs_rohs_cnt
                                        AND ifs_nrohs_cnt =
                                               tab_data.ifs_nrohs_cnt
                                        AND TRUNC (uploaded_date) =
                                               TRUNC (SYSDATE));
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_message := SUBSTR (SQLERRM, 1, 100);

                     P_RCEC_ERROR_LOG (
                        I_module_name       => 'P_BTS_DATA_UPLOAD',
                        I_entity_name       => NULL,
                        I_entity_id         => NULL,
                        I_ext_entity_name   => NULL,
                        I_ext_entity_id     => NULL,
                        I_error_type        => 'EXCEPTION',
                        i_Error_Message     =>    'Error getting while executing P_BTS_DATA_UPLOAD '
                                               || ' <> '
                                               || v_message
                                               || ' LineNo=> '
                                               || DBMS_UTILITY.Format_error_backtrace,
                        I_created_by        => i_login_user,
                        I_updated_by        => i_login_user);
               END;

               IF lv_dataExists_flag = 'YES'
               THEN
                  v_message :=
                     'Same data has been uploaded today, please upload different data';

                  lv_process_err_tab.EXTEND;
                  lv_err_count := lv_err_count + 1;
                  lv_process_err_tab (lv_err_count) :=
                     RC_INV_MESSAGE_OBJ ('BTS_ADJ',
                                         NULL,
                                         NULL,
                                         NULL,
                                         'ERROR',
                                         v_message);
                  EXIT;
               END IF;
            END LOOP;


            IF lv_dataExists_flag = 'YES'
            THEN
               lv_status := 'ERROR';
               GOTO return_process;
            END IF;
         END IF;

         SELECT COUNT (1)
           INTO lv_unmatched_cnt
           FROM TABLE (CAST (ltab_bts_data_tab AS RC_BTS_CYCLE_DATA_TAB)) tab_data
          WHERE NOT EXISTS
                       (SELECT 1
                          FROM crpadm.rc_product_master rpm
                         WHERE     refresh_part_number =
                                      tab_data.refresh_part_number
                               AND tan_id = tab_data.tan_id);
      END IF;

      IF NVL (lv_unmatched_cnt, 0) <> 0
      THEN
         FOR rec IN ltab_bts_data_tab.FIRST .. ltab_bts_data_tab.LAST
         LOOP
            SELECT COUNT (1)
              INTO lv_part_exists_cnt
              FROM crpadm.rc_product_master rpm
             WHERE     refresh_part_number =
                          ltab_bts_data_tab (rec).refresh_part_number
                   AND tan_id = ltab_bts_data_tab (rec).tan_id;

            IF lv_part_exists_cnt = 0
            THEN
               lv_record_num := lv_record_num + 1;

               IF lv_record_num = 1
               THEN
                  lv_unmatched_rec := 'For Row #' || rec;     --lv_record_num;

                  /* LOWER (
                     TO_CHAR (
                        TO_DATE ('1-1-' || to_char(lv_record_num), 'dd-mm-yyyy'),
                        'FMYYYYth')); */

                  IF lv_unmatched_cnt = 1
                  THEN
                     lv_unmatched_rec := lv_unmatched_rec;
                  END IF;
               ELSE
                  IF lv_record_num = lv_unmatched_cnt
                  THEN
                     lv_unmatched_rec := lv_unmatched_rec || ' and ' || rec; --lv_record_num;
                  ELSE
                     lv_unmatched_rec := lv_unmatched_rec || ',' || rec; --lv_record_num;
                  END IF;
               END IF;
            END IF;
         END LOOP;
      END IF;

      IF lv_unmatched_cnt <> 0
      THEN
         v_message :=
               lv_unmatched_rec
            || ', Please provide valid PID and TAN combination';

         v_message := SUBSTR (v_message, 1, 1999);

         lv_process_err_tab.EXTEND;

         lv_err_count := lv_err_count + 1;

         lv_process_err_tab (lv_err_count) :=
            RC_INV_MESSAGE_OBJ ('BTS_ADJ',
                                NULL,
                                NULL,
                                NULL,
                                'ERROR',
                                v_message);
         lv_status := 'ERROR';
         GOTO return_process;
      ELSE
         IF ltab_bts_data_tab.EXISTS (1)
         THEN
            lv_file_name := ltab_bts_data_tab (1).file_name;

            FOR rec IN ltab_bts_data_tab.FIRST .. ltab_bts_data_tab.LAST
            LOOP
               INSERT INTO RC_BTS_CYCLE_UPLOAD_DATA (REQUEST_ID,
                                                     REFRESH_PART_NUMBER,
                                                     TAN_ID,
                                                     SITE_ID,
                                                     CYCLE_ROHS_CNT,
                                                     CYCLE_NROHS_CNT,
                                                     IFS_ROHS_CNT,
                                                     IFS_NROHS_CNT,
                                                     USER_COMMENTS,
                                                     ADJ_ROHS_QTY,
                                                     ADJ_NROHS_QTY,
                                                     UPLOADED_DATE,
                                                     UPLOADED_BY,
                                                     FILE_NAME,
                                                     V_ATTR1)
                       VALUES (
                                 rc_bts_inv_seq.NEXTVAL,
                                 ltab_bts_data_tab (rec).REFRESH_PART_NUMBER,
                                 ltab_bts_data_tab (rec).TAN_ID,
                                 ltab_bts_data_tab (rec).SITE_ID,
                                 ltab_bts_data_tab (rec).CYCLE_ROHS_CNT,
                                 ltab_bts_data_tab (rec).CYCLE_NROHS_CNT,
                                 ltab_bts_data_tab (rec).IFS_ROHS_CNT,
                                 ltab_bts_data_tab (rec).IFS_NROHS_CNT,
                                 ltab_bts_data_tab (rec).USER_COMMENTS,
                                   ltab_bts_data_tab (rec).CYCLE_ROHS_CNT
                                 - ltab_bts_data_tab (rec).IFS_ROHS_CNT, --ADJ_ROHS_QTY,
                                   ltab_bts_data_tab (rec).CYCLE_NROHS_CNT
                                 - ltab_bts_data_tab (rec).IFS_NROHS_CNT, --ADJ_NROHS_QTY,
                                 SYSDATE,
                                 i_login_user, --ltab_bts_data_tab (rec).UPLOADED_BY,
                                 UPPER (
                                    TRIM (ltab_bts_data_tab (rec).FILE_NAME)),
                                 lv_upload_id);
            END LOOP;
         END IF;
      END IF;

     <<return_process>>
      o_status := lv_status;

      IF lv_status = 'ERROR'
      THEN
         o_process_err_msg := lv_process_err_tab;
      ELSE
         IF ltab_bts_data_tab.EXISTS (1)
         THEN
            BEGIN
               P_BTS_EMAIL_NOTIFICATION (i_login_user,
                                         lv_upload_id,
                                         i_site_code,
                                         'Y',
                                         ltab_bts_data_tab);
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_message := v_message || '-' || SUBSTR (SQLERRM, 1, 200);
                  P_RCEC_ERROR_LOG (
                     I_module_name       => 'P_BTS_DATA_UPLOAD',
                     I_entity_name       => NULL,
                     I_entity_id         => NULL,
                     I_ext_entity_name   => NULL,
                     I_ext_entity_id     => NULL,
                     I_error_type        => 'EXCEPTION',
                     i_Error_Message     =>    'Error getting while executing P_BTS_EMAIL_NOTIFICATION while uploading '
                                            || ' <> '
                                            || v_message
                                            || ' LineNo=> '
                                            || DBMS_UTILITY.Format_error_backtrace,
                     I_created_by        => i_login_user,
                     I_updated_by        => i_login_user);
            END;
         END IF;
      END IF;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := SUBSTR (SQLERRM, 1, 100);
         P_RCEC_ERROR_LOG (
            I_module_name       => 'P_BTS_DATA_UPLOAD',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while executing P_BTS_DATA_UPLOAD '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => i_login_user,
            I_updated_by        => i_login_user);
   END P_BTS_DATA_UPLOAD;

   PROCEDURE P_BTS_DATA_VIEW (
      i_login_user              IN            VARCHAR2,
      i_load_view               IN            VARCHAR2,
      i_min_row                 IN            VARCHAR2,
      i_max_row                 IN            VARCHAR2,
      i_sort_column_name        IN            VARCHAR2,
      i_sort_column_by          IN            VARCHAR2,
      i_part_number             IN            VARCHAR2,
      i_tan_id                  IN            VARCHAR2,
      i_site_id                 IN            VARCHAR2,
      i_upload_date             IN            VARCHAR2,
      o_display_count              OUT NOCOPY NUMBER,
      o_bts_cycle_data_tab         OUT NOCOPY RC_BTS_CYCLE_DATA_TAB,
      o_bts_cycle_alldata_tab      OUT NOCOPY RC_BTS_CYCLE_DATA_TAB)
   IS
      lv_count_query            VARCHAR2 (32767);
      lv_all_data_query         VARCHAR2 (32767);
      lv_query                  VARCHAR2 (32767);
      lv_extquery               VARCHAR2 (32767);
      lv_sort_column_name       VARCHAR2 (200);
      lv_sort_column_by         VARCHAR2 (200);
      lv_display_count          NUMBER;
      lv_min_row                NUMBER;
      lv_max_row                NUMBER;
      lv_load_view              VARCHAR2 (30);
      lv_part_number            VARCHAR2 (300);
      lv_tan_id                 VARCHAR2 (300);
      lv_site_id                VARCHAR2 (30);
      lv_upload_date            VARCHAR2 (100);
      lv_request_id             NUMBER;
      ltab_bts_cycle_all_data   RC_BTS_CYCLE_DATA_TAB
                                   := RC_BTS_CYCLE_DATA_TAB ();
      ltab_bts_cycle_data       RC_BTS_CYCLE_DATA_TAB
                                   := RC_BTS_CYCLE_DATA_TAB ();
      lv_rec_exists_cnt         NUMBER;
   BEGIN
      lv_sort_column_name := TRIM (i_sort_column_name);
      lv_sort_column_by := TRIM (i_sort_column_by);
      lv_min_row := i_min_row;
      lv_max_row := i_max_row;
      lv_load_view := UPPER (TRIM (i_load_view));
      lv_part_number := TRIM (i_part_number);
      lv_tan_id := TRIM (i_tan_id);
      lv_site_id := TRIM (i_site_id);
      lv_upload_date := TRIM (i_upload_date);

      --lv_request_id:= TRIM(i_request_id);

      IF UPPER (lv_sort_column_name) LIKE '%DATE'
      THEN
         lv_sort_column_name :=
               'TO_DATE('
            || lv_sort_column_name
            || ', ''DD-Mon-YYYY HH:Mi:SS'')';
      END IF;

      lv_count_query :=
         '  SELECT COUNT (*)
                                        FROM RC_BTS_CYCLE_UPLOAD_DATA';

      lv_query :=
         '  SELECT RC_BTS_CYCLE_DATA_OBJ(
                                                REQUEST_ID,
                                                REFRESH_PART_NUMBER,
                                                TAN_ID,
                                                SITE_ID,
                                                CYCLE_ROHS_CNT,
                                                CYCLE_NROHS_CNT,
                                                IFS_ROHS_CNT,
                                                IFS_NROHS_CNT,
                                                USER_COMMENTS,
                                                ADJ_ROHS_QTY,
                                                STRATEGIC_MASKED_QTY_RHS,
                                                ADJ_NROHS_QTY,
                                                STRATEGIC_MASKED_QTY_NONROHS,
                                                UPLOADED_DATE,
                                                UPLOADED_BY,
                                                FILE_NAME,
                                                APPROVER_COMMENTS,
                                                ACTION,
                                                IS_BTS_PROCESSED,
                                                PROCESSED_DATE,
                                                PROCESSED_BY,
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
                                                D_ATTR4)
                                                    FROM(
                                                    SELECT rbc.*,';

      IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
      THEN
         lv_query :=
               lv_query
            || 'ROW_NUMBER()  OVER (ORDER BY '
            || lv_sort_column_name
            || ' '
            || lv_sort_column_by
            || ' ) AS rnum
                FROM (';
      --FROM RC_BTS_CYCLE_UPLOAD_DATA rbc';
      ELSE
         lv_query := lv_query || 'ROWNUM  rnum
                FROM (';
      -- FROM RC_BTS_CYCLE_UPLOAD_DATA rbc';
      END IF;

      lv_query :=
            lv_query
         || '    SELECT REQUEST_ID,
       REFRESH_PART_NUMBER,
       TAN_ID,
       SITE_ID,
       CYCLE_ROHS_CNT,
       CYCLE_NROHS_CNT,
       IFS_ROHS_CNT,
       IFS_NROHS_CNT,
       USER_COMMENTS,
       ADJ_ROHS_QTY,
       CASE
          WHEN SITE_ID = ''LRO'' THEN NVL(SP.LRO_RHS_QUANTITY,0)
          WHEN SITE_ID = ''FVE'' THEN NVL(SP.FVE_RHS_QUANTITY,0)
          ELSE 0
       END
          STRATEGIC_MASKED_QTY_RHS,
       ADJ_NROHS_QTY,
       CASE
          WHEN SITE_ID = ''LRO'' THEN NVL(SP.LRO_NRHS_QUANTITY,0)
          WHEN SITE_ID = ''FVE'' THEN 0
          ELSE 0
       END
          STRATEGIC_MASKED_QTY_NONROHS,
       TO_CHAR (UPLOADED_DATE, ''DD-Mon-YYYY HH:Mi:SS'') UPLOADED_DATE,
       UPLOADED_BY,
       FILE_NAME,
       APPROVER_COMMENTS,
       ACTION,
       IS_BTS_PROCESSED,
       TO_CHAR (PROCESSED_DATE, ''DD-Mon-YYYY HH:Mi:SS'') PROCESSED_DATE,
       PROCESSED_BY,
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
       D_ATTR4
  FROM RC_BTS_CYCLE_UPLOAD_DATA bts
       LEFT OUTER JOIN (SELECT partnumber,
       LRO_RHS_QUANTITY,
       LRO_NRHS_QUANTITY,
       FVE_RHS_QUANTITY,
       TOTAL_QUANTITY,
       CREATED_ON
  FROM RC_INV_STR_INV_MASK_MV
 WHERE TRUNC (CREATED_ON) =
          (SELECT TRUNC (MAX (CREATED_ON)) FROM RC_INV_STR_INV_MASK_MV)
         ) SP
          ON (BTS.REFRESH_PART_NUMBER = SP.PARTNUMBER) ';



      IF     lv_part_number IS NULL
         AND lv_tan_id IS NULL
         AND lv_site_id IS NULL
         AND lv_upload_date IS NULL
         AND lv_request_id IS NULL
      THEN
         lv_extquery := lv_extquery || ' WHERE 1=1';
      --                                    WHERE (PROCESSED_DATE IS NULL OR (action = ''Approved'' AND NVL(IS_BTS_Processed,''No'') = ''No'')
      --                                           OR TRUNC(TO_DATE(PROCESSED_DATE)) >= TRUNC(TO_DATE(SYSDATE-7))
      --                                           ) ';
      --  commented by swpriyad as part of PRB0059995
      ELSE
         lv_extquery := lv_extquery || '
                           WHERE 1=1';
      END IF;


      IF lv_part_number IS NOT NULL
      THEN
         lv_extquery :=
               lv_extquery
            || '
                        AND refresh_part_number IN
                                (SELECT  LISTAGG (refresh_part_number, '','')
                                         WITHIN GROUP (ORDER BY refresh_part_number, '','')
                                  FROM (  SELECT refresh_part_number
                                            FROM RC_BTS_CYCLE_UPLOAD_DATA rbc
                                           WHERE EXISTS
                                                    (SELECT 1
                                                       FROM (    SELECT DISTINCT
                                                                        UPPER (
                                                                           TRIM (REGEXP_SUBSTR ( '''
            || lv_part_number
            || ''',
                                                                                                ''[^ ,]+'',
                                                                                                1,
                                                                                                LEVEL)))
                                                                           AS part
                                                                   FROM DUAL
                                                             CONNECT BY REGEXP_SUBSTR ( '''
            || lv_part_number
            || ''',
                                                                                       ''[^ ,]+'',
                                                                                       1,
                                                                                       LEVEL)
                                                                           IS NOT NULL)
                                                      WHERE UPPER (rbc.refresh_part_number) LIKE
                                                               ''%''|| part || ''%'')
                                        GROUP BY refresh_part_number))';
      END IF;

      IF lv_tan_id IS NOT NULL
      THEN
         lv_extquery :=
               lv_extquery
            || '
                        AND tan_id IN
                                (SELECT  LISTAGG (TAN_ID, '','')
                                         WITHIN GROUP (ORDER BY TAN_ID, '','')
                                  FROM (  SELECT TAN_ID
                                            FROM RC_BTS_CYCLE_UPLOAD_DATA rbc
                                           WHERE EXISTS
                                                    (SELECT 1
                                                       FROM (    SELECT DISTINCT
                                                                        UPPER (
                                                                           TRIM (REGEXP_SUBSTR ( '''
            || lv_tan_id
            || ''',
                                                                                                ''[^ ,]+'',
                                                                                                1,
                                                                                                LEVEL)))
                                                                           AS tanid
                                                                   FROM DUAL
                                                             CONNECT BY REGEXP_SUBSTR ( '''
            || lv_tan_id
            || ''',
                                                                                       ''[^ ,]+'',
                                                                                       1,
                                                                                       LEVEL)
                                                                           IS NOT NULL)
                                                      WHERE UPPER (rbc.TAN_ID) LIKE
                                                               ''%''|| tanid || ''%'')
                                        GROUP BY TAN_ID))';
      END IF;

      IF lv_site_id IS NOT NULL AND lv_site_id != 'ALL'
      THEN
         lv_extquery :=
               lv_extquery
            || '
                        AND site_id = '''
            || lv_site_id
            || '''';
      END IF;

      IF lv_upload_date IS NOT NULL
      THEN
         lv_extquery :=
               lv_extquery
            || '
                            AND TO_DATE(uploaded_date,''DD-Mon-RRRR HH:Mi:SS'') =TO_DATE('
            || ''''
            || lv_upload_date
            || ''',''MM/DD/RRRR'')';
      END IF;

      lv_query := lv_query || lv_extquery;

      lv_all_data_query := lv_query;

      lv_count_query := lv_count_query || lv_extquery;

      IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
      THEN
         lv_query :=
               lv_query
            || '  )  rbc) WHERE rnum >='
            || lv_min_row
            || ' AND rnum <='
            || lv_max_row
            || ' ORDER BY '
            || lv_sort_column_name
            || ' '
            || lv_sort_column_by;

         lv_all_data_query :=
               lv_all_data_query
            || '  )  rbc)  ORDER BY '
            || lv_sort_column_name
            || ' '
            || lv_sort_column_by;
      ELSE
         IF lv_load_view = 'PENDING'
         THEN
            lv_query :=
                  lv_query
               || ' ORDER BY CASE
                                    WHEN action IS NULL AND (NVL(ADJ_ROHS_QTY,0)<>0 OR NVL(ADJ_NROHS_QTY,0)<>0)  THEN 1
                                    ELSE 2
                                 END,TO_DATE(uploaded_date,''DD-Mon-RRRR HH:Mi:SS'') desc) rbc)  WHERE rnum >='
               || lv_min_row
               || ' AND rnum<= '
               || lv_max_row;

            lv_all_data_query :=
                  lv_all_data_query
               || '  ORDER BY CASE
                                                                    WHEN action IS NULL AND (NVL(ADJ_ROHS_QTY,0)<>0 OR NVL(ADJ_NROHS_QTY,0)<>0)  THEN 1
                                                                    ELSE 2
                                                                 END,TO_DATE(uploaded_date,''DD-Mon-RRRR HH:Mi:SS'') desc) rbc) ';
         ELSE
            lv_query :=
                  lv_query
               || ' ORDER BY CASE
                                    WHEN action = ''Approved'' AND NVL(IS_BTS_Processed,''No'') = ''No'' THEN 1
                                    ELSE 3
                                 END,TO_DATE(uploaded_date,''DD-Mon-RRRR HH:Mi:SS'') desc) rbc)  WHERE rnum >='
               || lv_min_row
               || ' AND rnum<= '
               || lv_max_row;

            lv_all_data_query :=
                  lv_all_data_query
               || ' ORDER BY CASE
                                                        WHEN action = ''Approved'' AND NVL(IS_BTS_Processed,''No'') = ''No'' THEN 1
                                                        ELSE 3
                                                     END, TO_DATE(uploaded_date,''DD-Mon-RRRR HH:Mi:SS'') desc) rbc) ';
         END IF;
      END IF;


      --      INSERT INTO temp2_query
      --           VALUES (lv_query, SYSDATE);

      COMMIT;

      EXECUTE IMMEDIATE lv_query BULK COLLECT INTO ltab_bts_cycle_data;



      IF ltab_bts_cycle_data.EXISTS (1) AND lv_load_view = 'PENDING'
      THEN
         FOR rec IN ltab_bts_cycle_data.FIRST .. ltab_bts_cycle_data.LAST
         LOOP
            SELECT COUNT (1)
              INTO lv_rec_exists_cnt
              FROM RC_BTS_CYCLE_UPLOAD_DATA
             WHERE     refresh_part_number =
                          ltab_bts_cycle_data (rec).refresh_part_number
                   AND PROCESSED_DATE <= (SYSDATE - 1 / 24)
                   AND UPPER (ACTION) LIKE 'APPROVE%';

            IF lv_rec_exists_cnt > 0
            THEN
               ltab_bts_cycle_data (rec).v_attr4 := 'Y';
            ELSE
               ltab_bts_cycle_data (rec).v_attr4 := 'N';
            END IF;
         END LOOP;
      END IF;

      /*    IF lv_min_row IN (0,1)
         THEN */

      EXECUTE IMMEDIATE lv_all_data_query
         BULK COLLECT INTO ltab_bts_cycle_all_data;

      o_bts_cycle_alldata_tab := ltab_bts_cycle_all_data;

      --  END IF;


      EXECUTE IMMEDIATE lv_count_query INTO lv_display_count;

      o_bts_cycle_data_tab := ltab_bts_cycle_data;

      o_display_count := lv_display_count;
   EXCEPTION
      WHEN OTHERS
      THEN
         P_RCEC_ERROR_LOG (
            I_module_name       => 'P_BTS_DATA_VIEW',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while executing P_BTS_DATA_VIEW '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => i_login_user,
            I_updated_by        => i_login_user);
   END P_BTS_DATA_VIEW;

   PROCEDURE P_BTS_DATA_SU_PROCESS (
      i_login_user           IN VARCHAR2,
      i_bts_cycle_data_tab   IN RC_BTS_CYCLE_DATA_TAB)
   IS
      ltab_bts_cycle_data   RC_BTS_CYCLE_DATA_TAB := RC_BTS_CYCLE_DATA_TAB ();
   BEGIN
      ltab_bts_cycle_data := i_bts_cycle_data_tab;

      IF ltab_bts_cycle_data.EXISTS (1)
      THEN
         FORALL indx IN 1 .. ltab_bts_cycle_data.COUNT
            UPDATE rc_bts_cycle_upload_data rbc
               SET is_bts_processed =
                      ltab_bts_cycle_data (indx).is_bts_processed,
                   d_attr1 = SYSDATE,             --BTS processed updated Date
                   v_attr3 = i_login_user           --BTS processed updated By
             WHERE rbc.request_id = ltab_bts_cycle_data (indx).request_id;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         P_RCEC_ERROR_LOG (
            I_module_name       => 'P_BTS_DATA_SU_PROCESS',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while executing P_BTS_DATA_SU_PROCESS '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => i_login_user,
            I_updated_by        => i_login_user);
   END P_BTS_DATA_SU_PROCESS;

   PROCEDURE P_BTS_DATA_ADJ_PROCESS (
      i_login_user           IN            VARCHAR2,
      i_bts_cycle_data_tab   IN            RC_BTS_CYCLE_DATA_TAB,
      i_process_conf_flag    IN            VARCHAR2,
      o_bts_cycle_data_tab      OUT NOCOPY RC_BTS_CYCLE_DATA_TAB,
      o_process_err_msg         OUT NOCOPY RC_INV_MESSAGE_TAB,
      o_bts_warn_msg            OUT NOCOPY VARCHAR2,
      o_status                  OUT NOCOPY VARCHAR2)
   IS
      lv_ccw_count_flag           VARCHAR2 (1) := 'N';
      ltab_bts_cycle_data         RC_BTS_CYCLE_DATA_TAB := RC_BTS_CYCLE_DATA_TAB ();
      ltab_bts_cycle_data1        RC_BTS_CYCLE_DATA_TAB
                                     := RC_BTS_CYCLE_DATA_TAB ();
      lo_bts_cycle_data           RC_BTS_CYCLE_DATA_TAB
                                     := RC_BTS_CYCLE_DATA_TAB ();
      ltab_bts_inv_data           RC_BTS_CYCLE_DATA_TAB
                                     := RC_BTS_CYCLE_DATA_TAB ();
      ltab_bts_mail_data          RC_BTS_CYCLE_DATA_TAB
                                     := RC_BTS_CYCLE_DATA_TAB ();
      lv_process_err_tab          RC_INV_MESSAGE_TAB := RC_INV_MESSAGE_TAB ();
      lv_ccw_rohs_qty             NUMBER;
      lv_ccw_nrohs_qty            NUMBER;
      lv_cycl_rohs_cnt            NUMBER;
      lv_cycl_nrohs_cnt           NUMBER;
      lv_status                   VARCHAR2 (100);
      lv_excess_inv_flag          VARCHAR2 (1) := 'N';
      lv_request_id               NUMBER;
      lv_batch_proc_id            VARCHAR2 (300);
      lv_dup_part_number          VARCHAR2 (300);
      lv_inv_Log_seq              NUMBER;
      ln_part_cnt                 NUMBER;
      lv_ccw_o_available_qty      NUMBER;
      lv_ccw_o_avail_to_res_qty   NUMBER;
      lv_ccw_o_reserve_qty        NUMBER;
      lv_ccw_r_available_qty      NUMBER;
      lv_ccw_r_avail_to_res_qty   NUMBER;
      lv_ccw_r_reserve_qty        NUMBER;
      lv_rec_batch_id             VARCHAR2 (300);
      lv_adj_qty_r                NUMBER;
      lv_adj_qty_o                NUMBER;
      lv_adj_qty                  NUMBER;
      lv_message                  VARCHAR2 (32767);
      lv_err_count                NUMBER := 0;
      lv_cdc_rohs_qty             NUMBER := 0;
      lv_cdc_nrohs_qty            NUMBER := 0;
      lv_refresh_part_number      VARCHAR2 (2000);
      lv_tot_adj_rohs             NUMBER := 0;
      lv_tot_adj_nrohs            NUMBER := 0;
      lv_warn_msg                 VARCHAR2 (2000); --Added for Sprint20 Release
   BEGIN
      ltab_bts_cycle_data := i_bts_cycle_data_tab;

      /*
            insert into temp values(i_login_user);
            IF i_bts_cycle_data_tab.EXISTS(1)
            THEN
               insert into temp values(i_bts_cycle_data_tab(1).request_id||'-'||i_bts_cycle_data_tab(1).REFRESH_PART_NUMBER);
            ELSE
              insert into temp values('No Data getting from UI into TAB input');

            END IF;

            COMMIT;
      */
      IF ltab_bts_cycle_data.EXISTS (1) AND i_login_user IS NOT NULL
      THEN
         ltab_bts_cycle_data1 := ltab_bts_cycle_data;

         lv_warn_msg := NULL;

         FOR rec IN ltab_bts_cycle_data.FIRST .. ltab_bts_cycle_data.LAST
         LOOP
            lv_refresh_part_number := NULL;
            lv_refresh_part_number :=
               ltab_bts_cycle_data (rec).refresh_part_number;

            v_message := NULL;

            SELECT NVL (SUM (cycle_rohs_cnt), 0),
                   NVL (SUM (cycle_nrohs_cnt), 0),
                   NVL (SUM (adj_rohs_qty), 0),
                   NVL (SUM (adj_nrohs_qty), 0)
              INTO lv_cycl_rohs_cnt,
                   lv_cycl_nrohs_cnt,
                   lv_tot_adj_rohs,
                   lv_tot_adj_nrohs
              FROM TABLE (
                      CAST (ltab_bts_cycle_data1 AS RC_BTS_CYCLE_DATA_TAB)) tab_data
             WHERE     tab_data.refresh_part_number = lv_refresh_part_number
                   AND UPPER (tab_data.action) LIKE 'APPROV%';

            IF UPPER (ltab_bts_cycle_data (rec).action) LIKE 'APPROVE%'
            THEN
               SELECT DECODE (COUNT (1), 0, 'N', 'Y')
                 INTO lv_excess_inv_flag
                 FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                WHERE     part_number =
                             ltab_bts_cycle_data (rec).refresh_part_number
                      AND UPPER (Inventory_flow) = 'EXCESS';


               BEGIN
                  SELECT NVL (SUM (available_fgi), 0)
                    INTO lv_ccw_rohs_qty --ltab_bts_cycle_data(rec).n_attr1 --CCW Rohs Quantity
                    FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                   WHERE     part_number =
                                ltab_bts_cycle_data (rec).refresh_part_number
                         AND site_code = ltab_bts_cycle_data (rec).site_id
                         AND rohs_compliant = 'YES';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lv_ccw_rohs_qty := 0;
               END;

               ltab_bts_cycle_data (rec).n_attr1 := lv_ccw_rohs_qty;

               BEGIN
                  SELECT NVL (SUM (available_fgi), 0)
                    INTO lv_ccw_nrohs_qty --ltab_bts_cycle_data(rec).n_attr2 --CCW Non Rohs Quantity
                    FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                   WHERE     part_number =
                                ltab_bts_cycle_data (rec).refresh_part_number
                         AND site_code = ltab_bts_cycle_data (rec).site_id
                         AND rohs_compliant = 'NO';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lv_ccw_nrohs_qty := 0;
               END;

               ltab_bts_cycle_data (rec).n_attr2 := lv_ccw_nrohs_qty;

               SELECT NVL (SUM (ORDERED_QUANTITY), 0)
                 INTO lv_cdc_rohs_qty
                 FROM RC_SSOT_3A4_BACKLOG R3R
                WHERE     1 = 1
                      AND R3R.PRODUCTION_RESULT_CODE = 'AWAITING_SHIPPING'
                      AND ORDER_HOLDS IS NULL
                      AND OTM_SHIPPING_ROUTE_CODE LIKE 'CDC%'
                      AND R3R.ORGANIZATION_CODE =
                             ltab_bts_cycle_data (rec).site_id
                      AND PRODUCT_ID =
                             ltab_bts_cycle_data (rec).refresh_part_number
                      AND EXISTS
                             (SELECT 1
                                FROM RMK_SSOT_TRANSACTIONS RST
                               WHERE     SALES_ORDER_NUMBER =
                                            TO_CHAR (R3R.ORDER_NUMBER)
                                     AND UPPER (ROHS_COMPLIANT) = 'YES'
                                     AND PRODUCT_ID = R3R.PRODUCT_ID);

               SELECT NVL (SUM (ORDERED_QUANTITY), 0)
                 INTO lv_cdc_nrohs_qty
                 FROM RC_SSOT_3A4_BACKLOG R3R
                WHERE     1 = 1
                      AND R3R.PRODUCTION_RESULT_CODE = 'AWAITING_SHIPPING'
                      AND ORDER_HOLDS IS NULL
                      AND OTM_SHIPPING_ROUTE_CODE LIKE 'CDC%'
                      AND R3R.ORGANIZATION_CODE =
                             ltab_bts_cycle_data (rec).site_id
                      AND PRODUCT_ID =
                             ltab_bts_cycle_data (rec).refresh_part_number
                      AND EXISTS
                             (SELECT 1
                                FROM RMK_SSOT_TRANSACTIONS RST
                               WHERE     SALES_ORDER_NUMBER =
                                            TO_CHAR (R3R.ORDER_NUMBER)
                                     AND UPPER (ROHS_COMPLIANT) = 'NO'
                                     AND PRODUCT_ID = R3R.PRODUCT_ID);



               lv_message :=
                  'For PID ' || ltab_bts_cycle_data (rec).refresh_part_number;

               -- IF (NVL(ltab_bts_cycle_data(rec).adj_rohs_qty,0) = 0 AND  NVL(ltab_bts_cycle_data(rec).adj_nrohs_qty,0) = 0)
               IF lv_tot_adj_rohs = 0 AND lv_tot_adj_nrohs = 0
               THEN
                  v_message :=
                        lv_message
                     || ' IFS Rohs and Non Rohs adjustments are zero ';
               END IF;

               --IF lv_cycl_rohs_cnt>lv_ccw_rohs_qty AND NVL(ltab_bts_cycle_data(rec).adj_rohs_qty,0) <>0
               IF lv_cycl_rohs_cnt > lv_ccw_rohs_qty AND lv_tot_adj_rohs < 0 -- lv_tot_adj_rohs <>0 commented to fix the issue for positive adjustments
               THEN
                  v_message :=
                        v_message
                     || '<br>'
                     || lv_message
                     || ' Physical Cycle Count RoHS ( '
                     || lv_cycl_rohs_cnt
                     || ' units) greater than CCW available quantity RoHS ('
                     || lv_ccw_rohs_qty
                     || ' units) ';
               END IF;

               --IF lv_cycl_nrohs_cnt>lv_ccw_nrohs_qty AND NVL(ltab_bts_cycle_data(rec).adj_nrohs_qty,0) <>0
               IF     lv_cycl_nrohs_cnt > lv_ccw_nrohs_qty
                  AND lv_tot_adj_nrohs < 0 -- lv_tot_adj_rohs <>0 commented to fix the issue for positive adjustments
               THEN
                  v_message :=
                        v_message
                     || '<br>'
                     || lv_message
                     || ' Physical Cycle Count Non RoHS ( '
                     || lv_cycl_nrohs_cnt
                     || ' units) greater than CCW available quantity NRoHS ( '
                     || lv_ccw_nrohs_qty
                     || 'units) ';
               END IF;

               --IF NVL(ltab_bts_cycle_data(rec).adj_rohs_qty,0)<0 AND ABS(ltab_bts_cycle_data(rec).adj_rohs_qty)>lv_ccw_rohs_qty AND NVL(ltab_bts_cycle_data(rec).adj_rohs_qty,0) <>0
               IF     lv_tot_adj_rohs < 0
                  AND ABS (lv_tot_adj_rohs) > lv_ccw_rohs_qty
                  AND lv_tot_adj_rohs <> 0
               THEN
                  v_message :=
                        v_message
                     || '<br>'
                     || lv_message
                     || ' CCW Available quantity ROHS ( '
                     || lv_ccw_rohs_qty
                     || ' units) become negative with the adjustment ';
               END IF;

               --IF NVL(ltab_bts_cycle_data(rec).adj_nrohs_qty,0)<0 AND ABS(ltab_bts_cycle_data(rec).adj_nrohs_qty)>lv_ccw_nrohs_qty AND NVL(ltab_bts_cycle_data(rec).adj_nrohs_qty,0) <>0
               IF     lv_tot_adj_nrohs < 0
                  AND ABS (lv_tot_adj_nrohs) > lv_ccw_nrohs_qty
                  AND lv_tot_adj_nrohs <> 0
               THEN
                  v_message :=
                        v_message
                     || '<br>'
                     || lv_message
                     || ' CCW Available quantity Non ROHS ( '
                     || lv_ccw_nrohs_qty
                     || ' units) become negative with the adjustment';
               END IF;

               -- IF NVL(ltab_bts_cycle_data(rec).adj_rohs_qty,0)<0 AND ABS(NVL(ltab_bts_cycle_data(rec).adj_rohs_qty,0))<lv_cdc_rohs_qty
               IF     lv_tot_adj_rohs < 0
                  AND ABS (lv_tot_adj_rohs) < lv_cdc_rohs_qty
                  AND lv_cdc_rohs_qty <> 0 --Added for Pack-Out Quantity Validation rule on 14th Mar,2018
                  AND NVL (i_process_conf_flag, '*') = '*'
               THEN
                  -- v_message:= v_message||'<br>'||lv_message||' Pack out quantity ('||lv_cdc_rohs_qty||' units) is greater than the Cycle Count ROHS Adjustment quantity'; --Commented for Sprint20 Release
                  lv_warn_msg :=
                        lv_message
                     || ' Pack out quantity ('
                     || lv_cdc_rohs_qty
                     || ' units) is greater than the Cycle Count ROHS Adjustment quantity';
               END IF;

               --IF NVL(ltab_bts_cycle_data(rec).adj_nrohs_qty,0)<0 AND ABS(NVL(ltab_bts_cycle_data(rec).adj_nrohs_qty,0)) <lv_cdc_nrohs_qty
               IF     lv_tot_adj_nrohs < 0
                  AND ABS (lv_tot_adj_nrohs) < lv_cdc_nrohs_qty
                  AND lv_cdc_nrohs_qty <> 0 --Added for Pack-Out Quantity Validation rule on 14th Mar,2018
                  AND NVL (i_process_conf_flag, '*') = '*'
               THEN
                  -- v_message:= v_message||'<br>'||lv_message||' Pack out quantity ('||lv_cdc_nrohs_qty||' units) is greater than the Cycle Count Non ROHS Adjustment quantity';
                  lv_warn_msg :=
                        lv_warn_msg
                     || '<br>'
                     || lv_message
                     || ' Pack out quantity ('
                     || lv_cdc_nrohs_qty
                     || ' units) is greater than the Cycle Count Non ROHS Adjustment quantity';
               END IF;
            END IF;

            IF /* ((lv_cycl_rohs_cnt>lv_ccw_rohs_qty AND NVL(ltab_bts_cycle_data(rec).cycle_rohs_cnt,0) <>0) OR
                  (lv_cycl_nrohs_cnt>lv_ccw_nrohs_qty AND NVL(ltab_bts_cycle_data(rec).cycle_nrohs_cnt,0) <>0)) OR
                  (NVL(ltab_bts_cycle_data(rec).adj_rohs_qty,0) = 0 AND  NVL(ltab_bts_cycle_data(rec).adj_nrohs_qty,0) = 0) */
              v_message IS NOT NULL
               AND UPPER (ltab_bts_cycle_data (rec).action) LIKE 'APPROVE%'
               AND lv_warn_msg IS NULL
            THEN
               ltab_bts_cycle_data (rec).action := NULL;

               ln_part_cnt := 0;

               IF lv_dup_part_number IS NOT NULL
               THEN
                  SELECT COUNT (1)
                    INTO ln_part_cnt
                    FROM DUAL
                   WHERE ltab_bts_cycle_data (rec).refresh_part_number IN (    SELECT DISTINCT
                                                                                      REGEXP_SUBSTR (
                                                                                         lv_dup_part_number,
                                                                                         '[^,]+',
                                                                                         1,
                                                                                         LEVEL)
                                                                                 FROM DUAL
                                                                           CONNECT BY REGEXP_SUBSTR (
                                                                                         lv_dup_part_number,
                                                                                         '[^,]+',
                                                                                         1,
                                                                                         LEVEL)
                                                                                         IS NOT NULL);

                  lv_dup_part_number :=
                        lv_dup_part_number
                     || ','
                     || ltab_bts_cycle_data (rec).refresh_part_number;
               ELSE
                  lv_dup_part_number :=
                     ltab_bts_cycle_data (rec).refresh_part_number;
               END IF;

               IF NVL (ln_part_cnt, 0) <> 0
               THEN
                  v_message := NULL;
               ELSE
                  v_message := SUBSTR (v_message, 1, 1999);
               END IF;



               lv_process_err_tab.EXTEND;
               lv_err_count := lv_err_count + 1;
               lv_process_err_tab (lv_err_count) :=
                  RC_INV_MESSAGE_OBJ ('BTS_ADJ',
                                      ltab_bts_cycle_data (rec).request_id,
                                      NULL,
                                      NULL,
                                      'ERROR',
                                      v_message);
               lv_status := 'ERROR';
            --            ELSIF (NVL(ltab_bts_cycle_data(rec).adj_rohs_qty,0) <>0 OR  NVL(ltab_bts_cycle_data(rec).adj_nrohs_qty,0) <>0) OR
            --               UPPER(ltab_bts_cycle_data (rec).action) NOT LIKE 'APPROVE%'
            --               AND lv_warn_msg IS NULL AND  v_message IS NULL
            --            THEN
            --
            --               UPDATE rc_bts_cycle_upload_data rbc
            --                  SET adj_rohs_qty= ltab_bts_cycle_data (rec).adj_rohs_qty,
            --                       adj_nrohs_qty= ltab_bts_cycle_data (rec).adj_nrohs_qty,
            --                      approver_comments= ltab_bts_cycle_data (rec).approver_comments,
            --                      action= ltab_bts_cycle_data (rec).action,
            --                      is_bts_processed= ltab_bts_cycle_data (rec).is_bts_processed,
            --                      processed_date=SYSDATE,
            --                      processed_by=i_login_user
            --                WHERE rbc.request_id = ltab_bts_cycle_data (rec).request_id;
            --
            --                ltab_bts_cycle_data(rec).processed_date:= TO_CHAR(SYSDATE,'DD-Mon-YYYY HH:Mi:SS');
            --
            --                ltab_bts_cycle_data(rec).processed_by:=i_login_user;

            END IF;
         END LOOP;

         IF     lv_warn_msg IS NULL
            AND lv_err_count = 0
            AND ltab_bts_cycle_data.EXISTS (1)
         THEN
            FOR rec IN ltab_bts_cycle_data.FIRST .. ltab_bts_cycle_data.LAST
            LOOP
               UPDATE rc_bts_cycle_upload_data rbc
                  SET adj_rohs_qty = ltab_bts_cycle_data (rec).adj_rohs_qty,
                      adj_nrohs_qty = ltab_bts_cycle_data (rec).adj_nrohs_qty,
                      approver_comments =
                         ltab_bts_cycle_data (rec).approver_comments,
                      action = ltab_bts_cycle_data (rec).action,
                      is_bts_processed =
                         ltab_bts_cycle_data (rec).is_bts_processed,
                      processed_date = SYSDATE,
                      processed_by = i_login_user
                WHERE rbc.request_id = ltab_bts_cycle_data (rec).request_id;

               ltab_bts_cycle_data (rec).processed_date :=
                  TO_CHAR (SYSDATE, 'DD-Mon-YYYY HH:Mi:SS');

               ltab_bts_cycle_data (rec).processed_by := i_login_user;
            END LOOP;
         END IF;

         o_bts_warn_msg := lv_warn_msg;

         o_bts_cycle_data_tab := ltab_bts_cycle_data;


         IF lv_warn_msg IS NULL AND lv_err_count = 0
         THEN
            SELECT RC_BTS_CYCLE_DATA_OBJ (REQUEST_ID,
                                          REFRESH_PART_NUMBER,
                                          TAN_ID,
                                          SITE_ID,
                                          CYCLE_ROHS_CNT,
                                          CYCLE_NROHS_CNT,
                                          IFS_ROHS_CNT,
                                          IFS_NROHS_CNT,
                                          USER_COMMENTS,
                                          ADJ_ROHS_QTY,
                                          STRATEGIC_MASKED_QTY_RHS,
                                          ADJ_NROHS_QTY,
                                          STRATEGIC_MASKED_QTY_NONROHS,
                                          UPLOADED_DATE,
                                          UPLOADED_BY,
                                          FILE_NAME,
                                          APPROVER_COMMENTS,
                                          ACTION,
                                          IS_BTS_PROCESSED,
                                          PROCESSED_DATE,
                                          PROCESSED_BY,
                                          V_ATTR1,
                                          V_ATTR2,        --Set of Request IDs
                                          V_ATTR3,
                                          V_ATTR4,
                                          N_ATTR1,
                                          N_ATTR2,
                                          N_ATTR3,
                                          N_ATTR4,
                                          D_ATTR1,
                                          D_ATTR2,
                                          D_ATTR3,
                                          D_ATTR4)
              BULK COLLECT INTO ltab_bts_mail_data
              FROM TABLE (
                      CAST (ltab_bts_cycle_data AS RC_BTS_CYCLE_DATA_TAB)) tab_data
             WHERE     UPPER (tab_data.action) IS NOT NULL
                   AND tab_data.site_id = 'LRO';

            IF ltab_bts_mail_data.EXISTS (1)
            THEN
               BEGIN
                  P_BTS_EMAIL_NOTIFICATION (i_login_user,
                                            NULL,
                                            'LRO',
                                            'N',
                                            ltab_bts_mail_data);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_message := v_message || '-' || SUBSTR (SQLERRM, 1, 200);
                     P_RCEC_ERROR_LOG (
                        I_module_name       => 'P_BTS_DATA_ADJ_PROCESS',
                        I_entity_name       => NULL,
                        I_entity_id         => NULL,
                        I_ext_entity_name   => NULL,
                        I_ext_entity_id     => NULL,
                        I_error_type        => 'EXCEPTION',
                        i_Error_Message     =>    'Error getting while executing P_BTS_EMAIL_NOTIFICATION for LRO location '
                                               || ' <> '
                                               || v_message
                                               || ' LineNo=> '
                                               || DBMS_UTILITY.Format_error_backtrace,
                        I_created_by        => i_login_user,
                        I_updated_by        => i_login_user);
               END;
            END IF;

            SELECT RC_BTS_CYCLE_DATA_OBJ (REQUEST_ID,
                                          REFRESH_PART_NUMBER,
                                          TAN_ID,
                                          SITE_ID,
                                          CYCLE_ROHS_CNT,
                                          CYCLE_NROHS_CNT,
                                          IFS_ROHS_CNT,
                                          IFS_NROHS_CNT,
                                          USER_COMMENTS,
                                          ADJ_ROHS_QTY,
                                          STRATEGIC_MASKED_QTY_RHS,
                                          ADJ_NROHS_QTY,
                                          STRATEGIC_MASKED_QTY_NONROHS,
                                          UPLOADED_DATE,
                                          UPLOADED_BY,
                                          FILE_NAME,
                                          APPROVER_COMMENTS,
                                          ACTION,
                                          IS_BTS_PROCESSED,
                                          PROCESSED_DATE,
                                          PROCESSED_BY,
                                          V_ATTR1,
                                          V_ATTR2,        --Set of Request IDs
                                          V_ATTR3,
                                          V_ATTR4,
                                          N_ATTR1,
                                          N_ATTR2,
                                          N_ATTR3,
                                          N_ATTR4,
                                          D_ATTR1,
                                          D_ATTR2,
                                          D_ATTR3,
                                          D_ATTR4)
              BULK COLLECT INTO ltab_bts_mail_data
              FROM TABLE (
                      CAST (ltab_bts_cycle_data AS RC_BTS_CYCLE_DATA_TAB)) tab_data
             WHERE     UPPER (tab_data.action) IS NOT NULL
                   AND tab_data.site_id = 'FVE';

            IF ltab_bts_mail_data.EXISTS (1)
            THEN
               BEGIN
                  P_BTS_EMAIL_NOTIFICATION (i_login_user,
                                            NULL,
                                            'FVE',
                                            'N',
                                            ltab_bts_mail_data);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_message := v_message || '-' || SUBSTR (SQLERRM, 1, 200);
                     P_RCEC_ERROR_LOG (
                        I_module_name       => 'P_BTS_DATA_ADJ_PROCESS',
                        I_entity_name       => NULL,
                        I_entity_id         => NULL,
                        I_ext_entity_name   => NULL,
                        I_ext_entity_id     => NULL,
                        I_error_type        => 'EXCEPTION',
                        i_Error_Message     =>    'Error getting while executing P_BTS_EMAIL_NOTIFICATION for FVE location '
                                               || ' <> '
                                               || v_message
                                               || ' LineNo=> '
                                               || DBMS_UTILITY.Format_error_backtrace,
                        I_created_by        => i_login_user,
                        I_updated_by        => i_login_user);
               END;
            END IF;

            SELECT RC_BTS_CYCLE_DATA_OBJ (NULL,                  --REQUEST_ID,
                                          REFRESH_PART_NUMBER,
                                          NULL,                      --TAN_ID,
                                          SITE_ID,
                                          NULL,              --CYCLE_ROHS_CNT,
                                          NULL,             --CYCLE_NROHS_CNT,
                                          NULL,                --IFS_ROHS_CNT,
                                          NULL,               --IFS_NROHS_CNT,
                                          NULL,               --USER_COMMENTS,
                                          ADJ_ROHS_QTY,
                                          NULL,     --STRATEGIC_MASKED_QTY_RHS
                                          ADJ_NROHS_QTY,
                                          NULL, --STRATEGIC_MASKED_QTY_NONROHS
                                          NULL,               --UPLOADED_DATE,
                                          NULL,                 --UPLOADED_BY,
                                          NULL,                   --FILE_NAME,
                                          NULL,           --APPROVER_COMMENTS,
                                          NULL,                      --ACTION,
                                          NULL,            --IS_BTS_PROCESSED,
                                          NULL,              --PROCESSED_DATE,
                                          NULL,                --PROCESSED_BY,
                                          NULL,                     --V_ATTR1,
                                          V_ATTR2,        --Set of Request IDs
                                          NULL,                     --V_ATTR3,
                                          NULL,                     --V_ATTR4,
                                          NULL,                     --N_ATTR1,
                                          NULL,                     --N_ATTR2,
                                          NULL,                     --N_ATTR3,
                                          NULL,                     --N_ATTR4,
                                          NULL,                     --D_ATTR1,
                                          NULL,                     --D_ATTR2,
                                          NULL,                     --D_ATTR3,
                                          NULL                      --D_ATTR4,
                                              )
              BULK COLLECT INTO ltab_bts_inv_data
              FROM (  SELECT LISTAGG ('BTSUI_' || REQUEST_ID, ',')
                                WITHIN GROUP (ORDER BY REQUEST_ID, ',')
                                V_ATTR2,
                             REFRESH_PART_NUMBER,
                             SITE_ID,
                             NVL (SUM (ADJ_ROHS_QTY), 0) ADJ_ROHS_QTY,
                             NVL (SUM (ADJ_NROHS_QTY), 0) ADJ_NROHS_QTY
                        FROM TABLE (
                                CAST (
                                   ltab_bts_cycle_data AS RC_BTS_CYCLE_DATA_TAB)) tab_data
                       WHERE UPPER (tab_data.action) LIKE 'APPROV%'
                    GROUP BY REFRESH_PART_NUMBER, SITE_ID);

            IF ltab_bts_inv_data.EXISTS (1)
            THEN
               FOR rec IN ltab_bts_inv_data.FIRST .. ltab_bts_inv_data.LAST
               LOOP
                  lv_refresh_part_number := NULL;
                  lv_refresh_part_number :=
                     ltab_bts_inv_data (rec).refresh_part_number;


                  lv_rec_batch_id := ltab_bts_inv_data (rec).v_attr2;

                  SELECT DECODE (COUNT (1), 0, 'N', 'Y')
                    INTO lv_excess_inv_flag
                    FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                   WHERE     part_number = lv_refresh_part_number --ltab_bts_inv_data(rec).refresh_part_number
                         AND UPPER (Inventory_flow) = 'EXCESS';

                  IF lv_excess_inv_flag = 'Y'
                  THEN
                     IF NVL (ltab_bts_inv_data (rec).adj_rohs_qty, 0) <> 0
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
                                     lv_refresh_part_number, --ltab_bts_inv_data(rec).refresh_part_number,
                                     ltab_bts_inv_data (rec).adj_rohs_qty,
                                     0,
                                     'YES',
                                     ltab_bts_inv_data (rec).site_id,
                                     'N',
                                     i_login_user,
                                     SYSDATE,
                                     i_login_user,
                                     SYSDATE,
                                     lv_rec_batch_id,       --lv_poe_batch_id,
                                     'E');
                     END IF;

                     IF NVL (ltab_bts_inv_data (rec).adj_nrohs_qty, 0) <> 0
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
                                     lv_refresh_part_number, -- ltab_bts_inv_data(rec).refresh_part_number,
                                     ltab_bts_inv_data (rec).adj_nrohs_qty,
                                     0,
                                     'NO',
                                     ltab_bts_inv_data (rec).site_id,
                                     'N',
                                     i_login_user,
                                     SYSDATE,
                                     i_login_user,
                                     SYSDATE,
                                     lv_rec_batch_id,       --lv_poe_batch_id,
                                     'E');
                     END IF;
                  ELSIF lv_excess_inv_flag = 'N'
                  THEN
                     IF NVL (ltab_bts_inv_data (rec).adj_rohs_qty, 0) <> 0
                     THEN
                        INSERT INTO XXCPO_RMK_INV_MASTER_TEMP
                           SELECT *
                             FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                            WHERE     part_number =
                                         ltab_bts_cycle_data (rec).refresh_part_number
                                  AND site_code =
                                         ltab_bts_inv_data (rec).site_id
                                  AND inventory_flow = 'Retail'
                                  AND rohs_compliant = 'YES';


                        BEGIN
                           SELECT NVL (SUM (available_fgi), 0),
                                  NVL (SUM (available_to_reserve_fgi), 0),
                                  NVL (SUM (reserved_fgi), 0)
                             INTO lv_ccw_r_available_qty,
                                  lv_ccw_r_avail_to_res_qty,
                                  lv_ccw_r_reserve_qty
                             FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                            WHERE     part_number =
                                         ltab_bts_cycle_data (rec).refresh_part_number
                                  AND site_code =
                                         ltab_bts_inv_data (rec).site_id
                                  AND inventory_flow = 'Retail'
                                  AND rohs_compliant = 'YES';
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              lv_ccw_r_available_qty := 0;
                              lv_ccw_r_avail_to_res_qty := 0;
                              lv_ccw_r_reserve_qty := 0;
                        END;


                        INSERT INTO XXCPO_RMK_INV_MASTER_TEMP
                           SELECT *
                             FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                            WHERE     part_number =
                                         ltab_bts_cycle_data (rec).refresh_part_number
                                  AND site_code =
                                         ltab_bts_inv_data (rec).site_id
                                  AND inventory_flow = 'Outlet'
                                  AND rohs_compliant = 'YES';

                        BEGIN
                           SELECT NVL (SUM (available_fgi), 0),
                                  NVL (SUM (available_to_reserve_fgi), 0),
                                  NVL (SUM (reserved_fgi), 0)
                             INTO lv_ccw_o_available_qty,
                                  lv_ccw_o_avail_to_res_qty,
                                  lv_ccw_o_reserve_qty
                             FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                            WHERE     part_number =
                                         ltab_bts_cycle_data (rec).refresh_part_number
                                  AND site_code =
                                         ltab_bts_inv_data (rec).site_id
                                  AND inventory_flow = 'Outlet'
                                  AND rohs_compliant = 'YES';
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              lv_ccw_o_available_qty := 0;
                              lv_ccw_o_avail_to_res_qty := 0;
                              lv_ccw_o_reserve_qty := 0;
                        END;

                        lv_adj_qty_r := 0;
                        lv_adj_qty_o := 0;
                        lv_adj_qty := 0;

                        IF    ltab_bts_inv_data (rec).adj_rohs_qty > 0
                           OR lv_ccw_o_available_qty <= 0
                        THEN
                           lv_adj_qty_r :=
                              ltab_bts_inv_data (rec).adj_rohs_qty;
                        ELSIF     lv_ccw_o_available_qty > 0
                              AND ltab_bts_inv_data (rec).adj_rohs_qty < 0
                        THEN
                           IF lv_ccw_o_avail_to_res_qty >=
                                 ABS (ltab_bts_inv_data (rec).adj_rohs_qty)
                           THEN
                              lv_adj_qty_o :=
                                 ltab_bts_inv_data (rec).adj_rohs_qty;
                           ELSE
                              lv_adj_qty_o := -lv_ccw_o_avail_to_res_qty;

                              lv_adj_qty :=
                                   ABS (ltab_bts_inv_data (rec).adj_rohs_qty)
                                 - lv_ccw_o_avail_to_res_qty;

                              IF lv_ccw_r_avail_to_res_qty >= lv_adj_qty
                              THEN
                                 lv_adj_qty_r := - (lv_adj_qty);
                              ELSE
                                 lv_adj_qty_r := - (lv_ccw_r_avail_to_res_qty);
                                 lv_adj_qty :=
                                    lv_adj_qty - lv_ccw_r_avail_to_res_qty;

                                 IF lv_ccw_o_reserve_qty >= lv_adj_qty
                                 THEN
                                    lv_adj_qty_o := lv_adj_qty_o - lv_adj_qty;
                                 ELSE
                                    lv_adj_qty_o :=
                                       lv_adj_qty_o - lv_ccw_o_reserve_qty;
                                    lv_adj_qty :=
                                       lv_adj_qty - lv_ccw_o_reserve_qty;
                                    lv_adj_qty_r := lv_adj_qty_r - lv_adj_qty;
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
                                        lv_refresh_part_number, --ltab_bts_cycle_data(rec).refresh_part_number,
                                        lv_adj_qty_r,
                                        0,
                                        'YES',
                                        ltab_bts_cycle_data (rec).site_id,
                                        'N',
                                        i_login_user,
                                        SYSDATE,
                                        i_login_user,
                                        SYSDATE,
                                        lv_rec_batch_id,    --lv_poe_batch_id,
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
                                        lv_refresh_part_number, --ltab_bts_cycle_data(rec).refresh_part_number,
                                        lv_adj_qty_o,
                                        0,
                                        'YES',
                                        ltab_bts_cycle_data (rec).site_id,
                                        'N',
                                        i_login_user,
                                        SYSDATE,
                                        i_login_user,
                                        SYSDATE,
                                        lv_rec_batch_id,
                                        'O');
                        END IF;
                     END IF;

                     IF NVL (ltab_bts_inv_data (rec).adj_nrohs_qty, 0) <> 0
                     THEN
                        INSERT INTO XXCPO_RMK_INV_MASTER_TEMP
                           SELECT *
                             FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                            WHERE     part_number =
                                         ltab_bts_cycle_data (rec).refresh_part_number
                                  AND site_code =
                                         ltab_bts_inv_data (rec).site_id
                                  AND inventory_flow = 'Retail'
                                  AND rohs_compliant = 'NO';

                        BEGIN
                           SELECT NVL (SUM (available_fgi), 0),
                                  NVL (SUM (available_to_reserve_fgi), 0),
                                  NVL (SUM (reserved_fgi), 0)
                             INTO lv_ccw_r_available_qty,
                                  lv_ccw_r_avail_to_res_qty,
                                  lv_ccw_r_reserve_qty
                             FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                            WHERE     part_number =
                                         ltab_bts_cycle_data (rec).refresh_part_number
                                  AND site_code =
                                         ltab_bts_inv_data (rec).site_id
                                  AND inventory_flow = 'Retail'
                                  AND rohs_compliant = 'NO';
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              lv_ccw_r_available_qty := 0;
                              lv_ccw_r_avail_to_res_qty := 0;
                              lv_ccw_r_reserve_qty := 0;
                        END;

                        INSERT INTO XXCPO_RMK_INV_MASTER_TEMP
                           SELECT *
                             FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                            WHERE     part_number =
                                         ltab_bts_cycle_data (rec).refresh_part_number
                                  AND site_code =
                                         ltab_bts_inv_data (rec).site_id
                                  AND inventory_flow = 'Outlet'
                                  AND rohs_compliant = 'NO';

                        BEGIN
                           SELECT NVL (SUM (available_fgi), 0),
                                  NVL (SUM (available_to_reserve_fgi), 0),
                                  NVL (SUM (reserved_fgi), 0)
                             INTO lv_ccw_o_available_qty,
                                  lv_ccw_o_avail_to_res_qty,
                                  lv_ccw_o_reserve_qty
                             FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                            WHERE     part_number =
                                         ltab_bts_cycle_data (rec).refresh_part_number
                                  AND site_code =
                                         ltab_bts_inv_data (rec).site_id
                                  AND inventory_flow = 'Outlet'
                                  AND rohs_compliant = 'NO';
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              lv_ccw_o_available_qty := 0;
                              lv_ccw_o_avail_to_res_qty := 0;
                              lv_ccw_o_reserve_qty := 0;
                        END;

                        lv_adj_qty_r := 0;
                        lv_adj_qty_o := 0;
                        lv_adj_qty := 0;

                        IF    ltab_bts_inv_data (rec).adj_nrohs_qty > 0
                           OR lv_ccw_o_available_qty <= 0
                        THEN
                           lv_adj_qty_r :=
                              ltab_bts_inv_data (rec).adj_nrohs_qty;
                        ELSIF     lv_ccw_o_available_qty > 0
                              AND ltab_bts_inv_data (rec).adj_nrohs_qty < 0
                        THEN
                           IF lv_ccw_o_avail_to_res_qty >=
                                 ABS (ltab_bts_inv_data (rec).adj_nrohs_qty)
                           THEN
                              lv_adj_qty_o :=
                                 ltab_bts_inv_data (rec).adj_nrohs_qty;
                           ELSE
                              lv_adj_qty_o := -lv_ccw_o_avail_to_res_qty;

                              lv_adj_qty :=
                                   ABS (
                                      ltab_bts_inv_data (rec).adj_nrohs_qty)
                                 - lv_ccw_o_avail_to_res_qty;

                              IF lv_ccw_r_avail_to_res_qty >= lv_adj_qty
                              THEN
                                 lv_adj_qty_r := - (lv_adj_qty);
                              ELSE
                                 lv_adj_qty_r := - (lv_ccw_r_avail_to_res_qty);
                                 lv_adj_qty :=
                                    lv_adj_qty - lv_ccw_r_avail_to_res_qty;

                                 IF lv_ccw_o_reserve_qty >= lv_adj_qty
                                 THEN
                                    lv_adj_qty_o := lv_adj_qty_o - lv_adj_qty;
                                 ELSE
                                    lv_adj_qty_o :=
                                       lv_adj_qty_o - lv_ccw_o_reserve_qty;
                                    lv_adj_qty :=
                                       lv_adj_qty - lv_ccw_o_reserve_qty;
                                    lv_adj_qty_r := lv_adj_qty_r - lv_adj_qty;
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
                                        lv_refresh_part_number, --ltab_bts_cycle_data(rec).refresh_part_number,
                                        lv_adj_qty_r,
                                        0,
                                        'NO',
                                        ltab_bts_cycle_data (rec).site_id,
                                        'N',
                                        i_login_user,
                                        SYSDATE,
                                        i_login_user,
                                        SYSDATE,
                                        lv_rec_batch_id,    --lv_poe_batch_id,
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
                                        lv_refresh_part_number, --ltab_bts_cycle_data(rec).refresh_part_number,
                                        lv_adj_qty_o,
                                        0,
                                        'NO',
                                        ltab_bts_cycle_data (rec).site_id,
                                        'N',
                                        i_login_user,
                                        SYSDATE,
                                        i_login_user,
                                        SYSDATE,
                                        lv_rec_batch_id,
                                        'O');
                        END IF;
                     END IF;
                  END IF;
               END LOOP;
            END IF;
         END IF;
      ELSE
         IF i_login_user IS NULL
         THEN
            v_message :=
               'Session might be expired, Please refresh the tool and reprocess it';

            lv_process_err_tab.EXTEND;
            lv_err_count := lv_err_count + 1;
            lv_process_err_tab (lv_err_count) :=
               RC_INV_MESSAGE_OBJ ('BTS_ADJ',
                                   NULL,
                                   NULL,
                                   NULL,
                                   'ERROR',
                                   v_message);
         ELSE
            v_message := 'Empty Data selected';

            lv_process_err_tab.EXTEND;
            lv_err_count := lv_err_count + 1;
            lv_process_err_tab (lv_err_count) :=
               RC_INV_MESSAGE_OBJ ('BTS_ADJ',
                                   NULL,
                                   NULL,
                                   NULL,
                                   'ERROR',
                                   v_message);
         END IF;
      END IF;

      IF lv_process_err_tab.EXISTS (1)
      THEN
         o_status := lv_status;
         o_process_err_msg := lv_process_err_tab;
      ELSE
         o_status := 'SUCCESS';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := v_message || '-' || SUBSTR (SQLERRM, 1, 200);
         P_RCEC_ERROR_LOG (
            I_module_name       => 'P_BTS_DATA_ADJ_PROCESS',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while executing P_BTS_DATA_ADJ_PROCESS '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => i_login_user,
            I_updated_by        => i_login_user);
   END P_BTS_DATA_ADJ_PROCESS;

   PROCEDURE P_BTS_EMAIL_NOTIFICATION (
      i_login_user           IN VARCHAR2,
      i_upload_id            IN NUMBER,
      i_site_id              IN VARCHAR2,
      i_upload_flag          IN VARCHAR2,
      i_bts_cycle_data_tab   IN RC_BTS_CYCLE_DATA_TAB)
   IS
      lv_user_id            VARCHAR2 (50);
      lv_username           VARCHAR2 (100);
      lv_uploadId           NUMBER;

      g_error_msg           VARCHAR2 (2000);
      lv_msg_from           VARCHAR2 (500);
      lv_msg_to             VARCHAR2 (500);
      lv_msg_subject        VARCHAR2 (32767);
      lv_msg_text           VARCHAR2 (32767);
      lv_msg_body           VARCHAR2 (32767);
      lv_output_hdr         LONG;
      lv_mailhost           VARCHAR2 (100) := 'outbound.cisco.com';
      lv_conn               UTL_SMTP.CONNECTION;
      lv_message_type       VARCHAR2 (100) := 'text/html; charset="iso-8859-1"';
      lv_crlf               VARCHAR2 (5) := CHR (13) || CHR (10);
      lv_count              NUMBER := 0;
      lv_output             LONG;
      lv_database_name      VARCHAR2 (50);
      lv_approve_flag       VARCHAR2 (3);
      lv_start_time         VARCHAR2 (100);
      ltab_bts_cycle_data   RC_BTS_CYCLE_DATA_TAB := RC_BTS_CYCLE_DATA_TAB ();
      lv_upload_flag        VARCHAR2 (3);
      lv_site_code          VARCHAR2 (10);
      lv_email_sender       VARCHAR2 (100) := 'remarketing-it@cisco.com';
      lv_login_user         VARCHAR2 (50);
      lv_count_col          NUMBER := 0;
   BEGIN
      ltab_bts_cycle_data := i_bts_cycle_data_tab;

      lv_upload_flag := UPPER (i_upload_flag);
      lv_site_code := UPPER (i_site_id);
      lv_login_user := UPPER (TRIM (i_login_user));

      SELECT ora_database_name INTO lv_database_name FROM DUAL;

      SELECT TO_CHAR (SYSDATE, 'MM/DD/YYYY HH:MI:SS PM')
        INTO lv_start_time
        FROM DUAL;


      lv_msg_from := 'refreshcentral-support@cisco.com';

      IF (ora_database_name = 'FNTR2DEV.CISCO.COM')
      THEN
         lv_msg_subject := 'DEV : ' || lv_msg_subject;
      ELSIF (ora_database_name = 'FNTR2STG.CISCO.COM')
      THEN
         lv_msg_subject := 'STAGE : ' || lv_msg_subject;
      ELSE
         lv_msg_subject := lv_msg_subject;
      END IF;

      IF lv_upload_flag = 'Y'
      THEN
         BEGIN
            SELECT first_name || ' ' || last_name
              INTO lv_username
              FROM CRPADM.RC_CS_EMP_DATA
             WHERE UPPER (CS_EMAIL_ADDR) = lv_login_user;
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_username := i_login_user;
         END;

         lv_msg_subject :=
               lv_msg_subject
            || i_site_id
            || ' BTS Physical Cycle Count uploaded successfully, Upload Id: '
            || i_upload_id;


         lv_msg_text :=
               ' <HTML> Hi Team'
            || ','
            || '<br><br>'
            || ' <body>'
            || i_site_id
            || ' BTS Physical cycle count file uploaded successfully. Once Inventory Admins approve the requests, we will notify you to process the adjustments in IFS system. '
            || '<br>'
            || 'Uploaded By: '
            || lv_username;

         IF lv_site_code = 'LRO'
         THEN
            BEGIN
               SELECT email_sender, email_recipients
                 INTO lv_msg_from, lv_msg_to
                 FROM crpadm.rc_email_notifications
                WHERE notification_name =
                         CASE
                            WHEN lv_database_name = 'FNTR2PRD.CISCO.COM'
                            THEN
                               'BTS_TRANS_ADJ_ULLRO_NOTIFY'
                            WHEN lv_database_name = 'FNTR2STG.CISCO.COM'
                            THEN
                               'BTS_TRANS_ADJ_DEV_LRO_NOTIFY'
                            ELSE
                               'BTS_TRANS_ADJ_DEV_LRO_NOTIFY'
                         END;
            EXCEPTION
               WHEN OTHERS
               THEN
                  lv_msg_from := lv_email_sender;
                  lv_msg_to := lv_email_sender;
            END;
         ELSIF lv_site_code = 'FVE'
         THEN
            BEGIN
               SELECT email_sender, email_recipients
                 INTO lv_msg_from, lv_msg_to
                 FROM crpadm.rc_email_notifications
                WHERE notification_name =
                         CASE
                            WHEN lv_database_name = 'FNTR2PRD.CISCO.COM'
                            THEN
                               'BTS_TRANS_ADJ_ULFVE_NOTIFY'
                            WHEN lv_database_name = 'FNTR2STG.CISCO.COM'
                            THEN
                               'BTS_TRANS_ADJ_DEV_FVE_NOTIFY'
                            ELSE
                               'BTS_TRANS_ADJ_DEV_FVE_NOTIFY'
                         END;
            EXCEPTION
               WHEN OTHERS
               THEN
                  lv_msg_from := lv_email_sender;
                  lv_msg_to := lv_email_sender;
            END;
         END IF;
      ELSIF lv_upload_flag = 'N'
      THEN
         lv_msg_subject :=
               lv_msg_subject
            || i_site_id
            || ' BTS Physical Cycle Count requests status';


         lv_msg_text :=
               '<HTML>'
            || '<br /><br /> '
            || i_site_id
            || ' BTS Physical Cycle Count requests given below.'
            || '<br /><br /> '
            || '
                <head>
                    <style>
                    table {
                        font-family: arial, sans-serif;
                        border-collapse: collapse;
                        width: 100%;
                    }

                    td, th {
                        border: 1px solid black;
                        text-align: left;
                        padding: 4px;
                    }
                    </style>
                    </head>
                    <body>
                    <table>
                         <tr>
                        <th>Refresh ID</th><th>Tan ID</th><th>Location</th><th>Cycle Count RoHS</th><th>Cycle Count Non RoHS</th><th>IFS RoHS</th><th>IFS Non RoHS</th><th>Adjustment Qty RoHS</th><th>Adjustment Qty Non RoHS</th><th>Status</th><th>Requested By</th><th>File Name</th><th>Requested Date</th><th>Processed By</th><th>Processed Date</th></tr>';



         IF lv_site_code = 'LRO'
         THEN
            BEGIN
               SELECT email_sender, email_recipients
                 INTO lv_msg_from, lv_msg_to
                 FROM crpadm.rc_email_notifications
                WHERE notification_name =
                         CASE
                            WHEN lv_database_name = 'FNTR2PRD.CISCO.COM'
                            THEN
                               'BTS_TRANS_ADJ_LRO_NOTIFY'
                            WHEN lv_database_name = 'FNTR2STG.CISCO.COM'
                            THEN
                               'BTS_TRANS_ADJ_DEV_LRO_NOTIFY'
                            ELSE
                               'BTS_TRANS_ADJ_DEV_LRO_NOTIFY'
                         END;
            EXCEPTION
               WHEN OTHERS
               THEN
                  lv_msg_from := lv_email_sender;
                  lv_msg_to := lv_email_sender;
            END;
         ELSIF lv_site_code = 'FVE'
         THEN
            BEGIN
               SELECT email_sender, email_recipients
                 INTO lv_msg_from, lv_msg_to
                 FROM crpadm.rc_email_notifications
                WHERE notification_name =
                         CASE
                            WHEN lv_database_name = 'FNTR2PRD.CISCO.COM'
                            THEN
                               'BTS_TRANS_ADJ_FVE_NOTIFY'
                            WHEN lv_database_name = 'FNTR2STG.CISCO.COM'
                            THEN
                               'BTS_TRANS_ADJ_DEV_FVE_NOTIFY'
                            ELSE
                               'BTS_TRANS_ADJ_DEV_FVE_NOTIFY'
                         END;
            EXCEPTION
               WHEN OTHERS
               THEN
                  lv_msg_from := lv_email_sender;
                  lv_msg_to := lv_email_sender;
            END;
         END IF;
      END IF;

      IF lv_upload_flag = 'N'
      THEN
         IF ltab_bts_cycle_data.EXISTS (1)
         THEN
            FOR i IN 1 .. ltab_bts_cycle_data.COUNT
            LOOP
               IF MOD (lv_count_col, 2) = 0
               THEN
                  lv_msg_text :=
                     lv_msg_text || '<tr style="background-color: #dddddd">';
               ELSE
                  lv_msg_text := lv_msg_text || '<tr>';
               END IF;

               lv_msg_text :=
                     lv_msg_text
                  || '<td>'
                  || ltab_bts_cycle_data (i).refresh_part_number
                  || '</td><td nowrap>'
                  || ltab_bts_cycle_data (i).tan_id
                  || '</td><td nowrap>'
                  || ltab_bts_cycle_data (i).site_id
                  || '</td><td nowrap>'
                  || ltab_bts_cycle_data (i).cycle_rohs_cnt
                  || '</td><td>'
                  || ltab_bts_cycle_data (i).cycle_nrohs_cnt
                  || '</td><td>'
                  || ltab_bts_cycle_data (i).ifs_rohs_cnt
                  || '</td><td>'
                  || ltab_bts_cycle_data (i).ifs_nrohs_cnt
                  || '</td><td>'
                  || ltab_bts_cycle_data (i).adj_rohs_qty
                  || '</td><td>'
                  || ltab_bts_cycle_data (i).adj_nrohs_qty
                  || '</td><td nowrap>'
                  || ltab_bts_cycle_data (i).action
                  || '</td><td>'
                  || ltab_bts_cycle_data (i).uploaded_by
                  || '</td><td nowrap>'
                  || ltab_bts_cycle_data (i).file_name
                  || '</td><td nowrap>'
                  || ltab_bts_cycle_data (i).uploaded_date
                  || '</td><td nowrap>'
                  || ltab_bts_cycle_data (i).processed_by
                  || '</td><td nowrap>'
                  || ltab_bts_cycle_data (i).processed_date
                  || '</td></tr>';


               lv_count_col := lv_count_col + 1;
            END LOOP;

            lv_msg_text :=
                  lv_msg_text
               || '</table>'
               || '<br> <br>'
               || ' It might take approximately an hour to update the inventory for Ordering.'
               || '<br> '
               || 'PLEASE DO NOT REPLY .. This is an Auto generated Email.'
               || '<br><br>'
               || 'Thanks & Regards,'
               || '<br>'
               || 'Refresh Central Support team'
               || '
                      </body> </html>';
         END IF;
      ELSE
         lv_msg_text :=
               lv_msg_text
            || '<br><br> '
            || 'PLEASE DO NOT REPLY .. This is an Auto generated Email.'
            || '<br><br>'
            || 'Thanks & Regards,'
            || '<br>'
            || 'Refresh Central Support team'
            || ' </body> </html>';
      END IF;

      IF i_login_user IS NOT NULL
      THEN
         lv_msg_to := lv_msg_to || ',' || i_login_user || '@cisco.com';
      END IF;

      BEGIN
         crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (lv_msg_from,
                                                              lv_msg_to,
                                                              lv_msg_subject,
                                                              lv_msg_text,
                                                              NULL, --lv_filename,
                                                              NULL --lv_output
                                                                  );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_message := SUBSTR (SQLERRM, 1, 50);
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := v_message || ' - ' || SUBSTR (SQLERRM, 1, 100);

         P_RCEC_ERROR_LOG (
            I_module_name       => 'P_BTS_EMAIL_NOTIFICATION',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while executing P_BTS_EMAIL_NOTIFICATION '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => i_login_user,
            I_updated_by        => i_login_user);
   END P_BTS_EMAIL_NOTIFICATION;
END RC_BTS_CYCLE_ADJ_PKG;
/