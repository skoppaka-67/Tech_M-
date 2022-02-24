CREATE OR REPLACE PACKAGE BODY CRPADM./*AppDB: 1029592*/
                                                                                                                                                                                                                                                                               "RC_DEMAND_AUTOMATION"
IS
   /*======================================================================================================+
   |                                 Referesh Central Demand Automation                                             |
   +=======================================================================================================+
   |
   | Object Name   : CRPADM.RC_DEMAND_AUTOMATION
   |
   | Module        : Demand Automation 2.0
   |
   | Description   : Demand sourcing and final demand list generation
   | Version :1.0
   | author : karsivak
   || Modification History
    ||------------------------------------------------------------------------------------------------------
    ||Date                          By                  Version                 Comments
    ||------------------------------------------------------------------------------------------------------
    ||30-June-2020      Shreyas,Malathi                 2.0                 SD report NMOS calculation changes as part of -PRB0062378 and FC date formatting
    ||24-August-2020    Sneha,Malathi                   2.1                 Added 'POE-NRHS' location for In-transit quantity for NEW/NEWX and changed lv_ws_rmktng_name variable assignmnet as part of -PRB0061800
   */

   v_errmsg   VARCHAR2 (2000);

   
      /* Procedure for setitng storage max and demand quantity for the products with WWRL inventory */
      PROCEDURE rc_demand_sourcing
      IS
         v_product          VARCHAR2 (256);
         v_mos              NUMBER;
         lv_count           NUMBER;
         lv_baseline_mos    NUMBER;
         lv_asp             NUMBER;
         lv_limit           NUMBER := 1000;
         lv_trans_percent   NUMBER;
         lv_include_count   NUMBER;
         lv_dem_lesser      NUMBER;
         lv_dem_greater     NUMBER;
   
         TYPE t_wwrl_details IS RECORD
         (
            part_no               VARCHAR2 (256),
            product_family        VARCHAR2 (100),
            product_common_name   VARCHAR2 (256),
            product_spare_name    VARCHAR2 (256),
            source_type           VARCHAR2 (10),
            status                VARCHAR2 (10),
            flag                  VARCHAR2 (10)
         );
   
         TYPE t_wwrl_details_list IS TABLE OF t_wwrl_details;
   
         TYPE t_rc_details IS RECORD
         (
            part_no          VARCHAR2 (256),
            product_family   VARCHAR2 (100),
            source_type      VARCHAR2 (10),
            status           VARCHAR2 (10)
         );
   
         TYPE t_rc_details_list IS TABLE OF t_rc_details;
   
         TYPE T_OBJ IS RECORD
         (
            PRODUCT_NAME   VARCHAR2 (5256 BYTE),
            VAL            VARCHAR2 (100)
         );
   
         TYPE T_LIST IS TABLE OF T_OBJ;
   
         lv_list            T_LIST := T_LIST ();
   
         lv_wwrl_data       t_wwrl_details_list;
   
         lv_cisco_data      t_wwrl_details_list;
   
         lv_rc_data         t_rc_details_list;
   
   
   
         CURSOR CUR_WWRL
         IS
            SELECT /*+ NO_MERGE(WWRL) */
                   DISTINCT
                   part_no,
                   product_family,
                   product_common_name,
                   RC_DEMAND_AUTOMATION.get_spare_name (product_common_name,
                                                        'Alternate'),
                   'WWRL',
                   'NEW',
                   'N'
              FROM (SELECT part_no,
                           product_family,
                           RC_DEMAND_AUTOMATION.get_common_name (part_no)
                              product_common_name,
                           CASE
                              WHEN part_no LIKE '%RF' THEN 0
                              WHEN part_no LIKE '%WS' THEN 1
                              ELSE 2
                           END
                              product_type
                      FROM RC_WWRL_INV_DATA_TBL RC_WWRL_INV_DATA_TBL1) wwrl
             WHERE     wwrl.part_no IS NOT NULL
                   AND NOT EXISTS
                              (SELECT 1
                                 FROM RC_DEMAND_SOURCING_LIST_STG c3_ocv
                                WHERE     STATUS = 'NEW'
                                      AND SOURCE_TYPE IN ('RSCM', 'ML/C3')
                                      AND (   wwrl.part_no = cisco_product_name
                                           OR wwrl.part_no = product_name
                                           OR wwrl.part_no = product_spare_name
                                           OR wwrl.part_no = excess_name
                                           OR wwrl.product_common_name =
                                                 cisco_product_name))
                   AND NOT EXISTS
                              (SELECT 1
                                 FROM (SELECT RC_DEMAND_AUTOMATION.get_spare_name (
                                                 part_no,
                                                 'Alternate')
                                                 part_no
                                         FROM RC_WWRL_INV_DATA_TBL RC_WWRL_INV_DATA_TBL2
                                        WHERE     part_no NOT LIKE '%='
                                              AND part_no NOT LIKE '%RF'
                                              AND part_no NOT LIKE '%WS') wsp
                                WHERE wsp.part_no = wwrl.part_no);
   
         CURSOR CUR_CISCO
         IS
            SELECT /*+ NO_MERGE(c) */
                   DISTINCT
                   PRODUCT_NAME PART_NO,
                   (SELECT product_family
                      FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                     WHERE product_name = product_id)
                      product_family,
                   product_common_name,
                   RC_DEMAND_AUTOMATION.get_spare_name (product_common_name,
                                                        'Alternate'),
                   'CISCO',
                   'NEW',
                   'N'
              FROM (SELECT RC_DEMAND_AUTOMATION.get_common_name (ORDERED_ITEM)
                              product_name,
                           NULL product_family,
                           RC_DEMAND_AUTOMATION.get_common_name (ORDERED_ITEM)
                              product_common_name,
                           CASE
                              WHEN ORDERED_ITEM LIKE '%RF' THEN 0
                              WHEN ORDERED_ITEM LIKE '%WS' THEN 1
                              ELSE 2
                           END
                              product_type
                      FROM CISCO_PRODUCT_SALES_QW CISC
                     WHERE     ORDERED_ITEM NOT LIKE '%RF'
                           AND ORDERED_ITEM NOT LIKE '%WS') c
             WHERE     c.product_name IS NOT NULL
                   AND NOT EXISTS
                              (SELECT 1
                                 FROM RC_DEMAND_SOURCING_LIST_STG c3_ocv
                                WHERE     STATUS = 'NEW'
                                      AND SOURCE_TYPE IN ('RSCM',
                                                          'ML/C3',
                                                          'WWRL')
                                      AND (   c.product_name =
                                                 cisco_product_name
                                           OR c.product_name = product_name
                                           OR c.product_name =
                                                 product_spare_name
                                           OR c.product_name = excess_name));
   
         CURSOR CUR_RC
         IS
            SELECT DISTINCT pocv.REFRESH_PART_NUMBER,
                            pocv.product_family,
                            'RSCM',
                            'NEW'
              FROM RC_PRODUCT_MASTER pocv
             WHERE                             -- pocv.refresh_life_cycle_id <> 6
                  program_type = 0
                   AND refresh_part_number NOT IN (SELECT refresh_part_number
                                                     FROM crpadm.rc_product_master
                                                    WHERE     refresh_life_cycle_id =
                                                                 6
                                                          AND program_type = 0
                                                          AND common_part_number IN (SELECT common_part_number
                                                                                       FROM crpadm.rc_product_master
                                                                                      WHERE     refresh_life_cycle_id <>
                                                                                                   6
                                                                                            AND program_type =
                                                                                                   0
                                                                                     UNION
                                                                                     SELECT xref_part_number
                                                                                       FROM crpadm.rc_product_master
                                                                                      WHERE     refresh_life_cycle_id <>
                                                                                                   6
                                                                                            AND program_type =
                                                                                                   0)
                                                   UNION
                                                   SELECT refresh_part_number
                                                     FROM crpadm.rc_product_master rm
                                                    WHERE     refresh_life_cycle_id =
                                                                 6
                                                          AND program_type = 0
                                                          AND common_part_number IN (SELECT common_part_number
                                                                                       FROM crpadm.rc_product_master rm1
                                                                                      WHERE     refresh_life_cycle_id =
                                                                                                   6
                                                                                            AND program_type =
                                                                                                   0
                                                                                            AND rm.refresh_part_number <>
                                                                                                   rm1.refresh_part_number
                                                                                            AND rm1.deactivation_date >=
                                                                                                   rm.deactivation_date
                                                                                     UNION
                                                                                     SELECT xref_part_number
                                                                                       FROM crpadm.rc_product_master rm1
                                                                                      WHERE     refresh_life_cycle_id =
                                                                                                   6
                                                                                            AND program_type =
                                                                                                   0
                                                                                            AND rm.refresh_part_number <>
                                                                                                   rm1.refresh_part_number
                                                                                            AND rm1.deactivation_date >=
                                                                                                   rm.deactivation_date))
            UNION
            SELECT REFRESH_PART_NUMBER,
                   pocv.product_family,
                   'RSCM',
                   'NEW'
              FROM RC_PRODUCT_MASTER pocv
             WHERE                         --     pocv.refresh_life_cycle_id <> 6
                  program_type = 1
                   AND refresh_part_number NOT IN (SELECT refresh_part_number
                                                     FROM crpadm.rc_product_master
                                                    WHERE     refresh_life_cycle_id =
                                                                 6
                                                          AND program_type = 1
                                                          AND common_part_number IN (SELECT common_part_number
                                                                                       FROM crpadm.rc_product_master
                                                                                      WHERE     refresh_life_cycle_id <>
                                                                                                   6
                                                                                            AND program_type =
                                                                                                   1
                                                                                     UNION
                                                                                     SELECT xref_part_number
                                                                                       FROM crpadm.rc_product_master
                                                                                      WHERE     refresh_life_cycle_id <>
                                                                                                   6
                                                                                            AND program_type =
                                                                                                   1)
                                                   UNION
                                                   SELECT refresh_part_number
                                                     FROM crpadm.rc_product_master rm
                                                    WHERE     refresh_life_cycle_id =
                                                                 6
                                                          AND program_type = 1
                                                          AND common_part_number IN (SELECT common_part_number
                                                                                       FROM crpadm.rc_product_master rm1
                                                                                      WHERE     refresh_life_cycle_id =
                                                                                                   6
                                                                                            AND program_type =
                                                                                                   1
                                                                                            AND rm.refresh_part_number <>
                                                                                                   rm1.refresh_part_number
                                                                                            AND rm1.deactivation_date >=
                                                                                                   rm.deactivation_date
                                                                                     UNION
                                                                                     SELECT xref_part_number
                                                                                       FROM crpadm.rc_product_master rm1
                                                                                      WHERE     refresh_life_cycle_id =
                                                                                                   6
                                                                                            AND program_type =
                                                                                                   1
                                                                                            AND rm.refresh_part_number <>
                                                                                                   rm1.refresh_part_number
                                                                                            AND rm1.deactivation_date >=
                                                                                                   rm.deactivation_date))
                   AND NOT EXISTS
                              (SELECT common_part_number
                                 FROM (SELECT DISTINCT common_part_number
                                         FROM RC_PRODUCT_MASTER
                                        WHERE REFRESH_PART_NUMBER LIKE '%RF'
                                       UNION
                                       SELECT DISTINCT
                                              XREF_PART_NUMBER
                                                 common_part_number
                                         FROM RC_PRODUCT_MASTER
                                        WHERE REFRESH_PART_NUMBER LIKE '%RF')
                                      ocm
                                WHERE pocv.common_part_number =
                                         ocm.common_part_number)
            UNION
            SELECT part_number,
                   product_family,
                   'ML/C3',
                   'NEW'
              FROM (SELECT DISTINCT
                           part_number,
                           product_family,
                           RC_DEMAND_AUTOMATION.get_common_name (part_number)
                              product_common_name,
                           (CASE
                               WHEN (   part_number LIKE '%RF'
                                     OR location LIKE 'RF%')
                               THEN
                                  0
                               WHEN (   part_number LIKE '%WS'
                                     OR location LIKE 'WS%')
                               THEN
                                  1
                               ELSE
                                  2
                            END)
                              product_type
                      FROM CRPADM.RC_INV_BTS_C3_MV
                     WHERE PART_NUMBER IS NOT NULL) ml_c3
             WHERE NOT EXISTS
                          (SELECT 1
                             FROM RC_DEMAND_SOURCING_PIDS ocv
                            WHERE (   ocv.REFRESH_PART_NUMBER =
                                         ml_c3.part_number
                                   OR ocv.refresh_part_number =
                                         ml_c3.product_common_name));
      BEGIN
         --Step 1: Inserting Pids from various sources into the table for Demand calculation--
   
         DELETE FROM rc_demand_sourcing_list
               WHERE status = 'Old' AND created_date < ADD_MONTHS (SYSDATE, -2);
   
         DELETE FROM RC_DEMAND_SOURCING_LIST_STG;
   
         DBMS_MVIEW.refresh (list => 'RC_DEMAND_SOURCING_PIDS', method => 'C'); 
   
   
         COMMIT;
   
         --      INSERT INTO RC_DEM_TST
         --           VALUES ('STEP1', SYSDATE);
         IF NOT (CUR_RC%ISOPEN)
         THEN
            OPEN CUR_RC;
         END IF;
   
         LOOP
            FETCH CUR_RC BULK COLLECT INTO lv_rc_data LIMIT lv_limit;
   
            IF lv_rc_data.COUNT > 0
            THEN
               FORALL idx IN lv_rc_data.FIRST .. lv_rc_data.LAST
                  INSERT INTO RC_DEMAND_SOURCING_LIST_STG (product_name,
                                                           product_family,
                                                           source_type,
                                                           status)
                       VALUES (lv_rc_data (idx).part_no,
                               lv_rc_data (idx).product_family,
                               lv_rc_data (idx).source_type,
                               lv_rc_data (idx).status);       -- ML/C3 inventory
   
               EXIT WHEN cur_rc%NOTFOUND;
            ELSE
               EXIT;
            END IF;
         END LOOP;                                     -- End of Cursor Iteration
   
         CLOSE cur_rc;
   
         COMMIT;
   
         --  IF NOT (CUR_BTS%ISOPEN)
         --      THEN
         --         OPEN CUR_BTS;
         --      END IF;
         --
         --      LOOP
         --         FETCH CUR_BTS BULK COLLECT INTO lv_rc_data LIMIT lv_limit;
         --
         --         IF lv_rc_data.COUNT > 0
         --         THEN
         --            FORALL idx IN lv_rc_data.FIRST .. lv_rc_data.LAST
         --               INSERT INTO RC_DEMAND_SOURCING_LIST_STG (product_name,
         --                                                        product_family,
         --                                                        source_type,
         --                                                        status)
         --                    VALUES (lv_rc_data (idx).part_no,
         --                            lv_rc_data (idx).product_family,
         --                            lv_rc_data (idx).source_type,
         --                            lv_rc_data (idx).status);       -- ML/C3 inventory
         --
         --            EXIT WHEN cur_bts%NOTFOUND;
         --         ELSE
         --            EXIT;
         --         END IF;
         --      END LOOP;                                     -- End of Cursor Iteration
         --
         --      CLOSE cur_bts;
         --
         --      COMMIT;
   
         INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                      'CRPADM.RC_DEMAND_AUTOMATION',
                      'INSERT COMPLETED',
                      SYSDATE);
   
         COMMIT;
   
   
         --Setting the Demand flag to N before the update and updating product attributes--
         UPDATE rc_demand_sourcing_list_stg ds
            SET not_to_demand_flag = 'N',
                created_date = SYSDATE,
                cisco_product_name =
                   (CASE
                       WHEN    ds.product_name LIKE '%RF'
                            OR ds.product_name LIKE '%WS'
                            OR ds.product_name LIKE '%RL'
                       THEN
                          (SELECT DISTINCT COMMON_PART_NUMBER
                             FROM RC_PRODUCT_MASTER
                            WHERE REFRESH_PART_NUMBER = ds.product_name)
                       ELSE
                          RC_DEMAND_AUTOMATION.get_common_name (ds.product_name)
                    END)
          WHERE status = 'NEW';
   
         UPDATE rc_demand_sourcing_list_stg ds
            SET cisco_product_name =
                   RC_DEMAND_AUTOMATION.get_common_name (ds.product_name)
          WHERE cisco_product_name IS NULL;
   
         --Updating common name for two different products having same product common name in Org city view which gets updated above as Cisco Name for the product--
         UPDATE rc_demand_sourcing_list_stg ds
            SET ds.cisco_product_name = get_common_name (ds.product_name)
          WHERE cisco_product_name IN (  SELECT cisco_product_name
                                           FROM rc_demand_sourcing_list_stg
                                          WHERE status = 'NEW'
                                       GROUP BY cisco_product_name
                                         HAVING COUNT (cisco_product_name) > 1);
   
         UPDATE rc_demand_sourcing_list_stg ds
            SET product_spare_name =
                   get_spare_name (ds.cisco_product_name, 'Alternate'),
                remarketing_name =
                   (CASE
                       WHEN    ds.product_name LIKE '%RF'
                            OR ds.product_name LIKE '%WS'
                            OR ds.product_name LIKE '%RL'
                       THEN
                          ds.product_name
                       ELSE
                          NVL (
                             (SELECT DISTINCT REFRESH_PART_NUMBER
                                FROM RC_PRODUCT_MASTER
                               WHERE     (   COMMON_PART_NUMBER =
                                                ds.product_name
                                          OR COMMON_PART_NUMBER =
                                                ds.cisco_product_name)
                                     AND REFRESH_PART_NUMBER LIKE '%RF'
                                     AND ROWNUM < 2),
                             (SELECT DISTINCT REFRESH_PART_NUMBER
                                FROM RC_PRODUCT_MASTER
                               WHERE     (   COMMON_PART_NUMBER =
                                                ds.product_name
                                          OR COMMON_PART_NUMBER =
                                                ds.cisco_product_name)
                                     AND REFRESH_PART_NUMBER LIKE '%WS'
                                     AND ROWNUM < 2))
                    END)
          WHERE status = 'NEW';
   
   
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET excess_name =
                   rc_utility.get_refresh_name (
                      NVL (DS.REMARKETING_NAME, DS.PRODUCT_NAME),
                      'EXCESS')
          WHERE STATUS = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_STG DS
            SET PRODUCT_FAMILY =
                   (SELECT DISTINCT PRODUCT_FAMILY
                      FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                     WHERE PRODUCT_ID = DS.CISCO_PRODUCT_NAME)
          WHERE STATUS = 'NEW' AND (DS.CISCO_PRODUCT_NAME IS NOT NULL);
   
         UPDATE RC_DEMAND_SOURCING_LIST_STG DS
            SET PRODUCT_FAMILY =
                   (SELECT DISTINCT PRODUCT_FAMILY
                      FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                     WHERE PRODUCT_ID = DS.PRODUCT_SPARE_NAME)
          WHERE     STATUS = 'NEW'
                AND (DS.PRODUCT_SPARE_NAME IS NOT NULL)
                AND (PRODUCT_FAMILY IS NULL OR CISCO_PRODUCT_NAME IS NULL);
   
      UPDATE RC_DEMAND_SOURCING_LIST_STG DS
         SET PRODUCT_FAMILY =
                (SELECT DISTINCT MC_PF.SEGMENT1
                   FROM CG1_MTL_SYSTEM_ITEMS_B@RC_ODSPROD MSI,
                        CG1_MTL_ITEM_CATEGORIES@RC_ODSPROD MIC_PF,
                        CG1_MTL_CATEGORIES_B@RC_ODSPROD MC_PF
                  WHERE     MSI.SEGMENT1 IN (DS.CISCO_PRODUCT_NAME)
                        AND MIC_PF.CATEGORY_SET_ID = 1100000245
                        AND MIC_PF.CATEGORY_ID = MC_PF.CATEGORY_ID
                        AND MSI.INVENTORY_ITEM_ID = MIC_PF.INVENTORY_ITEM_ID
                        AND MSI.ORGANIZATION_ID = MIC_PF.ORGANIZATION_ID
                        AND MSI.ORGANIZATION_ID = 1
                        AND MSI.END_DATE_ACTIVE IS NULL
                        AND MSI.GLOBAL_NAME = MC_PF.GLOBAL_NAME
                        AND MSI.GLOBAL_NAME = MIC_PF.GLOBAL_NAME
                        AND MSI.GLOBAL_NAME = 'CG')
       WHERE PRODUCT_FAMILY IS NULL;
   
         INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                      'CRPADM.RC_DEMAND_AUTOMATION',
                      'WWRL INSERT START',
                      SYSDATE);
   
         COMMIT;
   
         /*  INSERT INTO RC_DEMAND_SOURCING_LIST (product_name,
                                                product_family,
                                                CISCO_PRODUCT_NAME,
                                                PRODUCT_SPARE_NAME,
                                                source_type,
                                                status,
                                                not_to_demand_flag,
                                                created_date)
              (SELECT /*+ NO_MERGE(WWRL)  DISTINCT part_no,
            product_family,
            product_common_name,
            RC_DEMAND_AUTOMATION.get_spare_name(product_common_name, 'Alternate'),
            'WWRL',
            'NEW',
            'N',
            SYSDATE
       FROM (SELECT part_no,
                    product_family,
                    RC_DEMAND_AUTOMATION.get_common_name(part_no) product_common_name,
                    CASE WHEN part_no LIKE '%RF' THEN 0
                         WHEN part_no LIKE '%WS' THEN 1
                         ELSE 2 END product_type
               FROM RC_WWRL_INV_DATA_TBL RC_WWRL_INV_DATA_TBL1) wwrl
      WHERE wwrl.part_no IS NOT NULL
        AND NOT EXISTS (SELECT 1
                          FROM RC_DEMAND_SOURCING_LIST c3_ocv
                         WHERE STATUS = 'NEW'
                           AND SOURCE_TYPE IN ('RSCM', 'ML/C3')
                           AND (wwrl.part_no = cisco_product_name
                                 ))
         AND NOT EXISTS (SELECT 1
                          FROM RC_DEMAND_SOURCING_LIST c3_ocv
                         WHERE STATUS = 'NEW'
                           AND SOURCE_TYPE IN ('RSCM', 'ML/C3')
                           AND (wwrl.part_no = product_name
                                 ))
          AND NOT EXISTS (SELECT 1
                          FROM RC_DEMAND_SOURCING_LIST c3_ocv
                         WHERE STATUS = 'NEW'
                           AND SOURCE_TYPE IN ('RSCM', 'ML/C3')
                           AND (wwrl.part_no = product_spare_name
                                 ))
             AND NOT EXISTS (SELECT 1
                          FROM RC_DEMAND_SOURCING_LIST c3_ocv
                         WHERE STATUS = 'NEW'
                           AND SOURCE_TYPE IN ('RSCM', 'ML/C3')
                           AND (wwrl.part_no = excess_name
                                 ))
        AND NOT EXISTS (SELECT 1
                          FROM (SELECT RC_DEMAND_AUTOMATION.get_spare_name(part_no, 'Alternate') part_no
                                  FROM RC_WWRL_INV_DATA_TBL RC_WWRL_INV_DATA_TBL2
                                 WHERE part_no NOT LIKE '%='
                                   AND part_no NOT LIKE '%RF'
                                   AND part_no NOT LIKE '%WS') wsp
                         WHERE wsp.part_no = wwrl.part_no)
     );
   
           COMMIT;*/
   
         IF NOT (CUR_WWRL%ISOPEN)
         THEN
            OPEN CUR_WWRL;
         END IF;
   
         LOOP
            FETCH CUR_WWRL BULK COLLECT INTO lv_wwrl_data LIMIT lv_limit;
   
            IF lv_wwrl_data.COUNT > 0
            THEN
               FORALL idx IN lv_wwrl_data.FIRST .. lv_wwrl_data.LAST
                  INSERT INTO RC_DEMAND_SOURCING_LIST_stg (product_name,
                                                           product_family,
                                                           CISCO_PRODUCT_NAME,
                                                           PRODUCT_SPARE_NAME,
                                                           source_type,
                                                           status,
                                                           not_to_demand_flag,
                                                           created_date)
                       VALUES (lv_wwrl_data (idx).part_no,
                               lv_wwrl_data (idx).product_family,
                               lv_wwrl_data (idx).product_common_name,
                               lv_wwrl_data (idx).product_spare_name,
                               lv_wwrl_data (idx).source_type,
                               lv_wwrl_data (idx).status,
                               lv_wwrl_data (idx).flag,
                               SYSDATE);
   
   
   
               EXIT WHEN cur_wwrl%NOTFOUND;
            ELSE
               EXIT;
            END IF;
         END LOOP;                                     -- End of Cursor Iteration
   
         CLOSE cur_wwrl;
   
         COMMIT;
   
         IF NOT (CUR_CISCO%ISOPEN)
         THEN
            OPEN CUR_CISCO;
         END IF;
   
         LOOP
            FETCH CUR_CISCO BULK COLLECT INTO lv_cisco_data LIMIT lv_limit;
   
            IF lv_cisco_data.COUNT > 0
            THEN
               FORALL idx IN lv_cisco_data.FIRST .. lv_cisco_data.LAST
                  INSERT INTO RC_DEMAND_SOURCING_LIST_stg (product_name,
                                                           product_family,
                                                           CISCO_PRODUCT_NAME,
                                                           PRODUCT_SPARE_NAME,
                                                           source_type,
                                                           status,
                                                           not_to_demand_flag,
                                                           created_date)
                       VALUES (lv_cisco_data (idx).part_no,
                               lv_cisco_data (idx).product_family,
                               lv_cisco_data (idx).product_common_name,
                               lv_cisco_data (idx).product_spare_name,
                               lv_cisco_data (idx).source_type,
                               lv_cisco_data (idx).status,
                               lv_cisco_data (idx).flag,
                               SYSDATE);
   
   
   
               EXIT WHEN CUR_CISCO%NOTFOUND;
            ELSE
               EXIT;
            END IF;
         END LOOP;                                     -- End of Cursor Iteration
   
         CLOSE CUR_CISCO;
   
         COMMIT;
   
         /*Added for Include list functionality*/
         SELECT COUNT (*)
           INTO lv_include_count
           FROM rc_include_pid_list
          WHERE     TO_DATE (effective_to_date, 'DD/MM/RR') >= TRUNC (SYSDATE)
                AND product_id NOT IN (SELECT DISTINCT product_name
                                         FROM rc_demand_sourcing_list_stg
                                        WHERE     product_name IS NOT NULL
                                              AND STATUS = 'NEW'
                                       UNION
                                       SELECT DISTINCT cisco_product_name
                                         FROM rc_demand_sourcing_list_stg
                                        WHERE     cisco_product_name IS NOT NULL
                                              AND STATUS = 'NEW'
                                       UNION
                                       SELECT DISTINCT product_spare_name
                                         FROM rc_demand_sourcing_list_stg
                                        WHERE     product_spare_name IS NOT NULL
                                              AND STATUS = 'NEW');
   
         IF (lv_include_count) > 0
         THEN
            INSERT INTO rc_demand_sourcing_list_stg (STATUS,
                                                     product_name,
                                                     cisco_product_name,
                                                     include_or_exclude,
                                                     include_or_exclude_reason,
                                                     product_description,
                                                     product_family)
               (SELECT 'NEW',
                       product_id,
                       product_id,
                       'INCLUDE',
                       'User Inclusion',
                       (SELECT product_description
                          FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER RMK
                         WHERE RMK.PRODUCT_ID = RI.PRODUCT_ID),
                       (SELECT product_family
                          FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER RMK
                         WHERE RMK.PRODUCT_ID = RI.PRODUCT_ID)
                  FROM rc_include_pid_list RI
                 WHERE     TO_DATE (effective_to_date, 'DD/MM/RR') >=
                              TRUNC (SYSDATE)
                       AND product_id NOT IN (SELECT DISTINCT product_name
                                                FROM rc_demand_sourcing_list_stg
                                               WHERE     product_name
                                                            IS NOT NULL
                                                     AND STATUS = 'NEW'
                                              UNION
                                              SELECT DISTINCT cisco_product_name
                                                FROM rc_demand_sourcing_list_stg
                                               WHERE     cisco_product_name
                                                            IS NOT NULL
                                                     AND STATUS = 'NEW'
                                              UNION
                                              SELECT DISTINCT product_spare_name
                                                FROM rc_demand_sourcing_list_stg
                                               WHERE     product_spare_name
                                                            IS NOT NULL
                                                     AND STATUS = 'NEW')
                       AND EXISTS
                              (SELECT 1
                                 FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER RMK
                                WHERE RMK.PRODUCT_ID = RI.PRODUCT_ID));
   
            COMMIT;
         END IF;
   
         INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                      'CRPADM.RC_DEMAND_AUTOMATION',
                      'WWRL INSERT COMPLETED',
                      SYSDATE);
   
         COMMIT;
   
         UPDATE rc_demand_sourcing_list_Stg ds
            SET qty_on_hand =
                   get_qoh (ds.remarketing_name,
                            ds.cisco_product_name,
                            ds.product_spare_name,
                            source_type)
          WHERE status = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET (BLOCKED_PID_FROM, REASON_FOR_BLOCKED_PID) =
                   (SELECT ACTION, REASON
                      FROM (  SELECT DISTINCT ACTION, REASON, GTM
                                FROM RC_BLACKLIST_PIDS
                               WHERE (   MFG_PART_NUMBER = CISCO_PRODUCT_NAME
                                      OR MFG_PART_NUMBER = PRODUCT_SPARE_NAME)
                            ORDER BY GTM ASC)
                     WHERE ROWNUM = 1)
          WHERE     EXISTS
                       (SELECT 1
                          FROM RC_BLACKLIST_PIDS
                         WHERE (   MFG_PART_NUMBER = CISCO_PRODUCT_NAME
                                OR MFG_PART_NUMBER = PRODUCT_SPARE_NAME))
                AND status = 'NEW';
   
   
   
         UPDATE rc_demand_sourcing_list_Stg ds
            SET mos =
                   get_mos (ds.cisco_product_name,
                            product_spare_name,
                            qty_on_hand)
          WHERE     status = 'NEW'
                AND (REMARKETING_NAME IS NOT NULL OR EXCESS_NAME IS NOT NULL); -- AND BLOCKED_PID_FROM IN ('PP,DA', 'DA');
   
         COMMIT;
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET GPL =
                   (CASE
                       WHEN SOURCE_TYPE = 'RSCM'
                       THEN
                          (SELECT mfg_list_price_usd
                             FROM RC_PRODUCT_MASTER
                            WHERE REFRESH_PART_NUMBER =
                                     NVL (DS.REMARKETING_NAME, EXCESS_NAME))
                       ELSE
                          (SELECT list_price
                             FROM rmktgadm.rmk_cisco_product_master
                            WHERE product_id = ds.cisco_product_name)
                    END)
          WHERE STATUS = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET GPL =
                   (SELECT list_price
                      FROM rmktgadm.rmk_cisco_product_master
                     WHERE product_id = ds.product_spare_name)
          WHERE STATUS = 'NEW' AND GPL IS NULL;
   
         COMMIT;
   
   
         UPDATE rc_demand_sourcing_list_stg t
            SET REFRESH_LIFE_CYCLE_NAME =
                   (SELECT REFRESH_LIFE_CYCLE_NAME
                      FROM rc_product_master POCV
                     WHERE T.PRODUCT_NAME = pocv.refresh_part_number)
          WHERE status = 'NEW';
   
         COMMIT;
   
   
   
         UPDATE rc_demand_sourcing_list_stg t
            SET r12_SALES =
                   (SELECT (SUM (NVL (RS.TOTAL_QTY, 0)))
                      FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS RS
                           JOIN CRPADM.RC_PRODUCT_MASTER RPM
                              ON     RS.REFRESH_INVENTORY_ITEM_ID =
                                        RPM.REFRESH_INVENTORY_ITEM_ID
                                 AND (   RPM.REFRESH_PART_NUMBER =
                                            t.PRODUCT_NAME
                                      OR RPM.REFRESH_PART_NUMBER = EXCESS_NAME))
          WHERE status = 'NEW';
   
         UPDATE rc_demand_sourcing_list_stg t
            SET r6_SALES =
                   (SELECT (SUM (
                                 NVL (RS.MONTH_7_QTY, 0)
                               + NVL (RS.MONTH_8_QTY, 0)
                               + NVL (RS.MONTH_9_QTY, 0)
                               + NVL (RS.MONTH_10_QTY, 0)
                               + NVL (RS.MONTH_11_QTY, 0)
                               + NVL (RS.MONTH_12_QTY, 0)))
                      FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS RS
                           JOIN CRPADM.RC_PRODUCT_MASTER RPM
                              ON     RS.REFRESH_INVENTORY_ITEM_ID =
                                        RPM.REFRESH_INVENTORY_ITEM_ID
                                 AND (   RPM.REFRESH_PART_NUMBER =
                                            t.PRODUCT_NAME
                                      OR RPM.REFRESH_PART_NUMBER = EXCESS_NAME))
          WHERE status = 'NEW';
   
         COMMIT;
   
         UPDATE rc_demand_sourcing_list_stg
            SET r12_SALES = 0
          WHERE r12_SALES IS NULL;
   
        UPDATE RC_DEMAND_SOURCING_LIST_stg DS
           SET NETTABLE_DGI_QTY =
                  (  NVL (
                        (SELECT SUM (QTY_ON_HAND)
                           FROM CRPADM.RC_INV_BTS_C3_MV INV
                          WHERE     LOCATION IN
                                       (SELECT MSTR.SUB_INVENTORY_LOCATION
                                          FROM CRPADM.RC_SUB_INV_LOC_MSTR MSTR
                                         WHERE     MSTR.INVENTORY_TYPE = 1
                                               AND MSTR.NETTABLE_FLAG = 1
                                               AND SUB_INVENTORY_ID IN
                                                      (SELECT SUB_INVENTORY_ID
                                                         FROM RC_SUB_INV_LOC_FLG_DTLS
                                                        WHERE IS_SCRAP = 'DGI'))
                                AND (   PART_NUMBER = DS.RF_PID
                                     OR PART_NUMBER = DS.CISCO_PRODUCT_NAME
                                     OR PART_NUMBER = DS.PRODUCT_SPARE_NAME
                                     OR PART_NUMBER = DS.EXCESS_NAME)
                                AND SITE NOT LIKE 'Z32%'),
                        0)
                   - NVL (
                        (SELECT SUM (ABS (TOTAL_RESERVATIONS))
                           FROM CRPADM.RC_INV_BTS_C3_MV INV
                          WHERE     (   LOCATION IN
                                           (SELECT MSTR.SUB_INVENTORY_LOCATION
                                              FROM CRPADM.RC_SUB_INV_LOC_MSTR MSTR
                                             WHERE     MSTR.INVENTORY_TYPE = 1
                                                   AND MSTR.NETTABLE_FLAG = 1
                                                   AND SUB_INVENTORY_ID IN
                                                          (SELECT SUB_INVENTORY_ID
                                                             FROM RC_SUB_INV_LOC_FLG_DTLS
                                                            WHERE IS_SCRAP = 'DGI'))
                                     OR LOCATION = 'DGI')
                                AND (   PART_NUMBER = DS.RF_PID
                                     OR PART_NUMBER = DS.CISCO_PRODUCT_NAME
                                     OR PART_NUMBER = DS.PRODUCT_SPARE_NAME
                                     OR PART_NUMBER = DS.EXCESS_NAME)
                                AND SITE NOT LIKE 'Z32%'),
                        0))
         WHERE STATUS = 'NEW' AND REFRESH_LIFE_CYCLE_NAME <> 'DEACTIVATED';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET BRIGHTLINE_CATEGORY =
                   (SELECT MAX (BRIGHTLINE_CATEGORY)
                      FROM crpsc.rc_brightline_products
                     WHERE     (   PART_NUMBER = DS.CISCO_PRODUCT_NAME
                                OR PART_NUMBER = DS.PRODUCT_SPARE_NAME)
                           AND status = 'ACTIVE')
          WHERE status = 'NEW';
   
         COMMIT;
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg ds
            SET nettable_dgi_qty = 0
          WHERE nettable_dgi_qty IS NULL AND STATUS = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET NETTABLE_FGI_QTY =
                   (SELECT ROUND (
                                SUM (NVL (QTY_ON_HAND, 0))
                              - SUM (ABS (NVL (QTY_RESERVED, 0)))
                              - SUM (ABS (NVL (ADDITIONAL_RESERVATIONS, 0))))
                      FROM RMKTGADM.RMK_SSOT_INVENTORY SI
                     WHERE     EXISTS
                                  (SELECT 1
                                     FROM CRPADM.RC_PRODUCT_MASTER RC
                                    WHERE     1 = 1
                                          AND UPPER (REFRESH_LIFE_CYCLE_NAME) <>
                                                 'DEACTIVATED'
                                          AND TRIM (SI.PART_NUMBER) =
                                                 TRIM (RC.REFRESH_PART_NUMBER))
                           AND SI.LOCATION = 'FG'
                           AND SI.SITE_CODE IN ('LRO', 'FVE')
                           AND (   DS.PRODUCT_NAME = SI.PART_NUMBER
                                OR NVL (ds.remarketing_name, ds.product_name) =
                                      si.part_number
                                OR NVL (DS.excess_name, ds.product_name) =
                                      si.part_number))
          WHERE status = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg ds
            SET nettable_fgi_qty = 0
          WHERE nettable_fgi_qty IS NULL AND STATUS = 'NEW';
   
         INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                      'CRPADM.RC_DEMAND_AUTOMATION',
                      'BEFORE INTRANSIT',
                      SYSDATE);
   
         COMMIT;
   
         UPDATE RC_DEMAND_SOURCING_LIST_STG DS
            SET IN_TRANSIT_POE =
                   (SELECT (CASE
                               WHEN NVL (ds.REMARKETING_NAME, ds.EXCESS_NAME)
                                       IS NOT NULL
                               THEN
                                  ROUND (
                                     SUM (
                                          pending_qty
                                        * NVL (
                                               RC_UTILITY.GET_REFURB_YIELD (
                                                  RC_UTILITY.GET_INVENTORY_ITEM_ID (
                                                     NVL (DS.REMARKETING_NAME,
                                                          DS.EXCESS_NAME)),
                                                  TO_ORG,
                                                  TO_SUBINVENTORY)
                                             / 100,
                                             0)))
                               ELSE
                                  SUM (pending_qty)
                            END)
                              INTRANSIT_QTY
                      FROM RMKTGADM.RC_INV_INTRANSIT_SHIPMENTS sh
                     WHERE     status_flag = 'Y'
                           AND from_org IN ('NL6',
                                            'HK4',
                                            'JP3',
                                            'U30')
                           AND to_org IN ('Z05', 'Z29')
                           --  AND to_subinventory LIKE '%POE%'
                           AND to_subinventory IN ('POE-NEW',
                                                   'POE-NEWX',
                                                   'POE-NRHS',
                                                   'POE-DGI') -- POE-MRB subinventory should not be considered for intransit poe
                           AND (part_number IN (DS.cisco_product_name,
                                                DS.product_spare_name,
                                                DS.remarketing_name,
                                                DS.excess_Name))),
                IN_TRANSIT_NIB =
                   (SELECT (CASE
                               WHEN NVL (DS.REMARKETING_NAME, DS.EXCESS_NAME)
                                       IS NOT NULL
                               THEN
                                  ROUND (
                                     SUM (
                                          pending_qty
                                        * NVL (
                                               RC_UTILITY.GET_REFURB_YIELD (
                                                  RC_UTILITY.GET_INVENTORY_ITEM_ID (
                                                     NVL (DS.REMARKETING_NAME,
                                                          DS.EXCESS_NAME)),
                                                  TO_ORG,
                                                  TO_SUBINVENTORY)
                                             / 100,
                                             0)))
                               ELSE
                                  SUM (pending_qty)
                            END)
                              INTRANSIT_QTY
                      FROM RMKTGADM.RC_INV_INTRANSIT_SHIPMENTS sh
                     WHERE     status_flag = 'Y'
                           AND from_org IN ('NL6',
                                            'HK4',
                                            'JP3',
                                            'U30')
                           AND to_org IN ('Z05', 'Z29')
                           AND to_subinventory IN ('POE-NEW',
                                                   'POE-NEWX',
                                                   'POE-NRHS')  --added by sneyadav PRB0061800 
                           AND (part_number IN (DS.cisco_product_name,
                                                DS.product_spare_name,
                                                DS.remarketing_name,
                                                DS.excess_Name))),
                IN_TRANSIT_DGI =
                   (SELECT (CASE
                               WHEN NVL (ds.REMARKETING_NAME, ds.EXCESS_NAME)
                                       IS NOT NULL
                               THEN
                                  ROUND (
                                     SUM (
                                          pending_qty
                                        * NVL (
                                               RC_UTILITY.GET_REFURB_YIELD (
                                                  RC_UTILITY.GET_INVENTORY_ITEM_ID (
                                                     NVL (DS.REMARKETING_NAME,
                                                          DS.EXCESS_NAME)),
                                                  TO_ORG,
                                                  TO_SUBINVENTORY)
                                             / 100,
                                             0)))
                               ELSE
                                  SUM (pending_qty)
                            END)
                              INTRANSIT_QTY
                      FROM RMKTGADM.RC_INV_INTRANSIT_SHIPMENTS sh
                     WHERE     status_flag = 'Y'
                           AND from_org IN ('NL6',
                                            'HK4',
                                            'JP3',
                                            'U30')
                           AND to_org IN ('Z05', 'Z29')
                           AND to_subinventory LIKE '%POE-DGI%'
                           AND (part_number IN (DS.cisco_product_name,
                                                DS.product_spare_name,
                                                DS.remarketing_name,
                                                DS.excess_Name)))
          WHERE EXISTS
                   (SELECT 1
                      FROM RMKTGADM.RC_INV_INTRANSIT_SHIPMENTS sh
                     WHERE     status_flag = 'Y'
                           AND from_org IN ('NL6',
                                            'HK4',
                                            'JP3',
                                            'U30')
                           AND to_org IN ('Z05', 'Z29')
                           AND to_subinventory LIKE '%POE%'
                           AND (part_number IN (DS.cisco_product_name,
                                                DS.product_spare_name,
                                                DS.remarketing_name,
                                                DS.excess_Name)));
   
         SELECT CONFIG_VALUE
           INTO lv_trans_percent
           FROM RC_DA_SETUP
          WHERE CONFIG_TYPE = 'INTRANSIT_PERCENTAGE';
   
         UPDATE RC_DEMAND_SOURCING_LIST_STG
            SET IN_TRANSIT_POE =
                   CEIL ( (NVL (IN_TRANSIT_POE, 0) * (lv_trans_percent / 100))),
                IN_TRANSIT_NIB =
                   CEIL ( (NVL (IN_TRANSIT_NIB, 0) * (lv_trans_percent / 100))),
                IN_TRANSIT_DGI =
                   CEIL ( (NVL (IN_TRANSIT_DGI, 0) * (lv_trans_percent / 100)));
   
   
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET TOTAL_NETTABLE_QTY = NETTABLE_DGI_QTY + NETTABLE_FGI_QTY
          WHERE status = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET TOTAL_NET_TRANSIT =
                   (CASE
                       WHEN BRIGHTLINE_CATEGORY LIKE '%BL+'
                       THEN
                          NETTABLE_DGI_QTY + NETTABLE_FGI_QTY
                       ELSE
                          NETTABLE_DGI_QTY + NETTABLE_FGI_QTY + IN_TRANSIT_POE
                    END)
          WHERE status = 'NEW';
   
         INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                      'CRPADM.RC_DEMAND_AUTOMATION',
                      'AFTER INTRANSIT',
                      SYSDATE);
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET UNIT_STD_COST_USD =
                   (SELECT UNIT_STD_COST_USD
                      FROM RC_PRODUCT_MASTER
                     WHERE REFRESH_PART_NUMBER = DS.PRODUCT_NAME)
          WHERE     EXISTS
                       (SELECT 1
                          FROM RC_PRODUCT_MASTER
                         WHERE REFRESH_PART_NUMBER = DS.PRODUCT_NAME)
                AND status = 'NEW';
   
   
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg ds
            SET CUR_SALES_UNITS =
                   RC_DEMAND_AUTOMATION.GET_SALES_DATA ('ROLLING',
                                                        ds.excess_name,
                                                        0,
                                                        ds.product_name),
                CUR_SALES_REVENUE =
                   RC_DEMAND_AUTOMATION.GET_SALES_DATA ('ROLLING_REV',
                                                        ds.excess_name,
                                                        0,
                                                        ds.product_name)
          WHERE status = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET BACKLOG =
                   get_qoh (ds.remarketing_name,
                            ds.cisco_product_name,
                            ds.product_spare_name,
                            'BACKLOG')
          WHERE status = 'NEW';
   
         COMMIT;
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg ds
            SET CISCO_INVENTORY_ITEM_ID =
                   RC_UTILITY.GET_INVENTORY_ITEM_ID (ds.cisco_product_name),
                SPARE_INVENTORY_ITEM_ID =
                   RC_UTILITY.GET_INVENTORY_ITEM_ID (ds.product_spare_name)
          WHERE STATUS = 'NEW';
   
         COMMIT;
   
         /*  UPDATE RC_DEMAND_SOURCING_LIST_STG ds
              SET unit_std_cost_usd =
                     (SELECT ROUND (d.item_cost, 2)             -- C3_UNIT_STD_COST
                        FROM CSF_mtl_system_items_b B,                 --@ctsprd b,
                                                      CSF_cst_item_costs D --@ctsprd d
                       WHERE     b.inventory_item_id = d.inventory_item_id
                             AND d.cost_type_id = 1
                             AND b.organization_id = d.organization_id
                             AND d.organization_id = 65274
                             AND (   b.inventory_item_id =
                                        ds.CISCO_INVENTORY_ITEM_ID
                                  OR b.inventory_item_id =
                                        ds.SPARE_INVENTORY_ITEM_ID)
                             AND ROWNUM = 1)
            WHERE     unit_std_cost_usd IS NULL
                  AND STATUS = 'NEW'
                  AND (CISCO_INVENTORY_ITEM_ID > 0 OR SPARE_INVENTORY_ITEM_ID > 0);  */
   
      UPDATE RC_DEMAND_SOURCING_LIST_STG ds
         SET unit_std_cost_usd =
                (SELECT ROUND (d.item_cost, 2)             -- C3_UNIT_STD_COST
                   FROM MTL_SYSTEM_ITEMS_S@CSFPRD_DBL.CISCO.COM b, --@ctsprd b,
                        CST_ITEM_COSTS_S@CSFPRD_DBL.CISCO.COM d
                  WHERE     b.inventory_item_id = d.inventory_item_id
                        AND d.cost_type_id = 1
                        AND b.organization_id = d.organization_id
                        AND d.organization_id = 900000000
                        AND (   b.inventory_item_id =
                                   ds.CISCO_INVENTORY_ITEM_ID
                             OR b.inventory_item_id =
                                   ds.SPARE_INVENTORY_ITEM_ID)
                        AND ROWNUM = 1)
       WHERE     unit_std_cost_usd IS NULL
             AND STATUS = 'NEW'
             AND (CISCO_INVENTORY_ITEM_ID > 0 OR SPARE_INVENTORY_ITEM_ID > 0); -- changed org id and pulled tables using DB link

   
         COMMIT;
   
         /*   UPDATE RC_DEMAND_SOURCING_LIST_stg ds
               SET unit_std_cost_usd =
                      (SELECT ROUND (d.item_cost, 2)             -- C3_UNIT_STD_COST
                         FROM CSF_mtl_system_items_b B,                 --@ctsprd b,
                                                       CSF_cst_item_costs D --@ctsprd d
                        WHERE     b.inventory_item_id = d.inventory_item_id
                              AND d.cost_type_id = 1
                              AND b.organization_id = d.organization_id
                              AND d.organization_id = 65274
                              AND b.segment1 =
                                     NVL (ds.REMARKETING_NAME, ds.EXCESS_NAME))
             WHERE unit_std_cost_usd IS NULL AND STATUS = 'NEW'; */
   
      UPDATE RC_DEMAND_SOURCING_LIST_stg ds
         SET unit_std_cost_usd =
                (SELECT ROUND (d.item_cost, 2)             -- C3_UNIT_STD_COST
                   FROM MTL_SYSTEM_ITEMS_S@CSFPRD_DBL.CISCO.COM b, --@ctsprd b,
                        CST_ITEM_COSTS_S@CSFPRD_DBL.CISCO.COM d    --@ctsprd d
                  WHERE     b.inventory_item_id = d.inventory_item_id
                        AND d.cost_type_id = 1
                        AND b.organization_id = d.organization_id
                        AND d.organization_id = 900000000
                        AND b.segment1 =
                               NVL (ds.REMARKETING_NAME, ds.EXCESS_NAME))
       WHERE unit_std_cost_usd IS NULL AND STATUS = 'NEW'; -- changed org id and pulled tables using DB link
   
   
         INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                      'CRPADM.RC_DEMAND_AUTOMATION',
                      'ASP',
                      SYSDATE);
   
         COMMIT;
   
         --To check the vv_adm_scrap_report reoprt ASP data
         UPDATE rc_demand_sourcing_list_stg ds
            SET asp = get_asp (ds.remarketing_name, ds.cisco_product_name)
          WHERE status = 'NEW';
   
   
         COMMIT;
   
         UPDATE rc_demand_sourcing_list_stg ds
            SET asp =
                   (CASE
                       WHEN NVL (GPL, 0) > 0 THEN GPL * 0.35
                       ELSE UNIT_STD_COST_USD
                    END)
          WHERE status = 'NEW' AND NVL (ASP, 0) = 0;
   
         INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                      'CRPADM.RC_DEMAND_AUTOMATION',
                      'ASP END',
                      SYSDATE);
   
         COMMIT;
   
   
         INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                      'CRPADM.RC_DEMAND_AUTOMATION',
                      'AFTER STDCOST',
                      SYSDATE);
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET total_reservations =
                   get_total_reservations (
                      DS.remarketing_name,
                      rc_utility.get_refresh_name (DS.PRODUCT_NAME, 'EXCESS'))
          WHERE     status = 'NEW'
                AND EXISTS
                       (SELECT 1
                          FROM RC_DEMAND_SOURCING_LIST_stg DL
                         WHERE DL.PRODUCT_NAME = DS.PRODUCT_NAME);
   
   
         COMMIT;
   
      UPDATE RC_DEMAND_SOURCING_LIST_stg ds
         SET EOS =
                (CASE
                    WHEN EXISTS
                            (SELECT 1
                               FROM RC_PRODUCT_MASTER
                              WHERE REFRESH_PART_NUMBER = ds.PRODUCT_NAME)
                    THEN
                       (SELECT MFG_EOS_DATE
                          FROM RC_PRODUCT_MASTER
                         WHERE REFRESH_PART_NUMBER = ds.PRODUCT_NAME)
                    WHEN EXISTS
                            (SELECT 1
                               FROM rmktgadm.rmk_cisco_product_master
                              WHERE product_id = ds.cisco_product_name)
                    THEN
                       (SELECT eo_last_support_date
                          FROM rmktgadm.rmk_cisco_product_master
                         WHERE product_id = ds.cisco_product_name)
                    WHEN EXISTS
                            (SELECT 1
                               FROM xxesc_rscm_eol_pid_v@RC_ESCPRD
                              WHERE     pid = ds.cisco_product_name
                                    AND active_flag = 'Y')
                    THEN
                       (SELECT eo_last_support_date
                          FROM xxesc_rscm_eol_pid_v@RC_ESCPRD
                         WHERE     pid = ds.cisco_product_name
                               AND active_flag = 'Y')
                    ELSE
                       NULL
                 END)
       WHERE status = 'NEW';
   
         UPDATE rc_demand_sourcing_list_Stg ds
            SET product_life_cycle =
                   (CASE WHEN SYSDATE > DS.EOS THEN 'EOM' ELSE NULL END)
          WHERE status = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
      SET NETTABLE_MOS =
             CASE
                WHEN (    (NVL (cur_sales_units, 0) + NVL (ABS (BACKLOG), 0)) >
                             0
                      AND total_nettable_qty > 0
                      AND (( (cur_sales_units + ABS (BACKLOG)) / 13) > 1 OR ( (cur_sales_units + ABS (BACKLOG)) / 13) = 1))
                THEN
                   ROUND (
                        (total_nettable_qty)
                      / ( (cur_sales_units + ABS (BACKLOG)) / 13))
                WHEN (    (NVL (cur_sales_units, 0) + NVL (ABS (BACKLOG), 0)) >
                             0
                      AND total_nettable_qty > 0
                      AND (    ( (cur_sales_units + ABS (BACKLOG)) / 13) > 0
                           AND ( (cur_sales_units + ABS (BACKLOG)) / 13) < 1))
                THEN
                   ROUND ( (total_nettable_qty))
                ELSE
                   0
             END
    WHERE     status = 'NEW'
          AND EXISTS
                 (SELECT 1
                    FROM RC_DEMAND_SOURCING_LIST_stg DL
                   WHERE DL.PRODUCT_NAME = DS.PRODUCT_NAME);
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET MOS_BANDS =
                   RC_DEMAND_AUTOMATION.GET_MOS_BANDS (EOS,
                                                       cur_sales_units,
                                                       mos),
                NETTABLE_MOS_BANDS =
                   RC_DEMAND_AUTOMATION.GET_MOS_BANDS (EOS,
                                                       cur_sales_units,
                                                       nettable_mos)
          WHERE STATUS = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET mos_bands = 'No Sales without SKU'
          WHERE     (mos IS NULL OR NVL (cur_sales_units, 0) = 0)
                AND (REMARKETING_NAME IS NULL)
                AND mos_bands <> 'LDOS'
                AND STATUS = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET NETTABLE_MOS_BANDS = 'No Sales without SKU'
          WHERE     (nettable_mos IS NULL OR NVL (cur_sales_units, 0) = 0)
                AND (REMARKETING_NAME IS NULL)
                AND NETTABLE_MOS_BANDS <> 'LDOS'
                AND STATUS = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET DGI =
                   RC_DEMAND_AUTOMATION.GET_INV_DATA ('DGI',
                                                      ds.remarketing_name,
                                                      ds.cisco_product_name,
                                                      ds.product_spare_name,
                                                      source_type),
                FGI =
                   RC_DEMAND_AUTOMATION.GET_INV_DATA ('FG',
                                                      ds.remarketing_name,
                                                      ds.cisco_product_name,
                                                      ds.product_spare_name,
                                                      source_type),
                WIP =
                   RC_DEMAND_AUTOMATION.GET_INV_DATA ('WIP',
                                                      ds.remarketing_name,
                                                      ds.cisco_product_name,
                                                      ds.product_spare_name,
                                                      source_type),
                NIB =
                   RC_DEMAND_AUTOMATION.GET_INV_DATA ('NIB',
                                                      ds.remarketing_name,
                                                      ds.cisco_product_name,
                                                      ds.product_spare_name,
                                                      source_type),
                TOTAL_QTY =
                   RC_DEMAND_AUTOMATION.GET_INV_DATA ('TOTAL',
                                                      ds.remarketing_name,
                                                      ds.cisco_product_name,
                                                      ds.product_spare_name,
                                                      source_type),
                CONS_QTY =
                   RC_DEMAND_AUTOMATION.GET_INV_DATA ('CONS',
                                                      ds.remarketing_name,
                                                      ds.cisco_product_name,
                                                      ds.product_spare_name,
                                                      source_type)
          WHERE status = 'NEW';
   
         COMMIT;
   
   
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET CONS_PERCENTAGE =
                   (CASE
                       WHEN NVL (TOTAL_QTY, 0) > 0
                       THEN
                          ROUND ( (CONS_QTY / TOTAL_QTY) * 100, 2)
                       ELSE
                          0
                    END)
          WHERE status = 'NEW';
   
   
   
         COMMIT;
   
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg T
            SET NEW_PID_FLAG =
                   (CASE
                       WHEN    (    REFRESH_LIFE_CYCLE_NAME IN ('NPI', 'CUR')
                                AND R12_SALES = 0
                                AND TOTAL_QTY = 0)
                            OR (    (TOTAL_QTY = 0 OR SOURCE_TYPE = 'WWRL')
                                AND MOS_BANDS LIKE 'No Sales without SKU')
                       THEN
                          'Y'
                       ELSE
                          'N'
                    END)
          WHERE status = 'NEW';
   
         COMMIT;
   
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET PRODUCT_TYPE =
                   RC_DEMAND_AUTOMATION.get_product_type (PRODUCT_SPARE_NAME,
                                                          PRODUCT_NAME,
                                                          CISCO_PRODUCT_NAME)
          WHERE status = 'NEW';
   
   
   
         COMMIT;
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET (QUOTE_QTY) =
                   (SELECT SUM (QUANTITY_REQUESTED)
                      FROM rmktgadm.rmk_ssot_transactions
                     WHERE     product_id = DS.PRODUCT_NAME
                           AND (    transaction_type = 'QUOTE'
                                AND UPPER (quote_status) IN ('APPROVAL IN PROGRESS',
                                                             'APPROVED',
                                                             'APPROVED NOT READY TO ORDER',
                                                             'MORE INFORMATION REQUIRED',
                                                             'MORE INFORMATION REQUIRED-BOM',
                                                             'QUALIFICATION IN PROGRESS',
                                                             'QUALIFIED',
                                                             'RE-OPENED')
                                AND UPPER (RESERVATION_STATUS) = 'ACTIVE'))
          WHERE status = 'NEW';
   
         COMMIT;
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET (ORDER_QTY) =
                   (SELECT SUM (QUANTITY_TO_SHIP)
                      FROM rmktgadm.rmk_ssot_transactions
                     WHERE     product_id = DS.PRODUCT_NAME
                           AND (    UPPER (TRANSACTION_TYPE) IN ('WEB_ORDER',
                                                                 'STANDALONE_ORDER')
                                AND UPPER (RESERVATION_STATUS) = 'ACTIVE'
                                AND UPPER (ORDER_TYPE) <> 'OUTLET'
                                AND WEB_ORDER_ID IS NOT NULL
                                AND UPPER (WEB_ORDER_STATUS) != 'CANCELLED'
                                AND (UPPER (NVL (SO_LINE_STATUS, 'NULL'))) NOT IN ('IFS_SHIPPED',
                                                                                   'INVOICE_ELIGIBLE',
                                                                                   'CISCOSHIPPED',
                                                                                   'CANCELLED',
                                                                                   'IFS_SHIPMENT_ERROR')))
          WHERE status = 'NEW';
   
         COMMIT;
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET ORDER_QTY = 0
          WHERE ORDER_QTY IS NULL;
   
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET QUOTE_QTY = 0
          WHERE QUOTE_QTY IS NULL;
   
   
   
      UPDATE RC_DEMAND_SOURCING_LIST_stg DS
         SET BUSINESS_UNIT =
                (SELECT DISTINCT BUSINESS_UNIT
                   FROM CG1_CMF_PT_BUSINESS_UNITS@RC_ODSPROD
                  WHERE BUSINESS_UNIT_ID =
                           (SELECT BUSINESS_UNIT_ID
                              FROM CG1_CMF_PT_PRODUCT_FAMILI@RC_ODSPROD
                             WHERE PRODUCT_FAMILY = DS.PRODUCT_FAMILY))
       WHERE BUSINESS_UNIT IS NULL AND status = 'NEW';
   
         /*  UPDATE RC_DEMAND_SOURCING_LIST_stg
              SET BUSINESS_UNIT =
                     (SELECT BUSINESS_UNIT
                        FROM RC_PRODUCT_MASTER
                       WHERE REFRESH_PART_NUMBER = PRODUCT_NAME)
            WHERE     EXISTS
                         (SELECT 1
                            FROM RC_PRODUCT_MASTER
                           WHERE REFRESH_PART_NUMBER = PRODUCT_NAME)
                  AND status = 'NEW';
   
           COMMIT;*/
   
   
         --      UPDATE RC_DEMAND_SOURCING_LIST
         --         SET PRODUCT_DESCRIPTION =
         --                (SELECT DESCRIPTION
         --                   FROM RC_PRODUCT_MASTER
         --                  WHERE REFRESH_PART_NUMBER = PRODUCT_NAME)
         --       WHERE     EXISTS
         --                    (SELECT 1
         --                       FROM RC_PRODUCT_MASTER
         --                      WHERE REFRESH_PART_NUMBER = PRODUCT_NAME)
         --             AND status = 'NEW';
   
         COMMIT;
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET PRODUCT_description =
                   RC_DEMAND_AUTOMATION.get_product_description (
                      PRODUCT_SPARE_NAME,
                      PRODUCT_NAME,
                      CISCO_PRODUCT_NAME)
          WHERE status = 'NEW';
   
   
   
         SELECT CONFIG_VALUE
           INTO lv_asp
           FROM RC_DA_SETUP
          WHERE config_type = 'ASP';
   
         INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                      'CRPADM.RC_DEMAND_AUTOMATION',
                      'DB LINK UPDATE START',
                      SYSDATE);
   
         COMMIT;
   
         /*Include Item Type for “SPARE” ,”ATO MODEL”* Bhaskar
         UPDATE RC_DEMAND_SOURCING_LIST_STG
            SET ITEM_TYPE =
                   (SELECT DISTINCT CGL.ITEM_TYPE
                      FROM CG1_MTL_SYSTEM_ITEMS_B@RC_ODSPROD CGL
                     WHERE     (INVENTORY_ITEM_ID =
                                   CASE
                                      WHEN NVL (CISCO_INVENTORY_ITEM_ID, 0) = 0
                                      THEN
                                         SPARE_INVENTORY_ITEM_ID
                                      ELSE
                                         CISCO_INVENTORY_ITEM_ID
                                   END)
                           AND ORGANIZATION_ID = 1);
   
   UPDATE RC_DEMAND_SOURCING_LIST_STG ST
            SET ITEM_TYPE =
                   (SELECT DISTINCT CGL.ITEM_TYPE
                      FROM CG1_MTL_SYSTEM_ITEMS_B@RC_ODSPROD CGL
                     WHERE     (   SEGMENT1 = ST.CISCO_PRODUCT_NAME
                                OR SEGMENT1 = ST.PRODUCT_SPARE_NAME
                                OR SEGMENT1 = ST.PRODUCT_NAME)
                           AND ROWNUM = 1)
          WHERE ITEM_TYPE IS NULL;*/
   
      SELECT DISTINCT ST.PRODUCT_NAME, A.ITEM_TYPE
        BULK COLLECT INTO lv_list
        FROM CG1_MTL_SYSTEM_ITEMS_B@RC_ODSPROD A,
             RC_DEMAND_SOURCING_LIST_STG ST           --@RC_CG1PRD.CISCO.COM A
       WHERE (   SEGMENT1 = ST.CISCO_PRODUCT_NAME
              OR SEGMENT1 = ST.PRODUCT_SPARE_NAME
              OR SEGMENT1 = ST.PRODUCT_NAME);
   
         FORALL IDX IN lv_list.FIRST .. lv_list.LAST
            UPDATE RC_DEMAND_SOURCING_LIST_STG ST
               SET ITEM_TYPE = lv_list (idx).val
             WHERE ST.PRODUCT_NAME = lv_list (idx).product_name;
   
         COMMIT;
   
         /* UPDATE RC_demand_sourcing_list_stg st
             SET ITEM_TYPE =
                    (SELECT ITEM_TYPE
                       FROM RC_DEMAND_SOURCING_LIST_STG_BK -- XXITEMHUB.XXITM_PID_CATEGORY_OT_TEST@RC_CG1PRD.CISCO.com
                      WHERE PRODUCT_NAME = ST.product_name);*/
   
         /*Include Item category for (“Hardware Products”,” Non IOS Software” )( Demand only Hardware Products) Bhaskar*/
         /*UPDATE RC_DEMAND_SOURCING_LIST_STG st
                SET ST.ITEM_CATALOG_CATEGORY =
                       (SELECT DISTINCT A.ITEM_CATALOG_CATEGORY
                          FROM APPS.XXITM_UDA_DETAILS_TB@RC_CG1PRD.CISCO.COM A
                         WHERE     A.INVENTORY_ITEM_ID =
                                      (CASE
                                          WHEN NVL (ST.CISCO_INVENTORY_ITEM_ID, 0) =
                                                  0
                                          THEN
                                             ST.SPARE_INVENTORY_ITEM_ID
                                          ELSE
                                             ST.CISCO_INVENTORY_ITEM_ID
                                       END)
                               AND ST.CISCO_PRODUCT_NAME = A.ITEM_NAME);
             COMMIT; */
   
         SELECT DISTINCT ST.PRODUCT_NAME, A.ITEM_CATALOG_CATEGORY
           BULK COLLECT INTO lv_list
           FROM XXITM_UDA_DETAILS_TB A, RC_DEMAND_SOURCING_LIST_STG ST --@RC_CG1PRD.CISCO.COM A
          WHERE (   ITEM_NAME = ST.CISCO_PRODUCT_NAME
                 OR ITEM_NAME = ST.PRODUCT_SPARE_NAME
                 OR ITEM_NAME = ST.PRODUCT_NAME);
   
   
         FORALL IDX IN lv_list.FIRST .. lv_list.LAST
            UPDATE RC_DEMAND_SOURCING_LIST_STG ST
               SET ST.ITEM_CATALOG_CATEGORY = lv_list (idx).val
             WHERE ST.PRODUCT_NAME = lv_list (idx).product_name;
   
         /*   UPDATE RC_DEMAND_SOURCING_LIST_STG ST
               SET ST.ITEM_CATALOG_CATEGORY =
                      (SELECT A.ITEM_CATALOG_CATEGORY
                         FROM XXITM_UDA_DETAILS_TB A        --@RC_CG1PRD.CISCO.COM A
                        WHERE     A.INVENTORY_ITEM_ID =
                                     DECODE (ST.CISCO_INVENTORY_ITEM_ID,
                                             0, ST.SPARE_INVENTORY_ITEM_ID,
                                             ST.CISCO_INVENTORY_ITEM_ID)
                              AND ST.CISCO_PRODUCT_NAME = A.ITEM_NAME
                              AND ROWNUM = 1);*/
   
   
         COMMIT;
   
         /*Added PID_CATEGORY to the demand report Bhaskar*/
         UPDATE RC_demand_sourcing_list_stg
            SET PID_CATEGORY =
                   (SELECT PID_CATEGORY
                      FROM XXITEMHUB.XXITM_PID_CATEGORY_OT_TEST@RC_CG1PRD.CISCO.com
                     WHERE     inventory_item_id =
                                  (CASE
                                      WHEN     NVL (CISCO_INVENTORY_ITEM_ID, 0) =
                                                  0
                                           AND NVL (SPARE_INVENTORY_ITEM_ID, 0) >
                                                  0
                                      THEN
                                         SPARE_INVENTORY_ITEM_ID
                                      ELSE
                                         CISCO_INVENTORY_ITEM_ID
                                   END)
                           AND inventory_item_id > 0
                           AND ROWNUM = 1);
   
   
         /*Added PID_CATEGORY to the demand report Bhaskar*/
         UPDATE RC_demand_sourcing_list_stg ds
            SET PID_CATEGORY =
                   (SELECT PID_CATEGORY
                      FROM XXITEMHUB.XXITM_PID_CATEGORY_OT_TEST@RC_CG1PRD.CISCO.com
                     WHERE     (   ITEM_NAME = DS.CISCO_PRODUCT_NAME
                                OR ITEM_NAME = DS.PRODUCT_SPARE_NAME
                                OR ITEM_NAME = DS.PRODUCT_NAME)
                           AND ROWNUM = 1)
          WHERE PID_CATEGORY IS NULL;
   
         /*UPDATE RC_demand_sourcing_list_stg st
            SET PID_CATEGORY =
                   (SELECT PID_CATEGORY
                      FROM RC_DEMAND_SOURCING_LIST_STG_BK -- XXITEMHUB.XXITM_PID_CATEGORY_OT_TEST@RC_CG1PRD.CISCO.com
                     WHERE PRODUCT_NAME = ST.product_name);*/
   
         INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                      'CRPADM.RC_DEMAND_AUTOMATION',
                      'DB LINK UPDATE END',
                      SYSDATE);
   
         COMMIT;
   
         --Step 2: Update not to demand flag based on the ASP and  EOM--
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET not_to_demand_flag = 'Y',
                INCLUDE_OR_EXCLUDE = 'EXCLUDE',
                INCLUDE_OR_EXCLUDE_REASON =
                   (CASE
                       WHEN        ASP < lv_asp
                               AND (    NEW_PID_FLAG = 'Y'
                                    AND REMARKETING_NAME IS NULL
                                    AND EXCESS_NAME IS NULL)
                            OR (    REMARKETING_NAME IS NULL
                                AND EXCESS_NAME IS NULL
                                AND TOTAL_QTY + NVL (IN_TRANSIT_POE, 0) > 0
                                AND ASP < lv_asp)
                       THEN
                          'ASP validation failed'
                       WHEN BUSINESS_UNIT = 'TPMBU'
                       THEN
                          'TPMBU Business Unit'
                       WHEN BUSINESS_UNIT = 'CNGBU'
                       THEN
                          'CNGBU Business Unit'
                       WHEN PRODUCT_FAMILY = 'CISCO'
                       THEN
                          'CISCO Product Family'
                       WHEN PRODUCT_FAMILY IN ('TBA')
                       THEN
                          'TBA Product Family'
                       WHEN PRODUCT_DESCRIPTION LIKE '%Meraki%'
                       THEN
                          'Meraki Products'
                       WHEN PRODUCT_NAME LIKE 'MISC%'
                       THEN
                          'Misc Products'
                       WHEN     product_type IN (UPPER ('cable'),
                                                 UPPER ('accessory'))
                            AND NOT EXISTS
                                       (SELECT DISTINCT PRODUCT_ID
                                          FROM RC_INCLUDE_PID_LIST
                                         WHERE     TO_DATE (effective_to_date,
                                                            'DD/MM/RR') >=
                                                      TRUNC (SYSDATE)
                                               AND (   PRODUCT_ID =
                                                          DS.PRODUCT_NAME
                                                    OR PRODUCT_ID =
                                                          DS.CISCO_PRODUCT_NAME
                                                    OR PRODUCT_ID =
                                                          DS.PRODUCT_SPARE_NAME))
                       THEN
                          'Cable or Accessory'
                       WHEN     REFRESH_LIFE_CYCLE_NAME IN ('EOL')
                            AND NETTABLE_MOS >
                                   ROUND (MONTHS_BETWEEN (EOS, SYSDATE))
                            AND NVL (brightline_category, 'NA') NOT LIKE '%BL+'
                       THEN
                          'NMOS greater than Months to EOS'
                       WHEN    (    REFRESH_LIFE_CYCLE_NAME IS NULL
                                AND TRUNC (ADD_MONTHS (EOS, -12)) <=
                                       TRUNC (SYSDATE))
                            OR (    UPPER (TRIM (REFRESH_LIFE_CYCLE_NAME)) IN ('EOS',
                                                                               'EOL',
                                                                               'DEACTIVATED')
                                AND (NVL (brightline_category, 'NA') NOT LIKE
                                        '%BL+'))
                       THEN
                          'T-12'
                       WHEN product_life_cycle = 'EOM'
                       THEN
                          'End of Support'
                       WHEN BLOCKED_PID_FROM IN ('PP,DA', 'DA')
                       THEN
                          'Blocked PID'
                       WHEN        PID_CATEGORY NOT IN ('Hardware',
                                                        'HW Embedded with SW')
                               AND ITEM_CATALOG_CATEGORY NOT IN ('Hardware Products',
                                                                 'Non IOS Software')
                               AND (    PID_CATEGORY IS NOT NULL
                                    AND ITEM_CATALOG_CATEGORY IS NOT NULL)
                            OR (    PID_CATEGORY IS NULL
                                AND (   ITEM_CATALOG_CATEGORY IN ('License',
                                                                  'Non IOS Software')
                                     OR ITEM_CATALOG_CATEGORY LIKE '%Software%'))
                       THEN
                          'Software Products'
                       WHEN NETTABLE_MOS > 12
                       THEN
                          'NMos greater than 12'
                    END)
          WHERE    (   (       asp < lv_asp
                           AND (    NEW_PID_FLAG = 'Y'
                                AND REMARKETING_NAME IS NULL
                                AND EXCESS_NAME IS NULL)
                        OR (    REMARKETING_NAME IS NULL
                            AND EXCESS_NAME IS NULL
                            AND TOTAL_QTY + NVL (IN_TRANSIT_POE, 0) > 0
                            AND ASP < lv_asp))
                    OR product_life_cycle = 'EOM'
                    OR BUSINESS_UNIT IN ('TPMBU', 'CNGBU')
                    OR PRODUCT_FAMILY = 'CISCO'
                    OR (    UPPER (product_type) IN (UPPER ('cable'),
                                                     UPPER ('accessory'))
                        AND NOT EXISTS
                                   (SELECT DISTINCT PRODUCT_ID
                                      FROM RC_INCLUDE_PID_LIST
                                     WHERE     TO_DATE (effective_to_date,
                                                        'DD/MM/RR') >=
                                                  TRUNC (SYSDATE)
                                           AND (   PRODUCT_ID = DS.PRODUCT_NAME
                                                OR PRODUCT_ID =
                                                      DS.CISCO_PRODUCT_NAME
                                                OR PRODUCT_ID =
                                                      DS.PRODUCT_SPARE_NAME)))
                    OR nettable_mos > 12
                    OR PRODUCT_DESCRIPTION LIKE '%Meraki%'
                    OR PRODUCT_NAME LIKE 'MISC%'
                    OR (   (    REFRESH_LIFE_CYCLE_NAME IS NULL
                            AND TRUNC (ADD_MONTHS (EOS, -12)) <= TRUNC (SYSDATE))
                        OR (    UPPER (TRIM (REFRESH_LIFE_CYCLE_NAME)) IN ('EOS',
                                                                           'EOL',
                                                                           'DEACTIVATED')
                            AND (NVL (brightline_category, 'NA') NOT LIKE '%BL+'))
                        OR (    REFRESH_LIFE_CYCLE_NAME IN ('EOL')
                            AND NETTABLE_MOS >
                                   ROUND (MONTHS_BETWEEN (EOS, SYSDATE))
                            AND NVL (brightline_category, 'NA') NOT LIKE '%BL+'
                            AND EOS IS NOT NULL))
                    OR BLOCKED_PID_FROM IN ('PP,DA', 'DA'))
                OR PRODUCT_FAMILY = 'TBA'
                OR     (       PID_CATEGORY NOT IN ('Hardware',
                                                    'HW Embedded with SW')
                           AND ITEM_CATALOG_CATEGORY NOT IN ('Hardware Products',
                                                             'Non IOS Software')
                           AND (    PID_CATEGORY IS NOT NULL
                                AND ITEM_CATALOG_CATEGORY IS NOT NULL)
                        OR (    PID_CATEGORY IS NULL
                            AND (   ITEM_CATALOG_CATEGORY IN ('License',
                                                              'Non IOS Software')
                                 OR ITEM_CATALOG_CATEGORY LIKE '%Software%')))
                   AND STATUS = 'NEW';
   
         COMMIT;
   
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET INCLUDE_OR_EXCLUDE = 'INCLUDE'
          WHERE EXISTS
                   (SELECT 1
                      FROM RC_INCLUDE_PID_LIST
                     WHERE     TO_DATE (effective_to_date, 'DD/MM/RR') >=
                                  TRUNC (SYSDATE)
                           AND (   PRODUCT_ID = DS.PRODUCT_NAME
                                OR PRODUCT_ID = DS.CISCO_PRODUCT_NAME
                                OR PRODUCT_ID = DS.PRODUCT_SPARE_NAME));
   
         COMMIT;
   
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET INCLUDE_OR_EXCLUDE = 'EXCLUDE'
          WHERE EXISTS
                   (SELECT 1
                      FROM RC_EXCLUDE_PID_LIST
                     WHERE (   PRODUCT_ID = DS.PRODUCT_NAME
                            OR PRODUCT_ID = DS.CISCO_PRODUCT_NAME
                            OR PRODUCT_ID = DS.PRODUCT_SPARE_NAME));
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET NOT_TO_DEMAND_FLAG = 'Y',
                INCLUDE_OR_EXCLUDE_REASON = 'Excluded by User'
          WHERE     INCLUDE_OR_EXCLUDE = 'EXCLUDE'
                AND INCLUDE_OR_EXCLUDE_REASON IS NULL
                AND STATUS = 'NEW'
                AND EXISTS
                       (SELECT 1
                          FROM RC_EXCLUDE_PID_LIST
                         WHERE    PRODUCT_ID = DS.PRODUCT_NAME
                               OR PRODUCT_ID = DS.CISCO_PRODUCT_NAME
                               OR PRODUCT_ID = DS.PRODUCT_SPARE_NAME);
   
         COMMIT;
   
   
         --Step 3: Settting Storage max to the products--
         /*  UPDATE RC_DEMAND_SOURCING_LIST_stg ds
              SET wpm_quantity =
                     (SELECT SUM (fdt.current_max)
                        FROM crpsc.rc_forecasting_cumulative fdt
                       WHERE refresh_part_number IN (ds.remarketing_name,
                                                     REPLACE (ds.remarketing_name,
                                                              '-RF',
                                                              '-WS')))
            WHERE not_to_demand_flag = 'N' AND status = 'NEW';*/
   
   
         /*      UPDATE RC_DEMAND_SOURCING_LIST_stg
                  SET storage_max = wpm_quantity * 4
                WHERE not_to_demand_flag = 'N' AND STATUS = 'NEW';
   
               --Update storage Max value for the products to a minimum of 100--
               UPDATE RC_DEMAND_SOURCING_LIST_stg
                  SET storage_max = 100
                WHERE storage_max IS NULL OR storage_max < 100 AND STATUS = 'NEW';*/
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET FCS =
                   (CASE
                       WHEN SOURCE_TYPE = 'RSCM'
                       THEN
                          (SELECT MFG_FCS_DATE
                             FROM CRPADM.RC_PRODUCT_MASTER
                            WHERE DS.PRODUCT_NAME = REFRESH_PART_NUMBER)
                       ELSE
                          (SELECT MIN (FCS_DATE)
                             FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                            WHERE (   PRODUCT_ID = DS.PRODUCT_NAME
                                   OR PRODUCT_ID = DS.CISCO_PRODUCT_NAME
                                   OR PRODUCT_ID = DS.PRODUCT_SPARE_NAME))
                    END)
          WHERE status = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_STG DS
            SET FCS = RMKTGADM.GET_FCS_DATE (DS.CISCO_PRODUCT_NAME)
          WHERE STATUS = 'NEW' AND FCS IS NULL;
   
         UPDATE RC_DEMAND_SOURCING_LIST_STG DS
            SET FCS = RMKTGADM.GET_FCS_DATE (DS.PRODUCT_SPARE_NAME)
          WHERE STATUS = 'NEW' AND FCS IS NULL;
   
         UPDATE RC_DEMAND_SOURCING_LIST_STG DS
            SET FCS = RMKTGADM.GET_FCS_DATE (DS.REMARKETING_NAME)
          WHERE STATUS = 'NEW' AND FCS IS NULL;
   
         UPDATE RC_DEMAND_SOURCING_LIST_STG DS
            SET FCS = RMKTGADM.GET_FCS_DATE (DS.EXCESS_NAME)
          WHERE STATUS = 'NEW' AND FCS IS NULL;
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET STORAGE_MAX =
                   (SELECT CONFIG_VALUE
                      FROM RC_DA_SETUP
                     WHERE config_type = 'ASP')
          WHERE NEW_PID_FLAG = 'Y' AND status = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET REPAIR_METHOD =
                   (CASE
                       WHEN UPPER (REFRESH_LIFE_CYCLE_NAME) NOT LIKE
                               'DEACTIVATED'
                       THEN
                          (SELECT CNFG.CONFIG_NAME
                             FROM CRPADM.RC_PRODUCT_CONFIG CNFG
                            WHERE     CNFG.CONFIG_TYPE = 'REFRESH_METHOD'
                                  AND CNFG.CONFIG_ID =
                                         (SELECT MIN (REFRESH_METHOD_ID)
                                            FROM (SELECT *
                                                    FROM CRPADM.RC_PRODUCT_REPAIR_SETUP RS
                                                   WHERE     RS.REFRESH_PART_NUMBER =
                                                                DS.REMARKETING_NAME
                                                         AND REFRESH_STATUS =
                                                                'ACTIVE')))
                       ELSE
                          (SELECT CNFG.CONFIG_NAME
                             FROM CRPADM.RC_PRODUCT_CONFIG CNFG
                            WHERE     CNFG.CONFIG_TYPE = 'REFRESH_METHOD'
                                  AND CNFG.CONFIG_ID =
                                         (SELECT MIN (REFRESH_METHOD_ID)
                                            FROM (SELECT *
                                                    FROM CRPADM.RC_PRODUCT_REPAIR_SETUP RS
                                                   WHERE RS.REFRESH_PART_NUMBER =
                                                            DS.REMARKETING_NAME)))
                    END)
          WHERE STATUS = 'NEW' AND REMARKETING_NAME IS NOT NULL;
   
   
         /* Show inactive retail repair method for NPI PID’s Bhaskar.*/
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET REPAIR_METHOD =
                   (SELECT CNFG.CONFIG_NAME
                      FROM CRPADM.RC_PRODUCT_CONFIG CNFG
                     WHERE     CNFG.CONFIG_TYPE = 'REFRESH_METHOD'
                           AND CNFG.CONFIG_ID =
                                  (SELECT MIN (REFRESH_METHOD_ID)
                                     FROM (SELECT *
                                             FROM CRPADM.RC_PRODUCT_REPAIR_SETUP RS
                                            WHERE     RS.REFRESH_PART_NUMBER =
                                                         DS.PRODUCT_NAME
                                                  AND REFRESH_STATUS =
                                                         'INACTIVE')))
          WHERE     STATUS = 'NEW'
                AND REFRESH_LIFE_CYCLE_NAME = 'NPI'
                AND REPAIR_METHOD IS NULL;
   
         COMMIT;
   
         --      UPDATE RC_DEMAND_SOURCING_LIST
         --         SET SERVICE_REPAIR_FLAG =
         --                CASE WHEN REPAIR_METHOD = 'REPAIR' THEN 'Y' ELSE '-' END
         --       WHERE STATUS = 'NEW';
         -- Step 4: Update Demand max quantity based on the On hand quantity and Storage max value--
   
         --      UPDATE rc_demand_sourcing_list
         --         SET demand_qty = (storage_max - NVL (qty_on_hand, 0))
         --       WHERE not_to_demand_flag = 'N' AND status = 'NEW';
   
   
         INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                      'CRPADM.RC_DEMAND_AUTOMATION',
                      'NEW UPDATES',
                      SYSDATE);
   
         COMMIT;
   
   
   
         --Revenue bands
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET REVENUE_BANDS = 'Top 50'
          WHERE     CUR_SALES_REVENUE IN (SELECT CUR_SALES_REVENUE
                                            FROM (SELECT CUR_SALES_REVENUE,
                                                         ROWNUM rnum
                                                    FROM (  SELECT *
                                                              FROM RC_DEMAND_SOURCING_LIST_stg
                                                             WHERE CUR_SALES_REVENUE >
                                                                      0
                                                          ORDER BY CUR_SALES_REVENUE DESC)
                                                         A
                                                   WHERE ROWNUM <= 50)
                                           WHERE rnum >= 1)
                AND status = 'NEW';
   
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET REVENUE_BANDS = 'Top 50-100'
          WHERE     CUR_SALES_REVENUE IN (SELECT CUR_SALES_REVENUE
                                            FROM (SELECT CUR_SALES_REVENUE,
                                                         ROWNUM rnum
                                                    FROM (  SELECT *
                                                              FROM RC_DEMAND_SOURCING_LIST_stg
                                                             WHERE CUR_SALES_REVENUE >
                                                                      0
                                                          ORDER BY CUR_SALES_REVENUE DESC)
                                                         A
                                                   WHERE ROWNUM <= 100)
                                           WHERE rnum >= 51)
                AND status = 'NEW';
   
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET REVENUE_BANDS = 'Top 100-300'
          WHERE     CUR_SALES_REVENUE IN (SELECT CUR_SALES_REVENUE
                                            FROM (SELECT CUR_SALES_REVENUE,
                                                         ROWNUM rnum
                                                    FROM (  SELECT *
                                                              FROM RC_DEMAND_SOURCING_LIST_stg
                                                             WHERE CUR_SALES_REVENUE >
                                                                      0
                                                          ORDER BY CUR_SALES_REVENUE DESC)
                                                         A
                                                   WHERE ROWNUM <= 300)
                                           WHERE rnum >= 101)
                AND status = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET REVENUE_BANDS = 'Top 300-500'
          WHERE     CUR_SALES_REVENUE IN (SELECT CUR_SALES_REVENUE
                                            FROM (SELECT CUR_SALES_REVENUE,
                                                         ROWNUM rnum
                                                    FROM (  SELECT *
                                                              FROM RC_DEMAND_SOURCING_LIST_stg
                                                             WHERE CUR_SALES_REVENUE >
                                                                      0
                                                          ORDER BY CUR_SALES_REVENUE DESC)
                                                         A
                                                   WHERE ROWNUM <= 500)
                                           WHERE rnum >= 301)
                AND status = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET REVENUE_BANDS = 'Top 500-750'
          WHERE     CUR_SALES_REVENUE IN (SELECT CUR_SALES_REVENUE
                                            FROM (SELECT CUR_SALES_REVENUE,
                                                         ROWNUM rnum
                                                    FROM (  SELECT *
                                                              FROM RC_DEMAND_SOURCING_LIST_stg
                                                             WHERE CUR_SALES_REVENUE >
                                                                      0
                                                          ORDER BY CUR_SALES_REVENUE DESC)
                                                         A
                                                   WHERE ROWNUM <= 750)
                                           WHERE rnum >= 501)
                AND status = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET REVENUE_BANDS = 'Top 750-1000'
          WHERE     CUR_SALES_REVENUE IN (SELECT CUR_SALES_REVENUE
                                            FROM (SELECT CUR_SALES_REVENUE,
                                                         ROWNUM rnum
                                                    FROM (  SELECT *
                                                              FROM RC_DEMAND_SOURCING_LIST_stg
                                                             WHERE CUR_SALES_REVENUE >
                                                                      0
                                                          ORDER BY CUR_SALES_REVENUE DESC)
                                                         A
                                                   WHERE ROWNUM <= 1000)
                                           WHERE rnum >= 751)
                AND status = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET REVENUE_BANDS = 'Top 1000-2000'
          WHERE     CUR_SALES_REVENUE IN (SELECT CUR_SALES_REVENUE
                                            FROM (SELECT CUR_SALES_REVENUE,
                                                         ROWNUM rnum
                                                    FROM (  SELECT *
                                                              FROM RC_DEMAND_SOURCING_LIST_stg
                                                             WHERE CUR_SALES_REVENUE >
                                                                      0
                                                          ORDER BY CUR_SALES_REVENUE DESC)
                                                         A
                                                   WHERE ROWNUM <= 2000)
                                           WHERE rnum >= 1001)
                AND status = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET REVENUE_BANDS = 'Top 2000+'
          WHERE     CUR_SALES_REVENUE IN (SELECT CUR_SALES_REVENUE
                                            FROM (SELECT CUR_SALES_REVENUE,
                                                         ROWNUM rnum
                                                    FROM (  SELECT *
                                                              FROM RC_DEMAND_SOURCING_LIST_stg
                                                             WHERE CUR_SALES_REVENUE >
                                                                      0
                                                          ORDER BY CUR_SALES_REVENUE DESC)
                                                         A)
                                           WHERE rnum >= 2001)
                AND status = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET REVENUE_BANDS = 'No Sales'
          WHERE CUR_SALES_REVENUE = 0 AND status = 'NEW';
   
   
   
         COMMIT;
   
   
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET (RF_CREATION_DATE, RF_PID) =
                   (SELECT NPI_CREATION_DATE, REFRESH_PART_NUMBER
                      FROM RC_PRODUCT_MASTER
                     WHERE REFRESH_PART_NUMBER = PRODUCT_NAME)
          WHERE     EXISTS
                       (SELECT 1
                          FROM RC_PRODUCT_MASTER
                         WHERE REFRESH_PART_NUMBER = PRODUCT_NAME)
                AND status = 'NEW';
   
         COMMIT;
   
   
         SELECT CONFIG_VALUE
           INTO lv_baseline_mos
           FROM RC_DA_SETUP
          WHERE config_type = 'NETTABLE_MOS';
   
         SELECT CONFIG_VALUE
           INTO lv_dem_greater
           FROM RC_DA_SETUP
          WHERE config_type = 'MIN_DEM_FCS_GRTR';
   
         SELECT CONFIG_VALUE
           INTO lv_dem_lesser
           FROM RC_DA_SETUP
          WHERE config_type = 'MIN_DEM_FCS_LESSER';
   
   
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET DEMAND_QTY =
                   (CASE
                       WHEN (    total_reservations > 0
                             AND REFRESH_LIFE_CYCLE_NAME = 'EOL'
                             AND (   NETTABLE_MOS <= 6
                                  OR (NETTABLE_MOS > 6 AND NVL (r6_SALES, 0) = 0))
                             AND lv_baseline_mos >
                                    ROUND (MONTHS_BETWEEN (EOS, SYSDATE))
                             AND total_reservations > (TOTAL_QTY * 0.30)
                             AND r12_sales > 0)
                       THEN
                          ROUND (
                               (  r12_sales
                                * (ROUND (MONTHS_BETWEEN (EOS, SYSDATE)) * 2)
                                / 12)
                             - TOTAL_NET_TRANSIT)
                       WHEN (    total_reservations > 0
                             AND REFRESH_LIFE_CYCLE_NAME = 'EOL'
                             AND (   NETTABLE_MOS <= 6
                                  OR (NETTABLE_MOS > 6 AND NVL (r6_SALES, 0) = 0))
                             AND lv_baseline_mos >
                                    ROUND (MONTHS_BETWEEN (EOS, SYSDATE))
                             AND total_reservations < (TOTAL_QTY * 0.30)
                             AND r12_sales > 0)
                       THEN
                          ROUND (
                               (  r12_sales
                                * (ROUND (MONTHS_BETWEEN (EOS, SYSDATE)))
                                / 12)
                             - TOTAL_NET_TRANSIT)
                       WHEN (    total_reservations > 0
                             AND (   NETTABLE_MOS <= 6
                                  OR (NETTABLE_MOS > 6 AND NVL (r6_SALES, 0) = 0))
                             AND total_reservations > (TOTAL_QTY * 0.30)
                             AND r12_sales > 0)
                       THEN
                            (r12_sales * (lv_baseline_mos * 2) / 12)
                          - TOTAL_NET_TRANSIT
                       WHEN (    r12_sales > 0
                             AND (   total_reservations = 0
                                  OR total_reservations <= (TOTAL_QTY * 0.30))
                             AND (   NETTABLE_MOS <= 6
                                  OR (NETTABLE_MOS > 6 AND NVL (r6_SALES, 0) = 0)))
                       THEN
                            (r12_sales * (lv_baseline_mos) / 12)
                          - TOTAL_NET_TRANSIT
                       WHEN (    total_reservations > 0
                             AND NETTABLE_MOS >= 7
                             AND NVL (r6_Sales, 0) > 0
                             AND REFRESH_LIFE_CYCLE_NAME = 'EOL'
                             AND lv_baseline_mos >
                                    ROUND (MONTHS_BETWEEN (EOS, SYSDATE))
                             AND total_reservations > (TOTAL_QTY * 0.30)
                             AND r12_sales > 0)
                       THEN
                            ROUND (
                                 (  r12_sales
                                  * (ROUND (MONTHS_BETWEEN (EOS, SYSDATE)) * 2)
                                  / 12)
                               - TOTAL_NET_TRANSIT)
                          + NVL (DGI, 0) ---- ADDED TO FIX DEMAND_QTY COMING AS NULL
                       WHEN (    r12_sales > 0
                             AND REFRESH_LIFE_CYCLE_NAME = 'EOL'
                             AND lv_baseline_mos >
                                    ROUND (MONTHS_BETWEEN (EOS, SYSDATE))
                             AND (   total_reservations = 0
                                  OR total_reservations <= (TOTAL_QTY * 0.30))
                             AND NETTABLE_MOS >= 7
                             AND NVL (r6_Sales, 0) > 0)
                       THEN
                            ROUND (
                                 (  r12_sales
                                  * (ROUND (MONTHS_BETWEEN (EOS, SYSDATE)))
                                  / 12)
                               - TOTAL_NET_TRANSIT)
                          + NVL (DGI, 0) ---- ADDED TO FIX DEMAND_QTY COMING AS NULL
                       WHEN (    total_reservations > 0
                             AND NETTABLE_MOS >= 7
                             AND NVL (r6_Sales, 0) > 0
                             AND total_reservations > (TOTAL_QTY * 0.30)
                             AND r12_sales > 0)
                       THEN
                            (r12_sales * (lv_baseline_mos * 2) / 12)
                          - TOTAL_NET_TRANSIT
                          + NVL (DGI, 0) ---- ADDED TO FIX DEMAND_QTY COMING AS NULL
                       WHEN (    r12_sales > 0
                             AND (   total_reservations = 0
                                  OR total_reservations <= (TOTAL_QTY * 0.30))
                             AND NETTABLE_MOS >= 7
                             AND NVL (r6_Sales, 0) > 0)
                       THEN
                            (r12_sales * (lv_baseline_mos) / 12)
                          - TOTAL_NET_TRANSIT
                          + NVL (DGI, 0) ---- ADDED TO FIX DEMAND_QTY COMING AS NULL
                       WHEN     NEW_PID_FLAG = 'Y'
                            AND (   FCS < ADD_MONTHS (SYSDATE, -60)
                                 OR RF_CREATION_DATE < ADD_MONTHS (SYSDATE, -12)
                                 OR MOS_BANDS LIKE 'No Sales without SKU')
                       THEN
                          lv_dem_greater - TOTAL_NET_TRANSIT
                       WHEN     NEW_PID_FLAG = 'Y'
                            AND FCS >= ADD_MONTHS (SYSDATE, -60)
                       THEN
                          lv_dem_lesser - TOTAL_NET_TRANSIT
                       ELSE
                          0
                    END)
          WHERE NOT_TO_DEMAND_FLAG = 'N' AND STATUS = 'NEW';
          
          
          
UPDATE RC_DEMAND_SOURCING_LIST_STG
SET OLD_DEMAND=DEMAND_QTY;
          
          
          
          MERGE INTO RC_DEMAND_SOURCING_LIST_STG RD
     USING (SELECT RETAIL_PART_NUMBER,
       EXCESS_PART_NUMBER,
       COMMON_PART_NUMBER,
       XREF_PART_NUMBER,
       RF_ADJ_OVERRIDDEN_FORECAST RF_ADJ_OVERRIDDEN_FORECAST,
       RF_ADJUSTED_FORECAST RF_ADJUSTED_FORECAST,
       RF_90DAY_FORECAST RF_90DAY_FORECAST,
       WS_ADJUSTED_FORECAST WS_ADJUSTED_FORECAST,
       WS_90DAY_FORECAST WS_90DAY_FORECAST
  FROM RC_SALES_FORECAST) RS  
        ON (   RD.REMARKETING_NAME = RS.RETAIL_PART_NUMBER
            OR RD.EXCESS_NAME = RS.EXCESS_PART_NUMBER
            OR RD.CISCO_PRODUCT_NAME = RS.COMMON_PART_NUMBER
            OR RD.PRODUCT_SPARE_NAME = RS.XREF_PART_NUMBER)
WHEN MATCHED
THEN
   UPDATE SET
      RD.RF_FORECAST = RS.RF_90DAY_FORECAST,
      RD.WS_FORECAST = RS.WS_90DAY_FORECAST,
      RD.RF_ADJUSTED_FORECAST = NVL(RS.RF_ADJ_OVERRIDDEN_FORECAST,NVL(RS.RF_ADJUSTED_FORECAST,RF_90DAY_FORECAST));                  
   
                    
UPDATE RC_DEMAND_SOURCING_LIST_STG RD
   SET UNFULFILLED_FORECAST =
          (  SELECT CASE WHEN NVL (
                       (  SUM (
                               NVL (NVL (WS_ADJUSTED_FORECAST, WS_90DAY_FORECAST), 0)
                             + NVL ( NVL(RS.RF_ADJ_OVERRIDDEN_FORECAST,NVL(RS.RF_ADJUSTED_FORECAST,RF_90DAY_FORECAST)), 0))
                        - NVL (RD.TOTAL_NETTABLE_QTY, 0)),
                       0)>=0 THEN
                       NVL (
                       (  SUM (
                               NVL (NVL (WS_ADJUSTED_FORECAST, WS_90DAY_FORECAST), 0)
                             + NVL ( NVL(RS.RF_ADJ_OVERRIDDEN_FORECAST,NVL(RS.RF_ADJUSTED_FORECAST,RF_90DAY_FORECAST)), 0))
                        - NVL (RD.TOTAL_NETTABLE_QTY, 0)),
                       0)
                       ELSE
                       0
                       END
               FROM RC_SALES_FORECAST RS
              WHERE (   RD.REMARKETING_NAME = RS.RETAIL_PART_NUMBER
            OR RD.EXCESS_NAME = RS.EXCESS_PART_NUMBER
            OR RD.CISCO_PRODUCT_NAME = RS.COMMON_PART_NUMBER
            OR RD.PRODUCT_SPARE_NAME = RS.XREF_PART_NUMBER)
           GROUP BY TOTAL_NETTABLE_QTY);
           


    
UPDATE RC_DEMAND_SOURCING_LIST_STG RD
   SET DEMAND_QTY =
          (SELECT CASE
                     WHEN NVL (UNFULFILLED_FORECAST, 0) > NVL (DEMAND_QTY, 0)
                     THEN
                        ROUND (NVL (UNFULFILLED_FORECAST, 0))
                     WHEN NVL (UNFULFILLED_FORECAST, 0) < NVL (DEMAND_QTY, 0)
                     THEN
                        ROUND (
                           GREATEST (
                              NVL (DEMAND_QTY, 0) - NVL (NEW_DEMAND, 0),
                              0))
                     ELSE
                        ROUND (NVL (DEMAND_QTY, 0))
                  END
             FROM RC_SALES_FORECAST RS
            WHERE (   RD.REMARKETING_NAME = RS.RETAIL_PART_NUMBER
            OR RD.EXCESS_NAME = RS.EXCESS_PART_NUMBER
            OR RD.CISCO_PRODUCT_NAME = RS.COMMON_PART_NUMBER
            OR RD.PRODUCT_SPARE_NAME = RS.XREF_PART_NUMBER)) 
 WHERE EXISTS
          (SELECT 1
             FROM RC_SALES_FORECAST RS
            WHERE (   RD.REMARKETING_NAME = RS.RETAIL_PART_NUMBER
            OR RD.EXCESS_NAME = RS.EXCESS_PART_NUMBER
            OR RD.CISCO_PRODUCT_NAME = RS.COMMON_PART_NUMBER
            OR RD.PRODUCT_SPARE_NAME = RS.XREF_PART_NUMBER))
                  ;

COMMIT;
                            
             

          
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET CISCO_PRODUCT_NAME = NULL
          WHERE     CISCO_PRODUCT_NAME = PRODUCT_SPARE_NAME
                AND cisco_product_name LIKE '%='
                AND status = 'NEW';
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET PRODUCT_SPARE_NAME = NULL
          WHERE     CISCO_PRODUCT_NAME = PRODUCT_SPARE_NAME
                AND PRODUCT_SPARE_NAME NOT LIKE '%='
                AND status = 'NEW';
   
   
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET SERVICE_REPAIR_FLAG =
                   NVL ( (SELECT DISTINCT repair_flag
                            FROM rc_product_xelus_attr
                           WHERE common_part_number = ds.cisco_product_name),
                        (SELECT DISTINCT repair_flag
                           FROM rc_product_xelus_attr
                          WHERE common_part_number = ds.product_spare_name))
          WHERE STATUS = 'NEW';
   
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg DS
            SET INCLUDE_OR_EXCLUDE = 'INCLUDE'
          WHERE STATUS = 'NEW'        --             AND NOT_TO_DEMAND_FLAG = 'N'
                              AND INCLUDE_OR_EXCLUDE IS NULL;
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET include_or_exclude = 'EXCLUDE',
                include_or_exclude_reason = 'Demand quantity is zero or less'
          WHERE STATUS = 'NEW' AND NOT_TO_DEMAND_FLAG = 'N' AND demand_qty <= 0;
   
         UPDATE RC_DEMAND_SOURCING_LIST_stg
            SET include_or_exclude_reason =
                   (CASE
                       WHEN     NEW_PID_FLAG = 'Y'
                            AND MOS_BANDS LIKE 'No Sales without SKU'
                            AND NVL (IN_TRANSIT_POE, 0) > 0
                       THEN
                          'New Product Demand- InTransit'
                       WHEN     NEW_PID_FLAG = 'Y'
                            AND MOS_BANDS LIKE 'No Sales without SKU'
                            AND NVL (IN_TRANSIT_POE, 0) = 0
                       THEN
                          'New Product Demand'
                       WHEN     NEW_PID_FLAG = 'Y'
                            AND MOS_BANDS NOT LIKE 'No Sales without SKU'
                       THEN
                          'Demand based on Min Nettable value'
                       WHEN     UPPER (REFRESH_LIFE_CYCLE_NAME) IN ('EOS',
                                                                    'EOL',
                                                                    'DEACTIVATED')
                            AND (NVL (brightline_category, 'NA') LIKE '%BL+')
                       THEN
                          'BL+'
                       ELSE
                          'NMOS<=12 months with demand quantity'
                    END)
          WHERE     STATUS = 'NEW'
                AND NOT_TO_DEMAND_FLAG = 'N'
                AND INCLUDE_OR_EXCLUDE = 'INCLUDE'
                AND include_or_exclude_reason IS NULL;
   
   
         --      DELETE FROM rc_dem_strg_max_tbl;
         --
         --      INSERT INTO rc_dem_strg_max_tbl
         --         (SELECT product_name,
         --                 cisco_product_name,
         --                 remarketing_name,
         --                 product_life_cycle,
         --                 storage_max,
         --                 asp
         --            FROM rc_demand_sourcing_list
         --           WHERE status = 'NEW' AND not_to_demand_flag = 'N');
   
         DELETE FROM RC_DEMAND_SOURCING_LIST_stg
               WHERE        status = 'NEW'
                        AND (   PRODUCT_NAME IS NULL
                             OR REMARKETING_NAME = CISCO_PRODUCT_NAME)
                     OR (CISCO_PRODUCT_NAME IS NULL AND SOURCE_TYPE = 'RSCM');
   
         DELETE FROM RC_DEMAND_SOURCING_LIST_stg A
               WHERE     status = 'NEW'
                     AND SOURCE_TYPE = 'ML/C3'
                     AND EXISTS
                            (SELECT 1
                               FROM RC_DEMAND_SOURCING_LIST_stg B
                              WHERE     SOURCE_TYPE = 'RSCM'
                                    AND (   A.CISCO_PRODUCT_NAME =
                                               NVL (B.PRODUCT_SPARE_NAME, 'NA')
                                         OR B.CISCO_PRODUCT_NAME =
                                               NVL (A.PRODUCT_SPARE_NAME, 'NA')));
   
         DELETE FROM RC_DEMAND_SOURCING_LIST_stg A
               WHERE     status = 'NEW'
                     AND SOURCE_TYPE = 'ML/C3'
                     AND EXISTS
                            (SELECT 1
                               FROM RC_DEMAND_SOURCING_LIST_stg B
                              WHERE     SOURCE_TYPE = 'RSCM'
                                    AND REGEXP_REPLACE (
                                           A.PRODUCT_NAME,
                                           '(^[[:space:]]*|[[:space:]]*$)') =
                                           REGEXP_REPLACE (
                                              B.PRODUCT_NAME,
                                              '(^[[:space:]]*|[[:space:]]*$)'));
   
         DELETE FROM RC_DEMAND_SOURCING_LIST_stg A
               WHERE     status = 'NEW'
                     AND SOURCE_TYPE = 'WWRL'
                     AND EXISTS
                            (SELECT 1
                               FROM RC_DEMAND_SOURCING_LIST_stg B
                              WHERE     SOURCE_TYPE IN ('RSCM', 'ML/C3')
                                    AND (   A.CISCO_PRODUCT_NAME =
                                               NVL (B.PRODUCT_SPARE_NAME, 'NA')
                                         OR B.CISCO_PRODUCT_NAME =
                                               NVL (A.PRODUCT_SPARE_NAME, 'NA')));
   
         DELETE FROM RC_DEMAND_SOURCING_LIST_stg A
               WHERE     status = 'NEW'
                     AND SOURCE_TYPE = 'CISCO'
                     AND EXISTS
                            (SELECT 1
                               FROM RC_DEMAND_SOURCING_LIST_stg B
                              WHERE     SOURCE_TYPE IN ('RSCM', 'ML/C3', 'WWRL')
                                    AND (   A.CISCO_PRODUCT_NAME =
                                               NVL (B.PRODUCT_SPARE_NAME, 'NA')
                                         OR B.CISCO_PRODUCT_NAME =
                                               NVL (A.PRODUCT_SPARE_NAME, 'NA')));
   
         DELETE FROM RC_DEMAND_SOURCING_LIST_stg A
               WHERE     status = 'NEW'
                     AND EXISTS
                            (SELECT 1
                               FROM RC_DEMAND_SOURCING_LIST_stg B
                              WHERE B.CISCO_PRODUCT_NAME =
                                       NVL (A.PRODUCT_SPARE_NAME, 'NA'));
   
         INSERT INTO RC_DEMAND_SOURCING_LIST (PRODUCT_NAME,
                                              CISCO_PRODUCT_NAME,
                                              REMARKETING_NAME,
                                              PRODUCT_LIFE_CYCLE,
                                              QTY_ON_HAND,
                                              WWRL_FGI,
                                              WWRL_FGIX,
                                              WWRL_DGI,
                                              STATUS,
                                              STORAGE_MAX,
                                              DEMAND_QTY,
                                              NOT_TO_DEMAND_FLAG,
                                              CREATED_DATE,
                                              ASP,
                                              PRODUCT_FAMILY,
                                              SOURCE_TYPE,
                                              WPM_QUANTITY,
                                              PRODUCT_SPARE_NAME,
                                              MOS,
                                              REFRESH_LIFE_CYCLE_NAME,
                                              PRODUCT_TYPE,
                                              R12_SALES,
                                              NEW_PID_FLAG,
                                              BRIGHTLINE_CATEGORY,
                                              ORDER_QTY,
                                              QUOTE_QTY,
                                              BUSINESS_UNIT,
                                              DGI,
                                              FGI,
                                              WIP,
                                              NIB,
                                              TOTAL_QTY,
                                              CONS_QTY,
                                              NETTABLE_DGI_QTY,
                                              NETTABLE_FGI_QTY,
                                              TOTAL_NETTABLE_QTY,
                                              UNIT_STD_COST_USD,
                                              BLOCKED_PID_FROM,
                                              REASON_FOR_BLOCKED_PID,
                                              CONS_PERCENTAGE,
                                              CUR_SALES_UNITS,
                                              NETTABLE_MOS,
                                              EOS,
                                              FCS,
                                              CUR_SALES_REVENUE,
                                              BACKLOG,
                                              CONDITION_OF_INV_NEEDED,
                                              INCLUDE_OR_EXCLUDE,
                                              INCLUDE_OR_EXCLUDE_REASON,
                                              REVENUE_BANDS,
                                              PRODUCT_DESCRIPTION,
                                              REPAIR_METHOD,
                                              RF_CREATION_DATE,
                                              TOTAL_RESERVATIONS,
                                              MOS_BANDS,
                                              RF_PID,
                                              SERVICE_REPAIR_FLAG,
                                              NETTABLE_MOS_BANDS,
                                              CISCO_INVENTORY_ITEM_ID,
                                              SPARE_INVENTORY_ITEM_ID,
                                              EXCESS_NAME,
                                              GPL,
                                              R6_SALES,
                                              IN_TRANSIT_POE,
                                              IN_TRANSIT_NIB,
                                              IN_TRANSIT_DGI,
                                              PID_CATEGORY,
                                              BL,
                                              ITEM_TYPE,
                                              ITEM_CATALOG_CATEGORY,
                                              RF_FORECAST, WS_FORECAST, RF_ADJUSTED_FORECAST, UNFULFILLED_FORECAST,OLD_DEMAND)
            SELECT PRODUCT_NAME,
                   CISCO_PRODUCT_NAME,
                   REMARKETING_NAME,
                   PRODUCT_LIFE_CYCLE,
                   QTY_ON_HAND,
                   WWRL_FGI,
                   WWRL_FGIX,
                   WWRL_DGI,
                   STATUS,
                   STORAGE_MAX,
                   DEMAND_QTY,
                   NOT_TO_DEMAND_FLAG,
                   CREATED_DATE,
                   ASP,
                   PRODUCT_FAMILY,
                   SOURCE_TYPE,
                   WPM_QUANTITY,
                   PRODUCT_SPARE_NAME,
                   MOS,
                   REFRESH_LIFE_CYCLE_NAME,
                   PRODUCT_TYPE,
                   R12_SALES,
                   NEW_PID_FLAG,
                   BRIGHTLINE_CATEGORY,
                   ORDER_QTY,
                   QUOTE_QTY,
                   BUSINESS_UNIT,
                   DGI,
                   FGI,
                   WIP,
                   NIB,
                   TOTAL_QTY,
                   CONS_QTY,
                   NETTABLE_DGI_QTY,
                   NETTABLE_FGI_QTY,
                   TOTAL_NETTABLE_QTY,
                   UNIT_STD_COST_USD,
                   BLOCKED_PID_FROM,
                   REASON_FOR_BLOCKED_PID,
                   CONS_PERCENTAGE,
                   CUR_SALES_UNITS,
                   NETTABLE_MOS,
                   EOS,
                   FCS,
                   CUR_SALES_REVENUE,
                   BACKLOG,
                   CONDITION_OF_INV_NEEDED,
                   INCLUDE_OR_EXCLUDE,
                   INCLUDE_OR_EXCLUDE_REASON,
                   REVENUE_BANDS,
                   PRODUCT_DESCRIPTION,
                   REPAIR_METHOD,
                   RF_CREATION_DATE,
                   TOTAL_RESERVATIONS,
                   MOS_BANDS,
                   RF_PID,
                   SERVICE_REPAIR_FLAG,
                   NETTABLE_MOS_BANDS,
                   CISCO_INVENTORY_ITEM_ID,
                   SPARE_INVENTORY_ITEM_ID,
                   EXCESS_NAME,
                   GPL,
                   R6_SALES,
                   IN_TRANSIT_POE,
                   IN_TRANSIT_NIB,
                   IN_TRANSIT_DGI,
                   PID_CATEGORY,
                   BL,
                   ITEM_TYPE,
                   ITEM_CATALOG_CATEGORY,RF_FORECAST, WS_FORECAST, RF_ADJUSTED_FORECAST, UNFULFILLED_FORECAST,OLD_DEMAND
              FROM RC_DEMAND_SOURCING_LIST_STG;
   
   
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            crpadm.rc_global_error_logging (
               'OTHERS',
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
               NULL,
               'RC_DEMAND_SOURCING',
               'PROCEDURE',
               NULL,
               'Y');
      --To capture line no as per new structure--
   
      END;
   
--      /* Procedure for generating final demand list with priority and  FGI,FGIX,DGI quantity*/
      /* Procedure for generating final demand list with priority and  FGI,FGIX,DGI quantity*/
      PROCEDURE rc_fin_dem_list_proc
      IS
         lv_include_count          NUMBER;
         lv_incl_count             NUMBER;
         lv_count                  NUMBER;
         v_dem_max_percent         NUMBER;
         lv_mfg_part               VARCHAR2 (256 BYTE);
         lv_spare_part             VARCHAR2 (256 BYTE);
         lv_mfg_con_of_inv         VARCHAR2 (50 BYTE);
         lv_spare_con_of_inv       VARCHAR2 (50 BYTE);
         lv_mfg_avail_to_alloc     NUMBER;
         lv_spare_avail_to_alloc   NUMBER;
         lv_check                  VARCHAR2 (50 BYTE);
         lv_demand                 NUMBER;
         lv_condition_of_inv       VARCHAR2 (50 BYTE);
         lv_mfg_demand             NUMBER;
         lv_spare_demand           NUMBER;
         lv_dgi                    NUMBER;
         lv_fgi                    NUMBER;
         lv_fgix                   NUMBER;
         lv_mfg_dgi                NUMBER;
         lv_mfg_fgi                NUMBER;
         lv_mfg_fgix               NUMBER;
         lv_spare_dgi              NUMBER;
         lv_spare_fgi              NUMBER;
         lv_spare_fgix             NUMBER;
   
         CURSOR cur_incl_pid
         IS
            SELECT *
              FROM rc_include_pid_list
             WHERE     TO_DATE (effective_to_date, 'DD/MM/RR') >=
                          TRUNC (SYSDATE)
                   AND product_id IN (SELECT DISTINCT product_name
                                        FROM rc_dem_strg_max_tbl
                                       WHERE product_name IS NOT NULL
                                      UNION
                                      SELECT DISTINCT cisco_product_name
                                        FROM rc_dem_strg_max_tbl
                                       WHERE cisco_product_name IS NOT NULL
                                      UNION
                                      SELECT DISTINCT product_spare_name
                                        FROM rc_dem_strg_max_tbl
                                       WHERE product_spare_name IS NOT NULL);
   
         v_include_pid             cur_incl_pid%ROWTYPE;
   
         CURSOR CUR_DEM_MAX
         IS
            SELECT PRODUCT_NAME,
                   CISCO_PRODUCT_NAME,
                   PRODUCT_SPARE_NAME,
                   REMARKETING_NAME,
                   PRODUCT_LIFE_CYCLE,
                   QOH,
                   ASP,
                   WPM,
                   STORAGE_MAX,
                   ROUND(DEMAND_MAX) DEMAND_MAX,
                   PRIORITY,
                   FGI_QTY,
                   FGIX_QTY,
                   DGI_QTY,
                   LIST_GENERATION_DATE,
                   MOS,
                   CONDITION_OF_INV,
                   NETTABLE_MOS,
                   BUSINESS_UNIT,
                   DGI,
                   FGI,
                   WIP,
                   NIB,
                   TOTAL_QTY,
                   CONS_QTY,
                   NETTABLE_DGI_QTY,
                   NETTABLE_FGI_QTY,
                   TOTAL_NETTABLE_QTY,
                   UNIT_STD_COST_USD,
                   BLOCKED_PID_FROM,
                   REASON_FOR_BLOCKED_PID,
                   CONS_PERCENTAGE,
                   CUR_SALES_UNITS,
                   EOS,
                   FCS,
                   BACKLOG,
                   INCLUDE_OR_EXCLUDE,
                   INCLUDE_OR_EXCLUDE_REASON,
                   REVENUE_BANDS,
                   END_OF_LAST_SUPPORT_DATE,
                   PRODUCT_DESCRIPTION,
                   PRODUCT_FAMILY,
                   PRODUCT_TYPE,
                   REPAIR_METHOD,
                   RF_CREATION_DATE,
                   TOTAL_RESERVATIONS,
                   MOS_BANDS,
                   RF_PID,
                   SERVICE_REPAIR_FLAG,
                   VR_AVAILABILITY,
                   EXCESS_NAME,
                   GPL,
                   REFRESH_LIFE_CYCLE,
                   BL,
                   IN_TRANSIT_POE,
                   IN_TRANSIT_NIB,
                   IN_TRANSIT_DGI,
                   ITEM_TYPE,
                   ITEM_CATALOG_CATEGORY,
                   PID_CATEGORY,RF_FORECAST, WS_FORECAST, RF_ADJUSTED_FORECAST, UNFULFILLED_FORECAST,OLD_DEMAND
              FROM rc_dem_strg_max_tbl;
   
         CURSOR CUR_VR_DATA (
            i_cisco_name    VARCHAR2,
            i_spare_name    VARCHAR2)
         IS
              SELECT *
                FROM (  SELECT PART_NUMBER,
                               SUBINVENTORY,
                               SUM (QTY_AVAILABLE) VR_AVAIL_QTY,
                               'MFG' PR_TYPE
                          FROM (SELECT PART_NO part_number,
                                       CASE
                                          WHEN WAREHOUSE LIKE 'DGI%' THEN 'DGI'
                                          WHEN WAREHOUSE LIKE 'FGIX%' THEN 'FGIX'
                                          WHEN WAREHOUSE LIKE 'FGI%' THEN 'FGI'
                                          ELSE WAREHOUSE
                                       END
                                          SUBINVENTORY,
                                       QTY_AVAILABLE
                                  FROM RC_WWRL_INV_DATA_TBL
                                 WHERE PART_NO = i_cisco_name)
                      GROUP BY PART_NUMBER, SUBINVENTORY
                      UNION
                        SELECT PART_NUMBER,
                               SUBINVENTORY,
                               SUM (QTY_AVAILABLE) VR_AVAIL_QTY,
                               'SERVICE' PR_TYPE
                          FROM (SELECT PART_NO part_number,
                                       CASE
                                          WHEN WAREHOUSE LIKE 'DGI%' THEN 'DGI'
                                          WHEN WAREHOUSE LIKE 'FGIX%' THEN 'FGIX'
                                          WHEN WAREHOUSE LIKE 'FGI%' THEN 'FGI'
                                          ELSE WAREHOUSE
                                       END
                                          SUBINVENTORY,
                                       QTY_AVAILABLE
                                  FROM RC_WWRL_INV_DATA_TBL
                                 WHERE PART_NO = i_spare_name)
                      GROUP BY PART_NUMBER, SUBINVENTORY)
            ORDER BY PR_TYPE, SUBINVENTORY ASC;
   
   
         v_vr_data                 CUR_VR_DATA%ROWTYPE;
   
         --  v_dem_max_data            CUR_DEM_MAX%ROWTYPE;
         TYPE v_dem_max_data IS RECORD
         (
            PRODUCT_NAME                VARCHAR2 (256 BYTE),
            CISCO_PRODUCT_NAME          VARCHAR2 (256 BYTE),
            PRODUCT_SPARE_NAME          VARCHAR2 (256 BYTE),
            REMARKETING_NAME            VARCHAR2 (256 BYTE),
            PRODUCT_LIFE_CYCLE          VARCHAR2 (50 BYTE),
            QOH                         NUMBER,
            ASP                         NUMBER,
            WPM                         NUMBER,
            STORAGE_MAX                 NUMBER,
            DEMAND_MAX                  NUMBER,
            PRIORITY                    VARCHAR2 (10 BYTE),
            FGI_QTY                     NUMBER,
            FGIX_QTY                    NUMBER,
            DGI_QTY                     NUMBER,
            LIST_GENERATION_DATE        DATE,
            MOS                         NUMBER,
            CONDITION_OF_INV            VARCHAR2 (100 BYTE),
            NETTABLE_MOS                NUMBER,
            BUSINESS_UNIT               VARCHAR2 (500 BYTE),
            DGI                         NUMBER,
            FGI                         NUMBER,
            WIP                         NUMBER,
            NIB                         NUMBER,
            TOTAL_QTY                   NUMBER,
            CONS_QTY                    NUMBER,
            NETTABLE_DGI_QTY            NUMBER,
            NETTABLE_FGI_QTY            NUMBER,
            TOTAL_NETTABLE_QTY          NUMBER,
            UNIT_STD_COST_USD           NUMBER,
            BLOCKED_PID_FROM            VARCHAR2 (500 BYTE),
            REASON_FOR_BLOCKED_PID      VARCHAR2 (1000 BYTE),
            CONS_PERCENTAGE             NUMBER,
            CUR_SALES_UNITS             NUMBER,
            EOS                         DATE,
            FCS                         DATE,
            BACKLOG                     NUMBER,
            INCLUDE_OR_EXCLUDE          VARCHAR2 (100 BYTE),
            INCLUDE_OR_EXCLUDE_REASON   VARCHAR2 (100 BYTE),
            REVENUE_BANDS               VARCHAR2 (100 BYTE),
            END_OF_LAST_SUPPORT_DATE    DATE,
            PRODUCT_DESCRIPTION         VARCHAR2 (1000 BYTE),
            PRODUCT_FAMILY              VARCHAR2 (100 BYTE),
            PRODUCT_TYPE                VARCHAR2 (100 BYTE),
            REPAIR_METHOD               VARCHAR2 (100 BYTE),
            RF_CREATION_DATE            DATE,
            TOTAL_RESERVATIONS          NUMBER,
            MOS_BANDS                   VARCHAR2 (100 BYTE),
            RF_PID                      VARCHAR2 (1000 BYTE),
            SERVICE_REPAIR_FLAG         VARCHAR2 (100 BYTE),
            VR_AVAILABILITY             VARCHAR2 (10 BYTE),
            EXCESS_NAME                 VARCHAR2 (256 BYTE),
            GPL                         NUMBER,
            REFRESH_LIFE_CYCLE          VARCHAR2 (50 BYTE),
            BL                          VARCHAR2 (10 BYTE),
            IN_TRANSIT_POE              NUMBER,
            IN_TRANSIT_NIB              NUMBER,
            IN_TRANSIT_DGI              NUMBER,
            ITEM_TYPE                   VARCHAR2 (50 BYTE),
            ITEM_CATALOG_CATEGORY       VARCHAR2 (50 BYTE),
            PID_CAtegory                VARCHAR2 (50 BYTE),
            RF_FORECAST NUMBER, 
            WS_FORECAST NUMBER,
             RF_ADJUSTED_FORECAST NUMBER,
              UNFULFILLED_FORECAST NUMBER,
              OLD_DEMAND NUMBER
         );
   
         TYPE T_DEM_MAX_DATA_LIST IS TABLE OF v_dem_max_data;
   
         lv_dem_max_data_list      T_DEM_MAX_DATA_LIST;
   
         lv_pid                    VARCHAR2 (256 BYTE);
      BEGIN
         INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                      'CRPADM.RC_DEMAND_AUTOMATION',
                      'START',
                      SYSDATE);
   
        RC_DEMAND_AUTOMATION.rc_demand_sourcing;
   
         INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                      'CRPADM.RC_DEMAND_AUTOMATION',
                      'DEMAND_SOURCE_COM',
                      SYSDATE);
   
         INSERT INTO RC_FIN_DEMAND_LIST_HIST
            (SELECT * FROM RC_FIN_DEMAND_LIST);
   
         DELETE FROM RC_DEM_STRG_MAX_TBL;
   
         DELETE FROM RC_FIN_DEMAND_LIST;
   
         DELETE FROM RC_VAL_RECOVERY_DATA;
   
         COMMIT;
   
         INSERT INTO RC_DEM_STRG_MAX_TBL (PRODUCT_NAME,
                                          CISCO_PRODUCT_NAME,
                                          PRODUCT_LIFE_CYCLE,
                                          REFRESH_LIFE_CYCLE,
                                          QOH,
                                          DEMAND_MAX,
                                          WPM,
                                          STORAGE_MAX,
                                          REMARKETING_NAME,
                                          LIST_GENERATION_DATE,
                                          ASP,
                                          MOS,
                                          PRODUCT_SPARE_NAME,
                                          BUSINESS_UNIT,
                                          DGI,
                                          FGI,
                                          WIP,
                                          NIB,
                                          TOTAL_QTY,
                                          CONS_QTY,
                                          NETTABLE_DGI_QTY,
                                          NETTABLE_FGI_QTY,
                                          TOTAL_NETTABLE_QTY,
                                          UNIT_STD_COST_USD,
                                          BLOCKED_PID_FROM,
                                          REASON_FOR_BLOCKED_PID,
                                          CONS_PERCENTAGE,
                                          CUR_SALES_UNITS,
                                          EOS,
                                          FCS,
                                          BACKLOG,
                                          INCLUDE_OR_EXCLUDE,
                                          INCLUDE_OR_EXCLUDE_REASON,
                                          REVENUE_BANDS,
                                          --                                       END_OF_LAST_SUPPORT_DATE,
                                          PRODUCT_DESCRIPTION,
                                          PRODUCT_FAMILY,
                                          PRODUCT_TYPE,
                                          REPAIR_METHOD,
                                          RF_CREATION_DATE,
                                          TOTAL_RESERVATIONS,
                                          MOS_BANDS,
                                          NETTABLE_MOS,
                                          RF_PID,
                                          service_repair_flag,
                                          excess_name,
                                          gpl,
                                          bl,
                                          IN_TRANSIT_POE,
                                          IN_TRANSIT_NIB,
                                          IN_TRANSIT_DGI,
                                          ITEM_TYPE,
                                          ITEM_CATALOG_CATEGORY,
                                          PID_CATEGORY,
                                          RF_FORECAST, WS_FORECAST, RF_ADJUSTED_FORECAST, UNFULFILLED_FORECAST,OLD_DEMAND)
            (SELECT PRODUCT_NAME,
                    CISCO_PRODUCT_NAME,
                    PRODUCT_LIFE_CYCLE,
                    REFRESH_LIFE_CYCLE_NAME,
                    QTY_ON_HAND,
                    ROUND(DEMAND_QTY) DEMAND_MAX,
                    WPM_QUANTITY,
                    STORAGE_MAX,
                    REMARKETING_NAME,
                    SYSDATE,
                    ASP,
                    MOS,
                    PRODUCT_SPARE_NAME,
                    BUSINESS_UNIT,
                    DGI,
                    FGI,
                    WIP,
                    NIB,
                    TOTAL_QTY,
                    CONS_QTY,
                    NETTABLE_DGI_QTY,
                    NETTABLE_FGI_QTY,
                    TOTAL_NETTABLE_QTY,
                    UNIT_STD_COST_USD,
                    BLOCKED_PID_FROM,
                    REASON_FOR_BLOCKED_PID,
                    CONS_PERCENTAGE,
                    CUR_SALES_UNITS,
                    EOS,
                    FCS,
                    BACKLOG,
                    INCLUDE_OR_EXCLUDE,
                    INCLUDE_OR_EXCLUDE_REASON,
                    REVENUE_BANDS,
                    --                 END_OF_LAST_SUPPORT_DATE,
                    PRODUCT_DESCRIPTION,
                    PRODUCT_FAMILY,
                    PRODUCT_TYPE,
                    REPAIR_METHOD,
                    RF_CREATION_DATE,
                    TOTAL_RESERVATIONS,
                    MOS_BANDS,
                    NETTABLE_MOS,
                    RF_PID,
                    service_repair_flag,
                    excess_name,
                    gpl,
                    brightline_category,
                    IN_TRANSIT_POE,
                    IN_TRANSIT_NIB,
                    IN_TRANSIT_DGI,
                    ITEM_TYPE,
                    ITEM_CATALOG_CATEGORY,
                    PID_CATEGORY,RF_FORECAST, WS_FORECAST, RF_ADJUSTED_FORECAST, UNFULFILLED_FORECAST,OLD_DEMAND
               FROM RC_DEMAND_SOURCING_LIST
              WHERE STATUS = 'NEW');
   
   
   
         --      DELETE FROM RC_DEM_STRG_MAX_TBL
         --            WHERE demand_max <= 0;
   
         --Step 4: Updating FGI,FGIX,DGI flag based on priority--
         UPDATE RC_DEM_STRG_MAX_TBL DS
            SET VR_AVAILABILITY = 'N';
   
         UPDATE RC_DEM_STRG_MAX_TBL DS
            SET VR_AVAILABILITY = 'Y'
          WHERE EXISTS
                   (SELECT PART_NO
                      FROM RC_WWRL_INV_DATA_TBL
                     WHERE    PART_NO = NVL (DS.CISCO_PRODUCT_NAME, 'NA')
                           OR PART_NO = NVL (DS.PRODUCT_SPARE_NAME, 'NA'));
   
         FOR CUR_PRIORITY IN (  SELECT *
                                  FROM RC_DA_SETUP
                                 WHERE CONFIG_TYPE = 'PRIORITY'
                              ORDER BY MIN_MOS)
         LOOP
            UPDATE RC_DEM_STRG_MAX_TBL
               SET priority = CUR_PRIORITY.CONFIG_VALUE
             WHERE        NVL (nettable_mos, 0) BETWEEN CUR_PRIORITY.MIN_MOS
                                                    AND CUR_PRIORITY.MAX_MOS
                      AND CUR_PRIORITY.OPERATOR = 'BETWEEN'
                   OR (    CUR_PRIORITY.OPERATOR = 'GREATER THAN'
                       AND NVL (nettable_mos, 0) > CUR_PRIORITY.MIN_MOS)
                   OR (    CUR_PRIORITY.OPERATOR = 'LESS THAN'
                       AND NVL (nettable_mos, 0) < CUR_PRIORITY.MIN_MOS)
                   OR     (    CUR_PRIORITY.OPERATOR = 'EQUAL TO'
                           AND NVL (nettable_mos, 0) = CUR_PRIORITY.MIN_MOS)
                      AND INCLUDE_OR_EXCLUDE = 'INCLUDE';
   
            EXIT WHEN CUR_PRIORITY.OPERATOR = 'GREATER THAN';
         END LOOP;
   
         FOR CUR_COI IN (  SELECT *
                             FROM RC_DA_SETUP
                            WHERE CONFIG_TYPE = 'INVENTORY'
                         ORDER BY MIN_MOS)
         LOOP
            UPDATE RC_DEM_STRG_MAX_TBL
               SET CONDITION_OF_INV = CUR_COI.CONFIG_VALUE
             WHERE        NVL (nettable_mos, 0) BETWEEN CUR_COI.MIN_MOS
                                                    AND CUR_COI.MAX_MOS
                      AND CUR_COI.OPERATOR = 'BETWEEN'
                   OR (    CUR_COI.OPERATOR = 'GREATER THAN'
                       AND NVL (nettable_mos, 0) > CUR_COI.MIN_MOS)
                   OR (    CUR_COI.OPERATOR = 'LESS THAN'
                       AND NVL (nettable_mos, 0) < CUR_COI.MIN_MOS)
                   OR     (    CUR_COI.OPERATOR = 'EQUAL TO'
                           AND NVL (nettable_mos, 0) = CUR_COI.MIN_MOS)
                      AND INCLUDE_OR_EXCLUDE = 'INCLUDE';
   
            EXIT WHEN CUR_COI.OPERATOR = 'GREATER THAN';
         END LOOP;
   
         /* UPDATE RC_DEM_STRG_MAX_TBL
             SET CONDITION_OF_INV = 'FGIX and FGI'
           WHERE    (PRODUCT_NAME LIKE 'CTS%' AND REPAIR_METHOD = 'SCREEN')
                 OR (    MOS_BANDS LIKE 'No Sales%'
                     AND TOTAL_QTY > 39
                     AND TOTAL_NETTABLE_QTY < 40)
                 OR (MOS_BANDS LIKE 'No Sales%' AND TOTAL_QTY > 100);
   
          COMMIT;*/
   
         /* If repair method is screen and DGI quantity has reached 40 demand only FGIX and FGI – For PID Bhaskar*/
         UPDATE RC_DEM_STRG_MAX_TBL
            SET CONDITION_OF_INV = 'FGIX and FGI'
          WHERE    (    PRODUCT_NAME LIKE 'CTS%'
                    AND (REPAIR_METHOD = 'SCREEN' OR REPAIR_METHOD IS NULL)) --- TO UPDATE CONDITION_OF_INV FOR PARTS HAVING NO REFRESH METHOD
                OR (    MOS_BANDS LIKE 'No Sales%'
                    AND TOTAL_QTY > 39
                    AND TOTAL_NETTABLE_QTY < 40)
                OR (MOS_BANDS LIKE 'No Sales%' AND TOTAL_QTY > 100)
                OR (NVL (REPAIR_METHOD, 'SCREEN') = 'SCREEN' AND DGI >= 40);
   
         /*Product with no sales the priority is P2 Bhaskar*/
         UPDATE RC_DEM_STRG_MAX_TBL
            SET PRIORITY = 'P2'
          WHERE MOS_BANDS LIKE 'No Sales%';
   
         COMMIT;
   
         FOR v_include_pid IN cur_incl_pid
         LOOP
            lv_pid := v_include_pid.product_id;
   
            UPDATE rc_dem_strg_max_tbl fd
               SET priority = 'P1A',
                   DEMAND_MAX =
                      (CASE
                          WHEN     fd.DEMAND_MAX > v_include_pid.DEMAND_QUANTITY
                               AND UPPER (PRODUCT_TYPE) NOT IN ('CABLE',
                                                                'ACCESSORY')
                          THEN
                             ROUND(fd.DEMAND_MAX)
                          ELSE
                             ROUND(v_include_pid.DEMAND_QUANTITY)
                       END),
                   CONDITION_OF_INV =
                      (CASE
                          WHEN UPPER (PRODUCT_TYPE) IN ('CABLE', 'ACCESSORY')
                          THEN
                             'FGI'
                          WHEN UPPER (v_include_pid.INV_FLAG) LIKE 'DGI%'
                          THEN
                             'DGI, FGIX and FGI'
                          WHEN UPPER (v_include_pid.INV_FLAG) LIKE 'FGIX%'
                          THEN
                             'FGIX and FGI'
                          ELSE
                             UPPER (v_include_pid.INV_FLAG)
                       END),
                   INCLUDE_OR_EXCLUDE_REASON = 'User Inclusion',
                   INCLUDE_OR_EXCLUDE = 'INCLUDE'
             WHERE    product_name = lv_pid
                   OR cisco_product_name = lv_pid
                   OR product_spare_name = lv_pid;
   
            COMMIT;
         END LOOP;
   
         /*DA 2.0*/
         IF NOT (CUR_DEM_MAX%ISOPEN)
         THEN
            OPEN CUR_DEM_MAX;
         END IF;
   
         LOOP
            FETCH CUR_DEM_MAX BULK COLLECT INTO lv_dem_max_data_list LIMIT 1000;
   
            IF lv_dem_max_data_list.COUNT > 0
            THEN
               FOR idx IN 1 .. lv_dem_max_data_list.COUNT
               LOOP
                  IF lv_dem_max_data_list (idx).VR_AVAILABILITY = 'Y'
                  THEN
                     /*Consolidating VR Data*/
                     FOR V_VR_DATA
                        IN CUR_VR_DATA (
                              lv_dem_max_data_list (idx).CISCO_PRODUCT_NAME,
                              lv_dem_max_data_list (idx).PRODUCT_SPARE_NAME)
                     LOOP
                        BEGIN
                           SELECT COUNT (PART_NUMBER)
                             INTO lv_count
                             FROM RC_VAL_RECOVERY_DATA
                            WHERE PART_NUMBER = V_VR_DATA.PART_NUMBER;
   
                           CASE
                              WHEN V_VR_DATA.SUBINVENTORY LIKE 'DGI'
                              THEN
                                 lv_dgi := V_VR_DATA.VR_AVAIL_QTY;
                                 lv_fgix := 0;
                                 lv_fgi := 0;
                              WHEN V_VR_DATA.SUBINVENTORY LIKE 'FGIX'
                              THEN
                                 lv_fgix := V_VR_DATA.VR_AVAIL_QTY;
                                 lv_fgi := 0;
                                 lv_dgi := 0;
                              WHEN V_VR_DATA.SUBINVENTORY LIKE 'FGI'
                              THEN
                                 lv_fgi := V_VR_DATA.VR_AVAIL_QTY;
                                 lv_fgix := 0;
                                 lv_dgi := 0;
                           END CASE;
   
                           IF (LV_COUNT = 0)
                           THEN
                              INSERT INTO RC_VAL_RECOVERY_DATA
                                   VALUES (V_VR_DATA.PART_NUMBER,
                                           NULL,
                                           lv_dgi,
                                           lv_fgix,
                                           lv_fgi);
   
                              COMMIT;
                           ELSE
                              UPDATE RC_VAL_RECOVERY_DATA
                                 SET DGI = DGI + lv_dgi,
                                     FGIX = FGIX + lv_fgix,
                                     FGI = FGI + lv_fgi
                               WHERE PART_NUMBER = V_VR_DATA.PART_NUMBER;
   
                              COMMIT;
                           END IF;
                        END;
                     END LOOP;
   
                     UPDATE RC_VAL_RECOVERY_DATA
                        SET CONDITION_OF_INV =
                               (CASE
                                   WHEN DGI > 0 THEN 'DGI, FGIX and FGI'
                                   WHEN DGI = 0 AND FGIX > 0 THEN 'FGIX and FGI'
                                   ELSE 'FGI'
                                END)
                      WHERE PART_NUMBER =
                               lv_dem_max_data_list (idx).CISCO_PRODUCT_NAME;
   
                     UPDATE RC_VAL_RECOVERY_DATA
                        SET CONDITION_OF_INV =
                               (CASE
                                   WHEN DGI > 0 THEN 'DGI, FGIX and FGI'
                                   WHEN DGI = 0 AND FGIX > 0 THEN 'FGIX and FGI'
                                   ELSE 'FGI'
                                END)
                      WHERE PART_NUMBER =
                               lv_dem_max_data_list (idx).PRODUCT_SPARE_NAME;
   
                     COMMIT;
                     lv_check := 'Both';
   
                     BEGIN
                        SELECT part_number,
                               DGI,
                               FGIX,
                               FGI,
                               condition_of_inv
                          INTO lv_mfg_part,
                               lv_mfg_dgi,
                               lv_mfg_fgix,
                               lv_mfg_fgi,
                               lv_mfg_con_of_inv
                          FROM RC_VAL_RECOVERY_DATA
                         WHERE part_number =
                                  lv_dem_max_data_list (idx).CISCO_PRODUCT_NAME;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           lv_check := 'No MFG Found';
                     END;
   
                     BEGIN
                        SELECT part_number,
                               DGI,
                               FGIX,
                               FGI,
                               condition_of_inv
                          INTO lv_spare_part,
                               lv_spare_dgi,
                               lv_spare_fgix,
                               lv_spare_fgi,
                               lv_spare_con_of_inv
                          FROM RC_VAL_RECOVERY_DATA
                         WHERE part_number =
                                  lv_dem_max_data_list (idx).PRODUCT_SPARE_NAME;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           lv_check := 'No Spare Found';
                     END;
   
                     lv_mfg_avail_to_alloc := 0;
                     lv_spare_avail_to_alloc := 0;
                     lv_condition_of_inv :=
                        lv_dem_max_data_list (idx).CONDITION_OF_INV;
   
                     CASE
                        WHEN lv_dem_max_data_list (idx).CONDITION_OF_INV LIKE
                                'DGI%'
                        THEN
                           lv_spare_avail_to_alloc :=
                              lv_spare_dgi + lv_spare_fgix + lv_spare_fgi;
                           lv_mfg_avail_to_alloc :=
                              lv_mfg_dgi + lv_mfg_fgix + lv_mfg_fgi;
                        WHEN lv_dem_max_data_list (idx).CONDITION_OF_INV LIKE
                                'FGIX%'
                        THEN
                           lv_spare_avail_to_alloc :=
                              lv_spare_fgix + lv_spare_fgi;
                           lv_mfg_avail_to_alloc := lv_mfg_fgix + lv_mfg_fgi;
                        WHEN lv_dem_max_data_list (idx).CONDITION_OF_INV LIKE
                                'FGI%'
                        THEN
                           lv_spare_avail_to_alloc := lv_spare_fgi;
                           lv_mfg_avail_to_alloc := lv_mfg_fgi;
                        ELSE
                           lv_spare_avail_to_alloc :=
                              lv_spare_dgi + lv_spare_fgix + lv_spare_fgi;
                           lv_mfg_avail_to_alloc :=
                              lv_mfg_dgi + lv_mfg_fgix + lv_mfg_fgi;
                     END CASE;
   
                     IF lv_check = 'Both'
                     THEN
                        IF lv_dem_max_data_list (idx).DEMAND_MAX >
                              (lv_spare_avail_to_alloc + lv_mfg_avail_to_alloc)
                        THEN
                           IF    lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE =
                                    'User Inclusion'
                              OR (  lv_spare_avail_to_alloc
                                  + lv_mfg_avail_to_alloc) = 0
                           THEN
                              lv_mfg_demand :=
                                 lv_dem_max_data_list (idx).DEMAND_MAX;
                              lv_spare_demand :=
                                 lv_dem_max_data_list (idx).DEMAND_MAX;
                           ELSE
                              lv_mfg_demand :=
                                   lv_dem_max_data_list (idx).DEMAND_MAX
                                 - (  lv_spare_avail_to_alloc
                                    + lv_mfg_avail_to_alloc);
                              lv_spare_demand :=
                                   lv_dem_max_data_list (idx).DEMAND_MAX
                                 - (  lv_spare_avail_to_alloc
                                    + lv_mfg_avail_to_alloc);
                           END IF;
                        ELSE
                           --                    CASE  WHEN lv_dem_max_data_list (idx).DEMAND_MAX <=lv_mfg_avail_to_alloc AND lv_spare_con_of_inv=lv_mfg_con_of_inv
                           --        THEN
                           --            lv_mfg_demand:=lv_dem_max_data_list (idx).DEMAND_MAX;
                           --            lv_spare_demand:=0;
                           --            lv_condition_of_inv:=lv_dem_max_data_list(idx).CONDITION_OF_INV;
                           --        WHEN  lv_dem_max_data_list (idx).DEMAND_MAX <=(lv_spare_avail_to_alloc+lv_mfg_avail_to_alloc) AND lv_spare_con_of_inv=lv_mfg_con_of_inv
                           --        THEN
                           --            lv_mfg_demand:=lv_mfg_avail_to_alloc;
                           --            lv_spare_demand :=lv_dem_max_data_list (idx).DEMAND_MAX- lv_mfg_demand;
                           --             lv_condition_of_inv:=lv_dem_max_data_list(idx).CONDITION_OF_INV;
                           --        ELSE
                           CASE
                              WHEN lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE =
                                      'User Inclusion'
                              THEN
                                 lv_mfg_demand :=
                                    lv_dem_max_data_list (idx).DEMAND_MAX;
                                 lv_spare_demand :=
                                    lv_dem_max_data_list (idx).DEMAND_MAX;
                                 lv_condition_of_inv :=
                                    lv_dem_max_data_list (idx).CONDITION_OF_INV;
                              WHEN lv_dem_max_data_list (idx).DEMAND_MAX <=
                                      lv_mfg_fgi
                              THEN
                                 lv_mfg_demand :=
                                    lv_dem_max_data_list (idx).DEMAND_MAX;
                                 lv_condition_of_inv := 'FGI';
                                 lv_spare_demand := 0;
                              WHEN lv_dem_max_data_list (idx).DEMAND_MAX <=
                                      (lv_mfg_fgi + lv_spare_fgi)
                              THEN
                                 lv_mfg_demand := lv_mfg_fgi;
                                 lv_condition_of_inv := 'FGI';
                                 lv_spare_demand :=
                                      lv_dem_max_data_list (idx).DEMAND_MAX
                                    - lv_mfg_fgi;
                              WHEN lv_dem_max_data_list (idx).DEMAND_MAX <=
                                      (lv_mfg_fgi + lv_spare_fgi + lv_mfg_fgix)
                              THEN
                                 lv_spare_demand := lv_spare_fgi;
                                 lv_mfg_demand :=
                                      lv_dem_max_data_list (idx).DEMAND_MAX
                                    - lv_spare_demand;
                                 lv_condition_of_inv := 'FGIX and FGI';
                              WHEN lv_dem_max_data_list (idx).DEMAND_MAX <=
                                      (  lv_mfg_fgi
                                       + lv_spare_fgi
                                       + lv_mfg_fgix
                                       + lv_spare_fgix)
                              THEN
                                 lv_mfg_demand := lv_mfg_fgi + lv_mfg_fgix;
                                 lv_spare_demand :=
                                      lv_dem_max_data_list (idx).DEMAND_MAX
                                    - (lv_mfg_demand);
                                 lv_condition_of_inv := 'FGIX and FGI';
                              ELSE
                                 lv_mfg_demand := lv_mfg_avail_to_alloc;
                                 lv_spare_demand :=
                                      lv_dem_max_data_list (idx).DEMAND_MAX
                                    - lv_mfg_demand;
                                 lv_condition_of_inv :=
                                    lv_dem_max_data_list (idx).CONDITION_OF_INV;
                           END CASE;
                        --    END CASE;
                        END IF;
   
   
                        INSERT
                          INTO CRPADM.RC_FIN_DEMAND_LIST (
                                  PRODUCT_NAME,
                                  PRODUCT_DESCRIPTION,
                                  PRODUCT_FAMILY,
                                  PRODUCT_TYPE,
                                  EOS,
                                  BUSINESS_UNIT,
                                  PRODUCT_LIFE_CYCLE,
                                  UNIT_STD_COST_USD,
                                  ASP,
                                  POE_MAX,
                                  STORAGE_MAX,
                                  QOH,
                                  VR_AVAIL_QTY,
                                  DEMAND_MAX,
                                  CONDITION_OF_INV,
                                  PRIORITY,
                                  FGI_QTY,
                                  FGIX_QTY,
                                  DGI_QTY,
                                  LIST_GENERATION_DATE,
                                  BLOCKED_PID_FROM,
                                  REASON_FOR_BLOCKED_PID,
                                  DGI,
                                  FGI,
                                  WIP,
                                  NIB,
                                  TOTAL_QTY,
                                  CONS_QTY,
                                  NETTABLE_DGI_QTY,
                                  NETTABLE_FGI_QTY,
                                  TOTAL_NETTABLE_QTY,
                                  CONS_PERCENTAGE,
                                  CUR_SALES_UNITS,
                                  MOS,
                                  NETTABLE_MOS,
                                  REVENUE_BANDS,
                                  MOS_BANDS,
                                  FCS,
                                  BACKLOG,
                                  INCLUDE_OR_EXCLUDE,
                                  INCLUDE_OR_EXCLUDE_REASON,
                                  --                                                   END_OF_LAST_SUPPORT_DATE,
                                  REPAIR_METHOD,
                                  RF_CREATION_DATE,
                                  TOTAL_RESERVATIONS,
                                  RF_PID,
                                  SERVICE_REPAIR_FLAG,
                                  GPL,
                                  EXPECTED_RECEIPTS,
                                  REFRESH_LIFE_CYCLE,
                                  IN_TRANSIT_POE,
                                  IN_TRANSIT_NIB,
                                  IN_TRANSIT_DGI,
                                  ITEM_TYPE,
                                  ITEM_CATALOG_CATEGORY,
                                  PID_CATEGORY,
                                  BL,
                                  RF_FORECAST, WS_FORECAST, RF_ADJUSTED_FORECAST, UNFULFILLED_FORECAST,OLD_DEMAND)
                           VALUES (
                                     lv_dem_max_data_list (idx).CISCO_PRODUCT_NAME,
                                     lv_dem_max_data_list (idx).PRODUCT_DESCRIPTION,
                                     lv_dem_max_data_list (idx).PRODUCT_FAMILY,
                                     lv_dem_max_data_list (idx).PRODUCT_TYPE,
                                     lv_dem_max_data_list (idx).EOS,
                                     lv_dem_max_data_list (idx).BUSINESS_UNIT,
                                     lv_dem_max_data_list (idx).PRODUCT_LIFE_CYCLE,
                                     lv_dem_max_data_list (idx).UNIT_STD_COST_USD,
                                     lv_dem_max_data_list (idx).ASP,
                                     lv_dem_max_data_list (idx).WPM,
                                     lv_dem_max_data_list (idx).STORAGE_MAX,
                                     lv_dem_max_data_list (idx).QOH,
                                     lv_mfg_avail_to_alloc,
                                     lv_mfg_demand,
                                     lv_condition_of_inv, --lv_dem_max_data_list (idx).CONDITION_OF_INV,
                                     lv_dem_max_data_list (idx).PRIORITY,
                                     lv_dem_max_data_list (idx).FGI_QTY,
                                     lv_dem_max_data_list (idx).FGIX_QTY,
                                     lv_dem_max_data_list (idx).DGI_QTY,
                                     lv_dem_max_data_list (idx).LIST_GENERATION_DATE,
                                     lv_dem_max_data_list (idx).BLOCKED_PID_FROM,
                                     lv_dem_max_data_list (idx).REASON_FOR_BLOCKED_PID,
                                     lv_dem_max_data_list (idx).DGI,
                                     lv_dem_max_data_list (idx).FGI,
                                     lv_dem_max_data_list (idx).WIP,
                                     lv_dem_max_data_list (idx).NIB,
                                     lv_dem_max_data_list (idx).TOTAL_QTY,
                                     lv_dem_max_data_list (idx).CONS_QTY,
                                     lv_dem_max_data_list (idx).NETTABLE_DGI_QTY,
                                     lv_dem_max_data_list (idx).NETTABLE_FGI_QTY,
                                     lv_dem_max_data_list (idx).TOTAL_NETTABLE_QTY,
                                     lv_dem_max_data_list (idx).CONS_PERCENTAGE,
                                     lv_dem_max_data_list (idx).CUR_SALES_UNITS,
                                     lv_dem_max_data_list (idx).MOS,
                                     lv_dem_max_data_list (idx).NETTABLE_MOS,
                                     lv_dem_max_data_list (idx).REVENUE_BANDS,
                                     lv_dem_max_data_list (idx).MOS_BANDS,
                                     lv_dem_max_data_list (idx).FCS,
                                     lv_dem_max_data_list (idx).BACKLOG,
                                     lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE,
                                     lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE_REASON,
                                     --                         lv_dem_max_data_list(idx).END_OF_LAST_SUPPORT_DATE,
                                     lv_dem_max_data_list (idx).REPAIR_METHOD,
                                     lv_dem_max_data_list (idx).RF_CREATION_DATE,
                                     lv_dem_max_data_list (idx).TOTAL_RESERVATIONS,
                                     lv_dem_max_data_list (idx).RF_PID,
                                     lv_dem_max_data_list (idx).SERVICE_REPAIR_FLAG,
                                     lv_dem_max_data_list (idx).GPL,
                                     LEAST (lv_mfg_avail_to_alloc,
                                            lv_mfg_demand),
                                     lv_dem_max_data_list (idx).REFRESH_LIFE_CYCLE,
                                     lv_dem_max_data_list (idx).IN_TRANSIT_POE,
                                     lv_dem_max_data_list (idx).IN_TRANSIT_NIB,
                                     lv_dem_max_data_list (idx).IN_TRANSIT_DGI,
                                     lv_dem_max_data_list (idx).ITEM_TYPE,
                                     lv_dem_max_data_list (idx).ITEM_CATALOG_CATEGORY,
                                     lv_dem_max_data_list (idx).PID_CATEGORY,
                                     lv_dem_max_data_list (idx).BL,
                                     lv_dem_max_data_list (idx).RF_FORECAST, lv_dem_max_data_list (idx).WS_FORECAST, 
                                     lv_dem_max_data_list (idx).RF_ADJUSTED_FORECAST, lv_dem_max_data_list (idx).UNFULFILLED_FORECAST,lv_dem_max_data_list (idx).OLD_DEMAND);
   
                        INSERT
                          INTO CRPADM.RC_FIN_DEMAND_LIST (
                                  PRODUCT_NAME,
                                  PRODUCT_DESCRIPTION,
                                  PRODUCT_FAMILY,
                                  PRODUCT_TYPE,
                                  EOS,
                                  BUSINESS_UNIT,
                                  PRODUCT_LIFE_CYCLE,
                                  UNIT_STD_COST_USD,
                                  ASP,
                                  POE_MAX,
                                  STORAGE_MAX,
                                  QOH,
                                  VR_AVAIL_QTY,
                                  DEMAND_MAX,
                                  CONDITION_OF_INV,
                                  PRIORITY,
                                  FGI_QTY,
                                  FGIX_QTY,
                                  DGI_QTY,
                                  LIST_GENERATION_DATE,
                                  BLOCKED_PID_FROM,
                                  REASON_FOR_BLOCKED_PID,
                                  DGI,
                                  FGI,
                                  WIP,
                                  NIB,
                                  TOTAL_QTY,
                                  CONS_QTY,
                                  NETTABLE_DGI_QTY,
                                  NETTABLE_FGI_QTY,
                                  TOTAL_NETTABLE_QTY,
                                  CONS_PERCENTAGE,
                                  CUR_SALES_UNITS,
                                  MOS,
                                  NETTABLE_MOS,
                                  REVENUE_BANDS,
                                  MOS_BANDS,
                                  FCS,
                                  BACKLOG,
                                  INCLUDE_OR_EXCLUDE,
                                  INCLUDE_OR_EXCLUDE_REASON,
                                  --                                                   END_OF_LAST_SUPPORT_DATE,
                                  REPAIR_METHOD,
                                  RF_CREATION_DATE,
                                  TOTAL_RESERVATIONS,
                                  RF_PID,
                                  SERVICE_REPAIR_FLAG,
                                  GPL,
                                  EXPECTED_RECEIPTS,
                                  REFRESH_LIFE_CYCLE,
                                  IN_TRANSIT_POE,
                                  IN_TRANSIT_NIB,
                                  IN_TRANSIT_DGI,
                                  ITEM_TYPE,
                                  ITEM_CATALOG_CATEGORY,
                                  PID_CATEGORY,
                                  BL,
                                 RF_FORECAST,WS_FORECAST, 
                                 RF_ADJUSTED_FORECAST, UNFULFILLED_FORECAST,OLD_DEMAND)
                           VALUES (
                                     lv_dem_max_data_list (idx).PRODUCT_SPARE_NAME,
                                     lv_dem_max_data_list (idx).PRODUCT_DESCRIPTION,
                                     lv_dem_max_data_list (idx).PRODUCT_FAMILY,
                                     lv_dem_max_data_list (idx).PRODUCT_TYPE,
                                     lv_dem_max_data_list (idx).EOS,
                                     lv_dem_max_data_list (idx).BUSINESS_UNIT,
                                     lv_dem_max_data_list (idx).PRODUCT_LIFE_CYCLE,
                                     lv_dem_max_data_list (idx).UNIT_STD_COST_USD,
                                     lv_dem_max_data_list (idx).ASP,
                                     lv_dem_max_data_list (idx).WPM,
                                     lv_dem_max_data_list (idx).STORAGE_MAX,
                                     lv_dem_max_data_list (idx).QOH,
                                     lv_spare_avail_to_alloc,
                                     lv_spare_demand,
                                     lv_condition_of_inv, --lv_dem_max_data_list (idx).CONDITION_OF_INV,
                                     lv_dem_max_data_list (idx).PRIORITY,
                                     lv_dem_max_data_list (idx).FGI_QTY,
                                     lv_dem_max_data_list (idx).FGIX_QTY,
                                     lv_dem_max_data_list (idx).DGI_QTY,
                                     lv_dem_max_data_list (idx).LIST_GENERATION_DATE,
                                     lv_dem_max_data_list (idx).BLOCKED_PID_FROM,
                                     lv_dem_max_data_list (idx).REASON_FOR_BLOCKED_PID,
                                     lv_dem_max_data_list (idx).DGI,
                                     lv_dem_max_data_list (idx).FGI,
                                     lv_dem_max_data_list (idx).WIP,
                                     lv_dem_max_data_list (idx).NIB,
                                     lv_dem_max_data_list (idx).TOTAL_QTY,
                                     lv_dem_max_data_list (idx).CONS_QTY,
                                     lv_dem_max_data_list (idx).NETTABLE_DGI_QTY,
                                     lv_dem_max_data_list (idx).NETTABLE_FGI_QTY,
                                     lv_dem_max_data_list (idx).TOTAL_NETTABLE_QTY,
                                     lv_dem_max_data_list (idx).CONS_PERCENTAGE,
                                     lv_dem_max_data_list (idx).CUR_SALES_UNITS,
                                     lv_dem_max_data_list (idx).MOS,
                                     lv_dem_max_data_list (idx).NETTABLE_MOS,
                                     lv_dem_max_data_list (idx).REVENUE_BANDS,
                                     lv_dem_max_data_list (idx).MOS_BANDS,
                                     lv_dem_max_data_list (idx).FCS,
                                     lv_dem_max_data_list (idx).BACKLOG,
                                     lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE,
                                     lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE_REASON,
                                     --                         lv_dem_max_data_list(idx).END_OF_LAST_SUPPORT_DATE,
                                     lv_dem_max_data_list (idx).REPAIR_METHOD,
                                     lv_dem_max_data_list (idx).RF_CREATION_DATE,
                                     lv_dem_max_data_list (idx).TOTAL_RESERVATIONS,
                                     lv_dem_max_data_list (idx).RF_PID,
                                     lv_dem_max_data_list (idx).SERVICE_REPAIR_FLAG,
                                     lv_dem_max_data_list (idx).GPL,
                                     LEAST (lv_spare_avail_to_alloc,
                                            lv_spare_demand),
                                     lv_dem_max_data_list (idx).REFRESH_LIFE_CYCLE,
                                     lv_dem_max_data_list (idx).IN_TRANSIT_POE,
                                     lv_dem_max_data_list (idx).IN_TRANSIT_NIB,
                                     lv_dem_max_data_list (idx).IN_TRANSIT_DGI,
                                     lv_dem_max_data_list (idx).ITEM_TYPE,
                                     lv_dem_max_data_list (idx).ITEM_CATALOG_CATEGORY,
                                     lv_dem_max_data_list (idx).PID_CATEGORY,
                                     lv_dem_max_data_list (idx).BL,
                                     lv_dem_max_data_list (idx).RF_FORECAST, lv_dem_max_data_list (idx).WS_FORECAST, 
                                     lv_dem_max_data_list (idx).RF_ADJUSTED_FORECAST, lv_dem_max_data_list (idx).UNFULFILLED_FORECAST,lv_dem_max_data_list (idx).OLD_DEMAND);
                     ELSIF lv_check = 'No Spare Found'
                     THEN
                        IF lv_mfg_avail_to_alloc >
                              lv_dem_max_data_list (idx).DEMAND_MAX
                        THEN
                           CASE
                              WHEN lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE =
                                      'User Inclusion'
                              THEN
                                 lv_condition_of_inv :=
                                    lv_dem_max_data_list (idx).CONDITION_OF_INV;
                              WHEN lv_dem_max_data_list (idx).DEMAND_MAX <=
                                      lv_mfg_fgi
                              THEN
                                 lv_condition_of_inv := 'FGI';
                              WHEN lv_dem_max_data_list (idx).DEMAND_MAX <=
                                      (lv_mfg_fgi + lv_mfg_fgix)
                              THEN
                                 lv_condition_of_inv := 'FGIX and FGI';
                              ELSE
                                 lv_condition_of_inv :=
                                    lv_dem_max_data_list (idx).CONDITION_OF_INV;
                           END CASE;
   
                           INSERT
                             INTO CRPADM.RC_FIN_DEMAND_LIST (
                                     PRODUCT_NAME,
                                     PRODUCT_DESCRIPTION,
                                     PRODUCT_FAMILY,
                                     PRODUCT_TYPE,
                                     EOS,
                                     BUSINESS_UNIT,
                                     PRODUCT_LIFE_CYCLE,
                                     UNIT_STD_COST_USD,
                                     ASP,
                                     POE_MAX,
                                     STORAGE_MAX,
                                     QOH,
                                     VR_AVAIL_QTY,
                                     DEMAND_MAX,
                                     CONDITION_OF_INV,
                                     PRIORITY,
                                     FGI_QTY,
                                     FGIX_QTY,
                                     DGI_QTY,
                                     LIST_GENERATION_DATE,
                                     BLOCKED_PID_FROM,
                                     REASON_FOR_BLOCKED_PID,
                                     DGI,
                                     FGI,
                                     WIP,
                                     NIB,
                                     TOTAL_QTY,
                                     CONS_QTY,
                                     NETTABLE_DGI_QTY,
                                     NETTABLE_FGI_QTY,
                                     TOTAL_NETTABLE_QTY,
                                     CONS_PERCENTAGE,
                                     CUR_SALES_UNITS,
                                     MOS,
                                     NETTABLE_MOS,
                                     REVENUE_BANDS,
                                     MOS_BANDS,
                                     FCS,
                                     BACKLOG,
                                     INCLUDE_OR_EXCLUDE,
                                     INCLUDE_OR_EXCLUDE_REASON,
                                     --                                                 END_OF_LAST_SUPPORT_DATE,
                                     REPAIR_METHOD,
                                     RF_CREATION_DATE,
                                     TOTAL_RESERVATIONS,
                                     RF_PID,
                                     SERVICE_REPAIR_FLAG,
                                     GPL,
                                     EXPECTED_RECEIPTS,
                                     REFRESH_LIFE_CYCLE,
                                     IN_TRANSIT_POE,
                                     IN_TRANSIT_NIB,
                                     IN_TRANSIT_DGI,
                                     ITEM_TYPE,
                                     ITEM_CATALOG_CATEGORY,
                                     PID_CATEGORY,
                                     BL,
                                     RF_FORECAST,WS_FORECAST, 
                                     RF_ADJUSTED_FORECAST, UNFULFILLED_FORECAST,OLD_DEMAND)
                              VALUES (
                                        lv_dem_max_data_list (idx).CISCO_PRODUCT_NAME,
                                        lv_dem_max_data_list (idx).PRODUCT_DESCRIPTION,
                                        lv_dem_max_data_list (idx).PRODUCT_FAMILY,
                                        lv_dem_max_data_list (idx).PRODUCT_TYPE,
                                        lv_dem_max_data_list (idx).EOS,
                                        lv_dem_max_data_list (idx).BUSINESS_UNIT,
                                        lv_dem_max_data_list (idx).PRODUCT_LIFE_CYCLE,
                                        lv_dem_max_data_list (idx).UNIT_STD_COST_USD,
                                        lv_dem_max_data_list (idx).ASP,
                                        lv_dem_max_data_list (idx).WPM,
                                        lv_dem_max_data_list (idx).STORAGE_MAX,
                                        lv_dem_max_data_list (idx).QOH,
                                        lv_mfg_avail_to_alloc,
                                        lv_dem_max_data_list (idx).DEMAND_MAX,
                                        lv_condition_of_inv,
                                        lv_dem_max_data_list (idx).PRIORITY,
                                        lv_dem_max_data_list (idx).FGI_QTY,
                                        lv_dem_max_data_list (idx).FGIX_QTY,
                                        lv_dem_max_data_list (idx).DGI_QTY,
                                        lv_dem_max_data_list (idx).LIST_GENERATION_DATE,
                                        lv_dem_max_data_list (idx).BLOCKED_PID_FROM,
                                        lv_dem_max_data_list (idx).REASON_FOR_BLOCKED_PID,
                                        lv_dem_max_data_list (idx).DGI,
                                        lv_dem_max_data_list (idx).FGI,
                                        lv_dem_max_data_list (idx).WIP,
                                        lv_dem_max_data_list (idx).NIB,
                                        lv_dem_max_data_list (idx).TOTAL_QTY,
                                        lv_dem_max_data_list (idx).CONS_QTY,
                                        lv_dem_max_data_list (idx).NETTABLE_DGI_QTY,
                                        lv_dem_max_data_list (idx).NETTABLE_FGI_QTY,
                                        lv_dem_max_data_list (idx).TOTAL_NETTABLE_QTY,
                                        lv_dem_max_data_list (idx).CONS_PERCENTAGE,
                                        lv_dem_max_data_list (idx).CUR_SALES_UNITS,
                                        lv_dem_max_data_list (idx).MOS,
                                        lv_dem_max_data_list (idx).NETTABLE_MOS,
                                        lv_dem_max_data_list (idx).REVENUE_BANDS,
                                        lv_dem_max_data_list (idx).MOS_BANDS,
                                        lv_dem_max_data_list (idx).FCS,
                                        lv_dem_max_data_list (idx).BACKLOG,
                                        lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE,
                                        lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE_REASON,
                                        --                       lv_dem_max_data_list(idx).END_OF_LAST_SUPPORT_DATE,
                                        lv_dem_max_data_list (idx).REPAIR_METHOD,
                                        lv_dem_max_data_list (idx).RF_CREATION_DATE,
                                        lv_dem_max_data_list (idx).TOTAL_RESERVATIONS,
                                        lv_dem_max_data_list (idx).RF_PID,
                                        lv_dem_max_data_list (idx).SERVICE_REPAIR_FLAG,
                                        lv_dem_max_data_list (idx).GPL,
                                        LEAST (
                                           lv_mfg_avail_to_alloc,
                                           lv_dem_max_data_list (idx).DEMAND_MAX),
                                        lv_dem_max_data_list (idx).REFRESH_LIFE_CYCLE,
                                        lv_dem_max_data_list (idx).IN_TRANSIT_POE,
                                        lv_dem_max_data_list (idx).IN_TRANSIT_NIB,
                                        lv_dem_max_data_list (idx).IN_TRANSIT_DGI,
                                        lv_dem_max_data_list (idx).ITEM_TYPE,
                                        lv_dem_max_data_list (idx).ITEM_CATALOG_CATEGORY,
                                        lv_dem_max_data_list (idx).PID_CATEGORY,
                                        lv_dem_max_data_list (idx).BL,
                                        lv_dem_max_data_list (idx).RF_FORECAST, lv_dem_max_data_list (idx).WS_FORECAST, 
                                     lv_dem_max_data_list (idx).RF_ADJUSTED_FORECAST, lv_dem_max_data_list (idx).UNFULFILLED_FORECAST,lv_dem_max_data_list (idx).OLD_DEMAND);
                        ELSIF lv_mfg_avail_to_alloc = 0
                        THEN
                           IF lv_dem_max_data_list (idx).CISCO_PRODUCT_NAME
                                 IS NOT NULL
                           THEN
                              INSERT
                                INTO CRPADM.RC_FIN_DEMAND_LIST (
                                        PRODUCT_NAME,
                                        PRODUCT_DESCRIPTION,
                                        PRODUCT_FAMILY,
                                        PRODUCT_TYPE,
                                        EOS,
                                        BUSINESS_UNIT,
                                        PRODUCT_LIFE_CYCLE,
                                        UNIT_STD_COST_USD,
                                        ASP,
                                        POE_MAX,
                                        STORAGE_MAX,
                                        QOH,
                                        VR_AVAIL_QTY,
                                        DEMAND_MAX,
                                        CONDITION_OF_INV,
                                        PRIORITY,
                                        FGI_QTY,
                                        FGIX_QTY,
                                        DGI_QTY,
                                        LIST_GENERATION_DATE,
                                        BLOCKED_PID_FROM,
                                        REASON_FOR_BLOCKED_PID,
                                        DGI,
                                        FGI,
                                        WIP,
                                        NIB,
                                        TOTAL_QTY,
                                        CONS_QTY,
                                        NETTABLE_DGI_QTY,
                                        NETTABLE_FGI_QTY,
                                        TOTAL_NETTABLE_QTY,
                                        CONS_PERCENTAGE,
                                        CUR_SALES_UNITS,
                                        MOS,
                                        NETTABLE_MOS,
                                        REVENUE_BANDS,
                                        MOS_BANDS,
                                        FCS,
                                        BACKLOG,
                                        INCLUDE_OR_EXCLUDE,
                                        INCLUDE_OR_EXCLUDE_REASON,
                                        --                                                 END_OF_LAST_SUPPORT_DATE,
                                        REPAIR_METHOD,
                                        RF_CREATION_DATE,
                                        TOTAL_RESERVATIONS,
                                        RF_PID,
                                        SERVICE_REPAIR_FLAG,
                                        GPL,
                                        EXPECTED_RECEIPTS,
                                        REFRESH_LIFE_CYCLE,
                                        IN_TRANSIT_POE,
                                        IN_TRANSIT_NIB,
                                        IN_TRANSIT_DGI,
                                        ITEM_TYPE,
                                        ITEM_CATALOG_CATEGORY,
                                        PID_CATEGORY,
                                        BL,
                                        RF_FORECAST, WS_FORECAST, 
                                     RF_ADJUSTED_FORECAST,UNFULFILLED_FORECAST,OLD_DEMAND)
                                 VALUES (
                                           lv_dem_max_data_list (idx).CISCO_PRODUCT_NAME,
                                           lv_dem_max_data_list (idx).PRODUCT_DESCRIPTION,
                                           lv_dem_max_data_list (idx).PRODUCT_FAMILY,
                                           lv_dem_max_data_list (idx).PRODUCT_TYPE,
                                           lv_dem_max_data_list (idx).EOS,
                                           lv_dem_max_data_list (idx).BUSINESS_UNIT,
                                           lv_dem_max_data_list (idx).PRODUCT_LIFE_CYCLE,
                                           lv_dem_max_data_list (idx).UNIT_STD_COST_USD,
                                           lv_dem_max_data_list (idx).ASP,
                                           lv_dem_max_data_list (idx).WPM,
                                           lv_dem_max_data_list (idx).STORAGE_MAX,
                                           lv_dem_max_data_list (idx).QOH,
                                           0,
                                           lv_dem_max_data_list (idx).DEMAND_MAX,
                                           lv_dem_max_data_list (idx).CONDITION_OF_INV,
                                           lv_dem_max_data_list (idx).PRIORITY,
                                           lv_dem_max_data_list (idx).FGI_QTY,
                                           lv_dem_max_data_list (idx).FGIX_QTY,
                                           lv_dem_max_data_list (idx).DGI_QTY,
                                           lv_dem_max_data_list (idx).LIST_GENERATION_DATE,
                                           lv_dem_max_data_list (idx).BLOCKED_PID_FROM,
                                           lv_dem_max_data_list (idx).REASON_FOR_BLOCKED_PID,
                                           lv_dem_max_data_list (idx).DGI,
                                           lv_dem_max_data_list (idx).FGI,
                                           lv_dem_max_data_list (idx).WIP,
                                           lv_dem_max_data_list (idx).NIB,
                                           lv_dem_max_data_list (idx).TOTAL_QTY,
                                           lv_dem_max_data_list (idx).CONS_QTY,
                                           lv_dem_max_data_list (idx).NETTABLE_DGI_QTY,
                                           lv_dem_max_data_list (idx).NETTABLE_FGI_QTY,
                                           lv_dem_max_data_list (idx).TOTAL_NETTABLE_QTY,
                                           lv_dem_max_data_list (idx).CONS_PERCENTAGE,
                                           lv_dem_max_data_list (idx).CUR_SALES_UNITS,
                                           lv_dem_max_data_list (idx).MOS,
                                           lv_dem_max_data_list (idx).NETTABLE_MOS,
                                           lv_dem_max_data_list (idx).REVENUE_BANDS,
                                           lv_dem_max_data_list (idx).MOS_BANDS,
                                           lv_dem_max_data_list (idx).FCS,
                                           lv_dem_max_data_list (idx).BACKLOG,
                                           lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE,
                                           lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE_REASON,
                                           --                       lv_dem_max_data_list(idx).END_OF_LAST_SUPPORT_DATE,
                                           lv_dem_max_data_list (idx).REPAIR_METHOD,
                                           lv_dem_max_data_list (idx).RF_CREATION_DATE,
                                           lv_dem_max_data_list (idx).TOTAL_RESERVATIONS,
                                           lv_dem_max_data_list (idx).RF_PID,
                                           lv_dem_max_data_list (idx).SERVICE_REPAIR_FLAG,
                                           lv_dem_max_data_list (idx).GPL,
                                           0,
                                           lv_dem_max_data_list (idx).REFRESH_LIFE_CYCLE,
                                           lv_dem_max_data_list (idx).IN_TRANSIT_POE,
                                           lv_dem_max_data_list (idx).IN_TRANSIT_NIB,
                                           lv_dem_max_data_list (idx).IN_TRANSIT_DGI,
                                           lv_dem_max_data_list (idx).ITEM_TYPE,
                                           lv_dem_max_data_list (idx).ITEM_CATALOG_CATEGORY,
                                           lv_dem_max_data_list (idx).PID_CATEGORY,
                                           lv_dem_max_data_list (idx).BL,
                                           lv_dem_max_data_list (idx).RF_FORECAST, lv_dem_max_data_list (idx).WS_FORECAST, 
                                     lv_dem_max_data_list (idx).RF_ADJUSTED_FORECAST, lv_dem_max_data_list (idx).UNFULFILLED_FORECAST,lv_dem_max_data_list (idx).OLD_DEMAND);
                           END IF;
   
                           IF lv_dem_max_data_list (idx).PRODUCT_SPARE_NAME
                                 IS NOT NULL
                           THEN
                              INSERT
                                INTO CRPADM.RC_FIN_DEMAND_LIST (
                                        PRODUCT_NAME,
                                        PRODUCT_DESCRIPTION,
                                        PRODUCT_FAMILY,
                                        PRODUCT_TYPE,
                                        EOS,
                                        BUSINESS_UNIT,
                                        PRODUCT_LIFE_CYCLE,
                                        UNIT_STD_COST_USD,
                                        ASP,
                                        POE_MAX,
                                        STORAGE_MAX,
                                        QOH,
                                        VR_AVAIL_QTY,
                                        DEMAND_MAX,
                                        CONDITION_OF_INV,
                                        PRIORITY,
                                        FGI_QTY,
                                        FGIX_QTY,
                                        DGI_QTY,
                                        LIST_GENERATION_DATE,
                                        BLOCKED_PID_FROM,
                                        REASON_FOR_BLOCKED_PID,
                                        DGI,
                                        FGI,
                                        WIP,
                                        NIB,
                                        TOTAL_QTY,
                                        CONS_QTY,
                                        NETTABLE_DGI_QTY,
                                        NETTABLE_FGI_QTY,
                                        TOTAL_NETTABLE_QTY,
                                        CONS_PERCENTAGE,
                                        CUR_SALES_UNITS,
                                        MOS,
                                        NETTABLE_MOS,
                                        REVENUE_BANDS,
                                        MOS_BANDS,
                                        FCS,
                                        BACKLOG,
                                        INCLUDE_OR_EXCLUDE,
                                        INCLUDE_OR_EXCLUDE_REASON,
                                        --                            END_OF_LAST_SUPPORT_DATE,
                                        REPAIR_METHOD,
                                        RF_CREATION_DATE,
                                        TOTAL_RESERVATIONS,
                                        RF_PID,
                                        SERVICE_REPAIR_FLAG,
                                        GPL,
                                        EXPECTED_RECEIPTS,
                                        REFRESH_LIFE_CYCLE,
                                        IN_TRANSIT_POE,
                                        IN_TRANSIT_NIB,
                                        IN_TRANSIT_DGI,
                                        ITEM_TYPE,
                                        ITEM_CATALOG_CATEGORY,
                                        PID_CATEGORY,
                                        BL,
                                       RF_FORECAST, WS_FORECAST, 
                                     RF_ADJUSTED_FORECAST, UNFULFILLED_FORECAST,OLD_DEMAND)
                                 VALUES (
                                           lv_dem_max_data_list (idx).PRODUCT_SPARE_NAME,
                                           lv_dem_max_data_list (idx).PRODUCT_DESCRIPTION,
                                           lv_dem_max_data_list (idx).PRODUCT_FAMILY,
                                           lv_dem_max_data_list (idx).PRODUCT_TYPE,
                                           lv_dem_max_data_list (idx).EOS,
                                           lv_dem_max_data_list (idx).BUSINESS_UNIT,
                                           lv_dem_max_data_list (idx).PRODUCT_LIFE_CYCLE,
                                           lv_dem_max_data_list (idx).UNIT_STD_COST_USD,
                                           lv_dem_max_data_list (idx).ASP,
                                           lv_dem_max_data_list (idx).WPM,
                                           lv_dem_max_data_list (idx).STORAGE_MAX,
                                           lv_dem_max_data_list (idx).QOH,
                                           0,
                                           lv_dem_max_data_list (idx).DEMAND_MAX,
                                           lv_dem_max_data_list (idx).CONDITION_OF_INV,
                                           lv_dem_max_data_list (idx).PRIORITY,
                                           lv_dem_max_data_list (idx).FGI_QTY,
                                           lv_dem_max_data_list (idx).FGIX_QTY,
                                           lv_dem_max_data_list (idx).DGI_QTY,
                                           lv_dem_max_data_list (idx).LIST_GENERATION_DATE,
                                           lv_dem_max_data_list (idx).BLOCKED_PID_FROM,
                                           lv_dem_max_data_list (idx).REASON_FOR_BLOCKED_PID,
                                           lv_dem_max_data_list (idx).DGI,
                                           lv_dem_max_data_list (idx).FGI,
                                           lv_dem_max_data_list (idx).WIP,
                                           lv_dem_max_data_list (idx).NIB,
                                           lv_dem_max_data_list (idx).TOTAL_QTY,
                                           lv_dem_max_data_list (idx).CONS_QTY,
                                           lv_dem_max_data_list (idx).NETTABLE_DGI_QTY,
                                           lv_dem_max_data_list (idx).NETTABLE_FGI_QTY,
                                           lv_dem_max_data_list (idx).TOTAL_NETTABLE_QTY,
                                           lv_dem_max_data_list (idx).CONS_PERCENTAGE,
                                           lv_dem_max_data_list (idx).CUR_SALES_UNITS,
                                           lv_dem_max_data_list (idx).MOS,
                                           lv_dem_max_data_list (idx).NETTABLE_MOS,
                                           lv_dem_max_data_list (idx).REVENUE_BANDS,
                                           lv_dem_max_data_list (idx).MOS_BANDS,
                                           lv_dem_max_data_list (idx).FCS,
                                           lv_dem_max_data_list (idx).BACKLOG,
                                           lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE,
                                           lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE_REASON,
                                           --                               lv_dem_max_data_list(idx).END_OF_LAST_SUPPORT_DATE,
                                           lv_dem_max_data_list (idx).REPAIR_METHOD,
                                           lv_dem_max_data_list (idx).RF_CREATION_DATE,
                                           lv_dem_max_data_list (idx).TOTAL_RESERVATIONS,
                                           lv_dem_max_data_list (idx).RF_PID,
                                           lv_dem_max_data_list (idx).SERVICE_REPAIR_FLAG,
                                           lv_dem_max_data_list (idx).GPL,
                                           0,
                                           lv_dem_max_data_list (idx).REFRESH_LIFE_CYCLE,
                                           lv_dem_max_data_list (idx).IN_TRANSIT_POE,
                                           lv_dem_max_data_list (idx).IN_TRANSIT_NIB,
                                           lv_dem_max_data_list (idx).IN_TRANSIT_DGI,
                                           lv_dem_max_data_list (idx).ITEM_TYPE,
                                           lv_dem_max_data_list (idx).ITEM_CATALOG_CATEGORY,
                                           lv_dem_max_data_list (idx).PID_CATEGORY,
                                           lv_dem_max_data_list (idx).BL,
                                           lv_dem_max_data_list (idx).RF_FORECAST, lv_dem_max_data_list (idx).WS_FORECAST, 
                                     lv_dem_max_data_list (idx).RF_ADJUSTED_FORECAST, lv_dem_max_data_list (idx).UNFULFILLED_FORECAST,lv_dem_max_data_list (idx).OLD_DEMAND);
                           END IF;
                        ELSE
                           INSERT
                             INTO CRPADM.RC_FIN_DEMAND_LIST (
                                     PRODUCT_NAME,
                                     PRODUCT_DESCRIPTION,
                                     PRODUCT_FAMILY,
                                     PRODUCT_TYPE,
                                     EOS,
                                     BUSINESS_UNIT,
                                     PRODUCT_LIFE_CYCLE,
                                     UNIT_STD_COST_USD,
                                     ASP,
                                     POE_MAX,
                                     STORAGE_MAX,
                                     QOH,
                                     VR_AVAIL_QTY,
                                     DEMAND_MAX,
                                     CONDITION_OF_INV,
                                     PRIORITY,
                                     FGI_QTY,
                                     FGIX_QTY,
                                     DGI_QTY,
                                     LIST_GENERATION_DATE,
                                     BLOCKED_PID_FROM,
                                     REASON_FOR_BLOCKED_PID,
                                     DGI,
                                     FGI,
                                     WIP,
                                     NIB,
                                     TOTAL_QTY,
                                     CONS_QTY,
                                     NETTABLE_DGI_QTY,
                                     NETTABLE_FGI_QTY,
                                     TOTAL_NETTABLE_QTY,
                                     CONS_PERCENTAGE,
                                     CUR_SALES_UNITS,
                                     MOS,
                                     NETTABLE_MOS,
                                     REVENUE_BANDS,
                                     MOS_BANDS,
                                     FCS,
                                     BACKLOG,
                                     INCLUDE_OR_EXCLUDE,
                                     INCLUDE_OR_EXCLUDE_REASON,
                                     --                                                 END_OF_LAST_SUPPORT_DATE,
                                     REPAIR_METHOD,
                                     RF_CREATION_DATE,
                                     TOTAL_RESERVATIONS,
                                     RF_PID,
                                     SERVICE_REPAIR_FLAG,
                                     GPL,
                                     EXPECTED_RECEIPTS,
                                     REFRESH_LIFE_CYCLE,
                                     IN_TRANSIT_POE,
                                     IN_TRANSIT_NIB,
                                     IN_TRANSIT_DGI,
                                     ITEM_TYPE,
                                     ITEM_CATALOG_CATEGORY,
                                     PID_CATEGORY,
                                     BL,
                                     RF_FORECAST,WS_FORECAST, 
                                     RF_ADJUSTED_FORECAST, UNFULFILLED_FORECAST,OLD_DEMAND)
                              VALUES (
                                        lv_dem_max_data_list (idx).CISCO_PRODUCT_NAME,
                                        lv_dem_max_data_list (idx).PRODUCT_DESCRIPTION,
                                        lv_dem_max_data_list (idx).PRODUCT_FAMILY,
                                        lv_dem_max_data_list (idx).PRODUCT_TYPE,
                                        lv_dem_max_data_list (idx).EOS,
                                        lv_dem_max_data_list (idx).BUSINESS_UNIT,
                                        lv_dem_max_data_list (idx).PRODUCT_LIFE_CYCLE,
                                        lv_dem_max_data_list (idx).UNIT_STD_COST_USD,
                                        lv_dem_max_data_list (idx).ASP,
                                        lv_dem_max_data_list (idx).WPM,
                                        lv_dem_max_data_list (idx).STORAGE_MAX,
                                        lv_dem_max_data_list (idx).QOH,
                                        lv_mfg_avail_to_alloc,
                                        (  lv_dem_max_data_list (idx).DEMAND_MAX
                                         - lv_mfg_avail_to_alloc), --Modified by karsivak as per Change request
                                        lv_dem_max_data_list (idx).CONDITION_OF_INV,
                                        lv_dem_max_data_list (idx).PRIORITY,
                                        lv_dem_max_data_list (idx).FGI_QTY,
                                        lv_dem_max_data_list (idx).FGIX_QTY,
                                        lv_dem_max_data_list (idx).DGI_QTY,
                                        lv_dem_max_data_list (idx).LIST_GENERATION_DATE,
                                        lv_dem_max_data_list (idx).BLOCKED_PID_FROM,
                                        lv_dem_max_data_list (idx).REASON_FOR_BLOCKED_PID,
                                        lv_dem_max_data_list (idx).DGI,
                                        lv_dem_max_data_list (idx).FGI,
                                        lv_dem_max_data_list (idx).WIP,
                                        lv_dem_max_data_list (idx).NIB,
                                        lv_dem_max_data_list (idx).TOTAL_QTY,
                                        lv_dem_max_data_list (idx).CONS_QTY,
                                        lv_dem_max_data_list (idx).NETTABLE_DGI_QTY,
                                        lv_dem_max_data_list (idx).NETTABLE_FGI_QTY,
                                        lv_dem_max_data_list (idx).TOTAL_NETTABLE_QTY,
                                        lv_dem_max_data_list (idx).CONS_PERCENTAGE,
                                        lv_dem_max_data_list (idx).CUR_SALES_UNITS,
                                        lv_dem_max_data_list (idx).MOS,
                                        lv_dem_max_data_list (idx).NETTABLE_MOS,
                                        lv_dem_max_data_list (idx).REVENUE_BANDS,
                                        lv_dem_max_data_list (idx).MOS_BANDS,
                                        lv_dem_max_data_list (idx).FCS,
                                        lv_dem_max_data_list (idx).BACKLOG,
                                        lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE,
                                        lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE_REASON,
                                        --                       lv_dem_max_data_list(idx).END_OF_LAST_SUPPORT_DATE,
                                        lv_dem_max_data_list (idx).REPAIR_METHOD,
                                        lv_dem_max_data_list (idx).RF_CREATION_DATE,
                                        lv_dem_max_data_list (idx).TOTAL_RESERVATIONS,
                                        lv_dem_max_data_list (idx).RF_PID,
                                        lv_dem_max_data_list (idx).SERVICE_REPAIR_FLAG,
                                        lv_dem_max_data_list (idx).GPL,
                                        lv_mfg_avail_to_alloc,
                                        lv_dem_max_data_list (idx).REFRESH_LIFE_CYCLE,
                                        lv_dem_max_data_list (idx).IN_TRANSIT_POE,
                                        lv_dem_max_data_list (idx).IN_TRANSIT_NIB,
                                        lv_dem_max_data_list (idx).IN_TRANSIT_DGI,
                                        lv_dem_max_data_list (idx).ITEM_TYPE,
                                        lv_dem_max_data_list (idx).ITEM_CATALOG_CATEGORY,
                                        lv_dem_max_data_list (idx).PID_CATEGORY,
                                        lv_dem_max_data_list (idx).BL,
                                        lv_dem_max_data_list (idx).RF_FORECAST, lv_dem_max_data_list (idx).WS_FORECAST, 
                                     lv_dem_max_data_list (idx).RF_ADJUSTED_FORECAST, lv_dem_max_data_list (idx).UNFULFILLED_FORECAST,lv_dem_max_data_list (idx).OLD_DEMAND);
   
   
                           IF (lv_dem_max_data_list (idx).PRODUCT_SPARE_NAME
                                  IS NOT NULL)
                           THEN
                              INSERT
                                INTO CRPADM.RC_FIN_DEMAND_LIST (
                                        PRODUCT_NAME,
                                        PRODUCT_DESCRIPTION,
                                        PRODUCT_FAMILY,
                                        PRODUCT_TYPE,
                                        EOS,
                                        BUSINESS_UNIT,
                                        PRODUCT_LIFE_CYCLE,
                                        UNIT_STD_COST_USD,
                                        ASP,
                                        POE_MAX,
                                        STORAGE_MAX,
                                        QOH,
                                        VR_AVAIL_QTY,
                                        DEMAND_MAX,
                                        CONDITION_OF_INV,
                                        PRIORITY,
                                        FGI_QTY,
                                        FGIX_QTY,
                                        DGI_QTY,
                                        LIST_GENERATION_DATE,
                                        BLOCKED_PID_FROM,
                                        REASON_FOR_BLOCKED_PID,
                                        DGI,
                                        FGI,
                                        WIP,
                                        NIB,
                                        TOTAL_QTY,
                                        CONS_QTY,
                                        NETTABLE_DGI_QTY,
                                        NETTABLE_FGI_QTY,
                                        TOTAL_NETTABLE_QTY,
                                        CONS_PERCENTAGE,
                                        CUR_SALES_UNITS,
                                        MOS,
                                        NETTABLE_MOS,
                                        REVENUE_BANDS,
                                        MOS_BANDS,
                                        FCS,
                                        BACKLOG,
                                        INCLUDE_OR_EXCLUDE,
                                        INCLUDE_OR_EXCLUDE_REASON,
                                        --                            END_OF_LAST_SUPPORT_DATE,
                                        REPAIR_METHOD,
                                        RF_CREATION_DATE,
                                        TOTAL_RESERVATIONS,
                                        RF_PID,
                                        SERVICE_REPAIR_FLAG,
                                        GPL,
                                        EXPECTED_RECEIPTS,
                                        REFRESH_LIFE_CYCLE,
                                        IN_TRANSIT_POE,
                                        IN_TRANSIT_NIB,
                                        IN_TRANSIT_DGI,
                                        ITEM_TYPE,
                                        ITEM_CATALOG_CATEGORY,
                                        PID_CATEGORY,
                                        BL,
                                       RF_FORECAST, WS_FORECAST, 
                                     RF_ADJUSTED_FORECAST, UNFULFILLED_FORECAST,OLD_DEMAND)
                                 VALUES (
                                           lv_dem_max_data_list (idx).PRODUCT_SPARE_NAME,
                                           lv_dem_max_data_list (idx).PRODUCT_DESCRIPTION,
                                           lv_dem_max_data_list (idx).PRODUCT_FAMILY,
                                           lv_dem_max_data_list (idx).PRODUCT_TYPE,
                                           lv_dem_max_data_list (idx).EOS,
                                           lv_dem_max_data_list (idx).BUSINESS_UNIT,
                                           lv_dem_max_data_list (idx).PRODUCT_LIFE_CYCLE,
                                           lv_dem_max_data_list (idx).UNIT_STD_COST_USD,
                                           lv_dem_max_data_list (idx).ASP,
                                           lv_dem_max_data_list (idx).WPM,
                                           lv_dem_max_data_list (idx).STORAGE_MAX,
                                           lv_dem_max_data_list (idx).QOH,
                                           0,
                                           (  lv_dem_max_data_list (idx).DEMAND_MAX
                                            - lv_mfg_avail_to_alloc),
                                           lv_dem_max_data_list (idx).CONDITION_OF_INV,
                                           lv_dem_max_data_list (idx).PRIORITY,
                                           lv_dem_max_data_list (idx).FGI_QTY,
                                           lv_dem_max_data_list (idx).FGIX_QTY,
                                           lv_dem_max_data_list (idx).DGI_QTY,
                                           lv_dem_max_data_list (idx).LIST_GENERATION_DATE,
                                           lv_dem_max_data_list (idx).BLOCKED_PID_FROM,
                                           lv_dem_max_data_list (idx).REASON_FOR_BLOCKED_PID,
                                           lv_dem_max_data_list (idx).DGI,
                                           lv_dem_max_data_list (idx).FGI,
                                           lv_dem_max_data_list (idx).WIP,
                                           lv_dem_max_data_list (idx).NIB,
                                           lv_dem_max_data_list (idx).TOTAL_QTY,
                                           lv_dem_max_data_list (idx).CONS_QTY,
                                           lv_dem_max_data_list (idx).NETTABLE_DGI_QTY,
                                           lv_dem_max_data_list (idx).NETTABLE_FGI_QTY,
                                           lv_dem_max_data_list (idx).TOTAL_NETTABLE_QTY,
                                           lv_dem_max_data_list (idx).CONS_PERCENTAGE,
                                           lv_dem_max_data_list (idx).CUR_SALES_UNITS,
                                           lv_dem_max_data_list (idx).MOS,
                                           lv_dem_max_data_list (idx).NETTABLE_MOS,
                                           lv_dem_max_data_list (idx).REVENUE_BANDS,
                                           lv_dem_max_data_list (idx).MOS_BANDS,
                                           lv_dem_max_data_list (idx).FCS,
                                           lv_dem_max_data_list (idx).BACKLOG,
                                           lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE,
                                           lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE_REASON,
                                           --                               lv_dem_max_data_list(idx).END_OF_LAST_SUPPORT_DATE,
                                           lv_dem_max_data_list (idx).REPAIR_METHOD,
                                           lv_dem_max_data_list (idx).RF_CREATION_DATE,
                                           lv_dem_max_data_list (idx).TOTAL_RESERVATIONS,
                                           lv_dem_max_data_list (idx).RF_PID,
                                           lv_dem_max_data_list (idx).SERVICE_REPAIR_FLAG,
                                           lv_dem_max_data_list (idx).GPL,
                                           0,
                                           lv_dem_max_data_list (idx).REFRESH_LIFE_CYCLE,
                                           lv_dem_max_data_list (idx).IN_TRANSIT_POE,
                                           lv_dem_max_data_list (idx).IN_TRANSIT_NIB,
                                           lv_dem_max_data_list (idx).IN_TRANSIT_DGI,
                                           lv_dem_max_data_list (idx).ITEM_TYPE,
                                           lv_dem_max_data_list (idx).ITEM_CATALOG_CATEGORY,
                                           lv_dem_max_data_list (idx).PID_CATEGORY,
                                           lv_dem_max_data_list (idx).BL,
                                           lv_dem_max_data_list (idx).RF_FORECAST, lv_dem_max_data_list (idx).WS_FORECAST, 
                                     lv_dem_max_data_list (idx).RF_ADJUSTED_FORECAST, lv_dem_max_data_list (idx).UNFULFILLED_FORECAST,lv_dem_max_data_list (idx).OLD_DEMAND);
                           ELSE
                              UPDATE RC_FIN_DEMAND_LIST
                                 SET DEMAND_MAX =ROUND(
                                          lv_dem_max_data_list (idx).DEMAND_MAX
                                        - lv_mfg_avail_to_alloc)
                               WHERE PRODUCT_NAME =
                                        lv_dem_max_data_list (idx).CISCO_PRODUCT_NAME;
   
                              COMMIT;
                           END IF;
                        END IF;
                     ELSE
                        IF lv_spare_avail_to_alloc >
                              lv_dem_max_data_list (idx).DEMAND_MAX
                        THEN
                           CASE
                              WHEN lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE =
                                      'User Inclusion'
                              THEN
                                 lv_condition_of_inv :=
                                    lv_dem_max_data_list (idx).CONDITION_OF_INV;
                              WHEN lv_dem_max_data_list (idx).DEMAND_MAX <=
                                      lv_spare_fgi
                              THEN
                                 lv_condition_of_inv := 'FGI';
                              WHEN lv_dem_max_data_list (idx).DEMAND_MAX <=
                                      (lv_spare_fgi + lv_spare_fgix)
                              THEN
                                 lv_condition_of_inv := 'FGIX and FGI';
                              ELSE
                                 lv_condition_of_inv :=
                                    lv_dem_max_data_list (idx).CONDITION_OF_INV;
                           END CASE;
   
                           INSERT
                             INTO CRPADM.RC_FIN_DEMAND_LIST (
                                     PRODUCT_NAME,
                                     PRODUCT_DESCRIPTION,
                                     PRODUCT_FAMILY,
                                     PRODUCT_TYPE,
                                     EOS,
                                     BUSINESS_UNIT,
                                     PRODUCT_LIFE_CYCLE,
                                     UNIT_STD_COST_USD,
                                     ASP,
                                     POE_MAX,
                                     STORAGE_MAX,
                                     QOH,
                                     VR_AVAIL_QTY,
                                     DEMAND_MAX,
                                     CONDITION_OF_INV,
                                     PRIORITY,
                                     FGI_QTY,
                                     FGIX_QTY,
                                     DGI_QTY,
                                     LIST_GENERATION_DATE,
                                     BLOCKED_PID_FROM,
                                     REASON_FOR_BLOCKED_PID,
                                     DGI,
                                     FGI,
                                     WIP,
                                     NIB,
                                     TOTAL_QTY,
                                     CONS_QTY,
                                     NETTABLE_DGI_QTY,
                                     NETTABLE_FGI_QTY,
                                     TOTAL_NETTABLE_QTY,
                                     CONS_PERCENTAGE,
                                     CUR_SALES_UNITS,
                                     MOS,
                                     NETTABLE_MOS,
                                     REVENUE_BANDS,
                                     MOS_BANDS,
                                     FCS,
                                     BACKLOG,
                                     INCLUDE_OR_EXCLUDE,
                                     INCLUDE_OR_EXCLUDE_REASON,
                                     --                                                 END_OF_LAST_SUPPORT_DATE,
                                     REPAIR_METHOD,
                                     RF_CREATION_DATE,
                                     TOTAL_RESERVATIONS,
                                     RF_PID,
                                     SERVICE_REPAIR_FLAG,
                                     GPL,
                                     EXPECTED_RECEIPTS,
                                     REFRESH_LIFE_CYCLE,
                                     IN_TRANSIT_POE,
                                     IN_TRANSIT_NIB,
                                     IN_TRANSIT_DGI,
                                     ITEM_TYPE,
                                     ITEM_CATALOG_CATEGORY,
                                     PID_CATEGORY,
                                     BL,
                                     RF_FORECAST, WS_FORECAST, 
                                     RF_ADJUSTED_FORECAST,UNFULFILLED_FORECAST,OLD_DEMAND)
                              VALUES (
                                        lv_dem_max_data_list (idx).PRODUCT_SPARE_NAME,
                                        lv_dem_max_data_list (idx).PRODUCT_DESCRIPTION,
                                        lv_dem_max_data_list (idx).PRODUCT_FAMILY,
                                        lv_dem_max_data_list (idx).PRODUCT_TYPE,
                                        lv_dem_max_data_list (idx).EOS,
                                        lv_dem_max_data_list (idx).BUSINESS_UNIT,
                                        lv_dem_max_data_list (idx).PRODUCT_LIFE_CYCLE,
                                        lv_dem_max_data_list (idx).UNIT_STD_COST_USD,
                                        lv_dem_max_data_list (idx).ASP,
                                        lv_dem_max_data_list (idx).WPM,
                                        lv_dem_max_data_list (idx).STORAGE_MAX,
                                        lv_dem_max_data_list (idx).QOH,
                                        lv_spare_avail_to_alloc,
                                        lv_dem_max_data_list (idx).DEMAND_MAX,
                                        lv_condition_of_inv, --lv_dem_max_data_list (idx).CONDITION_OF_INV,
                                        lv_dem_max_data_list (idx).PRIORITY,
                                        lv_dem_max_data_list (idx).FGI_QTY,
                                        lv_dem_max_data_list (idx).FGIX_QTY,
                                        lv_dem_max_data_list (idx).DGI_QTY,
                                        lv_dem_max_data_list (idx).LIST_GENERATION_DATE,
                                        lv_dem_max_data_list (idx).BLOCKED_PID_FROM,
                                        lv_dem_max_data_list (idx).REASON_FOR_BLOCKED_PID,
                                        lv_dem_max_data_list (idx).DGI,
                                        lv_dem_max_data_list (idx).FGI,
                                        lv_dem_max_data_list (idx).WIP,
                                        lv_dem_max_data_list (idx).NIB,
                                        lv_dem_max_data_list (idx).TOTAL_QTY,
                                        lv_dem_max_data_list (idx).CONS_QTY,
                                        lv_dem_max_data_list (idx).NETTABLE_DGI_QTY,
                                        lv_dem_max_data_list (idx).NETTABLE_FGI_QTY,
                                        lv_dem_max_data_list (idx).TOTAL_NETTABLE_QTY,
                                        lv_dem_max_data_list (idx).CONS_PERCENTAGE,
                                        lv_dem_max_data_list (idx).CUR_SALES_UNITS,
                                        lv_dem_max_data_list (idx).MOS,
                                        lv_dem_max_data_list (idx).NETTABLE_MOS,
                                        lv_dem_max_data_list (idx).REVENUE_BANDS,
                                        lv_dem_max_data_list (idx).MOS_BANDS,
                                        lv_dem_max_data_list (idx).FCS,
                                        lv_dem_max_data_list (idx).BACKLOG,
                                        lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE,
                                        lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE_REASON,
                                        --                       lv_dem_max_data_list(idx).END_OF_LAST_SUPPORT_DATE,
                                        lv_dem_max_data_list (idx).REPAIR_METHOD,
                                        lv_dem_max_data_list (idx).RF_CREATION_DATE,
                                        lv_dem_max_data_list (idx).TOTAL_RESERVATIONS,
                                        lv_dem_max_data_list (idx).RF_PID,
                                        lv_dem_max_data_list (idx).SERVICE_REPAIR_FLAG,
                                        lv_dem_max_data_list (idx).GPL,
                                        LEAST (
                                           lv_spare_avail_to_alloc,
                                           lv_dem_max_data_list (idx).DEMAND_MAX),
                                        lv_dem_max_data_list (idx).REFRESH_LIFE_CYCLE,
                                        lv_dem_max_data_list (idx).IN_TRANSIT_POE,
                                        lv_dem_max_data_list (idx).IN_TRANSIT_NIB,
                                        lv_dem_max_data_list (idx).IN_TRANSIT_DGI,
                                        lv_dem_max_data_list (idx).ITEM_TYPE,
                                        lv_dem_max_data_list (idx).ITEM_CATALOG_CATEGORY,
                                        lv_dem_max_data_list (idx).PID_CATEGORY,
                                        lv_dem_max_data_list (idx).BL,
                                        lv_dem_max_data_list (idx).RF_FORECAST, lv_dem_max_data_list (idx).WS_FORECAST, 
                                     lv_dem_max_data_list (idx).RF_ADJUSTED_FORECAST, lv_dem_max_data_list (idx).UNFULFILLED_FORECAST,lv_dem_max_data_list (idx).OLD_DEMAND);
                        ELSIF lv_spare_avail_to_alloc = 0
                        THEN
                           IF lv_dem_max_data_list (idx).CISCO_PRODUCT_NAME
                                 IS NOT NULL
                           THEN
                              INSERT
                                INTO CRPADM.RC_FIN_DEMAND_LIST (
                                        PRODUCT_NAME,
                                        PRODUCT_DESCRIPTION,
                                        PRODUCT_FAMILY,
                                        PRODUCT_TYPE,
                                        EOS,
                                        BUSINESS_UNIT,
                                        PRODUCT_LIFE_CYCLE,
                                        UNIT_STD_COST_USD,
                                        ASP,
                                        POE_MAX,
                                        STORAGE_MAX,
                                        QOH,
                                        VR_AVAIL_QTY,
                                        DEMAND_MAX,
                                        CONDITION_OF_INV,
                                        PRIORITY,
                                        FGI_QTY,
                                        FGIX_QTY,
                                        DGI_QTY,
                                        LIST_GENERATION_DATE,
                                        BLOCKED_PID_FROM,
                                        REASON_FOR_BLOCKED_PID,
                                        DGI,
                                        FGI,
                                        WIP,
                                        NIB,
                                        TOTAL_QTY,
                                        CONS_QTY,
                                        NETTABLE_DGI_QTY,
                                        NETTABLE_FGI_QTY,
                                        TOTAL_NETTABLE_QTY,
                                        CONS_PERCENTAGE,
                                        CUR_SALES_UNITS,
                                        MOS,
                                        NETTABLE_MOS,
                                        REVENUE_BANDS,
                                        MOS_BANDS,
                                        FCS,
                                        BACKLOG,
                                        INCLUDE_OR_EXCLUDE,
                                        INCLUDE_OR_EXCLUDE_REASON,
                                        --                            END_OF_LAST_SUPPORT_DATE,
                                        REPAIR_METHOD,
                                        RF_CREATION_DATE,
                                        TOTAL_RESERVATIONS,
                                        RF_PID,
                                        SERVICE_REPAIR_FLAG,
                                        GPL,
                                        EXPECTED_RECEIPTS,
                                        REFRESH_LIFE_CYCLE,
                                        IN_TRANSIT_POE,
                                        IN_TRANSIT_NIB,
                                        IN_TRANSIT_DGI,
                                        ITEM_TYPE,
                                        ITEM_CATALOG_CATEGORY,
                                        PID_CATEGORY,
                                        BL,
                                        RF_FORECAST, WS_FORECAST, 
                                     RF_ADJUSTED_FORECAST, UNFULFILLED_FORECAST,OLD_DEMAND)
                                 VALUES (
                                           lv_dem_max_data_list (idx).CISCO_PRODUCT_NAME,
                                           lv_dem_max_data_list (idx).PRODUCT_DESCRIPTION,
                                           lv_dem_max_data_list (idx).PRODUCT_FAMILY,
                                           lv_dem_max_data_list (idx).PRODUCT_TYPE,
                                           lv_dem_max_data_list (idx).EOS,
                                           lv_dem_max_data_list (idx).BUSINESS_UNIT,
                                           lv_dem_max_data_list (idx).PRODUCT_LIFE_CYCLE,
                                           lv_dem_max_data_list (idx).UNIT_STD_COST_USD,
                                           lv_dem_max_data_list (idx).ASP,
                                           lv_dem_max_data_list (idx).WPM,
                                           lv_dem_max_data_list (idx).STORAGE_MAX,
                                           lv_dem_max_data_list (idx).QOH,
                                           0,
                                           lv_dem_max_data_list (idx).DEMAND_MAX,
                                           lv_dem_max_data_list (idx).CONDITION_OF_INV,
                                           lv_dem_max_data_list (idx).PRIORITY,
                                           lv_dem_max_data_list (idx).FGI_QTY,
                                           lv_dem_max_data_list (idx).FGIX_QTY,
                                           lv_dem_max_data_list (idx).DGI_QTY,
                                           lv_dem_max_data_list (idx).LIST_GENERATION_DATE,
                                           lv_dem_max_data_list (idx).BLOCKED_PID_FROM,
                                           lv_dem_max_data_list (idx).REASON_FOR_BLOCKED_PID,
                                           lv_dem_max_data_list (idx).DGI,
                                           lv_dem_max_data_list (idx).FGI,
                                           lv_dem_max_data_list (idx).WIP,
                                           lv_dem_max_data_list (idx).NIB,
                                           lv_dem_max_data_list (idx).TOTAL_QTY,
                                           lv_dem_max_data_list (idx).CONS_QTY,
                                           lv_dem_max_data_list (idx).NETTABLE_DGI_QTY,
                                           lv_dem_max_data_list (idx).NETTABLE_FGI_QTY,
                                           lv_dem_max_data_list (idx).TOTAL_NETTABLE_QTY,
                                           lv_dem_max_data_list (idx).CONS_PERCENTAGE,
                                           lv_dem_max_data_list (idx).CUR_SALES_UNITS,
                                           lv_dem_max_data_list (idx).MOS,
                                           lv_dem_max_data_list (idx).NETTABLE_MOS,
                                           lv_dem_max_data_list (idx).REVENUE_BANDS,
                                           lv_dem_max_data_list (idx).MOS_BANDS,
                                           lv_dem_max_data_list (idx).FCS,
                                           lv_dem_max_data_list (idx).BACKLOG,
                                           lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE,
                                           lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE_REASON,
                                           --                       lv_dem_max_data_list(idx).END_OF_LAST_SUPPORT_DATE,
                                           lv_dem_max_data_list (idx).REPAIR_METHOD,
                                           lv_dem_max_data_list (idx).RF_CREATION_DATE,
                                           lv_dem_max_data_list (idx).TOTAL_RESERVATIONS,
                                           lv_dem_max_data_list (idx).RF_PID,
                                           lv_dem_max_data_list (idx).SERVICE_REPAIR_FLAG,
                                           lv_dem_max_data_list (idx).GPL,
                                           0,
                                           lv_dem_max_data_list (idx).REFRESH_LIFE_CYCLE,
                                           lv_dem_max_data_list (idx).IN_TRANSIT_POE,
                                           lv_dem_max_data_list (idx).IN_TRANSIT_NIB,
                                           lv_dem_max_data_list (idx).IN_TRANSIT_DGI,
                                           lv_dem_max_data_list (idx).ITEM_TYPE,
                                           lv_dem_max_data_list (idx).ITEM_CATALOG_CATEGORY,
                                           lv_dem_max_data_list (idx).PID_CATEGORY,
                                           lv_dem_max_data_list (idx).BL,
                                           lv_dem_max_data_list (idx).RF_FORECAST, lv_dem_max_data_list (idx).WS_FORECAST, 
                                     lv_dem_max_data_list (idx).RF_ADJUSTED_FORECAST, lv_dem_max_data_list (idx).UNFULFILLED_FORECAST,lv_dem_max_data_list (idx).OLD_DEMAND);
                           END IF;
   
                           IF lv_dem_max_data_list (idx).PRODUCT_SPARE_NAME
                                 IS NOT NULL
                           THEN
                              INSERT
                                INTO CRPADM.RC_FIN_DEMAND_LIST (
                                        PRODUCT_NAME,
                                        PRODUCT_DESCRIPTION,
                                        PRODUCT_FAMILY,
                                        PRODUCT_TYPE,
                                        EOS,
                                        BUSINESS_UNIT,
                                        PRODUCT_LIFE_CYCLE,
                                        UNIT_STD_COST_USD,
                                        ASP,
                                        POE_MAX,
                                        STORAGE_MAX,
                                        QOH,
                                        VR_AVAIL_QTY,
                                        DEMAND_MAX,
                                        CONDITION_OF_INV,
                                        PRIORITY,
                                        FGI_QTY,
                                        FGIX_QTY,
                                        DGI_QTY,
                                        LIST_GENERATION_DATE,
                                        BLOCKED_PID_FROM,
                                        REASON_FOR_BLOCKED_PID,
                                        DGI,
                                        FGI,
                                        WIP,
                                        NIB,
                                        TOTAL_QTY,
                                        CONS_QTY,
                                        NETTABLE_DGI_QTY,
                                        NETTABLE_FGI_QTY,
                                        TOTAL_NETTABLE_QTY,
                                        CONS_PERCENTAGE,
                                        CUR_SALES_UNITS,
                                        MOS,
                                        NETTABLE_MOS,
                                        REVENUE_BANDS,
                                        MOS_BANDS,
                                        FCS,
                                        BACKLOG,
                                        INCLUDE_OR_EXCLUDE,
                                        INCLUDE_OR_EXCLUDE_REASON,
                                        --                                                 END_OF_LAST_SUPPORT_DATE,
                                        REPAIR_METHOD,
                                        RF_CREATION_DATE,
                                        TOTAL_RESERVATIONS,
                                        RF_PID,
                                        SERVICE_REPAIR_FLAG,
                                        GPL,
                                        EXPECTED_RECEIPTS,
                                        REFRESH_LIFE_CYCLE,
                                        IN_TRANSIT_POE,
                                        IN_TRANSIT_NIB,
                                        IN_TRANSIT_DGI,
                                        ITEM_TYPE,
                                        ITEM_CATALOG_CATEGORY,
                                        PID_CATEGORY,
                                        BL,
                                       RF_FORECAST, WS_FORECAST, 
                                     RF_ADJUSTED_FORECAST, UNFULFILLED_FORECAST,OLD_DEMAND)
                                 VALUES (
                                           lv_dem_max_data_list (idx).PRODUCT_SPARE_NAME,
                                           lv_dem_max_data_list (idx).PRODUCT_DESCRIPTION,
                                           lv_dem_max_data_list (idx).PRODUCT_FAMILY,
                                           lv_dem_max_data_list (idx).PRODUCT_TYPE,
                                           lv_dem_max_data_list (idx).EOS,
                                           lv_dem_max_data_list (idx).BUSINESS_UNIT,
                                           lv_dem_max_data_list (idx).PRODUCT_LIFE_CYCLE,
                                           lv_dem_max_data_list (idx).UNIT_STD_COST_USD,
                                           lv_dem_max_data_list (idx).ASP,
                                           lv_dem_max_data_list (idx).WPM,
                                           lv_dem_max_data_list (idx).STORAGE_MAX,
                                           lv_dem_max_data_list (idx).QOH,
                                           0,
                                           lv_dem_max_data_list (idx).DEMAND_MAX,
                                           lv_dem_max_data_list (idx).CONDITION_OF_INV,
                                           lv_dem_max_data_list (idx).PRIORITY,
                                           lv_dem_max_data_list (idx).FGI_QTY,
                                           lv_dem_max_data_list (idx).FGIX_QTY,
                                           lv_dem_max_data_list (idx).DGI_QTY,
                                           lv_dem_max_data_list (idx).LIST_GENERATION_DATE,
                                           lv_dem_max_data_list (idx).BLOCKED_PID_FROM,
                                           lv_dem_max_data_list (idx).REASON_FOR_BLOCKED_PID,
                                           lv_dem_max_data_list (idx).DGI,
                                           lv_dem_max_data_list (idx).FGI,
                                           lv_dem_max_data_list (idx).WIP,
                                           lv_dem_max_data_list (idx).NIB,
                                           lv_dem_max_data_list (idx).TOTAL_QTY,
                                           lv_dem_max_data_list (idx).CONS_QTY,
                                           lv_dem_max_data_list (idx).NETTABLE_DGI_QTY,
                                           lv_dem_max_data_list (idx).NETTABLE_FGI_QTY,
                                           lv_dem_max_data_list (idx).TOTAL_NETTABLE_QTY,
                                           lv_dem_max_data_list (idx).CONS_PERCENTAGE,
                                           lv_dem_max_data_list (idx).CUR_SALES_UNITS,
                                           lv_dem_max_data_list (idx).MOS,
                                           lv_dem_max_data_list (idx).NETTABLE_MOS,
                                           lv_dem_max_data_list (idx).REVENUE_BANDS,
                                           lv_dem_max_data_list (idx).MOS_BANDS,
                                           lv_dem_max_data_list (idx).FCS,
                                           lv_dem_max_data_list (idx).BACKLOG,
                                           lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE,
                                           lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE_REASON,
                                           --                       lv_dem_max_data_list(idx).END_OF_LAST_SUPPORT_DATE,
                                           lv_dem_max_data_list (idx).REPAIR_METHOD,
                                           lv_dem_max_data_list (idx).RF_CREATION_DATE,
                                           lv_dem_max_data_list (idx).TOTAL_RESERVATIONS,
                                           lv_dem_max_data_list (idx).RF_PID,
                                           lv_dem_max_data_list (idx).SERVICE_REPAIR_FLAG,
                                           lv_dem_max_data_list (idx).GPL,
                                           0,
                                           lv_dem_max_data_list (idx).REFRESH_LIFE_CYCLE,
                                           lv_dem_max_data_list (idx).IN_TRANSIT_POE,
                                           lv_dem_max_data_list (idx).IN_TRANSIT_NIB,
                                           lv_dem_max_data_list (idx).IN_TRANSIT_DGI,
                                           lv_dem_max_data_list (idx).ITEM_TYPE,
                                           lv_dem_max_data_list (idx).ITEM_CATALOG_CATEGORY,
                                           lv_dem_max_data_list (idx).PID_CATEGORY,
                                           lv_dem_max_data_list (idx).BL,
                                           lv_dem_max_data_list (idx).RF_FORECAST, lv_dem_max_data_list (idx).WS_FORECAST, 
                                     lv_dem_max_data_list (idx).RF_ADJUSTED_FORECAST, lv_dem_max_data_list (idx).UNFULFILLED_FORECAST,lv_dem_max_data_list (idx).OLD_DEMAND);
                           END IF;
                        ELSE
                           INSERT
                             INTO CRPADM.RC_FIN_DEMAND_LIST (
                                     PRODUCT_NAME,
                                     PRODUCT_DESCRIPTION,
                                     PRODUCT_FAMILY,
                                     PRODUCT_TYPE,
                                     EOS,
                                     BUSINESS_UNIT,
                                     PRODUCT_LIFE_CYCLE,
                                     UNIT_STD_COST_USD,
                                     ASP,
                                     POE_MAX,
                                     STORAGE_MAX,
                                     QOH,
                                     VR_AVAIL_QTY,
                                     DEMAND_MAX,
                                     CONDITION_OF_INV,
                                     PRIORITY,
                                     FGI_QTY,
                                     FGIX_QTY,
                                     DGI_QTY,
                                     LIST_GENERATION_DATE,
                                     BLOCKED_PID_FROM,
                                     REASON_FOR_BLOCKED_PID,
                                     DGI,
                                     FGI,
                                     WIP,
                                     NIB,
                                     TOTAL_QTY,
                                     CONS_QTY,
                                     NETTABLE_DGI_QTY,
                                     NETTABLE_FGI_QTY,
                                     TOTAL_NETTABLE_QTY,
                                     CONS_PERCENTAGE,
                                     CUR_SALES_UNITS,
                                     MOS,
                                     NETTABLE_MOS,
                                     REVENUE_BANDS,
                                     MOS_BANDS,
                                     FCS,
                                     BACKLOG,
                                     INCLUDE_OR_EXCLUDE,
                                     INCLUDE_OR_EXCLUDE_REASON,
                                     --                                                 END_OF_LAST_SUPPORT_DATE,
                                     REPAIR_METHOD,
                                     RF_CREATION_DATE,
                                     TOTAL_RESERVATIONS,
                                     RF_PID,
                                     SERVICE_REPAIR_FLAG,
                                     GPL,
                                     EXPECTED_RECEIPTS,
                                     REFRESH_LIFE_CYCLE,
                                     IN_TRANSIT_POE,
                                     IN_TRANSIT_NIB,
                                     IN_TRANSIT_DGI,
                                     ITEM_TYPE,
                                     ITEM_CATALOG_CATEGORY,
                                     PID_CATEGORY,
                                     BL,
                                    RF_FORECAST, WS_FORECAST, 
                                    RF_ADJUSTED_FORECAST, UNFULFILLED_FORECAST,OLD_DEMAND)
                              VALUES (
                                        lv_dem_max_data_list (idx).PRODUCT_SPARE_NAME,
                                        lv_dem_max_data_list (idx).PRODUCT_DESCRIPTION,
                                        lv_dem_max_data_list (idx).PRODUCT_FAMILY,
                                        lv_dem_max_data_list (idx).PRODUCT_TYPE,
                                        lv_dem_max_data_list (idx).EOS,
                                        lv_dem_max_data_list (idx).BUSINESS_UNIT,
                                        lv_dem_max_data_list (idx).PRODUCT_LIFE_CYCLE,
                                        lv_dem_max_data_list (idx).UNIT_STD_COST_USD,
                                        lv_dem_max_data_list (idx).ASP,
                                        lv_dem_max_data_list (idx).WPM,
                                        lv_dem_max_data_list (idx).STORAGE_MAX,
                                        lv_dem_max_data_list (idx).QOH,
                                        lv_spare_avail_to_alloc,
                                          lv_dem_max_data_list (idx).DEMAND_MAX
                                        - lv_spare_avail_to_alloc,
                                        lv_dem_max_data_list (idx).CONDITION_OF_INV,
                                        lv_dem_max_data_list (idx).PRIORITY,
                                        lv_dem_max_data_list (idx).FGI_QTY,
                                        lv_dem_max_data_list (idx).FGIX_QTY,
                                        lv_dem_max_data_list (idx).DGI_QTY,
                                        lv_dem_max_data_list (idx).LIST_GENERATION_DATE,
                                        lv_dem_max_data_list (idx).BLOCKED_PID_FROM,
                                        lv_dem_max_data_list (idx).REASON_FOR_BLOCKED_PID,
                                        lv_dem_max_data_list (idx).DGI,
                                        lv_dem_max_data_list (idx).FGI,
                                        lv_dem_max_data_list (idx).WIP,
                                        lv_dem_max_data_list (idx).NIB,
                                        lv_dem_max_data_list (idx).TOTAL_QTY,
                                        lv_dem_max_data_list (idx).CONS_QTY,
                                        lv_dem_max_data_list (idx).NETTABLE_DGI_QTY,
                                        lv_dem_max_data_list (idx).NETTABLE_FGI_QTY,
                                        lv_dem_max_data_list (idx).TOTAL_NETTABLE_QTY,
                                        lv_dem_max_data_list (idx).CONS_PERCENTAGE,
                                        lv_dem_max_data_list (idx).CUR_SALES_UNITS,
                                        lv_dem_max_data_list (idx).MOS,
                                        lv_dem_max_data_list (idx).NETTABLE_MOS,
                                        lv_dem_max_data_list (idx).REVENUE_BANDS,
                                        lv_dem_max_data_list (idx).MOS_BANDS,
                                        lv_dem_max_data_list (idx).FCS,
                                        lv_dem_max_data_list (idx).BACKLOG,
                                        lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE,
                                        lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE_REASON,
                                        --                       lv_dem_max_data_list(idx).END_OF_LAST_SUPPORT_DATE,
                                        lv_dem_max_data_list (idx).REPAIR_METHOD,
                                        lv_dem_max_data_list (idx).RF_CREATION_DATE,
                                        lv_dem_max_data_list (idx).TOTAL_RESERVATIONS,
                                        lv_dem_max_data_list (idx).RF_PID,
                                        lv_dem_max_data_list (idx).SERVICE_REPAIR_FLAG,
                                        lv_dem_max_data_list (idx).GPL,
                                        lv_spare_avail_to_alloc,
                                        lv_dem_max_data_list (idx).REFRESH_LIFE_CYCLE,
                                        lv_dem_max_data_list (idx).IN_TRANSIT_POE,
                                        lv_dem_max_data_list (idx).IN_TRANSIT_NIB,
                                        lv_dem_max_data_list (idx).IN_TRANSIT_DGI,
                                        lv_dem_max_data_list (idx).ITEM_TYPE,
                                        lv_dem_max_data_list (idx).ITEM_CATALOG_CATEGORY,
                                        lv_dem_max_data_list (idx).PID_CATEGORY,
                                        lv_dem_max_data_list (idx).BL,
                                        lv_dem_max_data_list (idx).RF_FORECAST, lv_dem_max_data_list (idx).WS_FORECAST, 
                                     lv_dem_max_data_list (idx).RF_ADJUSTED_FORECAST, lv_dem_max_data_list (idx).UNFULFILLED_FORECAST,lv_dem_max_data_list (idx).OLD_DEMAND);
   
                           IF lv_dem_max_data_list (idx).CISCO_PRODUCT_NAME
                                 IS NOT NULL
                           THEN
                              INSERT
                                INTO CRPADM.RC_FIN_DEMAND_LIST (
                                        PRODUCT_NAME,
                                        PRODUCT_DESCRIPTION,
                                        PRODUCT_FAMILY,
                                        PRODUCT_TYPE,
                                        EOS,
                                        BUSINESS_UNIT,
                                        PRODUCT_LIFE_CYCLE,
                                        UNIT_STD_COST_USD,
                                        ASP,
                                        POE_MAX,
                                        STORAGE_MAX,
                                        QOH,
                                        VR_AVAIL_QTY,
                                        DEMAND_MAX,
                                        CONDITION_OF_INV,
                                        PRIORITY,
                                        FGI_QTY,
                                        FGIX_QTY,
                                        DGI_QTY,
                                        LIST_GENERATION_DATE,
                                        BLOCKED_PID_FROM,
                                        REASON_FOR_BLOCKED_PID,
                                        DGI,
                                        FGI,
                                        WIP,
                                        NIB,
                                        TOTAL_QTY,
                                        CONS_QTY,
                                        NETTABLE_DGI_QTY,
                                        NETTABLE_FGI_QTY,
                                        TOTAL_NETTABLE_QTY,
                                        CONS_PERCENTAGE,
                                        CUR_SALES_UNITS,
                                        MOS,
                                        NETTABLE_MOS,
                                        REVENUE_BANDS,
                                        MOS_BANDS,
                                        FCS,
                                        BACKLOG,
                                        INCLUDE_OR_EXCLUDE,
                                        INCLUDE_OR_EXCLUDE_REASON,
                                        --                            END_OF_LAST_SUPPORT_DATE,
                                        REPAIR_METHOD,
                                        RF_CREATION_DATE,
                                        TOTAL_RESERVATIONS,
                                        RF_PID,
                                        SERVICE_REPAIR_FLAG,
                                        GPL,
                                        EXPECTED_RECEIPTS,
                                        REFRESH_LIFE_CYCLE,
                                        IN_TRANSIT_POE,
                                        IN_TRANSIT_NIB,
                                        IN_TRANSIT_DGI,
                                        ITEM_TYPE,
                                        ITEM_CATALOG_CATEGORY,
                                        PID_CATEGORY,
                                        BL,
                                        RF_FORECAST,WS_FORECAST, 
                                     RF_ADJUSTED_FORECAST, UNFULFILLED_FORECAST,OLD_DEMAND)
                                 VALUES (
                                           lv_dem_max_data_list (idx).CISCO_PRODUCT_NAME,
                                           lv_dem_max_data_list (idx).PRODUCT_DESCRIPTION,
                                           lv_dem_max_data_list (idx).PRODUCT_FAMILY,
                                           lv_dem_max_data_list (idx).PRODUCT_TYPE,
                                           lv_dem_max_data_list (idx).EOS,
                                           lv_dem_max_data_list (idx).BUSINESS_UNIT,
                                           lv_dem_max_data_list (idx).PRODUCT_LIFE_CYCLE,
                                           lv_dem_max_data_list (idx).UNIT_STD_COST_USD,
                                           lv_dem_max_data_list (idx).ASP,
                                           lv_dem_max_data_list (idx).WPM,
                                           lv_dem_max_data_list (idx).STORAGE_MAX,
                                           lv_dem_max_data_list (idx).QOH,
                                           0,
                                           (  lv_dem_max_data_list (idx).DEMAND_MAX
                                            - lv_spare_avail_to_alloc),
                                           lv_dem_max_data_list (idx).CONDITION_OF_INV,
                                           lv_dem_max_data_list (idx).PRIORITY,
                                           lv_dem_max_data_list (idx).FGI_QTY,
                                           lv_dem_max_data_list (idx).FGIX_QTY,
                                           lv_dem_max_data_list (idx).DGI_QTY,
                                           lv_dem_max_data_list (idx).LIST_GENERATION_DATE,
                                           lv_dem_max_data_list (idx).BLOCKED_PID_FROM,
                                           lv_dem_max_data_list (idx).REASON_FOR_BLOCKED_PID,
                                           lv_dem_max_data_list (idx).DGI,
                                           lv_dem_max_data_list (idx).FGI,
                                           lv_dem_max_data_list (idx).WIP,
                                           lv_dem_max_data_list (idx).NIB,
                                           lv_dem_max_data_list (idx).TOTAL_QTY,
                                           lv_dem_max_data_list (idx).CONS_QTY,
                                           lv_dem_max_data_list (idx).NETTABLE_DGI_QTY,
                                           lv_dem_max_data_list (idx).NETTABLE_FGI_QTY,
                                           lv_dem_max_data_list (idx).TOTAL_NETTABLE_QTY,
                                           lv_dem_max_data_list (idx).CONS_PERCENTAGE,
                                           lv_dem_max_data_list (idx).CUR_SALES_UNITS,
                                           lv_dem_max_data_list (idx).MOS,
                                           lv_dem_max_data_list (idx).NETTABLE_MOS,
                                           lv_dem_max_data_list (idx).REVENUE_BANDS,
                                           lv_dem_max_data_list (idx).MOS_BANDS,
                                           lv_dem_max_data_list (idx).FCS,
                                           lv_dem_max_data_list (idx).BACKLOG,
                                           lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE,
                                           lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE_REASON,
                                           --                               lv_dem_max_data_list(idx).END_OF_LAST_SUPPORT_DATE,
                                           lv_dem_max_data_list (idx).REPAIR_METHOD,
                                           lv_dem_max_data_list (idx).RF_CREATION_DATE,
                                           lv_dem_max_data_list (idx).TOTAL_RESERVATIONS,
                                           lv_dem_max_data_list (idx).RF_PID,
                                           lv_dem_max_data_list (idx).SERVICE_REPAIR_FLAG,
                                           lv_dem_max_data_list (idx).GPL,
                                           0,
                                           lv_dem_max_data_list (idx).REFRESH_LIFE_CYCLE,
                                           lv_dem_max_data_list (idx).IN_TRANSIT_POE,
                                           lv_dem_max_data_list (idx).IN_TRANSIT_NIB,
                                           lv_dem_max_data_list (idx).IN_TRANSIT_DGI,
                                           lv_dem_max_data_list (idx).ITEM_TYPE,
                                           lv_dem_max_data_list (idx).ITEM_CATALOG_CATEGORY,
                                           lv_dem_max_data_list (idx).PID_CATEGORY,
                                           lv_dem_max_data_list (idx).BL,lv_dem_max_data_list (idx).RF_FORECAST, lv_dem_max_data_list (idx).WS_FORECAST, 
                                     lv_dem_max_data_list (idx).RF_ADJUSTED_FORECAST, lv_dem_max_data_list (idx).UNFULFILLED_FORECAST,lv_dem_max_data_list (idx).OLD_DEMAND);
                           ELSE
                              UPDATE RC_FIN_DEMAND_LIST
                                 SET DEMAND_MAX =ROUND(
                                          lv_dem_max_data_list (idx).DEMAND_MAX
                                        - lv_spare_avail_to_alloc)
                               WHERE PRODUCT_NAME =
                                        lv_dem_max_data_list (idx).PRODUCT_SPARE_NAME;
   
                              COMMIT;
                           END IF;
                        END IF;
                     END IF;
                  ELSE
                     IF lv_dem_max_data_list (idx).CISCO_PRODUCT_NAME
                           IS NOT NULL
                     THEN
                        INSERT
                          INTO CRPADM.RC_FIN_DEMAND_LIST (
                                  PRODUCT_NAME,
                                  PRODUCT_DESCRIPTION,
                                  PRODUCT_FAMILY,
                                  PRODUCT_TYPE,
                                  EOS,
                                  BUSINESS_UNIT,
                                  PRODUCT_LIFE_CYCLE,
                                  UNIT_STD_COST_USD,
                                  ASP,
                                  POE_MAX,
                                  STORAGE_MAX,
                                  QOH,
                                  VR_AVAIL_QTY,
                                  DEMAND_MAX,
                                  CONDITION_OF_INV,
                                  PRIORITY,
                                  FGI_QTY,
                                  FGIX_QTY,
                                  DGI_QTY,
                                  LIST_GENERATION_DATE,
                                  BLOCKED_PID_FROM,
                                  REASON_FOR_BLOCKED_PID,
                                  DGI,
                                  FGI,
                                  WIP,
                                  NIB,
                                  TOTAL_QTY,
                                  CONS_QTY,
                                  NETTABLE_DGI_QTY,
                                  NETTABLE_FGI_QTY,
                                  TOTAL_NETTABLE_QTY,
                                  CONS_PERCENTAGE,
                                  CUR_SALES_UNITS,
                                  MOS,
                                  NETTABLE_MOS,
                                  REVENUE_BANDS,
                                  MOS_BANDS,
                                  FCS,
                                  BACKLOG,
                                  INCLUDE_OR_EXCLUDE,
                                  INCLUDE_OR_EXCLUDE_REASON,
                                  --                                                 END_OF_LAST_SUPPORT_DATE,
                                  REPAIR_METHOD,
                                  RF_CREATION_DATE,
                                  TOTAL_RESERVATIONS,
                                  RF_PID,
                                  SERVICE_REPAIR_FLAG,
                                  GPL,
                                  EXPECTED_RECEIPTS,
                                  REFRESH_LIFE_CYCLE,
                                  IN_TRANSIT_POE,
                                  IN_TRANSIT_NIB,
                                  IN_TRANSIT_DGI,
                                  ITEM_TYPE,
                                  ITEM_CATALOG_CATEGORY,
                                  PID_CATEGORY,
                                  BL,
                                 RF_FORECAST, WS_FORECAST, 
                                 RF_ADJUSTED_FORECAST, UNFULFILLED_FORECAST,OLD_DEMAND)
                           VALUES (
                                     lv_dem_max_data_list (idx).CISCO_PRODUCT_NAME,
                                     lv_dem_max_data_list (idx).PRODUCT_DESCRIPTION,
                                     lv_dem_max_data_list (idx).PRODUCT_FAMILY,
                                     lv_dem_max_data_list (idx).PRODUCT_TYPE,
                                     lv_dem_max_data_list (idx).EOS,
                                     lv_dem_max_data_list (idx).BUSINESS_UNIT,
                                     lv_dem_max_data_list (idx).PRODUCT_LIFE_CYCLE,
                                     lv_dem_max_data_list (idx).UNIT_STD_COST_USD,
                                     lv_dem_max_data_list (idx).ASP,
                                     lv_dem_max_data_list (idx).WPM,
                                     lv_dem_max_data_list (idx).STORAGE_MAX,
                                     lv_dem_max_data_list (idx).QOH,
                                     0,
                                     lv_dem_max_data_list (idx).DEMAND_MAX,
                                     lv_dem_max_data_list (idx).CONDITION_OF_INV,
                                     lv_dem_max_data_list (idx).PRIORITY,
                                     lv_dem_max_data_list (idx).FGI_QTY,
                                     lv_dem_max_data_list (idx).FGIX_QTY,
                                     lv_dem_max_data_list (idx).DGI_QTY,
                                     lv_dem_max_data_list (idx).LIST_GENERATION_DATE,
                                     lv_dem_max_data_list (idx).BLOCKED_PID_FROM,
                                     lv_dem_max_data_list (idx).REASON_FOR_BLOCKED_PID,
                                     lv_dem_max_data_list (idx).DGI,
                                     lv_dem_max_data_list (idx).FGI,
                                     lv_dem_max_data_list (idx).WIP,
                                     lv_dem_max_data_list (idx).NIB,
                                     lv_dem_max_data_list (idx).TOTAL_QTY,
                                     lv_dem_max_data_list (idx).CONS_QTY,
                                     lv_dem_max_data_list (idx).NETTABLE_DGI_QTY,
                                     lv_dem_max_data_list (idx).NETTABLE_FGI_QTY,
                                     lv_dem_max_data_list (idx).TOTAL_NETTABLE_QTY,
                                     lv_dem_max_data_list (idx).CONS_PERCENTAGE,
                                     lv_dem_max_data_list (idx).CUR_SALES_UNITS,
                                     lv_dem_max_data_list (idx).MOS,
                                     lv_dem_max_data_list (idx).NETTABLE_MOS,
                                     lv_dem_max_data_list (idx).REVENUE_BANDS,
                                     lv_dem_max_data_list (idx).MOS_BANDS,
                                     lv_dem_max_data_list (idx).FCS,
                                     lv_dem_max_data_list (idx).BACKLOG,
                                     lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE,
                                     lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE_REASON,
                                     --                       lv_dem_max_data_list(idx).END_OF_LAST_SUPPORT_DATE,
                                     lv_dem_max_data_list (idx).REPAIR_METHOD,
                                     lv_dem_max_data_list (idx).RF_CREATION_DATE,
                                     lv_dem_max_data_list (idx).TOTAL_RESERVATIONS,
                                     lv_dem_max_data_list (idx).RF_PID,
                                     lv_dem_max_data_list (idx).SERVICE_REPAIR_FLAG,
                                     lv_dem_max_data_list (idx).GPL,
                                     0,
                                     lv_dem_max_data_list (idx).REFRESH_LIFE_CYCLE,
                                     lv_dem_max_data_list (idx).IN_TRANSIT_POE,
                                     lv_dem_max_data_list (idx).IN_TRANSIT_NIB,
                                     lv_dem_max_data_list (idx).IN_TRANSIT_DGI,
                                     lv_dem_max_data_list (idx).ITEM_TYPE,
                                     lv_dem_max_data_list (idx).ITEM_CATALOG_CATEGORY,
                                     lv_dem_max_data_list (idx).PID_CATEGORY,
                                     lv_dem_max_data_list (idx).BL,
                                     lv_dem_max_data_list (idx).RF_FORECAST, lv_dem_max_data_list (idx).WS_FORECAST, 
                                     lv_dem_max_data_list (idx).RF_ADJUSTED_FORECAST, lv_dem_max_data_list (idx).UNFULFILLED_FORECAST,lv_dem_max_data_list (idx).OLD_DEMAND);
                     END IF;
   
                     IF lv_dem_max_data_list (idx).PRODUCT_SPARE_NAME
                           IS NOT NULL
                     THEN
                        INSERT
                          INTO CRPADM.RC_FIN_DEMAND_LIST (
                                  PRODUCT_NAME,
                                  PRODUCT_DESCRIPTION,
                                  PRODUCT_FAMILY,
                                  PRODUCT_TYPE,
                                  EOS,
                                  BUSINESS_UNIT,
                                  PRODUCT_LIFE_CYCLE,
                                  UNIT_STD_COST_USD,
                                  ASP,
                                  POE_MAX,
                                  STORAGE_MAX,
                                  QOH,
                                  VR_AVAIL_QTY,
                                  DEMAND_MAX,
                                  CONDITION_OF_INV,
                                  PRIORITY,
                                  FGI_QTY,
                                  FGIX_QTY,
                                  DGI_QTY,
                                  LIST_GENERATION_DATE,
                                  BLOCKED_PID_FROM,
                                  REASON_FOR_BLOCKED_PID,
                                  DGI,
                                  FGI,
                                  WIP,
                                  NIB,
                                  TOTAL_QTY,
                                  CONS_QTY,
                                  NETTABLE_DGI_QTY,
                                  NETTABLE_FGI_QTY,
                                  TOTAL_NETTABLE_QTY,
                                  CONS_PERCENTAGE,
                                  CUR_SALES_UNITS,
                                  MOS,
                                  NETTABLE_MOS,
                                  REVENUE_BANDS,
                                  MOS_BANDS,
                                  FCS,
                                  BACKLOG,
                                  INCLUDE_OR_EXCLUDE,
                                  INCLUDE_OR_EXCLUDE_REASON,
                                  --                                                 END_OF_LAST_SUPPORT_DATE,
                                  REPAIR_METHOD,
                                  RF_CREATION_DATE,
                                  TOTAL_RESERVATIONS,
                                  RF_PID,
                                  SERVICE_REPAIR_FLAG,
                                  GPL,
                                  EXPECTED_RECEIPTS,
                                  REFRESH_LIFE_CYCLE,
                                  IN_TRANSIT_POE,
                                  IN_TRANSIT_NIB,
                                  IN_TRANSIT_DGI,
                                  ITEM_TYPE,
                                  ITEM_CATALOG_CATEGORY,
                                  PID_CATEGORY,
                                  BL,
                                  RF_FORECAST, WS_FORECAST, 
                                   RF_ADJUSTED_FORECAST, UNFULFILLED_FORECAST,OLD_DEMAND)
                           VALUES (
                                     lv_dem_max_data_list (idx).PRODUCT_SPARE_NAME,
                                     lv_dem_max_data_list (idx).PRODUCT_DESCRIPTION,
                                     lv_dem_max_data_list (idx).PRODUCT_FAMILY,
                                     lv_dem_max_data_list (idx).PRODUCT_TYPE,
                                     lv_dem_max_data_list (idx).EOS,
                                     lv_dem_max_data_list (idx).BUSINESS_UNIT,
                                     lv_dem_max_data_list (idx).PRODUCT_LIFE_CYCLE,
                                     lv_dem_max_data_list (idx).UNIT_STD_COST_USD,
                                     lv_dem_max_data_list (idx).ASP,
                                     lv_dem_max_data_list (idx).WPM,
                                     lv_dem_max_data_list (idx).STORAGE_MAX,
                                     lv_dem_max_data_list (idx).QOH,
                                     0,
                                     lv_dem_max_data_list (idx).DEMAND_MAX,
                                     lv_dem_max_data_list (idx).CONDITION_OF_INV,
                                     lv_dem_max_data_list (idx).PRIORITY,
                                     lv_dem_max_data_list (idx).FGI_QTY,
                                     lv_dem_max_data_list (idx).FGIX_QTY,
                                     lv_dem_max_data_list (idx).DGI_QTY,
                                     lv_dem_max_data_list (idx).LIST_GENERATION_DATE,
                                     lv_dem_max_data_list (idx).BLOCKED_PID_FROM,
                                     lv_dem_max_data_list (idx).REASON_FOR_BLOCKED_PID,
                                     lv_dem_max_data_list (idx).DGI,
                                     lv_dem_max_data_list (idx).FGI,
                                     lv_dem_max_data_list (idx).WIP,
                                     lv_dem_max_data_list (idx).NIB,
                                     lv_dem_max_data_list (idx).TOTAL_QTY,
                                     lv_dem_max_data_list (idx).CONS_QTY,
                                     lv_dem_max_data_list (idx).NETTABLE_DGI_QTY,
                                     lv_dem_max_data_list (idx).NETTABLE_FGI_QTY,
                                     lv_dem_max_data_list (idx).TOTAL_NETTABLE_QTY,
                                     lv_dem_max_data_list (idx).CONS_PERCENTAGE,
                                     lv_dem_max_data_list (idx).CUR_SALES_UNITS,
                                     lv_dem_max_data_list (idx).MOS,
                                     lv_dem_max_data_list (idx).NETTABLE_MOS,
                                     lv_dem_max_data_list (idx).REVENUE_BANDS,
                                     lv_dem_max_data_list (idx).MOS_BANDS,
                                     lv_dem_max_data_list (idx).FCS,
                                     lv_dem_max_data_list (idx).BACKLOG,
                                     lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE,
                                     lv_dem_max_data_list (idx).INCLUDE_OR_EXCLUDE_REASON,
                                     --                       lv_dem_max_data_list(idx).END_OF_LAST_SUPPORT_DATE,
                                     lv_dem_max_data_list (idx).REPAIR_METHOD,
                                     lv_dem_max_data_list (idx).RF_CREATION_DATE,
                                     lv_dem_max_data_list (idx).TOTAL_RESERVATIONS,
                                     lv_dem_max_data_list (idx).RF_PID,
                                     lv_dem_max_data_list (idx).SERVICE_REPAIR_FLAG,
                                     lv_dem_max_data_list (idx).GPL,
                                     0,
                                     lv_dem_max_data_list (idx).REFRESH_LIFE_CYCLE,
                                     lv_dem_max_data_list (idx).IN_TRANSIT_POE,
                                     lv_dem_max_data_list (idx).IN_TRANSIT_NIB,
                                     lv_dem_max_data_list (idx).IN_TRANSIT_DGI,
                                     lv_dem_max_data_list (idx).ITEM_TYPE,
                                     lv_dem_max_data_list (idx).ITEM_CATALOG_CATEGORY,
                                     lv_dem_max_data_list (idx).PID_CATEGORY,
                                     lv_dem_max_data_list (idx).BL,
                                     lv_dem_max_data_list (idx).RF_FORECAST, lv_dem_max_data_list (idx).WS_FORECAST, 
                                     lv_dem_max_data_list (idx).RF_ADJUSTED_FORECAST, lv_dem_max_data_list (idx).UNFULFILLED_FORECAST,lv_dem_max_data_list (idx).OLD_DEMAND);
                     END IF;
                  END IF;
               END LOOP;
            ELSE
               EXIT;
            END IF;
   
            EXIT WHEN CUR_DEM_MAX%NOTFOUND;
         END LOOP;
   
         CLOSE CUR_DEM_MAX;
   
         DELETE FROM RC_FIN_DEMAND_LIST FL
               WHERE EXISTS
                        (SELECT 1
                           FROM RC_PRODUCT_MASTER
                          WHERE FL.PRODUCT_NAME = REFRESH_PART_NUMBER);
   
         DELETE FROM RC_FIN_DEMAND_LIST FL
               WHERE ITEM_TYPE = 'TURNKEY'; -- ADDED AS PER JERALD REQUIRMENT NOT TO PULL TURNKEY PARTS
   
                            
          
   
         UPDATE RC_FIN_DEMAND_LIST
            SET INCLUDE_OR_EXCLUDE = 'EXCLUDE',
                INCLUDE_OR_EXCLUDE_REASON = 'Demand quantity is zero or less'
          WHERE INCLUDE_OR_EXCLUDE = 'INCLUDE' AND DEMAND_MAX <= 0;
   
         UPDATE RC_FIN_DEMAND_LIST
            SET VR_AVAIL_QTY =
                   (SELECT SUM (DGI + FGI + FGIX)
                      FROM RC_VAL_RECOVERY_DATA
                     WHERE PART_NUMBER = PRODUCT_NAME)
          WHERE INCLUDE_OR_EXCLUDE = 'EXCLUDE';
   
         UPDATE RC_FIN_DEMAND_LIST
            SET EXPECTED_RECEIPTS = 0
          WHERE INCLUDE_OR_EXCLUDE = 'EXCLUDE' OR EXPECTED_RECEIPTS < 0;
   
         UPDATE RC_FIN_DEMAND_LIST
            SET DEMAND_MAX = 0, PRIORITY = 'NA', CONDITION_OF_INV = 'NA'
          WHERE INCLUDE_OR_EXCLUDE = 'EXCLUDE';
   
       /*  UPDATE RC_FIN_DEMAND_LIST RD
            SET (RF_FORECAST, WS_FORECAST, RF_ADJUSTED_FORECAST) =
                   (SELECT NVL(RF_90DAY_FORECAST,0),
                           NVL(WS_90DAY_FORECAST,0),
                           NVL(RF_ADJUSTED_FORECAST,0)
                      FROM RC_SALES_FORECAST RS
                     WHERE (   RD.PRODUCT_NAME = RS.RETAIL_PART_NUMBER
                            OR RD.PRODUCT_NAME = RS.EXCESS_PART_NUMBER
                            OR RD.PRODUCT_NAME = RS.COMMON_PART_NUMBER));*/
                            
               
                            
   
         UPDATE rc_demand_sourcing_list
            SET status = 'Old'
          WHERE status = 'Previous';
   
         UPDATE rc_demand_sourcing_list
            SET status = 'Previous'
          WHERE status = 'Current';
   
         UPDATE rc_demand_sourcing_list
            SET status = 'Current'
          WHERE status = 'NEW';
   
         INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                      'CRPADM.RC_DEMAND_AUTOMATION',
                      'END',
                      SYSDATE);
   
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            crpadm.rc_global_error_logging (
               'OTHERS',
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
               NULL,
               'RC_FIN_DEM_LIST_PROC',
               'PROCEDURE',
               NULL,
               'Y');
      END;
   
      PROCEDURE rc_irt_mail_rpt_proc_1
      IS
         v_msg_from         VARCHAR2 (500);
         v_msg_to           VARCHAR2 (500);
         v_msg_subject      VARCHAR2 (32767);
         v_msg_text         VARCHAR2 (32767);
         v_output11         LONG;
         v_output12         LONG;
         v_output21         LONG;
         v_mail_send_flag   VARCHAR2 (10);
         v_output22         LONG;
         v_output23         LONG;
         lv_database_name   VARCHAR2 (100);
         v_output31         LONG;
         v_output_hdr       LONG;
         v_output32         LONG;
   
         v_output41         LONG;
         v_output42         LONG;
         v_output43         LONG;
   
         v_output51         LONG;
         v_output52         LONG;
         v_output53         LONG;
   
         v_output61         LONG;
         v_output62         LONG;
         v_output63         LONG;
   
         v_msg              VARCHAR2 (20) := NULL;
         v_errmsg           VARCHAR2 (500);
         v_fiscal_year      VARCHAR2 (10);
         v_qtr              VARCHAR2 (5);
         v_week             NUMBER;
         v_qtr_start_date   DATE;
         v_qtr_end_date     DATE;
   
   
         mailhost           VARCHAR2 (100) := 'javamail.cisco.com';
         conn               UTL_SMTP.connection;
         v_message_type     VARCHAR2 (100) := 'text/plain';
         v_crlf             VARCHAR2 (5) := CHR (13) || CHR (10);
         v_count            NUMBER := 0;
      BEGIN
         DELETE FROM rc_final_rpt_t;
   
   
         --------Getting the FISCAL YEAR--------------
         --      SELECT MAX (fiscal_year_name)
         --        INTO v_fiscal_year
         --        FROM vavni_cisco_rscm_admin.vv_adm_calendar_yearly_vw
         --       WHERE SYSDATE > fiscal_year_start_date;
         --
         --      --------Getting the Quarter--------------
         --      SELECT qtr_1_start_date, qtr_1_end_date
         --        INTO v_qtr_start_date, v_qtr_end_date
         --        FROM vavni_cisco_rscm_admin.vv_adm_calendar_yearly_vw
         --       WHERE fiscal_year_name = v_fiscal_year;
         --
         --      IF SYSDATE >= v_qtr_start_date AND SYSDATE <= v_qtr_end_date
         --      THEN
         --         v_qtr := 'Q1';
         --      ELSE
         --         SELECT qtr_2_start_date, qtr_2_end_date
         --           INTO v_qtr_start_date, v_qtr_end_date
         --           FROM vavni_cisco_rscm_admin.vv_adm_calendar_yearly_vw
         --          WHERE fiscal_year_name = v_fiscal_year;
         --
         --         IF SYSDATE >= v_qtr_start_date AND SYSDATE <= v_qtr_end_date
         --         THEN
         --            v_qtr := 'Q2';
         --         ELSE
         --            SELECT qtr_3_start_date, qtr_3_end_date
         --              INTO v_qtr_start_date, v_qtr_end_date
         --              FROM vavni_cisco_rscm_admin.vv_adm_calendar_yearly_vw
         --             WHERE fiscal_year_name = v_fiscal_year;
         --
         --            IF SYSDATE >= v_qtr_start_date AND SYSDATE <= v_qtr_end_date
         --            THEN
         --               v_qtr := 'Q3';
         --            ELSE
         --               SELECT qtr_4_start_date, qtr_4_end_date
         --                 INTO v_qtr_start_date, v_qtr_end_date
         --                 FROM vavni_cisco_rscm_admin.vv_adm_calendar_yearly_vw
         --                WHERE fiscal_year_name = v_fiscal_year;
         --
         --               IF SYSDATE >= v_qtr_start_date AND SYSDATE <= v_qtr_end_date
         --               THEN
         --                  v_qtr := 'Q4';
         --               END IF;
         --            END IF;
         --         END IF;
         --      END IF;
         --
   
         --
         --
         --      --------Getting the Week No of the Quarter--------------
         --      SELECT cal_week_no
         --        INTO v_week
         --        FROM vavni_cisco_rscm_admin.vv_adm_cal_week_vw
         --       WHERE     cal_year = TRIM (REPLACE (v_fiscal_year, 'FY', ''))
         --             AND cal_qtr_no = TRIM (REPLACE (v_qtr, 'Q', ''))
         --             AND cal_week_start_date <= SYSDATE
         --             AND SYSDATE <= cal_end_date;
         --
   
   
         SELECT 'FY' || FISCAL_YEAR_NUMBER,
                'Q' || FISCAL_QUARTER_NUMBER,
                FISCAL_WEEK_IN_QTR_NUMBER
           INTO v_fiscal_year, v_qtr, v_week
           FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
          WHERE calendar_date = TRUNC (SYSDATE);
   
   
         INSERT INTO rc_final_rpt_t (dmnd_priority,
                                     product_number,
                                     qty_demanded,
                                     demand_generation_date,
                                     week_no,
                                     qtr_no,
                                     fiscal_year,
                                     inv_type,
                                     status)
            SELECT t.demand_priority,
                   t.product_name,
                   t.qty_demanded,
                   t.demand_generation_date,
                   v_week,
                   v_qtr,
                   v_fiscal_year,
                   'FGI',
                   'Current'
              FROM (  SELECT priority AS demand_priority,
                             cisco_product_name product_name,
                             SUM (fgi_qty) AS qty_demanded,
                             list_generation_date AS demand_generation_date
                        FROM crpadm.rc_dem_strg_max_tbl
                       WHERE fgi_qty > 0
                    GROUP BY priority, cisco_product_name, list_generation_date
                    UNION
                      SELECT priority AS demand_priority,
                             product_spare_name product_name,
                             SUM (fgi_qty) AS qty_demanded,
                             list_generation_date AS demand_generation_date
                        FROM crpadm.rc_dem_strg_max_tbl
                       WHERE fgi_qty > 0 AND product_spare_name IS NOT NULL
                    GROUP BY priority, product_spare_name, list_generation_date)
                   t;
   
         INSERT INTO rc_final_rpt_t (dmnd_priority,
                                     product_number,
                                     qty_demanded,
                                     demand_generation_date,
                                     week_no,
                                     qtr_no,
                                     fiscal_year,
                                     inv_type,
                                     status)
            SELECT t.demand_priority,
                   t.product_name,
                   t.qty_demanded,
                   t.demand_generation_date,
                   v_week,
                   v_qtr,
                   v_fiscal_year,
                   'FGIX',
                   'Current'
              FROM (  SELECT priority AS demand_priority,
                             cisco_product_name product_name,
                             SUM (fgix_qty) AS qty_demanded,
                             list_generation_date AS demand_generation_date
                        FROM crpadm.rc_dem_strg_max_tbl
                       WHERE fgix_qty > 0
                    GROUP BY priority, cisco_product_name, list_generation_date
                    UNION
                      SELECT priority AS demand_priority,
                             product_spare_name product_name,
                             SUM (fgix_qty) AS qty_demanded,
                             list_generation_date AS demand_generation_date
                        FROM crpadm.rc_dem_strg_max_tbl
                       WHERE fgix_qty > 0 AND product_spare_name IS NOT NULL
                    GROUP BY priority, product_spare_name, list_generation_date)
                   t;
   
         INSERT INTO rc_final_rpt_t (dmnd_priority,
                                     product_number,
                                     qty_demanded,
                                     demand_generation_date,
                                     week_no,
                                     qtr_no,
                                     fiscal_year,
                                     inv_type,
                                     status)
            SELECT t.demand_priority,
                   t.product_name,
                   t.qty_demanded,
                   t.demand_generation_date,
                   v_week,
                   v_qtr,
                   v_fiscal_year,
                   'DGI',
                   'Current'
              FROM (  SELECT priority AS demand_priority,
                             cisco_product_name product_name,
                             SUM (dgi_qty) AS qty_demanded,
                             list_generation_date AS demand_generation_date
                        FROM crpadm.rc_dem_strg_max_tbl
                       WHERE dgi_qty > 0
                    GROUP BY priority, cisco_product_name, list_generation_date
                    UNION
                      SELECT priority AS demand_priority,
                             product_spare_name product_name,
                             SUM (dgi_qty) AS qty_demanded,
                             list_generation_date AS demand_generation_date
                        FROM crpadm.rc_dem_strg_max_tbl
                       WHERE dgi_qty > 0 AND product_spare_name IS NOT NULL
                    GROUP BY priority, product_spare_name, list_generation_date)
                   t;
   
   
         UPDATE rc_final_demand_rpt_tbl
            SET status = 'Old'
          WHERE status = 'Current';
   
         INSERT INTO rc_final_demand_rpt_tbl
            (SELECT * FROM rc_final_rpt_t);
   
         COMMIT;
   
         SELECT property_value
           INTO v_msg_from
           FROM rc_properties
          WHERE property_name = 'REMARKETING_MAILER_ID';
   
         SELECT property_value
           INTO v_mail_send_flag
           FROM rc_properties
          WHERE property_name = 'IRT_STATUS_MAIL_FLAG';
   
         SELECT property_value
           INTO v_msg_to
           FROM rc_properties
          WHERE property_name = 'POE_DEMAND_MAILER_ID';
   
         ----------Sending the mail to poe_demand team with POE Demand Lists as attachments---------------------
   
         SELECT ora_database_name INTO lv_database_name FROM DUAL;
   
         v_msg_subject :=
               v_fiscal_year
            || ' : Refresh Central DA2.0 Demand Lists for  '
            || v_qtr
            || ' Wk'
            || v_week
            || ' Allocation as of '
            || TO_CHAR (SYSDATE, 'Monthdd,YYYY');                   ------SUBJECT
   
         IF (ora_database_name = 'FNTR2DEV.CISCO.COM')
         THEN
            v_msg_subject := 'DEV : ' || v_msg_subject;
         ELSIF (ora_database_name = 'FNTR2STG.CISCO.COM')
         THEN
            v_msg_subject := 'STAGE : ' || v_msg_subject;
         ELSE
            v_msg_subject := v_msg_subject;
         END IF;
   
         v_msg_text :=
               v_crlf
            || 'Hi All,'
            || CHR (10)
            || CHR (10)
            || 'Please find attached the Refresh Central DA2.0 Demand Lists for '
            || TO_CHAR (SYSDATE, 'Month dd, YYYY')
            || ' for '
            || v_fiscal_year
            || ' '
            || v_qtr
            || ' Week '
            || v_week
            || '.'
            || CHR (10)
            || CHR (10)
            || 'If any issues with IRT reports please contact Remarketing-IT team remarketing-it@cisco.com '
            || CHR (10)
            || CHR (10)
            || 'PLEASE DO NOT REPLY .. This is an Auto generated Email.For More Details contact at refresh_inventory_admin@cisco.com'
            || CHR (10)
            || CHR (10)
            || 'Thanks,
   Remarketing Support';
   
         -- Open the SMTP connection ...
         conn := UTL_SMTP.open_connection (mailhost, 25);
         UTL_SMTP.helo (conn, mailhost);
         UTL_SMTP.mail (conn, v_msg_from);
         UTL_SMTP.rcpt (conn, v_msg_to);
   
         -- Open data
         UTL_SMTP.open_data (conn);
   
         -- Message info
         UTL_SMTP.write_data (conn, 'To: ' || v_msg_to || v_crlf);
         UTL_SMTP.write_data (conn, 'From: ' || v_msg_from || v_crlf);
         UTL_SMTP.write_data (conn, 'Subject: ' || v_msg_subject || v_crlf);
         UTL_SMTP.write_data (conn, 'MIME-Version: 1.0' || v_crlf);
         UTL_SMTP.write_data (
            conn,
               'Content-Type: multipart/mixed; boundary="SECBOUND"'
            || v_crlf
            || v_crlf);
   
         -- Message body
         UTL_SMTP.write_data (conn, '--SECBOUND' || v_crlf);
         UTL_SMTP.write_data (
            conn,
            'Content-Type: ' || v_message_type || v_crlf || v_crlf);
         UTL_SMTP.write_data (conn, v_msg_text || v_crlf);
   
         -- Attachment Part
   
         -- Attach info
         /* UTL_SMTP.WRITE_DATA (CONN, '--SECBOUND' || V_CRLF);
          UTL_SMTP.
           WRITE_DATA (
             CONN,
                'Content-Type: '
             || 'text/plain'
             || ' name="'
             || 'EMEA_FGI_FGIX.xls'
             || '"'
             || V_CRLF);
          UTL_SMTP.
           WRITE_DATA (
             CONN,
                'Content-Disposition: attachment; filename="'
             || 'EMEA_FGI_FGIX.xls'
             || '"'
             || V_CRLF
             || V_CRLF);
   
          -- Attach body
          FOR C11
             IN (  SELECT 'ERM_' || DMND_PRIORITY || '_' || 'FGI'
                             AS PRIORITY_INV_TYPE,
                          PRODUCT_NUMBER,
                          QTY_DEMANDED,
                          TO_CHAR (DEMAND_GENERATION_DATE + 14, 'MM/DD/YYYY')
                             AS IRT_DATE,
                          'EMEA' AS THEATER
                     FROM CRPADM.RC_FINAL_RPT_T_TST
                    WHERE STATUS = 'Current' AND INV_TYPE = 'FGI'
                 ORDER BY DMND_PRIORITY, PRODUCT_NUMBER ASC)
          LOOP
             V_OUTPUT11 :=
                   C11.PRIORITY_INV_TYPE
                || CHR (9)
                || C11.PRODUCT_NUMBER
                || CHR (9)
                || C11.QTY_DEMANDED
                || CHR (9)
                || C11.IRT_DATE
                || CHR (9)
                || 'N'
                || CHR (9)
                || C11.THEATER
                || CHR (10);
             UTL_SMTP.WRITE_DATA (CONN, V_OUTPUT11);
          END LOOP;
   
          FOR C12
             IN (  SELECT 'ERM_' || DMND_PRIORITY || '_' || 'FGIX'
                             AS PRIORITY_INV_TYPE,
                          PRODUCT_NUMBER,
                          QTY_DEMANDED,
                          TO_CHAR (DEMAND_GENERATION_DATE + 14, 'MM/DD/YYYY')
                             AS IRT_DATE,
                          'EMEA' AS THEATER
                     FROM CRPADM.RC_FINAL_RPT_T_TST
                    WHERE STATUS = 'Current' AND INV_TYPE = 'FGIX'
                 ORDER BY DMND_PRIORITY, PRODUCT_NUMBER ASC)
          LOOP
             V_OUTPUT12 :=
                   C12.PRIORITY_INV_TYPE
                || CHR (9)
                || C12.PRODUCT_NUMBER
                || CHR (9)
                || C12.QTY_DEMANDED
                || CHR (9)
                || C12.IRT_DATE
                || CHR (9)
                || 'N'
                || CHR (9)
                || C12.THEATER
                || CHR (10);
             UTL_SMTP.WRITE_DATA (CONN, V_OUTPUT12);
          END LOOP;*/
   
   
   
         -- Attach info
         UTL_SMTP.write_data (conn, '--SECBOUND' || v_crlf);
         UTL_SMTP.write_data (
            conn,
               'Content-Type: '
            || 'text/plain'
            || ' name="'
            || 'EMEA_FGI_FGIX_DGI.xls'
            || '"'
            || v_crlf);
         UTL_SMTP.write_data (
            conn,
               'Content-Disposition: attachment; filename="'
            || 'EMEA_FGI_FGIX_DGI.xls'
            || '"'
            || v_crlf
            || v_crlf);
   
         v_output_hdr :=
               'PRIORITY_INV_TYPE'
            || CHR (9)
            || 'PRODUCT_NUMBER'
            || CHR (9)
            || 'QTY_DEMANDED'
            || CHR (9)
            || 'IRT_DATE'
            || CHR (9)
            || 'STATUS'
            || CHR (9)
            || 'THEATER'
            || CHR (10);
   
         -- Attach body
         FOR c21
            IN (  SELECT CASE
                            WHEN dmnd_priority = 'P1A'
                            THEN
                               'ERM_' || dmnd_priority || '_' || 'DGI'
                            WHEN dmnd_priority = 'P1'
                            THEN
                               'ERM_' || dmnd_priority || '_' || 'FGIX'
                            WHEN dmnd_priority = 'P2'
                            THEN
                               'ERM_' || dmnd_priority || '_' || 'FGI'
                         END
                            AS priority_inv_type,
                         product_number,
                         qty_demanded,
                         TO_CHAR (demand_generation_date + 14, 'MM/DD/YYYY')
                            AS irt_date,
                         'EMEA' AS theater
                    FROM crpadm.rc_final_rpt_t
                   WHERE     status = 'Current'
                         AND (   (dmnd_priority = 'P1A' AND inv_type = 'DGI')
                              OR (dmnd_priority = 'P1' AND inv_type = 'FGIX')
                              OR (dmnd_priority = 'P2' AND inv_type = 'FGI'))
                ORDER BY dmnd_priority, product_number ASC)
         LOOP
            IF v_count = 0
            THEN
               v_output21 :=
                     v_output_hdr
                  || c21.priority_inv_type
                  || CHR (9)
                  || c21.product_number
                  || CHR (9)
                  || c21.qty_demanded
                  || CHR (9)
                  || c21.irt_date
                  || CHR (9)
                  || 'N'
                  || CHR (9)
                  || c21.theater
                  || CHR (10);
               v_count := v_count + 1;
            ELSE
               v_output21 :=
                     c21.priority_inv_type
                  || CHR (9)
                  || c21.product_number
                  || CHR (9)
                  || c21.qty_demanded
                  || CHR (9)
                  || c21.irt_date
                  || CHR (9)
                  || 'N'
                  || CHR (9)
                  || c21.theater
                  || CHR (10);
            END IF;
   
            UTL_SMTP.write_data (conn, v_output21);
         END LOOP;
   
         /* FOR C21
             IN (  SELECT 'ERM_' || DMND_PRIORITY || '_' || 'FGI'
                             AS PRIORITY_INV_TYPE,
                          PRODUCT_NUMBER,
                          QTY_DEMANDED,
                          TO_CHAR (DEMAND_GENERATION_DATE + 14, 'MM/DD/YYYY')
                             AS IRT_DATE,
                          'EMEA' AS THEATER
                     FROM CRPADM.RC_FINAL_RPT_T_TST
                    WHERE STATUS = 'Current' AND INV_TYPE = 'FGI'
                 ORDER BY DMND_PRIORITY, PRODUCT_NUMBER ASC)
          LOOP
             V_OUTPUT21 :=
                   C21.PRIORITY_INV_TYPE
                || CHR (9)
                || C21.PRODUCT_NUMBER
                || CHR (9)
                || C21.QTY_DEMANDED
                || CHR (9)
                || C21.IRT_DATE
                || CHR (9)
                || 'N'
                || CHR (9)
                || C21.THEATER
                || CHR (10);
             UTL_SMTP.WRITE_DATA (CONN, V_OUTPUT21);
          END LOOP;
   
          FOR C22
             IN (  SELECT 'ERM_' || DMND_PRIORITY || '_' || 'DGI'
                             AS PRIORITY_INV_TYPE,
                          PRODUCT_NUMBER,
                          QTY_DEMANDED,
                          TO_CHAR (DEMAND_GENERATION_DATE + 14, 'MM/DD/YYYY')
                             AS IRT_DATE,
                          'EMEA' AS THEATER
                     FROM CRPADM.RC_FINAL_RPT_T_TST
                    WHERE STATUS = 'Current' AND INV_TYPE = 'DGI'
                 ORDER BY DMND_PRIORITY, PRODUCT_NUMBER ASC)
          LOOP
             V_OUTPUT22 :=
                   C22.PRIORITY_INV_TYPE
                || CHR (9)
                || C22.PRODUCT_NUMBER
                || CHR (9)
                || C22.QTY_DEMANDED
                || CHR (9)
                || C22.IRT_DATE
                || CHR (9)
                || 'N'
                || CHR (9)
                || C22.THEATER
                || CHR (10);
             UTL_SMTP.WRITE_DATA (CONN, V_OUTPUT22);
          END LOOP;
   
          FOR C23
             IN (  SELECT 'ERM_' || DMND_PRIORITY || '_' || 'FGIX'
                             AS PRIORITY_INV_TYPE,
                          PRODUCT_NUMBER,
                          QTY_DEMANDED,
                          TO_CHAR (DEMAND_GENERATION_DATE + 14, 'MM/DD/YYYY')
                             AS IRT_DATE,
                          'EMEA' AS THEATER
                     FROM CRPADM.RC_FINAL_RPT_T_TST
                    WHERE STATUS = 'Current' AND INV_TYPE = 'FGIX'
                 ORDER BY DMND_PRIORITY, PRODUCT_NUMBER ASC)
          LOOP
             V_OUTPUT23 :=
                   C23.PRIORITY_INV_TYPE
                || CHR (9)
                || C23.PRODUCT_NUMBER
                || CHR (9)
                || C23.QTY_DEMANDED
                || CHR (9)
                || C23.IRT_DATE
                || CHR (9)
                || 'N'
                || CHR (9)
                || C23.THEATER
                || CHR (10);
             UTL_SMTP.WRITE_DATA (CONN, V_OUTPUT23);
          END LOOP;*/
   
   
   
         -- Attach info
         /*UTL_SMTP.WRITE_DATA (CONN, '--SECBOUND' || V_CRLF);
         UTL_SMTP.
          WRITE_DATA (
            CONN,
               'Content-Type: '
            || 'text/plain'
            || ' name="'
            || 'NAM_FGI_FGIX.xls'
            || '"'
            || V_CRLF);
         UTL_SMTP.
          WRITE_DATA (
            CONN,
               'Content-Disposition: attachment; filename="'
            || 'NAM_FGI_FGIX.xls'
            || '"'
            || V_CRLF
            || V_CRLF);
   
         -- Attach body
         FOR C31
            IN (  SELECT 'RM_' || DMND_PRIORITY || '_' || 'FGI'
                            AS PRIORITY_INV_TYPE,
                         PRODUCT_NUMBER,
                         QTY_DEMANDED,
                         TO_CHAR (DEMAND_GENERATION_DATE + 14, 'MM/DD/YYYY')
                            AS IRT_DATE,
                         'AMER' AS THEATER
                    FROM CRPADM.RC_FINAL_RPT_T_TST
                   WHERE STATUS = 'Current' AND INV_TYPE = 'FGI'
                ORDER BY DMND_PRIORITY, PRODUCT_NUMBER ASC)
         LOOP
            V_OUTPUT31 :=
                  C31.PRIORITY_INV_TYPE
               || CHR (9)
               || C31.PRODUCT_NUMBER
               || CHR (9)
               || C31.QTY_DEMANDED
               || CHR (9)
               || C31.IRT_DATE
               || CHR (9)
               || 'N'
               || CHR (9)
               || C31.THEATER
               || CHR (10);
            UTL_SMTP.WRITE_DATA (CONN, V_OUTPUT31);
         END LOOP;
   
         FOR C32
            IN (  SELECT 'RM_' || DMND_PRIORITY || '_' || 'FGIX'
                            AS PRIORITY_INV_TYPE,
                         PRODUCT_NUMBER,
                         QTY_DEMANDED,
                         TO_CHAR (DEMAND_GENERATION_DATE + 14, 'MM/DD/YYYY')
                            AS IRT_DATE,
                         'AMER' AS THEATER
                    FROM CRPADM.RC_FINAL_RPT_T_TST
                   WHERE STATUS = 'Current' AND INV_TYPE = 'FGIX'
                ORDER BY DMND_PRIORITY, PRODUCT_NUMBER ASC)
         LOOP
            V_OUTPUT32 :=
                  C32.PRIORITY_INV_TYPE
               || CHR (9)
               || C32.PRODUCT_NUMBER
               || CHR (9)
               || C32.QTY_DEMANDED
               || CHR (9)
               || C32.IRT_DATE
               || CHR (9)
               || 'N'
               || CHR (9)
               || C32.THEATER
               || CHR (10);
            UTL_SMTP.WRITE_DATA (CONN, V_OUTPUT32);
         END LOOP;*/
   
   
         -- Attach info
         UTL_SMTP.write_data (conn, '--SECBOUND' || v_crlf);
         UTL_SMTP.write_data (
            conn,
               'Content-Type: '
            || 'text/plain'
            || ' name="'
            || 'NAM_FGI_FGIX_DGI.xls'
            || '"'
            || v_crlf);
         UTL_SMTP.write_data (
            conn,
               'Content-Disposition: attachment; filename="'
            || 'NAM_FGI_FGIX_DGI.xls'
            || '"'
            || v_crlf
            || v_crlf);
   
         -- Attach body
         v_count := 0;
   
         FOR c41
            IN (  SELECT CASE
                            WHEN dmnd_priority = 'P1A'
                            THEN
                               'RM-NA_' || dmnd_priority || '_' || 'DGI'
                            WHEN dmnd_priority = 'P1'
                            THEN
                               'RM-NA_' || dmnd_priority || '_' || 'FGIX'
                            WHEN dmnd_priority = 'P2'
                            THEN
                               'RM-NA_' || dmnd_priority || '_' || 'FGI'
                         END
                            AS priority_inv_type,
                         product_number,
                         qty_demanded,
                         TO_CHAR (demand_generation_date + 14, 'MM/DD/YYYY')
                            AS irt_date,
                         'AMER' AS theater
                    FROM crpadm.rc_final_rpt_t
                   WHERE     status = 'Current'
                         AND (   (dmnd_priority = 'P1A' AND inv_type = 'DGI')
                              OR (dmnd_priority = 'P1' AND inv_type = 'FGIX')
                              OR (dmnd_priority = 'P2' AND inv_type = 'FGI'))
                ORDER BY dmnd_priority, product_number ASC)
         LOOP
            IF v_count = 0
            THEN
               v_output41 :=
                     v_output_hdr
                  || c41.priority_inv_type
                  || CHR (9)
                  || c41.product_number
                  || CHR (9)
                  || c41.qty_demanded
                  || CHR (9)
                  || c41.irt_date
                  || CHR (9)
                  || 'N'
                  || CHR (9)
                  || c41.theater
                  || CHR (10);
               v_count := v_count + 1;
            ELSE
               v_output41 :=
                     c41.priority_inv_type
                  || CHR (9)
                  || c41.product_number
                  || CHR (9)
                  || c41.qty_demanded
                  || CHR (9)
                  || c41.irt_date
                  || CHR (9)
                  || 'N'
                  || CHR (9)
                  || c41.theater
                  || CHR (10);
            END IF;
   
            UTL_SMTP.write_data (conn, v_output41);
         END LOOP;
   
         /*FOR C41
            IN (  SELECT 'RM_' || DMND_PRIORITY || '_' || 'FGI'
                            AS PRIORITY_INV_TYPE,
                         PRODUCT_NUMBER,
                         QTY_DEMANDED,
                         TO_CHAR (DEMAND_GENERATION_DATE + 14, 'MM/DD/YYYY')
                            AS IRT_DATE,
                         'AMER' AS THEATER
                    FROM CRPADM.RC_FINAL_RPT_T_TST
                   WHERE STATUS = 'Current' AND INV_TYPE = 'FGI'
                ORDER BY DMND_PRIORITY, PRODUCT_NUMBER ASC)
         LOOP
            V_OUTPUT41 :=
                  C41.PRIORITY_INV_TYPE
               || CHR (9)
               || C41.PRODUCT_NUMBER
               || CHR (9)
               || C41.QTY_DEMANDED
               || CHR (9)
               || C41.IRT_DATE
               || CHR (9)
               || 'N'
               || CHR (9)
               || C41.THEATER
               || CHR (10);
            UTL_SMTP.WRITE_DATA (CONN, V_OUTPUT41);
         END LOOP;
   
         FOR C42
            IN (  SELECT 'RM_' || DMND_PRIORITY || '_' || 'DGI'
                            AS PRIORITY_INV_TYPE,
                         PRODUCT_NUMBER,
                         QTY_DEMANDED,
                         TO_CHAR (DEMAND_GENERATION_DATE + 14, 'MM/DD/YYYY')
                            AS IRT_DATE,
                         'AMER' AS THEATER
                    FROM CRPADM.RC_FINAL_RPT_T_TST
                   WHERE STATUS = 'Current' AND INV_TYPE = 'DGI'
                ORDER BY DMND_PRIORITY, PRODUCT_NUMBER ASC)
         LOOP
            V_OUTPUT42 :=
                  C42.PRIORITY_INV_TYPE
               || CHR (9)
               || C42.PRODUCT_NUMBER
               || CHR (9)
               || C42.QTY_DEMANDED
               || CHR (9)
               || C42.IRT_DATE
               || CHR (9)
               || 'N'
               || CHR (9)
               || C42.THEATER
               || CHR (10);
            UTL_SMTP.WRITE_DATA (CONN, V_OUTPUT42);
         END LOOP;
   
         FOR C43
            IN (  SELECT 'RM_' || DMND_PRIORITY || '_' || 'FGIX'
                            AS PRIORITY_INV_TYPE,
                         PRODUCT_NUMBER,
                         QTY_DEMANDED,
                         TO_CHAR (DEMAND_GENERATION_DATE + 14, 'MM/DD/YYYY')
                            AS IRT_DATE,
                         'AMER' AS THEATER
                    FROM CRPADM.RC_FINAL_RPT_T_TST
                   WHERE STATUS = 'Current' AND INV_TYPE = 'FGIX'
                ORDER BY DMND_PRIORITY, PRODUCT_NUMBER ASC)
         LOOP
            V_OUTPUT43 :=
                  C43.PRIORITY_INV_TYPE
               || CHR (9)
               || C43.PRODUCT_NUMBER
               || CHR (9)
               || C43.QTY_DEMANDED
               || CHR (9)
               || C43.IRT_DATE
               || CHR (9)
               || 'N'
               || CHR (9)
               || C43.THEATER
               || CHR (10);
            UTL_SMTP.WRITE_DATA (CONN, V_OUTPUT43);
         END LOOP;*/
   
         -- Attach info
         /* UTL_SMTP.WRITE_DATA (CONN, '--SECBOUND' || V_CRLF);
          UTL_SMTP.
           WRITE_DATA (
             CONN,
                'Content-Type: '
             || 'text/plain'
             || ' name="'
             || 'APAC_FGI_FGIX.xls'
             || '"'
             || V_CRLF);
          UTL_SMTP.
           WRITE_DATA (
             CONN,
                'Content-Disposition: attachment; filename="'
             || 'APAC_FGI_FGIX.xls'
             || '"'
             || V_CRLF
             || V_CRLF);
   
          -- Attach body
          FOR C51
             IN (  SELECT 'ARM_' || DMND_PRIORITY || '_' || 'FGI'
                             AS PRIORITY_INV_TYPE,
                          PRODUCT_NUMBER,
                          QTY_DEMANDED,
                          TO_CHAR (DEMAND_GENERATION_DATE + 14, 'MM/DD/YYYY')
                             AS IRT_DATE,
                          'APAC' AS THEATER
                     FROM CRPADM.RC_FINAL_RPT_T_TST
                    WHERE STATUS = 'Current' AND INV_TYPE = 'FGI'
                 ORDER BY DMND_PRIORITY, PRODUCT_NUMBER ASC)
          LOOP
             V_OUTPUT51 :=
                   C51.PRIORITY_INV_TYPE
                || CHR (9)
                || C51.PRODUCT_NUMBER
                || CHR (9)
                || C51.QTY_DEMANDED
                || CHR (9)
                || C51.IRT_DATE
                || CHR (9)
                || 'N'
                || CHR (9)
                || C51.THEATER
                || CHR (10);
             UTL_SMTP.WRITE_DATA (CONN, V_OUTPUT51);
          END LOOP;
   
          FOR C52
             IN (  SELECT 'ARM_' || DMND_PRIORITY || '_' || 'FGIX'
                             AS PRIORITY_INV_TYPE,
                          PRODUCT_NUMBER,
                          QTY_DEMANDED,
                          TO_CHAR (DEMAND_GENERATION_DATE + 14, 'MM/DD/YYYY')
                             AS IRT_DATE,
                          'APAC' AS THEATER
                     FROM CRPADM.RC_FINAL_RPT_T_TST
                    WHERE STATUS = 'Current' AND INV_TYPE = 'FGIX'
                 ORDER BY DMND_PRIORITY, PRODUCT_NUMBER ASC)
          LOOP
             V_OUTPUT52 :=
                   C52.PRIORITY_INV_TYPE
                || CHR (9)
                || C52.PRODUCT_NUMBER
                || CHR (9)
                || C52.QTY_DEMANDED
                || CHR (9)
                || C52.IRT_DATE
                || CHR (9)
                || 'N'
                || CHR (9)
                || C52.THEATER
                || CHR (10);
             UTL_SMTP.WRITE_DATA (CONN, V_OUTPUT52);
          END LOOP;*/
   
         -- Attach info
         UTL_SMTP.write_data (conn, '--SECBOUND' || v_crlf);
         UTL_SMTP.write_data (
            conn,
               'Content-Type: '
            || 'text/plain'
            || ' name="'
            || 'APAC_FGI_FGIX_DGI.xls'
            || '"'
            || v_crlf);
         UTL_SMTP.write_data (
            conn,
               'Content-Disposition: attachment; filename="'
            || 'APAC_FGI_FGIX_DGI.xls'
            || '"'
            || v_crlf
            || v_crlf);
         v_count := 0;
   
         -- Attach body
         FOR c61
            IN (  SELECT CASE
                            WHEN dmnd_priority = 'P1A'
                            THEN
                               'ARM_' || dmnd_priority || '_' || 'DGI'
                            WHEN dmnd_priority = 'P1'
                            THEN
                               'ARM_' || dmnd_priority || '_' || 'FGIX'
                            WHEN dmnd_priority = 'P2'
                            THEN
                               'ARM_' || dmnd_priority || '_' || 'FGI'
                         END
                            AS priority_inv_type,
                         product_number,
                         qty_demanded,
                         TO_CHAR (demand_generation_date + 14, 'MM/DD/YYYY')
                            AS irt_date,
                         'APAC' AS theater
                    FROM crpadm.rc_final_rpt_t
                   WHERE     status = 'Current'
                         AND (   (dmnd_priority = 'P1A' AND inv_type = 'DGI')
                              OR (dmnd_priority = 'P1' AND inv_type = 'FGIX')
                              OR (dmnd_priority = 'P2' AND inv_type = 'FGI'))
                ORDER BY dmnd_priority, product_number ASC)
         LOOP
            IF v_count = 0
            THEN
               v_output61 :=
                     v_output_hdr
                  || c61.priority_inv_type
                  || CHR (9)
                  || c61.product_number
                  || CHR (9)
                  || c61.qty_demanded
                  || CHR (9)
                  || c61.irt_date
                  || CHR (9)
                  || 'N'
                  || CHR (9)
                  || c61.theater
                  || CHR (10);
               v_count := v_count + 1;
            ELSE
               v_output61 :=
                     c61.priority_inv_type
                  || CHR (9)
                  || c61.product_number
                  || CHR (9)
                  || c61.qty_demanded
                  || CHR (9)
                  || c61.irt_date
                  || CHR (9)
                  || 'N'
                  || CHR (9)
                  || c61.theater
                  || CHR (10);
            END IF;
   
            UTL_SMTP.write_data (conn, v_output61);
         END LOOP;
   
         /*FOR C61
            IN (  SELECT 'ARM_' || DMND_PRIORITY || '_' || 'FGI'
                            AS PRIORITY_INV_TYPE,
                         PRODUCT_NUMBER,
                         QTY_DEMANDED,
                         TO_CHAR (DEMAND_GENERATION_DATE + 14, 'MM/DD/YYYY')
                            AS IRT_DATE,
                         'APAC' AS THEATER
                    FROM CRPADM.RC_FINAL_RPT_T_TST
                   WHERE STATUS = 'Current' AND INV_TYPE = 'FGI'
                ORDER BY DMND_PRIORITY, PRODUCT_NUMBER ASC)
         LOOP
            V_OUTPUT61 :=
                  C61.PRIORITY_INV_TYPE
               || CHR (9)
               || C61.PRODUCT_NUMBER
               || CHR (9)
               || C61.QTY_DEMANDED
               || CHR (9)
               || C61.IRT_DATE
               || CHR (9)
               || 'N'
               || CHR (9)
               || C61.THEATER
               || CHR (10);
            UTL_SMTP.WRITE_DATA (CONN, V_OUTPUT61);
         END LOOP;
   
         FOR C62
            IN (  SELECT 'ARM_' || DMND_PRIORITY || '_' || 'FGIX'
                            AS PRIORITY_INV_TYPE,
                         PRODUCT_NUMBER,
                         QTY_DEMANDED,
                         TO_CHAR (DEMAND_GENERATION_DATE + 14, 'MM/DD/YYYY')
                            AS IRT_DATE,
                         'APAC' AS THEATER
                    FROM CRPADM.RC_FINAL_RPT_T_TST
                   WHERE STATUS = 'Current' AND INV_TYPE = 'FGIX'
                ORDER BY DMND_PRIORITY, PRODUCT_NUMBER ASC)
         LOOP
            V_OUTPUT62 :=
                  C62.PRIORITY_INV_TYPE
               || CHR (9)
               || C62.PRODUCT_NUMBER
               || CHR (9)
               || C62.QTY_DEMANDED
               || CHR (9)
               || C62.IRT_DATE
               || CHR (9)
               || 'N'
               || CHR (9)
               || C62.THEATER
               || CHR (10);
            UTL_SMTP.WRITE_DATA (CONN, V_OUTPUT62);
         END LOOP;
   
   
         FOR C63
            IN (  SELECT 'ARM_' || DMND_PRIORITY || '_' || 'DGI'
                            AS PRIORITY_INV_TYPE,
                         PRODUCT_NUMBER,
                         QTY_DEMANDED,
                         TO_CHAR (DEMAND_GENERATION_DATE + 14, 'MM/DD/YYYY')
                            AS IRT_DATE,
                         'APAC' AS THEATER
                    FROM CRPADM.RC_FINAL_RPT_T_TST
                   WHERE STATUS = 'Current' AND INV_TYPE = 'DGI'
                ORDER BY DMND_PRIORITY, PRODUCT_NUMBER ASC)
         LOOP
            V_OUTPUT63 :=
                  C63.PRIORITY_INV_TYPE
               || CHR (9)
               || C63.PRODUCT_NUMBER
               || CHR (9)
               || C63.QTY_DEMANDED
               || CHR (9)
               || C63.IRT_DATE
               || CHR (9)
               || 'N'
               || CHR (9)
               || C63.THEATER
               || CHR (10);
            UTL_SMTP.WRITE_DATA (CONN, V_OUTPUT63);
         END LOOP;*/
   
   
         -- Close data
         UTL_SMTP.close_data (conn);
         UTL_SMTP.quit (conn);
   
         v_msg := NULL;
         v_msg := 'SUCCESS';
   
         IF (v_mail_send_flag = 'Y')
         THEN
            rc_msg_mail_proc ('SUCCESS', NULL);
      END IF;
   
   
   
         COMMIT;
         v_errmsg := NULL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_msg := 'ERROR';
            v_errmsg := SQLERRM; ---------Getting the error message in case of failure
   
            crpadm.rc_global_error_logging (
               'OTHERS',
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
            NULL,
            'RC_IRT_MAIL_RPT_PROC',
            'PROCEDURE',
            NULL,
            'Y');

         IF (v_mail_send_flag = 'Y')
         THEN
            rc_msg_mail_proc ('ERROR', v_errmsg);
         END IF;



         COMMIT;
   END rc_irt_mail_rpt_proc_1;
--   
      PROCEDURE rc_irt_mail_rpt_proc
      IS
         v_msg_from         VARCHAR2 (500);
         v_msg_to           VARCHAR2 (500);
         v_msg_subject      VARCHAR2 (32767);
         v_msg_text         VARCHAR2 (32767);
         v_output11         LONG;
         v_output12         LONG;
         v_output21         LONG;
         v_mail_send_flag   VARCHAR2 (10);
         v_output22         LONG;
         v_output23         LONG;
         lv_prod_name       VARCHAR2 (256);
         lv_eos_name        VARCHAR2 (256);
         lv_pad             VARCHAR2 (100);
         l_step             PLS_INTEGER := 12000;
   
         v_output31         BLOB;
         v_output_hdr       LONG;
         v_output32         LONG;
   
         v_output41         LONG;
         v_output42         LONG;
         v_output43         LONG;
   
         v_output51         LONG;
         v_output52         LONG;
         v_output53         LONG;
   
         v_output61         LONG;
         v_output62         LONG;
         v_output63         LONG;
   
         v_msg              VARCHAR2 (20) := NULL;
         v_errmsg           VARCHAR2 (500);
         v_fiscal_year      VARCHAR2 (10);
         v_qtr              VARCHAR2 (5);
         v_week             NUMBER;
         v_qtr_start_date   DATE;
         v_qtr_end_date     DATE;
         lv_database_name   VARCHAR2 (100);
   
         mailhost           VARCHAR2 (100) := 'javamail.cisco.com';
         conn               UTL_SMTP.connection;
         v_message_type     VARCHAR2 (100) := 'text/plain';
         v_crlf             VARCHAR2 (5) := CHR (13) || CHR (10);
         v_count            NUMBER := 0;
         l_stylesheet       VARCHAR2 (3000)
            := '<html><head><style type="text/css">table  { empty-cells     : show;
                                       border-collapse : collapse;
                                 border          : solid 2px #444444;}
                      td       { border          : solid 1px #444444;
                                font-size       : 8pt;
                                 padding         : 1px;}
                      </style>
                    </head><body><table><thead>';
      BEGIN
      
      INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                      'CRPADM.RC_DEMAND_AUTOMATION.RC_IRT_MAIL_RPT_PROC',
                      'START',
                      SYSDATE);
   
      
      
      
      RC_DEMAND_AUTOMATION.rc_fin_dem_list_proc;
   
         SELECT 'FY' || FISCAL_YEAR_NUMBER,
                'Q' || FISCAL_QUARTER_NUMBER,
                FISCAL_WEEK_IN_QTR_NUMBER
           INTO v_fiscal_year, v_qtr, v_week
           FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
          WHERE calendar_date = TRUNC (SYSDATE);
   
   
   
         SELECT property_value
           INTO v_msg_from
           FROM rc_properties
          WHERE property_name = 'REMARKETING_MAILER_ID';
   
         SELECT property_value
           INTO v_mail_send_flag
           FROM rc_properties
          WHERE property_name = 'IRT_STATUS_MAIL_FLAG';
   
         SELECT property_value
           INTO v_msg_to
           FROM rc_properties
          WHERE property_name = 'POE_DEMAND_MAILER_ID';
          
--         v_msg_to:='jyotmoha@cisco.com';
   
         ----------Sending the mail to poe_demand team with POE Demand Lists as attachments---------------------
   
   
         SELECT ora_database_name INTO lv_database_name FROM DUAL;
   
         v_msg_subject :=
               v_fiscal_year
            || ' : Refresh Central DA2.0 Demand Lists for  '
            || v_qtr
            || ' Wk'
            || v_week
            || ' Allocation as of '
            || TO_CHAR (SYSDATE, 'Monthdd,YYYY');                   ------SUBJECT
   
         IF (ora_database_name = 'FNTR2DEV.CISCO.COM')
         THEN
            v_msg_subject := 'DEV : ' || v_msg_subject;
         ELSIF (ora_database_name = 'FNTR2STG.CISCO.COM')
         THEN
            v_msg_subject := 'STAGE : ' || v_msg_subject;
         ELSE
            v_msg_subject := v_msg_subject;
         END IF;
   
         ------SUBJECT
   
   
         v_msg_text :=
               v_crlf
            || 'Hi All,'
            || CHR (10)
            || CHR (10)
            || 'Please find attached the Refresh Central DA2.0 Demand Lists for '
            || TO_CHAR (SYSDATE, 'Month dd, YYYY')
            || ' for '
            || v_fiscal_year
            || ' '
            || v_qtr
            || ' Week '
            || v_week
            || '.'
            || CHR (10)
            || CHR (10)
            || 'If any issues with IRT reports please contact Remarketing-IT team remarketing-it@cisco.com '
            || CHR (10)
            || CHR (10)
            || 'PLEASE DO NOT REPLY .. This is an Auto generated Email.For More Details contact refresh_inventory_admin@cisco.com'
            || CHR (10)
            || CHR (10)
            || 'Thanks,
   Remarketing Support';
   
         -- Open the SMTP connection ...
         conn := UTL_SMTP.open_connection (mailhost, 25);
         UTL_SMTP.helo (conn, mailhost);
         UTL_SMTP.mail (conn, v_msg_from);
         UTL_SMTP.rcpt (conn, v_msg_to);
   
         -- Open data
         UTL_SMTP.open_data (conn);
   
         -- Message info
         UTL_SMTP.write_data (conn, 'To: ' || v_msg_to || v_crlf);
         UTL_SMTP.write_data (conn, 'From: ' || v_msg_from || v_crlf);
         UTL_SMTP.write_data (conn, 'Subject: ' || v_msg_subject || v_crlf);
         UTL_SMTP.write_data (conn, 'MIME-Version: 1.0' || v_crlf);
         UTL_SMTP.write_data (
            conn,
               'Content-Type: multipart/mixed; boundary="SECBOUND"'
            || v_crlf
            || v_crlf);
   
         -- Message body
         UTL_SMTP.write_data (conn, '--SECBOUND' || v_crlf);
         UTL_SMTP.write_data (
            conn,
            'Content-Type: ' || v_message_type || v_crlf || v_crlf);
         UTL_SMTP.write_data (conn, v_msg_text || v_crlf);
   
   
   
         -- Attach info
         UTL_SMTP.write_data (conn, '--SECBOUND' || v_crlf);
         UTL_SMTP.write_data (
            conn,
               'Content-Type: '
            || 'text/plain'
            || ' name="'
            || 'Demand_automation_Report.xls'
            || '"'
            || v_crlf);
         UTL_SMTP.write_data (
            conn,
               'Content-Disposition: attachment; filename="'
            || 'Demand_automation_Report.xls'
            || '"'
            || v_crlf
            || v_crlf);
   
         v_output_hdr :=
               l_stylesheet
            || '<th style="background: #f4a341;">RF PID</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Part Number</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Refresh Product Life Cycle</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">RF Forecast</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">WS Forecast</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">RF Adjusted Forecast</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Unfulfilled Forecast</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">VR Available to Allocate Quantity</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Expected Receipts from VR</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">New Demand</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Old Demand</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Priority</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Condition of the Inventory Needed</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Product Description</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Product Type</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Product Family</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Business Unit</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">BL & BL+</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Item Type</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">PID Category</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Item Category</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">EOS</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Standard Cost</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">GPL</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">ASP</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Blocked PID From</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Reason for Blocked PID</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">DGI</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">FGI</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">WIP</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">NIB</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Total Qty</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Nettable DGI</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Nettable FGI</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Total Nettable Quantity</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Cons Qty</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Cons Percentage</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">In Transit POE</th>'
            || CHR (9)
            ||'<th style="background: #f4a341;">In Transit NIB</th>'
            ||CHR(9)
             
            || '<th style="background: #f4a341;">In Transit DGI</th>'
            || CHR (9)
            
            || '<th style="background: #f4a341;">POE MAX</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">MOS</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">MOS Month</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">'
            || CONCAT (CONCAT ('="', 'Nettable MOS'), '"')
            || '</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Revenue</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Shipped Units 12M</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Backlog</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Total Reservations</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Service Repair Flag</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">RF Creation Date</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Retail Repair Method</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">FCS</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Include or Exclude</th>'
            || CHR (9)
            || '<th style="background: #f4a341;">Include or Exclude Reason</th></thead>'
            || CHR (10);
   
         -- Attach body
         FOR c21 IN (  SELECT *
                         FROM rc_fin_demand_list
                     ORDER BY product_name ASC)
         LOOP
            /* lv_prod_name :=
                (CASE
                    WHEN c21.EOS >= SYSDATE
                    THEN
                       '<td style="color:red;" align="left">'
                    WHEN ADD_MONTHS (C21.EOS, 4) >= SYSDATE
                    THEN
                       '<td style="color:orange;" align="left">'
                    ELSE
                       '<td align="left">'
                 END);*/
            lv_prod_name := '<td align="left">';
            /* lv_eos_name :=
                (CASE
                    WHEN c21.EOS >= SYSDATE
                    THEN
                       '<td style="color:red;">'
                    WHEN ADD_MONTHS (C21.EOS, 4) >= SYSDATE
                    THEN
                       '<td style="color:orange;">'
                    ELSE
                       '<td>'
                 END);*/
            lv_eos_name := '<td>';
   
            /*  BEGIN
               SELECT TRIM(TRANSLATE(c21.product_name, '0123456789',' ')) into lv_prod_name FROM dual;
              EXCEPTION
              WHEN NO_DATA_FOUND
              THEN
              lv_prod_name:=NULL;
              END;
             BEGIN
              Select
         TRANSLATE(
         substr(c21.product_name,instr(c21.product_name,'.')+1),'123456789',
                    RPAD('0', 61, '0')
                ) into lv_pad
         from dual where exists (select c21.product_name from dual where c21.product_name like '%.%') ;
          EXCEPTION
              WHEN NO_DATA_FOUND
              THEN
              lv_pad:=NULL;
              END;*/
            IF v_count = 0
            THEN
               v_output21 :=
                     v_output_hdr
                  || ' <tbody><tr><td align="left">'
                  || c21.RF_PID
                  || '</td>'
                  || CHR (9)
                  || lv_prod_name
                  || CONCAT (CONCAT ('="', c21.product_name), '"')
                  --                (CASE WHEN lv_prod_name IS NULL AND lv_pad is not null THEN
                  --               CONCAT(CONCAT('="',c21.product_name),'"')--CONCAT(CONCAT('=TEXT(',c21.product_name),',"#.'||lv_pad||'")')
                  --               WHEN lv_prod_name is null and lv_pad is null
                  --               THEN
                  --               CONCAT(CONCAT('=TEXT(',c21.product_name),',"0")')
                  --                ELSE c21.product_name END)
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.REFRESH_LIFE_CYCLE
                  || '</td>'
                  || CHR (9)
                  ||'<td>'
                  || c21.RF_FORECAST
                  || '</td>'
                  || CHR (9)
                  ||'<td>'
                  || c21.WS_FORECAST
                  || '</td>'
                  || CHR (9)
                  ||'<td>'
                  || c21.RF_ADJUSTED_FORECAST
                  || '</td>'
                  || CHR (9)
                  ||'<td>'
                  || c21.UNFULFILLED_FORECAST
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.VR_AVAIL_QTY
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.EXPECTED_RECEIPTS
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.demand_max
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.old_demand
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.PRIORITY
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.CONDITION_OF_INV
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.product_description
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.PRODUCT_TYPE
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.product_family
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.business_unit
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.bl
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.item_type
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.pid_category
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.item_catalog_category
                  || '</td>'
                  || CHR (9)
                  || lv_eos_name
                  || c21.eos
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.UNIT_STD_COST_USD
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.GPL
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.ASP
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.BLOCKED_PID_FROM
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.REASON_FOR_BLOCKED_PID
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.DGI
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.FGI
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.WIP
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.NIB
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.TOTAL_QTY
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.NETTABLE_DGI_QTY
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.NETTABLE_FGI_QTY
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.TOTAL_NETTABLE_QTY
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.CONS_QTY
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.CONS_PERCENTAGE
                  || '%'
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.IN_TRANSIT_POE
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.IN_TRANSIT_NIB
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.IN_TRANSIT_DGI
                  || '</td>'
                  || CHR (9)
                  
                  || '<td>'
                  || c21.poe_max
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.mos
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.mos_bands
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.nettable_mos
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.REVENUE_BANDS
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.CUR_SALES_UNITS
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.BACKLOG
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.TOTAL_RESERVATIONS
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.SERVICE_REPAIR_FLAG
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.RF_CREATION_DATE
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.REPAIR_METHOD
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || to_char(c21.FCS,'MM/DD/YYYY')
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.INCLUDE_OR_EXCLUDE
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.INCLUDE_OR_EXCLUDE_REASON
                  || '</td></tr>'
                  || CHR (10);
               v_count := v_count + 1;
            ELSE
               v_output21 :=
                     '<tr><td align="left">'
                  || c21.RF_PID
                  || '</td>'
                  || CHR (9)
                  || lv_prod_name
                  || CONCAT (CONCAT ('="', c21.product_name), '"')
                  --                 (CASE WHEN lv_prod_name IS NULL AND lv_pad is not null THEN
                  --               CONCAT(CONCAT('="',c21.product_name),'"')
                  --               WHEN lv_prod_name is null and lv_pad is null
                  --               THEN
                  --               CONCAT(CONCAT('=TEXT(',c21.product_name),',"0")')
                  --                ELSE c21.product_name END)
                  --                 || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.REFRESH_LIFE_CYCLE
                  || '</td>'
                  || CHR (9)
                  ||'<td>'
                  || c21.RF_FORECAST
                  || '</td>'
                  || CHR (9)
                  ||'<td>'
                  || c21.WS_FORECAST
                  || '</td>'
                  || CHR (9)
                  ||'<td>'
                  || c21.RF_ADJUSTED_FORECAST
                  || '</td>'
                  || CHR (9)
                  ||'<td>'
                  || c21.UNFULFILLED_FORECAST
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.VR_AVAIL_QTY
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.EXPECTED_RECEIPTS
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.demand_max
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.old_demand
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.PRIORITY
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.CONDITION_OF_INV
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.product_description
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.PRODUCT_TYPE
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.product_family
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.business_unit
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.bl
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.item_type
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.pid_category
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.item_catalog_category
                  || '</td>'
                  || CHR (9)
                  || lv_eos_name
                  || c21.eos
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.UNIT_STD_COST_USD
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.GPL
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.ASP
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.BLOCKED_PID_FROM
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.REASON_FOR_BLOCKED_PID
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.DGI
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.FGI
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.WIP
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.NIB
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.TOTAL_QTY
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.NETTABLE_DGI_QTY
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.NETTABLE_FGI_QTY
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.TOTAL_NETTABLE_QTY
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.CONS_QTY
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.CONS_PERCENTAGE
                  || '%'
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.IN_TRANSIT_POE
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.IN_TRANSIT_NIB
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.IN_TRANSIT_DGI
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.poe_max
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.mos
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.mos_bands
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.nettable_mos
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.REVENUE_BANDS
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.CUR_SALES_UNITS
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.BACKLOG
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.TOTAL_RESERVATIONS
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.SERVICE_REPAIR_FLAG
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.RF_CREATION_DATE
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.REPAIR_METHOD
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || to_char(c21.FCS,'MM/DD/YYYY')
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.INCLUDE_OR_EXCLUDE
                  || '</td>'
                  || CHR (9)
                  || '<td>'
                  || c21.INCLUDE_OR_EXCLUDE_REASON
                  || '</td></tr>'
                  || CHR (10);
            END IF;
   
            --       g_output21:=utl_raw.cast_to_raw(v_output21);
            --       UTL_COMPRESS.lz_compress(src => v_output31,dst => g_output21);
            --          FOR i IN 0 .. TRUNC((DBMS_LOB.getlength(g_output21) - 1 )/l_step) LOOP
            --      UTL_SMTP.write_data(conn, DBMS_LOB.substr(g_output21, l_step, i * l_step + 1));
            --    END LOOP;
            UTL_SMTP.write_data (conn, v_output21);
         END LOOP;
   
         UTL_SMTP.write_data (conn, '</tbody></table></body></html>');
         -- Close data
         UTL_SMTP.close_data (conn);
         UTL_SMTP.quit (conn);
   
         v_msg := NULL;
         v_msg := 'SUCCESS';
   
         IF (v_mail_send_flag = 'Y')
         THEN
            rc_msg_mail_proc ('SUCCESS', NULL);
         END IF;
   
   
   
         COMMIT;
         v_errmsg := NULL;
            INSERT INTO CRPADM.RC_PROCESS_LOG
              VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                      'CRPADM.RC_DEMAND_AUTOMATION.RC_IRT_MAIL_RPT_PROC',
                      'END',
                      SYSDATE);
   
         
      EXCEPTION
         WHEN OTHERS
         THEN
            v_msg := 'ERROR';
            v_errmsg := SQLERRM; ---------Getting the error message in case of failure
   
            crpadm.rc_global_error_logging (
               'OTHERS',
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
               NULL,
               'RC_IRT_MAIL_RPT_PROC',
               'PROCEDURE',
               NULL,
               'Y');
   
            IF (v_mail_send_flag = 'Y')
            THEN
               rc_msg_mail_proc ('ERROR', v_errmsg);
            END IF;
   
   
   
            COMMIT;
      END rc_irt_mail_rpt_proc;
   
      PROCEDURE rc_msg_mail_proc (i_msg IN VARCHAR2, i_errmsg VARCHAR2)
      IS
         v_msg_from       VARCHAR2 (500);
         v_msg_to         VARCHAR2 (500);
         v_msg_subject    VARCHAR2 (32767);
         v_msg_text       VARCHAR2 (32767);
         v_errmsg         VARCHAR2 (500);
   
         mailhost         VARCHAR2 (100) := 'javamail.cisco.com';
         conn             UTL_SMTP.connection;
         v_message_type   VARCHAR2 (100) := 'text/plain';
         v_crlf           VARCHAR2 (5) := CHR (13) || CHR (10);
      BEGIN
         SELECT property_value
           INTO v_msg_from
           FROM rc_properties
          WHERE property_name = 'REMARKETING_MAILER_ID';
   
   
         SELECT property_value
           INTO v_msg_to
           FROM rc_properties
          WHERE property_name = 'POE_DEMAND_MAILER_ID';
   
--  v_msg_to:='jyotmoha@cisco.com';
  
         v_msg_subject := 'Status of Refresh Central Demand Generation';
         v_msg_text := NULL;
   
         IF i_msg = 'SUCCESS'
         THEN
            v_msg_text :=
                  'Hi All,'
               || CHR (10)
               || CHR (10)
               || 'Final WWRL Demand list has been generated successfully and CCRE Product demand list for WWRL VR IRT has been sent on '
               || TO_CHAR (SYSDATE, 'dd Mon yy hh24:mi:ss')
               || '.'
               || CHR (10)
               || CHR (10)
               || 'PLEASE DO NOT REPLY .. This is an Auto generated Email. For More Details reach out remarketing-it@cisco.com '
               || CHR (10)
               || CHR (10)
               || 'Thanks,'
               || CHR (10)
               || 'Remarketing Support';
         ELSIF i_msg = 'ERROR'
         THEN
            v_msg_text :=
                  'Hi Remarketing Team,'
               || CHR (10)
               || CHR (10)
               || 'There was problem with Final WWRL Demand list generation in the following module on '
               || TO_CHAR (SYSDATE, 'dd Mon yy hh24:mi:ss')
               || '.'
               || CHR (10)
               || CHR (10)
               || 'Error Details: '
               || i_errmsg
               || '.'
               || CHR (10)
               || CHR (10)
               || 'Please resolve the issue ASAP.'
               || CHR (10)
               || CHR (10)
               || 'PLEASE DO NOT REPLY .. This is an Auto generated Email. For More Details reach out remarketing-it@cisco.com '
               || CHR (10)
               || CHR (10)
               || 'Thanks,'
               || CHR (10)
               || 'Remarketing Support';
         END IF;
   
         -- Open the SMTP connection ...
         conn := UTL_SMTP.open_connection (mailhost, 25);
         UTL_SMTP.helo (conn, mailhost);
         UTL_SMTP.mail (conn, v_msg_from);
         UTL_SMTP.rcpt (conn,v_msg_to);
   
         -- Open data
         UTL_SMTP.open_data (conn);
   
         -- Message info
         UTL_SMTP.write_data (conn, 'To: ' ||
          v_msg_to 
          || v_crlf);
         UTL_SMTP.write_data (conn, 'From: ' || v_msg_from || v_crlf);
         UTL_SMTP.write_data (conn, 'Subject: ' || v_msg_subject || v_crlf);
         UTL_SMTP.write_data (conn, 'MIME-Version: 1.0' || v_crlf);
         UTL_SMTP.write_data (
            conn,
               'Content-Type: multipart/mixed; boundary="SECBOUND"'
            || v_crlf
            || v_crlf);
   
         -- Message body
         UTL_SMTP.write_data (conn, '--SECBOUND' || v_crlf);
         UTL_SMTP.write_data (
            conn,
            'Content-Type: ' || v_message_type || v_crlf || v_crlf);
         UTL_SMTP.write_data (conn, v_msg_text || v_crlf);
         -- Close data
         UTL_SMTP.close_data (conn);
         UTL_SMTP.quit (conn);
   
   
   
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg := SQLERRM;
   
            INSERT INTO rc_error_log
                 VALUES (error_id_seq.NEXTVAL,
                         NULL,
                         v_errmsg,
                         NULL,
                         'RC_MSG_MAIL_PROC',
                         'PROCEDURE',
                         SYSDATE,
                         NULL);
   
            COMMIT;
      END rc_msg_mail_proc;
   
      PROCEDURE rc_exclude_pid_update (i_exclude_list IN rc_exclde_pid_list)
      IS
         lv_exclude_list   rc_exclde_pid_list;
      BEGIN
         lv_exclude_list := rc_exclde_pid_list ();
   
         lv_exclude_list := i_exclude_list;
   
         DELETE FROM rc_exclude_pid_list;
   
         FOR idx IN 1 .. lv_exclude_list.COUNT ()
         LOOP
            EXIT WHEN idx IS NULL;
   
            INSERT INTO rc_exclude_pid_list
                 VALUES (lv_exclude_list (idx).product_id,
                         lv_exclude_list (idx).eos_date,
                         lv_exclude_list (idx).eom_date,
                         lv_exclude_list (idx).exclusion_reason);
         END LOOP;
   
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg := SQLERRM;
   
            INSERT INTO rc_error_log
                 VALUES (error_id_seq.NEXTVAL,
                         NULL,
                         v_errmsg,
                         NULL,
                         'RC_EXCLUDE_PID_UPDATE',
                         'PROCEDURE',
                         SYSDATE,
                         NULL);
      END;
   
      PROCEDURE rc_include_pid_update (i_include_list IN rc_inclde_pid_list)
      IS
         lv_include_list   rc_inclde_pid_list;
         lv_count          NUMBER;
      BEGIN
         lv_include_list := rc_inclde_pid_list ();
   
         lv_include_list := i_include_list;
   
         DELETE FROM rc_include_pid_list;
   
         FOR idx IN 1 .. lv_include_list.COUNT ()
         LOOP
            EXIT WHEN idx IS NULL;
   
            SELECT COUNT (*)
              INTO lv_count
              FROM rc_include_pid_list
             WHERE product_id = lv_include_list (idx).product_id;
   
            IF lv_count = 0
            THEN
               INSERT INTO rc_include_pid_list (product_id,
                                                demand_quantity,
                                                effective_to_date,
                                                inv_flag)
                    VALUES (lv_include_list (idx).product_id,
                            lv_include_list (idx).quantity,
                            lv_include_list (idx).effective_to_date,
                            lv_include_list (idx).inventory_type);
            END IF;
   
            COMMIT;
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg := SQLERRM;
   
            INSERT INTO rc_error_log
                 VALUES (error_id_seq.NEXTVAL,
                         NULL,
                         v_errmsg,
                         NULL,
                         'RC_INCLUDE_PID_UPDATE',
                         'PROCEDURE',
                         SYSDATE,
                         NULL);
      END;
   
      FUNCTION get_spare_name (i_cisco_name VARCHAR2, i_type VARCHAR2)
         RETURN VARCHAR2
      IS
         lv_cisco_name   VARCHAR2 (256);
         lv_spare_name   VARCHAR2 (256);
         lv_type         VARCHAR2 (256);
      BEGIN
         lv_cisco_name := i_cisco_name;
         lv_type := i_type;
   
         CASE
            WHEN lv_cisco_name LIKE '%='
            THEN
               lv_spare_name := REPLACE (lv_cisco_name, '=');
            ELSE
               lv_spare_name := CONCAT (lv_cisco_name, '=');
         END CASE;
   
         BEGIN
            IF (lv_type = 'Alternate')
            THEN
               BEGIN
                  SELECT DISTINCT product_id
                    INTO lv_spare_name
                    FROM rmktgadm.rmk_cisco_product_master
                   WHERE product_id = lv_spare_name;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     SELECT DISTINCT part_number
                       INTO lv_spare_name
                       FROM CRPADM.RC_INV_BTS_C3_MV
                      WHERE part_number = lv_spare_name;
               END;
            ELSE
               lv_spare_name := lv_cisco_name;
            END IF;
   
   
            RETURN lv_spare_name;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               RETURN NULL;
         END;
      END;
   
      FUNCTION get_asp (i_remarketing_name VARCHAR2, i_cisco_name VARCHAR2)
         RETURN NUMBER
      IS
         lv_remarketing_name   VARCHAR2 (256);
         lv_cisco_name         VARCHAR2 (256);
         lv_asp                NUMBER;
         lv_item_id            NUMBER;
      BEGIN
         lv_remarketing_name := i_remarketing_name;
         lv_cisco_name := i_cisco_name;
   
         SELECT asp
           INTO lv_asp
           FROM (  SELECT DISTINCT ytd_avg_sales_price asp, month_end_ship_date
                     FROM crpsc.rc_monthly_shipment_revenue shp
                          JOIN rc_product_master b
                             ON shp.refresh_inventory_item_id =
                                   b.refresh_inventory_item_id
                    WHERE refresh_part_number = lv_remarketing_name
                 ORDER BY month_end_ship_date DESC)
          WHERE ROWNUM < 2;
   
         RETURN lv_asp;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            RETURN 0;
      END;
   
      FUNCTION get_life_cycle (i_common_name VARCHAR2)
         RETURN VARCHAR2
      IS
         lv_common_name   VARCHAR2 (250);
         lv_life_cycle    VARCHAR2 (25);
      BEGIN
         lv_common_name := i_common_name;
   
         --
         --      SELECT (CASE
         --                 WHEN     SYSDATE > eo_sales_date
         --                      AND SYSDATE < eo_last_support_date
         --                 THEN
         --                    'EOL'
         --                 WHEN SYSDATE < eo_sales_date
         --                 THEN
         --                    'CUR'
         --                 WHEN SYSDATE > eo_last_support_date
         --                 THEN
         --                    'EOM'
         --                 ELSE
         --                    'CUR'
         --              END)
         --        INTO lv_life_cycle
         --        FROM rmktgadm.rmk_cisco_product_master
         --       WHERE product_id = lv_common_name;
         --
         --      RETURN lv_life_cycle;
         --   EXCEPTION
         --      WHEN NO_DATA_FOUND
         --      THEN
         --         BEGIN
         SELECT DISTINCT
                (CASE
                    WHEN     SYSDATE > eo_sales_date
                         AND SYSDATE < eo_last_support_date
                    THEN
                       'EOL'
                    WHEN SYSDATE < eo_sales_date
                    THEN
                       'CUR'
                    WHEN SYSDATE > eo_last_support_date
                    THEN
                       'EOM'
                    ELSE
                       'CUR'
                 END)
           INTO lv_life_cycle
           FROM xxesc_rscm_eol_pid_v@RC_ESCPRD
          WHERE pid = lv_common_name AND active_flag = 'Y';
   
         RETURN lv_life_cycle;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            RETURN NULL;
         WHEN OTHERS
         THEN
            RETURN NULL;
      END;
   
      FUNCTION get_common_name (i_stripped_name VARCHAR2)
         RETURN VARCHAR2
      IS
         lv_product_name   VARCHAR2 (250);
         lv_common_name    VARCHAR2 (250);
      BEGIN
         lv_product_name := i_stripped_name;
   
         IF (lv_product_name LIKE '%RF' OR lv_product_name LIKE '%WS')
         THEN
            lv_common_name := get_orig_mfg_part (lv_product_name);
         END IF;
   
         IF (lv_product_name NOT LIKE '%RF' AND lv_product_name NOT LIKE '%WS')
         THEN
            BEGIN
               IF (lv_product_name LIKE '%=')
               THEN
                  SELECT DISTINCT product_id
                    INTO lv_common_name
                    FROM rmktgadm.rmk_cisco_product_master
                   WHERE product_id =
                            TRIM (
                               SUBSTR (TRIM (lv_product_name),
                                       1,
                                       (LENGTH (TRIM (lv_product_name))) - 1));
               ELSE
                  SELECT DISTINCT product_id
                    INTO lv_common_name
                    FROM rmktgadm.rmk_cisco_product_master
                   WHERE product_id = lv_product_name;
               END IF;
   
               RETURN lv_common_name;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  BEGIN
                     SELECT DISTINCT product_id
                       INTO lv_common_name
                       FROM rmktgadm.rmk_cisco_product_master
                      WHERE product_id = lv_product_name;
   
                     RETURN lv_common_name;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        RETURN lv_product_name;
                  END;
            END;
   
            RETURN lv_common_name;
         END IF;
   
   
         RETURN lv_common_name;
      END;
   
   
      FUNCTION get_mos (i_cisco_name    VARCHAR2,
                        i_spare_name    VARCHAR2,
                        i_qoh           NUMBER)
         RETURN NUMBER
      IS
         lv_cisco_name   VARCHAR2 (256);
         lv_spare_name   VARCHAR2 (256);
         lv_cur_sales    NUMBER;
         lv_qoh          NUMBER;
         lv_mos          NUMBER;
         lv_mos_flag     VARCHAR2 (1);
      BEGIN
         lv_cisco_name := i_cisco_name;
         lv_spare_name := i_spare_name;
         lv_qoh := i_qoh;
         lv_mos := 0;
   
         SELECT GREATEST (SUM (NVL (shp.total_qty, 0)), SUM (M3_QTY))
           INTO lv_cur_sales
           FROM (SELECT REFRESH_INVENTORY_ITEM_ID,
                        total_qty,
                          NVL (MONTH_10_QTY, 0)
                        + NVL (MONTH_11_QTY, 0)
                        + NVL (MONTH_12_QTY, 0)
                           AS M3_QTY
                   FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS) shp
                LEFT OUTER JOIN
                (SELECT REFRESH_INVENTORY_ITEM_ID,
                        COMMON_PART_NUMBER,
                        XREF_PART_NUMBER
                   FROM RC_PRODUCT_MASTER p) b
                   ON shp.REFRESH_INVENTORY_ITEM_ID =
                         b.REFRESH_INVENTORY_ITEM_ID
          WHERE    b.COMMON_PART_NUMBER = lv_cisco_name
                OR b.XREF_PART_NUMBER = lv_spare_name;
   
         IF lv_cur_sales > 0
         THEN
            lv_cur_sales := lv_cur_sales / 12;
            lv_mos := FLOOR (lv_qoh / lv_cur_sales);
         ELSE
            lv_mos := 0;
         END IF;
   
   
   
         RETURN lv_mos;
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN lv_mos;
      END;
   
      FUNCTION get_mos_bands (i_MFG_EOS_DATE       DATE,
                              i_CUR_Sales_Units    NUMBER,
                              i_MOS                NUMBER)
         RETURN VARCHAR2
      IS
         lv_MOS_BANDS         VARCHAR2 (256);
         LV_MFG_EOS_DATE      DATE;
         lv_product_name      VARCHAR2 (256);
         lv_CUR_Sales_Units   NUMBER;
         lv_MOS               NUMBER;
      BEGIN
         -- lv_product_name := i_product_name;
         LV_MFG_EOS_DATE := i_MFG_EOS_DATE;
         lv_CUR_Sales_Units := i_CUR_Sales_Units;
         lv_MOS := i_MOS;
   
         -- lv_mos := 0;
         --  lv_MOS_BANDS := '1';
   
         --      SELECT DISTINCT EOS, cur_sales_units, MOS
         --        INTO LV_MFG_EOS_DATE, lv_CUR_Sales_Units, lv_MOS
         --        FROM RC_DEMAND_SOURCING_LIST
         --       WHERE PRODUCT_NAME = i_product_name;
   
   
         IF TRUNC (NVL (LV_MFG_EOS_DATE, SYSDATE + 1)) <= TRUNC (SYSDATE)
         THEN
            lv_MOS_BANDS := 'LDOS';
         ELSE
            IF (lv_CUR_Sales_Units > 0)
            THEN
               IF (lv_MOS <= 3)
               THEN
                  lv_MOS_BANDS := '0-3 MOS';
               ELSIF (lv_MOS >= 4 AND lv_MOS <= 12)
               THEN
                  lv_MOS_BANDS := '4-12 MOS';
               ELSIF (lv_MOS >= 13 AND lv_MOS <= 24)
               THEN
                  lv_MOS_BANDS := '1-2 Years';
               ELSIF (lv_MOS >= 25 AND lv_MOS <= 60)
               THEN
                  lv_MOS_BANDS := '3-5 Years';
               ELSIF (lv_MOS >= 61 AND lv_MOS <= 120)
               THEN
                  lv_MOS_BANDS := '5-10 Years';
               ELSIF (lv_MOS > 120)
               THEN
                  lv_MOS_BANDS := '10+ Years';
               ELSE
                  lv_MOS_BANDS := 'No Sales';
               END IF;
            ELSE
               lv_MOS_BANDS := 'No Sales with sku';
            END IF;
         END IF;
   
   
   
         RETURN lv_MOS_BANDS;
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN lv_MOS_BANDS;
      END;
   
      FUNCTION get_qoh (i_rmktng_name    VARCHAR2,
                        i_common_name    VARCHAR2,
                        i_spare_name     VARCHAR2,
                        i_source         VARCHAR2)
         RETURN NUMBER
      IS
         lv_rmktng_name      VARCHAR2 (100);
         lv_common_name      VARCHAR2 (100);
         lv_spare_name       VARCHAR2 (100);
         lv_ws_rmktng_name   VARCHAR2 (100);
         lv_source           VARCHAR2 (100);
         lv_gtm              VARCHAR2 (100);
         lv_qoh              NUMBER := 0;
      BEGIN
         lv_source := i_source;
         lv_common_name := i_common_name;
         lv_rmktng_name := i_rmktng_name;
         lv_ws_rmktng_name := ' ';
         lv_spare_name := i_spare_name;
   
         BEGIN
            SELECT gtm
              INTO lv_gtm
              FROM rc_blacklist_pids
             WHERE     delete_flag = 'N'
                   AND UPPER (action) LIKE '%DA%'
                   AND mfg_part_number = lv_common_name
                   AND mfg_part_number IN (SELECT common_part_number
                                             FROM RC_PRODUCT_MASTER
                                            WHERE refresh_life_cycle_id = 0);
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_gtm := ' ';
         END;
   
         IF lv_rmktng_name LIKE '%RF' AND lv_gtm NOT IN ('WS Only', 'Both')
         THEN
            lv_ws_rmktng_name := REPLACE (lv_rmktng_name, '-RF', '-WS');
         END IF;
   
         IF lv_source = 'WWRL'
         THEN
            lv_qoh := 0;
         ELSE
            SELECT SUM (NVL (qty_on_hand, 0)) + SUM (NVL (qty_in_transit, 0))
              INTO lv_qoh
              FROM CRPADM.RC_INV_BTS_C3_MV
             WHERE part_number IN (lv_common_name,
                                   lv_rmktng_name,
                                   lv_spare_name,
                                   lv_ws_rmktng_name);
         END IF;
   
         IF lv_source = 'BACKLOG'
         THEN
            SELECT SUM (NVL (qty_reserved, 0))
              INTO lv_qoh
              FROM CRPADM.RC_INV_BTS_C3_MV
             WHERE part_number IN (lv_common_name,
                                   lv_rmktng_name,
                                   lv_spare_name,
                                   lv_ws_rmktng_name);
         END IF;
   
         RETURN lv_qoh;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            RETURN lv_qoh;
         WHEN OTHERS
         THEN
            RETURN lv_qoh;
      END;
   
      FUNCTION get_total_reservations (i_remarketing_name    VARCHAR2,
                                       i_excess_name         VARCHAR2)
         RETURN NUMBER
      IS
         lv_product_name       VARCHAR2 (1000);
         lv_remarketing_name   VARCHAR2 (1000);
         lv_excess_name        VARCHAR2 (1000);
         lv_total              NUMBER;
      BEGIN
         --lv_source := i_source;
         --lv_product_name := i_product_name;
         lv_remarketing_name := i_remarketing_name;
         lv_excess_name := i_excess_name;
   
         --  lv_remarketing_name := ' ';
         -- lv_excess_name := ' ';
         -- lv_total :=0;
   
   
         --      SELECT DISTINCT
         --             REMARKETING_NAME,
         --             rc_utility.get_refresh_name (lv_product_name, 'EXCESS')
         --        INTO lv_remarketing_name, lv_excess_name
         --        FROM rc_demand_sourcing_list
         --       WHERE product_name = lv_product_name AND REMARKETING_NAME IS NOT NULL;
   
   
   
         SELECT SUM (ABS (NVL (total_reservations, 0)))
           INTO lv_total
           FROM rmktgadm.rmk_ssot_inventory
          WHERE part_number IN (lv_remarketing_name, lv_excess_name);
   
   
         RETURN lv_total;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_total := 101;
            RETURN lv_total;
         WHEN OTHERS
         THEN
            lv_total := 100;
            g_error_msg :=
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
   
   
            DBMS_OUTPUT.put_line (g_error_msg);
   
            RETURN lv_total;
      END;
   
      FUNCTION get_product_type (PRODUCT_SPARE_NAME    VARCHAR2,
                                 PRODUCT_NAME          VARCHAR2,
                                 CISCO_PRODUCT_NAME    VARCHAR2)
         RETURN VARCHAR2
      IS
         lv_out   VARCHAR2 (256 BYTE);
      BEGIN
         SELECT PRODUCT_TYPE
           INTO lv_out
           FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
          WHERE product_id = CISCO_PRODUCT_NAME;
   
         RETURN lv_out;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT PRODUCT_TYPE
                 INTO lv_out
                 FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                WHERE product_id = PRODUCT_SPARE_NAME;
   
               RETURN lv_out;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  BEGIN
                     SELECT PRODUCT_TYPE
                       INTO lv_out
                       FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                      WHERE product_id = PRODUCT_NAME;
   
                     RETURN lv_out;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        BEGIN
                        SELECT DISTINCT MC_PF.SEGMENT2
                          INTO lv_out
                          FROM CG1_MTL_SYSTEM_ITEMS_B@RC_ODSPROD MSI,
                               CG1_MTL_ITEM_CATEGORIES@RC_ODSPROD MIC_PF,
                               CG1_MTL_CATEGORIES_B@RC_ODSPROD MC_PF
                         WHERE     MSI.SEGMENT1 =
                                      NVL (
                                         CISCO_PRODUCT_NAME,
                                         NVL (PRODUCT_SPARE_NAME,
                                              PRODUCT_NAME))
                               AND MSI.INVENTORY_ITEM_ID =
                                      MIC_PF.INVENTORY_ITEM_ID
                               AND MIC_PF.CATEGORY_ID = MC_PF.CATEGORY_ID
                               AND MIC_PF.CATEGORY_SET_ID = 1100000245
                               AND MSI.ORGANIZATION_ID = 1;
--   
                           RETURN lv_out;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              RETURN NULL;
                        END;
                  END;
            END;
      END;
   
      FUNCTION get_product_description (PRODUCT_SPARE_NAME    VARCHAR2,
                                        PRODUCT_NAME          VARCHAR2,
                                        CISCO_PRODUCT_NAME    VARCHAR2)
         RETURN VARCHAR2
      IS
         lv_out   VARCHAR2 (256 BYTE);
      BEGIN
      SELECT DISTINCT MSI.DESCRIPTION
        INTO lv_out
        FROM CG1_MTL_SYSTEM_ITEMS_B@RC_ODSPROD MSI
       WHERE     MSI.SEGMENT1 =
                    NVL (CISCO_PRODUCT_NAME,
                         NVL (PRODUCT_SPARE_NAME, PRODUCT_NAME))
             AND MSI.ORGANIZATION_ID = 1;
--   
         RETURN lv_out;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT PRODUCT_DESCRIPTION
                 INTO lv_out
                 FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                WHERE product_id = CISCO_PRODUCT_NAME;
   
               RETURN lv_out;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  BEGIN
                     SELECT PRODUCT_DESCRIPTION
                       INTO lv_out
                       FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                      WHERE product_id = PRODUCT_SPARE_NAME;
   
                     RETURN lv_out;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        BEGIN
                           SELECT PRODUCT_DESCRIPTION
                             INTO lv_out
                             FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                            WHERE product_id = PRODUCT_NAME;
   
                           RETURN lv_out;
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              RETURN NULL;
                        END;
                  END;
            END;
      END;
   
      --Function for getting inventory data for the products--
      FUNCTION GET_INV_DATA (i_inv_type       VARCHAR2,
                             i_rmktng_name    VARCHAR2,
                             i_common_name    VARCHAR2,
                             i_spare_name     VARCHAR2,
                             i_source         VARCHAR2)
         RETURN NUMBER
      IS
         lv_rmktng_name      VARCHAR2 (100);
         lv_common_name      VARCHAR2 (100);
         lv_spare_name       VARCHAR2 (100);
         lv_ws_rmktng_name   VARCHAR2 (100);
         lv_source           VARCHAR2 (100);
         lv_gtm              VARCHAR2 (100);
         lv_qoh              NUMBER := 0;
         lv_inv_type         VARCHAR2 (20);
      BEGIN
         lv_inv_type := i_inv_type;
         lv_source := i_source;
         lv_common_name := i_common_name;
         lv_rmktng_name := i_rmktng_name;
         lv_ws_rmktng_name := '';               --changed for PRB0061800 
         lv_spare_name := i_spare_name;
   
         BEGIN
            SELECT gtm
              INTO lv_gtm
              FROM rc_blacklist_pids
             WHERE     delete_flag = 'N'
                   AND UPPER (action) LIKE '%DA%'
                   AND mfg_part_number = lv_common_name
                   AND mfg_part_number IN (SELECT common_part_number
                                             FROM RC_PRODUCT_MASTER
                                            WHERE refresh_life_cycle_id = 0);
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_gtm := ' ';
         END;
   
         IF lv_rmktng_name LIKE '%RF' AND lv_gtm NOT IN ('WS Only', 'Both')
         THEN
            lv_ws_rmktng_name := REPLACE (lv_rmktng_name, '-RF', '-WS');
         END IF;
   
   
         IF lv_inv_type = 'TOTAL'
         THEN
            IF lv_source = 'WWRL' OR lv_source = 'CISCO'
            THEN
               --            SELECT SUM (NVL (qty_available, 0))
               --              INTO lv_qoh
               --              FROM rc_wwrl_inv_data_tbl
               --             WHERE part_no IN (lv_common_name,
               --                               lv_rmktng_name,
               --                               lv_spare_name,
               --                               lv_ws_rmktng_name);
               lv_qoh := 0;
            ELSE
               SELECT ROUND (SUM (QTY))
                 INTO lv_QOH
                 FROM (  SELECT CASE
                                   WHEN    LOCATION LIKE '%FG%'
                                        OR (    lv_rmktng_name IS NULL
                                            AND lv_ws_rmktng_name IS NULL)
                                   THEN
                                      SUM (QTY_ON_HAND) + SUM (QTY_IN_TRANSIT)
                                   ELSE
                                        (SUM (QTY_ON_HAND) + SUM (QTY_IN_TRANSIT))
                                      * NVL (
                                             RC_UTILITY.GET_REFURB_YIELD (
                                                RC_UTILITY.GET_INVENTORY_ITEM_ID (
                                                   NVL (lv_rmktng_name,
                                                        lv_ws_rmktng_name)),
                                                SUBSTR (SITE, 1, 3),
                                                LOCATION)
                                           / 100,
                                           0)
                                END
                                   QTY
                           FROM CRPADM.RC_INV_BTS_C3_MV ML1
                          WHERE ML1.PART_NUMBER IN (lv_common_name,
                                                    lv_rmktng_name,
                                                    lv_spare_name,
                                                    lv_ws_rmktng_name)
                       GROUP BY SITE, LOCATION);
            END IF;
         ELSE
            IF lv_source = 'WWRL' OR lv_source = 'CISCO'
            THEN
               lv_qoh := 0;
            --            SELECT SUM (NVL (qty_available, 0))
            --              INTO lv_qoh
            --              FROM rc_wwrl_inv_data_tbl
            --             WHERE     part_no IN (lv_common_name,
            --                                   lv_rmktng_name,
            --                                   lv_spare_name,
            --                                   lv_ws_rmktng_name)
            --                   AND SUBSTR (warehouse, 1, 2) = SUBSTR (lv_inv_type, 1, 2);
            ELSE
               SELECT ROUND (SUM (QTY))
                 INTO lv_QOH
                 FROM (  SELECT CASE
                                   WHEN    LOCATION LIKE '%FG%'
                                        OR (    lv_rmktng_name IS NULL
                                            AND lv_ws_rmktng_name IS NULL)
                                   THEN
                                      SUM (QTY_ON_HAND) + SUM (QTY_IN_TRANSIT)
                                   ELSE
                                        (SUM (QTY_ON_HAND) + SUM (QTY_IN_TRANSIT))
                                      * NVL (
                                             RC_UTILITY.GET_REFURB_YIELD (
                                                RC_UTILITY.GET_INVENTORY_ITEM_ID (
                                                   NVL (lv_rmktng_name,
                                                        lv_ws_rmktng_name)),
                                                SUBSTR (SITE, 1, 3),
                                                LOCATION)
                                           / 100,
                                           0)
                                END
                                   QTY
                           FROM CRPADM.RC_INV_BTS_C3_MV ML1
                          WHERE     ML1.part_number IN (lv_common_name,
                                                        lv_rmktng_name,
                                                        lv_spare_name,
                                                        lv_ws_rmktng_name)
                                AND ML1.LOCATION IN (SELECT DISTINCT
                                                            SUB_INVENTORY_LOCATION
                                                       FROM CRPADM.RC_SUB_INV_LOC_MSTR LM,
                                                            CRPADM.RC_SUB_INV_LOC_FLG_DTLS FD
                                                      WHERE     LM.SUB_INVENTORY_ID =
                                                                   FD.SUB_INVENTORY_ID
                                                            AND is_scrap =
                                                                   lv_inv_type)
                       GROUP BY SITE, LOCATION);
            END IF;
         END IF;
   
         RETURN lv_QOH;
      END;
   
      FUNCTION GET_SALES_DATA (i_sales_type      VARCHAR2,
                               i_excess_name     VARCHAR2,
                               i_fiscal          NUMBER,
                               i_product_name    VARCHAR2)
         RETURN NUMBER
      IS
         lv_sales            NUMBER;
         lv_sales_type       VARCHAR2 (50);
         lv_fiscal           NUMBER;
         --      lv_retail           NUMBER;
         --      lv_excess           NUMBER;
         --      lv_refresh_name     VARCHAR2 (256);
         --      lv_excess_name      VARCHAR2 (256);
   
         lv_year_strt_date   DATE;
         lv_year_end_date    DATE;
         lv_excess_name      VARCHAR2 (256);
         lv_product_name     VARCHAR2 (256);
      BEGIN
         lv_sales_type := i_sales_type;
         lv_fiscal := i_fiscal;
         --      lv_retail := i_retail;
         lv_excess_name := i_excess_name;
         --      lv_excess := i_excess;
         --      lv_refresh_name := i_refresh_name;
         --      lv_excess_name := i_excess_name;
         lv_product_name := i_product_name;
   
         SELECT MIN (FISCAL_QTR_START_DATE), MAX (FISCAL_QTR_END_DATE)
           INTO lv_year_strt_date, lv_year_end_date
           FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
          WHERE fiscal_year_number IN (SELECT DISTINCT fiscal_year_number
                                         FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                                        WHERE CALENDAR_DATE =
                                                 TRUNC (
                                                    ADD_MONTHS (SYSDATE,
                                                                lv_fiscal)));
   
   
         --      IF (lv_sales_type = 'SALES UNITS')
         --      THEN
         --         SELECT SUM (MTD_SHIPMENT_QTY)
         --           INTO lv_sales
         --           FROM CRPSC.RC_MONTHLY_SHIPMENT_REVENUE
         --          WHERE     REFRESH_INVENTORY_ITEM_ID IN (lv_retail, lv_excess)
         --                AND MONTH_END_SHIP_DATE BETWEEN lv_year_strt_date
         --                                            AND lv_year_end_date;
         --      ELSIF (lv_sales_type = 'SALES REVENUE')
         --      THEN
         --         SELECT SUM (MTD_SHIPMENT_REV)
         --           INTO lv_sales
         --           FROM CRPSC.RC_MONTHLY_SHIPMENT_REVENUE
         --          WHERE     REFRESH_INVENTORY_ITEM_ID IN (lv_retail, lv_excess)
         --                AND MONTH_END_SHIP_DATE BETWEEN lv_year_strt_date
         --                                            AND lv_year_end_date;
         --      ELS
         IF (lv_sales_type = 'ROLLING_REV')
         THEN
            --            SELECT NVL (SUM (SHP.GRAND_TOTAL_QTY_REV), 0)
            --              INTO lv_sales
            --              FROM (SELECT PRODUCT_ID, GRAND_TOTAL_QTY_REV
            --                      FROM VAVNI_CISCO_RSCM_BP.VV_BP_MON_ROLLING_SHIP_DATA_VW)
            --                   SHP
            --                   INNER JOIN CRPADM.RC_PRODUCT_MAPID_MAPPING B
            --                      ON SHP.PRODUCT_ID = B.PRODUCT_MAP_ID
            --             WHERE REFRESH_PART_NUMBER IN (lv_refresh_name, lv_excess_name);
   
            SELECT NVL (SUM (SHP.TOTAL_REV), 0)
              INTO lv_sales
              FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS SHP
                   INNER JOIN CRPADM.RC_PRODUCT_MASTER B
                      ON SHP.REFRESH_INVENTORY_ITEM_ID =
                            B.REFRESH_INVENTORY_ITEM_ID
             WHERE REFRESH_PART_NUMBER IN (lv_product_name, lv_excess_name);
         ELSE
            SELECT NVL (SUM (SHP.TOTAL_QTY), 0)
              INTO lv_sales
              FROM CRPSC.RC_MONTHLY_ROLLING_SHIP_DTLS SHP
                   INNER JOIN CRPADM.RC_PRODUCT_MASTER B
                      ON SHP.REFRESH_INVENTORY_ITEM_ID =
                            B.REFRESH_INVENTORY_ITEM_ID
             --                         AND SHP.PROGRAM_TYPE = lv_prog_type
             WHERE REFRESH_PART_NUMBER IN (lv_product_name, lv_excess_name);
         END IF;
   
   
         RETURN lv_sales;
      END;
   
   
   
      PROCEDURE rc_get_exclude_pid (
         o_exclude_list            OUT rc_exclde_pid_list,
         i_min_row              IN     NUMBER,
         i_max_row              IN     NUMBER,
         i_filter_column_name   IN     VARCHAR2,
         i_filter_user_input    IN     VARCHAR2,
         i_sort_column_name     IN     VARCHAR2,
         i_sort_column_by       IN     VARCHAR2,
         i_filter_list          IN     rc_filter_list)
      IS
         lv_exclude_list         rc_exclde_pid_list;
         lv_filter_list          rc_filter_list := i_filter_list;
         v_query                 VARCHAR2 (32767);
         v_main_query            VARCHAR2 (32767);
         lv_max_row              NUMBER;
         lv_min_row              NUMBER;
         lv_total_row_count      NUMBER;
         lv_filter_column_name   VARCHAR2 (100);
         lv_filter_user_input    VARCHAR2 (100);
         lv_sort_column_name     VARCHAR2 (100);
         lv_sort_column_by       VARCHAR2 (100);
         lv_filter_value         VARCHAR2 (1000);
         v_count_query           VARCHAR2 (32767) DEFAULT NULL;
      BEGIN
         lv_exclude_list := rc_exclde_pid_list ();
         o_exclude_list := rc_exclde_pid_list ();
         lv_max_row := i_max_row;
         lv_min_row := i_min_row;
         lv_filter_column_name := UPPER (TRIM (i_filter_column_name));
         lv_filter_user_input := UPPER (TRIM (i_filter_user_input));
         lv_sort_column_name := UPPER (TRIM (i_sort_column_name));
         lv_sort_column_by := UPPER (TRIM (i_sort_column_by));
   
         --      lv_exclude_list := i_exclude_list;
   
         /*SELECT RC_EXCLUDE_PID_OBJ (PRODUCT_ID,
                                    EOS_DATE,
                                    EOM_DATE,
                                    EXCLUSION_REASON)
           BULK COLLECT INTO lv_exclude_list
           FROM (SELECT *
                   FROM (SELECT fd.*, ROWNUM rnum
                           FROM (  SELECT *
                                     FROM RC_EXCLUDE_PID_LIST
                                 ORDER BY PRODUCT_ID) fd
                          WHERE ROWNUM <= i_max_row)
                  WHERE rnum > i_min_row);
   
         o_exclude_list := lv_exclude_list;*/
         v_main_query :=
               'SELECT RC_EXCLUDE_PID_OBJ (product_id, eos_date, eom_date, exclusion_reason) from (
               SELECT product_id, eos_date, eom_date, exclusion_reason
                   FROM (SELECT fd.product_id, fd.eos_date, fd.eom_date,
                   fd.exclusion_reason, ROWNUM rnum
                           FROM (  SELECT *
                                     FROM RC_EXCLUDE_PID_LIST
                                 ORDER BY PRODUCT_ID) fd
                          WHERE ROWNUM <= '
            || i_max_row
            || ')
                  WHERE rnum > '
            || i_min_row;
   
   
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
            FOR idx IN 1 .. i_filter_list.COUNT ()
            LOOP
               IF idx = 1
               THEN
                  IF     (i_filter_list (idx).filter IS NOT NULL)
                     AND (i_filter_list (idx).filter NOT LIKE ' ')
                  THEN
                     lv_filter_value :=
                        UPPER (TO_CHAR (TRIM (i_filter_list (idx).filter)));
   
   
                     v_main_query :=
                           v_main_query
                        || ' AND (UPPER(TRIM('
                        || lv_filter_column_name
                        || ')) LIKE (UPPER(TRIM(''%'
                        || lv_filter_value
                        || '%''))))';
                     v_count_query :=
                           v_count_query
                        || ' AND (UPPER(TRIM('
                        || lv_filter_column_name
                        || ')) LIKE (UPPER(TRIM(''%'
                        || lv_filter_value
                        || '%''))))';
                  END IF;
               ELSIF     (i_filter_list (idx).filter IS NOT NULL)
                     AND (i_filter_list (idx).filter NOT LIKE ' ')
               THEN
                  lv_filter_value :=
                     UPPER (TO_CHAR (TRIM (i_filter_list (idx).filter)));
   
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
         END IF;
   
         -- For Sorting based on the user selection
         IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
         THEN
            -- For getting the limited set of data based on the min and max values
            -- v_row_clause :=
            --    ' ) WHERE RNUM >' || lv_min_row || ' AND RNUM <=' || lv_max_row;
   
            v_main_query :=
                  v_main_query
               || ' ORDER BY '
               || lv_sort_column_name
               || ' '
               || lv_sort_column_by
               || ')';
         ELSE
            -- For getting the limited set of data based on the min and max values
            -- v_row_clause :=
            --    ' ) WHERE RNUM >' || lv_min_row || ' AND RNUM <=' || lv_max_row;
   
            v_main_query := v_main_query || ' ORDER BY PRODUCT_ID)';
         END IF;
   
   
         BEGIN
            EXECUTE IMMEDIATE v_main_query BULK COLLECT INTO o_exclude_list;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               o_exclude_list := rc_exclde_pid_list ();
               crpadm.rc_global_error_logging (
                  'OTHERS',
                     SUBSTR (SQLERRM, 1, 200)
                  || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
                  NULL,
                  'RC_GET_EXCLUDE_PID',
                  'PROCEDURE',
                  NULL,
                  'Y');
            WHEN OTHERS
            THEN
               crpadm.rc_global_error_logging (
                  'OTHERS',
                     SUBSTR (SQLERRM, 1, 200)
                  || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
                  NULL,
                  'RC_GET_EXCLUDE_PID',
                  'PROCEDURE',
                  NULL,
                  'Y');
         END;
      --o_exclude_list := lv_exclude_list;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            o_exclude_list := rc_exclde_pid_list ();
            crpadm.rc_global_error_logging (
               'NO DATA FOUND',
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
               NULL,
               'RC_GET_EXCLUDE_PID',
               'PROCEDURE',
               NULL,
               'Y');
         WHEN OTHERS
         THEN
            o_exclude_list := NULL;
            crpadm.rc_global_error_logging (
               'OTHERS',
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
               NULL,
               'RC_GET_EXCLUDE_PID',
               'PROCEDURE',
               NULL,
               'Y');
      END;
   
      PROCEDURE rc_get_include_pid (
         o_include_list            OUT rc_inclde_pid_list,
         i_min_row              IN     NUMBER,
         i_max_row              IN     NUMBER,
         i_filter_column_name   IN     VARCHAR2,
         i_filter_user_input    IN     VARCHAR2,
         i_sort_column_name     IN     VARCHAR2,
         i_sort_column_by       IN     VARCHAR2,
         i_filter_list          IN     rc_filter_list)
      IS
         lv_include_list         rc_inclde_pid_list;
         v_query                 VARCHAR2 (32767);
         v_main_query            VARCHAR2 (32767);
         lv_max_row              NUMBER;
         lv_min_row              NUMBER;
         lv_total_row_count      NUMBER;
         lv_filter_column_name   VARCHAR2 (100);
         lv_filter_user_input    VARCHAR2 (100);
         lv_sort_column_name     VARCHAR2 (100);
         lv_sort_column_by       VARCHAR2 (100);
         lv_filter_value         VARCHAR2 (1000);
         v_count_query           VARCHAR2 (32767) DEFAULT NULL;
      BEGIN
         lv_include_list := rc_inclde_pid_list ();
         o_include_list := rc_inclde_pid_list ();
         lv_max_row := i_max_row;
         lv_min_row := i_min_row;
         lv_filter_column_name := UPPER (TRIM (i_filter_column_name));
         lv_filter_user_input := UPPER (TRIM (i_filter_user_input));
         lv_sort_column_name := UPPER (TRIM (i_sort_column_name));
         lv_sort_column_by := UPPER (TRIM (i_sort_column_by));
   
         --      lv_exclude_list := i_exclude_list;
   
         v_main_query :=
               'SELECT RC_INCLUDE_PID_OBJ (PRODUCT_ID,
                                    QUANTITY,
                                    EFFECTIVE_TO_DATE,
                                    INVENTORY_TYPE)
           FROM (SELECT *
                   FROM (SELECT fd.*, ROWNUM rnum
                           FROM (  SELECT PRODUCT_ID,
                                          DEMAND_QUANTITY AS QUANTITY,
                                          EFFECTIVE_TO_DATE,
                                          INV_FLAG AS INVENTORY_TYPE
                                     FROM RC_INCLUDE_PID_LIST
                                 ORDER BY PRODUCT_ID) fd
                          WHERE ROWNUM <= '
            || i_max_row
            || ')
                  WHERE rnum >'
            || i_min_row;
   
   
   
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
            FOR idx IN 1 .. i_filter_list.COUNT ()
            LOOP
               IF idx = 1
               THEN
                  IF     (i_filter_list (idx).filter IS NOT NULL)
                     AND (i_filter_list (idx).filter NOT LIKE ' ')
                  THEN
                     lv_filter_value :=
                        UPPER (TO_CHAR (TRIM (i_filter_list (idx).filter)));
   
   
                     v_main_query :=
                           v_main_query
                        || ' AND (UPPER(TRIM('
                        || lv_filter_column_name
                        || ')) LIKE (UPPER(TRIM('''
                        || lv_filter_value
                        || '''))))';
                     v_count_query :=
                           v_count_query
                        || ' AND (UPPER(TRIM('
                        || lv_filter_column_name
                        || ')) LIKE (UPPER(TRIM(''%'
                        || lv_filter_value
                        || '%''))))';
                  END IF;
               ELSIF     (i_filter_list (idx).filter IS NOT NULL)
                     AND (i_filter_list (idx).filter NOT LIKE ' ')
               THEN
                  lv_filter_value :=
                     UPPER (TO_CHAR (TRIM (i_filter_list (idx).filter)));
   
                  v_main_query :=
                        v_main_query
                     || ' OR (UPPER(TRIM('
                     || lv_filter_column_name
                     || ')) LIKE (UPPER(TRIM('''
                     || lv_filter_value
                     || '''))))';
                  v_count_query :=
                        v_count_query
                     || ' OR (UPPER(TRIM('
                     || lv_filter_column_name
                     || ')) LIKE (UPPER(TRIM(''%'
                     || lv_filter_value
                     || '%''))))';
               END IF;
            END LOOP;
         END IF;
   
         CASE
            WHEN lv_sort_column_name = 'QUANTITY'
            THEN
               lv_sort_column_name := 'DEMAND_QUANTITY';
            WHEN lv_sort_column_name = 'INVENTORY_TYPE'
            THEN
               lv_sort_column_name := 'INV_FLAG';
            ELSE
               lv_sort_column_name := lv_sort_column_name;
         END CASE;
   
         -- For Sorting based on the user selection
         IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
         THEN
            -- For getting the limited set of data based on the min and max values
            -- v_row_clause :=
            --    ' ) WHERE RNUM >' || lv_min_row || ' AND RNUM <=' || lv_max_row;
   
            v_main_query :=
                  v_main_query
               || ' ORDER BY '
               || lv_sort_column_name
               || ' '
               || lv_sort_column_by
               || ')';
         ELSE
            -- For getting the limited set of data based on the min and max values
            -- v_row_clause :=
            --    ' ) WHERE RNUM >' || lv_min_row || ' AND RNUM <=' || lv_max_row;
   
            v_main_query := v_main_query || ' ORDER BY PRODUCT_ID)';
         END IF;
   
         --      INSERT INTO temp_1
         --           VALUES (v_main_query);
   
         COMMIT;
   
         --  DBMS_OUTPUT.put_line (v_main_query);
   
         BEGIN
            EXECUTE IMMEDIATE v_main_query BULK COLLECT INTO o_include_list;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               o_include_list := rc_inclde_pid_list ();
         END;
      --o_include_list := lv_include_list;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            o_include_list := NULL;
            crpadm.rc_global_error_logging (
               'NO DATA FOUND',
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
               NULL,
               'RC_GET_INCLUDE_PID',
               'PROCEDURE',
               NULL,
               'Y');
         WHEN OTHERS
         THEN
            o_include_list := NULL;
            crpadm.rc_global_error_logging (
               'OTHERS',
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
               NULL,
               'RC_GET_INCLUDE_PID',
               'PROCEDURE',
               NULL,
               'Y');
      END;
   
      PROCEDURE rc_get_final_demand (
         o_final_demand_list       OUT rc_final_demand_list,
         i_min_row              IN     NUMBER,
         i_max_row              IN     NUMBER,
         i_filter_column_name   IN     VARCHAR2,
         i_filter_user_input    IN     VARCHAR2,
         i_sort_column_name     IN     VARCHAR2,
         i_sort_column_by       IN     VARCHAR2,
         i_filter_list          IN     rc_filter_list)
      IS
         lv_final_demand_list    rc_final_demand_list;
         v_query                 VARCHAR2 (32767);
         v_main_query            VARCHAR2 (32767);
         lv_max_row              NUMBER;
         lv_min_row              NUMBER;
         lv_total_row_count      NUMBER;
         lv_filter_column_name   VARCHAR2 (100);
         lv_filter_user_input    VARCHAR2 (100);
         lv_sort_column_name     VARCHAR2 (100);
         lv_sort_column_by       VARCHAR2 (100);
         lv_filter_value         VARCHAR2 (1000);
         v_count_query           VARCHAR2 (32767) DEFAULT NULL;
      BEGIN
         lv_final_demand_list := rc_final_demand_list ();
         o_final_demand_list := rc_final_demand_list ();
         lv_max_row := i_max_row;
         lv_min_row := i_min_row;
         lv_filter_column_name := UPPER (TRIM (i_filter_column_name));
         lv_filter_user_input := UPPER (TRIM (i_filter_user_input));
         lv_sort_column_name := UPPER (TRIM (i_sort_column_name));
         lv_sort_column_by := UPPER (TRIM (i_sort_column_by));
   
         --      lv_exclude_list := i_exclude_list;
   
         v_main_query :=
               'SELECT RC_FINAL_DEMAND_OBJ (PRODUCT_NAME,
                                     CISCO_PRODUCT_NAME,
                                     PRODUCT_LIFE_CYCLE,
                                     STORAGE_MAX,
                                     DEMAND_MAX,
                                     ASP,
                                     QOH,
                                     FGI_QTY,
                                     FGIX_QTY,
                                     DGI_QTY,
                                     PRIORITY,
                                     WPM,
                                     LIST_GENERATION_DATE)
           FROM (SELECT *
                   FROM (  SELECT PRODUCT_NAME,
                                  CISCO_PRODUCT_NAME,
                                  PRODUCT_LIFE_CYCLE,
                                  STORAGE_MAX,
                                  DEMAND_MAX,
                                  ASP,
                                  QOH,
                                  FGI_QTY,
                                  FGIX_QTY,
                                  DGI_QTY,
                                  PRIORITY,
                                  WPM,
                                  LIST_GENERATION_DATE AS LIST_GENERATION_DATE
                             FROM RC_FIN_DEMAND_LIST
                         ORDER BY PRODUCT_NAME) fd
                  WHERE ROWNUM <= '
            || i_max_row
            || ' AND ROWNUM >= '
            || i_min_row;
   
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
            FOR idx IN 1 .. i_filter_list.COUNT ()
            LOOP
               IF idx = 1
               THEN
                  IF     (i_filter_list (idx).filter IS NOT NULL)
                     AND (i_filter_list (idx).filter NOT LIKE ' ')
                  THEN
                     lv_filter_value :=
                        UPPER (TO_CHAR (TRIM (i_filter_list (idx).filter)));
   
   
                     v_main_query :=
                           v_main_query
                        || ' AND (UPPER(TRIM('
                        || lv_filter_column_name
                        || ')) LIKE (UPPER(TRIM(''%'
                        || lv_filter_value
                        || '%''))))';
                     v_count_query :=
                           v_count_query
                        || ' AND (UPPER(TRIM('
                        || lv_filter_column_name
                        || ')) LIKE (UPPER(TRIM(''%'
                        || lv_filter_value
                        || '%''))))';
                  END IF;
               ELSIF     (i_filter_list (idx).filter IS NOT NULL)
                     AND (i_filter_list (idx).filter NOT LIKE ' ')
               THEN
                  lv_filter_value :=
                     UPPER (TO_CHAR (TRIM (i_filter_list (idx).filter)));
   
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
         END IF;
   
         -- For Sorting based on the user selection
         IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
         THEN
            -- For getting the limited set of data based on the min and max values
            -- v_row_clause :=
            --    ' ) WHERE RNUM >' || lv_min_row || ' AND RNUM <=' || lv_max_row;
   
            v_main_query :=
                  v_main_query
               || ' ORDER BY '
               || lv_sort_column_name
               || ' '
               || lv_sort_column_by
               || ')';
         ELSE
            -- For getting the limited set of data based on the min and max values
            -- v_row_clause :=
            --    ' ) WHERE RNUM >' || lv_min_row || ' AND RNUM <=' || lv_max_row;
   
            v_main_query := v_main_query || ' ORDER BY PRODUCT_NAME)';
         END IF;
   
         --   DBMS_OUTPUT.put_line (v_main_query);
   
         BEGIN
            EXECUTE IMMEDIATE v_main_query BULK COLLECT INTO o_final_demand_list;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               o_final_demand_list := rc_final_demand_list ();
         END;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            o_final_demand_list := NULL;
            crpadm.rc_global_error_logging (
               'NO DATA FOUND',
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
               NULL,
               'RC_GET_FINAL_DEMAND',
               'PROCEDURE',
               NULL,
               'Y');
         WHEN OTHERS
         THEN
            o_final_demand_list := NULL;
            crpadm.rc_global_error_logging (
               'OTHERS',
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
               NULL,
               'RC_GET_FINAL_DEMAND',
               'PROCEDURE',
               NULL,
               'Y');
      END;


   PROCEDURE rc_get_final_demand_filter (
      o_final_demand_list       OUT rc_final_demand_list,
      i_min_row              IN     NUMBER,
      i_max_row              IN     NUMBER,
      i_filter_column_name   IN     VARCHAR2,
      i_filter_user_input    IN     VARCHAR2,
      i_sort_column_name     IN     VARCHAR2,
      i_sort_column_by       IN     VARCHAR2,
      i_filter_list          IN     rc_new_filter_obj_list)
   IS
      lv_final_demand_list    rc_final_demand_list;
      v_query                 VARCHAR2 (32767);
      v_main_query            CLOB;                        --VARCHAR2 (32767);
      lv_max_row              NUMBER;
      lv_min_row              NUMBER;
      lv_total_row_count      NUMBER;
      lv_filter_column_name   VARCHAR2 (100);
      lv_filter_user_input    VARCHAR2 (100);
      lv_sort_column_name     VARCHAR2 (100);
      lv_sort_column_by       VARCHAR2 (100);
      lv_filter_value         VARCHAR2 (1000);
      v_count_query           CLOB;           --VARCHAR2 (32767) DEFAULT NULL;
      lv_filter_data_list     rc_filter_data_obj_list;
      lv_null_query           VARCHAR2 (32767);
      lv_in_query             CLOB;
      ln_out_qry              CLOB;                        -- VARCHAR2(32767);
   BEGIN
      lv_final_demand_list := rc_final_demand_list ();
      o_final_demand_list := rc_final_demand_list ();
      lv_max_row := i_max_row;
      lv_min_row := i_min_row;
      IF(UPPER (TRIM (i_filter_column_name))='RF_ADJ_FORECAST') THEN 
      lv_filter_column_name :='RF_ADJUSTED_FORECAST';
      ELSE
      lv_filter_column_name := UPPER (TRIM (i_filter_column_name));
      END IF;
      lv_filter_user_input := UPPER (TRIM (i_filter_user_input));
      lv_sort_column_name := UPPER (TRIM (i_sort_column_name));
      lv_sort_column_by := UPPER (TRIM (i_sort_column_by));


     /*  INSERT INTO TEMP_QUERY
       VALUES('i_filter_column_name :'||i_filter_column_name||
       'i_filter_user_input: '||       i_filter_user_input||
       'i_sort_column_name: '||i_sort_column_name||
       'i_sort_column_by: '||i_sort_column_by,SYSDATE);*/





      --      lv_exclude_list := i_exclude_list;

      v_main_query :=
         'SELECT RC_FINAL_DEMAND_OBJ (RF_PID ,
   PRODUCT_NAME ,
   REFRESH_LIFE_CYCLE ,
   VR_AVL_TO_ALLOCATE_QTY, 
   EXPECTED_RECEIPTS,  
   TOTAL_DEMAND_QTY ,
   PRIORITY ,
   CONDITION_OF_INV_NEEDED ,
   PRODUCT_DESCRIPTION ,
   PRODUCT_TYPE ,
   PRODUCT_FAMILY ,
   BUSINESS_UNIT ,
   BL ,
   END_OF_LAST_SUPPORT_DATE ,
   STANDARD_COST, 
   GPL ,
   ASP ,
   BLOCKED_PID_FROM ,
   REASON_FOR_BLOCKED_PID ,
   DGI, 
   FGI ,
   WIP ,
   NIB ,
   TOTAL_QTY, 
   NETTABLE_DGI, 
   NETTABLE_FGI ,
   TOTAL_NETTABLE_QTY, 
   CONS_QTY ,
   CONS_PERCENTAGE, 
   POE_MAX ,
   MOS ,
   MOS_MONTH ,
   NETTABLE_MOS, 
   REVENUE ,
   SHIPPED_UNITS_12M, 
   BACKLOG ,
   TOTAL_RESERVATIONS, 
   SERVICE_REPAIR_FLAG ,
   RF_CREATION_DATE ,
   REPAIR_METHOD ,
   FCS ,
   INCLUDE_OR_EXCLUDE ,
   INCLUDE_OR_EXCLUDE_REASON ,
   LIST_GENERATION_DATE ,
   VR_FETCHED_DATE ,
   IN_TRANSIT_POE     ,        
   IN_TRANSIT_NIB      ,       
   IN_TRANSIT_DGI,
   ITEM_TYPE,
   PID_CATEGORY,
   ITEM_CATALOG_CATEGORY,
   RF_FORECAST,
   WS_FORECAST,
   RF_ADJUSTED_FORECAST,
   UNFULFILLED_FORECAST,
   OLD_DEMAND  )
  FROM (SELECT *
          FROM (SELECT PRODUCT_NAME,
                        VR_AVAIL_QTY VR_AVL_TO_ALLOCATE_QTY,
                       ROUND(DEMAND_MAX) TOTAL_DEMAND_QTY,
                       PRODUCT_DESCRIPTION,
                       PRODUCT_TYPE,
                       PRODUCT_FAMILY,
                       BUSINESS_UNIT,
                       TO_CHAR (EOS, ''DD-MON-YYYY'')
                          AS END_OF_LAST_SUPPORT_DATE,
                       UNIT_STD_COST_USD STANDARD_COST,
                       ASP,
                       BLOCKED_PID_FROM,
                       REASON_FOR_BLOCKED_PID,
                       DGI,
                       FGI,
                       WIP,
                       NIB,
                       TOTAL_QTY,
                       NETTABLE_DGI_QTY NETTABLE_DGI,
                       NETTABLE_FGI_QTY NETTABLE_FGI,
                       TOTAL_NETTABLE_QTY,
                       CONS_QTY,
                       CONS_PERCENTAGE,
                       POE_MAX,
                       MOS,
                       MOS_BANDS MOS_MONTH,
                       NETTABLE_MOS,
                       REVENUE_BANDS REVENUE,
                       CUR_SALES_UNITS              AS SHIPPED_UNITS_12M,
                       BACKLOG,
                       TOTAL_RESERVATIONS,
                       SERVICE_REPAIR_FLAG,
                       REPAIR_METHOD,
                       TO_CHAR (RF_CREATION_DATE, ''DD-MON-YYYY'')
                          AS RF_CREATION_DATE,
                       RF_PID,
                       TO_CHAR (FCS, ''MM/DD/YYYY'') AS FCS,
                       INCLUDE_OR_EXCLUDE,
                       INCLUDE_OR_EXCLUDE_REASON,
                       PRIORITY,
                       CONDITION_OF_INV CONDITION_OF_INV_NEEDED,
                       TO_CHAR (LIST_GENERATION_DATE, ''DD-MON-YYYY HH:MI:SS AM'')
                          AS LIST_GENERATION_DATE, (SELECT MAX(TO_CHAR(CREATED_AT, ''DD-MON-YYYY HH:MI:SS AM'')) FROM RC_WWRL_INV_DATA_TBL) AS VR_FETCHED_DATE,
                          REFRESH_LIFE_CYCLE,
                            EXPECTED_RECEIPTS,
                            GPL,BL,
                            IN_TRANSIT_POE,
                            IN_TRANSIT_NIB,IN_TRANSIT_DGI,ITEM_TYPE,
   PID_CATEGORY,
   ITEM_CATALOG_CATEGORY,
   RF_FORECAST,
   WS_FORECAST,
   RF_ADJUSTED_FORECAST,
   UNFULFILLED_FORECAST,
   OLD_DEMAND
                  FROM (SELECT fd.*,';

      IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
      THEN
         v_main_query :=
               v_main_query
            || 'ROW_NUMBER()  OVER (ORDER BY '
            || lv_sort_column_name
            || ' '
            || lv_sort_column_by
            || ' ) AS rnum  FROM RC_FIN_DEMAND_LIST fd where (0 = 0  ';
      ELSE
         v_main_query :=
               v_main_query
            || ' ROWNUM rnum
                     FROM  RC_FIN_DEMAND_LIST fd where (0 = 0  ';
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


      IF i_filter_list IS NOT EMPTY
      THEN
         get_in_condition_for_query (i_filter_list, lv_in_query);
         v_main_query := v_main_query || lv_in_query;
      END IF;

      -- For Column Level Filter with user selected checkboxes

      /* IF i_filter_list IS NOT EMPTY
       THEN
          FOR IDX IN 1 .. i_filter_list.COUNT ()
          LOOP
             IF     (i_filter_list (idx).COL_NAME IS NOT NULL)
                AND (i_filter_list (idx).COL_NAME NOT LIKE ' ')
             THEN
                lv_filter_column_name :=
                   UPPER (TO_CHAR (TRIM (i_filter_list (idx).COL_NAME)));



                   v_main_query :=
                      v_main_query
                   || ' AND (UPPER ('
                   || lv_filter_column_name
                   || ') IN (';

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
                           v_main_query :=
                                  v_main_query
                               || ''''
                               || lv_filter_value
                               || '''';
                            v_count_query :=
                                  v_count_query
                               || ''''
                               || lv_filter_value
                               || '''';
                         --ELSE
                            -- v_main_query  :=
                             --     v_main_query
                             --  || ','
                             --  || ''''
                             --  || lv_filter_value
                             --  || '''';
                           -- v_count_query :=
                            --      v_count_query
                             --  || ','
                            --   || ''''
                            --   || lv_filter_value
                            --   || '''';
                         END IF;
                      END IF;
                   END IF;
                END LOOP;

                v_main_query := v_main_query || ')'|| lv_null_query || ')';
                v_count_query := v_count_query || ')'|| lv_null_query || ')';
                lv_null_query:=' ';
             END IF;
          END LOOP;
       -- v_count_query := v_count_query || '))';
       --v_main_query := v_main_query || '))';
       END IF;*/


      IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
      THEN
         -- For getting the limited set of data based on the min and max values
         ln_out_qry :=
               v_main_query
            || ' AND 1 = 1) ) WHERE rnum >'
            || TO_CHAR (lv_min_row)
            || ' AND rnum <='
            || TO_CHAR (lv_max_row);



         ln_out_qry :=
               ln_out_qry
            || ' ORDER BY '
            || lv_sort_column_name
            || ' '
            || lv_sort_column_by
            || '))';

         v_main_query := ln_out_qry;
      ELSE
         -- For getting the limited set of data based on the min and max values
         ln_out_qry :=
               ln_out_qry
            || ' AND 1 = 1) AND ROWNUM <= '
            || TO_CHAR (lv_max_row)
            || ') WHERE rnum >'
            || TO_CHAR (lv_min_row);

         v_main_query :=
            v_main_query || ln_out_qry || ' ORDER BY PRODUCT_NAME))';
      END IF;

         /*   INSERT INTO temp_query
                 VALUES (v_main_query,sysdate);*/

      COMMIT;

      BEGIN
         EXECUTE IMMEDIATE v_main_query BULK COLLECT INTO o_final_demand_list;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            o_final_demand_list := rc_final_demand_list ();
      END;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         o_final_demand_list := NULL;
         crpadm.rc_global_error_logging (
            'NO DATA FOUND',
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
            NULL,
            'RC_GET_FINAL_DEMAND',
            'PROCEDURE',
            NULL,
            'Y');
      WHEN OTHERS
      THEN
         o_final_demand_list := NULL;
         crpadm.rc_global_error_logging (
            'OTHERS',
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
            NULL,
            'RC_GET_FINAL_DEMAND',
            'PROCEDURE',
            NULL,
            'Y');
   END;

      PROCEDURE rc_get_final_demand_unique (
         o_final_demand_list       OUT rc_addl_filters_list,
         i_user_id              IN     VARCHAR2,
         i_filter_column_name   IN     VARCHAR2,
         i_tabname              IN     VARCHAR2,
         i_filter_list          IN     rc_new_filter_obj_list)
      IS
         lv_final_demand_list    rc_addl_filters_list;
         v_query                 CLOB;                        --VARCHAR2 (32767);
         v_main_query            CLOB;                        --VARCHAR2 (32767);
         lv_filter_column        VARCHAR2 (100);
         lv_total_row_count      NUMBER;
         lv_filter_column_name   VARCHAR2 (100);
         lv_user_id              VARCHAR2 (100);
         lv_in_query             CLOB;
         lv_filter_value         VARCHAR2 (1000);
         v_count_query           VARCHAR2 (32767) DEFAULT NULL;
         lv_filter_data_list     rc_filter_data_obj_list;
         lv_tabname              VARCHAR2 (100);
         lv_null_query           VARCHAR2 (32767);
      BEGIN
         lv_final_demand_list := rc_addl_filters_list ();
         lv_user_id := i_user_id;
         lv_tabname := i_tabname;
   
         lv_filter_column := UPPER (TRIM (i_filter_column_name));
   
   
         CASE
            WHEN lv_tabname = 'finaldemand'
            THEN
               v_main_query :=
                  'SELECT *
             FROM (SELECT PRODUCT_NAME,
                           VR_AVAIL_QTY,
                          DEMAND_MAX,
                          PRODUCT_DESCRIPTION,
                          PRODUCT_TYPE,
                          PRODUCT_FAMILY,
                          BUSINESS_UNIT,
                          TO_CHAR (EOS, ''DD-MON-YYYY'')
                             AS EOS,
                          UNIT_STD_COST_USD,
                          ASP,
                          BLOCKED_PID_FROM,
                          REASON_FOR_BLOCKED_PID,
                          DGI,
                          FGI,
                          WIP,
                          NIB,
                          TOTAL_QTY,
                          NETTABLE_DGI_QTY ,
                          NETTABLE_FGI_QTY ,
                          TOTAL_NETTABLE_QTY,
                          CONS_QTY,
                          CONS_PERCENTAGE,
                          POE_MAX,
                          MOS,
                          MOS_BANDS,
                          NETTABLE_MOS,
                          REVENUE_BANDS REVENUE,
                          CUR_SALES_UNITS             ,
                          BACKLOG,
                          TOTAL_RESERVATIONS,
                          SERVICE_REPAIR_FLAG,
                          REPAIR_METHOD,
                          TO_CHAR (RF_CREATION_DATE, ''DD-MON-YYYY'')
                             AS RF_CREATION_DATE,
                          RF_PID,
                          TO_CHAR (FCS, ''MM/DD/YYYY'') AS FCS,
                          INCLUDE_OR_EXCLUDE,
                          INCLUDE_OR_EXCLUDE_REASON,
                          PRIORITY,
                          CONDITION_OF_INV,
                          GPL,BL,
                           IN_TRANSIT_POE,
                           IN_TRANSIT_NIB,IN_TRANSIT_DGI,ITEM_TYPE,
                           PID_CATEGORY,
                           ITEM_CATALOG_CATEGORY,
                           RF_FORECAST,
                           WS_FORECAST,
                           RF_ADJUSTED_FORECAST ,
                           UNFULFILLED_FORECAST,
                           OLD_DEMAND,
                          TO_CHAR (LIST_GENERATION_DATE, ''DD-MON-YYYY HH:MI:SS AM'')
                             AS LIST_GENERATION_DATE
                                       FROM RC_FIN_DEMAND_LIST
                         ORDER BY PRODUCT_NAME) fd
                  WHERE 1=1 ';
            WHEN lv_tabname = 'includepid'
            THEN
               v_main_query :=
                  'SELECT PRODUCT_ID,
                                    QUANTITY,
                                    EFFECTIVE_TO_DATE,
                                    INVENTORY_TYPE
           FROM (SELECT *
                   FROM (SELECT fd.*, ROWNUM rnum
                           FROM (  SELECT PRODUCT_ID,
                                          DEMAND_QUANTITY AS QUANTITY,
                                          EFFECTIVE_TO_DATE,
                                          INV_FLAG AS INVENTORY_TYPE
                                     FROM RC_INCLUDE_PID_LIST
                                 ORDER BY PRODUCT_ID) fd)) WHERE 1=1';
            ELSE
               v_main_query :=
                  'SELECT product_id, eos_date, eom_date, exclusion_reason
                   FROM (SELECT fd.product_id, fd.eos_date, fd.eom_date,
                   fd.exclusion_reason, ROWNUM rnum
                           FROM (  SELECT *
                                     FROM RC_EXCLUDE_PID_LIST
                                 ORDER BY PRODUCT_ID) fd)  WHERE 1=1';
         END CASE;
   
   
         -- For Column Level Filtering based on the user input
   
   
         IF i_filter_list IS NOT EMPTY
         THEN
            get_in_condition_for_query (i_filter_list, lv_in_query);
   
   
            v_main_query := v_main_query || lv_in_query;
         END IF;
   
         /*  IF i_filter_list IS NOT EMPTY
           THEN
              FOR IDX IN 1 .. i_filter_list.COUNT ()
              LOOP
                 IF     (i_filter_list (idx).COL_NAME IS NOT NULL)
                    AND (i_filter_list (idx).COL_NAME NOT LIKE ' ')
                 THEN
                    lv_filter_column_name :=
                       UPPER (TO_CHAR (TRIM (i_filter_list (idx).COL_NAME)));
   
   
   
                       v_main_query :=
                          v_main_query
                       || ' AND ( UPPER ('
                       || lv_filter_column_name
                       || ') IN (';
   
   
   
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
     --
     --                                   IF    UPPER (lv_filter_column_name) =
     --                                 UPPER ('EFFECTIVE_TO_DATE')
     --
     --                        THEN
     --                           lv_filter_value :=
     --                              TO_CHAR (
     --                                 TO_DATE (lv_filter_value,
     --                                          'DD/MM/YYYY HH:MI:SS AM'));
     --                        END IF;
   
                             IF idx = 1
                             THEN
                               v_main_query :=
                                      v_main_query
                                   || ''''
                                   || lv_filter_value
                                   || '''';
   
                             ELSE
                                 v_main_query  :=
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
   
         v_query :=
               ' SELECT DISTINCT '
            || lv_filter_column
            || ' FROM ( '
            || v_main_query
            || ' )';
   
         v_query :=
            v_query || ' ORDER BY ' || lv_filter_column || ' ASC NULLS FIRST';
   
         /*      INSERT INTO TEMP_QUERY
                    VALUES (v_query,SYSDATE);*/
   
         COMMIT;
   
         BEGIN
            EXECUTE IMMEDIATE v_query BULK COLLECT INTO lv_final_demand_list;
   
            o_final_demand_list := lv_final_demand_list;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lv_final_demand_list := rc_addl_filters_list ();
         END;
         
         
         
         
      EXCEPTION
         WHEN OTHERS
         THEN
            -- Logging exception
            crpadm.rc_global_error_logging (
               'OTHERS',
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
               NULL,
               'CRPADM.RC_DEMAND_AUTOMATION.RC_GET_FINAL_DEMAND_UNIQUE',
               'PROCEDURE',
               lv_user_id,
               'N');
      END;
   
      PROCEDURE rc_get_include_pid_filter (
         o_include_list            OUT rc_inclde_pid_list,
         i_min_row              IN     NUMBER,
         i_max_row              IN     NUMBER,
         i_filter_column_name   IN     VARCHAR2,
         i_filter_user_input    IN     VARCHAR2,
         i_sort_column_name     IN     VARCHAR2,
         i_sort_column_by       IN     VARCHAR2,
         i_filter_list          IN     rc_new_filter_obj_list)
      IS
         lv_include_list         rc_inclde_pid_list;
         v_query                 CLOB;                        --VARCHAR2 (32767);
         v_main_query            CLOB;                        --VARCHAR2 (32767);
         lv_in_query             CLOB;
         lv_max_row              NUMBER;
         lv_min_row              NUMBER;
         lv_total_row_count      NUMBER;
         lv_filter_column_name   VARCHAR2 (100);
         lv_filter_user_input    VARCHAR2 (100);
         lv_sort_column_name     VARCHAR2 (100);
         lv_sort_column_by       VARCHAR2 (100);
         lv_filter_value         VARCHAR2 (1000);
         v_count_query           VARCHAR2 (32767) DEFAULT NULL;
         lv_filter_data_list     rc_filter_data_obj_list;
         lv_null_query           VARCHAR2 (32767);
      BEGIN
         lv_include_list := rc_inclde_pid_list ();
         o_include_list := rc_inclde_pid_list ();
         lv_max_row := i_max_row;
         lv_min_row := i_min_row;
         lv_filter_column_name := UPPER (TRIM (i_filter_column_name));
         lv_filter_user_input := UPPER (TRIM (i_filter_user_input));
         lv_sort_column_name := UPPER (TRIM (i_sort_column_name));
         lv_sort_column_by := UPPER (TRIM (i_sort_column_by));
   
         --      lv_exclude_list := i_exclude_list;
   
         v_main_query :=
            'SELECT RC_INCLUDE_PID_OBJ (PRODUCT_ID,
                                    QUANTITY,
                                    EFFECTIVE_TO_DATE,
                                    INVENTORY_TYPE)
           FROM (SELECT *
                   FROM (  SELECT PRODUCT_ID,
                                          DEMAND_QUANTITY AS QUANTITY,
                                          EFFECTIVE_TO_DATE,
                                          INV_FLAG AS INVENTORY_TYPE
                                     FROM (select fd.*, ';
   
         IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
         THEN
            CASE
               WHEN lv_sort_column_name = 'QUANTITY'
               THEN
                  lv_sort_column_name := 'DEMAND_QUANTITY';
               WHEN lv_sort_column_name = 'INVENTORY_TYPE'
               THEN
                  lv_sort_column_name := 'INV_FLAG';
               ELSE
                  lv_sort_column_name := lv_sort_column_name;
            END CASE;
   
            v_main_query :=
                  v_main_query
               || 'ROW_NUMBER()  OVER (ORDER BY '
               || lv_sort_column_name
               || ' '
               || lv_sort_column_by
               || ' ) AS rnum  FROM RC_INCLUDE_PID_LIST fd where (0 = 0  ';
         ELSE
            v_main_query :=
                  v_main_query
               || ' ROWNUM rnum
                        FROM  RC_INCLUDE_PID_LIST fd where (0 = 0  ';
         END IF;
   
         CASE
            WHEN lv_filter_column_name = 'QUANTITY'
            THEN
               lv_filter_column_name := 'DEMAND_QUANTITY';
            WHEN lv_filter_column_name = 'INVENTORY_TYPE'
            THEN
               lv_filter_column_name := 'INV_FLAG';
            ELSE
               lv_filter_column_name := lv_filter_column_name;
         END CASE;
   
         IF i_filter_list IS NOT EMPTY
         THEN
            get_in_condition_for_query (i_filter_list, lv_in_query);
   
            v_main_query := v_main_query || lv_in_query;
         END IF;
   
   
         -- For Column Level Filtering based on the user input
         /*IF lv_filter_column_name IS NOT NULL
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
   
   
   
         IF i_filter_list IS NOT EMPTY
         THEN
            FOR IDX IN 1 .. i_filter_list.COUNT ()
            LOOP
               IF     (i_filter_list (idx).COL_NAME IS NOT NULL)
                  AND (i_filter_list (idx).COL_NAME NOT LIKE ' ')
               THEN
                  lv_filter_column_name :=
                     UPPER (TO_CHAR (TRIM (i_filter_list (idx).COL_NAME)));
   
                   CASE WHEN lv_filter_column_name='QUANTITY'
                   THEN
                   lv_filter_column_name:='DEMAND_QUANTITY';
                   WHEN  lv_filter_column_name='INVENTORY_TYPE'
                   THEN
                   lv_filter_column_name:='INV_FLAG';
                   ELSE
                   lv_filter_column_name:=lv_filter_column_name;
                   END CASE;
   
                     v_main_query :=
                        v_main_query
                     || ' AND (UPPER ('
                     || lv_filter_column_name
                     || ') IN (';
   
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
                             v_main_query :=
                                    v_main_query
                                 || ''''
                                 || lv_filter_value
                                 || '''';
                              v_count_query :=
                                    v_count_query
                                 || ''''
                                 || lv_filter_value
                                 || '''';
                           ELSE
                               v_main_query  :=
                                    v_main_query
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
   
                  v_main_query := v_main_query || ')'|| lv_null_query || ')';
                  v_count_query := v_count_query || ')'|| lv_null_query || ')';
                  lv_null_query:=' ';
               END IF;
            END LOOP;
         -- v_count_query := v_count_query || '))';
         --v_main_query := v_main_query || '))';
         END IF;*/
   
   
   
         -- For Sorting based on the user selection
         IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
         THEN
            -- For getting the limited set of data based on the min and max values
   
            CASE
               WHEN lv_sort_column_name = 'QUANTITY'
               THEN
                  lv_sort_column_name := 'DEMAND_QUANTITY';
               WHEN lv_sort_column_name = 'INVENTORY_TYPE'
               THEN
                  lv_sort_column_name := 'INV_FLAG';
               ELSE
                  lv_sort_column_name := lv_sort_column_name;
            END CASE;
   
            v_main_query :=
                  v_main_query
               || ' AND 1 = 1) ) WHERE rnum >'
               || TO_CHAR (lv_min_row)
               || 'AND rnum <='
               || TO_CHAR (lv_max_row);
   
   
   
            v_main_query :=
                  v_main_query
               || ' ORDER BY '
               || lv_sort_column_name
               || ' '
               || lv_sort_column_by
               || '))';
         ELSE
            -- For getting the limited set of data based on the min and max values
            v_main_query :=
                  v_main_query
               || ' AND 1 = 1) AND ROWNUM <= '
               || TO_CHAR (lv_max_row)
               || ') WHERE rnum >'
               || TO_CHAR (lv_min_row);
   
            v_main_query := v_main_query || ' ORDER BY PRODUCT_ID))';
         END IF;
   
   
   
         --  DBMS_OUTPUT.put_line (v_main_query);
   
   
   
         BEGIN
            EXECUTE IMMEDIATE v_main_query BULK COLLECT INTO o_include_list;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               o_include_list := rc_inclde_pid_list ();
         END;
      --o_include_list := lv_include_list;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            o_include_list := NULL;
            crpadm.rc_global_error_logging (
               'NO DATA FOUND',
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
               NULL,
               'RC_GET_INCLUDE_PID',
               'PROCEDURE',
               NULL,
               'Y');
         WHEN OTHERS
         THEN
            o_include_list := NULL;
            crpadm.rc_global_error_logging (
               'OTHERS',
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
               NULL,
               'RC_GET_INCLUDE_PID',
               'PROCEDURE',
               NULL,
               'Y');
      END;
   
      PROCEDURE rc_get_exclude_pid_filter (
         o_exclude_list            OUT rc_exclde_pid_list,
         i_min_row              IN     NUMBER,
         i_max_row              IN     NUMBER,
         i_filter_column_name   IN     VARCHAR2,
         i_filter_user_input    IN     VARCHAR2,
         i_sort_column_name     IN     VARCHAR2,
         i_sort_column_by       IN     VARCHAR2,
         i_filter_list          IN     rc_new_filter_obj_list)
      IS
         lv_exclude_list         rc_exclde_pid_list;
   
         v_query                 CLOB;                        --VARCHAR2 (32767);
         v_main_query            CLOB;                        --VARCHAR2 (32767);
         lv_in_query             CLOB;
         lv_max_row              NUMBER;
         lv_min_row              NUMBER;
         lv_total_row_count      NUMBER;
         lv_filter_column_name   VARCHAR2 (100);
         lv_filter_user_input    VARCHAR2 (100);
         lv_sort_column_name     VARCHAR2 (100);
         lv_sort_column_by       VARCHAR2 (100);
         lv_filter_value         VARCHAR2 (1000);
         v_count_query           VARCHAR2 (32767) DEFAULT NULL;
         lv_filter_data_list     rc_filter_data_obj_list;
         lv_null_query           VARCHAR2 (32767);
      BEGIN
         lv_exclude_list := rc_exclde_pid_list ();
         o_exclude_list := rc_exclde_pid_list ();
         lv_max_row := i_max_row;
         lv_min_row := i_min_row;
         lv_filter_column_name := UPPER (TRIM (i_filter_column_name));
         lv_filter_user_input := UPPER (TRIM (i_filter_user_input));
         lv_sort_column_name := UPPER (TRIM (i_sort_column_name));
         lv_sort_column_by := UPPER (TRIM (i_sort_column_by));
   
         --      lv_exclude_list := i_exclude_list;
   
         /*SELECT RC_EXCLUDE_PID_OBJ (PRODUCT_ID,
                                    EOS_DATE,
                                    EOM_DATE,
                                    EXCLUSION_REASON)
           BULK COLLECT INTO lv_exclude_list
           FROM (SELECT *
                   FROM (SELECT fd.*, ROWNUM rnum
                           FROM (  SELECT *
                                     FROM RC_EXCLUDE_PID_LIST
                                 ORDER BY PRODUCT_ID) fd
                          WHERE ROWNUM <= i_max_row)
                  WHERE rnum > i_min_row);
   
         o_exclude_list := lv_exclude_list;*/
         v_main_query :=
            'SELECT RC_EXCLUDE_PID_OBJ (product_id, eos_date, eom_date, exclusion_reason) from (
               SELECT product_id, eos_date, eom_date, exclusion_reason
                   FROM ( SELECT fd.*,
                                     ';
   
   
         IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
         THEN
            v_main_query :=
                  v_main_query
               || 'ROW_NUMBER()  OVER (ORDER BY '
               || lv_sort_column_name
               || ' '
               || lv_sort_column_by
               || ' ) AS rnum  FROM RC_EXCLUDE_PID_LIST fd where (0 = 0  ';
         ELSE
            v_main_query :=
                  v_main_query
               || ' ROWNUM rnum
                        FROM  RC_EXCLUDE_PID_LIST fd where (0 = 0  ';
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
   
         IF i_filter_list IS NOT EMPTY
         THEN
            get_in_condition_for_query (i_filter_list, lv_in_query);
   
            v_main_query := v_main_query || lv_in_query;
         END IF;
   
         -- For Column Level Filter with user selected checkboxes
   
         /* IF i_filter_list IS NOT EMPTY
          THEN
             FOR IDX IN 1 .. i_filter_list.COUNT ()
             LOOP
                IF     (i_filter_list (idx).COL_NAME IS NOT NULL)
                   AND (i_filter_list (idx).COL_NAME NOT LIKE ' ')
                THEN
                   lv_filter_column_name :=
                      UPPER (TO_CHAR (TRIM (i_filter_list (idx).COL_NAME)));
   
   
   
                      v_main_query :=
                         v_main_query
                      || ' AND  ( UPPER ('
                      || lv_filter_column_name
                      || ') IN (';
   
                   v_count_query :=
                         v_count_query
                      || ' AND  ( UPPER ('
                      || lv_filter_column_name
                      || ') IN (';
   
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
                                     v_main_query
                                  || ''''
                                  || lv_filter_value
                                  || '''';
                               v_count_query :=
                                     v_count_query
                                  || ''''
                                  || lv_filter_value
                                  || '''';
                            ELSE
                                v_main_query  :=
                                     v_main_query
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
   
                   v_main_query := v_main_query || ')'|| lv_null_query || ')';
                   v_count_query := v_count_query || ')'|| lv_null_query || ')';
                   lv_null_query:=' ';
   
                END IF;
             END LOOP;
          -- v_count_query := v_count_query || '))';
          --v_main_query := v_main_query || '))';
          END IF;*/
   
         -- For Sorting based on the user selection
         IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
         THEN
            -- For getting the limited set of data based on the min and max values
            v_main_query :=
                  v_main_query
               || ' AND 1 = 1) ) WHERE rnum >'
               || TO_CHAR (lv_min_row)
               || 'AND rnum <='
               || TO_CHAR (lv_max_row);
   
   
   
            v_main_query :=
                  v_main_query
               || ' ORDER BY '
               || lv_sort_column_name
               || ' '
               || lv_sort_column_by
               || ')';
         ELSE
            -- For getting the limited set of data based on the min and max values
   
            v_main_query :=
                  v_main_query
               || ' AND 1 = 1) AND ROWNUM <= '
               || TO_CHAR (lv_max_row)
               || ') WHERE rnum >'
               || TO_CHAR (lv_min_row);
   
            v_main_query := v_main_query || ' ORDER BY PRODUCT_ID)';
         END IF;
   
   
         BEGIN
            EXECUTE IMMEDIATE v_main_query BULK COLLECT INTO o_exclude_list;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               o_exclude_list := rc_exclde_pid_list ();
               crpadm.rc_global_error_logging (
                  'OTHERS',
                     SUBSTR (SQLERRM, 1, 200)
                  || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
                  NULL,
                  'RC_GET_EXCLUDE_PID',
                  'PROCEDURE',
                  NULL,
                  'Y');
            WHEN OTHERS
            THEN
               crpadm.rc_global_error_logging (
                  'OTHERS',
                     SUBSTR (SQLERRM, 1, 200)
                  || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
                  NULL,
                  'RC_GET_EXCLUDE_PID',
                  'PROCEDURE',
                  NULL,
                  'Y');
         END;
      --o_exclude_list := lv_exclude_list;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            o_exclude_list := rc_exclde_pid_list ();
            crpadm.rc_global_error_logging (
               'NO DATA FOUND',
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
               NULL,
               'RC_GET_EXCLUDE_PID',
               'PROCEDURE',
               NULL,
               'Y');
         WHEN OTHERS
         THEN
            o_exclude_list := NULL;
            crpadm.rc_global_error_logging (
               'OTHERS',
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
               NULL,
               'RC_GET_EXCLUDE_PID',
               'PROCEDURE',
               NULL,
               'Y');
      END;


   PROCEDURE get_in_condition_for_query (
      i_filter_list       rc_new_filter_obj_list,
      i_in_query      OUT CLOB)
   IS
      lv_in_query             CLOB;
      lv_null_query           VARCHAR2 (32767);
      lv_count                NUMBER;
      lv_filter_data_list     rc_filter_data_obj_list;
      lv_filter_column_name   VARCHAR2 (100);
      lv_filter_value         VARCHAR2 (4000);
      lv_column_data_type     VARCHAR2 (25);
      lv_table_name           VARCHAR2 (50);
   BEGIN
      lv_count := 1;

      IF i_filter_list IS NOT EMPTY
      THEN
         FOR idx IN 1 .. i_filter_list.COUNT ()
         LOOP
            IF     (i_filter_list (idx).col_name IS NOT NULL)
               AND (i_filter_list (idx).col_name NOT LIKE ' ')
            THEN
               lv_filter_column_name :=
                  UPPER (TO_CHAR (TRIM (i_filter_list (idx).col_name)));

               CASE
                  WHEN lv_filter_column_name = 'QUANTITY'
                  THEN
                     lv_filter_column_name := 'DEMAND_QUANTITY';
                  WHEN lv_filter_column_name = 'INVENTORY_TYPE'
                  THEN
                     lv_filter_column_name := 'INV_FLAG';
                  WHEN lv_filter_column_name = 'CONDITION_OF_INV_NEEDED'
                  THEN
                     lv_filter_column_name := 'CONDITION_OF_INV';
                  WHEN lv_filter_column_name = 'SHIPPED_UNITS_12M'
                  THEN
                     lv_filter_column_name := 'CUR_SALES_UNITS';
                  WHEN lv_filter_column_name = 'MOS_MONTH'
                  THEN
                     lv_filter_column_name := 'MOS_BANDS';
                  WHEN lv_filter_column_name = 'NETTABLE_DGI'
                  THEN
                     lv_filter_column_name := 'NETTABLE_DGI_QTY';
                  WHEN lv_filter_column_name = 'NETTABLE_FGI'
                  THEN
                     lv_filter_column_name := 'NETTABLE_FGI_QTY';
                  WHEN lv_filter_column_name = 'STANDARD_COST'
                  THEN
                     lv_filter_column_name := 'UNIT_STD_COST_USD';
                  WHEN lv_filter_column_name = 'TOTAL_DEMAND_QTY'
                  THEN
                     lv_filter_column_name := 'DEMAND_MAX';
                  WHEN lv_filter_column_name = 'OLD_DEMAND'
                  THEN
                     lv_filter_column_name := 'OLD_DEMAND';
                  WHEN lv_filter_column_name = 'END_OF_LAST_SUPPORT_DATE'
                  THEN
                     lv_filter_column_name := 'EOS';
                  WHEN lv_filter_column_name = 'VR_AVL_TO_ALLOCATE_QTY'
                  THEN
                     lv_filter_column_name := 'VR_AVAIL_QTY';
                  ELSE
                     lv_filter_column_name := lv_filter_column_name;
               END CASE;

               lv_table_name := 'RC_FIN_DEMAND_LIST';

               SELECT DISTINCT DATA_TYPE
                 INTO lv_column_data_type
                 FROM ALL_TAB_COLUMNS
                WHERE     COLUMN_NAME = lv_filter_column_name
                      AND TABLE_NAME LIKE '%' || lv_table_name || '%';

               lv_in_query := lv_in_query || ' AND ';


               lv_filter_data_list := i_filter_list (idx).col_value;

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

                  IF lv_filter_data_list IS NOT EMPTY
                  THEN
                     IF     (lv_filter_data_list (idx).filter_data
                                IS NOT NULL)
                        AND (lv_filter_data_list (idx).filter_data NOT LIKE
                                ' ')
                     THEN
                        lv_filter_value :=
                           UPPER (
                              TO_CHAR (
                                 TRIM (lv_filter_data_list (idx).filter_data)));

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
         crpadm.rc_global_error_logging (
            'NO DATA FOUND',
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
            NULL,
            'GET_IN_CONDITION_FOR_QUERY',
            'PROCEDURE',
            NULL,
            'Y');
      WHEN OTHERS
      THEN
         crpadm.rc_global_error_logging (
            'OTHERS',
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.format_error_backtrace, 12),
            NULL,
            'GET_IN_CONDITION_FOR_QUERY',
            'PROCEDURE',
            NULL,
            'Y');
   END;
END RC_DEMAND_AUTOMATION;
/