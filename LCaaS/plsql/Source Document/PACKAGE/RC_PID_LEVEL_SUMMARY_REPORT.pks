CREATE OR REPLACE PACKAGE CRPREP.RC_PID_LEVEL_SUMMARY_REPORT
AS
   /*****************************************************************************************************************
       || Object Name    : RC_PID_LEVEL_SUMMARY_REPORT
       || Modules        : PID LEVEL SUMMARY REPORT
       || Description    :  PID LEVEL SUMMARY REPORT GENERATION
       ||------------------------------------------------------------------------------------------------------------
       ||Date                  By                 Version        Comments
       ||------------------------------------------------------------------------------------------------------------
       ||06-Oct-2017     sidbhumi         1.0          Initial creation
       ||------------------------------------------------------------------------------------------------------------
   *****************************************************************************************************************/
   g_error_msg               VARCHAR2 (2000) := NULL;
   g_email_flag_yes          CHAR;
   g_email_flag_no           CHAR;

   TYPE RC_PROPERTY_MAPPING_LIST IS TABLE OF VARCHAR2 (500)
      INDEX BY VARCHAR2 (500);

   g_property_mapping_list   RC_PROPERTY_MAPPING_LIST;

   PROCEDURE RC_PLS_REPORT_FETCH (
      i_user_id                       IN     VARCHAR2,
      i_user_role                     IN     VARCHAR2,
      i_min                           IN     NUMBER,
      i_max                           IN     NUMBER,
      i_sort_column_name              IN     VARCHAR2,
      i_sort_column_by                IN     VARCHAR2,
      i_filter_column_name            IN     VARCHAR2,
      i_filter_user_input             IN     VARCHAR2,
      i_filter_list                   IN     CRPSC.RC_NEW_FILTER_LIST,
      i_repair_site_filter            IN     VARCHAR2,
      i_fiscal_year_filter            IN     VARCHAR2,
      i_quarter_filter                IN     VARCHAR2,
      i_month_filter                  IN     VARCHAR2,
      i_week_filter                   IN     VARCHAR2,
      o_pid_level_summary_data_list      OUT CRPREP.RC_PID_LEVEL_SUMMARY_LIST,
      o_record_count                     OUT NUMBER,
      o_status                           OUT NUMBER,
      o_notificationMsg                  OUT VARCHAR2);

   PROCEDURE GET_UNIQUE_FILTERS (
      i_user_id              IN     VARCHAR2,
      i_filter_column_name   IN     VARCHAR2,
      i_filter_user_input    IN     VARCHAR2,
      i_filter_list          IN     CRPSC.RC_NEW_FILTER_LIST,
      i_repair_site_filter   IN     VARCHAR2,
      i_fiscal_year_filter   IN     NUMBER,
      i_quarter_filter       IN     VARCHAR2,
      i_month_filter         IN     VARCHAR2,
      i_week_filter          IN     NUMBER,
      o_unique_value            OUT CRPSC.RC_NORMALISED_LIST);

   PROCEDURE GET_FILTERS_IN_QUERY (
      i_filter_list   IN     CRPSC.RC_NEW_FILTER_LIST,
      i_table_name    IN     VARCHAR2,
      o_in_query         OUT CLOB);

   PROCEDURE GET_ADVANCED_FILTERS (
      i_user_id               IN     VARCHAR2,
      i_user_role             IN     VARCHAR2,
      o_pls_adv_fltr_list        OUT CRPREP.RC_PLS_ADV_FLTR_LIST,
      o_repair_partner_list      OUT CRPADM.RC_REPAIR_PARTNER_LIST,
      o_status                   OUT NUMBER,
      o_status_msg               OUT VARCHAR2);

   PROCEDURE UPLOAD_PLS_DATA (
      i_user_id                   IN VARCHAR2,
      i_repair_partner_id         IN NUMBER,
      i_upload_id                 IN NUMBER,
      i_upload_role               IN VARCHAR2,
      i_pid_summary_upload_list   IN RC_PID_LEVEL_SUMMARY_GU_LIST);

   PROCEDURE RC_PID_LEVEL_SUMMARY_EMAIL (
      I_USER_ID        IN VARCHAR2,
      I_UPLOAD_ID      IN NUMBER,
      I_INVALID_LIST   IN RC_PLS_INVALID_LIST);
END RC_PID_LEVEL_SUMMARY_REPORT;
/