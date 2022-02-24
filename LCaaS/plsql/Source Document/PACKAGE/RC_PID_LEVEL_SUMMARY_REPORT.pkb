CREATE OR REPLACE PACKAGE BODY CRPREP./*AppDB: 1044578*/
                                                                                                                                           "RC_PID_LEVEL_SUMMARY_REPORT"
AS
    /*****************************************************************************************************************
        || Object Name    : RC_PID_LEVEL_SUMMARY_REPORT
       || Modules        : PID LEVEL SUMMARY REPORT
       || Description    :  PID LEVEL SUMMARY REPORT GENERATION
        ||------------------------------------------------------------------------------------------------------------
        ||Date                  By                 Version         Comments
        ||------------------------------------------------------------------------------------------------------------
        ||12-aug-2019    sidbhumi         1.0          Initial creation
        ||------------------------------------------------------------------------------------------------------------
    *****************************************************************************************************************/
    PROCEDURE RC_PLS_REPORT_FETCH (
        i_user_id                       IN     VARCHAR2,
        i_user_role                     IN     VARCHAR2,
        i_min                           IN     NUMBER,
        i_max                           IN     NUMBER,
        i_sort_column_name              IN     VARCHAR2,
        i_sort_column_by                IN     VARCHAR2,
        i_filter_column_name            IN     VARCHAR2,
        i_filter_user_input             IN     VARCHAR2,
        i_filter_list                   IN     CRPSC.RC_NEW_FILTER_LIST,
        i_repair_site_filter            IN     VARCHAR2,
        i_fiscal_year_filter            IN     VARCHAR2,
        i_quarter_filter                IN     VARCHAR2,
        i_month_filter                  IN     VARCHAR2,
        i_week_filter                   IN     VARCHAR2,
        o_pid_level_summary_data_list      OUT CRPREP.RC_PID_LEVEL_SUMMARY_LIST,
        o_record_count                     OUT NUMBER,
        o_status                           OUT NUMBER,
        o_notificationMsg                  OUT VARCHAR2)
    AS
        lv_pls_data_list        CRPREP.RC_PID_LEVEL_SUMMARY_LIST;
        lv_record_count         NUMBER;
        lv_query                CLOB;
        lv_main_query           CLOB;
        lv_row_clause           CLOB;
        lv_row_filter_clause    CLOB;
        lv_count_query          CLOB;
        LV_REPAIR_SITE_CLAUSE   CLOB;
        lv_sort_column_name     VARCHAR2 (30);
        lv_sort_column_by       VARCHAR2 (10);
        lv_sort_query           CLOB;
        lv_table_name           VARCHAR2 (50);
        lv_filter_list          crpsc.rc_new_filter_list;
        lv_filter_query         CLOB;
        lv_max_row              NUMBER;
        lv_min_row              NUMBER;
        lv_msg                  VARCHAR2 (200 BYTE);
        lv_filter_column_name   VARCHAR2 (50 BYTE);
        lv_filter_user_input    VARCHAR2 (500 BYTE);
        lv_repair_site_filter   VARCHAR2 (500 BYTE);
        lv_fiscal_year_filter   VARCHAR2 (500);
        lv_quarter_filter       VARCHAR2 (500 BYTE);
        lv_month_filter         VARCHAR2 (500 BYTE);
        lv_week_filter          VARCHAR2 (500);
        lv_ZCODE_list           T_NORMALISED_LIST;
        lv_idx                  NUMBER;
        lv_cur_deal_id          CLOB;
        lv_i_deal_id            CLOB;
        --      lv_deal_id_filter       CLOB;
        lv_repair_partner_id    NUMBER;
        lv_in_query             CLOB;
        lv_user_role            VARCHAR2 (30);
        lv_user_id              VARCHAR2 (30);
        lv_quote_data_list      CRPREP.RC_PID_LEVEL_SUMMARY_LIST;
    BEGIN
        lv_max_row := i_max;
        lv_min_row := i_min;
        lv_quote_data_list := CRPREP.RC_PID_LEVEL_SUMMARY_LIST ();
        lv_sort_column_name := UPPER (TRIM (i_sort_column_name));
        lv_sort_column_by := UPPER (TRIM (i_sort_column_by));
        lv_filter_column_name := UPPER (TRIM (i_filter_column_name));
        lv_filter_user_input := UPPER (TRIM (i_filter_user_input));
        lv_repair_site_filter := i_repair_site_filter;
        lv_fiscal_year_filter := i_fiscal_year_filter;
        lv_quarter_filter := i_quarter_filter;
        lv_month_filter := i_month_filter;
        lv_week_filter := i_week_filter;
        lv_table_name := 'RC_PID_LEVEL_SUMMARY';
        lv_filter_list := i_filter_list;
        lv_user_id := i_user_id;
        lv_user_role := i_user_role;
        lv_ZCODE_list := T_NORMALISED_LIST ();


        --      lv_table_name := 'RMK_CCW_QUOTE_V';
        --      lv_filter_list := i_filter_list;
        --      lv_deal_id_filter := NULL;
        o_status := 1;
        
        IF (    (    lv_sort_column_name IS NOT NULL
                 AND lv_sort_column_by IS NOT NULL)
            AND (lv_sort_column_name <> ' ' AND lv_sort_column_by <> ' ')
            AND (    UPPER (lv_sort_column_name) NOT LIKE 'NULL'
                 AND UPPER (lv_sort_column_by) NOT LIKE 'NULL'))
        THEN
            lv_sort_query :=
                   lv_sort_column_name
                || ' '
                || lv_sort_column_by
                || ' NULLS LAST ';
        ELSE
            lv_sort_query := ' REFRESH_PID ASC ';
        END IF;

        -- Included Quote_Expiry_date, Reservation_Expiry_Date filter in addition to Existing filter, as part of user story US135214.Sprint16(4Nov17)
        -- -90 is added in line 125 and filter procedure also
        lv_main_query :=
               ' SELECT PLS.*, ROW_NUMBER ()
                        OVER (ORDER BY '
            || lv_sort_query
            || ' ) RNUM FROM (SELECT REPAIR_SITE,
       FISCAL_YEAR,
       QUARTER,
       MONTH,
       WEEK,
       WEEKEND_DATE,
       COST_TYPE,
       SUB_REFURB_TYPE,
       REFRESH_PID,
       QTY,
       UNIT_PRICE,
       TOTAL_COST,
       SERIAL_NUMBER,
       ECO_NUMBER,
       STATUS
  FROM RC_PID_LEVEL_SUMMARY';


        --      lv_main_query := '';


        LV_ROW_FILTER_CLAUSE := ' WHERE 1=1 ';

        IF (    lv_repair_site_filter IS NOT NULL
            AND lv_repair_site_filter <> 'ALL')
        THEN
            LV_ROW_FILTER_CLAUSE :=
                   LV_ROW_FILTER_CLAUSE
                || ' AND ( REPAIR_SITE = '''
                || lv_repair_site_filter
                || ''')';
        END IF;


        IF (lv_user_role = 'RP')
        THEN
            SELECT DISTINCT NVL (ZCODE, 'NA')
              BULK COLLECT INTO lv_ZCODE_list
              FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER  RP
                   JOIN CRPADM.rc_repair_partner_user_map MAP
                       ON RP.REPAIR_PARTNER_ID = MAP.REPAIR_PARTNER_ID
             WHERE     MAP.USER_NAME = lv_user_id
             AND ZCODE <> 'Z32'
                   AND RP.ACTIVE_FLAG = 'Y'
                   AND MAP.ACTIVE_FLAG = 'Y';
        END IF;

        LV_REPAIR_SITE_CLAUSE := ' ';

        IF (lv_ZCODE_list.COUNT () > 0)
        THEN
            LV_REPAIR_SITE_CLAUSE :=
                LV_REPAIR_SITE_CLAUSE || ' AND REPAIR_SITE IN(';

            FOR I IN 1 .. lv_ZCODE_list.COUNT ()
            LOOP
                EXIT WHEN I IS NULL;
                LV_REPAIR_SITE_CLAUSE :=
                       LV_REPAIR_SITE_CLAUSE
                    || ''''
                    || lv_ZCODE_list (I)
                    || '''';

                IF (I < lv_ZCODE_list.COUNT ())
                THEN
                    LV_REPAIR_SITE_CLAUSE := LV_REPAIR_SITE_CLAUSE || ',';
                END IF;
            END LOOP;

            LV_REPAIR_SITE_CLAUSE := LV_REPAIR_SITE_CLAUSE || ')';
        END IF;

        LV_ROW_FILTER_CLAUSE := LV_ROW_FILTER_CLAUSE || LV_REPAIR_SITE_CLAUSE;


        IF (lv_fiscal_year_filter IS NOT NULL --          AND lv_fiscal_year_filter <> 'ALL'
                                             )
        THEN
            LV_ROW_FILTER_CLAUSE :=
                   LV_ROW_FILTER_CLAUSE
                || ' AND ( FISCAL_YEAR = '''
                || lv_fiscal_year_filter
                || ''')';
        END IF;


        IF (lv_quarter_filter IS NOT NULL AND lv_quarter_filter <> 'ALL')
        THEN
            LV_ROW_FILTER_CLAUSE :=
                   LV_ROW_FILTER_CLAUSE
                || ' AND ( QUARTER = '''
                || lv_quarter_filter
                || ''')';
        END IF;


        IF (lv_month_filter IS NOT NULL AND lv_month_filter <> 'ALL')
        THEN
            LV_ROW_FILTER_CLAUSE :=
                   LV_ROW_FILTER_CLAUSE
                || ' AND ( MONTH = '''
                || lv_month_filter
                || ''')';
        END IF;


        IF (lv_week_filter IS NOT NULL AND TO_CHAR (lv_week_filter) <> 'ALL')
        THEN
            LV_ROW_FILTER_CLAUSE :=
                   LV_ROW_FILTER_CLAUSE
                || ' AND ( WEEK = '''
                || lv_week_filter
                || ''')';
        END IF;


        -- For Column Level Filtering based on the user input
        IF     lv_filter_column_name IS NOT NULL
           AND lv_filter_user_input IS NOT NULL
        THEN
            LV_ROW_FILTER_CLAUSE :=
                   LV_ROW_FILTER_CLAUSE
                || ' AND (UPPER(TRIM('
                || lv_filter_column_name
                || ')) LIKE (UPPER(TRIM(''%'
                || lv_filter_user_input
                || '%''))))';
        END IF;

        /* Column Filters */
        IF (lv_filter_list IS NOT EMPTY)
        THEN
            get_filters_in_query (lv_filter_list,
                                  lv_table_name,
                                  lv_filter_query);

            LV_ROW_FILTER_CLAUSE :=
                LV_ROW_FILTER_CLAUSE || ' ' || lv_filter_query;
        END IF;

        --
        --            IF (UPPER (lv_user_role) = 'RP')
        --            THEN
        --               SELECT REPAIR_PARTNER_ID
        --                 INTO lv_repair_partner_id
        --                 FROM CRPADM.rc_repair_partner_user_map
        --                WHERE USER_NAME = lv_user_id;
        --
        --
        --               LV_ROW_FILTER_CLAUSE :=
        --                     LV_ROW_FILTER_CLAUSE
        --                  || ' '
        --                  || ' AND REPAIR_PARTNER = '''
        --                  || lv_repair_partner_id
        --                  || '''';
        --            END IF;

        --      IF (UPPER (lv_user_role) = 'BPM')
        --      THEN
        --         LV_ROW_FILTER_CLAUSE :=
        --               LV_ROW_FILTER_CLAUSE
        --            || ' '
        --            || ' AND REPAIR_PARTNER IN (
        --              SELECT RP.REPAIR_PARTNER_ID
        --           FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
        --                INNER JOIN CRPADM.RC_REPAIR_PARTNER_BPM_SETUP BPM
        --                   ON RP.REPAIR_PARTNER_ID = BPM.REPAIR_PARTNER_ID
        --          WHERE ACTIVE_FLAG = ''Y''  AND BPM.BPM_USER_ID = '''
        --            || i_user_id
        --            || ''')';
        --      END IF;

        lv_main_query := lv_main_query || LV_ROW_FILTER_CLAUSE || ' ) PLS';



        --      lv_main_query := lv_main_query || LV_ROW_FILTER_CLAUSE;

        lv_row_clause :=
            ' WHERE RNUM <= ' || lv_max_row || ' AND RNUM >= ' || lv_min_row;

        lv_count_query := 'SELECT COUNT (*) FROM ( ' || lv_main_query || ' )';

        lv_query := 'SELECT RC_PID_LEVEL_SUMMARY_OBJ (REPAIR_SITE,
       FISCAL_YEAR,
       QUARTER,
       MONTH,
       WEEK,
       WEEKEND_DATE,
       COST_TYPE,
       SUB_REFURB_TYPE,
       REFRESH_PID,
       QTY,
       UNIT_PRICE,
       TOTAL_COST,
       SERIAL_NUMBER,
       ECO_NUMBER,
       STATUS)
        FROM ( ' || lv_main_query || ' ) ' || lv_row_clause;
        
        EXECUTE IMMEDIATE lv_query BULK COLLECT INTO lv_pls_data_list;

        EXECUTE IMMEDIATE lv_count_query INTO lv_record_count;

        o_pid_level_summary_data_list := lv_pls_data_list;
        o_record_count := lv_record_count;
        o_status := 1;
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
                'RC_PID_LEVEL_SUMMARY_REPORT.RC_PLS_REPORT_FETCH',
                'PROCEDURE',
                i_user_id,
                'Y');
    END RC_PLS_REPORT_FETCH;

    PROCEDURE GET_UNIQUE_FILTERS (
        i_user_id              IN     VARCHAR2,
        i_filter_column_name   IN     VARCHAR2,
        i_filter_user_input    IN     VARCHAR2,
        i_filter_list          IN     CRPSC.RC_NEW_FILTER_LIST,
        i_repair_site_filter   IN     VARCHAR2,
        i_fiscal_year_filter   IN     NUMBER,
        i_quarter_filter       IN     VARCHAR2,
        i_month_filter         IN     VARCHAR2,
        i_week_filter          IN     NUMBER,
        o_unique_value            OUT CRPSC.RC_NORMALISED_LIST)
    IS
        lv_filter_list          CRPSC.RC_NEW_FILTER_LIST;
        lv_query                CLOB;
        lv_filter_query         CLOB;
        lv_filter_column_name   VARCHAR2 (50 BYTE);
        lv_filter_user_input    VARCHAR2 (500 BYTE);
        lv_idx                  NUMBER;
        lv_cur_deal_id          CLOB;
        lv_i_deal_id            CLOB;
        lv_deal_id_filter       CLOB;
        lv_repair_site_filter   VARCHAR2 (500 BYTE);
        lv_fiscal_year_filter   NUMBER;
        lv_quarter_filter       VARCHAR2 (500 BYTE);
        lv_month_filter         VARCHAR2 (500 BYTE);
        lv_week_filter          NUMBER;
        lv_in_query             CLOB;
        LV_ROW_FILTER_CLAUSE    CLOB;
        lv_ZCODE_list           T_NORMALISED_LIST;
        LV_REPAIR_SITE_CLAUSE   CLOB;
    BEGIN
        lv_filter_list := i_filter_list;
        lv_filter_column_name := UPPER (TRIM (i_filter_column_name));
        lv_filter_user_input := UPPER (TRIM (i_filter_user_input));
        lv_deal_id_filter := NULL;
        lv_repair_site_filter := i_repair_site_filter;
        lv_fiscal_year_filter := i_fiscal_year_filter;
        lv_quarter_filter := i_quarter_filter;
        lv_month_filter := i_month_filter;
        lv_week_filter := i_week_filter;


        lv_query :=
               'SELECT DISTINCT UPPER('
            || lv_filter_column_name
            || ') '
            || lv_filter_column_name
            || ' FROM CRPREP.RC_PID_LEVEL_SUMMARY ';


        LV_ROW_FILTER_CLAUSE := ' WHERE 1=1 ';
        
            SELECT DISTINCT NVL (ZCODE, 'NA')
              BULK COLLECT INTO lv_ZCODE_list
              FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER  RP
                   JOIN CRPADM.rc_repair_partner_user_map MAP
                       ON RP.REPAIR_PARTNER_ID = MAP.REPAIR_PARTNER_ID
             WHERE     MAP.USER_NAME = i_user_id
             AND ZCODE <> 'Z32'
                   AND RP.ACTIVE_FLAG = 'Y'
                   AND MAP.ACTIVE_FLAG = 'Y';

        LV_REPAIR_SITE_CLAUSE := ' ';

        IF (lv_ZCODE_list.COUNT () > 0)
        THEN
            LV_REPAIR_SITE_CLAUSE :=
                LV_REPAIR_SITE_CLAUSE || ' AND (REPAIR_SITE IN(';

            FOR I IN 1 .. lv_ZCODE_list.COUNT ()
            LOOP
                EXIT WHEN I IS NULL;
                LV_REPAIR_SITE_CLAUSE :=
                       LV_REPAIR_SITE_CLAUSE
                    || ''''
                    || lv_ZCODE_list (I)
                    || '''';

                IF (I < lv_ZCODE_list.COUNT ())
                THEN
                    LV_REPAIR_SITE_CLAUSE := LV_REPAIR_SITE_CLAUSE || ',';
                END IF;
            END LOOP;

            LV_REPAIR_SITE_CLAUSE := LV_REPAIR_SITE_CLAUSE || '))';
        END IF;
        
        LV_ROW_FILTER_CLAUSE :=
                   LV_ROW_FILTER_CLAUSE || LV_REPAIR_SITE_CLAUSE;

        IF (    lv_repair_site_filter IS NOT NULL
            AND lv_repair_site_filter <> 'ALL')
        THEN
            LV_ROW_FILTER_CLAUSE :=
                   LV_ROW_FILTER_CLAUSE
                || ' AND ( REPAIR_SITE = '''
                || lv_repair_site_filter
                || ''')';
        END IF;



        IF (lv_fiscal_year_filter IS NOT NULL --          AND lv_fiscal_year_filter <> 'ALL'
                                             )
        THEN
            LV_ROW_FILTER_CLAUSE :=
                   LV_ROW_FILTER_CLAUSE
                || ' AND ( FISCAL_YEAR = '
                || lv_fiscal_year_filter
                || ')';
        END IF;


        IF (lv_quarter_filter IS NOT NULL AND lv_quarter_filter <> 'ALL')
        THEN
            LV_ROW_FILTER_CLAUSE :=
                   LV_ROW_FILTER_CLAUSE
                || ' AND ( QUARTER = '''
                || lv_quarter_filter
                || ''')';
        END IF;


        IF (lv_month_filter IS NOT NULL AND lv_month_filter <> 'ALL')
        THEN
            LV_ROW_FILTER_CLAUSE :=
                   LV_ROW_FILTER_CLAUSE
                || ' AND ( MONTH = '''
                || lv_month_filter
                || ''')';
        END IF;


        IF (lv_week_filter IS NOT NULL     --      AND lv_week_filter <> 'ALL'
                                      )
        THEN
            LV_ROW_FILTER_CLAUSE :=
                   LV_ROW_FILTER_CLAUSE
                || ' AND ( WEEK = '
                || lv_week_filter
                || ')';
        END IF;


        -- For Column Level Filtering based on the user input
        IF     lv_filter_column_name IS NOT NULL
           AND lv_filter_user_input IS NOT NULL
        THEN
            LV_ROW_FILTER_CLAUSE :=
                   LV_ROW_FILTER_CLAUSE
                || ' AND (UPPER(TRIM('
                || lv_filter_column_name
                || ')) LIKE (UPPER(TRIM(''%'
                || lv_filter_user_input
                || '%''))))';
        END IF;


        lv_query := lv_query || LV_ROW_FILTER_CLAUSE;



        IF (lv_filter_list IS NOT NULL OR lv_filter_user_input IS NOT NULL)
        THEN
            IF (lv_filter_list IS NOT NULL)
            THEN
                GET_FILTERS_IN_QUERY (lv_filter_list,
                                      'RC_PID_LEVEL_SUMMARY',
                                      lv_filter_query);
                lv_query := lv_query || ' ' || lv_filter_query;
            END IF;
        END IF;



        lv_query :=
               lv_query
            || ' ORDER BY '
            || lv_filter_column_name
            || ' ASC NULLS LAST';



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
                'RC_PID_LEVEL_SUMMARY_REPORT.GET_UNIQUE_FILTERS',
                'PROCEDURE',
                i_user_id,
                'Y');
    END GET_UNIQUE_FILTERS;


    PROCEDURE GET_FILTERS_IN_QUERY (
        i_filter_list   IN     CRPSC.RC_NEW_FILTER_LIST,
        i_table_name    IN     VARCHAR2,
        o_in_query         OUT CLOB)
    IS
        lv_in_query             CLOB;
        lv_null_query           VARCHAR2 (32767);
        lv_count                NUMBER;
        lv_filter_data_list     CRPSC.RC_FILTER_DATA_OBJ_LIST;
        lv_filter_column_name   VARCHAR2 (1000);
        lv_filter_value         VARCHAR2 (4000);
        lv_column_data_type     VARCHAR2 (25);
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

                    lv_filter_value :=
                        UPPER (
                            TO_CHAR (
                                TRIM (lv_filter_data_list (idx).FILTER_DATA)));


                    IF     (lv_filter_data_list (idx).FILTER_DATA IS NOT NULL)
                       AND (lv_filter_data_list (idx).FILTER_DATA NOT LIKE
                                ' ')
                    THEN
                        lv_filter_value :=
                            UPPER (
                                TO_CHAR (
                                    TRIM (
                                        lv_filter_data_list (idx).FILTER_DATA)));

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
                                       lv_in_query
                                    || ''''
                                    || lv_filter_value
                                    || '''';
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


        COMMIT;
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
                'RC_PID_LEVEL_SUMMARY_REPORT.GET_FILTERS_IN_QUERY',
                'PROCEDURE',
                '',
                'Y');
            COMMIT;
    END GET_FILTERS_IN_QUERY;

    PROCEDURE GET_ADVANCED_FILTERS (
        i_user_id               IN     VARCHAR2,
        i_user_role             IN     VARCHAR2,
        o_pls_adv_fltr_list        OUT CRPREP.RC_PLS_ADV_FLTR_LIST,
        o_repair_partner_list      OUT CRPADM.RC_REPAIR_PARTNER_LIST,
        o_status                   OUT NUMBER,
        o_status_msg               OUT VARCHAR2)
    IS
        lv_pls_adv_fltr_list     CRPREP.RC_PLS_ADV_FLTR_LIST
                                     := CRPREP.RC_PLS_ADV_FLTR_LIST ();
        lv_repair_partner_list   CRPADM.RC_REPAIR_PARTNER_LIST;
        lv_user_id               VARCHAR2 (50 BYTE);
        lv_user_role             VARCHAR2 (50 BYTE);
        lv_repair_userid         VARCHAR2 (50 BYTE);
        lv_query                 CLOB;
        LV_ROW_FILTER_CLAUSE     VARCHAR2 (1000 BYTE);
--        lv_repair_partner_id     VARCHAR2 (50 BYTE);
    BEGIN
        lv_repair_partner_list := CRPADM.RC_REPAIR_PARTNER_LIST ();
        lv_user_id := i_user_id;
        lv_user_role := i_user_role;
        o_status := 1;
        o_status_msg := NULL;
        lv_query := 'SELECT RC_PLS_ADV_FLTR_OBJ (REPAIR_SITE,
                                                FISCAL_YEAR,
                                                QUARTER,
                                                MONTH,
                                                WEEK)
                            FROM (SELECT DISTINCT REPAIR_SITE,
                                                    FISCAL_YEAR,
                                                    QUARTER,
                                                    MONTH,
                                                    WEEK
                                      FROM RC_PID_LEVEL_SUMMARY ';

        IF (UPPER (lv_user_role) = 'RP')
        THEN
--            SELECT DISTINCT REPAIR_PARTNER_ID
--              INTO lv_repair_partner_id
--              FROM CRPADM.rc_repair_partner_user_map
--             WHERE USER_NAME = lv_user_id;


            LV_ROW_FILTER_CLAUSE :=
                   LV_ROW_FILTER_CLAUSE
                || ' '
                || ' WHERE REPAIR_SITE IN (SELECT DISTINCT ZCODE
           FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                JOIN CRPADM.rc_repair_partner_user_map MAP
                   ON RP.REPAIR_PARTNER_ID = MAP.REPAIR_PARTNER_ID
          WHERE 1=1 AND RP.ACTIVE_FLAG = ''Y''
          AND ZCODE <> ''Z32''
             AND MAP.ACTIVE_FLAG = ''Y'' AND MAP.USER_NAME = '''
                || lv_user_id
                || ''') ';
        --         LV_ROW_FILTER_CLAUSE :=
        --               LV_ROW_FILTER_CLAUSE
        --            || ' '
        --            || ' WHERE REPAIR_PARTNER = '''
        --            || lv_repair_partner_id
        --            || '''';


        --      ELSIF (UPPER (lv_user_role) = 'BPM')
        --      THEN
        --         LV_ROW_FILTER_CLAUSE :=
        --               LV_ROW_FILTER_CLAUSE
        --            || ' '
        --            || ' WHERE REPAIR_PARTNER IN (
        --              SELECT RP.REPAIR_PARTNER_ID
        --           FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
        --                INNER JOIN CRPADM.RC_REPAIR_PARTNER_BPM_SETUP BPM
        --                   ON RP.REPAIR_PARTNER_ID = BPM.REPAIR_PARTNER_ID
        --          WHERE ACTIVE_FLAG = ''Y''  AND BPM.BPM_USER_ID = '''
        --            || i_user_id
        --            || ''')';
        END IF;



        lv_query := lv_query || LV_ROW_FILTER_CLAUSE || ')';


        EXECUTE IMMEDIATE lv_query BULK COLLECT INTO lv_pls_adv_fltr_list;

        BEGIN
            SELECT DISTINCT USER_NAME
              INTO lv_repair_userid
              FROM CRPADM.RC_REPAIR_PARTNER_USER_MAP
             WHERE USER_NAME = lv_user_id;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                IF lv_user_role = 'RP'
                THEN
                    o_status := -1;

                    SELECT PROPERTY_VALUE
                      INTO o_status_msg
                      FROM CRPADM.RC_PROPERTIES
                     WHERE PROPERTY_TYPE = 'MSG_FOR_IMPROPER_ROLE';
                END IF;

                lv_repair_userid := '';
        END;

        BEGIN
            IF lv_repair_userid IS NOT NULL
            THEN
                SELECT CRPADM.RC_REPAIR_PARTNER_OBJ (REPAIR_PARTNER_ID,
                                                     REPAIR_PARTNER_NAME)
                  BULK COLLECT INTO lv_repair_partner_list
                  FROM (SELECT DISTINCT
                               usr.REPAIR_PARTNER_ID   REPAIR_PARTNER_ID,
                               usr.REPAIR_PARTNER_NAME REPAIR_PARTNER_NAME
                          FROM CRPADM.RC_REPAIR_PARTNER_USER_MAP usr
                         WHERE     usr.USER_NAME = lv_user_id
                               AND usr.ACTIVE_FLAG = 'Y');
            --         ELSIF (UPPER (lv_user_role) = 'BPM')
            --         THEN
            --            SELECT CRPADM.RC_REPAIR_PARTNER_OBJ (REPAIR_PARTNER_ID,
            --                                                 REPAIR_PARTNER_NAME)
            --              BULK COLLECT INTO lv_repair_partner_list
            --              FROM (SELECT DISTINCT
            --                           RP.REPAIR_PARTNER_ID, RP.REPAIR_PARTNER_NAME
            --                      FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
            --                           INNER JOIN CRPADM.RC_REPAIR_PARTNER_BPM_SETUP BPM
            --                              ON RP.REPAIR_PARTNER_ID = BPM.REPAIR_PARTNER_ID
            --                     WHERE ACTIVE_FLAG = 'Y' AND BPM.BPM_USER_ID = lv_user_id);
            ELSE
                SELECT CRPADM.RC_REPAIR_PARTNER_OBJ (REPAIR_PARTNER_ID,
                                                     REPAIR_PARTNER_NAME)
                  BULK COLLECT INTO lv_repair_partner_list
                  FROM (SELECT DISTINCT
                               RP.REPAIR_PARTNER_ID   REPAIR_PARTNER_ID,
                               RP.REPAIR_PARTNER_NAME REPAIR_PARTNER_NAME
                          FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER rp
                         WHERE     RP.ACTIVE_FLAG = 'Y'
                               AND ZCODE <> 'Z32'
                               AND RP.ACTIVE_FLAG = 'Y' --                           AND MAP.ACTIVE_FLAG = 'Y'
                                                       );
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_repair_partner_list := CRPADM.RC_REPAIR_PARTNER_LIST ();
                o_status := 0;
        END;

        o_pls_adv_fltr_list := lv_pls_adv_fltr_list;
        o_repair_partner_list := lv_repair_partner_list;
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
                'RC_PID_LEVEL_SUMMARY_REPORT.GET_ADVANCED_FILTERS',
                'PROCEDURE',
                i_user_id,
                'Y');
    END GET_ADVANCED_FILTERS;



   PROCEDURE UPLOAD_PLS_DATA (
        i_user_id                   IN VARCHAR2,
        i_repair_partner_id         IN NUMBER,
        i_upload_id                 IN NUMBER,
        i_upload_role               IN VARCHAR2,
        i_pid_summary_upload_list   IN RC_PID_LEVEL_SUMMARY_GU_LIST)
    IS
        lv_pid_summary_upload_list   RC_PID_LEVEL_SUMMARY_GU_LIST;
        lv_pid_summary_upload_list1   RC_PID_LEVEL_SUMMARY_GU_LIST;
        lv_repair_partner_id         VARCHAR2 (50);
        lv_upload_id                 VARCHAR2 (50);
        lv_upload_role               VARCHAR2 (50);
        lv_gu_ZCODE                  VARCHAR2 (150);
        lv_valid_site_code           NUMBER;
        lv_accesible_site_code       NUMBER;
        lv_weekend_date_list         T_NORMALISED_LIST;
        lv_ZCODE_list                T_NORMALISED_LIST;
        lv_weekend_count             NUMBER;
        lv_pid_count                 NUMBER;
        lv_valid_pid                 NUMBER;
        lv_valid_year                NUMBER;
        lv_valid_quarter             NUMBER;
        lv_valid_wk                  NUMBER;
        LV_REC_EXIST_COUNT           NUMBER;
        LV_REC_EXIST_CNT1           NUMBER;
        lv_uploaded_weekend_flag     NUMBER;
        lv_we_date                   VARCHAR2 (50);
        lv_user_id                   VARCHAR2 (50);
        LV_MONTH                     VARCHAR2 (50);
        LV_QUARTER                   VARCHAR2 (50);
        LV_YEAR                      VARCHAR2 (50);
        LV_WEEK                      VARCHAR2 (50);
        lv_error_message             VARCHAR2 (500);
        lv_weekend_error             VARCHAR2 (100);
        lv_site_error                VARCHAR2 (100);
        lv_pid_error                 VARCHAR2 (100);
        lv_access_error              VARCHAR2 (100);
        lv_year_error                VARCHAR2 (100);
        lv_qtr_error                 VARCHAR2 (100);
        lv_wk_error                  VARCHAR2 (100);
        lv_string_count_in_qty       NUMBER;
        lv_valid_qty                 NUMBER;
        lv_string_count_in_price     NUMBER;
        lv_valid_unit_price          NUMBER;
        lv_string_count_in_cost      NUMBER;
        lv_valid_total_cost          NUMBER;
        lv_qty_error                 VARCHAR2 (100);
        lv_price_error               VARCHAR2 (100);
        lv_cost_error                VARCHAR2 (100);
        --lv_query1                    VARCHAR2(100);
        lv_size                      NUMBER;
        LV_INVALID_LIST              RC_PLS_INVALID_LIST
                                         := RC_PLS_INVALID_LIST ();
        CUSTOM_EXCEPTION             EXCEPTION;
        PRAGMA EXCEPTION_INIT (CUSTOM_EXCEPTION, -20001);
    BEGIN
        INSERT INTO CRPADM.RC_PROCESS_LOG
             VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                     'CRPREP.RC_PID_LEVEL_SUMMARY_REPORT.UPLOAD_PLS_DATA',
                     'START',
                     SYSDATE);

        lv_pid_summary_upload_list := RC_PID_LEVEL_SUMMARY_GU_LIST ();
        lv_pid_summary_upload_list1 := RC_PID_LEVEL_SUMMARY_GU_LIST ();
        lv_pid_summary_upload_list := i_pid_summary_upload_list;
        lv_pid_summary_upload_list1 := i_pid_summary_upload_list;
        lv_repair_partner_id := i_repair_partner_id;
        lv_upload_id := i_upload_id;
        lv_user_id := i_user_id;
        lv_upload_role := i_upload_role;
        lv_weekend_date_list := T_NORMALISED_LIST ();
        lv_ZCODE_list := T_NORMALISED_LIST ();
        --      lv_error_message := '';
        lv_upload_id := CRPADM.UPLOAD_ID_SEQ.NEXTVAL;
        lv_valid_site_code := -1;
        lv_accesible_site_code := -1;
        lv_valid_year := -1;
        lv_valid_quarter := -1;
        lv_valid_wk := -1;
        lv_valid_qty := -1;
        lv_valid_unit_price := -1;
        lv_valid_total_cost := -1;


        SELECT DISTINCT NVL (ZCODE, 'NA')
          INTO lv_gu_ZCODE
          FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER  RP
               JOIN CRPADM.rc_repair_partner_user_map MAP
                   ON     RP.REPAIR_PARTNER_ID = MAP.REPAIR_PARTNER_ID
                      AND RP.REPAIR_PARTNER_ID = lv_repair_partner_id
                      AND ZCODE <> 'Z32'
                      AND RP.ACTIVE_FLAG = 'Y'
                      AND MAP.ACTIVE_FLAG = 'Y';



        SELECT DISTINCT NVL (ZCODE, 'NA')
          BULK COLLECT INTO lv_ZCODE_list
          FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER  RP
--               JOIN CRPADM.rc_repair_partner_user_map MAP
--                   ON RP.REPAIR_PARTNER_ID = MAP.REPAIR_PARTNER_ID
         WHERE 1 = 1 AND ZCODE <> 'Z32' AND RP.ACTIVE_FLAG = 'Y';-- AND MAP.ACTIVE_FLAG = 'Y';


        DELETE FROM RC_INVALID_PLS_GU;
        DELETE FROM RC_PID_LEVEL_SUMMARY_TEMP;

        COMMIT;

        SELECT DISTINCT TO_CHAR (FISCAL_WEEK_END_DATE, 'MM/DD/YYYY')
          BULK COLLECT INTO lv_weekend_date_list
          FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM;
        
        -- Added below logic by shashi to check any data exist with combination of Fiscal year,site code and weekend date. 
        -- If exists it should delete the existing data for that  combination of Fiscal year,site code and weekend date.
        FOR idx IN 1 .. lv_pid_summary_upload_list.COUNT ()
        LOOP
            EXIT WHEN idx IS NULL;

            SELECT COUNT (*)
              INTO LV_REC_EXIST_CNT1
              FROM rc_pid_level_summary
                    WHERE     UPPER (TRIM (repair_site)) =
                       UPPER (
                           TRIM (
                               lv_pid_summary_upload_list (idx).REPAIR_SITE))
                   AND weekend_date =
                       TO_CHAR (
                           TO_DATE (
                               lv_pid_summary_upload_list (idx).WEEKEND_DATE,
                               'MM/DD/RR'),
                           'MM/DD/YYYY')
                   AND  UPPER (TRIM(FISCAL_YEAR)) =
                       UPPER (TRIM(lv_pid_summary_upload_list (idx).FISCAL_YEAR)); 
                       
                                                      
             IF LV_REC_EXIST_CNT1 <> 0
             
                THEN
                
                DELETE FROM rc_pid_level_summary
                    WHERE     UPPER (TRIM (repair_site)) =
                       UPPER (
                           TRIM (
                               lv_pid_summary_upload_list (idx).REPAIR_SITE))
                   AND weekend_date =
                       TO_CHAR (
                           TO_DATE (
                               lv_pid_summary_upload_list (idx).WEEKEND_DATE,
                               'MM/DD/RR'),
                           'MM/DD/YYYY')
                   AND  UPPER (TRIM(FISCAL_YEAR)) =
                       UPPER (TRIM(lv_pid_summary_upload_list (idx).FISCAL_YEAR)); 
                
                COMMIT;
                
                END IF;
                                                                           
                                                                           
        END LOOP;
        
        
        -- Changed the logic by shashi in where condition. Added fiscal year instead of refresh id. 
       
        FOR idx IN 1 .. lv_pid_summary_upload_list.COUNT ()
        LOOP
            EXIT WHEN idx IS NULL;

            SELECT COUNT (*)
              INTO LV_REC_EXIST_COUNT
              FROM rc_pid_level_summary
             WHERE     UPPER (TRIM (repair_site)) =
                       UPPER (
                           TRIM (
                               lv_pid_summary_upload_list (idx).REPAIR_SITE))
                   AND weekend_date =
                       TO_CHAR (
                           TO_DATE (
                               lv_pid_summary_upload_list (idx).WEEKEND_DATE,
                               'MM/DD/RR'),
                           'MM/DD/YYYY')
                   AND  UPPER (TRIM(FISCAL_YEAR)) =
                       UPPER (TRIM(lv_pid_summary_upload_list (idx).FISCAL_YEAR));
              -- AND UPPER (refresh_pid) =
                 --      UPPER (lv_pid_summary_upload_list (idx).REFRESH_PID) --                AND serial_number =
                                                                           --                       lv_pid_summary_upload_list (idx).SERIAL_NUMBER
                             

             
            SELECT COUNT (
                       DISTINCT (TO_CHAR (FISCAL_WEEK_END_DATE, 'MM/DD/YYYY')))
              INTO lv_uploaded_weekend_flag
              FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
             WHERE TO_CHAR (FISCAL_WEEK_END_DATE, 'MM/DD/YYYY') =
                   TO_CHAR (
                       TO_DATE (
                           lv_pid_summary_upload_list (idx).WEEKEND_DATE,
                           'MM/DD/RR'),
                       'MM/DD/YYYY');


            SELECT COUNT (*)
              INTO lv_valid_pid
              FROM CRPADM.RC_PRODUCT_MASTER
             WHERE    UPPER (lv_pid_summary_upload_list (idx).REFRESH_PID) =
                      UPPER (REFRESH_PART_NUMBER)
                   OR UPPER (lv_pid_summary_upload_list (idx).REFRESH_PID) =
                      UPPER (COMMON_PART_NUMBER)
                   OR UPPER (lv_pid_summary_upload_list (idx).REFRESH_PID) =
                      UPPER (XREF_PART_NUMBER);


            BEGIN
                SELECT DISTINCT
                       SUBSTR (CALENDAR_MONTH_NAME, 1, 3)
                           MONTH_NO,
                       SUBSTR (FISCAL_QUARTER_NAME, 1, 2),
                          SUBSTR (FISCAL_QUARTER_NAME, 4, 2)
                       || SUBSTR (FISCAL_QUARTER_NAME, 8, 2),
                       --'WK' || LPAD (TO_CHAR (FISCAL_WEEK_NUMBER), 2, '0')
                        CASE
                          WHEN  LPAD (TO_CHAR (mod(FISCAL_WEEK_NUMBER,13)), 2, '0')<>'00'
                          THEN 'WK' || LPAD (TO_CHAR (mod(FISCAL_WEEK_NUMBER,13)), 2, '0')
                          WHEN (LPAD (TO_CHAR (mod(FISCAL_WEEK_NUMBER,13)), 2, '0')='00')
                          THEN 'WK13'
                       END
                    --   'WK' || LPAD (TO_CHAR (FISCAL_WEEK_NUMBER), 2, '0')   
                    -- modified to handle week value as below.
                    -- If week value is less than or equals to 13 shoud come as 'wk01','wk02'..'wk13'.  if greater than 13, needs to start again from 'wk01'..so on.  
                  INTO LV_MONTH,
                       LV_QUARTER,
                       LV_YEAR,
                       LV_WEEK
                  FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                 WHERE TO_CHAR (FISCAL_WEEK_END_DATE, 'MM/DD/YYYY') =
                       TO_CHAR (
                           TO_DATE (
                               lv_pid_summary_upload_list (idx).WEEKEND_DATE,
                               'MM/DD/RR'),
                           'MM/DD/YYYY')
                           and  CALENDAR_MONTH_NUMBER=ltrim(TO_CHAR(TO_DATE(lv_pid_summary_upload_list (idx).WEEKEND_DATE,'MM/DD/RR'),'MM'),'0');-- Added this line by shashi for upload issue with 8/3/2019 weekend date for fixing the  Sprint 29 point release issue

                IF LV_YEAR =
                   UPPER (
                       TRIM (lv_pid_summary_upload_list (idx).FISCAL_YEAR))
                THEN
                    lv_valid_year := 1;
                ELSE
                    lv_valid_year := 0;
                END IF;

                IF LV_QUARTER =
                   UPPER (TRIM (lv_pid_summary_upload_list (idx).QUARTER))
                THEN
                    lv_valid_quarter := 1;
                ELSE
                    lv_valid_quarter := 0;
                END IF;

                IF LV_WEEK =
                   UPPER (TRIM (lv_pid_summary_upload_list (idx).WEEK))
                THEN
                    lv_valid_wk := 1;
                ELSE
                    lv_valid_wk := 0;
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    LV_MONTH := NULL;
                    LV_QUARTER := NULL;
                    LV_YEAR := NULL;
                    LV_WEEK := NULL;
                    lv_valid_year := 0;
                    lv_valid_quarter := 0;
                    lv_valid_wk := 0;
            END;

            IF (lv_ZCODE_list.COUNT () > 0)
            THEN
                IF UPPER (
                       TRIM (lv_pid_summary_upload_list (idx).REPAIR_SITE))
                        MEMBER OF lv_ZCODE_list
                THEN
                    lv_valid_site_code := 1;
                ELSE
                    lv_valid_site_code := 0;
                END IF;

                IF UPPER (TRIM (lv_gu_ZCODE)) =
                   UPPER (
                       TRIM (lv_pid_summary_upload_list (idx).REPAIR_SITE))
                THEN
                    lv_accesible_site_code := 1;
                ELSE
                    lv_accesible_site_code := 0;
                END IF;
            ELSE
                IF (UPPER (TRIM (lv_gu_ZCODE)) =
                    UPPER (
                        TRIM (lv_pid_summary_upload_list (idx).REPAIR_SITE)))
                THEN
                    lv_accesible_site_code := 1;
                ELSE
                    lv_accesible_site_code := 0;
                END IF;
            END IF;

           /* SELECT LENGTH (
                       TRIM (
                           TRANSLATE (lv_pid_summary_upload_list (idx).QTY,
                                      '0123456789.',
                                      ' ')))
              INTO lv_string_count_in_qty
              FROM DUAL;*/ --commented above by shashi and added below to handle the numbers with comma seperated on Oct 8 2019.
              
              SELECT LENGTH (REPLACE(
                       TRIM (
                           TRANSLATE (lv_pid_summary_upload_list (idx).QTY,
                                      '0123456789.',
                                      ' ')), ',', ''))
              INTO lv_string_count_in_qty
              FROM DUAL;

            IF lv_string_count_in_qty IS NULL
            THEN
                lv_valid_qty := 1;
            ELSE
                lv_valid_qty := 0;
            END IF;

            /*SELECT LENGTH (
                       TRIM (
                           TRANSLATE (
                               lv_pid_summary_upload_list (idx).UNIT_PRICE,
                               '0123456789.',
                               ' ')))
              INTO lv_string_count_in_price
              FROM DUAL;*/--commented above by shashi and added below to handle the numbers with comma seperated on Oct 8 2019.
              
              SELECT LENGTH (REPLACE(
                       TRIM (
                           TRANSLATE (
                               lv_pid_summary_upload_list (idx).UNIT_PRICE,
                               '0123456789.',
                               ' ')), ',', ''))
              INTO lv_string_count_in_price
              FROM DUAL;

            IF lv_string_count_in_price IS NULL
            THEN
                lv_valid_unit_price := 1;
            ELSE
                lv_valid_unit_price := 0;
            END IF;

            /*SELECT LENGTH (
                       TRIM (
                           TRANSLATE (
                               lv_pid_summary_upload_list (idx).TOTAL_COST,
                               '0123456789.',
                               ' ')))
              INTO lv_string_count_in_cost
              FROM DUAL;*/--commented above by shashi and added below to handle the numbers with comma seperated on Oct 8 2019.
              
              SELECT LENGTH (REPLACE(
                       TRIM (
                           TRANSLATE (
                               lv_pid_summary_upload_list (idx).TOTAL_COST,
                               '0123456789.',
                               ' ')), ',', ''))
              INTO lv_string_count_in_cost
              FROM DUAL;

            IF lv_string_count_in_cost IS NULL
            THEN
                lv_valid_total_cost := 1;
            ELSE
                lv_valid_total_cost := 0;
            END IF;

            

            IF     lv_uploaded_weekend_flag > 0
               AND lv_valid_site_code > 0
               AND lv_valid_pid > 0
               AND lv_accesible_site_code > 0
               AND lv_valid_year > 0
               AND lv_valid_quarter > 0
               AND lv_valid_wk > 0
               AND lv_valid_qty > 0
               AND lv_valid_unit_price > 0
               AND lv_valid_total_cost > 0
            THEN
                IF LV_REC_EXIST_COUNT = 0
                --             OR lv_weekend_count = 0
                THEN
                    INSERT INTO RC_PID_LEVEL_SUMMARY_TEMP (REPAIR_SITE,
                                                      FISCAL_YEAR,
                                                      QUARTER,
                                                      WEEK,
                                                      WEEKEND_DATE,
                                                      COST_TYPE,
                                                      SUB_REFURB_TYPE,
                                                      REFRESH_PID,
                                                      QTY,
                                                      UNIT_PRICE,
                                                      TOTAL_COST,
                                                      SERIAL_NUMBER,
                                                      ECO_NUMBER,
                                                      STATUS,
                                                      CREATION_DATE,
                                                      UPLOADED_BY,
                                                      REPAIR_PARTNER,
                                                      MONTH)
                             VALUES (
                                        UPPER (
                                            lv_pid_summary_upload_list (idx).REPAIR_SITE),
                                        UPPER (
                                            lv_pid_summary_upload_list (idx).FISCAL_YEAR),
                                        UPPER (
                                            lv_pid_summary_upload_list (idx).QUARTER),
                                        UPPER (
                                            lv_pid_summary_upload_list (idx).WEEK),
                                        TO_CHAR (
                                            TO_DATE (
                                                lv_pid_summary_upload_list (
                                                    idx).WEEKEND_DATE,
                                                'MM/DD/RR'),
                                            'MM/DD/YYYY'),
                                        UPPER (
                                            lv_pid_summary_upload_list (idx).COST_TYPE),
                                        UPPER (
                                            lv_pid_summary_upload_list (idx).SUB_REFURB_TYPE),
                                        UPPER (
                                            lv_pid_summary_upload_list (idx).REFRESH_PID),
                                        /*TO_NUMBER(lv_pid_summary_upload_list (idx).QTY),
                                        TO_NUMBER(lv_pid_summary_upload_list (idx).UNIT_PRICE),
                                        TO_NUMBER(lv_pid_summary_upload_list (idx).TOTAL_COST),*/
                                        TO_NUMBER(REPLACE(lv_pid_summary_upload_list (idx).QTY, ',', '')),
                                        TO_NUMBER(REPLACE(lv_pid_summary_upload_list (idx).UNIT_PRICE, ',', '')),
                                        TO_NUMBER(REPLACE(lv_pid_summary_upload_list (idx).TOTAL_COST, ',', '')),
                                        lv_pid_summary_upload_list (idx).SERIAL_NUMBER,
                                        lv_pid_summary_upload_list (idx).ECO_NUMBER,
                                        UPPER (
                                            lv_pid_summary_upload_list (idx).STATUS),
                                        SYSDATE,
                                        lv_user_id,
                                        lv_repair_partner_id,
                                        LV_MONTH);

                    COMMIT;
                       
                END IF;
            ELSE
                BEGIN
                    lv_error_message := '';
                    lv_weekend_error := '';
                    lv_site_error := '';
                    lv_pid_error := '';
                    lv_access_error := '';
                    lv_year_error := '';
                    lv_qtr_error := '';
                    lv_wk_error := '';
                    lv_qty_error := '';
                    lv_price_error := '';
                    lv_cost_error := '';

                    CASE
                        WHEN lv_uploaded_weekend_flag = 0
                        THEN
                            lv_weekend_error := 'Weekend Date is Not Valid.';
                        ELSE
                            NULL;
                    END CASE;

                    CASE
                        WHEN lv_valid_site_code = 0
                        THEN
                            lv_site_error := 'Site Code is Not Valid.';
                        ELSE
                            NULL;
                    END CASE;

                    CASE
                        WHEN lv_valid_pid = 0
                        THEN
                            lv_pid_error := 'Refresh Pid is Not Valid.';
                        ELSE
                            NULL;
                    END CASE;

                    CASE
                        WHEN     lv_accesible_site_code = 0
                             AND lv_valid_site_code <> 0
                        THEN
                            lv_access_error :=
                                'Selected Repair site in RC doesn''t match as per the uploaded file.';
                        ELSE
                            NULL;
                    END CASE;

                    CASE
                        WHEN lv_valid_year = 0
                        THEN
                            lv_year_error := 'Fiscal Year is incorrect.';
                        ELSE
                            NULL;
                    END CASE;

                    CASE
                        WHEN lv_valid_quarter = 0
                        THEN
                            lv_qtr_error := 'Fiscal Quarter is incorrect.';
                        ELSE
                            NULL;
                    END CASE;

                    CASE
                        WHEN lv_valid_wk = 0
                        THEN
                            lv_wk_error := 'Fiscal Week is incorrect.';
                        ELSE
                            NULL;
                    END CASE;

                    CASE
                        WHEN lv_valid_qty = 0
                        THEN
                            lv_qty_error := 'Quantity is not a number.';
                        ELSE
                            NULL;
                    END CASE;

                    CASE
                        WHEN lv_valid_unit_price = 0
                        THEN
                            lv_price_error := 'Unit price is not a number.';
                        ELSE
                            NULL;
                    END CASE;

                    CASE
                        WHEN lv_valid_total_cost = 0
                        THEN
                            lv_cost_error := 'Total Cost is not a number.';
                        ELSE
                            NULL;
                    END CASE;

                    lv_error_message :=
                           lv_weekend_error
                        || ' '
                        || lv_site_error
                        || ' '
                        || lv_pid_error
                        || ' '
                        || lv_access_error
                        || ' '
                        || lv_year_error
                        || ' '
                        || lv_wk_error
                        || ' '
                        || lv_qtr_error
                        || ' '
                        || lv_cost_error
                        || ' '
                        || lv_price_error
                        || ' '
                        || lv_qty_error;

                    lv_error_message := TRIM (lv_error_message);


                    INSERT INTO RC_INVALID_PLS_GU (ERROR_MESSAGE,
                                                   REPAIR_SITE,
                                                   FISCAL_YEAR,
                                                   QUARTER,
                                                   WEEK,
                                                   WEEKEND_DATE,
                                                   COST_TYPE,
                                                   SUB_REFURB_TYPE,
                                                   REFRESH_PID,
                                                   QTY,
                                                   UNIT_PRICE,
                                                   TOTAL_COST,
                                                   SERIAL_NUMBER,
                                                   ECO_NUMBER,
                                                   STATUS)
                        (SELECT lv_error_message,
                                lv_pid_summary_upload_list (idx).REPAIR_SITE,
                                lv_pid_summary_upload_list (idx).FISCAL_YEAR,
                                lv_pid_summary_upload_list (idx).QUARTER,
                                lv_pid_summary_upload_list (idx).WEEK,
                                TO_CHAR (
                                    TO_DATE (
                                        lv_pid_summary_upload_list (idx).WEEKEND_DATE,
                                        'MM/DD/RR'),
                                    'MM/DD/YYYY'),
                                lv_pid_summary_upload_list (idx).COST_TYPE,
                                lv_pid_summary_upload_list (idx).SUB_REFURB_TYPE,
                                lv_pid_summary_upload_list (idx).REFRESH_PID,
                                lv_pid_summary_upload_list (idx).QTY,
                                lv_pid_summary_upload_list (idx).UNIT_PRICE,
                                lv_pid_summary_upload_list (idx).TOTAL_COST,
                                lv_pid_summary_upload_list (idx).SERIAL_NUMBER,
                                lv_pid_summary_upload_list (idx).ECO_NUMBER,
                                lv_pid_summary_upload_list (idx).STATUS
                           FROM DUAL);

                    COMMIT;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        g_error_msg :=
                               SUBSTR (SQLERRM, 1, 200)
                            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                                       12);
                        CRPADM.RC_GLOBAL_ERROR_LOGGING ('OTHERS',
                                                        g_error_msg,
                                                        NULL,
                                                        'UPLOAD_PLS_DATA',
                                                        'PROCEDURE',
                                                        NULL,
                                                        'N');
                        LV_INVALID_LIST := RC_PLS_INVALID_LIST ();
                END;
            END IF;
            
            

            INSERT INTO RC_PID_LEVEL_SUMMARY_HISTORY (REPAIR_SITE,
                                                      FISCAL_YEAR,
                                                      QUARTER,
                                                      WEEK,
                                                      WEEKEND_DATE,
                                                      COST_TYPE,
                                                      SUB_REFURB_TYPE,
                                                      REFRESH_PID,
                                                      QTY,
                                                      UNIT_PRICE,
                                                      TOTAL_COST,
                                                      SERIAL_NUMBER,
                                                      ECO_NUMBER,
                                                      STATUS,
                                                      CREATION_DATE,
                                                      UPLOADED_BY,
                                                      REPAIR_PARTNER,
                                                      MONTH,
                                                      HIST_CREATED_DATE)
                (SELECT REPAIR_SITE,
                        FISCAL_YEAR,
                        QUARTER,
                        WEEK,
                        WEEKEND_DATE,
                        COST_TYPE,
                        SUB_REFURB_TYPE,
                        REFRESH_PID,
                        QTY,
                        UNIT_PRICE,
                        TOTAL_COST,
                        SERIAL_NUMBER,
                        ECO_NUMBER,
                        STATUS,
                        CREATION_DATE,
                        UPLOADED_BY,
                        REPAIR_PARTNER,
                        MONTH,
                        SYSDATE
                   FROM RC_PID_LEVEL_SUMMARY_TEMP PLS
                  WHERE     PLS.WEEKEND_DATE =
                            TO_CHAR (
                                TO_DATE (
                                    lv_pid_summary_upload_list (idx).WEEKEND_DATE,
                                    'MM/DD/RR'),
                                'MM/DD/YYYY')
                        AND UPPER (PLS.UPLOADED_BY) = UPPER (lv_user_id)
                        AND UPPER (PLS.REFRESH_PID) =
                            UPPER (
                                lv_pid_summary_upload_list (idx).REFRESH_PID));

            lv_uploaded_weekend_flag := -1;
            lv_valid_site_code := -1;
            lv_valid_pid := -1;
            lv_accesible_site_code := -1;
            lv_pid_count := -1;
            lv_weekend_count := -1;
            lv_valid_year := -1;
            lv_valid_quarter := -1;
            lv_valid_wk := -1;
            lv_valid_qty := -1;
            lv_valid_unit_price := -1;
            lv_valid_total_cost := -1;
        END LOOP;

        BEGIN
            SELECT RC_PLS_INVALID_OBJ (ERROR_MESSAGE,
                                       REPAIR_SITE,
                                       FISCAL_YEAR,
                                       QUARTER,
                                       WEEK,
                                       WEEKEND_DATE,
                                       COST_TYPE,
                                       SUB_REFURB_TYPE,
                                       REFRESH_PID,
                                       QTY,
                                       UNIT_PRICE,
                                       TOTAL_COST,
                                       SERIAL_NUMBER,
                                       ECO_NUMBER,
                                       STATUS)
              BULK COLLECT INTO LV_INVALID_LIST
              FROM (SELECT ERROR_MESSAGE,
                           REPAIR_SITE,
                           FISCAL_YEAR,
                           QUARTER,
                           WEEK,
                           WEEKEND_DATE,
                           COST_TYPE,
                           SUB_REFURB_TYPE,
                           REFRESH_PID,
                           QTY,
                           UNIT_PRICE,
                           TOTAL_COST,
                           SERIAL_NUMBER,
                           ECO_NUMBER,
                           STATUS
                      FROM RC_INVALID_PLS_GU);

            COMMIT;
        EXCEPTION
            WHEN OTHERS
            THEN
                LV_INVALID_LIST := RC_PLS_INVALID_LIST ();
        END;
        
        insert into RC_PID_LEVEL_SUMMARY
        select * from RC_PID_LEVEL_SUMMARY_TEMP;
        
        COMMIT;

        RC_PID_LEVEL_SUMMARY_EMAIL (I_USER_ID, I_UPLOAD_ID, LV_INVALID_LIST);

        INSERT INTO CRPADM.RC_PROCESS_LOG
             VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                     'CRPREP.RC_PID_LEVEL_SUMMARY_REPORT.UPLOAD_PLS_DATA',
                     'END',
                     SYSDATE);
    EXCEPTION
        WHEN OTHERS
        THEN
            g_error_msg :=
                   SUBSTR (SQLERRM, 1, 200)
                || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
            CRPADM.RC_GLOBAL_ERROR_LOGGING ('OTHERS',
                                            g_error_msg,
                                            NULL,
                                            'UPLOAD_PLS_DATA',
                                            'PROCEDURE',
                                            NULL,
                                            'N');
            RAISE_APPLICATION_ERROR (-20001, g_error_msg);
    END UPLOAD_PLS_DATA;


    PROCEDURE RC_PID_LEVEL_SUMMARY_EMAIL (
        I_USER_ID        IN VARCHAR2,
        I_UPLOAD_ID      IN NUMBER,
        I_INVALID_LIST   IN RC_PLS_INVALID_LIST)
    IS
        LV_UPLOAD_ID       NUMBER;
        LV_INVALID_LIST1   RC_PLS_INVALID_LIST;
        LV_FROM_ID         VARCHAR2 (500);
        LV_TO_ID           VARCHAR2 (500);
        LV_SUBJECT         VARCHAR2 (32767);
        LV_MESSAGE         VARCHAR2 (32767);
        LV_MAILHOST        VARCHAR2 (100) := 'OUTBOUND.CISCO.COM';
        LV_CONN            UTL_SMTP.CONNECTION;
        LV_MESSAGE_TYPE    VARCHAR2 (100)
                               := 'TEXT/HTML; CHARSET="ISO-8859-1"';
        LV_CRLF            VARCHAR2 (5) := CHR (13) || CHR (10);
        LV_OUTPUT          CLOB;
        LV_OUTPUT1         CLOB;
        LV_DATABASE_NAME   VARCHAR2 (50);
        LV_UPLOADED_DATE   VARCHAR2 (50);
        LV_TO_ID_LIST      CRPSC.RC_NORMALISED_LIST
                               := CRPSC.RC_NORMALISED_LIST ();
    BEGIN
        LV_UPLOAD_ID := I_UPLOAD_ID;
        LV_INVALID_LIST1 := I_INVALID_LIST;
        LV_FROM_ID := 'REFRESHCENTRAL-SUPPORT@CISCO.COM';
        LV_TO_ID := I_USER_ID || '@CISCO.COM';

        BEGIN
            SELECT USERID || '@CISCO.COM'
              BULK COLLECT INTO LV_TO_ID_LIST
              FROM (    SELECT REGEXP_SUBSTR ((I_USER_ID),
                                              '[^,]+',
                                              1,
                                              LEVEL)
                                   USERID
                          FROM DUAL
                    CONNECT BY REGEXP_SUBSTR ((I_USER_ID),
                                              '[^,]+',
                                              1,
                                              LEVEL)
                                   IS NOT NULL);
        EXCEPTION
            WHEN OTHERS
            THEN
                LV_TO_ID_LIST := CRPSC.RC_NORMALISED_LIST ();
        END;


        BEGIN
            SELECT TO_CHAR (MAX (UPDATED_ON), 'MM/DD/YYYY HH:MI:SS PM')
              INTO LV_UPLOADED_DATE
              FROM CRPADM.RC_GU_PRODUCT_REFRESH_SETUP
             WHERE     UPPER (MODULE) LIKE
                           '%' || UPPER ('PID level Summary') || '%'
                   AND UPLOAD_ID = LV_UPLOAD_ID;
        EXCEPTION
            WHEN OTHERS
            THEN
                LV_UPLOADED_DATE :=
                    TO_CHAR (SYSDATE, 'MM/DD/YYYY HH:MI:SS PM');
        END;

        IF LV_INVALID_LIST1.COUNT = 0
        THEN
            LV_SUBJECT :=
                   'PROCESSING COMPLETED SUCCESSFULLY FOR UPLOAD ID: '
                || LV_UPLOAD_ID;
        ELSE
            LV_SUBJECT :=
                   'PROCESSING COMPLETED WITH EXCEPTION FOR UPLOAD ID: '
                || LV_UPLOAD_ID;
        END IF;

        SELECT ORA_DATABASE_NAME INTO LV_DATABASE_NAME FROM DUAL;

        IF (ORA_DATABASE_NAME = 'FNTR2DEV.CISCO.COM')
        THEN
            LV_SUBJECT := 'DEV : ' || LV_SUBJECT;
        ELSIF (ORA_DATABASE_NAME = 'FNTR2STG.CISCO.COM')
        THEN
            LV_SUBJECT := 'STAGE : ' || LV_SUBJECT;
        ELSE
            LV_SUBJECT := LV_SUBJECT;
        END IF;

        LV_MESSAGE :=
               ' <HTML> HI, '
            || '<BR /><BR /> '
            || CHR (10)
            || CHR (10)
            || LV_SUBJECT
            || CHR (10)
            || CHR (10)
            || '<BR /><BR /> '
            || 'UPLOADED BY :- '
            || CHR (10)
            || CHR (10)
            || I_USER_ID
            || CHR (10)
            || CHR (10)
            || '<BR /><BR /> '
            || 'UPLOADED ON :- '
            || CHR (10)
            || CHR (10)
            || LV_UPLOADED_DATE
            || CHR (10)
            || CHR (10)
            || '<BR /><BR /> '
            || 'PLEASE DO NOT REPLY .. THIS IS AN AUTO GENERATED EMAIL. '
            || CHR (10)
            || CHR (10)
            || '<BR /><BR /> '
            || '<BR /><BR /> '
            || 'THANKS & REGARDS,'
            || '<BR />'
            || 'REFRESH CENTRAL SUPPORT TEAM </HTML>';

        -- OPEN THE SMTP CONNECTION ...
        LV_CONN := UTL_SMTP.OPEN_CONNECTION (LV_MAILHOST, 25);
        UTL_SMTP.HELO (LV_CONN, LV_MAILHOST);
        UTL_SMTP.MAIL (LV_CONN, LV_FROM_ID);

        FOR IDX IN 1 .. LV_TO_ID_LIST.COUNT ()
        LOOP
            UTL_SMTP.RCPT (LV_CONN, LV_TO_ID_LIST (IDX));
        END LOOP;

        -- OPEN DATA
        UTL_SMTP.OPEN_DATA (LV_CONN);

        -- MESSAGE INFO
        FOR IDX IN 1 .. LV_TO_ID_LIST.COUNT ()
        LOOP
            UTL_SMTP.WRITE_DATA (LV_CONN,
                                 'TO: ' || LV_TO_ID_LIST (IDX) || LV_CRLF);
        END LOOP;

        UTL_SMTP.WRITE_DATA (LV_CONN, 'FROM: ' || LV_FROM_ID || LV_CRLF);
        UTL_SMTP.WRITE_DATA (LV_CONN, 'SUBJECT: ' || LV_SUBJECT || LV_CRLF);
        UTL_SMTP.WRITE_DATA (LV_CONN, 'MIME-VERSION: 1.0' || LV_CRLF);
        UTL_SMTP.WRITE_DATA (
            LV_CONN,
               'CONTENT-TYPE: MULTIPART/MIXED; BOUNDARY="SECBOUND"'
            || LV_CRLF
            || ' BOUNDARY="SECBOUND"'
            || LV_CRLF);

        -- MESSAGE BODY
        UTL_SMTP.WRITE_DATA (LV_CONN, '--SECBOUND' || LV_CRLF);
        UTL_SMTP.WRITE_DATA (
            LV_CONN,
               'CONTENT-TYPE: TEXT/HTML;'
            || LV_CRLF
            || 'CONTENT-TRANSFER_ENCODING: 8BIT'
            || LV_CRLF
            || LV_MESSAGE_TYPE
            || LV_CRLF
            || LV_CRLF);

        UTL_SMTP.WRITE_DATA (LV_CONN, LV_MESSAGE || LV_CRLF); --||'CONTENT-TRANSFER_ENCODING: 7BIT'|| LV_CRLF);

        -- ATTACHMENT PART
        IF LV_INVALID_LIST1.COUNT () > 0
        THEN
            UTL_SMTP.WRITE_DATA (LV_CONN, '--SECBOUND' || LV_CRLF);
            UTL_SMTP.WRITE_DATA (
                LV_CONN,
                   'CONTENT-TYPE: TEXT/PLAIN;'
                || LV_CRLF
                || ' NAME="PIDLEVELSUMMARYERRORDETAILS.XLS"'
                || LV_CRLF
                || 'CONTENT-TRANSFER_ENCODING: 8BIT'
                || LV_CRLF
                || 'CONTENT-DISPOSITION: ATTACHMENT;'
                || LV_CRLF
                || ' FILENAME= "PIDLEVELSUMMARYERRORDETAILS.XLS"'
                || LV_CRLF
                || LV_CRLF);

            LV_OUTPUT :=
                   'ERROR MESSAGE'
                || CHR (9)
                || 'REPAIR SITE'
                || CHR (9)
                || 'FISCAL YEAR'
                || CHR (9)
                || 'QUARTER'
                || CHR (9)
                || 'WEEK'
                || CHR (9)
                || 'WEEKEND_DATE'
                || CHR (9)
                || 'COST_TYPE'
                || CHR (9)
                || 'SUB_REFURB_TYPE'
                || CHR (9)
                || 'REFRESH_PID'
                || CHR (9)
                || 'QTY'
                || CHR (9)
                || 'UNIT_PRICE'
                || CHR (9)
                || 'TOTAL_COST'
                || CHR (9)
                || 'SERIAL_NUMBER'
                || CHR (9)
                || 'ECO_NUMBER'
                || CHR (9)
                || 'STATUS'
                || CHR (10);

            UTL_SMTP.WRITE_DATA (LV_CONN,LV_OUTPUT);
            FOR IDX IN 1 .. LV_INVALID_LIST1.COUNT
            LOOP
                LV_OUTPUT1 :=
                       
                     LV_INVALID_LIST1 (IDX).ERROR_MESSAGE
                    || CHR (9)
                    || LV_INVALID_LIST1 (IDX).REPAIR_SITE
                    || CHR (9)
                    || LV_INVALID_LIST1 (IDX).FISCAL_YEAR
                    || CHR (9)
                    || LV_INVALID_LIST1 (IDX).QUARTER
                    || CHR (9)
                    || LV_INVALID_LIST1 (IDX).WEEK
                    || CHR (9)
                    || LV_INVALID_LIST1 (IDX).WEEKEND_DATE
                    || CHR (9)
                    || LV_INVALID_LIST1 (IDX).COST_TYPE
                    || CHR (9)
                    || LV_INVALID_LIST1 (IDX).SUB_REFURB_TYPE
                    || CHR (9)
                    || LV_INVALID_LIST1 (IDX).REFRESH_PID
                    || CHR (9)
                    || LV_INVALID_LIST1 (IDX).QTY
                    || CHR (9)
                    || LV_INVALID_LIST1 (IDX).UNIT_PRICE
                    || CHR (9)
                    || LV_INVALID_LIST1 (IDX).TOTAL_COST
                    || CHR (9)
                    || LV_INVALID_LIST1 (IDX).SERIAL_NUMBER
                    || CHR (9)
                    || LV_INVALID_LIST1 (IDX).ECO_NUMBER
                    || CHR (9)
                    || LV_INVALID_LIST1 (IDX).STATUS
                    || CHR (10);
                    UTL_SMTP.WRITE_DATA (LV_CONN,LV_OUTPUT1);
            END LOOP;

            UTL_SMTP.WRITE_DATA (LV_CONN, LV_OUTPUT);
        END IF;

        -- CLOSE DATA
        UTL_SMTP.CLOSE_DATA (LV_CONN);
        UTL_SMTP.QUIT (LV_CONN);
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            G_ERROR_MSG :=
                   SUBSTR (SQLERRM, 1, 200)
                || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
            CRPADM.RC_GLOBAL_ERROR_LOGGING (
                'NO DATA FOUND',
                G_ERROR_MSG,
                NULL,
                'CRPADM.RC_PID_LEVEL_SUMMARY_REPORT.RC_PID_LEVEL_SUMMARY_EMAIL',
                'PACKAGE',
                NULL,
                'N');
        WHEN OTHERS
        THEN
            G_ERROR_MSG :=
                   SUBSTR (SQLERRM, 1, 200)
                || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
            CRPADM.RC_GLOBAL_ERROR_LOGGING (
                'OTHERS',
                G_ERROR_MSG,
                NULL,
                'CRPADM.RC_SALES_FORECAST_DATA_EXTRACT.RC_PID_LEVEL_SUMMARY_EMAIL',
                'PACKAGE',
                NULL,
                'Y');
    END RC_PID_LEVEL_SUMMARY_EMAIL;
END RC_PID_LEVEL_SUMMARY_REPORT;
/