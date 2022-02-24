CREATE OR REPLACE PACKAGE CRPADM./*AppDB: 1024271*/          "RC_INV_SHORTAGE_DATA_FETCH" 
IS

   PROCEDURE RC_INV_SHORTAGE_DATA_EXTRACT (i_user_id                IN  VARCHAR2,
                                     i_min                          IN  NUMBER,
                                     i_max                          IN  NUMBER,
                                     i_filter_column_name           IN  VARCHAR2,
                                     i_filter_user_input            IN  VARCHAR2,
                                     i_sort_column_name             IN  VARCHAR2,
                                     i_sort_column_by               IN  VARCHAR2,
                                     i_filter_list                  IN  RC_NEW_FILTER_OBJ_LIST,               
                                     o_total_row_count              OUT NUMBER,
                                     o_bl_list                      OUT RC_INV_SHORTAGE_LIST);
   PROCEDURE RC_INV_SHORTAGE_TRANS_DATA_EXT (i_user_id                IN  VARCHAR2,
                                     i_min                          IN  NUMBER,
                                     i_max                          IN  NUMBER,
                                     i_filter_column_name           IN  VARCHAR2,
                                     i_filter_user_input            IN  VARCHAR2,
                                     i_sort_column_name             IN  VARCHAR2,
                                     i_sort_column_by               IN  VARCHAR2,
                                     i_filter_list                  IN  RC_NEW_FILTER_OBJ_LIST,               
                                     o_total_row_count              OUT NUMBER,
                                     o_inventory_sum                OUT NUMBER,
                                     o_bl_list                      OUT RC_INV_SHORTAGE_TRANS_LIST);
   PROCEDURE RC_INV_GET_UNIQUE_PID (
      i_user_id                  IN     VARCHAR2,
      i_filter_column_name       IN     VARCHAR2,
      i_filter_list              IN     RC_NEW_FILTER_OBJ_LIST,
      o_bl_filter_list           OUT    RC_GET_UNIQUE_PID_LIST);                                     
   PROCEDURE RC_TRANS_GET_UNIQUE_PID (
      i_user_id                  IN     VARCHAR2,
      i_filter_column_name       IN     VARCHAR2,
      i_filter_list              IN     RC_NEW_FILTER_OBJ_LIST,
      o_bl_filter_list           OUT    RC_GET_UNIQUE_PID_LIST);     
   PROCEDURE GET_IN_CONDITION_FOR_QUERY (
      i_filter_list       RC_NEW_FILTER_OBJ_LIST,
      i_in_query      OUT CLOB);
   PROCEDURE RC_INV_EXCEL_DOWNLOAD (
       o_inv_list                      OUT RC_INV_SHORTAGE_LIST,
       o_trans_list                    OUT RC_INV_SHORTAGE_TRANS_LIST);
END RC_INV_SHORTAGE_DATA_FETCH;
/