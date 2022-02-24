CREATE OR REPLACE PACKAGE RMKTGADM./*AppDB: 1039656*/            "RC_INV_C3_CYCLE_COUNT_PKG" 
AS
 /*
****************************************************************************************************************
* Object Name       :RC_INV_INTRANS_SHIPMENTS
*  Project Name : Refresh Central
 * Copy Rights:   Cisco Systems, INC., CALIFORNIA
* Description       : This API for Inventory Adjustment reconcialiation
* Created Date: 2nd May, 2017
===================================================================================================+
* Version              Date                     Modified by                     Description
===================================================================================================+
 1.0                   27th Nov, 2017            sridvasu                     Created for C3 Cycle count Report. 
 1.1                   14th Sep, 2018            sridvasu                     As part of US224425 for DGI Reconciliation access to RP
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
 
PROCEDURE P_RC_INV_C3_CYCLECNT_LOAD;

PROCEDURE P_RC_ORG_SUBINV_ENTRY_STATUS (
                                        i_login_user IN VARCHAR2, -- Added as part of US224425 for DGI Recon access to RP on 14-SEP-2018
                                        i_user_role IN VARCHAR2, -- Added as part of US224425 for DGI Recon access to RP on 14-SEP-2018
                                        i_report_run_date IN VARCHAR2,
                                        O_TO_ORG OUT T_TO_ORG_TBL,
                                        O_TO_SUBINV OUT T_TO_SUBINV_TBL,
                                        O_ENTRY_STATUS OUT T_ENTRY_STATUS_TBL,
                                        O_RPT_RUN_DATE OUT T_RPT_RUN_DATE_TBL,
                                        o_report_run_message OUT VARCHAR2);
                                        
PROCEDURE P_RC_INV_C3_CYCLECNT_LOAD_UI
    (    
    i_part_number            VARCHAR2,
    i_zcode                 VARCHAR2,
    i_subinv              VARCHAR2,
    i_entry_status           VARCHAR2,
    i_report_run_date       VARCHAR2,
    i_min_row                NUMBER,
    i_max_row                NUMBER,
    i_sort_column_name       VARCHAR2,
    i_sort_column_by         VARCHAR2,
    o_c3_cyclecount  OUT NOCOPY  RC_INV_C3_CYCLECNT_TAB,
    o_count                OUT NOCOPY  NUMBER,
    o_report_run_message   OUT NOCOPY VARCHAR2);   
    
PROCEDURE P_RC_INV_C3_CYCLECNT_SUM_LOAD
    (    
    i_zcode                 VARCHAR2,
    i_subinv              VARCHAR2,
    i_min_row                NUMBER,
    i_max_row                NUMBER,
    i_sort_column_name       VARCHAR2,
    i_sort_column_by         VARCHAR2,
    o_c3_sum_cyclecount  OUT NOCOPY  RC_INV_C3_CYCLECNT_SUM_TAB,
    o_count                OUT NOCOPY  NUMBER);                                         

v_message   VARCHAR2(32767);

END;
/