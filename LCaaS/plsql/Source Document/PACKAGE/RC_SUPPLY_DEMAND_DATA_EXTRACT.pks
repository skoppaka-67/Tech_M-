CREATE OR REPLACE PACKAGE CRPREP./*AppDB: 1029810*/                 "RC_SUPPLY_DEMAND_DATA_EXTRACT"                  
                                                                   
AS
   g_error_msg   VARCHAR2 (2000) := NULL;
   g_flag_yes    CHAR := 'Y';

   PROCEDURE RC_SUP_DEM_INITIAL_PAGE_LOAD (
      i_user_id                       IN     VARCHAR2,
      i_min                           IN     NUMBER,
      i_max                           IN     NUMBER,
      i_productName                   IN     CLOB,
      i_revenueBand                   IN     VARCHAR2,
      i_aspBand                       IN     VARCHAR2,
      i_mosBand                       IN     VARCHAR2,
      i_eos                           IN     VARCHAR2,
      i_sort_column_name              IN     VARCHAR2,
      i_sort_column_by                IN     VARCHAR2,
      i_filter_column_name            IN     VARCHAR2,
      i_filter_user_input             IN     VARCHAR2,
      i_filter_list                   IN     CRPSC.RC_NEW_FILTER_LIST,
      o_sup_dem_report_details_list      OUT CRPREP.RC_SUPPLY_DEMAND_REPORT_LIST,
      o_record_count                     OUT NUMBER,
      o_status                           OUT NUMBER,
      o_notificationMsg                  OUT VARCHAR2,
      o_current_year                     OUT VARCHAR2);


   PROCEDURE RC_SUP_DEM_FILTER_VALUE (
      i_user_id             IN     VARCHAR2,
      o_revenue_band_list      OUT CRPREP.RC_NORMALISED_VARCHAR_LIST,
      o_asp_band_list          OUT CRPREP.RC_NORMALISED_VARCHAR_LIST,
      o_mos_band_list          OUT CRPREP.RC_NORMALISED_VARCHAR_LIST,
      o_current_year                     OUT VARCHAR2);

      PROCEDURE GET_UNIQUE_FILTERS (
     i_productName                   IN     CLOB,
      i_revenueBand                   IN     VARCHAR2,
      i_aspBand                       IN     VARCHAR2,
      i_mosBand                       IN     VARCHAR2,
      i_eos                           IN     VARCHAR2,
      i_filter_column_name            IN     VARCHAR2,
      i_filter_user_input             IN     VARCHAR2,
      i_filter_list          IN     CRPSC.RC_NEW_FILTER_LIST,
      o_unique_value            OUT T_NORMALISED_LIST);
END RC_SUPPLY_DEMAND_DATA_EXTRACT;
/