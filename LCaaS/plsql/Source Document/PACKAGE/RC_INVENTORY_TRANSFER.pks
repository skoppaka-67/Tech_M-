CREATE OR REPLACE PACKAGE CRPSC./*AppDB: 1029859*/         "RC_INVENTORY_TRANSFER" 
AS
   g_error_msg   VARCHAR2 (2000) := NULL;

   PROCEDURE RC_INV_TRANSFER_ENGINE;

   PROCEDURE RC_FETCH_INV_SETUP_DROPDOWNS (
      i_user_id                 IN     VARCHAR2,
      o_refresh_method_list        OUT RC_REFRESH_METHOD_LIST,
      o_theater_list               OUT RC_INV_THEATER_LIST,
      o_zlocation_list             OUT RC_ZLOCATION_LIST,
      o_sub_inv_location_list      OUT RC_SUB_INV_LOCATION_LIST,
      o_program_type_list          OUT RC_INV_THEATER_LIST);

  PROCEDURE RC_FETCH_INV_SETUP_DETAILS (
      i_user_id                      IN     VARCHAR2,
      i_src_zlocation                IN     VARCHAR2,
      i_dest_zlocation               IN     VARCHAR2,
      i_status                       IN     VARCHAR2,
      i_sort_column                  IN     VARCHAR2,
      i_sort_by                      IN     VARCHAR2,
      o_inventory_setup_rules_list      OUT RC_INVENTORY_SETUP_RULES_LIST);

   PROCEDURE RC_ADD_INV_SETUP_DETAILS (
      i_user_id                      IN     VARCHAR2,
      i_src_zlocation                IN     VARCHAR2,
      i_dest_zlocation               IN     VARCHAR2,
      i_status                       IN     VARCHAR2,
      i_inventory_setup_rules_list   IN     RC_INVENTORY_SETUP_RULES_LIST,
      o_inventory_setup_rules_list      OUT RC_INVENTORY_SETUP_RULES_LIST);

   PROCEDURE RC_UPDATE_INV_SETUP_DETAILS (
      i_user_id                      IN     VARCHAR2,
      i_src_zlocation                IN     VARCHAR2,
      i_dest_zlocation               IN     VARCHAR2,
      i_status                       IN     VARCHAR2,
      i_inventory_setup_rules_list   IN     RC_INVENTORY_SETUP_RULES_LIST,
      o_inventory_setup_rules_list      OUT RC_INVENTORY_SETUP_RULES_LIST);

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
      o_date                             OUT TIMESTAMP);

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
      o_date                             OUT TIMESTAMP);


   PROCEDURE RC_FETCH_INV_RPT_UNQ_FILTERS (
       i_user_id                       IN     VARCHAR2,
       i_product                       IN     VARCHAR2,
      i_src_zlocation                 IN     VARCHAR2,
      i_dest_zlocation                IN     VARCHAR2,
      i_sub_inv_location              IN     VARCHAR2,
      i_filter_column_name            IN     VARCHAR2,
      i_filter_list                   IN     RC_NEW_FILTER_OBJ_LIST,
      o_inventory_transfer_rpt_list      OUT RC_ADDL_FILTERS_LIST);
      
      PROCEDURE GET_IN_CONDITION_FOR_QUERY (
      i_filter_list           RC_NEW_FILTER_OBJ_LIST,
      i_in_query              OUT CLOB);
END RC_INVENTORY_TRANSFER;
/