CREATE OR REPLACE PACKAGE RMKTGADM./*AppDB: 1045300*/            "RMK_INV_TRANSFER_PKG"                                                 
AS

    /*
   ****************************************************************************************************************
   * Object Name       :RMK_INV_TRANSFER_PKG
   *  Project Name : Refresh Central
    * Copy Rights:   Cisco Systems, INC., CALIFORNIA
   * Description       : This API for Inventory Adjustment utility to adjust/transfer inventory between different programs (Retail, Outlet and Excess)
   * Created Date: 9th Jan, 2017
   ===================================================================================================+
   * Version              Date                     Modified by                     Description
   ===================================================================================================+
    1.0                   30th Jan, 2017            satbanda                     Created for Inventory Adjustment utility to adjust/transfer
                                                                                         inventory between different programs (Retail, Outlet and Excess)
    1.1                   2nd  Feb, 2017            satbanda                     Added new function f_get_pending_flag for Restrict the transaction/Adjustment
                                                                                    if any pending or incomplete transaction for respective PID and location.
    1.2                   8th Mar, 2017             satbanda                     Modified for Sorting of Pending transactions
    1.3                   25th July,2017            satbanda                     US123787# Inventory Adjustment Upload feature.
    2.0                   25-Oct-2017               satbanda                     US137794# Inventory transfer requests email notifications
    3.0                   04th Jan,2018             satbanda                     US157355 Trigger Email notification for Refresh Inventory Admin
    3.1                   24th Jan 2018             sridvasu                     US161611# Update comments in 'Additional_Comments' column
    3.2                   14-Jun-2019               sridvasu                     US269991# DGI Transfer - New transaction type
   ===================================================================================================+
    **************************************************************************************************************** */
   v_Retail_Outlet VARCHAR2(30):= 'RETAIL-OUTLET';
   v_Outlet_Retail VARCHAR2(30) :=   'OUTLET-RETAIL';
   v_Adjustment VARCHAR2(30) :=   'ADJUSTMENT';
   v_dgi_transfer VARCHAR2(30) :=   'DGI-TRANSFER'; -- Added on 30-May-2019 for DGI Tranfer changes
   v_rejected VARCHAR2(30) :=   'REJECTED'; --Added on 8thMarch, 2017
   v_invalid_pid_msg  VARCHAR2(50) :=   'Please Enter the valid Refresh PID';
   v_access_pid_msg  VARCHAR2(100) :=   'Non Admin cannot transfer or adjust inventory for WS PID';
   v_admin VARCHAR2(30) :=   'ADMIN';
   --Added for US157355 <Start>
   v_yes_flag VARCHAR2(3):='YES';
   v_no_flag VARCHAR2(3):='NO';
   --Added for US157355 <End>
   v_FVE_Nettable_NonNettable VARCHAR2(30) := 'Nettable-2-NonNettable';
   v_FVE_NonNettable_Nettable VARCHAR2(30) := 'NonNettable-2-Nettable';

   PROCEDURE P_INV_TRANSFER (
      i_part_number      IN            VARCHAR2,
      i_trans_type       IN            VARCHAR2,
      o_trans_info_tab      OUT NOCOPY RMK_INV_TRANSFER_INFO_TAB,
      o_trans_dtl_tab       OUT NOCOPY RMK_INV_TRANSFER_DTL_TAB,
      o_trans_status_tab OUT NOCOPY RMK_INV_MOVE_STATUS_TAB);

   PROCEDURE P_INV_TRANSREQ_VIEW (
      i_load_view                        VARCHAR2,--Added on 8thMarch, 2017
      i_min_row                          VARCHAR2,
      i_max_row                          VARCHAR2,
      i_sort_column_name                 VARCHAR2,
      i_sort_column_by                   VARCHAR2,
      i_request_id                       NUMBER,
      i_part_number                      VARCHAR2,
      i_transaction_type                 VARCHAR2,
      i_program_type                     VARCHAR2,
      i_site_code                        VARCHAR2,
      i_from_subinv                      VARCHAR2,
      i_to_subinv                        VARCHAR2,      
      i_rohs_compliant_flag              VARCHAR2,
      i_requested_by                     VARCHAR2,
      i_request_from_date                VARCHAR2,
      i_request_to_date                  VARCHAR2,
      i_approved_by                      VARCHAR2,
      i_approv_from_date                 VARCHAR2,
      i_approv_to_date                   VARCHAR2,
      i_process_sts                      VARCHAR2,
      o_display_count         OUT NOCOPY NUMBER,
      o_trans_status_tab OUT NOCOPY RMK_INV_MOVE_STATUS_TAB);

    PROCEDURE P_INV_SU_TRANSREQ (
      i_part_number      IN VARCHAR2,
      i_request_type     IN VARCHAR2,                        -- CREATE/UPDATE
      i_trans_type       IN VARCHAR2, --RETAIL-OUTLET, OUTLET-RETAIL, ADJUSTMENT
      i_from_prgm_type   IN VARCHAR2,
      i_to_prgm_type     IN VARCHAR2,
      i_rohs_check_needed  IN VARCHAR2,
      i_mos                IN NUMBER,
      i_retail_max         IN NUMBER,
      i_outlet_cap         IN NUMBER,
      i_ytd_avg_sales_price IN NUMBER,
      i_created_by     IN VARCHAR2,
      i_approved_by  IN VARCHAR2,
      i_approve_sts   IN VARCHAR2,-- Auto-Approved/ Pending, Approved, Rejected
      i_process_status IN VARCHAR2, --PROCESSED/ NEW, PROCESSED
      i_auto_notify_mail     IN VARCHAR2, --Added for US157355 on 4th Jan,2018
      o_trans_dtl_tab    IN RMK_INV_TRANSFER_DTL_TAB);

      PROCEDURE P_INV_PID_VALIDATE (
      i_part_number  IN         VARCHAR2,
      i_created_by   IN         VARCHAR2,
      i_user_role    IN         VARCHAR2,
      o_err_message  OUT NOCOPY VARCHAR2,
      o_pid_lookups  OUT NOCOPY VARCHAR2
      );

      PROCEDURE P_INV_PIDS_UPLOADER (
       i_uploaded_by       IN  VARCHAR2,
      io_upload_dtl_tab   IN OUT  RMK_INV_TRANSFER_DTL_TAB,
      o_trans_status_tab  OUT NOCOPY RMK_INV_MOVE_STATUS_TAB,
      o_err_message       OUT NOCOPY VARCHAR2,
      o_upload_sts        OUT NOCOPY VARCHAR2 -- SUCCESS/FAILED
      );

      PROCEDURE RC_INV_TRANS_NOTIFY_MAIL; --US137794
      
      PROCEDURE P_INV_COMMENTS_UPDATE (
         i_additional_comments_tab   IN T_REQ_ID_COMMENTS_TAB,
         i_user_id               IN VARCHAR2);                                  

      Function f_get_outletelg_flag (
      i_part_number VARCHAR2,
      i_mos    NUMBER
      )
      RETURN VARCHAR2;

      Function f_get_pending_flag (
      i_part_number VARCHAR2,
      i_location    VARCHAR2,
      i_rohs_compliant VARCHAR2
      )
      RETURN VARCHAR2;
/* Start added as part of DGI Transfer changes on 14-Jun-2019 */      
      PROCEDURE P_RC_INV_SITE_CODE ( o_rc_inv_site_code   OUT NOCOPY RC_INV_SITE_CODE_TAB,
                                   o_rc_inv_from_subinv   OUT NOCOPY RC_INV_FROM_SUBINV_TAB,
                                   o_rc_inv_to_subinv   OUT NOCOPY RC_INV_TO_SUBINV_TAB);
      
      PROCEDURE P_TO_SUBINV_ADJ_QTY_VALIDATION (i_c3_onhand_qty	NUMBER,
										i_to_subinv	VARCHAR2,
										i_adj_qty	NUMBER,
										o_message	OUT NOCOPY VARCHAR2);      

      PROCEDURE P_RC_INV_TRANS_DGI_NOTIFY_MAIL;
      
      PROCEDURE P_RC_INV_DGI_APPROVAL_NOTIFY;
      
      Function f_get_pending_dgi_flag (
      i_part_number VARCHAR2,
      i_location    VARCHAR2,
      i_from_subinv VARCHAR2
      )
      RETURN VARCHAR2;      
/* End added as part of DGI Transfer changes on 14-Jun-2019 */

/* US223935-Automation of daily FVE inventory movements - Phase 2 changes Starts*/
      PROCEDURE RC_FVE_INV_MOVE_AUTOMATION;
/* US223935-Automation of daily FVE inventory movements - Phase 2 changes Starts*/ 
END RMK_INV_TRANSFER_PKG;
/