CREATE OR REPLACE PACKAGE BODY CRPADM./*AppDB: 1044126*/
                                                                    "RC_SALES_FORECAST_DATA_EXTRACT"
AS
   /***********************************************************************************************************
       || Object Name    : RC_SALES_FORECAST_DATA_EXTRACT
       || Modules          : Sales Forecast data extract
       || Modification History
       ||------------------------------------------------------------------------------------------------------
       ||Date                  By                  Version       Comments
       ||------------------------------------------------------------------------------------------------------
       ||25-Sep-2018      Sweta Priyadarshi         1.0          Initial creation
       ||01-Oct-2018      Abhishekh Bhat            1.1          RC_SALES_FORECAST_PAGE_LOAD
       ||------------------------------------------------------------------------------------------------------
   *************************************************************************************************************/
   PROCEDURE RC_SALES_FORECAST_EXPORT_FETCH (
      i_forecast_quarter   IN     VARCHAR2,
      i_forecast_month     IN     VARCHAR2,
      i_forecast_year      IN     VARCHAR2,
      O_EXPORT_LIST           OUT RC_SALES_FORECAST_GU_LIST)
   IS
      LV_QUERY               CLOB;
      LV_ROW_FILTER_CLAUSE   CLOB;
      LV_ORDER_BY_CLAUSE     CLOB;
      LV_forecast_quarter    VARCHAR2 (100);
      LV_forecast_month      VARCHAR2 (100);
      LV_forecast_year       VARCHAR2 (100);
      LV_PUBLISHED_quarter   VARCHAR2 (100);
      LV_PUBLISHED_month     VARCHAR2 (100);
      LV_PUBLISHED_year      VARCHAR2 (100);
      LV_COUNT               NUMBER;
      LV_EXPORT_LIST         RC_SALES_FORECAST_GU_LIST
                                := RC_SALES_FORECAST_GU_LIST ();
   BEGIN
      INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (
                        CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                        'CRPADM.RC_SALES_FORECAST_DATA_EXTRACT.RC_SALES_FORECAST_EXPORT_FETCH',
                        'START',
                        SYSDATE);

      LV_FORECAST_QUARTER := I_FORECAST_QUARTER;
      LV_FORECAST_MONTH := I_FORECAST_MONTH;
      LV_FORECAST_YEAR := I_FORECAST_YEAR;


      SELECT DISTINCT FORECAST_QUARTER, FORECAST_MONTH, FORECAST_YEAR
        INTO LV_PUBLISHED_QUARTER, LV_PUBLISHED_MONTH, LV_PUBLISHED_YEAR
        FROM RC_SALES_FORECAST;

      SELECT COUNT (*)
        INTO LV_COUNT
        FROM RC_SALES_FORECAST_STAGING
       WHERE     FORECAST_QUARTER = LV_FORECAST_QUARTER
             AND FORECAST_MONTH = LV_FORECAST_MONTH
             AND FORECAST_YEAR = LV_FORECAST_YEAR;

      LV_ROW_FILTER_CLAUSE := ' WHERE 1=1';

      IF (LV_COUNT > 0)
      THEN
         LV_ROW_FILTER_CLAUSE :=
               LV_ROW_FILTER_CLAUSE
            || ' AND FORECAST_QUARTER='''
            || LV_FORECAST_QUARTER
            || ''' AND FORECAST_MONTH='''
            || LV_FORECAST_MONTH
            || ''' AND FORECAST_YEAR='''
            || LV_FORECAST_YEAR
            || '''';
      ELSE
         LV_ROW_FILTER_CLAUSE :=
               LV_ROW_FILTER_CLAUSE
            || ' AND FORECAST_QUARTER='''
            || LV_PUBLISHED_QUARTER
            || ''' AND FORECAST_MONTH='''
            || LV_PUBLISHED_MONTH
            || ''' AND FORECAST_YEAR='''
            || LV_PUBLISHED_YEAR
            || ''' OR (    FORECAST_QUARTER IS NULL
           AND FORECAST_MONTH IS NULL
           AND FORECAST_YEAR IS NULL)';
      END IF;


      LV_ORDER_BY_CLAUSE := ' ORDER BY PID_PRIORITY ';


      LV_QUERY :=
         'SELECT RC_SALES_FORECAST_GU_OBJ(COMMON_PART_NUMBER,
       RETAIL_PART_NUMBER,
       EXCESS_PART_NUMBER,
       UNORDERED_RF_FG,
       RF_NETTABLE_DGI_WITH_YIELD,
       TOTAL_PIPELINE_INV,
       SALES_PRIORITY,
       RF_90DAY_FORECAST,
       WS_90DAY_FORECAST,
       REFRESH_LIFE_CYCLE,
       EXCESS_LIFE_CYCLE,
       MFG_EOS_DATE,
       PID_PRIORITY,
       ADJUSTED_OVERRIDDEN_FORECAST,
       RF_ADJUSTED_FORECAST,
       RF_ADJ_OVERRIDDEN_FORECAST,
       ADJUSTED_PID_PRIORITY,
       ADJ_OVERRIDDEN_PID_PRIORITY)
            FROM 
                     (SELECT COMMON_PART_NUMBER,
                             RETAIL_PART_NUMBER,
                             EXCESS_PART_NUMBER,
                             NVL ((NVL (UNORDERED_RF_FG, 0) + NVL (UNORDERED_WS_FG, 0)), 0) AS UNORDERED_RF_FG,
                             NVL ((  NVL (RF_NETTABLE_DGI_WITHOUT_YIELD, 0)
                                     + NVL (WS_NETTABLE_DGI_WITHOUT_YIELD, 0)
                                     + NVL (POE_NETTABLE_DGI_WITHOUT_YIELD, 0)),
                                0) AS RF_NETTABLE_DGI_WITH_YIELD,
                             NVL (TOTAL_NETTABLE_PIPELINE, 0) AS TOTAL_PIPELINE_INV,
                             SALES_PRIORITY,
                             NVL (RF_90DAY_FORECAST, 0) AS RF_90DAY_FORECAST,
                             NVL (WS_90DAY_FORECAST, 0) AS WS_90DAY_FORECAST,
                             REFRESH_LIFE_CYCLE,
                             EXCESS_LIFE_CYCLE,
                             TO_CHAR (MFG_EOS_DATE, ''MM/DD/YYYY'') AS MFG_EOS_DATE,
                             PID_PRIORITY,
                             ADJUSTED_OVERRIDDEN_FORECAST,
                             NVL (RF_ADJUSTED_FORECAST, 0) AS RF_ADJUSTED_FORECAST,
                             NVL (RF_ADJ_OVERRIDDEN_FORECAST, 0) AS RF_ADJ_OVERRIDDEN_FORECAST,
                             ADJUSTED_PID_PRIORITY,
                             ADJ_OVERRIDDEN_PID_PRIORITY 
                        FROM RC_SALES_FORECAST_STAGING';

      LV_QUERY := LV_QUERY || LV_ROW_FILTER_CLAUSE || ' )';

      /*INSERT INTO TEMP_QUERY
           VALUES (LV_QUERY, SYSDATE);*/

      EXECUTE IMMEDIATE LV_QUERY BULK COLLECT INTO LV_EXPORT_LIST;

      O_EXPORT_LIST := LV_EXPORT_LIST;

      INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (
                        CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                        'CRPADM.RC_SALES_FORECAST_DATA_EXTRACT.RC_SALES_FORECAST_EXPORT_FETCH',
                        'END',
                        SYSDATE);
   EXCEPTION
      WHEN OTHERS
      THEN
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
            G_ERROR_MSG,
            NULL,
            'CRPADM.RC_SALES_FORECAST_DATA_EXTRACT.RC_SALES_FORECAST_EXPORT_FETCH',
            'PROCEDURE',
            NULL,
            'N');
   END;


   PROCEDURE RC_SALES_FORECAST_PROP_FETCH (
      O_FILTER_PID_PRIORITY_LIST      OUT CRPADM.RC_SALES_FRCST_PID_PRTY_LIST,
      O_FLTR_FRCST_QQ_MM_YY_TL_LIST   OUT CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST,
      O_PUBLISHED_QQ_MM_YY_LIST       OUT CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST,
      O_CURRENT_QQ_MM_YY_LIST         OUT CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST,
      O_FUTURE_QQ_MM_YY_LIST          OUT CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST,
      O_GU_PUBLISHED_QQ_MM_YY_LIST    OUT CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST,
      O_ADV_FLTR_QQ_MM_YY_LIST        OUT CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST,
      O_LATEST_STG_QQ_MM_YY_LIST      OUT CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST)
   IS
      LV_FILTER_PID_PRIORITY_LIST      CRPADM.RC_SALES_FRCST_PID_PRTY_LIST
                                          := RC_SALES_FRCST_PID_PRTY_LIST ();
      LV_FLTR_FRCST_QQ_MM_YY_TL_LIST   CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST
                                          := RC_SLS_FRCST_QQ_MM_YY_TL_LIST ();
      LV_TEMPLATE_ENABLED_FLAG         VARCHAR2 (100);
      LV_PUBLISHED_QQ_MM_YY_LIST       CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST
                                          := RC_SLS_FRCST_QQ_MM_YY_TL_LIST ();
      LV_CURRENT_QQ_MM_YY_LIST         CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST
                                          := RC_SLS_FRCST_QQ_MM_YY_TL_LIST ();
      LV_FUTURE_QQ_MM_YY_LIST          CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST
                                          := RC_SLS_FRCST_QQ_MM_YY_TL_LIST ();
      LV_GU_PUBLISHED_QQ_MM_YY_LIST    CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST
                                          := RC_SLS_FRCST_QQ_MM_YY_TL_LIST ();
      LV_ADV_FLTR_QQ_MM_YY_LIST        CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST
                                          := RC_SLS_FRCST_QQ_MM_YY_TL_LIST ();
      LV_LATEST_STG_QQ_MM_YY_LIST      CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST
                                          := RC_SLS_FRCST_QQ_MM_YY_TL_LIST ();

      LV_QUERY                         CLOB;
   BEGIN
      LV_QUERY := 'SELECT DISTINCT pid_priority
                FROM rc_sales_forecast
                WHERE pid_priority IS NOT NULL
                and forecast_quarter is not null 
                ORDER BY pid_priority';

      EXECUTE IMMEDIATE LV_QUERY
         BULK COLLECT INTO LV_FILTER_PID_PRIORITY_LIST;

      LV_QUERY :=
         'SELECT RC_SALES_FRCST_QQ_MM_YY_TL_OBJ (FORECAST_QUARTER,
                                      FORECAST_MONTH,
                                      FORECAST_YEAR,
                                      TEMPLATE_FLAG)
            FROM (  SELECT DISTINCT FORECAST_QUARTER, FORECAST_MONTH, FORECAST_YEAR, NVL (IS_TEMPLATE_ENABLED, ''NA'') TEMPLATE_FLAG
            FROM rc_sales_forecast_config where forecast_quarter is not null 
        ORDER BY forecast_year)';

      EXECUTE IMMEDIATE LV_QUERY
         BULK COLLECT INTO LV_FLTR_FRCST_QQ_MM_YY_TL_LIST;


      --      SELECT DISTINCT NVL (IS_TEMPLATE_ENABLED, 'NA')
      --        INTO LV_TEMPLATE_ENABLED_FLAG
      --        FROM rc_sales_forecast_config;

      LV_QUERY :=
         'SELECT RC_SALES_FRCST_QQ_MM_YY_TL_OBJ (FORECAST_QUARTER,
                                      FORECAST_MONTH,
                                      FORECAST_YEAR,
                                      TEMPLATE_FLAG) FROM (SELECT DISTINCT FORECAST_QUARTER,
                FORECAST_MONTH,
                FORECAST_YEAR,
                '''' TEMPLATE_FLAG
                FROM rc_sales_forecast
                where forecast_quarter is not null)';

      EXECUTE IMMEDIATE LV_QUERY BULK COLLECT INTO LV_PUBLISHED_QQ_MM_YY_LIST;

      LV_QUERY :=
         'SELECT RC_SALES_FRCST_QQ_MM_YY_TL_OBJ (FORECAST_QUARTER,
                                      FORECAST_MONTH,
                                      FORECAST_YEAR,
                                      TEMPLATE_FLAG) FROM
            (SELECT DISTINCT FISCAL_QUARTER_NAME FORECAST_QUARTER,
                  FISCAL_YEAR_NUMBER FORECAST_YEAR,
                  CONFIG.FORECAST_MONTH FORECAST_MONTH,
                  '' - '' TEMPLATE_FLAG
    FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM DIM
         JOIN RC_SALES_FORECAST_CONFIG CONFIG
            ON     CONFIG.FORECAST_YEAR = TO_CHAR (DIM.FISCAL_YEAR_NUMBER)
               AND CONFIG.FORECAST_QUARTER = TO_CHAR (DIM.FISCAL_QUARTER_NAME)
               AND CONFIG.FORECAST_MONTH =
                      TO_CHAR (CASE
                                  WHEN DIM.FISCAL_MONTH_NUMBER IN (1,
                                                                   4,
                                                                   7,
                                                                   10)
                                  THEN
                                     ''M1''
                                  WHEN DIM.FISCAL_MONTH_NUMBER IN (2,
                                                                   5,
                                                                   8,
                                                                   11)
                                  THEN
                                     ''M2''
                                  WHEN DIM.FISCAL_MONTH_NUMBER IN (3,
                                                                   6,
                                                                   9,
                                                                   12)
                                  THEN
                                     ''M3''
                               END)
               AND FISCAL_MONTH_ID = (SELECT FISCAL_MONTH_ID
                                        FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                                       WHERE CALENDAR_DATE = TRUNC (SYSDATE))
ORDER BY FISCAL_YEAR_NUMBER, FISCAL_QUARTER_NAME)';



      -- 'SELECT RC_SALES_FRCST_QQ_MM_YY_TL_OBJ (FORECAST_QUARTER,
      --                                      FORECAST_MONTH,
      --                                      FORECAST_YEAR,
      --                                      TEMPLATE_FLAG) FROM
      --            (SELECT FISCAL_QUARTER_NAME FORECAST_QUARTER,
      --                ''M'' || RNUM AS FORECAST_MONTH,
      --                FISCAL_YEAR_NUMBER FORECAST_YEAR,
      --                '''' TEMPLATE_FLAG
      --            FROM (SELECT *
      --          FROM (SELECT FISCAL_QUARTER_NAME,
      --                       FISCAL_MONTH_ID,
      --                       FISCAL_YEAR_NUMBER,
      --                       ROWNUM RNUM
      --                  FROM (  SELECT DISTINCT
      --                                 FISCAL_QUARTER_NAME,
      --                                 FISCAL_MONTH_ID,
      --                                 FISCAL_YEAR_NUMBER
      --                            FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
      --                           WHERE CURRENT_FISCAL_QUARTER_FLAG = ''Y''
      --                        ORDER BY 2))
      --         WHERE FISCAL_MONTH_ID = (SELECT FISCAL_MONTH_ID
      --                                    FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
      --                                   WHERE CALENDAR_DATE = TRUNC (SYSDATE))))';

      EXECUTE IMMEDIATE LV_QUERY BULK COLLECT INTO LV_CURRENT_QQ_MM_YY_LIST;

      LV_QUERY :=
         'SELECT RC_SALES_FRCST_QQ_MM_YY_TL_OBJ (FORECAST_QUARTER,
                                      FORECAST_MONTH,
                                      FORECAST_YEAR,
                                      TEMPLATE_FLAG)  FROM(SELECT DISTINCT forecast_year, forecast_quarter, forecast_month, '''' TEMPLATE_FLAG
    FROM rc_sales_forecast_config config
         JOIN rmktgadm.cdm_time_hierarchy_dim dim
            ON (    config.forecast_quarter = dim.fiscal_quarter_name
                AND forecast_month =
                       CASE
                          WHEN MOD (fiscal_month_number, 3) = 1 THEN ''M1''
                          WHEN MOD (fiscal_month_number, 3) = 2 THEN ''M2''
                          WHEN MOD (fiscal_month_number, 3) = 0 THEN ''M3''
                       END)
   WHERE fiscal_month_key >
            (SELECT DISTINCT fiscal_month_key
               FROM rc_sales_forecast sf
                    JOIN rmktgadm.cdm_time_hierarchy_dim dim
                       ON (    sf.forecast_quarter = dim.fiscal_quarter_name
                           AND sf.forecast_month =
                                  CASE
                                     WHEN MOD (fiscal_month_number, 3) = 1
                                     THEN
                                        ''M1''
                                     WHEN MOD (fiscal_month_number, 3) = 2
                                     THEN
                                        ''M2''
                                     WHEN MOD (fiscal_month_number, 3) = 0
                                     THEN
                                        ''M3''
                                  END)) and forecast_quarter is not null
ORDER BY forecast_year, forecast_quarter, forecast_month)';

      EXECUTE IMMEDIATE LV_QUERY BULK COLLECT INTO LV_FUTURE_QQ_MM_YY_LIST;


      LV_QUERY :=
         'SELECT RC_SALES_FRCST_QQ_MM_YY_TL_OBJ (FORECAST_QUARTER,
                                      FORECAST_MONTH,
                                      FORECAST_YEAR,
                                      TEMPLATE_FLAG)  FROM(SELECT forecast_year, forecast_quarter, forecast_month,IS_TEMPLATE_ENABLED template_flag 
                                                          FROM rc_sales_forecast_config
                                                         WHERE 1 = 1 
                                                         and forecast_quarter is not null
                                                         AND is_upload_enabled = ''Y'')';

      EXECUTE IMMEDIATE LV_QUERY
         BULK COLLECT INTO LV_GU_PUBLISHED_QQ_MM_YY_LIST;


      /*
            LV_QUERY :=
               'SELECT RC_SALES_FRCST_QQ_MM_YY_TL_OBJ (FORECAST_QUARTER,
                                            FORECAST_MONTH,
                                            FORECAST_YEAR,
                                            TEMPLATE_FLAG)  FROM(select distinct forecast_year, forecast_quarter, forecast_month,'''' template_flag
                                               from rc_sales_forecast where forecast_quarter is not null
                                               union
                                               select distinct forecast_year, forecast_quarter, forecast_month,'''' template_flag
                                               from rc_sales_forecast_staging where forecast_quarter is not null
                                               union
                                               select distinct forecast_year, forecast_quarter, forecast_month,'''' template_flag
                                               from rc_all_sales_forecast where forecast_quarter is not null
                                               union
                                               select forecast_year, forecast_quarter, forecast_month,'''' template_flag from rc_sales_forecast_config where IS_UPLOAD_ENABLED = ''Y'')';
                                               */

      LV_QUERY :=
         'SELECT RC_SALES_FRCST_QQ_MM_YY_TL_OBJ (FORECAST_QUARTER,
                                      FORECAST_MONTH,
                                      FORECAST_YEAR,
                                      TEMPLATE_FLAG)  FROM(select distinct forecast_year, forecast_quarter, forecast_month,'''' template_flag 
                                         from rc_sales_forecast_config)';



      EXECUTE IMMEDIATE LV_QUERY BULK COLLECT INTO LV_ADV_FLTR_QQ_MM_YY_LIST;


      LV_QUERY :=
         'SELECT RC_SALES_FRCST_QQ_MM_YY_TL_OBJ (FORECAST_QUARTER,
                                      FORECAST_MONTH,
                                      FORECAST_YEAR,
                                      TEMPLATE_FLAG)  FROM(SELECT DISTINCT forecast_year,
                forecast_quarter,
                forecast_month,
                '''' TEMPLATE_FLAG
            FROM rc_sales_forecast_staging staging
       JOIN rmktgadm.cdm_time_hierarchy_dim dim
          ON (    staging.forecast_quarter = dim.fiscal_quarter_name
              AND staging.forecast_month =
                     CASE
                        WHEN MOD (fiscal_month_number, 3) = 1 THEN ''M1''
                        WHEN MOD (fiscal_month_number, 3) = 2 THEN ''M2''
                        WHEN MOD (fiscal_month_number, 3) = 0 THEN ''M3''
                     END)
        WHERE fiscal_month_key =
          (SELECT DISTINCT MAX (fiscal_month_key)
             FROM rc_sales_forecast_staging sf
                  JOIN rmktgadm.cdm_time_hierarchy_dim dim
                     ON (    sf.forecast_quarter = dim.fiscal_quarter_name
                         AND sf.forecast_month =
                                CASE
                                   WHEN MOD (fiscal_month_number, 3) = 1
                                   THEN
                                      ''M1''
                                   WHEN MOD (fiscal_month_number, 3) = 2
                                   THEN
                                      ''M2''
                                   WHEN MOD (fiscal_month_number, 3) = 0
                                   THEN
                                      ''M3''
                                END)))';

      EXECUTE IMMEDIATE LV_QUERY
         BULK COLLECT INTO LV_LATEST_STG_QQ_MM_YY_LIST;


      O_FILTER_PID_PRIORITY_LIST := LV_FILTER_PID_PRIORITY_LIST;
      O_FLTR_FRCST_QQ_MM_YY_TL_LIST := LV_FLTR_FRCST_QQ_MM_YY_TL_LIST;
      O_PUBLISHED_QQ_MM_YY_LIST := LV_PUBLISHED_QQ_MM_YY_LIST;
      O_CURRENT_QQ_MM_YY_LIST := LV_CURRENT_QQ_MM_YY_LIST;
      O_FUTURE_QQ_MM_YY_LIST := LV_FUTURE_QQ_MM_YY_LIST;
      O_GU_PUBLISHED_QQ_MM_YY_LIST := LV_GU_PUBLISHED_QQ_MM_YY_LIST;
      O_ADV_FLTR_QQ_MM_YY_LIST := LV_ADV_FLTR_QQ_MM_YY_LIST;
      O_LATEST_STG_QQ_MM_YY_LIST := LV_LATEST_STG_QQ_MM_YY_LIST;
   EXCEPTION
      WHEN OTHERS
      THEN
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         CRPADM.RC_GLOBAL_ERROR_LOGGING ('OTHERS',
                                         G_ERROR_MSG,
                                         NULL,
                                         'RC_SALES_FORECAST_PROP_FETCH',
                                         'PROCEDURE',
                                         NULL,
                                         'N');
   END;


    PROCEDURE RC_SALES_FORECAST_GU_UPLOAD (
      I_USER_ID            IN VARCHAR2,
      I_UPLOAD_ID          IN NUMBER,
      I_FORECAST_QUARTER   IN VARCHAR2,
      I_FORECAST_MONTH     IN VARCHAR2,
      I_FORECAST_YEAR      IN VARCHAR2,
      I_UPLOAD_LIST        IN RC_SALES_FORECAST_GU_LIST)
   IS
      LV_UPLOAD_LIST              RC_SALES_FORECAST_GU_LIST
                                     := RC_SALES_FORECAST_GU_LIST ();
      LV_INVALID_LIST             RC_INVALID_SALES_FORECAST_LIST
                                     := RC_INVALID_SALES_FORECAST_LIST ();
      LV_COUNT                    NUMBER;
      LV_ERROR_MESSAGE            VARCHAR2 (500);
      LV_REFRESH_FORECAST_VALID   NUMBER;
      LV_EXCESS_FORECAST_VALID    NUMBER;
      LV_VALUE                    NUMBER;
      E_INVALID_VALUES            EXCEPTION;
      CUSTOM_EXCEPTION            EXCEPTION;
      PRAGMA EXCEPTION_INIT (CUSTOM_EXCEPTION, -20001);
      lv_forecast_quarter         VARCHAR2 (100);
      lv_forecast_month           VARCHAR2 (100);
      lv_forecast_year            VARCHAR2 (100);
      lv_pid_avail_count          NUMBER;
      lv_override_count           NUMBER;
   BEGIN
      INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (
                        CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                        'CRPADM.RC_SALES_FORECAST_DATA_EXTRACT.RC_SALES_FORECAST_GU_UPLOAD',
                        'START',
                        SYSDATE);

      LV_UPLOAD_LIST := I_UPLOAD_LIST;
      lv_forecast_quarter := I_FORECAST_QUARTER;
      lv_forecast_month := I_FORECAST_MONTH;
      lv_forecast_year := I_FORECAST_YEAR;

      DELETE FROM RC_INVALID_SALES_FORECAST_GU;

      COMMIT;


      IF (LV_UPLOAD_LIST IS NOT NULL)
      THEN
         FOR IDX IN 1 .. LV_UPLOAD_LIST.COUNT ()
         LOOP
            LV_ERROR_MESSAGE := NULL;


            BEGIN
               BEGIN
                  /* IF LENGTH (LV_UPLOAD_LIST (IDX).REFRESH_PART_NUMBER) < 3
                   THEN
                      --  LV_UPLOAD_LIST (IDX).REFRESH_PART_NUMBER := 'NA';
                      INSERT INTO rc_mstr_test
                              VALUES (
                                        LV_UPLOAD_LIST (IDX).REFRESH_PART_NUMBER,
                                        0,
                                        NULL);

                      COMMIT;
                   END IF;

                   IF LENGTH (LV_UPLOAD_LIST (IDX).EXCESS_PART_NUMBER) < 3
                   THEN
                      --   LV_UPLOAD_LIST (IDX).EXCESS_PART_NUMBER := 'NA';
                      INSERT INTO rc_mstr_test
                              VALUES (
                                        LV_UPLOAD_LIST (IDX).EXCESS_PART_NUMBER,
                                        0,
                                        NULL);

                      COMMIT;
                   END IF;
                  */
                  SELECT COUNT (*)
                    INTO LV_COUNT
                    FROM RC_SALES_FORECAST_STAGING
                   WHERE     1 = 1
                         AND (   NVL (COMMON_PART_NUMBER, 'NA') =
                                    NVL (
                                       LV_UPLOAD_LIST (IDX).COMMON_PART_NUMBER,
                                       'NA')
                              OR NVL (XREF_PART_NUMBER, 'NA') =
                                    NVL (
                                       LV_UPLOAD_LIST (IDX).COMMON_PART_NUMBER,
                                       'NA'))
                         AND NVL (RETAIL_PART_NUMBER, 'NA') =
                                NVL (
                                   LV_UPLOAD_LIST (IDX).REFRESH_PART_NUMBER,
                                   'NA')
                         AND NVL (EXCESS_PART_NUMBER, 'NA') =
                                NVL (LV_UPLOAD_LIST (IDX).EXCESS_PART_NUMBER,
                                     'NA');



                  IF (LV_COUNT = 0)
                  THEN
                     LV_ERROR_MESSAGE :=
                        'INVALID PART NUMBER OR INVALID RETAIL/EXCESS PART NUMBER';
                     RAISE E_INVALID_VALUES;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     LV_ERROR_MESSAGE :=
                        'INVALID PART NUMBER OR INVALID RETAIL/EXCESS PART NUMBER';


                     RAISE E_INVALID_VALUES;
               END;

               BEGIN
                  SELECT LENGTH (
                            TRIM (
                               TRANSLATE (
                                  LV_UPLOAD_LIST (IDX).REFRESH_FORECAST,
                                  '0123456789',
                                  ' ')))
                    INTO LV_REFRESH_FORECAST_VALID
                    FROM DUAL;


                  IF LV_REFRESH_FORECAST_VALID IS NULL
                  THEN
                     SELECT NVL (
                               TO_NUMBER (
                                  LV_UPLOAD_LIST (IDX).REFRESH_FORECAST),
                               0)
                       INTO LV_VALUE
                       FROM DUAL;
                  ELSE
                     LV_ERROR_MESSAGE := 'REFRESH FORECAST VALUE IS INVALID.';



                     RAISE E_INVALID_VALUES;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     LV_ERROR_MESSAGE := 'REFRESH FORECAST VALUE IS INVALID.';


                     RAISE E_INVALID_VALUES;
               END;

               BEGIN
                  SELECT LENGTH (
                            TRIM (
                               TRANSLATE (
                                  LV_UPLOAD_LIST (IDX).EXCESS_FORECAST,
                                  '0123456789',
                                  ' ')))
                    INTO LV_EXCESS_FORECAST_VALID
                    FROM DUAL;



                  IF LV_EXCESS_FORECAST_VALID IS NULL
                  THEN
                     SELECT NVL (
                               TO_NUMBER (
                                  LV_UPLOAD_LIST (IDX).EXCESS_FORECAST),
                               0)
                       INTO LV_VALUE
                       FROM DUAL;
                  ELSE
                     LV_ERROR_MESSAGE := 'EXCESS FORECAST VALUE IS INVALID.';
                     RAISE E_INVALID_VALUES;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     LV_ERROR_MESSAGE := 'EXCESS FORECAST VALUE IS INVALID.';
                     RAISE E_INVALID_VALUES;
               END;

               --               INSERT INTO RC_SALES_FORECAST_HIST
               --                  (SELECT RETAIL_PART_NUMBER,
               --                          EXCESS_PART_NUMBER,
               --                          XREF_PART_NUMBER,
               --                          COMMON_PART_NUMBER,
               --                          REFRESH_INVENTORY_ITEM_ID,
               --                          EXCESS_INVENTORY_ITEM_ID,
               --                          COMMON_INVENTORY_ITEM_ID,
               --                          XREF_INVENTORY_ITEM_ID,
               --                          PID_LIFE_CYCLE,
               --                          UNORDERED_RF_FG,
               --                          RF_NETTABLE_DGI_WITH_YIELD,
               --                          TOTAL_PIPELINE,
               --                          SALES_PRIORITY,
               --                          RF_90DAY_FORECAST,
               --                          WS_90DAY_FORECAST,
               --                          RF_ALLOCATION,
               --                          WS_ALLOCATION,
               --                          OUTLET_ALLOCATION,
               --                          PIPELINE_NOT_ALLOTED,
               --                          ASP_RF,
               --                          ASP_WS,
               --                          EXPECTED_REVENUE_RF,
               --                          EXPECTED_REVENUE_WS,
               --                          FORECASTED_REVENUE,
               --                          RF_SALES_3M,
               --                          WS_SALES_3M,
               --                          OUTLET_SALES_3M,
               --                          SUGGESTED_RF_MAX,
               --                          TOTAL_NEW_MAX,
               --                          NAM_RF_NEW_MAX,
               --                          EMEA_RF_NEW_MAX,
               --                          UNITS_REQB_CONSTRAINED,
               --                          UNITS_REQB_UNCONSTRAINED,
               --                          UNITS_REQ_BUILD,
               --                          RF_EXPECTED_REPAIR_COST,
               --                          WS_EXPECTED_REPAIR_COST,
               --                          TOTAL_EXPECTED_REPAIR_COST,
               --                          RF_FORECASTED_REPAIR_COST,
               --                          WS_FORECASTED_REPAIR_COST,
               --                          TOTAL_FORECASTED_REPAIR_COST,
               --                          SYSTEM_DEMAND,
               --                          REFRESH_YIELD,
               --                          SALES_FORECAST_12M,
               --                          NEW_DEMAND,
               --                          CREATED_ON,
               --                          UPDATED_BY,
               --                          UPDATED_ON,
               --                          SUBMITTED_AT,
               --                          APPROVED_AT,
               --                          APPROVAL_STATUS,
               --                          'Y',
               --                          SYSDATE,
               --                          I_USER_ID,
               --                          ASP_OUTLET,
               --                          EXPECTED_REVENUE_OUTLET,
               --                          PID_PRIORITY,
               --                          SALES_RF_ALLOCATION,
               --                          SALES_WS_ALLOCATION,
               --                          RF_ALLOCATED_FROM_DAY0,
               --                          WS_ALLOCATED_FROM_DAY0,
               --                          EXPECTED_SALES_REVENUE_RF,
               --                          EXPECTED_SALES_REVENUE_WS,
               --                          EXPECTED_SALES_REVENUE_OUTLET,
               --                          TOTL_EXPCTD_SALES_REPAIR_COST,
               --                          EXCESS_LIFE_CYCLE,
               --                          REFRESH_LIFE_CYCLE,
               --                          MFG_EOS_DATE
               --                     FROM RC_SALES_FORECAST
               --                    WHERE COMMON_PART_NUMBER =
               --                             TRIM (LV_UPLOAD_LIST (IDX).COMMON_PART_NUMBER));

               --               UPDATE RC_SALES_FORECAST
               --                  SET RF_90DAY_FORECAST =
               --                         NVL (LV_UPLOAD_LIST (IDX).REFRESH_FORECAST, 0),
               --                      WS_90DAY_FORECAST =
               --                         NVL (LV_UPLOAD_LIST (IDX).EXCESS_FORECAST, 0),
               --                      SALES_PRIORITY = LV_UPLOAD_LIST (IDX).SALES_PRIORITY,
               --                      APPROVAL_STATUS = 'DRAFT',
               --                      UPDATED_ON = SYSDATE,
               --                      UPDATED_BY = I_USER_ID
               --                WHERE TRIM (COMMON_PART_NUMBER) =
               --                         TRIM (LV_UPLOAD_LIST (IDX).COMMON_PART_NUMBER);

               --               UPDATE RC_SALES_FORECAST_STAGING
               --                  SET RF_90DAY_FORECAST =
               --                         NVL (LV_UPLOAD_LIST (IDX).REFRESH_FORECAST, 0),
               --                      WS_90DAY_FORECAST =
               --                         NVL (LV_UPLOAD_LIST (IDX).EXCESS_FORECAST, 0),
               --                      SALES_PRIORITY = LV_UPLOAD_LIST (IDX).SALES_PRIORITY
               --                WHERE TRIM (COMMON_PART_NUMBER) =
               --                         TRIM (LV_UPLOAD_LIST (IDX).COMMON_PART_NUMBER);

               INSERT INTO RC_SALES_FORECAST_STAGING_HIST (
                              RETAIL_PART_NUMBER,
                              EXCESS_PART_NUMBER,
                              XREF_PART_NUMBER,
                              COMMON_PART_NUMBER,
                              REFRESH_INVENTORY_ITEM_ID,
                              EXCESS_INVENTORY_ITEM_ID,
                              COMMON_INVENTORY_ITEM_ID,
                              XREF_INVENTORY_ITEM_ID,
                              PID_LIFE_CYCLE,
                              UNORDERED_RF_FG,
                              RF_NETTABLE_DGI_WITH_YIELD,
                              TOTAL_NETTABLE_PIPELINE,
                              SALES_PRIORITY,
                              RF_90DAY_FORECAST,
                              WS_90DAY_FORECAST,
                              NAM_RF_MAX_PERC,
                              EMEA_RF_MAX_PERC,
                              UPDATED_ON,
                              FORECASTING_PRIORITY,
                              EXPECTED_SALES_REVENUE_RF,
                              EXPECTED_SALES_REVENUE_WS,
                              EXPECTED_SALES_REVENUE_OUTLET,
                              TOTL_EXPCTD_SALES_REPAIR_COST,
                              EXCESS_LIFE_CYCLE,
                              REFRESH_LIFE_CYCLE,
                              MFG_EOS_DATE,
                              TOTAL_RF_ALLOCATION,
                              WS_ALLOCATION,
                              OUTLET_ALLOCATION,
                              PIPELINE_NOT_ALLOCATED,
                              ASP_RF,
                              ASP_WS,
                              EXPECTED_REVENUE_RF,
                              EXPECTED_REVENUE_WS,
                              FORECASTED_REVENUE,
                              RF_SALES_3M,
                              WS_SALES_3M,
                              OUTLET_SALES_3M,
                              SUGGESTED_RF_MAX,
                              TOTAL_NEW_MAX,
                              NAM_RF_NEW_MAX,
                              EMEA_RF_NEW_MAX,
                              UNITS_REQB_CONSTRAINED,
                              UNITS_REQB_UNCONSTRAINED,
                              UNITS_REQ_BUILD,
                              RF_EXPECTED_REPAIR_COST,
                              WS_EXPECTED_REPAIR_COST,
                              TOTAL_EXPECTED_REPAIR_COST,
                              RF_FORECASTED_REPAIR_COST,
                              WS_FORECASTED_REPAIR_COST,
                              TOTAL_FORECASTED_REPAIR_COST,
                              SYSTEM_DEMAND,
                              REFRESH_YIELD,
                              SALES_FORECAST_12M,
                              NEW_DEMAND,
                              CREATED_ON,
                              UPDATED_BY,
                              SUBMITTED_AT,
                              APPROVED_AT,
                              APPROVAL_STATUS,
                              ASP_OUTLET,
                              EXPECTED_REVENUE_OUTLET,
                              PID_PRIORITY,
                              SALES_RF_ALLOCATION,
                              SALES_WS_ALLOCATION,
                              RF_ALLOCATED_FROM_DAY0,
                              WS_ALLOCATED_FROM_DAY0,
                              FORECAST_QUARTER,
                              FORECAST_MONTH,
                              FORECAST_YEAR,
                              HIST_CREATED_DATE,
                              HIST_CREATED_BY,
                              UNORDERED_WS_FG,
                              RF_NETTABLE_DGI_WITHOUT_YIELD,
                              WS_NETTABLE_DGI_WITH_YIELD,
                              WS_NETTABLE_DGI_WITHOUT_YIELD,
                              TOTAL_NON_NETTABLE_PIPELINE,
                              RF_FG_ALLOCATION,
                              RF_DGI_ALLOCATION,
                              WS_ADJUSTED_FORECAST,
                              RF_ADJUSTED_FORECAST,
                              POE_NETTABLE_DGI_WITHOUT_YIELD,
                              ADJUSTED_OVERRIDDEN_FORECAST,
                              RF_ADJ_OVERRIDDEN_FORECAST,
                              ADJUSTED_PID_PRIORITY,
                              ADJ_OVERRIDDEN_PID_PRIORITY)
                  (SELECT RETAIL_PART_NUMBER,
                          EXCESS_PART_NUMBER,
                          XREF_PART_NUMBER,
                          COMMON_PART_NUMBER,
                          REFRESH_INVENTORY_ITEM_ID,
                          EXCESS_INVENTORY_ITEM_ID,
                          COMMON_INVENTORY_ITEM_ID,
                          XREF_INVENTORY_ITEM_ID,
                          PID_LIFE_CYCLE,
                          UNORDERED_RF_FG,
                          RF_NETTABLE_DGI_WITH_YIELD,
                          TOTAL_NETTABLE_PIPELINE,
                          SALES_PRIORITY,
                          RF_90DAY_FORECAST,
                          WS_90DAY_FORECAST,
                          NAM_RF_MAX_PERC,
                          EMEA_RF_MAX_PERC,
                          UPDATED_ON,
                          FORECASTING_PRIORITY,
                          EXPECTED_SALES_REVENUE_RF,
                          EXPECTED_SALES_REVENUE_WS,
                          EXPECTED_SALES_REVENUE_OUTLET,
                          TOTL_EXPCTD_SALES_REPAIR_COST,
                          EXCESS_LIFE_CYCLE,
                          REFRESH_LIFE_CYCLE,
                          MFG_EOS_DATE,
                          TOTAL_RF_ALLOCATION,
                          WS_ALLOCATION,
                          OUTLET_ALLOCATION,
                          PIPELINE_NOT_ALLOCATED,
                          ASP_RF,
                          ASP_WS,
                          EXPECTED_REVENUE_RF,
                          EXPECTED_REVENUE_WS,
                          FORECASTED_REVENUE,
                          RF_SALES_3M,
                          WS_SALES_3M,
                          OUTLET_SALES_3M,
                          SUGGESTED_RF_MAX,
                          TOTAL_NEW_MAX,
                          NAM_RF_NEW_MAX,
                          EMEA_RF_NEW_MAX,
                          UNITS_REQB_CONSTRAINED,
                          UNITS_REQB_UNCONSTRAINED,
                          UNITS_REQ_BUILD,
                          RF_EXPECTED_REPAIR_COST,
                          WS_EXPECTED_REPAIR_COST,
                          TOTAL_EXPECTED_REPAIR_COST,
                          RF_FORECASTED_REPAIR_COST,
                          WS_FORECASTED_REPAIR_COST,
                          TOTAL_FORECASTED_REPAIR_COST,
                          SYSTEM_DEMAND,
                          REFRESH_YIELD,
                          SALES_FORECAST_12M,
                          NEW_DEMAND,
                          CREATED_ON,
                          UPDATED_BY,
                          SUBMITTED_AT,
                          APPROVED_AT,
                          APPROVAL_STATUS,
                          ASP_OUTLET,
                          EXPECTED_REVENUE_OUTLET,
                          PID_PRIORITY,
                          SALES_RF_ALLOCATION,
                          SALES_WS_ALLOCATION,
                          RF_ALLOCATED_FROM_DAY0,
                          WS_ALLOCATED_FROM_DAY0,
                          FORECAST_QUARTER,
                          FORECAST_MONTH,
                          FORECAST_YEAR,
                          SYSDATE,
                          I_USER_ID,
                          UNORDERED_WS_FG,
                          RF_NETTABLE_DGI_WITHOUT_YIELD,
                          WS_NETTABLE_DGI_WITH_YIELD,
                          WS_NETTABLE_DGI_WITHOUT_YIELD,
                          TOTAL_NON_NETTABLE_PIPELINE,
                          RF_FG_ALLOCATION,
                          RF_DGI_ALLOCATION,
                          WS_ADJUSTED_FORECAST,
                          RF_ADJUSTED_FORECAST,
                          POE_NETTABLE_DGI_WITHOUT_YIELD,
                          ADJUSTED_OVERRIDDEN_FORECAST,
                          RF_ADJ_OVERRIDDEN_FORECAST,
                          ADJUSTED_PID_PRIORITY,
                          ADJ_OVERRIDDEN_PID_PRIORITY
                     FROM RC_SALES_FORECAST_STAGING
                    WHERE     TRIM (COMMON_PART_NUMBER) =
                                 TRIM (
                                    LV_UPLOAD_LIST (IDX).COMMON_PART_NUMBER)
                          AND FORECAST_QUARTER = lv_forecast_quarter
                          AND FORECAST_MONTH = lv_forecast_month
                          AND FORECAST_YEAR = lv_forecast_year);



               BEGIN
                  SELECT COUNT (*)
                    INTO lv_pid_avail_count
                    FROM RC_SALES_FORECAST_STAGING
                   WHERE     (
                   TRIM (COMMON_PART_NUMBER) =
                                TRIM (
                                   LV_UPLOAD_LIST (IDX).COMMON_PART_NUMBER)
                                   OR
                                   TRIM (RETAIL_PART_NUMBER) =
                                TRIM (
                                   LV_UPLOAD_LIST (IDX).REFRESH_PART_NUMBER)
                                   OR
                                   TRIM (EXCESS_PART_NUMBER) =
                                TRIM (
                                   LV_UPLOAD_LIST (IDX).EXCESS_PART_NUMBER)
                                   )
                         AND FORECAST_QUARTER = lv_forecast_quarter
                         AND FORECAST_MONTH = lv_forecast_month
                         AND FORECAST_YEAR = lv_forecast_year;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lv_pid_avail_count := 0;
               END;

               IF (    lv_pid_avail_count > 0
                   AND LV_UPLOAD_LIST (IDX).ADJUSTED_OVERRIDDEN_FORECAST =
                          'Y')
               THEN
                  UPDATE RC_SALES_FORECAST_STAGING
                     SET RF_ADJ_OVERRIDDEN_FORECAST =
                            NVL (LV_UPLOAD_LIST (IDX).REFRESH_FORECAST, 0),
                         ADJ_OVERRIDDEN_PID_PRIORITY =
                            DECODE (TRIM (LV_UPLOAD_LIST (IDX).PID_PRIORITY),
                                    'P1', 'P1',
                                    'P2', 'P2',
                                    'P3', 'P3',
                                    ''),
                         APPROVAL_STATUS = 'DRAFT',
                         ADJUSTED_OVERRIDDEN_FORECAST = 'Y',
                         UPDATED_ON = SYSDATE,
                         UPDATED_BY = I_USER_ID
                   WHERE     (
                   TRIM (COMMON_PART_NUMBER) =
                                TRIM (
                                   LV_UPLOAD_LIST (IDX).COMMON_PART_NUMBER)
                                   OR
                                   TRIM (RETAIL_PART_NUMBER) =
                                TRIM (
                                   LV_UPLOAD_LIST (IDX).REFRESH_PART_NUMBER)
                                   OR
                                   TRIM (EXCESS_PART_NUMBER) =
                                TRIM (
                                   LV_UPLOAD_LIST (IDX).EXCESS_PART_NUMBER)
                                   )
                         AND FORECAST_QUARTER = lv_forecast_quarter
                         AND FORECAST_MONTH = lv_forecast_month
                         AND FORECAST_YEAR = lv_forecast_year;
               ELSIF (    lv_pid_avail_count > 0
                      AND (   LV_UPLOAD_LIST (IDX).ADJUSTED_OVERRIDDEN_FORECAST =
                                 'N'
                           OR LV_UPLOAD_LIST (IDX).ADJUSTED_OVERRIDDEN_FORECAST
                                 IS NULL))
               THEN
                  UPDATE RC_SALES_FORECAST_STAGING
                     SET RF_90DAY_FORECAST =
                            NVL (LV_UPLOAD_LIST (IDX).REFRESH_FORECAST, 0),
                         WS_90DAY_FORECAST =
                            NVL (LV_UPLOAD_LIST (IDX).EXCESS_FORECAST, 0),
                         SALES_PRIORITY = LV_UPLOAD_LIST (IDX).SALES_PRIORITY,
                         PID_PRIORITY =
                            DECODE (TRIM (LV_UPLOAD_LIST (IDX).PID_PRIORITY),
                                    'P1', 'P1',
                                    'P2', 'P2',
                                    'P3', 'P3',
                                    ''),
                         APPROVAL_STATUS = 'DRAFT',
                         ADJUSTED_OVERRIDDEN_FORECAST = 'N',
                         UPDATED_ON = SYSDATE,
                         UPDATED_BY = I_USER_ID
                   WHERE     (
                   TRIM (COMMON_PART_NUMBER) =
                                TRIM (
                                   LV_UPLOAD_LIST (IDX).COMMON_PART_NUMBER)
                                   OR
                                   TRIM (RETAIL_PART_NUMBER) =
                                TRIM (
                                   LV_UPLOAD_LIST (IDX).REFRESH_PART_NUMBER)
                                   OR
                                   TRIM (EXCESS_PART_NUMBER) =
                                TRIM (
                                   LV_UPLOAD_LIST (IDX).EXCESS_PART_NUMBER)
                                   )
                         AND FORECAST_QUARTER = lv_forecast_quarter
                         AND FORECAST_MONTH = lv_forecast_month
                         AND FORECAST_YEAR = lv_forecast_year;      
                    ELSIF lv_pid_avail_count = 0
               THEN
                  INSERT
                    INTO RC_SALES_FORECAST_STAGING (
                            COMMON_PART_NUMBER,
                            RETAIL_PART_NUMBER,
                            EXCESS_PART_NUMBER,
                            XREF_PART_NUMBER,
                            COMMON_INVENTORY_ITEM_ID,
                            REFRESH_INVENTORY_ITEM_ID,
                            EXCESS_INVENTORY_ITEM_ID,
                            XREF_INVENTORY_ITEM_ID,
                            UNORDERED_RF_FG,
                            RF_NETTABLE_DGI_WITH_YIELD,
                            TOTAL_NETTABLE_PIPELINE,
                            SALES_PRIORITY,
                            RF_90DAY_FORECAST,
                            WS_90DAY_FORECAST,
                            EXCESS_LIFE_CYCLE,
                            REFRESH_LIFE_CYCLE,
                            MFG_EOS_DATE,
                            PID_PRIORITY,
                            FORECAST_QUARTER,
                            FORECAST_MONTH,
                            FORECAST_YEAR,
                            APPROVAL_STATUS,
                            CREATED_ON,
                            UPDATED_ON,
                            UPDATED_BY,
                            ADJUSTED_OVERRIDDEN_FORECAST,
                            RF_ADJ_OVERRIDDEN_FORECAST,
                            ADJ_OVERRIDDEN_PID_PRIORITY)
                     VALUES (
                               LV_UPLOAD_LIST (IDX).COMMON_PART_NUMBER,
                               LV_UPLOAD_LIST (IDX).REFRESH_PART_NUMBER,
                               LV_UPLOAD_LIST (IDX).EXCESS_PART_NUMBER,
                               (SELECT DISTINCT XREF_PART_NUMBER
                                  FROM CRPADM.RC_PRODUCT_MASTER
                                 WHERE     TRIM (COMMON_PART_NUMBER) =
                                              TRIM (
                                                 LV_UPLOAD_LIST (IDX).COMMON_PART_NUMBER)
                                       AND REFRESH_PART_NUMBER =
                                              DECODE (
                                                 LV_UPLOAD_LIST (IDX).REFRESH_PART_NUMBER,
                                                 '', LV_UPLOAD_LIST (IDX).EXCESS_PART_NUMBER,
                                                 LV_UPLOAD_LIST (IDX).REFRESH_PART_NUMBER)),
                               (SELECT DISTINCT COMMON_INVENTORY_ITEM_ID
                                  FROM CRPADM.RC_PRODUCT_MASTER
                                 WHERE REFRESH_PART_NUMBER =
                                          DECODE (
                                             LV_UPLOAD_LIST (IDX).REFRESH_PART_NUMBER,
                                             '', LV_UPLOAD_LIST (IDX).EXCESS_PART_NUMBER,
                                             LV_UPLOAD_LIST (IDX).REFRESH_PART_NUMBER)),
                               (SELECT DISTINCT REFRESH_INVENTORY_ITEM_ID
                                  FROM CRPADM.RC_PRODUCT_MASTER
                                 WHERE REFRESH_PART_NUMBER =
                                          LV_UPLOAD_LIST (IDX).REFRESH_PART_NUMBER),
                               (SELECT DISTINCT REFRESH_INVENTORY_ITEM_ID
                                  FROM CRPADM.RC_PRODUCT_MASTER
                                 WHERE REFRESH_PART_NUMBER =
                                          LV_UPLOAD_LIST (IDX).EXCESS_PART_NUMBER),
                               (SELECT DISTINCT XREF_INVENTORY_ITEM_ID
                                  FROM CRPADM.RC_PRODUCT_MASTER
                                 WHERE     TRIM (COMMON_PART_NUMBER) =
                                              TRIM (
                                                 LV_UPLOAD_LIST (IDX).COMMON_PART_NUMBER)
                                       AND REFRESH_PART_NUMBER =
                                              DECODE (
                                                 LV_UPLOAD_LIST (IDX).REFRESH_PART_NUMBER,
                                                 '', LV_UPLOAD_LIST (IDX).EXCESS_PART_NUMBER,
                                                 LV_UPLOAD_LIST (IDX).REFRESH_PART_NUMBER)),
                               LV_UPLOAD_LIST (IDX).UNORDERED_RF_FG,
                               LV_UPLOAD_LIST (IDX).RF_NETTABLE_DGI_WITH_YIELD,
                               LV_UPLOAD_LIST (IDX).TOTAL_PIPELINE_INV,
                               LV_UPLOAD_LIST (IDX).SALES_PRIORITY,
                               NVL (LV_UPLOAD_LIST (IDX).REFRESH_FORECAST, 0),
                               NVL (LV_UPLOAD_LIST (IDX).EXCESS_FORECAST, 0),
                               LV_UPLOAD_LIST (IDX).EXCESS_LIFE_CYCLE,
                               LV_UPLOAD_LIST (IDX).REFRESH_LIFE_CYCLE,
                               TO_DATE (LV_UPLOAD_LIST (IDX).MFG_EOS_DATE,
                                        'MM/DD/YYYY'),
                               DECODE (
                                  TRIM (LV_UPLOAD_LIST (IDX).PID_PRIORITY),
                                  'P1', 'P1',
                                  'P2', 'P2',
                                  'P3', 'P3',
                                  ''),
                               lv_forecast_quarter,
                               lv_forecast_month,
                               lv_forecast_year,
                               'DRAFT',
                               SYSDATE,
                               SYSDATE,
                               I_USER_ID,
                               (CASE
                                   WHEN LV_UPLOAD_LIST (IDX).ADJUSTED_OVERRIDDEN_FORECAST =
                                           'Y'
                                   THEN
                                      'Y'
                                   WHEN (   LV_UPLOAD_LIST (IDX).ADJUSTED_OVERRIDDEN_FORECAST =
                                               'N'
                                         OR LV_UPLOAD_LIST (IDX).ADJUSTED_OVERRIDDEN_FORECAST
                                               IS NULL)
                                   THEN
                                      'N'
                                   ELSE
                                      NULL
                                END),
                               (CASE
                                   WHEN LV_UPLOAD_LIST (IDX).ADJUSTED_OVERRIDDEN_FORECAST =
                                           'Y'
                                   THEN
                                      NVL (
                                         LV_UPLOAD_LIST (IDX).REFRESH_FORECAST,
                                         0)
                                   WHEN (   LV_UPLOAD_LIST (IDX).ADJUSTED_OVERRIDDEN_FORECAST =
                                               'N'
                                         OR LV_UPLOAD_LIST (IDX).ADJUSTED_OVERRIDDEN_FORECAST
                                               IS NULL)
                                   THEN
                                      NULL
                                   ELSE
                                      NULL
                                END),
                               (CASE
                                   WHEN LV_UPLOAD_LIST (IDX).ADJUSTED_OVERRIDDEN_FORECAST =
                                           'Y'
                                   THEN
                                      DECODE (
                                         TRIM (
                                            LV_UPLOAD_LIST (IDX).PID_PRIORITY),
                                         'P1', 'P1',
                                         'P2', 'P2',
                                         'P3', 'P3',
                                         '')
                                   WHEN (   LV_UPLOAD_LIST (IDX).ADJUSTED_OVERRIDDEN_FORECAST =
                                               'N'
                                         OR LV_UPLOAD_LIST (IDX).ADJUSTED_OVERRIDDEN_FORECAST
                                               IS NULL)
                                   THEN
                                      NULL
                                   ELSE
                                      NULL
                                END));
               END IF;

               UPDATE RC_SALES_FORECAST_CONFIG
                  SET UPLOADED_ON = SYSDATE,
                      UPLOADED_BY = I_USER_ID,
                      IS_TEMPLATE_ENABLED = 'Y',
                      TEMPLATE_ENABLED_ON = SYSDATE,
                      TEMPLATE_ENABLED_BY = I_USER_ID
                WHERE     FORECAST_QUARTER = lv_forecast_quarter
                      AND FORECAST_MONTH = lv_forecast_month
                      AND FORECAST_YEAR = lv_forecast_year;
            EXCEPTION
               WHEN E_INVALID_VALUES
               THEN
                  ROLLBACK;

                  G_ERROR_MSG :=
                        SUBSTR (SQLERRM, 1, 200)
                     || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
                  CRPADM.RC_GLOBAL_ERROR_LOGGING (
                     'E_INVALID_VALUES',
                     G_ERROR_MSG,
                     NULL,
                     'CRPADM.RC_SALES_FORECAST_DATA_EXTRACT.RC_SALES_FORECAST_GU_UPLOAD',
                     'PACKAGE',
                     NULL,
                     'Y');

                  INSERT INTO RC_INVALID_SALES_FORECAST_GU (
                                 COMMON_PART_NUMBER,
                                 REFRESH_PART_NUMBER,
                                 EXCESS_PART_NUMBER,
                                 UNORDERED_RF_FG,
                                 RF_NETTABLE_DGI_WITH_YIELD,
                                 TOTAL_PIPELINE_INV,
                                 SALES_PRIORITY,
                                 REFRESH_FORECAST,
                                 EXCESS_FORECAST,
                                 ERROR_MESSAGE,
                                 EXCESS_LIFE_CYCLE,
                                 REFRESH_LIFE_CYCLE,
                                 MFG_EOS_DATE,
                                 ADJUSTED_OVERRIDDEN_FORECAST)
                     (SELECT LV_UPLOAD_LIST (IDX).COMMON_PART_NUMBER,
                             LV_UPLOAD_LIST (IDX).REFRESH_PART_NUMBER,
                             LV_UPLOAD_LIST (IDX).EXCESS_PART_NUMBER,
                             NVL (
                                TO_NUMBER (
                                   LV_UPLOAD_LIST (IDX).UNORDERED_RF_FG),
                                0),
                             NVL (
                                TO_NUMBER (
                                   LV_UPLOAD_LIST (IDX).RF_NETTABLE_DGI_WITH_YIELD),
                                0),
                             NVL (
                                TO_NUMBER (
                                   LV_UPLOAD_LIST (IDX).TOTAL_PIPELINE_INV),
                                0),
                             LV_UPLOAD_LIST (IDX).SALES_PRIORITY,
                             NVL (
                                TO_NUMBER (
                                   LV_UPLOAD_LIST (IDX).REFRESH_FORECAST),
                                0),
                             NVL (
                                TO_NUMBER (
                                   LV_UPLOAD_LIST (IDX).EXCESS_FORECAST),
                                0),
                             LV_ERROR_MESSAGE,
                             LV_UPLOAD_LIST (IDX).EXCESS_LIFE_CYCLE,
                             LV_UPLOAD_LIST (IDX).REFRESH_LIFE_CYCLE,
                             NVL (
                                (TO_DATE (LV_UPLOAD_LIST (IDX).MFG_EOS_DATE,
                                          'MM/DD/YYYY')),
                                NULL),
                             LV_UPLOAD_LIST (IDX).ADJUSTED_OVERRIDDEN_FORECAST
                        FROM DUAL);

                  COMMIT;
            END;

            COMMIT;
         END LOOP;

         COMMIT;
      END IF;

      BEGIN
         SELECT RC_INVALID_SALES_FORECAST_OBJ (COMMON_PART_NUMBER,
                                               REFRESH_PART_NUMBER,
                                               EXCESS_PART_NUMBER,
                                               UNORDERED_RF_FG,
                                               RF_NETTABLE_DGI_WITH_YIELD,
                                               TOTAL_PIPELINE_INV,
                                               SALES_PRIORITY,
                                               REFRESH_FORECAST,
                                               EXCESS_FORECAST,
                                               ERROR_MESSAGE,
                                               EXCESS_LIFE_CYCLE,
                                               REFRESH_LIFE_CYCLE,
                                               MFG_EOS_DATE,
                                               PID_PRIORITY)
           BULK COLLECT INTO LV_INVALID_LIST
           FROM (SELECT COMMON_PART_NUMBER,
                        REFRESH_PART_NUMBER,
                        EXCESS_PART_NUMBER,
                        UNORDERED_RF_FG,
                        RF_NETTABLE_DGI_WITH_YIELD,
                        TOTAL_PIPELINE_INV,
                        SALES_PRIORITY,
                        REFRESH_FORECAST,
                        EXCESS_FORECAST,
                        ERROR_MESSAGE,
                        EXCESS_LIFE_CYCLE,
                        REFRESH_LIFE_CYCLE,
                        MFG_EOS_DATE,
                        PID_PRIORITY
                   FROM RC_INVALID_SALES_FORECAST_GU);
      EXCEPTION
         WHEN OTHERS
         THEN
            LV_INVALID_LIST := RC_INVALID_SALES_FORECAST_LIST ();
      END;

      SELECT COUNT (*)
        INTO lv_override_count
        FROM RC_SALES_FORECAST_STAGING
       WHERE     FORECAST_QUARTER = lv_forecast_quarter
             AND FORECAST_MONTH = lv_forecast_month
             AND FORECAST_YEAR = lv_forecast_year
             AND ADJUSTED_OVERRIDDEN_FORECAST = 'Y';

      IF lv_override_count > 0
      THEN
         UPDATE RC_SALES_FORECAST_CONFIG
            SET IS_ADJUSTED_OVERRIDDEN = 'Y'
          WHERE     FORECAST_QUARTER = lv_forecast_quarter
                AND FORECAST_MONTH = lv_forecast_month
                AND FORECAST_YEAR = lv_forecast_year;
      ELSE
         UPDATE RC_SALES_FORECAST_CONFIG
            SET IS_ADJUSTED_OVERRIDDEN = 'N'
          WHERE     FORECAST_QUARTER = lv_forecast_quarter
                AND FORECAST_MONTH = lv_forecast_month
                AND FORECAST_YEAR = lv_forecast_year;
      END IF;

      COMMIT;

      --CALL TO ENGINE PROC
      RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_ONUPLOAD (
         lv_forecast_quarter,
         lv_forecast_month,
         lv_forecast_year);


      -- CALL RC_SALES_FORECAST_EMAIL PROCEDURE TO SEND SUCCESS/ EXCEPTION EMAIL TO USER
      RC_SALES_FORECAST_EMAIL (I_USER_ID, I_UPLOAD_ID, LV_INVALID_LIST);

      INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (
                        CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                        'CRPADM.RC_SALES_FORECAST_DATA_EXTRACT.RC_SALES_FORECAST_GU_UPLOAD',
                        'END',
                        SYSDATE);

      UPDATE CRPSC.RC_AE_CONFIG_PROPERTIES
         SET CONFIG_VALUE = 'N'
       WHERE     CONFIG_CATEGORY = 'ALLOC_CONFIG_UI'
             AND CONFIG_NAME = 'REVIEW_FLAG';

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         LV_INVALID_LIST := RC_INVALID_SALES_FORECAST_LIST ();

         CRPADM.RC_GLOBAL_ERROR_LOGGING ('OTHERS',
                                         G_ERROR_MSG,
                                         NULL,
                                         'RC_SALES_FORECAST_GU_UPLOAD',
                                         'PROCEDURE',
                                         NULL,
                                         'N');


         RC_SALES_FORECAST_EMAIL (I_USER_ID, I_UPLOAD_ID, LV_INVALID_LIST);
   END RC_SALES_FORECAST_GU_UPLOAD;

   -- RC_SALES_FORECAST_EMAIL PROCEDURE TO SEND SUCCESS/ EXCEPTION EMAIL TO USER
   PROCEDURE RC_SALES_FORECAST_EMAIL (
      I_USER_ID        IN VARCHAR2,
      I_UPLOAD_ID      IN NUMBER,
      I_INVALID_LIST   IN RC_INVALID_SALES_FORECAST_LIST)
   IS
      LV_UPLOAD_ID       NUMBER;
      LV_INVALID_LIST    RC_INVALID_SALES_FORECAST_LIST;
      LV_FROM_ID         VARCHAR2 (500);
      LV_TO_ID           VARCHAR2 (500);
      LV_SUBJECT         VARCHAR2 (32767);
      LV_MESSAGE         VARCHAR2 (32767);
      LV_MAILHOST        VARCHAR2 (100) := 'OUTBOUND.CISCO.COM';
      LV_CONN            UTL_SMTP.CONNECTION;
      LV_MESSAGE_TYPE    VARCHAR2 (100) := 'TEXT/HTML; CHARSET="ISO-8859-1"';
      LV_CRLF            VARCHAR2 (5) := CHR (13) || CHR (10);
      LV_OUTPUT          LONG;
      LV_DATABASE_NAME   VARCHAR2 (50);
      LV_UPLOADED_DATE   VARCHAR2 (50);
      LV_TO_ID_LIST      CRPSC.RC_NORMALISED_LIST
                            := CRPSC.RC_NORMALISED_LIST ();
   BEGIN
      LV_UPLOAD_ID := I_UPLOAD_ID;
      LV_INVALID_LIST := I_INVALID_LIST;
      LV_FROM_ID := 'REFRESHCENTRAL-SUPPORT@CISCO.COM';
      LV_TO_ID := I_USER_ID || '@CISCO.COM';

      BEGIN
         SELECT USERID || '@CISCO.COM'
           BULK COLLECT INTO LV_TO_ID_LIST
           FROM (    SELECT REGEXP_SUBSTR (
                               (SELECT PROPERTY_VALUE
                                  FROM RC_PROPERTIES
                                 WHERE PROPERTY_NAME = 'HAS_SF_UPLOAD_ACCESS'),
                               '[^,]+',
                               1,
                               LEVEL)
                               USERID
                       FROM DUAL
                 CONNECT BY REGEXP_SUBSTR (
                               (SELECT PROPERTY_VALUE
                                  FROM RC_PROPERTIES
                                 WHERE PROPERTY_NAME = 'HAS_SF_UPLOAD_ACCESS'),
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
           FROM RC_GU_PRODUCT_REFRESH_SETUP
          WHERE     UPPER (MODULE) LIKE
                       '%' || UPPER ('Sales Forecasting') || '%'
                AND UPLOAD_ID = LV_UPLOAD_ID;
      EXCEPTION
         WHEN OTHERS
         THEN
            LV_UPLOADED_DATE := TO_CHAR (SYSDATE, 'MM/DD/YYYY HH:MI:SS PM');
      END;

      IF LV_INVALID_LIST.COUNT = 0
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
      IF LV_INVALID_LIST.COUNT () > 0
      THEN
         UTL_SMTP.WRITE_DATA (LV_CONN, '--SECBOUND' || LV_CRLF);
         UTL_SMTP.WRITE_DATA (
            LV_CONN,
               'CONTENT-TYPE: TEXT/PLAIN;'
            || LV_CRLF
            || ' NAME="SALESFORECASTERRORDETAILS.XLS"'
            || LV_CRLF
            || 'CONTENT-TRANSFER_ENCODING: 8BIT'
            || LV_CRLF
            || 'CONTENT-DISPOSITION: ATTACHMENT;'
            || LV_CRLF
            || ' FILENAME= "SALESFORECASTERRORDETAILS.XLS"'
            || LV_CRLF
            || LV_CRLF);

         LV_OUTPUT :=
               'MFG PID'
            || CHR (9)
            || 'RF PID'
            || CHR (9)
            || 'WS PID'
            || CHR (9)
            || 'UNORDERED FG'
            || CHR (9)
            || 'NETTABLE DGI'
            || CHR (9)
            || 'TOTAL PIPELINE'
            || CHR (9)
            || 'SALES PRIORITY'
            || CHR (9)
            || 'RF 90 DAY FORECAST'
            || CHR (9)
            || 'WS 90 DAY FORECAST'
            || CHR (9)
            || 'ERROR MESSAGE'
            || CHR (9)
            || 'EXCESS_LIFE_CYCLE'
            || CHR (9)
            || 'REFRESH_LIFE_CYCLE'
            || CHR (9)
            || 'MFG_EOS_DATE'
            || CHR (9)
            || 'PID_PRIORITY'
            || CHR (10);


         FOR IDX IN 1 .. LV_INVALID_LIST.COUNT
         LOOP
            --  IF LENGTH(LV_INVALID_LIST (IDX).REFRESH_PART_NUMBER) < 3
            --          THEN
            --  LV_UPLOAD_LIST (IDX).REFRESH_PART_NUMBER := 'NA';
            --        insert into rc_mstr_test (test,updatedAt,test2) values( LV_INVALID_LIST (IDX).REFRESH_PART_NUMBER, idx,LV_INVALID_LIST (IDX).ERROR_MESSAGE);
            --       commit;

            --                       insert into invalid_sales_forecast_temp(COMMON_PART_NUMBER,
            --                                                    REFRESH_PART_NUMBER,
            --                                                    EXCESS_PART_NUMBER,
            --                                                    UNORDERED_RF_FG ,
            --                                                    RF_NETTABLE_DGI_WITH_YIELD ,
            --                                                    TOTAL_PIPELINE_INV ,
            --                                                    SALES_PRIORITY ,
            --                                                    REFRESH_FORECAST ,
            --                                                    EXCESS_FORECAST ,
            --                                                    ERROR_MESSAGE,
            --                                                    LV_OUTPUT ) values(LV_INVALID_LIST (IDX).COMMON_PART_NUMBER,
            --                                                                LV_INVALID_LIST (IDX).REFRESH_PART_NUMBER,
            --                                                                LV_INVALID_LIST (IDX).EXCESS_PART_NUMBER,
            --                                                                LV_INVALID_LIST (IDX).UNORDERED_RF_FG,
            --                                                                LV_INVALID_LIST (IDX).RF_NETTABLE_DGI_WITH_YIELD,
            --                                                                LV_INVALID_LIST (IDX).TOTAL_PIPELINE_INV,
            --                                                                LV_INVALID_LIST (IDX).SALES_PRIORITY,
            --                                                                LV_INVALID_LIST (IDX).REFRESH_FORECAST,
            --                                                                LV_INVALID_LIST (IDX).EXCESS_FORECAST,
            --                                                                LV_INVALID_LIST (IDX).ERROR_MESSAGE,
            --                                                                LV_OUTPUT
            --                                                               || LV_INVALID_LIST (IDX).COMMON_PART_NUMBER
            --                                                               || CHR (9)
            --                                                               || LV_INVALID_LIST (IDX).REFRESH_PART_NUMBER
            --                                                               || CHR (9)
            --                                                               || LV_INVALID_LIST (IDX).EXCESS_PART_NUMBER
            --                                                               || CHR (9)
            --                                                               || LV_INVALID_LIST (IDX).UNORDERED_RF_FG
            --                                                               || CHR (9)
            --                                                               || LV_INVALID_LIST (IDX).RF_NETTABLE_DGI_WITH_YIELD
            --                                                               || CHR (9)
            --                                                               || LV_INVALID_LIST (IDX).TOTAL_PIPELINE_INV
            --                                                               || CHR (9)
            --                                                               || LV_INVALID_LIST (IDX).SALES_PRIORITY
            --                                                               || CHR (9)
            --                                                               || LV_INVALID_LIST (IDX).REFRESH_FORECAST
            --                                                               || CHR (9)
            --                                                               || LV_INVALID_LIST (IDX).EXCESS_FORECAST
            --                                                               || CHR (9)
            --                                                               || LV_INVALID_LIST (IDX).COMMON_PART_NUMBER
            --                                                               || CHR (10));
            --
            --                commit;
            --         END IF;

            --                  IF LENGTH(LV_INVALID_LIST (IDX).EXCESS_PART_NUMBER) < 3
            --                  THEN
            --                  --   LV_UPLOAD_LIST (IDX).EXCESS_PART_NUMBER := 'NA';
            --                                     insert into rc_mstr_test (test,updatedAt) values( LV_INVALID_LIST (IDX).EXCESS_PART_NUMBER,idx);
            --                                     commit;
            --                  END IF;
            LV_OUTPUT :=
                  LV_OUTPUT
               || LV_INVALID_LIST (IDX).COMMON_PART_NUMBER
               || CHR (9)
               || LV_INVALID_LIST (IDX).REFRESH_PART_NUMBER
               || CHR (9)
               || LV_INVALID_LIST (IDX).EXCESS_PART_NUMBER
               || CHR (9)
               || LV_INVALID_LIST (IDX).UNORDERED_RF_FG
               || CHR (9)
               || LV_INVALID_LIST (IDX).RF_NETTABLE_DGI_WITH_YIELD
               || CHR (9)
               || LV_INVALID_LIST (IDX).TOTAL_PIPELINE_INV
               || CHR (9)
               || LV_INVALID_LIST (IDX).SALES_PRIORITY
               || CHR (9)
               || LV_INVALID_LIST (IDX).REFRESH_FORECAST
               || CHR (9)
               || LV_INVALID_LIST (IDX).EXCESS_FORECAST
               || CHR (9)
               || LV_INVALID_LIST (IDX).ERROR_MESSAGE
               || CHR (9)
               || LV_INVALID_LIST (IDX).EXCESS_LIFE_CYCLE
               || CHR (9)
               || LV_INVALID_LIST (IDX).REFRESH_LIFE_CYCLE
               || CHR (9)
               || LV_INVALID_LIST (IDX).MFG_EOS_DATE
               || CHR (9)
               || LV_INVALID_LIST (IDX).PID_PRIORITY
               || CHR (10);
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
            'CRPADM.RC_SALES_FORECAST_DATA_EXTRACT.RC_SALES_FORECAST_EMAIL',
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
            'CRPADM.RC_SALES_FORECAST_DATA_EXTRACT.RC_SALES_FORECAST_EMAIL',
            'PACKAGE',
            NULL,
            'Y');
   END RC_SALES_FORECAST_EMAIL;

   PROCEDURE RC_SALES_FORECAST_PAGE_LOAD (
      I_USER_ID                 IN     VARCHAR2,
      I_MIN                     IN     NUMBER,
      I_MAX                     IN     NUMBER,
      I_PRODUCTNAME             IN     CLOB,
      I_RF_FORECAST             IN     NUMBER,
      I_WS_FORECAST             IN     NUMBER,
      I_APPROVAL_STATUS         IN     VARCHAR2,
      I_SALES_PRIORITY          IN     VARCHAR2,
      I_QUARTER_MONTH           IN     VARCHAR2,
      I_YEAR                    IN     VARCHAR2,
      I_SNAPSHOT                IN     VARCHAR2,
      I_PID_PRIORITY            IN     VARCHAR2,
      O_SALES_FORECAST_LIST        OUT CRPADM.RC_SALES_FORECAST_LIST,
      O_RECORD_COUNT               OUT NUMBER,
      O_SUBMIT_BTN_FLAG            OUT VARCHAR2,
      O_APPROVE_BTN_FLAG           OUT VARCHAR2,
      O_UPLOAD_BTN_FLAG            OUT VARCHAR2,
      O_IS_FORECAST_SUBMITTED      OUT VARCHAR2,
      O_IS_PUBLISHED               OUT VARCHAR2,
      O_PUBLISHED_FLAG             OUT VARCHAR2)
   IS
      LV_SALES_FORECAST_LIST          RC_SALES_FORECAST_LIST;
      LV_QUERY                        CLOB;
      LV_MAIN_QUERY                   CLOB;
      LV_ROW_CLAUSE                   CLOB;
      LV_ROW_FILTER_CLAUSE            CLOB;
      LV_ROW_COUNT                    CLOB;
      LV_RF_FORECAST                  NUMBER;
      LV_WS_FORECAST                  NUMBER;
      LV_MAX_ROW                      NUMBER;
      LV_MIN_ROW                      NUMBER;
      LV_IDX                          NUMBER;
      LV_CUR_PART_NUMBER              CLOB;
      LV_I_PART_NUMBER                CLOB;
      LV_PRODUCTNAME                  CLOB;
      LV_USER_ID                      VARCHAR2 (100 BYTE);
      LV_APPROVAL_STATUS              VARCHAR2 (100 BYTE);
      LV_SALES_PRIORITY               VARCHAR2 (100 BYTE);
      LV_PID_PRIORITY                 VARCHAR2 (100 BYTE);
      LV_RECORD_COUNT                 NUMBER;
      LV_IS_FORECAST_SUBMITTED        VARCHAR2 (100 BYTE);
      LV_IS_FORECAST_APPROVED         VARCHAR2 (100 BYTE);
      LV_IS_FORECAST_UPLOAD_ENABLED   VARCHAR2 (100 BYTE);
      LV_IS_FORECAST_PUBLISHED        VARCHAR2 (100 BYTE);
      LV_SUBMIT_BTN_FLAG              VARCHAR2 (100 BYTE);
      LV_APPROVE_BTN_FLAG             VARCHAR2 (100 BYTE);
      LV_UPLOAD_BTN_FLAG              VARCHAR2 (100 BYTE);
      LV_PUBLISHED_BTN_FLAG           VARCHAR2 (100 BYTE);
      LV_USER_COUNT                   NUMBER := 0;
      LV_SUBMIT_COUNT                 NUMBER := 0;
      LV_APPROVE_COUNT                NUMBER := 0;
      LV_TABLE_NAME                   VARCHAR2 (100 BYTE);
      LV_QUARTER_MONTH_YEAR           VARCHAR2 (100 BYTE);
      I_QUARTER_MONTH_YEAR            VARCHAR2 (100 BYTE);
      LV_QUARTER                      VARCHAR2 (20 BYTE);
      LV_MONTH                        VARCHAR2 (20 BYTE);
      LV_YEAR                         VARCHAR2 (10 BYTE);
      LV_SNAPSHOT                     VARCHAR2 (10 BYTE);
      LV_PUBLISHED_FLAG               VARCHAR2 (10 BYTE);
      LV_REVIEW                       VARCHAR2 (10 BYTE);
   --      lv_is_overridden                VARCHAR2 (100);
   BEGIN
      LV_SALES_FORECAST_LIST := RC_SALES_FORECAST_LIST ();
      LV_MAX_ROW := I_MAX;
      LV_MIN_ROW := I_MIN;
      LV_USER_ID := I_USER_ID;
      LV_PRODUCTNAME := I_PRODUCTNAME;
      LV_APPROVAL_STATUS := I_APPROVAL_STATUS;
      LV_RF_FORECAST := I_RF_FORECAST;
      LV_WS_FORECAST := I_WS_FORECAST;
      LV_SALES_PRIORITY := I_SALES_PRIORITY;
      LV_PID_PRIORITY := I_PID_PRIORITY;
      LV_SNAPSHOT := I_SNAPSHOT;

      IF I_QUARTER_MONTH = 'ALL' AND I_YEAR = 'ALL'
      THEN
         SELECT DISTINCT FORECAST_QUARTER, FORECAST_MONTH, FORECAST_YEAR
           INTO LV_QUARTER, LV_MONTH, LV_YEAR
           FROM RC_SALES_FORECAST
          WHERE     FORECAST_QUARTER IS NOT NULL
                AND FORECAST_MONTH IS NOT NULL
                AND FORECAST_YEAR IS NOT NULL;
      ELSE
         LV_YEAR := I_YEAR;

         LV_QUARTER := SUBSTR (I_QUARTER_MONTH, 1, 2) || ' FY' || LV_YEAR;
         LV_MONTH := SUBSTR (I_QUARTER_MONTH, -2, 2);
      END IF;



      COMMIT;

      --        SELECT    SUBSTR (FISCAL_QUARTER_NAME, 1, 2)
      --               || 'M'
      --               || RNUM
      --               || FISCAL_YEAR_NUMBER
      --          INTO LV_QUARTER_MONTH_YEAR
      --          FROM (SELECT *
      --                  FROM (SELECT FISCAL_QUARTER_NAME,
      --                               FISCAL_MONTH_ID,
      --                               FISCAL_YEAR_NUMBER,
      --                               ROWNUM RNUM
      --                          FROM (  SELECT DISTINCT
      --                                         FISCAL_QUARTER_NAME,
      --                                         FISCAL_MONTH_ID,
      --                                         FISCAL_YEAR_NUMBER
      --                                    FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
      --                                   WHERE CURRENT_FISCAL_QUARTER_FLAG = 'Y'
      --                                ORDER BY 2))
      --                 WHERE FISCAL_MONTH_ID =
      --                       (SELECT FISCAL_MONTH_ID
      --                          FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
      --                         WHERE CALENDAR_DATE = TRUNC (SYSDATE)));

      SELECT DISTINCT FORECAST_QUARTER || FORECAST_MONTH || FORECAST_YEAR
        INTO LV_QUARTER_MONTH_YEAR
        FROM RC_SALES_FORECAST;

      --        INSERT INTO RC_TEST_BLOCK
      --                 VALUES ('LV_QUARTER_MONTH_YEAR ' || LV_QUARTER_MONTH_YEAR,
      --                         SYSDATE);
      --
      --        COMMIT;

      SELECT LV_QUARTER || LV_MONTH || LV_YEAR
        INTO I_QUARTER_MONTH_YEAR
        FROM DUAL;

      --        INSERT INTO RC_TEST_BLOCK
      --                 VALUES ('I_QUARTER_MONTH_YEAR ' || I_QUARTER_MONTH_YEAR,
      --                         SYSDATE);
      --
      --        COMMIT;

      /*INSERT INTO temp_query
              VALUES (
                           'LV_QUARTER '
                        || LV_QUARTER
                        || ' LV_MONTH '
                        || LV_MONTH
                        || ' LV_YEAR '
                        || LV_YEAR,
                        SYSDATE);*/


      LV_MAIN_QUERY :=
         ' SELECT * FROM( SELECT AB.*,
           ROWNUM RNUM FROM (SELECT RETAIL_PART_NUMBER,
               EXCESS_PART_NUMBER,
               XREF_PART_NUMBER,
               COMMON_PART_NUMBER,
               PID_LIFE_CYCLE,
               UNORDERED_RF_FG,
               RF_NETTABLE_DGI_WITH_YIELD,
               TOTAL_NETTABLE_PIPELINE,
               SALES_PRIORITY,
               RF_90DAY_FORECAST,
               WS_90DAY_FORECAST,
               TOTAL_RF_ALLOCATION,
               WS_ALLOCATION,
               OUTLET_ALLOCATION,
               PIPELINE_NOT_ALLOCATED,
               ASP_RF,
               ASP_WS,
               EXPECTED_REVENUE_RF,
               EXPECTED_REVENUE_WS,
               FORECASTED_REVENUE,
               RF_SALES_3M,
               WS_SALES_3M,
               OUTLET_SALES_3M,
               SUGGESTED_RF_MAX,
               TOTAL_NEW_MAX,
               NAM_RF_NEW_MAX,
               EMEA_RF_NEW_MAX,
               UNITS_REQB_CONSTRAINED,
               UNITS_REQB_UNCONSTRAINED,
               UNITS_REQ_BUILD,
               RF_EXPECTED_REPAIR_COST,
               WS_EXPECTED_REPAIR_COST,
               TOTAL_EXPECTED_REPAIR_COST,
               RF_FORECASTED_REPAIR_COST,
               WS_FORECASTED_REPAIR_COST,
               TOTAL_FORECASTED_REPAIR_COST,
               SYSTEM_DEMAND,
               REFRESH_YIELD,
               SALES_FORECAST_12M,
               NEW_DEMAND,
               CREATED_ON,
               UPDATED_BY,
               UPDATED_ON,
               APPROVAL_STATUS,
               ASP_OUTLET,
               EXPECTED_REVENUE_OUTLET,
               NVL( NVL( ADJ_OVERRIDDEN_PID_PRIORITY, ADJUSTED_PID_PRIORITY), PID_PRIORITY) AS PID_PRIORITY,
               SALES_RF_ALLOCATION,
               SALES_WS_ALLOCATION,
               RF_ALLOCATED_FROM_DAY0,
               WS_ALLOCATED_FROM_DAY0,
               EXPECTED_SALES_REVENUE_RF,
               EXPECTED_SALES_REVENUE_OUTLET,
               EXPECTED_SALES_REVENUE_WS,
               TOTL_EXPCTD_SALES_REPAIR_COST,
               REFRESH_LIFE_CYCLE,
               EXCESS_LIFE_CYCLE,
               MFG_EOS_DATE,
               UNORDERED_WS_FG ,
               RF_NETTABLE_DGI_WITHOUT_YIELD ,
               WS_NETTABLE_DGI_WITHOUT_YIELD ,
               WS_NETTABLE_DGI_WITH_YIELD ,
               POE_NETTABLE_DGI_WITHOUT_YIELD ,
               TOTAL_NON_NETTABLE_PIPELINE ,
               RF_FG_ALLOCATION ,
               RF_DGI_ALLOCATION ,
               NVL ( NVL ( RF_ADJ_OVERRIDDEN_FORECAST, RF_ADJUSTED_FORECAST ), RF_90DAY_FORECAST ) AS RF_ADJUSTED_FORECAST,
               WS_ADJUSTED_FORECAST  ';

      IF (LV_SNAPSHOT IS NULL) OR (LV_SNAPSHOT = '')
      THEN
         IF LV_QUARTER_MONTH_YEAR = I_QUARTER_MONTH_YEAR
         THEN
            --            IF LV_IS_OVERRIDDEN != 'I'
            --            THEN
            LV_TABLE_NAME := ' FROM RC_SALES_FORECAST ';
         --            ELSE
         --               LV_TABLE_NAME := ' FROM RC_SALES_FORECAST_STAGING ';
         --            END IF;
         ELSE
            LV_TABLE_NAME := ' FROM RC_SALES_FORECAST_STAGING ';
         END IF;
      ELSE
         LV_TABLE_NAME := ' FROM RC_ALL_SALES_FORECAST ';
      END IF;

      LV_ROW_CLAUSE :=
            ' ) AB ) WHERE RNUM <= '
         || LV_MAX_ROW
         || ' AND RNUM > '
         || LV_MIN_ROW;

      LV_ROW_COUNT := 'SELECT COUNT(*) ';


      LV_ROW_FILTER_CLAUSE := '';

      IF (   (LV_PRODUCTNAME IS NOT NULL)
          OR (LV_APPROVAL_STATUS IS NOT NULL)
          OR (LV_RF_FORECAST IS NOT NULL)
          OR (LV_WS_FORECAST IS NOT NULL)
          OR (LV_SALES_PRIORITY IS NOT NULL)
          OR (LV_YEAR IS NOT NULL)
          OR (LV_QUARTER IS NOT NULL)
          OR (LV_MONTH IS NOT NULL)
          OR (LV_SNAPSHOT IS NOT NULL)
          OR (LV_PID_PRIORITY IS NOT NULL))
      THEN
         LV_ROW_FILTER_CLAUSE := ' WHERE 1=1 ';

         IF (LV_PRODUCTNAME IS NOT NULL)
         THEN
            LV_ROW_FILTER_CLAUSE := LV_ROW_FILTER_CLAUSE || ' AND (';
            LV_I_PART_NUMBER := LV_PRODUCTNAME;
            LV_IDX := INSTR (LV_I_PART_NUMBER, ',');

            IF LV_IDX = 0
            THEN
               LV_I_PART_NUMBER := REPLACE (LV_I_PART_NUMBER, '*', '');
               LV_ROW_FILTER_CLAUSE :=
                     LV_ROW_FILTER_CLAUSE
                  || '(UPPER(RETAIL_PART_NUMBER) = UPPER('''
                  || LV_I_PART_NUMBER
                  || ''') OR UPPER(EXCESS_PART_NUMBER) = UPPER('''
                  || LV_I_PART_NUMBER
                  || ''') OR UPPER(XREF_PART_NUMBER) = UPPER( '''
                  || LV_I_PART_NUMBER
                  || ''') OR UPPER(COMMON_PART_NUMBER) = UPPER('''
                  || LV_I_PART_NUMBER
                  || '''))';
               LV_ROW_FILTER_CLAUSE := LV_ROW_FILTER_CLAUSE || ' )';
            ELSE
               LV_CUR_PART_NUMBER :=
                  SUBSTR (LV_I_PART_NUMBER,
                          1,
                          INSTR (LV_I_PART_NUMBER, ',') - 1);
               LV_CUR_PART_NUMBER := REPLACE (LV_CUR_PART_NUMBER, '*', '');

               LV_ROW_FILTER_CLAUSE :=
                     LV_ROW_FILTER_CLAUSE
                  || '(UPPER(RETAIL_PART_NUMBER) = UPPER('''
                  || LV_CUR_PART_NUMBER
                  || ''') OR UPPER(EXCESS_PART_NUMBER) = UPPER('''
                  || LV_CUR_PART_NUMBER
                  || ''') OR UPPER(XREF_PART_NUMBER) = UPPER('''
                  || LV_CUR_PART_NUMBER
                  || ''') OR UPPER(COMMON_PART_NUMBER) = UPPER('''
                  || LV_CUR_PART_NUMBER
                  || '''))';
               LV_I_PART_NUMBER :=
                  SUBSTR (LV_I_PART_NUMBER, LV_IDX + LENGTH (','));

               LOOP
                  LV_IDX := INSTR (LV_I_PART_NUMBER, ',');

                  IF LV_IDX > 0
                  THEN
                     LV_CUR_PART_NUMBER :=
                        SUBSTR (LV_I_PART_NUMBER,
                                1,
                                INSTR (LV_I_PART_NUMBER, ',') - 1);

                     LV_I_PART_NUMBER :=
                        SUBSTR (LV_I_PART_NUMBER, LV_IDX + LENGTH (','));
                     LV_CUR_PART_NUMBER :=
                        REPLACE (LV_CUR_PART_NUMBER, '*', '');
                     LV_ROW_FILTER_CLAUSE :=
                           LV_ROW_FILTER_CLAUSE
                        || ' OR (UPPER(RETAIL_PART_NUMBER) = UPPER('''
                        || LV_CUR_PART_NUMBER
                        || ''') OR UPPER(EXCESS_PART_NUMBER) = UPPER('''
                        || LV_CUR_PART_NUMBER
                        || ''') OR UPPER(XREF_PART_NUMBER) = UPPER('''
                        || LV_CUR_PART_NUMBER
                        || ''') OR UPPER(COMMON_PART_NUMBER) = UPPER('''
                        || LV_CUR_PART_NUMBER
                        || '''))';
                  ELSE
                     LV_I_PART_NUMBER := REPLACE (LV_I_PART_NUMBER, '*', '');
                     LV_ROW_FILTER_CLAUSE :=
                           LV_ROW_FILTER_CLAUSE
                        || ' OR (UPPER(RETAIL_PART_NUMBER) = UPPER('''
                        || LV_I_PART_NUMBER
                        || ''') OR UPPER(EXCESS_PART_NUMBER) = UPPER('''
                        || LV_I_PART_NUMBER
                        || ''') OR UPPER(XREF_PART_NUMBER) = UPPER('''
                        || LV_I_PART_NUMBER
                        || ''') OR UPPER(COMMON_PART_NUMBER) = UPPER('''
                        || LV_I_PART_NUMBER
                        || '''))';
                     EXIT WHEN LV_IDX = 0;
                  END IF;
               END LOOP;

               LV_ROW_FILTER_CLAUSE := LV_ROW_FILTER_CLAUSE || ')';
            END IF;
         END IF;

         IF (LV_SALES_PRIORITY IS NOT NULL)
         THEN
            IF (LV_SALES_PRIORITY = 'P1')
            THEN
               LV_ROW_FILTER_CLAUSE :=
                  LV_ROW_FILTER_CLAUSE || 'AND (SALES_PRIORITY LIKE ''P1'')';
            ELSIF (LV_SALES_PRIORITY = 'P2')
            THEN
               LV_ROW_FILTER_CLAUSE :=
                  LV_ROW_FILTER_CLAUSE || 'AND (SALES_PRIORITY LIKE ''P2'')';
            ELSIF (LV_SALES_PRIORITY = 'P3')
            THEN
               LV_ROW_FILTER_CLAUSE :=
                  LV_ROW_FILTER_CLAUSE || 'AND (SALES_PRIORITY LIKE ''P3'')';
            ELSIF (LV_SALES_PRIORITY = 'NA')
            THEN
               LV_ROW_FILTER_CLAUSE :=
                  LV_ROW_FILTER_CLAUSE || 'AND (SALES_PRIORITY IS NULL)';
            END IF;
         END IF;

         IF (LV_RF_FORECAST IS NOT NULL AND LV_RF_FORECAST <> 0)
         THEN
            LV_ROW_FILTER_CLAUSE :=
                  LV_ROW_FILTER_CLAUSE
               || ' AND RF_90DAY_FORECAST > '
               || LV_RF_FORECAST;
         END IF;

         IF (LV_WS_FORECAST IS NOT NULL AND LV_WS_FORECAST <> 0)
         THEN
            LV_ROW_FILTER_CLAUSE :=
                  LV_ROW_FILTER_CLAUSE
               || ' AND WS_90DAY_FORECAST > '
               || LV_WS_FORECAST;
         END IF;

         IF (LV_APPROVAL_STATUS IS NOT NULL)
         THEN
            IF (LV_APPROVAL_STATUS = 'DRAFT')
            THEN
               LV_ROW_FILTER_CLAUSE :=
                     LV_ROW_FILTER_CLAUSE
                  || 'AND (APPROVAL_STATUS LIKE ''%DRAFT'')';
            ELSIF (LV_APPROVAL_STATUS = 'SUBMITTED')
            THEN
               LV_ROW_FILTER_CLAUSE :=
                     LV_ROW_FILTER_CLAUSE
                  || 'AND (APPROVAL_STATUS LIKE ''%SUBMITTED'')';
            ELSIF (LV_APPROVAL_STATUS = 'APPROVED')
            THEN
               LV_ROW_FILTER_CLAUSE :=
                     LV_ROW_FILTER_CLAUSE
                  || 'AND (APPROVAL_STATUS LIKE ''%APPROVED'')';
            ELSIF (LV_APPROVAL_STATUS = 'NA')
            THEN
               LV_ROW_FILTER_CLAUSE :=
                  LV_ROW_FILTER_CLAUSE || 'AND (APPROVAL_STATUS IS NULL)';
            END IF;
         END IF;


         IF     LV_QUARTER IS NOT NULL
            AND LV_MONTH IS NOT NULL
            AND LV_YEAR IS NOT NULL
         THEN
            --            IF LV_QUARTER_MONTH_YEAR != I_QUARTER_MONTH_YEAR
            --            THEN
            LV_ROW_FILTER_CLAUSE :=
                  LV_ROW_FILTER_CLAUSE
               || ' AND FORECAST_YEAR = '''
               || LV_YEAR
               || '''';
            LV_ROW_FILTER_CLAUSE :=
                  LV_ROW_FILTER_CLAUSE
               || ' AND FORECAST_QUARTER = '''
               || LV_QUARTER
               || '''';
            LV_ROW_FILTER_CLAUSE :=
                  LV_ROW_FILTER_CLAUSE
               || ' AND FORECAST_MONTH = '''
               || LV_MONTH
               || '''';
         --            END IF;
         END IF;



         IF LV_SNAPSHOT IS NOT NULL
         THEN
            LV_ROW_FILTER_CLAUSE :=
                  LV_ROW_FILTER_CLAUSE
               || 'AND SNAPSHOT_TYPE = '''
               || LV_SNAPSHOT
               || '''';
         END IF;

         IF (LV_PID_PRIORITY IS NOT NULL AND LV_PID_PRIORITY <> 'ALL')
         THEN
            LV_ROW_FILTER_CLAUSE :=
                  LV_ROW_FILTER_CLAUSE
               || ' AND ( PID_PRIORITY = '''
               || LV_PID_PRIORITY
               || ''''
               || ' OR ADJUSTED_PID_PRIORITY = '''
               || LV_PID_PRIORITY
               || ''''
               || ' OR ADJ_OVERRIDDEN_PID_PRIORITY = '''
               || LV_PID_PRIORITY
               || ''')';
         END IF;
      END IF;

      LV_MAIN_QUERY :=
            LV_MAIN_QUERY
         || LV_TABLE_NAME
         || LV_ROW_FILTER_CLAUSE
         || ' ORDER BY PID_PRIORITY '
         || LV_ROW_CLAUSE;

      LV_ROW_COUNT :=
         LV_ROW_COUNT || LV_TABLE_NAME || LV_ROW_FILTER_CLAUSE;

      LV_QUERY :=
         'SELECT RC_SALES_FORECAST_OBJ ( RETAIL_PART_NUMBER,
               EXCESS_PART_NUMBER,
               XREF_PART_NUMBER,
               COMMON_PART_NUMBER,
               PID_LIFE_CYCLE,
               UNORDERED_RF_FG,
               RF_NETTABLE_DGI_WITH_YIELD,
               TOTAL_NETTABLE_PIPELINE,
               SALES_PRIORITY,
               RF_90DAY_FORECAST,
               WS_90DAY_FORECAST,
               TOTAL_RF_ALLOCATION,
               WS_ALLOCATION,
               OUTLET_ALLOCATION,
               PIPELINE_NOT_ALLOCATED,
               ASP_RF,
               ASP_WS,
               EXPECTED_REVENUE_RF,
               EXPECTED_REVENUE_WS,
               FORECASTED_REVENUE,
               RF_SALES_3M,
               WS_SALES_3M,
               OUTLET_SALES_3M,
               SUGGESTED_RF_MAX,
               TOTAL_NEW_MAX,
               NAM_RF_NEW_MAX,
               EMEA_RF_NEW_MAX,
               UNITS_REQB_CONSTRAINED,
               UNITS_REQB_UNCONSTRAINED,
               UNITS_REQ_BUILD,
               RF_EXPECTED_REPAIR_COST,
               WS_EXPECTED_REPAIR_COST,
               TOTAL_EXPECTED_REPAIR_COST,
               RF_FORECASTED_REPAIR_COST,
               WS_FORECASTED_REPAIR_COST,
               TOTAL_FORECASTED_REPAIR_COST,
               SYSTEM_DEMAND,
               REFRESH_YIELD,
               SALES_FORECAST_12M,
               NEW_DEMAND,
               CREATED_ON,
               UPDATED_BY,
               UPDATED_ON,
               APPROVAL_STATUS,
               ASP_OUTLET,
               EXPECTED_REVENUE_OUTLET,
               PID_PRIORITY,
               SALES_RF_ALLOCATION,
               SALES_WS_ALLOCATION,
               RF_ALLOCATED_FROM_DAY0,
               WS_ALLOCATED_FROM_DAY0,
               EXPECTED_SALES_REVENUE_RF,
               EXPECTED_SALES_REVENUE_OUTLET,
               EXPECTED_SALES_REVENUE_WS,
               TOTL_EXPCTD_SALES_REPAIR_COST,
               REFRESH_LIFE_CYCLE,
               EXCESS_LIFE_CYCLE,
               MFG_EOS_DATE,
               UNORDERED_WS_FG ,
               RF_NETTABLE_DGI_WITHOUT_YIELD ,
               WS_NETTABLE_DGI_WITHOUT_YIELD ,
               WS_NETTABLE_DGI_WITH_YIELD ,
               POE_NETTABLE_DGI_WITHOUT_YIELD ,
               TOTAL_NON_NETTABLE_PIPELINE ,
               RF_FG_ALLOCATION ,
               RF_DGI_ALLOCATION ,
               RF_ADJUSTED_FORECAST ,
               WS_ADJUSTED_FORECAST 
               )
               FROM ( ' || LV_MAIN_QUERY || ' ) ';


      COMMIT;


      /*INSERT INTO temp_query
           VALUES (LV_QUERY, SYSDATE);*/

      --
      --        COMMIT;
      --
      --        INSERT INTO RC_TEST_BLOCK
      --             VALUES (LV_ROW_COUNT, SYSDATE);
      --
      --        COMMIT;

      EXECUTE IMMEDIATE LV_QUERY BULK COLLECT INTO LV_SALES_FORECAST_LIST;

      EXECUTE IMMEDIATE LV_ROW_COUNT INTO LV_RECORD_COUNT;

      --        SELECT PROPERTY_VALUE
      --          INTO LV_IS_FORECAST_SUBMITTED
      --          FROM RC_PROPERTIES
      --         WHERE PROPERTY_TYPE = 'IS_FORECAST_SUBMITTED';

      SELECT DISTINCT IS_SUBMITTED
        INTO LV_IS_FORECAST_SUBMITTED
        FROM RC_SALES_FORECAST_CONFIG
       WHERE     FORECAST_QUARTER = LV_QUARTER
             AND FORECAST_MONTH = LV_MONTH
             AND FORECAST_YEAR = LV_YEAR;

      SELECT DISTINCT IS_PUBLISHED
        INTO LV_PUBLISHED_FLAG
        FROM RC_SALES_FORECAST_CONFIG
       WHERE     FORECAST_QUARTER = LV_QUARTER
             AND FORECAST_MONTH = LV_MONTH
             AND FORECAST_YEAR = LV_YEAR;

      SELECT COUNT (COMMON_PART_NUMBER)
        INTO LV_SUBMIT_COUNT
        FROM RC_SALES_FORECAST_STAGING
       WHERE     APPROVAL_STATUS = 'DRAFT'
             AND FORECAST_QUARTER = LV_QUARTER
             AND FORECAST_MONTH = LV_MONTH
             AND FORECAST_YEAR = LV_YEAR;

      SELECT TO_CHAR (CONFIG_VALUE)
        INTO LV_REVIEW
        FROM CRPSC.RC_AE_CONFIG_PROPERTIES
       WHERE     CONFIG_NAME = 'REVIEW_FLAG'
             AND CONFIG_CATEGORY = 'ALLOC_CONFIG_UI';

      SELECT COUNT (*)
        INTO LV_USER_COUNT
        FROM DUAL
       WHERE LV_USER_ID IN
                (    SELECT REGEXP_SUBSTR (
                               (SELECT PROPERTY_VALUE
                                  FROM RC_PROPERTIES
                                 WHERE PROPERTY_NAME = 'HAS_FC_SUBMIT_ACCESS'),
                               '[^,]+',
                               1,
                               LEVEL)
                       FROM DUAL
                 CONNECT BY REGEXP_SUBSTR (
                               (SELECT PROPERTY_VALUE
                                  FROM RC_PROPERTIES
                                 WHERE PROPERTY_NAME = 'HAS_FC_SUBMIT_ACCESS'),
                               '[^,]+',
                               1,
                               LEVEL)
                               IS NOT NULL);

      IF (    LV_USER_COUNT > 0
          AND LV_IS_FORECAST_SUBMITTED = 'N'
          AND LV_SUBMIT_COUNT > 0)
      THEN
         LV_SUBMIT_BTN_FLAG := 'Y';
      ELSIF (    LV_USER_COUNT > 0
             AND LV_IS_FORECAST_SUBMITTED = 'Y'
             AND LV_SUBMIT_COUNT = 0)
      THEN
         LV_SUBMIT_BTN_FLAG := 'D';
      ELSE
         LV_SUBMIT_BTN_FLAG := 'N';
      END IF;

      --        INSERT INTO RC_TEST_BLOCK
      --             VALUES ('LV_SUBMIT_BTN_FLAG ' || LV_SUBMIT_BTN_FLAG, SYSDATE);
      --
      --        COMMIT;

      LV_USER_COUNT := 0;

      SELECT COUNT (*)
        INTO LV_USER_COUNT
        FROM DUAL
       WHERE LV_USER_ID IN
                (    SELECT REGEXP_SUBSTR (
                               (SELECT PROPERTY_VALUE
                                  FROM RC_PROPERTIES
                                 WHERE PROPERTY_NAME = 'HAS_FC_APPROVE_ACCESS'),
                               '[^,]+',
                               1,
                               LEVEL)
                       FROM DUAL
                 CONNECT BY REGEXP_SUBSTR (
                               (SELECT PROPERTY_VALUE
                                  FROM RC_PROPERTIES
                                 WHERE PROPERTY_NAME =
                                          'HAS_FC_APPROVE_ACCESS'),
                               '[^,]+',
                               1,
                               LEVEL)
                               IS NOT NULL);

      SELECT COUNT (COMMON_PART_NUMBER)
        INTO LV_SUBMIT_COUNT
        FROM RC_SALES_FORECAST_STAGING
       WHERE     APPROVAL_STATUS = 'SUBMITTED'
             AND FORECAST_QUARTER = LV_QUARTER
             AND FORECAST_MONTH = LV_MONTH
             AND FORECAST_YEAR = LV_YEAR;

      SELECT DISTINCT IS_APPROVED
        INTO LV_IS_FORECAST_APPROVED
        FROM RC_SALES_FORECAST_CONFIG
       WHERE     FORECAST_QUARTER = LV_QUARTER
             AND FORECAST_MONTH = LV_MONTH
             AND FORECAST_YEAR = LV_YEAR;

      IF (    LV_USER_COUNT > 0
          AND LV_SUBMIT_COUNT > 0
          AND LV_IS_FORECAST_APPROVED = 'N')
      THEN
         LV_APPROVE_BTN_FLAG := 'Y';
      ELSIF (    LV_USER_COUNT > 0
             AND LV_SUBMIT_COUNT = 0
             AND LV_IS_FORECAST_APPROVED = 'Y')
      THEN
         LV_APPROVE_BTN_FLAG := 'D';
      ELSE
         LV_APPROVE_BTN_FLAG := 'N';
      END IF;

      --        INSERT INTO RC_TEST_BLOCK
      --             VALUES ('LV_APPROVE_BTN_FLAG ' || LV_APPROVE_BTN_FLAG, SYSDATE);
      --
      --        COMMIT;

      LV_USER_COUNT := 0;

      SELECT COUNT (*)
        INTO LV_USER_COUNT
        FROM DUAL
       WHERE LV_USER_ID IN
                (    SELECT REGEXP_SUBSTR (
                               (SELECT PROPERTY_VALUE
                                  FROM RC_PROPERTIES
                                 WHERE PROPERTY_NAME = 'HAS_SF_UPLOAD_ACCESS'),
                               '[^,]+',
                               1,
                               LEVEL)
                       FROM DUAL
                 CONNECT BY REGEXP_SUBSTR (
                               (SELECT PROPERTY_VALUE
                                  FROM RC_PROPERTIES
                                 WHERE PROPERTY_NAME = 'HAS_SF_UPLOAD_ACCESS'),
                               '[^,]+',
                               1,
                               LEVEL)
                               IS NOT NULL);

      SELECT DISTINCT IS_UPLOAD_ENABLED
        INTO LV_IS_FORECAST_UPLOAD_ENABLED
        FROM RC_SALES_FORECAST_CONFIG
       WHERE     FORECAST_QUARTER = LV_QUARTER
             AND FORECAST_MONTH = LV_MONTH
             AND FORECAST_YEAR = LV_YEAR;

      SELECT COUNT (COMMON_PART_NUMBER)
        INTO LV_APPROVE_COUNT
        FROM RC_SALES_FORECAST_STAGING
       WHERE     APPROVAL_STATUS = 'APPROVED'
             AND FORECAST_QUARTER = LV_QUARTER
             AND FORECAST_MONTH = LV_MONTH
             AND FORECAST_YEAR = LV_YEAR;

      IF (    LV_USER_COUNT > 0
          AND LV_IS_FORECAST_UPLOAD_ENABLED = 'Y'
          AND LV_REVIEW = 'N'
          AND LV_APPROVE_COUNT = 0)
      THEN
         LV_UPLOAD_BTN_FLAG := 'Y';
      ELSIF (    LV_USER_COUNT > 0
             AND LV_IS_FORECAST_UPLOAD_ENABLED = 'N'
             AND LV_REVIEW = 'N'
             AND LV_APPROVE_COUNT > 0)
      THEN
         LV_UPLOAD_BTN_FLAG := 'D';
      ELSE
         LV_UPLOAD_BTN_FLAG := 'N';
      END IF;

      --        INSERT INTO RC_TEST_BLOCK
      --             VALUES ('LV_UPLOAD_BTN_FLAG ' || LV_UPLOAD_BTN_FLAG, SYSDATE);
      --
      --        COMMIT;

      LV_USER_COUNT := 0;
      LV_APPROVE_COUNT := 0;

      SELECT COUNT (*)
        INTO LV_USER_COUNT
        FROM DUAL
       WHERE LV_USER_ID IN
                (    SELECT REGEXP_SUBSTR (
                               (SELECT PROPERTY_VALUE
                                  FROM RC_PROPERTIES
                                 WHERE PROPERTY_NAME = 'HAS_FC_PUBLISH_ACCESS'),
                               '[^,]+',
                               1,
                               LEVEL)
                       FROM DUAL
                 CONNECT BY REGEXP_SUBSTR (
                               (SELECT PROPERTY_VALUE
                                  FROM RC_PROPERTIES
                                 WHERE PROPERTY_NAME =
                                          'HAS_FC_PUBLISH_ACCESS'),
                               '[^,]+',
                               1,
                               LEVEL)
                               IS NOT NULL);

      SELECT DISTINCT IS_PUBLISHED
        INTO LV_IS_FORECAST_PUBLISHED
        FROM RC_SALES_FORECAST_CONFIG
       WHERE     FORECAST_QUARTER = LV_QUARTER
             AND FORECAST_MONTH = LV_MONTH
             AND FORECAST_YEAR = LV_YEAR;

      SELECT COUNT (COMMON_PART_NUMBER)
        INTO LV_APPROVE_COUNT
        FROM RC_SALES_FORECAST_STAGING
       WHERE     APPROVAL_STATUS = 'APPROVED'
             AND FORECAST_QUARTER = LV_QUARTER
             AND FORECAST_MONTH = LV_MONTH
             AND FORECAST_YEAR = LV_YEAR;

      IF (    LV_USER_COUNT > 0
          AND LV_IS_FORECAST_PUBLISHED = 'Y'
          AND LV_APPROVE_COUNT = 0)
      THEN
         LV_PUBLISHED_BTN_FLAG := 'D';
      ELSIF (    LV_USER_COUNT > 0
             AND LV_IS_FORECAST_PUBLISHED = 'N'
             AND LV_APPROVE_COUNT > 0)
      THEN
         LV_PUBLISHED_BTN_FLAG := 'Y';
      ELSE
         LV_PUBLISHED_BTN_FLAG := 'N';
      END IF;

      --        INSERT INTO RC_TEST_BLOCK
      --                 VALUES ('LV_PUBLISHED_BTN_FLAG ' || LV_PUBLISHED_BTN_FLAG,
      --                         SYSDATE);
      --
      --        COMMIT;
      --
      --        INSERT INTO RC_TEST_BLOCK
      --                 VALUES (
      --                               'LV_USER_COUNT '
      --                            || LV_USER_COUNT
      --                            || 'LV_IS_FORECAST_PUBLISHED'
      --                            || LV_IS_FORECAST_PUBLISHED
      --                            || 'LV_APPROVE_COUNT'
      --                            || LV_APPROVE_COUNT,
      --                            SYSDATE);
      --
      --        COMMIT;

      O_RECORD_COUNT := LV_RECORD_COUNT;
      O_SALES_FORECAST_LIST := LV_SALES_FORECAST_LIST;
      O_SUBMIT_BTN_FLAG := LV_SUBMIT_BTN_FLAG;
      O_APPROVE_BTN_FLAG := LV_APPROVE_BTN_FLAG;
      O_UPLOAD_BTN_FLAG := LV_UPLOAD_BTN_FLAG;
      O_IS_FORECAST_SUBMITTED := LV_IS_FORECAST_SUBMITTED;
      O_IS_PUBLISHED := LV_PUBLISHED_BTN_FLAG;
      O_PUBLISHED_FLAG := LV_PUBLISHED_FLAG;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         O_RECORD_COUNT := 0;
         O_SALES_FORECAST_LIST := NULL;
         O_SUBMIT_BTN_FLAG := NULL;
         O_APPROVE_BTN_FLAG := NULL;
         O_UPLOAD_BTN_FLAG := NULL;
         O_IS_FORECAST_SUBMITTED := NULL;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'NO DATA FOUND',
            G_ERROR_MSG,
            NULL,
            'CRPADM.RC_SALES_FORECAST_DATA_EXTRACT.RC_SALES_FORECAST_PAGE_LOAD',
            'PACKAGE',
            NULL,
            'N');
      WHEN OTHERS
      THEN
         O_RECORD_COUNT := 0;
         O_SALES_FORECAST_LIST := NULL;
         O_SUBMIT_BTN_FLAG := NULL;
         O_APPROVE_BTN_FLAG := NULL;
         O_UPLOAD_BTN_FLAG := NULL;
         O_IS_FORECAST_SUBMITTED := NULL;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
            G_ERROR_MSG,
            NULL,
            'CRPADM.RC_SALES_FORECAST_DATA_EXTRACT.RC_SALES_FORECAST_PAGE_LOAD',
            'PACKAGE',
            NULL,
            'Y');
   END RC_SALES_FORECAST_PAGE_LOAD;

   PROCEDURE RC_SALES_FORECAST_FIN_SUM_LOAD (
      I_USER_ID                     IN     VARCHAR2,
      I_QUARTER_MONTH               IN     VARCHAR2,
      I_YEAR                        IN     VARCHAR2,
      I_SNAPSHOT                    IN     VARCHAR2,
      O_SALES_FORECAST_FINSUMLIST      OUT CRPADM.RC_SALES_FORECAST_FINSUMLIST)
   IS
      LV_SALES_FORECAST_FINSUMLIST   RC_SALES_FORECAST_FINSUMLIST;
      --      lv_is_overridden               VARCHAR2 (100);
      LV_QUERY                       CLOB;
      LV_MAIN_QUERY                  CLOB;
      LV_ROW_CLAUSE                  CLOB;
      LV_ROW_FILTER_CLAUSE           CLOB;
      LV_ROW_COUNT                   CLOB;
      LV_TABLE_NAME                  VARCHAR2 (100 BYTE);
      LV_QUARTER_MONTH_YEAR          VARCHAR2 (100 BYTE);
      I_QUARTER_MONTH_YEAR           VARCHAR2 (100 BYTE);
      LV_QUARTER                     VARCHAR2 (20 BYTE);
      LV_MONTH                       VARCHAR2 (20 BYTE);
      LV_YEAR                        VARCHAR2 (10 BYTE);
      LV_SNAPSHOT                    VARCHAR2 (10 BYTE);
   BEGIN
      LV_SALES_FORECAST_FINSUMLIST := RC_SALES_FORECAST_FINSUMLIST ();

      LV_SNAPSHOT := I_SNAPSHOT;

      IF I_QUARTER_MONTH = 'ALL' AND I_YEAR = 'ALL'
      THEN
         SELECT DISTINCT FORECAST_QUARTER, FORECAST_MONTH, FORECAST_YEAR
           INTO LV_QUARTER, LV_MONTH, LV_YEAR
           FROM RC_SALES_FORECAST
          WHERE     FORECAST_QUARTER IS NOT NULL
                AND FORECAST_MONTH IS NOT NULL
                AND FORECAST_YEAR IS NOT NULL;
      ELSE
         LV_YEAR := I_YEAR;

         LV_QUARTER := SUBSTR (I_QUARTER_MONTH, 1, 2) || ' FY' || LV_YEAR;
         LV_MONTH := SUBSTR (I_QUARTER_MONTH, -2, 2);
      END IF;

      SELECT DISTINCT FORECAST_QUARTER || FORECAST_MONTH || FORECAST_YEAR
        INTO LV_QUARTER_MONTH_YEAR
        FROM RC_SALES_FORECAST;

      SELECT LV_QUARTER || LV_MONTH || LV_YEAR
        INTO I_QUARTER_MONTH_YEAR
        FROM DUAL;

      IF (LV_SNAPSHOT IS NULL) OR (LV_SNAPSHOT = '')
      THEN
         IF LV_QUARTER_MONTH_YEAR = I_QUARTER_MONTH_YEAR
         THEN
            LV_TABLE_NAME := ' FROM RC_SALES_FORECAST ';
         ELSE
            LV_TABLE_NAME := ' FROM RC_SALES_FORECAST_STAGING ';
         END IF;
      ELSE
         LV_TABLE_NAME := ' FROM RC_ALL_SALES_FORECAST ';
      END IF;


      IF (   LV_SNAPSHOT IS NOT NULL
          OR LV_QUARTER IS NOT NULL
          OR LV_MONTH IS NOT NULL
          OR LV_YEAR IS NOT NULL)
      THEN
         LV_ROW_FILTER_CLAUSE := ' WHERE 1=1 ';

         IF     LV_QUARTER IS NOT NULL
            AND LV_MONTH IS NOT NULL
            AND LV_YEAR IS NOT NULL
         THEN
            --            IF LV_QUARTER_MONTH_YEAR != I_QUARTER_MONTH_YEAR
            --            THEN
            LV_ROW_FILTER_CLAUSE :=
                  LV_ROW_FILTER_CLAUSE
               || ' AND FORECAST_YEAR = '''
               || LV_YEAR
               || '''';
            LV_ROW_FILTER_CLAUSE :=
                  LV_ROW_FILTER_CLAUSE
               || ' AND FORECAST_QUARTER = '''
               || LV_QUARTER
               || '''';
            LV_ROW_FILTER_CLAUSE :=
                  LV_ROW_FILTER_CLAUSE
               || ' AND FORECAST_MONTH = '''
               || LV_MONTH
               || '''';
         --            END IF;
         END IF;

         IF LV_SNAPSHOT IS NOT NULL
         THEN
            LV_ROW_FILTER_CLAUSE :=
                  LV_ROW_FILTER_CLAUSE
               || ' AND SNAPSHOT_TYPE = '''
               || LV_SNAPSHOT
               || '''';
         END IF;
      END IF;

      LV_QUERY :=
            '
      SELECT RC_SALES_FORECAST_FINSUMOBJ (EXPECTED_REVENUE_RF,
                                          EXPECTED_REVENUE_WS,
                                          EXPECTED_REVENUE_OUTLET,
                                          EXPECTED_REPAIR_COST,
                                          RF_FORECASTED_REPAIR_COST,
                                          WS_FORECASTED_REPAIR_COST,
                                          OUTLET_FORECASTED_REPAIR_COST,
                                          FORECASTED_REPAIR_COST,
                                          SUBMITTED_AT,
                                          APPROVED_AT,
                                          UPDATED_ON,
                                          EXPECTED_SALES_REVENUE_RF,
                                          EXPECTED_SALES_REVENUE_OUTLET,
                                          EXPECTED_SALES_REVENUE_WS,
                                          TOTL_EXPCTD_SALES_REPAIR_COST,
                                          FIN_QTR_INFO)
        FROM (SELECT EXPECTED_REVENUE_RF,
                     EXPECTED_REVENUE_WS,
                     EXPECTED_REVENUE_OUTLET,
                     EXPECTED_REPAIR_COST,
                     RF_FORECASTED_REPAIR_COST,
                     WS_FORECASTED_REPAIR_COST,
                     OUTLET_FORECASTED_REPAIR_COST,
                     FORECASTED_REPAIR_COST,
                     (SELECT TO_CHAR (MAX (SUBMITTED_AT),
                                      ''MM/DD/YYYY HH:MI:SS AM'') '
         || LV_TABLE_NAME
         || LV_ROW_FILTER_CLAUSE
         || ')
                        AS SUBMITTED_AT,
                     (SELECT TO_CHAR (MAX (APPROVED_AT),
                                      ''MM/DD/YYYY HH:MI:SS AM'') '
         || LV_TABLE_NAME
         || LV_ROW_FILTER_CLAUSE
         || ')
                        AS APPROVED_AT,
                     (SELECT TO_CHAR (MAX (UPDATED_ON),
                                      ''MM/DD/YYYY HH:MI:SS AM'') '
         || LV_TABLE_NAME
         || LV_ROW_FILTER_CLAUSE
         || ')
                        AS UPDATED_ON,
                     EXPECTED_SALES_REVENUE_RF,
                     EXPECTED_SALES_REVENUE_OUTLET,
                     EXPECTED_SALES_REVENUE_WS,
                     TOTL_EXPCTD_SALES_REPAIR_COST,'''
         --                     (SELECT DISTINCT FISCAL_QUARTER_NAME
         --                        FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
         --                       WHERE     CURRENT_FISCAL_YEAR_FLAG = ''Y''
         --                             AND CURRENT_FISCAL_QUARTER_FLAG = ''Y'')'
         || SUBSTR (LV_QUARTER, 1, 2)
         || '/'
         || LV_MONTH
         || ' FY'
         || LV_YEAR
         || ''' AS FIN_QTR_INFO
                FROM (SELECT SUM (NVL (EXPECTED_REVENUE_RF, 0))
                                AS EXPECTED_REVENUE_RF,
                             SUM (NVL (EXPECTED_REVENUE_WS, 0))
                                AS EXPECTED_REVENUE_WS,
                             SUM (NVL (EXPECTED_REVENUE_OUTLET, 0))
                                AS EXPECTED_REVENUE_OUTLET,
                             SUM (NVL (TOTAL_EXPECTED_REPAIR_COST, 0))
                                AS EXPECTED_REPAIR_COST,
                             --                           SUM (NVL (RF_FORECASTED_REPAIR_COST, 0))
                             --                              AS RF_FORECASTED_REPAIR_COST,
                             --                           SUM (NVL (WS_FORECASTED_REPAIR_COST, 0))
                             --                              AS WS_FORECASTED_REPAIR_COST,
                             SUM (NVL ((NVL ( NVL ( RF_ADJ_OVERRIDDEN_FORECAST, RF_ADJUSTED_FORECAST ), RF_90DAY_FORECAST )) * ASP_RF, 0))
                                AS RF_FORECASTED_REPAIR_COST,
                             SUM (NVL ((NVL ( WS_ADJUSTED_FORECAST, WS_90DAY_FORECAST ) ) * ASP_WS, 0))
                                AS WS_FORECASTED_REPAIR_COST,
                             0 AS OUTLET_FORECASTED_REPAIR_COST,
                             SUM (NVL (TOTAL_FORECASTED_REPAIR_COST, 0))
                                AS FORECASTED_REPAIR_COST,
                             SUM (NVL (EXPECTED_SALES_REVENUE_RF, 0))
                                AS EXPECTED_SALES_REVENUE_RF,
                             SUM (NVL (EXPECTED_SALES_REVENUE_OUTLET, 0))
                                AS EXPECTED_SALES_REVENUE_OUTLET,
                             SUM (NVL (EXPECTED_SALES_REVENUE_WS, 0))
                                AS EXPECTED_SALES_REVENUE_WS,
                             SUM (NVL (TOTL_EXPCTD_SALES_REPAIR_COST, 0))
                                AS TOTL_EXPCTD_SALES_REPAIR_COST '
         || LV_TABLE_NAME
         || LV_ROW_FILTER_CLAUSE
         || '))';

      --
      --      INSERT INTO TEMP_QUERY
      --           VALUES (LV_QUERY, SYSDATE);
      --
      --
      --
      --      INSERT INTO TEMP_QUERY
      --           VALUES (LV_ROW_FILTER_CLAUSE, SYSDATE);



      EXECUTE IMMEDIATE LV_QUERY
         BULK COLLECT INTO LV_SALES_FORECAST_FINSUMLIST;

      O_SALES_FORECAST_FINSUMLIST := LV_SALES_FORECAST_FINSUMLIST;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         O_SALES_FORECAST_FINSUMLIST := NULL;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'NO DATA FOUND',
            G_ERROR_MSG,
            NULL,
            'CRPADM.RC_SALES_FORECAST_DATA_EXTRACT.RC_SALES_FORECAST_FIN_SUM_LOAD',
            'PACKAGE',
            NULL,
            'N');
      WHEN OTHERS
      THEN
         O_SALES_FORECAST_FINSUMLIST := NULL;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
            G_ERROR_MSG,
            NULL,
            'CRPADM.RC_SALES_FORECAST_DATA_EXTRACT.RC_SALES_FORECAST_FIN_SUM_LOAD',
            'PACKAGE',
            NULL,
            'Y');
   END RC_SALES_FORECAST_FIN_SUM_LOAD;

   PROCEDURE RC_SALES_FORECAST_FLAG_DTLS (
      I_USER_ID            IN     VARCHAR2,
      I_FORECAST_QUARTER   IN     VARCHAR2,
      I_FORECAST_MONTH     IN     VARCHAR2,
      I_FORECAST_YEAR      IN     VARCHAR2,
      O_UPLOAD_BTN_FLAG       OUT VARCHAR2)
   IS
      LV_USER_COUNT                   NUMBER := 0;
      LV_IS_FORECAST_UPLOAD_ENABLED   VARCHAR2 (100 BYTE);
      LV_APPROVE_COUNT                NUMBER := 0;
      LV_UPLOAD_BTN_FLAG              VARCHAR2 (100 BYTE);
      LV_USER_ID                      VARCHAR2 (100 BYTE);
      LV_QUARTER                      VARCHAR2 (20 BYTE);
      LV_MONTH                        VARCHAR2 (20 BYTE);
      LV_YEAR                         VARCHAR2 (10 BYTE);
      LV_REVIEW                       VARCHAR2 (10 BYTE);
   BEGIN
      LV_USER_COUNT := 0;
      LV_USER_ID := I_USER_ID;

      --        IF I_QUARTER_MONTH = 'ALL' AND I_YEAR = 'ALL'
      --        THEN
      --            SELECT DISTINCT FORECAST_QUARTER, FORECAST_MONTH, FORECAST_YEAR
      --              INTO LV_QUARTER, LV_MONTH, LV_YEAR
      --              FROM RC_SALES_FORECAST
      --             WHERE     FORECAST_QUARTER IS NOT NULL
      --                   AND FORECAST_MONTH IS NOT NULL
      --                   AND FORECAST_YEAR IS NOT NULL;
      --        ELSE
      LV_YEAR := I_FORECAST_YEAR;

      LV_QUARTER := I_FORECAST_QUARTER; --SUBSTR (I_QUARTER_MONTH, 1, 2) || ' FY' || LV_YEAR;
      LV_MONTH := I_FORECAST_MONTH;         --SUBSTR (I_QUARTER_MONTH, -2, 2);

      --        END IF;

      --        INSERT INTO RC_TEST_BLOCK
      --                 VALUES (LV_QUARTER || '-' || LV_MONTH || '/' || LV_YEAR,
      --                         SYSDATE);
      --
      --        COMMIT;

      SELECT COUNT (*)
        INTO LV_USER_COUNT
        FROM DUAL
       WHERE LV_USER_ID IN
                (    SELECT REGEXP_SUBSTR (
                               (SELECT PROPERTY_VALUE
                                  FROM RC_PROPERTIES
                                 WHERE PROPERTY_NAME = 'HAS_SF_UPLOAD_ACCESS'),
                               '[^,]+',
                               1,
                               LEVEL)
                       FROM DUAL
                 CONNECT BY REGEXP_SUBSTR (
                               (SELECT PROPERTY_VALUE
                                  FROM RC_PROPERTIES
                                 WHERE PROPERTY_NAME = 'HAS_SF_UPLOAD_ACCESS'),
                               '[^,]+',
                               1,
                               LEVEL)
                               IS NOT NULL);

      SELECT DISTINCT IS_UPLOAD_ENABLED
        INTO LV_IS_FORECAST_UPLOAD_ENABLED
        FROM RC_SALES_FORECAST_CONFIG
       WHERE     FORECAST_QUARTER = LV_QUARTER
             AND FORECAST_MONTH = LV_MONTH
             AND FORECAST_YEAR = LV_YEAR;

      SELECT COUNT (COMMON_PART_NUMBER)
        INTO LV_APPROVE_COUNT
        FROM RC_SALES_FORECAST_STAGING
       WHERE     APPROVAL_STATUS = 'APPROVED'
             AND FORECAST_QUARTER = LV_QUARTER
             AND FORECAST_MONTH = LV_MONTH
             AND FORECAST_YEAR = LV_YEAR;

      SELECT TO_CHAR (CONFIG_VALUE)
        INTO LV_REVIEW
        FROM CRPSC.RC_AE_CONFIG_PROPERTIES
       WHERE     CONFIG_NAME = 'REVIEW_FLAG'
             AND CONFIG_CATEGORY = 'ALLOC_CONFIG_UI';

      IF (    LV_USER_COUNT > 0
          AND LV_IS_FORECAST_UPLOAD_ENABLED = 'Y'
          AND LV_REVIEW = 'N'
          AND LV_APPROVE_COUNT = 0)
      THEN
         LV_UPLOAD_BTN_FLAG := 'Y';
      ELSIF (    LV_USER_COUNT > 0
             AND LV_IS_FORECAST_UPLOAD_ENABLED = 'N'
             AND LV_REVIEW = 'N'
             AND LV_APPROVE_COUNT > 0)
      THEN
         LV_UPLOAD_BTN_FLAG := 'D';
      ELSE
         LV_UPLOAD_BTN_FLAG := 'N';
      END IF;

      O_UPLOAD_BTN_FLAG := LV_UPLOAD_BTN_FLAG;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         O_UPLOAD_BTN_FLAG := NULL;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'NO DATA FOUND',
            G_ERROR_MSG,
            NULL,
            'CRPADM.RC_SALES_FORECAST_DATA_EXTRACT.RC_SALES_FORECAST_FLAG_DTLS',
            'PACKAGE',
            NULL,
            'N');
      WHEN OTHERS
      THEN
         O_UPLOAD_BTN_FLAG := NULL;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
            G_ERROR_MSG,
            NULL,
            'CRPADM.RC_SALES_FORECAST_DATA_EXTRACT.RC_SALES_FORECAST_FLAG_DTLS',
            'PACKAGE',
            NULL,
            'Y');
   END RC_SALES_FORECAST_FLAG_DTLS;
END RC_SALES_FORECAST_DATA_EXTRACT;
/