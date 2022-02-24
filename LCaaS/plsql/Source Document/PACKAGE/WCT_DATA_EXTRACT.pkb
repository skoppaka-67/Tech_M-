CREATE OR REPLACE PACKAGE BODY CRPEXCESS./*AppDB: 1040323*/                                  "WCT_DATA_EXTRACT"                                   
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
    20-MAR-2017  satbanda                  4.1       removing references to stripped name and RSCM
    25-APR-2017  satbanda                  4.2       Modified for Retrieve lines object's additional attribute in Exclude quotes API
    18-Jul-2017  satbanda                  4.3       Modified for US121008 (Extended Net Price not showing)
    28-Aug-2017  hkarka                    4.4       US134908 - Multiple active RF pid on mfg pid issue in Inventory Download report
    06-Sep-2017  satbanda                  6.0       Modified for US131874 PID Deactivation EPQ2O Changes
    07-Sep-2017  satbanda                  6.1       US134623 -PID Deactivation - EP/Q2O change to restrict DGI inventory for EOS T-4 PIDs
    13-Sep-2017  satbanda                  5.0       US136936 - Discount percentages for approval level in Excess portal
    29-Nov-2017  satbanda                  7.1       US151907 - Modified for Promo Flag for Excess quote lines
    26-OCT-2018  hkarka                    1.7       restrict quote creation when WS PID doesn't exists
	26-OCT-2018  csirigir                  1.8       restrict quote creation when WS PID doesn't exists
   ====================================================================================================*/

   /*PROCEDURE TO FETCH INITIAL DATA*/
   PROCEDURE LOAD_INITIAL_DATA (
      i_User_ID               IN     VARCHAR2,
      o_Initial_Data_Object      OUT WCT_INITIAL_DATA_OBJECT)
   IS
      v_Initial_Data_Object           WCT_INITIAL_DATA_OBJECT;

      v_Property_Mapping_List         WCT_PROPERTY_MAPPING_LIST;
      v_Customer_List                 WCT_CUSTOMER_LIST;
      v_Retrieve_Quotes_List          WCT_RETRIEVE_QUOTES_LIST;
      v_Approval_Quotes_List          WCT_RETRIEVE_QUOTES_LIST;
      v_Approval_Action_Quotes_List   WCT_RETRIEVE_QUOTES_LIST;
      v_All_Quote_List                WCT_RETRIEVE_QUOTES_LIST;

      v_User_Detail_Object            WCT_USER_DETAIL_OBJECT;
      v_Z_Location_List               WCT_VARCHAR_LIST;
      v_locationSub_list              WCT_VARCHARLOC_LIST;

      lv_User_Id                      VARCHAR2 (12);
      lv_Valid_User_Count             NUMBER := 0;
      lv_User_Status                  VARCHAR2 (15);
   BEGIN
      --dbms_output.put_line( 'Start Time=' || TO_CHAR (SYSDATE, 'HH:MI:SS'));
      lv_User_Id := i_User_ID;

      SELECT COUNT (*)
        INTO lv_Valid_User_Count
        FROM WCT_USERS
       WHERE USER_ID = lv_User_Id AND STATUS = v_Status_Active;

      --If VALID user
      IF (lv_Valid_User_Count > 0)
      THEN
         lv_User_Status := 'VALID';

         -- GENERATE PROPERTY MAPPING LIST
         BEGIN
            SELECT WCT_PROPERTY_MAPPING_OBJECT (PROPERTY_TYPE,
                                                PROPERTY_VALUE)
              BULK COLLECT INTO v_Property_Mapping_List
              FROM WCT_PROPERTIES;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               --LOG EXCEPTION
               INSERT INTO WCT_ERROR_LOG
                    VALUES ('GENERATE PROPERTY MAPPING LIST',
                            lv_User_Id,
                            'LOAD_INITIAL_DATA - No data found',
                            SYSDATE);
            WHEN OTHERS
            THEN
               --LOG EXCEPTION
               v_Error_Message := NULL;
               v_Error_Message := SUBSTR (SQLERRM, 1, 200);

               INSERT INTO WCT_ERROR_LOG
                    VALUES ('GENERATE PROPERTY MAPPING LIST',
                            lv_User_Id,
                            'LOAD_INITIAL_DATA - ' || v_Error_Message,
                            SYSDATE);
         END;

         -- <Satya Reddy> <28th jun 2016> added null as this process not required at intial load
         -- GENERATE CUSTOMER LIST
         LOAD_CUSTOMER_LIST (lv_User_Id,
                             v_Customer_List_Type_View,
                             v_Customer_List);

         /*
                  -- GENERATE QUOTE LIST
                  LOAD_RETRIEVE_QUOTE_LIST (lv_User_Id,
                                            v_Load_Type_Complete,
                                            v_Empty_String,
                                            v_Retrieve_Quotes_List);
                  LOAD_ALL_QUOTE_LIST (lv_User_Id,
                                       v_Load_Type_Preview,
                                       v_All_Quote_List);*/

         --FETCH USER DETAILS
         BEGIN
            SELECT WCT_USER_DETAIL_OBJECT (
                      USER_ID,
                      USER_NAME,
                      NVL (JOB_TITLE, v_Empty_String),
                      NVL (PHONE_NUM, v_Empty_String),
                      NVL (CELL_NUM, v_Empty_String),
                      NVL (EMAIL_ADDRESS, v_Empty_String),
                      STATUS,
                      ROLE,
                      IS_ADMIN,
                      IS_READ_ONLY,
                      APPROVER_LEVEL)
              INTO v_User_Detail_Object
              FROM WCT_USERS
             WHERE USER_ID = lv_User_Id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               --LOG EXCEPTION
               INSERT INTO WCT_ERROR_LOG
                    VALUES ('FETCH USER DETAILS',
                            lv_User_Id,
                            'LOAD_INITIAL_DATA - No data found',
                            SYSDATE);
            WHEN OTHERS
            THEN
               --LOG EXCEPTION
               v_Error_Message := NULL;
               v_Error_Message := SUBSTR (SQLERRM, 1, 200);

               INSERT INTO WCT_ERROR_LOG
                    VALUES ('FETCH USER DETAILS',
                            lv_User_Id,
                            'LOAD_INITIAL_DATA - ' || v_Error_Message,
                            SYSDATE);
         END;
      -- <Satya Reddy> <28th jun 2016> added null as this process not required at intial load

      /* IF (v_User_Detail_Object.ACCESS_TYPE_ADMIN = v_Flag_Yes)
       THEN
          -- GENERATE APPROVAL QUOTE LIST
          LOAD_APPROVAL_QUOTE_LIST (lv_User_Id,
                                    v_Load_Type_Action,
                                    v_Approval_Quotes_List);

          -- GENERATE APPROVAL ACTION QUOTE LIST FOR THE USER
          LOAD_APPROVAL_QUOTE_LIST (lv_User_Id,
                                    v_Load_Type_Preview,
                                    v_Approval_Action_Quotes_List);
       ELSE
          v_Approval_Quotes_List := NULL;
          v_Approval_Action_Quotes_List := NULL;
       END IF;*/
      ELSE
         -- INVALID user
         v_Property_Mapping_List := NULL;
         v_Customer_List := NULL;
         v_Retrieve_Quotes_List := NULL;
         lv_User_Status := 'INVALID';
         v_User_Detail_Object := NULL;
         v_Approval_Quotes_List := NULL;
         v_All_Quote_List := NULL;
      END IF;

      -- Load Z location list for inventory download
      BEGIN
           /*SELECT DISTINCT ZLOC
             BULK COLLECT INTO v_Z_Location_List
             FROM VV_ADM_ZLOCATION_TABLE
         ORDER BY ZLOC;*/
           SELECT DISTINCT ZLOC || ':' || REGION_NAME
             BULK COLLECT INTO v_Z_Location_List
             FROM VAVNI_CISCO_RSCM_ADMIN.VV_ADM_ZLOCATION_TABLE
         ORDER BY 1;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_Z_Location_List := WCT_VARCHAR_LIST ();

            --LOG EXCEPTION
            INSERT INTO WCT_ERROR_LOG
                 VALUES ('FETCH ZLOC DETAILS',
                         lv_User_Id,
                         'LOAD_INITIAL_DATA - No data found',
                         SYSDATE);
         WHEN OTHERS
         THEN
            v_Z_Location_List := WCT_VARCHAR_LIST ();
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message := SUBSTR (SQLERRM, 1, 200);

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('FETCH ZLOC DETAILS',
                         lv_User_Id,
                         'LOAD_INITIAL_DATA - ' || v_Error_Message,
                         SYSDATE);
      END;

      BEGIN
           /*SELECT DISTINCT INVLOC
             BULK COLLECT INTO v_locationSub_list
             FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
         ORDER BY INVLOC;*/
           SELECT DISTINCT DESTINATION_SUBINVENTORY
             BULK COLLECT INTO v_locationSub_list
             FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
            WHERE DESTINATION_SUBINVENTORY IN ('FG',
                                               'WS-FGSLD',
                                               'WS-DGI',
                                               'WS-FGI',
                                               'WS-LT',
                                               'WS-NEW',
                                               'WS-NEW-X',
                                               'WS-NRHS',
                                               'POE-DGI',
                                               'POE-NEW',
                                               'POE-NEWX',
                                               'POE-NRHS')
         ORDER BY 1;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_locationSub_list := WCT_VARCHARLOC_LIST ();

            --LOG EXCEPTION
            INSERT INTO WCT_ERROR_LOG
                 VALUES ('FETCH ZLOC DETAILS',
                         lv_User_Id,
                         'LOAD_INITIAL_DATA - No data found',
                         SYSDATE);
         WHEN OTHERS
         THEN
            v_locationSub_list := WCT_VARCHARLOC_LIST ();
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message := SUBSTR (SQLERRM, 1, 200);

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('FETCH ZLOC DETAILS',
                         lv_User_Id,
                         'LOAD_INITIAL_DATA - ' || v_Error_Message,
                         SYSDATE);
      END;

      -- <Satya Reddy> <28th jun 2016> added null as this process not required at intial load
      --v_Customer_List   := null;
      v_Retrieve_Quotes_List := NULL;
      v_Approval_Quotes_List := NULL;
      v_Approval_Action_Quotes_List := NULL;
      v_All_Quote_List := NULL;

      v_Initial_Data_Object :=
         WCT_INITIAL_DATA_OBJECT (v_User_Detail_Object,
                                  v_Property_Mapping_List,
                                  v_Customer_List,
                                  v_Retrieve_Quotes_List,
                                  lv_User_Status,
                                  v_Approval_Quotes_List,
                                  v_Z_Location_List,
                                  v_locationSub_list,
                                  v_Approval_Action_Quotes_List,
                                  v_All_Quote_List);

      o_Initial_Data_Object := v_Initial_Data_Object;
   --dbms_output.put_line( 'End Time=' || TO_CHAR (SYSDATE, 'HH:MI:SS'));
   END;

   /* PROCEDURE TO FETCH CUSTOMER LIST */
   PROCEDURE LOAD_CUSTOMER_LIST (
      i_User_Id              IN     VARCHAR2,
      i_Customer_List_Type   IN     VARCHAR2,
      o_Customer_List           OUT WCT_CUSTOMER_LIST)
   IS
      v_Customer_List         WCT_CUSTOMER_LIST;
      lv_User_Id              VARCHAR2 (12);
      lv_Customer_List_Type   VARCHAR2 (6);
   BEGIN
      lv_User_Id := i_User_Id;
      lv_Customer_List_Type := i_Customer_List_Type;

      BEGIN
         IF (lv_Customer_List_Type = v_Customer_List_Type_View)
         THEN
              SELECT WCT_CUSTOMER_OBJECT (
                        CUSTOMER_ID,
                           POC_TITLE
                        || ' '
                        || POC_FIRST_NAME
                        || ' '
                        || POC_LAST_NAME
                        || ', '
                        || COMPANY_NAME,
                        REGION)
                BULK COLLECT INTO v_Customer_List
                FROM WCT_CUSTOMER CUST, WCT_COMPANY_MASTER COM
               WHERE     CUST.STATUS = v_Status_Active
                     AND CUST.COMPANY_ID = COM.COMPANY_ID
            ORDER BY COMPANY_NAME;
         ELSIF (lv_Customer_List_Type = v_Customer_List_Type_Update)
         THEN
              SELECT WCT_CUSTOMER_OBJECT (
                        CUSTOMER_ID,
                           POC_TITLE
                        || ' '
                        || POC_FIRST_NAME
                        || ' '
                        || POC_LAST_NAME
                        || ', '
                        || COMPANY_NAME,
                        REGION)
                BULK COLLECT INTO v_Customer_List
                FROM WCT_CUSTOMER CUST, WCT_COMPANY_MASTER COM
               WHERE CUST.COMPANY_ID = COM.COMPANY_ID
            ORDER BY COMPANY_NAME;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            --LOG EXCEPTION
            INSERT INTO WCT_ERROR_LOG
                 VALUES ('LOAD_INITIAL_DATA',
                         lv_User_Id,
                         'No data found',
                         SYSDATE);
         WHEN OTHERS
         THEN
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message := SUBSTR (SQLERRM, 1, 200);

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('LOAD_INITIAL_DATA',
                         lv_User_Id,
                         v_Error_Message,
                         SYSDATE);
      END;

      o_Customer_List := v_Customer_List;
   END;

   /* PROCEDURE TO FETCH QUOTE LIST */
   PROCEDURE LOAD_RETRIEVE_QUOTE_LIST (
      i_User_Id                IN     VARCHAR2,
      i_Load_Type              IN     VARCHAR2,
      i_Part_Number            IN     VARCHAR2,
      o_Retrieve_Quotes_List      OUT WCT_RETRIEVE_QUOTES_LIST)
   IS
      v_Retrieve_Quotes_List   WCT_RETRIEVE_QUOTES_LIST;
      lv_User_Id               VARCHAR2 (12);
      lv_Load_Type             VARCHAR2 (8);
      lv_Part_Number           VARCHAR2 (30);
      LV_FISCAL_STRT_DATE      VARCHAR2 (20); -- added to capture last fiscal start date
   BEGIN
      lv_User_Id := i_User_Id;
      lv_Part_Number := i_Part_Number;
      lv_Load_Type := i_Load_Type;

      BEGIN
         -- If default retrieval
         IF (lv_Load_Type = v_Load_Type_Complete)
         THEN
            SELECT DISTINCT TRUNC (FISCAL_QTR_START_DATE)
              INTO LV_FISCAL_STRT_DATE
              FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
             WHERE     FISCAL_YEAR_NUMBER =
                          (  (SELECT FISCAL_YEAR_NUMBER
                                FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                               WHERE TRUNC (CALENDAR_DATE) = TRUNC (SYSDATE))
                           - 1)
                   AND FISCAL_QUARTER_NUMBER = 1; --last fiscal year's start date


              SELECT WCT_RETRIEVE_QUOTES_OBJECT (QH.QUOTE_ID,
                                                 COM.COMPANY_NAME,
                                                 QH.CREATED_DATE,
                                                 QH.CREATED_BY,
                                                 QH.DEAL_VALUE,
                                                 QH.STATUS,
                                                 CUST.CUSTOMER_ID,
                                                 SD.STATUS_DESCRIPTION,
                                                 QH.APPROVER_LEVEL_1,
                                                 QH.APPROVER_LEVEL_2)
                BULK COLLECT INTO v_Retrieve_Quotes_List
                FROM WCT_QUOTE_HEADER QH,
                     WCT_CUSTOMER CUST,
                     WCT_COMPANY_MASTER COM,
                     WCT_STATUS_DETAIL SD
               WHERE     1 = 1
                     AND QH.CREATED_DATE >= LV_FISCAL_STRT_DATE --added to restrict data to last fiscal year
                     AND QH.CUSTOMER_ID = CUST.CUSTOMER_ID
                     AND COM.COMPANY_ID = CUST.COMPANY_ID
                     AND QH.STATUS = SD.STATUS
                     AND QH.STATUS NOT IN (v_Status_New, v_Status_Deleted)
            ORDER BY QH.CREATED_DATE DESC;
         ELSIF (lv_Load_Type = v_Load_Type_Search)
         THEN
            -- if part search retrieval
            lv_Part_Number := UPPER (lv_Part_Number);

              SELECT WCT_RETRIEVE_QUOTES_OBJECT (QH.QUOTE_ID,
                                                 COM.COMPANY_NAME,
                                                 QH.CREATED_DATE,
                                                 QH.CREATED_BY,
                                                 QH.DEAL_VALUE,
                                                 QH.STATUS,
                                                 CUST.CUSTOMER_ID,
                                                 SD.STATUS_DESCRIPTION,
                                                 QH.APPROVER_LEVEL_1,
                                                 QH.APPROVER_LEVEL_2)
                BULK COLLECT INTO v_Retrieve_Quotes_List
                FROM WCT_QUOTE_HEADER QH,
                     WCT_QUOTE_LINE QL,
                     WCT_CUSTOMER CUST,
                     WCT_COMPANY_MASTER COM,
                     WCT_STATUS_DETAIL SD
               WHERE     1 = 1
                     AND QH.QUOTE_ID = QL.QUOTE_ID
                     AND QH.CUSTOMER_ID = CUST.CUSTOMER_ID
                     AND COM.COMPANY_ID = CUST.COMPANY_ID
                     AND QH.STATUS = SD.STATUS
                     AND QH.STATUS NOT IN (v_Status_New, v_Status_Deleted)
                     AND (   UPPER (QL.REQUESTED_PART) LIKE
                                '%' || lv_Part_Number || '%'
                          OR UPPER (QL.WHOLESALE_PART) LIKE
                                '%' || lv_Part_Number || '%'
                          OR UPPER (QL.REFURBISHED_PART) LIKE
                                '%' || lv_Part_Number || '%'
                          OR UPPER (QL.MANUFACTURING_PART) LIKE
                                '%' || lv_Part_Number || '%')
            ORDER BY QH.CREATED_DATE DESC;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            --LOG EXCEPTION
            INSERT INTO WCT_ERROR_LOG
                 VALUES ('GENERATE QUOTE LIST',
                         lv_User_Id,
                         'LOAD_RETRIEVE_QUOTE_LIST - No data found',
                         SYSDATE);
         WHEN OTHERS
         THEN
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message := SUBSTR (SQLERRM, 1, 200);

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('GENERATE QUOTE LIST',
                         lv_User_Id,
                         'LOAD_RETRIEVE_QUOTE_LIST - ' || v_Error_Message,
                         SYSDATE);
      END;

      o_Retrieve_Quotes_List := v_Retrieve_Quotes_List;
   END;

   /*PROCEDURE TO GET DATA REFRESH TIME*/
   PROCEDURE GET_DATA_REFRESH_TIME (i_Client_Date_Time   IN     VARCHAR2,
                                    o_Date_Time_String      OUT VARCHAR2)
   IS
      lv_Client_Date_Time   VARCHAR2 (22);
      lv_Date_Time_String   VARCHAR2 (100);
   BEGIN
      lv_Client_Date_Time := i_Client_Date_Time;
      lv_Date_Time_String := v_Empty_String;

      VV_RSCM_UTIL.GET_DATA_REFRESH_TIME (lv_Date_Time_String,
                                          lv_Client_Date_Time);

      o_Date_Time_String := lv_Date_Time_String;
   END;

   /*PROCEDURE TO FETCH DATA FOR BOMs - New Search, Edit Quote and Copy Quote*/
--   PROCEDURE DATA_EXTRACT (
--      i_search_list              IN     WCT_BOM_LIST,
--      i_Customer_Id              IN     NUMBER,
--      i_User_ID                  IN     VARCHAR2,
--      i_Search_Type              IN     VARCHAR2,
--      i_Quote_Id                 IN     VARCHAR2,
--      i_Copy_Quote_Customer_Id   IN     NUMBER,
--      o_Search_Result_Object        OUT WCT_SEARCH_RESULT_OBJECT)
--   IS
--      --   Declare TYPES
--      v_Out_Search_Data_List          WCT_SEARCH_DATA_LIST;
--      v_Search_Data_Object            WCT_SEARCH_DATA_OBJECT;
--      v_Out_Search_Result_Object      WCT_SEARCH_RESULT_OBJECT;
--      v_Sales_History_List            WCT_SALES_HISTORY_LIST;
--      v_Inventory_Detail_List_Local   WCT_INVENTORY_DETAIL_LIST;
--      v_Inventory_Detail_List_Frn     WCT_INVENTORY_DETAIL_LIST;
--      v_Recent_Quotes_List            WCT_RECENT_QUOTES_LIST;
--      v_Customer_Detail_Object        WCT_CUSTOMER_DETAIL_OBJECT;
--      v_Invalid_Part_List             WCT_VARCHAR_LIST;
--      v_Property_Mapping_List         WCT_PROPERTY_MAPPING_LIST;
--      v_Inventory_Detail_Local        WCT_INVENTORY_REGION_OBJECT;
--      v_Inventory_Detail_Foreign      WCT_INVENTORY_REGION_OBJECT;
--      v_Recent_Sales_Object           WCT_SALES_HISTORY_OBJECT;
--      v_Exclude_Pid_List              WCT_VARCHAR_LIST; -- added for exclusion of PID Sept 2014
--      v_Brightline_Plus_Pid_List      WCT_VARCHAR_LIST; -- added for exclusion of PID Sept 2014
--      l_sqerrm                        VARCHAR2 (4000);
--
--      v_RL_Pid_List                   WCT_VARCHAR_LIST; -- added for RL Oct 2014
--      lv_c3_inv_count                 NUMBER;
--
--      TYPE T_PART_DETAILS_OBJECT IS RECORD
--      (
--         product_name          VARCHAR2 (50),
--         product_common_name   VARCHAR2 (50)
--      );
--
--      TYPE T_PART_DETAILS_LIST IS TABLE OF T_PART_DETAILS_OBJECT;
--
--      TYPE T_EDIT_QUOTE_LIST IS TABLE OF WCT_QUOTE_LINE%ROWTYPE;
--
--      v_Part_Details_Object           T_PART_DETAILS_OBJECT;
--      v_Part_Details_List             T_PART_DETAILS_LIST;
--
--      --   Declare local variable
--      lv_Line_No                      VARCHAR2 (1000);
--      lv_Requested_Part               VARCHAR2 (50);
--      lv_Manufacture_Part             VARCHAR2 (50);
--      lv_Refurbished_Part             VARCHAR2 (50);
--      lv_Wholesale_Part               VARCHAR2 (50);
--      lv_Encryption_Status            VARCHAR2 (30);
--      lv_Available_Quantity_1         NUMBER;
--      lv_Available_Quantity_2         NUMBER;
--      lv_Requested_Quantity           NUMBER;
--      lv_Broker_Offer                 NUMBER (15, 2);
--      lv_Broker_Offer_Missing_Flag    CHAR;
--      lv_Glp                          NUMBER (15, 2);
--      lv_Base_Price                   NUMBER (15, 2);
--      lv_Suggested_Price_Old          NUMBER (15, 2);
--      lv_Suggested_Price_New          NUMBER (15, 2);
--      lv_Ext_Sell_Price_1             NUMBER (15, 2);
--      lv_Ext_Sell_Price_2             NUMBER (15, 2);
--      lv_Base_Price_Discount          NUMBER (5, 2);
--      lv_Lead_Time_1                  VARCHAR2 (5);
--      lv_Lead_Time_2                  VARCHAR2 (5);
--      lv_Lead_Time_Count              NUMBER;
--
--      -- Variables for local region
--      lv_Reservation_RF_Quotes_Lcl    NUMBER;
--      lv_Reservation_RF_Backlog_Lcl   NUMBER;
--      lv_Reservation_WS_Order_Lcl     NUMBER;
--      lv_Reservation_POE_For_RF_Lcl   NUMBER;
--
--      lv_Reservation_Total_Lcl        NUMBER;
--      lv_Reservation_Total_RF_Lcl     NUMBER;
--      lv_Reservation_Total_WS_Lcl     NUMBER;
--
--      lv_Available_RF_Lcl             VARCHAR2 (10);
--      lv_Available_WS_Lcl             VARCHAR2 (10);
--      lv_Available_POE_Lcl            VARCHAR2 (10);
--
--      -- Variables for foreign region
--      lv_Reservation_RF_Quotes_Frn    NUMBER;
--      lv_Reservation_RF_Backlog_Frn   NUMBER;
--      lv_Reservation_WS_Order_Frn     NUMBER;
--      lv_Reservation_POE_For_RF_Frn   NUMBER;
--
--      lv_Reservation_Total_Frn        NUMBER;
--      lv_Reservation_Total_RF_Frn     NUMBER;
--      lv_Reservation_Total_WS_Frn     NUMBER;
--
--      lv_Available_RF_Frn             VARCHAR2 (10);
--      lv_Available_WS_Frn             VARCHAR2 (10);
--      lv_Available_POE_Frn            VARCHAR2 (10);
--
--      lv_Product_Name_Stripped        VARCHAR2 (50);
--      lv_Product_Name_Stripped_WS     VARCHAR2 (50);
--      lv_Recent_Price                 NUMBER (15, 2);
--
--      lv_FG_Only                      NUMBER;
--      lv_Base_Discount_Default        NUMBER;
--      lv_Base_Discount_Eos            NUMBER;
--      lv_Base_Discount_Eos_Over       NUMBER;
--      lv_Eos_Date                     DATE;
--      lv_Eos_Over_Date                DATE;
--      lv_Customer_Id                  NUMBER;
--      lv_User_Id                      VARCHAR2 (20);
--      lv_Quote_Id                     VARCHAR2 (10);
--      lv_Quote_Line_Id                NUMBER;
--      lv_Date                         DATE;
--      lv_Deal_Value                   NUMBER (15, 2) := 0.00;
--      lv_Part_Validity_Flag           CHAR;
--      lv_Invalid_Part_Count           NUMBER;
--      lv_index                        NUMBER := 1;
--      lv_RL_Part_Validity_Flag        CHAR;   --added for RL karusing Oct 2014
--
--      lv_Round_Scale                  NUMBER;
--
--      lv_Exclude_Pid_Validity_Flag    CHAR; -- added for exclusion of PID karusing Sept 2014
--      lv_Brightline_Plus_Flag         CHAR; -- added for exclusion of PID karusing Sept 2014
--      lv_Exclude_Pid_Count            NUMBER; --added for exclusion of PID karusing Sept 2014
--      lv_Brightline_Plus_Pid_Count    NUMBER; --added for exclusion of PID karusing Sept 2014
--      lv_Brightline_Category          NUMBER; ---added for exclusion of PID karusing Sept 2014
--
--      lv_RL_Pid_Count                 NUMBER;      --added for RL Pid Oct 2014
--
--      --v_Quote_Line_Insert_List        T_EDIT_QUOTE_LIST;
--      v_Quote_Line_Update_List        T_EDIT_QUOTE_LIST;
--
--      lv_Inventory_Detail_Notes_1     VARCHAR2 (4000) := v_Empty_String;
--      lv_Inventory_Detail_Notes_2     VARCHAR2 (4000) := v_Empty_String;
--      lv_Region_Local                 VARCHAR2 (4);
--      lv_Region_Foreign               VARCHAR2 (4);
--      lv_Static_Price_Exists          CHAR;
--      lv_Copy_Quote_Customer_Id       NUMBER;
--      lv_Old_Quote_Id                 VARCHAR2 (10);
--      lv_Conflicting_Part_Count       NUMBER;
--      lv_Conflicting_Part_Id          VARCHAR2 (50);
--      lv_Conflicting_Part_WS          VARCHAR2 (50);
--
--      lv_Lead_Time_Id                 NUMBER;
--      lv_Row_Id                       NUMBER;
--      lv_Lead_Time_Row_Count          NUMBER;
--      lv_Row_Count                    NUMBER;
--      lv_N_Value                      VARCHAR2 (5);
--
--      -- added for June 2014 release - ruchhabr
--      lv_Gdgi_Reservation             NUMBER;
--      lv_Gdgi_WS_Reservation          NUMBER;
--      lv_Quantity_On_Hand_1           NUMBER;
--      lv_Quantity_In_Transit_1        NUMBER;
--      lv_Quantity_On_Hand_2           NUMBER;
--      lv_Quantity_In_Transit_2        NUMBER;
--      lv_exclude_count                NUMBER;     --added for exclusion of PID
--      IS_RL_AVAILABLE                 NUMBER := 0;              --added for RL
--      lv_Product_Common_Name          VARCHAR2 (50);           -- added for RL
--      lv_Strip_RL                     VARCHAR2 (50);            --added for RL
--
--      lv_RL_Pid_Add                   VARCHAR2 (50);            --added for RL
--   BEGIN
--      v_Out_Search_Data_List := WCT_SEARCH_DATA_LIST ();
--      v_Sales_History_List := WCT_SALES_HISTORY_LIST ();
--      v_Inventory_Detail_List_Local := WCT_INVENTORY_DETAIL_LIST ();
--      v_Inventory_Detail_List_Frn := WCT_INVENTORY_DETAIL_LIST ();
--
--      lv_Customer_Id := i_Customer_Id;
--      lv_User_Id := i_User_ID;
--      lv_Quote_Id := i_Quote_Id;
--      lv_Copy_Quote_Customer_Id := i_Copy_Quote_Customer_Id;
--      lv_Old_Quote_Id := i_Quote_Id;
--
--      -- insert into nar(seq,quote_id, issue) values(1,'Data Extract=> '||lv_Quote_Id||' quotes '||lv_Old_Quote_Id,lv_Customer_Id||' lv_Customer_Id$lv_User_Id '||lv_User_Id ); commit;
--      -- Fetch current date
--      SELECT SYSTIMESTAMP INTO lv_Date FROM DUAL;
--
--      -- Start of code changes done by Infosys for April 2014 release - ravchitt
--      -- Fetch region for customer
--      IF (lv_Copy_Quote_Customer_Id IS NOT NULL)
--      THEN
--         IF (lv_Copy_Quote_Customer_Id <> lv_Customer_Id)
--         THEN
--            lv_Customer_Id := lv_Copy_Quote_Customer_Id;
--            lv_Copy_Quote_Customer_Id := i_Customer_Id;
--         END IF;
--      END IF;
--
--      SELECT REGION
--        INTO lv_Region_Local
--        FROM WCT_CUSTOMER CUST, WCT_COMPANY_MASTER COM
--       WHERE     CUSTOMER_ID = lv_Customer_Id
--             AND CUST.COMPANY_ID = COM.COMPANY_ID;
--
--      -- End of code changes done by Infosys for April 2014 release ravchitt
--      CASE
--         WHEN lv_Region_Local = 'NAM'
--         THEN
--            lv_Region_Foreign := 'EMEA';
--         WHEN lv_Region_Local = 'EMEA'
--         THEN
--            lv_Region_Foreign := 'NAM';
--      END CASE;
--
--      v_Invalid_Part_List := WCT_VARCHAR_LIST ();
--      lv_Invalid_Part_Count := 1;
--
--      v_Exclude_Pid_List := WCT_VARCHAR_LIST ();
--      lv_Exclude_Pid_Count := 1;
--
--      v_Brightline_Plus_Pid_List := WCT_VARCHAR_LIST ();
--      lv_Brightline_Plus_Pid_Count := 1;
--
--      v_RL_Pid_List := WCT_VARCHAR_LIST ();
--      lv_RL_Pid_Count := 1;
--
--      --8.2 Get currency rounding scale and system discount from Properties table
--
--      -- Fetch all properties in 1 query
--      SELECT WCT_PROPERTY_MAPPING_OBJECT (PROPERTY_TYPE, PROPERTY_VALUE)
--        BULK COLLECT INTO v_Property_Mapping_List
--        FROM WCT_PROPERTIES
--       WHERE PROPERTY_TYPE IN ('CURRENCY_ROUNDING_SCALE',
--                               'SYSTEM_DISCOUNT_DEFAULT',
--                               'SYSTEM_DISCOUNT_EOS',
--                               'SYSTEM_DISCOUNT_EOS_OVER');
--
--      FOR idx IN 1 .. v_Property_Mapping_List.COUNT ()
--      LOOP
--         IF (v_Property_Mapping_List (idx).PROPERTY_TYPE =
--                'CURRENCY_ROUNDING_SCALE')
--         THEN
--            lv_Round_Scale :=
--               TO_NUMBER (v_Property_Mapping_List (idx).PROPERTY_VALUE);
--         ELSIF (v_Property_Mapping_List (idx).PROPERTY_TYPE =
--                   'SYSTEM_DISCOUNT_DEFAULT')
--         THEN
--            lv_Base_Discount_Default :=
--               v_Property_Mapping_List (idx).PROPERTY_VALUE;
--         ELSIF (v_Property_Mapping_List (idx).PROPERTY_TYPE =
--                   'SYSTEM_DISCOUNT_EOS')
--         THEN
--            lv_Base_Discount_Eos :=
--               v_Property_Mapping_List (idx).PROPERTY_VALUE;
--         ELSIF (v_Property_Mapping_List (idx).PROPERTY_TYPE =
--                   'SYSTEM_DISCOUNT_EOS_OVER')
--         THEN
--            lv_Base_Discount_Eos_Over :=
--               v_Property_Mapping_List (idx).PROPERTY_VALUE;
--         END IF;
--      END LOOP;
--
--      lv_Base_Price_Discount := lv_Base_Discount_Default;
--
--      SELECT ADD_MONTHS (SYSDATE, -12) INTO lv_Eos_Over_Date FROM DUAL;
--
--      --      idx:=1;
--      FOR idx IN 1 .. i_search_list.COUNT ()
--      LOOP
--         EXIT WHEN idx IS NULL;
--         --1.0 Extract input values to local variables
--         lv_Line_No := i_search_list (idx).LINE_NO;
--         lv_Requested_Part := i_search_list (idx).REQUESTED_PART;
--         lv_Requested_Quantity := i_search_list (idx).QUANTITY;
--         lv_Broker_Offer_Missing_Flag :=
--            UPPER (i_search_list (idx).BROKER_OFFER_MISSING_FLAG);
--
--         IF (lv_Broker_Offer_Missing_Flag = v_Flag_Yes)
--         THEN
--            lv_Broker_Offer := NULL;
--         ELSE
--            lv_Broker_Offer := i_search_list (idx).BROKER_OFFER;
--         END IF;
--
--         -- Reset local variales
--         lv_Manufacture_Part := v_Empty_String;
--         lv_Refurbished_Part := v_Empty_String;
--         lv_Wholesale_Part := v_Empty_String;
--         lv_Encryption_Status := v_Empty_String;
--         lv_Row_Id := 1;
--         lv_Ext_Sell_Price_2 := 0;
--         lv_Exclude_Pid_Validity_Flag := v_Flag_Yes;
--         lv_Brightline_Plus_Flag := v_Flag_Yes;
--         lv_RL_Part_Validity_Flag := v_Flag_Yes;
--
--         --Validate each BOM
--         --Using VALIDATE_PART_ID from VV_RSCM_UTIL - Setting NULL for Region
--         lv_Part_Validity_Flag :=
--            VV_RSCM_UTIL.VALIDATE_PART_ID_EXCESS_MODIFY (lv_Requested_Part,
--                                                         NULL);
--
--         -- start: add exclusion logic - arrajago,Aug 2014
--         lv_exclude_count := 0;
--         lv_Brightline_Category := 0;
--
--         -- Get Part Stripped name
--         lv_Product_Name_Stripped :=
--            VV_RSCM_UTIL.GET_STRIPPED_NAME (lv_Requested_Part); -- to restrict WS,MFG,spare PID if any one is brightline
--
--
--         SELECT COUNT (1)
--           INTO lv_exclude_count
--           FROM vavni_cisco_rscm_admin.WCT_EXCLUDE_PID
--          WHERE        STATUS = 'ACTIVE'
--                   AND EXCLUDE_TIER1 = 'Y'
--                   AND EXCLUDE_TIER2 = 'Y'
--                   AND EXCLUDE_TIER3 = 'Y'
--                   AND (   BRIGHTLINE_CATEGORY = '1'
--                        OR BRIGHTLINE_CATEGORY = '2')
--                   -- AND PRODUCT_ID = lv_Requested_Part;
--                   AND PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped -- added to restrict WS,Spare PID and MFG PID.
--                OR PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped || 'WS'
--                OR PRODUCT_NAME_STRIPPED =
--                      DECODE (
--                         SUBSTR (
--                            lv_Product_Name_Stripped,
--                            (  LENGTH (lv_Product_Name_Stripped)
--                             - LENGTH (lv_Product_Name_Stripped)
--                             - 2)),
--                         'WS', SUBSTR (lv_Product_Name_Stripped,
--                                       1,
--                                       LENGTH (lv_Product_Name_Stripped) - 2));
--
--         --OR PRODUCT_NAME_STRIPPED =
--         --      SUBSTR (lv_Product_Name_Stripped,
--         --             1,
--         --             LENGTH (lv_Product_Name_Stripped) - 2);
--
--
--
--         BEGIN
--            --            SELECT BRIGHTLINE_CATEGORY
--            --              INTO lv_Brightline_Category
--            --              FROM WCT_EXCLUDE_PID
--            --             WHERE PRODUCT_ID = lv_Requested_Part;
--
--
--
--            SELECT BRIGHTLINE_CATEGORY
--              INTO lv_Brightline_Category
--              FROM vavni_cisco_rscm_admin.WCT_EXCLUDE_PID
--             WHERE    PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped -- added to restrict WS,Spare PID and MFG PID.
--                   OR PRODUCT_NAME_STRIPPED =
--                         lv_Product_Name_Stripped || 'WS'
--                   OR PRODUCT_NAME_STRIPPED =
--                         DECODE (
--                            SUBSTR (
--                               lv_Product_Name_Stripped,
--                               (  LENGTH (lv_Product_Name_Stripped)
--                                - LENGTH (lv_Product_Name_Stripped)
--                                - 2)),
--                            'WS', SUBSTR (
--                                     lv_Product_Name_Stripped,
--                                     1,
--                                     LENGTH (lv_Product_Name_Stripped) - 2));
--         --   OR PRODUCT_NAME_STRIPPED =
--         --        SUBSTR (lv_Product_Name_Stripped,
--         --                1,
--         --                LENGTH (lv_Product_Name_Stripped) - 2);
--
--         EXCEPTION
--            WHEN NO_DATA_FOUND
--            THEN
--               lv_Brightline_Category := 0;
--         END;
--
--         IF     (lv_Part_Validity_Flag = v_Flag_Yes)
--            AND (lv_exclude_count > 0)
--            AND (lv_Brightline_Category = 1)  -- category 1 for brightline PID
--         THEN
--            lv_Exclude_Pid_Validity_Flag := v_Flag_No;
--         ELSIF     (lv_Part_Validity_Flag = v_Flag_Yes)
--               AND (lv_exclude_count > 0)
--               AND (lv_Brightline_Category = 2) -- category 2 for brightline Plus PID
--         THEN
--            lv_Brightline_Plus_Flag := v_Flag_No;
--         ELSIF (lv_Part_Validity_Flag = v_Flag_No) AND (lv_exclude_count > 0)
--         THEN
--            lv_Part_Validity_Flag := v_Flag_No;
--         ELSIF (lv_Part_Validity_Flag = v_Flag_No)
--         THEN
--            lv_Requested_Part := lv_Requested_Part || '=';
--            lv_Part_Validity_Flag :=
--               VV_RSCM_UTIL.VALIDATE_PART_ID_EXCESS_MODIFY (
--                  lv_Requested_Part,
--                  NULL);
--         END IF;
--
--         -- end: add exclusion logic - arrajago, Aug 2014
--
--         -- If invalid part found, add it to invalid part list
--         IF (lv_Part_Validity_Flag = v_Flag_No)
--         THEN
--            lv_RL_Pid_Add := i_search_list (idx).REQUESTED_PART;
--
--            SELECT    SUBSTR (lv_RL_Pid_Add, 1, LENGTH (lv_RL_Pid_Add) - 2)
--                   || 'RL'
--              INTO lv_Strip_RL
--              FROM DUAL;
--
--            lv_RL_Part_Validity_Flag :=
--               VV_RSCM_UTIL.VALIDATE_PART_ID_EXCESS_MODIFY (lv_Strip_RL,
--                                                            NULL);
--
--            IF (lv_RL_Part_Validity_Flag = v_Flag_Yes)
--            -- IF( v_Invalid_Part_List(idx).REQUESTED_PART = lv_Strip_RL )
--            --  'SUBSTR(lv_Product_Name_Stripped,1,LENGTH(lv_Product_Name_Stripped)-2)||'RL')'
--            THEN
--               v_RL_Pid_List.EXTEND ();
--               v_RL_Pid_List (lv_RL_Pid_Count) :=
--                  i_search_list (idx).REQUESTED_PART;
--               lv_RL_Pid_Count := lv_RL_Pid_Count + 1;
--            ELSE
--               v_Invalid_Part_List.EXTEND ();
--               v_Invalid_Part_List (lv_Invalid_Part_Count) :=
--                  i_search_list (idx).REQUESTED_PART;
--               lv_Invalid_Part_Count := lv_Invalid_Part_Count + 1;
--            END IF;
--         --END IF;
--         -- if exclude PID found, add to exclusion list
--         ELSIF (lv_Exclude_Pid_Validity_Flag = v_Flag_No)
--         THEN
--            v_Exclude_Pid_List.EXTEND ();
--            v_Exclude_Pid_List (lv_Exclude_Pid_Count) :=
--               i_search_list (idx).REQUESTED_PART;
--            lv_Exclude_Pid_Count := lv_Exclude_Pid_Count + 1;
--         --if brightline plus Pid found add to brightline plus list
--         ELSIF (lv_Brightline_Plus_Flag = v_Flag_No)
--         THEN
--            v_Brightline_Plus_Pid_List.EXTEND ();
--            v_Brightline_Plus_Pid_List (lv_Brightline_Plus_Pid_Count) :=
--               i_search_list (idx).REQUESTED_PART;
--            lv_Brightline_Plus_Pid_Count := lv_Brightline_Plus_Pid_Count + 1;
--         ELSE
--            --Fetch data for the requested part
--
--
--            --            -- Get Part Stripped name
--            --            lv_Product_Name_Stripped :=
--            --               VV_RSCM_UTIL.GET_STRIPPED_NAME (lv_Requested_Part);
--
--            IF (lv_Requested_Part LIKE '%-RL') -- OR lv_Requested_Part LIKE '%-RF')
--            THEN
--               lv_Product_Name_Stripped_WS :=
--                     SUBSTR (lv_Product_Name_Stripped,
--                             1,
--                             LENGTH (lv_Product_Name_Stripped) - 2)
--                  || 'WS';
--            ELSIF (lv_Requested_Part NOT LIKE '%-WS')
--            THEN
--               lv_Product_Name_Stripped_WS := lv_Product_Name_Stripped || 'WS';
--            ELSIF (lv_Requested_Part LIKE '%-WS')
--            THEN
--               lv_Product_Name_Stripped_WS := lv_Product_Name_Stripped;
--               lv_Product_Name_Stripped :=
--                  SUBSTR (lv_Product_Name_Stripped,
--                          1,
--                          LENGTH (lv_Product_Name_Stripped) - 2);
--            END IF;
--
--            --2.0 Compute Recent 3 quotes
--            /*BEGIN
--               SELECT WCT_RECENT_QUOTES_OBJECT (LAST_UPDATED_BY,
--                                                REQUESTED_QUANTITY,
--                                                LAST_UPDATED_DATE,
--                                                SUGGESTED_PRICE,
--                                                COMPANY_NAME)
--                 BULK COLLECT INTO v_Recent_Quotes_List
--                 FROM (SELECT headerTBL.LAST_UPDATED_BY,
--                              lineTBL.REQUESTED_QUANTITY,
--                              headerTBL.LAST_UPDATED_DATE,
--                              lineTBL.SUGGESTED_PRICE,
--                              companyTBL.COMPANY_NAME,
--                              ROW_NUMBER ()
--                              OVER (
--                                 ORDER BY headerTBL.LAST_UPDATED_DATE DESC)
--                                 RNO
--                         FROM WCT_QUOTE_LINE lineTBL,
--                              WCT_QUOTE_HEADER headerTBL,
--                              WCT_CUSTOMER customerTBL,
--                              WCT_COMPANY_MASTER companyTBL
--                        WHERE (    headerTBL.QUOTE_ID = lineTBL.QUOTE_ID
--                               AND headerTBL.STATUS = 'QUOTE'
--                               AND lineTBL.REQUESTED_PART = lv_Requested_Part
--                               AND headerTBL.CUSTOMER_ID =
--                                      customerTBL.CUSTOMER_ID
--                               AND customerTBL.COMPANY_ID =
--                                      companyTBL.COMPANY_ID))
--                WHERE RNO <= 3;
--            EXCEPTION
--               WHEN NO_DATA_FOUND
--               THEN
--                  --LOG EXCEPTION
--                  INSERT INTO WCT_ERROR_LOG
--                       VALUES (UPPER (lv_Requested_Part),
--                               lv_User_Id,
--                               'Data_extract - Step 2.0 - No data found',
--                               SYSDATE);
--               WHEN OTHERS
--               THEN
--                  --LOG EXCEPTION
--                  v_Error_Message := NULL;
--                  v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--                  INSERT INTO WCT_ERROR_LOG
--                       VALUES (
--                                 UPPER (lv_Requested_Part),
--                                 lv_User_Id,
--                                    'Data_extract - Step 2.0 - '
--                                 || v_Error_Message,
--                                 SYSDATE);
--            END;*/
--            v_Recent_Quotes_List :=
--               GET_RECENT_QUOTE_DETAILS (lv_Requested_Part, lv_User_Id);
--
--            --3.0 Get basic attributes like Manufacture Part, Refurbished Part, Wholesale part, Encryption Status, GLP
--            -- 3.0.1 Get conflicting part count
--            SELECT COUNT (*)
--              INTO lv_Conflicting_Part_Count
--              FROM WCT_CONFLICTING_PARTS
--             WHERE PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped;
--
--            --3.1 Fetch Manufacture Part
--            BEGIN
--               IF (lv_Conflicting_Part_Count > 1)
--               THEN
--                  SELECT PRODUCT_ID, PRODUCT_ID_WHOLESALE
--                    INTO lv_Conflicting_Part_Id, lv_Conflicting_Part_WS
--                    FROM WCT_CONFLICTING_PARTS
--                   WHERE     1 = 1
--                         AND (   PRODUCT_ID = lv_Requested_Part
--                              OR PRODUCT_ID_REFURBISHED = lv_Requested_Part
--                              OR PRODUCT_ID_WHOLESALE = lv_Requested_Part);
--
--                  SELECT PRODUCT_NAME, PRODUCT_COMMON_NAME
--                    BULK COLLECT INTO v_Part_Details_List
--                    FROM (SELECT DISTINCT
--                                 PM_PROD.PRODUCT_NAME,
--                                 PM_PROD.PRODUCT_COMMON_NAME
--                            FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
--                           WHERE    PM_PROD.PRODUCT_NAME =
--                                       lv_Conflicting_Part_Id
--                                 OR PM_PROD.PRODUCT_NAME =
--                                       lv_Conflicting_Part_WS);
--               ELSE
--                  SELECT COUNT (*)
--                    INTO IS_RL_AVAILABLE
--                    FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW
--                   WHERE    PRODUCT_NAME_STRIPPED =
--                               lv_Product_Name_Stripped || '%RL'
--                         OR PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped;
--
--                  -- SELECT PRODUCT_COMMON_NAME INTO lv_Product_Common_Name from VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW where
--                  -- UPPER(PRODUCT_NAME)=UPPER(lv_Requested_Part);
--
--                  IF (IS_RL_AVAILABLE > 0)
--                  THEN
--                     IF (lv_Requested_Part LIKE '%-RF') -- OR lv_Requested_Part=lv_Product_Common_Name)
--                     THEN
--                        SELECT PRODUCT_NAME, PRODUCT_COMMON_NAME
--                          BULK COLLECT INTO v_Part_Details_List
--                          FROM (SELECT DISTINCT
--                                       PM_PROD.PRODUCT_NAME,
--                                       PM_PROD.PRODUCT_COMMON_NAME
--                                  FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
--                                 WHERE (   (    (   PM_PROD.PRODUCT_NAME_STRIPPED =
--                                                       lv_Product_Name_Stripped
--                                                 OR PM_PROD.PRODUCT_NAME_STRIPPED =
--                                                       -- added for mapping RF part with RL part
--                                                       SUBSTR (
--                                                          lv_Product_Name_Stripped,
--                                                          1,
--                                                            LENGTH (
--                                                               lv_Product_Name_Stripped)
--                                                          - 2)
--                                                 OR PM_PROD.PRODUCT_NAME_STRIPPED =
--                                                          lv_Product_Name_Stripped
--                                                       || 'RL')
--                                            AND PM_PROD.PRODUCT_NAME LIKE
--                                                   '%-RF')
--                                        OR PM_PROD.PRODUCT_NAME_STRIPPED =
--                                              lv_Product_Name_Stripped_WS
--                                        OR PM_PROD.PRODUCT_NAME_STRIPPED =
--                                                 lv_Product_Name_Stripped
--                                              || 'WS'));
--                     ELSE
--                        SELECT PRODUCT_NAME, PRODUCT_COMMON_NAME
--                          BULK COLLECT INTO v_Part_Details_List
--                          FROM (  SELECT DISTINCT
--                                         PM_PROD.PRODUCT_NAME,
--                                         PM_PROD.PRODUCT_COMMON_NAME
--                                    FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
--                                   WHERE (   PM_PROD.PRODUCT_NAME_STRIPPED =
--                                                lv_Product_Name_Stripped
--                                          OR PM_PROD.PRODUCT_NAME_STRIPPED =
--                                                lv_Product_Name_Stripped_WS
--                                          OR PM_PROD.PRODUCT_NAME_STRIPPED =
--                                                -- added for mapping MFG part with RL part
--                                                SUBSTR (
--                                                   lv_Product_Name_Stripped,
--                                                   1,
--                                                     LENGTH (
--                                                        lv_Product_Name_Stripped)
--                                                   - 2)
--                                          OR --added for mapping ws part with RL part
--                                            PM_PROD.PRODUCT_NAME_STRIPPED =
--                                                --added for mapping MFG part with RL part
--                                                (   SUBSTR (
--                                                       lv_Product_Name_Stripped,
--                                                       1,
--                                                         LENGTH (
--                                                            lv_Product_Name_Stripped)
--                                                       - 2)
--                                                 || 'RL')
--                                          OR PM_PROD.PRODUCT_NAME_STRIPPED =
--                                                   lv_Product_Name_Stripped
--                                                || 'RL'
--                                          OR PM_PROD.PRODUCT_NAME_STRIPPED =
--                                                   lv_Product_Name_Stripped
--                                                || 'WS')
--                                ORDER BY product_name ASC);
--                     --                     SELECT DISTINCT PRODUCT_NAME_STRIPPED INTO lv_Product_Name_Stripped
--                     --                     FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW WHERE (PRODUCT_NAME_STRIPPED =
--                     --                                    lv_Product_Name_Stripped OR
--                     --                                    PRODUCT_NAME_STRIPPED =
--                     --                                    lv_Product_Name_Stripped||'RL'
--                     --                                    or
--                     --                                     ) AND PRODUCT_NAME LIKE '%-RL';
--                     END IF;
--                  ELSE
--                     SELECT PRODUCT_NAME, PRODUCT_COMMON_NAME
--                       BULK COLLECT INTO v_Part_Details_List
--                       FROM (SELECT DISTINCT
--                                    PM_PROD.PRODUCT_NAME,
--                                    PM_PROD.PRODUCT_COMMON_NAME
--                               FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
--                              WHERE    PM_PROD.PRODUCT_NAME_STRIPPED =
--                                          lv_Product_Name_Stripped
--                                    OR PM_PROD.PRODUCT_NAME_STRIPPED =
--                                          lv_Product_Name_Stripped_WS);
--                  END IF;
--               END IF;
--
--               IF (v_Part_Details_List.COUNT () > 0)
--               THEN
--                  FOR i IN 1 .. v_Part_Details_List.COUNT ()
--                  LOOP
--                     v_Part_Details_Object := v_Part_Details_List (i);
--
--                     IF (v_Part_Details_Object.product_name LIKE '%WS')
--                     THEN
--                        lv_Wholesale_Part :=
--                           v_Part_Details_Object.product_name;
--                     ELSIF (v_Part_Details_Object.product_name LIKE '%-RF')
--                     THEN
--                        lv_Refurbished_Part :=
--                           v_Part_Details_Object.product_name;
--                     ELSIF (v_Part_Details_Object.product_name LIKE '%-RL')
--                     THEN
--                        lv_Refurbished_Part :=
--                           v_Part_Details_Object.product_name;
--                     END IF;
--
--                     lv_Manufacture_Part :=
--                        v_Part_Details_Object.product_common_name;
--                  END LOOP;
--               ELSE
--                  lv_Refurbished_Part := v_Empty_String;
--                  lv_Wholesale_Part := v_Empty_String;
--
--                  --3.1.1 - If Product is not found in RSCM, get this info from New Product Master table which contains all Cisco PIDs
--                  BEGIN
--                     SELECT DISTINCT PRODUCT_ID
--                       INTO lv_Manufacture_Part
--                       FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
--                      WHERE PRODUCT_ID = lv_Requested_Part;
--                  EXCEPTION
--                     WHEN NO_DATA_FOUND
--                     THEN
--                        BEGIN
--                           SELECT DISTINCT PRODUCT_ID
--                             INTO lv_Manufacture_Part
--                             FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
--                            WHERE PRODUCT_ID = lv_Requested_Part || '=';
--                        EXCEPTION
--                           WHEN NO_DATA_FOUND
--                           THEN
--                              lv_Manufacture_Part := v_Empty_String;
--                        END;
--                  END;
--               END IF;
--            EXCEPTION
--               --LOG EXCEPTION
--               WHEN OTHERS
--               THEN
--                  --LOG EXCEPTION
--                  v_Error_Message := NULL;
--                  v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--                  INSERT INTO WCT_ERROR_LOG
--                          VALUES (
--                                    UPPER (lv_Requested_Part),
--                                    lv_User_Id,
--                                       'Data_extract - Step 3.1 - '
--                                    || v_Error_Message,
--                                    SYSDATE);
--            END;
--
--            --3.2 Fetch Encryption Status, GLP, EOS
--            BEGIN
--               SELECT ENCRYPTION_STATUS,
--                      NVL (LIST_PRICE, 0),
--                      NVL (EO_SALES_DATE,
--                           TO_DATE ('12/31/2999', 'MM/DD/YYYY')) -- '12/31/2999' Added for assigning far off value to NUll value
--                 INTO lv_Encryption_Status, lv_Glp, lv_Eos_Date
--                 FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
--                WHERE PRODUCT_ID = lv_Manufacture_Part; -- Any query to RMK_CISCO_PRODUCT_MASTER should run on MFG part
--
--               -- if GLP is 0, Try with = appended to MFG part
--               IF (lv_Glp = 0)
--               THEN
--                  BEGIN
--                     IF (SUBSTR (lv_Manufacture_Part, -1, 1) = '=')
--                     THEN
--                        SELECT ENCRYPTION_STATUS,
--                               NVL (LIST_PRICE, 0),
--                               NVL (EO_SALES_DATE,
--                                    TO_DATE ('12/31/2999', 'MM/DD/YYYY')) -- '12/31/2999' Added for assigning far off value to NUll value
--                          INTO lv_Encryption_Status, lv_Glp, lv_Eos_Date
--                          FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
--                         WHERE PRODUCT_ID =
--                                  SUBSTR (lv_Manufacture_Part,
--                                          1,
--                                          (LENGTH (lv_Manufacture_Part) - 1)); -- Try with = removed from MFG part
--                     ELSE
--                        SELECT ENCRYPTION_STATUS,
--                               NVL (LIST_PRICE, 0),
--                               NVL (EO_SALES_DATE,
--                                    TO_DATE ('12/31/2999', 'MM/DD/YYYY')) -- '12/31/2999' Added for assigning far off value to NUll value
--                          INTO lv_Encryption_Status, lv_Glp, lv_Eos_Date
--                          FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
--                         WHERE PRODUCT_ID = (lv_Manufacture_Part || '='); -- Try with = appended to MFG part
--                     END IF;
--                  EXCEPTION
--                     WHEN NO_DATA_FOUND
--                     THEN
--                        lv_Glp := 0;
--                  END;
--               END IF;
--            EXCEPTION
--               WHEN NO_DATA_FOUND
--               THEN
--                  BEGIN
--                     IF (SUBSTR (lv_Manufacture_Part, -1, 1) = '=')
--                     THEN
--                        SELECT ENCRYPTION_STATUS,
--                               NVL (LIST_PRICE, 0),
--                               NVL (EO_SALES_DATE,
--                                    TO_DATE ('12/31/2999', 'MM/DD/YYYY')) -- '12/31/2999' Added for assigning far off value to NUll value
--                          INTO lv_Encryption_Status, lv_Glp, lv_Eos_Date
--                          FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
--                         WHERE PRODUCT_ID =
--                                  SUBSTR (lv_Manufacture_Part,
--                                          1,
--                                          (LENGTH (lv_Manufacture_Part) - 1)); -- Try with = removed from MFG part
--                     ELSE
--                        SELECT ENCRYPTION_STATUS,
--                               NVL (LIST_PRICE, 0),
--                               NVL (EO_SALES_DATE,
--                                    TO_DATE ('12/31/2999', 'MM/DD/YYYY')) -- '12/31/2999' Added for assigning far off value to NUll value
--                          INTO lv_Encryption_Status, lv_Glp, lv_Eos_Date
--                          FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
--                         WHERE PRODUCT_ID = (lv_Manufacture_Part || '='); -- Try with = appended to MFG part
--                     END IF;
--                  EXCEPTION
--                     WHEN NO_DATA_FOUND
--                     THEN
--                        lv_Glp := 0;
--
--                        --LOG EXCEPTION
--                        INSERT INTO WCT_ERROR_LOG
--                                VALUES (
--                                          UPPER (lv_Requested_Part),
--                                          lv_User_Id,
--                                          'Data_extract - Step 3.2 - No data found',
--                                          SYSDATE);
--                  END;
--               WHEN OTHERS
--               THEN
--                  lv_Glp := 0;
--
--                  --LOG EXCEPTION
--                  v_Error_Message := NULL;
--                  v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--                  INSERT INTO WCT_ERROR_LOG
--                          VALUES (
--                                    UPPER (lv_Requested_Part),
--                                    lv_User_Id,
--                                       'Data_extract - Step 3.2 - '
--                                    || v_Error_Message,
--                                    SYSDATE);
--            END;
--
--            --4.0 Compute Reservations
--            -- 4.0.1 Compute local reservations
--            COMPUTE_RESERVATIONS (lv_Requested_Part,
--                                  lv_Product_Name_Stripped,
--                                  lv_User_Id,
--                                  lv_Region_Local,
--                                  lv_Conflicting_Part_Count,
--                                  lv_Conflicting_Part_Id,
--                                  lv_Conflicting_Part_WS,
--                                  lv_Reservation_RF_Quotes_Lcl,
--                                  lv_Reservation_RF_Backlog_Lcl,
--                                  lv_Reservation_WS_Order_Lcl,
--                                  lv_Reservation_Total_Lcl,
--                                  lv_Reservation_Total_RF_Lcl,
--                                  lv_Reservation_Total_WS_Lcl);
--
--            -- 4.0.2 Compute foreign reservations
--            COMPUTE_RESERVATIONS (lv_Requested_Part,
--                                  lv_Product_Name_Stripped,
--                                  lv_User_Id,
--                                  lv_Region_Foreign,
--                                  lv_Conflicting_Part_Count,
--                                  lv_Conflicting_Part_Id,
--                                  lv_Conflicting_Part_WS,
--                                  lv_Reservation_RF_Quotes_Frn,
--                                  lv_Reservation_RF_Backlog_Frn,
--                                  lv_Reservation_WS_Order_Frn,
--                                  lv_Reservation_Total_Frn,
--                                  lv_Reservation_Total_RF_Frn,
--                                  lv_Reservation_Total_WS_Frn);
--
--            -- 4.0.3 Compute GDGI Reservation
--
--            --   /* Start changes to include FG inventory Aug 2016 */
--            lv_Gdgi_Reservation :=
--               GET_GDGI_RESERVATION (lv_Product_Name_Stripped);
--
--            -- 4.0.4 Update local reservations with GDGI reservation
--            lv_Reservation_RF_Backlog_Lcl :=
--               lv_Reservation_RF_Backlog_Lcl + lv_Gdgi_Reservation;
--
--            lv_Reservation_Total_RF_Lcl :=
--               lv_Reservation_Total_RF_Lcl + lv_Gdgi_Reservation;
--
--            lv_Reservation_Total_Lcl :=
--               lv_Reservation_Total_Lcl + lv_Gdgi_Reservation;
--
--            lv_Gdgi_WS_Reservation :=
--               GET_GDGI_RESERVATION_WS (lv_Product_Name_Stripped_WS);
--
--            lv_Reservation_WS_Order_Lcl :=
--               lv_Reservation_WS_Order_Lcl + lv_Gdgi_WS_Reservation;
--
--            lv_Reservation_Total_WS_Lcl :=
--               lv_Reservation_Total_WS_Lcl + lv_Gdgi_WS_Reservation;
--
--            lv_Reservation_Total_Lcl :=
--               lv_Reservation_Total_Lcl + lv_Gdgi_WS_Reservation;
--
--
--
--            --5.0 Inventory computation
--            -- 5.0.1 Compute Inventory by Sub Locations and Available Quantity
--            compute_inv_and_available_qty (lv_Requested_Part,
--                                           lv_Product_Name_Stripped,
--                                           lv_Wholesale_Part,
--                                           lv_User_Id,
--                                           lv_Requested_Quantity,
--                                           lv_Reservation_Total_RF_Lcl,
--                                           lv_Reservation_Total_WS_Lcl,
--                                           lv_Reservation_Total_RF_Frn,
--                                           lv_Reservation_Total_WS_Frn,
--                                           lv_Region_Local,
--                                           lv_Region_Foreign,
--                                           lv_Conflicting_Part_Count,
--                                           lv_Conflicting_Part_Id,
--                                           lv_Conflicting_Part_WS,
--                                           lv_Reservation_POE_For_RF_Lcl,
--                                           lv_FG_Only,
--                                           lv_Available_RF_Lcl,
--                                           lv_Available_WS_Lcl,
--                                           lv_Available_POE_Lcl,
--                                           lv_Available_Quantity_1,
--                                           lv_Available_Quantity_2,
--                                           v_Inventory_Detail_List_Local,
--                                           v_Inventory_Detail_List_Frn,
--                                           lv_Lead_Time_1,
--                                           lv_Lead_Time_2,
--                                           lv_Lead_Time_Count,
--                                           lv_Inventory_Detail_Notes_1,
--                                           lv_Inventory_Detail_Notes_2,
--                                           lv_Available_RF_Frn,
--                                           lv_Quantity_On_Hand_1, -- added for June 2014 release - ruchhabr
--                                           lv_Quantity_In_Transit_1, -- added for June 2014 release - ruchhabr
--                                           lv_Quantity_On_Hand_2, -- added for June 2014 release - ruchhabr
--                                           lv_Quantity_In_Transit_2); -- added for June 2014 release - ruchhabr
--
--            -- 5.0.2 Create Inventory Objects
--            v_Inventory_Detail_Local :=
--               WCT_INVENTORY_REGION_OBJECT (lv_Reservation_RF_Quotes_Lcl,
--                                            lv_Reservation_RF_Backlog_Lcl,
--                                            lv_Reservation_WS_Order_Lcl,
--                                            lv_Reservation_POE_For_RF_Lcl,
--                                            lv_Reservation_Total_Lcl,
--                                            lv_Reservation_Total_RF_Lcl,
--                                            lv_Reservation_Total_WS_Lcl,
--                                            lv_Available_RF_Lcl,
--                                            lv_Available_WS_Lcl,
--                                            lv_Available_POE_Lcl,
--                                            v_Inventory_Detail_List_Local);
--
--            v_Inventory_Detail_Foreign :=
--               WCT_INVENTORY_REGION_OBJECT (lv_Reservation_RF_Quotes_Frn,
--                                            lv_Reservation_RF_Backlog_Frn,
--                                            lv_Reservation_WS_Order_Frn,
--                                            lv_Reservation_POE_For_RF_Frn,
--                                            lv_Reservation_Total_Frn,
--                                            lv_Reservation_Total_RF_Frn,
--                                            lv_Reservation_Total_WS_Frn,
--                                            lv_Available_RF_Frn,
--                                            lv_Available_WS_Frn,
--                                            lv_Available_POE_Frn,
--                                            v_Inventory_Detail_List_Frn);
--
--            --6.0 Fetch Sales history details
--            --6.1 Fetch sales history list
--            BEGIN
--               IF (lv_Conflicting_Part_Count > 1)
--               THEN
--                  SELECT WCT_SALES_HISTORY_OBJECT (BASE_UNIT_PRICE,
--                                                   SALES_ORDER_DATE,
--                                                   CUSTOMER_NAME,
--                                                   QUANTITY_ORDERED)
--                    BULK COLLECT INTO v_Sales_History_List
--                    FROM (SELECT WSPR.BASE_UNIT_PRICE,
--                                 WSPR.SALES_ORDER_DATE,
--                                 WSPR.CUSTOMER_NAME,
--                                 WSPR.QUANTITY_ORDERED,
--                                 ROW_NUMBER ()
--                                    OVER (ORDER BY SALES_ORDER_DATE DESC)
--                                    RNO
--                            FROM RMKTGADM.RMK_WS_AR_BACKLOG_SHIPMENT WSPR
--                           WHERE     1 = 1
--                                 AND (   WSPR.PRODUCT_ID =
--                                            lv_Conflicting_Part_Id
--                                      OR WSPR.PRODUCT_ID =
--                                            lv_Conflicting_Part_WS)
--                                 AND SALES_ORDER_DATE >
--                                        ADD_MONTHS (SYSDATE, -6))
--                   WHERE RNO <= 5;
--               ELSE
--                  SELECT WCT_SALES_HISTORY_OBJECT (BASE_UNIT_PRICE,
--                                                   SALES_ORDER_DATE,
--                                                   CUSTOMER_NAME,
--                                                   QUANTITY_ORDERED)
--                    BULK COLLECT INTO v_Sales_History_List
--                    FROM (SELECT WSPR.BASE_UNIT_PRICE,
--                                 WSPR.SALES_ORDER_DATE,
--                                 WSPR.CUSTOMER_NAME,
--                                 WSPR.QUANTITY_ORDERED,
--                                 ROW_NUMBER ()
--                                    OVER (ORDER BY SALES_ORDER_DATE DESC)
--                                    RNO
--                            FROM RMKTGADM.RMK_WS_AR_BACKLOG_SHIPMENT WSPR
--                           WHERE     1 = 1
--                                 AND (   WSPR.PRODUCT_NAME_STRIPPED =
--                                            lv_Product_Name_Stripped
--                                      OR WSPR.PRODUCT_NAME_STRIPPED =
--                                            lv_Product_Name_Stripped_WS)
--                                 AND SALES_ORDER_DATE >
--                                        ADD_MONTHS (SYSDATE, -6))
--                   WHERE RNO <= 5;
--               END IF;
--            EXCEPTION
--               WHEN NO_DATA_FOUND
--               THEN
--                  --LOG EXCEPTION
--                  INSERT INTO WCT_ERROR_LOG
--                       VALUES (UPPER (lv_Requested_Part),
--                               lv_User_Id,
--                               'Data_extract - Step 6.1 - No data found',
--                               SYSDATE);
--               WHEN OTHERS
--               THEN
--                  --LOG EXCEPTION
--                  v_Error_Message := NULL;
--                  v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--                  INSERT INTO WCT_ERROR_LOG
--                          VALUES (
--                                    UPPER (lv_Requested_Part),
--                                    lv_User_Id,
--                                       'Data_extract - Step 6.1 - '
--                                    || v_Error_Message,
--                                    SYSDATE);
--            END;
--
--            --6.2 fetch last sold price to the customer
--            BEGIN
--               IF (lv_Conflicting_Part_Count > 1)
--               THEN
--                    SELECT WCT_SALES_HISTORY_OBJECT (WSPR.BASE_UNIT_PRICE,
--                                                     WSPR.SALES_ORDER_DATE,
--                                                     WSPR.CUSTOMER_NAME,
--                                                     WSPR.QUANTITY_ORDERED)
--                      INTO v_Recent_Sales_Object
--                      FROM RMKTGADM.RMK_WS_AR_BACKLOG_SHIPMENT WSPR
--                     WHERE     1 = 1
--                           AND (   WSPR.PRODUCT_ID = lv_Conflicting_Part_Id
--                                OR WSPR.PRODUCT_ID = lv_Conflicting_Part_WS)
--                           AND UPPER (WSPR.CUSTOMER_NAME) =
--                                  (SELECT UPPER (CM.COMPANY_NAME)
--                                     FROM WCT_COMPANY_MASTER CM,
--                                          WCT_CUSTOMER CUST
--                                    WHERE     1 = 1
--                                          AND CM.COMPANY_ID = CUST.COMPANY_ID
--                                          AND CUST.CUSTOMER_ID = lv_Customer_Id)
--                           AND ROWNUM <= 1
--                  ORDER BY SALES_ORDER_DATE DESC;
--               ELSE
--                    SELECT WCT_SALES_HISTORY_OBJECT (WSPR.BASE_UNIT_PRICE,
--                                                     WSPR.SALES_ORDER_DATE,
--                                                     WSPR.CUSTOMER_NAME,
--                                                     WSPR.QUANTITY_ORDERED)
--                      INTO v_Recent_Sales_Object
--                      FROM RMKTGADM.RMK_WS_AR_BACKLOG_SHIPMENT WSPR
--                     WHERE     1 = 1
--                           AND (   WSPR.PRODUCT_NAME_STRIPPED =
--                                      lv_Product_Name_Stripped
--                                OR WSPR.PRODUCT_NAME_STRIPPED =
--                                      lv_Product_Name_Stripped_WS)
--                           AND UPPER (WSPR.CUSTOMER_NAME) =
--                                  (SELECT UPPER (CM.COMPANY_NAME)
--                                     FROM WCT_COMPANY_MASTER CM,
--                                          WCT_CUSTOMER CUST
--                                    WHERE     1 = 1
--                                          AND CM.COMPANY_ID = CUST.COMPANY_ID
--                                          AND CUST.CUSTOMER_ID = lv_Customer_Id)
--                           AND ROWNUM <= 1
--                  ORDER BY SALES_ORDER_DATE DESC;
--               END IF;
--            EXCEPTION
--               WHEN NO_DATA_FOUND
--               THEN
--                  v_Recent_Sales_Object :=
--                     WCT_SALES_HISTORY_OBJECT (0,
--                                               SYSDATE,
--                                               'NO_DATA',
--                                               0);
--
--                  --LOG EXCEPTION
--                  INSERT INTO WCT_ERROR_LOG
--                       VALUES (UPPER (lv_Requested_Part),
--                               lv_User_Id,
--                               'Data_extract - Step 6.2 - No data found',
--                               SYSDATE);
--               WHEN OTHERS
--               THEN
--                  v_Recent_Sales_Object :=
--                     WCT_SALES_HISTORY_OBJECT (0,
--                                               SYSDATE,
--                                               'NO_DATA',
--                                               0);
--                  --LOG EXCEPTION
--                  v_Error_Message := NULL;
--                  v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--                  INSERT INTO WCT_ERROR_LOG
--                          VALUES (
--                                    UPPER (lv_Requested_Part),
--                                    lv_User_Id,
--                                       'Data_extract - Step 6.2 - '
--                                    || v_Error_Message,
--                                    SYSDATE);
--            END;
--
--            --7.0 Compute Suggested Price using Pricing Engine
--            BEGIN
--               --7.1.1 Fetch recent high price
--               lv_Recent_Price := 0.00;
--
--               IF v_Sales_History_List.COUNT () > 0
--               THEN
--                  lv_Recent_Price := v_Sales_History_List (1).PRICE;
--               ELSIF (v_Recent_Sales_Object.CUSTOMER_NAME <> 'NO_DATA')
--               THEN
--                  lv_Recent_Price := v_Recent_Sales_Object.PRICE;
--               END IF;
--
--               --7.1.2 determine discount based on EOS date
--               BEGIN
--                  IF (lv_Eos_Date <= TRUNC (lv_Eos_Over_Date))
--                  THEN
--                     lv_Base_Price_Discount := lv_Base_Discount_Eos_Over;
--                  ELSIF (lv_Eos_Date <= TRUNC (SYSDATE))
--                  THEN
--                     lv_Base_Price_Discount := lv_Base_Discount_Eos;
--                  END IF;
--               EXCEPTION
--                  WHEN OTHERS
--                  THEN
--                     --LOG EXCEPTION
--                     v_Error_Message := NULL;
--                     v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--                     INSERT INTO WCT_ERROR_LOG
--                             VALUES (
--                                       UPPER (lv_Requested_Part),
--                                       lv_User_Id,
--                                          'Data_extract - Step 7.1.2 - '
--                                       || v_Error_Message,
--                                       SYSDATE);
--               END;
--
--               --7.1.3 Compute base price, suggested price, ext sell price, and updated base price discount
--               --Commented by satbanda on 20-Mar-2017 for validate PID logic <Start>
--              /* PRICING_ENGINE (lv_Broker_Offer_Missing_Flag,
--                               lv_Recent_Price,
--                               NVL (lv_Broker_Offer, 0.00),
--                               lv_Available_Quantity_1,
--                               lv_Requested_Quantity,
--                               lv_Base_Price_Discount,
--                               lv_Glp,
--                               lv_Round_Scale,
--                               lv_Requested_Part,
--                               lv_Product_Name_Stripped,
--                               lv_Product_Name_Stripped_WS,
--                               lv_Customer_Id,
--                               lv_Region_Local,
--                               lv_Conflicting_Part_Count,
--                               lv_Conflicting_Part_Id,
--                               lv_Conflicting_Part_WS,
--                               lv_Base_Price,
--                               lv_Suggested_Price_New,
--                               lv_Ext_Sell_Price_1,
--                               lv_Base_Price_Discount,
--                               lv_Static_Price_Exists);*/
--                --Commented by satbanda on 20-Mar-2017 for validate PID logic <End>
--
--               -- Start of code changes done by Infosys for April 2014 release--  ravchitt
--               -- Code for calculating suggested Price
--               -- If new search
--               IF (    (i_Search_Type = v_Search_Type_New)
--                   AND (lv_Copy_Quote_Customer_Id IS NULL))
--               THEN
--                  lv_Suggested_Price_Old := lv_Suggested_Price_New;
--               -- If edit quote or copy quote with same customer
--               ELSIF (   (i_Search_Type = v_Search_Type_Edit)
--                      OR (lv_Copy_Quote_Customer_Id = lv_Customer_Id))
--               THEN
--                  BEGIN
--                     SELECT SUGGESTED_PRICE, DISCOUNT
--                       INTO lv_Suggested_Price_Old, lv_Base_Price_Discount
--                       FROM WCT_QUOTE_LINE
--                      WHERE     QUOTE_ID = lv_Old_Quote_Id
--                            AND REQUESTED_PART = lv_Requested_Part;
--
--                     IF (lv_Requested_Quantity > lv_Available_Quantity_1)
--                     THEN
--                        lv_Ext_Sell_Price_1 :=
--                           lv_Suggested_Price_Old * lv_Available_Quantity_1;
--                     ELSE
--                        lv_Ext_Sell_Price_1 :=
--                           lv_Suggested_Price_Old * lv_Requested_Quantity;
--                     END IF;
--                  EXCEPTION
--                     WHEN NO_DATA_FOUND
--                     THEN
--                        lv_Suggested_Price_Old := lv_Suggested_Price_New;
--                  END;
--               -- Copy quote with different customer
--               ELSE
--                  lv_Suggested_Price_Old := lv_Suggested_Price_New;
--               -- End Start of code changes done by Infosys for April 2014 release -- ravchitt
--               END IF;
--
--               IF (lv_Lead_Time_Count > 1)
--               THEN
--                  lv_Ext_Sell_Price_2 :=
--                       lv_Suggested_Price_Old
--                     * LEAST (
--                          lv_Available_Quantity_2,
--                          (lv_Requested_Quantity - lv_Available_Quantity_1));
--               END IF;
--
--               --7.1.4 Update Deal Value
--               lv_Deal_Value :=
--                  lv_Deal_Value + lv_Ext_Sell_Price_1 + lv_Ext_Sell_Price_2;
--            EXCEPTION
--               WHEN OTHERS
--               THEN
--                  --LOG EXCEPTION
--                  v_Error_Message := NULL;
--                  v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--                  INSERT INTO WCT_ERROR_LOG
--                          VALUES (
--                                    UPPER (lv_Requested_Part),
--                                    lv_User_Id,
--                                       'Data_extract - Step 7.0 - '
--                                    || v_Error_Message,
--                                    SYSDATE);
--            END;
--
--            --8.0 Get N value based on EOS date
--            CASE
--               WHEN lv_Eos_Date <= TRUNC (lv_Eos_Over_Date)
--               THEN
--                  lv_N_Value := 'N - 2';
--               WHEN lv_Eos_Date <= TRUNC (SYSDATE)
--               THEN
--                  lv_N_Value := 'N - 1';
--               ELSE
--                  lv_N_Value := 'N';
--            END CASE;
--
--            --Code moved to PRICING ENGINE
--
--            --9.0 Generate Unique Quote ID and Save each line in a Collection
--            BEGIN
--               v_Search_Data_Object :=
--                  WCT_SEARCH_DATA_OBJECT (lv_Line_No,
--                                          lv_Requested_Part,
--                                          lv_Manufacture_Part,
--                                          lv_Refurbished_Part,
--                                          lv_Wholesale_Part,
--                                          lv_Encryption_Status,
--                                          --lv_Available_Quantity,
--                                          lv_Available_Quantity_1,
--                                          lv_Requested_Quantity,
--                                          lv_Broker_Offer,
--                                          lv_Glp,
--                                          lv_Base_Price,
--                                          lv_Suggested_Price_Old,
--                                          lv_Suggested_Price_New,
--                                          --lv_Ext_Sell_Price,
--                                          lv_Ext_Sell_Price_1,
--                                          lv_Base_Price_Discount,
--                                          --lv_Lead_Time,
--                                          lv_Lead_Time_1,
--                                          lv_Eos_Date,
--                                          lv_Static_Price_Exists,
--                                          --lv_Inventory_Detail_Note,
--                                          lv_Inventory_Detail_Notes_1,
--                                          lv_Row_Id,
--                                          lv_Recent_Price,
--                                          v_Recent_Sales_Object,
--                                          v_Sales_History_List,
--                                          v_Recent_Quotes_List,
--                                          v_Inventory_Detail_Local,
--                                          v_Inventory_Detail_Foreign,
--                                          lv_N_Value,
--                                          lv_Quantity_On_Hand_1, -- added for June 2014 release - ruchhabr
--                                          lv_Quantity_In_Transit_1); -- added for June 2014 release - ruchhabr
--               v_Out_Search_Data_List.EXTEND;
--               v_Out_Search_Data_List (lv_index) := v_Search_Data_Object;
--               lv_index := lv_index + 1;
--
--
--               IF (lv_Lead_Time_Count > 1)
--               THEN
--                  lv_Row_Id := lv_Row_Id + 1;
--                  v_Search_Data_Object :=
--                     WCT_SEARCH_DATA_OBJECT (lv_Line_No,
--                                             lv_Requested_Part,
--                                             lv_Manufacture_Part,
--                                             lv_Refurbished_Part,
--                                             lv_Wholesale_Part,
--                                             lv_Encryption_Status,
--                                             --lv_Available_Quantity,
--                                             lv_Available_Quantity_2,
--                                             lv_Requested_Quantity,
--                                             lv_Broker_Offer,
--                                             lv_Glp,
--                                             lv_Base_Price,
--                                             lv_Suggested_Price_Old,
--                                             lv_Suggested_Price_New,
--                                             --lv_Ext_Sell_Price,
--                                             lv_Ext_Sell_Price_2,
--                                             lv_Base_Price_Discount,
--                                             lv_Lead_Time_2,
--                                             lv_Eos_Date,
--                                             lv_Static_Price_Exists,
--                                             --lv_Inventory_Detail_Note,
--                                             lv_Inventory_Detail_Notes_2,
--                                             lv_Row_Id,
--                                             lv_Recent_Price,
--                                             v_Recent_Sales_Object,
--                                             v_Sales_History_List,
--                                             v_Recent_Quotes_List,
--                                             v_Inventory_Detail_Local,
--                                             v_Inventory_Detail_Foreign,
--                                             lv_N_Value,
--                                             lv_Quantity_On_Hand_2, -- added for June 2014 release - ruchhabr
--                                             lv_Quantity_In_Transit_2); -- added for June 2014 release - ruchhabr
--                  v_Out_Search_Data_List.EXTEND;
--                  v_Out_Search_Data_List (lv_index) := v_Search_Data_Object;
--                  lv_index := lv_index + 1;
--               END IF;
--            EXCEPTION
--               WHEN OTHERS
--               THEN
--                  --LOG EXCEPTION
--                  v_Error_Message := NULL;
--                  v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--                  INSERT INTO WCT_ERROR_LOG
--                          VALUES (
--                                    UPPER (lv_Requested_Part),
--                                    lv_User_Id,
--                                       'Data_extract - Step 9.0 - '
--                                    || v_Error_Message,
--                                    SYSDATE);
--            END;
--         END IF;
--
--         --Reset system discount to defaultr
--         lv_Base_Price_Discount := lv_Base_Discount_Default;
--      END LOOP;
--
--      --insert into nar(seq) values(100);
--
--      -- If valid rows present, only then update the header and line table
--      IF (v_Out_Search_Data_List.COUNT () > 0)
--      THEN
--         --insert into nar(seq) values(200);
--         --10.0 Create Header entry for the quote
--         BEGIN
--            IF (i_Search_Type = v_Search_Type_New)
--            THEN
--               --insert into nar(seq) values(300);
--               lv_Quote_Id := GENERATE_QUOTE_ID (v_Quote_Id_Type_Dummy);
--
--               --insert into nar(seq) values(400);
--               BEGIN
--                  INSERT INTO WCT_QUOTE_HEADER (QUOTE_ID,
--                                                CUSTOMER_ID,
--                                                CREATED_DATE,
--                                                CREATED_BY,
--                                                LAST_UPDATED_DATE,
--                                                LAST_UPDATED_BY,
--                                                DEAL_VALUE,
--                                                STATUS)
--                       VALUES (lv_Quote_Id,
--                               lv_Customer_Id,
--                               lv_Date,
--                               lv_User_Id,
--                               lv_Date,
--                               lv_User_Id,
--                               lv_Deal_Value,
--                               v_Status_New);
--               EXCEPTION
--                  WHEN OTHERS
--                  THEN
--                     l_sqerrm := SUBSTR (SQLERRM, 1, 500);
--               --insert into nar(seq,issue) values(500,'lv_Quote_Id=> '||lv_Quote_Id||' <> '||l_sqerrm);
--               END;
--            --insert into nar(seq,quote_id, issue) values(2,'Data Extract=> '|| lv_Quote_Id,lv_Customer_Id||' lv_Customer_Id$lv_Date '||lv_Date ); commit;
--            ELSE
--               -- if search was edit quote
--               lv_Quote_Id := i_Quote_Id;
--
--               -- Add new entry in the audit header table
--               DECLARE
--                  lv_audit_header_quote_id        VARCHAR2 (10 BYTE);
--                  lv_audit_header_customer_id     NUMBER;
--                  lv_audit_header_created_date    DATE;
--                  lv_audit_header_created_by      VARCHAR2 (12 BYTE);
--                  lv_aud_head_last_updated_date   DATE;
--                  lv_aud_head_last_updated_by     VARCHAR2 (12 BYTE);
--                  lv_audit_header_deal_value      NUMBER (15, 2);
--                  lv_audit_header_status          VARCHAR2 (10 BYTE);
--               BEGIN
--                  SELECT QUOTE_ID,
--                         CUSTOMER_ID,
--                         CREATED_DATE,
--                         CREATED_BY,
--                         LAST_UPDATED_DATE,
--                         LAST_UPDATED_BY,
--                         DEAL_VALUE,
--                         STATUS
--                    INTO lv_audit_header_quote_id,
--                         lv_audit_header_customer_id,
--                         lv_audit_header_created_date,
--                         lv_audit_header_created_by,
--                         lv_aud_head_last_updated_date,
--                         lv_aud_head_last_updated_by,
--                         lv_audit_header_deal_value,
--                         lv_audit_header_status
--                    FROM WCT_QUOTE_HEADER
--                   WHERE QUOTE_ID = lv_Quote_Id;
--
--                  INSERT INTO WCT_QUOTE_HEADER_AUDIT (AUDIT_HEADER_ID,
--                                                      QUOTE_ID,
--                                                      CUSTOMER_ID,
--                                                      CREATED_DATE,
--                                                      CREATED_BY,
--                                                      LAST_UPDATED_DATE,
--                                                      LAST_UPDATED_BY,
--                                                      DEAL_VALUE,
--                                                      STATUS)
--                       VALUES (WCT_AUDIT_HEADER_ID.NEXTVAL,
--                               lv_audit_header_quote_id,
--                               lv_audit_header_customer_id,
--                               lv_audit_header_created_date,
--                               lv_audit_header_created_by,
--                               lv_aud_head_last_updated_date,
--                               lv_aud_head_last_updated_by,
--                               lv_audit_header_deal_value,
--                               lv_audit_header_status);
--               EXCEPTION
--                  WHEN OTHERS
--                  THEN
--                     --LOG EXCEPTION
--                     v_Error_Message := NULL;
--                     v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--                     INSERT INTO WCT_ERROR_LOG
--                          VALUES ('INSERTING INTO AUDIT HEADER-1',
--                                  lv_User_Id,
--                                  'EDIT_QUOTE - ' || v_Error_Message,
--                                  SYSDATE);
--               END;
--
--               --insert into nar(seq,quote_id, issue) values(10,'Data Extract=> '||lv_Quote_Id||' quotes '||lv_Old_Quote_Id,' lv_User_Id '||lv_User_Id ); commit;
--               -- Update quote header table
--               UPDATE WCT_QUOTE_HEADER
--                  SET LAST_UPDATED_DATE = SYSDATE,
--                      LAST_UPDATED_BY = lv_User_Id,
--                      DEAL_VALUE = lv_Deal_Value
--                WHERE QUOTE_ID = lv_Quote_Id;
--            --insert into nar(seq,quote_id, issue) values(11,'Data Extract=> '||lv_Quote_Id||' quotes '||lv_Old_Quote_Id,' lv_User_Id '||lv_User_Id ); commit;
--
--
--            END IF;
--         EXCEPTION
--            WHEN OTHERS
--            THEN
--               --LOG EXCEPTION
--               v_Error_Message := NULL;
--               v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--               INSERT INTO WCT_ERROR_LOG
--                    VALUES (UPPER (lv_Requested_Part),
--                            lv_User_Id,
--                            'Data_extract - Step 10.0 - ' || v_Error_Message,
--                            SYSDATE);
--         END;
--
--         --11.0 Bulk Insert/Update Collection to Line
--
--         BEGIN
--            IF (i_Search_Type = v_Search_Type_New)
--            THEN
--               FOR idx IN 1 .. v_Out_Search_Data_List.COUNT ()
--               LOOP
--                  -- Start of code changes done by Infosys for April 2014 release -- ruchhabr
--                  lv_Row_Id := v_Out_Search_Data_List (idx).ROW_ID;
--
--                  IF (lv_Row_Id = 1)
--                  THEN
--                     lv_Lead_Time_Id := WCT_LEAD_TIME_ID_SEQ.NEXTVAL;
--                  END IF;
--
--                  INSERT INTO WCT_LEAD_TIME (LEAD_TIME_ID,
--                                             REQUESTED_PART,
--                                             REQUESTED_QUANTITY,
--                                             AVAILABLE_QUANTITY,
--                                             LEAD_TIME,
--                                             ROW_ID,
--                                             INVENTORY_DETAIL_NOTES,
--                                             CREATED_DATE,
--                                             CREATED_BY,
--                                             LAST_UPDATED_DATE,
--                                             LAST_UPDATED_BY,
--                                             QUANTITY_ON_HAND, -- added for June 2014 release - ruchhabr
--                                             QUANTITY_IN_TRANSIT) -- added for June 2014 release - ruchhabr
--                          VALUES (
--                                    lv_Lead_Time_Id,
--                                    v_Out_Search_Data_List (idx).REQUESTED_PART,
--                                    v_Out_Search_Data_List (idx).REQUESTED_QUANTITY,
--                                    v_Out_Search_Data_List (idx).AVAILABLE_QUANTITY,
--                                    TO_CHAR (
--                                       v_Out_Search_Data_List (idx).LEAD_TIME),
--                                    lv_Row_Id,
--                                    v_Out_Search_Data_List (idx).INVENTORY_DETAIL_NOTES,
--                                    lv_Date,
--                                    lv_User_Id,
--                                    lv_Date,
--                                    lv_User_Id,
--                                    v_Out_Search_Data_List (idx).QUANTITY_ON_HAND, -- added for June 2014 release - ruchhabr
--                                    v_Out_Search_Data_List (idx).QUANTITY_IN_TRANSIT); -- added for June 2014 release - ruchhabr
--
--                  IF (lv_Row_Id = 1)
--                  THEN
--                     lv_Quote_Line_Id := WCT_QUOTE_LINE_ID.NEXTVAL;
--
--                     INSERT INTO WCT_QUOTE_LINE (LINE_ID,
--                                                 QUOTE_ID,
--                                                 LINE_NO,
--                                                 REQUESTED_PART,
--                                                 WHOLESALE_PART,
--                                                 REQUESTED_QUANTITY,
--                                                 AVAILABLE_QUANTITY,
--                                                 BROKER_OFFER,
--                                                 GLP,
--                                                 SUGGESTED_PRICE,
--                                                 EXT_SELL_PRICE,
--                                                 LEAD_TIME,
--                                                 ENCRYPTION_STATUS,
--                                                 INVENTORY_DETAIL_NOTES,
--                                                 CREATED_DATE,
--                                                 CREATED_BY,
--                                                 LAST_UPDATED_DATE,
--                                                 LAST_UPDATED_BY,
--                                                 DISCOUNT,
--                                                 EOS_DATE)
--                             VALUES (
--                                       lv_Quote_Line_Id,
--                                       lv_Quote_Id,
--                                       v_Out_Search_Data_List (idx).LINE_NO,
--                                       v_Out_Search_Data_List (idx).REQUESTED_PART,
--                                       v_Out_Search_Data_List (idx).WHOLESALE_PART,
--                                       v_Out_Search_Data_List (idx).REQUESTED_QUANTITY,
--                                       v_Out_Search_Data_List (idx).AVAILABLE_QUANTITY,
--                                       v_Out_Search_Data_List (idx).BROKER_OFFER,
--                                       v_Out_Search_Data_List (idx).GLP,
--                                       v_Out_Search_Data_List (idx).SUGGESTED_PRICE_OLD,
--                                       v_Out_Search_Data_List (idx).EXT_SELL_PRICE,
--                                       lv_Lead_Time_Id, -- code changes done by Infosys for April 2014 release -- ruchhabr
--                                       v_Out_Search_Data_List (idx).ENCRYPTION_STATUS,
--                                       v_Out_Search_Data_List (idx).INVENTORY_DETAIL_NOTES,
--                                       lv_Date,
--                                       lv_User_Id,
--                                       lv_Date,
--                                       lv_User_Id,
--                                       v_Out_Search_Data_List (idx).SYSTEM_DISCOUNT,
--                                       v_Out_Search_Data_List (idx).EOS_DATE);
--                  END IF;
--               -- End of code changes done by Infosys for April 2014 release -- ruchhabr
--               END LOOP;
--            ELSE
--               -- Search type is Edit Quote
--
--               -- Insert new records in WCT_QUOTE_LINE_TMP table
--               FOR idx IN 1 .. v_Out_Search_Data_List.COUNT ()
--               LOOP
--                  INSERT INTO WCT_QUOTE_LINE_TMP (QUOTE_ID,
--                                                  LINE_NO,
--                                                  REQUESTED_PART,
--                                                  WHOLESALE_PART,
--                                                  REQUESTED_QUANTITY,
--                                                  AVAILABLE_QUANTITY,
--                                                  BROKER_OFFER,
--                                                  GLP,
--                                                  SUGGESTED_PRICE,
--                                                  EXT_SELL_PRICE,
--                                                  LEAD_TIME,
--                                                  ENCRYPTION_STATUS,
--                                                  INVENTORY_DETAIL_NOTES,
--                                                  CREATED_DATE,
--                                                  CREATED_BY,
--                                                  LAST_UPDATED_DATE,
--                                                  LAST_UPDATED_BY,
--                                                  DISCOUNT,
--                                                  EOS_DATE)
--                          VALUES (
--                                    lv_Quote_Id,
--                                    v_Out_Search_Data_List (idx).LINE_NO,
--                                    v_Out_Search_Data_List (idx).REQUESTED_PART,
--                                    v_Out_Search_Data_List (idx).WHOLESALE_PART,
--                                    v_Out_Search_Data_List (idx).REQUESTED_QUANTITY,
--                                    v_Out_Search_Data_List (idx).AVAILABLE_QUANTITY,
--                                    v_Out_Search_Data_List (idx).BROKER_OFFER,
--                                    v_Out_Search_Data_List (idx).GLP,
--                                    v_Out_Search_Data_List (idx).SUGGESTED_PRICE_OLD,
--                                    v_Out_Search_Data_List (idx).EXT_SELL_PRICE,
--                                    v_Out_Search_Data_List (idx).LEAD_TIME,
--                                    v_Out_Search_Data_List (idx).ENCRYPTION_STATUS,
--                                    v_Out_Search_Data_List (idx).INVENTORY_DETAIL_NOTES,
--                                    lv_Date,
--                                    lv_User_Id,
--                                    lv_Date,
--                                    lv_User_Id,
--                                    v_Out_Search_Data_List (idx).SYSTEM_DISCOUNT,
--                                    v_Out_Search_Data_List (idx).EOS_DATE);
--               END LOOP;
--
--               -- Fetch records from WCT_QUOTE_LINE_TMP to be updated in WCT_QUOTE_LINE
--               SELECT EL.LINE_ID,
--                      EL.QUOTE_ID,
--                      EL.LINE_NO,
--                      EL.REQUESTED_PART,
--                      EL.WHOLESALE_PART,
--                      EL.REFURBISHED_PART,
--                      EL.MANUFACTURING_PART,
--                      EL.REQUESTED_QUANTITY,
--                      EL.AVAILABLE_QUANTITY,
--                      EL.BROKER_OFFER,
--                      EL.GLP,
--                      EL.SUGGESTED_PRICE,
--                      EL.EXT_SELL_PRICE,
--                      EL.LEAD_TIME,
--                      EL.CREATED_DATE,
--                      EL.CREATED_BY,
--                      EL.LAST_UPDATED_DATE,
--                      EL.LAST_UPDATED_BY,
--                      EL.ENCRYPTION_STATUS,
--                      EL.INVENTORY_DETAIL_NOTES,
--                      EL.DISCOUNT,
--                      EL.COMMENTS_L1,
--                      EL.COMMENTS_L2,
--                      EL.EOS_DATE,
--                      EL.APPROVAL_LEVEL,
--                      EL.APPROVAL_STATUS_L1,
--                      EL.APPROVAL_STATUS_L2,
--                      EL.PROMO_FLAG --US151907
--                 BULK COLLECT INTO v_Quote_Line_Update_List
--                 FROM WCT_QUOTE_LINE_TMP EL, WCT_QUOTE_LINE QL
--                WHERE     EL.QUOTE_ID = QL.QUOTE_ID
--                      AND EL.REQUESTED_PART = QL.REQUESTED_PART;
--
--               -- changes made by ruchhabr 02-MAY-2014
--               /*-- Update existing records in WCT_QUOTE_LINE
--               FOR idx IN 1 .. v_Quote_Line_Update_List.COUNT ()
--               LOOP
--                  --changes made by ruchhabr 02-MAY-2014
--                  UPDATE WCT_QUOTE_LINE
--                     SET REQUESTED_QUANTITY =
--                            v_Quote_Line_Update_List (idx).REQUESTED_QUANTITY,
--                         AVAILABLE_QUANTITY =
--                            v_Quote_Line_Update_List (idx).AVAILABLE_QUANTITY,
--                         BROKER_OFFER =
--                            v_Quote_Line_Update_List (idx).BROKER_OFFER,
--                         GLP = v_Quote_Line_Update_List (idx).GLP,
--                         SUGGESTED_PRICE =
--                            v_Quote_Line_Update_List (idx).SUGGESTED_PRICE,
--                         EXT_SELL_PRICE =
--                            v_Quote_Line_Update_List (idx).EXT_SELL_PRICE,
--                         LEAD_TIME = lv_Lead_Time_Id, --changes made by cbharath--30-04-2014
--                         LAST_UPDATED_DATE =
--                            v_Quote_Line_Update_List (idx).LAST_UPDATED_DATE,
--                         LAST_UPDATED_BY =
--                            v_Quote_Line_Update_List (idx).LAST_UPDATED_BY
--                   WHERE     QUOTE_ID = lv_Quote_Id
--                         AND REQUESTED_PART =
--                                v_Quote_Line_Update_List (idx).REQUESTED_PART;
--               END LOOP;*/
--
--               -- add/update rows as per the new quote
--               FOR idx IN 1 .. v_Out_Search_Data_List.COUNT ()
--               LOOP
--                  lv_Row_Id := v_Out_Search_Data_List (idx).ROW_ID;
--
--                  SELECT COUNT (*)
--                    INTO lv_Row_Count
--                    FROM WCT_QUOTE_LINE
--                   WHERE     QUOTE_ID = lv_Quote_Id
--                         AND REQUESTED_PART =
--                                v_Out_Search_Data_List (idx).REQUESTED_PART;
--
--                  -- if existing row
--                  IF (lv_Row_Count > 0)
--                  THEN
--                     -- fetch existing lead time id from wct_quote_line table
--                     SELECT LEAD_TIME
--                       INTO lv_Lead_Time_Id
--                       FROM WCT_QUOTE_LINE
--                      WHERE     QUOTE_ID = lv_Quote_Id
--                            AND REQUESTED_PART =
--                                   v_Out_Search_Data_List (idx).REQUESTED_PART;
--
--                     -- get existing row count for lead time
--                     SELECT COUNT (*)
--                       INTO lv_Lead_Time_Row_Count
--                       FROM wct_lead_time
--                      WHERE lead_time_id = lv_Lead_Time_Id;
--
--                     IF (lv_Row_Id = 1)
--                     THEN
--                        lv_Available_Quantity_1 :=
--                           v_Out_Search_Data_List (idx).AVAILABLE_QUANTITY;
--
--                        -- check if current scenario has 2 rows
--                        IF (    (idx < v_Out_Search_Data_List.COUNT)
--                            AND (v_Out_Search_Data_List (idx + 1).ROW_ID = 2)
--                            AND (v_Out_Search_Data_List (idx).REQUESTED_PART =
--                                    v_Out_Search_Data_List (idx + 1).REQUESTED_PART))
--                        THEN
--                           lv_Available_Quantity_2 :=
--                              v_Out_Search_Data_List (idx + 1).AVAILABLE_QUANTITY;
--                        ELSE
--                           lv_Available_Quantity_2 := 0;
--                        END IF;
--
--                        -- update wct_quote_line
--                        UPDATE WCT_QUOTE_LINE
--                           SET REQUESTED_QUANTITY =
--                                  v_Out_Search_Data_List (idx).REQUESTED_QUANTITY,
--                               AVAILABLE_QUANTITY =
--                                    lv_Available_Quantity_1
--                                  + lv_Available_Quantity_2,
--                               BROKER_OFFER =
--                                  v_Out_Search_Data_List (idx).BROKER_OFFER,
--                               GLP = v_Out_Search_Data_List (idx).GLP,
--                               SUGGESTED_PRICE =
--                                  v_Out_Search_Data_List (idx).SUGGESTED_PRICE_OLD,
--                               EXT_SELL_PRICE =
--                                  v_Out_Search_Data_List (idx).EXT_SELL_PRICE,
--                               LAST_UPDATED_DATE = lv_Date,
--                               LAST_UPDATED_BY = lv_User_Id
--                         WHERE     QUOTE_ID = lv_Quote_Id
--                               AND REQUESTED_PART =
--                                      v_Out_Search_Data_List (idx).REQUESTED_PART;
--
--                        -- update first row
--                        UPDATE WCT_LEAD_TIME
--                           SET LEAD_TIME =
--                                  v_Out_Search_Data_List (idx).LEAD_TIME,
--                               REQUESTED_QUANTITY =
--                                  v_Out_Search_Data_List (idx).REQUESTED_QUANTITY,
--                               AVAILABLE_QUANTITY =
--                                  v_Out_Search_Data_List (idx).AVAILABLE_QUANTITY,
--                               QUANTITY_ON_HAND = -- added for June 2014 release - ruchhabr
--                                  v_Out_Search_Data_List (idx).QUANTITY_ON_HAND,
--                               QUANTITY_IN_TRANSIT = -- added for June 2014 release - ruchhabr
--                                  v_Out_Search_Data_List (idx).QUANTITY_IN_TRANSIT
--                         WHERE LEAD_TIME_ID = lv_Lead_Time_Id AND ROW_ID = 1;
--
--
--                        -- check if previously 2 rows and currently also 2 rows
--                        IF (    (idx < v_Out_Search_Data_List.COUNT)
--                            AND (v_Out_Search_Data_List (idx).REQUESTED_PART =
--                                    v_Out_Search_Data_List (idx + 1).REQUESTED_PART))
--                        THEN
--                           IF (lv_Lead_Time_Row_Count > 1)
--                           THEN
--                              -- update second row
--                              UPDATE WCT_LEAD_TIME
--                                 SET LEAD_TIME =
--                                        v_Out_Search_Data_List (idx + 1).LEAD_TIME,
--                                     REQUESTED_QUANTITY =
--                                        v_Out_Search_Data_List (idx + 1).REQUESTED_QUANTITY,
--                                     AVAILABLE_QUANTITY =
--                                        lv_Available_Quantity_2,
--                                     QUANTITY_ON_HAND = -- added for June 2014 release - ruchhabr
--                                        v_Out_Search_Data_List (idx + 1).QUANTITY_ON_HAND,
--                                     QUANTITY_IN_TRANSIT = -- added for June 2014 release - ruchhabr
--                                        v_Out_Search_Data_List (idx + 1).QUANTITY_IN_TRANSIT
--                               WHERE     LEAD_TIME_ID = lv_Lead_Time_Id
--                                     AND ROW_ID = 2;
--                           ELSE
--                              -- add second row
--                              INSERT
--                                INTO WCT_LEAD_TIME (LEAD_TIME_ID,
--                                                    REQUESTED_PART,
--                                                    REQUESTED_QUANTITY,
--                                                    AVAILABLE_QUANTITY,
--                                                    LEAD_TIME,
--                                                    ROW_ID,
--                                                    INVENTORY_DETAIL_NOTES,
--                                                    CREATED_DATE,
--                                                    CREATED_BY,
--                                                    LAST_UPDATED_DATE,
--                                                    LAST_UPDATED_BY,
--                                                    QUANTITY_ON_HAND, -- added for June 2014 release - ruchhabr
--                                                    QUANTITY_IN_TRANSIT) -- added for June 2014 release - ruchhabr
--                                 VALUES (
--                                           lv_Lead_Time_Id,
--                                           v_Out_Search_Data_List (idx + 1).REQUESTED_PART,
--                                           v_Out_Search_Data_List (idx + 1).REQUESTED_QUANTITY,
--                                           v_Out_Search_Data_List (idx + 1).AVAILABLE_QUANTITY,
--                                           TO_CHAR (
--                                              v_Out_Search_Data_List (
--                                                 idx + 1).LEAD_TIME),
--                                           2,
--                                           v_Out_Search_Data_List (idx + 1).INVENTORY_DETAIL_NOTES,
--                                           lv_Date,
--                                           lv_User_Id,
--                                           lv_Date,
--                                           lv_User_Id,
--                                           v_Out_Search_Data_List (idx + 1).QUANTITY_ON_HAND, -- added for June 2014 release - ruchhabr
--                                           v_Out_Search_Data_List (idx + 1).QUANTITY_IN_TRANSIT); -- added for June 2014 release - ruchhabr
--                           END IF;
--                        -- check if previously 2 rows and currently only 1 row
--                        ELSIF (lv_Lead_Time_Row_Count > 1)
--                        THEN
--                           -- delete the second row
--                           DELETE FROM WCT_LEAD_TIME
--                                 WHERE     LEAD_TIME_ID = lv_Lead_Time_Id
--                                       AND ROW_ID = 2;
--                        END IF;
--                     END IF;
--                  -- add new row
--                  ELSE
--                     IF (lv_Row_Id = 1)
--                     THEN
--                        lv_Lead_Time_Id := WCT_LEAD_TIME_ID_SEQ.NEXTVAL;
--
--                        lv_Available_Quantity_1 :=
--                           v_Out_Search_Data_List (idx).AVAILABLE_QUANTITY;
--                        lv_Available_Quantity_2 := 0;
--
--
--                        INSERT INTO WCT_LEAD_TIME (LEAD_TIME_ID,
--                                                   REQUESTED_PART,
--                                                   REQUESTED_QUANTITY,
--                                                   AVAILABLE_QUANTITY,
--                                                   LEAD_TIME,
--                                                   ROW_ID,
--                                                   INVENTORY_DETAIL_NOTES,
--                                                   CREATED_DATE,
--                                                   CREATED_BY,
--                                                   LAST_UPDATED_DATE,
--                                                   LAST_UPDATED_BY,
--                                                   QUANTITY_ON_HAND, -- added for June 2014 release - ruchhabr
--                                                   QUANTITY_IN_TRANSIT) -- added for June 2014 release - ruchhabr
--                                VALUES (
--                                          lv_Lead_Time_Id,
--                                          v_Out_Search_Data_List (idx).REQUESTED_PART,
--                                          v_Out_Search_Data_List (idx).REQUESTED_QUANTITY,
--                                          v_Out_Search_Data_List (idx).AVAILABLE_QUANTITY,
--                                          TO_CHAR (
--                                             v_Out_Search_Data_List (idx).LEAD_TIME),
--                                          1,
--                                          v_Out_Search_Data_List (idx).INVENTORY_DETAIL_NOTES,
--                                          lv_Date,
--                                          lv_User_Id,
--                                          lv_Date,
--                                          lv_User_Id,
--                                          v_Out_Search_Data_List (idx).QUANTITY_ON_HAND, -- added for June 2014 release - ruchhabr
--                                          v_Out_Search_Data_List (idx).QUANTITY_IN_TRANSIT); -- added for June 2014 release - ruchhabr
--
--
--                        IF (    (idx < v_Out_Search_Data_List.COUNT)
--                            AND (v_Out_Search_Data_List (idx + 1).ROW_ID = 2)
--                            AND (v_Out_Search_Data_List (idx).REQUESTED_PART =
--                                    v_Out_Search_Data_List (idx + 1).REQUESTED_PART))
--                        THEN
--                           INSERT INTO WCT_LEAD_TIME (LEAD_TIME_ID,
--                                                      REQUESTED_PART,
--                                                      REQUESTED_QUANTITY,
--                                                      AVAILABLE_QUANTITY,
--                                                      LEAD_TIME,
--                                                      ROW_ID,
--                                                      INVENTORY_DETAIL_NOTES,
--                                                      CREATED_DATE,
--                                                      CREATED_BY,
--                                                      LAST_UPDATED_DATE,
--                                                      LAST_UPDATED_BY,
--                                                      QUANTITY_ON_HAND, -- added for June 2014 release - ruchhabr
--                                                      QUANTITY_IN_TRANSIT) -- added for June 2014 release - ruchhabr
--                                   VALUES (
--                                             lv_Lead_Time_Id,
--                                             v_Out_Search_Data_List (idx + 1).REQUESTED_PART,
--                                             v_Out_Search_Data_List (idx + 1).REQUESTED_QUANTITY,
--                                             v_Out_Search_Data_List (idx + 1).AVAILABLE_QUANTITY,
--                                             TO_CHAR (
--                                                v_Out_Search_Data_List (
--                                                   idx + 1).LEAD_TIME),
--                                             2,
--                                             v_Out_Search_Data_List (idx + 1).INVENTORY_DETAIL_NOTES,
--                                             lv_Date,
--                                             lv_User_Id,
--                                             lv_Date,
--                                             lv_User_Id,
--                                             v_Out_Search_Data_List (idx + 1).QUANTITY_ON_HAND, -- added for June 2014 release - ruchhabr
--                                             v_Out_Search_Data_List (idx + 1).QUANTITY_IN_TRANSIT); -- added for June 2014 release - ruchhabr
--
--                           lv_Available_Quantity_2 :=
--                              v_Out_Search_Data_List (idx + 1).AVAILABLE_QUANTITY;
--                        END IF;
--
--                        lv_Quote_Line_Id := WCT_QUOTE_LINE_ID.NEXTVAL;
--
--                        INSERT INTO WCT_QUOTE_LINE (LINE_ID,
--                                                    QUOTE_ID,
--                                                    LINE_NO,
--                                                    REQUESTED_PART,
--                                                    WHOLESALE_PART,
--                                                    REQUESTED_QUANTITY,
--                                                    AVAILABLE_QUANTITY,
--                                                    BROKER_OFFER,
--                                                    GLP,
--                                                    SUGGESTED_PRICE,
--                                                    EXT_SELL_PRICE,
--                                                    LEAD_TIME,
--                                                    ENCRYPTION_STATUS,
--                                                    INVENTORY_DETAIL_NOTES,
--                                                    CREATED_DATE,
--                                                    CREATED_BY,
--                                                    LAST_UPDATED_DATE,
--                                                    LAST_UPDATED_BY,
--                                                    DISCOUNT,
--                                                    EOS_DATE)
--                                VALUES (
--                                          lv_Quote_Line_Id,
--                                          lv_Quote_Id,
--                                          v_Out_Search_Data_List (idx).LINE_NO,
--                                          v_Out_Search_Data_List (idx).REQUESTED_PART,
--                                          v_Out_Search_Data_List (idx).WHOLESALE_PART,
--                                          v_Out_Search_Data_List (idx).REQUESTED_QUANTITY,
--                                            lv_Available_Quantity_1
--                                          + lv_Available_Quantity_2,
--                                          v_Out_Search_Data_List (idx).BROKER_OFFER,
--                                          v_Out_Search_Data_List (idx).GLP,
--                                          v_Out_Search_Data_List (idx).SUGGESTED_PRICE_OLD,
--                                          v_Out_Search_Data_List (idx).EXT_SELL_PRICE,
--                                          lv_Lead_Time_Id,
--                                          v_Out_Search_Data_List (idx).ENCRYPTION_STATUS,
--                                          v_Out_Search_Data_List (idx).INVENTORY_DETAIL_NOTES,
--                                          lv_Date,
--                                          lv_User_Id,
--                                          lv_Date,
--                                          lv_User_Id,
--                                          v_Out_Search_Data_List (idx).SYSTEM_DISCOUNT,
--                                          v_Out_Search_Data_List (idx).EOS_DATE);
--                     END IF;
--                  END IF;
--               END LOOP;
--
--               /*-- Fetch records from WCT_QUOTE_LINE_TMP to be inserted into WCT_QUOTE_LINE
--               SELECT LINE_ID,
--                      QUOTE_ID,
--                      LINE_NO,
--                      REQUESTED_PART,
--                      WHOLESALE_PART,
--                      REFURBISHED_PART,
--                      MANUFACTURING_PART,
--                      REQUESTED_QUANTITY,
--                      AVAILABLE_QUANTITY,
--                      BROKER_OFFER,
--                      GLP,
--                      SUGGESTED_PRICE,
--                      EXT_SELL_PRICE,
--                      LEAD_TIME,
--                      CREATED_DATE,
--                      CREATED_BY,
--                      LAST_UPDATED_DATE,
--                      LAST_UPDATED_BY,
--                      ENCRYPTION_STATUS,
--                      INVENTORY_DETAIL_NOTES,
--                      DISCOUNT,
--                      COMMENTS_L1,
--                      COMMENTS_L2,
--                      EOS_DATE,
--                      APPROVAL_LEVEL,
--                      APPROVAL_STATUS_L1,
--                      APPROVAL_STATUS_L2
--                 BULK COLLECT INTO v_Quote_Line_Insert_List
--                 FROM WCT_QUOTE_LINE_TMP
--                WHERE REQUESTED_PART NOT IN
--                         (SELECT REQUESTED_PART
--                            FROM WCT_QUOTE_LINE QL
--                           WHERE QL.QUOTE_ID = lv_Quote_Id);
--
--               -- Insert new records into WCT_QUOTE_LINE
--               FOR idx IN 1 .. v_Quote_Line_Insert_List.COUNT ()
--               LOOP
--                  lv_Quote_Line_Id := WCT_QUOTE_LINE_ID.NEXTVAL;
--
--                  INSERT INTO WCT_QUOTE_LINE (LINE_ID,
--                                              QUOTE_ID,
--                                              LINE_NO,
--                                              REQUESTED_PART,
--                                              WHOLESALE_PART,
--                                              REQUESTED_QUANTITY,
--                                              AVAILABLE_QUANTITY,
--                                              BROKER_OFFER,
--                                              GLP,
--                                              SUGGESTED_PRICE,
--                                              EXT_SELL_PRICE,
--                                              LEAD_TIME,
--                                              ENCRYPTION_STATUS,
--                                              CREATED_DATE,
--                                              CREATED_BY,
--                                              LAST_UPDATED_DATE,
--                                              LAST_UPDATED_BY,
--                                              DISCOUNT,
--                                              EOS_DATE)
--                       VALUES (
--                                 lv_Quote_Line_Id,
--                                 lv_Quote_Id,
--                                 v_Quote_Line_Insert_List (idx).LINE_NO,
--                                 v_Quote_Line_Insert_List (idx).REQUESTED_PART,
--                                 v_Quote_Line_Insert_List (idx).WHOLESALE_PART,
--                                 v_Quote_Line_Insert_List (idx).REQUESTED_QUANTITY,
--                                 v_Quote_Line_Insert_List (idx).AVAILABLE_QUANTITY,
--                                 v_Quote_Line_Insert_List (idx).BROKER_OFFER,
--                                 v_Quote_Line_Insert_List (idx).GLP,
--                                 v_Quote_Line_Insert_List (idx).SUGGESTED_PRICE,
--                                 v_Quote_Line_Insert_List (idx).EXT_SELL_PRICE,
--                                 v_Quote_Line_Insert_List (idx).LEAD_TIME,
--                                 v_Quote_Line_Insert_List (idx).ENCRYPTION_STATUS,
--                                 lv_Date,
--                                 lv_User_Id,
--                                 lv_Date,
--                                 lv_User_Id,
--                                 v_Out_Search_Data_List (idx).SYSTEM_DISCOUNT,
--                                 v_Out_Search_Data_List (idx).EOS_DATE);
--               END LOOP;*/
--               -- end changes made by ruchhabr 02-MAY-2014
--
--               -- Delete records from WCT_QUOTE_LINE
--               DELETE FROM WCT_QUOTE_LINE QL
--                     WHERE     QL.QUOTE_ID = lv_Quote_Id
--                           AND REQUESTED_PART NOT IN (SELECT REQUESTED_PART
--                                                        FROM WCT_QUOTE_LINE_TMP EL);
--
--               -- Empty the temp table
--               DELETE FROM WCT_QUOTE_LINE_TMP;
--
--               -- Add rows to the WCT_QUOTE_LINE_AUDIT table
--               FOR idx IN 1 .. v_Out_Search_Data_List.COUNT ()
--               LOOP
--                  INSERT INTO WCT_QUOTE_LINE_AUDIT
--                     SELECT *
--                       FROM WCT_QUOTE_LINE
--                      WHERE     QUOTE_ID = lv_Quote_Id
--                            AND REQUESTED_PART =
--                                   v_Out_Search_Data_List (idx).REQUESTED_PART;
--               END LOOP;
--            END IF;
--         EXCEPTION
--            WHEN OTHERS
--            THEN
--               --LOG EXCEPTION
--               v_Error_Message := NULL;
--               v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--               INSERT INTO WCT_ERROR_LOG
--                    VALUES (UPPER (lv_Requested_Part),
--                            lv_User_Id,
--                            'Data_extract - Step 11.0 - ' || v_Error_Message,
--                            SYSDATE);
--         END;
--      END IF;
--
--
--      --12.0 Fetch customer details
--
--      BEGIN
--         SELECT WCT_CUSTOMER_DETAIL_OBJECT (COMPANY_NAME,
--                                            POC_FIRST_NAME,
--                                            POC_LAST_NAME,
--                                            POC_TITLE,
--                                            ADDRESS_1,
--                                            ADDRESS_2,
--                                            CITY,
--                                            STATE,
--                                            COUNTRY,
--                                            ZIP)
--           INTO v_Customer_Detail_Object
--           FROM WCT_CUSTOMER CUST, WCT_COMPANY_MASTER COM
--          WHERE     CUSTOMER_ID = lv_Customer_Id
--                AND CUST.COMPANY_ID = COM.COMPANY_ID;
--      EXCEPTION
--         WHEN NO_DATA_FOUND
--         THEN
--            --LOG EXCEPTION
--            INSERT INTO WCT_ERROR_LOG
--                 VALUES (UPPER (lv_Requested_Part),
--                         lv_User_Id,
--                         'Data_extract - Step 12.0 - No data found',
--                         SYSDATE);
--         WHEN OTHERS
--         THEN
--            --LOG EXCEPTION
--            v_Error_Message := NULL;
--            v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--            INSERT INTO WCT_ERROR_LOG
--                 VALUES (UPPER (lv_Requested_Part),
--                         lv_User_Id,
--                         'Data_extract - Step 12.0 - ' || v_Error_Message,
--                         SYSDATE);
--      END;
--
--      COMMIT;
--      v_Out_Search_Result_Object :=
--         WCT_SEARCH_RESULT_OBJECT (v_Out_Search_Data_List,
--                                   v_Customer_Detail_Object,
--                                   v_Invalid_Part_List,
--                                   lv_Quote_Id,
--                                   v_Exclude_Pid_List, --added for exclude PID logic karusing Sep 2014
--                                   v_Brightline_Plus_Pid_List, --added for exclude PID logic karusing Sep 2014
--                                   v_RL_Pid_List);     --added for RL Oct 2014
--
--      o_Search_Result_Object := v_Out_Search_Result_Object;
--
--      /* Check and when Inventory is zero, notify Support team */
--      SELECT COUNT (*)
--        INTO lv_c3_inv_count
--        FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_TBL;
--
--      IF (lv_c3_inv_count = 0)
--      THEN
--         ZERO_INVENTORY_EMAIL;
--      END IF;
--   EXCEPTION
--      WHEN OTHERS
--      THEN
--         --LOG EXCEPTION
--         v_Error_Message := NULL;
--         v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--         INSERT INTO WCT_ERROR_LOG
--                 VALUES (
--                           UPPER (lv_Requested_Part),
--                           lv_User_Id,
--                              'Data_extract - '
--                           || v_Error_Message
--                           || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
--                           SYSDATE);
--   END;

   /*PROCEDURE TO UPDATE QUOTE LINES FOR SEARCHED BOMs*/
   PROCEDURE SAVE_QUOTE (
      i_Update_Quote_Object          IN     WCT_QUOTE_OBJECT,
      i_Save_Type                    IN     VARCHAR2,
      i_Customer_Id                  IN     NUMBER,
      o_Save_Quote_Response_Object      OUT WCT_SAVE_QUOTE_RESPONSE_OBJECT)
   IS
      v_Save_Quote_Response_Object   WCT_SAVE_QUOTE_RESPONSE_OBJECT;

      lv_Update_Quote_List           WCT_QUOTE_LINE_LIST;
      lv_Update_Quote_Count          NUMBER;
      lv_Quote_Id                    VARCHAR2 (10);
      lv_User_Id                     VARCHAR2 (12);
      lv_Status                      VARCHAR2 (7);
      lv_Response_Message            VARCHAR2 (100);
      lv_Last_Updated_Date           DATE;
      lv_Deal_Value                  NUMBER (15, 2);
      lv_Quote_Id_Type               VARCHAR2 (1);
      lv_Quote_Id_New                VARCHAR2 (10);
      lv_Eos_Date                    DATE;
      lv_Eos_Date_Over               DATE;
      lv_Discount                    NUMBER (5, 2);
      lv_Comments_L1                 VARCHAR2 (13) := v_Empty_String;
      lv_Comments_L2                 VARCHAR2 (13) := v_Empty_String;
      lv_Approval_Status_L1          CHAR;
      lv_Approval_Status_L2          CHAR;
      lv_Approval_Level              NUMBER;
      lv_Approval_Level_0            BOOLEAN;
      lv_Approval_Level_1            BOOLEAN;
      lv_Approval_Level_2            BOOLEAN;
      lv_Lead_Time_Id                NUMBER;
      lv_Lead_Time_Count             NUMBER;
      lv_Available_Quantity          NUMBER;
      lv_Ext_Sell_Price              NUMBER (15, 2);

      lv_Requested_Part              VARCHAR2 (50);
      --Added by satbanda on 28-Mar-2017 for Validate PID logic <start>
      lv_Manufacture_Part           VARCHAR2 (50):= v_Empty_String;
      lv_Refurbished_Part           VARCHAR2 (50):= v_Empty_String;
      lv_spare_Part                 VARCHAR2 (50):= v_Empty_String;
      lv_Wholesale_Part             VARCHAR2 (50):= v_Empty_String;
      lv_Error_Message              VARCHAR2 (2000);
      lv_Part_Validity_Flag         VARCHAR2 (30);
      --Added by satbanda on 28-Mar-2017 for Validate PID logic <End>
      lv_Customer_Id                 NUMBER;
      lv_Static_Price                NUMBER (15, 2);
      lv_Static_Price_Exists         CHAR;
      --Commented by satbanda on 28-Mar-2017 for validate PID logic <Start>
      /*lv_Product_Name_Stripped       VARCHAR2 (50);
      lv_Product_Name_Stripped_WS    VARCHAR2 (50);
      lv_Conflicting_Part_Count      NUMBER;
      lv_Conflicting_Part_Id         VARCHAR2 (50);
      lv_Conflicting_Part_WS         VARCHAR2 (50);*/
      --Commented by satbanda on 28-Mar-2017 for validate PID logic <End>
      lv_View_Quote_Details_Object   WCT_VIEW_QUOTE_DETAILS_OBJECT;
      lv_Return_Quote_List           WCT_QUOTE_LINE_LIST;
      lv_Skip_Approval_Workflow      CHAR;
      lv_User_Notes                  VARCHAR2 (1500);
      lv_Quote_Status                VARCHAR2 (8);

      v_To_List                      WCT_VARCHAR_LIST;
      v_Cc_List                      WCT_VARCHAR_LIST;
      lv_From                        VARCHAR2 (50);
      lv_Subject                     VARCHAR2 (1000);
      lv_Html_Msg                    CLOB;
       --Added by satbanda for US136936 <Start>
      lv_dis_n_2_val2                NUMBER:=0;
      lv_dis_n_2_val1                NUMBER:=0;
      lv_dis_n_1_val2                NUMBER:=0;
      lv_dis_n_1_val1                NUMBER:=0;
      lv_dis_n_val2                  NUMBER:=0;
      lv_dis_n_val1                  NUMBER:=0;
    --Added by satbanda for US136936 <End>

   BEGIN
      -- logic to sort the incomming collection
      lv_Update_Quote_List :=
         SORT_QUOTE_LINE_LIST (i_Update_Quote_Object.QUOTE_LINE_LIST);

      --lv_Update_Quote_List := i_Update_Quote_Object.QUOTE_LINE_LIST;
      lv_Update_Quote_Count := lv_Update_Quote_List.COUNT ();
      lv_Quote_Id := i_Update_Quote_Object.QUOTE_ID;
      lv_User_Id := i_Update_Quote_Object.USER_ID;
      lv_User_Notes := i_Update_Quote_Object.USER_NOTES;
      lv_Customer_Id := i_Customer_Id;
      lv_Return_Quote_List := NULL;

      lv_Deal_Value := 0;

      lv_Quote_Id_Type := SUBSTR (lv_Quote_Id, 1, 1);

      --insert INTO nar(seq,quote_id,issue) values (3,' Save QUOTE=> '||lv_Quote_Id,lv_User_Id||' <lv_User_Id$lv_Customer_Id> '||lv_Customer_Id); commit;

      -- If dummy quote id, i.e., old status is new quote
      IF (lv_Quote_Id_Type = v_Quote_Id_Type_Dummy)
      THEN
         lv_Quote_Id_New := GENERATE_QUOTE_ID (v_Quote_Id_Type_Quote);

         -- need to use tmp table because of the foreign key reference
         DELETE FROM WCT_QUOTE_LINE_TMP;

         INSERT INTO WCT_QUOTE_LINE_TMP (LINE_ID,
                                         QUOTE_ID,
                                         LINE_NO,
                                         REQUESTED_PART,
                                         WHOLESALE_PART,
                                         REFURBISHED_PART,
                                         MANUFACTURING_PART,
                                         REQUESTED_QUANTITY,
                                         AVAILABLE_QUANTITY,
                                         BROKER_OFFER,
                                         GLP,
                                         SUGGESTED_PRICE,
                                         EXT_SELL_PRICE,
                                         LEAD_TIME,
                                         CREATED_DATE,
                                         CREATED_BY,
                                         LAST_UPDATED_DATE,
                                         LAST_UPDATED_BY,
                                         ENCRYPTION_STATUS,
                                         INVENTORY_DETAIL_NOTES,
                                         DISCOUNT,
                                         EOS_DATE,
                                         COMMENTS_L1,
                                         COMMENTS_L2,
                                         APPROVAL_LEVEL,
                                         APPROVAL_STATUS_L1,
                                         APPROVAL_STATUS_L2,
                                         PROMO_FLAG --US151907
                                         )
            SELECT LINE_ID,
                   QUOTE_ID,
                   LINE_NO,
                   REQUESTED_PART,
                   WHOLESALE_PART,
                   REFURBISHED_PART,
                   MANUFACTURING_PART,
                   REQUESTED_QUANTITY,
                   AVAILABLE_QUANTITY,
                   BROKER_OFFER,
                   GLP,
                   SUGGESTED_PRICE,
                   EXT_SELL_PRICE,
                   LEAD_TIME,
                   CREATED_DATE,
                   CREATED_BY,
                   LAST_UPDATED_DATE,
                   LAST_UPDATED_BY,
                   ENCRYPTION_STATUS,
                   INVENTORY_DETAIL_NOTES,
                   DISCOUNT,
                   EOS_DATE,
                   COMMENTS_L1,
                   COMMENTS_L2,
                   APPROVAL_LEVEL,
                   APPROVAL_STATUS_L1,
                   APPROVAL_STATUS_L2,
                   PROMO_FLAG --US151907
              FROM WCT_QUOTE_LINE
             WHERE QUOTE_ID = lv_Quote_Id;

         DELETE FROM WCT_QUOTE_LINE
               WHERE QUOTE_ID = lv_Quote_Id;

         UPDATE WCT_QUOTE_HEADER
            SET QUOTE_ID = lv_Quote_Id_New
          WHERE QUOTE_ID = lv_Quote_Id;

         UPDATE WCT_QUOTE_LINE_TMP
            SET QUOTE_ID = lv_Quote_Id_New;

         INSERT INTO WCT_QUOTE_LINE (LINE_ID,
                                     QUOTE_ID,
                                     LINE_NO,
                                     REQUESTED_PART,
                                     WHOLESALE_PART,
                                     REFURBISHED_PART,
                                     MANUFACTURING_PART,
                                     REQUESTED_QUANTITY,
                                     AVAILABLE_QUANTITY,
                                     BROKER_OFFER,
                                     GLP,
                                     SUGGESTED_PRICE,
                                     EXT_SELL_PRICE,
                                     LEAD_TIME,
                                     CREATED_DATE,
                                     CREATED_BY,
                                     LAST_UPDATED_DATE,
                                     LAST_UPDATED_BY,
                                     ENCRYPTION_STATUS,
                                     INVENTORY_DETAIL_NOTES,
                                     DISCOUNT,
                                     EOS_DATE,
                                     COMMENTS_L1,
                                     COMMENTS_L2,
                                     APPROVAL_LEVEL,
                                     APPROVAL_STATUS_L1,
                                     APPROVAL_STATUS_L2,
                                     PROMO_FLAG --US151907
                                     )
            SELECT LINE_ID,
                   QUOTE_ID,
                   LINE_NO,
                   REQUESTED_PART,
                   WHOLESALE_PART,
                   REFURBISHED_PART,
                   MANUFACTURING_PART,
                   REQUESTED_QUANTITY,
                   AVAILABLE_QUANTITY,
                   BROKER_OFFER,
                   GLP,
                   SUGGESTED_PRICE,
                   EXT_SELL_PRICE,
                   LEAD_TIME,
                   CREATED_DATE,
                   CREATED_BY,
                   LAST_UPDATED_DATE,
                   LAST_UPDATED_BY,
                   ENCRYPTION_STATUS,
                   INVENTORY_DETAIL_NOTES,
                   DISCOUNT,
                   EOS_DATE,
                   COMMENTS_L1,
                   COMMENTS_L2,
                   APPROVAL_LEVEL,
                   APPROVAL_STATUS_L1,
                   APPROVAL_STATUS_L2,
                   PROMO_FLAG --US151907
              FROM WCT_QUOTE_LINE_TMP;

         DELETE FROM WCT_QUOTE_LINE_TMP;

         lv_Quote_Id := lv_Quote_Id_New;
      END IF;

      --insert INTO nar(seq,quote_id,issue) values (4,'Save Quote=> '||lv_Quote_Id_New,lv_User_Id||' <lv_User_Id$lv_Customer_Id> '||lv_Customer_Id); commit;
      SELECT SYSDATE INTO lv_Last_Updated_Date FROM DUAL;

      COMMIT;

      IF (lv_Update_Quote_Count > 0)
      THEN
         --Insert into Quote_Header_Audit table
         DECLARE
            lv_audit_header_quote_id        VARCHAR2 (10 BYTE);
            lv_audit_header_customer_id     NUMBER;
            lv_audit_header_created_date    DATE;
            lv_audit_header_created_by      VARCHAR2 (12 BYTE);
            lv_aud_head_last_updated_date   DATE;
            lv_aud_head_last_updated_by     VARCHAR2 (12 BYTE);
            lv_audit_header_deal_value      NUMBER (15, 2);
            lv_audit_header_status          VARCHAR2 (10 BYTE);
            lv_audit_header_user_notes      VARCHAR2 (1500 BYTE);
         BEGIN
            lv_audit_header_quote_id := NULL;
            lv_audit_header_customer_id := NULL;
            lv_audit_header_created_date := NULL;
            lv_audit_header_created_by := NULL;
            lv_aud_head_last_updated_date := NULL;
            lv_aud_head_last_updated_by := NULL;
            lv_audit_header_deal_value := NULL;
            lv_audit_header_status := NULL;
            lv_audit_header_user_notes := NULL;

            SELECT QUOTE_ID,
                   CUSTOMER_ID,
                   CREATED_DATE,
                   CREATED_BY,
                   LAST_UPDATED_DATE,
                   LAST_UPDATED_BY,
                   DEAL_VALUE,
                   STATUS,
                   USER_NOTES
              INTO lv_audit_header_quote_id,
                   lv_audit_header_customer_id,
                   lv_audit_header_created_date,
                   lv_audit_header_created_by,
                   lv_aud_head_last_updated_date,
                   lv_aud_head_last_updated_by,
                   lv_audit_header_deal_value,
                   lv_audit_header_status,
                   lv_audit_header_user_notes
              FROM WCT_QUOTE_HEADER
             WHERE QUOTE_ID = lv_Quote_Id;

            INSERT INTO WCT_QUOTE_HEADER_AUDIT (AUDIT_HEADER_ID,
                                                QUOTE_ID,
                                                CUSTOMER_ID,
                                                CREATED_DATE,
                                                CREATED_BY,
                                                LAST_UPDATED_DATE,
                                                LAST_UPDATED_BY,
                                                DEAL_VALUE,
                                                STATUS,
                                                USER_NOTES)
                 VALUES (WCT_AUDIT_HEADER_ID.NEXTVAL,
                         lv_audit_header_quote_id,
                         lv_audit_header_customer_id,
                         lv_audit_header_created_date,
                         lv_audit_header_created_by,
                         lv_aud_head_last_updated_date,
                         lv_aud_head_last_updated_by,
                         lv_audit_header_deal_value,
                         lv_audit_header_status,
                         lv_audit_header_user_notes);
         EXCEPTION
            WHEN OTHERS
            THEN
               --LOG EXCEPTION
               v_Error_Message := NULL;
               v_Error_Message := SUBSTR (SQLERRM, 1, 200);

               INSERT INTO WCT_ERROR_LOG
                    VALUES ('INSERTING INTO AUDIT HEADER-1',
                            lv_User_Id,
                            'SAVE_QUOTE - ' || v_Error_Message,
                            SYSDATE);
         END;

         -- NEXT SUB PROC

         --CODE HERE
         IF (i_Update_Quote_Object.QUOTE_UPDATED_FLAG = v_Flag_Yes)
         THEN
            BEGIN
               FOR counter IN 1 .. lv_Update_Quote_List.COUNT ()
               LOOP
                  EXIT WHEN counter IS NULL;

                  INSERT INTO WCT_QUOTE_LINE_AUDIT
                     SELECT *
                       FROM WCT_QUOTE_LINE
                      WHERE     QUOTE_ID = lv_Quote_Id --lv_Update_Quote_List (counter).QUOTE_ID
                            AND REQUESTED_PART =
                                   lv_Update_Quote_List (counter).REQUESTED_PART;
               END LOOP;

               -- Start of code changes done by Infosys for April 2014 release -- ruchhabr
               /*FORALL idx
                   IN lv_Update_Quote_List.FIRST .. lv_Update_Quote_List.LAST
                  UPDATE WCT_QUOTE_LINE
                     SET SUGGESTED_PRICE =
                            lv_Update_Quote_List (idx).SUGGESTED_PRICE,
                         EXT_SELL_PRICE =
                            lv_Update_Quote_List (idx).EXT_SELL_PRICE,
                         LEAD_TIME = lv_Update_Quote_List (idx).LEAD_TIME,
                         REQUESTED_QUANTITY =
                            lv_Update_Quote_List (idx).REQUESTED_QUANTITY,
                         AVAILABLE_QUANTITY =
                            lv_Update_Quote_List (idx).AVAILABLE_QUANTITY,
                         DISCOUNT = lv_Update_Quote_List (idx).DISCOUNT,
                         INVENTORY_DETAIL_NOTES =
                            lv_Update_Quote_List (idx).INVENTORY_DETAIL_NOTES,
                         LAST_UPDATED_BY = lv_User_Id,
                         LAST_UPDATED_DATE = lv_Last_Updated_Date
                   WHERE     1 = 1 --    AND LINE_ID = lv_Update_Quote_List (idx).LINE_ID
                         AND QUOTE_ID = lv_Quote_Id
                         AND REQUESTED_PART =
                                lv_Update_Quote_List (idx).REQUESTED_PART;*/

               FOR idx IN 1 .. lv_Update_Quote_List.COUNT
               LOOP
                  IF (lv_Update_Quote_List (idx).ROW_ID = 1)
                  THEN
                     lv_Available_Quantity :=
                        lv_Update_Quote_List (idx).AVAILABLE_QUANTITY;

                     BEGIN
                        SELECT LEAD_TIME
                          INTO lv_Lead_Time_Id
                          FROM WCT_QUOTE_LINE
                         WHERE     1 = 1
                               AND QUOTE_ID = lv_Quote_Id
                               AND REQUESTED_PART =
                                      lv_Update_Quote_List (idx).REQUESTED_PART;

                        -- Get actual lead time count from WCT_LEAD_TIME for the current part
                        SELECT COUNT (*)
                          INTO lv_Lead_Time_Count
                          FROM WCT_LEAD_TIME
                         WHERE LEAD_TIME_ID = lv_Lead_Time_Id;

                        IF (lv_Update_Quote_List (idx).ROW_ID = 1)
                        THEN
                           -- check if UI sends 3 rows for the same requested part
                           -- IF (lv_Update_Quote_List.COUNT >= 3)
                           --  THEN
                           IF (    (idx + 1 < lv_Update_Quote_Count)
                               AND (lv_Update_Quote_List (idx).REQUESTED_PART =
                                       lv_Update_Quote_List (idx + 1).REQUESTED_PART)
                               AND (lv_Update_Quote_List (idx + 1).ROW_ID = 2)
                               AND (lv_Update_Quote_List (idx).REQUESTED_PART =
                                       lv_Update_Quote_List (idx + 2).REQUESTED_PART)
                               AND (lv_Update_Quote_List (idx + 2).ROW_ID = 3))
                           THEN
                              lv_Available_Quantity :=
                                 lv_Update_Quote_List (idx).AVAILABLE_QUANTITY;

                              -- update the first row
                              UPDATE WCT_LEAD_TIME
                                 SET REQUESTED_QUANTITY =
                                        lv_Update_Quote_List (idx).REQUESTED_QUANTITY,
                                     AVAILABLE_QUANTITY =
                                        lv_Update_Quote_List (idx).AVAILABLE_QUANTITY,
                                     LEAD_TIME =
                                        lv_Update_Quote_List (idx).LEAD_TIME,
                                     INVENTORY_DETAIL_NOTES =
                                        lv_Update_Quote_List (idx).INVENTORY_DETAIL_NOTES,
                                     LAST_UPDATED_DATE = lv_Last_Updated_Date,
                                     LAST_UPDATED_BY = lv_User_Id,
                                     QUANTITY_ON_HAND = -- added for June 2014 release - ruchhabr
                                        lv_Update_Quote_List (idx).QUANTITY_ON_HAND,
                                     QUANTITY_IN_TRANSIT = -- added for June 2014 release - ruchhabr
                                        lv_Update_Quote_List (idx).QUANTITY_IN_TRANSIT
                               WHERE     LEAD_TIME_ID = lv_Lead_Time_Id
                                     AND ROW_ID = 1;

                              IF (lv_Lead_Time_Count = 1)
                              THEN
                                 INSERT
                                   INTO WCT_LEAD_TIME (
                                           LEAD_TIME_ID,
                                           REQUESTED_PART,
                                           REQUESTED_QUANTITY,
                                           AVAILABLE_QUANTITY,
                                           LEAD_TIME,
                                           ROW_ID,
                                           INVENTORY_DETAIL_NOTES,
                                           CREATED_DATE,
                                           CREATED_BY,
                                           LAST_UPDATED_DATE,
                                           LAST_UPDATED_BY,
                                           QUANTITY_ON_HAND, -- added for June 2014 release - ruchhabr
                                           QUANTITY_IN_TRANSIT) -- added for June 2014 release - ruchhabr
                                    VALUES (
                                              lv_Lead_Time_Id,
                                              lv_Update_Quote_List (idx).REQUESTED_PART,
                                              lv_Update_Quote_List (idx).REQUESTED_QUANTITY,
                                              lv_Update_Quote_List (idx + 1).AVAILABLE_QUANTITY,
                                              TO_CHAR (
                                                 lv_Update_Quote_List (
                                                    idx + 1).LEAD_TIME),
                                              2,
                                              lv_Update_Quote_List (idx + 1).INVENTORY_DETAIL_NOTES,
                                              lv_Last_Updated_Date,
                                              lv_User_Id,
                                              lv_Last_Updated_Date,
                                              lv_User_Id,
                                              lv_Update_Quote_List (idx + 1).QUANTITY_ON_HAND, -- added for June 2014 release - ruchhabr
                                              lv_Update_Quote_List (idx + 1).QUANTITY_IN_TRANSIT);

                                 -- add 3rd row
                                 INSERT
                                   INTO WCT_LEAD_TIME (
                                           LEAD_TIME_ID,
                                           REQUESTED_PART,
                                           REQUESTED_QUANTITY,
                                           AVAILABLE_QUANTITY,
                                           LEAD_TIME,
                                           ROW_ID,
                                           INVENTORY_DETAIL_NOTES,
                                           CREATED_DATE,
                                           CREATED_BY,
                                           LAST_UPDATED_DATE,
                                           LAST_UPDATED_BY,
                                           QUANTITY_ON_HAND, -- added for June 2014 release - ruchhabr
                                           QUANTITY_IN_TRANSIT) -- added for June 2014 release - ruchhabr
                                    VALUES (
                                              lv_Lead_Time_Id,
                                              lv_Update_Quote_List (idx).REQUESTED_PART,
                                              lv_Update_Quote_List (idx).REQUESTED_QUANTITY,
                                              lv_Update_Quote_List (idx + 2).AVAILABLE_QUANTITY,
                                              TO_CHAR (
                                                 lv_Update_Quote_List (
                                                    idx + 2).LEAD_TIME),
                                              3,
                                              lv_Update_Quote_List (idx + 2).INVENTORY_DETAIL_NOTES,
                                              lv_Last_Updated_Date,
                                              lv_User_Id,
                                              lv_Last_Updated_Date,
                                              lv_User_Id,
                                              lv_Update_Quote_List (idx + 2).QUANTITY_ON_HAND, -- added for June 2014 release - ruchhabr
                                              lv_Update_Quote_List (idx + 2).QUANTITY_IN_TRANSIT);
                              -- added for June 2014 release - ruchhabr
                              ELSE
                                 IF (lv_Lead_Time_Count = 2) -- update 2nd row and add 3rd row
                                 THEN
                                    UPDATE WCT_LEAD_TIME
                                       SET REQUESTED_QUANTITY =
                                              lv_Update_Quote_List (idx).REQUESTED_QUANTITY,
                                           AVAILABLE_QUANTITY =
                                              lv_Update_Quote_List (idx + 1).AVAILABLE_QUANTITY,
                                           LEAD_TIME =
                                              lv_Update_Quote_List (idx + 1).LEAD_TIME,
                                           INVENTORY_DETAIL_NOTES =
                                              lv_Update_Quote_List (idx + 1).INVENTORY_DETAIL_NOTES,
                                           LAST_UPDATED_DATE =
                                              lv_Last_Updated_Date,
                                           LAST_UPDATED_BY = lv_User_Id,
                                           QUANTITY_ON_HAND = -- added for June 2014 release - ruchhabr
                                              lv_Update_Quote_List (idx + 1).QUANTITY_ON_HAND,
                                           QUANTITY_IN_TRANSIT = -- added for June 2014 release - ruchhabr
                                              lv_Update_Quote_List (idx + 1).QUANTITY_IN_TRANSIT
                                     WHERE     LEAD_TIME_ID = lv_Lead_Time_Id
                                           AND ROW_ID = 2;

                                    -- add 3rd row
                                    INSERT
                                      INTO WCT_LEAD_TIME (
                                              LEAD_TIME_ID,
                                              REQUESTED_PART,
                                              REQUESTED_QUANTITY,
                                              AVAILABLE_QUANTITY,
                                              LEAD_TIME,
                                              ROW_ID,
                                              INVENTORY_DETAIL_NOTES,
                                              CREATED_DATE,
                                              CREATED_BY,
                                              LAST_UPDATED_DATE,
                                              LAST_UPDATED_BY,
                                              QUANTITY_ON_HAND, -- added for June 2014 release - ruchhabr
                                              QUANTITY_IN_TRANSIT) -- added for June 2014 release - ruchhabr
                                       VALUES (
                                                 lv_Lead_Time_Id,
                                                 lv_Update_Quote_List (idx).REQUESTED_PART,
                                                 lv_Update_Quote_List (idx).REQUESTED_QUANTITY,
                                                 lv_Update_Quote_List (
                                                    idx + 2).AVAILABLE_QUANTITY,
                                                 TO_CHAR (
                                                    lv_Update_Quote_List (
                                                       idx + 2).LEAD_TIME),
                                                 3,
                                                 lv_Update_Quote_List (
                                                    idx + 2).INVENTORY_DETAIL_NOTES,
                                                 lv_Last_Updated_Date,
                                                 lv_User_Id,
                                                 lv_Last_Updated_Date,
                                                 lv_User_Id,
                                                 lv_Update_Quote_List (
                                                    idx + 2).QUANTITY_ON_HAND, -- added for June 2014 release - ruchhabr
                                                 lv_Update_Quote_List (
                                                    idx + 2).QUANTITY_IN_TRANSIT);
                                 -- added for June 2014 release - ruchhabr

                                 ELSE
                                    IF (lv_Lead_Time_Count = 3) --update 2nd and 3rd rows
                                    THEN
                                       UPDATE WCT_LEAD_TIME
                                          SET REQUESTED_QUANTITY =
                                                 lv_Update_Quote_List (idx).REQUESTED_QUANTITY,
                                              AVAILABLE_QUANTITY =
                                                 lv_Update_Quote_List (
                                                    idx + 1).AVAILABLE_QUANTITY,
                                              LEAD_TIME =
                                                 lv_Update_Quote_List (
                                                    idx + 1).LEAD_TIME,
                                              INVENTORY_DETAIL_NOTES =
                                                 lv_Update_Quote_List (
                                                    idx + 1).INVENTORY_DETAIL_NOTES,
                                              LAST_UPDATED_DATE =
                                                 lv_Last_Updated_Date,
                                              LAST_UPDATED_BY = lv_User_Id,
                                              QUANTITY_ON_HAND = -- added for June 2014 release - ruchhabr
                                                 lv_Update_Quote_List (
                                                    idx + 1).QUANTITY_ON_HAND,
                                              QUANTITY_IN_TRANSIT = -- added for June 2014 release - ruchhabr
                                                 lv_Update_Quote_List (
                                                    idx + 1).QUANTITY_IN_TRANSIT
                                        WHERE     LEAD_TIME_ID =
                                                     lv_Lead_Time_Id
                                              AND ROW_ID = 2;


                                       UPDATE WCT_LEAD_TIME
                                          SET REQUESTED_QUANTITY =
                                                 lv_Update_Quote_List (idx).REQUESTED_QUANTITY,
                                              AVAILABLE_QUANTITY =
                                                 lv_Update_Quote_List (
                                                    idx + 2).AVAILABLE_QUANTITY,
                                              LEAD_TIME =
                                                 lv_Update_Quote_List (
                                                    idx + 2).LEAD_TIME,
                                              INVENTORY_DETAIL_NOTES =
                                                 lv_Update_Quote_List (
                                                    idx + 2).INVENTORY_DETAIL_NOTES,
                                              LAST_UPDATED_DATE =
                                                 lv_Last_Updated_Date,
                                              LAST_UPDATED_BY = lv_User_Id,
                                              QUANTITY_ON_HAND = -- added for June 2014 release - ruchhabr
                                                 lv_Update_Quote_List (
                                                    idx + 2).QUANTITY_ON_HAND,
                                              QUANTITY_IN_TRANSIT = -- added for June 2014 release - ruchhabr
                                                 lv_Update_Quote_List (
                                                    idx + 2).QUANTITY_IN_TRANSIT
                                        WHERE     LEAD_TIME_ID =
                                                     lv_Lead_Time_Id
                                              AND ROW_ID = 3;
                                    END IF;
                                 END IF;
                              END IF;

                              lv_Available_Quantity :=
                                   lv_Available_Quantity
                                 + lv_Update_Quote_List (idx + 1).AVAILABLE_QUANTITY;

                              lv_Available_Quantity :=
                                   lv_Available_Quantity
                                 + lv_Update_Quote_List (idx + 2).AVAILABLE_QUANTITY;
                           -- end of row 3 exists

                           -- END IF;  -- end of3 rows exist

                           -- start of UI send 2 rows

                           ELSE
                              IF (    (idx < lv_Update_Quote_Count)
                                  AND (lv_Update_Quote_List (idx).REQUESTED_PART =
                                          lv_Update_Quote_List (idx + 1).REQUESTED_PART)
                                  AND (lv_Update_Quote_List (idx + 1).ROW_ID =
                                          2)
                                  AND (   (    (idx + 1 <
                                                   lv_Update_Quote_Count)
                                           AND ( (lv_Update_Quote_List (idx).REQUESTED_PART <>
                                                     lv_Update_Quote_List (
                                                        idx + 2).REQUESTED_PART)))
                                       OR (idx + 1 = lv_Update_Quote_Count)))
                              THEN
                                 lv_Available_Quantity :=
                                    lv_Update_Quote_List (idx).AVAILABLE_QUANTITY;

                                 -- update the first row
                                 UPDATE WCT_LEAD_TIME
                                    SET REQUESTED_QUANTITY =
                                           lv_Update_Quote_List (idx).REQUESTED_QUANTITY,
                                        AVAILABLE_QUANTITY =
                                           lv_Update_Quote_List (idx).AVAILABLE_QUANTITY,
                                        LEAD_TIME =
                                           lv_Update_Quote_List (idx).LEAD_TIME,
                                        INVENTORY_DETAIL_NOTES =
                                           lv_Update_Quote_List (idx).INVENTORY_DETAIL_NOTES,
                                        LAST_UPDATED_DATE =
                                           lv_Last_Updated_Date,
                                        LAST_UPDATED_BY = lv_User_Id,
                                        QUANTITY_ON_HAND = -- added for June 2014 release - ruchhabr
                                           lv_Update_Quote_List (idx).QUANTITY_ON_HAND,
                                        QUANTITY_IN_TRANSIT = -- added for June 2014 release - ruchhabr
                                           lv_Update_Quote_List (idx).QUANTITY_IN_TRANSIT
                                  WHERE     LEAD_TIME_ID = lv_Lead_Time_Id
                                        AND ROW_ID = 1;

                                 IF (lv_Lead_Time_Count = 1)
                                 THEN
                                    -- insert a new record for the next row

                                    INSERT
                                      INTO WCT_LEAD_TIME (
                                              LEAD_TIME_ID,
                                              REQUESTED_PART,
                                              REQUESTED_QUANTITY,
                                              AVAILABLE_QUANTITY,
                                              LEAD_TIME,
                                              ROW_ID,
                                              INVENTORY_DETAIL_NOTES,
                                              CREATED_DATE,
                                              CREATED_BY,
                                              LAST_UPDATED_DATE,
                                              LAST_UPDATED_BY,
                                              QUANTITY_ON_HAND, -- added for June 2014 release - ruchhabr
                                              QUANTITY_IN_TRANSIT) -- added for June 2014 release - ruchhabr
                                       VALUES (
                                                 lv_Lead_Time_Id,
                                                 lv_Update_Quote_List (idx).REQUESTED_PART,
                                                 lv_Update_Quote_List (idx).REQUESTED_QUANTITY,
                                                 lv_Update_Quote_List (
                                                    idx + 1).AVAILABLE_QUANTITY,
                                                 TO_CHAR (
                                                    lv_Update_Quote_List (
                                                       idx + 1).LEAD_TIME),
                                                 2,
                                                 lv_Update_Quote_List (
                                                    idx + 1).INVENTORY_DETAIL_NOTES,
                                                 lv_Last_Updated_Date,
                                                 lv_User_Id,
                                                 lv_Last_Updated_Date,
                                                 lv_User_Id,
                                                 lv_Update_Quote_List (
                                                    idx + 1).QUANTITY_ON_HAND, -- added for June 2014 release - ruchhabr
                                                 lv_Update_Quote_List (
                                                    idx + 1).QUANTITY_IN_TRANSIT);
                                 -- added for June 2014 release - ruchhabr
                                 ELSE
                                    IF (lv_Lead_Time_Count = 2)
                                    THEN
                                       -- update the second row
                                       UPDATE WCT_LEAD_TIME
                                          SET REQUESTED_QUANTITY =
                                                 lv_Update_Quote_List (idx).REQUESTED_QUANTITY,
                                              AVAILABLE_QUANTITY =
                                                 lv_Update_Quote_List (
                                                    idx + 1).AVAILABLE_QUANTITY,
                                              LEAD_TIME =
                                                 lv_Update_Quote_List (
                                                    idx + 1).LEAD_TIME,
                                              INVENTORY_DETAIL_NOTES =
                                                 lv_Update_Quote_List (
                                                    idx + 1).INVENTORY_DETAIL_NOTES,
                                              LAST_UPDATED_DATE =
                                                 lv_Last_Updated_Date,
                                              LAST_UPDATED_BY = lv_User_Id,
                                              QUANTITY_ON_HAND = -- added for June 2014 release - ruchhabr
                                                 lv_Update_Quote_List (
                                                    idx + 1).QUANTITY_ON_HAND,
                                              QUANTITY_IN_TRANSIT = -- added for June 2014 release - ruchhabr
                                                 lv_Update_Quote_List (
                                                    idx + 1).QUANTITY_IN_TRANSIT
                                        WHERE     LEAD_TIME_ID =
                                                     lv_Lead_Time_Id
                                              AND ROW_ID = 2;
                                    ELSE
                                       IF (lv_Lead_Time_Count = 3) -- delete row from DB as UI sent only 2 rows
                                       THEN
                                          DELETE FROM WCT_LEAD_TIME
                                                WHERE     LEAD_TIME_ID =
                                                             lv_Lead_Time_Id
                                                      AND ROW_ID = 3;
                                       END IF;
                                    END IF;
                                 END IF;

                                 lv_Available_Quantity :=
                                      lv_Available_Quantity
                                    + lv_Update_Quote_List (idx + 1).AVAILABLE_QUANTITY;
                              -- end of loop where 2nd row exists
                              --END IF;



                              ELSE
                                 IF (   (    (idx < lv_Update_Quote_Count)
                                         AND (lv_Update_Quote_List (idx).REQUESTED_PART <>
                                                 lv_Update_Quote_List (
                                                    idx + 1).REQUESTED_PART))
                                     OR (idx = lv_Update_Quote_Count))
                                 THEN
                                    IF (   lv_Lead_Time_Count = 3
                                        OR lv_Lead_Time_Count = 2) -- delete row 2 or 3  from DB as UI sent only 1 rows
                                    THEN
                                       DELETE FROM WCT_LEAD_TIME
                                             WHERE     LEAD_TIME_ID =
                                                          lv_Lead_Time_Id
                                                   AND ROW_ID IN (2, 3);
                                    END IF;      -- delete row 2 and 3 from DB
                                 END IF;  -- end of only 1 row retuned from UI
                              END IF;   -- end of only 2 rows returned from UI
                           END IF;      -- end of only 3 rows returned from UI

                           -- update first row
                           UPDATE WCT_LEAD_TIME
                              SET REQUESTED_QUANTITY =
                                     lv_Update_Quote_List (idx).REQUESTED_QUANTITY,
                                  AVAILABLE_QUANTITY =
                                     lv_Update_Quote_List (idx).AVAILABLE_QUANTITY,
                                  LEAD_TIME =
                                     lv_Update_Quote_List (idx).LEAD_TIME,
                                  INVENTORY_DETAIL_NOTES =
                                     lv_Update_Quote_List (idx).INVENTORY_DETAIL_NOTES,
                                  LAST_UPDATED_DATE = lv_Last_Updated_Date,
                                  LAST_UPDATED_BY = lv_User_Id,
                                  QUANTITY_ON_HAND = -- added for June 2014 release - ruchhabr
                                     lv_Update_Quote_List (idx).QUANTITY_ON_HAND,
                                  QUANTITY_IN_TRANSIT = -- added for June 2014 release - ruchhabr
                                     lv_Update_Quote_List (idx).QUANTITY_IN_TRANSIT
                            WHERE     LEAD_TIME_ID = lv_Lead_Time_Id
                                  AND ROW_ID = 1;
                        -- END IF;
                        END IF;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           --LOG EXCEPTION
                           v_Error_Message := NULL;
                           v_Error_Message := SUBSTR (SQLERRM, 1, 200);

                           INSERT INTO WCT_ERROR_LOG
                                VALUES ('UPDATING WCT_LEAD_TIME',
                                        lv_User_Id,
                                        'SAVE_QUOTE - ' || v_Error_Message,
                                        SYSDATE);
                     END;

                     lv_Ext_Sell_Price :=
                          LEAST (
                             lv_Available_Quantity,
                             lv_Update_Quote_List (idx).REQUESTED_QUANTITY)
                        * lv_Update_Quote_List (idx).SUGGESTED_PRICE;

                     UPDATE WCT_QUOTE_LINE
                        SET SUGGESTED_PRICE =
                               lv_Update_Quote_List (idx).SUGGESTED_PRICE,
                            EXT_SELL_PRICE = lv_Ext_Sell_Price,
                            REQUESTED_QUANTITY =
                               lv_Update_Quote_List (idx).REQUESTED_QUANTITY,
                            AVAILABLE_QUANTITY = lv_Available_Quantity,
                            DISCOUNT = lv_Update_Quote_List (idx).DISCOUNT,
                            INVENTORY_DETAIL_NOTES =
                               lv_Update_Quote_List (idx).INVENTORY_DETAIL_NOTES,
                            PROMO_FLAG =
                               lv_Update_Quote_List (idx).PROMO_FLAG,--US151907
                            LAST_UPDATED_BY = lv_User_Id,
                            LAST_UPDATED_DATE = lv_Last_Updated_Date
                      WHERE     1 = 1
                            AND QUOTE_ID = lv_Quote_Id
                            AND REQUESTED_PART =
                                   lv_Update_Quote_List (idx).REQUESTED_PART;
                  END IF;
               END LOOP;
            -- End of code changes done by Infosys for April 2014 release -- ruchhabr
            EXCEPTION
               WHEN OTHERS
               THEN
                  lv_Status := v_Status_Failure;
                  lv_Response_Message :=
                     'Quote generation was unsuccessful due to some technical issue. Please try later.';

                  --LOG EXCEPTION
                  v_Error_Message := NULL;
                  v_Error_Message := SUBSTR (SQLERRM, 1, 200);

                  INSERT INTO WCT_ERROR_LOG
                       VALUES ('UPDATING QUOTE LINE',
                               lv_User_Id,
                               'SAVE_QUOTE - ' || v_Error_Message,
                               SYSDATE);
            END;
         END IF;

         --CODE ENDS

         SELECT SUM (EXT_SELL_PRICE)
           INTO lv_Deal_Value
           FROM WCT_QUOTE_LINE
          WHERE QUOTE_ID = lv_Quote_Id;
      -- ELSE CONDITION HANDLES CASES WHEN NO ROWS ARE UPDATED AND GENERATE QUOTE / SAVE AS DRAFT (NEW TO DRAFT) IS CLICKED
      ELSE
         DECLARE
            lv_audit_header_quote_id        VARCHAR2 (10 BYTE);
            lv_audit_header_customer_id     NUMBER;
            lv_audit_header_created_date    DATE;
            lv_audit_header_created_by      VARCHAR2 (12 BYTE);
            lv_aud_head_last_updated_date   DATE;
            lv_aud_head_last_updated_by     VARCHAR2 (12 BYTE);
            lv_audit_header_deal_value      NUMBER (15, 2);
            lv_audit_header_status          VARCHAR2 (10 BYTE);
         BEGIN
            lv_audit_header_quote_id := NULL;
            lv_audit_header_customer_id := NULL;
            lv_audit_header_created_date := NULL;
            lv_audit_header_created_by := NULL;
            lv_aud_head_last_updated_date := NULL;
            lv_aud_head_last_updated_by := NULL;
            lv_audit_header_deal_value := NULL;
            lv_audit_header_status := NULL;

            SELECT QUOTE_ID,
                   CUSTOMER_ID,
                   CREATED_DATE,
                   CREATED_BY,
                   LAST_UPDATED_DATE,
                   LAST_UPDATED_BY,
                   DEAL_VALUE,
                   STATUS
              INTO lv_audit_header_quote_id,
                   lv_audit_header_customer_id,
                   lv_audit_header_created_date,
                   lv_audit_header_created_by,
                   lv_aud_head_last_updated_date,
                   lv_aud_head_last_updated_by,
                   lv_audit_header_deal_value,
                   lv_audit_header_status
              FROM WCT_QUOTE_HEADER
             WHERE QUOTE_ID = lv_Quote_Id;


            --C0DE HERE
            --            IF ( (lv_audit_header_status = 'DRAFT')
            --                OR (lv_audit_header_status = 'QUOTE'
            --                    AND i_Update_Quote_Object.QUOTE_UPDATED_FLAG = 'Y'))
            --            THEN
            INSERT INTO WCT_QUOTE_HEADER_AUDIT (AUDIT_HEADER_ID,
                                                QUOTE_ID,
                                                CUSTOMER_ID,
                                                CREATED_DATE,
                                                CREATED_BY,
                                                LAST_UPDATED_DATE,
                                                LAST_UPDATED_BY,
                                                DEAL_VALUE,
                                                STATUS)
                 VALUES (WCT_AUDIT_HEADER_ID.NEXTVAL,
                         lv_audit_header_quote_id,
                         lv_audit_header_customer_id,
                         lv_audit_header_created_date,
                         lv_audit_header_created_by,
                         lv_aud_head_last_updated_date,
                         lv_aud_head_last_updated_by,
                         lv_audit_header_deal_value,
                         lv_audit_header_status);
         --            END IF;
         -- COD ENDS
         EXCEPTION
            WHEN OTHERS
            THEN
               --LOG EXCEPTION
               v_Error_Message := NULL;
               v_Error_Message := SUBSTR (SQLERRM, 1, 200);

               INSERT INTO WCT_ERROR_LOG
                    VALUES ('INSERTING INTO AUDIT HEADER-2',
                            lv_User_Id,
                            'SAVE_QUOTE - ' || v_Error_Message,
                            SYSDATE);
         END;

         SELECT SUM (EXT_SELL_PRICE)
           INTO lv_Deal_Value
           FROM WCT_QUOTE_LINE
          WHERE QUOTE_ID = lv_Quote_Id;
      END IF;

      IF (lv_Status = v_Status_Failure)
      THEN
         -- IF error occurred while updating WCT_QUOTE_LINE table, ROLLBACK
         ROLLBACK;
      ELSE
         --Update Quote_Header table: change status from DRAFT to QUOTE
         IF (UPPER (i_Save_Type) = v_Status_Quote)
         THEN
            /*lv_Update_Quote_List := NULL;

            SELECT WCT_QUOTE_LINE_OBJECT (QL.LINE_ID,
                                          QL.QUOTE_ID,
                                          QL.LINE_NO,
                                          QL.REQUESTED_PART,
                                          QL.WHOLESALE_PART,
                                          QL.REQUESTED_QUANTITY,
                                          LT.AVAILABLE_QUANTITY,
                                          QL.BROKER_OFFER,
                                          QL.GLP,
                                          QL.SUGGESTED_PRICE,
                                          QL.EXT_SELL_PRICE,
                                          LT.LEAD_TIME,
                                          QL.ENCRYPTION_STATUS,
                                          LT.INVENTORY_DETAIL_NOTES,
                                          QL.DISCOUNT,
                                          QL.COMMENTS_L1,
                                          QL.COMMENTS_L2,
                                          QL.EOS_DATE,
                                          QL.APPROVAL_LEVEL,
                                          QL.APPROVAL_STATUS_L1,
                                          QL.APPROVAL_STATUS_L2,
                                          LT.ROW_ID,
                                          NULL,
                                          NULL)
              BULK COLLECT INTO lv_Update_Quote_List
              FROM WCT_QUOTE_LINE QL, WCT_LEAD_TIME LT
             WHERE     QL.QUOTE_ID = lv_Quote_Id
                   AND QL.LEAD_TIME = LT.LEAD_TIME_ID;*/

            -- fetch value for the property SKIP_APPROVAL_WORKFLOW from WCT_PROPERTIES
            BEGIN
               SELECT PROPERTY_VALUE
                 INTO lv_Skip_Approval_Workflow
                 FROM WCT_PROPERTIES
                WHERE PROPERTY_TYPE = 'SKIP_APPROVAL_WORKFLOW';
            EXCEPTION
               WHEN OTHERS
               THEN
                  lv_Skip_Approval_Workflow := v_Flag_Yes;
            END;

            FOR idx IN 1 .. lv_Update_Quote_List.COUNT ()
            LOOP
               IF (lv_Update_Quote_List (idx).ROW_ID = 1)
               THEN
                  lv_Requested_Part :=
                     lv_Update_Quote_List (idx).REQUESTED_PART;

                  -- Get Part Stripped name
                  --Commented by satbanda on 28-Mar-2017 for validate PID logic <Start>
                  /*lv_Product_Name_Stripped :=
                     VV_RSCM_UTIL.GET_STRIPPED_NAME (lv_Requested_Part);
                  lv_Product_Name_Stripped_WS :=
                     lv_Product_Name_Stripped || 'WS';

                  SELECT COUNT (*)
                    INTO lv_Conflicting_Part_Count
                    FROM WCT_CONFLICTING_PARTS
                   WHERE PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped;

                  IF (lv_Conflicting_Part_Count > 1)
                  THEN
                     SELECT PRODUCT_ID, PRODUCT_ID_WHOLESALE
                       INTO lv_Conflicting_Part_Id, lv_Conflicting_Part_WS
                       FROM WCT_CONFLICTING_PARTS
                      WHERE     1 = 1
                            AND (   PRODUCT_ID = lv_Requested_Part
                                 OR PRODUCT_ID_REFURBISHED =
                                       lv_Requested_Part
                                 OR PRODUCT_ID_WHOLESALE = lv_Requested_Part);
                  END IF;

                   GET_STATIC_PRICE_DETAILS (lv_Customer_Id,
                                            lv_Product_Name_Stripped,
                                            lv_Product_Name_Stripped_WS,
                                            lv_Conflicting_Part_Count,
                                            lv_Conflicting_Part_Id,
                                            lv_Conflicting_Part_WS,
                                            lv_Static_Price_Exists,
                                            lv_Static_Price);
                                            */
                    --Commented by satbanda on 20-Mar-2017 for validate PID logic <End>

                --Added by satbanda on 28-Mar-2017 for validate PID logic <Start>
                 VV_RSCM_UTIL.wct_validate_pid (lv_Requested_Part,
                                                lv_User_id,
                                                lv_Manufacture_Part,
                                                lv_spare_Part,
                                                lv_Wholesale_Part,
                                                lv_Refurbished_Part,
                                                lv_Part_Validity_Flag,
                                                lv_Error_Message);

                 GET_STATIC_PRICE_DETAILS ( lv_Customer_Id,
                                            lv_Manufacture_Part,
                                            lv_spare_Part,
                                            lv_Wholesale_Part,
                                            lv_Refurbished_Part,
                                            lv_Static_Price_Exists,
                                            lv_Static_Price);
                --Added by satbanda on 28-Mar-2017 for validate PID logic <End>

                  --lv_Eos_Date := lv_Update_Quote_List (idx).EOS_DATE;
                  lv_Discount := lv_Update_Quote_List (idx).DISCOUNT;

                  SELECT EOS_DATE
                    INTO lv_Eos_Date
                    FROM WCT_QUOTE_LINE
                   WHERE     1 = 1
                         AND QUOTE_ID = lv_Quote_Id
                         AND REQUESTED_PART =
                                lv_Update_Quote_List (idx).REQUESTED_PART;

                  IF (    (lv_Static_Price_Exists = v_Flag_Yes)
                      AND (lv_Static_Price =  lv_Update_Quote_List (idx).SUGGESTED_PRICE))
                  THEN
                     lv_Approval_Level := 0;
                     lv_Approval_Level_0 := TRUE;
                     lv_Approval_Status_L1 := v_Approval_Status_Approved;
                     lv_Approval_Status_L2 := v_Approval_Status_Approved;

                     lv_Comments_L1 := v_Empty_String;
                     lv_Comments_L2 := v_Empty_String;
                  ELSE
                     SELECT ADD_MONTHS (lv_Eos_Date, 12)
                       INTO lv_Eos_Date_Over
                       FROM DUAL;

                     --Added by satbanda for US136936 <Start>
                     BEGIN

                        SELECT PROPERTY_VALUE
                          INTO lv_dis_n_2_val2
                          FROM WCT_PROPERTIES
                         WHERE PROPERTY_TYPE = 'DISCOUNT_CATEGORY_N_2_LIMIT_2';

                        SELECT PROPERTY_VALUE
                          INTO lv_dis_n_2_val1
                          FROM WCT_PROPERTIES
                        WHERE PROPERTY_TYPE = 'DISCOUNT_CATEGORY_N_2_LIMIT_1';

                        SELECT PROPERTY_VALUE
                          INTO lv_dis_n_1_val2
                          FROM WCT_PROPERTIES
                        WHERE PROPERTY_TYPE = 'DISCOUNT_CATEGORY_N_1_LIMIT_2';

                        SELECT PROPERTY_VALUE
                          INTO lv_dis_n_1_val1
                          FROM WCT_PROPERTIES
                         WHERE PROPERTY_TYPE = 'DISCOUNT_CATEGORY_N_1_LIMIT_1';

                        SELECT PROPERTY_VALUE
                          INTO lv_dis_n_val2
                          FROM WCT_PROPERTIES
                         WHERE PROPERTY_TYPE = 'DISCOUNT_CATEGORY_N_LIMIT_2';

                        SELECT PROPERTY_VALUE
                          INTO lv_dis_n_val1
                          FROM WCT_PROPERTIES
                        WHERE PROPERTY_TYPE = 'DISCOUNT_CATEGORY_N_LIMIT_1';

                     EXCEPTION
                       WHEN OTHERS
                       THEN
                          v_Error_Message := SUBSTR (SQLERRM, 1, 200);

                           INSERT INTO WCT_ERROR_LOG
                                VALUES ('Fetching discount category Values',
                                        lv_User_Id,
                                        'SAVE_QUOTE - ' || v_Error_Message,
                                        SYSDATE);
                     END;
                    --Added by satbanda for US136936 <End>

                     -- EOS + 1 year
                     IF (lv_Eos_Date_Over < SYSDATE)
                     THEN
                        IF (lv_Discount >
                                lv_dis_n_2_val2)  --95) --Modified by satbanda for US136936
                        THEN
                           lv_Approval_Level := 2;
                           lv_Approval_Level_2 := TRUE;
                        ELSIF (lv_Discount > lv_dis_n_2_val1)  --90) --Modified by satbanda for US136936
                        THEN
                           lv_Approval_Level := 1;
                           lv_Approval_Level_1 := TRUE;
                        ELSE
                           lv_Approval_Level := 0;
                           lv_Approval_Level_0 := TRUE;
                        END IF;
                     -- EOS
                     ELSIF (lv_Eos_Date < SYSDATE)
                     THEN
                        IF (lv_Discount > lv_dis_n_1_val2)  --90) --Modified by satbanda for US136936
                        THEN
                           lv_Approval_Level := 2;
                           lv_Approval_Level_2 := TRUE;
                        ELSIF (lv_Discount > lv_dis_n_1_val1)  --85) --Modified by satbanda for US136936
                        THEN
                           lv_Approval_Level := 1;
                           lv_Approval_Level_1 := TRUE;
                        ELSE
                           lv_Approval_Level := 0;
                           lv_Approval_Level_0 := TRUE;
                        END IF;
                     -- GPL
                     ELSE
                        IF (lv_Discount > lv_dis_n_val2)  --85) --Modified by satbanda for US136936
                        THEN
                           lv_Approval_Level := 2;
                           lv_Approval_Level_2 := TRUE;
                        ELSIF (lv_Discount > lv_dis_n_val1)  --80) --Modified by satbanda for US136936
                        THEN
                           lv_Approval_Level := 1;
                           lv_Approval_Level_1 := TRUE;
                        ELSE
                           lv_Approval_Level := 0;
                           lv_Approval_Level_0 := TRUE;
                        END IF;
                     END IF;

                     -- if level 2 approval
                     IF (lv_Approval_Level = 2)
                     THEN
                        lv_Approval_Status_L1 := v_Approval_Status_Pending;
                        lv_Approval_Status_L2 := v_Approval_Status_Pending;
                     -- if level 1 approval
                     ELSIF (lv_Approval_Level = 1)
                     THEN
                        lv_Approval_Status_L1 := v_Approval_Status_Pending;
                        lv_Approval_Status_L2 := v_Approval_Status_Approved;

                        lv_Comments_L2 := v_Empty_String;
                     -- if level 0 approval
                     ELSE
                        lv_Approval_Status_L1 := v_Approval_Status_Approved;
                        lv_Approval_Status_L2 := v_Approval_Status_Approved;

                        lv_Comments_L1 := v_Empty_String;
                        lv_Comments_L2 := v_Empty_String;
                     END IF;
                  END IF;

                  -- auto approve the line if skip approval workflow is Y
                  IF (lv_Skip_Approval_Workflow = v_Flag_Yes)
                  THEN
                     lv_Approval_Level := 0;
                     lv_Approval_Level_0 := TRUE;
                     lv_Approval_Level_1 := FALSE;
                     lv_Approval_Level_2 := FALSE;
                     lv_Approval_Status_L1 := v_Approval_Status_Approved;
                     lv_Approval_Status_L2 := v_Approval_Status_Approved;

                     lv_Comments_L1 := v_Empty_String;
                     lv_Comments_L2 := v_Empty_String;
                  END IF;

                  UPDATE WCT_QUOTE_LINE
                     SET APPROVAL_LEVEL = lv_Approval_Level,
                         APPROVAL_STATUS_L1 = lv_Approval_Status_L1,
                         APPROVAL_STATUS_L2 = lv_Approval_Status_L2,
                         COMMENTS_L1 = lv_Comments_L1,
                         COMMENTS_L2 = lv_Comments_L2
                   WHERE     1 = 1
                         AND QUOTE_ID = lv_Quote_Id
                         AND REQUESTED_PART =
                                lv_Update_Quote_List (idx).REQUESTED_PART;
               END IF;
            END LOOP;

            -- if any line requires level 2 approval
            IF (lv_Approval_Level_2)
            THEN
               /*-- if any line is auto approved, set status as PARTIAL
               IF (lv_Approval_Level_0)
               THEN
                  UPDATE WCT_QUOTE_HEADER
                     SET STATUS = v_Status_Partial,
                         DEAL_VALUE = lv_Deal_Value,
                         APPROVAL_LEVEL = 2,
                         USER_NOTES = lv_User_Notes
                   WHERE QUOTE_ID = lv_Quote_Id;

                  lv_Quote_Status := v_Status_Partial;
               ELSE
                  --   set status as PENDING if no auto approved line
                  UPDATE WCT_QUOTE_HEADER
                     SET STATUS = v_Status_Pending,
                         DEAL_VALUE = lv_Deal_Value,
                         APPROVAL_LEVEL = 2,
                         USER_NOTES = lv_User_Notes
                   WHERE QUOTE_ID = lv_Quote_Id;

                  lv_Quote_Status := v_Status_Pending;
               END IF;*/

               --   set status as PENDING
               UPDATE WCT_QUOTE_HEADER
                  SET STATUS = v_Status_Pending,
                      DEAL_VALUE = lv_Deal_Value,
                      APPROVAL_LEVEL = 2,
                      USER_NOTES = lv_User_Notes
                WHERE QUOTE_ID = lv_Quote_Id;

               lv_Quote_Status := v_Status_Pending;
               lv_Status := v_Status_Pending;
               lv_Response_Message := 'Quote is pending for approval.';
            -- if any line requires level 1 approval
            ELSIF (lv_Approval_Level_1)
            THEN
               /*-- if any line is auto approved, set status as PARTIAL
               IF (lv_Approval_Level_0)
               THEN
                  UPDATE WCT_QUOTE_HEADER
                     SET STATUS = v_Status_Partial,
                         DEAL_VALUE = lv_Deal_Value,
                         APPROVAL_LEVEL = 1,
                         USER_NOTES = lv_User_Notes
                   WHERE QUOTE_ID = lv_Quote_Id;

                  lv_Quote_Status := v_Status_Partial;
               ELSE
                  --   set status as PENDING if no auto approved line
                  UPDATE WCT_QUOTE_HEADER
                     SET STATUS = v_Status_Pending,
                         DEAL_VALUE = lv_Deal_Value,
                         APPROVAL_LEVEL = 1,
                         USER_NOTES = lv_User_Notes
                   WHERE QUOTE_ID = lv_Quote_Id;

                  lv_Quote_Status := v_Status_Pending;
               END IF;*/

               --   set status as PENDING
               UPDATE WCT_QUOTE_HEADER
                  SET STATUS = v_Status_Pending,
                      DEAL_VALUE = lv_Deal_Value,
                      APPROVAL_LEVEL = 1,
                      USER_NOTES = lv_User_Notes
                WHERE QUOTE_ID = lv_Quote_Id;

               lv_Quote_Status := v_Status_Pending;
               lv_Status := v_Status_Pending;
               lv_Response_Message := 'Quote is pending for approval.';
            -- if all lines auto approved, set status as QUOTE
            ELSE
               UPDATE WCT_QUOTE_HEADER
                  SET STATUS = v_Status_Quote,
                      DEAL_VALUE = lv_Deal_Value,
                      APPROVAL_LEVEL = 0,
                      USER_NOTES = lv_User_Notes
                WHERE QUOTE_ID = lv_Quote_Id;

               lv_Quote_Status := v_Status_Quote;

               lv_Status := v_Status_Success;
               lv_Response_Message := 'Quote generated Successfully.';
            END IF;


            -- Email functionality for Approval Workflow
            BEGIN
               -- quote is in pending or partial status
               IF (   (lv_Quote_Status = v_Status_Pending)
                   OR (lv_Quote_Status = v_Status_Partial))
               THEN
                  BEGIN
                     -- Generate mail content
                     GENERATE_EMAIL_CONTENT (lv_Quote_Id,
                                             v_Status_Pending,
                                             1,
                                             v_To_List,
                                             v_Cc_List,
                                             lv_From,
                                             lv_Subject,
                                             lv_Html_Msg);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_Error_Message := NULL;
                        v_Error_Message := SUBSTR (SQLERRM, 1, 200);

                        INSERT INTO WCT_ERROR_LOG
                                VALUES (
                                          'SAVE_QUOTE',
                                          lv_User_Id,
                                             'GENERATE_EMAIL_CONTENT - '
                                          || v_Error_Message,
                                          SYSDATE);

                        COMMIT;
                  END;

                  BEGIN
                     -- send email
                     EMAIL_UTIL (v_To_List,
                                 v_Cc_List,
                                 lv_From,
                                 lv_Subject,
                                 lv_Html_Msg);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_Error_Message := NULL;
                        v_Error_Message := SUBSTR (SQLERRM, 1, 200);

                        INSERT INTO WCT_ERROR_LOG
                             VALUES ('SAVE_QUOTE',
                                     lv_User_Id,
                                     'EMAIL_UTIL - ' || v_Error_Message,
                                     SYSDATE);

                        COMMIT;
                  END;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  --LOG EXCEPTION
                  v_Error_Message := NULL;
                  v_Error_Message := SUBSTR (SQLERRM, 1, 200);

                  INSERT INTO WCT_ERROR_LOG
                       VALUES ('SAVE_QUOTE',
                               lv_User_Id,
                               'EMAIL GENERATION - ' || v_Error_Message,
                               SYSDATE);

                  COMMIT;
            END;


            VIEW_QUOTE_DETAILS (lv_Quote_Id,
                                v_View_Type_Export,
                                lv_View_Quote_Details_Object);

            lv_Return_Quote_List :=
               lv_View_Quote_Details_Object.QUOTE_LINE_LIST;
         --insert INTO nar(seq) values (6); COMMIT;
         ELSE
            UPDATE WCT_QUOTE_HEADER
               SET STATUS = v_Status_Draft,
                   DEAL_VALUE = lv_Deal_Value,
                   USER_NOTES = lv_User_Notes
             WHERE QUOTE_ID = lv_Quote_Id;

            lv_Status := v_Status_Success;
            lv_Response_Message :=
               'Draft saved Successfully. Download it from Retrieve Quote Tab.';
         -- insert INTO nar(seq) values (7); COMMIT;
         END IF;
      --insert INTO nar(seq) values (8); COMMIT;
      END IF;

      --insert INTO nar(seq,quote_id,issue) values (5,'Save quote=> '||lv_Quote_Id,
      --lv_User_Id||' <lv_User_Id$lv_Customer_Id> '||lv_Customer_Id||'   <<lv_Last_Updated_Date=> '||lv_Last_Updated_Date); commit;
      v_Save_Quote_Response_Object :=
         WCT_SAVE_QUOTE_RESPONSE_OBJECT (lv_Status,
                                         lv_Response_Message,
                                         lv_Last_Updated_Date,
                                         lv_Quote_Id,
                                         lv_Return_Quote_List);

      o_Save_Quote_Response_Object := v_Save_Quote_Response_Object;
   END;
--
--   /*PROCEDURE TO COMPUTE RESERVATIONS*/
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
--      o_Reservation_Total_WS        OUT NUMBER)
--   IS
--      lv_Requested_Part             VARCHAR2 (25 BYTE);
--      lv_Product_Name_Stripped      VARCHAR2 (25 BYTE);
--      lv_User_Id                    VARCHAR2 (12 BYTE);
--      lv_Product_Name_Stripped_WS   VARCHAR2 (25 BYTE);
--      lv_Reservation_RF_Quotes      NUMBER;
--      lv_Reservation_RF_Backlog     NUMBER;
--      lv_Reservation_WS_Order       NUMBER;
--      lv_Reservation_Total          NUMBER;
--      lv_Reservation_Total_RF       NUMBER;
--      lv_Reservation_Total_WS       NUMBER;
--      lv_Region                     VARCHAR2 (4 BYTE);
--      lv_Conflicting_Part_Count     NUMBER;
--      lv_Conflicting_Part_Id        VARCHAR2 (50);
--      lv_Conflicting_Part_WS        VARCHAR2 (50);
--      IS_RL_AVAILABLE               NUMBER;
--   BEGIN
--      lv_Requested_Part := i_Part_Number;
--      lv_Product_Name_Stripped := i_Product_Name_Stripped;
--
--      --lv_Product_Name_Stripped_WS := lv_Product_Name_Stripped || 'WS';
--
--
--      IF (lv_Product_Name_Stripped LIKE '%RL')
--      THEN
--         lv_Product_Name_Stripped_WS :=
--               SUBSTR (lv_Product_Name_Stripped,
--                       1,
--                       LENGTH (lv_Product_Name_Stripped) - 2)
--            || 'WS';
--      ELSIF (lv_Product_Name_Stripped NOT LIKE '%WS')
--      THEN
--         lv_Product_Name_Stripped_WS := lv_Product_Name_Stripped || 'WS';
--      ELSIF (lv_Product_Name_Stripped LIKE '%WS')
--      THEN
--         lv_Product_Name_Stripped_WS := lv_Product_Name_Stripped;
--      END IF;
--
--      lv_User_Id := i_User_Id;
--      lv_Region := i_Region;
--      lv_Conflicting_Part_Count := i_Conflicting_Part_Count;
--      lv_Conflicting_Part_Id := i_Conflicting_Part_Id;
--      lv_Conflicting_Part_WS := i_Conflicting_Part_WS;
--
--      --Step 2.0 - Compute RF Quotes
--      BEGIN
--         IF (lv_Conflicting_Part_Count > 1)
--         THEN
--            SELECT ABS (NVL (SUM (ADDITIONAL_RESERVATIONS), 0))
--              INTO lv_Reservation_RF_Quotes
--              FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--             WHERE     1 = 1
--                   AND (   PART_NUMBER = lv_Conflicting_Part_Id
--                        OR PART_NUMBER = lv_Conflicting_Part_WS)
--                   AND PRODUCT_FAMILY NOT LIKE '%WHLSALE%'
--                   AND REGION = lv_Region;
--         ELSE
--            SELECT COUNT (*)
--              INTO IS_RL_AVAILABLE
--              FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW
--             WHERE PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped;
--
--            IF (lv_Product_Name_Stripped LIKE '%RL' AND IS_RL_AVAILABLE > 0)
--            THEN
--               SELECT ABS (NVL (SUM (ADDITIONAL_RESERVATIONS), 0))
--                 INTO lv_Reservation_RF_Quotes
--                 FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                WHERE     PRODUCT_NAME_STRIPPED IN (lv_Product_Name_Stripped,
--                                                    -- AND PRODUCT_NAME_STRIPPED =
--                                                    SUBSTR (
--                                                       lv_Product_Name_Stripped,
--                                                       1,
--                                                         LENGTH (
--                                                            lv_Product_Name_Stripped)
--                                                       - 2))
--                      AND PRODUCT_FAMILY NOT LIKE '%WHLSALE%'
--                      AND REGION = lv_Region;
--            ELSE
--               SELECT ABS (NVL (SUM (ADDITIONAL_RESERVATIONS), 0))
--                 INTO lv_Reservation_RF_Quotes
--                 FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                WHERE     PRODUCT_NAME_STRIPPED IN (lv_Product_Name_Stripped,
--                                                       lv_Product_Name_Stripped
--                                                    || 'RL')
--                      AND PRODUCT_FAMILY NOT LIKE '%WHLSALE%'
--                      AND REGION = lv_Region;
--            END IF;
--         END IF;
--      EXCEPTION
--         WHEN NO_DATA_FOUND
--         THEN
--            --LOG EXCEPTION
--            INSERT INTO WCT_ERROR_LOG
--                 VALUES (UPPER (lv_Requested_Part),
--                         lv_User_Id,
--                         'COMPUTE_RESERVATIONS - Step 2.0 - No data found',
--                         SYSDATE);
--         WHEN OTHERS
--         THEN
--            --LOG EXCEPTION
--            v_Error_Message := NULL;
--            v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--            INSERT INTO WCT_ERROR_LOG
--                    VALUES (
--                              UPPER (lv_Requested_Part),
--                              lv_User_Id,
--                                 'COMPUTE_RESERVATIONS - Step 2.0 - '
--                              || v_Error_Message,
--                              SYSDATE);
--      END;
--
--      --Step 3.0 Compute RF Backlog
--      BEGIN
--         IF (lv_Conflicting_Part_Count > 1)
--         THEN
--            SELECT ABS (NVL (SUM (QTY_RESERVED), 0))
--              INTO lv_Reservation_RF_Backlog
--              FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--             WHERE     1 = 1
--                   AND (   PART_NUMBER = lv_Conflicting_Part_Id
--                        OR PART_NUMBER = lv_Conflicting_Part_WS)
--                   AND PRODUCT_FAMILY NOT LIKE '%WHLSALE%'
--                   AND REGION = lv_Region;
--         ELSE
--            SELECT COUNT (*)
--              INTO IS_RL_AVAILABLE
--              FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW
--             WHERE PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped;
--
--            IF (lv_Product_Name_Stripped LIKE '%RL' AND IS_RL_AVAILABLE > 0)
--            THEN
--               SELECT ABS (NVL (SUM (ADDITIONAL_RESERVATIONS), 0))
--                 INTO lv_Reservation_RF_Quotes
--                 FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                WHERE     PRODUCT_NAME_STRIPPED IN (lv_Product_Name_Stripped,
--                                                    -- AND PRODUCT_NAME_STRIPPED =
--                                                    SUBSTR (
--                                                       lv_Product_Name_Stripped,
--                                                       1,
--                                                         LENGTH (
--                                                            lv_Product_Name_Stripped)
--                                                       - 2))
--                      AND PRODUCT_FAMILY NOT LIKE '%WHLSALE%'
--                      AND REGION = lv_Region;
--
--               SELECT ABS (NVL (SUM (QTY_RESERVED), 0))
--                 INTO lv_Reservation_RF_Backlog
--                 FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                WHERE     PRODUCT_NAME_STRIPPED IN (lv_Product_Name_Stripped,
--                                                    -- AND PRODUCT_NAME_STRIPPED =
--                                                    SUBSTR (
--                                                       lv_Product_Name_Stripped,
--                                                       1,
--                                                         LENGTH (
--                                                            lv_Product_Name_Stripped)
--                                                       - 2))
--                      AND PRODUCT_FAMILY NOT LIKE '%WHLSALE%'
--                      AND REGION = lv_Region;
--            ELSE
--               SELECT ABS (NVL (SUM (ADDITIONAL_RESERVATIONS), 0))
--                 INTO lv_Reservation_RF_Quotes
--                 FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                WHERE     PRODUCT_NAME_STRIPPED IN (lv_Product_Name_Stripped,
--                                                       lv_Product_Name_Stripped
--                                                    || 'RL')
--                      AND PRODUCT_FAMILY NOT LIKE '%WHLSALE%'
--                      AND REGION = lv_Region;
--
--               SELECT ABS (NVL (SUM (QTY_RESERVED), 0))
--                 INTO lv_Reservation_RF_Backlog
--                 FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                WHERE     PRODUCT_NAME_STRIPPED IN (lv_Product_Name_Stripped,
--                                                       lv_Product_Name_Stripped
--                                                    || 'RL')
--                      AND PRODUCT_FAMILY NOT LIKE '%WHLSALE%'
--                      AND REGION = lv_Region;
--            END IF;
--         END IF;
--      EXCEPTION
--         WHEN NO_DATA_FOUND
--         THEN
--            --LOG EXCEPTION
--            INSERT INTO WCT_ERROR_LOG
--                 VALUES (UPPER (lv_Requested_Part),
--                         lv_User_Id,
--                         'COMPUTE_RESERVATIONS - Step 3.0 - No data found',
--                         SYSDATE);
--         WHEN OTHERS
--         THEN
--            --LOG EXCEPTION
--            v_Error_Message := NULL;
--            v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--            INSERT INTO WCT_ERROR_LOG
--                    VALUES (
--                              UPPER (lv_Requested_Part),
--                              lv_User_Id,
--                                 'COMPUTE_RESERVATIONS - Step 3.0 - '
--                              || v_Error_Message,
--                              SYSDATE);
--      END;
--
--      --Step 4.0 Compute WS Orders
--      BEGIN
--         IF (lv_Conflicting_Part_Count > 1)
--         THEN
--            SELECT ABS (NVL (SUM (QTY_RESERVED), 0))
--              INTO lv_Reservation_WS_Order
--              FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--             WHERE     1 = 1
--                   AND (   PART_NUMBER = lv_Conflicting_Part_Id
--                        OR PART_NUMBER = lv_Conflicting_Part_WS)
--                   AND PRODUCT_FAMILY LIKE '%WHLSALE%'
--                   AND REGION = lv_Region;
--         ELSE
--            SELECT ABS (NVL (SUM (QTY_RESERVED), 0))
--              INTO lv_Reservation_WS_Order
--              FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--             WHERE     (   PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped
--                        OR PRODUCT_NAME_STRIPPED =
--                              lv_Product_Name_Stripped_WS)
--                   AND PRODUCT_FAMILY LIKE '%WHLSALE%'
--                   AND REGION = lv_Region;
--         END IF;
--      EXCEPTION
--         WHEN NO_DATA_FOUND
--         THEN
--            --LOG EXCEPTION
--            INSERT INTO WCT_ERROR_LOG
--                 VALUES (UPPER (lv_Requested_Part),
--                         lv_User_Id,
--                         'COMPUTE_RESERVATIONS - Step 4.0 - No data found',
--                         SYSDATE);
--         WHEN OTHERS
--         THEN
--            --LOG EXCEPTION
--            v_Error_Message := NULL;
--            v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--            INSERT INTO WCT_ERROR_LOG
--                    VALUES (
--                              UPPER (lv_Requested_Part),
--                              lv_User_Id,
--                                 'COMPUTE_RESERVATIONS - Step 4.0 - '
--                              || v_Error_Message,
--                              SYSDATE);
--      END;
--
--      /*
--      -- Intentionally Making lv_Reservation_WS_Order:= 0. So that system will fetch the Backlog from VV_ADM_RSVN_BACKLOG_TMP_T.
--      -- Short term fix to get the correct backlog until 2hourly job is fixed.
--
--      lv_Reservation_WS_Order := 0;
--
--      -- STEP 4.0.1. IF WS RESERVATION IS 0 THEN CHECK THE VALUE IN VV_ADM_RSVN_BACKLOG_TMP_T table
--      IF lv_Reservation_WS_Order = 0
--      THEN
--         BEGIN
--            SELECT ABS (NVL (SUM (QUANTITY_TO_SHIP), 0))
--              INTO lv_Reservation_WS_Order
--              FROM VV_ADM_RSVN_BACKLOG_TMP_T
--             WHERE REGEXP_REPLACE (PRODUCT_ID, '[-=/ ]', '') =
--                      lv_Product_Name_Stripped_WS
--                   AND UPPER (ORDER_TYPE) LIKE 'WHOLESALE';
--         EXCEPTION
--            WHEN NO_DATA_FOUND
--            THEN
--               --LOG EXCEPTION
--               INSERT INTO WCT_ERROR_LOG
--                    VALUES (
--                              UPPER (lv_Requested_Part),
--                              lv_User_Id,
--                              'COMPUTE_RESERVATIONS - Step 4.0.1 - No data found',
--                              SYSDATE);
--            WHEN OTHERS
--            THEN
--               --LOG EXCEPTION
--               v_Error_Message := NULL;
--               v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--               INSERT INTO WCT_ERROR_LOG
--                    VALUES (
--                              UPPER (lv_Requested_Part),
--                              lv_User_Id,
--                              'COMPUTE_RESERVATIONS - Step 4.0.1 - '
--                              || v_Error_Message,
--                              SYSDATE);
--         END;
--      END IF;
--      */
--
--      -- Start of code changes done by Infosys for April 2014 release -- ruchhabr
--      -- Setting RF backlog to 0 since we have to exclude them
--      /*lv_Reservation_RF_Quotes := 0;*/
--      -- End of code changes done by Infosys for April 2014 release -- ruchhabr
--
--      --Compute Total reservations
--      lv_Reservation_Total :=
--           lv_Reservation_RF_Quotes
--         + lv_Reservation_RF_Backlog
--         + lv_Reservation_WS_Order;
--
--
--      lv_Reservation_Total_RF :=
--         lv_Reservation_RF_Quotes + lv_Reservation_RF_Backlog;
--      lv_Reservation_Total_WS := lv_Reservation_WS_Order;
--
--      --o_FG_Only := lv_FG_Only;
--      o_Reservation_RF_Quotes := lv_Reservation_RF_Quotes;
--      o_Reservation_RF_Backlog := lv_Reservation_RF_Backlog;
--      o_Reservation_WS_Order := lv_Reservation_WS_Order;
--      o_Reservation_Total := lv_Reservation_Total;
--      o_Reservation_Total_RF := lv_Reservation_Total_RF;
--      o_Reservation_Total_WS := lv_Reservation_Total_WS;
--   END;

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
--      o_Quantity_In_Transit_2            OUT NUMBER)
--   IS
--      v_Inventory_Detail_List_Local    WCT_INVENTORY_DETAIL_LIST;
--      v_Inventory_Detail_List_Frn      WCT_INVENTORY_DETAIL_LIST;
--      v_Final_Inventory_Return_List    WCT_INVENTORY_DETAIL_LIST;
--      v_Final_Inventory_List_FGI       WCT_INVENTORY_DETAIL_LIST;
--      v_Final_Inventory_List_WS        WCT_INVENTORY_DETAIL_LIST;
--      v_Final_Inventory_List_POE       WCT_INVENTORY_DETAIL_LIST;
--
--      v_Inventory_Detail_List_Lcl_FG   WCT_INVENTORY_DETAIL_LIST;
--      v_Inventory_Detail_List_Frn_FG   WCT_INVENTORY_DETAIL_LIST;
--      v_Inventory_Detail_List_L        WCT_INVENTORY_DETAIL_LIST;
--      v_Inventory_Detail_List_F        WCT_INVENTORY_DETAIL_LIST;
--
--      lv_Inventory_WS_FGI_Count_lcl    NUMBER;
--      lv_Inventory_WS_FGI_Count_Frn    NUMBER;
--
--      lv_Requested_Part                VARCHAR2 (25 BYTE);
--      lv_Product_Name_Stripped         VARCHAR2 (25 BYTE);
--      lv_Product_Name_Stripped_WS      VARCHAR2 (25 BYTE);
--      lv_Wholesale_Part                VARCHAR2 (25 BYTE);
--      lv_User_Id                       VARCHAR2 (12 BYTE);
--
--      lv_Reservation_RF_Total_Lcl      NUMBER;
--      lv_Reservation_WS_Total_Lcl      NUMBER;
--      lv_Reservation_RF_Total_Frn      NUMBER;
--      lv_Reservation_WS_Total_Frn      NUMBER;
--
--      lv_Requested_Qty                 NUMBER;
--      lv_Available_Quantity            NUMBER;
--
--      lv_Location                      VARCHAR2 (100);
--      lv_Yield_Factor_Lcl              NUMBER;
--      lv_Yield_Factor_Frn              NUMBER;
--
--      lv_Available_Quantity_RF         NUMBER;
--      lv_Available_Quantity_FG         NUMBER;
--      lv_Available_Quantity_WS         NUMBER;
--      lv_Available_Quantity_POE        NUMBER;
--      lv_Available_Quantity_RF_Frn     NUMBER;
--
--      lv_Final_Inventory_FGI_Count     NUMBER;
--      lv_Final_Inventory_WS_Count      NUMBER;
--      lv_Final_Inventory_POE_Count     NUMBER;
--      lv_Final_Inventory_Count         NUMBER;
--
--      lv_RF_Reduce_From_POE_TMP        NUMBER;
--      lv_RF_Reduce_From_POE            NUMBER;
--      lv_WS_reduce_From_POE            NUMBER;
--      lv_Net_Available_POE             NUMBER;
--      lv_Lead_Time_1                   VARCHAR2 (5) := v_Empty_String;
--      lv_Lead_Time_2                   VARCHAR2 (5) := v_Empty_String;
--      lv_Available_Quantity_Net_1      NUMBER := 0;
--      lv_Available_Quantity_Net_2      NUMBER := 0;
--
--      lv_Z_Location                    VARCHAR2 (3);
--      lv_Inventory_Detail_Notes_1      VARCHAR2 (4000) := v_Empty_String;
--      lv_Inventory_Detail_Notes_2      VARCHAR2 (4000) := v_Empty_String;
--      lv_Inventory_Detail_Notes_O_H    VARCHAR2 (4000) := v_Empty_String;
--      lv_Inventory_Detail_Notes_I_T    VARCHAR2 (4000) := v_Empty_String;
--
--      lv_Available_Quantity_FG_Net     NUMBER := 0;
--      lv_Available_Quantity_WS_Net     NUMBER := 0;
--      lv_Available_Quantity_POE_Net    NUMBER := 0;
--
--      lv_Conflicting_Part_Count        NUMBER;
--      lv_Conflicting_Part_Id           VARCHAR2 (50);
--      lv_Conflicting_Part_WS           VARCHAR2 (50);
--
--      lv_Total_Available               NUMBER := 0;
--      lv_Available_Qty_On_Hand         NUMBER := 0;
--      lv_Available_Qty_In_Transit      NUMBER := 0;
--      lv_Available_QtyOnHand_Net       NUMBER := 0;
--      lv_Available_QtyInTransit_Net    NUMBER := 0;
--
--      lv_Available_Qty_O_H_WS_Net      NUMBER := 0;
--      lv_Available_Qty_I_T_WS_Net      NUMBER := 0;
--      lv_Available_Qty_O_H_POE_Net     NUMBER := 0;
--      lv_Available_Qty_I_T_POE_Net     NUMBER := 0;
--
--      lv_Lead_Time_Count               NUMBER := 1;
--
--      lv_Quantity_On_Hand_1            NUMBER := 0;
--      lv_Quantity_In_Transit_1         NUMBER := 0;
--      lv_Quantity_On_Hand_2            NUMBER := 0;
--      lv_Quantity_In_Transit_2         NUMBER := 0;
--      IS_RL_AVAILABLE                  NUMBER;                      --ADDED RL
--   BEGIN
--      BEGIN
--         lv_Requested_Part := i_Part_Number;
--         lv_Product_Name_Stripped := i_Product_Name_Stripped;
--
--         --  lv_Product_Name_Stripped_WS := lv_Product_Name_Stripped || 'WS';
--
--         IF (lv_Product_Name_Stripped LIKE '%RL')
--         THEN
--            lv_Product_Name_Stripped_WS :=
--                  SUBSTR (lv_Product_Name_Stripped,
--                          1,
--                          LENGTH (lv_Product_Name_Stripped) - 2)
--               || 'WS';
--         ELSIF (lv_Product_Name_Stripped NOT LIKE '%WS')
--         THEN
--            lv_Product_Name_Stripped_WS := lv_Product_Name_Stripped || 'WS';
--         ELSIF (lv_Product_Name_Stripped LIKE '%WS')
--         THEN
--            lv_Product_Name_Stripped_WS := lv_Product_Name_Stripped;
--         END IF;
--
--         lv_Wholesale_Part := i_Wholesale_Part;
--         lv_User_Id := i_User_Id;
--         lv_Requested_Qty := i_Requested_Qty;
--
--         lv_Reservation_RF_Total_Lcl := i_Reservation_RF_Total_Lcl;
--         lv_Reservation_WS_Total_Lcl := i_Reservation_WS_Total_Lcl;
--         lv_Reservation_RF_Total_Frn := i_Reservation_RF_Total_Frn;
--         lv_Reservation_WS_Total_Frn := i_Reservation_WS_Total_Frn;
--
--         lv_Available_Quantity := 0;
--
--         lv_Conflicting_Part_Count := i_Conflicting_Part_Count;
--         lv_Conflicting_Part_Id := i_Conflicting_Part_Id;
--         lv_Conflicting_Part_WS := i_Conflicting_Part_WS;
--
--         v_Inventory_Detail_List_Local := WCT_INVENTORY_DETAIL_LIST ();
--         v_Inventory_Detail_List_Frn := WCT_INVENTORY_DETAIL_LIST ();
--
--         v_Inventory_Detail_List_Lcl_FG := WCT_INVENTORY_DETAIL_LIST ();
--         v_Inventory_Detail_List_Frn_FG := WCT_INVENTORY_DETAIL_LIST ();
--         v_Inventory_Detail_List_L := WCT_INVENTORY_DETAIL_LIST ();
--         v_Inventory_Detail_List_F := WCT_INVENTORY_DETAIL_LIST ();
--         lv_Inventory_WS_FGI_Count_lcl := 0;
--         lv_Inventory_WS_FGI_Count_Frn := 0;
--
--         lv_Final_Inventory_FGI_Count := 0;
--         lv_Final_Inventory_WS_Count := 0;
--         lv_Final_Inventory_POE_Count := 0;
--
--         v_Final_Inventory_List_FGI := WCT_INVENTORY_DETAIL_LIST ();
--         v_Final_Inventory_List_WS := WCT_INVENTORY_DETAIL_LIST ();
--         v_Final_Inventory_List_POE := WCT_INVENTORY_DETAIL_LIST ();
--
--         lv_Final_Inventory_Count := 0;
--         v_Final_Inventory_Return_List := WCT_INVENTORY_DETAIL_LIST ();
--
--         BEGIN
--            -- Step 0 Compute sum of Retail parts available
--            lv_Available_Quantity_RF := 0;
--
--            IF (lv_Conflicting_Part_Count > 1)
--            THEN
--               -- Start of code changes done by Infosys for April 2014 release -- ruchhabr
--               SELECT NVL (SUM (QTY_ON_HAND + QTY_IN_TRANSIT), 0)
--                 INTO lv_Available_Quantity_RF
--                 FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                WHERE     1 = 1
--                      AND (   PART_NUMBER = lv_Conflicting_Part_Id
--                           OR PART_NUMBER = lv_Conflicting_Part_WS)
--                      AND (    LOCATION IN (SELECT DESTINATION_SUBINVENTORY
--                                              FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                                             WHERE     1 = 1
--                                                   AND (PROGRAM_TYPE = 0) -- FOR 0= Retail
--                                                   AND IS_NETTABLE = 1
--                                                   AND IS_ENABLE = 1
--                                                   AND INVENTORY_TYPE <> 2) -- changes by karusing to exclude WIP location
--                           AND product_family <> 'WHLSALE')
--                      AND REGION = i_Region_Local;
--
--               SELECT NVL (SUM (QTY_ON_HAND + QTY_IN_TRANSIT), 0)
--                 INTO lv_Available_Quantity_RF_Frn
--                 FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                WHERE     1 = 1
--                      AND (   PART_NUMBER = lv_Conflicting_Part_Id
--                           OR PART_NUMBER = lv_Conflicting_Part_WS)
--                      AND (    LOCATION IN (SELECT DESTINATION_SUBINVENTORY
--                                              FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                                             WHERE     1 = 1
--                                                   AND (PROGRAM_TYPE = 0) -- FOR 0= Retail
--                                                   AND IS_NETTABLE = 1
--                                                   AND IS_ENABLE = 1
--                                                   AND INVENTORY_TYPE <> 2) -- changes by karusing to exclude WIP location
--                           AND product_family <> 'WHLSALE')
--                      AND REGION = i_Region_Foreign;
--
--               -- Step 1.0 Compute All Netable Inventory Sub Locations and respective available quantity
--
--               /*SELECT WCT_INVENTORY_DETAIL_OBJECT (SITE,
--                                                     LOCATION,
--                                                     QTY_ON_HAND,
--                                                     QTY_IN_TRANSIT,
--                                                     '100',
--                                                     QTY_ON_HAND + QTY_IN_TRANSIT,
--                                                     NULL) -- NULL FOR LOCATION TYPE
--                   BULK COLLECT INTO v_Inventory_Detail_List_Local
--                   FROM RSCM_ML_C3_INV_MV
--                  WHERE     1 = 1
--                        AND (   PART_NUMBER = lv_Conflicting_Part_Id
--                             OR PART_NUMBER = lv_Conflicting_Part_WS)
--                        AND LOCATION IN
--                               (SELECT DESTINATION_SUBINVENTORY
--                                  FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                                 WHERE     1 = 1
--                                       AND (PROGRAM_TYPE = 1 OR PROGRAM_TYPE = 2) -- FOR 1= WHOLESALE, 2= DGI locations
--                                       AND IS_NETTABLE = 1
--                                       AND IS_ENABLE = 1)
--                        --AND LOCATION <> 'FG' -- excluding FG location as items in this location are from ML
--                        AND LOCATION NOT IN ('FG', 'WS-FGSLD') -- excluding FG and WS-FGSLD location as items in this location are from ML
--                        AND SUBSTR (SITE, 1, 3) IN
--                               (SELECT ZLOC
--                                  FROM VV_ADM_ZLOCATION_TABLE
--                                 WHERE REGION_NAME = i_Region_Local)
--               ORDER BY LOCATION DESC;*/
--
--               /*SELECT WCT_INVENTORY_DETAIL_OBJECT (SITE,
--                                                   LOCATION,
--                                                   QTY_ON_HAND,
--                                                   QTY_IN_TRANSIT,
--                                                   NULL, -- NULL FOR YIELD_FACTOR
--                                                   TOTAL_AVAILABLE,
--                                                   NULL, -- NULL FOR LOCATION TYPE
--                                                   v_Flag_No) -- NO FOR SELECTED
--                 BULK COLLECT INTO v_Inventory_Detail_List_Local
--                 FROM (  SELECT SITE,
--                                LOCATION,
--                                SUM (QTY_ON_HAND) AS QTY_ON_HAND,
--                                SUM (QTY_IN_TRANSIT) AS QTY_IN_TRANSIT,
--                                SUM (QTY_ON_HAND + QTY_IN_TRANSIT)
--                                   AS TOTAL_AVAILABLE
--                           FROM RSCM_ML_C3_INV_MV
--                          WHERE     1 = 1
--                                AND (   PART_NUMBER = lv_Conflicting_Part_Id
--                                     OR PART_NUMBER = lv_Conflicting_Part_WS)
--                                AND LOCATION IN
--                                       (SELECT DESTINATION_SUBINVENTORY
--                                          FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                                         WHERE     1 = 1
--                                               AND (   PROGRAM_TYPE = 1
--                                                    OR PROGRAM_TYPE = 2) -- FOR 1= WHOLESALE, 2= DGI locations
--                                               AND IS_NETTABLE = 1
--                                               AND IS_ENABLE = 1)
--                                --AND LOCATION <> 'FG' -- excluding FG location as items in this location are from ML
--                                AND LOCATION NOT IN ('FG', 'WS-FGSLD') -- excluding FG and WS-FGSLD location as items in this location are from ML
--                                AND SUBSTR (SITE, 1, 3) IN
--                                       (SELECT ZLOC
--                                          FROM VV_ADM_ZLOCATION_TABLE
--                                         WHERE REGION_NAME = i_Region_Local)
--                       GROUP BY SITE, LOCATION
--                       ORDER BY SITE);*/
--
--               SELECT WCT_INVENTORY_DETAIL_OBJECT (
--                         SITE,
--                         LOC,
--                         QTY_ON_HAND,
--                         QTY_IN_TRANSIT,
--                         CASE
--                            WHEN (NVL (yield, 80) = 0) THEN 80
--                            ELSE NVL (yield, 80)
--                         END,                         -- NULL FOR YIELD_FACTOR
--                         NULL,                     -- NULL FOR TOTAL_AVAILABLE
--                         NULL,                       -- NULL FOR LOCATION TYPE
--                         v_Flag_No)                         -- NO FOR SELECTED
--                 BULK COLLECT INTO v_Inventory_Detail_List_L
--                 FROM (  SELECT SITE,
--                                MV.LOCATION LOC,
--                                QTY_ON_HAND,
--                                QTY_IN_TRANSIT,
--                                CASE
--                                   WHEN SCM.DESTINATION_SUBINVENTORY IS NULL
--                                   THEN
--                                      100
--                                   ELSE
--                                      PM_PROD.rm_yield
--                                END
--                                   AS yield
--                           FROM (  SELECT PRODUCT_NAME_STRIPPED,
--                                          SITE,
--                                          REGION,
--                                          LOCATION,
--                                          SUM (QTY_ON_HAND) QTY_ON_HAND,
--                                          0 QTY_IN_TRANSIT,
--                                          NULL TOTAL_AVAILABLE
--                                     FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                                    WHERE     1 = 1
--                                          AND (   PART_NUMBER =
--                                                     lv_Conflicting_Part_Id
--                                               OR PART_NUMBER =
--                                                     lv_Conflicting_Part_WS)
--                                 GROUP BY PRODUCT_NAME_STRIPPED,
--                                          SITE,
--                                          REGION,
--                                          LOCATION
--                                 UNION
--                                   SELECT PRODUCT_NAME_STRIPPED,
--                                          SITE,
--                                          REGION,
--                                          LOCATION,
--                                          0 QTY_ON_HAND,
--                                          SUM (QTY_IN_TRANSIT),
--                                          NULL TOTAL_AVAILABLE
--                                     FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                                    WHERE     1 = 1
--                                          AND (   PART_NUMBER =
--                                                     lv_Conflicting_Part_Id
--                                               OR PART_NUMBER =
--                                                     lv_Conflicting_Part_WS)
--                                 GROUP BY PRODUCT_NAME_STRIPPED,
--                                          SITE,
--                                          REGION,
--                                          LOCATION) MV
--                                LEFT OUTER JOIN
--                                VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
--                                   ON     PM_PROD.product_name_stripped =
--                                             MV.product_name_stripped
--                                      AND PM_PROD.REGION_NAME = MV.REGION
--                                LEFT OUTER JOIN
--                                VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP SCM
--                                   ON     MV.LOCATION =
--                                             SCM.DESTINATION_SUBINVENTORY
--                                      AND SCM.YIELD_WS = 'YES'
--                          WHERE     1 = 1
--                                AND (QTY_ON_HAND > 0 OR QTY_IN_TRANSIT > 0)
--                                AND MV.LOCATION IN (SELECT DESTINATION_SUBINVENTORY
--                                                      FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                                                     WHERE     1 = 1
--                                                           AND (   PROGRAM_TYPE =
--                                                                      1
--                                                                OR PROGRAM_TYPE =
--                                                                      2) -- FOR 1= WHOLESALE, 2= DGI locations
--                                                           AND IS_NETTABLE = 1
--                                                           AND IS_ENABLE = 1
--                                                           AND INVENTORY_TYPE <>
--                                                                  2) -- changes by karusing to exclude WIP location)
--                                AND MV.LOCATION NOT IN ('FG',
--                                                        'WS-FGSLD',
--                                                        'RF-W-RHS',
--                                                        'RF-W-OEM',
--                                                        'RF-WIP',
--                                                        'WS-WIP') -- excluding FG and WS-FGSLD location, WIP location  as items in this location are from ML
--                                AND SUBSTR (SITE, 1, 3) IN (SELECT ZLOC
--                                                              FROM VAVNI_CISCO_RSCM_ADMIN.VV_ADM_ZLOCATION_TABLE
--                                                             WHERE REGION_NAME =
--                                                                      i_Region_Local)
--                       ORDER BY SITE, LOC DESC, QTY_ON_HAND DESC);
--
--               /*  changes to include FG inventory Aug 2016 */
--
--               SELECT WCT_INVENTORY_DETAIL_OBJECT (SITE,
--                                                   LOC,
--                                                   QTY_ON_HAND,
--                                                   QTY_IN_TRANSIT,
--                                                   NULL, -- NULL FOR YIELD_FACTOR
--                                                   NULL, -- NULL FOR TOTAL_AVAILABLE
--                                                   NULL, -- NULL FOR LOCATION TYPE
--                                                   v_Flag_No) -- NO FOR SELECTED
--                 BULK COLLECT INTO v_Inventory_Detail_List_Lcl_FG
--                 FROM (  SELECT SITE,
--                                MV.LOCATION LOC,
--                                QTY_ON_HAND,
--                                QTY_IN_TRANSIT
--                           -- '100' yield
--                           FROM (  SELECT PRODUCT_NAME_STRIPPED,
--                                          SITE,
--                                          REGION,
--                                          LOCATION,
--                                          SUM (QTY_ON_HAND) QTY_ON_HAND,
--                                          0 QTY_IN_TRANSIT,
--                                          NULL TOTAL_AVAILABLE
--                                     FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                                    WHERE     1 = 1
--                                          AND (   PART_NUMBER =
--                                                     lv_Conflicting_Part_Id
--                                               OR PART_NUMBER =
--                                                     lv_Conflicting_Part_WS)
--                                          AND REGION = i_Region_Local
--                                          AND PRODUCT_FAMILY LIKE '%WHLSALE%'
--                                 GROUP BY PRODUCT_NAME_STRIPPED,
--                                          SITE,
--                                          REGION,
--                                          LOCATION
--                                 UNION
--                                   SELECT PRODUCT_NAME_STRIPPED,
--                                          SITE,
--                                          REGION,
--                                          LOCATION,
--                                          0 QTY_ON_HAND,
--                                          SUM (QTY_IN_TRANSIT),
--                                          NULL TOTAL_AVAILABLE
--                                     FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                                    WHERE     1 = 1
--                                          AND (   PART_NUMBER =
--                                                     lv_Conflicting_Part_Id
--                                               OR PART_NUMBER =
--                                                     lv_Conflicting_Part_WS)
--                                          AND REGION = i_Region_Local
--                                          AND PRODUCT_FAMILY LIKE '%WHLSALE%'
--                                 GROUP BY PRODUCT_NAME_STRIPPED,
--                                          SITE,
--                                          REGION,
--                                          LOCATION) MV
--                                LEFT OUTER JOIN
--                                VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
--                                   ON     PM_PROD.product_name_stripped =
--                                             MV.product_name_stripped
--                                      AND PM_PROD.REGION_NAME = MV.REGION
--                          --
--                          WHERE     1 = 1
--                                AND (QTY_ON_HAND > 0 OR QTY_IN_TRANSIT > 0)
--                                AND MV.LOCATION = 'FG'           -- get FG inv
--                       --
--                       ORDER BY SITE, LOC DESC, QTY_ON_HAND DESC);
--            -- End of code changes done by Infosys for April 2014 release -- ruchhabr
--            ELSE
--               SELECT COUNT (*)
--                 INTO IS_RL_AVAILABLE
--                 FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW
--                WHERE PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped;
--
--               IF (    lv_Product_Name_Stripped LIKE '%RL'
--                   AND IS_RL_AVAILABLE > 0)
--               THEN
--                  SELECT NVL (SUM (QTY_ON_HAND + QTY_IN_TRANSIT), 0)
--                    INTO lv_Available_Quantity_RF
--                    FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                   WHERE     1 = 1
--                         AND PRODUCT_NAME_STRIPPED IN (lv_Product_Name_Stripped,
--                                                       -- AND PRODUCT_NAME_STRIPPED =
--                                                       SUBSTR (
--                                                          lv_Product_Name_Stripped,
--                                                          1,
--                                                            LENGTH (
--                                                               lv_Product_Name_Stripped)
--                                                          - 2),
--                                                          SUBSTR (
--                                                             lv_Product_Name_Stripped,
--                                                             1,
--                                                               LENGTH (
--                                                                  lv_Product_Name_Stripped)
--                                                             - 2)
--                                                       || 'WS')
--                         AND (    LOCATION IN (SELECT DESTINATION_SUBINVENTORY
--                                                 FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                                                WHERE     1 = 1
--                                                      AND (PROGRAM_TYPE = 0) -- FOR 0= Retail
--                                                      AND IS_NETTABLE = 1
--                                                      AND IS_ENABLE = 1
--                                                      AND INVENTORY_TYPE <> 2) -- changes by karusing to exclude WIP location)
--                              AND product_family <> 'WHLSALE')
--                         AND REGION = i_Region_Local;
--
--                  SELECT NVL (SUM (QTY_ON_HAND + QTY_IN_TRANSIT), 0)
--                    INTO lv_Available_Quantity_RF_Frn
--                    FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                   WHERE     1 = 1
--                         AND PRODUCT_NAME_STRIPPED IN (lv_Product_Name_Stripped,
--                                                       -- AND PRODUCT_NAME_STRIPPED =
--                                                       SUBSTR (
--                                                          lv_Product_Name_Stripped,
--                                                          1,
--                                                            LENGTH (
--                                                               lv_Product_Name_Stripped)
--                                                          - 2))
--                         AND (    LOCATION IN (SELECT DESTINATION_SUBINVENTORY
--                                                 FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                                                WHERE     1 = 1
--                                                      AND (PROGRAM_TYPE = 0) -- FOR 0= Retail
--                                                      AND IS_NETTABLE = 1
--                                                      AND IS_ENABLE = 1
--                                                      AND INVENTORY_TYPE <> 2) -- changes by karusing to exclude WIP location)
--                              AND product_family <> 'WHLSALE')
--                         AND REGION = i_Region_Foreign;
--               ELSE
--                  -- Start of code changes done by Infosys for April 2014 release -- ruchhabr
--                  SELECT NVL (SUM (QTY_ON_HAND + QTY_IN_TRANSIT), 0)
--                    INTO lv_Available_Quantity_RF
--                    FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                   WHERE     1 = 1
--                         AND PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped
--                         AND (    LOCATION IN (SELECT DESTINATION_SUBINVENTORY
--                                                 FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                                                WHERE     1 = 1
--                                                      AND (PROGRAM_TYPE = 0) -- FOR 0= Retail
--                                                      AND IS_NETTABLE = 1
--                                                      AND IS_ENABLE = 1
--                                                      AND INVENTORY_TYPE <> 2) -- changes by karusing to exclude WIP location)
--                              AND product_family <> 'WHLSALE')
--                         AND REGION = i_Region_Local;
--
--                  SELECT NVL (SUM (QTY_ON_HAND + QTY_IN_TRANSIT), 0)
--                    INTO lv_Available_Quantity_RF_Frn
--                    FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                   WHERE     1 = 1
--                         AND PRODUCT_NAME_STRIPPED LIKE
--                                lv_Product_Name_Stripped
--                         AND (    LOCATION IN (SELECT DESTINATION_SUBINVENTORY
--                                                 FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                                                WHERE     1 = 1
--                                                      AND (PROGRAM_TYPE = 0) -- FOR 0= Retail
--                                                      AND IS_NETTABLE = 1
--                                                      AND IS_ENABLE = 1
--                                                      AND INVENTORY_TYPE <> 2) -- changes by karusing to exclude WIP location)
--                              AND product_family <> 'WHLSALE')
--                         AND REGION = i_Region_Foreign;
--               -- Step 1.0 Compute All Netable Inventory Sub Locations and respective available quantity
--
--               /*SELECT WCT_INVENTORY_DETAIL_OBJECT (SITE,
--                                                   LOCATION,
--                                                   QTY_ON_HAND,
--                                                   QTY_IN_TRANSIT,
--                                                   '100',
--                                                   QTY_ON_HAND + QTY_IN_TRANSIT,
--                                                   NULL) -- NULL FOR LOCATION TYPE
--                 BULK COLLECT INTO v_Inventory_Detail_List_Local
--                 FROM RSCM_ML_C3_INV_MV
--                WHERE     1 = 1
--                      AND (   PRODUCT_NAME_STRIPPED LIKE
--                                 lv_Product_Name_Stripped_WS
--                           OR PRODUCT_NAME_STRIPPED LIKE
--                                 lv_Product_Name_Stripped)
--                      AND LOCATION IN
--                             (SELECT DESTINATION_SUBINVENTORY
--                                FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                               WHERE     1 = 1
--                                     AND (PROGRAM_TYPE = 1 OR PROGRAM_TYPE = 2) -- FOR 1= WHOLESALE, 2= DGI locations
--                                     AND IS_NETTABLE = 1
--                                     AND IS_ENABLE = 1)
--                      --AND LOCATION <> 'FG' -- excluding FG location as items in this location are from ML
--                      AND LOCATION NOT IN ('FG', 'WS-FGSLD') -- excluding FG and WS-FGSLD location as items in this location are from ML
--                      AND SUBSTR (SITE, 1, 3) IN
--                             (SELECT ZLOC
--                                FROM VV_ADM_ZLOCATION_TABLE
--                               WHERE REGION_NAME = i_Region_Local)
--             ORDER BY LOCATION DESC;*/
--
--               /*SELECT WCT_INVENTORY_DETAIL_OBJECT (SITE,
--                                                   LOCATION,
--                                                   QTY_ON_HAND,
--                                                   QTY_IN_TRANSIT,
--                                                   NULL, -- NULL FOR YIELD_FACTOR
--                                                   TOTAL_AVAILABLE,
--                                                   NULL, -- NULL FOR LOCATION TYPE
--                                                   v_Flag_No) -- NO FOR SELECTED
--                 BULK COLLECT INTO v_Inventory_Detail_List_Local
--                 FROM (  SELECT SITE,
--                                LOCATION,
--                                SUM (QTY_ON_HAND) AS QTY_ON_HAND,
--                                SUM (QTY_IN_TRANSIT) AS QTY_IN_TRANSIT,
--                                SUM (QTY_ON_HAND + QTY_IN_TRANSIT)
--                                   AS TOTAL_AVAILABLE
--                           FROM RSCM_ML_C3_INV_MV
--                          WHERE     1 = 1
--                                AND (   PRODUCT_NAME_STRIPPED LIKE
--                                           lv_Product_Name_Stripped_WS
--                                     OR PRODUCT_NAME_STRIPPED LIKE
--                                           lv_Product_Name_Stripped)
--                                AND LOCATION IN
--                                       (SELECT DESTINATION_SUBINVENTORY
--                                          FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                                         WHERE     1 = 1
--                                               AND (   PROGRAM_TYPE = 1
--                                                    OR PROGRAM_TYPE = 2) -- FOR 1= WHOLESALE, 2= DGI locations
--                                               AND IS_NETTABLE = 1
--                                               AND IS_ENABLE = 1)
--                                --AND LOCATION <> 'FG' -- excluding FG location as items in this location are from ML
--                                AND LOCATION NOT IN ('FG', 'WS-FGSLD') -- excluding FG and WS-FGSLD location as items in this location are from ML
--                                AND SUBSTR (SITE, 1, 3) IN
--                                       (SELECT ZLOC
--                                          FROM VV_ADM_ZLOCATION_TABLE
--                                         WHERE REGION_NAME = i_Region_Local)
--                       GROUP BY SITE, LOCATION
--                       ORDER BY SITE);*/
--               END IF;
--
--               SELECT WCT_INVENTORY_DETAIL_OBJECT (
--                         SITE,
--                         LOC,
--                         QTY_ON_HAND,
--                         QTY_IN_TRANSIT,
--                         CASE                          --changes amde cbharath
--                            WHEN (NVL (yield, 80) = 0) THEN 80
--                            ELSE NVL (yield, 80)
--                         END,
--                         NULL,                     -- NULL FOR TOTAL_AVAILABLE
--                         NULL,                       -- NULL FOR LOCATION TYPE
--                         v_Flag_No)                         -- NO FOR SELECTED
--                 BULK COLLECT INTO v_Inventory_Detail_List_L
--                 FROM (  SELECT SITE,
--                                MV.LOCATION LOC,
--                                QTY_ON_HAND,
--                                QTY_IN_TRANSIT,
--                                CASE
--                                   WHEN SCM.DESTINATION_SUBINVENTORY IS NULL
--                                   THEN
--                                      100
--                                   ELSE
--                                      PM_PROD.rm_yield
--                                END
--                                   AS yield
--                           FROM (  SELECT product_name_stripped,
--                                          SITE,
--                                          REGION,
--                                          LOCATION,
--                                          SUM (QTY_ON_HAND) QTY_ON_HAND,
--                                          0 QTY_IN_TRANSIT,
--                                          NULL TOTAL_AVAILABLE
--                                     FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                                    WHERE     1 = 1
--                                          AND (   PRODUCT_NAME_STRIPPED LIKE
--                                                     lv_Product_Name_Stripped_WS
--                                               OR PRODUCT_NAME_STRIPPED LIKE
--                                                     lv_Product_Name_Stripped
--                                               OR PRODUCT_NAME_STRIPPED IN --added for showing all locations
--                                                                           (lv_Product_Name_Stripped_WS,
--                                                                            SUBSTR (
--                                                                               lv_Product_Name_Stripped_WS,
--                                                                               1,
--                                                                                 LENGTH (
--                                                                                    lv_Product_Name_Stripped_WS)
--                                                                               - 2))
--                                               OR PRODUCT_NAME_STRIPPED IN --add
--                                                                           (lv_Product_Name_Stripped_WS,
--                                                                               SUBSTR (
--                                                                                  lv_Product_Name_Stripped_WS,
--                                                                                  1,
--                                                                                    LENGTH (
--                                                                                       lv_Product_Name_Stripped_WS)
--                                                                                  - 2)
--                                                                            || 'RL')) --ended
--                                 GROUP BY product_name_stripped,
--                                          SITE,
--                                          REGION,
--                                          LOCATION
--                                 UNION
--                                   SELECT product_name_stripped,
--                                          SITE,
--                                          REGION,
--                                          LOCATION,
--                                          0 QTY_ON_HAND,
--                                          SUM (QTY_IN_TRANSIT),
--                                          NULL TOTAL_AVAILABLE
--                                     FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                                    WHERE     1 = 1
--                                          AND (   PRODUCT_NAME_STRIPPED LIKE
--                                                     lv_Product_Name_Stripped_WS
--                                               OR PRODUCT_NAME_STRIPPED LIKE
--                                                     lv_Product_Name_Stripped
--                                               OR PRODUCT_NAME_STRIPPED IN --added for showing all locations
--                                                                           (lv_Product_Name_Stripped_WS,
--                                                                            SUBSTR (
--                                                                               lv_Product_Name_Stripped_WS,
--                                                                               1,
--                                                                                 LENGTH (
--                                                                                    lv_Product_Name_Stripped_WS)
--                                                                               - 2))
--                                               OR PRODUCT_NAME_STRIPPED IN --add
--                                                                           (lv_Product_Name_Stripped_WS,
--                                                                               SUBSTR (
--                                                                                  lv_Product_Name_Stripped_WS,
--                                                                                  1,
--                                                                                    LENGTH (
--                                                                                       lv_Product_Name_Stripped_WS)
--                                                                                  - 2)
--                                                                            || 'RL')) --ended
--                                 GROUP BY product_name_stripped,
--                                          SITE,
--                                          REGION,
--                                          LOCATION) MV
--                                LEFT OUTER JOIN
--                                VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
--                                   ON     PM_PROD.product_name_stripped =
--                                             MV.product_name_stripped
--                                      AND PM_PROD.REGION_NAME = MV.REGION
--                                LEFT OUTER JOIN
--                                VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP SCM
--                                   ON     MV.LOCATION =
--                                             SCM.DESTINATION_SUBINVENTORY
--                                      AND SCM.YIELD_WS = 'YES'
--                          WHERE     1 = 1
--                                AND (QTY_ON_HAND > 0 OR QTY_IN_TRANSIT > 0)
--                                AND MV.LOCATION IN (SELECT DESTINATION_SUBINVENTORY
--                                                      FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                                                     WHERE     1 = 1
--                                                           AND (   PROGRAM_TYPE =
--                                                                      1
--                                                                OR PROGRAM_TYPE =
--                                                                      2) -- FOR 1= WHOLESALE, 2= DGI locations
--                                                           AND IS_NETTABLE = 1
--                                                           AND IS_ENABLE = 1)
--                                AND MV.LOCATION NOT IN ('FG',
--                                                        'WS-FGSLD',
--                                                        'RF-W-RHS',
--                                                        'RF-W-OEM',
--                                                        'RF-WIP',
--                                                        'WS-WIP') -- excluding FG and WS-FGSLD location, WIP location as items in this location are from ML
--                                AND SUBSTR (SITE, 1, 3) IN (SELECT ZLOC
--                                                              FROM VAVNI_CISCO_RSCM_ADMIN.VV_ADM_ZLOCATION_TABLE
--                                                             WHERE REGION_NAME =
--                                                                      i_Region_Local)
--                       ORDER BY SITE, LOC DESC, QTY_ON_HAND DESC);
--
--               /*  changes to include FG inventory Aug 2016 */
--
--               SELECT WCT_INVENTORY_DETAIL_OBJECT (SITE,
--                                                   LOC,
--                                                   QTY_ON_HAND,
--                                                   QTY_IN_TRANSIT,
--                                                   yield,
--                                                   NULL, -- NULL FOR TOTAL_AVAILABLE
--                                                   NULL, -- NULL FOR LOCATION TYPE
--                                                   v_Flag_No) -- NO FOR SELECTED
--                 BULK COLLECT INTO v_Inventory_Detail_List_Lcl_FG
--                 FROM (  SELECT SITE,
--                                MV.LOCATION LOC,
--                                QTY_ON_HAND,
--                                QTY_IN_TRANSIT,
--                                '100' AS yield
--                           FROM (  SELECT product_name_stripped,
--                                          SITE,
--                                          REGION,
--                                          LOCATION,
--                                          SUM (QTY_ON_HAND) QTY_ON_HAND,
--                                          0 QTY_IN_TRANSIT,
--                                          NULL TOTAL_AVAILABLE
--                                     FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                                    WHERE     1 = 1
--                                          AND (   PRODUCT_NAME_STRIPPED LIKE
--                                                     lv_Product_Name_Stripped_WS
--                                               OR PRODUCT_NAME_STRIPPED LIKE
--                                                     lv_Product_Name_Stripped
--                                               OR PRODUCT_NAME_STRIPPED IN --added for showing all locations
--                                                                           (lv_Product_Name_Stripped_WS,
--                                                                            SUBSTR (
--                                                                               lv_Product_Name_Stripped_WS,
--                                                                               1,
--                                                                                 LENGTH (
--                                                                                    lv_Product_Name_Stripped_WS)
--                                                                               - 2))
--                                               OR PRODUCT_NAME_STRIPPED IN --add
--                                                                           (lv_Product_Name_Stripped_WS,
--                                                                               SUBSTR (
--                                                                                  lv_Product_Name_Stripped_WS,
--                                                                                  1,
--                                                                                    LENGTH (
--                                                                                       lv_Product_Name_Stripped_WS)
--                                                                                  - 2)
--                                                                            || 'RL'))
--                                          AND REGION = i_Region_Local
--                                          AND PRODUCT_FAMILY LIKE '%WHLSALE%' --ended
--                                 GROUP BY product_name_stripped,
--                                          SITE,
--                                          REGION,
--                                          LOCATION
--                                 UNION
--                                   SELECT product_name_stripped,
--                                          SITE,
--                                          REGION,
--                                          LOCATION,
--                                          0 QTY_ON_HAND,
--                                          SUM (QTY_IN_TRANSIT),
--                                          NULL TOTAL_AVAILABLE
--                                     FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                                    WHERE     1 = 1
--                                          AND (   PRODUCT_NAME_STRIPPED LIKE
--                                                     lv_Product_Name_Stripped_WS
--                                               OR PRODUCT_NAME_STRIPPED LIKE
--                                                     lv_Product_Name_Stripped
--                                               OR PRODUCT_NAME_STRIPPED IN --added for showing all locations
--                                                                           (lv_Product_Name_Stripped_WS,
--                                                                            SUBSTR (
--                                                                               lv_Product_Name_Stripped_WS,
--                                                                               1,
--                                                                                 LENGTH (
--                                                                                    lv_Product_Name_Stripped_WS)
--                                                                               - 2))
--                                               OR PRODUCT_NAME_STRIPPED IN --add
--                                                                           (lv_Product_Name_Stripped_WS,
--                                                                               SUBSTR (
--                                                                                  lv_Product_Name_Stripped_WS,
--                                                                                  1,
--                                                                                    LENGTH (
--                                                                                       lv_Product_Name_Stripped_WS)
--                                                                                  - 2)
--                                                                            || 'RL'))
--                                          AND REGION = i_Region_Local
--                                          AND PRODUCT_FAMILY LIKE '%WHLSALE%' --ended
--                                 GROUP BY product_name_stripped,
--                                          SITE,
--                                          REGION,
--                                          LOCATION) MV
--                                LEFT OUTER JOIN
--                                VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
--                                   ON     PM_PROD.product_name_stripped =
--                                             MV.product_name_stripped
--                                      AND PM_PROD.REGION_NAME = MV.REGION
--                          WHERE     1 = 1
--                                AND (QTY_ON_HAND > 0 OR QTY_IN_TRANSIT > 0)
--                                AND MV.LOCATION = 'FG'               -- FG inv
--                       ORDER BY SITE, LOC DESC, QTY_ON_HAND DESC);
--            -- End of code changes done by Infosys for April 2014 release -- ruchhabr
--
--            END IF;
--         EXCEPTION
--            WHEN NO_DATA_FOUND
--            THEN
--               --LOG EXCEPTION
--               INSERT INTO WCT_ERROR_LOG
--                       VALUES (
--                                 UPPER (lv_Requested_Part),
--                                 lv_User_Id,
--                                 'COMPUTE_INV_AND_AVAILABLE_QTY - Step 1.0 - No data found',
--                                 SYSDATE);
--            WHEN OTHERS
--            THEN
--               --LOG EXCEPTION
--               v_Error_Message := NULL;
--               v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--               INSERT INTO WCT_ERROR_LOG
--                       VALUES (
--                                 UPPER (lv_Requested_Part),
--                                 lv_User_Id,
--                                    'COMPUTE_INV_AND_AVAILABLE_QTY - Step 1.0 - '
--                                 || v_Error_Message,
--                                 SYSDATE);
--         END;
--
--         -- Step 3.0 : Compute Total available FGI, DGI and POE Inventory. Decide how much to return to UI, also fill in Yield Factor in the List
--         lv_Available_Quantity_FG := 0;
--         lv_Available_Quantity_WS := 0;
--         lv_Available_Quantity_POE := 0;
--
--         /* Start changes to include FG inventory Aug 2016 */
--
--         lv_Inventory_WS_FGI_Count_lcl := 0;
--
--         --  v_Inventory_Detail_List_Local.COUNT ();
--         -- insert FG
--
--         FOR i IN 1 .. v_Inventory_Detail_List_Lcl_FG.COUNT ()
--         LOOP
--            lv_Inventory_WS_FGI_Count_lcl := lv_Inventory_WS_FGI_Count_lcl + 1;
--            v_Inventory_Detail_List_Local.EXTEND ();
--            v_Inventory_Detail_List_Local (lv_Inventory_WS_FGI_Count_lcl) :=
--               v_Inventory_Detail_List_Lcl_FG (i);
--         END LOOP;
--
--         -- insert FGI, DGI, POE
--
--         FOR i IN 1 .. v_Inventory_Detail_List_L.COUNT ()
--         LOOP
--            lv_Inventory_WS_FGI_Count_lcl := lv_Inventory_WS_FGI_Count_lcl + 1;
--            v_Inventory_Detail_List_Local.EXTEND ();
--            v_Inventory_Detail_List_Local (lv_Inventory_WS_FGI_Count_lcl) :=
--               v_Inventory_Detail_List_L (i);
--         END LOOP;
--
--
--
--         FOR i IN 1 .. v_Inventory_Detail_List_Local.COUNT ()
--         LOOP
--            lv_Location :=
--               v_Inventory_Detail_List_Local (i).INVENTORY_LOCATION;
--            lv_Yield_Factor_Lcl :=
--               v_Inventory_Detail_List_Local (i).YIELD_FACTOR;
--
--            /* Start changes to include FG inventory Aug 2016 */
--
--            IF (lv_Location = 'WS-FGI' OR lv_Location = 'FG') -- include FG as well
--            THEN
--               lv_Available_Qty_On_Hand :=
--                  v_Inventory_Detail_List_Local (i).ON_HAND;
--               lv_Available_Qty_In_Transit :=
--                  v_Inventory_Detail_List_Local (i).IN_TRANSIT;
--
--               lv_Total_Available :=
--                  lv_Available_Qty_On_Hand + lv_Available_Qty_In_Transit;
--               lv_Available_Quantity_FG :=
--                  lv_Available_Quantity_FG + lv_Total_Available;
--
--               v_Inventory_Detail_List_Local (i).TOTAL_AVAILABLE :=
--                  lv_Total_Available;
--               v_Inventory_Detail_List_Local (i).YIELD_FACTOR :=
--                  v_Not_Applicable;
--
--               v_Inventory_Detail_List_Local (i).LOCATION_TYPE := 'FGI';
--
--               lv_Final_Inventory_FGI_Count :=
--                  lv_Final_Inventory_FGI_Count + 1;
--               v_Final_Inventory_List_FGI.EXTEND ();
--               v_Final_Inventory_List_FGI (lv_Final_Inventory_FGI_Count) :=
--                  v_Inventory_Detail_List_Local (i);
--            ELSIF (lv_Location LIKE 'WS%')
--            THEN
--               --Changes made by Chaithra on 28-04-2014
--               --Commented
--
--               -- IF (NOT lv_Yield_Factor_Override)
--               --THEN
--               --lv_Yield_Factor_Override_Val := lv_Yield_Factor_Lcl;
--               -- END IF;
--
--               -- Start of code changes done by Infosys for April 2014 release -- karusing
--               /*lv_Available_Quantity_WS :=
--                     lv_Available_Quantity_WS
--                   + v_Inventory_Detail_List_Local (i).TOTAL_AVAILABLE;
--                v_Inventory_Detail_List_Local (i).YIELD_FACTOR :=
--                   lv_Yield_Factor_Lcl;*/
--
--               lv_Available_Qty_On_Hand :=
--                  v_Inventory_Detail_List_Local (i).ON_HAND;
--               lv_Available_Qty_In_Transit :=
--                  v_Inventory_Detail_List_Local (i).IN_TRANSIT;
--
--               lv_Available_Qty_On_Hand :=
--                  (lv_Available_Qty_On_Hand * lv_Yield_Factor_Lcl) / 100;
--
--               lv_Available_Qty_In_Transit :=
--                  (lv_Available_Qty_In_Transit * lv_Yield_Factor_Lcl) / 100;
--
--               lv_Available_Qty_On_Hand :=
--                  VV_RSCM_UTIL.GENERIC_ROUND_UTIL (lv_Available_Qty_On_Hand,
--                                                   1);
--
--               lv_Available_Qty_In_Transit :=
--                  VV_RSCM_UTIL.GENERIC_ROUND_UTIL (
--                     lv_Available_Qty_In_Transit,
--                     1);
--
--               lv_Total_Available :=
--                  lv_Available_Qty_On_Hand + lv_Available_Qty_In_Transit;
--
--               v_Inventory_Detail_List_Local (i).TOTAL_AVAILABLE :=
--                  lv_Total_Available;
--
--               lv_Available_Quantity_WS :=
--                  lv_Available_Quantity_WS + lv_Total_Available;
--               -- End of code changes done by Infosys for April 2014 release -- karusing
--
--               v_Inventory_Detail_List_Local (i).LOCATION_TYPE := 'WS';
--
--               lv_Final_Inventory_WS_Count := lv_Final_Inventory_WS_Count + 1;
--               v_Final_Inventory_List_WS.EXTEND ();
--               v_Final_Inventory_List_WS (lv_Final_Inventory_WS_Count) :=
--                  v_Inventory_Detail_List_Local (i);
--            ELSIF (lv_Location LIKE 'POE%')
--            THEN
--               lv_Available_Qty_On_Hand :=
--                  v_Inventory_Detail_List_Local (i).ON_HAND;
--               lv_Available_Qty_In_Transit :=
--                  v_Inventory_Detail_List_Local (i).IN_TRANSIT;
--
--               lv_Available_Qty_On_Hand :=
--                  (lv_Available_Qty_On_Hand * lv_Yield_Factor_Lcl) / 100;
--
--               lv_Available_Qty_In_Transit :=
--                  (lv_Available_Qty_In_Transit * lv_Yield_Factor_Lcl) / 100;
--
--               lv_Available_Qty_On_Hand :=
--                  VV_RSCM_UTIL.GENERIC_ROUND_UTIL (lv_Available_Qty_On_Hand,
--                                                   1);
--
--               lv_Available_Qty_In_Transit :=
--                  VV_RSCM_UTIL.GENERIC_ROUND_UTIL (
--                     lv_Available_Qty_In_Transit,
--                     1);
--
--               lv_Total_Available :=
--                  lv_Available_Qty_On_Hand + lv_Available_Qty_In_Transit;
--
--               v_Inventory_Detail_List_Local (i).YIELD_FACTOR :=
--                  lv_Yield_Factor_Lcl;
--
--               v_Inventory_Detail_List_Local (i).TOTAL_AVAILABLE :=
--                  lv_Total_Available;
--
--               lv_Available_Quantity_POE :=
--                  lv_Available_Quantity_POE + lv_Total_Available;
--               -- End of code changes done by Infosys for April 2014 release -- karusing
--
--               v_Inventory_Detail_List_Local (i).LOCATION_TYPE := 'POE';
--
--               lv_Final_Inventory_POE_Count :=
--                  lv_Final_Inventory_POE_Count + 1;
--               v_Final_Inventory_List_POE.EXTEND ();
--               v_Final_Inventory_List_POE (lv_Final_Inventory_POE_Count) :=
--                  v_Inventory_Detail_List_Local (i);
--            END IF;
--         END LOOP;
--
--         lv_RF_Reduce_From_POE := 0;
--         lv_WS_reduce_From_POE := 0;
--         lv_Net_Available_POE := 0;
--
--         -- CHECK FOR RF - FULFILMENT FROM RF-FGI ITSELF. ELSE MAKE A NOTE TO REDUCE IT FROM POE
--         IF ( (lv_Reservation_RF_Total_Lcl + lv_Reservation_RF_Total_Frn) >
--                (lv_Available_Quantity_RF + lv_Available_Quantity_RF_Frn))
--         THEN
--            lv_RF_Reduce_From_POE :=
--                 lv_Reservation_RF_Total_Lcl
--               + lv_Reservation_RF_Total_Frn         -- for global reservation
--               - (lv_Available_Quantity_RF + lv_Available_Quantity_RF_Frn); -- for global reservation
--         ELSE
--            lv_Reservation_RF_Total_Lcl := 0;
--            lv_Reservation_RF_Total_Frn := 0;
--         END IF;
--
--         -- IF NO INVENTORY AVAILABLE IN FG + WS + POE
--
--
--
--         IF ( (  lv_Available_Quantity_FG
--               + lv_Available_Quantity_WS
--               + lv_Available_Quantity_POE) <= 0)
--         THEN
--            --lv_Lead_Time := 0;          -- UI to display lead time as N/A if 0
--            lv_Available_Quantity := 0;
--         ELSE
--            -- ADD FGI INVENTORY TO FINAL LIST
--            FOR i IN 1 .. v_Final_Inventory_List_FGI.COUNT ()
--            LOOP
--               lv_Final_Inventory_Count := lv_Final_Inventory_Count + 1;
--               v_Final_Inventory_Return_List.EXTEND ();
--               v_Final_Inventory_Return_List (lv_Final_Inventory_Count) :=
--                  v_Final_Inventory_List_FGI (i);
--            END LOOP;
--
--            -- Start of code changes done by Infosys for April 2014 release -- ravchitt
--            -- ADD WS INVENTORY TO FINAL LIST
--            FOR i IN 1 .. v_Final_Inventory_List_WS.COUNT ()
--            LOOP
--               lv_Final_Inventory_Count := lv_Final_Inventory_Count + 1;
--               v_Final_Inventory_Return_List.EXTEND ();
--               v_Final_Inventory_Return_List (lv_Final_Inventory_Count) :=
--                  v_Final_Inventory_List_WS (i);
--            END LOOP;
--
--            -- ADD POE INVENTORY TO FINAL LIST
--            FOR i IN 1 .. v_Final_Inventory_List_POE.COUNT ()
--            LOOP
--               lv_Final_Inventory_Count := lv_Final_Inventory_Count + 1;
--               v_Final_Inventory_Return_List.EXTEND ();
--               v_Final_Inventory_Return_List (lv_Final_Inventory_Count) :=
--                  v_Final_Inventory_List_POE (i);
--            END LOOP;
--
--            --  End of code changes done by Infosys for April 2014 release -- ravchitt
--
--            lv_Available_Quantity_FG_Net :=
--                 lv_Available_Quantity_FG
--               - lv_Reservation_WS_Total_Lcl
--               - lv_Reservation_WS_Total_Frn;
--
--
--
--            lv_Requested_Qty :=
--               lv_Requested_Qty - lv_Available_Quantity_FG_Net;
--
--
--
--            IF (lv_Available_Quantity_FG_Net <= 0)
--            THEN
--               lv_Available_Quantity_FG_Net := 0;
--               lv_WS_reduce_From_POE :=
--                    lv_Reservation_WS_Total_Lcl
--                  + lv_Reservation_WS_Total_Frn      -- for global reservation
--                  - lv_Available_Quantity_FG;
--            ELSE
--               lv_WS_reduce_From_POE := 0;
--            END IF;
--
--
--
--            -- REQUESTED QUANTITY SATISFIED FROM FG ITSELF
--            IF (lv_Requested_Qty <= 0)
--            THEN
--               --lv_Lead_Time := 1;
--               lv_Available_Quantity_WS := 0;
--               lv_Available_Quantity_POE := 0;
--            ELSE
--               lv_Available_Quantity_WS_Net :=
--                  lv_Available_Quantity_WS - lv_WS_reduce_From_POE;
--               lv_Requested_Qty :=
--                  lv_Requested_Qty - lv_Available_Quantity_WS_Net;
--
--
--
--               IF (lv_Available_Quantity_WS_Net <= 0)
--               THEN
--                  lv_Available_Quantity_WS_Net := 0;
--                  lv_WS_reduce_From_POE :=
--                     lv_WS_reduce_From_POE - lv_Available_Quantity_WS;
--               ELSE
--                  lv_WS_reduce_From_POE := 0;
--               END IF;
--
--
--               -- Start of code changes done by Infosys for April 2014 release -- ravchitt
--               -- ADD POE INVENTORY TO FINAL LIST
--               /*FOR i IN 1 .. v_Final_Inventory_List_POE.COUNT ()
--               LOOP
--                  lv_Final_Inventory_Count := lv_Final_Inventory_Count + 1;
--                  v_Final_Inventory_Return_List.EXTEND ();
--                  v_Final_Inventory_Return_List (lv_Final_Inventory_Count) :=
--                     v_Final_Inventory_List_POE (i);
--               END LOOP;*/
--
--               -- End of code changes done by Infosys for April 2014 release -- ravchitt
--               -- REQUESTED QUANTITY SATISFIED FROM FG + WS ITSELF
--               IF (lv_Requested_Qty <= 0)
--               THEN
--                  --lv_Lead_Time := 2;
--                  lv_Available_Quantity_POE := 0;
--               ELSE
--                  -- REQUESTED QUANTITY SATISFIED FROM FG + WS + POE
--                  /*IF ( (  lv_RF_Reduce_From_POE
--                        + lv_WS_reduce_From_POE
--                        + lv_Requested_Qty) <= lv_Available_Quantity_POE)
--                  THEN
--                     lv_Lead_Time := 3;
--                  ELSE
--                     lv_Lead_Time := 4;
--                  END IF;*/
--
--                  -- COMPUTING NET AVAILABLE QUANTITY
--                  lv_Available_Quantity_POE_Net :=
--                       lv_Available_Quantity_POE
--                     - (lv_RF_Reduce_From_POE + lv_WS_reduce_From_POE);
--
--
--                  IF (lv_Available_Quantity_POE_Net < 0)
--                  THEN
--                     lv_Available_Quantity_POE_Net := 0;
--                  END IF;
--               /*IF (lv_RF_Reduce_From_POE > 0)
--               THEN
--                  lv_RF_Reduce_From_POE :=
--                     lv_Available_Quantity_POE - lv_RF_Reduce_From_POE;
--               END IF;*/
--               END IF;
--            END IF;
--
--            lv_Available_Quantity :=
--                 lv_Available_Quantity_FG_Net
--               + lv_Available_Quantity_WS_Net
--               + lv_Available_Quantity_POE_Net;
--         END IF;
--
--         IF (lv_Available_Quantity < 0)
--         THEN
--            lv_Available_Quantity := 0;
--         END IF;
--
--         -- Start of code changes done by Infosys for April 2014 release -- ruchhabr
--         /*IF (lv_Wholesale_Part IS NULL)
--         THEN
--            lv_Lead_Time := 4;
--         ELSIF (lv_Available_Quantity <= 0)
--         THEN
--            lv_Lead_Time := 0;          -- UI to display lead time as N/A if 0
--         ELSIF (lv_Available_Quantity >= i_Requested_Qty)
--         THEN
--            lv_Lead_Time := 1;
--         ELSIF (lv_Available_Quantity >= (i_Requested_Qty / 2))
--         THEN
--            lv_Lead_Time := 2;
--         ELSIF (lv_Available_Quantity < (i_Requested_Qty / 2))
--         THEN
--            lv_Lead_Time := 4;
--         ELSE
--            lv_Lead_Time := 3;
--         END IF;*/
--
--         -- Re-initialize requested quantity
--         lv_Requested_Qty := i_Requested_Qty;
--
--         lv_RF_Reduce_From_POE_TMP := lv_RF_Reduce_From_POE;
--
--         lv_Requested_Qty :=
--              lv_Requested_Qty
--            + lv_Reservation_WS_Total_Lcl
--            + lv_Reservation_WS_Total_Frn;
--
--
--
--         FOR i IN 1 .. v_Final_Inventory_Return_List.COUNT
--         LOOP
--            IF (v_Final_Inventory_Return_List (i).YIELD_FACTOR =
--                   v_Not_Applicable)
--            THEN
--               lv_Yield_Factor_Lcl := 100;
--            ELSE
--               lv_Yield_Factor_Lcl :=
--                  v_Final_Inventory_Return_List (i).YIELD_FACTOR;
--            END IF;
--
--            lv_Available_Qty_On_Hand :=
--               v_Final_Inventory_Return_List (i).ON_HAND;
--            lv_Available_Qty_In_Transit :=
--               v_Final_Inventory_Return_List (i).IN_TRANSIT;
--
--            lv_Available_Qty_On_Hand :=
--               (lv_Available_Qty_On_Hand * lv_Yield_Factor_Lcl) / 100;
--
--            lv_Available_Qty_In_Transit :=
--               (lv_Available_Qty_In_Transit * lv_Yield_Factor_Lcl) / 100;
--
--            lv_Available_Qty_On_Hand :=
--               VV_RSCM_UTIL.GENERIC_ROUND_UTIL (lv_Available_Qty_On_Hand, 1);
--
--            lv_Available_Qty_In_Transit :=
--               VV_RSCM_UTIL.GENERIC_ROUND_UTIL (lv_Available_Qty_In_Transit,
--                                                1);
--
--            lv_Total_Available :=
--               lv_Available_Qty_On_Hand + lv_Available_Qty_In_Transit;
--
--            lv_Available_QtyOnHand_Net :=
--               lv_Available_QtyOnHand_Net + lv_Available_Qty_On_Hand;
--            lv_Available_QtyInTransit_Net :=
--               lv_Available_QtyInTransit_Net + lv_Available_Qty_In_Transit;
--
--            v_Final_Inventory_Return_List (i).SELECTED := v_Flag_Yes;
--
--            IF (   (v_Final_Inventory_Return_List (i).LOCATION_TYPE = 'FGI')
--                OR (v_Final_Inventory_Return_List (i).LOCATION_TYPE = 'WS'))
--            THEN
--               lv_Available_Qty_O_H_WS_Net :=
--                  lv_Available_Qty_O_H_WS_Net + lv_Available_Qty_On_Hand;
--               lv_Available_Qty_I_T_WS_Net :=
--                  lv_Available_Qty_I_T_WS_Net + lv_Available_Qty_In_Transit;
--            ELSIF (v_Final_Inventory_Return_List (i).LOCATION_TYPE = 'POE')
--            THEN
--               lv_Available_Qty_O_H_POE_Net :=
--                  lv_Available_Qty_O_H_POE_Net + lv_Available_Qty_On_Hand;
--               lv_Available_Qty_I_T_POE_Net :=
--                  lv_Available_Qty_I_T_POE_Net + lv_Available_Qty_In_Transit;
--               lv_RF_Reduce_From_POE_TMP :=
--                  lv_RF_Reduce_From_POE_TMP - lv_Total_Available;
--            END IF;
--
--
--
--            lv_Z_Location :=
--               SUBSTR (v_Final_Inventory_Return_List (i).INVENTORY_SITE,
--                       1,
--                       3);
--
--            IF (lv_Available_Qty_On_Hand > 0)
--            THEN
--               IF (i > 1)
--               THEN
--                  lv_Inventory_Detail_Notes_O_H :=
--                     lv_Inventory_Detail_Notes_O_H || ', ';
--               END IF;
--
--               lv_Inventory_Detail_Notes_O_H :=
--                     lv_Inventory_Detail_Notes_O_H
--                  || lv_Z_Location
--                  || '-'
--                  || v_Final_Inventory_Return_List (i).INVENTORY_LOCATION
--                  || ' ('
--                  || lv_Available_Qty_On_Hand
--                  || ')';
--            END IF;
--
--            IF (lv_Available_Qty_In_Transit > 0)
--            THEN
--               IF (i > 1)
--               THEN
--                  lv_Inventory_Detail_Notes_I_T :=
--                     lv_Inventory_Detail_Notes_I_T || ', ';
--               END IF;
--
--               lv_Inventory_Detail_Notes_I_T :=
--                     lv_Inventory_Detail_Notes_I_T
--                  || lv_Z_Location
--                  || '-'
--                  || v_Final_Inventory_Return_List (i).INVENTORY_LOCATION
--                  || ' ('
--                  || lv_Available_Qty_In_Transit
--                  || ')';
--            END IF;
--
--            IF (    (lv_Total_Available >= lv_Requested_Qty)
--                AND (lv_RF_Reduce_From_POE_TMP <= 0))
--            THEN
--               EXIT;
--            ELSE
--               lv_Requested_Qty := lv_Requested_Qty - lv_Total_Available;
--            END IF;
--         END LOOP;
--
--         IF (lv_RF_Reduce_From_POE_TMP > 0)
--         THEN
--            lv_RF_Reduce_From_POE :=
--               lv_RF_Reduce_From_POE - lv_RF_Reduce_From_POE_TMP;
--         END IF;
--
--         -- if WS reservations are more than WS available
--         IF ( (lv_Reservation_WS_Total_Lcl + lv_Reservation_WS_Total_Frn) >
--                (lv_Available_Qty_O_H_WS_Net + lv_Available_Qty_I_T_WS_Net))
--         THEN
--            lv_WS_reduce_From_POE :=
--                 (lv_Reservation_WS_Total_Lcl + lv_Reservation_WS_Total_Frn)
--               - (lv_Available_Qty_O_H_WS_Net + lv_Available_Qty_I_T_WS_Net);
--
--            lv_Available_Qty_O_H_WS_Net := 0;
--            lv_Available_Qty_I_T_WS_Net := 0;
--         ELSE
--            lv_Available_Qty_O_H_WS_Net :=
--                 lv_Available_Qty_O_H_WS_Net
--               - (lv_Reservation_WS_Total_Lcl + lv_Reservation_WS_Total_Frn);
--
--            IF (lv_Available_Qty_O_H_WS_Net < 0)
--            THEN
--               lv_Available_Qty_I_T_WS_Net :=
--                  lv_Available_Qty_I_T_WS_Net + lv_Available_Qty_O_H_WS_Net;
--               lv_Available_Qty_O_H_WS_Net := 0;
--            END IF;
--
--            /*IF (lv_Available_Qty_I_T_WS_Net < 0)
--            THEN
--               lv_Available_Qty_I_T_WS_Net := 0;
--            END IF;*/
--
--            lv_WS_reduce_From_POE := 0;
--         END IF;
--
--         -- if RF reservations are more than RF available
--         IF (lv_RF_Reduce_From_POE > 0)
--         THEN
--            lv_Available_Qty_O_H_POE_Net :=
--               lv_Available_Qty_O_H_POE_Net - lv_RF_Reduce_From_POE;
--
--            IF (lv_Available_Qty_O_H_POE_Net < 0)
--            THEN
--               lv_Available_Qty_I_T_POE_Net :=
--                  lv_Available_Qty_I_T_POE_Net + lv_Available_Qty_O_H_POE_Net;
--               lv_Available_Qty_O_H_POE_Net := 0;
--
--               IF (lv_Available_Qty_I_T_POE_Net < 0)
--               THEN
--                  lv_Available_Qty_I_T_POE_Net := 0;
--               END IF;
--            END IF;
--         END IF;
--
--         -- if WS reservations for POE exist
--         IF (lv_WS_Reduce_From_POE > 0)
--         THEN
--            IF ( (lv_Available_Qty_O_H_POE_Net + lv_Available_Qty_I_T_POE_Net) >
--                   0)
--            THEN
--               lv_Available_Qty_O_H_POE_Net :=
--                  lv_Available_Qty_O_H_POE_Net - lv_WS_Reduce_From_POE;
--
--               IF (lv_Available_Qty_O_H_POE_Net < 0)
--               THEN
--                  lv_Available_Qty_I_T_POE_Net :=
--                       lv_Available_Qty_I_T_POE_Net
--                     + lv_Available_Qty_O_H_POE_Net;
--                  lv_Available_Qty_O_H_POE_Net := 0;
--
--                  IF (lv_Available_Qty_I_T_POE_Net < 0)
--                  THEN
--                     lv_Available_Qty_I_T_POE_Net := 0;
--                  END IF;
--               END IF;
--            ELSE
--               lv_Available_Qty_O_H_POE_Net := 0;
--               lv_Available_Qty_I_T_POE_Net := 0;
--            END IF;
--         END IF;
--
--         lv_Available_QtyOnHand_Net :=
--            lv_Available_Qty_O_H_WS_Net + lv_Available_Qty_O_H_POE_Net;
--         lv_Available_QtyInTransit_Net :=
--            lv_Available_Qty_I_T_WS_Net + lv_Available_Qty_I_T_POE_Net;
--
--
--         /*IF (  lv_Available_QtyOnHand_Net
--     - (lv_WS_reduce_From_POE + lv_RF_reduce_From_POE) <= 0)
-- THEN
--    lv_Available_QtyOnHand_Net := 0;
--
--    IF (  lv_Available_QtyInTransit_Net
--        + (  lv_Available_QtyOnHand_Net
--           - (lv_WS_reduce_From_POE + lv_RF_reduce_From_POE)) <= 0)
--    THEN
--       lv_Available_QtyInTransit_Net := 0;
--    ELSE
--       lv_Available_QtyInTransit_Net :=
--            lv_Available_QtyInTransit_Net
--          + (  lv_Available_QtyOnHand_Net
--             - (lv_WS_reduce_From_POE + lv_RF_reduce_From_POE));
--    END IF;
-- ELSE
--    lv_Available_QtyOnHand_Net :=
--         lv_Available_QtyOnHand_Net
--       - (lv_WS_reduce_From_POE + lv_RF_reduce_From_POE);
-- END IF;*/
--
--         -- Re-initialize requested quantity
--         lv_Requested_Qty := i_Requested_Qty;
--
--         /*
--         * Ship time Logic: condition sequence updated for June release
--         * ------------------------------------------------------------
--         * 1) No inventory: ship time 0, i.e.,  N/A
--         * 2) No wholesale part: ship time 4 weeks
--         */
--
--         -- ship time is 0 weeks, i.e., N/A if no quantity available
--         IF (    lv_Available_QtyOnHand_Net = 0
--             AND lv_Available_QtyInTransit_Net = 0)
--         THEN
--            lv_Lead_Time_1 := '0';      -- UI to display lead time as N/A if 0
--
--            -- changes for June release - ruchhabr
--            lv_Quantity_On_Hand_1 := '0';
--            lv_Quantity_In_Transit_1 := '0';
--         -- ship time is 4 weeks if no wholesale part exists
--         ELSIF (lv_Wholesale_Part IS NULL)
--         THEN
--            lv_Lead_Time_1 := '4';
--            --lv_Available_Quantity_Net_1 := lv_Available_Quantity;
--            lv_Available_Quantity_Net_1 :=
--               lv_Available_QtyOnHand_Net + lv_Available_QtyInTransit_Net;
--            lv_Inventory_Detail_Notes_1 :=
--               lv_Inventory_Detail_Notes_O_H || lv_Inventory_Detail_Notes_I_T; --Changes made by cbharath on 29-4-2014
--
--            -- changes for June release - ruchhabr
--            lv_Quantity_On_Hand_1 := lv_Available_QtyOnHand_Net;
--            lv_Quantity_In_Transit_1 := lv_Available_QtyInTransit_Net;
--         -- ship time is 0 weeks, i.e., N/A if no quantity available
--         --ELSIF (lv_Available_Quantity = 0)
--         /*ELSIF (    lv_Available_QtyOnHand_Net = 0
--                AND lv_Available_QtyInTransit_Net = 0)
--         THEN
--            lv_Lead_Time_1 := '0';      -- UI to display lead time as N/A if 0
--
--            -- changes for June release - ruchhabr
--            lv_Quantity_On_Hand_1 := '0';
--            lv_Quantity_In_Transit_1 := '0';*/
--         -- ship time is 1 week if requested quantity is fulfilled by on hand alone
--         ELSIF (lv_Available_QtyOnHand_Net >= i_Requested_Qty)
--         THEN
--            lv_Lead_Time_1 := '1';
--
--            lv_Available_Quantity_Net_1 := lv_Available_QtyOnHand_Net;
--            lv_Inventory_Detail_Notes_1 := lv_Inventory_Detail_Notes_O_H;
--
--            -- changes for June release - ruchhabr
--            lv_Quantity_On_Hand_1 := lv_Available_QtyOnHand_Net;
--         -- min ship time is 1 week and max ship time is 4 weeks if only on hand is available
--         ELSIF (    (lv_Available_QtyOnHand_Net > 0)
--                AND (lv_Available_QtyInTransit_Net = 0))
--         THEN
--            lv_Lead_Time_1 := '1';
--            --lv_Lead_Time_2 := '4';
--            --lv_Lead_Time_Count := 2;
--
--            lv_Available_Quantity_Net_1 := lv_Available_QtyOnHand_Net;
--            /*lv_Available_Quantity_Net_2 :=
--               lv_Requested_Qty - lv_Available_QtyOnHand_Net;*/
--            lv_Inventory_Detail_Notes_1 := lv_Inventory_Detail_Notes_O_H;
--
--            -- changes for June release - ruchhabr
--            lv_Quantity_On_Hand_1 := lv_Available_QtyOnHand_Net;
--            lv_Quantity_In_Transit_1 := '0';
--         -- min ship time is 1 week and max ship time is 4-6 weeks if both on hand and in transit available
--         ELSIF (    (lv_Available_QtyOnHand_Net > 0)
--                AND (lv_Available_QtyInTransit_Net > 0))
--         THEN
--            lv_Lead_Time_1 := '1';
--            lv_Lead_Time_2 := '4-6';
--            lv_Lead_Time_Count := 2;
--
--            lv_Available_Quantity_Net_1 := lv_Available_QtyOnHand_Net;
--            lv_Available_Quantity_Net_2 := lv_Available_QtyInTransit_Net;
--            /*lv_Available_Quantity_Net_2 :=
--               lv_Requested_Qty - lv_Available_QtyOnHand_Net;*/
--            lv_Inventory_Detail_Notes_1 := lv_Inventory_Detail_Notes_O_H;
--            lv_Inventory_Detail_Notes_2 := lv_Inventory_Detail_Notes_I_T;
--
--            -- changes for June release - ruchhabr
--            lv_Quantity_On_Hand_1 := lv_Available_QtyOnHand_Net;
--            lv_Quantity_In_Transit_2 := lv_Available_QtyInTransit_Net;
--         -- min ship time is 4-6 weeks if only in transit available
--         ELSIF (    (lv_Available_QtyOnHand_Net = 0)
--                AND (lv_Available_QtyInTransit_Net > 0))
--         THEN
--            lv_Lead_Time_1 := '4-6';
--
--            --lv_Available_Quantity_Net_1 := lv_Available_Quantity;
--            lv_Available_Quantity_Net_1 := lv_Available_QtyInTransit_Net;
--            lv_Inventory_Detail_Notes_1 := lv_Inventory_Detail_Notes_I_T;
--
--            -- changes for June release - ruchhabr
--            lv_Quantity_On_Hand_1 := 0;
--            lv_Quantity_In_Transit_1 := lv_Available_QtyInTransit_Net;
--         END IF;
--
--
--         o_Lead_Time_1 := lv_Lead_Time_1;
--         o_Lead_Time_2 := lv_Lead_Time_2;
--         o_Lead_Time_Count := lv_Lead_Time_Count;
--         o_Available_Quantity_Net_1 := lv_Available_Quantity_Net_1;
--         o_Available_Quantity_Net_2 := lv_Available_Quantity_Net_2;
--         o_Inventory_Detail_Notes_1 := lv_Inventory_Detail_Notes_1;
--         o_Inventory_Detail_Notes_2 := lv_Inventory_Detail_Notes_2;
--         -- End of code changes done by Infosys for April 2014 release -- ruchhabr
--
--         -- changes for June release - ruchhabr
--         o_Quantity_On_Hand_1 := lv_Quantity_On_Hand_1;
--         o_Quantity_In_Transit_1 := lv_Quantity_In_Transit_1;
--         o_Quantity_On_Hand_2 := lv_Quantity_On_Hand_2;
--         o_Quantity_In_Transit_2 := lv_Quantity_In_Transit_2;
--
--
--         o_FG_Only := lv_Available_Quantity_FG;
--
--         -- NET AVAILABLE
--         --o_Available_Quantity := lv_Available_Quantity;
--
--         -- GROSS AVAILABLE =  lv_Available_Quantity_FG + lv_Available_Quantity_WS + lv_Available_Quantity_POE;
--
--         -- if available qty is -ve, set it to 0
--         /*IF (o_Available_Quantity < 0)
--         THEN
--            o_Available_Quantity := 0;
--         END IF;*/
--
--         --Code commented since all location may or may not be selected. Logic is now moved to UI.
--         -- Logic to generate Inventory notes for local region
--         /*FOR idx IN 1 .. v_Final_Inventory_Return_List.COUNT ()
--         LOOP
--            lv_Z_Location :=
--               SUBSTR (v_Final_Inventory_Return_List (idx).INVENTORY_SITE,
--                       1,
--                       3);
--
--            IF (idx > 1)
--            THEN
--               lv_Inventory_Detail_Notes := lv_Inventory_Detail_Notes || ', ';
--            END IF;
--
--            lv_Inventory_Detail_Notes :=
--                  lv_Inventory_Detail_Notes
--               || lv_Z_Location
--               || '-'
--               || v_Final_Inventory_Return_List (idx).INVENTORY_LOCATION
--               || ' ('
--               || v_Final_Inventory_Return_List (idx).TOTAL_AVAILABLE
--               || ')';
--         END LOOP;*/
--
--         --o_Inventory_Detail_Notes := lv_Inventory_Detail_Notes;
--         o_Inventory_Detail_List_Local := v_Final_Inventory_Return_List; --v_Final_Inventory_Return_List;
--
--         -- Start of code changes done by Infosys for April 2014 release -- ruchhabr
--         /*CASE
--            -- REQUESTED QUANTITY SATISFIED FROM FG ITSELF
--            WHEN lv_Lead_Time = 1
--            THEN
--               o_Available_RF := v_Empty_String || lv_Available_Quantity_RF;
--               o_Available_WS :=
--                     v_Empty_String
--                  || (lv_Available_Quantity_FG + lv_Available_Quantity_WS);
--               o_Available_POE := v_Not_Applicable;
--            -- REQUESTED QUANTITY SATISFIED FROM FG + WS ITSELF
--            WHEN lv_Lead_Time = 2
--            THEN
--               o_Available_RF := v_Empty_String || lv_Available_Quantity_RF;
--               o_Available_WS :=
--                     v_Empty_String
--                  || (lv_Available_Quantity_FG + lv_Available_Quantity_WS);
--               o_Available_POE := v_Not_Applicable;
--            -- REQUESTED QUANTITY SATISFIED FROM FG + WS + POE
--            WHEN lv_Lead_Time = 3
--            THEN
--               o_Available_RF := v_Empty_String || lv_Available_Quantity_RF;
--               o_Available_WS :=
--                     v_Empty_String
--                  || (lv_Available_Quantity_FG + lv_Available_Quantity_WS);
--               o_Available_POE := v_Empty_String || lv_Available_Quantity_POE;
--            ELSE
--               o_Available_RF := v_Empty_String || lv_Available_Quantity_RF;
--               o_Available_WS :=
--                     v_Empty_String
--                  || (lv_Available_Quantity_FG + lv_Available_Quantity_WS);
--               o_Available_POE := v_Empty_String || lv_Available_Quantity_POE;
--         END CASE;
--
--         -- ADDED to change the lead time 3 to 2 EVEN if POE Locations are included.
--
--         IF lv_Lead_Time = 3
--         THEN
--            lv_Lead_Time := 2;
--         END IF;
--         */
--
--         o_Available_RF := v_Empty_String || lv_Available_Quantity_RF;
--         o_Available_WS :=
--               v_Empty_String
--            || (lv_Available_Quantity_FG + lv_Available_Quantity_WS);
--         o_Available_POE := v_Empty_String || lv_Available_Quantity_POE;
--         --  End of code changes done by Infosys for April 2014 release  -- ruchhabr
--
--         --o_Lead_Time := lv_Lead_Time_1;
--
--         o_Reservation_POE_For_RF := lv_RF_Reduce_From_POE;
--
--         -- Start of code changes done by Infosys for April 2014 release -- ravchitt
--         -- Step 4.0 If requested quantity not fulfilled by Local region, get inventory details for Foreign Region
--         --IF (i_Requested_Qty > lv_Available_Quantity)
--         -- THEN
--         -- Step 4.1 Get inventory for foreign region
--         BEGIN
--            IF (lv_Conflicting_Part_Count > 1)
--            THEN
--               -- Start of code changes done by Infosys for April 2014 release -- ruchhabr
--               /*SELECT WCT_INVENTORY_DETAIL_OBJECT (
--                         SITE,
--                         LOCATION,
--                         QTY_ON_HAND,
--                         QTY_IN_TRANSIT,
--                         '100',
--                         QTY_ON_HAND + QTY_IN_TRANSIT,
--                         NULL)                     -- NULL FOR LOCATION TYPE
--                 BULK COLLECT INTO v_Inventory_Detail_List_Frn
--                 FROM RSCM_ML_C3_INV_MV
--                WHERE     1 = 1
--                      AND (   PART_NUMBER = lv_Conflicting_Part_Id
--                           OR PART_NUMBER = lv_Conflicting_Part_WS)
--                      AND LOCATION IN
--                             (SELECT DESTINATION_SUBINVENTORY
--                                FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                               WHERE     1 = 1
--                                     AND (   PROGRAM_TYPE = 1
--                                          OR PROGRAM_TYPE = 2) -- FOR 1= WHOLESALE, 2= DGI locations
--                                     AND IS_NETTABLE = 1
--                                     AND IS_ENABLE = 1)
--                      --AND LOCATION <> 'FG' -- excluding FG location as items in this location are from ML
--                      AND LOCATION NOT IN ('FG', 'WS-FGSLD') -- excluding FG and WS-FGSLD location as items in this location are from ML
--                      AND SUBSTR (SITE, 1, 3) IN
--                             (SELECT ZLOC
--                                FROM VV_ADM_ZLOCATION_TABLE
--                               WHERE REGION_NAME = i_Region_Foreign)
--             ORDER BY LOCATION DESC;*/
--
--               /*SELECT WCT_INVENTORY_DETAIL_OBJECT (SITE,
--                                                   LOCATION,
--                                                   QTY_ON_HAND,
--                                                   QTY_IN_TRANSIT,
--                                                   NULL, -- NULL FOR YIELD_FACTOR
--                                                   TOTAL_AVAILABLE,
--                                                   NULL, -- NULL FOR LOCATION TYPE
--                                                   v_Flag_No) -- NO FOR SELECTED
--                 BULK COLLECT INTO v_Inventory_Detail_List_Frn
--                 FROM (  SELECT SITE,
--                                LOCATION,
--                                SUM (QTY_ON_HAND) AS QTY_ON_HAND,
--                                SUM (QTY_IN_TRANSIT) AS QTY_IN_TRANSIT,
--                                SUM (QTY_ON_HAND + QTY_IN_TRANSIT)
--                                   AS TOTAL_AVAILABLE
--                           FROM RSCM_ML_C3_INV_MV
--                          WHERE     1 = 1
--                                AND (   PART_NUMBER = lv_Conflicting_Part_Id
--                                     OR PART_NUMBER = lv_Conflicting_Part_WS)
--                                AND LOCATION IN
--                                       (SELECT DESTINATION_SUBINVENTORY
--                                          FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                                         WHERE     1 = 1
--                                               AND (   PROGRAM_TYPE = 1
--                                                    OR PROGRAM_TYPE = 2) -- FOR 1= WHOLESALE, 2= DGI locations
--                                               AND IS_NETTABLE = 1
--                                               AND IS_ENABLE = 1)
--                                --AND LOCATION <> 'FG' -- excluding FG location as items in this location are from ML
--                                AND LOCATION NOT IN ('FG', 'WS-FGSLD') -- excluding FG and WS-FGSLD location as items in this location are from ML
--                                AND SUBSTR (SITE, 1, 3) IN
--                                       (SELECT ZLOC
--                                          FROM VV_ADM_ZLOCATION_TABLE
--                                         WHERE REGION_NAME = i_Region_Foreign)
--                       GROUP BY SITE, LOCATION
--                       ORDER BY SITE);*/
--
--               SELECT WCT_INVENTORY_DETAIL_OBJECT (
--                         SITE,
--                         LOC,
--                         QTY_ON_HAND,
--                         QTY_IN_TRANSIT,
--                         CASE
--                            WHEN (NVL (yield, 80) = 0) THEN 80
--                            ELSE NVL (yield, 80)
--                         END,
--                         NULL,                     -- NULL FOR TOTAL_AVAILABLE
--                         NULL,                       -- NULL FOR LOCATION TYPE
--                         v_Flag_No)                         -- NO FOR SELECTED
--                 BULK COLLECT INTO v_Inventory_Detail_List_F
--                 FROM (  SELECT SITE,
--                                MV.LOCATION LOC,
--                                QTY_ON_HAND,
--                                QTY_IN_TRANSIT,
--                                CASE
--                                   WHEN SCM.DESTINATION_SUBINVENTORY IS NULL
--                                   THEN
--                                      100
--                                   ELSE
--                                      PM_PROD.rm_yield
--                                END
--                                   AS yield
--                           FROM (  SELECT PRODUCT_NAME_STRIPPED,
--                                          SITE,
--                                          REGION,
--                                          LOCATION,
--                                          SUM (QTY_ON_HAND) QTY_ON_HAND,
--                                          0 QTY_IN_TRANSIT,
--                                          NULL TOTAL_AVAILABLE
--                                     FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                                    WHERE     1 = 1
--                                          AND (   PART_NUMBER =
--                                                     lv_Conflicting_Part_Id
--                                               OR PART_NUMBER =
--                                                     lv_Conflicting_Part_WS)
--                                 GROUP BY PRODUCT_NAME_STRIPPED,
--                                          SITE,
--                                          REGION,
--                                          LOCATION
--                                 UNION
--                                   SELECT PRODUCT_NAME_STRIPPED,
--                                          SITE,
--                                          REGION,
--                                          LOCATION,
--                                          0 QTY_ON_HAND,
--                                          SUM (QTY_IN_TRANSIT),
--                                          NULL TOTAL_AVAILABLE
--                                     FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                                    WHERE     1 = 1
--                                          AND (   PART_NUMBER =
--                                                     lv_Conflicting_Part_Id
--                                               OR PART_NUMBER =
--                                                     lv_Conflicting_Part_WS)
--                                 GROUP BY PRODUCT_NAME_STRIPPED,
--                                          SITE,
--                                          REGION,
--                                          LOCATION) MV
--                                LEFT OUTER JOIN
--                                VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
--                                   ON     PM_PROD.product_name_stripped =
--                                             MV.product_name_stripped
--                                      AND PM_PROD.REGION_NAME = MV.REGION
--                                LEFT OUTER JOIN
--                                VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP SCM
--                                   ON     MV.LOCATION =
--                                             SCM.DESTINATION_SUBINVENTORY
--                                      AND SCM.YIELD_WS = 'YES'
--                          WHERE     1 = 1
--                                AND (QTY_ON_HAND > 0 OR QTY_IN_TRANSIT > 0)
--                                AND MV.LOCATION IN (SELECT DESTINATION_SUBINVENTORY
--                                                      FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                                                     WHERE     1 = 1
--                                                           AND (   PROGRAM_TYPE =
--                                                                      1
--                                                                OR PROGRAM_TYPE =
--                                                                      2) -- FOR 1= WHOLESALE, 2= DGI locations
--                                                           AND IS_NETTABLE = 1
--                                                           AND IS_ENABLE = 1)
--                                AND MV.LOCATION NOT IN ('FG',
--                                                        'WS-FGSLD',
--                                                        'RF-W-RHS',
--                                                        'RF-W-OEM',
--                                                        'RF-WIP',
--                                                        'WS-WIP') -- excluding FG and WS-FGSLD location, WIP location as items in this location are from ML
--                                AND SUBSTR (SITE, 1, 3) IN (SELECT ZLOC
--                                                              FROM VAVNI_CISCO_RSCM_ADMIN.VV_ADM_ZLOCATION_TABLE
--                                                             WHERE REGION_NAME =
--                                                                      i_Region_Foreign)
--                       ORDER BY SITE, LOC DESC, QTY_ON_HAND DESC);
--
--               /* Start changes to include FG inventory Aug 2016 */
--
--               SELECT WCT_INVENTORY_DETAIL_OBJECT (SITE,
--                                                   LOC,
--                                                   QTY_ON_HAND,
--                                                   QTY_IN_TRANSIT,
--                                                   yield, -- NULL FOR YIELD_FACTOR
--                                                   NULL, -- NULL FOR TOTAL_AVAILABLE
--                                                   NULL, -- NULL FOR LOCATION TYPE
--                                                   v_Flag_No) -- NO FOR SELECTED
--                 BULK COLLECT INTO v_Inventory_Detail_List_Frn_FG
--                 FROM (  SELECT SITE,
--                                MV.LOCATION LOC,
--                                QTY_ON_HAND,
--                                QTY_IN_TRANSIT,
--                                '100' AS yield
--                           FROM (  SELECT PRODUCT_NAME_STRIPPED,
--                                          SITE,
--                                          REGION,
--                                          LOCATION,
--                                          SUM (QTY_ON_HAND) QTY_ON_HAND,
--                                          0 QTY_IN_TRANSIT,
--                                          NULL TOTAL_AVAILABLE
--                                     FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                                    WHERE     1 = 1
--                                          AND (   PART_NUMBER =
--                                                     lv_Conflicting_Part_Id
--                                               OR PART_NUMBER =
--                                                     lv_Conflicting_Part_WS)
--                                          AND REGION = i_Region_Foreign
--                                          AND PRODUCT_FAMILY LIKE '%WHLSALE%'
--                                 GROUP BY PRODUCT_NAME_STRIPPED,
--                                          SITE,
--                                          REGION,
--                                          LOCATION
--                                 UNION
--                                   SELECT PRODUCT_NAME_STRIPPED,
--                                          SITE,
--                                          REGION,
--                                          LOCATION,
--                                          0 QTY_ON_HAND,
--                                          SUM (QTY_IN_TRANSIT),
--                                          NULL TOTAL_AVAILABLE
--                                     FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                                    WHERE     1 = 1
--                                          AND (   PART_NUMBER =
--                                                     lv_Conflicting_Part_Id
--                                               OR PART_NUMBER =
--                                                     lv_Conflicting_Part_WS)
--                                          AND REGION = i_Region_Foreign
--                                          AND PRODUCT_FAMILY LIKE '%WHLSALE%'
--                                 GROUP BY PRODUCT_NAME_STRIPPED,
--                                          SITE,
--                                          REGION,
--                                          LOCATION) MV
--                                LEFT OUTER JOIN
--                                VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
--                                   ON     PM_PROD.product_name_stripped =
--                                             MV.product_name_stripped
--                                      AND PM_PROD.REGION_NAME = MV.REGION
--                          --
--                          WHERE     1 = 1
--                                AND (QTY_ON_HAND > 0 OR QTY_IN_TRANSIT > 0)
--                                AND MV.LOCATION = 'FG'       -- include FG inv
--                       --
--                       ORDER BY SITE, LOC DESC, QTY_ON_HAND DESC);
--            -- End of code changes done by Infosys for April 2014 release -- ruchhabr
--            ELSE
--               -- Start of code changes done by Infosys for April 2014 release -- ruchhabr
--               /*SELECT WCT_INVENTORY_DETAIL_OBJECT (
--                         SITE,
--                         LOCATION,
--                         QTY_ON_HAND,
--                         QTY_IN_TRANSIT,
--                         '100',
--                         QTY_ON_HAND + QTY_IN_TRANSIT,
--                         NULL)                     -- NULL FOR LOCATION TYPE
--                 BULK COLLECT INTO v_Inventory_Detail_List_Frn
--                 FROM RSCM_ML_C3_INV_MV
--                WHERE     1 = 1
--                      AND (   PRODUCT_NAME_STRIPPED LIKE
--                                 lv_Product_Name_Stripped_WS
--                           OR PRODUCT_NAME_STRIPPED LIKE
--                                 lv_Product_Name_Stripped)
--                      AND LOCATION IN
--                             (SELECT DESTINATION_SUBINVENTORY
--                                FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                               WHERE     1 = 1
--                                     AND (   PROGRAM_TYPE = 1
--                                          OR PROGRAM_TYPE = 2) -- FOR 1= WHOLESALE, 2= DGI locations
--                                     AND IS_NETTABLE = 1
--                                     AND IS_ENABLE = 1)
--                      --AND LOCATION <> 'FG' -- excluding FG location as items in this location are from ML
--                      AND LOCATION NOT IN ('FG', 'WS-FGSLD') -- excluding FG and WS-FGSLD location as items in this location are from ML
--                      AND SUBSTR (SITE, 1, 3) IN
--                             (SELECT ZLOC
--                                FROM VV_ADM_ZLOCATION_TABLE
--                               WHERE REGION_NAME = i_Region_Foreign)
--             ORDER BY LOCATION DESC;*/
--
--               /*SELECT WCT_INVENTORY_DETAIL_OBJECT (SITE,
--                                                   LOCATION,
--                                                   QTY_ON_HAND,
--                                                   QTY_IN_TRANSIT,
--                                                   NULL, -- NULL FOR YIELD_FACTOR
--                                                   TOTAL_AVAILABLE,
--                                                   NULL, -- NULL FOR LOCATION TYPE
--                                                   v_Flag_No) -- NO FOR SELECTED
--                 BULK COLLECT INTO v_Inventory_Detail_List_Frn
--                 FROM (  SELECT SITE,
--                                LOCATION,
--                                SUM (QTY_ON_HAND) AS QTY_ON_HAND,
--                                SUM (QTY_IN_TRANSIT) AS QTY_IN_TRANSIT,
--                                SUM (QTY_ON_HAND + QTY_IN_TRANSIT)
--                                   AS TOTAL_AVAILABLE
--                           FROM RSCM_ML_C3_INV_MV
--                          WHERE     1 = 1
--                                AND (   PRODUCT_NAME_STRIPPED LIKE
--                                           lv_Product_Name_Stripped_WS
--                                     OR PRODUCT_NAME_STRIPPED LIKE
--                                           lv_Product_Name_Stripped)
--                                AND LOCATION IN
--                                       (SELECT DESTINATION_SUBINVENTORY
--                                          FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                                         WHERE     1 = 1
--                                               AND (   PROGRAM_TYPE = 1
--                                                    OR PROGRAM_TYPE = 2) -- FOR 1= WHOLESALE, 2= DGI locations
--                                               AND IS_NETTABLE = 1
--                                               AND IS_ENABLE = 1)
--                                --AND LOCATION <> 'FG' -- excluding FG location as items in this location are from ML
--                                AND LOCATION NOT IN ('FG', 'WS-FGSLD') -- excluding FG and WS-FGSLD location as items in this location are from ML
--                                AND SUBSTR (SITE, 1, 3) IN
--                                       (SELECT ZLOC
--                                          FROM VV_ADM_ZLOCATION_TABLE
--                                         WHERE REGION_NAME = i_Region_Foreign)
--                       GROUP BY SITE, LOCATION
--                       ORDER BY SITE);*/
--
--
--               SELECT WCT_INVENTORY_DETAIL_OBJECT (
--                         SITE,
--                         LOC,
--                         QTY_ON_HAND,
--                         QTY_IN_TRANSIT,
--                         CASE                          --changes made cbharath
--                            WHEN (NVL (yield, 80) = 0) THEN 80
--                            ELSE NVL (yield, 80)
--                         END,
--                         NULL,                     -- NULL FOR TOTAL_AVAILABLE
--                         NULL,                       -- NULL FOR LOCATION TYPE
--                         v_Flag_No)                         -- NO FOR SELECTED
--                 BULK COLLECT INTO v_Inventory_Detail_List_F
--                 FROM (  SELECT SITE,
--                                MV.LOCATION LOC,
--                                QTY_ON_HAND,
--                                QTY_IN_TRANSIT,
--                                CASE
--                                   WHEN SCM.DESTINATION_SUBINVENTORY IS NULL
--                                   THEN
--                                      100
--                                   ELSE
--                                      PM_PROD.rm_yield
--                                END
--                                   AS yield
--                           FROM (  SELECT product_name_stripped,
--                                          SITE,
--                                          REGION,
--                                          LOCATION,
--                                          SUM (QTY_ON_HAND) QTY_ON_HAND,
--                                          0 QTY_IN_TRANSIT,
--                                          NULL TOTAL_AVAILABLE
--                                     FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                                    WHERE     1 = 1
--                                          AND (   PRODUCT_NAME_STRIPPED LIKE
--                                                     lv_Product_Name_Stripped_WS
--                                               OR PRODUCT_NAME_STRIPPED LIKE
--                                                     lv_Product_Name_Stripped
--                                               OR PRODUCT_NAME_STRIPPED IN --added for showing all locations
--                                                                           (lv_Product_Name_Stripped_WS,
--                                                                            SUBSTR (
--                                                                               lv_Product_Name_Stripped_WS,
--                                                                               1,
--                                                                                 LENGTH (
--                                                                                    lv_Product_Name_Stripped_WS)
--                                                                               - 2))
--                                               OR PRODUCT_NAME_STRIPPED IN --add
--                                                                           (lv_Product_Name_Stripped_WS,
--                                                                               SUBSTR (
--                                                                                  lv_Product_Name_Stripped_WS,
--                                                                                  1,
--                                                                                    LENGTH (
--                                                                                       lv_Product_Name_Stripped_WS)
--                                                                                  - 2)
--                                                                            || 'RL')) --ended
--                                 GROUP BY product_name_stripped,
--                                          SITE,
--                                          REGION,
--                                          LOCATION
--                                 UNION
--                                   SELECT product_name_stripped,
--                                          SITE,
--                                          REGION,
--                                          LOCATION,
--                                          0 QTY_ON_HAND,
--                                          SUM (QTY_IN_TRANSIT),
--                                          NULL TOTAL_AVAILABLE
--                                     FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                                    WHERE     1 = 1
--                                          AND (   PRODUCT_NAME_STRIPPED LIKE
--                                                     lv_Product_Name_Stripped_WS
--                                               OR PRODUCT_NAME_STRIPPED LIKE
--                                                     lv_Product_Name_Stripped
--                                               OR PRODUCT_NAME_STRIPPED IN --added for showing all locations
--                                                                           (lv_Product_Name_Stripped_WS,
--                                                                            SUBSTR (
--                                                                               lv_Product_Name_Stripped_WS,
--                                                                               1,
--                                                                                 LENGTH (
--                                                                                    lv_Product_Name_Stripped_WS)
--                                                                               - 2))
--                                               OR PRODUCT_NAME_STRIPPED IN --add
--                                                                           (lv_Product_Name_Stripped_WS,
--                                                                               SUBSTR (
--                                                                                  lv_Product_Name_Stripped_WS,
--                                                                                  1,
--                                                                                    LENGTH (
--                                                                                       lv_Product_Name_Stripped_WS)
--                                                                                  - 2)
--                                                                            || 'RL')) --ended
--                                 GROUP BY product_name_stripped,
--                                          SITE,
--                                          REGION,
--                                          LOCATION) MV
--                                LEFT OUTER JOIN
--                                VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
--                                   ON     PM_PROD.product_name_stripped =
--                                             MV.product_name_stripped
--                                      AND PM_PROD.REGION_NAME = MV.REGION
--                                LEFT OUTER JOIN
--                                VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP SCM
--                                   ON     MV.LOCATION =
--                                             SCM.DESTINATION_SUBINVENTORY
--                                      AND SCM.YIELD_WS = 'YES'
--                          WHERE     1 = 1
--                                AND (QTY_ON_HAND > 0 OR QTY_IN_TRANSIT > 0)
--                                AND MV.LOCATION IN (SELECT DESTINATION_SUBINVENTORY
--                                                      FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                                                     WHERE     1 = 1
--                                                           AND (   PROGRAM_TYPE =
--                                                                      1
--                                                                OR PROGRAM_TYPE =
--                                                                      2) -- FOR 1= WHOLESALE, 2= DGI locations
--                                                           AND IS_NETTABLE = 1
--                                                           AND IS_ENABLE = 1)
--                                AND MV.LOCATION NOT IN ('FG',
--                                                        'WS-FGSLD',
--                                                        'RF-W-RHS',
--                                                        'RF-W-OEM',
--                                                        'RF-WIP',
--                                                        'WS-WIP') -- excluding FG and WS-FGSLD location, WIP location as items in this location are from ML
--                                AND SUBSTR (SITE, 1, 3) IN (SELECT ZLOC
--                                                              FROM VAVNI_CISCO_RSCM_ADMIN.VV_ADM_ZLOCATION_TABLE
--                                                             WHERE REGION_NAME =
--                                                                      i_Region_Foreign)
--                       ORDER BY SITE, LOC DESC, QTY_ON_HAND DESC);
--
--               /* Start changes to include FG inventory Aug 2016 */
--
--               SELECT WCT_INVENTORY_DETAIL_OBJECT (SITE,
--                                                   LOC,
--                                                   QTY_ON_HAND,
--                                                   QTY_IN_TRANSIT,
--                                                   yield,
--                                                   NULL, -- NULL FOR TOTAL_AVAILABLE
--                                                   NULL, -- NULL FOR LOCATION TYPE
--                                                   v_Flag_No) -- NO FOR SELECTED
--                 BULK COLLECT INTO v_Inventory_Detail_List_Frn_FG
--                 FROM (  SELECT SITE,
--                                MV.LOCATION LOC,
--                                QTY_ON_HAND,
--                                QTY_IN_TRANSIT,
--                                '100' AS yield
--                           FROM (  SELECT product_name_stripped,
--                                          SITE,
--                                          REGION,
--                                          LOCATION,
--                                          SUM (QTY_ON_HAND) QTY_ON_HAND,
--                                          0 QTY_IN_TRANSIT,
--                                          NULL TOTAL_AVAILABLE
--                                     FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                                    WHERE     1 = 1
--                                          AND (   PRODUCT_NAME_STRIPPED LIKE
--                                                     lv_Product_Name_Stripped_WS
--                                               OR PRODUCT_NAME_STRIPPED LIKE
--                                                     lv_Product_Name_Stripped
--                                               OR PRODUCT_NAME_STRIPPED IN --added for showing all locations
--                                                                           (lv_Product_Name_Stripped_WS,
--                                                                            SUBSTR (
--                                                                               lv_Product_Name_Stripped_WS,
--                                                                               1,
--                                                                                 LENGTH (
--                                                                                    lv_Product_Name_Stripped_WS)
--                                                                               - 2))
--                                               OR PRODUCT_NAME_STRIPPED IN --add
--                                                                           (lv_Product_Name_Stripped_WS,
--                                                                               SUBSTR (
--                                                                                  lv_Product_Name_Stripped_WS,
--                                                                                  1,
--                                                                                    LENGTH (
--                                                                                       lv_Product_Name_Stripped_WS)
--                                                                                  - 2)
--                                                                            || 'RL'))
--                                          AND REGION = i_Region_Foreign
--                                          AND PRODUCT_FAMILY LIKE '%WHLSALE%' --ended
--                                 GROUP BY product_name_stripped,
--                                          SITE,
--                                          REGION,
--                                          LOCATION
--                                 UNION
--                                   SELECT product_name_stripped,
--                                          SITE,
--                                          REGION,
--                                          LOCATION,
--                                          0 QTY_ON_HAND,
--                                          SUM (QTY_IN_TRANSIT),
--                                          NULL TOTAL_AVAILABLE
--                                     FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--                                    WHERE     1 = 1
--                                          AND (   PRODUCT_NAME_STRIPPED LIKE
--                                                     lv_Product_Name_Stripped_WS
--                                               OR PRODUCT_NAME_STRIPPED LIKE
--                                                     lv_Product_Name_Stripped
--                                               OR PRODUCT_NAME_STRIPPED IN --added for showing all locations
--                                                                           (lv_Product_Name_Stripped_WS,
--                                                                            SUBSTR (
--                                                                               lv_Product_Name_Stripped_WS,
--                                                                               1,
--                                                                                 LENGTH (
--                                                                                    lv_Product_Name_Stripped_WS)
--                                                                               - 2))
--                                               OR PRODUCT_NAME_STRIPPED IN --add
--                                                                           (lv_Product_Name_Stripped_WS,
--                                                                               SUBSTR (
--                                                                                  lv_Product_Name_Stripped_WS,
--                                                                                  1,
--                                                                                    LENGTH (
--                                                                                       lv_Product_Name_Stripped_WS)
--                                                                                  - 2)
--                                                                            || 'RL'))
--                                          AND REGION = i_Region_Foreign
--                                          AND PRODUCT_FAMILY LIKE '%WHLSALE%' --ended
--                                 GROUP BY product_name_stripped,
--                                          SITE,
--                                          REGION,
--                                          LOCATION) MV
--                                LEFT OUTER JOIN
--                                VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
--                                   ON     PM_PROD.product_name_stripped =
--                                             MV.product_name_stripped
--                                      AND PM_PROD.REGION_NAME = MV.REGION
--                          WHERE     1 = 1
--                                AND (QTY_ON_HAND > 0 OR QTY_IN_TRANSIT > 0)
--                                AND MV.LOCATION = 'FG'       -- include FG inv
--                       ORDER BY SITE, LOC DESC, QTY_ON_HAND DESC);
--            -- End of code changes done by Infosys for April 2014 release -- ruchhabr
--            END IF;
--         EXCEPTION
--            WHEN NO_DATA_FOUND
--            THEN
--               o_Inventory_Detail_List_Frn := NULL;
--
--               --LOG EXCEPTION
--               INSERT INTO WCT_ERROR_LOG
--                       VALUES (
--                                 UPPER (lv_Requested_Part),
--                                 lv_User_Id,
--                                 'COMPUTE_INV_AND_AVAILABLE_QTY - Step 4.1 - No data found',
--                                 SYSDATE);
--            WHEN OTHERS
--            THEN
--               --LOG EXCEPTION
--               v_Error_Message := NULL;
--               v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--               INSERT INTO WCT_ERROR_LOG
--                       VALUES (
--                                 UPPER (lv_Requested_Part),
--                                 lv_User_Id,
--                                    'COMPUTE_INV_AND_AVAILABLE_QTY - Step 4.1 - '
--                                 || v_Error_Message,
--                                 SYSDATE);
--         END;
--
--         --  End of code changes done by Infosys for April 2014 release  -- ravchitt
--
--         /* Start changes to include FG inventory Aug 2016 */
--
--         lv_Inventory_WS_FGI_Count_Frn := 0;
--
--         -- v_Inventory_Detail_List_Frn.COUNT ();
--
--         FOR i IN 1 .. v_Inventory_Detail_List_Frn_FG.COUNT ()
--         LOOP
--            lv_Inventory_WS_FGI_Count_Frn := lv_Inventory_WS_FGI_Count_Frn + 1;
--            v_Inventory_Detail_List_Frn.EXTEND ();
--            v_Inventory_Detail_List_Frn (lv_Inventory_WS_FGI_Count_Frn) :=
--               v_Inventory_Detail_List_Frn_FG (i);
--         END LOOP;
--
--         FOR i IN 1 .. v_Inventory_Detail_List_F.COUNT ()
--         LOOP
--            lv_Inventory_WS_FGI_Count_Frn := lv_Inventory_WS_FGI_Count_Frn + 1;
--            v_Inventory_Detail_List_Frn.EXTEND ();
--            v_Inventory_Detail_List_Frn (lv_Inventory_WS_FGI_Count_Frn) :=
--               v_Inventory_Detail_List_F (i);
--         END LOOP;
--
--
--
--         -- Step 4.3 Update yeild factor and location type for all ocations
--         BEGIN
--            FOR i IN 1 .. v_Inventory_Detail_List_Frn.COUNT ()
--            LOOP
--               lv_Location :=
--                  v_Inventory_Detail_List_Frn (i).INVENTORY_LOCATION;
--               lv_Yield_Factor_Frn :=
--                  v_Inventory_Detail_List_Frn (i).YIELD_FACTOR;
--
--               IF (lv_Location = 'WS-FGI' OR lv_Location = 'FG') -- include FG inv
--               THEN
--                  lv_Available_Qty_On_Hand :=
--                     v_Inventory_Detail_List_Frn (i).ON_HAND;
--                  lv_Available_Qty_In_Transit :=
--                     v_Inventory_Detail_List_Frn (i).IN_TRANSIT;
--
--                  lv_Total_Available :=
--                     lv_Available_Qty_On_Hand + lv_Available_Qty_In_Transit;
--
--                  v_Inventory_Detail_List_Frn (i).TOTAL_AVAILABLE :=
--                     lv_Total_Available;
--
--                  v_Inventory_Detail_List_Frn (i).YIELD_FACTOR :=
--                     v_Not_Applicable;
--                  v_Inventory_Detail_List_Frn (i).LOCATION_TYPE := 'FGI';
--               ELSIF (lv_Location LIKE 'WS%')
--               THEN
--                  v_Inventory_Detail_List_Frn (i).LOCATION_TYPE := 'WS';
--                  -- Start of code changes done by Infosys for April 2014 release -- karusing
--                  lv_Available_Qty_On_Hand :=
--                     v_Inventory_Detail_List_Frn (i).ON_HAND;
--                  lv_Available_Qty_In_Transit :=
--                     v_Inventory_Detail_List_Frn (i).IN_TRANSIT;
--
--                  lv_Available_Qty_On_Hand :=
--                     (lv_Available_Qty_On_Hand * lv_Yield_Factor_Frn) / 100;
--
--                  lv_Available_Qty_In_Transit :=
--                       (lv_Available_Qty_In_Transit * lv_Yield_Factor_Frn)
--                     / 100;
--
--                  lv_Available_Qty_On_Hand :=
--                     VV_RSCM_UTIL.GENERIC_ROUND_UTIL (
--                        lv_Available_Qty_On_Hand,
--                        1);
--
--                  lv_Available_Qty_In_Transit :=
--                     VV_RSCM_UTIL.GENERIC_ROUND_UTIL (
--                        lv_Available_Qty_In_Transit,
--                        1);
--
--                  lv_Total_Available :=
--                     lv_Available_Qty_On_Hand + lv_Available_Qty_In_Transit;
--
--                  v_Inventory_Detail_List_Frn (i).TOTAL_AVAILABLE :=
--                     lv_Total_Available;
--               -- End of code changes done by Infosys for April 2014 release -- karusing
--               ELSIF (lv_Location LIKE 'POE%')
--               THEN
--                  v_Inventory_Detail_List_Frn (i).LOCATION_TYPE := 'POE';
--                  -- Start of code changes done by Infosys for April 2014 release -- karusing
--                  lv_Available_Qty_On_Hand :=
--                     v_Inventory_Detail_List_Frn (i).ON_HAND;
--                  lv_Available_Qty_In_Transit :=
--                     v_Inventory_Detail_List_Frn (i).IN_TRANSIT;
--
--                  lv_Available_Qty_On_Hand :=
--                     (lv_Available_Qty_On_Hand * lv_Yield_Factor_Frn) / 100;
--
--                  lv_Available_Qty_In_Transit :=
--                       (lv_Available_Qty_In_Transit * lv_Yield_Factor_Frn)
--                     / 100;
--
--                  lv_Available_Qty_On_Hand :=
--                     VV_RSCM_UTIL.GENERIC_ROUND_UTIL (
--                        lv_Available_Qty_On_Hand,
--                        1);
--
--                  lv_Available_Qty_In_Transit :=
--                     VV_RSCM_UTIL.GENERIC_ROUND_UTIL (
--                        lv_Available_Qty_In_Transit,
--                        1);
--
--                  lv_Total_Available :=
--                     lv_Available_Qty_On_Hand + lv_Available_Qty_In_Transit;
--
--                  v_Inventory_Detail_List_Frn (i).TOTAL_AVAILABLE :=
--                     lv_Total_Available;
--               --changes ends --cbharath--06-05-2014
--
--               -- End of code changes done by Infosys for April 2014 release -- karusing
--
--               --End of code changes done for yeild factor calculations for foreign region  -- chaithra-18-04-2014
--               END IF;
--            END LOOP;
--         EXCEPTION
--            WHEN OTHERS
--            THEN
--               --LOG EXCEPTION
--               v_Error_Message := NULL;
--               v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--               INSERT INTO WCT_ERROR_LOG
--                       VALUES (
--                                 UPPER (lv_Requested_Part),
--                                 lv_User_Id,
--                                    'COMPUTE_INV_AND_AVAILABLE_QTY - Step 4.2 - '
--                                 || v_Error_Message,
--                                 SYSDATE);
--         END;
--
--         --END IF;
--
--         o_Inventory_Detail_List_Frn := v_Inventory_Detail_List_Frn;
--         o_Available_RF_Frn := lv_Available_Quantity_RF_Frn;
--      EXCEPTION
--         WHEN OTHERS
--         THEN
--            --LOG EXCEPTION
--            v_Error_Message := NULL;
--            v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--            INSERT INTO WCT_ERROR_LOG
--                    VALUES (
--                              UPPER (lv_Requested_Part),
--                              lv_User_Id,
--                                 'COMPUTE_INV_AND_AVAILABLE_QTY - Step Main - '
--                              || v_Error_Message,
--                              SYSDATE);
--      END;
--   END;

   /*PROCEDUTRE TO DETERMINE SELLING PRICE (CISCO OFFER)*/

   --Commented by satbanda on 20-Mar-2017 for validate PID logic <Start>
   /*
   PROCEDURE PRICING_ENGINE (i_Broker_Offer_Missing_Flag   IN     CHAR,
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
                             o_Static_Price_Exists            OUT CHAR)
   IS
      lv_Broker_Offer_Missing_Flag   CHAR;
      lv_Suggested_Price             NUMBER (15, 2);
      lv_Base_Price                  NUMBER (15, 2);
      lv_Recent_Price                NUMBER (15, 2);
      lv_Broker_Offer                NUMBER (15, 2);
      lv_Glp                         NUMBER (15, 2);
      lv_Base_Price_Discount         NUMBER;
      lv_Ext_Sell_Price              NUMBER (15, 2);
      lv_Available_Quantity          NUMBER;
      lv_Round_Scale                 NUMBER;

      lv_Requested_Part              VARCHAR2 (50);
      lv_Customer_Id                 NUMBER;
      lv_Static_Price                NUMBER (15, 2);
      lv_Static_Price_Exists         CHAR;
      lv_Region_Local                VARCHAR2 (4);
      --lv_Tier                        NUMBER (1);
      lv_base_price_available        CHAR;
      lv_base_price_for_customer     NUMBER (15, 2);
      lv_Product_Name_Stripped       VARCHAR2 (50);
      lv_Product_Name_Stripped_WS    VARCHAR2 (50);

       lv_Conflicting_Part_Count      NUMBER;
      lv_Conflicting_Part_Id         VARCHAR2 (50);
      lv_Conflicting_Part_WS         VARCHAR2 (50);
   BEGIN
      lv_Broker_Offer_Missing_Flag := i_Broker_Offer_Missing_Flag;
      lv_Recent_Price := i_Recent_Price;
      lv_Broker_Offer := i_Broker_Offer;
      lv_Glp := i_Glp;
      lv_Available_Quantity := i_Available_Quantity;
      lv_Base_Price_Discount := i_Base_Price_Discount;
      lv_Round_Scale := i_Round_Scale;

      lv_Region_Local := i_Region_Local;
      lv_Requested_Part := i_Requested_Part;
      lv_Customer_Id := i_Customer_Id;

      lv_Product_Name_Stripped := i_Product_Name_Stripped;
      lv_Product_Name_Stripped_WS := i_Product_Name_Stripped_WS;

      lv_Conflicting_Part_Count := i_Conflicting_Part_Count;
      lv_Conflicting_Part_Id := i_Conflicting_Part_Id;
      lv_Conflicting_Part_WS := i_Conflicting_Part_WS;


      --Step 1.0 Compute Base Price
      IF (lv_Glp = 0)
      THEN
         lv_Base_Price := 0;
      ELSE
         lv_Base_Price := (lv_Glp * (100.00 - lv_Base_Price_Discount)) / 100;
      END IF;

      IF (lv_Recent_Price = 0)
      THEN
         lv_Recent_Price := lv_Base_Price;
      END IF;

      --Step 2.0 Compute Suggested/Selling Price
      -- Check for Static Price
      GET_STATIC_PRICE_DETAILS (lv_Customer_Id,
                                lv_Product_Name_Stripped,
                                lv_Product_Name_Stripped_WS,
                                lv_Conflicting_Part_Count,
                                lv_Conflicting_Part_Id,
                                lv_Conflicting_Part_WS,
                                lv_Static_Price_Exists,
                                lv_Static_Price);

      -- Code moved to procedure GET_STATIC_PRICE_DETAILS
      /*BEGIN
         SELECT tier
           INTO lv_Tier
           FROM WCT_CUSTOMER cus, WCT_COMPANY_MASTER com
          WHERE     cus.COMPANY_ID = com.COMPANY_ID
                AND cus.CUSTOMER_ID = lv_Customer_Id;

         IF (lv_Conflicting_Part_Count > 1)
         THEN
            IF (lv_Tier = 1)
            THEN
               SELECT tier1
                 INTO lv_Static_Price
                 FROM WCT_STATIC_PRICE_MASTER
                WHERE     1 = 1
                      AND (   PRODUCT_ID = lv_Conflicting_Part_Id
                           OR PRODUCT_ID = lv_Conflicting_Part_WS)
                      AND ROWNUM = 1;

               lv_Static_Price_Exists := v_Flag_Yes;
            ELSIF (lv_Tier = 2)
            THEN
               SELECT tier2
                 INTO lv_Static_Price
                 FROM WCT_STATIC_PRICE_MASTER
                WHERE     1 = 1
                      AND (   PRODUCT_ID = lv_Conflicting_Part_Id
                           OR PRODUCT_ID = lv_Conflicting_Part_WS)
                      AND ROWNUM = 1;

               lv_Static_Price_Exists := v_Flag_Yes;
            ELSIF (lv_Tier = 3)
            THEN
               SELECT tier3
                 INTO lv_Static_Price
                 FROM WCT_STATIC_PRICE_MASTER
                WHERE     1 = 1
                      AND (   PRODUCT_ID = lv_Conflicting_Part_Id
                           OR PRODUCT_ID = lv_Conflicting_Part_WS)
                      AND ROWNUM = 1;

               lv_Static_Price_Exists := v_Flag_Yes;
            ELSE
               lv_Static_Price_Exists := v_Flag_No;
            END IF;
         ELSE
            IF (lv_Tier = 1)
            THEN
               SELECT tier1
                 INTO lv_Static_Price
                 FROM WCT_STATIC_PRICE_MASTER
                WHERE     1 = 1           --AND PRODUCT_ID = lv_Requested_Part
                      AND PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped
                      AND ROWNUM = 1;

               lv_Static_Price_Exists := v_Flag_Yes;
            ELSIF (lv_Tier = 2)
            THEN
               SELECT tier2
                 INTO lv_Static_Price
                 FROM WCT_STATIC_PRICE_MASTER
                WHERE     1 = 1           --AND PRODUCT_ID = lv_Requested_Part
                      AND PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped
                      AND ROWNUM = 1;

               lv_Static_Price_Exists := v_Flag_Yes;
            ELSIF (lv_Tier = 3)
            THEN
               SELECT tier3
                 INTO lv_Static_Price
                 FROM WCT_STATIC_PRICE_MASTER
                WHERE     1 = 1           --AND PRODUCT_ID = lv_Requested_Part
                      AND PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped
                      AND ROWNUM = 1;

               lv_Static_Price_Exists := v_Flag_Yes;
            ELSE
               lv_Static_Price_Exists := v_Flag_No;
            END IF;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_Static_Price_Exists := v_Flag_No;
      END; --


      BEGIN
         IF (lv_Conflicting_Part_Count > 1)
         THEN
            SELECT BASE_UNIT_PRICE
              INTO lv_base_price_for_customer
              FROM (SELECT SHP.BASE_UNIT_PRICE,
                           ROW_NUMBER ()
                              OVER (ORDER BY SHP.SALES_ORDER_DATE DESC)
                              RNO
                      FROM RMKTGADM.RMK_WS_AR_BACKLOG_SHIPMENT SHP
                     WHERE     1 = 1
                           AND (   PRODUCT_ID = lv_Conflicting_Part_Id
                                OR PRODUCT_ID = lv_Conflicting_Part_WS)
                           AND SHP.CUSTOMER_NAME =
                                  (SELECT COM.COMPANY_NAME
                                     FROM WCT_COMPANY_MASTER COM,
                                          WCT_CUSTOMER CUST
                                    WHERE     CUST.CUSTOMER_ID =
                                                 i_Customer_Id
                                          AND CUST.COMPANY_ID =
                                                 COM.COMPANY_ID))
             WHERE RNO = 1;
         ELSE
            SELECT BASE_UNIT_PRICE
              INTO lv_base_price_for_customer
              FROM (SELECT SHP.BASE_UNIT_PRICE,
                           ROW_NUMBER ()
                              OVER (ORDER BY SHP.SALES_ORDER_DATE DESC)
                              RNO
                      FROM RMKTGADM.RMK_WS_AR_BACKLOG_SHIPMENT SHP
                     WHERE     (   SHP.PRODUCT_NAME_STRIPPED =
                                      lv_Product_Name_Stripped
                                OR SHP.PRODUCT_NAME_STRIPPED =
                                      lv_Product_Name_Stripped_WS)
                           AND SHP.CUSTOMER_NAME =
                                  (SELECT COM.COMPANY_NAME
                                     FROM WCT_COMPANY_MASTER COM,
                                          WCT_CUSTOMER CUST
                                    WHERE     CUST.CUSTOMER_ID =
                                                 i_Customer_Id
                                          AND CUST.COMPANY_ID =
                                                 COM.COMPANY_ID))
             WHERE RNO = 1;
         END IF;

         lv_base_price_available := v_flag_yes;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_base_price_available := v_flag_no;
      END;

      IF (lv_Static_Price_Exists = v_Flag_Yes)
      THEN
         lv_Suggested_Price := lv_Static_Price;
      ELSIF (lv_base_price_available = v_Flag_Yes)
      THEN
         lv_Suggested_Price := lv_base_price_for_customer;
      ELSIF (lv_Broker_Offer_Missing_Flag = v_Flag_Yes) -- If broker price not found
      THEN
         lv_Suggested_Price := GREATEST (lv_Recent_Price, lv_Base_Price);
      ELSIF (   lv_Broker_Offer > lv_Base_Price
             OR lv_Broker_Offer > lv_Recent_Price)
      THEN
         lv_Suggested_Price := lv_Broker_Offer;
      ELSE
         lv_Suggested_Price := GREATEST (lv_Recent_Price, lv_Base_Price);
      END IF;

      lv_Suggested_Price :=
         VV_RSCM_UTIL.GENERIC_ROUND_UTIL (lv_Suggested_Price, lv_Round_Scale);

      --Step 3.0 Compute Ext Selling Price
      lv_Ext_Sell_Price :=
           lv_Suggested_Price
         * LEAST (lv_Available_Quantity, i_Requested_Quantity);

      --Step 4.0 Compute system discount (as per suggested price)
      IF (lv_Glp = 0)
      THEN
         lv_Base_Price_Discount := 0;
      ELSE
         lv_Base_Price_Discount :=
            100.00 - ( (lv_Suggested_Price * 100) / lv_Glp);
      END IF;

      o_Base_Price := lv_Base_Price;
      o_Suggested_Price := lv_Suggested_Price;
      o_Ext_Sell_Price := lv_Ext_Sell_Price;
      o_Base_Price_Discount := lv_Base_Price_Discount;
      o_Static_Price_Exists := lv_Static_Price_Exists;
   END;*/
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
                             o_Static_Price_Exists            OUT CHAR)
   IS
      lv_Broker_Offer_Missing_Flag   CHAR;
      lv_Suggested_Price             NUMBER (15, 2);
      lv_Base_Price                  NUMBER (15, 2);
      lv_Recent_Price                NUMBER (15, 2);
      lv_Broker_Offer                NUMBER (15, 2);
      lv_Glp                         NUMBER (15, 2);
      lv_Base_Price_Discount         NUMBER;
      lv_Ext_Sell_Price              NUMBER (15, 2);
      lv_Available_Quantity          NUMBER;
      lv_Round_Scale                 NUMBER;

      lv_Requested_Part              VARCHAR2 (50);
      lv_Wholesale_Part              VARCHAR2 (50);
      lv_spare_Part                  VARCHAR2 (50);
      lv_Refurbished_Part            VARCHAR2 (50);
      lv_Manufacture_Part            VARCHAR2 (50);
      lv_Customer_Id                 NUMBER;
      lv_Static_Price                NUMBER (15, 2);
      lv_Static_Price_Exists         CHAR;
      lv_Region_Local                VARCHAR2 (4);
      lv_base_price_available        CHAR;
      lv_base_price_for_customer     NUMBER (15, 2);


   BEGIN
      lv_Broker_Offer_Missing_Flag := i_Broker_Offer_Missing_Flag;
      lv_Recent_Price := i_Recent_Price;
      lv_Broker_Offer := i_Broker_Offer;
      lv_Glp := i_Glp;
      lv_Available_Quantity := i_Available_Quantity;
      lv_Base_Price_Discount := i_Base_Price_Discount;
      lv_Round_Scale := i_Round_Scale;

      lv_Region_Local := i_Region_Local;
      lv_Requested_Part := i_Requested_Part;
      lv_Manufacture_Part := i_Manufacture_Part;
      lv_spare_Part := i_spare_Part;
      lv_Wholesale_Part := i_Wholesale_Part;
      lv_Refurbished_Part := i_Refurbished_Part;
      lv_Customer_Id := i_Customer_Id;

      --Step 1.0 Compute Base Price
      IF (lv_Glp = 0)
      THEN
         lv_Base_Price := 0;
      ELSE
         lv_Base_Price := (lv_Glp * (100.00 - lv_Base_Price_Discount)) / 100;
      END IF;

      IF (lv_Recent_Price = 0)
      THEN
         lv_Recent_Price := lv_Base_Price;
      END IF;

      --Step 2.0 Compute Suggested/Selling Price
      -- Check for Static Price
      GET_STATIC_PRICE_DETAILS (lv_Customer_Id,
                                lv_Manufacture_Part,
                                lv_spare_Part,
                                lv_Wholesale_Part,
                                lv_Refurbished_Part,
                                lv_Static_Price_Exists,
                                lv_Static_Price);

     BEGIN
       SELECT net_price
          INTO lv_base_price_for_customer
          FROM
            ( SELECT  ssot.net_price,
                    ROW_NUMBER () OVER (ORDER BY ssot.ORDER_CREATED_DATE DESC) RNO
                FROM rmktgadm.rmk_ssot_transactions ssot,
                 wct_company_master company,
                 wct_customer customer
               WHERE     ssot.order_type = 'EXCESS'
                 AND ssot.web_order_status NOT IN ('UNSUBMITTED',
                                   'CANCELLED')
                 AND ssot.so_line_status NOT IN ('CANCELLED')
                 AND ssot.sales_order_number IS NOT NULL
                     AND ssot.sales_order_line_number IS NOT NULL
                 AND ssot.customer_id = company.cg1_customer_id
                 AND company.company_id = customer.company_id
                 AND customer.customer_id = lv_customer_id
                 AND ssot.product_id = lv_Wholesale_Part
                  --Added for US151907 <Start>
                 AND ssot.web_order_id NOT IN (SELECT TO_CHAR(ccw_weborder_id)
                                                 FROM rcec_order_headers roh,
                                                      rcec_order_lines rol,
                                                      wct_quote_line wql
                                                WHERE wql.promo_flag= v_Flag_Yes
                                                  AND wql.line_id=rol.quote_line_id
                                                  AND rol.wholesale_part_number = lv_Wholesale_Part
                                                  AND roh.excess_order_id=rol.excess_order_id
                                                )
                 --Added for US151907 <End>
             )
             WHERE RNO = 1;

      lv_base_price_available := v_flag_yes;

      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_base_price_available := v_flag_no;
      END;


      IF (lv_Static_Price_Exists = v_Flag_Yes)
      THEN
         lv_Suggested_Price := lv_Static_Price;
      ELSIF (lv_base_price_available = v_Flag_Yes)
      THEN
         lv_Suggested_Price := lv_base_price_for_customer;
      ELSIF (lv_Broker_Offer_Missing_Flag = v_Flag_Yes) -- If broker price not found
      THEN
         lv_Suggested_Price := GREATEST (lv_Recent_Price, lv_Base_Price);
      ELSIF (   lv_Broker_Offer > lv_Base_Price
             OR lv_Broker_Offer > lv_Recent_Price)
      THEN
         lv_Suggested_Price := lv_Broker_Offer;
      ELSE
         lv_Suggested_Price := GREATEST (lv_Recent_Price, lv_Base_Price);
      END IF;

      lv_Suggested_Price :=
         VV_RSCM_UTIL.GENERIC_ROUND_UTIL (lv_Suggested_Price, lv_Round_Scale);

      --Step 3.0 Compute Ext Selling Price
      lv_Ext_Sell_Price :=
           lv_Suggested_Price
         * LEAST (lv_Available_Quantity, i_Requested_Quantity);

      --Step 4.0 Compute system discount (as per suggested price)
      IF (lv_Glp = 0)
      THEN
         lv_Base_Price_Discount := 0;
      ELSE
         lv_Base_Price_Discount :=
            100.00 - ( (lv_Suggested_Price * 100) / lv_Glp);
      END IF;

      o_Base_Price := lv_Base_Price;
      o_Suggested_Price := lv_Suggested_Price;
      o_Ext_Sell_Price := lv_Ext_Sell_Price;
      o_Base_Price_Discount := lv_Base_Price_Discount;
      o_Static_Price_Exists := lv_Static_Price_Exists;
   END;

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
      o_Static_Price                  OUT NUMBER)
   IS
      lv_Customer_Id                NUMBER;
      lv_Static_Price               NUMBER (15, 2);
      lv_Static_Price_Exists        CHAR;
      lv_Tier                       NUMBER (1);
      lv_Product_Name_Stripped      VARCHAR2 (50);
      lv_Product_Name_Stripped_WS   VARCHAR2 (50);

      lv_Conflicting_Part_Count     NUMBER;
      lv_Conflicting_Part_Id        VARCHAR2 (50);
      lv_Conflicting_Part_WS        VARCHAR2 (50);
   BEGIN
      lv_Static_Price := 0;
      lv_Customer_Id := i_Customer_Id;

      lv_Product_Name_Stripped := i_Product_Name_Stripped;
      lv_Product_Name_Stripped_WS := i_Product_Name_Stripped_WS;

      lv_Conflicting_Part_Count := i_Conflicting_Part_Count;
      lv_Conflicting_Part_Id := i_Conflicting_Part_Id;
      lv_Conflicting_Part_WS := i_Conflicting_Part_WS;

      BEGIN
         SELECT tier
           INTO lv_Tier
           FROM WCT_CUSTOMER cus, WCT_COMPANY_MASTER com
          WHERE     cus.COMPANY_ID = com.COMPANY_ID
                AND cus.CUSTOMER_ID = lv_Customer_Id;

         IF (lv_Conflicting_Part_Count > 1)
         THEN
            IF (lv_Tier = 1)
            THEN
               SELECT tier1
                 INTO lv_Static_Price
                 FROM WCT_STATIC_PRICE_MASTER
                WHERE     1 = 1
                      AND (   PRODUCT_ID = lv_Conflicting_Part_Id
                           OR PRODUCT_ID = lv_Conflicting_Part_WS)
                      AND ROWNUM = 1;

               lv_Static_Price_Exists := v_Flag_Yes;
            ELSIF (lv_Tier = 2)
            THEN
               SELECT tier2
                 INTO lv_Static_Price
                 FROM WCT_STATIC_PRICE_MASTER
                WHERE     1 = 1
                      AND (   PRODUCT_ID = lv_Conflicting_Part_Id
                           OR PRODUCT_ID = lv_Conflicting_Part_WS)
                      AND ROWNUM = 1;

               lv_Static_Price_Exists := v_Flag_Yes;
            ELSIF (lv_Tier = 3)
            THEN
               SELECT tier3
                 INTO lv_Static_Price
                 FROM WCT_STATIC_PRICE_MASTER
                WHERE     1 = 1
                      AND (   PRODUCT_ID = lv_Conflicting_Part_Id
                           OR PRODUCT_ID = lv_Conflicting_Part_WS)
                      AND ROWNUM = 1;

               lv_Static_Price_Exists := v_Flag_Yes;
            ELSE
               lv_Static_Price_Exists := v_Flag_No;
            END IF;
         ELSE
            IF (lv_Tier = 1)
            THEN
               SELECT tier1
                 INTO lv_Static_Price
                 FROM WCT_STATIC_PRICE_MASTER
                WHERE     1 = 1           --AND PRODUCT_ID = lv_Requested_Part
                      AND PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped
                      AND ROWNUM = 1;

               lv_Static_Price_Exists := v_Flag_Yes;
            ELSIF (lv_Tier = 2)
            THEN
               SELECT tier2
                 INTO lv_Static_Price
                 FROM WCT_STATIC_PRICE_MASTER
                WHERE     1 = 1           --AND PRODUCT_ID = lv_Requested_Part
                      AND PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped
                      AND ROWNUM = 1;

               lv_Static_Price_Exists := v_Flag_Yes;
            ELSIF (lv_Tier = 3)
            THEN
               SELECT tier3
                 INTO lv_Static_Price
                 FROM WCT_STATIC_PRICE_MASTER
                WHERE     1 = 1           --AND PRODUCT_ID = lv_Requested_Part
                      AND PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped
                      AND ROWNUM = 1;

               lv_Static_Price_Exists := v_Flag_Yes;
            ELSE
               lv_Static_Price_Exists := v_Flag_No;
            END IF;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_Static_Price_Exists := v_Flag_No;
         WHEN OTHERS
         THEN
            lv_Static_Price_Exists := v_Flag_No;
      END;


      o_Static_Price := lv_Static_Price;
      o_Static_Price_Exists := lv_Static_Price_Exists;
   END;*/
   --Commented by satbanda on 20-Mar-2017 for validate PID logic <Start>

   --Added by satbanda on 20-Mar-2017 for validate PID logic <Start>

    PROCEDURE GET_STATIC_PRICE_DETAILS (
      i_Customer_Id                 IN     NUMBER,
      i_Manufacture_Part            IN     VARCHAR2,
      i_spare_Part                  IN     VARCHAR2,
      i_Wholesale_Part              IN     VARCHAR2,
      i_Refurbished_Part            IN     VARCHAR2,
      o_Static_Price_Exists           OUT CHAR,
      o_Static_Price                  OUT NUMBER)
   IS
      lv_Customer_Id                NUMBER;
      lv_Static_Price               NUMBER (15, 2);
      lv_Static_Price_Exists        CHAR:= v_Flag_No;
      lv_Manufacture_Part           VARCHAR2 (50):= v_Empty_String;
      lv_Refurbished_Part           VARCHAR2 (50):= v_Empty_String;
      lv_spare_Part                 VARCHAR2 (50):= v_Empty_String;
      lv_Wholesale_Part             VARCHAR2 (50):= v_Empty_String;
   BEGIN
      lv_Static_Price := 0;
      lv_Customer_Id := i_Customer_Id;
      lv_Manufacture_Part := i_Manufacture_Part;
      lv_spare_Part := i_spare_Part;
      lv_Wholesale_Part := i_Wholesale_Part;
      lv_Refurbished_Part := i_Refurbished_Part;

     BEGIN
         SELECT CASE
                WHEN wtier.tier =1 THEN     tier1
                WHEN wtier.tier =2 THEN     tier2
                WHEN wtier.tier =3 THEN     tier3
                ELSE NULL
                END Static_Price,
                CASE
                WHEN wtier.tier in (1,2,3) THEN v_Flag_Yes
                ELSE v_Flag_No
                END Static_Price_Exists
           INTO lv_Static_Price,lv_Static_Price_Exists
           FROM WCT_STATIC_PRICE_MASTER wsp,
            (SELECT tier
               FROM WCT_CUSTOMER cus, WCT_COMPANY_MASTER com
              WHERE     cus.COMPANY_ID = com.COMPANY_ID
                    AND cus.CUSTOMER_ID = lv_Customer_Id) wtier
          WHERE 1 = 1           --
            AND PRODUCT_ID IN (lv_Manufacture_Part, lv_spare_Part, lv_Wholesale_Part, lv_Refurbished_Part)
            AND ROWNUM = 1;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_Static_Price_Exists := v_Flag_No;
         WHEN OTHERS
         THEN
            lv_Static_Price_Exists := v_Flag_No;
      END;

      o_Static_Price := lv_Static_Price;
      o_Static_Price_Exists := lv_Static_Price_Exists;

   END GET_STATIC_PRICE_DETAILS;
   --Added by satbanda on 20-Mar-2017 for validate PID logic <End>

   /*PROCEDUTRE TO VIEW QUOTE DETAILS - EXCEL EXPORTS, PREVIEW*/

   PROCEDURE VIEW_QUOTE_DETAILS (
      i_Quote_Id                    IN     VARCHAR2,
      i_View_Type                   IN     VARCHAR2,
      o_View_Quote_Details_Object      OUT WCT_VIEW_QUOTE_DETAILS_OBJECT)
   IS
      --v_Quote_Line_Object      WCT_QUOTE_LINE_OBJECT;
      v_View_Quote_Details_Object   WCT_VIEW_QUOTE_DETAILS_OBJECT;
      v_Quote_Line_List             WCT_QUOTE_LINE_LIST;
      v_Customer_Detail_Object      WCT_CUSTOMER_DETAIL_OBJECT;
      v_User_Detail_Object          WCT_USER_DETAIL_OBJECT;

      lv_View_Type                  VARCHAR2 (10);
      lv_Quote_Created_Date         DATE;
      lv_Quote_Id                   VARCHAR2 (10);
      lv_Customer_Id                NUMBER;
      lv_Created_By                 VARCHAR2 (12);
      lv_Job_Title                  VARCHAR2 (50);
      lv_User_Name                  VARCHAR2 (50);
      lv_Phone_Num                  VARCHAR2 (20);
      lv_Cell_Num                   VARCHAR2 (20);
      lv_Email_Address              VARCHAR2 (22);
      lv_User_Notes                 VARCHAR2 (1500);

      lv_Company_Name               VARCHAR2 (50);
      lv_Customer_First_Name        VARCHAR2 (25);
      lv_Customer_Last_Name         VARCHAR2 (25);
      lv_Customer_Title             VARCHAR2 (4);
      lv_Address_1                  VARCHAR2 (100);
      lv_Address_2                  VARCHAR2 (100);
      lv_City                       VARCHAR2 (20);
      lv_State                      VARCHAR2 (20);
      lv_Country                    VARCHAR2 (20);
      lv_Zip                        VARCHAR2 (10);

      v_Quote_Line_List_Count       NUMBER;
   BEGIN
      lv_Quote_Id := i_Quote_Id;
      lv_View_Type := i_View_Type;

      IF (lv_View_Type = v_View_Type_Export)
      THEN
         -- Fetch Customer Id and User Id from Quote Id
         SELECT CUSTOMER_ID, CREATED_BY, CREATED_DATE
           INTO lv_Customer_Id, lv_Created_By, lv_Quote_Created_Date
           FROM WCT_QUOTE_HEADER
          WHERE QUOTE_ID = lv_Quote_Id;

         -- GENERATE USER DETAIL OBJECT
         BEGIN
            SELECT USER_NAME,
                   NVL (JOB_TITLE, v_Empty_String),
                   NVL (PHONE_NUM, v_Empty_String),
                   NVL (CELL_NUM, v_Empty_String),
                   NVL (EMAIL_ADDRESS, v_Empty_String)
              INTO lv_User_Name,
                   lv_Job_Title,
                   lv_Phone_Num,
                   lv_Cell_Num,
                   lv_Email_Address
              FROM WCT_USERS
             WHERE USER_ID = lv_Created_By;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               --LOG EXCEPTION
               INSERT INTO WCT_ERROR_LOG
                    VALUES ('GENERATE USER DETAIL OBJECT',
                            lv_Created_By,
                            'LOAD_RETRIEVE_QUOTE_DETAILS - No data found',
                            SYSDATE);
            WHEN OTHERS
            THEN
               --LOG EXCEPTION
               v_Error_Message := NULL;
               v_Error_Message := SUBSTR (SQLERRM, 1, 200);

               INSERT INTO WCT_ERROR_LOG
                       VALUES (
                                 'GENERATE USER DETAIL OBJECT',
                                 lv_Created_By,
                                    'LOAD_RETRIEVE_QUOTE_DETAILS - '
                                 || v_Error_Message,
                                 SYSDATE);
         END;

         v_User_Detail_Object :=
            WCT_USER_DETAIL_OBJECT (lv_Created_By,
                                    lv_User_Name,
                                    lv_Job_Title,
                                    lv_Phone_Num,
                                    lv_Cell_Num,
                                    lv_Email_Address,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL);

         -- GENERATE CUSTOMER DETAIL OBJECT
         BEGIN
            SELECT COMPANY_NAME,
                   POC_FIRST_NAME,
                   POC_LAST_NAME,
                   POC_TITLE,
                   ADDRESS_1,
                   ADDRESS_2,
                   CITY,
                   STATE,
                   COUNTRY,
                   ZIP
              INTO lv_Company_Name,
                   lv_Customer_First_Name,
                   lv_Customer_Last_Name,
                   lv_Customer_Title,
                   lv_Address_1,
                   lv_Address_2,
                   lv_City,
                   lv_State,
                   lv_Country,
                   lv_Zip
              FROM WCT_CUSTOMER CUST, WCT_COMPANY_MASTER COM
             WHERE     CUSTOMER_ID = lv_Customer_Id
                   AND CUST.COMPANY_ID = COM.COMPANY_ID;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               --LOG EXCEPTION
               INSERT INTO WCT_ERROR_LOG
                    VALUES ('GENERATE CUSTOMER DETAIL OBJECT',
                            lv_Created_By,
                            'LOAD_RETRIEVE_QUOTE_DETAILS - No data found',
                            SYSDATE);
            WHEN OTHERS
            THEN
               --LOG EXCEPTION
               v_Error_Message := NULL;
               v_Error_Message := SUBSTR (SQLERRM, 1, 200);

               INSERT INTO WCT_ERROR_LOG
                       VALUES (
                                 'GENERATE CUSTOMER DETAIL OBJECT',
                                 lv_Created_By,
                                    'LOAD_RETRIEVE_QUOTE_DETAILS - '
                                 || v_Error_Message,
                                 SYSDATE);
         END;

         v_Customer_Detail_Object :=
            WCT_CUSTOMER_DETAIL_OBJECT (lv_Company_Name,
                                        lv_Customer_First_Name,
                                        lv_Customer_Last_Name,
                                        lv_Customer_Title,
                                        lv_Address_1,
                                        lv_Address_2,
                                        lv_City,
                                        lv_State,
                                        lv_Country,
                                        lv_Zip);
      ELSIF (lv_View_Type = v_View_Type_ModusLink)
      THEN
         -- Fetch User Id from Quote Id
         SELECT CREATED_DATE, NVL (USER_NOTES, v_Empty_String)
           INTO lv_Quote_Created_Date, lv_User_Notes
           FROM WCT_QUOTE_HEADER
          WHERE QUOTE_ID = lv_Quote_Id;

         -- If  view type is modus Link, created BY,  customer details, and user details are not required
         lv_Created_By := NULL;
         v_Customer_Detail_Object := NULL;
         v_User_Detail_Object := NULL;
      ELSE                                                -- view type is edit
         -- Fetch User Id from Quote Id
         SELECT CREATED_BY
           INTO lv_Created_By
           FROM WCT_QUOTE_HEADER
          WHERE QUOTE_ID = lv_Quote_Id;

         -- If  view type is edit, customer details, user details and quote created date are not required
         v_Customer_Detail_Object := NULL;
         v_User_Detail_Object := NULL;

         lv_Quote_Created_Date := NULL;
      END IF;

      -- GENERATE QUOTE LINE LIST
      IF (lv_View_Type = v_View_Type_ModusLink)
      THEN
         BEGIN
              SELECT WCT_QUOTE_LINE_OBJECT (
                        NULL,                                       -- LINE_ID
                        NULL,                                      -- QUOTE_ID
                        NULL,                                       -- LINE_NO
                        QL.REQUESTED_PART,
                        WHOLESALE_PART,
                        QL.REQUESTED_QUANTITY,
                        LEAST (LT.REQUESTED_QUANTITY, LT.AVAILABLE_QUANTITY),
                        NULL,                                  -- BROKER_OFFER
                        NULL,                                           -- GLP
                        QL.SUGGESTED_PRICE,
                        NULL,                                -- EXT_SELL_PRICE
                        LT.LEAD_TIME,
                        NULL,                             -- ENCRYPTION_STATUS
                        LT.INVENTORY_DETAIL_NOTES,
                        NULL,                                      -- DISCOUNT
                        NULL,                                    -- COMMENTS_1
                        NULL,                                    -- COMMENTS_2
                        NULL,                                      -- EOS_DATE
                        NULL,                                -- APPROVAL_LEVEL
                        NVL (QL.APPROVAL_STATUS_L1, v_Empty_String),
                        NVL (QL.APPROVAL_STATUS_L2, v_Empty_String),
                        LT.ROW_ID,
                        NULL,                                       -- N_VALUE
                        NULL,                             -- RECENT_SALES_LIST
                        NVL (LT.QUANTITY_ON_HAND, 0),
                        NVL (LT.QUANTITY_IN_TRANSIT, 0),
                        NVL(QL.PROMO_FLAG,'N') -- US151907
                        )
                BULK COLLECT INTO v_Quote_Line_List
                FROM WCT_QUOTE_LINE QL, WCT_LEAD_TIME LT
               WHERE     QL.QUOTE_ID = lv_Quote_Id
                     AND QL.LEAD_TIME = LT.LEAD_TIME_ID
                     AND QL.APPROVAL_STATUS_L1 = v_Approval_Status_Approved
                     AND QL.APPROVAL_STATUS_L2 = v_Approval_Status_Approved
            ORDER BY QL.LINE_ID, LT.ROW_ID;

            v_Quote_Line_List_Count := v_Quote_Line_List.COUNT ();

            FOR idx IN 1 .. v_Quote_Line_List.COUNT ()
            LOOP
               IF (v_Quote_Line_List (idx).ROW_ID = 1)
               THEN
                  -- compute qty on hand to display for line 1
                  v_Quote_Line_List (idx).QUANTITY_ON_HAND :=
                     LEAST (v_Quote_Line_List (idx).AVAILABLE_QUANTITY,
                            v_Quote_Line_List (idx).REQUESTED_QUANTITY,
                            v_Quote_Line_List (idx).QUANTITY_ON_HAND);

                  -- compute qty in transit to display for line 1
                  v_Quote_Line_List (idx).QUANTITY_IN_TRANSIT :=
                     LEAST (
                        v_Quote_Line_List (idx).AVAILABLE_QUANTITY,
                        v_Quote_Line_List (idx).REQUESTED_QUANTITY,
                        v_Quote_Line_List (idx).QUANTITY_IN_TRANSIT,
                        (  v_Quote_Line_List (idx).AVAILABLE_QUANTITY
                         - v_Quote_Line_List (idx).QUANTITY_ON_HAND));

                  IF (    (idx < v_Quote_Line_List_Count)
                      AND (v_Quote_Line_List (idx).REQUESTED_PART =
                              v_Quote_Line_List (idx + 1).REQUESTED_PART)
                      AND (v_Quote_Line_List (idx + 1).ROW_ID = 2))
                  THEN
                     v_Quote_Line_List (idx + 1).AVAILABLE_QUANTITY :=
                        LEAST (
                           v_Quote_Line_List (idx + 1).AVAILABLE_QUANTITY,
                           (  v_Quote_Line_List (idx).REQUESTED_QUANTITY
                            - v_Quote_Line_List (idx).AVAILABLE_QUANTITY));

                     -- compute qty on hand to display for line 2
                     v_Quote_Line_List (idx + 1).QUANTITY_ON_HAND :=
                        LEAST (
                           v_Quote_Line_List (idx + 1).AVAILABLE_QUANTITY,
                           v_Quote_Line_List (idx + 1).REQUESTED_QUANTITY,
                           v_Quote_Line_List (idx + 1).QUANTITY_ON_HAND);

                     -- compute qty in transit to display for line 2
                     v_Quote_Line_List (idx + 1).QUANTITY_IN_TRANSIT :=
                        LEAST (
                           v_Quote_Line_List (idx + 1).AVAILABLE_QUANTITY,
                           v_Quote_Line_List (idx + 1).REQUESTED_QUANTITY,
                           v_Quote_Line_List (idx + 1).QUANTITY_IN_TRANSIT,
                           (  v_Quote_Line_List (idx + 1).AVAILABLE_QUANTITY
                            - v_Quote_Line_List (idx + 1).QUANTITY_ON_HAND));
                  END IF;

                  -- for checking 3rd line split

                  IF (    (idx < v_Quote_Line_List_Count)
                      AND (v_Quote_Line_List (idx).REQUESTED_PART =
                              v_Quote_Line_List (idx + 1).REQUESTED_PART)
                      AND (v_Quote_Line_List (idx + 1).ROW_ID = 2)
                      AND (v_Quote_Line_List (idx).REQUESTED_PART =
                              v_Quote_Line_List (idx + 2).REQUESTED_PART)
                      AND (v_Quote_Line_List (idx + 2).ROW_ID = 3))
                  THEN
                     v_Quote_Line_List (idx + 2).AVAILABLE_QUANTITY :=
                        LEAST (
                           v_Quote_Line_List (idx + 2).AVAILABLE_QUANTITY,
                           (  v_Quote_Line_List (idx).REQUESTED_QUANTITY
                            - v_Quote_Line_List (idx).AVAILABLE_QUANTITY
                            - v_Quote_Line_List (idx + 1).AVAILABLE_QUANTITY));

                     -- compute qty on hand to display for line 2
                     v_Quote_Line_List (idx + 1).QUANTITY_ON_HAND :=
                        LEAST (
                           v_Quote_Line_List (idx + 1).AVAILABLE_QUANTITY,
                           v_Quote_Line_List (idx + 1).REQUESTED_QUANTITY,
                           v_Quote_Line_List (idx + 1).QUANTITY_ON_HAND);

                     -- compute qty in transit to display for line 2
                     v_Quote_Line_List (idx + 1).QUANTITY_IN_TRANSIT :=
                        LEAST (
                           v_Quote_Line_List (idx + 1).AVAILABLE_QUANTITY,
                           v_Quote_Line_List (idx + 1).REQUESTED_QUANTITY,
                           v_Quote_Line_List (idx + 1).QUANTITY_IN_TRANSIT,
                           (  v_Quote_Line_List (idx + 1).AVAILABLE_QUANTITY
                            - v_Quote_Line_List (idx + 1).QUANTITY_ON_HAND));
                  END IF;
               END IF;
            END LOOP;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               --LOG EXCEPTION
               INSERT INTO WCT_ERROR_LOG
                    VALUES ('GENERATE QUOTE LINE LIST - MODUS LINK EXPORT',
                            lv_Created_By,
                            'LOAD_RETRIEVE_QUOTE_DETAILS - No data found',
                            SYSDATE);
            WHEN OTHERS
            THEN
               --LOG EXCEPTION
               v_Error_Message := NULL;
               v_Error_Message := SUBSTR (SQLERRM, 1, 200);

               INSERT INTO WCT_ERROR_LOG
                       VALUES (
                                 'GENERATE QUOTE LINE LIST - MODUS LINK EXPORT',
                                 lv_Created_By,
                                    'LOAD_RETRIEVE_QUOTE_DETAILS - '
                                 || v_Error_Message,
                                 SYSDATE);
         END;
      ELSIF (lv_View_Type = v_View_Type_Export)
      THEN
         BEGIN
              SELECT WCT_QUOTE_LINE_OBJECT (
                        QL.LINE_ID,
                        QL.QUOTE_ID,
                        QL.LINE_NO,
                        QL.REQUESTED_PART,
                        QL.WHOLESALE_PART,
                        QL.REQUESTED_QUANTITY,
                        LEAST (LT.REQUESTED_QUANTITY, LT.AVAILABLE_QUANTITY),
                        QL.BROKER_OFFER,
                        QL.GLP,
                        QL.SUGGESTED_PRICE,
                        QL.EXT_SELL_PRICE,
                        LT.LEAD_TIME,
                        QL.ENCRYPTION_STATUS,
                        LT.INVENTORY_DETAIL_NOTES,
                        QL.DISCOUNT,
                        QL.COMMENTS_L1,
                        QL.COMMENTS_L2,
                        QL.EOS_DATE,
                        QL.APPROVAL_LEVEL,
                        NVL (QL.APPROVAL_STATUS_L1, v_Empty_String),
                        NVL (QL.APPROVAL_STATUS_L2, v_Empty_String),
                        LT.ROW_ID,
                        NULL,                                       -- N_VALUE
                        NULL,                             -- RECENT_SALES_LIST
                        NULL,                              -- QUANTITY_ON_HAND
                        NULL,                           -- QUANTITY_IN_TRANSIT
                        NVL(QL.PROMO_FLAG,'N') -- US151907
                        )
                BULK COLLECT INTO v_Quote_Line_List
                FROM WCT_QUOTE_LINE QL, WCT_LEAD_TIME LT
               WHERE     QL.QUOTE_ID = lv_Quote_Id
                     AND QL.LEAD_TIME = LT.LEAD_TIME_ID
            ORDER BY QL.LINE_ID, LT.ROW_ID;

            v_Quote_Line_List_Count := v_Quote_Line_List.COUNT ();


            FOR idx IN 1 .. v_Quote_Line_List.COUNT ()
            LOOP
               IF (v_Quote_Line_List (idx).ROW_ID = 1)
               THEN
                  -- Line specific Ext Sell Price
                  v_Quote_Line_List (idx).EXT_SELL_PRICE :=
                       v_Quote_Line_List (idx).SUGGESTED_PRICE
                     * v_Quote_Line_List (idx).AVAILABLE_QUANTITY;

                  IF (    (idx < v_Quote_Line_List_Count)
                      AND (v_Quote_Line_List (idx).REQUESTED_PART =
                              v_Quote_Line_List (idx + 1).REQUESTED_PART)
                      AND (v_Quote_Line_List (idx + 1).ROW_ID = 2))
                  THEN
                     v_Quote_Line_List (idx + 1).AVAILABLE_QUANTITY :=
                        LEAST (
                           v_Quote_Line_List (idx + 1).AVAILABLE_QUANTITY,
                           (  v_Quote_Line_List (idx).REQUESTED_QUANTITY
                            - v_Quote_Line_List (idx).AVAILABLE_QUANTITY));

                     v_Quote_Line_List (idx + 1).EXT_SELL_PRICE :=
                          v_Quote_Line_List (idx).SUGGESTED_PRICE
                        * v_Quote_Line_List (idx + 1).AVAILABLE_QUANTITY;
                  END IF;

                  -- for 3rd line split

                  IF (    (idx < v_Quote_Line_List_Count)
                      AND (v_Quote_Line_List (idx).REQUESTED_PART =
                              v_Quote_Line_List (idx + 1).REQUESTED_PART)
                      AND (v_Quote_Line_List (idx + 1).ROW_ID = 2)
                      AND (v_Quote_Line_List (idx).REQUESTED_PART =
                              v_Quote_Line_List (idx + 2).REQUESTED_PART)
                      AND (v_Quote_Line_List (idx + 2).ROW_ID = 3))
                  THEN
                     v_Quote_Line_List (idx + 2).AVAILABLE_QUANTITY :=
                        LEAST (
                           v_Quote_Line_List (idx + 2).AVAILABLE_QUANTITY,
                           (  v_Quote_Line_List (idx).REQUESTED_QUANTITY
                            - v_Quote_Line_List (idx).AVAILABLE_QUANTITY
                            - v_Quote_Line_List (idx + 1).AVAILABLE_QUANTITY));

                     v_Quote_Line_List (idx + 2).EXT_SELL_PRICE :=
                          v_Quote_Line_List (idx).SUGGESTED_PRICE
                        * v_Quote_Line_List (idx + 2).AVAILABLE_QUANTITY;
                  END IF;
               END IF;
            END LOOP;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               --LOG EXCEPTION
               INSERT INTO WCT_ERROR_LOG
                    VALUES ('GENERATE QUOTE LINE LIST - EXTERNAL EXPORT',
                            lv_Created_By,
                            'LOAD_RETRIEVE_QUOTE_DETAILS - No data found',
                            SYSDATE);
            WHEN OTHERS
            THEN
               --LOG EXCEPTION
               v_Error_Message := NULL;
               v_Error_Message := SUBSTR (SQLERRM, 1, 200);

               INSERT INTO WCT_ERROR_LOG
                       VALUES (
                                 'GENERATE QUOTE LINE LIST - EXTERNAL EXPORT',
                                 lv_Created_By,
                                    'LOAD_RETRIEVE_QUOTE_DETAILS - '
                                 || v_Error_Message,
                                 SYSDATE);
         END;
      ELSE                                                -- if view type edit
         BEGIN
            SELECT WCT_QUOTE_LINE_OBJECT (NULL,                      --LINE_ID
                                          NULL,                     --QUOTE_ID
                                          NULL,                      --LINE_NO
                                          REQUESTED_PART,
                                          NULL,               --WHOLESALE_PART
                                          REQUESTED_QUANTITY,
                                          NULL,           --AVAILABLE_QUANTITY
                                          BROKER_OFFER,
                                          NULL,                          --GLP
                                          NULL,              --SUGGESTED_PRICE
                                          NULL,               --EXT_SELL_PRICE
                                          NULL,                    --LEAD_TIME
                                          NULL,            --ENCRYPTION_STATUS
                                          NULL,       --INVENTORY_DETAIL_NOTES
                                          NULL,                     --DISCOUNT
                                          NULL,                  --COMMENTS_L1
                                          NULL,                  --COMMENTS_L2
                                          NULL,                     --EOS_DATE
                                          NULL,               --APPROVAL_LEVEL
                                          NULL,           --APPROVAL_STATUS_L1
                                          NULL,           --APPROVAL_STATUS_L2
                                          NULL,                       --ROW_ID
                                          NULL,                     -- N_VALUE
                                          NULL,           -- RECENT_SALES_LIST
                                          NULL,            -- QUANTITY_ON_HAND
                                          NULL,         -- QUANTITY_IN_TRANSIT
                                          NVL(PROMO_FLAG,'N') -- US151907
                                          )
              BULK COLLECT INTO v_Quote_Line_List
              FROM WCT_QUOTE_LINE
             WHERE QUOTE_ID = lv_Quote_Id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               --LOG EXCEPTION
               INSERT INTO WCT_ERROR_LOG
                    VALUES ('GENERATE QUOTE LINE LIST - EDIT',
                            lv_Created_By,
                            'LOAD_RETRIEVE_QUOTE_DETAILS - No data found',
                            SYSDATE);
            WHEN OTHERS
            THEN
               --LOG EXCEPTION
               v_Error_Message := NULL;
               v_Error_Message := SUBSTR (SQLERRM, 1, 200);

               INSERT INTO WCT_ERROR_LOG
                       VALUES (
                                 'GENERATE QUOTE LINE LIST - EDIT',
                                 lv_Created_By,
                                    'LOAD_RETRIEVE_QUOTE_DETAILS - '
                                 || v_Error_Message,
                                 SYSDATE);
         END;
      END IF;

      v_View_Quote_Details_Object :=
         WCT_VIEW_QUOTE_DETAILS_OBJECT (v_Customer_Detail_Object,
                                        v_User_Detail_Object,
                                        v_Quote_Line_List,
                                        lv_Quote_Created_Date,
                                        lv_User_Notes);

      o_View_Quote_Details_Object := v_View_Quote_Details_Object;
   END;

   /* PROCEDURE TO LOG ERROR DETAILS */

   PROCEDURE GET_ERROR_DETAILS (i_User_Id        IN     VARCHAR2,
                                o_Error_Object      OUT WCT_ERROR_OBJECT)
   IS
      v_Error_Object     WCT_ERROR_OBJECT;

      lv_User_Id         VARCHAR2 (12);

      lv_Error_Message   VARCHAR2 (1000) := v_Empty_String;
      lv_Mail_To         VARCHAR2 (50) := v_Empty_String;
      lv_Mail_Subject    VARCHAR2 (100) := v_Empty_String;
   BEGIN
      lv_User_Id := i_User_Id;

      BEGIN
         SELECT PROPERTY_VALUE
           INTO lv_Error_Message
           FROM WCT_PROPERTIES
          WHERE PROPERTY_TYPE = 'ERROR_MESSAGE';

         SELECT PROPERTY_VALUE
           INTO lv_Mail_To
           FROM WCT_PROPERTIES
          WHERE PROPERTY_TYPE = 'ERROR_MAIL_TO';

         SELECT PROPERTY_VALUE
           INTO lv_Mail_Subject
           FROM WCT_PROPERTIES
          WHERE PROPERTY_TYPE = 'ERROR_MAIL_SUBJECT';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            --LOG EXCEPTION
            INSERT INTO WCT_ERROR_LOG
                 VALUES ('GENERATE ERROR OBJECT',
                         lv_User_Id,
                         'GET_ERROR_DETAILS - No data found',
                         SYSDATE);
         WHEN OTHERS
         THEN
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message := SUBSTR (SQLERRM, 1, 200);

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('GENERATE ERROR OBJECT',
                         lv_User_Id,
                         'GET_ERROR_DETAILS - ' || v_Error_Message,
                         SYSDATE);
      END;

      v_Error_Object :=
         WCT_ERROR_OBJECT (lv_Error_Message, lv_Mail_To, lv_Mail_Subject);
      o_Error_Object := v_Error_Object;
   END;

   /* PROCEDURE TO LOAD APPROVAL QUOTE LIST */

   PROCEDURE LOAD_APPROVAL_QUOTE_LIST (
      i_User_Id                IN     VARCHAR2,
      i_Load_Type              IN     VARCHAR2,
      o_Approval_Quotes_List      OUT WCT_RETRIEVE_QUOTES_LIST)
   IS
      v_Approval_Quotes_List   WCT_RETRIEVE_QUOTES_LIST;
      lv_User_Id               VARCHAR2 (12);
      lv_Approver_Level        NUMBER;
      lv_Load_Type             VARCHAR2 (8);
   BEGIN
      lv_User_Id := i_User_Id;
      lv_Load_Type := i_Load_Type;

      BEGIN
         SELECT APPROVER_LEVEL
           INTO lv_Approver_Level
           FROM WCT_USERS
          WHERE USER_ID = lv_User_Id;

         IF (lv_Load_Type = v_Load_Type_Action)
         THEN
            IF (lv_Approver_Level = 2)
            THEN
                 SELECT WCT_RETRIEVE_QUOTES_OBJECT (QH.QUOTE_ID,
                                                    COM.COMPANY_NAME,
                                                    QH.CREATED_DATE,
                                                    QH.CREATED_BY,
                                                    QH.DEAL_VALUE,
                                                    QH.STATUS,
                                                    CUST.CUSTOMER_ID,
                                                    SD.STATUS_DESCRIPTION,
                                                    QH.APPROVER_LEVEL_1,
                                                    QH.APPROVER_LEVEL_2) --added karusing to retrieve approver id
                   BULK COLLECT INTO v_Approval_Quotes_List
                   FROM WCT_QUOTE_HEADER QH,
                        WCT_CUSTOMER CUST,
                        WCT_COMPANY_MASTER COM,
                        WCT_STATUS_DETAIL SD
                  WHERE     1 = 1
                        AND QH.CUSTOMER_ID = CUST.CUSTOMER_ID
                        /*AND (   QH.STATUS = v_Status_Pending
                             OR QH.STATUS = v_Status_Partial)*/
                        AND QH.STATUS = v_Status_Pending
                        AND COM.COMPANY_ID = CUST.COMPANY_ID
                        AND QH.STATUS = SD.STATUS
                        AND APPROVAL_LEVEL = lv_Approver_Level
                        AND QH.QUOTE_ID IN (SELECT DISTINCT QL.QUOTE_ID
                                              FROM WCT_QUOTE_LINE QL
                                             WHERE     QL.APPROVAL_STATUS_L1 =
                                                          v_Approval_Status_Approved
                                                   AND QL.APPROVAL_STATUS_L2 =
                                                          v_Approval_Status_Pending)
                        AND QH.Quote_id NOT IN (SELECT DISTINCT quote_id
                                                  FROM wct_quote_line
                                                 WHERE approval_status_l1 =
                                                          v_Approval_Status_Pending)
               ORDER BY QH.CREATED_DATE DESC;
            ELSIF (lv_Approver_Level = 1)
            THEN
                 SELECT WCT_RETRIEVE_QUOTES_OBJECT (QH.QUOTE_ID,
                                                    COM.COMPANY_NAME,
                                                    QH.CREATED_DATE,
                                                    QH.CREATED_BY,
                                                    QH.DEAL_VALUE,
                                                    QH.STATUS,
                                                    CUST.CUSTOMER_ID,
                                                    SD.STATUS_DESCRIPTION,
                                                    QH.APPROVER_LEVEL_1,
                                                    QH.APPROVER_LEVEL_2) --added karusing to retrieve approver id
                   BULK COLLECT INTO v_Approval_Quotes_List
                   FROM WCT_QUOTE_HEADER QH,
                        WCT_CUSTOMER CUST,
                        WCT_COMPANY_MASTER COM,
                        WCT_STATUS_DETAIL SD
                  WHERE     1 = 1
                        AND QH.CUSTOMER_ID = CUST.CUSTOMER_ID
                        /*AND (   QH.STATUS = v_Status_Pending
                             OR QH.STATUS = v_Status_Partial)*/
                        AND QH.STATUS = v_Status_Pending
                        AND COM.COMPANY_ID = CUST.COMPANY_ID
                        AND QH.STATUS = SD.STATUS
                        AND APPROVAL_LEVEL >= lv_Approver_Level
                        AND QH.QUOTE_ID IN (SELECT DISTINCT QL.QUOTE_ID
                                              FROM WCT_QUOTE_LINE QL
                                             WHERE QL.APPROVAL_STATUS_L1 =
                                                      v_Approval_Status_Pending)
               ORDER BY QH.CREATED_DATE DESC;
            ELSE
               v_Approval_Quotes_List := NULL;
            END IF;
         ELSIF (lv_Load_Type = v_Load_Type_Preview)
         THEN
            IF (lv_Approver_Level = 2)
            THEN
                 SELECT WCT_RETRIEVE_QUOTES_OBJECT (QH.QUOTE_ID,
                                                    COM.COMPANY_NAME,
                                                    QH.LAST_UPDATED_DATE,
                                                    QH.CREATED_BY,
                                                    QH.DEAL_VALUE,
                                                    QH.STATUS,
                                                    CUST.CUSTOMER_ID,
                                                    SD.STATUS_DESCRIPTION,
                                                    QH.APPROVER_LEVEL_1,
                                                    QH.APPROVER_LEVEL_2) --added karusing to retrieve approver id
                   BULK COLLECT INTO v_Approval_Quotes_List
                   FROM WCT_QUOTE_HEADER QH,
                        WCT_CUSTOMER CUST,
                        WCT_COMPANY_MASTER COM,
                        WCT_STATUS_DETAIL SD
                  WHERE     1 = 1
                        AND QH.CUSTOMER_ID = CUST.CUSTOMER_ID
                        AND (   QH.STATUS = v_Status_Approved
                             OR QH.STATUS = v_Status_Partial
                             OR QH.STATUS = v_Status_Quote
                             OR QH.STATUS = v_Status_Rejected)
                        AND COM.COMPANY_ID = CUST.COMPANY_ID
                        AND QH.STATUS = SD.STATUS
                        AND QH.APPROVER_LEVEL_2 = lv_User_Id
                        AND QH.QUOTE_ID IN (  SELECT DISTINCT QL.QUOTE_ID
                                                FROM WCT_QUOTE_LINE QL
                                               WHERE     QL.QUOTE_ID =
                                                            QH.QUOTE_ID
                                                     AND (   (    QL.APPROVAL_STATUS_L1 =
                                                                     v_Approval_Status_Approved
                                                              AND QL.APPROVAL_STATUS_L2 =
                                                                     v_Approval_Status_Approved)
                                                          OR (    QL.APPROVAL_STATUS_L1 =
                                                                     v_Approval_Status_Approved
                                                              AND QL.APPROVAL_STATUS_L2 =
                                                                     v_Approval_Status_Rejected)
                                                          OR (    QL.APPROVAL_STATUS_L1 =
                                                                     v_Approval_Status_Rejected
                                                              AND QL.APPROVAL_STATUS_L2 =
                                                                     v_Approval_Status_Rejected))
                                            GROUP BY QL.QUOTE_ID
                                              HAVING COUNT (QL.LINE_ID) =
                                                        (SELECT COUNT (*)
                                                           FROM WCT_QUOTE_LINE QLI
                                                          WHERE QLI.QUOTE_ID =
                                                                   QL.QUOTE_ID))
               /*AND QH.Quote_id NOT IN
                      (SELECT DISTINCT quote_id
                         FROM wct_quote_line
                        WHERE approval_status_l1 =
                                 v_Approval_Status_Pending)*/
               ORDER BY QH.LAST_UPDATED_DATE DESC;
            ELSIF (lv_Approver_Level = 1)
            THEN
                 SELECT WCT_RETRIEVE_QUOTES_OBJECT (QH.QUOTE_ID,
                                                    COM.COMPANY_NAME,
                                                    QH.LAST_UPDATED_DATE,
                                                    QH.CREATED_BY,
                                                    QH.DEAL_VALUE,
                                                    QH.STATUS,
                                                    CUST.CUSTOMER_ID,
                                                    SD.STATUS_DESCRIPTION,
                                                    QH.APPROVER_LEVEL_1,
                                                    QH.APPROVER_LEVEL_2) --added karusing to retrieve approver id
                   BULK COLLECT INTO v_Approval_Quotes_List
                   FROM WCT_QUOTE_HEADER QH,
                        WCT_CUSTOMER CUST,
                        WCT_COMPANY_MASTER COM,
                        WCT_STATUS_DETAIL SD
                  WHERE     1 = 1
                        AND QH.CUSTOMER_ID = CUST.CUSTOMER_ID
                        AND (   QH.STATUS = v_Status_Approved
                             OR QH.STATUS = v_Status_Partial
                             OR QH.STATUS = v_Status_Quote
                             OR QH.STATUS = v_Status_Rejected)
                        AND COM.COMPANY_ID = CUST.COMPANY_ID
                        AND QH.STATUS = SD.STATUS
                        AND QH.APPROVER_LEVEL_1 = lv_User_Id
                        AND QH.QUOTE_ID IN (  SELECT DISTINCT QL.QUOTE_ID
                                                FROM WCT_QUOTE_LINE QL
                                               WHERE     QL.QUOTE_ID =
                                                            QH.QUOTE_ID
                                                     AND (   (    QL.APPROVAL_STATUS_L1 =
                                                                     v_Approval_Status_Approved
                                                              AND QL.APPROVAL_STATUS_L2 =
                                                                     v_Approval_Status_Approved)
                                                          OR (    QL.APPROVAL_STATUS_L1 =
                                                                     v_Approval_Status_Rejected
                                                              AND QL.APPROVAL_STATUS_L2 =
                                                                     v_Approval_Status_Rejected))
                                            GROUP BY QL.QUOTE_ID
                                              HAVING COUNT (QL.LINE_ID) =
                                                        (SELECT COUNT (*)
                                                           FROM WCT_QUOTE_LINE QLI
                                                          WHERE QLI.QUOTE_ID =
                                                                   QL.QUOTE_ID))
               ORDER BY QH.LAST_UPDATED_DATE DESC;
            ELSE
               v_Approval_Quotes_List := NULL;
            END IF;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            --LOG EXCEPTION
            INSERT INTO WCT_ERROR_LOG
                 VALUES ('GENERATE QUOTE LIST',
                         lv_User_Id,
                         'LOAD_APPROVAL_QUOTE_LIST - No data found',
                         SYSDATE);
         WHEN OTHERS
         THEN
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message := SUBSTR (SQLERRM, 1, 200);

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('GENERATE QUOTE LIST',
                         lv_User_Id,
                         'LOAD_APPROVAL_QUOTE_LIST - ' || v_Error_Message,
                         SYSDATE);
      END;

      o_Approval_Quotes_List := v_Approval_Quotes_List;
   END;

   /* PROCEDURE TO LOAD CUSTOMER COMPANY DATA */

   PROCEDURE LOAD_CUSTOMER_COMPANY_DATA (
      i_User_Id                   IN     VARCHAR2,
      o_Customer_Company_Object      OUT WCT_CUSTOMER_COMPANY_OBJECT)
   IS
      v_Customer_List       WCT_CUSTOMER_LIST;
      v_Company_List        WCT_COMPANY_LIST;
      v_Sales_Person_List   WCT_USER_LIST;

      lv_User_Id            VARCHAR2 (12 BYTE);
   BEGIN
      lv_User_Id := i_User_Id;

      -- GENERATE CUSTOMER LIST
      LOAD_CUSTOMER_LIST (lv_User_Id,
                          v_Customer_List_Type_Update,
                          v_Customer_List);

      -- GENERATE COMPANY LIST
      LOAD_COMPANY_LIST (lv_User_Id, v_Company_List);

      -- GENERATE USER LIST
      LOAD_USER_LIST (lv_User_Id, v_Sales_Person_List);

      o_Customer_Company_Object :=
         WCT_CUSTOMER_COMPANY_OBJECT (v_Customer_List,
                                      v_Company_List,
                                      v_Sales_Person_List);
   END;

   /* PROCEDURE TO FETCH COMPANY LIST */

   PROCEDURE LOAD_COMPANY_LIST (i_User_Id        IN     VARCHAR2,
                                o_Company_List      OUT WCT_COMPANY_LIST)
   IS
      v_Company_List   WCT_COMPANY_LIST;
      lv_User_Id       VARCHAR2 (12);
   BEGIN
      lv_User_Id := i_User_Id;

      BEGIN
           SELECT WCT_COMPANY_OBJECT (COMPANY_ID, COMPANY_NAME)
             BULK COLLECT INTO v_Company_List
             FROM WCT_COMPANY_MASTER
         ORDER BY COMPANY_NAME;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            --LOG EXCEPTION
            INSERT INTO WCT_ERROR_LOG
                 VALUES ('LOAD_COMPANY_LIST',
                         lv_User_Id,
                         'No data found',
                         SYSDATE);
         WHEN OTHERS
         THEN
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message := SUBSTR (SQLERRM, 1, 200);

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('LOAD_COMPANY_LIST',
                         lv_User_Id,
                         v_Error_Message,
                         SYSDATE);
      END;

      o_Company_List := v_Company_List;
   END;

   /* PROCEDURE TO FETCH USER LIST */

   PROCEDURE LOAD_USER_LIST (i_User_Id     IN     VARCHAR2,
                             o_User_List      OUT WCT_USER_LIST)
   IS
      v_User_List   WCT_USER_LIST;
      lv_User_Id    VARCHAR2 (12);
   BEGIN
      lv_User_Id := i_User_Id;

      BEGIN
           SELECT WCT_USER_OBJECT (USER_ID,
                                   USER_NAME || ' (' || USER_ID || ')',
                                   APPROVER_LEVEL)
             BULK COLLECT INTO v_User_List
             FROM WCT_USERS
            WHERE ROLE = 'USER'
         ORDER BY USER_ID;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            --LOG EXCEPTION
            INSERT INTO WCT_ERROR_LOG
                 VALUES ('LOAD_USER_LIST',
                         lv_User_Id,
                         'No data found',
                         SYSDATE);
         WHEN OTHERS
         THEN
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message := SUBSTR (SQLERRM, 1, 200);

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('LOAD_USER_LIST',
                         lv_User_Id,
                         v_Error_Message,
                         SYSDATE);
      END;

      o_User_List := v_User_List;
   END;

   /* PROCEDURE TO FETCH STATIC PRICE PART LIST */

   PROCEDURE LOAD_STATIC_PRICE_PART_LIST (
      i_User_Id                  IN     VARCHAR2,
      o_Static_Price_Part_List      OUT WCT_STATIC_PRICE_PART_LIST)
   IS
      v_Static_Price_Part_List   WCT_STATIC_PRICE_PART_LIST;
   BEGIN
      v_Static_Price_Part_List := WCT_STATIC_PRICE_PART_LIST ();

      BEGIN
           SELECT PRODUCT_ID
             BULK COLLECT INTO v_Static_Price_Part_List
             FROM WCT_STATIC_PRICE_MASTER
         ORDER BY PRODUCT_ID;
      EXCEPTION
         WHEN OTHERS
         THEN
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message := SUBSTR (SQLERRM, 1, 200);

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('LOAD_STATIC_PRICE_PART_LIST',
                         i_User_Id,
                         v_Error_Message,
                         SYSDATE);
      END;

      o_Static_Price_Part_List := v_Static_Price_Part_List;
   END;


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
      o_Response_Object      OUT WCT_RESPONSE_OBJECT)
   IS
      lv_Company_Id              NUMBER;
      lv_Company_Name            VARCHAR2 (50);
      lv_Tier                    NUMBER;
      lv_Address_1               VARCHAR2 (100);
      lv_Address_2               VARCHAR2 (100);
      lv_City                    VARCHAR2 (20);
      lv_State                   VARCHAR2 (20);
      lv_Zip                     VARCHAR2 (10);
      lv_Country                 VARCHAR2 (20);
      lv_Region                  VARCHAR2 (10);
      lv_Status                  VARCHAR2 (10);
      lv_User_Id                 VARCHAR2 (12);
      lv_Action_Type             VARCHAR2 (6 BYTE);
      lv_Response_Message        VARCHAR2 (200 BYTE);
      lv_Response_Type           VARCHAR2 (7 BYTE);
      lv_Active_Customer_Count   NUMBER := 0;

      lv_Company_Count           NUMBER := 0;
      lv_Date                    DATE := SYSDATE;
   BEGIN
      lv_Company_Id := i_Company_Id;
      lv_Company_Name := i_Company_Name;
      lv_Tier := i_Tier;
      lv_Address_1 := i_Address_1;
      lv_Address_2 := i_Address_2;
      lv_City := i_City;
      lv_State := i_State;
      lv_Zip := i_Zip;
      lv_Country := i_Country;
      lv_Region := i_Region;
      lv_Status := i_Status;
      lv_User_Id := i_User_Id;
      lv_Action_Type := i_Action_Type;

      IF (lv_Action_Type = v_Action_Type_Add)
      THEN
         lv_Company_Count := 0;

         BEGIN
            lv_Date := SYSDATE;

            -- Check for existing company with same details
            SELECT COUNT (*)
              INTO lv_Company_Count
              FROM WCT_COMPANY_MASTER
             WHERE     COMPANY_NAME = lv_Company_Name
                   AND TIER = lv_Tier
                   AND STATUS = lv_Status
                   AND REGION = lv_Region;

            -- If no company with same details found, insert a new company
            IF (lv_Company_Count = 0)
            THEN
               -- If insert company true, add the company
               BEGIN
                  INSERT INTO WCT_COMPANY_MASTER (COMPANY_ID,
                                                  COMPANY_NAME,
                                                  TIER,
                                                  ADDRESS_1,
                                                  ADDRESS_2,
                                                  CITY,
                                                  STATE,
                                                  ZIP,
                                                  REGION,
                                                  STATUS,
                                                  CREATED_BY,
                                                  CREATED_DATE,
                                                  UPDATED_BY,
                                                  UPDATED_ON,
                                                  COUNTRY)
                       VALUES (WCT_SEQ_COMPANY_ID.NEXTVAL,
                               lv_Company_Name,
                               lv_Tier,
                               lv_Address_1,
                               lv_Address_2,
                               lv_City,
                               lv_State,
                               lv_Zip,
                               lv_Region,
                               lv_Status,
                               lv_User_Id,
                               lv_Date,
                               lv_User_Id,
                               lv_Date,
                               lv_Country);

                  lv_Response_Type := v_Status_Success;
                  lv_Response_Message := 'Company added successfully';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lv_Response_Type := v_Status_Failure;
                     lv_Response_Message :=
                        'An error occurred while adding Company';
               END;
            ELSE
               lv_Response_Type := v_Status_Failure;
               lv_Response_Message := 'System identified existing Company';
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_Response_Type := v_Status_Failure;
               lv_Response_Message := 'An error occurred while adding Company';

               --LOG EXCEPTION
               v_Error_Message := NULL;
               v_Error_Message := SUBSTR (SQLERRM, 1, 200);

               INSERT INTO WCT_ERROR_LOG
                    VALUES ('ADD_UPDATE_COMPANY_DETAILS',
                            lv_User_Id,
                            'ADD_COMPANY_DETAILS: ' || v_Error_Message,
                            SYSDATE);
         END;
      ELSIF (lv_Action_Type = v_Action_Type_Update)
      THEN
         BEGIN
            IF (lv_Status = v_Status_Inactive)
            THEN
               SELECT COUNT (*)
                 INTO lv_Active_Customer_Count
                 FROM WCT_CUSTOMER
                WHERE COMPANY_ID = lv_Company_Id AND STATUS = v_Status_Active;
            END IF;

            IF (lv_Active_Customer_Count > 0)
            THEN
               lv_Response_Type := v_Status_Failure;
               lv_Response_Message :=
                  'System identified active customers for the company.';
            ELSE
               UPDATE WCT_COMPANY_MASTER
                  SET COMPANY_NAME = lv_Company_Name,
                      TIER = lv_Tier,
                      ADDRESS_1 = lv_Address_1,
                      ADDRESS_2 = lv_Address_2,
                      CITY = lv_City,
                      STATE = lv_State,
                      ZIP = lv_Zip,
                      COUNTRY = lv_Country,
                      REGION = lv_Region,
                      STATUS = lv_Status,
                      UPDATED_BY = lv_User_Id,
                      UPDATED_ON = lv_Date
                WHERE COMPANY_ID = lv_Company_Id;

               IF (SQL%ROWCOUNT > 0)
               THEN
                  lv_Response_Type := v_Status_Success;
                  lv_Response_Message := 'Data updated successfully.';
               ELSE
                  lv_Response_Type := v_Status_Failure;
                  lv_Response_Message := 'No data updated.';
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_Response_Type := v_Status_Failure;
               lv_Response_Message :=
                  'Update failed due to some technical reasons. Please contact Excess Portal Support.';

               --LOG EXCEPTION
               v_Error_Message := NULL;
               v_Error_Message := SUBSTR (SQLERRM, 1, 200);

               INSERT INTO WCT_ERROR_LOG
                    VALUES ('ADD_UPDATE_COMPANY_DETAILS',
                            lv_User_Id,
                            'UPDATE_COMPANY_DETAILS: ' || v_Error_Message,
                            SYSDATE);
         END;
      END IF;

      o_Response_Object :=
         WCT_RESPONSE_OBJECT (lv_Response_Type, lv_Response_Message);
   END;

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
      o_Response_Object      OUT WCT_RESPONSE_OBJECT)
   IS
      lv_Customer_Id           NUMBER;
      lv_Poc_Title             VARCHAR2 (3);
      lv_Poc_First_Name        VARCHAR2 (50);
      lv_Poc_Last_Name         VARCHAR2 (50);
      lv_Sales_Person          VARCHAR2 (12);
      lv_Status                VARCHAR2 (8);
      lv_Company_Id            NUMBER;
      lv_User_Id               VARCHAR2 (12);
      lv_Action_Type           VARCHAR2 (6 BYTE);
      lv_Response_Message      VARCHAR2 (200 BYTE);
      lv_Response_Type         VARCHAR2 (7 BYTE);
      lv_Inactive_User_Count   NUMBER := 0;
      lv_Customer_Count        NUMBER := 0;
      lv_Date                  DATE := SYSDATE;
   BEGIN
      lv_Customer_Id := i_Customer_Id;
      lv_Poc_Title := i_Poc_Title;
      lv_Poc_First_Name := i_Poc_First_Name;
      lv_Poc_Last_Name := i_Poc_Last_Name;
      lv_Sales_Person := i_Sales_Person;
      lv_Status := i_Status;
      lv_Company_Id := i_Company_Id;
      lv_User_Id := i_User_Id;
      lv_Action_Type := i_Action_Type;

      IF (lv_Action_Type = v_Action_Type_Add)
      THEN
         BEGIN
            -- Check for existing customer with same details
            SELECT COUNT (*)
              INTO lv_Customer_Count
              FROM WCT_CUSTOMER
             WHERE     POC_TITLE = lv_Poc_Title
                   AND POC_FIRST_NAME = lv_Poc_First_Name
                   AND POC_LAST_NAME = lv_Poc_Last_Name
                   AND SALES_PERSON = lv_Sales_Person
                   AND COMPANY_ID = lv_Company_Id;

            -- If no customer with same details found, insert a new customer
            IF (lv_Customer_Count = 0)
            THEN
               -- If insert customer true, add the customer

               SELECT COUNT (*)
                 INTO lv_Inactive_User_Count
                 FROM WCT_USERS
                WHERE     USER_ID = lv_Sales_Person
                      AND STATUS = v_Status_Inactive;

               IF (lv_Inactive_User_Count = 0)
               THEN
                  BEGIN
                     INSERT INTO WCT_CUSTOMER (CUSTOMER_ID,
                                               POC_TITLE,
                                               POC_FIRST_NAME,
                                               POC_LAST_NAME,
                                               SALES_PERSON,
                                               COMPANY_ID,
                                               STATUS,
                                               CREATED_BY,
                                               CREATED_DATE,
                                               LAST_UPDATED_BY,
                                               LAST_UPDATED_DATE)
                          VALUES (WCT_CUSTOMER_SEQ.NEXTVAL,
                                  lv_Poc_Title,
                                  lv_Poc_First_Name,
                                  lv_Poc_Last_Name,
                                  lv_Sales_Person,
                                  lv_Company_Id,
                                  v_Status_Active,
                                  lv_User_Id,
                                  lv_Date,
                                  lv_User_Id,
                                  lv_Date);

                     lv_Response_Type := v_Status_Success;
                     lv_Response_Message := 'Customer added successfully';
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        lv_Response_Type := v_Status_Failure;
                        lv_Response_Message :=
                           'An error occurred while adding Customer';
                  END;
               ELSE
                  lv_Response_Type := v_Status_Failure;
                  lv_Response_Message :=
                     'System identified the selected sales person as INACTIVE user.';
               END IF;
            ELSE
               lv_Response_Type := v_Status_Failure;
               lv_Response_Message := 'System identified existing Customer';
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_Response_Type := v_Status_Failure;
               lv_Response_Message :=
                  'An error occurred while adding Customer';

               --LOG EXCEPTION
               v_Error_Message := NULL;
               v_Error_Message := SUBSTR (SQLERRM, 1, 200);

               INSERT INTO WCT_ERROR_LOG
                    VALUES ('ADD_UPDATE_CUSTOMER_DETAILS',
                            lv_User_Id,
                            'ADD_CUSTOMER_DETAILS: ' || v_Error_Message,
                            SYSDATE);
         END;
      ELSIF (lv_Action_Type = v_Action_Type_Update)
      THEN
         BEGIN
            SELECT COUNT (*)
              INTO lv_Inactive_User_Count
              FROM WCT_USERS
             WHERE USER_ID = lv_Sales_Person AND STATUS = v_Status_Inactive;

            IF (lv_Inactive_User_Count > 0)
            THEN
               lv_Response_Type := v_Status_Failure;
               lv_Response_Message :=
                  'System identified inactive Sales Person for the customer.';
            ELSE
               UPDATE WCT_CUSTOMER
                  SET POC_TITLE = lv_Poc_Title,
                      POC_FIRST_NAME = lv_Poc_First_Name,
                      POC_LAST_NAME = lv_Poc_Last_Name,
                      SALES_PERSON = lv_Sales_Person,
                      STATUS = lv_Status,
                      COMPANY_ID = lv_Company_Id,
                      LAST_UPDATED_BY = lv_User_Id,
                      LAST_UPDATED_DATE = lv_Date
                WHERE CUSTOMER_ID = lv_Customer_Id;

               IF (SQL%ROWCOUNT > 0)
               THEN
                  lv_Response_Type := v_Status_Success;
                  lv_Response_Message := 'Data updated successfully.';
               ELSE
                  lv_Response_Type := v_Status_Failure;
                  lv_Response_Message := 'No data updated.';
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_Response_Type := v_Status_Failure;
               lv_Response_Message :=
                  'Update failed due to some technical reasons. Please contact Excess Portal Support.';

               --LOG EXCEPTION
               v_Error_Message := NULL;
               v_Error_Message := SUBSTR (SQLERRM, 1, 200);

               INSERT INTO WCT_ERROR_LOG
                    VALUES ('ADD_UPDATE_CUSTOMER_DETAILS',
                            lv_User_Id,
                            'UPDATE_CUSTOMER_DETAILS: ' || v_Error_Message,
                            SYSDATE);
         END;
      END IF;

      o_Response_Object :=
         WCT_RESPONSE_OBJECT (lv_Response_Type, lv_Response_Message);
   END;

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
      o_Response_Object            OUT WCT_RESPONSE_OBJECT)
   IS
      lv_User_Id                 VARCHAR2 (12 BYTE);
      lv_User_Name               VARCHAR2 (50 BYTE);
      lv_Status                  VARCHAR2 (15 BYTE);
      lv_Job_Title               VARCHAR2 (50 BYTE);
      lv_Email_Address           VARCHAR2 (22 BYTE);
      lv_Phone_Number            VARCHAR2 (20 BYTE);
      lv_Cell_Number             VARCHAR2 (20 BYTE);
      lv_Access_Type_Admin       VARCHAR2 (1 BYTE);
      lv_Access_Type_Read_Only   VARCHAR2 (1 BYTE);
      lv_Action_Type             VARCHAR2 (6 BYTE);

      lv_Response_Message        VARCHAR2 (200 BYTE);
      lv_Response_Type           VARCHAR2 (7 BYTE);

      lv_Active_Customer_Count   NUMBER := 0;
      lv_User_Count              NUMBER := 0;
   BEGIN
      lv_User_Id := i_User_Id;
      lv_User_Name := i_User_Name;
      lv_Status := i_Status;
      lv_Job_Title := i_Job_Title;
      lv_Email_Address := i_Email_Address;
      lv_Phone_Number := i_Phone_Number;
      lv_Cell_Number := i_Cell_Number;
      lv_Access_Type_Admin := i_Access_Type_Admin;
      lv_Access_Type_Read_Only := i_Access_Type_Read_Only;
      lv_Action_Type := i_Action_Type;

      IF (lv_Action_Type = v_Action_Type_Add)
      THEN
         BEGIN
            SELECT COUNT (*)
              INTO lv_User_Count
              FROM WCT_USERS
             WHERE USER_ID = lv_User_Id;

            IF (lv_User_Count = 0)
            THEN
               INSERT INTO WCT_USERS (USER_ID,
                                      USER_NAME,
                                      JOB_TITLE,
                                      EMAIL_ADDRESS,
                                      PHONE_NUM,
                                      CELL_NUM,
                                      STATUS,
                                      IS_ADMIN,
                                      IS_READ_ONLY,
                                      ROLE,
                                      APPROVER_LEVEL,
                                      CREATED_BY,
                                      CREATED_DATE)
                    VALUES (lv_User_Id,
                            lv_User_Name,
                            lv_Job_Title,
                            lv_Email_Address,
                            lv_Phone_Number,
                            lv_Cell_Number,
                            lv_Status,
                            lv_Access_Type_Admin,
                            lv_Access_Type_Read_Only,
                            'USER',                                    -- ROLE
                            0,                               -- APPROVER_LEVEL
                            lv_User_Id,
                            SYSDATE);

               lv_Response_Type := v_Status_Success;
               lv_Response_Message := 'User details added successfully.';
            ELSE
               lv_Response_Type := v_Status_Failure;
               lv_Response_Message :=
                  'User Id <b>' || lv_User_Id || '</b> already exists.';
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_Response_Type := v_Status_Failure;
               lv_Response_Message :=
                  'Add user failed due to some technical reasons. Please contact Excess Portal Support.';

               --LOG EXCEPTION
               v_Error_Message := NULL;
               v_Error_Message := SUBSTR (SQLERRM, 1, 200);

               INSERT INTO WCT_ERROR_LOG
                    VALUES ('ADD_UPDATE_USER_DETAILS',
                            lv_User_Id,
                            'ADD_USER_DETAILS: ' || v_Error_Message,
                            SYSDATE);
         END;
      ELSIF (lv_Action_Type = v_Action_Type_Update)
      THEN
         BEGIN
            SELECT COUNT (*)
              INTO lv_Active_Customer_Count
              FROM WCT_CUSTOMER
             WHERE SALES_PERSON = lv_User_Id AND STATUS = v_Status_Active;

            IF (    (UPPER (lv_Status) = v_Status_Inactive)
                AND (lv_Active_Customer_Count > 0))
            THEN
               lv_Response_Type := v_Status_Failure;
               lv_Response_Message :=
                  'System identified active customers for the user.';
            ELSE
               UPDATE WCT_USERS
                  SET USER_NAME = lv_User_Name,
                      JOB_TITLE = lv_Job_Title,
                      EMAIL_ADDRESS = lv_Email_Address,
                      PHONE_NUM = lv_Phone_Number,
                      CELL_NUM = lv_Cell_Number,
                      STATUS = lv_Status,
                      IS_ADMIN = lv_Access_Type_Admin,
                      IS_READ_ONLY = lv_Access_Type_Read_Only
                WHERE USER_ID = lv_User_Id;

               IF (SQL%ROWCOUNT > 0)
               THEN
                  lv_Response_Type := v_Status_Success;
                  lv_Response_Message := 'Data updated successfully.';
               ELSE
                  lv_Response_Type := v_Status_Failure;
                  lv_Response_Message := 'No data updated.';
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               lv_Response_Type := v_Status_Failure;
               lv_Response_Message :=
                  'Update failed due to some technical reasons. Please contact Excess Portal Support.';

               --LOG EXCEPTION
               v_Error_Message := NULL;
               v_Error_Message := SUBSTR (SQLERRM, 1, 200);

               INSERT INTO WCT_ERROR_LOG
                    VALUES ('ADD_UPDATE_USER_DETAILS',
                            lv_User_Id,
                            'UPDATE_USER_DETAILS: ' || v_Error_Message,
                            SYSDATE);
         END;
      END IF;

      o_Response_Object :=
         WCT_RESPONSE_OBJECT (lv_Response_Type, lv_Response_Message);
   END;

   /* PROCEDURE TO ADD STATIC PRICE PART DETAILS */

   PROCEDURE ADD_STATIC_PRICE_DETAILS (
      i_User_Id                    IN     VARCHAR2,
      i_Static_Price_Detail_List   IN     WCT_ADD_STATIC_PRICE_LIST,
      o_Response_Object               OUT WCT_ADD_DATA_RESPONSE_OBJECT)
   IS
      v_Static_Price_Detail_List   WCT_ADD_STATIC_PRICE_LIST;
      v_Success_List               WCT_ADD_DATA_RESPONSE_LIST;
      v_Error_List                 WCT_ADD_DATA_RESPONSE_LIST;
      lv_User_Id                   VARCHAR2 (12);
      lv_Line_No                   VARCHAR2 (1000);
      lv_Success_Message           VARCHAR2 (1000);
      lv_Error_Message             VARCHAR2 (1000);
      lv_Date                      DATE;
      lv_Success_Count             NUMBER;
      lv_Error_Count               NUMBER;
      lv_Part_Number_Count         NUMBER;
      lv_Part_Validity_Flag        CHAR;
      lv_Part_Number               VARCHAR2 (50 BYTE);
   BEGIN
      v_Static_Price_Detail_List := i_Static_Price_Detail_List;
      lv_User_Id := i_User_Id;
      lv_Date := SYSDATE;

      v_Success_List := WCT_ADD_DATA_RESPONSE_LIST ();
      v_Error_List := WCT_ADD_DATA_RESPONSE_LIST ();

      lv_Success_Count := 1;
      lv_Error_Count := 1;


      FOR idx IN 1 .. v_Static_Price_Detail_List.COUNT ()
      LOOP
         lv_Line_No := v_Static_Price_Detail_List (idx).LINE_NO;
         lv_Part_Number := v_Static_Price_Detail_List (idx).PART_NUMBER;
         lv_Part_Number_Count := 0;
         lv_Error_Message := v_Empty_String;
         lv_Success_Message := v_Empty_String;

         SELECT COUNT (*)
           INTO lv_Part_Number_Count
           FROM WCT_STATIC_PRICE_MASTER
          WHERE UPPER (PRODUCT_ID) = UPPER (lv_Part_Number);

         -- If no Part Details with same part number found, insert a new row
         IF (lv_Part_Number_Count = 0)
         THEN
            BEGIN
               lv_Part_Validity_Flag :=
                  VV_RSCM_UTIL.VALIDATE_PART_ID_EXCESS_MODIFY (
                     lv_Part_Number,
                     NULL);

               -- If invalid part found, add it to invalid part list
               IF (lv_Part_Validity_Flag = v_Flag_No)
               THEN
                  lv_Error_Message :=
                        'System identified invalid part number '
                     || lv_Part_Number;
               ELSE
                  INSERT INTO WCT_STATIC_PRICE_MASTER (STATIC_PRICE_ID,
                                                       PRODUCT_ID,
                                                       TIER1,
                                                       TIER2,
                                                       TIER3,
                                                       CREATED_BY,
                                                       CREATED_DATE,
                                                       UPDATED_BY,
                                                       UPDATED_ON)
                       VALUES (WCT_STATIC_PRICE_SEQ.NEXTVAL,
                               lv_Part_Number,
                               v_Static_Price_Detail_List (idx).TIER1,
                               v_Static_Price_Detail_List (idx).TIER2,
                               v_Static_Price_Detail_List (idx).TIER3,
                               lv_User_Id,
                               lv_Date,
                               lv_User_Id,
                               lv_Date);

                  lv_Success_Message :=
                        'Details for '
                     || lv_Part_Number
                     || ' added successfully';
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  lv_Error_Message :=
                     'An error occurred while adding Part details';
            END;
         ELSE
            -- update logic
            BEGIN
               UPDATE WCT_STATIC_PRICE_MASTER
                  SET TIER1 = v_Static_Price_Detail_List (idx).TIER1,
                      TIER2 = v_Static_Price_Detail_List (idx).TIER2,
                      TIER3 = v_Static_Price_Detail_List (idx).TIER3,
                      UPDATED_BY = lv_User_Id,
                      UPDATED_ON = lv_Date
                WHERE UPPER (PRODUCT_ID) = UPPER (lv_Part_Number);

               lv_Success_Message :=
                  'Details for ' || lv_Part_Number || ' updated successfully';
            EXCEPTION
               WHEN OTHERS
               THEN
                  lv_Error_Message :=
                     'An error occurred while adding Part details';
            END;
         END IF;

         IF (LENGTH (lv_Error_Message) > 0)
         THEN
            lv_Error_Message := lv_Error_Message || ' at Line# ' || lv_Line_No;
            v_Error_List.EXTEND ();
            v_Error_List (lv_Error_Count) := lv_Error_Message;
            lv_Error_Count := lv_Error_Count + 1;
         END IF;

         IF (LENGTH (lv_Success_Message) > 0)
         THEN
            lv_Success_Message :=
               lv_Success_Message || ' at Line# ' || lv_Line_No;
            v_Success_List.EXTEND ();
            v_Success_List (lv_Success_Count) := lv_Success_Message;
            lv_Success_Count := lv_Success_Count + 1;
         END IF;
      END LOOP;

      o_Response_Object :=
         WCT_ADD_DATA_RESPONSE_OBJECT (v_Success_List, v_Error_List);
   END;

   /* PROCEDURE TO UPDATE APPROVER DETAILS */

   PROCEDURE SAVE_APPROVERS (
      i_User_Id                 IN     VARCHAR2,
      i_Level_0_Approver_List   IN     WCT_VARCHAR_LIST,
      i_Level_1_Approver_List   IN     WCT_VARCHAR_LIST,
      i_Level_2_Approver_List   IN     WCT_VARCHAR_LIST,
      o_Response_Object            OUT WCT_RESPONSE_OBJECT)
   IS
      lv_User_Id            VARCHAR2 (12);

      lv_Response_Message   VARCHAR2 (200 BYTE);
      lv_Response_Type      VARCHAR2 (7 BYTE);
   BEGIN
      lv_User_Id := i_User_Id;

      BEGIN
         COMMIT;

         FORALL idx
             IN i_Level_0_Approver_List.FIRST .. i_Level_0_Approver_List.LAST
            UPDATE WCT_USERS
               SET APPROVER_LEVEL = 0
             WHERE USER_ID IN i_Level_0_Approver_List (idx);

         FORALL idx
             IN i_Level_1_Approver_List.FIRST .. i_Level_1_Approver_List.LAST
            UPDATE WCT_USERS
               SET APPROVER_LEVEL = 1
             WHERE USER_ID IN i_Level_1_Approver_List (idx);

         FORALL idx
             IN i_Level_2_Approver_List.FIRST .. i_Level_2_Approver_List.LAST
            UPDATE WCT_USERS
               SET APPROVER_LEVEL = 2
             WHERE USER_ID IN i_Level_2_Approver_List (idx);

         lv_Response_Type := v_Status_Success;
         lv_Response_Message := 'Data updated successfully.';
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            lv_Response_Type := v_Status_Failure;
            lv_Response_Message :=
               'Update failed due to some technical reasons. Please contact Excess Portal Support.';
            ROLLBACK;
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message := SUBSTR (SQLERRM, 1, 200);

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('SAVE_APPROVERS',
                         lv_User_Id,
                         v_Error_Message,
                         SYSDATE);
      END;

      o_Response_Object :=
         WCT_RESPONSE_OBJECT (lv_Response_Type, lv_Response_Message);
   END;

   /* PROCEDURE TO FETCH QUOTE DETAILS FOR APPROVAL */

   PROCEDURE VIEW_APPROVE_QUOTE_DETAILS (
      i_Quote_Id                    IN     VARCHAR2,
      i_Approver_Level              IN     VARCHAR2,
      o_View_Quote_Details_Object      OUT WCT_VIEW_QUOTE_DETAILS_OBJECT)
   IS
      v_View_Quote_Details_Object   WCT_VIEW_QUOTE_DETAILS_OBJECT;
      v_Quote_Line_List             WCT_QUOTE_LINE_LIST;
      v_Quote_Line_List_Temp_1      WCT_QUOTE_LINE_LIST;
      v_Quote_Line_List_Temp_2      WCT_QUOTE_LINE_LIST;
      v_Customer_Detail_Object      WCT_CUSTOMER_DETAIL_OBJECT;
      v_User_Detail_Object          WCT_USER_DETAIL_OBJECT;

      lv_Approver_Level             NUMBER;
      lv_Quote_Created_Date         DATE;
      lv_Quote_Id                   VARCHAR2 (10);
      lv_Customer_Id                NUMBER;
      lv_Created_By                 VARCHAR2 (12);
      lv_Job_Title                  VARCHAR2 (50);
      lv_User_Name                  VARCHAR2 (50);
      lv_Phone_Num                  VARCHAR2 (20);
      lv_Cell_Num                   VARCHAR2 (20);
      lv_Email_Address              VARCHAR2 (22);
      lv_User_Notes                 VARCHAR2 (1500);

      lv_Company_Name               VARCHAR2 (50);
      lv_Customer_First_Name        VARCHAR2 (25);
      lv_Customer_Last_Name         VARCHAR2 (25);
      lv_Customer_Title             VARCHAR2 (4);
      lv_Address_1                  VARCHAR2 (100);
      lv_Address_2                  VARCHAR2 (100);
      lv_City                       VARCHAR2 (20);
      lv_State                      VARCHAR2 (20);
      lv_Country                    VARCHAR2 (20);
      lv_Zip                        VARCHAR2 (10);
      lv_Eos_Over_Date              DATE;

      lv_Count_Temp_1               NUMBER := 1;
      lv_Count_Temp_2               NUMBER := 1;
   BEGIN
      lv_Quote_Id := i_Quote_Id;
      lv_Approver_Level := i_Approver_Level;
      v_Quote_Line_List := WCT_QUOTE_LINE_LIST ();
      v_Quote_Line_List_Temp_1 := WCT_QUOTE_LINE_LIST ();
      v_Quote_Line_List_Temp_2 := WCT_QUOTE_LINE_LIST ();


      -- Fetch Customer Id and User Id from Quote Id
      SELECT CUSTOMER_ID,
             CREATED_BY,
             CREATED_DATE,
             NVL (USER_NOTES, v_Empty_String)
        INTO lv_Customer_Id,
             lv_Created_By,
             lv_Quote_Created_Date,
             lv_User_Notes
        FROM WCT_QUOTE_HEADER
       WHERE QUOTE_ID = lv_Quote_Id;

      -- GENERATE USER DETAIL OBJECT
      BEGIN
         SELECT JOB_TITLE,
                USER_NAME,
                NVL (PHONE_NUM, v_Empty_String),
                NVL (CELL_NUM, v_Empty_String),
                EMAIL_ADDRESS
           INTO lv_Job_Title,
                lv_User_Name,
                lv_Phone_Num,
                lv_Cell_Num,
                lv_Email_Address
           FROM WCT_USERS
          WHERE USER_ID = lv_Created_By;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            --LOG EXCEPTION
            INSERT INTO WCT_ERROR_LOG
                 VALUES ('GENERATE USER DETAIL OBJECT',
                         lv_Created_By,
                         'LOAD_RETRIEVE_QUOTE_DETAILS - No data found',
                         SYSDATE);
         WHEN OTHERS
         THEN
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message := SUBSTR (SQLERRM, 1, 200);

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('GENERATE USER DETAIL OBJECT',
                         lv_Created_By,
                         'LOAD_RETRIEVE_QUOTE_DETAILS - ' || v_Error_Message,
                         SYSDATE);
      END;

      v_User_Detail_Object :=
         WCT_USER_DETAIL_OBJECT (lv_Created_By,
                                 lv_User_Name,
                                 lv_Job_Title,
                                 lv_Phone_Num,
                                 lv_Cell_Num,
                                 lv_Email_Address,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL);

      -- GENERATE CUSTOMER DETAIL OBJECT
      BEGIN
         SELECT COMPANY_NAME,
                POC_FIRST_NAME,
                POC_LAST_NAME,
                POC_TITLE,
                ADDRESS_1,
                ADDRESS_2,
                CITY,
                STATE,
                COUNTRY,
                ZIP
           INTO lv_Company_Name,
                lv_Customer_First_Name,
                lv_Customer_Last_Name,
                lv_Customer_Title,
                lv_Address_1,
                lv_Address_2,
                lv_City,
                lv_State,
                lv_Country,
                lv_Zip
           FROM WCT_CUSTOMER CUST, WCT_COMPANY_MASTER COM
          WHERE     CUSTOMER_ID = lv_Customer_Id
                AND CUST.COMPANY_ID = COM.COMPANY_ID;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            --LOG EXCEPTION
            INSERT INTO WCT_ERROR_LOG
                 VALUES ('GENERATE CUSTOMER DETAIL OBJECT',
                         lv_Created_By,
                         'ADMIN_PREVIEW_QUOTE_DETAILS - No data found',
                         SYSDATE);
         WHEN OTHERS
         THEN
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message := SUBSTR (SQLERRM, 1, 200);

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('GENERATE CUSTOMER DETAIL OBJECT',
                         lv_Created_By,
                         'ADMIN_PREVIEW_QUOTE_DETAILS - ' || v_Error_Message,
                         SYSDATE);
      END;

      v_Customer_Detail_Object :=
         WCT_CUSTOMER_DETAIL_OBJECT (lv_Company_Name,
                                     lv_Customer_First_Name,
                                     lv_Customer_Last_Name,
                                     lv_Customer_Title,
                                     lv_Address_1,
                                     lv_Address_2,
                                     lv_City,
                                     lv_State,
                                     lv_Country,
                                     lv_Zip);

      -- GENERATE QUOTE LINE LIST
      BEGIN
         SELECT ADD_MONTHS (SYSDATE, -12) INTO lv_Eos_Over_Date FROM DUAL;

         IF (lv_Approver_Level = 1)
         THEN
              SELECT WCT_QUOTE_LINE_OBJECT (
                        LINE_ID,
                        NULL,                                       --QUOTE_ID
                        NULL,                                        --LINE_NO
                        REQUESTED_PART,
                        WHOLESALE_PART,
                        REQUESTED_QUANTITY,
                        LEAST (REQUESTED_QUANTITY, AVAILABLE_QUANTITY),
                        NULL,                                   --BROKER_OFFER
                        GLP,
                        SUGGESTED_PRICE,
                        EXT_SELL_PRICE,
                        NULL,                                      --LEAD_TIME
                        NULL,                              --ENCRYPTION_STATUS
                        NULL,                         --INVENTORY_DETAIL_NOTES
                        DISCOUNT,
                        NVL (COMMENTS_L1, v_Empty_String),
                        NVL (COMMENTS_L2, v_Empty_String),
                        EOS_DATE,
                        APPROVAL_LEVEL,
                        APPROVAL_STATUS_L1,
                        APPROVAL_STATUS_L2,
                        NULL,                                         --ROW_ID
                        CASE                                         --N_VALUE
                           WHEN EOS_DATE <= TRUNC (lv_Eos_Over_Date)
                           THEN
                              'N - 2'
                           WHEN EOS_DATE <= TRUNC (SYSDATE)
                           THEN
                              'N - 1'
                           ELSE
                              'N'
                        END,
                        GET_RECENT_QUOTE_DETAILS (REQUESTED_PART, NULL),
                        NULL,                              -- QUANTITY_ON_HAND
                        NULL,                           -- QUANTITY_IN_TRANSIT
                        NVL(PROMO_FLAG,'N') -- US151907
                        )
                BULK COLLECT INTO v_Quote_Line_List
                FROM WCT_QUOTE_LINE
               WHERE QUOTE_ID = lv_Quote_Id
            ORDER BY APPROVAL_LEVEL ASC, LINE_ID ASC;

            --AND APPROVAL_STATUS_L1 = v_Approval_Status_Pending; -- level 1 pending

            -- iterate over the set and separate out items in 2 groups: L0 and L1,L2
            FOR idx IN 1 .. v_Quote_Line_List.COUNT
            LOOP
               IF (v_Quote_Line_List (idx).APPROVAL_LEVEL = 0)
               THEN
                  v_Quote_Line_List_Temp_1.EXTEND ();
                  v_Quote_Line_List_Temp_1 (lv_Count_Temp_1) :=
                     v_Quote_Line_List (idx);
                  lv_Count_Temp_1 := lv_Count_Temp_1 + 1;
               ELSE
                  v_Quote_Line_List_Temp_2.EXTEND ();
                  v_Quote_Line_List_Temp_2 (lv_Count_Temp_2) :=
                     v_Quote_Line_List (idx);
                  lv_Count_Temp_2 := lv_Count_Temp_2 + 1;
               END IF;
            END LOOP;

            -- append L0 items to L1,L2 items
            FOR idx IN 1 .. v_Quote_Line_List_Temp_1.COUNT
            LOOP
               v_Quote_Line_List_Temp_2.EXTEND ();
               v_Quote_Line_List_Temp_2 (lv_Count_Temp_2) :=
                  v_Quote_Line_List_Temp_1 (idx);
               lv_Count_Temp_2 := lv_Count_Temp_2 + 1;
            END LOOP;

            v_Quote_Line_List := v_Quote_Line_List_Temp_2;
         ELSE
              SELECT WCT_QUOTE_LINE_OBJECT (
                        LINE_ID,
                        NULL,                                       --QUOTE_ID
                        NULL,                                        --LINE_NO
                        REQUESTED_PART,
                        WHOLESALE_PART,
                        REQUESTED_QUANTITY,
                        LEAST (REQUESTED_QUANTITY, AVAILABLE_QUANTITY),
                        NULL,                                   --BROKER_OFFER
                        GLP,
                        SUGGESTED_PRICE,
                        EXT_SELL_PRICE,
                        NULL,                                      --LEAD_TIME
                        NULL,                              --ENCRYPTION_STATUS
                        NULL,                         --INVENTORY_DETAIL_NOTES
                        DISCOUNT,
                        NVL (COMMENTS_L1, v_Empty_String),
                        NVL (COMMENTS_L2, v_Empty_String),
                        EOS_DATE,
                        APPROVAL_LEVEL,
                        APPROVAL_STATUS_L1,
                        APPROVAL_STATUS_L2,
                        NULL,                                         --ROW_ID
                        CASE                                         --N_VALUE
                           WHEN EOS_DATE <= TRUNC (lv_Eos_Over_Date)
                           THEN
                              'N - 2'
                           WHEN EOS_DATE <= TRUNC (SYSDATE)
                           THEN
                              'N - 1'
                           ELSE
                              'N'
                        END,
                        GET_RECENT_QUOTE_DETAILS (REQUESTED_PART, NULL),
                        NULL,                              -- QUANTITY_ON_HAND
                        NULL,                           -- QUANTITY_IN_TRANSIT
                        NVL(PROMO_FLAG,'N') -- US151907
                        )
                BULK COLLECT INTO v_Quote_Line_List
                FROM WCT_QUOTE_LINE
               WHERE QUOTE_ID = lv_Quote_Id
            ORDER BY APPROVAL_LEVEL DESC, LINE_ID ASC;
         --                   AND APPROVAL_LEVEL = lv_Approver_Level
         --                   AND APPROVAL_STATUS_L1 = v_Approval_Status_Approved -- level 1 approved
         --           AND APPROVAL_STATUS_L2 = v_Approval_Status_Pending; -- level 2 pending
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            --LOG EXCEPTION
            INSERT INTO WCT_ERROR_LOG
                 VALUES ('GENERATE QUOTE LINE LIST',
                         lv_Created_By,
                         'ADMIN_PREVIEW_QUOTE_DETAILS - No data found',
                         SYSDATE);
         WHEN OTHERS
         THEN
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message := SUBSTR (SQLERRM, 1, 200);

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('GENERATE QUOTE LINE LIST',
                         lv_Created_By,
                         'ADMIN_PREVIEW_QUOTE_DETAILS - ' || v_Error_Message,
                         SYSDATE);
      END;

      v_View_Quote_Details_Object :=
         WCT_VIEW_QUOTE_DETAILS_OBJECT (v_Customer_Detail_Object,
                                        v_User_Detail_Object,
                                        v_Quote_Line_List,
                                        lv_Quote_Created_Date,
                                        lv_User_Notes);

      o_View_Quote_Details_Object := v_View_Quote_Details_Object;
   END;

   /* PROCEDURE TO UPDATE APPROVAL/REJECTION FOR QUOTE LINES */

   --   PROCEDURE APPROVAL_WORKFLOW_ACTION (
   --      i_User_Id           IN     VARCHAR2,
   --      i_Quote_Id          IN     VARCHAR2,
   --      i_Approver_Level    IN     NUMBER,
   --      i_Approval_Status   IN     CHAR,
   --      i_Quote_Line_List   IN     WCT_QUOTE_LINE_LIST,
   --      o_Response_Object      OUT WCT_RESPONSE_OBJECT)
   --   IS
   --      v_Quote_Line_List              WCT_QUOTE_LINE_LIST;
   --      lv_User_Id                     VARCHAR2 (12);
   --      lv_Quote_Id                    VARCHAR2 (10);
   --      lv_Approval_Status             CHAR;
   --      lv_Approver_Level              NUMBER;
   --
   --      lv_Quote_Line_Count            NUMBER := 0;
   --      lv_Rejected_Quote_Line_Count   NUMBER := 0;
   --      lv_Approved_Quote_Line_Count   NUMBER := 0;
   --      lv_Pending_Quote_Line_Count    NUMBER := 0;
   --      lv_Quote_Status                VARCHAR2 (8);
   --
   --      lv_Response_Message            VARCHAR2 (200 BYTE);
   --      lv_Response_Type               VARCHAR2 (7 BYTE);
   --
   --      v_To_List                      WCT_VARCHAR_LIST;
   --      v_Cc_List                      WCT_VARCHAR_LIST;
   --      v_Level2_Approvers_List        WCT_VARCHAR_LIST;
   --      lv_From                        VARCHAR2 (50);
   --      lv_Subject                     VARCHAR2 (1000);
   --      lv_Html_Msg                    VARCHAR2 (4000);
   --      lv_Content_Type                VARCHAR2 (8);
   --      lv_Send_Mail                   BOOLEAN := TRUE;
   --   BEGIN
   --      BEGIN
   --         COMMIT;
   --         lv_User_Id := i_User_Id;
   --         lv_Quote_Id := i_Quote_Id;
   --         lv_Approver_Level := i_Approver_Level;
   --         lv_Approval_Status := i_Approval_Status;
   --         v_Quote_Line_List := i_Quote_Line_List;
   --
   --         -- get total line count for the quote
   --         SELECT COUNT (*)
   --           INTO lv_Quote_Line_Count
   --           FROM WCT_QUOTE_LINE
   --          WHERE QUOTE_ID = lv_Quote_Id;
   --
   --         IF (lv_Approver_Level = 2)
   --         THEN
   --            FORALL idx IN v_Quote_Line_List.FIRST .. v_Quote_Line_List.LAST
   --               UPDATE WCT_QUOTE_LINE
   --                  SET APPROVAL_STATUS_L2 = lv_Approval_Status,
   --                      COMMENTS_L2 = v_Quote_Line_List (idx).COMMENTS_L2
   --                WHERE LINE_ID = v_Quote_Line_List (idx).LINE_ID;
   --         ELSIF (lv_Approver_Level = 1)
   --         THEN
   --            FORALL idx IN v_Quote_Line_List.FIRST .. v_Quote_Line_List.LAST
   --               UPDATE WCT_QUOTE_LINE
   --                  SET APPROVAL_STATUS_L1 = lv_Approval_Status,
   --                      COMMENTS_L1 = v_Quote_Line_List (idx).COMMENTS_L1
   --                WHERE LINE_ID = v_Quote_Line_List (idx).LINE_ID;
   --         END IF;
   --
   --
   --         -- Get count of approved lines
   --         SELECT COUNT (*)
   --           INTO lv_Approved_Quote_Line_Count
   --           FROM WCT_QUOTE_LINE
   --          WHERE     QUOTE_ID = lv_Quote_Id
   --                AND APPROVAL_STATUS_L1 = v_Approval_Status_Approved
   --                AND APPROVAL_STATUS_L2 = v_Approval_Status_Approved;
   --
   --         -- if no of lines approved = total no of lines in the quote, set status as QUOTE
   --         IF (lv_Quote_Line_Count = lv_Approved_Quote_Line_Count)
   --         THEN
   --            lv_Quote_Status := v_Status_Quote;
   --            lv_Content_Type := v_Status_Quote;
   --
   --            lv_Response_Type := v_Status_Success;
   --            lv_Response_Message := 'Quote approved by L1.';-- lv_approval_level append
   --         ELSE
   --            -- Get count of rejected lines
   --            SELECT COUNT (*)
   --              INTO lv_Rejected_Quote_Line_Count
   --              FROM WCT_QUOTE_LINE
   --             WHERE QUOTE_ID = lv_Quote_Id
   --                   AND (APPROVAL_STATUS_L1 = v_Approval_Status_Rejected
   --                        OR APPROVAL_STATUS_L2 = v_Approval_Status_Rejected);
   --
   --            -- if no of lines rejected = total no of lines in the quote, set status as REJECTED
   --            IF (lv_Quote_Line_Count = lv_Rejected_Quote_Line_Count)
   --            THEN
   --               lv_Quote_Status := v_Status_Rejected;
   --               lv_Content_Type := v_Status_Rejected;
   --
   --               lv_Response_Message := 'Quote rejected by Level 1 Approver';-- quote line
   --            ELSE
   --               SELECT COUNT (*)
   --                 INTO lv_Pending_Quote_Line_Count
   --                 FROM WCT_QUOTE_LINE
   --                WHERE QUOTE_ID = lv_Quote_Id
   --                      AND ( (APPROVAL_STATUS_L1 = v_Approval_Status_Pending
   --                             AND APPROVAL_STATUS_L2 =
   --                                    v_Approval_Status_Pending)
   --                           OR (APPROVAL_STATUS_L1 =
   --                                  v_Approval_Status_Approved
   --                               AND APPROVAL_STATUS_L2 =
   --                                      v_Approval_Status_Pending));
   --
   --               --Message updated for approval workflow
   --               lv_Response_Type := v_Status_Success;
   --               lv_Response_Message :=
   --                  'Quote approved successfully by L1. Requires L2 approval';
   --
   --               -- if no of lines pending = total no of lines in the quote, set status as PENDING
   --               IF (lv_Quote_Line_Count = lv_Pending_Quote_Line_Count)
   --               THEN
   --                  lv_Quote_Status := v_Status_Pending;
   --                  lv_Content_Type := v_Status_Pending;
   --               -- else set the status as PARTIAL
   --               ELSE
   --                  lv_Quote_Status := v_Status_Partial;  --quote updated successfully
   --
   --                  -- Setting content type for email - Partially rejected
   --                  IF ( (lv_Rejected_Quote_Line_Count > 0)
   --                      AND (lv_Approved_Quote_Line_Count > 0)
   --                      AND (lv_Approved_Quote_Line_Count
   --                           + lv_Rejected_Quote_Line_Count =
   --                              lv_Quote_Line_Count))
   --                  THEN
   --                     lv_Content_Type := v_Status_Partial;
   --                  ELSE
   --                     lv_Content_Type := v_Status_Pending;
   --                  END IF;
   --
   --                  lv_Response_Type := v_Status_Success;
   --                  lv_Response_Message :=
   --                     'Quote Status is .' || lv_Quote_Status || '</b>.';
   --               END IF;
   --            END IF;
   --         END IF;
   --
   --         IF (lv_Approver_Level = 2)
   --         THEN
   --            UPDATE WCT_QUOTE_HEADER
   --               SET STATUS = lv_Quote_Status, APPROVER_LEVEL_2 = lv_User_Id
   --             WHERE QUOTE_ID = lv_Quote_Id;
   --         ELSE
   --            UPDATE WCT_QUOTE_HEADER
   --               SET STATUS = lv_Quote_Status, APPROVER_LEVEL_1 = lv_User_Id
   --             WHERE QUOTE_ID = lv_Quote_Id;
   --
   --            -- Get line count that require level 2 approval
   --            SELECT COUNT (*)
   --              INTO lv_Pending_Quote_Line_Count
   --              FROM WCT_QUOTE_LINE
   --             WHERE QUOTE_ID = lv_Quote_Id
   --                   AND (APPROVAL_STATUS_L1 = v_Approval_Status_Approved
   --                        AND APPROVAL_STATUS_L2 = v_Approval_Status_Pending);
   --
   --            IF (lv_Pending_Quote_Line_Count > 0)
   --            THEN
   --               lv_Approver_Level := 2;
   --            END IF;
   --         END IF;
   --
   --         --         lv_Response_Type := v_Status_Success;
   --         --          lv_Response_Message := lv_Response_Message ||
   --         --           '. Quote Approved .'  'Quote updated successfully. New status for Quote is <b>'
   --         --                            || lv_Quote_Status || '</b>.';
   --
   --         /* If  approver is a level 1 approver, and quote had lines pending for
   --         level 1 approval, mail should not be sent again */
   --         IF (lv_Approver_Level = 1 AND lv_Content_Type = v_Status_Pending)
   --         THEN
   --            lv_Send_Mail := FALSE;
   --         END IF;
   --
   --         --         IF (lv_Approver_Level = 1 AND lv_Content_Type = v_Status_Partial)
   --         --         THEN
   --         --            lv_Send_Mail := TRUE;
   --         --         END IF;
   --
   --         -- Email functionality
   --         IF (lv_Send_Mail)
   --         THEN
   --            BEGIN
   --               -- generate email content
   --               GENERATE_EMAIL_CONTENT (lv_User_Id,
   --                                       lv_Quote_Id,
   --                                       lv_Content_Type,
   --                                       lv_Approver_Level,
   --                                       v_To_List,
   --                                       v_Cc_List,
   --                                       v_Level2_Approvers_List,
   --                                       lv_From,
   --                                       lv_Subject,
   --                                       lv_Html_Msg);
   --               -- send email
   --               EMAIL_UTIL (v_To_List,
   --                           v_Cc_List,
   --                           lv_From,
   --                           lv_Subject,
   --                           lv_Html_Msg);
   --            EXCEPTION
   --               WHEN OTHERS
   --               THEN
   --                  --LOG EXCEPTION
   --                  v_Error_Message := NULL;
   --                  v_Error_Message := SUBSTR (SQLERRM, 1, 200);
   --
   --                  INSERT INTO WCT_ERROR_LOG
   --                       VALUES ('APPROVAL_WORKFLOW_ACTION',
   --                               lv_User_Id,
   --                               'EMAIL GENERATION - ' || v_Error_Message,
   --                               SYSDATE);
   --            END;
   --         END IF;
   --      EXCEPTION
   --         WHEN OTHERS
   --         THEN
   --            lv_Response_Type := v_Status_Failure;
   --            lv_Response_Message :=
   --               'Update failed due to some technical reasons. Please contact WRT-Support.';
   --            ROLLBACK;
   --      END;
   --
   --      --dbms_output.put_line(lv_Response_Type || ' and ' ||lv_Response_Message );
   --      o_Response_Object :=
   --         WCT_RESPONSE_OBJECT (lv_Response_Type, lv_Response_Message);
   --   END;


   PROCEDURE APPROVAL_WORKFLOW_ACTION (
      i_User_Id           IN     VARCHAR2,
      i_Quote_ID          IN     VARCHAR2,
      i_Approver_Level    IN     NUMBER,
      i_Approval_Status   IN     CHAR,
      i_Quote_Line_List   IN     WCT_QUOTE_LINE_LIST,
      o_Response_Object      OUT WCT_RESPONSE_OBJECT)
   IS
      v_Quote_Line_List        WCT_QUOTE_LINE_LIST;

      lv_User_Id               VARCHAR2 (12);
      lv_Quote_Id              VARCHAR2 (10);
      lv_Approval_Status       CHAR;
      lv_Approver_Level        NUMBER;
      lv_Quote_Status          VARCHAR2 (8);
      lv_Date                  DATE;

      lv_Pending_Count_L1      NUMBER := 0;
      lv_Pending_Count_L2      NUMBER := 0;
      lv_Rejected_Count_L1     NUMBER := 0;
      lv_Rejected_Count_L2     NUMBER := 0;
      lv_Approved_Count_L1     NUMBER := 0;
      lv_Approved_Count_L2     NUMBER := 0;

      lv_Response_Message      VARCHAR2 (200 BYTE);
      lv_Response_Type         VARCHAR2 (7 BYTE);

      v_To_List                WCT_VARCHAR_LIST;
      v_Cc_List                WCT_VARCHAR_LIST;

      lv_From                  VARCHAR2 (50);
      lv_Html_Msg              CLOB;
      lv_Subject               VARCHAR2 (1000);
      lv_Send_Mail             BOOLEAN := TRUE;
      lv_Mail_Content_Status   VARCHAR2 (8);
      lv_Mail_Approver_Level   NUMBER;
   BEGIN
      lv_User_Id := i_User_Id;
      lv_Quote_Id := i_Quote_Id;
      lv_Approver_Level := i_Approver_Level;
      lv_Approval_Status := i_Approval_Status;
      v_Quote_Line_List := i_Quote_Line_List;
      lv_Response_Type := v_Status_Success;
      lv_Mail_Approver_Level := lv_Approver_Level;
      lv_Date := SYSDATE;

      BEGIN
         COMMIT;

         -- UPDATE WCT_QUOTE_LINE TABLE
         IF (lv_Approver_Level = 2)
         THEN
            FORALL idx IN v_Quote_Line_List.FIRST .. v_Quote_Line_List.LAST
               UPDATE WCT_QUOTE_LINE
                  SET APPROVAL_STATUS_L2 = lv_Approval_Status,
                      COMMENTS_L2 = v_Quote_Line_List (idx).COMMENTS_L2,
                      LAST_UPDATED_DATE = lv_Date,
                      LAST_UPDATED_BY = lv_User_Id
                WHERE     LINE_ID = v_Quote_Line_List (idx).LINE_ID
                      AND APPROVAL_STATUS_L2 = v_Approval_Status_Pending;
         ELSIF (lv_Approver_Level = 1)
         THEN
            -- If Line rejected by Level 1 Approver, set the status for both L1 and L2 as rejected
            IF (lv_Approval_Status = v_Approval_Status_Rejected)
            THEN
               FORALL idx
                   IN v_Quote_Line_List.FIRST .. v_Quote_Line_List.LAST
                  UPDATE WCT_QUOTE_LINE
                     SET APPROVAL_STATUS_L1 = lv_Approval_Status,
                         APPROVAL_STATUS_L2 = lv_Approval_Status,
                         COMMENTS_L1 = v_Quote_Line_List (idx).COMMENTS_L1,
                         LAST_UPDATED_DATE = lv_Date,
                         LAST_UPDATED_BY = lv_User_Id
                   WHERE     LINE_ID = v_Quote_Line_List (idx).LINE_ID
                         AND APPROVAL_STATUS_L1 = v_Approval_Status_Pending;
            ELSE
               FORALL idx
                   IN v_Quote_Line_List.FIRST .. v_Quote_Line_List.LAST
                  UPDATE WCT_QUOTE_LINE
                     SET APPROVAL_STATUS_L1 = lv_Approval_Status,
                         COMMENTS_L1 = v_Quote_Line_List (idx).COMMENTS_L1,
                         LAST_UPDATED_DATE = lv_Date,
                         LAST_UPDATED_BY = lv_User_Id
                   WHERE     LINE_ID = v_Quote_Line_List (idx).LINE_ID
                         AND APPROVAL_STATUS_L1 = v_Approval_Status_Pending;
            END IF;
         END IF;

         -- GENERATE EMAIL CONTENT

         -- Empty Cc list
         v_Cc_List := WCT_VARCHAR_LIST ();

         SELECT COUNT (*)
           INTO lv_Pending_Count_L1
           FROM WCT_QUOTE_LINE
          WHERE     QUOTE_ID = lv_Quote_Id
                AND APPROVAL_STATUS_L1 = v_Approval_Status_Pending;

         SELECT COUNT (*)
           INTO lv_Pending_Count_L2
           FROM WCT_QUOTE_LINE
          WHERE     QUOTE_ID = lv_Quote_Id
                AND APPROVAL_STATUS_L2 = v_Approval_Status_Pending
                AND APPROVAL_STATUS_L1 = v_Approval_Status_Approved; -- Added condition for line to be approved by L1

         -- Get rejected line(s) count
         SELECT COUNT (*)
           INTO lv_Rejected_Count_L1
           FROM WCT_QUOTE_LINE
          WHERE     QUOTE_ID = lv_Quote_Id
                AND APPROVAL_STATUS_L1 = v_Approval_Status_Rejected;

         SELECT COUNT (*)
           INTO lv_Rejected_Count_L2
           FROM WCT_QUOTE_LINE
          WHERE     QUOTE_ID = lv_Quote_Id
                AND APPROVAL_STATUS_L2 = v_Approval_Status_Rejected;

         -- Get approved line(s) count
         SELECT COUNT (*)
           INTO lv_Approved_Count_L1
           FROM WCT_QUOTE_LINE
          WHERE     QUOTE_ID = lv_Quote_Id
                AND APPROVAL_STATUS_L1 = v_Approval_Status_Approved;

         SELECT COUNT (*)
           INTO lv_Approved_Count_L2
           FROM WCT_QUOTE_LINE
          WHERE     QUOTE_ID = lv_Quote_Id
                AND APPROVAL_STATUS_L2 = v_Approval_Status_Approved
                AND APPROVAL_STATUS_L1 = v_Approval_Status_Approved; -- Added condition for line to be approved by L1


         IF (lv_Approver_Level = 1)                        -- Approver level 1
         THEN
            IF (lv_Approval_Status = v_Approval_Status_Approved) -- workflow action APPROVE
            THEN
               IF (lv_Pending_Count_L1 > 0)        -- pending lines at Level 1
               THEN
                  IF (lv_Pending_Count_L2 > 0)     -- pending lines at Level 2
                  THEN
                     lv_Response_Message :=
                        'Quote Line(s) approved at Level 1. Pending For Approval at Level 2. Please approve/reject remaining lines';
                  ELSE                          -- no pending lines at Level 2
                     lv_Response_Message :=
                        'Quote Line(s) approved. Please approve/reject remaining lines';
                  END IF;

                  -- no mail sending
                  lv_Send_Mail := FALSE;

                  /*-- New Quote status is PARTIAL
                  --lv_Quote_Status := v_Status_Partial;*/

                  -- New Quote status is PENDING since 1 or more lines are pending for approval
                  lv_Quote_Status := v_Status_Pending;
               ELSE                             -- no pending lines at Level 1
                  IF (lv_Pending_Count_L2 > 0)     -- pending lines at Level 2
                  THEN
                     lv_Response_Message :=
                        'Quote Approved at Level 1 Pending for Approval at Level 2';

                     /*-- New Quote status is PARTIAL
                     lv_Quote_Status := v_Status_Partial;*/

                     -- New Quote status is PENDING since 1 or more lines are pending for approval
                     lv_Quote_Status := v_Status_Pending;
                     lv_Mail_Content_Status := v_Status_Pending;
                     lv_Mail_Approver_Level := 2;
                  -- send mail to level2 approvers only;
                  ELSE                          -- no pending lines at Level 2
                     IF (lv_Rejected_Count_L1 > 0) -- rejected lines at Level 1
                     THEN
                        -- changed from CC list to TO list
                        lv_Response_Message := 'Quote Approved Partially.';

                        -- New Quote status is PARTIAL
                        lv_Quote_Status := v_Status_Partial;
                        lv_Mail_Content_Status := v_Status_Partial;
                     -- send mail to quote creator
                     ELSE                      -- no rejected lines at Level 1
                        -- changed from CC list to TO list
                        lv_Response_Message := 'Quote Approved.';

                        /*-- New Quote status is QUOTE
                        lv_Quote_Status := v_Status_Quote;
                        lv_Mail_Content_Status := v_Status_Quote;*/

                        -- New Quote status is APPROVED
                        lv_Quote_Status := v_Status_Approved;
                        lv_Mail_Content_Status := v_Status_Approved;
                     -- send mail to quote creator
                     END IF;
                  END IF;
               END IF;
            ELSIF (lv_Approval_Status = v_Approval_Status_Rejected) -- workflow action REJECT
            THEN
               IF (lv_Pending_Count_L1 > 0)        -- pending lines at Level 1
               THEN
                  lv_Response_Message :=
                     'Quote Line(s) rejected. Please approve/reject remaining lines';

                  /*-- New Quote status is PARTIAL
                  lv_Quote_Status := v_Status_Partial;*/

                  -- New Quote status is PENDING since 1 or more lines are pending for approval
                  lv_Quote_Status := v_Status_Pending;

                  -- no mail sending
                  lv_Send_Mail := FALSE;
               ELSE                             -- no pending lines at Level 1
                  IF (lv_Pending_Count_L2 > 0)     -- pending lines at Level 2
                  THEN
                     lv_Response_Message :=
                        'Few Quote line rejected at Level 1. Quote pending For Approval at Level 2';

                     /*-- New Quote status is PARTIAL
                     lv_Quote_Status := v_Status_Partial;*/

                     -- New Quote status is PENDING since 1 or more lines are pending for approval
                     lv_Quote_Status := v_Status_Pending;
                     lv_Mail_Content_Status := v_Status_Pending;
                     lv_Mail_Approver_Level := 2;
                  -- send mail to quote creator.
                  ELSE
                     IF (lv_Approved_Count_L1 > 0) -- approved lines at Level 1
                     THEN
                        lv_Response_Message := 'Quote Approved Partially';

                        -- New Quote status is PARTIAL
                        lv_Quote_Status := v_Status_Partial;
                        lv_Mail_Content_Status := v_Status_Partial;
                     -- send mail to quote creator.
                     ELSE                     -- all lines rejected at Level 1
                        lv_Response_Message := 'Quote Rejected.';

                        -- New Quote status is REJECTED
                        lv_Quote_Status := v_Status_Rejected;
                        lv_Mail_Content_Status := v_Status_Rejected;
                     -- send mail to quote creator.
                     END IF;
                  END IF;
               END IF;
            END IF;
         ELSIF (lv_Approver_Level = 2)                     -- Approver level 2
         THEN
            IF (lv_Approval_Status = v_Approval_Status_Approved) -- workflow action APPROVE
            THEN
               IF (lv_Pending_Count_L2 > 0)        -- pending lines at Level 2
               THEN
                  lv_Response_Message :=
                     'Quote Line(s) approved. Please approve/reject remaining lines';

                  /*-- New Quote status is PARTIAL
                  lv_Quote_Status := v_Status_Partial;*/

                  -- New Quote status is PENDING since 1 or more lines are pending for approval
                  lv_Quote_Status := v_Status_Pending;

                  -- no mail sent
                  lv_Send_Mail := FALSE;
               ELSE                             -- no pending lines at Level 2
                  IF (lv_Rejected_Count_L2 > 0)   -- rejected lines at Level 2
                  THEN
                     lv_Response_Message := 'Quote approved Partially';

                     -- New Quote status is PARTIAL
                     lv_Quote_Status := v_Status_Partial;
                     lv_Mail_Content_Status := v_Status_Partial;
                  -- send mail to quote creator.
                  ELSE                         -- no rejected lines at Level 2
                     lv_Response_Message := 'Quote Approved';

                     /*-- New Quote status is QUOTE
                        lv_Quote_Status := v_Status_Quote;
                        lv_Mail_Content_Status := v_Status_Quote;*/

                     -- New Quote status is APPROVED
                     lv_Quote_Status := v_Status_Approved;
                     lv_Mail_Content_Status := v_Status_Approved;
                  -- send mail to quote creator
                  END IF;
               END IF;
            ELSIF (lv_Approval_Status = v_Approval_Status_Rejected) -- workflow action REJECT
            THEN
               IF (lv_Pending_Count_L2 > 0)        -- pending lines at Level 2
               THEN
                  lv_Response_Message :=
                     'Quote Line(s) Rejected. Please approve/reject remaining lines';

                  /*-- New Quote status is PARTIAL
                  lv_Quote_Status := v_Status_Partial;*/

                  -- New Quote status is PENDING since 1 or more lines are pending for approval
                  lv_Quote_Status := v_Status_Pending;

                  -- no mail sent
                  lv_Send_Mail := FALSE;
               ELSE
                  IF (lv_Approved_Count_L2 > 0)   -- approved lines at Level 2
                  THEN
                     lv_Response_Message := 'Quote approved Partially';

                     -- New Quote status is PARTIAL
                     lv_Quote_Status := v_Status_Partial;
                     lv_Mail_Content_Status := v_Status_Partial;
                  -- send mail to quote creator.
                  ELSE
                     lv_Response_Message := 'Quote Rejected';

                     -- New Quote status is REJECTED
                     lv_Quote_Status := v_Status_Rejected;
                     lv_Mail_Content_Status := v_Status_Rejected;
                  -- send mail to quote creator.
                  END IF;
               END IF;
            END IF;
         END IF;

         -- Update Quote Status
         IF (lv_Approver_Level = 2)
         THEN
            UPDATE WCT_QUOTE_HEADER
               SET STATUS = lv_Quote_Status,
                   APPROVER_LEVEL_2 = lv_User_Id,
                   LAST_UPDATED_DATE = lv_Date,
                   LAST_UPDATED_BY = lv_User_Id
             WHERE QUOTE_ID = lv_Quote_Id;
         ELSE
            UPDATE WCT_QUOTE_HEADER
               SET STATUS = lv_Quote_Status,
                   APPROVER_LEVEL_1 = lv_User_Id,
                   LAST_UPDATED_DATE = lv_Date,
                   LAST_UPDATED_BY = lv_User_Id
             WHERE QUOTE_ID = lv_Quote_Id;
         END IF;

         IF (lv_Send_Mail)
         THEN
            BEGIN
               -- Generate mail content
               GENERATE_EMAIL_CONTENT (lv_Quote_Id,
                                       lv_Mail_Content_Status,
                                       lv_Mail_Approver_Level,
                                       v_To_List,
                                       v_Cc_List,
                                       lv_From,
                                       lv_Subject,
                                       lv_Html_Msg);
               -- send email
               EMAIL_UTIL (v_To_List,
                           v_Cc_List,
                           lv_From,
                           lv_Subject,
                           lv_Html_Msg);
            EXCEPTION
               WHEN OTHERS
               THEN
                  lv_Response_Message :=
                        lv_Response_Message
                     || ' The mail could not be sent due to some technical reasons. Please contact Excess Portal Support.';

                  --LOG EXCEPTION
                  v_Error_Message := NULL;
                  v_Error_Message :=
                        SUBSTR (SQLERRM, 1, 200)
                     || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

                  INSERT INTO WCT_ERROR_LOG
                       VALUES ('APPROVAL_WORKFLOW_ACTION',
                               lv_User_Id,
                               'Send Mail: ' || v_Error_Message,
                               SYSDATE);
            END;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            --ROLLBACK;

            lv_Response_Type := v_Status_Failure;
            lv_Response_Message :=
               'Update failed due to some technical reasons. Please contact Excess Portal Support.';
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message :=
                  SUBSTR (SQLERRM, 1, 200)
               || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('APPROVAL_WORKFLOW_ACTION',
                         lv_User_Id,
                         v_Error_Message,
                         SYSDATE);
      END;


      o_Response_Object :=
         WCT_RESPONSE_OBJECT (lv_Response_Type, lv_Response_Message);
   END;


   /* PROCEDURE TO GENERATE EMAIL CONTENT */
   PROCEDURE GENERATE_EMAIL_CONTENT (
      i_Quote_Id         IN     VARCHAR2,
      i_Quote_Status     IN     VARCHAR2,
      i_Approval_Level   IN     NUMBER,
      o_To_List             OUT WCT_VARCHAR_LIST,
      o_Cc_List             OUT WCT_VARCHAR_LIST,
      o_From                OUT VARCHAR2,
      o_Subject             OUT VARCHAR2,
      o_Html_Msg            OUT CLOB)
   IS
      v_To_List                    WCT_VARCHAR_LIST;
      v_Cc_List                    WCT_VARCHAR_LIST;
      v_Approved_Quote_Line_List   WCT_QUOTE_LINE_LIST;
      v_Rejected_Quote_Line_List   WCT_QUOTE_LINE_LIST;

      lv_Created_By                VARCHAR2 (12);
      lv_Approval_Level            NUMBER;
      lv_Quote_Id                  VARCHAR2 (10);
      lv_Quote_Status              VARCHAR2 (50);

      lv_From                      VARCHAR2 (50);
      lv_Subject                   VARCHAR2 (1000);
      lv_Html_Msg                  CLOB;
      lv_Html_Msg_Footer           VARCHAR2 (200);
      lv_Html_Msg_Header           VARCHAR2 (100);
      lv_Approval_Url              VARCHAR2 (50);

      lv_Title                     VARCHAR2 (5);
      lv_First_Name                VARCHAR2 (50);
      lv_Last_Name                 VARCHAR2 (50);
      lv_Company_Name              VARCHAR2 (50);
      lv_Customer_Info             CLOB;

      lv_Approved_Lines_Details    CLOB;
      lv_Rejected_Lines_Details    CLOB;
   BEGIN
      lv_Quote_Id := i_Quote_Id;
      lv_Quote_Status := i_Quote_Status;
      lv_Approval_Level := i_Approval_Level;

      -- Empty To list
      v_To_List := WCT_VARCHAR_LIST ();

      -- Empty Cc list
      v_Cc_List := WCT_VARCHAR_LIST ();

      -- Get various properties
      SELECT PROPERTY_VALUE
        INTO lv_Approval_Url
        FROM WCT_PROPERTIES
       WHERE PROPERTY_TYPE = 'APPROVAL_URL';

      SELECT PROPERTY_VALUE
        INTO lv_From
        FROM WCT_PROPERTIES
       WHERE PROPERTY_TYPE = 'APPROVAL_WORKFLOW_FROM_MAIL_ID';

      -- Get User, Customer Info
      SELECT QH.CREATED_BY,
             CST.POC_TITLE,
             CST.POC_FIRST_NAME,
             CST.POC_LAST_NAME,
             CMP.COMPANY_NAME
        INTO lv_Created_By,
             lv_Title,
             lv_First_Name,
             lv_Last_Name,
             lv_Company_Name
        FROM WCT_QUOTE_HEADER QH, WCT_CUSTOMER CST, WCT_COMPANY_MASTER CMP
       WHERE     QH.CUSTOMER_ID = CST.CUSTOMER_ID
             AND CST.COMPANY_ID = CMP.COMPANY_ID
             AND QUOTE_ID = lv_Quote_Id;

      -- Generate HTML Message Header Content
      lv_Html_Msg_Header :=
         '<span style="font-family: Arial; font-size: 14px;">';

      -- Generate HTML Message Footer Content
      lv_Html_Msg_Footer :=
            'please go to <a href="'
         || lv_Approval_Url
         || '">Excess Portal</a></span>';

      -- Generate Customer Info
      lv_Customer_Info :=
         '<table border=0 style="font-family: Arial; font-size: 14px;">';

      lv_Customer_Info :=
            lv_Customer_Info
         || '<tr><td><b>Customer Details:</b><br><br>'
         || lv_Title
         || ' '
         || lv_First_Name
         || ' '
         || lv_Last_Name
         || ', <i>'
         || lv_Company_Name
         || '</i></td></tr>';

      lv_Customer_Info := lv_Customer_Info || '</table>' || (CHR (10));

      IF (lv_Quote_Status = v_Status_Pending)
      THEN
         -- Send mail to the approvers
         SELECT USER_ID
           BULK COLLECT INTO v_To_List
           FROM WCT_USERS
          WHERE ROLE = 'USER' AND APPROVER_LEVEL = lv_Approval_Level;

         -- User to be notified only for the first time and
         -- not when quote moves from Level 1 to Level 2 for approval
         IF (lv_Approval_Level = 1)
         THEN
            v_Cc_List.EXTEND ();
            v_Cc_List (1) := lv_Created_By;
         END IF;

         lv_Subject :=
               'Excess Portal - Approval Required '
            || lv_Company_Name
            || ' #'
            || lv_Quote_Id;

         lv_Html_Msg :=
               lv_Html_Msg_Header
            || 'Please approve the quote '
            || lv_Quote_Id
            || '.<br><br>'
            || lv_Customer_Info
            || '<br><br>'
            || 'To approve the request, '
            || lv_Html_Msg_Footer;
      ELSE
         IF (   (lv_Quote_Status = v_Status_Partial)
             OR (lv_Quote_Status = v_Status_Rejected))
         THEN
            SELECT WCT_QUOTE_LINE_OBJECT (
                      LINE_ID,                                       --LINE_ID
                      NULL,                                         --QUOTE_ID
                      NULL,                                          --LINE_NO
                      REQUESTED_PART,
                      NVL (WHOLESALE_PART, v_Empty_String),
                      REQUESTED_QUANTITY,
                      AVAILABLE_QUANTITY,
                      NULL,                                     --BROKER_OFFER
                      GLP,
                      SUGGESTED_PRICE,
                      NULL,                                   --EXT_SELL_PRICE
                      NULL,                                        --LEAD_TIME
                      NULL,                                --ENCRYPTION_STATUS
                      NULL,                           --INVENTORY_DETAIL_NOTES
                      DISCOUNT,
                      COMMENTS_L1,
                      COMMENTS_L2,
                      NULL,                                         --EOS_DATE
                      NULL,                                   --APPROVAL_LEVEL
                      NULL,                               --APPROVAL_STATUS_L1
                      NULL,                               --APPROVAL_STATUS_L2
                      NULL,                                           --ROW_ID
                      NULL,                                         -- N_VALUE
                      NULL,                               -- RECENT_SALES_LIST
                      NULL,                                -- QUANTITY_ON_HAND
                      NULL,                             -- QUANTITY_IN_TRANSIT
                      NVL(PROMO_FLAG,'N') -- US151907
                      )
              BULK COLLECT INTO v_Rejected_Quote_Line_List
              FROM WCT_QUOTE_LINE
             WHERE     QUOTE_ID = lv_Quote_Id
                   AND (   APPROVAL_STATUS_L1 = v_Approval_Status_Rejected
                        OR APPROVAL_STATUS_L2 = v_Approval_Status_Rejected);

            IF (v_Rejected_Quote_Line_List.COUNT > 0)
            THEN
               lv_Rejected_Lines_Details :=
                     '<table border=1 cellpadding=5 style="font-family: Arial; font-size: 14px;">'
                  || (CHR (10));

               -- Print header
               lv_Rejected_Lines_Details :=
                     lv_Rejected_Lines_Details
                  || '<tr>'
                  || '<th align="center">Requested Part</th>'
                  || '<th align="center">WS Part Number</th>'
                  || '<th align="center">Quantity<br>Requested</th>'
                  || '<th align="center">Quantity<br>Available</th>'
                  || '<th align="center">Unit<br>Sale Price</th>'
                  || '<th align="center">Global<br>Price List</th>'
                  || '<th align="center">Discount<br>(%)</th>'
                  || '<th align="center" width="300">Comments</th>'
                  || '</tr>'
                  || (CHR (10));

               -- Print content
               FOR idx IN 1 .. v_Rejected_Quote_Line_List.COUNT ()
               LOOP
                  lv_Rejected_Lines_Details :=
                        lv_Rejected_Lines_Details
                     || TO_CHAR (
                              '<tr>'
                           || '<td align="center">'
                           || v_Rejected_Quote_Line_List (idx).REQUESTED_PART
                           || '</td>'
                           || '<td align="center">'
                           || v_Rejected_Quote_Line_List (idx).WHOLESALE_PART
                           || '</td>'
                           || '<td align="center">'
                           || v_Rejected_Quote_Line_List (idx).REQUESTED_QUANTITY
                           || '</td>'
                           || '<td align="center">'
                           || v_Rejected_Quote_Line_List (idx).AVAILABLE_QUANTITY
                           || '</td>'
                           || '<td align="center">'
                           || TRIM (
                                 TO_CHAR (
                                    v_Rejected_Quote_Line_List (idx).SUGGESTED_PRICE,
                                    '$9,999,999,999,999'))
                           || '</td>'
                           || '<td align="center">'
                           || TRIM (
                                 TO_CHAR (
                                    v_Rejected_Quote_Line_List (idx).GLP,
                                    '$9,999,999,999,999'))
                           || '</td>'
                           || '<td align="center">'
                           || TRIM (
                                 TO_CHAR (
                                    v_Rejected_Quote_Line_List (idx).DISCOUNT,
                                    '999.99'))
                           || '</td>'
                           || '<td align="left">'
                           || '<b>Level-1:</b>  '
                           || v_Rejected_Quote_Line_List (idx).COMMENTS_L1
                           || '<br><b>Level-2:</b>  '
                           || v_Rejected_Quote_Line_List (idx).COMMENTS_L2
                           || '</td>'
                           || '</tr>'
                           || (CHR (10)));
               END LOOP;

               lv_Rejected_Lines_Details :=
                  lv_Rejected_Lines_Details || '</table>' || (CHR (10));
            END IF;
         END IF;

         IF (   (lv_Quote_Status = v_Status_Partial)
             OR (lv_Quote_Status = v_Status_Approved)) -- changed to APPROVED from QUOTE - june 2014 release changes - ruchhabr
         THEN
            SELECT WCT_QUOTE_LINE_OBJECT (
                      LINE_ID,                                       --LINE_ID
                      NULL,                                         --QUOTE_ID
                      NULL,                                          --LINE_NO
                      REQUESTED_PART,
                      NVL (WHOLESALE_PART, v_Empty_String),
                      REQUESTED_QUANTITY,
                      AVAILABLE_QUANTITY,
                      NULL,                                     --BROKER_OFFER
                      GLP,
                      SUGGESTED_PRICE,
                      NULL,                                   --EXT_SELL_PRICE
                      NULL,                                        --LEAD_TIME
                      NULL,                                --ENCRYPTION_STATUS
                      NULL,                           --INVENTORY_DETAIL_NOTES
                      DISCOUNT,
                      COMMENTS_L1,
                      COMMENTS_L2,
                      NULL,                                         --EOS_DATE
                      NULL,                                   --APPROVAL_LEVEL
                      NULL,                               --APPROVAL_STATUS_L1
                      NULL,                               --APPROVAL_STATUS_L2
                      NULL,                                           --ROW_ID
                      NULL,                                         -- N_VALUE
                      NULL,                               -- RECENT_SALES_LIST
                      NULL,                                -- QUANTITY_ON_HAND
                      NULL,                             -- QUANTITY_IN_TRANSIT
                      NVL(PROMO_FLAG,'N') -- US151907
                      )
              BULK COLLECT INTO v_Approved_Quote_Line_List
              FROM WCT_QUOTE_LINE
             WHERE     QUOTE_ID = lv_Quote_Id
                   AND APPROVAL_STATUS_L1 = v_Approval_Status_Approved
                   AND APPROVAL_STATUS_L2 = v_Approval_Status_Approved;

            IF (v_Approved_Quote_Line_List.COUNT > 0)
            THEN
               lv_Approved_Lines_Details :=
                     '<table border=1 cellpadding=5 style="font-family: Arial; font-size: 14px;">'
                  || (CHR (10));

               -- Print header
               lv_Approved_Lines_Details :=
                     lv_Approved_Lines_Details
                  || '<tr>'
                  || '<th align="center">Requested Part</th>'
                  || '<th align="center">WS Part Number</th>'
                  || '<th align="center">Quantity<br>Requested</th>'
                  || '<th align="center">Quantity<br>Available</th>'
                  || '<th align="center">Unit<br>Sale Price</th>'
                  || '<th align="center">Global<br>Price List</th>'
                  || '<th align="center">Discount<br>(%)</th>'
                  || '<th align="center" width="300">Comments</th>'
                  || '</tr>'
                  || (CHR (10));

               -- Print content
               FOR idx IN 1 .. v_Approved_Quote_Line_List.COUNT ()
               LOOP
                  lv_Approved_Lines_Details :=
                        lv_Approved_Lines_Details
                     || TO_CHAR (
                              '<tr>'
                           || '<td align="center">'
                           || v_Approved_Quote_Line_List (idx).REQUESTED_PART
                           || '</td>'
                           || '<td align="center">'
                           || v_Approved_Quote_Line_List (idx).WHOLESALE_PART
                           || '</td>'
                           || '<td align="center">'
                           || v_Approved_Quote_Line_List (idx).REQUESTED_QUANTITY
                           || '</td>'
                           || '<td align="center">'
                           || v_Approved_Quote_Line_List (idx).AVAILABLE_QUANTITY
                           || '</td>'
                           || '<td align="center">'
                           || TRIM (
                                 TO_CHAR (
                                    v_Approved_Quote_Line_List (idx).SUGGESTED_PRICE,
                                    '$9,999,999,999,999'))
                           || '</td>'
                           || '<td align="center">'
                           || TRIM (
                                 TO_CHAR (
                                    v_Approved_Quote_Line_List (idx).GLP,
                                    '$9,999,999,999,999'))
                           || '</td>'
                           || '<td align="center">'
                           || TRIM (
                                 TO_CHAR (
                                    v_Approved_Quote_Line_List (idx).DISCOUNT,
                                    '999.99'))
                           || '</td>'
                           || '<td align="left">'
                           || '<b>Level-1:</b>  '
                           || v_Approved_Quote_Line_List (idx).COMMENTS_L1
                           || '<br><b>Level-2:</b>  '
                           || v_Approved_Quote_Line_List (idx).COMMENTS_L2
                           || '</td>'
                           || '</tr>'
                           || (CHR (10)));
               END LOOP;

               lv_Approved_Lines_Details :=
                  lv_Approved_Lines_Details || '</table>' || (CHR (10));
            END IF;
         END IF;

         -- send mail to quote creator.
         v_To_List := WCT_VARCHAR_LIST ();
         v_To_List.EXTEND ();
         v_To_List (1) := lv_Created_By;

         IF (lv_Quote_Status = v_Status_Approved) -- changed to APPROVED from QUOTE - june 2014 release changes - ruchhabr
         THEN
            lv_Subject :=
               'Excess Portal - Quote - ' || lv_Quote_Id || ' Approved';

            lv_Html_Msg :=
                  lv_Html_Msg_Header
               || 'Quote - '
               || lv_Quote_Id
               || ' has been approved.<br><br>'
               || lv_Customer_Info
               || '<br><br>'
               || 'Following are the details for approved lines:'
               || '<br><br>'
               || lv_Approved_Lines_Details
               || '<br><br>'
               || 'To download the quote, '
               || lv_Html_Msg_Footer;
         ELSIF (lv_Quote_Status = v_Status_Partial)
         THEN
            lv_Subject :=
                  'Excess Portal - Quote - '
               || lv_Quote_Id
               || ' Approved Partially';

            lv_Html_Msg :=
                  lv_Html_Msg_Header
               || 'Quote - '
               || lv_Quote_Id
               || ' has been approved, however few lines were rejected.'
               || '<br><br>'
               || lv_Customer_Info
               || '<br><br>'
               || 'Following are the details for the approved lines:'
               || '<br><br>'
               || lv_Approved_Lines_Details
               || '<br><br>'
               || 'Following are the details for the rejected lines:'
               || '<br><br>'
               || lv_Rejected_Lines_Details
               || '<br><br>'
               || 'To download the quote, '
               || lv_Html_Msg_Footer;
         ELSIF (lv_Quote_Status = v_Status_Rejected)
         THEN
            lv_Subject :=
               'Excess Portal - Quote - ' || lv_Quote_Id || ' Rejected';

            lv_Html_Msg :=
                  lv_Html_Msg_Header
               || 'Quote - '
               || lv_Quote_Id
               || ' has been rejected.'
               || '<br><br>'
               || lv_Customer_Info
               || '<br><br>'
               || 'Following are the details for the rejected lines:'
               || '<br><br>'
               || lv_Rejected_Lines_Details
               || '</span>';
         END IF;
      END IF;


      o_To_List := v_To_List;
      o_Cc_List := v_Cc_List;
      o_From := lv_From;
      o_Subject := lv_Subject;
      o_Html_Msg := lv_Html_Msg;
   END;

   /*PROCEDURE TO SEND MAILS*/

   PROCEDURE EMAIL_UTIL (i_To_List    IN WCT_VARCHAR_LIST,
                         i_Cc_List    IN WCT_VARCHAR_LIST,
                         i_From       IN VARCHAR2,
                         i_Subject    IN VARCHAR2,
                         i_Html_Msg   IN CLOB DEFAULT NULL)
   IS
      lv_Mail_Conn          UTL_SMTP.connection;
      lv_Boundary           VARCHAR2 (50) := '----=*#abc1234321cba#*=';
      lv_Smtlv_Port         NUMBER DEFAULT 25;
      lv_Database_Name      VARCHAR2 (50);
      lv_Smtlv_Host         VARCHAR2 (30) := 'outbound.cisco.com';
      lv_To_List            WCT_VARCHAR_LIST;
      lv_Cc_List            WCT_VARCHAR_LIST;
      lv_Subject            VARCHAR2 (500);
      lv_From               VARCHAR2 (1000);
      lv_Html_Msg           CLOB;
      lv_Clob_Chunk_Start   NUMBER := 1;
      lv_Clob_Chunk_Size    NUMBER := 3999;
   BEGIN
      SELECT ORA_DATABASE_NAME INTO lv_Database_Name FROM DUAL;

      IF (ora_database_name = 'FNTR2DEV.CISCO.COM')
      THEN
         lv_Subject := 'DEV : ' || i_Subject;
      ELSIF (ora_database_name = 'FNTR2STG.CISCO.COM')
      THEN
         lv_Subject := 'STAGE : ' || i_Subject;
      ELSE
         lv_Subject := i_Subject;
      END IF;

      lv_To_List := i_To_List;
      lv_Cc_List := i_Cc_List;
      lv_From := i_From;
      lv_Html_Msg := i_Html_Msg;

      lv_Mail_Conn := UTL_SMTP.open_connection (lv_Smtlv_Host, lv_Smtlv_Port);
      UTL_SMTP.helo (lv_Mail_Conn, lv_Smtlv_Host);
      UTL_SMTP.mail (lv_Mail_Conn, lv_From);

      -- Adding multiple To's
      FOR idx IN 1 .. lv_To_list.COUNT ()
      LOOP
         UTL_SMTP.rcpt (lv_Mail_Conn, lv_To_List (idx));
      END LOOP;

      -- Adding multiple Cc's
      FOR idx IN 1 .. lv_Cc_list.COUNT ()
      LOOP
         UTL_SMTP.rcpt (lv_Mail_Conn, lv_Cc_list (idx));
      END LOOP;

      UTL_SMTP.open_data (lv_Mail_Conn);

      UTL_SMTP.write_data (
         lv_Mail_Conn,
            'Date: '
         || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
         || UTL_TCP.crlf);

      -- Adding multiple To's
      FOR idx IN 1 .. lv_To_list.COUNT ()
      LOOP
         UTL_SMTP.write_data (lv_Mail_Conn,
                              'To: ' || lv_To_list (idx) || UTL_TCP.crlf);
      END LOOP;

      UTL_SMTP.write_data (lv_Mail_Conn, 'From: ' || lv_From || UTL_TCP.crlf);

      -- Adding multiple Cc's
      FOR idx IN 1 .. lv_Cc_list.COUNT ()
      LOOP
         UTL_SMTP.write_data (lv_Mail_Conn,
                              'Cc: ' || lv_Cc_list (idx) || UTL_TCP.crlf);
      END LOOP;

      UTL_SMTP.write_data (lv_Mail_Conn,
                           'Subject: ' || lv_Subject || UTL_TCP.crlf);
      UTL_SMTP.write_data (lv_Mail_Conn,
                           'Reply-To: ' || lv_From || UTL_TCP.crlf);
      UTL_SMTP.write_data (lv_Mail_Conn, 'MIME-Version: 1.0' || UTL_TCP.crlf);
      UTL_SMTP.write_data (
         lv_Mail_Conn,
            'Content-Type: multipart/alternative; boundary="'
         || lv_Boundary
         || '"'
         || UTL_TCP.crlf
         || UTL_TCP.crlf);

      IF lv_Html_Msg IS NOT NULL
      THEN
         UTL_SMTP.write_data (lv_Mail_Conn,
                              '--' || lv_Boundary || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            lv_Mail_Conn,
               'Content-Type: text/html; charset="iso-8859-1"'
            || UTL_TCP.crlf
            || UTL_TCP.crlf);

         --UTL_SMTP.write_data (lv_Mail_Conn, lv_Html_Msg);

         -- If HTML body content to be written is more than the chunk size
         -- write content in chunks
         IF (LENGTH (lv_Html_Msg) > lv_Clob_Chunk_Size)
         THEN
            -- Build message in segments
            LOOP
               IF lv_Clob_Chunk_Start + lv_Clob_Chunk_Size <=
                     LENGTH (lv_Html_Msg) + 1
               THEN
                  UTL_SMTP.write_data (
                     lv_Mail_Conn,
                     SUBSTR (lv_Html_Msg,
                             lv_Clob_Chunk_Start,
                             lv_Clob_Chunk_Size));
               END IF;

               lv_Clob_Chunk_Start := lv_Clob_Chunk_Start + lv_Clob_Chunk_Size;
               EXIT WHEN lv_Clob_Chunk_Start + lv_Clob_Chunk_Size >
                            LENGTH (lv_Html_Msg);
            END LOOP;

            UTL_SMTP.write_data (
               lv_Mail_Conn,
               SUBSTR (lv_Html_Msg,
                       lv_Clob_Chunk_Start,
                       LENGTH (lv_Html_Msg) - lv_Clob_Chunk_Start + 1));
         ELSE
            UTL_SMTP.write_data (lv_Mail_Conn, lv_Html_Msg);
         END IF;

         UTL_SMTP.write_data (lv_Mail_Conn, UTL_TCP.crlf || UTL_TCP.crlf);
      END IF;

      UTL_SMTP.write_data (lv_Mail_Conn,
                           '--' || lv_Boundary || '--' || UTL_TCP.crlf);
      UTL_SMTP.close_data (lv_Mail_Conn);

      UTL_SMTP.quit (lv_Mail_Conn);
   END;
--
--   /* PROCEDURE TO DOWNLOAD INVENTORY */
--   PROCEDURE INVENTORY_DOWNLOAD (
--      i_Customer_Region             IN     VARCHAR2,
--      i_Inventory_Region            IN     VARCHAR2,
--      i_Sub_Inventory_Location      IN     VARCHAR2,
--      i_Sub_Inv_Location            IN     VARCHAR2,
--      i_Display_Type                IN     VARCHAR2,
--      i_User_Id                     IN     VARCHAR2,
--      i_Client_Date_Time            IN     VARCHAR2,
--      i_Tier                        IN     NUMBER,    --added new IN parameter
--      i_Cap_Flag                    IN     CHAR,      --added new IN parameter
--      i_Cap_Value                   IN     NUMBER,    --added new IN parameter
--      i_FG_inventory                IN     VARCHAR2, --added new IN parameter for FG inclusion
--      i_POE_Intransit_Inv           IN     VARCHAR2,
--      o_Inventory_Download_Object      OUT WCT_INVENTORY_DOWNLOAD_OBJECT)
--   IS
--      TYPE T_RAW_INVENTORY_OBJECT IS RECORD
--      (
--         MFG_PRODUCT_ID        VARCHAR2 (50),
--         WS_PRODUCT_ID         VARCHAR2 (50),
--         PRODUCT_DESCRIPTION   VARCHAR2 (200),
--         QTY_NAM_POE_OH        NUMBER,
--         QTY_NAM_WS_OH         NUMBER,
--         QTY_NAM_POE_IT        NUMBER,
--         QTY_NAM_WS_IT         NUMBER,
--         QTY_EMEA_POE_OH       NUMBER,
--         QTY_EMEA_WS_OH        NUMBER,
--         QTY_EMEA_POE_IT       NUMBER,
--         QTY_EMEA_WS_IT        NUMBER,
--         WS_BACKLOG            NUMBER,
--         RF_BACKLOG            NUMBER
--      );
--
--      TYPE T_EXCEPTION_PART_OBJECT IS RECORD
--      (
--         PART_NUMBER             VARCHAR2 (50),
--         PRODUCT_NAME_STRIPPED   VARCHAR2 (50)
--      );
--
--      TYPE T_RAW_INVENTORY_LIST IS TABLE OF T_RAW_INVENTORY_OBJECT;
--
--      TYPE T_EXCEPTION_PART_LIST IS TABLE OF T_EXCEPTION_PART_OBJECT;
--
--      v_Raw_Inventory_List          T_RAW_INVENTORY_LIST;
--      v_Exception_Part_List         T_EXCEPTION_PART_LIST;    --added new list
--
--      v_Inventory_Download_List     WCT_INV_DNLD_LIST;
--      v_Inventory_Download_List_F   WCT_INV_DNLD_LIST;
--
--
--      lv_Customer_region            VARCHAR2 (100);
--      lv_Inventory_region           VARCHAR2 (100);
--      lv_Sub_Inventory_Location     VARCHAR2 (100);
--      lv_Sub_Inv_Location           VARCHAR2 (1000);
--      lv_User_Id                    VARCHAR2 (12);
--      lv_Display_Type               VARCHAR2 (50);
--      lv_RF_Reservations            NUMBER := 0;
--      lv_WS_Reservations            NUMBER := 0;
--      lv_POE_Reservations_FOR_RF    NUMBER := 0;
--      lv_POE_Reservations_FOR_WS    NUMBER := 0;
--      lv_Quantity_Available_RF      NUMBER := 0;
--      lv_Quantity_1                 NUMBER := 0;
--      lv_Quantity_2                 NUMBER := 0;
--      lv_Quantity_1_WS              NUMBER := 0;
--      lv_Quantity_2_WS              NUMBER := 0;
--      lv_Quantity_1_POE             NUMBER := 0;
--      lv_Quantity_2_POE             NUMBER := 0;
--      lv_Inv_Dnld_List_Count        NUMBER := 1;
--      lv_Date_Time_String           VARCHAR2 (100) := v_Empty_String;
--      lv_Include_Row                BOOLEAN;
--      lv_Ws_Product_Id              VARCHAR2 (50);
--      lv_Discmailer                 VARCHAR2 (2000) := v_Empty_String;
--      lv_Encryption_Status          VARCHAR2 (80);
--      lv_Restricted_Flag            CHAR;
--      lv_Tier                       NUMBER (1);          --Added two varibles.
--      lv_Product_Name_Stripped      VARCHAR2 (50);
--      lv_FG_inventory               VARCHAR2 (50);    --Added for FG inclusion
--      lv_Cap_Flag                   CHAR; --added new variable for cap availability
--      lv_Cap_Value                  NUMBER := 0; --added new variable for cap availability
--      lv_FG_NAM                     VARCHAR2 (10);
--      lv_FG_EMEA                    VARCHAR2 (10);
--      lv_POE_Intransit_flag         VARCHAR2 (10);
--   BEGIN
--      lv_User_Id := i_User_Id;
--      lv_Customer_Region := i_Customer_region;
--      lv_Inventory_region := i_Inventory_Region;
--      lv_Display_Type := i_Display_Type;
--      lv_Sub_Inventory_Location := i_Sub_Inventory_Location;
--      lv_Sub_Inv_Location := i_Sub_Inv_Location;
--      lv_Tier := i_Tier;                                               --added
--      lv_Cap_Flag := i_Cap_Flag;                                       --added
--      lv_Cap_Value := i_Cap_Value;                                     --added
--      lv_FG_inventory := i_FG_inventory;                               --added
--      lv_FG_NAM := 'NO';
--      lv_FG_EMEA := 'NO';
--      lv_POE_Intransit_flag := i_POE_Intransit_Inv;
--
--      v_Inventory_Download_List := WCT_INV_DNLD_LIST ();
--      v_Inventory_Download_List_F := WCT_INV_DNLD_LIST ();
--
--      GET_DATA_REFRESH_TIME (i_Client_Date_Time, lv_Date_Time_String);
--
--      IF (lv_Tier = 1) --changes for exclusion of PID for seleted Tier user August 2014 by karusing
--      THEN
--         SELECT PRODUCT_ID, PRODUCT_NAME_STRIPPED
--           BULK COLLECT INTO v_Exception_Part_List
--           FROM vavni_cisco_rscm_admin.WCT_EXCLUDE_PID
--          WHERE STATUS = 'ACTIVE' AND EXCLUDE_TIER1 = 'Y';
--      ELSIF (lv_Tier = 2)
--      THEN
--         SELECT PRODUCT_ID, PRODUCT_NAME_STRIPPED
--           BULK COLLECT INTO v_Exception_Part_List
--           FROM vavni_cisco_rscm_admin.WCT_EXCLUDE_PID
--          WHERE STATUS = 'ACTIVE' AND EXCLUDE_TIER2 = 'Y';
--      END IF;
--
--      CASE
--         WHEN (UPPER (lv_FG_inventory) = '')
--         THEN
--            lv_FG_NAM := 'NO';
--            lv_FG_EMEA := 'NO';
--         WHEN (UPPER (lv_FG_inventory) = 'ALL')
--         THEN
--            lv_FG_NAM := 'YES';
--            lv_FG_EMEA := 'YES';
--         WHEN (UPPER (lv_FG_inventory) = 'FG_NAM')
--         THEN
--            lv_FG_NAM := 'YES';
--            lv_FG_EMEA := 'NO';
--         WHEN (UPPER (lv_FG_inventory) = 'FG_EMEA')
--         THEN
--            lv_FG_NAM := 'NO';
--            lv_FG_EMEA := 'YES';
--         ELSE
--            lv_FG_NAM := 'NO';
--            lv_FG_EMEA := 'NO';
--      END CASE;
--
--
--
--      BEGIN
--           SELECT MFG_PRODUCT_ID,
--                  --WS_PRODUCT_ID,
--                  GET_WS_PART_NUMBER (MFG_PRODUCT_ID) WS_PRODUCT_ID,
--                  GET_PART_DESCRIPTION (MFG_PRODUCT_ID) DESCRIPTION,
--                  NVL (SUM (QTY_NAM_POE_OH), 0),
--                  NVL (SUM (QTY_NAM_WS_OH), 0),
--                  NVL (SUM (QTY_NAM_POE_IT), 0),
--                  NVL (SUM (QTY_NAM_WS_IT), 0),
--                  NVL (SUM (QTY_EMEA_POE_OH), 0),
--                  NVL (SUM (QTY_EMEA_WS_OH), 0),
--                  NVL (SUM (QTY_EMEA_POE_IT), 0),
--                  NVL (SUM (QTY_EMEA_WS_IT), 0),
--                  GET_BACKLOG (VV_RSCM_UTIL.GET_STRIPPED_NAME (MFG_PRODUCT_ID),
--                               'WS')
--                     WS_BACKLOG,
--                  GET_BACKLOG (VV_RSCM_UTIL.GET_STRIPPED_NAME (MFG_PRODUCT_ID),
--                               'RF')
--                     RF_BACKLOG
--             BULK COLLECT INTO v_Raw_Inventory_List
--             FROM (  SELECT MFG_PRODUCT_ID,
--                            --WS_PRODUCT_ID,
--                            --DESCRIPTION,
--                            NVL (SUM (COL1), 0) QTY_NAM_POE_OH,
--                            NVL (SUM (COL2), 0) QTY_NAM_WS_OH,
--                            NVL (SUM (COL3), 0) QTY_NAM_POE_IT,
--                            NVL (SUM (COL4), 0) QTY_NAM_WS_IT,
--                            NVL (SUM (COL5), 0) QTY_EMEA_POE_OH,
--                            NVL (SUM (COL6), 0) QTY_EMEA_WS_OH,
--                            NVL (SUM (COL7), 0) QTY_EMEA_POE_IT,
--                            NVL (SUM (COL8), 0) QTY_EMEA_WS_IT /*,
--                             GET_BACKLOG (PRODUCT_NAME_STRIPPED, 'WS') WS_BACKLOG,
--                             GET_BACKLOG (PRODUCT_NAME_STRIPPED, 'RF') RF_BACKLOG*/
--                       FROM (  SELECT MFG_PRODUCT_ID,
--                                      --WS_PRODUCT_ID,
--                                      --DESCRIPTION,
--                                      PRODUCT_NAME_STRIPPED,
--                                      REGION,
--                                      LOC,
--                                      CASE
--                                         WHEN REGION = 'NAM' AND LOC = 'POE'
--                                         THEN
--                                            SUM (QTY_ON_HAND)
--                                      END
--                                         AS COL1,
--                                      CASE
--                                         WHEN REGION = 'NAM' AND LOC = 'WS'
--                                         THEN
--                                            SUM (QTY_ON_HAND)
--                                      END
--                                         AS COL2,
--                                      CASE
--                                         WHEN     REGION = 'NAM'
--                                              AND LOC = 'POE'
--                                              AND lv_POE_Intransit_flag = 'Y'
--                                         THEN
--                                            SUM (QTY_IN_TRANSIT)
--                                      END
--                                         AS COL3,
--                                      CASE
--                                         WHEN REGION = 'NAM' AND LOC = 'WS'
--                                         THEN
--                                            SUM (QTY_IN_TRANSIT)
--                                      END
--                                         AS COL4,
--                                      CASE
--                                         WHEN REGION = 'EMEA' AND LOC = 'POE'
--                                         THEN
--                                            SUM (QTY_ON_HAND)
--                                      END
--                                         AS COL5,
--                                      CASE
--                                         WHEN REGION = 'EMEA' AND LOC = 'WS'
--                                         THEN
--                                            SUM (QTY_ON_HAND)
--                                      END
--                                         AS COL6,
--                                      CASE
--                                         WHEN     REGION = 'EMEA'
--                                              AND LOC = 'POE'
--                                              AND lv_POE_Intransit_flag = 'Y'
--                                         THEN
--                                            SUM (QTY_IN_TRANSIT)
--                                      END
--                                         AS COL7,
--                                      CASE
--                                         WHEN REGION = 'EMEA' AND LOC = 'WS'
--                                         THEN
--                                            SUM (QTY_IN_TRANSIT)
--                                      END
--                                         AS COL8
--                                 FROM (SELECT DISTINCT
--                                              CASE
--                                                 WHEN SUBSTR (
--                                                         PM_PROD.PRODUCT_COMMON_NAME,
--                                                         LENGTH (
--                                                            PM_PROD.PRODUCT_COMMON_NAME),
--                                                         1) = '='
--                                                 THEN
--                                                    SUBSTR (
--                                                       PM_PROD.PRODUCT_COMMON_NAME,
--                                                       0,
--                                                         LENGTH (
--                                                            PM_PROD.PRODUCT_COMMON_NAME)
--                                                       - 1)
--                                                 ELSE
--                                                    PM_PROD.PRODUCT_COMMON_NAME
--                                              END
--                                                 AS MFG_PRODUCT_ID,
--                                              --       PM_PROD.PRODUCT_NAME WS_PRODUCT_ID,
--                                              --      PM_PROD.DESCRIPTION DESCRIPTION,
--                                              MV.PRODUCT_NAME_STRIPPED,
--                                              MV.REGION,
--                                              SUBSTR (MV.SITE, 1, 3) ZLOC,
--                                              MV.LOCATION,
--                                              SUBSTR (MV.LOCATION,
--                                                      1,
--                                                      INSTR (MV.LOCATION, '-') - 1)
--                                                 AS LOC,
--                                              CASE
--                                                 WHEN lv_Sub_Inventory_Location LIKE
--                                                         '%' || ZLOC.ZLOC || '%'
--                                                 THEN
--                                                    CASE
--                                                       WHEN SCM.YIELD_WS = 'YES'
--                                                       THEN
--                                                          ROUND (
--                                                               (  MV.QTY_ON_HAND
--                                                                * CASE
--                                                                     WHEN    RM_YIELD
--                                                                                IS NULL
--                                                                          OR RM_YIELD =
--                                                                                0
--                                                                     THEN
--                                                                        80
--                                                                     ELSE
--                                                                        RM_YIELD
--                                                                  END)
--                                                             / 100)
--                                                       ELSE
--                                                          MV.QTY_ON_HAND
--                                                    END
--                                                 ELSE
--                                                    0
--                                              END
--                                                 AS QTY_ON_HAND,
--                                              CASE
--                                                 WHEN lv_Sub_Inventory_Location LIKE
--                                                         '%' || ZLOC.ZLOC || '%'
--                                                 THEN
--                                                    CASE
--                                                       WHEN SCM.YIELD_WS = 'YES'
--                                                       THEN
--                                                          ROUND (
--                                                               (  MV.QTY_IN_TRANSIT
--                                                                * CASE
--                                                                     WHEN    RM_YIELD
--                                                                                IS NULL
--                                                                          OR RM_YIELD =
--                                                                                0
--                                                                     THEN
--                                                                        80
--                                                                     ELSE
--                                                                        RM_YIELD
--                                                                  END)
--                                                             / 100)
--                                                       ELSE
--                                                          MV.QTY_IN_TRANSIT
--                                                    END
--                                                 ELSE
--                                                    0
--                                              END
--                                                 AS QTY_IN_TRANSIT,
--                                              CASE
--                                                 WHEN    RM_YIELD IS NULL
--                                                      OR RM_YIELD = 0
--                                                 THEN
--                                                    80
--                                                 ELSE
--                                                    RM_YIELD
--                                              END
--                                                 AS RM_YIELD,
--                                              SCM.YIELD_WS,
--                                              PRODUCT_FAMILY
--                                         FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV MV
--                                              LEFT OUTER JOIN
--                                              VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
--                                                 ON     (PM_PROD.PRODUCT_NAME_STRIPPED =
--                                                            MV.PRODUCT_NAME_STRIPPED)
--                                                    AND MV.REGION =
--                                                           PM_PROD.REGION_NAME
--                                              INNER JOIN
--                                              VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP LOC
--                                                 ON LOC.DESTINATION_SUBINVENTORY =
--                                                       MV.LOCATION
--                                              INNER JOIN
--                                              VAVNI_CISCO_RSCM_ADMIN.VV_ADM_ZLOCATION_TABLE ZLOC
--                                                 ON ZLOC.ZLOC =
--                                                       SUBSTR (MV.SITE, 1, 3)
--                                              LEFT OUTER JOIN
--                                              VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP SCM
--                                                 ON     MV.LOCATION =
--                                                           SCM.DESTINATION_SUBINVENTORY
--                                                    AND SCM.YIELD_WS = 'YES'
--                                        WHERE     NVL (
--                                                     PM_PROD.PRODUCT_BU_STATUS_ID,
--                                                     0) <> 6
--                                              AND LOC.DESTINATION_SUBINVENTORY IN (    SELECT DISTINCT
--                                                                                              REGEXP_SUBSTR (
--                                                                                                 lv_Sub_Inv_Location,
--                                                                                                 '[^,]+',
--                                                                                                 1,
--                                                                                                 LEVEL)
--                                                                                         FROM DUAL
--                                                                                   CONNECT BY REGEXP_SUBSTR (
--                                                                                                 lv_Sub_Inv_Location,
--                                                                                                 '[^,]+',
--                                                                                                 1,
--                                                                                                 LEVEL)
--                                                                                                 IS NOT NULL)
--                                              AND (   LOC.PROGRAM_TYPE = 1
--                                                   OR LOC.PROGRAM_TYPE = 2) -- FOR 1= WHOLESALE, 2= DGI LOCATIONS
--                                              AND LOC.IS_NETTABLE = 1
--                                              AND LOC.IS_ENABLE = 1
--                                              AND MV.LOCATION NOT IN ('FG',
--                                                                      'WS-FGSLD',
--                                                                      'RF-W-RHS',
--                                                                      'RF-W-OEM',
--                                                                      'RF-WIP',
--                                                                      'WS-WIP'))
--                             GROUP BY MFG_PRODUCT_ID,
--                                      REGION,
--                                      LOC,
--                                      PRODUCT_NAME_STRIPPED
--                             UNION
--                               SELECT MFG_PRODUCT_ID,
--                                      PRODUCT_NAME_STRIPPED,
--                                      REGION,
--                                      LOC,
--                                      0 AS COL1,
--                                      CASE
--                                         WHEN     REGION = 'NAM'
--                                              AND LOC = 'FG'
--                                              AND lv_FG_NAM = 'YES'
--                                         THEN
--                                            SUM (QTY_ON_HAND)
--                                         ELSE
--                                            0
--                                      END
--                                         AS COL2,
--                                      0 AS COL3,
--                                      CASE
--                                         WHEN     REGION = 'NAM'
--                                              AND LOC = 'FG'
--                                              AND lv_FG_NAM = 'YES'
--                                         THEN
--                                            SUM (QTY_IN_TRANSIT)
--                                         ELSE
--                                            0
--                                      END
--                                         AS COL4,
--                                      0 AS COL5,
--                                      CASE
--                                         WHEN     REGION = 'EMEA'
--                                              AND LOC = 'FG'
--                                              AND lv_FG_EMEA = 'YES'
--                                         THEN
--                                            SUM (QTY_ON_HAND)
--                                         ELSE
--                                            0
--                                      END
--                                         AS COL6,
--                                      0 AS COL7,
--                                      CASE
--                                         WHEN     REGION = 'EMEA'
--                                              AND LOC = 'FG'
--                                              AND lv_FG_EMEA = 'YES'
--                                         THEN
--                                            SUM (QTY_IN_TRANSIT)
--                                         ELSE
--                                            0
--                                      END
--                                         AS COL8
--                                 FROM (SELECT DISTINCT
--                                              CASE
--                                                 WHEN SUBSTR (
--                                                         PM_PROD.PRODUCT_COMMON_NAME,
--                                                         LENGTH (
--                                                            PM_PROD.PRODUCT_COMMON_NAME),
--                                                         1) = '='
--                                                 THEN
--                                                    SUBSTR (
--                                                       PM_PROD.PRODUCT_COMMON_NAME,
--                                                       0,
--                                                         LENGTH (
--                                                            PM_PROD.PRODUCT_COMMON_NAME)
--                                                       - 1)
--                                                 ELSE
--                                                    PM_PROD.PRODUCT_COMMON_NAME
--                                              END
--                                                 AS MFG_PRODUCT_ID,
--                                              --       PM_PROD.PRODUCT_NAME WS_PRODUCT_ID,
--                                              --      PM_PROD.DESCRIPTION DESCRIPTION,
--                                              MV.PRODUCT_NAME_STRIPPED,
--                                              MV.REGION,
--                                              MV.SITE AS ZLOC,
--                                              MV.LOCATION,
--                                              MV.LOCATION AS LOC,
--                                              MV.QTY_ON_HAND AS QTY_ON_HAND,
--                                              MV.QTY_IN_TRANSIT AS QTY_IN_TRANSIT,
--                                              '100' AS RM_YIELD,
--                                              NULL,
--                                              PRODUCT_FAMILY
--                                         FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV MV
--                                              LEFT OUTER JOIN
--                                              VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
--                                                 ON     (PM_PROD.PRODUCT_NAME_STRIPPED =
--                                                            MV.PRODUCT_NAME_STRIPPED)
--                                                    AND MV.REGION =
--                                                           PM_PROD.REGION_NAME
--                                        WHERE     PM_PROD.PRODUCT_BU_STATUS_ID <> 6
--                                              AND MV.LOCATION IN ('FG')
--                                              AND MV.PRODUCT_FAMILY LIKE
--                                                     '%WHLSALE%')
--                             GROUP BY MFG_PRODUCT_ID,
--                                      REGION,
--                                      LOC,
--                                      PRODUCT_NAME_STRIPPED
--                             ORDER BY 1,
--                                      2,
--                                      3,
--                                      4)
--                   GROUP BY MFG_PRODUCT_ID,                   --WS_PRODUCT_ID,
--                                            --DESCRIPTION,
--                                            PRODUCT_NAME_STRIPPED)
--         GROUP BY MFG_PRODUCT_ID                --, WS_PRODUCT_ID, DESCRIPTION
--         ORDER BY MFG_PRODUCT_ID;                           --, WS_PRODUCT_ID;
--
--
--         FOR idx IN 1 .. v_Raw_Inventory_List.COUNT ()
--         LOOP
--            lv_Restricted_Flag := 'N';
--
--            -- set include row to true
--            lv_Include_Row := TRUE;
--
--            -- IF (lv_Tier = 2)
--            --THEN
--            lv_Product_Name_Stripped :=
--               VV_RSCM_UTIL.GET_STRIPPED_NAME (
--                  v_Raw_Inventory_List (idx).MFG_PRODUCT_ID);
--
--            FOR innerIdx IN 1 .. v_Exception_Part_List.COUNT ()
--            LOOP
--               IF UPPER (lv_Product_Name_Stripped) =
--                     UPPER (
--                        v_Exception_Part_List (innerIdx).PRODUCT_NAME_STRIPPED)
--               THEN
--                  lv_Include_Row := FALSE;
--                  EXIT;
--               END IF;
--            END LOOP;
--
--
--            IF (lv_Include_Row)
--            THEN
--               BEGIN
--                  SELECT NVL (ENCRYPTION_STATUS, v_Empty_String)
--                    INTO lv_Encryption_Status
--                    FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
--                   WHERE PRODUCT_ID =
--                            v_Raw_Inventory_List (idx).MFG_PRODUCT_ID;
--
--                  IF (lv_Customer_Region = 'NAM')
--                  THEN
--                     IF (lv_Encryption_Status = 'Restricted')
--                     THEN
--                        lv_Restricted_Flag := v_Flag_Yes;
--                     END IF;
--                  ELSIF (lv_Customer_Region = 'EMEA')
--                  THEN
--                     IF (   lv_Encryption_Status = 'Restricted'
--                         OR lv_Encryption_Status = 'Unrestricted')
--                     THEN
--                        lv_Restricted_Flag := v_Flag_Yes;
--                     END IF;
--                  END IF;
--               EXCEPTION
--                  WHEN NO_DATA_FOUND
--                  THEN
--                     lv_Encryption_Status := v_Empty_String;
--                  WHEN OTHERS
--                  THEN
--                     lv_Encryption_Status := v_Empty_String;
--               END;
--
--               IF (lv_Inventory_region = 'ALL')
--               THEN
--                  IF (lv_Customer_Region = 'NAM')
--                  THEN
--                     lv_Quantity_1_WS :=
--                        v_Raw_Inventory_List (idx).QTY_NAM_WS_OH;
--                     lv_Quantity_2_WS :=
--                          v_Raw_Inventory_List (idx).QTY_NAM_WS_IT
--                        + v_Raw_Inventory_List (idx).QTY_EMEA_WS_OH
--                        + v_Raw_Inventory_List (idx).QTY_EMEA_WS_IT;
--
--                     lv_Quantity_1_POE :=
--                        v_Raw_Inventory_List (idx).QTY_NAM_POE_OH;
--                     lv_Quantity_2_POE :=
--                          v_Raw_Inventory_List (idx).QTY_NAM_POE_IT
--                        + v_Raw_Inventory_List (idx).QTY_EMEA_POE_OH
--                        + v_Raw_Inventory_List (idx).QTY_EMEA_POE_IT;
--                  ELSIF (lv_Customer_Region = 'EMEA')
--                  THEN
--                     lv_Quantity_1_WS :=
--                        v_Raw_Inventory_List (idx).QTY_EMEA_WS_OH;
--                     lv_Quantity_2_WS :=
--                          v_Raw_Inventory_List (idx).QTY_EMEA_WS_IT
--                        + v_Raw_Inventory_List (idx).QTY_NAM_WS_OH
--                        + v_Raw_Inventory_List (idx).QTY_NAM_WS_IT;
--
--                     lv_Quantity_1_POE :=
--                        v_Raw_Inventory_List (idx).QTY_EMEA_POE_OH;
--                     lv_Quantity_2_POE :=
--                          v_Raw_Inventory_List (idx).QTY_EMEA_POE_IT
--                        + v_Raw_Inventory_List (idx).QTY_NAM_POE_OH
--                        + v_Raw_Inventory_List (idx).QTY_NAM_POE_IT;
--                  END IF;
--               ELSIF (lv_Inventory_region = 'NAM')
--               THEN
--                  IF (lv_Customer_Region = 'NAM')
--                  THEN
--                     lv_Quantity_1_WS :=
--                        v_Raw_Inventory_List (idx).QTY_NAM_WS_OH;
--                     lv_Quantity_2_WS :=
--                        v_Raw_Inventory_List (idx).QTY_NAM_WS_IT;
--
--                     lv_Quantity_1_POE :=
--                        v_Raw_Inventory_List (idx).QTY_NAM_POE_OH;
--                     lv_Quantity_2_POE :=
--                        v_Raw_Inventory_List (idx).QTY_NAM_POE_IT;
--                  ELSIF (lv_Customer_Region = 'EMEA')
--                  THEN
--                     lv_Quantity_1_WS := 0;
--                     lv_Quantity_2_WS :=
--                          v_Raw_Inventory_List (idx).QTY_NAM_WS_OH
--                        + v_Raw_Inventory_List (idx).QTY_NAM_WS_IT;
--
--                     lv_Quantity_1_POE := 0;
--                     lv_Quantity_2_POE :=
--                          v_Raw_Inventory_List (idx).QTY_NAM_POE_OH
--                        + v_Raw_Inventory_List (idx).QTY_NAM_POE_IT;
--                  END IF;
--               ELSIF (lv_Inventory_region = 'EMEA')
--               THEN
--                  IF (lv_Customer_Region = 'NAM')
--                  THEN
--                     lv_Quantity_1_WS := 0;
--                     lv_Quantity_2_WS :=
--                          v_Raw_Inventory_List (idx).QTY_EMEA_WS_OH
--                        + v_Raw_Inventory_List (idx).QTY_EMEA_WS_IT;
--
--                     lv_Quantity_1_POE := 0;
--                     lv_Quantity_2_POE :=
--                          v_Raw_Inventory_List (idx).QTY_EMEA_POE_OH
--                        + v_Raw_Inventory_List (idx).QTY_EMEA_POE_IT;
--                  ELSIF (lv_Customer_Region = 'EMEA')
--                  THEN
--                     lv_Quantity_1_WS :=
--                        v_Raw_Inventory_List (idx).QTY_EMEA_WS_OH;
--                     lv_Quantity_2_WS :=
--                        v_Raw_Inventory_List (idx).QTY_EMEA_WS_IT;
--
--                     lv_Quantity_1_POE :=
--                        v_Raw_Inventory_List (idx).QTY_EMEA_POE_OH;
--                     lv_Quantity_2_POE :=
--                        v_Raw_Inventory_List (idx).QTY_EMEA_POE_IT;
--                  END IF;
--               END IF;
--
--               -- Handle reservations
--               lv_RF_Reservations := 0;
--               lv_WS_Reservations := 0;
--               lv_POE_Reservations_FOR_RF := 0;
--               lv_POE_Reservations_FOR_WS := 0;
--               lv_Quantity_Available_RF := 0;
--
--               lv_POE_Reservations_FOR_RF :=
--                  v_Raw_Inventory_List (idx).RF_BACKLOG;
--               lv_WS_Reservations := v_Raw_Inventory_List (idx).WS_BACKLOG;
--
--               -- Compute WS net available
--               IF (lv_WS_Reservations > (lv_Quantity_1_WS + lv_Quantity_2_WS))
--               THEN
--                  lv_POE_Reservations_FOR_WS :=
--                       lv_WS_Reservations
--                     - (lv_Quantity_1_WS + lv_Quantity_2_WS);
--                  lv_Quantity_1_WS := 0;
--                  lv_Quantity_2_WS := 0;
--               ELSE
--                  lv_Quantity_1_WS := lv_Quantity_1_WS - lv_WS_Reservations;
--
--                  IF (lv_Quantity_1_WS < 0)
--                  THEN
--                     lv_Quantity_2_WS :=
--                          lv_Quantity_2_WS
--                        + (lv_Quantity_1_WS - lv_WS_Reservations);
--                     lv_Quantity_1_WS := 0;
--                  END IF;
--
--                  IF (lv_Quantity_2_WS < 0)
--                  THEN
--                     lv_Quantity_2_WS := 0;
--                  END IF;
--               END IF;
--
--               -- Compute POE net available
--               -- fulfill RF reservations from POE, if any
--               IF (lv_POE_Reservations_FOR_RF > 0)
--               THEN
--                  lv_Quantity_1_POE :=
--                     lv_Quantity_1_POE - lv_POE_Reservations_FOR_RF;
--
--                  IF (lv_Quantity_1_POE < 0)
--                  THEN
--                     lv_Quantity_2_POE :=
--                        lv_Quantity_2_POE + lv_Quantity_1_POE;
--                     lv_Quantity_1_POE := 0;
--                  END IF;
--
--                  IF (lv_Quantity_2_POE < 0)
--                  THEN
--                     lv_Quantity_2_POE := 0;
--                  END IF;
--               END IF;
--
--               -- fulfill WS reservations from POE, if any
--               IF (    (lv_POE_Reservations_FOR_WS > 0)
--                   AND ( (lv_Quantity_1_POE + lv_Quantity_2_POE) > 0))
--               THEN
--                  lv_Quantity_1_POE :=
--                     lv_Quantity_1_POE - lv_POE_Reservations_FOR_WS;
--
--                  IF (lv_Quantity_1_POE < 0)
--                  THEN
--                     lv_Quantity_2_POE :=
--                        lv_Quantity_2_POE + lv_Quantity_1_POE;
--                     lv_Quantity_1_POE := 0;
--                  END IF;
--
--                  IF (lv_Quantity_2_POE < 0)
--                  THEN
--                     lv_Quantity_2_POE := 0;
--                  END IF;
--               END IF;
--
--               -- set include row to true
--               lv_Include_Row := TRUE;
--
--               -- compute net quantity 1 and quantity 2
--               lv_Quantity_1 := lv_Quantity_1_WS + lv_Quantity_1_POE;
--               lv_Quantity_2 := lv_Quantity_2_WS + lv_Quantity_2_POE;
--
--               IF (lv_Display_Type = 'ALL')
--               THEN
--                  IF (v_Raw_Inventory_List (idx).WS_PRODUCT_ID LIKE '%WS')
--                  THEN
--                     lv_Ws_Product_Id :=
--                        v_Raw_Inventory_List (idx).WS_PRODUCT_ID;
--                  ELSE
--                     lv_Ws_Product_Id := v_Empty_String;
--                  END IF;
--               ELSIF (lv_Display_Type = 'WS')
--               THEN
--                  IF (v_Raw_Inventory_List (idx).WS_PRODUCT_ID LIKE '%WS')
--                  THEN
--                     lv_Ws_Product_Id :=
--                        v_Raw_Inventory_List (idx).WS_PRODUCT_ID;
--                  ELSE
--                     lv_Include_Row := FALSE;
--                  END IF;
--               ELSIF (lv_Display_Type = 'NWS')
--               THEN
--                  IF (v_Raw_Inventory_List (idx).WS_PRODUCT_ID LIKE '%WS')
--                  THEN
--                     lv_Include_Row := FALSE;
--                  ELSE
--                     lv_Ws_Product_Id :=
--                        v_Raw_Inventory_List (idx).WS_PRODUCT_ID;
--                  END IF;
--               END IF;
--
--               IF (lv_Include_Row)
--               THEN
--                  IF (lv_Cap_Flag = v_Flag_Yes)
--                  THEN
--                     IF (lv_Quantity_1 >= lv_Cap_Value)
--                     THEN
--                        lv_Quantity_1 := lv_Cap_Value;
--                        lv_Quantity_2 := 0;
--                     ELSE
--                        lv_Quantity_2 :=
--                           LEAST ( (lv_Cap_Value - lv_Quantity_1),
--                                  lv_Quantity_2);
--                     END IF;
--                  END IF;
--
--                  -- create and store inventory download object in the list
--                  v_Inventory_Download_List.EXTEND ();
--
--                  v_Inventory_Download_List (lv_Inv_Dnld_List_Count) :=
--                     WCT_INV_DNLD_OBJECT (
--                        v_Raw_Inventory_List (idx).MFG_PRODUCT_ID,
--                        lv_Ws_Product_Id,
--                        v_Raw_Inventory_List (idx).PRODUCT_DESCRIPTION,
--                        lv_Quantity_1,
--                        lv_Quantity_2,
--                        0,
--                        lv_Restricted_Flag);         --Change No of Parameters
--                  lv_Inv_Dnld_List_Count := lv_Inv_Dnld_List_Count + 1;
--               END IF;
--            END IF;
--         END LOOP;
--      EXCEPTION
--         WHEN OTHERS
--         THEN
--            --LOG EXCEPTION
--            v_Error_Message := NULL;
--            v_Error_Message := SUBSTR (SQLERRM, 1, 200);
--
--            INSERT INTO WCT_ERROR_LOG
--                 VALUES ('INVENTORY_DOWNLOAD',
--                         lv_User_Id,
--                         v_Error_Message,
--                         SYSDATE);
--      END;
--
--      BEGIN
--         SELECT PROPERTY_VALUE
--           INTO lv_Discmailer
--           FROM WCT_PROPERTIES
--          WHERE PROPERTY_TYPE = 'INVENTORY_DOWNLOAD_DISCLAIMER';
--      EXCEPTION
--         WHEN OTHERS
--         THEN
--            lv_Discmailer := v_Empty_String;
--      END;
--
--      -- assign final inventory download list to the OUT parameter
--      o_Inventory_Download_Object :=
--         WCT_INVENTORY_DOWNLOAD_OBJECT (v_Inventory_Download_List,
--                                        lv_Date_Time_String,
--                                        lv_Discmailer);
--   END;

   /* PROCEDURE TO GET PARTS FOR AUTO SUGGEST */
   PROCEDURE GET_ALL_PARTS_AUTO_SUGGEST (
      i_Initial           IN     VARCHAR2,
      i_User_Id           IN     VARCHAR2,
      o_All_Parts_Found      OUT WCT_VARCHAR_LIST)
   IS
      lv_Initial           VARCHAR2 (100);
      lv_User_Id           VARCHAR2 (12);
      lv_All_Parts_Found   WCT_VARCHAR_LIST;
   BEGIN
      BEGIN
         --implementation in progress
         lv_All_Parts_Found := WCT_VARCHAR_LIST ();
         lv_Initial := UPPER (i_Initial);
         lv_User_Id := i_User_Id;

--(start) Commented by hkarka for removing references to stripped and RSCM on 08-MAR-2017
/*
           SELECT DISTINCT PRODUCT_NAME
             BULK COLLECT INTO lv_All_Parts_Found
             FROM (SELECT DISTINCT PRODUCT_NAME
                     FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW
                    WHERE     PRODUCT_NAME LIKE lv_Initial || '%'
                          AND PRODUCT_NAME NOT LIKE '% %'
                          AND PRODUCT_BU_STATUS_ID <> 6
                   UNION
                   SELECT DISTINCT PRODUCT_ID
                     FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                    WHERE     PRODUCT_ID LIKE lv_Initial || '%'
                          AND PRODUCT_ID NOT LIKE '% %')
         ORDER BY PRODUCT_NAME;
*/
--(end) Commented by hkarka for removing references to stripped and RSCM on 08-MAR-2017

         -- (start) added for stripped name logic by HKARKAAPRRELEASE
           SELECT DISTINCT product_id
             BULK COLLECT INTO lv_All_Parts_Found
             FROM (SELECT refresh_part_number product_id
                     FROM crpadm.rc_product_master
                    WHERE     refresh_part_number LIKE lv_Initial || '%'
                          AND refresh_part_number NOT LIKE '% %'
                          AND refresh_life_cycle_id <> 6
                   UNION
                   SELECT common_part_number product_id
                     FROM crpadm.rc_product_master
                    WHERE     common_part_number LIKE lv_Initial || '%'
                          AND refresh_life_cycle_id <> 6
                          AND common_part_number NOT LIKE '% %'
                   UNION
                   SELECT xref_part_number product_id
                     FROM crpadm.rc_product_master
                    WHERE     xref_part_number LIKE lv_Initial || '%'
                          AND refresh_life_cycle_id <> 6
                          AND xref_part_number NOT LIKE '% %'
                   UNION
                   SELECT DISTINCT PRODUCT_ID
                     FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                    WHERE     PRODUCT_ID LIKE lv_Initial || '%'
                          AND PRODUCT_ID NOT LIKE '% %')
         ORDER BY PRODUCT_ID;
         -- (end) added for stripped name logic by HKARKAAPRRELEASE

      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT DISTINCT PRODUCT_ID
                 BULK COLLECT INTO lv_All_Parts_Found
                 FROM (  SELECT DISTINCT
                                PRODUCT_ID,
                                ROW_NUMBER () OVER (ORDER BY PRODUCT_ID)
                                   AS ROW_NUM
                           FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                          WHERE     PRODUCT_ID LIKE lv_Initial || '%'
                                AND PRODUCT_ID NOT LIKE '% %'
                       ORDER BY PRODUCT_ID);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  INSERT INTO WCT_ERROR_LOG
                       VALUES (lv_Initial,
                               lv_User_Id,
                               'no matching parts found',
                               SYSDATE);
            END;
      END;

      o_all_parts_found := lv_All_Parts_Found;
   END;

   /*FUNCTION TO GENERATE UNIQUE QUOTE_ID*/

   FUNCTION GENERATE_QUOTE_ID (i_Quote_Id_Type IN VARCHAR2)
      RETURN VARCHAR2
   IS
      lv_Quote_Id        VARCHAR2 (10);
      lv_Length          NUMBER;
      lv_Upper_Limit     NUMBER;
      lv_Quote_Id_Type   VARCHAR2 (1);
   BEGIN
      lv_Quote_Id_Type := i_Quote_Id_Type;

      IF (lv_Quote_Id_Type = v_Quote_Id_Type_Quote)
      THEN
         lv_Quote_Id := '' || WCT_QUOTE_HEADER_ID.NEXTVAL;
      ELSIF (lv_Quote_Id_Type = v_Quote_Id_Type_Dummy)
      THEN
         lv_Quote_Id := '' || WCT_QUOTE_HEADER_ID_DUMMY.NEXTVAL;
      END IF;

      SELECT PROPERTY_VALUE
        INTO lv_Upper_Limit
        FROM WCT_PROPERTIES
       WHERE PROPERTY_TYPE = 'QUOTE_ID_UPPER_LIMIT';

      lv_Length := LENGTH (lv_Quote_Id);

      FOR i IN 1 .. (lv_Upper_Limit - lv_Length)
      LOOP
         lv_Quote_Id := '0' || lv_Quote_Id;
      END LOOP;

      lv_Quote_Id := lv_Quote_Id_Type || '' || lv_Quote_Id;

      RETURN lv_Quote_Id;
   END;

   /* FUNCTION to get backlog for inventory download */
--   FUNCTION GET_BACKLOG (i_Product_Name_Stripped    VARCHAR2,
--                         i_Product_Type             VARCHAR2)
--      RETURN NUMBER
--   IS
--      lv_Total_Reservations      NUMBER (10);
--      lv_Product_Name_Stripped   VARCHAR (50);
--      lv_Quantity_Available_RF   NUMBER (10);
--      lv_Product_Type            VARCHAR2 (5);
--      lv_Gdgi_Reservation        NUMBER; -- added for June 2014 release - ruchhabr
--   BEGIN
--      lv_Total_Reservations := 0;
--      lv_Product_Name_Stripped := i_Product_Name_Stripped;
--      lv_Product_Type := i_Product_Type;
--
--      IF (lv_Product_Type = 'RF')
--      THEN
--         SELECT ABS (NVL (SUM (TOTAL_RESERVATIONS), 0))
--           INTO lv_Total_Reservations
--           FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--          WHERE     PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped
--                AND PRODUCT_FAMILY NOT LIKE '%WHLSALE%'
--                AND LOCATION NOT IN (SELECT DESTINATION_SUBINVENTORY
--                                       FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                                      WHERE INVENTORY_TYPE = 2);
--
--         SELECT NVL (SUM (QTY_ON_HAND + QTY_IN_TRANSIT), 0)
--           INTO lv_Quantity_Available_RF
--           FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--          WHERE     PRODUCT_NAME_STRIPPED LIKE lv_Product_Name_Stripped
--                AND (    LOCATION IN (SELECT DESTINATION_SUBINVENTORY
--                                        FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
--                                       WHERE     1 = 1
--                                             AND (PROGRAM_TYPE = 0) -- FOR 0= Retail
--                                             AND IS_NETTABLE = 1
--                                             AND IS_ENABLE = 1
--                                             AND INVENTORY_TYPE <> 2) -- changes by karusing to exclude WIP location
--                     AND product_family <> 'WHLSALE');
--
--         -- added for June 2014 release - ruchhabr
--         lv_Gdgi_Reservation :=
--            GET_GDGI_RESERVATION (lv_Product_Name_Stripped);
--
--         IF (lv_Quantity_Available_RF > lv_Total_Reservations)
--         THEN
--            lv_Total_Reservations := 0;
--         ELSE
--            lv_Total_Reservations :=
--               lv_Total_Reservations - lv_Quantity_Available_RF;
--         END IF;
--      ELSIF (lv_Product_Type = 'WS')
--      THEN
--         SELECT ABS (NVL (SUM (QTY_RESERVED), 0))
--           INTO lv_Total_Reservations
--           FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--          WHERE     (   PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped
--                     OR PRODUCT_NAME_STRIPPED =
--                           lv_Product_Name_Stripped || 'WS')
--                AND PRODUCT_FAMILY LIKE '%WHLSALE%';
--      END IF;
--
--      RETURN lv_Total_Reservations;
--   EXCEPTION
--      WHEN NO_DATA_FOUND
--      THEN
--         RETURN (lv_Total_Reservations);
--      WHEN OTHERS
--      THEN
--         RETURN (lv_Total_Reservations);
--   END;


   /* FUNCTION to get recent quote details */
   FUNCTION GET_RECENT_QUOTE_DETAILS (i_Requested_Part   IN VARCHAR2,
                                      i_User_Id          IN VARCHAR2)
      RETURN WCT_RECENT_QUOTES_LIST
   IS
      --Declare the type
      v_Recent_Quotes_List   WCT_RECENT_QUOTES_LIST;

      --   Declare local variable
      lv_User_Id             VARCHAR2 (12);
      lv_Requested_Part      VARCHAR2 (50);
   BEGIN
      v_Recent_Quotes_List := WCT_RECENT_QUOTES_LIST ();
      lv_Requested_Part := i_Requested_Part;
      lv_User_Id := i_User_Id;

      BEGIN
         SELECT WCT_RECENT_QUOTES_OBJECT (CREATED_BY,
                                          REQUESTED_QUANTITY,
                                          LAST_UPDATED_DATE,
                                          SUGGESTED_PRICE,
                                          COMPANY_NAME)
           BULK COLLECT INTO v_Recent_Quotes_List
           FROM (SELECT headerTBL.CREATED_BY,
                        lineTBL.REQUESTED_QUANTITY,
                        headerTBL.LAST_UPDATED_DATE,
                        lineTBL.SUGGESTED_PRICE,
                        companyTBL.COMPANY_NAME,
                        ROW_NUMBER ()
                           OVER (ORDER BY headerTBL.LAST_UPDATED_DATE DESC)
                           RNO
                   FROM WCT_QUOTE_LINE lineTBL,
                        WCT_QUOTE_HEADER headerTBL,
                        WCT_CUSTOMER customerTBL,
                        WCT_COMPANY_MASTER companyTBL
                  WHERE (    headerTBL.QUOTE_ID = lineTBL.QUOTE_ID
                         AND (   headerTBL.STATUS IN (v_Status_Approved,
                                                      v_Status_Partial)
                              OR headerTBL.STATUS = v_Status_Quote)
                         -- OR headerTBL.STATUS = v_Status_Partial
                         -- OR headerTBL.STATUS = v_Status_Quote)
                         AND lineTBL.AVAILABLE_QUANTITY > 0
                         AND lineTBL.REQUESTED_PART = lv_Requested_Part
                         AND headerTBL.CUSTOMER_ID = customerTBL.CUSTOMER_ID
                         AND customerTBL.COMPANY_ID = companyTBL.COMPANY_ID
                         AND lineTBL.APPROVAL_STATUS_l1 =
                                v_Approval_Status_Approved
                         AND NVL(lineTBL.promo_flag,'N') = 'N' --US151907
                         AND lineTBL.APPROVAL_STATUS_l2 =
                                v_Approval_Status_Approved))
          WHERE RNO <= 5;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            --LOG EXCEPTION
            INSERT INTO WCT_ERROR_LOG
                 VALUES (UPPER (lv_Requested_Part),
                         lv_User_Id,
                         'GET_RECENT_QUOTE_DETAILS - No data found',
                         SYSDATE);
         WHEN OTHERS
         THEN
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message := SUBSTR (SQLERRM, 1, 200);

            INSERT INTO WCT_ERROR_LOG
                 VALUES (UPPER (lv_Requested_Part),
                         lv_User_Id,
                         'GET_RECENT_QUOTE_DETAILS - ' || v_Error_Message,
                         SYSDATE);
      END;

      RETURN v_Recent_Quotes_List;
   END;

   /* FUNCTION to get WS part number for a part */
   FUNCTION GET_PART_DESCRIPTION (i_Part_Number VARCHAR2)
      RETURN VARCHAR2
   IS
      lv_Part_Number   VARCHAR2 (60);
      lv_Output        VARCHAR (255) := ' ';
   BEGIN
      lv_Part_Number := i_Part_Number;
      
      --Modified by satbanda on 23rd Jan,2018 for replacing VAVNI RSCM objects <start> 

--      SELECT DISTINCT NVL (DESCRIPTION, v_Empty_String)
--        INTO lv_Output
--        FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW
--       WHERE     (   PRODUCT_COMMON_NAME = lv_Part_Number
--                  OR PRODUCT_COMMON_NAME = lv_Part_Number || '=')
--             AND PRODUCT_FAMILY_NAME = 'WHLSALE'
--             AND ROWNUM <= 1;
      SELECT DISTINCT NVL (DESCRIPTION, v_Empty_String)
        INTO lv_Output
        FROM CRPADM.RC_PRODUCT_MASTER RPM
       WHERE   (  lv_Part_Number = RPM.REFRESH_PART_NUMBER
               OR lv_Part_Number = RPM.COMMON_PART_NUMBER
               OR lv_Part_Number = RPM.XREF_PART_NUMBER)
             AND ROWNUM <= 1;
        --Modified by satbanda on 23rd Jan,2018 for replacing VAVNI RSCM objects <End>     

      RETURN lv_Output;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         BEGIN
            SELECT DISTINCT NVL (DESCRIPTION, v_Empty_String)
              INTO lv_Output
              FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW
             WHERE     (   PRODUCT_COMMON_NAME = lv_Part_Number
                        OR PRODUCT_COMMON_NAME = lv_Part_Number || '=')
                   AND ROWNUM <= 1;

            RETURN lv_Output;
         EXCEPTION
            WHEN OTHERS
            THEN
               --DBMS_OUTPUT.put_line ('Others ' || SUBSTR (SQLERRM, 1, 200));
               --lv_Output := v_Empty_String;
               RETURN lv_Output;
         END;
      WHEN OTHERS
      THEN
         --DBMS_OUTPUT.put_line ('Others ' || SUBSTR (SQLERRM, 1, 200));
         --lv_Output := v_Empty_String;
         RETURN lv_Output;
   END;

   /* FUNCTION to get WS part number for a part */
   FUNCTION GET_WS_PART_NUMBER (i_Part_Number VARCHAR2)
      RETURN VARCHAR2
   IS
      lv_Part_Number                VARCHAR2 (50);
     -- lv_Product_Name_Stripped_WS   VARCHAR2 (50); -- added -- changes made by "ruchhabr" - August 2014 release

   --   TYPE T_PART_WS_PID IS RECORD (product_name VARCHAR2 (50) -- product_common_name   VARCHAR2 (50)
                                                             -- );

     -- TYPE T_PART_WS_LIST IS TABLE OF T_PART_WS_PID;

      --pid_list                      T_PART_WS_LIST;
   BEGIN
      lv_Part_Number := i_Part_Number;


      -- START: added -- changes made by "ruchhabr" - August 2014 release
      /*SELECT DISTINCT NVL (PRODUCT_NAME, v_Empty_String)
        INTO lv_Part_Number
        FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW
       WHERE     PRODUCT_COMMON_NAME = lv_Part_Number
             AND PRODUCT_FAMILY_NAME = 'WHLSALE'; */

--      lv_Product_Name_Stripped_WS :=
--         VV_RSCM_UTIL.GET_STRIPPED_NAME (lv_Part_Number) || 'WS';
         
         BEGIN
        /*--(Start) Commented by csirigir as on 26-OCT-2018 as part of Selling FGI change    
			SELECT refresh_part_number
               INTO lv_Part_Number
               FROM CRPADM.RC_PRODUCT_MASTER
              WHERE (   UPPER(refresh_part_number) = lv_Part_Number
                     OR UPPER(common_part_number) = lv_Part_Number
                     OR UPPER(xref_part_number) = lv_Part_Number) --requested part may be a wholesale part, manufacturing part or xref part(spare)
                    AND NVL (deactivation_date, SYSDATE) >= SYSDATE --should not be deactivated
                    AND program_type = 1                          --wholesale part
                    AND inventory_item_status_code = 'ENABLE-MAJ'
                    AND refresh_life_cycle_name IN ('CUR', 'EOL', 'EOS');
					
		 */ --(End) Commented by csirigir as on 26-OCT-2018 as part of Selling FGI change		
         
        --(Start) Added by csirigir as on 26-OCT-2018 as part of Selling FGI change		 
		      
			 SELECT refresh_part_number
			   INTO lv_Part_Number
			   FROM CRPADM.RC_PRODUCT_MASTER
			  WHERE ( UPPER(refresh_part_number) = lv_Part_Number
			         OR UPPER(common_part_number) in (lv_Part_Number,lv_Part_Number||'=')
			         OR UPPER(xref_part_number) = lv_Part_Number) --requested part may be a wholesale part, manufacturing part or xref part(spare)
			    AND NVL (deactivation_date, SYSDATE) >= SYSDATE --should not be deactivated
			    AND program_type = 1 --wholesale part
			  --AND inventory_item_status_code = 'ENABLE-MAJ'
			    AND refresh_life_cycle_id <> 6;
			  --AND refresh_life_cycle_name IN ('CUR', 'EOL', 'EOS')
			  
		 --(End) Added by csirigir as on 26-OCT-2018 as part of Selling FGI change
		 
        EXCEPTION
         WHEN OTHERS THEN
            lv_Part_Number := null;
        END;


--      SELECT DISTINCT NVL (PRODUCT_NAME, v_Empty_String)
--        INTO lv_Part_Number
--        FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW
--       WHERE     PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped_WS
--             AND PRODUCT_FAMILY_NAME = 'WHLSALE';

      -- END: changes made by "ruchhabr" - August 2014 release

      RETURN lv_Part_Number;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         lv_Part_Number := v_Empty_String;
         RETURN lv_Part_Number;
      WHEN OTHERS
      THEN
         lv_Part_Number := v_Empty_String;
         RETURN lv_Part_Number;
   END;

--   /* FUNCTION to get GDGI reservation for a part */
--   FUNCTION GET_GDGI_RESERVATION (i_Product_Name_Stripped IN VARCHAR2)
--      RETURN NUMBER
--   IS
--      lv_Product_Name_Stripped   VARCHAR2 (50);
--      lv_Gdgi_Reservation        NUMBER := 0;
--   BEGIN
--      lv_Product_Name_Stripped := i_Product_Name_Stripped;
--
--      BEGIN
--         SELECT ABS (NVL (SUM (total_reservations), 0))
--           INTO lv_Gdgi_Reservation
--           FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--          WHERE     PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped
--                AND PRODUCT_FAMILY NOT LIKE '%WHLSALE%'
--                AND SITE IN ('GDGI', 'Global DGI');
--      EXCEPTION
--         WHEN NO_DATA_FOUND
--         THEN
--            lv_Gdgi_Reservation := 0;
--         WHEN OTHERS
--         THEN
--            lv_Gdgi_Reservation := 0;
--      END;
--
--      RETURN lv_Gdgi_Reservation;
--   END;
--
--   FUNCTION GET_GDGI_RESERVATION_WS (i_Product_Name_Stripped IN VARCHAR2)
--      RETURN NUMBER
--   IS
--      lv_Product_Name_Stripped   VARCHAR2 (50);
--      lv_Gdgi_Reservation        NUMBER := 0;
--   BEGIN
--      lv_Product_Name_Stripped := i_Product_Name_Stripped;
--
--      BEGIN
--         SELECT ABS (NVL (SUM (total_reservations), 0))
--           INTO lv_Gdgi_Reservation
--           FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV
--          WHERE     PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped
--                AND PRODUCT_FAMILY LIKE '%WHLSALE%'
--                AND SITE IN ('GDGI', 'Global DGI');
--      EXCEPTION
--         WHEN NO_DATA_FOUND
--         THEN
--            lv_Gdgi_Reservation := 0;
--         WHEN OTHERS
--         THEN
--            lv_Gdgi_Reservation := 0;
--      END;
--
--      RETURN lv_Gdgi_Reservation;
--   END;



   /* FUNCTION TO SORT QUOTE LINE LIST */
   FUNCTION SORT_QUOTE_LINE_LIST (i_Quote_Line_List IN WCT_QUOTE_LINE_LIST)
      RETURN WCT_QUOTE_LINE_LIST
   IS
      lv_Quote_Line_List          WCT_QUOTE_LINE_LIST;
      lv_Quote_Line_List_Sorted   WCT_QUOTE_LINE_LIST;
      lv_Sortable_Table           WCT_SORTABLE_TABLE;

      lv_Line_No_Numeric          NUMBER;
      lv_Line_No_Delimiter_Pos    NUMBER;
   BEGIN
      lv_Quote_Line_List := i_Quote_Line_List;
      lv_Quote_Line_List_Sorted := WCT_QUOTE_LINE_LIST ();
      lv_Sortable_Table := WCT_SORTABLE_TABLE ();

      FOR idx IN 1 .. lv_Quote_Line_List.COUNT ()
      LOOP
         lv_Line_No_Delimiter_Pos :=
            INSTR (lv_Quote_Line_List (idx).LINE_NO,
                   ',',
                   1,
                   1);

         IF (lv_Line_No_Delimiter_Pos > 0)
         THEN
            lv_Line_No_Numeric :=
               TO_NUMBER (
                  SUBSTR (lv_Quote_Line_List (idx).LINE_NO,
                          1,
                          lv_Line_No_Delimiter_Pos - 1));
         ELSE
            lv_Line_No_Numeric := TO_NUMBER (lv_Quote_Line_List (idx).LINE_NO);
         END IF;

         lv_Sortable_Table.EXTEND ();
         lv_Sortable_Table (idx) :=
            WCT_SORTABLE_OBJECT (lv_Line_No_Numeric,
                                 TO_CHAR (lv_Quote_Line_List (idx).ROW_ID),
                                 idx);
      END LOOP;


      SELECT CAST (MULTISET (  SELECT *
                                 FROM TABLE (lv_Sortable_Table)
                             ORDER BY 1, 2) AS WCT_SORTABLE_TABLE)
        INTO lv_Sortable_Table
        FROM DUAL;

      FOR idx IN 1 .. lv_Sortable_Table.COUNT ()
      LOOP
         lv_Quote_Line_List_Sorted.EXTEND ();
         lv_Quote_Line_List_Sorted (idx) :=
            lv_Quote_Line_List (lv_Sortable_Table (idx).POINTER);
      END LOOP;

      RETURN lv_Quote_Line_List_Sorted;
   END;

   /* PROCEDURE TO ALL QUOTE LIST */

   PROCEDURE LOAD_ALL_QUOTE_LIST (
      i_User_Id                IN     VARCHAR2,
      i_Load_Type              IN     VARCHAR2,
      o_Approval_Quotes_List      OUT WCT_RETRIEVE_QUOTES_LIST)
   IS
      v_Approval_Quotes_List   WCT_RETRIEVE_QUOTES_LIST;
      lv_User_Id               VARCHAR2 (12);
      lv_Approver_Level        NUMBER;
      lv_Load_Type             VARCHAR2 (8);
      LV_FISCAL_STRT_DATE      VARCHAR2 (20); -- to capture last fiscal year start date
   BEGIN
      lv_User_Id := i_User_Id;
      lv_Load_Type := i_Load_Type;

      BEGIN
         --         SELECT APPROVER_LEVEL
         --           INTO lv_Approver_Level
         --           FROM WCT_USERS
         --          WHERE USER_ID = lv_User_Id;

         --         IF (lv_Load_Type = v_Load_Type_Action)
         --         THEN
         --            IF (lv_Approver_Level = 2)
         --            THEN
         --                 SELECT WCT_RETRIEVE_QUOTES_OBJECT (QH.QUOTE_ID,
         --                                                    COM.COMPANY_NAME,
         --                                                    QH.CREATED_DATE,
         --                                                    QH.CREATED_BY,
         --                                                    QH.DEAL_VALUE,
         --                                                    QH.STATUS,
         --                                                    CUST.CUSTOMER_ID,
         --                                                    SD.STATUS_DESCRIPTION,
         --                                                    QH.APPROVER_LEVEL_1,
         --                                                    QH.APPROVER_LEVEL_2) --added karusing to retrieve approver id
         --                   BULK COLLECT INTO v_Approval_Quotes_List
         --                   FROM WCT_QUOTE_HEADER QH,
         --                        WCT_CUSTOMER CUST,
         --                        WCT_COMPANY_MASTER COM,
         --                        WCT_STATUS_DETAIL SD
         --                  WHERE     1 = 1
         --                        AND QH.CUSTOMER_ID = CUST.CUSTOMER_ID
         --                        /*AND (   QH.STATUS = v_Status_Pending
         --                             OR QH.STATUS = v_Status_Partial)*/
         --                        AND QH.STATUS = v_Status_Pending
         --                        AND COM.COMPANY_ID = CUST.COMPANY_ID
         --                        AND QH.STATUS = SD.STATUS
         --                        AND APPROVAL_LEVEL = lv_Approver_Level
         --                        AND QH.QUOTE_ID IN
         --                               (SELECT DISTINCT QL.QUOTE_ID
         --                                  FROM WCT_QUOTE_LINE QL
         --                                 WHERE QL.APPROVAL_STATUS_L1 =
         --                                          v_Approval_Status_Approved
         --                                       AND QL.APPROVAL_STATUS_L2 =
         --                                              v_Approval_Status_Pending)
         --                        AND QH.Quote_id NOT IN
         --                               (SELECT DISTINCT quote_id
         --                                  FROM wct_quote_line
         --                                 WHERE approval_status_l1 =
         --                                          v_Approval_Status_Pending)
         --               ORDER BY QH.CREATED_DATE DESC;
         --            ELSIF (lv_Approver_Level = 1)
         --            THEN
         --                 SELECT WCT_RETRIEVE_QUOTES_OBJECT (QH.QUOTE_ID,
         --                                                    COM.COMPANY_NAME,
         --                                                    QH.CREATED_DATE,
         --                                                    QH.CREATED_BY,
         --                                                    QH.DEAL_VALUE,
         --                                                    QH.STATUS,
         --                                                    CUST.CUSTOMER_ID,
         --                                                    SD.STATUS_DESCRIPTION,
         --                                                    QH.APPROVER_LEVEL_1,
         --                                                    QH.APPROVER_LEVEL_2) --added karusing to retrieve approver id
         --                   BULK COLLECT INTO v_Approval_Quotes_List
         --                   FROM WCT_QUOTE_HEADER QH,
         --                        WCT_CUSTOMER CUST,
         --                        WCT_COMPANY_MASTER COM,
         --                        WCT_STATUS_DETAIL SD
         --                  WHERE     1 = 1
         --                        AND QH.CUSTOMER_ID = CUST.CUSTOMER_ID
         --                        /*AND (   QH.STATUS = v_Status_Pending
         --                             OR QH.STATUS = v_Status_Partial)*/
         --                        AND QH.STATUS = v_Status_Pending
         --                        AND COM.COMPANY_ID = CUST.COMPANY_ID
         --                        AND QH.STATUS = SD.STATUS
         --                        AND APPROVAL_LEVEL >= lv_Approver_Level
         --                        AND QH.QUOTE_ID IN
         --                               (SELECT DISTINCT QL.QUOTE_ID
         --                                  FROM WCT_QUOTE_LINE QL
         --                                 WHERE QL.APPROVAL_STATUS_L1 =
         --                                          v_Approval_Status_Pending)
         --               ORDER BY QH.CREATED_DATE DESC;
         --            ELSE
         --               v_Approval_Quotes_List := NULL;
         --            END IF;
         --         ELSIF (lv_Load_Type = v_Load_Type_Preview)
         --         THEN
         --            IF (lv_Approver_Level = 2)
         --            THEN

         SELECT DISTINCT TRUNC (FISCAL_QTR_START_DATE)
           INTO LV_FISCAL_STRT_DATE
           FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
          WHERE     FISCAL_YEAR_NUMBER =
                       (  (SELECT FISCAL_YEAR_NUMBER
                             FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                            WHERE TRUNC (CALENDAR_DATE) = TRUNC (SYSDATE))
                        - 1)
                AND FISCAL_QUARTER_NUMBER = 1; --last fiscal year's start date

           SELECT WCT_RETRIEVE_QUOTES_OBJECT (QH.QUOTE_ID,
                                              COM.COMPANY_NAME,
                                              QH.LAST_UPDATED_DATE,
                                              QH.CREATED_BY,
                                              QH.DEAL_VALUE,
                                              QH.STATUS,
                                              CUST.CUSTOMER_ID,
                                              SD.STATUS_DESCRIPTION,
                                              QH.APPROVER_LEVEL_1,
                                              QH.APPROVER_LEVEL_2) --added karusing to retrieve approver id
             BULK COLLECT INTO o_Approval_Quotes_List
             FROM WCT_QUOTE_HEADER QH,
                  WCT_CUSTOMER CUST,
                  WCT_COMPANY_MASTER COM,
                  WCT_STATUS_DETAIL SD
            WHERE     1 = 1
                  AND QH.CREATED_DATE >= LV_FISCAL_STRT_DATE -- added for restricting data to last fiscal year
                  AND QH.CUSTOMER_ID = CUST.CUSTOMER_ID
                  AND (   QH.STATUS = 'APPROVED'
                       OR QH.STATUS = 'PARTIAL'
                       OR QH.STATUS = 'QUOTE'
                       OR QH.STATUS = 'REJECTED'
                       OR QH.STATUS = 'PENDING')
                  AND COM.COMPANY_ID = CUST.COMPANY_ID
                  AND QH.STATUS = SD.STATUS
         --                        AND QH.QUOTE_ID IN
         --                               (  SELECT DISTINCT QL.QUOTE_ID
         --                                    FROM WCT_QUOTE_LINE QL
         --                                   WHERE QL.QUOTE_ID = QH.QUOTE_ID
         --                                         AND ( (QL.APPROVAL_STATUS_L1 =
         --                                                   v_Approval_Status_Approved
         --                                                AND QL.APPROVAL_STATUS_L2 =
         --                                                       v_Approval_Status_Approved)
         --                                              OR (QL.APPROVAL_STATUS_L1 =
         --                                                     v_Approval_Status_Approved
         --                                                  AND QL.APPROVAL_STATUS_L2 =
         --                                                         v_Approval_Status_Rejected)
         --                                              OR (QL.APPROVAL_STATUS_L1 =
         --                                                     v_Approval_Status_Rejected
         --                                                  AND QL.APPROVAL_STATUS_L2 =
         --                                                         v_Approval_Status_Rejected))
         --                                GROUP BY QL.QUOTE_ID
         --                                  HAVING COUNT (QL.LINE_ID) =
         --                                            (SELECT COUNT (*)
         --                                               FROM WCT_QUOTE_LINE QLI
         --                                              WHERE QLI.
         --                                                     QUOTE_ID = QL.QUOTE_ID))
         /*AND QH.Quote_id NOT IN
                (SELECT DISTINCT quote_id
                   FROM wct_quote_line
                  WHERE approval_status_l1 =
                           v_Approval_Status_Pending)*/
         ORDER BY QH.LAST_UPDATED_DATE DESC;
      --            ELSIF (lv_Approver_Level = 1)
      --            THEN
      --                 SELECT WCT_RETRIEVE_QUOTES_OBJECT (QH.QUOTE_ID,
      --                                                    COM.COMPANY_NAME,
      --                                                    QH.LAST_UPDATED_DATE,
      --                                                    QH.CREATED_BY,
      --                                                    QH.DEAL_VALUE,
      --                                                    QH.STATUS,
      --                                                    CUST.CUSTOMER_ID,
      --                                                    SD.STATUS_DESCRIPTION,
      --                                                    QH.APPROVER_LEVEL_1,
      --                                                    QH.APPROVER_LEVEL_2)  --added karusing to retrieve approver id
      --                   BULK COLLECT INTO v_Approval_Quotes_List
      --                   FROM WCT_QUOTE_HEADER QH,
      --                        WCT_CUSTOMER CUST,
      --                        WCT_COMPANY_MASTER COM,
      --                        WCT_STATUS_DETAIL SD
      --                  WHERE 1 = 1 AND QH.CUSTOMER_ID = CUST.CUSTOMER_ID
      --                        AND (   QH.STATUS = v_Status_Approved
      --                             OR QH.STATUS = v_Status_Partial
      --                             OR QH.STATUS = v_Status_Quote
      --                             OR QH.STATUS = v_Status_Rejected
      --                             OR QH.STATUS = v_Status_Pending)
      --                        AND COM.COMPANY_ID = CUST.COMPANY_ID
      --                        AND QH.STATUS = SD.STATUS
      --                        AND QH.QUOTE_ID IN
      --                               (  SELECT DISTINCT QL.QUOTE_ID
      --                                    FROM WCT_QUOTE_LINE QL
      --                                   WHERE QL.QUOTE_ID = QH.QUOTE_ID
      --                                         AND ( (QL.APPROVAL_STATUS_L1 =
      --                                                   v_Approval_Status_Approved
      --                                                AND QL.APPROVAL_STATUS_L2 =
      --                                                       v_Approval_Status_Approved)
      --                                              OR (QL.APPROVAL_STATUS_L1 =
      --                                                     v_Approval_Status_Rejected
      --                                                  AND QL.APPROVAL_STATUS_L2 =
      --                                                         v_Approval_Status_Rejected))
      --                                GROUP BY QL.QUOTE_ID
      --                                  HAVING COUNT (QL.LINE_ID) =
      --                                            (SELECT COUNT (*)
      --                                               FROM WCT_QUOTE_LINE QLI
      --                                              WHERE QLI.
      --                                                     QUOTE_ID = QL.QUOTE_ID))
      --               ORDER BY QH.LAST_UPDATED_DATE DESC;
      --            ELSE
      --               v_Approval_Quotes_List := NULL;
      --            --END IF;
      --         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            --LOG EXCEPTION
            INSERT INTO WCT_ERROR_LOG
                 VALUES ('GENERATE QUOTE LIST',
                         lv_User_Id,
                         'LOAD_APPROVAL_QUOTE_LIST - No data found',
                         SYSDATE);
         WHEN OTHERS
         THEN
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message := SUBSTR (SQLERRM, 1, 200);

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('GENERATE QUOTE LIST',
                         lv_User_Id,
                         'LOAD_APPROVAL_QUOTE_LIST - ' || v_Error_Message,
                         SYSDATE);
      END;
   --      o_Approval_Quotes_List := v_Approval_Quotes_List;
   END;


   PROCEDURE ZERO_INVENTORY_EMAIL
   IS
      lv_to_mail        VARCHAR2 (100);
      lv_from_mail      VARCHAR2 (100);
      lv_subject        VARCHAR2 (250);
      lv_mail_content   VARCHAR2 (3000);
   BEGIN
      SELECT PROPERTY_VALUE
        INTO lv_to_mail
        FROM WCT_PROPERTIES
       WHERE PROPERTY_TYPE = 'ZERO_INVENTORY_MAIL_ID';

      SELECT PROPERTY_VALUE
        INTO lv_from_mail
        FROM WCT_PROPERTIES
       WHERE PROPERTY_TYPE = 'ERROR_MAIL_TO';

      SELECT PROPERTY_VALUE
        INTO lv_subject
        FROM WCT_PROPERTIES
       WHERE PROPERTY_TYPE = 'ZERO_INVENTORY_MAIL_SUBJECT';

      lv_mail_content :=
         '<HTML><font face="Calibri"> Hi Team, <br><br>There is <u>No Data</u> in <b>RSCM_ML_C3_INV_MV</b>. Hence Excess Portal is showing Zero Inventory.
   <br> Please check this on priority. <br><br>Thanks & Regards,<br>Excess Portal Team </HTML>';
      VV_RSCM_UTIL.GENERIC_EMAIL_UTIL (lv_to_mail,
                                       lv_from_mail,
                                       lv_subject,
                                       lv_mail_content);
   END;

   PROCEDURE REPORTING_DATA (
      i_User_Id         IN     VARCHAR2,
      o_summaryReport      OUT WCT_REPORT_SUMMARY_LIST,
      o_quotesReport       OUT WCT_REPORT_QUOTES_LIST,
      o_salesReport        OUT WCT_REPORT_SALES_LIST)
   IS
      lv_summaryReport_List    WCT_REPORT_SUMMARY_LIST;
      lv_summaryReport_Obj     WCT_REPORT_SUMMARY_OBJECT;
      lv_quotesReport          WCT_REPORT_QUOTES_LIST;
      lv_salesReport           WCT_REPORT_SALES_LIST;
      lv_total_quotes          T_NORMALISED_LIST;
      lv_customer_list         T_NORMALISED_LIST;
      -- v_Wct_Report_Data_List   T_NORMALISED_LIST;
      lv_customer_name         VARCHAR2 (500);
      lv_summary_cust_name     VARCHAR2 (5000);
      lv_wholesale_part        VARCHAR2 (2000);
      lv_cust_id               NUMBER;
      lv_total_qty             NUMBER;
      --      lv_total_orders          T_NORMALISED_LIST;
      lv_total_orders          NUMBER;
      counter                  NUMBER := 1;
      lv_cust                  VARCHAR2 (1000);
      lv_cust_list             T_NORMALISED_LIST;
      lv_summary_cust_order    VARCHAR2 (5000);
      lv_qty_ordered           NUMBER;
      qty_quoted               NUMBER;
      lv_max_quoted_price      NUMBER;
      lv_max_quote             VARCHAR2 (10);
      lv_min_quoted_price      NUMBER;
      lv_min_quote             VARCHAR2 (10);
      lv_max_quoted_trend      NUMBER;
      lv_min_quoted_trend      NUMBER;
      lv_max_sales_price       NUMBER;
      lv_max_sales             VARCHAR (10);
      lv_max_sales_trend       NUMBER;
      lv_min_sales_price       NUMBER;
      lv_min_sales             VARCHAR2 (10);
      lv_min_sales_trend       NUMBER;
      lv_count                 NUMBER;


      TYPE WCT_REPORT_DATA_REC IS RECORD
      (
         REQUESTED_PART        VARCHAR2 (100),
         QUOTE_ID_COUNT        NUMBER,
         TOTAL_QTY             NUMBER,
         MAX_SUGGESTED_PRICE   NUMBER,
         MIN_SUGGESTED_PRICE   NUMBER,
         Quote_Cust_List       VARCHAR (1000)
      );

      TYPE WCT_REPORT_DATA_LIST IS TABLE OF WCT_REPORT_DATA_REC;

      v_Wct_Report_Data_List   WCT_REPORT_DATA_LIST
                                  := WCT_REPORT_DATA_LIST ();
   BEGIN
      v_Wct_Report_Data_List := WCT_REPORT_DATA_LIST ();
      lv_summaryReport_List := WCT_REPORT_SUMMARY_LIST ();
      lv_quotesReport := WCT_REPORT_QUOTES_LIST ();
      lv_salesReport := WCT_REPORT_SALES_LIST ();
      lv_total_quotes := T_NORMALISED_LIST ();

      --      lv_total_orders := T_NORMALISED_LIST ();

      BEGIN
           SELECT /*+ index(ql.quoteline_id_idx, qh.sys_C00590440 )*/
                  DISTINCT
                  ql.REQUESTED_PART,
                  COUNT (ql.quote_id),
                  SUM (LEAST (REQUESTED_QUANTITY, AVAILABLE_QUANTITY)),
                  MAX (ql.SUGGESTED_PRICE),
                  MIN (ql.SUGGESTED_PRICE),
                  LISTAGG (wcm.COMPANY_NAME, ',')
                     WITHIN GROUP (ORDER BY wcm.company_name)
             BULK COLLECT INTO v_Wct_Report_Data_List
             FROM Wct_quote_line ql,
                  WCT_QUOTE_HEADER qh,
                  WCT_COMPANY_MASTER wcm,
                  WCT_CUSTOMER wc
            WHERE     qh.STATUS IN ('APPROVED', 'PARTIAL', 'QUOTE')
                  AND ql.QUOTE_ID = qh.QUOTE_ID
                  AND ql.created_date >= TRUNC (SYSDATE - 90)
                  AND ql.APPROVAL_STATUS_l1 = 'A'
                  AND ql.APPROVAL_STATUS_l2 = 'A'
                  AND WC.CUSTOMER_ID = QH.CUSTOMER_ID
                  AND WCM.COMPANY_ID = WC.COMPANY_ID
         GROUP BY ql.REQUESTED_PART
         ORDER BY REQUESTED_PART;

         FOR idx IN 1 .. v_Wct_Report_Data_List.COUNT ()
         --FOR idx IN 1 .. 1
         LOOP
            --            EXIT WHEN idx IS NULL;

            SELECT LISTAGG (CUSTOMER_NAME, ',')
                      WITHIN GROUP (ORDER BY CUSTOMER_NAME)
              INTO lv_summary_cust_order
              FROM RMKTGADM.RMK_WS_AR_BACKLOG_SHIPMENT
             WHERE     SALES_ORDER_DATE >= TRUNC (SYSDATE) - 90
                   AND PRODUCT_ID =
                          v_Wct_Report_Data_List (idx).REQUESTED_PART;

            BEGIN
               SELECT COUNT (sales_order_number),
                      SUM (quantity_ordered),
                      MAX (BASE_UNIT_PRICE),
                      MIN (BASE_UNIT_PRICE)
                 INTO lv_total_orders,
                      lv_qty_ordered,
                      lv_max_sales_price,
                      lv_min_sales_price
                 FROM RMKTGADM.RMK_WS_AR_BACKLOG_SHIPMENT
                WHERE     SALES_ORDER_DATE >= TRUNC (SYSDATE) - 90
                      AND PRODUCT_ID =
                             v_Wct_Report_Data_List (idx).REQUESTED_PART;
            --
            EXCEPTION
               WHEN OTHERS
               THEN
                  lv_qty_ordered := 0;
                  lv_total_orders := 0;
            END;

            --

            CASE
               WHEN (lv_max_quoted_trend >
                        v_Wct_Report_Data_List (idx).MAX_SUGGESTED_PRICE)
               THEN
                  lv_max_quote := 'DOWN';
               WHEN (lv_max_quoted_trend =
                        v_Wct_Report_Data_List (idx).MAX_SUGGESTED_PRICE)
               THEN
                  lv_max_quote := 'SAME';
               ELSE
                  lv_max_quote := 'UP';
            END CASE;

            CASE
               WHEN (lv_min_quoted_trend >
                        v_Wct_Report_Data_List (idx).MIN_SUGGESTED_PRICE)
               THEN
                  lv_min_quote := 'DOWN';
               WHEN (lv_min_quoted_trend =
                        v_Wct_Report_Data_List (idx).MIN_SUGGESTED_PRICE)
               THEN
                  lv_min_quote := 'SAME';
               ELSE
                  lv_min_quote := 'UP';
            END CASE;


            SELECT MAX (BASE_UNIT_PRICE), MIN (BASE_UNIT_PRICE)
              INTO lv_max_sales_trend, lv_min_sales_trend
              FROM RMKTGADM.RMK_WS_AR_BACKLOG_SHIPMENT
             WHERE     product_id =
                          v_Wct_Report_Data_List (idx).REQUESTED_PART
                   AND SALES_ORDER_DATE BETWEEN TRUNC (SYSDATE - 180)
                                            AND TRUNC (SYSDATE - 90);

            CASE
               WHEN (    lv_max_sales_trend IS NULL
                     AND lv_max_sales_price IS NULL)
               THEN
                  lv_max_sales := '-';
               WHEN (lv_max_sales_trend > lv_max_sales_price)
               THEN
                  lv_max_sales := 'DOWN';
               WHEN (lv_max_sales_trend = lv_max_sales_price)
               THEN
                  lv_max_sales := 'SAME';
               ELSE
                  lv_max_sales := 'UP';
            END CASE;

            CASE
               WHEN (    lv_min_sales_trend IS NULL
                     AND lv_min_sales_price IS NULL)
               THEN
                  lv_min_sales := '-';
               WHEN (lv_min_sales_trend > lv_min_sales_price)
               THEN
                  lv_min_sales := 'DOWN';
               WHEN (lv_min_sales_trend = lv_min_sales_price)
               THEN
                  lv_min_sales := 'SAME';
               ELSE
                  lv_min_sales := 'UP';
            END CASE;

            BEGIN
               SELECT DISTINCT (WHOLESALE_PART)
                 INTO lv_wholesale_part
                 FROM WCT_QUOTE_LINE
                WHERE     REQUESTED_PART =
                             v_Wct_Report_Data_List (idx).REQUESTED_PART
                      AND WHOLESALE_PART IS NOT NULL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  lv_wholesale_part := NULL;
            END;

            lv_summaryReport_obj :=
               WCT_REPORT_SUMMARY_OBJECT (
                  v_Wct_Report_Data_List (idx).REQUESTED_PART,
                  lv_wholesale_part,
                  v_Wct_Report_Data_List (idx).QUOTE_ID_COUNT,
                  v_Wct_Report_Data_List (idx).TOTAL_QTY,
                  v_Wct_Report_Data_List (idx).Quote_Cust_List,
                  lv_summary_cust_order,
                  lv_total_orders,
                  CASE
                     WHEN v_Wct_Report_Data_List (idx).QUOTE_ID_COUNT = 0
                     THEN
                        0
                     ELSE
                          (  lv_total_orders
                           / v_Wct_Report_Data_List (idx).QUOTE_ID_COUNT)
                        * 100
                  END,
                  CASE
                     WHEN v_Wct_Report_Data_List (idx).TOTAL_QTY = 0
                     THEN
                        0
                     WHEN lv_qty_ordered = 0
                     THEN
                        0
                     ELSE
                          (  lv_qty_ordered
                           / v_Wct_Report_Data_List (idx).TOTAL_QTY)
                        * 100
                  END,
                  v_Wct_Report_Data_List (idx).MAX_SUGGESTED_PRICE,
                  lv_max_quote,
                  v_Wct_Report_Data_List (idx).MIN_SUGGESTED_PRICE,
                  lv_min_quote,
                  lv_max_sales_price,
                  lv_max_sales,
                  lv_min_sales_price,
                  lv_min_sales);
            lv_summaryReport_List.EXTEND ();
            lv_summaryReport_List (counter) := lv_summaryReport_obj;
            counter := counter + 1;
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message :=
                  SUBSTR (SQLERRM, 1, 200)
               || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('Generate summary reporting data',
                         i_User_Id,
                         v_Error_Message,
                         SYSDATE);
      END;

      SELECT WCT_REPORT_QUOTES_OBJECT (REQUESTED_PART,
                                       WHOLESALE_PART,
                                       CREATED_DATE,
                                       QUOTE_STATUS,
                                       PRICE_QUOTED,
                                       QUANTITY_QUOTED,
                                       CUSTOMER_NAME)
        BULK COLLECT INTO lv_quotesReport
        FROM (  SELECT DISTINCT
                       ql.REQUESTED_PART,
                       ql.WHOLESALE_PART,
                       ql.CREATED_DATE,
                       CASE
                          WHEN qh.STATUS = v_Status_Quote
                          THEN
                             'AUTO APPROVED'
                          WHEN qh.STATUS = v_Status_Partial
                          THEN
                             'PARTIALLY APPROVED'
                          WHEN qh.STATUS = v_Status_Approved
                          THEN
                             'APPROVED'
                       END
                          QUOTE_STATUS,
                       ql.SUGGESTED_PRICE AS PRICE_QUOTED,
                       LEAST (ql.REQUESTED_QUANTITY, ql.AVAILABLE_QUANTITY)
                          AS QUANTITY_QUOTED,
                       (SELECT COMPANY_NAME
                          FROM WCT_COMPANY_MASTER
                         WHERE COMPANY_ID = WC.COMPANY_ID)
                          AS CUSTOMER_NAME
                  FROM Wct_quote_line ql, WCT_QUOTE_header qh, WCT_CUSTOMER wc
                 WHERE     qh.STATUS IN (v_Status_Approved,
                                         v_Status_Partial,
                                         v_Status_Quote)
                       AND ql.QUOTE_ID = qh.QUOTE_ID
                       AND qh.customer_id = wc.CUSTOMER_ID
                       AND (ql.CREATED_DATE >= TRUNC (SYSDATE) - 90)
                       AND ql.APPROVAL_STATUS_l1 = v_Approval_Status_Approved
                       AND ql.APPROVAL_STATUS_l2 = v_Approval_Status_Approved
              ORDER BY ql.REQUESTED_PART);

      SELECT WCT_REPORT_SALES_OBJECT (REQUESTED_PART,
                                      WHOLESALE_PART,
                                      RECENT_SALES_PRICE,
                                      RECENT_PRICE_DATE,
                                      QUANTITY_PURCHASED,
                                      CUSTOMER_NAME)
        BULK COLLECT INTO lv_salesReport
        FROM (  SELECT WSPR1.PRODUCT_ID AS REQUESTED_PART,
                       ql.WHOLESALE_PART,
                       WSPR1.BASE_UNIT_PRICE AS RECENT_SALES_PRICE,
                       WSPR1.SALES_ORDER_DATE AS RECENT_PRICE_DATE,
                       WSPR1.QUANTITY_ORDERED AS QUANTITY_PURCHASED,
                       WSPR1.CUSTOMER_NAME
                  FROM RMKTGADM.RMK_WS_AR_BACKLOG_SHIPMENT WSPR1
                       LEFT JOIN
                       (SELECT DISTINCT REQUESTED_PART, WHOLESALE_PART
                          FROM Wct_quote_line
                         WHERE CREATED_DATE >= TRUNC (SYSDATE) - 90) ql
                          ON WSPR1.PRODUCT_ID = ql.REQUESTED_PART
                 WHERE WSPR1.SALES_ORDER_DATE >= TRUNC (SYSDATE) - 90
              ORDER BY WSPR1.PRODUCT_ID);

      o_summaryReport := lv_summaryReport_List;
      o_quotesReport := lv_quotesReport;
      o_salesReport := lv_salesReport;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         --LOG EXCEPTION
         INSERT INTO WCT_ERROR_LOG
              VALUES ('GENERATE REPORTING DATA',
                      i_User_Id,
                      'No data found',
                      SYSDATE);
      WHEN OTHERS
      THEN
         --LOG EXCEPTION
         v_Error_Message := NULL;
         v_Error_Message :=
            SUBSTR (SQLERRM, 1, 200) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

         INSERT INTO WCT_ERROR_LOG
              VALUES ('Generate reporting data',
                      i_User_Id,
                      v_Error_Message,
                      SYSDATE);
   END;

   /* New Procedure for All Quote Info */
   --Nar
   PROCEDURE LOAD_ALL_QUOTE_DETAILS (
      i_User_Id                IN     VARCHAR2,
      i_Load_Type              IN     VARCHAR2,
      o_Approval_Quotes_List      OUT WCT_RETRIEVE_QUOTES_LIST)
   IS
      v_Approval_Quotes_List   WCT_RETRIEVE_QUOTES_LIST;
      lv_User_Id               VARCHAR2 (12);
      lv_Approver_Level        NUMBER;
      lv_Load_Type             VARCHAR2 (8);
      LV_FISCAL_STRT_DATE      VARCHAR2 (20); -- to capture last fiscal year start date
   BEGIN
      lv_User_Id := i_User_Id;
      lv_Load_Type := i_Load_Type;

      BEGIN
         SELECT DISTINCT TRUNC (FISCAL_QTR_START_DATE)
           INTO LV_FISCAL_STRT_DATE
           FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
          WHERE     FISCAL_YEAR_NUMBER =
                       (  (SELECT FISCAL_YEAR_NUMBER
                             FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                            WHERE TRUNC (CALENDAR_DATE) = TRUNC (SYSDATE))
                        - 1)
                AND FISCAL_QUARTER_NUMBER = 1; --last fiscal year's start date

           SELECT WCT_RETRIEVE_QUOTES_OBJECT (QH.QUOTE_ID,
                                              COM.COMPANY_NAME,
                                              QH.LAST_UPDATED_DATE,
                                              QH.CREATED_BY,
                                              QH.DEAL_VALUE,
                                              QH.STATUS,
                                              CUST.CUSTOMER_ID,
                                              SD.STATUS_DESCRIPTION,
                                              QH.APPROVER_LEVEL_1,
                                              QH.APPROVER_LEVEL_2) --added karusing to retrieve approver id
             BULK COLLECT INTO o_Approval_Quotes_List
             FROM WCT_QUOTE_HEADER QH,
                  WCT_CUSTOMER CUST,
                  WCT_COMPANY_MASTER COM,
                  WCT_STATUS_DETAIL SD
            WHERE     1 = 1
                  AND QH.CREATED_DATE >= LV_FISCAL_STRT_DATE -- added for restricting data to last fiscal year
                  AND QH.CUSTOMER_ID = CUST.CUSTOMER_ID
                  AND (   QH.STATUS = 'APPROVED'
                       OR QH.STATUS = 'PARTIAL'
                       OR QH.STATUS = 'QUOTE'
                       OR QH.STATUS = 'REJECTED'
                       OR QH.STATUS = 'PENDING')
                  AND COM.COMPANY_ID = CUST.COMPANY_ID
                  AND QH.STATUS = SD.STATUS
         ORDER BY QH.LAST_UPDATED_DATE DESC;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            --LOG EXCEPTION
            INSERT INTO WCT_ERROR_LOG
                 VALUES ('GENERATE QUOTE LIST',
                         lv_User_Id,
                         'LOAD_APPROVAL_QUOTE_LIST - No data found',
                         SYSDATE);
         WHEN OTHERS
         THEN
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message := SUBSTR (SQLERRM, 1, 200);

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('GENERATE QUOTE LIST',
                         lv_User_Id,
                         'LOAD_APPROVAL_QUOTE_LIST - ' || v_Error_Message,
                         SYSDATE);
      END;
   --      o_Approval_Quotes_List := v_Approval_Quotes_List;
   END LOAD_ALL_QUOTE_DETAILS;


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
      o_negative_ccw_flag                OUT CHAR)
   AS
      g_error_msg                      VARCHAR2 (1500);
      lv_requested_mfg_part_number     VARCHAR2 (250);
      lv_requested_spare_part_number   VARCHAR2 (250);
      lv_requested_rf_part_number      VARCHAR2 (250);
      lv_requested_ws_part_number      VARCHAR2 (250);
      lv_region                        VARCHAR2 (20);
      lv_refresh_cycle_name            VARCHAR2 (25);
      lv_item_status                   VARCHAR2 (25);
      lv_local_region                  VARCHAR2 (20);
      lv_frn_region                    VARCHAR2 (20);
      lv_requested_qty                 NUMBER;
      lv_total_onhand_rf               NUMBER;
      lv_total_onhand_ws               NUMBER;
      lv_total_rf_rsvn                 NUMBER;
      lv_total_ws_rsvn                 NUMBER;
      lv_net_available                 NUMBER := 0;
      lv_lead_time1                    NUMBER := 0;
      lv_lead_time2                    NUMBER := 0;
      lv_lead_time3                    NUMBER := 0;
      lv_available_qty1                NUMBER := 0;
      lv_available_qty2                NUMBER := 0;
      lv_available_qty3                NUMBER := 0;
      lv_onhand_qty_lcl                NUMBER := 0;
      lv_onhand_qty_frn                NUMBER := 0;
      lv_onhand_qty_gdgi               NUMBER := 0;
      lv_lead_time_count               NUMBER := 0;
      lv_local_fulfill                 VARCHAR2 (20);
      lv_foreign_fulfill               VARCHAR2 (20);
      lv_gdgi_fulfill                  VARCHAR2 (20);
      lv_ws_present                    VARCHAR2 (20);
      lv_negative_ccw_flag             CHAR;
      --Added for US134623 <Start>
      lv_mfg_eos_date                  DATE;
      lv_eos_rch_flag                  VARCHAR2 (3);
      --Added for US134623 <End>
      lv_available_qty_list            WCT_AVAILABLE_QTY_LIST;
      lv_rf_ws_qty_list                WCT_RF_WS_QTY_LIST;
      lv_rf_ws_qty_obj                 WCT_RF_WS_QTY_OBJ;
   BEGIN
      lv_requested_mfg_part_number := NVL (i_requested_mfg_part_number, 'NA');
      lv_requested_rf_part_number := NVL (i_requested_rf_part_number, 'NA');
      lv_requested_ws_part_number := NVL (i_requested_ws_part_number, 'NA');
      lv_requested_spare_part_number :=
         NVL (i_requested_spare_part_number, 'NA');
      lv_region := i_region;
      lv_requested_qty := i_requested_qty;
      lv_available_qty_list := WCT_AVAILABLE_QTY_LIST ();
      lv_rf_ws_qty_list := WCT_RF_WS_QTY_LIST ();

      --      INSERT INTO testing
      --              VALUES (
      --                           i_requested_mfg_part_number
      --                        || ' '
      --                        || i_requested_rf_part_number
      --                        || ' '
      --                        || i_requested_ws_part_number
      --                        || ' '
      --                        || i_requested_spare_part_number);
      --
      --      COMMIT;

      BEGIN
         SELECT DISTINCT REFRESH_LIFE_CYCLE_NAME
                ,NVL (mfg_eos_date,
                           TO_DATE ('12/31/2999', 'MM/DD/YYYY')) --Added for US134623
           INTO lv_refresh_cycle_name
                ,lv_mfg_eos_date --Added for US134623
           FROM crpadm.rc_product_master
          WHERE refresh_part_number = lv_requested_ws_part_number;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lv_refresh_cycle_name := NULL;
            lv_item_status := NULL;
            lv_mfg_eos_date:=NULL;--Added for US134623
      END;

     --Added for US134623 <Start>
      lv_eos_rch_flag:='N';

      IF lv_mfg_eos_date IS NOT NULL
         AND MONTHS_BETWEEN(lv_mfg_eos_date,SYSDATE)<=4
      THEN
         lv_eos_rch_flag := 'Y';
      ELSE
         lv_eos_rch_flag := 'N';
      END IF;
      --Added for US134623 <End>

      IF (    i_requested_ws_part_number IS NOT NULL
          AND (   lv_refresh_cycle_name = 'CUR'
               OR lv_refresh_cycle_name = 'EOL'
               OR lv_refresh_cycle_name = 'EOS'))
      THEN
         lv_ws_present := 'Y';

         IF (UPPER (i_region) = 'NAM')
         THEN
            SELECT WCT_AVAILABLE_QTY_OBJ (INVENTORY_SITE,
                                          INVENTORY_THEATER,
                                          INVENTORY_LOCATION,
                                          ROHS_FLAG,
                                          ON_HAND,
                                          RESERVATIONS,
                                          TOTAL_AVAILABLE_CCW,
                                          SELECTED)
              BULK COLLECT INTO lv_available_qty_list
              FROM (  SELECT SITE_CODE INVENTORY_SITE,
                             CASE
                                WHEN SITE_CODE = 'LRO' THEN 'NAM'
                                WHEN SITE_CODE = 'FVE' THEN 'EMEA'
                                ELSE NULL
                             END
                                INVENTORY_THEATER,
                             CASE
                                WHEN SITE_CODE IN ('LRO', 'FVE') THEN 'FG'
                                WHEN SITE_CODE = 'GDGI' THEN 'GDGI'
                                ELSE NULL
                             END
                                INVENTORY_LOCATION,
                             ROHS_COMPLIANT ROHS_FLAG,
                             CASE
                                WHEN SITE_CODE IN ('LRO', 'FVE')
                                THEN
                                   NVL (AVAILABLE_FGI, 0)
                               --Added for US134623 <Start>
                                WHEN SITE_CODE = 'GDGI'  AND lv_eos_rch_flag = 'Y'
                                THEN
                                   0
                                --Added for US134623 <End>
                                WHEN SITE_CODE = 'GDGI'
                                THEN
                                   NVL (AVAILABLE_DGI, 0)
                                ELSE
                                   NULL
                             END
                                ON_HAND,
                             CASE
                                WHEN SITE_CODE IN ('LRO', 'FVE')
                                THEN
                                   NVL (RESERVED_FGI, 0)
                                --Added for US134623 <Start>
                                WHEN SITE_CODE = 'GDGI'  AND lv_eos_rch_flag = 'Y'
                                THEN
                                   0
                                --Added for US134623 <End>
                                WHEN SITE_CODE = 'GDGI'
                                THEN
                                   NVL (RESERVED_DGI, 0)
                                ELSE
                                   NULL
                             END
                                RESERVATIONS,
                             CASE
                                WHEN SITE_CODE IN ('LRO', 'FVE')
                                THEN
                                   NVL (AVAILABLE_TO_RESERVE_FGI, 0)
                                --Added for US134623 <Start>
                                WHEN SITE_CODE = 'GDGI'  AND lv_eos_rch_flag = 'Y'
                                THEN
                                   0
                                --Added for US134623 <End>
                                WHEN SITE_CODE = 'GDGI'
                                THEN
                                   NVL (AVAILABLE_TO_RESERVE_DGI, 0)
                                ELSE
                                   NULL
                             END
                                TOTAL_AVAILABLE_CCW,
                             NULL SELECTED
                        FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                       WHERE     PART_NUMBER = lv_requested_ws_part_number
                             AND SITE_CODE IN ('FVE', 'LRO', 'GDGI')
                    ORDER BY INVENTORY_THEATER DESC NULLS LAST);
         ELSIF (UPPER (i_region) = 'EMEA')
         THEN
            SELECT WCT_AVAILABLE_QTY_OBJ (INVENTORY_SITE,
                                          INVENTORY_THEATER,
                                          INVENTORY_LOCATION,
                                          ROHS_FLAG,
                                          ON_HAND,
                                          RESERVATIONS,
                                          TOTAL_AVAILABLE_CCW,
                                          SELECTED)
              BULK COLLECT INTO lv_available_qty_list
              FROM (  SELECT SITE_CODE INVENTORY_SITE,
                             CASE
                                WHEN SITE_CODE = 'LRO' THEN 'NAM'
                                WHEN SITE_CODE = 'FVE' THEN 'EMEA'
                                ELSE NULL
                             END
                                INVENTORY_THEATER,
                             CASE
                                WHEN SITE_CODE IN ('LRO', 'FVE') THEN 'FG'
                                WHEN SITE_CODE = 'GDGI' THEN 'GDGI'
                                ELSE NULL
                             END
                                INVENTORY_LOCATION,
                             ROHS_COMPLIANT ROHS_FLAG,
                             CASE
                                WHEN SITE_CODE IN ('LRO', 'FVE')
                                THEN
                                   NVL (AVAILABLE_FGI, 0)
                                --Added for US134623 <Start>
                                WHEN SITE_CODE = 'GDGI'  AND lv_eos_rch_flag = 'Y'
                                THEN
                                   0
                                --Added for US134623 <End>
                                WHEN SITE_CODE = 'GDGI'
                                THEN
                                   NVL (AVAILABLE_DGI, 0)
                                ELSE
                                   NULL
                             END
                                ON_HAND,
                             CASE
                                WHEN SITE_CODE IN ('LRO', 'FVE')
                                THEN
                                   NVL (RESERVED_FGI, 0)
                                --Added for US134623 <Start>
                                WHEN SITE_CODE = 'GDGI'  AND lv_eos_rch_flag = 'Y'
                                THEN
                                   0
                                --Added for US134623 <End>
                                WHEN SITE_CODE = 'GDGI'
                                THEN
                                   NVL (RESERVED_DGI, 0)
                                ELSE
                                   NULL
                             END
                                RESERVATIONS,
                             CASE
                                WHEN SITE_CODE IN ('LRO', 'FVE')
                                THEN
                                   NVL (AVAILABLE_TO_RESERVE_FGI, 0)
                                --Added for US134623 <Start>
                                WHEN SITE_CODE = 'GDGI'  AND lv_eos_rch_flag = 'Y'
                                THEN
                                   0
                                --Added for US134623 <End>
                                WHEN SITE_CODE = 'GDGI'
                                THEN
                                   NVL (AVAILABLE_TO_RESERVE_DGI, 0)
                                ELSE
                                   NULL
                             END
                                TOTAL_AVAILABLE_CCW,
                             NULL SELECTED
                        FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                       WHERE     PART_NUMBER = lv_requested_ws_part_number
                             AND SITE_CODE IN ('FVE', 'LRO', 'GDGI')
                             AND ROHS_COMPLIANT = 'YES' -- Added condition to return only ROHS YEs items when customer is EMEA region
                    ORDER BY INVENTORY_THEATER NULLS LAST);
         END IF;

         -- Calculate Total for Local, foregin and GDGI lines from Inv List

         FOR idx IN 1 .. lv_available_qty_list.COUNT ()
         LOOP
            lv_net_available :=
                 NVL(lv_available_qty_list (idx).TOTAL_AVAILABLE_CCW,0) --Added NVL for US134623
               + lv_net_available;
         END LOOP;


         IF (lv_region = 'NAM')
         THEN
            lv_local_region := 'NAM';
            lv_frn_region := 'EMEA';
         ELSIF (lv_region = 'EMEA')
         THEN
            lv_local_region := 'EMEA';
            lv_frn_region := 'NAM';
         END IF;

         FOR idx IN 1 .. lv_available_qty_list.COUNT ()
         LOOP
            IF (lv_available_qty_list (idx).INVENTORY_THEATER = i_region)
            THEN
               lv_onhand_qty_lcl :=
                    lv_onhand_qty_lcl
                  + NVL(lv_available_qty_list (idx).TOTAL_AVAILABLE_CCW,0); --Added NVL for US134623
            ELSE
               IF (lv_available_qty_list (idx).INVENTORY_THEATER IS NOT NULL)
               THEN
                  lv_onhand_qty_frn :=
                       lv_onhand_qty_frn
                     + NVL(lv_available_qty_list (idx).TOTAL_AVAILABLE_CCW,0);--Added NVL for US134623
               ELSE
                  IF (lv_available_qty_list (idx).INVENTORY_THEATER IS NULL)
                  THEN
                     lv_onhand_qty_gdgi :=
                          lv_onhand_qty_gdgi
                        + NVL(lv_available_qty_list (idx).TOTAL_AVAILABLE_CCW,0); --Added NVL for US134623
                  END IF;
               END IF;
            END IF;
         END LOOP;

         FOR idxn IN 1 .. lv_available_qty_list.COUNT ()
         LOOP
            IF (   lv_onhand_qty_lcl < 0
                OR lv_onhand_qty_frn < 0
                OR lv_onhand_qty_gdgi < 0)
            THEN
               lv_negative_ccw_flag := 'Y';
            ELSE
               lv_negative_ccw_flag := 'N';
            END IF;
         END LOOP;

         IF (lv_net_available > 0)
         THEN
            --            INSERT INTO testing
            --                 VALUES ('negative ccw flag: ' || lv_negative_ccw_flag);
            --
            --            COMMIT;

            --            IF (lv_negative_ccw_flag = 'N')
            --            THEN

            IF (lv_negative_ccw_flag = 'Y')
            THEN
               --               INSERT INTO testing
               --                       VALUES (
               --                                    lv_local_region
               --                                 || ' '
               --                                 || lv_frn_region
               --                                 || ' local qty: '
               --                                 || lv_onhand_qty_lcl
               --                                 || ' frn qty :'
               --                                 || lv_onhand_qty_frn
               --                                 || ' gdgi qty: '
               --                                 || lv_onhand_qty_gdgi);
               --
               --               COMMIT;

               FOR idx IN 1 .. lv_available_qty_list.COUNT
               LOOP
                  IF (    lv_onhand_qty_lcl < 0
                      AND NVL (lv_available_qty_list (idx).INVENTORY_THEATER,
                               'NA') = lv_local_region)
                  THEN
                     lv_available_qty1 := lv_net_available;
                  ELSIF (    lv_onhand_qty_frn < 0
                         AND NVL (
                                lv_available_qty_list (idx).INVENTORY_THEATER,
                                'NA') = lv_frn_region)
                  THEN
                     lv_available_qty1 := lv_net_available;
                  ELSIF (    lv_onhand_qty_gdgi < 0
                         AND lv_available_qty_list (idx).INVENTORY_THEATER
                                IS NULL)
                  THEN
                     lv_available_qty1 := lv_net_available;
                  END IF;

                  --                  lv_available_qty_list (idx).SELECTED := 'Y';
                  --               lv_available_qty1 := lv_net_available;
                  lv_lead_time1 := 4;
                  lv_lead_time_count := 1;
                  lv_local_fulfill := 'Y';
                  lv_foreign_fulfill := 'Y';
                  lv_gdgi_fulfill := 'Y';
               END LOOP;
            ELSIF (    lv_requested_qty <= lv_onhand_qty_lcl
                   AND lv_onhand_qty_lcl > 0) -- if requested qty can be met with local theater only
            THEN
               lv_available_qty1 := lv_onhand_qty_lcl;
               lv_lead_time1 := 1;
               lv_lead_time_count := 1;
               lv_local_fulfill := 'Y';
            ELSE
               IF (lv_requested_qty <= lv_onhand_qty_lcl + lv_onhand_qty_frn) -- if req qty can be met with local and foreign theater
               THEN
                  IF (lv_onhand_qty_lcl > 0)
                  THEN
                     lv_available_qty1 := lv_onhand_qty_lcl;
                     lv_lead_time1 := 1;
                     lv_available_qty2 := lv_onhand_qty_frn;
                     lv_lead_time2 := 3;
                     lv_lead_time_count := 2;
                     lv_local_fulfill := 'Y';
                     lv_foreign_fulfill := 'Y';
                  ELSE
                     lv_available_qty1 := lv_onhand_qty_frn;
                     lv_lead_time1 := 3;
                     lv_lead_time_count := 1;
                     lv_foreign_fulfill := 'Y';
                  END IF;
               ELSE
                  IF (lv_requested_qty <=
                           lv_onhand_qty_lcl
                         + lv_onhand_qty_frn
                         + lv_onhand_qty_gdgi) -- if req qty can be met with local, goreign and gdgi
                  THEN
                     IF (lv_onhand_qty_lcl > 0)
                     THEN
                        lv_available_qty1 := lv_onhand_qty_lcl;
                        lv_lead_time1 := 1;
                        lv_local_fulfill := 'Y';

                        IF (lv_onhand_qty_frn > 0) -- local > 0, foreign > 0 ; gdgi > 0
                        THEN
                           lv_available_qty2 := lv_onhand_qty_frn;
                           lv_lead_time2 := 3;
                           lv_foreign_fulfill := 'Y';

                           IF (lv_onhand_qty_gdgi > 0)
                           THEN
                              lv_available_qty3 := lv_onhand_qty_gdgi;
                              lv_lead_time3 := 4;
                              lv_gdgi_fulfill := 'Y';
                              lv_lead_time_count := 3;
                           ELSE
                              lv_lead_time_count := 2;
                           END IF;
                        ELSE
                           IF (lv_onhand_qty_gdgi > 0)
                           THEN
                              lv_available_qty2 := lv_onhand_qty_gdgi;
                              lv_lead_time2 := 4;
                              lv_lead_time_count := 2;
                              lv_gdgi_fulfill := 'Y';
                           ELSE
                              lv_lead_time_count := 1;
                           END IF;
                        END IF;
                     ELSE
                        IF (lv_onhand_qty_frn > 0) -- local= 0, foreign > 0 ; gdgi > 0
                        THEN
                           lv_available_qty1 := lv_onhand_qty_frn;
                           lv_lead_time1 := 3;
                           lv_foreign_fulfill := 'Y';

                           IF (lv_onhand_qty_gdgi > 0)
                           THEN
                              lv_available_qty2 := lv_onhand_qty_gdgi;
                              lv_lead_time2 := 4;
                              lv_lead_time_count := 2;
                              lv_gdgi_fulfill := 'Y';
                           ELSE
                              lv_lead_time_count := 1;
                           END IF;
                        ELSE               -- local = 0 , foreign = 0 gdgi > 0
                           lv_available_qty1 := lv_onhand_qty_gdgi;
                           lv_lead_time1 := 4;
                           lv_gdgi_fulfill := 'Y';
                        END IF;
                     END IF;
                  ELSE       -- Qty req > total avbl ( Local + foreign + GDGI)
                     IF (lv_onhand_qty_lcl > 0)
                     THEN
                        lv_available_qty1 := lv_onhand_qty_lcl;
                        lv_lead_time1 := 1;
                        lv_local_fulfill := 'Y';

                        IF (lv_onhand_qty_frn > 0) -- local > 0, foreign > 0 ; gdgi > 0
                        THEN
                           lv_available_qty2 := lv_onhand_qty_frn;
                           lv_lead_time2 := 3;
                           lv_foreign_fulfill := 'Y';

                           IF (lv_onhand_qty_gdgi > 0)
                           THEN
                              lv_available_qty3 := lv_onhand_qty_gdgi;
                              lv_lead_time3 := 4;
                              lv_gdgi_fulfill := 'Y';
                              lv_lead_time_count := 3;
                           ELSE
                              lv_lead_time_count := 2;
                           END IF;
                        ELSE
                           IF (lv_onhand_qty_gdgi > 0)
                           THEN
                              lv_available_qty2 := lv_onhand_qty_gdgi;
                              lv_lead_time2 := 4;
                              lv_lead_time_count := 2;
                              lv_gdgi_fulfill := 'Y';
                           ELSE
                              lv_lead_time_count := 1;
                           END IF;
                        END IF;
                     ELSE
                        IF (lv_onhand_qty_frn > 0) -- local= 0, foreign > 0 ; gdgi > 0
                        THEN
                           lv_available_qty1 := lv_onhand_qty_frn;
                           lv_lead_time1 := 3;
                           lv_foreign_fulfill := 'Y';

                           IF (lv_onhand_qty_gdgi > 0)
                           THEN
                              lv_available_qty2 := lv_onhand_qty_gdgi;
                              lv_lead_time2 := 4;
                              lv_lead_time_count := 2;
                              lv_gdgi_fulfill := 'Y';
                           ELSE
                              lv_lead_time_count := 1;
                           END IF;
                        ELSIF (lv_onhand_qty_gdgi > 0) -- local = 0 , foreign = 0 gdgi > 0
                        THEN
                           lv_available_qty1 := lv_onhand_qty_gdgi;
                           lv_lead_time1 := 4;
                           lv_gdgi_fulfill := 'Y';
                        ELSIF (    lv_onhand_qty_lcl = 0
                               AND lv_onhand_qty_frn = 0
                               AND lv_onhand_qty_gdgi = 0)
                        THEN
                           lv_available_qty1 := 0;
                           lv_available_qty2 := 0;
                           lv_available_qty3 := 0;

                           lv_lead_time1 := 0;
                           lv_lead_time2 := 0;
                           lv_lead_time3 := 0;
                           lv_lead_time_count := 0;
                        END IF;
                     END IF;
                  END IF;
               END IF;
            END IF;

            FOR idx IN 1 .. lv_available_qty_list.COUNT ()
            LOOP
               IF (    lv_local_fulfill = 'Y'
                   AND lv_available_qty_list (idx).INVENTORY_THEATER =
                          i_region)
               THEN
                  lv_available_qty_list (idx).SELECTED := 'Y';
               ELSE
                  IF (    lv_foreign_fulfill = 'Y'
                      AND lv_available_qty_list (idx).INVENTORY_THEATER !=
                             i_region
                      AND lv_available_qty_list (idx).INVENTORY_THEATER
                             IS NOT NULL)
                  THEN
                     lv_available_qty_list (idx).SELECTED := 'Y';
                  ELSE
                     IF (    lv_gdgi_fulfill = 'Y'
                         AND lv_available_qty_list (idx).INVENTORY_THEATER
                                IS NULL)
                     THEN
                        lv_available_qty_list (idx).SELECTED := 'Y';
                     END IF;
                  END IF;
               END IF;
            END LOOP;
         ELSE                                           -- net requested < 0 -
            lv_available_qty1 := 0;
            lv_lead_time1 := 0;
            lv_lead_time_count := 0;
            lv_gdgi_fulfill := 'Y';
            lv_foreign_fulfill := 'Y';
            lv_local_fulfill := 'Y';

            FOR idx IN 1 .. lv_available_qty_list.COUNT ()
            LOOP
               IF (    lv_local_fulfill = 'Y'
                   AND lv_available_qty_list (idx).INVENTORY_THEATER =
                          i_region)
               THEN
                  lv_available_qty_list (idx).SELECTED := 'Y';
               ELSE
                  IF (    lv_foreign_fulfill = 'Y'
                      AND lv_available_qty_list (idx).INVENTORY_THEATER !=
                             i_region
                      AND lv_available_qty_list (idx).INVENTORY_THEATER
                             IS NOT NULL)
                  THEN
                     lv_available_qty_list (idx).SELECTED := 'Y';
                  ELSE
                     IF (    lv_gdgi_fulfill = 'Y'
                         AND lv_available_qty_list (idx).INVENTORY_THEATER
                                IS NULL)
                     THEN
                        lv_available_qty_list (idx).SELECTED := 'Y';
                     END IF;
                  END IF;
               END IF;
            END LOOP;
         END IF;

         o_Lead_Time_Count := lv_lead_time_count;

         IF (UPPER (i_region) = 'EMEA')
         THEN
            SELECT /*SUM (MSTR.AVAILABLE_FGI + MSTR.AVAILABLE_DGI),
                   SUM (MSTR.RESERVED_FGI + MSTR.RESERVED_DGI)*/ --Commented for US134623
                   --Added for US134623 <Start>
                   SUM (MSTR.AVAILABLE_FGI + DECODE(lv_eos_rch_flag ,'N',MSTR.AVAILABLE_DGI,0 )),
                   SUM (MSTR.RESERVED_FGI  + DECODE(lv_eos_rch_flag ,'N',MSTR.RESERVED_DGI,0 ))
                   --Added for US134623 <End>
              INTO lv_total_onhand_rf, lv_total_rf_rsvn
              FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER MSTR
             WHERE     MSTR.PART_NUMBER = lv_requested_rf_part_number
                   AND MSTR.ROHS_COMPLIANT = 'YES';



            SELECT /* SUM (MSTR.AVAILABLE_FGI + MSTR.AVAILABLE_DGI),
                   SUM (MSTR.RESERVED_FGI + MSTR.RESERVED_DGI) */--Commented for US134623
                    --Added for US134623 <Start>
                   SUM (MSTR.AVAILABLE_FGI + DECODE(lv_eos_rch_flag ,'N',MSTR.AVAILABLE_DGI,0 )),
                   SUM (MSTR.RESERVED_FGI  + DECODE(lv_eos_rch_flag ,'N',MSTR.RESERVED_DGI,0 ))
                   --Added for US134623 <End>
              INTO lv_total_onhand_ws, lv_total_ws_rsvn
              FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER MSTR
             WHERE     MSTR.PART_NUMBER = lv_requested_ws_part_number
                   AND MSTR.ROHS_COMPLIANT = 'YES';
         ELSE
            SELECT /* SUM (MSTR.AVAILABLE_FGI + MSTR.AVAILABLE_DGI),
                   SUM (MSTR.RESERVED_FGI + MSTR.RESERVED_DGI) */--Commented for US134623
                    --Added for US134623 <Start>
                   SUM (MSTR.AVAILABLE_FGI + DECODE(lv_eos_rch_flag ,'N',MSTR.AVAILABLE_DGI,0 )),
                   SUM (MSTR.RESERVED_FGI  + DECODE(lv_eos_rch_flag ,'N',MSTR.RESERVED_DGI,0 ))
                   --Added for US134623 <End>
              INTO lv_total_onhand_rf, lv_total_rf_rsvn
              FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER MSTR
             WHERE MSTR.PART_NUMBER = lv_requested_rf_part_number;

            SELECT /* SUM (MSTR.AVAILABLE_FGI + MSTR.AVAILABLE_DGI),
                   SUM (MSTR.RESERVED_FGI + MSTR.RESERVED_DGI) */--Commented for US134623
                    --Added for US134623 <Start>
                   SUM (MSTR.AVAILABLE_FGI + DECODE(lv_eos_rch_flag ,'N',MSTR.AVAILABLE_DGI,0 )),
                   SUM (MSTR.RESERVED_FGI  + DECODE(lv_eos_rch_flag ,'N',MSTR.RESERVED_DGI,0 ))
                   --Added for US134623 <End>
              INTO lv_total_onhand_ws, lv_total_ws_rsvn
              FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER MSTR
             WHERE MSTR.PART_NUMBER = lv_requested_ws_part_number;
         END IF;

         lv_rf_ws_qty_list.EXTEND ();
         lv_rf_ws_qty_obj :=
            WCT_RF_WS_QTY_OBJ (lv_total_onhand_rf,
                               lv_total_onhand_ws,
                               i_requested_qty,
                               lv_total_rf_rsvn,
                               lv_total_ws_rsvn,
                               lv_net_available);
         lv_rf_ws_qty_list (1) := lv_rf_ws_qty_obj;

         o_WS_present := lv_ws_present;
      ELSE
         lv_ws_present := 'N';

           --         INSERT INTO testing
           --              VALUES ('inside else loop');
           --
           --         COMMIT;

           --(start)  commented by hkarka as on 27-MAR-2017
/*
           SELECT WCT_AVAILABLE_QTY_OBJ (INVENTORY_SITE,
                                         INVENTORY_THEATER,
                                         INVENTORY_LOCATION,
                                         ROHS_FLAG,
                                         SUM (ON_HAND),
                                         SUM (RESERVATIONS),
                                         SUM (TOTAL_AVAILABLE_CCW),
                                         SELECTED)
             BULK COLLECT INTO lv_available_qty_list
             FROM (SELECT 'GDGI' INVENTORY_SITE,
                          NULL INVENTORY_THEATER,
                          'GDGI' INVENTORY_LOCATION,
                          ROHS_PART ROHS_FLAG,
                          CASE
                             WHEN (SCM.DESTINATION_SUBINVENTORY IS NULL)
                             THEN
                                QTY_ON_HAND
                             ELSE
                                ROUND (
                                     QTY_ON_HAND
                                   * (NVL (PM_PROD.rm_yield, 80) / 100))
                          END
                             ON_HAND,
                          QTY_RESERVED RESERVATIONS,
                          NULL TOTAL_AVAILABLE_CCW,
                          NULL SELECTED
                     FROM (  SELECT PRODUCT_NAME_STRIPPED,
                                    SITE,
                                    REGION,
                                    'YES' ROHS_PART,
                                    LOCATION,
                                    SUM (QTY_ON_HAND) QTY_ON_HAND,
                                    SUM (QTY_RESERVED) QTY_RESERVED,
                                    NULL TOTAL_AVAILABLE
                               FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV mv
                              WHERE MV.PART_NUMBER IN (lv_requested_mfg_part_number,
                                                       lv_requested_ws_part_number,
                                                       lv_requested_rf_part_number,
                                                       lv_requested_spare_part_number)
                           GROUP BY PRODUCT_NAME_STRIPPED,
                                    SITE,
                                    REGION,
                                    LOCATION,
                                    ROHS_PART) MV
                          LEFT OUTER JOIN
                          VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
                             ON     PM_PROD.product_name_stripped =
                                       MV.product_name_stripped
                                AND PM_PROD.REGION_NAME = MV.REGION
                          LEFT OUTER JOIN
                          VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP SCM
                             ON     MV.LOCATION = SCM.DESTINATION_SUBINVENTORY
                                AND SCM.YIELD_WS = 'YES'
                    WHERE     1 = 1
                          AND MV.LOCATION IN (SELECT DESTINATION_SUBINVENTORY
                                                FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
                                               WHERE     1 = 1
                                                     AND (   PROGRAM_TYPE = 1
                                                          OR PROGRAM_TYPE = 2) -- include WS and POE locations
                                                     AND IS_NETTABLE = 1
                                                     AND IS_ENABLE = 1
                                                     AND DESTINATION_SUBINVENTORY NOT IN ('WS-FGSLD'))
                          -- AND INVENTORY_TYPE <> 2)-- to allow WS WIP
                          AND MV.LOCATION NOT IN (                     --'FG',
                                                  'WS-FGSLD',
                                                  'RF-W-RHS',
                                                  'RF-W-OEM',
                                                  'RF-WIP'         -- 'WS-WIP'
                                                          ))
         GROUP BY INVENTORY_SITE,
                  INVENTORY_THEATER,
                  INVENTORY_LOCATION,
                  ROHS_FLAG,
                  SELECTED;

*/
--(end)  commented by hkarka as on 27-MAR-2017

--(start)  added by hkarka as on 27-MAR-2017
  SELECT WCT_AVAILABLE_QTY_OBJ (
            inventory_site,
            inventory_theater,
            inventory_location,
            rohs_flag,
            SUM (ROUND (QTY_ON_HAND * (NVL (refresh_yield, 80) / 100))),
            SUM (qty_reserved),
            SUM (TOTAL_AVAILABLE_CCW),
            selected)
    BULK COLLECT INTO lv_available_qty_list
    FROM (SELECT 'GDGI' inventory_site,
                 NULL inventory_theater,
                 'GDGI' inventory_location,
                 'YES' rohs_flag,
                 mv.part_number,
                 mv.site,
                 mv.location,
                 mv.qty_on_hand,
                 mv.qty_in_transit,
                 mv.qty_reserved,
                 mv.repair_flag,
                 mv.product_name_stripped,
                 mv.region,
                 locmstr.sub_inventory_id,
                 locmstr.program_type,
                 locmstr.nettable_flag,
                 vv_rscm_util.calculate_yield (mv.location,
                                  mv.part_number,
                                  locmstr.program_type,
                                  mv.region,
                                  SUBSTR (mv.site, 1, 3),
                                  NULL)                     --refurb_method_id
                    refresh_yield,
                 NULL TOTAL_AVAILABLE_CCW,
                 NULL selected
            FROM CRPADM.RC_INV_BTS_C3_MV mv, --VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV mv, --Modified by satbanda on 23rd Jan,2018 for replacing VAVNI RSCM objects
                 CRPADM.RC_SUB_INV_LOC_MSTR locmstr
           WHERE     locmstr.sub_inventory_location = mv.location
                 AND locmstr.program_type IN (1, 2)
                 AND locmstr.nettable_flag = 1
                 AND MV.PART_NUMBER IN ( lv_requested_mfg_part_number,
                                        lv_requested_ws_part_number,
                                        lv_requested_rf_part_number,
                                        lv_requested_spare_part_number)
                 AND MV.LOCATION NOT IN ('WS-FGSLD',
                                         'RF-W-RHS',
                                         'RF-W-OEM',
                                         'RF-WIP'))
GROUP BY inventory_site,
         inventory_theater,
         inventory_location,
         rohs_flag;
--(end)  added by hkarka as on 27-MAR-2017



         lv_lead_time1 := 4;
         lv_lead_time2 := 0;
         lv_lead_time3 := 0;
         o_Lead_Time_Count := 1;


         SELECT SUM (QTY_ON_HAND) QTY_ON_HAND,
                SUM (QTY_RESERVED) QTY_RESERVED
           INTO lv_total_onhand_rf, lv_total_rf_rsvn
           FROM CRPADM.RC_INV_BTS_C3_MV mv --VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV mv --Modified by satbanda on 23rd Jan,2018 for replacing VAVNI RSCM objects
                INNER JOIN crpadm.rc_product_master mstr
                   ON (   MV.PART_NUMBER = MSTR.REFRESH_PART_NUMBER
                       OR MV.PART_NUMBER = MSTR.COMMON_PART_NUMBER
                       OR MV.PART_NUMBER = MSTR.XREF_PART_NUMBER)
          WHERE     1 = 1
                AND (   MSTR.REFRESH_PART_NUMBER IN (lv_requested_rf_part_number,
                                                     lv_requested_mfg_part_number)
                     OR MSTR.COMMON_PART_NUMBER IN (lv_requested_rf_part_number,
                                                    lv_requested_mfg_part_number)
                     OR MSTR.XREF_PART_NUMBER IN (lv_requested_rf_part_number,
                                                  lv_requested_mfg_part_number))
                --(start) commented by hkarka as on 27-MAR-2017
/*
        AND MV.LOCATION IN (SELECT DESTINATION_SUBINVENTORY
                                      FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
                                     WHERE     1 = 1
                                           AND (PROGRAM_TYPE = 2)
                                           AND IS_NETTABLE = 1
                                           AND IS_ENABLE = 1
                                           AND INVENTORY_TYPE <> 2);
*/
--(end) commented by hkarka as on 27-MAR-2017
--(start) added by hkarka as on 27-MAR-2017
                AND MV.LOCATION IN (SELECT sub_inventory_location
                                      FROM crpadm.RC_SUB_INV_LOC_MSTR
                                     WHERE     1 = 1
                                           AND (PROGRAM_TYPE = 2)
                                           AND MONTHS_BETWEEN(NVL(mstr.mfg_eos_date,TO_DATE ('12/31/2999', 'MM/DD/YYYY')),SYSDATE)>4 --Added for US134623
                                           AND nettable_flag = 1
                                           AND INVENTORY_TYPE <> 2);
--(end) added by hkarka as on 27-MAR-2017


         IF (lv_available_qty_list.COUNT > 0)
         THEN
            --            INSERT INTO testing
            --                 VALUES ('list count is >0');

            lv_available_qty1 := lv_available_qty_list (1).ON_HAND;
            lv_total_onhand_ws := lv_available_qty_list (1).ON_HAND;
            lv_total_ws_rsvn := 0;
            lv_net_available := lv_available_qty_list (1).ON_HAND;

            lv_available_qty_list (1).TOTAL_AVAILABLE_CCW :=
               lv_total_onhand_ws;
            lv_available_qty_list (1).SELECTED := 'Y';
         END IF;


         lv_rf_ws_qty_list.EXTEND ();
         lv_rf_ws_qty_obj :=
            WCT_RF_WS_QTY_OBJ (lv_total_onhand_rf,
                               lv_total_onhand_ws,
                               i_requested_qty,
                               lv_total_rf_rsvn,
                               lv_total_ws_rsvn,
                               lv_net_available);
         lv_rf_ws_qty_list (1) := lv_rf_ws_qty_obj;
      END IF;

      o_available_qty_list := lv_available_qty_list;
      o_rf_ws_qty_list := lv_rf_ws_qty_list;
      o_lead_time1 := lv_lead_time1;
      o_lead_time2 := lv_lead_time2;
      o_lead_time3 := lv_lead_time3;
      o_available_qty1 := lv_available_qty1;
      o_available_qty2 := lv_available_qty2;
      o_available_qty3 := lv_available_qty3;
      o_WS_present := lv_ws_present;
      o_negative_ccw_flag := lv_negative_ccw_flag;
   EXCEPTION
      WHEN OTHERS
      THEN
         g_error_msg :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
   -- Logging exception
   --         CRPADM.RC_GLOBAL_ERROR_LOGGING ('OTHERS',
   --                                         g_error_msg,
   --                                         NULL,
   --                                         'MAIN',
   --                                         'PROCEDURE',
   --                                         NULL,
   --                                         'Y');
   END;

   PROCEDURE DATA_EXTRACT_MODIFY (
      i_search_list              IN     WCT_BOM_LIST,
      i_Customer_Id              IN     NUMBER,
      i_User_ID                  IN     VARCHAR2,
      i_Search_Type              IN     VARCHAR2,
      i_Quote_Id                 IN     VARCHAR2,
      i_Copy_Quote_Customer_Id   IN     NUMBER,
      o_Search_Result_Object        OUT WCT_SEARCH_RESULT_MOD_OBJECT)
   IS
      --   Declare TYPES
      v_Out_Search_Data_List          WCT_SEARCH_DATA_MODIFY_LIST;
      v_Search_Data_Object            WCT_SEARCH_DATA_MODIFY_OBJECT;
      v_Out_Search_Result_Object      WCT_SEARCH_RESULT_MOD_OBJECT;
      v_Sales_History_List            WCT_SALES_HISTORY_LIST;
      v_Inventory_avbl_List           WCT_AVAILABLE_QTY_LIST;
      v_RF_WS_Inv_Qty_List            WCT_RF_WS_QTY_LIST;

      v_Recent_Quotes_List            WCT_RECENT_QUOTES_LIST;
      v_Customer_Detail_Object        WCT_CUSTOMER_DETAIL_OBJECT;
      v_Invalid_Part_List             WCT_VARCHAR_LIST;
      v_Property_Mapping_List         WCT_PROPERTY_MAPPING_LIST;
      v_Inventory_Detail_gbl_list     WCT_INVENTORY_GLOBAL_OBJECT;

      v_Recent_Sales_Object           WCT_SALES_HISTORY_OBJECT;
      --Commented by satbanda on 20-Mar-2017 for validate PID logic <Start>
    /*   v_Exclude_Pid_List              WCT_VARCHAR_LIST; -- added for exclusion of PID Sept 2014
      v_Brightline_Plus_Pid_List      WCT_VARCHAR_LIST; -- added for exclusion of PID Sept 2014 */
      --Commented by satbanda on 20-Mar-2017 for validate PID logic <End>
      l_sqerrm                        VARCHAR2 (4000);
      --Commented by satbanda on 20-Mar-2017 for validate PID logic <Start>
      /* v_RL_Pid_List                   WCT_VARCHAR_LIST; -- added for RL Oct 2014
      v_NON_ORDERABLE_Pid_List        WCT_VARCHAR_LIST; */
      --Commented by satbanda on 20-Mar-2017 for validate PID logic <End>
      lv_c3_inv_count                 NUMBER;
      lv_temp1                        NUMBER;
      lv_negative_ccw_flag            CHAR;

      TYPE T_PART_DETAILS_OBJECT IS RECORD
      (
         product_name          VARCHAR2 (50),
         product_common_name   VARCHAR2 (50)
      );

      TYPE T_PART_DETAILS_LIST IS TABLE OF T_PART_DETAILS_OBJECT;

      TYPE T_EDIT_QUOTE_LIST IS TABLE OF WCT_QUOTE_LINE%ROWTYPE;

      v_Part_Details_Object           T_PART_DETAILS_OBJECT;
      v_Part_Details_List             T_PART_DETAILS_LIST;

      --   Declare local variable
      lv_Line_No                      VARCHAR2 (1000);
      lv_Requested_Part               VARCHAR2 (50);
      lv_Manufacture_Part             VARCHAR2 (50);
      lv_Refurbished_Part             VARCHAR2 (50);
      lv_RF_Part                      VARCHAR2 (50) := v_Empty_String;
      lv_spare_Part                   VARCHAR2 (50) := v_Empty_String;
      lv_Wholesale_Part               VARCHAR2 (50);
      lv_Encryption_Status            VARCHAR2 (30);
      lv_Available_Quantity_1         NUMBER;
      lv_Available_Quantity_2         NUMBER;
      lv_Available_Quantity_3         NUMBER;
      lv_Requested_Quantity           NUMBER;
      lv_Broker_Offer                 NUMBER (15, 2);
      lv_Broker_Offer_Missing_Flag    CHAR;
      lv_Glp                          NUMBER (15, 2);
      lv_Base_Price                   NUMBER (15, 2);
      lv_Suggested_Price_Old          NUMBER (15, 2);
      lv_Suggested_Price_New          NUMBER (15, 2);
      lv_Ext_Sell_Price_1             NUMBER (15, 2);
      lv_Ext_Sell_Price_2             NUMBER (15, 2);
      lv_Ext_Sell_Price_3             NUMBER (15, 2);
      lv_Base_Price_Discount          NUMBER (5, 2);
      lv_Lead_Time_1                  VARCHAR2 (5);
      lv_Lead_Time_2                  VARCHAR2 (5);
      lv_Lead_Time_3                  VARCHAR2 (5);
      lv_WS_present                   VARCHAR2 (5) := v_Empty_String;
      lv_Lead_Time_Count              NUMBER;
      lv_rf_part_count                NUMBER;

      -- Variables for local region
      lv_Reservation_RF_Quotes        NUMBER;
      lv_Reservation_RF_Backlog       NUMBER;
      lv_Reservation_WS_Order         NUMBER;
      lv_Reservation_POE_For_RF_Lcl   NUMBER;

      lv_Reservation_Total_Lcl        NUMBER;
      lv_Reservation_Total_RF         NUMBER;


      lv_Available_RF                 VARCHAR2 (10);
      lv_Available_WS                 VARCHAR2 (10);
      lv_Available_POE                VARCHAR2 (10);

      --Commented by satbanda on 20-Mar-2017 for validate PID logic <Start>
      /* lv_Product_Name_Stripped        VARCHAR2 (50);
      lv_Product_Name_Stripped_WS     VARCHAR2 (50);*/
      --Commented by satbanda on 20-Mar-2017 for validate PID logic <End>
      lv_Recent_Price                 NUMBER (15, 2);

      lv_FG_Only                      NUMBER;
      lv_Base_Discount_Default        NUMBER;
      lv_Base_Discount_Eos            NUMBER;
      lv_Base_Discount_Eos_Over       NUMBER;
      lv_Eos_Date                     DATE;
      lv_Eos_Over_Date                DATE;
      lv_Customer_Id                  NUMBER;
      lv_User_Id                      VARCHAR2 (20);
      lv_Quote_Id                     VARCHAR2 (10);
      lv_Quote_Line_Id                NUMBER;
      lv_Date                         DATE;
      lv_Deal_Value                   NUMBER (15, 2) := 0.00;
      lv_Part_Validity_Flag           CHAR;
      lv_Invalid_Part_Count           NUMBER;
      lv_index                        NUMBER := 1;
      --lv_RL_Part_Validity_Flag        CHAR;   --added for RL karusing Oct 2014--Commented by satbanda on 20-Mar-2017 for validate PID logic

      lv_Round_Scale                  NUMBER;
      --Commented by satbanda on 20-Mar-2017 for validate PID logic <Start>
      /* lv_Exclude_Pid_Validity_Flag    CHAR; -- added for exclusion of PID karusing Sept 2014
      lv_Brightline_Plus_Flag         CHAR; -- added for exclusion of PID karusing Sept 2014
      lv_Exclude_Pid_Count            NUMBER; --added for exclusion of PID karusing Sept 2014
      lv_Brightline_Plus_Pid_Count    NUMBER; --added for exclusion of PID karusing Sept 2014
      lv_Brightline_Category          NUMBER; ---added for exclusion of PID karusing Sept 2014

      lv_RL_Pid_Count                 NUMBER;      --added for RL Pid Oct 2014

      lv_NON_ORDERABLE_Pid_Count      NUMBER; --ADDED FOR NON ORDERABLE PID MAR 2017 */
      --Commented by satbanda on 20-Mar-2017 for validate PID logic <End>

      --v_Quote_Line_Insert_List        T_EDIT_QUOTE_LIST;
      v_Quote_Line_Update_List        T_EDIT_QUOTE_LIST;

      lv_Inventory_Detail_Notes_1     VARCHAR2 (4000) := v_Empty_String;
      lv_Inventory_Detail_Notes_2     VARCHAR2 (4000) := v_Empty_String;
      lv_Inventory_Detail_Notes_3     VARCHAR2 (4000) := v_Empty_String;
      lv_Region_Local                 VARCHAR2 (4);
      lv_Region_Foreign               VARCHAR2 (4);
      lv_Static_Price_Exists          CHAR;
      lv_Copy_Quote_Customer_Id       NUMBER;
      lv_Old_Quote_Id                 VARCHAR2 (10);
      --Commented by satbanda on 20-Mar-2017 for validate PID logic <Start>
   /*    lv_Conflicting_Part_Count       NUMBER;
      lv_Conflicting_Part_Id          VARCHAR2 (50);
      lv_Conflicting_Part_WS          VARCHAR2 (50); */
      --Commented by satbanda on 20-Mar-2017 for validate PID logic <End>

      lv_Lead_Time_Id                 NUMBER;
      lv_Row_Id                       NUMBER;
      lv_Lead_Time_Row_Count          NUMBER;
      lv_Row_Count                    NUMBER;
      lv_N_Value                      VARCHAR2 (5);

      -- added for June 2014 release - ruchhabr
      lv_Gdgi_Reservation             NUMBER;
      lv_Gdgi_WS_Reservation          NUMBER;
      lv_Quantity_On_Hand_1           NUMBER;
      lv_Quantity_In_Transit_1        NUMBER;
      lv_Quantity_On_Hand_2           NUMBER;
      lv_Quantity_In_Transit_2        NUMBER;
      lv_exclude_count                NUMBER;     --added for exclusion of PID
      IS_RL_AVAILABLE                 NUMBER := 0;              --added for RL
      lv_Product_Common_Name          VARCHAR2 (50);           -- added for RL
      lv_Strip_RL                     VARCHAR2 (50);            --added for RL

      lv_RL_Pid_Add                   VARCHAR2 (50);            --added for RL
      --Added by satbanda to get the active Part for deactivated Wholesale parts<Start>
      lv_common_part                  VARCHAR2 (300);
      lv_refresh_cycle_name           VARCHAR2 (300);
      lv_Wholesale_Part_nbr           VARCHAR2 (300);

      lv_COMMON_PART_NUMBER           VARCHAR2 (300);
      lv_REFRESH_INVENTORY_ITEM_ID    VARCHAR2 (300);

      lv_orderablePIDCount            NUMBER := 0;
      lv_ORDERABLE_Flag               CHAR;
   --Added by satbanda to get the active Part for deactivated Wholesale parts<End>
      lv_Error_Message                VARCHAR2 (2000);
      lv_promo_flag                    VARCHAR2 (3); --Added for US151907
   BEGIN
      INSERT INTO wct_error_log
           VALUES (i_Search_Type,
                   i_User_ID,
                   'error',
                   SYSDATE);

      COMMIT;
      v_Out_Search_Data_List := WCT_SEARCH_DATA_MODIFY_LIST ();
      v_Sales_History_List := WCT_SALES_HISTORY_LIST ();
      -- v_Inventory_Detail_List_Local := WCT_AVAILABLE_QTY_LIST ();

      lv_Customer_Id := i_Customer_Id;
      lv_User_Id := i_User_ID;
      lv_Quote_Id := i_Quote_Id;
      lv_Copy_Quote_Customer_Id := i_Copy_Quote_Customer_Id;
      lv_Old_Quote_Id := i_Quote_Id;

      -- insert into nar(seq,quote_id, issue) values(1,'Data Extract=> '||lv_Quote_Id||' quotes '||lv_Old_Quote_Id,lv_Customer_Id||' lv_Customer_Id$lv_User_Id '||lv_User_Id ); commit;
      -- Fetch current date
      SELECT SYSTIMESTAMP INTO lv_Date FROM DUAL;

      -- Start of code changes done by Infosys for April 2014 release - ravchitt
      -- Fetch region for customer
      IF (lv_Copy_Quote_Customer_Id IS NOT NULL)
      THEN
         IF (lv_Copy_Quote_Customer_Id <> lv_Customer_Id)
         THEN
            lv_Customer_Id := lv_Copy_Quote_Customer_Id;
            lv_Copy_Quote_Customer_Id := i_Customer_Id;
         END IF;
      END IF;

      SELECT REGION
        INTO lv_Region_Local
        FROM WCT_CUSTOMER CUST, WCT_COMPANY_MASTER COM
       WHERE     CUSTOMER_ID = lv_Customer_Id
             AND CUST.COMPANY_ID = COM.COMPANY_ID;

      -- End of code changes done by Infosys for April 2014 release ravchitt
      CASE
         WHEN lv_Region_Local = 'NAM'
         THEN
            lv_Region_Foreign := 'EMEA';
         WHEN lv_Region_Local = 'EMEA'
         THEN
            lv_Region_Foreign := 'NAM';
      END CASE;

      v_Invalid_Part_List := WCT_VARCHAR_LIST ();
      lv_Invalid_Part_Count := 1;

      --Commented by satbanda on 20-Mar-2017 for validate PID logic <Start>
      /* v_Exclude_Pid_List := WCT_VARCHAR_LIST ();
      lv_Exclude_Pid_Count := 1;

      v_Brightline_Plus_Pid_List := WCT_VARCHAR_LIST ();
      lv_Brightline_Plus_Pid_Count := 1;

      v_RL_Pid_List := WCT_VARCHAR_LIST ();
      lv_RL_Pid_Count := 1;

      v_NON_ORDERABLE_Pid_List := WCT_VARCHAR_LIST ();
      lv_NON_ORDERABLE_Pid_Count := 1; */
      --Commented by satbanda on 20-Mar-2017 for validate PID logic <End>

      --8.2 Get currency rounding scale and system discount from Properties table

      -- Fetch all properties in 1 query
      SELECT WCT_PROPERTY_MAPPING_OBJECT (PROPERTY_TYPE, PROPERTY_VALUE)
        BULK COLLECT INTO v_Property_Mapping_List
        FROM WCT_PROPERTIES
       WHERE PROPERTY_TYPE IN ('CURRENCY_ROUNDING_SCALE',
                               'SYSTEM_DISCOUNT_DEFAULT',
                               'SYSTEM_DISCOUNT_EOS',
                               'SYSTEM_DISCOUNT_EOS_OVER');

      FOR idx IN 1 .. v_Property_Mapping_List.COUNT ()
      LOOP
         IF (v_Property_Mapping_List (idx).PROPERTY_TYPE =
                'CURRENCY_ROUNDING_SCALE')
         THEN
            lv_Round_Scale :=
               TO_NUMBER (v_Property_Mapping_List (idx).PROPERTY_VALUE);
         ELSIF (v_Property_Mapping_List (idx).PROPERTY_TYPE =
                   'SYSTEM_DISCOUNT_DEFAULT')
         THEN
            lv_Base_Discount_Default :=
               v_Property_Mapping_List (idx).PROPERTY_VALUE;
         ELSIF (v_Property_Mapping_List (idx).PROPERTY_TYPE =
                   'SYSTEM_DISCOUNT_EOS')
         THEN
            lv_Base_Discount_Eos :=
               v_Property_Mapping_List (idx).PROPERTY_VALUE;
         ELSIF (v_Property_Mapping_List (idx).PROPERTY_TYPE =
                   'SYSTEM_DISCOUNT_EOS_OVER')
         THEN
            lv_Base_Discount_Eos_Over :=
               v_Property_Mapping_List (idx).PROPERTY_VALUE;
         END IF;
      END LOOP;

      lv_Base_Price_Discount := lv_Base_Discount_Default;

      SELECT ADD_MONTHS (SYSDATE, -12) INTO lv_Eos_Over_Date FROM DUAL;

      --      idx:=1;
      FOR idx IN 1 .. i_search_list.COUNT ()
      LOOP
         EXIT WHEN idx IS NULL;
         --1.0 Extract input values to local variables
         lv_Line_No := i_search_list (idx).LINE_NO;
         lv_Requested_Part := i_search_list (idx).REQUESTED_PART;
         lv_Requested_Quantity := i_search_list (idx).QUANTITY;
         lv_Broker_Offer_Missing_Flag :=
            UPPER (i_search_list (idx).BROKER_OFFER_MISSING_FLAG);

         IF (lv_Broker_Offer_Missing_Flag = v_Flag_Yes)
         THEN
            lv_Broker_Offer := NULL;
         ELSE
            lv_Broker_Offer := i_search_list (idx).BROKER_OFFER;
         END IF;

         --Added for US151907 <Start>
         lv_promo_flag:='N';
         BEGIN
             SELECT promo_flag
               INTO lv_promo_flag
               FROM wct_quote_line
             WHERE  quote_id = lv_Quote_Id
               AND  requested_part=    i_search_list (idx).requested_part;
         EXCEPTION
             WHEN Others
             THEN
                lv_promo_flag:='N';
         END;

         --Added for US151907 <End>

         -- Reset local variales
         lv_Manufacture_Part := v_Empty_String;
         lv_Refurbished_Part := v_Empty_String;
         lv_Wholesale_Part := v_Empty_String;
         lv_Encryption_Status := v_Empty_String;
         lv_Row_Id := 1;
         lv_Ext_Sell_Price_2 := 0;
         --Commented by satbanda on 20-Mar-2017 for validate PID logic <Start>
         /*lv_Exclude_Pid_Validity_Flag := v_Flag_Yes;
         lv_Brightline_Plus_Flag := v_Flag_Yes;
         lv_RL_Part_Validity_Flag := v_Flag_Yes;*/
         --Commented by satbanda on 20-Mar-2017 for validate PID logic <End>

          --Added by satbanda on 20-Mar-2017 for validate PID logic <start>
          VV_RSCM_UTIL.wct_validate_pid (lv_Requested_Part,
                                        lv_User_id,
                                        lv_Manufacture_Part,
                                        lv_spare_Part,
                                        lv_Wholesale_Part,
                                        lv_Refurbished_Part,
                                        lv_Part_Validity_Flag,
                                        lv_Error_Message);



            IF lv_Error_Message IS NOT NULL
            THEN
               v_Invalid_Part_List.EXTEND ();
               v_Invalid_Part_List (lv_Invalid_Part_Count) := lv_Error_Message;
               lv_Invalid_Part_Count := lv_Invalid_Part_Count + 1;
               lv_Part_Validity_Flag:= v_Flag_No;
            END IF;
            --Added by satbanda on 20-Mar-2017 for validate PID logic <End>

          --Commented apart of Validate PID logic <start>
         /*
         --Validate each BOM
         --Using VALIDATE_PART_ID from VV_RSCM_UTIL - Setting NULL for Region
         lv_Part_Validity_Flag :=
            VV_RSCM_UTIL.VALIDATE_PART_ID_EXCESS_MODIFY (lv_Requested_Part,
                                                         NULL);

         -- start: add exclusion logic - arrajago,Aug 2014
         lv_exclude_count := 0;
         lv_Brightline_Category := 0;

         -- Get Part Stripped name
         lv_Product_Name_Stripped :=
            VV_RSCM_UTIL.GET_STRIPPED_NAME (lv_Requested_Part); -- to restrict WS,MFG,spare PID if any one is brightline


         SELECT COUNT (1)
           INTO lv_exclude_count
           FROM vavni_cisco_rscm_admin.WCT_EXCLUDE_PID
          WHERE        STATUS = 'ACTIVE'
                   AND EXCLUDE_TIER1 = 'Y'
                   AND EXCLUDE_TIER2 = 'Y'
                   AND EXCLUDE_TIER3 = 'Y'
                   AND (   BRIGHTLINE_CATEGORY = '1'
                        OR BRIGHTLINE_CATEGORY = '2')
                   -- AND PRODUCT_ID = lv_Requested_Part;
                   AND PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped -- added to restrict WS,Spare PID and MFG PID.
                OR PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped || 'WS'
                OR PRODUCT_NAME_STRIPPED =
                      DECODE (
                         SUBSTR (
                            lv_Product_Name_Stripped,
                            (  LENGTH (lv_Product_Name_Stripped)
                             - LENGTH (lv_Product_Name_Stripped)
                             - 2)),
                         'WS', SUBSTR (lv_Product_Name_Stripped,
                                       1,
                                       LENGTH (lv_Product_Name_Stripped) - 2));

         --OR PRODUCT_NAME_STRIPPED =
         --      SUBSTR (lv_Product_Name_Stripped,
         --             1,
         --             LENGTH (lv_Product_Name_Stripped) - 2);



         BEGIN
            --            SELECT BRIGHTLINE_CATEGORY
            --              INTO lv_Brightline_Category
            --              FROM WCT_EXCLUDE_PID
            --             WHERE PRODUCT_ID = lv_Requested_Part;



            SELECT BRIGHTLINE_CATEGORY
              INTO lv_Brightline_Category
              FROM vavni_cisco_rscm_admin.WCT_EXCLUDE_PID
             WHERE    PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped -- added to restrict WS,Spare PID and MFG PID.
                   OR PRODUCT_NAME_STRIPPED =
                         lv_Product_Name_Stripped || 'WS'
                   OR PRODUCT_NAME_STRIPPED =
                         DECODE (
                            SUBSTR (
                               lv_Product_Name_Stripped,
                               (  LENGTH (lv_Product_Name_Stripped)
                                - LENGTH (lv_Product_Name_Stripped)
                                - 2)),
                            'WS', SUBSTR (
                                     lv_Product_Name_Stripped,
                                     1,
                                     LENGTH (lv_Product_Name_Stripped) - 2));
         --   OR PRODUCT_NAME_STRIPPED =
         --        SUBSTR (lv_Product_Name_Stripped,
         --                1,
         --                LENGTH (lv_Product_Name_Stripped) - 2);

         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lv_Brightline_Category := 0;
         END;



         BEGIN
            SELECT REFRESH_INVENTORY_ITEM_ID
              INTO lv_REFRESH_INVENTORY_ITEM_ID
              FROM CRPADM.RC_PRODUCT_MASTER
             WHERE     (   COMMON_PART_NUMBER = lv_Requested_Part
                        OR xref_PART_NUMBER = lv_Requested_Part
                        OR REFRESH_PART_NUMBER = lv_Requested_Part)
                   AND refresh_life_cycle_name NOT IN ('DEACTIVATED')
                   AND program_type = 1;
                   --            SELECT DISTINCT COMMON_PART_NUMBER

            --              INTO lv_COMMON_PART_NUMBER
            --              FROM CRPADM.RC_PRODUCT_MASTER
            --             WHERE     (   COMMON_PART_NUMBER = lv_Requested_Part
            --                        OR COMMON_PART_NUMBER = lv_Requested_Part || '='
            --                        OR REFRESH_PART_NUMBER = lv_Requested_Part)
            --                   AND COMMON_PART_NUMBER IS NOT NULL; -- to resrtict records with Common Part Number as NULL --59 in prod
            --
            --            --getREFRESH_INVENTORY_ITEM_ID
            --
            --            SELECT REFRESH_INVENTORY_ITEM_ID
            --              INTO lv_REFRESH_INVENTORY_ITEM_ID
            --              FROM CRPADM.RC_PRODUCT_MASTER
            --             WHERE     COMMON_PART_NUMBER = lv_COMMON_PART_NUMBER
            --                   AND Program_type = 1;
            --
            --
            IF (lv_REFRESH_INVENTORY_ITEM_ID IS NOT NULL)
            THEN
               SELECT COUNT (1)
                 INTO lv_orderablePIDCount
                 FROM CRPADM.RC_PRODUCT_MASTER
                WHERE     REFRESH_INVENTORY_ITEM_ID =
                             lv_REFRESH_INVENTORY_ITEM_ID
                      AND REFRESH_LIFE_CYCLE_ID = 3
                      AND INVENTORY_ITEM_STATUS_CODE = 'ENABLE-MAJ';

               --                      AND EXISTS
               --                             (SELECT 1
               --                                FROM CG1_MTL_SYSTEM_ITEMS_B@ODSPROD mtl -- 1.5
               --                               WHERE     mtl.INVENTORY_ITEM_ID =
               --                                            lv_REFRESH_INVENTORY_ITEM_ID
               --                                     AND mtl.organization_id = 1
               --                                     AND NVL (mtl.INVENTORY_ITEM_STATUS_CODE,
               --                                              'NA') = 'ENABLE-MAJ');

               IF (lv_orderablePIDCount > 0)
               THEN
                  lv_ORDERABLE_Flag := v_Flag_Yes;
               ELSE
                  lv_ORDERABLE_Flag := v_Flag_No;
               END IF;
            ELSE
               lv_ORDERABLE_Flag := v_Flag_Yes;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lv_ORDERABLE_Flag := v_Flag_Yes;
            WHEN OTHERS
            THEN
               lv_ORDERABLE_Flag := v_Flag_No;
         END;

         IF     (lv_Part_Validity_Flag = v_Flag_Yes)
            AND (lv_exclude_count > 0)
            AND (lv_Brightline_Category = 1)  -- category 1 for brightline PID
         THEN
            lv_Exclude_Pid_Validity_Flag := v_Flag_No;
         ELSIF     (lv_Part_Validity_Flag = v_Flag_Yes)
               AND (lv_exclude_count > 0)
               AND (lv_Brightline_Category = 2) -- category 2 for brightline Plus PID
         THEN
            lv_Brightline_Plus_Flag := v_Flag_No;
         ELSIF (lv_Part_Validity_Flag = v_Flag_No) AND (lv_exclude_count > 0)
         THEN
            lv_Part_Validity_Flag := v_Flag_No;
         ELSIF (lv_Part_Validity_Flag = v_Flag_No)
         THEN
            lv_Requested_Part := lv_Requested_Part || '=';
            lv_Part_Validity_Flag :=
               VV_RSCM_UTIL.VALIDATE_PART_ID_EXCESS_MODIFY (
                  lv_Requested_Part,
                  NULL);
         END IF;

         -- end: add exclusion logic - arrajago, Aug 2014

         -- If invalid part found, add it to invalid part list
         IF (lv_Part_Validity_Flag = v_Flag_No)
         THEN
            lv_RL_Pid_Add := i_search_list (idx).REQUESTED_PART;

            SELECT    SUBSTR (lv_RL_Pid_Add, 1, LENGTH (lv_RL_Pid_Add) - 2)
                   || 'RL'
              INTO lv_Strip_RL
              FROM DUAL;

            lv_RL_Part_Validity_Flag :=
               VV_RSCM_UTIL.VALIDATE_PART_ID_EXCESS_MODIFY (lv_Strip_RL,
                                                            NULL);

            IF (lv_RL_Part_Validity_Flag = v_Flag_Yes)
            -- IF( v_Invalid_Part_List(idx).REQUESTED_PART = lv_Strip_RL )
            --  'SUBSTR(lv_Product_Name_Stripped,1,LENGTH(lv_Product_Name_Stripped)-2)||'RL')'
            THEN
               v_RL_Pid_List.EXTEND ();
               v_RL_Pid_List (lv_RL_Pid_Count) :=
                  i_search_list (idx).REQUESTED_PART;
               lv_RL_Pid_Count := lv_RL_Pid_Count + 1;
            ELSE
               v_Invalid_Part_List.EXTEND ();
               v_Invalid_Part_List (lv_Invalid_Part_Count) :=
                  i_search_list (idx).REQUESTED_PART;
               lv_Invalid_Part_Count := lv_Invalid_Part_Count + 1;
            END IF;
         --END IF;
         -- if exclude PID found, add to exclusion list
         ELSIF (lv_Exclude_Pid_Validity_Flag = v_Flag_No)
         THEN
            v_Exclude_Pid_List.EXTEND ();
            v_Exclude_Pid_List (lv_Exclude_Pid_Count) :=
               i_search_list (idx).REQUESTED_PART;
            lv_Exclude_Pid_Count := lv_Exclude_Pid_Count + 1;
         --if brightline plus Pid found add to brightline plus list
         ELSIF (lv_Brightline_Plus_Flag = v_Flag_No)
         THEN
            v_Brightline_Plus_Pid_List.EXTEND ();
            v_Brightline_Plus_Pid_List (lv_Brightline_Plus_Pid_Count) :=
               i_search_list (idx).REQUESTED_PART;
            lv_Brightline_Plus_Pid_Count := lv_Brightline_Plus_Pid_Count + 1;
         ELSIF (lv_ORDERABLE_Flag = v_Flag_No)
         THEN
            v_NON_ORDERABLE_Pid_List.EXTEND ();
            v_NON_ORDERABLE_Pid_List (lv_NON_ORDERABLE_Pid_Count) :=
               i_search_list (idx).REQUESTED_PART;
            lv_NON_ORDERABLE_Pid_Count := lv_NON_ORDERABLE_Pid_Count + 1;*/

            --Commented apart of Validate PID logic <End>
         IF (lv_Part_Validity_Flag = v_Flag_Yes) --Added apart of Validate PID logic
         THEN
         --ELSE --Commented apart of Validate PID logic
            --Fetch data for the requested part


            --            -- Get Part Stripped name
            --            lv_Product_Name_Stripped :=
            --               VV_RSCM_UTIL.GET_STRIPPED_NAME (lv_Requested_Part);

--(Start) commented by hkarka as on 20-MAR-2017 for stripped name logic change
/*
            IF (lv_Requested_Part LIKE '%-RL') -- OR lv_Requested_Part LIKE '%-RF')
            THEN
               lv_Product_Name_Stripped_WS :=
                     SUBSTR (lv_Product_Name_Stripped,
                             1,
                             LENGTH (lv_Product_Name_Stripped) - 2)
                  || 'WS';
            ELSIF (lv_Requested_Part NOT LIKE '%-WS')
            THEN
               lv_Product_Name_Stripped_WS := lv_Product_Name_Stripped || 'WS';
            ELSIF (lv_Requested_Part LIKE '%-WS')
            THEN
               lv_Product_Name_Stripped_WS := lv_Product_Name_Stripped;
               lv_Product_Name_Stripped :=
                  SUBSTR (lv_Product_Name_Stripped,
                          1,
                          LENGTH (lv_Product_Name_Stripped) - 2);
            END IF;
*/
--(End) commented by hkarka as on 20-MAR-2017 for stripped name logic change

            v_Recent_Quotes_List :=
               GET_RECENT_QUOTE_DETAILS (lv_Requested_Part, lv_User_Id);

            --3.0 Get basic attributes like Manufacture Part, Refurbished Part, Wholesale part, Encryption Status, GLP

--(Start) commented by hkarka as on 20-MAR-2017 for stripped name logic change
/*
        -- 3.0.1 Get conflicting part count
            SELECT COUNT (*)
              INTO lv_Conflicting_Part_Count
              FROM WCT_CONFLICTING_PARTS
             WHERE PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped;

            --3.1 Fetch Manufacture Part
            BEGIN
               IF (lv_Conflicting_Part_Count > 1)
               THEN
                  SELECT PRODUCT_ID, PRODUCT_ID_WHOLESALE
                    INTO lv_Conflicting_Part_Id, lv_Conflicting_Part_WS
                    FROM WCT_CONFLICTING_PARTS
                   WHERE     1 = 1
                         AND (   PRODUCT_ID = lv_Requested_Part
                              OR PRODUCT_ID_REFURBISHED = lv_Requested_Part
                              OR PRODUCT_ID_WHOLESALE = lv_Requested_Part);

                  SELECT PRODUCT_NAME, PRODUCT_COMMON_NAME
                    BULK COLLECT INTO v_Part_Details_List
                    FROM (SELECT DISTINCT
                                 PM_PROD.PRODUCT_NAME,
                                 PM_PROD.PRODUCT_COMMON_NAME
                            FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
                           WHERE    PM_PROD.PRODUCT_NAME =
                                       lv_Conflicting_Part_Id
                                 OR PM_PROD.PRODUCT_NAME =
                                       lv_Conflicting_Part_WS);
               ELSE
                  SELECT COUNT (*)
                    INTO IS_RL_AVAILABLE
                    FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW
                   WHERE    PRODUCT_NAME_STRIPPED =
                               lv_Product_Name_Stripped || '%RL'
                         OR PRODUCT_NAME_STRIPPED = lv_Product_Name_Stripped;

                  -- SELECT PRODUCT_COMMON_NAME INTO lv_Product_Common_Name from VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW where
                  -- UPPER(PRODUCT_NAME)=UPPER(lv_Requested_Part);

                  IF (IS_RL_AVAILABLE > 0)
                  THEN
                     IF (lv_Requested_Part LIKE '%-RF') -- OR lv_Requested_Part=lv_Product_Common_Name)
                     THEN
                        SELECT PRODUCT_NAME, PRODUCT_COMMON_NAME
                          BULK COLLECT INTO v_Part_Details_List
                          FROM (SELECT DISTINCT
                                       PM_PROD.PRODUCT_NAME,
                                       PM_PROD.PRODUCT_COMMON_NAME
                                  FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
                                 WHERE (   (    (   PM_PROD.PRODUCT_NAME_STRIPPED =
                                                       lv_Product_Name_Stripped
                                                 OR PM_PROD.PRODUCT_NAME_STRIPPED =
                                                       -- added for mapping RF part with RL part
                                                       SUBSTR (
                                                          lv_Product_Name_Stripped,
                                                          1,
                                                            LENGTH (
                                                               lv_Product_Name_Stripped)
                                                          - 2)
                                                 OR PM_PROD.PRODUCT_NAME_STRIPPED =
                                                          lv_Product_Name_Stripped
                                                       || 'RL')
                                            AND PM_PROD.PRODUCT_NAME LIKE
                                                   '%-RF')
                                        OR PM_PROD.PRODUCT_NAME_STRIPPED =
                                              lv_Product_Name_Stripped_WS
                                        OR PM_PROD.PRODUCT_NAME_STRIPPED =
                                                 lv_Product_Name_Stripped
                                              || 'WS'));
                     ELSE
                        SELECT PRODUCT_NAME, PRODUCT_COMMON_NAME
                          BULK COLLECT INTO v_Part_Details_List
                          FROM (  SELECT DISTINCT
                                         PM_PROD.PRODUCT_NAME,
                                         PM_PROD.PRODUCT_COMMON_NAME
                                    FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
                                   WHERE (   PM_PROD.PRODUCT_NAME_STRIPPED =
                                                lv_Product_Name_Stripped
                                          OR PM_PROD.PRODUCT_NAME_STRIPPED =
                                                lv_Product_Name_Stripped_WS
                                          OR PM_PROD.PRODUCT_NAME_STRIPPED =
                                                -- added for mapping MFG part with RL part
                                                SUBSTR (
                                                   lv_Product_Name_Stripped,
                                                   1,
                                                     LENGTH (
                                                        lv_Product_Name_Stripped)
                                                   - 2)
                                          OR --added for mapping ws part with RL part
                                            PM_PROD.PRODUCT_NAME_STRIPPED =
                                                --added for mapping MFG part with RL part
                                                (   SUBSTR (
                                                       lv_Product_Name_Stripped,
                                                       1,
                                                         LENGTH (
                                                            lv_Product_Name_Stripped)
                                                       - 2)
                                                 || 'RL')
                                          OR PM_PROD.PRODUCT_NAME_STRIPPED =
                                                   lv_Product_Name_Stripped
                                                || 'RL'
                                          OR PM_PROD.PRODUCT_NAME_STRIPPED =
                                                   lv_Product_Name_Stripped
                                                || 'WS')
                                ORDER BY product_name ASC);
                     --                     SELECT DISTINCT PRODUCT_NAME_STRIPPED INTO lv_Product_Name_Stripped
                     --                     FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW WHERE (PRODUCT_NAME_STRIPPED =
                     --                                    lv_Product_Name_Stripped OR
                     --                                    PRODUCT_NAME_STRIPPED =
                     --                                    lv_Product_Name_Stripped||'RL'
                     --                                    or
                     --                                     ) AND PRODUCT_NAME LIKE '%-RL';
                     END IF;
                  ELSE
                     SELECT PRODUCT_NAME, PRODUCT_COMMON_NAME
                       BULK COLLECT INTO v_Part_Details_List
                       FROM (SELECT DISTINCT
                                    PM_PROD.PRODUCT_NAME,
                                    PM_PROD.PRODUCT_COMMON_NAME
                               FROM VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
                              WHERE    PM_PROD.PRODUCT_NAME_STRIPPED =
                                          lv_Product_Name_Stripped
                                    OR PM_PROD.PRODUCT_NAME_STRIPPED =
                                          lv_Product_Name_Stripped_WS);
                  END IF;
               END IF;

               --Commented apart of Validate PID logic <start>
               /*
               IF (v_Part_Details_List.COUNT () > 0)
               THEN
                  FOR i IN 1 .. v_Part_Details_List.COUNT ()
                  LOOP
                     v_Part_Details_Object := v_Part_Details_List (i);

                     IF (v_Part_Details_Object.product_name LIKE '%WS')
                     THEN
                        lv_Wholesale_Part :=
                           v_Part_Details_Object.product_name;
                     ELSIF (v_Part_Details_Object.product_name LIKE '%-RF')
                     THEN
                        lv_Refurbished_Part :=
                           v_Part_Details_Object.product_name;
                     ELSIF (v_Part_Details_Object.product_name LIKE '%-RL')
                     THEN
                        lv_Refurbished_Part :=
                           v_Part_Details_Object.product_name;
                     END IF;

                     lv_Manufacture_Part :=
                        v_Part_Details_Object.product_common_name;
                  END LOOP;
               ELSE
                  lv_Refurbished_Part := v_Empty_String;
                  lv_Wholesale_Part := v_Empty_String;

                  --3.1.1 - If Product is not found in RSCM, get this info from New Product Master table which contains all Cisco PIDs
                  BEGIN
                     SELECT DISTINCT PRODUCT_ID
                       INTO lv_Manufacture_Part
                       FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                      WHERE PRODUCT_ID = lv_Requested_Part;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        BEGIN
                           SELECT DISTINCT PRODUCT_ID
                             INTO lv_Manufacture_Part
                             FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                            WHERE PRODUCT_ID = lv_Requested_Part || '=';
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              lv_Manufacture_Part := v_Empty_String;
                        END;
                  END;
               END IF;*//*
            --Commented apart of Validate PID logic <End>
            EXCEPTION
               --LOG EXCEPTION
               WHEN OTHERS
               THEN
                  --LOG EXCEPTION
                  v_Error_Message := NULL;
                  v_Error_Message := SUBSTR (SQLERRM, 1, 200);

                  INSERT INTO WCT_ERROR_LOG
                          VALUES (
                                    UPPER (lv_Requested_Part),
                                    lv_User_Id,
                                       'Data_extract - Step 3.1 - '
                                    || v_Error_Message,
                                    SYSDATE);
            END;
*/
--(End) commented by hkarka as on 20-MAR-2017 for stripped name logic change

            -- Fetch encryption status



            BEGIN
               SELECT DISTINCT ECCN
                 INTO lv_Encryption_Status
                 FROM CRPADM.RC_PRODUCT_MASTER
                WHERE common_part_number = lv_Manufacture_Part;

               INSERT INTO wct_error_log
                    VALUES (UPPER (lv_Manufacture_Part),
                            lv_Encryption_Status,
                            'dint get encryption status' || v_Error_Message,
                            SYSDATE);

               COMMIT;

               IF (   lv_Encryption_Status LIKE '5A002%'
                   OR lv_Encryption_Status LIKE '5D002%')
               THEN
                  lv_Encryption_Status := 'Dual Use';
               ELSE
                  lv_Encryption_Status := '';
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN                                            --LOG EXCEPTION
                  v_Error_Message := NULL;
                  v_Error_Message := SUBSTR (SQLERRM, 1, 200);
                  lv_Encryption_Status := '';

                  INSERT INTO WCT_ERROR_LOG
                          VALUES (
                                    UPPER (lv_Requested_Part),
                                    lv_User_Id,
                                       'ERROR in finding encryption status '
                                    || v_Error_Message,
                                    SYSDATE);
            END;

            --3.2 Fetch  GLP, EOS
            BEGIN
               SELECT NVL (LIST_PRICE, 0),
                      NVL (EO_SALES_DATE,
                           TO_DATE ('12/31/2999', 'MM/DD/YYYY')) -- '12/31/2999' Added for assigning far off value to NUll value
                 INTO lv_Glp, lv_Eos_Date
                 FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                WHERE PRODUCT_ID = lv_Wholesale_Part; -- Tech data change to fetch price using WS part

               -- if GLP is 0, Try with = appended to MFG part
               IF (lv_Glp = 0)
               THEN
                  BEGIN
                     IF (SUBSTR (lv_Manufacture_Part, -1, 1) = '=')
                     THEN
                        SELECT NVL (LIST_PRICE, 0),
                               NVL (EO_SALES_DATE,
                                    TO_DATE ('12/31/2999', 'MM/DD/YYYY')) -- '12/31/2999' Added for assigning far off value to NUll value
                          INTO lv_Glp, lv_Eos_Date
                          FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                         WHERE PRODUCT_ID =
                                  SUBSTR (lv_Manufacture_Part,
                                          1,
                                          (LENGTH (lv_Manufacture_Part) - 1)); -- Try with = removed from MFG part
                     ELSE
                        SELECT NVL (LIST_PRICE, 0),
                               NVL (EO_SALES_DATE,
                                    TO_DATE ('12/31/2999', 'MM/DD/YYYY')) -- '12/31/2999' Added for assigning far off value to NUll value
                          INTO lv_Glp, lv_Eos_Date
                          FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                         WHERE PRODUCT_ID = (lv_Manufacture_Part || '='); -- Try with = appended to MFG part
                     END IF;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        lv_Glp := 0;
                     WHEN OTHERS --added WHEN OTHERS exception by hkarka on 20-MAR-2017
                     THEN
                        lv_Glp := 0;
                  END;
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  BEGIN
                     IF (SUBSTR (lv_Manufacture_Part, -1, 1) = '=')
                     THEN
                        SELECT NVL (LIST_PRICE, 0),
                               NVL (EO_SALES_DATE,
                                    TO_DATE ('12/31/2999', 'MM/DD/YYYY')) -- '12/31/2999' Added for assigning far off value to NUll value
                          INTO lv_Glp, lv_Eos_Date
                          FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                         WHERE PRODUCT_ID =
                                  SUBSTR (lv_Manufacture_Part,
                                          1,
                                          (LENGTH (lv_Manufacture_Part) - 1)); -- Try with = removed from MFG part
                     ELSE
                        SELECT NVL (LIST_PRICE, 0),
                               NVL (EO_SALES_DATE,
                                    TO_DATE ('12/31/2999', 'MM/DD/YYYY')) -- '12/31/2999' Added for assigning far off value to NUll value
                          INTO lv_Glp, lv_Eos_Date
                          FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER
                         WHERE PRODUCT_ID = (lv_Manufacture_Part || '='); -- Try with = appended to MFG part
                     END IF;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        lv_Glp := 0;

                        --LOG EXCEPTION
                        INSERT INTO WCT_ERROR_LOG
                                VALUES (
                                          UPPER (lv_Requested_Part),
                                          lv_User_Id,
                                          'Data_extract - Step 3.2 - No data found',
                                          SYSDATE);
                     WHEN OTHERS --added WHEN OTHERS exception by hkarka on 20-MAR-2017
                     THEN
                        lv_Glp := 0;

                        --LOG EXCEPTION
                        v_Error_Message := NULL;
                        v_Error_Message := SUBSTR (SQLERRM, 1, 200);
                        INSERT INTO WCT_ERROR_LOG
                                VALUES (
                                          UPPER (lv_Requested_Part),
                                          lv_User_Id,
                                       'Data_extract - Step 3.2 - '
                                    || v_Error_Message,
                                          SYSDATE);
                  END;
               WHEN OTHERS
               THEN
                  lv_Glp := 0;

                  --LOG EXCEPTION
                  v_Error_Message := NULL;
                  v_Error_Message := SUBSTR (SQLERRM, 1, 200);

                  INSERT INTO WCT_ERROR_LOG
                          VALUES (
                                    UPPER (lv_Requested_Part),
                                    lv_User_Id,
                                       'Data_extract - Step 3.2 - '
                                    || v_Error_Message,
                                    SYSDATE);
            END;

            --            --4.0 Compute Reservations
            --            -- 4.0.1 Compute local reservations
            --            COMPUTE_RESERVATIONS (lv_Requested_Part,
            --                                  lv_Product_Name_Stripped,
            --                                  lv_User_Id,
            --                                  lv_Region_Local,
            --                                  lv_Conflicting_Part_Count,
            --                                  lv_Conflicting_Part_Id,
            --                                  lv_Conflicting_Part_WS,
            --                                  lv_Reservation_RF_Quotes_Lcl,
            --                                  lv_Reservation_RF_Backlog_Lcl,
            --                                  lv_Reservation_WS_Order_Lcl,
            --                                  lv_Reservation_Total_Lcl,
            --                                  lv_Reservation_Total_RF_Lcl,
            --                                  lv_Reservation_Total_WS_Lcl);
            --
            --            -- 4.0.2 Compute foreign reservations
            --            COMPUTE_RESERVATIONS (lv_Requested_Part,
            --                                  lv_Product_Name_Stripped,
            --                                  lv_User_Id,
            --                                  lv_Region_Foreign,
            --                                  lv_Conflicting_Part_Count,
            --                                  lv_Conflicting_Part_Id,
            --                                  lv_Conflicting_Part_WS,
            --                                  lv_Reservation_RF_Quotes_Frn,
            --                                  lv_Reservation_RF_Backlog_Frn,
            --                                  lv_Reservation_WS_Order_Frn,
            --                                  lv_Reservation_Total_Frn,
            --                                  lv_Reservation_Total_RF_Frn,
            --                                  lv_Reservation_Total_WS_Frn);
            --
            --            -- 4.0.3 Compute GDGI Reservation
            --
            --            --   /* Start changes to include FG inventory Aug 2016 */
            --            lv_Gdgi_Reservation :=
            --               GET_GDGI_RESERVATION (lv_Product_Name_Stripped);
            --
            --            -- 4.0.4 Update local reservations with GDGI reservation
            --            lv_Reservation_RF_Backlog_Lcl :=
            --               lv_Reservation_RF_Backlog_Lcl + lv_Gdgi_Reservation;
            --
            --            lv_Reservation_Total_RF_Lcl :=
            --               lv_Reservation_Total_RF_Lcl + lv_Gdgi_Reservation;
            --
            --            lv_Reservation_Total_Lcl :=
            --               lv_Reservation_Total_Lcl + lv_Gdgi_Reservation;
            --
            --            lv_Gdgi_WS_Reservation :=
            --               GET_GDGI_RESERVATION_WS (lv_Product_Name_Stripped_WS);
            --
            --            lv_Reservation_WS_Order_Lcl :=
            --               lv_Reservation_WS_Order_Lcl + lv_Gdgi_WS_Reservation;
            --
            --            lv_Reservation_Total_WS_Lcl :=
            --               lv_Reservation_Total_WS_Lcl + lv_Gdgi_WS_Reservation;
            --
            --            lv_Reservation_Total_Lcl :=
            --               lv_Reservation_Total_Lcl + lv_Gdgi_WS_Reservation;



            --5.0 Inventory computation
            -- 5.0.1 Compute Inventory by Sub Locations and Available Quantity
            --            compute_inv_and_available_qty (lv_Requested_Part,
            --                                           lv_Product_Name_Stripped,
            --                                           lv_Wholesale_Part,
            --                                           lv_User_Id,
            --                                           lv_Requested_Quantity,
            --                                           lv_Reservation_Total_RF_Lcl,
            --                                           lv_Reservation_Total_WS_Lcl,
            --                                           lv_Reservation_Total_RF_Frn,
            --                                           lv_Reservation_Total_WS_Frn,
            --                                           lv_Region_Local,
            --                                           lv_Region_Foreign,
            --                                           lv_Conflicting_Part_Count,
            --                                           lv_Conflicting_Part_Id,
            --                                           lv_Conflicting_Part_WS,
            --                                           lv_Reservation_POE_For_RF_Lcl,
            --                                           lv_FG_Only,
            --                                           lv_Available_RF_Lcl,
            --                                           lv_Available_WS_Lcl,
            --                                           lv_Available_POE_Lcl,
            --                                           lv_Available_Quantity_1,
            --                                           lv_Available_Quantity_2,
            --                                           v_Inventory_Detail_List_Local,
            --                                           v_Inventory_Detail_List_Frn,
            --                                           lv_Lead_Time_1,
            --                                           lv_Lead_Time_2,
            --                                           lv_Lead_Time_Count,
            --                                           lv_Inventory_Detail_Notes_1,
            --                                           lv_Inventory_Detail_Notes_2,
            --                                           lv_Available_RF_Frn,
            --                                           lv_Quantity_On_Hand_1, -- added for June 2014 release - ruchhabr
            --                                           lv_Quantity_In_Transit_1, -- added for June 2014 release - ruchhabr
            --                                           lv_Quantity_On_Hand_2, -- added for June 2014 release - ruchhabr
            --                                           lv_Quantity_In_Transit_2); -- added for June 2014 release - ruchhabr


            --Derive Spare, RF parts to send to cal avbl inv procedure

            --Derive Spare, RF parts to send to cal avbl inv procedure

            --Commented apart of Validate PID logic <start>
        /*

            IF (SUBSTR (lv_Manufacture_Part, -1) <> '=')
            THEN
               lv_spare_Part := lv_Manufacture_Part || '=';
            ELSE
               lv_spare_part := lv_Manufacture_Part;
               lv_Manufacture_Part :=
                  SUBSTR (lv_Manufacture_Part,
                          1,
                          (LENGTH (lv_Manufacture_Part) - 1));
            END IF;


            BEGIN
               SELECT COUNT (*)
                 INTO lv_rf_part_count
                 FROM CRPADM.RC_PRODUCT_MASTER PROD
                WHERE     PROD.COMMON_PART_NUMBER IN (lv_spare_Part,
                                                      lv_Manufacture_Part)
                      AND program_TYPE = 0;


               IF (lv_rf_part_count > 1)
               THEN
                  SELECT REFRESH_PART_NUMBER
                    INTO lv_RF_part
                    FROM CRPADM.RC_PRODUCT_MASTER PROD
                   WHERE     PROD.COMMON_PART_NUMBER IN (lv_spare_Part,
                                                         lv_Manufacture_Part)
                         AND program_TYPE = 0
                         AND REFRESH_LIFE_CYCLE_NAME = 'CUR';
               ELSE
                  SELECT REFRESH_PART_NUMBER
                    INTO lv_RF_part
                    FROM CRPADM.RC_PRODUCT_MASTER PROD
                   WHERE     PROD.COMMON_PART_NUMBER IN (lv_spare_Part,
                                                         lv_Manufacture_Part)
                         AND program_TYPE = 0;
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  lv_RF_part := '';
            END;



            INSERT INTO WCT_ERROR_LOG
                 VALUES (lv_Manufacture_Part || ' ' || lv_spare_Part,
                         'nrashmi',
                         'before procedure call',
                         SYSDATE);

            COMMIT;*/
            --Commented apart of Validate PID logic <End>

            --Added by satbanda to get the active Part for deactivated Wholesale parts<start>
            --retrieve common part number and refresh life cycle name
--(Start) commented by hkarka as on 20-MAR-2017 for stripped name logic change
/*
        BEGIN
               SELECT common_part_number, refresh_life_cycle_name
                 INTO lv_common_part, lv_refresh_cycle_name
                 FROM crpadm.rc_product_master
                WHERE refresh_part_number = lv_Wholesale_Part;
            EXCEPTION
               WHEN OTHERS
               THEN
                  lv_common_part := NULL;
                  lv_refresh_cycle_name := NULL;
            END;

            --derive active ws pid for the same common part number
            IF lv_refresh_cycle_name = v_deactivated_status
            THEN
               BEGIN
                  SELECT refresh_part_number
                    INTO lv_wholesale_part_nbr
                    FROM crpadm.rc_product_master
                   WHERE     common_part_number = lv_common_part
                         AND NVL (deactivation_date, SYSDATE) >= SYSDATE --should not be deactivated
                         AND program_type = 1;                --wholesale part

                  --AND inventory_item_status_code = 'ENABLE-MAJ'  --commented by hkarka as on 20-NOV-2016
                  --AND refresh_life_cycle_name IN ('CUR', 'EOL', 'EOS');  --commented by hkarka as on 20-NOV-2016

                  lv_wholesale_part := lv_wholesale_part_nbr;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lv_wholesale_part_nbr := lv_wholesale_part;
               END;
            END IF;
            --Added by satbanda to get the active Part for deactivated Wholesale parts<End>
*/
--(End) commented by hkarka as on 20-MAR-2017 for stripped name logic change

        CALCULATE_AVAILABLE_QTY (lv_Manufacture_Part,
                                     lv_spare_Part,
                                     lv_RF_part,
                                     lv_Wholesale_Part,
                                     lv_Region_Local,
                                     lv_Requested_Quantity,
                                     v_Inventory_avbl_List,
                                     v_RF_WS_Inv_Qty_List,
                                     lv_Lead_Time_1,
                                     lv_Lead_Time_2,
                                     lv_Lead_Time_3,
                                     lv_Available_Quantity_1,
                                     lv_Available_Quantity_2,
                                     lv_Available_Quantity_3,
                                     lv_Lead_Time_Count,
                                     lv_WS_present,
                                     lv_negative_ccw_flag);

            -- 5.0.2 Create Inventory Objects


            v_Inventory_Detail_gbl_list :=
               WCT_INVENTORY_GLOBAL_OBJECT (v_RF_WS_Inv_Qty_List,
                                            v_Inventory_avbl_List,
                                            lv_WS_present);


            --            v_Inventory_Detail_gbl_list :=
            --               WCT_INVENTORY_GLOBAL_OBJECT (lv_Reservation_RF_Quotes_Lcl,
            --                                            lv_Reservation_RF_Backlog_Lcl,
            --                                            lv_Reservation_WS_Order_Lcl,
            --                                            lv_Reservation_POE_For_RF_Lcl,
            --                                            lv_Reservation_Total_Lcl,
            --                                            lv_Reservation_Total_RF_Lcl,
            --                                            lv_Reservation_Total_WS_Lcl,
            --                                            lv_Available_RF_Lcl,
            --                                            lv_Available_WS_Lcl,
            --                                            lv_Available_POE_Lcl,
            --                                            v_Inventory_Detail_List_Local);

            --            v_Inventory_Detail_Foreign :=
            --               WCT_INVENTORY_REGION_OBJECT (lv_Reservation_RF_Quotes_Frn,
            --                                            lv_Reservation_RF_Backlog_Frn,
            --                                            lv_Reservation_WS_Order_Frn,
            --                                            lv_Reservation_POE_For_RF_Frn,
            --                                            lv_Reservation_Total_Frn,
            --                                            lv_Reservation_Total_RF_Frn,
            --                                            lv_Reservation_Total_WS_Frn,
            --                                            lv_Available_RF_Frn,
            --                                            lv_Available_WS_Frn,
            --                                            lv_Available_POE_Frn,
            --                                            v_Inventory_Detail_List_Frn);

            --6.0 Fetch Sales history details
            --6.1 Fetch sales history list
            BEGIN

                --(Start) added by hkarka as on 20-MAR-2017 for stripped name logic change
        SELECT WCT_SALES_HISTORY_OBJECT (BASE_UNIT_PRICE,
                         SALES_ORDER_DATE,
                         CUSTOMER_NAME,
                         QUANTITY_ORDERED)
          BULK COLLECT INTO v_Sales_History_List
          FROM (SELECT main.sales_order_number,
                   main.BASE_UNIT_PRICE,
                   main.SALES_ORDER_DATE,
                   main.CUSTOMER_NAME,
                   main.QUANTITY_ORDERED,
                   ROW_NUMBER () OVER (ORDER BY SALES_ORDER_DATE DESC) RNO
              FROM (  SELECT subqry1.sales_ordeR_number,
                     subqry1.net_price base_unit_price,
                     subqry1.order_created_date sales_order_date,
                     subqry1.customer_name,
                     SUM (quantity_requested) quantity_ordered
                    FROM (SELECT DISTINCT ssot.sales_ordeR_number,
                              ssot.sales_order_line_number,
                              ssot.net_price,
                              ssot.order_created_date,
                              ssot.customer_name,
                              ssot.product_id,
                              ssot.quantity_requested
                        FROM rmktgadm.rmk_ssot_transactions ssot
                       WHERE     order_type = 'EXCESS'
                               AND ssot.web_order_status NOT IN ('UNSUBMITTED',
                                                  'CANCELLED')
                             AND ssot.so_line_status NOT IN ('CANCELLED')
                         AND ssot.sales_order_number IS NOT NULL
                         --Added for US151907 <Start>
                         AND ssot.web_order_id NOT IN (SELECT TO_CHAR(ccw_weborder_id)
                                                         FROM rcec_order_headers roh,
                                                              rcec_order_lines rol,
                                                              wct_quote_line wql
                                                        WHERE wql.promo_flag= v_Flag_Yes
                                                          AND wql.line_id=rol.quote_line_id
                                                          AND rol.wholesale_part_number = lv_Wholesale_Part
                                                          AND roh.excess_order_id=rol.excess_order_id
                                                        )
                         --Added for US151907 <End>
                         AND ssot.sales_order_line_number IS NOT NULL
                         AND ssot.order_created_date >
                            ADD_MONTHS (SYSDATE, -6)
                         AND product_id = lv_Wholesale_Part) subqry1
                GROUP BY subqry1.sales_ordeR_number,
                     subqry1.net_price,
                     subqry1.order_created_date,
                     subqry1.customer_name) main)
         WHERE RNO <= 5;
                --(End) added by hkarka as on 20-MAR-2017 for stripped name logic change

               --(Start) commented by hkarka as on 20-MAR-2017 for stripped name logic change
           /*
           IF (lv_Conflicting_Part_Count > 1)
               THEN
                  --(Start) commented by hkarka as on 20-NOV-2016 for retrieve Sales history from new process as well
                  *//*
                  SELECT WCT_SALES_HISTORY_OBJECT (BASE_UNIT_PRICE,
                                                                 SALES_ORDER_DATE,
                                                                 CUSTOMER_NAME,
                                                                 QUANTITY_ORDERED)
                                  BULK COLLECT INTO v_Sales_History_List
                                  FROM (SELECT WSPR.BASE_UNIT_PRICE,
                                               WSPR.SALES_ORDER_DATE,
                                               WSPR.CUSTOMER_NAME,
                                               WSPR.QUANTITY_ORDERED,
                                               ROW_NUMBER ()
                                                  OVER (ORDER BY SALES_ORDER_DATE DESC)
                                                  RNO
                                          FROM RMKTGADM.RMK_WS_AR_BACKLOG_SHIPMENT WSPR
                                         WHERE     1 = 1
                                               AND (   WSPR.PRODUCT_ID =
                                                          lv_Conflicting_Part_Id
                                                    OR WSPR.PRODUCT_ID =
                                                          lv_Conflicting_Part_WS)
                                               AND SALES_ORDER_DATE >
                                                      ADD_MONTHS (SYSDATE, -6))
                                 WHERE RNO <= 5;
                                *//*
                  --(End) commented by hkarka as on 20-NOV-2016 for retrieve Sales history from new process as well
                  --(Start) Added by hkarka as on 20-NOV-2016 for retrieve Sales history from new process as well
                  SELECT WCT_SALES_HISTORY_OBJECT (BASE_UNIT_PRICE,
                                                   SALES_ORDER_DATE,
                                                   CUSTOMER_NAME,
                                                   QUANTITY_ORDERED)
                    BULK COLLECT INTO v_Sales_History_List
                    FROM (SELECT main.sales_order_number,
                                 main.BASE_UNIT_PRICE,
                                 main.SALES_ORDER_DATE,
                                 main.CUSTOMER_NAME,
                                 main.QUANTITY_ORDERED,
                                 ROW_NUMBER ()
                                    OVER (ORDER BY SALES_ORDER_DATE DESC)
                                    RNO
                            FROM (SELECT wspr.sales_order_number,
                                         WSPR.BASE_UNIT_PRICE,
                                         WSPR.SALES_ORDER_DATE,
                                         WSPR.CUSTOMER_NAME,
                                         WSPR.QUANTITY_ORDERED
                                    FROM RMKTGADM.RMK_WS_AR_BACKLOG_SHIPMENT WSPR
                                   WHERE     1 = 1
                                         AND (   WSPR.PRODUCT_ID =
                                                    lv_Conflicting_Part_Id
                                              OR WSPR.PRODUCT_ID =
                                                    lv_Conflicting_Part_WS)
                                         AND WSPR.SALES_ORDER_DATE >
                                                ADD_MONTHS (SYSDATE, -6)
                                  UNION
                                  (  SELECT subqry1.sales_ordeR_number,
                                            subqry1.net_price base_unit_price,
                                            subqry1.order_created_date
                                               sales_order_date,
                                            subqry1.customer_name,
                                            --subqry1.product_id,
                                            SUM (quantity_requested)
                                               quantity_ordered
                                       FROM (SELECT DISTINCT
                                                    ssot.sales_ordeR_number,
                                                    ssot.sales_order_line_number,
                                                    ssot.net_price,
                                                    ssot.order_created_date,
                                                    ssot.customer_name,
                                                    ssot.product_id,
                                                    ssot.quantity_requested
                                               FROM rmktgadm.rmk_ssot_transactions ssot
                                              WHERE     order_type = 'EXCESS'
                                                    AND ssot.sales_order_number
                                                           IS NOT NULL
                                                    AND ssot.sales_order_line_number
                                                           IS NOT NULL
                                                    AND ssot.order_created_date >
                                                           ADD_MONTHS (SYSDATE,
                                                                       -6)
                                                    AND product_id =
                                                           lv_conflicting_part_ws)
                                            subqry1
                                   GROUP BY subqry1.sales_ordeR_number,
                                            subqry1.net_price,
                                            subqry1.order_created_date,
                                            subqry1.customer_name)) main)
                   WHERE RNO <= 5;
               --(End) Added by hkarka as on 20-NOV-2016 for retrieve Sales history from new process as well
               ELSE
                  --(Start) commented by hkarka as on 20-NOV-2016 for retrieve Sales history from new process as well
                  /*
    SELECT WCT_SALES_HISTORY_OBJECT (BASE_UNIT_PRICE,
                                                   SALES_ORDER_DATE,
                                                   CUSTOMER_NAME,
                                                   QUANTITY_ORDERED)
                    BULK COLLECT INTO v_Sales_History_List
                    FROM (SELECT WSPR.BASE_UNIT_PRICE,
                                 WSPR.SALES_ORDER_DATE,
                                 WSPR.CUSTOMER_NAME,
                                 WSPR.QUANTITY_ORDERED,
                                 ROW_NUMBER ()
                                    OVER (ORDER BY SALES_ORDER_DATE DESC)
                                    RNO
                            FROM RMKTGADM.RMK_WS_AR_BACKLOG_SHIPMENT WSPR
                           WHERE     1 = 1
                                 AND (   WSPR.PRODUCT_NAME_STRIPPED =
                                            lv_Product_Name_Stripped
                                      OR WSPR.PRODUCT_NAME_STRIPPED =
                                            lv_Product_Name_Stripped_WS)
                                 AND SALES_ORDER_DATE >
                                        ADD_MONTHS (SYSDATE, -6))
                   WHERE RNO <= 5;
     *//*
                  --(End) commented by hkarka as on 20-NOV-2016 for retrieve Sales history from new process as well
                  --(Start) added by hkarka as on 20-NOV-2016 for retrieve Sales history from new process as well
                  SELECT WCT_SALES_HISTORY_OBJECT (BASE_UNIT_PRICE,
                                                   SALES_ORDER_DATE,
                                                   CUSTOMER_NAME,
                                                   QUANTITY_ORDERED)
                    BULK COLLECT INTO v_Sales_History_List
                    FROM (SELECT main.sales_order_number,
                                 main.BASE_UNIT_PRICE,
                                 main.SALES_ORDER_DATE,
                                 main.CUSTOMER_NAME,
                                 main.QUANTITY_ORDERED,
                                 ROW_NUMBER ()
                                    OVER (ORDER BY SALES_ORDER_DATE DESC)
                                    RNO
                            FROM (SELECT wspr.sales_order_number,
                                         WSPR.BASE_UNIT_PRICE,
                                         WSPR.SALES_ORDER_DATE,
                                         WSPR.CUSTOMER_NAME,
                                         WSPR.QUANTITY_ORDERED
                                    FROM RMKTGADM.RMK_WS_AR_BACKLOG_SHIPMENT WSPR
                                   WHERE     1 = 1
                                         AND (   WSPR.PRODUCT_NAME_STRIPPED =
                                                    lv_Product_Name_Stripped
                                              OR WSPR.PRODUCT_NAME_STRIPPED =
                                                    lv_Product_Name_Stripped_WS)
                                         AND WSPR.SALES_ORDER_DATE >
                                                ADD_MONTHS (SYSDATE, -6)
                                  UNION
                                  (  SELECT subqry1.sales_ordeR_number,
                                            subqry1.net_price base_unit_price,
                                            subqry1.order_created_date
                                               sales_order_date,
                                            subqry1.customer_name,
                                            --subqry1.product_id,
                                            SUM (quantity_requested)
                                               quantity_ordered
                                       FROM (SELECT DISTINCT
                                                    ssot.sales_ordeR_number,
                                                    ssot.sales_order_line_number,
                                                    ssot.net_price,
                                                    ssot.order_created_date,
                                                    ssot.customer_name,
                                                    ssot.product_id,
                                                    ssot.quantity_requested
                                               FROM rmktgadm.rmk_ssot_transactions ssot
                                              WHERE     order_type = 'EXCESS'
                                                    AND ssot.sales_order_number
                                                           IS NOT NULL
                                                    AND ssot.sales_order_line_number
                                                           IS NOT NULL
                                                    AND ssot.order_created_date >
                                                           ADD_MONTHS (SYSDATE,
                                                                       -6)
                                                    AND product_id =
                                                           lv_Wholesale_Part)
                                            subqry1
                                   GROUP BY subqry1.sales_ordeR_number,
                                            subqry1.net_price,
                                            subqry1.order_created_date,
                                            subqry1.customer_name)) main)
                   WHERE RNO <= 5;
               --(End) added by hkarka as on 20-NOV-2016 for retrieve Sales history from new process as well

               END IF;
            */
            --(End) commented by hkarka as on 20-MAR-2017 for stripped name logic change

        EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  --LOG EXCEPTION
                  INSERT INTO WCT_ERROR_LOG
                       VALUES (UPPER (lv_Requested_Part),
                               lv_User_Id,
                               'Data_extract - Step 6.1 - No data found',
                               SYSDATE);
               WHEN OTHERS
               THEN
                  --LOG EXCEPTION
                  v_Error_Message := NULL;
                  v_Error_Message := SUBSTR (SQLERRM, 1, 200);

                  INSERT INTO WCT_ERROR_LOG
                          VALUES (
                                    UPPER (lv_Requested_Part),
                                    lv_User_Id,
                                       'Data_extract - Step 6.1 - '
                                    || v_Error_Message,
                                    SYSDATE);
            END;

            --6.2 fetch last sold price to the customer
            BEGIN

               --(Start) added by hkarka as on 20-MAR-2017 for stripped name logic change
        SELECT WCT_SALES_HISTORY_OBJECT (base_unit_price,
                         sales_order_date,
                         customer_name,
                         quantity_ordered)
          INTO v_Recent_Sales_Object
          FROM (  SELECT net_price base_unit_price,
                 order_created_date sales_order_date,
                 customer_name,
                 SUM (quantity_requested) quantity_ordered
                FROM (SELECT DISTINCT ssot.sales_ordeR_number,
                          ssot.sales_order_line_number,
                          ssot.net_price,
                          ssot.order_created_date,
                          ssot.customer_name,
                          ssot.product_id,
                          ssot.quantity_requested
                    FROM rmktgadm.rmk_ssot_transactions ssot,
                     wct_company_master company,
                     wct_customer customer
                   WHERE     ssot.order_type = 'EXCESS'
                     AND ssot.web_order_status NOT IN ('UNSUBMITTED',
                                       'CANCELLED')
                     AND ssot.so_line_status NOT IN ('CANCELLED')
                     AND ssot.sales_order_number IS NOT NULL
                         AND ssot.sales_order_line_number IS NOT NULL
                     AND ssot.customer_id = company.cg1_customer_id
                     AND company.company_id = customer.company_id
                     AND customer.customer_id = lv_customer_id
                     AND ssot.product_id = lv_Wholesale_Part
                      --Added for US151907 <Start>
                     AND ssot.web_order_id NOT IN (SELECT TO_CHAR(ccw_weborder_id)
                                                     FROM rcec_order_headers roh,
                                                          rcec_order_lines rol,
                                                          wct_quote_line wql
                                                    WHERE wql.promo_flag= v_Flag_Yes
                                                      AND wql.line_id=rol.quote_line_id
                                                      AND rol.wholesale_part_number = lv_Wholesale_Part
                                                      AND roh.excess_order_id=rol.excess_order_id
                                                    )
                     --Added for US151907 <End>
                     )
            GROUP BY net_price, order_created_date, customer_name
            ORDER BY sales_order_date DESC)
         WHERE ROWNUM = 1;

               --(End) added by hkarka as on 20-MAR-2017 for stripped name logic change

               --(Start) commented by hkarka as on 20-MAR-2017 for stripped name logic change
           /*
           IF (lv_Conflicting_Part_Count > 1)
               THEN
                    SELECT WCT_SALES_HISTORY_OBJECT (WSPR.BASE_UNIT_PRICE,
                                                     WSPR.SALES_ORDER_DATE,
                                                     WSPR.CUSTOMER_NAME,
                                                     WSPR.QUANTITY_ORDERED)
                      INTO v_Recent_Sales_Object
                      FROM RMKTGADM.RMK_WS_AR_BACKLOG_SHIPMENT WSPR
                     WHERE     1 = 1
                           AND (   WSPR.PRODUCT_ID = lv_Conflicting_Part_Id
                                OR WSPR.PRODUCT_ID = lv_Conflicting_Part_WS)
                           AND UPPER (WSPR.CUSTOMER_NAME) =
                                  (SELECT UPPER (CM.COMPANY_NAME)
                                     FROM WCT_COMPANY_MASTER CM,
                                          WCT_CUSTOMER CUST
                                    WHERE     1 = 1
                                          AND CM.COMPANY_ID = CUST.COMPANY_ID
                                          AND CUST.CUSTOMER_ID = lv_Customer_Id)
                           AND ROWNUM <= 1
                  ORDER BY SALES_ORDER_DATE DESC;
               ELSE
                    SELECT WCT_SALES_HISTORY_OBJECT (WSPR.BASE_UNIT_PRICE,
                                                     WSPR.SALES_ORDER_DATE,
                                                     WSPR.CUSTOMER_NAME,
                                                     WSPR.QUANTITY_ORDERED)
                      INTO v_Recent_Sales_Object
                      FROM RMKTGADM.RMK_WS_AR_BACKLOG_SHIPMENT WSPR
                     WHERE     1 = 1
                           AND (   WSPR.PRODUCT_NAME_STRIPPED =
                                      lv_Product_Name_Stripped
                                OR WSPR.PRODUCT_NAME_STRIPPED =
                                      lv_Product_Name_Stripped_WS)
                           AND UPPER (WSPR.CUSTOMER_NAME) =
                                  (SELECT UPPER (CM.COMPANY_NAME)
                                     FROM WCT_COMPANY_MASTER CM,
                                          WCT_CUSTOMER CUST
                                    WHERE     1 = 1
                                          AND CM.COMPANY_ID = CUST.COMPANY_ID
                                          AND CUST.CUSTOMER_ID = lv_Customer_Id)
                           AND ROWNUM <= 1
                  ORDER BY SALES_ORDER_DATE DESC;
               END IF;
           */
               --(End) commented by hkarka as on 20-MAR-2017 for stripped name logic change
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_Recent_Sales_Object :=
                     WCT_SALES_HISTORY_OBJECT (0,
                                               SYSDATE,
                                               'NO_DATA',
                                               0);

                  --LOG EXCEPTION
                  INSERT INTO WCT_ERROR_LOG
                       VALUES (UPPER (lv_Requested_Part),
                               lv_User_Id,
                               'Data_extract - Step 6.2 - No data found',
                               SYSDATE);
               WHEN OTHERS
               THEN
                  v_Recent_Sales_Object :=
                     WCT_SALES_HISTORY_OBJECT (0,
                                               SYSDATE,
                                               'NO_DATA',
                                               0);
                  --LOG EXCEPTION
                  v_Error_Message := NULL;
                  v_Error_Message := SUBSTR (SQLERRM, 1, 200);

                  INSERT INTO WCT_ERROR_LOG
                          VALUES (
                                    UPPER (lv_Requested_Part),
                                    lv_User_Id,
                                       'Data_extract - Step 6.2 - '
                                    || v_Error_Message,
                                    SYSDATE);
            END;

            --7.0 Compute Suggested Price using Pricing Engine
            BEGIN
               --7.1.1 Fetch recent high price
               lv_Recent_Price := 0.00;

               IF v_Sales_History_List.COUNT () > 0
               THEN
                  lv_Recent_Price := v_Sales_History_List (1).PRICE;
               ELSIF (v_Recent_Sales_Object.CUSTOMER_NAME <> 'NO_DATA')
               THEN
                  lv_Recent_Price := v_Recent_Sales_Object.PRICE;
               END IF;

               --7.1.2 determine discount based on EOS date
               BEGIN
                  IF (lv_Eos_Date <= TRUNC (lv_Eos_Over_Date))
                  THEN
                     lv_Base_Price_Discount := lv_Base_Discount_Eos_Over;
                  ELSIF (lv_Eos_Date <= TRUNC (SYSDATE))
                  THEN
                     lv_Base_Price_Discount := lv_Base_Discount_Eos;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     --LOG EXCEPTION
                     v_Error_Message := NULL;
                     v_Error_Message := SUBSTR (SQLERRM, 1, 200);

                     INSERT INTO WCT_ERROR_LOG
                             VALUES (
                                       UPPER (lv_Requested_Part),
                                       lv_User_Id,
                                          'Data_extract - Step 7.1.2 - '
                                       || v_Error_Message,
                                       SYSDATE);
               END;

               --7.1.3 Compute base price, suggested price, ext sell price, and updated base price discount
                --Commented by satbanda on 20-Mar-2017 for validate PID logic <Start>
                              /*
               PRICING_ENGINE (lv_Broker_Offer_Missing_Flag,
                               lv_Recent_Price,
                               NVL (lv_Broker_Offer, 0.00),
                               lv_Available_Quantity_1,
                               lv_Requested_Quantity,
                               lv_Base_Price_Discount,
                               lv_Glp,
                               lv_Round_Scale,
                               lv_Requested_Part,
                               lv_Product_Name_Stripped,
                               lv_Product_Name_Stripped_WS,
                               lv_Customer_Id,
                               lv_Region_Local,
                               lv_Conflicting_Part_Count,
                               lv_Conflicting_Part_Id,
                               lv_Conflicting_Part_WS,
                               lv_Base_Price,
                               lv_Suggested_Price_New,
                               lv_Ext_Sell_Price_1,
                               lv_Base_Price_Discount,
                               lv_Static_Price_Exists);*/
                               --Commented by satbanda on 20-Mar-2017 for validate PID logic <End>

                --Added by satbanda on 20-Mar-2017 for Validate PID logic    <Start>
               PRICING_ENGINE (lv_Broker_Offer_Missing_Flag,
                               lv_Recent_Price,
                               NVL (lv_Broker_Offer, 0.00),
                               lv_Available_Quantity_1,
                               lv_Requested_Quantity,
                               lv_Base_Price_Discount,
                               lv_Glp,
                               lv_Round_Scale,
                               lv_Requested_Part,
                               lv_Manufacture_Part,
                               lv_spare_Part,
                               lv_Wholesale_Part,
                               lv_Refurbished_Part,
                               lv_Customer_Id,
                               lv_Region_Local,
                               lv_Base_Price,
                               lv_Suggested_Price_New,
                               lv_Ext_Sell_Price_1,
                               lv_Base_Price_Discount,
                               lv_Static_Price_Exists);
                 --Added by satbanda on 20-Mar-2017 for Validate PID logic    <End>

               -- Start of code changes done by Infosys for April 2014 release--  ravchitt
               -- Code for calculating suggested Price
               -- If new search
               IF (    (i_Search_Type = v_Search_Type_New)
                   AND (lv_Copy_Quote_Customer_Id IS NULL))
               THEN
                  lv_Suggested_Price_Old := lv_Suggested_Price_New;
               -- If edit quote or copy quote with same customer
               ELSIF (   (i_Search_Type = v_Search_Type_Edit)
                      OR (lv_Copy_Quote_Customer_Id = lv_Customer_Id))
               THEN
                  BEGIN
                     SELECT SUGGESTED_PRICE, DISCOUNT
                       INTO lv_Suggested_Price_Old, lv_Base_Price_Discount
                       FROM WCT_QUOTE_LINE
                      WHERE     QUOTE_ID = lv_Old_Quote_Id
                            AND REQUESTED_PART = lv_Requested_Part;

                     IF (lv_Requested_Quantity > lv_Available_Quantity_1)
                     THEN
                        lv_Ext_Sell_Price_1 :=
                           lv_Suggested_Price_Old * lv_Available_Quantity_1;
                     ELSE
                        lv_Ext_Sell_Price_1 :=
                           lv_Suggested_Price_Old * lv_Requested_Quantity;
                     END IF;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        lv_Suggested_Price_Old := lv_Suggested_Price_New;
                  END;
               -- Copy quote with different customer
               ELSE
                  lv_Suggested_Price_Old := lv_Suggested_Price_New;
               -- End Start of code changes done by Infosys for April 2014 release -- ravchitt
               END IF;

               IF (lv_Lead_Time_Count > 1)
               THEN
                  lv_Ext_Sell_Price_2 :=
                       lv_Suggested_Price_Old
                     * LEAST (
                          lv_Available_Quantity_2,
                          (lv_Requested_Quantity - lv_Available_Quantity_1));

                  IF (lv_Lead_Time_Count = 3)
                  THEN
                  --Commented by satbanda on 18th July,2017 for US121008 (Extended Net Price not showing) <Start>
                    /* lv_Ext_Sell_Price_3 :=
                          lv_Suggested_Price_Old
                        * LEAST (
                             lv_Available_Quantity_3,
                             (lv_Requested_Quantity - lv_Available_Quantity_2));*/
                    --Commented by satbanda on 18th July,2017 for US121008 (Extended Net Price not showing) <End>

                    --Added by satbanda on 18th July,2017 for US121008 (Extended Net Price not showing) <Start>
                     lv_Ext_Sell_Price_3 :=
                          lv_Suggested_Price_Old
                        * LEAST (
                             lv_Available_Quantity_3,
                             (lv_Requested_Quantity - lv_Available_Quantity_2 -  lv_Available_Quantity_1));
                  --Added by satbanda on 18th July,2017 for US121008 (Extended Net Price not showing) <End>

                  END IF;
               END IF;

               --7.1.4 Update Deal Value
               lv_Deal_Value :=
                    lv_Deal_Value
                  + lv_Ext_Sell_Price_1
                  + lv_Ext_Sell_Price_2
                  + lv_Ext_Sell_Price_3;
            EXCEPTION
               WHEN OTHERS
               THEN
                  --LOG EXCEPTION
                  v_Error_Message := NULL;
                  v_Error_Message := SUBSTR (SQLERRM, 1, 200);

                  INSERT INTO WCT_ERROR_LOG
                          VALUES (
                                    UPPER (lv_Requested_Part),
                                    lv_User_Id,
                                       'Data_extract - Step 7.0 - '
                                    || v_Error_Message,
                                    SYSDATE);
            END;

            --8.0 Get N value based on EOS date
            CASE
               WHEN lv_Eos_Date <= TRUNC (lv_Eos_Over_Date)
               THEN
                  lv_N_Value := 'N - 2';
               WHEN lv_Eos_Date <= TRUNC (SYSDATE)
               THEN
                  lv_N_Value := 'N - 1';
               ELSE
                  lv_N_Value := 'N';
            END CASE;

            --Code moved to PRICING ENGINE

            --9.0 Generate Unique Quote ID and Save each line in a Collection
            BEGIN
               v_Search_Data_Object :=
                  WCT_SEARCH_DATA_MODIFY_OBJECT (lv_Line_No,
                                                 lv_Requested_Part,
                                                 lv_Manufacture_Part,
                                                 lv_Refurbished_Part,
                                                 lv_Wholesale_Part,
                                                 lv_Encryption_Status,
                                                 --lv_Available_Quantity,
                                                 lv_Available_Quantity_1,
                                                 lv_Requested_Quantity,
                                                 lv_Broker_Offer,
                                                 lv_Glp,
                                                 lv_Base_Price,
                                                 lv_Suggested_Price_Old,
                                                 lv_Suggested_Price_New,
                                                 --lv_Ext_Sell_Price,
                                                 lv_Ext_Sell_Price_1,
                                                 lv_Base_Price_Discount,
                                                 --lv_Lead_Time,
                                                 lv_Lead_Time_1,
                                                 lv_Eos_Date,
                                                 lv_Static_Price_Exists,
                                                 --lv_Inventory_Detail_Note,
                                                 lv_Inventory_Detail_Notes_1,
                                                 lv_Row_Id,
                                                 lv_Recent_Price,
                                                 v_Recent_Sales_Object,
                                                 v_Sales_History_List,
                                                 v_Recent_Quotes_List,
                                                 v_Inventory_Detail_gbl_list,
                                                 lv_N_Value,
                                                 lv_negative_ccw_flag,
                                                 lv_promo_flag --Added for US151907
                                                 );
               v_Out_Search_Data_List.EXTEND;
               v_Out_Search_Data_List (lv_index) := v_Search_Data_Object;
               lv_index := lv_index + 1;


               IF (lv_Lead_Time_Count > 1)
               THEN
                  lv_Row_Id := lv_Row_Id + 1;
                  v_Search_Data_Object :=
                     WCT_SEARCH_DATA_MODIFY_OBJECT (
                        lv_Line_No,
                        lv_Requested_Part,
                        lv_Manufacture_Part,
                        lv_Refurbished_Part,
                        lv_Wholesale_Part,
                        lv_Encryption_Status,
                        --lv_Available_Quantity,
                        lv_Available_Quantity_2,
                        lv_Requested_Quantity,
                        lv_Broker_Offer,
                        lv_Glp,
                        lv_Base_Price,
                        lv_Suggested_Price_Old,
                        lv_Suggested_Price_New,
                        --lv_Ext_Sell_Price,
                        lv_Ext_Sell_Price_2,
                        lv_Base_Price_Discount,
                        lv_Lead_Time_2,
                        lv_Eos_Date,
                        lv_Static_Price_Exists,
                        --lv_Inventory_Detail_Note,
                        lv_Inventory_Detail_Notes_2,
                        lv_Row_Id,
                        lv_Recent_Price,
                        v_Recent_Sales_Object,
                        v_Sales_History_List,
                        v_Recent_Quotes_List,
                        v_Inventory_Detail_gbl_list,
                        lv_N_Value,
                        lv_negative_ccw_flag,
                        lv_promo_flag --Added for US151907
                        );
                  v_Out_Search_Data_List.EXTEND;
                  v_Out_Search_Data_List (lv_index) := v_Search_Data_Object;
                  lv_index := lv_index + 1;

                  IF lv_Lead_Time_Count = 3
                  THEN
                     lv_Row_Id := lv_Row_Id + 1;
                     v_Search_Data_Object :=
                        WCT_SEARCH_DATA_MODIFY_OBJECT (
                           lv_Line_No,
                           lv_Requested_Part,
                           lv_Manufacture_Part,
                           lv_Refurbished_Part,
                           lv_Wholesale_Part,
                           lv_Encryption_Status,
                           --lv_Available_Quantity,
                           lv_Available_Quantity_3,
                           lv_Requested_Quantity,
                           lv_Broker_Offer,
                           lv_Glp,
                           lv_Base_Price,
                           lv_Suggested_Price_Old,
                           lv_Suggested_Price_New,
                           --lv_Ext_Sell_Price,
                           lv_Ext_Sell_Price_3,
                           lv_Base_Price_Discount,
                           lv_Lead_Time_3,
                           lv_Eos_Date,
                           lv_Static_Price_Exists,
                           --lv_Inventory_Detail_Note,
                           lv_Inventory_Detail_Notes_3,
                           lv_Row_Id,
                           lv_Recent_Price,
                           v_Recent_Sales_Object,
                           v_Sales_History_List,
                           v_Recent_Quotes_List,
                           v_Inventory_Detail_gbl_list,
                           lv_N_Value,
                           lv_negative_ccw_flag,
                           lv_promo_flag --Added for US151907
                           );
                     v_Out_Search_Data_List.EXTEND;
                     v_Out_Search_Data_List (lv_index) := v_Search_Data_Object;
                     lv_index := lv_index + 1;
                  END IF;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  --LOG EXCEPTION
                  v_Error_Message := NULL;
                  v_Error_Message := SUBSTR (SQLERRM, 1, 200);

                  INSERT INTO WCT_ERROR_LOG
                          VALUES (
                                    UPPER (lv_Requested_Part),
                                    lv_User_Id,
                                       'Data_extract - Step 9.0 - '
                                    || v_Error_Message,
                                    SYSDATE);
            END;
         END IF;

         --Reset system discount to defaultr
         lv_Base_Price_Discount := lv_Base_Discount_Default;
      END LOOP;

      --insert into nar(seq) values(100);

      -- If valid rows present, only then update the header and line table
      IF (v_Out_Search_Data_List.COUNT () > 0)
      THEN
         --insert into nar(seq) values(200);
         --10.0 Create Header entry for the quote
         BEGIN
            IF (i_Search_Type = v_Search_Type_New)
            THEN
               --insert into nar(seq) values(300);
               lv_Quote_Id := GENERATE_QUOTE_ID (v_Quote_Id_Type_Dummy);

               --insert into nar(seq) values(400);
               BEGIN
                  INSERT INTO WCT_QUOTE_HEADER (QUOTE_ID,
                                                CUSTOMER_ID,
                                                CREATED_DATE,
                                                CREATED_BY,
                                                LAST_UPDATED_DATE,
                                                LAST_UPDATED_BY,
                                                DEAL_VALUE,
                                                STATUS)
                       VALUES (lv_Quote_Id,
                               lv_Customer_Id,
                               lv_Date,
                               lv_User_Id,
                               lv_Date,
                               lv_User_Id,
                               lv_Deal_Value,
                               v_Status_New);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_sqerrm := SUBSTR (SQLERRM, 1, 500);
               --insert into nar(seq,issue) values(500,'lv_Quote_Id=> '||lv_Quote_Id||' <> '||l_sqerrm);
               END;
            --insert into nar(seq,quote_id, issue) values(2,'Data Extract=> '|| lv_Quote_Id,lv_Customer_Id||' lv_Customer_Id$lv_Date '||lv_Date ); commit;
            ELSE
               -- if search was edit quote
               lv_Quote_Id := i_Quote_Id;

               -- Add new entry in the audit header table
               DECLARE
                  lv_audit_header_quote_id        VARCHAR2 (10 BYTE);
                  lv_audit_header_customer_id     NUMBER;
                  lv_audit_header_created_date    DATE;
                  lv_audit_header_created_by      VARCHAR2 (12 BYTE);
                  lv_aud_head_last_updated_date   DATE;
                  lv_aud_head_last_updated_by     VARCHAR2 (12 BYTE);
                  lv_audit_header_deal_value      NUMBER (15, 2);
                  lv_audit_header_status          VARCHAR2 (10 BYTE);
               BEGIN
                  SELECT QUOTE_ID,
                         CUSTOMER_ID,
                         CREATED_DATE,
                         CREATED_BY,
                         LAST_UPDATED_DATE,
                         LAST_UPDATED_BY,
                         DEAL_VALUE,
                         STATUS
                    INTO lv_audit_header_quote_id,
                         lv_audit_header_customer_id,
                         lv_audit_header_created_date,
                         lv_audit_header_created_by,
                         lv_aud_head_last_updated_date,
                         lv_aud_head_last_updated_by,
                         lv_audit_header_deal_value,
                         lv_audit_header_status
                    FROM WCT_QUOTE_HEADER
                   WHERE QUOTE_ID = lv_Quote_Id;

                  INSERT INTO WCT_QUOTE_HEADER_AUDIT (AUDIT_HEADER_ID,
                                                      QUOTE_ID,
                                                      CUSTOMER_ID,
                                                      CREATED_DATE,
                                                      CREATED_BY,
                                                      LAST_UPDATED_DATE,
                                                      LAST_UPDATED_BY,
                                                      DEAL_VALUE,
                                                      STATUS)
                       VALUES (WCT_AUDIT_HEADER_ID.NEXTVAL,
                               lv_audit_header_quote_id,
                               lv_audit_header_customer_id,
                               lv_audit_header_created_date,
                               lv_audit_header_created_by,
                               lv_aud_head_last_updated_date,
                               lv_aud_head_last_updated_by,
                               lv_audit_header_deal_value,
                               lv_audit_header_status);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     --LOG EXCEPTION
                     v_Error_Message := NULL;
                     v_Error_Message := SUBSTR (SQLERRM, 1, 200);

                     INSERT INTO WCT_ERROR_LOG
                          VALUES ('INSERTING INTO AUDIT HEADER-1',
                                  lv_User_Id,
                                  'EDIT_QUOTE - ' || v_Error_Message,
                                  SYSDATE);
               END;

               --insert into nar(seq,quote_id, issue) values(10,'Data Extract=> '||lv_Quote_Id||' quotes '||lv_Old_Quote_Id,' lv_User_Id '||lv_User_Id ); commit;
               -- Update quote header table
               UPDATE WCT_QUOTE_HEADER
                  SET LAST_UPDATED_DATE = SYSDATE,
                      LAST_UPDATED_BY = lv_User_Id,
                      DEAL_VALUE = lv_Deal_Value
                WHERE QUOTE_ID = lv_Quote_Id;
            --insert into nar(seq,quote_id, issue) values(11,'Data Extract=> '||lv_Quote_Id||' quotes '||lv_Old_Quote_Id,' lv_User_Id '||lv_User_Id ); commit;


            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               --LOG EXCEPTION
               v_Error_Message := NULL;
               v_Error_Message := SUBSTR (SQLERRM, 1, 200);

               INSERT INTO WCT_ERROR_LOG
                    VALUES (UPPER (lv_Requested_Part),
                            lv_User_Id,
                            'Data_extract - Step 10.0 - ' || v_Error_Message,
                            SYSDATE);
         END;

         --11.0 Bulk Insert/Update Collection to Line

         BEGIN
            IF (i_Search_Type = v_Search_Type_New)
            THEN
               FOR idx IN 1 .. v_Out_Search_Data_List.COUNT ()
               LOOP
                  -- Start of code changes done by Infosys for April 2014 release -- ruchhabr
                  lv_Row_Id := v_Out_Search_Data_List (idx).ROW_ID;

                  IF (lv_Row_Id = 1)
                  THEN
                     lv_Lead_Time_Id := WCT_LEAD_TIME_ID_SEQ.NEXTVAL;
                  END IF;

                  INSERT INTO WCT_LEAD_TIME (LEAD_TIME_ID,
                                             REQUESTED_PART,
                                             REQUESTED_QUANTITY,
                                             AVAILABLE_QUANTITY,
                                             LEAD_TIME,
                                             ROW_ID,
                                             INVENTORY_DETAIL_NOTES,
                                             CREATED_DATE,
                                             CREATED_BY,
                                             LAST_UPDATED_DATE,
                                             LAST_UPDATED_BY)
                          VALUES (
                                    lv_Lead_Time_Id,
                                    v_Out_Search_Data_List (idx).REQUESTED_PART,
                                    v_Out_Search_Data_List (idx).REQUESTED_QUANTITY,
                                    v_Out_Search_Data_List (idx).AVAILABLE_QUANTITY,
                                    TO_CHAR (
                                       v_Out_Search_Data_List (idx).LEAD_TIME),
                                    lv_Row_Id,
                                    v_Out_Search_Data_List (idx).INVENTORY_DETAIL_NOTES,
                                    lv_Date,
                                    lv_User_Id,
                                    lv_Date,
                                    lv_User_Id);

                  IF (lv_Row_Id = 1)
                  THEN
                     lv_Quote_Line_Id := WCT_QUOTE_LINE_ID.NEXTVAL;

                     INSERT INTO WCT_QUOTE_LINE (LINE_ID,
                                                 QUOTE_ID,
                                                 LINE_NO,
                                                 REQUESTED_PART,
                                                 WHOLESALE_PART,
                                                 REQUESTED_QUANTITY,
                                                 AVAILABLE_QUANTITY,
                                                 BROKER_OFFER,
                                                 GLP,
                                                 SUGGESTED_PRICE,
                                                 EXT_SELL_PRICE,
                                                 LEAD_TIME,
                                                 ENCRYPTION_STATUS,
                                                 INVENTORY_DETAIL_NOTES,
                                                 CREATED_DATE,
                                                 CREATED_BY,
                                                 LAST_UPDATED_DATE,
                                                 LAST_UPDATED_BY,
                                                 DISCOUNT,
                                                 EOS_DATE,
                                                 PROMO_FLAG --Added ofr US151907
                                                 )
                             VALUES (
                                       lv_Quote_Line_Id,
                                       lv_Quote_Id,
                                       v_Out_Search_Data_List (idx).LINE_NO,
                                       v_Out_Search_Data_List (idx).REQUESTED_PART,
                                       v_Out_Search_Data_List (idx).WHOLESALE_PART,
                                       v_Out_Search_Data_List (idx).REQUESTED_QUANTITY,
                                       v_Out_Search_Data_List (idx).AVAILABLE_QUANTITY,
                                       v_Out_Search_Data_List (idx).BROKER_OFFER,
                                       v_Out_Search_Data_List (idx).GLP,
                                       v_Out_Search_Data_List (idx).SUGGESTED_PRICE_OLD,
                                       v_Out_Search_Data_List (idx).EXT_SELL_PRICE,
                                       lv_Lead_Time_Id, -- code changes done by Infosys for April 2014 release -- ruchhabr
                                       v_Out_Search_Data_List (idx).ENCRYPTION_STATUS,
                                       v_Out_Search_Data_List (idx).INVENTORY_DETAIL_NOTES,
                                       lv_Date,
                                       lv_User_Id,
                                       lv_Date,
                                       lv_User_Id,
                                       v_Out_Search_Data_List (idx).SYSTEM_DISCOUNT,
                                       v_Out_Search_Data_List (idx).EOS_DATE,
                                       v_Out_Search_Data_List (idx).promo_flag --Added for US151907
                                       );
                  END IF;
               -- End of code changes done by Infosys for April 2014 release -- ruchhabr
               END LOOP;
            ELSE
               -- Search type is Edit Quote

               -- Insert new records in WCT_QUOTE_LINE_TMP table
               FOR idx IN 1 .. v_Out_Search_Data_List.COUNT ()
               LOOP
                  INSERT INTO WCT_QUOTE_LINE_TMP (QUOTE_ID,
                                                  LINE_NO,
                                                  REQUESTED_PART,
                                                  WHOLESALE_PART,
                                                  REQUESTED_QUANTITY,
                                                  AVAILABLE_QUANTITY,
                                                  BROKER_OFFER,
                                                  GLP,
                                                  SUGGESTED_PRICE,
                                                  EXT_SELL_PRICE,
                                                  LEAD_TIME,
                                                  ENCRYPTION_STATUS,
                                                  INVENTORY_DETAIL_NOTES,
                                                  CREATED_DATE,
                                                  CREATED_BY,
                                                  LAST_UPDATED_DATE,
                                                  LAST_UPDATED_BY,
                                                  DISCOUNT,
                                                  EOS_DATE,
                                                  PROMO_FLAG --Added for US151907
                                                  )
                          VALUES (
                                    lv_Quote_Id,
                                    v_Out_Search_Data_List (idx).LINE_NO,
                                    v_Out_Search_Data_List (idx).REQUESTED_PART,
                                    v_Out_Search_Data_List (idx).WHOLESALE_PART,
                                    v_Out_Search_Data_List (idx).REQUESTED_QUANTITY,
                                    v_Out_Search_Data_List (idx).AVAILABLE_QUANTITY,
                                    v_Out_Search_Data_List (idx).BROKER_OFFER,
                                    v_Out_Search_Data_List (idx).GLP,
                                    v_Out_Search_Data_List (idx).SUGGESTED_PRICE_OLD,
                                    v_Out_Search_Data_List (idx).EXT_SELL_PRICE,
                                    v_Out_Search_Data_List (idx).LEAD_TIME,
                                    v_Out_Search_Data_List (idx).ENCRYPTION_STATUS,
                                    v_Out_Search_Data_List (idx).INVENTORY_DETAIL_NOTES,
                                    lv_Date,
                                    lv_User_Id,
                                    lv_Date,
                                    lv_User_Id,
                                    v_Out_Search_Data_List (idx).SYSTEM_DISCOUNT,
                                    v_Out_Search_Data_List (idx).EOS_DATE,
                                    v_Out_Search_Data_List (idx).promo_flag --Added for US151907
                                    );
               END LOOP;

               -- Fetch records from WCT_QUOTE_LINE_TMP to be updated in WCT_QUOTE_LINE
               SELECT EL.LINE_ID,
                      EL.QUOTE_ID,
                      EL.LINE_NO,
                      EL.REQUESTED_PART,
                      EL.WHOLESALE_PART,
                      EL.REFURBISHED_PART,
                      EL.MANUFACTURING_PART,
                      EL.REQUESTED_QUANTITY,
                      EL.AVAILABLE_QUANTITY,
                      EL.BROKER_OFFER,
                      EL.GLP,
                      EL.SUGGESTED_PRICE,
                      EL.EXT_SELL_PRICE,
                      EL.LEAD_TIME,
                      EL.CREATED_DATE,
                      EL.CREATED_BY,
                      EL.LAST_UPDATED_DATE,
                      EL.LAST_UPDATED_BY,
                      EL.ENCRYPTION_STATUS,
                      EL.INVENTORY_DETAIL_NOTES,
                      EL.DISCOUNT,
                      EL.COMMENTS_L1,
                      EL.COMMENTS_L2,
                      EL.EOS_DATE,
                      EL.APPROVAL_LEVEL,
                      EL.APPROVAL_STATUS_L1,
                      EL.APPROVAL_STATUS_L2,
                      EL.PROMO_FLAG -- US151907
                 BULK COLLECT INTO v_Quote_Line_Update_List
                 FROM WCT_QUOTE_LINE_TMP EL, WCT_QUOTE_LINE QL
                WHERE     EL.QUOTE_ID = QL.QUOTE_ID
                      AND EL.REQUESTED_PART = QL.REQUESTED_PART;

               -- add/update rows as per the new quote
               FOR idx IN 1 .. v_Out_Search_Data_List.COUNT ()
               LOOP
                  lv_Row_Id := v_Out_Search_Data_List (idx).ROW_ID;

                  SELECT COUNT (*)
                    INTO lv_Row_Count
                    FROM WCT_QUOTE_LINE
                   WHERE     QUOTE_ID = lv_Quote_Id
                         AND REQUESTED_PART =
                                v_Out_Search_Data_List (idx).REQUESTED_PART;

                  -- if existing row
                  IF (lv_Row_Count > 0)
                  THEN
                     -- fetch existing lead time id from wct_quote_line table
                     SELECT LEAD_TIME
                       INTO lv_Lead_Time_Id
                       FROM WCT_QUOTE_LINE
                      WHERE     QUOTE_ID = lv_Quote_Id
                            AND REQUESTED_PART =
                                   v_Out_Search_Data_List (idx).REQUESTED_PART;

                     -- get existing row count for lead time
                     SELECT COUNT (*)
                       INTO lv_Lead_Time_Row_Count
                       FROM wct_lead_time
                      WHERE lead_time_id = lv_Lead_Time_Id;

                     IF (lv_Row_Id = 1)
                     THEN
                        lv_Available_Quantity_1 :=
                           v_Out_Search_Data_List (idx).AVAILABLE_QUANTITY;

                        -- check if current scenario has 2 rows
                        IF (    (idx < v_Out_Search_Data_List.COUNT)
                            AND (v_Out_Search_Data_List (idx + 1).ROW_ID = 2)
                            AND (v_Out_Search_Data_List (idx).REQUESTED_PART =
                                    v_Out_Search_Data_List (idx + 1).REQUESTED_PART))
                        THEN
                           lv_Available_Quantity_2 :=
                              v_Out_Search_Data_List (idx + 1).AVAILABLE_QUANTITY;
                        ELSE
                           lv_Available_Quantity_2 := 0;
                        END IF;

                        -- update wct_quote_line
                        UPDATE WCT_QUOTE_LINE
                           SET REQUESTED_QUANTITY =
                                  v_Out_Search_Data_List (idx).REQUESTED_QUANTITY,
                               AVAILABLE_QUANTITY =
                                    lv_Available_Quantity_1
                                  + lv_Available_Quantity_2,
                               BROKER_OFFER =
                                  v_Out_Search_Data_List (idx).BROKER_OFFER,
                               GLP = v_Out_Search_Data_List (idx).GLP,
                               SUGGESTED_PRICE =
                                  v_Out_Search_Data_List (idx).SUGGESTED_PRICE_OLD,
                               EXT_SELL_PRICE =
                                  v_Out_Search_Data_List (idx).EXT_SELL_PRICE,
                               PROMO_FLAG = v_Out_Search_Data_List (idx).promo_flag, --Added for US151907
                               LAST_UPDATED_DATE = lv_Date,
                               LAST_UPDATED_BY = lv_User_Id
                         WHERE     QUOTE_ID = lv_Quote_Id
                               AND REQUESTED_PART =
                                      v_Out_Search_Data_List (idx).REQUESTED_PART;

                        -- update first row
                        UPDATE WCT_LEAD_TIME
                           SET LEAD_TIME =
                                  v_Out_Search_Data_List (idx).LEAD_TIME,
                               REQUESTED_QUANTITY =
                                  v_Out_Search_Data_List (idx).REQUESTED_QUANTITY,
                               AVAILABLE_QUANTITY =
                                  v_Out_Search_Data_List (idx).AVAILABLE_QUANTITY
                         WHERE LEAD_TIME_ID = lv_Lead_Time_Id AND ROW_ID = 1;


                        -- check if previously 2 rows and currently also 2 rows
                        IF (    (idx < v_Out_Search_Data_List.COUNT)
                            AND (v_Out_Search_Data_List (idx).REQUESTED_PART =
                                    v_Out_Search_Data_List (idx + 1).REQUESTED_PART))
                        THEN
                           IF (lv_Lead_Time_Row_Count > 1)
                           THEN
                              -- update second row
                              UPDATE WCT_LEAD_TIME
                                 SET LEAD_TIME =
                                        v_Out_Search_Data_List (idx + 1).LEAD_TIME,
                                     REQUESTED_QUANTITY =
                                        v_Out_Search_Data_List (idx + 1).REQUESTED_QUANTITY,
                                     AVAILABLE_QUANTITY =
                                        lv_Available_Quantity_2
                               WHERE     LEAD_TIME_ID = lv_Lead_Time_Id
                                     AND ROW_ID = 2;
                           ELSE
                              -- add second row
                              INSERT
                                INTO WCT_LEAD_TIME (LEAD_TIME_ID,
                                                    REQUESTED_PART,
                                                    REQUESTED_QUANTITY,
                                                    AVAILABLE_QUANTITY,
                                                    LEAD_TIME,
                                                    ROW_ID,
                                                    INVENTORY_DETAIL_NOTES,
                                                    CREATED_DATE,
                                                    CREATED_BY,
                                                    LAST_UPDATED_DATE,
                                                    LAST_UPDATED_BY)
                                 VALUES (
                                           lv_Lead_Time_Id,
                                           v_Out_Search_Data_List (idx + 1).REQUESTED_PART,
                                           v_Out_Search_Data_List (idx + 1).REQUESTED_QUANTITY,
                                           v_Out_Search_Data_List (idx + 1).AVAILABLE_QUANTITY,
                                           TO_CHAR (
                                              v_Out_Search_Data_List (
                                                 idx + 1).LEAD_TIME),
                                           2,
                                           v_Out_Search_Data_List (idx + 1).INVENTORY_DETAIL_NOTES,
                                           lv_Date,
                                           lv_User_Id,
                                           lv_Date,
                                           lv_User_Id);
                           END IF;
                        -- check if previously 2 rows and currently only 1 row
                        ELSIF (lv_Lead_Time_Row_Count > 1)
                        THEN
                           -- delete the second row
                           DELETE FROM WCT_LEAD_TIME
                                 WHERE     LEAD_TIME_ID = lv_Lead_Time_Id
                                       AND ROW_ID = 2;
                        END IF;
                     END IF;
                  -- add new row
                  ELSE
                     IF (lv_Row_Id = 1)
                     THEN
                        lv_Lead_Time_Id := WCT_LEAD_TIME_ID_SEQ.NEXTVAL;

                        lv_Available_Quantity_1 :=
                           v_Out_Search_Data_List (idx).AVAILABLE_QUANTITY;
                        lv_Available_Quantity_2 := 0;


                        INSERT INTO WCT_LEAD_TIME (LEAD_TIME_ID,
                                                   REQUESTED_PART,
                                                   REQUESTED_QUANTITY,
                                                   AVAILABLE_QUANTITY,
                                                   LEAD_TIME,
                                                   ROW_ID,
                                                   INVENTORY_DETAIL_NOTES,
                                                   CREATED_DATE,
                                                   CREATED_BY,
                                                   LAST_UPDATED_DATE,
                                                   LAST_UPDATED_BY)
                                VALUES (
                                          lv_Lead_Time_Id,
                                          v_Out_Search_Data_List (idx).REQUESTED_PART,
                                          v_Out_Search_Data_List (idx).REQUESTED_QUANTITY,
                                          v_Out_Search_Data_List (idx).AVAILABLE_QUANTITY,
                                          TO_CHAR (
                                             v_Out_Search_Data_List (idx).LEAD_TIME),
                                          1,
                                          v_Out_Search_Data_List (idx).INVENTORY_DETAIL_NOTES,
                                          lv_Date,
                                          lv_User_Id,
                                          lv_Date,
                                          lv_User_Id);


                        IF (    (idx < v_Out_Search_Data_List.COUNT)
                            AND (v_Out_Search_Data_List (idx + 1).ROW_ID = 2)
                            AND (v_Out_Search_Data_List (idx).REQUESTED_PART =
                                    v_Out_Search_Data_List (idx + 1).REQUESTED_PART))
                        THEN
                           INSERT INTO WCT_LEAD_TIME (LEAD_TIME_ID,
                                                      REQUESTED_PART,
                                                      REQUESTED_QUANTITY,
                                                      AVAILABLE_QUANTITY,
                                                      LEAD_TIME,
                                                      ROW_ID,
                                                      INVENTORY_DETAIL_NOTES,
                                                      CREATED_DATE,
                                                      CREATED_BY,
                                                      LAST_UPDATED_DATE,
                                                      LAST_UPDATED_BY)
                                   VALUES (
                                             lv_Lead_Time_Id,
                                             v_Out_Search_Data_List (idx + 1).REQUESTED_PART,
                                             v_Out_Search_Data_List (idx + 1).REQUESTED_QUANTITY,
                                             v_Out_Search_Data_List (idx + 1).AVAILABLE_QUANTITY,
                                             TO_CHAR (
                                                v_Out_Search_Data_List (
                                                   idx + 1).LEAD_TIME),
                                             2,
                                             v_Out_Search_Data_List (idx + 1).INVENTORY_DETAIL_NOTES,
                                             lv_Date,
                                             lv_User_Id,
                                             lv_Date,
                                             lv_User_Id);

                           lv_Available_Quantity_2 :=
                              v_Out_Search_Data_List (idx + 1).AVAILABLE_QUANTITY;
                        END IF;

                        lv_Quote_Line_Id := WCT_QUOTE_LINE_ID.NEXTVAL;

                        INSERT INTO WCT_QUOTE_LINE (LINE_ID,
                                                    QUOTE_ID,
                                                    LINE_NO,
                                                    REQUESTED_PART,
                                                    WHOLESALE_PART,
                                                    REQUESTED_QUANTITY,
                                                    AVAILABLE_QUANTITY,
                                                    BROKER_OFFER,
                                                    GLP,
                                                    SUGGESTED_PRICE,
                                                    EXT_SELL_PRICE,
                                                    LEAD_TIME,
                                                    ENCRYPTION_STATUS,
                                                    INVENTORY_DETAIL_NOTES,
                                                    CREATED_DATE,
                                                    CREATED_BY,
                                                    LAST_UPDATED_DATE,
                                                    LAST_UPDATED_BY,
                                                    DISCOUNT,
                                                    EOS_DATE,
                                                    PROMO_FLAG --Added for US151907
                                                    )
                                VALUES (
                                          lv_Quote_Line_Id,
                                          lv_Quote_Id,
                                          v_Out_Search_Data_List (idx).LINE_NO,
                                          v_Out_Search_Data_List (idx).REQUESTED_PART,
                                          v_Out_Search_Data_List (idx).WHOLESALE_PART,
                                          v_Out_Search_Data_List (idx).REQUESTED_QUANTITY,
                                            lv_Available_Quantity_1
                                          + lv_Available_Quantity_2,
                                          v_Out_Search_Data_List (idx).BROKER_OFFER,
                                          v_Out_Search_Data_List (idx).GLP,
                                          v_Out_Search_Data_List (idx).SUGGESTED_PRICE_OLD,
                                          v_Out_Search_Data_List (idx).EXT_SELL_PRICE,
                                          lv_Lead_Time_Id,
                                          v_Out_Search_Data_List (idx).ENCRYPTION_STATUS,
                                          v_Out_Search_Data_List (idx).INVENTORY_DETAIL_NOTES,
                                          lv_Date,
                                          lv_User_Id,
                                          lv_Date,
                                          lv_User_Id,
                                          v_Out_Search_Data_List (idx).SYSTEM_DISCOUNT,
                                          v_Out_Search_Data_List (idx).EOS_DATE,
                                          v_Out_Search_Data_List (idx).promo_flag --Added for US151907
                                          );
                     END IF;
                  END IF;
               END LOOP;

               /*-- Fetch records from WCT_QUOTE_LINE_TMP to be inserted into WCT_QUOTE_LINE
               SELECT LINE_ID,
                      QUOTE_ID,
                      LINE_NO,
                      REQUESTED_PART,
                      WHOLESALE_PART,
                      REFURBISHED_PART,
                      MANUFACTURING_PART,
                      REQUESTED_QUANTITY,
                      AVAILABLE_QUANTITY,
                      BROKER_OFFER,
                      GLP,
                      SUGGESTED_PRICE,
                      EXT_SELL_PRICE,
                      LEAD_TIME,
                      CREATED_DATE,
                      CREATED_BY,
                      LAST_UPDATED_DATE,
                      LAST_UPDATED_BY,
                      ENCRYPTION_STATUS,
                      INVENTORY_DETAIL_NOTES,
                      DISCOUNT,
                      COMMENTS_L1,
                      COMMENTS_L2,
                      EOS_DATE,
                      APPROVAL_LEVEL,
                      APPROVAL_STATUS_L1,
                      APPROVAL_STATUS_L2
                 BULK COLLECT INTO v_Quote_Line_Insert_List
                 FROM WCT_QUOTE_LINE_TMP
                WHERE REQUESTED_PART NOT IN
                         (SELECT REQUESTED_PART
                            FROM WCT_QUOTE_LINE QL
                           WHERE QL.QUOTE_ID = lv_Quote_Id);

               -- Insert new records into WCT_QUOTE_LINE
               FOR idx IN 1 .. v_Quote_Line_Insert_List.COUNT ()
               LOOP
                  lv_Quote_Line_Id := WCT_QUOTE_LINE_ID.NEXTVAL;

                  INSERT INTO WCT_QUOTE_LINE (LINE_ID,
                                              QUOTE_ID,
                                              LINE_NO,
                                              REQUESTED_PART,
                                              WHOLESALE_PART,
                                              REQUESTED_QUANTITY,
                                              AVAILABLE_QUANTITY,
                                              BROKER_OFFER,
                                              GLP,
                                              SUGGESTED_PRICE,
                                              EXT_SELL_PRICE,
                                              LEAD_TIME,
                                              ENCRYPTION_STATUS,
                                              CREATED_DATE,
                                              CREATED_BY,
                                              LAST_UPDATED_DATE,
                                              LAST_UPDATED_BY,
                                              DISCOUNT,
                                              EOS_DATE)
                       VALUES (
                                 lv_Quote_Line_Id,
                                 lv_Quote_Id,
                                 v_Quote_Line_Insert_List (idx).LINE_NO,
                                 v_Quote_Line_Insert_List (idx).REQUESTED_PART,
                                 v_Quote_Line_Insert_List (idx).WHOLESALE_PART,
                                 v_Quote_Line_Insert_List (idx).REQUESTED_QUANTITY,
                                 v_Quote_Line_Insert_List (idx).AVAILABLE_QUANTITY,
                                 v_Quote_Line_Insert_List (idx).BROKER_OFFER,
                                 v_Quote_Line_Insert_List (idx).GLP,
                                 v_Quote_Line_Insert_List (idx).SUGGESTED_PRICE,
                                 v_Quote_Line_Insert_List (idx).EXT_SELL_PRICE,
                                 v_Quote_Line_Insert_List (idx).LEAD_TIME,
                                 v_Quote_Line_Insert_List (idx).ENCRYPTION_STATUS,
                                 lv_Date,
                                 lv_User_Id,
                                 lv_Date,
                                 lv_User_Id,
                                 v_Out_Search_Data_List (idx).SYSTEM_DISCOUNT,
                                 v_Out_Search_Data_List (idx).EOS_DATE);
               END LOOP;*/
               -- end changes made by ruchhabr 02-MAY-2014

               -- Delete records from WCT_QUOTE_LINE
               DELETE FROM WCT_QUOTE_LINE QL
                     WHERE     QL.QUOTE_ID = lv_Quote_Id
                           AND REQUESTED_PART NOT IN (SELECT REQUESTED_PART
                                                        FROM WCT_QUOTE_LINE_TMP EL);

               -- Empty the temp table
               DELETE FROM WCT_QUOTE_LINE_TMP;

               -- Add rows to the WCT_QUOTE_LINE_AUDIT table
               FOR idx IN 1 .. v_Out_Search_Data_List.COUNT ()
               LOOP
                  INSERT INTO WCT_QUOTE_LINE_AUDIT
                     SELECT *
                       FROM WCT_QUOTE_LINE
                      WHERE     QUOTE_ID = lv_Quote_Id
                            AND REQUESTED_PART =
                                   v_Out_Search_Data_List (idx).REQUESTED_PART;
               END LOOP;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               --LOG EXCEPTION
               v_Error_Message := NULL;
               v_Error_Message := SUBSTR (SQLERRM, 1, 200);

               INSERT INTO WCT_ERROR_LOG
                    VALUES (UPPER (lv_Requested_Part),
                            lv_User_Id,
                            'Data_extract - Step 11.0 - ' || v_Error_Message,
                            SYSDATE);
         END;
      END IF;


      --12.0 Fetch customer details

      BEGIN
         SELECT WCT_CUSTOMER_DETAIL_OBJECT (COMPANY_NAME,
                                            POC_FIRST_NAME,
                                            POC_LAST_NAME,
                                            POC_TITLE,
                                            ADDRESS_1,
                                            ADDRESS_2,
                                            CITY,
                                            STATE,
                                            COUNTRY,
                                            ZIP)
           INTO v_Customer_Detail_Object
           FROM WCT_CUSTOMER CUST, WCT_COMPANY_MASTER COM
          WHERE     CUSTOMER_ID = lv_Customer_Id
                AND CUST.COMPANY_ID = COM.COMPANY_ID;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            --LOG EXCEPTION
            INSERT INTO WCT_ERROR_LOG
                 VALUES (UPPER (lv_Requested_Part),
                         lv_User_Id,
                         'Data_extract - Step 12.0 - No data found',
                         SYSDATE);
         WHEN OTHERS
         THEN
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message := SUBSTR (SQLERRM, 1, 200);

            INSERT INTO WCT_ERROR_LOG
                 VALUES (UPPER (lv_Requested_Part),
                         lv_User_Id,
                         'Data_extract - Step 12.0 - ' || v_Error_Message,
                         SYSDATE);
      END;

      COMMIT;
      v_Out_Search_Result_Object :=
         WCT_SEARCH_RESULT_MOD_OBJECT (v_Out_Search_Data_List,
                                       v_Customer_Detail_Object,
                                       v_Invalid_Part_List,
                                       lv_Quote_Id,
                                       --Commented by satbanda on 20-Mar-2017 for validate PID logic <Start>
                                      /*  v_Exclude_Pid_List, --added for exclude PID logic karusing Sep 2014
                                       v_Brightline_Plus_Pid_List, --added for exclude PID logic karusing Sep 2014
                                       v_RL_Pid_List,
                                       v_NON_ORDERABLE_Pid_List */
                                       --Commented by satbanda on 20-Mar-2017 for validate PID logic <End>
                                       NULL,NULL,NULL,NULL --Added by satbanda on 20-Mar-2017 for Validate PID logic
                                       ); --added for RL Oct 2014

      o_Search_Result_Object := v_Out_Search_Result_Object;

      /* Check and when Inventory is zero, notify Support team */

      SELECT COUNT (*)
        INTO lv_c3_inv_count
        FROM CRPADM.RC_INV_BTS_C3_TBL; --VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_TBL;--Modified by satbanda on 23rd Jan,2018 for replacing VAVNI RSCM objects

      IF (lv_c3_inv_count = 0)
      THEN
         ZERO_INVENTORY_EMAIL;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         --LOG EXCEPTION
         v_Error_Message := NULL;
         v_Error_Message := SUBSTR (SQLERRM, 1, 200);

         INSERT INTO WCT_ERROR_LOG
                 VALUES (
                           UPPER (lv_Requested_Part),
                           lv_User_Id,
                              'Data_extract - '
                           || v_Error_Message
                           || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                           SYSDATE);
   END;

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
      o_Inventory_Download_Object      OUT WCT_INVENTORY_DOWNLOAD_OBJECT)
   IS
      TYPE T_EXCEPTION_PART_OBJECT IS RECORD
      (
         PART_NUMBER             VARCHAR2 (50),
         PRODUCT_NAME_STRIPPED   VARCHAR2 (50)
      );

      TYPE T_EXCEPTION_PART_LIST IS TABLE OF T_EXCEPTION_PART_OBJECT;

      --      TYPE EP_INV_PID_OBJECT IS RECORD
      --      (
      --         PART_NUMBER             VARCHAR2 (50),
      --         PRODUCT_DESC           VARCHAR2 (100)
      --      );
      --
      --      TYPE EP_INV_PID_LIST IS TABLE OF T_EXCEPTION_PART_OBJECT;

      TYPE EP_INV_PID_LIST IS TABLE OF VARCHAR2 (32000);

      v_Raw_Inventory_List        EP_INV_PID_LIST;
      --commented by hkarka for removing references to Customer Tier on 04-APR-2017
      --v_Exception_Part_List       T_EXCEPTION_PART_LIST;      --added new list
      lv_ws_part_number           VARCHAR2 (100);
      lv_spare_part_number        VARCHAR2 (100);
      lv_rf_part_number           VARCHAR2 (100);
      lv_Customer_region          VARCHAR2 (100);
      lv_Inventory_region         VARCHAR2 (100);

      lv_User_Id                  VARCHAR2 (12);
      lv_Display_Type             VARCHAR2 (50);

      lv_Quantity_1               NUMBER := 0;
      lv_Quantity_2               NUMBER := 0;
      lv_Quantity_3               NUMBER := 0;
      lv_Net_WS_Quantity          NUMBER := 0;
      lv_rf_part_count            NUMBER := 0;

      lv_Inv_Dnld_List_Count      NUMBER := 1;
      lv_Date_Time_String         VARCHAR2 (100) := v_Empty_String;
      lv_Include_Row              BOOLEAN;
      lv_Part_Validity_Flag       CHAR;
      lv_Ws_Product_Id            VARCHAR2 (50);
      lv_Disclaimer               VARCHAR2 (2000) := v_Empty_String;
      lv_Encryption_Status        VARCHAR2 (80);
      lv_Restricted_Flag          CHAR;
      --commented by hkarka for removing references to Customer Tier on 04-APR-2017
      --lv_Tier                     NUMBER (1);            --Added two varibles.
      lv_bl_count                   NUMBER;

      lv_Product_Name_Stripped    VARCHAR2 (50);
      lv_Cap_Flag                 CHAR; --added new variable for cap availability
      lv_Cap_Value                NUMBER := 0; --added new variable for cap availability
      lv_ccw                      NUMBER := 0;
      lv_part_desc                VARCHAR2 (100);
      v_Inventory_Download_List   WCT_INV_DNLD_LIST;
      lv_refresh_cycle_name       VARCHAR2 (50);
      lv_Inventory_Region_LRO     VARCHAR2 (10);
      lv_Inventory_Region_FVE     VARCHAR2 (10);
      lv_Inventory_Region_GDGI    VARCHAR2 (10);
      --Added by satbanda to get the active Part for deactivated Wholesale parts<Start>
      lv_common_part              VARCHAR2 (300);
      lv_refresh_life_cycle       VARCHAR2 (300);
      lv_Wholesale_Part_nbr       VARCHAR2 (300);
      lv_mfg_eos_date             DATE;--Added for US134623
   --  BEGIN
   BEGIN
      lv_User_Id := i_User_Id;
      lv_Customer_Region := i_Customer_region;
      lv_Display_Type := i_Display_Type;
      --commented by hkarka for removing references to Customer Tier on 04-APR-2017
      --lv_Tier := i_Tier;                                               --added
      lv_Cap_Flag := i_Cap_Flag;                                       --added
      lv_Cap_Value := i_Cap_Value;
      lv_Inventory_Region_LRO := i_Inventory_Region_LRO; -- LRO site indicator
      lv_Inventory_Region_FVE := i_Inventory_Region_FVE; -- FVE site indicator
      lv_Inventory_Region_GDGI := i_Inventory_Region_GDGI;             --added

      v_Inventory_Download_List := WCT_INV_DNLD_LIST ();

      GET_DATA_REFRESH_TIME (i_Client_Date_Time, lv_Date_Time_String);

--(start) commented by hkarka for removing references to Customer Tier on 04-APR-2017
/*
      IF (lv_Tier = 1) --changes for exclusion of PID for seleted Tier user August 2014 by karusing
      THEN
         SELECT PRODUCT_ID, PRODUCT_NAME_STRIPPED
           BULK COLLECT INTO v_Exception_Part_List
           FROM vavni_cisco_rscm_admin.WCT_EXCLUDE_PID
          WHERE STATUS = 'ACTIVE' AND EXCLUDE_TIER1 = 'Y';
      ELSIF (lv_Tier = 2)
      THEN
         SELECT PRODUCT_ID, PRODUCT_NAME_STRIPPED
           BULK COLLECT INTO v_Exception_Part_List
           FROM vavni_cisco_rscm_admin.WCT_EXCLUDE_PID
          WHERE STATUS = 'ACTIVE' AND EXCLUDE_TIER2 = 'Y';
      END IF;
*/
--(end) commented by hkarka for removing references to Customer Tier on 04-APR-2017

      BEGIN
        --Commented by Satbanda for replacing VAVNI schema objects with C3 objects <Start>
         -- get the part id's - union to include parts with only FG inv.
         /* SELECT PART_NUMBER
           BULK COLLECT INTO v_Raw_Inventory_List
           FROM ( (  SELECT DISTINCT
                             CASE
                               WHEN SUBSTR (
                                       PM_PROD.PRODUCT_COMMON_NAME,
                                       LENGTH (PM_PROD.PRODUCT_COMMON_NAME),
                                       1) = '='
                               THEN
                                  SUBSTR (
                                     PM_PROD.PRODUCT_COMMON_NAME,
                                     0,
                                     LENGTH (PM_PROD.PRODUCT_COMMON_NAME) - 1)
                               ELSE
                                  PM_PROD.PRODUCT_COMMON_NAME
                            END
                               AS PART_NUMBER
                       FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV MV
                       --Added for US134623 <Start>
                            INNER JOIN crpadm.rc_product_master mstr
                               ON (   MV.PART_NUMBER = MSTR.REFRESH_PART_NUMBER
                                   OR MV.PART_NUMBER = MSTR.COMMON_PART_NUMBER
                                   OR MV.PART_NUMBER = MSTR.XREF_PART_NUMBER)
                        --Added for US134623 <End>
                            LEFT OUTER JOIN
                            VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
                               ON     (PM_PROD.PRODUCT_NAME_STRIPPED =
                                          MV.PRODUCT_NAME_STRIPPED)
                                  AND MV.REGION = PM_PROD.REGION_NAME
                            INNER JOIN
                            VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP LOC
                               ON LOC.DESTINATION_SUBINVENTORY = MV.LOCATION
                            INNER JOIN
                            VAVNI_CISCO_RSCM_ADMIN.VV_ADM_ZLOCATION_TABLE ZLOC
                               ON ZLOC.ZLOC = SUBSTR (MV.SITE, 1, 3)
                            LEFT OUTER JOIN
                            VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP SCM
                               ON     MV.LOCATION =
                                         SCM.DESTINATION_SUBINVENTORY
                                  AND SCM.YIELD_WS = 'YES'
                      WHERE NVL (PM_PROD.PRODUCT_BU_STATUS_ID, 0) <> 6
                            AND (LOC.PROGRAM_TYPE = 1 OR
                            (LOC.PROGRAM_TYPE = 2
                             AND MONTHS_BETWEEN(NVL(mstr.mfg_eos_date,TO_DATE ('12/31/2999', 'MM/DD/YYYY')),SYSDATE)>4) --Added for US134623
                            ) -- FOR 1= WHOLESALE, 2= DGI LOCATIONS
                            AND LOC.IS_NETTABLE = 1
                            AND LOC.IS_ENABLE = 1
                   GROUP BY PRODUCT_COMMON_NAME)
                 UNION
                (SELECT DISTINCT
                         CASE
                            WHEN SUBSTR (
                                    PM_PROD.PRODUCT_COMMON_NAME,
                                    LENGTH (PM_PROD.PRODUCT_COMMON_NAME),
                                    1) = '='
                            THEN
                               SUBSTR (
                                  PM_PROD.PRODUCT_COMMON_NAME,
                                  0,
                                  LENGTH (PM_PROD.PRODUCT_COMMON_NAME) - 1)
                            ELSE
                               PM_PROD.PRODUCT_COMMON_NAME
                         END
                            AS PART_NUMBER
                    FROM VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV MV
                         LEFT OUTER JOIN
                         VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
                            ON     (PM_PROD.PRODUCT_NAME_STRIPPED =
                                       MV.PRODUCT_NAME_STRIPPED)
                               AND MV.REGION = PM_PROD.REGION_NAME
                   WHERE     PM_PROD.PRODUCT_BU_STATUS_ID <> 6
                         AND MV.LOCATION IN ('FG')
                         AND MV.PRODUCT_FAMILY LIKE '%WHLSALE%')
                 ORDER BY PART_NUMBER ASC); */
        --Commented by Satbanda for replacing VAVNI schema objects with C3 objects <End>    
      --Added by Satbanda for replacing VAVNI schema objects with C3 objects <Start>        
        SELECT PART_NUMBER
           BULK COLLECT INTO v_Raw_Inventory_List 
           FROM ( 
       --(start) Added by hkarka as on 26-OCT-2018 as part of Selling FGI change
		SELECT DISTINCT
		       CASE
			  WHEN SUBSTR (mstr.COMMON_PART_NUMBER,
				       LENGTH (mstr.COMMON_PART_NUMBER),
				       1) = '='
			  THEN
			     SUBSTR (mstr.COMMON_PART_NUMBER,
				     0,
				     LENGTH (mstr.COMMON_PART_NUMBER) - 1)
			  ELSE
			     mstr.COMMON_PART_NUMBER
		       END
			  AS PART_NUMBER
		  FROM crpadm.rc_product_master mstr
		 WHERE     NVL (mstr.REFRESH_LIFE_CYCLE_ID, 0) <> 6
		       AND mstr.PROGRAM_TYPE = 1
		       AND MONTHS_BETWEEN (
			      NVL (mstr.mfg_eos_date, TO_DATE ('12/31/2999', 'MM/DD/YYYY')),
			      SYSDATE) > 4
                 );
       --(end) Added by hkarka as on 26-OCT-2018 as part of Selling FGI change

       --(start) Commented by hkarka as on 26-OCT-2018 as part of Selling FGI change
	   /*
	   (  SELECT DISTINCT
                             CASE
                               WHEN SUBSTR (
                                       mstr.COMMON_PART_NUMBER,
                                       LENGTH (mstr.COMMON_PART_NUMBER),
                                       1) = '='
                               THEN
                                  SUBSTR (
                                     mstr.COMMON_PART_NUMBER,
                                     0,
                                     LENGTH (mstr.COMMON_PART_NUMBER) - 1)
                               ELSE
                                  mstr.COMMON_PART_NUMBER
                            END
                              AS PART_NUMBER
                       FROM CRPADM.RC_INV_BTS_C3_MV MV 
                            INNER JOIN crpadm.rc_product_master mstr
                               ON (   MV.PART_NUMBER = MSTR.REFRESH_PART_NUMBER
                                   OR MV.PART_NUMBER = MSTR.COMMON_PART_NUMBER
                                   OR MV.PART_NUMBER = MSTR.XREF_PART_NUMBER)
                            INNER JOIN
                            crpadm.RC_SUB_INV_LOC_MSTR LOC 
                               ON LOC.SUB_INVENTORY_LOCATION = MV.LOCATION
                            INNER JOIN
                            (SELECT DISTINCT ZCODE, THEATER_NAME
                               FROM crpadm.RC_PRODUCT_REPAIR_PARTNER
                              WHERE ACTIVE_FLAG = 'Y') ZLOC
                               ON ZLOC.ZCODE = SUBSTR (MV.SITE, 1, 3)
                            LEFT OUTER JOIN
                            crpadm.RC_SUB_INV_LOC_FLG_DTLS SCM 
                               ON     LOC.SUB_INVENTORY_ID =
                                         SCM.SUB_INVENTORY_ID
                                  AND SCM.YIELD_WS = 'Y'
                      WHERE NVL (mstr.REFRESH_LIFE_CYCLE_ID, 0) <> 6 
                            AND (LOC.PROGRAM_TYPE = 1 OR
                            (LOC.PROGRAM_TYPE = 2
                             AND MONTHS_BETWEEN(NVL(mstr.mfg_eos_date,TO_DATE ('12/31/2999', 'MM/DD/YYYY')),SYSDATE)>4) 
                            ) -- FOR 1= WHOLESALE, 2= DGI LOCATIONS
                            AND LOC.NETTABLE_FLAG = 1
                   GROUP BY mstr.COMMON_PART_NUMBER 
                   )
                 UNION
                (SELECT DISTINCT
                          CASE
                               WHEN SUBSTR (
                                       mstr.COMMON_PART_NUMBER,
                                       LENGTH (mstr.COMMON_PART_NUMBER),
                                       1) = '='
                               THEN
                                  SUBSTR (
                                     mstr.COMMON_PART_NUMBER,
                                     0,
                                     LENGTH (mstr.COMMON_PART_NUMBER) - 1)
                               ELSE
                                  mstr.COMMON_PART_NUMBER
                            END
                              AS PART_NUMBER
                    FROM CRPADM.RC_INV_BTS_C3_MV MV 
                         INNER JOIN 
                         crpadm.rc_product_master mstr
                               ON (   MV.PART_NUMBER = MSTR.REFRESH_PART_NUMBER
                                   OR MV.PART_NUMBER = MSTR.COMMON_PART_NUMBER
                                   OR MV.PART_NUMBER = MSTR.XREF_PART_NUMBER)
                   WHERE     NVL (mstr.REFRESH_LIFE_CYCLE_ID, 0) <> 6
                         AND MV.LOCATION IN ('FG')
                         AND MV.PRODUCT_FAMILY LIKE '%WHLSALE%')
                 ORDER BY  PART_NUMBER ASC
		 );    
		 */
                 --(end) Commented by hkarka as on 26-OCT-2018 as part of Selling FGI change
                 --Added by Satbanda for replacing VAVNI schema objects with C3 objects <End>

         -- FOR idx IN 1 .. v_Raw_Inventory_List.COUNT ()

         FOR idx IN 1 .. v_Raw_Inventory_List.COUNT ()
         LOOP
            lv_ws_part_number := '';
            lv_part_desc := '';
            lv_refresh_cycle_name := '';
            lv_Quantity_1 := 0;
            lv_Quantity_2 := 0;
            lv_Quantity_3 := 0;
            lv_spare_part_number := '';
            lv_rf_part_number := '';

            -- spare part number
            lv_spare_part_number := v_Raw_Inventory_List (idx) || '=';

            lv_ws_part_number :=
               get_ws_part_number (v_Raw_Inventory_List (idx));

            -- Adding logic to retrieve the active WS part number

            BEGIN
               SELECT common_part_number, refresh_life_cycle_name
                 INTO lv_common_part, lv_refresh_life_cycle
                 FROM crpadm.rc_product_master
                WHERE refresh_part_number = lv_ws_part_number;
            EXCEPTION
               WHEN OTHERS
               THEN
                  lv_common_part := NULL;
                  lv_refresh_cycle_name := NULL;
            END;

            --derive active ws pid for the same common part number
            IF lv_refresh_cycle_name = v_deactivated_status
            THEN
               BEGIN
                  SELECT refresh_part_number
                    INTO lv_wholesale_part_nbr
                    FROM crpadm.rc_product_master
                   WHERE     common_part_number = lv_common_part
                         AND NVL (deactivation_date, SYSDATE) >= SYSDATE --should not be deactivated
                         AND program_type = 1;                --wholesale part

                  lv_ws_part_number := lv_wholesale_part_nbr;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     lv_wholesale_part_nbr := lv_ws_part_number;
               END;
            END IF;

            -- get the RF part number

            BEGIN
               SELECT COUNT (*)
                 INTO lv_rf_part_count
                 FROM CRPADM.RC_PRODUCT_MASTER PROD
                WHERE     PROD.COMMON_PART_NUMBER IN (lv_spare_part_number,
                                                      v_Raw_Inventory_List (
                                                         idx))
                      AND program_TYPE = 0;


               IF (lv_rf_part_count > 1)
               THEN
                  SELECT REFRESH_PART_NUMBER
                    INTO lv_rf_part_number
                    FROM CRPADM.RC_PRODUCT_MASTER PROD
                   WHERE     PROD.COMMON_PART_NUMBER IN (lv_spare_part_number,
                                                         v_Raw_Inventory_List (
                                                            idx))
                         AND program_TYPE = 0
                         AND REFRESH_LIFE_CYCLE_NAME = 'CUR';
               ELSE
                  SELECT REFRESH_PART_NUMBER
                    INTO lv_rf_part_number
                    FROM CRPADM.RC_PRODUCT_MASTER PROD
                   WHERE     PROD.COMMON_PART_NUMBER IN (lv_spare_part_number,
                                                         v_Raw_Inventory_List (
                                                            idx))
                         AND program_TYPE = 0;
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  lv_rf_part_number := '';

               --(start) added by hkarka as on 8/28/2017 for multiple active RF pid on mfg pid issue in Inventory Download report
               WHEN OTHERS
               THEN
                  v_Error_Message := NULL;
                  v_Error_Message :=
                  SUBSTR (SQLERRM, 1, 50) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

                  INSERT INTO WCT_ERROR_LOG
                  VALUES ('INVENTORY_DOWNLOAD - '||v_Raw_Inventory_List (idx),
                           lv_User_Id,
                           v_Error_Message,
                           SYSDATE);
               --(end) added by hkarka as on 8/28/2017 for multiple active RF pid on mfg pid issue in Inventory Download report
            END;


            lv_part_desc := GET_PART_DESCRIPTION (v_Raw_Inventory_List (idx));

            IF (lv_ws_part_number IS NOT NULL)
            THEN
               BEGIN
                  SELECT DISTINCT REFRESH_LIFE_CYCLE_NAME,
                         NVL (mfg_eos_date,
                           TO_DATE ('12/31/2999', 'MM/DD/YYYY')) --Added for US134623
                    INTO lv_refresh_cycle_name
                        ,lv_mfg_eos_date --Added for US134623
                    FROM CRPADM.RC_PRODUCT_MASTER
                   WHERE refresh_part_number = lv_ws_part_number;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     lv_refresh_cycle_name := v_Empty_string;
               END;
            END IF;

            IF (    lv_ws_part_number IS NOT NULL
                AND (   lv_refresh_cycle_name = 'CUR'
                     OR lv_refresh_cycle_name = 'EOL'
                     OR lv_refresh_cycle_name = 'EOS'))
            THEN
               -- WS implementation
               --moving the region check after negative inv calc.
               IF (UPPER (lv_Customer_Region) = 'NAM')
               THEN
                  SELECT NVL (SUM (AVAILABLE_TO_RESERVE_FGI), 0)
                    INTO lv_Quantity_1
                    FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                   WHERE     PART_NUMBER = lv_ws_part_number
                         AND SITE_CODE = 'LRO';


                  SELECT NVL (SUM (AVAILABLE_TO_RESERVE_FGI), 0)
                    INTO lv_Quantity_2
                    FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                   WHERE     PART_NUMBER = lv_ws_part_number
                         AND SITE_CODE = 'FVE';

                  SELECT NVL (SUM (AVAILABLE_TO_RESERVE_DGI), 0)
                    INTO lv_Quantity_3
                    FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                   WHERE     PART_NUMBER = lv_ws_part_number
                         AND SITE_CODE = 'GDGI'
                         AND MONTHS_BETWEEN(lv_mfg_eos_date,SYSDATE)>4 --Added for US134623
                         ;
               ELSIF (UPPER (lv_Customer_Region) = 'EMEA')
               THEN
                  SELECT NVL (SUM (AVAILABLE_TO_RESERVE_FGI), 0)
                    INTO lv_Quantity_2
                    FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                   WHERE     PART_NUMBER = lv_ws_part_number
                         AND SITE_CODE = 'LRO'
                         AND ROHS_COMPLIANT = 'YES'; -- Added condition to return only ROHS YEs items when customer is EMEA region;

                  SELECT NVL (SUM (AVAILABLE_TO_RESERVE_FGI), 0)
                    INTO lv_Quantity_1
                    FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                   WHERE     PART_NUMBER = lv_ws_part_number
                         AND SITE_CODE = 'FVE'
                         AND ROHS_COMPLIANT = 'YES'; -- Added condition to return only ROHS YEs items when customer is EMEA region;

                  SELECT NVL (SUM (AVAILABLE_TO_RESERVE_DGI), 0)
                    INTO lv_Quantity_3
                    FROM RMKTGADM.XXCPO_RMK_INVENTORY_MASTER
                   WHERE     PART_NUMBER = lv_ws_part_number
                         AND SITE_CODE = 'GDGI'
                         AND MONTHS_BETWEEN(lv_mfg_eos_date,SYSDATE)>4 --Added for US134623
                         AND ROHS_COMPLIANT = 'YES'; -- Added condition to return only ROHS YEs items when customer is EMEA region;
               END IF;

               -- negative inv implementation starts
               -- find the net qty

               lv_Net_WS_Quantity :=
                  lv_Quantity_1 + lv_Quantity_2 + lv_Quantity_3;

               IF (lv_Net_WS_Quantity < 0)  -- if Net qty is negative on whole
               THEN
                  lv_Quantity_1 := 0;
                  lv_Quantity_2 := 0;
                  lv_Quantity_3 := 0;
               ELSE
                  IF (   lv_Quantity_1 < 0
                      OR lv_Quantity_2 < 0
                      OR lv_Quantity_3 < 0) -- check if any qty is negative ( region is negative )
                  THEN
                     lv_Quantity_3 := lv_Net_WS_Quantity; --set GDGI Qty with NetTotal WS Qty
                     lv_Quantity_1 := 0;
                     lv_Quantity_2 := 0;
                  END IF;
               END IF;

               -- negative inv implementation ends
               -- region check starts

               IF (UPPER (lv_Customer_Region) = 'NAM')
               THEN
                  IF (lv_Inventory_Region_LRO <> 'Y')
                  THEN
                     lv_Quantity_1 := 0;
                  END IF;

                  IF (lv_Inventory_Region_FVE <> 'Y')
                  THEN
                     lv_Quantity_2 := 0;
                  END IF;

                  IF (lv_Inventory_Region_GDGI <> 'Y')
                  THEN
                     lv_Quantity_3 := 0;
                  END IF;
               ELSE
                  IF ( (UPPER (lv_Customer_Region) = 'EMEA'))
                  THEN
                     IF (lv_Inventory_Region_LRO <> 'Y')
                     THEN
                        lv_Quantity_2 := 0;
                     END IF;

                     IF (lv_Inventory_Region_FVE <> 'Y')
                     THEN
                        lv_Quantity_1 := 0;
                     END IF;

                     IF (lv_Inventory_Region_GDGI <> 'Y')
                     THEN
                        lv_Quantity_3 := 0;
                     END IF;
                  END IF;
               END IF;
            -- region check ends
            ELSE
               -- non WS implementation starts
               
              

               IF (lv_Inventory_Region_GDGI = 'Y')
               THEN
/*
                  SELECT NVL (SUM (ON_HAND), 0)
                    INTO lv_Quantity_3
                    FROM (SELECT CASE
                                    WHEN (SCM.DESTINATION_SUBINVENTORY
                                             IS NULL)
                                    THEN
                                       QTY_ON_HAND
                                    ELSE
                                       ROUND (
                                            QTY_ON_HAND*
                                            (NVL (MV.rm_yield, 80) / 100))
                                 END
                                    ON_HAND
                            FROM (  SELECT PRODUCT_NAME_STRIPPED,
                                           PART_NUMBER,--Added for US134623
                                           region,
                                           SUM (QTY_ON_HAND) QTY_ON_HAND,
                                           LOCATION
                                           --Added by Satbanda for replacing VAVNI schema objects with C3 objects <Start>
                                            ,vv_rscm_util.calculate_yield (mv.location,
                                                     mv.part_number,
                                                     locmstr.program_type,
                                                     mv.region,
                                                     SUBSTR (mv.site, 1, 3),
                                                     NULL)  rm_yield        --refurb_method_id
                                           --Added by Satbanda for replacing VAVNI schema objects with C3 objects <End>
                                      FROM CRPADM.RC_INV_BTS_C3_MV MV, --VAVNI_CISCO_RSCM_ADMIN.RSCM_ML_C3_INV_MV mv  --Added by Satbanda for replacing VAVNI schema objects with C3 objects
                                       CRPADM.RC_SUB_INV_LOC_MSTR locmstr
                                     WHERE MV.PART_NUMBER IN (lv_ws_part_number,
                                                              lv_spare_part_number,
                                                              lv_rf_part_number,
                                                              v_Raw_Inventory_List (
                                                                 idx))
                                        AND locmstr.sub_inventory_location = mv.location
                                        AND locmstr.program_type IN (1, 2)
                                        AND locmstr.nettable_flag = 1
                                  GROUP BY PRODUCT_NAME_STRIPPED,
                                           PART_NUMBER,--Added for US134623
                                           REGION,
                                           LOCATION) MV
                                --Added for US134623 <Start>
                                INNER JOIN crpadm.rc_product_master mstr
                                   ON (   MV.PART_NUMBER = MSTR.REFRESH_PART_NUMBER
                                       OR MV.PART_NUMBER = MSTR.COMMON_PART_NUMBER
                                       OR MV.PART_NUMBER = MSTR.XREF_PART_NUMBER)
                            --Added for US134623 <End>
                                  LEFT OUTER JOIN
                                 VAVNI_CISCO_RSCM_PM.VV_PM_PRD_ORG_CITY_VW PM_PROD
                                    ON     PM_PROD.product_name_stripped =
                                              MV.product_name_stripped
                                       AND PM_PROD.REGION_NAME = MV.REGION
                                 LEFT OUTER JOIN
                                 VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP SCM
                                    ON     MV.LOCATION =
                                              SCM.DESTINATION_SUBINVENTORY
                                       AND SCM.YIELD_WS = 'YES'
                           WHERE     1 = 1
                                 AND MV.LOCATION IN (SELECT DESTINATION_SUBINVENTORY
                                                       FROM VAVNI_CISCO_RSCM_BP.VV_BP_SUBINV_COL_MAP
                                                      WHERE     1 = 1
                                                            AND (   PROGRAM_TYPE =
                                                                       1
                                                                 OR
                                                                 (PROGRAM_TYPE =2
                                                                  AND MONTHS_BETWEEN(NVL(mstr.mfg_eos_date,TO_DATE ('12/31/2999', 'MM/DD/YYYY')),SYSDATE)>4) --Added for US134623
                                                                 ) -- include WS and POE locations
                                                            AND IS_NETTABLE =
                                                                   1
                                                            AND IS_ENABLE = 1
                                                            AND DESTINATION_SUBINVENTORY NOT IN ('WS-FGSLD'))
                                 -- AND INVENTORY_TYPE <> 2)-- to allow WS WIP
                                 AND MV.LOCATION NOT IN (              --'FG',
                                                         'WS-FGSLD',
                                                         'RF-W-RHS',
                                                         'RF-W-OEM',
                                                         'RF-WIP'  -- 'WS-WIP'
                                                                 ));
*/

        /* --(Start) Commented by csirigir as on 26-OCT-2018 as part of Selling FGI change
                --(Start) added by hkarka
       
                  SELECT SUM (ROUND (QTY_ON_HAND * (NVL (refresh_yield, 80) / 100))) qty
                    INTO lv_Quantity_3
                    FROM (
                    SELECT 'GDGI' inventory_site,
                                 NULL inventory_theater,
                                 'GDGI' inventory_location,
                                 'YES' rohs_flag,
                                 mv.part_number,
                                 mv.site,
                                 mv.location,
                                 mv.qty_on_hand,
                                 mv.qty_in_transit,
                                 mv.qty_reserved,
                                 mv.repair_flag,
                                 mv.product_name_stripped,
                                 mv.region,
                                 locmstr.sub_inventory_id,
                                 locmstr.program_type,
                                 locmstr.nettable_flag,
                                 vv_rscm_util.calculate_yield (mv.location,
                                                  mv.part_number,
                                                  locmstr.program_type,
                                                  mv.region,
                                                  SUBSTR (mv.site, 1, 3),
                                                  NULL)                     --refurb_method_id
                                    refresh_yield,
                                 NULL TOTAL_AVAILABLE_CCW,
                                 NULL selected
                            FROM CRPADM.RC_INV_BTS_C3_MV mv,
                                 CRPADM.RC_SUB_INV_LOC_MSTR locmstr
                           WHERE     locmstr.sub_inventory_location = mv.location
                                 AND locmstr.program_type IN (1, 2)
                                 AND locmstr.nettable_flag = 1
                                                     AND MV.PART_NUMBER IN (lv_ws_part_number,
                                                                              lv_spare_part_number,
                                                                              lv_rf_part_number,
                                                                              v_Raw_Inventory_List (
                                                                                 idx))
                                 AND MV.LOCATION NOT IN ('WS-FGSLD',
                                                         'RF-W-RHS',
                                                         'RF-W-OEM',
                                                         'RF-WIP')
                                                        );

                --(End) added by hkarka
				
		   --(End) Commented by csirigir as on 26-OCT-2018 as part of Selling FGI change */

                  lv_Quantity_1 := 0;
                  lv_Quantity_2 := 0;
				  lv_Quantity_3 := 0;  --Added by csirigir as on 26-OCT-2018 as part of Selling FGI change
               ELSE
                  lv_Quantity_1 := 0;
                  lv_Quantity_2 := 0;
                  lv_Quantity_3 := 0;
               END IF;
            END IF;


            lv_Restricted_Flag := 'N';

            -- set include row to true
            lv_Include_Row := TRUE;

            lv_Product_Name_Stripped :=
               VV_RSCM_UTIL.GET_STRIPPED_NAME (v_Raw_Inventory_List (idx));

--(start) Commented by hkarka for removing references to stripped and RSCM on 08-MAR-2017
/*
        FOR innerIdx IN 1 .. v_Exception_Part_List.COUNT ()
            LOOP
               IF UPPER (lv_Product_Name_Stripped) =
                     UPPER (
                        v_Exception_Part_List (innerIdx).PRODUCT_NAME_STRIPPED)
               THEN
                  lv_Include_Row := FALSE;
                  EXIT;
               END IF;
            END LOOP;
*/
--(end) Commented by hkarka for removing references to stripped and RSCM on 08-MAR-2017

--(start) Added by hkarka for removing references to stripped and RSCM on 08-MAR-2017
          BEGIN
          lv_bl_count := 0;

          SELECT count(1)
                INTO lv_bl_count
                FROM CRPSC.RC_BRIGHTLINE_PRODUCTS rbp,
                     CRPADM.RC_PRODUCT_MASTER rpm
               WHERE rbp.STATUS = 'ACTIVE'
                 AND rpm.common_part_number IN (v_Raw_Inventory_List (idx),v_Raw_Inventory_List (idx)||'=')
                 --AND rpm.program_type = 1
         AND brightline_category IN ('BL', 'BL+', 'BL,BL+')
                 AND (   rbp.PART_NUMBER = rpm.refresh_part_number
                      OR rbp.PART_NUMBER = rpm.common_part_number
                      OR rbp.PART_NUMBER = rpm.xref_part_number);

             IF (lv_bl_count >0) THEN
                lv_Include_Row := FALSE;
         ELSE
                lv_Include_Row := TRUE;
             END IF;
          EXCEPTION
             WHEN OTHERS THEN
                lv_Include_Row := TRUE;
          END;
--(end) Added by hkarka for removing references to stripped and RSCM on 08-MAR-2017

        -- adding Pid validation to not include invalid or deactivated pids in inv report
            lv_Part_Validity_Flag :=
               VV_RSCM_UTIL.VALIDATE_PART_ID_EXCESS_MODIFY (
                  v_Raw_Inventory_List (idx),
                  NULL);

            IF (lv_Part_Validity_Flag = 'N')
            THEN
               lv_Part_Validity_Flag :=
                  VV_RSCM_UTIL.VALIDATE_PART_ID_EXCESS_MODIFY (
                     v_Raw_Inventory_List (idx) || '=',
                     NULL);
            END IF;

            IF (lv_Include_Row AND (lv_Part_Validity_Flag = v_Flag_Yes))
            THEN
               BEGIN
                  SELECT DISTINCT ECCN
                    INTO lv_Encryption_Status
                    FROM CRPADM.RC_PRODUCT_MASTER
                   WHERE common_part_number = v_Raw_Inventory_List (idx);


                  IF (   lv_Encryption_Status LIKE '5A002%'
                      OR lv_Encryption_Status LIKE '5D002%')
                  THEN
                     lv_Restricted_Flag := v_Flag_Yes;
                  ELSE
                     lv_Restricted_Flag := v_Flag_No;
                  END IF;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     lv_Encryption_Status := v_Empty_String;
                  WHEN OTHERS
                  THEN
                     lv_Encryption_Status := v_Empty_String;
               END;

               IF (lv_Display_Type = 'ALL')
               THEN
                  IF (lv_ws_part_number LIKE '%WS')
                  THEN
                     lv_Ws_Product_Id := lv_ws_part_number;
                  ELSE
                     lv_Ws_Product_Id := v_Empty_String;
                  END IF;
               ELSIF (lv_Display_Type = 'WS')
               THEN
                  IF (lv_ws_part_number LIKE '%WS')
                  THEN
                     lv_Ws_Product_Id := lv_ws_part_number;
                  ELSE
                     lv_Include_Row := FALSE;
                  END IF;
               ELSIF (lv_Display_Type = 'NWS')
               THEN
                  IF (lv_ws_part_number LIKE '%WS')
                  THEN
                     lv_Include_Row := FALSE;
                  ELSE
                     lv_Ws_Product_Id := lv_ws_part_number;
                  END IF;
               END IF;

               IF (lv_Include_Row AND (lv_Part_Validity_Flag = v_Flag_Yes))
               THEN
                  IF (lv_Cap_Flag = v_Flag_Yes)
                  THEN
                     IF (lv_Quantity_1 >= lv_Cap_Value)
                     THEN
                        lv_Quantity_1 := lv_Cap_Value;
                        lv_Quantity_2 := 0;
                        lv_Quantity_3 := 0;
                     ELSE
                        IF ( (lv_Quantity_1 + lv_Quantity_2) >= lv_Cap_Value)
                        THEN
                           lv_Quantity_3 := 0;
                           lv_Quantity_2 := lv_Cap_Value - lv_Quantity_1;
                        ELSE
                           IF ( (  lv_Quantity_1
                                 + lv_Quantity_2
                                 + lv_Quantity_3) >= lv_Cap_Value)
                           THEN
                              lv_Quantity_3 :=
                                   lv_Cap_Value
                                 - (lv_Quantity_2 + lv_Quantity_1);
                           ELSE
                              lv_Quantity_1 := lv_Quantity_1;
                              lv_Quantity_2 := lv_Quantity_2;
                              lv_Quantity_3 := lv_Quantity_3;
                           END IF;
                        END IF;
                     END IF;
                  END IF;

                  -- create and store inventory download object in the list
                  v_Inventory_Download_List.EXTEND ();

                  v_Inventory_Download_List (lv_Inv_Dnld_List_Count) :=
                     WCT_INV_DNLD_OBJECT (v_Raw_Inventory_List (idx),
                                          lv_Ws_Product_Id,
                                          lv_part_desc,
                                          NVL (lv_Quantity_1, 0),
                                          NVL (lv_Quantity_2, 0),
                                          NVL (lv_Quantity_3, 0),
                                          lv_Restricted_Flag);
                  lv_Inv_Dnld_List_Count := lv_Inv_Dnld_List_Count + 1;
               END IF;
            END IF;
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            --LOG EXCEPTION
            v_Error_Message := NULL;
            v_Error_Message :=
               SUBSTR (SQLERRM, 1, 50) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('INVENTORY_DOWNLOAD',
                         lv_User_Id,
                         v_Error_Message,
                         SYSDATE);
      END;

      BEGIN
         SELECT PROPERTY_VALUE
           INTO lv_Disclaimer
           FROM WCT_PROPERTIES
          WHERE PROPERTY_TYPE = 'INVENTORY_DOWNLOAD_DISCLAIMER';
      EXCEPTION
         WHEN OTHERS
         THEN
            lv_Disclaimer := v_Empty_String;
      END;

      -- assign final inventory download list to the OUT parameter

      o_Inventory_Download_Object :=
         WCT_INVENTORY_DOWNLOAD_OBJECT (v_Inventory_Download_List,
                                        lv_Date_Time_String,
                                        lv_Disclaimer);
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END;

   --Added by satbanda for Q4FY17 - April Release <Start>

   PROCEDURE P_APPROVEDQUOTE_EXCLUDE (
      i_load_type                         VARCHAR2,               --QUOTE/LINE/EXCLUDE
      i_min_row                           VARCHAR2,
      i_max_row                           VARCHAR2,
      i_sort_column_name                  VARCHAR2,
      i_sort_column_by                    VARCHAR2,
      i_user_id                           VARCHAR2,
      i_quote_id                          VARCHAR2,
      i_cust_name                         VARCHAR2,
      i_created_date                      VARCHAR2,
      i_created_by                        VARCHAR2,
      i_deal_value                        NUMBER,
      i_status                            VARCHAR2,
      i_part_number                       VARCHAR2,
      o_approvedquote_tab      OUT NOCOPY WCT_QUOTE_EXCL_TAB,
      o_quote_detail_tab       OUT NOCOPY RCEC_RETRIEVE_LINE_TAB,
      o_display_count          OUT NOCOPY NUMBER)
   AS
      lv_approvedquote_tab   WCT_QUOTE_EXCL_TAB := WCT_QUOTE_EXCL_TAB ();
      lv_quote_line_list     RCEC_RETRIEVE_LINE_TAB
                                := RCEC_RETRIEVE_LINE_TAB ();
      lv_display_count       NUMBER := 0;
      lv_cnt_query           VARCHAR2 (32767);
      lv_query               CLOB;
      lv_ext_query           CLOB;
      lv_ws_part             VARCHAR2 (200);
      lv_Approver_Level      VARCHAR2 (200);
      lv_load_type           VARCHAR2 (30);
      lv_min_row             NUMBER;
      lv_max_row             NUMBER;
      lv_sort_column_name    VARCHAR2 (300);
      lv_sort_column_by      VARCHAR2 (300);
      lv_user_id             VARCHAR2 (300);
      lv_quote_id            VARCHAR2 (32767);
      lv_cust_name           VARCHAR2 (300);
      lv_created_date        VARCHAR2 (300);
      lv_created_by          VARCHAR2 (300);
      lv_deal_value          NUMBER;
      lv_status              VARCHAR2 (300);
      lv_part_number         VARCHAR2 (300);
      lv_include_cnt         NUMBER;
      lv_exclude_cnt         NUMBER;
      lv_exceed_cnt          NUMBER;
   BEGIN
      lv_load_type := TRIM (i_load_type);
      lv_min_row := i_min_row;
      lv_max_row := i_max_row;
      lv_sort_column_name := TRIM (i_sort_column_name);
      lv_sort_column_by := TRIM (i_sort_column_by);
      lv_user_id := UPPER (TRIM (i_user_id));
      lv_quote_id := UPPER (TRIM (i_quote_id));
      lv_cust_name := UPPER (TRIM (i_cust_name));
      lv_created_date := TRIM (i_created_date);
      lv_created_by := UPPER (TRIM (i_created_by));
      lv_deal_value := i_deal_value;
      lv_status := UPPER (TRIM (i_status));
      lv_part_number := UPPER (TRIM (i_part_number));


      IF lv_load_type = v_Status_Quote
      THEN
         lv_cnt_query := 'SELECT COUNT(*) ';

         lv_query :=
            ' SELECT WCT_QUOTE_EXCL_OBJECT (
                                                                                    QUOTE_ID,
                                                                                    COMPANY_NAME,
                                                                                    REGION,
                                                                                    CREATED_DATE,
                                                                                    CREATED_BY,
                                                                                    LAST_UPDATED_DATE,
                                                                                    DEAL_VALUE,
                                                                                    NULL,NULL,NULL,NULL,
                                                                                    NULL,NULL,NULL,NULL,
                                                                                    NULL,NULL,NULL,NULL
                                                                                    ) ';
         lv_query:=
            lv_query
            || ' FROM (
                     SELECT  QUOTE_ID,
                             COMPANY_NAME,
                             REGION,
                             CREATED_DATE,
                             CREATED_BY,
                              LAST_UPDATED_DATE,DEAL_VALUE,';

          IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
         THEN

               lv_query :=
                     lv_query
                  || 'ROW_NUMBER()  OVER (ORDER BY '
                  || lv_sort_column_name
                  || ' '
                  || lv_sort_column_by
                  || ' ) AS rnum';

         ELSE
            lv_query := lv_query || 'ROWNUM  rnum';
         END IF;

         lv_query :=
               lv_query
            || ' FROM (SELECT QH.QUOTE_ID,
                                                             COM.COMPANY_NAME,
                                                             COM.REGION,
                                                             QH.CREATED_DATE,
                                                             QH.CREATED_BY,
                                                             QH.LAST_UPDATED_DATE,
                                                             (SELECT ROUND (SUM (requested_quantity * suggested_price), 2)
                                                                 FROM wct_quote_line wql
                                                                WHERE quote_id = qh.quote_id AND approval_status_l1 IN ( ''A'',''P'') AND approval_status_l2 IN ( ''A'',''P'')
                                                                    AND NOT EXISTS (SELECT 1
                                                                                                  FROM  rcec_order_lines rol
                                                                                                WHERE rol.order_line_status  IN (''SUBMITTED'',''DRAFT'',''IN PROGRESS'')
                                                                                                   AND rol.quote_id = wql.quote_id
                                                                                                   AND rol.quote_line_id = wql.line_id)  ) DEAL_VALUE ';



         IF lv_part_number IS NOT NULL
         THEN
            lv_ext_query :=
                  ' AND (UPPER(REQUESTED_PART) LIKE '''
               || '%'
               || lv_part_number
               || '%'
               || ''' OR UPPER(WHOLESALE_PART) LIKE '''
               || '%'
               || lv_part_number
               || '%'
               || ''')';
         END IF;

         lv_ext_query :=
               '   FROM WCT_QUOTE_HEADER QH,
                                WCT_CUSTOMER CUST,
                                WCT_COMPANY_MASTER COM,
                                WCT_STATUS_DETAIL SD
                          WHERE     1 = 1
                                AND QH.CUSTOMER_ID = CUST.CUSTOMER_ID
                                 AND COM.COMPANY_ID = CUST.COMPANY_ID
                                AND QH.STATUS = SD.STATUS
                                AND QH.QUOTE_ID IN (SELECT QL.QUOTE_ID
                                                      FROM WCT_QUOTE_LINE QL
                                                     WHERE QL.QUOTE_ID = QH.QUOTE_ID
                                                       AND QL.APPROVAL_STATUS_L1 IN ( ''A'',''P'')
                                                       AND QL.APPROVAL_STATUS_L2 IN ( ''A'',''P'')'
            || lv_ext_query
             || '
                                                     GROUP BY QL.QUOTE_ID'
                                                    /* HAVING COUNT (QL.LINE_ID) =
                                                            (SELECT COUNT (*)
                                                               FROM WCT_QUOTE_LINE QLI
                                                              WHERE QLI.QUOTE_ID =
                                                                       QL.QUOTE_ID
                                                                       '
            || lv_ext_query*/
            || ')
            --)
                               AND ( TRUNC(QH.LAST_UPDATED_DATE) >= TRUNC(SYSDATE) - 14 OR
                                       EXISTS  (SELECT  quote_id
                                                  FROM RCEC_INCL_EXCL_QUOTES
                                                 WHERE quote_id=qh.quote_id
                                                   AND QUOTE_TYPE=''INCLUDE''
                                                   AND IS_ACTIVE_QUOTE=''Y'')
                                                       )
                               AND NOT EXISTS ( SELECT  quote_id
                                                  FROM RCEC_INCL_EXCL_QUOTES
                                                 WHERE quote_id=qh.quote_id
                                                   AND QUOTE_TYPE=''EXCLUDE''
                                                   AND IS_ACTIVE_QUOTE=''Y'')
                               AND NOT EXISTS      (select 1
                                                        from rcec_order_headers roh,
                                                             rcec_order_lines rol,
                                                             WCT_QUOTE_LINE  wql
                                                        where roh.excess_order_id = ROL.EXCESS_ORDER_ID
                                                        and roh.order_status in (''SUBMITTED'',''DRAFT'',''IN PROGRESS'')
                                                        and rol.quote_id = wql.quote_id
                                                        and rol.quote_line_id = wql.line_id
                                                        and rol.ORDER_LINE_STATUS in (''SUBMITTED'',''DRAFT'',''IN PROGRESS'')
                                                        and wql.quote_id = qh.quote_id'
                                                        || lv_ext_query
                                                        ||' having count(*) >=(select count(*) from WCT_QUOTE_LINE  where quote_id=qh.quote_id and approval_status_l1 IN ( ''A'',''P'') and approval_status_l2 IN ( ''A'',''P'')'
                                                        || lv_ext_query
                                                        ||'))';

         IF lv_user_id IS NOT NULL
         THEN
            lv_ext_query :=
                  lv_ext_query
               || ' AND UPPER(qh.created_by) = '''
               || lv_user_id
               || '''';
         END IF;

         IF lv_quote_id IS NOT NULL
         THEN
            lv_ext_query :=
               lv_ext_query || ' AND QH.QUOTE_ID = ''' || lv_quote_id || '''';
         END IF;

         IF lv_cust_name IS NOT NULL
         THEN
            lv_ext_query :=
                  lv_ext_query
               || ' AND UPPER(COM.COMPANY_NAME) = '''
               || lv_cust_name
               || '''';
         END IF;

         IF lv_created_date IS NOT NULL
         THEN
            lv_ext_query :=
                  lv_ext_query
               || ' AND  TO_DATE(qh.created_date)= TO_DATE('
               || ''''
               || lv_created_date
               || ''',''MM/DD/YYYY'')';
         END IF;

         IF lv_created_by IS NOT NULL
         THEN
            lv_ext_query :=
                  lv_ext_query
               || ' AND UPPER(qh.created_by) = '''
               || lv_created_by
               || '''';
         END IF;

         IF lv_deal_value IS NOT NULL
         THEN
            lv_ext_query :=
                  lv_ext_query
               || ' AND   (SELECT ROUND (SUM (requested_quantity * suggested_price), 2)
                                                                       FROM wct_quote_line wql
                                                                      WHERE quote_id = qh.quote_id
                                                                           AND approval_status_l1 = ''A'' AND approval_status_l2 = ''A''
                                                                           AND NOT EXISTS (SELECT 1 FROM  rcec_order_lines rol
                                                                                                      WHERE rol.order_line_status  IN (''SUBMITTED'',''DRAFT'',''IN PROGRESS'')
                                                                                                      AND rol.quote_id = wql.quote_id
                                                                                                      AND rol.quote_line_id = wql.line_id)  ) = '
               || lv_deal_value
               || '';
         END IF;

         IF lv_status IS NOT NULL
         THEN
            lv_ext_query :=
               lv_ext_query || ' AND QH.STATUS =''' || lv_status || '''';
         ELSE
            lv_ext_query :=
                  lv_ext_query
               || ' AND QH.STATUS IN ('''
               || v_Status_Approved
               || ''','''
               || v_Status_Partial
               || ''','''
               || v_Status_Quote
               || ''','''
               || v_Status_Pending
               || ''')';
         END IF;

         lv_cnt_query := lv_cnt_query || lv_ext_query;

         lv_query := lv_query || lv_ext_query;

         IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
         THEN
            lv_query :=
                  lv_query
               || '  ))  WQ WHERE rnum >='
               || lv_min_row
               || ' AND rnum <='
               || lv_max_row;

            lv_query :=
                  lv_query
               || ' ORDER BY WQ.'
               || lv_sort_column_name
               || ' '
               || lv_sort_column_by;
         ELSE
            lv_query :=
                  lv_query
               || ' AND ROWNUM <= '
               || lv_max_row
               || ' ORDER BY QH.LAST_UPDATED_DATE desc) WHERE rnum >='
               || lv_min_row;
         END IF;


         EXECUTE IMMEDIATE lv_query BULK COLLECT INTO lv_approvedquote_tab;

         EXECUTE IMMEDIATE lv_cnt_query INTO lv_display_count;



         o_approvedquote_tab := lv_approvedquote_tab;
         o_display_count := lv_display_count;
      ELSIF lv_load_type = v_Load_Type_line
      THEN
           SELECT RCEC_RETRIEVE_LINE_OBJECT (
                     QL.LINE_ID,                               --Quote Line Id
                     UPPER (QL.REQUESTED_PART),                -- Request part
                     NVL (
                        QL.WHOLESALE_PART,
                        RCEC_CUSTOMER_PKG.f_get_ws_part (
                           UPPER (ql.REQUESTED_PART),
                           lv_user_id,
                           lv_user_id)),                      --Wholesale Part
                     QL.REQUESTED_QUANTITY,                   --Quote Quantity
                     QL.REQUESTED_QUANTITY * QL.SUGGESTED_PRICE, --Extended Price
                     NULL,
                     QL.SUGGESTED_PRICE,                          --Unit Price
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL --Modified by satbanda on 25th April,2017 for Retrieve lines object additional attribute
                     )
             BULK COLLECT INTO lv_quote_line_list
             FROM WCT_QUOTE_LINE QL
            WHERE     QL.QUOTE_ID = lv_quote_id
                  AND approval_status_l1! = v_Approval_Status_Rejected
                  AND approval_status_l2 != v_Approval_Status_Rejected
                  AND NOT EXISTS
                             (SELECT 1
                                FROM rcec_order_headers roh,
                                     rcec_order_lines rol
                               WHERE     roh.excess_order_id =
                                            ROL.EXCESS_ORDER_ID
                                     AND rol.order_line_status !=
                                            v_Status_Deleted
                                     AND roh.order_status != v_Status_Deleted
                                     AND rol.quote_id = ql.quote_id
                                     AND rol.quote_line_id = ql.line_id)
         ORDER BY QL.LINE_ID;

         o_quote_detail_tab := lv_quote_line_list;
      ELSIF lv_load_type = v_Load_Type_exclude
      THEN
         FOR rqe IN ( SELECT REGEXP_SUBSTR (lv_quote_id, '[^,]+',1, LEVEL) quote_id
                        FROM DUAL
                      CONNECT BY REGEXP_SUBSTR (lv_quote_id, '[^,]+',1, LEVEL)  IS NOT NULL )
         LOOP

            lv_exceed_cnt:=0;
            lv_exclude_cnt:=0;
            lv_include_cnt:=0;

            SELECT count(1)
              INTO lv_include_cnt
              FROM RCEC_INCL_EXCL_QUOTES
             WHERE QUOTE_ID = rqe.quote_id
               AND QUOTE_TYPE = v_Load_Type_include
               AND IS_ACTIVE_QUOTE = v_Flag_Yes;

             SELECT count(1)
              INTO lv_exclude_cnt
              FROM RCEC_INCL_EXCL_QUOTES
             WHERE QUOTE_ID = rqe.quote_id
               AND QUOTE_TYPE = v_Load_Type_exclude
               AND IS_ACTIVE_QUOTE = v_Flag_Yes;

             IF lv_include_cnt>0
             THEN

                UPDATE RCEC_INCL_EXCL_QUOTES
                   SET IS_ACTIVE_QUOTE = v_Flag_No
                 WHERE QUOTE_ID = rqe.quote_id
                   AND QUOTE_TYPE = v_Load_Type_include;

                SELECT count(1)
                  INTO lv_exceed_cnt
                 FROM WCT_QUOTE_HEADER
                WHERE quote_id= rqe.quote_id
                  AND TRUNC(last_updated_date) >= TRUNC(SYSDATE) - 14;

             END IF;

             IF lv_exceed_cnt=0 AND lv_exclude_cnt=0
             THEN

                  BEGIN
                     INSERT INTO RCEC_INCL_EXCL_QUOTES (
                                                         QUOTE_ID,
                                                         QUOTE_TYPE,
                                                         IS_ACTIVE_QUOTE,
                                                         CREATED_BY,
                                                         CREATION_DATE,
                                                         LAST_UPDATED_BY,
                                                         LAST_UPDATED_DATE)
                                               VALUES  (
                                                        rqe.quote_id,
                                                        v_Load_Type_exclude,
                                                        v_Flag_Yes,
                                                        lv_user_id,
                                                        SYSDATE,
                                                        lv_user_id,
                                                        SYSDATE
                                                        );
                  EXCEPTION
                  WHEN OTHERS
                  THEN

                    v_Error_Message := 'Error getting while inserting exculde quotes: ' ||SUBSTR(SQLERRM,1,200);

                     rcec_customer_pkg.p_rcec_error_log (
                        I_module_name     => 'WCT-P_APPROVEDQUOTE_EXCLUDE',
                        I_error_type      => 'ERROR',
                        i_Error_Message   =>    v_Error_Message
                                             || ' LineNo=> '
                                             || DBMS_UTILITY.Format_error_backtrace,
                        I_created_by      => lv_user_id,
                        I_updated_by      => lv_user_id);
                  END;

             END IF;

         END LOOP;
      ELSE
         v_Error_Message :=
            'Load type is not getting from UI for the User: ' || lv_user_id ;

         rcec_customer_pkg.p_rcec_error_log (
            I_module_name     => 'WCT-P_APPROVEDQUOTE_EXCLUDE',
            I_error_type      => 'ERROR',
            i_Error_Message   =>  v_Error_Message,
            I_created_by      => lv_user_id,
            I_updated_by      => lv_user_id);
      END IF;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_Error_Message :=
               'Error occured while executing the WCT_DATA_EXTRACT.P_APPROVEDQUOTE_EXCLUDE API: '
            || SUBSTR (SQLERRM, 1, 200);

         rcec_customer_pkg.p_rcec_error_log (
            I_module_name     => 'WCT-P_APPROVEDQUOTE_EXCLUDE',
            I_error_type      => 'ERROR',
            i_Error_Message   =>    v_Error_Message
                                 || ' LineNo=> '
                                 || DBMS_UTILITY.Format_error_backtrace,
            I_created_by      => lv_user_id,
            I_updated_by      => lv_user_id);
   END P_APPROVEDQUOTE_EXCLUDE;
--Added by satbanda for Q4FY17 - April Release <End>
--Added by satbanda for US131874 - October Release <Start>
   PROCEDURE P_MFGPID_EOS_VALIDATE (
          i_created_by                       VARCHAR2,
          io_tab_eos_flag  IN OUT WCT_PROPERTY_MAPPING_LIST --Existing object using for PID EOS flag
          )
    AS
      lv_created_by VARCHAR2(300);
      ltab_eos_pidlist WCT_PROPERTY_MAPPING_LIST:=WCT_PROPERTY_MAPPING_LIST();
      ltab_eos_pidflag WCT_PROPERTY_MAPPING_LIST:=WCT_PROPERTY_MAPPING_LIST();
      lv_pid_eos_date VARCHAR2(100);
      TYPE product_list is RECORD (PRODUCT_ID VARCHAR2(300));
      TYPE REC_PRODUCT_LIST IS TABLE OF product_list;
      lv_product_list REC_PRODUCT_LIST:=REC_PRODUCT_LIST();
    BEGIN

        ltab_eos_pidlist:=io_tab_eos_flag;

        IF ltab_eos_pidlist.EXISTS(1)
        THEN
            SELECT property_value
             BULK COLLECT INTO lv_product_list
             FROM TABLE (CAST (ltab_eos_pidlist AS WCT_PROPERTY_MAPPING_LIST));
        END IF;

        IF lv_product_list.EXISTS(1)
        THEN
           FOR rec_pid IN 1 .. lv_product_list.Count
           LOOP

               lv_product_list.EXTEND;

                 BEGIN
                     SELECT DISTINCT to_char(rpm.mfg_eos_date,'DD-MON-YYYY')
                       INTO lv_pid_eos_date
                     FROM CRPADM.RC_PRODUCT_MASTER rpm
                    WHERE 1=1
                      AND (refresh_part_number = lv_product_list(rec_pid).product_id  OR
                          common_part_number = lv_product_list(rec_pid).product_id OR
                          xref_part_number = lv_product_list(rec_pid).product_id)
                        ;
                EXCEPTION
                WHEN Others
                THEN
                    BEGIN
                       SELECT DISTINCT to_char(rcpm.eo_last_support_date,'DD-MON-YYYY')
                         INTO lv_pid_eos_date
                         FROM RMKTGADM.RMK_CISCO_PRODUCT_MASTER rcpm
                        WHERE 1=1
                          AND product_id = lv_product_list(rec_pid).product_id ;

                    EXCEPTION
                    WHEN Others
                    THEN
                        v_Error_Message := 'Error while getting mfgPID Validate'||SUBSTR(SQLERRM,1,200)
                                            ||'for Product ID:'||lv_product_list(rec_pid).product_id;

                        lv_pid_eos_date:='E';

                        INSERT INTO WCT_ERROR_LOG
                             VALUES ('P_MFGPID_EOS_VALIDATE',
                                     lv_created_by,
                                     v_Error_Message,
                                     SYSDATE);
                    END;

                END;

                ltab_eos_pidflag.EXTEND;

                ltab_eos_pidflag(rec_pid):=WCT_PROPERTY_MAPPING_OBJECT(lv_pid_eos_date,lv_product_list(rec_pid).product_id);


           END LOOP;
        ELSE
            v_Error_Message := 'There is no productsIds';

                INSERT INTO WCT_ERROR_LOG
                     VALUES ('P_MFGPID_EOS_VALIDATE',
                             lv_created_by,
                             v_Error_Message,
                             SYSDATE);
        END IF;

        io_tab_eos_flag:=ltab_eos_pidflag;

    EXCEPTION
       WHEN Others
        THEN
            v_Error_Message := 'Error while executing P_MFGPID_EOS_VALIDATE procedure'||SUBSTR(SQLERRM,1,200);

            INSERT INTO WCT_ERROR_LOG
                 VALUES ('P_MFGPID_EOS_VALIDATE',
                         lv_created_by,
                         v_Error_Message,
                         SYSDATE);
    END P_MFGPID_EOS_VALIDATE;
  --Added by satbanda for US131874 - October Release <End>

END WCT_DATA_EXTRACT;
/