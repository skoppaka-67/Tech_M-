CREATE OR REPLACE PACKAGE RMKTGADM./*AppDB: 1045319*/            "RC_INV_RECON_ADJ_PKG" 
                                  
AS
   /*
  ****************************************************************************************************************
  * Object Name       :RC_INV_RECON_ADJ_PKG
  *  Project Name : Refresh Central
   * Copy Rights:   Cisco Systems, INC., CALIFORNIA
  * Description       : This API for Inventory Adjustment reconcialiation
  * Created Date: 2nd May, 2017
  ===================================================================================================+
  * Version              Date                     Modified by                     Description
  ===================================================================================================+
   1.0                   2nd May, 2017            satbanda                     Created for Inventory Adjustment Reconciliation
   1.1                   20th July,2017           satbanda                     Modified for US122733 (Sorting and Advanced Filter)
   2.0                   31st Aug,2017            satbanda                     Modified for US134969 (Searching capability for Multiple requests at a time)
   3.0                   12th Jan,2018            satbanda                     Modified for US148664 (Inventory Reconiliation History)
  ===================================================================================================+
   **************************************************************************************************************** */

   v_FVE                  VARCHAR2 (5) := 'FVE';
   v_LRO                  VARCHAR2 (5) := 'LRO';
   v_Excess               VARCHAR2 (10) := 'EXCESS';
   v_recon_job            VARCHAR2 (30) := 'BTS_RECON_JOB';
   v_adjmnt_job           VARCHAR2 (30) := 'BTS_ADJMNT_JOB';
   v_reconciled           VARCHAR2 (30) := 'RECONCILED';
   v_ignored              VARCHAR2 (30) := 'IGNORED';
   v_adjusted             VARCHAR2 (30) := 'ADJUSTED';
   v_processed            VARCHAR2 (30) := 'PROCESSED';
   v_running_sts          VARCHAR2 (10) := 'RUNNING';
   v_completed            VARCHAR2 (10) := 'COMPLETED';
   v_cancelled            VARCHAR2 (10) := 'CANCELLED';

   v_restrict_conf_type   VARCHAR2 (30) := 'DISABLE_RECONCIL';
   v_yes_flag             VARCHAR2 (10) := 'YES';
   v_no_flag              VARCHAR2 (10) := 'NO';
   v_y_flag               VARCHAR2 (10) := 'Y';
   v_n_flag               VARCHAR2 (10) := 'N';

   PROCEDURE P_INV_LOC_RECONCILIATION (
      i_site_loc            IN            VARCHAR2,
      i_reconcile_flag      IN            VARCHAR2,
      i_recon_batch_id      IN            VARCHAR2, --Added by satbanda on 12th Jan,2018 for US148664 Recon History
      i_user_id             IN            VARCHAR2,
      i_min_row                           VARCHAR2,
      i_max_row                           VARCHAR2,
      o_last_loc_run           OUT NOCOPY VARCHAR2,
      o_display_count          OUT NOCOPY NUMBER,
      o_inv_recon_tab          OUT NOCOPY RC_INV_RECON_ADJ_TAB,
      o_inv_recon_all_tab      OUT NOCOPY RC_INV_RECON_ADJ_TAB,
      o_process_check_msg      OUT NOCOPY RC_INV_MESSAGE_TAB);

   PROCEDURE P_INV_RECON_ADJ_PROCESS (
      i_inv_recon_tab       IN            RC_INV_RECON_ADJ_TAB,
      i_user_id             IN            VARCHAR2,
      o_status                 OUT NOCOPY VARCHAR2,
      o_process_check_msg      OUT NOCOPY RC_INV_MESSAGE_TAB);

   PROCEDURE P_INV_RECON_FB02_INFO (
      i_user_id            IN            VARCHAR2,
      o_refresh_lro_dt        OUT NOCOPY VARCHAR2,
      o_refresh_fve_dt        OUT NOCOPY VARCHAR2,
      o_refresh_3a4_dt        OUT NOCOPY VARCHAR2,
      o_restrict_3A4_msg      OUT NOCOPY VARCHAR2,
      o_restrict_lro_msg      OUT NOCOPY VARCHAR2,
      o_restrict_fve_msg      OUT NOCOPY VARCHAR2);

   PROCEDURE P_INV_RECON_SAVE_DATA (
      i_inv_recon_tab   IN            RC_INV_RECON_ADJ_TAB,
      i_user_id         IN            VARCHAR2,
      o_status             OUT NOCOPY VARCHAR2);

   --Added by satbanda on 20th July, 2017 for US122733 (Sorting and Advanced Filter) <Start>
   PROCEDURE P_INV_LOC_RECON_VIEW (
      i_site_loc                             VARCHAR2,
      i_batch_proc_id                        VARCHAR2,
      i_user_id                              VARCHAR2,
      i_min_row                              VARCHAR2,
      i_max_row                              VARCHAR2,
      i_sort_column_name                     VARCHAR2,
      i_sort_column_by                       VARCHAR2,
      i_request_id                           VARCHAR2, --NUMBER,-Modified by satbanda for US134969
      i_program_type                         VARCHAR2, -- item type Retail+Outlet / Excess
      i_refresh_part_number                  CLOB,
      i_rohs_compliant                       VARCHAR2,
      i_total_actual_qty                     NUMBER,
      i_total_ccw_qty                        NUMBER,
      i_total_adjustment                     NUMBER,
      i_total_adjustment_new                 NUMBER,
      i_cdc_shipment_qty                     NUMBER,
      i_cdc_shipment_qty_new                 NUMBER,
      i_cc_shipment_qty                      NUMBER,
      i_cc_shipment_qty_new                  NUMBER,
      i_fb02_on_hand_qty                     NUMBER,
      i_adjustment_allow                     VARCHAR2,
      i_adjustment_allow_new                 VARCHAR2,
      o_inv_recon_tab             OUT NOCOPY RC_INV_RECON_ADJ_TAB,
      o_inv_allrecon_tab          OUT NOCOPY RC_INV_RECON_ADJ_TAB, --Added by satbanda for US134969
      o_search_count              OUT NOCOPY NUMBER,
      o_process_check_msg         OUT NOCOPY RC_INV_MESSAGE_TAB);

   --Added by satbanda on 20th July, 2017 for US122733 (Sorting and Advanced Filter) <End>

   --Added by satbanda on 12th Jan,2018 for US148664 (Reconciliation History) <Start>
   PROCEDURE P_INV_LOC_RECON_HISTORY (
      i_login_user           IN            VARCHAR2,
      o_recon_fve_hist_obj      OUT NOCOPY RC_INV_RECON_HIST_OBJECT,
      o_recon_lro_hist_obj      OUT NOCOPY RC_INV_RECON_HIST_OBJECT);

   FUNCTION F_GET_ADJINV_RETAIL_OUTLET (
      i_tab_recon_inv_data   IN RC_INV_RECON_ADJ_TAB)
      RETURN RC_INV_RECON_ADJ_TAB;
--Added by satbanda on 12th Jan,2018 for US148664 (Reconciliation History) <End>

END RC_INV_RECON_ADJ_PKG;
/