CREATE OR REPLACE PACKAGE RMKTGADM./*AppDB: 1032174*/
                                                                                                 "RC_INV_INTRANS_SHIPMENTS"
AS
   /*
  ****************************************************************************************************************
  * Object Name       :RC_INV_INTRANS_SHIPMENTS
  *  Project Name : Refresh Central
   * Copy Rights:   Cisco Systems, INC., CALIFORNIA
  * Description       : This API for Inventory Adjustment reconcialiation
  * Created Date: 2nd May, 2017
  ===================================================================================================+
  * Version              Date                     Modified by                     Description
  ===================================================================================================+
   1.0                   07th Nov, 2017            sridvasu                     Created for Intransit Shipments Report.
   1.1                   21st Mar. 2017            sridvasu                     Created new procedure to send email for Aged Orders
   1.2                   10th Jul, 2020            jhegdeka                     US198778 - Added new procedure PROCEDURE P_RC_INSERT_SONSORDER_STG_HIST and 
                                                                                 new input params for procedures P_RC_INV_FROM_TO_ORG_SUBINV and P_RC_INV_INTRANS_SHIP_LOAD_UI

  ===================================================================================================+
   **************************************************************************************************************** */

   PROCEDURE P_RC_ERROR_LOG (i_Module_Name        VARCHAR2,
                             i_Entity_Name        VARCHAR2 DEFAULT NULL,
                             i_Entity_ID          VARCHAR2 DEFAULT NULL,
                             i_EXT_Entity_Name    VARCHAR2 DEFAULT NULL,
                             i_EXT_Entity_ID      VARCHAR2 DEFAULT NULL,
                             i_Error_Type         VARCHAR2,
                             i_Error_Message      VARCHAR2,
                             i_Created_by         VARCHAR2,
                             i_UPDATED_BY         VARCHAR2);

   PROCEDURE P_RC_INV_INTRANS_SHIPMTS_LOAD;

   PROCEDURE RC_INV_MAIN;

   PROCEDURE P_RC_INV_FROM_TO_ORG_SUBINV (
      O_FROM_ORG             OUT T_FROM_ORG_TBL,
      O_TO_ORG               OUT T_TO_ORG_TBL,
      O_TO_SUBINV            OUT T_TO_SUBINV_TBL,
      --US198778 New Code Start
      O_FROM_SUBINV          OUT T_FROM_SUBINV_TBL,
      O_FREIGHT_CODE         OUT T_FREIGHT_CODE_TBL,
      O_ORDER_TYPE           OUT T_ORDER_TYPE_TBL, 
      --US198778 New Code End
      o_report_run_message   OUT VARCHAR2);

   PROCEDURE P_RC_INV_INTRANS_SHIP_LOAD_UI (
      i_part_number                              VARCHAR2,
      i_order_number                             VARCHAR2,
      i_shipment_number                          VARCHAR2,
      i_from_org                                 VARCHAR2,
      i_to_org                                   VARCHAR2,
      i_to_subinv                                VARCHAR2,
      i_aged_order                               VARCHAR2,
      --US198778 New Code Start
      i_order_type                               VARCHAR2,
      i_from_subinv                              VARCHAR2,
      i_freight_code                             VARCHAR2,
      i_shipped_date_from                        VARCHAR2,
      i_shipped_date_to                          VARCHAR2,
      i_expected_received_date_from              VARCHAR2,
      i_expected_received_date_to                VARCHAR2,
      --US198778 New Code End
      i_min_row                                  NUMBER,
      i_max_row                                  NUMBER,
      i_sort_column_name                         VARCHAR2,
      i_sort_column_by                           VARCHAR2,
      o_inv_intrans_shipmts           OUT NOCOPY RC_INV_INTRANS_SHIPMTS_TAB,
      o_inv_intrans_shipmts_data      OUT NOCOPY RC_INV_INTRANS_SHIPMTS_TAB,
      o_count                         OUT NOCOPY NUMBER);

   PROCEDURE P_RC_INV_INTRANS_SHIP_UPDATE (
      i_input_comments       RC_INV_INTRANS_SHIPMTS_TAB,
      i_user_id              VARCHAR2,
      error_status       OUT VARCHAR2);

   PROCEDURE P_RC_INTRANS_AGED_ORDERS_MAIL;
   
   --US198778 New Code Start
   PROCEDURE P_RC_INSERT_SONSORDER_STG_HIST;
   --US198778 New Code End

   v_message   VARCHAR2 (32767);
   v_start_date DATE;       --US198778 New Variable Added
END RC_INV_INTRANS_SHIPMENTS;
/