CREATE OR REPLACE PACKAGE RMKTGADM./*AppDB: 1032174*/                                                                                                               "RC_INV_OPEN_DELIVERABLES_PKG"                      
AS

 /*
****************************************************************************************************************
* Object Name       :RC_INV_OPEN_DELIVERABLES_PKG
*  Project Name : Refresh Central
 * Copy Rights:   Cisco Systems, INC., CALIFORNIA
* Description       : This API for Open Deliverables UI Report.
* Created Date: 4th June, 2018
===================================================================================================+
* Version              Date                     Modified by                     Description
===================================================================================================+
 1.0                   04th Jun 2018            sridvasu                     Created for Open Deliverables UI Report.
  
===================================================================================================+
 **************************************************************************************************************** */
   
PROCEDURE P_RC_ERROR_LOG (i_Module_Name        VARCHAR2,
                               i_Entity_Name        VARCHAR2 DEFAULT NULL,
                               i_Entity_ID          VARCHAR2 DEFAULT NULL,
                               i_EXT_Entity_Name    VARCHAR2 DEFAULT NULL,
                               i_EXT_Entity_ID      VARCHAR2 DEFAULT NULL,
                               i_Error_Type         VARCHAR2,
                               i_Error_Message      VARCHAR2,
                               i_Created_by         VARCHAR2,
                               i_UPDATED_BY         VARCHAR2);

PROCEDURE P_RC_INV_OPEN_DELIVER_LOAD;

PROCEDURE RC_INV_MAIN;

PROCEDURE P_RC_INV_FROM_TO_ORG_SUBINV(I_LOGIN_USER VARCHAR2,
                                      I_USER_ROLE VARCHAR2,
                                      O_FROM_ORG OUT T_FROM_ORG_TBL,
                                      O_TO_ORG OUT T_TO_ORG_TBL,
                                      O_TO_SUBINV OUT T_TO_SUBINV_TBL,
                                      I_FROM_ORG VARCHAR2,
                                      I_TO_ORG VARCHAR2,
                                      I_SUB_INV VARCHAR2,
                                      o_report_run_message OUT VARCHAR2);

PROCEDURE P_RC_INV_OPEN_DELIVER_LOAD_UI
    (  
    i_login_user                VARCHAR2,  
    i_user_role                 VARCHAR2,
    i_part_number                VARCHAR2,
    i_order_number            VARCHAR2,
    i_shipment_number        VARCHAR2,
    i_from_org                VARCHAR2,
    i_to_org                VARCHAR2,
    i_to_subinv                VARCHAR2,
    i_aged_order            VARCHAR2,
    i_min_row                NUMBER,
    i_max_row                NUMBER,
    i_sort_column_name        VARCHAR2,
    i_sort_column_by        VARCHAR2,
    o_inv_open_deliver_data  OUT NOCOPY  RC_INV_OPEN_DELIVER_TAB,
    o_inv_open_deliver_alldata  OUT NOCOPY  RC_INV_OPEN_DELIVER_TAB,
    o_count                OUT NOCOPY  NUMBER);
      
PROCEDURE P_RC_OPEN_DELIVER_AGED_MAIL;  
                                                                                            
FUNCTION F_GET_USER_ZSITES (  i_login_user  IN  VARCHAR2,
                                 i_user_role   IN  VARCHAR2) RETURN RC_VARCHAR_TAB;
                               
v_message   VARCHAR2(32767);

END RC_INV_OPEN_DELIVERABLES_PKG;
/