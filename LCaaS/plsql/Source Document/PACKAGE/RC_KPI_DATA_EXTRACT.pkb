CREATE OR REPLACE PACKAGE BODY CRPREP./*AppDB: 1039333*/                         "RC_KPI_DATA_EXTRACT" 
AS
    /***********************************************************************************************************
        || Object Name    : RC_KPI_DATA_EXTRACT
        || Modules        : KPI report
        || Description    : Fetching KPI details for differnt KPI screens
        || Modification History
        ||------------------------------------------------------------------------------------------------------
        ||Date              By                  Version        Comments
        ||------------------------------------------------------------------------------------------------------
        ||22-Dec-2016   Sai Chaitanya Garbham     1.0          Initial creation
        ||28-Dec-2016   Sweta Priyadarshi        1.1          Added procedures for advance filters and
        ||                                                            current qrt weekend level KPI details
        ||20-Mar-2017    Sweta Priyadarshi       1.2          Added procedures for intransit details
        ||15-Sept-2017   Sai Chaitanya          2.0          Multiple BPM to single Repair Partner implementation
        ||30-Oct-2017   Sweta Priyadarshi       2.1          Adding Cycle Count Upload
        ||27-Jul-2018  Bhaskar Reddivari       2.3          Automate the KPI Cycle Count Upload by removing the manual upload.
        ||03-Feb-2021  Sweta Priyadarshi                    Mutiple Repair Partner US changes
        ||------------------------------------------------------------------------------------------------------
    *************************************************************************************************************/

    /* Procedure to load data in Initial Page */
    PROCEDURE RC_KPI_INITIAL_PAGE_LOAD (
        i_user_id                  IN     VARCHAR2,
        i_repair_partner_id        IN     NUMBER,
        i_bpm                      IN     NUMBER,
        i_year                     IN     NUMBER,
        i_qtr                      IN     VARCHAR2,
        i_tab                      IN     NUMBER,
        o_wk_column_header_list       OUT CRPADM.T_NORMALISED_LIST,
        o_wk_page_load_list           OUT RC_WK_METRIC_DATA_LIST,
        o_qtr_column_header_list      OUT CRPADM.T_NORMALISED_LIST,
        o_qtr_page_load_list          OUT RC_QTR_METRIC_DATA_LIST,
        o_status                      OUT NUMBER)
    AS
        lv_wk_column_header_list    CRPADM.T_NORMALISED_LIST;
        lv_qtr_column_header_list   CRPADM.T_NORMALISED_LIST;
        lv_wk_page_load_list        RC_WK_METRIC_DATA_LIST;
        lv_wk_data_list             RC_WEEK_DATA_LIST;
        lv_qtr_data_list            RC_WEEK_DATA_LIST;
        lv_qtr_page_load_list       RC_QTR_METRIC_DATA_LIST;
        lv_user_id                  VARCHAR2 (100);
        lv_repair_partner_id        NUMBER;
        lv_bpm_id                   NUMBER;
        lv_year                     NUMBER;
        lv_qtr                      VARCHAR2 (100);
        lv_fiscal_qtr               VARCHAR2 (100);
        lv_tab                      NUMBER;
        lv_metric_data_query        VARCHAR2 (3500);
        lv_query                    CLOB;
        lv_constraint               VARCHAR2 (3500);
        lv_cum_metric_value         NUMBER := 0;
        lv_week_count               NUMBER := 0;
    BEGIN
        lv_user_id := i_user_id;
        lv_repair_partner_id := i_repair_partner_id;
        lv_bpm_id := i_bpm;
        lv_year := i_year;
        lv_qtr := UPPER (i_qtr);
        lv_tab := i_tab;
        o_status := 1;

        IF (lv_tab = 1)                                         -- Weekly view
        THEN
            lv_wk_column_header_list := CRPADM.T_NORMALISED_LIST ();
            lv_wk_page_load_list := RC_WK_METRIC_DATA_LIST ();
            lv_wk_data_list := RC_WEEK_DATA_LIST ();

            lv_qtr_column_header_list := CRPADM.T_NORMALISED_LIST ();
            lv_qtr_page_load_list := RC_QTR_METRIC_DATA_LIST ();

              SELECT fiscal_week_end_date
                BULK COLLECT INTO lv_wk_column_header_list
                FROM rmktgadm.cdm_time_hierarchy_dim
               WHERE     UPPER (FISCAL_QUARTER_NAME) = UPPER (lv_qtr)
                     AND FISCAL_WEEK_END_IND = 'Y'
            ORDER BY 1;

            lv_metric_data_query :=
                   '
         SELECT RC_WK_METRIC_DATA_OBJ (KPI_ID,
                                       KPI_NAME,
                                       WEEK_LIST,
                                       QTD,
                                       OVERRIDDEN_QTD)
           FROM (  SELECT MSTR.KPI_ID,
                          KPI_NAME,
                          NULL WEEK_LIST,
                          ROUND (AVG (kpi_QTD), 2) AS QTD,
                          ROUND (AVG (OVERRIDDEN_KPI_QTD), 2) AS OVERRIDDEN_QTD
                     FROM RC_KPI_SETUP STP
                          INNER JOIN RC_KPI_MASTER MSTR
                             ON     STP.KPI_ID = MSTR.KPI_ID
                                AND MSTR.FISCAL_YEAR = '
                || lv_year
                || '
                                AND MSTR.FISCAL_QUARTER = UPPER ('''
                || lv_qtr
                || ''')
                    WHERE ACTIVE_FLAG = '''
                || g_flag_yes
                || '''';

            IF (lv_repair_partner_id != -1)
            THEN
                lv_constraint :=
                       ' AND REPAIR_PARTNER_ID = '
                    || lv_repair_partner_id
                    || ' ';

                IF (lv_bpm_id != -1)
                THEN
                    lv_constraint :=
                           lv_constraint
                        || ' AND REPAIR_PARTNER_ID IN (SELECT DISTINCT REPAIR_PARTNER_ID FROM CRPADM.RC_REPAIR_PARTNER_BPM_SETUP  WHERE BPM_ID = '
                        || lv_bpm_id
                        || ')';
                END IF;
            END IF;

            lv_metric_data_query :=
                   lv_metric_data_query
                || lv_constraint
                || ' GROUP BY MSTR.KPI_ID, KPI_NAME
                 ORDER BY 1)';

            EXECUTE IMMEDIATE lv_metric_data_query
                BULK COLLECT INTO lv_wk_page_load_list;

            FOR idx IN 1 .. lv_wk_page_load_list.COUNT
            LOOP
                IF (lv_wk_page_load_list (idx).KPI_ID = 1) -- Commit vs Actuals
                THEN
                    lv_constraint := ' ';
                    lv_query :=
                           'SELECT RC_WEEK_DATA_OBJ (WEEKEND_DATE, METRIC_VALUE, COLOR)
                 FROM (  SELECT FISCAL_WEEKEND_DATE AS WEEKEND_DATE,
                                METRIC_VALUE,
                                (SELECT COLOR_CODE
                                   FROM RC_KPI_COLOR_MAP CLR
                                        INNER JOIN RC_KPI_SCORE_RANGE RNG
                                           ON (    (   RNG.SCORE =
                                                          CLR.SCORE_RANGE_MIN
                                                    OR RNG.SCORE =
                                                          CLR.SCORE_RANGE_MAX)
                                               AND RNG.KPI_ID = 1
                                               AND RNG.QUARTER_NAME = '''
                        || lv_qtr
                        || ''')
                                  WHERE     METRIC_VALUE >= RNG.SCORE_MIN
                                        AND METRIC_VALUE <= RNG.SCORE_MAX)
                                   AS COLOR
                           FROM (  SELECT PC_ACT.FISCAL_WEEKEND_DATE,
                                          CASE
                                             WHEN SUM (PC_ACT.CALCULATED_VALUE) =
                                                     0
                                             THEN
                                                0
                                             ELSE
                                                          ROUND( SUM (
                                                                 PC_ACT.CUM_ACTUALS) /   SUM (PC_ACT.CALCULATED_VALUE)  
                                                         * 100,2)
                                          END
                                             METRIC_VALUE
                                     FROM RC_KPI_PC_ACT pc_act
                                    WHERE PC_ACT.FISCAL_WEEKEND_DATE IN (SELECT DISTINCT FISCAL_WEEK_END_DATE
                                                                           FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                                                                          WHERE   TRUNC(CALENDAR_DATE)<TRUNC(SYSDATE) AND  UPPER (
                                                                                       FISCAL_QUARTER_NAME) =
                                                                                       UPPER (
                                                                                          '''
                        || lv_qtr
                        --                        || ''')
                        --                                                                                AND FISCAL_WEEK_END_IND =
                        --                                                                                       '''
                        --                        || g_flag_yes
                        || '''))';

                    IF (lv_repair_partner_id != -1)
                    THEN
                        lv_constraint :=
                               ' AND REPAIR_PARTNER_ID = '
                            || lv_repair_partner_id
                            || ' ';
                    ELSIF (lv_bpm_id != -1)
                    THEN
                        lv_constraint :=
                               ' AND REPAIR_PARTNER_ID IN (SELECT DISTINCT REPAIR_PARTNER_ID FROM CRPADM.RC_REPAIR_PARTNER_BPM_SETUP WHERE BPM_ID = '
                            || lv_bpm_id
                            || ')';
                    END IF;

                    lv_query := lv_query || lv_constraint || '
                                 GROUP BY PC_ACT.FISCAL_WEEKEND_DATE)
                       ORDER BY 1)';

                    EXECUTE IMMEDIATE lv_query
                        BULK COLLECT INTO lv_wk_data_list;

                    lv_wk_page_load_list (idx).WEEK_LIST := lv_wk_data_list;
                ELSIF (lv_wk_page_load_list (idx).KPI_ID = 2)    -- TSRM vs PC
                THEN
                    lv_constraint := ' ';
                    lv_query := ' ';
                    lv_query :=
                           'SELECT RC_WEEK_DATA_OBJ (WEEKEND_DATE, METRIC_VALUE, COLOR)
                 FROM (  SELECT FISCAL_WEEKEND_DATE AS WEEKEND_DATE,
                                METRIC_VALUE,
                                (SELECT COLOR_CODE
                                   FROM RC_KPI_COLOR_MAP CLR
                                        INNER JOIN RC_KPI_SCORE_RANGE RNG
                                           ON (    (   RNG.SCORE =
                                                          CLR.SCORE_RANGE_MIN
                                                    OR RNG.SCORE =
                                                          CLR.SCORE_RANGE_MAX)
                                               AND RNG.KPI_ID = 2
                                               AND RNG.QUARTER_NAME ='''
                        || lv_qtr
                        || ''')
                                  WHERE     METRIC_VALUE >= RNG.SCORE_MIN
                                        AND METRIC_VALUE <= RNG.SCORE_MAX)
                                   AS COLOR
                           FROM (  SELECT FISCAL_WEEKEND_DATE,
                                          CASE
                                             WHEN SUM (TSRM_PC.CALCULATED_VALUE) =
                                                     0
                                             THEN
                                                0
                                             ELSE
                                                            ROUND( SUM (
                                                                 TSRM_PC.CUM_PC) / SUM (
                                                                 TSRM_PC.CALCULATED_VALUE)
                                                         * 100,2)
                                          END
                                             METRIC_VALUE
                                     FROM RC_KPI_TSRM_PC TSRM_PC
                                    WHERE TSRM_PC.FISCAL_WEEKEND_DATE IN (SELECT DISTINCT FISCAL_WEEK_END_DATE
                                                                            FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                                                                           WHERE  TRUNC(CALENDAR_DATE)<TRUNC(SYSDATE) AND  UPPER (
                                                                                        FISCAL_QUARTER_NAME) =
                                                                                        UPPER ('''
                        || lv_qtr
                        --                        || ''')
                        --                                                                                 AND FISCAL_WEEK_END_IND =
                        --                                                                                        '''
                        --                        || g_flag_yes
                        || ''')) ';


                    IF (lv_repair_partner_id != -1)
                    THEN
                        lv_constraint :=
                               ' AND REPAIR_PARTNER_ID = '
                            || lv_repair_partner_id
                            || ' ';
                    ELSIF (lv_bpm_id != -1)
                    THEN
                        lv_constraint :=
                               ' AND REPAIR_PARTNER_ID IN (SELECT DISTINCT REPAIR_PARTNER_ID FROM CRPADM.RC_REPAIR_PARTNER_BPM_SETUP WHERE BPM_ID = '
                            || lv_bpm_id
                            || ')';
                    END IF;

                    lv_query :=
                           lv_query
                        || lv_constraint
                        || '                                                        
                                 GROUP BY TSRM_PC.FISCAL_WEEKEND_DATE)
                       ORDER BY 1)';

                    EXECUTE IMMEDIATE lv_query
                        BULK COLLECT INTO lv_wk_data_list;

                    lv_wk_page_load_list (idx).WEEK_LIST := lv_wk_data_list;
                ELSIF (lv_wk_page_load_list (idx).KPI_ID = 3)    -- In Transit
                THEN
                    lv_constraint := ' ';
                    lv_query := ' ';
                    lv_query :=
                           'SELECT RC_WEEK_DATA_OBJ (WEEKEND_DATE, METRIC_VALUE, COLOR)
                 FROM (  SELECT FISCAL_WEEKEND_DATE AS WEEKEND_DATE,
                                METRIC_VALUE,
                                (SELECT COLOR_CODE
                                   FROM RC_KPI_COLOR_MAP CLR
                                        INNER JOIN RC_KPI_SCORE_RANGE RNG
                                           ON (    (   RNG.SCORE =
                                                          CLR.SCORE_RANGE_MIN
                                                    OR RNG.SCORE =
                                                          CLR.SCORE_RANGE_MAX)
                                               AND RNG.KPI_ID = 3
                                               AND RNG.QUARTER_NAME ='''
                        || lv_qtr
                        || ''')
                                  WHERE     METRIC_VALUE >= RNG.SCORE_MIN
                                        AND METRIC_VALUE <= RNG.SCORE_MAX)
                                   AS COLOR
                           FROM (  SELECT FISCAL_WEEKEND_DATE,
                                          SUM(TOTAL_DELAY) METRIC_VALUE
                                   FROM RC_KPI_INTRANSIT INTRAN
                                   WHERE INTRAN.FISCAL_QUARTER  =
                                                           UPPER ('''
                        || lv_qtr
                        || ''') ';

                    IF (lv_repair_partner_id != -1)
                    THEN
                        lv_constraint :=
                               ' AND INTRAN.REPAIR_PARTNER_ID = '
                            || lv_repair_partner_id
                            || ' ';
                    ELSIF (lv_bpm_id != -1)
                    THEN
                        lv_constraint :=
                               ' AND INTRAN.REPAIR_PARTNER_ID IN (SELECT DISTINCT REPAIR_PARTNER_ID FROM CRPADM.RC_REPAIR_PARTNER_BPM_SETUP WHERE BPM_ID = '
                            || lv_bpm_id
                            || ')';
                    END IF;

                    lv_query :=
                           lv_query
                        || lv_constraint
                        || ' GROUP BY INTRAN.FISCAL_WEEKEND_DATE)
                       ORDER BY 1)';

                    EXECUTE IMMEDIATE lv_query
                        BULK COLLECT INTO lv_wk_data_list;

                    lv_wk_page_load_list (idx).WEEK_LIST := lv_wk_data_list;
                ELSIF (lv_wk_page_load_list (idx).KPI_ID = 4)   -- Cycle Count
                THEN
                    lv_constraint := ' ';
                    lv_query := ' ';
                    lv_query :=
                           'SELECT RC_WEEK_DATA_OBJ (WEEKEND_DATE, METRIC_VALUE, COLOR)
                             FROM (  SELECT FISCAL_WEEKEND_DATE AS WEEKEND_DATE,
                                            METRIC_VALUE,
                                            (SELECT COLOR_CODE
                                               FROM RC_KPI_COLOR_MAP CLR
                                                    INNER JOIN RC_KPI_SCORE_RANGE RNG
                                                       ON (    (   RNG.SCORE =
                                                                      CLR.SCORE_RANGE_MIN
                                                                OR RNG.SCORE =
                                                                      CLR.SCORE_RANGE_MAX)
                                                           AND RNG.KPI_ID = 4
                                                           AND RNG.QUARTER_NAME ='''
                        || lv_qtr
                        || ''')
                                              WHERE     METRIC_VALUE >= RNG.SCORE_MIN
                                                    AND METRIC_VALUE <= RNG.SCORE_MAX)
                                               AS COLOR
                                       FROM (  SELECT FISCAL_WEEKEND_DATE,
                                       CASE WHEN ACTUAL_COUNT_VALUES > 0
                                       THEN
                                               ROUND(       (  (  (  ACTUAL_COUNT_VALUES
                                                         - SEC_COUNT_VALUES)
                                                      / ACTUAL_COUNT_VALUES)
                                                   * 100),2)
                                                   ELSE 0
                                                   END METRIC_VALUE
                                               FROM (SELECT *
                                                     FROM (  SELECT --REPAIR_PARTNER_ID,
                                                                    FISCAL_WEEKEND_DATE,
                                                                    SUM (CYCLE_COUNT_VALUES)
                                                                       CYCLE_COUNT_VALUES,
                                                                    CYCLE_COUNT_VALUES_TYPE
                                                               FROM RC_KPI_CYCLE_COUNT
                                               WHERE  FISCAL_QUARTER  =
                                                                       UPPER ('''
                        || lv_qtr
                        || ''') ';

                    IF (lv_repair_partner_id != -1)
                    THEN
                        lv_constraint :=
                               ' AND REPAIR_PARTNER_ID = '
                            || lv_repair_partner_id
                            || ' ';
                    ELSIF (lv_bpm_id != -1)
                    THEN
                        lv_constraint :=
                               ' AND REPAIR_PARTNER_ID IN (SELECT DISTINCT REPAIR_PARTNER_ID FROM CRPADM.RC_REPAIR_PARTNER_BPM_SETUP WHERE BPM_ID = '
                            || lv_bpm_id
                            || ')';
                    END IF;

                    IF lv_year <= 2018
                    THEN
                        lv_query :=
                               lv_query
                            || lv_constraint
                            || ' GROUP BY --REPAIR_PARTNER_ID,
                                        FISCAL_WEEKEND_DATE,
                                        CYCLE_COUNT_VALUES_TYPE) PIVOT (SUM (CYCLE_COUNT_VALUES) AS COUNT_VALUES
                                            FOR (CYCLE_COUNT_VALUES_TYPE)
                                            IN  (''No. of Variants (second pass)'' AS SEC,
                                            ''No. of Actual Counts'' AS ACTUAL))))
                                   ORDER BY 1)';
                    ELSE
                        lv_query :=
                               lv_query
                            || lv_constraint
                            || ' AND CYCLE_COUNT_ID = 1                     --Sprint 22 change Only Repair Site KPI % should be shown on dashboard.
                                  GROUP BY --REPAIR_PARTNER_ID,
                                        FISCAL_WEEKEND_DATE,
                                        CYCLE_COUNT_VALUES_TYPE) PIVOT (SUM (CYCLE_COUNT_VALUES) AS COUNT_VALUES
                                            FOR (CYCLE_COUNT_VALUES_TYPE)
                                            IN  (''No. of Variants'' AS SEC,
                                            ''System Inventory'' AS ACTUAL))))
                                   ORDER BY 1)';
                    END IF;

                    EXECUTE IMMEDIATE lv_query
                        BULK COLLECT INTO lv_wk_data_list;

                    lv_wk_page_load_list (idx).WEEK_LIST := lv_wk_data_list;
                END IF;

                SELECT DISTINCT UPPER (fiscal_quarter_name)
                  INTO lv_fiscal_qtr
                  FROM rmktgadm.cdm_time_hierarchy_dim
                 WHERE CURRENT_FISCAL_QUARTER_FLAG = 'Y';


                IF (    lv_repair_partner_id = -1
                    AND lv_bpm_id = -1
                    AND lv_qtr = lv_fiscal_qtr)
                THEN
                    IF (lv_wk_data_list IS NOT NULL)
                    THEN
                        lv_cum_metric_value := 0;

                        SELECT COUNT (DISTINCT FISCAL_WEEK_END_DATE)
                          INTO lv_week_count
                          FROM rmktgadm.cdm_time_hierarchy_dim
                         WHERE     FISCAL_QUARTER_NAME = UPPER (lv_qtr)
                               AND FISCAL_WEEK_END_DATE <
                                   (SELECT CHL_END_TIMESTAMP
                                      FROM CRPADM.RC_CRON_HISTORY_LOG
                                     WHERE CHL_CRON_NAME = 'RC_KPI_ENGINE');

                        FOR idx1 IN 1 .. lv_week_count
                        LOOP
                            IF idx1 > lv_wk_data_list.COUNT
                            THEN
                                lv_cum_metric_value :=
                                    lv_cum_metric_value + 0;
                            ELSE
                                lv_cum_metric_value :=
                                      lv_cum_metric_value
                                    + lv_wk_data_list (idx1).metric_value;
                            END IF;
                        END LOOP;

                        CASE
                            WHEN lv_week_count > 0
                            THEN
                                lv_cum_metric_value :=
                                    ROUND (
                                        (lv_cum_metric_value / lv_week_count),
                                        2);
                            ELSE
                                lv_cum_metric_value := 0;
                        END CASE;

                        lv_wk_page_load_list (idx).QTD := lv_cum_metric_value;
                        lv_wk_page_load_list (idx).OVERRIDDEN_QTD := NULL;
                    END IF;
                ELSIF (    lv_repair_partner_id = -1
                       AND lv_bpm_id = -1
                       AND lv_qtr != lv_fiscal_qtr)
                THEN
                    IF (lv_wk_data_list IS NOT NULL)
                    THEN
                        lv_cum_metric_value := 0;

                        SELECT COUNT (DISTINCT FISCAL_WEEK_END_DATE)
                          INTO lv_week_count
                          FROM rmktgadm.cdm_time_hierarchy_dim
                         WHERE     FISCAL_QUARTER_NAME = UPPER (lv_qtr)
                               AND FISCAL_WEEK_END_DATE <
                                   (SELECT CHL_END_TIMESTAMP
                                      FROM CRPADM.RC_CRON_HISTORY_LOG
                                     WHERE CHL_CRON_NAME = 'RC_KPI_ENGINE');

                        FOR idx1 IN 1 .. lv_week_count
                        LOOP
                            IF idx1 > lv_wk_data_list.COUNT
                            THEN
                                lv_cum_metric_value :=
                                    lv_cum_metric_value + 0;
                            ELSE
                                lv_cum_metric_value :=
                                      lv_cum_metric_value
                                    + lv_wk_data_list (idx1).metric_value;
                            END IF;
                        END LOOP;

                        CASE
                            WHEN lv_week_count > 0
                            THEN
                                lv_cum_metric_value :=
                                    ROUND (
                                        (lv_cum_metric_value / lv_week_count),
                                        2);
                            ELSE
                                lv_cum_metric_value := 0;
                        END CASE;

                        lv_wk_page_load_list (idx).QTD := lv_cum_metric_value;
                        lv_wk_page_load_list (idx).OVERRIDDEN_QTD := NULL;
                    END IF;
                ELSIF (lv_repair_partner_id != -1 AND lv_bpm_id != -1)
                THEN
                    IF (lv_wk_data_list IS NOT NULL)
                    THEN
                        lv_cum_metric_value := 0;

                        SELECT COUNT (DISTINCT FISCAL_WEEK_END_DATE)
                          INTO lv_week_count
                          FROM rmktgadm.cdm_time_hierarchy_dim
                         WHERE     FISCAL_QUARTER_NAME = UPPER (lv_qtr)
                               AND FISCAL_WEEK_END_DATE <
                                   (SELECT CHL_END_TIMESTAMP
                                      FROM CRPADM.RC_CRON_HISTORY_LOG
                                     WHERE CHL_CRON_NAME = 'RC_KPI_ENGINE');


                        FOR idx1 IN 1 .. lv_week_count
                        LOOP
                            IF idx1 > lv_wk_data_list.COUNT
                            THEN
                                lv_cum_metric_value :=
                                    lv_cum_metric_value + 0;
                            ELSE
                                lv_cum_metric_value :=
                                      lv_cum_metric_value
                                    + lv_wk_data_list (idx1).metric_value;
                            END IF;
                        END LOOP;

                        CASE
                            WHEN lv_week_count > 0
                            THEN
                                lv_cum_metric_value :=
                                    ROUND (
                                        (lv_cum_metric_value / lv_week_count),
                                        2);
                            ELSE
                                lv_cum_metric_value := 0;
                        END CASE;

                        lv_wk_page_load_list (idx).QTD := lv_cum_metric_value;
                    END IF;
                ELSIF (lv_repair_partner_id <> -1 AND lv_bpm_id = -1)
                THEN
                    IF (lv_wk_data_list IS NOT NULL)
                    THEN
                        lv_cum_metric_value := 0;

                        SELECT COUNT (DISTINCT FISCAL_WEEK_END_DATE)
                          INTO lv_week_count
                          FROM rmktgadm.cdm_time_hierarchy_dim
                         WHERE     FISCAL_QUARTER_NAME = UPPER (lv_qtr)
                               AND FISCAL_WEEK_END_DATE <
                                   (SELECT CHL_END_TIMESTAMP
                                      FROM CRPADM.RC_CRON_HISTORY_LOG
                                     WHERE CHL_CRON_NAME = 'RC_KPI_ENGINE');


                        FOR idx1 IN 1 .. lv_week_count
                        LOOP
                            IF idx1 > lv_wk_data_list.COUNT
                            THEN
                                lv_cum_metric_value :=
                                    lv_cum_metric_value + 0;
                            ELSE
                                lv_cum_metric_value :=
                                      lv_cum_metric_value
                                    + lv_wk_data_list (idx1).metric_value;
                            END IF;
                        END LOOP;

                        CASE
                            WHEN lv_week_count > 0
                            THEN
                                lv_cum_metric_value :=
                                    ROUND (
                                        (lv_cum_metric_value / lv_week_count),
                                        2);
                            ELSE
                                lv_cum_metric_value := 0;
                        END CASE;

                        lv_wk_page_load_list (idx).QTD := lv_cum_metric_value;
                        lv_wk_page_load_list (idx).OVERRIDDEN_QTD := NULL;
                    END IF;
                END IF;
            END LOOP;


            o_wk_column_header_list := lv_wk_column_header_list;
            o_wk_page_load_list := lv_wk_page_load_list;
            o_qtr_column_header_list := lv_qtr_column_header_list;
            o_qtr_page_load_list := lv_qtr_page_load_list;
        ELSIF (lv_tab = 2)                                   -- Quarterly view
        THEN
            lv_qtr_column_header_list := CRPADM.T_NORMALISED_LIST ();
            lv_qtr_page_load_list := RC_QTR_METRIC_DATA_LIST ();
            lv_qtr_data_list := RC_WEEK_DATA_LIST ();

            o_wk_column_header_list := CRPADM.T_NORMALISED_LIST ('-1');
            o_wk_page_load_list := RC_WK_METRIC_DATA_LIST ();


              SELECT FISCAL_QUARTER_NAME
                BULK COLLECT INTO lv_qtr_column_header_list
                FROM (  SELECT DISTINCT FISCAL_QUARTER_NAME, FISCAL_QUARTER_ID
                          FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                         WHERE     FISCAL_YEAR_NUMBER IN (lv_year - 1, lv_year)
                               AND CALENDAR_DATE <= TRUNC (SYSDATE)
                      ORDER BY FISCAL_QUARTER_ID DESC)
               WHERE ROWNUM <= 4
            ORDER BY FISCAL_QUARTER_ID;

            SELECT RC_QTR_METRIC_DATA_OBJ (KPI_ID, KPI_NAME, QTR_LIST)
              BULK COLLECT INTO lv_qtr_page_load_list
              FROM (  SELECT KPI_ID, KPI_NAME, NULL QTR_LIST
                        FROM RC_KPI_SETUP
                       WHERE ACTIVE_FLAG = 'Y'
                    ORDER BY 1);

            FOR idx IN 1 .. lv_qtr_page_load_list.COUNT
            LOOP
                IF (lv_qtr_page_load_list (idx).KPI_ID = 1)
                THEN
                    lv_query :=
                           'SELECT RC_WEEK_DATA_OBJ (WEEKEND_DATE, METRIC_VALUE, COLOR)
                 FROM (  SELECT FISCAL_QUARTER_NAME AS WEEKEND_DATE,
                                KPI_PERCENTAGE AS METRIC_VALUE,
                                (SELECT COLOR_CODE
                                   FROM RC_KPI_COLOR_MAP CLR
                                        INNER JOIN RC_KPI_SCORE_RANGE RNG
                                           ON (    (   RNG.SCORE =
                                                          CLR.SCORE_RANGE_MIN
                                                    OR RNG.SCORE =
                                                          CLR.SCORE_RANGE_MAX)
                                               AND RNG.KPI_ID = 1
                                               AND RNG.QUARTER_NAME = '''
                        || lv_qtr
                        || ''')
                                  WHERE     KPI_PERCENTAGE >= RNG.SCORE_MIN
                                        AND KPI_PERCENTAGE <= RNG.SCORE_MAX)
                                   AS COLOR
                           FROM (  SELECT DISTINCT
                                          CDM.FISCAL_QUARTER_NAME,
                                          CASE
                              WHEN SUM (PC_ACT.CALCULATED_VALUE) = 0
                              THEN
                                 0
                              ELSE
                                  ROUND((  SUM (
                                                        PC_ACT.CUM_ACTUALS)
                                                   / SUM (PC_ACT.CALCULATED_VALUE))
                                                * 100,2)
                           END
                              KPI_PERCENTAGE
                                     FROM RC_KPI_PC_ACT PC_ACT
                                          INNER JOIN
                                          RMKTGADM.CDM_TIME_HIERARCHY_DIM CDM
                                             ON     PC_ACT.FISCAL_WEEKEND_DATE =
                                                       CDM.FISCAL_WEEK_END_DATE
                                                AND CDM.FISCAL_QUARTER_NAME IN (SELECT FISCAL_QUARTER_NAME
             FROM (  SELECT DISTINCT FISCAL_QUARTER_NAME, FISCAL_QUARTER_ID
                       FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                      WHERE     FISCAL_YEAR_NUMBER IN ('
                        || (lv_year - 1)
                        || ','
                        || lv_year
                        || ') AND CALENDAR_DATE <= TRUNC (SYSDATE)
                   ORDER BY FISCAL_QUARTER_ID DESC)
            WHERE ROWNUM <= 4) ';

                    IF (lv_repair_partner_id != -1)
                    THEN
                        lv_constraint :=
                               ' AND REPAIR_PARTNER_ID = '
                            || lv_repair_partner_id
                            || ' ';
                    ELSIF (lv_bpm_id != -1)
                    THEN
                        lv_constraint :=
                               ' AND REPAIR_PARTNER_ID IN (SELECT DISTINCT REPAIR_PARTNER_ID FROM CRPADM.RC_REPAIR_PARTNER_BPM_SETUP WHERE BPM_ID = '
                            || lv_bpm_id
                            || ')';
                    END IF;

                    lv_query :=
                           lv_query
                        || lv_constraint
                        || '  GROUP BY CDM.FISCAL_QUARTER_NAME)
                       ORDER BY 1)';

                    EXECUTE IMMEDIATE lv_query
                        BULK COLLECT INTO lv_qtr_data_list;

                    lv_qtr_page_load_list (idx).QTR_LIST := lv_qtr_data_list;
                ELSIF (lv_qtr_page_load_list (idx).KPI_ID = 2)   -- TSRM vs PC
                THEN
                    lv_query :=
                           'SELECT RC_WEEK_DATA_OBJ (WEEKEND_DATE, METRIC_VALUE, COLOR)
                 FROM (  SELECT FISCAL_QUARTER_NAME AS WEEKEND_DATE,
                                KPI_PERCENTAGE AS METRIC_VALUE,
                                (SELECT COLOR_CODE
                                   FROM RC_KPI_COLOR_MAP CLR
                                        INNER JOIN RC_KPI_SCORE_RANGE RNG
                                           ON (    (   RNG.SCORE =
                                                          CLR.SCORE_RANGE_MIN
                                                    OR RNG.SCORE =
                                                          CLR.SCORE_RANGE_MAX)
                                               AND RNG.KPI_ID = 2
                                               AND RNG.QUARTER_NAME = '''
                        || lv_qtr
                        || ''')
                                  WHERE     KPI_PERCENTAGE >= RNG.SCORE_MIN
                                        AND KPI_PERCENTAGE <= RNG.SCORE_MAX)
                                   AS COLOR
                           FROM (  SELECT DISTINCT
                                          CDM.FISCAL_QUARTER_NAME,
                                          CASE
                              WHEN SUM (TSRM_PC.CALCULATED_VALUE) = 0
                              THEN
                                 0
                              ELSE
                                  ROUND( (  SUM (
                                                        TSRM_PC.CUM_PC)
                                                   / SUM (TSRM_PC.CALCULATED_VALUE))
                                                * 100,2)
                           END
                              KPI_PERCENTAGE
                                     FROM RC_KPI_TSRM_PC TSRM_PC
                                          INNER JOIN
                                          RMKTGADM.CDM_TIME_HIERARCHY_DIM CDM
                                             ON     TSRM_PC.FISCAL_WEEKEND_DATE =
                                                       CDM.FISCAL_WEEK_END_DATE
                                                AND CDM.FISCAL_QUARTER_NAME IN (SELECT FISCAL_QUARTER_NAME
             FROM (  SELECT DISTINCT FISCAL_QUARTER_NAME, FISCAL_QUARTER_ID
                       FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                      WHERE     FISCAL_YEAR_NUMBER IN ('
                        || (lv_year - 1)
                        || ','
                        || lv_year
                        || ')
                            AND CALENDAR_DATE <= TRUNC (SYSDATE)
                   ORDER BY FISCAL_QUARTER_ID DESC)
            WHERE ROWNUM <= 4) ';

                    IF (lv_repair_partner_id != -1)
                    THEN
                        lv_constraint :=
                               ' AND REPAIR_PARTNER_ID = '
                            || lv_repair_partner_id
                            || ' ';
                    ELSIF (lv_bpm_id != -1)
                    THEN
                        lv_constraint :=
                               ' AND REPAIR_PARTNER_ID IN (SELECT DISTINCT REPAIR_PARTNER_ID FROM CRPADM.RC_REPAIR_PARTNER_BPM_SETUP WHERE BPM_ID = '
                            || lv_bpm_id
                            || ')';
                    END IF;

                    lv_query :=
                           lv_query
                        || lv_constraint
                        || ' GROUP BY CDM.FISCAL_QUARTER_NAME)
                       ORDER BY 1)';

                    EXECUTE IMMEDIATE lv_query
                        BULK COLLECT INTO lv_qtr_data_list;

                    lv_qtr_page_load_list (idx).QTR_LIST := lv_qtr_data_list;
                ELSIF (lv_qtr_page_load_list (idx).KPI_ID = 3)   -- In Transit
                THEN
                    lv_query :=
                           'SELECT RC_WEEK_DATA_OBJ (WEEKEND_DATE, METRIC_VALUE, COLOR)
                      FROM (SELECT FISCAL_QUARTER AS WEEKEND_DATE,
                                   TOTAL_DELAY AS METRIC_VALUE,
                                   (SELECT COLOR_CODE
                                      FROM RC_KPI_COLOR_MAP CLR
                                           INNER JOIN RC_KPI_SCORE_RANGE RNG
                                              ON (    (   RNG.SCORE = CLR.SCORE_RANGE_MIN
                                                       OR RNG.SCORE = CLR.SCORE_RANGE_MAX)
                                                  AND RNG.KPI_ID = 3
                                               AND RNG.QUARTER_NAME = '''
                        || lv_qtr
                        || ''')
                                     WHERE     TOTAL_DELAY >= RNG.SCORE_MIN
                                           AND TOTAL_DELAY <= RNG.SCORE_MAX)
                                      AS COLOR
                              FROM (SELECT DISTINCT
                                           INTRAN.FISCAL_QUARTER, SUM (TOTAL_DELAY) TOTAL_DELAY
                                      FROM RC_KPI_INTRANSIT INTRAN
                                     WHERE INTRAN.FISCAL_QUARTER IN (SELECT FISCAL_QUARTER_NAME
                                                                       FROM (SELECT DISTINCT
                                                                                    FISCAL_QUARTER_NAME,
                                                                                    FISCAL_QUARTER_ID
                                                                               FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                                                                              WHERE FISCAL_YEAR_NUMBER IN ('
                        || (lv_year - 1)
                        || ','
                        || lv_year
                        || ')
                       AND CALENDAR_DATE <= TRUNC (SYSDATE)
               ORDER BY FISCAL_QUARTER_ID DESC)
                WHERE ROWNUM <= 4) ';

                    IF (lv_repair_partner_id != -1)
                    THEN
                        lv_constraint :=
                               ' AND INTRAN.REPAIR_PARTNER_ID = '
                            || lv_repair_partner_id
                            || ' ';
                    ELSIF (lv_bpm_id != -1)
                    THEN
                        lv_constraint :=
                               ' AND INTRAN.REPAIR_PARTNER_ID IN (SELECT DISTINCT REPAIR_PARTNER_ID FROM CRPADM.RC_REPAIR_PARTNER_BPM_SETUP WHERE BPM_ID = '
                            || lv_bpm_id
                            || ')';
                    END IF;

                    lv_query :=
                           lv_query
                        || lv_constraint
                        || ' GROUP BY INTRAN.FISCAL_QUARTER)
                       ORDER BY 1)';

                    EXECUTE IMMEDIATE lv_query
                        BULK COLLECT INTO lv_qtr_data_list;

                    lv_qtr_page_load_list (idx).QTR_LIST := lv_qtr_data_list;
                ELSIF (lv_qtr_page_load_list (idx).KPI_ID = 4)  -- Cycle Count
                THEN
                    lv_query :=
                           'SELECT RC_WEEK_DATA_OBJ (WEEKEND_DATE, METRIC_VALUE, COLOR)
                                  FROM (SELECT FISCAL_QUARTER AS WEEKEND_DATE,
                                               METRIC_VALUE,
                                               (SELECT COLOR_CODE
                                                  FROM RC_KPI_COLOR_MAP CLR
                                                       INNER JOIN RC_KPI_SCORE_RANGE RNG
                                                          ON (    (   RNG.SCORE = CLR.SCORE_RANGE_MIN
                                                                   OR RNG.SCORE = CLR.SCORE_RANGE_MAX)
                                                              AND RNG.KPI_ID = 4
                                                              AND RNG.QUARTER_NAME = '''
                        || lv_qtr
                        || ''')
                                                 WHERE     METRIC_VALUE >= RNG.SCORE_MIN
                                                       AND METRIC_VALUE <= RNG.SCORE_MAX)
                                                  AS COLOR
                                          FROM (SELECT 
                            FISCAL_QUARTER,
                            CASE WHEN ACTUAL_COUNT_VALUES > 0
                            THEN
                   ROUND ((  ( (ACTUAL_COUNT_VALUES - SEC_COUNT_VALUES) / ACTUAL_COUNT_VALUES)
                    * 100),2)
                    ELSE 0
                    END
                      METRIC_VALUE
              FROM (SELECT *
                      FROM (  SELECT --REPAIR_PARTNER_ID,
                                     (SELECT DISTINCT FISCAL_QUARTER_NAME
                                            FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                                            WHERE FISCAL_WEEK_END_DATE = FISCAL_WEEKEND_DATE)
                                     FISCAL_QUARTER,
                                     --FISCAL_WEEKEND_DATE,
                                     SUM (CYCLE_COUNT_VALUES) CYCLE_COUNT_VALUES,
                                     CYCLE_COUNT_VALUES_TYPE
                                FROM RC_KPI_CYCLE_COUNT
                                                 WHERE FISCAL_QUARTER IN (SELECT FISCAL_QUARTER_NAME
                                                                                   FROM (SELECT DISTINCT
                                                                                                FISCAL_QUARTER_NAME,
                                                                                                FISCAL_QUARTER_ID
                                                                                           FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                                                                                          WHERE FISCAL_YEAR_NUMBER IN ('
                        || (lv_year - 1)
                        || ','
                        || lv_year
                        || ')
                                   AND CALENDAR_DATE <= TRUNC (SYSDATE)
                           ORDER BY FISCAL_QUARTER_ID DESC)
                            WHERE ROWNUM <= 4) ';

                    IF (lv_repair_partner_id != -1)
                    THEN
                        lv_constraint :=
                               ' AND REPAIR_PARTNER_ID = '
                            || lv_repair_partner_id
                            || ' ';
                    ELSIF (lv_bpm_id != -1)
                    THEN
                        lv_constraint :=
                               ' AND REPAIR_PARTNER_ID IN (SELECT DISTINCT REPAIR_PARTNER_ID FROM CRPADM.RC_REPAIR_PARTNER_BPM_SETUP WHERE BPM_ID = '
                            || lv_bpm_id
                            || ')';
                    END IF;

                    IF lv_year <= 2018
                    THEN
                        lv_query :=
                               lv_query
                            || lv_constraint
                            || ' GROUP BY --REPAIR_PARTNER_ID,
                                     FISCAL_WEEKEND_DATE,
                                     CYCLE_COUNT_VALUES_TYPE) PIVOT (SUM (CYCLE_COUNT_VALUES) AS COUNT_VALUES
                                                              FOR (CYCLE_COUNT_VALUES_TYPE)
                                                              IN  (''No. of Variants (second pass)'' AS SEC,
                                                                  ''No. of Actual Counts'' AS ACTUAL)))
                                   ORDER BY 1))';
                    ELSE
                        lv_query :=
                               lv_query
                            || lv_constraint
                            || ' GROUP BY --REPAIR_PARTNER_ID,
                                     FISCAL_WEEKEND_DATE,
                                     CYCLE_COUNT_VALUES_TYPE) PIVOT (SUM (CYCLE_COUNT_VALUES) AS COUNT_VALUES
                                                              FOR (CYCLE_COUNT_VALUES_TYPE)
                                                              IN  (''No. of Variants'' AS SEC,
                                                                  ''System Inventory'' AS ACTUAL)))
                                   ORDER BY 1))';
                    END IF;

                    EXECUTE IMMEDIATE lv_query
                        BULK COLLECT INTO lv_qtr_data_list;

                    lv_qtr_page_load_list (idx).QTR_LIST := lv_qtr_data_list;
                END IF;
            END LOOP;

            o_qtr_column_header_list := lv_qtr_column_header_list;
            o_qtr_page_load_list := lv_qtr_page_load_list;
        END IF;
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
                'RC_KPI_DATA_EXTRACT.RC_KPI_INITIAL_PAGE_LOAD',
                'PROCEDURE',
                i_user_id,
                'N');
    END RC_KPI_INITIAL_PAGE_LOAD;

    /* Procedure to fetch Year list and Quarter list in Filters */
    PROCEDURE RC_KPI_FILTERS_LIST (
        i_user_id                  IN     VARCHAR2,
        o_bpm_list                    OUT CRPADM.RC_BPM_LIST,
        o_repair_partner_list         OUT CRPADM.RC_REPAIR_PARTNER_LIST,
        o_fiscal_quarter_list         OUT CRPADM.RC_REFRESH_METHOD_LIST,
        o_fiscal_year_list            OUT CRPADM.RC_PROGRAM_TYPE_LIST,
        o_fiscal_quarter_wk_list      OUT CRPADM.RC_REFRESH_METHOD_LIST,
        o_bts_sites_list              OUT CRPADM.RC_REPAIR_PARTNER_LIST,
        o_status                      OUT NUMBER)
    AS
        lv_repair_partner_list      CRPADM.RC_REPAIR_PARTNER_LIST;
        lv_bpm_list                 CRPADM.RC_BPM_LIST;
        lv_user_id                  VARCHAR2 (50 BYTE);
        lv_repair_userid            VARCHAR2 (50 BYTE);
        lv_fiscal_qtr_end_date      DATE;
        lv_fiscal_year_list         CRPADM.RC_PROGRAM_TYPE_LIST;
        lv_fiscal_quarter_list      CRPADM.RC_REFRESH_METHOD_LIST;
        lv_fiscal_quarter_wk_list   CRPADM.RC_REFRESH_METHOD_LIST;
        lv_bts_sites_list           CRPADM.RC_REPAIR_PARTNER_LIST
                                        := CRPADM.RC_REPAIR_PARTNER_LIST ();
    BEGIN
        lv_bpm_list := CRPADM.RC_BPM_LIST ();
        lv_repair_partner_list := CRPADM.RC_REPAIR_PARTNER_LIST ();
        lv_fiscal_year_list := CRPADM.RC_PROGRAM_TYPE_LIST ();
        lv_fiscal_quarter_list := CRPADM.RC_REFRESH_METHOD_LIST ();
        lv_fiscal_quarter_wk_list := CRPADM.RC_REFRESH_METHOD_LIST ();
        o_bpm_list := CRPADM.RC_BPM_LIST ();
        o_repair_partner_list := CRPADM.RC_REPAIR_PARTNER_LIST ();
        o_fiscal_year_list := CRPADM.RC_PROGRAM_TYPE_LIST ();
        o_fiscal_quarter_list := CRPADM.RC_REFRESH_METHOD_LIST ();
        o_fiscal_quarter_wk_list := CRPADM.RC_REFRESH_METHOD_LIST ();
        lv_user_id := i_user_id;
        o_status := 1;

        BEGIN
            SELECT CRPADM.RC_BPM_OBJ (BPM_ID, BPM_USER_ID, REPAIR_PARTNER_ID)
              BULK COLLECT INTO lv_bpm_list
              FROM (SELECT DISTINCT
                           BPM.BPM_ID, BPM.BPM_USER_ID, BPM.REPAIR_PARTNER_ID
                      FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER  RP
                           INNER JOIN CRPADM.RC_REPAIR_PARTNER_BPM_SETUP BPM
                               ON RP.REPAIR_PARTNER_ID =
                                  BPM.REPAIR_PARTNER_ID
                     WHERE RP.ACTIVE_FLAG = 'Y' AND RP.BPM_ID IS NOT NULL);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_bpm_list := CRPADM.RC_BPM_LIST ();
        END;

        BEGIN
            SELECT DISTINCT USER_NAME
              INTO lv_repair_userid
              FROM CRPADM.RC_REPAIR_PARTNER_USER_MAP
             WHERE UPPER (TRIM (USER_NAME)) = UPPER (TRIM (lv_user_id));
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_repair_userid := '';
        END;

        BEGIN
            IF lv_repair_userid IS NOT NULL
            THEN
                SELECT CRPADM.RC_REPAIR_PARTNER_OBJ (REPAIR_PARTNER_ID,
                                                     REPAIR_PARTNER_NAME)
                  BULK COLLECT INTO lv_repair_partner_list
                  FROM (SELECT RP.REPAIR_PARTNER_ID, RP.REPAIR_PARTNER_NAME
                          FROM CRPADM.RC_REPAIR_PARTNER_USER_MAP  USR,
                               CRPADM.RC_PRODUCT_REPAIR_PARTNER   RP
                         WHERE     RP.REPAIR_PARTNER_ID =
                                   USR.REPAIR_PARTNER_ID
                               AND UPPER (TRIM (USR.USER_NAME)) =
                                   UPPER (TRIM (lv_user_id))
                               AND USR.ACTIVE_FLAG = 'Y');
            ELSE
                SELECT CRPADM.RC_REPAIR_PARTNER_OBJ (REPAIR_PARTNER_ID,
                                                     REPAIR_PARTNER_NAME)
                  BULK COLLECT INTO lv_repair_partner_list
                  FROM (SELECT REPAIR_PARTNER_ID, REPAIR_PARTNER_NAME
                          FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER
                         WHERE ACTIVE_FLAG = 'Y');
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_repair_partner_list := CRPADM.RC_REPAIR_PARTNER_LIST ();
        END;

        SELECT FISCAL_QTR_END_DATE
          INTO lv_fiscal_qtr_end_date
          FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
         WHERE CALENDAR_DATE = TRUNC (SYSDATE);

        BEGIN
            SELECT CRPADM.RC_PROGRAM_TYPE_OBJ (CONFIG_NAME, CONFIG_ID)
              BULK COLLECT INTO lv_fiscal_year_list
              FROM (SELECT DISTINCT
                           CURRENT_FISCAL_YEAR_FLAG CONFIG_NAME,
                           FISCAL_YEAR_NUMBER       CONFIG_ID
                      FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                     WHERE     CALENDAR_DATE >=
                               (SELECT MIN (FISCAL_WEEKEND_DATE)
                                  FROM RC_KPI_TSRM_PC)
                           AND CALENDAR_DATE <= lv_fiscal_qtr_end_date);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_fiscal_year_list := CRPADM.RC_PROGRAM_TYPE_LIST ();
        END;

        BEGIN
            SELECT CRPADM.RC_REFRESH_METHOD_OBJ (CONFIG_NAME,
                                                 CONFIG_ID,
                                                 UDC_1)
              BULK COLLECT INTO lv_fiscal_quarter_list
              FROM (SELECT DISTINCT
                           FISCAL_QUARTER_NAME         CONFIG_NAME,
                           FISCAL_YEAR_NUMBER          CONFIG_ID,
                           CURRENT_FISCAL_QUARTER_FLAG UDC_1
                      FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                     WHERE     CALENDAR_DATE >=
                               (SELECT MIN (FISCAL_WEEKEND_DATE)
                                  FROM RC_KPI_TSRM_PC)
                           AND CALENDAR_DATE <= lv_fiscal_qtr_end_date);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_fiscal_quarter_list := CRPADM.RC_REFRESH_METHOD_LIST ();
        END;

        BEGIN
            SELECT CRPADM.RC_REFRESH_METHOD_OBJ (CONFIG_NAME,
                                                 CONFIG_ID,
                                                 UDC_1)
              BULK COLLECT INTO lv_fiscal_quarter_wk_list
              FROM (SELECT DISTINCT
                           FISCAL_QUARTER_NAME                          CONFIG_NAME,
                           FISCAL_WEEK_NUMBER                           CONFIG_ID,
                           TO_CHAR (FISCAL_WEEK_END_DATE, 'MM/DD/YYYY') UDC_1
                      FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                     WHERE     (   CURRENT_FISCAL_QUARTER_FLAG = 'Y'
                                OR PREVIOUS_FISCAL_QUARTER_FLAG = 'Y')
                           AND FISCAL_WEEK_END_DATE <= TRUNC (SYSDATE));
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_fiscal_quarter_wk_list := CRPADM.RC_REFRESH_METHOD_LIST ();
        END;

        BEGIN
            SELECT CRPADM.RC_REPAIR_PARTNER_OBJ (REPAIR_PARTNER_ID,
                                                 REPAIR_PARTNER_NAME)
              BULK COLLECT INTO lv_bts_sites_list
              FROM (SELECT PROPERTY_ID    REPAIR_PARTNER_ID,
                           PROPERTY_VALUE REPAIR_PARTNER_NAME
                      FROM CRPADM.RC_PROPERTIES
                     WHERE     PROPERTY_TYPE = 'INVENTORY_SITE'
                           AND PROPERTY_NAME IN
                                   ('NAM_LRO_INVENTORY_SITE',
                                    'EMEA_FVE_INVENTORY_SITE'));
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_bts_sites_list := CRPADM.RC_REPAIR_PARTNER_LIST ();
        END;

        o_bpm_list := lv_bpm_list;
        o_repair_partner_list := lv_repair_partner_list;
        o_fiscal_year_list := lv_fiscal_year_list;
        o_fiscal_quarter_list := lv_fiscal_quarter_list;
        o_fiscal_quarter_wk_list := lv_fiscal_quarter_wk_list;
        o_bts_sites_list := lv_bts_sites_list;
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
                'RC_KPI_DATA_EXTRACT.RC_KPI_FILTERS_LIST',
                'PROCEDURE',
                i_user_id,
                'N');
    END RC_KPI_FILTERS_LIST;

    /* Procedure to fetch Partner Commit vs Actuals details */
    PROCEDURE RC_KPI_PC_VS_ACT_DETAILS (
        i_user_id                 IN     VARCHAR2,
        i_repair_partner          IN     NUMBER,
        i_bpm                     IN     NUMBER,
        i_year                    IN     NUMBER,
        i_qtr                     IN     VARCHAR2,
        o_wk_column_header_list      OUT CRPADM.T_NORMALISED_LIST,
        o_wk_page_load_list          OUT RC_PC_VS_ACT_WK_LIST,
        o_wk_page_load_total         OUT RC_PC_VS_ACT_WK_LIST,
        o_status                     OUT NUMBER)
    AS
        lv_repair_partner          NUMBER;
        lv_bpm                     NUMBER;
        lv_year                    NUMBER;
        lv_qtr                     VARCHAR2 (100 BYTE);
        lv_wk_page_load_list       RC_PC_VS_ACT_WK_LIST;
        lv_wk_page_load_total      RC_PC_VS_ACT_WK_LIST;
        lv_query                   VARCHAR2 (32767);
        lv_total_query             VARCHAR2 (32767);
        lv_main_query              VARCHAR2 (32767);
        lv_where_condition         VARCHAR2 (200);
        lv_wk_column_header_list   CRPADM.T_NORMALISED_LIST;
        lv_current_weekend         DATE;
        lv_current_quarter         VARCHAR2 (50 BYTE);
    BEGIN
        lv_wk_page_load_list := RC_PC_VS_ACT_WK_LIST ();
        lv_wk_page_load_total := RC_PC_VS_ACT_WK_LIST ();
        lv_wk_column_header_list := CRPADM.T_NORMALISED_LIST ();
        lv_repair_partner := i_repair_partner;
        lv_bpm := i_bpm;
        lv_year := i_year;
        lv_qtr := i_qtr;
        o_status := 1;

          SELECT FISCAL_WEEK_END_DATE
            BULK COLLECT INTO lv_wk_column_header_list
            FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
           WHERE     UPPER (FISCAL_QUARTER_NAME) = UPPER (lv_qtr)
                 AND FISCAL_WEEK_END_IND = 'Y'
        ORDER BY 1;

        SELECT DISTINCT FISCAL_QUARTER_NAME
          INTO lv_current_quarter
          FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
         WHERE CURRENT_FISCAL_QUARTER_FLAG = 'Y';

        SELECT CRPADM.RC_GET_WEEKEND_DATE (SYSDATE)
          INTO lv_current_weekend
          FROM DUAL;

        lv_query :=
            'SELECT TO_CHAR (PC.FISCAL_WEEKEND_DATE, ''MM/DD/YYYY'') FISCAL_WEEKEND_DATE,
               PC.CUM_PC,
               PC.CUM_ACTUALS,
               PC.CALCULATED_VALUE
          FROM RC_KPI_PC_ACT PC INNER JOIN
       (  SELECT DISTINCT REFRESH_INVENTORY_ITEM_ID,
                          SETUP.REPAIR_PARTNER_ID,
                          REFRESH_PART_NUMBER,
                          SETUP.BPM_USER_ID,
                          RPB.BPM_ID
            FROM CRPADM.RC_PRODUCT_REPAIR_SETUP SETUP,
                 (SELECT BPM.REPAIR_PARTNER_ID, BPM.BPM_USER_ID, BPM.BPM_ID
                    FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER RP,
                         (  SELECT BPM_SETUP.REPAIR_PARTNER_ID,
                                   BPM_SETUP.BPM_USER_ID,
                                   BPM_SETUP.BPM_ID,
                                   COUNT (*)
                              FROM CRPADM.RC_REPAIR_PARTNER_BPM_SETUP BPM_SETUP
                          GROUP BY BPM_SETUP.REPAIR_PARTNER_ID,
                                   BPM_SETUP.BPM_USER_ID,
                                   BPM_SETUP.BPM_ID) BPM
                   WHERE     RP.REPAIR_PARTNER_ID = BPM.REPAIR_PARTNER_ID
                         AND RP.ACTIVE_FLAG = ''Y'') RPB
           WHERE     SETUP.REPAIR_PARTNER_ID = RPB.REPAIR_PARTNER_ID
                 AND SETUP.BPM_USER_ID = RPB.BPM_USER_ID
        GROUP BY REFRESH_INVENTORY_ITEM_ID,
                 SETUP.REPAIR_PARTNER_ID,
                 REFRESH_PART_NUMBER,
                 SETUP.BPM_USER_ID,
                 RPB.BPM_ID) BPM
           ON     PC.REFRESH_INVENTORY_ITEM_ID =
                  BPM.REFRESH_INVENTORY_ITEM_ID
              AND PC.REPAIR_PARTNER_ID = BPM.REPAIR_PARTNER_ID ';

        IF lv_repair_partner != -1
        THEN
            lv_where_condition :=
                   lv_where_condition
                || ' AND PC.REPAIR_PARTNER_ID = '
                || lv_repair_partner;
        END IF;

        IF lv_bpm != -1
        THEN
            lv_where_condition :=
                lv_where_condition || ' AND BPM.BPM_ID = ' || lv_bpm;
        END IF;


        IF lv_qtr IS NOT NULL
        THEN
            lv_where_condition :=
                   lv_where_condition
                || ' AND FISCAL_QUARTER = '''
                || lv_qtr
                || '''';
        ELSIF lv_qtr = ' ' OR lv_qtr IS NULL
        THEN
            SELECT DISTINCT FISCAL_QUARTER_NAME
              INTO lv_qtr
              FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
             WHERE CALENDAR_DATE = TRUNC (SYSDATE);

            lv_where_condition :=
                   lv_where_condition
                || ' AND FISCAL_QUARTER = '''
                || lv_qtr
                || '''';
        END IF;

        lv_query := lv_query || lv_where_condition;

        lv_total_query :=
               'SELECT RC_PC_VS_ACT_WK_OBJ (FISCAL_WEEKEND_DATE,
                            CUM_PC,
                            CUM_ACTUALS,
                            CALCULATED_VALUE,
                            KPI_PERCENTAGE)
  FROM (SELECT '' TOTAL'' FISCAL_WEEKEND_DATE,
                           CUM_PC,
                           CUM_ACTUALS,
                           CALCULATED_VALUE,
                           CASE
                              WHEN CALCULATED_VALUE = 0
                              THEN
                                 0
                              ELSE
                                 ROUND ( ( (CUM_ACTUALS/CALCULATED_VALUE) * 100), 2)
                           END
                              KPI_PERCENTAGE
                      FROM (  SELECT SUM (CUM_PC) CUM_PC,
                                     SUM (CUM_ACTUALS) CUM_ACTUALS,
                                     SUM (CALCULATED_VALUE) CALCULATED_VALUE
                                FROM ('
            || lv_query
            || ' )))';


        lv_main_query :=
               'SELECT RC_PC_VS_ACT_WK_OBJ (FISCAL_WEEKEND_DATE,
                            CUM_PC,
                            CUM_ACTUALS,
                            CALCULATED_VALUE,
                            KPI_PERCENTAGE)
  FROM (SELECT FISCAL_WEEKEND_DATE,
               CUM_PC,
               CUM_ACTUALS,
               CALCULATED_VALUE,
               CASE
                  WHEN CALCULATED_VALUE = 0 THEN 0
                  ELSE ROUND ( ( (CUM_ACTUALS / CALCULATED_VALUE) * 100), 2)
               END
                  KPI_PERCENTAGE
          FROM (SELECT FISCAL_WEEKEND_DATE,
                       CUM_PC,
                       CUM_ACTUALS,
                       CALCULATED_VALUE
                  FROM (SELECT FISCAL_WEEKEND_DATE,
                               SUM (CUM_PC) CUM_PC,
                               SUM (CUM_ACTUALS) CUM_ACTUALS,
                               SUM (CALCULATED_VALUE) CALCULATED_VALUE
                          FROM ('
            || lv_query
            || ' ) GROUP BY FISCAL_WEEKEND_DATE)))';


        EXECUTE IMMEDIATE lv_main_query
            BULK COLLECT INTO lv_wk_page_load_list;

        EXECUTE IMMEDIATE lv_total_query
            BULK COLLECT INTO lv_wk_page_load_total;

        --      IF lv_qtr = lv_current_quarter
        --      THEN
        --         SELECT COUNT (DISTINCT FISCAL_WEEKEND_DATE)
        --           INTO lv_week_count
        --           FROM RC_KPI_PC_ACT
        --          WHERE FISCAL_QUARTER = lv_qtr;
        --
        --         lv_kpi_percentage :=
        --            (lv_wk_page_load_total (1).KPI_PERCENTAGE * lv_week_count);
        --
        --         SELECT COUNT (DISTINCT FISCAL_WEEKEND_DATE)
        --           INTO lv_week_count
        --           FROM RC_KPI_PC_ACT
        --          WHERE     FISCAL_QUARTER = lv_qtr
        --                AND FISCAL_WEEKEND_DATE < lv_current_weekend;
        --
        --         lv_wk_page_load_total (1).KPI_PERCENTAGE :=
        --            TRUNC ( (lv_kpi_percentage / lv_week_count), 2);
        --      END IF;

        o_wk_page_load_list := lv_wk_page_load_list;
        o_wk_page_load_total := lv_wk_page_load_total;
        o_wk_column_header_list := lv_wk_column_header_list;
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
                'RC_KPI_DATA_EXTRACT.RC_KPI_PC_VS_ACT_DETAILS',
                'PROCEDURE',
                i_user_id,
                'N');
    END RC_KPI_PC_VS_ACT_DETAILS;

    /* Procedure to fetch TSRM vs Partner Commit details */
    PROCEDURE RC_KPI_TSRM_PC_DETAILS (
        i_user_id                 IN     VARCHAR2,
        i_repair_partner          IN     NUMBER,
        i_bpm                     IN     NUMBER,
        i_year                    IN     NUMBER,
        i_qtr                     IN     VARCHAR2,
        o_wk_column_header_list      OUT CRPADM.T_NORMALISED_LIST,
        o_wk_page_load_list          OUT RC_TSRM_PC_WK_LIST,
        o_wk_page_load_total         OUT RC_TSRM_PC_WK_LIST,
        o_status                     OUT NUMBER)
    AS
        lv_repair_partner          NUMBER;
        lv_bpm                     NUMBER;
        lv_year                    NUMBER;
        lv_qtr                     VARCHAR2 (100 BYTE);
        lv_wk_page_load_list       RC_TSRM_PC_WK_LIST;
        lv_wk_page_load_total      RC_TSRM_PC_WK_LIST;
        lv_query                   VARCHAR2 (32767);
        lv_main_query              VARCHAR2 (32767);
        lv_total_query             VARCHAR2 (32767);
        lv_where_condition         VARCHAR2 (200);
        lv_wk_column_header_list   CRPADM.T_NORMALISED_LIST;
    BEGIN
        lv_wk_page_load_list := RC_TSRM_PC_WK_LIST ();
        lv_wk_page_load_total := RC_TSRM_PC_WK_LIST ();
        lv_wk_column_header_list := CRPADM.T_NORMALISED_LIST ();
        lv_repair_partner := i_repair_partner;
        lv_bpm := i_bpm;
        lv_year := i_year;
        lv_qtr := i_qtr;
        o_status := 1;

          SELECT FISCAL_WEEK_END_DATE
            BULK COLLECT INTO lv_wk_column_header_list
            FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
           WHERE     UPPER (FISCAL_QUARTER_NAME) = UPPER (lv_qtr)
                 AND FISCAL_WEEK_END_IND = 'Y'
        ORDER BY 1;

        lv_query :=
            'SELECT TO_CHAR (PC.FISCAL_WEEKEND_DATE, ''MM/DD/YYYY'') FISCAL_WEEKEND_DATE,
                         PC.CUM_TSRM,
                         PC.CUM_PC, 
                         PC.CALCULATED_VALUE
                    FROM RC_KPI_TSRM_PC PC INNER JOIN
       (  SELECT DISTINCT REFRESH_INVENTORY_ITEM_ID,
                          SETUP.REPAIR_PARTNER_ID,
                          REFRESH_PART_NUMBER,
                          SETUP.BPM_USER_ID,
                          RPB.BPM_ID
            FROM CRPADM.RC_PRODUCT_REPAIR_SETUP SETUP,
                 (SELECT BPM.REPAIR_PARTNER_ID, BPM.BPM_USER_ID, BPM.BPM_ID
                    FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER RP,
                         (  SELECT BPM_SETUP.REPAIR_PARTNER_ID,
                                   BPM_SETUP.BPM_USER_ID,
                                   BPM_SETUP.BPM_ID,
                                   COUNT (*)
                              FROM CRPADM.RC_REPAIR_PARTNER_BPM_SETUP BPM_SETUP
                          GROUP BY BPM_SETUP.REPAIR_PARTNER_ID,
                                   BPM_SETUP.BPM_USER_ID,
                                   BPM_SETUP.BPM_ID) BPM
                   WHERE     RP.REPAIR_PARTNER_ID = BPM.REPAIR_PARTNER_ID
                         AND RP.ACTIVE_FLAG = ''Y'') RPB
           WHERE     SETUP.REPAIR_PARTNER_ID = RPB.REPAIR_PARTNER_ID
                 AND SETUP.BPM_USER_ID = RPB.BPM_USER_ID
        GROUP BY REFRESH_INVENTORY_ITEM_ID,
                 SETUP.REPAIR_PARTNER_ID,
                 REFRESH_PART_NUMBER,
                 SETUP.BPM_USER_ID,
                 RPB.BPM_ID) BPM
           ON     PC.REFRESH_INVENTORY_ITEM_ID =
                  BPM.REFRESH_INVENTORY_ITEM_ID
              AND PC.REPAIR_PARTNER_ID = BPM.REPAIR_PARTNER_ID ';

        IF lv_repair_partner != -1
        THEN
            lv_where_condition :=
                   lv_where_condition
                || ' AND PC.REPAIR_PARTNER_ID = '
                || lv_repair_partner;
        END IF;

        IF lv_bpm != -1
        THEN
            lv_where_condition :=
                lv_where_condition || ' AND BPM.BPM_ID = ' || lv_bpm;
        END IF;

        IF lv_qtr IS NOT NULL
        THEN
            lv_where_condition :=
                   lv_where_condition
                || ' AND FISCAL_QUARTER = '''
                || lv_qtr
                || '''';
        ELSIF lv_qtr = ' ' OR lv_qtr IS NULL
        THEN
            SELECT DISTINCT FISCAL_QUARTER_NAME
              INTO lv_qtr
              FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
             WHERE CALENDAR_DATE = TRUNC (SYSDATE);

            lv_where_condition :=
                   lv_where_condition
                || ' AND FISCAL_QUARTER = '''
                || lv_qtr
                || '''';
        END IF;

        lv_query := lv_query || lv_where_condition;

        lv_total_query := 'SELECT RC_TSRM_PC_WK_OBJ (FISCAL_WEEKEND_DATE,
                          CUM_TSRM,
                          CUM_PC,
                          CALCULATED_VALUE,
                          KPI_PERCENTAGE)
  FROM (SELECT '' TOTAL'' FISCAL_WEEKEND_DATE,
               CUM_TSRM,
               CUM_PC,
               CALCULATED_VALUE,
               CASE
                  WHEN CALCULATED_VALUE = 0
                  THEN
                     0
                  ELSE
                           ROUND ( ( (CUM_PC/CALCULATED_VALUE) * 100), 2)
               END
                  KPI_PERCENTAGE
          FROM (  SELECT SUM (CUM_TSRM) CUM_TSRM,
                         SUM (CUM_PC) CUM_PC,
                         SUM (CALCULATED_VALUE) CALCULATED_VALUE
                    FROM (' || lv_query || ' )))';

        lv_main_query :=
               'SELECT RC_TSRM_PC_WK_OBJ (FISCAL_WEEKEND_DATE,
                          CUM_TSRM,
                          CUM_PC,
                          CALCULATED_VALUE,
                          KPI_PERCENTAGE)
  FROM (SELECT FISCAL_WEEKEND_DATE,
               CUM_TSRM,
               CUM_PC,
               CALCULATED_VALUE,
               CASE
                  WHEN CALCULATED_VALUE = 0 THEN 0
                  ELSE ROUND ( ( (CUM_PC / CALCULATED_VALUE) * 100), 2)
               END
                  KPI_PERCENTAGE
          FROM (SELECT FISCAL_WEEKEND_DATE,
                       CUM_TSRM,
                       CUM_PC,
                       CALCULATED_VALUE
                  FROM (SELECT FISCAL_WEEKEND_DATE,
                               SUM (CUM_TSRM) CUM_TSRM,
                               SUM (CUM_PC) CUM_PC,
                               SUM (CALCULATED_VALUE) CALCULATED_VALUE
                          FROM ('
            || lv_query
            || ' ) GROUP BY FISCAL_WEEKEND_DATE)))';


        EXECUTE IMMEDIATE lv_main_query
            BULK COLLECT INTO lv_wk_page_load_list;

        EXECUTE IMMEDIATE lv_total_query
            BULK COLLECT INTO lv_wk_page_load_total;

        o_wk_page_load_list := lv_wk_page_load_list;
        o_wk_page_load_total := lv_wk_page_load_total;
        o_wk_column_header_list := lv_wk_column_header_list;
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
                'RC_KPI_DATA_EXTRACT.RC_KPI_TSRM_PC_DETAILS',
                'PROCEDURE',
                i_user_id,
                'N');
    END RC_KPI_TSRM_PC_DETAILS;

    /* Procedure to fetch Partner Commit vs Actuals PID level summary data */
    PROCEDURE RC_KPI_COMMIT_ACT_PID_DTLS (
        i_user_id                     IN     VARCHAR2,
        i_weekend_date                IN     VARCHAR2,
        i_repair_partner              IN     NUMBER,
        i_bpm                         IN     NUMBER,
        i_year                        IN     NUMBER,
        i_qtr                         IN     VARCHAR2,
        i_part_number                 IN     CRPADM.T_NORMALISED_LIST,
        i_min_range                   IN     NUMBER,
        i_max_range                   IN     NUMBER,
        o_commit_act_pid_dtls_list       OUT RC_COMMIT_ACT_PID_DTLS_LIST,
        o_commit_act_pid_dtls_total      OUT RC_COMMIT_ACT_PID_DTLS_LIST,
        o_total_row_count                OUT NUMBER,
        o_status                         OUT NUMBER)
    AS
        lv_weekend_date                DATE := TO_DATE (i_weekend_date, 'MM/DD/YYYY');
        lv_repair_partner              NUMBER := i_repair_partner;
        lv_bpm                         NUMBER := i_bpm;
        lv_year                        NUMBER := i_year;
        lv_qtr                         VARCHAR2 (20) := i_qtr;
        lv_pid_list                    CRPADM.T_NORMALISED_LIST := i_part_number;
        lv_commit_act_pid_dtls_list    RC_COMMIT_ACT_PID_DTLS_LIST;
        lv_commit_act_pid_dtls_total   RC_COMMIT_ACT_PID_DTLS_LIST;
        lv_flag_yes                    CHAR (1) := 'Y';
        lv_query                       VARCHAR2 (3500);
        lv_constraint                  VARCHAR2 (1500);
        lv_count_query                 VARCHAR2 (32767) DEFAULT NULL;
        lv_total_query                 VARCHAR2 (32767) DEFAULT NULL;
        lv_main_query                  VARCHAR2 (32767) DEFAULT NULL;
        lv_total_row_count             NUMBER;
    BEGIN
        o_status := 1;
        lv_commit_act_pid_dtls_list := RC_COMMIT_ACT_PID_DTLS_LIST ();
        lv_commit_act_pid_dtls_total := RC_COMMIT_ACT_PID_DTLS_LIST ();

        lv_count_query :=
               'SELECT COUNT (*) FROM RC_KPI_PC_ACT PC_ACT
               INNER JOIN CRPADM.RC_PRODUCT_REPAIR_PARTNER REP
                  ON     PC_ACT.REPAIR_PARTNER_ID = REP.REPAIR_PARTNER_ID
                     AND REP.ACTIVE_FLAG = '''
            || lv_flag_yes
            || ''' AND FISCAL_WEEKEND_DATE = '''
            || lv_weekend_date
            || '''';


        lv_query :=
               'SELECT PART_NUMBER, COMMIT, ACTUAL_CALCULATION, ACTUAL_COMPLETE, KPI_PERCENTAGE, REPAIR_PARTNER FROM (
  SELECT PART_NUMBER, COMMIT, ACTUAL_CALCULATION, ACTUAL_COMPLETE, KPI_PERCENTAGE, REPAIR_PARTNER, ROWNUM RNUM FROM 
                           ( SELECT REFRESH_PART_NUMBER PART_NUMBER,
               CUM_PC COMMIT,
               CUM_ACTUALS ACTUAL_COMPLETE,
               CALCULATED_VALUE ACTUAL_CALCULATION,
               KPI_PERCENTAGE KPI_PERCENTAGE,
               REP.REPAIR_PARTNER_NAME REPAIR_PARTNER
          FROM RC_KPI_PC_ACT PC_ACT
               INNER JOIN CRPADM.RC_PRODUCT_REPAIR_PARTNER REP
                  ON     PC_ACT.REPAIR_PARTNER_ID = REP.REPAIR_PARTNER_ID
                     AND REP.ACTIVE_FLAG = '''
            || lv_flag_yes
            || ''' AND FISCAL_WEEKEND_DATE = '''
            || lv_weekend_date
            || '''';



        IF (lv_pid_list IS NOT NULL)
        THEN
            IF (lv_pid_list (1) != ' ')
            THEN
                DELETE FROM KPI_PID_LIST;

                FORALL idx IN 1 .. lv_pid_list.COUNT
                    INSERT INTO KPI_PID_LIST
                         VALUES (UPPER (lv_pid_list (idx)));

                COMMIT;
                lv_constraint :=
                    ' AND UPPER(PC_ACT.REFRESH_PART_NUMBER) IN (SELECT DISTINCT PART_NUMBER FROM KPI_PID_LIST)';
            END IF;
        END IF;

        IF (lv_repair_partner != -1)
        THEN
            lv_constraint :=
                   lv_constraint
                || ' AND REP.REPAIR_PARTNER_ID = '
                || lv_repair_partner;
        END IF;

        IF (lv_bpm != -1)
        THEN
            lv_constraint := lv_constraint || ' AND REP.BPM_ID = ' || lv_bpm;
        END IF;

        lv_total_query :=
               ' SELECT RC_COMMIT_ACT_PID_DTLS_OBJ (PART_NUMBER,
                                   COMMIT,
                                   ACTUAL_COMPLETE,
                                   ACTUAL_CALCULATION,
                                   KPI_PERCENTAGE,
                                   REPAIR_PARTNER)
               FROM ( SELECT ''TOTAL'' PART_NUMBER,
                      COMMIT,
                      ACTUAL_COMPLETE,
                      ACTUAL_CALCULATION,
                      CASE
                              WHEN ACTUAL_CALCULATION = 0
                              THEN
                                 0
                              ELSE
                                 ROUND ( ( (ACTUAL_COMPLETE/ACTUAL_CALCULATION) * 100), 2)
                           END
              KPI_PERCENTAGE,
              '' '' REPAIR_PARTNER
              FROM (SELECT SUM(COMMIT) COMMIT,
                    SUM(ACTUAL_COMPLETE) ACTUAL_COMPLETE,
                    SUM(ACTUAL_CALCULATION) ACTUAL_CALCULATION
                    FROM ( '
            || lv_query
            || lv_constraint
            || ' )))))';

        lv_count_query := lv_count_query || lv_constraint;

        lv_constraint :=
               lv_constraint
            || ' ORDER BY REFRESH_PART_NUMBER)) WHERE RNUM BETWEEN '
            || i_min_range
            || ' AND '
            || i_max_range;

        lv_query := lv_query || lv_constraint;


        lv_main_query := ' SELECT RC_COMMIT_ACT_PID_DTLS_OBJ (PART_NUMBER,
                                   COMMIT,
                                   ACTUAL_COMPLETE,
                                   ACTUAL_CALCULATION,
                                   KPI_PERCENTAGE,
                                   REPAIR_PARTNER)
                          FROM ( ' || lv_query || ' ) ';



        EXECUTE IMMEDIATE lv_main_query
            BULK COLLECT INTO lv_commit_act_pid_dtls_list;

        EXECUTE IMMEDIATE lv_count_query INTO lv_total_row_count;

        EXECUTE IMMEDIATE lv_total_query
            BULK COLLECT INTO lv_commit_act_pid_dtls_total;


        o_commit_act_pid_dtls_list := lv_commit_act_pid_dtls_list;
        o_commit_act_pid_dtls_total := lv_commit_act_pid_dtls_total;
        o_total_row_count := lv_total_row_count;
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
                'RC_KPI_DATA_EXTRACT.RC_KPI_COMMIT_ACT_PID_DTLS',
                'PROCEDURE',
                i_user_id,
                'N');
    END RC_KPI_COMMIT_ACT_PID_DTLS;

    PROCEDURE RC_KPI_TSRM_VS_PC_QTR_DETAILS (
        i_user_id                 IN     VARCHAR2,
        i_repair_partner          IN     NUMBER,
        i_bpm                     IN     NUMBER,
        i_year                    IN     NUMBER,
        i_qtr                     IN     VARCHAR2,
        o_qtr_page_load_list         OUT RC_KPI_TSRM_PC_QTR_LIST,
        o_wk_column_header_list      OUT CRPADM.T_NORMALISED_LIST,
        o_status                     OUT NUMBER)
    AS
        lv_repair_partner          NUMBER;
        lv_bpm                     NUMBER;
        lv_year                    NUMBER;
        lv_qtr                     VARCHAR2 (100 BYTE);
        lv_qtr_page_load_list      RC_KPI_TSRM_PC_QTR_LIST;
        lv_query                   VARCHAR2 (32767);
        lv_main_query              VARCHAR2 (32767);
        lv_where_condition         VARCHAR2 (200);
        lv_wk_column_header_list   CRPADM.T_NORMALISED_LIST;
        lv_current_weekend         DATE;
        lv_current_quarter         VARCHAR2 (50 BYTE);
    BEGIN
        lv_qtr_page_load_list := RC_KPI_TSRM_PC_QTR_LIST ();
        o_qtr_page_load_list := RC_KPI_TSRM_PC_QTR_LIST ();
        lv_wk_column_header_list := CRPADM.T_NORMALISED_LIST ();
        lv_repair_partner := i_repair_partner;
        lv_bpm := i_bpm;
        lv_year := i_year;
        lv_qtr := i_qtr;
        o_status := 1;

          SELECT FISCAL_WEEK_END_DATE
            BULK COLLECT INTO lv_wk_column_header_list
            FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
           WHERE     UPPER (FISCAL_QUARTER_NAME) = UPPER (lv_qtr)
                 AND FISCAL_WEEK_END_IND = 'Y'
        ORDER BY 1;

        SELECT DISTINCT FISCAL_QUARTER_NAME
          INTO lv_current_quarter
          FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
         WHERE CURRENT_FISCAL_QUARTER_FLAG = 'Y';

        SELECT CRPADM.RC_GET_WEEKEND_DATE (SYSDATE)
          INTO lv_current_weekend
          FROM DUAL;

        IF lv_repair_partner != -1
        THEN
            lv_where_condition :=
                   lv_where_condition
                || ' AND PC.REPAIR_PARTNER_ID = '
                || lv_repair_partner;
        END IF;

        IF lv_bpm != -1
        THEN
            lv_where_condition :=
                lv_where_condition || ' AND RP.BPM_ID = ' || lv_bpm;
        END IF;


        IF lv_qtr IS NOT NULL
        THEN
            lv_where_condition :=
                   lv_where_condition
                || ' AND FISCAL_QUARTER = '''
                || lv_qtr
                || '''';
        ELSIF lv_qtr = ' ' OR lv_qtr IS NULL
        THEN
            SELECT DISTINCT FISCAL_QUARTER_NAME
              INTO lv_qtr
              FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
             WHERE CALENDAR_DATE = TRUNC (SYSDATE);

            lv_where_condition :=
                   lv_where_condition
                || ' AND FISCAL_QUARTER = '''
                || lv_qtr
                || '''';
        END IF;

        lv_query :=
            ' SELECT 
                              REFRESH_PART_NUMBER,
                              REPAIR_PARTNER_NAME,
                              FISCAL_QUARTER,
                               SUM (CUM_TSRM) CUM_TSRM,
                               SUM (CUM_PC) CUM_PC,
                               SUM (CALCULATED_VALUE) CALCULATED_VALUE
                               FROM (SELECT REFRESH_PART_NUMBER ,RP.REPAIR_PARTNER_NAME,FISCAL_QUARTER,
               PC.CUM_TSRM,
               PC.CUM_PC,
               PC.CALCULATED_VALUE
          FROM RC_KPI_TSRM_PC PC, CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
         WHERE PC.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID ';

        lv_query := lv_query || lv_where_condition;


        lv_main_query :=
               'SELECT RC_KPI_TSRM_PC_QTR_OBJ(REFRESH_PART_NUMBER ,
            REPAIR_PARTNER_NAME,
            FISCAL_QUARTER,
                            CUM_TSRM,
                            CUM_PC,
                            CALCULATED_VALUE,
                            KPI_PERCENTAGE )                        
  FROM (SELECT REFRESH_PART_NUMBER ,REPAIR_PARTNER_NAME,FISCAL_QUARTER,
               CUM_TSRM,
               CUM_PC,
               CALCULATED_VALUE,
               CASE
                  WHEN CALCULATED_VALUE = 0 THEN 0
                  ELSE ROUND ( ( (CUM_PC / CALCULATED_VALUE) * 100), 2)
               END
                  KPI_PERCENTAGE
          FROM (SELECT REFRESH_PART_NUMBER ,REPAIR_PARTNER_NAME,FISCAL_QUARTER,
                       CUM_TSRM,
                       CUM_PC,
                       CALCULATED_VALUE
                  FROM ('
            || lv_query
            || ')GROUP BY REFRESH_PART_NUMBER ,REPAIR_PARTNER_NAME,FISCAL_QUARTER)))';


        EXECUTE IMMEDIATE lv_main_query
            BULK COLLECT INTO lv_qtr_page_load_list;

        o_qtr_page_load_list := lv_qtr_page_load_list;

        o_wk_column_header_list := lv_wk_column_header_list;
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
                'RC_KPI_DATA_EXTRACT.RC_KPI_PC_VS_ACT_DETAILS',
                'PROCEDURE',
                i_user_id,
                'N');
    END RC_KPI_TSRM_VS_PC_QTR_DETAILS;


    PROCEDURE RC_KPI_PC_VS_ACT_QTR_DETAILS (
        i_user_id                 IN     VARCHAR2,
        i_repair_partner          IN     NUMBER,
        i_bpm                     IN     NUMBER,
        i_year                    IN     NUMBER,
        i_qtr                     IN     VARCHAR2,
        o_qtr_page_load_list         OUT RC_PC_VS_ACT_QTR_LIST,
        o_wk_column_header_list      OUT CRPADM.T_NORMALISED_LIST,
        o_status                     OUT NUMBER)
    AS
        lv_repair_partner          NUMBER;
        lv_bpm                     NUMBER;
        lv_year                    NUMBER;
        lv_qtr                     VARCHAR2 (100 BYTE);
        lv_qtr_page_load_list      RC_PC_VS_ACT_QTR_LIST;
        lv_qtr_page_load_total     RC_PC_VS_ACT_QTR_LIST;
        lv_query                   VARCHAR2 (32767);
        lv_main_query              VARCHAR2 (32767);
        lv_where_condition         VARCHAR2 (200);
        lv_wk_column_header_list   CRPADM.T_NORMALISED_LIST;
        lv_current_weekend         DATE;
        lv_current_quarter         VARCHAR2 (50 BYTE);
    BEGIN
        lv_qtr_page_load_list := RC_PC_VS_ACT_QTR_LIST ();
        lv_qtr_page_load_total := RC_PC_VS_ACT_QTR_LIST ();
        o_qtr_page_load_list := RC_PC_VS_ACT_QTR_LIST ();
        lv_wk_column_header_list := CRPADM.T_NORMALISED_LIST ();
        lv_repair_partner := i_repair_partner;
        lv_bpm := i_bpm;
        lv_year := i_year;
        lv_qtr := i_qtr;
        o_status := 1;

          SELECT FISCAL_WEEK_END_DATE
            BULK COLLECT INTO lv_wk_column_header_list
            FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
           WHERE     UPPER (FISCAL_QUARTER_NAME) = UPPER (lv_qtr)
                 AND FISCAL_WEEK_END_IND = 'Y'
        ORDER BY 1;

        SELECT DISTINCT FISCAL_QUARTER_NAME
          INTO lv_current_quarter
          FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
         WHERE CURRENT_FISCAL_QUARTER_FLAG = 'Y';

        SELECT CRPADM.RC_GET_WEEKEND_DATE (SYSDATE)
          INTO lv_current_weekend
          FROM DUAL;

        IF lv_repair_partner != -1
        THEN
            lv_where_condition :=
                   lv_where_condition
                || ' AND PC.REPAIR_PARTNER_ID = '
                || lv_repair_partner;
        END IF;

        IF lv_bpm != -1
        THEN
            lv_where_condition :=
                lv_where_condition || ' AND RP.BPM_ID = ' || lv_bpm;
        END IF;


        IF lv_qtr IS NOT NULL
        THEN
            lv_where_condition :=
                   lv_where_condition
                || ' AND FISCAL_QUARTER = '''
                || lv_qtr
                || '''';
        ELSIF lv_qtr = ' ' OR lv_qtr IS NULL
        THEN
            SELECT DISTINCT FISCAL_QUARTER_NAME
              INTO lv_qtr
              FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
             WHERE CALENDAR_DATE = TRUNC (SYSDATE);

            lv_where_condition :=
                   lv_where_condition
                || ' AND FISCAL_QUARTER = '''
                || lv_qtr
                || '''';
        END IF;

        lv_query :=
            ' SELECT 
                              REFRESH_PART_NUMBER,
                              REPAIR_PARTNER_NAME,
                              FISCAL_QUARTER,
                               SUM (CUM_PC) CUM_PC,
                               SUM (CUM_ACTUALS) CUM_ACTUALS,
                               SUM (CALCULATED_VALUE) CALCULATED_VALUE
                               FROM (SELECT REFRESH_PART_NUMBER ,RP.REPAIR_PARTNER_NAME,FISCAL_QUARTER,
               PC.CUM_PC,
               PC.CUM_ACTUALS,
               PC.CALCULATED_VALUE
          FROM RC_KPI_PC_ACT PC, CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
         WHERE PC.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID ';

        lv_query := lv_query || lv_where_condition;


        lv_main_query :=
               'SELECT RC_PC_VS_ACT_QTR_OBJ(REFRESH_PART_NUMBER ,
            REPAIR_PARTNER_NAME,
            FISCAL_QUARTER,
                            CUM_PC,
                            CUM_ACTUALS,
                            CALCULATED_VALUE,
                            KPI_PERCENTAGE )                        
  FROM (SELECT REFRESH_PART_NUMBER ,REPAIR_PARTNER_NAME,FISCAL_QUARTER,
               CUM_PC,
               CUM_ACTUALS,
               CALCULATED_VALUE,
               CASE
                  WHEN CALCULATED_VALUE = 0 THEN 0
                  ELSE ROUND ( ( (CUM_ACTUALS / CALCULATED_VALUE) * 100), 2)
               END
                  KPI_PERCENTAGE
          FROM (SELECT REFRESH_PART_NUMBER ,REPAIR_PARTNER_NAME,FISCAL_QUARTER,
                       CUM_PC,
                       CUM_ACTUALS,
                       CALCULATED_VALUE
                  FROM ('
            || lv_query
            || ')GROUP BY REFRESH_PART_NUMBER ,REPAIR_PARTNER_NAME,FISCAL_QUARTER)))';


        EXECUTE IMMEDIATE lv_main_query
            BULK COLLECT INTO lv_qtr_page_load_list;

        o_qtr_page_load_list := lv_qtr_page_load_list;

        o_wk_column_header_list := lv_wk_column_header_list;
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
                'RC_KPI_DATA_EXTRACT.RC_KPI_PC_VS_ACT_DETAILS',
                'PROCEDURE',
                i_user_id,
                'N');
    END RC_KPI_PC_VS_ACT_QTR_DETAILS;



    /* Procedure to fetch TSRM vs Partner Commit PID level summary data */
    PROCEDURE RC_KPI_TSRM_PC_PID_DTLS (
        i_user_id                  IN     VARCHAR2,
        i_weekend_date             IN     VARCHAR2,
        i_repair_partner           IN     NUMBER,
        i_bpm                      IN     NUMBER,
        i_year                     IN     NUMBER,
        i_qtr                      IN     VARCHAR2,
        i_part_number              IN     CRPADM.T_NORMALISED_LIST,
        i_min_range                IN     NUMBER,
        i_max_range                IN     NUMBER,
        o_tsrm_pc_pid_dtls_list       OUT RC_TSRM_PC_PID_DTLS_LIST,
        o_tsrm_pc_pid_dtls_total      OUT RC_TSRM_PC_PID_DTLS_LIST,
        o_total_row_count             OUT NUMBER,
        o_status                      OUT NUMBER)
    AS
        lv_weekend_date             DATE := TO_DATE (i_weekend_date, 'MM/DD/YYYY');
        lv_repair_partner           NUMBER := i_repair_partner;
        lv_bpm                      NUMBER := i_bpm;
        lv_year                     NUMBER := i_year;
        lv_qtr                      VARCHAR2 (20) := i_qtr;
        lv_pid_list                 CRPADM.T_NORMALISED_LIST := i_part_number;
        lv_tsrm_pc_pid_dtls_list    RC_TSRM_PC_PID_DTLS_LIST;
        lv_tsrm_pc_pid_dtls_total   RC_TSRM_PC_PID_DTLS_LIST;
        lv_flag_yes                 CHAR (1) := 'Y';
        lv_query                    VARCHAR2 (3500);
        lv_constraint               VARCHAR2 (1500);
        lv_count_query              VARCHAR2 (32767) DEFAULT NULL;
        lv_total_query              VARCHAR2 (32767) DEFAULT NULL;
        lv_main_query               VARCHAR2 (32767) DEFAULT NULL;
        lv_total_row_count          NUMBER;
    BEGIN
        o_status := 1;
        lv_tsrm_pc_pid_dtls_list := RC_TSRM_PC_PID_DTLS_LIST ();
        lv_tsrm_pc_pid_dtls_total := RC_TSRM_PC_PID_DTLS_LIST ();

        lv_count_query :=
               'SELECT COUNT (*) FROM RC_KPI_TSRM_PC TSRM_PC
               INNER JOIN CRPADM.RC_PRODUCT_REPAIR_PARTNER REP
                  ON     TSRM_PC.REPAIR_PARTNER_ID = REP.REPAIR_PARTNER_ID
                     AND REP.ACTIVE_FLAG = '''
            || lv_flag_yes
            || ''' AND FISCAL_WEEKEND_DATE = '''
            || lv_weekend_date
            || ''' ';

        lv_query :=
               ' SELECT REFRESH_PART_NUMBER,
               CUM_TSRM,
               CUM_PC,
               CALCULATED_VALUE,
               KPI_PERCENTAGE,
               REPAIR_PARTNER_NAME,
               ROWNUM RNUM
          FROM ( SELECT REFRESH_PART_NUMBER,
               CUM_TSRM,
               CUM_PC,
               CALCULATED_VALUE,
               KPI_PERCENTAGE,
               REP.REPAIR_PARTNER_NAME
          FROM RC_KPI_TSRM_PC TSRM_PC
               INNER JOIN CRPADM.RC_PRODUCT_REPAIR_PARTNER REP
                  ON     TSRM_PC.REPAIR_PARTNER_ID = REP.REPAIR_PARTNER_ID
                     AND REP.ACTIVE_FLAG = '''
            || lv_flag_yes
            || ''' AND FISCAL_WEEKEND_DATE = '''
            || lv_weekend_date
            || ''' ';

        IF (lv_pid_list IS NOT NULL)
        THEN
            IF (lv_pid_list (1) != ' ')
            THEN
                DELETE FROM KPI_PID_LIST;

                FORALL idx IN 1 .. lv_pid_list.COUNT
                    INSERT INTO KPI_PID_LIST
                         VALUES (UPPER (lv_pid_list (idx)));

                COMMIT;
                lv_constraint :=
                    ' AND UPPER(TSRM_PC.REFRESH_PART_NUMBER) IN (SELECT DISTINCT PART_NUMBER FROM KPI_PID_LIST)';
            END IF;
        END IF;

        IF (lv_repair_partner != -1)
        THEN
            lv_constraint :=
                   lv_constraint
                || ' AND REP.REPAIR_PARTNER_ID = '
                || lv_repair_partner;
        END IF;


        IF (lv_bpm != -1)
        THEN
            lv_constraint := lv_constraint || ' AND REP.BPM_ID = ' || lv_bpm;
        END IF;

        lv_count_query := lv_count_query || lv_constraint;


        lv_total_query :=
               ' SELECT RC_TSRM_PC_PID_DTLS_OBJ (PART_NUMBER,
                                TSRM,
                                COMMIT,
                                KPI_PERCENTAGE,
                                CALCULATED_VALUE,
                                REPAIR_PARTNER)
                FROM ( SELECT ''TOTAL'' PART_NUMBER,
                      CUM_TSRM TSRM,
                      CUM_PC COMMIT,
                      CASE
                              WHEN CALCULATED_VALUE = 0
                              THEN
                                 0
                              ELSE
                                 ROUND ( ( (CUM_PC/CALCULATED_VALUE) * 100), 2)
                           END
                    KPI_PERCENTAGE,
                    CALCULATED_VALUE,
                    '' '' REPAIR_PARTNER
              FROM (SELECT SUM(CUM_TSRM) CUM_TSRM,
                    SUM(CUM_PC) CUM_PC,
                    SUM(CALCULATED_VALUE) CALCULATED_VALUE
                    FROM ( '
            || lv_query
            || lv_constraint
            || ' ))))';
        lv_constraint := lv_constraint || ' ORDER BY REFRESH_PART_NUMBER)';
        lv_query := lv_query || lv_constraint;

        lv_query :=
               lv_query
            || ' ) WHERE RNUM BETWEEN '
            || i_min_range
            || ' AND '
            || i_max_range;


        lv_main_query := 'SELECT RC_TSRM_PC_PID_DTLS_OBJ (PART_NUMBER,
                                TSRM,
                                COMMIT,
                                KPI_PERCENTAGE,
                                CALCULATED_VALUE,
                                REPAIR_PARTNER)
                FROM ( SELECT REFRESH_PART_NUMBER PART_NUMBER,
               CUM_TSRM TSRM,
               CUM_PC COMMIT,
               KPI_PERCENTAGE KPI_PERCENTAGE,
               CALCULATED_VALUE,
               REPAIR_PARTNER_NAME REPAIR_PARTNER
          FROM (' || lv_query || ' )';


        EXECUTE IMMEDIATE lv_main_query
            BULK COLLECT INTO lv_tsrm_pc_pid_dtls_list;

        EXECUTE IMMEDIATE lv_total_query
            BULK COLLECT INTO lv_tsrm_pc_pid_dtls_total;

        EXECUTE IMMEDIATE lv_count_query INTO lv_total_row_count;

        o_tsrm_pc_pid_dtls_list := lv_tsrm_pc_pid_dtls_list;
        o_tsrm_pc_pid_dtls_total := lv_tsrm_pc_pid_dtls_total;
        o_total_row_count := lv_total_row_count;
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
                'RC_KPI_DATA_EXTRACT.RC_KPI_TSRM_PC_PID_DTLS',
                'PROCEDURE',
                i_user_id,
                'N');
    END RC_KPI_TSRM_PC_PID_DTLS;

    /* Procedure to Update and Save overridden KPI */
    PROCEDURE RC_KPI_SAVE_OVERRIDDEN_KPI (
        i_user_id               IN     VARCHAR2,
        i_repair_partner_id     IN     NUMBER,
        i_bpm_id                IN     NUMBER,
        i_year                  IN     NUMBER,
        i_qtr                   IN     VARCHAR2,
        i_overridden_qtd_list   IN     RC_KPI_OVERRIDDEN_QTD_LIST,
        o_status                   OUT NUMBER)
    AS
    BEGIN
        FOR idx IN 1 .. i_overridden_qtd_list.COUNT ()
        LOOP
            INSERT INTO RC_KPI_OVERRIDDEN_QTD_MSTR (KPI_ID,
                                                    FISCAL_YEAR,
                                                    FISCAL_QTR,
                                                    REPAIR_PARTNER_ID,
                                                    BPM_ID,
                                                    OVERRIDDEN_QTD,
                                                    UPDATED_BY,
                                                    UPDATED_ON)
                 VALUES (i_overridden_qtd_list (idx).KPI_ID,
                         i_year,
                         i_qtr,
                         i_repair_partner_id,
                         i_bpm_id,
                         i_overridden_qtd_list (idx).OVERRIDDEN_QTD,
                         i_user_id,
                         SYSDATE);



            MERGE INTO RC_KPI_MASTER
                 USING DUAL
                    ON (    KPI_ID = i_overridden_qtd_list (idx).KPI_ID
                        AND FISCAL_YEAR = i_year
                        AND FISCAL_QUARTER = i_qtr
                        AND REPAIR_PARTNER_ID = i_repair_partner_id)
            WHEN MATCHED
            THEN
                UPDATE SET
                    OVERRIDDEN_KPI_QTD =
                        i_overridden_qtd_list (idx).OVERRIDDEN_QTD
            WHEN NOT MATCHED
            THEN
                INSERT     (KPI_ID,
                            FISCAL_YEAR,
                            FISCAL_QUARTER,
                            REPAIR_PARTNER_ID,
                            OVERRIDDEN_KPI_QTD)
                    VALUES (i_overridden_qtd_list (idx).KPI_ID,
                            i_year,
                            i_qtr,
                            i_repair_partner_id,
                            i_overridden_qtd_list (idx).OVERRIDDEN_QTD);
        END LOOP;

        COMMIT;
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
                'RC_KPI_DATA_EXTRACT.RC_KPI_SAVE_OVERRIDDEN_KPI',
                'PROCEDURE',
                i_user_id,
                'N');
    END RC_KPI_SAVE_OVERRIDDEN_KPI;

    /*Procedure to fetch data for IN Transit Tab*/
    PROCEDURE RC_KPI_INTRANSIT_DETAILS (
        i_user_id                 IN     VARCHAR2,
        i_repair_partner_id       IN     NUMBER,
        i_bpm                     IN     NUMBER,
        i_year                    IN     NUMBER,
        i_qtr                     IN     VARCHAR2,
        o_wk_column_header_list      OUT CRPADM.T_NORMALISED_LIST,
        o_wk_page_load_list          OUT RC_WK_TRANSIT_DATA_LIST,
        o_wk_page_load_total         OUT RC_WK_TRANSIT_DATA_LIST,
        o_box_link                   OUT VARCHAR2,
        o_status                     OUT NUMBER)
    AS
        lv_wk_column_header_list   CRPADM.T_NORMALISED_LIST;
        lv_wk_page_load_list       RC_WK_TRANSIT_DATA_LIST;
        lv_wk_page_load_total      RC_WK_TRANSIT_DATA_LIST;
        lv_wk_data_list            RC_WEEK_DATA_LIST;
        lv_total_query             VARCHAR2 (32767);
        lv_user_id                 VARCHAR2 (100);
        lv_repair_partner_id       NUMBER;
        lv_bpm_id                  NUMBER;
        lv_year                    NUMBER;
        lv_qtr                     VARCHAR2 (100);
        lv_metric_data_query       VARCHAR2 (3500);
        lv_constraint              VARCHAR2 (3500);
        lv_fiscal_qtr              VARCHAR2 (100);
        lv_query                   VARCHAR2 (3500);
        lv_box_link                VARCHAR2 (200);
        lv_cum_metric_value        NUMBER := 0;
        lv_week_count              NUMBER := 0;
    BEGIN
        lv_user_id := i_user_id;
        lv_repair_partner_id := i_repair_partner_id;
        lv_bpm_id := i_bpm;
        lv_year := i_year;
        lv_qtr := UPPER (i_qtr);
        lv_wk_column_header_list := CRPADM.T_NORMALISED_LIST ();
        lv_wk_data_list := RC_WEEK_DATA_LIST ();
        lv_wk_page_load_list := RC_WK_TRANSIT_DATA_LIST ();
        lv_wk_page_load_total := RC_WK_TRANSIT_DATA_LIST ();
        o_status := 1;

        BEGIN
            SELECT PROPERTY_VALUE
              INTO lv_box_link
              FROM CRPADM.RC_PROPERTIES
             WHERE PROPERTY_TYPE = 'BOX LINK';

            o_box_link := lv_box_link;
        EXCEPTION
            WHEN OTHERS
            THEN
                o_box_link := '';
        END;


          SELECT fiscal_week_end_date
            BULK COLLECT INTO lv_wk_column_header_list
            FROM rmktgadm.cdm_time_hierarchy_dim
           WHERE     UPPER (FISCAL_QUARTER_NAME) = UPPER (lv_qtr)
                 AND FISCAL_WEEK_END_IND = 'Y'
        ORDER BY 1;


        lv_metric_data_query :=
               'SELECT RC_WK_TRANSIT_DATA_OBJ (PARETO_REASON_ID,
                                       PARETO_REASON,
                                       WEEK_LIST,
                                       QTR_TOTAL)
           FROM (  SELECT PAR.PARETO_REASON_ID,
                          PAR.PARETO_REASON,
                          NULL WEEK_LIST,
                          SUM(MSTR.TOTAL_DELAY) AS QTR_TOTAL
                          FROM CRPADM.RC_PARETO_REASON_MASTER PAR
                          LEFT OUTER JOIN RC_KPI_INTRANSIT MSTR
                             ON PAR.PARETO_REASON_ID = MSTR.PARETO_REASON_ID
                            WHERE PAR.PARETO_ID = 2
                             AND MSTR.FISCAL_YEAR = '
            || lv_year
            || ' 
                             AND UPPER(MSTR.FISCAL_QUARTER) = UPPER ('''
            || lv_qtr
            || ''')
                            AND PAR.ACTIVE_FLAG = '''
            || g_flag_yes
            || '''';

        IF (lv_repair_partner_id != -1)
        THEN
            lv_constraint :=
                ' AND REPAIR_PARTNER_ID = ' || lv_repair_partner_id || ' ';
        ELSIF (lv_bpm_id != -1)
        THEN
            lv_constraint :=
                   ' AND REPAIR_PARTNER_ID IN (SELECT DISTINCT REPAIR_PARTNER_ID FROM CRPADM.RC_REPAIR_PARTNER_BPM_SETUP WHERE BPM_ID = '
                || lv_bpm_id
                || ')';
        END IF;

        lv_metric_data_query :=
               lv_metric_data_query
            || lv_constraint
            || ' GROUP BY PAR.PARETO_REASON_ID, PAR.PARETO_REASON
                 ORDER BY 1)';

        EXECUTE IMMEDIATE lv_metric_data_query
            BULK COLLECT INTO lv_wk_page_load_list;

        FOR idx IN 1 .. lv_wk_page_load_list.COUNT
        LOOP
            lv_constraint := ' ';
            lv_query :=
                   'SELECT RC_WEEK_DATA_OBJ (WEEKEND_DATE, METRIC_VALUE, COLOR)
                 FROM (  SELECT FISCAL_WEEKEND_DATE AS WEEKEND_DATE,
                                METRIC_VALUE, '' '' COLOR
                           FROM (  SELECT INTR.FISCAL_WEEKEND_DATE,
                                          SUM(INTR.TOTAL_DELAY) METRIC_VALUE
                                     FROM RC_KPI_INTRANSIT INTR
                                    WHERE INTR.FISCAL_QUARTER  =
                                                           UPPER ('''
                || lv_qtr
                || ''')
            AND INTR.PARETO_REASON_ID = '
                || lv_wk_page_load_list (idx).PARETO_REASON_ID;

            IF (lv_repair_partner_id != -1)
            THEN
                lv_constraint :=
                       ' AND REPAIR_PARTNER_ID = '
                    || lv_repair_partner_id
                    || ' ';
            ELSIF (lv_bpm_id != -1)
            THEN
                lv_constraint :=
                       ' AND REPAIR_PARTNER_ID IN (SELECT DISTINCT REPAIR_PARTNER_ID FROM CRPADM.RC_REPAIR_PARTNER_BPM_SETUP WHERE BPM_ID = '
                    || lv_bpm_id
                    || ')';
            END IF;

            lv_query :=
                   lv_query
                || lv_constraint
                || ' GROUP BY INTR.FISCAL_WEEKEND_DATE)
                       ORDER BY 1)';

            EXECUTE IMMEDIATE lv_query BULK COLLECT INTO lv_wk_data_list;

            lv_wk_page_load_list (idx).WEEK_LIST := lv_wk_data_list;

            SELECT DISTINCT UPPER (fiscal_quarter_name)
              INTO lv_fiscal_qtr
              FROM rmktgadm.cdm_time_hierarchy_dim
             WHERE CURRENT_FISCAL_QUARTER_FLAG = 'Y';

            IF (    lv_repair_partner_id = -1
                AND lv_bpm_id = -1
                AND lv_qtr = lv_fiscal_qtr)
            THEN
                IF (lv_wk_data_list IS NOT NULL)
                THEN
                    lv_cum_metric_value := 0;

                    SELECT COUNT (DISTINCT FISCAL_WEEK_END_DATE)
                      INTO lv_week_count
                      FROM rmktgadm.cdm_time_hierarchy_dim
                     WHERE     FISCAL_QUARTER_NAME = UPPER (lv_qtr)
                           AND FISCAL_WEEK_END_DATE <
                               (SELECT CHL_END_TIMESTAMP
                                  FROM CRPADM.RC_CRON_HISTORY_LOG
                                 WHERE CHL_CRON_NAME = 'RC_KPI_ENGINE');

                    FOR idx1 IN 1 .. lv_week_count
                    LOOP
                        IF idx1 > lv_wk_data_list.COUNT
                        THEN
                            lv_cum_metric_value := lv_cum_metric_value + 0;
                        ELSE
                            lv_cum_metric_value :=
                                  lv_cum_metric_value
                                + lv_wk_data_list (idx1).metric_value;
                        END IF;
                    END LOOP;

                    CASE
                        WHEN lv_week_count > 0
                        THEN
                            lv_cum_metric_value :=
                                ROUND ((lv_cum_metric_value / lv_week_count),
                                       2);
                        ELSE
                            lv_cum_metric_value := 0;
                    END CASE;

                    lv_wk_page_load_list (idx).QTR_TOTAL :=
                        lv_cum_metric_value;
                END IF;
            ELSIF (    lv_repair_partner_id = -1
                   AND lv_bpm_id = -1
                   AND lv_qtr != lv_fiscal_qtr)
            THEN
                IF (lv_wk_data_list IS NOT NULL)
                THEN
                    lv_cum_metric_value := 0;

                    SELECT COUNT (DISTINCT FISCAL_WEEK_END_DATE)
                      INTO lv_week_count
                      FROM rmktgadm.cdm_time_hierarchy_dim
                     WHERE     FISCAL_QUARTER_NAME = UPPER (lv_qtr)
                           AND FISCAL_WEEK_END_DATE <
                               (SELECT CHL_END_TIMESTAMP
                                  FROM CRPADM.RC_CRON_HISTORY_LOG
                                 WHERE CHL_CRON_NAME = 'RC_KPI_ENGINE');

                    FOR idx1 IN 1 .. lv_week_count
                    LOOP
                        IF idx1 > lv_wk_data_list.COUNT
                        THEN
                            lv_cum_metric_value := lv_cum_metric_value + 0;
                        ELSE
                            lv_cum_metric_value :=
                                  lv_cum_metric_value
                                + lv_wk_data_list (idx1).metric_value;
                        END IF;
                    END LOOP;

                    CASE
                        WHEN lv_week_count > 0
                        THEN
                            lv_cum_metric_value :=
                                ROUND ((lv_cum_metric_value / lv_week_count),
                                       2);
                        ELSE
                            lv_cum_metric_value := 0;
                    END CASE;

                    lv_wk_page_load_list (idx).QTR_TOTAL :=
                        lv_cum_metric_value;
                END IF;
            ELSIF (lv_repair_partner_id != -1 AND lv_bpm_id != -1)
            THEN
                IF (lv_wk_data_list IS NOT NULL)
                THEN
                    lv_cum_metric_value := 0;

                    SELECT COUNT (DISTINCT FISCAL_WEEK_END_DATE)
                      INTO lv_week_count
                      FROM rmktgadm.cdm_time_hierarchy_dim
                     WHERE     FISCAL_QUARTER_NAME = UPPER (lv_qtr)
                           AND FISCAL_WEEK_END_DATE <
                               (SELECT CHL_END_TIMESTAMP
                                  FROM CRPADM.RC_CRON_HISTORY_LOG
                                 WHERE CHL_CRON_NAME = 'RC_KPI_ENGINE');


                    FOR idx1 IN 1 .. lv_week_count
                    LOOP
                        IF idx1 > lv_wk_data_list.COUNT
                        THEN
                            lv_cum_metric_value := lv_cum_metric_value + 0;
                        ELSE
                            lv_cum_metric_value :=
                                  lv_cum_metric_value
                                + lv_wk_data_list (idx1).metric_value;
                        END IF;
                    END LOOP;

                    CASE
                        WHEN lv_week_count > 0
                        THEN
                            lv_cum_metric_value :=
                                ROUND ((lv_cum_metric_value / lv_week_count),
                                       2);
                        ELSE
                            lv_cum_metric_value := 0;
                    END CASE;

                    lv_wk_page_load_list (idx).QTR_TOTAL :=
                        lv_cum_metric_value;
                END IF;
            END IF;
        END LOOP;

        lv_total_query :=
               'SELECT RC_WK_TRANSIT_DATA_OBJ (PARETO_REASON_ID,
                                       PARETO_REASON,
                                       WEEK_LIST,
                                       QTR_TOTAL)
               FROM (SELECT -1 PARETO_REASON_ID,
                          '' Total Delayed'' PARETO_REASON,
                          NULL WEEK_LIST, 
                          METRIC_VALUE QTR_TOTAL
                      FROM (  SELECT SUM(INTR.TOTAL_DELAY) METRIC_VALUE
                           FROM RC_KPI_INTRANSIT INTR
                                    WHERE INTR.FISCAL_QUARTER  =
                                                           UPPER ('''
            || lv_qtr
            || ''')';

        lv_query :=
               'SELECT RC_WEEK_DATA_OBJ (WEEKEND_DATE, METRIC_VALUE, COLOR)
                 FROM (  SELECT FISCAL_WEEKEND_DATE AS WEEKEND_DATE,
                                METRIC_VALUE, '' '' COLOR
                           FROM (  SELECT INTR.FISCAL_WEEKEND_DATE,
                                          SUM(INTR.TOTAL_DELAY) METRIC_VALUE
                                     FROM RC_KPI_INTRANSIT INTR
                                    WHERE INTR.FISCAL_QUARTER  =
                                                           UPPER ('''
            || lv_qtr
            || ''')';

        IF (lv_repair_partner_id != -1)
        THEN
            lv_constraint :=
                ' AND REPAIR_PARTNER_ID = ' || lv_repair_partner_id || ' ';
        ELSIF (lv_bpm_id != -1)
        THEN
            lv_constraint :=
                   ' AND REPAIR_PARTNER_ID IN (SELECT DISTINCT REPAIR_PARTNER_ID FROM CRPADM.RC_REPAIR_PARTNER_BPM_SETUP WHERE BPM_ID = '
                || lv_bpm_id
                || ')';
        END IF;

        lv_query :=
               lv_query
            || lv_constraint
            || ' GROUP BY INTR.FISCAL_WEEKEND_DATE) ORDER BY 1)';

        lv_total_query := lv_total_query || lv_constraint || '))';

        EXECUTE IMMEDIATE lv_total_query
            BULK COLLECT INTO lv_wk_page_load_total;

        lv_wk_data_list := RC_WEEK_DATA_LIST ();

        EXECUTE IMMEDIATE lv_query BULK COLLECT INTO lv_wk_data_list;

        IF lv_wk_data_list IS NOT NULL
        THEN
            lv_wk_page_load_total (1).WEEK_LIST := lv_wk_data_list;
            lv_cum_metric_value := 0;

            SELECT COUNT (DISTINCT FISCAL_WEEK_END_DATE)
              INTO lv_week_count
              FROM rmktgadm.cdm_time_hierarchy_dim
             WHERE     FISCAL_QUARTER_NAME = UPPER (lv_qtr)
                   AND FISCAL_WEEK_END_DATE <
                       (SELECT CHL_END_TIMESTAMP
                          FROM CRPADM.RC_CRON_HISTORY_LOG
                         WHERE CHL_CRON_NAME = 'RC_KPI_ENGINE');


            FOR idx1 IN 1 .. lv_week_count
            LOOP
                IF idx1 > lv_wk_data_list.COUNT
                THEN
                    lv_cum_metric_value := lv_cum_metric_value + 0;
                ELSE
                    lv_cum_metric_value :=
                          lv_cum_metric_value
                        + lv_wk_data_list (idx1).metric_value;
                END IF;
            END LOOP;

            CASE
                WHEN lv_week_count > 0
                THEN
                    lv_cum_metric_value :=
                        ROUND ((lv_cum_metric_value / lv_week_count), 2);
                ELSE
                    lv_cum_metric_value := 0;
            END CASE;

            lv_wk_page_load_total (1).QTR_TOTAL := lv_cum_metric_value;
        END IF;

        o_wk_column_header_list := lv_wk_column_header_list;
        o_wk_page_load_list := lv_wk_page_load_list;
        o_wk_page_load_total := lv_wk_page_load_total;
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
                'RC_KPI_DATA_EXTRACT.RC_KPI_INTRANSIT_DETAILS',
                'PROCEDURE',
                i_user_id,
                'N');
    END RC_KPI_INTRANSIT_DETAILS;

    /*Saving edited data for Intransit KPI*/
    PROCEDURE RC_KPI_SAVE_INTRANSIT (
        i_user_id             IN     VARCHAR2,
        i_repair_partner_id   IN     NUMBER,
        i_bpm                 IN     NUMBER,
        i_year                IN     NUMBER,
        i_qtr                 IN     VARCHAR2,
        i_wk_page_load_list   IN     RC_WK_TRANSIT_DATA_LIST,
        o_status                 OUT NUMBER)
    AS
        lv_wk_data_list    RC_WEEK_DATA_LIST;
        lv_count           NUMBER;
        lv_fical_weekend   DATE;
    BEGIN
        o_status := 1;
        lv_wk_data_list := RC_WEEK_DATA_LIST ();

        FOR idx IN 1 .. i_wk_page_load_list.COUNT ()
        LOOP
            lv_wk_data_list := RC_WEEK_DATA_LIST ();
            lv_wk_data_list := i_wk_page_load_list (idx).WEEK_LIST;

            FOR idx1 IN 1 .. lv_wk_data_list.COUNT ()
            LOOP
                lv_count := 0;
                lv_fical_weekend :=
                    TO_DATE (lv_wk_data_list (idx1).WEEKEND_DATE,
                             'DD-MON-YY');

                SELECT COUNT (*)
                  INTO lv_count
                  FROM RC_KPI_INTRANSIT
                 WHERE     PARETO_REASON_ID =
                           i_wk_page_load_list (idx).PARETO_REASON_ID
                       AND REPAIR_PARTNER_ID = i_repair_partner_id
                       AND FISCAL_WEEKEND_DATE = lv_fical_weekend;

                IF lv_count = 0
                THEN
                    INSERT INTO RC_KPI_INTRANSIT (PARETO_ID,
                                                  PARETO_REASON_ID,
                                                  REPAIR_PARTNER_ID,
                                                  TOTAL_DELAY,
                                                  FISCAL_YEAR,
                                                  FISCAL_QUARTER,
                                                  FISCAL_WEEKEND_DATE,
                                                  UPDATED_BY,
                                                  UPDATED_ON)
                             VALUES (
                                        2,
                                        i_wk_page_load_list (idx).PARETO_REASON_ID,
                                        i_repair_partner_id,
                                        lv_wk_data_list (idx1).METRIC_VALUE,
                                        (SELECT DISTINCT FISCAL_YEAR_NUMBER
                                           FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                                          WHERE FISCAL_WEEK_END_DATE =
                                                lv_fical_weekend),
                                        (SELECT DISTINCT FISCAL_QUARTER_NAME
                                           FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                                          WHERE FISCAL_WEEK_END_DATE =
                                                lv_fical_weekend),
                                        lv_fical_weekend,
                                        i_user_id,
                                        SYSDATE);
                ELSE
                    UPDATE RC_KPI_INTRANSIT
                       SET TOTAL_DELAY = lv_wk_data_list (idx1).METRIC_VALUE,
                           UPDATED_BY = i_user_id,
                           UPDATED_ON = SYSDATE
                     WHERE     PARETO_REASON_ID =
                               i_wk_page_load_list (idx).PARETO_REASON_ID
                           AND REPAIR_PARTNER_ID = i_repair_partner_id
                           AND FISCAL_WEEKEND_DATE = lv_fical_weekend;
                END IF;
            END LOOP;
        END LOOP;

        COMMIT;

        /*Call to KPI Engine to populate KPI MASTER Table whenever user edits intransit data*/
        RC_KPI_ENGINE.RC_KPI_INTRANSIT_MASTER_LOAD (1);
    EXCEPTION
        WHEN OTHERS
        THEN
            o_status := 0;
            ROLLBACK;
            g_error_msg :=
                   SUBSTR (SQLERRM, 1, 200)
                || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
            -- Logging exception
            CRPADM.RC_GLOBAL_ERROR_LOGGING (
                'OTHERS',
                g_error_msg,
                NULL,
                'RC_KPI_DATA_EXTRACT.RC_KPI_SAVE_INTRANSIT',
                'PROCEDURE',
                i_user_id,
                'N');
    END RC_KPI_SAVE_INTRANSIT;

    /*Procedure to fetch data for Cycle Count Tab*/
    PROCEDURE RC_KPI_CYCLE_COUNT_DETAILS (
        i_user_id                 IN     VARCHAR2,
        i_repair_partner_id       IN     NUMBER,
        i_bpm                     IN     NUMBER,
        i_year                    IN     NUMBER,
        i_qtr                     IN     VARCHAR2,
        i_bts_site                IN     NUMBER,
        o_wk_column_header_list      OUT CRPADM.T_NORMALISED_LIST,
        o_wk_page_load_list          OUT RC_CYCLE_COUNT_DATA_LIST,
        o_box_link                   OUT VARCHAR2,
        o_status                     OUT NUMBER)
    AS
        lv_wk_column_header_list   CRPADM.T_NORMALISED_LIST;
        lv_wk_page_load_list       RC_CYCLE_COUNT_DATA_LIST;
        lv_wk_data_list            RC_WEEK_DATA_LIST;
        lv_user_id                 VARCHAR2 (100);
        lv_repair_partner_id       NUMBER;
        lv_bpm_id                  NUMBER;
        lv_year                    NUMBER;
        lv_qtr                     VARCHAR2 (100);
        lv_metric_data_query       VARCHAR2 (32676);
        lv_constraint              VARCHAR2 (3500);
        lv_fiscal_qtr              VARCHAR2 (100);
        lv_query                   VARCHAR2 (32676);
        lv_cum_metric_value        NUMBER := 0;
        lv_week_count              NUMBER := 0;
        lv_box_link                VARCHAR2 (200);
        lv_disc_flag               VARCHAR2 (100) := '';
        lv_disc_flag_grp           VARCHAR2 (100) := '';
        lv_bts_disc_flag           VARCHAR2 (100) := '';
        lv_bts_disc_flag_grp       VARCHAR2 (100) := '';
        lv_rp_query                VARCHAR2 (3500);
        lv_rp_count                NUMBER;
        lv_req_qtr_end_date        DATE;
        lv_current_qtr_end_date    DATE;
        lv_bts_site_id             NUMBER;
        lv_bts_query               VARCHAR2 (3500);
    BEGIN
        lv_user_id := i_user_id;
        lv_repair_partner_id := i_repair_partner_id;
        lv_bpm_id := i_bpm;
        lv_year := i_year;
        lv_qtr := UPPER (i_qtr);
        lv_wk_column_header_list := CRPADM.T_NORMALISED_LIST ();
        lv_wk_data_list := RC_WEEK_DATA_LIST ();
        lv_wk_page_load_list := RC_CYCLE_COUNT_DATA_LIST ();
        lv_bts_site_id := i_bts_site;
        o_status := 1;

        SELECT DISTINCT FISCAL_QTR_END_DATE
          INTO lv_current_qtr_end_date
          FROM rmktgadm.cdm_time_hierarchy_dim
         WHERE UPPER (FISCAL_QUARTER_NAME) = UPPER (lv_qtr);

        SELECT DISTINCT FISCAL_QTR_END_DATE
          INTO lv_req_qtr_end_date
          FROM rmktgadm.cdm_time_hierarchy_dim
         WHERE UPPER (FISCAL_QUARTER_NAME) = UPPER ('Q4 FY2018');

        BEGIN
            SELECT PROPERTY_VALUE
              INTO lv_box_link
              FROM CRPADM.RC_PROPERTIES
             WHERE PROPERTY_TYPE = 'BOX LINK';

            o_box_link := lv_box_link;
        EXCEPTION
            WHEN OTHERS
            THEN
                o_box_link := '';
        END;

          SELECT fiscal_week_end_date
            BULK COLLECT INTO lv_wk_column_header_list
            FROM rmktgadm.cdm_time_hierarchy_dim
           WHERE     UPPER (FISCAL_QUARTER_NAME) = UPPER (lv_qtr)
                 AND FISCAL_WEEK_END_IND = 'Y'
        ORDER BY 1;

        IF i_year <= 2018
        THEN
            lv_metric_data_query :=
                   'SELECT RC_CYCLE_COUNT_DATA_OBJ (CYCLE_COUNT_ID,
                                 CYCLE_COUNT_INV_TYPE,
                                 CYCLE_COUNT_VALUES_TYPE,
                                 WEEK_LIST,
                                 QTR_TOTAL)
   FROM (SELECT * FROM (SELECT CYCLE_COUNT_ID,
               CYCLE_COUNT_INV_TYPE,
               CYCLE_COUNT_VALUES_TYPE,
               WEEK_LIST,
               QTR_TOTAL,
               ROW_NUMBER () 
               OVER (
                  ORDER BY
                     CYCLE_COUNT_ID,
                     CASE
                        WHEN CYCLE_COUNT_VALUES_TYPE = ''No. of Actual Counts''
                        THEN
                           000 || CYCLE_COUNT_VALUES_TYPE
                        WHEN CYCLE_COUNT_VALUES_TYPE =
                                ''No. of Variants (first pass)''
                        THEN
                           111 || CYCLE_COUNT_VALUES_TYPE
                        WHEN CYCLE_COUNT_VALUES_TYPE =
                                ''% Compliant (first pass)''
                        THEN
                           222 || CYCLE_COUNT_VALUES_TYPE
                        WHEN CYCLE_COUNT_VALUES_TYPE =
                                ''No. of Variants (second pass)''
                        THEN
                           333 || CYCLE_COUNT_VALUES_TYPE
                        WHEN CYCLE_COUNT_VALUES_TYPE =
                                ''% Compliant (second pass)''
                        THEN
                           444 || CYCLE_COUNT_VALUES_TYPE
                        WHEN CYCLE_COUNT_VALUES_TYPE =
                                ''Adjusted (+) $''
                        THEN
                           555 || CYCLE_COUNT_VALUES_TYPE
                        WHEN CYCLE_COUNT_VALUES_TYPE =
                                ''Adjusted (-) $''
                        THEN
                           666 || CYCLE_COUNT_VALUES_TYPE
                        WHEN CYCLE_COUNT_VALUES_TYPE =
                                ''Total Adjusted $''
                        THEN
                           777 || CYCLE_COUNT_VALUES_TYPE
                        ELSE
                           888 || CYCLE_COUNT_VALUES_TYPE
                     END)RNUM
          FROM (SELECT CYCLE_COUNT_ID,
                CYCLE_COUNT_INV_TYPE,
                CYCLE_COUNT_VALUES_TYPE,
                NULL WEEK_LIST,
                SUM(CYCLE_COUNT_VALUES) QTR_TOTAL
           FROM RC_KPI_CYCLE_COUNT
          WHERE FISCAL_YEAR = '
                || lv_year
                || ' AND UPPER (FISCAL_QUARTER) = UPPER ('''
                || lv_qtr
                || ''')';
        ELSE
            lv_metric_data_query :=
                   'SELECT RC_CYCLE_COUNT_DATA_OBJ (CYCLE_COUNT_ID,
                                 CYCLE_COUNT_INV_TYPE,
                                 CYCLE_COUNT_VALUES_TYPE,
                                 WEEK_LIST,
                                 QTR_TOTAL)
   FROM (SELECT * FROM (SELECT CYCLE_COUNT_ID,
               CYCLE_COUNT_INV_TYPE,
               CYCLE_COUNT_VALUES_TYPE,
               WEEK_LIST,
               QTR_TOTAL,
               ROW_NUMBER () 
               OVER (
                  ORDER BY
                     CYCLE_COUNT_ID,
                     CASE
                        WHEN CYCLE_COUNT_VALUES_TYPE = ''No. of Actual Counts''   
                        THEN
                           000 || CYCLE_COUNT_VALUES_TYPE
                        WHEN CYCLE_COUNT_VALUES_TYPE =
                                ''System Inventory''
                        THEN
                           111 || CYCLE_COUNT_VALUES_TYPE
                        WHEN CYCLE_COUNT_VALUES_TYPE =
                                ''No. of Variants''
                        THEN
                           222 || CYCLE_COUNT_VALUES_TYPE
                        WHEN CYCLE_COUNT_VALUES_TYPE =
                                ''% Compliant''
                        THEN
                           333 || CYCLE_COUNT_VALUES_TYPE
                        WHEN CYCLE_COUNT_VALUES_TYPE =
                                ''Adjusted (+) $''
                        THEN
                           444 || CYCLE_COUNT_VALUES_TYPE
                        WHEN CYCLE_COUNT_VALUES_TYPE =
                                ''Adjusted (-) $''
                        THEN
                           555 || CYCLE_COUNT_VALUES_TYPE
                        WHEN CYCLE_COUNT_VALUES_TYPE =
                                ''Total Adjusted $''
                        THEN
                           666 || CYCLE_COUNT_VALUES_TYPE
                        ELSE
                           777 || CYCLE_COUNT_VALUES_TYPE
                     END)RNUM
          FROM (SELECT CYCLE_COUNT_ID,
                CYCLE_COUNT_INV_TYPE,
                CYCLE_COUNT_VALUES_TYPE,
                NULL WEEK_LIST,
                SUM(CYCLE_COUNT_VALUES) QTR_TOTAL
           FROM RC_KPI_CYCLE_COUNT
          WHERE  CYCLE_COUNT_ID = 1
            AND FISCAL_YEAR = '
                || lv_year
                || ' AND UPPER (FISCAL_QUARTER) = UPPER ('''
                || lv_qtr
                || ''')';
        END IF;

        IF (lv_repair_partner_id != -1)
        THEN
            lv_constraint :=
                ' AND REPAIR_PARTNER_ID = ' || lv_repair_partner_id || ' ';
        ELSIF (lv_bpm_id != -1)
        THEN
            lv_constraint :=
                   ' AND REPAIR_PARTNER_ID IN (SELECT DISTINCT REPAIR_PARTNER_ID FROM CRPADM.RC_REPAIR_PARTNER_BPM_SETUP WHERE BPM_ID = '
                || lv_bpm_id
                || ')';
        END IF;

        IF (lv_bts_site_id != -1)
        THEN
            lv_bts_query :=
                   ' AND BTS_SITE = (SELECT PROPERTY_VALUE
                                                    FROM CRPADM.RC_PROPERTIES
                                                    WHERE PROPERTY_TYPE = ''INVENTORY_SITE'' AND PROPERTY_ID = '
                || lv_bts_site_id
                || ' ) ';
            lv_bts_disc_flag := ' , NO_DISCREPANCY_FLAG COLOR ';
            lv_bts_disc_flag_grp := ' , NO_DISCREPANCY_FLAG ';
        ELSE
            lv_bts_query := ' ';
            lv_bts_disc_flag := ' , '' '' COLOR ';
            lv_bts_disc_flag_grp := ' ';
        END IF;

        IF i_year <= 2018
        THEN
            lv_metric_data_query :=
                   lv_metric_data_query
                || lv_constraint
                || ' GROUP BY CYCLE_COUNT_ID, CYCLE_COUNT_INV_TYPE, CYCLE_COUNT_VALUES_TYPE
              UNION ALL
              SELECT CYCLE_COUNT_ID,
              CYCLE_COUNT_INV_TYPE,
              ''% Compliant (first pass)'' CYCLE_COUNT_VALUES_TYPE,
               NULL WEEK_LIST,
                CASE
                  WHEN ACTUAL_COUNT_VALUES > 0
                  THEN
                     ROUND((  (  (ACTUAL_COUNT_VALUES - FIR_COUNT_VALUES)
                         / ACTUAL_COUNT_VALUES)
                      * 100),2)
                  ELSE
                     0
                END
                  QTR_TOTAL
                  FROM (SELECT *
                          FROM (  SELECT CYCLE_COUNT_ID,
                                         CYCLE_COUNT_INV_TYPE,
                                         SUM (CYCLE_COUNT_VALUES) CYCLE_COUNT_VALUES,
                                         CYCLE_COUNT_VALUES_TYPE
                                    FROM RC_KPI_CYCLE_COUNT
                                    WHERE FISCAL_YEAR = '
                || lv_year
                || ' AND UPPER (FISCAL_QUARTER) = UPPER ('''
                || lv_qtr
                || ''')'
                || lv_constraint
                || 'GROUP BY CYCLE_COUNT_ID,
                                 CYCLE_COUNT_INV_TYPE,
                                 CYCLE_COUNT_VALUES_TYPE) PIVOT (SUM (
                                                                    CYCLE_COUNT_VALUES) AS COUNT_VALUES
                                                          FOR (
                                                             CYCLE_COUNT_VALUES_TYPE)
                                                          IN  (''No. of Variants (first pass)'' AS FIR,
                                                              ''No. of Actual Counts'' AS ACTUAL)))
                                                              UNION ALL
              SELECT CYCLE_COUNT_ID,
               CYCLE_COUNT_INV_TYPE,
               ''% Compliant (second pass)'' CYCLE_COUNT_VALUES_TYPE,
               NULL WEEK_LIST,
               CASE
                  WHEN ACTUAL_COUNT_VALUES > 0
                  THEN
               ROUND((  (  (ACTUAL_COUNT_VALUES - SEC_COUNT_VALUES)
                   / ACTUAL_COUNT_VALUES)
                * 100),2)
                ELSE 0
                END
                  QTR_TOTAL
          FROM (SELECT *
                  FROM (  SELECT CYCLE_COUNT_ID,
                                 CYCLE_COUNT_INV_TYPE,
                                 SUM (CYCLE_COUNT_VALUES) CYCLE_COUNT_VALUES,
                                 CYCLE_COUNT_VALUES_TYPE
                            FROM RC_KPI_CYCLE_COUNT
                            WHERE FISCAL_YEAR = '
                || lv_year
                || ' AND UPPER (FISCAL_QUARTER) = UPPER ('''
                || lv_qtr
                || ''')'
                || lv_constraint
                || 'GROUP BY CYCLE_COUNT_ID,
                                 CYCLE_COUNT_INV_TYPE,
                                 CYCLE_COUNT_VALUES_TYPE) PIVOT (SUM (
                                                                    CYCLE_COUNT_VALUES) AS COUNT_VALUES
                                                          FOR (
                                                             CYCLE_COUNT_VALUES_TYPE)
                                                          IN  (''No. of Variants (second pass)'' AS SEC,
                                                              ''No. of Actual Counts'' AS ACTUAL)))
                                                              UNION ALL
              SELECT CYCLE_COUNT_ID,
               CYCLE_COUNT_INV_TYPE,
               ''Total Adjusted $'' CYCLE_COUNT_VALUES_TYPE,
               NULL WEEK_LIST,
               ROUND((NVL(POSITIVE_COUNT_VALUES,0) + ABS(NVL(NEGATIVE_COUNT_VALUES,0))),2)
                  QTR_TOTAL
          FROM (SELECT *
                  FROM (  SELECT CYCLE_COUNT_ID,
                                 CYCLE_COUNT_INV_TYPE,
                                 SUM (CYCLE_COUNT_VALUES) CYCLE_COUNT_VALUES,
                                 CYCLE_COUNT_VALUES_TYPE
                            FROM RC_KPI_CYCLE_COUNT
                            WHERE FISCAL_YEAR = '
                || lv_year
                || ' AND UPPER (FISCAL_QUARTER) = UPPER ('''
                || lv_qtr
                || ''')'
                || lv_constraint
                || 'GROUP BY CYCLE_COUNT_ID,
                                 CYCLE_COUNT_INV_TYPE,
                                 CYCLE_COUNT_VALUES_TYPE) PIVOT (SUM (
                                                                    CYCLE_COUNT_VALUES) AS COUNT_VALUES
                                                          FOR (
                                                             CYCLE_COUNT_VALUES_TYPE)
                                                          IN  (''Adjusted (+) $'' AS POSITIVE,
                                                              ''Adjusted (-) $'' AS NEGATIVE)))))ORDER BY RNUM)';
        ELSE
            lv_metric_data_query :=
                   lv_metric_data_query
                || lv_constraint
                || ' GROUP BY CYCLE_COUNT_ID, CYCLE_COUNT_INV_TYPE, CYCLE_COUNT_VALUES_TYPE
              UNION ALL
                            SELECT CYCLE_COUNT_ID,
                                   CYCLE_COUNT_INV_TYPE,
                                   CYCLE_COUNT_VALUES_TYPE,
                                   NULL                 WEEK_LIST,
                                   SUM (CYCLE_COUNT_VALUES) QTR_TOTAL
                              FROM RC_KPI_CYCLE_COUNT
                             WHERE     CYCLE_COUNT_ID = 2
                                   AND REPAIR_PARTNER_ID = 1 '
                || lv_bts_query
                || ' AND FISCAL_YEAR = '
                || lv_year
                || ' AND UPPER (FISCAL_QUARTER) = UPPER ('''
                || lv_qtr
                || ''')
                          GROUP BY CYCLE_COUNT_ID,
                                   CYCLE_COUNT_INV_TYPE,
                                   CYCLE_COUNT_VALUES_TYPE
              UNION ALL
              SELECT CYCLE_COUNT_ID,
              CYCLE_COUNT_INV_TYPE,
              ''% Compliant'' CYCLE_COUNT_VALUES_TYPE,
               NULL WEEK_LIST,
                CASE
                  WHEN ACTUAL_COUNT_VALUES > 0
                  THEN
                     ROUND((  (  (ACTUAL_COUNT_VALUES - FIR_COUNT_VALUES)
                         / ACTUAL_COUNT_VALUES)
                      * 100),2)
                  ELSE
                     0
                END
                  QTR_TOTAL
                  FROM (SELECT *
                          FROM (  SELECT CYCLE_COUNT_ID,
                                         CYCLE_COUNT_INV_TYPE,
                                         SUM (CYCLE_COUNT_VALUES) CYCLE_COUNT_VALUES,
                                         CYCLE_COUNT_VALUES_TYPE
                                    FROM RC_KPI_CYCLE_COUNT
                                    WHERE     CYCLE_COUNT_ID = 1
                                   AND FISCAL_YEAR = '
                || lv_year
                || ' AND UPPER (FISCAL_QUARTER) = UPPER ('''
                || lv_qtr
                || ''')'
                || lv_constraint
                || 'GROUP BY CYCLE_COUNT_ID,
                                 CYCLE_COUNT_INV_TYPE,
                                 CYCLE_COUNT_VALUES_TYPE) PIVOT (SUM (
                                                                    CYCLE_COUNT_VALUES) AS COUNT_VALUES
                                                          FOR (
                                                             CYCLE_COUNT_VALUES_TYPE)
                                                          IN  (''No. of Variants'' AS FIR,
                                                              ''System Inventory'' AS ACTUAL)))
              UNION ALL
              SELECT CYCLE_COUNT_ID,
              CYCLE_COUNT_INV_TYPE,
              ''% Compliant'' CYCLE_COUNT_VALUES_TYPE,
               NULL WEEK_LIST,
                CASE
                  WHEN ACTUAL_COUNT_VALUES > 0
                  THEN
                     ROUND((  (  (ACTUAL_COUNT_VALUES - FIR_COUNT_VALUES)
                         / ACTUAL_COUNT_VALUES)
                      * 100),2)
                  ELSE
                     0
                END
                  QTR_TOTAL
                  FROM (SELECT *
                          FROM (  SELECT CYCLE_COUNT_ID,
                                         CYCLE_COUNT_INV_TYPE,
                                         SUM (CYCLE_COUNT_VALUES) CYCLE_COUNT_VALUES,
                                         CYCLE_COUNT_VALUES_TYPE
                                    FROM RC_KPI_CYCLE_COUNT
                                    WHERE     CYCLE_COUNT_ID = 2
                                    AND REPAIR_PARTNER_ID = 1 '
                || lv_bts_query
                || ' AND FISCAL_YEAR = '
                || lv_year
                || ' AND UPPER (FISCAL_QUARTER) = UPPER ('''
                || lv_qtr
                || ''') GROUP BY CYCLE_COUNT_ID,
                                 CYCLE_COUNT_INV_TYPE,
                                 CYCLE_COUNT_VALUES_TYPE) PIVOT (SUM (
                                                                    CYCLE_COUNT_VALUES) AS COUNT_VALUES
                                                          FOR (
                                                             CYCLE_COUNT_VALUES_TYPE)
                                                          IN  (''No. of Variants'' AS FIR,
                                                              ''System Inventory'' AS ACTUAL)))
              UNION ALL
              SELECT CYCLE_COUNT_ID,
               CYCLE_COUNT_INV_TYPE,
               ''Total Adjusted $'' CYCLE_COUNT_VALUES_TYPE,
               NULL WEEK_LIST,
               ROUND((NVL(POSITIVE_COUNT_VALUES,0) + ABS(NVL(NEGATIVE_COUNT_VALUES,0))),2)
                  QTR_TOTAL
          FROM (SELECT *
                  FROM (  SELECT CYCLE_COUNT_ID,
                                 CYCLE_COUNT_INV_TYPE,
                                 SUM (CYCLE_COUNT_VALUES) CYCLE_COUNT_VALUES,
                                 CYCLE_COUNT_VALUES_TYPE
                            FROM RC_KPI_CYCLE_COUNT
                            WHERE     CYCLE_COUNT_ID = 1
                                   AND FISCAL_YEAR = '
                || lv_year
                || ' AND UPPER (FISCAL_QUARTER) = UPPER ('''
                || lv_qtr
                || ''')'
                || lv_constraint
                || 'GROUP BY CYCLE_COUNT_ID,
                                 CYCLE_COUNT_INV_TYPE,
                                 CYCLE_COUNT_VALUES_TYPE) PIVOT (SUM (
                                                                    CYCLE_COUNT_VALUES) AS COUNT_VALUES
                                                          FOR (
                                                             CYCLE_COUNT_VALUES_TYPE)
                                                          IN  (''Adjusted (+) $'' AS POSITIVE,
                                                              ''Adjusted (-) $'' AS NEGATIVE)))
             UNION ALL
              SELECT CYCLE_COUNT_ID,
               CYCLE_COUNT_INV_TYPE,
               ''Total Adjusted $'' CYCLE_COUNT_VALUES_TYPE,
               NULL WEEK_LIST,
               ROUND((NVL(POSITIVE_COUNT_VALUES,0) + ABS(NVL(NEGATIVE_COUNT_VALUES,0))),2)
                  QTR_TOTAL
          FROM (SELECT *
                  FROM (  SELECT CYCLE_COUNT_ID,
                                 CYCLE_COUNT_INV_TYPE,
                                 SUM (CYCLE_COUNT_VALUES) CYCLE_COUNT_VALUES,
                                 CYCLE_COUNT_VALUES_TYPE
                            FROM RC_KPI_CYCLE_COUNT
                            WHERE     CYCLE_COUNT_ID = 2
                            AND REPAIR_PARTNER_ID = 1 '
                || lv_bts_query
                || ' AND FISCAL_YEAR = '
                || lv_year
                || ' AND UPPER (FISCAL_QUARTER) = UPPER ('''
                || lv_qtr
                || ''') GROUP BY CYCLE_COUNT_ID,
                                 CYCLE_COUNT_INV_TYPE,
                                 CYCLE_COUNT_VALUES_TYPE) PIVOT (SUM (
                                                                    CYCLE_COUNT_VALUES) AS COUNT_VALUES
                                                          FOR (
                                                             CYCLE_COUNT_VALUES_TYPE)
                                                          IN  (''Adjusted (+) $'' AS POSITIVE,
                                                              ''Adjusted (-) $'' AS NEGATIVE)))))ORDER BY RNUM)';
        END IF;

        EXECUTE IMMEDIATE lv_metric_data_query
            BULK COLLECT INTO lv_wk_page_load_list;

        FOR idx IN 1 .. lv_wk_page_load_list.COUNT
        LOOP
            lv_constraint := ' ';

            IF (lv_repair_partner_id != -1)
            THEN
                lv_constraint :=
                       ' AND REPAIR_PARTNER_ID = '
                    || lv_repair_partner_id
                    || ' ';
                lv_disc_flag := ' , NO_DISCREPANCY_FLAG COLOR ';
                lv_disc_flag_grp := ' , NO_DISCREPANCY_FLAG ';
            ELSIF (lv_bpm_id != -1)
            THEN
                lv_constraint :=
                       ' AND REPAIR_PARTNER_ID IN (SELECT DISTINCT REPAIR_PARTNER_ID FROM CRPADM.RC_REPAIR_PARTNER_BPM_SETUP WHERE BPM_ID = '
                    || lv_bpm_id
                    || ')';

                BEGIN
                    lv_rp_query :=
                           'SELECT COUNT(DISTINCT REPAIR_PARTNER_ID) FROM CRPADM.RC_REPAIR_PARTNER_BPM_SETUP WHERE BPM_ID = '
                        || lv_bpm_id
                        || ')';

                    EXECUTE IMMEDIATE lv_rp_query INTO lv_rp_count;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        lv_rp_count := 0;
                END;

                IF lv_rp_count = 1
                THEN
                    lv_disc_flag := ' , NO_DISCREPANCY_FLAG COLOR ';
                    lv_disc_flag_grp := ' , NO_DISCREPANCY_FLAG ';
                ELSE
                    lv_disc_flag := ' , '' '' COLOR ';
                    lv_disc_flag_grp := ' ';
                END IF;
            ELSE
                lv_disc_flag := ' , '' '' COLOR ';
                lv_disc_flag_grp := ' ';
            END IF;

            IF i_year <= 2018
            THEN
                lv_query :=
                       'SELECT RC_WEEK_DATA_OBJ (WEEKEND_DATE, METRIC_VALUE, COLOR)
              FROM (  SELECT FISCAL_WEEKEND_DATE AS WEEKEND_DATE,
                             METRIC_VALUE, COLOR
                        FROM (  SELECT CYCLE_COUNT_ID,
                                        FISCAL_WEEKEND_DATE,
                                        CYCLE_COUNT_VALUES_TYPE,
                                       SUM(CYCLE_COUNT_VALUES) METRIC_VALUE'
                    || lv_disc_flag
                    || 'FROM RC_KPI_CYCLE_COUNT
                                 WHERE FISCAL_QUARTER  =
                                                        UPPER ('''
                    || lv_qtr
                    || ''') ';
            ELSE
                lv_query :=
                       'SELECT RC_WEEK_DATA_OBJ (WEEKEND_DATE, METRIC_VALUE, COLOR)
              FROM (  SELECT FISCAL_WEEKEND_DATE AS WEEKEND_DATE,
                             METRIC_VALUE, COLOR
                        FROM (  SELECT CYCLE_COUNT_ID,
                                        FISCAL_WEEKEND_DATE,
                                        CYCLE_COUNT_VALUES_TYPE,
                                       SUM(CYCLE_COUNT_VALUES) METRIC_VALUE'
                    || lv_disc_flag
                    || 'FROM RC_KPI_CYCLE_COUNT
                                 WHERE CYCLE_COUNT_ID = 1
                           AND FISCAL_QUARTER  =
                                                        UPPER ('''
                    || lv_qtr
                    || ''') ';
            END IF;

            IF i_year <= 2018
            THEN
                lv_query :=
                       lv_query
                    || lv_constraint
                    || ' GROUP BY FISCAL_WEEKEND_DATE, CYCLE_COUNT_ID, CYCLE_COUNT_VALUES_TYPE'
                    || lv_disc_flag_grp
                    || 'UNION ALL
        SELECT CYCLE_COUNT_ID,
               FISCAL_WEEKEND_DATE,
               ''% Compliant (second pass)'' CYCLE_COUNT_VALUES_TYPE,
               CASE
                  WHEN ACTUAL_COUNT_VALUES > 0
                  THEN
               ROUND((  (  (ACTUAL_COUNT_VALUES - SEC_COUNT_VALUES)
                   / ACTUAL_COUNT_VALUES)
                * 100),2)
                ELSE 0
                END
                  METRIC_VALUE'
                    || lv_disc_flag
                    || 'FROM (SELECT *
                  FROM (  SELECT CYCLE_COUNT_ID,
                                 --REPAIR_PARTNER_ID,
                                 FISCAL_WEEKEND_DATE,
                                 SUM (CYCLE_COUNT_VALUES) CYCLE_COUNT_VALUES,
                                 CYCLE_COUNT_VALUES_TYPE '
                    || lv_disc_flag_grp
                    || 'FROM RC_KPI_CYCLE_COUNT
                            WHERE FISCAL_QUARTER  = UPPER ('''
                    || lv_qtr
                    || ''')'
                    || lv_constraint
                    || 'GROUP BY CYCLE_COUNT_ID,
                                 FISCAL_WEEKEND_DATE,
                                 CYCLE_COUNT_VALUES_TYPE'
                    || lv_disc_flag_grp
                    || ') PIVOT (SUM (CYCLE_COUNT_VALUES) AS COUNT_VALUES
                                                          FOR (
                                                             CYCLE_COUNT_VALUES_TYPE)
                                                          IN  (''No. of Variants (second pass)'' AS SEC,
                                                              ''No. of Actual Counts'' AS ACTUAL)))
           UNION ALL
           SELECT CYCLE_COUNT_ID,
               FISCAL_WEEKEND_DATE,
               ''% Compliant (first pass)'' CYCLE_COUNT_VALUES_TYPE,
               CASE
                  WHEN ACTUAL_COUNT_VALUES > 0
                  THEN
               ROUND((  (  (ACTUAL_COUNT_VALUES - FIR_COUNT_VALUES)
                   / ACTUAL_COUNT_VALUES)
                * 100),2)
                ELSE 0
                END
                  METRIC_VALUE'
                    || lv_disc_flag
                    || 'FROM (SELECT *
                  FROM (  SELECT CYCLE_COUNT_ID,
                                 --REPAIR_PARTNER_ID,
                                 FISCAL_WEEKEND_DATE,
                                 SUM (CYCLE_COUNT_VALUES) CYCLE_COUNT_VALUES,
                                 CYCLE_COUNT_VALUES_TYPE '
                    || lv_disc_flag_grp
                    || 'FROM RC_KPI_CYCLE_COUNT
                            WHERE FISCAL_QUARTER  = UPPER ('''
                    || lv_qtr
                    || ''')'
                    || lv_constraint
                    || 'GROUP BY CYCLE_COUNT_ID,
                                 --REPAIR_PARTNER_ID,
                                 FISCAL_WEEKEND_DATE,
                                 CYCLE_COUNT_VALUES_TYPE'
                    || lv_disc_flag_grp
                    || ') PIVOT (SUM (  CYCLE_COUNT_VALUES) AS COUNT_VALUES
                                                          FOR (
                                                             CYCLE_COUNT_VALUES_TYPE)
                                                          IN  (''No. of Variants (first pass)'' AS FIR,
                                                              ''No. of Actual Counts'' AS ACTUAL)))
            UNION ALL
           SELECT CYCLE_COUNT_ID,
               FISCAL_WEEKEND_DATE,
               ''Total Adjusted $'' CYCLE_COUNT_VALUES_TYPE,
               ROUND ( (NVL(POSITIVE_COUNT_VALUES,0) + ABS(NVL(NEGATIVE_COUNT_VALUES,0))), 2)
          METRIC_VALUE'
                    || lv_disc_flag
                    || 'FROM (SELECT *
                  FROM (  SELECT CYCLE_COUNT_ID,
                                 FISCAL_WEEKEND_DATE,
                                 SUM (CYCLE_COUNT_VALUES) CYCLE_COUNT_VALUES,
                                 CYCLE_COUNT_VALUES_TYPE '
                    || lv_disc_flag_grp
                    || 'FROM RC_KPI_CYCLE_COUNT
                            WHERE FISCAL_QUARTER  = UPPER ('''
                    || lv_qtr
                    || ''')'
                    || lv_constraint
                    || 'GROUP BY CYCLE_COUNT_ID,
                                 FISCAL_WEEKEND_DATE,
                                 CYCLE_COUNT_VALUES_TYPE'
                    || lv_disc_flag_grp
                    || ') PIVOT (SUM ( CYCLE_COUNT_VALUES) AS COUNT_VALUES
                                                          FOR (
                                                             CYCLE_COUNT_VALUES_TYPE)
                                                          IN  (''Adjusted (+) $'' AS POSITIVE,
                                                               ''Adjusted (-) $'' AS NEGATIVE))))
                                                              WHERE CYCLE_COUNT_ID = '
                    || lv_wk_page_load_list (idx).CYCLE_COUNT_ID
                    || ' AND CYCLE_COUNT_VALUES_TYPE = '''
                    || lv_wk_page_load_list (idx).CYCLE_COUNT_VALUES_TYPE
                    || ''' ORDER BY WEEKEND_DATE)';
            ELSE
                lv_query :=
                       lv_query
                    || lv_constraint
                    || ' GROUP BY FISCAL_WEEKEND_DATE, CYCLE_COUNT_ID, CYCLE_COUNT_VALUES_TYPE'
                    || lv_disc_flag_grp
                    || ' UNION ALL
               SELECT CYCLE_COUNT_ID,
                                        FISCAL_WEEKEND_DATE,
                                        CYCLE_COUNT_VALUES_TYPE,
                                       SUM(CYCLE_COUNT_VALUES) METRIC_VALUE'
                    || lv_bts_disc_flag
                    || 'FROM RC_KPI_CYCLE_COUNT
                                 WHERE CYCLE_COUNT_ID = 2
                                 AND REPAIR_PARTNER_ID = 1 '
                    || lv_bts_query
                    || ' AND FISCAL_QUARTER  =
                                                        UPPER ('''
                    || lv_qtr
                    || ''') GROUP BY FISCAL_WEEKEND_DATE, CYCLE_COUNT_ID, CYCLE_COUNT_VALUES_TYPE'
                    || lv_bts_disc_flag_grp
                    || ' UNION ALL
           SELECT CYCLE_COUNT_ID,
               FISCAL_WEEKEND_DATE,
               ''% Compliant'' CYCLE_COUNT_VALUES_TYPE,
               CASE
                  WHEN ACTUAL_COUNT_VALUES > 0
                  THEN
               ROUND((  (  (ACTUAL_COUNT_VALUES - FIR_COUNT_VALUES)
                   / ACTUAL_COUNT_VALUES)
                * 100),2)
                ELSE 0
                END
                  METRIC_VALUE'
                    || lv_disc_flag
                    || 'FROM (SELECT *
                  FROM (  SELECT CYCLE_COUNT_ID,
                                 --REPAIR_PARTNER_ID,
                                 FISCAL_WEEKEND_DATE,
                                 SUM (CYCLE_COUNT_VALUES) CYCLE_COUNT_VALUES,
                                 CYCLE_COUNT_VALUES_TYPE '
                    || lv_disc_flag_grp
                    || 'FROM RC_KPI_CYCLE_COUNT
                            WHERE CYCLE_COUNT_ID = 1
                           AND FISCAL_QUARTER  = UPPER ('''
                    || lv_qtr
                    || ''')'
                    || lv_constraint
                    || 'GROUP BY CYCLE_COUNT_ID,
                                 --REPAIR_PARTNER_ID,
                                 FISCAL_WEEKEND_DATE,
                                 CYCLE_COUNT_VALUES_TYPE'
                    || lv_disc_flag_grp
                    || ') PIVOT (SUM (  CYCLE_COUNT_VALUES) AS COUNT_VALUES
                                                          FOR (
                                                             CYCLE_COUNT_VALUES_TYPE)
                                                          IN  (''No. of Variants'' AS FIR,
                                                              ''System Inventory'' AS ACTUAL)))
            UNION ALL
           SELECT CYCLE_COUNT_ID,
               FISCAL_WEEKEND_DATE,
               ''% Compliant'' CYCLE_COUNT_VALUES_TYPE,
               CASE
                  WHEN ACTUAL_COUNT_VALUES > 0
                  THEN
               ROUND((  (  (ACTUAL_COUNT_VALUES - FIR_COUNT_VALUES)
                   / ACTUAL_COUNT_VALUES)
                * 100),2)
                ELSE 0
                END
                  METRIC_VALUE'
                    || lv_bts_disc_flag
                    || 'FROM (SELECT *
                  FROM (  SELECT CYCLE_COUNT_ID,
                                 --REPAIR_PARTNER_ID,
                                 FISCAL_WEEKEND_DATE,
                                 SUM (CYCLE_COUNT_VALUES) CYCLE_COUNT_VALUES,
                                 CYCLE_COUNT_VALUES_TYPE '
                    || lv_bts_disc_flag_grp
                    || 'FROM RC_KPI_CYCLE_COUNT
                            WHERE CYCLE_COUNT_ID = 2
                            AND REPAIR_PARTNER_ID = 1 '
                    || lv_bts_query
                    || ' AND FISCAL_QUARTER  = UPPER ('''
                    || lv_qtr
                    || ''') GROUP BY CYCLE_COUNT_ID,
                                 --REPAIR_PARTNER_ID,
                                 FISCAL_WEEKEND_DATE,
                                 CYCLE_COUNT_VALUES_TYPE'
                    || lv_bts_disc_flag_grp
                    || ') PIVOT (SUM (  CYCLE_COUNT_VALUES) AS COUNT_VALUES
                                                          FOR (
                                                             CYCLE_COUNT_VALUES_TYPE)
                                                          IN  (''No. of Variants'' AS FIR,
                                                              ''System Inventory'' AS ACTUAL)))
            UNION ALL
           SELECT CYCLE_COUNT_ID,
               FISCAL_WEEKEND_DATE,
               ''Total Adjusted $'' CYCLE_COUNT_VALUES_TYPE,
               ROUND ( (NVL(POSITIVE_COUNT_VALUES,0) + ABS(NVL(NEGATIVE_COUNT_VALUES,0))), 2)
          METRIC_VALUE'
                    || lv_disc_flag
                    || 'FROM (SELECT *
                  FROM (  SELECT CYCLE_COUNT_ID,
                                 FISCAL_WEEKEND_DATE,
                                 SUM (CYCLE_COUNT_VALUES) CYCLE_COUNT_VALUES,
                                 CYCLE_COUNT_VALUES_TYPE '
                    || lv_disc_flag_grp
                    || 'FROM RC_KPI_CYCLE_COUNT
                            WHERE CYCLE_COUNT_ID = 1
                           AND FISCAL_QUARTER  = UPPER ('''
                    || lv_qtr
                    || ''')'
                    || lv_constraint
                    || 'GROUP BY CYCLE_COUNT_ID,
                                 FISCAL_WEEKEND_DATE,
                                 CYCLE_COUNT_VALUES_TYPE'
                    || lv_disc_flag_grp
                    || ') PIVOT (SUM ( CYCLE_COUNT_VALUES) AS COUNT_VALUES
                                                          FOR (
                                                             CYCLE_COUNT_VALUES_TYPE)
                                                          IN  (''Adjusted (+) $'' AS POSITIVE,
                                                               ''Adjusted (-) $'' AS NEGATIVE)))
                UNION ALL
           SELECT CYCLE_COUNT_ID,
               FISCAL_WEEKEND_DATE,
               ''Total Adjusted $'' CYCLE_COUNT_VALUES_TYPE,
               ROUND ( (NVL(POSITIVE_COUNT_VALUES,0) + ABS(NVL(NEGATIVE_COUNT_VALUES,0))), 2)
          METRIC_VALUE'
                    || lv_bts_disc_flag
                    || 'FROM (SELECT *
                  FROM (  SELECT CYCLE_COUNT_ID,
                                 FISCAL_WEEKEND_DATE,
                                 SUM (CYCLE_COUNT_VALUES) CYCLE_COUNT_VALUES,
                                 CYCLE_COUNT_VALUES_TYPE '
                    || lv_bts_disc_flag_grp
                    || 'FROM RC_KPI_CYCLE_COUNT
                            WHERE CYCLE_COUNT_ID = 2
                            AND REPAIR_PARTNER_ID = 1 '
                    || lv_bts_query
                    || ' AND FISCAL_QUARTER  = UPPER ('''
                    || lv_qtr
                    || ''') GROUP BY CYCLE_COUNT_ID,
                                 FISCAL_WEEKEND_DATE,
                                 CYCLE_COUNT_VALUES_TYPE'
                    || lv_bts_disc_flag_grp
                    || ') PIVOT (SUM ( CYCLE_COUNT_VALUES) AS COUNT_VALUES
                                                          FOR (
                                                             CYCLE_COUNT_VALUES_TYPE)
                                                          IN  (''Adjusted (+) $'' AS POSITIVE,
                                                               ''Adjusted (-) $'' AS NEGATIVE))))
                                                              WHERE CYCLE_COUNT_ID = '
                    || lv_wk_page_load_list (idx).CYCLE_COUNT_ID
                    || ' AND CYCLE_COUNT_VALUES_TYPE = '''
                    || lv_wk_page_load_list (idx).CYCLE_COUNT_VALUES_TYPE
                    || ''' ORDER BY WEEKEND_DATE)';
            END IF;

            EXECUTE IMMEDIATE lv_query BULK COLLECT INTO lv_wk_data_list;

            lv_wk_page_load_list (idx).WEEK_LIST := lv_wk_data_list;

            SELECT DISTINCT UPPER (fiscal_quarter_name)
              INTO lv_fiscal_qtr
              FROM rmktgadm.cdm_time_hierarchy_dim
             WHERE CURRENT_FISCAL_QUARTER_FLAG = 'Y';

            IF    lv_wk_page_load_list (idx).CYCLE_COUNT_VALUES_TYPE =
                  '% Compliant (second pass)'
               OR lv_wk_page_load_list (idx).CYCLE_COUNT_VALUES_TYPE =
                  '% Compliant (first pass)'
               OR lv_wk_page_load_list (idx).CYCLE_COUNT_VALUES_TYPE =
                  '% Compliant'
            THEN
                IF (    lv_repair_partner_id = -1
                    AND lv_bpm_id = -1
                    AND lv_qtr = lv_fiscal_qtr)
                THEN
                    IF (lv_wk_data_list IS NOT NULL)
                    THEN
                        lv_cum_metric_value := 0;

                        SELECT COUNT (DISTINCT FISCAL_WEEK_END_DATE)
                          INTO lv_week_count
                          FROM rmktgadm.cdm_time_hierarchy_dim
                         WHERE     FISCAL_QUARTER_NAME = UPPER (lv_qtr)
                               AND FISCAL_WEEK_END_DATE <
                                   (SELECT CHL_END_TIMESTAMP
                                      FROM CRPADM.RC_CRON_HISTORY_LOG
                                     WHERE CHL_CRON_NAME = 'RC_KPI_ENGINE');

                        FOR idx1 IN 1 .. lv_week_count
                        LOOP
                            IF idx1 > lv_wk_data_list.COUNT
                            THEN
                                lv_cum_metric_value :=
                                    lv_cum_metric_value + 0;
                            ELSE
                                lv_cum_metric_value :=
                                      lv_cum_metric_value
                                    + lv_wk_data_list (idx1).metric_value;
                            END IF;
                        END LOOP;

                        CASE
                            WHEN lv_week_count > 0
                            THEN
                                lv_cum_metric_value :=
                                    ROUND (
                                        (lv_cum_metric_value / lv_week_count),
                                        2);
                            ELSE
                                lv_cum_metric_value := 0;
                        END CASE;

                        lv_wk_page_load_list (idx).QTR_TOTAL :=
                            lv_cum_metric_value;
                    END IF;
                ELSIF (    lv_repair_partner_id = -1
                       AND lv_bpm_id = -1
                       AND lv_qtr != lv_fiscal_qtr)
                THEN
                    IF (lv_wk_data_list IS NOT NULL)
                    THEN
                        lv_cum_metric_value := 0;

                        SELECT COUNT (DISTINCT FISCAL_WEEK_END_DATE)
                          INTO lv_week_count
                          FROM rmktgadm.cdm_time_hierarchy_dim
                         WHERE     FISCAL_QUARTER_NAME = UPPER (lv_qtr)
                               AND FISCAL_WEEK_END_DATE <
                                   (SELECT CHL_END_TIMESTAMP
                                      FROM CRPADM.RC_CRON_HISTORY_LOG
                                     WHERE CHL_CRON_NAME = 'RC_KPI_ENGINE');

                        FOR idx1 IN 1 .. lv_week_count
                        LOOP
                            IF idx1 > lv_wk_data_list.COUNT
                            THEN
                                lv_cum_metric_value :=
                                    lv_cum_metric_value + 0;
                            ELSE
                                lv_cum_metric_value :=
                                      lv_cum_metric_value
                                    + lv_wk_data_list (idx1).metric_value;
                            END IF;
                        END LOOP;

                        CASE
                            WHEN lv_week_count > 0
                            THEN
                                lv_cum_metric_value :=
                                    ROUND (
                                        (lv_cum_metric_value / lv_week_count),
                                        2);
                            ELSE
                                lv_cum_metric_value := 0;
                        END CASE;

                        lv_wk_page_load_list (idx).QTR_TOTAL :=
                            lv_cum_metric_value;
                    END IF;
                ELSIF (lv_repair_partner_id != -1 AND lv_bpm_id != -1)
                THEN
                    IF (lv_wk_data_list IS NOT NULL)
                    THEN
                        lv_cum_metric_value := 0;

                        SELECT COUNT (DISTINCT FISCAL_WEEK_END_DATE)
                          INTO lv_week_count
                          FROM rmktgadm.cdm_time_hierarchy_dim
                         WHERE     FISCAL_QUARTER_NAME = UPPER (lv_qtr)
                               AND FISCAL_WEEK_END_DATE <
                                   (SELECT CHL_END_TIMESTAMP
                                      FROM CRPADM.RC_CRON_HISTORY_LOG
                                     WHERE CHL_CRON_NAME = 'RC_KPI_ENGINE');


                        FOR idx1 IN 1 .. lv_week_count
                        LOOP
                            IF idx1 > lv_wk_data_list.COUNT
                            THEN
                                lv_cum_metric_value :=
                                    lv_cum_metric_value + 0;
                            ELSE
                                lv_cum_metric_value :=
                                      lv_cum_metric_value
                                    + lv_wk_data_list (idx1).metric_value;
                            END IF;
                        END LOOP;

                        CASE
                            WHEN lv_week_count > 0
                            THEN
                                lv_cum_metric_value :=
                                    ROUND (
                                        (lv_cum_metric_value / lv_week_count),
                                        2);
                            ELSE
                                lv_cum_metric_value := 0;
                        END CASE;

                        lv_wk_page_load_list (idx).QTR_TOTAL :=
                            lv_cum_metric_value;
                    END IF;
                ELSIF (lv_repair_partner_id != -1 AND lv_bpm_id = -1)
                THEN
                    IF (lv_wk_data_list IS NOT NULL)
                    THEN
                        lv_cum_metric_value := 0;

                        SELECT COUNT (DISTINCT FISCAL_WEEK_END_DATE)
                          INTO lv_week_count
                          FROM rmktgadm.cdm_time_hierarchy_dim
                         WHERE     FISCAL_QUARTER_NAME = UPPER (lv_qtr)
                               AND FISCAL_WEEK_END_DATE <
                                   (SELECT CHL_END_TIMESTAMP
                                      FROM CRPADM.RC_CRON_HISTORY_LOG
                                     WHERE CHL_CRON_NAME = 'RC_KPI_ENGINE');


                        FOR idx1 IN 1 .. lv_week_count
                        LOOP
                            IF idx1 > lv_wk_data_list.COUNT
                            THEN
                                lv_cum_metric_value :=
                                    lv_cum_metric_value + 0;
                            ELSE
                                lv_cum_metric_value :=
                                      lv_cum_metric_value
                                    + lv_wk_data_list (idx1).metric_value;
                            END IF;
                        END LOOP;

                        CASE
                            WHEN lv_week_count > 0
                            THEN
                                lv_cum_metric_value :=
                                    ROUND (
                                        (lv_cum_metric_value / lv_week_count),
                                        2);
                            ELSE
                                lv_cum_metric_value := 0;
                        END CASE;

                        lv_wk_page_load_list (idx).QTR_TOTAL :=
                            lv_cum_metric_value;
                    END IF;
                END IF;
            END IF;
        END LOOP;

        o_wk_column_header_list := lv_wk_column_header_list;
        o_wk_page_load_list := lv_wk_page_load_list;
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
                'RC_KPI_DATA_EXTRACT.RC_KPI_CYCLE_COUNT_DETAILS',
                'PROCEDURE',
                i_user_id,
                'N');
    END RC_KPI_CYCLE_COUNT_DETAILS;

    /*Saving edited data for Cycle Count KPI*/
    PROCEDURE RC_KPI_SAVE_CYCLE_COUNT (
        i_user_id             IN     VARCHAR2,
        i_repair_partner_id   IN     NUMBER,
        i_bpm                 IN     NUMBER,
        i_year                IN     NUMBER,
        i_qtr                 IN     VARCHAR2,
        i_bts_site            IN     NUMBER,
        i_wk_page_load_list   IN     RC_CYCLE_COUNT_DATA_LIST,
        o_status                 OUT NUMBER)
    AS
        lv_wk_data_list     RC_WEEK_DATA_LIST;
        --   lv_count           NUMBER;
        lv_fiscal_weekend   DATE;
    BEGIN
        o_status := 1;
        lv_wk_data_list := RC_WEEK_DATA_LIST ();

        FOR idx IN 1 .. i_wk_page_load_list.COUNT ()
        LOOP
            lv_wk_data_list := RC_WEEK_DATA_LIST ();
            lv_wk_data_list := i_wk_page_load_list (idx).WEEK_LIST;

            FOR idx1 IN 1 .. lv_wk_data_list.COUNT ()
            LOOP
                --    lv_count := 0;

                lv_fiscal_weekend :=
                    TO_DATE (lv_wk_data_list (idx1).WEEKEND_DATE,
                             'DD-MON-YY');

                IF (i_wk_page_load_list (idx).CYCLE_COUNT_ID = 1)
                THEN
                    IF i_wk_page_load_list (idx).CYCLE_COUNT_VALUES_TYPE IN
                           ('Adjusted (+) $', 'Adjusted (-) $')
                    THEN
                        UPDATE RC_KPI_CYCLE_COUNT
                           SET NO_DISCREPANCY_FLAG = 'N',
                               DISCREPANCY_UPDATED_BY = i_user_id,
                               DISCREPANCY_UPDATED_ON = SYSDATE
                         WHERE     CYCLE_COUNT_ID =
                                   i_wk_page_load_list (idx).CYCLE_COUNT_ID
                               AND REPAIR_PARTNER_ID = i_repair_partner_id
                               AND FISCAL_WEEKEND_DATE = lv_fiscal_weekend;


                        UPDATE RC_KPI_CYCLE_COUNT
                           SET CYCLE_COUNT_VALUES =
                                   ROUND (
                                       lv_wk_data_list (idx1).METRIC_VALUE,
                                       2),
                               UPDATED_BY = i_user_id,
                               UPDATED_ON = SYSDATE
                         WHERE     CYCLE_COUNT_ID =
                                   i_wk_page_load_list (idx).CYCLE_COUNT_ID
                               AND REPAIR_PARTNER_ID = i_repair_partner_id
                               AND CYCLE_COUNT_INV_TYPE =
                                   i_wk_page_load_list (idx).CYCLE_COUNT_INV_TYPE
                               AND CYCLE_COUNT_VALUES_TYPE =
                                   i_wk_page_load_list (idx).CYCLE_COUNT_VALUES_TYPE
                               AND FISCAL_WEEKEND_DATE = lv_fiscal_weekend;
                    ELSE
                        UPDATE RC_KPI_CYCLE_COUNT
                           SET CYCLE_COUNT_VALUES =
                                   lv_wk_data_list (idx1).METRIC_VALUE,
                               UPDATED_BY = i_user_id,
                               UPDATED_ON = SYSDATE
                         WHERE     CYCLE_COUNT_ID =
                                   i_wk_page_load_list (idx).CYCLE_COUNT_ID
                               AND REPAIR_PARTNER_ID = i_repair_partner_id
                               AND CYCLE_COUNT_INV_TYPE =
                                   i_wk_page_load_list (idx).CYCLE_COUNT_INV_TYPE
                               AND CYCLE_COUNT_VALUES_TYPE =
                                   i_wk_page_load_list (idx).CYCLE_COUNT_VALUES_TYPE
                               AND FISCAL_WEEKEND_DATE = lv_fiscal_weekend;
                    END IF;
                ELSIF (i_wk_page_load_list (idx).CYCLE_COUNT_ID = 2)
                THEN
                    IF i_bts_site != -1
                    THEN
                        IF i_wk_page_load_list (idx).CYCLE_COUNT_VALUES_TYPE IN
                               ('Adjusted (+) $', 'Adjusted (-) $')
                        THEN
                            UPDATE RC_KPI_CYCLE_COUNT
                               SET NO_DISCREPANCY_FLAG = 'N',
                                   DISCREPANCY_UPDATED_BY = i_user_id,
                                   DISCREPANCY_UPDATED_ON = SYSDATE
                             WHERE     CYCLE_COUNT_ID =
                                       i_wk_page_load_list (idx).CYCLE_COUNT_ID
                                   AND FISCAL_WEEKEND_DATE =
                                       lv_fiscal_weekend
                                   AND BTS_SITE =
                                       (SELECT PROPERTY_VALUE
                                          FROM CRPADM.RC_PROPERTIES
                                         WHERE     PROPERTY_TYPE =
                                                   'INVENTORY_SITE'
                                               AND PROPERTY_ID = i_bts_site);

                            UPDATE RC_KPI_CYCLE_COUNT
                               SET CYCLE_COUNT_VALUES =
                                       ROUND (
                                           lv_wk_data_list (idx1).METRIC_VALUE,
                                           2),
                                   UPDATED_BY = i_user_id,
                                   UPDATED_ON = SYSDATE
                             WHERE     CYCLE_COUNT_ID =
                                       i_wk_page_load_list (idx).CYCLE_COUNT_ID
                                   AND CYCLE_COUNT_INV_TYPE =
                                       i_wk_page_load_list (idx).CYCLE_COUNT_INV_TYPE
                                   AND CYCLE_COUNT_VALUES_TYPE =
                                       i_wk_page_load_list (idx).CYCLE_COUNT_VALUES_TYPE
                                   AND FISCAL_WEEKEND_DATE =
                                       lv_fiscal_weekend
                                   AND BTS_SITE =
                                       (SELECT PROPERTY_VALUE
                                          FROM CRPADM.RC_PROPERTIES
                                         WHERE     PROPERTY_TYPE =
                                                   'INVENTORY_SITE'
                                               AND PROPERTY_ID = i_bts_site);
                        ELSE
                            UPDATE RC_KPI_CYCLE_COUNT
                               SET CYCLE_COUNT_VALUES =
                                       lv_wk_data_list (idx1).METRIC_VALUE,
                                   UPDATED_BY = i_user_id,
                                   UPDATED_ON = SYSDATE
                             WHERE     CYCLE_COUNT_ID =
                                       i_wk_page_load_list (idx).CYCLE_COUNT_ID
                                   AND CYCLE_COUNT_INV_TYPE =
                                       i_wk_page_load_list (idx).CYCLE_COUNT_INV_TYPE
                                   AND CYCLE_COUNT_VALUES_TYPE =
                                       i_wk_page_load_list (idx).CYCLE_COUNT_VALUES_TYPE
                                   AND FISCAL_WEEKEND_DATE =
                                       lv_fiscal_weekend
                                   AND BTS_SITE =
                                       (SELECT PROPERTY_VALUE
                                          FROM CRPADM.RC_PROPERTIES
                                         WHERE     PROPERTY_TYPE =
                                                   'INVENTORY_SITE'
                                               AND PROPERTY_ID = i_bts_site);
                        END IF;
                    END IF;
                END IF;

                COMMIT;
            END LOOP;
        END LOOP;

        COMMIT;

        /*Call to KPI Engine to populate KPI MASTER Table whenever user edits intransit data*/
        RC_KPI_ENGINE.RC_KPI_INTRANSIT_MASTER_LOAD (2);
    EXCEPTION
        WHEN OTHERS
        THEN
            o_status := 0;
            ROLLBACK;
            g_error_msg :=
                   SUBSTR (SQLERRM, 1, 200)
                || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
            -- Logging exception
            CRPADM.RC_GLOBAL_ERROR_LOGGING (
                'OTHERS',
                g_error_msg,
                NULL,
                'RC_KPI_DATA_EXTRACT.RC_KPI_SAVE_CYCLE_COUNT',
                'PROCEDURE',
                i_user_id,
                'N');
    END RC_KPI_SAVE_CYCLE_COUNT;

    /*saving no discrepancy for a particular week which will mean not adjusted values for cycle count*/
    PROCEDURE RC_KPI_SAVE_NO_DISCREPANCY (
        i_user_id                 IN     VARCHAR2,
        i_c3_bts_cycle_count_id   IN     NUMBER,
        i_repair_partner_id       IN     NUMBER,
        i_qtr_number              IN     VARCHAR2,
        i_weekend_date            IN     VARCHAR2,
        o_status                     OUT NUMBER)
    AS
        lv_fiscal_quarter_name    VARCHAR2 (100 BYTE);
        lv_fiscal_week_end_date   DATE;
        lv_cycle_count_id         NUMBER;
        lv_count                  NUMBER;
        lv_error_msg              VARCHAR2 (200 BYTE);
    BEGIN
        lv_fiscal_quarter_name := i_qtr_number;
        lv_fiscal_week_end_date := TO_DATE (i_weekend_date, 'MM/DD/YYYY');
        lv_cycle_count_id := i_c3_bts_cycle_count_id;
        o_status := 1;

        BEGIN
            SELECT COUNT (DISTINCT FISCAL_WEEK_END_DATE)
              INTO lv_count
              FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
             WHERE     FISCAL_WEEK_END_DATE = lv_fiscal_week_end_date
                   AND FISCAL_QUARTER_NAME = lv_fiscal_quarter_name
                   AND (   CURRENT_FISCAL_QUARTER_FLAG = 'Y'
                        OR PREVIOUS_FISCAL_QUARTER_FLAG = 'Y');
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_error_msg := 'Weekend date is not matching.';
        END;

        IF lv_count > 0
        THEN
            UPDATE RC_KPI_CYCLE_COUNT
               SET NO_DISCREPANCY_FLAG = 'N',
                   CYCLE_COUNT_VALUES = 0,
                   DISCREPANCY_UPDATED_BY = i_user_id,
                   DISCREPANCY_UPDATED_ON = SYSDATE
             WHERE     CYCLE_COUNT_ID = lv_cycle_count_id
                   AND REPAIR_PARTNER_ID = i_repair_partner_id
                   AND FISCAL_QUARTER = lv_fiscal_quarter_name
                   AND FISCAL_WEEKEND_DATE = lv_fiscal_week_end_date;

            --                AND CYCLE_COUNT_VALUES_TYPE IN ('Adjusted (+) $',
            --                                                'Adjusted (-) $');

            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            o_status := 0;
            ROLLBACK;
            g_error_msg :=
                   SUBSTR (SQLERRM, 1, 200)
                || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
            -- Logging exception
            CRPADM.RC_GLOBAL_ERROR_LOGGING (
                'OTHERS',
                g_error_msg,
                NULL,
                'RC_KPI_DATA_EXTRACT.RC_KPI_SAVE_NO_DISCREPANCY',
                'PROCEDURE',
                i_user_id,
                'N');
    END RC_KPI_SAVE_NO_DISCREPANCY;

    PROCEDURE RC_KPI_EMAIL_CONTENT (
        i_uploadId        IN NUMBER,
        rc_invalid_list   IN RC_CYCLE_COUNT_UPLOAD_INV_LIST)
    IS
        lv_user_id             VARCHAR2 (50);
        lv_username            VARCHAR2 (100);
        lv_uploadId            NUMBER;
        lv_userrole            VARCHAR2 (100);

        g_error_msg            VARCHAR2 (2000);
        lv_msg_from            VARCHAR2 (500);
        lv_msg_to              VARCHAR2 (500);
        lv_msg_subject         VARCHAR2 (32767);
        lv_msg_text            VARCHAR2 (32767);
        lv_output_hdr          LONG;
        lv_mailhost            VARCHAR2 (100) := 'outbound.cisco.com';
        lv_conn                UTL_SMTP.CONNECTION;
        lv_message_type        VARCHAR2 (100) := 'text/html; charset="iso-8859-1"';
        lv_crlf                VARCHAR2 (5) := CHR (13) || CHR (10);
        lv_count               NUMBER := 0;
        lv_user_count          NUMBER := 0;
        lv_output              LONG;
        lv_database_name       VARCHAR2 (50);
        lv_refresh_part_num    VARCHAR2 (10000);
        lv_temp_count          NUMBER := 0;
        lv_repair_partner_id   VARCHAR2 (50);
    BEGIN
        lv_uploadId := i_uploadId;

        SELECT ora_database_name INTO lv_database_name FROM DUAL;

        SELECT UPDATED_BY,
               USER_NAME,
               USER_EMAIL,
               USER_ROLE
          INTO lv_user_id,
               lv_username,
               lv_msg_to,
               lv_userrole
          FROM CRPADM.RC_GU_PRODUCT_REFRESH_SETUP
         WHERE UPLOAD_ID = lv_uploadId;

        --      IF (lv_userrole = 'RP')
        --      THEN
        --         SELECT REPAIR_PARTNER_ID
        --           INTO lv_repair_partner_id
        --           FROM CRPADM.RC_REPAIR_PARTNER_USER_MAP
        --          WHERE USER_NAME = lv_user_id;
        --
        --         SELECT EMAIL_ID
        --           INTO lv_msg_to
        --           FROM CRPADM.RC_RP_EXTERNAL_MAILER
        --          WHERE REPAIR_PARTNER_ID = lv_repair_partner_id
        --                    AND ACTIVE_FLAG = 'Y';
        --      END IF;

        lv_msg_from := 'refreshcentral-support@cisco.com';

        IF (rc_invalid_list.COUNT () > 0)
        THEN
            lv_msg_subject :=
                   'Processing completed with exception for Upload Id: '
                || lv_uploadId;
        ELSE
            lv_msg_subject :=
                   'Processing completed successfully for Upload Id: '
                || lv_uploadId;
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
            || lv_msg_subject
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

        lv_temp_count := rc_invalid_list.COUNT ();

        -- Attachment Part
        IF (rc_invalid_list.COUNT () > 0)
        THEN
            UTL_SMTP.WRITE_DATA (lv_conn, '--SECBOUND' || lv_crlf);
            UTL_SMTP.WRITE_DATA (
                lv_conn,
                   'Content-Type: text/plain;'
                || lv_crlf
                || ' name="CycleCountUploadErrorDetails.xls"'
                || lv_crlf
                || 'Content-Transfer_Encoding: 8bit'
                || lv_crlf
                || 'Content-Disposition: attachment;'
                || lv_crlf
                || ' filename= "CycleCountUploadErrorDetails.xls"'
                || lv_crlf
                || lv_crlf);

            lv_output_hdr :=
                   'FYQtr'
                || CHR (9)
                || 'Wk #'
                || CHR (9)
                || 'DATE_COUNT'
                || CHR (9)
                || 'WE(Week Ending Date)'
                || CHR (9)
                || 'Refresh PID'
                || CHR (9)
                || 'No. of Actual Counts'
                || CHR (9)
                || 'No. of Variants (first pass)'
                || CHR (9)
                || '2st pass actual count'
                || CHR (9)
                || 'No. of Variants (second pass)'
                || CHR (9)
                || 'Message'
                || CHR (10);

            FOR idx IN 1 .. rc_invalid_list.COUNT ()
            LOOP
                IF lv_count = 0
                THEN
                    lv_output :=
                           lv_output_hdr
                        || NVL (rc_invalid_list (idx).FISCAL_YEAR_QUARTER,
                                '-')
                        || CHR (9)
                        || NVL (rc_invalid_list (idx).FISCAL_WEEK_NUMBER, 0)
                        || CHR (9)
                        || NVL (rc_invalid_list (idx).DATE_COUNT, '-')
                        || CHR (9)
                        || NVL (rc_invalid_list (idx).FISCAL_WEEKEND_DATE,
                                '-')
                        || CHR (9)
                        || NVL (rc_invalid_list (idx).REFRESH_PART_ID, '-')
                        || CHR (9)
                        || NVL (rc_invalid_list (idx).NO_OF_ACTUAL_COUNTS, 0)
                        || CHR (9)
                        || NVL (
                               rc_invalid_list (idx).NO_OF_VARIANTS_FIRST_PASS,
                               0)
                        || CHR (9)
                        || NVL (
                               rc_invalid_list (idx).SECOND_PASS_ACTUAL_COUNTS,
                               0)
                        || CHR (9)
                        || NVL (
                               rc_invalid_list (idx).NO_OF_VARIANTS_SECOND_PASS,
                               0)
                        || CHR (9)
                        || NVL (rc_invalid_list (idx).ERROR_MSG, '-')
                        || CHR (10);
                    lv_count := lv_count + 1;
                ELSE
                    lv_output :=
                           NVL (rc_invalid_list (idx).FISCAL_YEAR_QUARTER,
                                '-')
                        || CHR (9)
                        || NVL (rc_invalid_list (idx).FISCAL_WEEK_NUMBER, 0)
                        || CHR (9)
                        || NVL (rc_invalid_list (idx).DATE_COUNT, '-')
                        || CHR (9)
                        || NVL (rc_invalid_list (idx).FISCAL_WEEKEND_DATE,
                                '-')
                        || CHR (9)
                        || NVL (rc_invalid_list (idx).REFRESH_PART_ID, '-')
                        || CHR (9)
                        || NVL (rc_invalid_list (idx).NO_OF_ACTUAL_COUNTS, 0)
                        || CHR (9)
                        || NVL (
                               rc_invalid_list (idx).NO_OF_VARIANTS_FIRST_PASS,
                               0)
                        || CHR (9)
                        || NVL (
                               rc_invalid_list (idx).SECOND_PASS_ACTUAL_COUNTS,
                               0)
                        || CHR (9)
                        || NVL (
                               rc_invalid_list (idx).NO_OF_VARIANTS_SECOND_PASS,
                               0)
                        || CHR (9)
                        || NVL (rc_invalid_list (idx).ERROR_MSG, '-')
                        || CHR (10);
                END IF;

                UTL_SMTP.WRITE_DATA (lv_conn, lv_output);
            END LOOP;
        END IF;

        -- Close data
        UTL_SMTP.CLOSE_DATA (lv_conn);
        UTL_SMTP.QUIT (lv_conn);
    EXCEPTION
        WHEN OTHERS
        THEN
            g_error_msg :=
                   SUBSTR (SQLERRM, 1, 200)
                || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
            CRPADM.RC_GLOBAL_ERROR_LOGGING (
                'OTHERS',
                g_error_msg,
                NULL,
                'RC_KPI_DATA_EXTRACT.RC_KPI_EMAIL_CONTENT',
                'PROCEDURE',
                NULL,
                'N');
    END RC_KPI_EMAIL_CONTENT;

    PROCEDURE RC_KPI_DOWNLOAD_CYCLE_COUNT (
        i_user_id                     IN     VARCHAR2,
        i_repair_partner_id           IN     NUMBER,
        i_bpm                         IN     NUMBER,
        i_year                        IN     NUMBER,
        i_qtr                         IN     VARCHAR2,
        o_cycle_count_download_list      OUT RC_CYCLE_COUNT_DOWNLOAD_LIST,
        o_msg                            OUT VARCHAR2,
        o_status                         OUT NUMBER)
    IS
        lv_cycle_count_download_list   RC_CYCLE_COUNT_DOWNLOAD_LIST;
        lv_string_list                 CRPSC.RC_NORMALISED_LIST;
        lv_msg                         VARCHAR2 (200 BYTE) DEFAULT NULL;
        lv_main_query                  VARCHAR2 (32676);
        lv_query                       VARCHAR2 (32676);
        lv_count                       NUMBER;
        lv_year                        VARCHAR2 (100 BYTE)
                                           := SUBSTR (i_year, -4, 4);
        lv_current_qtr_end_date        DATE;
        lv_req_qtr_end_date            DATE;
    BEGIN
        lv_cycle_count_download_list := RC_CYCLE_COUNT_DOWNLOAD_LIST ();
        lv_string_list := CRPSC.RC_NORMALISED_LIST ();
        o_status := 0;


        SELECT DISTINCT FISCAL_QTR_END_DATE
          INTO lv_current_qtr_end_date
          FROM rmktgadm.cdm_time_hierarchy_dim
         WHERE UPPER (FISCAL_QUARTER_NAME) = UPPER (i_qtr);

        SELECT DISTINCT FISCAL_QTR_END_DATE
          INTO lv_req_qtr_end_date
          FROM rmktgadm.cdm_time_hierarchy_dim
         WHERE UPPER (FISCAL_QUARTER_NAME) = UPPER ('Q4 FY2018');

        IF lv_current_qtr_end_date <= lv_req_qtr_end_date
        THEN
            lv_query :=
                ' SELECT CYCLE_COUNT, CASE WHEN CYCLE_COUNT = ''BTS''
         THEN BTS_SITE
          ELSE
           REPAIR_PARTNER_NAME
            END
               REPAIR_PARTNER_NAME,
               FISCAL_YEAR_QUARTER,
               FISCAL_WEEK_NUMBER,
               DATE_COUNT,
               FISCAL_WEEKEND_DATE,
               REFRESH_PART_ID,
               TAN_ID,
               NO_OF_ACTUAL_COUNTS,
               NO_OF_VARIANTS_FIRST_PASS,
                SECOND_PASS_ACTUAL_COUNTS,
               NO_OF_VARIANTS_SECOND_PASS,
               NO_OF_VARIANTS,
               SYSTEM_INVENTORY,
               UNIT_STD_COST,
               ADJUSTED_P      ADJUSTED_POSITIVE,
               ADJUSTED_N      ADJUSTED_NEGATIVE,
               UPLOADED_DATE,
               STATUS,
               UPDATED_BY UPLOADED_BY
          FROM (SELECT DISTINCT
                       CASE
                          WHEN CYCLE_COUNT_ID = 1 THEN ''C3''
                          WHEN CYCLE_COUNT_ID = 2 THEN ''BTS''
                       END
                          CYCLE_COUNT,
                       (SELECT REPAIR_PARTNER_NAME
                          FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER
                         WHERE REPAIR_PARTNER_ID = KPI.REPAIR_PARTNER_ID)
                          REPAIR_PARTNER_NAME,
                       CASE
                          WHEN BTS_SITES IS NULL THEN ''NA''
                          ELSE BTS_SITES
                       END
                          BTS_SITE,
                       (SELECT DISTINCT
                               ''FY'' || SUBSTR (FISCAL_QUARTER_ID, -4, 4)
                          FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                         WHERE     FISCAL_YEAR_NUMBER = KPI.FISCAL_YEAR
                               AND FISCAL_QUARTER_NAME = KPI.FISCAL_QUARTER
                               AND FISCAL_WEEK_NUMBER =
                                      KPI.FISCAL_WEEK_NUMBER
                               AND FISCAL_WEEK_END_DATE =
                                      KPI.FISCAL_WEEKEND_DATE)
                          FISCAL_YEAR_QUARTER,
                       FISCAL_WEEK_NUMBER,
                       TO_CHAR (UPDATED_ON, ''MM/DD/YYYY'') UPLOADED_DATE,
                       TO_CHAR (FISCAL_WEEKEND_DATE, ''MM/DD/YYYY'')
                          FISCAL_WEEKEND_DATE,
                       REFRESH_PART_ID,
                       CASE WHEN TAN_ID IS NULL THEN '' '' ELSE TAN_ID END
                          TAN_ID,
                       NO_OF_ACTUAL_COUNTS,
                        NO_OF_VARIANTS_FIRST_PASS,
                SECOND_PASS_ACTUAL_COUNTS,
                NO_OF_VARIANTS_SECOND_PASS,
                       NO_OF_VARIANTS,
                       0 SYSTEM_INVENTORY,
                       STATUS,
                       (SELECT UNIT_STD_COST_USD
                          FROM (  SELECT MAX (UNIT_STD_COST_USD)
                                            UNIT_STD_COST_USD,
                                         REFRESH_PART_ID
                                    FROM CRPADM.RC_PRODUCT_MASTER PM
                                   WHERE (   KPI.REFRESH_PART_ID =
                                                PM.REFRESH_PART_NUMBER
                                          OR KPI.REFRESH_PART_ID =
                                                PM.COMMON_PART_NUMBER
                                          OR KPI.REFRESH_PART_ID =
                                                PM.XREF_PART_NUMBER)
                                GROUP BY REFRESH_PART_ID))
                          UNIT_STD_COST,
                       CASE WHEN ADJUSTED_P > 0 THEN ADJUSTED_P ELSE 0 END
                          ADJUSTED_P,
                       CASE WHEN ADJUSTED_N < 0 THEN ADJUSTED_N ELSE 0 END
                          ADJUSTED_N,
                       TO_CHAR (DATE_COUNT, ''MM/DD/YYYY'') DATE_COUNT,
                       FISCAL_YEAR,
                       FISCAL_QUARTER,
                       REPAIR_PARTNER_ID,
                          UPDATED_BY
                  FROM RC_KPI_CYCLE_COUNT_PID_LEVEL KPI) WHERE 1 = 1 ';
        ELSE
            lv_query :=
                ' SELECT CYCLE_COUNT, CASE WHEN CYCLE_COUNT = ''BTS''
            THEN BTS_SITE
            ELSE REPAIR_PARTNER_NAME
            END
               REPAIR_PARTNER_NAME,
               FISCAL_YEAR_QUARTER,
               FISCAL_WEEK_NUMBER,
               '' ''             DATE_COUNT,
               FISCAL_WEEKEND_DATE,
               REFRESH_PART_ID,
               TAN_ID,
               NO_OF_ACTUAL_COUNTS,
               TO_NUMBER (''0'') NO_OF_VARIANTS_FIRST_PASS,
               TO_NUMBER (''0'') SECOND_PASS_ACTUAL_COUNTS,
               TO_NUMBER (''0'') NO_OF_VARIANTS_SECOND_PASS,
               NO_OF_VARIANTS,
               SYSTEM_INVENTORY,
               UNIT_STD_COST,
               ADJUSTED_P      ADJUSTED_POSITIVE,
               ADJUSTED_N      ADJUSTED_NEGATIVE,
               UPLOADED_DATE,
               STATUS,
               UPDATED_BY UPLOADED_BY
          FROM (SELECT DISTINCT
                       CASE
                          WHEN CYCLE_COUNT_ID = 1 THEN ''C3''
                          WHEN CYCLE_COUNT_ID = 2 THEN ''BTS''
                       END
                          CYCLE_COUNT,
                       (SELECT REPAIR_PARTNER_NAME
                          FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER
                         WHERE REPAIR_PARTNER_ID = KPI.REPAIR_PARTNER_ID)
                          REPAIR_PARTNER_NAME,
                       CASE
                          WHEN BTS_SITES IS NULL THEN ''NA''
                          ELSE BTS_SITES
                       END
                          BTS_SITE,
                       (SELECT DISTINCT
                               ''FY'' || SUBSTR (FISCAL_QUARTER_ID, -4, 4)
                          FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                         WHERE     FISCAL_YEAR_NUMBER = KPI.FISCAL_YEAR
                               AND FISCAL_QUARTER_NAME = KPI.FISCAL_QUARTER
                               AND FISCAL_WEEK_NUMBER =
                                      KPI.FISCAL_WEEK_NUMBER
                               AND FISCAL_WEEK_END_DATE =
                                      KPI.FISCAL_WEEKEND_DATE)
                          FISCAL_YEAR_QUARTER,
                       FISCAL_WEEK_NUMBER,
                       TO_CHAR (UPDATED_ON, ''MM/DD/YYYY'') UPLOADED_DATE,
                       TO_CHAR (FISCAL_WEEKEND_DATE, ''MM/DD/YYYY'')
                          FISCAL_WEEKEND_DATE,
                       REFRESH_PART_ID,
                       CASE WHEN TAN_ID IS NULL THEN '' '' ELSE TAN_ID END
                          TAN_ID,
                       NO_OF_ACTUAL_COUNTS,
                       NO_OF_VARIANTS,
                       CASE
                           WHEN CYCLE_COUNT_ID = 1 
                            THEN REFRESH_SITE_SYSTEM_INVENTORY
                           WHEN CYCLE_COUNT_ID = 2 
                            THEN BTS_SITE_SYSTEM_INVENTORY
                       END SYSTEM_INVENTORY,
                       STATUS,
                       (SELECT UNIT_STD_COST_USD
                          FROM (  SELECT MAX (UNIT_STD_COST_USD)
                                            UNIT_STD_COST_USD,
                                         REFRESH_PART_ID
                                    FROM CRPADM.RC_PRODUCT_MASTER PM
                                   WHERE (   KPI.REFRESH_PART_ID =
                                                PM.REFRESH_PART_NUMBER
                                          OR KPI.REFRESH_PART_ID =
                                                PM.COMMON_PART_NUMBER
                                          OR KPI.REFRESH_PART_ID =
                                                PM.XREF_PART_NUMBER)
                                GROUP BY REFRESH_PART_ID))
                          UNIT_STD_COST,
                       CASE WHEN ADJUSTED_P > 0 THEN ADJUSTED_P ELSE 0 END
                          ADJUSTED_P,
                       CASE WHEN ADJUSTED_N < 0 THEN ADJUSTED_N ELSE 0 END
                          ADJUSTED_N,
                       TO_CHAR (DATE_COUNT, ''MM/DD/YYYY'') DATE_COUNT,
                       FISCAL_YEAR,
                       FISCAL_QUARTER,
                       REPAIR_PARTNER_ID,
                          UPDATED_BY
                  FROM RC_KPI_CYCLE_COUNT_PID_LEVEL KPI) WHERE 1 = 1 ';
        END IF;

        IF i_repair_partner_id != -1
        THEN
            lv_query :=
                   lv_query
                || ' AND REPAIR_PARTNER_ID = '
                || i_repair_partner_id
                || ' AND FISCAL_YEAR = '''
                || lv_year
                || ''' AND FISCAL_QUARTER = '''
                || i_qtr
                || ''' ORDER BY FISCAL_WEEKEND_DATE';
        ELSE
            lv_query :=
                   lv_query
                || ' AND FISCAL_YEAR = '''
                || lv_year
                || ''' AND FISCAL_QUARTER = '''
                || i_qtr
                || ''' ORDER BY FISCAL_WEEKEND_DATE';
        END IF;

        lv_main_query := 'SELECT RC_CYCLE_COUNT_DOWNLOAD_OBJ (CYCLE_COUNT,
                                    REPAIR_PARTNER_NAME,
                                    FISCAL_YEAR_QUARTER,
                                    FISCAL_WEEK_NUMBER,
                                    DATE_COUNT,
                                    FISCAL_WEEKEND_DATE,
                                    REFRESH_PART_ID,
                                    TAN_ID,
                                    NO_OF_ACTUAL_COUNTS,
                                    NO_OF_VARIANTS_FIRST_PASS,
                                    SECOND_PASS_ACTUAL_COUNTS,
                                    NO_OF_VARIANTS_SECOND_PASS,
                                    NO_OF_VARIANTS,
                                    SYSTEM_INVENTORY,
                                    UNIT_STD_COST,
                                    ADJUSTED_POSITIVE,
                                    ADJUSTED_NEGATIVE,
                                    UPLOADED_DATE,
                                    STATUS,
                                    UPLOADED_BY)
        FROM ( ' || lv_query || ' )';

        EXECUTE IMMEDIATE lv_main_query
            BULK COLLECT INTO lv_cycle_count_download_list;

        lv_count := lv_cycle_count_download_list.COUNT ();

        IF lv_count = 0
        THEN
            IF i_repair_partner_id != -1
            THEN
                SELECT NO_DISCREPANCY_FLAG
                  BULK COLLECT INTO lv_string_list
                  FROM RC_KPI_CYCLE_COUNT
                 WHERE     REPAIR_PARTNER_ID = i_repair_partner_id
                       AND FISCAL_QUARTER = i_qtr
                       AND FISCAL_YEAR = lv_year;
            ELSE
                SELECT NO_DISCREPANCY_FLAG
                  BULK COLLECT INTO lv_string_list
                  FROM RC_KPI_CYCLE_COUNT
                 WHERE FISCAL_QUARTER = i_qtr AND FISCAL_YEAR = lv_year;
            END IF;

            IF 'Y' MEMBER OF lv_string_list
            THEN
                lv_msg :=
                    'No Data Present for PID level Discrepancy ' || i_qtr;
            ELSE
                lv_msg := 'No Discrepancy for quarter ' || i_qtr;
            END IF;
        END IF;

        o_cycle_count_download_list := lv_cycle_count_download_list;
        o_msg := lv_msg;
    EXCEPTION
        WHEN OTHERS
        THEN
            o_status := 0;
            ROLLBACK;
            g_error_msg :=
                   SUBSTR (SQLERRM, 1, 200)
                || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
            -- Logging exception
            CRPADM.RC_GLOBAL_ERROR_LOGGING (
                'OTHERS',
                g_error_msg,
                NULL,
                'RC_KPI_DATA_EXTRACT.RC_KPI_DOWNLOAD_CYCLE_COUNT',
                'PROCEDURE',
                i_user_id,
                'N');
    END RC_KPI_DOWNLOAD_CYCLE_COUNT;
END RC_KPI_DATA_EXTRACT;
/