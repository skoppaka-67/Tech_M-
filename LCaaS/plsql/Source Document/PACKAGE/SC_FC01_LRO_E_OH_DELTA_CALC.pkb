CREATE OR REPLACE PACKAGE BODY CRPSC.SC_FC01_LRO_E_OH_DELTA_CALC
AS
   /**********************************************************************************************
            || Object Name     : SC_FC01_LRO_HIST_DELTA_CALC
            || Modification History
            ||
            ||-----------------------------------------------------------------------------------------
            ||Date                       By            Version        Comments
            ||-----------------------------------------------------------------------------------------
           || Crated a New Package to Proces the Onhand Inventory from FC01 Feed - Receipts Inventory. hkommoju

            -- SC_FC01_DELTA_FVE--  SC_FC01_OH_DELTA_LRO
            ||-----------------------------------------------------------------------------------------
        **********************************************************************************************/

   /*-----------------------Procedure to run SC_FC01_LRO_HIST_POPULATE and SC_FC01_DELTA_CALC procedures-------------------------------*/
   PROCEDURE SC_FC01_LRO_E_OH_MAIN
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
                   'SC_FC01_LRO_E_OH_MAIN',
                   NULL,
                   'CRPSC');

      COMMIT;

      SC_FC01_LRO_E_OH_STG;

      SC_FC01_LRO_E_OH_HIST;

      SC_FC01_LRO_E_OH_DELTA;

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
                   'SC_FC01_LRO_E_OH_MAIN',
                   NULL,
                   'CRPSC');

      COMMIT;
   END SC_FC01_LRO_E_OH_MAIN;

   /*-----------------------Procedure to populate stage table SC_FC01_OH_STG_LRO from ESM tables-------------------------------*/
   PROCEDURE SC_FC01_LRO_E_OH_STG
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
                   'SC_FC01_LRO_E_OH_STG',
                   NULL,
                   'CRPSC');

      COMMIT;

      -->> To Excelude PIDs that already Process and comes with new Delivery Line ID

      DELETE FROM SC_FC01_OH_STG_LRO stg
            WHERE     (stg.PRODUCT_ID, stg.PO_NUMBER, stg.PO_LINE_NUMBER) IN
                         (SELECT lr.PRODUCT_ID,
                                 lr.PO_NUMBER,
                                 lr.PO_LINE_NUMBER
                            FROM sc_fc01_oh_hist_lro lr
                           WHERE     lr.run_status = 'LASTRUN'
                                 AND (    stg.PRODUCT_ID = lr.PRODUCT_ID
                                      AND stg.PO_NUMBER = lr.PO_NUMBER
                                      AND stg.PO_LINE_NUMBER =
                                             lr.PO_LINE_NUMBER)
                                 AND stg.DELIVERY_LINE_NUMBER <>
                                        lr.DELIVERY_LINE_NUMBER
                                 AND stg.DELIVERY_LINE_NUMBER = 1)
                  AND refresh_part_number LIKE '%WS'
                  AND refresh_part_number NOT LIKE '%RF';

      COMMIT;

      /* Start Commented on 08-MAY-2019 as it is taken care as part of FC01 ETL */

      --      Delete from SC_FC01_OH_STG_LRO  where refresh_part_number like '%WS';  -->> Added Newly.
      --
      --      INSERT INTO SC_FC01_OH_STG_LRO (PRODUCT_ID,
      --                                CISCO_MFG_PART_NUM,
      --                                PARTNER_ID,
      --                                PO_NUMBER,
      --                                PO_LINE_NUMBER,
      --                                DELIVERY_LINE_NUMBER,
      --                                TRANSACTION_ID,
      --                                RECEIPT_NUMBER,
      --                                DOCUMENT_ID,
      --                                RECORD_STATUS,
      --                                LINE_RECORD_STATUS,
      --                                HUB_LOCATION,
      --                                INVENTORY_LOCATION_TYPE,
      --                                EXPECTED_DATE,
      --                                RECEIVED_DATE,
      --                                AGING_INFO,
      --                                RCT_CREATION_DATE,
      --                                RCT_LAST_UPDATE_DATE,
      --                                LINE_CREATION_DATE,
      --                                LINE_LAST_UPDATE_DATE,
      --                                EXPECTED_QTY,
      --                                RECEIVED_QTY,
      --                                AVAILABLE_QTY,
      --                                ALLOCATED_QTY,
      --                                PICKED_QTY,
      --                                ONHOLD_QTY,
      --                                INTRANSIT_QTY,
      --                                RECORD_CREATED_ON,
      --                                RECORD_CREATED_BY,
      --                                RECORD_UPDATED_ON,
      --                                RECORD_UPDATED_BY,
      --                                REFRESH_PART_NUMBER,
      --                                ROHS_FLAG,
      --                                SHIPMENT_QTY)
      --            (select
      --                pl.END_USER_PRODUCT_ID    PRODUCT_ID,
      --                pl.MFG_PRODUCT_ID   CISCO_MFG_PART_NUM,
      --                po.PARTNER_ID    PARTNER_ID,
      --                pr.PURCHASE_ORDER_NUMBER    PO_NUMBER,
      --                pr.LINE_NUMBER   PO_LINE_NUMBER,
      --                pr.DELIVERY_LINE_NUMBER    DELIVERY_LINE_NUMBER,
      --                pr.TRANSACTION_ID    TRANSACTION_ID,
      --                NULL RECEIPT_NUMBER,
      --                po.DOCUMENT_ID    DOCUMENT_ID,
      --                pl.RECORD_STATUS    RECORD_STATUS,
      --                pl.STATUS_CODE LINE_RECORD_STATUS,
      --                po.PLANNING_DIVISION    HUB_LOCATION,
      --                NULL INVENTORY_LOCATION_TYPE,
      --                NULL EXPECTED_DATE,
      --                pr.RECEIVED_DATE  RECEIVED_DATE, -- NULL RECEIVED_DATE,
      --                NULL AGING_INFO,
      --                NULL RCT_CREATION_DATE,---pr.CREATION_DATE    RCT_CREATION_DATE,
      --                NULL RCT_LAST_UPDATE_DATE,--pr.LAST_UPDATE_DATE    RCT_LAST_UPDATE_DATE,
      --                pl.CREATION_DATE    LINE_CREATION_DATE,
      --                pl.LAST_UPDATE_DATE   LINE_LAST_UPDATE_DATE,
      --                NULL EXPECTED_QTY,
      --                pr.RECEIVED_QTY   RECEIVED_QTY,
      --                NULL        AVAILABLE_QTY,
      --                NULL        ALLOCATED_QTY,
      --                NULL        PICKED_QTY,
      --                NULL        ONHOLD_QTY,
      --                NULL        INTRANSIT_QTY,
      --                SYSDATE     RECORD_CREATED_ON,
      --                NULL        RECORD_CREATED_BY,
      --                SYSDATE     RECORD_UPDATED_ON,
      --                NULL        RECORD_UPDATED_BY,
      --                PM.REFRESH_PART_NUMBER REFRESH_PART_NUMBER,
      --                decode(upper(PD.COMPLIANCE_CATEGORY2), 'ROHS','YES','NO')  ROHS_FLAG,
      --                NULL        SHIPMENT_QTY
      --                from        IF_PURCHASE_ORDER@sc_esmprd po
      --                -- Line
      --                Inner Join      IF_PURCHASE_ORDER_LINE@sc_esmprd pl on (po.transaction_id = pl.transaction_id and po.PURCHASE_ORDER_NUMBER = pl.PURCHASE_ORDER_NUMBER)
      --                -- Delivery
      --                Inner join (   Select  ipd.Purchase_Order_Number, ipd.LINE_NUMBER, ipd.delivery_line_number, ipd.transaction_id , COMPLIANCE_CATEGORY2,
      --                                            sum(ipd.REQUIRED_QTY) REQUIRED_QTY, sum(ipd.TOTAL_RECEIVED_QTY) TOTAL_RECEIVED_QTY, sum(ipd.REMAINING_QTY) REMAINING_QTY
      --                                    From    IF_PURCHASE_ORDER_DELIVERY@sc_esmprd ipd
      --                                    Group By ipd.Purchase_Order_Number, ipd.LINE_NUMBER, ipd.delivery_line_number,ipd.transaction_id, COMPLIANCE_CATEGORY2
      --                                ) pd
      --                            on  (pl.transaction_id = pd.transaction_id and pl.PURCHASE_ORDER_NUMBER = pd.PURCHASE_ORDER_NUMBER and pl.LINE_NUMBER = pd.LINE_NUMBER)
      --                -- Receipts
      --                Inner join (   Select  ipr.Purchase_Order_Number, ipr.LINE_NUMBER, ipr.DELIVERY_LINE_NUMBER, ipr.transaction_id, ipr.RECEIVED_DATE, -- CREATION_DATE, LAST_UPDATE_DATE, RECEIVED_DATE,
      --                                    sum(ipr.RECEIVED_QTY) RECEIVED_QTY
      --                                    From    IF_PURCHASE_ORDER_RECEIPTS@sc_esmprd ipr
      --                                    Group By ipr.Purchase_Order_Number, ipr.LINE_NUMBER, ipr.transaction_id, ipr.DELIVERY_LINE_NUMBER, ipr.RECEIVED_DATE --CREATION_DATE, LAST_UPDATE_DATE, RECEIVED_DATE
      --                                ) pr
      --                             on (pd.transaction_id = pr.transaction_id and pd.PURCHASE_ORDER_NUMBER = pr.PURCHASE_ORDER_NUMBER and pd.LINE_NUMBER = pr.LINE_NUMBER
      --                                  and pd.delivery_line_number = pr.delivery_line_number)
      --                -- Product Master
      --                Inner Join crpadm.rc_product_master pm on (pm.tan_id = pl.end_user_product_id)
      --                where 1=1
      --                --and po.LOAD_TYPE = 'INCR'
      --                and po.planning_division = 'LRO'
      --                --and trunc(pl.creation_date) > trunc(sysdate) - 10
      --                and nvl(pr.received_qty,0) > 0
      --                and pr.transaction_id = ( select max(ipr.transaction_id) from IF_PURCHASE_ORDER_RECEIPTS@sc_esmprd ipr
      --                                            where 1 = 1 --ipl.END_USER_PRODUCT_ID = pl.END_USER_PRODUCT_ID
      --                                            and ipr.PURCHASE_ORDER_NUMBER = pr.PURCHASE_ORDER_NUMBER
      --                                            and ipr.LINE_NUMBER = pr.LINE_NUMBER
      --                                            and ipr.DELIVERY_LINE_NUMBER = pr.DELIVERY_LINE_NUMBER
      --                                            and ipr.PLANNING_DIVISION = 'LRO'
      --                                        )
      --                and pm.refresh_part_number like '%WS'
      --                -->>
      --                and (pl.END_USER_PRODUCT_ID, pl.PURCHASE_ORDER_NUMBER , pl.LINE_NUMBER, pl.Transaction_ID )
      --                     NOT IN
      --                    (   select END_USER_PRODUCT_ID, PURCHASE_ORDER_NUMBER, LINE_NUMBER , Transaction_ID
      --                        from IF_PURCHASE_ORDER_LINE@sc_esmprd where PLANNING_DIVISION = 'LRO' and STATUS_CODE in (  'Closed'  , 'Cancelled' )
      --                        and trunc(CREATION_DATE) <= '20-MAR-2017'
      --                    )
      --                -->> To Excelude PIDs that already Process and comes with new Dlivery Line ID
      --                and (pl.END_USER_PRODUCT_ID, pl.PURCHASE_ORDER_NUMBER , pl.LINE_NUMBER  )
      --                NOT IN
      --                ( select lr.PRODUCT_ID, lr.PO_NUMBER, lr.PO_LINE_NUMBER from sc_fc01_oh_hist_lro lr
      --                    where lr.run_status = 'LASTRUN'
      --                    and
      --                    ( pl.END_USER_PRODUCT_ID = lr.PRODUCT_ID and  pl.PURCHASE_ORDER_NUMBER = lr.PO_NUMBER and pl.LINE_NUMBER = lr.PO_LINE_NUMBER )
      --                    and pr.DELIVERY_LINE_NUMBER <> lr.DELIVERY_LINE_NUMBER
      --                    and pr.DELIVERY_LINE_NUMBER = 1
      --                )  --and  document_id like 'RMA_FC01_20190202015001.01%'  or (document_id like 'RMA_FC01_20190201111014.14%' and trunc(pr.received_date) = to_date('01/26/2019','mm/dd/yyyy'))   /*to process Jan 26 records of full load and Feb 2nd records*/
      --                     and  document_id not like 'RMA_FC01_20190201111014.14%' --- to avoid full load of Jan 26 week
      --        );

      /* End Commented on 08-MAY-2019 as it is taken care as part of FC01 ETL */

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
                   'SC_FC01_LRO_E_OH_STG',
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
                      'SC_FC01_LRO_E_OH_STG',
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
                      'SC_FC01_LRO_E_OH_STG',
                      NULL,
                      'CRPSC');

         COMMIT;
   END SC_FC01_LRO_E_OH_STG;

   /*-----------------------Procedure to populate history table SC_FC01_HIST_FVE from SC_FC01_STG_FVE table-------------------------------*/
   PROCEDURE SC_FC01_LRO_E_OH_HIST
   AS
      CURSOR SC_FC01_CUR_LRO_OH_HIST
      IS
         SELECT stg.PRODUCT_ID,
                stg.PO_NUMBER,
                stg.PO_LINE_NUMBER,
                stg.DELIVERY_LINE_NUMBER,
                   stg.TRANSACTION_ID
                || DECODE (UPPER (stg.ROHS_FLAG), 'YES', 1, 0)
                   TRANSACTION_ID,
                stg.REFRESH_PART_NUMBER,          ---Added Refresh_part_number
                stg.RECEIVED_DATE
           FROM SC_FC01_OH_STG_LRO stg                     --  SC_FC01_STG_FVE
          WHERE     1 = 1
                AND stg.HUB_LOCATION = 'LRO' -->> Added to filter only for FVE process
                AND (stg.PRODUCT_ID,
                     stg.PO_NUMBER,
                     stg.PO_LINE_NUMBER,
                     stg.DELIVERY_LINE_NUMBER,
                        stg.TRANSACTION_ID
                     || DECODE (UPPER (stg.ROHS_FLAG), 'YES', 1, 0),
                     stg.RECEIVED_DATE                                    -->>
                                      ) NOT IN
                       (SELECT hist.PRODUCT_ID,
                               hist.PO_NUMBER,
                               hist.PO_LINE_NUMBER,
                               hist.DELIVERY_LINE_NUMBER,
                               hist.TRANSACTION_ID,
                               hist.RECEIVED_DATE                         -->>
                          FROM SC_FC01_OH_HIST_LRO hist) --  SC_FC01_OH_HIST_LRO
                AND stg.REFRESH_PART_NUMBER LIKE '%WS'
                AND stg.REFRESH_PART_NUMBER NOT LIKE '%RF'
                --AND stg.PO_NUMBER like 'CSC%'  -- >> Added to exclude Non CSC POs
                AND stg.REFRESH_PART_NUMBER IN
                       (SELECT REFRESH_PART_NUMBER
                          FROM CRPADM.RC_PRODUCT_MASTER); ------Process if RPN is present in RC_PRODUCT_MASTER

      FC01_LRO_HIST_REC   SC_FC01_CUR_LRO_OH_HIST%ROWTYPE; -- Required or Not?
   BEGIN
      --   DELETE from sc_fc01_snapshot_fve o where o.PL_TRANSACTION_ID <> (select max(i.PL_TRANSACTION_ID) from sc_fc01_snapshot_fve i
      --                                                                        where o.PL_PURCHASE_ORDER_NUMBER = i.PL_PURCHASE_ORDER_NUMBER
      --                                                                        and o.PL_LINE_NUMBER = i.PL_LINE_NUMBER
      --                                                                        and o.PL_END_USER_PRODUCT_ID = i.PL_END_USER_PRODUCT_ID);

      --   Commit;

      -->> To Re-Load FC01 FVE for Both Retail and Excess


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
      --        NULL RECORD_UPDATED_BY
      --        from IF_PURCHASE_ORDER_LINE@sc_esmprd pl
      --        Inner Join IF_PURCHASE_ORDER@sc_esmprd po on (pl.TRANSACTION_ID = po.TRANSACTION_ID)
      --        Inner Join IF_PURCHASE_ORDER_DELIVERY@sc_esmprd pd  on (pl.TRANSACTION_ID = pd.TRANSACTION_ID)
      --        inner join crpadm.rc_product_master pm on (pl.END_USER_PRODUCT_ID  = pm.tan_id)
      --        where 1=1
      --        --and po.LOAD_TYPE = 'INCR'
      --        and pl.PLANNING_DIVISION in ('FVE')
      --        and pl.TRANSACTION_ID = (select max(ipl.TRANSACTION_ID) from IF_PURCHASE_ORDER_LINE@sc_esmprd ipl
      --                          inner join IF_PURCHASE_ORDER@sc_esmprd ipo on (ipl.Transaction_id = ipo.Transaction_id)
      --                            where 1=1
      --                            -- and ipo.Load_Type = 'INCR'
      --                            and ipl.PLANNING_DIVISION = 'FVE'
      --                            and ipl.PLANNING_DIVISION = pl.PLANNING_DIVISION
      --                            and ipl.END_USER_PRODUCT_ID = pl.END_USER_PRODUCT_ID
      --                            and ipl.PURCHASE_ORDER_NUMBER = pl.PURCHASE_ORDER_NUMBER
      --                            and ipl.LINE_NUMBER = pl.LINE_NUMBER );
      --
      --       Commit;
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
                   'SC_FC01_LRO_E_OH_HIST',
                   NULL,
                   'CRPSC');

      COMMIT;

      FOR FC01_LRO_HIST_REC IN SC_FC01_CUR_LRO_OH_HIST
      LOOP
         --  EXIT WHEN FC01_LRO_HIST_REC%IS NULL;

         INSERT INTO SC_FC01_OH_HIST_LRO (PRODUCT_ID,
                                          CISCO_MFG_PART_NUM,
                                          PARTNER_ID,
                                          PO_NUMBER,
                                          PO_LINE_NUMBER,
                                          DELIVERY_LINE_NUMBER,
                                          TRANSACTION_ID,
                                          RECEIPT_NUMBER,
                                          DOCUMENT_ID,
                                          RECORD_STATUS,
                                          LINE_RECORD_STATUS,
                                          HUB_LOCATION,
                                          INVENTORY_LOCATION_TYPE,
                                          EXPECTED_DATE,
                                          RECEIVED_DATE,
                                          AGING_INFO,
                                          RCT_CREATION_DATE,
                                          RCT_LAST_UPDATE_DATE,
                                          LINE_CREATION_DATE,
                                          LINE_LAST_UPDATE_DATE,
                                          EXPECTED_QTY,
                                          RECEIVED_QTY,
                                          AVAILABLE_QTY,
                                          ALLOCATED_QTY,
                                          PICKED_QTY,
                                          ONHOLD_QTY,
                                          INTRANSIT_QTY,
                                          RECORD_CREATED_ON,
                                          RECORD_CREATED_BY,
                                          RECORD_UPDATED_ON,
                                          RECORD_UPDATED_BY,
                                          REFRESH_PART_NUMBER,
                                          ROHS_FLAG,
                                          RUN_STATUS)
            SELECT PRODUCT_ID,
                   CISCO_MFG_PART_NUM,
                   PARTNER_ID,
                   PO_NUMBER,
                   PO_LINE_NUMBER,
                   DELIVERY_LINE_NUMBER,
                      TRANSACTION_ID
                   || DECODE (UPPER (stg.ROHS_FLAG), 'YES', 1, 0),        -->>
                   NULL,
                   DOCUMENT_ID,
                   RECORD_STATUS,
                   --NULL,
                   LINE_RECORD_STATUS,
                   HUB_LOCATION,
                   NULL,
                   NULL,
                   RECEIVED_DATE,
                   NULL,
                   RCT_CREATION_DATE,
                   RCT_LAST_UPDATE_DATE,
                   LINE_CREATION_DATE,
                   LINE_LAST_UPDATE_DATE,
                   NULL,
                   RECEIVED_QTY,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   SYSDATE,
                   NULL,
                   SYSDATE,
                   NULL,
                   REFRESH_PART_NUMBER,
                   ROHS_FLAG,
                   'CURRENT'
              FROM SC_FC01_OH_STG_LRO stg
             WHERE     stg.PRODUCT_ID = FC01_LRO_HIST_REC.PRODUCT_ID
                   AND stg.PO_NUMBER = FC01_LRO_HIST_REC.PO_NUMBER
                   AND stg.PO_LINE_NUMBER = FC01_LRO_HIST_REC.PO_LINE_NUMBER
                   AND stg.DELIVERY_LINE_NUMBER =
                          FC01_LRO_HIST_REC.DELIVERY_LINE_NUMBER
                   AND    stg.TRANSACTION_ID
                       || DECODE (UPPER (stg.ROHS_FLAG), 'YES', 1, 0) =
                          FC01_LRO_HIST_REC.TRANSACTION_ID
                   AND stg.REFRESH_PART_NUMBER =
                          FC01_LRO_HIST_REC.REFRESH_PART_NUMBER ---Added Refresh_part_number
                   AND stg.HUB_LOCATION = 'LRO'
                   AND stg.RECEIVED_DATE = FC01_LRO_HIST_REC.RECEIVED_DATE -->>
                   AND STG.REFRESH_PART_NUMBER LIKE '%WS'
                   AND STG.REFRESH_PART_NUMBER NOT LIKE '%RF'; -->> Added to filter only for FVE process
      -->> No Sum Calculated
      --              GROUP BY
      --                   PRODUCT_ID,
      --                    CISCO_MFG_PART_NUM,
      --                    PARTNER_ID,
      --                    PO_NUMBER,
      --                    PO_LINE_NUMBER,
      --                    DELIVERY_LINE_NUMBER,
      --                    TRANSACTION_ID || decode(upper(stg.ROHS_FLAG), 'YES', 1 , 0 ),
      --                    NULL,
      --                    DOCUMENT_ID,
      --                    RECORD_STATUS,
      --                    NULL,
      --                    HUB_LOCATION,
      --                    NULL,
      --                    NULL,
      --                    RECEIVED_DATE,
      --                    NULL,
      --                    RCT_CREATION_DATE,
      --                    RCT_LAST_UPDATE_DATE,
      --                    LINE_CREATION_DATE,
      --                    LINE_LAST_UPDATE_DATE,
      --                    NULL,
      --                    RECEIVED_QTY,
      --                    NULL,
      --                    NULL,
      --                    NULL,
      --                    NULL,
      --                    NULL,
      --                    sysdate,
      --                    NULL,
      --                    sysdate,
      --                    null,
      --                    REFRESH_PART_NUMBER,
      --                    ROHS_FLAG,
      --                    'CURRENT';
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
                   'SC_FC01_LRO_E_OH_HIST',
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
                      'SC_FC01_LRO_E_OH_HIST',
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
                      'SC_FC01_LRO_E_OH_HIST',
                      NULL,
                      'CRPSC');

         COMMIT;
   END SC_FC01_LRO_E_OH_HIST;

   /*-----------------------Procedure to calculate Delta value from SC_FC01_OH_STG_LRO table-------------------------------*/
   PROCEDURE SC_FC01_LRO_E_OH_DELTA
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

      CURSOR CUR_FC01_HIST
      IS
           SELECT A.*, ROWNUM
             FROM (  SELECT PRODUCT_ID,
                            PO_NUMBER,
                            PO_LINE_NUMBER,
                            DELIVERY_LINE_NUMBER,
                            HUB_LOCATION,
                            REFRESH_PART_NUMBER,
                            ROHS_FLAG,                          -->> Added New
                            RECEIVED_DATE -->> included received_date column as part of sc integration
                       FROM SC_FC01_OH_HIST_LRO
                      WHERE     RUN_STATUS = 'CURRENT'
                            AND REFRESH_PART_NUMBER LIKE '%WS'
                            AND REFRESH_PART_NUMBER NOT LIKE '%RF'
                   GROUP BY PRODUCT_ID,
                            PO_NUMBER,
                            PO_LINE_NUMBER,
                            DELIVERY_LINE_NUMBER,
                            HUB_LOCATION,
                            REFRESH_PART_NUMBER,
                            ROHS_FLAG,
                            RECEIVED_DATE -->> included received_date column as part of sc integration
                   ORDER BY PRODUCT_ID,
                            PO_NUMBER,
                            PO_LINE_NUMBER,
                            DELIVERY_LINE_NUMBER,
                            HUB_LOCATION,
                            REFRESH_PART_NUMBER,
                            ROHS_FLAG,                          -->> Added New
                            RECEIVED_DATE) A                              -->>
         ORDER BY ROWNUM;

      FC01_INV_RECORD      CUR_FC01_HIST%ROWTYPE;
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
                   'SC_FC01_LRO_E_OH_DELTA',
                   NULL,
                   'CRPSC');

      COMMIT;

      OPEN CUR_FC01_HIST;

      LOOP
         FETCH CUR_FC01_HIST INTO FC01_INV_RECORD;

         EXIT WHEN CUR_FC01_HIST%NOTFOUND;
         -->>> DeBug
         DBMS_OUTPUT.PUT_LINE (SYSDATE);
         DBMS_OUTPUT.PUT_LINE (
            'FC01_INV_RECORD.HUB_LOCATION:' || FC01_INV_RECORD.HUB_LOCATION);
         DBMS_OUTPUT.PUT_LINE (
            'FC01_INV_RECORD.PRODUCT_ID:' || FC01_INV_RECORD.PRODUCT_ID);
         DBMS_OUTPUT.PUT_LINE (
            'FC01_INV_RECORD.PO_NUMBER:' || FC01_INV_RECORD.PO_NUMBER);
         DBMS_OUTPUT.PUT_LINE (
               'FC01_INV_RECORD.PO_LINE_NUMBER:'
            || FC01_INV_RECORD.PO_LINE_NUMBER);
         DBMS_OUTPUT.PUT_LINE (
               'FC01_INV_RECORD.DELIVERY_LINE_NUMBER:'
            || FC01_INV_RECORD.DELIVERY_LINE_NUMBER);
         DBMS_OUTPUT.PUT_LINE (
               'FC01_INV_RECORD.REFRESH_PART_NUMBER:'
            || FC01_INV_RECORD.REFRESH_PART_NUMBER);
         DBMS_OUTPUT.PUT_LINE ('----------------');

         SELECT FC01_INV_RECORD.HUB_LOCATION INTO VAR_HUB_LOCATION FROM DUAL;

         IF VAR_HUB_LOCATION = 'LRO'
         THEN
            SELECT COUNT (*)
              INTO VAR_DELTA_COUNT
              FROM SC_FC01_OH_DELTA_LRO
             WHERE     HUB_LOCATION = FC01_INV_RECORD.HUB_LOCATION
                   AND PRODUCT_ID = FC01_INV_RECORD.PRODUCT_ID
                   AND PO_NUMBER = FC01_INV_RECORD.PO_NUMBER
                   AND PO_LINE_NUMBER = FC01_INV_RECORD.PO_LINE_NUMBER
                   AND DELIVERY_LINE_NUMBER =
                          FC01_INV_RECORD.DELIVERY_LINE_NUMBER -->> Added Newly
                   AND RCT_CREATION_DATE = FC01_INV_RECORD.RECEIVED_DATE -->> included received_date column as part of sc integration
                   AND ROHS_FLAG = FC01_INV_RECORD.ROHS_FLAG    -->> Added New
                   AND REFRESH_PART_NUMBER =
                          FC01_INV_RECORD.REFRESH_PART_NUMBER
                   AND REFRESH_PART_NUMBER LIKE '%WS'
                   AND REFRESH_PART_NUMBER NOT LIKE '%RF';

            ------ RECORD NOT PRESENT FOR PRODUCT IN DELTA
            IF VAR_DELTA_COUNT = 0
            THEN
               BEGIN
                  SELECT SUM (RECEIVED_QTY)
                    INTO VAR_QNTY
                    FROM SC_FC01_OH_HIST_LRO
                   WHERE     HUB_LOCATION = FC01_INV_RECORD.HUB_LOCATION
                         AND PRODUCT_ID = FC01_INV_RECORD.PRODUCT_ID
                         AND PO_NUMBER = FC01_INV_RECORD.PO_NUMBER
                         AND PO_LINE_NUMBER = FC01_INV_RECORD.PO_LINE_NUMBER
                         AND DELIVERY_LINE_NUMBER =
                                FC01_INV_RECORD.DELIVERY_LINE_NUMBER
                         AND REFRESH_PART_NUMBER =
                                FC01_INV_RECORD.REFRESH_PART_NUMBER
                         AND RECEIVED_DATE = FC01_INV_RECORD.RECEIVED_DATE -->> included received_date column as part of sc integration
                         AND REFRESH_PART_NUMBER LIKE '%WS'
                         AND REFRESH_PART_NUMBER NOT LIKE '%RF';



                  INSERT INTO SC_FC01_OH_DELTA_LRO (HUB_LOCATION,
                                                    PRODUCT_ID,
                                                    PO_NUMBER,
                                                    PO_LINE_NUMBER,
                                                    DELIVERY_LINE_NUMBER,
                                                    RECORD_CREATED_ON,
                                                    RECORD_CREATED_BY,
                                                    RECORD_UPDATED_ON,
                                                    RECORD_UPDATED_BY,
                                                    RECEIVED_QTY,
                                                    RCT_CREATION_DATE,
                                                    TRANSACTION_ID,
                                                    REFRESH_PART_NUMBER,
                                                    ROHS_FLAG,
                                                    PROCESSED_STATUS,
                                                    NEW_REC)
                     SELECT HUB_LOCATION,
                            PRODUCT_ID,
                            PO_NUMBER,
                            PO_LINE_NUMBER,
                            DELIVERY_LINE_NUMBER,
                            SYSDATE,
                            'WF_SC_FC01_LRO_HIST',
                            SYSDATE,
                            'SC_FC01_LRO_E_OH_DELTA_CALC',
                            VAR_QNTY,
                            RECEIVED_DATE,
                            -- RCT_CREATION_DATE,
                            TRANSACTION_ID,
                            REFRESH_PART_NUMBER,
                            ROHS_FLAG,
                            'N' PROCESSED_STATUS,
                            'Y' NEW_REC
                       FROM SC_FC01_OH_HIST_LRO
                      WHERE     HUB_LOCATION = FC01_INV_RECORD.HUB_LOCATION
                            AND PRODUCT_ID = FC01_INV_RECORD.PRODUCT_ID
                            AND PO_NUMBER = FC01_INV_RECORD.PO_NUMBER
                            AND PO_LINE_NUMBER =
                                   FC01_INV_RECORD.PO_LINE_NUMBER
                            AND DELIVERY_LINE_NUMBER =
                                   FC01_INV_RECORD.DELIVERY_LINE_NUMBER
                            AND REFRESH_PART_NUMBER =
                                   FC01_INV_RECORD.REFRESH_PART_NUMBER
                            AND RECEIVED_DATE = FC01_INV_RECORD.RECEIVED_DATE -->> included received_date column as part of sc integration
                            AND RUN_STATUS = 'CURRENT'
                            AND REFRESH_PART_NUMBER LIKE '%WS'
                            AND REFRESH_PART_NUMBER NOT LIKE '%RF';

                  COMMIT;

                  DBMS_OUTPUT.PUT_LINE (
                     'DELTA INSERTED WHEN NOT PRESENT IN DELTA');

                  UPDATE SC_FC01_OH_HIST_LRO
                     SET RUN_STATUS =
                            CASE
                               WHEN RUN_STATUS = 'LASTRUN' THEN 'HISTORY'
                               WHEN RUN_STATUS = 'CURRENT' THEN 'LASTRUN'
                               ELSE 'HISTORY'
                            END,
                         RECORD_UPDATED_ON = SYSDATE,
                         RECORD_UPDATED_BY = 'SC_FC01_LRO_E_OH_DELTA_CALC' -->> Need to check
                   WHERE     UPPER (PRODUCT_ID) =
                                UPPER (FC01_INV_RECORD.PRODUCT_ID)
                         AND UPPER (PO_NUMBER) =
                                UPPER (FC01_INV_RECORD.PO_NUMBER)
                         AND UPPER (PO_LINE_NUMBER) =
                                UPPER (FC01_INV_RECORD.PO_LINE_NUMBER)
                         AND DELIVERY_LINE_NUMBER =
                                FC01_INV_RECORD.DELIVERY_LINE_NUMBER
                         AND UPPER (HUB_LOCATION) =
                                UPPER (FC01_INV_RECORD.HUB_LOCATION)
                         AND UPPER (REFRESH_PART_NUMBER) =
                                UPPER (FC01_INV_RECORD.REFRESH_PART_NUMBER)
                         AND RECEIVED_DATE = FC01_INV_RECORD.RECEIVED_DATE -->> included received_date column as part of sc integration
                         AND RUN_STATUS != 'HISTORY'
                         AND REFRESH_PART_NUMBER LIKE '%WS'
                         AND REFRESH_PART_NUMBER NOT LIKE '%RF';

                  COMMIT;

                  DBMS_OUTPUT.PUT_LINE (
                     'HISTORY UPDATED AFTER INSERTION INTO DELTA WHEN NOT PRESENT IN DELTA');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     RAISE_APPLICATION_ERROR (-20021, SQLERRM --  'PROBLEM IS WHILE INSERTING RECORDS INTO DELTA TABLE'
                                                             --FC01_INV_RECORD.REFRESH_PART_NUMBER
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
                                  'SC_FC01_LRO_E_OH_DELTA',
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
                                  'SC_FC01_LRO_E_OH_DELTA',
                                  NULL,
                                  'CRPSC');

                     COMMIT;
               END;
            ---- IF RECORD IS PRESENT IN DELTA
            ELSE
               SELECT MAX (TRANSACTION_ID)
                 INTO VAR_HIST_TRANS_ID
                 FROM SC_FC01_OH_HIST_LRO
                WHERE     UPPER (PRODUCT_ID) =
                             UPPER (FC01_INV_RECORD.PRODUCT_ID)
                      AND UPPER (PO_NUMBER) =
                             UPPER (FC01_INV_RECORD.PO_NUMBER)
                      AND UPPER (PO_LINE_NUMBER) =
                             UPPER (FC01_INV_RECORD.PO_LINE_NUMBER)
                      AND DELIVERY_LINE_NUMBER =
                             FC01_INV_RECORD.DELIVERY_LINE_NUMBER
                      AND UPPER (HUB_LOCATION) =
                             UPPER (FC01_INV_RECORD.HUB_LOCATION)
                      AND UPPER (REFRESH_PART_NUMBER) =
                             UPPER (FC01_INV_RECORD.REFRESH_PART_NUMBER)
                      AND RECEIVED_DATE = FC01_INV_RECORD.RECEIVED_DATE -->> included received_date column as part of sc integration
                      AND REFRESH_PART_NUMBER LIKE '%WS'
                      AND REFRESH_PART_NUMBER NOT LIKE '%RF';

               SELECT TRANSACTION_ID
                 INTO VAR_DELTA_TRANS_ID
                 FROM SC_FC01_OH_DELTA_LRO
                WHERE     UPPER (PRODUCT_ID) =
                             UPPER (FC01_INV_RECORD.PRODUCT_ID)
                      AND UPPER (PO_NUMBER) =
                             UPPER (FC01_INV_RECORD.PO_NUMBER)
                      AND UPPER (PO_LINE_NUMBER) =
                             UPPER (FC01_INV_RECORD.PO_LINE_NUMBER)
                      AND DELIVERY_LINE_NUMBER =
                             FC01_INV_RECORD.DELIVERY_LINE_NUMBER
                      AND UPPER (HUB_LOCATION) =
                             UPPER (FC01_INV_RECORD.HUB_LOCATION)
                      AND UPPER (REFRESH_PART_NUMBER) =
                             UPPER (FC01_INV_RECORD.REFRESH_PART_NUMBER)
                      AND UPPER (ROHS_FLAG) =
                             UPPER (FC01_INV_RECORD.ROHS_FLAG)
                      AND RCT_CREATION_DATE = FC01_INV_RECORD.RECEIVED_DATE -->> included received_date column as part of sc integration
                      AND REFRESH_PART_NUMBER LIKE '%WS'
                      AND REFRESH_PART_NUMBER NOT LIKE '%RF';

               SELECT SUM (RECEIVED_QTY)
                 INTO VAR_CUR_QTY
                 FROM SC_FC01_OH_HIST_LRO
                WHERE     UPPER (PRODUCT_ID) =
                             UPPER (FC01_INV_RECORD.PRODUCT_ID)
                      AND UPPER (PO_NUMBER) =
                             UPPER (FC01_INV_RECORD.PO_NUMBER)
                      AND UPPER (PO_LINE_NUMBER) =
                             UPPER (FC01_INV_RECORD.PO_LINE_NUMBER)
                      AND DELIVERY_LINE_NUMBER =
                             FC01_INV_RECORD.DELIVERY_LINE_NUMBER
                      AND UPPER (HUB_LOCATION) =
                             UPPER (FC01_INV_RECORD.HUB_LOCATION)
                      AND UPPER (REFRESH_PART_NUMBER) =
                             UPPER (FC01_INV_RECORD.REFRESH_PART_NUMBER)
                      AND RECEIVED_DATE = FC01_INV_RECORD.RECEIVED_DATE -->> included received_date column as part of sc integration
                      AND TRANSACTION_ID = VAR_HIST_TRANS_ID
                      AND REFRESH_PART_NUMBER LIKE '%WS'
                      AND REFRESH_PART_NUMBER NOT LIKE '%RF';

               SELECT SUM (RECEIVED_QTY)
                 INTO VAR_LR_QTY
                 FROM SC_FC01_OH_HIST_LRO
                WHERE     UPPER (PRODUCT_ID) =
                             UPPER (FC01_INV_RECORD.PRODUCT_ID)
                      AND UPPER (PO_NUMBER) =
                             UPPER (FC01_INV_RECORD.PO_NUMBER)
                      AND UPPER (PO_LINE_NUMBER) =
                             UPPER (FC01_INV_RECORD.PO_LINE_NUMBER)
                      AND DELIVERY_LINE_NUMBER =
                             FC01_INV_RECORD.DELIVERY_LINE_NUMBER
                      AND UPPER (HUB_LOCATION) =
                             UPPER (FC01_INV_RECORD.HUB_LOCATION)
                      AND UPPER (REFRESH_PART_NUMBER) =
                             UPPER (FC01_INV_RECORD.REFRESH_PART_NUMBER)
                      AND RECEIVED_DATE = FC01_INV_RECORD.RECEIVED_DATE -->> included received_date column as part of sc integration
                      AND TRANSACTION_ID = VAR_DELTA_TRANS_ID
                      AND REFRESH_PART_NUMBER LIKE '%WS'
                      AND REFRESH_PART_NUMBER NOT LIKE '%RF';

               VAR_QTY := VAR_CUR_QTY - VAR_LR_QTY;

               IF VAR_HIST_TRANS_ID - VAR_DELTA_TRANS_ID = 0
               THEN
                  UPDATE SC_FC01_OH_DELTA_LRO
                     SET RECEIVED_QTY = VAR_QTY,
                         RECORD_UPDATED_ON = SYSDATE,
                         RECORD_UPDATED_BY = 'SC_FC01_LRO_E_OH_DELTA_CALC',
                         NEW_REC = 'Y'
                   WHERE     UPPER (PRODUCT_ID) =
                                UPPER (FC01_INV_RECORD.PRODUCT_ID)
                         AND UPPER (PO_NUMBER) =
                                UPPER (FC01_INV_RECORD.PO_NUMBER)
                         AND UPPER (PO_LINE_NUMBER) =
                                UPPER (FC01_INV_RECORD.PO_LINE_NUMBER)
                         AND DELIVERY_LINE_NUMBER =
                                FC01_INV_RECORD.DELIVERY_LINE_NUMBER
                         AND UPPER (HUB_LOCATION) =
                                UPPER (FC01_INV_RECORD.HUB_LOCATION)
                         AND UPPER (REFRESH_PART_NUMBER) =
                                UPPER (FC01_INV_RECORD.REFRESH_PART_NUMBER)
                         AND RCT_CREATION_DATE =
                                FC01_INV_RECORD.RECEIVED_DATE -->> included received_date column as part of sc integration
                         AND REFRESH_PART_NUMBER LIKE '%WS'
                         AND REFRESH_PART_NUMBER NOT LIKE '%RF';

                  COMMIT;
               ELSE
                  UPDATE SC_FC01_OH_DELTA_LRO
                     SET RECEIVED_QTY = VAR_QTY,
                         RECORD_UPDATED_ON = SYSDATE,
                         RECORD_UPDATED_BY = 'SC_FC01_LRO_E_OH_DELTA_CALC',
                         TRANSACTION_ID = VAR_HIST_TRANS_ID,
                         NEW_REC = 'Y'
                   WHERE     UPPER (PRODUCT_ID) =
                                UPPER (FC01_INV_RECORD.PRODUCT_ID)
                         AND UPPER (PO_NUMBER) =
                                UPPER (FC01_INV_RECORD.PO_NUMBER)
                         AND UPPER (PO_LINE_NUMBER) =
                                UPPER (FC01_INV_RECORD.PO_LINE_NUMBER)
                         AND DELIVERY_LINE_NUMBER =
                                FC01_INV_RECORD.DELIVERY_LINE_NUMBER
                         AND UPPER (HUB_LOCATION) =
                                UPPER (FC01_INV_RECORD.HUB_LOCATION)
                         AND UPPER (REFRESH_PART_NUMBER) =
                                UPPER (FC01_INV_RECORD.REFRESH_PART_NUMBER)
                         AND RCT_CREATION_DATE =
                                FC01_INV_RECORD.RECEIVED_DATE -->> included received_date column as part of sc integration
                         AND REFRESH_PART_NUMBER LIKE '%WS'
                         AND REFRESH_PART_NUMBER NOT LIKE '%RF';

                  DBMS_OUTPUT.PUT_LINE (
                     'DELTA UPDATED WHEN TRANSACTION ID ARE NOT EQUAL FOR A PARTICULAR PRODUCT');
                  COMMIT;

                  UPDATE SC_FC01_OH_HIST_LRO
                     SET RUN_STATUS =
                            CASE
                               WHEN RUN_STATUS = 'LASTRUN' THEN 'HISTORY'
                               WHEN RUN_STATUS = 'CURRENT' THEN 'LASTRUN'
                               ELSE 'HISTORY'
                            END,
                         RECORD_UPDATED_ON = SYSDATE,
                         RECORD_UPDATED_BY = 'SC_FC01_LRO_E_OH_DELTA_CALC'
                   WHERE     UPPER (PRODUCT_ID) =
                                UPPER (FC01_INV_RECORD.PRODUCT_ID)
                         AND UPPER (PO_NUMBER) =
                                UPPER (FC01_INV_RECORD.PO_NUMBER)
                         AND UPPER (PO_LINE_NUMBER) =
                                UPPER (FC01_INV_RECORD.PO_LINE_NUMBER)
                         AND DELIVERY_LINE_NUMBER =
                                FC01_INV_RECORD.DELIVERY_LINE_NUMBER
                         AND UPPER (HUB_LOCATION) =
                                UPPER (FC01_INV_RECORD.HUB_LOCATION)
                         AND UPPER (REFRESH_PART_NUMBER) =
                                UPPER (FC01_INV_RECORD.REFRESH_PART_NUMBER)
                         AND RECEIVED_DATE = FC01_INV_RECORD.RECEIVED_DATE -->> included received_date column as part of sc integration
                         AND RUN_STATUS != 'HISTORY'
                         AND REFRESH_PART_NUMBER LIKE '%WS'
                         AND REFRESH_PART_NUMBER NOT LIKE '%RF';

                  DBMS_OUTPUT.PUT_LINE (
                     'HISTORY UPDATED AFTER UPDATION OF DELTA WHEN TRANSACTION ID ARE NOT EQUAL FOR A PARTICULAR PRODUCT');
               END IF;
            END IF;
         END IF;

         COMMIT;
      END LOOP;

      CLOSE CUR_FC01_HIST;

      INSERT INTO SC_FC01_OH_DELTA_LRO_HIST (PRODUCT_ID,
                                             PO_NUMBER,
                                             PO_LINE_NUMBER,
                                             DELIVERY_LINE_NUMBER,
                                             RECEIVED_QTY,
                                             RECORD_CREATED_BY,
                                             RECORD_CREATED_ON,
                                             HUB_LOCATION,
                                             RECORD_UPDATED_BY,
                                             RECORD_UPDATED_ON,
                                             RCT_CREATION_DATE,
                                             TRANSACTION_ID,
                                             REFRESH_PART_NUMBER,
                                             ROHS_FLAG,
                                             PROCESSED_STATUS)
         SELECT PRODUCT_ID,
                PO_NUMBER,
                PO_LINE_NUMBER,
                DELIVERY_LINE_NUMBER,
                RECEIVED_QTY,
                RECORD_CREATED_BY,
                RECORD_CREATED_ON,
                HUB_LOCATION,
                RECORD_UPDATED_BY,
                RECORD_UPDATED_ON,
                RCT_CREATION_DATE,
                TRANSACTION_ID,
                REFRESH_PART_NUMBER,
                ROHS_FLAG,
                PROCESSED_STATUS
           FROM SC_FC01_OH_DELTA_LRO
          WHERE     NEW_REC = 'Y'
                AND RECEIVED_QTY != 0
                AND REFRESH_PART_NUMBER LIKE '%WS'
                AND REFRESH_PART_NUMBER NOT LIKE '%RF';

      COMMIT;

      UPDATE SC_FC01_OH_DELTA_LRO
         SET NEW_REC = 'N'
       WHERE     REFRESH_PART_NUMBER LIKE '%WS'
             AND REFRESH_PART_NUMBER NOT LIKE '%RF';

      COMMIT;

      --    DELETE FROM SC_FC01_OH_DELTA_LRO
      --    WHERE TOTAL_QTY = 0;

      COMMIT;

      DBMS_OUTPUT.PUT_LINE ('Records got inserted into Delta_hist table');

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
                   'SC_FC01_LRO_E_OH_DELTA',
                   NULL,
                   'CRPSC');

      COMMIT;
   END SC_FC01_LRO_E_OH_DELTA;
END SC_FC01_LRO_E_OH_DELTA_CALC;
/