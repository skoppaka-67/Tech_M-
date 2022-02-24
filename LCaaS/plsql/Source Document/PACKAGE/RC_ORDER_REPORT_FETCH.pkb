CREATE OR REPLACE PACKAGE BODY CRPREP./*AppDB: 1039343*/                                              "RC_ORDER_REPORT_FETCH" 
AS
   /**************************************************************************************************************************************************************************
             || Object Name     :
             || Modules        :
             || Description    :
             || Modification History
             ||
             ||----------------------------------------------------------------------------------------------------------------------------------------------------------------
             ||Date                       By                     Version        Comments
             ||----------------------------------------------------------------------------------------------------------------------------------------------------------------
             |6-6-2017             obabrier                   1.0            Initial package
            | 5-17-2018             obabrier                   2.0           Updated RC_HISTORY_DETAILS_FETCH procedure
                                                                             to fix data mismatch in CCW order Backlog Report
             ||-----------------------------------------------------------------------------------------------------------------------------------------------------------
     **************************************************************************************************************************************************************************/

   /*------------------------ Procedure to calculate BL Products ---------------------------------------*/
   PROCEDURE RC_HISTORY_DETAILS_EXTRACT (
      i_user_id              IN     VARCHAR2,
      i_min_row              IN     NUMBER,
      i_max_row              IN     NUMBER,
      --advance fitlers start
      i_fiscal_year          IN     VARCHAR2,
      i_part_number          IN     VARCHAR2,
      i_order_status         IN     VARCHAR2,
      i_order_number         IN     VARCHAR2,
      i_end_customer_name    IN     VARCHAR2,
      i_theater              IN     VARCHAR2,
      --advance fitlers end
      i_sort_column_name     IN     VARCHAR2,
      i_sort_column_by       IN     VARCHAR2,
      i_filter_list          IN     RC_NEW_FILTER_OBJ_LIST,
      o_data_fetch_list         OUT ORDER_DETAILS_LIST,
      o_total_record_count      OUT NUMBER,
      o_load_date               OUT VARCHAR2,
      o_status                  OUT VARCHAR2,
      o_booked_orders           OUT NUMBER)
   IS
      lv_fiscal_year             VARCHAR2 (32767);
      lv_part_number             VARCHAR2 (32767);
      lv_order_status            VARCHAR2 (32767);
      lv_order_number            VARCHAR2 (32767);
      lv_end_customer_name       VARCHAR2 (32767);
      lv_theater                 VARCHAR2 (32767);
      lv_fiscal_quarter_check    VARCHAR2 (10);
      lv_booked_qry              VARCHAR2 (32767);
      lv_sort_column_name        VARCHAR2 (30);
      lv_sort_column_by          VARCHAR2 (10);
      lv_data_fetch_list         ORDER_DETAILS_LIST;
      lv_final_query             CLOB;
      lv_constraint_query        CLOB;
      lv_sort_query              CLOB;
      lv_count_query             CLOB;
      lv_total_record_count      NUMBER;
      lv_load_date               DATE;
      lv_filter_list             RC_NEW_FILTER_OBJ_LIST;
      lv_table_name              VARCHAR2 (50);
      lv_filter_query            CLOB;
      g_error_msg                CLOB;



      lv_i_refresh_part_number   VARCHAR2 (32767);
      lv_idx                     NUMBER;
      lv_cur_part_number         VARCHAR2 (32767);
   BEGIN
      lv_data_fetch_list := ORDER_DETAILS_LIST ();
      lv_fiscal_year := i_fiscal_year;
      lv_part_number := i_part_number;
      lv_order_status := i_order_status;
      lv_order_number := i_order_number;
      lv_end_customer_name := i_end_customer_name;
      lv_theater := i_theater;
      lv_sort_column_name := UPPER (TRIM (i_sort_column_name));
      lv_sort_column_by := UPPER (TRIM (i_sort_column_by));
      lv_filter_list := i_filter_list;

      --      IF lv_generated_date is not null
      --      then
      --      o_load_date := lv_generated_date;
      --
      --      else
      --       Begin
      --      select MAX(LAST_REFRESH_DATE)
      --           INTO lv_load_date
      --           FROM all_mviews
      --          where mview_name = 'RC_INV_BTS_C3_MV';
      --          o_load_date := TO_CHAR (lv_load_date, 'mm/dd/yyyy hh:mi:ss AM');
      --      EXCEPTION
      --         WHEN OTHERS
      --         THEN
      --            o_load_date := NULL;
      --      END;
      --
      --
      --
      --      END If;

      SELECT MAX (UPDATED_DATE)
        INTO lv_load_date
        FROM RMKTGADM.RMK_SSOT_TRANSACTIONS;

      o_load_date :=
         TO_CHAR (lv_load_date, 'mm/dd/yyyy hh:mi:ss AM');

      IF (lv_fiscal_year IS NULL)
      THEN
         SELECT fiscal_quarter_name
           INTO lv_fiscal_year
           FROM rmktgadm.CDM_TIME_HIERARCHY_DIM
          WHERE calendar_date = TRUNC (SYSDATE);
      END IF;

      SELECT DISTINCT CURRENT_FISCAL_QUARTER_FLAG
        INTO lv_fiscal_quarter_check
        FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
       WHERE FISCAL_QUARTER_NAME = lv_fiscal_year;

      lv_final_query :=
         'SELECT ORDER_DETAILS_OBJ (
       gtm,
       theater,
       region_name,
       fiscal_month_id,
       fiscal_week_name,
       fiscal_week_number,
       sales_order_number,
       so_line_id,
       quote_id,
       quote_line_id,
       web_order_id,
       web_order_line_id,
       order_status,
       purchase_order_number,
       order_creation_date,
       order_submission_date,
       part_number,
       quantity,
       list_price,
       ext_list_price,
       currency_code,
       rounded_unit_net_price,
       extended_net_price,
       EXT_NET_PRICE_USD,
       DEAL_ID,
       end_customer_name,
       ship_to_customer_name,
       bill_to_customer_type,
       invoice_to_customer_name,
       order_created_by,
       order_submitted_by,
       order_updated_on,
       order_line_updated_on,
       reseller_customer_name,
       order_line_created_on,
       customer_name,
       order_line_created_by,
       order_line_updated_by,
       hold_name,
       EX_STATE,
       END_CUSTOMER_COUNTRY,
       PRODUCT_FAMILY,
       customer_request_date,
       ship_date,
       channel,
       inventory_site)
  FROM (  SELECT
       gtm,
       theater,
       region_name,
       fiscal_month_id,
       fiscal_week_name,
       fiscal_week_number,
       sales_order_number,
       so_line_id,
       quote_id,
       quote_line_id,
       web_order_id,
       web_order_line_id,
       order_status,
       purchase_order_number,
       order_creation_date,
       order_submission_date,
       part_number,
       quantity,
       list_price,
       ext_list_price,
       currency_code,
       rounded_unit_net_price,
       extended_net_price,
       EXT_NET_PRICE_USD,
       DEAL_ID,
       end_customer_name,
       ship_to_customer_name,
       bill_to_customer_type,
       invoice_to_customer_name,
       order_created_by,
       order_submitted_by,
       order_updated_on,
       order_line_updated_on,
       reseller_customer_name,
       order_line_created_on,
       customer_name,
       order_line_created_by,
       order_line_updated_by,
       hold_name,
       EX_STATE,
       END_CUSTOMER_COUNTRY,
       PRODUCT_FAMILY,
       customer_request_date,
       ship_date,
       channel,
       inventory_site,
       fiscal_quarter
 FROM (  SELECT
       gtm,
       theater,
       region_name,
       fiscal_month_id,
       fiscal_week_name,
       fiscal_week_number,
       sales_order_number,
       so_line_id,
       quote_id,
       quote_line_id,
       web_order_id,
       web_order_line_id,
       order_status,
       purchase_order_number,
       order_creation_date,
       order_submission_date,
       part_number,
       quantity,
       list_price,
       ext_list_price,
       currency_code,
       rounded_unit_net_price,
       extended_net_price,
       EXT_NET_PRICE_USD,
       DEAL_ID,
       end_customer_name,
       ship_to_customer_name,
       bill_to_customer_type,
       invoice_to_customer_name,
       order_created_by,
       order_submitted_by,
       order_updated_on,
       order_line_updated_on,
       reseller_customer_name,
       order_line_created_on,
       customer_name,
       order_line_created_by,
       order_line_updated_by,
       hold_name,
       EX_STATE,
       END_CUSTOMER_COUNTRY,
       PRODUCT_FAMILY,
       customer_request_date,
       ship_date,
       fiscal_quarter,
       channel,
       inventory_site,
       ROWNUM RNUM
  FROM (  SELECT DISTINCT
                 hdr.inventory_flow AS GTM,
                 NVL (
                    (SELECT DISTINCT
                            NVL (map.region_name,
                                 ''Country Mapping Unavailable'')
                       FROM VAVNI_CISCO_RSCM_ADMIN.oct_mdm_region_country_map map --need to change to Crpadm
                      WHERE     co.INVOICE_TO_CUSTOMER_COUNTRY_CD =
                                   map.country_name(+)
                            AND map.ACTIVE = ''A''),
                    ''Country Mapping Unavailable'')
                    AS Theater,
                 (SELECT REGION_NAME
                    FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ADM_BSF_COUNTRYREG_MASTER --need to change to Crpadm
                   WHERE COUNTRY_CODE = ssot.THEATER)
                    REGION_NAME,
                 dim.fiscal_month_id,
                 dim.fiscal_week_name,
                 dim.fiscal_week_number,
                 ssot.sales_order_number,
                 SSOT.SO_LINE_ID,
                 co.QUOTE_ID,
                 co.QUOTE_LINE_ID,
                 co.WEB_ORDER_ID,
                 co.ORDER_LINE_ID AS web_order_line_id,
                 (ssot.WEB_ORDER_STATUS || ''-'' || ssot.SO_LINE_STATUS)
                    AS ORDER_STATUS,
                 co.PURCHASE_ORDER_NUMBER,
                 co.ORDER_CREATION_DATE,
                 co.ORDER_SUBMISSION_DATE,
                 co.PART_NUMBER,
                 co.QUANTITY,
                 co.LIST_PRICE,
                 co.EXT_LIST_PRICE,
                 co.CURRENCY_CODE,
                 co.ROUNDED_UNIT_NET_PRICE,
                 co.EXTENDED_NET_PRICE,
                 ssot.EXT_NET_PRICE_USD,
                 ssot.DEAL_ID,
                 co.END_CUSTOMER_NAME,
                 co.SHIP_TO_CUSTOMER_NAME,
                 co.BILL_TO_CUSTOMER_TYPE,
                 co.INVOICE_TO_CUSTOMER_NAME,
                 co.ORDER_CREATED_BY,
                 co.ORDER_SUBMITTED_BY,
                 co.ORDER_UPDATED_ON,
                 co.ORDER_LINE_UPDATED_ON,
                 co.RESELLER_CUSTOMER_NAME,
                 co.ORDER_LINE_CREATED_ON,
                 --(Start) commented by hkarka on 20-DEC-2017
                 /*
                 (SELECT RCTM_STD_COUNTRY
                    FROM rmktgadm.RMK_COUNTRY_THEATER_MAP
                   WHERE RCTM_STD_COUNTRY_CODE =
                            co.INVOICE_TO_CUSTOMER_COUNTRY_CD)
                 */ 
                 --(End) commented by hkarka on 20-DEC-2017
                 co.INVOICE_TO_CUSTOMER_NAME --added by hkarka on 20-DEC-2017
                    customer_name,
                 co.ORDER_LINE_CREATED_BY,
                 co.ORDER_LINE_UPDATED_BY,
                 ssot.HOLD_NAME,
                 EX.EX_STATE,
                 NVL (Ex.EX_COUNTRY, ''NO END CUSTOMER'') END_CUSTOMER_COUNTRY,
                 pm.PRODUCT_FAMILY,
                 customer_request_date,
                 (SELECT MAX (shp.ship_date)
                    FROM crpsc.xxcrpsc_od_shipment_dtls_intf shp
                   WHERE     SSOT.sales_order_number = shp.SALES_ORDER_NO
                         AND SSOT.sales_order_line_number = shp.line_no)
                    ship_date,
                    ssot.CHANNEL channel,
                    ssot.INVENTORY_SITE inventory_site,
                    dim.fiscal_quarter_name fiscal_quarter
            FROM rmktgadm.co_order_rf_publish co,
                 rmktgadm.xxcpo_rmk_reservation_header hdr,
                 rmktgadm.rmk_ssot_transactions ssot,
                 rmktgadm.CDM_TIME_HIERARCHY_DIM dim,
                 CRPADM.EX_CUSTOMER_ADDRESS EX,
                 CRPADM.RC_PRODUCT_MASTER PM
           WHERE     1 = 1
                 AND co.web_order_id = hdr.web_order_id
                 AND co.order_line_id = HDR.WEB_ORDER_LINE_ID
                 AND co.web_order_id = ssot.web_order_id
                 AND co.order_line_id = ssot.WEB_ORDER_LINE_ID
                 AND CO.END_CUSTOMER_SITE_ID = EX.EX_SITE_USE_ID(+)
                 AND PM.REFRESH_PART_NUMBER = CO.PART_NUMBER
                 AND dim.calendar_date = TRUNC (order_creation_date)
                 AND hdr.active_flag = 1
                 AND is_refurbished = ''Y'' AND ssot.SALES_ORDER_NUMBER IS NOT NULL
                 AND (   TRUNC (co.order_creation_date) >=
                            TO_DATE (''09/10/2016'', ''mm/dd/yyyy'')
                      OR TRUNC (co.order_line_created_on) >=
                            TO_DATE (''09/10/2016'', ''mm/dd/yyyy''))) Where 1=1';
      /* Refer History table when Generated Date filter value is Not Null */

      --(start) commented by hkarka on 19-DEC-2017
      /*
              lv_count_query := 'SELECT COUNT(*)             FROM rmktgadm.co_order_rf_publish co,
                       rmktgadm.xxcpo_rmk_reservation_header hdr,
                       rmktgadm.rmk_ssot_transactions ssot,
                       rmktgadm.CDM_TIME_HIERARCHY_DIM dim,
                       CRPADM.EX_CUSTOMER_ADDRESS EX,
                       CRPADM.RC_PRODUCT_MASTER PM
                 WHERE     1 = 1
                       AND co.web_order_id = hdr.web_order_id
                       AND co.order_line_id = HDR.WEB_ORDER_LINE_ID
                       AND co.web_order_id = ssot.web_order_id
                       AND co.order_line_id = ssot.WEB_ORDER_LINE_ID
                       AND CO.END_CUSTOMER_SITE_ID = EX.EX_SITE_USE_ID(+)
                       AND PM.REFRESH_PART_NUMBER = CO.PART_NUMBER
                       AND dim.calendar_date = TRUNC (order_creation_date)
                       AND hdr.active_flag = 1
                       AND is_refurbished = ''Y''
                       AND (   TRUNC (co.order_creation_date) >=
                                  TO_DATE (''09/10/2016'', ''mm/dd/yyyy'')
                            OR TRUNC (co.order_line_created_on) >=
                                  TO_DATE (''09/10/2016'', ''mm/dd/yyyy'')) ';
      */
      --(end) commented by hkarka on 19-DEC-2017

      --(start) added by hkarka on 19-DEC-2017
      lv_count_query :=
         'SELECT COUNT(*) from            
        (select 
        DISTINCT
                 hdr.inventory_flow AS GTM,
                 NVL (
                    (SELECT DISTINCT
                            NVL (map.region_name,
                                 ''Country Mapping Unavailable'')
                       FROM VAVNI_CISCO_RSCM_ADMIN.oct_mdm_region_country_map map --need to change to Crpadm
                      WHERE     co.INVOICE_TO_CUSTOMER_COUNTRY_CD =
                                   map.country_name(+)
                            AND map.ACTIVE = ''A''),
                    ''Country Mapping Unavailable'')
                    AS Theater,
                 (SELECT REGION_NAME
                    FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ADM_BSF_COUNTRYREG_MASTER --need to change to Crpadm
                   WHERE COUNTRY_CODE = ssot.THEATER)
                    REGION_NAME,
                 dim.fiscal_month_id,
                 dim.fiscal_week_name,
                 dim.fiscal_week_number,
                 ssot.sales_order_number,
                 SSOT.SO_LINE_ID,
                 co.QUOTE_ID,
                 co.QUOTE_LINE_ID,
                 co.WEB_ORDER_ID,
                 co.ORDER_LINE_ID AS web_order_line_id,
                 (ssot.WEB_ORDER_STATUS || ''-'' || ssot.SO_LINE_STATUS)
                    AS ORDER_STATUS,
                 co.PURCHASE_ORDER_NUMBER,
                 co.ORDER_CREATION_DATE,
                 co.ORDER_SUBMISSION_DATE,
                 co.PART_NUMBER,
                 co.QUANTITY,
                 co.LIST_PRICE,
                 co.EXT_LIST_PRICE,
                 co.CURRENCY_CODE,
                 co.ROUNDED_UNIT_NET_PRICE,
                 co.EXTENDED_NET_PRICE,
                 ssot.EXT_NET_PRICE_USD,
                 ssot.DEAL_ID,
                 co.END_CUSTOMER_NAME,
                 co.SHIP_TO_CUSTOMER_NAME,
                 co.BILL_TO_CUSTOMER_TYPE,
                 co.INVOICE_TO_CUSTOMER_NAME,
                 co.ORDER_CREATED_BY,
                 co.ORDER_SUBMITTED_BY,
                 co.ORDER_UPDATED_ON,
                 co.ORDER_LINE_UPDATED_ON,
                 co.RESELLER_CUSTOMER_NAME,
                 co.ORDER_LINE_CREATED_ON,
                 (SELECT RCTM_STD_COUNTRY
                    FROM rmktgadm.RMK_COUNTRY_THEATER_MAP
                   WHERE RCTM_STD_COUNTRY_CODE =
                            co.INVOICE_TO_CUSTOMER_COUNTRY_CD)
                    customer_name,
                 co.ORDER_LINE_CREATED_BY,
                 co.ORDER_LINE_UPDATED_BY,
                 ssot.HOLD_NAME,
                 EX.EX_STATE,
                 NVL (Ex.EX_COUNTRY, ''NO END CUSTOMER'') END_CUSTOMER_COUNTRY,
                 pm.PRODUCT_FAMILY,
                 customer_request_date,
                 (SELECT MAX (shp.ship_date)
                    FROM crpsc.xxcrpsc_od_shipment_dtls_intf shp
                   WHERE     SSOT.sales_order_number = shp.SALES_ORDER_NO
                         AND SSOT.sales_order_line_number = shp.line_no)
                    ship_date,
                    ssot.CHANNEL channel,
                    ssot.INVENTORY_SITE inventory_site,
                    dim.fiscal_quarter_name fiscal_quarter
        FROM rmktgadm.co_order_rf_publish co,
                 rmktgadm.xxcpo_rmk_reservation_header hdr,
                 rmktgadm.rmk_ssot_transactions ssot,
                 rmktgadm.CDM_TIME_HIERARCHY_DIM dim,
                 CRPADM.EX_CUSTOMER_ADDRESS EX,
                 CRPADM.RC_PRODUCT_MASTER PM
           WHERE     1 = 1
                 AND co.web_order_id = hdr.web_order_id
                 AND co.order_line_id = HDR.WEB_ORDER_LINE_ID
                 AND co.web_order_id = ssot.web_order_id
                 AND co.order_line_id = ssot.WEB_ORDER_LINE_ID
                 AND CO.END_CUSTOMER_SITE_ID = EX.EX_SITE_USE_ID(+)
                 AND PM.REFRESH_PART_NUMBER = CO.PART_NUMBER
                 AND dim.calendar_date = TRUNC (order_creation_date)
                 AND ssot.SALES_ORDER_NUMBER IS NOT NULL
                 AND hdr.active_flag = 1
                 AND is_refurbished = ''Y''
                 AND (   TRUNC (co.order_creation_date) >=
                            TO_DATE (''09/10/2016'', ''mm/dd/yyyy'')
                      OR TRUNC (co.order_line_created_on) >=
                            TO_DATE (''09/10/2016'', ''mm/dd/yyyy'')) ';

      --(end) added by hkarka on 19-DEC-2017


      IF (lv_fiscal_year IS NOT NULL)
      THEN
         lv_constraint_query :=
               lv_constraint_query
            || ' AND fiscal_quarter = '''
            || lv_fiscal_year
            || '''';

         lv_count_query :=
               lv_count_query
            || 'AND dim.fiscal_quarter_name = '''
            || lv_fiscal_year
            || '''';
      END IF;

      IF (lv_order_status IS NOT NULL)
      THEN
         lv_constraint_query :=
               lv_constraint_query
            || ' AND order_status = '''
            || lv_order_status
            || '''';

         lv_count_query :=
               lv_count_query
            || ' AND (ssot.WEB_ORDER_STATUS || ''-'' || ssot.SO_LINE_STATUS) = '''
            || lv_order_status
            || '''';
      END IF;

      IF (lv_theater IS NOT NULL)
      THEN
         lv_constraint_query :=
            lv_constraint_query || ' AND theater = ''' || lv_theater || '''';

         lv_count_query :=
               lv_count_query
            || ' AND                  NVL (
                    (SELECT DISTINCT
                            NVL (map.region_name,
                                 ''Country Mapping Unavailable'')
                       FROM VAVNI_CISCO_RSCM_ADMIN.oct_mdm_region_country_map map
                      WHERE     co.INVOICE_TO_CUSTOMER_COUNTRY_CD =
                                   map.country_name(+)
                            AND map.ACTIVE = ''A''),
                    ''Country Mapping Unavailable'') = '''
            || lv_theater
            || '''';
      END IF;

      /* Advance filter on part Number */

      IF lv_part_number IS NOT NULL
      THEN
         IF (lv_part_number IS NOT NULL)
         THEN
            lv_constraint_query := lv_constraint_query || ' AND ( ';
            lv_count_query := lv_count_query || ' AND ( ';

            lv_i_refresh_part_number := lv_part_number;
            lv_idx := INSTR (lv_i_refresh_part_number, ',');


            IF lv_idx = 0
            THEN
               lv_i_refresh_part_number :=
                  REPLACE (lv_i_refresh_part_number, '*', '');
               lv_constraint_query :=
                     lv_constraint_query
                  || 'UPPER(part_number) LIKE UPPER(''%'
                  || lv_i_refresh_part_number
                  || '%'')';

               lv_count_query :=
                     lv_count_query
                  || 'UPPER(co.PART_NUMBER) LIKE UPPER(''%'
                  || lv_i_refresh_part_number
                  || '%'')';
            ELSE
               lv_cur_part_number :=
                  SUBSTR (lv_i_refresh_part_number,
                          1,
                          INSTR (lv_i_refresh_part_number, ',') - 1);
               lv_cur_part_number := REPLACE (lv_cur_part_number, '*', '');

               lv_constraint_query :=
                     lv_constraint_query
                  || 'UPPER(part_number) LIKE UPPER(''%'
                  || lv_cur_part_number
                  || '%'')';

               lv_count_query :=
                     lv_count_query
                  || 'UPPER(co.PART_NUMBER) LIKE UPPER(''%'
                  || lv_cur_part_number
                  || '%'')';

               lv_i_refresh_part_number :=
                  SUBSTR (lv_i_refresh_part_number, lv_idx + LENGTH (' '));
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
                        SUBSTR (lv_i_refresh_part_number,
                                lv_idx + LENGTH (','));
                     lv_cur_part_number :=
                        REPLACE (lv_cur_part_number, '*', '');
                     lv_constraint_query :=
                           lv_constraint_query
                        || ' OR UPPER(part_number) LIKE  UPPER(''%'
                        || lv_cur_part_number
                        || '%'')';

                     lv_count_query :=
                           lv_count_query
                        || ' OR UPPER(co.PART_NUMBER) LIKE  UPPER(''%'
                        || lv_cur_part_number
                        || '%'')';
                  ELSE
                     lv_i_refresh_part_number :=
                        REPLACE (lv_i_refresh_part_number, '*', '');
                     lv_constraint_query :=
                           lv_constraint_query
                        || ' OR UPPER(part_number) LIKE  UPPER(''%'
                        || lv_i_refresh_part_number
                        || '%'')';
                     lv_count_query :=
                           lv_count_query
                        || ' OR UPPER(co.PART_NUMBER) LIKE  UPPER(''%'
                        || lv_i_refresh_part_number
                        || '%'')';

                     EXIT;
                  END IF;
               END LOOP;
            END IF;
         END IF;

         lv_constraint_query := lv_constraint_query || ')';
         lv_count_query := lv_count_query || ')';
      END IF;



      IF lv_order_number IS NOT NULL
      THEN
         IF (lv_order_number IS NOT NULL)
         THEN
            lv_constraint_query := lv_constraint_query || ' AND ( ';
            lv_count_query := lv_count_query || ' AND ( ';


            lv_i_refresh_part_number := lv_order_number;
            lv_idx := INSTR (lv_i_refresh_part_number, ',');


            IF lv_idx = 0
            THEN
               lv_i_refresh_part_number :=
                  REPLACE (lv_i_refresh_part_number, '*', '');
               lv_constraint_query :=
                     lv_constraint_query
                  || 'UPPER(SALES_ORDER_NUMBER) LIKE UPPER(''%'
                  || lv_i_refresh_part_number
                  || '%'')';

               lv_count_query :=
                     lv_count_query
                  || 'UPPER(ssot.sales_order_number) LIKE UPPER(''%'
                  || lv_i_refresh_part_number
                  || '%'')';
            ELSE
               lv_cur_part_number :=
                  SUBSTR (lv_i_refresh_part_number,
                          1,
                          INSTR (lv_i_refresh_part_number, ',') - 1);
               lv_cur_part_number := REPLACE (lv_cur_part_number, '*', '');

               lv_constraint_query :=
                     lv_constraint_query
                  || 'UPPER(SALES_ORDER_NUMBER) LIKE UPPER(''%'
                  || lv_cur_part_number
                  || '%'')';
               lv_count_query :=
                     lv_count_query
                  || 'UPPER(ssot.sales_order_number) LIKE UPPER(''%'
                  || lv_cur_part_number
                  || '%'')';

               lv_i_refresh_part_number :=
                  SUBSTR (lv_i_refresh_part_number, lv_idx + LENGTH (' '));
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
                        SUBSTR (lv_i_refresh_part_number,
                                lv_idx + LENGTH (','));
                     lv_cur_part_number :=
                        REPLACE (lv_cur_part_number, '*', '');
                     lv_constraint_query :=
                           lv_constraint_query
                        || ' OR UPPER(SALES_ORDER_NUMBER) LIKE  UPPER(''%'
                        || lv_cur_part_number
                        || '%'')';
                     lv_count_query :=
                           lv_count_query
                        || ' OR UPPER(ssot.sales_order_number) LIKE  UPPER(''%'
                        || lv_cur_part_number
                        || '%'')';
                  ELSE
                     lv_i_refresh_part_number :=
                        REPLACE (lv_i_refresh_part_number, '*', '');
                     lv_constraint_query :=
                           lv_constraint_query
                        || ' OR UPPER(SALES_ORDER_NUMBER) LIKE  UPPER(''%'
                        || lv_i_refresh_part_number
                        || '%'')';
                     lv_count_query :=
                           lv_count_query
                        || ' OR UPPER(ssot.sales_order_number) LIKE  UPPER(''%'
                        || lv_i_refresh_part_number
                        || '%'')';

                     EXIT;
                  END IF;
               END LOOP;
            END IF;
         END IF;

         lv_constraint_query := lv_constraint_query || ')';
         lv_count_query := lv_count_query || ')';
      END IF;

      IF lv_end_customer_name IS NOT NULL
      THEN
         IF (lv_end_customer_name IS NOT NULL)
         THEN
            lv_constraint_query := lv_constraint_query || ' AND ( ';
            lv_count_query := lv_count_query || ' AND ( ';


            lv_i_refresh_part_number := lv_end_customer_name;
            lv_idx := INSTR (lv_i_refresh_part_number, ',');


            IF lv_idx = 0
            THEN
               lv_i_refresh_part_number :=
                  REPLACE (lv_i_refresh_part_number, '*', '');
               lv_constraint_query :=
                     lv_constraint_query
                  || 'UPPER(end_customer_name) LIKE UPPER(''%'
                  || lv_i_refresh_part_number
                  || '%'')';

               lv_count_query :=
                     lv_count_query
                  || 'UPPER(co.END_CUSTOMER_NAME) LIKE UPPER(''%'
                  || lv_i_refresh_part_number
                  || '%'')';
            ELSE
               lv_cur_part_number :=
                  SUBSTR (lv_i_refresh_part_number,
                          1,
                          INSTR (lv_i_refresh_part_number, ',') - 1);
               lv_cur_part_number := REPLACE (lv_cur_part_number, '*', '');

               lv_constraint_query :=
                     lv_constraint_query
                  || 'UPPER(end_customer_name) LIKE UPPER(''%'
                  || lv_cur_part_number
                  || '%'')';
               lv_count_query :=
                     lv_count_query
                  || 'UPPER(co.END_CUSTOMER_NAME) LIKE UPPER(''%'
                  || lv_cur_part_number
                  || '%'')';
               lv_i_refresh_part_number :=
                  SUBSTR (lv_i_refresh_part_number, lv_idx + LENGTH (' '));
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
                        SUBSTR (lv_i_refresh_part_number,
                                lv_idx + LENGTH (','));
                     lv_cur_part_number :=
                        REPLACE (lv_cur_part_number, '*', '');
                     lv_constraint_query :=
                           lv_constraint_query
                        || ' OR UPPER(end_customer_name) LIKE  UPPER(''%'
                        || lv_cur_part_number
                        || '%'')';

                     lv_count_query :=
                           lv_count_query
                        || ' OR UPPER(co.END_CUSTOMER_NAME) LIKE  UPPER(''%'
                        || lv_cur_part_number
                        || '%'')';
                  ELSE
                     lv_i_refresh_part_number :=
                        REPLACE (lv_i_refresh_part_number, '*', '');
                     lv_constraint_query :=
                           lv_constraint_query
                        || ' OR UPPER(end_customer_name) LIKE  UPPER(''%'
                        || lv_i_refresh_part_number
                        || '%'')';
                     lv_count_query :=
                           lv_count_query
                        || ' OR UPPER(co.END_CUSTOMER_NAME) LIKE  UPPER(''%'
                        || lv_i_refresh_part_number
                        || '%'')';

                     EXIT;
                  END IF;
               END LOOP;
            END IF;
         END IF;

         lv_constraint_query := lv_constraint_query || ')';
         lv_count_query := lv_count_query || ')';
      END IF;


      lv_final_query := lv_final_query || lv_constraint_query;

      IF lv_fiscal_quarter_check = 'Y'
      THEN
         lv_booked_qry :=
            'select
   sum(TOTAL_BOOKINGS) from (select calendar_date,ORDER_NUMBER SALES_ORDER_NUMBER,
                 PRODUCT_ID part_number,
                 COUNTRY THEATER,
                 end_user_customer end_customer_name,sum(NVL(REV_CUR_WK,0)+NVL(REV_NEXT_WK,0)+NVL(REV_CUR_QTR_REM_WKS,0)+NVL(REV_NEXT_QTR,0)+NVL(REV_TO_BE_SCHEDULED,0)
   +NVL(REV_NO_INVENTORY,0)+NVL(REV_IN_TRANSIT,0)) TOTAL_BOOKINGS,
   dim.fiscal_quarter_name fiscal_quarter,(select MAX (web_order_Status || ''-'' || so_line_Status) 
   from RMKTGADM.RMK_SSOT_TRANSACTIONS TR where TR.SALES_ORDER_NUMBER=BSF.ORDER_NUMBER and TR.SO_LINE_ID=BSF.MFG_LINE_ID
   and tr.sales_order_line_number=bsf.line_number) as order_status
    from CRPADM.RC_MASTER_BACKLOG BSF,RMKTGADM.CDM_TIME_HIERARCHY_DIM DIM
  GROUP BY CALENDAR_DATE,FISCAL_QUARTER_NAME,ORDER_NUMBER,MFG_LINE_ID,PRODUCT_ID,country,end_user_customer,line_number
  )  WHERE TRUNC(CALENDAR_DATE)=TRUNC(SYSDATE)';
      ELSE
         lv_booked_qry :=
            'select
   sum(TOTAL_BOOKINGS) from (select calendar_date,SO_NUMBER SALES_ORDER_NUMBER,
                 refresh_part_number part_number,
                 COUNTRY THEATER,
                 end_user_customer end_customer_name,sum(NVL(REV_CUR_WK,0)+NVL(REV_NEXT_WK,0)+NVL(REV_CUR_QTR_REM_WKS,0)+NVL(REV_NEXT_QTR,0)+NVL(REV_TO_BE_SCHEDULED,0)
   +NVL(REV_NO_INVENTORY,0)+NVL(REV_IN_TRANSIT,0)) TOTAL_BOOKINGS,
   dim.fiscal_quarter_name fiscal_quarter,(select MAX (web_order_Status || ''-'' || so_line_Status) 
   from RMKTGADM.RMK_SSOT_TRANSACTIONS TR where TR.SALES_ORDER_NUMBER=BSF.SO_NUMBER and TR.SO_LINE_ID=BSF.SO_LINE_ID
   and tr.sales_order_line_number=bsf.line_number) as order_status
    from CRPSC.RC_BSF_CUMULATIVE_HISTORY BSF,RMKTGADM.CDM_TIME_HIERARCHY_DIM DIM
   WHERE 
    BSF.EXECUTION_DATE=TRUNC(CALENDAR_DATE)
    AND CALENDAR_DATE=FISCAL_QTR_END_DATE
  and ORDER_TYPE IN (''RETAIL'', ''EXCESS'', ''OUTLET'')
  GROUP BY CALENDAR_DATE,FISCAL_QUARTER_NAME,SO_NUMBER,SO_LINE_ID,refresh_part_number,country,end_user_customer,line_number
   )  WHERE 1=1 ';
      END IF;

      lv_booked_qry := lv_booked_qry || lv_constraint_query;



      COMMIT;

      -- EXECUTE IMMEDIATE lv_booked_qry INTO o_booked_orders;

      IF (lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL)
      THEN
         lv_sort_query :=
               lv_sort_column_name
            || ' '
            || lv_sort_column_by
            || ' NULLS LAST)  WHERE 1=1 ';
      ELSE
         lv_sort_query := ' order_creation_date DESC)  WHERE 1=1';
      END IF;

      lv_final_query := lv_final_query || ' ORDER BY ' || lv_sort_query;

      /* Min & Max   */
      IF (i_min_row > 0 AND i_max_row > i_min_row)
      THEN
         lv_final_query :=
               lv_final_query
            || ' AND RNUM >= '
            || i_min_row
            || ' AND RNUM <= '
            || i_max_row;
      END IF;

      lv_final_query := lv_final_query || ')';
      lv_count_query := lv_count_query || ')'; --added by hkarka on 19-DEC-2017

      EXECUTE IMMEDIATE lv_final_query BULK COLLECT INTO lv_data_fetch_list;



      o_data_fetch_list := lv_data_fetch_list;



      --insert into debug_orderreport values ('lv_count_query: ', lv_count_query, SYSDATE);  --added by hkarka 19-DEC-2017 remove**
      EXECUTE IMMEDIATE lv_count_query INTO lv_total_record_count;



      o_total_record_count := lv_total_record_count;



      o_status := 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_status := 0;
         g_error_msg :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12);

         -- Logging exception for the SUB process for refreshing Order Tmp Table

         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
            g_error_msg,
            NULL,
            'RC_ORDER_REPORT_FETCH.RC_HISTORY_DETAILS_EXTRACT',
            'PROCEDURE',
            i_user_id,
            'N');

         COMMIT;
   END RC_HISTORY_DETAILS_EXTRACT;

   PROCEDURE RC_ORDER_DETAILS_EXTRACT (
      i_user_id              IN     VARCHAR2,
      i_min_row              IN     NUMBER,
      i_max_row              IN     NUMBER,
      --advance fitlers start
      i_part_number          IN     VARCHAR2,
      i_order_status         IN     VARCHAR2,
      i_order_number         IN     VARCHAR2,
      i_end_customer_name    IN     VARCHAR2,
      i_theater              IN     VARCHAR2,
      i_order_line_amount    IN     VARCHAR2, -- Added by obarbier for 25k filter
      --advance fitlers end
      i_sort_column_name     IN     VARCHAR2,
      i_sort_column_by       IN     VARCHAR2,
      i_filter_list          IN     RC_NEW_FILTER_OBJ_LIST,
      o_data_fetch_list         OUT ORDER_DETAILS_HIST_LIST,
      o_total_record_count      OUT NUMBER,
      o_load_date               OUT VARCHAR2,
      o_status                  OUT VARCHAR2,
      o_booked_orders           OUT NUMBER)
   IS
      lv_part_number             VARCHAR2 (32767);
      lv_order_status            VARCHAR2 (32767);
      lv_order_number            VARCHAR2 (32767);
      lv_end_customer_name       VARCHAR2 (32767);
      lv_theater                 VARCHAR2 (32767);
      lv_order_line_amount       VARCHAR2 (32767); -- added by obarbier for 25k filters
      lv_sort_column_name        VARCHAR2 (30);
      lv_sort_column_by          VARCHAR2 (10);
      lv_data_fetch_list         ORDER_DETAILS_HIST_LIST;
      lv_final_query             CLOB;
      lv_constraint_query        CLOB;
      lv_sort_query              CLOB;
      lv_count_query             CLOB;
      lv_total_record_count      NUMBER;
      lv_load_date               DATE;
      lv_filter_list             RC_NEW_FILTER_OBJ_LIST;
      lv_table_name              VARCHAR2 (50);
      lv_filter_query            CLOB;
      g_error_msg                CLOB;
      lv_i_refresh_part_number   VARCHAR2 (32767);
      lv_idx                     NUMBER;
      lv_booked_qry              VARCHAR2 (32767);
      lv_cur_part_number         VARCHAR2 (32767);
   BEGIN
      lv_data_fetch_list := ORDER_DETAILS_HIST_LIST ();
      lv_part_number := i_part_number;
      lv_order_status := i_order_status;
      lv_order_number := i_order_number;
      lv_end_customer_name := i_end_customer_name;
      lv_theater := i_theater;
      lv_order_line_amount := i_order_line_amount; --added by obarbier for 25k filters
      lv_sort_column_name := UPPER (TRIM (i_sort_column_name));
      lv_sort_column_by := UPPER (TRIM (i_sort_column_by));
      lv_filter_list := i_filter_list;



      --      IF lv_generated_date is not null
      --      then
      --      o_load_date := lv_generated_date;
      --
      --      else
      --       Begin
      --      select MAX(LAST_REFRESH_DATE)
      --           INTO lv_load_date
      --           FROM all_mviews
      --          where mview_name = 'RC_INV_BTS_C3_MV';
      --          o_load_date := TO_CHAR (lv_load_date, 'mm/dd/yyyy hh:mi:ss AM');
      --      EXCEPTION
      --         WHEN OTHERS
      --         THEN
      --            o_load_date := NULL;
      --      END;
      --
      --
      --
      --      END If;


      SELECT MAX (UPDATED_DATE)
        INTO lv_load_date
        FROM RMKTGADM.RMK_SSOT_TRANSACTIONS;

      o_load_date :=
         TO_CHAR (lv_load_date, 'mm/dd/yyyy hh:mi:ss AM');

      lv_final_query :=
         'SELECT ORDER_DETAILS_HIST_OBJ (
         SALES_ORDER_NUMBER,
         CUSTOMER_NAME,
         CUSTOMER_ID,
         RESELLER_NAME,
         END_USER_CUSTOMER,
         CUSTOMER_PO_NUMBER,
         WEB_ORDER_STATUS,
         ORDER_CREATED_DATE,
         PRODUCT_ID,
         INVENTORY_SITE,
         LINE_ALLOC_STATUS,
         CUSTOMER_TYPE,
         THEATER,
         CHANNEL,
         ORDER_TYPE,
         CURRENCY_CODE,
         REMARKETING_SALES_MANAGER,
         SO_LINE_STATUS,
         LIST_PRICE,
         QUANTITY_ALLOCATED,
         NET_PRICE,
         SUM_EXTENDED_NET_PRICE,
         QUANTITY_REQUESTED,
         NET_PRICE_USD,
         SUM_EXT_NET_PRICE_USD,
         TOTAL_RESERVATION,
         EXTENDED_NET_PRICE,
         EXT_NET_PRICE_USD
    )
 FROM ( SELECT
          SALES_ORDER_NUMBER,
         CUSTOMER_NAME,
         CUSTOMER_ID,
         RESELLER_NAME,
         END_USER_CUSTOMER,
         CUSTOMER_PO_NUMBER,
         WEB_ORDER_STATUS,
         ORDER_CREATED_DATE,
         PRODUCT_ID,
         INVENTORY_SITE,
         LINE_ALLOC_STATUS,
         CUSTOMER_TYPE,
         THEATER,
         CHANNEL,
         ORDER_TYPE,
         CURRENCY_CODE,
         REMARKETING_SALES_MANAGER,
         SO_LINE_STATUS,
         LIST_PRICE,
         QUANTITY_ALLOCATED,
         NET_PRICE,
         EXTENDED_NET_PRICE as SUM_EXTENDED_NET_PRICE,
         QUANTITY_REQUESTED,
         NET_PRICE_USD,
         EXT_NET_PRICE_USD as SUM_EXT_NET_PRICE_USD,
         TOTAL_RESERVATION,
         --EXTENDED_NET_PRICE,
         NET_PRICE*TOTAL_RESERVATION EXTENDED_NET_PRICE,
         --EXT_NET_PRICE_USD
         NET_PRICE_USD*TOTAL_RESERVATION EXT_NET_PRICE_USD
   FROM ( SELECT
          SALES_ORDER_NUMBER,
         CUSTOMER_NAME,
         CUSTOMER_ID,
         RESELLER_NAME,
         END_USER_CUSTOMER,
         CUSTOMER_PO_NUMBER,
         WEB_ORDER_STATUS,
         ORDER_CREATED_DATE,
         PRODUCT_ID,
         INVENTORY_SITE,
         LINE_ALLOC_STATUS,
         CUSTOMER_TYPE,
         THEATER,
         CHANNEL,
         ORDER_TYPE,
         CURRENCY_CODE,
         REMARKETING_SALES_MANAGER,
         SO_LINE_STATUS,
         LIST_PRICE,
         QUANTITY_ALLOCATED,
         NET_PRICE,
         SUM_EXTENDED_NET_PRICE,
         QUANTITY_REQUESTED,
         NET_PRICE_USD,
         SUM_EXT_NET_PRICE_USD,
         TOTAL_RESERVATION,
         EXTENDED_NET_PRICE,
         EXT_NET_PRICE_USD,
         ROWNUM RNUM
  FROM (  SELECT DISTINCT
  RMKTGADM.RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER as SALES_ORDER_NUMBER ,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CUSTOMER_NAME as CUSTOMER_NAME,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CUSTOMER_ID as CUSTOMER_ID,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.RESELLER_NAME as RESELLER_NAME,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.END_USER_CUSTOMER as END_USER_CUSTOMER ,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CUSTOMER_PO_NUMBER as CUSTOMER_PO_NUMBER ,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.WEB_ORDER_STATUS as WEB_ORDER_STATUS,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.ORDER_CREATED_DATE as ORDER_CREATED_DATE ,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.PRODUCT_ID as PRODUCT_ID,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.INVENTORY_SITE as INVENTORY_SITE ,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.LINE_ALLOC_STATUS as LINE_ALLOC_STATUS ,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CUSTOMER_TYPE as CUSTOMER_TYPE ,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.THEATER as THEATER ,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CHANNEL as CHANNEL,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.ORDER_TYPE as ORDER_TYPE ,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CURRENCY_CODE as CURRENCY_CODE,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.REMARKETING_SALES_MANAGER as REMARKETING_SALES_MANAGER,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.SO_LINE_STATUS as SO_LINE_STATUS,
  NVL(RMKTGADM.RMK_SSOT_TRANSACTIONS.LIST_PRICE,0) as LIST_PRICE,
  sum(NVL(To_Number(replace(trim(RMKTGADM.RMK_SSOT_TRANSACTIONS.QUANTITY_ALLOCATED),'','','''')),0)) as QUANTITY_ALLOCATED,
  NVL(RMKTGADM.RMK_SSOT_TRANSACTIONS.NET_PRICE,0) as NET_PRICE,
  Sum(NVL(RMKTGADM.RMK_SSOT_TRANSACTIONS.EXTENDED_NET_PRICE,0)) as SUM_EXTENDED_NET_PRICE,
  sum(NVL(To_Number(replace(trim(RMKTGADM.RMK_SSOT_TRANSACTIONS.QUANTITY_REQUESTED),'','','''')),0)) as QUANTITY_REQUESTED,
  NVL(RMKTGADM.RMK_SSOT_TRANSACTIONS.NET_PRICE_USD,0) as NET_PRICE_USD,
  Sum(NVL(RMKTGADM.RMK_SSOT_TRANSACTIONS.EXT_NET_PRICE_USD,0)) as SUM_EXT_NET_PRICE_USD ,
  Sum(NVL(RMKTGADM.RMK_SSOT_TRANSACTIONS.TOTAL_RESERVATION,0)) as TOTAL_RESERVATION,
  NVL(RMK_SSOT_TRAN_SO_EXT_PRICE.EXTENDED_NET_PRICE,0) as EXTENDED_NET_PRICE,
  NVL(RMK_SSOT_TRAN_SO_EXT_PRICE.EXT_NET_PRICE_USD,0) as EXT_NET_PRICE_USD
FROM
  RMKTGADM.RMK_SSOT_TRANSACTIONS INNER JOIN ( 
  select  SALES_ORDER_NUMBER as SALES_ORDER_NUMBER,
sum ( EXTENDED_NET_PRICE ) as EXTENDED_NET_PRICE, 
sum ( EXT_NET_PRICE_USD ) as EXT_NET_PRICE_USD  
from (
SELECT distinct
RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER,
ORIGINAL_QUANTITY_REQUESTED,
NVL (RMK_SSOT_TRANSACTIONS.EXTENDED_NET_PRICE, 0) EXTENDED_NET_PRICE ,
NVL (RMK_SSOT_TRANSACTIONS.EXT_NET_PRICE_USD, 0) EXT_NET_PRICE_USD 
FROM RMKTGADM.RMK_SSOT_TRANSACTIONS  
)
group by SALES_ORDER_NUMBER
  )  RMK_SSOT_TRAN_SO_EXT_PRICE ON (RMKTGADM.RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER=RMK_SSOT_TRAN_SO_EXT_PRICE.SALES_ORDER_NUMBER) 
WHERE
  (
   RMKTGADM.RMK_SSOT_TRANSACTIONS.WEB_ORDER_ID  Is Not Null  
   AND
   RMKTGADM.RMK_SSOT_TRANSACTIONS.TRANSACTION_TYPE  IN  ( ''WEB_ORDER'',''STANDALONE_ORDER''  )
   AND
   (
    RMKTGADM.RMK_SSOT_TRANSACTIONS.SO_LINE_STATUS  NOT IN  ( ''IFS_SHIPPED'',''IFS_INTERFACED'',
                                                             ''INVOICE_ELIGIBLE'',''CANCELLED'',
                                                             ''NOT_ENTERED'',''INVOICED'',''CISCOSHIPPED''  )
    OR
    RMKTGADM.RMK_SSOT_TRANSACTIONS.SO_LINE_STATUS  Is Null  
   )
   AND
   RMKTGADM.RMK_SSOT_TRANSACTIONS.RESERVATION_STATUS  =  ''ACTIVE''
   AND
   RMKTGADM.RMK_SSOT_TRANSACTIONS.WEB_ORDER_STATUS  NOT IN  ( ''CANCELLED'' )
  )
GROUP BY
  RMKTGADM.RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CUSTOMER_NAME, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CUSTOMER_ID, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.RESELLER_NAME, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.END_USER_CUSTOMER, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CUSTOMER_PO_NUMBER, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.WEB_ORDER_STATUS, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.ORDER_CREATED_DATE, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.PRODUCT_ID, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.INVENTORY_SITE, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.LINE_ALLOC_STATUS, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CUSTOMER_TYPE, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.THEATER, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CHANNEL, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.ORDER_TYPE, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CURRENCY_CODE, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.REMARKETING_SALES_MANAGER, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.SO_LINE_STATUS, 
  NVL(RMKTGADM.RMK_SSOT_TRANSACTIONS.LIST_PRICE,0), 
  NVL(RMKTGADM.RMK_SSOT_TRANSACTIONS.NET_PRICE,0), 
  NVL(RMKTGADM.RMK_SSOT_TRANSACTIONS.NET_PRICE_USD,0), 
  NVL(RMK_SSOT_TRAN_SO_EXT_PRICE.EXTENDED_NET_PRICE,0), 
  NVL(RMK_SSOT_TRAN_SO_EXT_PRICE.EXT_NET_PRICE_USD,0)';

      lv_count_query :=
         'SELECT COUNT(*)
       --Added by satbanda for grouping count <Start>
          FROM (    SELECT DISTINCT
  RMKTGADM.RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER as SALES_ORDER_NUMBER ,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CUSTOMER_NAME as CUSTOMER_NAME,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CUSTOMER_ID as CUSTOMER_ID,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.RESELLER_NAME as RESELLER_NAME,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.END_USER_CUSTOMER as END_USER_CUSTOMER ,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CUSTOMER_PO_NUMBER as CUSTOMER_PO_NUMBER ,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.WEB_ORDER_STATUS as WEB_ORDER_STATUS,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.ORDER_CREATED_DATE as ORDER_CREATED_DATE ,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.PRODUCT_ID as PRODUCT_ID,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.INVENTORY_SITE as INVENTORY_SITE ,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.LINE_ALLOC_STATUS as LINE_ALLOC_STATUS ,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CUSTOMER_TYPE as CUSTOMER_TYPE ,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.THEATER as THEATER ,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CHANNEL as CHANNEL,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.ORDER_TYPE as ORDER_TYPE ,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CURRENCY_CODE as CURRENCY_CODE,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.REMARKETING_SALES_MANAGER as REMARKETING_SALES_MANAGER,
  RMKTGADM.RMK_SSOT_TRANSACTIONS.SO_LINE_STATUS as SO_LINE_STATUS,
  NVL(RMKTGADM.RMK_SSOT_TRANSACTIONS.LIST_PRICE,0) as LIST_PRICE,
  sum(NVL(To_Number(replace(trim(RMKTGADM.RMK_SSOT_TRANSACTIONS.QUANTITY_ALLOCATED),'','','''')),0)) as QUANTITY_ALLOCATED,
  NVL(RMKTGADM.RMK_SSOT_TRANSACTIONS.NET_PRICE,0) as NET_PRICE,
  Sum(NVL(RMKTGADM.RMK_SSOT_TRANSACTIONS.EXTENDED_NET_PRICE,0)) as SUM_EXTENDED_NET_PRICE,
  sum(NVL(To_Number(replace(trim(RMKTGADM.RMK_SSOT_TRANSACTIONS.QUANTITY_REQUESTED),'','','''')),0)) as QUANTITY_REQUESTED,
  NVL(RMKTGADM.RMK_SSOT_TRANSACTIONS.NET_PRICE_USD,0) as NET_PRICE_USD,
  Sum(NVL(RMKTGADM.RMK_SSOT_TRANSACTIONS.EXT_NET_PRICE_USD,0)) as SUM_EXT_NET_PRICE_USD ,
  Sum(NVL(RMKTGADM.RMK_SSOT_TRANSACTIONS.TOTAL_RESERVATION,0)) as TOTAL_RESERVATION,
  NVL(RMK_SSOT_TRAN_SO_EXT_PRICE.EXTENDED_NET_PRICE,0) as EXTENDED_NET_PRICE,
  NVL(RMK_SSOT_TRAN_SO_EXT_PRICE.EXT_NET_PRICE_USD,0) as EXT_NET_PRICE_USD
FROM
  RMKTGADM.RMK_SSOT_TRANSACTIONS INNER JOIN ( 
  select  SALES_ORDER_NUMBER as SALES_ORDER_NUMBER,
sum ( EXTENDED_NET_PRICE ) as EXTENDED_NET_PRICE, 
sum ( EXT_NET_PRICE_USD ) as EXT_NET_PRICE_USD  
from (
SELECT distinct
RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER,
ORIGINAL_QUANTITY_REQUESTED,
NVL (RMK_SSOT_TRANSACTIONS.EXTENDED_NET_PRICE, 0) EXTENDED_NET_PRICE ,
NVL (RMK_SSOT_TRANSACTIONS.EXT_NET_PRICE_USD, 0) EXT_NET_PRICE_USD 
FROM RMKTGADM.RMK_SSOT_TRANSACTIONS  
)
group by SALES_ORDER_NUMBER
  )  RMK_SSOT_TRAN_SO_EXT_PRICE ON (RMKTGADM.RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER=RMK_SSOT_TRAN_SO_EXT_PRICE.SALES_ORDER_NUMBER) 
WHERE
  (
   RMKTGADM.RMK_SSOT_TRANSACTIONS.WEB_ORDER_ID  Is Not Null  
   AND
   RMKTGADM.RMK_SSOT_TRANSACTIONS.TRANSACTION_TYPE  IN  ( ''WEB_ORDER'',''STANDALONE_ORDER''  )
   AND
   (
    RMKTGADM.RMK_SSOT_TRANSACTIONS.SO_LINE_STATUS  NOT IN  ( ''IFS_SHIPPED'',''IFS_INTERFACED'',
                                                             ''INVOICE_ELIGIBLE'',''CANCELLED'',
                                                             ''NOT_ENTERED'',''INVOICED'',''CISCOSHIPPED''  )
    OR
    RMKTGADM.RMK_SSOT_TRANSACTIONS.SO_LINE_STATUS  Is Null  
   )
   AND
   RMKTGADM.RMK_SSOT_TRANSACTIONS.RESERVATION_STATUS  =  ''ACTIVE''
   AND
   RMKTGADM.RMK_SSOT_TRANSACTIONS.WEB_ORDER_STATUS  NOT IN  ( ''CANCELLED'',''CLOSED''  )';


      /* Refer History table when Generated Date filter value is Not Null */
      --( RMKTGADM.RMK_SSOT_TRANSACTIONS.WEB_ORDER_STATUS || '-' || RMKTGADM.RMK_SSOT_TRANSACTIONS.SO_LINE_STATUS)
      IF (lv_order_status IS NOT NULL)
      THEN
         lv_constraint_query :=
               lv_constraint_query
            || ' AND so_line_status = '''
            || lv_order_status
            || '''';

         lv_count_query :=
               lv_count_query
            || ' AND RMKTGADM.RMK_SSOT_TRANSACTIONS.so_line_status = '''
            || lv_order_status
            || '''';
      END IF;

      IF (lv_theater IS NOT NULL)
      THEN
         lv_constraint_query :=
            lv_constraint_query || ' AND THEATER = ''' || lv_theater || '''';

         lv_count_query :=
               lv_count_query
            || ' AND RMKTGADM.RMK_SSOT_TRANSACTIONS.THEATER = '''
            || lv_theater
            || '''';
      END IF;

      -- Added by obarbier for 25k filters
      IF (lv_order_line_amount IS NOT NULL)
      THEN
         lv_constraint_query :=
               lv_constraint_query
            || ' AND SUM_EXTENDED_NET_PRICE '
            || lv_order_line_amount
            || '';

         lv_count_query :=
               lv_count_query
            || ' AND RMKTGADM.RMK_SSOT_TRANSACTIONS.EXT_NET_PRICE_USD '
            || lv_order_line_amount
            || '';
      END IF;

      -- Endof filters
      /* Advance filter on part Number */
      IF lv_part_number IS NOT NULL
      THEN
         IF (lv_part_number IS NOT NULL)
         THEN
            lv_constraint_query := lv_constraint_query || ' AND ( ';
            lv_count_query := lv_count_query || ' AND ( ';


            lv_i_refresh_part_number := lv_part_number;
            lv_idx := INSTR (lv_i_refresh_part_number, ',');


            IF lv_idx = 0
            THEN
               lv_i_refresh_part_number :=
                  REPLACE (lv_i_refresh_part_number, '*', '');
               lv_constraint_query :=
                     lv_constraint_query
                  || 'UPPER(PRODUCT_ID) LIKE UPPER(''%'
                  || lv_i_refresh_part_number
                  || '%'')';

               lv_count_query :=
                     lv_count_query
                  || 'UPPER(RMKTGADM.RMK_SSOT_TRANSACTIONS.PRODUCT_ID) LIKE UPPER(''%'
                  || lv_i_refresh_part_number
                  || '%'')';
            ELSE
               lv_cur_part_number :=
                  SUBSTR (lv_i_refresh_part_number,
                          1,
                          INSTR (lv_i_refresh_part_number, ',') - 1);
               lv_cur_part_number := REPLACE (lv_cur_part_number, '*', '');

               lv_constraint_query :=
                     lv_constraint_query
                  || 'UPPER(PRODUCT_ID) LIKE UPPER(''%'
                  || lv_cur_part_number
                  || '%'')';

               lv_count_query :=
                     lv_count_query
                  || 'UPPER(RMKTGADM.RMK_SSOT_TRANSACTIONS.PRODUCT_ID) LIKE UPPER(''%'
                  || lv_cur_part_number
                  || '%'')';

               lv_i_refresh_part_number :=
                  SUBSTR (lv_i_refresh_part_number, lv_idx + LENGTH (' '));
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
                        SUBSTR (lv_i_refresh_part_number,
                                lv_idx + LENGTH (','));
                     lv_cur_part_number :=
                        REPLACE (lv_cur_part_number, '*', '');
                     lv_constraint_query :=
                           lv_constraint_query
                        || ' OR UPPER(PRODUCT_ID) LIKE  UPPER(''%'
                        || lv_cur_part_number
                        || '%'')';
                     lv_count_query :=
                           lv_count_query
                        || ' OR UPPER(RMKTGADM.RMK_SSOT_TRANSACTIONS.PRODUCT_ID) LIKE  UPPER(''%'
                        || lv_cur_part_number
                        || '%'')';
                  ELSE
                     lv_i_refresh_part_number :=
                        REPLACE (lv_i_refresh_part_number, '*', '');
                     lv_constraint_query :=
                           lv_constraint_query
                        || ' OR UPPER(PRODUCT_ID) LIKE  UPPER(''%'
                        || lv_i_refresh_part_number
                        || '%'')';
                     lv_count_query :=
                           lv_count_query
                        || ' OR UPPER(RMKTGADM.RMK_SSOT_TRANSACTIONS.PRODUCT_ID) LIKE  UPPER(''%'
                        || lv_i_refresh_part_number
                        || '%'')';

                     EXIT;
                  END IF;
               END LOOP;
            END IF;
         END IF;

         lv_constraint_query := lv_constraint_query || ')';
         lv_count_query := lv_count_query || ')'; --Commented by satbanda for actual count
      END IF;



      IF lv_order_number IS NOT NULL
      THEN
         IF (lv_order_number IS NOT NULL)
         THEN
            lv_constraint_query := lv_constraint_query || ' AND ( ';
            lv_count_query := lv_count_query || ' AND ( ';

            lv_i_refresh_part_number := lv_order_number;
            lv_idx := INSTR (lv_i_refresh_part_number, ',');


            IF lv_idx = 0
            THEN
               lv_i_refresh_part_number :=
                  REPLACE (lv_i_refresh_part_number, '*', '');
               lv_constraint_query :=
                     lv_constraint_query
                  || 'UPPER(SALES_ORDER_NUMBER) LIKE UPPER(''%'
                  || lv_i_refresh_part_number
                  || '%'')';

               lv_count_query :=
                     lv_count_query
                  || 'UPPER(RMKTGADM.RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER) LIKE UPPER(''%'
                  || lv_i_refresh_part_number
                  || '%'')';
            ELSE
               lv_cur_part_number :=
                  SUBSTR (lv_i_refresh_part_number,
                          1,
                          INSTR (lv_i_refresh_part_number, ',') - 1);
               lv_cur_part_number := REPLACE (lv_cur_part_number, '*', '');

               lv_constraint_query :=
                     lv_constraint_query
                  || 'UPPER(SALES_ORDER_NUMBER) LIKE UPPER(''%'
                  || lv_cur_part_number
                  || '%'')';

               lv_count_query :=
                     lv_count_query
                  || 'UPPER(RMKTGADM.RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER) LIKE UPPER(''%'
                  || lv_cur_part_number
                  || '%'')';

               lv_i_refresh_part_number :=
                  SUBSTR (lv_i_refresh_part_number, lv_idx + LENGTH (' '));
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
                        SUBSTR (lv_i_refresh_part_number,
                                lv_idx + LENGTH (','));
                     lv_cur_part_number :=
                        REPLACE (lv_cur_part_number, '*', '');
                     lv_constraint_query :=
                           lv_constraint_query
                        || ' OR UPPER(SALES_ORDER_NUMBER) LIKE  UPPER(''%'
                        || lv_cur_part_number
                        || '%'')';
                     lv_count_query :=
                           lv_count_query
                        || ' OR UPPER(RMKTGADM.RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER) LIKE  UPPER(''%'
                        || lv_cur_part_number
                        || '%'')';
                  ELSE
                     lv_i_refresh_part_number :=
                        REPLACE (lv_i_refresh_part_number, '*', '');
                     lv_constraint_query :=
                           lv_constraint_query
                        || ' OR UPPER(SALES_ORDER_NUMBER) LIKE  UPPER(''%'
                        || lv_i_refresh_part_number
                        || '%'')';
                     lv_count_query :=
                           lv_count_query
                        || ' OR UPPER(RMKTGADM.RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER) LIKE  UPPER(''%'
                        || lv_i_refresh_part_number
                        || '%'')';

                     EXIT;
                  END IF;
               END LOOP;
            END IF;
         END IF;

         lv_constraint_query := lv_constraint_query || ')';
         lv_count_query := lv_count_query || ')';
      END IF;

      IF lv_end_customer_name IS NOT NULL
      THEN
         IF (lv_end_customer_name IS NOT NULL)
         THEN
            lv_constraint_query := lv_constraint_query || ' AND ( ';
            lv_count_query := lv_count_query || ' AND ( ';


            lv_i_refresh_part_number := lv_end_customer_name;
            lv_idx := INSTR (lv_i_refresh_part_number, ',');


            IF lv_idx = 0
            THEN
               lv_i_refresh_part_number :=
                  REPLACE (lv_i_refresh_part_number, '*', '');
               lv_constraint_query :=
                     lv_constraint_query
                  || 'UPPER(END_USER_CUSTOMER) LIKE UPPER(''%'
                  || lv_i_refresh_part_number
                  || '%'')';
               lv_count_query :=
                     lv_count_query
                  || 'UPPER(RMKTGADM.RMK_SSOT_TRANSACTIONS.END_USER_CUSTOMER) LIKE UPPER(''%'
                  || lv_i_refresh_part_number
                  || '%'')';
            ELSE
               lv_cur_part_number :=
                  SUBSTR (lv_i_refresh_part_number,
                          1,
                          INSTR (lv_i_refresh_part_number, ',') - 1);
               lv_cur_part_number := REPLACE (lv_cur_part_number, '*', '');

               lv_constraint_query :=
                     lv_constraint_query
                  || 'UPPER(END_USER_CUSTOMER) LIKE UPPER(''%'
                  || lv_cur_part_number
                  || '%'')';
               lv_count_query :=
                     lv_count_query
                  || 'UPPER(RMKTGADM.RMK_SSOT_TRANSACTIONS.END_USER_CUSTOMER) LIKE UPPER(''%'
                  || lv_cur_part_number
                  || '%'')';

               lv_i_refresh_part_number :=
                  SUBSTR (lv_i_refresh_part_number, lv_idx + LENGTH (' '));
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
                        SUBSTR (lv_i_refresh_part_number,
                                lv_idx + LENGTH (','));
                     lv_cur_part_number :=
                        REPLACE (lv_cur_part_number, '*', '');
                     lv_constraint_query :=
                           lv_constraint_query
                        || ' OR UPPER(END_USER_CUSTOMER) LIKE  UPPER(''%'
                        || lv_cur_part_number
                        || '%'')';
                     lv_count_query :=
                           lv_count_query
                        || ' OR UPPER(RMKTGADM.RMK_SSOT_TRANSACTIONS.END_USER_CUSTOMER) LIKE  UPPER(''%'
                        || lv_cur_part_number
                        || '%'')';
                  ELSE
                     lv_i_refresh_part_number :=
                        REPLACE (lv_i_refresh_part_number, '*', '');
                     lv_constraint_query :=
                           lv_constraint_query
                        || ' OR UPPER(END_USER_CUSTOMER) LIKE  UPPER(''%'
                        || lv_i_refresh_part_number
                        || '%'')';
                     lv_count_query :=
                           lv_count_query
                        || ' OR UPPER(RMKTGADM.RMK_SSOT_TRANSACTIONS.END_USER_CUSTOMER) LIKE  UPPER(''%'
                        || lv_i_refresh_part_number
                        || '%'')';

                     EXIT;
                  END IF;
               END LOOP;
            END IF;
         END IF;

         lv_constraint_query := lv_constraint_query || ')';
         lv_count_query := lv_count_query || ')';
      END IF;



      /* Column Filters */
      --      IF (lv_filter_list IS NOT NULL)
      --      THEN
      --         GET_FILTERS_IN_QUERY (lv_filter_list,
      --                               lv_table_name,
      --                               lv_filter_query);
      --         lv_constraint_query := lv_constraint_query || ' ' || lv_filter_query;
      --      END IF;
      --
      --     lv_final_query := lv_final_query || lv_constraint_query;


      IF (lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL)
      THEN
         lv_sort_query :=
               lv_sort_column_name
            || ' '
            || lv_sort_column_by
            || ' NULLS LAST) ) WHERE 1=1 ';
      ELSE
         lv_sort_query :=
               ' SALES_ORDER_NUMBER DESC) WHERE 1 =1 '
            || lv_constraint_query
            || ')  WHERE 1=1';
      END IF;

      lv_final_query := lv_final_query || ' ORDER BY ' || lv_sort_query;

      lv_booked_qry :=
         'select
   sum(TOTAL_BOOKINGS) from (select calendar_date,ORDER_NUMBER SALES_ORDER_NUMBER,
                 PRODUCT_ID part_number,
                 COUNTRY THEATER,
                 end_user_customer end_customer_name,sum(NVL(REV_CUR_WK,0)+NVL(REV_NEXT_WK,0)+NVL(REV_CUR_QTR_REM_WKS,0)+NVL(REV_NEXT_QTR,0)+NVL(REV_TO_BE_SCHEDULED,0)
   +NVL(REV_NO_INVENTORY,0)+NVL(REV_IN_TRANSIT,0)) TOTAL_BOOKINGS,
   dim.fiscal_quarter_name fiscal_quarter,(select MAX (web_order_Status || ''-'' || so_line_Status) 
   from RMKTGADM.RMK_SSOT_TRANSACTIONS TR where TR.SALES_ORDER_NUMBER=BSF.ORDER_NUMBER and TR.SO_LINE_ID=BSF.MFG_LINE_ID
   and tr.sales_order_line_number=bsf.line_number) as order_status
    from CRPADM.RC_MASTER_BACKLOG BSF,RMKTGADM.CDM_TIME_HIERARCHY_DIM DIM
  GROUP BY CALENDAR_DATE,FISCAL_QUARTER_NAME,ORDER_NUMBER,MFG_LINE_ID,PRODUCT_ID,country,end_user_customer,line_number
  )  WHERE TRUNC(CALENDAR_DATE)=TRUNC(SYSDATE)';

      lv_booked_qry := lv_booked_qry || lv_constraint_query;

      /*      EXECUTE IMMEDIATE lv_booked_qry INTO o_booked_orders;*/


      /* Min & Max   */
      IF (i_min_row > 0 AND i_max_row > i_min_row)
      THEN
         lv_final_query :=
               lv_final_query
            || ' AND RNUM >= '
            || i_min_row
            || ' AND RNUM <= '
            || i_max_row;
      END IF;

      lv_final_query := lv_final_query || ')';
      lv_count_query := lv_count_query || ')
             --Added by satbanda for grouping count <Start>
GROUP BY
  RMKTGADM.RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CUSTOMER_NAME, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CUSTOMER_ID, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.RESELLER_NAME, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.END_USER_CUSTOMER, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CUSTOMER_PO_NUMBER, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.WEB_ORDER_STATUS, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.ORDER_CREATED_DATE, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.PRODUCT_ID, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.INVENTORY_SITE, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.LINE_ALLOC_STATUS, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CUSTOMER_TYPE, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.THEATER, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CHANNEL, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.ORDER_TYPE, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.CURRENCY_CODE, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.REMARKETING_SALES_MANAGER, 
  RMKTGADM.RMK_SSOT_TRANSACTIONS.SO_LINE_STATUS, 
  NVL(RMKTGADM.RMK_SSOT_TRANSACTIONS.LIST_PRICE,0), 
  NVL(RMKTGADM.RMK_SSOT_TRANSACTIONS.NET_PRICE,0), 
  NVL(RMKTGADM.RMK_SSOT_TRANSACTIONS.NET_PRICE_USD,0), 
  NVL(RMK_SSOT_TRAN_SO_EXT_PRICE.EXTENDED_NET_PRICE,0), 
  NVL(RMK_SSOT_TRAN_SO_EXT_PRICE.EXT_NET_PRICE_USD,0)
         --Added by satbanda for grouping count <End>
      )';


      --insert into test_queries_table  (queries, modules, created_on)
      --values (lv_count_query,'Order Backlog Count', sysdate);

      EXECUTE IMMEDIATE lv_final_query BULK COLLECT INTO lv_data_fetch_list;

      o_data_fetch_list := lv_data_fetch_list;


      EXECUTE IMMEDIATE lv_count_query INTO lv_total_record_count;


      o_total_record_count := lv_total_record_count;
      o_status := 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_status := 0;
         g_error_msg :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12);

         -- Logging exception for the SUB process for refreshing Order Tmp Table
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
            g_error_msg,
            NULL,
            'RC_ORDER_REPORT_FETCH.RC_ORDER_DETAILS_EXTRACT',
            'PROCEDURE',
            i_user_id,
            'N');

         COMMIT;
   END RC_ORDER_DETAILS_EXTRACT;

   PROCEDURE GET_UNIQUE_ORDER_RPT_FILTERS (
      i_user_id        IN     VARCHAR2,
      i_column_name    IN     VARCHAR2,
      i_filter_list    IN     RC_NEW_FILTER_OBJ_LIST,
      o_unique_value      OUT T_NORMALISED_LIST,
      o_status            OUT NUMBER)
   IS
      lv_table_name     VARCHAR2 (50);
      lv_column_name    VARCHAR2 (30);
      lv_filter_list    RC_NEW_FILTER_OBJ_LIST;
      lv_type           VARCHAR2 (30);
      lv_query          CLOB;
      lv_filter_query   CLOB;
      g_error_msg       CLOB;
   BEGIN
      lv_column_name := UPPER (TRIM (i_column_name));
      lv_filter_list := i_filter_list;


      lv_table_name := 'RC_INV_BTS_C3_MV';
      lv_query :=
            'SELECT DISTINCT UPPER('
         || lv_column_name
         || ')  FROM  rmktgadm.co_order_rf_publish co,
                 rmktgadm.xxcpo_rmk_reservation_header hdr,
                 rmktgadm.rmk_ssot_transactions ssot,
                 rmktgadm.CDM_TIME_HIERARCHY_DIM dim,
                 CRPADM.EX_CUSTOMER_ADDRESS EX,
                 CRPADM.RC_PRODUCT_MASTER PM
           WHERE     1 = 1
                 AND co.web_order_id = hdr.web_order_id
                 AND co.order_line_id = HDR.WEB_ORDER_LINE_ID
                 AND co.web_order_id = ssot.web_order_id
                 AND co.order_line_id = ssot.WEB_ORDER_LINE_ID
                 AND CO.END_CUSTOMER_SITE_ID = EX.EX_SITE_USE_ID(+)
                 AND PM.REFRESH_PART_NUMBER = CO.PART_NUMBER
                 AND dim.calendar_date = TRUNC (order_creation_date)
                 AND hdr.active_flag = 1
                 AND is_refurbished = ''Y''
                 AND (   TRUNC (co.order_creation_date) >=
                            TO_DATE (''09/10/2016'', ''mm/dd/yyyy'')
                      OR TRUNC (co.order_line_created_on) >=
                            TO_DATE (''09/10/2016'', ''mm/dd/yyyy'')) )';



      IF (lv_filter_list IS NOT NULL)
      THEN
         GET_FILTERS_IN_QUERY (lv_filter_list,
                               lv_table_name,
                               lv_filter_query);
         lv_query := lv_query || ' ' || lv_filter_query;
      END IF;

      lv_query :=
            lv_query
         || ' ORDER BY UPPER( '
         || lv_column_name
         || ' ) ASC NULLS FIRST';



      EXECUTE IMMEDIATE lv_query BULK COLLECT INTO o_unique_value;


      o_status := 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_status := 0;
         g_error_msg :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12);


         COMMIT;
   END GET_UNIQUE_ORDER_RPT_FILTERS;


   PROCEDURE GET_FILTERS_IN_QUERY (
      i_filter_list   IN     RC_NEW_FILTER_OBJ_LIST,
      i_table_name    IN     VARCHAR2,
      o_in_query         OUT CLOB)
   IS
      lv_in_query             CLOB;
      lv_null_query           VARCHAR2 (32767);
      lv_count                NUMBER;
      lv_filter_data_list     RC_FILTER_DATA_OBJ_LIST;
      lv_filter_column_name   VARCHAR2 (1000);
      lv_filter_value         VARCHAR2 (4000);
      lv_column_data_type     VARCHAR2 (25);
      g_error_msg             CLOB;
   BEGIN
      lv_count := 1;

      FOR IDX IN 1 .. i_filter_list.COUNT ()
      LOOP
         IF     (i_filter_list (idx).COL_NAME IS NOT NULL)
            AND (i_filter_list (idx).COL_NAME NOT LIKE ' ')
         THEN
            lv_filter_column_name :=
               UPPER (TO_CHAR (TRIM (i_filter_list (idx).COL_NAME)));

            SELECT DISTINCT DATA_TYPE
              INTO lv_column_data_type
              FROM ALL_TAB_COLUMNS
             WHERE     COLUMN_NAME = lv_filter_column_name
                   AND TABLE_NAME LIKE '%' || i_table_name || '%';

            lv_in_query := lv_in_query || ' AND ';

            lv_filter_data_list := i_filter_list (idx).COL_VALUE;

            FOR idx IN 1 .. lv_filter_data_list.COUNT ()
            LOOP
               IF lv_count > 999
               THEN
                  lv_count := 1;
                  lv_in_query :=
                        lv_in_query
                     || ') OR UPPER(TRIM('
                     || lv_filter_column_name
                     || ')) IN (';
               END IF;

               IF     (lv_filter_data_list (idx).FILTER_DATA IS NOT NULL)
                  AND (lv_filter_data_list (idx).FILTER_DATA NOT LIKE ' ')
               THEN
                  lv_filter_value :=
                     UPPER (
                        TO_CHAR (
                           TRIM (lv_filter_data_list (idx).FILTER_DATA)));

                  IF lv_filter_value LIKE '/'
                  THEN
                     lv_null_query :=
                        'OR ' || lv_filter_column_name || ' IS NULL';
                  END IF;


                  IF (lv_column_data_type = 'DATE')
                  THEN
                     IF lv_filter_value LIKE '/'
                     THEN
                        lv_filter_value := '';
                     ELSE
                        lv_filter_value :=
                           TO_DATE (lv_filter_value, 'DD-MON-YY');
                     END IF;
                  END IF;


                  IF idx = 1
                  THEN
                     lv_in_query :=
                           lv_in_query
                        || '(UPPER(TRIM('
                        || lv_filter_column_name
                        || ')) IN ('
                        || ''''
                        || lv_filter_value
                        || '''';
                  ELSE
                     IF lv_count = 1
                     THEN
                        lv_in_query :=
                           lv_in_query || '''' || lv_filter_value || '''';
                     ELSE
                        lv_in_query :=
                              lv_in_query
                           || ','
                           || ''''
                           || lv_filter_value
                           || '''';
                     END IF;
                  END IF;
               END IF;

               lv_count := lv_count + 1;
            END LOOP;

            lv_in_query := lv_in_query || ')' || lv_null_query || ')';
            lv_null_query := ' ';
         END IF;
      END LOOP;

      o_in_query := lv_in_query;
   EXCEPTION
      WHEN OTHERS
      THEN
         g_error_msg :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12);

         -- Logging exception for the SUB process for refreshing Order Tmp Table

         COMMIT;
   END GET_FILTERS_IN_QUERY;

   PROCEDURE RC_ORDER_DETAILS_FILTERS (
      i_user_id          IN     VARCHAR2,
      o_order_stauts        OUT T_NORMALISED_LIST,
      o_theater             OUT T_NORMALISED_LIST,
      o_fiscal_quarter      OUT T_NORMALISED_LIST,
      o_status              OUT NUMBER)
   IS
      lv_order_stauts     T_NORMALISED_LIST;
      lv_theater          T_NORMALISED_LIST;
      lv_fiscal_quarter   T_NORMALISED_LIST;
      g_error_msg         CLOB;
   BEGIN
      lv_order_stauts := T_NORMALISED_LIST ();
      lv_theater := T_NORMALISED_LIST ();
      lv_fiscal_quarter := T_NORMALISED_LIST ();

      BEGIN
           SELECT fiscal_quarter_name fiscal_quarter
             BULK COLLECT INTO lv_fiscal_quarter
             FROM rmktgadm.co_order_rf_publish        co,
                  rmktgadm.xxcpo_rmk_reservation_header hdr,
                  rmktgadm.rmk_ssot_transactions      ssot,
                  rmktgadm.CDM_TIME_HIERARCHY_DIM     dim,
                  CRPADM.EX_CUSTOMER_ADDRESS          EX,
                  CRPADM.RC_PRODUCT_MASTER            PM
            WHERE     calendar_date <= SYSDATE
                  AND co.web_order_id = hdr.web_order_id
                  AND co.order_line_id = HDR.WEB_ORDER_LINE_ID
                  AND co.web_order_id = ssot.web_order_id
                  AND co.order_line_id = ssot.WEB_ORDER_LINE_ID
                  AND CO.END_CUSTOMER_SITE_ID = EX.EX_SITE_USE_ID(+)
                  AND PM.REFRESH_PART_NUMBER = CO.PART_NUMBER
                  AND dim.calendar_date = TRUNC (order_creation_date)
                  AND hdr.active_flag = 1
                  AND is_refurbished = 'Y'
                  AND (   TRUNC (co.order_creation_date) >=
                             TO_DATE ('09/10/2016', 'mm/dd/yyyy')
                       OR TRUNC (co.order_line_created_on) >=
                             TO_DATE ('09/10/2016', 'mm/dd/yyyy'))
         GROUP BY fiscal_quarter_name, fiscal_quarter_id
         ORDER BY fiscal_quarter_id DESC;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_fiscal_quarter := T_NORMALISED_LIST ();
      END;

      BEGIN
         SELECT DISTINCT
                (ssot.WEB_ORDER_STATUS || '-' || ssot.SO_LINE_STATUS)
           BULK COLLECT INTO lv_order_stauts
           FROM rmktgadm.co_order_rf_publish          co,
                rmktgadm.xxcpo_rmk_reservation_header hdr,
                rmktgadm.rmk_ssot_transactions        ssot,
                rmktgadm.CDM_TIME_HIERARCHY_DIM       dim,
                CRPADM.EX_CUSTOMER_ADDRESS            EX,
                CRPADM.RC_PRODUCT_MASTER              PM
          WHERE     1 = 1
                AND co.web_order_id = hdr.web_order_id
                AND co.order_line_id = HDR.WEB_ORDER_LINE_ID
                AND co.web_order_id = ssot.web_order_id
                AND co.order_line_id = ssot.WEB_ORDER_LINE_ID
                AND CO.END_CUSTOMER_SITE_ID = EX.EX_SITE_USE_ID(+)
                AND PM.REFRESH_PART_NUMBER = CO.PART_NUMBER
                AND dim.calendar_date = TRUNC (order_creation_date)
                AND hdr.active_flag = 1
                AND is_refurbished = 'Y'
                AND (   TRUNC (co.order_creation_date) >=
                           TO_DATE ('09/10/2016', 'mm/dd/yyyy')
                     OR TRUNC (co.order_line_created_on) >=
                           TO_DATE ('09/10/2016', 'mm/dd/yyyy'))
                AND (    ssot.WEB_ORDER_STATUS IS NOT NULL
                     AND ssot.SO_LINE_STATUS IS NOT NULL);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_order_stauts := T_NORMALISED_LIST ();
      END;

      BEGIN
         SELECT DISTINCT
                NVL (
                   (SELECT DISTINCT
                           NVL (map.region_name,
                                'Country Mapping Unavailable')
                      FROM VAVNI_CISCO_RSCM_ADMIN.oct_mdm_region_country_map
                           map                      --need to change to Crpadm
                     WHERE     co.INVOICE_TO_CUSTOMER_COUNTRY_CD =
                                  map.country_name(+)
                           AND map.ACTIVE = 'A'),
                   'Country Mapping Unavailable')
                   AS Theater
           BULK COLLECT INTO lv_theater
           FROM rmktgadm.co_order_rf_publish          co,
                rmktgadm.xxcpo_rmk_reservation_header hdr,
                rmktgadm.rmk_ssot_transactions        ssot,
                rmktgadm.CDM_TIME_HIERARCHY_DIM       dim,
                CRPADM.EX_CUSTOMER_ADDRESS            EX,
                CRPADM.RC_PRODUCT_MASTER              PM
          WHERE     1 = 1
                AND co.web_order_id = hdr.web_order_id
                AND co.order_line_id = HDR.WEB_ORDER_LINE_ID
                AND co.web_order_id = ssot.web_order_id
                AND co.order_line_id = ssot.WEB_ORDER_LINE_ID
                AND CO.END_CUSTOMER_SITE_ID = EX.EX_SITE_USE_ID(+)
                AND PM.REFRESH_PART_NUMBER = CO.PART_NUMBER
                AND dim.calendar_date = TRUNC (order_creation_date)
                AND hdr.active_flag = 1
                AND is_refurbished = 'Y'
                AND (   TRUNC (co.order_creation_date) >=
                           TO_DATE ('09/10/2016', 'mm/dd/yyyy')
                     OR TRUNC (co.order_line_created_on) >=
                           TO_DATE ('09/10/2016', 'mm/dd/yyyy'))
                AND Theater IS NOT NULL;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_theater := T_NORMALISED_LIST ();
      END;



      o_order_stauts := lv_order_stauts;
      o_theater := lv_theater;
      o_fiscal_quarter := lv_fiscal_quarter;
      o_status := 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_status := 0;
         g_error_msg :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12);

         COMMIT;
   END;

   PROCEDURE RC_CCW_BACKLOG_FILTERS (
      i_user_id          IN     VARCHAR2,
      o_order_stauts        OUT T_NORMALISED_LIST,
      o_theater             OUT T_NORMALISED_LIST,
      o_fiscal_quarter      OUT T_NORMALISED_LIST,
      o_status              OUT NUMBER)
   IS
      lv_order_stauts     T_NORMALISED_LIST;
      lv_theater          T_NORMALISED_LIST;
      lv_fiscal_quarter   T_NORMALISED_LIST;
      g_error_msg         CLOB;
   BEGIN
      lv_order_stauts := T_NORMALISED_LIST ();
      lv_theater := T_NORMALISED_LIST ();
      lv_fiscal_quarter := T_NORMALISED_LIST ();

      BEGIN
           SELECT fiscal_quarter_name fiscal_quarter
             BULK COLLECT INTO lv_fiscal_quarter
             FROM rmktgadm.co_order_rf_publish        co,
                  rmktgadm.xxcpo_rmk_reservation_header hdr,
                  rmktgadm.rmk_ssot_transactions      ssot,
                  rmktgadm.CDM_TIME_HIERARCHY_DIM     dim,
                  CRPADM.EX_CUSTOMER_ADDRESS          EX,
                  CRPADM.RC_PRODUCT_MASTER            PM
            WHERE     calendar_date <= SYSDATE
                  AND co.web_order_id = hdr.web_order_id
                  AND co.order_line_id = HDR.WEB_ORDER_LINE_ID
                  AND co.web_order_id = ssot.web_order_id
                  AND co.order_line_id = ssot.WEB_ORDER_LINE_ID
                  AND CO.END_CUSTOMER_SITE_ID = EX.EX_SITE_USE_ID(+)
                  AND PM.REFRESH_PART_NUMBER = CO.PART_NUMBER
                  AND dim.calendar_date = TRUNC (order_creation_date)
                  AND hdr.active_flag = 1
                  AND is_refurbished = 'Y'
                  AND (   TRUNC (co.order_creation_date) >=
                             TO_DATE ('09/10/2016', 'mm/dd/yyyy')
                       OR TRUNC (co.order_line_created_on) >=
                             TO_DATE ('09/10/2016', 'mm/dd/yyyy'))
         GROUP BY fiscal_quarter_name, fiscal_quarter_id
         ORDER BY fiscal_quarter_id DESC;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_fiscal_quarter := T_NORMALISED_LIST ();
      END;


      BEGIN
         --SELECT DISTINCT ( RMKTGADM.RMK_SSOT_TRANSACTIONS.WEB_ORDER_STATUS || '-' || RMKTGADM.RMK_SSOT_TRANSACTIONS.SO_LINE_STATUS)
         SELECT DISTINCT (RMKTGADM.RMK_SSOT_TRANSACTIONS.so_line_status)
           BULK COLLECT INTO lv_order_stauts
           FROM RMKTGADM.RMK_SSOT_TRANSACTIONS
                INNER JOIN
                (  SELECT SALES_ORDER_NUMBER     AS SALES_ORDER_NUMBER,
                          SUM (EXTENDED_NET_PRICE) AS EXTENDED_NET_PRICE,
                          SUM (EXT_NET_PRICE_USD) AS EXT_NET_PRICE_USD
                     FROM (SELECT DISTINCT
                                  RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER,
                                  ORIGINAL_QUANTITY_REQUESTED,
                                  NVL (
                                     RMK_SSOT_TRANSACTIONS.EXTENDED_NET_PRICE,
                                     0)
                                     EXTENDED_NET_PRICE,
                                  NVL (RMK_SSOT_TRANSACTIONS.EXT_NET_PRICE_USD,
                                       0)
                                     EXT_NET_PRICE_USD
                             FROM RMKTGADM.RMK_SSOT_TRANSACTIONS)
                 GROUP BY SALES_ORDER_NUMBER) RMK_SSOT_TRAN_SO_EXT_PRICE
                   ON (RMKTGADM.RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER =
                          RMK_SSOT_TRAN_SO_EXT_PRICE.SALES_ORDER_NUMBER)
          WHERE (    RMKTGADM.RMK_SSOT_TRANSACTIONS.WEB_ORDER_ID IS NOT NULL
                 AND RMKTGADM.RMK_SSOT_TRANSACTIONS.TRANSACTION_TYPE IN
                        ('WEB_ORDER', 'STANDALONE_ORDER')
                 AND (   RMKTGADM.RMK_SSOT_TRANSACTIONS.SO_LINE_STATUS NOT IN
                            ('IFS_SHIPPED',
                             'IFS_INTERFACED',
                             'INVOICE_ELIGIBLE',
                             'CANCELLED',
                             'NOT_ENTERED',
                             'INVOICED',
                             'CISCOSHIPPED')
                      OR RMKTGADM.RMK_SSOT_TRANSACTIONS.SO_LINE_STATUS
                            IS NULL)
                 AND RMKTGADM.RMK_SSOT_TRANSACTIONS.RESERVATION_STATUS =
                        'ACTIVE'
                 AND RMKTGADM.RMK_SSOT_TRANSACTIONS.WEB_ORDER_STATUS NOT IN
                        ('CANCELLED', 'CLOSED'));
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_order_stauts := T_NORMALISED_LIST ();
      END;

      BEGIN
         SELECT DISTINCT RMKTGADM.RMK_SSOT_TRANSACTIONS.THEATER
           BULK COLLECT INTO lv_theater
           FROM RMKTGADM.RMK_SSOT_TRANSACTIONS
                INNER JOIN
                (  SELECT SALES_ORDER_NUMBER     AS SALES_ORDER_NUMBER,
                          SUM (EXTENDED_NET_PRICE) AS EXTENDED_NET_PRICE,
                          SUM (EXT_NET_PRICE_USD) AS EXT_NET_PRICE_USD
                     FROM (SELECT DISTINCT
                                  RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER,
                                  ORIGINAL_QUANTITY_REQUESTED,
                                  NVL (
                                     RMK_SSOT_TRANSACTIONS.EXTENDED_NET_PRICE,
                                     0)
                                     EXTENDED_NET_PRICE,
                                  NVL (RMK_SSOT_TRANSACTIONS.EXT_NET_PRICE_USD,
                                       0)
                                     EXT_NET_PRICE_USD
                             FROM RMKTGADM.RMK_SSOT_TRANSACTIONS)
                 GROUP BY SALES_ORDER_NUMBER) RMK_SSOT_TRAN_SO_EXT_PRICE
                   ON (RMKTGADM.RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER =
                          RMK_SSOT_TRAN_SO_EXT_PRICE.SALES_ORDER_NUMBER)
          WHERE (    RMKTGADM.RMK_SSOT_TRANSACTIONS.WEB_ORDER_ID IS NOT NULL
                 AND RMKTGADM.RMK_SSOT_TRANSACTIONS.TRANSACTION_TYPE IN
                        ('WEB_ORDER', 'STANDALONE_ORDER')
                 AND (   RMKTGADM.RMK_SSOT_TRANSACTIONS.SO_LINE_STATUS NOT IN
                            ('IFS_SHIPPED',
                             'IFS_INTERFACED',
                             'INVOICE_ELIGIBLE',
                             'CANCELLED',
                             'NOT_ENTERED',
                             'INVOICED',
                             'CISCOSHIPPED')
                      OR RMKTGADM.RMK_SSOT_TRANSACTIONS.SO_LINE_STATUS
                            IS NULL)
                 AND RMKTGADM.RMK_SSOT_TRANSACTIONS.RESERVATION_STATUS =
                        'ACTIVE'
                 AND RMKTGADM.RMK_SSOT_TRANSACTIONS.WEB_ORDER_STATUS NOT IN
                        ('CANCELLED', 'CLOSED'));
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_theater := T_NORMALISED_LIST ();
      END;



      o_order_stauts := lv_order_stauts;
      o_theater := lv_theater;
      o_fiscal_quarter := lv_fiscal_quarter;
      o_status := 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_status := 0;
         g_error_msg :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12);

         COMMIT;
   END;


   PROCEDURE RC_GET_SUMMA_REPORT (
      i_OD_fiscal_year         IN     VARCHAR2,
      i_OD_part_number         IN     VARCHAR2,
      i_OD_order_status        IN     VARCHAR2,
      i_OD_order_number        IN     VARCHAR2,
      i_OD_end_customer_name   IN     VARCHAR2,
      i_OD_theater             IN     VARCHAR2,
      --Advance filter for Order Backlog
      i_OB_part_number         IN     VARCHAR2,
      i_OB_order_status        IN     VARCHAR2,
      i_OB_order_number        IN     VARCHAR2,
      i_OB_end_customer_name   IN     VARCHAR2,
      i_OB_theater             IN     VARCHAR2,
      i_OB_order_line_amount   IN     VARCHAR2,
      --advance fitlers end
      o_od_summary_data           OUT ORDER_DETAILS_SUMMA_LIST,
      o_ob_summary_data           OUT ORDER_DETAILS_SUMMA_LIST,
      o_status                    OUT NUMBER)
   IS
      lv_fiscal_year                  VARCHAR2 (100);
      lv_fiscal_year_query            VARCHAR2 (32767);
      lv_od_summary_data              ORDER_DETAILS_SUMMA_LIST;
      lv_ob_summary_data              ORDER_DETAILS_SUMMA_LIST;
      lv_part_number                  VARCHAR2 (32767);
      lv_part_number_query            VARCHAR2 (32767);
      lv_fiscal_quarter_check         VARCHAR2 (10);
      lv_order_status                 VARCHAR2 (100);
      lv_order_status_query           VARCHAR2 (32767);
      lv_order_number                 VARCHAR2 (32767);
      lv_order_number_query           VARCHAR2 (32767);
      lv_end_customer_name            VARCHAR2 (32767);
      lv_end_customer_name_query      VARCHAR2 (32767);
      lv_theater                      VARCHAR2 (50);
      lv_theater_query                VARCHAR2 (32767);
      lv_od_summary_query             CLOB;
      lv_ob_summary_query             CLOB;
      g_error_msg                     CLOB;
      lv_i_refresh_part_number        VARCHAR2 (32767);
      lv_idx                          NUMBER;
      lv_cur_part_number              VARCHAR2 (32767);
      lv_booked_qty_qry               VARCHAR2 (32767);
      lv_booked_rev_qry               VARCHAR2 (32767);
      lv_ob_booked_qty_qry            VARCHAR2 (32767);
      lv_ob_booked_rev_qry            VARCHAR2 (32767);

      lv_OB_part_number               VARCHAR2 (32767);
      lv_OB_part_number_query         VARCHAR2 (32767);
      lv_OB_order_status              VARCHAR2 (32767);
      lv_OB_order_status_query        VARCHAR2 (32767);
      lv_OB_order_number              VARCHAR2 (32767);
      lv_OB_order_number_query        VARCHAR2 (32767);
      lv_OB_end_customer_name         VARCHAR2 (32767);
      lv_OB_end_customer_name_query   VARCHAR2 (32767);
      lv_OB_theater                   VARCHAR2 (32767);
      lv_OB_theater_query             VARCHAR2 (32767);
      lv_OB_order_line_amount         VARCHAR2 (32767);
      lv_OB_order_line_amount_query   VARCHAR2 (32767);
   BEGIN
      lv_fiscal_year := i_OD_fiscal_year;
      lv_part_number := i_OD_part_number;
      lv_order_status := i_OD_order_status;
      lv_order_number := i_OD_order_number;
      lv_end_customer_name := i_OD_end_customer_name;
      lv_theater := i_OD_theater;
      lv_od_summary_data := ORDER_DETAILS_SUMMA_LIST ();
      lv_ob_summary_data := ORDER_DETAILS_SUMMA_LIST ();

      lv_OB_part_number := i_OB_part_number;
      lv_OB_order_status := i_OB_order_status;
      lv_OB_order_number := i_OB_order_number;
      lv_OB_end_customer_name := i_OB_end_customer_name;
      lv_OB_theater := i_OB_theater;
      lv_OB_order_line_amount := i_OB_order_line_amount;

      IF (lv_fiscal_year IS NULL)
      THEN
         SELECT fiscal_quarter_name
           INTO lv_fiscal_year
           FROM rmktgadm.CDM_TIME_HIERARCHY_DIM
          WHERE calendar_date = TRUNC (SYSDATE);
      END IF;

      SELECT DISTINCT CURRENT_FISCAL_QUARTER_FLAG
        INTO lv_fiscal_quarter_check
        FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
       WHERE FISCAL_QUARTER_NAME = lv_fiscal_year;

      --(start) commented by hkarka on 19-DEC-2017
      /*
         lv_od_summary_query:='
          SELECT ORDER_DETAILS_SUMMA_OBJ(
                  Order_Total_Amount,
                  Order_Total_Quantity
              )
          FROM(
          SELECT   SUM(ssot.EXT_NET_PRICE_USD) Order_Total_Amount,
                   --  SUM(co.QUANTITY) Order_Total_Quantity --Commented by satband for correct count
                      COUNT(ssot.sales_order_line_number) Order_Total_Quantity --Added by satband for correct count
                FROM rmktgadm.co_order_rf_publish co,
                       rmktgadm.xxcpo_rmk_reservation_header hdr,
                       rmktgadm.rmk_ssot_transactions ssot,
                       rmktgadm.CDM_TIME_HIERARCHY_DIM dim,
                       CRPADM.EX_CUSTOMER_ADDRESS EX,
                       CRPADM.RC_PRODUCT_MASTER PM
                 WHERE     1 = 1
                       AND co.web_order_id = hdr.web_order_id
                       AND co.order_line_id = HDR.WEB_ORDER_LINE_ID
                       AND co.web_order_id = ssot.web_order_id
                       AND co.order_line_id = ssot.WEB_ORDER_LINE_ID
                       AND CO.END_CUSTOMER_SITE_ID = EX.EX_SITE_USE_ID(+)
                       AND PM.REFRESH_PART_NUMBER = CO.PART_NUMBER
                       AND dim.calendar_date = TRUNC (order_creation_date)
                       AND hdr.active_flag = 1
                       AND is_refurbished = ''Y''
                       AND (   TRUNC (co.order_creation_date) >=
                                  TO_DATE (''09/10/2016'', ''mm/dd/yyyy'')
                            OR TRUNC (co.order_line_created_on) >=
                                  TO_DATE (''09/10/2016'', ''mm/dd/yyyy''))
                       --Added by satbanda for correct count <Start>
                       AND ssot.TRANSACTION_TYPE IN (''WEB_ORDER'',
                                                                        ''STANDALONE_ORDER'')
                        AND (   ssot.SO_LINE_STATUS NOT IN (''IFS_SHIPPED'',
                                                                                      ''IFS_INTERFACED'',
                                                                                      ''INVOICE_ELIGIBLE'',
                                                                                      ''CANCELLED'',
                                                                                      ''NOT_ENTERED'',
                                                                                      ''INVOICED'',
                                                                                      ''CISCOSHIPPED'')
                             OR ssot.SO_LINE_STATUS IS NULL)
                        AND ssot.RESERVATION_STATUS = ''ACTIVE''
                        AND ssot.INVENTORY_SITE in (''FVE'', ''LRO'')
                        AND ssot.WEB_ORDER_STATUS  NOT IN (''CANCELLED'', ''CLOSED'')
                        --Added by satbanda for correct count <End>
                                                    ';
      */
      --(end) commented by hkarka on 19-DEC-2017

      --(start) added by hkarka on 19-DEC-2017

      IF (lv_fiscal_year IS NOT NULL)
      THEN
         lv_fiscal_year_query :=
               lv_fiscal_year_query
            || ' AND dim.fiscal_quarter_name = '''
            || lv_fiscal_year
            || '''';
      END IF;

      -- Added by obarbier for 25k filters
      IF (lv_OB_order_line_amount IS NOT NULL)
      THEN
         lv_OB_order_line_amount_query :=
               lv_OB_order_line_amount_query
            --|| ' AND SUM_EXTENDED_NET_PRICE '  --commented by hkarka on 19-DEC-2017
            || ' AND RMKTGADM.RMK_SSOT_TRANSACTIONS.EXT_NET_PRICE_USD '
            || lv_OB_order_line_amount
            || '';
      END IF;

      -- Endof filters

      /* Advance filter on site */
      IF (lv_order_status IS NOT NULL)
      THEN
         /*For Summry Information */
         lv_order_status_query :=
               lv_order_status_query
            || 'AND (ssot.WEB_ORDER_STATUS || ''-'' || ssot.SO_LINE_STATUS) =''' --uncommented by hkarka on 19-DEC-2017
            --       || 'AND (ssot.WEB_ORDER_STATUS) =''' --commented by hkarka on 19-DEC-2017
            || lv_order_status
            || '''';
      END IF;

      IF (lv_OB_order_status IS NOT NULL)
      THEN
         /*For Summry Information */

         lv_OB_order_status_query :=
               lv_OB_order_status_query
            || 'AND RMKTGADM.RMK_SSOT_TRANSACTIONS.so_line_status ='''
            || lv_OB_order_status
            || '''';
      END IF;

      IF (lv_theater IS NOT NULL)
      THEN
         lv_theater_query :=
               lv_theater_query
            || 'AND
                     ( NVL (
                    (SELECT DISTINCT
                            NVL (map.region_name,
                                 ''Country Mapping Unavailable'')
                       FROM VAVNI_CISCO_RSCM_ADMIN.oct_mdm_region_country_map map --need to change to Crpadm
                      WHERE     co.INVOICE_TO_CUSTOMER_COUNTRY_CD =
                                   map.country_name(+)
                            AND map.ACTIVE = ''A''),
                    ''Country Mapping Unavailable'')='''
            || lv_theater
            || ''')';
      END IF;

      IF (lv_OB_theater IS NOT NULL)
      THEN
         lv_OB_theater_query :=
               lv_OB_theater_query
            || 'AND RMKTGADM.RMK_SSOT_TRANSACTIONS.THEATER ='''
            || lv_OB_theater
            || '''';
      END IF;

      /* Advance filter on part Number */
      IF lv_part_number IS NOT NULL
      THEN
         IF (lv_part_number IS NOT NULL)
         THEN
            lv_part_number_query := lv_part_number_query || ' AND ( ';

            lv_i_refresh_part_number := lv_part_number;

            lv_idx := INSTR (lv_i_refresh_part_number, ',');


            IF lv_idx = 0
            THEN
               lv_i_refresh_part_number :=
                  REPLACE (lv_i_refresh_part_number, '*', '');



               lv_part_number_query :=
                     lv_part_number_query
                  || 'UPPER(co.PART_NUMBER) LIKE UPPER(''%'
                  || lv_i_refresh_part_number
                  || '%'')';
            ELSE
               lv_cur_part_number :=
                  SUBSTR (lv_i_refresh_part_number,
                          1,
                          INSTR (lv_i_refresh_part_number, ',') - 1);
               lv_cur_part_number := REPLACE (lv_cur_part_number, '*', '');



               lv_part_number_query :=
                     lv_part_number_query
                  || 'UPPER(co.PART_NUMBER) LIKE UPPER(''%'
                  || lv_cur_part_number
                  || '%'')';

               lv_i_refresh_part_number :=
                  SUBSTR (lv_i_refresh_part_number, lv_idx + LENGTH (' '));
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
                        SUBSTR (lv_i_refresh_part_number,
                                lv_idx + LENGTH (','));
                     lv_cur_part_number :=
                        REPLACE (lv_cur_part_number, '*', '');

                     lv_part_number_query :=
                           lv_part_number_query
                        || ' OR UPPER(co.PART_NUMBER) LIKE  UPPER(''%'
                        || lv_cur_part_number
                        || '%'')';
                  ELSE
                     lv_i_refresh_part_number :=
                        REPLACE (lv_i_refresh_part_number, '*', '');
                     lv_part_number_query :=
                           lv_part_number_query
                        || ' OR UPPER(co.PART_NUMBER) LIKE  UPPER(''%'
                        || lv_i_refresh_part_number
                        || '%'')';
                     EXIT;
                  END IF;
               END LOOP;
            END IF;
         END IF;

         lv_part_number_query := lv_part_number_query || ')';
      END IF;

      IF lv_OB_part_number IS NOT NULL
      THEN
         IF (lv_OB_part_number IS NOT NULL)
         THEN
            lv_OB_part_number_query := lv_OB_part_number_query || ' AND ( ';

            lv_i_refresh_part_number := lv_OB_part_number;

            lv_idx := INSTR (lv_i_refresh_part_number, ',');


            IF lv_idx = 0
            THEN
               lv_i_refresh_part_number :=
                  REPLACE (lv_i_refresh_part_number, '*', '');
               lv_OB_part_number_query :=
                     lv_OB_part_number_query
                  || 'UPPER( RMKTGADM.RMK_SSOT_TRANSACTIONS.PRODUCT_ID) LIKE UPPER(''%'
                  || lv_i_refresh_part_number
                  || '%'')';
            ELSE
               lv_cur_part_number :=
                  SUBSTR (lv_i_refresh_part_number,
                          1,
                          INSTR (lv_i_refresh_part_number, ',') - 1);
               lv_cur_part_number := REPLACE (lv_cur_part_number, '*', '');

               lv_OB_part_number_query :=
                     lv_OB_part_number_query
                  || 'UPPER( RMKTGADM.RMK_SSOT_TRANSACTIONS.PRODUCT_ID) LIKE UPPER(''%'
                  || lv_cur_part_number
                  || '%'')';

               lv_i_refresh_part_number :=
                  SUBSTR (lv_i_refresh_part_number, lv_idx + LENGTH (' '));
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
                        SUBSTR (lv_i_refresh_part_number,
                                lv_idx + LENGTH (','));
                     lv_cur_part_number :=
                        REPLACE (lv_cur_part_number, '*', '');

                     lv_OB_part_number_query :=
                           lv_OB_part_number_query
                        || ' OR UPPER(RMKTGADM.RMK_SSOT_TRANSACTIONS.PRODUCT_ID) LIKE  UPPER(''%'
                        || lv_cur_part_number
                        || '%'')';
                  ELSE
                     lv_i_refresh_part_number :=
                        REPLACE (lv_i_refresh_part_number, '*', '');
                     lv_OB_part_number_query :=
                           lv_OB_part_number_query
                        || ' OR UPPER( RMKTGADM.RMK_SSOT_TRANSACTIONS.PRODUCT_ID) LIKE  UPPER(''%'
                        || lv_i_refresh_part_number
                        || '%'')';
                     EXIT;
                  END IF;
               END LOOP;
            END IF;
         END IF;

         lv_OB_part_number_query := lv_OB_part_number_query || ')';
      END IF;

      IF lv_order_number IS NOT NULL
      THEN
         IF (lv_order_number IS NOT NULL)
         THEN
            lv_order_number_query := lv_order_number_query || ' AND ( ';

            lv_i_refresh_part_number := lv_order_number;
            lv_idx := INSTR (lv_i_refresh_part_number, ',');


            IF lv_idx = 0
            THEN
               lv_i_refresh_part_number :=
                  REPLACE (lv_i_refresh_part_number, '*', '');



               lv_order_number_query :=
                     lv_order_number_query
                  || 'UPPER(ssot.sales_order_number) LIKE UPPER(''%'
                  || lv_i_refresh_part_number
                  || '%'')';
            ELSE
               lv_cur_part_number :=
                  SUBSTR (lv_i_refresh_part_number,
                          1,
                          INSTR (lv_i_refresh_part_number, ',') - 1);
               lv_cur_part_number := REPLACE (lv_cur_part_number, '*', '');



               lv_order_number_query :=
                     lv_order_number_query
                  || 'UPPER(ssot.sales_order_number) LIKE UPPER(''%'
                  || lv_cur_part_number
                  || '%'')';

               lv_i_refresh_part_number :=
                  SUBSTR (lv_i_refresh_part_number, lv_idx + LENGTH (' '));
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
                        SUBSTR (lv_i_refresh_part_number,
                                lv_idx + LENGTH (','));
                     lv_cur_part_number :=
                        REPLACE (lv_cur_part_number, '*', '');

                     lv_order_number_query :=
                           lv_od_summary_query
                        || ' OR UPPER(ssot.sales_order_number) LIKE  UPPER(''%'
                        || lv_cur_part_number
                        || '%'')';
                  ELSE
                     lv_i_refresh_part_number :=
                        REPLACE (lv_i_refresh_part_number, '*', '');
                     lv_order_number_query :=
                           lv_od_summary_query
                        || ' OR UPPER(ssot.sales_order_number) LIKE  UPPER(''%'
                        || lv_i_refresh_part_number
                        || '%'')';
                     EXIT;
                  END IF;
               END LOOP;
            END IF;
         END IF;

         lv_order_number_query := lv_order_number_query || ')';
      END IF;

      IF lv_OB_order_number IS NOT NULL
      THEN
         IF (lv_OB_order_number IS NOT NULL)
         THEN
            lv_OB_order_number_query := lv_OB_order_number_query || ' AND ( ';

            lv_i_refresh_part_number := lv_OB_order_number;
            lv_idx := INSTR (lv_i_refresh_part_number, ',');


            IF lv_idx = 0
            THEN
               lv_i_refresh_part_number :=
                  REPLACE (lv_i_refresh_part_number, '*', '');

               lv_OB_order_number_query :=
                     lv_OB_order_number_query
                  || 'UPPER( RMKTGADM.RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER) LIKE UPPER(''%'
                  || lv_i_refresh_part_number
                  || '%'')';
            ELSE
               lv_cur_part_number :=
                  SUBSTR (lv_i_refresh_part_number,
                          1,
                          INSTR (lv_i_refresh_part_number, ',') - 1);
               lv_cur_part_number := REPLACE (lv_cur_part_number, '*', '');


               lv_OB_order_number_query :=
                     lv_OB_order_number_query
                  || 'UPPER( RMKTGADM.RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER) LIKE UPPER(''%'
                  || lv_cur_part_number
                  || '%'')';

               lv_i_refresh_part_number :=
                  SUBSTR (lv_i_refresh_part_number, lv_idx + LENGTH (' '));
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
                        SUBSTR (lv_i_refresh_part_number,
                                lv_idx + LENGTH (','));
                     lv_cur_part_number :=
                        REPLACE (lv_cur_part_number, '*', '');
                     lv_OB_order_number_query :=
                           lv_OB_order_number_query
                        || ' OR UPPER( RMKTGADM.RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER) LIKE  UPPER(''%'
                        || lv_cur_part_number
                        || '%'')';
                  ELSE
                     lv_i_refresh_part_number :=
                        REPLACE (lv_i_refresh_part_number, '*', '');
                     lv_OB_order_number_query :=
                           lv_OB_order_number_query
                        || ' OR UPPER( RMKTGADM.RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER) LIKE  UPPER(''%'
                        || lv_i_refresh_part_number
                        || '%'')';
                     EXIT;
                  END IF;
               END LOOP;
            END IF;
         END IF;

         lv_OB_order_number_query := lv_OB_order_number_query || ')';
      END IF;


      IF lv_end_customer_name IS NOT NULL
      THEN
         IF (lv_end_customer_name IS NOT NULL)
         THEN
            lv_end_customer_name_query :=
               lv_end_customer_name_query || ' AND ( ';
            lv_i_refresh_part_number := lv_end_customer_name;
            lv_idx := INSTR (lv_i_refresh_part_number, ',');


            IF lv_idx = 0
            THEN
               lv_i_refresh_part_number :=
                  REPLACE (lv_i_refresh_part_number, '*', '');


               lv_end_customer_name_query :=
                     lv_end_customer_name_query
                  --|| 'UPPER(co.END_USER_CUSTOMER) LIKE UPPER(''%'  --commented by hkarka on 19-DEc-2017
                  || 'UPPER(co.END_CUSTOMER_NAME) LIKE UPPER(''%' --added by hkarka on 19-DEC-2017
                  || lv_i_refresh_part_number
                  || '%'')';
            ELSE
               lv_cur_part_number :=
                  SUBSTR (lv_i_refresh_part_number,
                          1,
                          INSTR (lv_i_refresh_part_number, ',') - 1);
               lv_cur_part_number := REPLACE (lv_cur_part_number, '*', '');


               lv_end_customer_name_query :=
                     lv_end_customer_name_query
                  --|| 'UPPER(co.END_USER_CUSTOMER) LIKE UPPER(''%'  --commented by hkarka on 19-DEC-2017
                  || 'UPPER(co.END_CUSTOMER_NAME) LIKE UPPER(''%' --added by hkarka on 19-DEC-2017
                  || lv_cur_part_number
                  || '%'')';

               lv_i_refresh_part_number :=
                  SUBSTR (lv_i_refresh_part_number, lv_idx + LENGTH (' '));
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
                        SUBSTR (lv_i_refresh_part_number,
                                lv_idx + LENGTH (','));
                     lv_cur_part_number :=
                        REPLACE (lv_cur_part_number, '*', '');

                     lv_end_customer_name_query :=
                           lv_end_customer_name_query
                        --|| ' OR UPPER(co.END_USER_CUSTOMER) LIKE  UPPER(''%'  --commented by hkarka on 19-DEC-2017
                        || ' OR UPPER(co.END_CUSTOMER_NAME) LIKE  UPPER(''%' --added by hkarka on 19-DEC-2017
                        || lv_cur_part_number
                        || '%'')';
                  ELSE
                     lv_i_refresh_part_number :=
                        REPLACE (lv_i_refresh_part_number, '*', '');
                     lv_end_customer_name_query :=
                           lv_end_customer_name_query
                        --|| ' OR UPPER(co.END_USER_CUSTOMER) LIKE  UPPER(''%'  --commented by hkarka on 19-DEC-2017
                        || ' OR UPPER(co.END_CUSTOMER_NAME) LIKE  UPPER(''%' --added by hkarka on 19-DEC-2017
                        || lv_i_refresh_part_number
                        || '%'')';

                     EXIT;
                  END IF;
               END LOOP;
            END IF;
         END IF;

         --lv_od_summary_query := lv_od_summary_query || '))';  --commented by hkarka on 19-DEC-2017
         lv_end_customer_name_query := lv_end_customer_name_query || ')'; --added by hkarka on 19-DEC-2017
      END IF;

      IF lv_OB_end_customer_name IS NOT NULL
      THEN
         IF (lv_OB_end_customer_name IS NOT NULL)
         THEN
            lv_OB_end_customer_name_query :=
               lv_OB_end_customer_name_query || ' AND ( ';

            lv_i_refresh_part_number := lv_OB_end_customer_name;
            lv_idx := INSTR (lv_i_refresh_part_number, ',');


            IF lv_idx = 0
            THEN
               lv_i_refresh_part_number :=
                  REPLACE (lv_i_refresh_part_number, '*', '');
               lv_OB_end_customer_name_query :=
                     lv_OB_end_customer_name_query
                  || 'UPPER(RMKTGADM.RMK_SSOT_TRANSACTIONS.END_USER_CUSTOMER) LIKE UPPER(''%'
                  || lv_i_refresh_part_number
                  || '%'')';
            ELSE
               lv_cur_part_number :=
                  SUBSTR (lv_i_refresh_part_number,
                          1,
                          INSTR (lv_i_refresh_part_number, ',') - 1);
               lv_cur_part_number := REPLACE (lv_cur_part_number, '*', '');
               lv_OB_end_customer_name_query :=
                     lv_OB_end_customer_name_query
                  || 'UPPER(RMKTGADM.RMK_SSOT_TRANSACTIONS.END_USER_CUSTOMER) LIKE UPPER(''%'
                  || lv_cur_part_number
                  || '%'')';

               lv_i_refresh_part_number :=
                  SUBSTR (lv_i_refresh_part_number, lv_idx + LENGTH (' '));
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
                        SUBSTR (lv_i_refresh_part_number,
                                lv_idx + LENGTH (','));
                     lv_cur_part_number :=
                        REPLACE (lv_cur_part_number, '*', '');
                     lv_OB_end_customer_name_query :=
                           lv_OB_end_customer_name_query
                        || ' OR UPPER(RMKTGADM.RMK_SSOT_TRANSACTIONS.END_USER_CUSTOMER) LIKE  UPPER(''%'
                        || lv_cur_part_number
                        || '%'')';
                  ELSE
                     lv_i_refresh_part_number :=
                        REPLACE (lv_i_refresh_part_number, '*', '');
                     lv_OB_end_customer_name_query :=
                           lv_OB_end_customer_name_query
                        || ' OR UPPER(RMKTGADM.RMK_SSOT_TRANSACTIONS.END_USER_CUSTOMER) LIKE  UPPER(''%'
                        || lv_i_refresh_part_number
                        || '%'')';
                     EXIT;
                  END IF;
               END LOOP;
            END IF;
         END IF;

         lv_OB_end_customer_name_query :=
            lv_OB_end_customer_name_query || ')';
      END IF;


      IF lv_fiscal_quarter_check = 'Y'
      THEN
         lv_booked_rev_qry :=
               ' (SELECT /*+ parallel(qry) */ SUM (TOTAL_BOOKINGS)
                  FROM (  SELECT SALES_ORDER_NUMBER,
                                 tr.PRODUCT_ID PART_NUMBER,
                                 tr.end_user_customer end_customer_name,
                                 tr.so_line_Status,
                                 tr.web_order_Status,
                                  sum(NVL(REV_CUR_WK,0)+NVL(REV_NEXT_WK,0)+NVL(REV_CUR_QTR_REM_WKS,0)+NVL(REV_NEXT_QTR,0)+NVL(REV_TO_BE_SCHEDULED,0)
   +NVL(REV_NO_INVENTORY,0)+NVL(REV_IN_TRANSIT,0))
                                    TOTAL_BOOKINGS,
                                 (select distinct INVOICE_TO_CUSTOMER_COUNTRY_CD from rmktgadm.co_order_rf_publish co
   WHERE tr.WEB_ORDER_ID=ORDER_ID AND tr.WEB_ORDER_LINE_ID =CO.ORDER_LINE_ID
  ) INVOICE_TO_CUSTOMER_COUNTRY_CD
                            FROM rmktgadm.rmk_ssot_transactions TR RIGHT OUTER JOIN CRPADM.RC_MASTER_BACKLOG BSF
                                 ON BSF.ORDER_NUMBER = TR.SALES_ORDER_NUMBER
                                 AND BSF.MFG_LINE_ID = TR.SO_LINE_ID
                                 AND BSF.LINE_NUMBER =
                                        TR.SALES_ORDER_LINE_NUMBER
                        GROUP BY SALES_ORDER_NUMBER,
                                 tr.PRODUCT_ID,tr.WEB_ORDER_ID,tr.WEB_ORDER_LINE_ID,
                                 tr.end_user_customer,
                                 tr.so_line_Status,
                                 tr.web_order_Status
                                 ) qry WHERE 1=1'
            || REPLACE (lv_part_number_query, 'co.')
            || REPLACE (lv_order_status_query, 'ssot.')
            || REPLACE (lv_order_number_query, 'ssot.')
            || REPLACE (lv_end_customer_name_query, 'co.')
            || REPLACE (lv_theater_query, 'co.')
            || ' ) AS Booked_Revenue';

         lv_booked_qty_qry :=
               '(SELECT /*+ parallel(qry1) */ SUM (TOTAL_BOOKINGS)
  FROM (  SELECT SALES_ORDER_NUMBER,
                 PRODUCT_ID PART_NUMBER,
                 end_user_customer end_customer_name,
                 so_line_Status,
                 web_order_Status,
                 COUNT (DISTINCT sales_order_line_number) TOTAL_BOOKINGS,
                 co.INVOICE_TO_CUSTOMER_COUNTRY_CD
            FROM rmktgadm.rmk_ssot_transactions TR,
                 rmktgadm.co_order_rf_publish co
           WHERE     co.weB_order_id = tr.web_order_id
                 AND co.order_line_id = tr.web_order_line_id
                 AND EXISTS
                        (SELECT 1
                           FROM CRPADM.RC_MASTER_BACKLOG BSF
                          WHERE     (  NVL (qty_CUR_WK, 0)
                                     + NVL (qty_NEXT_WK, 0)
                                     + NVL (QTY_CUR_QTR_REM_WKS, 0)
                                     + NVL (QTY_NEXT_QTR, 0)
                                     + NVL (QTY_TO_BE_SCHEDULED, 0)
                                     + NVL (QTY_NO_INVENTORY, 0)
                                     + NVL (QTY_IN_TRANSIT, 0)) > 0
                                AND TR.SALES_ORDER_NUMBER = BSF.ORDER_NUMBER
                                AND TR.SO_LINE_ID = BSF.MFG_LINE_ID
                                AND tr.sales_order_line_number =
                                       bsf.line_number)
        GROUP BY SALES_ORDER_NUMBER,
                 tr.WEB_ORDER_ID,
                 WEB_ORDER_LINE_ID,
                 PRODUCT_ID,
                 end_user_customer,
                 so_line_Status,
                 web_order_Status,
                 INVOICE_TO_CUSTOMER_COUNTRY_CD) qry1
  WHERE 1=1'
            || REPLACE (lv_part_number_query, 'co.')
            || REPLACE (lv_order_status_query, 'ssot.')
            || REPLACE (lv_order_number_query, 'ssot.')
            || REPLACE (lv_end_customer_name_query, 'co.')
            || REPLACE (lv_theater_query, 'co.')
            || ' ) AS Booked_qty';
      ELSE
         lv_booked_rev_qry :=
               '(select /*+ parallel(qry) */
   sum(TOTAL_BOOKINGS) from (select ORDER_NUMBER SALES_ORDER_NUMBER,
                  PRODUCT_ID PART_NUMBER,
                 COUNTRY THEATER,
                 end_user_customer end_customer_name,sum(NVL(REV_CUR_WK,0)+NVL(REV_NEXT_WK,0)+NVL(REV_CUR_QTR_REM_WKS,0)+NVL(REV_NEXT_QTR,0)+NVL(REV_TO_BE_SCHEDULED,0)
   +NVL(REV_NO_INVENTORY,0)+NVL(REV_IN_TRANSIT,0)) TOTAL_BOOKINGS,
   (select dim.fiscal_quarter_name
   from RMKTGADM.CDM_TIME_HIERARCHY_DIM DIM
   WHERE TRUNC(BSF.HISTORY_SAVE_DATE)=TRUNC(CALENDAR_DATE))  fiscal_quarter, (select MAX (so_line_Status) 
   from RMKTGADM.RMK_SSOT_TRANSACTIONS TR where TR.SALES_ORDER_NUMBER=BSF.ORDER_NUMBER and TR.SO_LINE_ID=BSF.MFG_LINE_ID
   and tr.sales_order_line_number=bsf.line_number) as so_line_Status,
   (select MAX (web_order_Status) 
   from RMKTGADM.RMK_SSOT_TRANSACTIONS TR where TR.SALES_ORDER_NUMBER=BSF.ORDER_NUMBER and TR.SO_LINE_ID=BSF.MFG_LINE_ID
   and tr.sales_order_line_number=bsf.line_number) as web_order_Status,
    (select distinct INVOICE_TO_CUSTOMER_COUNTRY_CD from rmktgadm.co_order_rf_publish co,rmktgadm.rmk_ssot_transactions ssot
   WHERE ssot.WEB_ORDER_ID=ORDER_ID AND ssot.WEB_ORDER_LINE_ID =CO.ORDER_LINE_ID
   and ssot.SALES_ORDER_NUMBER=BSF.ORDER_NUMBER and ssot.SO_LINE_ID=BSF.MFG_LINE_ID
   and ssot.sales_order_line_number=bsf.line_number ) INVOICE_TO_CUSTOMER_COUNTRY_CD
    from CRPADM.RC_MASTER_BACKLOG_HISTORY BSF WHERE 
     BSF.HISTORY_SAVE_DATE=(SELECT MAX(HISTORY_SAVE_DATE) FROM  CRPADM.RC_MASTER_BACKLOG_HISTORY
    WHERE EXISTS (SELECT 1 FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM DIM
     WHERE
     TRUNC(HISTORY_SAVE_DATE)=TRUNC(CALENDAR_DATE)
      AND CALENDAR_DATE=FISCAL_QTR_START_DATE
    '
            || lv_fiscal_year_query
            || ' )) GROUP BY HISTORY_SAVE_DATE,ORDER_NUMBER,MFG_LINE_ID,PRODUCT_ID,country,end_user_customer,line_number
   ) qry WHERE 1=1 '
            || REPLACE (lv_part_number_query, 'co.')
            || REPLACE (lv_order_status_query, 'ssot.')
            || REPLACE (lv_order_number_query, 'ssot.')
            || REPLACE (lv_end_customer_name_query, 'co.')
            || REPLACE (lv_theater_query, 'co.')
            || ' ) AS Booked_Revenue';

         lv_booked_qty_qry :=
               '(SELECT /*+ parallel(qry1) */ SUM (TOTAL_BOOKINGS)
  FROM (  SELECT SALES_ORDER_NUMBER,
                 PRODUCT_ID PART_NUMBER,
                 end_user_customer end_customer_name,
                 so_line_Status,
                 web_order_Status,
                 COUNT (DISTINCT sales_order_line_number) TOTAL_BOOKINGS,
                 co.INVOICE_TO_CUSTOMER_COUNTRY_CD
            FROM rmktgadm.rmk_ssot_transactions TR,
                 rmktgadm.co_order_rf_publish co
           WHERE     co.weB_order_id = tr.web_order_id
                 AND co.order_line_id = tr.web_order_line_id
                 AND EXISTS
                        (SELECT 1
                           FROM CRPADM.RC_MASTER_BACKLOG_HISTORY BSF
                          WHERE     (  NVL (qty_CUR_WK, 0)
                                     + NVL (qty_NEXT_WK, 0)
                                     + NVL (QTY_CUR_QTR_REM_WKS, 0)
                                     + NVL (QTY_NEXT_QTR, 0)
                                     + NVL (QTY_TO_BE_SCHEDULED, 0)
                                     + NVL (QTY_NO_INVENTORY, 0)
                                     + NVL (QTY_IN_TRANSIT, 0)) > 0
                                AND TR.SALES_ORDER_NUMBER = BSF.ORDER_NUMBER
                                AND TR.SO_LINE_ID = BSF.MFG_LINE_ID
                                AND tr.sales_order_line_number =
                                       bsf.line_number
                                AND BSF.HISTORY_SAVE_DATE =
                                       (SELECT MAX (HISTORY_SAVE_DATE)
                                          FROM CRPADM.RC_MASTER_BACKLOG_HISTORY
                                         WHERE TRUNC (HISTORY_SAVE_DATE) IN (SELECT TRUNC (
                                                                                       CALENDAR_DATE)
                                                                               FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM DIM
                                                                              WHERE     CALENDAR_DATE =
                                                                                           FISCAL_QTR_START_DATE
     '
            || lv_fiscal_year_query
            || ' )))
  GROUP BY SALES_ORDER_NUMBER,
                 tr.WEB_ORDER_ID,
                 WEB_ORDER_LINE_ID,
                 PRODUCT_ID,
                 end_user_customer,
                 so_line_Status,
                 web_order_Status,
                 INVOICE_TO_CUSTOMER_COUNTRY_CD
   ) qry1 WHERE 1=1 '
            || REPLACE (lv_part_number_query, 'co.')
            || REPLACE (lv_order_status_query, 'ssot.')
            || REPLACE (lv_order_number_query, 'ssot.')
            || REPLACE (lv_end_customer_name_query, 'co.')
            || REPLACE (lv_theater_query, 'co.')
            || ' ) AS Booked_qty';
      END IF;



      lv_od_summary_query :=
            '
    SELECT ORDER_DETAILS_SUMMA_OBJ(
            Order_Total_Amount,
            Order_Total_Quantity,
            Booked_qty,
            Booked_Revenue
        )
    FROM (SELECT Order_Total_Amount, Order_Total_Quantity ,'
         || lv_booked_qty_qry
         || ', '
         || lv_booked_rev_qry
         || ' 
   from ( SELECT   SUM(EXT_NET_PRICE_USD) Order_Total_Amount,
                COUNT(web_order_line_id) Order_Total_Quantity               
                 from
                (
    SELECT DISTINCT
                 hdr.inventory_flow AS GTM,
                 NVL (
                    (SELECT DISTINCT
                            NVL (map.region_name,
                                 ''Country Mapping Unavailable'')
                       FROM VAVNI_CISCO_RSCM_ADMIN.oct_mdm_region_country_map map --need to change to Crpadm
                      WHERE     co.INVOICE_TO_CUSTOMER_COUNTRY_CD =
                                   map.country_name(+)
                            AND map.ACTIVE = ''A''),
                    ''Country Mapping Unavailable'')
                    AS Theater,
                 (SELECT REGION_NAME
                    FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ADM_BSF_COUNTRYREG_MASTER --need to change to Crpadm
                   WHERE COUNTRY_CODE = ssot.THEATER)
                    REGION_NAME,
                 dim.fiscal_month_id,
                 dim.fiscal_week_name,
                 dim.fiscal_week_number,
                 ssot.sales_order_number,
                 SSOT.SO_LINE_ID,
                 co.QUOTE_ID,
                 co.QUOTE_LINE_ID,
                 co.WEB_ORDER_ID,
                 co.ORDER_LINE_ID AS web_order_line_id,
                 (ssot.WEB_ORDER_STATUS || ''-'' || ssot.SO_LINE_STATUS)
                    AS ORDER_STATUS,
                 co.PURCHASE_ORDER_NUMBER,
                 co.ORDER_CREATION_DATE,
                 co.ORDER_SUBMISSION_DATE,
                 co.PART_NUMBER,
                 co.QUANTITY,
                 co.LIST_PRICE,
                 co.EXT_LIST_PRICE,
                 co.CURRENCY_CODE,
                 co.ROUNDED_UNIT_NET_PRICE,
                 co.EXTENDED_NET_PRICE,
                 ssot.EXT_NET_PRICE_USD,
                 ssot.DEAL_ID,
                 co.END_CUSTOMER_NAME,
                 co.SHIP_TO_CUSTOMER_NAME,
                 co.BILL_TO_CUSTOMER_TYPE,
                 co.INVOICE_TO_CUSTOMER_NAME,
                 co.ORDER_CREATED_BY,
                 co.ORDER_SUBMITTED_BY,
                 co.ORDER_UPDATED_ON,
                 co.ORDER_LINE_UPDATED_ON,
                 co.RESELLER_CUSTOMER_NAME,
                 co.ORDER_LINE_CREATED_ON,
                 (SELECT RCTM_STD_COUNTRY
                    FROM rmktgadm.RMK_COUNTRY_THEATER_MAP
                   WHERE RCTM_STD_COUNTRY_CODE =
                            co.INVOICE_TO_CUSTOMER_COUNTRY_CD)
                    customer_name,
                 co.ORDER_LINE_CREATED_BY,
                 co.ORDER_LINE_UPDATED_BY,
                 ssot.HOLD_NAME,
                 EX.EX_STATE,
                 NVL (Ex.EX_COUNTRY, ''NO END CUSTOMER'') END_CUSTOMER_COUNTRY,
                 pm.PRODUCT_FAMILY,
                 customer_request_date,
                 (SELECT MAX (shp.ship_date)
                    FROM crpsc.xxcrpsc_od_shipment_dtls_intf shp
                   WHERE     SSOT.sales_order_number = shp.SALES_ORDER_NO
                         AND SSOT.sales_order_line_number = shp.line_no)
                    ship_date,
                    ssot.CHANNEL channel,
                    ssot.INVENTORY_SITE inventory_site,
                    dim.fiscal_quarter_name fiscal_quarter
            FROM rmktgadm.co_order_rf_publish co,
                 rmktgadm.xxcpo_rmk_reservation_header hdr,
                 rmktgadm.rmk_ssot_transactions ssot,
                 rmktgadm.CDM_TIME_HIERARCHY_DIM dim,
                 CRPADM.EX_CUSTOMER_ADDRESS EX,
                 CRPADM.RC_PRODUCT_MASTER PM
           WHERE     1 = 1
                 AND co.web_order_id = hdr.web_order_id
                 AND co.order_line_id = HDR.WEB_ORDER_LINE_ID
                 AND co.web_order_id = ssot.web_order_id
                 AND co.order_line_id = ssot.WEB_ORDER_LINE_ID
                 AND CO.END_CUSTOMER_SITE_ID = EX.EX_SITE_USE_ID(+)
                 AND PM.REFRESH_PART_NUMBER = CO.PART_NUMBER
                 AND dim.calendar_date = TRUNC (order_creation_date)
                 AND hdr.active_flag = 1
                 AND is_refurbished = ''Y''
                 AND (   TRUNC (co.order_creation_date) >=
                            TO_DATE (''09/10/2016'', ''mm/dd/yyyy'')
                      OR TRUNC (co.order_line_created_on) >=
                            TO_DATE (''09/10/2016'', ''mm/dd/yyyy'')) ';
      lv_od_summary_query :=
            lv_od_summary_query
         || lv_fiscal_year_query
         || lv_part_number_query
         || lv_order_status_query
         || lv_order_number_query
         || lv_end_customer_name_query
         || lv_theater_query;



      lv_ob_booked_qty_qry := '';

      lv_ob_booked_rev_qry :=
            '(SELECT /*+ parallel(qry) */ SUM (TOTAL_BOOKINGS)
  FROM (  SELECT SALES_ORDER_NUMBER,
                 tr.PRODUCT_ID ,
                 tr.end_user_customer,
                 tr.so_line_Status,
                 tr.web_order_Status,EXT_NET_PRICE_USD,
                  sum(NVL(REV_CUR_WK,0)+NVL(REV_NEXT_WK,0)+NVL(REV_CUR_QTR_REM_WKS,0)+NVL(REV_NEXT_QTR,0)+NVL(REV_TO_BE_SCHEDULED,0)
   +NVL(REV_NO_INVENTORY,0)+NVL(REV_IN_TRANSIT,0)) TOTAL_BOOKINGS,
                 tr.theater
            FROM rmktgadm.rmk_ssot_transactions TR RIGHT OUTER JOIN
                 CRPADM.RC_MASTER_BACKLOG BSF
           ON       BSF.ORDER_NUMBER=TR.SALES_ORDER_NUMBER
   AND BSF.MFG_LINE_ID=TR.SO_LINE_ID
   AND BSF.LINE_NUMBER=TR.SALES_ORDER_LINE_NUMBER
        GROUP BY SALES_ORDER_NUMBER,
                 tr.PRODUCT_ID,EXT_NET_PRICE_USD,
                 tr.end_user_customer,
                 tr.so_line_Status,
                 tr.web_order_Status,
                 tr.theater) qry WHERE 1=1 '
         || REPLACE (lv_OB_part_number_query,
                     'RMKTGADM.RMK_SSOT_TRANSACTIONS.')
         || REPLACE (lv_OB_order_number_query,
                     'RMKTGADM.RMK_SSOT_TRANSACTIONS.')
         || REPLACE (lv_OB_order_line_amount_query,
                     'RMKTGADM.RMK_SSOT_TRANSACTIONS.')
         || REPLACE (lv_OB_order_status_query,
                     'RMKTGADM.RMK_SSOT_TRANSACTIONS.')
         || REPLACE (lv_OB_end_customer_name_query,
                     'RMKTGADM.RMK_SSOT_TRANSACTIONS.')
         || REPLACE (lv_OB_theater_query, 'RMKTGADM.RMK_SSOT_TRANSACTIONS.')
         || ') AS BOOKED_REVENUE';
      lv_ob_booked_qty_qry :=
            ' (select /*+ parallel(qry1) */
   sum(TOTAL_BOOKINGS) from (select ORDER_NUMBER SALES_ORDER_NUMBER,
                 PRODUCT_ID,
                  (select MAX (THEATER) 
   from RMKTGADM.RMK_SSOT_TRANSACTIONS TR where TR.SALES_ORDER_NUMBER=BSF.ORDER_NUMBER and TR.SO_LINE_ID=BSF.MFG_LINE_ID
   and tr.sales_order_line_number=bsf.line_number)  THEATER,
                 (SELECT MAX (end_user_customer)
                                    FROM RMKTGADM.RMK_SSOT_TRANSACTIONS TR
                                   WHERE     TR.SALES_ORDER_NUMBER =
                                                BSF.ORDER_NUMBER
                                         AND TR.SO_LINE_ID = BSF.MFG_LINE_ID
                                         AND tr.sales_order_line_number =
                                                bsf.line_number) end_user_customer ,count(distinct bsf.line_number) TOTAL_BOOKINGS,
  (select MAX (so_line_Status) 
   from RMKTGADM.RMK_SSOT_TRANSACTIONS TR where TR.SALES_ORDER_NUMBER=BSF.ORDER_NUMBER and TR.SO_LINE_ID=BSF.MFG_LINE_ID
   and tr.sales_order_line_number=bsf.line_number) as so_line_Status,
   (select MAX (web_order_Status) 
   from RMKTGADM.RMK_SSOT_TRANSACTIONS TR where TR.SALES_ORDER_NUMBER=BSF.ORDER_NUMBER and TR.SO_LINE_ID=BSF.MFG_LINE_ID
   and tr.sales_order_line_number=bsf.line_number) as web_order_Status,
   (select MAX (EXT_NET_PRICE_USD) 
   from RMKTGADM.RMK_SSOT_TRANSACTIONS TR where TR.SALES_ORDER_NUMBER=BSF.ORDER_NUMBER and TR.SO_LINE_ID=BSF.MFG_LINE_ID
   and tr.sales_order_line_number=bsf.line_number) EXT_NET_PRICE_USD,
    (select distinct INVOICE_TO_CUSTOMER_COUNTRY_CD from rmktgadm.co_order_rf_publish co,rmktgadm.rmk_ssot_transactions ssot
   WHERE ssot.WEB_ORDER_ID=ORDER_ID AND ssot.WEB_ORDER_LINE_ID =CO.ORDER_LINE_ID
   and ssot.SALES_ORDER_NUMBER=BSF.ORDER_NUMBER and ssot.SO_LINE_ID=BSF.MFG_LINE_ID
   and ssot.sales_order_line_number=bsf.line_number ) INVOICE_TO_CUSTOMER_COUNTRY_CD
    from CRPADM.RC_MASTER_BACKLOG BSF
    WHERE (NVL(QTY_CUR_WK,0)+NVL(QTY_NEXT_WK,0)+NVL(QTY_CUR_QTR_REM_WKS,0)+NVL(QTY_NEXT_QTR,0)
                 +NVL(REV_TO_BE_SCHEDULED,0)
   +NVL(QTY_NO_INVENTORY,0)+NVL(QTY_IN_TRANSIT,0))>0
  GROUP BY ORDER_NUMBER,MFG_LINE_ID,PRODUCT_ID,country,end_user_customer,line_number
  ) qry1 WHERE 1=1 '
         || REPLACE (lv_OB_part_number_query,
                     'RMKTGADM.RMK_SSOT_TRANSACTIONS.')
         || REPLACE (lv_OB_order_number_query,
                     'RMKTGADM.RMK_SSOT_TRANSACTIONS.')
         || REPLACE (lv_OB_order_line_amount_query,
                     'RMKTGADM.RMK_SSOT_TRANSACTIONS.')
         || REPLACE (lv_OB_order_status_query,
                     'RMKTGADM.RMK_SSOT_TRANSACTIONS.')
         || REPLACE (lv_OB_end_customer_name_query,
                     'RMKTGADM.RMK_SSOT_TRANSACTIONS.')
         || REPLACE (lv_OB_theater_query, 'RMKTGADM.RMK_SSOT_TRANSACTIONS.')
         || ') AS BOOKED_QTY';

      --(end) added by hkarka on 19-DEC-2017

      lv_ob_summary_query :=
            '    SELECT ORDER_DETAILS_SUMMA_OBJ(
            Order_Total_Amount,
            Order_Total_Quantity,
            Booked_Qty,
            Booked_Revenue
        )
    FROM( SELECT Order_Total_Amount, Order_Total_Quantity,0 Booked_Qty , '
         || lv_ob_booked_rev_qry
         || ' 
    from (SELECT SUM (
                            rmk_ssot_transactions.NET_PRICE_USD
                          * RMKTGADM.RMK_SSOT_TRANSACTIONS.TOTAL_RESERVATION)
                          Order_Total_Amount,
                       COUNT (RMK_SSOT_TRANSACTIONS.sales_order_line_number)
                          Order_Total_Quantity
                  FROM RMKTGADM.RMK_SSOT_TRANSACTIONS
                       INNER JOIN
                       (  SELECT SALES_ORDER_NUMBER AS SALES_ORDER_NUMBER,
                                 SUM (EXTENDED_NET_PRICE) AS EXTENDED_NET_PRICE,
                                 SUM (NET_PRICE_USD) AS NET_PRICE_USD
                            FROM (SELECT DISTINCT
                                         RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER,
                                         ORIGINAL_QUANTITY_REQUESTED,
                                         NVL (
                                            RMK_SSOT_TRANSACTIONS.EXTENDED_NET_PRICE,
                                            0)
                                            EXTENDED_NET_PRICE,
                                         NVL (
                                            RMK_SSOT_TRANSACTIONS.NET_PRICE_USD,
                                            0)
                                            NET_PRICE_USD
                                    FROM RMKTGADM.RMK_SSOT_TRANSACTIONS)
group by SALES_ORDER_NUMBER
  )  RMK_SSOT_TRAN_SO_EXT_PRICE ON (RMKTGADM.RMK_SSOT_TRANSACTIONS.SALES_ORDER_NUMBER=RMK_SSOT_TRAN_SO_EXT_PRICE.SALES_ORDER_NUMBER) 
WHERE
  (
   RMKTGADM.RMK_SSOT_TRANSACTIONS.WEB_ORDER_ID  Is Not Null  
   AND
   RMKTGADM.RMK_SSOT_TRANSACTIONS.TRANSACTION_TYPE  IN  ( ''WEB_ORDER'',''STANDALONE_ORDER''  )
   AND
   (
    RMKTGADM.RMK_SSOT_TRANSACTIONS.SO_LINE_STATUS  NOT IN  ( ''IFS_SHIPPED'',''IFS_INTERFACED'',
                                                             ''INVOICE_ELIGIBLE'',''CANCELLED'',
                                                             ''NOT_ENTERED'',''INVOICED'',''CISCOSHIPPED''  )
    OR
    RMKTGADM.RMK_SSOT_TRANSACTIONS.SO_LINE_STATUS  Is Null  
   )
   AND
   RMKTGADM.RMK_SSOT_TRANSACTIONS.RESERVATION_STATUS  =  ''ACTIVE''
   AND  
   RMKTGADM.RMK_SSOT_TRANSACTIONS.WEB_ORDER_STATUS  NOT IN  ( ''CANCELLED'' )'
         || lv_OB_part_number_query
         || lv_OB_order_number_query
         || lv_OB_order_line_amount_query
         || lv_OB_order_status_query
         || lv_OB_end_customer_name_query
         || lv_OB_theater_query;



      lv_od_summary_query := lv_od_summary_query || ')))'; --added by hkarka on 19-DEC-2017
      lv_ob_summary_query := lv_ob_summary_query || ')))'; --added by hkarka on 19-DEC-2017

      --insert into test_queries_table  (queries, modules, created_on)
      --values (lv_ob_summary_query,'Order Backlog Summary', sysdate);

      COMMIT;

      EXECUTE IMMEDIATE lv_od_summary_query
         BULK COLLECT INTO lv_od_summary_data;

      o_od_summary_data := lv_od_summary_data;

      EXECUTE IMMEDIATE lv_ob_summary_query
         BULK COLLECT INTO lv_ob_summary_data;



      o_ob_summary_data := lv_ob_summary_data;
      o_status := 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_status := 0;
         g_error_msg :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12);


         --           CRPADM.RC_GLOBAL_ERROR_LOGGING (
         --            'OTHERS',
         --            g_error_msg,
         --            NULL,
         --            'RC_ORDER_REPORT_FETCH.RC_GET_SUUMA_REPORT',
         --            'PROCEDURE',
         --            'ADMIN',
         --            'N');

         COMMIT;
   END;
END RC_ORDER_REPORT_FETCH;
/