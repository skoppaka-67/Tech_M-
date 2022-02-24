CREATE OR REPLACE PACKAGE BODY CRPREP./*AppDB: 1032631*/           "RC_SUPPLY_DEMAND_DATA_EXTRACT" 

AS
   PROCEDURE RC_SUP_DEM_INITIAL_PAGE_LOAD (
      i_user_id                       IN     VARCHAR2,
      i_min                           IN     NUMBER,
      i_max                           IN     NUMBER,
      i_productName                   IN     CLOB,
      i_revenueBand                   IN     VARCHAR2,
      i_aspBand                       IN     VARCHAR2,
      i_mosBand                       IN     VARCHAR2,
      i_eos                           IN     VARCHAR2,
      i_sort_column_name              IN     VARCHAR2,
      i_sort_column_by                IN     VARCHAR2,
      i_filter_column_name            IN     VARCHAR2,
      i_filter_user_input             IN     VARCHAR2,
      i_filter_list                   IN     CRPSC.RC_NEW_FILTER_LIST,
      o_sup_dem_report_details_list      OUT CRPREP.RC_SUPPLY_DEMAND_REPORT_LIST,
      o_record_count                     OUT NUMBER,
      o_status                           OUT NUMBER,
      o_notificationMsg                  OUT VARCHAR2,
      o_current_year                     OUT VARCHAR2)
   AS
      lv_sup_dem_report_details_list   CRPREP.RC_SUPPLY_DEMAND_REPORT_LIST;
      lv_query                         CLOB;
      lv_main_query                    CLOB;
      lv_row_clause                    CLOB;
      lv_row_filter_clause             CLOB;
      lv_row_count                     CLOB;
      lv_sort_column_name              VARCHAR2 (30);
      lv_sort_column_by                VARCHAR2 (10);
      lv_filter_list                   CRPSC.RC_NEW_FILTER_LIST;
      lv_sort_query                    CLOB;
      lv_max_row                       NUMBER;
      lv_min_row                       NUMBER;
      lv_idx                           NUMBER;
      lv_cur_part_number               CLOB;
      lv_i_part_number                 CLOB;
      lv_productName                   CLOB;
      lv_revenueBand                   VARCHAR2 (50 BYTE);
      lv_aspBand                       VARCHAR2 (50 BYTE);
      lv_mosBand                       VARCHAR2 (50 BYTE);
      lv_eos                           VARCHAR2 (50 BYTE);
      lv_record_count                  NUMBER;
      lv_msg                           VARCHAR2 (200 BYTE);
      lv_table_name                    VARCHAR2 (50);
      lv_filter_query                  CLOB;
      lv_filter_column_name            VARCHAR2 (50 BYTE);
      lv_filter_user_input             VARCHAR2 (500 BYTE);
      v_fiscal_year                    VARCHAR2 (200);
   BEGIN
      lv_max_row := i_max;
      lv_min_row := i_min;
      lv_productName := i_productName;
      lv_revenueBand := i_revenueBand;
      lv_sort_column_name := UPPER (TRIM (i_sort_column_name));
      lv_sort_column_by := UPPER (TRIM (i_sort_column_by));
      lv_aspBand := i_aspBand;
      lv_mosBand := i_mosBand;
      lv_eos := i_eos;
      lv_filter_list := i_filter_list;
      lv_sup_dem_report_details_list := RC_SUPPLY_DEMAND_REPORT_LIST ();
      lv_table_name := 'RC_SCRAP_REPORT';
      lv_filter_column_name := UPPER (TRIM (i_filter_column_name));
      lv_filter_user_input := UPPER (TRIM (i_filter_user_input));
      lv_row_filter_clause := ' ';



      lv_main_query := ' SELECT * FROM( SELECT AB.*,
  ROWNUM rnum FROM ( SELECT 
          PRODUCT_NAME,
  BL_CATEGORY,
  DGI,
  NIB,
  WIP,
  FG,
  CONS,
  OTHER,
  PERCENTAGE_CONS_OTHER,
  TOTAL_UNITS,
  PREV2_SALES_UNITS,
  PREV2_SALES_REVENUE,
  PREV_FISCAL_YEAR_SALES_UNITS,
  CUR_FISCAL_YEAR_SALES_UNITS,
  PREV_FISCAL_YEAR_SALES_REVENUE,
  CUR_FISCAL_YEAR_SALES_REVENUE,
  CUR_FISCAL_YEAR_REVENUE_BANDS,
  RF_SALES_12M,
  EXCESS_SALES_12M,
  OUTLET_SALES_12M,
  RF_SALES_3M,
  EXCESS_SALES_3M,
  TOTAL_SALES_3M,
  SALES_TO_MAX_12M,
  FG_PERCENT_TO_MAX,
  SALES_TO_QOH,
  ASP,
  ASP_RF,
  ASP_WS,
  ASP_BANDS,
  IN_TRANSIT_INVENTORY_TO_POE,
   FCS,
  AGE,
  POE_MAX,
  FOUR_POE_MAX,
  MOS,
  MOS_BANDS,
  PRODUCT_FAMILY,
  PRODUCT_LIFE_CYCLE,
  PID_CREATION_DATE,
  MFG_EOS_DATE,
  MFG_EOL_DATE,
  EXCESS,
  EXCESS_DGI,
  EXCESS_NIB,
  EXCESS_FG,
  ADDITIONAL_EXCESS,
  REMAINING_QUANTITY,
  SCRAP_NOTES,
  STD_MATERIAL_COST,
  GPL,
  OCT_ACCUMULATED_6M,
  QUOTES,
  BACKLOG,
  SHORTAGE,
  REFRESH_YIELD,
  GLOBAL_REFRESH_METHOD,
  PRIORITY,
  PERIODIC_SCRAP,
  total_available_to_reserve,
  global_refresh_method_ws,
  nettable_dgi_qty,
  nettable_fgi_qty,
  total_nettable_inventory,
  nettable_mos,
  OUTLET_SALES_3M
          FROM CRPREP.RC_SCRAP_REPORT ';

      lv_row_clause :=
            ' ) AB ) ABC WHERE ABC.rnum <= '
         || lv_max_row
         || ' AND ABC.rnum > '
         || lv_min_row;

      lv_row_count :=
         'SELECT COUNT(*) FROM RC_SCRAP_REPORT';


      lv_row_filter_clause := 'WHERE 1=1 ';


      IF (   (TO_CHAR (lv_productName) IS NOT NULL)
          OR (lv_revenueBand IS NOT NULL AND lv_revenueBand <> 'ALL')
          OR (lv_aspBand IS NOT NULL AND lv_aspBand <> 'ALL')
          OR (lv_mosBand IS NOT NULL AND lv_mosBand <> 'ALL')
          OR (lv_eos IS NOT NULL AND lv_eos <> 'ALL'))
      THEN
         -- lv_row_filter_clause := '';

         IF (lv_productName IS NOT NULL)
         THEN
            lv_row_filter_clause := lv_row_filter_clause || ' AND (';
            lv_i_part_number := lv_productName;
            lv_idx := INSTR (lv_i_part_number, ',');

            IF lv_idx = 0
            THEN
               lv_i_part_number := REPLACE (lv_i_part_number, '*', '');
               lv_row_filter_clause :=
                     lv_row_filter_clause
                  || '(UPPER(PRODUCT_NAME) = UPPER('''
                  || lv_i_part_number
                  || ''') OR UPPER(RETAIL_PART_NUMBER) = UPPER('''
                  || lv_i_part_number
                  || ''') OR UPPER(EXCESS_PART_NUMBER) = UPPER('''
                  || lv_i_part_number
                  || ''') OR UPPER(XREF_PART_NUMBER) = UPPER('''
                  || lv_i_part_number
                  || '''))';
            ELSE
               lv_cur_part_number :=
                  SUBSTR (lv_i_part_number,
                          1,
                          INSTR (lv_i_part_number, ',') - 1);
               lv_cur_part_number := REPLACE (lv_cur_part_number, '*', '');

               lv_row_filter_clause :=
                     lv_row_filter_clause
                  || '(UPPER(PRODUCT_NAME) = UPPER('''
                  || lv_cur_part_number
                  || ''') OR UPPER(RETAIL_PART_NUMBER) = UPPER('''
                  || lv_cur_part_number
                  || ''') OR UPPER(EXCESS_PART_NUMBER) = UPPER('''
                  || lv_cur_part_number
                  || ''') OR UPPER(XREF_PART_NUMBER) = UPPER('''
                  || lv_cur_part_number
                  || '''))';
               lv_i_part_number :=
                  SUBSTR (lv_i_part_number, lv_idx + LENGTH (','));
            END IF;


            IF lv_idx > 0
            THEN
               LOOP
                  lv_idx := INSTR (lv_i_part_number, ',');

                  IF lv_idx > 0
                  THEN
                     lv_cur_part_number :=
                        SUBSTR (lv_i_part_number,
                                1,
                                INSTR (lv_i_part_number, ',') - 1);

                     lv_i_part_number :=
                        SUBSTR (lv_i_part_number, lv_idx + LENGTH (','));
                     lv_cur_part_number :=
                        REPLACE (lv_cur_part_number, '*', '');
                     lv_row_filter_clause :=
                           lv_row_filter_clause
                        || ' OR (UPPER(PRODUCT_NAME) = UPPER('''
                        || lv_cur_part_number
                        || ''') OR UPPER(RETAIL_PART_NUMBER) = UPPER('''
                        || lv_cur_part_number
                        || ''') OR UPPER(EXCESS_PART_NUMBER) = UPPER('''
                        || lv_cur_part_number
                        || ''') OR UPPER(XREF_PART_NUMBER) = UPPER('''
                        || lv_cur_part_number
                        || '''))';
                  ELSE
                     lv_i_part_number := REPLACE (lv_i_part_number, '*', '');
                     lv_row_filter_clause :=
                           lv_row_filter_clause
                        || ' OR (UPPER(PRODUCT_NAME) = UPPER('''
                        || lv_i_part_number
                        || ''') OR UPPER(RETAIL_PART_NUMBER) = UPPER('''
                        || lv_i_part_number
                        || ''') OR UPPER(EXCESS_PART_NUMBER) = UPPER('''
                        || lv_i_part_number
                        || ''') OR UPPER(XREF_PART_NUMBER) = UPPER('''
                        || lv_i_part_number
                        || '''))';
                     EXIT;
                  END IF;
               END LOOP;
            END IF;

            lv_row_filter_clause := lv_row_filter_clause || ')';
         END IF;

         IF (lv_revenueBand IS NOT NULL AND lv_revenueBand <> 'ALL')
         THEN
            lv_row_filter_clause :=
                  lv_row_filter_clause
               || ' AND UPPER(CUR_FISCAL_YEAR_REVENUE_BANDS) = '
               || 'UPPER('''
               || lv_revenueBand
               || ''')';
         END IF;

         IF (lv_aspBand IS NOT NULL AND lv_aspBand <> 'ALL')
         THEN
            lv_row_filter_clause :=
                  lv_row_filter_clause
               || ' AND UPPER(ASP_BANDS) = '
               || 'UPPER('''
               || lv_aspBand
               || ''')';
         END IF;

         IF (lv_mosBand IS NOT NULL AND lv_mosBand <> 'ALL')
         THEN
            lv_row_filter_clause :=
                  lv_row_filter_clause
               || ' AND UPPER(MOS_BANDS) = '
               || 'UPPER('''
               || lv_mosBand
               || ''')';
         END IF;

         IF (lv_eos IS NOT NULL AND lv_eos <> 'ALL')
         THEN
            IF (lv_eos = 'PAST_EOS')
            THEN
               lv_row_filter_clause :=
                  lv_row_filter_clause || 'AND MFG_EOS_DATE  < SYSDATE ';
            ELSE
               lv_row_filter_clause :=
                     lv_row_filter_clause
                  || 'AND MFG_EOS_DATE  >= Sysdate and MFG_EOS_DATE  <= ADD_MONTHS (SYSDATE, 4)';
            END IF;
         END IF;
      END IF;

      --To implement sorting
      IF (    (    lv_sort_column_name IS NOT NULL
               AND lv_sort_column_by IS NOT NULL)
          AND (lv_sort_column_name <> ' ' AND lv_sort_column_by <> ' ')
          AND (    UPPER (lv_sort_column_name) NOT LIKE 'NULL'
               AND UPPER (lv_sort_column_by) NOT LIKE 'NULL'))
      THEN
         lv_sort_query :=
            lv_sort_column_name || ' ' || lv_sort_column_by || ' NULLS LAST ';
      ELSE
         lv_sort_query := ' PRODUCT_NAME ASC ';
      END IF;



      /* Column Filters */
      IF (lv_filter_list IS NOT EMPTY)
      THEN
         RMKTGADM.RC_3A4_DATA_EXTRACT.GET_FILTERS_IN_QUERY (lv_filter_list,
                                                            lv_table_name,
                                                            lv_filter_query);
         lv_row_filter_clause :=
            lv_row_filter_clause || ' ' || lv_filter_query;
      END IF;



      --  For Column Level Filtering based on the user input
      IF     lv_filter_column_name IS NOT NULL
         AND lv_filter_user_input IS NOT NULL
      THEN
         lv_row_filter_clause :=
               lv_row_filter_clause
            || ' AND (UPPER(TRIM('
            || lv_filter_column_name
            || ')) LIKE (UPPER(TRIM(''%'
            || lv_filter_user_input
            || '%''))))';
      END IF;



      lv_row_count :=
         'SELECT COUNT(*) FROM RC_SCRAP_REPORT ' || lv_row_filter_clause;



      EXECUTE IMMEDIATE lv_row_count INTO lv_record_count;

      lv_main_query :=
         lv_main_query || lv_row_filter_clause || lv_row_clause;



      --      lv_main_query :=
      --            lv_main_query
      --         || lv_row_filter_clause
      --         || ' ORDER BY PRODUCT_NAME ASC'
      --         || lv_row_clause;
      --
      --
      --
      --      lv_row_count := lv_row_count || lv_row_filter_clause;

      lv_query :=
         'SELECT RC_SUPPLY_DEMAND_REPORT_OBJ (
                PRODUCT_NAME,
  BL_CATEGORY,
  DGI,
  NIB,
  WIP,
  FG,
  CONS,
  OTHER,
  PERCENTAGE_CONS_OTHER,
  TOTAL_UNITS,
  PREV2_SALES_UNITS,
  PREV2_SALES_REVENUE,
  PREV_FISCAL_YEAR_SALES_UNITS,
  CUR_FISCAL_YEAR_SALES_UNITS,
  PREV_FISCAL_YEAR_SALES_REVENUE,
  CUR_FISCAL_YEAR_SALES_REVENUE,
  CUR_FISCAL_YEAR_REVENUE_BANDS,
  RF_SALES_12M,
  EXCESS_SALES_12M,
  OUTLET_SALES_12M,
  RF_SALES_3M,
  EXCESS_SALES_3M,
  TOTAL_SALES_3M,
  SALES_TO_MAX_12M,
  FG_PERCENT_TO_MAX,
  SALES_TO_QOH,
  ASP,
  ASP_RF,
  ASP_WS,
  ASP_BANDS,
  IN_TRANSIT_INVENTORY_TO_POE,
  FCS,
  AGE,
  POE_MAX,
  FOUR_POE_MAX,
  MOS,
  MOS_BANDS,
  PRODUCT_FAMILY,
  PRODUCT_LIFE_CYCLE,
  PID_CREATION_DATE,
  MFG_EOS_DATE,
  MFG_EOL_DATE,
  EXCESS,
  EXCESS_DGI,
  EXCESS_NIB,
  EXCESS_FG,
  ADDITIONAL_EXCESS,
  REMAINING_QUANTITY,
  SCRAP_NOTES,
  STD_MATERIAL_COST,
  GPL,
  OCT_ACCUMULATED_6M,
  QUOTES,
  BACKLOG,
  SHORTAGE,
  REFRESH_YIELD,
  GLOBAL_REFRESH_METHOD,
  PRIORITY,
  PERIODIC_SCRAP,
  total_available_to_reserve,
  global_refresh_method_ws,
  nettable_dgi_qty,
  nettable_fgi_qty,
  total_nettable_inventory,
  nettable_mos  ,
  OUTLET_SALES_3M
  )
        FROM ( ' || lv_main_query || ' ) ';

      lv_query :=
         lv_query || ' order by ' || lv_sort_query;



      BEGIN
         EXECUTE IMMEDIATE lv_query
            BULK COLLECT INTO lv_sup_dem_report_details_list;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_sup_dem_report_details_list := RC_SUPPLY_DEMAND_REPORT_LIST ();
      END;

      SELECT TO_CHAR (MAX (PROCESS_TIMESTAMP), 'mm/dd/yyyy hh:mi:ss AM')
        INTO lv_msg
        FROM CRPADM.RC_PROCESS_LOG
       WHERE     PROCESS_NAME = 'CRPREP.RC_SUPPLY_DEMAND_REPORT'
             AND PROCESS_STATUS = 'END';

      SELECT FISCAL_YEAR_NUMBER
        INTO v_fiscal_year
        FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
       WHERE calendar_date = TRUNC (SYSDATE);

      o_notificationMsg :=
         'Supply Demand Report was generated on ' || lv_msg;
      o_record_count := lv_record_count;
      o_sup_dem_report_details_list := lv_sup_dem_report_details_list;
      o_current_year := v_fiscal_year;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_status := 0;
         g_error_msg :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         -- Logging exception
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
            g_error_msg,
            NULL,
            'RC_SUPPLY_DEMAND_DATA_EXTRACT.RC_SUP_DEM_INITIAL_PAGE_LOAD',
            'PROCEDURE',
            i_user_id,
            'N');
   END RC_SUP_DEM_INITIAL_PAGE_LOAD;

   PROCEDURE RC_SUP_DEM_FILTER_VALUE (
      i_user_id             IN     VARCHAR2,
      o_revenue_band_list      OUT CRPREP.RC_NORMALISED_VARCHAR_LIST,
      o_asp_band_list          OUT CRPREP.RC_NORMALISED_VARCHAR_LIST,
      o_mos_band_list          OUT CRPREP.RC_NORMALISED_VARCHAR_LIST,
      o_current_year           OUT VARCHAR2)
   AS
      lv_revenue_band_list   CRPREP.RC_NORMALISED_VARCHAR_LIST;
      lv_asp_band_list       CRPREP.RC_NORMALISED_VARCHAR_LIST;
      lv_mos_band_list       CRPREP.RC_NORMALISED_VARCHAR_LIST;
      v_fiscal_year          VARCHAR2 (200);
   BEGIN
      lv_revenue_band_list := RC_NORMALISED_VARCHAR_LIST ();
      lv_asp_band_list := RC_NORMALISED_VARCHAR_LIST ();
      lv_mos_band_list := RC_NORMALISED_VARCHAR_LIST ();

        SELECT DISTINCT CUR_FISCAL_YEAR_REVENUE_BANDS
          BULK COLLECT INTO lv_revenue_band_list
          FROM RC_SCRAP_REPORT
         WHERE CUR_FISCAL_YEAR_REVENUE_BANDS IS NOT NULL
      ORDER BY CUR_FISCAL_YEAR_REVENUE_BANDS;

        SELECT DISTINCT ASP_BANDS
          BULK COLLECT INTO lv_asp_band_list
          FROM RC_SCRAP_REPORT
         WHERE ASP_BANDS IS NOT NULL
      ORDER BY ASP_BANDS;

        SELECT DISTINCT MOS_BANDS
          BULK COLLECT INTO lv_mos_band_list
          FROM RC_SCRAP_REPORT
         WHERE MOS_BANDS IS NOT NULL
      ORDER BY MOS_BANDS;

      SELECT FISCAL_YEAR_NUMBER
        INTO v_fiscal_year
        FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
       WHERE calendar_date = TRUNC (SYSDATE);

      o_revenue_band_list := lv_revenue_band_list;
      o_asp_band_list := lv_asp_band_list;
      o_mos_band_list := lv_mos_band_list;
      o_current_year := v_fiscal_year;
   EXCEPTION
      WHEN OTHERS
      THEN
         g_error_msg :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         -- Logging exception
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
            g_error_msg,
            NULL,
            'RC_SUPPLY_DEMAND_DATA_EXTRACT.RC_SUP_DEM_FILTER_VALUE',
            'PROCEDURE',
            i_user_id,
            'N');
   END RC_SUP_DEM_FILTER_VALUE;

   PROCEDURE GET_UNIQUE_FILTERS (
      i_productName          IN     CLOB,
      i_revenueBand          IN     VARCHAR2,
      i_aspBand              IN     VARCHAR2,
      i_mosBand              IN     VARCHAR2,
      i_eos                  IN     VARCHAR2,
      i_filter_column_name   IN     VARCHAR2,
      i_filter_user_input    IN     VARCHAR2,
      i_filter_list          IN     CRPSC.RC_NEW_FILTER_LIST,
      o_unique_value            OUT T_NORMALISED_LIST)
   IS
      lv_filter_list          CRPSC.RC_NEW_FILTER_LIST;
      lv_query                CLOB;
      lv_filter_query         CLOB;
      lv_filter_column_name   VARCHAR2 (50 BYTE);
      lv_filter_user_input    VARCHAR2 (500 BYTE);
      lv_productName          CLOB;
      lv_revenueBand          VARCHAR2 (50 BYTE);
      lv_aspBand              VARCHAR2 (50 BYTE);
      lv_mosBand              VARCHAR2 (50 BYTE);
      lv_eos                  VARCHAR2 (50 BYTE);
      lv_row_filter_clause    CLOB;
      lv_i_part_number        CLOB;
      lv_idx                  NUMBER;
      lv_cur_part_number      CLOB;
   BEGIN
      lv_filter_list := i_filter_list;
      lv_filter_column_name := UPPER (TRIM (i_filter_column_name));
      lv_filter_user_input := UPPER (TRIM (i_filter_user_input));
      lv_productName := i_productName;
      lv_revenueBand := i_revenueBand;
      lv_aspBand := i_aspBand;
      lv_mosBand := i_mosBand;
      lv_eos := i_eos;



      lv_row_filter_clause := '';

      IF (   (TO_CHAR (lv_productName) IS NOT NULL)
          OR (lv_revenueBand IS NOT NULL AND lv_revenueBand <> 'ALL')
          OR (lv_aspBand IS NOT NULL AND lv_aspBand <> 'ALL')
          OR (lv_mosBand IS NOT NULL AND lv_mosBand <> 'ALL')
          OR (lv_eos IS NOT NULL AND lv_eos <> 'ALL'))
      THEN
         lv_row_filter_clause := '';



         IF (TO_CHAR (lv_productName) IS NOT NULL)
         THEN
            lv_row_filter_clause := lv_row_filter_clause || ' AND (';
            lv_i_part_number := lv_productName;
            lv_idx := INSTR (lv_i_part_number, ',');

            IF lv_idx = 0
            THEN
               lv_i_part_number := REPLACE (lv_i_part_number, '*', '');
               lv_row_filter_clause :=
                     lv_row_filter_clause
                  || '(UPPER(PRODUCT_NAME) = UPPER('''
                  || lv_i_part_number
                  || ''') OR UPPER(RETAIL_PART_NUMBER) = UPPER('''
                  || lv_i_part_number
                  || ''') OR UPPER(EXCESS_PART_NUMBER) = UPPER('''
                  || lv_i_part_number
                  || ''') OR UPPER(XREF_PART_NUMBER) = UPPER('''
                  || lv_i_part_number
                  || '''))';
            ELSE
               lv_cur_part_number :=
                  SUBSTR (lv_i_part_number,
                          1,
                          INSTR (lv_i_part_number, ',') - 1);
               lv_cur_part_number := REPLACE (lv_cur_part_number, '*', '');

               lv_row_filter_clause :=
                     lv_row_filter_clause
                  || '(UPPER(PRODUCT_NAME) = UPPER('''
                  || lv_cur_part_number
                  || ''') OR UPPER(RETAIL_PART_NUMBER) = UPPER('''
                  || lv_cur_part_number
                  || ''') OR UPPER(EXCESS_PART_NUMBER) = UPPER('''
                  || lv_cur_part_number
                  || ''') OR UPPER(XREF_PART_NUMBER) = UPPER('''
                  || lv_cur_part_number
                  || '''))';
               lv_i_part_number :=
                  SUBSTR (lv_i_part_number, lv_idx + LENGTH (','));
            END IF;


            IF lv_idx > 0
            THEN
               LOOP
                  lv_idx := INSTR (lv_i_part_number, ',');

                  IF lv_idx > 0
                  THEN
                     lv_cur_part_number :=
                        SUBSTR (lv_i_part_number,
                                1,
                                INSTR (lv_i_part_number, ',') - 1);

                     lv_i_part_number :=
                        SUBSTR (lv_i_part_number, lv_idx + LENGTH (','));
                     lv_cur_part_number :=
                        REPLACE (lv_cur_part_number, '*', '');
                     lv_row_filter_clause :=
                           lv_row_filter_clause
                        || ' OR (UPPER(PRODUCT_NAME) = UPPER('''
                        || lv_cur_part_number
                        || ''') OR UPPER(RETAIL_PART_NUMBER) = UPPER('''
                        || lv_cur_part_number
                        || ''') OR UPPER(EXCESS_PART_NUMBER) = UPPER('''
                        || lv_cur_part_number
                        || ''') OR UPPER(XREF_PART_NUMBER) = UPPER('''
                        || lv_cur_part_number
                        || '''))';
                  ELSE
                     lv_i_part_number := REPLACE (lv_i_part_number, '*', '');
                     lv_row_filter_clause :=
                           lv_row_filter_clause
                        || ' OR (UPPER(PRODUCT_NAME) = UPPER('''
                        || lv_i_part_number
                        || ''') OR UPPER(RETAIL_PART_NUMBER) = UPPER('''
                        || lv_i_part_number
                        || ''') OR UPPER(EXCESS_PART_NUMBER) = UPPER('''
                        || lv_i_part_number
                        || ''') OR UPPER(XREF_PART_NUMBER) = UPPER('''
                        || lv_i_part_number
                        || '''))';
                     EXIT;
                  END IF;
               END LOOP;
            END IF;

            lv_row_filter_clause := lv_row_filter_clause || ')';
         END IF;

         IF (lv_revenueBand IS NOT NULL AND lv_revenueBand <> 'ALL')
         THEN
            lv_row_filter_clause :=
                  lv_row_filter_clause
               || ' AND UPPER(CUR_FISCAL_YEAR_REVENUE_BANDS) = '
               || 'UPPER('''
               || lv_revenueBand
               || ''')';
         END IF;

         IF (lv_aspBand IS NOT NULL AND lv_aspBand <> 'ALL')
         THEN
            lv_row_filter_clause :=
                  lv_row_filter_clause
               || ' AND UPPER(ASP_BANDS) = '
               || 'UPPER('''
               || lv_aspBand
               || ''')';
         END IF;

         IF (lv_mosBand IS NOT NULL AND lv_mosBand <> 'ALL')
         THEN
            lv_row_filter_clause :=
                  lv_row_filter_clause
               || ' AND UPPER(MOS_BANDS) = '
               || 'UPPER('''
               || lv_mosBand
               || ''')';
         END IF;

         IF (lv_eos IS NOT NULL AND lv_eos <> 'ALL')
         THEN
            IF (lv_eos = 'PAST_EOS')
            THEN
               lv_row_filter_clause :=
                  lv_row_filter_clause || 'AND MFG_EOS_DATE  < SYSDATE ';
            ELSE
               lv_row_filter_clause :=
                     lv_row_filter_clause
                  || 'AND MFG_EOS_DATE  >= Sysdate and MFG_EOS_DATE  <= ADD_MONTHS (SYSDATE, 4)';
            END IF;
         END IF;
      END IF;



      lv_query :=
            'SELECT DISTINCT UPPER('
         || lv_filter_column_name
         || ') '
         || lv_filter_column_name
         || ' FROM RC_SCRAP_REPORT where 1=1';

      IF lv_row_filter_clause IS NOT NULL
      THEN
         lv_query := lv_query || ' ' || lv_row_filter_clause;
      END IF;


      -- For Column Level Filtering based on the user input
      IF     lv_filter_column_name IS NOT NULL
         AND lv_filter_user_input IS NOT NULL
      THEN
         lv_query :=
               lv_query
            || ' and (UPPER(TRIM('
            || lv_filter_column_name
            || ')) LIKE (UPPER(TRIM(''%'
            || lv_filter_user_input
            || '%''))))';
      END IF;

      IF (lv_filter_list IS NOT NULL OR lv_filter_user_input IS NOT NULL)
      THEN
         IF (lv_filter_list IS NOT NULL)
         THEN
            RMKTGADM.RC_3A4_DATA_EXTRACT.GET_FILTERS_IN_QUERY (
               lv_filter_list,
               'RC_SCRAP_REPORT',
               lv_filter_query);
            lv_query := lv_query || ' ' || lv_filter_query;
         END IF;
      END IF;



      -- lv_query := lv_query || ' ' || lv_row_filter_clause;
      lv_query :=
            lv_query
         || ' ORDER BY '
         || i_filter_column_name
         || ' ASC NULLS FIRST';



      EXECUTE IMMEDIATE lv_query BULK COLLECT INTO o_unique_value;
   EXCEPTION
      WHEN OTHERS
      THEN
         g_error_msg :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12);
         -- Logging exception
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
            g_error_msg,
            NULL,
            'RC_SUPPLY_DEMAND_DATA_EXTRACT.GET_UNIQUE_FILTERS',
            'PROCEDURE',
            NULL,
            'Y');
   END GET_UNIQUE_FILTERS;
END RC_SUPPLY_DEMAND_DATA_EXTRACT;
/