CREATE OR REPLACE PACKAGE BODY CRPSC.SC_FB02_FVE_R_HIST_DELTA_CALC
AS
   /**********************************************************************************************
            || Object Name     : SC_FB02_FVE_HIST_DELTA_CALC
            || Modification History
            ||
            ||-----------------------------------------------------------------------------------------
            ||Date                       By            Version        Comments
            ||-----------------------------------------------------------------------------------------
            || 29-FEB-2016          bsunitha, aradhkum          1.0         Created procedures for FB02 history population and Delta calculation
            || 31-MAR-2016          bsunitha, aradhkum        1.1         Added code REFRESH_PART_NUMBER, ROHS_FLAG in both FB02 history population and Delta calculation Procedures
            // 25-APR-2016            bsunitha                      1.2           Changed the AVAILABLE_QTY to RECEIVED_QTY in History poplation and delta calculation
            //28-APR-2016             hkommoju                   1.3            Changes done for the HUB_LOCATION 'LRO'
            //28-APR-2016             hkommoju                  1.4   Reverted Changes done for the HUB_LOCATION 'LRO'
            //5-MAY-2016             hkommoju                   1.5         Changes to filter only FVE
            //16-AUG-2016             aradhkum                  1.6         Changes to processed if RPN is available in RC_PRODUCT_MASTER
            ||-----------------------------------------------------------------------------------------
        **********************************************************************************************/

   /*-----------------------Procedure to run SC_FB02_HIST_POPULATE and SC_FB02_DELTA_CALC procedures-------------------------------*/
   PROCEDURE SC_FB02_FVE_R_MAIN
   AS
   BEGIN
      -- Insert a 'START' entry into the Log Table, with Start Time Stamp.
      INSERT INTO SC_CRON_HISTORY_LOG (CHL_ID,
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
                   'SC_FB02_FVE_R_MAIN',
                   NULL,
                   'CRPSC');

      COMMIT;

      SC_FB02_FVE_R_HIST_POPULATE;

      SC_FB02_FVE_R_DELTA_CALC;

      -- Insert a 'SUCCESS' entry into the Log Table with End Time Stamp.
      INSERT INTO SC_CRON_HISTORY_LOG (CHL_ID,
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
                   'SC_FB02_FVE_R_MAIN',
                   NULL,
                   'CRPSC');

      COMMIT;
   END SC_FB02_FVE_R_MAIN;

   /*-----------------------Procedure to populate history table SC_FB02_HIST_FVE from SC_FB02_STG_FVE table-------------------------------*/
   PROCEDURE SC_FB02_FVE_R_HIST_POPULATE
   AS
      CURSOR SC_FB02_CURSOR_HIST
      IS
         SELECT stg.PRODUCT_ID,
                stg.PO_NUMBER,
                stg.PO_LINE_NUMBER,
                stg.LOT_NUMBER,
                stg.TRANSACTION_ID,
                stg.REFRESH_PART_NUMBER           ---Added Refresh_part_number
           FROM SC_FB02_STG_FVE stg
          WHERE     1 = 1
                AND stg.HUB_LOCATION = 'FVE' -->> Added to filter only for FVE process
                AND (stg.PRODUCT_ID,
                     stg.PO_NUMBER,
                     stg.PO_LINE_NUMBER,
                     stg.LOT_NUMBER,
                     stg.TRANSACTION_ID) NOT IN
                       (SELECT hist.PRODUCT_ID,
                               hist.PO_NUMBER,
                               hist.PO_LINE_NUMBER,
                               hist.LOT_NUMBER,
                               hist.TRANSACTION_ID
                          FROM SC_FB02_HIST_FVE hist)
                AND stg.REFRESH_PART_NUMBER LIKE '%RF'
                AND stg.REFRESH_PART_NUMBER NOT LIKE '%WS'
                AND stg.PO_NUMBER LIKE 'CSC%' -- >> Added to exclude Non CSC POs
                AND stg.REFRESH_PART_NUMBER IN
                       (SELECT REFRESH_PART_NUMBER
                          FROM CRPADM.RC_PRODUCT_MASTER); ------Process if RPN is present in RC_PRODUCT_MASTER

      --      FB02_HIST_RECORDS   SC_FB02_CURSOR_HIST%ROWTYPE;     -- Required or Not?

      TYPE SC_FB02_OBJ IS RECORD
      (
         PRODUCT_ID            VARCHAR2 (100 BYTE),
         PO_NUMBER             VARCHAR2 (100 BYTE),
         PO_LINE_NUMBER        VARCHAR2 (100 BYTE),
         LOT_NUMBER            VARCHAR2 (100 BYTE),
         TRANSACTION_ID        NUMBER,
         REFRESH_PART_NUMBER   VARCHAR2 (100 BYTE)
      );


      TYPE SC_FB02_CURSOR_HIST_LIST IS TABLE OF SC_FB02_OBJ;

      FB02_HIST_RECORDS   SC_FB02_CURSOR_HIST_LIST;
   BEGIN
      --   DELETE from sc_fc01_snapshot_fve o where o.PL_TRANSACTION_ID <> (select max(i.PL_TRANSACTION_ID) from sc_fc01_snapshot_fve i
      --                                                                        where o.PL_PURCHASE_ORDER_NUMBER = i.PL_PURCHASE_ORDER_NUMBER
      --                                                                        and o.PL_LINE_NUMBER = i.PL_LINE_NUMBER
      --                                                                        and o.PL_END_USER_PRODUCT_ID = i.PL_END_USER_PRODUCT_ID);

      --   Commit;

      -->> To Re-Load FC01 FVE for Both Retail and Excess

      /* Start Commented on 08-MAY-2019 as it is taken care as part of FC01 ETL */

      --    delete from sc_fc01_snapshot_fve;
      --
      --    insert into sc_fc01_snapshot_fve
      --    select  -- Purchase Order
      --        pl.PURCHASE_ORDER_NUMBER PL_PURCHASE_ORDER_NUMBER,
      --        pl.LINE_NUMBER PL_LINE_NUMBER,
      --        pl.END_USER_PRODUCT_ID PL_END_USER_PRODUCT_ID,
      --        pl.PARTNER_ID PL_PARTNER_ID,
      --        pl.PLANNING_DIVISION PL_PLANNING_DIVISION,
      --        po.PLACEMENT_DATE PO_PLACEMENT_DATE,
      --        po.DOCUMENT_ID PO_DOCUMENT_ID,
      --        pl.TRANSACTION_ID PL_TRANSACTION_ID,
      --        po.LOAD_TYPE PO_LOAD_TYPE,
      --        pl.STATUS_CODE PL_LINE_STATUS_CODE,
      --        pl.RECORD_STATUS PL_RECORD_STATUS,
      --        po.CREATION_DATE PO_CREATION_DATE,
      --        po.LAST_UPDATE_DATE PO_LAST_UPDATE_DATE,
      --        pl.CREATION_DATE PL_CREATION_DATE,
      --        pl.LAST_UPDATE_DATE PL_LAST_UPDATE_DATE,
      --        pd.CREATION_DATE PD_CREATION_DATE,
      --        pd.LAST_UPDATE_DATE PD_LAST_UPDATE_DATE,
      --        pd.DELIVERY_LINE_NUMBER PD_DELIVERY_LINE_NUMBER,
      --        pd.CURRENT_DELIVERY_DATE PD_CURRENT_DELIVERY_DATE,
      --        pd.REQUIRED_QTY PD_REQUIRED_QTY,
      --        pd.TOTAL_RECEIVED_QTY PD_TOTAL_RECEIVED_QTY,
      --        pd.REMAINING_QTY PD_REMAINING_QTY,
      --        pm.refresh_part_number REFRESH_PART_NUMBER,
      --        'Y' ROHS_FLAG,
      --        sysdate RECORD_CREATED_ON,
      --        NULL RECORD_CREATED_BY,
      --        sysdate RECORD_UPDATED_ON,
      --        NULL RECORD_UPDATED_BY,
      --        po.BUYER PO_BUYER
      --        from IF_PURCHASE_ORDER_LINE@sc_esmprd pl
      --        Inner Join IF_PURCHASE_ORDER@sc_esmprd po on (pl.TRANSACTION_ID = po.TRANSACTION_ID)
      --        Inner Join IF_PURCHASE_ORDER_DELIVERY@sc_esmprd pd  on (pl.TRANSACTION_ID = pd.TRANSACTION_ID)
      --        inner join crpadm.rc_product_master pm on (pl.END_USER_PRODUCT_ID  = pm.tan_id)
      --        where 1=1
      --        --and po.LOAD_TYPE = 'INCR'
      --        and pl.PLANNING_DIVISION in ('FVE')
      --        and pl.PURCHASE_ORDER_NUMBER NOT LIKE 'CMI%'--STF implemented on NOV 16th,2017
      --        and pl.TRANSACTION_ID = (select max(ipl.TRANSACTION_ID) from IF_PURCHASE_ORDER_LINE@sc_esmprd ipl
      --                          --inner join IF_PURCHASE_ORDER@sc_esmprd ipo on (ipl.Transaction_id = ipo.Transaction_id)
      --                            where 1=1
      --                            -- and ipo.Load_Type = 'INCR'
      --                            and ipl.PLANNING_DIVISION = 'FVE'
      --                            and ipl.PLANNING_DIVISION = pl.PLANNING_DIVISION
      --                            and ipl.END_USER_PRODUCT_ID = pl.END_USER_PRODUCT_ID
      --                            and ipl.PURCHASE_ORDER_NUMBER = pl.PURCHASE_ORDER_NUMBER
      --                            and ipl.LINE_NUMBER = pl.LINE_NUMBER );
      --
      --       Commit;

      /* End Commented on 08-MAY-2019 as it is taken care as part of FC01 ETL */

      -->>

      -- Insert a 'START' entry into the Log Table, with Start Time Stamp.
      INSERT INTO SC_CRON_HISTORY_LOG (CHL_ID,
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
                   'SC_FB02_FVE_R_HIST_POPULATE',
                   NULL,
                   'CRPSC');

      COMMIT;

      IF NOT (SC_FB02_CURSOR_HIST%ISOPEN)
      THEN
         OPEN SC_FB02_CURSOR_HIST;        --Opening Cursor SC_FB02_CURSOR_HIST
      END IF;

      LOOP
         FETCH SC_FB02_CURSOR_HIST
            BULK COLLECT INTO FB02_HIST_RECORDS
            LIMIT 2000;

         IF (FB02_HIST_RECORDS.COUNT > 0)
         THEN
            FORALL idx IN FB02_HIST_RECORDS.FIRST .. FB02_HIST_RECORDS.LAST
               --  EXIT WHEN FB02_HIST_RECORDS%IS NULL;

               INSERT INTO SC_FB02_HIST_FVE (HUB_LOCATION,
                                             PRODUCT_ID,
                                             PO_NUMBER,
                                             PO_LINE_NUMBER,
                                             LOT_NUMBER,
                                             LINE_RECORD_STATUS,
                                             RECORD_CREATED_ON,
                                             RECORD_CREATED_BY,
                                             RUN_STATUS,
                                             RECEIVED_QTY,
                                             RECORD_UPDATED_ON,
                                             RECORD_UPDATED_BY,
                                             TRANSACTION_ID,
                                             LINE_CREATION_DATE,
                                             REFRESH_PART_NUMBER,
                                             ROHS_FLAG,
                                             LINE_LAST_UPDATE_DATE,
                                             CISCO_MFG_PART_NUM,
                                             PARTNER_ID,
                                             RECEIPT_NUMBER,
                                             DOCUMENT_ID,
                                             RECORD_STATUS,
                                             INVENTORY_LOCATION_TYPE,
                                             EXPECTED_DATE,
                                             RECEIVED_DATE,
                                             AGING_INFO,
                                             INV_CREATION_DATE,
                                             INV_LAST_UPDATE_DATE,
                                             EXPECTED_QTY,
                                             AVAILABLE_QTY,
                                             ALLOCATED_QTY,
                                             PICKED_QTY,
                                             ONHOLD_QTY,
                                             INTRANSIT_QTY)
                  SELECT stg.HUB_LOCATION,
                         stg.PRODUCT_ID,
                         stg.PO_NUMBER,
                         stg.PO_LINE_NUMBER,
                         stg.LOT_NUMBER,
                         LINE_RECORD_STATUS,
                         SYSDATE,
                         RECORD_CREATED_BY,
                         'CURRENT',
                         stg.RECEIVED_QTY,
                         NULL,
                         NULL,
                         TRANSACTION_ID,
                         LINE_CREATION_DATE,
                         REFRESH_PART_NUMBER,
                         'YES' ROHS_FLAG, -->> Temporarily Decoding RoHS with 'Yes' until we receive it in the feed.
                         stg.LINE_LAST_UPDATE_DATE,
                         STG.CISCO_MFG_PART_NUM,
                         stg.PARTNER_ID,
                         stg.RECEIPT_NUMBER,
                         stg.DOCUMENT_ID,
                         stg.RECORD_STATUS,
                         stg.INVENTORY_LOCATION_TYPE,
                         stg.EXPECTED_DATE,
                         stg.RECEIVED_DATE,
                         stg.AGING_INFO,
                         stg.INV_CREATION_DATE,
                         stg.INV_LAST_UPDATE_DATE,
                         stg.EXPECTED_QTY,
                         stg.AVAILABLE_QTY,
                         stg.ALLOCATED_QTY,
                         stg.PICKED_QTY,
                         stg.ONHOLD_QTY,
                         stg.INTRANSIT_QTY
                    FROM SC_FB02_STG_FVE stg
                   WHERE     stg.PRODUCT_ID =
                                FB02_HIST_RECORDS (idx).PRODUCT_ID
                         AND stg.PO_NUMBER =
                                FB02_HIST_RECORDS (idx).PO_NUMBER
                         AND stg.PO_LINE_NUMBER =
                                FB02_HIST_RECORDS (idx).PO_LINE_NUMBER
                         AND stg.LOT_NUMBER =
                                FB02_HIST_RECORDS (idx).LOT_NUMBER
                         AND stg.TRANSACTION_ID =
                                FB02_HIST_RECORDS (idx).TRANSACTION_ID
                         AND stg.REFRESH_PART_NUMBER =
                                FB02_HIST_RECORDS (idx).REFRESH_PART_NUMBER ---Added Refresh_part_number
                         AND stg.HUB_LOCATION = 'FVE'
                         AND STG.REFRESH_PART_NUMBER LIKE '%RF'
                         AND STG.REFRESH_PART_NUMBER NOT LIKE '%WS'; -->> Added to filter only for FVE process

            EXIT WHEN SC_FB02_CURSOR_HIST%NOTFOUND;
         END IF;
      END LOOP;

      -- Insert a 'SUCCESS' entry into the Log Table with End Time Stamp.
      INSERT INTO SC_CRON_HISTORY_LOG (CHL_ID,
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
                   'SC_FB02_FVE_R_HIST_POPULATE',
                   NULL,
                   'CRPSC');

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE_APPLICATION_ERROR (
            -20021,
            'PROBLEM IS WHILE CHECKING NUMBER OF RECORDS PRESENT IN HISTORY TABLE');

         -- Insert a 'EXCEPTION' entry into the Log Table, with Start Time Stamp.
         INSERT INTO SC_CRON_HISTORY_LOG (CHL_ID,
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
                      'SC_FB02_FVE_R_HIST_POPULATE',
                      NULL,
                      'CRPSC');

         -- Insert a 'FAILED' entry into the Log Table, with Start Time Stamp.
         INSERT INTO SC_CRON_HISTORY_LOG (CHL_ID,
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
                      'SC_FB02_FVE_R_HIST_POPULATE',
                      NULL,
                      'CRPSC');

         COMMIT;
   END SC_FB02_FVE_R_HIST_POPULATE;

   /*-----------------------Procedure to calculate Delta value from SC_FB02_STG_FVE table-------------------------------*/
   PROCEDURE SC_FB02_FVE_R_DELTA_CALC
   AS
      VAR_CUR_QTY          NUMBER;
      VAR_RUN_STATUS       VARCHAR2 (20);
      VAR_LR_QTY           NUMBER;
      VAR_QTY              NUMBER;
      VAR_QNTY             NUMBER;
      VAR_COUNT            NUMBER;
      VAR_DELTA_COUNT      NUMBER;
      VAR_CHECK_STATUS     NUMBER;
      VAR_TRANSACTION_ID   NUMBER;
      VAR_HIST_TRANS_ID    NUMBER;
      VAR_DELTA_TRANS_ID   NUMBER;
      VAR_HUB_LOCATION     VARCHAR2 (50);

      CURSOR CUR_FB02_HIST
      IS
           SELECT A.*, ROWNUM
             FROM (  SELECT PRODUCT_ID,
                            PO_NUMBER,
                            PO_LINE_NUMBER,
                            LOT_NUMBER,
                            HUB_LOCATION,
                            REFRESH_PART_NUMBER,
                            LINE_CREATION_DATE,
                            TRANSACTION_ID,
                            ROHS_FLAG
                       FROM SC_FB02_HIST_FVE
                      WHERE     RUN_STATUS = 'CURRENT'
                            AND REFRESH_PART_NUMBER LIKE '%RF'
                            AND REFRESH_PART_NUMBER NOT LIKE '%WS'
                   ORDER BY PRODUCT_ID,
                            PO_NUMBER,
                            PO_LINE_NUMBER,
                            LOT_NUMBER,
                            HUB_LOCATION,
                            REFRESH_PART_NUMBER) A
         ORDER BY ROWNUM;

      TYPE SC_FB02_INV_OBJ IS RECORD
      (
         PRODUCT_ID            VARCHAR2 (100 BYTE),
         PO_NUMBER             VARCHAR2 (100 BYTE),
         PO_LINE_NUMBER        VARCHAR2 (100 BYTE),
         LOT_NUMBER            VARCHAR2 (100 BYTE),
         HUB_LOCATION          VARCHAR2 (100 BYTE),
         REFRESH_PART_NUMBER   VARCHAR2 (100 BYTE),
         LINE_CREATION_DATE    DATE,
         TRANSACTION_ID        NUMBER,
         ROHS_FLAG             VARCHAR2 (3 BYTE),
         ROW_NUMBER            NUMBER
      );


      TYPE SC_FB02_CURSOR_INV_LIST IS TABLE OF SC_FB02_INV_OBJ;

      FB02_INV_RECORD      SC_FB02_CURSOR_INV_LIST;
   BEGIN
      -- Insert a 'START' entry into the Log Table, with Start Time Stamp.
      INSERT INTO SC_CRON_HISTORY_LOG (CHL_ID,
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
                   'SC_FB02_FVE_R_DELTA_CALC',
                   NULL,
                   'CRPSC');

      COMMIT;



      IF NOT (CUR_FB02_HIST%ISOPEN)
      THEN
         OPEN CUR_FB02_HIST;                    --Opening Cursor CUR_FB02_HIST
      END IF;

      LOOP
         FETCH CUR_FB02_HIST BULK COLLECT INTO FB02_INV_RECORD LIMIT 2000;



         --         DBMS_OUTPUT.
         --          PUT_LINE (
         --            'FB02_INV_RECORD.HUB_LOCATION:' || FB02_INV_RECORD.HUB_LOCATION);
         --         DBMS_OUTPUT.
         --          PUT_LINE (
         --            'FB02_INV_RECORD.PRODUCT_ID:' || FB02_INV_RECORD.PRODUCT_ID);
         --         DBMS_OUTPUT.
         --          PUT_LINE (
         --            'FB02_INV_RECORD.PO_NUMBER:' || FB02_INV_RECORD.PO_NUMBER);
         --         DBMS_OUTPUT.
         --          PUT_LINE (
         --            'FB02_INV_RECORD.PO_LINE_NUMBER:'
         --            || FB02_INV_RECORD.PO_LINE_NUMBER);
         --         DBMS_OUTPUT.
         --          PUT_LINE (
         --            'FB02_INV_RECORD.REFRESH_PART_NUMBER:'
         --            || FB02_INV_RECORD.REFRESH_PART_NUMBER);
         --         DBMS_OUTPUT.PUT_LINE ('----------------');

         FOR IDX IN 1 .. FB02_INV_RECORD.COUNT
         LOOP
            SELECT FB02_INV_RECORD (IDX).HUB_LOCATION
              INTO VAR_HUB_LOCATION
              FROM DUAL;

            IF VAR_HUB_LOCATION = 'FVE'
            THEN
               SELECT COUNT (*)
                 INTO VAR_DELTA_COUNT
                 FROM SC_FB02_DELTA_FVE
                WHERE     HUB_LOCATION = FB02_INV_RECORD (IDX).HUB_LOCATION
                      AND PRODUCT_ID = FB02_INV_RECORD (IDX).PRODUCT_ID
                      AND PO_NUMBER = FB02_INV_RECORD (IDX).PO_NUMBER
                      AND PO_LINE_NUMBER =
                             FB02_INV_RECORD (IDX).PO_LINE_NUMBER
                      AND LOT_NUMBER = FB02_INV_RECORD (IDX).LOT_NUMBER
                      AND REFRESH_PART_NUMBER =
                             FB02_INV_RECORD (IDX).REFRESH_PART_NUMBER
                      AND REFRESH_PART_NUMBER LIKE '%RF'
                      AND REFRESH_PART_NUMBER NOT LIKE '%WS';

               ------ RECORD NOT PRESENT FOR PRODUCT IN DELTA
               IF VAR_DELTA_COUNT = 0
               THEN
                  BEGIN
                     SELECT RECEIVED_QTY
                       INTO VAR_QNTY
                       FROM SC_FB02_HIST_FVE
                      WHERE     HUB_LOCATION =
                                   FB02_INV_RECORD (IDX).HUB_LOCATION
                            AND PRODUCT_ID = FB02_INV_RECORD (IDX).PRODUCT_ID
                            AND PO_NUMBER = FB02_INV_RECORD (IDX).PO_NUMBER
                            AND PO_LINE_NUMBER =
                                   FB02_INV_RECORD (IDX).PO_LINE_NUMBER
                            AND LOT_NUMBER = FB02_INV_RECORD (IDX).LOT_NUMBER
                            AND REFRESH_PART_NUMBER =
                                   FB02_INV_RECORD (IDX).REFRESH_PART_NUMBER
                            AND REFRESH_PART_NUMBER LIKE '%RF'
                            AND REFRESH_PART_NUMBER NOT LIKE '%WS'
                            AND RUN_STATUS = 'CURRENT';



                     INSERT INTO SC_FB02_DELTA_FVE (HUB_LOCATION,
                                                    PRODUCT_ID,
                                                    PO_NUMBER,
                                                    PO_LINE_NUMBER,
                                                    LOT_NUMBER,
                                                    RECORD_CREATED_ON,
                                                    RECORD_CREATED_BY,
                                                    RECEIVED_QTY,
                                                    LINE_CREATION_DATE,
                                                    TRANSACTION_ID,
                                                    REFRESH_PART_NUMBER,
                                                    ROHS_FLAG,
                                                    PROCESSED_STATUS,
                                                    NEW_REC)
                          VALUES (FB02_INV_RECORD (IDX).HUB_LOCATION,
                                  FB02_INV_RECORD (IDX).PRODUCT_ID,
                                  FB02_INV_RECORD (IDX).PO_NUMBER,
                                  FB02_INV_RECORD (IDX).PO_LINE_NUMBER,
                                  FB02_INV_RECORD (IDX).LOT_NUMBER,
                                  SYSDATE,
                                  'WF_SC_FB02_FVE_HIST',
                                  VAR_QNTY,
                                  FB02_INV_RECORD (IDX).LINE_CREATION_DATE,
                                  FB02_INV_RECORD (IDX).TRANSACTION_ID,
                                  FB02_INV_RECORD (IDX).REFRESH_PART_NUMBER,
                                  FB02_INV_RECORD (IDX).ROHS_FLAG,
                                  'N',
                                  'Y');

                     COMMIT;

                     -- DBMS_OUTPUT.PUT_LINE ('DELTA INSERTED WHEN NOT PRESENT IN DELTA');

                     UPDATE SC_FB02_HIST_FVE
                        SET RUN_STATUS =
                               CASE
                                  WHEN RUN_STATUS = 'LASTRUN' THEN 'HISTORY'
                                  WHEN RUN_STATUS = 'CURRENT' THEN 'LASTRUN'
                                  ELSE 'HISTORY'
                               END,
                            RECORD_UPDATED_ON = SYSDATE,
                            RECORD_UPDATED_BY = 'WF_SC_FB02_FVE_HIST'
                      WHERE     UPPER (PRODUCT_ID) =
                                   UPPER (FB02_INV_RECORD (IDX).PRODUCT_ID)
                            AND UPPER (PO_NUMBER) =
                                   UPPER (FB02_INV_RECORD (IDX).PO_NUMBER)
                            AND UPPER (PO_LINE_NUMBER) =
                                   UPPER (
                                      FB02_INV_RECORD (IDX).PO_LINE_NUMBER)
                            AND LOT_NUMBER = FB02_INV_RECORD (IDX).LOT_NUMBER
                            AND UPPER (HUB_LOCATION) =
                                   UPPER (FB02_INV_RECORD (IDX).HUB_LOCATION)
                            AND UPPER (REFRESH_PART_NUMBER) =
                                   UPPER (
                                      FB02_INV_RECORD (IDX).REFRESH_PART_NUMBER)
                            AND RUN_STATUS != 'HISTORY'
                            AND REFRESH_PART_NUMBER LIKE '%RF'
                            AND REFRESH_PART_NUMBER NOT LIKE '%WS';

                     COMMIT;
                  --  DBMS_OUTPUT.PUT_LINE ('HISTORY UPDATED AFTER INSERTION INTO DELTA WHEN NOT PRESENT IN DELTA');

                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        RAISE_APPLICATION_ERROR (-20021, SQLERRM --  'PROBLEM IS WHILE INSERTING RECORDS INTO DELTA TABLE'
                                                                --FB02_INV_RECORD.REFRESH_PART_NUMBER
                        );

                        -- Insert a 'EXCEPTION' entry into the Log Table, with Start Time Stamp.
                        INSERT INTO SC_CRON_HISTORY_LOG (CHL_ID,
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
                                     'SC_FB02_FVE_R_DELTA_CALC',
                                     NULL,
                                     'CRPSC');

                        -- Insert a 'FAILED' entry into the Log Table, with Start Time Stamp.
                        INSERT INTO SC_CRON_HISTORY_LOG (CHL_ID,
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
                                     'SC_FB02_FVE_R_DELTA_CALC',
                                     NULL,
                                     'CRPSC');

                        COMMIT;
                  END;
               ---- IF RECORD IS PRESENT IN DELTA
               ELSE
                  SELECT MAX (TRANSACTION_ID)
                    INTO VAR_HIST_TRANS_ID
                    FROM SC_FB02_HIST_FVE
                   WHERE     UPPER (PRODUCT_ID) =
                                UPPER (FB02_INV_RECORD (IDX).PRODUCT_ID)
                         AND UPPER (PO_NUMBER) =
                                UPPER (FB02_INV_RECORD (IDX).PO_NUMBER)
                         AND UPPER (PO_LINE_NUMBER) =
                                UPPER (FB02_INV_RECORD (IDX).PO_LINE_NUMBER)
                         AND LOT_NUMBER = FB02_INV_RECORD (IDX).LOT_NUMBER
                         AND UPPER (HUB_LOCATION) =
                                UPPER (FB02_INV_RECORD (IDX).HUB_LOCATION)
                         AND UPPER (REFRESH_PART_NUMBER) =
                                UPPER (
                                   FB02_INV_RECORD (IDX).REFRESH_PART_NUMBER)
                         AND REFRESH_PART_NUMBER LIKE '%RF'
                         AND REFRESH_PART_NUMBER NOT LIKE '%WS';

                  SELECT TRANSACTION_ID
                    INTO VAR_DELTA_TRANS_ID
                    FROM SC_FB02_DELTA_FVE
                   WHERE     UPPER (PRODUCT_ID) =
                                UPPER (FB02_INV_RECORD (IDX).PRODUCT_ID)
                         AND UPPER (PO_NUMBER) =
                                UPPER (FB02_INV_RECORD (IDX).PO_NUMBER)
                         AND UPPER (PO_LINE_NUMBER) =
                                UPPER (FB02_INV_RECORD (IDX).PO_LINE_NUMBER)
                         AND LOT_NUMBER = FB02_INV_RECORD (IDX).LOT_NUMBER
                         AND UPPER (HUB_LOCATION) =
                                UPPER (FB02_INV_RECORD (IDX).HUB_LOCATION)
                         AND UPPER (REFRESH_PART_NUMBER) =
                                UPPER (
                                   FB02_INV_RECORD (IDX).REFRESH_PART_NUMBER)
                         AND REFRESH_PART_NUMBER LIKE '%RF'
                         AND REFRESH_PART_NUMBER NOT LIKE '%WS';

                  SELECT RECEIVED_QTY
                    INTO VAR_CUR_QTY
                    FROM SC_FB02_HIST_FVE
                   WHERE     UPPER (PRODUCT_ID) =
                                UPPER (FB02_INV_RECORD (IDX).PRODUCT_ID)
                         AND UPPER (PO_NUMBER) =
                                UPPER (FB02_INV_RECORD (IDX).PO_NUMBER)
                         AND UPPER (PO_LINE_NUMBER) =
                                UPPER (FB02_INV_RECORD (IDX).PO_LINE_NUMBER)
                         AND LOT_NUMBER = FB02_INV_RECORD (IDX).LOT_NUMBER
                         AND UPPER (HUB_LOCATION) =
                                UPPER (FB02_INV_RECORD (IDX).HUB_LOCATION)
                         AND UPPER (REFRESH_PART_NUMBER) =
                                UPPER (
                                   FB02_INV_RECORD (IDX).REFRESH_PART_NUMBER)
                         AND TRANSACTION_ID = VAR_HIST_TRANS_ID
                         AND REFRESH_PART_NUMBER LIKE '%RF'
                         AND REFRESH_PART_NUMBER NOT LIKE '%WS';

                  SELECT RECEIVED_QTY
                    INTO VAR_LR_QTY
                    FROM SC_FB02_HIST_FVE
                   WHERE     UPPER (PRODUCT_ID) =
                                UPPER (FB02_INV_RECORD (IDX).PRODUCT_ID)
                         AND UPPER (PO_NUMBER) =
                                UPPER (FB02_INV_RECORD (IDX).PO_NUMBER)
                         AND UPPER (PO_LINE_NUMBER) =
                                UPPER (FB02_INV_RECORD (IDX).PO_LINE_NUMBER)
                         AND LOT_NUMBER = FB02_INV_RECORD (IDX).LOT_NUMBER
                         AND UPPER (HUB_LOCATION) =
                                UPPER (FB02_INV_RECORD (IDX).HUB_LOCATION)
                         AND UPPER (REFRESH_PART_NUMBER) =
                                UPPER (
                                   FB02_INV_RECORD (IDX).REFRESH_PART_NUMBER)
                         AND TRANSACTION_ID = VAR_DELTA_TRANS_ID
                         AND REFRESH_PART_NUMBER LIKE '%RF'
                         AND REFRESH_PART_NUMBER NOT LIKE '%WS';

                  VAR_QTY := VAR_CUR_QTY - VAR_LR_QTY;

                  IF VAR_HIST_TRANS_ID - VAR_DELTA_TRANS_ID = 0
                  THEN
                     UPDATE SC_FB02_DELTA_FVE
                        SET RECEIVED_QTY = VAR_QTY,
                            RECORD_UPDATED_ON = SYSDATE,
                            RECORD_UPDATED_BY = 'WF_SC_FB02_FVE_HIST',
                            NEW_REC = 'Y'
                      WHERE     UPPER (PRODUCT_ID) =
                                   UPPER (FB02_INV_RECORD (IDX).PRODUCT_ID)
                            AND UPPER (PO_NUMBER) =
                                   UPPER (FB02_INV_RECORD (IDX).PO_NUMBER)
                            AND UPPER (PO_LINE_NUMBER) =
                                   UPPER (
                                      FB02_INV_RECORD (IDX).PO_LINE_NUMBER)
                            AND LOT_NUMBER = FB02_INV_RECORD (IDX).LOT_NUMBER
                            AND UPPER (HUB_LOCATION) =
                                   UPPER (FB02_INV_RECORD (IDX).HUB_LOCATION)
                            AND UPPER (REFRESH_PART_NUMBER) =
                                   UPPER (
                                      FB02_INV_RECORD (IDX).REFRESH_PART_NUMBER)
                            AND REFRESH_PART_NUMBER LIKE '%RF'
                            AND REFRESH_PART_NUMBER NOT LIKE '%WS';

                     COMMIT;
                  ELSE
                     UPDATE SC_FB02_DELTA_FVE
                        SET RECEIVED_QTY = VAR_QTY,
                            RECORD_UPDATED_ON = SYSDATE,
                            RECORD_UPDATED_BY = 'WF_SC_FB02_FVE_HIST',
                            TRANSACTION_ID = VAR_HIST_TRANS_ID,
                            NEW_REC = 'Y'
                      WHERE     UPPER (PRODUCT_ID) =
                                   UPPER (FB02_INV_RECORD (IDX).PRODUCT_ID)
                            AND UPPER (PO_NUMBER) =
                                   UPPER (FB02_INV_RECORD (IDX).PO_NUMBER)
                            AND UPPER (PO_LINE_NUMBER) =
                                   UPPER (
                                      FB02_INV_RECORD (IDX).PO_LINE_NUMBER)
                            AND LOT_NUMBER = FB02_INV_RECORD (IDX).LOT_NUMBER
                            AND UPPER (HUB_LOCATION) =
                                   UPPER (FB02_INV_RECORD (IDX).HUB_LOCATION)
                            AND UPPER (REFRESH_PART_NUMBER) =
                                   UPPER (
                                      FB02_INV_RECORD (IDX).REFRESH_PART_NUMBER)
                            AND REFRESH_PART_NUMBER LIKE '%RF'
                            AND REFRESH_PART_NUMBER NOT LIKE '%WS';

                     --  DBMS_OUTPUT.PUT_LINE ('DELTA UPDATED WHEN TRANSACTION ID ARE NOT EQUAL FOR A PARTICULAR PRODUCT');
                     COMMIT;

                     UPDATE SC_FB02_HIST_FVE
                        SET RUN_STATUS =
                               CASE
                                  WHEN RUN_STATUS = 'LASTRUN' THEN 'HISTORY'
                                  WHEN RUN_STATUS = 'CURRENT' THEN 'LASTRUN'
                                  ELSE 'HISTORY'
                               END,
                            RECORD_UPDATED_ON = SYSDATE,
                            RECORD_UPDATED_BY = 'WF_SC_FB02_FVE_HIST'
                      WHERE     UPPER (PRODUCT_ID) =
                                   UPPER (FB02_INV_RECORD (IDX).PRODUCT_ID)
                            AND UPPER (PO_NUMBER) =
                                   UPPER (FB02_INV_RECORD (IDX).PO_NUMBER)
                            AND UPPER (PO_LINE_NUMBER) =
                                   UPPER (
                                      FB02_INV_RECORD (IDX).PO_LINE_NUMBER)
                            AND LOT_NUMBER = FB02_INV_RECORD (IDX).LOT_NUMBER
                            AND UPPER (HUB_LOCATION) =
                                   UPPER (FB02_INV_RECORD (IDX).HUB_LOCATION)
                            AND UPPER (REFRESH_PART_NUMBER) =
                                   UPPER (
                                      FB02_INV_RECORD (IDX).REFRESH_PART_NUMBER)
                            AND RUN_STATUS != 'HISTORY'
                            AND REFRESH_PART_NUMBER LIKE '%RF'
                            AND REFRESH_PART_NUMBER NOT LIKE '%WS';
                  --  DBMS_OUTPUT.PUT_LINE ('HISTORY UPDATED AFTER UPDATION OF DELTA WHEN TRANSACTION ID ARE NOT EQUAL FOR A PARTICULAR PRODUCT');
                  END IF;
               END IF;
            END IF;

            COMMIT;
         END LOOP;

         EXIT WHEN CUR_FB02_HIST%NOTFOUND;
      END LOOP;

      CLOSE CUR_FB02_HIST;

      INSERT INTO SC_FB02_DELTA_FVE_HIST (PRODUCT_ID,
                                          PO_NUMBER,
                                          PO_LINE_NUMBER,
                                          LOT_NUMBER,
                                          RECEIVED_QTY,
                                          RECORD_CREATED_BY,
                                          RECORD_CREATED_ON,
                                          HUB_LOCATION,
                                          RECORD_UPDATED_BY,
                                          RECORD_UPDATED_ON,
                                          LINE_CREATION_DATE,
                                          TRANSACTION_ID,
                                          REFRESH_PART_NUMBER,
                                          ROHS_FLAG,
                                          PROCESSED_STATUS)
         SELECT PRODUCT_ID,
                PO_NUMBER,
                PO_LINE_NUMBER,
                LOT_NUMBER,
                RECEIVED_QTY,
                RECORD_CREATED_BY,
                RECORD_CREATED_ON,
                HUB_LOCATION,
                RECORD_UPDATED_BY,
                RECORD_UPDATED_ON,
                LINE_CREATION_DATE,
                TRANSACTION_ID,
                REFRESH_PART_NUMBER,
                ROHS_FLAG,
                PROCESSED_STATUS
           FROM SC_FB02_DELTA_FVE
          WHERE     NEW_REC = 'Y'
                AND RECEIVED_QTY != 0
                AND REFRESH_PART_NUMBER LIKE '%RF'
                AND REFRESH_PART_NUMBER NOT LIKE '%WS';

      COMMIT;

      UPDATE SC_FB02_DELTA_FVE
         SET NEW_REC = 'N'
       WHERE     REFRESH_PART_NUMBER LIKE '%RF'
             AND REFRESH_PART_NUMBER NOT LIKE '%WS';

      COMMIT;

      --    DELETE FROM SC_FB02_DELTA_FVE
      --    WHERE TOTAL_QTY = 0;

      COMMIT;

      --  DBMS_OUTPUT.PUT_LINE('Records got inserted into Delta_hist table');

      -- Insert a 'SUCCESS' entry into the Log Table with End Time Stamp.
      INSERT INTO SC_CRON_HISTORY_LOG (CHL_ID,
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
                   'SC_FB02_FVE_R_DELTA_CALC',
                   NULL,
                   'CRPSC');

      COMMIT;
   END SC_FB02_FVE_R_DELTA_CALC;
END SC_FB02_FVE_R_HIST_DELTA_CALC;
/