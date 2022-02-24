CREATE OR REPLACE PACKAGE RMKTGADM./*AppDB: 1033213*/            "RC_ZSITE_CYCLE_ADJ_PKG" 
AS
   /*
  ****************************************************************************************************************
  * Object Name       :RC_ZSITE_CYCLE_ADJ_PKG
  *  Project Name     : Refresh Central
   * Copy Rights:   Cisco Systems, INC., CALIFORNIA
  * Description       : This API for Z-Site cycle count Adjustment
  * Created Date:  20th April,2018
  ===================================================================================================+
  * Version              Date                     Modified by                     Description
  ===================================================================================================+
   1.0                  20th April,2018           satbanda                     Created for Z-Site cycle count Adjustment
  ===================================================================================================+
   **************************************************************************************************************** */
    v_message VARCHAR2(32767);
    v_rejected VARCHAR2(20):='REJECTED';

    PROCEDURE P_RCEC_ERROR_LOG (i_Module_Name        VARCHAR2,
                               i_Entity_Name        VARCHAR2 DEFAULT NULL,
                               i_Entity_ID          VARCHAR2 DEFAULT NULL,
                               i_EXT_Entity_Name    VARCHAR2 DEFAULT NULL,
                               i_EXT_Entity_ID      VARCHAR2 DEFAULT NULL,
                               i_Error_Type         VARCHAR2,
                               i_Error_Message      VARCHAR2,
                               i_Created_by         VARCHAR2,
                               i_UPDATED_BY         VARCHAR2);
      
    PROCEDURE P_ZSITE_DATA_UPLOAD (
      i_zsite_cycle_data_tab     IN         RC_Z_SITE_CYCLE_DATA_TAB,
      i_upload_id                IN         VARCHAR2,
      i_site_code                IN         VARCHAR2, --Z-Sites
      i_login_user               IN         VARCHAR2,
      i_user_role                IN         VARCHAR2,
      o_process_err_msg          OUT        RC_INV_MESSAGE_TAB,
      o_status                   OUT NOCOPY VARCHAR2);
    PROCEDURE P_ZSITE_DATA_VIEW (
      i_login_user                IN            VARCHAR2,
      i_load_view                 IN            VARCHAR2,
      i_min_row                   IN            VARCHAR2,
      i_max_row                   IN            VARCHAR2,
      i_sort_column_name          IN            VARCHAR2,
      i_sort_column_by            IN            VARCHAR2,
      i_part_number               IN            VARCHAR2,
      i_site_id                   IN            VARCHAR2,
      i_sub_inv_id                IN            VARCHAR2,
      i_status                    IN            VARCHAR2,      
      i_upload_date_from          IN            VARCHAR2,
      i_upload_date_to            IN            VARCHAR2,
      o_display_count                OUT NOCOPY NUMBER,
      o_zsite_cycle_data_tab         OUT NOCOPY RC_Z_SITE_CYCLE_DATA_TAB,
      o_zsite_cycle_alldata_tab      OUT NOCOPY RC_Z_SITE_CYCLE_DATA_TAB);
    PROCEDURE P_ZSITE_DATA_SU_PROCESS(
      i_login_user               IN         VARCHAR2,
      i_zsite_cycle_data_tab     IN         RC_Z_SITE_CYCLE_DATA_TAB);

    PROCEDURE P_ZSITE_DATA_ADJ_PROCESS(
      i_login_user               IN         VARCHAR2,
      i_zsite_cycle_data_tab     IN         RC_Z_SITE_CYCLE_DATA_TAB,
      o_zsite_cycle_data_tab     OUT NOCOPY RC_Z_SITE_CYCLE_DATA_TAB,
      o_process_err_msg          OUT NOCOPY RC_INV_MESSAGE_TAB,
      o_status                   OUT NOCOPY VARCHAR2 );
     PROCEDURE P_ZSITE_EMAIL_NOTIFICATION(
      i_login_user               IN         VARCHAR2,
      i_upload_id                IN         NUMBER,
      i_site_id                  IN         VARCHAR2,
      i_upload_flag              IN         VARCHAR2,
      i_zsite_cycle_data_tab     IN         RC_Z_SITE_CYCLE_DATA_TAB
         );
     FUNCTION F_GET_USER_ZSITES ( i_login_user  IN  VARCHAR2, 
                                 i_user_role   IN  VARCHAR2,
                                 i_filter_flag IN  VARCHAR2 DEFAULT 'N')
      RETURN RC_VARCHAR_TAB;
      
      FUNCTION F_GET_ZSITE_SUB_INV (i_login_user  IN  VARCHAR2, 
                                 i_user_role   IN  VARCHAR2,
                                 i_zsite_code  IN  VARCHAR2)
      RETURN RC_VARCHAR_TAB    ;  

END RC_ZSITE_CYCLE_ADJ_PKG;
/