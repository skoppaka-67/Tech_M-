CREATE OR REPLACE PACKAGE CRPADM./*AppDB: 1043657*/          "RC_SALES_FORECAST_DATA_EXTRACT"                  
AS
   /***********************************************************************************************************
         || Object Name    : RC_SALES_FORECAST_DATA_EXTRACT
         || Modules          : Sales Forecast data extract
         || Modification History
         ||------------------------------------------------------------------------------------------------------
         ||Date                  By                  Version       Comments
         ||------------------------------------------------------------------------------------------------------
         ||25-Sep-2018      Sweta Priyadarshi         1.0          Initial creation
         ||01-Oct-2018      Abhishekh Bhat            1.1          RC_SALES_FORECAST_PAGE_LOAD
         ||------------------------------------------------------------------------------------------------------
     *************************************************************************************************************/
   g_error_msg   VARCHAR2 (32767 BYTE);

   PROCEDURE RC_SALES_FORECAST_EXPORT_FETCH (
      i_forecast_quarter   IN     VARCHAR2,
      i_forecast_month     IN     VARCHAR2,
      i_forecast_year      IN     VARCHAR2,
      O_EXPORT_LIST           OUT RC_SALES_FORECAST_GU_LIST);



   PROCEDURE RC_SALES_FORECAST_PROP_FETCH (
      O_FILTER_PID_PRIORITY_LIST      OUT CRPADM.RC_SALES_FRCST_PID_PRTY_LIST,
      O_FLTR_FRCST_QQ_MM_YY_TL_LIST   OUT CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST,
      O_PUBLISHED_QQ_MM_YY_LIST       OUT CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST,
      O_CURRENT_QQ_MM_YY_LIST         OUT CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST,
      O_FUTURE_QQ_MM_YY_LIST          OUT CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST,
      O_GU_PUBLISHED_QQ_MM_YY_LIST    OUT CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST,
      O_ADV_FLTR_QQ_MM_YY_LIST        OUT CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST,
      O_LATEST_STG_QQ_MM_YY_LIST      OUT CRPADM.RC_SLS_FRCST_QQ_MM_YY_TL_LIST);


   PROCEDURE RC_SALES_FORECAST_GU_UPLOAD (
      i_user_id            IN VARCHAR2,
      i_upload_id          IN NUMBER,
      i_forecast_quarter   IN VARCHAR2,
      i_forecast_month     IN VARCHAR2,
      i_forecast_year      IN VARCHAR2,
      i_upload_list        IN RC_SALES_FORECAST_GU_LIST);

   PROCEDURE RC_SALES_FORECAST_EMAIL (
      i_user_id        IN VARCHAR2,
      i_upload_id      IN NUMBER,
      i_invalid_list   IN RC_INVALID_SALES_FORECAST_LIST);

   PROCEDURE RC_SALES_FORECAST_PAGE_LOAD (
      I_USER_ID                 IN     VARCHAR2,
      I_MIN                     IN     NUMBER,
      I_MAX                     IN     NUMBER,
      I_PRODUCTNAME             IN     CLOB,
      I_RF_FORECAST             IN     NUMBER,
      I_WS_FORECAST             IN     NUMBER,
      I_APPROVAL_STATUS         IN     VARCHAR2,
      I_SALES_PRIORITY          IN     VARCHAR2,
      I_QUARTER_MONTH           IN     VARCHAR2,
      I_YEAR                    IN     VARCHAR2,
      I_SNAPSHOT                IN     VARCHAR2,
      I_PID_PRIORITY            IN     VARCHAR2,
      O_SALES_FORECAST_LIST        OUT CRPADM.RC_SALES_FORECAST_LIST,
      O_RECORD_COUNT               OUT NUMBER,
      O_SUBMIT_BTN_FLAG            OUT VARCHAR2,
      O_APPROVE_BTN_FLAG           OUT VARCHAR2,
      O_UPLOAD_BTN_FLAG            OUT VARCHAR2,
      O_IS_FORECAST_SUBMITTED      OUT VARCHAR2,
      O_IS_PUBLISHED               OUT VARCHAR2,
      O_PUBLISHED_FLAG             OUT VARCHAR2);

   PROCEDURE RC_SALES_FORECAST_FIN_SUM_LOAD (
      I_USER_ID                     IN     VARCHAR2,
      I_QUARTER_MONTH               IN     VARCHAR2,
      I_YEAR                        IN     VARCHAR2,
      I_SNAPSHOT                    IN     VARCHAR2,
      O_SALES_FORECAST_FINSUMLIST      OUT CRPADM.RC_SALES_FORECAST_FINSUMLIST);

   PROCEDURE RC_SALES_FORECAST_FLAG_DTLS (
      I_USER_ID            IN     VARCHAR2,
      I_FORECAST_QUARTER   IN     VARCHAR2,
      I_FORECAST_MONTH     IN     VARCHAR2,
      I_FORECAST_YEAR      IN     VARCHAR2,
      O_UPLOAD_BTN_FLAG       OUT VARCHAR2);
END RC_SALES_FORECAST_DATA_EXTRACT;
/