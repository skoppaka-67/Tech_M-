CREATE OR REPLACE PACKAGE CRPADM./*AppDB: 1018321*/
                                                                                               "RC_DEMAND_AUTOMATION"
IS
   g_error_msg               VARCHAR2 (2000) := NULL;
   g_output21         BLOB;
   PROCEDURE RC_DEMAND_SOURCING;

   PROCEDURE RC_FIN_DEM_LIST_PROC;

   PROCEDURE RC_IRT_MAIL_RPT_PROC;
   
      PROCEDURE RC_IRT_MAIL_RPT_PROC_1;

   PROCEDURE RC_MSG_MAIL_PROC (I_MSG IN VARCHAR2, I_ERRMSG VARCHAR2);

   PROCEDURE RC_EXCLUDE_PID_UPDATE (i_exclude_list IN RC_EXCLDE_PID_LIST);

   PROCEDURE RC_INCLUDE_PID_UPDATE (i_include_list IN RC_INCLDE_PID_LIST);

   FUNCTION GET_COMMON_NAME (i_stripped_name VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION GET_LIFE_CYCLE (i_common_name VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION GET_QOH (i_rmktng_name    VARCHAR2,
                     i_common_name    VARCHAR2,
                     i_spare_name     VARCHAR2,
                     i_source         VARCHAR2)
      RETURN NUMBER;

   FUNCTION GET_SPARE_NAME (i_cisco_name VARCHAR2, i_type VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION GET_MOS (i_cisco_name    VARCHAR2,
                     i_spare_name    VARCHAR2,
                     i_QOH           NUMBER)
      RETURN NUMBER;

   FUNCTION GET_ASP (i_remarketing_name VARCHAR2, i_cisco_name VARCHAR2)
      RETURN NUMBER;

   FUNCTION GET_INV_DATA (i_inv_type       VARCHAR2,
                       i_rmktng_name    VARCHAR2,
                       i_common_name    VARCHAR2,
                       i_spare_name     VARCHAR2,
                       i_source         VARCHAR2)
      RETURN NUMBER;

    FUNCTION GET_SALES_DATA (i_sales_type      VARCHAR2,
                            i_excess_name       VARCHAR2,
                            i_fiscal          NUMBER,
                            i_product_name    VARCHAR2)
      RETURN NUMBER;
   FUNCTION GET_MOS_BANDS  ( i_MFG_EOS_DATE date, i_CUR_Sales_Units NUMBER, i_MOS NUMBER)
      RETURN VARCHAR2;

   FUNCTION get_total_reservations (i_remarketing_name VARCHAR2,i_excess_name VARCHAR2)
      RETURN NUMBER;

   FUNCTION get_product_type (PRODUCT_SPARE_NAME    VARCHAR2,
                              PRODUCT_NAME          VARCHAR2,
                              CISCO_PRODUCT_NAME    VARCHAR2)
      RETURN VARCHAR2;
 FUNCTION get_product_description (PRODUCT_SPARE_NAME    VARCHAR2,
                                     PRODUCT_NAME          VARCHAR2,
                                     CISCO_PRODUCT_NAME    VARCHAR2)
      RETURN VARCHAR2;
   PROCEDURE RC_GET_EXCLUDE_PID (
      o_exclude_list            OUT RC_EXCLDE_PID_LIST,
      i_min_row              IN     NUMBER,
      i_max_row              IN     NUMBER,
      i_filter_column_name   IN     VARCHAR2,
      i_filter_user_input    IN     VARCHAR2,
      i_sort_column_name     IN     VARCHAR2,
      i_sort_column_by       IN     VARCHAR2,
      i_filter_list          IN     RC_FILTER_LIST);

   PROCEDURE RC_GET_INCLUDE_PID (
      o_include_list            OUT RC_INCLDE_PID_LIST,
      i_min_row              IN     NUMBER,
      i_max_row              IN     NUMBER,
      i_filter_column_name   IN     VARCHAR2,
      i_filter_user_input    IN     VARCHAR2,
      i_sort_column_name     IN     VARCHAR2,
      i_sort_column_by       IN     VARCHAR2,
      i_filter_list          IN     RC_FILTER_LIST);

   PROCEDURE RC_GET_FINAL_DEMAND (
      o_final_demand_list       OUT RC_FINAL_DEMAND_LIST,
      i_min_row              IN     NUMBER,
      i_max_row              IN     NUMBER,
      i_filter_column_name   IN     VARCHAR2,
      i_filter_user_input    IN     VARCHAR2,
      i_sort_column_name     IN     VARCHAR2,
      i_sort_column_by       IN     VARCHAR2,
      i_filter_list          IN     RC_FILTER_LIST);

   PROCEDURE RC_GET_FINAL_DEMAND_FILTER (
      o_final_demand_list       OUT RC_FINAL_DEMAND_LIST,
      i_min_row              IN     NUMBER,
      i_max_row              IN     NUMBER,
      i_filter_column_name   IN     VARCHAR2,
      i_filter_user_input    IN     VARCHAR2,
      i_sort_column_name     IN     VARCHAR2,
      i_sort_column_by       IN     VARCHAR2,
      i_filter_list          IN     RC_NEW_FILTER_OBJ_LIST);

   PROCEDURE RC_GET_FINAL_DEMAND_UNIQUE (
      o_final_demand_list       OUT RC_ADDL_FILTERS_LIST,
      i_user_id              IN     VARCHAR2,
      i_filter_column_name   IN     VARCHAR2,
      i_tabname              IN     VARCHAR2,
      i_filter_list          IN     RC_NEW_FILTER_OBJ_LIST);

   PROCEDURE RC_GET_INCLUDE_PID_FILTER (
      o_include_list            OUT RC_INCLDE_PID_LIST,
      i_min_row              IN     NUMBER,
      i_max_row              IN     NUMBER,
      i_filter_column_name   IN     VARCHAR2,
      i_filter_user_input    IN     VARCHAR2,
      i_sort_column_name     IN     VARCHAR2,
      i_sort_column_by       IN     VARCHAR2,
      i_filter_list          IN     RC_NEW_FILTER_OBJ_LIST);

   PROCEDURE RC_GET_EXCLUDE_PID_FILTER (
      o_exclude_list            OUT RC_EXCLDE_PID_LIST,
      i_min_row              IN     NUMBER,
      i_max_row              IN     NUMBER,
      i_filter_column_name   IN     VARCHAR2,
      i_filter_user_input    IN     VARCHAR2,
      i_sort_column_name     IN     VARCHAR2,
      i_sort_column_by       IN     VARCHAR2,
      i_filter_list          IN     RC_NEW_FILTER_OBJ_LIST);

   PROCEDURE GET_IN_CONDITION_FOR_QUERY (
      i_filter_list       RC_NEW_FILTER_OBJ_LIST,
      i_in_query      OUT CLOB);
END RC_DEMAND_AUTOMATION;
/