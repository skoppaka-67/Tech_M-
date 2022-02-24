CREATE OR REPLACE PACKAGE BODY CRPSC./*AppDB: 1044818*/
                                       "RC_INVENTORY_TRANSFER"
AS
    /**********************************************************************************************
    || Object Name    : RC_INVENTORY_TRANSFER
    || Modules        : Global Build Plan
    || Description    :Inventory transfer related changes in GBP
    || Modification History
    ||
    ||-----------------------------------------------------------------------------------------
    ||Date              By                   Version        Comments
    ||-----------------------------------------------------------------------------------------
    ||16-Feb-2016       Tressa               1.0            Initial version RC_INV_TRANSFER_ENGINE
    ||23-Feb-2016       Sweta Priyadarshi    1.1            Changes for Inventory rules setup screen
    ||07-Mar-2016       Mahesh Rolla         1.2            Changed Refurb to Refresh
    ||16-Mar-2016       Tressa John          1.3            Added insert into notifications table for UI notifications
    ||17-Mar-2016       Sweta Priyadarshi    1.4            Column level sorting and filtering for Inventory Transfer Report screen
    ||15-Dec-2017      Sweta Priyadarshi     1.5           Changed logic in RC_INV_TRANSFER_ENGINE
    ||19-Jan-2018      Sweta Priyadarshi     1.6           Changed logic in RC_INV_TRANSFER_ENGINE to allow WIP & Non Nettable locations (RF-REWRK)
    ||05-Apr-2018      Sweta Priyadarshi     1.7           Cross theater transfer only when Repair capability is not present in local theater
    ||12-Apr-2019      Sweta Priyadarshi     1.8           Removing ACTIVE check while sourcing inventory to be transferred
    ||-----------------------------------------------------------------------------------------
    **********************************************************************************************/
    PROCEDURE RC_INV_TRANSFER_ENGINE
    IS
        /*CURSOR c_nam_details
        IS
             SELECT DISTINCT PRD.REFRESH_INVENTORY_ITEM_ID,
                             TT.INVENTORY_ITEM_ID C3_INVENTORY_ITEM_ID,
                             STUP.THEATER_ID,
                             TT.LOCATION,
                             REGEXP_SUBSTR (TT.PLACE_ID,
                                            '[^- ]+',
                                            1,
                                            1)
                                PLACE_ID,
                             TT.QTY_ON_HAND_USEBL QTY_ON_HAND,
                             PRD.PROGRAM_TYPE
               FROM RC_C3_INVENTORY_DATA_SNAPSHOT TT
                    JOIN CRPADM.RC_PRODUCT_MASTER PRD
                       ON    TT.INVENTORY_ITEM_ID = PRD.REFRESH_INVENTORY_ITEM_ID
                          OR TT.INVENTORY_ITEM_ID = PRD.COMMON_INVENTORY_ITEM_ID
                          OR TT.INVENTORY_ITEM_ID = PRD.XREF_INVENTORY_ITEM_ID
                    JOIN CRPADM.RC_PRODUCT_REPAIR_SETUP STUP
                       ON PRD.REFRESH_INVENTORY_ITEM_ID =
                             STUP.REFRESH_INVENTORY_ITEM_ID
                    JOIN CRPADM.RC_SUB_INV_LOC_MSTR MP
                       ON TT.LOCATION = MP.SUB_INVENTORY_LOCATION
              WHERE     1 = 1
                    AND PRD.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5) --Changes made for Pid Deactivation EOS/EOL Automation
                    AND STUP.REFRESH_STATUS = 'ACTIVE'
                    AND STUP.THEATER_ID =
                           (SELECT CONFIG_ID
                              FROM CRPADM.RC_PRODUCT_CONFIG
                             WHERE     CONFIG_TYPE = 'THEATER'
                                   AND CONFIG_NAME = 'NAM')
                    AND MP.PROGRAM_TYPE IN (0, 1)
                    AND MP.NETTABLE_FLAG = 1
                    AND MP.INVENTORY_TYPE = 1
                    AND TT.QTY_ON_HAND_USEBL > 0
                    AND REGEXP_SUBSTR (TT.PLACE_ID,
                                       '[^- ]+',
                                       1,
                                       1) IN (SELECT ZCODE
                                                FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER
                                               WHERE THEATER_ID =
                                                        (SELECT CONFIG_ID
                                                           FROM CRPADM.RC_PRODUCT_CONFIG
                                                          WHERE     CONFIG_TYPE =
                                                                       'THEATER'
                                                                AND CONFIG_NAME =
                                                                       'NAM'))
           ORDER BY 1;

        CURSOR c_emea_details
        IS
             SELECT DISTINCT PRD.REFRESH_INVENTORY_ITEM_ID,
                             TT.INVENTORY_ITEM_ID C3_INVENTORY_ITEM_ID,
                             STUP.THEATER_ID,
                             TT.LOCATION,
                             REGEXP_SUBSTR (TT.PLACE_ID,
                                            '[^- ]+',
                                            1,
                                            1)
                                PLACE_ID,
                             TT.QTY_ON_HAND_USEBL QTY_ON_HAND,
                             PRD.PROGRAM_TYPE
               FROM RC_C3_INVENTORY_DATA_SNAPSHOT TT
                    JOIN CRPADM.RC_PRODUCT_MASTER PRD
                       ON    TT.INVENTORY_ITEM_ID = PRD.REFRESH_INVENTORY_ITEM_ID
                          OR TT.INVENTORY_ITEM_ID = PRD.COMMON_INVENTORY_ITEM_ID
                          OR TT.INVENTORY_ITEM_ID = PRD.XREF_INVENTORY_ITEM_ID
                    JOIN CRPADM.RC_PRODUCT_REPAIR_SETUP STUP
                       ON PRD.REFRESH_INVENTORY_ITEM_ID =
                             STUP.REFRESH_INVENTORY_ITEM_ID
                    JOIN CRPADM.RC_SUB_INV_LOC_MSTR MP
                       ON TT.LOCATION = MP.SUB_INVENTORY_LOCATION
              WHERE     1 = 1
                    AND PRD.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5) --Changes made for Pid Deactivation EOS/EOL Automation
                    AND STUP.REFRESH_STATUS = 'ACTIVE'
                    AND STUP.THEATER_ID =
                           (SELECT CONFIG_ID
                              FROM CRPADM.RC_PRODUCT_CONFIG
                             WHERE     CONFIG_TYPE = 'THEATER'
                                   AND CONFIG_NAME = 'EMEA')
                    AND MP.PROGRAM_TYPE IN (0, 1)
                    AND MP.NETTABLE_FLAG = 1
                    AND MP.INVENTORY_TYPE = 1
                    AND TT.QTY_ON_HAND_USEBL > 0
                    AND REGEXP_SUBSTR (TT.PLACE_ID,
                                       '[^- ]+',
                                       1,
                                       1) IN (SELECT ZCODE
                                                FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER
                                               WHERE THEATER_ID =
                                                        (SELECT CONFIG_ID
                                                           FROM CRPADM.RC_PRODUCT_CONFIG
                                                          WHERE     CONFIG_TYPE =
                                                                       'THEATER'
                                                                AND CONFIG_NAME =
                                                                       'EMEA'))
           ORDER BY 1;*/

        CURSOR c_refurb_method (
            lv_inv_item      NUMBER,
            lv_theater_id    NUMBER,
            lv_zcode         VARCHAR2)
        IS
            SELECT REFRESH_METHOD_ID
              FROM CRPADM.RC_PRODUCT_REPAIR_SETUP  ST
                   INNER JOIN CRPADM.RC_PRODUCT_REPAIR_PARTNER PTR
                       ON PTR.REPAIR_PARTNER_ID = ST.REPAIR_PARTNER_ID
             WHERE     ST.REFRESH_INVENTORY_ITEM_ID = lv_inv_item
                   AND ST.THEATER_ID = lv_theater_id
                   AND PTR.ZCODE = lv_zcode
                   AND (   REFRESH_STATUS = 'ACTIVE'
                        OR (    REFRESH_METHOD_ID = 3
                            AND REFRESH_STATUS = 'DEACTIVATED'));

        --                   AND REFRESH_STATUS = 'ACTIVE';

        CURSOR c_nam
        IS
            SELECT DTLS.REFRESH_INVENTORY_ITEM_ID,
                   DTLS.THEATER_ID,
                   MSTR.ROHS_CHECK_NEEDED,
                   NET_REQ,
                   NET_REQ_ROHS,
                   NET_REQ_NRHS
              FROM RC_INV_TRANS_NET_REQ_DETAILS  DTLS
                   INNER JOIN CRPADM.RC_PRODUCT_MASTER MSTR
                       ON DTLS.REFRESH_INVENTORY_ITEM_ID =
                          MSTR.REFRESH_INVENTORY_ITEM_ID
             WHERE     THEATER_ID =
                       (SELECT CONFIG_ID
                          FROM CRPADM.RC_PRODUCT_CONFIG
                         WHERE     CONFIG_TYPE = 'THEATER'
                               AND CONFIG_NAME = 'NAM')
                   AND (NET_REQ > 0);

        CURSOR c_emea
        IS
            SELECT DTLS.REFRESH_INVENTORY_ITEM_ID,
                   DTLS.THEATER_ID,
                   MSTR.ROHS_CHECK_NEEDED,
                   NET_REQ,
                   NET_REQ_ROHS,
                   NET_REQ_NRHS
              FROM RC_INV_TRANS_NET_REQ_DETAILS  DTLS
                   INNER JOIN CRPADM.RC_PRODUCT_MASTER MSTR
                       ON DTLS.REFRESH_INVENTORY_ITEM_ID =
                          MSTR.REFRESH_INVENTORY_ITEM_ID
             WHERE     THEATER_ID =
                       (SELECT CONFIG_ID
                          FROM CRPADM.RC_PRODUCT_CONFIG
                         WHERE     CONFIG_TYPE = 'THEATER'
                               AND CONFIG_NAME = 'EMEA')
                   AND (NET_REQ > 0);

        CURSOR c_dgi_details (
            lv_inv_item      NUMBER,
            lv_theater_id    NUMBER)
        IS
            SELECT DISTINCT
                   PRD.REFRESH_INVENTORY_ITEM_ID,
                   TT.INVENTORY_ITEM_ID
                       C3_INVENTORY_ITEM_ID,
                   STUP.THEATER_ID,
                   TT.LOCATION,
                   REGEXP_SUBSTR (TT.SITE,
                                  '[^- ]+',
                                  1,
                                  1)
                       PLACE_ID,
                   STUP.REFRESH_METHOD_ID,
                   REFRESH_YIELD,
                   FLOOR (
                       DECODE (
                           REFRESH_YIELD,
                           NULL, 0,
                           (  (TT.QTY_ON_HAND + TT.QTY_IN_TRANSIT)
                            * (REFRESH_YIELD / 100))))
                       QTY_ON_HAND,
                   PRD.PROGRAM_TYPE,
                   --                   (SELECT MIN (PRIORITY) Z_PRIORITY
                   --                      FROM CRPADM.RC_ASSIGNED_RP_SETUP
                   --                     WHERE     THEATER_ID = STUP.THEATER_ID
                   --                           AND STATUS = 'Y'
                   --                           AND PROGRAM_TYPE = PRD.PROGRAM_TYPE
                   --                           AND ZCODE = REGEXP_SUBSTR (TT.PLACE_ID,
                   --                                                      '[^- ]+',
                   --                                                      1,
                   --                                                      1))
                   RPSETUP.PRIORITY
                       Z_PRIORITY,
                   PRIO.PRIORITY,
                   FLG.ROHS_FLAG
              FROM CRPADM.RC_INV_BTS_C3_MV  TT
                   JOIN CRPADM.RC_PRODUCT_MASTER PRD
                       ON    TT.INVENTORY_ITEM_ID =
                             PRD.REFRESH_INVENTORY_ITEM_ID
                          OR TT.INVENTORY_ITEM_ID =
                             PRD.COMMON_INVENTORY_ITEM_ID
                          OR TT.INVENTORY_ITEM_ID =
                             PRD.XREF_INVENTORY_ITEM_ID
                   JOIN CRPADM.RC_PRODUCT_REPAIR_SETUP STUP
                       ON PRD.REFRESH_INVENTORY_ITEM_ID =
                          STUP.REFRESH_INVENTORY_ITEM_ID
                   JOIN CRPADM.RC_SUB_INV_LOC_MSTR MP
                       ON TT.LOCATION = MP.SUB_INVENTORY_LOCATION
                   JOIN CRPADM.RC_SUB_INV_LOC_FLG_DTLS FLG
                       ON MP.SUB_INVENTORY_ID = FLG.SUB_INVENTORY_ID
                   JOIN RC_SUB_INV_PRIORITY PRIO
                       ON     TT.LOCATION = PRIO.SUB_INV_LOC
                          AND PRD.PROGRAM_TYPE = PRIO.PROGRAM_TYPE
                   JOIN CRPADM.RC_ASSIGNED_RP_SETUP RPSETUP
                       ON     RPSETUP.PROGRAM_TYPE = PRD.PROGRAM_TYPE
                          AND RPSETUP.THEATER_ID = STUP.THEATER_ID
                          AND REGEXP_SUBSTR (TT.SITE,
                                             '[^- ]+',
                                             1,
                                             1) = RPSETUP.ZCODE
                          AND RPSETUP.REFRESH_METHOD_ID =
                              STUP.REFRESH_METHOD_ID
             WHERE     PRD.REFRESH_INVENTORY_ITEM_ID = lv_inv_item
                   AND PRD.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                   -- AND STUP.REFRESH_STATUS = 'ACTIVE'
                   AND STUP.THEATER_ID = lv_theater_id
                   AND MP.PROGRAM_TYPE IN (0, 1)
                   AND MP.NETTABLE_FLAG IN (0, 1)
                   AND MP.INVENTORY_TYPE IN (1, 2)
                   AND TT.QTY_ON_HAND >= 0
                   AND REGEXP_SUBSTR (TT.SITE,
                                      '[^- ]+',
                                      1,
                                      1) IN
                           (SELECT ZCODE
                              FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER
                             WHERE     REPAIR_PARTNER_ID =
                                       STUP.REPAIR_PARTNER_ID
                                   AND THEATER_ID = lv_theater_id)
            --                   AND STUP.REFRESH_METHOD_ID =
            --                       (SELECT *
            --                          FROM (  SELECT REFRESH_METHOD_ID
            --                                    FROM CRPADM.RC_PRODUCT_REPAIR_SETUP
            --                                   WHERE     REPAIR_PARTNER_ID =
            --                                             STUP.REPAIR_PARTNER_ID
            --                                         AND REFRESH_INVENTORY_ITEM_ID =
            --                                             STUP.REFRESH_INVENTORY_ITEM_ID
            --                                         AND REFRESH_STATUS = 'ACTIVE'
            --                                         AND REFRESH_METHOD_ID <> 3
            --                                ORDER BY REFRESH_METHOD_ID DESC)
            --                         WHERE ROWNUM = 1)
            UNION
            SELECT DISTINCT STUP.REFRESH_INVENTORY_ITEM_ID,
                            0                                   C3_INVENTORY_ITEM_ID,
                            STUP.THEATER_ID,
                            INVSETUP.SUB_INVENTORY_LOCATION     LOCATION,
                            INVSETUP.DESTINATION_LOCATION_ZCODE PLACE_ID,
                            STUP.REFRESH_METHOD_ID,
                            REFRESH_YIELD,
                            0                                   QTY_ON_HAND,
                            INVSETUP.PROGRAM_TYPE,
                            --                   (SELECT MIN (PRIORITY) Z_PRIORITY
                            --                      FROM CRPADM.RC_ASSIGNED_RP_SETUP
                            --                     WHERE     THEATER_ID = STUP.THEATER_ID
                            --                           AND STATUS = 'Y'
                            --                           AND PROGRAM_TYPE = INVSETUP.PROGRAM_TYPE
                            --                           AND ZCODE = INVSETUP.DESTINATION_LOCATION_ZCODE)
                            RPSETUP.PRIORITY                    Z_PRIORITY,
                            PRIO.PRIORITY,
                            FLG.ROHS_FLAG
              FROM RC_INV_TRANSFER_SETUP  INVSETUP
                   JOIN
                   (SELECT *
                      FROM CRPADM.RC_PRODUCT_REPAIR_SETUP
                     WHERE     REFRESH_INVENTORY_ITEM_ID = lv_inv_item
                           AND THEATER_ID = lv_theater_id
                           AND REFRESH_STATUS = 'ACTIVE') STUP
                       ON     STUP.THEATER_ID = INVSETUP.DESTINATION_REGION
                          AND STUP.REFRESH_METHOD_ID =
                              INVSETUP.DESTINATION_REFRESH_METHOD
                   JOIN CRPADM.RC_PRODUCT_MASTER RPM
                       ON STUP.REFRESH_INVENTORY_ITEM_ID =
                          RPM.REFRESH_INVENTORY_ITEM_ID
                   JOIN CRPADM.RC_PRODUCT_REPAIR_PARTNER REP
                       ON     REP.REPAIR_PARTNER_ID = STUP.REPAIR_PARTNER_ID
                          AND INVSETUP.DESTINATION_LOCATION_ZCODE = REP.ZCODE
                          AND STUP.THEATER_ID = REP.THEATER_ID
                   JOIN CRPADM.RC_SUB_INV_LOC_MSTR MP
                       ON INVSETUP.SUB_INVENTORY_LOCATION =
                          MP.SUB_INVENTORY_LOCATION
                   JOIN CRPADM.RC_SUB_INV_LOC_FLG_DTLS FLG
                       ON MP.SUB_INVENTORY_ID = FLG.SUB_INVENTORY_ID
                   JOIN RC_SUB_INV_PRIORITY PRIO
                       ON     INVSETUP.SUB_INVENTORY_LOCATION =
                              PRIO.SUB_INV_LOC
                          AND INVSETUP.PROGRAM_TYPE = PRIO.PROGRAM_TYPE
                   JOIN CRPADM.RC_ASSIGNED_RP_SETUP RPSETUP
                       ON     RPSETUP.PROGRAM_TYPE = INVSETUP.PROGRAM_TYPE
                          AND RPSETUP.THEATER_ID = STUP.THEATER_ID
                          AND REP.ZCODE = RPSETUP.ZCODE
                          AND RPSETUP.REFRESH_METHOD_ID =
                              STUP.REFRESH_METHOD_ID
             WHERE     IS_ACTIVE = 'Y'
                   --                   AND STUP.REFRESH_METHOD_ID =
                   --                       (SELECT *
                   --                          FROM (  SELECT REFRESH_METHOD_ID
                   --                                    FROM CRPADM.RC_PRODUCT_REPAIR_SETUP
                   --                                   WHERE     REPAIR_PARTNER_ID =
                   --                                             STUP.REPAIR_PARTNER_ID
                   --                                         AND REFRESH_INVENTORY_ITEM_ID =
                   --                                             STUP.REFRESH_INVENTORY_ITEM_ID
                   --                                         AND REFRESH_STATUS = 'ACTIVE'
                   --                                         AND REFRESH_METHOD_ID <> 3
                   --                                ORDER BY REFRESH_METHOD_ID DESC)
                   --                         WHERE ROWNUM = 1)
                   AND NOT EXISTS
                           (SELECT 1
                              FROM CRPADM.RC_INV_BTS_C3_MV TT
                             WHERE     (   TT.INVENTORY_ITEM_ID =
                                           RPM.REFRESH_INVENTORY_ITEM_ID
                                        OR TT.INVENTORY_ITEM_ID =
                                           RPM.COMMON_INVENTORY_ITEM_ID
                                        OR TT.INVENTORY_ITEM_ID =
                                           RPM.XREF_INVENTORY_ITEM_ID)
                                   AND TT.LOCATION =
                                       INVSETUP.SUB_INVENTORY_LOCATION
                                   AND REGEXP_SUBSTR (TT.SITE,
                                                      '[^- ]+',
                                                      1,
                                                      1) =
                                       INVSETUP.DESTINATION_LOCATION_ZCODE
                                   AND TT.QTY_ON_HAND >= 0)
            ORDER BY
                1,
                PRIORITY,
                REFRESH_METHOD_ID DESC,
                Z_PRIORITY;

        CURSOR c_src_dgi_details (
            lv_inv_item      NUMBER,
            lv_theater_id    NUMBER)
        IS
              SELECT DISTINCT PRD.REFRESH_INVENTORY_ITEM_ID,
                              TT.INVENTORY_ITEM_ID
                                  C3_INVENTORY_ITEM_ID,
                              STUP.THEATER_ID,
                              TT.LOCATION,
                              REGEXP_SUBSTR (TT.SITE,
                                             '[^- ]+',
                                             1,
                                             1)
                                  PLACE_ID,
                              0
                                  REFRESH_YIELD,
                              TT.QTY_ON_HAND
                                  QTY_ON_HAND,
                              PRD.PROGRAM_TYPE,
                              (SELECT MIN (PRIORITY) Z_PRIORITY
                                 FROM CRPADM.RC_ASSIGNED_RP_SETUP
                                WHERE     THEATER_ID = STUP.THEATER_ID
                                      AND STATUS = 'Y'
                                      AND PROGRAM_TYPE = PRD.PROGRAM_TYPE
                                      AND ZCODE = REGEXP_SUBSTR (TT.SITE,
                                                                 '[^- ]+',
                                                                 1,
                                                                 1))
                                  Z_PRIORITY,
                              PRIO.PRIORITY,
                              FLG.ROHS_FLAG
                FROM CRPADM.RC_INV_BTS_C3_MV TT
                     JOIN CRPADM.RC_PRODUCT_MASTER PRD
                         ON    TT.INVENTORY_ITEM_ID =
                               PRD.REFRESH_INVENTORY_ITEM_ID
                            OR TT.INVENTORY_ITEM_ID =
                               PRD.COMMON_INVENTORY_ITEM_ID
                            OR TT.INVENTORY_ITEM_ID =
                               PRD.XREF_INVENTORY_ITEM_ID
                     JOIN CRPADM.RC_PRODUCT_REPAIR_SETUP STUP
                         ON PRD.REFRESH_INVENTORY_ITEM_ID =
                            STUP.REFRESH_INVENTORY_ITEM_ID
                     JOIN CRPADM.RC_SUB_INV_LOC_MSTR MP
                         ON TT.LOCATION = MP.SUB_INVENTORY_LOCATION
                     JOIN CRPADM.RC_SUB_INV_LOC_FLG_DTLS FLG
                         ON MP.SUB_INVENTORY_ID = FLG.SUB_INVENTORY_ID
                     JOIN RC_SUB_INV_PRIORITY PRIO
                         ON     TT.LOCATION = PRIO.SUB_INV_LOC
                            AND PRD.PROGRAM_TYPE = PRIO.PROGRAM_TYPE
               WHERE     1 = 1
                     AND PRD.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                     AND STUP.REFRESH_INVENTORY_ITEM_ID = lv_inv_item
                     -- AND STUP.REFRESH_STATUS = 'ACTIVE'
                     AND STUP.THEATER_ID = lv_theater_id
                     AND MP.PROGRAM_TYPE IN (0, 1)
                     AND MP.NETTABLE_FLAG IN (0, 1)
                     AND MP.INVENTORY_TYPE IN (1, 2)
                     AND TT.QTY_ON_HAND > 0
                     AND REGEXP_SUBSTR (TT.SITE,
                                        '[^- ]+',
                                        1,
                                        1) IN
                             (SELECT DISTINCT SOURCE_LOCATION_ZCODE
                                FROM RC_INV_TRANSFER_SETUP
                               WHERE SOURCE_REGION = lv_theater_id)
                     AND REGEXP_SUBSTR (TT.SITE,
                                        '[^- ]+',
                                        1,
                                        1) IN
                             (SELECT ZCODE
                                FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER
                               WHERE     REPAIR_PARTNER_ID =
                                         STUP.REPAIR_PARTNER_ID
                                     AND THEATER_ID = lv_theater_id)
            ORDER BY Z_PRIORITY, PRIORITY;

        CURSOR c_rem_src_dgi_details (
            lv_inv_item      NUMBER,
            lv_theater_id    NUMBER)
        IS
            SELECT REFRESH_INVENTORY_ITEM_ID,
                   C3_INVENTORY_ITEM_ID,
                   THEATER_ID,
                   LOCATION,
                   PLACE_ID,
                   REFRESH_YIELD,
                   QTY_ON_HAND,
                   PROGRAM_TYPE,
                   Z_PRIORITY,
                   PRIORITY,
                   ROHS_FLAG
              FROM RC_INV_TRANS_REM_DGI_DETAILS
             WHERE     REFRESH_INVENTORY_ITEM_ID = lv_inv_item
                   AND THEATER_ID = lv_theater_id
            UNION
            SELECT DISTINCT PRD.REFRESH_INVENTORY_ITEM_ID,
                            TT.INVENTORY_ITEM_ID
                                C3_INVENTORY_ITEM_ID,
                            STUP.THEATER_ID,
                            TT.LOCATION,
                            REGEXP_SUBSTR (TT.SITE,
                                           '[^- ]+',
                                           1,
                                           1)
                                PLACE_ID,
                            0
                                REFRESH_YIELD,
                            TO_NUMBER (TT.QTY_ON_HAND)
                                QTY_ON_HAND,
                            PRD.PROGRAM_TYPE,
                            (SELECT MIN (PRIORITY) Z_PRIORITY
                               FROM CRPADM.RC_ASSIGNED_RP_SETUP
                              WHERE     THEATER_ID = STUP.THEATER_ID
                                    AND STATUS = 'Y'
                                    AND PROGRAM_TYPE = PRD.PROGRAM_TYPE
                                    AND ZCODE = REGEXP_SUBSTR (TT.SITE,
                                                               '[^- ]+',
                                                               1,
                                                               1))
                                Z_PRIORITY,
                            PRIO.PRIORITY,
                            FLG.ROHS_FLAG
              FROM CRPADM.RC_INV_BTS_C3_MV  TT
                   JOIN CRPADM.RC_PRODUCT_MASTER PRD
                       ON    TT.INVENTORY_ITEM_ID =
                             PRD.REFRESH_INVENTORY_ITEM_ID
                          OR TT.INVENTORY_ITEM_ID =
                             PRD.COMMON_INVENTORY_ITEM_ID
                          OR TT.INVENTORY_ITEM_ID =
                             PRD.XREF_INVENTORY_ITEM_ID
                   JOIN CRPADM.RC_PRODUCT_REPAIR_SETUP STUP
                       ON PRD.REFRESH_INVENTORY_ITEM_ID =
                          STUP.REFRESH_INVENTORY_ITEM_ID
                   JOIN CRPADM.RC_SUB_INV_LOC_MSTR MP
                       ON TT.LOCATION = MP.SUB_INVENTORY_LOCATION
                   JOIN CRPADM.RC_SUB_INV_LOC_FLG_DTLS FLG
                       ON MP.SUB_INVENTORY_ID = FLG.SUB_INVENTORY_ID
                   JOIN RC_SUB_INV_PRIORITY PRIO
                       ON     TT.LOCATION = PRIO.SUB_INV_LOC
                          AND PRD.PROGRAM_TYPE = PRIO.PROGRAM_TYPE
             WHERE     1 = 1
                   AND PRD.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                   AND STUP.REFRESH_INVENTORY_ITEM_ID = lv_inv_item
                   --                   AND STUP.REFRESH_STATUS = 'ACTIVE'
                   AND STUP.THEATER_ID = lv_theater_id
                   AND MP.PROGRAM_TYPE IN (0, 1)
                   AND MP.NETTABLE_FLAG IN (0, 1)
                   AND MP.INVENTORY_TYPE IN (1, 2)
                   AND TT.QTY_ON_HAND > 0
                   AND REGEXP_SUBSTR (TT.SITE,
                                      '[^- ]+',
                                      1,
                                      1) IN
                           (SELECT DISTINCT SOURCE_LOCATION_ZCODE
                              FROM RC_INV_TRANSFER_SETUP
                             WHERE SOURCE_REGION = lv_theater_id)
                   AND REGEXP_SUBSTR (TT.SITE,
                                      '[^- ]+',
                                      1,
                                      1) IN
                           (SELECT ZCODE
                              FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER
                             WHERE     REPAIR_PARTNER_ID =
                                       STUP.REPAIR_PARTNER_ID
                                   AND THEATER_ID = lv_theater_id)
                   AND (STUP.REFRESH_INVENTORY_ITEM_ID, STUP.THEATER_ID) IN
                           (SELECT REFRESH_INVENTORY_ITEM_ID, THEATER_ID
                              FROM RC_INV_TRANS_NET_REQ_DETAILS
                             WHERE     REFRESH_INVENTORY_ITEM_ID =
                                       lv_inv_item
                                   AND THEATER_ID = lv_theater_id)
                   AND (STUP.REFRESH_INVENTORY_ITEM_ID, STUP.THEATER_ID) NOT IN
                           (SELECT REFRESH_INVENTORY_ITEM_ID, THEATER_ID
                              FROM RC_INV_TRANS_REM_DGI_DETAILS
                             WHERE     REFRESH_INVENTORY_ITEM_ID =
                                       lv_inv_item
                                   AND THEATER_ID = lv_theater_id)
            ORDER BY Z_PRIORITY, PRIORITY;

        TYPE RC_DGI_OBJ IS RECORD
        (
            REFRESH_INVENTORY_ITEM_ID    NUMBER,
            C3_INVENTORY_ITEM_ID         NUMBER,
            THEATER_ID                   NUMBER,
            LOCATION                     VARCHAR2 (50 BYTE),
            PLACE_ID                     VARCHAR2 (100 BYTE),
            REFRESH_YIELD                NUMBER (10, 2),
            QTY_ON_HAND                  NUMBER,
            PROGRAM_TYPE                 NUMBER,
            Z_PRIORITY                   NUMBER,
            PRIORITY                     NUMBER,
            ROHS_FLAG                    VARCHAR2 (1 BYTE)
        );

        TYPE RC_DGI_LIST IS TABLE OF RC_DGI_OBJ;

        TYPE RC_DEST_DGI_OBJ IS RECORD
        (
            REFRESH_INVENTORY_ITEM_ID    NUMBER,
            C3_INVENTORY_ITEM_ID         NUMBER,
            THEATER_ID                   NUMBER,
            LOCATION                     VARCHAR2 (50 BYTE),
            PLACE_ID                     VARCHAR2 (100 BYTE),
            REFRESH_METHOD_ID            NUMBER,
            REFRESH_YIELD                NUMBER (10, 2),
            QTY_ON_HAND                  NUMBER,
            PROGRAM_TYPE                 NUMBER,
            Z_PRIORITY                   NUMBER,
            PRIORITY                     NUMBER,
            ROHS_FLAG                    VARCHAR2 (1 BYTE)
        );

        TYPE RC_DEST_DGI_LIST IS TABLE OF RC_DEST_DGI_OBJ;

        lv_src_dgi_list                  RC_DGI_LIST := RC_DGI_LIST ();
        lv_dgi_list                      RC_DEST_DGI_LIST := RC_DEST_DGI_LIST ();
        lv_dgi_cross_list                RC_DEST_DGI_LIST := RC_DEST_DGI_LIST ();
        lv_theater_refresh_method_nam    NUMBER;
        lv_theater_refresh_method_emea   NUMBER;
        lv_global_refresh_method         NUMBER;
        lv_priority                      NUMBER;
        lv_final_priority                NUMBER;
        lv_exists                        NUMBER;
        lv_max_refurb                    NUMBER;
        lv_rp_refresh_method_id          NUMBER;
        lv_destn_zloc                    VARCHAR2 (10);
        lv_dtn_zloc                      VARCHAR2 (10);
        lv_inv_loc                       VARCHAR2 (100);
        lv_dtn_refresh_method            NUMBER;

        lv_refurb_method                 RC_NORMALISED_NUMBER_LIST;
        lv_transfer_rules                RC_INV_TRANSFER_RULES_LIST;
        lv_refurb_check                  RC_NORMALISED_NUMBER_LIST;
        lv_source_loc_nam_list           RC_NORMALISED_LIST;
        lv_source_loc_emea_list          RC_NORMALISED_LIST;
        lv_net_req                       NUMBER;
        lv_net_req_emea                  NUMBER;
        lv_qty_on_hand                   NUMBER;
        lv_c3_id                         NUMBER;
        lv_cross_theater                 NUMBER;
        lv_net_req_rohs_nrhs             NUMBER;
        lv_nam_id                        NUMBER;
        lv_emea_id                       NUMBER;
        lv_rohs_flag                     VARCHAR2 (1 BYTE) DEFAULT NULL;
        lv_dgi_src_qty                   NUMBER := 0;
        lv_trans_qty                     NUMBER := 0;
        lv_rem_qty                       NUMBER := 0;
        lv_trans_yield_qty               NUMBER := 0;
        lv_orig_dgi_src_qty              NUMBER := 0;
        lv_orig_dgi_src_qty_yield        NUMBER := 0;
    BEGIN
        --Log the process START timestamp
        INSERT INTO CRPADM.RC_PROCESS_LOG
             VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                     'RC_INV_TRANSFER_ENGINE',
                     'START',
                     SYSDATE);

        COMMIT;
        lv_transfer_rules := RC_INV_TRANSFER_RULES_LIST ();
        lv_refurb_method := RC_NORMALISED_NUMBER_LIST ();
        lv_refurb_check := RC_NORMALISED_NUMBER_LIST ();

        --History
        INSERT INTO RC_INVENTORY_TRANSFER_TBL_HIST (
                        REFRESH_INVENTORY_ITEM_ID,
                        SOURCE_LOCATION_ZCODE,
                        DESTINATION_LOCATION_ZCODE,
                        SUB_INVENTORY_LOCATION,
                        C3_ONHAND_DGI,
                        CREATED_ON,
                        C3_INVENTORY_ITEM_ID,
                        QTY_TO_TRANSFER,
                        HISTORY_SAVE_DATE)
            SELECT REFRESH_INVENTORY_ITEM_ID,
                   SOURCE_LOCATION_ZCODE,
                   DESTINATION_LOCATION_ZCODE,
                   SUB_INVENTORY_LOCATION,
                   C3_ONHAND_DGI,
                   CREATED_ON,
                   C3_INVENTORY_ITEM_ID,
                   QTY_TO_TRANSFER,
                   SYSDATE
              FROM RC_INVENTORY_TRANSFER_TBL;

        INSERT INTO RC_INV_TRANS_NET_REQ_DETLS_HIS (
                        REFRESH_INVENTORY_ITEM_ID,
                        THEATER_ID,
                        BTO,
                        BTO_ROHS,
                        BTO_NON_ROHS,
                        CURR_MAX,
                        APPROVED_QUOTES,
                        APRROVED_QUOTES_ROHS,
                        APRROVED_QUOTES_NRHS,
                        FG_AT_BTS,
                        FG_ROHS,
                        FG_NON_ROHS,
                        FG_IN_TRANSIT,
                        FG_IN_TRANSIT_ROHS,
                        FG_IN_TRANSIT_NRHS,
                        FGI_IN_TRANSIT,
                        FGI_IN_TRANSIT_ROHS,
                        FGI_IN_TRANSIT_NON_ROHS,
                        SCREEN_ONLY_INV,
                        SCREEN_ONLY_INV_ROHS,
                        SCREEN_ONLY_INV_NRHS,
                        NET_REQ,
                        NET_REQ_ROHS,
                        NET_REQ_NRHS,
                        UPDATED_ON,
                        REM_FG_AT_BTS,
                        REM_FG_ROHS,
                        REM_FG_NON_ROHS,
                        ROHS_CHECK_NEEDED,
                        HISTORY_SAVE_DATE)
            SELECT REFRESH_INVENTORY_ITEM_ID,
                   THEATER_ID,
                   BTO,
                   BTO_ROHS,
                   BTO_NON_ROHS,
                   CURR_MAX,
                   APPROVED_QUOTES,
                   APRROVED_QUOTES_ROHS,
                   APRROVED_QUOTES_NRHS,
                   FG_AT_BTS,
                   FG_ROHS,
                   FG_NON_ROHS,
                   FG_IN_TRANSIT,
                   FG_IN_TRANSIT_ROHS,
                   FG_IN_TRANSIT_NRHS,
                   FGI_IN_TRANSIT,
                   FGI_IN_TRANSIT_ROHS,
                   FGI_IN_TRANSIT_NON_ROHS,
                   SCREEN_ONLY_INV,
                   SCREEN_ONLY_INV_ROHS,
                   SCREEN_ONLY_INV_NRHS,
                   NET_REQ,
                   NET_REQ_ROHS,
                   NET_REQ_NRHS,
                   UPDATED_ON,
                   REM_FG_AT_BTS,
                   REM_FG_ROHS,
                   REM_FG_NON_ROHS,
                   ROHS_CHECK_NEEDED,
                   SYSDATE
              FROM RC_INV_TRANS_NET_REQ_DETAILS;

        INSERT INTO RC_INV_TRANS_REM_DGI_DTLS_HIST (
                        REFRESH_INVENTORY_ITEM_ID,
                        C3_INVENTORY_ITEM_ID,
                        THEATER_ID,
                        LOCATION,
                        PLACE_ID,
                        REFRESH_YIELD,
                        QTY_ON_HAND,
                        PROGRAM_TYPE,
                        Z_PRIORITY,
                        PRIORITY,
                        ROHS_FLAG,
                        CREATED_ON,
                        HISTORY_SAVE_DATE)
            SELECT REFRESH_INVENTORY_ITEM_ID,
                   C3_INVENTORY_ITEM_ID,
                   THEATER_ID,
                   LOCATION,
                   PLACE_ID,
                   REFRESH_YIELD,
                   QTY_ON_HAND,
                   PROGRAM_TYPE,
                   Z_PRIORITY,
                   PRIORITY,
                   ROHS_FLAG,
                   CREATED_ON,
                   SYSDATE
              FROM RC_INV_TRANS_REM_DGI_DETAILS;

        --Truncate and reload table
        EXECUTE IMMEDIATE 'TRUNCATE TABLE RC_INVENTORY_TRANSFER_TBL';

        EXECUTE IMMEDIATE 'TRUNCATE TABLE RC_INV_TRANS_NET_REQ_DETAILS';

        EXECUTE IMMEDIATE 'TRUNCATE TABLE RC_INV_TRANS_REM_DGI_DETAILS';

        EXECUTE IMMEDIATE 'TRUNCATE TABLE RC_INV_TRANS_NET_REQ_DTLS_TMP';

        SELECT CONFIG_ID
          INTO lv_emea_id
          FROM CRPADM.RC_PRODUCT_CONFIG
         WHERE CONFIG_TYPE = 'THEATER' AND CONFIG_NAME = 'EMEA';

        SELECT CONFIG_ID
          INTO lv_nam_id
          FROM CRPADM.RC_PRODUCT_CONFIG
         WHERE CONFIG_TYPE = 'THEATER' AND CONFIG_NAME = 'NAM';

        SELECT MIN (CONFIG_ID)
          INTO lv_max_refurb
          FROM CRPADM.RC_PRODUCT_CONFIG
         WHERE CONFIG_TYPE = 'REFRESH_METHOD';

        SELECT CONFIG_ID
          BULK COLLECT INTO lv_refurb_check
          FROM CRPADM.RC_PRODUCT_CONFIG
         WHERE     CONFIG_TYPE = 'REFRESH_METHOD'
               AND CONFIG_NAME IN ('SCREEN', 'TEST');

        /*Fetch source sites for NAM and EMEA*/
        SELECT DISTINCT SOURCE_LOCATION_ZCODE
          BULK COLLECT INTO lv_source_loc_nam_list
          FROM RC_INV_TRANSFER_SETUP
         WHERE SOURCE_REGION =
               (SELECT CONFIG_ID
                  FROM CRPADM.RC_PRODUCT_CONFIG
                 WHERE CONFIG_TYPE = 'THEATER' AND CONFIG_NAME = 'NAM');

        SELECT DISTINCT SOURCE_LOCATION_ZCODE
          BULK COLLECT INTO lv_source_loc_emea_list
          FROM RC_INV_TRANSFER_SETUP
         WHERE SOURCE_REGION =
               (SELECT CONFIG_ID
                  FROM CRPADM.RC_PRODUCT_CONFIG
                 WHERE CONFIG_TYPE = 'THEATER' AND CONFIG_NAME = 'EMEA');

        BEGIN
            /*INSERT DATA IN TEMP TABLE FOR NET REQ CALCULATION*/
            MERGE INTO RC_INV_TRANS_NET_REQ_DETAILS REQ
                 USING (SELECT DISTINCT
                               STUP.REFRESH_INVENTORY_ITEM_ID,
                               STUP.THEATER_ID,
                               PRD.ROHS_CHECK_NEEDED
                          FROM CRPADM.RC_PRODUCT_MASTER  PRD
                               JOIN CRPADM.RC_PRODUCT_REPAIR_SETUP STUP
                                   ON PRD.REFRESH_INVENTORY_ITEM_ID =
                                      STUP.REFRESH_INVENTORY_ITEM_ID
                         WHERE     PRD.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                               AND STUP.REFRESH_STATUS = 'ACTIVE') PROD
                    ON (    REQ.REFRESH_INVENTORY_ITEM_ID =
                            PROD.REFRESH_INVENTORY_ITEM_ID
                        AND REQ.THEATER_ID = PROD.THEATER_ID)
            WHEN NOT MATCHED
            THEN
                INSERT     (REFRESH_INVENTORY_ITEM_ID,
                            THEATER_ID,
                            ROHS_CHECK_NEEDED)
                    VALUES (PROD.REFRESH_INVENTORY_ITEM_ID,
                            PROD.THEATER_ID,
                            PROD.ROHS_CHECK_NEEDED);

            /*Update BTO values from GBP tables*/

            MERGE INTO RC_INV_TRANS_NET_REQ_DETAILS REQ
                 USING (SELECT DISTINCT REFRESH_INVENTORY_ITEM_ID,
                                        THEATER_ID,
                                        BUILD_TO_ORDER,
                                        BTO_ROHS,
                                        BTO_NON_ROHS
                          FROM RC_GBP_BTO_BTM GBP) BTO
                    ON (    REQ.REFRESH_INVENTORY_ITEM_ID =
                            BTO.REFRESH_INVENTORY_ITEM_ID
                        AND REQ.THEATER_ID = BTO.THEATER_ID)
            WHEN MATCHED
            THEN
                UPDATE SET
                    REQ.BTO = BTO.BUILD_TO_ORDER,
                    REQ.BTO_NON_ROHS = BTO.BTO_NON_ROHS,
                    REQ.BTO_ROHS = BTO.BTO_ROHS;

            /*Update max values from forecasting tables*/

            MERGE INTO RC_INV_TRANS_NET_REQ_DETAILS REQ
                 USING (SELECT DISTINCT
                               REFRESH_INVENTORY_ITEM_ID,
                               THEATER_ID,
                               CURRENT_MAX
                          FROM RC_FORECASTING_CUMULATIVE) FORE
                    ON (    REQ.REFRESH_INVENTORY_ITEM_ID =
                            FORE.REFRESH_INVENTORY_ITEM_ID
                        AND REQ.THEATER_ID = FORE.THEATER_ID)
            WHEN MATCHED
            THEN
                UPDATE SET REQ.CURR_MAX = NVL (FORE.CURRENT_MAX, 0);

            /*Update approved quotes values from transation tables*/

            MERGE INTO RC_INV_TRANS_NET_REQ_DETAILS REQ
                 USING (  SELECT DISTINCT
                                 PROD.REFRESH_INVENTORY_ITEM_ID,
                                 THEATER_ID,
                                 SUM (QUANTITY_REQUESTED) QUANTITY_REQUESTED
                            FROM RC_SSOT_TRANSACTIONS_SNAPSHOT RT,
                                 CRPADM.RC_PRODUCT_MASTER     PROD,
                                 (SELECT DISTINCT
                                         REFRESH_INVENTORY_ITEM_ID,
                                         RS.THEATER_ID,
                                         THEATER_NAME
                                    FROM CRPADM.RC_PRODUCT_REPAIR_SETUP RS
                                         INNER JOIN
                                         CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                                             ON RS.REPAIR_PARTNER_ID =
                                                RP.REPAIR_PARTNER_ID) SETUP
                           WHERE     TRANSACTION_TYPE = 'QUOTE'
                                 AND QUOTE_STATUS = 'Approved'
                                 AND PRODUCT_ID = PROD.REFRESH_PART_NUMBER
                                 AND PROD.REFRESH_INVENTORY_ITEM_ID =
                                     SETUP.REFRESH_INVENTORY_ITEM_ID
                                 AND RT.RSCM_REGION = SETUP.THEATER_NAME
                        GROUP BY PROD.REFRESH_INVENTORY_ITEM_ID, THEATER_ID)
                       SSOT
                    ON (    REQ.REFRESH_INVENTORY_ITEM_ID =
                            SSOT.REFRESH_INVENTORY_ITEM_ID
                        AND REQ.THEATER_ID = SSOT.THEATER_ID)
            WHEN MATCHED
            THEN
                UPDATE SET
                    REQ.APPROVED_QUOTES = NVL (SSOT.QUANTITY_REQUESTED, 0);

            MERGE INTO RC_INV_TRANS_NET_REQ_DETAILS REQ
                 USING (  SELECT DISTINCT
                                 PROD.REFRESH_INVENTORY_ITEM_ID,
                                 THEATER_ID,
                                 SUM (QUANTITY_REQUESTED) QUANTITY_REQUESTED
                            FROM RC_SSOT_TRANSACTIONS_SNAPSHOT RT,
                                 CRPADM.RC_PRODUCT_MASTER     PROD,
                                 (SELECT DISTINCT
                                         REFRESH_INVENTORY_ITEM_ID,
                                         RS.THEATER_ID,
                                         THEATER_NAME
                                    FROM CRPADM.RC_PRODUCT_REPAIR_SETUP RS
                                         INNER JOIN
                                         CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                                             ON RS.REPAIR_PARTNER_ID =
                                                RP.REPAIR_PARTNER_ID) SETUP
                           WHERE     TRANSACTION_TYPE = 'QUOTE'
                                 AND QUOTE_STATUS = 'Approved'
                                 AND PRODUCT_ID = PROD.REFRESH_PART_NUMBER
                                 AND PROD.REFRESH_INVENTORY_ITEM_ID =
                                     SETUP.REFRESH_INVENTORY_ITEM_ID
                                 AND RT.RSCM_REGION = SETUP.THEATER_NAME
                                 AND ROHS_COMPLIANT = 'YES'
                        GROUP BY PROD.REFRESH_INVENTORY_ITEM_ID, THEATER_ID)
                       SSOT
                    ON (    REQ.REFRESH_INVENTORY_ITEM_ID =
                            SSOT.REFRESH_INVENTORY_ITEM_ID
                        AND REQ.THEATER_ID = SSOT.THEATER_ID)
            WHEN MATCHED
            THEN
                UPDATE SET
                    REQ.APRROVED_QUOTES_ROHS =
                        NVL (SSOT.QUANTITY_REQUESTED, 0);

            MERGE INTO RC_INV_TRANS_NET_REQ_DETAILS REQ
                 USING (  SELECT DISTINCT
                                 PROD.REFRESH_INVENTORY_ITEM_ID,
                                 THEATER_ID,
                                 SUM (QUANTITY_REQUESTED) QUANTITY_REQUESTED
                            FROM RC_SSOT_TRANSACTIONS_SNAPSHOT RT,
                                 CRPADM.RC_PRODUCT_MASTER     PROD,
                                 (SELECT DISTINCT
                                         REFRESH_INVENTORY_ITEM_ID,
                                         RS.THEATER_ID,
                                         THEATER_NAME
                                    FROM CRPADM.RC_PRODUCT_REPAIR_SETUP RS
                                         INNER JOIN
                                         CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                                             ON RS.REPAIR_PARTNER_ID =
                                                RP.REPAIR_PARTNER_ID) SETUP
                           WHERE     TRANSACTION_TYPE = 'QUOTE'
                                 AND QUOTE_STATUS = 'Approved'
                                 AND PRODUCT_ID = PROD.REFRESH_PART_NUMBER
                                 AND PROD.REFRESH_INVENTORY_ITEM_ID =
                                     SETUP.REFRESH_INVENTORY_ITEM_ID
                                 AND RSCM_REGION = SETUP.THEATER_NAME
                                 AND ROHS_COMPLIANT = 'NO'
                        GROUP BY PROD.REFRESH_INVENTORY_ITEM_ID, THEATER_ID)
                       SSOT
                    ON (    REQ.REFRESH_INVENTORY_ITEM_ID =
                            SSOT.REFRESH_INVENTORY_ITEM_ID
                        AND REQ.THEATER_ID = SSOT.THEATER_ID)
            WHEN MATCHED
            THEN
                UPDATE SET
                    REQ.APRROVED_QUOTES_NRHS =
                        NVL (SSOT.QUANTITY_REQUESTED, 0);


            /*Update FG values from snapshot tables*/

            MERGE INTO RC_INV_TRANS_NET_REQ_DETAILS REQ
                 USING (  SELECT DISTINCT
                                 PROD.REFRESH_INVENTORY_ITEM_ID,
                                 MAPP.SITE_CODE,
                                 CASE
                                     WHEN MAPP.SITE_CODE = 'FVE'
                                     THEN
                                         lv_emea_id
                                     WHEN MAPP.SITE_CODE = 'LRO'
                                     THEN
                                         lv_nam_id
                                 END
                                     THEATER_ID,
                                 SUM (
                                       NVL (
                                           TO_NUMBER (
                                               REPLACE (QTY_ON_HAND, ',', '')),
                                           0)
                                     + NVL (
                                           TO_NUMBER (
                                               REPLACE (QTY_RESERVED, ',', '')),
                                           0))
                                     QTY_ON_HAND,
                                 SUM (
                                     NVL (
                                         TO_NUMBER (
                                             REPLACE (QTY_IN_TRANSIT, ',', '')),
                                         0))
                                     QTY_IN_TRANSIT
                            FROM CRPADM.RC_INV_BTS_C3_MV       MV,
                                 CRPADM.RC_PRODUCT_MASTER      PROD,
                                 RMKTGADM.RMK_INV_SITE_MAPPINGS MAPP
                           WHERE     MAPP.SITE_CODE IN ('LRO', 'FVE')
                                 AND LOCATION = 'FG'
                                 AND PART_NUMBER = PROD.REFRESH_PART_NUMBER
                                 AND MAPP.SITE = MV.SITE
                                 AND MAPP.INV_TYPE = 'FGI'
                                 AND PROD.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                        GROUP BY PROD.REFRESH_INVENTORY_ITEM_ID, SITE_CODE)
                       INV
                    ON (    REQ.REFRESH_INVENTORY_ITEM_ID =
                            INV.REFRESH_INVENTORY_ITEM_ID
                        AND REQ.THEATER_ID = INV.THEATER_ID)
            WHEN MATCHED
            THEN
                UPDATE SET
                    REQ.FG_AT_BTS = INV.QTY_ON_HAND,
                    REQ.FG_IN_TRANSIT = INV.QTY_IN_TRANSIT;

            --         MERGE INTO RC_INV_TRANS_NET_REQ_DETAILS REQ
            --              USING (  SELECT DISTINCT
            --                              PROD.REFRESH_INVENTORY_ITEM_ID,
            --                              THEATER_ID,
            --                              SUM (
            --                                 NVL (
            --                                    TO_NUMBER (REPLACE (QTY_ON_HAND, ',', '')),
            --                                    0))
            --                                 QTY_ON_HAND,
            --                              SUM (
            --                                 NVL (
            --                                    TO_NUMBER (
            --                                       REPLACE (QTY_IN_TRANSIT, ',', '')),
            --                                    0))
            --                                 QTY_IN_TRANSIT
            --                         FROM RC_SSOT_INVENTORY_SNAPSHOT,
            --                              CRPADM.RC_PRODUCT_MASTER PROD,
            --                              (SELECT DISTINCT
            --                                      REFRESH_INVENTORY_ITEM_ID, THEATER_ID
            --                                 FROM CRPADM.RC_PRODUCT_REPAIR_SETUP) SETUP
            --                        WHERE     SITE IN ('LRO')
            --                              AND LOCATION = 'FG'
            --                              AND PART_NUMBER = PROD.REFRESH_PART_NUMBER
            --                              AND PROD.REFRESH_INVENTORY_ITEM_ID =
            --                                     SETUP.REFRESH_INVENTORY_ITEM_ID
            --                     GROUP BY PROD.REFRESH_INVENTORY_ITEM_ID, THEATER_ID) INV
            --                 ON (    REQ.REFRESH_INVENTORY_ITEM_ID =
            --                            INV.REFRESH_INVENTORY_ITEM_ID
            --                     AND REQ.THEATER_ID = INV.THEATER_ID
            --                     AND REQ.THEATER_ID =
            --                            (SELECT CONFIG_ID
            --                               FROM CRPADM.RC_PRODUCT_CONFIG
            --                              WHERE     CONFIG_TYPE = 'THEATER'
            --                                    AND CONFIG_NAME = 'NAM'))
            --         WHEN MATCHED
            --         THEN
            --            UPDATE SET
            --               REQ.FG_AT_BTS = INV.QTY_ON_HAND,
            --               REQ.FG_IN_TRANSIT = INV.QTY_IN_TRANSIT;

            MERGE INTO RC_INV_TRANS_NET_REQ_DETAILS REQ
                 USING (  SELECT DISTINCT
                                 PROD.REFRESH_INVENTORY_ITEM_ID,
                                 MAPP.SITE_CODE,
                                 CASE
                                     WHEN MAPP.SITE_CODE = 'FVE'
                                     THEN
                                         lv_emea_id
                                     WHEN MAPP.SITE_CODE = 'LRO'
                                     THEN
                                         lv_nam_id
                                 END
                                     THEATER_ID,
                                 SUM (
                                       NVL (
                                           TO_NUMBER (
                                               REPLACE (QTY_ON_HAND, ',', '')),
                                           0)
                                     + NVL (
                                           TO_NUMBER (
                                               REPLACE (QTY_RESERVED, ',', '')),
                                           0))
                                     QTY_ON_HAND,
                                 SUM (
                                     NVL (
                                         TO_NUMBER (
                                             REPLACE (QTY_IN_TRANSIT, ',', '')),
                                         0))
                                     QTY_IN_TRANSIT
                            FROM CRPADM.RC_INV_BTS_C3_MV       MV,
                                 CRPADM.RC_PRODUCT_MASTER      PROD,
                                 RMKTGADM.RMK_INV_SITE_MAPPINGS MAPP
                           WHERE     MAPP.SITE_CODE IN ('LRO', 'FVE')
                                 AND LOCATION = 'FG'
                                 AND PART_NUMBER = PROD.REFRESH_PART_NUMBER
                                 AND MAPP.SITE = MV.SITE
                                 AND MAPP.INV_TYPE = 'FGI'
                                 AND ROHS_PART = 'YES'
                                 AND PROD.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                        GROUP BY PROD.REFRESH_INVENTORY_ITEM_ID, SITE_CODE)
                       INV
                    ON (    REQ.REFRESH_INVENTORY_ITEM_ID =
                            INV.REFRESH_INVENTORY_ITEM_ID
                        AND REQ.THEATER_ID = INV.THEATER_ID)
            WHEN MATCHED
            THEN
                UPDATE SET
                    REQ.FG_ROHS = INV.QTY_ON_HAND,
                    REQ.FG_IN_TRANSIT_ROHS = INV.QTY_IN_TRANSIT;

            --         MERGE INTO RC_INV_TRANS_NET_REQ_DETAILS REQ
            --              USING (  SELECT DISTINCT
            --                              PROD.REFRESH_INVENTORY_ITEM_ID,
            --                              THEATER_ID,
            --                              SUM (
            --                                 NVL (
            --                                    TO_NUMBER (REPLACE (QTY_ON_HAND, ',', '')),
            --                                    0))
            --                                 QTY_ON_HAND,
            --                              SUM (
            --                                 NVL (
            --                                    TO_NUMBER (
            --                                       REPLACE (QTY_IN_TRANSIT, ',', '')),
            --                                    0))
            --                                 QTY_IN_TRANSIT
            --                         FROM RC_SSOT_INVENTORY_SNAPSHOT,
            --                              CRPADM.RC_PRODUCT_MASTER PROD,
            --                              (SELECT DISTINCT
            --                                      REFRESH_INVENTORY_ITEM_ID, THEATER_ID
            --                                 FROM CRPADM.RC_PRODUCT_REPAIR_SETUP) SETUP
            --                        WHERE     SITE IN ('LRO')
            --                              AND LOCATION = 'FG'
            --                              AND PART_NUMBER = PROD.REFRESH_PART_NUMBER
            --                              AND PROD.REFRESH_INVENTORY_ITEM_ID =
            --                                     SETUP.REFRESH_INVENTORY_ITEM_ID
            --                              AND ROHS_PART = 'YES'
            --                     GROUP BY PROD.REFRESH_INVENTORY_ITEM_ID, THEATER_ID) INV
            --                 ON (    REQ.REFRESH_INVENTORY_ITEM_ID =
            --                            INV.REFRESH_INVENTORY_ITEM_ID
            --                     AND REQ.THEATER_ID = INV.THEATER_ID
            --                     AND REQ.THEATER_ID =
            --                            (SELECT CONFIG_ID
            --                               FROM CRPADM.RC_PRODUCT_CONFIG
            --                              WHERE     CONFIG_TYPE = 'THEATER'
            --                                    AND CONFIG_NAME = 'NAM'))
            --         WHEN MATCHED
            --         THEN
            --            UPDATE SET
            --               REQ.FG_ROHS = INV.QTY_ON_HAND,
            --               REQ.FG_IN_TRANSIT_ROHS = INV.QTY_IN_TRANSIT;

            MERGE INTO RC_INV_TRANS_NET_REQ_DETAILS REQ
                 USING (  SELECT DISTINCT
                                 PROD.REFRESH_INVENTORY_ITEM_ID,
                                 MAPP.SITE_CODE,
                                 CASE
                                     WHEN MAPP.SITE_CODE = 'FVE'
                                     THEN
                                         lv_emea_id
                                     WHEN MAPP.SITE_CODE = 'LRO'
                                     THEN
                                         lv_nam_id
                                 END
                                     THEATER_ID,
                                 SUM (
                                       NVL (
                                           TO_NUMBER (
                                               REPLACE (QTY_ON_HAND, ',', '')),
                                           0)
                                     + NVL (
                                           TO_NUMBER (
                                               REPLACE (QTY_RESERVED, ',', '')),
                                           0))
                                     QTY_ON_HAND,
                                 SUM (
                                     NVL (
                                         TO_NUMBER (
                                             REPLACE (QTY_IN_TRANSIT, ',', '')),
                                         0))
                                     QTY_IN_TRANSIT
                            FROM CRPADM.RC_INV_BTS_C3_MV       MV,
                                 CRPADM.RC_PRODUCT_MASTER      PROD,
                                 RMKTGADM.RMK_INV_SITE_MAPPINGS MAPP
                           WHERE     MAPP.SITE_CODE IN ('LRO', 'FVE')
                                 AND LOCATION = 'FG'
                                 AND PART_NUMBER = PROD.REFRESH_PART_NUMBER
                                 AND MAPP.SITE = MV.SITE
                                 AND MAPP.INV_TYPE = 'FGI'
                                 AND ROHS_PART = 'NO'
                                 AND PROD.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                        GROUP BY PROD.REFRESH_INVENTORY_ITEM_ID, SITE_CODE)
                       INV
                    ON (    REQ.REFRESH_INVENTORY_ITEM_ID =
                            INV.REFRESH_INVENTORY_ITEM_ID
                        AND REQ.THEATER_ID = INV.THEATER_ID)
            WHEN MATCHED
            THEN
                UPDATE SET
                    REQ.FG_NON_ROHS = INV.QTY_ON_HAND,
                    REQ.FG_IN_TRANSIT_NRHS = INV.QTY_IN_TRANSIT;

            --         MERGE INTO RC_INV_TRANS_NET_REQ_DETAILS REQ
            --              USING (  SELECT DISTINCT
            --                              PROD.REFRESH_INVENTORY_ITEM_ID,
            --                              THEATER_ID,
            --                              SUM (
            --                                 NVL (
            --                                    TO_NUMBER (REPLACE (QTY_ON_HAND, ',', '')),
            --                                    0))
            --                                 QTY_ON_HAND,
            --                              SUM (
            --                                 NVL (
            --                                    TO_NUMBER (
            --                                       REPLACE (QTY_IN_TRANSIT, ',', '')),
            --                                    0))
            --                                 QTY_IN_TRANSIT
            --                         FROM RC_SSOT_INVENTORY_SNAPSHOT,
            --                              CRPADM.RC_PRODUCT_MASTER PROD,
            --                              (SELECT DISTINCT
            --                                      REFRESH_INVENTORY_ITEM_ID, THEATER_ID
            --                                 FROM CRPADM.RC_PRODUCT_REPAIR_SETUP) SETUP
            --                        WHERE     SITE IN ('LRO')
            --                              AND LOCATION = 'FG'
            --                              AND PART_NUMBER = PROD.REFRESH_PART_NUMBER
            --                              AND PROD.REFRESH_INVENTORY_ITEM_ID =
            --                                     SETUP.REFRESH_INVENTORY_ITEM_ID
            --                              AND ROHS_PART = 'NO'
            --                     GROUP BY PROD.REFRESH_INVENTORY_ITEM_ID, THEATER_ID) INV
            --                 ON (    REQ.REFRESH_INVENTORY_ITEM_ID =
            --                            INV.REFRESH_INVENTORY_ITEM_ID
            --                     AND REQ.THEATER_ID = INV.THEATER_ID
            --                     AND REQ.THEATER_ID =
            --                            (SELECT CONFIG_ID
            --                               FROM CRPADM.RC_PRODUCT_CONFIG
            --                              WHERE     CONFIG_TYPE = 'THEATER'
            --                                    AND CONFIG_NAME = 'NAM'))
            --         WHEN MATCHED
            --         THEN
            --            UPDATE SET
            --               REQ.FG_NON_ROHS = INV.QTY_ON_HAND,
            --               REQ.FG_IN_TRANSIT_NRHS = INV.QTY_IN_TRANSIT;

            /*Update FGI values from snapshot tables*/

            MERGE INTO RC_INV_TRANS_NET_REQ_DETAILS REQ
                 USING (  SELECT DISTINCT
                                 PROD.REFRESH_INVENTORY_ITEM_ID,
                                 THEATER_ID,
                                 SUM (
                                       NVL (
                                           TO_NUMBER (
                                               REPLACE (QTY_ON_HAND, ',', '')),
                                           0)
                                     + NVL (
                                           TO_NUMBER (
                                               REPLACE (QTY_IN_TRANSIT,
                                                        ',',
                                                        '')),
                                           0))
                                     QTY_IN_TRANSIT
                            FROM CRPADM.RC_INV_BTS_C3_MV   MV,
                                 CRPADM.RC_PRODUCT_MASTER  PROD,
                                 (SELECT DISTINCT ZCODE, THEATER_ID
                                    FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER) RP,
                                 CRPADM.RC_SUB_INV_LOC_MSTR SUB
                           WHERE     LOCATION = SUB.SUB_INVENTORY_LOCATION
                                 AND (   MV.INVENTORY_ITEM_ID =
                                         PROD.REFRESH_INVENTORY_ITEM_ID
                                      OR MV.INVENTORY_ITEM_ID =
                                         PROD.COMMON_INVENTORY_ITEM_ID
                                      OR MV.INVENTORY_ITEM_ID =
                                         PROD.XREF_INVENTORY_ITEM_ID)
                                 AND MV.INVENTORY_ITEM_ID <> 0
                                 --                                 AND PART_NUMBER = PROD.REFRESH_PART_NUMBER
                                 AND LOCATION <> 'FG'
                                 AND INVENTORY_TYPE = 0
                                 AND SUB.NETTABLE_FLAG = 1
                                 AND SUB.PROGRAM_TYPE != 2
                                 AND PROD.PROGRAM_TYPE = SUB.PROGRAM_TYPE
                                 AND REGEXP_SUBSTR (SITE,
                                                    '[^- ]+',
                                                    1,
                                                    1) = RP.ZCODE
                                 AND PROD.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                        GROUP BY PROD.REFRESH_INVENTORY_ITEM_ID, THEATER_ID)
                       INV
                    ON (    REQ.REFRESH_INVENTORY_ITEM_ID =
                            INV.REFRESH_INVENTORY_ITEM_ID
                        AND REQ.THEATER_ID = INV.THEATER_ID)
            WHEN MATCHED
            THEN
                UPDATE SET REQ.FGI_IN_TRANSIT = INV.QTY_IN_TRANSIT;

            MERGE INTO RC_INV_TRANS_NET_REQ_DETAILS REQ
                 USING (  SELECT DISTINCT
                                 PROD.REFRESH_INVENTORY_ITEM_ID,
                                 THEATER_ID,
                                 SUM (
                                       NVL (
                                           TO_NUMBER (
                                               REPLACE (QTY_ON_HAND, ',', '')),
                                           0)
                                     + NVL (
                                           TO_NUMBER (
                                               REPLACE (QTY_IN_TRANSIT,
                                                        ',',
                                                        '')),
                                           0))
                                     QTY_IN_TRANSIT
                            FROM CRPADM.RC_INV_BTS_C3_MV   MV,
                                 CRPADM.RC_PRODUCT_MASTER  PROD,
                                 (SELECT DISTINCT ZCODE, THEATER_ID
                                    FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER) RP,
                                 CRPADM.RC_SUB_INV_LOC_MSTR SUB
                           WHERE     LOCATION = SUB.SUB_INVENTORY_LOCATION
                                 AND (   MV.INVENTORY_ITEM_ID =
                                         PROD.REFRESH_INVENTORY_ITEM_ID
                                      OR MV.INVENTORY_ITEM_ID =
                                         PROD.COMMON_INVENTORY_ITEM_ID
                                      OR MV.INVENTORY_ITEM_ID =
                                         PROD.XREF_INVENTORY_ITEM_ID)
                                 AND MV.INVENTORY_ITEM_ID <> 0
                                 --                                 AND PART_NUMBER = PROD.REFRESH_PART_NUMBER
                                 AND LOCATION <> 'FG'
                                 AND INVENTORY_TYPE = 0
                                 AND SUB.NETTABLE_FLAG = 1
                                 AND SUB.PROGRAM_TYPE != 2
                                 AND ROHS_CHECK_NEEDED = 'Y'
                                 AND PROD.PROGRAM_TYPE = SUB.PROGRAM_TYPE
                                 AND REGEXP_SUBSTR (SITE,
                                                    '[^- ]+',
                                                    1,
                                                    1) = RP.ZCODE
                                 AND PROD.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                        GROUP BY PROD.REFRESH_INVENTORY_ITEM_ID, THEATER_ID)
                       INV
                    ON (    REQ.REFRESH_INVENTORY_ITEM_ID =
                            INV.REFRESH_INVENTORY_ITEM_ID
                        AND REQ.THEATER_ID = INV.THEATER_ID)
            WHEN MATCHED
            THEN
                UPDATE SET REQ.FGI_IN_TRANSIT_ROHS = INV.QTY_IN_TRANSIT;

            MERGE INTO RC_INV_TRANS_NET_REQ_DETAILS REQ
                 USING (  SELECT DISTINCT
                                 PROD.REFRESH_INVENTORY_ITEM_ID,
                                 THEATER_ID,
                                 SUM (
                                       NVL (
                                           TO_NUMBER (
                                               REPLACE (QTY_ON_HAND, ',', '')),
                                           0)
                                     + NVL (
                                           TO_NUMBER (
                                               REPLACE (QTY_IN_TRANSIT,
                                                        ',',
                                                        '')),
                                           0))
                                     QTY_IN_TRANSIT
                            FROM CRPADM.RC_INV_BTS_C3_MV   MV,
                                 CRPADM.RC_PRODUCT_MASTER  PROD,
                                 (SELECT DISTINCT ZCODE, THEATER_ID
                                    FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER) RP,
                                 CRPADM.RC_SUB_INV_LOC_MSTR SUB
                           WHERE     LOCATION = SUB.SUB_INVENTORY_LOCATION
                                 AND (   MV.INVENTORY_ITEM_ID =
                                         PROD.REFRESH_INVENTORY_ITEM_ID
                                      OR MV.INVENTORY_ITEM_ID =
                                         PROD.COMMON_INVENTORY_ITEM_ID
                                      OR MV.INVENTORY_ITEM_ID =
                                         PROD.XREF_INVENTORY_ITEM_ID)
                                 AND MV.INVENTORY_ITEM_ID <> 0
                                 --                                 AND PART_NUMBER = PROD.REFRESH_PART_NUMBER
                                 AND LOCATION <> 'FG'
                                 AND INVENTORY_TYPE = 0
                                 AND SUB.NETTABLE_FLAG = 1
                                 AND SUB.PROGRAM_TYPE != 2
                                 AND ROHS_CHECK_NEEDED = 'N'
                                 AND PROD.PROGRAM_TYPE = SUB.PROGRAM_TYPE
                                 AND REGEXP_SUBSTR (SITE,
                                                    '[^- ]+',
                                                    1,
                                                    1) = RP.ZCODE
                                 AND PROD.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                        GROUP BY PROD.REFRESH_INVENTORY_ITEM_ID, THEATER_ID)
                       INV
                    ON (    REQ.REFRESH_INVENTORY_ITEM_ID =
                            INV.REFRESH_INVENTORY_ITEM_ID
                        AND REQ.THEATER_ID = INV.THEATER_ID)
            WHEN MATCHED
            THEN
                UPDATE SET REQ.FGI_IN_TRANSIT_NON_ROHS = INV.QTY_IN_TRANSIT;

            /*UPDATE screen only inventory*/

            MERGE INTO RC_INV_TRANS_NET_REQ_DETAILS REQ
                 USING (  SELECT DISTINCT
                                 PROD_MSTR.REFRESH_INVENTORY_ITEM_ID,
                                 SETUP.THEATER_ID,
                                 SUM (
                                     NVL (
                                         TO_NUMBER (
                                             REPLACE (INVT.QTY_ON_HAND,
                                                      ',',
                                                      '')),
                                         0))
                                     QTY_ON_HAND
                            FROM CRPADM.RC_INV_BTS_C3_MV INVT
                                 INNER JOIN CRPADM.RC_PRODUCT_MASTER PROD_MSTR
                                     ON (   INVT.INVENTORY_ITEM_ID =
                                            PROD_MSTR.REFRESH_INVENTORY_ITEM_ID
                                         OR INVT.INVENTORY_ITEM_ID =
                                            PROD_MSTR.COMMON_INVENTORY_ITEM_ID
                                         OR INVT.INVENTORY_ITEM_ID =
                                            PROD_MSTR.XREF_INVENTORY_ITEM_ID)
                                 INNER JOIN
                                 CRPADM.RC_PRODUCT_REPAIR_SETUP SETUP
                                     ON PROD_MSTR.REFRESH_INVENTORY_ITEM_ID =
                                        SETUP.REFRESH_INVENTORY_ITEM_ID
                                 INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR E
                                     ON     TRIM (INVT.LOCATION) =
                                            TRIM (E.SUB_INVENTORY_LOCATION)
                                        AND E.PROGRAM_TYPE IN (0, 1)
                                        AND E.NETTABLE_FLAG IN (0, 1)
                                 INNER JOIN CRPADM.RC_SUB_INV_LOC_FLG_DTLS F
                                     ON E.SUB_INVENTORY_ID = F.SUB_INVENTORY_ID
                           WHERE     F.REFRESH_METHOD_ID = 3
                                 AND REGEXP_SUBSTR (INVT.SITE,
                                                    '[^- ]+',
                                                    1,
                                                    1) =
                                     (SELECT ZCODE
                                        FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER
                                             RP
                                       WHERE RP.REPAIR_PARTNER_ID =
                                             SETUP.REPAIR_PARTNER_ID)
                                 AND SETUP.REFRESH_STATUS = 'ACTIVE'
                                 AND SETUP.REFRESH_METHOD_ID =
                                     (SELECT CONFIG_ID
                                        FROM CRPADM.RC_PRODUCT_CONFIG
                                       WHERE     CONFIG_TYPE = 'REFRESH_METHOD'
                                             AND CONFIG_NAME = ('SCREEN'))
                        GROUP BY PROD_MSTR.REFRESH_INVENTORY_ITEM_ID,
                                 SETUP.THEATER_ID) INV
                    ON (    REQ.REFRESH_INVENTORY_ITEM_ID =
                            INV.REFRESH_INVENTORY_ITEM_ID
                        AND REQ.THEATER_ID = INV.THEATER_ID)
            WHEN MATCHED
            THEN
                UPDATE SET REQ.SCREEN_ONLY_INV = INV.QTY_ON_HAND;

            MERGE INTO RC_INV_TRANS_NET_REQ_DETAILS REQ
                 USING (  SELECT DISTINCT
                                 PROD_MSTR.REFRESH_INVENTORY_ITEM_ID,
                                 SETUP.THEATER_ID,
                                 SUM (
                                     NVL (
                                         TO_NUMBER (
                                             REPLACE (INVT.QTY_ON_HAND,
                                                      ',',
                                                      '')),
                                         0))
                                     QTY_ON_HAND
                            FROM CRPADM.RC_INV_BTS_C3_MV INVT
                                 INNER JOIN CRPADM.RC_PRODUCT_MASTER PROD_MSTR
                                     ON (   INVT.INVENTORY_ITEM_ID =
                                            PROD_MSTR.REFRESH_INVENTORY_ITEM_ID
                                         OR INVT.INVENTORY_ITEM_ID =
                                            PROD_MSTR.COMMON_INVENTORY_ITEM_ID
                                         OR INVT.INVENTORY_ITEM_ID =
                                            PROD_MSTR.XREF_INVENTORY_ITEM_ID)
                                 INNER JOIN
                                 CRPADM.RC_PRODUCT_REPAIR_SETUP SETUP
                                     ON PROD_MSTR.REFRESH_INVENTORY_ITEM_ID =
                                        SETUP.REFRESH_INVENTORY_ITEM_ID
                                 INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR E
                                     ON     TRIM (INVT.LOCATION) =
                                            TRIM (E.SUB_INVENTORY_LOCATION)
                                        AND E.PROGRAM_TYPE IN (0, 1)
                                        AND E.NETTABLE_FLAG IN (0, 1)
                                 INNER JOIN CRPADM.RC_SUB_INV_LOC_FLG_DTLS F
                                     ON E.SUB_INVENTORY_ID = F.SUB_INVENTORY_ID
                           WHERE     F.REFRESH_METHOD_ID = 3
                                 AND ROHS_FLAG = 1
                                 AND REGEXP_SUBSTR (INVT.SITE,
                                                    '[^- ]+',
                                                    1,
                                                    1) =
                                     (SELECT ZCODE
                                        FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER
                                             RP
                                       WHERE RP.REPAIR_PARTNER_ID =
                                             SETUP.REPAIR_PARTNER_ID)
                                 AND SETUP.REFRESH_STATUS = 'ACTIVE'
                                 AND SETUP.REFRESH_METHOD_ID =
                                     (SELECT CONFIG_ID
                                        FROM CRPADM.RC_PRODUCT_CONFIG
                                       WHERE     CONFIG_TYPE = 'REFRESH_METHOD'
                                             AND CONFIG_NAME = ('SCREEN'))
                        GROUP BY PROD_MSTR.REFRESH_INVENTORY_ITEM_ID,
                                 SETUP.THEATER_ID) INV
                    ON (    REQ.REFRESH_INVENTORY_ITEM_ID =
                            INV.REFRESH_INVENTORY_ITEM_ID
                        AND REQ.THEATER_ID = INV.THEATER_ID)
            WHEN MATCHED
            THEN
                UPDATE SET REQ.SCREEN_ONLY_INV_ROHS = INV.QTY_ON_HAND;

            MERGE INTO RC_INV_TRANS_NET_REQ_DETAILS REQ
                 USING (  SELECT DISTINCT
                                 PROD_MSTR.REFRESH_INVENTORY_ITEM_ID,
                                 SETUP.THEATER_ID,
                                 SUM (
                                     NVL (
                                         TO_NUMBER (
                                             REPLACE (INVT.QTY_ON_HAND,
                                                      ',',
                                                      '')),
                                         0))
                                     QTY_ON_HAND
                            FROM CRPADM.RC_INV_BTS_C3_MV INVT
                                 INNER JOIN CRPADM.RC_PRODUCT_MASTER PROD_MSTR
                                     ON (   INVT.INVENTORY_ITEM_ID =
                                            PROD_MSTR.REFRESH_INVENTORY_ITEM_ID
                                         OR INVT.INVENTORY_ITEM_ID =
                                            PROD_MSTR.COMMON_INVENTORY_ITEM_ID
                                         OR INVT.INVENTORY_ITEM_ID =
                                            PROD_MSTR.XREF_INVENTORY_ITEM_ID)
                                 INNER JOIN
                                 CRPADM.RC_PRODUCT_REPAIR_SETUP SETUP
                                     ON PROD_MSTR.REFRESH_INVENTORY_ITEM_ID =
                                        SETUP.REFRESH_INVENTORY_ITEM_ID
                                 INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR E
                                     ON     TRIM (INVT.LOCATION) =
                                            TRIM (E.SUB_INVENTORY_LOCATION)
                                        AND E.PROGRAM_TYPE IN (0, 1)
                                        AND E.NETTABLE_FLAG IN (0, 1)
                                 INNER JOIN CRPADM.RC_SUB_INV_LOC_FLG_DTLS F
                                     ON E.SUB_INVENTORY_ID = F.SUB_INVENTORY_ID
                           WHERE     F.REFRESH_METHOD_ID = 3
                                 AND ROHS_FLAG = 0
                                 AND REGEXP_SUBSTR (INVT.SITE,
                                                    '[^- ]+',
                                                    1,
                                                    1) =
                                     (SELECT ZCODE
                                        FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER
                                             RP
                                       WHERE RP.REPAIR_PARTNER_ID =
                                             SETUP.REPAIR_PARTNER_ID)
                                 AND SETUP.REFRESH_STATUS = 'ACTIVE'
                                 AND SETUP.REFRESH_METHOD_ID =
                                     (SELECT CONFIG_ID
                                        FROM CRPADM.RC_PRODUCT_CONFIG
                                       WHERE     CONFIG_TYPE = 'REFRESH_METHOD'
                                             AND CONFIG_NAME = ('SCREEN'))
                        GROUP BY PROD_MSTR.REFRESH_INVENTORY_ITEM_ID,
                                 SETUP.THEATER_ID) INV
                    ON (    REQ.REFRESH_INVENTORY_ITEM_ID =
                            INV.REFRESH_INVENTORY_ITEM_ID
                        AND REQ.THEATER_ID = INV.THEATER_ID)
            WHEN MATCHED
            THEN
                UPDATE SET REQ.SCREEN_ONLY_INV_NRHS = INV.QTY_ON_HAND;

            /*Update Net Requirements total, ROHS and NON ROHS*/
            UPDATE RC_INV_TRANS_NET_REQ_DETAILS
               SET NET_REQ =
                         NVL (BTO, 0)
                       + NVL (APPROVED_QUOTES, 0)
                       + NVL (CURR_MAX, 0)
                       - (  NVL (FG_AT_BTS, 0)
                          + NVL (FG_IN_TRANSIT, 0)
                          + NVL (FGI_IN_TRANSIT, 0)
                          + NVL (SCREEN_ONLY_INV, 0)),
                   NET_REQ_ROHS =
                         NVL (BTO_ROHS, 0)
                       + NVL (APRROVED_QUOTES_ROHS, 0)
                       + NVL (CURR_MAX, 0)
                       - (  NVL (FG_ROHS, 0)
                          + NVL (FG_IN_TRANSIT_ROHS, 0)
                          + NVL (FGI_IN_TRANSIT_ROHS, 0)
                          + NVL (SCREEN_ONLY_INV_ROHS, 0)),
                   NET_REQ_NRHS =
                         NVL (BTO_NON_ROHS, 0)
                       + NVL (APRROVED_QUOTES_NRHS, 0)
                       + NVL (CURR_MAX, 0)
                       - (  NVL (FG_NON_ROHS, 0)
                          + NVL (FG_IN_TRANSIT_NRHS, 0)
                          + NVL (FGI_IN_TRANSIT_NON_ROHS, 0)
                          + NVL (SCREEN_ONLY_INV_NRHS, 0));

            UPDATE RC_INV_TRANS_NET_REQ_DETAILS
               SET REM_FG_AT_BTS =
                         NVL (FG_AT_BTS, 0)
                       + NVL (FG_IN_TRANSIT, 0)
                       - (  NVL (BTO, 0)
                          + NVL (APPROVED_QUOTES, 0)
                          + NVL (CURR_MAX, 0)),
                   REM_FG_NON_ROHS =
                         NVL (FG_NON_ROHS, 0)
                       + NVL (FG_IN_TRANSIT_NRHS, 0)
                       - (  NVL (BTO_NON_ROHS, 0)
                          + NVL (APRROVED_QUOTES_NRHS, 0)
                          + NVL (CURR_MAX, 0));


            UPDATE RC_INV_TRANS_NET_REQ_DETAILS
               SET REM_FG_ROHS =
                       CASE
                           WHEN REM_FG_NON_ROHS >= 0
                           THEN
                                 NVL (FG_ROHS, 0)
                               + NVL (FG_IN_TRANSIT_ROHS, 0)
                               - (  NVL (BTO_ROHS, 0)
                                  + NVL (APRROVED_QUOTES_ROHS, 0)
                                  + 0)
                           ELSE
                                 NVL (FG_ROHS, 0)
                               + NVL (FG_IN_TRANSIT_ROHS, 0)
                               - (  NVL (BTO_ROHS, 0)
                                  + NVL (APRROVED_QUOTES_ROHS, 0)
                                  + ABS (NVL (REM_FG_NON_ROHS, 0)))
                       END;

            /*Update negative values to 0*/
            UPDATE RC_INV_TRANS_NET_REQ_DETAILS
               SET NET_REQ = CASE WHEN NET_REQ < 0 THEN 0 ELSE NET_REQ END,
                   NET_REQ_ROHS =
                       CASE
                           WHEN NET_REQ_ROHS < 0 THEN 0
                           ELSE NET_REQ_ROHS
                       END,
                   NET_REQ_NRHS =
                       CASE
                           WHEN NET_REQ_NRHS < 0 THEN 0
                           ELSE NET_REQ_NRHS
                       END,
                   REM_FG_AT_BTS =
                       CASE
                           WHEN REM_FG_AT_BTS < 0 THEN 0
                           ELSE REM_FG_AT_BTS
                       END,
                   REM_FG_ROHS =
                       CASE WHEN REM_FG_ROHS < 0 THEN 0 ELSE REM_FG_ROHS END,
                   REM_FG_NON_ROHS =
                       CASE
                           WHEN REM_FG_NON_ROHS < 0 THEN 0
                           ELSE REM_FG_NON_ROHS
                       END;

            INSERT INTO RC_INV_TRANS_NET_REQ_DTLS_TMP (
                            REFRESH_INVENTORY_ITEM_ID,
                            THEATER_ID,
                            BTO,
                            BTO_ROHS,
                            BTO_NON_ROHS,
                            CURR_MAX,
                            APPROVED_QUOTES,
                            APRROVED_QUOTES_ROHS,
                            APRROVED_QUOTES_NRHS,
                            FG_AT_BTS,
                            FG_ROHS,
                            FG_NON_ROHS,
                            FG_IN_TRANSIT,
                            FG_IN_TRANSIT_ROHS,
                            FG_IN_TRANSIT_NRHS,
                            FGI_IN_TRANSIT,
                            FGI_IN_TRANSIT_ROHS,
                            FGI_IN_TRANSIT_NON_ROHS,
                            SCREEN_ONLY_INV,
                            SCREEN_ONLY_INV_ROHS,
                            SCREEN_ONLY_INV_NRHS,
                            NET_REQ,
                            NET_REQ_ROHS,
                            NET_REQ_NRHS,
                            UPDATED_ON,
                            REM_FG_AT_BTS,
                            REM_FG_ROHS,
                            REM_FG_NON_ROHS,
                            ROHS_CHECK_NEEDED)
                SELECT REFRESH_INVENTORY_ITEM_ID,
                       THEATER_ID,
                       BTO,
                       BTO_ROHS,
                       BTO_NON_ROHS,
                       CURR_MAX,
                       APPROVED_QUOTES,
                       APRROVED_QUOTES_ROHS,
                       APRROVED_QUOTES_NRHS,
                       FG_AT_BTS,
                       FG_ROHS,
                       FG_NON_ROHS,
                       FG_IN_TRANSIT,
                       FG_IN_TRANSIT_ROHS,
                       FG_IN_TRANSIT_NRHS,
                       FGI_IN_TRANSIT,
                       FGI_IN_TRANSIT_ROHS,
                       FGI_IN_TRANSIT_NON_ROHS,
                       SCREEN_ONLY_INV,
                       SCREEN_ONLY_INV_ROHS,
                       SCREEN_ONLY_INV_NRHS,
                       NET_REQ,
                       NET_REQ_ROHS,
                       NET_REQ_NRHS,
                       UPDATED_ON,
                       REM_FG_AT_BTS,
                       REM_FG_ROHS,
                       REM_FG_NON_ROHS,
                       ROHS_CHECK_NEEDED
                  FROM RC_INV_TRANS_NET_REQ_DETAILS;

            COMMIT;

            UPDATE RC_INV_TRANS_NET_REQ_DETAILS DTLS
               SET DTLS.NET_REQ =
                         DTLS.NET_REQ
                       - (SELECT   NVL (REMAIN.REM_FG_ROHS, 0)
                                 + NVL (REMAIN.REM_FG_NON_ROHS, 0)
                            FROM RC_INV_TRANS_NET_REQ_DETAILS REMAIN
                           WHERE     REMAIN.REFRESH_INVENTORY_ITEM_ID =
                                     DTLS.REFRESH_INVENTORY_ITEM_ID
                                 AND REMAIN.THEATER_ID = lv_emea_id),
                   DTLS.NET_REQ_ROHS =
                         DTLS.NET_REQ_ROHS
                       - (SELECT   NVL (REMAIN.REM_FG_ROHS, 0)
                                 + NVL (REMAIN.REM_FG_NON_ROHS, 0)
                            FROM RC_INV_TRANS_NET_REQ_DETAILS REMAIN
                           WHERE     REMAIN.REFRESH_INVENTORY_ITEM_ID =
                                     DTLS.REFRESH_INVENTORY_ITEM_ID
                                 AND REMAIN.THEATER_ID = lv_emea_id),
                   DTLS.NET_REQ_NRHS =
                         DTLS.NET_REQ_NRHS
                       - (SELECT   NVL (REMAIN.REM_FG_ROHS, 0)
                                 + NVL (REMAIN.REM_FG_NON_ROHS, 0)
                            FROM RC_INV_TRANS_NET_REQ_DETAILS REMAIN
                           WHERE     REMAIN.REFRESH_INVENTORY_ITEM_ID =
                                     DTLS.REFRESH_INVENTORY_ITEM_ID
                                 AND REMAIN.THEATER_ID = lv_emea_id)
             WHERE DTLS.THEATER_ID = lv_nam_id AND EXISTS
              (SELECT 1
                 FROM RC_INV_TRANS_NET_REQ_DETAILS REMAIN
                WHERE     REMAIN.REFRESH_INVENTORY_ITEM_ID =
                             DTLS.REFRESH_INVENTORY_ITEM_ID
                      AND REMAIN.THEATER_ID = lv_emea_id);

            UPDATE RC_INV_TRANS_NET_REQ_DETAILS DTLS
               SET DTLS.NET_REQ =
                         DTLS.NET_REQ
                       - (SELECT CASE
                                     WHEN ROHS_CHECK_NEEDED = 'Y'
                                     THEN
                                         NVL (REMAIN.REM_FG_ROHS, 0)
                                     WHEN ROHS_CHECK_NEEDED = 'N'
                                     THEN
                                           NVL (REMAIN.REM_FG_ROHS, 0)
                                         + NVL (REMAIN.REM_FG_NON_ROHS, 0)
                                 END
                                     REM_FG
                            FROM RC_INV_TRANS_NET_REQ_DETAILS REMAIN
                           WHERE     REMAIN.REFRESH_INVENTORY_ITEM_ID =
                                     DTLS.REFRESH_INVENTORY_ITEM_ID
                                 AND REMAIN.THEATER_ID = lv_nam_id),
                   DTLS.NET_REQ_ROHS =
                         DTLS.NET_REQ_ROHS
                       - (SELECT CASE
                                     WHEN ROHS_CHECK_NEEDED = 'Y'
                                     THEN
                                         NVL (REMAIN.REM_FG_ROHS, 0)
                                     WHEN ROHS_CHECK_NEEDED = 'N'
                                     THEN
                                           NVL (REMAIN.REM_FG_ROHS, 0)
                                         + NVL (REMAIN.REM_FG_NON_ROHS, 0)
                                 END
                                     REM_FG
                            FROM RC_INV_TRANS_NET_REQ_DETAILS REMAIN
                           WHERE     REMAIN.REFRESH_INVENTORY_ITEM_ID =
                                     DTLS.REFRESH_INVENTORY_ITEM_ID
                                 AND REMAIN.THEATER_ID = lv_nam_id),
                   DTLS.NET_REQ_NRHS =
                         DTLS.NET_REQ_NRHS
                       - (SELECT CASE
                                     WHEN ROHS_CHECK_NEEDED = 'Y'
                                     THEN
                                         NVL (REMAIN.REM_FG_ROHS, 0)
                                     WHEN ROHS_CHECK_NEEDED = 'N'
                                     THEN
                                           NVL (REMAIN.REM_FG_ROHS, 0)
                                         + NVL (REMAIN.REM_FG_NON_ROHS, 0)
                                 END
                                     REM_FG
                            FROM RC_INV_TRANS_NET_REQ_DETAILS REMAIN
                           WHERE     REMAIN.REFRESH_INVENTORY_ITEM_ID =
                                     DTLS.REFRESH_INVENTORY_ITEM_ID
                                 AND REMAIN.THEATER_ID = lv_nam_id)
             WHERE DTLS.THEATER_ID = lv_emea_id AND EXISTS
              (SELECT 1
                 FROM RC_INV_TRANS_NET_REQ_DETAILS REMAIN
                WHERE     REMAIN.REFRESH_INVENTORY_ITEM_ID =
                             DTLS.REFRESH_INVENTORY_ITEM_ID
                      AND REMAIN.THEATER_ID = lv_nam_id);

            UPDATE RC_INV_TRANS_NET_REQ_DETAILS
               SET NET_REQ = CASE WHEN NET_REQ < 0 THEN 0 ELSE NET_REQ END,
                   NET_REQ_ROHS =
                       CASE
                           WHEN NET_REQ_ROHS < 0 THEN 0
                           ELSE NET_REQ_ROHS
                       END,
                   NET_REQ_NRHS =
                       CASE
                           WHEN NET_REQ_NRHS < 0 THEN 0
                           ELSE NET_REQ_NRHS
                       END;

            COMMIT;
        EXCEPTION
            WHEN OTHERS
            THEN
                --Insert into RC_NOTIFICATION_HISTORY table for notifications
                INSERT INTO CRPADM.RC_JOBS_NOTIFICATION_HISTORY (
                                NOTIFICATION_ID,
                                TIME_STAMP,
                                STATUS)
                     VALUES (4, SYSDATE, 'Failed');

                COMMIT;
                g_error_msg :=
                       SUBSTR (SQLERRM, 1, 200)
                    || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
                CRPADM.RC_GLOBAL_ERROR_LOGGING (
                    'OTHERS',
                    g_error_msg,
                    NULL,
                    'CRPSC.RC_INVENTORY_TRANSFER.RC_INV_TRANSFER_ENGINE',
                    'PACKAGE',
                    NULL,
                    'Y');
        END;


        FOR rec IN c_nam
        LOOP
            --Get the theater refurb method
            RC_GET_REFRESH_METHOD (rec.REFRESH_INVENTORY_ITEM_ID,
                                   NULL,
                                   lv_theater_refresh_method_nam,
                                   lv_theater_refresh_method_emea,
                                   lv_global_refresh_method,
                                   lv_rp_refresh_method_id);

            lv_net_req_rohs_nrhs := 0;
            lv_net_req := 0;
            lv_dgi_src_qty := 0;
            lv_net_req := rec.NET_REQ;

            IF rec.ROHS_CHECK_NEEDED = 'Y'
            THEN
                lv_net_req_rohs_nrhs := rec.NET_REQ_ROHS;
            ELSIF rec.ROHS_CHECK_NEEDED = 'N'
            THEN
                lv_net_req_rohs_nrhs := rec.NET_REQ_NRHS;
            END IF;

            IF rec.THEATER_ID = lv_emea_id
            THEN
                lv_cross_theater := lv_nam_id;
            ELSIF rec.THEATER_ID = lv_nam_id
            THEN
                lv_cross_theater := lv_emea_id;
            END IF;

            OPEN c_src_dgi_details (rec.REFRESH_INVENTORY_ITEM_ID,
                                    rec.THEATER_ID);

            FETCH c_src_dgi_details BULK COLLECT INTO lv_src_dgi_list;

            CLOSE c_src_dgi_details;

            lv_c3_id := 0;

            FOR idx IN 1 .. lv_src_dgi_list.COUNT ()
            LOOP
                lv_dgi_src_qty := lv_src_dgi_list (idx).QTY_ON_HAND;

                OPEN c_refurb_method (rec.REFRESH_INVENTORY_ITEM_ID,
                                      rec.THEATER_ID,
                                      lv_src_dgi_list (idx).PLACE_ID);

                FETCH c_refurb_method BULK COLLECT INTO lv_refurb_method;

                CLOSE c_refurb_method;

                IF (lv_max_refurb NOT MEMBER OF lv_refurb_method)
                THEN
                    OPEN c_dgi_details (rec.REFRESH_INVENTORY_ITEM_ID,
                                        rec.THEATER_ID);

                    FETCH c_dgi_details BULK COLLECT INTO lv_dgi_list;

                    CLOSE c_dgi_details;

                    lv_final_priority := 0;
                    lv_inv_loc := NULL;
                    lv_destn_zloc := NULL;
                    lv_qty_on_hand := 0;

                    FOR i IN 1 .. lv_dgi_list.COUNT ()
                    LOOP
                        IF (   lv_dgi_list (i).LOCATION <> 'RF-DGI'
                            OR (    lv_dgi_list (i).LOCATION = 'RF-DGI'
                                AND (lv_refurb_check
                                          NOT SUBMULTISET OF lv_refurb_method))) --If src is 'RF-DGI' and has both test and screen then do not transfer
                        THEN
                            FOR dat IN 1 .. lv_refurb_method.COUNT ()
                            LOOP
                                EXIT WHEN DAT IS NULL;

                                --Transfer within theater
                                IF (    lv_refurb_method (dat) <>
                                        lv_theater_refresh_method_nam
                                    AND lv_refurb_method (dat) <> 4)
                                THEN
                                    SELECT RC_INV_TRANSFER_RULES_OBJ (
                                               DESTINATION_REGION,
                                               DESTINATION_REFRESH_METHOD,
                                               DESTINATION_LOCATION_ZCODE,
                                               SUB_INVENTORY_LOCATION)
                                      BULK COLLECT INTO lv_transfer_rules
                                      FROM (SELECT DESTINATION_REGION,
                                                   DESTINATION_REFRESH_METHOD,
                                                   DESTINATION_LOCATION_ZCODE,
                                                   SUB_INVENTORY_LOCATION
                                              FROM RC_INV_TRANSFER_SETUP
                                             WHERE     IS_ACTIVE = 'Y'
                                                   AND SOURCE_REFRESH_METHOD =
                                                       lv_refurb_method (dat)
                                                   AND SOURCE_LOCATION_ZCODE =
                                                       lv_src_dgi_list (idx).PLACE_ID
                                                   AND SOURCE_REGION =
                                                       DESTINATION_REGION
                                                   AND SOURCE_REGION =
                                                       rec.THEATER_ID
                                                   AND (    DESTINATION_REFRESH_METHOD =
                                                            lv_dgi_list (i).REFRESH_METHOD_ID
                                                        AND DESTINATION_REFRESH_METHOD <=
                                                            lv_refurb_method (
                                                                dat))
                                                   AND SUB_INVENTORY_LOCATION =
                                                       lv_dgi_list (i).LOCATION
                                                   AND SUB_INVENTORY_LOCATION =
                                                       lv_src_dgi_list (idx).LOCATION
                                                   AND PROGRAM_TYPE =
                                                       lv_dgi_list (i).PROGRAM_TYPE
                                                   AND DESTINATION_LOCATION_ZCODE =
                                                       lv_dgi_list (i).PLACE_ID);

                                    --                                       IN (SELECT ZCODE
                                    --                                                                            FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER P
                                    --                                                                           WHERE P.REPAIR_PARTNER_ID IN (SELECT REPAIR_PARTNER_ID
                                    --                                                                                                           FROM CRPADM.RC_PRODUCT_REPAIR_SETUP
                                    --                                                                                                          WHERE     REFRESH_INVENTORY_ITEM_ID =
                                    --                                                                                                                       rec.REFRESH_INVENTORY_ITEM_ID
                                    --                                                                                                                AND THEATER_ID =
                                    --                                                                                                                       rec.THEATER_ID
                                    --                                                                                                                AND REFRESH_METHOD_ID = --Fix for engine suggesting tranfer to deactivated locations
                                    --                                                                                                                       lv_theater_refresh_method_nam
                                    --                                                                                                                AND REFRESH_STATUS =
                                    --                                                                                                                       'ACTIVE')));

                                    --Find which location has the highest priority and suggest transfer to the same.
                                    IF lv_transfer_rules.COUNT () > 0
                                    THEN
                                        FOR i IN 1 ..
                                                 lv_transfer_rules.COUNT ()
                                        LOOP
                                            EXIT WHEN i IS NULL;

                                            BEGIN
                                                SELECT PRIORITY
                                                  INTO lv_priority
                                                  FROM CRPADM.RC_ASSIGNED_RP_SETUP
                                                 WHERE     THEATER_ID =
                                                           rec.THEATER_ID
                                                       AND STATUS = 'Y'
                                                       AND REFRESH_METHOD_ID =
                                                           lv_transfer_rules (
                                                               i).DESTINATION_REFRESH_METHOD
                                                       AND ZCODE =
                                                           lv_transfer_rules (
                                                               i).DESTINATION_LOCATION_ZCODE
                                                       AND PROGRAM_TYPE =
                                                           lv_dgi_list (i).PROGRAM_TYPE;
                                            EXCEPTION
                                                WHEN NO_DATA_FOUND
                                                THEN
                                                    lv_priority := 0;
                                            END;

                                            lv_dtn_zloc :=
                                                lv_transfer_rules (i).DESTINATION_LOCATION_ZCODE;

                                            IF lv_dtn_zloc IS NOT NULL
                                            THEN
                                                IF    lv_final_priority >
                                                      lv_priority
                                                   OR lv_priority <> 0
                                                THEN
                                                    lv_final_priority :=
                                                        lv_priority;
                                                    lv_destn_zloc :=
                                                        lv_transfer_rules (i).DESTINATION_LOCATION_ZCODE;
                                                    lv_inv_loc :=
                                                        lv_transfer_rules (i).SUB_INVENTORY_LOCATION;
                                                END IF;
                                            END IF;
                                        END LOOP;

                                        lv_qty_on_hand :=
                                              lv_qty_on_hand
                                            + lv_dgi_list (i).QTY_ON_HAND;
                                        lv_c3_id :=
                                            lv_src_dgi_list (idx).C3_INVENTORY_ITEM_ID;

                                        lv_exists := 0;
                                        lv_trans_qty := 0;
                                        lv_trans_yield_qty := 0;
                                        lv_rem_qty := 0;

                                        IF (lv_inv_loc IS NOT NULL)
                                        THEN
                                            SELECT COUNT (*)
                                              INTO lv_exists
                                              FROM RC_INVENTORY_TRANSFER_TBL
                                             WHERE     REFRESH_INVENTORY_ITEM_ID =
                                                       rec.REFRESH_INVENTORY_ITEM_ID
                                                   AND SOURCE_LOCATION_ZCODE =
                                                       lv_src_dgi_list (idx).PLACE_ID
                                                   AND DESTINATION_LOCATION_ZCODE =
                                                       lv_destn_zloc
                                                   AND SUB_INVENTORY_LOCATION =
                                                       lv_inv_loc;

                                            --                                  AND C3_ONHAND_DGI = rec.QTY_ON_HAND;
                                            IF lv_dgi_src_qty > 0
                                            THEN
                                                lv_orig_dgi_src_qty :=
                                                    lv_dgi_src_qty;

                                                SELECT (FLOOR (
                                                            DECODE (
                                                                lv_dgi_list (
                                                                    i).REFRESH_YIELD,
                                                                NULL, 0,
                                                                (  lv_dgi_src_qty
                                                                 * (  lv_dgi_list (
                                                                          i).REFRESH_YIELD
                                                                    / 100)))))
                                                  INTO lv_orig_dgi_src_qty_yield
                                                  FROM DUAL;

                                                IF (    lv_exists = 0
                                                    AND (  lv_net_req
                                                         - lv_dgi_list (i).QTY_ON_HAND) >
                                                        0)
                                                THEN
                                                    lv_rem_qty :=
                                                          lv_net_req
                                                        - lv_dgi_list (i).QTY_ON_HAND;

                                                    IF (lv_rem_qty >=
                                                        lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        lv_trans_qty :=
                                                            lv_dgi_src_qty;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_dgi_src_qty
                                                                         * (  lv_dgi_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty := 0;
                                                    ELSIF (lv_rem_qty <
                                                           lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        SELECT (CEIL (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_rem_qty
                                                                         * (  100
                                                                            / lv_dgi_list (
                                                                                  i).REFRESH_YIELD)))))
                                                          INTO lv_trans_qty
                                                          FROM DUAL;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_trans_qty
                                                                         * (  lv_dgi_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty :=
                                                              lv_dgi_src_qty
                                                            - lv_trans_qty;
                                                    END IF;

                                                    INSERT INTO RC_INVENTORY_TRANSFER_TBL
                                                             VALUES (
                                                                        rec.REFRESH_INVENTORY_ITEM_ID,
                                                                        lv_src_dgi_list (
                                                                            idx).PLACE_ID,
                                                                        lv_destn_zloc,
                                                                        lv_inv_loc,
                                                                        lv_orig_dgi_src_qty,
                                                                        SYSDATE,
                                                                        lv_c3_id,
                                                                        lv_trans_qty);

                                                    COMMIT;
                                                    lv_exists := 1;
                                                    lv_net_req :=
                                                          lv_net_req
                                                        - (  lv_dgi_list (i).QTY_ON_HAND
                                                           + lv_trans_yield_qty);
                                                ELSIF (    lv_exists > 0
                                                       AND --(  lv_net_req - lv_dgi_list (i).QTY_ON_HAND) >
                                                           lv_net_req > 0)
                                                THEN
                                                    lv_rem_qty := lv_net_req;

                                                    --                                                        - lv_dgi_list (i).QTY_ON_HAND;

                                                    IF (lv_rem_qty >=
                                                        lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        lv_trans_qty :=
                                                            lv_dgi_src_qty;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_dgi_src_qty
                                                                         * (  lv_dgi_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty := 0;
                                                    ELSIF (lv_rem_qty <
                                                           lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        SELECT (CEIL (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_rem_qty
                                                                         * (  100
                                                                            / lv_dgi_list (
                                                                                  i).REFRESH_YIELD)))))
                                                          INTO lv_trans_qty
                                                          FROM DUAL;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_trans_qty
                                                                         * (  lv_dgi_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty :=
                                                              lv_dgi_src_qty
                                                            - lv_trans_qty;
                                                    END IF;

                                                    UPDATE RC_INVENTORY_TRANSFER_TBL
                                                       SET DESTINATION_LOCATION_ZCODE =
                                                               lv_destn_zloc,
                                                           C3_ONHAND_DGI =
                                                               lv_orig_dgi_src_qty,
                                                           QTY_TO_TRANSFER =
                                                               lv_trans_qty
                                                     WHERE     REFRESH_INVENTORY_ITEM_ID =
                                                               rec.REFRESH_INVENTORY_ITEM_ID
                                                           AND SOURCE_LOCATION_ZCODE =
                                                               lv_src_dgi_list (
                                                                   idx).PLACE_ID
                                                           AND SUB_INVENTORY_LOCATION =
                                                               lv_inv_loc;

                                                    COMMIT;
                                                    lv_net_req :=
                                                          lv_net_req
                                                        - (  lv_dgi_list (i).QTY_ON_HAND
                                                           + lv_trans_yield_qty);
                                                ELSIF ((  lv_net_req
                                                        - lv_dgi_list (i).QTY_ON_HAND) <
                                                       0)
                                                THEN
                                                    lv_net_req := 0;
                                                END IF;
                                            END IF;
                                        END IF;
                                    END IF;
                                END IF;
                            END LOOP;
                        END IF;
                    END LOOP;


                    IF lv_net_req > 0
                    THEN
                        --CROSS THEATER TRANSFER
                        OPEN c_dgi_details (rec.REFRESH_INVENTORY_ITEM_ID,
                                            lv_cross_theater);

                        FETCH c_dgi_details
                            BULK COLLECT INTO lv_dgi_cross_list;

                        CLOSE c_dgi_details;

                        FOR i IN 1 .. lv_dgi_cross_list.COUNT ()
                        LOOP
                            IF (   lv_dgi_cross_list (i).LOCATION <> 'RF-DGI'
                                OR (    lv_dgi_cross_list (i).LOCATION =
                                        'RF-DGI'
                                    AND (lv_refurb_check
                                              NOT SUBMULTISET OF lv_refurb_method))) --If src is 'RF-DGI' and has both test and screen then do not transfer
                            THEN
                                FOR dat IN 1 .. lv_refurb_method.COUNT ()
                                LOOP
                                    EXIT WHEN DAT IS NULL;


                                    IF (    lv_refurb_method (dat) <>
                                            lv_global_refresh_method
                                        AND lv_refurb_method (dat) <> 4)
                                    THEN
                                        SELECT RC_INV_TRANSFER_RULES_OBJ (
                                                   DESTINATION_REGION,
                                                   DESTINATION_REFRESH_METHOD,
                                                   DESTINATION_LOCATION_ZCODE,
                                                   SUB_INVENTORY_LOCATION)
                                          BULK COLLECT INTO lv_transfer_rules
                                          FROM (SELECT DESTINATION_REGION,
                                                       DESTINATION_REFRESH_METHOD,
                                                       DESTINATION_LOCATION_ZCODE,
                                                       SUB_INVENTORY_LOCATION
                                                  FROM RC_INV_TRANSFER_SETUP
                                                 WHERE     IS_ACTIVE = 'Y'
                                                       AND SOURCE_REFRESH_METHOD =
                                                           lv_refurb_method (
                                                               dat)
                                                       AND SOURCE_LOCATION_ZCODE =
                                                           lv_src_dgi_list (
                                                               idx).PLACE_ID
                                                       AND SOURCE_REGION <>
                                                           DESTINATION_REGION
                                                       AND SOURCE_REGION =
                                                           REC.THEATER_ID
                                                       AND (    DESTINATION_REFRESH_METHOD =
                                                                lv_dgi_cross_list (
                                                                    i).REFRESH_METHOD_ID
                                                            AND DESTINATION_REFRESH_METHOD <=
                                                                lv_refurb_method (
                                                                    dat))
                                                       AND SUB_INVENTORY_LOCATION =
                                                           lv_dgi_cross_list (
                                                               i).LOCATION
                                                       AND SUB_INVENTORY_LOCATION =
                                                           lv_src_dgi_list (
                                                               idx).LOCATION
                                                       AND PROGRAM_TYPE =
                                                           lv_dgi_cross_list (
                                                               i).PROGRAM_TYPE
                                                       AND DESTINATION_LOCATION_ZCODE =
                                                           lv_dgi_cross_list (
                                                               i).PLACE_ID);

                                        --                                         IN (SELECT ZCODE
                                        --                                                                              FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER P
                                        --                                                                             WHERE P.REPAIR_PARTNER_ID IN (SELECT REPAIR_PARTNER_ID
                                        --                                                                                                             FROM CRPADM.RC_PRODUCT_REPAIR_SETUP
                                        --                                                                                                            WHERE     REFRESH_INVENTORY_ITEM_ID =
                                        --                                                                                                                         rec.REFRESH_INVENTORY_ITEM_ID
                                        --                                                                                                                  --                                                      AND THEATER_ID =
                                        --                                                                                                                  --                                                            rec.THEATER_ID --commented out to check Z05 to Z26 cross theater issue
                                        --                                                                                                                  AND REFRESH_METHOD_ID =
                                        --                                                                                                                         lv_global_refresh_method --Fix for engine suggesting tranfer to deactivated locations
                                        --                                                                                                                  AND REFRESH_STATUS =
                                        --                                                                                                                         'ACTIVE')));

                                        IF lv_transfer_rules.COUNT () > 0
                                        THEN
                                            FOR i IN 1 ..
                                                     lv_transfer_rules.COUNT ()
                                            LOOP
                                                EXIT WHEN i IS NULL;

                                                BEGIN
                                                    SELECT PRIORITY
                                                      INTO lv_priority
                                                      FROM CRPADM.RC_ASSIGNED_RP_SETUP
                                                     WHERE     THEATER_ID <>
                                                               rec.THEATER_ID
                                                           AND STATUS = 'Y'
                                                           AND REFRESH_METHOD_ID =
                                                               lv_transfer_rules (
                                                                   i).DESTINATION_REFRESH_METHOD
                                                           AND ZCODE =
                                                               lv_transfer_rules (
                                                                   i).DESTINATION_LOCATION_ZCODE
                                                           AND PROGRAM_TYPE =
                                                               lv_dgi_cross_list (
                                                                   i).PROGRAM_TYPE;
                                                EXCEPTION
                                                    WHEN NO_DATA_FOUND
                                                    THEN
                                                        lv_priority := 0;
                                                END;

                                                lv_dtn_zloc :=
                                                    lv_transfer_rules (i).DESTINATION_LOCATION_ZCODE;

                                                IF lv_dtn_zloc IS NOT NULL
                                                THEN
                                                    IF    lv_final_priority >
                                                          lv_priority
                                                       OR lv_priority <> 0
                                                    THEN
                                                        lv_final_priority :=
                                                            lv_priority;
                                                        lv_destn_zloc :=
                                                            lv_transfer_rules (
                                                                i).DESTINATION_LOCATION_ZCODE;
                                                        lv_inv_loc :=
                                                            lv_transfer_rules (
                                                                i).SUB_INVENTORY_LOCATION;
                                                        lv_dtn_refresh_method :=
                                                            lv_transfer_rules (
                                                                i).DESTINATION_REFRESH_METHOD;
                                                    END IF;
                                                END IF;
                                            END LOOP;

                                            lv_qty_on_hand :=
                                                  lv_qty_on_hand
                                                + lv_dgi_cross_list (i).QTY_ON_HAND;
                                            lv_c3_id :=
                                                lv_src_dgi_list (idx).C3_INVENTORY_ITEM_ID;

                                            lv_exists := 0;
                                            lv_trans_qty := 0;
                                            lv_rem_qty := 0;

                                            IF (lv_inv_loc IS NOT NULL)
                                            THEN
                                                BEGIN
                                                    SELECT ROHS_FLAG
                                                      INTO lv_rohs_flag
                                                      FROM CRPADM.RC_SUB_INV_LOC_FLG_DTLS
                                                           FLG
                                                           JOIN
                                                           CRPADM.RC_SUB_INV_LOC_MSTR
                                                           MP
                                                               ON MP.SUB_INVENTORY_ID =
                                                                  FLG.SUB_INVENTORY_ID
                                                     WHERE     FLG.REFRESH_METHOD_ID =
                                                               lv_dtn_refresh_method
                                                           AND MP.SUB_INVENTORY_LOCATION =
                                                               lv_inv_loc;
                                                EXCEPTION
                                                    WHEN OTHERS
                                                    THEN
                                                        lv_rohs_flag := '';
                                                END;

                                                IF lv_rohs_flag = '1'
                                                THEN
                                                    SELECT COUNT (*)
                                                      INTO lv_exists
                                                      FROM RC_INVENTORY_TRANSFER_TBL
                                                     WHERE     REFRESH_INVENTORY_ITEM_ID =
                                                               rec.REFRESH_INVENTORY_ITEM_ID
                                                           AND SOURCE_LOCATION_ZCODE =
                                                               lv_src_dgi_list (
                                                                   idx).PLACE_ID
                                                           AND DESTINATION_LOCATION_ZCODE =
                                                               lv_destn_zloc
                                                           AND SUB_INVENTORY_LOCATION =
                                                               lv_inv_loc;

                                                    --                                  AND C3_ONHAND_DGI = rec.QTY_ON_HAND;
                                                    IF lv_dgi_src_qty > 0
                                                    THEN
                                                        lv_orig_dgi_src_qty :=
                                                            lv_dgi_src_qty;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_cross_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_dgi_src_qty
                                                                         * (  lv_dgi_cross_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_orig_dgi_src_qty_yield
                                                          FROM DUAL;

                                                        IF (    lv_exists = 0
                                                            AND (  lv_net_req_rohs_nrhs
                                                                 - lv_dgi_cross_list (
                                                                       i).QTY_ON_HAND) >
                                                                0)
                                                        THEN
                                                            lv_rem_qty :=
                                                                  lv_net_req_rohs_nrhs
                                                                - lv_dgi_cross_list (
                                                                      i).QTY_ON_HAND;

                                                            IF (lv_rem_qty >=
                                                                lv_orig_dgi_src_qty_yield)
                                                            THEN
                                                                lv_trans_qty :=
                                                                    lv_dgi_src_qty;

                                                                SELECT (FLOOR (
                                                                            DECODE (
                                                                                lv_dgi_cross_list (
                                                                                    i).REFRESH_YIELD,
                                                                                NULL, 0,
                                                                                (  lv_dgi_src_qty
                                                                                 * (  lv_dgi_cross_list (
                                                                                          i).REFRESH_YIELD
                                                                                    / 100)))))
                                                                  INTO lv_trans_yield_qty
                                                                  FROM DUAL;

                                                                lv_dgi_src_qty :=
                                                                    0;
                                                            ELSIF (lv_rem_qty <
                                                                   lv_orig_dgi_src_qty_yield)
                                                            THEN
                                                                SELECT (CEIL (
                                                                            DECODE (
                                                                                lv_dgi_cross_list (
                                                                                    i).REFRESH_YIELD,
                                                                                NULL, 0,
                                                                                (  lv_rem_qty
                                                                                 * (  100
                                                                                    / lv_dgi_cross_list (
                                                                                          i).REFRESH_YIELD)))))
                                                                  INTO lv_trans_qty
                                                                  FROM DUAL;

                                                                SELECT (FLOOR (
                                                                            DECODE (
                                                                                lv_dgi_cross_list (
                                                                                    i).REFRESH_YIELD,
                                                                                NULL, 0,
                                                                                (  lv_trans_qty
                                                                                 * (  lv_dgi_cross_list (
                                                                                          i).REFRESH_YIELD
                                                                                    / 100)))))
                                                                  INTO lv_trans_yield_qty
                                                                  FROM DUAL;

                                                                lv_dgi_src_qty :=
                                                                      lv_dgi_src_qty
                                                                    - lv_trans_qty;
                                                            END IF;

                                                            INSERT INTO RC_INVENTORY_TRANSFER_TBL
                                                                     VALUES (
                                                                                rec.REFRESH_INVENTORY_ITEM_ID,
                                                                                lv_src_dgi_list (
                                                                                    idx).PLACE_ID,
                                                                                lv_destn_zloc,
                                                                                lv_inv_loc,
                                                                                lv_orig_dgi_src_qty,
                                                                                SYSDATE,
                                                                                lv_c3_id,
                                                                                lv_trans_qty);

                                                            COMMIT;
                                                            lv_exists := 1;
                                                            lv_net_req_rohs_nrhs :=
                                                                  lv_net_req_rohs_nrhs
                                                                - (  lv_dgi_cross_list (
                                                                         i).QTY_ON_HAND
                                                                   + lv_trans_yield_qty);
                                                        ELSIF (    lv_exists >
                                                                   0
                                                               AND --(  lv_net_req_rohs_nrhs
                                                                   --                                                                    - lv_dgi_cross_list (
                                                                   --                                                                          i).QTY_ON_HAND) >
                                                                   lv_net_req_rohs_nrhs >
                                                                   0)
                                                        THEN
                                                            lv_rem_qty :=
                                                                lv_net_req_rohs_nrhs;

                                                            --                                                                - lv_dgi_cross_list (
                                                            --                                                                      i).QTY_ON_HAND;

                                                            IF (lv_rem_qty >=
                                                                lv_orig_dgi_src_qty_yield)
                                                            THEN
                                                                lv_trans_qty :=
                                                                    lv_dgi_src_qty;

                                                                SELECT (FLOOR (
                                                                            DECODE (
                                                                                lv_dgi_cross_list (
                                                                                    i).REFRESH_YIELD,
                                                                                NULL, 0,
                                                                                (  lv_dgi_src_qty
                                                                                 * (  lv_dgi_cross_list (
                                                                                          i).REFRESH_YIELD
                                                                                    / 100)))))
                                                                  INTO lv_trans_yield_qty
                                                                  FROM DUAL;

                                                                lv_dgi_src_qty :=
                                                                    0;
                                                            ELSIF (lv_rem_qty <
                                                                   lv_orig_dgi_src_qty_yield)
                                                            THEN
                                                                SELECT (CEIL (
                                                                            DECODE (
                                                                                lv_dgi_cross_list (
                                                                                    i).REFRESH_YIELD,
                                                                                NULL, 0,
                                                                                (  lv_rem_qty
                                                                                 * (  100
                                                                                    / lv_dgi_cross_list (
                                                                                          i).REFRESH_YIELD)))))
                                                                  INTO lv_trans_qty
                                                                  FROM DUAL;

                                                                SELECT (FLOOR (
                                                                            DECODE (
                                                                                lv_dgi_cross_list (
                                                                                    i).REFRESH_YIELD,
                                                                                NULL, 0,
                                                                                (  lv_trans_qty
                                                                                 * (  lv_dgi_cross_list (
                                                                                          i).REFRESH_YIELD
                                                                                    / 100)))))
                                                                  INTO lv_trans_yield_qty
                                                                  FROM DUAL;

                                                                lv_dgi_src_qty :=
                                                                      lv_dgi_src_qty
                                                                    - lv_trans_qty;
                                                            END IF;

                                                            UPDATE RC_INVENTORY_TRANSFER_TBL
                                                               SET DESTINATION_LOCATION_ZCODE =
                                                                       lv_destn_zloc,
                                                                   C3_ONHAND_DGI =
                                                                       lv_orig_dgi_src_qty,
                                                                   QTY_TO_TRANSFER =
                                                                       lv_trans_qty
                                                             WHERE     REFRESH_INVENTORY_ITEM_ID =
                                                                       rec.REFRESH_INVENTORY_ITEM_ID
                                                                   AND SOURCE_LOCATION_ZCODE =
                                                                       lv_src_dgi_list (
                                                                           idx).PLACE_ID
                                                                   AND SUB_INVENTORY_LOCATION =
                                                                       lv_inv_loc;

                                                            COMMIT;
                                                            lv_net_req_rohs_nrhs :=
                                                                  lv_net_req_rohs_nrhs
                                                                - (  lv_dgi_cross_list (
                                                                         i).QTY_ON_HAND
                                                                   + lv_trans_yield_qty);
                                                        ELSIF ((  lv_net_req_rohs_nrhs
                                                                - lv_dgi_cross_list (
                                                                      i).QTY_ON_HAND) <
                                                               0)
                                                        THEN
                                                            lv_net_req_rohs_nrhs :=
                                                                0;
                                                        END IF;
                                                    END IF;
                                                END IF;
                                            END IF;
                                        END IF;
                                    END IF;
                                END LOOP;
                            END IF;
                        END LOOP;
                    END IF;
                END IF;

                /*INSERT remaining DGI at source site into a temporary table*/
                IF lv_dgi_src_qty >= 0
                THEN
                    INSERT INTO RC_INV_TRANS_REM_DGI_DETAILS
                             VALUES (
                                        lv_src_dgi_list (idx).REFRESH_INVENTORY_ITEM_ID,
                                        lv_src_dgi_list (idx).C3_INVENTORY_ITEM_ID,
                                        lv_src_dgi_list (idx).THEATER_ID,
                                        lv_src_dgi_list (idx).LOCATION,
                                        lv_src_dgi_list (idx).PLACE_ID,
                                        lv_src_dgi_list (idx).REFRESH_YIELD,
                                        lv_dgi_src_qty,
                                        lv_src_dgi_list (idx).PROGRAM_TYPE,
                                        lv_src_dgi_list (idx).Z_PRIORITY,
                                        lv_src_dgi_list (idx).PRIORITY,
                                        lv_src_dgi_list (idx).ROHS_FLAG,
                                        SYSDATE);

                    COMMIT;
                END IF;
            END LOOP;

            /*Update the remaining net req back to table*/
            IF rec.ROHS_CHECK_NEEDED = 'Y'
            THEN
                UPDATE RC_INV_TRANS_NET_REQ_DETAILS
                   SET NET_REQ = lv_net_req,
                       NET_REQ_ROHS = lv_net_req_rohs_nrhs
                 WHERE     REFRESH_INVENTORY_ITEM_ID =
                           rec.REFRESH_INVENTORY_ITEM_ID
                       AND THEATER_ID = rec.THEATER_ID;
            ELSIF rec.ROHS_CHECK_NEEDED = 'N'
            THEN
                UPDATE RC_INV_TRANS_NET_REQ_DETAILS
                   SET NET_REQ = lv_net_req,
                       NET_REQ_NRHS = lv_net_req_rohs_nrhs
                 WHERE     REFRESH_INVENTORY_ITEM_ID =
                           rec.REFRESH_INVENTORY_ITEM_ID
                       AND THEATER_ID = rec.THEATER_ID;
            END IF;

            COMMIT;
        END LOOP;



        lv_src_dgi_list := RC_DGI_LIST ();

        FOR rec IN c_emea
        LOOP
            --Get the theater refurb method
            RC_GET_REFRESH_METHOD (rec.REFRESH_INVENTORY_ITEM_ID,
                                   NULL,
                                   lv_theater_refresh_method_nam,
                                   lv_theater_refresh_method_emea,
                                   lv_global_refresh_method,
                                   lv_rp_refresh_method_id);

            lv_net_req_rohs_nrhs := 0;
            lv_net_req := 0;
            lv_dgi_src_qty := 0;
            lv_net_req := rec.NET_REQ;

            IF rec.ROHS_CHECK_NEEDED = 'Y'
            THEN
                lv_net_req_rohs_nrhs := rec.NET_REQ_ROHS;
            ELSIF rec.ROHS_CHECK_NEEDED = 'N'
            THEN
                lv_net_req_rohs_nrhs := rec.NET_REQ_NRHS;
            END IF;

            IF rec.THEATER_ID = lv_emea_id
            THEN
                lv_cross_theater := lv_nam_id;
            ELSIF rec.THEATER_ID = lv_nam_id
            THEN
                lv_cross_theater := lv_emea_id;
            END IF;


            OPEN c_src_dgi_details (rec.REFRESH_INVENTORY_ITEM_ID,
                                    rec.THEATER_ID);

            FETCH c_src_dgi_details BULK COLLECT INTO lv_src_dgi_list;

            CLOSE c_src_dgi_details;

            lv_c3_id := 0;

            FOR idx IN 1 .. lv_src_dgi_list.COUNT ()
            LOOP
                lv_dgi_src_qty := lv_src_dgi_list (idx).QTY_ON_HAND;

                OPEN c_refurb_method (rec.REFRESH_INVENTORY_ITEM_ID,
                                      rec.THEATER_ID,
                                      lv_src_dgi_list (idx).PLACE_ID);

                FETCH c_refurb_method BULK COLLECT INTO lv_refurb_method;

                CLOSE c_refurb_method;

                IF (lv_max_refurb NOT MEMBER OF lv_refurb_method)
                THEN
                    OPEN c_dgi_details (rec.REFRESH_INVENTORY_ITEM_ID,
                                        rec.THEATER_ID);

                    FETCH c_dgi_details BULK COLLECT INTO lv_dgi_list;

                    CLOSE c_dgi_details;

                    lv_final_priority := 0;
                    lv_inv_loc := NULL;
                    lv_destn_zloc := NULL;
                    lv_qty_on_hand := 0;

                    FOR i IN 1 .. lv_dgi_list.COUNT ()
                    LOOP
                        IF (   lv_dgi_list (i).LOCATION <> 'RF-DGI'
                            OR (    lv_dgi_list (i).LOCATION = 'RF-DGI'
                                AND (lv_refurb_check
                                          NOT SUBMULTISET OF lv_refurb_method))) --If src is 'RF-DGI' and has both test and screen then do not transfer
                        THEN
                            FOR dat IN 1 .. lv_refurb_method.COUNT ()
                            LOOP
                                EXIT WHEN DAT IS NULL;

                                --Transfer within theater
                                IF (    lv_refurb_method (dat) <>
                                        lv_theater_refresh_method_emea
                                    AND lv_refurb_method (dat) <> 4)
                                THEN
                                    SELECT RC_INV_TRANSFER_RULES_OBJ (
                                               DESTINATION_REGION,
                                               DESTINATION_REFRESH_METHOD,
                                               DESTINATION_LOCATION_ZCODE,
                                               SUB_INVENTORY_LOCATION)
                                      BULK COLLECT INTO lv_transfer_rules
                                      FROM (SELECT DESTINATION_REGION,
                                                   DESTINATION_REFRESH_METHOD,
                                                   DESTINATION_LOCATION_ZCODE,
                                                   SUB_INVENTORY_LOCATION
                                              FROM RC_INV_TRANSFER_SETUP
                                             WHERE     IS_ACTIVE = 'Y'
                                                   AND SOURCE_REFRESH_METHOD =
                                                       lv_refurb_method (dat)
                                                   AND SOURCE_LOCATION_ZCODE =
                                                       lv_src_dgi_list (idx).PLACE_ID
                                                   AND SOURCE_REGION =
                                                       DESTINATION_REGION
                                                   AND SOURCE_REGION =
                                                       rec.THEATER_ID
                                                   AND (    DESTINATION_REFRESH_METHOD =
                                                            lv_dgi_list (i).REFRESH_METHOD_ID
                                                        AND DESTINATION_REFRESH_METHOD <=
                                                            lv_refurb_method (
                                                                dat))
                                                   AND SUB_INVENTORY_LOCATION =
                                                       lv_dgi_list (i).LOCATION
                                                   AND SUB_INVENTORY_LOCATION =
                                                       lv_src_dgi_list (idx).LOCATION
                                                   AND PROGRAM_TYPE =
                                                       lv_dgi_list (i).PROGRAM_TYPE
                                                   AND DESTINATION_LOCATION_ZCODE =
                                                       lv_dgi_list (i).PLACE_ID);

                                    --                       IN (SELECT ZCODE
                                    --                                                                            FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER P
                                    --                                                                           WHERE P.REPAIR_PARTNER_ID IN (SELECT REPAIR_PARTNER_ID
                                    --                                                                                                           FROM CRPADM.RC_PRODUCT_REPAIR_SETUP
                                    --                                                                                                          WHERE     REFRESH_INVENTORY_ITEM_ID =
                                    --                                                                                                                       rec.REFRESH_INVENTORY_ITEM_ID
                                    --                                                                                                                AND THEATER_ID =
                                    --                                                                                                                       rec.THEATER_ID
                                    --                                                                                                                AND REFRESH_METHOD_ID =
                                    --                                                                                                                       lv_theater_refresh_method_emea --Fix for engine suggesting tranfer to deactivated locations
                                    --                                                                                                                AND REFRESH_STATUS =
                                    --                                                                                                                       'ACTIVE')));



                                    --Find which location has the highest priority and suggest transfer to the same.

                                    IF lv_transfer_rules.COUNT () > 0
                                    THEN
                                        FOR i IN 1 ..
                                                 lv_transfer_rules.COUNT ()
                                        LOOP
                                            EXIT WHEN i IS NULL;

                                            BEGIN
                                                SELECT PRIORITY
                                                  INTO lv_priority
                                                  FROM CRPADM.RC_ASSIGNED_RP_SETUP
                                                 WHERE     THEATER_ID =
                                                           rec.THEATER_ID
                                                       AND STATUS = 'Y'
                                                       AND REFRESH_METHOD_ID =
                                                           lv_transfer_rules (
                                                               i).DESTINATION_REFRESH_METHOD
                                                       AND ZCODE =
                                                           lv_transfer_rules (
                                                               i).DESTINATION_LOCATION_ZCODE
                                                       AND PROGRAM_TYPE =
                                                           lv_dgi_list (i).PROGRAM_TYPE;
                                            EXCEPTION
                                                WHEN NO_DATA_FOUND
                                                THEN
                                                    lv_priority := 0;
                                            END;

                                            lv_dtn_zloc :=
                                                lv_transfer_rules (i).DESTINATION_LOCATION_ZCODE;

                                            IF lv_dtn_zloc IS NOT NULL
                                            THEN
                                                IF    lv_final_priority >
                                                      lv_priority
                                                   OR lv_priority <> 0
                                                THEN
                                                    lv_final_priority :=
                                                        lv_priority;
                                                    lv_destn_zloc :=
                                                        lv_transfer_rules (i).DESTINATION_LOCATION_ZCODE;
                                                    lv_inv_loc :=
                                                        lv_transfer_rules (i).SUB_INVENTORY_LOCATION;
                                                END IF;
                                            END IF;
                                        END LOOP;

                                        lv_qty_on_hand :=
                                              lv_qty_on_hand
                                            + lv_dgi_list (i).QTY_ON_HAND;
                                        lv_c3_id :=
                                            lv_src_dgi_list (idx).C3_INVENTORY_ITEM_ID;

                                        lv_exists := 0;
                                        lv_trans_qty := 0;
                                        lv_trans_yield_qty := 0;
                                        lv_rem_qty := 0;

                                        IF (lv_inv_loc IS NOT NULL)
                                        THEN
                                            SELECT COUNT (*)
                                              INTO lv_exists
                                              FROM RC_INVENTORY_TRANSFER_TBL
                                             WHERE     REFRESH_INVENTORY_ITEM_ID =
                                                       rec.REFRESH_INVENTORY_ITEM_ID
                                                   AND SOURCE_LOCATION_ZCODE =
                                                       lv_src_dgi_list (idx).PLACE_ID
                                                   AND DESTINATION_LOCATION_ZCODE =
                                                       lv_destn_zloc
                                                   AND SUB_INVENTORY_LOCATION =
                                                       lv_inv_loc;

                                            --                                  AND C3_ONHAND_DGI = rec.QTY_ON_HAND;
                                            IF lv_dgi_src_qty > 0
                                            THEN
                                                lv_orig_dgi_src_qty :=
                                                    lv_dgi_src_qty;

                                                SELECT (FLOOR (
                                                            DECODE (
                                                                lv_dgi_list (
                                                                    i).REFRESH_YIELD,
                                                                NULL, 0,
                                                                (  lv_dgi_src_qty
                                                                 * (  lv_dgi_list (
                                                                          i).REFRESH_YIELD
                                                                    / 100)))))
                                                  INTO lv_orig_dgi_src_qty_yield
                                                  FROM DUAL;

                                                IF (    lv_exists = 0
                                                    AND (  lv_net_req
                                                         - lv_dgi_list (i).QTY_ON_HAND) >
                                                        0)
                                                THEN
                                                    lv_rem_qty :=
                                                          lv_net_req
                                                        - lv_dgi_list (i).QTY_ON_HAND;

                                                    IF (lv_rem_qty >=
                                                        lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        lv_trans_qty :=
                                                            lv_dgi_src_qty;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_dgi_src_qty
                                                                         * (  lv_dgi_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty := 0;
                                                    ELSIF (lv_rem_qty <
                                                           lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        SELECT (CEIL (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_rem_qty
                                                                         * (  100
                                                                            / lv_dgi_list (
                                                                                  i).REFRESH_YIELD)))))
                                                          INTO lv_trans_qty
                                                          FROM DUAL;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_trans_qty
                                                                         * (  lv_dgi_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty :=
                                                              lv_dgi_src_qty
                                                            - lv_trans_qty;
                                                    END IF;

                                                    INSERT INTO RC_INVENTORY_TRANSFER_TBL
                                                             VALUES (
                                                                        rec.REFRESH_INVENTORY_ITEM_ID,
                                                                        lv_src_dgi_list (
                                                                            idx).PLACE_ID,
                                                                        lv_destn_zloc,
                                                                        lv_inv_loc,
                                                                        lv_orig_dgi_src_qty,
                                                                        SYSDATE,
                                                                        lv_c3_id,
                                                                        lv_trans_qty);

                                                    COMMIT;
                                                    lv_exists := 1;
                                                    lv_net_req :=
                                                          lv_net_req
                                                        - (  lv_dgi_list (i).QTY_ON_HAND
                                                           + lv_trans_yield_qty);
                                                ELSIF (    lv_exists > 0
                                                       AND     --(  lv_net_req
                                                           --                                                            - lv_dgi_list (i).QTY_ON_HAND) >
                                                           lv_net_req > 0)
                                                THEN
                                                    lv_rem_qty := lv_net_req;

                                                    --                                                        - lv_dgi_list (i).QTY_ON_HAND;

                                                    IF (lv_rem_qty >=
                                                        lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        lv_trans_qty :=
                                                            lv_dgi_src_qty;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_dgi_src_qty
                                                                         * (  lv_dgi_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty := 0;
                                                    ELSIF (lv_rem_qty <
                                                           lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        SELECT (CEIL (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_rem_qty
                                                                         * (  100
                                                                            / lv_dgi_list (
                                                                                  i).REFRESH_YIELD)))))
                                                          INTO lv_trans_qty
                                                          FROM DUAL;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_trans_qty
                                                                         * (  lv_dgi_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty :=
                                                              lv_dgi_src_qty
                                                            - lv_trans_qty;
                                                    END IF;

                                                    UPDATE RC_INVENTORY_TRANSFER_TBL
                                                       SET DESTINATION_LOCATION_ZCODE =
                                                               lv_destn_zloc,
                                                           C3_ONHAND_DGI =
                                                               lv_orig_dgi_src_qty,
                                                           QTY_TO_TRANSFER =
                                                               lv_trans_qty
                                                     WHERE     REFRESH_INVENTORY_ITEM_ID =
                                                               rec.REFRESH_INVENTORY_ITEM_ID
                                                           AND SOURCE_LOCATION_ZCODE =
                                                               lv_src_dgi_list (
                                                                   idx).PLACE_ID
                                                           AND SUB_INVENTORY_LOCATION =
                                                               lv_inv_loc;

                                                    COMMIT;
                                                    lv_net_req :=
                                                          lv_net_req
                                                        - (  lv_dgi_list (i).QTY_ON_HAND
                                                           + lv_trans_yield_qty);
                                                ELSIF ((  lv_net_req
                                                        - lv_dgi_list (i).QTY_ON_HAND) <
                                                       0)
                                                THEN
                                                    lv_net_req := 0;
                                                END IF;
                                            END IF;
                                        END IF;
                                    END IF;
                                END IF;
                            END LOOP;
                        END IF;
                    END LOOP;

                    IF lv_net_req > 0
                    THEN
                        --CROSS THEATER TRANSFER
                        OPEN c_dgi_details (rec.REFRESH_INVENTORY_ITEM_ID,
                                            lv_cross_theater);

                        FETCH c_dgi_details
                            BULK COLLECT INTO lv_dgi_cross_list;

                        CLOSE c_dgi_details;

                        FOR i IN 1 .. lv_dgi_cross_list.COUNT ()
                        LOOP
                            IF (   lv_dgi_cross_list (i).LOCATION <> 'RF-DGI'
                                OR (    lv_dgi_cross_list (i).LOCATION =
                                        'RF-DGI'
                                    AND (lv_refurb_check
                                              NOT SUBMULTISET OF lv_refurb_method))) --If src is 'RF-DGI' and has both test and screen then do not transfer
                            THEN
                                FOR dat IN 1 .. lv_refurb_method.COUNT ()
                                LOOP
                                    EXIT WHEN DAT IS NULL;

                                    IF (    lv_refurb_method (dat) <>
                                            lv_global_refresh_method
                                        AND lv_refurb_method (dat) <> 4)
                                    --                            AND lv_exists = 0)
                                    THEN
                                        SELECT RC_INV_TRANSFER_RULES_OBJ (
                                                   DESTINATION_REGION,
                                                   DESTINATION_REFRESH_METHOD,
                                                   DESTINATION_LOCATION_ZCODE,
                                                   SUB_INVENTORY_LOCATION)
                                          BULK COLLECT INTO lv_transfer_rules
                                          FROM (SELECT DESTINATION_REGION,
                                                       DESTINATION_REFRESH_METHOD,
                                                       DESTINATION_LOCATION_ZCODE,
                                                       SUB_INVENTORY_LOCATION
                                                  FROM RC_INV_TRANSFER_SETUP
                                                 WHERE     IS_ACTIVE = 'Y'
                                                       AND SOURCE_REFRESH_METHOD =
                                                           lv_refurb_method (
                                                               dat)
                                                       AND SOURCE_LOCATION_ZCODE =
                                                           lv_src_dgi_list (
                                                               idx).PLACE_ID
                                                       AND SOURCE_REGION <>
                                                           DESTINATION_REGION
                                                       AND SOURCE_REGION =
                                                           REC.THEATER_ID
                                                       AND (    DESTINATION_REFRESH_METHOD =
                                                                lv_dgi_cross_list (
                                                                    i).REFRESH_METHOD_ID
                                                            AND DESTINATION_REFRESH_METHOD <=
                                                                lv_refurb_method (
                                                                    dat))
                                                       AND SUB_INVENTORY_LOCATION =
                                                           lv_dgi_cross_list (
                                                               i).LOCATION
                                                       AND SUB_INVENTORY_LOCATION =
                                                           lv_src_dgi_list (
                                                               idx).LOCATION
                                                       AND PROGRAM_TYPE =
                                                           lv_dgi_cross_list (
                                                               i).PROGRAM_TYPE
                                                       AND DESTINATION_LOCATION_ZCODE =
                                                           lv_dgi_cross_list (
                                                               i).PLACE_ID);

                                        --                                         IN (SELECT ZCODE
                                        --                                                                              FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER P
                                        --                                                                             WHERE P.REPAIR_PARTNER_ID IN (SELECT REPAIR_PARTNER_ID
                                        --                                                                                                             FROM CRPADM.RC_PRODUCT_REPAIR_SETUP
                                        --                                                                                                            WHERE     REFRESH_INVENTORY_ITEM_ID =
                                        --                                                                                                                         rec.REFRESH_INVENTORY_ITEM_ID
                                        --                                                                                                                  --                                                      AND THEATER_ID =
                                        --                                                                                                                  --                                                            rec.THEATER_ID --commented out to check Z05 to Z26 cross theater issue
                                        --                                                                                                                  AND REFRESH_METHOD_ID =
                                        --                                                                                                                         lv_global_refresh_method --Fix for engine suggesting tranfer to deactivated locations
                                        --                                                                                                                  AND REFRESH_STATUS =
                                        --                                                                                                                         'ACTIVE')));

                                        IF lv_transfer_rules.COUNT () > 0
                                        THEN
                                            FOR i IN 1 ..
                                                     lv_transfer_rules.COUNT ()
                                            LOOP
                                                EXIT WHEN i IS NULL;

                                                BEGIN
                                                    SELECT PRIORITY
                                                      INTO lv_priority
                                                      FROM CRPADM.RC_ASSIGNED_RP_SETUP
                                                     WHERE     THEATER_ID <>
                                                               rec.THEATER_ID
                                                           AND STATUS = 'Y'
                                                           AND REFRESH_METHOD_ID =
                                                               lv_transfer_rules (
                                                                   i).DESTINATION_REFRESH_METHOD
                                                           AND ZCODE =
                                                               lv_transfer_rules (
                                                                   i).DESTINATION_LOCATION_ZCODE
                                                           AND PROGRAM_TYPE =
                                                               lv_dgi_cross_list (
                                                                   i).PROGRAM_TYPE;
                                                EXCEPTION
                                                    WHEN NO_DATA_FOUND
                                                    THEN
                                                        lv_priority := 0;
                                                END;

                                                lv_dtn_zloc :=
                                                    lv_transfer_rules (i).DESTINATION_LOCATION_ZCODE;

                                                IF lv_dtn_zloc IS NOT NULL
                                                THEN
                                                    IF    lv_final_priority >
                                                          lv_priority
                                                       OR lv_priority <> 0
                                                    THEN
                                                        lv_final_priority :=
                                                            lv_priority;
                                                        lv_destn_zloc :=
                                                            lv_transfer_rules (
                                                                i).DESTINATION_LOCATION_ZCODE;
                                                        lv_inv_loc :=
                                                            lv_transfer_rules (
                                                                i).SUB_INVENTORY_LOCATION;
                                                    END IF;
                                                END IF;
                                            END LOOP;

                                            lv_qty_on_hand :=
                                                  lv_qty_on_hand
                                                + lv_dgi_cross_list (i).QTY_ON_HAND;
                                            lv_c3_id :=
                                                lv_src_dgi_list (idx).C3_INVENTORY_ITEM_ID;

                                            lv_exists := 0;
                                            lv_trans_qty := 0;
                                            lv_rem_qty := 0;

                                            IF (lv_inv_loc IS NOT NULL)
                                            THEN
                                                SELECT COUNT (*)
                                                  INTO lv_exists
                                                  FROM RC_INVENTORY_TRANSFER_TBL
                                                 WHERE     REFRESH_INVENTORY_ITEM_ID =
                                                           rec.REFRESH_INVENTORY_ITEM_ID
                                                       AND SOURCE_LOCATION_ZCODE =
                                                           lv_src_dgi_list (
                                                               idx).PLACE_ID
                                                       AND DESTINATION_LOCATION_ZCODE =
                                                           lv_destn_zloc
                                                       AND SUB_INVENTORY_LOCATION =
                                                           lv_inv_loc;

                                                --                                  AND C3_ONHAND_DGI = rec.QTY_ON_HAND;
                                                IF lv_dgi_src_qty > 0
                                                THEN
                                                    lv_orig_dgi_src_qty :=
                                                        lv_dgi_src_qty;

                                                    SELECT (FLOOR (
                                                                DECODE (
                                                                    lv_dgi_cross_list (
                                                                        i).REFRESH_YIELD,
                                                                    NULL, 0,
                                                                    (  lv_dgi_src_qty
                                                                     * (  lv_dgi_cross_list (
                                                                              i).REFRESH_YIELD
                                                                        / 100)))))
                                                      INTO lv_orig_dgi_src_qty_yield
                                                      FROM DUAL;

                                                    IF (    lv_exists = 0
                                                        AND (  lv_net_req_rohs_nrhs
                                                             - lv_dgi_cross_list (
                                                                   i).QTY_ON_HAND) >
                                                            0)
                                                    THEN
                                                        lv_rem_qty :=
                                                              lv_net_req_rohs_nrhs
                                                            - lv_dgi_cross_list (
                                                                  i).QTY_ON_HAND;

                                                        IF (lv_rem_qty >=
                                                            lv_orig_dgi_src_qty_yield)
                                                        THEN
                                                            lv_trans_qty :=
                                                                lv_dgi_src_qty;

                                                            SELECT (FLOOR (
                                                                        DECODE (
                                                                            lv_dgi_cross_list (
                                                                                i).REFRESH_YIELD,
                                                                            NULL, 0,
                                                                            (  lv_dgi_src_qty
                                                                             * (  lv_dgi_cross_list (
                                                                                      i).REFRESH_YIELD
                                                                                / 100)))))
                                                              INTO lv_trans_yield_qty
                                                              FROM DUAL;

                                                            lv_dgi_src_qty :=
                                                                0;
                                                        ELSIF (lv_rem_qty <
                                                               lv_orig_dgi_src_qty_yield)
                                                        THEN
                                                            SELECT (CEIL (
                                                                        DECODE (
                                                                            lv_dgi_cross_list (
                                                                                i).REFRESH_YIELD,
                                                                            NULL, 0,
                                                                            (  lv_rem_qty
                                                                             * (  100
                                                                                / lv_dgi_cross_list (
                                                                                      i).REFRESH_YIELD)))))
                                                              INTO lv_trans_qty
                                                              FROM DUAL;

                                                            SELECT (FLOOR (
                                                                        DECODE (
                                                                            lv_dgi_cross_list (
                                                                                i).REFRESH_YIELD,
                                                                            NULL, 0,
                                                                            (  lv_trans_qty
                                                                             * (  lv_dgi_cross_list (
                                                                                      i).REFRESH_YIELD
                                                                                / 100)))))
                                                              INTO lv_trans_yield_qty
                                                              FROM DUAL;

                                                            lv_dgi_src_qty :=
                                                                  lv_dgi_src_qty
                                                                - lv_trans_qty;
                                                        END IF;

                                                        INSERT INTO RC_INVENTORY_TRANSFER_TBL
                                                                 VALUES (
                                                                            rec.REFRESH_INVENTORY_ITEM_ID,
                                                                            lv_src_dgi_list (
                                                                                idx).PLACE_ID,
                                                                            lv_destn_zloc,
                                                                            lv_inv_loc,
                                                                            lv_orig_dgi_src_qty,
                                                                            SYSDATE,
                                                                            lv_c3_id,
                                                                            lv_trans_qty);

                                                        COMMIT;
                                                        lv_exists := 1;
                                                        lv_net_req_rohs_nrhs :=
                                                              lv_net_req_rohs_nrhs
                                                            - (  lv_dgi_cross_list (
                                                                     i).QTY_ON_HAND
                                                               + lv_trans_yield_qty);
                                                    ELSIF (    lv_exists > 0
                                                           AND --(  lv_net_req_rohs_nrhs
                                                               --                                                                - lv_dgi_cross_list (
                                                               --                                                                      i).QTY_ON_HAND) >
                                                               lv_net_req_rohs_nrhs >
                                                               0)
                                                    THEN
                                                        lv_rem_qty :=
                                                            lv_net_req_rohs_nrhs;

                                                        --                                                            - lv_dgi_cross_list (
                                                        --                                                                  i).QTY_ON_HAND;

                                                        IF (lv_rem_qty >=
                                                            lv_orig_dgi_src_qty_yield)
                                                        THEN
                                                            lv_trans_qty :=
                                                                lv_dgi_src_qty;

                                                            SELECT (FLOOR (
                                                                        DECODE (
                                                                            lv_dgi_cross_list (
                                                                                i).REFRESH_YIELD,
                                                                            NULL, 0,
                                                                            (  lv_dgi_src_qty
                                                                             * (  lv_dgi_cross_list (
                                                                                      i).REFRESH_YIELD
                                                                                / 100)))))
                                                              INTO lv_trans_yield_qty
                                                              FROM DUAL;

                                                            lv_dgi_src_qty :=
                                                                0;
                                                        ELSIF (lv_rem_qty <
                                                               lv_orig_dgi_src_qty_yield)
                                                        THEN
                                                            SELECT (CEIL (
                                                                        DECODE (
                                                                            lv_dgi_cross_list (
                                                                                i).REFRESH_YIELD,
                                                                            NULL, 0,
                                                                            (  lv_rem_qty
                                                                             * (  100
                                                                                / lv_dgi_cross_list (
                                                                                      i).REFRESH_YIELD)))))
                                                              INTO lv_trans_qty
                                                              FROM DUAL;

                                                            SELECT (FLOOR (
                                                                        DECODE (
                                                                            lv_dgi_cross_list (
                                                                                i).REFRESH_YIELD,
                                                                            NULL, 0,
                                                                            (  lv_trans_qty
                                                                             * (  lv_dgi_cross_list (
                                                                                      i).REFRESH_YIELD
                                                                                / 100)))))
                                                              INTO lv_trans_yield_qty
                                                              FROM DUAL;

                                                            lv_dgi_src_qty :=
                                                                  lv_dgi_src_qty
                                                                - lv_trans_qty;
                                                        END IF;

                                                        UPDATE RC_INVENTORY_TRANSFER_TBL
                                                           SET DESTINATION_LOCATION_ZCODE =
                                                                   lv_destn_zloc,
                                                               C3_ONHAND_DGI =
                                                                   lv_orig_dgi_src_qty,
                                                               QTY_TO_TRANSFER =
                                                                   lv_trans_qty
                                                         WHERE     REFRESH_INVENTORY_ITEM_ID =
                                                                   rec.REFRESH_INVENTORY_ITEM_ID
                                                               AND SOURCE_LOCATION_ZCODE =
                                                                   lv_src_dgi_list (
                                                                       idx).PLACE_ID
                                                               AND SUB_INVENTORY_LOCATION =
                                                                   lv_inv_loc;

                                                        COMMIT;
                                                        lv_net_req_rohs_nrhs :=
                                                              lv_net_req_rohs_nrhs
                                                            - (  lv_dgi_cross_list (
                                                                     i).QTY_ON_HAND
                                                               + lv_trans_yield_qty);
                                                    ELSIF ((  lv_net_req_rohs_nrhs
                                                            - lv_dgi_cross_list (
                                                                  i).QTY_ON_HAND) <
                                                           0)
                                                    THEN
                                                        lv_net_req_rohs_nrhs :=
                                                            0;
                                                    END IF;
                                                END IF;
                                            END IF;
                                        END IF;
                                    END IF;
                                END LOOP;
                            END IF;
                        END LOOP;
                    END IF;
                END IF;

                /*INSERT remaining DGI at source site into a temporary table*/
                IF lv_dgi_src_qty >= 0
                THEN
                    INSERT INTO RC_INV_TRANS_REM_DGI_DETAILS
                             VALUES (
                                        lv_src_dgi_list (idx).REFRESH_INVENTORY_ITEM_ID,
                                        lv_src_dgi_list (idx).C3_INVENTORY_ITEM_ID,
                                        lv_src_dgi_list (idx).THEATER_ID,
                                        lv_src_dgi_list (idx).LOCATION,
                                        lv_src_dgi_list (idx).PLACE_ID,
                                        lv_src_dgi_list (idx).REFRESH_YIELD,
                                        lv_dgi_src_qty,
                                        lv_src_dgi_list (idx).PROGRAM_TYPE,
                                        lv_src_dgi_list (idx).Z_PRIORITY,
                                        lv_src_dgi_list (idx).PRIORITY,
                                        lv_src_dgi_list (idx).ROHS_FLAG,
                                        SYSDATE);

                    COMMIT;
                END IF;
            END LOOP;

            /*Update the remaining net req back to table*/
            IF rec.ROHS_CHECK_NEEDED = 'Y'
            THEN
                UPDATE RC_INV_TRANS_NET_REQ_DETAILS
                   SET NET_REQ = lv_net_req,
                       NET_REQ_ROHS = lv_net_req_rohs_nrhs
                 WHERE     REFRESH_INVENTORY_ITEM_ID =
                           rec.REFRESH_INVENTORY_ITEM_ID
                       AND THEATER_ID = rec.THEATER_ID;
            ELSIF rec.ROHS_CHECK_NEEDED = 'N'
            THEN
                UPDATE RC_INV_TRANS_NET_REQ_DETAILS
                   SET NET_REQ = lv_net_req,
                       NET_REQ_NRHS = lv_net_req_rohs_nrhs
                 WHERE     REFRESH_INVENTORY_ITEM_ID =
                           rec.REFRESH_INVENTORY_ITEM_ID
                       AND THEATER_ID = rec.THEATER_ID;
            END IF;

            COMMIT;
        END LOOP;

        /*For using cross theater DGI for fulfiling req*/
        lv_src_dgi_list := RC_DGI_LIST ();

        FOR rec IN c_nam
        LOOP
            --Get the theater refurb method
            RC_GET_REFRESH_METHOD (rec.REFRESH_INVENTORY_ITEM_ID,
                                   NULL,
                                   lv_theater_refresh_method_nam,
                                   lv_theater_refresh_method_emea,
                                   lv_global_refresh_method,
                                   lv_rp_refresh_method_id);

            lv_net_req_rohs_nrhs := 0;
            lv_dgi_src_qty := 0;

            IF rec.ROHS_CHECK_NEEDED = 'Y'
            THEN
                lv_net_req_rohs_nrhs := rec.NET_REQ_ROHS;
            ELSIF rec.ROHS_CHECK_NEEDED = 'N'
            THEN
                lv_net_req_rohs_nrhs := rec.NET_REQ_NRHS;
            END IF;

            IF rec.THEATER_ID = lv_emea_id
            THEN
                lv_cross_theater := lv_nam_id;
            ELSIF rec.THEATER_ID = lv_nam_id
            THEN
                lv_cross_theater := lv_emea_id;
            END IF;

            OPEN c_rem_src_dgi_details (rec.REFRESH_INVENTORY_ITEM_ID,
                                        lv_cross_theater);

            FETCH c_rem_src_dgi_details BULK COLLECT INTO lv_src_dgi_list;

            CLOSE c_rem_src_dgi_details;

            lv_c3_id := 0;

            FOR idx IN 1 .. lv_src_dgi_list.COUNT ()
            LOOP
                lv_dgi_src_qty := lv_src_dgi_list (idx).QTY_ON_HAND;

                OPEN c_refurb_method (rec.REFRESH_INVENTORY_ITEM_ID,
                                      lv_cross_theater,
                                      lv_src_dgi_list (idx).PLACE_ID);

                FETCH c_refurb_method BULK COLLECT INTO lv_refurb_method;

                CLOSE c_refurb_method;

                IF (lv_max_refurb NOT MEMBER OF lv_refurb_method)
                THEN
                    lv_final_priority := 0;
                    lv_inv_loc := NULL;
                    lv_destn_zloc := NULL;
                    lv_qty_on_hand := 0;


                    OPEN c_dgi_details (rec.REFRESH_INVENTORY_ITEM_ID,
                                        lv_cross_theater);

                    FETCH c_dgi_details BULK COLLECT INTO lv_dgi_list;

                    CLOSE c_dgi_details;

                    FOR i IN 1 .. lv_dgi_list.COUNT ()
                    LOOP
                        IF (   lv_dgi_list (i).LOCATION <> 'RF-DGI'
                            OR (    lv_dgi_list (i).LOCATION = 'RF-DGI'
                                AND (lv_refurb_check
                                          NOT SUBMULTISET OF lv_refurb_method))) --If src is 'RF-DGI' and has both test and screen then do not transfer
                        THEN
                            FOR dat IN 1 .. lv_refurb_method.COUNT ()
                            LOOP
                                EXIT WHEN DAT IS NULL;

                                --Transfer within theater
                                IF (    lv_refurb_method (dat) <>
                                        lv_theater_refresh_method_emea
                                    AND lv_refurb_method (dat) <> 4)
                                THEN
                                    SELECT RC_INV_TRANSFER_RULES_OBJ (
                                               DESTINATION_REGION,
                                               DESTINATION_REFRESH_METHOD,
                                               DESTINATION_LOCATION_ZCODE,
                                               SUB_INVENTORY_LOCATION)
                                      BULK COLLECT INTO lv_transfer_rules
                                      FROM (SELECT DESTINATION_REGION,
                                                   DESTINATION_REFRESH_METHOD,
                                                   DESTINATION_LOCATION_ZCODE,
                                                   SUB_INVENTORY_LOCATION
                                              FROM RC_INV_TRANSFER_SETUP
                                             WHERE     IS_ACTIVE = 'Y'
                                                   AND SOURCE_REFRESH_METHOD =
                                                       lv_refurb_method (dat)
                                                   AND SOURCE_LOCATION_ZCODE =
                                                       lv_src_dgi_list (idx).PLACE_ID
                                                   AND SOURCE_REGION =
                                                       DESTINATION_REGION
                                                   AND SOURCE_REGION =
                                                       lv_cross_theater
                                                   AND (    DESTINATION_REFRESH_METHOD =
                                                            lv_dgi_list (i).REFRESH_METHOD_ID
                                                        AND DESTINATION_REFRESH_METHOD <=
                                                            lv_refurb_method (
                                                                dat))
                                                   AND SUB_INVENTORY_LOCATION =
                                                       lv_dgi_list (i).LOCATION
                                                   AND SUB_INVENTORY_LOCATION =
                                                       lv_src_dgi_list (idx).LOCATION
                                                   AND PROGRAM_TYPE =
                                                       lv_dgi_list (i).PROGRAM_TYPE
                                                   AND DESTINATION_LOCATION_ZCODE =
                                                       lv_dgi_list (i).PLACE_ID);

                                    --Find which location has the highest priority and suggest transfer to the same.
                                    IF lv_transfer_rules.COUNT () > 0
                                    THEN
                                        FOR i IN 1 ..
                                                 lv_transfer_rules.COUNT ()
                                        LOOP
                                            EXIT WHEN i IS NULL;

                                            BEGIN
                                                SELECT PRIORITY
                                                  INTO lv_priority
                                                  FROM CRPADM.RC_ASSIGNED_RP_SETUP
                                                 WHERE     THEATER_ID =
                                                           lv_cross_theater
                                                       AND STATUS = 'Y'
                                                       AND REFRESH_METHOD_ID =
                                                           lv_transfer_rules (
                                                               i).DESTINATION_REFRESH_METHOD
                                                       AND ZCODE =
                                                           lv_transfer_rules (
                                                               i).DESTINATION_LOCATION_ZCODE
                                                       AND PROGRAM_TYPE =
                                                           lv_dgi_list (i).PROGRAM_TYPE;
                                            EXCEPTION
                                                WHEN NO_DATA_FOUND
                                                THEN
                                                    lv_priority := 0;
                                            END;

                                            lv_dtn_zloc :=
                                                lv_transfer_rules (i).DESTINATION_LOCATION_ZCODE;

                                            IF lv_dtn_zloc IS NOT NULL
                                            THEN
                                                IF    lv_final_priority >
                                                      lv_priority
                                                   OR lv_priority <> 0
                                                THEN
                                                    lv_final_priority :=
                                                        lv_priority;
                                                    lv_destn_zloc :=
                                                        lv_transfer_rules (i).DESTINATION_LOCATION_ZCODE;
                                                    lv_inv_loc :=
                                                        lv_transfer_rules (i).SUB_INVENTORY_LOCATION;
                                                END IF;
                                            END IF;
                                        END LOOP;

                                        lv_qty_on_hand :=
                                              lv_qty_on_hand
                                            + lv_dgi_list (i).QTY_ON_HAND;
                                        lv_c3_id :=
                                            lv_src_dgi_list (idx).C3_INVENTORY_ITEM_ID;

                                        lv_exists := 0;
                                        lv_trans_qty := 0;
                                        lv_trans_yield_qty := 0;
                                        lv_rem_qty := 0;

                                        IF (lv_inv_loc IS NOT NULL)
                                        THEN
                                            SELECT COUNT (*)
                                              INTO lv_exists
                                              FROM RC_INVENTORY_TRANSFER_TBL
                                             WHERE     REFRESH_INVENTORY_ITEM_ID =
                                                       rec.REFRESH_INVENTORY_ITEM_ID
                                                   AND SOURCE_LOCATION_ZCODE =
                                                       lv_src_dgi_list (idx).PLACE_ID
                                                   AND DESTINATION_LOCATION_ZCODE =
                                                       lv_destn_zloc
                                                   AND SUB_INVENTORY_LOCATION =
                                                       lv_inv_loc;

                                            IF lv_dgi_src_qty > 0
                                            THEN
                                                lv_orig_dgi_src_qty :=
                                                    lv_dgi_src_qty;

                                                SELECT (FLOOR (
                                                            DECODE (
                                                                lv_dgi_list (
                                                                    i).REFRESH_YIELD,
                                                                NULL, 0,
                                                                (  lv_dgi_src_qty
                                                                 * (  lv_dgi_list (
                                                                          i).REFRESH_YIELD
                                                                    / 100)))))
                                                  INTO lv_orig_dgi_src_qty_yield
                                                  FROM DUAL;

                                                IF (    lv_exists = 0
                                                    AND (  lv_net_req_rohs_nrhs
                                                         - lv_dgi_list (i).QTY_ON_HAND) >
                                                        0)
                                                THEN
                                                    lv_rem_qty :=
                                                          lv_net_req_rohs_nrhs
                                                        - lv_dgi_list (i).QTY_ON_HAND;

                                                    IF (lv_rem_qty >=
                                                        lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        lv_trans_qty :=
                                                            lv_dgi_src_qty;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_dgi_src_qty
                                                                         * (  lv_dgi_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty := 0;
                                                    ELSIF (lv_rem_qty <
                                                           lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        SELECT (CEIL (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_rem_qty
                                                                         * (  100
                                                                            / lv_dgi_list (
                                                                                  i).REFRESH_YIELD)))))
                                                          INTO lv_trans_qty
                                                          FROM DUAL;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_trans_qty
                                                                         * (  lv_dgi_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty :=
                                                              lv_dgi_src_qty
                                                            - lv_trans_qty;
                                                    END IF;

                                                    INSERT INTO RC_INVENTORY_TRANSFER_TBL
                                                             VALUES (
                                                                        rec.REFRESH_INVENTORY_ITEM_ID,
                                                                        lv_src_dgi_list (
                                                                            idx).PLACE_ID,
                                                                        lv_destn_zloc,
                                                                        lv_inv_loc,
                                                                        lv_orig_dgi_src_qty,
                                                                        SYSDATE,
                                                                        lv_c3_id,
                                                                        lv_trans_qty);

                                                    COMMIT;
                                                    lv_exists := 1;
                                                    lv_net_req_rohs_nrhs :=
                                                          lv_net_req_rohs_nrhs
                                                        - (  lv_dgi_list (i).QTY_ON_HAND
                                                           + lv_trans_yield_qty);
                                                ELSIF (    lv_exists > 0
                                                       AND --(  lv_net_req_rohs_nrhs
                                                           --                                                            - lv_dgi_list (i).QTY_ON_HAND) >
                                                           lv_net_req_rohs_nrhs >
                                                           0)
                                                THEN
                                                    lv_rem_qty :=
                                                        lv_net_req_rohs_nrhs;

                                                    --                                                        - lv_dgi_list (i).QTY_ON_HAND;

                                                    IF (lv_rem_qty >=
                                                        lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        lv_trans_qty :=
                                                            lv_dgi_src_qty;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_dgi_src_qty
                                                                         * (  lv_dgi_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty := 0;
                                                    ELSIF (lv_rem_qty <
                                                           lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        SELECT (CEIL (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_rem_qty
                                                                         * (  100
                                                                            / lv_dgi_list (
                                                                                  i).REFRESH_YIELD)))))
                                                          INTO lv_trans_qty
                                                          FROM DUAL;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_trans_qty
                                                                         * (  lv_dgi_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty :=
                                                              lv_dgi_src_qty
                                                            - lv_trans_qty;
                                                    END IF;

                                                    UPDATE RC_INVENTORY_TRANSFER_TBL
                                                       SET --DESTINATION_LOCATION_ZCODE =
                                                           --                                                 lv_destn_zloc,
                                                           --                                              C3_ONHAND_DGI =
                                                           --                                                 lv_orig_dgi_src_qty,
                                                           QTY_TO_TRANSFER =
                                                               (  QTY_TO_TRANSFER
                                                                + lv_trans_qty)
                                                     WHERE     REFRESH_INVENTORY_ITEM_ID =
                                                               rec.REFRESH_INVENTORY_ITEM_ID
                                                           AND SOURCE_LOCATION_ZCODE =
                                                               lv_src_dgi_list (
                                                                   idx).PLACE_ID
                                                           AND SUB_INVENTORY_LOCATION =
                                                               lv_inv_loc
                                                           AND DESTINATION_LOCATION_ZCODE =
                                                               lv_destn_zloc;

                                                    COMMIT;
                                                    lv_net_req_rohs_nrhs :=
                                                          lv_net_req_rohs_nrhs
                                                        - (  lv_dgi_list (i).QTY_ON_HAND
                                                           + lv_trans_yield_qty);
                                                ELSIF ((  lv_net_req_rohs_nrhs
                                                        - lv_dgi_list (i).QTY_ON_HAND) <
                                                       0)
                                                THEN
                                                    lv_net_req_rohs_nrhs := 0;
                                                END IF;
                                            END IF;
                                        END IF;
                                    END IF;
                                END IF;
                            END LOOP;
                        END IF;
                    END LOOP;



                    --CROSS THEATER TRANSFER

                    OPEN c_dgi_details (rec.REFRESH_INVENTORY_ITEM_ID,
                                        rec.THEATER_ID);

                    FETCH c_dgi_details BULK COLLECT INTO lv_dgi_cross_list;

                    CLOSE c_dgi_details;

                    FOR i IN 1 .. lv_dgi_cross_list.COUNT ()
                    LOOP
                        IF (   lv_dgi_cross_list (i).LOCATION <> 'RF-DGI'
                            OR (    lv_dgi_cross_list (i).LOCATION = 'RF-DGI'
                                AND (lv_refurb_check
                                          NOT SUBMULTISET OF lv_refurb_method))) --If src is 'RF-DGI' and has both test and screen then do not transfer
                        THEN
                            FOR dat IN 1 .. lv_refurb_method.COUNT ()
                            LOOP
                                EXIT WHEN DAT IS NULL;

                                IF (    lv_refurb_method (dat) <>
                                        lv_global_refresh_method
                                    AND lv_refurb_method (dat) <> 4)
                                --                            AND lv_exists = 0)
                                THEN
                                    SELECT RC_INV_TRANSFER_RULES_OBJ (
                                               DESTINATION_REGION,
                                               DESTINATION_REFRESH_METHOD,
                                               DESTINATION_LOCATION_ZCODE,
                                               SUB_INVENTORY_LOCATION)
                                      BULK COLLECT INTO lv_transfer_rules
                                      FROM (SELECT DESTINATION_REGION,
                                                   DESTINATION_REFRESH_METHOD,
                                                   DESTINATION_LOCATION_ZCODE,
                                                   SUB_INVENTORY_LOCATION
                                              FROM RC_INV_TRANSFER_SETUP
                                             WHERE     IS_ACTIVE = 'Y'
                                                   AND SOURCE_REFRESH_METHOD =
                                                       lv_refurb_method (dat)
                                                   AND SOURCE_LOCATION_ZCODE =
                                                       lv_src_dgi_list (idx).PLACE_ID
                                                   AND SOURCE_REGION <>
                                                       DESTINATION_REGION
                                                   AND SOURCE_REGION =
                                                       lv_cross_theater
                                                   AND (    DESTINATION_REFRESH_METHOD =
                                                            lv_dgi_cross_list (
                                                                i).REFRESH_METHOD_ID
                                                        AND DESTINATION_REFRESH_METHOD <=
                                                            lv_refurb_method (
                                                                dat))
                                                   AND SUB_INVENTORY_LOCATION =
                                                       lv_dgi_cross_list (i).LOCATION
                                                   AND SUB_INVENTORY_LOCATION =
                                                       lv_src_dgi_list (idx).LOCATION
                                                   AND PROGRAM_TYPE =
                                                       lv_dgi_cross_list (i).PROGRAM_TYPE
                                                   AND DESTINATION_LOCATION_ZCODE =
                                                       lv_dgi_cross_list (i).PLACE_ID);

                                    IF lv_transfer_rules.COUNT () > 0
                                    THEN
                                        FOR i IN 1 ..
                                                 lv_transfer_rules.COUNT ()
                                        LOOP
                                            EXIT WHEN i IS NULL;

                                            BEGIN
                                                SELECT PRIORITY
                                                  INTO lv_priority
                                                  FROM CRPADM.RC_ASSIGNED_RP_SETUP
                                                 WHERE     THEATER_ID =
                                                           rec.THEATER_ID
                                                       AND STATUS = 'Y'
                                                       AND REFRESH_METHOD_ID =
                                                           lv_transfer_rules (
                                                               i).DESTINATION_REFRESH_METHOD
                                                       AND ZCODE =
                                                           lv_transfer_rules (
                                                               i).DESTINATION_LOCATION_ZCODE
                                                       AND PROGRAM_TYPE =
                                                           lv_dgi_cross_list (
                                                               i).PROGRAM_TYPE;
                                            EXCEPTION
                                                WHEN NO_DATA_FOUND
                                                THEN
                                                    lv_priority := 0;
                                            END;

                                            lv_dtn_zloc :=
                                                lv_transfer_rules (i).DESTINATION_LOCATION_ZCODE;

                                            IF lv_dtn_zloc IS NOT NULL
                                            THEN
                                                IF    lv_final_priority >
                                                      lv_priority
                                                   OR lv_priority <> 0
                                                THEN
                                                    lv_final_priority :=
                                                        lv_priority;
                                                    lv_destn_zloc :=
                                                        lv_transfer_rules (i).DESTINATION_LOCATION_ZCODE;
                                                    lv_inv_loc :=
                                                        lv_transfer_rules (i).SUB_INVENTORY_LOCATION;
                                                END IF;
                                            END IF;
                                        END LOOP;

                                        lv_qty_on_hand :=
                                              lv_qty_on_hand
                                            + lv_dgi_cross_list (i).QTY_ON_HAND;
                                        lv_c3_id :=
                                            lv_src_dgi_list (idx).C3_INVENTORY_ITEM_ID;

                                        lv_exists := 0;
                                        lv_trans_qty := 0;
                                        lv_rem_qty := 0;

                                        IF (lv_inv_loc IS NOT NULL)
                                        THEN
                                            SELECT COUNT (*)
                                              INTO lv_exists
                                              FROM RC_INVENTORY_TRANSFER_TBL
                                             WHERE     REFRESH_INVENTORY_ITEM_ID =
                                                       rec.REFRESH_INVENTORY_ITEM_ID
                                                   AND SOURCE_LOCATION_ZCODE =
                                                       lv_src_dgi_list (idx).PLACE_ID
                                                   AND DESTINATION_LOCATION_ZCODE =
                                                       lv_destn_zloc
                                                   AND SUB_INVENTORY_LOCATION =
                                                       lv_inv_loc;

                                            IF lv_dgi_src_qty > 0
                                            THEN
                                                lv_orig_dgi_src_qty :=
                                                    lv_dgi_src_qty;

                                                SELECT (FLOOR (
                                                            DECODE (
                                                                lv_dgi_cross_list (
                                                                    i).REFRESH_YIELD,
                                                                NULL, 0,
                                                                (  lv_dgi_src_qty
                                                                 * (  lv_dgi_cross_list (
                                                                          i).REFRESH_YIELD
                                                                    / 100)))))
                                                  INTO lv_orig_dgi_src_qty_yield
                                                  FROM DUAL;

                                                IF (    lv_exists = 0
                                                    AND (  lv_net_req_rohs_nrhs
                                                         - lv_dgi_cross_list (
                                                               i).QTY_ON_HAND) >
                                                        0)
                                                THEN
                                                    lv_rem_qty :=
                                                          lv_net_req_rohs_nrhs
                                                        - lv_dgi_cross_list (
                                                              i).QTY_ON_HAND;

                                                    IF (lv_rem_qty >=
                                                        lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        lv_trans_qty :=
                                                            lv_dgi_src_qty;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_cross_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_dgi_src_qty
                                                                         * (  lv_dgi_cross_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty := 0;
                                                    ELSIF (lv_rem_qty <
                                                           lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        SELECT (CEIL (
                                                                    DECODE (
                                                                        lv_dgi_cross_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_rem_qty
                                                                         * (  100
                                                                            / lv_dgi_cross_list (
                                                                                  i).REFRESH_YIELD)))))
                                                          INTO lv_trans_qty
                                                          FROM DUAL;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_cross_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_trans_qty
                                                                         * (  lv_dgi_cross_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty :=
                                                              lv_dgi_src_qty
                                                            - lv_trans_qty;
                                                    END IF;

                                                    INSERT INTO RC_INVENTORY_TRANSFER_TBL
                                                             VALUES (
                                                                        rec.REFRESH_INVENTORY_ITEM_ID,
                                                                        lv_src_dgi_list (
                                                                            idx).PLACE_ID,
                                                                        lv_destn_zloc,
                                                                        lv_inv_loc,
                                                                        lv_orig_dgi_src_qty,
                                                                        SYSDATE,
                                                                        lv_c3_id,
                                                                        lv_trans_qty);

                                                    COMMIT;
                                                    lv_exists := 1;
                                                    lv_net_req_rohs_nrhs :=
                                                          lv_net_req_rohs_nrhs
                                                        - (  lv_dgi_cross_list (
                                                                 i).QTY_ON_HAND
                                                           + lv_trans_yield_qty);
                                                ELSIF (    lv_exists > 0
                                                       AND --(  lv_net_req_rohs_nrhs
                                                           --                                                            - lv_dgi_cross_list (
                                                           --                                                                  i).QTY_ON_HAND) >
                                                           lv_net_req_rohs_nrhs >
                                                           0)
                                                THEN
                                                    lv_rem_qty :=
                                                        lv_net_req_rohs_nrhs;

                                                    --                                                        - lv_dgi_cross_list (
                                                    --                                                              i).QTY_ON_HAND;

                                                    IF (lv_rem_qty >=
                                                        lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        lv_trans_qty :=
                                                            lv_dgi_src_qty;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_cross_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_dgi_src_qty
                                                                         * (  lv_dgi_cross_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty := 0;
                                                    ELSIF (lv_rem_qty <
                                                           lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        SELECT (CEIL (
                                                                    DECODE (
                                                                        lv_dgi_cross_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_rem_qty
                                                                         * (  100
                                                                            / lv_dgi_cross_list (
                                                                                  i).REFRESH_YIELD)))))
                                                          INTO lv_trans_qty
                                                          FROM DUAL;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_cross_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_trans_qty
                                                                         * (  lv_dgi_cross_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty :=
                                                              lv_dgi_src_qty
                                                            - lv_trans_qty;
                                                    END IF;

                                                    UPDATE RC_INVENTORY_TRANSFER_TBL
                                                       SET --DESTINATION_LOCATION_ZCODE =
                                                           --                                                    lv_destn_zloc,
                                                           --                                                 C3_ONHAND_DGI =
                                                           --                                                    lv_orig_dgi_src_qty,
                                                           QTY_TO_TRANSFER =
                                                               (  QTY_TO_TRANSFER
                                                                + lv_trans_qty)
                                                     WHERE     REFRESH_INVENTORY_ITEM_ID =
                                                               rec.REFRESH_INVENTORY_ITEM_ID
                                                           AND SOURCE_LOCATION_ZCODE =
                                                               lv_src_dgi_list (
                                                                   idx).PLACE_ID
                                                           AND SUB_INVENTORY_LOCATION =
                                                               lv_inv_loc
                                                           AND DESTINATION_LOCATION_ZCODE =
                                                               lv_destn_zloc;

                                                    COMMIT;
                                                    lv_net_req_rohs_nrhs :=
                                                          lv_net_req_rohs_nrhs
                                                        - (  lv_dgi_cross_list (
                                                                 i).QTY_ON_HAND
                                                           + lv_trans_yield_qty);
                                                ELSIF ((  lv_net_req_rohs_nrhs
                                                        - lv_dgi_cross_list (
                                                              i).QTY_ON_HAND) <
                                                       0)
                                                THEN
                                                    lv_net_req_rohs_nrhs := 0;
                                                END IF;
                                            END IF;
                                        END IF;
                                    END IF;
                                END IF;
                            END LOOP;
                        END IF;
                    END LOOP;
                END IF;
            END LOOP;
        END LOOP;

        lv_src_dgi_list := RC_DGI_LIST ();

        FOR rec IN c_emea
        LOOP
            --Get the theater refurb method
            RC_GET_REFRESH_METHOD (rec.REFRESH_INVENTORY_ITEM_ID,
                                   NULL,
                                   lv_theater_refresh_method_nam,
                                   lv_theater_refresh_method_emea,
                                   lv_global_refresh_method,
                                   lv_rp_refresh_method_id);

            lv_net_req_rohs_nrhs := 0;
            lv_dgi_src_qty := 0;

            IF rec.ROHS_CHECK_NEEDED = 'Y'
            THEN
                lv_net_req_rohs_nrhs := rec.NET_REQ_ROHS;
            ELSIF rec.ROHS_CHECK_NEEDED = 'N'
            THEN
                lv_net_req_rohs_nrhs := rec.NET_REQ_NRHS;
            END IF;

            IF rec.THEATER_ID = lv_emea_id
            THEN
                lv_cross_theater := lv_nam_id;
            ELSIF rec.THEATER_ID = lv_nam_id
            THEN
                lv_cross_theater := lv_emea_id;
            END IF;

            OPEN c_rem_src_dgi_details (rec.REFRESH_INVENTORY_ITEM_ID,
                                        lv_cross_theater);

            FETCH c_rem_src_dgi_details BULK COLLECT INTO lv_src_dgi_list;

            CLOSE c_rem_src_dgi_details;

            lv_c3_id := 0;

            FOR idx IN 1 .. lv_src_dgi_list.COUNT ()
            LOOP
                lv_dgi_src_qty := lv_src_dgi_list (idx).QTY_ON_HAND;

                OPEN c_refurb_method (rec.REFRESH_INVENTORY_ITEM_ID,
                                      lv_cross_theater,
                                      lv_src_dgi_list (idx).PLACE_ID);

                FETCH c_refurb_method BULK COLLECT INTO lv_refurb_method;

                CLOSE c_refurb_method;

                IF (lv_max_refurb NOT MEMBER OF lv_refurb_method)
                THEN
                    lv_final_priority := 0;
                    lv_inv_loc := NULL;
                    lv_destn_zloc := NULL;
                    lv_qty_on_hand := 0;

                    OPEN c_dgi_details (rec.REFRESH_INVENTORY_ITEM_ID,
                                        lv_cross_theater);

                    FETCH c_dgi_details BULK COLLECT INTO lv_dgi_list;

                    CLOSE c_dgi_details;

                    FOR i IN 1 .. lv_dgi_list.COUNT ()
                    LOOP
                        IF (   lv_dgi_list (i).LOCATION <> 'RF-DGI'
                            OR (    lv_dgi_list (i).LOCATION = 'RF-DGI'
                                AND (lv_refurb_check
                                          NOT SUBMULTISET OF lv_refurb_method))) --If src is 'RF-DGI' and has both test and screen then do not transfer
                        THEN
                            FOR dat IN 1 .. lv_refurb_method.COUNT ()
                            LOOP
                                EXIT WHEN DAT IS NULL;

                                --Transfer within theater
                                IF (    lv_refurb_method (dat) <>
                                        lv_theater_refresh_method_nam
                                    AND lv_refurb_method (dat) <> 4)
                                THEN
                                    SELECT RC_INV_TRANSFER_RULES_OBJ (
                                               DESTINATION_REGION,
                                               DESTINATION_REFRESH_METHOD,
                                               DESTINATION_LOCATION_ZCODE,
                                               SUB_INVENTORY_LOCATION)
                                      BULK COLLECT INTO lv_transfer_rules
                                      FROM (SELECT DESTINATION_REGION,
                                                   DESTINATION_REFRESH_METHOD,
                                                   DESTINATION_LOCATION_ZCODE,
                                                   SUB_INVENTORY_LOCATION
                                              FROM RC_INV_TRANSFER_SETUP
                                             WHERE     IS_ACTIVE = 'Y'
                                                   AND SOURCE_REFRESH_METHOD =
                                                       lv_refurb_method (dat)
                                                   AND SOURCE_LOCATION_ZCODE =
                                                       lv_src_dgi_list (idx).PLACE_ID
                                                   AND SOURCE_REGION =
                                                       DESTINATION_REGION
                                                   AND SOURCE_REGION =
                                                       lv_cross_theater
                                                   AND (    DESTINATION_REFRESH_METHOD =
                                                            lv_dgi_list (i).REFRESH_METHOD_ID
                                                        AND DESTINATION_REFRESH_METHOD <=
                                                            lv_refurb_method (
                                                                dat))
                                                   AND SUB_INVENTORY_LOCATION =
                                                       lv_dgi_list (i).LOCATION
                                                   AND SUB_INVENTORY_LOCATION =
                                                       lv_src_dgi_list (idx).LOCATION
                                                   AND PROGRAM_TYPE =
                                                       lv_dgi_list (i).PROGRAM_TYPE
                                                   AND DESTINATION_LOCATION_ZCODE =
                                                       lv_dgi_list (i).PLACE_ID);

                                    --Find which location has the highest priority and suggest transfer to the same.
                                    IF lv_transfer_rules.COUNT () > 0
                                    THEN
                                        FOR i IN 1 ..
                                                 lv_transfer_rules.COUNT ()
                                        LOOP
                                            EXIT WHEN i IS NULL;

                                            BEGIN
                                                SELECT PRIORITY
                                                  INTO lv_priority
                                                  FROM CRPADM.RC_ASSIGNED_RP_SETUP
                                                 WHERE     THEATER_ID =
                                                           lv_cross_theater
                                                       AND STATUS = 'Y'
                                                       AND REFRESH_METHOD_ID =
                                                           lv_transfer_rules (
                                                               i).DESTINATION_REFRESH_METHOD
                                                       AND ZCODE =
                                                           lv_transfer_rules (
                                                               i).DESTINATION_LOCATION_ZCODE
                                                       AND PROGRAM_TYPE =
                                                           lv_dgi_list (i).PROGRAM_TYPE;
                                            EXCEPTION
                                                WHEN NO_DATA_FOUND
                                                THEN
                                                    lv_priority := 0;
                                            END;

                                            lv_dtn_zloc :=
                                                lv_transfer_rules (i).DESTINATION_LOCATION_ZCODE;

                                            IF lv_dtn_zloc IS NOT NULL
                                            THEN
                                                IF    lv_final_priority >
                                                      lv_priority
                                                   OR lv_priority <> 0
                                                THEN
                                                    lv_final_priority :=
                                                        lv_priority;
                                                    lv_destn_zloc :=
                                                        lv_transfer_rules (i).DESTINATION_LOCATION_ZCODE;
                                                    lv_inv_loc :=
                                                        lv_transfer_rules (i).SUB_INVENTORY_LOCATION;
                                                END IF;
                                            END IF;
                                        END LOOP;

                                        lv_qty_on_hand :=
                                              lv_qty_on_hand
                                            + lv_dgi_list (i).QTY_ON_HAND;
                                        lv_c3_id :=
                                            lv_src_dgi_list (idx).C3_INVENTORY_ITEM_ID;

                                        lv_exists := 0;
                                        lv_trans_qty := 0;
                                        lv_trans_yield_qty := 0;
                                        lv_rem_qty := 0;

                                        IF (lv_inv_loc IS NOT NULL)
                                        THEN
                                            SELECT COUNT (*)
                                              INTO lv_exists
                                              FROM RC_INVENTORY_TRANSFER_TBL
                                             WHERE     REFRESH_INVENTORY_ITEM_ID =
                                                       rec.REFRESH_INVENTORY_ITEM_ID
                                                   AND SOURCE_LOCATION_ZCODE =
                                                       lv_src_dgi_list (idx).PLACE_ID
                                                   AND DESTINATION_LOCATION_ZCODE =
                                                       lv_destn_zloc
                                                   AND SUB_INVENTORY_LOCATION =
                                                       lv_inv_loc;

                                            IF lv_dgi_src_qty > 0
                                            THEN
                                                lv_orig_dgi_src_qty :=
                                                    lv_dgi_src_qty;

                                                SELECT (FLOOR (
                                                            DECODE (
                                                                lv_dgi_list (
                                                                    i).REFRESH_YIELD,
                                                                NULL, 0,
                                                                (  lv_dgi_src_qty
                                                                 * (  lv_dgi_list (
                                                                          i).REFRESH_YIELD
                                                                    / 100)))))
                                                  INTO lv_orig_dgi_src_qty_yield
                                                  FROM DUAL;

                                                IF (lv_exists = 0 AND --(  lv_net_req_rohs_nrhs
 --                                                         - lv_dgi_list (i).QTY_ON_HAND) >
                                                     lv_net_req_rohs_nrhs > 0)
                                                THEN
                                                    lv_rem_qty :=
                                                        lv_net_req_rohs_nrhs;

                                                    --                                                        - lv_dgi_list (i).QTY_ON_HAND;

                                                    IF (lv_rem_qty >=
                                                        lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        lv_trans_qty :=
                                                            lv_dgi_src_qty;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_dgi_src_qty
                                                                         * (  lv_dgi_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty := 0;
                                                    ELSIF (lv_rem_qty <
                                                           lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        SELECT (CEIL (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_rem_qty
                                                                         * (  100
                                                                            / lv_dgi_list (
                                                                                  i).REFRESH_YIELD)))))
                                                          INTO lv_trans_qty
                                                          FROM DUAL;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_trans_qty
                                                                         * (  lv_dgi_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty :=
                                                              lv_dgi_src_qty
                                                            - lv_trans_qty;
                                                    END IF;

                                                    INSERT INTO RC_INVENTORY_TRANSFER_TBL
                                                             VALUES (
                                                                        rec.REFRESH_INVENTORY_ITEM_ID,
                                                                        lv_src_dgi_list (
                                                                            idx).PLACE_ID,
                                                                        lv_destn_zloc,
                                                                        lv_inv_loc,
                                                                        lv_orig_dgi_src_qty,
                                                                        SYSDATE,
                                                                        lv_c3_id,
                                                                        lv_trans_qty);

                                                    COMMIT;
                                                    lv_exists := 1;
                                                    lv_net_req_rohs_nrhs :=
                                                          lv_net_req_rohs_nrhs
                                                        - (  lv_dgi_list (i).QTY_ON_HAND
                                                           + lv_trans_yield_qty);
                                                ELSIF (    lv_exists > 0
                                                       AND --(  lv_net_req_rohs_nrhs
                                                           --                                                            - lv_dgi_list (i).QTY_ON_HAND) >
                                                           lv_net_req_rohs_nrhs >
                                                           0)
                                                THEN
                                                    lv_rem_qty :=
                                                        lv_net_req_rohs_nrhs;

                                                    --                                                        - lv_dgi_list (i).QTY_ON_HAND;

                                                    IF (lv_rem_qty >=
                                                        lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        lv_trans_qty :=
                                                            lv_dgi_src_qty;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_dgi_src_qty
                                                                         * (  lv_dgi_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty := 0;
                                                    ELSIF (lv_rem_qty <
                                                           lv_orig_dgi_src_qty_yield)
                                                    THEN
                                                        SELECT (CEIL (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_rem_qty
                                                                         * (  100
                                                                            / lv_dgi_list (
                                                                                  i).REFRESH_YIELD)))))
                                                          INTO lv_trans_qty
                                                          FROM DUAL;

                                                        SELECT (FLOOR (
                                                                    DECODE (
                                                                        lv_dgi_list (
                                                                            i).REFRESH_YIELD,
                                                                        NULL, 0,
                                                                        (  lv_trans_qty
                                                                         * (  lv_dgi_list (
                                                                                  i).REFRESH_YIELD
                                                                            / 100)))))
                                                          INTO lv_trans_yield_qty
                                                          FROM DUAL;

                                                        lv_dgi_src_qty :=
                                                              lv_dgi_src_qty
                                                            - lv_trans_qty;
                                                    END IF;

                                                    UPDATE RC_INVENTORY_TRANSFER_TBL
                                                       SET --DESTINATION_LOCATION_ZCODE =
                                                           --                                                 lv_destn_zloc,
                                                           --                                              C3_ONHAND_DGI =
                                                           --                                                 lv_orig_dgi_src_qty,
                                                           QTY_TO_TRANSFER =
                                                               (  QTY_TO_TRANSFER
                                                                + lv_trans_qty)
                                                     WHERE     REFRESH_INVENTORY_ITEM_ID =
                                                               rec.REFRESH_INVENTORY_ITEM_ID
                                                           AND SOURCE_LOCATION_ZCODE =
                                                               lv_src_dgi_list (
                                                                   idx).PLACE_ID
                                                           AND SUB_INVENTORY_LOCATION =
                                                               lv_inv_loc
                                                           AND DESTINATION_LOCATION_ZCODE =
                                                               lv_destn_zloc;

                                                    COMMIT;
                                                    lv_net_req_rohs_nrhs :=
                                                          lv_net_req_rohs_nrhs
                                                        - (  lv_dgi_list (i).QTY_ON_HAND
                                                           + lv_trans_yield_qty);
                                                ELSIF ((  lv_net_req_rohs_nrhs
                                                        - lv_dgi_list (i).QTY_ON_HAND) <
                                                       0)
                                                THEN
                                                    lv_net_req_rohs_nrhs := 0;
                                                END IF;
                                            END IF;
                                        END IF;
                                    END IF;
                                END IF;
                            END LOOP;
                        END IF;
                    END LOOP;

                    --CROSS THEATER TRANSFER
                    OPEN c_dgi_details (rec.REFRESH_INVENTORY_ITEM_ID,
                                        rec.THEATER_ID);

                    FETCH c_dgi_details BULK COLLECT INTO lv_dgi_cross_list;

                    CLOSE c_dgi_details;

                    FOR i IN 1 .. lv_dgi_cross_list.COUNT ()
                    LOOP
                        IF (   lv_dgi_cross_list (i).LOCATION <> 'RF-DGI'
                            OR (    lv_dgi_cross_list (i).LOCATION = 'RF-DGI'
                                AND (lv_refurb_check
                                          NOT SUBMULTISET OF lv_refurb_method))) --If src is 'RF-DGI' and has both test and screen then do not transfer
                        THEN
                            FOR dat IN 1 .. lv_refurb_method.COUNT ()
                            LOOP
                                EXIT WHEN DAT IS NULL;


                                IF (    lv_refurb_method (dat) <>
                                        lv_global_refresh_method
                                    AND lv_refurb_method (dat) <> 4)
                                --                            AND lv_exists = 0)
                                THEN
                                    SELECT RC_INV_TRANSFER_RULES_OBJ (
                                               DESTINATION_REGION,
                                               DESTINATION_REFRESH_METHOD,
                                               DESTINATION_LOCATION_ZCODE,
                                               SUB_INVENTORY_LOCATION)
                                      BULK COLLECT INTO lv_transfer_rules
                                      FROM (SELECT DESTINATION_REGION,
                                                   DESTINATION_REFRESH_METHOD,
                                                   DESTINATION_LOCATION_ZCODE,
                                                   SUB_INVENTORY_LOCATION
                                              FROM RC_INV_TRANSFER_SETUP
                                             WHERE     IS_ACTIVE = 'Y'
                                                   AND SOURCE_REFRESH_METHOD =
                                                       lv_refurb_method (dat)
                                                   AND SOURCE_LOCATION_ZCODE =
                                                       lv_src_dgi_list (idx).PLACE_ID
                                                   AND SOURCE_REGION <>
                                                       DESTINATION_REGION
                                                   AND SOURCE_REGION =
                                                       lv_cross_theater
                                                   AND (    DESTINATION_REFRESH_METHOD =
                                                            lv_dgi_cross_list (
                                                                i).REFRESH_METHOD_ID
                                                        AND DESTINATION_REFRESH_METHOD <=
                                                            lv_refurb_method (
                                                                dat))
                                                   AND SUB_INVENTORY_LOCATION =
                                                       lv_dgi_cross_list (i).LOCATION
                                                   AND SUB_INVENTORY_LOCATION =
                                                       lv_src_dgi_list (idx).LOCATION
                                                   AND PROGRAM_TYPE =
                                                       lv_dgi_cross_list (i).PROGRAM_TYPE
                                                   AND DESTINATION_LOCATION_ZCODE =
                                                       lv_dgi_cross_list (i).PLACE_ID);

                                    IF lv_transfer_rules.COUNT () > 0
                                    THEN
                                        FOR i IN 1 ..
                                                 lv_transfer_rules.COUNT ()
                                        LOOP
                                            EXIT WHEN i IS NULL;

                                            BEGIN
                                                SELECT PRIORITY
                                                  INTO lv_priority
                                                  FROM CRPADM.RC_ASSIGNED_RP_SETUP
                                                 WHERE     THEATER_ID =
                                                           rec.THEATER_ID
                                                       AND STATUS = 'Y'
                                                       AND REFRESH_METHOD_ID =
                                                           lv_transfer_rules (
                                                               i).DESTINATION_REFRESH_METHOD
                                                       AND ZCODE =
                                                           lv_transfer_rules (
                                                               i).DESTINATION_LOCATION_ZCODE
                                                       AND PROGRAM_TYPE =
                                                           lv_dgi_cross_list (
                                                               i).PROGRAM_TYPE;
                                            EXCEPTION
                                                WHEN NO_DATA_FOUND
                                                THEN
                                                    lv_priority := 0;
                                            END;

                                            lv_dtn_zloc :=
                                                lv_transfer_rules (i).DESTINATION_LOCATION_ZCODE;

                                            IF lv_dtn_zloc IS NOT NULL
                                            THEN
                                                IF    lv_final_priority >
                                                      lv_priority
                                                   OR lv_priority <> 0
                                                THEN
                                                    lv_final_priority :=
                                                        lv_priority;
                                                    lv_destn_zloc :=
                                                        lv_transfer_rules (i).DESTINATION_LOCATION_ZCODE;
                                                    lv_inv_loc :=
                                                        lv_transfer_rules (i).SUB_INVENTORY_LOCATION;
                                                    lv_dtn_refresh_method :=
                                                        lv_transfer_rules (i).DESTINATION_REFRESH_METHOD;
                                                END IF;
                                            END IF;
                                        END LOOP;

                                        lv_qty_on_hand :=
                                              lv_qty_on_hand
                                            + lv_dgi_cross_list (i).QTY_ON_HAND;
                                        lv_c3_id :=
                                            lv_src_dgi_list (idx).C3_INVENTORY_ITEM_ID;

                                        lv_exists := 0;
                                        lv_trans_qty := 0;
                                        lv_rem_qty := 0;

                                        IF (lv_inv_loc IS NOT NULL)
                                        THEN
                                            BEGIN
                                                SELECT ROHS_FLAG
                                                  INTO lv_rohs_flag
                                                  FROM CRPADM.RC_SUB_INV_LOC_FLG_DTLS
                                                       FLG
                                                       JOIN
                                                       CRPADM.RC_SUB_INV_LOC_MSTR
                                                       MP
                                                           ON MP.SUB_INVENTORY_ID =
                                                              FLG.SUB_INVENTORY_ID
                                                 WHERE     FLG.REFRESH_METHOD_ID =
                                                           lv_dtn_refresh_method
                                                       AND MP.SUB_INVENTORY_LOCATION =
                                                           lv_inv_loc;
                                            EXCEPTION
                                                WHEN OTHERS
                                                THEN
                                                    lv_rohs_flag := '';
                                            END;

                                            IF lv_rohs_flag = '1'
                                            THEN
                                                SELECT COUNT (*)
                                                  INTO lv_exists
                                                  FROM RC_INVENTORY_TRANSFER_TBL
                                                 WHERE     REFRESH_INVENTORY_ITEM_ID =
                                                           rec.REFRESH_INVENTORY_ITEM_ID
                                                       AND SOURCE_LOCATION_ZCODE =
                                                           lv_src_dgi_list (
                                                               idx).PLACE_ID
                                                       AND DESTINATION_LOCATION_ZCODE =
                                                           lv_destn_zloc
                                                       AND SUB_INVENTORY_LOCATION =
                                                           lv_inv_loc;

                                                IF lv_dgi_src_qty > 0
                                                THEN
                                                    lv_orig_dgi_src_qty :=
                                                        lv_dgi_src_qty;

                                                    SELECT (FLOOR (
                                                                DECODE (
                                                                    lv_dgi_cross_list (
                                                                        i).REFRESH_YIELD,
                                                                    NULL, 0,
                                                                    (  lv_dgi_src_qty
                                                                     * (  lv_dgi_cross_list (
                                                                              i).REFRESH_YIELD
                                                                        / 100)))))
                                                      INTO lv_orig_dgi_src_qty_yield
                                                      FROM DUAL;

                                                    IF (    lv_exists = 0
                                                        AND (  lv_net_req_rohs_nrhs
                                                             - lv_dgi_cross_list (
                                                                   i).QTY_ON_HAND) >
                                                            0)
                                                    THEN
                                                        lv_rem_qty :=
                                                              lv_net_req_rohs_nrhs
                                                            - lv_dgi_cross_list (
                                                                  i).QTY_ON_HAND;

                                                        IF (lv_rem_qty >=
                                                            lv_orig_dgi_src_qty_yield)
                                                        THEN
                                                            lv_trans_qty :=
                                                                lv_dgi_src_qty;

                                                            SELECT (FLOOR (
                                                                        DECODE (
                                                                            lv_dgi_cross_list (
                                                                                i).REFRESH_YIELD,
                                                                            NULL, 0,
                                                                            (  lv_dgi_src_qty
                                                                             * (  lv_dgi_cross_list (
                                                                                      i).REFRESH_YIELD
                                                                                / 100)))))
                                                              INTO lv_trans_yield_qty
                                                              FROM DUAL;

                                                            lv_dgi_src_qty :=
                                                                0;
                                                        ELSIF (lv_rem_qty <
                                                               lv_orig_dgi_src_qty_yield)
                                                        THEN
                                                            SELECT (CEIL (
                                                                        DECODE (
                                                                            lv_dgi_cross_list (
                                                                                i).REFRESH_YIELD,
                                                                            NULL, 0,
                                                                            (  lv_rem_qty
                                                                             * (  100
                                                                                / lv_dgi_cross_list (
                                                                                      i).REFRESH_YIELD)))))
                                                              INTO lv_trans_qty
                                                              FROM DUAL;

                                                            SELECT (FLOOR (
                                                                        DECODE (
                                                                            lv_dgi_cross_list (
                                                                                i).REFRESH_YIELD,
                                                                            NULL, 0,
                                                                            (  lv_trans_qty
                                                                             * (  lv_dgi_cross_list (
                                                                                      i).REFRESH_YIELD
                                                                                / 100)))))
                                                              INTO lv_trans_yield_qty
                                                              FROM DUAL;

                                                            lv_dgi_src_qty :=
                                                                  lv_dgi_src_qty
                                                                - lv_trans_qty;
                                                        END IF;

                                                        INSERT INTO RC_INVENTORY_TRANSFER_TBL
                                                                 VALUES (
                                                                            rec.REFRESH_INVENTORY_ITEM_ID,
                                                                            lv_src_dgi_list (
                                                                                idx).PLACE_ID,
                                                                            lv_destn_zloc,
                                                                            lv_inv_loc,
                                                                            lv_orig_dgi_src_qty,
                                                                            SYSDATE,
                                                                            lv_c3_id,
                                                                            lv_trans_qty);

                                                        COMMIT;
                                                        lv_exists := 1;
                                                        lv_net_req_rohs_nrhs :=
                                                              lv_net_req_rohs_nrhs
                                                            - (  lv_dgi_cross_list (
                                                                     i).QTY_ON_HAND
                                                               + lv_trans_yield_qty);
                                                    ELSIF (    lv_exists > 0
                                                           AND --(  lv_net_req_rohs_nrhs
                                                               --                                                                - lv_dgi_cross_list (
                                                               --                                                                      i).QTY_ON_HAND) >
                                                               lv_net_req_rohs_nrhs >
                                                               0)
                                                    THEN
                                                        lv_rem_qty :=
                                                            lv_net_req_rohs_nrhs;

                                                        --                                                            - lv_dgi_cross_list (
                                                        --                                                                  i).QTY_ON_HAND;

                                                        IF (lv_rem_qty >=
                                                            lv_orig_dgi_src_qty_yield)
                                                        THEN
                                                            lv_trans_qty :=
                                                                lv_dgi_src_qty;

                                                            SELECT (FLOOR (
                                                                        DECODE (
                                                                            lv_dgi_cross_list (
                                                                                i).REFRESH_YIELD,
                                                                            NULL, 0,
                                                                            (  lv_dgi_src_qty
                                                                             * (  lv_dgi_cross_list (
                                                                                      i).REFRESH_YIELD
                                                                                / 100)))))
                                                              INTO lv_trans_yield_qty
                                                              FROM DUAL;

                                                            lv_dgi_src_qty :=
                                                                0;
                                                        ELSIF (lv_rem_qty <
                                                               lv_orig_dgi_src_qty_yield)
                                                        THEN
                                                            SELECT (CEIL (
                                                                        DECODE (
                                                                            lv_dgi_cross_list (
                                                                                i).REFRESH_YIELD,
                                                                            NULL, 0,
                                                                            (  lv_rem_qty
                                                                             * (  100
                                                                                / lv_dgi_cross_list (
                                                                                      i).REFRESH_YIELD)))))
                                                              INTO lv_trans_qty
                                                              FROM DUAL;

                                                            SELECT (FLOOR (
                                                                        DECODE (
                                                                            lv_dgi_cross_list (
                                                                                i).REFRESH_YIELD,
                                                                            NULL, 0,
                                                                            (  lv_trans_qty
                                                                             * (  lv_dgi_cross_list (
                                                                                      i).REFRESH_YIELD
                                                                                / 100)))))
                                                              INTO lv_trans_yield_qty
                                                              FROM DUAL;

                                                            lv_dgi_src_qty :=
                                                                  lv_dgi_src_qty
                                                                - lv_trans_qty;
                                                        END IF;

                                                        UPDATE RC_INVENTORY_TRANSFER_TBL
                                                           SET --DESTINATION_LOCATION_ZCODE =
                                                               --                                                    lv_destn_zloc,
                                                               --                                                 C3_ONHAND_DGI =
                                                               --                                                    lv_orig_dgi_src_qty,
                                                               QTY_TO_TRANSFER =
                                                                   (  QTY_TO_TRANSFER
                                                                    + lv_trans_qty)
                                                         WHERE     REFRESH_INVENTORY_ITEM_ID =
                                                                   rec.REFRESH_INVENTORY_ITEM_ID
                                                               AND SOURCE_LOCATION_ZCODE =
                                                                   lv_src_dgi_list (
                                                                       idx).PLACE_ID
                                                               AND SUB_INVENTORY_LOCATION =
                                                                   lv_inv_loc
                                                               AND DESTINATION_LOCATION_ZCODE =
                                                                   lv_destn_zloc;

                                                        COMMIT;
                                                        lv_net_req_rohs_nrhs :=
                                                              lv_net_req_rohs_nrhs
                                                            - (  lv_dgi_cross_list (
                                                                     i).QTY_ON_HAND
                                                               + lv_trans_yield_qty);
                                                    ELSIF ((  lv_net_req_rohs_nrhs
                                                            - lv_dgi_cross_list (
                                                                  i).QTY_ON_HAND) <
                                                           0)
                                                    THEN
                                                        lv_net_req_rohs_nrhs :=
                                                            0;
                                                    END IF;
                                                END IF;
                                            END IF;
                                        END IF;
                                    END IF;
                                END IF;
                            END LOOP;
                        END IF;
                    END LOOP;
                END IF;
            END LOOP;
        END LOOP;

        --Insert into RC_NOTIFICATION_HISTORY table for notifications

        INSERT INTO CRPADM.RC_JOBS_NOTIFICATION_HISTORY (NOTIFICATION_ID,
                                                         TIME_STAMP,
                                                         STATUS)
             VALUES (4, SYSDATE, 'Successful');

        --Log process END timestamp

        INSERT INTO CRPADM.RC_PROCESS_LOG
             VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                     'RC_INV_TRANSFER_ENGINE',
                     'END',
                     SYSDATE);

        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            --Insert into RC_NOTIFICATION_HISTORY table for notifications

            INSERT INTO CRPADM.RC_JOBS_NOTIFICATION_HISTORY (NOTIFICATION_ID,
                                                             TIME_STAMP,
                                                             STATUS)
                 VALUES (4, SYSDATE, 'Failed');

            COMMIT;
            g_error_msg :=
                   SUBSTR (SQLERRM, 1, 200)
                || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
            CRPADM.RC_GLOBAL_ERROR_LOGGING (
                'OTHERS',
                g_error_msg,
                NULL,
                'CRPSC.RC_INVENTORY_TRANSFER.RC_INV_TRANSFER_ENGINE',
                'PACKAGE',
                NULL,
                'Y');
    END RC_INV_TRANSFER_ENGINE;

    /*-----------------------Procedure to fetch data for Inventory Transfer set up Dropdowns-------------------------------*/

    PROCEDURE RC_FETCH_INV_SETUP_DROPDOWNS (
        i_user_id                 IN     VARCHAR2,
        o_refresh_method_list        OUT RC_REFRESH_METHOD_LIST,
        o_theater_list               OUT RC_INV_THEATER_LIST,
        o_zlocation_list             OUT RC_ZLOCATION_LIST,
        o_sub_inv_location_list      OUT RC_SUB_INV_LOCATION_LIST,
        o_program_type_list          OUT RC_INV_THEATER_LIST)
    IS
        lv_refresh_method_list     RC_REFRESH_METHOD_LIST;
        lv_theater_list            RC_INV_THEATER_LIST;
        lv_zlocation_list          RC_ZLOCATION_LIST;
        lv_sub_inv_location_list   RC_SUB_INV_LOCATION_LIST;
        lv_program_type_list       RC_INV_THEATER_LIST;
    BEGIN
        lv_refresh_method_list := RC_REFRESH_METHOD_LIST ();
        lv_theater_list := RC_INV_THEATER_LIST ();
        lv_zlocation_list := RC_ZLOCATION_LIST ();
        lv_sub_inv_location_list := RC_SUB_INV_LOCATION_LIST ();
        o_refresh_method_list := RC_REFRESH_METHOD_LIST ();
        o_theater_list := RC_INV_THEATER_LIST ();
        o_zlocation_list := RC_ZLOCATION_LIST ();
        o_sub_inv_location_list := RC_SUB_INV_LOCATION_LIST ();
        lv_program_type_list := RC_INV_THEATER_LIST ();
        o_program_type_list := RC_INV_THEATER_LIST ();

        BEGIN
            SELECT RC_REFRESH_METHOD_OBJ (CONFIG_NAME, CONFIG_ID, UDC_1)
              BULK COLLECT INTO lv_refresh_method_list
              FROM (  SELECT CONFIG_NAME, CONFIG_ID, UDC_1
                        FROM CRPADM.RC_PRODUCT_CONFIG
                       WHERE CONFIG_TYPE = 'REFRESH_METHOD' AND CONFIG_ID != 4 --None is not included
                    ORDER BY CONFIG_ID DESC);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_refresh_method_list := RC_REFRESH_METHOD_LIST ();
        END;

        BEGIN
            SELECT RC_INV_THEATER_OBJ (CONFIG_NAME, CONFIG_ID)
              BULK COLLECT INTO lv_theater_list
              FROM (SELECT CONFIG_NAME, CONFIG_ID
                      FROM CRPADM.RC_PRODUCT_CONFIG
                     WHERE     CONFIG_TYPE = 'THEATER'
                           AND CONFIG_NAME NOT IN ('JPN', 'APAC')); --only NAM and EMEA theatre
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_theater_list := RC_INV_THEATER_LIST ();
        END;

        BEGIN
            SELECT RC_ZLOCATION_OBJ (ZCODE, THEATER_ID)
              BULK COLLECT INTO lv_zlocation_list
              FROM (  SELECT DISTINCT ZCODE, THEATER_ID
                        FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER
                       WHERE     ZCODE IS NOT NULL
                             AND ACTIVE_FLAG = 'Y'
                             AND ZCODE <> 'Z32'
                    ORDER BY ZCODE);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_zlocation_list := RC_ZLOCATION_LIST ();
        END;

        BEGIN
            SELECT RC_SUB_INV_LOCATION_OBJ (SUB_INVENTORY_ID,
                                            SUB_INVENTORY_LOCATION,
                                            REFRESH_METHOD_ID,
                                            PROGRAM_TYPE)
              BULK COLLECT INTO lv_sub_inv_location_list
              FROM (SELECT MSTR.SUB_INVENTORY_ID,
                           MSTR.SUB_INVENTORY_LOCATION,
                           FLG.REFRESH_METHOD_ID,
                           MSTR.PROGRAM_TYPE
                      FROM CRPADM.RC_SUB_INV_LOC_MSTR  MSTR
                           INNER JOIN CRPADM.RC_SUB_INV_LOC_FLG_DTLS FLG
                               ON     MSTR.SUB_INVENTORY_ID =
                                      FLG.SUB_INVENTORY_ID
                                  AND FLG.REFRESH_METHOD_ID IN (1, 2, 3)
                                  AND MSTR.PROGRAM_TYPE IN (0, 1)
                                  AND MSTR.INVENTORY_TYPE IN (1, 2)
                                  AND MSTR.NETTABLE_FLAG IN (0, 1));
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_sub_inv_location_list := RC_SUB_INV_LOCATION_LIST ();
        END;

        BEGIN
            SELECT RC_INV_THEATER_OBJ (CONFIG_NAME, CONFIG_ID)
              BULK COLLECT INTO lv_program_type_list
              FROM (SELECT CONFIG_NAME, CONFIG_ID
                      FROM CRPADM.RC_PRODUCT_CONFIG
                     WHERE     CONFIG_TYPE = 'PROGRAM_TYPE'
                           AND CONFIG_ID IN (0, 1));
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_program_type_list := RC_INV_THEATER_LIST ();
        END;

        o_refresh_method_list := lv_refresh_method_list;
        o_theater_list := lv_theater_list;
        o_zlocation_list := lv_zlocation_list;
        o_sub_inv_location_list := lv_sub_inv_location_list;
        o_program_type_list := lv_program_type_list;
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
                'CRPSC.RC_INVENTORY_TRANSFER.RC_FETCH_INV_SETUP_DROPDOWNS',
                'PROCEDURE',
                i_user_id,
                'N');
    END RC_FETCH_INV_SETUP_DROPDOWNS;

    /*-----------------------Procedure to fetch data for Inventory Transfer set up Details-------------------------------*/

    PROCEDURE RC_FETCH_INV_SETUP_DETAILS (
        i_user_id                      IN     VARCHAR2,
        i_src_zlocation                IN     VARCHAR2,
        i_dest_zlocation               IN     VARCHAR2,
        i_status                       IN     VARCHAR2,
        i_sort_column                  IN     VARCHAR2,
        i_sort_by                      IN     VARCHAR2,
        o_inventory_setup_rules_list      OUT RC_INVENTORY_SETUP_RULES_LIST)
    IS
        lv_inventory_setup_rules_list   RC_INVENTORY_SETUP_RULES_LIST;
        v_query                         VARCHAR2 (32767);
        v_main_query                    VARCHAR2 (32767);
        v_src_zlocation                 VARCHAR2 (100) DEFAULT NULL;
        v_dest_zlocation                VARCHAR2 (100) DEFAULT NULL;
        v_status                        VARCHAR2 (100) DEFAULT NULL;
        lv_sort_column                  VARCHAR2 (100);
        lv_sort_by                      VARCHAR2 (100);
        lv_user_id                      VARCHAR2 (100);
        lv_src_zlocation                VARCHAR2 (100);
        lv_dest_zlocation               VARCHAR2 (100);
        lv_status                       VARCHAR2 (2);
    BEGIN
        lv_inventory_setup_rules_list := RC_INVENTORY_SETUP_RULES_LIST ();
        o_inventory_setup_rules_list := RC_INVENTORY_SETUP_RULES_LIST ();
        lv_user_id := i_user_id;
        lv_src_zlocation := i_src_zlocation;
        lv_dest_zlocation := i_dest_zlocation;
        lv_status := i_status;
        lv_sort_column := i_sort_column;
        lv_sort_by := i_sort_by;

        v_main_query := 'SELECT INV_TRANSFER_SETUP_ID,
                     (SELECT CONFIG_NAME
                        FROM CRPADM.RC_PRODUCT_CONFIG
                       WHERE     CONFIG_ID = A.SOURCE_REGION
                             AND CONFIG_TYPE = ''THEATER'')
                        SOURCE_REGION,
                     (SELECT CONFIG_NAME
                        FROM CRPADM.RC_PRODUCT_CONFIG
                       WHERE     CONFIG_ID = A.SOURCE_REFRESH_METHOD
                             AND CONFIG_TYPE = ''REFRESH_METHOD'')
                        SOURCE_REFRESH_METHOD,
                     SOURCE_LOCATION_ZCODE,
                     (SELECT CONFIG_NAME
                        FROM CRPADM.RC_PRODUCT_CONFIG
                       WHERE     CONFIG_ID = A.DESTINATION_REGION
                             AND CONFIG_TYPE = ''THEATER'')
                        DESTINATION_REGION,
                     (SELECT CONFIG_NAME
                        FROM CRPADM.RC_PRODUCT_CONFIG
                       WHERE     CONFIG_ID = A.DESTINATION_REFRESH_METHOD
                             AND CONFIG_TYPE = ''REFRESH_METHOD'')
                        DESTINATION_REFRESH_METHOD,
                     DESTINATION_LOCATION_ZCODE,
                     SUB_INVENTORY_LOCATION,
                     CREATED_BY,
                     TO_CHAR(CREATED_ON,''DD-Mon-YYYY'') CREATED_ON,
                     UPDATED_BY,
                      TO_CHAR(UPDATED_ON,''DD-Mon-YYYY'') UPDATED_ON,
                     IS_ACTIVE,
                     (SELECT CONFIG_NAME
                        FROM CRPADM.RC_PRODUCT_CONFIG
                       WHERE     CONFIG_ID = A.PROGRAM_TYPE
                             AND CONFIG_TYPE = ''PROGRAM_TYPE'') PROGRAM_TYPE
                FROM RC_INV_TRANSFER_SETUP A where 1= 1';


        IF lv_src_zlocation IS NOT NULL
        THEN
            v_src_zlocation :=
                   ' AND A.SOURCE_LOCATION_ZCODE = '
                || ''''
                || lv_src_zlocation
                || '''';
            v_main_query := v_main_query || v_src_zlocation;
        END IF;

        IF lv_dest_zlocation IS NOT NULL
        THEN
            v_dest_zlocation :=
                   ' AND A.DESTINATION_LOCATION_ZCODE = '
                || ''''
                || lv_dest_zlocation
                || '''';
            v_main_query := v_main_query || v_dest_zlocation;
        END IF;

        IF lv_status IS NOT NULL
        THEN
            v_status := ' AND A.IS_ACTIVE = ' || '''' || lv_status || '''';
            v_main_query := v_main_query || v_status;
        END IF;


        v_query :=
            'SELECT RC_INVENTORY_SETUP_RULES_OBJ (INV_TRANSFER_SETUP_ID,
                                           SOURCE_REGION,
                                           SOURCE_REFRESH_METHOD,
                                           SOURCE_LOCATION_ZCODE,
                                           DESTINATION_REGION,
                                           DESTINATION_REFRESH_METHOD,
                                           DESTINATION_LOCATION_ZCODE,
                                           SUB_INVENTORY_LOCATION,
                                           CREATED_BY,
                                           CREATED_ON,
                                           UPDATED_BY,
                                           UPDATED_ON,
                                           IS_ACTIVE,
                                           PROGRAM_TYPE)
        FROM (' || v_main_query || ')';



        IF (i_sort_column IS NOT NULL AND i_sort_by IS NOT NULL)
        THEN
            v_query :=
                v_query || ' ORDER BY ' || i_sort_column || ' ' || i_sort_by;
        END IF;


        EXECUTE IMMEDIATE v_query
            BULK COLLECT INTO lv_inventory_setup_rules_list;

        o_inventory_setup_rules_list := lv_inventory_setup_rules_list;
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
                'CRPSC.RC_INVENTORY_TRANSFER.RC_FETCH_INV_SETUP_DETAILS',
                'PROCEDURE',
                lv_user_id,
                'N');
    END RC_FETCH_INV_SETUP_DETAILS;

    /*-----------------------Procedure to INSERT data for Inventory Transfer set up Details-------------------------------*/

    PROCEDURE RC_ADD_INV_SETUP_DETAILS (
        i_user_id                      IN     VARCHAR2,
        i_src_zlocation                IN     VARCHAR2,
        i_dest_zlocation               IN     VARCHAR2,
        i_status                       IN     VARCHAR2,
        i_inventory_setup_rules_list   IN     RC_INVENTORY_SETUP_RULES_LIST,
        o_inventory_setup_rules_list      OUT RC_INVENTORY_SETUP_RULES_LIST)
    IS
        lv_inventory_setup_rules_list   RC_INVENTORY_SETUP_RULES_LIST;
        lv_i_inv_setup_rules_list       RC_INVENTORY_SETUP_RULES_LIST;
        lv_COUNT                        NUMBER;
        lv_user_id                      VARCHAR2 (100);
        lv_src_zlocation                VARCHAR2 (100);
        lv_dest_zlocation               VARCHAR2 (100);
        lv_status                       VARCHAR2 (2);
        lv_sort_column                  VARCHAR2 (2);
        lv_sort_by                      VARCHAR2 (2);
    BEGIN
        lv_inventory_setup_rules_list := RC_INVENTORY_SETUP_RULES_LIST ();
        o_inventory_setup_rules_list := RC_INVENTORY_SETUP_RULES_LIST ();
        lv_i_inv_setup_rules_list := RC_INVENTORY_SETUP_RULES_LIST ();
        lv_i_inv_setup_rules_list := i_inventory_setup_rules_list;
        lv_user_id := i_user_id;
        lv_src_zlocation := i_src_zlocation;
        lv_dest_zlocation := i_dest_zlocation;
        lv_status := i_status;
        lv_sort_column := NULL;
        lv_sort_by := NULL;

        FOR idx IN 1 .. lv_i_inv_setup_rules_list.COUNT
        LOOP
            SELECT COUNT (*)
              INTO lv_COUNT
              FROM RC_INV_TRANSFER_SETUP
             WHERE     SOURCE_REGION =
                       TO_NUMBER (
                           lv_i_inv_setup_rules_list (idx).SOURCE_REGION)
                   AND SOURCE_REFRESH_METHOD =
                       TO_NUMBER (
                           lv_i_inv_setup_rules_list (idx).SOURCE_REFRESH_METHOD)
                   AND SOURCE_LOCATION_ZCODE =
                       lv_i_inv_setup_rules_list (idx).SOURCE_LOCATION_ZCODE
                   AND DESTINATION_REGION =
                       TO_NUMBER (
                           lv_i_inv_setup_rules_list (idx).DESTINATION_REGION)
                   AND DESTINATION_REFRESH_METHOD =
                       TO_NUMBER (
                           lv_i_inv_setup_rules_list (idx).DESTINATION_REFRESH_METHOD)
                   AND DESTINATION_LOCATION_ZCODE =
                       lv_i_inv_setup_rules_list (idx).DESTINATION_LOCATION_ZCODE
                   AND SUB_INVENTORY_LOCATION =
                       lv_i_inv_setup_rules_list (idx).SUB_INVENTORY_LOCATION
                   AND PROGRAM_TYPE =
                       TO_NUMBER (
                           lv_i_inv_setup_rules_list (idx).PROGRAM_TYPE);


            IF (lv_COUNT = 0)
            THEN
                INSERT INTO RC_INV_TRANSFER_SETUP (
                                INV_TRANSFER_SETUP_ID,
                                SOURCE_REGION,
                                SOURCE_REFRESH_METHOD,
                                SOURCE_LOCATION_ZCODE,
                                DESTINATION_REGION,
                                DESTINATION_REFRESH_METHOD,
                                DESTINATION_LOCATION_ZCODE,
                                SUB_INVENTORY_LOCATION,
                                CREATED_BY,
                                CREATED_ON,
                                IS_ACTIVE,
                                PROGRAM_TYPE)
                         VALUES (
                                    CRPSC.INV_TRANSFER_SEQ.NEXTVAL,
                                    TO_NUMBER (
                                        lv_i_inv_setup_rules_list (idx).SOURCE_REGION),
                                    TO_NUMBER (
                                        lv_i_inv_setup_rules_list (idx).SOURCE_REFRESH_METHOD),
                                    lv_i_inv_setup_rules_list (idx).SOURCE_LOCATION_ZCODE,
                                    TO_NUMBER (
                                        lv_i_inv_setup_rules_list (idx).DESTINATION_REGION),
                                    TO_NUMBER (
                                        lv_i_inv_setup_rules_list (idx).DESTINATION_REFRESH_METHOD),
                                    lv_i_inv_setup_rules_list (idx).DESTINATION_LOCATION_ZCODE,
                                    lv_i_inv_setup_rules_list (idx).SUB_INVENTORY_LOCATION,
                                    lv_user_id,
                                    SYSDATE,
                                    'Y',
                                    TO_NUMBER (
                                        lv_i_inv_setup_rules_list (idx).PROGRAM_TYPE));

                COMMIT;


                RC_FETCH_INV_SETUP_DETAILS (lv_user_id,
                                            lv_src_zlocation,
                                            lv_dest_zlocation,
                                            lv_status,
                                            lv_sort_column,
                                            lv_sort_by,
                                            lv_inventory_setup_rules_list);
            END IF;
        END LOOP;

        o_inventory_setup_rules_list := lv_inventory_setup_rules_list;
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
                'CRPSC.RC_INVENTORY_TRANSFER.RC_ADD_INV_SETUP_DETAILS',
                'PROCEDURE',
                lv_user_id,
                'N');
    END RC_ADD_INV_SETUP_DETAILS;


    /*-----------------------Procedure to UPDATE data for Inventory Transfer set up Details-------------------------------*/

    PROCEDURE RC_UPDATE_INV_SETUP_DETAILS (
        i_user_id                      IN     VARCHAR2,
        i_src_zlocation                IN     VARCHAR2,
        i_dest_zlocation               IN     VARCHAR2,
        i_status                       IN     VARCHAR2,
        i_inventory_setup_rules_list   IN     RC_INVENTORY_SETUP_RULES_LIST,
        o_inventory_setup_rules_list      OUT RC_INVENTORY_SETUP_RULES_LIST)
    IS
        lv_inventory_setup_rules_list   RC_INVENTORY_SETUP_RULES_LIST;
        lv_i_inv_setup_rules_list       RC_INVENTORY_SETUP_RULES_LIST;
        lv_src_zlocation                VARCHAR2 (100);
        lv_dest_zlocation               VARCHAR2 (100);
        lv_status                       VARCHAR2 (2);
        lv_user_id                      VARCHAR2 (100);
        lv_sort_column                  VARCHAR2 (2);
        lv_sort_by                      VARCHAR2 (2);
    BEGIN
        lv_inventory_setup_rules_list := RC_INVENTORY_SETUP_RULES_LIST ();
        o_inventory_setup_rules_list := RC_INVENTORY_SETUP_RULES_LIST ();
        lv_i_inv_setup_rules_list := RC_INVENTORY_SETUP_RULES_LIST ();
        lv_i_inv_setup_rules_list := i_inventory_setup_rules_list;
        lv_user_id := i_user_id;
        lv_src_zlocation := i_src_zlocation;
        lv_dest_zlocation := i_dest_zlocation;
        lv_status := i_status;
        lv_sort_column := NULL;
        lv_sort_by := NULL;

        FOR idx IN 1 .. lv_i_inv_setup_rules_list.COUNT
        LOOP
            UPDATE RC_INV_TRANSFER_SETUP
               SET SOURCE_REGION =
                       (CASE
                            WHEN lv_i_inv_setup_rules_list (idx).SOURCE_REGION
                                     IS NOT NULL
                            THEN
                                TO_NUMBER (
                                    lv_i_inv_setup_rules_list (idx).SOURCE_REGION)
                            ELSE
                                SOURCE_REGION
                        END),
                   SOURCE_REFRESH_METHOD =
                       (CASE
                            WHEN lv_i_inv_setup_rules_list (idx).SOURCE_REFRESH_METHOD
                                     IS NOT NULL
                            THEN
                                TO_NUMBER (
                                    lv_i_inv_setup_rules_list (idx).SOURCE_REFRESH_METHOD)
                            ELSE
                                SOURCE_REFRESH_METHOD
                        END),
                   SOURCE_LOCATION_ZCODE =
                       (CASE
                            WHEN lv_i_inv_setup_rules_list (idx).SOURCE_LOCATION_ZCODE
                                     IS NOT NULL
                            THEN
                                lv_i_inv_setup_rules_list (idx).SOURCE_LOCATION_ZCODE
                            ELSE
                                SOURCE_LOCATION_ZCODE
                        END),
                   DESTINATION_REGION =
                       (CASE
                            WHEN lv_i_inv_setup_rules_list (idx).DESTINATION_REGION
                                     IS NOT NULL
                            THEN
                                TO_NUMBER (
                                    lv_i_inv_setup_rules_list (idx).DESTINATION_REGION)
                            ELSE
                                DESTINATION_REGION
                        END),
                   DESTINATION_REFRESH_METHOD =
                       (CASE
                            WHEN lv_i_inv_setup_rules_list (idx).DESTINATION_REFRESH_METHOD
                                     IS NOT NULL
                            THEN
                                TO_NUMBER (
                                    lv_i_inv_setup_rules_list (idx).DESTINATION_REFRESH_METHOD)
                            ELSE
                                DESTINATION_REFRESH_METHOD
                        END),
                   DESTINATION_LOCATION_ZCODE =
                       (CASE
                            WHEN lv_i_inv_setup_rules_list (idx).DESTINATION_LOCATION_ZCODE
                                     IS NOT NULL
                            THEN
                                lv_i_inv_setup_rules_list (idx).DESTINATION_LOCATION_ZCODE
                            ELSE
                                DESTINATION_LOCATION_ZCODE
                        END),
                   SUB_INVENTORY_LOCATION =
                       (CASE
                            WHEN lv_i_inv_setup_rules_list (idx).SUB_INVENTORY_LOCATION
                                     IS NOT NULL
                            THEN
                                lv_i_inv_setup_rules_list (idx).SUB_INVENTORY_LOCATION
                            ELSE
                                SUB_INVENTORY_LOCATION
                        END),
                   UPDATED_BY =
                       (CASE
                            WHEN lv_i_inv_setup_rules_list (idx).UPDATED_BY
                                     IS NOT NULL
                            THEN
                                lv_i_inv_setup_rules_list (idx).UPDATED_BY
                            ELSE
                                UPDATED_BY
                        END),
                   UPDATED_ON = SYSDATE,
                   IS_ACTIVE =
                       (CASE
                            WHEN lv_i_inv_setup_rules_list (idx).IS_ACTIVE
                                     IS NOT NULL
                            THEN
                                lv_i_inv_setup_rules_list (idx).IS_ACTIVE
                            ELSE
                                IS_ACTIVE
                        END),
                   PROGRAM_TYPE =
                       (CASE
                            WHEN lv_i_inv_setup_rules_list (idx).PROGRAM_TYPE
                                     IS NOT NULL
                            THEN
                                TO_NUMBER (
                                    lv_i_inv_setup_rules_list (idx).PROGRAM_TYPE)
                            ELSE
                                PROGRAM_TYPE
                        END)
             WHERE INV_TRANSFER_SETUP_ID =
                   lv_i_inv_setup_rules_list (idx).INV_TRANSFER_SETUP_ID;
        END LOOP;

        COMMIT;

        RC_FETCH_INV_SETUP_DETAILS (lv_user_id,
                                    lv_src_zlocation,
                                    lv_dest_zlocation,
                                    lv_status,
                                    lv_sort_column,
                                    lv_sort_by,
                                    lv_inventory_setup_rules_list);

        o_inventory_setup_rules_list := lv_inventory_setup_rules_list;
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
                'CRPSC.RC_INVENTORY_TRANSFER.RC_UPDATE_INV_SETUP_DETAILS',
                'PROCEDURE',
                lv_user_id,
                'N');
    END RC_UPDATE_INV_SETUP_DETAILS;


    /*-----------------------Procedure to FETCH data for Inventory Transfer Report Details with column level filters and sorting-------------------------------*/

    PROCEDURE RC_FETCH_INV_RPT_DETAILS (
        i_user_id                       IN     VARCHAR2,
        i_product                       IN     VARCHAR2,
        i_src_zlocation                 IN     VARCHAR2,
        i_dest_zlocation                IN     VARCHAR2,
        i_sub_inv_location              IN     VARCHAR2,
        i_min                           IN     NUMBER,
        i_max                           IN     NUMBER,
        i_filter_column_name            IN     VARCHAR2,
        i_filter_user_input             IN     VARCHAR2,
        i_sort_column_name              IN     VARCHAR2,
        i_sort_column_by                IN     VARCHAR2,
        i_filter_list                   IN     RC_FILTER_LIST,
        o_inventory_transfer_rpt_list      OUT RC_INVENTORY_TRANSFER_RPT_LIST,
        o_total_row_count                  OUT NUMBER,
        o_last_refreshed_msg               OUT VARCHAR2,
        o_date                             OUT TIMESTAMP)
    IS
        lv_user_id                       VARCHAR2 (50 BYTE);
        v_query                          VARCHAR2 (32767);
        v_main_query                     VARCHAR2 (32767);
        v_product                        VARCHAR2 (100) DEFAULT NULL;
        v_src_zlocation                  VARCHAR2 (100) DEFAULT NULL;
        v_dest_zlocation                 VARCHAR2 (100) DEFAULT NULL;
        v_sub_inv_location               VARCHAR2 (100) DEFAULT NULL;
        v_whereclause                    VARCHAR2 (32767) DEFAULT NULL;
        v_row_clause                     VARCHAR2 (200) DEFAULT NULL;
        lv_product                       VARCHAR2 (100);
        lv_src_zlocation                 VARCHAR2 (50);
        lv_dest_zlocation                VARCHAR2 (50);
        lv_sub_inv_location              VARCHAR2 (10);
        lv_max_row                       NUMBER;
        lv_min_row                       NUMBER;
        lv_total_row_count               NUMBER;
        lv_filter_column_name            VARCHAR2 (100);
        lv_filter_user_input             VARCHAR2 (100);
        lv_sort_column_name              VARCHAR2 (100);
        lv_sort_column_by                VARCHAR2 (100);
        lv_filter_value                  VARCHAR2 (1000);
        v_count_query                    VARCHAR2 (32767) DEFAULT NULL;
        lv_inventory_transfer_rpt_list   RC_INVENTORY_TRANSFER_RPT_LIST;
        lv_last_refreshed_msg            VARCHAR2 (100);
        lv_date                          TIMESTAMP;
    BEGIN
        lv_user_id := i_user_id;
        lv_product := i_product;
        lv_src_zlocation := i_src_zlocation;
        lv_dest_zlocation := i_dest_zlocation;
        lv_sub_inv_location := i_sub_inv_location;
        lv_inventory_transfer_rpt_list := RC_INVENTORY_TRANSFER_RPT_LIST ();
        o_inventory_transfer_rpt_list := RC_INVENTORY_TRANSFER_RPT_LIST ();
        lv_max_row := i_max;
        lv_min_row := i_min;
        lv_filter_column_name := UPPER (TRIM (i_filter_column_name));
        lv_filter_user_input := UPPER (TRIM (i_filter_user_input));
        lv_sort_column_name := UPPER (TRIM (i_sort_column_name));
        lv_sort_column_by := UPPER (TRIM (i_sort_column_by));

        v_count_query :=
            'SELECT  count(*)
         FROM RC_INVENTORY_TRANSFER_TBL A, CRPADM.RC_PRODUCT_MASTER B                    
          WHERE A.REFRESH_INVENTORY_ITEM_ID = B.REFRESH_INVENTORY_ITEM_ID ';

        v_main_query := ' SELECT REFRESH_INVENTORY_ITEM_ID,
               REFRESH_PART_NUMBER,
               C3_PART_NUMBER,
--               MLC3.INVENTORY_ITEM_ID INVENTORY_ITEM_ID,
--               MLC3.PART_NUMBER PART_NUMBER,
               SOURCE_LOCATION_ZCODE,
               DESTINATION_LOCATION_ZCODE,
               SUB_INVENTORY_LOCATION,
               C3_ONHAND_DGI FROM ( SELECT A.REFRESH_INVENTORY_ITEM_ID,
               CASE
          WHEN A.C3_INVENTORY_ITEM_ID = B.COMMON_INVENTORY_ITEM_ID
          THEN
             COMMON_PART_NUMBER
          WHEN A.C3_INVENTORY_ITEM_ID = B.XREF_INVENTORY_ITEM_ID
          THEN
             XREF_PART_NUMBER
       END C3_PART_NUMBER,
               B.REFRESH_PART_NUMBER,
               A.SOURCE_LOCATION_ZCODE,
               A.DESTINATION_LOCATION_ZCODE,
               A.SUB_INVENTORY_LOCATION,
               A.C3_ONHAND_DGI';

        --           ROWNUM RNUM
        --          FROM RC_INVENTORY_TRANSFER_TBL A, RC_PRODUCT_MASTER B
        --          WHERE A.REFRESH_INVENTORY_ITEM_ID = B.REFRESH_INVENTORY_ITEM_ID ';

        CASE
            WHEN lv_sort_column_name = 'REFRESHPARTNUMBER'
            THEN
                lv_sort_column_name := 'REFRESH_PART_NUMBER';
            WHEN lv_sort_column_name = 'SOURCELOCATIONZCODE'
            THEN
                lv_sort_column_name := 'SOURCE_LOCATION_ZCODE';
            WHEN lv_sort_column_name = 'DESTINATIONLOCATIONZCODE'
            THEN
                lv_sort_column_name := 'DESTINATION_LOCATION_ZCODE';
            WHEN lv_sort_column_name = 'SUBINVENTORYLOCATION'
            THEN
                lv_sort_column_name := 'SUB_INVENTORY_LOCATION';
            WHEN lv_sort_column_name = 'C3ONHANDDGI'
            THEN
                lv_sort_column_name := 'C3_ONHAND_DGI';
            ELSE
                lv_sort_column_name := '';
        END CASE;

        CASE
            WHEN lv_filter_column_name = 'REFRESHPARTNUMBER'
            THEN
                lv_filter_column_name := 'REFRESH_PART_NUMBER';
            WHEN lv_filter_column_name = 'SOURCELOCATIONZCODE'
            THEN
                lv_filter_column_name := 'SOURCE_LOCATION_ZCODE';
            WHEN lv_filter_column_name = 'DESTINATIONLOCATIONZCODE'
            THEN
                lv_filter_column_name := 'DESTINATION_LOCATION_ZCODE';
            WHEN lv_filter_column_name = 'SUBINVENTORYLOCATION'
            THEN
                lv_filter_column_name := 'SUB_INVENTORY_LOCATION';
            WHEN lv_filter_column_name = 'C3ONHANDDGI'
            THEN
                lv_filter_column_name := 'C3_ONHAND_DGI';
            ELSE
                lv_filter_column_name := '';
        END CASE;

        -- Code for adding the ROW_NUMBER()  OVER or ROWNUM based on whether the sorting is applied or not
        IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
        THEN
            v_main_query :=
                   v_main_query
                || ', ROW_NUMBER()  OVER (ORDER BY '
                || lv_sort_column_name
                || ' '
                || lv_sort_column_by
                || ' ) AS RNUM  FROM RC_INVENTORY_TRANSFER_TBL A
       JOIN CRPADM.rc_product_master B
          ON A.refresh_inventory_item_id =
                B.refresh_inventory_item_id
         ';
        ELSE
            v_main_query := v_main_query || ', ROWNUM RNUM
                     FROM RC_INVENTORY_TRANSFER_TBL A
       JOIN CRPADM.rc_product_master B
          ON A.refresh_inventory_item_id =
                B.refresh_inventory_item_id';
        END IF;


        IF lv_product IS NOT NULL
        THEN
            v_product :=
                   '  AND B.REFRESH_PART_NUMBER = '
                || ''''
                || lv_product
                || '''';
            v_main_query := v_main_query || v_product;
        END IF;

        IF lv_src_zlocation IS NOT NULL
        THEN
            v_src_zlocation :=
                   '  AND A.SOURCE_LOCATION_ZCODE = '
                || ''''
                || lv_src_zlocation
                || '''';
            v_main_query := v_main_query || v_src_zlocation;
        END IF;

        IF lv_dest_zlocation IS NOT NULL
        THEN
            v_dest_zlocation :=
                   '  AND A.DESTINATION_LOCATION_ZCODE = '
                || ''''
                || lv_dest_zlocation
                || '''';
            v_main_query := v_main_query || v_dest_zlocation;
        END IF;

        IF lv_sub_inv_location IS NOT NULL
        THEN
            v_sub_inv_location :=
                   '  AND A.SUB_INVENTORY_LOCATION = '
                || ''''
                || lv_sub_inv_location
                || '''';
            v_main_query := v_main_query || v_sub_inv_location;
        END IF;

        -- For Column Level Filtering based on the user input
        IF     lv_filter_column_name IS NOT NULL
           AND lv_filter_user_input IS NOT NULL
        THEN
            v_main_query :=
                   v_main_query
                || ' AND (UPPER(TRIM('
                || lv_filter_column_name
                || ')) LIKE (UPPER(TRIM(''%'
                || lv_filter_user_input
                || '%''))))';
            v_count_query :=
                   v_count_query
                || ' AND (UPPER(TRIM('
                || lv_filter_column_name
                || ')) LIKE (UPPER(TRIM(''%'
                || lv_filter_user_input
                || '%''))))';
        END IF;

        -- For Column Level Filter with user selected checkboxes
        IF lv_filter_column_name IS NOT NULL
        THEN
            IF i_filter_list IS NOT EMPTY
            THEN
                FOR IDX IN 1 .. i_filter_list.COUNT ()
                LOOP
                    IF idx = 1
                    THEN
                        IF     (i_filter_list (idx).FILTER IS NOT NULL)
                           AND (i_filter_list (idx).FILTER NOT LIKE ' ')
                        THEN
                            lv_filter_value :=
                                UPPER (
                                    TO_CHAR (
                                        TRIM (i_filter_list (idx).FILTER)));


                            v_main_query :=
                                   v_main_query
                                || ' AND ((UPPER(TRIM('
                                || lv_filter_column_name
                                || ')) LIKE (UPPER(TRIM(''%'
                                || lv_filter_value
                                || '%''))))';
                            v_count_query :=
                                   v_count_query
                                || ' AND ((UPPER(TRIM('
                                || lv_filter_column_name
                                || ')) LIKE (UPPER(TRIM(''%'
                                || lv_filter_value
                                || '%''))))';
                        END IF;
                    ELSIF     (i_filter_list (idx).FILTER IS NOT NULL)
                          AND (i_filter_list (idx).FILTER NOT LIKE ' ')
                    THEN
                        lv_filter_value :=
                            UPPER (
                                TO_CHAR (TRIM (i_filter_list (idx).FILTER)));

                        v_main_query :=
                               v_main_query
                            || ' OR (UPPER(TRIM('
                            || lv_filter_column_name
                            || ')) LIKE (UPPER(TRIM(''%'
                            || lv_filter_value
                            || '%''))))';

                        v_count_query :=
                               v_count_query
                            || ' OR (UPPER(TRIM('
                            || lv_filter_column_name
                            || ')) LIKE (UPPER(TRIM(''%'
                            || lv_filter_value
                            || '%''))))';
                    END IF;
                END LOOP;

                v_count_query := v_count_query || ')';
                v_main_query := v_main_query || ')';
            END IF;
        END IF;

        -- For Sorting based on the user selection
        IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
        THEN
            -- For getting the limited set of data based on the min and max values
            v_row_clause :=
                   ' ) WHERE RNUM >'
                || lv_min_row
                || ' AND RNUM <='
                || lv_max_row;

            v_main_query :=
                   v_main_query
                || ' ORDER BY '
                || lv_sort_column_name
                || ' '
                || lv_sort_column_by;
        ELSE
            -- For getting the limited set of data based on the min and max values
            v_row_clause :=
                   ' ) WHERE RNUM >'
                || lv_min_row
                || ' AND RNUM <='
                || lv_max_row;

            v_main_query :=
                v_main_query || ' ORDER BY REFRESH_INVENTORY_ITEM_ID';
        END IF;

        v_whereclause :=
               v_product
            || v_src_zlocation
            || v_dest_zlocation
            || v_sub_inv_location;


        --      v_row_clause :=
        --         ' ) WHERE RNUM <= ' || lv_max_row || ' AND RNUM >' || lv_min_row;

        v_main_query := v_main_query || v_row_clause;

        v_query :=
               'SELECT RC_INVENTORY_TRANSFER_RPT_OBJ (REFRESH_INVENTORY_ITEM_ID,
                                      REFRESH_PART_NUMBER,
                                      C3_PART_NUMBER,
--                                      INVENTORY_ITEM_ID,
--                                      PART_NUMBER,
                                      SOURCE_LOCATION_ZCODE,
                                      DESTINATION_LOCATION_ZCODE,
                                      SUB_INVENTORY_LOCATION,
                                      C3_ONHAND_DGI)
        FROM ('
            || v_main_query
            || ')';

        v_count_query := v_count_query || v_whereclause;



        BEGIN
            EXECUTE IMMEDIATE v_count_query INTO lv_total_row_count;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_total_row_count := 0;
        END;

        BEGIN
            EXECUTE IMMEDIATE v_query
                BULK COLLECT INTO lv_inventory_transfer_rpt_list;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_inventory_transfer_rpt_list :=
                    RC_INVENTORY_TRANSFER_RPT_LIST ();
        END;


        BEGIN
            SELECT MAX (TIME_STAMP)
              INTO lv_date
              FROM CRPADM.RC_JOBS_NOTIFICATION_HISTORY
             WHERE     NOTIFICATION_ID = 4
                   AND UPPER (STATUS) = UPPER ('successful');

            lv_last_refreshed_msg :=
                'Inventory Transfer List is generated on ' || lv_date;

            o_date := lv_date;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_last_refreshed_msg :=
                    'No successful execution of the Inventory Transfer Engine';
        END;

        o_total_row_count := lv_total_row_count;
        o_inventory_transfer_rpt_list := lv_inventory_transfer_rpt_list;
        o_last_refreshed_msg := lv_last_refreshed_msg;
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
                'CRPSC.RC_INVENTORY_TRANSFER.RC_FETCH_INV_RPT_DETAILS',
                'PROCEDURE',
                lv_user_id,
                'N');
    END RC_FETCH_INV_RPT_DETAILS;

    PROCEDURE RC_FETCH_INV_RPT_DTLS_FILTER (
        i_user_id                       IN     VARCHAR2,
        i_product                       IN     VARCHAR2,
        i_src_zlocation                 IN     VARCHAR2,
        i_dest_zlocation                IN     VARCHAR2,
        i_sub_inv_location              IN     VARCHAR2,
        i_min                           IN     NUMBER,
        i_max                           IN     NUMBER,
        i_filter_column_name            IN     VARCHAR2,
        i_filter_user_input             IN     VARCHAR2,
        i_sort_column_name              IN     VARCHAR2,
        i_sort_column_by                IN     VARCHAR2,
        i_filter_list                   IN     RC_NEW_FILTER_OBJ_LIST,
        o_inventory_transfer_rpt_list      OUT RC_INVENTORY_TRANSFER_RPT_LIST,
        o_total_row_count                  OUT NUMBER,
        o_last_refreshed_msg               OUT VARCHAR2,
        o_date                             OUT TIMESTAMP)
    IS
        lv_user_id                       VARCHAR2 (50 BYTE);
        v_query                          VARCHAR2 (32767);
        v_main_query                     CLOB;             --VARCHAR2 (32767);
        v_product                        VARCHAR2 (32767) DEFAULT NULL;
        v_c3_product                     VARCHAR2 (32767) DEFAULT NULL;
        v_src_zlocation                  VARCHAR2 (100) DEFAULT NULL;
        v_dest_zlocation                 VARCHAR2 (100) DEFAULT NULL;
        v_sub_inv_location               VARCHAR2 (100) DEFAULT NULL;
        v_whereclause                    VARCHAR2 (32767) DEFAULT NULL;
        v_row_clause                     VARCHAR2 (200) DEFAULT NULL;
        lv_product                       VARCHAR2 (32767);
        lv_src_zlocation                 VARCHAR2 (50);
        lv_dest_zlocation                VARCHAR2 (50);
        lv_sub_inv_location              VARCHAR2 (10);
        lv_max_row                       NUMBER;
        lv_min_row                       NUMBER;
        lv_total_row_count               NUMBER;
        lv_filter_column_name            VARCHAR2 (100);
        lv_filter_column                 VARCHAR2 (100);
        lv_filter_user_input             VARCHAR2 (100);
        lv_sort_column_name              VARCHAR2 (100);
        lv_sort_column_name_C3           VARCHAR2 (100);
        lv_sort_column_by                VARCHAR2 (100);
        lv_filter_value                  VARCHAR2 (1000);
        v_count_query                    CLOB; --VARCHAR2 (32767) DEFAULT NULL;
        v_outer_query                    VARCHAR2 (32767) DEFAULT NULL;
        lv_inventory_transfer_rpt_list   RC_INVENTORY_TRANSFER_RPT_LIST;
        lv_last_refreshed_msg            VARCHAR2 (100);
        lv_date                          TIMESTAMP;
        lv_date1                         VARCHAR2 (100);
        lv_filter_data_list              RC_FILTER_DATA_OBJ_LIST;
        lv_null_query                    VARCHAR2 (32767);
        lv_in_query                      CLOB;
        lv_pos                           NUMBER;
        lv_fav_data                      VARCHAR2 (100);
    BEGIN
        lv_user_id := i_user_id;
        lv_product := i_product;
        lv_src_zlocation := i_src_zlocation;
        lv_dest_zlocation := i_dest_zlocation;
        lv_sub_inv_location := i_sub_inv_location;
        lv_inventory_transfer_rpt_list := RC_INVENTORY_TRANSFER_RPT_LIST ();
        o_inventory_transfer_rpt_list := RC_INVENTORY_TRANSFER_RPT_LIST ();
        lv_max_row := i_max;
        lv_min_row := i_min;
        lv_filter_column := UPPER (TRIM (i_filter_column_name));
        lv_filter_user_input := UPPER (TRIM (i_filter_user_input));
        lv_sort_column_name := UPPER (TRIM (i_sort_column_name));
        lv_sort_column_by := UPPER (TRIM (i_sort_column_by));

        v_count_query :=
            'SELECT COUNT (*)
               FROM (SELECT REFRESH_INVENTORY_ITEM_ID,
               REFRESH_PART_NUMBER,
               C3_PART_NUMBER,
               SOURCE_LOCATION_ZCODE,
               DESTINATION_LOCATION_ZCODE,
               SUB_INVENTORY_LOCATION,
               C3_ONHAND_DGI,
               QTY_TO_TRANSFER
          FROM (SELECT A.REFRESH_INVENTORY_ITEM_ID,
                       CASE
                          WHEN A.C3_INVENTORY_ITEM_ID =
                                  B.COMMON_INVENTORY_ITEM_ID
                          THEN
                             COMMON_PART_NUMBER
                          WHEN A.C3_INVENTORY_ITEM_ID =
                                  B.XREF_INVENTORY_ITEM_ID
                          THEN
                             XREF_PART_NUMBER
                       END
                          C3_PART_NUMBER,
                       B.REFRESH_PART_NUMBER,
                       A.SOURCE_LOCATION_ZCODE,
                       A.DESTINATION_LOCATION_ZCODE,
                       A.SUB_INVENTORY_LOCATION,
                       A.C3_ONHAND_DGI,
                       A.QTY_TO_TRANSFER
                  FROM RC_INVENTORY_TRANSFER_TBL A
                       JOIN CRPADM.RC_PRODUCT_MASTER B
                          ON A.REFRESH_INVENTORY_ITEM_ID =
                                B.REFRESH_INVENTORY_ITEM_ID) WHERE C3_ONHAND_DGI > 0) WHERE 1 = 1';

        v_outer_query := 'SELECT REFRESH_INVENTORY_ITEM_ID,
       REFRESH_PART_NUMBER,
       C3_PART_NUMBER,
       SOURCE_LOCATION_ZCODE,
       DESTINATION_LOCATION_ZCODE,
       SUB_INVENTORY_LOCATION,
       C3_ONHAND_DGI,
       QTY_TO_TRANSFER,
               rnum
       
  FROM (  SELECT REFRESH_INVENTORY_ITEM_ID,
                 REFRESH_PART_NUMBER,
                 C3_PART_NUMBER,
                 SOURCE_LOCATION_ZCODE,
                 DESTINATION_LOCATION_ZCODE,
                 SUB_INVENTORY_LOCATION,
                 C3_ONHAND_DGI,QTY_TO_TRANSFER';
        v_main_query :=
            ' SELECT A.REFRESH_INVENTORY_ITEM_ID,
               CASE
          WHEN A.C3_INVENTORY_ITEM_ID = B.COMMON_INVENTORY_ITEM_ID
          THEN
             COMMON_PART_NUMBER
          WHEN A.C3_INVENTORY_ITEM_ID = B.XREF_INVENTORY_ITEM_ID
          THEN
             XREF_PART_NUMBER
       END C3_PART_NUMBER,
               B.REFRESH_PART_NUMBER,
               A.SOURCE_LOCATION_ZCODE,
               A.DESTINATION_LOCATION_ZCODE,
               A.SUB_INVENTORY_LOCATION,
               A.C3_ONHAND_DGI,
               A.QTY_TO_TRANSFER
               FROM RC_INVENTORY_TRANSFER_TBL A
                         JOIN CRPADM.rc_product_master B
                            ON A.refresh_inventory_item_id =
                                  B.refresh_inventory_item_id WHERE A.C3_ONHAND_DGI > 0';

        CASE
            WHEN lv_sort_column_name = 'REFRESHPARTNUMBER'
            THEN
                lv_sort_column_name := 'REFRESH_PART_NUMBER';
            WHEN lv_sort_column_name = 'C3PARTNUMBER'
            THEN
                lv_sort_column_name := 'C3_PART_NUMBER';
            WHEN lv_sort_column_name = 'SOURCELOCATIONZCODE'
            THEN
                lv_sort_column_name := 'SOURCE_LOCATION_ZCODE';
            WHEN lv_sort_column_name = 'DESTINATIONLOCATIONZCODE'
            THEN
                lv_sort_column_name := 'DESTINATION_LOCATION_ZCODE';
            WHEN lv_sort_column_name = 'SUBINVENTORYLOCATION'
            THEN
                lv_sort_column_name := 'SUB_INVENTORY_LOCATION';
            WHEN lv_sort_column_name = 'C3ONHANDDGI'
            THEN
                lv_sort_column_name := 'C3_ONHAND_DGI';
            WHEN lv_sort_column_name = 'QTYTOTRANSFER'
            THEN
                lv_sort_column_name := 'QTY_TO_TRANSFER';
            ELSE
                lv_sort_column_name := '';
        END CASE;


        CASE
            WHEN lv_filter_column = 'REFRESHPARTNUMBER'
            THEN
                lv_filter_column := 'REFRESH_PART_NUMBER';
            WHEN lv_filter_column = 'C3PARTNUMBER'
            THEN
                lv_filter_column := 'C3_PART_NUMBER';
            WHEN lv_filter_column = 'SOURCELOCATIONZCODE'
            THEN
                lv_filter_column := 'SOURCE_LOCATION_ZCODE';
            WHEN lv_filter_column = 'DESTINATIONLOCATIONZCODE'
            THEN
                lv_filter_column := 'DESTINATION_LOCATION_ZCODE';
            WHEN lv_filter_column = 'SUBINVENTORYLOCATION'
            THEN
                lv_filter_column := 'SUB_INVENTORY_LOCATION';
            WHEN lv_filter_column = 'C3ONHANDDGI'
            THEN
                lv_filter_column := 'C3_ONHAND_DGI';
            WHEN lv_filter_column = 'QTYTOTRANSFER'
            THEN
                lv_filter_column := 'QTY_TO_TRANSFER';
            ELSE
                lv_filter_column := '';
        END CASE;



        IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
        THEN
            v_outer_query :=
                   v_outer_query
                || ', ROW_NUMBER()  OVER (ORDER BY '
                || lv_sort_column_name
                || ' '
                || lv_sort_column_by
                || ' ) AS RNUM  FROM ('
                || v_main_query
                || ') WHERE 1 = 1 ';
        ELSE
            v_outer_query :=
                v_outer_query || ', ROWNUM RNUM
                     FROM (' || v_main_query || ' ) WHERE 1 = 1 ';
        END IF;


        --      IF lv_product IS NOT NULL
        --      THEN
        --         v_product :=
        --            '  AND REFRESH_PART_NUMBER = ' || '''' || lv_product || '''';
        --         v_outer_query := v_outer_query || v_product;
        --      END IF;

        IF lv_product IS NOT NULL
        THEN
            v_product := ' AND ( REFRESH_PART_NUMBER IN (';
            v_c3_product := ' OR C3_PART_NUMBER IN ( ';

            WHILE lv_product IS NOT NULL
            LOOP
                lv_pos := INSTR (lv_product, ',');

                IF lv_pos = 0
                THEN
                    v_product := v_product || '''' || lv_product || ''')';
                    v_c3_product :=
                        v_c3_product || '''' || lv_product || ''')';
                    lv_product := NULL;
                ELSE
                    lv_fav_data := SUBSTR (lv_product, 1, lv_pos - 1);
                    lv_product := SUBSTR (lv_product, lv_pos + 1);
                    v_product :=
                        v_product || '''' || lv_fav_data || '''' || ',';
                    v_c3_product :=
                        v_c3_product || '''' || lv_fav_data || '''' || ',';
                END IF;
            END LOOP;

            v_product := v_product || v_c3_product || ' ) ';

            v_outer_query := v_outer_query || v_product;
        END IF;

        IF lv_src_zlocation IS NOT NULL
        THEN
            v_src_zlocation :=
                   '  AND SOURCE_LOCATION_ZCODE = '
                || ''''
                || lv_src_zlocation
                || '''';
            v_outer_query := v_outer_query || v_src_zlocation;
        END IF;

        IF lv_dest_zlocation IS NOT NULL
        THEN
            v_dest_zlocation :=
                   '  AND DESTINATION_LOCATION_ZCODE = '
                || ''''
                || lv_dest_zlocation
                || '''';
            v_outer_query := v_outer_query || v_dest_zlocation;
        END IF;

        IF lv_sub_inv_location IS NOT NULL
        THEN
            v_sub_inv_location :=
                   '  AND SUB_INVENTORY_LOCATION = '
                || ''''
                || lv_sub_inv_location
                || '''';
            v_outer_query := v_outer_query || v_sub_inv_location;
        END IF;

        -- For Column Level Filtering based on the user input
        IF lv_filter_column IS NOT NULL AND lv_filter_user_input IS NOT NULL
        THEN
            v_outer_query :=
                   v_outer_query
                || ' AND (UPPER(TRIM('
                || lv_filter_column
                || ')) LIKE (UPPER(TRIM(''%'
                || lv_filter_user_input
                || '%''))))';
            v_count_query :=
                   v_count_query
                || ' AND (UPPER(TRIM('
                || lv_filter_column
                || ')) LIKE (UPPER(TRIM(''%'
                || lv_filter_user_input
                || '%''))))';
        END IF;

        IF i_filter_list IS NOT EMPTY
        THEN
            GET_IN_CONDITION_FOR_QUERY (i_filter_list, lv_in_query);

            v_outer_query := v_outer_query || lv_in_query;
            v_count_query := v_count_query || lv_in_query;
        END IF;

        -- For Column Level Filter with user selected checkboxes

        /*IF i_filter_list IS NOT EMPTY
        THEN
           FOR IDX IN 1 .. i_filter_list.COUNT ()
           LOOP
              IF     (i_filter_list (idx).COL_NAME IS NOT NULL)
                 AND (i_filter_list (idx).COL_NAME NOT LIKE ' ')
              THEN
                 lv_filter_column_name :=
                    UPPER (TO_CHAR (TRIM (i_filter_list (idx).COL_NAME)));

                 CASE
                    WHEN lv_filter_column_name = 'REFRESHPARTNUMBER'
                    THEN
                       lv_filter_column_name := 'REFRESH_PART_NUMBER';
                    WHEN lv_filter_column_name = 'C3PARTNUMBER'
                    THEN
                       lv_filter_column_name := 'C3_PART_NUMBER';
                    WHEN lv_filter_column_name = 'SOURCELOCATIONZCODE'
                    THEN
                       lv_filter_column_name := 'SOURCE_LOCATION_ZCODE';
                    WHEN lv_filter_column_name = 'DESTINATIONLOCATIONZCODE'
                    THEN
                       lv_filter_column_name := 'DESTINATION_LOCATION_ZCODE';
                    WHEN lv_filter_column_name = 'SUBINVENTORYLOCATION'
                    THEN
                       lv_filter_column_name := 'SUB_INVENTORY_LOCATION';
                    WHEN lv_filter_column_name = 'C3ONHANDDGI'
                    THEN
                       lv_filter_column_name := 'C3_ONHAND_DGI';
                    ELSE
                       lv_filter_column_name := '';
                 END CASE;

                 v_outer_query :=
                       v_outer_query
                    || ' AND ('
                    || lv_filter_column_name
                    || ' IN (';

                 v_count_query :=
                       v_count_query
                    || ' AND ('
                    || lv_filter_column_name
                    || ' IN (';

                 lv_filter_data_list := i_filter_list (idx).COL_VALUE;

                 FOR IDX IN 1 .. lv_filter_data_list.COUNT ()
                 LOOP
                    IF lv_filter_data_list IS NOT EMPTY
                    THEN
                       IF     (lv_filter_data_list (idx).FILTER_DATA
                                  IS NOT NULL)
                          AND (lv_filter_data_list (idx).FILTER_DATA NOT LIKE
                                  ' ')
                       THEN
                          lv_filter_value :=
                             UPPER (
                                TO_CHAR (
                                   TRIM (lv_filter_data_list (idx).FILTER_DATA)));

                          IF lv_filter_value LIKE '/'
                            THEN
                            lv_null_query := 'OR ' || lv_filter_column_name || ' IS NULL';
                          END IF;


                          IF idx = 1
                          THEN
                             v_outer_query :=
                                   v_outer_query
                                || ''''
                                || lv_filter_value
                                || '''';
                             v_count_query :=
                                   v_count_query
                                || ''''
                                || lv_filter_value
                                || '''';
                          ELSE
                             v_outer_query :=
                                   v_outer_query
                                || ','
                                || ''''
                                || lv_filter_value
                                || '''';
                             v_count_query :=
                                   v_count_query
                                || ','
                                || ''''
                                || lv_filter_value
                                || '''';
                          END IF;
                       END IF;
                    END IF;
                 END LOOP;

                 v_outer_query := v_outer_query || ')'|| lv_null_query || ')';
                 v_count_query := v_count_query || ')'|| lv_null_query || ')';
              END IF;
           END LOOP;
        -- v_count_query := v_count_query || '))';
        --v_main_query := v_main_query || '))';
        END IF;*/

        -- For Sorting based on the user selection
        IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
        THEN
            -- For getting the limited set of data based on the min and max values
            v_row_clause :=
                   '  ) WHERE RNUM >'
                || lv_min_row
                || ' AND RNUM <='
                || lv_max_row;

            v_outer_query :=
                   v_outer_query
                || ' ORDER BY '
                || lv_sort_column_name
                || ' '
                || lv_sort_column_by;
        ELSE
            -- For getting the limited set of data based on the min and max values
            v_row_clause :=
                   '  ) WHERE RNUM >'
                || lv_min_row
                || ' AND RNUM <='
                || lv_max_row;

            v_outer_query := v_outer_query || ' ORDER BY REFRESH_PART_NUMBER';
        END IF;

        v_whereclause :=
               v_product
            || v_src_zlocation
            || v_dest_zlocation
            || v_sub_inv_location;


        v_row_clause :=
            ' ) WHERE RNUM <= ' || lv_max_row || ' AND RNUM >' || lv_min_row;


        v_count_query := v_count_query || v_whereclause;

        v_outer_query := v_outer_query || v_row_clause;


        v_query :=
               ' SELECT RC_INVENTORY_TRANSFER_RPT_OBJ (REFRESH_INVENTORY_ITEM_ID,
                                      REFRESH_PART_NUMBER,
                                      C3_PART_NUMBER,
--                                      INVENTORY_ITEM_ID,
--                                      PART_NUMBER,
                                      SOURCE_LOCATION_ZCODE,
                                      DESTINATION_LOCATION_ZCODE,
                                      SUB_INVENTORY_LOCATION,
                                      C3_ONHAND_DGI,
                                      QTY_TO_TRANSFER)
        FROM ( '
            || v_outer_query
            || ' ) ';

        BEGIN
            EXECUTE IMMEDIATE v_count_query INTO lv_total_row_count;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_total_row_count := 0;
        END;

        BEGIN
            EXECUTE IMMEDIATE v_query
                BULK COLLECT INTO lv_inventory_transfer_rpt_list;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_inventory_transfer_rpt_list :=
                    RC_INVENTORY_TRANSFER_RPT_LIST ();
        END;


        BEGIN
            SELECT TO_CHAR (MAX (TIME_STAMP), 'DD-MON-YYYY HH:MI:SS AM')
              INTO lv_date1
              FROM CRPADM.RC_JOBS_NOTIFICATION_HISTORY
             WHERE     NOTIFICATION_ID = 4
                   AND UPPER (STATUS) = UPPER ('successful');

            lv_last_refreshed_msg :=
                'Inventory Transfer Report is generated on ' || lv_date1;

            o_date := lv_date;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_last_refreshed_msg :=
                    'No successful execution of the Inventory Transfer Engine';
        END;

        o_total_row_count := lv_total_row_count;
        o_inventory_transfer_rpt_list := lv_inventory_transfer_rpt_list;
        o_last_refreshed_msg := lv_last_refreshed_msg;
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
                'CRPSC.RC_INVENTORY_TRANSFER.RC_FETCH_INV_RPT_DETAILS',
                'PROCEDURE',
                lv_user_id,
                'N');
    END RC_FETCH_INV_RPT_DTLS_FILTER;



    PROCEDURE RC_FETCH_INV_RPT_UNQ_FILTERS (
        i_user_id                       IN     VARCHAR2,
        i_product                       IN     VARCHAR2,
        i_src_zlocation                 IN     VARCHAR2,
        i_dest_zlocation                IN     VARCHAR2,
        i_sub_inv_location              IN     VARCHAR2,
        i_filter_column_name            IN     VARCHAR2,
        i_filter_list                   IN     RC_NEW_FILTER_OBJ_LIST,
        o_inventory_transfer_rpt_list      OUT RC_ADDL_FILTERS_LIST)
    IS
        v_product                        VARCHAR2 (100) DEFAULT NULL;
        v_src_zlocation                  VARCHAR2 (100) DEFAULT NULL;
        v_dest_zlocation                 VARCHAR2 (100) DEFAULT NULL;
        v_sub_inv_location               VARCHAR2 (100) DEFAULT NULL;
        v_query                          VARCHAR2 (32767);
        v_main_query                     CLOB;             --VARCHAR2 (32767);
        lv_filter_value                  VARCHAR2 (1000);
        lv_user_id                       VARCHAR2 (100);

        lv_filter_column_name            VARCHAR2 (100);
        lv_filter_column                 VARCHAR2 (100);
        lv_inventory_transfer_rpt_list   RC_ADDL_FILTERS_LIST;
        lv_filter_data_list              RC_FILTER_DATA_OBJ_LIST;

        lv_product                       VARCHAR2 (100);
        lv_src_zlocation                 VARCHAR2 (50);
        lv_dest_zlocation                VARCHAR2 (50);
        lv_sub_inv_location              VARCHAR2 (10);
        lv_null_query                    VARCHAR2 (32767);
        lv_in_query                      CLOB;
    BEGIN
        lv_user_id := i_user_id;
        lv_product := i_product;
        lv_src_zlocation := i_src_zlocation;
        lv_dest_zlocation := i_dest_zlocation;
        lv_sub_inv_location := i_sub_inv_location;
        lv_inventory_transfer_rpt_list := RC_ADDL_FILTERS_LIST ();

        lv_filter_column := UPPER (TRIM (i_filter_column_name));



        v_main_query := ' SELECT REFRESH_INVENTORY_ITEM_ID,
               REFRESH_PART_NUMBER,
               C3_PART_NUMBER,
--               MLC3.INVENTORY_ITEM_ID INVENTORY_ITEM_ID,
--               MLC3.PART_NUMBER PART_NUMBER,
               SOURCE_LOCATION_ZCODE,
               DESTINATION_LOCATION_ZCODE,
               SUB_INVENTORY_LOCATION,
               C3_ONHAND_DGI,
               QTY_TO_TRANSFER FROM ( SELECT A.REFRESH_INVENTORY_ITEM_ID,
               CASE
          WHEN A.C3_INVENTORY_ITEM_ID = B.COMMON_INVENTORY_ITEM_ID
          THEN
             COMMON_PART_NUMBER
          WHEN A.C3_INVENTORY_ITEM_ID = B.XREF_INVENTORY_ITEM_ID
          THEN
             XREF_PART_NUMBER
       END C3_PART_NUMBER,
               B.REFRESH_PART_NUMBER,
               A.SOURCE_LOCATION_ZCODE,
               A.DESTINATION_LOCATION_ZCODE,
               A.SUB_INVENTORY_LOCATION,
               A.C3_ONHAND_DGI,
               A.QTY_TO_TRANSFER
               FROM RC_INVENTORY_TRANSFER_TBL A
                         JOIN CRPADM.RC_PRODUCT_MASTER B
                            ON A.REFRESH_INVENTORY_ITEM_ID =
                                  B.REFRESH_INVENTORY_ITEM_ID) WHERE 1=1 ';

        CASE
            WHEN lv_filter_column = 'REFRESHPARTNUMBER'
            THEN
                lv_filter_column := 'REFRESH_PART_NUMBER';
            WHEN lv_filter_column = 'C3PARTNUMBER'
            THEN
                lv_filter_column := 'C3_PART_NUMBER';
            WHEN lv_filter_column = 'SOURCELOCATIONZCODE'
            THEN
                lv_filter_column := 'SOURCE_LOCATION_ZCODE';
            WHEN lv_filter_column = 'DESTINATIONLOCATIONZCODE'
            THEN
                lv_filter_column := 'DESTINATION_LOCATION_ZCODE';
            WHEN lv_filter_column = 'SUBINVENTORYLOCATION'
            THEN
                lv_filter_column := 'SUB_INVENTORY_LOCATION';
            WHEN lv_filter_column = 'C3ONHANDDGI'
            THEN
                lv_filter_column := 'C3_ONHAND_DGI';
            WHEN lv_filter_column = 'QTYTOTRANSFER'
            THEN
                lv_filter_column := 'QTY_TO_TRANSFER';
            ELSE
                lv_filter_column := '';
        END CASE;

        IF i_filter_list IS NOT EMPTY
        THEN
            GET_IN_CONDITION_FOR_QUERY (i_filter_list, lv_in_query);

            v_main_query := v_main_query || lv_in_query;
        END IF;

        --Z
        /* IF i_filter_list IS NOT EMPTY
         THEN
            FOR IDX IN 1 .. i_filter_list.COUNT ()
            LOOP
               IF     (i_filter_list (idx).COL_NAME IS NOT NULL)
                  AND (i_filter_list (idx).COL_NAME NOT LIKE ' ')
               THEN
                  lv_filter_column_name :=
                     UPPER (TO_CHAR (TRIM (i_filter_list (idx).COL_NAME)));



                  CASE
                     WHEN lv_filter_column_name = 'REFRESHPARTNUMBER'
                     THEN
                        lv_filter_column_name := 'REFRESH_PART_NUMBER';
                     WHEN lv_filter_column_name = 'C3PARTNUMBER'
                     THEN
                        lv_filter_column_name := 'C3_PART_NUMBER';
                     WHEN lv_filter_column_name = 'SOURCELOCATIONZCODE'
                     THEN
                        lv_filter_column_name := 'SOURCE_LOCATION_ZCODE';
                     WHEN lv_filter_column_name = 'DESTINATIONLOCATIONZCODE'
                     THEN
                        lv_filter_column_name := 'DESTINATION_LOCATION_ZCODE';
                     WHEN lv_filter_column_name = 'SUBINVENTORYLOCATION'
                     THEN
                        lv_filter_column_name := 'SUB_INVENTORY_LOCATION';
                     WHEN lv_filter_column_name = 'C3ONHANDDGI'
                     THEN
                        lv_filter_column_name := 'C3_ONHAND_DGI';
                     ELSE
                        lv_filter_column_name := '';
                  END CASE;



                  v_main_query :=
                        v_main_query
                     || ' AND ('
                     || lv_filter_column_name
                     || ' IN (';



                  lv_filter_data_list := i_filter_list (idx).COL_VALUE;

                  FOR IDX IN 1 .. lv_filter_data_list.COUNT ()
                  LOOP
                     IF lv_filter_data_list IS NOT EMPTY
                     THEN
                        IF     (lv_filter_data_list (idx).FILTER_DATA
                                   IS NOT NULL)
                           AND (lv_filter_data_list (idx).FILTER_DATA NOT LIKE
                                   ' ')
                        THEN
                           lv_filter_value :=
                              UPPER (
                                 TO_CHAR (
                                    TRIM (lv_filter_data_list (idx).FILTER_DATA)));

                           IF lv_filter_value LIKE '/'
                             THEN
                             lv_null_query := 'OR ' || lv_filter_column_name || ' IS NULL';
                           END IF;


                           IF idx = 1
                           THEN
                              v_main_query :=
                                 v_main_query || '''' || lv_filter_value || '''';
                           ELSE
                              v_main_query :=
                                    v_main_query
                                 || ','
                                 || ''''
                                 || lv_filter_value
                                 || '''';
                           END IF;
                        END IF;
                     END IF;
                  END LOOP;

                  v_main_query := v_main_query || ')'|| lv_null_query || ')';
               END IF;
            END LOOP;
         END IF;*/

        -- For Sorting based on the user selection



        v_query :=
               ' SELECT DISTINCT '
            || lv_filter_column
            || ' FROM ( '
            || v_main_query
            || ' )';

        IF lv_product IS NOT NULL
        THEN
            v_product :=
                   '  WHERE REFRESH_PART_NUMBER = '
                || ''''
                || lv_product
                || '''';
            v_query := v_query || v_product;
        END IF;

        IF lv_src_zlocation IS NOT NULL
        THEN
            v_src_zlocation :=
                   '  WHERE SOURCE_LOCATION_ZCODE = '
                || ''''
                || lv_src_zlocation
                || '''';
            v_query := v_query || v_src_zlocation;
        END IF;

        IF lv_dest_zlocation IS NOT NULL
        THEN
            v_dest_zlocation :=
                   '  WHERE DESTINATION_LOCATION_ZCODE = '
                || ''''
                || lv_dest_zlocation
                || '''';
            v_query := v_query || v_dest_zlocation;
        END IF;

        IF lv_sub_inv_location IS NOT NULL
        THEN
            v_sub_inv_location :=
                   '  WHERE SUB_INVENTORY_LOCATION = '
                || ''''
                || lv_sub_inv_location
                || '''';
            v_query := v_query || v_sub_inv_location;
        END IF;

        -- Ordering the Unique filter data

        v_query :=
            v_query || ' ORDER BY ' || lv_filter_column || ' ASC NULLS FIRST';

        COMMIT;


        EXECUTE IMMEDIATE v_query
            BULK COLLECT INTO lv_inventory_transfer_rpt_list;

        o_inventory_transfer_rpt_list := lv_inventory_transfer_rpt_list;

        BEGIN
            EXECUTE IMMEDIATE v_query
                BULK COLLECT INTO lv_inventory_transfer_rpt_list;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                lv_inventory_transfer_rpt_list := RC_ADDL_FILTERS_LIST ();
        END;
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
                'CRPSC.RC_INVENTORY_TRANSFER.RC_FETCH_INV_RPT_UNQ_FILTERS',
                'PROCEDURE',
                lv_user_id,
                'N');
    END RC_FETCH_INV_RPT_UNQ_FILTERS;

    PROCEDURE GET_IN_CONDITION_FOR_QUERY (
        i_filter_list       RC_NEW_FILTER_OBJ_LIST,
        i_in_query      OUT CLOB)
    IS
        lv_in_query             CLOB;
        lv_null_query           VARCHAR2 (32767);
        lv_count                NUMBER;
        lv_filter_data_list     RC_FILTER_DATA_OBJ_LIST;
        lv_filter_column_name   VARCHAR2 (100);
        lv_filter_value         VARCHAR2 (1000);
    BEGIN
        lv_count := 1;

        IF i_filter_list IS NOT EMPTY
        THEN
            FOR IDX IN 1 .. i_filter_list.COUNT ()
            LOOP
                IF     (i_filter_list (idx).COL_NAME IS NOT NULL)
                   AND (i_filter_list (idx).COL_NAME NOT LIKE ' ')
                THEN
                    lv_filter_column_name :=
                        UPPER (TO_CHAR (TRIM (i_filter_list (idx).COL_NAME)));

                    CASE
                        WHEN lv_filter_column_name = 'REFRESHPARTNUMBER'
                        THEN
                            lv_filter_column_name := 'REFRESH_PART_NUMBER';
                        WHEN lv_filter_column_name = 'C3PARTNUMBER'
                        THEN
                            lv_filter_column_name := 'C3_PART_NUMBER';
                        WHEN lv_filter_column_name = 'SOURCELOCATIONZCODE'
                        THEN
                            lv_filter_column_name := 'SOURCE_LOCATION_ZCODE';
                        WHEN lv_filter_column_name =
                             'DESTINATIONLOCATIONZCODE'
                        THEN
                            lv_filter_column_name :=
                                'DESTINATION_LOCATION_ZCODE';
                        WHEN lv_filter_column_name = 'SUBINVENTORYLOCATION'
                        THEN
                            lv_filter_column_name := 'SUB_INVENTORY_LOCATION';
                        WHEN lv_filter_column_name = 'C3ONHANDDGI'
                        THEN
                            lv_filter_column_name := 'C3_ONHAND_DGI';
                        WHEN lv_filter_column_name = 'QTYTOTRANSFER'
                        THEN
                            lv_filter_column_name := 'QTY_TO_TRANSFER';
                        ELSE
                            lv_filter_column_name := '';
                    END CASE;

                    lv_in_query := lv_in_query || ' AND ';


                    lv_filter_data_list := i_filter_list (idx).COL_VALUE;

                    FOR IDX IN 1 .. lv_filter_data_list.COUNT ()
                    LOOP
                        IF lv_count > 999
                        THEN
                            lv_count := 1;
                            lv_in_query :=
                                   lv_in_query
                                || ') OR UPPER ('
                                || lv_filter_column_name
                                || ') IN (';
                        END IF;

                        IF lv_filter_data_list IS NOT EMPTY
                        THEN
                            IF     (lv_filter_data_list (idx).FILTER_DATA
                                        IS NOT NULL)
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
                                           'OR '
                                        || lv_filter_column_name
                                        || ' IS NULL';
                                END IF;

                                IF idx = 1
                                THEN
                                    lv_in_query :=
                                           lv_in_query
                                        || '(UPPER ('
                                        || lv_filter_column_name
                                        || ') IN ('
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
                        END IF;

                        lv_count := lv_count + 1;
                    END LOOP;

                    lv_in_query := lv_in_query || ')' || lv_null_query || ')';
                    lv_null_query := ' ';
                END IF;
            END LOOP;

            i_in_query := lv_in_query;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            CRPADM.RC_GLOBAL_ERROR_LOGGING (
                'NO DATA FOUND',
                   SUBSTR (SQLERRM, 1, 200)
                || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12),
                NULL,
                'GET_IN_CONDITION_FOR_QUERY',
                'PROCEDURE',
                NULL,
                'Y');
        WHEN OTHERS
        THEN
            CRPADM.RC_GLOBAL_ERROR_LOGGING (
                'OTHERS',
                   SUBSTR (SQLERRM, 1, 200)
                || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12),
                NULL,
                'GET_IN_CONDITION_FOR_QUERY',
                'PROCEDURE',
                NULL,
                'Y');
    END;
END RC_INVENTORY_TRANSFER;
/