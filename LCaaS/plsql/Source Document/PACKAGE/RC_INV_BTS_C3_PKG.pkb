CREATE OR REPLACE PACKAGE BODY CRPADM./*AppDB: 1041617*/                         "RC_INV_BTS_C3_PKG" 
IS
   /*===================================================================================================+
    Object Name    : RC_INV_BTS_C3_PKG
    Module         : C3 and FGI Interface 2 Hourly Refresh SSOT
    Description    : C3 AND FGI AUTOMATION PROCESS 2 Hourly Refresh SSOT
    Revision History:
    -----------------
    Date        Updated By       Bug/Case#   Rev   Comments
   ========= ================ =========== ==== ======================================================
   8 Apr 2013  radwived                           1.0     First Draft
 14 Jun 2013  Seshadri                            2.0     WS Enablement Changes, Common DGI Consolidation and Sreen Only Part Changes
 02 Sep 2013 ruchhabr                            3.0     Procedure added to refresh the table RSCM_TMP_ML_C3_INV_TBL used by 1CT,WCT
 28 Sep 2018 sridvasu                            3.1     Added new procedure RC_INV_C3_QTY_YIELD_CALC to calculate qty after yield 
 23 Oct 2018 sridvasu                            3.2     Updating with 100% yield for IS_SCRAP = FG locations
 09-Nov-2018 sridvasu                            3.3     Added on 09-Nov-2018 for Index issue
 26-Nov-2018 sridvasu                            3.4     Added Nettable Flag column to C3, BTS C3 and BTS C3 MV         
 12-Dec-2018 sridvasu                            3.5     Added rf yield %age and ws yield %age columns to C3, BTS C3 and BTS C3 MV and updating yield %age in c3 table
 09-Jan-2019 sridvasu                            3.6     Added code to avoid negative qty on hand/qty in transit
 29-Jan-2019 sridvasu                            3.7     Added update statement to update inventory item id in BTS C3 table
 11-Feb-2019 sridvasu                            3.8     Apply global screen yield for Z05,Z29 if local screen yield is not setup for Z05 or Z29
 27-FEB-2019 csirigir                            3.9     Modified the code to get inventory item id from RMK_SSOT_INVENTORY
 05-Mar-2019 sridvasu                            4.0     Stopped referring RMK_INV_SITE_MAPPINGS table to get Region and added RC_PRODUCT_CONFIG table  
   ==============================================================================================*/

   PROCEDURE BTS_MAIN
   IS
   BEGIN
    
    RC_INV_C3_QTY_YIELD_CALC;
    
    REFRESH_BTS_C3_INV_DATA;
    
    REFRESH_BTS_C3_INV_MV;
   END;        

   PROCEDURE REFRESH_BTS_C3_INV_DATA
   IS
      TYPE T_RAW_DATA_OBJECT IS RECORD
      (
         INVENTORY_ITEM_ID         NUMBER, 
         PART_NUMBER               VARCHAR2 (100 BYTE),
         PRODUCT_FAMILY            VARCHAR2 (100 BYTE),
         SITE                      VARCHAR2 (500 BYTE),
         LOCATION                  VARCHAR2 (100 BYTE),
         QTY_ON_HAND               NUMBER,
         QTY_IN_TRANSIT            NUMBER,
         QTY_RESERVED              NUMBER,
         PART_STATUS               VARCHAR2 (100 BYTE),
         ADDITIONAL_RESERVATIONS   NUMBER,
         TOTAL_RESERVATIONS        NUMBER,
         ROHS_PART                 VARCHAR2 (50 BYTE),
         VISIBLE                   VARCHAR2 (50 BYTE),
         --PRODUCT_NAME_STRIPPED     VARCHAR2 (250 BYTE),
         --REPAIR_FLAG               VARCHAR2 (25 BYTE),
         --PRODUCT_CATEGORY          VARCHAR2 (120 BYTE),
         --SUB_GROUP                 VARCHAR2 (120 BYTE),
         --PRODUCT_SUB_CATEGORY      VARCHAR2 (150 BYTE),
         --QTY_10_DAYS               NUMBER,
         --QTY_30_DAYS               NUMBER,
         program_type              VARCHAR2 (25),
         RF_REFURB_METHOD           VARCHAR2(50),
         WS_REFURB_METHOD           VARCHAR2(50),
         RF_QTY_AFTER_YIELD         NUMBER,
         WS_QTY_AFTER_YIELD         NUMBER,
         NETTABLE_FLAG          VARCHAR2(1), -->> Added on 26-Nov-2018 by sridvasu
		 RF_YIELD_PERCENT			NUMBER,-->> Added on 12-Dec-2018 by sridvasu
		 WS_YIELD_PERCENT			NUMBER, -->> Added on 12-Dec-2018 by sridvasu
		 YIELDED_RF_QTY_IN_TRANSIT  NUMBER, -->> Added on 12-Dec-2018 by sridvasu
		 YIELDED_WS_QTY_IN_TRANSIT  NUMBER  -->> Added on 12-Dec-2018 by sridvasu		 
--         REGION                    VARCHAR2(100)
      );

      TYPE T_RAW_DATA_LIST IS TABLE OF T_RAW_DATA_OBJECT;

      v_Raw_Data_List            T_RAW_DATA_LIST;
      lv_inventory_item_id       NUMBER;
      lv_Product_Name            VARCHAR2 (256);
      --lv_Product_Name_Stripped   VARCHAR2 (256);
      --lv_Repair_Flag             VARCHAR2 (25) := 'None';
      --lv_Repair_Flag_EM          NUMBER;
      --lv_Repair_Flag_NAM         NUMBER;
      --lv_Category_Count          NUMBER;
      --lv_Product_Category        VARCHAR2 (120);
      --lv_Sub_Group               VARCHAR2 (120);
      --lv_Product_Sub_Category    VARCHAR2 (150);
      --lv_Partner_Commit_FG       NUMBER;
      lv_qty_on_hand             NUMBER;
      lv_total_reservations      NUMBER;
      lv_location                VARCHAR2 (100);
      ERROR_MSG                  VARCHAR2(10000);
      g_error_msg                     VARCHAR2 (2000) := NULL;

   BEGIN
      BEGIN
         
        INSERT INTO RC_CRON_HISTORY_LOG (CHL_ID,
                                       CHL_STATUS,
                                       CHL_START_TIMESTAMP,
                                       CHL_END_TIMESTAMP,
                                       CHL_CRON_NAME,
                                       CHL_COMMENTS,
                                       CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'START',
                   SYSDATE,
                   SYSDATE,
                   'REFRESH_BTS_C3_INV_DATA',
                   NULL,
                   'CRPADM');         

         -- fetch entire data into local record type
         SELECT INVENTORY_ITEM_ID,
                PART_ID,
                PRODUCT_FAMILY,
                SITE,
                LOCATION,
                QTY_ON_HAND,
                QTY_IN_TRANSIT,
                QTY_RESERVED,
                PART_STATUS,
                ADDITIONAL_RESERVATIONS,
                TOTAL_RESERVATIONS,
                ROHS_PART,
                VISIBLE,
                --PRODUCT_NAME_STRIPPED,
                --REPAIR_FLAG,
                --PRODUCT_CATEGORY,
                --SUB_GROUP,
                --PRODUCT_SUB_CATEGORY,
                --QTY_10_DAYS,
                --QTY_30_DAYS,
                program_type,
                RF_REFURB_METHOD,
                WS_REFURB_METHOD,
                RF_QTY_AFTER_YIELD,
                WS_QTY_AFTER_YIELD,
                NETTABLE_FLAG,      -->> Added on 26-Nov-2018 by sridvasu  
				RF_YIELD_PERCENT,		-->> Added on 12-Dec-2018 by sridvasu  
				WS_YIELD_PERCENT,		-->> Added on 12-Dec-2018 by sridvasu 
				YIELDED_RF_QTY_IN_TRANSIT, -->> Added on 12-Dec-2018 by sridvasu
				YIELDED_WS_QTY_IN_TRANSIT  -->> Added on 12-Dec-2018 by sridvasu 		
--                REGION
           BULK COLLECT INTO v_Raw_Data_List
           FROM (SELECT DISTINCT INVENTORY_ITEM_ID,
                                 PART_ID,
                                 PRD_FAMILY AS PRODUCT_FAMILY,
                                 PLACE_ID AS SITE,
                                 LOCATION,
                                 TO_NUMBER (QTY_ON_HAND_USEBL) QTY_ON_HAND,
                                 TO_NUMBER (QTY_IN_TRANS_USEBL) QTY_IN_TRANSIT,
                                 0 AS QTY_RESERVED,
                                 NULL AS PART_STATUS,
                                 0 AS ADDITIONAL_RESERVATIONS,
                                 0 AS TOTAL_RESERVATIONS,
                                 NULL AS ROHS_PART,
                                 NULL AS VISIBLE,
                                 --PRODUCT_NAME_STRIPPED,
                                 --(SELECT PC.CONFIG_NAME
                                 --  FROM CRPADM.RC_PRODUCT_CONFIG PC
                                 --       WHERE PC.CONFIG_TYPE = 'REFRESH_METHOD' 
                                 --             AND PC.CONFIG_ID = RMKTGADM.RC_INV_DELTA_LOAD_RF.RC_INV_GET_REFURB_METHOD (PM.REFRESH_INVENTORY_ITEM_ID)) REPAIR_FLAG,
                                 --NULL PRODUCT_CATEGORY,
                                 --NULL SUB_GROUP,
                                 --NULL PRODUCT_SUB_CATEGORY,
                                 --NULL QTY_10_DAYS,
                                 --NULL QTY_30_DAYS,
                                 NULL program_type,
                                 RF_REFURB_METHOD,
                                 WS_REFURB_METHOD,
                                 RF_QTY_AFTER_YIELD,
                                 WS_QTY_AFTER_YIELD,
                                 NETTABLE_FLAG,          -->> Added on 26-Nov-2018 by sridvasu   
								 RF_YIELD_PERCENT,		-->> Added on 12-Dec-2018 by sridvasu  
								 WS_YIELD_PERCENT,		-->> Added on 12-Dec-2018 by sridvasu
                                 YIELDED_RF_QTY_IN_TRANSIT, -->> Added on 12-Dec-2018 by sridvasu
                                 YIELDED_WS_QTY_IN_TRANSIT  -->> Added on 12-Dec-2018 by sridvasu 									  								 
--                                 MP.REGION REGION
                   FROM CRPADM.RC_INV_C3_TBL C3 
                   --INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR SIL ON ((C3.LOCATION = SIL.SUB_INVENTORY_LOCATION))                   
                   --LEFT OUTER JOIN CRPADM.RC_PRODUCT_MASTER PM ON  (C3.INVENTORY_ITEM_ID = PM.REFRESH_INVENTORY_ITEM_ID 
                    --                                                OR C3.INVENTORY_ITEM_ID = PM.COMMON_INVENTORY_ITEM_ID 
                    --                                                OR C3.INVENTORY_ITEM_ID = PM.XREF_INVENTORY_ITEM_ID
                    --                                                AND SIL.PROGRAM_TYPE = PM.PROGRAM_TYPE )
                 UNION ALL
                         SELECT --NULL INVENTORY_ITEM_ID,     --Commented by csirigir on 27-FEB-2019
						        REFRESH_INVENTORY_ITEM_ID,    --Added by csirigir on 27-FEB-2019
                                PART_NUMBER,
                                PRODUCT_FAMILY,
                                NVL (ORIGNAL_SITE_NAME, SITE),
                                LOCATION,
                                TO_NUMBER (REPLACE (QTY_ON_HAND, ',', '')),
                                TO_NUMBER (REPLACE (QTY_IN_TRANSIT, ',', '')),
                                TO_NUMBER (REPLACE (QTY_RESERVED, ',', '')),
                                PART_STATUS,
                                TO_NUMBER (
                                   REPLACE (ADDITIONAL_RESERVATIONS, ',', '')),
                                (  TO_NUMBER (REPLACE (QTY_RESERVED, ',', ''))
                                 + TO_NUMBER (
                                      REPLACE (ADDITIONAL_RESERVATIONS, ',', '')))
                                   AS TOTAL_RESERVATIONS,
                                ROHS_PART,
                                VISIBLE,
                                --PRODUCT_NAME_STRIPPED,
                                --NULL REPAIR_FLAG,
                                --NULL PRODUCT_CATEGORY,
                                --NULL SUB_GROUP,
                                --NULL PRODUCT_SUB_CATEGORY,
                                --NULL QTY_10_DAYS,
                                --NULL QTY_30_DAYS,
                                RMK.program_type,
                                NULL RF_REFURB_METHOD,
                                NULL WS_REFURB_METHOD,
                                NULL RF_QTY_AFTER_YIELD,
                                NULL WS_QTY_AFTER_YIELD,
                                LOC.NETTABLE_FLAG,         -->> Added on 26-Nov-2018 by sridvasu  
								NULL RF_YIELD_PERCENT,		-->> Added on 12-Dec-2018 by sridvasu  
								NULL WS_YIELD_PERCENT,		-->> Added on 12-Dec-2018 by sridvasu 	
                                NULL YIELDED_RF_QTY_IN_TRANSIT, -->> Added on 12-Dec-2018 by sridvasu
                                NULL YIELDED_WS_QTY_IN_TRANSIT  -->> Added on 12-Dec-2018 by sridvasu 															
--                                NULL REGION
                   FROM RMKTGADM.RMK_SSOT_INVENTORY  RMK
                   LEFT OUTER JOIN CRPADM.RC_SUB_INV_LOC_MSTR LOC ON (RMK.LOCATION = LOC.SUB_INVENTORY_LOCATION) ); -->> Added on 26-Nov-2018 by sridvasu

         -- Iterate over the results and insert them into the table RC_INV_BTS_C3_TBL
--         FOR idx IN 1 .. v_Raw_Data_List.COUNT ()
--         LOOP
--            lv_inventory_item_id := v_Raw_Data_List (idx).INVENTORY_ITEM_ID;
--            lv_Product_Name := v_Raw_Data_List (idx).PART_NUMBER;
--            -- lv_Product_Name_Stripped := v_Raw_Data_List (idx).PRODUCT_NAME_STRIPPED;
--            lv_location := v_Raw_Data_List (idx).LOCATION;
--            lv_qty_on_hand := v_Raw_Data_List (idx).QTY_ON_HAND;
--            lv_total_reservations := v_Raw_Data_List (idx).TOTAL_RESERVATIONS;

            -- logic for categories,sub_categories and sub_group
--            BEGIN
--               SELECT COUNT (*)
--                 INTO lv_Category_Count
--                 FROM oct_part_category_family
--                WHERE PART_NUMBER LIKE lv_Product_Name || '%';
--
--               IF (lv_Category_Count = 1) --Changes done as part of version 5.0
--               THEN
--                  SELECT CATEGORY, SUB_CATEGORY
--                    INTO lv_Product_Category, lv_Product_Sub_Category
--                    FROM oct_part_category_family
--                   WHERE PART_NUMBER LIKE lv_Product_Name || '%';
--               ELSE
--                  SELECT DISTINCT CATEGORY
--                    INTO lv_Product_Category
--                    FROM oct_part_category_family
--                   WHERE PART_NUMBER LIKE lv_Product_Name || '%';
--
--                  SELECT LISTAGG (SUB_CATEGORY, ', ')
--                            WITHIN GROUP (ORDER BY PART_NUMBER DESC)
--                            "SUB_CATEGORY" --Changes done as part of version 5.0
--                    INTO lv_Product_Sub_Category
--                    FROM oct_part_category_family
--                   WHERE PART_NUMBER LIKE lv_Product_Name || '%';
--               END IF;
--
--               SELECT RPR_PRODUCT_SUBGROUP
--                 INTO lv_Sub_Group
--                 FROM RMKTGADM.RMK_PRODUCT
--                WHERE RPR_PRODUCT_ID = lv_Product_Name;
--            EXCEPTION
--               WHEN NO_DATA_FOUND
--               THEN
--                  lv_Product_Category := '';
--                  lv_Sub_Group := '';
--                  lv_Product_Sub_Category := '';
--               WHEN OTHERS
--               THEN
--                  lv_Product_Category := '';
--                  lv_Sub_Group := '';
--                  lv_Product_Sub_Category := '';
--            END;

            -- logic for Repair Flag
--            BEGIN
--               SELECT DISTINCT (REPAIR_STATUS_ID)
--                 INTO lv_Repair_Flag_EM
--                 FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW
--                WHERE     product_name_stripped = lv_Product_Name_Stripped
--                      AND REGION_NAME = 'EMEA';
--
--               SELECT DISTINCT (REPAIR_STATUS_ID)
--                 INTO lv_Repair_Flag_NAM
--                 FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW
--                WHERE     product_name_stripped = lv_Product_Name_Stripped
--                      AND REGION_NAME = 'NAM';
--            EXCEPTION
--               WHEN NO_DATA_FOUND
--               THEN
--                  lv_Repair_Flag := 'None';
--               WHEN OTHERS
--               THEN
--                  lv_Repair_Flag := 'None';
--            END;

--            lv_Repair_Flag :=
--               RMKTGADM.RC_INV_DELTA_LOAD_RF.RC_INV_GET_REFURB_METHOD (lv_inventory_item_id);

--                SELECT PC.CONFIG_NAME
--                    INTO lv_Repair_Flag
--                      FROM CRPADM.RC_PRODUCT_CONFIG PC
--                    WHERE PC.CONFIG_TYPE = 'REFRESH_METHOD' 
--                           AND PC.CONFIG_ID = RMKTGADM.RC_INV_DELTA_LOAD_RF.RC_INV_GET_REFURB_METHOD (lv_inventory_item_id);  

-->> 10 Days
--
--            IF (   ( (lv_Repair_Flag <> 'RF Screen') AND (lv_location = 'FG'))
--                OR (    (lv_Repair_Flag = 'RF Screen')
--                    AND (lv_location IN ('RF_NEW',
--                                         'RF_NRHS',
--                                         'RF_WIP',
--                                         'FG'))))
--            THEN
--               v_Raw_Data_List (idx).QTY_10_DAYS :=  lv_qty_on_hand + lv_total_reservations; -- for 10 and 30 days, in transient quantities are not considered


-->> 30 Days                  

--               SELECT NVL (SUM (partner_commit_week), 0)
--                 INTO lv_Partner_Commit_FG
--                 FROM VAVNI_CISCO_RSCM_BP.vv_bp_schedule_daily_qtr_tbl T,
--                      VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_CITY
--                WHERE     1 = 1
--                      AND partner_commit_week > 0
--                      AND t.product_map_id = pm_city.product_map_id
--                      AND plan_date >=
--                             VAVNI_CISCO_RSCM_KPI.GET_WEEK_END_DATE (SYSDATE)
--                      AND plan_date <=
--                             VAVNI_CISCO_RSCM_KPI.GET_WEEK_END_DATE (
--                                SYSDATE + 21)
--                      AND PM_CITY.product_name_stripped =
--                             lv_Product_Name_Stripped;
--
--               v_Raw_Data_List (idx).QTY_30_DAYS :=
--                    lv_qty_on_hand
--                  + lv_Partner_Commit_FG
--                  + lv_total_reservations;
--            ELSE
--               v_Raw_Data_List (idx).QTY_10_DAYS := 0;
----               v_Raw_Data_List (idx).QTY_30_DAYS := 0;
--            END IF;
--
--            v_Raw_Data_List (idx).PRODUCT_CATEGORY := lv_Product_Category;
--            v_Raw_Data_List (idx).SUB_GROUP := lv_Sub_Group;
----            v_Raw_Data_List (idx).REPAIR_FLAG := lv_Repair_Flag;
--            v_Raw_Data_List (idx).PRODUCT_SUB_CATEGORY :=
--               lv_Product_Sub_Category;
--         END LOOP;
        
             

         --         EXECUTE IMMEDIATE 'TRUNCATE TABLE RC_INV_BTS_C3_TBL';
         EXECUTE IMMEDIATE 'DELETE FROM RC_INV_BTS_C3_TBL';

         FORALL idx IN v_Raw_Data_List.FIRST .. v_Raw_Data_List.LAST
            INSERT INTO RC_INV_BTS_C3_TBL (PART_NUMBER,
                                            PRODUCT_FAMILY,
                                            SITE,
                                            LOCATION,
                                            QTY_ON_HAND,
                                            QTY_IN_TRANSIT,
                                            QTY_RESERVED,
                                            PART_STATUS,
                                            ADDITIONAL_RESERVATIONS,
                                            TOTAL_RESERVATIONS,
                                            ROHS_PART,
                                            VISIBLE,
--                                            PRODUCT_NAME_STRIPPED,
                                            --REPAIR_FLAG,
                                            --PRODUCT_CATEGORY,
                                            --SUB_GROUP,
                                            --PRODUCT_SUB_CATEGORY,
                                            --QTY_10_DAYS,
                                            --QTY_30_DAYS,
                                            program_type,
                                            INVENTORY_ITEM_ID,
                                            RF_REFURB_METHOD,
                                            WS_REFURB_METHOD,
                                            RF_QTY_AFTER_YIELD,
                                            WS_QTY_AFTER_YIELD,
                                            NETTABLE_FLAG,   -->> Added on 26-Nov-2018 by sridvasu
											RF_YIELD_PERCENT,   -->> Added on 12-Dec-2018 by sridvasu  
											WS_YIELD_PERCENT,   -->> Added on 12-Dec-2018 by sridvasu
											YIELDED_RF_QTY_IN_TRANSIT,  -->> Added on 12-Dec-2018 by sridvasu
											YIELDED_WS_QTY_IN_TRANSIT ) -->> Added on 12-Dec-2018 by sridvasu  
--                                            REGION)
                 VALUES (v_Raw_Data_List (idx).PART_NUMBER,
                         v_Raw_Data_List (idx).PRODUCT_FAMILY,
                         v_Raw_Data_List (idx).SITE,
                         v_Raw_Data_List (idx).LOCATION,
                         v_Raw_Data_List (idx).QTY_ON_HAND,
                         v_Raw_Data_List (idx).QTY_IN_TRANSIT,
                         v_Raw_Data_List (idx).QTY_RESERVED,
                         v_Raw_Data_List (idx).PART_STATUS,
                         v_Raw_Data_List (idx).ADDITIONAL_RESERVATIONS,
                         v_Raw_Data_List (idx).TOTAL_RESERVATIONS,
                         v_Raw_Data_List (idx).ROHS_PART,
                         v_Raw_Data_List (idx).VISIBLE,
--                         v_Raw_Data_List (idx).PRODUCT_NAME_STRIPPED,
                         --v_Raw_Data_List (idx).REPAIR_FLAG,
                         --v_Raw_Data_List (idx).PRODUCT_CATEGORY,
                         --v_Raw_Data_List (idx).SUB_GROUP,
                         --v_Raw_Data_List (idx).PRODUCT_SUB_CATEGORY,
                         --v_Raw_Data_List (idx).QTY_10_DAYS,
                         --v_Raw_Data_List (idx).QTY_30_DAYS,
                         v_Raw_Data_List (idx).program_type,
                         v_Raw_Data_List (idx).INVENTORY_ITEM_ID,
                         v_Raw_Data_List (idx).RF_REFURB_METHOD,
                         v_Raw_Data_List (idx).WS_REFURB_METHOD,
                         v_Raw_Data_List (idx).RF_QTY_AFTER_YIELD,
                         v_Raw_Data_List (idx).WS_QTY_AFTER_YIELD,
                         v_Raw_Data_List (idx).NETTABLE_FLAG,                          -->> Added on 26-Nov-2018 by sridvasu
						 v_Raw_Data_List (idx).RF_YIELD_PERCENT,					   -->> Added on 12-Dec-2018 by sridvasu 
						 v_Raw_Data_List (idx).WS_YIELD_PERCENT,                       -->> Added on 12-Dec-2018 by sridvasu
						 v_Raw_Data_List (idx).YIELDED_RF_QTY_IN_TRANSIT,              -->> Added on 12-Dec-2018 by sridvasu
						 v_Raw_Data_List (idx).YIELDED_WS_QTY_IN_TRANSIT );			   -->> Added on 12-Dec-2018 by sridvasu
--                         v_Raw_Data_List (idx).REGION);

        
         COMMIT;
         
         IF v_Raw_Data_List.COUNT = 0 THEN
             RAISE NO_DATA_FOUND;                
         END IF;
         -- to update region column w.r.t. its site
         
/* Start Commented below code not to refer rmk site mappings table for Region on 05-MAR-2019 */         

--         UPDATE RC_INV_BTS_C3_TBL
--            SET REGION =
--                   (SELECT DISTINCT REGION
--                      FROM RMKTGADM.RMK_INV_SITE_MAPPINGS
--                     WHERE SITE = RC_INV_BTS_C3_TBL.SITE);

/* End Commented below code not to refer rmk site mappings table for Region on 05-MAR-2019 */

/* Start Added below code to get region from product config table on 05-MAR-2019 */

            UPDATE RC_INV_BTS_C3_TBL
            SET REGION =
                   (SELECT DISTINCT B.CONFIG_NAME
                        FROM RC_PRODUCT_REPAIR_PARTNER A, 
                        RC_PRODUCT_CONFIG B
                    WHERE B.CONFIG_ID = A.THEATER_ID
                        AND B.CONFIG_TYPE = 'THEATER'
                        AND A.ZCODE = SUBSTR(RC_INV_BTS_C3_TBL.SITE,1,3));
                        
/* End Added below code to get region from product config table on 05-MAR-2019 */                        
                     
/* Start Added update statement to update inventory item id in BTS C3 table on 29-Jan-2019 */                                               
                     
    /*     UPDATE rc_inv_bts_c3_tbl c3      --Commented by csirigir on 27-FEB-2019
            SET inventory_Item_id =
                   (SELECT refresh_inventory_item_id
                      FROM rc_product_master rpm
                     WHERE rpm.refresh_part_number = c3.part_number)
          WHERE inventory_item_id IS NULL;     */              

/* End Added update statement to update inventory item id in BTS C3 table on 29-Jan-2019 */
/* UPDATE qty_masked */ 
For I in (Select part_number,program_type,location,SITE,ROHS_PART,qty_masked from(
            Select C3TBL.PART_NUMBER,C3TBL.PROGRAM_TYPE,C3TBL.LOCATION,SITE,ROHS_PART,
            CASE WHEN SITE = 'Teleplan BTS' AND ROHS_PART ='YES' AND LRO_RHS_QUANTITY>0 THEN LRO_RHS_QUANTITY
                                                                                       WHEN SITE = 'Teleplan BTS' AND ROHS_PART ='NO' AND LRO_NRHS_QUANTITY >0 THEN LRO_NRHS_QUANTITY
                                                                                       WHEN SITE = 'Flex Venray' AND ROHS_PART ='YES' AND FVE_RHS_QUANTITY >0 THEN FVE_RHS_QUANTITY
                                                                                       END QTY_MASKED
            from crpadm.RC_INV_BTS_C3_TBL C3TBL
            LEFT OUTER JOIN RMKTGADM.RC_INV_STR_INV_MASK_MV MSK 
            ON (C3TBL.PART_NUMBER = MSK.PARTNUMBER 
                AND C3TBL.PROGRAM_TYPE='RETAIL' 
                AND C3TBL.LOCATION='FG')
                ) where QTY_MASKED IS NOT NULL)
                
      Loop
      
         Update RC_INV_BTS_C3_TBL BTC
         Set  qty_masked = i.qty_masked
         where BTC.part_number = i.part_number
         and BTC.program_type = i.program_type
         and BTC.LOCATION = i.LOCATION
         and BTC.SITE = i.SITE
         and BTC.ROHS_PART = i.ROHS_PART;
      
      End Loop;    

/*UPDATE qty_masked END */

         COMMIT;
        
          BEGIN
               --Calling History pkg to maintain the history
              RMKTGADM.RC_HISTORY_PKG.P_RC_INSERT_HIST('CRPADM.RC_INV_BTS_C3_TBL'); 
          EXCEPTION
            WHEN OTHERS THEN
               g_error_msg :=
               'Calling History '||SUBSTR (SQLERRM, 1, 200)|| SUBSTR (DBMS_UTILITY.format_error_backtrace, 12);      
         END;      
        -->> Inserting SUCCESS entry to Log table
        
           INSERT INTO RC_CRON_HISTORY_LOG (CHL_ID,
                                       CHL_STATUS,
                                       CHL_START_TIMESTAMP,
                                       CHL_END_TIMESTAMP,
                                       CHL_CRON_NAME,
                                       CHL_COMMENTS,
                                       CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'SUCCESS',
                   SYSDATE,
                   SYSDATE,
                   'REFRESH_BTS_C3_INV_DATA',
                   NULL,
                   'CRPADM');

        COMMIT;
      
      EXCEPTION                    
               

        WHEN NO_DATA_FOUND THEN
        
            INSERT INTO RC_CRON_HISTORY_LOG (CHL_ID,
                                          CHL_STATUS,
                                          CHL_START_TIMESTAMP,
                                          CHL_END_TIMESTAMP,
                                          CHL_CRON_NAME,
                                          CHL_COMMENTS,
                                          CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'EXCEPTION',
                      SYSDATE,
                      SYSDATE,
                      'RC_BTS_C3_DATA_REFRESH',
                      'NULL VALUES',
                      'CRPADM');
                      
              COMMIT;   
                                  
        WHEN OTHERS THEN
        
          ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
            
            INSERT INTO RC_CRON_HISTORY_LOG (CHL_ID,
                                          CHL_STATUS,
                                          CHL_START_TIMESTAMP,
                                          CHL_END_TIMESTAMP,
                                          CHL_CRON_NAME,
                                          CHL_COMMENTS,
                                          CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'EXCEPTION',
                      SYSDATE,
                      SYSDATE,
                      'RC_BTS_C3_DATA_REFRESH',
                      ERROR_MSG,
                      'CRPADM');
                      
              COMMIT;
              
              RAISE_APPLICATION_ERROR (-20000, SQLERRM);                
      END;      
   END;
PROCEDURE REFRESH_BTS_C3_INV_MV
IS
    
    ERROR_MSG                  VARCHAR2(10000);
    lv_status                       VARCHAR2(50); -->> Added on 09-Nov-2018 for Index issue
    
    BEGIN
      DBMS_SNAPSHOT.REFRESH(
        LIST                 => 'CRPADM.RC_INV_BTS_C3_MV'
       ,PUSH_DEFERRED_RPC    => TRUE
       ,REFRESH_AFTER_ERRORS => FALSE
       ,PURGE_OPTION         => 1
       ,PARALLELISM          => 0
       ,ATOMIC_REFRESH       => TRUE
       ,NESTED               => FALSE);

--    DBMS_MVIEW.REFRESH('CRPADM.RC_INV_BTS_C3_MV', '','', TRUE, FALSE, 0,0,0,FALSE, FALSE);
    
    /* Start Added on 09-Nov-2018 for Index issue */
SELECT status
  INTO lv_status
  FROM user_indexes a
 WHERE index_name = 'MV_PART_NUMBER_IDX';

INSERT INTO RC_INV_BTS_MV_INDEX  values (lv_status,
                                 'MV_PART_NUMBER_IDX status',
                                 SYSDATE);

COMMIT;    
    
--execute immediate 'alter index MV_PART_NUMBER_IDX rebuild';

/* End Added on 09-Nov-2018 for Index issue */

    EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            ROLLBACK;

            INSERT INTO RC_CRON_HISTORY_LOG (CHL_ID,
                                          CHL_STATUS,
                                          CHL_START_TIMESTAMP,
                                          CHL_END_TIMESTAMP,
                                          CHL_CRON_NAME,
                                          CHL_COMMENTS,
                                          CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'EXCEPTION',
                      SYSDATE,
                      SYSDATE,
                      'REFRESH_BTS_C3_INV_MV',
                      'NULL VALUES',
                      'CRPADM');
                      
              COMMIT;                      
               
         WHEN OTHERS
         THEN
            ROLLBACK;
            
            ERROR_MSG :=
                  SUBSTR (SQLERRM, 1, 200)
               || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

            INSERT INTO RC_CRON_HISTORY_LOG (CHL_ID,
                                          CHL_STATUS,
                                          CHL_START_TIMESTAMP,
                                          CHL_END_TIMESTAMP,
                                          CHL_CRON_NAME,
                                          CHL_COMMENTS,
                                          CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'EXCEPTION',
                      SYSDATE,
                      SYSDATE,
                      'REFRESH_BTS_C3_INV_MV',
                       ERROR_MSG,
                      'CRPADM');
                      
              COMMIT; 

    END;
    
/* Start Added new procedure RC_INV_C3_QTY_YIELD_CALC to calculate qty after yield on 28th Sep 2018 by sridvasu */    
    
PROCEDURE RC_INV_C3_QTY_YIELD_CALC
AS
   CURSOR C3_DATA
   IS
      SELECT * FROM RC_INV_C3_TBL;

   C3          C3_DATA%ROWTYPE;

   ERROR_MSG   VARCHAR2 (10000);
BEGIN
   -->> Inserting START entry to Log table

   INSERT INTO RC_CRON_HISTORY_LOG (CHL_ID,
                                    CHL_STATUS,
                                    CHL_START_TIMESTAMP,
                                    CHL_END_TIMESTAMP,
                                    CHL_CRON_NAME,
                                    CHL_COMMENTS,
                                    CHL_CREATED_BY)
        VALUES (SEQ_CHL_ID.NEXTVAL,
                'START',
                SYSDATE,
                SYSDATE,
                'RC_INV_C3_QTY_YIELD_CALC',
                NULL,
                'CRPADM');


   OPEN C3_DATA;

   LOOP
      FETCH C3_DATA INTO C3;

      EXIT WHEN C3_DATA%NOTFOUND;
      
      BEGIN

      UPDATE RC_INV_C3_TBL TBL
         SET RF_REFURB_METHOD =
                (SELECT PC.CONFIG_NAME
                   FROM CRPADM.RC_PRODUCT_CONFIG PC
                        INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                           ON (   C3.INVENTORY_ITEM_ID =
                                     PM.REFRESH_INVENTORY_ITEM_ID
                               OR C3.INVENTORY_ITEM_ID =
                                     PM.COMMON_INVENTORY_ITEM_ID
                               OR C3.INVENTORY_ITEM_ID =
                                     PM.XREF_INVENTORY_ITEM_ID)
                        INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR M
                           ON (C3.LOCATION = M.SUB_INVENTORY_LOCATION)
                  WHERE     1 = 1
                        AND PC.CONFIG_TYPE = 'REFRESH_METHOD'
                        AND (SELECT CRPADM.RC_INV_BTS_C3_PKG.RC_INV_GET_REFURB_METHOD (PM.REFRESH_INVENTORY_ITEM_ID, (SUBSTR (C3.PLACE_ID, 1, 3)), C3.LOCATION)
                               FROM DUAL) = PC.CONFIG_ID
                        AND M.NETTABLE_FLAG = 1
                        AND M.PROGRAM_TYPE IN (0, 2)
                        AND PM.PROGRAM_TYPE = 0
                        AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                        AND PM.REFRESH_PART_NUMBER NOT IN
                        (SELECT REFRESH_PART_NUMBER
                           FROM RMKTGADM.RC_INV_EXCLUDE_PIDS)),
             WS_REFURB_METHOD =
                (SELECT PC.CONFIG_NAME
                   FROM CRPADM.RC_PRODUCT_CONFIG PC
                        INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                           ON (   C3.INVENTORY_ITEM_ID =
                                     PM.REFRESH_INVENTORY_ITEM_ID
                               OR C3.INVENTORY_ITEM_ID =
                                     PM.COMMON_INVENTORY_ITEM_ID
                               OR C3.INVENTORY_ITEM_ID =
                                     PM.XREF_INVENTORY_ITEM_ID)
                        INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR M
                           ON (C3.LOCATION = M.SUB_INVENTORY_LOCATION)
                  WHERE     1 = 1
                        AND PC.CONFIG_TYPE = 'REFRESH_METHOD'
                        AND (SELECT CRPADM.RC_INV_BTS_C3_PKG.RC_INV_GET_REFURB_METHOD (PM.REFRESH_INVENTORY_ITEM_ID, (SUBSTR (C3.PLACE_ID, 1, 3)), C3.LOCATION)
                               FROM DUAL) = PC.CONFIG_ID
                        AND M.NETTABLE_FLAG = 1
                        AND M.PROGRAM_TYPE IN (1, 2) 
                        AND PM.PROGRAM_TYPE = 1
                        AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                        AND PM.REFRESH_PART_NUMBER NOT IN
                        (SELECT REFRESH_PART_NUMBER
                           FROM RMKTGADM.RC_INV_EXCLUDE_PIDS)),
             RF_QTY_AFTER_YIELD =
                NVL (
                   (SELECT NVL (
                                CRPADM.RC_INV_BTS_C3_PKG.RC_INV_GET_YIELD (
                                   PM.REFRESH_INVENTORY_ITEM_ID,
                                   SUBSTR (C3.PLACE_ID, 1, 3),
                                   C3.LOCATION)
                              * (  NVL (CASE WHEN C3.QTY_ON_HAND_USEBL>0 THEN C3.QTY_ON_HAND_USEBL ELSE 0 END, 0) ) -->> Added case to avoid negative qty_on_hand 09-Jan-2019
--                                 + NVL (
--                                      DECODE (M.UDC_1,
--                                              'Y', C3.QTY_IN_TRANS_USEBL,
--                                              0),
--                                      0)),  --commented by hkarka on 01OCT2018
                                      /100, --added by hkarka on 01OCT2018
                              0)
                      FROM DUAL
                           INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                              ON (   C3.INVENTORY_ITEM_ID =
                                        PM.REFRESH_INVENTORY_ITEM_ID
                                  OR C3.INVENTORY_ITEM_ID =
                                        PM.COMMON_INVENTORY_ITEM_ID
                                  OR C3.INVENTORY_ITEM_ID =
                                        PM.XREF_INVENTORY_ITEM_ID)
                           INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR M
                              ON (C3.LOCATION = M.SUB_INVENTORY_LOCATION)
                     WHERE     1 = 1
                           AND M.NETTABLE_FLAG = 1
                           AND M.PROGRAM_TYPE IN (0, 2)
                           AND PM.PROGRAM_TYPE = 0
                           AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                           AND PM.REFRESH_PART_NUMBER NOT IN
                        (SELECT REFRESH_PART_NUMBER
                           FROM RMKTGADM.RC_INV_EXCLUDE_PIDS)),
                   0),
             WS_QTY_AFTER_YIELD =
                NVL (
                   (SELECT NVL (
                                CRPADM.RC_INV_BTS_C3_PKG.RC_INV_GET_YIELD (
                                   PM.REFRESH_INVENTORY_ITEM_ID,
                                   SUBSTR (C3.PLACE_ID, 1, 3),
                                   C3.LOCATION)
                              * (  NVL (CASE WHEN C3.QTY_ON_HAND_USEBL>0 THEN C3.QTY_ON_HAND_USEBL ELSE 0 END, 0)) -->> Added case to avoid negative qty_on_hand 09-Jan-2019
--                                 + NVL (
--                                      DECODE (M.UDC_1,
--                                              'Y', C3.QTY_IN_TRANS_USEBL,
--                                              0),
--                                      0)),  --commented by hkarka on 01OCT2018
                                      /100,  --added by hkarka on 01OCT2018
                              0)
                      FROM DUAL
                           INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                              ON (   C3.INVENTORY_ITEM_ID =
                                        PM.REFRESH_INVENTORY_ITEM_ID
                                  OR C3.INVENTORY_ITEM_ID =
                                        PM.COMMON_INVENTORY_ITEM_ID
                                  OR C3.INVENTORY_ITEM_ID =
                                        PM.XREF_INVENTORY_ITEM_ID)
                           INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR M
                              ON (C3.LOCATION = M.SUB_INVENTORY_LOCATION)
                     WHERE     1 = 1
                           AND M.NETTABLE_FLAG = 1
                           AND M.PROGRAM_TYPE IN (1, 2)
                           AND PM.PROGRAM_TYPE = 1
                           AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                           AND PM.REFRESH_PART_NUMBER NOT IN
                        (SELECT REFRESH_PART_NUMBER
                           FROM RMKTGADM.RC_INV_EXCLUDE_PIDS)),
                   0),  
/* Start Added on 12-Dec-2018 by sridvasu */				   
			RF_YIELD_PERCENT = 
                NVL (
                   (SELECT NVL (
                                CRPADM.RC_INV_BTS_C3_PKG.RC_INV_GET_YIELD (
                                   PM.REFRESH_INVENTORY_ITEM_ID,
                                   SUBSTR (C3.PLACE_ID, 1, 3),
                                   C3.LOCATION),
                              0)
                      FROM DUAL
                           INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                              ON (   C3.INVENTORY_ITEM_ID =
                                        PM.REFRESH_INVENTORY_ITEM_ID
                                  OR C3.INVENTORY_ITEM_ID =
                                        PM.COMMON_INVENTORY_ITEM_ID
                                  OR C3.INVENTORY_ITEM_ID =
                                        PM.XREF_INVENTORY_ITEM_ID)
                           INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR M
                              ON (C3.LOCATION = M.SUB_INVENTORY_LOCATION)
                     WHERE     1 = 1
                           AND M.NETTABLE_FLAG = 1
                           AND M.PROGRAM_TYPE IN (0, 2)
                           AND PM.PROGRAM_TYPE = 0
                           AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                           AND PM.REFRESH_PART_NUMBER NOT IN
                        (SELECT REFRESH_PART_NUMBER
                           FROM RMKTGADM.RC_INV_EXCLUDE_PIDS)),
                   0),
             WS_YIELD_PERCENT =
                NVL (
                   (SELECT NVL (
                                CRPADM.RC_INV_BTS_C3_PKG.RC_INV_GET_YIELD (
                                   PM.REFRESH_INVENTORY_ITEM_ID,
                                   SUBSTR (C3.PLACE_ID, 1, 3),
                                   C3.LOCATION),
                              0)
                      FROM DUAL
                           INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                              ON (   C3.INVENTORY_ITEM_ID =
                                        PM.REFRESH_INVENTORY_ITEM_ID
                                  OR C3.INVENTORY_ITEM_ID =
                                        PM.COMMON_INVENTORY_ITEM_ID
                                  OR C3.INVENTORY_ITEM_ID =
                                        PM.XREF_INVENTORY_ITEM_ID)
                           INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR M
                              ON (C3.LOCATION = M.SUB_INVENTORY_LOCATION)
                     WHERE     1 = 1
                           AND M.NETTABLE_FLAG = 1
                           AND M.PROGRAM_TYPE IN (1, 2)
                           AND PM.PROGRAM_TYPE = 1
                           AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                           AND PM.REFRESH_PART_NUMBER NOT IN
                        (SELECT REFRESH_PART_NUMBER
                           FROM RMKTGADM.RC_INV_EXCLUDE_PIDS)),
                   0),
             YIELDED_RF_QTY_IN_TRANSIT =
                NVL (
                   (SELECT NVL (
                                CRPADM.RC_INV_BTS_C3_PKG.RC_INV_GET_YIELD (
                                   PM.REFRESH_INVENTORY_ITEM_ID,
                                   SUBSTR (C3.PLACE_ID, 1, 3),
                                   C3.LOCATION)
                              * 
                                 NVL (
                                      DECODE (M.UDC_1,
                                              'Y', CASE WHEN C3.QTY_IN_TRANS_USEBL>0 THEN C3.QTY_IN_TRANS_USEBL ELSE 0 END,  -->> Added case to avoid negative qty_in_transit 09-Jan-2019
                                              0),
                                      0)  --commented by hkarka on 01OCT2018
                                      /100, --added by hkarka on 01OCT2018
                              0)
                      FROM DUAL
                           INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                              ON (   C3.INVENTORY_ITEM_ID =
                                        PM.REFRESH_INVENTORY_ITEM_ID
                                  OR C3.INVENTORY_ITEM_ID =
                                        PM.COMMON_INVENTORY_ITEM_ID
                                  OR C3.INVENTORY_ITEM_ID =
                                        PM.XREF_INVENTORY_ITEM_ID)
                           INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR M
                              ON (C3.LOCATION = M.SUB_INVENTORY_LOCATION)
                     WHERE     1 = 1
                           AND M.NETTABLE_FLAG = 1
                           AND M.PROGRAM_TYPE IN (0, 2)
                           AND PM.PROGRAM_TYPE = 0
                           AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                           AND PM.REFRESH_PART_NUMBER NOT IN
                        (SELECT REFRESH_PART_NUMBER
                           FROM RMKTGADM.RC_INV_EXCLUDE_PIDS)),
                   0),
             YIELDED_WS_QTY_IN_TRANSIT =
                NVL (
                   (SELECT NVL (
                                CRPADM.RC_INV_BTS_C3_PKG.RC_INV_GET_YIELD (
                                   PM.REFRESH_INVENTORY_ITEM_ID,
                                   SUBSTR (C3.PLACE_ID, 1, 3),
                                   C3.LOCATION)
                              * 
                                  NVL (
                                      DECODE (M.UDC_1,
                                              'Y', CASE WHEN C3.QTY_IN_TRANS_USEBL>0 THEN C3.QTY_IN_TRANS_USEBL ELSE 0 END,  -->> Added case to avoid negative qty_in_transit 09-Jan-2019
                                              0),
                                      0) 
                                      /100,  
                              0)
                      FROM DUAL
                           INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                              ON (   C3.INVENTORY_ITEM_ID =
                                        PM.REFRESH_INVENTORY_ITEM_ID
                                  OR C3.INVENTORY_ITEM_ID =
                                        PM.COMMON_INVENTORY_ITEM_ID
                                  OR C3.INVENTORY_ITEM_ID =
                                        PM.XREF_INVENTORY_ITEM_ID)
                           INNER JOIN CRPADM.RC_SUB_INV_LOC_MSTR M
                              ON (C3.LOCATION = M.SUB_INVENTORY_LOCATION)
                     WHERE     1 = 1
                           AND M.NETTABLE_FLAG = 1
                           AND M.PROGRAM_TYPE IN (1, 2)
                           AND PM.PROGRAM_TYPE = 1
                           AND PM.REFRESH_LIFE_CYCLE_ID IN (3, 4, 5)
                           AND PM.REFRESH_PART_NUMBER NOT IN
                        (SELECT REFRESH_PART_NUMBER
                           FROM RMKTGADM.RC_INV_EXCLUDE_PIDS)),
                   0)                   
/* End Added on 12-Dec-2018 by sridvasu */				   				   
       WHERE     1 = 1
             AND TBL.INVENTORY_ITEM_ID = C3.INVENTORY_ITEM_ID
             AND TBL.PLACE_ID = C3.PLACE_ID
             AND TBL.LOCATION = C3.LOCATION; -- WHERE PART_ID = 'WSC2960XR48FPDI-RF'	   
			 
        EXCEPTION         
           WHEN OTHERS
           THEN
              ERROR_MSG :=
                    SUBSTR (SQLERRM, 1, 200)
                 || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

              INSERT INTO RC_CRON_HISTORY_LOG (CHL_ID,
                                               CHL_STATUS,
                                               CHL_START_TIMESTAMP,
                                               CHL_END_TIMESTAMP,
                                               CHL_CRON_NAME,
                                               CHL_COMMENTS,
                                               CHL_CREATED_BY)
                   VALUES (SEQ_CHL_ID.NEXTVAL,
                           'EXCEPTION',
                           SYSDATE,
                           SYSDATE,
                           'RC_INV_C3_QTY_YIELD_CALC',
                           ERROR_MSG,
                           'CRPADM');

              COMMIT; 
            
      END;            

   END LOOP;
   
   /* Start updating with 100% yield for IS_SCRAP = FG locations on 23-OCT-2018 by sridvasu */

    UPDATE RC_INV_C3_TBL
       SET RF_QTY_AFTER_YIELD = CASE WHEN QTY_ON_HAND_USEBL>0 THEN QTY_ON_HAND_USEBL ELSE 0 END--+ QTY_IN_TRANS_USEBL -->> Commented Qty in transit for RF on 12-Dec-2018 by sridvasu -->> Added case to avoid negative qty_on_hand 09-Jan-2019
     WHERE LOCATION IN
              (SELECT SUB_INVENTORY_LOCATION
                 FROM CRPADM.RC_SUB_INV_LOC_FLG_DTLS FLG_DTLS,
                      CRPADM.RC_SUB_INV_LOC_MSTR LOC_MSTR
                WHERE     FLG_DTLS.SUB_INVENTORY_ID = LOC_MSTR.SUB_INVENTORY_ID
                      AND IS_SCRAP = 'FG'
                      AND PROGRAM_TYPE = 0);
                      
    UPDATE RC_INV_C3_TBL
       SET WS_QTY_AFTER_YIELD = CASE WHEN QTY_ON_HAND_USEBL>0 THEN QTY_ON_HAND_USEBL ELSE 0 END --+ QTY_IN_TRANS_USEBL -->> Commented Qty in transit for WS on 12-Dec-2018 by sridvasu -->> Added case to avoid negative qty_on_hand 09-Jan-2019
     WHERE LOCATION IN
              (SELECT SUB_INVENTORY_LOCATION
                 FROM CRPADM.RC_SUB_INV_LOC_FLG_DTLS FLG_DTLS,
                      CRPADM.RC_SUB_INV_LOC_MSTR LOC_MSTR
                WHERE     FLG_DTLS.SUB_INVENTORY_ID = LOC_MSTR.SUB_INVENTORY_ID
                      AND IS_SCRAP = 'FG'
                      AND PROGRAM_TYPE = 1);
                      
    /* End updating with 100% yield for IS_SCRAP = FG locations on 23-OCT-2018 by sridvasu */  
    
   /* Start updating with 100% yield for IS_SCRAP = FG locations on 12-Dec-2018 by sridvasu */

    UPDATE RC_INV_C3_TBL
       SET RF_YIELD_PERCENT = 100
     WHERE LOCATION IN
              (SELECT SUB_INVENTORY_LOCATION
                 FROM CRPADM.RC_SUB_INV_LOC_FLG_DTLS FLG_DTLS,
                      CRPADM.RC_SUB_INV_LOC_MSTR LOC_MSTR
                WHERE     FLG_DTLS.SUB_INVENTORY_ID = LOC_MSTR.SUB_INVENTORY_ID
                      AND IS_SCRAP = 'FG'
                      AND PROGRAM_TYPE = 0);
                      
    UPDATE RC_INV_C3_TBL
       SET WS_YIELD_PERCENT = 100
     WHERE LOCATION IN
              (SELECT SUB_INVENTORY_LOCATION
                 FROM CRPADM.RC_SUB_INV_LOC_FLG_DTLS FLG_DTLS,
                      CRPADM.RC_SUB_INV_LOC_MSTR LOC_MSTR
                WHERE     FLG_DTLS.SUB_INVENTORY_ID = LOC_MSTR.SUB_INVENTORY_ID
                      AND IS_SCRAP = 'FG'
                      AND PROGRAM_TYPE = 1);
                      
    UPDATE RC_INV_C3_TBL
       SET YIELDED_RF_QTY_IN_TRANSIT = CASE WHEN QTY_IN_TRANS_USEBL>0 THEN QTY_IN_TRANS_USEBL ELSE 0 END -->> Added case to avoid negative qty_in_transit 09-Jan-2019
     WHERE LOCATION IN
              (SELECT SUB_INVENTORY_LOCATION
                 FROM CRPADM.RC_SUB_INV_LOC_FLG_DTLS FLG_DTLS,
                      CRPADM.RC_SUB_INV_LOC_MSTR LOC_MSTR
                WHERE     FLG_DTLS.SUB_INVENTORY_ID = LOC_MSTR.SUB_INVENTORY_ID
                      AND IS_SCRAP = 'FG'
                      AND PROGRAM_TYPE = 0);
                      
    UPDATE RC_INV_C3_TBL
       SET YIELDED_WS_QTY_IN_TRANSIT = CASE WHEN QTY_IN_TRANS_USEBL>0 THEN QTY_IN_TRANS_USEBL ELSE 0 END -->> Added case to avoid negative qty_in_transit 09-Jan-2019
     WHERE LOCATION IN
              (SELECT SUB_INVENTORY_LOCATION
                 FROM CRPADM.RC_SUB_INV_LOC_FLG_DTLS FLG_DTLS,
                      CRPADM.RC_SUB_INV_LOC_MSTR LOC_MSTR
                WHERE     FLG_DTLS.SUB_INVENTORY_ID = LOC_MSTR.SUB_INVENTORY_ID
                      AND IS_SCRAP = 'FG'
                      AND PROGRAM_TYPE = 1);                      
                      
    /* End updating with 100% yield for IS_SCRAP = FG locations on 12-Dec-2018 by sridvasu */                         
   
/* Start  added script to update Nettable flag in C3 table on 26-Nov-2018 */

        UPDATE CRPADM.RC_INV_C3_TBL C3
           SET NETTABLE_FLAG =
                  (SELECT NETTABLE_FLAG
                     FROM CRPADM.RC_SUB_INV_LOC_MSTR LOC
                    WHERE LOC.SUB_INVENTORY_LOCATION = C3.LOCATION);
                    
/* End added script to update Nettable flag in C3 table on 26-Nov-2018 */   

  COMMIT;
  
  CLOSE C3_DATA;

   -->> Inserting SUCCESS entry to Log table

   INSERT INTO RC_CRON_HISTORY_LOG (CHL_ID,
                                    CHL_STATUS,
                                    CHL_START_TIMESTAMP,
                                    CHL_END_TIMESTAMP,
                                    CHL_CRON_NAME,
                                    CHL_COMMENTS,
                                    CHL_CREATED_BY)
        VALUES (SEQ_CHL_ID.NEXTVAL,
                'SUCCESS',
                SYSDATE,
                SYSDATE,
                'RC_INV_C3_QTY_YIELD_CALC',
                NULL,
                'CRPADM');

   COMMIT;
EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      INSERT INTO RC_CRON_HISTORY_LOG (CHL_ID,
                                       CHL_STATUS,
                                       CHL_START_TIMESTAMP,
                                       CHL_END_TIMESTAMP,
                                       CHL_CRON_NAME,
                                       CHL_COMMENTS,
                                       CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'EXCEPTION',
                   SYSDATE,
                   SYSDATE,
                   'RC_INV_C3_QTY_YIELD_CALC',
                   'NULL VALUES',
                   'CRPADM');

      COMMIT;
   WHEN OTHERS
   THEN
      ERROR_MSG :=
            SUBSTR (SQLERRM, 1, 200)
         || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

      INSERT INTO RC_CRON_HISTORY_LOG (CHL_ID,
                                       CHL_STATUS,
                                       CHL_START_TIMESTAMP,
                                       CHL_END_TIMESTAMP,
                                       CHL_CRON_NAME,
                                       CHL_COMMENTS,
                                       CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'EXCEPTION',
                   SYSDATE,
                   SYSDATE,
                   'RC_INV_C3_QTY_YIELD_CALC',
                   ERROR_MSG,
                   'CRPADM');

      COMMIT;

--      RAISE_APPLICATION_ERROR (-20000, SQLERRM);

END RC_INV_C3_QTY_YIELD_CALC; 

/* End Added new procedure RC_INV_C3_QTY_YIELD_CALC to calculate qty after yield on 28th Sep 2018 by sridvasu */   
 
   FUNCTION RC_INV_GET_REFURB_METHOD (I_RID                 NUMBER,
                                      I_ZCODE               VARCHAR2, --Added  parameter as part of userstory US193036 to modify yield calculation ligic
                                      I_SUB_INV_LOCATION    VARCHAR2) --Added  parameter as part of userstory US193036 to modify yield calculation ligic
      RETURN NUMBER
   IS
      LV_REFRESH_METHOD   NUMBER;
      ERROR_MSG           VARCHAR2(10000);
   BEGIN
      /* --Start Commented as part of userstory US193036 to modify yield calculation ligic

         SELECT MIN (RS.REFRESH_METHOD_ID)
           INTO LV_GLOBAL_REFRESH_METHOD
           FROM CRPADM.RC_PRODUCT_REPAIR_SETUP RS
          WHERE     RS.REFRESH_INVENTORY_ITEM_ID = I_RID
                AND RS.REFRESH_STATUS = 'ACTIVE';

         RETURN LV_GLOBAL_REFRESH_METHOD;

         --End Commented as part of userstory US193036 to modify yield calculation logic
         */
      --Start Added as part of userstory US193036 to modify yield calculation logic
      IF I_ZCODE IN ('Z05', 'Z29')
      THEN
         BEGIN
            SELECT NVL (RS.REFRESH_METHOD_ID, 0)
              INTO LV_REFRESH_METHOD
              FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                   CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
             WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                   AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                   AND RS.REFRESH_METHOD_ID IN
                          (SELECT DTLS.REFRESH_METHOD_ID
                             FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                  CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                            WHERE     MSTR.SUB_INVENTORY_ID =
                                         DTLS.SUB_INVENTORY_ID
                                  AND MSTR.SUB_INVENTORY_LOCATION =
                                         I_SUB_INV_LOCATION)
                   AND RP.ZCODE = I_ZCODE
                   AND RS.REFRESH_METHOD_ID = 3
                   AND RS.REFRESH_STATUS = 'ACTIVE'
                   AND RP.ACTIVE_FLAG = 'Y';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               LV_REFRESH_METHOD := 0;
            WHEN OTHERS
            THEN
               NULL;                                    -- need to be reviewed
         END;
         
/* Start added Apply global screen yield for Z05,Z29 if local screen yield is not setup for Z05 or Z29 on 11-FEB-2019 */         
         
         IF LV_REFRESH_METHOD = 0 OR LV_REFRESH_METHOD IS NULL
         THEN
            BEGIN

            SELECT NVL (RS.REFRESH_METHOD_ID, 0)
              INTO LV_REFRESH_METHOD
              FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                   CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
             WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                   AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                   AND RS.REFRESH_METHOD_ID IN
                          (SELECT DTLS.REFRESH_METHOD_ID
                             FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                  CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                            WHERE     MSTR.SUB_INVENTORY_ID =
                                         DTLS.SUB_INVENTORY_ID
                                  AND MSTR.SUB_INVENTORY_LOCATION =
                                         I_SUB_INV_LOCATION)
--                   AND RP.ZCODE = I_ZCODE
                   AND RS.REFRESH_METHOD_ID = 3
                   AND RS.REFRESH_STATUS = 'ACTIVE'
                   AND RP.ACTIVE_FLAG = 'Y';
                 
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  LV_REFRESH_METHOD := 0;
               WHEN OTHERS
               THEN
                  NULL;                                 -- need to be reviewed
            END;        

/* End added Apply global screen yield for Z05,Z29 if local screen yield is not setup for Z05 or Z29 on 11-FEB-2019 */      

             IF LV_REFRESH_METHOD = 0 OR LV_REFRESH_METHOD IS NULL
             THEN
                BEGIN
                   SELECT NVL (MIN (RS.REFRESH_METHOD_ID), 0)
                     INTO LV_REFRESH_METHOD
                     FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                          CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                    WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                          AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                          AND RS.REFRESH_METHOD_ID IN
                                 (SELECT DTLS.REFRESH_METHOD_ID
                                    FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                         CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                                   WHERE     MSTR.SUB_INVENTORY_ID =
                                                DTLS.SUB_INVENTORY_ID
                                         AND MSTR.SUB_INVENTORY_LOCATION =
                                                I_SUB_INV_LOCATION)
                          AND RP.ZCODE = I_ZCODE
                          AND RS.REFRESH_STATUS = 'ACTIVE'
                          AND RP.ACTIVE_FLAG = 'Y';
                EXCEPTION
                   WHEN NO_DATA_FOUND
                   THEN
                      LV_REFRESH_METHOD := 0;
                   WHEN OTHERS
                   THEN
                      NULL;                                 -- need to be reviewed
                END;

                IF LV_REFRESH_METHOD = 0 OR LV_REFRESH_METHOD IS NULL
                THEN
                   BEGIN
                      SELECT NVL (MIN (RS.REFRESH_METHOD_ID), 0)
                        INTO LV_REFRESH_METHOD
                        FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                             CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                       WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                             AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                             AND RS.REFRESH_METHOD_ID IN
                                    (SELECT DTLS.REFRESH_METHOD_ID
                                       FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                            CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                                      WHERE     MSTR.SUB_INVENTORY_ID =
                                                   DTLS.SUB_INVENTORY_ID
                                            AND MSTR.SUB_INVENTORY_LOCATION =
                                                   I_SUB_INV_LOCATION)
                             --              AND RP.ZCODE = I_ZCODE
                             AND RS.REFRESH_METHOD_ID <> 3
                             AND RS.REFRESH_STATUS = 'ACTIVE'
                             AND RP.ACTIVE_FLAG = 'Y';
                   EXCEPTION
                      WHEN NO_DATA_FOUND
                      THEN
                         LV_REFRESH_METHOD := 0;
                      WHEN OTHERS
                      THEN
                         NULL;                              -- need to be reviewed
                   END;
                END IF;
            END IF;
         END IF;
      ELSE
         BEGIN
            SELECT NVL (MIN (RS.REFRESH_METHOD_ID), 0)
              INTO LV_REFRESH_METHOD
              FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                   CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
             WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                   AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                   AND RS.REFRESH_METHOD_ID IN
                          (SELECT DTLS.REFRESH_METHOD_ID
                             FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                  CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                            WHERE     MSTR.SUB_INVENTORY_ID =
                                         DTLS.SUB_INVENTORY_ID
                                  AND MSTR.SUB_INVENTORY_LOCATION =
                                         I_SUB_INV_LOCATION)
                   AND RP.ZCODE = I_ZCODE
                   AND RS.REFRESH_METHOD_ID <> 3
                   AND RS.REFRESH_STATUS = 'ACTIVE'
                   AND RP.ACTIVE_FLAG = 'Y';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               LV_REFRESH_METHOD := 0;
            WHEN OTHERS
            THEN
               NULL;                                    -- need to be reviewed
         END;

         IF LV_REFRESH_METHOD = 0 OR LV_REFRESH_METHOD IS NULL
         THEN
            BEGIN
               SELECT NVL (MIN (RS.REFRESH_METHOD_ID), 0)
                 INTO LV_REFRESH_METHOD
                 FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                      CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                      AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                      AND RS.REFRESH_METHOD_ID IN
                             (SELECT DTLS.REFRESH_METHOD_ID
                                FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                     CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                               WHERE     MSTR.SUB_INVENTORY_ID =
                                            DTLS.SUB_INVENTORY_ID
                                     AND MSTR.SUB_INVENTORY_LOCATION =
                                            I_SUB_INV_LOCATION)
                      --          AND RP.ZCODE = I_ZCODE
                      AND RS.REFRESH_METHOD_ID <> 3
                      AND RS.REFRESH_STATUS = 'ACTIVE'
                      AND RP.ACTIVE_FLAG = 'Y';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  LV_REFRESH_METHOD := 0;
               WHEN OTHERS
               THEN
                  NULL;                                 -- need to be reviewed
            END;
         END IF;
      END IF;

      RETURN LV_REFRESH_METHOD;
   --End Added as part of userstory US193036 to modify yield calculation ligic

EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
         RETURN 0; ---Added as part of userstory US193036 to modify yield calculation ligic

         ERROR_MSG := 'NO DATA in RC_PRODUCT_REPAIR_SETUP for ' || I_RID;
            
      INSERT INTO RC_CRON_HISTORY_LOG (CHL_ID,
                                       CHL_STATUS,
                                       CHL_START_TIMESTAMP,
                                       CHL_END_TIMESTAMP,
                                       CHL_CRON_NAME,
                                       CHL_COMMENTS,
                                       CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'EXCEPTION',
                   SYSDATE,
                   SYSDATE,
                   'RC_INV_GET_REFURB_METHOD',
                   'NULL VALUES',
                   'CRPADM');
      COMMIT;
   WHEN OTHERS
   THEN
      ERROR_MSG :=
            SUBSTR (SQLERRM, 1, 200)
         || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

      INSERT INTO RC_CRON_HISTORY_LOG (CHL_ID,
                                       CHL_STATUS,
                                       CHL_START_TIMESTAMP,
                                       CHL_END_TIMESTAMP,
                                       CHL_CRON_NAME,
                                       CHL_COMMENTS,
                                       CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'EXCEPTION',
                   SYSDATE,
                   SYSDATE,
                   'RC_INV_GET_REFURB_METHOD',
                   ERROR_MSG,
                   'CRPADM');

      COMMIT;
      
   END RC_INV_GET_REFURB_METHOD;


   FUNCTION RC_INV_GET_YIELD ( /*I_PRODUCT_TYPE                 NUMBER,  --Removing  parameter as part of userstory US193036 to modify yield calculation ligic */
                              /* I_THEATER_ID                   NUMBER,  --Removing  parameter as part of userstory US193036 to modify yield calculation ligic */
                              /* I_REFRESH_METHOD_ID            NUMBER,  --Removing  parameter as part of userstory US193036 to modify yield calculation ligic */
                              I_RID                 INTEGER, -- Added  parameter as part of userstory US193036 to modify yield calculation ligic
                              I_ZCODE               VARCHAR2,
                              I_SUB_INV_LOCATION    VARCHAR2) -- Added  parameter as part of userstory US193036 to modify yield calculation ligic
      RETURN NUMBER
   IS
      LV_YIELD   NUMBER;
      ERROR_MSG  VARCHAR2(10000);
   BEGIN
      /*  Start Commented as part of userstory US193036 to modify yield calculation ligic
         SELECT NVL (REFRESH_YIELD, 0)
           INTO LV_YIELD
           FROM CRPADM.RC_PRODUCT_REPAIR_SETUP RS
                INNER JOIN CRPADM.RC_PRODUCT_MASTER PM
                   ON (PM.REFRESH_INVENTORY_ITEM_ID =
                          RS.REFRESH_INVENTORY_ITEM_ID)
                INNER JOIN CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                   ON (    RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                       AND RP.ACTIVE_FLAG = 'Y')
          WHERE     PM.PROGRAM_TYPE = I_PRODUCT_TYPE --0                  -- (paramer 1) pm.product_type
                AND RS.REFRESH_INVENTORY_ITEM_ID = I_REFRESH_INVENTORY_ITEM_ID --4210960 -- (Parameter 2)  pm.refresh_inventory_item_id
                AND RS.THEATER_ID = I_THEATER_ID --1   --,3  -- (Parameter 3) Map.REGION  (NAM , EMEA)
                AND RP.ZCODE = I_ZCODE --'Z05'       -- (parameter 4)  SUBSTR (C3.PLACE_ID, 1, 3)
                AND RS.REFRESH_STATUS = 'ACTIVE'
                AND RS.REFRESH_METHOD_ID = I_REFRESH_METHOD_ID --RMKTGADM.RC_INV_DELTA_LOAD_RF.RC_INV_GET_REFURB_METHOD(pm.refresh_inventory_item_id)
                AND RP.PROGRAM_TYPE = I_PRODUCT_TYPE;
        End Commented as part of userstory US193036 to modify yield calculation ligic */

      /*  Start Added as part of userstory US193036 to modify yield calculation ligic */

      IF I_ZCODE IN ('Z05', 'Z29')
      THEN
         BEGIN
            SELECT NVL (RS.REFRESH_YIELD, 0)
              INTO LV_YIELD
              FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                   CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
             WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                   AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                   AND RS.REFRESH_METHOD_ID IN
                          (SELECT DTLS.REFRESH_METHOD_ID
                             FROM CRPADM.RC_SUB_INV_LOC_MSTR    MSTR,
                                  CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                            WHERE     MSTR.SUB_INVENTORY_ID =
                                         DTLS.SUB_INVENTORY_ID
                                  AND MSTR.SUB_INVENTORY_LOCATION =
                                         I_SUB_INV_LOCATION)
                   AND RP.ZCODE = I_ZCODE
                   AND RS.REFRESH_METHOD_ID = 3
                   AND RS.REFRESH_STATUS = 'ACTIVE'
                   AND RP.ACTIVE_FLAG = 'Y';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               LV_YIELD := 0;
            WHEN OTHERS
            THEN
               LV_YIELD := 0;                           -- need to be reviewed
         END;

/* Start added Apply global screen yield for Z05,Z29 if local screen yield is not setup for Z05 or Z29 on 11-FEB-2019 */

         IF LV_YIELD = 0 OR LV_YIELD IS NULL
         THEN
            BEGIN

            SELECT NVL (RS.REFRESH_YIELD, 0)
              INTO LV_YIELD
              FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                   CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
             WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                   AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                   AND RS.REFRESH_METHOD_ID IN
                          (SELECT DTLS.REFRESH_METHOD_ID
                             FROM CRPADM.RC_SUB_INV_LOC_MSTR    MSTR,
                                  CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                            WHERE     MSTR.SUB_INVENTORY_ID =
                                         DTLS.SUB_INVENTORY_ID
                                  AND MSTR.SUB_INVENTORY_LOCATION =
                                         I_SUB_INV_LOCATION)
--                   AND RP.ZCODE = I_ZCODE
                   AND RS.REFRESH_METHOD_ID = 3
                   AND RS.REFRESH_STATUS = 'ACTIVE'
                   AND RP.ACTIVE_FLAG = 'Y';
                  
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  LV_YIELD := 0;
               WHEN OTHERS
               THEN
                  LV_YIELD := 0;                        -- need to be reviewed
            END;	

/* End added Apply global screen yield for Z05,Z29 if local screen yield is not setup for Z05 or Z29 on 11-FEB-2019 */
            
             IF LV_YIELD = 0 OR LV_YIELD IS NULL
             THEN
                BEGIN
                   SELECT NVL (MIN (RS.REFRESH_YIELD), 0)
                     INTO LV_YIELD
                     FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                          CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                    WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                          AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                          AND RS.REFRESH_METHOD_ID IN
                                 (SELECT DTLS.REFRESH_METHOD_ID
                                    FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                         CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                                   WHERE     MSTR.SUB_INVENTORY_ID =
                                                DTLS.SUB_INVENTORY_ID
                                         AND MSTR.SUB_INVENTORY_LOCATION =
                                                I_SUB_INV_LOCATION)
                          AND RP.ZCODE = I_ZCODE
                          AND RS.REFRESH_STATUS = 'ACTIVE'
                          AND RP.ACTIVE_FLAG = 'Y';
                EXCEPTION
                   WHEN NO_DATA_FOUND
                   THEN
                      LV_YIELD := 0;
                   WHEN OTHERS
                   THEN
                      LV_YIELD := 0;                        -- need to be reviewed
                END;

                IF LV_YIELD = 0 OR LV_YIELD IS NULL
                THEN
                   BEGIN
                      SELECT NVL (MIN (RS.REFRESH_YIELD), 0)
                        INTO LV_YIELD
                        FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                             CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                       WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                             AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                             AND RS.REFRESH_METHOD_ID IN
                                    (SELECT DTLS.REFRESH_METHOD_ID
                                       FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                            CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                                      WHERE     MSTR.SUB_INVENTORY_ID =
                                                   DTLS.SUB_INVENTORY_ID
                                            AND MSTR.SUB_INVENTORY_LOCATION =
                                                   I_SUB_INV_LOCATION)
                             --              AND RP.ZCODE = I_ZCODE
                             AND RS.REFRESH_METHOD_ID <> 3
                             AND RS.REFRESH_STATUS = 'ACTIVE'
                             AND RP.ACTIVE_FLAG = 'Y';
                   EXCEPTION
                      WHEN NO_DATA_FOUND
                      THEN
                         LV_YIELD := 0;
                      WHEN OTHERS
                      THEN
                         LV_YIELD := 0;                     -- need to be reviewed
                   END;
                END IF;
            END IF;
         END IF;
      ELSE
         BEGIN
            SELECT NVL (MIN (RS.REFRESH_YIELD), 0)
              INTO LV_YIELD
              FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                   CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
             WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                   AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                   AND RS.REFRESH_METHOD_ID IN
                          (SELECT DTLS.REFRESH_METHOD_ID
                             FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                  CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                            WHERE     MSTR.SUB_INVENTORY_ID =
                                         DTLS.SUB_INVENTORY_ID
                                  AND MSTR.SUB_INVENTORY_LOCATION =
                                         I_SUB_INV_LOCATION)
                   AND RP.ZCODE = I_ZCODE
                   AND RS.REFRESH_METHOD_ID <> 3
                   AND RS.REFRESH_STATUS = 'ACTIVE'
                   AND RP.ACTIVE_FLAG = 'Y';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               LV_YIELD := 0;
            WHEN OTHERS
            THEN
               LV_YIELD := 0;                           -- need to be reviewed
         END;

         IF LV_YIELD = 0 OR LV_YIELD IS NULL
         THEN
            BEGIN
               SELECT NVL (MIN (RS.REFRESH_YIELD), 0)
                 INTO LV_YIELD
                 FROM CRPADM.RC_PRODUCT_REPAIR_SETUP   RS,
                      CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                WHERE     REFRESH_INVENTORY_ITEM_ID = I_RID
                      AND RS.REPAIR_PARTNER_ID = RP.REPAIR_PARTNER_ID
                      AND RS.REFRESH_METHOD_ID IN
                             (SELECT DTLS.REFRESH_METHOD_ID
                                FROM CRPADM.RC_SUB_INV_LOC_MSTR     MSTR,
                                     CRPADM.RC_SUB_INV_LOC_FLG_DTLS DTLS
                               WHERE     MSTR.SUB_INVENTORY_ID =
                                            DTLS.SUB_INVENTORY_ID
                                     AND MSTR.SUB_INVENTORY_LOCATION =
                                            I_SUB_INV_LOCATION)
                      --          AND RP.ZCODE = I_ZCODE
                      AND RS.REFRESH_METHOD_ID <> 3
                      AND RS.REFRESH_STATUS = 'ACTIVE'
                      AND RP.ACTIVE_FLAG = 'Y';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  LV_YIELD := 0;
               WHEN OTHERS
               THEN
                  LV_YIELD := 0;                        -- need to be reviewed
            END;
         END IF;
      END IF;

      /* End Added as part of userstory US193036 to modify yield calculation ligic */


      RETURN LV_YIELD;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0;
      ----      DBMS_OUTPUT.PUT_LINE (
      ----         'NO DATA in RC_PRODUCT_REPAIR_SETUP for ');-- I_RID);
      WHEN OTHERS
      THEN
         ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

      INSERT INTO RC_CRON_HISTORY_LOG (CHL_ID,
                                       CHL_STATUS,
                                       CHL_START_TIMESTAMP,
                                       CHL_END_TIMESTAMP,
                                       CHL_CRON_NAME,
                                       CHL_COMMENTS,
                                       CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'EXCEPTION',
                   SYSDATE,
                   SYSDATE,
                   'RC_INV_GET_YIELD',
                   ERROR_MSG,
                   'CRPADM');

         COMMIT;

--         RAISE_APPLICATION_ERROR (-20000, SQLERRM);

   END RC_INV_GET_YIELD;

END RC_INV_BTS_C3_PKG;
/