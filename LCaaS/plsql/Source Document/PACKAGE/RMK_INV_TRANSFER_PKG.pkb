CREATE OR REPLACE PACKAGE BODY RMKTGADM./*AppDB: 1044181*/
                                                                                     "RMK_INV_TRANSFER_PKG"
AS
    v_message   VARCHAR2 (32767);

    /*
   ****************************************************************************************************************
   * Object Name       :RMK_INV_TRANSFER_PKG
   *  Project Name : Refresh Central
    * Copy Rights:   Cisco Systems, INC., CALIFORNIA
   * Description       : This API for Inventory Adjustment utility to adjust/transfer inventory between different programs (Retail, Outlet and Excess)
   * Created Date: 9th Jan, 2017
   ===================================================================================================+
   * Version              Date                      Modified by                     Description
   ===================================================================================================+
    1.0                   30th Jan, 2017            satbanda                     Created for Inventory Adjustment utility to adjust/transfer inventory between different programs (Retail, Outlet and Excess)
    1.1                   2nd  Feb, 2017            satbanda                     Modified for Restrict the transaction/Adjustment if any pending or incomplete transaction for respective PID and location.
    1.2                   7th  Feb, 2017            satbanda                     Modified for Program Type value of Inventory Adjustment.
    1.3                   9th  Feb, 2017            hkarka                       Modified for code to insert NEW_DGI incase of GDGI inventory
    1.4                  17th  Feb, 2017            satbanda                     Modified for display the all locations while adjustment
    1.5                   1st  Mar, 2017            satbanda                     Modified for Request and Approval changes.
    1.6                   8th  Mar, 2017            satbanda                     Modified for Sorting of Pending transactions
    2.0                   2nd  Aug, 2017            satbanda                     Added for US123787 - Inventory Adjustments Upload feature
    3.0                   10th Oct, 2017            satbanda                     Modified for US137794- Inventory Admin Utility Enhancements
    4.0                   25-Oct-2017               satbanda                     US137794# Inventory transfer requests email notifications
    5.0                   04th Jan,2018             satbanda                     US157355# Trigger Email notification for Refresh Inventory Admin
    5.1                   09-Jan-2018               satbanda                     US161611# New Email triggered features
    5.2                  24th Jan 2018              sridvasu                     US161611# Modifed status from 'PROCESSED' to 'APPROVED', added column for additional comments and created a procedure to update 'Additional_Comments' column
    5.3                   14-Jun-2019               sridvasu                     US269991# DGI Transfer - New transaction type
    5.4                   26-AUG-2019               mohamms2                     US269991# DGI Transfer - Enhancement to send Approval mail notification to respective repair partners.
    5.5                   24-Oct-2019               sneyadav                     Added Masked quantity for transaction type Adjustment, Retail to Outlet and Outlet to Retail.
    6                     30-June-2020              mabvenka                     PRB0062429-DGI Transfer Request not communicated to the partner
    6.1                   04-Aug-2020               mkalidos                     PRB0067313-FVE inventory movements is not correct for some PIDS
    6.1                   01-JUL-2020               csirigir                     US398932# Added to show consolidated POE in UI
   ===================================================================================================+
    **************************************************************************************************************** */


    PROCEDURE P_RCEC_ERROR_LOG (i_Module_Name        VARCHAR2,
                                i_Entity_Name        VARCHAR2 DEFAULT NULL,
                                i_Entity_ID          VARCHAR2 DEFAULT NULL,
                                i_EXT_Entity_Name    VARCHAR2 DEFAULT NULL,
                                i_EXT_Entity_ID      VARCHAR2 DEFAULT NULL,
                                i_Error_Type         VARCHAR2,
                                i_Error_Message      VARCHAR2,
                                i_Created_by         VARCHAR2,
                                i_UPDATED_BY         VARCHAR2)
    AS
        l_errid   NUMBER;
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        v_message := NULL;

        SELECT RMK_INV_ERROR_S.NEXTVAL INTO l_errid FROM DUAL;

        INSERT INTO RMK_INV_ERROR_LOG (ERR_ID,
                                       Module_Name,
                                       Entity_Name,
                                       Entity_ID,
                                       EXT_Entity_Name,
                                       EXT_Entity_ID,
                                       ERROR_TYPE,
                                       Error_Message,
                                       CREATED_BY,
                                       CREATION_DATE,
                                       LAST_UPDATED_BY,
                                       LAST_UPDATE_DATE)
             VALUES (l_errid,
                     i_Module_Name,
                     i_Entity_Name,
                     i_Entity_ID,
                     i_EXT_Entity_Name,
                     i_EXT_Entity_ID,
                     i_Error_Type,
                     i_Error_Message,
                     i_CREATED_BY,
                     SYSDATE,
                     i_UPDATED_BY,
                     SYSDATE);

        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            -- Log Exception
            v_message :=
                   SUBSTR (SQLERRM, 1, 200)
                || ' i_Module_Name->'
                || i_Module_Name
                || ' i_Entity_Name->'
                || i_Entity_Name
                || ' i_Entity_ID->'
                || i_Entity_ID
                || ' i_EXT_Entity_Name->'
                || i_EXT_Entity_Name
                || ' i_EXT_Entity_ID->'
                || i_EXT_Entity_ID
                || ' i_Error_Type->'
                || i_Error_Type
                || ' i_Error_Message->'
                || i_Error_Message
                || ' i_CREATED_BY->'
                || i_CREATED_BY
                || ' i_UPDATED_BY->'
                || i_UPDATED_BY;

            SELECT RMK_INV_ERROR_S.NEXTVAL INTO l_errid FROM DUAL;

            INSERT INTO RMK_INV_ERROR_LOG (ERR_ID,
                                           Module_Name,
                                           Error_Message,
                                           CREATION_DATE)
                 VALUES (l_errid,
                         'ERROR_LOG',
                         v_message,
                         SYSDATE);

            COMMIT;
    END P_RCEC_ERROR_LOG;

    PROCEDURE P_INV_TRANSFER (
        i_part_number        IN            VARCHAR2,
        i_trans_type         IN            VARCHAR2,
        o_trans_info_tab        OUT NOCOPY RMK_INV_TRANSFER_INFO_TAB,
        o_trans_dtl_tab         OUT NOCOPY RMK_INV_TRANSFER_DTL_TAB,
        o_trans_status_tab      OUT NOCOPY RMK_INV_MOVE_STATUS_TAB)
    AS
        type_inv_transfer_info_tab   RMK_INV_TRANSFER_INFO_TAB
                                         := RMK_INV_TRANSFER_INFO_TAB ();
        type_inv_transfer_dtl_tab    RMK_INV_TRANSFER_DTL_TAB
                                         := RMK_INV_TRANSFER_DTL_TAB ();
        type_inv_transfer_sts_tab    RMK_INV_MOVE_STATUS_TAB
                                         := RMK_INV_MOVE_STATUS_TAB ();
        v_pending_trans_flag         VARCHAR2 (1) := 'N';
    BEGIN
        v_message := NULL;

        WITH
            RMK_INV_TRNS_INFO
            AS
                (SELECT DISTINCT
                        pm.REFRESH_PART_NUMBER,
                        pm.ROHS_CHECK_NEEDED,
                        MOS.MOS,
                        (SELECT SUM (CURRENT_MAX)
                           FROM CRPSC.RC_GBP_CURRENT_MAX_PRIORITY
                          WHERE REFRESH_INVENTORY_ITEM_ID =
                                PM.REFRESH_INVENTORY_ITEM_ID)
                            Retail_Max,
                        (SELECT CASE
                                    WHEN MAX (YTD_AVG_SALES_PRICE) < 750
                                    THEN
                                        250
                                    WHEN MAX (YTD_AVG_SALES_PRICE) BETWEEN 751
                                                                       AND 5000
                                    THEN
                                        10
                                    WHEN MAX (YTD_AVG_SALES_PRICE) BETWEEN 5001
                                                                       AND 10000
                                    THEN
                                        5
                                    WHEN MAX (YTD_AVG_SALES_PRICE) BETWEEN 10001
                                                                       AND 25000
                                    THEN
                                        3
                                    WHEN MAX (YTD_AVG_SALES_PRICE) > 25000
                                    THEN
                                        1
                                END
                                    OutletCap
                           FROM CRPSC.RC_R12_SHIPMENT_HISTORY
                          WHERE REFRESH_INVENTORY_ITEM_ID =
                                PM.REFRESH_INVENTORY_ITEM_ID)
                            OUTLET_CAP,
                        (SELECT MAX (YTD_AVG_SALES_PRICE)
                           FROM CRPSC.RC_R12_SHIPMENT_HISTORY
                          WHERE REFRESH_INVENTORY_ITEM_ID =
                                PM.REFRESH_INVENTORY_ITEM_ID)
                            YTD_AVG_SALES_PRICE,
                        f_get_outletelg_flag (PM.REFRESH_PART_NUMBER,
                                              MOS.MOS)
                            OUTLET_ELGBL
                   FROM CRPADM.RC_PRODUCT_MASTER  PM
                        INNER JOIN RMKTGADM.XXCPO_RMK_INVENTORY_MASTER IM
                            ON (    PM.REFRESH_PART_NUMBER = IM.PART_NUMBER
                                AND IM.SITE_CODE IN ('LRO', 'FVE', 'GDGI'))
                        LEFT OUTER JOIN
                        (SELECT DISTINCT MOS, REFRESH_INVENTORY_ITEM_ID
                           FROM VAVNI_CISCO_RSCM_BP.VV_BP_MON_ROLLING_SHIP_DATA_VW
                                MOS
                                INNER JOIN
                                CRPADM.RC_PRODUCT_MAPID_MAPPING MAP
                                    ON (MAP.PRODUCT_MAP_ID = MOS.PRODUCT_ID))
                        MOS
                            ON (MOS.REFRESH_INVENTORY_ITEM_ID =
                                PM.REFRESH_INVENTORY_ITEM_ID)
                  WHERE PM.REFRESH_PART_NUMBER = i_part_number --AND PM.REFRESH_PART_NUMBER NOT IN (SELECT REFRESH_PART_NUMBER FROM RC_INV_EXCLUDE_PIDS)--Commented exclude check on 9thMarch,2017 as per mail confirmation
                                                              )
        SELECT RMK_INV_TRANSFER_INFO_OBJECT (REFRESH_PART_NUMBER,
                                             ROHS_CHECK_NEEDED,
                                             NVL (MOS, 0),
                                             NVL (RETAIL_MAX, 0),
                                             NVL (OUTLET_CAP, 0),
                                             NVL (YTD_AVG_SALES_PRICE, 0),
                                             OUTLET_ELGBL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL)
          BULK COLLECT INTO type_inv_transfer_info_tab
          FROM RMK_INV_TRNS_INFO;

        o_trans_info_tab := type_inv_transfer_info_tab;

        IF i_trans_type = v_Retail_Outlet
        THEN
              SELECT RMK_INV_TRANSFER_DTL_OBJECT (
                         part_number,
                         site_code,
                         rohs_compliant,
                         NVL (R_AVAILABLE_QUANTITY, 0),
                         NVL (R_RESERVED_QUANTITY, 0),
                         NVL (R_AVAILBLE_TO_RESERVE_QTY, 0),
                         NVL (O_AVAILABLE_QUANTITY, 0),
                         NVL (O_RESERVED_QUANTITY, 0),
                         NVL (O_AVAILBLE_TO_RESERVE_QTY, 0),
                         NULL,
                         NULL,
                         Restriction_flag,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NVL (MASKED_QTY, 0),              --added by sneyadav
                         					     NULL)                 --Added by csirigir on 01-JUL-2020 as part of US398932
                BULK COLLECT INTO type_inv_transfer_dtl_tab
                FROM (WITH
                          RO_INV_DATA
                          AS
                              (  SELECT part_number,
                                        inventory_flow,
                                        site_code,
                                        rohs_compliant,
                                        SUM (
                                            DECODE (site_code,
                                                    'GDGI', available_dgi,
                                                    available_fgi))
                                            Available_Quantity,
                                        SUM (
                                            DECODE (site_code,
                                                    'GDGI', reserved_dgi,
                                                    reserved_fgi))
                                            Reserved_Quantity,
                                        SUM (
                                            DECODE (
                                                site_code,
                                                'GDGI', available_to_reserve_dgi,
                                                available_to_reserve_fgi))
                                            Availble_to_Reserve_Qty,
                                        CASE
                                            WHEN     site_code = 'LRO'
                                                 AND rohs_compliant = 'YES'
                                            THEN
                                                lro_rhs_quantity
                                            WHEN     site_code = 'LRO'
                                                 AND rohs_compliant = 'NO'
                                            THEN
                                                lro_nrhs_quantity
                                            WHEN     site_code = 'FVE'
                                                 AND rohs_compliant = 'YES'
                                            THEN
                                                fve_rhs_quantity
                                            ELSE
                                                0
                                        END
                                            AS Masked_qty
                                   FROM rmktgadm.xxcpo_rmk_inventory_master rm
                                        LEFT OUTER JOIN
                                        rmktgadm.rc_inv_str_inv_mask_mv rc
                                            ON rc.partnumber = rm.part_number
                                  WHERE     rm.part_number = i_part_number
                                        AND site_code IN ('LRO', 'FVE', 'GDGI')
                                        AND inventory_flow = 'Retail'
                               GROUP BY part_number,
                                        inventory_flow,
                                        site_code,
                                        rohs_compliant,
                                        lro_rhs_quantity,
                                        lro_nrhs_quantity,
                                        fve_rhs_quantity
                               UNION
                                 SELECT part_number,
                                        inventory_flow,
                                        site_code,
                                        rohs_compliant,
                                        SUM (
                                            DECODE (site_code,
                                                    'GDGI', available_dgi,
                                                    available_fgi))
                                            Available_Quantity,
                                        SUM (
                                            DECODE (site_code,
                                                    'GDGI', reserved_dgi,
                                                    reserved_fgi))
                                            Reserved_Quantity,
                                        SUM (
                                            DECODE (
                                                site_code,
                                                'GDGI', available_to_reserve_dgi,
                                                available_to_reserve_fgi))
                                            Availble_to_Reserve_Qty,
                                        NULL
                                   FROM rmktgadm.xxcpo_rmk_inventory_master
                                  WHERE     part_number = i_part_number
                                        AND site_code IN ('LRO', 'FVE', 'GDGI')
                                        AND inventory_flow = 'Outlet'
                               GROUP BY part_number,
                                        inventory_flow,
                                        site_code,
                                        rohs_compliant)
                        SELECT part_number,
                               site_code,
                               rohs_compliant,
                               f_get_pending_flag (part_number,
                                                   site_code,
                                                   rohs_compliant)
                                   Restriction_flag,
                               (SELECT AVAILABLE_QUANTITY
                                  FROM RO_INV_DATA
                                 WHERE     1 = 1 --inventory_flow=Site_ROHS.inventory_flow
                                       AND site_code = Site_ROHS.site_code
                                       AND rohs_compliant =
                                           Site_ROHS.rohs_compliant
                                       AND inventory_flow = 'Retail')
                                   R_AVAILABLE_QUANTITY,
                               (SELECT RESERVED_QUANTITY
                                  FROM RO_INV_DATA
                                 WHERE     1 = 1 --inventory_flow=Site_ROHS.inventory_flow
                                       AND site_code = Site_ROHS.site_code
                                       AND rohs_compliant =
                                           Site_ROHS.rohs_compliant
                                       AND inventory_flow = 'Retail')
                                   R_RESERVED_QUANTITY,
                               (SELECT AVAILBLE_TO_RESERVE_QTY
                                  FROM RO_INV_DATA
                                 WHERE     1 = 1 --inventory_flow=Site_ROHS.inventory_flow
                                       AND site_code = Site_ROHS.site_code
                                       AND rohs_compliant =
                                           Site_ROHS.rohs_compliant
                                       AND inventory_flow = 'Retail')
                                   R_AVAILBLE_TO_RESERVE_QTY,
                               (SELECT AVAILABLE_QUANTITY
                                  FROM RO_INV_DATA
                                 WHERE     1 = 1 --inventory_flow=Site_ROHS.inventory_flow
                                       AND site_code = Site_ROHS.site_code
                                       AND rohs_compliant =
                                           Site_ROHS.rohs_compliant
                                       AND inventory_flow = 'Outlet')
                                   O_AVAILABLE_QUANTITY,
                               (SELECT RESERVED_QUANTITY
                                  FROM RO_INV_DATA
                                 WHERE     1 = 1 --inventory_flow=Site_ROHS.inventory_flow
                                       AND site_code = Site_ROHS.site_code
                                       AND rohs_compliant =
                                           Site_ROHS.rohs_compliant
                                       AND inventory_flow = 'Outlet')
                                   O_RESERVED_QUANTITY,
                               (SELECT AVAILBLE_TO_RESERVE_QTY
                                  FROM RO_INV_DATA
                                 WHERE     1 = 1 --inventory_flow=Site_ROHS.inventory_flow
                                       AND site_code = Site_ROHS.site_code
                                       AND rohs_compliant =
                                           Site_ROHS.rohs_compliant
                                       AND inventory_flow = 'Outlet')
                                   O_AVAILBLE_TO_RESERVE_QTY,
                               DECODE (site_code,  'LRO', 1,  'FVE', 2,  3)
                                   Site_Sequence,
                               (SELECT MASKED_QTY
                                  FROM RO_INV_DATA
                                 WHERE     1 = 1 --inventory_flow=Site_ROHS.inventory_flow
                                       AND site_code = Site_ROHS.site_code
                                       AND rohs_compliant =
                                           Site_ROHS.rohs_compliant
                                       AND inventory_flow = 'Retail')
                                   MASKED_QTY
                          FROM (  SELECT inventory_flow,
                                         part_number,
                                         site_code,
                                         rohs_compliant
                                    FROM rmktgadm.xxcpo_rmk_inventory_master
                                   WHERE     part_number = i_part_number
                                         AND site_code IN ('LRO', 'FVE', 'GDGI')
                                         AND inventory_flow IN ('Retail', 'Outlet')
                                GROUP BY part_number,
                                         site_code,
                                         rohs_compliant,
                                         inventory_flow) Site_ROHS
                      GROUP BY part_number, site_code, rohs_compliant)
            ORDER BY Site_Sequence;
        ELSIF i_trans_type = v_Outlet_Retail
        THEN
              SELECT RMK_INV_TRANSFER_DTL_OBJECT (
                         part_number,
                         site_code,
                         rohs_compliant,
                         NVL (O_AVAILABLE_QUANTITY, 0),
                         NVL (O_RESERVED_QUANTITY, 0),
                         NVL (O_AVAILBLE_TO_RESERVE_QTY, 0),
                         NVL (R_AVAILABLE_QUANTITY, 0),
                         NVL (R_RESERVED_QUANTITY, 0),
                         NVL (R_AVAILBLE_TO_RESERVE_QTY, 0),
                         NULL,
                         NULL,
                         Restriction_flag,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NVL (MASKED_QTY, 0),              --added by sneyadav
					     NULL)                 --Added by csirigir on 01-JUL-2020 as part of US398932                         
                BULK COLLECT INTO type_inv_transfer_dtl_tab
                FROM (WITH
                          RO_INV_DATA
                          AS
                              (  SELECT part_number,
                                        inventory_flow,
                                        site_code,
                                        rohs_compliant,
                                        SUM (
                                            DECODE (site_code,
                                                    'GDGI', available_dgi,
                                                    available_fgi))
                                            Available_Quantity,
                                        SUM (
                                            DECODE (site_code,
                                                    'GDGI', reserved_dgi,
                                                    reserved_fgi))
                                            Reserved_Quantity,
                                        SUM (
                                            DECODE (
                                                site_code,
                                                'GDGI', available_to_reserve_dgi,
                                                available_to_reserve_fgi))
                                            Availble_to_Reserve_Qty,
                                        CASE
                                            WHEN     site_code = 'LRO'
                                                 AND rohs_compliant = 'YES'
                                            THEN
                                                lro_rhs_quantity
                                            WHEN     site_code = 'LRO'
                                                 AND rohs_compliant = 'NO'
                                            THEN
                                                lro_nrhs_quantity
                                            WHEN     site_code = 'FVE'
                                                 AND rohs_compliant = 'YES'
                                            THEN
                                                fve_rhs_quantity
                                            ELSE
                                                0
                                        END
                                            AS Masked_qty
                                   FROM rmktgadm.xxcpo_rmk_inventory_master rm
                                        LEFT OUTER JOIN
                                        rmktgadm.rc_inv_str_inv_mask_mv rc
                                            ON rc.partnumber = rm.part_number
                                  WHERE     rm.part_number = i_part_number
                                        AND site_code IN ('LRO', 'FVE', 'GDGI')
                                        AND inventory_flow = 'Retail'
                               GROUP BY part_number,
                                        inventory_flow,
                                        site_code,
                                        rohs_compliant,
                                        lro_rhs_quantity,
                                        lro_nrhs_quantity,
                                        fve_rhs_quantity
                               UNION
                                 SELECT part_number,
                                        inventory_flow,
                                        site_code,
                                        rohs_compliant,
                                        SUM (
                                            DECODE (site_code,
                                                    'GDGI', available_dgi,
                                                    available_fgi))
                                            Available_Quantity,
                                        SUM (
                                            DECODE (site_code,
                                                    'GDGI', reserved_dgi,
                                                    reserved_fgi))
                                            Reserved_Quantity,
                                        SUM (
                                            DECODE (
                                                site_code,
                                                'GDGI', available_to_reserve_dgi,
                                                available_to_reserve_fgi))
                                            Availble_to_Reserve_Qty,
                                        NULL
                                   FROM rmktgadm.xxcpo_rmk_inventory_master
                                  WHERE     part_number = i_part_number
                                        AND site_code IN ('LRO', 'FVE', 'GDGI')
                                        AND inventory_flow = 'Outlet'
                               GROUP BY part_number,
                                        inventory_flow,
                                        site_code,
                                        rohs_compliant)
                        SELECT part_number,
                               site_code,
                               rohs_compliant,
                               f_get_pending_flag (part_number,
                                                   site_code,
                                                   rohs_compliant)
                                   Restriction_flag,
                               (SELECT AVAILABLE_QUANTITY
                                  FROM RO_INV_DATA
                                 WHERE     1 = 1 --inventory_flow=Site_ROHS.inventory_flow
                                       AND site_code = Site_ROHS.site_code
                                       AND rohs_compliant =
                                           Site_ROHS.rohs_compliant
                                       AND inventory_flow = 'Retail')
                                   R_AVAILABLE_QUANTITY,
                               (SELECT RESERVED_QUANTITY
                                  FROM RO_INV_DATA
                                 WHERE     1 = 1 --inventory_flow=Site_ROHS.inventory_flow
                                       AND site_code = Site_ROHS.site_code
                                       AND rohs_compliant =
                                           Site_ROHS.rohs_compliant
                                       AND inventory_flow = 'Retail')
                                   R_RESERVED_QUANTITY,
                               (SELECT AVAILBLE_TO_RESERVE_QTY
                                  FROM RO_INV_DATA
                                 WHERE     1 = 1 --inventory_flow=Site_ROHS.inventory_flow
                                       AND site_code = Site_ROHS.site_code
                                       AND rohs_compliant =
                                           Site_ROHS.rohs_compliant
                                       AND inventory_flow = 'Retail')
                                   R_AVAILBLE_TO_RESERVE_QTY,
                               (SELECT AVAILABLE_QUANTITY
                                  FROM RO_INV_DATA
                                 WHERE     1 = 1 --inventory_flow=Site_ROHS.inventory_flow
                                       AND site_code = Site_ROHS.site_code
                                       AND rohs_compliant =
                                           Site_ROHS.rohs_compliant
                                       AND inventory_flow = 'Outlet')
                                   O_AVAILABLE_QUANTITY,
                               (SELECT RESERVED_QUANTITY
                                  FROM RO_INV_DATA
                                 WHERE     1 = 1 --inventory_flow=Site_ROHS.inventory_flow
                                       AND site_code = Site_ROHS.site_code
                                       AND rohs_compliant =
                                           Site_ROHS.rohs_compliant
                                       AND inventory_flow = 'Outlet')
                                   O_RESERVED_QUANTITY,
                               (SELECT AVAILBLE_TO_RESERVE_QTY
                                  FROM RO_INV_DATA
                                 WHERE     1 = 1 --inventory_flow=Site_ROHS.inventory_flow
                                       AND site_code = Site_ROHS.site_code
                                       AND rohs_compliant =
                                           Site_ROHS.rohs_compliant
                                       AND inventory_flow = 'Outlet')
                                   O_AVAILBLE_TO_RESERVE_QTY,
                               DECODE (site_code,  'LRO', 1,  'FVE', 2,  3)
                                   Site_Sequence,
                               (SELECT MASKED_QTY
                                  FROM RO_INV_DATA
                                 WHERE     1 = 1 --inventory_flow=Site_ROHS.inventory_flow
                                       AND site_code = Site_ROHS.site_code
                                       AND rohs_compliant =
                                           Site_ROHS.rohs_compliant
                                       AND inventory_flow = 'Retail')
                                   MASKED_QTY
                          FROM (  SELECT inventory_flow,
                                         part_number,
                                         site_code,
                                         rohs_compliant
                                    FROM rmktgadm.xxcpo_rmk_inventory_master
                                   WHERE     part_number = i_part_number
                                         AND site_code IN ('LRO', 'FVE', 'GDGI')
                                         AND inventory_flow IN ('Retail', 'Outlet')
                                GROUP BY part_number,
                                         site_code,
                                         rohs_compliant,
                                         inventory_flow) Site_ROHS
                      GROUP BY part_number, site_code, rohs_compliant)
            ORDER BY Site_Sequence;
        ELSIF i_trans_type = v_Adjustment
        THEN
            --Commented on 21st FEB, 2017 for display all locations apart of March17 Release <Start>
            /* SELECT RMK_INV_TRANSFER_DTL_OBJECT (
                      part_number,
                      site_code,
                      rohs_compliant,
                      NVL (Available_Quantity, 0),
                      NVL (Reserved_Quantity, 0),
                      NVL (Availble_to_Reserve_Qty, 0),
                      NULL,
                      NULL,
                      NULL,
                      inventory_flow,
                      NULL,
                      Restriction_flag,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL)
              BULK COLLECT INTO type_inv_transfer_dtl_tab
              FROM (  SELECT part_number,
                             inventory_flow,
                             site_code,
                             f_get_pending_flag(part_number,site_code,rohs_compliant) Restriction_flag,
                             rohs_compliant,
                             SUM (
                                DECODE (site_code,
                                        'GDGI', available_dgi,
                                        available_fgi))
                                Available_Quantity,
                             SUM (
                                DECODE (site_code,
                                        'GDGI', reserved_dgi,
                                        reserved_fgi))
                                Reserved_Quantity,
                             SUM (
                                DECODE (site_code,
                                        'GDGI', available_to_reserve_dgi,
                                        available_to_reserve_fgi))
                                Availble_to_Reserve_Qty,
                             DECODE (site_code,  'LRO', 1,  'FVE', 2,  3)
                                Site_Sequence
                        FROM rmktgadm.xxcpo_rmk_inventory_master
                       WHERE     part_number = i_part_number
                             AND site_code IN ('LRO', 'FVE', 'GDGI')
                             AND inventory_flow IN ('Retail', 'Outlet', 'Excess')
                    GROUP BY part_number,
                             inventory_flow,
                             site_code,
                             rohs_compliant
                    ORDER BY inventory_flow desc,Site_Sequence); */
            --Commented on 21st FEB, 2017 for display all locations apart of March17 Release <Start>

            --Added on 21st FEB, 2017 for display all locations apart of March17 Release <Start>
            SELECT RMK_INV_TRANSFER_DTL_OBJECT (
                       i_part_number,
                       site_code,
                       rohs_compliant,
                       NVL (Available_Quantity, 0),
                       NVL (Reserved_Quantity, 0),
                       NVL (Availble_to_Reserve_Qty, 0),
                       NULL,
                       NULL,
                       NULL,
                       inventory_flow,
                       NULL,
                       Restriction_flag,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NVL (MASKED_QTY, 0),                --added by sneyadav
					   NULL)                 --Added by csirigir on 01-JUL-2020 as part of US398932
              BULK COLLECT INTO type_inv_transfer_dtl_tab
              FROM (  SELECT i_part_number,
                             ris.inventory_flow,
                             ris.site_code,
                             f_get_pending_flag (i_part_number,
                                                 ris.site_code,
                                                 ris.rohs_compliant)
                                 Restriction_flag,
                             ris.rohs_compliant,
                             Available_Quantity,
                             Reserved_Quantity,
                             Availble_to_Reserve_Qty,
                             DECODE (ris.site_code,  'LRO', 1,  'FVE', 2,  3)
                                 Site_Sequence,
                             masked_qty
                        FROM (  SELECT inventory_flow,
                                       site_code,
                                       rohs_compliant,
                                       SUM (
                                           DECODE (site_code,
                                                   'GDGI', available_dgi,
                                                   available_fgi))
                                           Available_Quantity,
                                       SUM (
                                           DECODE (site_code,
                                                   'GDGI', reserved_dgi,
                                                   reserved_fgi))
                                           Reserved_Quantity,
                                       SUM (
                                           DECODE (
                                               site_code,
                                               'GDGI', available_to_reserve_dgi,
                                               available_to_reserve_fgi))
                                           Availble_to_Reserve_Qty,
                                       CASE
                                           WHEN     site_code = 'LRO'
                                                AND rohs_compliant = 'YES'
                                                AND inventory_flow = 'Retail'
                                           THEN
                                               lro_rhs_quantity
                                           WHEN     site_code = 'LRO'
                                                AND rohs_compliant = 'NO'
                                                AND inventory_flow = 'Retail'
                                           THEN
                                               lro_nrhs_quantity
                                           WHEN     site_code = 'FVE'
                                                AND rohs_compliant = 'YES'
                                                AND inventory_flow = 'Retail'
                                           THEN
                                               fve_rhs_quantity
                                           ELSE
                                               0
                                       END
                                           AS masked_qty
                                  FROM rmktgadm.xxcpo_rmk_inventory_master rm
                                       LEFT OUTER JOIN
                                       rmktgadm.rc_inv_str_inv_mask_mv rc
                                           ON rc.partnumber = rm.part_number
                                 WHERE     rm.part_number = i_part_number
                                       AND site_code IN ('LRO', 'FVE', 'GDGI')
                                       AND inventory_flow IN
                                               ('Retail', 'Outlet', 'Excess')
                              GROUP BY inventory_flow,
                                       site_code,
                                       rohs_compliant,
                                       lro_rhs_quantity,
                                       lro_nrhs_quantity,
                                       fve_rhs_quantity) xri,
                             --Added /Commented for WS PID changes to dispaly only Excess Program values <Start>
                             --rmktgadm.rmk_inv_site_code_dtl ris
                              (SELECT *
                                 FROM rmktgadm.rmk_inv_site_code_dtl
                                WHERE     (SELECT program_type
                                             FROM crpadm.rc_product_master
                                            WHERE refresh_part_number =
                                                  i_part_number) =
                                          0
                                      AND inventory_flow IN
                                              ('Retail', 'Outlet')
                               UNION
                               SELECT *
                                 FROM rmktgadm.rmk_inv_site_code_dtl
                                WHERE     (SELECT program_type
                                             FROM crpadm.rc_product_master
                                            WHERE refresh_part_number =
                                                  i_part_number) =
                                          1
                                      AND inventory_flow = 'Excess') ris
                       --Added /Commented for WS PID changes to dispaly only Excess Program values <End>
                       WHERE     ris.site_code IN ('LRO', 'FVE', 'GDGI')
                             AND ris.site_code = xri.site_code(+)
                             AND ris.rohs_compliant = xri.rohs_compliant(+)
                             AND ris.inventory_flow = xri.inventory_flow(+)
                    --Commented for WS PID changes to dispaly only Excess Program values <Start>
                    /*AND (ris.inventory_flow IN ('Retail', 'Outlet')
                         OR ris.inventory_flow =
                               (CASE
                                   WHEN (SELECT program_type
                                           FROM crpadm.rc_product_master
                                          WHERE refresh_part_number =
                                                   i_part_number) = 1 THEN 'Excess'
                                   ELSE '*'
                                END))*/
                    --Commented for WS PID changes to dispaly only Excess Program values <End>
                    ORDER BY inventory_flow DESC, Site_Sequence);
        --Added on 21st FEB, 2017 for display all locations apart of March17 Release <End>

        /* Start added as part of DGI Transfer changes on 14-Jun-2019 */
        ELSIF i_trans_type = v_dgi_transfer
        THEN
            SELECT RMK_INV_TRANSFER_DTL_OBJECT (part_number,
                                                site_code,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                restriction_flag,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                c3_onhand_qty,
                                                from_subinv,
                                                NULL,
                                                NULL,      --added by sneyadav
											    c3_onhand_qty_poe)  --Added by csirigir on 01-JUL-2020 as part of US398932                                                 
              BULK COLLECT INTO type_inv_transfer_dtl_tab
              FROM (SELECT part_number,
                           SUBSTR (site, 1, 3)
                               site_code,       -- changes done on 19-Jul-2019
                           qty_on_hand
                               c3_onhand_qty,
                           location
                               from_subinv,
                           F_GET_PENDING_DGI_FLAG (part_number,
                                                   SUBSTR (site, 1, 3),
                                                   location)
                               restriction_flag,
							( SELECT NVL(SUM(QTY_ON_HAND),0) FROM rc_inv_bts_c3_mv_poe   --Added by csirigir on 01-JUL-2020 as part of US398932
							   WHERE 1=1 
								AND REGEXP_LIKE(LOCATION,'^(POE-DGI|POE-NEW|POE-NEWX|POE-NRHS|POE-LT)')
								AND part_number IN
                                   (SELECT refresh_part_number
                                      FROM crpadm.rc_product_master
                                     WHERE (   refresh_part_number =
                                               i_part_number
                                            OR common_part_number =
                                               i_part_number
                                            OR xref_part_number =
                                               i_part_number)
                                    UNION
                                    SELECT common_part_number
                                      FROM crpadm.rc_product_master
                                     WHERE     (   refresh_part_number =
                                                   i_part_number
                                                OR common_part_number =
                                                   i_part_number
                                                OR xref_part_number =
                                                   i_part_number)
                                           AND common_part_number IS NOT NULL
                                    UNION
                                    SELECT xref_part_number
                                      FROM crpadm.rc_product_master
                                     WHERE     (   refresh_part_number =
                                                   i_part_number
                                                OR common_part_number =
                                                   i_part_number
                                                OR xref_part_number =
                                                   i_part_number)
                                           AND xref_part_number IS NOT NULL)) c3_onhand_qty_poe                               
                      FROM crpadm.rc_inv_bts_c3_mv
                     WHERE     1 = 1            -- part_number = i_part_number
                           AND site LIKE 'Z%'
                           AND qty_on_hand > 0 -->> not to pull qty on hand with 0 qty
                           AND part_number IN
                                   (SELECT refresh_part_number
                                      FROM crpadm.rc_product_master
                                     WHERE (   refresh_part_number =
                                               i_part_number
                                            OR common_part_number =
                                               i_part_number
                                            OR xref_part_number =
                                               i_part_number)
                                    UNION
                                    SELECT common_part_number
                                      FROM crpadm.rc_product_master
                                     WHERE     (   refresh_part_number =
                                                   i_part_number
                                                OR common_part_number =
                                                   i_part_number
                                                OR xref_part_number =
                                                   i_part_number)
                                           AND common_part_number IS NOT NULL
                                    UNION
                                    SELECT xref_part_number
                                      FROM crpadm.rc_product_master
                                     WHERE     (   refresh_part_number =
                                                   i_part_number
                                                OR common_part_number =
                                                   i_part_number
                                                OR xref_part_number =
                                                   i_part_number)
                                           AND xref_part_number IS NOT NULL));
        /* End added as part of DGI Transfer changes on 14-Jun-2019 */
        END IF;


        o_trans_dtl_tab := type_inv_transfer_dtl_tab;

        BEGIN
            IF i_part_number IS NOT NULL
            THEN
                SELECT RMK_INV_MOVE_STATUS_OBJECT (REQUEST_ID,
                                                   PART_NUMBER,
                                                   TRANSACTION_TYPE,
                                                   PROGRAM_TYPE,
                                                   SITE_CODE,
                                                   ROHS_COMPLIANT_FLAG,
                                                   QTY_TO_TRANSFER,
                                                   REQUESTED_BY,
                                                   REQUESTED_DATE,
                                                   APPROVED_BY,
                                                   APPROVED_DATE,
                                                   APROVAL_STATUS,
                                                   PROCESS_STATUS,
                                                   COMMENTS,
                                                   NULL,
                                                   APPROVER_COMMENTS,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   FROM_SUBINV,
                                                   TO_SUBINV,
                                                   STRATEGIC_MASKED_QTY)
                  BULK COLLECT INTO type_inv_transfer_sts_tab
                  FROM (  SELECT REQUEST_ID,
                                 PART_NUMBER,
                                 CASE
                                     WHEN TRANSACTION_TYPE = v_Retail_Outlet
                                     THEN
                                         'Retail to Outlet'
                                     WHEN TRANSACTION_TYPE = v_Outlet_Retail
                                     THEN
                                         'Outlet to Retail'
                                     WHEN TRANSACTION_TYPE = v_Adjustment
                                     THEN
                                            'Adjustment'
                                         || '-'
                                         || FROM_PROGRAM_TYPE
                                     WHEN TRANSACTION_TYPE = v_dgi_transfer
                                     THEN
                                         'DGI Transfer'
                                 END
                                     TRANSACTION_TYPE,
                                 NULL
                                     PROGRAM_TYPE,
                                 SITE_CODE,
                                 ROHS_COMPLIANT_FLAG,
                                 QTY_TO_TRANSFER,
                                 REQUESTED_BY,
                                 REQUESTED_DATE,
                                 APPROVED_BY,
                                 APPROVED_DATE,
                                 APROVAL_STATUS,
                                 PROCESS_STATUS,
                                 COMMENTS,
                                 APPROVER_COMMENTS,
                                 FROM_SUBINV,
                                 TO_SUBINV,
                                 CASE
                                     WHEN     SITE_CODE = 'LRO'
                                          AND ROHS_COMPLIANT_FLAG = 'YES'
                                     THEN
                                         NVL (SP.LRO_RHS_QUANTITY, 0)
                                     WHEN     SITE_CODE = 'FVE'
                                          AND ROHS_COMPLIANT_FLAG = 'YES'
                                     THEN
                                         NVL (SP.FVE_RHS_QUANTITY, 0)
                                     WHEN     SITE_CODE = 'LRO'
                                          AND ROHS_COMPLIANT_FLAG = 'NO'
                                     THEN
                                         NVL (SP.LRO_NRHS_QUANTITY, 0)
                                     WHEN     SITE_CODE = 'FVE'
                                          AND ROHS_COMPLIANT_FLAG = 'NO'
                                     THEN
                                         0
                                     ELSE
                                         0
                                 END
                                     STRATEGIC_MASKED_QTY
                            FROM RMK_ADMINUI_INVTRANSFER
                                 LEFT OUTER JOIN
                                 (SELECT partnumber,
                                         LRO_RHS_QUANTITY,
                                         LRO_NRHS_QUANTITY,
                                         FVE_RHS_QUANTITY,
                                         TOTAL_QUANTITY,
                                         CREATED_ON
                                    FROM RC_INV_STR_INV_MASK_MV
                                   WHERE TRUNC (CREATED_ON) =
                                         (SELECT TRUNC (MAX (CREATED_ON))
                                            FROM RC_INV_STR_INV_MASK_MV)) SP
                                     ON (part_number = sp.partnumber)
                           WHERE     part_number IN
                                         (SELECT refresh_part_number
                                            FROM crpadm.rc_product_master
                                           WHERE (   refresh_part_number =
                                                     i_part_number
                                                  OR common_part_number =
                                                     i_part_number
                                                  OR xref_part_number =
                                                     i_part_number)
                                          UNION
                                          SELECT common_part_number
                                            FROM crpadm.rc_product_master
                                           WHERE     (   refresh_part_number =
                                                         i_part_number
                                                      OR common_part_number =
                                                         i_part_number
                                                      OR xref_part_number =
                                                         i_part_number)
                                                 AND common_part_number
                                                         IS NOT NULL
                                          UNION
                                          SELECT xref_part_number
                                            FROM crpadm.rc_product_master
                                           WHERE     (   refresh_part_number =
                                                         i_part_number
                                                      OR common_part_number =
                                                         i_part_number
                                                      OR xref_part_number =
                                                         i_part_number)
                                                 AND xref_part_number
                                                         IS NOT NULL)
                                 AND (   APPROVED_DATE IS NULL
                                      OR APPROVED_DATE >= SYSDATE - (1 / 24))
                        ORDER BY REQUEST_ID DESC);
            ELSE
                SELECT RMK_INV_MOVE_STATUS_OBJECT (REQUEST_ID,
                                                   PART_NUMBER,
                                                   TRANSACTION_TYPE,
                                                   PROGRAM_TYPE,
                                                   SITE_CODE,
                                                   ROHS_COMPLIANT_FLAG,
                                                   QTY_TO_TRANSFER,
                                                   REQUESTED_BY,
                                                   REQUESTED_DATE,
                                                   APPROVED_BY,
                                                   APPROVED_DATE,
                                                   APROVAL_STATUS,
                                                   PROCESS_STATUS,
                                                   COMMENTS,
                                                   NULL,
                                                   APPROVER_COMMENTS,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   FROM_SUBINV,
                                                   TO_SUBINV,
                                                   STRATEGIC_MASKED_QTY)
                  BULK COLLECT INTO type_inv_transfer_sts_tab
                  FROM (  SELECT REQUEST_ID,
                                 PART_NUMBER,
                                 CASE
                                     WHEN TRANSACTION_TYPE = v_Retail_Outlet
                                     THEN
                                         'Retail to Outlet'
                                     WHEN TRANSACTION_TYPE = v_Outlet_Retail
                                     THEN
                                         'Outlet to Retail'
                                     WHEN TRANSACTION_TYPE = v_Adjustment
                                     THEN
                                            'Adjustment'
                                         || '-'
                                         || FROM_PROGRAM_TYPE
                                     WHEN TRANSACTION_TYPE = v_dgi_transfer
                                     THEN
                                         'DGI Transfer'
                                 END
                                     TRANSACTION_TYPE,
                                 NULL
                                     PROGRAM_TYPE,
                                 SITE_CODE,
                                 ROHS_COMPLIANT_FLAG,
                                 QTY_TO_TRANSFER,
                                 REQUESTED_BY,
                                 REQUESTED_DATE,
                                 APPROVED_BY,
                                 APPROVED_DATE,
                                 APROVAL_STATUS,
                                 PROCESS_STATUS,
                                 COMMENTS,
                                 APPROVER_COMMENTS,
                                 FROM_SUBINV,
                                 TO_SUBINV,
                                 CASE
                                     WHEN     SITE_CODE = 'LRO'
                                          AND ROHS_COMPLIANT_FLAG = 'YES'
                                     THEN
                                         NVL (SP.LRO_RHS_QUANTITY, 0)
                                     WHEN     SITE_CODE = 'FVE'
                                          AND ROHS_COMPLIANT_FLAG = 'YES'
                                     THEN
                                         NVL (SP.FVE_RHS_QUANTITY, 0)
                                     WHEN     SITE_CODE = 'LRO'
                                          AND ROHS_COMPLIANT_FLAG = 'NO'
                                     THEN
                                         NVL (SP.LRO_NRHS_QUANTITY, 0)
                                     WHEN     SITE_CODE = 'FVE'
                                          AND ROHS_COMPLIANT_FLAG = 'NO'
                                     THEN
                                         0
                                     ELSE
                                         0
                                 END
                                     STRATEGIC_MASKED_QTY
                            FROM RMK_ADMINUI_INVTRANSFER
                                 LEFT OUTER JOIN
                                 (SELECT partnumber,
                                         LRO_RHS_QUANTITY,
                                         LRO_NRHS_QUANTITY,
                                         FVE_RHS_QUANTITY,
                                         TOTAL_QUANTITY,
                                         CREATED_ON
                                    FROM RC_INV_STR_INV_MASK_MV
                                   WHERE TRUNC (CREATED_ON) =
                                         (SELECT TRUNC (MAX (CREATED_ON))
                                            FROM RC_INV_STR_INV_MASK_MV)) SP
                                     ON (part_number = sp.partnumber)
                           WHERE     1 = 1
                                 AND NVL (UPPER (APROVAL_STATUS), '*') !=
                                     v_rejected
                                 AND APPROVED_DATE IS NULL
                        ORDER BY REQUEST_ID DESC);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                P_RCEC_ERROR_LOG (
                    I_module_name =>
                        'P_INV_TRANSFER',
                    I_entity_name =>
                        'Part_number' || '->' || i_part_number,
                    I_entity_id =>
                        NULL,
                    I_ext_entity_name =>
                        'i_trans_type' || '->' || i_trans_type,
                    I_ext_entity_id =>
                        NULL,
                    I_error_type =>
                        'EXCEPTION',
                    i_Error_Message =>
                           'Error getting while fetching Transfer transactions for following PID: '
                        || i_part_number
                        || ' <> '
                        || v_message
                        || ' LineNo=> '
                        || DBMS_UTILITY.Format_error_backtrace,
                    I_created_by =>
                        'P_INV_TRANSFER',
                    I_updated_by =>
                        'P_INV_TRANSFER');
        END;

        o_trans_status_tab := type_inv_transfer_sts_tab;
    EXCEPTION
        WHEN OTHERS
        THEN
            P_RCEC_ERROR_LOG (
                I_module_name =>
                    'P_INV_TRANSFER',
                I_entity_name =>
                    'Part_number' || '->' || i_part_number,
                I_entity_id =>
                    NULL,
                I_ext_entity_name =>
                    'i_trans_type' || '->' || i_trans_type,
                I_ext_entity_id =>
                    NULL,
                I_error_type =>
                    'EXCEPTION',
                i_Error_Message =>
                       'Error getting while exectuting Inventory Transfer for following PID: '
                    || i_part_number
                    || ' <> '
                    || v_message
                    || ' LineNo=> '
                    || DBMS_UTILITY.Format_error_backtrace,
                I_created_by =>
                    'P_INV_TRANSFER',
                I_updated_by =>
                    'P_INV_TRANSFER');
    END P_INV_TRANSFER;

    PROCEDURE P_INV_TRANSREQ_VIEW (
        i_load_view                           VARCHAR2,
        i_min_row                             VARCHAR2,
        i_max_row                             VARCHAR2,
        i_sort_column_name                    VARCHAR2,
        i_sort_column_by                      VARCHAR2,
        i_request_id                          NUMBER,
        i_part_number                         VARCHAR2,
        i_transaction_type                    VARCHAR2,
        i_program_type                        VARCHAR2,
        i_site_code                           VARCHAR2,
        i_from_subinv                         VARCHAR2, -->> Added as part of DGI Transfer changes on 14-Jun-2019
        i_to_subinv                           VARCHAR2, -->> Added as part of DGI Transfer changes on 14-Jun-2019
        i_rohs_compliant_flag                 VARCHAR2,
        i_requested_by                        VARCHAR2,
        i_request_from_date                   VARCHAR2,
        i_request_to_date                     VARCHAR2,
        i_approved_by                         VARCHAR2,
        i_approv_from_date                    VARCHAR2,
        i_approv_to_date                      VARCHAR2,
        i_process_sts                         VARCHAR2,
        o_display_count            OUT NOCOPY NUMBER,
        o_trans_status_tab         OUT NOCOPY RMK_INV_MOVE_STATUS_TAB)
    AS
        lv_count_query              VARCHAR2 (32767);
        lv_query                    VARCHAR2 (32767);
        lv_extquery                 VARCHAR2 (32767);
        lv_sort_column_name         VARCHAR2 (200);
        lv_sort_column_by           VARCHAR2 (200);
        lv_display_count            NUMBER;
        lv_min_row                  NUMBER;
        lv_max_row                  NUMBER;
        lv_load_view                VARCHAR2 (30);
        lv_request_id               NUMBER;
        lv_part_number              VARCHAR2 (32767);
        lv_transaction_type         VARCHAR2 (50);
        lv_program_type             VARCHAR2 (50);
        lv_site_code                VARCHAR2 (100);
        lv_from_subinv              VARCHAR2 (100); -->> Added as part of DGI Transfer changes on 14-Jun-2019
        lv_to_subinv                VARCHAR2 (100); -->> Added as part of DGI Transfer changes on 14-Jun-2019
        lv_rohs_compliant_flag      VARCHAR2 (3);
        lv_requested_by             VARCHAR2 (300);
        lv_request_from_date        VARCHAR2 (20);
        lv_request_to_date          VARCHAR2 (20);
        lv_approved_by              VARCHAR2 (300);
        lv_approv_from_date         VARCHAR2 (20);
        lv_approv_to_date           VARCHAR2 (20);
        lv_process_sts              VARCHAR2 (20);
        type_inv_transfer_sts_tab   RMK_INV_MOVE_STATUS_TAB
                                        := RMK_INV_MOVE_STATUS_TAB ();
    BEGIN
        lv_sort_column_name := TRIM (i_sort_column_name);
        lv_sort_column_by := TRIM (i_sort_column_by);
        lv_min_row := i_min_row;
        lv_max_row := i_max_row;
        lv_load_view := UPPER (TRIM (i_load_view));

        lv_request_id := TRIM (i_request_id);
        lv_part_number := UPPER (TRIM (i_part_number));
        lv_transaction_type := UPPER (TRIM (i_transaction_type));
        lv_program_type := UPPER (TRIM (i_program_type));
        lv_site_code := UPPER (TRIM (i_site_code));
        lv_from_subinv := UPPER (TRIM (i_from_subinv));
        lv_to_subinv := UPPER (TRIM (i_to_subinv));
        lv_rohs_compliant_flag := UPPER (TRIM (i_rohs_compliant_flag));
        lv_requested_by := UPPER (TRIM (i_requested_by));
        lv_request_from_date := UPPER (TRIM (i_request_from_date));
        lv_request_to_date := UPPER (TRIM (i_request_to_date));
        lv_approved_by := UPPER (TRIM (i_approved_by));
        lv_approv_from_date := UPPER (TRIM (i_approv_from_date));
        lv_approv_to_date := UPPER (TRIM (i_approv_to_date));
        lv_process_sts := UPPER (TRIM (i_process_sts));

        lv_count_query := '  SELECT COUNT (*)
                                        FROM RMK_ADMINUI_INVTRANSFER';

        lv_query :=
               '  SELECT RMK_INV_MOVE_STATUS_OBJECT(
                                               REQUEST_ID,
                                                     PART_NUMBER,
                                                     TRANSACTION_TYPE,
                                                     NULL,
                                                     SITE_CODE,
                                                     ROHS_COMPLIANT_FLAG,
                                                     QTY_TO_TRANSFER,
                                                     REQUESTED_BY,
                                                     REQUESTED_DATE,
                                                     APPROVED_BY,
                                                     APPROVED_DATE,
                                                     APROVAL_STATUS,
                                                     PROCESS_STATUS,
                                                     COMMENTS,
                                                     NULL,
                                                     APPROVER_COMMENTS,
                                                     ADDITIONAL_COMMENTS, -- Added as part of US161611 by sridvasu for additional comments column
                                                     NULL,
                                                     NULL,
                                                     NULL,
                                                     NULL,
                                                     NULL,
                                                     NULL,
                                                     NULL,
                                                     NULL,
                                                     C3_ONHAND_QTY,
                                                     FROM_SUBINV,
                                                     TO_SUBINV,
                                                     STRATEGIC_MASKED_QTY)
                                                     FROM(SELECT
                                                                             REQUEST_ID,
                                                                             PART_NUMBER,
                                                                              CASE
                                                                              WHEN TRANSACTION_TYPE = '''
            || v_Retail_Outlet
            || ''' THEN ''Retail to Outlet'''
            || ' WHEN TRANSACTION_TYPE = '''
            || v_Outlet_Retail
            || '''  THEN ''Outlet to Retail'''
            || ' WHEN TRANSACTION_TYPE = '''
            || v_Adjustment
            || ''' THEN ''Adjustment - '''
            || ' || FROM_PROGRAM_TYPE'
            || ' WHEN TRANSACTION_TYPE = '''
            || v_dgi_transfer
            || '''  THEN ''DGI Transfer'''
            || ' WHEN TRANSACTION_TYPE = '''
            || v_FVE_Nettable_NonNettable
            || '''  THEN ''FVE Nettable to NonNettable'''
            || ' WHEN TRANSACTION_TYPE = '''
            || v_FVE_NonNettable_Nettable
            || '''  THEN ''FVE NonNettable to Nettable'''
            || ' END TRANSACTION_TYPE,
                                                                            --  DECODE(TRANSACTION_TYPE,'''
            || v_Adjustment
            || ''',FROM_PROGRAM_TYPE,NULL) PROGRAM_TYPE,
                                                                             SITE_CODE, 
                                                                             ROHS_COMPLIANT_FLAG,
                                                                             NVL(QTY_TO_PROCESS,QTY_TO_TRANSFER)  QTY_TO_TRANSFER,
                                                                             REQUESTED_BY,
                                                                             REQUESTED_DATE,
                                                                             APPROVED_BY,
                                                                             APPROVED_DATE,
                                                                             APROVAL_STATUS,
                                                                             PROCESS_STATUS,
                                                                             COMMENTS,
                                                                             APPROVER_COMMENTS,
                                                                             ADDITIONAL_COMMENTS, -- Added as part of US161611 by sridvasu for additional comments column
                                                                             C3_ONHAND_QTY,
                                                                             FROM_SUBINV,
                                                                             TO_SUBINV,
                                                                             CASE WHEN SITE_CODE = ''LRO'' AND ROHS_COMPLIANT_FLAG =''YES'' THEN NVL(SP.LRO_RHS_QUANTITY,0)
                                                                                    WHEN SITE_CODE = ''FVE'' AND ROHS_COMPLIANT_FLAG =''YES'' THEN NVL(SP.FVE_RHS_QUANTITY,0)
                                                                                    WHEN SITE_CODE = ''LRO'' AND ROHS_COMPLIANT_FLAG =''NO'' THEN NVL(SP.LRO_NRHS_QUANTITY,0)
                                                                                    WHEN SITE_CODE = ''FVE'' AND ROHS_COMPLIANT_FLAG =''NO'' THEN 0
                                                                                    ELSE 0
                                                                              END
                                                                                STRATEGIC_MASKED_QTY,
                                                                             ';

        IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
        THEN
            lv_query :=
                   lv_query
                || 'ROW_NUMBER()  OVER (ORDER BY '
                || lv_sort_column_name
                || ' '
                || lv_sort_column_by
                || ' ) AS rnum
                            FROM RMK_ADMINUI_INVTRANSFER LEFT OUTER JOIN
       (SELECT partnumber,
               LRO_RHS_QUANTITY,
               LRO_NRHS_QUANTITY,
               FVE_RHS_QUANTITY,
               TOTAL_QUANTITY,
               CREATED_ON
          FROM RC_INV_STR_INV_MASK_MV
         WHERE TRUNC (CREATED_ON) =
                  (SELECT TRUNC (MAX (CREATED_ON))
                     FROM RC_INV_STR_INV_MASK_MV)) SP
          ON (part_number = sp.partnumber)';
        ELSE
            lv_query := lv_query || 'ROWNUM  rnum
                            FROM RMK_ADMINUI_INVTRANSFER LEFT OUTER JOIN
       (SELECT partnumber,
               LRO_RHS_QUANTITY,
               LRO_NRHS_QUANTITY,
               FVE_RHS_QUANTITY,
               TOTAL_QUANTITY,
               CREATED_ON
          FROM RC_INV_STR_INV_MASK_MV
         WHERE TRUNC (CREATED_ON) =
                  (SELECT TRUNC (MAX (CREATED_ON))
                     FROM RC_INV_STR_INV_MASK_MV)) SP
          ON (part_number = sp.partnumber)';
        END IF;

        IF lv_load_view = 'PENDING'
        THEN
            lv_extquery :=
                   lv_extquery
                || '
                           WHERE 1=1
                             AND NVL(UPPER(APROVAL_STATUS),''*'')!='''
                || v_rejected
                || '''
                             AND APPROVED_DATE IS NULL';
        ELSE
            --Added by satbanda for showing last one week data on 13thApr,2017 Prefilter <Start>
            IF     lv_part_number IS NULL
               AND lv_request_id IS NULL
               AND lv_transaction_type IS NULL
               AND lv_program_type IS NULL
               AND lv_site_code IS NULL
               AND lv_rohs_compliant_flag IS NULL
               AND lv_from_subinv IS NULL
               AND lv_to_subinv IS NULL
               AND lv_requested_by IS NULL
               AND lv_request_from_date IS NULL
               AND lv_request_to_date IS NULL
               AND lv_approved_by IS NULL
               AND lv_approv_from_date IS NULL
               AND lv_approv_to_date IS NULL
               AND lv_process_sts IS NULL
            THEN
                lv_extquery :=
                       lv_extquery
                    || '
                                        WHERE (APPROVED_DATE IS NULL
                                               OR TRUNC(TO_DATE(APPROVED_DATE)) >= TRUNC(TO_DATE(SYSDATE-7))
                                               ) ';
            ELSE
                --Added by satbanda for showing last one week data on 13thApr,2017 Prefilter <End>
                lv_extquery := lv_extquery || '
                               WHERE 1=1';
            END IF;
        END IF;

        IF lv_request_id IS NOT NULL
        THEN
            lv_extquery := lv_extquery || '
                            AND request_id = ' || lv_request_id || '';
        END IF;

        IF lv_part_number IS NOT NULL
        THEN
            lv_extquery :=
                   lv_extquery
                || '
                            AND part_number IN  ( SELECT REGEXP_SUBSTR ( '''
                || lv_part_number
                || ''''
                || ','
                || '''[^,]+'''
                || ',1, LEVEL)
                                 FROM DUAL
                           CONNECT BY REGEXP_SUBSTR ('''
                || lv_part_number
                || ''''
                || ','
                || '''[^,]+'''
                || ',1, LEVEL)  IS NOT NULL)';
        END IF;

        IF lv_transaction_type IS NOT NULL
        THEN
            IF lv_transaction_type = 'NETTABLE-NONNETTABLE'
            THEN
                lv_extquery :=
                       lv_extquery
                    || '
                            AND transaction_type IN ('''
                    || v_FVE_Nettable_NonNettable
                    || ''','''
                    || v_FVE_NonNettable_Nettable
                    || ''')';
            ELSE
                lv_extquery :=
                       lv_extquery
                    || '
                            AND transaction_type = '''
                    || lv_transaction_type
                    || '''';
            END IF;
        END IF;

        IF lv_program_type IS NOT NULL
        THEN
            lv_extquery :=
                   lv_extquery
                || '
                            AND UPPER(FROM_PROGRAM_TYPE) = '''
                || lv_program_type
                || '''';
        END IF;


        IF lv_site_code IS NOT NULL
        THEN
            lv_extquery := lv_extquery || '
                            AND site_code = ''' || lv_site_code || '''';
        END IF;

        /* Start added as part of DGI Transfer changes on 14-Jun-2019 */
        IF lv_from_subinv IS NOT NULL
        THEN
            lv_extquery := lv_extquery || '
                            AND from_subinv = ''' || lv_from_subinv || '''';
        END IF;

        IF lv_to_subinv IS NOT NULL
        THEN
            lv_extquery := lv_extquery || '
                            AND to_subinv = ''' || lv_to_subinv || '''';
        END IF;

        /* End added as part of DGI Transfer changes on 14-Jun-2019 */

        IF lv_process_sts IS NOT NULL
        THEN
            lv_extquery :=
                   lv_extquery
                || '
                            AND UPPER(PROCESS_STATUS) = '''
                || lv_process_sts
                || '''';
        END IF;


        IF lv_rohs_compliant_flag IS NOT NULL
        THEN
            lv_extquery :=
                   lv_extquery
                || '
                            AND rohs_compliant_flag = '''
                || lv_rohs_compliant_flag
                || '''';
        END IF;

        IF lv_requested_by IS NOT NULL
        THEN
            lv_extquery :=
                   lv_extquery
                || '
                            AND UPPER(requested_by) = '''
                || lv_requested_by
                || '''';
        END IF;

        IF     lv_request_from_date IS NOT NULL
           AND lv_request_to_date IS NOT NULL
        THEN
            lv_extquery :=
                   lv_extquery
                || '
                            AND TO_DATE(requested_date) BETWEEN TO_DATE('
                || ''''
                || lv_request_from_date
                || ''',''MM/DD/YYYY'') AND TO_DATE('
                || ''''
                || lv_request_to_date
                || ''',''MM/DD/YYYY'')';
        ELSIF lv_request_from_date IS NOT NULL
        THEN
            lv_extquery :=
                   lv_extquery
                || '
                                AND TO_DATE(requested_date) >=TO_DATE('
                || ''''
                || lv_request_from_date
                || ''',''MM/DD/YYYY'')';
        ELSIF lv_request_to_date IS NOT NULL
        THEN
            lv_extquery :=
                   lv_extquery
                || '
                                AND TO_DATE(requested_date) <=TO_DATE('
                || ''''
                || lv_request_to_date
                || ''',''MM/DD/YYYY'')';
        END IF;

        IF lv_approved_by IS NOT NULL
        THEN
            lv_extquery :=
                   lv_extquery
                || '
                            AND UPPER(approved_by) = '''
                || lv_approved_by
                || '''';
        END IF;

        IF lv_approv_from_date IS NOT NULL AND lv_approv_to_date IS NOT NULL
        THEN
            lv_extquery :=
                   lv_extquery
                || '
                            AND TO_DATE(approved_date) BETWEEN TO_DATE('
                || ''''
                || lv_approv_from_date
                || ''',''MM/DD/YYYY'') AND TO_DATE('
                || ''''
                || lv_approv_to_date
                || ''',''MM/DD/YYYY'')';
        ELSIF lv_approv_from_date IS NOT NULL
        THEN
            lv_extquery :=
                   lv_extquery
                || '
                                AND TO_DATE(approved_date) >=TO_DATE('
                || ''''
                || lv_approv_from_date
                || ''',''MM/DD/YYYY'')';
        ELSIF lv_approv_to_date IS NOT NULL
        THEN
            lv_extquery :=
                   lv_extquery
                || '
                                AND TO_DATE(approved_date) <=TO_DATE('
                || ''''
                || lv_approv_to_date
                || ''',''MM/DD/YYYY'')';
        END IF;

        lv_query := lv_query || lv_extquery;

        lv_count_query := lv_count_query || lv_extquery;

        IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
        THEN
            lv_query :=
                   lv_query
                || '  )  Inv WHERE rnum >='
                || lv_min_row
                || ' AND rnum <='
                || lv_max_row;

            lv_query :=
                   lv_query
                || ' ORDER BY Inv.'
                || lv_sort_column_name
                || ' '
                || lv_sort_column_by;
        ELSE
            lv_query :=
                   lv_query
                || ' AND ROWNUM <= '
                || lv_max_row
                || ' ORDER BY REQUESTED_DATE desc) WHERE rnum >='
                || lv_min_row;
        END IF;

        DBMS_OUTPUT.put_line (lv_query);
        DBMS_OUTPUT.put_line (lv_count_query);

        EXECUTE IMMEDIATE lv_query
            BULK COLLECT INTO type_inv_transfer_sts_tab;


        EXECUTE IMMEDIATE lv_count_query INTO lv_display_count;


        o_trans_status_tab := type_inv_transfer_sts_tab;

        o_display_count := lv_display_count;
    EXCEPTION
        WHEN OTHERS
        THEN
            P_RCEC_ERROR_LOG (
                I_module_name =>
                    'P_INV_TRANSREQ_VIEW',
                I_entity_name =>
                    NULL,
                I_entity_id =>
                    NULL,
                I_ext_entity_name =>
                    NULL,
                I_ext_entity_id =>
                    NULL,
                I_error_type =>
                    'EXCEPTION',
                i_Error_Message =>
                       'Error getting while executing P_INV_TRANSREQ_VIEW '
                    || ' <> '
                    || v_message
                    || ' LineNo=> '
                    || DBMS_UTILITY.Format_error_backtrace,
                I_created_by =>
                    'P_INV_TRANSREQ_VIEW',
                I_updated_by =>
                    'P_INV_TRANSREQ_VIEW');
    END P_INV_TRANSREQ_VIEW;

    PROCEDURE P_INV_SU_TRANSREQ (
        i_part_number           IN VARCHAR2,
        i_request_type          IN VARCHAR2,                  -- CREATE/UPDATE
        i_trans_type            IN VARCHAR2, --RETAIL-OUTLET, OUTLET-RETAIL, ADJUSTMENT
        i_from_prgm_type        IN VARCHAR2,
        i_to_prgm_type          IN VARCHAR2,
        i_rohs_check_needed     IN VARCHAR2,
        i_mos                   IN NUMBER,
        i_retail_max            IN NUMBER,
        i_outlet_cap            IN NUMBER,
        i_ytd_avg_sales_price   IN NUMBER,
        i_created_by            IN VARCHAR2,
        i_approved_by           IN VARCHAR2,
        i_approve_sts           IN VARCHAR2, -- Auto-Approved/ Pending, Approved, Rejected
        i_process_status        IN VARCHAR2,       --PROCESSED/ NEW, PROCESSED
        i_auto_notify_mail      IN VARCHAR2,   --Added by sabanda for US157355
        o_trans_dtl_tab         IN RMK_INV_TRANSFER_DTL_TAB)
    AS
        l_err_msg             VARCHAR2 (2000);
        lv_inv_Log_seq1       NUMBER;
        lv_inv_Log_seq2       NUMBER;
        lv_request_id         NUMBER;
        lv_poe_batch_id       VARCHAR2 (100);
        lv_approved_flag      VARCHAR2 (1) := 'N';                          --
        lv_process_status     VARCHAR2 (20);
        lv_aprove_sts         VARCHAR2 (20);
        l_approved_date       DATE;
        lv_auto_notify_mail   VARCHAR2 (3);    --Added by sabanda for US157355
        lv_adjustment_temp    NUMBER;
        lv_ostatus            VARCHAR2 (100);
    BEGIN
        lv_process_status := UPPER (TRIM (i_process_status));
        lv_aprove_sts := UPPER (TRIM (i_approve_sts));
        lv_auto_notify_mail := TRIM (i_auto_notify_mail); --Added by sabanda for US157355

        /*       IF i_request_type = 'CREATE'
              THEN */
        IF o_trans_dtl_tab.EXISTS (1)
        THEN
            FOR I IN 1 .. o_trans_dtl_tab.COUNT
            LOOP
                IF lv_process_status = 'APPROVED' -->> Modifed status from 'PROCESSED' to 'APPROVED' by sridvasu as part of US161611
                THEN
                    l_approved_date := SYSDATE;
                ELSE
                    l_approved_date := NULL;
                END IF;

                IF i_request_type = 'CREATE'
                THEN
                    SELECT RMK_ADMINUI_SEQ.NEXTVAL
                      INTO lv_request_id
                      FROM DUAL;

                    BEGIN
                        INSERT INTO RMK_ADMINUI_INVTRANSFER (
                                        REQUEST_ID,
                                        PART_NUMBER,
                                        INVENTORY_ITEM_ID,
                                        TRANSACTION_TYPE,
                                        FROM_PROGRAM_TYPE,
                                        TO_PROGRAM_TYPE,
                                        ROHS_CHECK_FLAG,
                                        MOS,
                                        RETAIL_MAX,
                                        OUTLET_CAP,
                                        AVG_SALE_PRICE_YTD,
                                        SITE_CODE,
                                        ROHS_COMPLIANT_FLAG,
                                        SRC_AVAIL_QTY,
                                        SRC_RESERVED_QTY,
                                        SRC_AVAIL_TO_RESERVE,
                                        TRG_AVAIL_QTY,
                                        TRG_RESERVED_QTY,
                                        TRG_AVAIL_TO_RESERVE,
                                        QTY_TO_TRANSFER,
                                        QTY_TO_PROCESS, --Added by satbanda for US123787 - Inventory Adjustments Upload feature
                                        COMMENTS,
                                        ATTRIBUTE1,
                                        ATTRIBUTE2,
                                        REQUESTED_BY,
                                        REQUESTED_DATE,
                                        APPROVED_BY,
                                        APPROVED_DATE,
                                        APROVAL_STATUS,
                                        PROCESS_STATUS,
                                        LAST_UPDATED_BY,
                                        LAST_UPDATED_DATE,
                                        CREATED_BY,
                                        CREATED_DATE,
                                        C3_ONHAND_QTY,
                                        FROM_SUBINV,
                                        TO_SUBINV)
                                 VALUES (
                                            lv_request_id,
                                            o_trans_dtl_tab (i).refresh_part_number, --i_part_number, Modified by satbanda for US123787 - Inventory Adjustments Upload feature
                                            NULL,
                                            i_trans_type,
                                            NVL (i_from_prgm_type,
                                                 o_trans_dtl_tab (i).v_attr1),
                                            i_to_prgm_type,
                                            i_rohs_check_needed,
                                            i_mos,
                                            i_retail_max,
                                            i_outlet_cap,
                                            i_ytd_avg_sales_price,
                                            o_trans_dtl_tab (i).site_location,
                                            o_trans_dtl_tab (i).rohs_compliant,
                                            o_trans_dtl_tab (i).src_avbl_qty,
                                            o_trans_dtl_tab (i).src_rsrv_qty,
                                            o_trans_dtl_tab (i).src_avbl_to_rsrv_qty,
                                            o_trans_dtl_tab (i).trg_avbl_qty,
                                            o_trans_dtl_tab (i).trg_rsrv_qty,
                                            o_trans_dtl_tab (i).trg_avbl_to_rsrv_qty,
                                            o_trans_dtl_tab (i).n_attr1,
                                            DECODE (
                                                lv_aprove_sts,
                                                'AUTO APPROVED', o_trans_dtl_tab (
                                                                     i).n_attr1,
                                                NULL), --Added by satbanda for US123787 - Inventory Adjustments Upload feature
                                            o_trans_dtl_tab (i).v_attr2,
                                            lv_auto_notify_mail, --NULL, Modified by sabanda for US157355
                                            'N', -- NULL, -->> As part of DGI Transfer to send approval notification
                                            i_created_by,
                                            SYSDATE,
                                            i_approved_by,
                                            l_approved_date, -- APPROVED_DATE,
                                            i_approve_sts, --APROVAL_STATUS --Pending, Approved
                                            lv_process_status, --i_process_status, --PROCESS_STATUS -- NEW, PROCESSED
                                            i_created_by,   --LAST_UPDATED_BY,
                                            SYSDATE,      --LAST_UPDATED_DATE,
                                            i_created_by,        --CREATED_BY,
                                            SYSDATE,            --CREATED_DATE
                                            o_trans_dtl_tab (i).c3_onhand_qty,
                                            o_trans_dtl_tab (i).from_subinv,
                                            UPPER (
                                                o_trans_dtl_tab (i).to_subinv));

                        COMMIT;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            v_message := SUBSTR (SQLERRM, 1, 200);

                            P_RCEC_ERROR_LOG (
                                I_module_name =>
                                    'P_INV_SU_TRANSREQ',
                                I_entity_name =>
                                       'Part_number'
                                    || '->'
                                    || o_trans_dtl_tab (i).refresh_part_number, --i_part_number, Modified by satbanda for US123787 - Inventory Adjustments Upload feature
                                I_entity_id =>
                                    NULL,
                                I_ext_entity_name =>
                                    'Request_id' || '->' || lv_request_id,
                                I_ext_entity_id =>
                                    NULL,
                                I_error_type =>
                                    'EXCEPTION',
                                i_Error_Message =>
                                       'Error getting while populating the data into RMK_ADMINUI_INVTRANSFER for following PID: '
                                    || o_trans_dtl_tab (i).refresh_part_number --i_part_number  Modified by satbanda for US123787 - Inventory Adjustments Upload feature
                                    || ' <> '
                                    || 'Transfer Type'
                                    || i_trans_type
                                    || ' <> '
                                    || v_message
                                    || ' LineNo=> '
                                    || DBMS_UTILITY.Format_error_backtrace,
                                I_created_by =>
                                    i_created_by,
                                I_updated_by =>
                                    i_created_by);
                    END;
                ELSIF i_request_type = 'UPDATE'
                THEN
                    UPDATE rmk_adminui_invtransfer
                       SET --qty_to_process =o_trans_dtl_tab (i).n_attr2, --Processed quantity --Commented by satbanda for showing processed quantiry if user didn't modified
                           qty_to_process =
                               NVL (o_trans_dtl_tab (i).n_attr2,
                                    qty_to_transfer), --Added by satbanda for showing processed quantiry if user didn't modified
                           --                   to_subinv = o_trans_dtl_tab(i).to_subinv, -->> Added as part of DGI Transfer changes on 14-Jun-2019
                           approver_comments = o_trans_dtl_tab (i).v_attr3, --Approver Comments
                           process_status =
                               DECODE (UPPER (i_approve_sts),
                                       v_rejected, v_rejected,
                                       lv_process_status),
                           aproval_status = i_approve_sts,
                           APPROVED_BY = i_approved_by,
                           last_updated_by = i_approved_by,
                           approved_date = SYSDATE,
                           last_updated_date = SYSDATE
                     WHERE request_id = o_trans_dtl_tab (i).n_attr3; --Request id

                    lv_request_id := o_trans_dtl_tab (i).n_attr3;
                END IF;

                lv_inv_Log_seq1 := NULL;
                lv_inv_Log_seq2 := NULL;
                lv_poe_batch_id := 'ADMINUI_' || lv_request_id;

                IF                         --lv_process_status='PROCESSED' AND
                   (   lv_aprove_sts = 'APPROVED'
                    OR lv_aprove_sts = 'AUTO APPROVED')
                THEN
                    BEGIN
                        IF i_trans_type IN (v_Retail_Outlet, v_Outlet_Retail)
                        THEN
                            --SELECT RMK_INV_LOG_PK_SEQ.NEXTVAL --commented by hkarka on 13-FEB-2017
                            SELECT RC_INV_LOG_PK_SEQ.NEXTVAL --added by hkarka on 13-FEB-2017 to replace the sequence name
                              INTO lv_inv_Log_seq1
                              FROM DUAL;

                            INSERT INTO RMK_INVENTORY_LOG (INVENTORY_LOG_ID,
                                                           PART_NUMBER,
                                                           NEW_FGI,
                                                           NEW_DGI,
                                                           ROHS_COMPLIANT,
                                                           SITE_CODE,
                                                           PROCESS_STATUS,
                                                           UPDATED_BY,
                                                           UPDATED_ON,
                                                           CREATED_BY,
                                                           CREATED_ON,
                                                           POE_BATCH_ID,
                                                           PROGRAM_TYPE)
                                     VALUES (
                                                lv_inv_Log_seq1,
                                                o_trans_dtl_tab (i).refresh_part_number, --i_part_number, Modified by satbanda for US123787 - Inventory Adjustments Upload feature
                                                -- DECODE (o_trans_dtl_tab (i).site_location, 'GDGI', 0, -o_trans_dtl_tab (i).n_attr2),  --modified by hkarka on 09-FEB-2017, insert NEW_FGI for FGI inventory--0,
                                                DECODE (
                                                    o_trans_dtl_tab (i).site_location,
                                                    'GDGI', 0,
                                                    -NVL (
                                                         o_trans_dtl_tab (i).n_attr2,
                                                         o_trans_dtl_tab (i).n_attr1)),
                                                -- DECODE (o_trans_dtl_tab (i).site_location, 'GDGI', -o_trans_dtl_tab (i).n_attr2, 0),  --modified by hkarka on 09-FEB-2017, insert NEW_DGI for DGI inventory
                                                DECODE (
                                                    o_trans_dtl_tab (i).site_location,
                                                    'GDGI', -NVL (
                                                                 o_trans_dtl_tab (
                                                                     i).n_attr2,
                                                                 o_trans_dtl_tab (
                                                                     i).n_attr1),
                                                    0),
                                                DECODE (
                                                    o_trans_dtl_tab (i).rohs_compliant,
                                                    'Y', 'YES',
                                                    'N', 'NO',
                                                    o_trans_dtl_tab (i).rohs_compliant),
                                                o_trans_dtl_tab (i).site_location,
                                                'N',
                                                i_created_by,
                                                SYSDATE,
                                                i_created_by,
                                                SYSDATE,
                                                lv_poe_batch_id,
                                                SUBSTR (i_from_prgm_type,
                                                        1,
                                                        1));

                            --SELECT RMK_INV_LOG_PK_SEQ.NEXTVAL  --commented by hkarka on 13-FEB-2017
                            SELECT RC_INV_LOG_PK_SEQ.NEXTVAL --added by hkarka on 13-FEB-2017 to replace the sequence name
                              INTO lv_inv_Log_seq2
                              FROM DUAL;

                            INSERT INTO RMK_INVENTORY_LOG (INVENTORY_LOG_ID,
                                                           PART_NUMBER,
                                                           NEW_FGI,
                                                           NEW_DGI,
                                                           ROHS_COMPLIANT,
                                                           SITE_CODE,
                                                           PROCESS_STATUS,
                                                           UPDATED_BY,
                                                           UPDATED_ON,
                                                           CREATED_BY,
                                                           CREATED_ON,
                                                           POE_BATCH_ID,
                                                           PROGRAM_TYPE)
                                     VALUES (
                                                lv_inv_Log_seq2,
                                                o_trans_dtl_tab (i).refresh_part_number, --i_part_number, Modified by satbanda for US123787 - Inventory Adjustments Upload feature
                                                --DECODE (o_trans_dtl_tab (i).site_location, 'GDGI', 0, o_trans_dtl_tab (i).n_attr2),  --modified by hkarka on 09-FEB-2017, insert NEW_FGI for FGI inventory--0,
                                                DECODE (
                                                    o_trans_dtl_tab (i).site_location,
                                                    'GDGI', 0,
                                                    NVL (
                                                        o_trans_dtl_tab (i).n_attr2,
                                                        o_trans_dtl_tab (i).n_attr1)),
                                                -- DECODE (o_trans_dtl_tab (i).site_location, 'GDGI', o_trans_dtl_tab (i).n_attr2, 0),  --modified by hkarka on 09-FEB-2017, insert NEW_DGI for DGI inventory
                                                DECODE (
                                                    o_trans_dtl_tab (i).site_location,
                                                    'GDGI', NVL (
                                                                o_trans_dtl_tab (
                                                                    i).n_attr2,
                                                                o_trans_dtl_tab (
                                                                    i).n_attr1),
                                                    0),
                                                DECODE (
                                                    o_trans_dtl_tab (i).rohs_compliant,
                                                    'Y', 'YES',
                                                    'N', 'NO',
                                                    o_trans_dtl_tab (i).rohs_compliant),
                                                o_trans_dtl_tab (i).site_location,
                                                'N',
                                                i_created_by,
                                                SYSDATE,
                                                i_created_by,
                                                SYSDATE,
                                                lv_poe_batch_id,
                                                SUBSTR (i_to_prgm_type, 1, 1));

                            COMMIT;
                        ELSIF i_trans_type = v_Adjustment
                        THEN
                            --SELECT RMK_INV_LOG_PK_SEQ.NEXTVAL  --commented by hkarka on 13-FEB-2017
                            SELECT RC_INV_LOG_PK_SEQ.NEXTVAL --added by hkarka on 13-FEB-2017 to replace the sequence name
                              INTO lv_inv_Log_seq2
                              FROM DUAL;

                            lv_adjustment_temp :=
                                NVL (o_trans_dtl_tab (i).n_attr2,
                                     o_trans_dtl_tab (i).n_attr1);

                            IF     lv_adjustment_temp < 0
                               AND o_trans_dtl_tab (i).MASKED_QTY > 0
                               AND o_trans_dtl_tab (i).v_attr1 = 'Retail'
                               AND o_trans_dtl_tab (i).SITE_LOCATION IN
                                       ('LRO', 'FVE')
                            THEN
                                lv_adjustment_temp :=
                                    ABS (lv_adjustment_temp);

                                IF o_trans_dtl_tab (i).TRG_AVBL_TO_RSRV_QTY >=
                                   lv_adjustment_temp
                                THEN
                                    INSERT INTO RMK_INVENTORY_LOG (
                                                    INVENTORY_LOG_ID,
                                                    PART_NUMBER,
                                                    NEW_FGI,
                                                    NEW_DGI,
                                                    ROHS_COMPLIANT,
                                                    SITE_CODE,
                                                    PROCESS_STATUS,
                                                    UPDATED_BY,
                                                    UPDATED_ON,
                                                    CREATED_BY,
                                                    CREATED_ON,
                                                    POE_BATCH_ID,
                                                    PROGRAM_TYPE)
                                             VALUES (
                                                        lv_inv_Log_seq2,
                                                        o_trans_dtl_tab (i).refresh_part_number, --i_part_number, Modified by satbanda for US123787 - Inventory Adjustments Upload feature
                                                        --DECODE (o_trans_dtl_tab (i).site_location, 'GDGI', 0, o_trans_dtl_tab (i).n_attr2),  --modified by hkarka on 09-FEB-2017, insert NEW_FGI for FGI inventory--0,
                                                        DECODE (
                                                            o_trans_dtl_tab (
                                                                i).site_location,
                                                            'GDGI', 0,
                                                            NVL (
                                                                o_trans_dtl_tab (
                                                                    i).n_attr2,
                                                                o_trans_dtl_tab (
                                                                    i).n_attr1)),
                                                        --DECODE (o_trans_dtl_tab (i).site_location, 'GDGI', o_trans_dtl_tab (i).n_attr2, 0),  --modified by hkarka on 09-FEB-2017, insert NEW_DGI for DGI inventory
                                                        DECODE (
                                                            o_trans_dtl_tab (
                                                                i).site_location,
                                                            'GDGI', NVL (
                                                                        o_trans_dtl_tab (
                                                                            i).n_attr2,
                                                                        o_trans_dtl_tab (
                                                                            i).n_attr1),
                                                            0),
                                                        DECODE (
                                                            o_trans_dtl_tab (
                                                                i).rohs_compliant,
                                                            'Y', 'YES',
                                                            'N', 'NO',
                                                            o_trans_dtl_tab (
                                                                i).rohs_compliant),
                                                        o_trans_dtl_tab (i).site_location,
                                                        'N',
                                                        i_created_by,
                                                        SYSDATE,
                                                        i_created_by,
                                                        SYSDATE,
                                                        lv_poe_batch_id,
                                                        SUBSTR (
                                                            o_trans_dtl_tab (
                                                                i).v_attr1,
                                                            1,
                                                            1) --Modified on 7th Feb, 2017 for restrict to one character value.
                                                              );

                                    COMMIT;
                                ELSE
                                    IF o_trans_dtl_tab (i).TRG_AVBL_TO_RSRV_QTY >
                                       0
                                    THEN
                                        lv_adjustment_temp :=
                                              lv_adjustment_temp
                                            - o_trans_dtl_tab (i).TRG_AVBL_TO_RSRV_QTY;

                                        INSERT INTO RMK_INVENTORY_LOG (
                                                        INVENTORY_LOG_ID,
                                                        PART_NUMBER,
                                                        NEW_FGI,
                                                        NEW_DGI,
                                                        ROHS_COMPLIANT,
                                                        SITE_CODE,
                                                        PROCESS_STATUS,
                                                        UPDATED_BY,
                                                        UPDATED_ON,
                                                        CREATED_BY,
                                                        CREATED_ON,
                                                        POE_BATCH_ID,
                                                        PROGRAM_TYPE)
                                                 VALUES (
                                                            lv_inv_Log_seq2,
                                                            o_trans_dtl_tab (
                                                                i).refresh_part_number, --i_part_number, Modified by satbanda for US123787 - Inventory Adjustments Upload feature
                                                            --DECODE (o_trans_dtl_tab (i).site_location, 'GDGI', 0, o_trans_dtl_tab (i).n_attr2),  --modified by hkarka on 09-FEB-2017, insert NEW_FGI for FGI inventory--0,
                                                            -o_trans_dtl_tab (
                                                                 i).TRG_AVBL_TO_RSRV_QTY,
                                                            0,
                                                            DECODE (
                                                                o_trans_dtl_tab (
                                                                    i).rohs_compliant,
                                                                'Y', 'YES',
                                                                'N', 'NO',
                                                                o_trans_dtl_tab (
                                                                    i).rohs_compliant),
                                                            o_trans_dtl_tab (
                                                                i).site_location,
                                                            'N',
                                                            i_created_by,
                                                            SYSDATE,
                                                            i_created_by,
                                                            SYSDATE,
                                                            lv_poe_batch_id,
                                                            SUBSTR (
                                                                o_trans_dtl_tab (
                                                                    i).v_attr1,
                                                                1,
                                                                1) --Modified on 7th Feb, 2017 for restrict to one character value.
                                                                  );

                                        COMMIT;
                                    END IF;

                                    IF o_trans_dtl_tab (i).MASKED_QTY >
                                       lv_adjustment_temp
                                    THEN
                                        INSERT INTO RC_INV_STR_INV_MASK_STG (
                                                        PARTNUMBER,
                                                        SITE,
                                                        ROHS,
                                                        MASKED_QTY,
                                                        CREATED_BY,
                                                        CREATED_AT,
                                                        PROCESSED_STATUS)
                                                 VALUES (
                                                            o_trans_dtl_tab (
                                                                i).refresh_part_number,
                                                            o_trans_dtl_tab (
                                                                i).site_location,
                                                            DECODE (
                                                                o_trans_dtl_tab (
                                                                    i).rohs_compliant,
                                                                'Y', 'YES',
                                                                'N', 'NO',
                                                                o_trans_dtl_tab (
                                                                    i).rohs_compliant),
                                                            lv_adjustment_temp,
                                                            'ADJUSTMENT',
                                                            SYSDATE,
                                                            'N');

                                        COMMIT;
                                    ELSE
                                        INSERT INTO RC_INV_STR_INV_MASK_STG (
                                                        PARTNUMBER,
                                                        SITE,
                                                        ROHS,
                                                        MASKED_QTY,
                                                        CREATED_BY,
                                                        CREATED_AT,
                                                        PROCESSED_STATUS)
                                                 VALUES (
                                                            o_trans_dtl_tab (
                                                                i).refresh_part_number,
                                                            o_trans_dtl_tab (
                                                                i).site_location,
                                                            DECODE (
                                                                o_trans_dtl_tab (
                                                                    i).rohs_compliant,
                                                                'Y', 'YES',
                                                                'N', 'NO',
                                                                o_trans_dtl_tab (
                                                                    i).rohs_compliant),
                                                            o_trans_dtl_tab (
                                                                i).MASKED_QTY,
                                                            'ADJUSTMENT',
                                                            SYSDATE,
                                                            'N');

                                        lv_adjustment_temp :=
                                              lv_adjustment_temp
                                            - o_trans_dtl_tab (i).MASKED_QTY;

                                        INSERT INTO RMK_INVENTORY_LOG (
                                                        INVENTORY_LOG_ID,
                                                        PART_NUMBER,
                                                        NEW_FGI,
                                                        NEW_DGI,
                                                        ROHS_COMPLIANT,
                                                        SITE_CODE,
                                                        PROCESS_STATUS,
                                                        UPDATED_BY,
                                                        UPDATED_ON,
                                                        CREATED_BY,
                                                        CREATED_ON,
                                                        POE_BATCH_ID,
                                                        PROGRAM_TYPE)
                                                 VALUES (
                                                            lv_inv_Log_seq2,
                                                            o_trans_dtl_tab (
                                                                i).refresh_part_number, --i_part_number, Modified by satbanda for US123787 - Inventory Adjustments Upload feature
                                                            --DECODE (o_trans_dtl_tab (i).site_location, 'GDGI', 0, o_trans_dtl_tab (i).n_attr2),  --modified by hkarka on 09-FEB-2017, insert NEW_FGI for FGI inventory--0,
                                                            -lv_adjustment_temp,
                                                            0,
                                                            DECODE (
                                                                o_trans_dtl_tab (
                                                                    i).rohs_compliant,
                                                                'Y', 'YES',
                                                                'N', 'NO',
                                                                o_trans_dtl_tab (
                                                                    i).rohs_compliant),
                                                            o_trans_dtl_tab (
                                                                i).site_location,
                                                            'N',
                                                            i_created_by,
                                                            SYSDATE,
                                                            i_created_by,
                                                            SYSDATE,
                                                            lv_poe_batch_id,
                                                            SUBSTR (
                                                                o_trans_dtl_tab (
                                                                    i).v_attr1,
                                                                1,
                                                                1) --Modified on 7th Feb, 2017 for restrict to one character value.
                                                                  );
                                    END IF;
                                END IF;

                                lv_adjustment_temp := 0;
                            ELSE
                                INSERT INTO RMK_INVENTORY_LOG (
                                                INVENTORY_LOG_ID,
                                                PART_NUMBER,
                                                NEW_FGI,
                                                NEW_DGI,
                                                ROHS_COMPLIANT,
                                                SITE_CODE,
                                                PROCESS_STATUS,
                                                UPDATED_BY,
                                                UPDATED_ON,
                                                CREATED_BY,
                                                CREATED_ON,
                                                POE_BATCH_ID,
                                                PROGRAM_TYPE)
                                         VALUES (
                                                    lv_inv_Log_seq2,
                                                    o_trans_dtl_tab (i).refresh_part_number, --i_part_number, Modified by satbanda for US123787 - Inventory Adjustments Upload feature
                                                    --DECODE (o_trans_dtl_tab (i).site_location, 'GDGI', 0, o_trans_dtl_tab (i).n_attr2),  --modified by hkarka on 09-FEB-2017, insert NEW_FGI for FGI inventory--0,
                                                    DECODE (
                                                        o_trans_dtl_tab (i).site_location,
                                                        'GDGI', 0,
                                                        NVL (
                                                            o_trans_dtl_tab (
                                                                i).n_attr2,
                                                            o_trans_dtl_tab (
                                                                i).n_attr1)),
                                                    --DECODE (o_trans_dtl_tab (i).site_location, 'GDGI', o_trans_dtl_tab (i).n_attr2, 0),  --modified by hkarka on 09-FEB-2017, insert NEW_DGI for DGI inventory
                                                    DECODE (
                                                        o_trans_dtl_tab (i).site_location,
                                                        'GDGI', NVL (
                                                                    o_trans_dtl_tab (
                                                                        i).n_attr2,
                                                                    o_trans_dtl_tab (
                                                                        i).n_attr1),
                                                        0),
                                                    DECODE (
                                                        o_trans_dtl_tab (i).rohs_compliant,
                                                        'Y', 'YES',
                                                        'N', 'NO',
                                                        o_trans_dtl_tab (i).rohs_compliant),
                                                    o_trans_dtl_tab (i).site_location,
                                                    'N',
                                                    i_created_by,
                                                    SYSDATE,
                                                    i_created_by,
                                                    SYSDATE,
                                                    lv_poe_batch_id,
                                                    SUBSTR (
                                                        o_trans_dtl_tab (i).v_attr1,
                                                        1,
                                                        1) --Modified on 7th Feb, 2017 for restrict to one character value.
                                                          );
                            END IF;

                            COMMIT;
                        END IF;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            v_message := SUBSTR (SQLERRM, 1, 200);

                            --Added by satbanda for process status change when get exception <Start>
                            UPDATE rmk_adminui_invtransfer
                               SET process_status = 'ERROR'
                             WHERE request_id = lv_request_id;

                            --Added by satbanda for process status change when get exception <End>

                            P_RCEC_ERROR_LOG (
                                I_module_name =>
                                    'P_INV_SU_TRANSREQ',
                                I_entity_name =>
                                       'Part_number'
                                    || '->'
                                    || o_trans_dtl_tab (i).refresh_part_number, --i_part_number, Modified by satbanda for US123787 - Inventory Adjustments Upload feature
                                I_entity_id =>
                                    NULL,
                                I_ext_entity_name =>
                                    'Request_id' || '->' || lv_request_id,
                                I_ext_entity_id =>
                                    NULL,
                                I_error_type =>
                                    'EXCEPTION',
                                i_Error_Message =>
                                       'Error getting while populating the data into RMK_INVENTORY_LOG for following PID: '
                                    || o_trans_dtl_tab (i).refresh_part_number --i_part_number Modified by satbanda for US123787 - Inventory Adjustments Upload feature
                                    || ' <> '
                                    || v_message
                                    || ' LineNo=> '
                                    || DBMS_UTILITY.Format_error_backtrace,
                                I_created_by =>
                                    i_created_by,
                                I_updated_by =>
                                    i_created_by);
                    END;
                END IF;
            END LOOP;
        /* Start added as part of DGI Transfer changes on 14-Jun-2019 */
        --    IF i_request_type = 'CREATE' THEN
        --     insert into debug2 values('Step 1 after create',sysdate);
        --        IF i_trans_type = 'DGI-TRANSFER' THEN
        --        insert into debug2 values('Step 2 after dgi transfer',sysdate);
        --            IF lv_aprove_sts = 'APPROVED' OR lv_aprove_sts = 'AUTO APPROVED' THEN
        --                P_RC_INV_DGI_APPROVAL_NOTIFY (i_created_by, i_part_number);
        --            ELSE
        --                P_RC_INV_TRANS_DGI_NOTIFY_MAIL(i_created_by,i_part_number);
        --            END IF;
        --        END IF;
        --
        --    ELSIF i_request_type = 'UPDATE' THEN
        --    insert into debug2 values('Step 1 after update',sysdate);commit;
        --        IF lv_aprove_sts = 'APPROVED' OR lv_aprove_sts = 'AUTO APPROVED' THEN
        --   insert into debug2 values('Step 2 after approved',sysdate);commit;
        --            IF i_trans_type = 'DGI-TRANSFER' THEN
        --insert into debug2 values('Step 3 after dgi transfer',sysdate);commit;
        --                P_RC_INV_DGI_APPROVAL_NOTIFY (i_created_by, i_part_number);
        --
        --dbms_output.put_line('main step 3 after mail');
        --            END IF;
        --
        --        END IF;
        --
        --    END IF;
        /* End added as part of DGI Transfer changes on 14-Jun-2019 */
        END IF;

        --END IF;

        SELECT COUNT (*)
          INTO lv_adjustment_temp
          FROM RC_INV_STR_INV_MASK_STG
         WHERE CREATED_BY = 'ADJUSTMENT' AND PROCESSED_STATUS = 'N';

        IF (lv_adjustment_temp > 0)
        THEN
            RC_STR_INV_MASK_ADJ ('ADJUSTMENT', lv_ostatus);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            v_message := SUBSTR (SQLERRM, 1, 50); --Added for US123787 - Inventory Adjustments Upload feature
            P_RCEC_ERROR_LOG (
                I_module_name =>
                    'RMK_INV_TRANSFER_PKG',
                I_entity_name =>
                    NULL, --'Part_number' || '->' ||i_part_number, Modified by satbanda for US123787 - Inventory Adjustments Upload feature
                I_entity_id =>
                    NULL,
                I_ext_entity_name =>
                    'Transaction Type' || '->' || i_trans_type,
                I_ext_entity_id =>
                    NULL,
                I_error_type =>
                    'EXCEPTION',
                i_Error_Message =>
                       'Error getting while executing P_INV_SU_TRANSREQ: ' --  for following PID: '
                    --                                  ||i_part_number
                    --                                  || ' <> '  Modified by satbanda for US123787 - Inventory Adjustments Upload feature
                    || v_message
                    || ' LineNo=> '
                    || DBMS_UTILITY.Format_error_backtrace,
                I_created_by =>
                    i_created_by,
                I_updated_by =>
                    i_created_by);
    END P_INV_SU_TRANSREQ;

    PROCEDURE P_INV_PID_VALIDATE (i_part_number   IN            VARCHAR2,
                                  i_created_by    IN            VARCHAR2,
                                  i_user_role     IN            VARCHAR2,
                                  o_err_message      OUT NOCOPY VARCHAR2,
                                  o_pid_lookups      OUT NOCOPY VARCHAR2)
    IS
        lv_count          NUMBER;
        lv_count1         NUMBER;
        lv_part_number    VARCHAR2 (100);
        lv_program_type   NUMBER;
        lv_user_role      VARCHAR2 (20);
        lv_err_msg        VARCHAR2 (500) := NULL;
        lv_pid_lookups    VARCHAR2 (500) := NULL;
    BEGIN
        lv_part_number := UPPER (TRIM (i_part_number));
        lv_user_role := UPPER (TRIM (i_user_role));

        SELECT COUNT (ROWID)
          INTO lv_count
          FROM CRPADM.RC_PRODUCT_MASTER
         WHERE     UPPER (refresh_part_number) = lv_part_number
               AND program_type IN (0, 1);

        SELECT COUNT (ROWID)
          INTO lv_count1
          FROM CRPADM.RC_PRODUCT_MASTER
         WHERE (   UPPER (common_part_number) = lv_part_number
                OR UPPER (xref_part_number) = lv_part_number);

        IF lv_count = 0 AND lv_count1 = 0
        THEN
            lv_err_msg := lv_err_msg || v_invalid_pid_msg;
        ELSIF lv_count = 1
        THEN
            SELECT program_type
              INTO lv_program_type                        --0 for RF, 1 for WS
              FROM CRPADM.RC_PRODUCT_MASTER
             WHERE UPPER (refresh_part_number) = lv_part_number;

            IF lv_program_type = 1
            THEN
                --Commented by satbanda for US137794 <Start>
                /*   IF NVL(lv_user_role,'*') !=v_admin
                  THEN
                      lv_err_msg:=lv_err_msg||v_access_pid_msg;
                  ELSE */
                --Commented by satbanda for US137794 <End>
                lv_pid_lookups :=
                    'ADJUSTMENT|Adjustment,DGI-TRANSFER|DGI Transfer';
            --END IF; --Commented by satbanda for US137794
            ELSE
                --Commented by satbanda for US137794 <Start>
                /*  IF NVL(lv_user_role,'*') !=v_admin
                 THEN
                    lv_pid_lookups:='RETAIL-OUTLET|Retail to Outlet,OUTLET-RETAIL|Outlet to Retail';
                 ELSE */
                --Commented by satbanda for US137794 <End>
                lv_pid_lookups :=
                    'RETAIL-OUTLET|Retail to Outlet,OUTLET-RETAIL|Outlet to Retail,ADJUSTMENT|Adjustment,DGI-TRANSFER|DGI Transfer';
            --END IF;--Commented by satbanda for US137794
            END IF;
        /* Start added as part of DGI Transfer changes on 14-Jun-2019 */
        ELSIF lv_count1 >= 1
        THEN
            lv_pid_lookups := 'DGI-TRANSFER|DGI Transfer';
        ELSE
            lv_err_msg := lv_err_msg || v_invalid_pid_msg;
        END IF;

        /* End added as part of DGI Transfer changes on 14-Jun-2019 */
        o_pid_lookups := lv_pid_lookups;

        o_err_message := lv_err_msg;
    EXCEPTION
        WHEN OTHERS
        THEN
            P_RCEC_ERROR_LOG (
                I_module_name =>
                    'P_INV_PID_VALIDATE',
                I_entity_name =>
                    'Part_number' || '->' || i_part_number,
                I_entity_id =>
                    NULL,
                I_ext_entity_name =>
                    NULL,
                I_ext_entity_id =>
                    NULL,
                I_error_type =>
                    'EXCEPTION',
                i_Error_Message =>
                       'Error getting while executing P_INV_PID_VALIDATE  for following PID: '
                    || i_part_number
                    || ' <> '
                    || v_message
                    || ' LineNo=> '
                    || DBMS_UTILITY.Format_error_backtrace,
                I_created_by =>
                    i_created_by,
                I_updated_by =>
                    i_created_by);
    END P_INV_PID_VALIDATE;

    -- Added for US123787 - Inventory Adjustments Upload feature <Start>
    PROCEDURE P_INV_PIDS_UPLOADER (
        i_uploaded_by        IN            VARCHAR2,
        io_upload_dtl_tab    IN OUT        RMK_INV_TRANSFER_DTL_TAB,
        o_trans_status_tab      OUT NOCOPY RMK_INV_MOVE_STATUS_TAB,
        o_err_message           OUT NOCOPY VARCHAR2,
        o_upload_sts            OUT NOCOPY VARCHAR2          -- SUCCESS/FAILED
                                                   )
    IS
        lv_count                     NUMBER;
        lv_part_number               VARCHAR2 (100);
        lv_program_type              NUMBER;
        lv_user_role                 VARCHAR2 (20);
        lv_err_msg                   VARCHAR2 (500) := NULL;
        lv_invalid_msg               VARCHAR2 (32767);
        lv_inv_flow_msg              VARCHAR2 (32767);
        lv_site_rohs_msg             VARCHAR2 (32767);
        lv_status                    VARCHAR2 (500) := 'SUCCESS';
        tab_upload_dtl               RMK_INV_TRANSFER_DTL_TAB
                                         := RMK_INV_TRANSFER_DTL_TAB ();
        type_inv_transfer_dtl_tab    RMK_INV_TRANSFER_DTL_TAB
                                         := RMK_INV_TRANSFER_DTL_TAB ();
        type_inv_transfer_dtl_tab1   RMK_INV_TRANSFER_DTL_TAB
                                         := RMK_INV_TRANSFER_DTL_TAB ();
        tab_trans_status             RMK_INV_MOVE_STATUS_TAB
                                         := RMK_INV_MOVE_STATUS_TAB ();
    BEGIN
        tab_upload_dtl := io_upload_dtl_tab;

        IF tab_upload_dtl.EXISTS (1)
        THEN
            FOR rec_pid IN tab_upload_dtl.FIRST .. tab_upload_dtl.LAST
            LOOP
                lv_part_number :=
                    UPPER (
                        TRIM (tab_upload_dtl (rec_pid).refresh_part_number));

                BEGIN
                    SELECT program_type
                      INTO lv_program_type
                      FROM CRPADM.RC_PRODUCT_MASTER
                     WHERE     UPPER (refresh_part_number) = lv_part_number
                           AND program_type IN (0, 1);

                    lv_count := 1;

                    tab_upload_dtl (rec_pid).n_attr3 := lv_program_type;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        lv_program_type := NULL;
                        lv_count := 0;
                END;

                IF lv_count = 0
                THEN
                    IF lv_invalid_msg IS NOT NULL
                    THEN
                        lv_invalid_msg := lv_invalid_msg || ',' || rec_pid;
                    ELSE
                        lv_invalid_msg :=
                               'System identified Invalid PID at line #  '
                            || rec_pid;
                    END IF;
                END IF;

                IF     lv_program_type = 1
                   AND UPPER (TRIM (tab_upload_dtl (rec_pid).v_attr1)) !=
                       'EXCESS'
                THEN
                    IF lv_inv_flow_msg IS NOT NULL
                    THEN
                        lv_inv_flow_msg := lv_inv_flow_msg || ',' || rec_pid;
                    ELSE
                        lv_inv_flow_msg :=
                               'Retail inventory adjustment is not allowed for Excess PID at line number(s): '
                            || rec_pid;
                    END IF;
                END IF;


                IF     UPPER (tab_upload_dtl (rec_pid).site_location) IN
                           ('FVE', 'GDGI')
                   AND UPPER (tab_upload_dtl (rec_pid).rohs_compliant) = 'NO'
                THEN
                    IF lv_site_rohs_msg IS NOT NULL
                    THEN
                        lv_site_rohs_msg :=
                            lv_site_rohs_msg || ',' || rec_pid;
                    ELSE
                        lv_site_rohs_msg :=
                               'Non ROHS inventory adjustment is not allowed for FVE/GDGI at line number(s): '
                            || rec_pid;
                    END IF;
                END IF;
            END LOOP;
        ELSE
            lv_err_msg := 'There is no data exist in uploaded file';
            lv_status := 'FAILED';
        END IF;


        IF lv_invalid_msg IS NOT NULL AND lv_inv_flow_msg IS NOT NULL
        THEN
            lv_err_msg := lv_invalid_msg || ' <br>' || lv_inv_flow_msg;
        ELSIF lv_invalid_msg IS NOT NULL
        THEN
            lv_err_msg := lv_invalid_msg;
        ELSIF lv_inv_flow_msg IS NOT NULL
        THEN
            lv_err_msg := lv_inv_flow_msg;
        END IF;

        IF lv_err_msg IS NOT NULL AND lv_site_rohs_msg IS NOT NULL
        THEN
            lv_err_msg := lv_err_msg || ' <br>' || lv_site_rohs_msg;
        ELSIF lv_site_rohs_msg IS NOT NULL
        THEN
            lv_err_msg := lv_site_rohs_msg;
        END IF;

        IF lv_err_msg IS NOT NULL
        THEN
            lv_status := 'FAILED';
        ELSE
            lv_status := 'SUCCESS';
        END IF;

        o_err_message := lv_err_msg;
        o_upload_sts := lv_status;

        io_upload_dtl_tab := tab_upload_dtl;

        IF lv_status = 'SUCCESS'
        THEN
            SELECT RMK_INV_TRANSFER_DTL_OBJECT (
                       refresh_part_number,
                       site_code,
                       rohs_compliant,
                       NVL (Available_Quantity, 0),
                       NVL (Reserved_Quantity, 0),
                       NVL (Availble_to_Reserve_Qty, 0),
                       NULL,
                       NULL,
                       NULL,
                       inventory_flow,
                       NULL,
                       Restriction_flag,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       MASKED_QTY,                         --added by sneyadav
                       NULL)        --Added by csirigir on 01-JUL-2020 as part of US398932                                     
              BULK COLLECT INTO type_inv_transfer_dtl_tab1
              FROM (  SELECT refresh_part_number,
                             inventory_flow,
                             site_code,
                             f_get_pending_flag (refresh_part_number,
                                                 site_code,
                                                 rohs_compliant)
                                 Restriction_flag,
                             rohs_compliant,
                             Available_Quantity,
                             Reserved_Quantity,
                             Availble_to_Reserve_Qty,
                             DECODE (site_code,  'LRO', 1,  'FVE', 2,  3)
                                 Site_Sequence,
                             CASE
                                 WHEN     SITE_CODE = 'LRO'
                                      AND ROHS_COMPLIANT = 'YES'
                                 THEN
                                     NVL (SP.LRO_RHS_QUANTITY, 0)
                                 WHEN     SITE_CODE = 'FVE'
                                      AND ROHS_COMPLIANT = 'YES'
                                 THEN
                                     NVL (SP.FVE_RHS_QUANTITY, 0)
                                 WHEN     SITE_CODE = 'LRO'
                                      AND ROHS_COMPLIANT = 'NO'
                                 THEN
                                     NVL (SP.LRO_NRHS_QUANTITY, 0)
                                 WHEN     SITE_CODE = 'FVE'
                                      AND ROHS_COMPLIANT = 'NO'
                                 THEN
                                     0
                                 ELSE
                                     0
                             END
                                 MASKED_QTY
                        FROM (  SELECT rpm.refresh_part_number,
                                       ris.inventory_flow,
                                       ris.site_code,
                                       ris.rohs_compliant,
                                       SUM (
                                           DECODE (ris.site_code,
                                                   'GDGI', xri.available_dgi,
                                                   xri.available_fgi))
                                           Available_Quantity,
                                       SUM (
                                           DECODE (ris.site_code,
                                                   'GDGI', xri.reserved_dgi,
                                                   xri.reserved_fgi))
                                           Reserved_Quantity,
                                       SUM (
                                           DECODE (
                                               ris.site_code,
                                               'GDGI', xri.available_to_reserve_dgi,
                                               xri.available_to_reserve_fgi))
                                           Availble_to_Reserve_Qty
                                  FROM (SELECT *
                                          FROM crpadm.rc_product_master
                                         WHERE     program_type IN (0, 1)
                                               AND refresh_part_number IN
                                                       (SELECT refresh_part_number
                                                          FROM TABLE (
                                                                   CAST (
                                                                       tab_upload_dtl AS rmk_inv_transfer_dtl_tab))))
                                       rpm
                                       LEFT OUTER JOIN
                                       (SELECT *
                                          FROM rmktgadm.rmk_inv_site_code_dtl)
                                       ris
                                           ON (   ris.inventory_flow =
                                                  DECODE (rpm.program_type,
                                                          0, 'Retail',
                                                          'Excess')
                                               OR ris.inventory_flow =
                                                  DECODE (rpm.program_type,
                                                          0, 'Outlet',
                                                          'Excess'))
                                       LEFT OUTER JOIN
                                       (SELECT *
                                          FROM rmktgadm.xxcpo_rmk_inventory_master
                                         WHERE     site_code IN
                                                       ('LRO', 'FVE', 'GDGI')
                                               AND inventory_flow IN
                                                       ('Retail',
                                                        'Outlet',
                                                        'Excess')) xri
                                           ON (    xri.part_number =
                                                   rpm.refresh_part_number
                                               AND xri.site_code = ris.site_code
                                               AND ris.rohs_compliant =
                                                   xri.rohs_compliant
                                               AND ris.inventory_flow =
                                                   xri.inventory_flow)
                                 WHERE     ris.site_code IN
                                               ('LRO', 'FVE', 'GDGI')
                                       AND (ris.inventory_flow,
                                            rpm.refresh_part_number,
                                            ris.site_code) IN
                                               (SELECT v_attr1,
                                                       refresh_part_number,
                                                       site_location
                                                  FROM TABLE (
                                                           CAST (
                                                               tab_upload_dtl AS rmk_inv_transfer_dtl_tab)))
                              GROUP BY rpm.refresh_part_number,
                                       ris.inventory_flow,
                                       ris.site_code,
                                       ris.rohs_compliant) part_detail
                             LEFT OUTER JOIN
                             (SELECT partnumber,
                                     LRO_RHS_QUANTITY,
                                     LRO_NRHS_QUANTITY,
                                     FVE_RHS_QUANTITY,
                                     TOTAL_QUANTITY,
                                     CREATED_ON
                                FROM RC_INV_STR_INV_MASK_MV
                               WHERE TRUNC (CREATED_ON) =
                                     (SELECT TRUNC (MAX (CREATED_ON))
                                        FROM RC_INV_STR_INV_MASK_MV)) SP
                                 ON (part_detail.refresh_part_number =
                                     sp.partnumber)
                    ORDER BY refresh_part_number,
                             inventory_flow DESC,
                             Site_Sequence);

            SELECT RMK_INV_TRANSFER_DTL_OBJECT (refresh_part_number,
                                                site_location,
                                                rohs_compliant,
                                                src_avbl_qty,
                                                src_rsrv_qty,
                                                src_avbl_to_rsrv_qty,
                                                NULL,
                                                NULL,
                                                NULL,
                                                inventory_flow,
                                                user_comments,
                                                Restricted_flag,
                                                NULL,
                                                AdjustmentQty,
                                                op_rohs_qty,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                MASKED_QTY, --added by sneyadav
                                                NULL)       --Added by csirigir on 01-JUL-2020 as part of US398932                                                
              BULK COLLECT INTO type_inv_transfer_dtl_tab
              FROM (SELECT rit1.refresh_part_number,
                           rit1.site_location,
                           rit1.rohs_compliant,
                           rit1.src_avbl_qty,
                           rit1.src_rsrv_qty,
                           rit1.src_avbl_to_rsrv_qty,
                           rit1.v_attr1
                               inventory_flow,
                           rit1.v_attr3
                               Restricted_flag,
                           NVL (rit2.n_attr1, 0)
                               AdjustmentQty,
                           (SELECT NVL (src_avbl_qty, 0)
                              FROM TABLE (
                                       CAST (
                                           type_inv_transfer_dtl_tab1 AS rmk_inv_transfer_dtl_tab))
                             WHERE     v_attr1 = rit2.v_attr1
                                   AND refresh_part_number =
                                       rit2.refresh_part_number
                                   AND site_location = rit2.site_location
                                   AND rohs_compliant =
                                       DECODE (rit2.rohs_compliant,
                                               'YES', 'NO',
                                               'YES'))
                               op_rohs_qty,
                           rit2.v_attr2
                               user_comments,
                           rit1.MASKED_QTY
                      FROM TABLE (
                               CAST (
                                   type_inv_transfer_dtl_tab1 AS rmk_inv_transfer_dtl_tab))
                           rit1,
                           TABLE (
                               CAST (
                                   tab_upload_dtl AS rmk_inv_transfer_dtl_tab))
                           rit2
                     WHERE     rit1.v_attr1 = rit2.v_attr1
                           AND rit1.refresh_part_number =
                               rit2.refresh_part_number
                           AND rit1.site_location = rit2.site_location
                           AND rit1.rohs_compliant = rit2.rohs_compliant);

            io_upload_dtl_tab := type_inv_transfer_dtl_tab;

            SELECT RMK_INV_MOVE_STATUS_OBJECT (REQUEST_ID,
                                               PART_NUMBER,
                                               TRANSACTION_TYPE,
                                               PROGRAM_TYPE,
                                               SITE_CODE,
                                               ROHS_COMPLIANT_FLAG,
                                               QTY_TO_TRANSFER,
                                               REQUESTED_BY,
                                               REQUESTED_DATE,
                                               APPROVED_BY,
                                               APPROVED_DATE,
                                               APROVAL_STATUS,
                                               PROCESS_STATUS,
                                               COMMENTS,
                                               NULL,
                                               APPROVER_COMMENTS,
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               STRATEGIC_MASKED_QTY)
              BULK COLLECT INTO tab_trans_status
              FROM (  SELECT REQUEST_ID,
                             PART_NUMBER,
                             CASE
                                 WHEN TRANSACTION_TYPE = v_Retail_Outlet
                                 THEN
                                     'Retail to Outlet'
                                 WHEN TRANSACTION_TYPE = v_Outlet_Retail
                                 THEN
                                     'Outlet to Retail'
                                 WHEN TRANSACTION_TYPE = v_Adjustment
                                 THEN
                                     'Adjustment' || '-' || FROM_PROGRAM_TYPE
                             END
                                 TRANSACTION_TYPE,
                             NULL
                                 PROGRAM_TYPE,
                             SITE_CODE,
                             ROHS_COMPLIANT_FLAG,
                             QTY_TO_TRANSFER,
                             REQUESTED_BY,
                             REQUESTED_DATE,
                             APPROVED_BY,
                             APPROVED_DATE,
                             APROVAL_STATUS,
                             PROCESS_STATUS,
                             COMMENTS,
                             APPROVER_COMMENTS,
                             CASE
                                 WHEN     SITE_CODE = 'LRO'
                                      AND ROHS_COMPLIANT_FLAG = 'YES'
                                 THEN
                                     NVL (SP.LRO_RHS_QUANTITY, 0)
                                 WHEN     SITE_CODE = 'FVE'
                                      AND ROHS_COMPLIANT_FLAG = 'YES'
                                 THEN
                                     NVL (SP.FVE_RHS_QUANTITY, 0)
                                 WHEN     SITE_CODE = 'LRO'
                                      AND ROHS_COMPLIANT_FLAG = 'NO'
                                 THEN
                                     NVL (SP.LRO_NRHS_QUANTITY, 0)
                                 WHEN     SITE_CODE = 'FVE'
                                      AND ROHS_COMPLIANT_FLAG = 'NO'
                                 THEN
                                     0
                                 ELSE
                                     0
                             END
                                 STRATEGIC_MASKED_QTY
                        FROM RMK_ADMINUI_INVTRANSFER
                             LEFT OUTER JOIN
                             (SELECT partnumber,
                                     LRO_RHS_QUANTITY,
                                     LRO_NRHS_QUANTITY,
                                     FVE_RHS_QUANTITY,
                                     TOTAL_QUANTITY,
                                     CREATED_ON
                                FROM RC_INV_STR_INV_MASK_MV
                               WHERE TRUNC (CREATED_ON) =
                                     (SELECT TRUNC (MAX (CREATED_ON))
                                        FROM RC_INV_STR_INV_MASK_MV)) SP
                                 ON (part_number = sp.partnumber)
                       WHERE     part_number IN
                                     (SELECT refresh_part_number
                                        FROM TABLE (
                                                 CAST (
                                                     tab_upload_dtl AS rmk_inv_transfer_dtl_tab)))
                             AND NVL (UPPER (APROVAL_STATUS), '*') !=
                                 v_rejected
                             AND (   APPROVED_DATE IS NULL
                                  OR APPROVED_DATE >= SYSDATE - (1 / 24))
                    ORDER BY REQUEST_ID DESC);

            o_trans_status_tab := tab_trans_status;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            P_RCEC_ERROR_LOG (
                I_module_name =>
                    'P_INV_PIDS_UPLOADER',
                I_entity_name =>
                    NULL,            --'Part_number' || '->' || i_part_number,
                I_entity_id =>
                    NULL,
                I_ext_entity_name =>
                    NULL,
                I_ext_entity_id =>
                    NULL,
                I_error_type =>
                    'EXCEPTION',
                i_Error_Message =>
                       'Error getting while executing P_INV_PIDS_UPLOADER  for following user: '
                    || i_uploaded_by
                    || ' <> '
                    || v_message
                    || ' LineNo=> '
                    || DBMS_UTILITY.Format_error_backtrace,
                I_created_by =>
                    i_uploaded_by,
                I_updated_by =>
                    i_uploaded_by);
    END P_INV_PIDS_UPLOADER;

    -- Added for US123787 - Inventory Adjustments Upload feature <End>

    -- Added for US137794 - Inventory Utility Email notifications <Start>
    PROCEDURE RC_INV_TRANS_NOTIFY_MAIL
    IS
        lv_msg_from            VARCHAR2 (500);
        lv_email_sender        VARCHAR2 (100) := 'remarketing-it@cisco.com';
        lv_msg_to              VARCHAR2 (500);
        lv_msg_subject         VARCHAR2 (32767);
        lv_tmsg_subject        VARCHAR2 (32767);
        lv_msg_text            VARCHAR2 (32767);
        lv_lro_msg_text        CLOB;
        lv_fve_msg_text        VARCHAR2 (32767);
        lv_dgi_msg_text        VARCHAR2 (32767);
        lv_trn_msg_text        VARCHAR2 (32767);
        lv_output_hdr          CLOB;
        lv_count               NUMBER := 0;
        lv_output              CLOB;
        lv_database_name       VARCHAR2 (50);
        lv_filename            VARCHAR2 (5000);
        lv_start_time          VARCHAR2 (100);
        lv_request_ids         VARCHAR2 (300);
        lv_count_col           NUMBER := 0;
        lv_req_recipients      VARCHAR2 (32767);
        lv_proc_recipients     VARCHAR2 (32767);
        lv_approval_rec_flag   VARCHAR2 (3) := v_no_flag; --Added by sabanda for US161611
    BEGIN
        SELECT ora_database_name INTO lv_database_name FROM DUAL;

        IF (lv_database_name = 'FNTR2PRD.CISCO.COM')
        THEN
            lv_tmsg_subject := NULL;
        ELSIF (lv_database_name = 'FNTR2STG.CISCO.COM')
        THEN
            lv_tmsg_subject := 'STAGE : ';
        ELSE
            lv_tmsg_subject := 'DEV : ';
        END IF;

        SELECT TO_CHAR (SYSDATE, 'MM/DD/YYYY HH:MI:SS PM')
          INTO lv_start_time
          FROM DUAL;


        lv_msg_text :=
            ' <head>
                    <style>
                    table {
                        font-family: arial, sans-serif;
                        border-collapse: collapse;
                        width: 100%;
                    }

                    td, th {
                        border: 1px solid black;
                        text-align: left;
                        padding: 4px;
                    }
                    </style>
                    </head>
                    <body>
                    <table>
                         <tr>
                        <th>Request ID</th><th>Refresh ID</th><th>Tan ID</th><th>Transaction Type</th><th>Location</th><th>ROHS Compliant</th><th>Qty Requested</th><th>Qty Approved</th><th>Requested By</th><th>Status</th><th>Requestor Comments</th><th>Approver Comments</th><th>Requested Date</th><th>Processed By</th><th>Processed Date</th></tr>';


        lv_count_col := 0;

        lv_lro_msg_text :=
               '<HTML>'
            || '<br /><br /> '
            || ' LRO BTS Inventory Adjustment Requests given below.'
            || '<br /><br /> '
            || lv_msg_text;

        lv_req_recipients := NULL;

        lv_proc_recipients := NULL;

        lv_approval_rec_flag := v_no_flag;     --Added by sabanda for US161611

        FOR rec
            IN ( /* SELECT *
                  FROM rmktgadm.rmk_adminui_invtransfer
                 WHERE   */
                  /* SELECT rpm.tan_id,rai.*
                    FROM rmktgadm.rmk_adminui_invtransfer rai,
                          crpadm.rc_product_master rpm
                   WHERE part_number=rpm.refresh_part_number AND
                              site_code = 'LRO'
                         AND transaction_type = 'ADJUSTMENT'
                         AND (   (approved_date IS NULL
                                 AND requested_date>=SYSDATE-1/24)--Added by sabanda for US161611
                              --OR approved_date >= SYSDATE - (1 / 48)
                              OR (approved_date > TRUNC(SYSDATE)+1/24*(FLOOR((SYSDATE-TRUNC(SYSDATE))*24)-1) AND approved_date <= TRUNC(SYSDATE)+1/24*(FLOOR((SYSDATE-TRUNC(SYSDATE))*24)))
                              OR (approved_date IS NULL
                                 AND EXISTS (SELECT 1 FROM rmktgadm.rmk_adminui_invtransfer WHERE transaction_type = rai.transaction_type AND site_code=rai.site_code AND approved_date > TRUNC(SYSDATE)+1/24*(FLOOR((SYSDATE-TRUNC(SYSDATE))*24)-1) AND approved_date <= TRUNC(SYSDATE)+1/24*(FLOOR((SYSDATE-TRUNC(SYSDATE))*24)))
                                 )
                                 )
                         AND (NVL(UPPER(aproval_status),'*') NOT LIKE 'AUTO%'
                         OR NVL(attribute1,v_no_flag) = v_yes_flag) --Added by sabanda for US157355
                ORDER BY process_status DESC, requested_date DESC, requested_by) */
                  SELECT *
                    FROM (SELECT rpm.tan_id,
                                 rai.REQUEST_ID,
                                 rai.PART_NUMBER,
                                 rai.TRANSACTION_TYPE,
                                 rai.FROM_PROGRAM_TYPE,
                                 rai.SITE_CODE,
                                 rai.ROHS_COMPLIANT_FLAG,
                                 rai.QTY_TO_TRANSFER,
                                 rai.QTY_TO_PROCESS,
                                 rai.REQUESTED_BY,
                                 CASE
                                     WHEN UPPER (rai.APROVAL_STATUS) LIKE
                                              'AUTO%'
                                     THEN
                                         'Approved'
                                     WHEN UPPER (rai.APROVAL_STATUS) LIKE
                                              'APPROVE%'
                                     THEN
                                         'Approved'
                                     ELSE
                                         INITCAP (rai.APROVAL_STATUS)
                                 END
                                     APROVAL_STATUS,
                                 INITCAP (rai.PROCESS_STATUS)
                                     PROCESS_STATUS,
                                 rai.COMMENTS,
                                 rai.APPROVER_COMMENTS,
                                 rai.REQUESTED_DATE,
                                 rai.APPROVED_BY,
                                 rai.APPROVED_DATE
                            FROM rmktgadm.rmk_adminui_invtransfer rai,
                                 crpadm.rc_product_master        rpm
                           WHERE     part_number = rpm.refresh_part_number
                                 AND site_code = 'LRO'
                                 AND transaction_type = 'ADJUSTMENT'
                                 AND (   (    approved_date IS NULL
                                          AND EXISTS
                                                  (SELECT 1
                                                     FROM rmktgadm.rmk_adminui_invtransfer
                                                    WHERE     transaction_type =
                                                              rai.transaction_type
                                                          AND site_code =
                                                              rai.site_code
                                                          AND (   requested_date BETWEEN   TRUNC (
                                                                                               SYSDATE)
                                                                                         +   1
                                                                                           / 24
                                                                                           * (  FLOOR (
                                                                                                      (  SYSDATE
                                                                                                       - TRUNC (
                                                                                                             SYSDATE))
                                                                                                    * 24)
                                                                                              - 1)
                                                                                     AND   TRUNC (
                                                                                               SYSDATE)
                                                                                         +   1
                                                                                           / 24
                                                                                           * (FLOOR (
                                                                                                    (  SYSDATE
                                                                                                     - TRUNC (
                                                                                                           SYSDATE))
                                                                                                  * 24))
                                                               OR (    approved_date BETWEEN   TRUNC (
                                                                                                   SYSDATE)
                                                                                             +   1
                                                                                               / 24
                                                                                               * (  FLOOR (
                                                                                                          (  SYSDATE
                                                                                                           - TRUNC (
                                                                                                                 SYSDATE))
                                                                                                        * 24)
                                                                                                  - 1)
                                                                                         AND   TRUNC (
                                                                                                   SYSDATE)
                                                                                             +   1
                                                                                               / 24
                                                                                               * (FLOOR (
                                                                                                        (  SYSDATE
                                                                                                         - TRUNC (
                                                                                                               SYSDATE))
                                                                                                      * 24))
                                                                   AND (   NVL (
                                                                               UPPER (
                                                                                   aproval_status),
                                                                               '*') NOT LIKE
                                                                               'AUTO%'
                                                                        OR NVL (
                                                                               attribute1,
                                                                               v_no_flag) =
                                                                           v_yes_flag)))))
                                      OR (    approved_date >
                                                TRUNC (SYSDATE)
                                              +   1
                                                / 24
                                                * (  FLOOR (
                                                           (  SYSDATE
                                                            - TRUNC (SYSDATE))
                                                         * 24)
                                                   - 1)
                                          AND approved_date <=
                                                TRUNC (SYSDATE)
                                              +   1
                                                / 24
                                                * (FLOOR (
                                                         (  SYSDATE
                                                          - TRUNC (SYSDATE))
                                                       * 24))))
                                 AND (   NVL (UPPER (aproval_status), '*') NOT LIKE
                                             'AUTO%'
                                      OR NVL (attribute1, v_no_flag) =
                                         v_yes_flag)) --Added by sabanda for US157355
                ORDER BY process_status DESC,
                         requested_date DESC,
                         requested_by)
        LOOP
            IF lv_req_recipients IS NULL
            THEN
                lv_req_recipients := rec.requested_by;
            ELSE
                lv_req_recipients :=
                    lv_req_recipients || ',' || rec.requested_by;
            END IF;

            IF     lv_proc_recipients IS NULL
               AND rec.approved_by IS NOT NULL
               AND NVL (UPPER (rec.aproval_status), '*') NOT LIKE 'AUTO%' --Added by sabanda for US157355
            THEN
                lv_proc_recipients := rec.approved_by;
                lv_approval_rec_flag := v_yes_flag; --Added by sabanda for US161611
            ELSIF     rec.approved_by IS NOT NULL
                  AND NVL (UPPER (rec.aproval_status), '*') NOT LIKE 'AUTO%' --Added by sabanda for US157355
            THEN
                lv_proc_recipients :=
                    lv_proc_recipients || ',' || rec.approved_by;
                lv_approval_rec_flag := v_yes_flag; --Added by sabanda for US161611
            END IF;

            IF MOD (lv_count_col, 2) = 0
            THEN
                lv_lro_msg_text :=
                       lv_lro_msg_text
                    || '<tr style="background-color: #dddddd">';
            ELSE
                lv_lro_msg_text := lv_lro_msg_text || '<tr>';
            END IF;

            lv_lro_msg_text :=
                   lv_lro_msg_text
                || '
                            <td>'
                || rec.REQUEST_ID
                || '</td><td nowrap>'
                || rec.PART_NUMBER
                || '</td><td nowrap>'
                || rec.TAN_ID
                || '</td><td nowrap>'
                || rec.TRANSACTION_TYPE
                || '-'
                || rec.FROM_PROGRAM_TYPE
                || '</td><td>'
                || rec.SITE_CODE
                || '</td><td>'
                || rec.ROHS_COMPLIANT_FLAG
                || '</td><td>'
                || rec.QTY_TO_TRANSFER
                || '</td><td>'
                || rec.QTY_TO_PROCESS
                || '</td><td nowrap>'
                || rec.REQUESTED_BY
                || '</td><td nowrap>'
                --|| rec.APROVAL_STATUS --Commented by satbanda for US161611
                || INITCAP (NVL (rec.APROVAL_STATUS, rec.PROCESS_STATUS)) --Added by satbanda for US161611
                || '</td><td nowrap>'
                || rec.COMMENTS
                || '</td><td nowrap>'
                || rec.APPROVER_COMMENTS
                || '</td><td nowrap>'
                || TO_CHAR (rec.REQUESTED_DATE, 'DD-Mon-YYYY HH:Mi:SS')
                || '</td><td nowrap>'
                || rec.APPROVED_BY
                || '</td><td nowrap>'
                || TO_CHAR (rec.APPROVED_DATE, 'DD-Mon-YYYY HH:Mi:SS')
                || '</td></tr>';

            lv_count_col := lv_count_col + 1;
        END LOOP;


        lv_lro_msg_text :=
               lv_lro_msg_text
            || '</table>'
            || '<br> '
            || ' It might take approximately an hour to update the inventory for Ordering.'
            || '<br> '
            || 'PLEASE DO NOT REPLY .. This is an Auto generated Email.'
            || '
                      </body> </html>';

        lv_msg_subject := NULL;

        IF lv_count_col > 0
        THEN
            lv_msg_subject :=
                   lv_tmsg_subject
                || 'LRO BTS Inventory Adjustment requests - '
                || lv_start_time;

            BEGIN
                SELECT email_sender, email_recipients
                  INTO lv_msg_from, lv_msg_to
                  FROM crpadm.rc_email_notifications
                 WHERE notification_name =
                       CASE
                           WHEN lv_database_name = 'FNTR2PRD.CISCO.COM'
                           THEN
                               --  'INV_TRANS_ADJ_LRO_NOTIFY'
                               DECODE (
                                   lv_approval_rec_flag,
                                   v_yes_flag, 'INV_TRANS_ADJ_LRO_NOTIFY',
                                   'INV_TRANS_ADJ_LRO_RNOTIFY') --Added by sabanda for US161611
                           WHEN lv_database_name = 'FNTR2STG.CISCO.COM'
                           THEN
                               'INV_TRANS_ADJ_STG_NOTIFY'
                           ELSE
                               'INV_TRANS_ADJ_DEV_NOTIFY'
                       END;
            EXCEPTION
                WHEN OTHERS
                THEN
                    lv_msg_from := lv_email_sender;
                    lv_msg_to := lv_email_sender;
            END;

            BEGIN
                --Added by satbanda for Multiple recipients issue <start>
                SELECT LISTAGG (participents, ',')
                           WITHIN GROUP (ORDER BY participents, ',')
                  INTO lv_req_recipients
                  FROM ( --Added by satbanda for Multiple recipients issue <End>
                            SELECT DISTINCT REGEXP_SUBSTR (lv_req_recipients,
                                                           '[^,]+',
                                                           1,
                                                           LEVEL)
                                                participents
                              FROM DUAL
                        CONNECT BY REGEXP_SUBSTR (lv_req_recipients,
                                                  '[^,]+',
                                                  1,
                                                  LEVEL)
                                       IS NOT NULL);
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;

            BEGIN
                --Added by satbanda for Multiple recipients issue <start>
                SELECT LISTAGG (participents, ',')
                           WITHIN GROUP (ORDER BY participents, ',')
                  INTO lv_proc_recipients
                  FROM ( --Added by satbanda for Multiple recipients issue <End>
                            SELECT DISTINCT REGEXP_SUBSTR (lv_proc_recipients,
                                                           '[^,]+',
                                                           1,
                                                           LEVEL)
                                                participents
                              -- INTO lv_proc_recipients
                              FROM DUAL
                        CONNECT BY REGEXP_SUBSTR (lv_proc_recipients,
                                                  '[^,]+',
                                                  1,
                                                  LEVEL)
                                       IS NOT NULL);
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;

            IF     lv_req_recipients IS NOT NULL
               AND lv_proc_recipients IS NOT NULL
            THEN
                lv_msg_to :=
                       lv_req_recipients
                    || ','
                    || lv_proc_recipients
                    || ','
                    || lv_msg_to;
            ELSIF lv_req_recipients IS NOT NULL
            THEN
                lv_msg_to := lv_req_recipients || ',' || lv_msg_to;
            END IF;


            BEGIN
                crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (
                    lv_msg_from,
                    lv_msg_to,
                    lv_msg_subject,
                    lv_lro_msg_text,
                    NULL,                                       --lv_filename,
                    NULL                                           --lv_output
                        );
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_message := SUBSTR (SQLERRM, 1, 50);
            END;
        END IF;

        lv_count_col := 0;

        lv_fve_msg_text :=
               '<HTML>'
            || '<br /><br /> '
            || ' FVE BTS Inventory Adjustment Requests given below.'
            || '<br /><br /> '
            || lv_msg_text;

        lv_req_recipients := NULL;

        lv_proc_recipients := NULL;

        lv_approval_rec_flag := v_no_flag;     --Added by sabanda for US161611

        FOR rec
            IN ( /* SELECT *
                  FROM rmktgadm.rmk_adminui_invtransfer
                 WHERE   */
                  /*  SELECT rpm.tan_id,rai.*
                     FROM rmktgadm.rmk_adminui_invtransfer rai,
                           crpadm.rc_product_master rpm
                    WHERE part_number=rpm.refresh_part_number AND
                          site_code = 'FVE'
                          AND transaction_type = 'ADJUSTMENT'
                          AND (   (approved_date IS NULL
                                  AND requested_date>=SYSDATE-1/24)--Added by sabanda for US161611
                                --OR approved_date >= SYSDATE - (1 / 48)
                               OR (approved_date > TRUNC(SYSDATE)+1/24*(FLOOR((SYSDATE-TRUNC(SYSDATE))*24)-1) AND approved_date <= TRUNC(SYSDATE)+1/24*(FLOOR((SYSDATE-TRUNC(SYSDATE))*24)))
                               OR (approved_date IS NULL
                                  AND EXISTS (SELECT 1 FROM rmktgadm.rmk_adminui_invtransfer WHERE transaction_type = rai.transaction_type AND site_code=rai.site_code AND approved_date > TRUNC(SYSDATE)+1/24*(FLOOR((SYSDATE-TRUNC(SYSDATE))*24)-1) AND approved_date <= TRUNC(SYSDATE)+1/24*(FLOOR((SYSDATE-TRUNC(SYSDATE))*24)))
                                  )
                               )
                          AND (NVL(UPPER(aproval_status),'*') NOT LIKE 'AUTO%'
                          OR NVL(attribute1,v_no_flag) = v_yes_flag) --Added by sabanda for US157355
                 ORDER BY process_status DESC, requested_date DESC, requested_by) */
                  SELECT *
                    FROM (SELECT rpm.tan_id,
                                 rai.REQUEST_ID,
                                 rai.PART_NUMBER,
                                 rai.TRANSACTION_TYPE,
                                 rai.FROM_PROGRAM_TYPE,
                                 rai.SITE_CODE,
                                 rai.ROHS_COMPLIANT_FLAG,
                                 rai.QTY_TO_TRANSFER,
                                 rai.QTY_TO_PROCESS,
                                 rai.REQUESTED_BY,
                                 CASE
                                     WHEN UPPER (rai.APROVAL_STATUS) LIKE
                                              'AUTO%'
                                     THEN
                                         'Approved'
                                     WHEN UPPER (rai.APROVAL_STATUS) LIKE
                                              'APPROVE%'
                                     THEN
                                         'Approved'
                                     ELSE
                                         INITCAP (rai.APROVAL_STATUS)
                                 END
                                     APROVAL_STATUS,
                                 INITCAP (rai.PROCESS_STATUS)
                                     PROCESS_STATUS,
                                 rai.COMMENTS,
                                 rai.APPROVER_COMMENTS,
                                 rai.REQUESTED_DATE,
                                 rai.APPROVED_BY,
                                 rai.APPROVED_DATE
                            FROM rmktgadm.rmk_adminui_invtransfer rai,
                                 crpadm.rc_product_master        rpm
                           WHERE     part_number = rpm.refresh_part_number
                                 AND site_code = 'FVE'
                                 AND transaction_type = 'ADJUSTMENT'
                                 AND (   (    approved_date IS NULL
                                          AND EXISTS
                                                  (SELECT 1
                                                     FROM rmktgadm.rmk_adminui_invtransfer
                                                    WHERE     transaction_type =
                                                              rai.transaction_type
                                                          AND site_code =
                                                              rai.site_code
                                                          AND (   requested_date BETWEEN   TRUNC (
                                                                                               SYSDATE)
                                                                                         +   1
                                                                                           / 24
                                                                                           * (  FLOOR (
                                                                                                      (  SYSDATE
                                                                                                       - TRUNC (
                                                                                                             SYSDATE))
                                                                                                    * 24)
                                                                                              - 1)
                                                                                     AND   TRUNC (
                                                                                               SYSDATE)
                                                                                         +   1
                                                                                           / 24
                                                                                           * (FLOOR (
                                                                                                    (  SYSDATE
                                                                                                     - TRUNC (
                                                                                                           SYSDATE))
                                                                                                  * 24))
                                                               OR (    approved_date BETWEEN   TRUNC (
                                                                                                   SYSDATE)
                                                                                             +   1
                                                                                               / 24
                                                                                               * (  FLOOR (
                                                                                                          (  SYSDATE
                                                                                                           - TRUNC (
                                                                                                                 SYSDATE))
                                                                                                        * 24)
                                                                                                  - 1)
                                                                                         AND   TRUNC (
                                                                                                   SYSDATE)
                                                                                             +   1
                                                                                               / 24
                                                                                               * (FLOOR (
                                                                                                        (  SYSDATE
                                                                                                         - TRUNC (
                                                                                                               SYSDATE))
                                                                                                      * 24))
                                                                   AND (   NVL (
                                                                               UPPER (
                                                                                   aproval_status),
                                                                               '*') NOT LIKE
                                                                               'AUTO%'
                                                                        OR NVL (
                                                                               attribute1,
                                                                               v_no_flag) =
                                                                           v_yes_flag)))))
                                      OR (    approved_date >
                                                TRUNC (SYSDATE)
                                              +   1
                                                / 24
                                                * (  FLOOR (
                                                           (  SYSDATE
                                                            - TRUNC (SYSDATE))
                                                         * 24)
                                                   - 1)
                                          AND approved_date <=
                                                TRUNC (SYSDATE)
                                              +   1
                                                / 24
                                                * (FLOOR (
                                                         (  SYSDATE
                                                          - TRUNC (SYSDATE))
                                                       * 24))))
                                 AND (   NVL (UPPER (aproval_status), '*') NOT LIKE
                                             'AUTO%'
                                      OR NVL (attribute1, v_no_flag) =
                                         v_yes_flag)) --Added by sabanda for US157355
                ORDER BY process_status DESC,
                         requested_date DESC,
                         requested_by)
        LOOP
            IF lv_req_recipients IS NULL
            THEN
                lv_req_recipients := rec.requested_by;
            ELSE
                lv_req_recipients :=
                    lv_req_recipients || ',' || rec.requested_by;
            END IF;

            IF     lv_proc_recipients IS NULL
               AND rec.approved_by IS NOT NULL
               AND NVL (UPPER (rec.aproval_status), '*') NOT LIKE 'AUTO%' --Added by sabanda for US157355
            THEN
                lv_proc_recipients := rec.approved_by;
                lv_approval_rec_flag := v_yes_flag; --Added by sabanda for US161611
            ELSIF     rec.approved_by IS NOT NULL
                  AND NVL (UPPER (rec.aproval_status), '*') NOT LIKE 'AUTO%' --Added by sabanda for US157355
            THEN
                lv_proc_recipients :=
                    lv_proc_recipients || ',' || rec.approved_by;
                lv_approval_rec_flag := v_yes_flag; --Added by sabanda for US161611
            END IF;

            IF MOD (lv_count_col, 2) = 0
            THEN
                lv_fve_msg_text :=
                       lv_fve_msg_text
                    || '<tr style="background-color: #dddddd">';
            ELSE
                lv_fve_msg_text := lv_fve_msg_text || '<tr>';
            END IF;

            lv_fve_msg_text :=
                   lv_fve_msg_text
                || '
                            <td>'
                || rec.REQUEST_ID
                || '</td><td nowrap>'
                || rec.PART_NUMBER
                || '</td><td nowrap>'
                || rec.TAN_ID
                || '</td><td nowrap>'
                || rec.TRANSACTION_TYPE
                || '-'
                || rec.FROM_PROGRAM_TYPE
                || '</td><td>'
                || rec.SITE_CODE
                || '</td><td>'
                || rec.ROHS_COMPLIANT_FLAG
                || '</td><td>'
                || rec.QTY_TO_TRANSFER
                || '</td><td>'
                || rec.QTY_TO_PROCESS
                || '</td><td nowrap>'
                || rec.REQUESTED_BY
                || '</td><td nowrap>'
                --|| rec.APROVAL_STATUS --Commented by satbanda for US161611
                || INITCAP (NVL (rec.APROVAL_STATUS, rec.PROCESS_STATUS)) --Added by satbanda for US161611
                || '</td><td nowrap>'
                || rec.COMMENTS
                || '</td><td nowrap>'
                || rec.APPROVER_COMMENTS
                || '</td><td nowrap>'
                || TO_CHAR (rec.REQUESTED_DATE, 'DD-Mon-YYYY HH:Mi:SS')
                || '</td><td nowrap>'
                || rec.APPROVED_BY
                || '</td><td nowrap>'
                || TO_CHAR (rec.APPROVED_DATE, 'DD-Mon-YYYY HH:Mi:SS')
                || '</td></tr>';


            lv_count_col := lv_count_col + 1;
        END LOOP;


        lv_fve_msg_text :=
               lv_fve_msg_text
            || '</table>'
            || '<br> '
            || ' It might take approximately an hour to update the inventory for Ordering.'
            || '<br> '
            || 'PLEASE DO NOT REPLY .. This is an Auto generated Email.'
            || ' </body> </html>';

        lv_msg_subject := NULL;

        IF lv_count_col > 0
        THEN
            lv_msg_subject :=
                   lv_tmsg_subject
                || 'FVE BTS Inventory Adjustment requests - '
                || lv_start_time;

            BEGIN
                SELECT email_sender, email_recipients
                  INTO lv_msg_from, lv_msg_to
                  FROM crpadm.rc_email_notifications
                 WHERE notification_name =
                       CASE
                           WHEN lv_database_name = 'FNTR2PRD.CISCO.COM'
                           THEN
                               --'INV_TRANS_ADJ_FVE_NOTIFY' --Commented by sabanda for US161611
                               DECODE (
                                   lv_approval_rec_flag,
                                   v_yes_flag, 'INV_TRANS_ADJ_FVE_NOTIFY',
                                   'INV_TRANS_ADJ_FVE_RNOTIFY') --Added by sabanda for US161611
                           WHEN lv_database_name = 'FNTR2STG.CISCO.COM'
                           THEN
                               'INV_TRANS_ADJ_STG_NOTIFY'
                           ELSE
                               'INV_TRANS_ADJ_DEV_NOTIFY'
                       END;
            EXCEPTION
                WHEN OTHERS
                THEN
                    lv_msg_from := lv_email_sender;
                    lv_msg_to := lv_email_sender;
            END;

            BEGIN
                --Added by satbanda for Multiple recipients issue <start>
                SELECT LISTAGG (participents, ',')
                           WITHIN GROUP (ORDER BY participents, ',')
                  INTO lv_req_recipients
                  FROM ( --Added by satbanda for Multiple recipients issue <End>
                            SELECT DISTINCT REGEXP_SUBSTR (lv_req_recipients,
                                                           '[^,]+',
                                                           1,
                                                           LEVEL)
                                                participents
                              -- INTO lv_req_recipients
                              FROM DUAL
                        CONNECT BY REGEXP_SUBSTR (lv_req_recipients,
                                                  '[^,]+',
                                                  1,
                                                  LEVEL)
                                       IS NOT NULL);
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;

            BEGIN
                --Added by satbanda for Multiple recipients issue <start>
                SELECT LISTAGG (participents, ',')
                           WITHIN GROUP (ORDER BY participents, ',')
                  INTO lv_proc_recipients
                  FROM ( --Added by satbanda for Multiple recipients issue <End>
                            SELECT DISTINCT REGEXP_SUBSTR (lv_proc_recipients,
                                                           '[^,]+',
                                                           1,
                                                           LEVEL)
                                                participents
                              --INTO lv_proc_recipients
                              FROM DUAL
                        CONNECT BY REGEXP_SUBSTR (lv_proc_recipients,
                                                  '[^,]+',
                                                  1,
                                                  LEVEL)
                                       IS NOT NULL);
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;

            IF     lv_req_recipients IS NOT NULL
               AND lv_proc_recipients IS NOT NULL
            THEN
                lv_msg_to :=
                       lv_req_recipients
                    || ','
                    || lv_proc_recipients
                    || ','
                    || lv_msg_to;
            ELSIF lv_req_recipients IS NOT NULL
            THEN
                lv_msg_to := lv_req_recipients || ',' || lv_msg_to;
            END IF;


            BEGIN
                crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (
                    lv_msg_from,
                    lv_msg_to,
                    lv_msg_subject,
                    lv_fve_msg_text,
                    NULL,                                       --lv_filename,
                    NULL                                           --lv_output
                        );
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_message := SUBSTR (SQLERRM, 1, 50);
            END;
        END IF;

        lv_count_col := 0;

        lv_dgi_msg_text :=
               '<HTML>'
            || '<br /><br /> '
            || ' GDGI Inventory Adjustment Requests given below.'
            || '<br /><br /> '
            || lv_msg_text;

        lv_req_recipients := NULL;

        lv_proc_recipients := NULL;

        lv_approval_rec_flag := v_no_flag;     --Added by sabanda for US161611

        FOR rec
            IN ( /* SELECT *
                  FROM rmktgadm.rmk_adminui_invtransfer
                 WHERE   */
                  /*  SELECT rpm.tan_id,rai.*
                     FROM rmktgadm.rmk_adminui_invtransfer rai,
                           crpadm.rc_product_master rpm
                    WHERE part_number=rpm.refresh_part_number AND
                                site_code = 'GDGI'
                          AND transaction_type = 'ADJUSTMENT'
                          AND (   (approved_date IS NULL
                                   AND requested_date>=SYSDATE-1/24)--Added by sabanda for US161611
                                --OR approved_date >= SYSDATE - (1 / 48)
                               OR (approved_date > TRUNC(SYSDATE)+1/24*(FLOOR((SYSDATE-TRUNC(SYSDATE))*24)-1) AND approved_date <= TRUNC(SYSDATE)+1/24*(FLOOR((SYSDATE-TRUNC(SYSDATE))*24)))
                               OR (approved_date IS NULL
                                  AND EXISTS (SELECT 1 FROM rmktgadm.rmk_adminui_invtransfer WHERE transaction_type = rai.transaction_type AND site_code=rai.site_code  AND approved_date > TRUNC(SYSDATE)+1/24*(FLOOR((SYSDATE-TRUNC(SYSDATE))*24)-1) AND approved_date <= TRUNC(SYSDATE)+1/24*(FLOOR((SYSDATE-TRUNC(SYSDATE))*24)))
                                  )
                               )
                          AND (NVL(UPPER(aproval_status),'*') NOT LIKE 'AUTO%'
                          OR NVL(attribute1,v_no_flag) = v_yes_flag) --Added by sabanda for US157355
                 ORDER BY process_status DESC, requested_date DESC, requested_by) */
                  SELECT *
                    FROM (SELECT rpm.tan_id,
                                 rai.REQUEST_ID,
                                 rai.PART_NUMBER,
                                 rai.TRANSACTION_TYPE,
                                 rai.FROM_PROGRAM_TYPE,
                                 rai.SITE_CODE,
                                 rai.ROHS_COMPLIANT_FLAG,
                                 rai.QTY_TO_TRANSFER,
                                 rai.QTY_TO_PROCESS,
                                 rai.REQUESTED_BY,
                                 CASE
                                     WHEN UPPER (rai.APROVAL_STATUS) LIKE
                                              'AUTO%'
                                     THEN
                                         'Approved'
                                     WHEN UPPER (rai.APROVAL_STATUS) LIKE
                                              'APPROVE%'
                                     THEN
                                         'Approved'
                                     ELSE
                                         INITCAP (rai.APROVAL_STATUS)
                                 END
                                     APROVAL_STATUS,
                                 INITCAP (rai.PROCESS_STATUS)
                                     PROCESS_STATUS,
                                 rai.COMMENTS,
                                 rai.APPROVER_COMMENTS,
                                 rai.REQUESTED_DATE,
                                 rai.APPROVED_BY,
                                 rai.APPROVED_DATE
                            FROM rmktgadm.rmk_adminui_invtransfer rai,
                                 crpadm.rc_product_master        rpm
                           WHERE     part_number = rpm.refresh_part_number
                                 AND site_code = 'GDGI'
                                 AND transaction_type = 'ADJUSTMENT'
                                 AND (   (    approved_date IS NULL
                                          AND EXISTS
                                                  (SELECT 1
                                                     FROM rmktgadm.rmk_adminui_invtransfer
                                                    WHERE     transaction_type =
                                                              rai.transaction_type
                                                          AND site_code =
                                                              rai.site_code
                                                          AND (   requested_date BETWEEN   TRUNC (
                                                                                               SYSDATE)
                                                                                         +   1
                                                                                           / 24
                                                                                           * (  FLOOR (
                                                                                                      (  SYSDATE
                                                                                                       - TRUNC (
                                                                                                             SYSDATE))
                                                                                                    * 24)
                                                                                              - 1)
                                                                                     AND   TRUNC (
                                                                                               SYSDATE)
                                                                                         +   1
                                                                                           / 24
                                                                                           * (FLOOR (
                                                                                                    (  SYSDATE
                                                                                                     - TRUNC (
                                                                                                           SYSDATE))
                                                                                                  * 24))
                                                               OR (    approved_date BETWEEN   TRUNC (
                                                                                                   SYSDATE)
                                                                                             +   1
                                                                                               / 24
                                                                                               * (  FLOOR (
                                                                                                          (  SYSDATE
                                                                                                           - TRUNC (
                                                                                                                 SYSDATE))
                                                                                                        * 24)
                                                                                                  - 1)
                                                                                         AND   TRUNC (
                                                                                                   SYSDATE)
                                                                                             +   1
                                                                                               / 24
                                                                                               * (FLOOR (
                                                                                                        (  SYSDATE
                                                                                                         - TRUNC (
                                                                                                               SYSDATE))
                                                                                                      * 24))
                                                                   AND (   NVL (
                                                                               UPPER (
                                                                                   aproval_status),
                                                                               '*') NOT LIKE
                                                                               'AUTO%'
                                                                        OR NVL (
                                                                               attribute1,
                                                                               v_no_flag) =
                                                                           v_yes_flag)))))
                                      OR (    approved_date >
                                                TRUNC (SYSDATE)
                                              +   1
                                                / 24
                                                * (  FLOOR (
                                                           (  SYSDATE
                                                            - TRUNC (SYSDATE))
                                                         * 24)
                                                   - 1)
                                          AND approved_date <=
                                                TRUNC (SYSDATE)
                                              +   1
                                                / 24
                                                * (FLOOR (
                                                         (  SYSDATE
                                                          - TRUNC (SYSDATE))
                                                       * 24))))
                                 AND (   NVL (UPPER (aproval_status), '*') NOT LIKE
                                             'AUTO%'
                                      OR NVL (attribute1, v_no_flag) =
                                         v_yes_flag)) --Added by sabanda for US157355
                ORDER BY process_status DESC,
                         requested_date DESC,
                         requested_by)
        LOOP
            IF lv_req_recipients IS NULL
            THEN
                lv_req_recipients := rec.requested_by;
            ELSE
                lv_req_recipients :=
                    lv_req_recipients || ',' || rec.requested_by;
            END IF;

            IF     lv_proc_recipients IS NULL
               AND rec.approved_by IS NOT NULL
               AND NVL (UPPER (rec.aproval_status), '*') NOT LIKE 'AUTO%' --Added by sabanda for US157355
            THEN
                lv_proc_recipients := rec.approved_by;
                lv_approval_rec_flag := v_yes_flag; --Added by sabanda for US161611
            ELSIF     rec.approved_by IS NOT NULL
                  AND NVL (UPPER (rec.aproval_status), '*') NOT LIKE 'AUTO%' --Added by sabanda for US157355
            THEN
                lv_proc_recipients :=
                    lv_proc_recipients || ',' || rec.approved_by;
                lv_approval_rec_flag := v_yes_flag; --Added by sabanda for US161611
            END IF;

            IF MOD (lv_count_col, 2) = 0
            THEN
                lv_dgi_msg_text :=
                       lv_dgi_msg_text
                    || '<tr style="background-color: #dddddd">';
            ELSE
                lv_dgi_msg_text := lv_dgi_msg_text || '<tr>';
            END IF;

            lv_dgi_msg_text :=
                   lv_dgi_msg_text
                || '
                            <td>'
                || rec.REQUEST_ID
                || '</td><td nowrap>'
                || rec.PART_NUMBER
                || '</td><td nowrap>'
                || rec.TAN_ID
                || '</td><td nowrap>'
                || rec.TRANSACTION_TYPE
                || '-'
                || rec.FROM_PROGRAM_TYPE
                || '</td><td>'
                || rec.SITE_CODE
                || '</td><td>'
                || rec.ROHS_COMPLIANT_FLAG
                || '</td><td>'
                || rec.QTY_TO_TRANSFER
                || '</td><td>'
                || rec.QTY_TO_PROCESS
                || '</td><td nowrap>'
                || rec.REQUESTED_BY
                || '</td><td nowrap>'
                --|| rec.APROVAL_STATUS --Commented by satbanda for US161611
                || INITCAP (NVL (rec.APROVAL_STATUS, rec.PROCESS_STATUS)) --Added by satbanda for US161611
                || '</td><td nowrap>'
                || rec.COMMENTS
                || '</td><td nowrap>'
                || rec.APPROVER_COMMENTS
                || '</td><td nowrap>'
                || TO_CHAR (rec.REQUESTED_DATE, 'DD-Mon-YYYY HH:Mi:SS')
                || '</td><td nowrap>'
                || rec.APPROVED_BY
                || '</td><td nowrap>'
                || TO_CHAR (rec.APPROVED_DATE, 'DD-Mon-YYYY HH:Mi:SS')
                || '</td></tr>';


            lv_count_col := lv_count_col + 1;
        END LOOP;


        lv_dgi_msg_text :=
               lv_dgi_msg_text
            || '</table> '
            || '<br> '
            || ' It might take approximately an hour to update the inventory for Ordering.'
            || '<br> '
            || 'PLEASE DO NOT REPLY .. This is an Auto generated Email.'
            || '</body> </html>';

        lv_msg_subject := NULL;

        IF lv_count_col > 0
        THEN
            lv_msg_subject :=
                   lv_tmsg_subject
                || 'GDGI Inventory Adjustment requests - '
                || lv_start_time;

            BEGIN
                SELECT email_sender, email_recipients
                  INTO lv_msg_from, lv_msg_to
                  FROM crpadm.rc_email_notifications
                 WHERE notification_name =
                       CASE
                           WHEN lv_database_name = 'FNTR2PRD.CISCO.COM'
                           THEN
                               'INV_TRANS_ADJ_DGI_NOTIFY'
                           WHEN lv_database_name = 'FNTR2STG.CISCO.COM'
                           THEN
                               'INV_TRANS_ADJ_STG_NOTIFY'
                           ELSE
                               'INV_TRANS_ADJ_DEV_NOTIFY'
                       END;
            EXCEPTION
                WHEN OTHERS
                THEN
                    lv_msg_from := lv_email_sender;
                    lv_msg_to := lv_email_sender;
            END;

            BEGIN
                --Added by satbanda for Multiple recipients issue <start>
                SELECT LISTAGG (participents, ',')
                           WITHIN GROUP (ORDER BY participents, ',')
                  INTO lv_req_recipients
                  FROM ( --Added by satbanda for Multiple recipients issue <End>
                            SELECT DISTINCT REGEXP_SUBSTR (lv_req_recipients,
                                                           '[^,]+',
                                                           1,
                                                           LEVEL)
                                                participents
                              --INTO lv_req_recipients
                              FROM DUAL
                        CONNECT BY REGEXP_SUBSTR (lv_req_recipients,
                                                  '[^,]+',
                                                  1,
                                                  LEVEL)
                                       IS NOT NULL);
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;

            BEGIN
                --Added by satbanda for Multiple recipients issue <start>
                SELECT LISTAGG (participents, ',')
                           WITHIN GROUP (ORDER BY participents, ',')
                  INTO lv_proc_recipients
                  FROM ( --Added by satbanda for Multiple recipients issue <End>
                            SELECT DISTINCT REGEXP_SUBSTR (lv_proc_recipients,
                                                           '[^,]+',
                                                           1,
                                                           LEVEL)
                                                participents
                              --   INTO lv_proc_recipients
                              FROM DUAL
                        CONNECT BY REGEXP_SUBSTR (lv_proc_recipients,
                                                  '[^,]+',
                                                  1,
                                                  LEVEL)
                                       IS NOT NULL);
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;

            IF     lv_req_recipients IS NOT NULL
               AND lv_proc_recipients IS NOT NULL
            THEN
                lv_msg_to :=
                       lv_req_recipients
                    || ','
                    || lv_proc_recipients
                    || ','
                    || lv_msg_to;
            ELSIF lv_req_recipients IS NOT NULL
            THEN
                lv_msg_to := lv_req_recipients || ',' || lv_msg_to;
            END IF;


            BEGIN
                crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (
                    lv_msg_from,
                    lv_msg_to,
                    lv_msg_subject,
                    lv_dgi_msg_text,
                    NULL,                                       --lv_filename,
                    NULL                                           --lv_output
                        );
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_message := SUBSTR (SQLERRM, 1, 50);
            END;
        END IF;

        lv_count_col := 0;

        lv_trn_msg_text :=
               '<HTML>'
            || '<br /><br /> '
            || ' BTS Inventory Transfer Requests given below.'
            || '<br /><br /> '
            || lv_msg_text;

        lv_req_recipients := NULL;

        lv_proc_recipients := NULL;

        lv_approval_rec_flag := v_no_flag;     --Added by sabanda for US161611

        FOR rec
            IN ( /* SELECT *
                   FROM rmktgadm.rmk_adminui_invtransfer
                  WHERE   */
                  /* SELECT rpm.tan_id,rai.*
                    FROM rmktgadm.rmk_adminui_invtransfer rai,
                          crpadm.rc_product_master rpm
                   WHERE part_number=rpm.refresh_part_number AND
                             transaction_type != 'ADJUSTMENT'
                         AND (   (approved_date IS NULL
                                  AND requested_date>=SYSDATE-1/24)--Added by sabanda for US161611
                               --OR approved_date >= SYSDATE - (1 / 48)
                              OR (approved_date > TRUNC(SYSDATE)+1/24*(FLOOR((SYSDATE-TRUNC(SYSDATE))*24)-1) AND approved_date <= TRUNC(SYSDATE)+1/24*(FLOOR((SYSDATE-TRUNC(SYSDATE))*24)))
                              OR (approved_date IS NULL
                                 AND EXISTS (SELECT 1 FROM rmktgadm.rmk_adminui_invtransfer WHERE transaction_type != 'ADJUSTMENT' AND approved_date > TRUNC(SYSDATE)+1/24*(FLOOR((SYSDATE-TRUNC(SYSDATE))*24)-1) AND approved_date <= TRUNC(SYSDATE)+1/24*(FLOOR((SYSDATE-TRUNC(SYSDATE))*24)))
                                 )
                                 )
                         AND (NVL(UPPER(aproval_status),'*') NOT LIKE 'AUTO%'
                         OR NVL(attribute1,v_no_flag) = v_yes_flag) --Added by sabanda for US157355
                ORDER BY process_status DESC, requested_date DESC, requested_by) */
                  SELECT *
                    FROM (SELECT rpm.tan_id,
                                 rai.REQUEST_ID,
                                 rai.PART_NUMBER,
                                 rai.TRANSACTION_TYPE,
                                 rai.FROM_PROGRAM_TYPE,
                                 rai.SITE_CODE,
                                 rai.ROHS_COMPLIANT_FLAG,
                                 rai.QTY_TO_TRANSFER,
                                 rai.QTY_TO_PROCESS,
                                 rai.REQUESTED_BY,
                                 CASE
                                     WHEN UPPER (rai.APROVAL_STATUS) LIKE
                                              'AUTO%'
                                     THEN
                                         'Approved'
                                     WHEN UPPER (rai.APROVAL_STATUS) LIKE
                                              'APPROVE%'
                                     THEN
                                         'Approved'
                                     ELSE
                                         INITCAP (rai.APROVAL_STATUS)
                                 END
                                     APROVAL_STATUS,
                                 INITCAP (rai.PROCESS_STATUS)
                                     PROCESS_STATUS,
                                 rai.COMMENTS,
                                 rai.APPROVER_COMMENTS,
                                 rai.REQUESTED_DATE,
                                 rai.APPROVED_BY,
                                 rai.APPROVED_DATE
                            FROM rmktgadm.rmk_adminui_invtransfer rai,
                                 crpadm.rc_product_master        rpm
                           WHERE     part_number = rpm.refresh_part_number
                                 AND --                           transaction_type != 'ADJUSTMENT'
                                     transaction_type NOT IN
                                         ('ADJUSTMENT', 'DGI-TRANSFER')
                                 AND (   (    approved_date IS NULL
                                          AND EXISTS
                                                  (SELECT 1
                                                     FROM rmktgadm.rmk_adminui_invtransfer
                                                    WHERE     transaction_type NOT IN
                                                                  ('ADJUSTMENT',
                                                                   'DGI-TRANSFER') -- transaction_type != 'ADJUSTMENT'
                                                          AND (   requested_date BETWEEN   TRUNC (
                                                                                               SYSDATE)
                                                                                         +   1
                                                                                           / 24
                                                                                           * (  FLOOR (
                                                                                                      (  SYSDATE
                                                                                                       - TRUNC (
                                                                                                             SYSDATE))
                                                                                                    * 24)
                                                                                              - 1)
                                                                                     AND   TRUNC (
                                                                                               SYSDATE)
                                                                                         +   1
                                                                                           / 24
                                                                                           * (FLOOR (
                                                                                                    (  SYSDATE
                                                                                                     - TRUNC (
                                                                                                           SYSDATE))
                                                                                                  * 24))
                                                               OR (    approved_date BETWEEN   TRUNC (
                                                                                                   SYSDATE)
                                                                                             +   1
                                                                                               / 24
                                                                                               * (  FLOOR (
                                                                                                          (  SYSDATE
                                                                                                           - TRUNC (
                                                                                                                 SYSDATE))
                                                                                                        * 24)
                                                                                                  - 1)
                                                                                         AND   TRUNC (
                                                                                                   SYSDATE)
                                                                                             +   1
                                                                                               / 24
                                                                                               * (FLOOR (
                                                                                                        (  SYSDATE
                                                                                                         - TRUNC (
                                                                                                               SYSDATE))
                                                                                                      * 24))
                                                                   AND (   NVL (
                                                                               UPPER (
                                                                                   aproval_status),
                                                                               '*') NOT LIKE
                                                                               'AUTO%'
                                                                        OR NVL (
                                                                               attribute1,
                                                                               v_no_flag) =
                                                                           v_yes_flag)))))
                                      OR (    approved_date >
                                                TRUNC (SYSDATE)
                                              +   1
                                                / 24
                                                * (  FLOOR (
                                                           (  SYSDATE
                                                            - TRUNC (SYSDATE))
                                                         * 24)
                                                   - 1)
                                          AND approved_date <=
                                                TRUNC (SYSDATE)
                                              +   1
                                                / 24
                                                * (FLOOR (
                                                         (  SYSDATE
                                                          - TRUNC (SYSDATE))
                                                       * 24))))
                                 AND (   NVL (UPPER (aproval_status), '*') NOT LIKE
                                             'AUTO%'
                                      OR NVL (attribute1, v_no_flag) =
                                         v_yes_flag)) --Added by sabanda for US157355
                ORDER BY process_status DESC,
                         requested_date DESC,
                         requested_by)
        LOOP
            IF lv_req_recipients IS NULL
            THEN
                lv_req_recipients := rec.requested_by;
            ELSE
                lv_req_recipients :=
                    lv_req_recipients || ',' || rec.requested_by;
            END IF;

            IF     lv_proc_recipients IS NULL
               AND rec.approved_by IS NOT NULL
               AND NVL (UPPER (rec.aproval_status), '*') NOT LIKE 'AUTO%' --Added by sabanda for US157355
            THEN
                lv_proc_recipients := rec.approved_by;
                lv_approval_rec_flag := v_yes_flag; --Added by sabanda for US161611
            ELSIF     rec.approved_by IS NOT NULL
                  AND NVL (UPPER (rec.aproval_status), '*') NOT LIKE 'AUTO%' --Added by sabanda for US157355
            THEN
                lv_proc_recipients :=
                    lv_proc_recipients || ',' || rec.approved_by;
                lv_approval_rec_flag := v_yes_flag; --Added by sabanda for US161611
            END IF;

            IF MOD (lv_count_col, 2) = 0
            THEN
                lv_trn_msg_text :=
                       lv_trn_msg_text
                    || '<tr style="background-color: #dddddd">';
            ELSE
                lv_trn_msg_text := lv_trn_msg_text || '<tr>';
            END IF;

            lv_trn_msg_text :=
                   lv_trn_msg_text
                || '
                            <td>'
                || rec.REQUEST_ID
                || '</td><td nowrap>'
                || rec.PART_NUMBER
                || '</td><td nowrap>'
                || rec.TAN_ID
                || '</td><td nowrap>'
                || rec.TRANSACTION_TYPE
                || '</td><td>'
                || rec.SITE_CODE
                || '</td><td>'
                || rec.ROHS_COMPLIANT_FLAG
                || '</td><td>'
                || rec.QTY_TO_TRANSFER
                || '</td><td>'
                || rec.QTY_TO_PROCESS
                || '</td><td nowrap>'
                || rec.REQUESTED_BY
                || '</td><td nowrap>'
                --|| rec.APROVAL_STATUS --Commented by satbanda for US161611
                || INITCAP (NVL (rec.APROVAL_STATUS, rec.PROCESS_STATUS)) --Added by satbanda for US161611
                || '</td><td nowrap>'
                || rec.COMMENTS
                || '</td><td nowrap>'
                || rec.APPROVER_COMMENTS
                || '</td><td nowrap>'
                || TO_CHAR (rec.REQUESTED_DATE, 'DD-Mon-YYYY HH:Mi:SS')
                || '</td><td nowrap>'
                || rec.APPROVED_BY
                || '</td><td nowrap>'
                || TO_CHAR (rec.APPROVED_DATE, 'DD-Mon-YYYY HH:Mi:SS')
                || '</td></tr>';

            lv_count_col := lv_count_col + 1;
        END LOOP;


        lv_trn_msg_text :=
               lv_trn_msg_text
            || '</table> '
            || '<br> '
            || ' It might take approximately an hour to update the inventory for Ordering.'
            || '<br> '
            || 'PLEASE DO NOT REPLY .. This is an Auto generated Email.'
            || '</body> </html>';
        lv_msg_subject := NULL;

        IF lv_count_col > 0
        THEN
            lv_msg_subject :=
                   lv_tmsg_subject
                || 'BTS Inventory Transfer requests - '
                || lv_start_time;

            BEGIN
                SELECT email_sender, email_recipients
                  INTO lv_msg_from, lv_msg_to
                  FROM crpadm.rc_email_notifications
                 WHERE notification_name =
                       CASE
                           WHEN lv_database_name = 'FNTR2PRD.CISCO.COM'
                           THEN
                               'INV_TRANS_ADJ_RO_NOTIFY'
                           WHEN lv_database_name = 'FNTR2STG.CISCO.COM'
                           THEN
                               'INV_TRANS_ADJ_STG_NOTIFY'
                           ELSE
                               'INV_TRANS_ADJ_DEV_NOTIFY'
                       END;
            EXCEPTION
                WHEN OTHERS
                THEN
                    lv_msg_from := lv_email_sender;
                    lv_msg_to := lv_email_sender;
            END;

            BEGIN
                --Added by satbanda for Multiple recipients issue <start>
                SELECT LISTAGG (participents, ',')
                           WITHIN GROUP (ORDER BY participents, ',')
                  INTO lv_req_recipients
                  FROM ( --Added by satbanda for Multiple recipients issue <End>
                            SELECT DISTINCT REGEXP_SUBSTR (lv_req_recipients,
                                                           '[^,]+',
                                                           1,
                                                           LEVEL)
                                                participents
                              --    INTO lv_req_recipients
                              FROM DUAL
                        CONNECT BY REGEXP_SUBSTR (lv_req_recipients,
                                                  '[^,]+',
                                                  1,
                                                  LEVEL)
                                       IS NOT NULL);
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;

            BEGIN
                --Added by satbanda for Multiple recipients issue <start>
                SELECT LISTAGG (participents, ',')
                           WITHIN GROUP (ORDER BY participents, ',')
                  INTO lv_proc_recipients
                  FROM ( --Added by satbanda for Multiple recipients issue <End>
                            SELECT DISTINCT REGEXP_SUBSTR (lv_proc_recipients,
                                                           '[^,]+',
                                                           1,
                                                           LEVEL)
                                                participents
                              -- INTO lv_proc_recipients
                              FROM DUAL
                        CONNECT BY REGEXP_SUBSTR (lv_proc_recipients,
                                                  '[^,]+',
                                                  1,
                                                  LEVEL)
                                       IS NOT NULL);
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;

            IF     lv_req_recipients IS NOT NULL
               AND lv_proc_recipients IS NOT NULL
            THEN
                lv_msg_to :=
                       lv_req_recipients
                    || ','
                    || lv_proc_recipients
                    || ','
                    || lv_msg_to;
            ELSIF lv_req_recipients IS NOT NULL
            THEN
                lv_msg_to := lv_req_recipients || ',' || lv_msg_to;
            END IF;


            BEGIN
                crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (
                    lv_msg_from,
                    lv_msg_to,
                    lv_msg_subject,
                    lv_trn_msg_text,
                    NULL,                                       --lv_filename,
                    NULL                                           --lv_output
                        );
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_message := SUBSTR (SQLERRM, 1, 50);
            END;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            v_message := SUBSTR (SQLERRM, 1, 200);

            P_RCEC_ERROR_LOG (
                I_module_name =>
                    'P_INV_TRANSFER',
                I_entity_name =>
                    NULL,
                I_entity_id =>
                    NULL,
                I_ext_entity_name =>
                    NULL,
                I_ext_entity_id =>
                    NULL,
                I_error_type =>
                    'EXCEPTION',
                i_Error_Message =>
                       'Error getting while executing RC_INV_TRANS_NOTIFY_MAIL '
                    || v_message
                    || ' LineNo=> '
                    || DBMS_UTILITY.Format_error_backtrace,
                I_created_by =>
                    'P_INV_TRANSFER',
                I_updated_by =>
                    'P_INV_TRANSFER');
    END RC_INV_TRANS_NOTIFY_MAIL;

    -- Added for US137794 - Inventory Utility Email notifications <End>


    -- Added as part of US161611 by sridvasu - Updating 'Addtional_Comments' column <Start>

    PROCEDURE P_INV_COMMENTS_UPDATE (
        i_additional_comments_tab   IN T_REQ_ID_COMMENTS_TAB,
        i_user_id                   IN VARCHAR2)
    AS
        lv_additional_comments_tab   T_REQ_ID_COMMENTS_TAB
                                         := T_REQ_ID_COMMENTS_TAB ();
        lv_user_id                   VARCHAR2 (2000);
    BEGIN
        lv_user_id := i_user_id;
        lv_additional_comments_tab := i_additional_comments_tab;

        FOR rec IN lv_additional_comments_tab.FIRST ..
                   lv_additional_comments_tab.LAST
        LOOP
            UPDATE RMK_ADMINUI_INVTRANSFER
               SET ADDITIONAL_COMMENTS =
                       lv_additional_comments_tab (rec).additional_comments,
                   LAST_UPDATED_BY = lv_user_id,
                   LAST_UPDATED_DATE = SYSDATE
             WHERE REQUEST_ID = lv_additional_comments_tab (rec).request_id;
        END LOOP;

        COMMIT;
    END P_INV_COMMENTS_UPDATE;

    -- Added as part of US161611 by sridvasu - Updating 'Addtional_Comments' column <End>

    FUNCTION f_get_outletelg_flag (i_part_number VARCHAR2, i_mos NUMBER)
        RETURN VARCHAR2
    IS
        l_rec_count          NUMBER;

        l_outletelgbl_flag   VARCHAR2 (1);
    BEGIN
        SELECT COUNT (ROWID)
          INTO l_rec_count
          FROM crpadm.rc_product_master pm
         WHERE     PM.REFRESH_PART_NUMBER = i_part_number
               AND PM.PROGRAM_TYPE =
                   (SELECT RIC.RC_INV_CONTROL_VALUE
                      FROM RMKTGADM.RC_INV_CONTROL RIC
                     WHERE     RIC.RC_INV_CONTROL_NAME = 'RETAIL'
                           AND RIC.RC_INV_CONTROL_FLAG = 'Y')
               AND NVL (i_mos, 0) NOT BETWEEN (SELECT RIC_SUB.RC_INV_CONTROL_VALUE
                                                 FROM RMKTGADM.RC_INV_CONTROL
                                                      RIC_SUB
                                                WHERE     RIC_SUB.RC_INV_CONTROL_NAME =
                                                          'MIN MOS'
                                                      AND RIC_SUB.RC_INV_CONTROL_FLAG =
                                                          'Y')
                                          AND (SELECT RIC_SUB1.RC_INV_CONTROL_VALUE
                                                 FROM RMKTGADM.RC_INV_CONTROL
                                                      RIC_SUB1
                                                WHERE     RIC_SUB1.RC_INV_CONTROL_NAME =
                                                          'MAX MOS'
                                                      AND RIC_SUB1.RC_INV_CONTROL_FLAG =
                                                          'Y') -- -- Include PIDs that have over 6 months supply of (Inclusive of) FGI and DGI
               AND TRUNC (PM.NPI_CREATION_DATE) <
                     TRUNC (SYSDATE)
                   - (SELECT RIC_NPI.RC_INV_CONTROL_VALUE
                        FROM RMKTGADM.RC_INV_CONTROL RIC_NPI
                       WHERE     RIC_NPI.RC_INV_CONTROL_NAME = 'PRODUCT AGE'
                             AND RIC_NPI.RC_INV_CONTROL_FLAG = 'Y');

        l_outletelgbl_flag := 'N';

        IF l_rec_count > 0
        THEN
            l_outletelgbl_flag := 'Y';
        ELSE
            l_outletelgbl_flag := 'N';
        END IF;

        RETURN l_outletelgbl_flag;
    EXCEPTION
        WHEN OTHERS
        THEN
            l_outletelgbl_flag := NULL;

            v_message := SUBSTR (SQLERRM, 1, 200);

            P_RCEC_ERROR_LOG (
                I_module_name =>
                    'F_GET_OUTLETELG_FLAG',
                I_entity_name =>
                    'Part_number' || '->' || i_part_number,
                I_entity_id =>
                    NULL,
                I_ext_entity_name =>
                    NULL,
                I_ext_entity_id =>
                    NULL,
                I_error_type =>
                    'EXCEPTION',
                i_Error_Message =>
                       'Error getting while executing f_get_outletelg_flag  for following PID: '
                    || i_part_number
                    || ' <> '
                    || v_message
                    || ' LineNo=> '
                    || DBMS_UTILITY.Format_error_backtrace,
                I_created_by =>
                    NULL,
                I_updated_by =>
                    NULL);
    END f_get_outletelg_flag;

    FUNCTION f_get_pending_flag (i_part_number       VARCHAR2,
                                 i_location          VARCHAR2,
                                 i_rohs_compliant    VARCHAR2)
        RETURN VARCHAR2
    IS
        l_rec_count            NUMBER := 0;

        l_pending_trans_flag   VARCHAR2 (1) := 'N';
    BEGIN
        --check the PID wheather it has pending any transaction or incomplete process
        BEGIN
            SELECT COUNT (1)
              INTO l_rec_count
              FROM rmk_adminui_invtransfer
             WHERE     part_number = i_part_number
                   AND site_code = i_location
                   AND rohs_compliant_flag = i_rohs_compliant
                   AND NVL (UPPER (APROVAL_STATUS), '*') != v_rejected
                   AND (   approved_date IS NULL
                        OR approved_date >= SYSDATE - (1 / 24));
        EXCEPTION
            WHEN OTHERS
            THEN
                v_message := SUBSTR (SQLERRM, 1, 200);

                P_RCEC_ERROR_LOG (
                    I_module_name =>
                        'F_GET_PENDING_FLAG',
                    I_entity_name =>
                        'Part_number' || '->' || i_part_number,
                    I_entity_id =>
                        NULL,
                    I_ext_entity_name =>
                        NULL,
                    I_ext_entity_id =>
                        NULL,
                    I_error_type =>
                        'EXCEPTION',
                    i_Error_Message =>
                           'Error getting while fetching pending transaction for following PID: '
                        || i_part_number
                        || ', Location: '
                        || i_location
                        || ' <> '
                        || v_message
                        || ' LineNo=> '
                        || DBMS_UTILITY.Format_error_backtrace,
                    I_created_by =>
                        NULL,
                    I_updated_by =>
                        NULL);
        END;

        IF l_rec_count > 0
        THEN
            l_pending_trans_flag := 'Y';
        ELSE
            BEGIN
                SELECT COUNT (1)
                  INTO l_rec_count
                  FROM XXCPO_RMK_INVENTORY_MASTER a
                 WHERE     part_number = i_part_number
                       AND site_code = i_location
                       AND rohs_compliant = i_rohs_compliant
                       AND DECODE (site_code, 'GDGI', new_dgi, new_fgi) > 0;
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_message := SUBSTR (SQLERRM, 1, 200);

                    P_RCEC_ERROR_LOG (
                        I_module_name =>
                            'F_GET_PENDING_FLAG',
                        I_entity_name =>
                            'Part_number' || '->' || i_part_number,
                        I_entity_id =>
                            NULL,
                        I_ext_entity_name =>
                            NULL,
                        I_ext_entity_id =>
                            NULL,
                        I_error_type =>
                            'EXCEPTION',
                        i_Error_Message =>
                               'Error getting while fetching incomplete NEW FGI/DGI attributes for following PID: '
                            || i_part_number
                            || ', Location: '
                            || i_location
                            || ' <> '
                            || v_message
                            || ' LineNo=> '
                            || DBMS_UTILITY.Format_error_backtrace,
                        I_created_by =>
                            NULL,
                        I_updated_by =>
                            NULL);
            END;

            IF l_rec_count > 0
            THEN
                l_pending_trans_flag := 'Y';
            ELSE
                l_pending_trans_flag := 'N';
            END IF;
        END IF;

        RETURN l_pending_trans_flag;
    EXCEPTION
        WHEN OTHERS
        THEN
            l_pending_trans_flag := NULL;

            v_message := SUBSTR (SQLERRM, 1, 200);

            P_RCEC_ERROR_LOG (
                I_module_name =>
                    'F_GET_PENDING_FLAG',
                I_entity_name =>
                    'Part_number' || '->' || i_part_number,
                I_entity_id =>
                    NULL,
                I_ext_entity_name =>
                    NULL,
                I_ext_entity_id =>
                    NULL,
                I_error_type =>
                    'EXCEPTION',
                i_Error_Message =>
                       'Error getting while executing f_get_outletelg_flag  for following PID: '
                    || i_part_number
                    || ' <> '
                    || v_message
                    || ' LineNo=> '
                    || DBMS_UTILITY.Format_error_backtrace,
                I_created_by =>
                    NULL,
                I_updated_by =>
                    NULL);
    END f_get_pending_flag;

    /* Start added as part of DGI Transfer changes to get site codes in Advanced filter on 14-Jun-2019 */
    PROCEDURE P_RC_INV_SITE_CODE (
        o_rc_inv_site_code        OUT NOCOPY RC_INV_SITE_CODE_TAB,
        o_rc_inv_from_subinv      OUT NOCOPY RC_INV_FROM_SUBINV_TAB,
        o_rc_inv_to_subinv        OUT NOCOPY RC_INV_TO_SUBINV_TAB)
    IS
        lv_rc_inv_site_code     RC_INV_SITE_CODE_TAB := RC_INV_SITE_CODE_TAB ();
        lv_rc_inv_from_subinv   RC_INV_FROM_SUBINV_TAB
                                    := RC_INV_FROM_SUBINV_TAB ();
        lv_rc_inv_to_subinv     RC_INV_TO_SUBINV_TAB
                                    := RC_INV_TO_SUBINV_TAB ();
    BEGIN
        BEGIN
            SELECT RC_INV_SITE_CODE_OBJ (SITE_CODE)
              BULK COLLECT INTO lv_rc_inv_site_code
              FROM (  SELECT DISTINCT SITE_CODE
                        FROM RMK_ADMINUI_INVTRANSFER
                    ORDER BY SITE_CODE);

            SELECT RC_INV_FROM_SUBINV_OBJ (FROM_SUBINV)
              BULK COLLECT INTO lv_rc_inv_from_subinv
              FROM (  SELECT DISTINCT FROM_SUBINV
                        FROM RMK_ADMINUI_INVTRANSFER
                       WHERE FROM_SUBINV IS NOT NULL
                    ORDER BY FROM_SUBINV);

            SELECT RC_INV_TO_SUBINV_OBJ (TO_SUBINV)
              BULK COLLECT INTO lv_rc_inv_to_subinv
              FROM (  SELECT DISTINCT TO_SUBINV
                        FROM RMK_ADMINUI_INVTRANSFER
                       WHERE TO_SUBINV IS NOT NULL
                    ORDER BY TO_SUBINV);
        EXCEPTION
            WHEN OTHERS
            THEN
                v_message := SUBSTR (SQLERRM, 1, 200);
                DBMS_OUTPUT.put_line (v_message);
        END;

        o_rc_inv_site_code := lv_rc_inv_site_code;

        o_rc_inv_from_subinv := lv_rc_inv_from_subinv;

        o_rc_inv_to_subinv := lv_rc_inv_to_subinv;
    EXCEPTION
        WHEN OTHERS
        THEN
            v_message := SUBSTR (SQLERRM, 1, 2000);

            P_RCEC_ERROR_LOG (
                I_module_name =>
                    'P_RC_INV_SITE_CODE',
                I_entity_name =>
                    NULL,
                I_entity_id =>
                    NULL,
                I_ext_entity_name =>
                    NULL,
                I_ext_entity_id =>
                    NULL,
                I_error_type =>
                    'EXCEPTION',
                I_Error_Message =>
                       'Error getting while getting Site codes or From Subinv or To Subinv'
                    || ' <> '
                    || v_message
                    || ' LineNo=> '
                    || DBMS_UTILITY.Format_error_backtrace,
                I_created_by =>
                    'P_RC_INV_SITE_CODE',
                I_updated_by =>
                    'P_RC_INV_SITE_CODE');
    END P_RC_INV_SITE_CODE;

    /* End added as part of DGI Transfer changes to get site codes in Advanced filter on 14-Jun-2019 */

    /* Start added as part of DGI Transfer changes to validate To subinventory and Adjustment qty on 14-Jun-2019 */
    PROCEDURE P_TO_SUBINV_ADJ_QTY_VALIDATION (
        i_c3_onhand_qty                 NUMBER,
        i_to_subinv                     VARCHAR2,
        i_adj_qty                       NUMBER,
        o_message            OUT NOCOPY VARCHAR2)
    AS
        lv_count                 NUMBER;
        lv_subinv_status         VARCHAR2 (100);
        lv_adj_qty_status        VARCHAR2 (100);
        o_subinv_error_message   VARCHAR2 (100);
        o_adj_qty_message        VARCHAR2 (100);
        lv_adj_qty_msg           VARCHAR2 (100);
        lv_subinv_msg            VARCHAR2 (100);
    BEGIN
        IF i_adj_qty <> 0
        THEN
            IF i_to_subinv IS NULL AND i_adj_qty IS NOT NULL
            THEN
                IF i_adj_qty <= i_c3_onhand_qty
                THEN
                    lv_adj_qty_status := 'SUCCESS';
                ELSE
                    lv_adj_qty_status := 'ERROR';
                END IF;

                IF lv_adj_qty_status = 'ERROR'
                THEN
                    o_message :=
                        'Adjustment quantity is more than C3 OnHand Qty';
                END IF;
            ELSIF i_to_subinv IS NOT NULL AND i_adj_qty IS NULL
            THEN
                SELECT COUNT (1)
                  INTO lv_count
                  FROM crpadm.rc_sub_inv_loc_mstr
                 WHERE     sub_inventory_location <> 'FG'
                       AND sub_inventory_location = UPPER (i_to_subinv);

                IF lv_count = 1
                THEN
                    lv_subinv_status := 'SUCCESS';
                ELSE
                    lv_subinv_status := 'ERROR';
                END IF;

                IF lv_subinv_status = 'ERROR'
                THEN
                    o_message := 'Please provide Valid To Sub inventory';
                END IF;
            ELSIF i_to_subinv IS NOT NULL AND i_adj_qty IS NOT NULL
            THEN
                IF i_adj_qty <= i_c3_onhand_qty
                THEN
                    lv_adj_qty_status := 'SUCCESS';
                ELSE
                    lv_adj_qty_status := 'ERROR';
                END IF;

                IF lv_adj_qty_status = 'ERROR'
                THEN
                    lv_adj_qty_msg :=
                        'Adjustment quantity is more than C3 OnHand Qty';
                END IF;

                SELECT COUNT (1)
                  INTO lv_count
                  FROM crpadm.rc_sub_inv_loc_mstr
                 WHERE     sub_inventory_location <> 'FG'
                       AND sub_inventory_location = UPPER (i_to_subinv);

                IF lv_count = 1
                THEN
                    lv_subinv_status := 'SUCCESS';
                ELSE
                    lv_subinv_status := 'ERROR';
                END IF;

                IF lv_subinv_status = 'ERROR'
                THEN
                    lv_subinv_msg := 'Please provide Valid To Sub inventory';
                END IF;

                IF lv_subinv_status = 'ERROR' AND lv_adj_qty_status = 'ERROR'
                THEN
                    o_message := lv_subinv_msg || ' and ' || lv_adj_qty_msg;
                ELSIF     lv_subinv_status = 'SUCCESS'
                      AND lv_adj_qty_status = 'ERROR'
                THEN
                    o_message := lv_adj_qty_msg;
                ELSIF     lv_subinv_status = 'ERROR'
                      AND lv_adj_qty_status = 'SUCCESS'
                THEN
                    o_message := lv_subinv_msg;
                END IF;
            END IF;
        ELSIF i_adj_qty = 0
        THEN
            lv_adj_qty_msg := 'Adjustment quantity should not be zero';
            o_message := lv_adj_qty_msg;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            v_message := SUBSTR (SQLERRM, 1, 200);

            P_RCEC_ERROR_LOG (
                I_module_name =>
                    'P_SUB_INV_ADJ_QTY_VALIDATION',
                I_entity_name =>
                    NULL,
                I_entity_id =>
                    NULL,
                I_ext_entity_name =>
                    NULL,
                I_ext_entity_id =>
                    NULL,
                I_error_type =>
                    'EXCEPTION',
                i_Error_Message =>
                       'Error getting while executing P_SUB_INV_ADJ_QTY_VALIDATION '
                    || v_message
                    || ' LineNo=> '
                    || DBMS_UTILITY.Format_error_backtrace,
                I_created_by =>
                    'P_SUB_INV_ADJ_QTY_VALIDATION',
                I_updated_by =>
                    'P_SUB_INV_ADJ_QTY_VALIDATION');
    END P_TO_SUBINV_ADJ_QTY_VALIDATION; /* End added as part of DGI Transfer changes to validate To subinventory and Adjustment qty on 14-Jun-2019 */

    /* Start added as part of DGI Transfer changes for Request Email notification on 14-Jun-2019 */
    PROCEDURE P_RC_INV_TRANS_DGI_NOTIFY_MAIL
    IS
        lv_msg_from          VARCHAR2 (500);
        lv_email_sender      VARCHAR2 (100) := 'remarketing-it@cisco.com';
        lv_msg_to            VARCHAR2 (500);
        lv_msg_subject       VARCHAR2 (32767);
        lv_tmsg_subject      VARCHAR2 (32767);
        lv_msg_text          VARCHAR2 (32767);
        lv_dgi_msg_text      VARCHAR2 (32767);
        lv_trn_msg_text      VARCHAR2 (32767);
        lv_output_hdr        CLOB;
        lv_count             NUMBER := 0;
        lv_output            CLOB;
        lv_database_name     VARCHAR2 (50);
        lv_filename          VARCHAR2 (5000);
        lv_start_time        VARCHAR2 (100);
        lv_request_ids       VARCHAR2 (300);
        lv_count_col         NUMBER := 0;
        lv_req_recipients    VARCHAR2 (32767);
        lv_proc_recipients   VARCHAR2 (32767);
    BEGIN
        INSERT INTO debug2
             VALUES ('mail step 1', SYSDATE);

        SELECT ora_database_name INTO lv_database_name FROM DUAL;

        IF (lv_database_name = 'FNTR2PRD.CISCO.COM')
        THEN
            lv_tmsg_subject := NULL;
        ELSIF (lv_database_name = 'FNTR2STG.CISCO.COM')
        THEN
            lv_tmsg_subject := 'STAGE : ';
        ELSE
            lv_tmsg_subject := 'DEV : ';
        END IF;

        SELECT TO_CHAR (SYSDATE, 'MM/DD/YYYY HH:MI:SS PM')
          INTO lv_start_time
          FROM DUAL;

        INSERT INTO debug2
             VALUES ('lv_start_time' || '-' || lv_start_time, SYSDATE);

        --insert into debug2 values (i_created_by||','||i_part_number,sysdate);

        lv_msg_text :=
            ' <head>
                    <style>
                    table {
                        font-family: arial, sans-serif;
                        border-collapse: collapse;
                        width: 100%;
                    }

                    td, th {
                        border: 1px solid black;
                        text-align: left;
                        padding: 4px;
                    }
                    </style>
                    </head>
                    <body>
                    <table>
                         <tr>
                        <th>Request ID</th><th>PID</th><th>Transaction Type</th><th>Site Code</th><th>From Subinv</th><th>To Subinv</th><th>C3 Onhand Qty</th><th>Qty Requested</th><th>Requested By</th><th>Requested Date</th><th>Requestor Comments</th></tr>';


        lv_count_col := 0;

        lv_dgi_msg_text :=
               '<HTML>'
            || '<br /><br /> '
            || ' DGI Inventory Transfer Requests given below.'
            || '<br /><br /> '
            || lv_msg_text;

        lv_req_recipients := NULL;

        FOR rec
            IN (  SELECT rai.REQUEST_ID,
                         rai.PART_NUMBER,
                         rai.TRANSACTION_TYPE,
                         rai.SITE_CODE,
                         rai.FROM_SUBINV,
                         UPPER (rai.TO_SUBINV) TO_SUBINV,
                         rai.C3_ONHAND_QTY,
                         rai.QTY_TO_TRANSFER,
                         rai.REQUESTED_BY,
                         rai.REQUESTED_DATE,
                         rai.COMMENTS
                    FROM rmktgadm.rmk_adminui_invtransfer rai
                   WHERE     1 = 1
                         AND transaction_type = 'DGI-TRANSFER'
                         AND aproval_status IS NULL
                         AND approved_date IS NULL
                         AND IS_MAIL_NOTIFIED IS NULL      -- Added PRB0061374
                ORDER BY requested_date DESC, requested_by)
        LOOP
            lv_req_recipients := rec.requested_by;

            --         INSERT INTO debug2
            --              VALUES ('requested_by' || '-' || rec.requested_by, SYSDATE);

            IF MOD (lv_count_col, 2) = 0
            THEN
                lv_dgi_msg_text :=
                       lv_dgi_msg_text
                    || '<tr style="background-color: #dddddd">';
            ELSE
                lv_dgi_msg_text := lv_dgi_msg_text || '<tr>';
            END IF;

            lv_dgi_msg_text :=
                   lv_dgi_msg_text
                || '
                            <td>'
                || rec.REQUEST_ID
                || '</td><td nowrap>'
                || rec.PART_NUMBER
                || '</td><td nowrap>'
                || rec.TRANSACTION_TYPE
                || '</td><td nowrap>'
                || rec.SITE_CODE
                || '</td><td>'
                || rec.FROM_SUBINV
                || '</td><td>'
                || rec.TO_SUBINV
                || '</td><td>'
                || rec.C3_ONHAND_QTY
                || '</td><td>'
                || rec.QTY_TO_TRANSFER
                || '</td><td nowrap>'
                || rec.REQUESTED_BY
                || '</td><td nowrap>'
                || TO_CHAR (rec.REQUESTED_DATE, 'DD-Mon-YYYY HH:Mi:SS')
                || '</td><td nowrap>'
                || rec.COMMENTS
                || '</td></tr>';


            lv_count_col := lv_count_col + 1;
        END LOOP;


        lv_dgi_msg_text :=
               lv_dgi_msg_text
            || '</table>'
            || '<br> '
            || 'PLEASE DO NOT REPLY .. This is an Auto generated Email.'
            || '
                      </body> </html>';

        lv_msg_subject := NULL;

        IF lv_count_col > 0
        THEN
            lv_msg_subject :=
                   lv_tmsg_subject
                || 'DGI Inventory Transfer Requests - '
                || lv_start_time;

            BEGIN
                SELECT email_sender, email_recipients
                  INTO lv_msg_from, lv_msg_to
                  FROM crpadm.rc_email_notifications
                 WHERE notification_name =
                       CASE
                           WHEN lv_database_name = 'FNTR2PRD.CISCO.COM'
                           THEN
                               'INV_TRANS_DGI_PRD_NOTIFY'
                           WHEN lv_database_name = 'FNTR2STG.CISCO.COM'
                           THEN
                               'INV_TRANS_DGI_STG_NOTIFY'
                           ELSE
                               'INV_TRANS_DGI_DEV_NOTIFY'
                       END;
            EXCEPTION
                WHEN OTHERS
                THEN
                    lv_msg_from := lv_email_sender;
                    lv_msg_to := lv_email_sender;
            END;

            INSERT INTO debug2
                     VALUES (
                                   'lv_msg_from_to'
                                || '-'
                                || lv_msg_from
                                || ','
                                || lv_msg_to,
                                SYSDATE);

            IF lv_req_recipients IS NOT NULL
            THEN
                lv_msg_to := lv_req_recipients || ',' || lv_msg_to;
            END IF;

            INSERT INTO debug2
                 VALUES ('lv_msg_to' || '-' || lv_msg_to, SYSDATE);

            BEGIN
                crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (
                    lv_msg_from,
                    lv_msg_to,
                    lv_msg_subject,
                    lv_dgi_msg_text,
                    NULL,                                       --lv_filename,
                    NULL                                           --lv_output
                        );
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_message := SUBSTR (SQLERRM, 1, 50);
            END;
        END IF;

        INSERT INTO debug2
             VALUES ('completed', SYSDATE);

        /*start mark the flag to 'Y' PRB0061374*/
        UPDATE rmk_adminui_invtransfer
           SET IS_MAIL_NOTIFIED = 'Y'
         WHERE     1 = 1
               AND transaction_type = 'DGI-TRANSFER'
               AND aproval_status IS NULL
               AND approved_date IS NULL;

        COMMIT;
    /*end mark the flag to 'Y' PRB0061374*/

    EXCEPTION
        WHEN OTHERS
        THEN
            v_message := SUBSTR (SQLERRM, 1, 200);

            P_RCEC_ERROR_LOG (
                I_module_name =>
                    'P_RC_INV_TRANS_DGI_NOTIFY_MAIL',
                I_entity_name =>
                    NULL,
                I_entity_id =>
                    NULL,
                I_ext_entity_name =>
                    NULL,
                I_ext_entity_id =>
                    NULL,
                I_error_type =>
                    'EXCEPTION',
                i_Error_Message =>
                       'Error getting while executing P_RC_INV_TRANS_DGI_NOTIFY_MAIL '
                    || v_message
                    || ' LineNo=> '
                    || DBMS_UTILITY.Format_error_backtrace,
                I_created_by =>
                    'P_RC_INV_TRANS_DGI_NOTIFY_MAIL',
                I_updated_by =>
                    'P_RC_INV_TRANS_DGI_NOTIFY_MAIL');
    END P_RC_INV_TRANS_DGI_NOTIFY_MAIL;

    /* End added as part of DGI Transfer changes for Request Email notification on 14-Jun-2019 */

    /* Start added as part of DGI Transfer changes for Approval Email notification on 14-Jun-2019 */
    PROCEDURE P_RC_INV_DGI_APPROVAL_NOTIFY
    IS
        lv_msg_from          VARCHAR2 (500);
        lv_email_sender      VARCHAR2 (100) := 'remarketing-it@cisco.com';
        lv_msg_to            VARCHAR2 (500);
        lv_site_msg_to       VARCHAR2 (500);
        lv_msg_subject       VARCHAR2 (32767);
        lv_tmsg_subject      VARCHAR2 (32767);
        lv_msg_text          VARCHAR2 (32767);
        lv_dgi_msg_text      VARCHAR2 (32767);    -- back to vrchar PRB0062429
        lv_trn_msg_text      VARCHAR2 (32767);
        lv_output_hdr        CLOB;
        lv_count             NUMBER := 0;
        lv_output            CLOB;
        lv_database_name     VARCHAR2 (50);
        lv_filename          VARCHAR2 (5000);
        lv_start_time        VARCHAR2 (100);
        lv_request_ids       VARCHAR2 (300);
        lv_count_col         NUMBER := 0;
        lv_req_recipients    VARCHAR2 (32767);
        lv_proc_recipients   VARCHAR2 (32767);


        COUNT_VALUE          NUMBER := 0;                   --added PRB0062429
        MIN_VALUE            NUMBER;                        --added PRB0062429
        MAX_VALUE            NUMBER;                        --added PRB0062429
    BEGIN
        --   INSERT INTO debug2
        --        VALUES ('mail step1', SYSDATE);

        FOR CUR
            IN (SELECT DISTINCT SUBSTR (SITE_CODE, 1, 3) SITE, SITE_CODE
                  FROM (  SELECT rai.REQUEST_ID,
                                 rai.PART_NUMBER,
                                 rai.TRANSACTION_TYPE,
                                 rai.SITE_CODE,
                                 rai.FROM_SUBINV,
                                 UPPER (rai.TO_SUBINV)
                                     TO_SUBINV,
                                 rai.C3_ONHAND_QTY,
                                 rai.QTY_TO_TRANSFER,
                                 rai.QTY_TO_PROCESS,
                                 rai.REQUESTED_BY,
                                 rai.REQUESTED_DATE,
                                 rai.APPROVED_BY,
                                 rai.APPROVED_DATE,
                                 CASE
                                     WHEN UPPER (rai.APROVAL_STATUS) LIKE
                                              'AUTO%'
                                     THEN
                                         'Approved'
                                     WHEN UPPER (rai.APROVAL_STATUS) LIKE
                                              'APPROVE%'
                                     THEN
                                         'Approved'
                                     ELSE
                                         INITCAP (rai.APROVAL_STATUS)
                                 END
                                     APROVAL_STATUS,
                                 rai.COMMENTS,
                                 rai.APPROVER_COMMENTS
                            FROM rmktgadm.rmk_adminui_invtransfer rai
                           WHERE     1 = 1
                                 AND transaction_type = 'DGI-TRANSFER'
                                 AND UPPER (aproval_status) IN
                                         ('APPROVED', 'AUTO APPROVED')
                                 AND approved_date IS NOT NULL
                                 AND attribute2 = 'N'
                        ORDER BY requested_date DESC, requested_by))
        LOOP
            --INSERT INTO debug2
            --      VALUES ('mail step2', SYSDATE);

            --  INSERT INTO debug2
            --       VALUES ('cur.site_code' || '-' || cur.site_code, SYSDATE);

            --  INSERT INTO debug2
            --       VALUES ('cur.site' || '-' || cur.site, SYSDATE);

            SELECT ora_database_name INTO lv_database_name FROM DUAL;

            IF (lv_database_name = 'FNTR2PRD.CISCO.COM')
            THEN
                lv_tmsg_subject := NULL;
            ELSIF (lv_database_name = 'FNTR2STG.CISCO.COM')
            THEN
                lv_tmsg_subject := 'STAGE : ';
            ELSE
                lv_tmsg_subject := 'DEV : ';
            END IF;

            SELECT TO_CHAR (SYSDATE, 'MM/DD/YYYY HH:MI:SS PM')
              INTO lv_start_time
              FROM DUAL;

            -- INSERT INTO debug2
            --      VALUES ('lv_start_time' || '-' || lv_start_time, SYSDATE);

            lv_msg_text :=
                ' <head>
                    <style>
                    table {
                        font-family: arial, sans-serif;
                        border-collapse: collapse;
                        width: 100%;
                    }

                    td, th {
                        border: 1px solid black;
                        text-align: left;
                        padding: 4px;
                    }
                    </style>
                    </head>
                    <body>
                    <table>
                         <tr>
                        <th>Request ID</th><th>PID</th><th>Transaction Type</th><th>Site Code</th><th>From Subinv</th><th>To Subinv</th><th>C3 Onhand Qty</th><th>Qty Requested</th><th>Qty Approved</th><th>Requested By</th><th>Requested Date</th><th>Approved By</th><th>Approved Date</th><th>Status</th><th>Requestor Comments</th><th>Approver Comments</th></tr>';


            --added PRB0062429 --

            SELECT COUNT (*)
              INTO COUNT_VALUE
              FROM rmktgadm.rmk_adminui_invtransfer rai
             WHERE     1 = 1
                   AND site_code LIKE '' || cur.site_code || '%'
                   AND transaction_type = 'DGI-TRANSFER'
                   AND UPPER (aproval_status) IN
                           ('APPROVED', 'AUTO APPROVED')
                   AND approved_date IS NOT NULL
                   AND attribute2 = 'N';

            --added PRB0062429 --


            IF COUNT_VALUE <= 50
            THEN --added PRB0062429 based this condition we added new code else block which handle mutiple mail genration
                lv_count_col := 0;

                lv_dgi_msg_text :=
                       '<HTML>'
                    || '<br /><br /> '
                    || cur.site_code
                    || ' DGI Inventory Transfer Requests Approved by Inventory Admin. Please process Adjustments in your system. '
                    || '<br /><br /> '
                    || lv_msg_text;

                IF MOD (lv_count_col, 2) = 0
                THEN
                    lv_dgi_msg_text :=
                           lv_dgi_msg_text
                        || '<tr style="background-color: #dddddd">';
                ELSE
                    lv_dgi_msg_text := lv_dgi_msg_text || '<tr>';
                END IF;


                lv_req_recipients := NULL;

                FOR rec
                    IN (  SELECT rai.REQUEST_ID,
                                 rai.PART_NUMBER,
                                 rai.TRANSACTION_TYPE,
                                 rai.SITE_CODE,
                                 rai.FROM_SUBINV,
                                 UPPER (rai.TO_SUBINV)
                                     TO_SUBINV,
                                 rai.C3_ONHAND_QTY,
                                 rai.QTY_TO_TRANSFER,
                                 rai.QTY_TO_PROCESS,
                                 rai.REQUESTED_BY,
                                 rai.REQUESTED_DATE,
                                 rai.APPROVED_BY,
                                 rai.APPROVED_DATE,
                                 CASE
                                     WHEN UPPER (rai.APROVAL_STATUS) LIKE
                                              'AUTO%'
                                     THEN
                                         'Approved'
                                     WHEN UPPER (rai.APROVAL_STATUS) LIKE
                                              'APPROVE%'
                                     THEN
                                         'Approved'
                                     ELSE
                                         INITCAP (rai.APROVAL_STATUS)
                                 END
                                     APROVAL_STATUS,
                                 rai.COMMENTS,
                                 rai.APPROVER_COMMENTS,
                                 RANK ()
                                 OVER (
                                     ORDER BY requested_date DESC, requested_by)
                                     RNUM
                            FROM rmktgadm.rmk_adminui_invtransfer rai
                           WHERE     1 = 1
                                 AND site_code LIKE '' || cur.site_code || '%'
                                 AND transaction_type = 'DGI-TRANSFER'
                                 AND UPPER (aproval_status) IN
                                         ('APPROVED', 'AUTO APPROVED')
                                 AND approved_date IS NOT NULL
                                 AND attribute2 = 'N'
                        ORDER BY requested_date DESC, requested_by)
                LOOP
                    --  INSERT INTO debug2
                    --        VALUES ('inside loop of dgi reeq body table ', SYSDATE);

                    --  INSERT INTO debug2
                    --        VALUES ('inside loop of dgi reeq body table site_code' || '-' || cur.site_code, SYSDATE);

                    lv_req_recipients :=
                        rec.requested_by || ',' || rec.approved_by;



                    lv_dgi_msg_text :=
                           lv_dgi_msg_text
                        || '
                            <td>'
                        || rec.REQUEST_ID
                        || '</td><td nowrap>'
                        || rec.PART_NUMBER
                        || '</td><td nowrap>'
                        || rec.TRANSACTION_TYPE
                        || '</td><td nowrap>'
                        || rec.SITE_CODE
                        || '</td><td>'
                        || rec.FROM_SUBINV
                        || '</td><td>'
                        || rec.TO_SUBINV
                        || '</td><td>'
                        || rec.C3_ONHAND_QTY
                        || '</td><td>'
                        || rec.QTY_TO_TRANSFER
                        || '</td><td>'
                        || rec.QTY_TO_PROCESS
                        || '</td><td nowrap>'
                        || rec.REQUESTED_BY
                        || '</td><td nowrap>'
                        || TO_CHAR (rec.REQUESTED_DATE,
                                    'DD-Mon-YYYY HH:Mi:SS')
                        || '</td><td nowrap>'
                        || rec.APPROVED_BY
                        || '</td><td nowrap>'
                        || TO_CHAR (rec.APPROVED_DATE,
                                    'DD-Mon-YYYY HH:Mi:SS')
                        || '</td><td nowrap>'
                        --|| rec.APROVAL_STATUS --Commented by satbanda for US161611
                        || INITCAP (rec.APROVAL_STATUS) --Added by satbanda for US161611
                        || '</td><td nowrap>'
                        || rec.COMMENTS
                        || '</td><td nowrap>'
                        || rec.APPROVER_COMMENTS
                        || '</td></tr>';


                    lv_count_col := lv_count_col + 1;
                END LOOP;                          -- mail body formation loop

                --     INSERT INTO debug2
                --         VALUES ('step3', SYSDATE);

                lv_dgi_msg_text :=
                       lv_dgi_msg_text
                    || '</table>'
                    || '<br> '
                    || 'PLEASE DO NOT REPLY .. This is an Auto generated Email.'
                    || '
                      </body> </html>';

                lv_msg_subject := NULL;



                IF lv_count_col > 0
                THEN
                    lv_msg_subject :=
                           lv_tmsg_subject
                        || 'DGI Inventory Transfer Requests - '
                        || lv_start_time;

                    BEGIN
                        SELECT email_sender, email_recipients
                          INTO lv_msg_from, lv_msg_to
                          FROM crpadm.rc_email_notifications
                         WHERE notification_name =
                               CASE
                                   /* WHEN lv_database_name = 'FNTR2PRD.CISCO.COM'
                                    THEN
                                        'INV_TRANS_DGI_PRD_NOTIFY' */
                                   -- Commented as part of production enhancements User Story# US344355
                                   /*Added as part of User Story # US344355 */
                                   WHEN     lv_database_name =
                                            'FNTR2PRD.CISCO.COM'
                                        AND cur.site_code = 'Z05'
                                   THEN
                                       'INV_TRANS_DGI_PRD_NOTIFY_Z05'
                                   WHEN     lv_database_name =
                                            'FNTR2PRD.CISCO.COM'
                                        AND cur.site_code = 'Z29'
                                   THEN
                                       'INV_TRANS_DGI_PRD_NOTIFY_Z29'
                                   WHEN     lv_database_name =
                                            'FNTR2PRD.CISCO.COM'
                                        AND cur.site_code = 'Z32'
                                   THEN
                                       'INV_TRANS_DGI_PRD_NOTIFY_Z32'
                                   WHEN     lv_database_name =
                                            'FNTR2PRD.CISCO.COM'
                                        AND cur.site_code = 'Z20'
                                   THEN
                                       'INV_TRANS_DGI_PRD_NOTIFY_Z20'
                                   WHEN     lv_database_name =
                                            'FNTR2PRD.CISCO.COM'
                                        AND cur.site_code = 'Z31'
                                   THEN
                                       'INV_TRANS_DGI_PRD_NOTIFY_Z31'
                                   WHEN     lv_database_name =
                                            'FNTR2PRD.CISCO.COM'
                                        AND cur.site_code = 'Z26'
                                   THEN
                                       'INV_TRANS_DGI_PRD_NOTIFY_Z26'
                                   WHEN     lv_database_name =
                                            'FNTR2PRD.CISCO.COM'
                                        AND cur.site_code = 'Z28'
                                   THEN
                                       'INV_TRANS_DGI_PRD_NOTIFY_Z28'
                                   /*End as part of User Story # US344355 */

                                   WHEN lv_database_name =
                                        'FNTR2STG.CISCO.COM'
                                   THEN
                                       'INV_TRANS_DGI_STG_NOTIFY'
                                   WHEN lv_database_name =
                                        'FNTR2DEV.CISCO.COM'
                                   THEN
                                       'INV_TRANS_DGI_DEV_NOTIFY'
                               END;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            lv_msg_from := lv_email_sender;
                            lv_msg_to := lv_email_sender;
                    END;

                    --   INSERT INTO debug2
                    --        VALUES ('step4', SYSDATE);

                    --   INSERT INTO debug2
                    --         VALUES (
                    --                   'lv_msg_from_to'
                    --                || '-'
                    --               || lv_msg_from
                    --               || ' '
                    --              || lv_msg_to,
                    --              SYSDATE);

                    BEGIN
                        SELECT EMAIL_RECIPIENTS
                          INTO lv_site_msg_to
                          FROM CRPADM.RC_EMAIL_NOTIFICATIONS
                         WHERE NOTIFICATION_NAME =
                               CASE
                                   WHEN lv_database_name =
                                        'FNTR2PRD.CISCO.COM'
                                   THEN
                                          'REFRESH_SITE_NOTIFICATIONS_PRD_'
                                       || cur.site
                                       || ''
                                   --                                'sridvasu@cisco.com'
                                   WHEN lv_database_name =
                                        'FNTR2STG.CISCO.COM'
                                   THEN
                                          'REFRESH_SITE_NOTIFICATIONS_PRD_'
                                       || cur.site
                                       || ''
                                   --                                    'sridvasu@cisco.com'
                                   ELSE
                                          'REFRESH_SITE_NOTIFICATIONS_PRD_'
                                       || cur.site
                                       || ''
                               --        'sridvasu@cisco.com'
                               END;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            lv_site_msg_to := lv_email_sender;
                    END;

                    --  INSERT INTO debug2
                    --      VALUES ('step5', SYSDATE);

                    -- INSERT INTO debug2
                    --      VALUES ('lv_site_msg_to' || '-' || lv_site_msg_to, SYSDATE);

                    IF lv_req_recipients IS NOT NULL
                    THEN
                        lv_msg_to :=
                               lv_req_recipients
                            || ','
                            || lv_msg_to
                            || ','
                            || lv_site_msg_to;
                    END IF;

                    --    INSERT INTO debug2
                    --            VALUES (
                    --                     'lv_req_recipients' || '-' || lv_req_recipients,
                    --                      SYSDATE);

                    BEGIN
                        crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (
                            lv_msg_from,
                            lv_msg_to,
                            lv_msg_subject,
                            lv_dgi_msg_text,
                            NULL,                               --lv_filename,
                            NULL                                   --lv_output
                                );
                    --INSERT INTO debug2
                    --     VALUES ('completed', SYSDATE);



                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            v_message := SUBSTR (SQLERRM, 1, 50);
                    END;
                END IF;
            ELSE -- this is count >50 added PRB0062429 entir esle block was added as part of  PRB0062429
                MIN_VALUE := 1;
                MAX_VALUE := 50;


                lv_req_recipients := NULL;

               <<clobdata>>
                LOOP
                    lv_count_col := 0;

                    lv_dgi_msg_text :=
                           '<HTML>'
                        || '<br /><br /> '
                        || cur.site_code
                        || ' DGI Inventory Transfer Requests Approved by Inventory Admin. Please process Adjustments in your system. '
                        || '<br /><br /> '
                        || lv_msg_text;

                    IF MOD (lv_count_col, 2) = 0
                    THEN
                        lv_dgi_msg_text :=
                               lv_dgi_msg_text
                            || '<tr style="background-color: #dddddd">';
                    ELSE
                        lv_dgi_msg_text := lv_dgi_msg_text || '<tr>';
                    END IF;


                    lv_req_recipients := NULL;

                    FOR rec
                        IN (SELECT *
                              FROM (  SELECT rai.REQUEST_ID,
                                             rai.PART_NUMBER,
                                             rai.TRANSACTION_TYPE,
                                             rai.SITE_CODE,
                                             rai.FROM_SUBINV,
                                             UPPER (rai.TO_SUBINV)
                                                 TO_SUBINV,
                                             rai.C3_ONHAND_QTY,
                                             rai.QTY_TO_TRANSFER,
                                             rai.QTY_TO_PROCESS,
                                             rai.REQUESTED_BY,
                                             rai.REQUESTED_DATE,
                                             rai.APPROVED_BY,
                                             rai.APPROVED_DATE,
                                             CASE
                                                 WHEN UPPER (
                                                          rai.APROVAL_STATUS) LIKE
                                                          'AUTO%'
                                                 THEN
                                                     'Approved'
                                                 WHEN UPPER (
                                                          rai.APROVAL_STATUS) LIKE
                                                          'APPROVE%'
                                                 THEN
                                                     'Approved'
                                                 ELSE
                                                     INITCAP (
                                                         rai.APROVAL_STATUS)
                                             END
                                                 APROVAL_STATUS,
                                             rai.COMMENTS,
                                             rai.APPROVER_COMMENTS,
                                             RANK ()
                                             OVER (
                                                 ORDER BY
                                                     requested_date DESC,
                                                     requested_by)
                                                 RNUM
                                        FROM rmktgadm.rmk_adminui_invtransfer
                                             rai
                                       WHERE     1 = 1
                                             AND site_code LIKE
                                                     '' || cur.site_code || '%'
                                             AND transaction_type =
                                                 'DGI-TRANSFER'
                                             AND UPPER (aproval_status) IN
                                                     ('APPROVED',
                                                      'AUTO APPROVED')
                                             AND approved_date IS NOT NULL
                                             AND attribute2 = 'N'
                                    ORDER BY requested_date DESC,
                                             requested_by)
                             WHERE RNUM BETWEEN MIN_VALUE AND MAX_VALUE)
                    LOOP
                        lv_req_recipients :=
                            rec.requested_by || ',' || rec.approved_by;



                        lv_dgi_msg_text :=
                               lv_dgi_msg_text
                            || '<td>'
                            || rec.REQUEST_ID
                            || '</td><td nowrap>'
                            || rec.PART_NUMBER
                            || '</td><td nowrap>'
                            || rec.TRANSACTION_TYPE
                            || '</td><td nowrap>'
                            || rec.SITE_CODE
                            || '</td><td>'
                            || rec.FROM_SUBINV
                            || '</td><td>'
                            || rec.TO_SUBINV
                            || '</td><td>'
                            || rec.C3_ONHAND_QTY
                            || '</td><td>'
                            || rec.QTY_TO_TRANSFER
                            || '</td><td>'
                            || rec.QTY_TO_PROCESS
                            || '</td><td nowrap>'
                            || rec.REQUESTED_BY
                            || '</td><td nowrap>'
                            || TO_CHAR (rec.REQUESTED_DATE,
                                        'DD-Mon-YYYY HH:Mi:SS')
                            || '</td><td nowrap>'
                            || rec.APPROVED_BY
                            || '</td><td nowrap>'
                            || TO_CHAR (rec.APPROVED_DATE,
                                        'DD-Mon-YYYY HH:Mi:SS')
                            || '</td><td nowrap>'
                            --|| rec.APROVAL_STATUS --Commented by satbanda for US161611
                            || INITCAP (rec.APROVAL_STATUS) --Added by satbanda for US161611
                            || '</td><td nowrap>'
                            || rec.COMMENTS
                            || '</td><td nowrap>'
                            || rec.APPROVER_COMMENTS
                            || '</td></tr>';


                        lv_count_col := lv_count_col + 1;
                    END LOOP; ---  bosy formation , in else clock it will run mitiple times



                    lv_dgi_msg_text :=
                           lv_dgi_msg_text
                        || '</table>'
                        || '<br> '
                        || 'PLEASE DO NOT REPLY .. This is an Auto generated Email.'
                        || '
                      </body> </html>';

                    lv_msg_subject := NULL;



                    IF lv_count_col > 0
                    THEN
                        lv_msg_subject :=
                               lv_tmsg_subject
                            || 'DGI Inventory Transfer Requests - '
                            || lv_start_time;

                        BEGIN
                            SELECT email_sender, email_recipients
                              INTO lv_msg_from, lv_msg_to
                              FROM crpadm.rc_email_notifications
                             WHERE notification_name =
                                   CASE
                                       /* WHEN lv_database_name = 'FNTR2PRD.CISCO.COM'
                                        THEN
                                            'INV_TRANS_DGI_PRD_NOTIFY' */
                                       -- Commented as part of production enhancements User Story# US344355
                                       /*Added as part of User Story # US344355 */
                                       WHEN     lv_database_name =
                                                'FNTR2PRD.CISCO.COM'
                                            AND cur.site_code = 'Z05'
                                       THEN
                                           'INV_TRANS_DGI_PRD_NOTIFY_Z05'
                                       WHEN     lv_database_name =
                                                'FNTR2PRD.CISCO.COM'
                                            AND cur.site_code = 'Z29'
                                       THEN
                                           'INV_TRANS_DGI_PRD_NOTIFY_Z29'
                                       WHEN     lv_database_name =
                                                'FNTR2PRD.CISCO.COM'
                                            AND cur.site_code = 'Z32'
                                       THEN
                                           'INV_TRANS_DGI_PRD_NOTIFY_Z32'
                                       WHEN     lv_database_name =
                                                'FNTR2PRD.CISCO.COM'
                                            AND cur.site_code = 'Z20'
                                       THEN
                                           'INV_TRANS_DGI_PRD_NOTIFY_Z20'
                                       WHEN     lv_database_name =
                                                'FNTR2PRD.CISCO.COM'
                                            AND cur.site_code = 'Z31'
                                       THEN
                                           'INV_TRANS_DGI_PRD_NOTIFY_Z31'
                                       WHEN     lv_database_name =
                                                'FNTR2PRD.CISCO.COM'
                                            AND cur.site_code = 'Z26'
                                       THEN
                                           'INV_TRANS_DGI_PRD_NOTIFY_Z26'
                                       WHEN     lv_database_name =
                                                'FNTR2PRD.CISCO.COM'
                                            AND cur.site_code = 'Z28'
                                       THEN
                                           'INV_TRANS_DGI_PRD_NOTIFY_Z28'
                                       /*End as part of User Story # US344355 */

                                       WHEN lv_database_name =
                                            'FNTR2STG.CISCO.COM'
                                       THEN
                                           'INV_TRANS_DGI_STG_NOTIFY'
                                       WHEN lv_database_name =
                                            'FNTR2DEV.CISCO.COM'
                                       THEN
                                           'INV_TRANS_DGI_DEV_NOTIFY'
                                   END;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                lv_msg_from := lv_email_sender;
                                lv_msg_to := lv_email_sender;
                        END;



                        BEGIN
                            SELECT EMAIL_RECIPIENTS
                              INTO lv_site_msg_to
                              FROM CRPADM.RC_EMAIL_NOTIFICATIONS
                             WHERE NOTIFICATION_NAME =
                                   CASE
                                       WHEN lv_database_name =
                                            'FNTR2PRD.CISCO.COM'
                                       THEN
                                              'REFRESH_SITE_NOTIFICATIONS_PRD_'
                                           || cur.site
                                           || ''
                                       --                                'sridvasu@cisco.com'
                                       WHEN lv_database_name =
                                            'FNTR2STG.CISCO.COM'
                                       THEN
                                              'REFRESH_SITE_NOTIFICATIONS_PRD_'
                                           || cur.site
                                           || ''
                                       --                                    'sridvasu@cisco.com'
                                       ELSE
                                              'REFRESH_SITE_NOTIFICATIONS_PRD_'
                                           || cur.site
                                           || ''
                                   --        'sridvasu@cisco.com'
                                   END;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                lv_site_msg_to := lv_email_sender;
                        END;

                        IF lv_req_recipients IS NOT NULL
                        THEN
                            lv_msg_to :=
                                   lv_req_recipients
                                || ','
                                || lv_msg_to
                                || ','
                                || lv_site_msg_to;
                        END IF;



                        BEGIN
                            crpadm.RC_INV_UTIL_GENERIC_MAIL.RC_INV_GENERIC_MAIL (
                                lv_msg_from,
                                lv_msg_to,
                                lv_msg_subject,
                                lv_dgi_msg_text,
                                NULL,                           --lv_filename,
                                NULL                               --lv_output
                                    );
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                v_message := SUBSTR (SQLERRM, 1, 50);
                        END;
                    END IF;



                    MIN_VALUE := MIN_VALUE + 50;
                    MAX_VALUE := MAX_VALUE + 50;
                    lv_dgi_msg_text := NULL;
                    EXIT clobdata WHEN MIN_VALUE > COUNT_VALUE;
                END LOOP;  -- loop of sending mutiple mails for same site code
            END IF;
        END LOOP;                                      --- main and first loop

        UPDATE rmktgadm.rmk_adminui_invtransfer rai
           SET attribute2 = 'Y'
         WHERE     1 = 1
               AND transaction_type = 'DGI-TRANSFER'
               AND UPPER (aproval_status) IN ('APPROVED', 'AUTO APPROVED')
               AND approved_date IS NOT NULL
               AND attribute2 = 'N';

        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            v_message := SUBSTR (SQLERRM, 1, 200);

            P_RCEC_ERROR_LOG (
                I_module_name =>
                    'P_RC_INV_DGI_APPROVAL_NOTIFY',
                I_entity_name =>
                    NULL,
                I_entity_id =>
                    NULL,
                I_ext_entity_name =>
                    NULL,
                I_ext_entity_id =>
                    NULL,
                I_error_type =>
                    'EXCEPTION',
                i_Error_Message =>
                       'Error getting while executing P_RC_INV_DGI_APPROVAL_NOTIFY '
                    || v_message
                    || ' LineNo=> '
                    || DBMS_UTILITY.Format_error_backtrace,
                I_created_by =>
                    'P_RC_INV_DGI_APPROVAL_NOTIFY',
                I_updated_by =>
                    'P_RC_INV_DGI_APPROVAL_NOTIFY');
    END P_RC_INV_DGI_APPROVAL_NOTIFY;

    /* End added as part of DGI Transfer changes for Approval Email notification on 14-Jun-2019 */



    FUNCTION F_GET_PENDING_DGI_FLAG (i_part_number    VARCHAR2,
                                     i_location       VARCHAR2,
                                     i_from_subinv    VARCHAR2)
        RETURN VARCHAR2
    IS
        l_rec_count            NUMBER := 0;

        l_pending_trans_flag   VARCHAR2 (1) := 'N';
    BEGIN
        --check the PID wheather it has pending any transaction or incomplete process
        BEGIN
            SELECT COUNT (1)
              INTO l_rec_count
              FROM rmk_adminui_invtransfer
             WHERE     part_number = i_part_number
                   AND site_code = i_location
                   AND from_subinv = i_from_subinv
                   AND NVL (UPPER (APROVAL_STATUS), '*') != v_rejected
                   AND (   approved_date IS NULL
                        OR approved_date >= SYSDATE - (1 / 24));
        EXCEPTION
            WHEN OTHERS
            THEN
                v_message := SUBSTR (SQLERRM, 1, 200);

                P_RCEC_ERROR_LOG (
                    I_module_name =>
                        'F_GET_PENDING_FLAG',
                    I_entity_name =>
                        'Part_number' || '->' || i_part_number,
                    I_entity_id =>
                        NULL,
                    I_ext_entity_name =>
                        NULL,
                    I_ext_entity_id =>
                        NULL,
                    I_error_type =>
                        'EXCEPTION',
                    i_Error_Message =>
                           'Error getting while fetching pending transaction for following PID: '
                        || i_part_number
                        || ', Location: '
                        || i_location
                        || ' <> '
                        || v_message
                        || ' LineNo=> '
                        || DBMS_UTILITY.Format_error_backtrace,
                    I_created_by =>
                        NULL,
                    I_updated_by =>
                        NULL);
        END;

        IF l_rec_count > 0
        THEN
            l_pending_trans_flag := 'Y';
        ELSE
            l_pending_trans_flag := 'N';
        END IF;

        RETURN l_pending_trans_flag;
    EXCEPTION
        WHEN OTHERS
        THEN
            l_pending_trans_flag := NULL;

            v_message := SUBSTR (SQLERRM, 1, 200);

            P_RCEC_ERROR_LOG (
                I_module_name =>
                    'F_GET_PENDING_DGI_FLAG',
                I_entity_name =>
                    'Part_number' || '->' || i_part_number,
                I_entity_id =>
                    NULL,
                I_ext_entity_name =>
                    NULL,
                I_ext_entity_id =>
                    NULL,
                I_error_type =>
                    'EXCEPTION',
                i_Error_Message =>
                       'Error getting while executing f_get_pending_dgi_flag  for following PID: '
                    || i_part_number
                    || ' <> '
                    || v_message
                    || ' LineNo=> '
                    || DBMS_UTILITY.Format_error_backtrace,
                I_created_by =>
                    NULL,
                I_updated_by =>
                    NULL);
    END f_get_pending_dgi_flag;

    /* US223935-Automation of daily FVE inventory movements - Phase 2 changes Starts*/
    PROCEDURE RC_FVE_INV_MOVE_AUTOMATION
    AS
        CURSOR c_partnumber
        IS
            SELECT DISTINCT REFRESH_PART_NUMBER
              FROM RC_FVE_INV_MOVEMENTS_STG
             WHERE PROCESS_STATUS = 'NOT PROCESSED';

        CURSOR c_fve_dtls (
            lv_partnumber    VARCHAR2)
        IS
              SELECT TAN_NUMBER,
                     FVE_TRANSFER_ORDER,
                     TRANSACTION_DATE,
                     QUANTITY,
                     TRANSACTION_TYPE,
                     REFRESH_PART_NUMBER,
                     PROCESS_STATUS,
                     CREATED_DATE,
                     CREATED_BY
                FROM RC_FVE_INV_MOVEMENTS_STG
               WHERE     REFRESH_PART_NUMBER = lv_partnumber
                     AND PROCESS_STATUS = 'NOT PROCESSED'
            ORDER BY TRANSACTION_DATE;

        TYPE RC_INV_OBJ IS RECORD
        (
            INVENTORY_FLOW              VARCHAR2 (25 BYTE),
            SITE_CODE                   VARCHAR2 (50 BYTE),
            RESTRICTION_FLAG            VARCHAR2 (10 BYTE),
            ROHS_COMPLIANT              VARCHAR2 (5 BYTE),
            AVAILABLE_QUANTITY          NUMBER,
            RESERVED_QUANTITY           NUMBER,
            AVAILABLE_TO_RESERVE_QTY    NUMBER
        );

        TYPE RC_INV_LIST IS TABLE OF RC_INV_OBJ;

        lv_inventory_list                RC_INV_LIST;

        lv_count                         NUMBER;
        lv_refresh_part_number           VARCHAR2 (50 BYTE);
        lv_rohs_check_needed             CHAR (1 BYTE);
        lv_mos                           NUMBER;
        lv_retail_max                    NUMBER;
        lv_outlet_cap                    NUMBER;
        lv_ytd_avg_sales_price           NUMBER (15, 2);
        lv_from_program_type             VARCHAR2 (25 BYTE);
        lv_site_code                     VARCHAR2 (50 BYTE);
        lv_restriction_flag              VARCHAR2 (10 BYTE);
        lv_rohs_compliant_flag           VARCHAR2 (5 BYTE);
        lv_available_qty                 NUMBER;
        lv_reserved_qty                  NUMBER;
        lv_available_to_reserve_qty      NUMBER;
        lv_retail_available_qty          NUMBER;
        lv_retail_reserved_qty           NUMBER;
        lv_retail_avail_to_reserve_qty   NUMBER;
        lv_outlet_available_qty          NUMBER;
        lv_outlet_reserved_qty           NUMBER;
        lv_outlet_avail_to_reserve_qty   NUMBER;
        lv_excess_available_qty          NUMBER;
        lv_excess_reserved_qty           NUMBER;
        lv_excess_avail_to_reserve_qty   NUMBER;
        lv_qty_to_transfer               NUMBER;
        lv_rem_qty                       NUMBER;
        lv_quantity                      NUMBER;
        --    lv_increment                     NUMBER;
        --    lv_flow                          VARCHAR2 (25 BYTE);
        --    lv_rem_inventory                 NUMBER;
        lv_flag                          VARCHAR2 (10 BYTE);
        lv_idx                           NUMBER;
        item_left                        NUMBER;
        lv_source_count                  NUMBER;
        V_PROCESS_COUNT                  NUMBER;
        --variables added for US353135
        mask_item_left                   NUMBER;
        mask_qyt_to_transfer             NUMBER;
        mask_item_used                   NUMBER;
        adg_status                       VARCHAR2 (20);
        V_MASK_ITEM_COUNT                NUMBER;
        MASK_QYT_TO_PROCESS              NUMBER;
        reserved_item_left               NUMBER;
        v_reserved_outlet                NUMBER;
        v_ros_comp_outlet                VARCHAR2 (20);
        v_avaible_fgi_outlet             NUMBER;
        v_reserved_fgi_outlet            NUMBER;
        v_avaiable_to_reserv_outlet      NUMBER;
        v_reserved_retail                NUMBER;
        v_ros_comp_retail                VARCHAR2 (20);
        v_avaible_fgi_retail             NUMBER;
        v_reserved_fgi_retail            NUMBER;
        v_avaiable_to_reserv_retail      NUMBER;
    --variables added for US353135
    BEGIN
        INSERT INTO CRPADM.RC_PROCESS_LOG
             VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                     'RC_FVE_INV_MOVE_AUTOMATION',
                     'START',
                     SYSDATE);

        COMMIT;

        SELECT COUNT (*) INTO lv_source_count FROM RC_FVE_INV_MOVEMENTS;

        IF lv_source_count > 0
        THEN
            /*HISTORY MAINTENANCE SHOULD BE HERE AND RC_FVE_INV_MOVEMENTS_TEST INSERTS WILL BE REMOVED*/
            EXECUTE IMMEDIATE 'TRUNCATE TABLE RC_FVE_INV_MOVEMENTS_TEST';

            INSERT INTO RC_FVE_INV_MOVEMENTS_TEST
                SELECT * FROM RC_FVE_INV_MOVEMENTS;

            COMMIT;

            EXECUTE IMMEDIATE 'TRUNCATE TABLE RC_FVE_INV_MOVEMENTS_STG';

            INSERT INTO RC_FVE_INV_MOVEMENTS_STG (TAN_NUMBER,
                                                  FVE_TRANSFER_ORDER,
                                                  TRANSACTION_DATE,
                                                  QUANTITY,
                                                  TRANSACTION_TYPE,
                                                  REFRESH_PART_NUMBER,
                                                  PROCESS_STATUS,
                                                  CREATED_DATE,
                                                  CREATED_BY)
                SELECT TAN_NUMBER,
                       FVE_TRANSFER_ORDER,
                       TRANSACTION_DATE,
                       QUANTITY,
                       TRANSACTION_TYPE,
                       (SELECT REFRESH_PART_NUMBER
                          FROM CRPADM.RC_PRODUCT_MASTER
                         WHERE TAN_ID = TAN_NUMBER)
                           REFRESH_PART_NUMBER,
                       PROCESS_STATUS,
                       CREATED_DATE,
                       CREATED_BY
                  FROM RC_FVE_INV_MOVEMENTS;

            COMMIT;

            FOR pid_rec IN c_partnumber
            LOOP
                SELECT COUNT (*)
                  INTO lv_count
                  FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                 WHERE PART_NUMBER = pid_rec.REFRESH_PART_NUMBER;

                IF lv_count > 0
                THEN
                    BEGIN
                        WITH
                            RMK_INV_TRNS_INFO
                            AS
                                (SELECT DISTINCT
                                        pm.REFRESH_PART_NUMBER,
                                        pm.ROHS_CHECK_NEEDED,
                                        MOS.MOS,
                                        (SELECT SUM (CURRENT_MAX)
                                           FROM CRPSC.RC_GBP_CURRENT_MAX_PRIORITY
                                          WHERE REFRESH_INVENTORY_ITEM_ID =
                                                PM.REFRESH_INVENTORY_ITEM_ID)
                                            Retail_Max,
                                        (SELECT CASE
                                                    WHEN MAX (
                                                             YTD_AVG_SALES_PRICE) <
                                                         750
                                                    THEN
                                                        250
                                                    WHEN MAX (
                                                             YTD_AVG_SALES_PRICE) BETWEEN 751
                                                                                      AND 5000
                                                    THEN
                                                        10
                                                    WHEN MAX (
                                                             YTD_AVG_SALES_PRICE) BETWEEN 5001
                                                                                      AND 10000
                                                    THEN
                                                        5
                                                    WHEN MAX (
                                                             YTD_AVG_SALES_PRICE) BETWEEN 10001
                                                                                      AND 25000
                                                    THEN
                                                        3
                                                    WHEN MAX (
                                                             YTD_AVG_SALES_PRICE) >
                                                         25000
                                                    THEN
                                                        1
                                                END
                                                    OutletCap
                                           FROM CRPSC.RC_R12_SHIPMENT_HISTORY
                                          WHERE REFRESH_INVENTORY_ITEM_ID =
                                                PM.REFRESH_INVENTORY_ITEM_ID)
                                            OUTLET_CAP,
                                        (SELECT MAX (YTD_AVG_SALES_PRICE)
                                           FROM CRPSC.RC_R12_SHIPMENT_HISTORY
                                          WHERE REFRESH_INVENTORY_ITEM_ID =
                                                PM.REFRESH_INVENTORY_ITEM_ID)
                                            YTD_AVG_SALES_PRICE,
                                        f_get_outletelg_flag (
                                            PM.REFRESH_PART_NUMBER,
                                            MOS.MOS)
                                            OUTLET_ELGBL
                                   FROM CRPADM.RC_PRODUCT_MASTER  PM
                                        INNER JOIN
                                        RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                                        IM
                                            ON (    PM.REFRESH_PART_NUMBER =
                                                    IM.PART_NUMBER
                                                AND IM.SITE_CODE IN
                                                        ('LRO', 'FVE', 'GDGI'))
                                        LEFT OUTER JOIN
                                        (SELECT DISTINCT
                                                MOS,
                                                REFRESH_INVENTORY_ITEM_ID
                                           FROM VAVNI_CISCO_RSCM_BP.VV_BP_MON_ROLLING_SHIP_DATA_VW
                                                MOS
                                                INNER JOIN
                                                CRPADM.RC_PRODUCT_MAPID_MAPPING
                                                MAP
                                                    ON (MAP.PRODUCT_MAP_ID =
                                                        MOS.PRODUCT_ID)) MOS
                                            ON (MOS.REFRESH_INVENTORY_ITEM_ID =
                                                PM.REFRESH_INVENTORY_ITEM_ID)
                                  WHERE PM.REFRESH_PART_NUMBER =
                                        pid_rec.REFRESH_PART_NUMBER)
                        SELECT REFRESH_PART_NUMBER,
                               ROHS_CHECK_NEEDED,
                               NVL (MOS, 0),
                               NVL (RETAIL_MAX, 0),
                               NVL (OUTLET_CAP, 0),
                               NVL (YTD_AVG_SALES_PRICE, 0)
                          INTO lv_refresh_part_number,
                               lv_rohs_check_needed,
                               lv_mos,
                               lv_retail_max,
                               lv_outlet_cap,
                               lv_ytd_avg_sales_price
                          FROM RMK_INV_TRNS_INFO;
                    EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                            lv_refresh_part_number := NULL;
                            lv_rohs_check_needed := NULL;
                            lv_mos := 0;
                            lv_retail_max := 0;
                            lv_outlet_cap := 0;
                            lv_ytd_avg_sales_price := 0;
                    END;

                      SELECT RIS.INVENTORY_FLOW,
                             RIS.SITE_CODE,
                             f_get_pending_flag (pid_rec.REFRESH_PART_NUMBER,
                                                 ris.site_code,
                                                 ris.rohs_compliant)
                                 Restriction_flag,
                             RIS.ROHS_COMPLIANT,
                             AVAILABLE_QUANTITY,
                             RESERVED_QUANTITY,
                             AVAILABLE_TO_RESERVE_QTY
                        BULK COLLECT INTO lv_inventory_list
                        FROM (  SELECT INVENTORY_FLOW,
                                       SITE_CODE,
                                       ROHS_COMPLIANT,
                                       SUM (
                                           DECODE (SITE_CODE,
                                                   'GDGI', AVAILABLE_DGI,
                                                   AVAILABLE_FGI))
                                           AVAILABLE_QUANTITY,
                                       SUM (
                                           DECODE (SITE_CODE,
                                                   'GDGI', RESERVED_DGI,
                                                   RESERVED_FGI))
                                           RESERVED_QUANTITY,
                                       SUM (
                                           DECODE (
                                               SITE_CODE,
                                               'GDGI', AVAILABLE_TO_RESERVE_DGI,
                                               AVAILABLE_TO_RESERVE_FGI))
                                           AVAILABLE_TO_RESERVE_QTY
                                  FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                                 WHERE     PART_NUMBER =
                                           pid_rec.REFRESH_PART_NUMBER
                                       AND SITE_CODE = 'FVE'
                                       AND INVENTORY_FLOW IN
                                               ('Retail', 'Outlet', 'Excess')
                              GROUP BY INVENTORY_FLOW,
                                       SITE_CODE,
                                       ROHS_COMPLIANT) XRI,
                             (SELECT *
                                FROM RMKTGADM.RMK_INV_SITE_CODE_DTL
                               WHERE     (SELECT PROGRAM_TYPE
                                            FROM CRPADM.RC_PRODUCT_MASTER
                                           WHERE REFRESH_PART_NUMBER =
                                                 pid_rec.REFRESH_PART_NUMBER) =
                                         0
                                     AND INVENTORY_FLOW IN ('Retail', 'Outlet')
                              UNION
                              SELECT *
                                FROM RMKTGADM.RMK_INV_SITE_CODE_DTL
                               WHERE     (SELECT PROGRAM_TYPE
                                            FROM CRPADM.RC_PRODUCT_MASTER
                                           WHERE REFRESH_PART_NUMBER =
                                                 pid_rec.REFRESH_PART_NUMBER) =
                                         1
                                     AND INVENTORY_FLOW = 'Excess') RIS
                       WHERE     RIS.SITE_CODE = 'FVE'
                             AND RIS.SITE_CODE = XRI.SITE_CODE
                             AND RIS.ROHS_COMPLIANT = XRI.ROHS_COMPLIANT
                             AND RIS.INVENTORY_FLOW = XRI.INVENTORY_FLOW
                    ORDER BY INVENTORY_FLOW;

                    --            lv_increment := 0;
                    --            lv_rem_inventory := 0;
                    --            lv_flow := NULL;
                    lv_flag := 'yes';
                    lv_idx := 1;
                    item_left := 0;
                    -- US353135 start
                    mask_item_left := 0;
                    mask_item_used := 0;
                    reserved_item_left := 0;

                    SELECT COUNT (FVE_RHS_QUANTITY)
                      INTO V_MASK_ITEM_COUNT
                      FROM RC_INV_STR_INV_MASK_MV
                     WHERE PARTNUMBER = PID_REC.REFRESH_PART_NUMBER;

                    IF V_MASK_ITEM_COUNT > 0
                    THEN
                        SELECT NVL (FVE_RHS_QUANTITY, 0)
                          INTO mask_item_left
                          FROM RC_INV_STR_INV_MASK_MV
                         WHERE PARTNUMBER = PID_REC.REFRESH_PART_NUMBER;
                    END IF;

                    -- US353135 end
                    FOR rec IN c_fve_dtls (pid_rec.REFRESH_PART_NUMBER)
                    LOOP
                        lv_qty_to_transfer := 0;
                        lv_rem_qty := 0;
                        lv_quantity := rec.QUANTITY;
                        v_reserved_outlet := 0;                     --US353135
                        v_reserved_retail := 0;                     --US353135

                        FOR idx IN lv_idx .. lv_inventory_list.COUNT ()
                        LOOP
                            --US353135 changes start
                            IF (lv_inventory_list (idx).INVENTORY_FLOW =
                                'Outlet')
                            THEN
                                v_reserved_outlet :=
                                    lv_inventory_list (idx).RESERVED_QUANTITY;
                                v_ros_comp_outlet :=
                                    lv_inventory_list (idx).ROHS_COMPLIANT;
                                v_avaible_fgi_outlet :=
                                    lv_inventory_list (idx).AVAILABLE_QUANTITY;
                                v_reserved_fgi_outlet :=
                                    lv_inventory_list (idx).RESERVED_QUANTITY;
                                v_avaiable_to_reserv_outlet :=
                                    lv_inventory_list (idx).AVAILABLE_TO_RESERVE_QTY;
                            ELSIF (lv_inventory_list (idx).INVENTORY_FLOW =
                                   'Retail')
                            THEN
                                v_reserved_retail :=
                                    lv_inventory_list (idx).RESERVED_QUANTITY;
                                v_ros_comp_retail :=
                                    lv_inventory_list (idx).ROHS_COMPLIANT;
                                v_avaible_fgi_retail :=
                                    lv_inventory_list (idx).AVAILABLE_QUANTITY;
                                v_reserved_fgi_retail :=
                                    lv_inventory_list (idx).RESERVED_QUANTITY;
                                v_avaiable_to_reserv_retail :=
                                    lv_inventory_list (idx).AVAILABLE_TO_RESERVE_QTY;
                            END IF;

                            --US353135 changes end
                            IF     lv_flag = 'yes'
                               AND lv_inventory_list (idx).AVAILABLE_QUANTITY >=
                                   0
                            THEN
                                IF (lv_inventory_list (idx).INVENTORY_FLOW =
                                    'Excess')       --check added for US353135
                                THEN
                                    item_left :=
                                          item_left
                                        + lv_inventory_list (idx).AVAILABLE_QUANTITY;
                                ELSE
                                    item_left :=
                                          item_left
                                        + lv_inventory_list (idx).AVAILABLE_TO_RESERVE_QTY;
                                END IF;
                            END IF;

                            --                    CASE
                            --                        WHEN    (    rec.TRANSACTION_TYPE =
                            --                                     'NonNettable-2-Nettable'
                            --                                 AND lv_inventory_list (idx).INVENTORY_FLOW =
                            --                                     'Outlet')
                            --                             OR (lv_inventory_list (idx).AVAILABLE_QUANTITY <=
                            --                                 0)
                            --                             OR lv_quantity <= 0
                            --                             OR (    MOD( lv_increment, 2 ) = 1
                            --                                 AND lv_rem_inventory <= 0
                            --                                 AND lv_flow =
                            --                                     lv_inventory_list (idx).INVENTORY_FLOW)
                            --                             OR ( MOD( lv_increment, 2 ) = 0
                            --                                 AND lv_rem_inventory > 0
                            --                                 AND lv_flow <>
                            --                                     lv_inventory_list (idx).INVENTORY_FLOW)
                            --                        THEN
                            --                            CONTINUE;
                            --                        WHEN rec.TRANSACTION_TYPE = 'NonNettable-2-Nettable'
                            --                        THEN
                            --                            lv_qty_to_transfer := rec.QUANTITY;
                            --                            lv_quantity := 0;            --to track quantities
                            --                        WHEN lv_inventory_list (idx).AVAILABLE_QUANTITY <=
                            --                             lv_quantity
                            --                        THEN
                            --                            lv_qty_to_transfer :=
                            --                                lv_inventory_list (idx).AVAILABLE_QUANTITY;
                            --                            lv_rem_qty := lv_quantity - lv_qty_to_transfer;
                            --                            lv_rem_inventory := 0;
                            --                            lv_flow := lv_inventory_list (idx).INVENTORY_FLOW;
                            --                        WHEN lv_inventory_list (idx).AVAILABLE_QUANTITY >
                            --                             lv_quantity
                            --                        THEN
                            --                            lv_qty_to_transfer := lv_quantity;
                            --                            lv_rem_qty := 0;
                            --                            lv_rem_inventory :=
                            --                                  lv_inventory_list (idx).AVAILABLE_QUANTITY
                            --                                - lv_qty_to_transfer;
                            --                            lv_flow := lv_inventory_list (idx).INVENTORY_FLOW;
                            --                    END CASE;

                            CASE
                                WHEN    (    rec.TRANSACTION_TYPE =
                                             'NonNettable-2-Nettable'
                                         AND lv_inventory_list (idx).INVENTORY_FLOW =
                                             'Outlet')
                                     OR (lv_inventory_list (idx).AVAILABLE_QUANTITY <=
                                         0
                                         AND rec.TRANSACTION_TYPE =                  ---- added for PRB0067313
                                             'Nettable-2-NonNettable')
                                     OR (    lv_inventory_list (idx).AVAILABLE_QUANTITY <=
                                             0
                                         AND lv_inventory_list (idx).INVENTORY_FLOW = -- US353135
                                             'Retail'
                                         AND lv_quantity <= 0
                                         AND rec.TRANSACTION_TYPE =                   -- added for PRB0067313
                                             'Nettable-2-NonNettable')
                                     OR (    lv_inventory_list (idx).AVAILABLE_QUANTITY <=
                                             0
                                         AND lv_inventory_list (idx).INVENTORY_FLOW = -- US353135
                                             'Retail'
                                         AND lv_quantity > 0
                                         AND mask_item_left <= 0
                                         AND rec.TRANSACTION_TYPE =                   -- added for PRB0067313
                                             'Nettable-2-NonNettable')
                                     OR (    lv_inventory_list (idx).AVAILABLE_QUANTITY <= -- US353135
                                             0
                                         AND lv_inventory_list (idx).INVENTORY_FLOW IN
                                                 ('Outlet', 'Excess')
                                        AND rec.TRANSACTION_TYPE =                    -- added for PRB0067313
                                             'Nettable-2-NonNettable')
                                     OR lv_quantity <= 0
                                THEN
                                    CONTINUE;
                                WHEN rec.TRANSACTION_TYPE =
                                     'NonNettable-2-Nettable'
                                THEN
                                    lv_qty_to_transfer := rec.QUANTITY;
                                    lv_quantity := 0;    --to track quantities
                                /*WHEN item_left < lv_quantity
                                THEN
                                    lv_flag := 'yes';
                                    lv_qty_to_transfer := item_left;
                                    lv_rem_qty := lv_quantity - lv_qty_to_transfer;
                                    item_left := 0;
                                    lv_idx := lv_idx + 1;*/
                                WHEN (    lv_inventory_list (idx).AVAILABLE_QUANTITY <= -- Condition added for US353135
                                          0
                                      AND lv_inventory_list (idx).INVENTORY_FLOW =
                                          'Retail'
                                      AND lv_quantity > 0)
                                THEN
                                    IF (mask_item_left >= lv_quantity) -- IF MASK IS > = REMAINING TRANSFER
                                    THEN
                                        mask_item_left :=
                                            mask_item_left - lv_quantity;
                                        mask_item_used := lv_quantity;
                                        lv_quantity := 0;  --to track quantity
                                        CONTINUE;
                                    ELSE
                                        lv_rem_qty :=
                                            lv_quantity - mask_item_left;
                                        mask_item_used := mask_item_left;
                                        mask_item_left := 0;
                                        lv_quantity := lv_rem_qty;
                                        CONTINUE;
                                    END IF;
                                WHEN item_left < lv_quantity
                                THEN
                                    lv_flag := 'yes';
                                    lv_qty_to_transfer := item_left;
                                    item_left := 0;
                                    lv_idx := lv_idx + 1;

                                    IF (    mask_item_left > 0
                                        AND lv_inventory_list (idx).INVENTORY_FLOW =
                                            'Retail') --(condition added for US353135 )
                                    THEN
                                        IF (mask_item_left >=
                                            lv_quantity - lv_qty_to_transfer) -- IF MASK IS > = REMAINING TRANSFER
                                        THEN
                                            mask_item_left :=
                                                  mask_item_left
                                                - (  lv_quantity
                                                   - lv_qty_to_transfer);
                                            mask_item_used :=
                                                  lv_quantity
                                                - lv_qty_to_transfer;
                                            lv_rem_qty := 0;
                                            lv_flag := 'no';
                                        ELSE
                                            lv_rem_qty :=
                                                  lv_quantity
                                                - (  lv_qty_to_transfer
                                                   + mask_item_left);
                                            mask_item_used := mask_item_left;
                                            mask_item_left := 0;
                                        END IF;
                                    ELSE -- IF THERE IS NO MASK QYT and its 'outlet'/'excess'
                                        lv_rem_qty :=
                                            lv_quantity - lv_qty_to_transfer;
                                    END IF;
                                WHEN item_left > lv_quantity
                                THEN
                                    lv_flag := 'no';
                                    lv_qty_to_transfer := lv_quantity;
                                    lv_rem_qty := 0;
                                    item_left :=
                                        item_left - lv_qty_to_transfer;
                                WHEN item_left = lv_quantity
                                THEN
                                    lv_flag := 'yes';
                                    lv_qty_to_transfer := item_left;
                                    lv_rem_qty :=
                                        lv_quantity - lv_qty_to_transfer;
                                    item_left := 0;
                                    lv_idx := lv_idx + 1;
                            END CASE;

                            lv_quantity := lv_rem_qty;

                            INSERT INTO RMK_ADMINUI_INVTRANSFER (
                                            REQUEST_ID,
                                            PART_NUMBER,
                                            INVENTORY_ITEM_ID,
                                            TRANSACTION_TYPE,
                                            FROM_PROGRAM_TYPE,
                                            TO_PROGRAM_TYPE,
                                            ROHS_CHECK_FLAG,
                                            MOS,
                                            RETAIL_MAX,
                                            OUTLET_CAP,
                                            AVG_SALE_PRICE_YTD,
                                            SITE_CODE,
                                            ROHS_COMPLIANT_FLAG,
                                            SRC_AVAIL_QTY,
                                            SRC_RESERVED_QTY,
                                            SRC_AVAIL_TO_RESERVE,
                                            TRG_AVAIL_QTY,
                                            TRG_RESERVED_QTY,
                                            TRG_AVAIL_TO_RESERVE,
                                            QTY_TO_TRANSFER,
                                            QTY_TO_PROCESS,
                                            COMMENTS,
                                            ATTRIBUTE1,
                                            ATTRIBUTE2,
                                            REQUESTED_BY,
                                            REQUESTED_DATE,
                                            APPROVED_BY,
                                            APPROVED_DATE,
                                            APROVAL_STATUS,
                                            PROCESS_STATUS,
                                            LAST_UPDATED_BY,
                                            LAST_UPDATED_DATE,
                                            CREATED_BY,
                                            CREATED_DATE,
                                            ADDITIONAL_COMMENTS,
                                            C3_ONHAND_QTY,
                                            FROM_SUBINV,
                                            TO_SUBINV)
                                     VALUES (
                                                RMK_ADMINUI_SEQ.NEXTVAL,
                                                lv_refresh_part_number,
                                                NULL,
                                                rec.TRANSACTION_TYPE,
                                                lv_inventory_list (idx).INVENTORY_FLOW,
                                                NULL,
                                                lv_rohs_check_needed,
                                                lv_mos,
                                                lv_retail_max,
                                                lv_outlet_cap,
                                                lv_ytd_avg_sales_price,
                                                lv_inventory_list (idx).SITE_CODE,
                                                lv_inventory_list (idx).ROHS_COMPLIANT,
                                                lv_inventory_list (idx).AVAILABLE_QUANTITY,
                                                lv_inventory_list (idx).RESERVED_QUANTITY,
                                                lv_inventory_list (idx).AVAILABLE_TO_RESERVE_QTY,
                                                NULL,
                                                NULL,
                                                NULL,
                                                lv_qty_to_transfer,
                                                lv_qty_to_transfer,
                                                NULL,
                                                NULL,
                                                NULL,
                                                'RC_FVE_INV_MOVE_AUTOMATION',
                                                SYSDATE,
                                                'RC_FVE_INV_MOVE_AUTOMATION',
                                                SYSDATE,
                                                'AUTO APPROVED',
                                                'APPROVED',
                                                'RC_FVE_INV_MOVE_AUTOMATION',
                                                SYSDATE,
                                                'RC_FVE_INV_MOVE_AUTOMATION',
                                                SYSDATE,
                                                rec.FVE_TRANSFER_ORDER,
                                                NULL,
                                                NULL,
                                                NULL);
                        END LOOP;

                        -- US353135 start
                        --if after adjusting AVAILABLE_TO_RESERVE_FGI and Mask_qyt the lv_quantity>0 adjust the RESERVED_FGI
                        IF (lv_quantity > 0)
                        THEN
                            --adjusting the RESERVED_FGI of outlet
                            IF (v_reserved_outlet > 0)
                            THEN
                                CASE
                                    WHEN v_reserved_outlet < lv_quantity
                                    THEN
                                        lv_qty_to_transfer :=
                                            v_reserved_outlet;
                                        lv_rem_qty :=
                                            lv_quantity - lv_qty_to_transfer;
                                        v_reserved_outlet := 0;
                                    WHEN v_reserved_outlet > lv_quantity
                                    THEN
                                        lv_qty_to_transfer := lv_quantity;
                                        lv_rem_qty := 0;
                                        v_reserved_outlet :=
                                              v_reserved_outlet
                                            - lv_qty_to_transfer;
                                    WHEN v_reserved_outlet = lv_quantity
                                    THEN
                                        lv_qty_to_transfer :=
                                            v_reserved_outlet;
                                        v_reserved_outlet := 0;
                                        lv_rem_qty :=
                                            lv_quantity - v_reserved_outlet;
                                END CASE;

                                INSERT INTO RMK_ADMINUI_INVTRANSFER (
                                                REQUEST_ID,
                                                PART_NUMBER,
                                                INVENTORY_ITEM_ID,
                                                TRANSACTION_TYPE,
                                                FROM_PROGRAM_TYPE,
                                                TO_PROGRAM_TYPE,
                                                ROHS_CHECK_FLAG,
                                                MOS,
                                                RETAIL_MAX,
                                                OUTLET_CAP,
                                                AVG_SALE_PRICE_YTD,
                                                SITE_CODE,
                                                ROHS_COMPLIANT_FLAG,
                                                SRC_AVAIL_QTY,
                                                SRC_RESERVED_QTY,
                                                SRC_AVAIL_TO_RESERVE,
                                                TRG_AVAIL_QTY,
                                                TRG_RESERVED_QTY,
                                                TRG_AVAIL_TO_RESERVE,
                                                QTY_TO_TRANSFER,
                                                QTY_TO_PROCESS,
                                                COMMENTS,
                                                ATTRIBUTE1,
                                                ATTRIBUTE2,
                                                REQUESTED_BY,
                                                REQUESTED_DATE,
                                                APPROVED_BY,
                                                APPROVED_DATE,
                                                APROVAL_STATUS,
                                                PROCESS_STATUS,
                                                LAST_UPDATED_BY,
                                                LAST_UPDATED_DATE,
                                                CREATED_BY,
                                                CREATED_DATE,
                                                ADDITIONAL_COMMENTS,
                                                C3_ONHAND_QTY,
                                                FROM_SUBINV,
                                                TO_SUBINV)
                                     VALUES (RMK_ADMINUI_SEQ.NEXTVAL,
                                             lv_refresh_part_number,
                                             NULL,
                                             rec.TRANSACTION_TYPE,
                                             'Outlet',
                                             NULL,
                                             lv_rohs_check_needed,
                                             lv_mos,
                                             lv_retail_max,
                                             lv_outlet_cap,
                                             lv_ytd_avg_sales_price,
                                             'FVE',
                                             v_ros_comp_outlet,
                                             v_avaible_fgi_outlet,
                                             v_reserved_fgi_outlet,
                                             v_avaiable_to_reserv_outlet,
                                             NULL,
                                             NULL,
                                             NULL,
                                             lv_qty_to_transfer,
                                             lv_qty_to_transfer,
                                             NULL,
                                             NULL,
                                             NULL,
                                             'RC_FVE_INV_MOVE_AUTOMATION',
                                             SYSDATE,
                                             'RC_FVE_INV_MOVE_AUTOMATION',
                                             SYSDATE,
                                             'AUTO APPROVED',
                                             'APPROVED',
                                             'RC_FVE_INV_MOVE_AUTOMATION',
                                             SYSDATE,
                                             'RC_FVE_INV_MOVE_AUTOMATION',
                                             SYSDATE,
                                             rec.FVE_TRANSFER_ORDER,
                                             NULL,
                                             NULL,
                                             NULL);
                            END IF;

                            lv_quantity := lv_rem_qty;

                            --adjusting the RESERVED_FGI of retail
                            IF (lv_rem_qty > 0 AND v_reserved_retail > 0)
                            THEN
                                CASE
                                    WHEN v_reserved_retail < lv_quantity
                                    THEN
                                        lv_qty_to_transfer :=
                                            v_reserved_retail;
                                        lv_rem_qty :=
                                            lv_quantity - lv_qty_to_transfer;
                                        v_reserved_retail := 0;
                                    WHEN v_reserved_retail > lv_quantity
                                    THEN
                                        lv_qty_to_transfer := lv_quantity;
                                        lv_rem_qty := 0;
                                        v_reserved_retail :=
                                              v_reserved_retail
                                            - lv_qty_to_transfer;
                                    WHEN v_reserved_retail = lv_quantity
                                    THEN
                                        lv_qty_to_transfer :=
                                            v_reserved_retail;
                                        v_reserved_retail := 0;
                                        lv_rem_qty :=
                                            lv_quantity - v_reserved_retail;
                                END CASE;

                                INSERT INTO RMK_ADMINUI_INVTRANSFER (
                                                REQUEST_ID,
                                                PART_NUMBER,
                                                INVENTORY_ITEM_ID,
                                                TRANSACTION_TYPE,
                                                FROM_PROGRAM_TYPE,
                                                TO_PROGRAM_TYPE,
                                                ROHS_CHECK_FLAG,
                                                MOS,
                                                RETAIL_MAX,
                                                OUTLET_CAP,
                                                AVG_SALE_PRICE_YTD,
                                                SITE_CODE,
                                                ROHS_COMPLIANT_FLAG,
                                                SRC_AVAIL_QTY,
                                                SRC_RESERVED_QTY,
                                                SRC_AVAIL_TO_RESERVE,
                                                TRG_AVAIL_QTY,
                                                TRG_RESERVED_QTY,
                                                TRG_AVAIL_TO_RESERVE,
                                                QTY_TO_TRANSFER,
                                                QTY_TO_PROCESS,
                                                COMMENTS,
                                                ATTRIBUTE1,
                                                ATTRIBUTE2,
                                                REQUESTED_BY,
                                                REQUESTED_DATE,
                                                APPROVED_BY,
                                                APPROVED_DATE,
                                                APROVAL_STATUS,
                                                PROCESS_STATUS,
                                                LAST_UPDATED_BY,
                                                LAST_UPDATED_DATE,
                                                CREATED_BY,
                                                CREATED_DATE,
                                                ADDITIONAL_COMMENTS,
                                                C3_ONHAND_QTY,
                                                FROM_SUBINV,
                                                TO_SUBINV)
                                     VALUES (RMK_ADMINUI_SEQ.NEXTVAL,
                                             lv_refresh_part_number,
                                             NULL,
                                             rec.TRANSACTION_TYPE,
                                             'Retail',
                                             NULL,
                                             lv_rohs_check_needed,
                                             lv_mos,
                                             lv_retail_max,
                                             lv_outlet_cap,
                                             lv_ytd_avg_sales_price,
                                             'FVE',
                                             v_ros_comp_retail,
                                             v_avaible_fgi_retail,
                                             v_reserved_fgi_retail,
                                             v_avaiable_to_reserv_retail,
                                             NULL,
                                             NULL,
                                             NULL,
                                             lv_qty_to_transfer,
                                             lv_qty_to_transfer,
                                             NULL,
                                             NULL,
                                             NULL,
                                             'RC_FVE_INV_MOVE_AUTOMATION',
                                             SYSDATE,
                                             'RC_FVE_INV_MOVE_AUTOMATION',
                                             SYSDATE,
                                             'AUTO APPROVED',
                                             'APPROVED',
                                             'RC_FVE_INV_MOVE_AUTOMATION',
                                             SYSDATE,
                                             'RC_FVE_INV_MOVE_AUTOMATION',
                                             SYSDATE,
                                             rec.FVE_TRANSFER_ORDER,
                                             NULL,
                                             NULL,
                                             NULL);
                            END IF;

                            lv_quantity := lv_rem_qty;
                        END IF;

                        -- US353135 end
                        IF lv_quantity < rec.QUANTITY
                        THEN
                            UPDATE RC_FVE_INV_MOVEMENTS_STG
                               SET PROCESS_STATUS = 'PROCESSED',
                                   UPDATED_DATE = SYSDATE,
                                   UPDATED_BY = 'RC_FVE_INV_MOVE_AUTOMATION'
                             WHERE     TAN_NUMBER = rec.TAN_NUMBER
                                   AND FVE_TRANSFER_ORDER =
                                       rec.FVE_TRANSFER_ORDER
                                   AND TRANSACTION_DATE =
                                       rec.TRANSACTION_DATE
                                   AND QUANTITY = rec.QUANTITY
                                   AND TRANSACTION_TYPE =
                                       rec.TRANSACTION_TYPE
                                   AND REFRESH_PART_NUMBER =
                                       rec.REFRESH_PART_NUMBER
                                   AND PROCESS_STATUS = 'NOT PROCESSED'
                                   AND CREATED_DATE = rec.CREATED_DATE
                                   AND CREATED_BY = rec.CREATED_BY;

                            UPDATE RC_FVE_INV_MOVEMENTS
                               SET PROCESS_STATUS = 'PROCESSED'
                             WHERE     TAN_NUMBER = rec.TAN_NUMBER
                                   AND FVE_TRANSFER_ORDER =
                                       rec.FVE_TRANSFER_ORDER
                                   AND TRANSACTION_DATE =
                                       rec.TRANSACTION_DATE
                                   AND QUANTITY = rec.QUANTITY
                                   AND TRANSACTION_TYPE =
                                       rec.TRANSACTION_TYPE
                                   AND PROCESS_STATUS = 'NOT PROCESSED'
                                   AND CREATED_DATE = rec.CREATED_DATE
                                   AND CREATED_BY = rec.CREATED_BY;
                        END IF;

                        INSERT INTO RC_FVE_INV_MOVEMENTS_HIST
                            SELECT TAN_NUMBER,
                                   FVE_TRANSFER_ORDER,
                                   TRANSACTION_DATE,
                                   QUANTITY,
                                   TRANSACTION_TYPE,
                                   PROCESS_STATUS,
                                   CREATED_DATE,
                                   CREATED_BY,
                                   CASE
                                       WHEN lv_quantity = rec.QUANTITY
                                       THEN
                                           0
                                       WHEN lv_quantity = 0
                                       THEN
                                           rec.QUANTITY
                                       WHEN lv_quantity < rec.QUANTITY
                                       THEN
                                           rec.QUANTITY - lv_quantity
                                   END
                                       QTY_TRANSFERRED,
                                   SYSDATE
                              FROM RC_FVE_INV_MOVEMENTS
                             WHERE     TAN_NUMBER = rec.TAN_NUMBER
                                   AND FVE_TRANSFER_ORDER =
                                       rec.FVE_TRANSFER_ORDER
                                   AND TRANSACTION_DATE =
                                       rec.TRANSACTION_DATE
                                   AND QUANTITY = rec.QUANTITY
                                   AND TRANSACTION_TYPE =
                                       rec.TRANSACTION_TYPE
                                   AND PROCESS_STATUS = 'PROCESSED'
                                   AND CREATED_DATE = rec.CREATED_DATE
                                   AND CREATED_BY = rec.CREATED_BY;

                        --                IF rec.TRANSACTION_TYPE = 'Nettable-2-NonNettable'
                        --                THEN
                        --                    lv_increment := lv_increment + 1;
                        --                END IF;
                        ---- US353135
                        IF (mask_item_used > 0)
                        THEN
                            INSERT INTO RC_INV_STR_INV_MASK_STG (
                                            PARTNUMBER,
                                            SITE,
                                            ROHS,
                                            MASKED_QTY,
                                            CREATED_BY,
                                            CREATED_AT,
                                            PROCESSED_STATUS)
                                 VALUES (lv_refresh_part_number,
                                         'FVE',
                                         'YES',
                                         mask_item_used,
                                         'FVE',
                                         SYSDATE,
                                         'N');
                        END IF;
                    -- US353135
                    END LOOP;

                    COMMIT;
                ELSE
                    INSERT INTO RC_FVE_INV_MOV_INVALID_PIDS (TAN_NUMBER,
                                                             ERROR_MSG)
                             VALUES (
                                        pid_rec.REFRESH_PART_NUMBER,
                                        'NOT PRESENT IN XXCPO_RMK_INVENTORY_MASTER');

                    COMMIT;

                    FOR rec IN c_fve_dtls (pid_rec.REFRESH_PART_NUMBER)
                    LOOP
                        INSERT INTO RC_FVE_INV_MOVEMENTS_HIST
                            SELECT TAN_NUMBER,
                                   FVE_TRANSFER_ORDER,
                                   TRANSACTION_DATE,
                                   QUANTITY,
                                   TRANSACTION_TYPE,
                                   PROCESS_STATUS,
                                   CREATED_DATE,
                                   CREATED_BY,
                                   QUANTITY,
                                   SYSDATE
                              FROM RC_FVE_INV_MOVEMENTS
                             WHERE     TAN_NUMBER = rec.TAN_NUMBER
                                   AND FVE_TRANSFER_ORDER =
                                       rec.FVE_TRANSFER_ORDER
                                   AND TRANSACTION_DATE =
                                       rec.TRANSACTION_DATE
                                   AND QUANTITY = rec.QUANTITY
                                   AND TRANSACTION_TYPE =
                                       rec.TRANSACTION_TYPE
                                   AND PROCESS_STATUS = rec.PROCESS_STATUS
                                   AND CREATED_DATE = rec.CREATED_DATE
                                   AND CREATED_BY = rec.CREATED_BY;
                    END LOOP;
                END IF;
            END LOOP;

            COMMIT;

            BEGIN
                SELECT COUNT (*)
                  INTO V_PROCESS_COUNT
                  FROM RC_FVE_INV_MOVEMENTS
                 WHERE PROCESS_STATUS = 'PROCESSED';

                IF (V_PROCESS_COUNT > 0)
                THEN
                    INSERT INTO RMK_INVENTORY_LOG (INVENTORY_LOG_ID,
                                                   PART_NUMBER,
                                                   NEW_FGI,
                                                   ROHS_COMPLIANT,
                                                   SITE_CODE,
                                                   PROCESS_STATUS,
                                                   UPDATED_BY,
                                                   UPDATED_ON,
                                                   CREATED_BY,
                                                   CREATED_ON,
                                                   POE_BATCH_ID,
                                                   PROGRAM_TYPE)
                        SELECT RC_INV_LOG_PK_SEQ.NEXTVAL,
                               PART_NUMBER,
                               CASE
                                   WHEN TRANSACTION_TYPE =
                                        'Nettable-2-NonNettable'
                                   THEN
                                       -QTY_TO_TRANSFER
                                   WHEN TRANSACTION_TYPE =
                                        'NonNettable-2-Nettable'
                                   THEN
                                       QTY_TO_TRANSFER
                               END
                                   QTY_TO_TRANSFER,
                               ROHS_COMPLIANT_FLAG,
                               SITE_CODE,
                               'N',
                               'RC_FVE_INV_MOVE_AUTOMATION',
                               SYSDATE,
                               'RC_FVE_INV_MOVE_AUTOMATION',
                               SYSDATE,
                               'ADMINUI_' || REQUEST_ID,
                               SUBSTR (FROM_PROGRAM_TYPE, 1, 1)
                          FROM RMK_ADMINUI_INVTRANSFER
                         WHERE     TRANSACTION_TYPE IN
                                       ('NonNettable-2-Nettable',
                                        'Nettable-2-NonNettable')
                               AND TO_CHAR (REQUESTED_DATE, 'MM-DD-YYYY') =
                                   TO_CHAR (SYSDATE, 'MM-DD-YYYY'); --only the present day record gets inserted
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_message := SUBSTR (SQLERRM, 1, 200);

                    UPDATE RMK_ADMINUI_INVTRANSFER
                       SET PROCESS_STATUS = 'ERROR'
                     WHERE REQUEST_ID NOT IN
                               (SELECT SUBSTR (POE_BATCH_ID, 9) REQUEST_ID
                                  FROM RMK_INVENTORY_LOG
                                 WHERE     PROCESS_STATUS = 'N'
                                       AND UPDATED_BY =
                                           'RC_FVE_INV_MOVE_AUTOMATION');

                    P_RCEC_ERROR_LOG (
                        I_module_name =>
                            'RC_FVE_INV_MOVE_AUTOMATION',
                        I_entity_name =>
                            NULL,
                        I_entity_id =>
                            NULL,
                        I_ext_entity_name =>
                            NULL,
                        I_ext_entity_id =>
                            NULL,
                        I_error_type =>
                            'EXCEPTION',
                        i_Error_Message =>
                               'Error while executing RC_FVE_INV_MOVE_AUTOMATION at: '
                            || v_message
                            || ' LineNo=> '
                            || DBMS_UTILITY.Format_error_backtrace,
                        I_created_by =>
                            'RC_FVE_INV_MOVE_AUTOMATION',
                        I_updated_by =>
                            'RC_FVE_INV_MOVE_AUTOMATION');
            END;

            COMMIT;

            DELETE RC_FVE_INV_MOVEMENTS
             WHERE PROCESS_STATUS = 'PROCESSED';

            COMMIT;
        END IF;

        INSERT INTO CRPADM.RC_PROCESS_LOG
             VALUES (CRPADM.PROCESS_ID_SEQ.NEXTVAL,
                     'RC_FVE_INV_MOVE_AUTOMATION',
                     'END',
                     SYSDATE);

        COMMIT;

        -- US353135
        -- CALL CRPADM.RC_STR_INV_MASK_ADJ
        SELECT COUNT (*)
          INTO MASK_QYT_TO_PROCESS
          FROM RC_INV_STR_INV_MASK_STG
         WHERE CREATED_BY = 'FVE' AND PROCESSED_STATUS = 'N';

        IF MASK_QYT_TO_PROCESS > 0
        THEN
            RC_STR_INV_MASK_ADJ ('FVE', adg_status);
        END IF;
    -- US353135
    EXCEPTION
        WHEN OTHERS
        THEN
            v_message := SUBSTR (SQLERRM, 1, 50);

            P_RCEC_ERROR_LOG (
                I_module_name =>
                    'RC_FVE_INV_MOVE_AUTOMATION',
                I_entity_name =>
                    NULL,
                I_entity_id =>
                    NULL,
                I_ext_entity_name =>
                    NULL,
                I_ext_entity_id =>
                    NULL,
                I_error_type =>
                    'EXCEPTION',
                i_Error_Message =>
                       'Error while executing RC_FVE_INV_MOVE_AUTOMATION at: '
                    || v_message
                    || ' LineNo=> '
                    || DBMS_UTILITY.Format_error_backtrace,
                I_created_by =>
                    'RC_FVE_INV_MOVE_AUTOMATION',
                I_updated_by =>
                    'RC_FVE_INV_MOVE_AUTOMATION');
    END RC_FVE_INV_MOVE_AUTOMATION;
/* US223935-Automation of daily FVE inventory movements - Phase 2 changes Ends*/

END RMK_INV_TRANSFER_PKG;
/