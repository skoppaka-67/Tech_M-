CREATE OR REPLACE PACKAGE BODY CRPADM./*AppDB: 1044120*/
                                                                    "RC_SALES_FORECAST_ENGINE"
AS
   /***********************************************************************************************************
       || Object Name    : RC_SALES_FORECAST_ENGINE
       || Modules          : Sales Forecast data load
       || Modification History
       ||------------------------------------------------------------------------------------------------------
       ||Date                    By                     Version          Comments
       ||------------------------------------------------------------------------------------------------------
       ||25-Sep-2018       Abhishekh Bhat                 1.0          Initial creation
       ||22-Feb-2019       Jyoti Mohanta                  2.0          Fix hourly refresh issue- common inventory item id 0 for NPI pids
       ||21-May-2019       Jyoti Mohanta                  2.1          Fix for forecast approve process, line 1497.
       ||21-Jan-2020       Shreyas Sambasivam             2.2          Fix for Duplicate PID issue changed pointing to RC_PRODUCT_MASTER_MV in Cursor C1 instead of table.         
       ||17-Jun-2020       Jyoti Hegdekar                 2.3          Fix for Sales Forecast OnSubmit process due to duplicate data
                                                                       in Demand Automation table 
       ||------------------------------------------------------------------------------------------------------
   *************************************************************************************************************/
   --Procedure to load the staging table with the latest data and upsert the same in main table
   PROCEDURE RC_SALES_FORECAST_LOAD
   IS
      CURSOR c1
      IS
         SELECT REFRESH_PART_NUMBER,
                COMMON_PART_NUMBER,
                XREF_PART_NUMBER,
                EXCESS_PART_NUMBER,
                REFRESH_INVENTORY_ITEM_ID,
                EXCESS_INVENTORY_ITEM_ID,
                COMMON_INVENTORY_ITEM_ID,
                XREF_INVENTORY_ITEM_ID,
                REFRESH_LIFE_CYCLE_NAME,
                NVL (RF_NETTABLE_DGI_WITH_YIELD, 0)
                   AS RF_NETTABLE_DGI_WITH_YIELD,
                NVL (WS_NETTABLE_DGI_WITH_YIELD, 0)
                   AS WS_NETTABLE_DGI_WITH_YIELD,
                NVL (POE_NETTABLE_DGI_WITH_YIELD, 0)
                   AS POE_NETTABLE_DGI_WITH_YIELD,
                NVL (RF_NETTABLE_DGI_WITHOUT_YIELD, 0)
                   AS RF_NETTABLE_DGI_WITHOUT_YIELD,
                NVL (WS_NETTABLE_DGI_WITHOUT_YIELD, 0)
                   AS WS_NETTABLE_DGI_WITHOUT_YIELD,
                NVL (POE_NETTABLE_DGI_WITHOUT_YIELD, 0)
                   AS POE_NETTABLE_DGI_WITHOUT_YIELD,
                (  NVL (RF_NETTABLE_DGI_WITHOUT_YIELD, 0)
                 + NVL (WS_NETTABLE_DGI_WITHOUT_YIELD, 0)
                 + NVL (POE_NETTABLE_DGI_WITHOUT_YIELD, 0))
                   NETTABLE_DGI,
                NVL (UNORDERED_FG, 0)    AS UNORDERED_FG,
                NVL (UNORDERED_RF_FG, 0) AS UNORDERED_RF_FG,
                NVL (UNORDERED_WS_FG, 0) AS UNORDERED_WS_FG,
                NVL (
                   (  NVL (
                         (  NVL (RF_NETTABLE_DGI_WITHOUT_YIELD, 0)
                          + NVL (WS_NETTABLE_DGI_WITHOUT_YIELD, 0)
                          + NVL (POE_NETTABLE_DGI_WITHOUT_YIELD, 0)),
                         0)
                    + NVL (UNORDERED_FG, 0)),
                   0)
                   AS TOTAL_NETTABLE_PIPELINE,
                NVL (TOTAL_NON_NETTABLE_PIPELINE, 0)
                   TOTAL_NON_NETTABLE_PIPELINE,
                EXCESS_LIFE_CYCLE,
                REFRESH_LIFE_CYCLE,
                MFG_EOS_DATE
           FROM (SELECT REFRESH_PART_NUMBER,
                        COMMON_PART_NUMBER,
                        XREF_PART_NUMBER,
                        EXCESS_PART_NUMBER,
                        REFRESH_INVENTORY_ITEM_ID,
                        EXCESS_INVENTORY_ITEM_ID,
                        COMMON_INVENTORY_ITEM_ID,
                        XREF_INVENTORY_ITEM_ID,
                        REFRESH_LIFE_CYCLE_NAME,
                        FLOOR (
                           GREATEST (
                                FLOOR (
                                   NVL (
                                      (SELECT SUM (RF_QTY_AFTER_YIELD)
                                         FROM CRPADM.RC_INV_BTS_C3_MV
                                        WHERE     (   LOCATION IN
                                                         (SELECT MSTR.SUB_INVENTORY_LOCATION
                                                            FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                                 MSTR
                                                           WHERE     MSTR.INVENTORY_TYPE =
                                                                        1
                                                                 AND MSTR.NETTABLE_FLAG =
                                                                        1
                                                                 AND MSTR.PROGRAM_TYPE IN
                                                                        (0))
                                                   OR LOCATION IN
                                                         ('RF-F-RHS',
                                                          'RF-FGI-R',
                                                          'RF-W-OEM',
                                                          'RF-W-RHS',
                                                          'RF-FGI',
                                                          'RF-WIP'))
                                              AND (   PART_NUMBER =
                                                         MP.REFRESH_PART_NUMBER
                                                   --          OR PART_NUMBER =
                                                   --                MP.EXCESS_PART_NUMBER
                                                   OR PART_NUMBER =
                                                         MP.COMMON_PART_NUMBER
                                                   OR PART_NUMBER =
                                                         MP.XREF_PART_NUMBER)
                                              AND SITE NOT LIKE 'Z32%'),
                                      0))
                              - (SELECT ABS (SUM (TOTAL_RESERVATIONS))
                                   FROM CRPADM.RC_INV_BTS_C3_MV
                                  WHERE     (   LOCATION = 'DGI'
                                             OR LOCATION IN
                                                   (SELECT MSTR.SUB_INVENTORY_LOCATION
                                                      FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                           MSTR
                                                     WHERE     MSTR.INVENTORY_TYPE =
                                                                  1
                                                           AND MSTR.NETTABLE_FLAG =
                                                                  1
                                                           AND MSTR.PROGRAM_TYPE IN
                                                                  (0))
                                             OR LOCATION IN ('RF-F-RHS',
                                                             'RF-FGI',
                                                             'RF-FGI-R',
                                                             'RF-W-OEM',
                                                             'RF-W-RHS',
                                                             'RF-WIP'))
                                        AND (   PART_NUMBER =
                                                   MP.REFRESH_PART_NUMBER
                                             --            OR PART_NUMBER =
                                             --                  MP.EXCESS_PART_NUMBER
                                             OR PART_NUMBER =
                                                   MP.COMMON_PART_NUMBER
                                             OR PART_NUMBER =
                                                   MP.XREF_PART_NUMBER)
                                        AND SITE NOT LIKE 'Z32%'),
                              0))
                           AS RF_NETTABLE_DGI_WITH_YIELD,
                        FLOOR (
                           GREATEST (
                                FLOOR (
                                   NVL (
                                      (SELECT SUM (WS_QTY_AFTER_YIELD)
                                         FROM CRPADM.RC_INV_BTS_C3_MV
                                        WHERE     (   LOCATION IN
                                                         (SELECT MSTR.SUB_INVENTORY_LOCATION
                                                            FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                                 MSTR
                                                           WHERE     MSTR.INVENTORY_TYPE =
                                                                        1
                                                                 AND MSTR.NETTABLE_FLAG =
                                                                        1
                                                                 AND MSTR.PROGRAM_TYPE IN
                                                                        (1))
                                                   OR LOCATION IN
                                                         ('WS-F-RHS',
                                                          'WS-FGI',
                                                          'WS-FGSLD',
                                                          'WS-W-RHS',
                                                          'WS-WIP'))
                                              AND ( --        PART_NUMBER = MP.REFRESH_PART_NUMBER
                                                                --          OR
                                                     PART_NUMBER =
                                                        MP.EXCESS_PART_NUMBER
                                                  OR PART_NUMBER =
                                                        MP.COMMON_PART_NUMBER
                                                  OR PART_NUMBER =
                                                        MP.XREF_PART_NUMBER)
                                              AND SITE NOT LIKE 'Z32%'),
                                      0))
                              - (SELECT ABS (SUM (TOTAL_RESERVATIONS))
                                   FROM CRPADM.RC_INV_BTS_C3_MV
                                  WHERE     (   LOCATION = 'DGI'
                                             OR LOCATION IN
                                                   (SELECT MSTR.SUB_INVENTORY_LOCATION
                                                      FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                           MSTR
                                                     WHERE     MSTR.INVENTORY_TYPE =
                                                                  1
                                                           AND MSTR.NETTABLE_FLAG =
                                                                  1
                                                           AND MSTR.PROGRAM_TYPE IN
                                                                  (1))
                                             OR LOCATION IN ('WS-F-RHS',
                                                             'WS-FGI',
                                                             'WS-FGSLD',
                                                             'WS-W-RHS',
                                                             'WS-WIP'))
                                        AND ( --                               PART_NUMBER = MP.REFRESH_PART_NUMBER
                                                              --            OR
                                               PART_NUMBER =
                                                  MP.EXCESS_PART_NUMBER
                                            OR PART_NUMBER =
                                                  MP.COMMON_PART_NUMBER
                                            OR PART_NUMBER =
                                                  MP.XREF_PART_NUMBER)
                                        AND SITE NOT LIKE 'Z32%'),
                              0))
                           AS WS_NETTABLE_DGI_WITH_YIELD,
                        FLOOR (
                           GREATEST (
                                FLOOR (
                                   NVL (
                                      (SELECT SUM (
                                                   WS_QTY_AFTER_YIELD
                                                 + RF_QTY_AFTER_YIELD)
                                         FROM CRPADM.RC_INV_BTS_C3_MV
                                        WHERE     (LOCATION IN
                                                      (SELECT MSTR.SUB_INVENTORY_LOCATION
                                                         FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                              MSTR
                                                        WHERE     MSTR.INVENTORY_TYPE =
                                                                     1
                                                              AND MSTR.NETTABLE_FLAG =
                                                                     1
                                                              AND MSTR.PROGRAM_TYPE IN
                                                                     (2)))
                                              AND (   PART_NUMBER =
                                                         MP.REFRESH_PART_NUMBER
                                                   OR PART_NUMBER =
                                                         MP.EXCESS_PART_NUMBER
                                                   OR PART_NUMBER =
                                                         MP.COMMON_PART_NUMBER
                                                   OR PART_NUMBER =
                                                         MP.XREF_PART_NUMBER)
                                              AND SITE NOT LIKE 'Z32%'),
                                      0))
                              - (SELECT ABS (SUM (TOTAL_RESERVATIONS))
                                   FROM CRPADM.RC_INV_BTS_C3_MV
                                  WHERE     (   LOCATION = 'DGI'
                                             OR LOCATION IN
                                                   (SELECT MSTR.SUB_INVENTORY_LOCATION
                                                      FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                           MSTR
                                                     WHERE     MSTR.INVENTORY_TYPE =
                                                                  1
                                                           AND MSTR.NETTABLE_FLAG =
                                                                  1
                                                           AND MSTR.PROGRAM_TYPE IN
                                                                  (2)))
                                        AND (   PART_NUMBER =
                                                   MP.REFRESH_PART_NUMBER
                                             OR PART_NUMBER =
                                                   MP.EXCESS_PART_NUMBER
                                             OR PART_NUMBER =
                                                   MP.COMMON_PART_NUMBER
                                             OR PART_NUMBER =
                                                   MP.XREF_PART_NUMBER)
                                        AND SITE NOT LIKE 'Z32%'),
                              0))
                           AS POE_NETTABLE_DGI_WITH_YIELD,
                        FLOOR (
                           GREATEST (
                              FLOOR (
                                 NVL (
                                    (SELECT SUM (QTY_ON_HAND)
                                       FROM CRPADM.RC_INV_BTS_C3_MV INV
                                      WHERE     (   LOCATION IN
                                                       (SELECT MSTR.SUB_INVENTORY_LOCATION
                                                          FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                               MSTR
                                                         WHERE     MSTR.INVENTORY_TYPE =
                                                                      1
                                                               AND MSTR.NETTABLE_FLAG =
                                                                      1
                                                               AND MSTR.PROGRAM_TYPE IN
                                                                      (0))
                                                 OR LOCATION IN ('RF-F-RHS',
                                                                 'RF-FGI-R',
                                                                 'RF-W-OEM',
                                                                 'RF-W-RHS',
                                                                 'RF-FGI',
                                                                 'RF-WIP'))
                                            AND (   PART_NUMBER =
                                                       MP.REFRESH_PART_NUMBER
                                                 --          OR PART_NUMBER =
                                                 --                MP.EXCESS_PART_NUMBER
                                                 OR PART_NUMBER =
                                                       MP.COMMON_PART_NUMBER
                                                 OR PART_NUMBER =
                                                       MP.XREF_PART_NUMBER)
                                            AND EXISTS
                                                   (SELECT *
                                                      FROM CRPADM.RC_PRODUCT_REPAIR_SETUP
                                                           RS,
                                                           CRPADM.RC_PRODUCT_REPAIR_PARTNER
                                                           RP
                                                     WHERE     1 = 1
                                                           AND RS.REFRESH_METHOD_ID IN
                                                                  (SELECT DTLS.REFRESH_METHOD_ID
                                                                     FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                                          MSTR,
                                                                          CRPADM.RC_SUB_INV_LOC_FLG_DTLS
                                                                          DTLS
                                                                    WHERE     MSTR.SUB_INVENTORY_ID =
                                                                                 DTLS.SUB_INVENTORY_ID
                                                                          AND MSTR.SUB_INVENTORY_LOCATION =
                                                                                 INV.LOCATION)
                                                           AND RS.REFRESH_INVENTORY_ITEM_ID IN
                                                                  (MP.REFRESH_INVENTORY_ITEM_ID,
                                                                   MP.EXCESS_INVENTORY_ITEM_ID,
                                                                   MP.COMMON_INVENTORY_ITEM_ID,
                                                                   MP.XREF_INVENTORY_ITEM_ID)
                                                           AND RS.REPAIR_PARTNER_ID =
                                                                  RP.REPAIR_PARTNER_ID
                                                           AND RS.REFRESH_STATUS =
                                                                  'ACTIVE'
                                                           AND RP.ACTIVE_FLAG =
                                                                  'Y')
                                            AND SITE NOT LIKE 'Z32%'),
                                    0)),
                              0))
                           AS RF_NETTABLE_DGI_WITHOUT_YIELD,
                        FLOOR (
                           GREATEST (
                              FLOOR (
                                 NVL (
                                    (SELECT SUM (QTY_ON_HAND)
                                       FROM CRPADM.RC_INV_BTS_C3_MV INV
                                      WHERE     (   LOCATION IN
                                                       (SELECT MSTR.SUB_INVENTORY_LOCATION
                                                          FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                               MSTR
                                                         WHERE     MSTR.INVENTORY_TYPE =
                                                                      1
                                                               AND MSTR.NETTABLE_FLAG =
                                                                      1
                                                               AND MSTR.PROGRAM_TYPE IN
                                                                      (1))
                                                 OR LOCATION IN ('WS-F-RHS',
                                                                 'WS-FGI',
                                                                 'WS-FGSLD',
                                                                 'WS-W-RHS',
                                                                 'WS-WIP'))
                                            AND ( --        PART_NUMBER = MP.REFRESH_PART_NUMBER
                                                                --          OR
                                                   PART_NUMBER =
                                                      MP.EXCESS_PART_NUMBER
                                                OR PART_NUMBER =
                                                      MP.COMMON_PART_NUMBER
                                                OR PART_NUMBER =
                                                      MP.XREF_PART_NUMBER)
                                            AND EXISTS
                                                   (SELECT *
                                                      FROM CRPADM.RC_PRODUCT_REPAIR_SETUP
                                                           RS,
                                                           CRPADM.RC_PRODUCT_REPAIR_PARTNER
                                                           RP
                                                     WHERE     1 = 1
                                                           AND RS.REFRESH_METHOD_ID IN
                                                                  (SELECT DTLS.REFRESH_METHOD_ID
                                                                     FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                                          MSTR,
                                                                          CRPADM.RC_SUB_INV_LOC_FLG_DTLS
                                                                          DTLS
                                                                    WHERE     MSTR.SUB_INVENTORY_ID =
                                                                                 DTLS.SUB_INVENTORY_ID
                                                                          AND MSTR.SUB_INVENTORY_LOCATION =
                                                                                 INV.LOCATION)
                                                           AND RS.REFRESH_INVENTORY_ITEM_ID IN
                                                                  (MP.REFRESH_INVENTORY_ITEM_ID,
                                                                   MP.EXCESS_INVENTORY_ITEM_ID,
                                                                   MP.COMMON_INVENTORY_ITEM_ID,
                                                                   MP.XREF_INVENTORY_ITEM_ID)
                                                           AND RS.REPAIR_PARTNER_ID =
                                                                  RP.REPAIR_PARTNER_ID
                                                           AND RS.REFRESH_STATUS =
                                                                  'ACTIVE'
                                                           AND (   RP.ACTIVE_FLAG =
                                                                      'Y'
                                                                OR RP.THEATER_ID =
                                                                      '3'))
                                            AND SITE NOT LIKE 'Z32%'),
                                    0)),
                              0))
                           AS WS_NETTABLE_DGI_WITHOUT_YIELD,
                        FLOOR (
                           GREATEST (
                              FLOOR (
                                 NVL (
                                    (SELECT SUM (QTY_ON_HAND)
                                       FROM CRPADM.RC_INV_BTS_C3_MV INV
                                      WHERE     (LOCATION IN
                                                    (SELECT MSTR.SUB_INVENTORY_LOCATION
                                                       FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                            MSTR
                                                      WHERE     MSTR.INVENTORY_TYPE =
                                                                   1
                                                            AND MSTR.NETTABLE_FLAG =
                                                                   1
                                                            AND MSTR.PROGRAM_TYPE IN
                                                                   (2)))
                                            AND (   PART_NUMBER =
                                                       MP.REFRESH_PART_NUMBER
                                                 OR PART_NUMBER =
                                                       MP.EXCESS_PART_NUMBER
                                                 OR PART_NUMBER =
                                                       MP.COMMON_PART_NUMBER
                                                 OR PART_NUMBER =
                                                       MP.XREF_PART_NUMBER)
                                            AND EXISTS
                                                   (SELECT *
                                                      FROM CRPADM.RC_PRODUCT_REPAIR_SETUP
                                                           RS,
                                                           CRPADM.RC_PRODUCT_REPAIR_PARTNER
                                                           RP
                                                     WHERE     1 = 1
                                                           AND RS.REFRESH_METHOD_ID IN
                                                                  (SELECT DTLS.REFRESH_METHOD_ID
                                                                     FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                                          MSTR,
                                                                          CRPADM.RC_SUB_INV_LOC_FLG_DTLS
                                                                          DTLS
                                                                    WHERE     MSTR.SUB_INVENTORY_ID =
                                                                                 DTLS.SUB_INVENTORY_ID
                                                                          AND MSTR.SUB_INVENTORY_LOCATION =
                                                                                 INV.LOCATION)
                                                           AND RS.REFRESH_INVENTORY_ITEM_ID IN
                                                                  (MP.REFRESH_INVENTORY_ITEM_ID,
                                                                   MP.EXCESS_INVENTORY_ITEM_ID,
                                                                   MP.COMMON_INVENTORY_ITEM_ID,
                                                                   MP.XREF_INVENTORY_ITEM_ID)
                                                           AND RS.REPAIR_PARTNER_ID =
                                                                  RP.REPAIR_PARTNER_ID
                                                           AND RS.REFRESH_STATUS =
                                                                  'ACTIVE'
                                                           AND RP.ACTIVE_FLAG =
                                                                  'Y')
                                            AND SITE NOT LIKE 'Z32%'),
                                    0)),
                              0))
                           AS POE_NETTABLE_DGI_WITHOUT_YIELD,
                        FLOOR (
                           GREATEST (
                              FLOOR (
                                 NVL (
                                    (SELECT SUM (QTY_ON_HAND)
                                       FROM CRPADM.RC_INV_BTS_C3_MV
                                      WHERE     (   LOCATION IN
                                                       (SELECT MSTR.SUB_INVENTORY_LOCATION
                                                          FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                               MSTR
                                                         WHERE     MSTR.INVENTORY_TYPE =
                                                                      1
                                                               AND MSTR.NETTABLE_FLAG =
                                                                      0)
                                                 OR LOCATION IN ('RF-F-RHS',
                                                                 'RF-FGI-R',
                                                                 'RF-W-OEM',
                                                                 'RF-W-RHS',
                                                                 'RF-FGI',
                                                                 'RF-WIP',
                                                                 'WS-F-RHS',
                                                                 'WS-FGI',
                                                                 'WS-FGSLD',
                                                                 'WS-W-RHS',
                                                                 'WS-WIP'))
                                            AND (   PART_NUMBER =
                                                       MP.REFRESH_PART_NUMBER
                                                 OR PART_NUMBER =
                                                       MP.EXCESS_PART_NUMBER
                                                 OR PART_NUMBER =
                                                       MP.COMMON_PART_NUMBER
                                                 OR PART_NUMBER =
                                                       MP.XREF_PART_NUMBER)
                                            AND SITE NOT LIKE 'Z32%'),
                                    0)),
                              0))
                           AS TOTAL_NON_NETTABLE_PIPELINE,
                        (SELECT GREATEST (
                                   SUM (
                                        (QTY_ON_HAND)
                                      - ABS (TOTAL_RESERVATIONS)),
                                   0)
                           FROM CRPADM.RC_INV_BTS_C3_MV
                          WHERE     LOCATION = 'FG' -- Considering only BTS FG locations
                                AND (   PART_NUMBER = MP.REFRESH_PART_NUMBER
                                     OR PART_NUMBER = MP.EXCESS_PART_NUMBER --Need to consider both RF PIDs and WS Pids
                                     OR PART_NUMBER = MP.COMMON_PART_NUMBER
                                     OR PART_NUMBER = MP.XREF_PART_NUMBER)
                                AND SITE NOT LIKE 'Z32%')
                           AS UNORDERED_FG,
                        (SELECT GREATEST (
                                   SUM (
                                        (QTY_ON_HAND)
                                      - ABS (TOTAL_RESERVATIONS)),
                                   0)
                           FROM CRPADM.RC_INV_BTS_C3_MV
                          WHERE     LOCATION = 'FG' -- Considering only BTS FG locations
                                AND (   PART_NUMBER = MP.REFRESH_PART_NUMBER
                                     --                            OR PART_NUMBER = MP.EXCESS_PART_NUMBER --Need to consider RF PIDs
                                     OR PART_NUMBER = MP.COMMON_PART_NUMBER
                                     OR PART_NUMBER = MP.XREF_PART_NUMBER)
                                AND SITE NOT LIKE 'Z32%')
                           AS UNORDERED_RF_FG,
                        (SELECT GREATEST (
                                   SUM (
                                        (QTY_ON_HAND)
                                      - ABS (TOTAL_RESERVATIONS)),
                                   0)
                           FROM CRPADM.RC_INV_BTS_C3_MV
                          WHERE     LOCATION = 'FG' -- Considering only BTS FG locations
                                AND ( --                       PART_NUMBER = MP.REFRESH_PART_NUMBER
                                              --                            OR
                                       PART_NUMBER = MP.EXCESS_PART_NUMBER --Need to consider WS Pids
                                    OR PART_NUMBER = MP.COMMON_PART_NUMBER
                                    OR PART_NUMBER = MP.XREF_PART_NUMBER)
                                AND SITE NOT LIKE 'Z32%')
                           AS UNORDERED_WS_FG,
                        EXCESS_LIFE_CYCLE,
                        REFRESH_LIFE_CYCLE,
                        MFG_EOS_DATE
                   FROM (SELECT /*+ INDEX(RPM1) */
                               REFRESH_PART_NUMBER,
                                COMMON_PART_NUMBER,
                                XREF_PART_NUMBER,
                                (SELECT DISTINCT REFRESH_PART_NUMBER
                                   FROM CRPADM.RC_PRODUCT_MASTER_MV PM
                                  WHERE     PROGRAM_TYPE = 1
                                        AND REFRESH_LIFE_CYCLE_ID IN
                                               (0, 3, 4)
                                        AND (   PM.COMMON_PART_NUMBER =
                                                   RPM1.COMMON_PART_NUMBER
                                             OR PM.XREF_PART_NUMBER =
                                                   RPM1.COMMON_PART_NUMBER)
                                        AND COMMON_PART_NUMBER NOT IN
                                               (SELECT COMMON_PART_NUMBER
                                                  FROM (  SELECT COMMON_PART_NUMBER,
                                                                 PROGRAM_TYPE
                                                            FROM CRPADM.RC_PRODUCT_MASTER_MV
                                                        GROUP BY COMMON_PART_NUMBER,
                                                                 PROGRAM_TYPE
                                                          HAVING COUNT (
                                                                    COMMON_PART_NUMBER) >
                                                                    1)
                                                UNION
                                                SELECT XREF_PART_NUMBER
                                                  FROM CRPADM.RC_PRODUCT_MASTER_MV
                                                 WHERE XREF_PART_NUMBER IN
                                                          (SELECT COMMON_PART_NUMBER
                                                             FROM CRPADM.RC_PRODUCT_MASTER_MV)))
                                   EXCESS_PART_NUMBER,
                                REFRESH_INVENTORY_ITEM_ID,
                                (SELECT DISTINCT REFRESH_INVENTORY_ITEM_ID
                                   FROM CRPADM.RC_PRODUCT_MASTER_MV PM
                                  WHERE     PROGRAM_TYPE = 1
                                        AND REFRESH_LIFE_CYCLE_ID IN
                                               (0, 3, 4)
                                        AND (   PM.COMMON_PART_NUMBER =
                                                   RPM1.COMMON_PART_NUMBER
                                             OR PM.XREF_PART_NUMBER =
                                                   RPM1.COMMON_PART_NUMBER)
                                        AND COMMON_PART_NUMBER NOT IN
                                               (SELECT COMMON_PART_NUMBER
                                                  FROM (  SELECT COMMON_PART_NUMBER,
                                                                 PROGRAM_TYPE
                                                            FROM CRPADM.RC_PRODUCT_MASTER_MV
                                                        GROUP BY COMMON_PART_NUMBER,
                                                                 PROGRAM_TYPE
                                                          HAVING COUNT (
                                                                    COMMON_PART_NUMBER) >
                                                                    1)
                                                UNION
                                                SELECT XREF_PART_NUMBER
                                                  FROM CRPADM.RC_PRODUCT_MASTER_MV
                                                 WHERE XREF_PART_NUMBER IN
                                                          (SELECT COMMON_PART_NUMBER
                                                             FROM CRPADM.RC_PRODUCT_MASTER_MV)))
                                   EXCESS_INVENTORY_ITEM_ID,
                                COMMON_INVENTORY_ITEM_ID,
                                XREF_INVENTORY_ITEM_ID,
                                REFRESH_LIFE_CYCLE_NAME,
                                (SELECT DISTINCT REFRESH_LIFE_CYCLE_NAME
                                   FROM CRPADM.RC_PRODUCT_MASTER_MV PM
                                  WHERE     PROGRAM_TYPE = 1
                                        AND REFRESH_LIFE_CYCLE_ID IN
                                               (0, 3, 4)
                                        AND (   PM.COMMON_PART_NUMBER =
                                                   RPM1.COMMON_PART_NUMBER
                                             OR PM.XREF_PART_NUMBER =
                                                   RPM1.COMMON_PART_NUMBER)
                                        AND COMMON_PART_NUMBER NOT IN
                                               (SELECT COMMON_PART_NUMBER
                                                  FROM (  SELECT COMMON_PART_NUMBER,
                                                                 PROGRAM_TYPE
                                                            FROM CRPADM.RC_PRODUCT_MASTER_MV
                                                        GROUP BY COMMON_PART_NUMBER,
                                                                 PROGRAM_TYPE
                                                          HAVING COUNT (
                                                                    COMMON_PART_NUMBER) >
                                                                    1)
                                                UNION
                                                SELECT XREF_PART_NUMBER
                                                  FROM CRPADM.RC_PRODUCT_MASTER_MV
                                                 WHERE XREF_PART_NUMBER IN
                                                          (SELECT COMMON_PART_NUMBER
                                                             FROM CRPADM.RC_PRODUCT_MASTER_MV)))
                                   EXCESS_LIFE_CYCLE,
                                REFRESH_LIFE_CYCLE_NAME REFRESH_LIFE_CYCLE,
                                MFG_EOS_DATE
                           FROM CRPADM.RC_PRODUCT_MASTER_MV RPM1
                          WHERE     PROGRAM_TYPE = 0
                                AND REFRESH_LIFE_CYCLE_ID IN (0, 3, 4)
                         UNION
                         SELECT NULL                    REFRESH_PART_NUMBER,
                                COMMON_PART_NUMBER,
                                XREF_PART_NUMBER,
                                REFRESH_PART_NUMBER     EXCESS_PART_NUMBER,
                                NULL                    REFRESH_INVENTORY_ITEM_ID,
                                REFRESH_INVENTORY_ITEM_ID
                                   EXCESS_INVENTORY_ITEM_ID,
                                COMMON_INVENTORY_ITEM_ID,
                                XREF_INVENTORY_ITEM_ID,
                                REFRESH_LIFE_CYCLE_NAME,
                                REFRESH_LIFE_CYCLE_NAME EXCESS_LIFE_CYCLE,
                                NULL                    REFRESH_LIFE_CYCLE,
                                MFG_EOS_DATE
                           FROM CRPADM.RC_PRODUCT_MASTER_MV PM
                          WHERE     PROGRAM_TYPE = 1
                                AND REFRESH_LIFE_CYCLE_ID IN (0, 3, 4)
                                AND NOT EXISTS
                                       (SELECT COMMON_PART_NUMBER
                                          FROM CRPADM.RC_PRODUCT_MASTER_MV RPM2
                                         WHERE     PROGRAM_TYPE = 0
                                               AND RPM2.REFRESH_LIFE_CYCLE_ID <>
                                                      6
                                               AND PM.COMMON_PART_NUMBER =
                                                      RPM2.COMMON_PART_NUMBER)
                                AND NOT EXISTS
                                       (SELECT XREF_PART_NUMBER
                                          FROM CRPADM.RC_PRODUCT_MASTER_MV RPM3
                                         WHERE     PROGRAM_TYPE = 0
                                               AND RPM3.REFRESH_LIFE_CYCLE_ID <>
                                                      6
                                               AND PM.COMMON_PART_NUMBER =
                                                      RPM3.XREF_PART_NUMBER))
                        MP);

      LV_HOURS        NUMBER (2);

      TYPE MONTH_OBJECT IS RECORD
      (
         FORECAST_QUARTER   VARCHAR2 (200 BYTE),
         FORECAST_MONTH     VARCHAR2 (200 BYTE),
         FORECAST_YEAR      VARCHAR2 (200 BYTE)
      );

      TYPE MONTH_LIST IS TABLE OF MONTH_OBJECT;

      lv_month_list   MONTH_LIST := MONTH_LIST ();
      LV_COUNT        NUMBER;
   BEGIN
      INSERT INTO CRPADM.RC_PROCESS_LOG
           VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                   'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_LOAD',
                   'START',
                   SYSDATE);

      COMMIT;


      --Update the RC_SALES_FORECAST_CONFIG table records to include next two qaurter records if not present.

      MERGE INTO RC_SALES_FORECAST_CONFIG CONFIG
           USING (  SELECT DISTINCT
                           FISCAL_YEAR_NUMBER,
                           FISCAL_QUARTER_NAME,
                           FISCAL_MONTH_NUMBER
                      FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                     WHERE FISCAL_QUARTER_KEY BETWEEN (SELECT   FISCAL_QUARTER_KEY
                                                              + 1
                                                         FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                                                        WHERE CALENDAR_DATE =
                                                                 TRUNC (
                                                                    SYSDATE))
                                                  AND (SELECT   FISCAL_QUARTER_KEY
                                                              + 2
                                                         FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                                                        WHERE CALENDAR_DATE =
                                                                 TRUNC (
                                                                    SYSDATE))
                  ORDER BY FISCAL_YEAR_NUMBER,
                           FISCAL_QUARTER_NAME,
                           FISCAL_MONTH_NUMBER) DIM
              ON (    CONFIG.FORECAST_YEAR = TO_CHAR (DIM.FISCAL_YEAR_NUMBER)
                  AND CONFIG.FORECAST_QUARTER =
                         TO_CHAR (DIM.FISCAL_QUARTER_NAME)
                  AND CONFIG.FORECAST_MONTH =
                         TO_CHAR (CASE
                                     WHEN DIM.FISCAL_MONTH_NUMBER IN (1,
                                                                      4,
                                                                      7,
                                                                      10)
                                     THEN
                                        'M1'
                                     WHEN DIM.FISCAL_MONTH_NUMBER IN (2,
                                                                      5,
                                                                      8,
                                                                      11)
                                     THEN
                                        'M2'
                                     WHEN DIM.FISCAL_MONTH_NUMBER IN (3,
                                                                      6,
                                                                      9,
                                                                      12)
                                     THEN
                                        'M3'
                                  END))
      WHEN NOT MATCHED
      THEN
         INSERT     (CONFIG.FORECAST_YEAR,
                     CONFIG.FORECAST_QUARTER,
                     CONFIG.FORECAST_MONTH,
                     CONFIG.IS_UPLOAD_ENABLED,
                     CONFIG.IS_SUBMITTED,
                     CONFIG.IS_APPROVED,
                     CONFIG.IS_PUBLISHED,
                     CONFIG.IS_TEMPLATE_ENABLED,
                     CONFIG.IS_OVERRIDDEN)
             VALUES (DIM.FISCAL_YEAR_NUMBER,
                     DIM.FISCAL_QUARTER_NAME,
                     CASE
                        WHEN DIM.FISCAL_MONTH_NUMBER IN (1,
                                                         4,
                                                         7,
                                                         10)
                        THEN
                           'M1'
                        WHEN DIM.FISCAL_MONTH_NUMBER IN (2,
                                                         5,
                                                         8,
                                                         11)
                        THEN
                           'M2'
                        WHEN DIM.FISCAL_MONTH_NUMBER IN (3,
                                                         6,
                                                         9,
                                                         12)
                        THEN
                           'M3'
                     END,
                     'Y',
                     'N',
                     'N',
                     'N',
                     'N',
                     'N');


      BEGIN
         SELECT DISTINCT FORECAST_QUARTER, FORECAST_MONTH, FORECAST_YEAR
           BULK COLLECT INTO lv_month_list
           FROM RC_SALES_FORECAST_STAGING;
      EXCEPTION
         WHEN OTHERS
         THEN
            SELECT FISCAL_QUARTER_NAME FORECAST_QUARTER,
                   'M' || RNUM         AS FORECAST_MONTH,
                   FISCAL_YEAR_NUMBER  FORECAST_YEAR
              BULK COLLECT INTO lv_month_list
              FROM (SELECT *
                      FROM (SELECT FISCAL_QUARTER_NAME,
                                   FISCAL_MONTH_ID,
                                   FISCAL_YEAR_NUMBER,
                                   ROWNUM RNUM
                              FROM (  SELECT DISTINCT
                                             FISCAL_QUARTER_NAME,
                                             FISCAL_MONTH_ID,
                                             FISCAL_YEAR_NUMBER
                                        FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                                       WHERE CURRENT_FISCAL_QUARTER_FLAG = 'Y'
                                    ORDER BY 2))
                     WHERE FISCAL_MONTH_ID =
                              (SELECT FISCAL_MONTH_ID
                                 FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                                WHERE CALENDAR_DATE = TRUNC (SYSDATE)));
      END;



      BEGIN
         --Upsert staging table with new entries
         FOR CUR_REC IN C1
         LOOP
            IF (CUR_REC.COMMON_PART_NUMBER IS NOT NULL)
            THEN
               UPDATE RC_SALES_FORECAST_STAGING RSF
                  SET RSF.RETAIL_PART_NUMBER = CUR_REC.REFRESH_PART_NUMBER,
                      RSF.EXCESS_PART_NUMBER = CUR_REC.EXCESS_PART_NUMBER,
                      RSF.XREF_PART_NUMBER = CUR_REC.XREF_PART_NUMBER,
                      RSF.COMMON_PART_NUMBER = CUR_REC.COMMON_PART_NUMBER,
                      RSF.REFRESH_INVENTORY_ITEM_ID =
                         CUR_REC.REFRESH_INVENTORY_ITEM_ID,
                      RSF.EXCESS_INVENTORY_ITEM_ID =
                         CUR_REC.EXCESS_INVENTORY_ITEM_ID,
                      RSF.XREF_INVENTORY_ITEM_ID =
                         CUR_REC.XREF_INVENTORY_ITEM_ID,
                      RSF.COMMON_INVENTORY_ITEM_ID =
                         CUR_REC.COMMON_INVENTORY_ITEM_ID,
                      RSF.PID_LIFE_CYCLE =
                         CUR_REC.REFRESH_LIFE_CYCLE_NAME,
                      RSF.UNORDERED_FG = CUR_REC.UNORDERED_FG,
                      RSF.UNORDERED_RF_FG = CUR_REC.UNORDERED_RF_FG,
                      RSF.UNORDERED_WS_FG = CUR_REC.UNORDERED_WS_FG,
                      RSF.WS_NETTABLE_DGI_WITH_YIELD =
                         CUR_REC.WS_NETTABLE_DGI_WITH_YIELD,
                      RSF.POE_NETTABLE_DGI_WITH_YIELD =
                         CUR_REC.POE_NETTABLE_DGI_WITH_YIELD,
                      RSF.RF_NETTABLE_DGI_WITHOUT_YIELD =
                         CUR_REC.RF_NETTABLE_DGI_WITHOUT_YIELD,
                      RSF.WS_NETTABLE_DGI_WITHOUT_YIELD =
                         CUR_REC.WS_NETTABLE_DGI_WITHOUT_YIELD,
                      RSF.POE_NETTABLE_DGI_WITHOUT_YIELD =
                         CUR_REC.POE_NETTABLE_DGI_WITHOUT_YIELD,
                      RSF.NETTABLE_DGI = CUR_REC.NETTABLE_DGI,
                      RSF.TOTAL_NON_NETTABLE_PIPELINE =
                         CUR_REC.TOTAL_NON_NETTABLE_PIPELINE,
                      RSF.RF_NETTABLE_DGI_WITH_YIELD =
                         CUR_REC.RF_NETTABLE_DGI_WITH_YIELD,
                      RSF.TOTAL_NETTABLE_PIPELINE =
                         CUR_REC.TOTAL_NETTABLE_PIPELINE,
                      RSF.UPDATED_ON = SYSDATE,
                      RSF.EXCESS_LIFE_CYCLE = CUR_REC.EXCESS_LIFE_CYCLE,
                      RSF.REFRESH_LIFE_CYCLE = CUR_REC.REFRESH_LIFE_CYCLE,
                      RSF.MFG_EOS_DATE = CUR_REC.MFG_EOS_DATE
                WHERE     1 = 1
                      --                AND COMMON_PART_NUMBER IS NOT NULL
                      AND (   COMMON_INVENTORY_ITEM_ID =
                                 CUR_REC.COMMON_INVENTORY_ITEM_ID
                           OR RSF.COMMON_PART_NUMBER =
                                 CUR_REC.COMMON_PART_NUMBER);
            END IF;

            IF (CUR_REC.REFRESH_PART_NUMBER IS NOT NULL)
            THEN
               UPDATE RC_SALES_FORECAST_STAGING RSF
                  SET RSF.RETAIL_PART_NUMBER = CUR_REC.REFRESH_PART_NUMBER,
                      RSF.EXCESS_PART_NUMBER = CUR_REC.EXCESS_PART_NUMBER,
                      RSF.XREF_PART_NUMBER = CUR_REC.XREF_PART_NUMBER,
                      RSF.COMMON_PART_NUMBER = CUR_REC.COMMON_PART_NUMBER,
                      RSF.REFRESH_INVENTORY_ITEM_ID =
                         CUR_REC.REFRESH_INVENTORY_ITEM_ID,
                      RSF.EXCESS_INVENTORY_ITEM_ID =
                         CUR_REC.EXCESS_INVENTORY_ITEM_ID,
                      RSF.XREF_INVENTORY_ITEM_ID =
                         CUR_REC.XREF_INVENTORY_ITEM_ID,
                      RSF.COMMON_INVENTORY_ITEM_ID =
                         CUR_REC.COMMON_INVENTORY_ITEM_ID,
                      RSF.PID_LIFE_CYCLE =
                         CUR_REC.REFRESH_LIFE_CYCLE_NAME,
                      RSF.UNORDERED_FG = CUR_REC.UNORDERED_FG,
                      RSF.UNORDERED_RF_FG = CUR_REC.UNORDERED_RF_FG,
                      RSF.UNORDERED_WS_FG = CUR_REC.UNORDERED_WS_FG,
                      RSF.WS_NETTABLE_DGI_WITH_YIELD =
                         CUR_REC.WS_NETTABLE_DGI_WITH_YIELD,
                      RSF.POE_NETTABLE_DGI_WITH_YIELD =
                         CUR_REC.POE_NETTABLE_DGI_WITH_YIELD,
                      RSF.RF_NETTABLE_DGI_WITHOUT_YIELD =
                         CUR_REC.RF_NETTABLE_DGI_WITHOUT_YIELD,
                      RSF.WS_NETTABLE_DGI_WITHOUT_YIELD =
                         CUR_REC.WS_NETTABLE_DGI_WITHOUT_YIELD,
                      RSF.POE_NETTABLE_DGI_WITHOUT_YIELD =
                         CUR_REC.POE_NETTABLE_DGI_WITHOUT_YIELD,
                      RSF.NETTABLE_DGI = CUR_REC.NETTABLE_DGI,
                      RSF.TOTAL_NON_NETTABLE_PIPELINE =
                         CUR_REC.TOTAL_NON_NETTABLE_PIPELINE,
                      RSF.RF_NETTABLE_DGI_WITH_YIELD =
                         CUR_REC.RF_NETTABLE_DGI_WITH_YIELD,
                      RSF.TOTAL_NETTABLE_PIPELINE =
                         CUR_REC.TOTAL_NETTABLE_PIPELINE,
                      RSF.UPDATED_ON = SYSDATE,
                      RSF.EXCESS_LIFE_CYCLE = CUR_REC.EXCESS_LIFE_CYCLE,
                      RSF.REFRESH_LIFE_CYCLE = CUR_REC.REFRESH_LIFE_CYCLE,
                      RSF.MFG_EOS_DATE = CUR_REC.MFG_EOS_DATE
                WHERE     1 = 1
                      --                and COMMON_PART_NUMBER IS NULL
                      --                         AND RETAIL_PART_NUMBER IS NOT NULL
                      AND (   REFRESH_INVENTORY_ITEM_ID =
                                 CUR_REC.REFRESH_INVENTORY_ITEM_ID
                           OR RSF.RETAIL_PART_NUMBER =
                                 CUR_REC.REFRESH_PART_NUMBER);
            END IF;

            IF (CUR_REC.XREF_PART_NUMBER IS NOT NULL)
            THEN
               UPDATE RC_SALES_FORECAST_STAGING RSF
                  SET RSF.RETAIL_PART_NUMBER = CUR_REC.REFRESH_PART_NUMBER,
                      RSF.EXCESS_PART_NUMBER = CUR_REC.EXCESS_PART_NUMBER,
                      RSF.XREF_PART_NUMBER = CUR_REC.XREF_PART_NUMBER,
                      RSF.COMMON_PART_NUMBER = CUR_REC.COMMON_PART_NUMBER,
                      RSF.REFRESH_INVENTORY_ITEM_ID =
                         CUR_REC.REFRESH_INVENTORY_ITEM_ID,
                      RSF.EXCESS_INVENTORY_ITEM_ID =
                         CUR_REC.EXCESS_INVENTORY_ITEM_ID,
                      RSF.XREF_INVENTORY_ITEM_ID =
                         CUR_REC.XREF_INVENTORY_ITEM_ID,
                      RSF.COMMON_INVENTORY_ITEM_ID =
                         CUR_REC.COMMON_INVENTORY_ITEM_ID,
                      RSF.PID_LIFE_CYCLE =
                         CUR_REC.REFRESH_LIFE_CYCLE_NAME,
                      RSF.UNORDERED_FG = CUR_REC.UNORDERED_FG,
                      RSF.UNORDERED_RF_FG = CUR_REC.UNORDERED_RF_FG,
                      RSF.UNORDERED_WS_FG = CUR_REC.UNORDERED_WS_FG,
                      RSF.WS_NETTABLE_DGI_WITH_YIELD =
                         CUR_REC.WS_NETTABLE_DGI_WITH_YIELD,
                      RSF.POE_NETTABLE_DGI_WITH_YIELD =
                         CUR_REC.POE_NETTABLE_DGI_WITH_YIELD,
                      RSF.RF_NETTABLE_DGI_WITHOUT_YIELD =
                         CUR_REC.RF_NETTABLE_DGI_WITHOUT_YIELD,
                      RSF.WS_NETTABLE_DGI_WITHOUT_YIELD =
                         CUR_REC.WS_NETTABLE_DGI_WITHOUT_YIELD,
                      RSF.POE_NETTABLE_DGI_WITHOUT_YIELD =
                         CUR_REC.POE_NETTABLE_DGI_WITHOUT_YIELD,
                      RSF.NETTABLE_DGI = CUR_REC.NETTABLE_DGI,
                      RSF.TOTAL_NON_NETTABLE_PIPELINE =
                         CUR_REC.TOTAL_NON_NETTABLE_PIPELINE,
                      RSF.RF_NETTABLE_DGI_WITH_YIELD =
                         CUR_REC.RF_NETTABLE_DGI_WITH_YIELD,
                      RSF.TOTAL_NETTABLE_PIPELINE =
                         CUR_REC.TOTAL_NETTABLE_PIPELINE,
                      RSF.UPDATED_ON = SYSDATE,
                      RSF.EXCESS_LIFE_CYCLE = CUR_REC.EXCESS_LIFE_CYCLE,
                      RSF.REFRESH_LIFE_CYCLE = CUR_REC.REFRESH_LIFE_CYCLE,
                      RSF.MFG_EOS_DATE = CUR_REC.MFG_EOS_DATE
                WHERE     1 = 1
                      --                and COMMON_PART_NUMBER IS NULL
                      --                      AND RETAIL_PART_NUMBER IS NULL
                      AND (   XREF_INVENTORY_ITEM_ID =
                                 CUR_REC.XREF_INVENTORY_ITEM_ID
                           OR RSF.XREF_PART_NUMBER = CUR_REC.XREF_PART_NUMBER);
            END IF;

            IF (CUR_REC.EXCESS_PART_NUMBER IS NOT NULL)
            THEN
               UPDATE RC_SALES_FORECAST_STAGING RSF
                  SET RSF.RETAIL_PART_NUMBER = CUR_REC.REFRESH_PART_NUMBER,
                      RSF.EXCESS_PART_NUMBER = CUR_REC.EXCESS_PART_NUMBER,
                      RSF.XREF_PART_NUMBER = CUR_REC.XREF_PART_NUMBER,
                      RSF.COMMON_PART_NUMBER = CUR_REC.COMMON_PART_NUMBER,
                      RSF.REFRESH_INVENTORY_ITEM_ID =
                         CUR_REC.REFRESH_INVENTORY_ITEM_ID,
                      RSF.EXCESS_INVENTORY_ITEM_ID =
                         CUR_REC.EXCESS_INVENTORY_ITEM_ID,
                      RSF.XREF_INVENTORY_ITEM_ID =
                         CUR_REC.XREF_INVENTORY_ITEM_ID,
                      RSF.COMMON_INVENTORY_ITEM_ID =
                         CUR_REC.COMMON_INVENTORY_ITEM_ID,
                      RSF.PID_LIFE_CYCLE =
                         CUR_REC.REFRESH_LIFE_CYCLE_NAME,
                      RSF.UNORDERED_FG = CUR_REC.UNORDERED_FG,
                      RSF.UNORDERED_RF_FG = CUR_REC.UNORDERED_RF_FG,
                      RSF.UNORDERED_WS_FG = CUR_REC.UNORDERED_WS_FG,
                      RSF.WS_NETTABLE_DGI_WITH_YIELD =
                         CUR_REC.WS_NETTABLE_DGI_WITH_YIELD,
                      RSF.POE_NETTABLE_DGI_WITH_YIELD =
                         CUR_REC.POE_NETTABLE_DGI_WITH_YIELD,
                      RSF.RF_NETTABLE_DGI_WITHOUT_YIELD =
                         CUR_REC.RF_NETTABLE_DGI_WITHOUT_YIELD,
                      RSF.WS_NETTABLE_DGI_WITHOUT_YIELD =
                         CUR_REC.WS_NETTABLE_DGI_WITHOUT_YIELD,
                      RSF.POE_NETTABLE_DGI_WITHOUT_YIELD =
                         CUR_REC.POE_NETTABLE_DGI_WITHOUT_YIELD,
                      RSF.NETTABLE_DGI = CUR_REC.NETTABLE_DGI,
                      RSF.TOTAL_NON_NETTABLE_PIPELINE =
                         CUR_REC.TOTAL_NON_NETTABLE_PIPELINE,
                      RSF.RF_NETTABLE_DGI_WITH_YIELD =
                         CUR_REC.RF_NETTABLE_DGI_WITH_YIELD,
                      RSF.TOTAL_NETTABLE_PIPELINE =
                         CUR_REC.TOTAL_NETTABLE_PIPELINE,
                      RSF.UPDATED_ON = SYSDATE,
                      RSF.EXCESS_LIFE_CYCLE = CUR_REC.EXCESS_LIFE_CYCLE,
                      RSF.REFRESH_LIFE_CYCLE = CUR_REC.REFRESH_LIFE_CYCLE,
                      RSF.MFG_EOS_DATE = CUR_REC.MFG_EOS_DATE
                WHERE (   EXCESS_INVENTORY_ITEM_ID =
                             CUR_REC.EXCESS_INVENTORY_ITEM_ID
                       OR RSF.EXCESS_PART_NUMBER = CUR_REC.EXCESS_PART_NUMBER);
            END IF;


            SELECT COUNT (*)
              INTO LV_COUNT
              FROM RC_SALES_FORECAST_STAGING
             WHERE    RETAIL_PART_NUMBER = CUR_REC.REFRESH_PART_NUMBER
                   OR EXCESS_PART_NUMBER = CUR_REC.EXCESS_PART_NUMBER
                   OR COMMON_PART_NUMBER = CUR_REC.COMMON_PART_NUMBER
                   OR XREF_PART_NUMBER = CUR_REC.XREF_PART_NUMBER;
            
            IF (LV_COUNT = 0)
                THEN
                insert into temp_var values('REF ='||CUR_REC.REFRESH_PART_NUMBER,sysdate);
                insert into temp_var values('EXC ='||CUR_REC.EXCESS_PART_NUMBER,sysdate);
                insert into temp_var values('COM ='||CUR_REC.COMMON_PART_NUMBER,sysdate);
                insert into temp_var values('XREF ='||CUR_REC.XREF_PART_NUMBER,sysdate);
                insert into temp_var values('XREF ='||CUR_REC.XREF_PART_NUMBER,sysdate);
                commit;
                
            END IF;
            
            IF (LV_COUNT = 0)
            THEN
               FOR IDX IN 1 .. lv_month_list.COUNT ()
               LOOP
                  INSERT
                    INTO RC_SALES_FORECAST_STAGING (
                            RETAIL_PART_NUMBER,
                            EXCESS_PART_NUMBER,
                            XREF_PART_NUMBER,
                            COMMON_PART_NUMBER,
                            REFRESH_INVENTORY_ITEM_ID,
                            EXCESS_INVENTORY_ITEM_ID,
                            COMMON_INVENTORY_ITEM_ID,
                            XREF_INVENTORY_ITEM_ID,
                            PID_LIFE_CYCLE,
                            UNORDERED_FG,
                            RF_NETTABLE_DGI_WITH_YIELD,
                            TOTAL_NETTABLE_PIPELINE,
                            UNORDERED_WS_FG,
                            UNORDERED_RF_FG,
                            RF_NETTABLE_DGI_WITHOUT_YIELD,
                            WS_NETTABLE_DGI_WITH_YIELD,
                            WS_NETTABLE_DGI_WITHOUT_YIELD,
                            POE_NETTABLE_DGI_WITH_YIELD,
                            POE_NETTABLE_DGI_WITHOUT_YIELD,
                            TOTAL_NON_NETTABLE_PIPELINE,
                            NETTABLE_DGI,
                            CREATED_ON,
                            EXCESS_LIFE_CYCLE,
                            REFRESH_LIFE_CYCLE,
                            MFG_EOS_DATE,
                            FORECAST_QUARTER,
                            FORECAST_MONTH,
                            FORECAST_YEAR)
                  VALUES (CUR_REC.REFRESH_PART_NUMBER,
                          CUR_REC.EXCESS_PART_NUMBER,
                          CUR_REC.XREF_PART_NUMBER,
                          CUR_REC.COMMON_PART_NUMBER,
                          CUR_REC.REFRESH_INVENTORY_ITEM_ID,
                          CUR_REC.EXCESS_INVENTORY_ITEM_ID,
                          CUR_REC.COMMON_INVENTORY_ITEM_ID,
                          CUR_REC.XREF_INVENTORY_ITEM_ID,
                          CUR_REC.REFRESH_LIFE_CYCLE_NAME,
                          CUR_REC.UNORDERED_FG,
                          CUR_REC.RF_NETTABLE_DGI_WITH_YIELD,
                          CUR_REC.TOTAL_NETTABLE_PIPELINE,
                          CUR_REC.UNORDERED_WS_FG,
                          CUR_REC.UNORDERED_RF_FG,
                          CUR_REC.RF_NETTABLE_DGI_WITHOUT_YIELD,
                          CUR_REC.WS_NETTABLE_DGI_WITH_YIELD,
                          CUR_REC.WS_NETTABLE_DGI_WITHOUT_YIELD,
                          CUR_REC.POE_NETTABLE_DGI_WITH_YIELD,
                          CUR_REC.POE_NETTABLE_DGI_WITHOUT_YIELD,
                          CUR_REC.TOTAL_NON_NETTABLE_PIPELINE,
                          CUR_REC.NETTABLE_DGI,
                          SYSDATE,
                          CUR_REC.EXCESS_LIFE_CYCLE,
                          CUR_REC.REFRESH_LIFE_CYCLE,
                          CUR_REC.MFG_EOS_DATE,
                          lv_month_list (IDX).FORECAST_QUARTER,
                          lv_month_list (IDX).FORECAST_MONTH,
                          lv_month_list (IDX).FORECAST_YEAR);
               END LOOP;
            END IF;

            COMMIT;
         END LOOP;

         COMMIT;
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
               'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_LOAD',
               'PACKAGE',
               NULL,
               'Y');
      END;

      UPDATE RC_SALES_FORECAST_STAGING SR
         SET (EXCESS_PART_NUMBER,
              EXCESS_INVENTORY_ITEM_ID,
              EXCESS_LIFE_CYCLE) =
                (SELECT PM.REFRESH_PART_NUMBER,
                        PM.REFRESH_INVENTORY_ITEM_ID,
                        PM.REFRESH_LIFE_CYCLE_NAME
                   FROM CRPADM.RC_PRODUCT_MASTER PM
                  WHERE     PM.COMMON_PART_NUMBER =
                               DECODE (
                                  SUBSTR (SR.COMMON_PART_NUMBER, -1, 1),
                                  '=', SUBSTR (
                                          SR.COMMON_PART_NUMBER,
                                          1,
                                          LENGTH (SR.COMMON_PART_NUMBER) - 1),
                                  SR.COMMON_PART_NUMBER || '=')
                        AND SR.EXCESS_PART_NUMBER IS NULL
                        AND REFRESH_LIFE_CYCLE_ID <> 6
                        AND PROGRAM_TYPE = 1)
       WHERE     SR.EXCESS_PART_NUMBER IS NULL
             AND EXISTS
                    (SELECT 1
                       FROM CRPADM.RC_PRODUCT_MASTER
                      WHERE     COMMON_PART_NUMBER =
                                   DECODE (
                                      SUBSTR (SR.COMMON_PART_NUMBER, -1, 1),
                                      '=', SUBSTR (
                                              SR.COMMON_PART_NUMBER,
                                              1,
                                                LENGTH (
                                                   SR.COMMON_PART_NUMBER)
                                              - 1),
                                      SR.COMMON_PART_NUMBER || '=')
                            AND SR.EXCESS_PART_NUMBER IS NULL
                            AND REFRESH_LIFE_CYCLE_ID <> 6
                            AND PROGRAM_TYPE = 1);

      UPDATE RC_SALES_FORECAST_STAGING SR
         SET (EXCESS_PART_NUMBER,
              EXCESS_INVENTORY_ITEM_ID,
              EXCESS_LIFE_CYCLE) =
                (SELECT REFRESH_PART_NUMBER,
                        REFRESH_INVENTORY_ITEM_ID,
                        REFRESH_LIFE_CYCLE_NAME
                   FROM CRPADM.RC_PRODUCT_MASTER
                  WHERE     COMMON_PART_NUMBER = SR.COMMON_PART_NUMBER
                        AND SR.EXCESS_PART_NUMBER IS NULL
                        AND REFRESH_LIFE_CYCLE_ID <> 6
                        AND PROGRAM_TYPE = 1
                        AND ROWNUM < 2)
       WHERE     EXCESS_PART_NUMBER IS NULL
             AND EXISTS
                    (SELECT 1
                       FROM CRPADM.RC_PRODUCT_MASTER
                      WHERE     COMMON_PART_NUMBER = SR.COMMON_PART_NUMBER
                            AND SR.EXCESS_PART_NUMBER IS NULL
                            AND REFRESH_LIFE_CYCLE_ID <> 6
                            AND PROGRAM_TYPE = 1);

      COMMIT;

      DELETE FROM RC_SALES_FORECAST_STAGING RSFS
            WHERE EXISTS
                     (SELECT 1
                        FROM CRPADM.RC_PRODUCT_MASTER RPM
                       WHERE     RPM.REFRESH_PART_NUMBER =
                                    NVL (RSFS.RETAIL_PART_NUMBER,
                                         RSFS.EXCESS_PART_NUMBER)
                             AND PROGRAM_TYPE IN (1, 0)
                             AND REFRESH_LIFE_CYCLE_ID IN (6));

      UPDATE RC_SALES_FORECAST_STAGING RSF
         SET (REFRESH_LIFE_CYCLE, MFG_EOS_DATE) =
                (SELECT REFRESH_LIFE_CYCLE_NAME, MFG_EOS_DATE
                   FROM CRPADM.RC_PRODUCT_MASTER RPM
                  WHERE RPM.REFRESH_PART_NUMBER = RSF.RETAIL_PART_NUMBER)
       WHERE EXISTS
                (SELECT 1
                   FROM CRPADM.RC_PRODUCT_MASTER RPM1
                  WHERE     PROGRAM_TYPE = 0
                        AND REFRESH_LIFE_CYCLE_ID IN (1, 5, 6)
                        AND RPM1.REFRESH_PART_NUMBER = RSF.RETAIL_PART_NUMBER);



      --      UPDATE RC_SALES_FORECAST_STAGING RSFS
      --         SET SALES_PRIORITY =
      --                NVL (
      --                   (SELECT SALES_PRIORITY
      --                      FROM RC_SALES_FORECAST RSF
      --                     WHERE RSFS.COMMON_INVENTORY_ITEM_ID =
      --                              RSF.COMMON_INVENTORY_ITEM_ID),
      --                   NULL),
      --             RF_90DAY_FORECAST =
      --                NVL (
      --                   (SELECT RF_90DAY_FORECAST
      --                      FROM RC_SALES_FORECAST RSF
      --                     WHERE RSFS.COMMON_INVENTORY_ITEM_ID =
      --                              RSF.COMMON_INVENTORY_ITEM_ID),
      --                   NULL),
      --             WS_90DAY_FORECAST =
      --                NVL (
      --                   (SELECT WS_90DAY_FORECAST
      --                      FROM RC_SALES_FORECAST RSF
      --                     WHERE RSFS.COMMON_INVENTORY_ITEM_ID =
      --                              RSF.COMMON_INVENTORY_ITEM_ID),
      --                   NULL);


      --      UPDATE RC_SALES_FORECAST SF
      --         SET SF.PID_PRIORITY =
      --                (SELECT CALCULATED_PRIORITY
      --                   FROM CRPSC.RC_CALCULATED_PRIORITIES CP
      --                  WHERE SF.RETAIL_PART_NUMBER = CP.RETAIL_PART_NUMBER);
      --
      --      UPDATE RC_SALES_FORECAST SF
      --         SET SF.PID_PRIORITY =
      --                (SELECT CALCULATED_PRIORITY
      --                   FROM CRPSC.RC_CALCULATED_PRIORITIES CP
      --                  WHERE CP.RETAIL_PART_NUMBER = SF.EXCESS_PART_NUMBER)
      --       WHERE SF.PID_PRIORITY IS NULL;

      UPDATE RC_SALES_FORECAST_STAGING RSFS
         SET FORECASTING_PRIORITY =
                CONCAT (
                   NVL (
                      (SELECT MIN (PRIORITY)
                         FROM CRPSC.RC_FORECASTING_CUMULATIVE RFC
                        WHERE     RFC.REFRESH_PART_NUMBER =
                                     RSFS.RETAIL_PART_NUMBER
                              AND THEATER_NAME = 'NAM'),
                      'X'),
                   NVL (
                      (SELECT MIN (PRIORITY)
                         FROM CRPSC.RC_FORECASTING_CUMULATIVE RFC
                        WHERE     RFC.REFRESH_PART_NUMBER =
                                     RSFS.RETAIL_PART_NUMBER
                              AND THEATER_NAME = 'EMEA'),
                      'X'));

      INSERT INTO CRPADM.RC_PROCESS_LOG
           VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                   'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_LOAD',
                   'SALES STAGING TABLE LOADED',
                   SYSDATE);

      COMMIT;

      --CALL TO MAINTAIN HISTORY FOR THE SALES FORECAST DAILY @ 3AM & 3PM.

      SELECT TO_CHAR (SYSDATE, 'HH') INTO LV_HOURS FROM DUAL;

      IF LV_HOURS = '3'
      THEN
         CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_HISTORY (NULL);

         INSERT INTO CRPADM.RC_PROCESS_LOG
                 VALUES (
                           CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                           'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_LOAD',
                           'SALES HISTORY TABLES UPDATED',
                           SYSDATE);

         COMMIT;
      END IF;

      --CALL TO UPDATE SALES VIEW DATA IN THE STAGING TABLE
      CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_ONUPLOAD (NULL,
                                                                  NULL,
                                                                  NULL);

      INSERT INTO CRPADM.RC_PROCESS_LOG
           VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                   'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_LOAD',
                   'SALES STAGING TABLE LOADED',
                   SYSDATE);

      COMMIT;

      --CALL TO UPDATE SALES FORECAST MAIN TABLE
      CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_UPDATE;

      INSERT INTO CRPADM.RC_PROCESS_LOG
           VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                   'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_LOAD',
                   'SALES VIEW MAIN UPDATED',
                   SYSDATE);

      COMMIT;

      INSERT INTO CRPADM.RC_PROCESS_LOG
           VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                   'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_LOAD',
                   'END',
                   SYSDATE);

      COMMIT;
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
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_LOAD',
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
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_LOAD',
            'PACKAGE',
            NULL,
            'Y');
   END;

   --PROCEDURE TO UPDATE SALES VIEW DATA OF STAGING TABLE ON COMPLETION OF UPLOAD FROM SALES FORECAST GU

   PROCEDURE RC_SALES_FORECAST_ONUPLOAD (I_FORECAST_QUARTER   IN VARCHAR2,
                                         I_FORECAST_MONTH     IN VARCHAR2,
                                         I_FORECAST_YEAR      IN VARCHAR2)
   IS
      LV_FORECAST_QUARTER       VARCHAR2 (100);
      LV_FORECAST_MONTH         VARCHAR2 (100);
      LV_FORECAST_YEAR          VARCHAR2 (100);
      LV_CLAUSE_QUERY           VARCHAR2 (1000);
      LV_QUERY                  CLOB;
      LV_QUERY1                 CLOB;
      LV_PUBLISH_CLAUSE_QUERY   CLOB;
      LV_IS_ADJUSTED            VARCHAR2 (100);
      LV_IS_PUBLISHED           VARCHAR2 (100);

      TYPE MONTH_OBJECT IS RECORD
      (
         FORECAST_QUARTER   VARCHAR2 (200 BYTE),
         FORECAST_MONTH     VARCHAR2 (200 BYTE),
         FORECAST_YEAR      VARCHAR2 (200 BYTE)
      );

      TYPE MONTH_LIST IS TABLE OF MONTH_OBJECT;

      lv_month_list             MONTH_LIST := MONTH_LIST ();
   BEGIN
      INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (
                        CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                        'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_ONUPLOAD',
                        'START',
                        SYSDATE);


      LV_FORECAST_QUARTER := I_FORECAST_QUARTER;
      LV_FORECAST_MONTH := I_FORECAST_MONTH;
      LV_FORECAST_YEAR := I_FORECAST_YEAR;

      LV_CLAUSE_QUERY := ' WHERE 1=1 ';

      IF (    LV_FORECAST_QUARTER IS NOT NULL
          AND LV_FORECAST_MONTH IS NOT NULL
          AND LV_FORECAST_YEAR IS NOT NULL)
      THEN
         LV_CLAUSE_QUERY :=
               LV_CLAUSE_QUERY
            || ' AND FORECAST_YEAR='''
            || LV_FORECAST_YEAR
            || ''' AND FORECAST_MONTH='''
            || LV_FORECAST_MONTH
            || ''' AND FORECAST_QUARTER='''
            || LV_FORECAST_QUARTER
            || '''';
      END IF;

      LV_PUBLISH_CLAUSE_QUERY :=
         ' AND (FORECAST_QUARTER, FORECAST_MONTH, FORECAST_YEAR) IN (SELECT DISTINCT
                                                                        FORECAST_QUARTER,
                                                                        FORECAST_MONTH,
                                                                        FORECAST_YEAR
                                                                   FROM RC_SALES_FORECAST_CONFIG
                                                                  WHERE IS_PUBLISHED =
                                                                           ''Y'')';



      LV_QUERY :=
            'UPDATE RC_SALES_FORECAST_STAGING RSF
      SET ASP_RF =
             (CASE
                 WHEN NVL (
                         CRPREP.GET_AVG_SALES_PRICE (
                            RSF.REFRESH_INVENTORY_ITEM_ID,
                            ''RETAIL'',
                            ''Y''),
                         0) > 0
                 THEN
                    CRPREP.GET_AVG_SALES_PRICE (
                       RSF.REFRESH_INVENTORY_ITEM_ID,
                       ''RETAIL'',
                       ''Y'')
                 WHEN (    RSF.RETAIL_PART_NUMBER IS NOT NULL
                       AND NVL (
                              (SELECT ASP_RF
                                 FROM CRPREP.RC_SCRAP_REPORT RSP
                                WHERE RSF.RETAIL_PART_NUMBER =
                                         RSP.RETAIL_PART_NUMBER),
                              0) > 0)
                 THEN
                    (SELECT ASP_RF
                       FROM CRPREP.RC_SCRAP_REPORT RSP
                      WHERE RSF.RETAIL_PART_NUMBER = RSP.RETAIL_PART_NUMBER)
                 WHEN (    RSF.RETAIL_PART_NUMBER IS NOT NULL
                       AND NVL (
                              (SELECT GPL
                                 FROM CRPREP.RC_SCRAP_REPORT RSP
                                WHERE RSF.RETAIL_PART_NUMBER =
                                         RSP.RETAIL_PART_NUMBER),
                              0) > 0)
                 THEN
                    CEIL (
                         (SELECT GPL
                            FROM CRPREP.RC_SCRAP_REPORT RSP
                           WHERE RSF.RETAIL_PART_NUMBER =
                                    RSP.RETAIL_PART_NUMBER)
                       * 0.35)
                 ELSE
                    0
              END),
          ASP_WS =
             (CASE
                 WHEN NVL (
                         CRPREP.GET_AVG_SALES_PRICE (
                            RSF.EXCESS_INVENTORY_ITEM_ID,
                            ''EXCESS'',
                            ''Y''),
                         0) > 0
                 THEN
                    CRPREP.GET_AVG_SALES_PRICE (RSF.EXCESS_INVENTORY_ITEM_ID,
                                                ''EXCESS'',
                                                ''Y'')
                 WHEN (    RSF.EXCESS_PART_NUMBER IS NOT NULL
                       AND NVL (
                              (SELECT GPL
                                 FROM CRPREP.RC_SCRAP_REPORT RSP
                                WHERE RSF.EXCESS_PART_NUMBER =
                                         RSP.EXCESS_PART_NUMBER),
                              0) > 0)
                 THEN
                    CEIL (
                         (SELECT GPL
                            FROM CRPREP.RC_SCRAP_REPORT RSP
                           WHERE RSF.EXCESS_PART_NUMBER =
                                    RSP.EXCESS_PART_NUMBER)
                       * 0.15)
                 ELSE
                    0
              END),
          ASP_OUTLET =
             (CASE
                 WHEN NVL (
                         CRPREP.GET_AVG_SALES_PRICE (
                            RSF.REFRESH_INVENTORY_ITEM_ID,
                            ''OUTLET'',
                            ''Y''),
                         0) > 0
                 THEN
                    CRPREP.GET_AVG_SALES_PRICE (
                       RSF.REFRESH_INVENTORY_ITEM_ID,
                       ''OUTLET'',
                       ''Y'')
                 WHEN (    RSF.RETAIL_PART_NUMBER IS NOT NULL
                       AND NVL (
                              (SELECT GPL
                                 FROM CRPREP.RC_SCRAP_REPORT RSP
                                WHERE RSF.RETAIL_PART_NUMBER =
                                         RSP.RETAIL_PART_NUMBER),
                              0) > 0)
                 THEN
                    CEIL (
                         (SELECT GPL
                            FROM CRPREP.RC_SCRAP_REPORT RSP
                           WHERE RSF.RETAIL_PART_NUMBER =
                                    RSP.RETAIL_PART_NUMBER)
                       * 0.10)
                 ELSE
                    0
              END),
             
          SALES_RF_ALLOCATION =
             NVL (
                LEAST (
                   GREATEST (
                      (  NVL (
                            (SELECT SUM (
                                         (QTY_ON_HAND)
                                       - ABS (TOTAL_RESERVATIONS))
                               FROM CRPADM.RC_INV_BTS_C3_MV
                              WHERE     LOCATION = ''FG'' -- Considering only BTS FG locations
                                    AND PROGRAM_TYPE = ''RETAIL''
                                    AND PART_NUMBER = RSF.RETAIL_PART_NUMBER
                                    AND SITE NOT LIKE ''Z32%''),
                            0)
                       + FLOOR (
                            NVL (
                               (SELECT SUM (RF_QTY_AFTER_YIELD)
                                  FROM CRPADM.RC_INV_BTS_C3_MV
                                 WHERE     (    LOCATION <> ''FG''
      AND LOCATION IN (SELECT MSTR.SUB_INVENTORY_LOCATION
                         FROM CRPADM.RC_SUB_INV_LOC_MSTR MSTR
                        --INNER JOIN
                        --CRPADM.RC_SUB_INV_LOC_FLG_DTLS
                        --FLG
                        --    ON   MSTR.SUB_INVENTORY_ID =
                        --         FLG.SUB_INVENTORY_ID
                        --      MSTR.INVENTORY_TYPE =
                        --             1
                        WHERE     MSTR.NETTABLE_FLAG = 1
                              AND MSTR.PROGRAM_TYPE = 0))
                                       AND (   PART_NUMBER =
                                                  RSF.RETAIL_PART_NUMBER
                                            OR PART_NUMBER =
                                                  RSF.COMMON_PART_NUMBER
                                            OR PART_NUMBER =
                                                  RSF.XREF_PART_NUMBER)
                                       AND SITE NOT LIKE ''Z32%''),
                               0))
                       - NVL (
                            (SELECT ABS (SUM (TOTAL_RESERVATIONS))
                               FROM CRPADM.RC_INV_BTS_C3_MV
                              WHERE     SITE = ''GDGI''
                                    AND PART_NUMBER = RSF.RETAIL_PART_NUMBER
                                    AND SITE NOT LIKE ''Z32%''),
                            0)),
                      0),
                    (NVL ( NVL ( RF_ADJ_OVERRIDDEN_FORECAST, RF_ADJUSTED_FORECAST ), RF_90DAY_FORECAST ))),
                0),
          SALES_WS_ALLOCATION =
             NVL (
                LEAST (
                   GREATEST (
                      (  NVL (
                            (SELECT SUM (
                                         (QTY_ON_HAND)
                                       - ABS (TOTAL_RESERVATIONS))
                               FROM CRPADM.RC_INV_BTS_C3_MV
                              WHERE     LOCATION = ''FG'' -- Considering only BTS FG locations
                                    AND PROGRAM_TYPE = ''EXCESS''
                                    AND PART_NUMBER = RSF.EXCESS_PART_NUMBER
                                    AND SITE NOT LIKE ''Z32%''),
                            0)
                       + FLOOR (
                            NVL (
                               (SELECT SUM (WS_QTY_AFTER_YIELD)
                                  FROM CRPADM.RC_INV_BTS_C3_MV
                                 WHERE     (    LOCATION <> ''FG''
                                            AND LOCATION IN (SELECT MSTR.SUB_INVENTORY_LOCATION
                                                               FROM CRPADM.RC_SUB_INV_LOC_MSTR MSTR
                                                              /* INNER JOIN
                                                               CRPADM.RC_SUB_INV_LOC_FLG_DTLS
                                                               FLG
                                                                  ON     MSTR.SUB_INVENTORY_ID =
                                                                            FLG.SUB_INVENTORY_ID
                                                                     AND MSTR.INVENTORY_TYPE =
                                                                            1*/
                                                              WHERE     MSTR.NETTABLE_FLAG =
                                                                           1
                                                                    AND MSTR.PROGRAM_TYPE =
                                                                           1))
                                       AND (   PART_NUMBER =
                                                  RSF.EXCESS_PART_NUMBER
                                            OR PART_NUMBER =
                                                  RSF.COMMON_PART_NUMBER
                                            OR PART_NUMBER =
                                                  RSF.XREF_PART_NUMBER)
                                       AND SITE NOT LIKE ''Z32%''),
                               0))
                       - NVL (
                            (SELECT ABS (SUM (TOTAL_RESERVATIONS))
                               FROM CRPADM.RC_INV_BTS_C3_MV
                              WHERE     SITE = ''GDGI''
                                    AND PART_NUMBER = RSF.EXCESS_PART_NUMBER
                                    AND SITE NOT LIKE ''Z32%''),
                            0)),
                      0),
                   (NVL (WS_ADJUSTED_FORECAST, WS_90DAY_FORECAST))),
                0)'
         || LV_CLAUSE_QUERY;

      EXECUTE IMMEDIATE LV_QUERY;



      --        UPDATE RC_SALES_FORECAST RSF
      LV_QUERY :=
            'UPDATE RC_SALES_FORECAST_STAGING RSF
      SET TOTAL_RF_ALLOCATION=
             NVL ( (SELECT RF_COUNTER
                      FROM CRPSC.RC_AE_FGI_REQUIREMENT AFR
                     WHERE AFR.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER),
                  0),
      RF_FG_ALLOCATION=NVL((SELECT COUNT (*)
                FROM CRPSC.RC_ALLOCATION_DETAILS ALLOC
                WHERE LOC_TO IN (SELECT MSTR.SUB_INVENTORY_LOCATION
                                FROM CRPADM.RC_SUB_INV_LOC_MSTR MSTR
                                WHERE     MSTR.INVENTORY_TYPE = 0
                                    AND MSTR.NETTABLE_FLAG = 1
                                    AND MSTR.PROGRAM_TYPE IN (0)) 
                AND (RSF.COMMON_PART_NUMBER=ALLOC.PRODUCT_NAME OR RSF.XREF_PART_NUMBER=ALLOC.PRODUCT_NAME)),0),
      RF_DGI_ALLOCATION=NVL((SELECT COUNT (*)
                FROM CRPSC.RC_ALLOCATION_DETAILS ALLOC
                WHERE LOC_TO IN (SELECT MSTR.SUB_INVENTORY_LOCATION
                                FROM CRPADM.RC_SUB_INV_LOC_MSTR MSTR
                                WHERE     MSTR.INVENTORY_TYPE = 1
                                    AND MSTR.NETTABLE_FLAG = 1
                                    AND MSTR.PROGRAM_TYPE IN (0)) 
                AND (RSF.COMMON_PART_NUMBER=ALLOC.PRODUCT_NAME OR RSF.XREF_PART_NUMBER=ALLOC.PRODUCT_NAME)),0),          
          WS_ALLOCATION =
             NVL ( (SELECT WS_COUNTER
                      FROM CRPSC.RC_AE_FGI_REQUIREMENT AFR
                     WHERE AFR.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER),
                  0),
          OUTLET_ALLOCATION =
             NVL ( (SELECT OUTLET_ALLOC_QUANTITY
                      FROM CRPSC.RC_AE_FGI_REQUIREMENT AFR
                     WHERE AFR.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER),
                  0),
          PIPELINE_NOT_ALLOCATED =
             NVL ( (SELECT SUM (QTY_ON_HAND)
             FROM CRPADM.RC_INV_BTS_C3_MV INV
            WHERE     (LOCATION IN (SELECT MSTR.SUB_INVENTORY_LOCATION
                                      FROM CRPADM.RC_SUB_INV_LOC_MSTR MSTR
                                     WHERE     MSTR.INVENTORY_TYPE = 1
                                           AND MSTR.NETTABLE_FLAG = 1
                                           AND MSTR.PROGRAM_TYPE IN (0, 1, 2)))
                  AND (   PART_NUMBER = RSF.RETAIL_PART_NUMBER
                       OR PART_NUMBER = RSF.EXCESS_PART_NUMBER
                       OR PART_NUMBER = RSF.COMMON_PART_NUMBER
                       OR PART_NUMBER = RSF.XREF_PART_NUMBER)
                  AND NOT EXISTS
                             (SELECT *
                                FROM CRPADM.RC_PRODUCT_REPAIR_SETUP RS,
                                     CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                               WHERE     1 = 1
                                     AND RS.REFRESH_METHOD_ID IN (SELECT DTLS.REFRESH_METHOD_ID
                                                                    FROM CRPADM.RC_SUB_INV_LOC_MSTR MSTR,
                                                                         CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                                                                   WHERE     MSTR.SUB_INVENTORY_ID =
                                                                                DTLS.SUB_INVENTORY_ID
                                                                         AND MSTR.SUB_INVENTORY_LOCATION =
                                                                                INV.LOCATION)
                                     AND RS.REFRESH_INVENTORY_ITEM_ID IN (RSF.REFRESH_INVENTORY_ITEM_ID,
                                                                          RSF.EXCESS_INVENTORY_ITEM_ID,
                                                                          RSF.COMMON_INVENTORY_ITEM_ID,
                                                                          RSF.XREF_INVENTORY_ITEM_ID)
                                     AND RS.REPAIR_PARTNER_ID =
                                            RP.REPAIR_PARTNER_ID
                                     AND RS.REFRESH_STATUS = ''ACTIVE''
                                     AND RP.ACTIVE_FLAG = ''Y'')
                  AND SITE NOT LIKE ''Z32%''),
                  0),
          RF_ALLOCATED_FROM_DAY0 =
             NVL ( (SELECT RF_COUNTER
                      FROM CRPSC.RC_AE_FGI_REQUIREMENT AFR
                     WHERE AFR.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER),
                  0),
          WS_ALLOCATED_FROM_DAY0 =
             NVL ( (SELECT WS_COUNTER
                      FROM CRPSC.RC_AE_FGI_REQUIREMENT AFR
                     WHERE AFR.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER),
                  0)'
         || LV_CLAUSE_QUERY
         || LV_PUBLISH_CLAUSE_QUERY;



      --      INSERT INTO temp_query
      --           VALUES (LV_QUERY, SYSDATE);

      BEGIN
         SELECT DISTINCT FORECAST_QUARTER, FORECAST_MONTH, FORECAST_YEAR
           BULK COLLECT INTO lv_month_list
           FROM RC_SALES_FORECAST_STAGING;
      EXCEPTION
         WHEN OTHERS
         THEN
            SELECT FISCAL_QUARTER_NAME FORECAST_QUARTER,
                   'M' || RNUM         AS FORECAST_MONTH,
                   FISCAL_YEAR_NUMBER  FORECAST_YEAR
              BULK COLLECT INTO lv_month_list
              FROM (SELECT *
                      FROM (SELECT FISCAL_QUARTER_NAME,
                                   FISCAL_MONTH_ID,
                                   FISCAL_YEAR_NUMBER,
                                   ROWNUM RNUM
                              FROM (  SELECT DISTINCT
                                             FISCAL_QUARTER_NAME,
                                             FISCAL_MONTH_ID,
                                             FISCAL_YEAR_NUMBER
                                        FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                                       WHERE CURRENT_FISCAL_QUARTER_FLAG = 'Y'
                                    ORDER BY 2))
                     WHERE FISCAL_MONTH_ID =
                              (SELECT FISCAL_MONTH_ID
                                 FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                                WHERE CALENDAR_DATE = TRUNC (SYSDATE)));
      END;

      FOR IDX IN 1 .. lv_month_list.COUNT ()
      LOOP
         SELECT NVL (IS_ADJUSTED, 'N'), NVL (IS_PUBLISHED, 'N')
           INTO LV_IS_ADJUSTED, LV_IS_PUBLISHED
           FROM RC_SALES_FORECAST_CONFIG
          WHERE     FORECAST_QUARTER = lv_month_list (IDX).FORECAST_QUARTER
                AND FORECAST_MONTH = lv_month_list (IDX).FORECAST_MONTH
                AND FORECAST_YEAR = lv_month_list (IDX).FORECAST_YEAR;

         IF (LV_IS_PUBLISHED = 'N')
         THEN
            CASE
               WHEN LV_IS_ADJUSTED = 'Y'
               THEN
                  UPDATE RC_SALES_FORECAST_STAGING RSF
                     SET OUTLET_ALLOCATION = RSF.OUTLET_ALLOCATION
                   WHERE     FORECAST_QUARTER =
                                lv_month_list (IDX).FORECAST_QUARTER
                         AND FORECAST_MONTH =
                                lv_month_list (IDX).FORECAST_MONTH
                         AND FORECAST_YEAR =
                                lv_month_list (IDX).FORECAST_YEAR;

                  COMMIT;
               ELSE
                  UPDATE RC_SALES_FORECAST_STAGING RSF
                     SET OUTLET_ALLOCATION = 0
                   WHERE     FORECAST_QUARTER =
                                lv_month_list (IDX).FORECAST_QUARTER
                         AND FORECAST_MONTH =
                                lv_month_list (IDX).FORECAST_MONTH
                         AND FORECAST_YEAR =
                                lv_month_list (IDX).FORECAST_YEAR;

                  COMMIT;
            END CASE;
         END IF;
      END LOOP;


      EXECUTE IMMEDIATE LV_QUERY;

      LV_QUERY :=
         'UPDATE RC_SALES_FORECAST_STAGING RSF
   SET TOTAL_RF_ALLOCATION= 0,
       RF_FG_ALLOCATION=0,
       RF_DGI_ALLOCATION=0,
       WS_ALLOCATION = 0,
       PIPELINE_NOT_ALLOCATED = 0,
       RF_ALLOCATED_FROM_DAY0 = 0,
       WS_ALLOCATED_FROM_DAY0 = 0
 WHERE     1 = 1
       AND (FORECAST_QUARTER, FORECAST_MONTH, FORECAST_YEAR) IN (SELECT DISTINCT
                                                                        FORECAST_QUARTER,
                                                                        FORECAST_MONTH,
                                                                        FORECAST_YEAR
                                                                   FROM RC_SALES_FORECAST_CONFIG
                                                                  WHERE IS_PUBLISHED =
                                                                           ''N'')';

      EXECUTE IMMEDIATE LV_QUERY;

      LV_QUERY1 :=
            'UPDATE RC_SALES_FORECAST_STAGING
   SET EXPECTED_REVENUE_RF =
          NVL ( (NVL (ASP_RF, 0) * NVL (TOTAL_RF_ALLOCATION, 0)), 0),
       EXPECTED_REVENUE_WS =
          NVL ( (NVL (ASP_WS, 0) * NVL (WS_ALLOCATION, 0)), 0),
       EXPECTED_REVENUE_OUTLET =
          NVL ( (NVL (ASP_OUTLET, 0) * NVL (OUTLET_ALLOCATION, 0)), 0),
       FORECASTED_REVENUE =
          (  NVL (NVL ((NVL ( NVL ( RF_ADJ_OVERRIDDEN_FORECAST, RF_ADJUSTED_FORECAST ), RF_90DAY_FORECAST )), 0) * NVL (ASP_RF, 0), 0)
           + NVL (NVL ((NVL (WS_ADJUSTED_FORECAST, WS_90DAY_FORECAST)), 0) * NVL (ASP_WS, 0), 0)),
       EXPECTED_SALES_REVENUE_RF =
          NVL ( (NVL (ASP_RF, 0) * NVL (SALES_RF_ALLOCATION, 0)), 0),
       EXPECTED_SALES_REVENUE_WS =
          NVL ( (NVL (ASP_WS, 0) * NVL (SALES_WS_ALLOCATION, 0)), 0),
       EXPECTED_SALES_REVENUE_OUTLET =
          NVL ( (NVL (ASP_OUTLET, 0) * NVL (OUTLET_ALLOCATION, 0)), 0)'
         || LV_CLAUSE_QUERY;

      EXECUTE IMMEDIATE LV_QUERY1;

      COMMIT;


      --CALL TO UPSERT HISTORY FOR THE SALES FORECAST DETAILS
      --CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_HISTORY;

      -- Upsert Financial summary staging table

      FOR IDX IN 1 .. lv_month_list.COUNT ()
      LOOP
         MERGE INTO CRPADM.RC_SALES_FORECAST_STG_FINSUM FINSUM
              USING (SELECT EXPECTED_REVENUE_RF,
                            EXPECTED_REVENUE_WS,
                            EXPECTED_REVENUE_OUTLET,
                            EXPECTED_REPAIR_COST,
                            RF_FORECASTED_REPAIR_COST,
                            WS_FORECASTED_REPAIR_COST,
                            OUTLET_FORECASTED_REPAIR_COST,
                            FORECASTED_REPAIR_COST,
                            UPLOADED_ON,
                            EXPECTED_SALES_REVENUE_RF,
                            EXPECTED_SALES_REVENUE_WS,
                            EXPECTED_SALES_REVENUE_OUTLET,
                            TOTL_EXPCTD_SALES_REPAIR_COST,
                            (SELECT DISTINCT FORECAST_QUARTER
                               FROM RC_SALES_FORECAST_STAGING
                              WHERE     FORECAST_QUARTER =
                                           lv_month_list (IDX).FORECAST_QUARTER
                                    AND FORECAST_MONTH =
                                           lv_month_list (IDX).FORECAST_MONTH
                                    AND FORECAST_YEAR =
                                           lv_month_list (IDX).FORECAST_YEAR)
                               AS FORECAST_QUARTER,
                            (SELECT DISTINCT FORECAST_MONTH
                               FROM RC_SALES_FORECAST_STAGING
                              WHERE     FORECAST_QUARTER =
                                           lv_month_list (IDX).FORECAST_QUARTER
                                    AND FORECAST_MONTH =
                                           lv_month_list (IDX).FORECAST_MONTH
                                    AND FORECAST_YEAR =
                                           lv_month_list (IDX).FORECAST_YEAR)
                               AS FORECAST_MONTH,
                            (SELECT DISTINCT FORECAST_YEAR
                               FROM RC_SALES_FORECAST_STAGING
                              WHERE     FORECAST_QUARTER =
                                           lv_month_list (IDX).FORECAST_QUARTER
                                    AND FORECAST_MONTH =
                                           lv_month_list (IDX).FORECAST_MONTH
                                    AND FORECAST_YEAR =
                                           lv_month_list (IDX).FORECAST_YEAR)
                               AS FORECAST_YEAR
                       FROM (SELECT SUM (NVL (EXPECTED_REVENUE_RF, 0))
                                       AS EXPECTED_REVENUE_RF,
                                    SUM (NVL (EXPECTED_REVENUE_WS, 0))
                                       AS EXPECTED_REVENUE_WS,
                                    SUM (NVL (EXPECTED_REVENUE_OUTLET, 0))
                                       AS EXPECTED_REVENUE_OUTLET,
                                    SUM (NVL (TOTAL_EXPECTED_REPAIR_COST, 0))
                                       AS EXPECTED_REPAIR_COST,
                                    SUM (
                                       NVL (
                                            (NVL (
                                                NVL (
                                                   RF_ADJ_OVERRIDDEN_FORECAST,
                                                   RF_ADJUSTED_FORECAST),
                                                RF_90DAY_FORECAST))
                                          * ASP_RF,
                                          0))
                                       AS RF_FORECASTED_REPAIR_COST,
                                    SUM (
                                       NVL (
                                            (NVL (WS_ADJUSTED_FORECAST,
                                                  WS_90DAY_FORECAST))
                                          * ASP_WS,
                                          0))
                                       AS WS_FORECASTED_REPAIR_COST,
                                    0 AS OUTLET_FORECASTED_REPAIR_COST,
                                    SUM (
                                       NVL (TOTAL_FORECASTED_REPAIR_COST, 0))
                                       AS FORECASTED_REPAIR_COST,
                                    NVL (MAX (UPDATED_ON), MAX (CREATED_ON))
                                       AS UPLOADED_ON,
                                    SUM (NVL (EXPECTED_SALES_REVENUE_RF, 0))
                                       AS EXPECTED_SALES_REVENUE_RF,
                                    SUM (
                                       NVL (EXPECTED_SALES_REVENUE_OUTLET, 0))
                                       AS EXPECTED_SALES_REVENUE_OUTLET,
                                    SUM (NVL (EXPECTED_SALES_REVENUE_WS, 0))
                                       AS EXPECTED_SALES_REVENUE_WS,
                                    SUM (
                                       NVL (TOTL_EXPCTD_SALES_REPAIR_COST, 0))
                                       AS TOTL_EXPCTD_SALES_REPAIR_COST
                               FROM RC_SALES_FORECAST_STAGING
                              WHERE     FORECAST_QUARTER =
                                           lv_month_list (IDX).FORECAST_QUARTER
                                    AND FORECAST_MONTH =
                                           lv_month_list (IDX).FORECAST_MONTH
                                    AND FORECAST_YEAR =
                                           lv_month_list (IDX).FORECAST_YEAR))
                    IFINSUM
                 ON (    IFINSUM.FORECAST_QUARTER = FINSUM.FORECAST_QUARTER
                     AND IFINSUM.FORECAST_MONTH = FINSUM.FORECAST_MONTH
                     AND IFINSUM.FORECAST_MONTH = FINSUM.FORECAST_MONTH)
         WHEN MATCHED
         THEN
            UPDATE SET
               FINSUM.EXPECTED_REVENUE_RF = IFINSUM.EXPECTED_REVENUE_RF,
               FINSUM.EXPECTED_REVENUE_WS = IFINSUM.EXPECTED_REVENUE_WS,
               FINSUM.EXPECTED_REVENUE_OUTLET =
                  IFINSUM.EXPECTED_REVENUE_OUTLET,
               FINSUM.EXPECTED_REPAIR_COST = IFINSUM.EXPECTED_REPAIR_COST,
               FINSUM.RF_FORECASTED_REPAIR_COST =
                  IFINSUM.RF_FORECASTED_REPAIR_COST,
               FINSUM.WS_FORECASTED_REPAIR_COST =
                  IFINSUM.WS_FORECASTED_REPAIR_COST,
               FINSUM.OUTLET_FORECASTED_REPAIR_COST =
                  IFINSUM.OUTLET_FORECASTED_REPAIR_COST,
               FINSUM.FORECASTED_REPAIR_COST = IFINSUM.FORECASTED_REPAIR_COST,
               FINSUM.UPLOADED_ON = IFINSUM.UPLOADED_ON,
               FINSUM.EXPECTED_SALES_REVENUE_RF =
                  IFINSUM.EXPECTED_SALES_REVENUE_RF,
               FINSUM.EXPECTED_SALES_REVENUE_WS =
                  IFINSUM.EXPECTED_SALES_REVENUE_WS,
               FINSUM.EXPECTED_SALES_REVENUE_OUTLET =
                  IFINSUM.EXPECTED_SALES_REVENUE_OUTLET,
               FINSUM.TOTL_EXPCTD_SALES_REPAIR_COST =
                  IFINSUM.TOTL_EXPCTD_SALES_REPAIR_COST
         WHEN NOT MATCHED
         THEN
            INSERT     (EXPECTED_REVENUE_RF,
                        EXPECTED_REVENUE_WS,
                        EXPECTED_REVENUE_OUTLET,
                        EXPECTED_REPAIR_COST,
                        RF_FORECASTED_REPAIR_COST,
                        WS_FORECASTED_REPAIR_COST,
                        OUTLET_FORECASTED_REPAIR_COST,
                        FORECASTED_REPAIR_COST,
                        UPLOADED_ON,
                        EXPECTED_SALES_REVENUE_RF,
                        EXPECTED_SALES_REVENUE_WS,
                        EXPECTED_SALES_REVENUE_OUTLET,
                        TOTL_EXPCTD_SALES_REPAIR_COST,
                        FORECAST_QUARTER,
                        FORECAST_MONTH,
                        FORECAST_YEAR)
                VALUES (IFINSUM.EXPECTED_REVENUE_RF,
                        IFINSUM.EXPECTED_REVENUE_WS,
                        IFINSUM.EXPECTED_REVENUE_OUTLET,
                        IFINSUM.EXPECTED_REPAIR_COST,
                        IFINSUM.RF_FORECASTED_REPAIR_COST,
                        IFINSUM.WS_FORECASTED_REPAIR_COST,
                        IFINSUM.OUTLET_FORECASTED_REPAIR_COST,
                        IFINSUM.FORECASTED_REPAIR_COST,
                        IFINSUM.UPLOADED_ON,
                        IFINSUM.EXPECTED_SALES_REVENUE_RF,
                        IFINSUM.EXPECTED_SALES_REVENUE_WS,
                        IFINSUM.EXPECTED_SALES_REVENUE_OUTLET,
                        IFINSUM.TOTL_EXPCTD_SALES_REPAIR_COST,
                        IFINSUM.FORECAST_QUARTER,
                        IFINSUM.FORECAST_MONTH,
                        IFINSUM.FORECAST_YEAR);

         COMMIT;
      END LOOP;


      INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (
                        CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                        'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_ONUPLOAD',
                        'END',
                        SYSDATE);
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
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_ONUPLOAD',
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
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_ONUPLOAD',
            'PACKAGE',
            NULL,
            'Y');
   END;


   --PROCEDURE TO UPDATE INVENTORY & REVENUE DATA OF MAIN TABLE

   PROCEDURE RC_SALES_FORECAST_UPDATE
   IS
      L_HOURS               NUMBER (2);
      lv_forecast_quarter   VARCHAR2 (10 BYTE);
      lv_forecast_month     VARCHAR2 (10 BYTE);
      lv_forecast_year      VARCHAR2 (10 BYTE);
   BEGIN
      INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (
                        CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                        'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_UPDATE',
                        'START',
                        SYSDATE);

      COMMIT;

      BEGIN
         SELECT DISTINCT FORECAST_QUARTER, FORECAST_MONTH, FORECAST_YEAR
           INTO lv_forecast_quarter, lv_forecast_month, lv_forecast_year
           FROM RC_SALES_FORECAST;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_forecast_quarter := NULL;
            lv_forecast_month := NULL;
            lv_forecast_year := NULL;
      END;



      --CALL TO MAINTAIN HISTORY FOR THE SALES FORECAST DAILY @ 3AM & 3PM.

      SELECT TO_CHAR (SYSDATE, 'HH') INTO L_HOURS FROM DUAL;

      IF L_HOURS = '3'
      THEN
         CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_HISTORY (NULL);
      END IF;

      --UPDATE MAIN TABLE WITH NEW INVENTORY
      MERGE INTO RC_SALES_FORECAST RSF
           USING (SELECT RETAIL_PART_NUMBER,
                         COMMON_PART_NUMBER,
                         XREF_PART_NUMBER,
                         EXCESS_PART_NUMBER,
                         REFRESH_INVENTORY_ITEM_ID,
                         EXCESS_INVENTORY_ITEM_ID,
                         COMMON_INVENTORY_ITEM_ID,
                         XREF_INVENTORY_ITEM_ID,
                         PID_LIFE_CYCLE,
                         RF_NETTABLE_DGI_WITH_YIELD,
                         UNORDERED_FG,
                         UNORDERED_RF_FG,
                         UNORDERED_WS_FG,
                         WS_NETTABLE_DGI_WITH_YIELD,
                         POE_NETTABLE_DGI_WITH_YIELD,
                         RF_NETTABLE_DGI_WITHOUT_YIELD,
                         WS_NETTABLE_DGI_WITHOUT_YIELD,
                         POE_NETTABLE_DGI_WITHOUT_YIELD,
                         NETTABLE_DGI,
                         TOTAL_NON_NETTABLE_PIPELINE,
                         TOTAL_NETTABLE_PIPELINE,
                         FORECASTING_PRIORITY,
                         UPDATED_ON,
                         EXCESS_LIFE_CYCLE,
                         REFRESH_LIFE_CYCLE,
                         MFG_EOS_DATE
                    FROM RC_SALES_FORECAST_STAGING
                   WHERE     APPROVAL_STATUS = 'APPROVED'
                         AND FORECAST_QUARTER = lv_forecast_quarter
                         AND FORECAST_MONTH = lv_forecast_month
                         AND FORECAST_YEAR = lv_forecast_year) IRSF
              ON (RSF.COMMON_INVENTORY_ITEM_ID =
                     IRSF.COMMON_INVENTORY_ITEM_ID)
      WHEN MATCHED
      THEN
         UPDATE SET
            RSF.RETAIL_PART_NUMBER = IRSF.RETAIL_PART_NUMBER,
            RSF.EXCESS_PART_NUMBER = IRSF.EXCESS_PART_NUMBER,
            RSF.XREF_PART_NUMBER = IRSF.XREF_PART_NUMBER,
            RSF.COMMON_PART_NUMBER = IRSF.COMMON_PART_NUMBER,
            RSF.REFRESH_INVENTORY_ITEM_ID = IRSF.REFRESH_INVENTORY_ITEM_ID,
            RSF.EXCESS_INVENTORY_ITEM_ID = IRSF.EXCESS_INVENTORY_ITEM_ID,
            RSF.XREF_INVENTORY_ITEM_ID = IRSF.XREF_INVENTORY_ITEM_ID,
            RSF.PID_LIFE_CYCLE = IRSF.PID_LIFE_CYCLE,
            RSF.UNORDERED_FG = IRSF.UNORDERED_FG,
            RSF.UNORDERED_RF_FG = IRSF.UNORDERED_RF_FG,
            RSF.UNORDERED_WS_FG = IRSF.UNORDERED_WS_FG,
            RSF.WS_NETTABLE_DGI_WITH_YIELD = IRSF.WS_NETTABLE_DGI_WITH_YIELD,
            RSF.POE_NETTABLE_DGI_WITH_YIELD =
               IRSF.POE_NETTABLE_DGI_WITH_YIELD,
            RSF.RF_NETTABLE_DGI_WITHOUT_YIELD =
               IRSF.RF_NETTABLE_DGI_WITHOUT_YIELD,
            RSF.WS_NETTABLE_DGI_WITHOUT_YIELD =
               IRSF.WS_NETTABLE_DGI_WITHOUT_YIELD,
            RSF.POE_NETTABLE_DGI_WITHOUT_YIELD =
               IRSF.POE_NETTABLE_DGI_WITHOUT_YIELD,
            RSF.NETTABLE_DGI = IRSF.NETTABLE_DGI,
            RSF.TOTAL_NON_NETTABLE_PIPELINE =
               IRSF.TOTAL_NON_NETTABLE_PIPELINE,
            RSF.RF_NETTABLE_DGI_WITH_YIELD = IRSF.RF_NETTABLE_DGI_WITH_YIELD,
            RSF.TOTAL_NETTABLE_PIPELINE = IRSF.TOTAL_NETTABLE_PIPELINE,
            RSF.FORECASTING_PRIORITY = IRSF.FORECASTING_PRIORITY,
            RSF.UPDATED_ON = IRSF.UPDATED_ON,
            RSF.EXCESS_LIFE_CYCLE = IRSF.EXCESS_LIFE_CYCLE,
            RSF.REFRESH_LIFE_CYCLE = IRSF.REFRESH_LIFE_CYCLE,
            RSF.MFG_EOS_DATE = IRSF.MFG_EOS_DATE;

      --      WHEN NOT MATCHED
      --      THEN
      --         INSERT     (RETAIL_PART_NUMBER,
      --                     EXCESS_PART_NUMBER,
      --                     XREF_PART_NUMBER,
      --                     COMMON_PART_NUMBER,
      --                     REFRESH_INVENTORY_ITEM_ID,
      --                     EXCESS_INVENTORY_ITEM_ID,
      --                     COMMON_INVENTORY_ITEM_ID,
      --                     XREF_INVENTORY_ITEM_ID,
      --                     PID_LIFE_CYCLE,
      --                     UNORDERED_FG,
      --                     RF_NETTABLE_DGI_WITH_YIELD,
      --                     TOTAL_NETTABLE_PIPELINE,
      --                     FORECASTING_PRIORITY,
      --                     CREATED_ON,
      --                     EXCESS_LIFE_CYCLE,
      --                     REFRESH_LIFE_CYCLE,
      --                     MFG_EOS_DATE,
      --                     PID_PRIORITY)
      --             VALUES (IRSF.RETAIL_PART_NUMBER,
      --                     IRSF.EXCESS_PART_NUMBER,
      --                     IRSF.XREF_PART_NUMBER,
      --                     IRSF.COMMON_PART_NUMBER,
      --                     IRSF.REFRESH_INVENTORY_ITEM_ID,
      --                     IRSF.EXCESS_INVENTORY_ITEM_ID,
      --                     IRSF.COMMON_INVENTORY_ITEM_ID,
      --                     IRSF.XREF_INVENTORY_ITEM_ID,
      --                     IRSF.PID_LIFE_CYCLE,
      --                     IRSF.UNORDERED_FG,
      --                     IRSF.RF_NETTABLE_DGI_WITH_YIELD,
      --                     IRSF.TOTAL_NETTABLE_PIPELINE,
      --                     IRSF.FORECASTING_PRIORITY,
      --                     SYSDATE,
      --                     IRSF.EXCESS_LIFE_CYCLE,
      --                     IRSF.REFRESH_LIFE_CYCLE,
      --                     IRSF.MFG_EOS_DATE,
      --                     IRSF.PID_PRIORITY);


      --      DELETE FROM CRPADM.RC_SALES_FORECAST RSF
      --            WHERE NOT EXISTS
      --                     (SELECT 1
      --                        FROM CRPADM.RC_SALES_FORECAST_STAGING RSFS
      --                       WHERE RSFS.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER
      --                         AND RSFS.APPROVAL_STATUS = 'APPROVED');


      --UPDATE ASP COLUMNS IN RC_SALES_FORECAST
      UPDATE RC_SALES_FORECAST RSF
         SET ASP_RF =
                (CASE
                    WHEN NVL (
                            CRPREP.GET_AVG_SALES_PRICE (
                               RSF.REFRESH_INVENTORY_ITEM_ID,
                               'RETAIL',
                               'Y'),
                            0) > 0
                    THEN
                       CRPREP.GET_AVG_SALES_PRICE (
                          RSF.REFRESH_INVENTORY_ITEM_ID,
                          'RETAIL',
                          'Y')
                    WHEN (    RSF.RETAIL_PART_NUMBER IS NOT NULL
                          AND NVL (
                                 (SELECT ASP_RF
                                    FROM CRPREP.RC_SCRAP_REPORT RSP
                                   WHERE RSF.RETAIL_PART_NUMBER =
                                            RSP.RETAIL_PART_NUMBER),
                                 0) > 0)
                    THEN
                       (SELECT ASP_RF
                          FROM CRPREP.RC_SCRAP_REPORT RSP
                         WHERE RSF.RETAIL_PART_NUMBER =
                                  RSP.RETAIL_PART_NUMBER)
                    WHEN (    RSF.RETAIL_PART_NUMBER IS NOT NULL
                          AND NVL (
                                 (SELECT GPL
                                    FROM CRPREP.RC_SCRAP_REPORT RSP
                                   WHERE RSF.RETAIL_PART_NUMBER =
                                            RSP.RETAIL_PART_NUMBER),
                                 0) > 0)
                    THEN
                       CEIL (
                            (SELECT GPL
                               FROM CRPREP.RC_SCRAP_REPORT RSP
                              WHERE RSF.RETAIL_PART_NUMBER =
                                       RSP.RETAIL_PART_NUMBER)
                          * 0.35)
                    ELSE
                       0
                 END),
             ASP_WS =
                (CASE
                    WHEN NVL (
                            CRPREP.GET_AVG_SALES_PRICE (
                               RSF.EXCESS_INVENTORY_ITEM_ID,
                               'EXCESS',
                               'Y'),
                            0) > 0
                    THEN
                       CRPREP.GET_AVG_SALES_PRICE (
                          RSF.EXCESS_INVENTORY_ITEM_ID,
                          'EXCESS',
                          'Y')
                    WHEN (    RSF.EXCESS_PART_NUMBER IS NOT NULL
                          AND NVL (
                                 (SELECT GPL
                                    FROM CRPREP.RC_SCRAP_REPORT RSP
                                   WHERE RSF.EXCESS_PART_NUMBER =
                                            RSP.EXCESS_PART_NUMBER),
                                 0) > 0)
                    THEN
                       CEIL (
                            (SELECT GPL
                               FROM CRPREP.RC_SCRAP_REPORT RSP
                              WHERE RSF.EXCESS_PART_NUMBER =
                                       RSP.EXCESS_PART_NUMBER)
                          * 0.15)
                    ELSE
                       0
                 END),
             ASP_OUTLET =
                (CASE
                    WHEN NVL (
                            CRPREP.GET_AVG_SALES_PRICE (
                               RSF.REFRESH_INVENTORY_ITEM_ID,
                               'OUTLET',
                               'Y'),
                            0) > 0
                    THEN
                       CRPREP.GET_AVG_SALES_PRICE (
                          RSF.REFRESH_INVENTORY_ITEM_ID,
                          'OUTLET',
                          'Y')
                    WHEN (    RSF.RETAIL_PART_NUMBER IS NOT NULL
                          AND NVL (
                                 (SELECT GPL
                                    FROM CRPREP.RC_SCRAP_REPORT RSP
                                   WHERE RSF.RETAIL_PART_NUMBER =
                                            RSP.RETAIL_PART_NUMBER),
                                 0) > 0)
                    THEN
                       CEIL (
                            (SELECT GPL
                               FROM CRPREP.RC_SCRAP_REPORT RSP
                              WHERE RSF.RETAIL_PART_NUMBER =
                                       RSP.RETAIL_PART_NUMBER)
                          * 0.10)
                    ELSE
                       0
                 END);

      --UPDATE ALLOCATION COLUMNS IN RC_SALES_FORECAST
      UPDATE RC_SALES_FORECAST RSF
         SET TOTAL_RF_ALLOCATION =
                NVL (
                   (SELECT RF_COUNTER
                      FROM CRPSC.RC_AE_FGI_REQUIREMENT AFR
                     WHERE AFR.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER),
                   0),
             WS_ALLOCATION =
                NVL (
                   (SELECT WS_COUNTER
                      FROM CRPSC.RC_AE_FGI_REQUIREMENT AFR
                     WHERE AFR.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER),
                   0),
             OUTLET_ALLOCATION =
                NVL (
                   (SELECT OUTLET_ALLOC_QUANTITY
                      FROM CRPSC.RC_AE_FGI_REQUIREMENT AFR
                     WHERE AFR.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER),
                   0),
             PIPELINE_NOT_ALLOCATED =
                NVL (
                   (SELECT SUM (QTY_ON_HAND)
                      FROM CRPADM.RC_INV_BTS_C3_MV INV
                     WHERE     (LOCATION IN
                                   (SELECT MSTR.SUB_INVENTORY_LOCATION
                                      FROM CRPADM.RC_SUB_INV_LOC_MSTR MSTR
                                     WHERE     MSTR.INVENTORY_TYPE = 1
                                           AND MSTR.NETTABLE_FLAG = 1
                                           AND MSTR.PROGRAM_TYPE IN (0, 1, 2)))
                           AND (   PART_NUMBER = RSF.RETAIL_PART_NUMBER
                                OR PART_NUMBER = RSF.EXCESS_PART_NUMBER
                                OR PART_NUMBER = RSF.COMMON_PART_NUMBER
                                OR PART_NUMBER = RSF.XREF_PART_NUMBER)
                           AND NOT EXISTS
                                  (SELECT *
                                     FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                                          CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                                    WHERE     1 = 1
                                          AND RS.REFRESH_METHOD_ID IN
                                                 (SELECT DTLS.REFRESH_METHOD_ID
                                                    FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                         MSTR,
                                                         CRPADM.RC_SUB_INV_LOC_FLG_DTLS
                                                         DTLS
                                                   WHERE     MSTR.SUB_INVENTORY_ID =
                                                                DTLS.SUB_INVENTORY_ID
                                                         AND MSTR.SUB_INVENTORY_LOCATION =
                                                                INV.LOCATION)
                                          AND RS.REFRESH_INVENTORY_ITEM_ID IN
                                                 (RSF.REFRESH_INVENTORY_ITEM_ID,
                                                  RSF.EXCESS_INVENTORY_ITEM_ID,
                                                  RSF.COMMON_INVENTORY_ITEM_ID,
                                                  RSF.XREF_INVENTORY_ITEM_ID)
                                          AND RS.REPAIR_PARTNER_ID =
                                                 RP.REPAIR_PARTNER_ID
                                          AND RS.REFRESH_STATUS = 'ACTIVE'
                                          AND RP.ACTIVE_FLAG = 'Y')
                           AND SITE NOT LIKE 'Z32%'),
                   0),
             SALES_RF_ALLOCATION =
                NVL (
                   LEAST (
                      GREATEST (
                         (  NVL (
                               (SELECT SUM (
                                            (QTY_ON_HAND)
                                          - ABS (TOTAL_RESERVATIONS))
                                  FROM CRPADM.RC_INV_BTS_C3_MV
                                 WHERE     LOCATION = 'FG' -- Considering only BTS FG locations
                                       AND PROGRAM_TYPE = 'RETAIL'
                                       AND PART_NUMBER =
                                              RSF.RETAIL_PART_NUMBER
                                       AND SITE NOT LIKE 'Z32%'),
                               0)
                          + FLOOR (
                               NVL (
                                  (SELECT SUM (RF_QTY_AFTER_YIELD)
                                     FROM CRPADM.RC_INV_BTS_C3_MV
                                    WHERE     (    LOCATION <> 'FG'
                                               AND LOCATION IN
                                                      (SELECT MSTR.SUB_INVENTORY_LOCATION
                                                         FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                              MSTR
                                                        WHERE     MSTR.NETTABLE_FLAG =
                                                                     1
                                                              AND MSTR.PROGRAM_TYPE =
                                                                     0))
                                          AND (   PART_NUMBER =
                                                     RSF.RETAIL_PART_NUMBER
                                               OR PART_NUMBER =
                                                     RSF.COMMON_PART_NUMBER
                                               OR PART_NUMBER =
                                                     RSF.XREF_PART_NUMBER)
                                          AND SITE NOT LIKE 'Z32%'),
                                  0))
                          - NVL (
                               (SELECT ABS (SUM (TOTAL_RESERVATIONS))
                                  FROM CRPADM.RC_INV_BTS_C3_MV
                                 WHERE     SITE = 'GDGI'
                                       AND PART_NUMBER =
                                              RSF.RETAIL_PART_NUMBER
                                       AND SITE NOT LIKE 'Z32%'),
                               0)),
                         0),
                      (NVL (
                          NVL (RF_ADJ_OVERRIDDEN_FORECAST,
                               RF_ADJUSTED_FORECAST),
                          RF_90DAY_FORECAST))),
                   0),
             SALES_WS_ALLOCATION =
                NVL (
                   LEAST (
                      GREATEST (
                         (  NVL (
                               (SELECT SUM (
                                            (QTY_ON_HAND)
                                          - ABS (TOTAL_RESERVATIONS))
                                  FROM CRPADM.RC_INV_BTS_C3_MV
                                 WHERE     LOCATION = 'FG' -- Considering only BTS FG locations
                                       AND PROGRAM_TYPE = 'EXCESS'
                                       AND PART_NUMBER =
                                              RSF.EXCESS_PART_NUMBER
                                       AND SITE NOT LIKE 'Z32%'),
                               0)
                          + FLOOR (
                               NVL (
                                  (SELECT SUM (WS_QTY_AFTER_YIELD)
                                     FROM CRPADM.RC_INV_BTS_C3_MV
                                    WHERE     (    LOCATION <> 'FG'
                                               AND LOCATION IN
                                                      (SELECT MSTR.SUB_INVENTORY_LOCATION
                                                         FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                              MSTR
                                                        WHERE     MSTR.NETTABLE_FLAG =
                                                                     1
                                                              AND MSTR.PROGRAM_TYPE =
                                                                     1))
                                          AND (   PART_NUMBER =
                                                     RSF.EXCESS_PART_NUMBER
                                               OR PART_NUMBER =
                                                     RSF.COMMON_PART_NUMBER
                                               OR PART_NUMBER =
                                                     RSF.XREF_PART_NUMBER)
                                          AND SITE NOT LIKE 'Z32%'),
                                  0))
                          - NVL (
                               (SELECT ABS (SUM (TOTAL_RESERVATIONS))
                                  FROM CRPADM.RC_INV_BTS_C3_MV
                                 WHERE     SITE = 'GDGI'
                                       AND PART_NUMBER =
                                              RSF.EXCESS_PART_NUMBER
                                       AND SITE NOT LIKE 'Z32%'),
                               0)),
                         0),
                      (NVL (WS_ADJUSTED_FORECAST, WS_90DAY_FORECAST))),
                   0),
             RF_ALLOCATED_FROM_DAY0 =
                NVL (
                   (SELECT RF_COUNTER
                      FROM CRPSC.RC_AE_FGI_REQUIREMENT AFR
                     WHERE AFR.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER),
                   0),
             WS_ALLOCATED_FROM_DAY0 =
                NVL (
                   (SELECT WS_COUNTER
                      FROM CRPSC.RC_AE_FGI_REQUIREMENT AFR
                     WHERE AFR.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER),
                   0);

      --UPDATE REVENUE COLUMNS IN RC_SALES_FORECAST
      UPDATE RC_SALES_FORECAST
         SET EXPECTED_REVENUE_RF = NVL ( (ASP_RF * TOTAL_RF_ALLOCATION), 0),
             EXPECTED_REVENUE_WS = NVL ( (ASP_WS * WS_ALLOCATION), 0),
             EXPECTED_REVENUE_OUTLET =
                NVL ( (ASP_OUTLET * OUTLET_ALLOCATION), 0),
             FORECASTED_REVENUE =
                  NVL (
                       (NVL (
                           NVL (RF_ADJ_OVERRIDDEN_FORECAST,
                                RF_ADJUSTED_FORECAST),
                           RF_90DAY_FORECAST))
                     * ASP_RF,
                     0)
                + NVL (
                     (NVL (WS_ADJUSTED_FORECAST, WS_90DAY_FORECAST)) * ASP_WS,
                     0);

      --UPDATE SALES REVENUE COLUMNS IN RC_SALES_FORECAST
      UPDATE RC_SALES_FORECAST
         SET EXPECTED_SALES_REVENUE_RF =
                NVL ( (ASP_RF * SALES_RF_ALLOCATION), 0),
             EXPECTED_SALES_REVENUE_WS =
                NVL ( (ASP_WS * SALES_WS_ALLOCATION), 0),
             EXPECTED_SALES_REVENUE_OUTLET =
                NVL ( (ASP_OUTLET * OUTLET_ALLOCATION), 0);

      --UPDATE BUILD UNITS REQD COLUMNS IN RC_SALES_FORECAST
      UPDATE RC_SALES_FORECAST RSF
         SET RSF.UNITS_REQB_CONSTRAINED =
                NVL (
                   (CASE
                       WHEN (RSF.SALES_RF_ALLOCATION - RSF.UNORDERED_FG) < 0
                       THEN
                          0
                       ELSE
                          LEAST (
                             (RSF.SALES_RF_ALLOCATION - RSF.UNORDERED_FG),
                             RSF.RF_NETTABLE_DGI_WITH_YIELD)
                    END),
                   0),
             RSF.UNITS_REQB_UNCONSTRAINED =
                NVL (
                   (CASE
                       WHEN (  (NVL (
                                   NVL (RSF.RF_ADJ_OVERRIDDEN_FORECAST,
                                        RSF.RF_ADJUSTED_FORECAST),
                                   RSF.RF_90DAY_FORECAST))
                             - RSF.UNORDERED_FG) < 0
                       THEN
                          0
                       ELSE
                          (  (NVL (
                                 NVL (RSF.RF_ADJ_OVERRIDDEN_FORECAST,
                                      RSF.RF_ADJUSTED_FORECAST),
                                 RSF.RF_90DAY_FORECAST))
                           - RSF.UNORDERED_FG)
                    END),
                   0),
             RSF.UNITS_REQ_BUILD =
                NVL (
                   (CASE
                       WHEN (RSF.UNORDERED_FG < RSF.TOTAL_NEW_MAX)
                       THEN
                          (CASE
                              WHEN ( (RSF.TOTAL_NEW_MAX - RSF.UNORDERED_FG) <
                                       RSF.TOTAL_NETTABLE_PIPELINE)
                              THEN
                                 (RSF.TOTAL_NEW_MAX - RSF.UNORDERED_FG)
                              ELSE
                                 GREATEST (
                                    (  RSF.TOTAL_NETTABLE_PIPELINE
                                     - RSF.UNORDERED_FG),
                                    0)
                           END)
                       ELSE
                          0
                    END),
                   0),
             RSF.NEW_DEMAND =
                NVL (
                   GREATEST (
                      ROUND (
                           ( (1 - (RSF.REFRESH_YIELD / 100)) + 1)
                         * (  RSF.SALES_FORECAST_12M
                            - RSF.TOTAL_NETTABLE_PIPELINE),
                         0),
                      RSF.SYSTEM_DEMAND),
                   0);

      --UPDATE REPAIR COST COLUMNS IN RC_SALES_FORECAST
      UPDATE RC_SALES_FORECAST RSF
         SET RSF.RF_EXPECTED_REPAIR_COST =
                NVL (
                   ROUND (
                        (  (  (NVL (
                                  (SELECT MAX (REPAIR_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.RETAIL_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.RETAIL_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.RETAIL_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                1))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 1
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.RETAIL_PART_NUMBER)
                         * RSF.UNITS_REQ_BUILD)
                      + (  (  (NVL (
                                  (SELECT MAX (TEST_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.RETAIL_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.RETAIL_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.RETAIL_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                2))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 2
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.RETAIL_PART_NUMBER)
                         * RSF.UNITS_REQ_BUILD)
                      + (  (  (NVL (
                                  (SELECT MAX (SCREEN_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.RETAIL_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                34
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.RETAIL_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.RETAIL_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                3))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 3
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.RETAIL_PART_NUMBER)
                         * RSF.UNITS_REQ_BUILD),
                      2),
                   0),
             RSF.WS_EXPECTED_REPAIR_COST =
                NVL (
                   ROUND (
                        (  (  (NVL (
                                  (SELECT MAX (REPAIR_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.EXCESS_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.EXCESS_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.EXCESS_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                1))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 1
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.EXCESS_PART_NUMBER)
                         * RSF.WS_ALLOCATION)
                      + (  (  (NVL (
                                  (SELECT MAX (TEST_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.EXCESS_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.EXCESS_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.EXCESS_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                2))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 2
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.EXCESS_PART_NUMBER)
                         * RSF.WS_ALLOCATION)
                      + (  (  (NVL (
                                  (SELECT MAX (SCREEN_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.EXCESS_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                34
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.EXCESS_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.EXCESS_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                3))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 3
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.EXCESS_PART_NUMBER)
                         * RSF.WS_ALLOCATION),
                      2),
                   0),
             RSF.RF_FORECASTED_REPAIR_COST =
                NVL (
                   ROUND (
                        (  (  (NVL (
                                  (SELECT MAX (REPAIR_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.RETAIL_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.RETAIL_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.RETAIL_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                1))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 1
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.RETAIL_PART_NUMBER)
                         * RSF.UNITS_REQB_UNCONSTRAINED)
                      + (  (  (NVL (
                                  (SELECT MAX (TEST_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.RETAIL_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.RETAIL_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.RETAIL_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                2))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 2
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.RETAIL_PART_NUMBER)
                         * RSF.UNITS_REQB_UNCONSTRAINED)
                      + (  (  (NVL (
                                  (SELECT MAX (SCREEN_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.RETAIL_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                34
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.RETAIL_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.RETAIL_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                3))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 3
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.RETAIL_PART_NUMBER)
                         * RSF.UNITS_REQB_UNCONSTRAINED),
                      2),
                   0),
             RSF.WS_FORECASTED_REPAIR_COST =
                NVL (
                   ROUND (
                        (  (  (NVL (
                                  (SELECT MAX (REPAIR_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.EXCESS_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.EXCESS_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.EXCESS_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                1))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 1
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.EXCESS_PART_NUMBER)
                         * (NVL (RSF.WS_ADJUSTED_FORECAST,
                                 RSF.WS_90DAY_FORECAST)))
                      + (  (  (NVL (
                                  (SELECT MAX (TEST_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.EXCESS_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.EXCESS_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.EXCESS_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                2))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 2
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.EXCESS_PART_NUMBER)
                         * (NVL (RSF.WS_ADJUSTED_FORECAST,
                                 RSF.WS_90DAY_FORECAST)))
                      + (  (  (NVL (
                                  (SELECT MAX (SCREEN_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.EXCESS_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                34
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.EXCESS_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.EXCESS_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                3))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 3
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.EXCESS_PART_NUMBER)
                         * (NVL (RSF.WS_ADJUSTED_FORECAST,
                                 RSF.WS_90DAY_FORECAST))),
                      2),
                   0);

      --UPDATE TOTAL REPAIR COST COLUMNS IN RC_SALES_FORECAST
      UPDATE RC_SALES_FORECAST RSF
         SET RSF.TOTAL_EXPECTED_REPAIR_COST =
                NVL (
                   (RSF.RF_EXPECTED_REPAIR_COST + RSF.WS_EXPECTED_REPAIR_COST),
                   0),
             RSF.TOTAL_FORECASTED_REPAIR_COST =
                NVL (
                   (  RSF.RF_FORECASTED_REPAIR_COST
                    + RSF.WS_FORECASTED_REPAIR_COST),
                   0);

      COMMIT;

      --Upsert Financial summary main table
      MERGE INTO CRPADM.RC_SALES_FORECAST_FINSUM FINSUM
           USING (SELECT EXPECTED_REVENUE_RF,
                         EXPECTED_REVENUE_WS,
                         EXPECTED_REVENUE_OUTLET,
                         EXPECTED_REPAIR_COST,
                         RF_FORECASTED_REPAIR_COST,
                         WS_FORECASTED_REPAIR_COST,
                         OUTLET_FORECASTED_REPAIR_COST,
                         FORECASTED_REPAIR_COST,
                         EXPECTED_SALES_REVENUE_RF,
                         EXPECTED_SALES_REVENUE_WS,
                         EXPECTED_SALES_REVENUE_OUTLET,
                         TOTL_EXPCTD_SALES_REPAIR_COST,
                         (SELECT DISTINCT FORECAST_QUARTER
                            FROM RC_SALES_FORECAST)
                            AS FORECAST_QUARTER,
                         (SELECT DISTINCT FORECAST_MONTH
                            FROM RC_SALES_FORECAST)
                            AS FORECAST_MONTH,
                         (SELECT DISTINCT FORECAST_YEAR
                            FROM RC_SALES_FORECAST)
                            AS FORECAST_YEAR
                    FROM (SELECT SUM (NVL (EXPECTED_REVENUE_RF, 0))
                                    AS EXPECTED_REVENUE_RF,
                                 SUM (NVL (EXPECTED_REVENUE_WS, 0))
                                    AS EXPECTED_REVENUE_WS,
                                 SUM (NVL (EXPECTED_REVENUE_OUTLET, 0))
                                    AS EXPECTED_REVENUE_OUTLET,
                                 SUM (NVL (TOTAL_EXPECTED_REPAIR_COST, 0))
                                    AS EXPECTED_REPAIR_COST,
                                 SUM (
                                    NVL (
                                         (NVL (
                                             NVL (RF_ADJ_OVERRIDDEN_FORECAST,
                                                  RF_ADJUSTED_FORECAST),
                                             RF_90DAY_FORECAST))
                                       * ASP_RF,
                                       0))
                                    AS RF_FORECASTED_REPAIR_COST,
                                 SUM (
                                    NVL (
                                         (NVL (WS_ADJUSTED_FORECAST,
                                               WS_90DAY_FORECAST))
                                       * ASP_WS,
                                       0))
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
                                    AS TOTL_EXPCTD_SALES_REPAIR_COST
                            FROM RC_SALES_FORECAST
                           WHERE     FORECAST_QUARTER = lv_forecast_quarter
                                 AND FORECAST_MONTH = lv_forecast_month
                                 AND FORECAST_YEAR = lv_forecast_year))
                 IFINSUM
              ON (    IFINSUM.FORECAST_QUARTER = FINSUM.FORECAST_QUARTER
                  AND IFINSUM.FORECAST_MONTH = FINSUM.FORECAST_MONTH
                  AND IFINSUM.FORECAST_MONTH = FINSUM.FORECAST_MONTH)
      WHEN MATCHED
      THEN
         UPDATE SET
            FINSUM.EXPECTED_REVENUE_RF = IFINSUM.EXPECTED_REVENUE_RF,
            FINSUM.EXPECTED_REVENUE_WS = IFINSUM.EXPECTED_REVENUE_WS,
            FINSUM.EXPECTED_REVENUE_OUTLET = IFINSUM.EXPECTED_REVENUE_OUTLET,
            FINSUM.EXPECTED_REPAIR_COST = IFINSUM.EXPECTED_REPAIR_COST,
            FINSUM.RF_FORECASTED_REPAIR_COST =
               IFINSUM.RF_FORECASTED_REPAIR_COST,
            FINSUM.WS_FORECASTED_REPAIR_COST =
               IFINSUM.WS_FORECASTED_REPAIR_COST,
            FINSUM.OUTLET_FORECASTED_REPAIR_COST =
               IFINSUM.OUTLET_FORECASTED_REPAIR_COST,
            FINSUM.FORECASTED_REPAIR_COST = IFINSUM.FORECASTED_REPAIR_COST,
            FINSUM.EXPECTED_SALES_REVENUE_RF =
               IFINSUM.EXPECTED_SALES_REVENUE_RF,
            FINSUM.EXPECTED_SALES_REVENUE_WS =
               IFINSUM.EXPECTED_SALES_REVENUE_WS,
            FINSUM.EXPECTED_SALES_REVENUE_OUTLET =
               IFINSUM.EXPECTED_SALES_REVENUE_OUTLET,
            FINSUM.TOTL_EXPCTD_SALES_REPAIR_COST =
               IFINSUM.TOTL_EXPCTD_SALES_REPAIR_COST;

      COMMIT;


      INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (
                        CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                        'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_UPDATE',
                        'END',
                        SYSDATE);

      COMMIT;
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
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_UPDATE',
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
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_UPDATE',
            'PACKAGE',
            NULL,
            'Y');
   END;



   --PROCEDURE TO UPSERT HISTORY FOR SALES FORECAST DETAILS

   PROCEDURE RC_SALES_FORECAST_HISTORY (I_USER_ID IN VARCHAR2)
   IS
      TYPE RC_SALES_FORECAST_HISTORY_OBJ IS RECORD
      (
         RETAIL_PART_NUMBER              VARCHAR2 (256 BYTE),
         EXCESS_PART_NUMBER              VARCHAR2 (256 BYTE),
         XREF_PART_NUMBER                VARCHAR2 (256 BYTE),
         COMMON_PART_NUMBER              VARCHAR2 (256 BYTE),
         REFRESH_INVENTORY_ITEM_ID       NUMBER,
         EXCESS_INVENTORY_ITEM_ID        NUMBER,
         COMMON_INVENTORY_ITEM_ID        NUMBER,
         XREF_INVENTORY_ITEM_ID          NUMBER,
         PID_LIFE_CYCLE                  VARCHAR2 (100 BYTE),
         UNORDERED_FG                    NUMBER,
         RF_NETTABLE_DGI_WITH_YIELD      NUMBER,
         TOTAL_NETTABLE_PIPELINE         NUMBER,
         SALES_PRIORITY                  VARCHAR2 (100 BYTE),
         RF_90DAY_FORECAST               NUMBER,
         WS_90DAY_FORECAST               NUMBER,
         TOTAL_RF_ALLOCATION             NUMBER,
         WS_ALLOCATION                   NUMBER,
         OUTLET_ALLOCATION               NUMBER,
         PIPELINE_NOT_ALLOCATED          NUMBER,
         ASP_RF                          NUMBER,
         ASP_WS                          NUMBER,
         EXPECTED_REVENUE_RF             NUMBER,
         EXPECTED_REVENUE_WS             NUMBER,
         FORECASTED_REVENUE              NUMBER,
         RF_SALES_3M                     NUMBER,
         WS_SALES_3M                     NUMBER,
         OUTLET_SALES_3M                 NUMBER,
         SUGGESTED_RF_MAX                NUMBER,
         TOTAL_NEW_MAX                   NUMBER,
         NAM_RF_NEW_MAX                  NUMBER,
         EMEA_RF_NEW_MAX                 NUMBER,
         UNITS_REQB_CONSTRAINED          NUMBER,
         UNITS_REQB_UNCONSTRAINED        NUMBER,
         UNITS_REQ_BUILD                 NUMBER,
         RF_EXPECTED_REPAIR_COST         NUMBER,
         WS_EXPECTED_REPAIR_COST         NUMBER,
         TOTAL_EXPECTED_REPAIR_COST      NUMBER,
         RF_FORECASTED_REPAIR_COST       NUMBER,
         WS_FORECASTED_REPAIR_COST       NUMBER,
         TOTAL_FORECASTED_REPAIR_COST    NUMBER,
         SYSTEM_DEMAND                   NUMBER,
         REFRESH_YIELD                   NUMBER,
         SALES_FORECAST_12M              NUMBER,
         NEW_DEMAND                      NUMBER,
         CREATED_ON                      DATE,
         UPDATED_BY                      VARCHAR2 (256 BYTE),
         UPDATED_ON                      DATE,
         SUBMITTED_AT                    DATE,
         APPROVED_AT                     DATE,
         APPROVAL_STATUS                 VARCHAR2 (256 BYTE),
         ASP_OUTLET                      NUMBER,
         EXPECTED_REVENUE_OUTLET         NUMBER,
         PID_PRIORITY                    VARCHAR2 (10 BYTE),
         SALES_RF_ALLOCATION             NUMBER,
         SALES_WS_ALLOCATION             NUMBER,
         RF_ALLOCATED_FROM_DAY0          NUMBER,
         WS_ALLOCATED_FROM_DAY0          NUMBER,
         EXPECTED_SALES_REVENUE_RF       NUMBER,
         EXPECTED_SALES_REVENUE_WS       NUMBER,
         EXPECTED_SALES_REVENUE_OUTLET   NUMBER,
         TOTL_EXPCTD_SALES_REPAIR_COST   NUMBER,
         EXCESS_LIFE_CYCLE               VARCHAR2 (10 BYTE),
         REFRESH_LIFE_CYCLE              VARCHAR2 (10 BYTE),
         MFG_EOS_DATE                    DATE,
         WS_ADJUSTED_FORECAST            NUMBER,
         RF_ADJUSTED_FORECAST            NUMBER,
         ADJUSTED_OVERRIDDEN_FORECAST    VARCHAR2 (100 BYTE),
         RF_ADJ_OVERRIDDEN_FORECAST      NUMBER,
         ADJUSTED_PID_PRIORITY           VARCHAR2 (10 BYTE),
         ADJ_OVERRIDDEN_PID_PRIORITY     VARCHAR2 (10 BYTE)
      );

      TYPE RC_SALES_FORECAST_HISTORY_LIST
         IS TABLE OF RC_SALES_FORECAST_HISTORY_OBJ;

      LV_SALES_FORECAST_HISTORY_LIST   RC_SALES_FORECAST_HISTORY_LIST;


      CURSOR C_FORECAST_DETAILS
      IS
         SELECT RETAIL_PART_NUMBER,
                EXCESS_PART_NUMBER,
                XREF_PART_NUMBER,
                COMMON_PART_NUMBER,
                REFRESH_INVENTORY_ITEM_ID,
                EXCESS_INVENTORY_ITEM_ID,
                COMMON_INVENTORY_ITEM_ID,
                XREF_INVENTORY_ITEM_ID,
                PID_LIFE_CYCLE,
                UNORDERED_FG,
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
                EXPECTED_SALES_REVENUE_RF,
                EXPECTED_SALES_REVENUE_WS,
                EXPECTED_SALES_REVENUE_OUTLET,
                TOTL_EXPCTD_SALES_REPAIR_COST,
                EXCESS_LIFE_CYCLE,
                REFRESH_LIFE_CYCLE,
                MFG_EOS_DATE,
                WS_ADJUSTED_FORECAST,
                RF_ADJUSTED_FORECAST,
                ADJUSTED_OVERRIDDEN_FORECAST,
                RF_ADJ_OVERRIDDEN_FORECAST,
                ADJUSTED_PID_PRIORITY,
                ADJ_OVERRIDDEN_PID_PRIORITY
           FROM RC_SALES_FORECAST;
   BEGIN
      INSERT INTO CRPADM.RC_PROCESS_LOG
           VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                   'HISTORY',
                   'START',
                   SYSDATE);

      COMMIT;

      IF NOT (C_FORECAST_DETAILS%ISOPEN)
      THEN
         OPEN C_FORECAST_DETAILS;
      END IF;

      LOOP
         FETCH C_FORECAST_DETAILS
            BULK COLLECT INTO LV_SALES_FORECAST_HISTORY_LIST
            LIMIT 2000;

         EXIT WHEN LV_SALES_FORECAST_HISTORY_LIST.COUNT = 0;

         IF LV_SALES_FORECAST_HISTORY_LIST.COUNT > 0
         THEN
            FORALL IDX
                IN LV_SALES_FORECAST_HISTORY_LIST.FIRST ..
                   LV_SALES_FORECAST_HISTORY_LIST.LAST
               INSERT
                 INTO RC_SALES_FORECAST_HIST (RETAIL_PART_NUMBER,
                                              EXCESS_PART_NUMBER,
                                              XREF_PART_NUMBER,
                                              COMMON_PART_NUMBER,
                                              REFRESH_INVENTORY_ITEM_ID,
                                              EXCESS_INVENTORY_ITEM_ID,
                                              COMMON_INVENTORY_ITEM_ID,
                                              XREF_INVENTORY_ITEM_ID,
                                              PID_LIFE_CYCLE,
                                              UNORDERED_FG,
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
                                              SUBMITTED_AT,
                                              APPROVED_AT,
                                              APPROVAL_STATUS,
                                              ACTIVE_FLAG,
                                              HIST_CREATED_DATE,
                                              HIST_CREATED_BY,
                                              ASP_OUTLET,
                                              EXPECTED_REVENUE_OUTLET,
                                              PID_PRIORITY,
                                              SALES_RF_ALLOCATION,
                                              SALES_WS_ALLOCATION,
                                              RF_ALLOCATED_FROM_DAY0,
                                              WS_ALLOCATED_FROM_DAY0,
                                              EXPECTED_SALES_REVENUE_RF,
                                              EXPECTED_SALES_REVENUE_WS,
                                              EXPECTED_SALES_REVENUE_OUTLET,
                                              TOTL_EXPCTD_SALES_REPAIR_COST,
                                              EXCESS_LIFE_CYCLE,
                                              REFRESH_LIFE_CYCLE,
                                              MFG_EOS_DATE,
                                              WS_ADJUSTED_FORECAST,
                                              RF_ADJUSTED_FORECAST,
                                              ADJUSTED_OVERRIDDEN_FORECAST,
                                              RF_ADJ_OVERRIDDEN_FORECAST,
                                              ADJUSTED_PID_PRIORITY,
                                              ADJ_OVERRIDDEN_PID_PRIORITY)
                  VALUES (
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).RETAIL_PART_NUMBER,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).EXCESS_PART_NUMBER,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).XREF_PART_NUMBER,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).COMMON_PART_NUMBER,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).REFRESH_INVENTORY_ITEM_ID,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).EXCESS_INVENTORY_ITEM_ID,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).COMMON_INVENTORY_ITEM_ID,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).XREF_INVENTORY_ITEM_ID,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).PID_LIFE_CYCLE,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).UNORDERED_FG,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).RF_NETTABLE_DGI_WITH_YIELD,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).TOTAL_NETTABLE_PIPELINE,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).SALES_PRIORITY,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).RF_90DAY_FORECAST,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).WS_90DAY_FORECAST,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).TOTAL_RF_ALLOCATION,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).WS_ALLOCATION,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).OUTLET_ALLOCATION,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).PIPELINE_NOT_ALLOCATED,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).ASP_RF,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).ASP_WS,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).EXPECTED_REVENUE_RF,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).EXPECTED_REVENUE_WS,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).FORECASTED_REVENUE,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).RF_SALES_3M,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).WS_SALES_3M,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).OUTLET_SALES_3M,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).SUGGESTED_RF_MAX,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).TOTAL_NEW_MAX,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).NAM_RF_NEW_MAX,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).EMEA_RF_NEW_MAX,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).UNITS_REQB_CONSTRAINED,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).UNITS_REQB_UNCONSTRAINED,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).UNITS_REQ_BUILD,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).RF_EXPECTED_REPAIR_COST,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).WS_EXPECTED_REPAIR_COST,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).TOTAL_EXPECTED_REPAIR_COST,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).RF_FORECASTED_REPAIR_COST,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).WS_FORECASTED_REPAIR_COST,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).TOTAL_FORECASTED_REPAIR_COST,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).SYSTEM_DEMAND,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).REFRESH_YIELD,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).SALES_FORECAST_12M,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).NEW_DEMAND,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).CREATED_ON,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).UPDATED_BY,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).UPDATED_ON,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).SUBMITTED_AT,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).APPROVED_AT,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).APPROVAL_STATUS,
                            'Y',
                            SYSDATE,
                            CASE
                               WHEN I_USER_ID IS NOT NULL THEN I_USER_ID
                               ELSE 'SYSTEM'
                            END,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).ASP_OUTLET,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).EXPECTED_REVENUE_OUTLET,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).PID_PRIORITY,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).SALES_RF_ALLOCATION,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).SALES_WS_ALLOCATION,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).RF_ALLOCATED_FROM_DAY0,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).WS_ALLOCATED_FROM_DAY0,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).EXPECTED_SALES_REVENUE_RF,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).EXPECTED_SALES_REVENUE_WS,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).EXPECTED_SALES_REVENUE_OUTLET,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).TOTL_EXPCTD_SALES_REPAIR_COST,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).EXCESS_LIFE_CYCLE,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).REFRESH_LIFE_CYCLE,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).MFG_EOS_DATE,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).WS_ADJUSTED_FORECAST,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).RF_ADJUSTED_FORECAST,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).ADJUSTED_OVERRIDDEN_FORECAST,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).RF_ADJ_OVERRIDDEN_FORECAST,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).ADJUSTED_PID_PRIORITY,
                            LV_SALES_FORECAST_HISTORY_LIST (IDX).ADJ_OVERRIDDEN_PID_PRIORITY);
         ELSE
            EXIT;
         END IF;
      END LOOP;                                     -- END OF CURSOR ITERATION

      CLOSE C_FORECAST_DETAILS;

      COMMIT;

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
                     POE_NETTABLE_DGI_WITH_YIELD,
                     POE_NETTABLE_DGI_WITHOUT_YIELD,
                     UNORDERED_FG,
                     TOTAL_NON_NETTABLE_PIPELINE,
                     RF_FG_ALLOCATION,
                     RF_DGI_ALLOCATION,
                     NETTABLE_DGI,
                     WS_ADJUSTED_FORECAST,
                     RF_ADJUSTED_FORECAST,
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
                 UNORDERED_FG,
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
                 CASE
                    WHEN I_USER_ID IS NOT NULL THEN I_USER_ID
                    ELSE 'SYSTEM'
                 END,
                 UNORDERED_WS_FG,
                 RF_NETTABLE_DGI_WITHOUT_YIELD,
                 WS_NETTABLE_DGI_WITH_YIELD,
                 WS_NETTABLE_DGI_WITHOUT_YIELD,
                 POE_NETTABLE_DGI_WITH_YIELD,
                 POE_NETTABLE_DGI_WITHOUT_YIELD,
                 UNORDERED_FG,
                 TOTAL_NON_NETTABLE_PIPELINE,
                 RF_FG_ALLOCATION,
                 RF_DGI_ALLOCATION,
                 NETTABLE_DGI,
                 WS_ADJUSTED_FORECAST,
                 RF_ADJUSTED_FORECAST,
                 ADJUSTED_OVERRIDDEN_FORECAST,
                 RF_ADJ_OVERRIDDEN_FORECAST,
                 ADJUSTED_PID_PRIORITY,
                 ADJ_OVERRIDDEN_PID_PRIORITY
            FROM RC_SALES_FORECAST_STAGING);

      INSERT INTO CRPADM.RC_PROCESS_LOG
           VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                   'HISTORY',
                   'END',
                   SYSDATE);

      COMMIT;
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
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_HISTORY',
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
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_HISTORY',
            'PACKAGE',
            NULL,
            'Y');
   END;

   --PROCEDURE TO UPDATE/CALCULATE COLUMNS OTHER THAN SALES VIEW IN MAIN TABLE ON CLICK OF SUBMIT FROM SALES FORECAST UI

   PROCEDURE RC_SALES_FORECAST_ONSUBMIT (
      I_USER_ID            IN     VARCHAR2,
      I_FORECAST_QUARTER   IN     VARCHAR2,
      I_FORECAST_MONTH     IN     VARCHAR2,
      I_FORECAST_YEAR      IN     VARCHAR2,
      I_ACTION             IN     VARCHAR2,
      O_STATUS                OUT VARCHAR2)
   IS
      lv_forecast_quarter   VARCHAR2 (10 BYTE);
      lv_forecast_month     VARCHAR2 (10 BYTE);
      lv_forecast_year      VARCHAR2 (10 BYTE);
   BEGIN
      --Call to maintain history for the sales forecast.
      CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_HISTORY (I_USER_ID);

      lv_forecast_quarter := I_FORECAST_QUARTER;
      lv_forecast_month := I_FORECAST_MONTH;
      lv_forecast_year := I_FORECAST_YEAR;

      IF I_ACTION = 'ALLOC_CONFIG_UI'
      THEN
         UPDATE CRPSC.RC_AE_CONFIG_PROPERTIES
            SET CONFIG_VALUE = 'Y'
          WHERE     CONFIG_CATEGORY = 'MASTER_ADJUSTED_ALLOCATION'
                AND CONFIG_NAME = 'Master';

         COMMIT;
      END IF;

      --        UPDATE RC_SALES_FORECAST RSF
      UPDATE RC_SALES_FORECAST_STAGING RSF
         SET RSF.RF_SALES_3M =
                NVL (CRPREP.RC_SUPPLY_DEMAND_REPORT.GET_SALES_DATA (
                        'R3M_SALES',
                        'RETAIL',
                        3,
                        RSF.REFRESH_INVENTORY_ITEM_ID,
                        RSF.EXCESS_INVENTORY_ITEM_ID,
                        RSF.RETAIL_PART_NUMBER,
                        RSF.EXCESS_PART_NUMBER),
                     0),
             /*NVL (
                (SELECT NVL (RF_SALES_3M, 0)
                   FROM CRPREP.RC_SCRAP_REPORT RSP
                  WHERE RSP.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER),
                0),*/
             RSF.WS_SALES_3M =
                NVL (CRPREP.RC_SUPPLY_DEMAND_REPORT.GET_SALES_DATA (
                        'R3M_SALES',
                        'EXCESS',
                        3,
                        RSF.REFRESH_INVENTORY_ITEM_ID,
                        RSF.EXCESS_INVENTORY_ITEM_ID,
                        RSF.RETAIL_PART_NUMBER,
                        RSF.EXCESS_PART_NUMBER),
                     0),
             /*  NVL (
                  (SELECT NVL (EXCESS_SALES_3M, 0)
                     FROM CRPREP.RC_SCRAP_REPORT RSP
                    WHERE RSP.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER),
                  0),*/
             RSF.OUTLET_SALES_3M =
                NVL (CRPREP.RC_SUPPLY_DEMAND_REPORT.GET_SALES_DATA (
                        'R3M_SALES',
                        'OUTLET',
                        3,
                        RSF.REFRESH_INVENTORY_ITEM_ID,
                        RSF.EXCESS_INVENTORY_ITEM_ID,
                        RSF.RETAIL_PART_NUMBER,
                        RSF.EXCESS_PART_NUMBER),
                     0),
             /* NVL (
                 (SELECT NVL (OUTLET_SALES_3M, 0)
                    FROM CRPREP.RC_SCRAP_REPORT RSP
                   WHERE RSP.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER),
                 0),*/
             
             RSF.SUGGESTED_RF_MAX =
                NVL ( (SELECT SUM (SUGGESTED_MAX)
                         FROM CRPSC.RC_FORECASTING_CUMULATIVE
                        WHERE REFRESH_PART_NUMBER = RSF.RETAIL_PART_NUMBER),
                     0),
                 
             RSF.UNITS_REQB_CONSTRAINED =
                NVL (
                   (CASE
                       WHEN (RSF.SALES_RF_ALLOCATION - RSF.UNORDERED_FG) < 0
                       THEN
                          0
                       ELSE
                          LEAST (
                             (RSF.SALES_RF_ALLOCATION - RSF.UNORDERED_FG),
                             RSF.RF_NETTABLE_DGI_WITH_YIELD)
                    END),
                   0),
             RSF.UNITS_REQB_UNCONSTRAINED =
                NVL (
                   (CASE
                       WHEN (  (NVL (
                                   NVL (RSF.RF_ADJ_OVERRIDDEN_FORECAST,
                                        RSF.RF_ADJUSTED_FORECAST),
                                   RSF.RF_90DAY_FORECAST))
                             - RSF.UNORDERED_FG) < 0
                       THEN
                          0
                       ELSE
                          (  (NVL (
                                 NVL (RSF.RF_ADJ_OVERRIDDEN_FORECAST,
                                      RSF.RF_ADJUSTED_FORECAST),
                                 RSF.RF_90DAY_FORECAST))
                           - RSF.UNORDERED_FG)
                    END),
                   0),
             /*---17Jun20: Start Commented --- Duplicate data in Demand Automation table causing issue in SF FY Q420 M2*/       
             --             RSF.SYSTEM_DEMAND =
             --                NVL (
             --                   NVL ( (SELECT DEMAND_MAX
             --                            FROM CRPADM.RC_FIN_DEMAND_LIST RFD
             --                           WHERE RFD.PRODUCT_NAME = RSF.COMMON_PART_NUMBER),
             --                        (SELECT DEMAND_MAX
             --                           FROM CRPADM.RC_FIN_DEMAND_LIST RFD
             --                          WHERE RFD.PRODUCT_NAME = RSF.XREF_PART_NUMBER)),
             --                   0),
             /*..17Jun20: End Commented ---*/
             /*--- 17Jun20:New code Start--- Duplicate data in Demand Automation table causing issue in SF FY Q420 M2*/
             RSF.SYSTEM_DEMAND =
                (CASE
                    WHEN (SELECT COUNT (RFD.PRODUCT_NAME)
                            FROM CRPADM.RC_FIN_DEMAND_LIST RFD
                           WHERE RFD.PRODUCT_NAME = RSF.COMMON_PART_NUMBER) =
                            1
                    THEN
                       (SELECT DEMAND_MAX
                          FROM CRPADM.RC_FIN_DEMAND_LIST RFD
                         WHERE RFD.PRODUCT_NAME = RSF.COMMON_PART_NUMBER)
                    WHEN (SELECT COUNT (RFD.PRODUCT_NAME)
                            FROM CRPADM.RC_FIN_DEMAND_LIST RFD
                           WHERE RFD.PRODUCT_NAME = RSF.COMMON_PART_NUMBER) >
                            1
                    THEN
                       (SELECT DEMAND_MAX
                          FROM CRPADM.RC_FIN_DEMAND_LIST RFD
                         WHERE     RFD.PRODUCT_NAME = RSF.COMMON_PART_NUMBER
                               AND RFD.REFRESH_LIFE_CYCLE = 'CUR')
                    WHEN (SELECT COUNT (RFD.PRODUCT_NAME)
                            FROM CRPADM.RC_FIN_DEMAND_LIST RFD
                           WHERE RFD.PRODUCT_NAME = RSF.XREF_PART_NUMBER) = 1
                    THEN
                       (SELECT DEMAND_MAX
                          FROM CRPADM.RC_FIN_DEMAND_LIST RFD
                         WHERE RFD.PRODUCT_NAME = RSF.XREF_PART_NUMBER)
                    WHEN (SELECT COUNT (RFD.PRODUCT_NAME)
                            FROM CRPADM.RC_FIN_DEMAND_LIST RFD
                           WHERE RFD.PRODUCT_NAME = RSF.XREF_PART_NUMBER) > 1
                    THEN
                       (SELECT DEMAND_MAX
                          FROM CRPADM.RC_FIN_DEMAND_LIST RFD
                         WHERE     RFD.PRODUCT_NAME = RSF.XREF_PART_NUMBER
                               AND RFD.REFRESH_LIFE_CYCLE = 'CUR')
                    ELSE
                       0
                 END),
             /*..17Jun20:New Code End  ---*/ 
             RSF.REFRESH_YIELD =
                NVL (
                   (SELECT MAX (RP.REFRESH_YIELD)
                      FROM CRPADM.RC_PRODUCT_REPAIR_SETUP RP
                     WHERE     RP.REFRESH_PART_NUMBER =
                                  NVL (RSF.RETAIL_PART_NUMBER,
                                       RSF.EXCESS_PART_NUMBER)
                           AND RP.REFRESH_STATUS = 'ACTIVE'
                           AND RP.REFRESH_METHOD_ID =
                                  (SELECT MIN (RS.REFRESH_METHOD_ID)
                                     FROM RC_PRODUCT_REPAIR_SETUP RS
                                    WHERE     RS.REFRESH_PART_NUMBER =
                                                 NVL (RSF.RETAIL_PART_NUMBER,
                                                      RSF.EXCESS_PART_NUMBER)
                                          AND RS.REFRESH_STATUS = 'ACTIVE')),
                   0),
             RSF.SALES_FORECAST_12M =
                NVL (
                   (  (  (NVL (
                             NVL (RSF.RF_ADJ_OVERRIDDEN_FORECAST,
                                  RSF.RF_ADJUSTED_FORECAST),
                             RSF.RF_90DAY_FORECAST))
                       + (NVL (RSF.WS_ADJUSTED_FORECAST,
                               RSF.WS_90DAY_FORECAST)))
                    * 4),
                   0)
       WHERE     FORECAST_QUARTER = lv_forecast_quarter
             AND FORECAST_MONTH = lv_forecast_month
             AND FORECAST_YEAR = lv_forecast_year;

      --  WHERE RSF.APPROVAL_STATUS = 'DRAFT';


      --        UPDATE RC_SALES_FORECAST RSF
      UPDATE RC_SALES_FORECAST_STAGING RSF
         SET RSF.TOTAL_NEW_MAX =
                NVL (
                   GREATEST (
                      NVL (
                         (NVL (
                             NVL (RSF.RF_ADJ_OVERRIDDEN_FORECAST,
                                  RSF.RF_ADJUSTED_FORECAST),
                             RSF.RF_90DAY_FORECAST)),
                         0),
                      NVL ( (RSF.RF_SALES_3M + RSF.OUTLET_SALES_3M), 0),
                      NVL (RSF.SUGGESTED_RF_MAX, 0)),
                   0),
             RSF.NEW_DEMAND =
                NVL (
                   GREATEST (
                      ROUND (
                           ( (1 - (RSF.REFRESH_YIELD / 100)) + 1)
                         * (  RSF.SALES_FORECAST_12M
                            - RSF.TOTAL_NETTABLE_PIPELINE),
                         0),
                      RSF.SYSTEM_DEMAND),
                   0)
       WHERE     FORECAST_QUARTER = lv_forecast_quarter
             AND FORECAST_MONTH = lv_forecast_month
             AND FORECAST_YEAR = lv_forecast_year;

      -- WHERE RSF.APPROVAL_STATUS = 'DRAFT';

      --        UPDATE RC_SALES_FORECAST RSF
      UPDATE RC_SALES_FORECAST_STAGING RSF
         SET RSF.NAM_RF_NEW_MAX =
                (CASE
                    WHEN     NVL (
                                (SELECT SUM (TOTAL_QTY)
                                   FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
                                  WHERE     REFRESH_INVENTORY_ITEM_ID =
                                               RSF.REFRESH_INVENTORY_ITEM_ID
                                        AND THEATER_ID = 1),
                                0) > 0
                         AND RSF.TOTAL_NEW_MAX > 0
                    THEN
                       NVL (
                          CEIL (
                               (  (  (  (SELECT SUM (TOTAL_QTY)
                                           FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
                                          WHERE     REFRESH_INVENTORY_ITEM_ID =
                                                       RSF.REFRESH_INVENTORY_ITEM_ID
                                                AND THEATER_ID = 1)
                                      / (SELECT SUM (TOTAL_QTY)
                                           FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
                                          WHERE REFRESH_INVENTORY_ITEM_ID =
                                                   RSF.REFRESH_INVENTORY_ITEM_ID))
                                   * 100)
                                * RSF.TOTAL_NEW_MAX)
                             / 100),
                          0)
                    WHEN     NVL (
                                (SELECT SUM (TOTAL_QTY)
                                   FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
                                  WHERE     REFRESH_INVENTORY_ITEM_ID =
                                               RSF.REFRESH_INVENTORY_ITEM_ID
                                        AND THEATER_ID = 1),
                                0) > 0
                         AND RSF.TOTAL_NEW_MAX = 0
                    THEN
                       1
                    WHEN     NVL (
                                (SELECT SUM (TOTAL_QTY)
                                   FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
                                  WHERE     REFRESH_INVENTORY_ITEM_ID =
                                               RSF.REFRESH_INVENTORY_ITEM_ID
                                        AND THEATER_ID = 3),
                                0) = 0
                         AND RSF.TOTAL_NEW_MAX > 0
                    THEN
                       1
                    WHEN     NVL (
                                (SELECT SUM (TOTAL_QTY)
                                   FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
                                  WHERE     REFRESH_INVENTORY_ITEM_ID =
                                               RSF.REFRESH_INVENTORY_ITEM_ID
                                        AND THEATER_ID = 3),
                                0) = 0
                         AND RSF.TOTAL_NEW_MAX = 0
                         AND RSF.RETAIL_PART_NUMBER IS NOT NULL
                    THEN
                       1
                    ELSE
                       0
                 END),
             RSF.EMEA_RF_NEW_MAX =
                (CASE
                    WHEN NVL (
                            (SELECT SUM (TOTAL_QTY)
                               FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
                              WHERE     REFRESH_INVENTORY_ITEM_ID =
                                           RSF.REFRESH_INVENTORY_ITEM_ID
                                    AND THEATER_ID = 3),
                            0) > 0
                    THEN
                       NVL (
                          FLOOR (
                               (  (  (  (SELECT SUM (TOTAL_QTY)
                                           FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
                                          WHERE     REFRESH_INVENTORY_ITEM_ID =
                                                       RSF.REFRESH_INVENTORY_ITEM_ID
                                                AND THEATER_ID = 3)
                                      / (SELECT SUM (TOTAL_QTY)
                                           FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
                                          WHERE REFRESH_INVENTORY_ITEM_ID =
                                                   RSF.REFRESH_INVENTORY_ITEM_ID))
                                   * 100)
                                * RSF.TOTAL_NEW_MAX)
                             / 100),
                          0)
                    ELSE
                       0
                 END),
             RSF.UNITS_REQ_BUILD =
                NVL (
                   (CASE
                       WHEN (RSF.UNORDERED_FG < RSF.TOTAL_NEW_MAX)
                       THEN
                          (CASE
                              WHEN ( (RSF.TOTAL_NEW_MAX - RSF.UNORDERED_FG) <
                                       RSF.TOTAL_NETTABLE_PIPELINE)
                              THEN
                                 (RSF.TOTAL_NEW_MAX - RSF.UNORDERED_FG)
                              ELSE
                                 GREATEST (
                                    (  RSF.TOTAL_NETTABLE_PIPELINE
                                     - RSF.UNORDERED_FG),
                                    0)
                           END)
                       ELSE
                          0
                    END),
                   0)
       WHERE     FORECAST_QUARTER = lv_forecast_quarter
             AND FORECAST_MONTH = lv_forecast_month
             AND FORECAST_YEAR = lv_forecast_year;

      --  WHERE RSF.APPROVAL_STATUS = 'DRAFT';
      --        UPDATE RC_SALES_FORECAST RSF
      UPDATE RC_SALES_FORECAST_STAGING RSF
         SET RSF.nam_rf_new_max = CEIL (.70 * RSF.total_new_max),
             RSF.emea_rf_new_max =
                (RSF.total_new_max - CEIL (0.70 * RSF.total_new_max))
       WHERE     RSF.retail_part_number IN
                    (SELECT RS.retail_part_number
                       --                      FROM rc_sales_forecast RS
                       FROM RC_SALES_FORECAST_STAGING RS
                      WHERE     RS.total_new_max > 0
                            AND (RS.nam_rf_new_max + RS.emea_rf_new_max) <
                                   (RS.total_new_max - 1))
             AND FORECAST_QUARTER = lv_forecast_quarter
             AND FORECAST_MONTH = lv_forecast_month
             AND FORECAST_YEAR = lv_forecast_year;

      --        UPDATE RC_SALES_FORECAST RSF
      UPDATE RC_SALES_FORECAST_STAGING RSF
         SET RSF.RF_EXPECTED_REPAIR_COST =
                NVL (
                   ROUND (
                        (  (  (NVL (
                                  (SELECT MAX (REPAIR_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.RETAIL_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.RETAIL_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.RETAIL_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                1))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 1
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.RETAIL_PART_NUMBER)
                         --* RSF.UNITS_REQB_CONSTRAINED)
                         * RSF.UNITS_REQ_BUILD)
                      + (  (  (NVL (
                                  (SELECT MAX (TEST_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.RETAIL_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.RETAIL_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.RETAIL_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                2))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 2
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.RETAIL_PART_NUMBER)
                         -- * RSF.UNITS_REQB_CONSTRAINED)
                         * RSF.UNITS_REQ_BUILD)
                      + (  (  (NVL (
                                  (SELECT MAX (SCREEN_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.RETAIL_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                34
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.RETAIL_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.RETAIL_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                3))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 3
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.RETAIL_PART_NUMBER)
                         --* RSF.UNITS_REQB_CONSTRAINED),
                         * RSF.UNITS_REQ_BUILD),
                      2),
                   0),
             RSF.WS_EXPECTED_REPAIR_COST =
                NVL (
                   ROUND (
                        (  (  (NVL (
                                  (SELECT MAX (REPAIR_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.EXCESS_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.EXCESS_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.EXCESS_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                1))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 1
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.EXCESS_PART_NUMBER)
                         * RSF.WS_ALLOCATION)
                      + (  (  (NVL (
                                  (SELECT MAX (TEST_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.EXCESS_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.EXCESS_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.EXCESS_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                2))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 2
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.EXCESS_PART_NUMBER)
                         * RSF.WS_ALLOCATION)
                      + (  (  (NVL (
                                  (SELECT MAX (SCREEN_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.EXCESS_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                34
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.EXCESS_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.EXCESS_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                3))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 3
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.EXCESS_PART_NUMBER)
                         * RSF.WS_ALLOCATION),
                      2),
                   0),
             RSF.RF_FORECASTED_REPAIR_COST =
                NVL (
                   ROUND (
                        (  (  (NVL (
                                  (SELECT MAX (REPAIR_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.RETAIL_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.RETAIL_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.RETAIL_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                1))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 1
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.RETAIL_PART_NUMBER)
                         * RSF.UNITS_REQB_UNCONSTRAINED)
                      + (  (  (NVL (
                                  (SELECT MAX (TEST_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.RETAIL_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.RETAIL_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.RETAIL_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                2))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 2
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.RETAIL_PART_NUMBER)
                         * RSF.UNITS_REQB_UNCONSTRAINED)
                      + (  (  (NVL (
                                  (SELECT MAX (SCREEN_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.RETAIL_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                34
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.RETAIL_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.RETAIL_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                3))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 3
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.RETAIL_PART_NUMBER)
                         * RSF.UNITS_REQB_UNCONSTRAINED),
                      2),
                   0),
             RSF.WS_FORECASTED_REPAIR_COST =
                NVL (
                   ROUND (
                        (  (  (NVL (
                                  (SELECT MAX (REPAIR_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.EXCESS_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.EXCESS_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.EXCESS_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                1))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 1
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.EXCESS_PART_NUMBER)
                         * (NVL (RSF.WS_ADJUSTED_FORECAST,
                                 RSF.WS_90DAY_FORECAST)))
                      + (  (  (NVL (
                                  (SELECT MAX (TEST_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.EXCESS_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.EXCESS_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.EXCESS_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                2))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 2
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.EXCESS_PART_NUMBER)
                         * (NVL (RSF.WS_ADJUSTED_FORECAST,
                                 RSF.WS_90DAY_FORECAST)))
                      + (  (  (NVL (
                                  (SELECT MAX (SCREEN_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.EXCESS_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                34
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.EXCESS_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.EXCESS_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                3))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 3
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.EXCESS_PART_NUMBER)
                         * (NVL (RSF.WS_ADJUSTED_FORECAST,
                                 RSF.WS_90DAY_FORECAST))),
                      2),
                   0)
       WHERE     FORECAST_QUARTER = lv_forecast_quarter
             AND FORECAST_MONTH = lv_forecast_month
             AND FORECAST_YEAR = lv_forecast_year;

      -- WHERE RSF.APPROVAL_STATUS = 'DRAFT';

      --        UPDATE RC_SALES_FORECAST RSF
      UPDATE RC_SALES_FORECAST_STAGING RSF
         SET RSF.TOTAL_EXPECTED_REPAIR_COST =
                NVL (
                   (RSF.RF_EXPECTED_REPAIR_COST + RSF.WS_EXPECTED_REPAIR_COST),
                   0),
             RSF.TOTAL_FORECASTED_REPAIR_COST =
                NVL (
                   (  RSF.RF_FORECASTED_REPAIR_COST
                    + RSF.WS_FORECASTED_REPAIR_COST),
                   0)
       WHERE     FORECAST_QUARTER = lv_forecast_quarter
             AND FORECAST_MONTH = lv_forecast_month
             AND FORECAST_YEAR = lv_forecast_year;

      --  WHERE RSF.APPROVAL_STATUS = 'DRAFT';

      --        UPDATE RC_SALES_FORECAST RSF
      UPDATE RC_SALES_FORECAST_STAGING RSF
         SET RSF.TOTL_EXPCTD_SALES_REPAIR_COST =
                NVL (
                   (                          -- SALES_RF_EXPECTED_REPAIR_COST
                    NVL (
                         ROUND (
                              (  (  (NVL (
                                        (SELECT MAX (REPAIR_PERCENTAGE)
                                           FROM RC_SALES_FORECAST_REPAIR_PERC
                                          WHERE PART_NUMBER =
                                                   RSF.RETAIL_PART_NUMBER),
                                        (SELECT CASE
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           1
                                                   THEN
                                                      100
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           2
                                                   THEN
                                                      50
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           3
                                                   THEN
                                                      33
                                                   ELSE
                                                      0
                                                END
                                           FROM RC_PRODUCT_REPAIR_SETUP
                                          WHERE     REFRESH_PART_NUMBER =
                                                       RSF.RETAIL_PART_NUMBER
                                                AND EXISTS
                                                       (SELECT 1
                                                          FROM RC_PRODUCT_REPAIR_SETUP
                                                         WHERE     REFRESH_PART_NUMBER =
                                                                      RSF.RETAIL_PART_NUMBER
                                                               AND REFRESH_METHOD_ID =
                                                                      1))))
                                  / 100)
                               * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                                    FROM RC_PRODUCT_REPAIR_SETUP
                                   WHERE     REFRESH_METHOD_ID = 1
                                         AND REFRESH_STATUS NOT IN
                                                ('DEACTIVATED', 'INACTIVE')
                                         AND REFRESH_PART_NUMBER =
                                                RSF.RETAIL_PART_NUMBER)
                               * RSF.UNITS_REQB_CONSTRAINED)
                            + (  (  (NVL (
                                        (SELECT MAX (TEST_PERCENTAGE)
                                           FROM RC_SALES_FORECAST_REPAIR_PERC
                                          WHERE PART_NUMBER =
                                                   RSF.RETAIL_PART_NUMBER),
                                        (SELECT CASE
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           1
                                                   THEN
                                                      100
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           2
                                                   THEN
                                                      50
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           3
                                                   THEN
                                                      33
                                                   ELSE
                                                      0
                                                END
                                           FROM RC_PRODUCT_REPAIR_SETUP
                                          WHERE     REFRESH_PART_NUMBER =
                                                       RSF.RETAIL_PART_NUMBER
                                                AND EXISTS
                                                       (SELECT 1
                                                          FROM RC_PRODUCT_REPAIR_SETUP
                                                         WHERE     REFRESH_PART_NUMBER =
                                                                      RSF.RETAIL_PART_NUMBER
                                                               AND REFRESH_METHOD_ID =
                                                                      2))))
                                  / 100)
                               * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                                    FROM RC_PRODUCT_REPAIR_SETUP
                                   WHERE     REFRESH_METHOD_ID = 2
                                         AND REFRESH_STATUS NOT IN
                                                ('DEACTIVATED', 'INACTIVE')
                                         AND REFRESH_PART_NUMBER =
                                                RSF.RETAIL_PART_NUMBER)
                               * RSF.UNITS_REQB_CONSTRAINED)
                            + (  (  (NVL (
                                        (SELECT MAX (SCREEN_PERCENTAGE)
                                           FROM RC_SALES_FORECAST_REPAIR_PERC
                                          WHERE PART_NUMBER =
                                                   RSF.RETAIL_PART_NUMBER),
                                        (SELECT CASE
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           1
                                                   THEN
                                                      100
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           2
                                                   THEN
                                                      50
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           3
                                                   THEN
                                                      34
                                                   ELSE
                                                      0
                                                END
                                           FROM RC_PRODUCT_REPAIR_SETUP
                                          WHERE     REFRESH_PART_NUMBER =
                                                       RSF.RETAIL_PART_NUMBER
                                                AND EXISTS
                                                       (SELECT 1
                                                          FROM RC_PRODUCT_REPAIR_SETUP
                                                         WHERE     REFRESH_PART_NUMBER =
                                                                      RSF.RETAIL_PART_NUMBER
                                                               AND REFRESH_METHOD_ID =
                                                                      3))))
                                  / 100)
                               * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                                    FROM RC_PRODUCT_REPAIR_SETUP
                                   WHERE     REFRESH_METHOD_ID = 3
                                         AND REFRESH_STATUS NOT IN
                                                ('DEACTIVATED', 'INACTIVE')
                                         AND REFRESH_PART_NUMBER =
                                                RSF.RETAIL_PART_NUMBER)
                               * RSF.UNITS_REQB_CONSTRAINED),
                            2),
                         0)
                    +                         -- SALES_WS_EXPECTED_REPAIR_COST
                      -- RSF.WS_EXPECTED_REPAIR_COST
                      NVL (
                         ROUND (
                              (  (  (NVL (
                                        (SELECT MAX (REPAIR_PERCENTAGE)
                                           FROM RC_SALES_FORECAST_REPAIR_PERC
                                          WHERE PART_NUMBER =
                                                   RSF.EXCESS_PART_NUMBER),
                                        (SELECT CASE
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           1
                                                   THEN
                                                      100
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           2
                                                   THEN
                                                      50
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           3
                                                   THEN
                                                      33
                                                   ELSE
                                                      0
                                                END
                                           FROM RC_PRODUCT_REPAIR_SETUP
                                          WHERE     REFRESH_PART_NUMBER =
                                                       RSF.EXCESS_PART_NUMBER
                                                AND EXISTS
                                                       (SELECT 1
                                                          FROM RC_PRODUCT_REPAIR_SETUP
                                                         WHERE     REFRESH_PART_NUMBER =
                                                                      RSF.EXCESS_PART_NUMBER
                                                               AND REFRESH_METHOD_ID =
                                                                      1))))
                                  / 100)
                               * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                                    FROM RC_PRODUCT_REPAIR_SETUP
                                   WHERE     REFRESH_METHOD_ID = 1
                                         AND REFRESH_STATUS NOT IN
                                                ('DEACTIVATED', 'INACTIVE')
                                         AND REFRESH_PART_NUMBER =
                                                RSF.EXCESS_PART_NUMBER)
                               * RSF.SALES_WS_ALLOCATION)
                            + (  (  (NVL (
                                        (SELECT MAX (TEST_PERCENTAGE)
                                           FROM RC_SALES_FORECAST_REPAIR_PERC
                                          WHERE PART_NUMBER =
                                                   RSF.EXCESS_PART_NUMBER),
                                        (SELECT CASE
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           1
                                                   THEN
                                                      100
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           2
                                                   THEN
                                                      50
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           3
                                                   THEN
                                                      33
                                                   ELSE
                                                      0
                                                END
                                           FROM RC_PRODUCT_REPAIR_SETUP
                                          WHERE     REFRESH_PART_NUMBER =
                                                       RSF.EXCESS_PART_NUMBER
                                                AND EXISTS
                                                       (SELECT 1
                                                          FROM RC_PRODUCT_REPAIR_SETUP
                                                         WHERE     REFRESH_PART_NUMBER =
                                                                      RSF.EXCESS_PART_NUMBER
                                                               AND REFRESH_METHOD_ID =
                                                                      2))))
                                  / 100)
                               * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                                    FROM RC_PRODUCT_REPAIR_SETUP
                                   WHERE     REFRESH_METHOD_ID = 2
                                         AND REFRESH_STATUS NOT IN
                                                ('DEACTIVATED', 'INACTIVE')
                                         AND REFRESH_PART_NUMBER =
                                                RSF.EXCESS_PART_NUMBER)
                               * RSF.SALES_WS_ALLOCATION)
                            + (  (  (NVL (
                                        (SELECT MAX (SCREEN_PERCENTAGE)
                                           FROM RC_SALES_FORECAST_REPAIR_PERC
                                          WHERE PART_NUMBER =
                                                   RSF.EXCESS_PART_NUMBER),
                                        (SELECT CASE
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           1
                                                   THEN
                                                      100
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           2
                                                   THEN
                                                      50
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           3
                                                   THEN
                                                      34
                                                   ELSE
                                                      0
                                                END
                                           FROM RC_PRODUCT_REPAIR_SETUP
                                          WHERE     REFRESH_PART_NUMBER =
                                                       RSF.EXCESS_PART_NUMBER
                                                AND EXISTS
                                                       (SELECT 1
                                                          FROM RC_PRODUCT_REPAIR_SETUP
                                                         WHERE     REFRESH_PART_NUMBER =
                                                                      RSF.EXCESS_PART_NUMBER
                                                               AND REFRESH_METHOD_ID =
                                                                      3))))
                                  / 100)
                               * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                                    FROM RC_PRODUCT_REPAIR_SETUP
                                   WHERE     REFRESH_METHOD_ID = 3
                                         AND REFRESH_STATUS NOT IN
                                                ('DEACTIVATED', 'INACTIVE')
                                         AND REFRESH_PART_NUMBER =
                                                RSF.EXCESS_PART_NUMBER)
                               * RSF.SALES_WS_ALLOCATION),
                            2),
                         0)),
                   0)
       WHERE     FORECAST_QUARTER = lv_forecast_quarter
             AND FORECAST_MONTH = lv_forecast_month
             AND FORECAST_YEAR = lv_forecast_year;


      --        UPDATE RC_SALES_FORECAST RSF
      UPDATE RC_SALES_FORECAST_STAGING RSF
         SET RSF.UPDATED_BY = I_USER_ID,
             RSF.UPDATED_ON = SYSDATE,
             RSF.SUBMITTED_AT = SYSDATE,
             RSF.APPROVAL_STATUS = 'SUBMITTED'
       WHERE     RSF.APPROVAL_STATUS = 'DRAFT'
             AND FORECAST_QUARTER = lv_forecast_quarter
             AND FORECAST_MONTH = lv_forecast_month
             AND FORECAST_YEAR = lv_forecast_year;

      COMMIT;

      --CALL TO UPSERT HISTORY FOR THE SALES FORECAST DETAILS
      --CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_HISTORY;

      --        UPDATE RC_SALES_FORECAST RSF
      UPDATE RC_SALES_FORECAST_STAGING RSF
         SET NAM_RF_MAX_PERC =
                (CASE
                    WHEN (SELECT SUM (TOTAL_QTY)
                            FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
                           WHERE     REFRESH_INVENTORY_ITEM_ID =
                                        RSF.REFRESH_INVENTORY_ITEM_ID
                                 AND THEATER_ID = 1) > 0
                    THEN
                       (  (  (SELECT SUM (TOTAL_QTY)
                                FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
                               WHERE     REFRESH_INVENTORY_ITEM_ID =
                                            RSF.REFRESH_INVENTORY_ITEM_ID
                                     AND THEATER_ID = 1)
                           / (SELECT SUM (TOTAL_QTY)
                                FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
                               WHERE REFRESH_INVENTORY_ITEM_ID =
                                        RSF.REFRESH_INVENTORY_ITEM_ID))
                        * 100)
                    ELSE
                       0
                 END),
             EMEA_RF_MAX_PERC =
                (CASE
                    WHEN (SELECT SUM (TOTAL_QTY)
                            FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
                           WHERE     REFRESH_INVENTORY_ITEM_ID =
                                        RSF.REFRESH_INVENTORY_ITEM_ID
                                 AND THEATER_ID = 3) > 0
                    THEN
                       (  (  (SELECT SUM (TOTAL_QTY)
                                FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
                               WHERE     REFRESH_INVENTORY_ITEM_ID =
                                            RSF.REFRESH_INVENTORY_ITEM_ID
                                     AND THEATER_ID = 3)
                           / (SELECT SUM (TOTAL_QTY)
                                FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
                               WHERE REFRESH_INVENTORY_ITEM_ID =
                                        RSF.REFRESH_INVENTORY_ITEM_ID))
                        * 100)
                    ELSE
                       0
                 END)
       WHERE     RSF.REFRESH_INVENTORY_ITEM_ID IN
                    (SELECT RSF.REFRESH_INVENTORY_ITEM_ID
                       --                      FROM RC_SALES_FORECAST IRSF
                       FROM RC_SALES_FORECAST_STAGING IRSF
                      WHERE     IRSF.APPROVAL_STATUS = 'SUBMITTED'
                            AND IRSF.REFRESH_INVENTORY_ITEM_ID =
                                   RSF.REFRESH_INVENTORY_ITEM_ID)
             AND FORECAST_QUARTER = lv_forecast_quarter
             AND FORECAST_MONTH = lv_forecast_month
             AND FORECAST_YEAR = lv_forecast_year;

      O_STATUS := 'SUCCESS';

      IF (O_STATUS = 'SUCCESS')
      THEN
         --         UPDATE RC_PROPERTIES
         --            SET PROPERTY_VALUE = 'Y',
         --                UPDATED_BY = I_USER_ID,
         --                UPDATED_ON = SYSDATE
         --          WHERE PROPERTY_TYPE = 'IS_FORECAST_SUBMITTED';

         UPDATE RC_SALES_FORECAST_CONFIG
            SET IS_SUBMITTED = 'Y',
                SUBMITTED_ON = SYSDATE,
                SUBMITTED_BY = I_USER_ID
          WHERE     FORECAST_QUARTER = lv_forecast_quarter
                AND FORECAST_MONTH = lv_forecast_month
                AND FORECAST_YEAR = lv_forecast_year;

         -- UPDATE STAGING FINANCIAL SUMMARY TABLE
         UPDATE RC_SALES_FORECAST_STG_FINSUM
            SET SUBMITTED_AT = SYSDATE
          WHERE     FORECAST_QUARTER = lv_forecast_quarter
                AND FORECAST_MONTH = lv_forecast_month
                AND FORECAST_YEAR = lv_forecast_year;
      END IF;

      COMMIT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         O_STATUS := 'FAILED';
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'NO DATA FOUND',
            G_ERROR_MSG,
            NULL,
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_ONSUBMIT',
            'PACKAGE',
            NULL,
            'N');
      WHEN OTHERS
      THEN
         O_STATUS := 'FAILED';
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
            G_ERROR_MSG,
            NULL,
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_ONSUBMIT',
            'PACKAGE',
            NULL,
            'Y');
   END;

   PROCEDURE RC_SALES_FORECAST_ONAPPROVE (
      I_USER_ID            IN     VARCHAR2,
      I_FORECAST_QUARTER   IN     VARCHAR2,
      I_FORECAST_MONTH     IN     VARCHAR2,
      I_FORECAST_YEAR      IN     VARCHAR2,
      O_STATUS                OUT VARCHAR2)
   IS
      lv_forecast_quarter   VARCHAR2 (10 BYTE);
      lv_forecast_month     VARCHAR2 (10 BYTE);
      lv_forecast_year      VARCHAR2 (10 BYTE);
   BEGIN
      lv_forecast_quarter := I_FORECAST_QUARTER;
      lv_forecast_month := I_FORECAST_MONTH;
      lv_forecast_year := I_FORECAST_YEAR;

      --CALL TO UPDATE HISTORY FOR THE SALES FORECAST DETAILS
      CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_HISTORY (I_USER_ID);

      --        UPDATE RC_SALES_FORECAST RSF
      UPDATE RC_SALES_FORECAST_STAGING RSF
         SET RSF.UPDATED_BY = I_USER_ID,
             RSF.UPDATED_ON = SYSDATE,
             RSF.APPROVED_AT = SYSDATE,
             RSF.APPROVAL_STATUS = 'APPROVED'
       WHERE     RSF.APPROVAL_STATUS = 'SUBMITTED'
             AND FORECAST_QUARTER = lv_forecast_quarter
             AND FORECAST_MONTH = lv_forecast_month
             AND FORECAST_YEAR = lv_forecast_year;

      COMMIT;

      O_STATUS := 'SUCCESS';

      IF (O_STATUS = 'SUCCESS')
      THEN
         --         UPDATE RC_PROPERTIES
         --            SET PROPERTY_VALUE = 'Y',
         --                UPDATED_BY = I_USER_ID,
         --                UPDATED_ON = SYSDATE
         --          WHERE PROPERTY_TYPE = 'IS_FORECAST_APPROVED';

         UPDATE RC_SALES_FORECAST_CONFIG
            SET IS_APPROVED = 'Y',
                APPROVED_ON = SYSDATE,
                APPROVED_BY = I_USER_ID,
                IS_UPLOAD_ENABLED = 'N'
          WHERE     FORECAST_QUARTER = lv_forecast_quarter
                AND FORECAST_MONTH = lv_forecast_month
                AND FORECAST_YEAR = lv_forecast_year;

         --Setting the is_upload_enabled_flag for all the previous months of the currently approved month to 'N'

         MERGE INTO rc_sales_forecast_config config
              USING (  SELECT DISTINCT forecast_year,
                                       forecast_quarter,
                                       forecast_month,
                                       fiscal_quarter_key,
                                       fiscal_month_number,
                                       fiscal_month_key
                         FROM rc_sales_forecast_config config
                              JOIN rmktgadm.cdm_time_hierarchy_dim dim
                                 ON (    config.forecast_quarter =
                                            dim.fiscal_quarter_name
                                     AND forecast_month =
                                            CASE
                                               WHEN MOD (fiscal_month_number,
                                                         3) = 1
                                               THEN
                                                  'M1'
                                               WHEN MOD (fiscal_month_number,
                                                         3) = 2
                                               THEN
                                                  'M2'
                                               WHEN MOD (fiscal_month_number,
                                                         3) = 0
                                               THEN
                                                  'M3'
                                            END)
                        WHERE fiscal_month_key <
                                 (SELECT DISTINCT fiscal_month_key
                                    FROM rc_sales_forecast sf
                                         JOIN
                                         rmktgadm.cdm_time_hierarchy_dim dim
                                            ON (    sf.forecast_quarter =
                                                       dim.fiscal_quarter_name
                                                AND sf.forecast_month =
                                                       CASE
                                                          WHEN MOD (
                                                                  fiscal_month_number,
                                                                  3) = 1
                                                          THEN
                                                             'M1'
                                                          WHEN MOD (
                                                                  fiscal_month_number,
                                                                  3) = 2
                                                          THEN
                                                             'M2'
                                                          WHEN MOD (
                                                                  fiscal_month_number,
                                                                  3) = 0
                                                          THEN
                                                             'M3'
                                                       END))
                     ORDER BY forecast_year, forecast_quarter, forecast_month)
                    sf
                 ON (    config.forecast_quarter = sf.forecast_quarter
                     AND config.forecast_year = sf.forecast_year
                     AND config.forecast_month = sf.forecast_month)
         WHEN MATCHED
         THEN
            UPDATE SET config.is_upload_enabled = 'N';



         -- UPDATE STAGING FINANCIAL SUMMARY TABLE
         UPDATE RC_SALES_FORECAST_STG_FINSUM
            SET APPROVED_AT = SYSDATE
          WHERE     FORECAST_QUARTER = lv_forecast_quarter
                AND FORECAST_MONTH = lv_forecast_month
                AND FORECAST_YEAR = lv_forecast_year;

         UPDATE CRPSC.RC_AE_CONFIG_PROPERTIES
            SET CONFIG_VALUE = 'Y'
          WHERE     CONFIG_CATEGORY = 'ALLOC_CONFIG_UI'
                AND CONFIG_NAME = 'REVIEW_FLAG';
      END IF;

      COMMIT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         O_STATUS := 'FAILED';
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'NO DATA FOUND',
            G_ERROR_MSG,
            NULL,
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_ONAPPROVE',
            'PACKAGE',
            NULL,
            'N');
      WHEN OTHERS
      THEN
         O_STATUS := 'FAILED';
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
            G_ERROR_MSG,
            NULL,
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_ONAPPROVE',
            'PACKAGE',
            NULL,
            'Y');
   END;

   PROCEDURE RC_SALES_FORECAST_ONPUBLISH (
      I_USER_ID            IN     VARCHAR2,
      I_FORECAST_QUARTER   IN     VARCHAR2,
      I_FORECAST_MONTH     IN     VARCHAR2,
      I_FORECAST_YEAR      IN     VARCHAR2,
      O_STATUS                OUT VARCHAR2)
   IS
      lv_forecast_quarter      VARCHAR2 (10 BYTE);
      lv_forecast_month        VARCHAR2 (10 BYTE);
      lv_forecast_year         VARCHAR2 (10 BYTE);
      TRUNC_SFMAIN_TBL_QUERY   VARCHAR2 (100)
                                  := 'TRUNCATE TABLE RC_SALES_FORECAST';
   BEGIN
      lv_forecast_quarter := I_FORECAST_QUARTER;
      lv_forecast_month := I_FORECAST_MONTH;
      lv_forecast_year := I_FORECAST_YEAR;

      --      INSERT INTO TEMP_QUERY
      --              VALUES (
      --                           'I_FORECAST_QUARTER: '
      --                        || I_FORECAST_QUARTER
      --                        || ' I_FORECAST_MONTH: '
      --                        || I_FORECAST_MONTH
      --                        || ' I_FORECAST_YEAR: '
      --                        || I_FORECAST_YEAR,
      --                        SYSDATE);

      --CALL TO UPDATE HISTORY FOR THE SALES FORECAST DETAILS
      CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_HISTORY (I_USER_ID);

      BEGIN
         EXECUTE IMMEDIATE TRUNC_SFMAIN_TBL_QUERY;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            G_ERROR_MSG :=
                  'ERROR WHILE TABLE TRUNCATE: '
               || SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 20);

            CRPADM.RC_GLOBAL_ERROR_LOGGING (
               'OTHERS',
               G_ERROR_MSG,
               NULL,
               'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_ONPUBLISH',
               'PACKAGE',
               NULL,
               'Y');

            COMMIT;
      END;

      UPDATE CRPSC.RC_AE_CONFIG_PROPERTIES
         SET CONFIG_VALUE = 'Y'
       WHERE CONFIG_NAME = 'DAY0_ALLOCATION_RUN';

      INSERT INTO RC_SALES_FORECAST (RETAIL_PART_NUMBER,
                                     EXCESS_PART_NUMBER,
                                     XREF_PART_NUMBER,
                                     COMMON_PART_NUMBER,
                                     REFRESH_INVENTORY_ITEM_ID,
                                     EXCESS_INVENTORY_ITEM_ID,
                                     COMMON_INVENTORY_ITEM_ID,
                                     XREF_INVENTORY_ITEM_ID,
                                     PID_LIFE_CYCLE,
                                     UNORDERED_FG,
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
                                     SUBMITTED_AT,
                                     APPROVED_AT,
                                     APPROVAL_STATUS,
                                     FORECASTING_PRIORITY,
                                     ASP_OUTLET,
                                     EXPECTED_REVENUE_OUTLET,
                                     PID_PRIORITY,
                                     SALES_RF_ALLOCATION,
                                     SALES_WS_ALLOCATION,
                                     RF_ALLOCATED_FROM_DAY0,
                                     WS_ALLOCATED_FROM_DAY0,
                                     EXPECTED_SALES_REVENUE_RF,
                                     EXPECTED_SALES_REVENUE_WS,
                                     EXPECTED_SALES_REVENUE_OUTLET,
                                     TOTL_EXPCTD_SALES_REPAIR_COST,
                                     REFRESH_LIFE_CYCLE,
                                     EXCESS_LIFE_CYCLE,
                                     MFG_EOS_DATE,
                                     FORECAST_MONTH,
                                     FORECAST_QUARTER,
                                     FORECAST_YEAR,
                                     UNORDERED_WS_FG,
                                     UNORDERED_RF_FG,
                                     RF_NETTABLE_DGI_WITHOUT_YIELD,
                                     WS_NETTABLE_DGI_WITH_YIELD,
                                     WS_NETTABLE_DGI_WITHOUT_YIELD,
                                     POE_NETTABLE_DGI_WITH_YIELD,
                                     POE_NETTABLE_DGI_WITHOUT_YIELD,
                                     TOTAL_NON_NETTABLE_PIPELINE,
                                     RF_FG_ALLOCATION,
                                     RF_DGI_ALLOCATION,
                                     NETTABLE_DGI,
                                     RF_ADJUSTED_FORECAST,
                                     WS_ADJUSTED_FORECAST,
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
                 UNORDERED_FG,
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
                 SUBMITTED_AT,
                 APPROVED_AT,
                 APPROVAL_STATUS,
                 FORECASTING_PRIORITY,
                 ASP_OUTLET,
                 EXPECTED_REVENUE_OUTLET,
                 PID_PRIORITY,
                 SALES_RF_ALLOCATION,
                 SALES_WS_ALLOCATION,
                 RF_ALLOCATED_FROM_DAY0,
                 WS_ALLOCATED_FROM_DAY0,
                 EXPECTED_SALES_REVENUE_RF,
                 EXPECTED_SALES_REVENUE_WS,
                 EXPECTED_SALES_REVENUE_OUTLET,
                 TOTL_EXPCTD_SALES_REPAIR_COST,
                 REFRESH_LIFE_CYCLE,
                 EXCESS_LIFE_CYCLE,
                 MFG_EOS_DATE,
                 FORECAST_MONTH,
                 FORECAST_QUARTER,
                 FORECAST_YEAR,
                 UNORDERED_WS_FG,
                 UNORDERED_RF_FG,
                 RF_NETTABLE_DGI_WITHOUT_YIELD,
                 WS_NETTABLE_DGI_WITH_YIELD,
                 WS_NETTABLE_DGI_WITHOUT_YIELD,
                 POE_NETTABLE_DGI_WITH_YIELD,
                 POE_NETTABLE_DGI_WITHOUT_YIELD,
                 TOTAL_NON_NETTABLE_PIPELINE,
                 RF_FG_ALLOCATION,
                 RF_DGI_ALLOCATION,
                 NETTABLE_DGI,
                 RF_ADJUSTED_FORECAST,
                 WS_ADJUSTED_FORECAST,
                 ADJUSTED_OVERRIDDEN_FORECAST,
                 RF_ADJ_OVERRIDDEN_FORECAST,
                 ADJUSTED_PID_PRIORITY,
                 ADJ_OVERRIDDEN_PID_PRIORITY
            FROM RC_SALES_FORECAST_STAGING
           WHERE     FORECAST_QUARTER = lv_forecast_quarter
                 AND FORECAST_MONTH = lv_forecast_month
                 AND FORECAST_YEAR = lv_forecast_year
                 AND APPROVAL_STATUS = 'APPROVED');

      COMMIT;

      INSERT INTO RC_SALES_FORECAST_FINSUM (EXPECTED_REVENUE_RF,
                                            EXPECTED_REVENUE_WS,
                                            EXPECTED_REVENUE_OUTLET,
                                            EXPECTED_REPAIR_COST,
                                            RF_FORECASTED_REPAIR_COST,
                                            WS_FORECASTED_REPAIR_COST,
                                            OUTLET_FORECASTED_REPAIR_COST,
                                            FORECASTED_REPAIR_COST,
                                            SUBMITTED_AT,
                                            APPROVED_AT,
                                            UPLOADED_ON,
                                            EXPECTED_SALES_REVENUE_RF,
                                            EXPECTED_SALES_REVENUE_WS,
                                            EXPECTED_SALES_REVENUE_OUTLET,
                                            TOTL_EXPCTD_SALES_REPAIR_COST,
                                            FORECAST_QUARTER,
                                            FORECAST_MONTH,
                                            FORECAST_YEAR)
         (SELECT EXPECTED_REVENUE_RF,
                 EXPECTED_REVENUE_WS,
                 EXPECTED_REVENUE_OUTLET,
                 EXPECTED_REPAIR_COST,
                 RF_FORECASTED_REPAIR_COST,
                 WS_FORECASTED_REPAIR_COST,
                 OUTLET_FORECASTED_REPAIR_COST,
                 FORECASTED_REPAIR_COST,
                 SUBMITTED_AT,
                 APPROVED_AT,
                 UPLOADED_ON,
                 EXPECTED_SALES_REVENUE_RF,
                 EXPECTED_SALES_REVENUE_WS,
                 EXPECTED_SALES_REVENUE_OUTLET,
                 TOTL_EXPCTD_SALES_REPAIR_COST,
                 (SELECT DISTINCT FORECAST_QUARTER
                    FROM RC_SALES_FORECAST)
                    AS FORECAST_QUARTER,
                 (SELECT DISTINCT FORECAST_MONTH
                    FROM RC_SALES_FORECAST)
                    AS FORECAST_MONTH,
                 (SELECT DISTINCT FORECAST_YEAR
                    FROM RC_SALES_FORECAST)
                    AS FORECAST_YEAR
            FROM (SELECT SUM (NVL (EXPECTED_REVENUE_RF, 0))
                            AS EXPECTED_REVENUE_RF,
                         SUM (NVL (EXPECTED_REVENUE_WS, 0))
                            AS EXPECTED_REVENUE_WS,
                         SUM (NVL (EXPECTED_REVENUE_OUTLET, 0))
                            AS EXPECTED_REVENUE_OUTLET,
                         SUM (NVL (TOTAL_EXPECTED_REPAIR_COST, 0))
                            AS EXPECTED_REPAIR_COST,
                         SUM (
                            NVL (
                                 (NVL (
                                     NVL (RF_ADJ_OVERRIDDEN_FORECAST,
                                          RF_ADJUSTED_FORECAST),
                                     RF_90DAY_FORECAST))
                               * ASP_RF,
                               0))
                            AS RF_FORECASTED_REPAIR_COST,
                         SUM (
                            NVL (
                                 (NVL (WS_ADJUSTED_FORECAST,
                                       WS_90DAY_FORECAST))
                               * ASP_WS,
                               0))
                            AS WS_FORECASTED_REPAIR_COST,
                         0                  AS OUTLET_FORECASTED_REPAIR_COST,
                         SUM (NVL (TOTAL_FORECASTED_REPAIR_COST, 0))
                            AS FORECASTED_REPAIR_COST,
                         MAX (SUBMITTED_AT) AS SUBMITTED_AT,
                         MAX (APPROVED_AT)  AS APPROVED_AT,
                         MAX (UPDATED_ON)   AS UPLOADED_ON,
                         SUM (NVL (EXPECTED_SALES_REVENUE_RF, 0))
                            AS EXPECTED_SALES_REVENUE_RF,
                         SUM (NVL (EXPECTED_SALES_REVENUE_OUTLET, 0))
                            AS EXPECTED_SALES_REVENUE_OUTLET,
                         SUM (NVL (EXPECTED_SALES_REVENUE_WS, 0))
                            AS EXPECTED_SALES_REVENUE_WS,
                         SUM (NVL (TOTL_EXPCTD_SALES_REPAIR_COST, 0))
                            AS TOTL_EXPCTD_SALES_REPAIR_COST
                    FROM RC_SALES_FORECAST));

      O_STATUS := 'SUCCESS';

      IF (O_STATUS = 'SUCCESS')
      THEN
         UPDATE RC_SALES_FORECAST_CONFIG
            SET IS_PUBLISHED = 'Y',
                PUBLISHED_ON = SYSDATE,
                PUBLISHED_BY = I_USER_ID
          WHERE     FORECAST_QUARTER = lv_forecast_quarter
                AND FORECAST_MONTH = lv_forecast_month
                AND FORECAST_YEAR = lv_forecast_year;

         UPDATE CRPSC.RC_AE_CONFIG_PROPERTIES
            SET CONFIG_VALUE = 'N'
          WHERE     CONFIG_CATEGORY = 'MASTER_ADJUSTED_ALLOCATION'
                AND CONFIG_NAME = 'Master';
      END IF;

      COMMIT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         O_STATUS := 'FAILED';
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'NO DATA FOUND',
            G_ERROR_MSG,
            NULL,
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_ONPUBLISH',
            'PACKAGE',
            NULL,
            'N');
      WHEN OTHERS
      THEN
         O_STATUS := 'FAILED';
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
            G_ERROR_MSG,
            NULL,
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_ONPUBLISH',
            'PACKAGE',
            NULL,
            'Y');
   END;

   PROCEDURE RC_ALL_SALES_FORECAST_LOAD (I_ACTION   IN     VARCHAR2,
                                         O_STATUS      OUT VARCHAR2)
   IS
      lv_forecast_quarter   VARCHAR2 (10 BYTE);
      lv_forecast_month     VARCHAR2 (10 BYTE);
      lv_forecast_year      VARCHAR2 (10 BYTE);
      lv_action             VARCHAR2 (10 BYTE);
      lv_uploaded_on        DATE;
      lv_submitted_on       DATE;
      lv_approved_on        DATE;
      lv_published_on       DATE;
   BEGIN
      lv_action := I_ACTION;

      BEGIN
         SELECT DISTINCT FORECAST_QUARTER, FORECAST_MONTH, FORECAST_YEAR
           INTO lv_forecast_quarter, lv_forecast_month, lv_forecast_year
           FROM RC_SALES_FORECAST;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_forecast_quarter := NULL;
            lv_forecast_month := NULL;
            lv_forecast_year := NULL;
      END;

      BEGIN
         SELECT UPLOADED_ON,
                SUBMITTED_ON,
                APPROVED_ON,
                PUBLISHED_ON
           INTO lv_uploaded_on,
                lv_submitted_on,
                lv_approved_on,
                lv_published_on
           FROM RC_SALES_FORECAST_CONFIG
          WHERE     FORECAST_QUARTER = lv_forecast_quarter
                AND FORECAST_MONTH = lv_forecast_month
                AND FORECAST_YEAR = lv_forecast_year;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_uploaded_on := NULL;
            lv_submitted_on := NULL;
            lv_approved_on := NULL;
            lv_published_on := NULL;
      END;

      -- Call to upsert Staging and update main table internally
      CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_LOAD;

      IF (lv_action = 'RA')
      THEN
         -- Insert Last day snapshot to RC_ALL_SALES_FORECAST table
         INSERT INTO RC_ALL_SALES_FORECAST (RETAIL_PART_NUMBER,
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
                                            SUBMITTED_AT,
                                            APPROVED_AT,
                                            APPROVAL_STATUS,
                                            FORECASTING_PRIORITY,
                                            ASP_OUTLET,
                                            EXPECTED_REVENUE_OUTLET,
                                            PID_PRIORITY,
                                            SALES_RF_ALLOCATION,
                                            SALES_WS_ALLOCATION,
                                            RF_ALLOCATED_FROM_DAY0,
                                            WS_ALLOCATED_FROM_DAY0,
                                            EXPECTED_SALES_REVENUE_RF,
                                            EXPECTED_SALES_REVENUE_WS,
                                            EXPECTED_SALES_REVENUE_OUTLET,
                                            TOTL_EXPCTD_SALES_REPAIR_COST,
                                            REFRESH_LIFE_CYCLE,
                                            EXCESS_LIFE_CYCLE,
                                            MFG_EOS_DATE,
                                            FORECAST_QUARTER,
                                            FORECAST_MONTH,
                                            FORECAST_YEAR,
                                            SNAPSHOT_TYPE,
                                            UNORDERED_WS_FG,
                                            RF_NETTABLE_DGI_WITHOUT_YIELD,
                                            WS_NETTABLE_DGI_WITH_YIELD,
                                            WS_NETTABLE_DGI_WITHOUT_YIELD,
                                            POE_NETTABLE_DGI_WITH_YIELD,
                                            POE_NETTABLE_DGI_WITHOUT_YIELD,
                                            TOTAL_NON_NETTABLE_PIPELINE,
                                            RF_FG_ALLOCATION,
                                            RF_DGI_ALLOCATION,
                                            WS_ADJUSTED_FORECAST,
                                            RF_ADJUSTED_FORECAST,
                                            NETTABLE_DGI,
                                            UNORDERED_FG,
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
                    UNORDERED_FG,
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
                    SUBMITTED_AT,
                    APPROVED_AT,
                    APPROVAL_STATUS,
                    FORECASTING_PRIORITY,
                    ASP_OUTLET,
                    EXPECTED_REVENUE_OUTLET,
                    PID_PRIORITY,
                    SALES_RF_ALLOCATION,
                    SALES_WS_ALLOCATION,
                    RF_ALLOCATED_FROM_DAY0,
                    WS_ALLOCATED_FROM_DAY0,
                    EXPECTED_SALES_REVENUE_RF,
                    EXPECTED_SALES_REVENUE_WS,
                    EXPECTED_SALES_REVENUE_OUTLET,
                    TOTL_EXPCTD_SALES_REPAIR_COST,
                    REFRESH_LIFE_CYCLE,
                    EXCESS_LIFE_CYCLE,
                    MFG_EOS_DATE,
                    FORECAST_QUARTER,
                    FORECAST_MONTH,
                    FORECAST_YEAR,
                    'LAST' AS SNAPSHOT_TYPE,
                    UNORDERED_WS_FG,
                    RF_NETTABLE_DGI_WITHOUT_YIELD,
                    WS_NETTABLE_DGI_WITH_YIELD,
                    WS_NETTABLE_DGI_WITHOUT_YIELD,
                    POE_NETTABLE_DGI_WITH_YIELD,
                    POE_NETTABLE_DGI_WITHOUT_YIELD,
                    TOTAL_NON_NETTABLE_PIPELINE,
                    RF_FG_ALLOCATION,
                    RF_DGI_ALLOCATION,
                    WS_ADJUSTED_FORECAST,
                    RF_ADJUSTED_FORECAST,
                    NETTABLE_DGI,
                    UNORDERED_FG,
                    ADJUSTED_OVERRIDDEN_FORECAST,
                    RF_ADJ_OVERRIDDEN_FORECAST,
                    ADJUSTED_PID_PRIORITY,
                    ADJ_OVERRIDDEN_PID_PRIORITY
               FROM RC_SALES_FORECAST);

         O_STATUS := 'SUCCESS';

         COMMIT;

         INSERT INTO CRPADM.RC_ALL_SALES_FORECAST_FINSUM
            (SELECT SUM (NVL (EXPECTED_REVENUE_RF, 0)) AS EXPECTED_REVENUE_RF,
                    SUM (NVL (EXPECTED_REVENUE_WS, 0)) AS EXPECTED_REVENUE_WS,
                    SUM (NVL (EXPECTED_REVENUE_OUTLET, 0))
                       AS EXPECTED_REVENUE_OUTLET,
                    SUM (NVL (TOTAL_EXPECTED_REPAIR_COST, 0))
                       AS EXPECTED_REPAIR_COST,
                    SUM (
                       NVL (
                            (NVL (
                                NVL (RF_ADJ_OVERRIDDEN_FORECAST,
                                     RF_ADJUSTED_FORECAST),
                                RF_90DAY_FORECAST))
                          * ASP_RF,
                          0))
                       AS RF_FORECASTED_REPAIR_COST,
                    SUM (
                       NVL (
                            (NVL (WS_ADJUSTED_FORECAST, WS_90DAY_FORECAST))
                          * ASP_WS,
                          0))
                       AS WS_FORECASTED_REPAIR_COST,
                    0
                       AS OUTLET_FORECASTED_REPAIR_COST,
                    SUM (NVL (TOTAL_FORECASTED_REPAIR_COST, 0))
                       AS FORECASTED_REPAIR_COST,
                    lv_submitted_on                    AS SUBMITTED_AT,
                    lv_approved_on                     AS APPROVED_AT,
                    lv_uploaded_on                     AS UPLOADED_ON,
                    lv_published_on                    AS PUBLISHED_ON,
                    SUM (NVL (EXPECTED_SALES_REVENUE_RF, 0))
                       AS EXPECTED_SALES_REVENUE_RF,
                    SUM (NVL (EXPECTED_SALES_REVENUE_OUTLET, 0))
                       AS EXPECTED_SALES_REVENUE_OUTLET,
                    SUM (NVL (EXPECTED_SALES_REVENUE_WS, 0))
                       AS EXPECTED_SALES_REVENUE_WS,
                    SUM (NVL (TOTL_EXPCTD_SALES_REPAIR_COST, 0))
                       AS TOTL_EXPCTD_SALES_REPAIR_COST,
                    lv_forecast_quarter                AS FORECAST_QUARTER,
                    lv_forecast_month                  AS FORECAST_MONTH,
                    lv_forecast_year                   AS FORECAST_YEAR,
                    'LAST'                             AS SNAPSHOT_TYPE
               FROM RC_SALES_FORECAST);

         COMMIT;
      ELSIF (lv_action = 'AE')
      THEN
         -- Insert Day 0 snapshot to RC_ALL_SALES_FORECAST table
         INSERT INTO RC_ALL_SALES_FORECAST (RETAIL_PART_NUMBER,
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
                                            SUBMITTED_AT,
                                            APPROVED_AT,
                                            APPROVAL_STATUS,
                                            FORECASTING_PRIORITY,
                                            ASP_OUTLET,
                                            EXPECTED_REVENUE_OUTLET,
                                            PID_PRIORITY,
                                            SALES_RF_ALLOCATION,
                                            SALES_WS_ALLOCATION,
                                            RF_ALLOCATED_FROM_DAY0,
                                            WS_ALLOCATED_FROM_DAY0,
                                            EXPECTED_SALES_REVENUE_RF,
                                            EXPECTED_SALES_REVENUE_WS,
                                            EXPECTED_SALES_REVENUE_OUTLET,
                                            TOTL_EXPCTD_SALES_REPAIR_COST,
                                            REFRESH_LIFE_CYCLE,
                                            EXCESS_LIFE_CYCLE,
                                            MFG_EOS_DATE,
                                            FORECAST_QUARTER,
                                            FORECAST_MONTH,
                                            FORECAST_YEAR,
                                            SNAPSHOT_TYPE,
                                            UNORDERED_WS_FG,
                                            RF_NETTABLE_DGI_WITHOUT_YIELD,
                                            WS_NETTABLE_DGI_WITH_YIELD,
                                            WS_NETTABLE_DGI_WITHOUT_YIELD,
                                            POE_NETTABLE_DGI_WITH_YIELD,
                                            POE_NETTABLE_DGI_WITHOUT_YIELD,
                                            UNORDERED_FG,
                                            TOTAL_NON_NETTABLE_PIPELINE,
                                            RF_FG_ALLOCATION,
                                            RF_DGI_ALLOCATION,
                                            RF_ADJUSTED_FORECAST,
                                            WS_ADJUSTED_FORECAST,
                                            NETTABLE_DGI,
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
                    SUBMITTED_AT,
                    APPROVED_AT,
                    APPROVAL_STATUS,
                    FORECASTING_PRIORITY,
                    ASP_OUTLET,
                    EXPECTED_REVENUE_OUTLET,
                    PID_PRIORITY,
                    SALES_RF_ALLOCATION,
                    SALES_WS_ALLOCATION,
                    RF_ALLOCATED_FROM_DAY0,
                    WS_ALLOCATED_FROM_DAY0,
                    EXPECTED_SALES_REVENUE_RF,
                    EXPECTED_SALES_REVENUE_WS,
                    EXPECTED_SALES_REVENUE_OUTLET,
                    TOTL_EXPCTD_SALES_REPAIR_COST,
                    REFRESH_LIFE_CYCLE,
                    EXCESS_LIFE_CYCLE,
                    MFG_EOS_DATE,
                    FORECAST_QUARTER,
                    FORECAST_MONTH,
                    FORECAST_YEAR,
                    'FIRST' AS SNAPSHOT_TYPE,
                    UNORDERED_WS_FG,
                    RF_NETTABLE_DGI_WITHOUT_YIELD,
                    WS_NETTABLE_DGI_WITH_YIELD,
                    WS_NETTABLE_DGI_WITHOUT_YIELD,
                    POE_NETTABLE_DGI_WITH_YIELD,
                    POE_NETTABLE_DGI_WITHOUT_YIELD,
                    UNORDERED_FG,
                    TOTAL_NON_NETTABLE_PIPELINE,
                    RF_FG_ALLOCATION,
                    RF_DGI_ALLOCATION,
                    RF_ADJUSTED_FORECAST,
                    WS_ADJUSTED_FORECAST,
                    NETTABLE_DGI,
                    ADJUSTED_OVERRIDDEN_FORECAST,
                    RF_ADJ_OVERRIDDEN_FORECAST,
                    ADJUSTED_PID_PRIORITY,
                    ADJ_OVERRIDDEN_PID_PRIORITY
               FROM RC_SALES_FORECAST);

         O_STATUS := 'SUCCESS';

         COMMIT;

         INSERT INTO CRPADM.RC_ALL_SALES_FORECAST_FINSUM
            (SELECT SUM (NVL (EXPECTED_REVENUE_RF, 0)) AS EXPECTED_REVENUE_RF,
                    SUM (NVL (EXPECTED_REVENUE_WS, 0)) AS EXPECTED_REVENUE_WS,
                    SUM (NVL (EXPECTED_REVENUE_OUTLET, 0))
                       AS EXPECTED_REVENUE_OUTLET,
                    SUM (NVL (TOTAL_EXPECTED_REPAIR_COST, 0))
                       AS EXPECTED_REPAIR_COST,
                    SUM (
                       NVL (
                            (NVL (
                                NVL (RF_ADJ_OVERRIDDEN_FORECAST,
                                     RF_ADJUSTED_FORECAST),
                                RF_90DAY_FORECAST))
                          * ASP_RF,
                          0))
                       AS RF_FORECASTED_REPAIR_COST,
                    SUM (
                       NVL (
                            (NVL (WS_ADJUSTED_FORECAST, WS_90DAY_FORECAST))
                          * ASP_WS,
                          0))
                       AS WS_FORECASTED_REPAIR_COST,
                    0
                       AS OUTLET_FORECASTED_REPAIR_COST,
                    SUM (NVL (TOTAL_FORECASTED_REPAIR_COST, 0))
                       AS FORECASTED_REPAIR_COST,
                    lv_submitted_on                    AS SUBMITTED_AT,
                    lv_approved_on                     AS APPROVED_AT,
                    lv_uploaded_on                     AS UPLOADED_ON,
                    lv_published_on                    AS PUBLISHED_ON,
                    SUM (NVL (EXPECTED_SALES_REVENUE_RF, 0))
                       AS EXPECTED_SALES_REVENUE_RF,
                    SUM (NVL (EXPECTED_SALES_REVENUE_OUTLET, 0))
                       AS EXPECTED_SALES_REVENUE_OUTLET,
                    SUM (NVL (EXPECTED_SALES_REVENUE_WS, 0))
                       AS EXPECTED_SALES_REVENUE_WS,
                    SUM (NVL (TOTL_EXPCTD_SALES_REPAIR_COST, 0))
                       AS TOTL_EXPCTD_SALES_REPAIR_COST,
                    lv_forecast_quarter                AS FORECAST_QUARTER,
                    lv_forecast_month                  AS FORECAST_MONTH,
                    lv_forecast_year                   AS FORECAST_YEAR,
                    'FIRST'                            AS SNAPSHOT_TYPE
               FROM RC_SALES_FORECAST);

         COMMIT;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         O_STATUS := 'FAILED';
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'NO DATA FOUND',
            G_ERROR_MSG,
            NULL,
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_ALL_SALES_FORECAST_LOAD',
            'PACKAGE',
            NULL,
            'N');
      WHEN OTHERS
      THEN
         O_STATUS := 'FAILED';
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
            G_ERROR_MSG,
            NULL,
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_ALL_SALES_FORECAST_LOAD',
            'PACKAGE',
            NULL,
            'Y');
   END;

   --Procedure to be executed post Allocation engine execution is completed

   PROCEDURE RC_SALES_FORECAST_AFTER_AE
   IS
      lv_status   VARCHAR2 (10 BYTE);
      lv_value    VARCHAR2 (100);
   BEGIN
      UPDATE RC_SALES_FORECAST RSF
         SET TOTAL_RF_ALLOCATION =
                NVL (
                   (SELECT RF_COUNTER
                      FROM CRPSC.RC_AE_FGI_REQUIREMENT AFR
                     WHERE AFR.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER),
                   0),
             WS_ALLOCATION =
                NVL (
                   (SELECT WS_COUNTER
                      FROM CRPSC.RC_AE_FGI_REQUIREMENT AFR
                     WHERE AFR.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER),
                   0),
             OUTLET_ALLOCATION =
                NVL (
                   (SELECT OUTLET_ALLOC_QUANTITY
                      FROM CRPSC.RC_AE_FGI_REQUIREMENT AFR
                     WHERE AFR.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER),
                   0),
             PIPELINE_NOT_ALLOCATED =
                NVL (
                   (SELECT SUM (QTY_ON_HAND)
                      FROM CRPADM.RC_INV_BTS_C3_MV INV
                     WHERE     (LOCATION IN
                                   (SELECT MSTR.SUB_INVENTORY_LOCATION
                                      FROM CRPADM.RC_SUB_INV_LOC_MSTR MSTR
                                     WHERE     MSTR.INVENTORY_TYPE = 1
                                           AND MSTR.NETTABLE_FLAG = 1
                                           AND MSTR.PROGRAM_TYPE IN (0, 1, 2)))
                           AND (   PART_NUMBER = RSF.RETAIL_PART_NUMBER
                                OR PART_NUMBER = RSF.EXCESS_PART_NUMBER
                                OR PART_NUMBER = RSF.COMMON_PART_NUMBER
                                OR PART_NUMBER = RSF.XREF_PART_NUMBER)
                           AND NOT EXISTS
                                  (SELECT *
                                     FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                                          CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                                    WHERE     1 = 1
                                          AND RS.REFRESH_METHOD_ID IN
                                                 (SELECT DTLS.REFRESH_METHOD_ID
                                                    FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                         MSTR,
                                                         CRPADM.RC_SUB_INV_LOC_FLG_DTLS
                                                         DTLS
                                                   WHERE     MSTR.SUB_INVENTORY_ID =
                                                                DTLS.SUB_INVENTORY_ID
                                                         AND MSTR.SUB_INVENTORY_LOCATION =
                                                                INV.LOCATION)
                                          AND RS.REFRESH_INVENTORY_ITEM_ID IN
                                                 (RSF.REFRESH_INVENTORY_ITEM_ID,
                                                  RSF.EXCESS_INVENTORY_ITEM_ID,
                                                  RSF.COMMON_INVENTORY_ITEM_ID,
                                                  RSF.XREF_INVENTORY_ITEM_ID)
                                          AND RS.REPAIR_PARTNER_ID =
                                                 RP.REPAIR_PARTNER_ID
                                          AND RS.REFRESH_STATUS = 'ACTIVE'
                                          AND RP.ACTIVE_FLAG = 'Y')
                           AND SITE NOT LIKE 'Z32%'),
                   0),
             RF_ALLOCATED_FROM_DAY0 =
                NVL (
                   (SELECT RF_COUNTER
                      FROM CRPSC.RC_AE_FGI_REQUIREMENT AFR
                     WHERE AFR.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER),
                   0),
             WS_ALLOCATED_FROM_DAY0 =
                NVL (
                   (SELECT WS_COUNTER
                      FROM CRPSC.RC_AE_FGI_REQUIREMENT AFR
                     WHERE AFR.COMMON_PART_NUMBER = RSF.COMMON_PART_NUMBER),
                   0),
             SALES_RF_ALLOCATION =
                NVL (
                   LEAST (
                      GREATEST (
                         (  NVL (
                               (SELECT SUM (
                                            (QTY_ON_HAND)
                                          - ABS (TOTAL_RESERVATIONS))
                                  FROM CRPADM.RC_INV_BTS_C3_MV
                                 WHERE     LOCATION = 'FG' -- Considering only BTS FG locations
                                       AND PROGRAM_TYPE = 'RETAIL'
                                       AND PART_NUMBER =
                                              RSF.RETAIL_PART_NUMBER
                                       AND SITE NOT LIKE 'Z32%'),
                               0)
                          + FLOOR (
                               NVL (
                                  (SELECT SUM (RF_QTY_AFTER_YIELD)
                                     FROM CRPADM.RC_INV_BTS_C3_MV
                                    WHERE     (    LOCATION <> 'FG'
                                               AND LOCATION IN
                                                      (SELECT MSTR.SUB_INVENTORY_LOCATION
                                                         FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                              MSTR
                                                        --INNER JOIN
                                                        --CRPADM.RC_SUB_INV_LOC_FLG_DTLS
                                                        --FLG
                                                        --    ON   MSTR.SUB_INVENTORY_ID =
                                                        --         FLG.SUB_INVENTORY_ID
                                                        --      MSTR.INVENTORY_TYPE =
                                                        --             1
                                                        WHERE     MSTR.NETTABLE_FLAG =
                                                                     1
                                                              AND MSTR.PROGRAM_TYPE =
                                                                     0))
                                          AND (   PART_NUMBER =
                                                     RSF.RETAIL_PART_NUMBER
                                               OR PART_NUMBER =
                                                     RSF.COMMON_PART_NUMBER
                                               OR PART_NUMBER =
                                                     RSF.XREF_PART_NUMBER)
                                          AND SITE NOT LIKE 'Z32%'),
                                  0))
                          - NVL (
                               (SELECT ABS (SUM (TOTAL_RESERVATIONS))
                                  FROM CRPADM.RC_INV_BTS_C3_MV
                                 WHERE     SITE = 'GDGI'
                                       AND PART_NUMBER =
                                              RSF.RETAIL_PART_NUMBER
                                       AND SITE NOT LIKE 'Z32%'),
                               0)),
                         0),
                      (NVL (
                          NVL (RF_ADJ_OVERRIDDEN_FORECAST,
                               RF_ADJUSTED_FORECAST),
                          RF_90DAY_FORECAST))),
                   0),
             SALES_WS_ALLOCATION =
                NVL (
                   LEAST (
                      GREATEST (
                         (  NVL (
                               (SELECT SUM (
                                            (QTY_ON_HAND)
                                          - ABS (TOTAL_RESERVATIONS))
                                  FROM CRPADM.RC_INV_BTS_C3_MV
                                 WHERE     LOCATION = 'FG' -- Considering only BTS FG locations
                                       AND PROGRAM_TYPE = 'EXCESS'
                                       AND PART_NUMBER =
                                              RSF.EXCESS_PART_NUMBER
                                       AND SITE NOT LIKE 'Z32%'),
                               0)
                          + FLOOR (
                               NVL (
                                  (SELECT SUM (WS_QTY_AFTER_YIELD)
                                     FROM CRPADM.RC_INV_BTS_C3_MV
                                    WHERE     (    LOCATION <> 'FG'
                                               AND LOCATION IN
                                                      (SELECT MSTR.SUB_INVENTORY_LOCATION
                                                         FROM CRPADM.RC_SUB_INV_LOC_MSTR
                                                              MSTR
                                                        /* INNER JOIN
                                                         CRPADM.RC_SUB_INV_LOC_FLG_DTLS
                                                         FLG
                                                            ON     MSTR.SUB_INVENTORY_ID =
                                                                      FLG.SUB_INVENTORY_ID
                                                               AND MSTR.INVENTORY_TYPE =
                                                                      1*/
                                                        WHERE     MSTR.NETTABLE_FLAG =
                                                                     1
                                                              AND MSTR.PROGRAM_TYPE =
                                                                     1))
                                          AND (   PART_NUMBER =
                                                     RSF.EXCESS_PART_NUMBER
                                               OR PART_NUMBER =
                                                     RSF.COMMON_PART_NUMBER
                                               OR PART_NUMBER =
                                                     RSF.XREF_PART_NUMBER)
                                          AND SITE NOT LIKE 'Z32%'),
                                  0))
                          - NVL (
                               (SELECT ABS (SUM (TOTAL_RESERVATIONS))
                                  FROM CRPADM.RC_INV_BTS_C3_MV
                                 WHERE     SITE = 'GDGI'
                                       AND PART_NUMBER =
                                              RSF.EXCESS_PART_NUMBER
                                       AND SITE NOT LIKE 'Z32%'),
                               0)),
                         0),
                      (NVL (WS_ADJUSTED_FORECAST, WS_90DAY_FORECAST))),
                   0);


      UPDATE RC_SALES_FORECAST RSF
         SET RSF.EXPECTED_REVENUE_RF =
                NVL ( (RSF.ASP_RF * RSF.TOTAL_RF_ALLOCATION), 0),
             RSF.EXPECTED_REVENUE_WS =
                NVL ( (RSF.ASP_WS * RSF.WS_ALLOCATION), 0),
             RSF.EXPECTED_REVENUE_OUTLET =
                NVL ( (RSF.ASP_OUTLET * RSF.OUTLET_ALLOCATION), 0),
             RSF.UNITS_REQB_CONSTRAINED =
                NVL (
                   (CASE
                       WHEN (RSF.SALES_RF_ALLOCATION - RSF.UNORDERED_FG) < 0
                       THEN
                          0
                       ELSE
                          LEAST (
                             (RSF.SALES_RF_ALLOCATION - RSF.UNORDERED_FG),
                             RSF.RF_NETTABLE_DGI_WITH_YIELD)
                    END),
                   0);

      UPDATE RC_SALES_FORECAST
         SET EXPECTED_SALES_REVENUE_RF =
                NVL ( (ASP_RF * SALES_RF_ALLOCATION), 0),
             EXPECTED_SALES_REVENUE_WS =
                NVL ( (ASP_WS * SALES_WS_ALLOCATION), 0),
             EXPECTED_SALES_REVENUE_OUTLET =
                NVL ( (ASP_OUTLET * OUTLET_ALLOCATION), 0);

      UPDATE RC_SALES_FORECAST RSF
         SET RSF.RF_EXPECTED_REPAIR_COST =
                NVL (
                   ROUND (
                        (  (  (NVL (
                                  (SELECT MAX (REPAIR_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.RETAIL_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.RETAIL_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.RETAIL_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                1))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 1
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.RETAIL_PART_NUMBER)
                         * RSF.UNITS_REQ_BUILD)
                      + (  (  (NVL (
                                  (SELECT MAX (TEST_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.RETAIL_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.RETAIL_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.RETAIL_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                2))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 2
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.RETAIL_PART_NUMBER)
                         * RSF.UNITS_REQ_BUILD)
                      + (  (  (NVL (
                                  (SELECT MAX (SCREEN_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.RETAIL_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                34
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.RETAIL_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.RETAIL_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                3))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 3
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.RETAIL_PART_NUMBER)
                         * RSF.UNITS_REQ_BUILD),
                      2),
                   0),
             RSF.WS_EXPECTED_REPAIR_COST =
                NVL (
                   ROUND (
                        (  (  (NVL (
                                  (SELECT MAX (REPAIR_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.EXCESS_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.EXCESS_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.EXCESS_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                1))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 1
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.EXCESS_PART_NUMBER)
                         * RSF.WS_ALLOCATION)
                      + (  (  (NVL (
                                  (SELECT MAX (TEST_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.EXCESS_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                33
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.EXCESS_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.EXCESS_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                2))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 2
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.EXCESS_PART_NUMBER)
                         * RSF.WS_ALLOCATION)
                      + (  (  (NVL (
                                  (SELECT MAX (SCREEN_PERCENTAGE)
                                     FROM RC_SALES_FORECAST_REPAIR_PERC
                                    WHERE PART_NUMBER =
                                             RSF.EXCESS_PART_NUMBER),
                                  (SELECT CASE
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     1
                                             THEN
                                                100
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     2
                                             THEN
                                                50
                                             WHEN COUNT (
                                                     DISTINCT REFRESH_METHOD_ID) =
                                                     3
                                             THEN
                                                34
                                             ELSE
                                                0
                                          END
                                     FROM RC_PRODUCT_REPAIR_SETUP
                                    WHERE     REFRESH_PART_NUMBER =
                                                 RSF.EXCESS_PART_NUMBER
                                          AND EXISTS
                                                 (SELECT 1
                                                    FROM RC_PRODUCT_REPAIR_SETUP
                                                   WHERE     REFRESH_PART_NUMBER =
                                                                RSF.EXCESS_PART_NUMBER
                                                         AND REFRESH_METHOD_ID =
                                                                3))))
                            / 100)
                         * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                              FROM RC_PRODUCT_REPAIR_SETUP
                             WHERE     REFRESH_METHOD_ID = 3
                                   AND REFRESH_STATUS NOT IN
                                          ('DEACTIVATED', 'INACTIVE')
                                   AND REFRESH_PART_NUMBER =
                                          RSF.EXCESS_PART_NUMBER)
                         * RSF.WS_ALLOCATION),
                      2),
                   0);

      UPDATE RC_SALES_FORECAST RSF
         SET RSF.TOTAL_EXPECTED_REPAIR_COST =
                NVL (
                   (RSF.RF_EXPECTED_REPAIR_COST + RSF.WS_EXPECTED_REPAIR_COST),
                   0);

      COMMIT;


      UPDATE RC_SALES_FORECAST RSF
         SET RSF.TOTL_EXPCTD_SALES_REPAIR_COST =
                NVL (
                   (                          -- SALES_RF_EXPECTED_REPAIR_COST
                    NVL (
                         ROUND (
                              (  (  (NVL (
                                        (SELECT MAX (REPAIR_PERCENTAGE)
                                           FROM RC_SALES_FORECAST_REPAIR_PERC
                                          WHERE PART_NUMBER =
                                                   RSF.RETAIL_PART_NUMBER),
                                        (SELECT CASE
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           1
                                                   THEN
                                                      100
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           2
                                                   THEN
                                                      50
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           3
                                                   THEN
                                                      33
                                                   ELSE
                                                      0
                                                END
                                           FROM RC_PRODUCT_REPAIR_SETUP
                                          WHERE     REFRESH_PART_NUMBER =
                                                       RSF.RETAIL_PART_NUMBER
                                                AND EXISTS
                                                       (SELECT 1
                                                          FROM RC_PRODUCT_REPAIR_SETUP
                                                         WHERE     REFRESH_PART_NUMBER =
                                                                      RSF.RETAIL_PART_NUMBER
                                                               AND REFRESH_METHOD_ID =
                                                                      1))))
                                  / 100)
                               * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                                    FROM RC_PRODUCT_REPAIR_SETUP
                                   WHERE     REFRESH_METHOD_ID = 1
                                         AND REFRESH_STATUS NOT IN
                                                ('DEACTIVATED', 'INACTIVE')
                                         AND REFRESH_PART_NUMBER =
                                                RSF.RETAIL_PART_NUMBER)
                               * RSF.UNITS_REQB_CONSTRAINED)
                            + (  (  (NVL (
                                        (SELECT MAX (TEST_PERCENTAGE)
                                           FROM RC_SALES_FORECAST_REPAIR_PERC
                                          WHERE PART_NUMBER =
                                                   RSF.RETAIL_PART_NUMBER),
                                        (SELECT CASE
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           1
                                                   THEN
                                                      100
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           2
                                                   THEN
                                                      50
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           3
                                                   THEN
                                                      33
                                                   ELSE
                                                      0
                                                END
                                           FROM RC_PRODUCT_REPAIR_SETUP
                                          WHERE     REFRESH_PART_NUMBER =
                                                       RSF.RETAIL_PART_NUMBER
                                                AND EXISTS
                                                       (SELECT 1
                                                          FROM RC_PRODUCT_REPAIR_SETUP
                                                         WHERE     REFRESH_PART_NUMBER =
                                                                      RSF.RETAIL_PART_NUMBER
                                                               AND REFRESH_METHOD_ID =
                                                                      2))))
                                  / 100)
                               * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                                    FROM RC_PRODUCT_REPAIR_SETUP
                                   WHERE     REFRESH_METHOD_ID = 2
                                         AND REFRESH_STATUS NOT IN
                                                ('DEACTIVATED', 'INACTIVE')
                                         AND REFRESH_PART_NUMBER =
                                                RSF.RETAIL_PART_NUMBER)
                               * RSF.UNITS_REQB_CONSTRAINED)
                            + (  (  (NVL (
                                        (SELECT MAX (SCREEN_PERCENTAGE)
                                           FROM RC_SALES_FORECAST_REPAIR_PERC
                                          WHERE PART_NUMBER =
                                                   RSF.RETAIL_PART_NUMBER),
                                        (SELECT CASE
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           1
                                                   THEN
                                                      100
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           2
                                                   THEN
                                                      50
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           3
                                                   THEN
                                                      34
                                                   ELSE
                                                      0
                                                END
                                           FROM RC_PRODUCT_REPAIR_SETUP
                                          WHERE     REFRESH_PART_NUMBER =
                                                       RSF.RETAIL_PART_NUMBER
                                                AND EXISTS
                                                       (SELECT 1
                                                          FROM RC_PRODUCT_REPAIR_SETUP
                                                         WHERE     REFRESH_PART_NUMBER =
                                                                      RSF.RETAIL_PART_NUMBER
                                                               AND REFRESH_METHOD_ID =
                                                                      3))))
                                  / 100)
                               * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                                    FROM RC_PRODUCT_REPAIR_SETUP
                                   WHERE     REFRESH_METHOD_ID = 3
                                         AND REFRESH_STATUS NOT IN
                                                ('DEACTIVATED', 'INACTIVE')
                                         AND REFRESH_PART_NUMBER =
                                                RSF.RETAIL_PART_NUMBER)
                               * RSF.UNITS_REQB_CONSTRAINED),
                            2),
                         0)
                    +                         -- SALES_WS_EXPECTED_REPAIR_COST
                      -- RSF.WS_EXPECTED_REPAIR_COST
                      NVL (
                         ROUND (
                              (  (  (NVL (
                                        (SELECT MAX (REPAIR_PERCENTAGE)
                                           FROM RC_SALES_FORECAST_REPAIR_PERC
                                          WHERE PART_NUMBER =
                                                   RSF.EXCESS_PART_NUMBER),
                                        (SELECT CASE
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           1
                                                   THEN
                                                      100
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           2
                                                   THEN
                                                      50
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           3
                                                   THEN
                                                      33
                                                   ELSE
                                                      0
                                                END
                                           FROM RC_PRODUCT_REPAIR_SETUP
                                          WHERE     REFRESH_PART_NUMBER =
                                                       RSF.EXCESS_PART_NUMBER
                                                AND EXISTS
                                                       (SELECT 1
                                                          FROM RC_PRODUCT_REPAIR_SETUP
                                                         WHERE     REFRESH_PART_NUMBER =
                                                                      RSF.EXCESS_PART_NUMBER
                                                               AND REFRESH_METHOD_ID =
                                                                      1))))
                                  / 100)
                               * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                                    FROM RC_PRODUCT_REPAIR_SETUP
                                   WHERE     REFRESH_METHOD_ID = 1
                                         AND REFRESH_STATUS NOT IN
                                                ('DEACTIVATED', 'INACTIVE')
                                         AND REFRESH_PART_NUMBER =
                                                RSF.EXCESS_PART_NUMBER)
                               * RSF.SALES_WS_ALLOCATION)
                            + (  (  (NVL (
                                        (SELECT MAX (TEST_PERCENTAGE)
                                           FROM RC_SALES_FORECAST_REPAIR_PERC
                                          WHERE PART_NUMBER =
                                                   RSF.EXCESS_PART_NUMBER),
                                        (SELECT CASE
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           1
                                                   THEN
                                                      100
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           2
                                                   THEN
                                                      50
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           3
                                                   THEN
                                                      33
                                                   ELSE
                                                      0
                                                END
                                           FROM RC_PRODUCT_REPAIR_SETUP
                                          WHERE     REFRESH_PART_NUMBER =
                                                       RSF.EXCESS_PART_NUMBER
                                                AND EXISTS
                                                       (SELECT 1
                                                          FROM RC_PRODUCT_REPAIR_SETUP
                                                         WHERE     REFRESH_PART_NUMBER =
                                                                      RSF.EXCESS_PART_NUMBER
                                                               AND REFRESH_METHOD_ID =
                                                                      2))))
                                  / 100)
                               * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                                    FROM RC_PRODUCT_REPAIR_SETUP
                                   WHERE     REFRESH_METHOD_ID = 2
                                         AND REFRESH_STATUS NOT IN
                                                ('DEACTIVATED', 'INACTIVE')
                                         AND REFRESH_PART_NUMBER =
                                                RSF.EXCESS_PART_NUMBER)
                               * RSF.SALES_WS_ALLOCATION)
                            + (  (  (NVL (
                                        (SELECT MAX (SCREEN_PERCENTAGE)
                                           FROM RC_SALES_FORECAST_REPAIR_PERC
                                          WHERE PART_NUMBER =
                                                   RSF.EXCESS_PART_NUMBER),
                                        (SELECT CASE
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           1
                                                   THEN
                                                      100
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           2
                                                   THEN
                                                      50
                                                   WHEN COUNT (
                                                           DISTINCT REFRESH_METHOD_ID) =
                                                           3
                                                   THEN
                                                      34
                                                   ELSE
                                                      0
                                                END
                                           FROM RC_PRODUCT_REPAIR_SETUP
                                          WHERE     REFRESH_PART_NUMBER =
                                                       RSF.EXCESS_PART_NUMBER
                                                AND EXISTS
                                                       (SELECT 1
                                                          FROM RC_PRODUCT_REPAIR_SETUP
                                                         WHERE     REFRESH_PART_NUMBER =
                                                                      RSF.EXCESS_PART_NUMBER
                                                               AND REFRESH_METHOD_ID =
                                                                      3))))
                                  / 100)
                               * (SELECT NVL (MAX (REFRESH_PRICE), 0)
                                    FROM RC_PRODUCT_REPAIR_SETUP
                                   WHERE     REFRESH_METHOD_ID = 3
                                         AND REFRESH_STATUS NOT IN
                                                ('DEACTIVATED', 'INACTIVE')
                                         AND REFRESH_PART_NUMBER =
                                                RSF.EXCESS_PART_NUMBER)
                               * RSF.SALES_WS_ALLOCATION),
                            2),
                         0)),
                   0);

      COMMIT;



      SELECT TO_CHAR (config_value)
        INTO lv_value
        FROM crpsc.rc_ae_config_properties
       WHERE config_name = 'DAY0_ALLOCATION_RUN';

      -- Call to load Day 0 Snapshot into RC_ALL_SALES_FORECAST table
      IF (lv_value = 'Y')
      THEN
         CRPADM.RC_SALES_FORECAST_ENGINE.RC_ALL_SALES_FORECAST_LOAD (
            'AE',
            lv_status);
      END IF;
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
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_AFTER_AE',
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
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_AFTER_AE',
            'PACKAGE',
            NULL,
            'Y');
   END;

   PROCEDURE RC_SALES_FORECAST_PID_PRIORITY
   IS
   BEGIN
      /* UPDATE RC_SALES_FORECAST RSF
          SET PID_PRIORITY =
                 (CASE
                     WHEN (    NVL (
                                  (SELECT SUM (NETTABLE_MOS)
                                     FROM RC_FIN_DEMAND_LIST
                                    WHERE    PRODUCT_NAME =
                                                RSF.COMMON_PART_NUMBER
                                          OR PRODUCT_NAME =
                                                RSF.XREF_PART_NUMBER),
                                  0) <= 3
                           AND NVL (
                                  (SELECT SUM (
                                               MONTH_10_QTY
                                             + MONTH_11_QTY
                                             + MONTH_12_QTY)
                                     FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
                                          DTLS
                                    WHERE    DTLS.REFRESH_INVENTORY_ITEM_ID =
                                                RSF.REFRESH_INVENTORY_ITEM_ID
                                          OR DTLS.REFRESH_INVENTORY_ITEM_ID =
                                                RSF.EXCESS_INVENTORY_ITEM_ID),
                                  0) > 0)
                     THEN
                        'P1'
                     WHEN (    NVL (
                                  (SELECT SUM (NETTABLE_MOS)
                                     FROM RC_FIN_DEMAND_LIST
                                    WHERE    PRODUCT_NAME =
                                                RSF.COMMON_PART_NUMBER
                                          OR PRODUCT_NAME =
                                                RSF.XREF_PART_NUMBER),
                                  0) >= 6
                           AND NVL (
                                  (SELECT SUM (
                                               MONTH_5_QTY
                                             + MONTH_6_QTY
                                             + MONTH_7_QTY
                                             + MONTH_8_QTY)
                                     FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
                                          DTLS
                                    WHERE    DTLS.REFRESH_INVENTORY_ITEM_ID =
                                                RSF.REFRESH_INVENTORY_ITEM_ID
                                          OR DTLS.REFRESH_INVENTORY_ITEM_ID =
                                                RSF.EXCESS_INVENTORY_ITEM_ID),
                                  0) > 0)
                     THEN
                        'P2'
                     WHEN (    NVL (
                                  (SELECT SUM (NETTABLE_MOS)
                                     FROM RC_FIN_DEMAND_LIST
                                    WHERE    PRODUCT_NAME =
                                                RSF.COMMON_PART_NUMBER
                                          OR PRODUCT_NAME =
                                                RSF.XREF_PART_NUMBER),
                                  0) >= 9
                           AND NVL (
                                  (SELECT SUM (
                                               MONTH_1_QTY
                                             + MONTH_2_QTY
                                             + MONTH_3_QTY
                                             + MONTH_4_QTY)
                                     FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS
                                          DTLS
                                    WHERE    DTLS.REFRESH_INVENTORY_ITEM_ID =
                                                RSF.REFRESH_INVENTORY_ITEM_ID
                                          OR DTLS.REFRESH_INVENTORY_ITEM_ID =
                                                RSF.EXCESS_INVENTORY_ITEM_ID),
                                  0) > 0)
                     THEN
                        'P3'
                     ELSE
                        NULL
                  END);*/

      UPDATE RC_SALES_FORECAST SF
         SET SF.PID_PRIORITY =
                (SELECT PID_PRIORITY
                   FROM CRPADM.RC_SALES_FORECAST CP
                  WHERE SF.RETAIL_PART_NUMBER = CP.RETAIL_PART_NUMBER);

      COMMIT;
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
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_PID_PRIORITY',
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
            'CRPADM.RC_SALES_FORECAST_ENGINE.RC_SALES_FORECAST_PID_PRIORITY',
            'PACKAGE',
            NULL,
            'Y');
   END;
END RC_SALES_FORECAST_ENGINE;
/