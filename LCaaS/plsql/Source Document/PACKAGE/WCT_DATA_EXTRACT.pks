CREATE OR REPLACE PACKAGE CRPEXCESS./*AppDB: 1028023*/                       "WCT_DATA_EXTRACT"                        
AS
   /*===================================================================================================+
    Object Name    : WCT_DATA_EXTRACT
    Module         : WRT DRIVING PACKAGE
    Description    : Wholesale Remarketing Tool driving package

    Revision History:
    -----------------
    Date         Updated By   Bug/Case#    Revision  Comments
    ===========  ===========  ===========  ========  ====================================================
    DD MMM YYYY  xxxxxxxx                  1.0       Comments....
    DD MMM YYYY  xxxxxxxx                  2.0       Comments....
    DD MMM YYYY  xxxxxxxx                  3.0       Comments....
    08-MAR-2017  hkarka                    4.0       removing references to stripped name and RSCM
    20-MAR-2017  satbanda                  5.0       removing references to stripped name and RSCM
    06-Sep-2017  satbanda                  6.0       Modified for US131874 PID Deactivation EPQ2O Changes
   ====================================================================================================*/

   /*GLOBAL VARIABLE FOR THE PACKAGE*/
   v_Empty_String                VARCHAR2 (1) := '';
   v_Status_Active               VARCHAR2 (6) := 'ACTIVE';
   v_Status_Approved             VARCHAR2 (8) := 'APPROVED';
   v_Status_Deleted              VARCHAR2 (7) := 'DELETED';
   v_Status_Draft                VARCHAR2 (5) := 'DRAFT';
   v_Status_Failure              VARCHAR2 (7) := 'FAILURE';
   v_Status_Inactive             VARCHAR2 (8) := 'INACTIVE';
   v_Status_New                  VARCHAR2 (3) := 'NEW';
   v_Status_Partial              VARCHAR2 (7) := 'PARTIAL';
   v_Status_Pending              VARCHAR2 (7) := 'PENDING';
   v_Status_Quote                VARCHAR2 (5) := 'QUOTE';
   v_Status_Rejected             VARCHAR2 (8) := 'REJECTED';
   v_Status_Success              VARCHAR2 (7) := 'SUCCESS';
   v_Default_Broker_Offer        NUMBER := 0.00;
   v_Flag_No                     VARCHAR2 (1) := 'N';
   v_Flag_Yes                    VARCHAR2 (1) := 'Y';
   v_Error_Message               VARCHAR2 (300);
   v_Not_Applicable              VARCHAR2 (3) := 'N/A';
   v_View_Type_Export            VARCHAR2 (8) := 'EXTERNAL';
   v_View_Type_ModusLink         VARCHAR2 (10) := 'MODUS_LINK';
   v_Search_Type_New             VARCHAR2 (3) := 'NEW';
   v_Search_Type_Edit            VARCHAR2 (4) := 'EDIT';
   v_Region_Type_Local           VARCHAR2 (5) := 'LOCAL';
   v_Region_Type_Foreign         VARCHAR2 (7) := 'FOREIGN';
   v_Quote_Id_Type_Dummy         VARCHAR2 (1) := 'D';
   v_Quote_Id_Type_Quote         VARCHAR2 (1) := 'Q';
   v_Customer_List_Type_Update   VARCHAR2 (6) := 'UPDATE';
   v_Customer_List_Type_View     VARCHAR2 (4) := 'VIEW';
   v_Load_Type_Action            VARCHAR2 (8) := 'ACTION';
   v_Load_Type_Complete          VARCHAR2 (8) := 'COMPLETE';
   v_Load_Type_Preview           VARCHAR2 (8) := 'PREVIEW';
   v_Load_Type_Search            VARCHAR2 (6) := 'SEARCH';
   v_Action_Type_Add             VARCHAR2 (3) := 'ADD';
   v_Action_Type_Update          VARCHAR2 (6) := 'UPDATE';
   v_Approval_Status_Approved    CHAR := 'A';
   v_Approval_Status_Pending     CHAR := 'P';
   v_Approval_Status_Rejected    CHAR := 'R';
   v_deactivated_status          VARCHAR2 (20) := 'DEACTIVATED'; --Added by satbanda to get the active Part for deactivated Wholesale parts
   --Added by satbanda for Q4FY17 - April Release <Start>
   v_Load_Type_line              VARCHAR2 (8) := 'LINE';
   v_Load_Type_exclude           VARCHAR2 (10) := 'EXCLUDE';
   v_Load_Type_include           VARCHAR2 (10) := 'INCLUDE';
   --Added by satbanda for Q4FY17 - April Release <End>

   /*PROCEDURE TO FETCH INITIAL DATA*/
   PROCEDURE LOAD_INITIAL_DATA (
      i_User_ID               IN     VARCHAR2,
      o_Initial_Data_Object      OUT WCT_INITIAL_DATA_OBJECT);

   /* PROCEDURE TO FETCH CUSTOMER LIST */
   PROCEDURE LOAD_CUSTOMER_LIST (
      i_User_Id              IN     VARCHAR2,
      i_Customer_List_Type   IN     VARCHAR2,
      o_Customer_List           OUT WCT_CUSTOMER_LIST);

   /* PROCEDURE TO FETCH QUOTE LIST */
   PROCEDURE LOAD_RETRIEVE_QUOTE_LIST (
      i_User_Id                IN     VARCHAR2,
      i_Load_Type              IN     VARCHAR2,
      i_Part_Number            IN     VARCHAR2,
      o_Retrieve_Quotes_List      OUT WCT_RETRIEVE_QUOTES_LIST);

   /*PROCEDURE TO GET DATA REFRESH TIME*/
   PROCEDURE GET_DATA_REFRESH_TIME (i_Client_Date_Time   IN     VARCHAR2,
                                    o_Date_Time_String      OUT VARCHAR2);

   /*PROCEDURE TO FETCH DATA FOR BOMs - New Search, Edit Quote and Copy Quote*/
--   PROCEDURE DATA_EXTRACT (
--      i_search_list              IN     WCT_BOM_LIST,
--      i_Customer_Id              IN     NUMBER,
--      i_User_ID                  IN     VARCHAR2,
--      i_Search_Type              IN     VARCHAR2,
--      i_Quote_Id                 IN     VARCHAR2,
--      i_Copy_Quote_Customer_Id   IN     NUMBER,
--      o_Search_Result_Object        OUT WCT_SEARCH_RESULT_OBJECT);

   /*PROCEDURE TO UPDATE QUOTE LINES FOR SEARCHED BOMs*/
   PROCEDURE SAVE_QUOTE (
      i_Update_Quote_Object          IN     WCT_QUOTE_OBJECT,
      i_Save_Type                    IN     VARCHAR2,
      i_Customer_Id                  IN     NUMBER,
      o_Save_Quote_Response_Object      OUT WCT_SAVE_QUOTE_RESPONSE_OBJECT);

   /*PROCEDURE TO COMPUTE RESERVATIONS*/
--   PROCEDURE COMPUTE_RESERVATIONS (
--      i_Part_Number              IN     VARCHAR2,
--      i_Product_Name_Stripped    IN     VARCHAR2,
--      i_User_Id                  IN     VARCHAR2,
--      i_Region                   IN     VARCHAR2,
--      i_Conflicting_Part_Count   IN     NUMBER,
--      i_Conflicting_Part_Id      IN     VARCHAR2,
--      i_Conflicting_Part_WS      IN     VARCHAR2,
--      o_Reservation_RF_Quotes       OUT NUMBER,
--      o_Reservation_RF_Backlog      OUT NUMBER,
--      o_Reservation_WS_Order        OUT NUMBER,
--      o_Reservation_Total           OUT NUMBER,
--      o_Reservation_Total_RF        OUT NUMBER,
--      o_Reservation_Total_WS        OUT NUMBER);

   /*PROCEDURE TO COMPUTE INVENTORY, AVAILABLE QUANTITY, SHIP TIME*/
--   PROCEDURE COMPUTE_INV_AND_AVAILABLE_QTY (
--      i_Part_Number                   IN     VARCHAR2,
--      i_Product_Name_Stripped         IN     VARCHAR2,
--      i_Wholesale_Part                IN     VARCHAR2,
--      i_User_Id                       IN     VARCHAR2,
--      i_Requested_Qty                 IN     NUMBER,
--      i_Reservation_RF_Total_Lcl      IN     NUMBER,
--      i_Reservation_WS_Total_Lcl      IN     NUMBER,
--      i_Reservation_RF_Total_Frn      IN     NUMBER,
--      i_Reservation_WS_Total_Frn      IN     NUMBER,
--      i_Region_Local                  IN     VARCHAR2,
--      i_Region_Foreign                IN     VARCHAR2,
--      i_Conflicting_Part_Count        IN     NUMBER,
--      i_Conflicting_Part_Id           IN     VARCHAR2,
--      i_Conflicting_Part_WS           IN     VARCHAR2,
--      o_Reservation_POE_For_RF           OUT NUMBER,
--      o_FG_Only                          OUT NUMBER,
--      o_Available_RF                     OUT VARCHAR2,
--      o_Available_WS                     OUT VARCHAR2,
--      o_Available_POE                    OUT VARCHAR2,
--      o_Available_Quantity_Net_1         OUT NUMBER,
--      o_Available_Quantity_Net_2         OUT NUMBER,
--      o_Inventory_Detail_List_Local      OUT WCT_INVENTORY_DETAIL_LIST,
--      o_Inventory_Detail_List_Frn        OUT WCT_INVENTORY_DETAIL_LIST,
--      o_Lead_Time_1                      OUT VARCHAR2,
--      o_Lead_Time_2                      OUT VARCHAR2,
--      o_Lead_Time_Count                  OUT NUMBER,
--      o_Inventory_Detail_Notes_1         OUT VARCHAR2,
--      o_Inventory_Detail_Notes_2         OUT VARCHAR2,
--      o_Available_RF_Frn                 OUT VARCHAR2,
--      o_Quantity_On_Hand_1               OUT NUMBER,
--      o_Quantity_In_Transit_1            OUT NUMBER,
--      o_Quantity_On_Hand_2               OUT NUMBER,
--      o_Quantity_In_Transit_2            OUT NUMBER);

   /*PROCEDUTRE TO DETERMINE SELLING PRICE (CISCO OFFER)*/
   --Commented by satbanda on 20-Mar-2017 for validate PID logic <Start>
   /*PROCEDURE PRICING_ENGINE (i_Broker_Offer_Missing_Flag   IN     CHAR,
                             i_Recent_Price                IN     NUMBER,
                             i_Broker_Offer                IN     NUMBER,
                             i_Available_Quantity          IN     NUMBER,
                             i_Requested_Quantity          IN     NUMBER,
                             i_Base_Price_Discount         IN     NUMBER,
                             i_Glp                         IN     NUMBER,
                             i_Round_Scale                 IN     NUMBER,
                             i_Requested_Part              IN     VARCHAR2,
                             i_Product_Name_Stripped       IN     VARCHAR2,
                             i_Product_Name_Stripped_WS    IN     VARCHAR2,
                             i_Customer_Id                 IN     NUMBER,
                             i_Region_Local                IN     VARCHAR2,
                             i_Conflicting_Part_Count      IN     NUMBER,
                             i_Conflicting_Part_Id         IN     VARCHAR2,
                             i_Conflicting_Part_WS         IN     VARCHAR2,
                             o_Base_Price                     OUT NUMBER,
                             o_Suggested_Price                OUT NUMBER,
                             o_Ext_Sell_Price                 OUT NUMBER,
                             o_Base_Price_Discount            OUT NUMBER,
                             o_Static_Price_Exists            OUT CHAR);*/
   --Commented by satbanda on 20-Mar-2017 for validate PID logic <End>

   --Added by satbanda on 20-Mar-2017 for validate PID logic <Start>
   PROCEDURE PRICING_ENGINE (i_Broker_Offer_Missing_Flag   IN     CHAR,
                             i_Recent_Price                IN     NUMBER,
                             i_Broker_Offer                IN     NUMBER,
                             i_Available_Quantity          IN     NUMBER,
                             i_Requested_Quantity          IN     NUMBER,
                             i_Base_Price_Discount         IN     NUMBER,
                             i_Glp                         IN     NUMBER,
                             i_Round_Scale                 IN     NUMBER,
                             i_Requested_Part              IN     VARCHAR2,
                             i_Manufacture_Part            IN     VARCHAR2,
                             i_spare_Part                  IN     VARCHAR2,
                             i_Wholesale_Part              IN     VARCHAR2,
                             i_Refurbished_Part            IN     VARCHAR2,
                             i_Customer_Id                 IN     NUMBER,
                             i_Region_Local                IN     VARCHAR2,
                             o_Base_Price                     OUT NUMBER,
                             o_Suggested_Price                OUT NUMBER,
                             o_Ext_Sell_Price                 OUT NUMBER,
                             o_Base_Price_Discount            OUT NUMBER,
                             o_Static_Price_Exists            OUT CHAR);
  --Added by satbanda on 20-Mar-2017 for validate PID logic <End>

   /*PROCEDUTRE TO GET STATIC PRICE DETAILS*/
   --Commented by satbanda on 20-Mar-2017 for validate PID logic <Start>
   /*PROCEDURE GET_STATIC_PRICE_DETAILS (
      i_Customer_Id                IN     NUMBER,
      i_Product_Name_Stripped      IN     VARCHAR2,
      i_Product_Name_Stripped_WS   IN     VARCHAR2,
      i_Conflicting_Part_Count     IN     NUMBER,
      i_Conflicting_Part_Id        IN     VARCHAR2,
      i_Conflicting_Part_WS        IN     VARCHAR2,
      o_Static_Price_Exists           OUT CHAR,
      o_Static_Price                  OUT NUMBER);*/
      --Commented by satbanda on 20-Mar-2017 for validate PID logic <End>
    --Added by satbanda on 20-Mar-2017 for validate PID logic <Start>
   PROCEDURE GET_STATIC_PRICE_DETAILS (
      i_Customer_Id                 IN     NUMBER,
      i_Manufacture_Part            IN     VARCHAR2,
      i_spare_Part                  IN     VARCHAR2,
      i_Wholesale_Part              IN     VARCHAR2,
      i_Refurbished_Part            IN     VARCHAR2,
      o_Static_Price_Exists           OUT CHAR,
      o_Static_Price                  OUT NUMBER);
  --Added by satbanda on 20-Mar-2017 for validate PID logic <End>

   /*PROCEDUTRE TO VIEW QUOTE DETAILS - EXCEL EXPORTS, PREVIEW*/
   PROCEDURE VIEW_QUOTE_DETAILS (
      i_Quote_ID                    IN     VARCHAR2,
      i_View_Type                   IN     VARCHAR2,
      o_View_Quote_Details_Object      OUT WCT_VIEW_QUOTE_DETAILS_OBJECT);

   /* PROCEDURE TO LOG ERROR DETAILS */
   PROCEDURE GET_ERROR_DETAILS (i_User_Id        IN     VARCHAR2,
                                o_Error_Object      OUT WCT_ERROR_OBJECT);

   /* PROCEDURE TO LOAD APPROVAL QUOTE LIST */
   PROCEDURE LOAD_APPROVAL_QUOTE_LIST (
      i_User_Id                IN     VARCHAR2,
      i_Load_Type              IN     VARCHAR2,
      o_Approval_Quotes_List      OUT WCT_RETRIEVE_QUOTES_LIST);

   /* PROCEDURE TO LOAD CUSTOMER COMPANY DATA */
   PROCEDURE LOAD_CUSTOMER_COMPANY_DATA (
      i_User_Id                   IN     VARCHAR2,
      o_Customer_Company_Object      OUT WCT_CUSTOMER_COMPANY_OBJECT);

   /* PROCEDURE TO FETCH COMPANY LIST */
   PROCEDURE LOAD_COMPANY_LIST (i_User_Id        IN     VARCHAR2,
                                o_Company_List      OUT WCT_COMPANY_LIST);

   /* PROCEDURE TO FETCH USER LIST */
   PROCEDURE LOAD_USER_LIST (i_User_Id     IN     VARCHAR2,
                             o_User_List      OUT WCT_USER_LIST);

   /* PROCEDURE TO FETCH STATIC PRICE PART LIST */
   PROCEDURE LOAD_STATIC_PRICE_PART_LIST (
      i_User_Id                  IN     VARCHAR2,
      o_Static_Price_Part_List      OUT WCT_STATIC_PRICE_PART_LIST);

   /* PROCEDURE TO ADD/UPDATE COMPANY DETAILS */
   PROCEDURE ADD_UPDATE_COMPANY_DETAILS (
      i_Company_Id        IN     NUMBER,
      i_Company_Name      IN     VARCHAR2,
      i_Tier              IN     NUMBER,
      i_Address_1         IN     VARCHAR2,
      i_Address_2         IN     VARCHAR2,
      i_City              IN     VARCHAR2,
      i_State             IN     VARCHAR2,
      i_Zip               IN     VARCHAR2,
      i_Country           IN     VARCHAR2,
      i_Region            IN     VARCHAR2,
      i_Status            IN     VARCHAR2,
      i_User_Id           IN     VARCHAR2,
      i_Action_Type       IN     VARCHAR2,
      o_Response_Object      OUT WCT_RESPONSE_OBJECT);

   /* PROCEDURE TO ADD/UPDATE CUSTOMER DETAILS */
   PROCEDURE ADD_UPDATE_CUSTOMER_DETAILS (
      i_Customer_Id       IN     NUMBER,
      i_Poc_Title         IN     VARCHAR2,
      i_Poc_First_Name    IN     VARCHAR2,
      i_Poc_Last_Name     IN     VARCHAR2,
      i_Sales_Person      IN     VARCHAR2,
      i_Status            IN     VARCHAR2,
      i_Company_Id        IN     NUMBER,
      i_User_Id           IN     VARCHAR2,
      i_Action_Type       IN     VARCHAR2,
      o_Response_Object      OUT WCT_RESPONSE_OBJECT);

   /* PROCEDURE TO ADD/UPDATE USER DETAILS */
   PROCEDURE ADD_UPDATE_USER_DETAILS (
      i_User_Id                 IN     VARCHAR2,
      i_User_Name               IN     VARCHAR2,
      i_Status                  IN     VARCHAR2,
      i_Job_Title               IN     VARCHAR2,
      i_Email_Address           IN     VARCHAR2,
      i_Phone_Number            IN     VARCHAR2,
      i_Cell_Number             IN     VARCHAR2,
      i_Access_Type_Admin       IN     VARCHAR2,
      i_Access_Type_Read_Only   IN     VARCHAR2,
      i_Action_Type             IN     VARCHAR2,
      o_Response_Object            OUT WCT_RESPONSE_OBJECT);

   /* PROCEDURE TO ADD STATIC PRICE PART DETAILS */
   PROCEDURE ADD_STATIC_PRICE_DETAILS (
      i_User_Id                    IN     VARCHAR2,
      i_Static_Price_Detail_List   IN     WCT_ADD_STATIC_PRICE_LIST,
      o_Response_Object               OUT WCT_ADD_DATA_RESPONSE_OBJECT);

   /* PROCEDURE TO UPDATE APPROVER DETAILS */
   PROCEDURE SAVE_APPROVERS (
      i_User_Id                 IN     VARCHAR2,
      i_Level_0_Approver_List   IN     WCT_VARCHAR_LIST,
      i_Level_1_Approver_List   IN     WCT_VARCHAR_LIST,
      i_Level_2_Approver_List   IN     WCT_VARCHAR_LIST,
      o_Response_Object            OUT WCT_RESPONSE_OBJECT);

   /* PROCEDURE TO FETCH QUOTE DETAILS FOR APPROVAL */
   PROCEDURE VIEW_APPROVE_QUOTE_DETAILS (
      i_Quote_ID                    IN     VARCHAR2,
      i_Approver_Level              IN     VARCHAR2,
      o_View_Quote_Details_Object      OUT WCT_VIEW_QUOTE_DETAILS_OBJECT);

   /* PROCEDURE TO UPDATE APPROVAL/REJECTION FOR QUOTE LINES */
   PROCEDURE APPROVAL_WORKFLOW_ACTION (
      i_User_Id           IN     VARCHAR2,
      i_Quote_ID          IN     VARCHAR2,
      i_Approver_Level    IN     NUMBER,
      i_Approval_Status   IN     CHAR,
      i_Quote_Line_List   IN     WCT_QUOTE_LINE_LIST,
      o_Response_Object      OUT WCT_RESPONSE_OBJECT);

   /* PROCEDURE TO GENERATE EMAIL CONTENT */
   PROCEDURE GENERATE_EMAIL_CONTENT (
      i_Quote_Id         IN     VARCHAR2,
      i_Quote_Status     IN     VARCHAR2,
      i_Approval_Level   IN     NUMBER,
      o_To_List             OUT WCT_VARCHAR_LIST,
      o_Cc_List             OUT WCT_VARCHAR_LIST,
      o_From                OUT VARCHAR2,
      o_Subject             OUT VARCHAR2,
      o_Html_Msg            OUT CLOB);

   /* PROCEDURE TO SEND EMAILS */
   PROCEDURE EMAIL_UTIL (i_To_List    IN WCT_VARCHAR_LIST,
                         i_Cc_List    IN WCT_VARCHAR_LIST,
                         i_From       IN VARCHAR2,
                         i_Subject    IN VARCHAR2,
                         i_Html_Msg   IN CLOB DEFAULT NULL);

   /* PROCEDURE TO DOWNLOAD INVENTORY */
--   PROCEDURE INVENTORY_DOWNLOAD (
--      i_Customer_Region             IN     VARCHAR2,
--      i_Inventory_Region            IN     VARCHAR2,
--      i_Sub_Inventory_Location      IN     VARCHAR2,
--      i_Sub_Inv_Location            IN     VARCHAR2,
--      i_Display_Type                IN     VARCHAR2,
--      i_User_Id                     IN     VARCHAR2,
--      i_Client_Date_Time            IN     VARCHAR2,
--      i_Tier                        IN     NUMBER,
--      i_Cap_Flag                    IN     CHAR,
--      i_Cap_Value                   IN     NUMBER,
--      i_FG_inventory                IN     VARCHAR2,
--      i_POE_Intransit_Inv           IN     VARCHAR2,
--      o_Inventory_Download_Object      OUT WCT_INVENTORY_DOWNLOAD_OBJECT);


   /* PROCEDURE TO GET PARTS FOR AUTO SUGGEST */
   PROCEDURE GET_ALL_PARTS_AUTO_SUGGEST (
      i_Initial           IN     VARCHAR2,
      i_User_Id           IN     VARCHAR2,
      o_All_Parts_Found      OUT WCT_VARCHAR_LIST);

   /*FUNCTION TO GENERATE UNIQUE QUOTE_ID*/
   FUNCTION GENERATE_QUOTE_ID (i_Quote_Id_Type IN VARCHAR2)
      RETURN VARCHAR2;

   /* FUNCTION to get backlog for inventory download */
--   FUNCTION GET_BACKLOG (i_Product_Name_Stripped    VARCHAR2,
--                         i_Product_Type             VARCHAR2)
--      RETURN NUMBER;

   /* FUNCTION to get recent quote details */
   FUNCTION GET_RECENT_QUOTE_DETAILS (i_Requested_Part   IN VARCHAR2,
                                      i_User_Id          IN VARCHAR2)
      RETURN WCT_RECENT_QUOTES_LIST;

   /* FUNCTION to get WS part number for a part */
   FUNCTION GET_WS_PART_NUMBER (i_Part_Number VARCHAR2)
      RETURN VARCHAR2;
--
   /* FUNCTION to get description of part number */
   FUNCTION GET_PART_DESCRIPTION (i_Part_Number VARCHAR2)
      RETURN VARCHAR2;
--
--   /* FUNCTION to get GDGI reservation for a part */
--   FUNCTION GET_GDGI_RESERVATION (i_Product_Name_Stripped IN VARCHAR2)
--      RETURN NUMBER;

   /* FUNCTION TO SORT QUOTE LINE LIST */
   FUNCTION SORT_QUOTE_LINE_LIST (i_Quote_Line_List IN WCT_QUOTE_LINE_LIST)
      RETURN WCT_QUOTE_LINE_LIST;


   PROCEDURE LOAD_ALL_QUOTE_LIST (
      i_User_Id                IN     VARCHAR2,
      i_Load_Type              IN     VARCHAR2,
      o_Approval_Quotes_List      OUT WCT_RETRIEVE_QUOTES_LIST);

   /* Procedure to check inventory and send out mail */
   PROCEDURE ZERO_INVENTORY_EMAIL;

   /* Procedure to fetch data for reporting tab*/
   PROCEDURE REPORTING_DATA (
      i_User_Id         IN     VARCHAR2,
      o_summaryReport      OUT WCT_REPORT_SUMMARY_LIST,
      o_quotesReport       OUT WCT_REPORT_QUOTES_LIST,
      o_salesReport        OUT WCT_REPORT_SALES_LIST);

--   FUNCTION GET_GDGI_RESERVATION_WS (i_Product_Name_Stripped IN VARCHAR2)
--      RETURN NUMBER;

   PROCEDURE CALCULATE_AVAILABLE_QTY (
      i_requested_mfg_part_number     IN     VARCHAR2,
      i_requested_spare_part_number   IN     VARCHAR2,
      i_requested_rf_part_number      IN     VARCHAR2,
      i_requested_ws_part_number      IN     VARCHAR,
      i_region                        IN     VARCHAR2,
      i_requested_qty                 IN     NUMBER,
      o_available_qty_list               OUT WCT_AVAILABLE_QTY_LIST,
      o_rf_ws_qty_list                   OUT WCT_RF_WS_QTY_LIST,
      o_lead_time1                       OUT VARCHAR2,
      o_lead_time2                       OUT VARCHAR2,
      o_lead_time3                       OUT VARCHAR2,
      o_available_qty1                   OUT NUMBER,
      o_available_qty2                   OUT NUMBER,
      o_available_qty3                   OUT NUMBER,
      o_Lead_Time_Count                  OUT NUMBER,
      o_WS_present                       OUT VARCHAR2,
      o_negative_ccw_flag                OUT CHAR);


   PROCEDURE DATA_EXTRACT_MODIFY (
      i_search_list              IN     WCT_BOM_LIST,
      i_Customer_Id              IN     NUMBER,
      i_User_ID                  IN     VARCHAR2,
      i_Search_Type              IN     VARCHAR2,
      i_Quote_Id                 IN     VARCHAR2,
      i_Copy_Quote_Customer_Id   IN     NUMBER,
      o_Search_Result_Object        OUT WCT_SEARCH_RESULT_MOD_OBJECT);



PROCEDURE INVENTORY_DOWNLOAD_MODIFY (
      i_Customer_Region             IN     VARCHAR2,                  -- as is
      i_Inventory_Region_LRO        IN     VARCHAR2,     -- LRO site indicator
      i_Inventory_Region_FVE        IN     VARCHAR2,     -- FVE site indicator
      i_Inventory_Region_GDGI       IN     VARCHAR2,    -- GDGI site indicator
      i_Display_Type                IN     VARCHAR2,                  -- as is
      i_User_Id                     IN     VARCHAR2,                  -- as is
      i_Client_Date_Time            IN     VARCHAR2,                  -- as is
      i_Tier                        IN     NUMBER,    --added new IN parameter
      i_Cap_Flag                    IN     CHAR,      --added new IN parameter
      i_Cap_Value                   IN     NUMBER,    --added new IN parameter
      o_Inventory_Download_Object      OUT WCT_INVENTORY_DOWNLOAD_OBJECT);

--Added by satbanda for Q4FY17 - April Release <Start>
PROCEDURE P_APPROVEDQUOTE_EXCLUDE (
          i_load_type                        VARCHAR2, --QUOTE/LINE
          i_min_row                          VARCHAR2,
          i_max_row                          VARCHAR2,
          i_sort_column_name                 VARCHAR2,
          i_sort_column_by                   VARCHAR2,
          i_user_id                          VARCHAR2,
          i_quote_id                         VARCHAR2,
          i_cust_name                        VARCHAR2,
          i_created_date                     VARCHAR2,
          i_created_by                       VARCHAR2,
          i_deal_value                       NUMBER,
          i_status                           VARCHAR2,
          i_part_number                      VARCHAR2,
          o_approvedquote_tab  OUT NOCOPY    WCT_QUOTE_EXCL_TAB,
          o_quote_detail_tab   OUT NOCOPY    RCEC_RETRIEVE_LINE_TAB,
          o_display_count       OUT  NOCOPY NUMBER
          );
--Added by satbanda for Q4FY17 - April Release <End>

--Added by satbanda for US131874 - October Release <Start>
PROCEDURE P_MFGPID_EOS_VALIDATE (
          i_created_by                       VARCHAR2,
          io_tab_eos_flag  IN OUT WCT_PROPERTY_MAPPING_LIST --Existing object using for PID EOS flag
          );
--Added by satbanda for US131874 - October Release <End>

END WCT_DATA_EXTRACT;
/