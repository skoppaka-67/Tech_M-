CREATE OR REPLACE PACKAGE BODY RMKTGADM./*AppDB: 1041257*/                               "RC_ZSITE_CYCLE_ADJ_PKG" 
AS
   /*
  ****************************************************************************************************************
  * Object Name       :RC_ZSITE_CYCLE_ADJ_PKG
  * Project Name : Refresh Central
  * Copy Rights:   Cisco Systems, INC., CALIFORNIA
  * Description       : This API for Z-SITE cycle count Adjustment
  * Created Date:   20th,April 2018
  ===================================================================================================+
  * Version              Date                     Modified by                     Description
  ===================================================================================================+
   1.0                  20th,April 2018            satbanda                     Created for  Z-SITE cycle count Adjustment
   1.1                  09th May 2018              sridvasu                     Additional changes added on 09-MAY-2018
   1.2                  30th May 2018              sridvasu                     Commented Condition for admin logs in, added trunc(uploaded_date) on 30th MAY 2018 by sridvasu, Download excel
   1.3                  12-Jul-2018                sridvasu                     Commented added conditions due to access issue on 12-Jul-2018
   1.4                  03-Aug-2018                csirigir                     Modified the code for standard cost calculation
   1.5                  22-Feb-2019                sridvasu                     Modified the code to restrict Z32 site
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

   PROCEDURE P_ZSITE_DATA_UPLOAD (
      i_zsite_cycle_data_tab   IN            RC_Z_SITE_CYCLE_DATA_TAB,
      i_upload_id              IN            VARCHAR2,
      i_site_code              IN            VARCHAR2,               --LRO/FVE
      i_login_user             IN            VARCHAR2,
      i_user_role              IN     VARCHAR2,
      o_process_err_msg           OUT NOCOPY RC_INV_MESSAGE_TAB,
      o_status                    OUT NOCOPY VARCHAR2)
   IS
      ltab_zsite_data_tab   RC_Z_SITE_CYCLE_DATA_TAB
                               := RC_Z_SITE_CYCLE_DATA_TAB ();

      lv_unmatched_cnt1     NUMBER:=0;
      lv_unmatched_cnt2     NUMBER:=0;
      v_message             VARCHAR2 (4000);
      lv_process_err_tab    RC_INV_MESSAGE_TAB := RC_INV_MESSAGE_TAB ();
      lv_record_num1        NUMBER := 0;
      lv_record_num2        NUMBER := 0;
      lv_unmatched_rec1     VARCHAR2 (32767);
      lv_unmatched_rec2     VARCHAR2 (32767);
      lv_dataExists_flag    VARCHAR2 (3) := 'NO';
      lv_upld_rec_cnt       NUMBER := 0;
      lv_dgi_files          VARCHAR2 (4000);
      lv_site_code          VARCHAR2 (200);
      lv_invalid_data_cnt   NUMBER;
      lv_status             VARCHAR2 (20) := 'SUCCESS';
      lv_file_name          VARCHAR2 (500);
      lv_upload_id          VARCHAR2 (100);
      lv_err_count          NUMBER := 0;
      lv_qty_on_hand        NUMBER :=0;
      lv_user_role          VARCHAR2(100);
      ltab_user_sites       RC_VARCHAR_TAB:=RC_VARCHAR_TAB();
      lv_r_partner_id       NUMBER:=0;
      lv_subinv_invalid_cnt NUMBER:=0;
      lv_part_invalid_cnt   NUMBER:=0;
      lv_part_exists_cnt    NUMBER:=0;
      lv_subinv_exists_cnt  NUMBER:=0;
      lv_std_cost           NUMBER;
      lv_actual_std_cost    NUMBER;
      lv_ext_std_cost       NUMBER;

      CURSOR data_cur
      IS
         SELECT *
           FROM TABLE (
                   CAST (ltab_zsite_data_tab AS RC_Z_SITE_CYCLE_DATA_TAB));
   BEGIN
      ltab_zsite_data_tab := i_zsite_cycle_data_tab;
      lv_site_code := TRIM (i_site_code);
      lv_upload_id := TRIM (i_upload_id);
      lv_user_role := UPPER(TRIM (i_user_role));


      IF ltab_zsite_data_tab.EXISTS (1) AND lv_site_code IS NOT NULL
      THEN

        lv_invalid_data_cnt:=0;

         BEGIN
            SELECT COUNT (1)
              INTO lv_upld_rec_cnt
                 FROM TABLE (
                      CAST (ltab_zsite_data_tab AS RC_Z_SITE_CYCLE_DATA_TAB)) tab_data;

         EXCEPTION
            WHEN OTHERS
            THEN
               lv_upld_rec_cnt := 0;
         END;

         BEGIN
              SELECT LISTAGG (v_attr1, ',')
                        WITHIN GROUP (ORDER BY v_attr1, ',')
                INTO lv_dgi_files
               FROM(
                   SELECT v_attr1
                    FROM rc_dgi_cycle_upload_data
                   WHERE TRUNC (TO_DATE (UPLOADED_DATE, 'DD-MON-YYYY HH:Mi:SS')) =
                            TRUNC (SYSDATE)
                GROUP BY v_attr1
                  HAVING COUNT (*) = lv_upld_rec_cnt);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lv_dgi_files := NULL;
            WHEN OTHERS
            THEN
               lv_dgi_files := NULL;
         END;


         IF lv_dgi_files IS NOT NULL
         THEN
            FOR rec IN (    SELECT DISTINCT REGEXP_SUBSTR (lv_dgi_files,
                                                           '[^,]+',
                                                           1,
                                                           LEVEL)
                                               upload_id
                            FROM DUAL
                        CONNECT BY REGEXP_SUBSTR (lv_dgi_files,
                                                  '[^,]+',
                                                  1,
                                                  LEVEL)
                                      IS NOT NULL)
            LOOP
               BEGIN
                  SELECT DECODE (COUNT (1), lv_upld_rec_cnt, 'YES', 'NO')
                    INTO lv_dataExists_flag
                    FROM TABLE (
                            CAST (
                               ltab_zsite_data_tab AS RC_Z_SITE_CYCLE_DATA_TAB)) tab_data
                   WHERE EXISTS(SELECT 1
                                   FROM rc_dgi_cycle_upload_data rbc
                                  WHERE     1 = 1
                                        AND refresh_part_number =
                                               tab_data.refresh_part_number
                                        AND z_site_id = tab_data.z_site_id
                                        AND z_cycle_cnt =
                                               tab_data.z_cycle_cnt
                                        AND z_site_cnt = tab_data.z_site_cnt
                                        AND sub_inventory =
                                               tab_data.sub_inventory
                                        AND v_attr1 = rec.upload_id
                                        AND TRUNC (
                                               TO_DATE (
                                                  uploaded_date,
                                                  'DD-MON-YYYY HH:Mi:SS')) =
                                               TRUNC (SYSDATE));
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_message := SUBSTR (SQLERRM, 1, 100);

                     P_RCEC_ERROR_LOG (
                        I_module_name       => 'P_ZSITE_DATA_UPLOAD',
                        I_entity_name       => NULL,
                        I_entity_id         => NULL,
                        I_ext_entity_name   => NULL,
                        I_ext_entity_id     => NULL,
                        I_error_type        => 'EXCEPTION',
                        i_Error_Message     =>    'Error getting while executing P_ZSITE_DATA_UPLOAD '
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
                     'Same data file has been uploaded on today, please check and upload again';

                  lv_process_err_tab.EXTEND;
                  lv_err_count := lv_err_count + 1;
                  lv_process_err_tab (lv_err_count) :=
                     RC_INV_MESSAGE_OBJ ('DGI_ADJ',
                                         NULL,
                                         NULL,
                                         NULL,
                                         'ERROR',
                                         v_message);
                  EXIT;
               END IF;
            END LOOP;
         END IF;

         IF lv_dataExists_flag = 'YES'
         THEN
            lv_status := 'ERROR';
           GOTO return_process;
         END IF;

         BEGIN
            SELECT COUNT (1)
              INTO lv_subinv_invalid_cnt
              FROM TABLE (
                      CAST (ltab_zsite_data_tab AS RC_Z_SITE_CYCLE_DATA_TAB)) tab_data
              WHERE TRIM(tab_data.sub_inventory)  NOT IN ( SELECT sub_inventory_location
                                                      FROM crpadm.rc_sub_inv_loc_mstr);

         EXCEPTION
            WHEN OTHERS
            THEN
               lv_subinv_invalid_cnt := 0;
         END;


         --Added by Satya on 10th May,2018 for additional check of Sub Inventory, Refresh Part <Start>
         BEGIN
            SELECT COUNT (1)
              INTO lv_part_invalid_cnt
             FROM TABLE (
                      CAST (ltab_zsite_data_tab AS RC_Z_SITE_CYCLE_DATA_TAB)) tab_data
              WHERE (TRIM(tab_data.refresh_part_number),substr(TRIM(tab_data.z_site_id),1,3)) NOT IN (select part_number, organization_code
                                                                                                        from crpadm.rc_inv_org_assignmnt_exception
                                                                                                            where enabled_flag = 'Y');

         EXCEPTION
            WHEN OTHERS
            THEN
               lv_part_invalid_cnt := 0;
         END;


         IF lv_subinv_invalid_cnt <> 0 OR lv_part_invalid_cnt<>0
         THEN

            FOR rec IN ltab_zsite_data_tab.FIRST .. ltab_zsite_data_tab.LAST
            LOOP
              IF lv_part_invalid_cnt <> 0
              THEN
                 SELECT count(1)
                   INTO lv_part_exists_cnt
                   FROM crpadm.rc_inv_org_assignmnt_exception
                  WHERE  part_number = ltab_zsite_data_tab(rec).refresh_part_number AND organization_code = substr(ltab_zsite_data_tab(rec).z_site_id,1,3) AND enabled_flag = 'Y';


                IF lv_part_exists_cnt=0
                THEN

                   lv_record_num1 := lv_record_num1 + 1;

                    IF lv_record_num1 = 1
                    THEN
                       lv_unmatched_rec1 := 'For Row #'||rec;

                       IF lv_unmatched_cnt1 = 1
                       THEN
                          lv_unmatched_rec1 :=  lv_unmatched_rec1;
                       END IF;
                    ELSE
                       IF lv_record_num1 = lv_part_invalid_cnt
                       THEN
                          lv_unmatched_rec1 :=
                                lv_unmatched_rec1
                             || ' and '
                             || rec;

                       ELSE
                           lv_unmatched_rec1 :=
                                lv_unmatched_rec1
                             || ','
                             || rec; --lv_record_num;
                       END IF;
                    END IF;
                 END IF;

               END IF;

               IF lv_subinv_invalid_cnt <> 0
               THEN
                  SELECT count(1)
                    INTO lv_subinv_exists_cnt
                    FROM crpadm.rc_sub_inv_loc_mstr
                    WHERE  sub_inventory_location =ltab_zsite_data_tab(rec).sub_inventory;




                    IF lv_subinv_exists_cnt=0
                    THEN

                       lv_record_num2 := lv_record_num2 + 1;

                        IF lv_record_num2 = 1
                        THEN
                           lv_unmatched_rec2 := 'For Row #'||rec;

                           IF lv_record_num2 = 1
                           THEN
                              lv_unmatched_rec2 :=  lv_unmatched_rec2;
                           END IF;
                        ELSE
                           IF lv_record_num2 = lv_subinv_invalid_cnt
                           THEN
                              lv_unmatched_rec2 :=
                                    lv_unmatched_rec2
                                 || ' and '
                                 || rec;

                           ELSE
                               lv_unmatched_rec2 :=
                                    lv_unmatched_rec2
                                 || ','
                                 || rec; --lv_record_num;
                           END IF;
                        END IF;
                     END IF;

                END IF;
              END LOOP;


              IF lv_unmatched_rec1 IS NOT NULL OR lv_unmatched_rec2 IS NOT NULL
              THEN
                 IF lv_unmatched_rec1 IS NOT NULL
                 THEN
                     v_message := v_message||
                           lv_unmatched_rec1||', please provide valid Part Number(s)' ||'<br>';
                 END IF;

                 IF lv_unmatched_rec2 IS NOT NULL
                 THEN
                     v_message := v_message||'<br>'||
                           lv_unmatched_rec2||', please provide valid SUB Inventory Code(s)' ;
                 END IF;

                 v_message:=SUBSTR(v_message,1,1999);


                 lv_process_err_tab.EXTEND;

                 lv_err_count:=lv_err_count+1;

                 lv_process_err_tab (lv_err_count) :=
                    RC_INV_MESSAGE_OBJ ('DGI_ADJ',
                                        NULL,
                                        NULL,
                                        NULL,
                                        'ERROR',
                                        v_message);
                lv_status:='ERROR';
                GOTO return_process;
              END IF;



            /* v_message :=
                  'Please provide Valid Sub Inventory Location(s) for Z Site: '
               || lv_site_code
               || ' in file data';

            lv_process_err_tab.EXTEND;

            lv_err_count := lv_err_count + 1;

            lv_process_err_tab (lv_err_count) :=
               RC_INV_MESSAGE_OBJ ('DGI_ADJ',
                                   NULL,
                                   NULL,
                                   NULL,
                                   'ERROR',
                                   v_message);
            lv_status := 'ERROR';
            GOTO return_process; */
         END IF;
         --Added by Satya on 10th May,2018 for additional check of Sub Inventory, Refresh Part <End>

     END IF;

      IF ltab_zsite_data_tab.EXISTS (1)
      THEN
         lv_file_name := ltab_zsite_data_tab (1).file_name;


         BEGIN
--            SELECT REPAIR_PARTNER_ID
--              INTO lv_r_partner_id
--              FROM crpadm.RC_REPAIR_PARTNER_USER_MAP
--             WHERE user_name = i_login_user;
             
             SELECT REPAIR_PARTNER_ID
             INTO lv_r_partner_id
             FROM CRPADM.RC_GU_PRODUCT_REFRESH_SETUP
             WHERE UPLOAD_ID = lv_upload_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_r_partner_id := 0;
         END;

         IF lv_r_partner_id IS NULL
         THEN
            lv_r_partner_id:=0;
         END IF;

         FOR rec IN ltab_zsite_data_tab.FIRST .. ltab_zsite_data_tab.LAST
         LOOP

            lv_qty_on_hand:=0;

            BEGIN
                SELECT NVL(SUM(QTY_ON_HAND),0)
                  INTO lv_qty_on_hand
                  FROM crpadm.RC_INV_BTS_C3_MV
                 WHERE     1 = 1
                   AND part_number = ltab_zsite_data_tab (rec).refresh_part_number                   --partnumber
                   AND site LIKE SUBSTR(lv_site_code,1,3)||'%'                                          --z site
                   AND location = ltab_zsite_data_tab (rec).sub_inventory;                                 --subinventory
            EXCEPTION
             WHEN OTHERS
             THEN
               lv_qty_on_hand:=0;
            END;
            
            BEGIN                     --Added for Standard cost calc on 03-Aug-2018 by Chandra
                 SELECT NVL(MAX(ROUND (d.item_cost, 2)),0),
                        NVL(MAX(ROUND (d.item_cost, 2)),0),
                        NVL(MAX(ROUND (d.item_cost, 2)),0)*(ltab_zsite_data_tab (rec).z_cycle_cnt - ltab_zsite_data_tab (rec).z_site_cnt)
                   INTO lv_std_cost,
                        lv_actual_std_cost,
                        lv_ext_std_cost
                    FROM MTL_SYSTEM_ITEMS_S@CSFPRD_DBL.CISCO.COM b, CST_ITEM_COSTS_S@CSFPRD_DBL.CISCO.COM d
                  WHERE     b.inventory_item_id = d.inventory_item_id
                        AND d.cost_type_id = 1
                        AND b.organization_id = d.organization_id
                        AND d.organization_id = 900000000
                  AND ltab_zsite_data_tab (rec).refresh_part_number = b.segment1; -- CHANGED SOURCE TO PULL STD COST
                     
              EXCEPTION
                   WHEN OTHERS
                   THEN
                       lv_std_cost:=0;
                       lv_actual_std_cost:=0;
                       lv_ext_std_cost:=0;
            END;
                        
                INSERT INTO rc_dgi_cycle_upload_data (request_id,
                                                  repair_partner_id,
                                                  refresh_part_number,
                                                  z_site_id,
                                                  sub_inventory,
                                                  z_cycle_cnt,
                                                  z_site_cnt,
                                                  z_adj_qty,
                                                  c3_onhand_qty,
                                                  user_comments,
                                                  uploaded_date,
                                                  uploaded_by,
                                                  file_name,
                                                  v_attr1,
                                                  created_by,
                                                  created_on,
                                                  last_updated_by,
                                                  last_updated_date,
                                                  std_cost,         --Added STD_COST, ACTUAL_STD_COST, EXT_STD_COST on 03-Aug-2018 by Chandra 
                                                  actual_std_cost,
                                                  ext_std_cost)
                    VALUES (
                              rc_dgi_z_site_inv_seq.NEXTVAL,
                              lv_r_partner_id, --ltab_zsite_data_tab (rec).repair_partner_id,
                              ltab_zsite_data_tab (rec).refresh_part_number,
                              lv_site_code,--ltab_zsite_data_tab (rec).z_site_id,
                              ltab_zsite_data_tab (rec).sub_inventory,
                              ltab_zsite_data_tab (rec).z_cycle_cnt,
                              ltab_zsite_data_tab (rec).z_site_cnt,
                                ltab_zsite_data_tab (rec).z_cycle_cnt
                              - ltab_zsite_data_tab (rec).z_site_cnt,
                              lv_qty_on_hand,
                              ltab_zsite_data_tab (rec).user_comments,
                              TO_CHAR (SYSDATE, 'DD-MON-YYYY HH:Mi:SS'),
                              i_login_user,
                              UPPER (
                                 TRIM (ltab_zsite_data_tab (rec).FILE_NAME)),
                              lv_upload_id,
                              i_login_user,
                              sysdate,
                              i_login_user,
                              sysdate,
                              lv_std_cost,
                              lv_actual_std_cost,
                              lv_ext_std_cost);
         END LOOP;
      END IF;

      <<return_process>>

      o_status := lv_status;

      IF lv_status = 'ERROR'
      THEN
         o_process_err_msg := lv_process_err_tab;
       ELSE
          IF ltab_zsite_data_tab.EXISTS(1)
          THEN
             BEGIN
               P_ZSITE_EMAIL_NOTIFICATION(i_login_user,lv_upload_id,i_site_code,'Y',ltab_zsite_data_tab);
             EXCEPTION
                 WHEN OTHERS
                 THEN
                   v_message:=v_message||'-'||SUBSTR(SQLERRM,1,200);
                   P_RCEC_ERROR_LOG (
                     I_module_name       => 'P_ZSITE_DATA_UPLOAD',
                     I_entity_name       =>NULL,
                     I_entity_id         => NULL,
                     I_ext_entity_name   => NULL,
                     I_ext_entity_id     => NULL,
                     I_error_type        => 'EXCEPTION',
                     i_Error_Message     => 'Error getting while executing P_ZSITE_EMAIL_NOTIFICATION while uploading '
                                           || ' <> '
                                           || v_message
                                           || ' LineNo=> '
                                           || DBMS_UTILITY.Format_error_backtrace,
                     I_created_by        => i_login_user,
                     I_updated_by        => i_login_user);
                END;
           END IF;
      END IF;

   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := SUBSTR (SQLERRM, 1, 100);
         P_RCEC_ERROR_LOG (
            I_module_name       => 'P_ZSITE_DATA_UPLOAD',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while executing P_ZSITE_DATA_UPLOAD '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => i_login_user,
            I_updated_by        => i_login_user);
   END P_ZSITE_DATA_UPLOAD;


   PROCEDURE P_ZSITE_DATA_VIEW (
      i_login_user                IN            VARCHAR2,
      i_load_view                 IN            VARCHAR2,
      i_min_row                   IN            VARCHAR2,
      i_max_row                   IN            VARCHAR2,
      i_sort_column_name          IN            VARCHAR2,
      i_sort_column_by            IN            VARCHAR2,
      i_part_number               IN            VARCHAR2,
      i_site_id                   IN            VARCHAR2,
      i_sub_inv_id                IN            VARCHAR2,
      i_status                    IN            VARCHAR2,
      i_upload_date_from          IN            VARCHAR2,
      i_upload_date_to            IN            VARCHAR2,
      o_display_count                OUT NOCOPY NUMBER,
      o_zsite_cycle_data_tab         OUT NOCOPY RC_Z_SITE_CYCLE_DATA_TAB,
      o_zsite_cycle_alldata_tab      OUT NOCOPY RC_Z_SITE_CYCLE_DATA_TAB)
   IS
      lv_count_query              VARCHAR2 (32767);
      lv_all_data_query           VARCHAR2 (32767);
      lv_query                    VARCHAR2 (32767);
      lv_extquery                 VARCHAR2 (32767);
      lv_sort_column_name         VARCHAR2 (200);
      lv_sort_column_by           VARCHAR2 (200);
      lv_display_count            NUMBER;
      lv_min_row                  NUMBER;
      lv_max_row                  NUMBER;
      lv_load_view                VARCHAR2 (30);
      lv_part_number              VARCHAR2 (300);
      lv_sub_inv_id               VARCHAR2 (300);
      lv_site_id                  VARCHAR2 (300);
      lv_upload_date_from         VARCHAR2 (100);
      lv_upload_date_to           VARCHAR2 (100);
      lv_status                   VARCHAR2 (100);
      lv_request_id               NUMBER;
      ltab_zsite_cycle_all_data   RC_Z_SITE_CYCLE_DATA_TAB
                                     := RC_Z_SITE_CYCLE_DATA_TAB ();
      ltab_zsite_cycle_data       RC_Z_SITE_CYCLE_DATA_TAB
                                     := RC_Z_SITE_CYCLE_DATA_TAB ();
      lv_rec_exists_cnt           NUMBER;
      lv_rp_site_codes            RC_VARCHAR_TAB:=RC_VARCHAR_TAB();
      ltab_site_codes             VARCHAR2(32767);
      l_count                     NUMBER;      --Added for Standard cost calc on 03-Aug-2018 by Chandra
   BEGIN
      lv_sort_column_name := TRIM (i_sort_column_name);
      lv_sort_column_by := TRIM (i_sort_column_by);
      lv_min_row := i_min_row;
      lv_max_row := i_max_row;
      lv_load_view := UPPER (TRIM (i_load_view));
      lv_part_number := TRIM (i_part_number);
      lv_sub_inv_id := TRIM (i_sub_inv_id);
      lv_site_id := TRIM (i_site_id);
      lv_upload_date_from := TRIM (i_upload_date_from);
      lv_upload_date_to := TRIM (i_upload_date_to);
      lv_status:=UPPER(TRIM(i_status));
      

             BEGIN                     --Added for Standard cost calc on 03-Aug-2018 by Chandra
                SELECT count(*) 
                  INTO l_count
                  FROM rc_dgi_cycle_upload_data rbc
                 WHERE rbc.std_cost IS NULL;
                   
                IF l_count<>0
                THEN
             
                UPDATE rc_dgi_cycle_upload_data rbc
                   SET (std_cost,actual_std_cost,ext_std_cost) = (SELECT NVL(MAX(ROUND (d.item_cost,2)),0),NVL(MAX(ROUND (d.item_cost,2)),0),NVL(MAX(ROUND (d.item_cost,2))*rbc.z_adj_qty,0)
                                                                    FROM MTL_SYSTEM_ITEMS_S@CSFPRD_DBL.CISCO.COM b, CST_ITEM_COSTS_S@CSFPRD_DBL.CISCO.COM d
                  WHERE     b.inventory_item_id = d.inventory_item_id
                        AND d.cost_type_id = 1
                        AND b.organization_id = d.organization_id
                        AND d.organization_id = 900000000
                        AND rbc.refresh_part_number = b.SEGMENT1)
                 WHERE rbc.std_cost IS NULL;  -- CHANGED SOURCE TO PULL STD COST
                   
                COMMIT;
                
                END IF;                         
           END;
          
      IF UPPER(lv_sort_column_name) LIKE '%DATE'
      THEN
         lv_sort_column_name := 'TO_DATE('||lv_sort_column_name||', ''DD-Mon-YYYY HH:Mi:SS'')';
      END IF;

      lv_count_query := '  SELECT COUNT (*)
                                        FROM RC_DGI_CYCLE_UPLOAD_DATA rbc';

      lv_query :=
                     '  SELECT RC_Z_SITE_CYCLE_DATA_OBJ(
                                                REQUEST_ID,
                                                REPAIR_PARTNER_ID,
                                                REFRESH_PART_NUMBER,
                                                Z_SITE_ID,
                                                SUB_INVENTORY,
                                                Z_CYCLE_CNT,
                                                Z_SITE_CNT,
                                                Z_ADJ_QTY,
                                                C3_ONHAND_QTY,
                                                USER_COMMENTS,
                                                UPLOADED_DATE,
                                                UPLOADED_BY,
                                                FILE_NAME,
                                                APPROVER_COMMENTS,
                                                ACTION,
                                                PROCESSED_FLAG,
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
                                                SITE_PROCESSED_DATE,
                                                D_ATTR2,
                                                D_ATTR3,
                                                D_ATTR4,
                                                STD_COST,     --Added STD_COST, ACTUAL_STD_COST, EXT_STD_COST on 03-Aug-2018 by Chandra
                                                ACTUAL_STD_COST,
                                                EXT_STD_COST)';

        IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
          THEN
             lv_query :=
                   lv_query
                ||' FROM(SELECT dgi_loc.*,'
                || 'ROW_NUMBER()  OVER (ORDER BY '
                || lv_sort_column_name
                || ' '
                || lv_sort_column_by
                || ' ) AS rnum ';
          ELSE
             lv_query :=
                lv_query
                ||' FROM(SELECT dgi_loc.*,'
                || 'ROWNUM  rnum ';
          END IF;

               lv_query :=
                   lv_query||' FROM(SELECT REQUEST_ID,
                                                                REPAIR_PARTNER_ID,
                                                                rbc.REFRESH_PART_NUMBER,
                                                                Z_SITE_ID,
                                                                SUB_INVENTORY,
                                                                Z_CYCLE_CNT,
                                                                Z_SITE_CNT,
                                                                Z_ADJ_QTY,
                                                                C3_ONHAND_QTY,
                                                                USER_COMMENTS,
                                                                --TO_DATE(UPLOADED_DATE,''DD-Mon-YYYY HH:Mi:SS'') UPLOADED_DATE,
                                                                UPLOADED_DATE,
                                                                UPLOADED_BY,
                                                                FILE_NAME,
                                                                APPROVER_COMMENTS,
                                                                ACTION,
                                                                PROCESSED_FLAG,
                                                               -- TO_DATE(PROCESSED_DATE,''DD-Mon-YYYY HH:Mi:SS'') PROCESSED_DATE,
                                                                PROCESSED_DATE,
                                                                PROCESSED_BY,
                                                                V_ATTR1,
                                                                V_ATTR2,
                                                                V_ATTR3,
                                                                V_ATTR4,
                                                                /* (SELECT MAX (UNIT_STD_COST_USD)
                                                                  FROM CRPADM.RC_PRODUCT_MASTER pm
                                                                    WHERE (pm.REFRESH_PART_NUMBER = rbc.refresh_part_number
                                                                          OR pm.COMMON_PART_NUMBER = rbc.refresh_part_number
                                                                          OR xref_part_number = rbc.refresh_part_number )
                                                                          and tan_id is not null)*Z_ADJ_QTY  */ --Commented by Satya for taking long time
                                                                N_ATTR1,
                                                                N_ATTR2,
                                                                N_ATTR3,
                                                                N_ATTR4,
                                                                SITE_PROCESSED_DATE,
                                                                D_ATTR2,
                                                                D_ATTR3,
                                                                D_ATTR4,
                                                                STD_COST,        --Added STD_COST, ACTUAL_STD_COST, EXT_STD_COST on 03-Aug-2018 by Chandra
                                                                ACTUAL_STD_COST,
                                                                EXT_STD_COST,
                                                                CASE
                                                                    WHEN action = ''Approved'' AND NVL(processed_flag,''No'') = ''No''
                                                                    THEN 1
                                                                  /*   WHEN action = ''Approved'' AND processed_flag IN (''Yes'')
                                                                    THEN 2 */
                                                                    ELSE 3
                                                                 END action_order,
                                                                CASE
                                                                    WHEN action IS NULL AND NVL(Z_ADJ_QTY,0)<>0  THEN 1
                                                                  --  WHEN action IS NULL AND NVL(Z_ADJ_QTY,0)= 0  THEN 2
                                                                    ELSE 3
                                                                 END admin_order
                                                            FROM RC_DGI_CYCLE_UPLOAD_DATA rbc ';

         IF  lv_part_number IS NULL AND
             lv_sub_inv_id IS NULL AND
             lv_site_id IS NULL AND
             lv_upload_date_from IS NULL AND
             lv_upload_date_to IS NULL
         THEN
            --lv_extquery := lv_extquery||' WHERE (SITE_PROCESSED_DATE IS NULL OR NVL(processed_flag,''No'') = ''No''
            lv_extquery := lv_extquery||' WHERE (SITE_PROCESSED_DATE IS NULL OR (action = ''Approved'' AND NVL(processed_flag,''No'') = ''No'')
                                           OR TRUNC(SITE_PROCESSED_DATE) >= TRUNC(TO_DATE(SYSDATE-7))
                                           ) ';
         ELSE
             lv_extquery := lv_extquery||'
                           WHERE 1=1';
         END IF;



         IF lv_load_view IS NULL
         THEN
            BEGIN
               lv_rp_site_codes:= F_GET_USER_ZSITES(i_login_user,'RP','Y');
            EXCEPTION
              WHEN OTHERS
              THEN
                NULL;
            END ;

            IF lv_rp_site_codes.EXISTS(1)
            THEN

               SELECT  LISTAGG ( column_value, ',')
                        WITHIN GROUP (ORDER BY column_value, ',')
                INTO ltab_site_codes
               FROM TABLE(CAST (lv_rp_site_codes AS RC_VARCHAR_TAB));

               lv_extquery := lv_extquery || 'AND Z_SITE_ID IN (SELECT DISTINCT REGEXP_SUBSTR ('''||ltab_site_codes||''',
                                                                                                         ''[^,]+'',
                                                                                                         1,
                                                                                                         LEVEL)
                                                                                             sites
                                                                            FROM DUAL
                                                                      CONNECT BY REGEXP_SUBSTR ('''||ltab_site_codes||''',
                                                                                                ''[^,]+'',
                                                                                                1,
                                                                                                LEVEL)
                                                                                    IS NOT NULL)';

            ELSE

              lv_extquery := lv_extquery||'
                            AND 1=2'; -- AND 1=1'; commented 1=1 and uncommented 1=2 on 12-Jul-2018 as there was an access issue
            END IF;
         END IF;


         IF lv_part_number IS NOT NULL
         THEN

            lv_extquery := lv_extquery||'
                        AND rbc.refresh_part_number IN (
                                        SELECT refresh_part_number
                                                            FROM RC_DGI_CYCLE_UPLOAD_DATA rbc
                                                           WHERE EXISTS
                                                                    (SELECT 1
                                                                       FROM (    SELECT DISTINCT
                                                                                        UPPER (
                                                                                           TRIM (REGEXP_SUBSTR ( '''||lv_part_number||''',
                                                                                                                ''[^ ,]+'',
                                                                                                                1,
                                                                                                                LEVEL)))
                                                                                           AS part
                                                                                   FROM DUAL
                                                                             CONNECT BY REGEXP_SUBSTR ( '''||lv_part_number||''',
                                                                                                       ''[^ ,]+'',
                                                                                                       1,
                                                                                                       LEVEL)
                                                                                           IS NOT NULL)
                                                                      WHERE UPPER (rbc.refresh_part_number) LIKE
                                                                               ''%''|| part || ''%'')
                                                        GROUP BY refresh_part_number)';

         END IF;

         IF lv_sub_inv_id IS NOT NULL
         THEN
            lv_extquery := lv_extquery||'
                        AND SUB_INVENTORY = '''||lv_sub_inv_id||'''';
         END IF;

         IF lv_site_id IS NOT NULL AND
            lv_site_id!='ALL'
         THEN
            lv_extquery := lv_extquery||'
                        AND Z_SITE_ID  = '''||lv_site_id||'''';

         END IF;

         -->> Start Added trunc(uploaded_date) on 30th MAY 2018 by sridvasu

         IF lv_upload_date_from IS NOT NULL AND
             lv_upload_date_to IS NOT NULL
          THEN
             lv_extquery := lv_extquery||'
                            AND TRUNC(TO_DATE(uploaded_date,''DD-Mon-YYYY HH:Mi:SS'')) BETWEEN TO_DATE('
               || ''''||lv_upload_date_from
               || ''',''MM/DD/YYYY'') AND TO_DATE('
               || ''''||lv_upload_date_to
               || ''',''MM/DD/YYYY'')';
          ELSIF lv_upload_date_from IS NOT NULL
          THEN
              lv_extquery := lv_extquery||'
                                AND TRUNC(TO_DATE(uploaded_date,''DD-Mon-YYYY HH:Mi:SS'')) >=TO_DATE('
                                                       || ''''||lv_upload_date_from
                                                       || ''',''MM/DD/YYYY'')';
          ELSIF lv_upload_date_to IS NOT NULL
          THEN
              lv_extquery := lv_extquery||'
                                AND TRUNC(TO_DATE(uploaded_date,''DD-Mon-YYYY HH:Mi:SS'')) <=TO_DATE('
                                                       || ''''||lv_upload_date_to
                                                       || ''',''MM/DD/YYYY'')';
         END IF;

         -->> End Added trunc(uploaded_date) on 30th MAY 2018 by sridvasu

          IF lv_status IS NOT NULL
          THEN
             lv_extquery := lv_extquery||'
                        AND UPPER(ACTION)  = '''||lv_status||'''';
          END IF;



          lv_query:=lv_query||lv_extquery;

          lv_all_data_query:=lv_query;

          lv_count_query:=lv_count_query||lv_extquery;

          IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
          THEN
              lv_query := lv_query || '  )   dgi_loc) WHERE rnum >=' || lv_min_row ||
                      ' AND rnum <=' || lv_max_row || ' ORDER BY ' || lv_sort_column_name || ' ' ||
                      lv_sort_column_by;

              lv_all_data_query := lv_all_data_query || '  )   dgi_loc)  ORDER BY ' || lv_sort_column_name || ' ' ||
                      lv_sort_column_by;
          ELSE

             IF lv_load_view='PENDING'
             THEN
                 lv_query := lv_query || --' AND ROWNUM <= ' || lv_max_row ||
                          ' ORDER BY admin_order,TO_DATE(uploaded_date,''DD-Mon-RRRR HH:Mi:SS'') desc) dgi_loc) WHERE rnum >=' || lv_min_row || ' AND rnum <= ' || lv_max_row;

                 lv_all_data_query := lv_all_data_query || '  ORDER BY admin_order,TO_DATE(uploaded_date,''DD-Mon-RRRR HH:Mi:SS'') desc) dgi_loc)' ;
             ELSE

                  lv_query := lv_query  ||--' AND ROWNUM <= ' || lv_max_row ||
                          ' ORDER BY action_order,TO_DATE(uploaded_date,''DD-Mon-RRRR HH:Mi:SS'') desc ) dgi_loc) WHERE rnum >=' || lv_min_row || ' AND rnum <= ' || lv_max_row;

                 lv_all_data_query := lv_all_data_query || ' ORDER BY action_order, TO_DATE(uploaded_date,''DD-Mon-RRRR HH:Mi:SS'') desc) dgi_loc) ';

             END IF;
          END IF;
          
        /*  IF lv_min_row IN (0,1)
         THEN

             UPDATE RC_DGI_CYCLE_UPLOAD_DATA rbc
               SET n_attr1=  (SELECT MAX (UNIT_STD_COST_USD)
                                FROM CRPADM.RC_PRODUCT_MASTER pm
                               WHERE rbc.refresh_part_number= ANY(REFRESH_PART_NUMBER,COMMON_PART_NUMBER,xref_part_number))*rbc.z_adj_qty
              WHERE n_attr1 IS NULL;

         END IF; */

          EXECUTE IMMEDIATE lv_query BULK COLLECT INTO ltab_zsite_cycle_data;
          
          IF ltab_zsite_cycle_data.EXISTS(1) AND lv_load_view='PENDING'
          THEN

            FOR rec IN ltab_zsite_cycle_data.FIRST .. ltab_zsite_cycle_data.LAST
            LOOP
               SELECT COUNT(1)
                 INTO lv_rec_exists_cnt
                 FROM RC_DGI_CYCLE_UPLOAD_DATA
                WHERE refresh_part_number=ltab_zsite_cycle_data(rec).refresh_part_number
                  AND SITE_PROCESSED_DATE<=(SYSDATE-1/24)
                  AND UPPER(ACTION) LIKE 'APPROVE%';

               IF lv_rec_exists_cnt>0
               THEN
                  ltab_zsite_cycle_data(rec).v_attr4:='Y';
               ELSE
                  ltab_zsite_cycle_data(rec).v_attr4:='N';
               END IF;

            END LOOP;
          END IF;
          
        /*  --Added by Satya for standard cost calc <Start>       --Start Commented by Chandra for Report download taking long time
           IF ltab_zsite_cycle_data.EXISTS(1)
           THEN
              FOR rec IN ltab_zsite_cycle_data.FIRST .. ltab_zsite_cycle_data.LAST
              LOOP
              
                BEGIN  
                
               SELECT MAX (UNIT_STD_COST_USD)*ltab_zsite_cycle_data(rec).z_adj_qty
                 INTO ltab_zsite_cycle_data(rec).n_attr1
                 FROM CRPADM.RC_PRODUCT_MASTER pm
                WHERE ltab_zsite_cycle_data(rec).refresh_part_number= ANY(REFRESH_PART_NUMBER,COMMON_PART_NUMBER,xref_part_number);
                EXCEPTION 
                WHEN OTHERS
                THEN
                  ltab_zsite_cycle_data(rec).n_attr1:=0;
                
                END;
               
              END LOOP;
             
           END IF;    
           
           IF ltab_zsite_cycle_all_data.EXISTS(1)
           THEN
              FOR rec IN ltab_zsite_cycle_all_data.FIRST .. ltab_zsite_cycle_all_data.LAST
              LOOP
               BEGIN

               SELECT MAX (UNIT_STD_COST_USD)*ltab_zsite_cycle_all_data(rec).z_adj_qty
                 INTO ltab_zsite_cycle_all_data(rec).n_attr1
                 FROM CRPADM.RC_PRODUCT_MASTER pm
                WHERE ltab_zsite_cycle_all_data(rec).refresh_part_number= ANY(REFRESH_PART_NUMBER,COMMON_PART_NUMBER,xref_part_number);    

                EXCEPTION 
                WHEN OTHERS
                THEN
                  ltab_zsite_cycle_all_data(rec).n_attr1:=0;
                                
                END;
                
              END LOOP;
             
           END IF;   
           
           --Added by Satya for standard cost calc <End> */   --End Commented by Chandra for Report download taking long time

          -->> Start Commented If condition for download excel is getting empty on 30th May 2018

--          IF lv_min_row IN (0,1)
--          THEN

            EXECUTE IMMEDIATE lv_all_data_query BULK COLLECT INTO ltab_zsite_cycle_all_data;

            o_zsite_cycle_alldata_tab:=ltab_zsite_cycle_all_data;

--          END IF;

        -->> End Commented If condition for download excel is getting empty on 30th May 2018

          EXECUTE IMMEDIATE lv_count_query INTO lv_display_count;

          o_zsite_cycle_data_tab:=ltab_zsite_cycle_data;

          o_display_count:=lv_display_count;

   EXCEPTION
      WHEN OTHERS
      THEN

         v_message:=SUBSTR(SQLERRM,1,200);

         P_RCEC_ERROR_LOG (
            I_module_name       => 'P_ZSITE_DATA_VIEW',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while executing P_ZSITE_DATA_VIEW '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => i_login_user,
            I_updated_by        => i_login_user);
   END P_ZSITE_DATA_VIEW;

   PROCEDURE P_ZSITE_DATA_SU_PROCESS (
      i_login_user             IN VARCHAR2,
      i_zsite_cycle_data_tab   IN RC_Z_SITE_CYCLE_DATA_TAB)
   IS
      ltab_zsite_cycle_data   RC_Z_SITE_CYCLE_DATA_TAB
                                 := RC_Z_SITE_CYCLE_DATA_TAB ();
   BEGIN
      ltab_zsite_cycle_data := i_zsite_cycle_data_tab;
       IF ltab_zsite_cycle_data.EXISTS(1)
       THEN
          FORALL indx IN 1 .. ltab_zsite_cycle_data.COUNT
                UPDATE rc_dgi_cycle_upload_data rbc
                  SET processed_flag=ltab_zsite_cycle_data (indx).processed_flag,
                      v_attr1 = SYSDATE, --DGI processed updated Date
                      v_attr3=i_login_user, --DGI processed updated By
                      site_processed_date = SYSDATE, -->> Added on 09-MARY-2018 to display last update date in UI by sridvasu
                      std_cost = ltab_zsite_cycle_data (indx).std_cost,        --Added STD_COST, ACTUAL_STD_COST, EXT_STD_COST on 03-Aug-2018 by Chandra
                      actual_std_cost = ltab_zsite_cycle_data (indx).actual_std_cost,
                      ext_std_cost = ltab_zsite_cycle_data (indx).ext_std_cost
                 WHERE rbc.request_id = ltab_zsite_cycle_data (indx).request_id;
       END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         P_RCEC_ERROR_LOG (
            I_module_name       => 'P_ZSITE_DATA_SU_PROCESS',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while executing P_ZSITE_DATA_SU_PROCESS '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => i_login_user,
            I_updated_by        => i_login_user);
   END P_ZSITE_DATA_SU_PROCESS;

   PROCEDURE P_ZSITE_DATA_ADJ_PROCESS (
      i_login_user             IN            VARCHAR2,
      i_zsite_cycle_data_tab   IN            RC_Z_SITE_CYCLE_DATA_TAB,
      o_zsite_cycle_data_tab      OUT NOCOPY RC_Z_SITE_CYCLE_DATA_TAB,
      o_process_err_msg           OUT NOCOPY RC_INV_MESSAGE_TAB,
      o_status                    OUT NOCOPY VARCHAR2)
   IS
      ltab_zsite_cycle_data   RC_Z_SITE_CYCLE_DATA_TAB
                                 := RC_Z_SITE_CYCLE_DATA_TAB ();
      ltab_zsite_cycle_data1  RC_Z_SITE_CYCLE_DATA_TAB
                                 := RC_Z_SITE_CYCLE_DATA_TAB ();
      ltab_zsite_mail_data RC_Z_SITE_CYCLE_DATA_TAB:=RC_Z_SITE_CYCLE_DATA_TAB(); -->> Added on 10-MAY-2018 by sridvasu
      --lv_z_site               RC_Z_SITE_TAB :=   RC_Z_SITE_TAB();

      lv_tot_cycl_cnt         NUMBER;
      lv_tot_adj_cnt          NUMBER;
      lv_message              VARCHAR2(32767);
      ln_part_cnt        NUMBER;
      lv_dup_part_number VARCHAR2(300);
      lv_err_count       NUMBER:=0;
      lv_status          VARCHAR2(100);
      lv_excess_inv_flag VARCHAR2(1):='N';
      lv_z_site_code      VARCHAR2(500);
      lv_z_sites_code     VARCHAR2(500);
      lv_count            NUMBER;
      lv_process_err_tab  RC_INV_MESSAGE_TAB:=RC_INV_MESSAGE_TAB();
      lv_refresh_part_number  RC_DGI_CYCLE_UPLOAD_DATA.refresh_part_number%TYPE;
      lv_sub_inventory RC_DGI_CYCLE_UPLOAD_DATA.sub_inventory%TYPE;

   BEGIN
      ltab_zsite_cycle_data := i_zsite_cycle_data_tab;

      IF ltab_zsite_cycle_data.EXISTS(1) AND i_login_user IS NOT NULL
      THEN

         ltab_zsite_cycle_data1:=ltab_zsite_cycle_data;

         FOR rec IN ltab_zsite_cycle_data.FIRST ..ltab_zsite_cycle_data.LAST
         LOOP

           lv_refresh_part_number:=NULL;
           lv_sub_inventory:=NULL;

           lv_refresh_part_number:=ltab_zsite_cycle_data(rec).refresh_part_number;
           lv_sub_inventory:=ltab_zsite_cycle_data(rec).sub_inventory;

           v_message:=NULL;

            SELECT NVL(SUM(z_cycle_cnt),0),
                   NVL(SUM(z_adj_qty),0)
              INTO lv_tot_cycl_cnt,
                   lv_tot_adj_cnt
             FROM TABLE (CAST (ltab_zsite_cycle_data1 AS RC_Z_SITE_CYCLE_DATA_TAB)) tab_data
            WHERE tab_data.refresh_part_number = lv_refresh_part_number
              AND tab_data.sub_inventory = lv_sub_inventory
              AND UPPER(tab_data.action) LIKE  'APPROV%';

            IF UPPER(ltab_zsite_cycle_data (rec).action) LIKE 'APPROVE%'
            THEN
               SELECT DECODE(COUNT(1),0,'N','Y')
                 INTO lv_excess_inv_flag
                 FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                WHERE part_number = lv_refresh_part_number
                  AND  UPPER(Inventory_flow)='EXCESS'    ;

                lv_message:= 'For PID '||ltab_zsite_cycle_data(rec).refresh_part_number;

               IF lv_tot_adj_cnt=0
               THEN
                   v_message:= lv_message||' Cycle adjustment quantity is zero ';
               END IF;

               IF v_message IS NOT NULL
                  AND UPPER(ltab_zsite_cycle_data (rec).action) LIKE 'APPROVE%'
               THEN
                  ltab_zsite_cycle_data (rec).action:=NULL;

                  ln_part_cnt:=0;

                  IF lv_dup_part_number IS NOT NULL
                  THEN
                    SELECT COUNT(1)
                      INTO ln_part_cnt
                     FROM DUAL
                    WHERE ltab_zsite_cycle_data(rec).refresh_part_number IN
                               (SELECT DISTINCT REGEXP_SUBSTR (lv_dup_part_number,
                                                        '[^,]+',
                                                        1,
                                                        LEVEL)
                                  FROM DUAL
                             CONNECT BY REGEXP_SUBSTR (lv_dup_part_number,
                                                       '[^,]+',
                                                       1,
                                                       LEVEL)
                                   IS NOT NULL);
                   lv_dup_part_number:= lv_dup_part_number||','||ltab_zsite_cycle_data(rec).refresh_part_number;
                  ELSE
                    lv_dup_part_number:=ltab_zsite_cycle_data(rec).refresh_part_number;
                  END IF;

                  IF NVL(ln_part_cnt,0)<>0
                  THEN
                    v_message:=NULL;
                  ELSE
                     v_message:=SUBSTR(v_message,1,1999);
                  END IF;



                  lv_process_err_tab.EXTEND;
                  lv_err_count:=lv_err_count+1;
                  lv_process_err_tab (lv_err_count) :=
                        RC_INV_MESSAGE_OBJ ('BTS_ADJ',
                                            ltab_zsite_cycle_data (rec).request_id,
                                            NULL,
                                            NULL,
                                            'ERROR',
                                            v_message
                                            );
                  lv_status:='ERROR';
               END IF;
             END IF;

         END LOOP;


         IF lv_err_count=0
           AND ltab_zsite_cycle_data.EXISTS(1)
         THEN
            FOR rec IN ltab_zsite_cycle_data.FIRST ..ltab_zsite_cycle_data.LAST
            LOOP

               UPDATE rc_dgi_cycle_upload_data
                  SET  z_adj_qty= ltab_zsite_cycle_data (rec).z_adj_qty,
                      approver_comments= ltab_zsite_cycle_data (rec).approver_comments,
                      action= ltab_zsite_cycle_data (rec).action,
                      processed_flag= ltab_zsite_cycle_data (rec).processed_flag,
                      processed_date=SYSDATE,
                      processed_by=i_login_user,
                      std_cost = ltab_zsite_cycle_data (rec).std_cost,        --Added STD_COST, ACTUAL_STD_COST, EXT_STD_COST on 03-Aug-2018 by Chandra
                      actual_std_cost = ltab_zsite_cycle_data (rec).actual_std_cost,
                      ext_std_cost = ltab_zsite_cycle_data (rec).ext_std_cost
                WHERE request_id = ltab_zsite_cycle_data (rec).request_id;

                ltab_zsite_cycle_data(rec).processed_date:= sysdate;

                ltab_zsite_cycle_data(rec).processed_by:=i_login_user;
             END LOOP;

         END IF;
      ELSE
        IF i_login_user IS NULL
        THEN
           v_message := 'Session might be expired, Please refresh the tool and reprocess it';

           lv_process_err_tab.EXTEND;
           lv_err_count:=lv_err_count+1;
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
           lv_err_count:=lv_err_count+1;
           lv_process_err_tab (lv_err_count) :=
                RC_INV_MESSAGE_OBJ ('BTS_ADJ',
                                    NULL,
                                    NULL,
                                    NULL,
                                    'ERROR',
                                    v_message);
        END IF;

      END IF;


      IF lv_process_err_tab.EXISTS(1)
      THEN
         o_status:=lv_status;
         o_process_err_msg:=lv_process_err_tab;
      ELSE
         o_status:='SUCCESS';
      END IF;
      /* Start Added on 10-MAY-2018 by sridvasu */

    IF ltab_zsite_cycle_data.EXISTS(1) THEN

      DELETE FROM RC_Z_SITE_CYCLE_MAIL_DATA;


      INSERT INTO RC_Z_SITE_CYCLE_MAIL_DATA (
                                        REQUEST_ID,
                REPAIR_PARTNER_ID,
                REFRESH_PART_NUMBER,
                Z_SITE_ID,
                SUB_INVENTORY,
                Z_CYCLE_CNT,
                Z_SITE_CNT,
                Z_ADJ_QTY,
                C3_ONHAND_QTY,
                USER_COMMENTS,
                UPLOADED_DATE,
                UPLOADED_BY,
                FILE_NAME,
                APPROVER_COMMENTS,
                ACTION,
                PROCESSED_FLAG,
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
                SITE_PROCESSED_DATE,
                D_ATTR2,
                D_ATTR3,
                D_ATTR4,
                STD_COST,         --Added STD_COST, ACTUAL_STD_COST, EXT_STD_COST on 03-Aug-2018 by Chandra
                ACTUAL_STD_COST,
                EXT_STD_COST)
                SELECT *
                 FROM  TABLE (CAST (ltab_zsite_cycle_data AS RC_Z_SITE_CYCLE_DATA_TAB)) tab_data
                       WHERE tab_data.action in ('Approved','Rejected','Recount');

         COMMIT;


      FOR i in (SELECT z_site FROM (SELECT DISTINCT SUBSTR(Z_SITE_ID,1,3) z_site FROM RC_Z_SITE_CYCLE_MAIL_DATA))

      LOOP


       lv_z_site_code :=   i.z_site;

        select RC_Z_SITE_CYCLE_DATA_OBJ(
                REQUEST_ID,
                REPAIR_PARTNER_ID,
                REFRESH_PART_NUMBER,
                Z_SITE_ID,
                SUB_INVENTORY,
                Z_CYCLE_CNT,
                Z_SITE_CNT,
                Z_ADJ_QTY,
                C3_ONHAND_QTY,
                USER_COMMENTS,
                UPLOADED_DATE,
                UPLOADED_BY,
                FILE_NAME,
                APPROVER_COMMENTS,
                ACTION,
                PROCESSED_FLAG,
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
                SITE_PROCESSED_DATE,
                D_ATTR2,
                D_ATTR3,
                D_ATTR4,
                STD_COST,         --Added STD_COST, ACTUAL_STD_COST, EXT_STD_COST on 03-Aug-2018 by Chandra
                ACTUAL_STD_COST,
                EXT_STD_COST
             )
                 BULK COLLECT INTO ltab_zsite_mail_data
                 FROM  RC_Z_SITE_CYCLE_MAIL_DATA tab_data
                       WHERE tab_data.action in ('Approved','Rejected','Recount')
                             and substr(tab_data.z_site_id,1,3) = lv_z_site_code;


         IF ltab_zsite_mail_data.EXISTS(1)
         THEN
            lv_count:=0;

            FOR rec_site IN (SELECT  Z_SITE_ID
                                 FROM RC_Z_SITE_CYCLE_MAIL_DATA
                              WHERE SUBSTR(Z_SITE_ID,1,3) = lv_z_site_code
                                GROUP BY Z_SITE_ID)
            LOOP
              lv_count:=lv_count+1;
               IF lv_count = 1
               THEN
                  lv_z_sites_code:=rec_site.z_site_id;
               ELSE
                  lv_z_sites_code:=lv_z_sites_code||','||rec_site.z_site_id;
               END IF;
            END LOOP;

            BEGIN

              P_ZSITE_EMAIL_NOTIFICATION(i_login_user,NULL,lv_z_sites_code,'N',ltab_zsite_mail_data);

            EXCEPTION
                WHEN OTHERS
                THEN
                  v_message:=v_message||'-'||SUBSTR(SQLERRM,1,200);
                  P_RCEC_ERROR_LOG (
                    I_module_name       => 'P_ZSITE_EMAIL_NOTIFICATION',
                    I_entity_name       =>NULL,
                    I_entity_id         => NULL,
                    I_ext_entity_name   => NULL,
                    I_ext_entity_id     => NULL,
                    I_error_type        => 'EXCEPTION',
                    i_Error_Message     => 'Error getting while executing P_ZSITE_EMAIL_NOTIFICATION for ' || lv_z_site_code || ' location '
                                          || ' <> '
                                          || v_message
                                          || ' LineNo=> '
                                          || DBMS_UTILITY.Format_error_backtrace,
                    I_created_by        => i_login_user,
                    I_updated_by        => i_login_user);
           END;
         END IF;

      END LOOP;

    END IF;

       /* End Added on 10-MAY-2018 by sridvasu */

   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := v_message || '-' || SUBSTR (SQLERRM, 1, 200);


         P_RCEC_ERROR_LOG (
            I_module_name       => 'P_ZSITE_DATA_ADJ_PROCESS',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while executing P_ZSITE_DATA_ADJ_PROCESS '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => i_login_user,
            I_updated_by        => i_login_user);
   END P_ZSITE_DATA_ADJ_PROCESS;

   PROCEDURE P_ZSITE_EMAIL_NOTIFICATION (
      i_login_user             IN VARCHAR2,
      i_upload_id              IN NUMBER,
      i_site_id                IN VARCHAR2,
      i_upload_flag            IN VARCHAR2,
      i_zsite_cycle_data_tab   IN RC_Z_SITE_CYCLE_DATA_TAB)
   IS
      lv_user_id              VARCHAR2 (50);
      lv_username             VARCHAR2 (100);
      lv_uploadId             NUMBER;

      g_error_msg             VARCHAR2 (2000);
      lv_msg_from             VARCHAR2 (500);
      lv_msg_to               VARCHAR2 (500);
      lv_msg_subject          VARCHAR2 (32767);
      lv_msg_text             VARCHAR2 (32767);
      lv_msg_body             VARCHAR2 (32767);
      lv_output_hdr           CLOB;
      lv_mailhost             VARCHAR2 (100) := 'outbound.cisco.com';
      lv_conn                 UTL_SMTP.CONNECTION;
      lv_message_type         VARCHAR2 (100) := 'text/html; charset="iso-8859-1"';
      lv_crlf                 VARCHAR2 (5) := CHR (13) || CHR (10);
      lv_count                NUMBER := 0;
      lv_output               CLOB;
      lv_database_name        VARCHAR2 (50);
      lv_approve_flag         VARCHAR2 (3);
      lv_start_time           VARCHAR2 (100);
      ltab_zsite_cycle_data   RC_Z_SITE_CYCLE_DATA_TAB
                                 := RC_Z_SITE_CYCLE_DATA_TAB ();
      lv_upload_flag          VARCHAR2 (3);
      lv_site_code            VARCHAR2 (10);
      lv_email_sender         VARCHAR2 (100) := 'remarketing-it@cisco.com';
      lv_login_user           VARCHAR2 (50);
      lv_count_col            NUMBER := 0;
      -->> Added on 09-MARY-2018
      lv_upload_date          VARCHAR2(100);
      lv_filename             VARCHAR2(500);
      lv_output1              CLOB;
      v_msg                   VARCHAR2(32767);
   BEGIN
      ltab_zsite_cycle_data := i_zsite_cycle_data_tab;

      lv_upload_flag := UPPER (i_upload_flag);
      lv_site_code := substr(UPPER (i_site_id),1,3);
      lv_login_user := UPPER (TRIM (i_login_user));



      SELECT ora_database_name INTO lv_database_name FROM DUAL;

      SELECT TO_CHAR (SYSDATE, 'MM/DD/YYYY HH:MI:SS PM')
        INTO lv_start_time
        FROM DUAL;


      lv_msg_from := lv_email_sender;

     IF lv_upload_flag = 'Y'
      THEN

         BEGIN
             SELECT first_name || ' ' || last_name
               INTO lv_username
              FROM CRPADM.RC_CS_EMP_DATA
             WHERE UPPER(CS_EMAIL_ADDR) = lv_login_user;
         EXCEPTION
           WHEN OTHERS
           THEN
             lv_username:=i_login_user;
         END;


          IF (lv_database_name = 'FNTR2PRD.CISCO.COM')
          THEN
             lv_msg_subject := lv_msg_subject;

             select EMAIL_RECIPIENTS into lv_msg_to from CRPADM.RC_EMAIL_NOTIFICATIONS where NOTIFICATION_NAME = 'PHYSICAL_CYCLE_COUNT_UL_NOTIFY_PRD_'||lv_site_code||'';

          ELSIF (lv_database_name = 'FNTR2STG.CISCO.COM')
          THEN
             lv_msg_subject := 'STAGE : ' || lv_msg_subject;

             select EMAIL_RECIPIENTS into lv_msg_to from CRPADM.RC_EMAIL_NOTIFICATIONS where NOTIFICATION_NAME = 'PHYSICAL_CYCLE_COUNT_UL_NOTIFY_STG_'||lv_site_code||'';
          ELSE
             lv_msg_subject := 'DEV : ' || lv_msg_subject;

             select EMAIL_RECIPIENTS into lv_msg_to from CRPADM.RC_EMAIL_NOTIFICATIONS where NOTIFICATION_NAME = 'PHYSICAL_CYCLE_COUNT_UL_NOTIFY_DEV_'||lv_site_code||'';
               -- lv_msg_to := 'sridvasu@cisco.com';

          END IF;

         lv_msg_subject :=
               lv_msg_subject || i_site_id||' Physical Cycle Count uploaded successfully, Upload Id: '||i_upload_id;


         lv_msg_text :=
                ' <HTML> Hi Team'
             || ','
             ||'<br><br>'
             ||' <body>'
             ||i_site_id||' Physical cycle count file uploaded successfully. Once Inventory Admins approve the requests, we will notify you to process the adjustments in your system. '||'<br><br>'||'Uploaded By: '||lv_username
             || '<br><br> '||'PLEASE DO NOT REPLY .. This is an Auto generated Email.'||'<br><br>'||'Thanks & Regards,'||'<br>'||'Refresh Central Support team'||' </body> </html>';

     ELSIF lv_upload_flag = 'N' THEN


         lv_msg_subject :=lv_msg_subject || i_site_id|| ' Physical Cycle Count requests status';


         lv_msg_text :=
              '<HTML>'
                  || '<br /><br /> '
                  ||i_site_id|| ' Physical Cycle Count requests given below.'
                  || '<br /><br /> '
                  ||'
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
                        <th>Refresh ID</th><th>Location</th><th>Physical Cycle Count Inventory</th><th>Repair Site system Inventory</th><th>Adjustment Quantity</th><th>Status</th><th>Approver Comments</th><th>Requested By</th><th>Requestor Comments</th><th>File Name</th><th>Requested Date</th><th>Processed By</th><th>Processed Date</th></tr>';



          IF (ora_database_name = 'FNTR2PRD.CISCO.COM')
          THEN
             lv_msg_subject := lv_msg_subject;

             select EMAIL_RECIPIENTS into lv_msg_to from CRPADM.RC_EMAIL_NOTIFICATIONS where NOTIFICATION_NAME = 'REFRESH_SITE_NOTIFICATIONS_PRD_'||lv_site_code||'';

          ELSIF (ora_database_name = 'FNTR2STG.CISCO.COM')
          THEN
             lv_msg_subject := 'STAGE : ' || lv_msg_subject;

             select EMAIL_RECIPIENTS into lv_msg_to from CRPADM.RC_EMAIL_NOTIFICATIONS where NOTIFICATION_NAME = 'REFRESH_SITE_NOTIFICATIONS_STG_'||lv_site_code||'';
          ELSE
             lv_msg_subject := 'DEV : ' || lv_msg_subject;

             select EMAIL_RECIPIENTS into lv_msg_to from CRPADM.RC_EMAIL_NOTIFICATIONS where NOTIFICATION_NAME = 'REFRESH_SITE_NOTIFICATIONS_DEV_'||lv_site_code||'';
--                         lv_msg_to := 'sridvasu@cisco.com';

          END IF;


        IF ltab_zsite_cycle_data.EXISTS(1)
        THEN

           FOR i IN 1 .. ltab_zsite_cycle_data.COUNT
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
                 || ltab_zsite_cycle_data(i).refresh_part_number
                 || '</td><td nowrap>'
                 || ltab_zsite_cycle_data(i).sub_inventory
                 || '</td><td nowrap>'
                 || ltab_zsite_cycle_data(i).z_cycle_cnt
                 || '</td><td>'
                 || ltab_zsite_cycle_data(i).z_site_cnt
                 || '</td><td>'
                 || ltab_zsite_cycle_data(i).z_adj_qty
                 || '</td><td>'
                 || ltab_zsite_cycle_data(i).action
                 || '</td><td>'
                 || ltab_zsite_cycle_data(i).approver_comments
                 || '</td><td nowrap>'
                 || ltab_zsite_cycle_data(i).uploaded_by
                 || '</td><td nowrap>'
                 || ltab_zsite_cycle_data(i).user_comments
                 || '</td><td nowrap>'
                 || ltab_zsite_cycle_data(i).file_name
                 || '</td><td nowrap>'
                 || ltab_zsite_cycle_data(i).uploaded_date
                 || '</td><td nowrap>'
                 || ltab_zsite_cycle_data(i).processed_by
                 || '</td><td nowrap>'
                 || to_char(ltab_zsite_cycle_data(i).processed_date,'DD-MON-YYYY HH:MI:SS')
                 || '</td></tr>';


              lv_count_col := lv_count_col + 1;
           END LOOP;


        END IF;


        lv_msg_text := lv_msg_text || '</table>' || '<br><br> '||'PLEASE DO NOT REPLY .. This is an Auto generated Email.'||'<br><br>'||'Thanks & Regards,'||'<br>'||'Refresh Central Support team'||' </body> </html>';

--     IF i_login_user IS NOT NULL
--     THEN
--        lv_msg_to:=lv_msg_to||','||i_login_user||'@cisco.com';
--     END IF;

--     lv_msg_to:='sridvasu@cisco.com';


     END IF;


          BEGIN
          CRPADM.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (lv_msg_from,
                                                               lv_msg_to,
                                                               lv_msg_subject,
                                                               lv_msg_text,
                                                               null, --lv_filename,
                                                               null --lv_output
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
            I_module_name       => 'P_ZSITE_EMAIL_NOTIFICATION',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while executing P_ZSITE_EMAIL_NOTIFICATION '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => i_login_user,
            I_updated_by        => i_login_user);
   END P_ZSITE_EMAIL_NOTIFICATION;

   FUNCTION F_GET_USER_ZSITES (  i_login_user  IN  VARCHAR2,
                                 i_user_role   IN  VARCHAR2,
                                 i_filter_flag IN  VARCHAR2 DEFAULT 'N')
      RETURN RC_VARCHAR_TAB
   IS
      lv_zsite_codes     VARCHAR2 (32767);
      lv_r_partner_id    NUMBER;
      lv_count           NUMBER := 0;
      lv_filter_flag     VARCHAR2(32767);
      ltab_user_z_sites  RC_VARCHAR_TAB:=RC_VARCHAR_TAB();
   BEGIN

      lv_filter_flag:=UPPER(TRIM(i_filter_flag));


      IF lv_filter_flag = 'N'
      THEN
         IF i_login_user IS NOT NULL AND (UPPER (i_user_role) NOT LIKE '%ADMIN%' AND UPPER (i_user_role) NOT LIKE '%BPM%') -- Added not like BPM also for the RP user on 12-Jul-2018
         THEN

--            BEGIN
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
--
--             IF lv_r_partner_id IS NOT NULL
--             THEN
                  SELECT z_site_id
                    BULK COLLECT INTO ltab_user_z_sites
                    FROM (SELECT zcode || ' - ' || RP.repair_partner_name z_site_id
                            FROM crpadm.rc_product_repair_partner RP
                                         INNER JOIN CRPADM.RC_REPAIR_PARTNER_USER_MAP USR
                                             ON RP.REPAIR_PARTNER_ID = USR.REPAIR_PARTNER_ID
                                   WHERE     ZCODE IS NOT NULL
                                         AND RP.ACTIVE_FLAG = 'Y'
                                         AND USR.ACTIVE_FLAG = 'Y' AND ZCODE <> 'Z32'
                                         AND USER_NAME = i_login_user)
--                           WHERE active_flag = 'Y' 
--                           AND zcode <> 'Z32' -->> Added to restrict Z32 site on 22-Feb-2019
--                           AND repair_partner_id = lv_r_partner_id)
                ORDER BY z_site_id; -->> Added on 09-MAY-2018 by sridvasu to display zsites in ascending order
--             END IF;

          ELSE

                  SELECT z_site_id
                    BULK COLLECT INTO ltab_user_z_sites
                    FROM (SELECT zcode || ' - ' || repair_partner_name z_site_id
                            FROM crpadm.rc_product_repair_partner a
                           WHERE active_flag = 'Y'
                           AND zcode <> 'Z32' -->> Added to restrict Z32 site on 22-Feb-2019
                           )
                ORDER BY z_site_id; -->> Added on 09-MAY-2018 by sridvasu to display zsites in acending order

          END IF;
      ELSE
          IF i_login_user IS NOT NULL AND (UPPER (i_user_role) NOT LIKE '%ADMIN%' AND UPPER (i_user_role) NOT LIKE '%BPM%') -- Added not like BPM also for the RP user on 12-Jul-2018
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

                  SELECT z_site_id
                    BULK COLLECT INTO ltab_user_z_sites
                    FROM rc_dgi_cycle_upload_data
                   WHERE z_site_id IN (SELECT zcode || ' - ' || rp.repair_partner_name
                                         FROM crpadm.rc_product_repair_partner RP
                                         INNER JOIN CRPADM.RC_REPAIR_PARTNER_USER_MAP USR
                                             ON RP.REPAIR_PARTNER_ID = USR.REPAIR_PARTNER_ID
                                   WHERE     ZCODE IS NOT NULL
                                         AND RP.ACTIVE_FLAG = 'Y'
                                         AND USR.ACTIVE_FLAG = 'Y' AND ZCODE <> 'Z32'
                                         AND USER_NAME = i_login_user)
--                                        WHERE     repair_partner_id = lv_r_partner_id
--                                              AND zcode <> 'Z32' -->> Added to restrict Z32 site on 22-Feb-2019
--                                              AND active_flag = 'Y')
                GROUP BY z_site_id
                ORDER BY z_site_id; -->> Added on 09-MAY-2018 by sridvasu to display zsites in acending order

--                 END IF;
          ELSE

                  SELECT z_site_id
                    BULK COLLECT INTO ltab_user_z_sites
                    FROM rc_dgi_cycle_upload_data
                   WHERE z_site_id IN (SELECT zcode || ' - ' || repair_partner_name
                                         FROM crpadm.rc_product_repair_partner a
                                        WHERE active_flag = 'Y'
                                        AND zcode <> 'Z32' -->> Added to restrict Z32 site on 22-Feb-2019
                                        )
                GROUP BY z_site_id
                ORDER BY z_site_id; -->> Added on 09-MAY-2018 by sridvasu to display zsites in acending order

          END IF;

      END IF;

      RETURN ltab_user_z_sites;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := v_message || ' - ' || SUBSTR (SQLERRM, 1, 100);

         P_RCEC_ERROR_LOG (
            I_module_name       => 'F_GET_USER_ZSITES',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while executing F_GET_USER_ZSITES '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => i_login_user,
            I_updated_by        => i_login_user);
   END F_GET_USER_ZSITES;

   FUNCTION F_GET_ZSITE_SUB_INV (i_login_user  IN  VARCHAR2,
                                 i_user_role   IN  VARCHAR2,
                                 i_zsite_code  IN  VARCHAR2)
      RETURN RC_VARCHAR_TAB
   IS
      lv_zsite_codes     VARCHAR2 (32767);
      lv_r_partner_id    NUMBER;
      lv_count           NUMBER := 0;
      lv_filter_flag     VARCHAR2(5);
      lv_z_site_code     VARCHAR2(1000);
      ltab_user_z_sites  RC_VARCHAR_TAB:=RC_VARCHAR_TAB();
   BEGIN

      lv_z_site_code:=UPPER(TRIM(i_zsite_code));

      IF i_login_user IS NOT NULL AND (UPPER (i_user_role) NOT LIKE '%ADMIN%' AND UPPER (i_user_role) NOT LIKE '%BPM%') -- Added not like BPM also for the RP user on 12-Jul-2018
      THEN

--         BEGIN
--            SELECT REPAIR_PARTNER_ID
--              INTO lv_r_partner_id
--              FROM crpadm.RC_REPAIR_PARTNER_USER_MAP
--             WHERE user_name = i_login_user;
--         EXCEPTION
--            WHEN OTHERS
--            THEN
--               lv_r_partner_id := NULL;
--         END;
--
--         IF lv_r_partner_id IS NOT NULL
--         THEN

            IF lv_z_site_code IS NULL
            THEN

              SELECT sub_inventory
                BULK COLLECT INTO ltab_user_z_sites
               FROM rc_dgi_cycle_upload_data
               WHERE z_site_id IN (SELECT zcode || ' - ' || rp.repair_partner_name
                                     FROM crpadm.rc_product_repair_partner RP
                                         INNER JOIN CRPADM.RC_REPAIR_PARTNER_USER_MAP USR
                                             ON RP.REPAIR_PARTNER_ID = USR.REPAIR_PARTNER_ID
                                   WHERE     ZCODE IS NOT NULL
                                         AND RP.ACTIVE_FLAG = 'Y'
                                         AND USR.ACTIVE_FLAG = 'Y' AND ZCODE <> 'Z32'
                                         AND USER_NAME = i_login_user
--                                    WHERE  repair_partner_id =lv_r_partner_id
--                                      AND  active_flag = 'Y'
--                                      AND zcode <> 'Z32' -->> Added to restrict Z32 site on 22-Feb-2019
                                      )
                GROUP BY sub_inventory;

            ELSE
               SELECT sub_inventory
                 BULK COLLECT INTO ltab_user_z_sites
                 FROM rc_dgi_cycle_upload_data
                WHERE z_site_id IN (SELECT zcode || ' - ' || rp.repair_partner_name
                                     FROM crpadm.rc_product_repair_partner RP
                                         INNER JOIN CRPADM.RC_REPAIR_PARTNER_USER_MAP USR
                                             ON RP.REPAIR_PARTNER_ID = USR.REPAIR_PARTNER_ID
                                   WHERE     ZCODE IS NOT NULL
                                         AND RP.ACTIVE_FLAG = 'Y'
                                         AND USR.ACTIVE_FLAG = 'Y' AND ZCODE <> 'Z32'
                                         AND USER_NAME = i_login_user)
--                                    WHERE  repair_partner_id =lv_r_partner_id
--                                      AND zcode <> 'Z32' -->> Added to restrict Z32 site on 22-Feb-2019
--                                      AND  active_flag = 'Y')
                  AND z_site_id = lv_z_site_code
               GROUP BY sub_inventory;

            END IF;
--         END IF;
      ELSE
         IF lv_z_site_code IS NULL
         THEN
            SELECT sub_inventory
              BULK COLLECT INTO ltab_user_z_sites
              FROM rc_dgi_cycle_upload_data
             WHERE z_site_id IN (SELECT zcode || ' - ' || repair_partner_name
                                     FROM crpadm.rc_product_repair_partner a
                                  WHERE active_flag = 'Y'
                                  AND zcode <> 'Z32' -->> Added to restrict Z32 site on 22-Feb-2019
                                  )
            GROUP BY sub_inventory;
         ELSE
            SELECT sub_inventory
              BULK COLLECT INTO ltab_user_z_sites
              FROM rc_dgi_cycle_upload_data
             WHERE z_site_id IN (SELECT zcode || ' - ' || repair_partner_name
                                     FROM crpadm.rc_product_repair_partner a
                                  WHERE active_flag = 'Y'
                                  AND zcode <> 'Z32' -->> Added to restrict Z32 site on 22-Feb-2019
                                  )
              AND z_site_id = lv_z_site_code
            GROUP BY sub_inventory;
         END IF;
      END IF;


      RETURN ltab_user_z_sites;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message := v_message || ' - ' || SUBSTR (SQLERRM, 1, 100);

         P_RCEC_ERROR_LOG (
            I_module_name       => 'F_GET_ZSITE_SUB_INV',
            I_entity_name       => NULL,
            I_entity_id         => NULL,
            I_ext_entity_name   => NULL,
            I_ext_entity_id     => NULL,
            I_error_type        => 'EXCEPTION',
            i_Error_Message     =>    'Error getting while executing F_GET_ZSITE_SUB_INV '
                                   || ' <> '
                                   || v_message
                                   || ' LineNo=> '
                                   || DBMS_UTILITY.Format_error_backtrace,
            I_created_by        => i_login_user,
            I_updated_by        => i_login_user);
   END F_GET_ZSITE_SUB_INV;

END RC_ZSITE_CYCLE_ADJ_PKG;
/