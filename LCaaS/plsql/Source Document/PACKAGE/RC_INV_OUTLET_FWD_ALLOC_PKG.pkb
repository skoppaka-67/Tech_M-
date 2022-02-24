CREATE OR REPLACE PACKAGE BODY RMKTGADM."RC_INV_OUTLET_FWD_ALLOC_PKG" 
AS
   /*
   ****************************************************************************************************************
   * Object Name  : RC_INV_OUTLET_FWD_ALLOC_PKG
   * Project Name : Refresh Central
   * Copy Rights  : Cisco Systems, INC., CALIFORNIA
   * Description  : Forward Outlet Allocation
   * Created Date : 11-MAR-2019
   ===================================================================================================+
   * Version   Date            Modified by                     Description
   ===================================================================================================+
     1.0       11-MAR-2019     csirigir                        First Draft.
     2.0       11-FEB-2020     sumravik                        Added Delta outlet Verification and validation for the user story #US456837 
   ===================================================================================================+
   **************************************************************************************************************** */

   G_UPDATED_BY              VARCHAR2 (100);
   G_ERROR_MSG               VARCHAR2 (300);
   G_PROC_NAME               VARCHAR2 (100);
   G_START_TIME              DATE;
   v_message      VARCHAR2 (50);
 PROCEDURE RC_INV_OUTLET_FWD_ALLOC_PROC
   AS
      V_LRO_ROHS_OUTLET    NUMBER;
      V_LRO_NROHS_OUTLET   NUMBER;
      V_FVE_ROHS_OUTLET    NUMBER;
      V_LRO_ROHS_RETAIL    NUMBER;
      V_LRO_NROHS_RETAIL   NUMBER;
      V_FVE_ROHS_RETAIL    NUMBER;
      L_START_TIME         DATE;
      V_TOTAL_RETAIL       NUMBER;
      V_TOTAL_OUTLET       NUMBER;
      CCW_FG_O_LRO_NROHS   NUMBER;
      CCW_FG_O_FVE_ROHS    NUMBER;
      
      CURSOR REG_OUT
      IS SELECT DISTINCT SYSDATE AS RECORD_CREATED_DATE,
                             PM.REFRESH_PART_NUMBER, 
                  (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
                             AVAILABLE_TO_RESERVE_FGI
                     FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
                    WHERE     IM.INVENTORY_FLOW = 'Retail'
                          AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
                          AND IM.SITE_CODE IN ('LRO', 'FVE')
                          AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
                     CCW_FG_R_TOTAL,
                  (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
                             AVAILABLE_TO_RESERVE_FGI
                     FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
                    WHERE     IM.INVENTORY_FLOW = 'Retail'
                          AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
                          AND IM.SITE_CODE IN ('FVE')
                          AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
                     CCW_FG_R_FVE_ROHS,
                  (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
                             AVAILABLE_TO_RESERVE_FGI
                     FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
                    WHERE     IM.INVENTORY_FLOW = 'Retail'
                          AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
                          AND IM.SITE_CODE IN ('LRO')
                          AND IM.ROHS_COMPLIANT = 'YES'
                          AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
                     CCW_FG_R_LRO_ROHS,
                  (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
                             AVAILABLE_TO_RESERVE_FGI
                     FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
                    WHERE     IM.INVENTORY_FLOW = 'Retail'
                          AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
                          AND IM.SITE_CODE IN ('LRO')
                          AND IM.ROHS_COMPLIANT = 'NO'
                          AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
                     CCW_FG_R_LRO_NROHS,
                     FGI.OUTLET_ALLOC_QUANTITY, 
                     (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0) --Added by chandra
                             AVAILABLE_TO_RESERVE_FGI
                     FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
                    WHERE     IM.INVENTORY_FLOW = 'Outlet'
                          AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
                          AND IM.SITE_CODE IN ('LRO', 'FVE')
                          AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
                     CCW_FG_O_TOTAL,
                  (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
                             AVAILABLE_TO_RESERVE_FGI
                     FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
                    WHERE     IM.INVENTORY_FLOW = 'Outlet'
                          AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
                          AND IM.SITE_CODE IN ('FVE')
                          AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
                     CCW_FG_O_FVE_ROHS,
                  (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
                             AVAILABLE_TO_RESERVE_FGI
                     FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
                    WHERE     IM.INVENTORY_FLOW = 'Outlet'
                          AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
                          AND IM.SITE_CODE IN ('LRO')
                          AND IM.ROHS_COMPLIANT = 'YES'
                          AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
                     CCW_FG_O_LRO_ROHS,
                  (SELECT NVL (SUM (IM.AVAILABLE_TO_RESERVE_FGI), 0)
                             AVAILABLE_TO_RESERVE_FGI
                     FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
                    WHERE     IM.INVENTORY_FLOW = 'Outlet'
                          AND PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
                          AND IM.SITE_CODE IN ('LRO')
                          AND IM.ROHS_COMPLIANT = 'NO'
                          AND IM.AVAILABLE_TO_RESERVE_FGI > 0)
                     CCW_FG_O_LRO_NROHS
                FROM CRPADM.RC_PRODUCT_MASTER PM       -- RF part number is setup
                      -- Inventory Master
                      INNER JOIN RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
                         ON (    PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
                             AND IM.SITE_CODE IN ('LRO', 'FVE'))
                      INNER JOIN CRPSC.RC_AE_FGI_REQUIREMENT FGI
                        ON (PM.REFRESH_PART_NUMBER = FGI.REFRESH_PART_NUMBER)
                WHERE 1=1
                AND PM.REFRESH_PART_NUMBER LIKE '%RF' ; 
--                AND NVL(FGI.OUTLET_ALLOC_QUANTITY,0) <> 0; -- Commented on 23-Apr-2019

      BASE      REG_OUT%ROWTYPE;
      
   BEGIN
      L_START_TIME := SYSDATE;

      DELETE FROM RMKTGADM.RC_INV_OUTLET_FWD_ALLOC;

      DELETE FROM RMKTGADM.RC_INV_DELTA_SPLIT_LOG;

      COMMIT;

      OPEN REG_OUT;

      LOOP
         FETCH REG_OUT INTO BASE;

         EXIT WHEN REG_OUT%NOTFOUND;

           V_TOTAL_OUTLET:= BASE.OUTLET_ALLOC_QUANTITY; 
           
          /*V_LRO_ROHS_OUTLET  := - BASE.CCW_FG_O_LRO_ROHS; 
           V_LRO_NROHS_OUTLET := - BASE.CCW_FG_O_LRO_NROHS;
           V_FVE_ROHS_OUTLET  := - BASE.CCW_FG_O_FVE_ROHS; 
           
           V_LRO_ROHS_RETAIL  := BASE.CCW_FG_O_LRO_ROHS;  
           V_LRO_NROHS_RETAIL := BASE.CCW_FG_O_LRO_NROHS; 
           V_FVE_ROHS_RETAIL  := BASE.CCW_FG_O_FVE_ROHS;  */
           
            V_LRO_ROHS_OUTLET := BASE.CCW_FG_O_LRO_ROHS;
            V_LRO_NROHS_OUTLET := BASE.CCW_FG_O_LRO_NROHS;
            V_FVE_ROHS_OUTLET := BASE.CCW_FG_O_FVE_ROHS;

            V_LRO_ROHS_RETAIL := -BASE.CCW_FG_O_LRO_ROHS;
            V_LRO_NROHS_RETAIL := -BASE.CCW_FG_O_LRO_NROHS;
            V_FVE_ROHS_RETAIL := -BASE.CCW_FG_O_FVE_ROHS;   

    IF   BASE.CCW_FG_R_FVE_ROHS + V_FVE_ROHS_RETAIL >= V_TOTAL_OUTLET THEN  
               V_LRO_ROHS_OUTLET  := V_LRO_ROHS_OUTLET;
               V_LRO_NROHS_OUTLET := V_LRO_NROHS_OUTLET;
               V_FVE_ROHS_OUTLET  := V_FVE_ROHS_OUTLET + V_TOTAL_OUTLET;
            ELSE
               V_FVE_ROHS_OUTLET := BASE.CCW_FG_R_FVE_ROHS;
                
        IF BASE.CCW_FG_R_LRO_ROHS + V_LRO_ROHS_RETAIL >= (V_TOTAL_OUTLET - (V_FVE_ROHS_RETAIL+V_FVE_ROHS_OUTLET)) THEN  
            V_LRO_ROHS_OUTLET := V_LRO_ROHS_OUTLET + V_TOTAL_OUTLET - (V_FVE_ROHS_RETAIL+V_FVE_ROHS_OUTLET);
            V_LRO_NROHS_OUTLET  := V_LRO_NROHS_OUTLET;
        ELSE
            V_LRO_ROHS_OUTLET := BASE.CCW_FG_R_LRO_ROHS; 

            IF BASE.CCW_FG_R_LRO_NROHS + V_LRO_NROHS_RETAIL >= (V_TOTAL_OUTLET - (V_FVE_ROHS_RETAIL+V_FVE_ROHS_OUTLET) - (V_LRO_ROHS_RETAIL+V_LRO_ROHS_OUTLET)) THEN
                V_LRO_NROHS_OUTLET := V_LRO_NROHS_OUTLET + V_TOTAL_OUTLET - (V_FVE_ROHS_RETAIL+V_FVE_ROHS_OUTLET) - (V_LRO_ROHS_RETAIL+V_LRO_ROHS_OUTLET);
            ELSE
                V_LRO_NROHS_OUTLET := BASE.CCW_FG_R_LRO_NROHS;
            END IF;
        END IF;
                
    END IF;		
		
         V_LRO_ROHS_RETAIL := -V_LRO_ROHS_OUTLET;

         V_LRO_NROHS_RETAIL := -V_LRO_NROHS_OUTLET;

         V_FVE_ROHS_RETAIL := -V_FVE_ROHS_OUTLET;
         
         V_TOTAL_RETAIL := V_LRO_ROHS_RETAIL+V_LRO_NROHS_RETAIL+V_FVE_ROHS_RETAIL;
         
         V_TOTAL_OUTLET := V_LRO_ROHS_OUTLET+V_LRO_NROHS_OUTLET+V_FVE_ROHS_OUTLET;

         -->> insert for outlet forward allocation table
               INSERT INTO RMKTGADM.RC_INV_OUTLET_FWD_ALLOC(REFRESH_PART_NUMBER,
                                                            OUTLET_ALLOC_QUANTITY,
                                                            CCW_FG_R_TOTAL,
                                                            CCW_FG_R_FVE_ROHS,
                                                            CCW_FG_R_LRO_ROHS,
                                                            CCW_FG_R_LRO_NROHS,
															 CCW_FG_O_TOTAL,
                                                            CCW_FG_O_LRO_ROHS,
                                                            CCW_FG_O_LRO_NROHS,
                                                            CCW_FG_O_FVE_ROHS,
                                                            TOTAL_OUTLET,
                                                            OUTLET_LRO_ROHS_SPLIT,
                                                            OUTLET_LRO_NROHS_SPLIT,
                                                            OUTLET_FVE_SPLIT,
                                                            TOTAL_RETAIL,
                                                            RETAIL_LRO_ROHS_SPLIT,
                                                            RETAIL_LRO_NROHS_SPLIT,
                                                            RETAIL_FVE_SPLIT,
                                                            RECORD_CREATED_ON,
                                                            RECORD_CREATED_BY,
                                                            RECORD_UPDATED_ON,
                                                            RECORD_UPDATED_BY
                                                           )
              VALUES (BASE.REFRESH_PART_NUMBER,
                      BASE.OUTLET_ALLOC_QUANTITY,
                      BASE.CCW_FG_R_TOTAL,
                      BASE.CCW_FG_R_FVE_ROHS,
                      BASE.CCW_FG_R_LRO_ROHS,
                      BASE.CCW_FG_R_LRO_NROHS,
					  BASE.CCW_FG_O_TOTAL,
                      BASE.CCW_FG_O_LRO_ROHS,
                      BASE.CCW_FG_O_LRO_NROHS,
                      BASE.CCW_FG_O_FVE_ROHS,
                      V_TOTAL_OUTLET,
                      V_LRO_ROHS_OUTLET,
                      V_LRO_NROHS_OUTLET,
                      V_FVE_ROHS_OUTLET,
                      V_TOTAL_RETAIL,
                      V_LRO_ROHS_RETAIL,
                      V_LRO_NROHS_RETAIL,
                      V_FVE_ROHS_RETAIL,
                      SYSDATE,
                      'RC_INV_OUTLET_FWD_ALLOC_PROC',
                      SYSDATE,
                      'RC_INV_OUTLET_FWD_ALLOC_PROC'
                      );

         -->> insert for retail LRO Rohs
         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
                                                      PART_NUMBER,
                                                      NEW_FGI,
                                                      ROHS_COMPLIANT,
                                                      SITE_CODE,
                                                      PROCESS_STATUS,
                                                      -- AVAILABLE_TO_RESERVE_FGI,
                                                      -- GLOBAL_CUR_MAX,
                                                      UPDATED_ON,
                                                      UPDATED_BY,
                                                      CREATED_ON,
                                                      CREATED_BY,
                                                      --POE_BATCH_ID,
                                                      PRODUCT_TYPE)
              VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL, -- added on 07/25/2016
                      BASE.REFRESH_PART_NUMBER,
                      V_LRO_ROHS_RETAIL,
                      'YES',
                      'LRO',
                      'N',
                      -- BASE.CCW_FG_R_TOTAL,
                      -- BASE.RETAIL_MAX,
                      SYSDATE,
                      'RC_INV_OUTLET_FWD_ALLOC_PROC',
                      SYSDATE,
                      'RC_INV_OUTLET_FWD_ALLOC_PROC',
                      --BASE.POE_BATCH_ID,
                      'R');

         -->> insert for retail LRO Non-Rohs
         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
                                                      PART_NUMBER,
                                                      NEW_FGI,
                                                      ROHS_COMPLIANT,
                                                      SITE_CODE,
                                                      PROCESS_STATUS,
                                                      -- AVAILABLE_TO_RESERVE_FGI,
                                                      -- GLOBAL_CUR_MAX,
                                                      UPDATED_ON,
                                                      UPDATED_BY,
                                                      CREATED_ON,
                                                      CREATED_BY,
                                                      --POE_BATCH_ID,
                                                      PRODUCT_TYPE)
              VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL, -- added on 07/25/2016
                      BASE.REFRESH_PART_NUMBER,
                      V_LRO_NROHS_RETAIL,
                      'NO',
                      'LRO',
                      'N',
                      -- BASE.CCW_FG_R_TOTAL,
                      -- BASE.RETAIL_MAX,
                      SYSDATE,
                      'RC_INV_OUTLET_FWD_ALLOC_PROC',
                      SYSDATE,
                      'RC_INV_OUTLET_FWD_ALLOC_PROC',
                      --BASE.POE_BATCH_ID,
                      'R');
                      
         -->> insert for retail FVE Rohs
         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
                                                      PART_NUMBER,
                                                      NEW_FGI,
                                                      ROHS_COMPLIANT,
                                                      SITE_CODE,
                                                      PROCESS_STATUS,
                                                      -- AVAILABLE_TO_RESERVE_FGI,
                                                      -- GLOBAL_CUR_MAX,
                                                      UPDATED_ON,
                                                      UPDATED_BY,
                                                      CREATED_ON,
                                                      CREATED_BY,
                                                      --POE_BATCH_ID,
                                                      PRODUCT_TYPE)
              VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL, -- added on 07/25/2016
                      BASE.REFRESH_PART_NUMBER,
                      V_FVE_ROHS_RETAIL,
                      'YES',
                      'FVE',
                      'N',
                      -- BASE.CCW_FG_R_TOTAL,
                      -- BASE.RETAIL_MAX,
                      SYSDATE,
                      'RC_INV_OUTLET_FWD_ALLOC_PROC',
                      SYSDATE,
                      'RC_INV_OUTLET_FWD_ALLOC_PROC',
                      --BASE.POE_BATCH_ID,
                      'R');

         -->> insert for Outlet LRO Rohs
         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
                                                      PART_NUMBER,
                                                      NEW_FGI,
                                                      ROHS_COMPLIANT,
                                                      SITE_CODE,
                                                      PROCESS_STATUS,
                                                      --AVAILABLE_TO_RESERVE_FGI,
                                                      --GLOBAL_CUR_MAX,
                                                      UPDATED_ON,
                                                      UPDATED_BY,
                                                      CREATED_ON,
                                                      CREATED_BY,
                                                      --POE_BATCH_ID,
                                                      PRODUCT_TYPE)
              VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL, -- added on 07/25/2016
                      BASE.REFRESH_PART_NUMBER,
                      V_LRO_ROHS_OUTLET,
                      'YES',
                      'LRO',
                      'N',
                      --BASE.CCW_FG_R_TOTAL,
                      --BASE.RETAIL_MAX,
                      SYSDATE,
                      'RC_INV_OUTLET_FWD_ALLOC_PROC',
                      SYSDATE,
                      'RC_INV_OUTLET_FWD_ALLOC_PROC',
                      --BASE.POE_BATCH_ID,
                      'O');

         -->> insert for Outlet LRO Non-Rohs
         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
                                                      PART_NUMBER,
                                                      NEW_FGI,
                                                      ROHS_COMPLIANT,
                                                      SITE_CODE,
                                                      PROCESS_STATUS,
                                                      --AVAILABLE_TO_RESERVE_FGI,
                                                      --GLOBAL_CUR_MAX,
                                                      UPDATED_ON,
                                                      UPDATED_BY,
                                                      CREATED_ON,
                                                      CREATED_BY,
                                                      --POE_BATCH_ID,
                                                      PRODUCT_TYPE)
              VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL, -- added on 07/25/2016
                      BASE.REFRESH_PART_NUMBER,
                      V_LRO_NROHS_OUTLET,
                      'NO',
                      'LRO',
                      'N',
                      --                 BASE.CCW_FG_R_TOTAL,
                      --                 BASE.RETAIL_MAX,
                      SYSDATE,
                      'RC_INV_OUTLET_FWD_ALLOC_PROC',
                      SYSDATE,
                      'RC_INV_OUTLET_FWD_ALLOC_PROC',
                      --BASE.POE_BATCH_ID,
                      'O');

         -->> insert for Outlet FVE Rohs
         INSERT INTO RMKTGADM.RC_INV_DELTA_SPLIT_LOG (INVENTORY_LOG_ID,
                                                      PART_NUMBER,
                                                      NEW_FGI,
                                                      ROHS_COMPLIANT,
                                                      SITE_CODE,
                                                      PROCESS_STATUS,
                                                      --AVAILABLE_TO_RESERVE_FGI,
                                                      --GLOBAL_CUR_MAX,
                                                      UPDATED_ON,
                                                      UPDATED_BY,
                                                      CREATED_ON,
                                                      CREATED_BY,
                                                      --POE_BATCH_ID,
                                                      PRODUCT_TYPE)
              VALUES (RMKTGADM.RC_INV_LOG_PK_SEQ.NEXTVAL, -- added on 07/25/2016
                      BASE.REFRESH_PART_NUMBER,
                      V_FVE_ROHS_OUTLET,
                      'YES',
                      'FVE',
                      'N',
                      --                 BASE.CCW_FG_R_TOTAL,
                      --                 BASE.RETAIL_MAX,
                      SYSDATE,
                      'RC_INV_OUTLET_FWD_ALLOC_PROC',
                      SYSDATE,
                      'RC_INV_OUTLET_FWD_ALLOC_PROC',
                      --BASE.POE_BATCH_ID,
                      'O');

      END LOOP;

      COMMIT;
      
      -->> Added New Condition to delete records for New FGI = 0
      DELETE FROM RMKTGADM.RC_INV_DELTA_SPLIT_LOG
            WHERE NEW_FGI = 0;

      -->> Hist table for RC_INV_OUTLET_FWD_ALLOC table
      INSERT INTO RMKTGADM.RC_INV_OUTLET_FWD_ALLOC_H
         SELECT * FROM RMKTGADM.RC_INV_OUTLET_FWD_ALLOC;
         
      INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG (INVENTORY_LOG_ID,
                                                  PART_NUMBER,
                                                  NEW_FGI,
                                                  NEW_DGI,
                                                  ROHS_COMPLIANT,
                                                  SITE_CODE,
                                                  PROCESS_STATUS,
                                                  PROGRAM_TYPE,
                                                  UPDATED_ON,
                                                  UPDATED_BY,
                                                  CREATED_ON,
                                                  CREATED_BY,
                                                  POE_BATCH_ID)
         SELECT OULOG.INVENTORY_LOG_ID,
                OULOG.PART_NUMBER,
                OULOG.NEW_FGI,
                0   NEW_DGI,
                OULOG.ROHS_COMPLIANT,
                OULOG.SITE_CODE,
                'N' PROCESS_STATUS,
                PRODUCT_TYPE,
                SYSDATE,
                G_UPDATED_BY,
                SYSDATE,
                G_UPDATED_BY,
                'OUTLET_FORWARD_ALLOCATION'
           FROM RMKTGADM.RC_INV_DELTA_SPLIT_LOG OULOG;     
          
--      --to Insert the Delta inv into  rmk_inventory_log from  rmk_inventory_log_stg
--      INSERT INTO RMK_INVENTORY_LOG
--         SELECT *
--           FROM RMK_INVENTORY_LOG_STG
--          WHERE ATTRIBUTE1 IS NULL AND POE_BATCH_ID = 'OUTLET_FORWARD_ALLOCATION';
--
--      --Updating the rmk_inventory_log_stg table after processing the Delta Inv.
--      UPDATE RMK_INVENTORY_LOG_STG
--         SET ATTRIBUTE1 = 'PROCESSED'
--       WHERE ATTRIBUTE1 IS NULL AND POE_BATCH_ID = 'OUTLET_FORWARD_ALLOCATION';         

      COMMIT;

      INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                             CHL_STATUS,
                                             CHL_START_TIMESTAMP,
                                             CHL_END_TIMESTAMP,
                                             CHL_CRON_NAME,
                                             CHL_COMMENTS,
                                             CHL_CREATED_BY)
           VALUES (SEQ_CHL_ID.NEXTVAL,
                   'SUCCESS',
                   L_START_TIME,
                   SYSDATE,
                   'RC_INV_OUTLET_FWD_ALLOC_PROC',
                   NULL,
                   'RC_INV_OUTLET_FWD_ALLOC_PKG');

      G_PROC_NAME := 'RC_INV_OUTLET_FWD_ALLOC_PROC';
      
      COMMIT;
      
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         G_ERROR_MSG :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

         INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                CHL_STATUS,
                                                CHL_START_TIMESTAMP,
                                                CHL_END_TIMESTAMP,
                                                CHL_CRON_NAME,
                                                CHL_COMMENTS,
                                                CHL_CREATED_BY)
              VALUES (SEQ_CHL_ID.NEXTVAL,
                      'FAILED',
                      G_START_TIME,
                      SYSDATE,
                      G_PROC_NAME,
                      G_ERROR_MSG,
                      'RC_INV_OUTLET_FWD_ALLOC_PKG');

         G_PROC_NAME := 'RC_INV_OUTLET_FWD_ALLOC_PROC';

         COMMIT;

         RAISE_APPLICATION_ERROR (-20000, SQLERRM);
        
    END RC_INV_OUTLET_FWD_ALLOC_PROC;
    
    PROCEDURE RC_MAIN
    AS
        TRUNC_RMK_INV_MASTER   VARCHAR2 (32767)
            := 'TRUNCATE TABLE RMKTGADM.RC_XXCPO_RMK_INVENTORY_MASTER_BACKUP';
    BEGIN
        EXECUTE IMMEDIATE TRUNC_RMK_INV_MASTER;


        INSERT INTO RC_XXCPO_RMK_INVENTORY_MASTER_BACKUP (
                        INVENTORY_MASTER_ID,
                        PART_NUMBER,
                        AVAILABLE_FGI,
                        NEW_FGI,
                        AVAILABLE_DGI,
                        NEW_DGI,
                        AVAILABLE_TO_RESERVE_FGI,
                        AVAILABLE_TO_RESERVE_DGI,
                        RESERVED_FGI,
                        RESERVED_DGI,
                        SITE_CODE,
                        ROHS_COMPLIANT,
                        AUTO_RESERVATION_FLAG,
                        CREATED_ON,
                        CREATED_BY,
                        UPDATED_ON,
                        UPDATED_BY,
                        PROCESS_NAME,
                        INVENTORY_FLOW)
            (SELECT INVENTORY_MASTER_ID,
                    PART_NUMBER,
                    AVAILABLE_FGI,
                    NEW_FGI,
                    AVAILABLE_DGI,
                    NEW_DGI,
                    AVAILABLE_TO_RESERVE_FGI,
                    AVAILABLE_TO_RESERVE_DGI,
                    RESERVED_FGI,
                    RESERVED_DGI,
                    SITE_CODE,
                    ROHS_COMPLIANT,
                    AUTO_RESERVATION_FLAG,
                    CREATED_ON,
                    CREATED_BY,
                    UPDATED_ON,
                    UPDATED_BY,
                    PROCESS_NAME,
                    INVENTORY_FLOW
               FROM XXCPO_RMK_INVENTORY_MASTER);

        COMMIT;
        RC_INV_OUTLET_FWD_ALLOC_PROC;

        RC_OUTLET_VALIDATION;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            G_ERROR_MSG :=
                   SUBSTR (SQLERRM, 1, 200)
                || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

            INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                   CHL_STATUS,
                                                   CHL_START_TIMESTAMP,
                                                   CHL_END_TIMESTAMP,
                                                   CHL_CRON_NAME,
                                                   CHL_COMMENTS,
                                                   CHL_CREATED_BY)
                 VALUES (SEQ_CHL_ID.NEXTVAL,
                         'FAILED',
                         SYSDATE,
                         SYSDATE,
                         G_PROC_NAME,
                         G_ERROR_MSG,
                         'RC_INV_OUTLET_FWD_ALLOC_PKG');

            G_PROC_NAME := 'RC_INV_OUTLET_FWD_ALLOC_PROC';

            COMMIT;
    END RC_MAIN;

    PROCEDURE RC_OUTLET_VALIDATION
    AS
        COUNT_INV_STG_OUTLET_PIDS   NUMBER;
        COUNT_INV_OUTLET_PIDS       NUMBER;
        SUM_NEW_FGI                 NUMBER;
        O_NEW_FGI_R                 NUMBER;
        O_NEW_FGI_O                 NUMBER;
        O_ALLOC_QTY                 NUMBER;
    BEGIN
        -- Data should be there after executing the above package..
        SELECT COUNT (*)
          INTO COUNT_INV_STG_OUTLET_PIDS
          FROM RMK_INVENTORY_LOG_STG
         WHERE     TRUNC (UPDATED_ON) = TO_DATE (SYSDATE)
               --UPDATED_ON = (SELECT max(updated_on) from RMKTGADM.rmk_inventory_log WHERE POE_BATCH_ID = 'OUTLET_FORWARD_ALLOCATION')
               AND POE_BATCH_ID = 'OUTLET_FORWARD_ALLOCATION';

        -- with the same condition record should not be present in the log table.
        SELECT COUNT (*)
          INTO COUNT_INV_OUTLET_PIDS
          FROM RMK_INVENTORY_LOG
         WHERE     TRUNC (UPDATED_ON) = TO_DATE (SYSDATE)
               --UPDATED_ON = (SELECT max(updated_on) from RMKTGADM.rmk_inventory_log WHERE POE_BATCH_ID = 'OUTLET_FORWARD_ALLOCATION')
               AND POE_BATCH_ID = 'OUTLET_FORWARD_ALLOCATION';

        -- some of new fgi should be zero.
        SELECT NVL (SUM (NEW_FGI), 0)
          INTO SUM_NEW_FGI
          FROM RMK_INVENTORY_LOG_STG
         WHERE     TRUNC (UPDATED_ON) = TO_DATE (SYSDATE)
               --UPDATED_ON = (SELECT max(updated_on) from RMKTGADM.rmk_inventory_log WHERE POE_BATCH_ID = 'OUTLET_FORWARD_ALLOCATION')
               AND POE_BATCH_ID = 'OUTLET_FORWARD_ALLOCATION';

        --- program_type R is -ve O is +ve but both should get same value.
        SELECT NVL (SUM (NEW_FGI), 0)
          INTO O_NEW_FGI_R
          FROM RMK_INVENTORY_LOG_STG
         WHERE     TRUNC (UPDATED_ON) = TO_DATE (SYSDATE)
               ---UPDATED_ON = (SELECT max(updated_on) from RMKTGADM.rmk_inventory_log WHERE POE_BATCH_ID = 'OUTLET_FORWARD_ALLOCATION')
               AND POE_BATCH_ID = 'OUTLET_FORWARD_ALLOCATION'
               AND PROGRAM_TYPE = 'R';

        ---GROUP BY PROGRAM_TYPE;

        SELECT NVL (SUM (NEW_FGI), 0)
          INTO O_NEW_FGI_O
          FROM RMK_INVENTORY_LOG_STG
         WHERE     TRUNC (UPDATED_ON) = TO_DATE (SYSDATE)
               ---UPDATED_ON = (SELECT max(updated_on) from RMKTGADM.rmk_inventory_log WHERE POE_BATCH_ID = 'OUTLET_FORWARD_ALLOCATION')
               AND POE_BATCH_ID = 'OUTLET_FORWARD_ALLOCATION'
               AND PROGRAM_TYPE = 'O';

        ---GROUP BY PROGRAM_TYPE;

        --need to change conditions i.e. fetching latest records --Source table   -- needs to verify this.  We should get some value.
        SELECT SUM (OUTLET_ALLOC_QUANTITY)
          INTO O_ALLOC_QTY
          FROM CRPSC.RC_AE_FGI_REQUIREMENT;

        /*SELECT SUM (AVAILABLE_TO_RESERVE_FGI)
          INTO O_AVAILABLE_TO_RESERVE_FGI
          FROM XXCPO_RMK_INVENTORY_MASTER
         WHERE INVENTORY_FLOW = 'Outlet';*/

        INSERT INTO TEST2 (MESSAGE, UPDATED_ON)
             VALUES ('INSIDE PROC', SYSDATE);

        COMMIT;

        IF (    COUNT_INV_STG_OUTLET_PIDS >= 0
            AND COUNT_INV_OUTLET_PIDS = 0
            AND SUM_NEW_FGI = 0
            AND O_NEW_FGI_R <= 0
            AND O_NEW_FGI_O >= 0
            AND O_ALLOC_QTY >= 0)
        THEN
            INSERT INTO TEST2 (MESSAGE, UPDATED_ON)
                 VALUES ('INSIDE IF', SYSDATE);

            COMMIT;

            INSERT INTO RMKTGADM.RMK_INVENTORY_LOG (INVENTORY_LOG_ID,
                                                    PART_NUMBER,
                                                    NEW_FGI,
                                                    NEW_DGI,
                                                    ROHS_COMPLIANT,
                                                    SITE_CODE,
                                                    PROCESS_STATUS,
                                                    ATTRIBUTE1,
                                                    ATTRIBUTE2,
                                                    UPDATED_ON,
                                                    UPDATED_BY,
                                                    CREATED_ON,
                                                    CREATED_BY,
                                                    POE_BATCH_ID,
                                                    PROGRAM_TYPE)
                (SELECT INVENTORY_LOG_ID,
                        PART_NUMBER,
                        NEW_FGI,
                        NEW_DGI,
                        ROHS_COMPLIANT,
                        SITE_CODE,
                        PROCESS_STATUS,
                        ATTRIBUTE1,
                        ATTRIBUTE2,
                        UPDATED_ON,
                        UPDATED_BY,
                        CREATED_ON,
                        CREATED_BY,
                        POE_BATCH_ID,
                        PROGRAM_TYPE
                   FROM RMK_INVENTORY_LOG_STG
                  WHERE     poe_batch_id LIKE 'OUTLET_FORWARD_ALLOCATION'
                        AND TRUNC (UPDATED_ON) = TO_DATE (SYSDATE));

            ---UPDATED_ON = (SELECT max(updated_on) from RMKTGADM.rmk_inventory_log_STG WHERE POE_BATCH_ID = 'OUTLET_FORWARD_ALLOCATION'));

            COMMIT;

            DELETE FROM RMKTGADM.RMK_INVENTORY_LOG_BACKUP;

            COMMIT;

            INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_BACKUP (INVENTORY_LOG_ID,
                                                           PART_NUMBER,
                                                           NEW_FGI,
                                                           NEW_DGI,
                                                           ROHS_COMPLIANT,
                                                           SITE_CODE,
                                                           PROCESS_STATUS,
                                                           ATTRIBUTE1,
                                                           ATTRIBUTE2,
                                                           UPDATED_ON,
                                                           UPDATED_BY,
                                                           CREATED_ON,
                                                           CREATED_BY,
                                                           POE_BATCH_ID,
                                                           PROGRAM_TYPE)
                (SELECT INVENTORY_LOG_ID,
                        PART_NUMBER,
                        NEW_FGI,
                        NEW_DGI,
                        ROHS_COMPLIANT,
                        SITE_CODE,
                        PROCESS_STATUS,
                        ATTRIBUTE1,
                        ATTRIBUTE2,
                        UPDATED_ON,
                        UPDATED_BY,
                        CREATED_ON,
                        CREATED_BY,
                        POE_BATCH_ID,
                        PROGRAM_TYPE
                   FROM RMK_INVENTORY_LOG
                  WHERE     TRUNC (UPDATED_ON) = TO_DATE (SYSDATE)
                        ---UPDATED_ON = (SELECT max(updated_on) from RMKTGADM.rmk_inventory_log WHERE POE_BATCH_ID = 'OUTLET_FORWARD_ALLOCATION')
                        AND POE_BATCH_ID LIKE 'OUTLET_FORWARD_ALLOCATION');

            COMMIT;

            UPDATE RMKTGADM.RMK_INVENTORY_LOG_STG
               SET ATTRIBUTE1 = 'PROCESSED'
             WHERE TRUNC (UPDATED_ON) = TO_DATE (SYSDATE);

            ---UPDATED_ON = (SELECT max(updated_on) from RMKTGADM.rmk_inventory_log WHERE POE_BATCH_ID = 'OUTLET_FORWARD_ALLOCATION');

            COMMIT;

            RC_OUTLET_VERIFICATION_SCRIPT;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            v_message := SUBSTR (SQLERRM, 1, 200);

            INSERT INTO OUTLET_ERROR_LOG (module_name,
                                          ERROR_TYPE,
                                          Error_Message,
                                          created_by,
                                          created_on,
                                          package_name)
                     VALUES (
                                'RC_OUTLET_VALIDATION',
                                'EXCEPTION',
                                   'Error while executing RC_OUTLET_VALIDATION'
                                || v_message
                                || ' LineNo=> '
                                || DBMS_UTILITY.Format_error_backtrace,
                                'RC_OUTLET_VALIDATION',
                                SYSDATE,
                                'RC_INV_OUTLET_FWD_ALLOC_PKG');

            COMMIT;
    END RC_OUTLET_VALIDATION;

    PROCEDURE RC_OUTLET_VERIFICATION_SCRIPT
    AS
        TRUNC_OUTLET_VERIFICATION   VARCHAR2 (32767)
            := 'TRUNCATE TABLE RMKTGADM.RC_OUTLET_VERIFICATION';
    BEGIN
        EXECUTE IMMEDIATE TRUNC_OUTLET_VERIFICATION;

        INSERT INTO RMKTGADM.RC_OUTLET_VERIFICATION (REFRESH_PART_NUMBER,
                                                     outlet_alloc_quantity,
                                                     BC_total_retail,
                                                     BC_total_outlet,
                                                     AC_total_retail,
                                                     AC_total_outlet,
                                                     BC_LRO_ROHS_RETAIL,
                                                     BC_LRO_NROHS_RETAIL,
                                                     BC_FVE_ROHS_RETAIL,
                                                     BC_LRO_ROHS_OUTLET,
                                                     BC_LRO_NROHS_OUTLET,
                                                     BC_FVE_ROHS_OUTLET,
                                                     AC_LRO_ROHS_RETAIL,
                                                     AC_LRO_NROHS_RETAIL,
                                                     AC_FVE_ROHS_RETAIL,
                                                     AC_LRO_ROHS_OUTLET,
                                                     AC_LRO_NROHS_OUTLET,
                                                     AC_FVE_ROHS_OUTLET)
            (SELECT refresh_part_number,
                    outlet_alloc_quantity,
                      BC_LRO_ROHS_RETAIL
                    + BC_LRO_NROHS_RETAIl
                    + BC_FVE_ROHS_RETAIL    BC_total_retail,
                      BC_LRO_ROHS_outlet
                    + BC_LRO_NROHS_outlet
                    + BC_FVE_ROHS_OUTLET    BC_total_outlet,
                      AC_LRO_ROHS_retail
                    + aC_LRO_NROHS_retail
                    + aC_FVE_ROHS_retail    AC_total_retail,
                      AC_LRO_ROHS_outlet
                    + AC_LRO_NROHS_outlet
                    + aC_FVE_ROHS_OUTLET    AC_total_outlet,
                    BC_LRO_ROHS_RETAIL,
                    BC_LRO_NROHS_RETAIL,
                    BC_FVE_ROHS_RETAIL,
                    BC_LRO_ROHS_OUTLET,
                    BC_LRO_NROHS_OUTLET,
                    BC_FVE_ROHS_OUTLET,
                    AC_LRO_ROHS_RETAIL,
                    AC_LRO_NROHS_RETAIL,
                    AC_FVE_ROHS_RETAIL,
                    AC_LRO_ROHS_OUTLET,
                    AC_LRO_NROHS_OUTLET,
                    AC_FVE_ROHS_OUTLET
               FROM (SELECT refresh_part_number,
                            outlet_alloc_quantity,
                            NVL (
                                (SELECT available_to_reserve_fgi
                                   FROM RC_XXCPO_RMK_INVENTORY_MASTER_BACKUP
                                        xxcpo
                                  WHERE     xxcpo.part_number =
                                            alloc.refresh_part_number
                                        AND xxcpo.inventory_flow = 'Retail'
                                        AND xxcpo.site_code = 'LRO'
                                        AND xxcpo.rohs_compliant = 'YES'),
                                0)      BC_LRO_ROHS_Retail,
                            NVL (
                                (SELECT available_to_reserve_fgi
                                   FROM RC_XXCPO_RMK_INVENTORY_MASTER_BACKUP
                                        xxcpo
                                  WHERE     xxcpo.part_number =
                                            alloc.refresh_part_number
                                        AND xxcpo.inventory_flow = 'Retail'
                                        AND xxcpo.site_code = 'LRO'
                                        AND xxcpo.rohs_compliant = 'NO'),
                                0)      BC_LRO_NROHS_Retail,
                            NVL (
                                (SELECT available_to_reserve_fgi
                                   FROM RC_XXCPO_RMK_INVENTORY_MASTER_BACKUP
                                        xxcpo
                                  WHERE     xxcpo.part_number =
                                            alloc.refresh_part_number
                                        AND xxcpo.inventory_flow = 'Retail'
                                        AND xxcpo.site_code = 'FVE'
                                        AND xxcpo.rohs_compliant = 'YES'),
                                0)      BC_FVE_ROHS_Retail,
                            NVL (
                                (SELECT available_to_reserve_fgi
                                   FROM RC_XXCPO_RMK_INVENTORY_MASTER_BACKUP
                                        xxcpo
                                  WHERE     xxcpo.part_number =
                                            alloc.refresh_part_number
                                        AND xxcpo.inventory_flow = 'Outlet'
                                        AND xxcpo.site_code = 'LRO'
                                        AND xxcpo.rohs_compliant = 'YES'),
                                0)      BC_LRO_ROHS_Outlet,
                            NVL (
                                (SELECT available_to_reserve_fgi
                                   FROM RC_XXCPO_RMK_INVENTORY_MASTER_BACKUP
                                        xxcpo
                                  WHERE     xxcpo.part_number =
                                            alloc.refresh_part_number
                                        AND xxcpo.inventory_flow = 'Outlet'
                                        AND xxcpo.site_code = 'LRO'
                                        AND xxcpo.rohs_compliant = 'NO'),
                                0)      BC_LRO_NROHS_Outlet,
                            NVL (
                                (SELECT available_to_reserve_fgi
                                   FROM RC_XXCPO_RMK_INVENTORY_MASTER_BACKUP
                                        xxcpo
                                  WHERE     xxcpo.part_number =
                                            alloc.refresh_part_number
                                        AND xxcpo.inventory_flow = 'Outlet'
                                        AND xxcpo.site_code = 'FVE'
                                        AND xxcpo.rohs_compliant = 'YES'),
                                0)      BC_FVE_ROHS_Outlet,
                              NVL (
                                  (SELECT available_to_reserve_fgi
                                     FROM RC_XXCPO_RMK_INVENTORY_MASTER_BACKUP
                                          xxcpo
                                    WHERE     xxcpo.part_number =
                                              alloc.refresh_part_number
                                          AND xxcpo.inventory_flow = 'Retail'
                                          AND xxcpo.site_code = 'LRO'
                                          AND xxcpo.rohs_compliant = 'YES'),
                                  0)
                            + NVL (
                                  (SELECT SUM (new_fgi)
                                     FROM RMK_INVENTORY_LOG_BACKUP log1
                                    WHERE     log1.part_number =
                                              alloc.refresh_part_number
                                          AND log1.program_type = 'R'
                                          AND log1.site_code = 'LRO'
                                          AND log1.rohs_compliant = 'YES'),
                                  0)    AC_LRO_ROHS_Retail,
                              NVL (
                                  (SELECT available_to_reserve_fgi
                                     FROM RC_XXCPO_RMK_INVENTORY_MASTER_BACKUP
                                          xxcpo
                                    WHERE     xxcpo.part_number =
                                              alloc.refresh_part_number
                                          AND xxcpo.inventory_flow = 'Retail'
                                          AND xxcpo.site_code = 'LRO'
                                          AND xxcpo.rohs_compliant = 'NO'),
                                  0)
                            + NVL (
                                  (SELECT SUM (new_fgi)
                                     FROM RMK_INVENTORY_LOG_BACKUP log1
                                    WHERE     log1.part_number =
                                              alloc.refresh_part_number
                                          AND log1.program_type = 'R'
                                          AND log1.site_code = 'LRO'
                                          AND log1.rohs_compliant = 'NO'),
                                  0)    AC_LRO_NROHS_Retail,
                              NVL (
                                  (SELECT available_to_reserve_fgi
                                     FROM RC_XXCPO_RMK_INVENTORY_MASTER_BACKUP
                                          xxcpo
                                    WHERE     xxcpo.part_number =
                                              alloc.refresh_part_number
                                          AND xxcpo.inventory_flow = 'Retail'
                                          AND xxcpo.site_code = 'FVE'
                                          AND xxcpo.rohs_compliant = 'YES'),
                                  0)
                            + NVL (
                                  (SELECT SUM (new_fgi)
                                     FROM RMK_INVENTORY_LOG_BACKUP log1
                                    WHERE     log1.part_number =
                                              alloc.refresh_part_number
                                          AND log1.program_type = 'R'
                                          AND log1.site_code = 'FVE'
                                          AND log1.rohs_compliant = 'YES'),
                                  0)    AC_FVE_ROHS_Retail,
                              NVL (
                                  (SELECT available_to_reserve_fgi
                                     FROM RC_XXCPO_RMK_INVENTORY_MASTER_BACKUP
                                          xxcpo
                                    WHERE     xxcpo.part_number =
                                              alloc.refresh_part_number
                                          AND xxcpo.inventory_flow = 'Outlet'
                                          AND xxcpo.site_code = 'LRO'
                                          AND xxcpo.rohs_compliant = 'YES'),
                                  0)
                            + NVL (
                                  (SELECT SUM (new_fgi)
                                     FROM RMK_INVENTORY_LOG_BACKUP log1
                                    WHERE     log1.part_number =
                                              alloc.refresh_part_number
                                          AND log1.program_type = 'O'
                                          AND log1.site_code = 'LRO'
                                          AND log1.rohs_compliant = 'YES'),
                                  0)    AC_LRO_ROHS_Outlet,
                              NVL (
                                  (SELECT available_to_reserve_fgi
                                     FROM RC_XXCPO_RMK_INVENTORY_MASTER_BACKUP
                                          xxcpo
                                    WHERE     xxcpo.part_number =
                                              alloc.refresh_part_number
                                          AND xxcpo.inventory_flow = 'Outlet'
                                          AND xxcpo.site_code = 'LRO'
                                          AND xxcpo.rohs_compliant = 'NO'),
                                  0)
                            + NVL (
                                  (SELECT SUM (new_fgi)
                                     FROM RMK_INVENTORY_LOG_BACKUP log1
                                    WHERE     log1.part_number =
                                              alloc.refresh_part_number
                                          AND log1.program_type = 'O'
                                          AND log1.site_code = 'LRO'
                                          AND log1.rohs_compliant = 'NO'),
                                  0)    AC_LRO_NROHS_Outlet,
                              NVL (
                                  (SELECT available_to_reserve_fgi
                                     FROM RC_XXCPO_RMK_INVENTORY_MASTER_BACKUP
                                          xxcpo
                                    WHERE     xxcpo.part_number =
                                              alloc.refresh_part_number
                                          AND xxcpo.inventory_flow = 'Outlet'
                                          AND xxcpo.site_code = 'FVE'
                                          AND xxcpo.rohs_compliant = 'YES'),
                                  0)
                            + NVL (
                                  (SELECT SUM (new_fgi)
                                     FROM RMK_INVENTORY_LOG_BACKUP log1
                                    WHERE     log1.part_number =
                                              alloc.refresh_part_number
                                          AND log1.program_type = 'O'
                                          AND log1.site_code = 'FVE'
                                          AND log1.rohs_compliant = 'YES'),
                                  0)    AC_FVE_ROHS_Outlet
                       FROM CRPSC.RC_AE_FGI_REQUIREMENT alloc
                      WHERE NVL (outlet_alloc_quantity, 0) <> 0));

        COMMIT;
    END RC_OUTLET_VERIFICATION_SCRIPT;

    PROCEDURE RC_CCW_DATA_UPDATE
    AS
        RC_CCW_DATA_COUNT        NUMBER;
        RC_OUTLET_COUNT          NUMBER;
        RC_OUT_RETAIL_COUNT      NUMBER;
        RC_OUTLET_FG_COUNT       NUMBER;
        RC_OUT_RETAIL_FG_COUNT   NUMBER;
        OUTLET_QTY               NUMBER;
        TOTAL_OUTLET_QTY         NUMBER;
        email_msg_from           VARCHAR2 (100)
                                     := 'refreshcentral-support@cisco.com';
        email_receipient         VARCHAR2 (100) := 'refreshcentral-support@cisco.com';
        email_msg_subject        VARCHAR2 (32767);
        email_msg_body           VARCHAR2 (32767);
        TRUNC_RMK_INV_MASTER     VARCHAR2 (32767)
            := 'TRUNCATE TABLE RMKTGADM.xxcpo_rmk_inventory_master_aft_fwd';
    BEGIN
        SELECT SUM (OUTLET_ALLOC_QUANTITY), SUM (AC_TOTAL_OUTLET)
          INTO OUTLET_QTY, TOTAL_OUTLET_QTY
          FROM RC_OUTLET_VERIFICATION;

        EXECUTE IMMEDIATE TRUNC_RMK_INV_MASTER;

        INSERT INTO logger
             VALUES ('start of ccw_update', SYSDATE);

        COMMIT;

        INSERT INTO xxcpo_rmk_inventory_master_aft_fwd (
                        INVENTORY_MASTER_ID,
                        PART_NUMBER,
                        AVAILABLE_FGI,
                        NEW_FGI,
                        AVAILABLE_DGI,
                        NEW_DGI,
                        AVAILABLE_TO_RESERVE_FGI,
                        AVAILABLE_TO_RESERVE_DGI,
                        RESERVED_FGI,
                        RESERVED_DGI,
                        SITE_CODE,
                        ROHS_COMPLIANT,
                        AUTO_RESERVATION_FLAG,
                        CREATED_ON,
                        CREATED_BY,
                        UPDATED_ON,
                        UPDATED_BY,
                        PROCESS_NAME,
                        INVENTORY_FLOW)
            (SELECT INVENTORY_MASTER_ID,
                    PART_NUMBER,
                    AVAILABLE_FGI,
                    NEW_FGI,
                    AVAILABLE_DGI,
                    NEW_DGI,
                    AVAILABLE_TO_RESERVE_FGI,
                    AVAILABLE_TO_RESERVE_DGI,
                    RESERVED_FGI,
                    RESERVED_DGI,
                    SITE_CODE,
                    ROHS_COMPLIANT,
                    AUTO_RESERVATION_FLAG,
                    CREATED_ON,
                    CREATED_BY,
                    UPDATED_ON,
                    UPDATED_BY,
                    PROCESS_NAME,
                    INVENTORY_FLOW
               FROM XXCPO_RMK_INVENTORY_MASTER);

        COMMIT;


        IF (OUTLET_QTY >= TOTAL_OUTLET_QTY)
        THEN
            SELECT COUNT (*)
              INTO RC_CCW_DATA_COUNT
              FROM xxcpo_rmk_inventory_master im
             WHERE     inventory_flow = 'Outlet'
                   AND available_to_reserve_fgi > 0
                   AND part_number IN (SELECT RF_PID
                                         FROM RC_OUTLET_PIDS outlet ---NEED TO CHANGE THE TABLENAME AS PER THE CHANGE IN GLOBAL UPLOADER
                                        WHERE outlet.RF_PID = im.part_number);

              SELECT NVL (SUM (NEW_FGI), 0)
                INTO RC_OUTLET_COUNT
                FROM xxcpo_rmk_inventory_master
               WHERE inventory_flow = 'Outlet'
            ORDER BY updated_on DESC;

              SELECT NVL (SUM (NEW_FGI), 0)
                INTO RC_OUT_RETAIL_COUNT
                FROM xxcpo_rmk_inventory_master
               WHERE inventory_flow IN ('Outlet', 'Retail') AND new_fgi <> 0
            ORDER BY updated_on DESC;

              SELECT NVL (SUM (NEW_FGI), 0)
                INTO RC_OUTLET_FG_COUNT
                FROM xxcpo_rmk_inventory_master
               WHERE inventory_flow = 'Outlet' AND new_fgi < 0
            ORDER BY updated_on DESC;

              SELECT NVL (SUM (NEW_FGI), 0)
                INTO RC_OUT_RETAIL_FG_COUNT
                FROM xxcpo_rmk_inventory_master
               WHERE inventory_flow = 'Retail' AND new_fgi > 0
            ORDER BY updated_on DESC;

            IF (    RC_CCW_DATA_COUNT > 0
                AND RC_OUTLET_COUNT = 0
                AND RC_OUT_RETAIL_COUNT = 0
                AND RC_OUTLET_FG_COUNT = 0
                AND RC_OUT_RETAIL_FG_COUNT = 0)
            THEN
                RC_EXCLUDE_OUTLET_ALLOC_PROC;

                INSERT INTO RMK_INVENTORY_LOG
                    SELECT *
                      FROM RMK_INVENTORY_LOG_STG
                     WHERE     ATTRIBUTE1 IS NULL
                           AND POE_BATCH_ID LIKE
                                   '%Do Not Allocate to Outlet%';

                COMMIT;


                UPDATE RMK_INVENTORY_LOG_STG
                   SET ATTRIBUTE1 = 'PROCESSED'
                 WHERE     ATTRIBUTE1 IS NULL
                       AND POE_BATCH_ID LIKE '%Do Not Allocate to Outlet%';

                email_msg_subject :=
                    'DELTA OUTLET FOR ' || SYSDATE || ' IS COMPLETED';
                email_msg_body :=
                       '<body>
                          Hi Team,<br><br>
                          Delta outlet is executed for '
                    || SYSDATE
                    || '                          
                               <br><br>                          
                          Thanks<br>
                          Cisco Refresh Team</body>';

                BEGIN
                    crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (
                        email_msg_from,
                        email_receipient,
                        email_msg_subject,
                        email_msg_body,
                        NULL,
                        NULL);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        v_message := SUBSTR (SQLERRM, 1, 50);
                END;
            ELSE
                IF (    RC_CCW_DATA_COUNT = 0
                    AND RC_OUTLET_COUNT = 0
                    AND RC_OUT_RETAIL_COUNT = 0
                    AND RC_OUTLET_FG_COUNT = 0
                    AND RC_OUT_RETAIL_FG_COUNT = 0)
                THEN
                    email_msg_subject :=
                           'DELTA OUTLET FOR '
                        || SYSDATE
                        || ' IS COMPLETED';
                    email_msg_body :=
                           '<body>
                          Hi Team,<br><br>
                          Delta outlet is executed for '
                        || SYSDATE
                        || '                          
                               <br><br>                          
                          Thanks<br>
                          Cisco Refresh Team</body>';

                    BEGIN
                        crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (
                            email_msg_from,
                            email_receipient,
                            email_msg_subject,
                            email_msg_body,
                            NULL,
                            NULL);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            v_message := SUBSTR (SQLERRM, 1, 50);
                    END;
                ELSE
                    email_msg_subject :=
                           'DELTA OUTLET FOR'
                        || SYSDATE
                        || 'IS NOT COMPLETED';
                    email_msg_body :=
                           '<body>
                          Hi Team,<br><br>
                          Delta outlet is executed with errors for'
                        || SYSDATE
                        || ' Kindly verify whether CCW table is updated or not                                            
                               <br><br>                          
                          Thanks<br>
                          Cisco Refresh Team</body>';

                    BEGIN
                        crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (
                            email_msg_from,
                            email_receipient,
                            email_msg_subject,
                            email_msg_body,
                            NULL,
                            NULL);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            v_message := SUBSTR (SQLERRM, 1, 50);
                    END;
                END IF;
            END IF;
        ELSE
            email_msg_subject :=
                'OUTLET ALLOCATION QUANTITY IS LESS THAN OUTLET INVENTORY';
            email_msg_body :=
                '<body>
                          Hi Team,<br><br>
                          There is a mismatch in outlet allocation quantity and total outlet quantity<br>
                          Kindly check RC_OUTLET_VERIFICATION table and process them manually.
                               <br><br>                          
                          Thanks<br>
                          Cisco Refresh Team</body>';

            BEGIN
                crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (
                    email_msg_from,
                    email_receipient,
                    email_msg_subject,
                    email_msg_body,
                    NULL,
                    NULL);
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_message := SUBSTR (SQLERRM, 1, 50);
            END;
        END IF;

        INSERT INTO logger
             VALUES ('end of ccw_update', SYSDATE);

        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            G_ERROR_MSG :=
                   SUBSTR (SQLERRM, 1, 200)
                || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

            INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                   CHL_STATUS,
                                                   CHL_START_TIMESTAMP,
                                                   CHL_END_TIMESTAMP,
                                                   CHL_CRON_NAME,
                                                   CHL_COMMENTS,
                                                   CHL_CREATED_BY)
                 VALUES (SEQ_CHL_ID.NEXTVAL,
                         'FAILED',
                         SYSDATE,
                         SYSDATE,
                         G_PROC_NAME,
                         G_ERROR_MSG,
                         'RC_CCW_DATA_UPDATE');

            G_PROC_NAME := 'RC_CCW_DATA_UPDATE';

            COMMIT;
    END RC_CCW_DATA_UPDATE;

    PROCEDURE RC_EXCLUDE_OUTLET_ALLOC_PROC
    IS
        CURSOR REV_OUTLET IS
            SELECT *
              FROM xxcpo_rmk_inventory_master im
             WHERE     inventory_flow = 'Outlet'
                   AND available_to_reserve_fgi > 0
                   AND part_number IN (SELECT part_number
                                         FROM RC_OUTLET_PIDS outlet
                                        WHERE outlet.RF_PID = im.part_number);

        REV_OUT        REV_OUTLET%ROWTYPE;
        G_START_TIME   DATE;
        G_ERROR_MSG    VARCHAR2 (32767);
        G_PROC_NAME    VARCHAR2 (100);
    BEGIN
        SELECT SYSDATE INTO G_START_TIME FROM DUAL;

        DELETE FROM RMKTGADM.REV_OUTLET_ALLOC;

        DELETE FROM RMKTGADM.RC_INV_REVERSE_OUTLET;

        COMMIT;

        OPEN REV_OUTLET;

        LOOP
            FETCH REV_OUTLET INTO REV_OUT;

            EXIT WHEN REV_OUTLET%NOTFOUND;

            INSERT INTO RMKTGADM.REV_OUTLET_ALLOC
                 VALUES (REV_OUT.PART_NUMBER,
                         REV_OUT.AVAILABLE_TO_RESERVE_FGI,
                         REV_OUT.SITE_CODE,
                         REV_OUT.ROHS_COMPLIANT,
                         REV_OUT.INVENTORY_FLOW);

            INSERT INTO RMKTGADM.RC_INV_REVERSE_OUTLET (INVENTORY_LOG_ID,
                                                        PART_NUMBER,
                                                        NEW_FGI,
                                                        NEW_DGI,
                                                        ROHS_COMPLIANT,
                                                        SITE_CODE,
                                                        PROCESS_STATUS,
                                                        UPDATED_ON,
                                                        UPDATED_BY,
                                                        CREATED_ON,
                                                        CREATED_BY,
                                                        POE_BATCH_ID,
                                                        PROGRAM_TYPE)
                 VALUES (RC_INV_LOG_PK_SEQ.NEXTVAL,
                         REV_OUT.part_number,
                         REV_OUT.Available_To_Reserve_FGI,
                         0,
                         REV_OUT.Rohs_Compliant,
                         REV_OUT.Site_Code,
                         'N',
                         SYSDATE,
                         'POEADMIN',
                         SYSDATE,
                         'POEADMIN',
                         'Do Not Allocate to Outlet' || SYSDATE,
                         'R');

            INSERT INTO RMKTGADM.RC_INV_REVERSE_OUTLET (INVENTORY_LOG_ID,
                                                        PART_NUMBER,
                                                        NEW_FGI,
                                                        NEW_DGI,
                                                        ROHS_COMPLIANT,
                                                        SITE_CODE,
                                                        PROCESS_STATUS,
                                                        UPDATED_ON,
                                                        UPDATED_BY,
                                                        CREATED_ON,
                                                        CREATED_BY,
                                                        POE_BATCH_ID,
                                                        PROGRAM_TYPE)
                 VALUES (RC_INV_LOG_PK_SEQ.NEXTVAL,
                         REV_OUT.part_number,
                         REV_OUT.Available_To_Reserve_FGI * -1,
                         0,
                         REV_OUT.Rohs_Compliant,
                         REV_OUT.Site_Code,
                         'N',
                         SYSDATE,
                         'POEADMIN',
                         SYSDATE,
                         'POEADMIN',
                         'Do Not Allocate to Outlet' || SYSDATE,
                         'O');
        END LOOP;

        CLOSE REV_OUTLET;

        INSERT INTO RMKTGADM.RC_INV_REVERSE_OUTLET_HIST
            SELECT * FROM RMKTGADM.RC_INV_REVERSE_OUTLET;


        INSERT INTO RMKTGADM.RMK_INVENTORY_LOG_STG
            SELECT * FROM RMKTGADM.RC_INV_REVERSE_OUTLET;

        --      --to Insert the Delta inv into  rmk_inventory_log from  rmk_inventory_log_stg
        --      INSERT INTO RMK_INVENTORY_LOG
        --         SELECT *
        --           FROM RMK_INVENTORY_LOG_STG
        --          WHERE ATTRIBUTE1 IS NULL AND POE_BATCH_ID = 'Do Not Allocate to Outlet Q4M1 MF 08-May-19';
        --
        --      --Updating the rmk_inventory_log_stg table after processing the Delta Inv.
        --      UPDATE RMK_INVENTORY_LOG_STG
        --         SET ATTRIBUTE1 = 'PROCESSED'
        --       WHERE ATTRIBUTE1 IS NULL AND POE_BATCH_ID = 'Do Not Allocate to Outlet Q4M1 MF 08-May-19';

        COMMIT;

        INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                               CHL_STATUS,
                                               CHL_START_TIMESTAMP,
                                               CHL_END_TIMESTAMP,
                                               CHL_CRON_NAME,
                                               CHL_COMMENTS,
                                               CHL_CREATED_BY)
             VALUES (SEQ_CHL_ID.NEXTVAL,
                     'SUCCESS',
                     G_START_TIME,
                     SYSDATE,
                     'RC_EXCLUDE_OUTLET_ALLOC_PROC',
                     NULL,
                     'RC_EXCLUDE_OUTLET_ALLOC_PROC');

        G_PROC_NAME := 'RC_EXCLUDE_OUTLET_ALLOC_PROC';
        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            G_ERROR_MSG :=
                   SUBSTR (SQLERRM, 1, 200)
                || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);

            INSERT INTO RMKTGADM.CRON_HISTORY_LOG (CHL_ID,
                                                   CHL_STATUS,
                                                   CHL_START_TIMESTAMP,
                                                   CHL_END_TIMESTAMP,
                                                   CHL_CRON_NAME,
                                                   CHL_COMMENTS,
                                                   CHL_CREATED_BY)
                 VALUES (SEQ_CHL_ID.NEXTVAL,
                         'FAILED',
                         G_START_TIME,
                         SYSDATE,
                         G_PROC_NAME,
                         G_ERROR_MSG,
                         'RC_EXCLUDE_OUTLET_ALLOC_PROC');

            --  G_PROC_NAME := 'RC_EXCLUDE_OUTLET_ALLOC_PROC';

            COMMIT;
    END RC_EXCLUDE_OUTLET_ALLOC_PROC;

    PROCEDURE RC_DELTA_OUTLET_TEMPLATE (
        o_delta_excel_list   OUT RC_DELTA_OUTLET_LIST)
    IS
        lv_delta_excel_list   RC_DELTA_OUTLET_LIST;
        lv_errm               VARCHAR2 (400);
        lv_query              VARCHAR2 (32000);
    BEGIN
        INSERT INTO logger
             VALUES ('start of rc_delta_outlet', SYSDATE);

        COMMIT;
        lv_delta_excel_list := RC_DELTA_OUTLET_LIST ();

        lv_query := 'SELECT RC_DELTA_OUTLET_OBJ (RF_PID)
        FROM (SELECT RF_PID                
          FROM RMKTGADM.RC_OUTLET_PIDS1)';

        EXECUTE IMMEDIATE lv_query
            BULK COLLECT INTO lv_delta_excel_list;

        o_delta_excel_list := lv_delta_excel_list;

        INSERT INTO logger
             VALUES ('end of rc_delta_outlet', SYSDATE);

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            lv_errm := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
            CRPADM.RC_GLOBAL_ERROR_LOGGING (
                'NO DATA FOUND',
                lv_errm,
                NULL,
                'RMKTGADM.RC_INV_OUTLET_FWD_ALLOC_PKG.RC_DELTA_OUTLET_TEMPLATE',
                'PACKAGE',
                NULL,
                'N');
        WHEN OTHERS
        THEN
            lv_errm := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
            CRPADM.RC_GLOBAL_ERROR_LOGGING (
                'OTHERS',
                lv_errm,
                NULL,
                'RMKTGADM.RC_INV_OUTLET_FWD_ALLOC_PKG.RC_DELTA_OUTLET_TEMPLATE',
                'PACKAGE',
                NULL,
                'Y');
    END;

    PROCEDURE RC_DELTA_OUTLET_PIDS_UPLOAD (
        i_user_id             IN VARCHAR2,
        i_upload_id           IN NUMBER,
        i_delta_outlet_pids   IN RC_DELTA_OUTLET_LIST)
    IS
        lv_delta_outlet_pids   RC_DELTA_OUTLET_LIST;
        lv_errm                VARCHAR2 (400);
        lv_valid_count         NUMBER;
        lv_err_count           NUMBER;        
        CUSTOM_EXCEPTION       EXCEPTION;
        PRAGMA EXCEPTION_INIT (CUSTOM_EXCEPTION, -20001);
        TRUNC_RC_OUTLET_PIDS   VARCHAR2 (32767)
            := 'TRUNCATE TABLE RMKTGADM.RC_OUTLET_PIDS';
    BEGIN
        INSERT INTO logger
             VALUES ('start of upload', SYSDATE);

        EXECUTE IMMEDIATE TRUNC_RC_OUTLET_PIDS;

        lv_delta_outlet_pids := RC_DELTA_OUTLET_LIST ();
        lv_delta_outlet_pids := i_delta_outlet_pids;
        lv_err_count := 1;

        FOR IDX IN 1 .. lv_delta_outlet_pids.COUNT
        LOOP
            lv_valid_count := 0;

            INSERT INTO RC_OUTLET_PIDS (RF_PID, UPLOAD_DATE)
                 VALUES (lv_delta_outlet_pids (IDX).RF_PID, SYSDATE);

            COMMIT;
        --lv_outlet_obj :=
        --RC_OUTLET_OBJ (
        --lv_delta_outlet_pids (IDX).RF_PID);
        ---lv_outlet_list.EXTEND ();
        --lv_outlet_list (idx) :=
        --lv_outlet_obj;
        ---lv_err_count := lv_err_count + 1;


        END LOOP;


        DELTA_OUTLET_PIDS_EMAIL (i_upload_id);

        INSERT INTO logger
             VALUES ('end of upload', SYSDATE);
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            lv_errm := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

            CRPADM.RC_GLOBAL_ERROR_LOGGING (
                'NO DATA FOUND',
                lv_errm,
                NULL,
                'RMKTGADM.RC_INV_OUTLET_FWD_ALLOC_PKG.RC_DELTA_OUTLET_PIDS_UPLOAD',
                'PACKAGE',
                i_user_id,
                'N');
            RAISE_APPLICATION_ERROR (-20001, lv_errm);
        WHEN OTHERS
        THEN
            lv_errm := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

            CRPADM.RC_GLOBAL_ERROR_LOGGING (
                'OTHERS',
                lv_errm,
                NULL,
                'RMKTGADM.RC_INV_OUTLET_FWD_ALLOC_PKG.RC_DELTA_OUTLET_PIDS_UPLOAD',
                'PACKAGE',
                i_user_id,
                'Y');
            RAISE_APPLICATION_ERROR (-20001, lv_errm);
    END;

    PROCEDURE DELTA_OUTLET_PIDS_EMAIL (i_uploadId IN NUMBER)
    AS
        lv_username        VARCHAR2 (100);
        lv_uploadId        NUMBER;
        lv_msg_subject     VARCHAR2 (32767);
        lv_msg_text        VARCHAR2 (32767);
        lv_msg_body        VARCHAR2 (32767);
        lv_output_hdr      LONG;
        lv_mailhost        VARCHAR2 (100) := 'outbound.cisco.com';
        lv_conn            UTL_SMTP.CONNECTION;
        lv_message_type    VARCHAR2 (100) := 'text/html; charset="iso-8859-1"';
        lv_crlf            VARCHAR2 (5) := CHR (13) || CHR (10);
        lv_count           NUMBER := 0;
        lv_output          LONG;
        lv_database_name   VARCHAR2 (50);
        lv_msg_from        VARCHAR2 (100);
        lv_msg_to          VARCHAR2 (100) := 'refreshcentral-support@cisco.com';
        lv_upload_date     DATE;
        refresh_pid        VARCHAR2 (100);
        lv_user_id         VARCHAR2 (100);
    BEGIN
        lv_uploadId := i_uploadId;

        SELECT ora_database_name INTO lv_database_name FROM DUAL;

        SELECT UPDATED_BY, USER_NAME, USER_EMAIL
          INTO lv_user_id, lv_username, lv_msg_to
          FROM CRPADM.RC_GU_PRODUCT_REFRESH_SETUP
         WHERE UPLOAD_ID = lv_uploadId;

          SELECT COUNT (RF_PID), UPLOAD_DATE
            INTO REFRESH_PID, LV_UPLOAD_DATE
            FROM RC_OUTLET_PIDS
        GROUP BY upload_date;

        lv_msg_from := 'refreshcentral-support@cisco.com';

        IF (REFRESH_PID <= 0)
        THEN
            lv_msg_subject :=
                   'Delta Outlet Pids - Processing completed with exception for Upload Id: '
                || lv_uploadId;
            lv_msg_body :=
                'Processing is failed because there are no records in the file, please upload the file with atleast one record and try again.';
        ELSE
            lv_msg_subject :=
                   'Delta Outlet Pids - Processing completed successfully for Upload Id: '
                || lv_uploadId;
            lv_msg_body :=
                'Processing completed successfully, please check the attachment for more details.';
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
            || lv_msg_body
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


        -- Attachment Part
        IF (REFRESH_PID > 0)
        THEN
            UTL_SMTP.WRITE_DATA (lv_conn, '--SECBOUND' || lv_crlf);
            UTL_SMTP.WRITE_DATA (
                lv_conn,
                   'Content-Type: text/plain;'
                || lv_crlf
                || ' name="DoNotAllocatetoOutlet.xls"'
                || lv_crlf
                || 'Content-Transfer_Encoding: 8bit'
                || lv_crlf
                || 'Content-Disposition: attachment;'
                || lv_crlf
                || ' filename= "DoNotAllocateToOutlet.xls"'
                || lv_crlf
                || lv_crlf);

            lv_output_hdr := 'RF PID' || CHR (10);

            FOR rec IN (SELECT RF_PID FROM RC_OUTLET_PIDS)
            LOOP
                IF lv_count = 0
                THEN
                    lv_output := lv_output_hdr || REC.RF_PID || CHR (10);
                    lv_count := lv_count + 1;
                ELSE
                    lv_output := REC.RF_PID || CHR (10);
                END IF;

                UTL_SMTP.WRITE_DATA (lv_conn, lv_output);
            END LOOP;
        -- UTL_SMTP.WRITE_DATA (lv_conn, lv_output);
        ELSE
            BEGIN
                crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (
                    lv_msg_from,
                    lv_msg_to,
                    lv_msg_subject,
                    lv_msg_body,
                    NULL,
                    NULL);
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_message := SUBSTR (SQLERRM, 1, 50);
            END;
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
            CRPADM.RC_GLOBAL_ERROR_LOGGING ('OTHERS',
                                            g_error_msg,
                                            NULL,
                                            'DELTA_OUTLET_PIDS_EMAIL',
                                            'PROCEDURE',
                                            NULL,
                                            'N');
    END;
    
END  RC_INV_OUTLET_FWD_ALLOC_PKG;
/