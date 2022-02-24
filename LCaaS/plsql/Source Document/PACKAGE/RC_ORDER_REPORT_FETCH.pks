CREATE OR REPLACE PACKAGE CRPREP./*AppDB: 1039356*/          "RC_ORDER_REPORT_FETCH" 
IS
   PROCEDURE RC_HISTORY_DETAILS_EXTRACT (
      i_user_id              IN     VARCHAR2,
      i_min_row              IN     NUMBER,
      i_max_row              IN     NUMBER,
      --advance fitlers start
      i_fiscal_year          IN     VARCHAR2,
      i_part_number          IN     VARCHAR2,
      i_order_status         IN     VARCHAR2,
      i_order_number         IN     VARCHAR2,
      i_end_customer_name    IN     VARCHAR2,
      i_theater              IN     VARCHAR2,
      --advance fitlers end
      i_sort_column_name     IN     VARCHAR2,
      i_sort_column_by       IN     VARCHAR2,
      i_filter_list          IN     RC_NEW_FILTER_OBJ_LIST,
      o_data_fetch_list         OUT ORDER_DETAILS_LIST,
      o_total_record_count      OUT NUMBER,
      o_load_date               OUT VARCHAR2,
      o_status                  OUT VARCHAR2,
      o_booked_orders           OUT NUMBER);

   PROCEDURE RC_ORDER_DETAILS_EXTRACT (
      i_user_id              IN     VARCHAR2,
      i_min_row              IN     NUMBER,
      i_max_row              IN     NUMBER,
      --advance fitlers start
      i_part_number          IN     VARCHAR2,
      i_order_status         IN     VARCHAR2,
      i_order_number         IN     VARCHAR2,
      i_end_customer_name    IN     VARCHAR2,
      i_theater              IN     VARCHAR2,
      i_order_line_amount    IN     VARCHAR2, -- Added by obarbier for 25k filter
      --advance fitlers end
      i_sort_column_name     IN     VARCHAR2,
      i_sort_column_by       IN     VARCHAR2,
      i_filter_list          IN     RC_NEW_FILTER_OBJ_LIST,
      o_data_fetch_list         OUT ORDER_DETAILS_HIST_LIST,
      o_total_record_count      OUT NUMBER,
      o_load_date               OUT VARCHAR2,
      o_status                  OUT VARCHAR2,
      o_booked_orders           OUT NUMBER);

   PROCEDURE GET_UNIQUE_ORDER_RPT_FILTERS (
      i_user_id        IN     VARCHAR2,
      i_column_name    IN     VARCHAR2,
      i_filter_list    IN     RC_NEW_FILTER_OBJ_LIST,
      o_unique_value      OUT T_NORMALISED_LIST,
      o_status            OUT NUMBER);

   PROCEDURE GET_FILTERS_IN_QUERY (
      i_filter_list   IN     RC_NEW_FILTER_OBJ_LIST,
      i_table_name    IN     VARCHAR2,
      o_in_query         OUT CLOB);

   PROCEDURE RC_ORDER_DETAILS_FILTERS (
      i_user_id          IN     VARCHAR2,
      o_order_stauts        OUT T_NORMALISED_LIST,
      o_theater             OUT T_NORMALISED_LIST,
      o_fiscal_quarter      OUT T_NORMALISED_LIST,
      o_status              OUT NUMBER);

   PROCEDURE RC_CCW_BACKLOG_FILTERS (
      i_user_id          IN     VARCHAR2,
      o_order_stauts        OUT T_NORMALISED_LIST,
      o_theater             OUT T_NORMALISED_LIST,
      o_fiscal_quarter      OUT T_NORMALISED_LIST,
      o_status              OUT NUMBER);

   PROCEDURE RC_GET_SUMMA_REPORT (
      --advance fitlers start
      i_OD_fiscal_year         IN     VARCHAR2,
      i_OD_part_number         IN     VARCHAR2,
      i_OD_order_status        IN     VARCHAR2,
      i_OD_order_number        IN     VARCHAR2,
      i_OD_end_customer_name   IN     VARCHAR2,
      i_OD_theater             IN     VARCHAR2,
      --Advance filter for Order Backlog
      i_OB_part_number         IN     VARCHAR2,
      i_OB_order_status        IN     VARCHAR2,
      i_OB_order_number        IN     VARCHAR2,
      i_OB_end_customer_name   IN     VARCHAR2,
      i_OB_theater             IN     VARCHAR2,
      i_OB_order_line_amount   IN     VARCHAR2,
      --advance fitlers end

      o_od_summary_data           OUT ORDER_DETAILS_SUMMA_LIST,
      o_ob_summary_data           OUT ORDER_DETAILS_SUMMA_LIST,
      o_status                    OUT NUMBER);
END RC_ORDER_REPORT_FETCH;
/