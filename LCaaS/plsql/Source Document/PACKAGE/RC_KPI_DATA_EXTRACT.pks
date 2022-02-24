CREATE OR REPLACE PACKAGE CRPREP./*AppDB: 1039144*/          "RC_KPI_DATA_EXTRACT" 
                                 
/***********************************************************************************************************
    || Object Name    : RC_KPI_DATA_EXTRACT
    || Modules        : KPI report
    || Description    : Fetching KPI details for differnt KPI screens
    || Modification History
    ||------------------------------------------------------------------------------------------------------
    ||Date              By                  Version        Comments
    ||------------------------------------------------------------------------------------------------------
    ||22-Dec-2016   Sai Chaitanya Garbham     1.0          Initial creation
    ||28-Dec-2016   Sweta Priyadarshi        1.1          Added procedures for advance filters and
    ||                                                          current qrt weekend level KPI details
    ||20-Mar-2017    Sweta Priyadarshi       1.2          Added procedures for intransit details
    ||15-Sept-2017   Sai Chaitanya           2.0          Multiple BPM to single Repair Partner implementation
    ||30-Oct-2017   Sweta Priyadarshi       2.1          Adding Cycle Count Upload
    ||02-Jan-2018  Sweta Priyadarshi       2.2          Adding download for pid with discrepancy
    ||27-Jul-2018  Bhaskar Reddivari       2.3          Automate the KPI Cycle Count Upload by removing the manual upload.
    ||--------------------------------------------------------------------------------------------------------------------
*************************************************************************************************************/
AS
    g_error_msg   VARCHAR2 (2000) := NULL;
    g_flag_yes    CHAR := 'Y';

    PROCEDURE RC_KPI_INITIAL_PAGE_LOAD (
        i_user_id                  IN     VARCHAR2,
        i_repair_partner_id        IN     NUMBER,
        i_bpm                      IN     NUMBER,
        i_year                     IN     NUMBER,
        i_qtr                      IN     VARCHAR2,
        i_tab                      IN     NUMBER,
        o_wk_column_header_list       OUT CRPADM.T_NORMALISED_LIST,
        o_wk_page_load_list           OUT RC_WK_METRIC_DATA_LIST,
        o_qtr_column_header_list      OUT CRPADM.T_NORMALISED_LIST,
        o_qtr_page_load_list          OUT RC_QTR_METRIC_DATA_LIST,
        o_status                      OUT NUMBER);

    PROCEDURE RC_KPI_PC_VS_ACT_QTR_DETAILS (
        i_user_id                 IN     VARCHAR2,
        i_repair_partner          IN     NUMBER,
        i_bpm                     IN     NUMBER,
        i_year                    IN     NUMBER,
        i_qtr                     IN     VARCHAR2,
        o_qtr_page_load_list         OUT RC_PC_VS_ACT_QTR_LIST,
        o_wk_column_header_list      OUT CRPADM.T_NORMALISED_LIST,
        o_status                     OUT NUMBER);

    PROCEDURE RC_KPI_TSRM_VS_PC_QTR_DETAILS (
        i_user_id                 IN     VARCHAR2,
        i_repair_partner          IN     NUMBER,
        i_bpm                     IN     NUMBER,
        i_year                    IN     NUMBER,
        i_qtr                     IN     VARCHAR2,
        o_qtr_page_load_list         OUT RC_KPI_TSRM_PC_QTR_LIST,
        o_wk_column_header_list      OUT CRPADM.T_NORMALISED_LIST,
        o_status                     OUT NUMBER);

    PROCEDURE RC_KPI_FILTERS_LIST (
        i_user_id                  IN     VARCHAR2,
        o_bpm_list                    OUT CRPADM.RC_BPM_LIST,
        o_repair_partner_list         OUT CRPADM.RC_REPAIR_PARTNER_LIST,
        o_fiscal_quarter_list         OUT CRPADM.RC_REFRESH_METHOD_LIST,
        o_fiscal_year_list            OUT CRPADM.RC_PROGRAM_TYPE_LIST,
        o_fiscal_quarter_wk_list      OUT CRPADM.RC_REFRESH_METHOD_LIST,
        o_bts_sites_list              OUT CRPADM.RC_REPAIR_PARTNER_LIST,
        o_status                      OUT NUMBER);

    PROCEDURE RC_KPI_PC_VS_ACT_DETAILS (
        i_user_id                 IN     VARCHAR2,
        i_repair_partner          IN     NUMBER,
        i_bpm                     IN     NUMBER,
        i_year                    IN     NUMBER,
        i_qtr                     IN     VARCHAR2,
        o_wk_column_header_list      OUT CRPADM.T_NORMALISED_LIST,
        o_wk_page_load_list          OUT RC_PC_VS_ACT_WK_LIST,
        o_wk_page_load_total         OUT RC_PC_VS_ACT_WK_LIST,
        o_status                     OUT NUMBER);

    PROCEDURE RC_KPI_TSRM_PC_DETAILS (
        i_user_id                 IN     VARCHAR2,
        i_repair_partner          IN     NUMBER,
        i_bpm                     IN     NUMBER,
        i_year                    IN     NUMBER,
        i_qtr                     IN     VARCHAR2,
        o_wk_column_header_list      OUT CRPADM.T_NORMALISED_LIST,
        o_wk_page_load_list          OUT RC_TSRM_PC_WK_LIST,
        o_wk_page_load_total         OUT RC_TSRM_PC_WK_LIST,
        o_status                     OUT NUMBER);

    PROCEDURE RC_KPI_COMMIT_ACT_PID_DTLS (
        i_user_id                     IN     VARCHAR2,
        i_weekend_date                IN     VARCHAR2,
        i_repair_partner              IN     NUMBER,
        i_bpm                         IN     NUMBER,
        i_year                        IN     NUMBER,
        i_qtr                         IN     VARCHAR2,
        i_part_number                 IN     CRPADM.T_NORMALISED_LIST,
        i_min_range                   IN     NUMBER,
        i_max_range                   IN     NUMBER,
        o_commit_act_pid_dtls_list       OUT RC_COMMIT_ACT_PID_DTLS_LIST,
        o_commit_act_pid_dtls_total      OUT RC_COMMIT_ACT_PID_DTLS_LIST,
        o_total_row_count                OUT NUMBER,
        o_status                         OUT NUMBER);

    PROCEDURE RC_KPI_TSRM_PC_PID_DTLS (
        i_user_id                  IN     VARCHAR2,
        i_weekend_date             IN     VARCHAR2,
        i_repair_partner           IN     NUMBER,
        i_bpm                      IN     NUMBER,
        i_year                     IN     NUMBER,
        i_qtr                      IN     VARCHAR2,
        i_part_number              IN     CRPADM.T_NORMALISED_LIST,
        i_min_range                IN     NUMBER,
        i_max_range                IN     NUMBER,
        o_tsrm_pc_pid_dtls_list       OUT RC_TSRM_PC_PID_DTLS_LIST,
        o_tsrm_pc_pid_dtls_total      OUT RC_TSRM_PC_PID_DTLS_LIST,
        o_total_row_count             OUT NUMBER,
        o_status                      OUT NUMBER);

    PROCEDURE RC_KPI_SAVE_OVERRIDDEN_KPI (
        i_user_id               IN     VARCHAR2,
        i_repair_partner_id     IN     NUMBER,
        i_bpm_id                IN     NUMBER,
        i_year                  IN     NUMBER,
        i_qtr                   IN     VARCHAR2,
        i_overridden_qtd_list   IN     RC_KPI_OVERRIDDEN_QTD_LIST,
        o_status                   OUT NUMBER);

    PROCEDURE RC_KPI_INTRANSIT_DETAILS (
        i_user_id                 IN     VARCHAR2,
        i_repair_partner_id       IN     NUMBER,
        i_bpm                     IN     NUMBER,
        i_year                    IN     NUMBER,
        i_qtr                     IN     VARCHAR2,
        o_wk_column_header_list      OUT CRPADM.T_NORMALISED_LIST,
        o_wk_page_load_list          OUT RC_WK_TRANSIT_DATA_LIST,
        o_wk_page_load_total         OUT RC_WK_TRANSIT_DATA_LIST,
        o_box_link                   OUT VARCHAR2,
        o_status                     OUT NUMBER);

    PROCEDURE RC_KPI_SAVE_INTRANSIT (
        i_user_id             IN     VARCHAR2,
        i_repair_partner_id   IN     NUMBER,
        i_bpm                 IN     NUMBER,
        i_year                IN     NUMBER,
        i_qtr                 IN     VARCHAR2,
        i_wk_page_load_list   IN     RC_WK_TRANSIT_DATA_LIST,
        o_status                 OUT NUMBER);

    PROCEDURE RC_KPI_CYCLE_COUNT_DETAILS (
        i_user_id                 IN     VARCHAR2,
        i_repair_partner_id       IN     NUMBER,
        i_bpm                     IN     NUMBER,
        i_year                    IN     NUMBER,
        i_qtr                     IN     VARCHAR2,
        i_bts_site                IN     NUMBER,
        o_wk_column_header_list      OUT CRPADM.T_NORMALISED_LIST,
        o_wk_page_load_list          OUT RC_CYCLE_COUNT_DATA_LIST,
        o_box_link                   OUT VARCHAR2,
        o_status                     OUT NUMBER);

    PROCEDURE RC_KPI_SAVE_CYCLE_COUNT (
        i_user_id             IN     VARCHAR2,
        i_repair_partner_id   IN     NUMBER,
        i_bpm                 IN     NUMBER,
        i_year                IN     NUMBER,
        i_qtr                 IN     VARCHAR2,
        i_bts_site            IN     NUMBER,
        i_wk_page_load_list   IN     RC_CYCLE_COUNT_DATA_LIST,
        o_status                 OUT NUMBER);

    PROCEDURE RC_KPI_SAVE_NO_DISCREPANCY (
        i_user_id                 IN     VARCHAR2,
        i_c3_bts_cycle_count_id   IN     NUMBER,
        i_repair_partner_id       IN     NUMBER,
        i_qtr_number              IN     VARCHAR2,
        i_weekend_date            IN     VARCHAR2,
        o_status                     OUT NUMBER);

    PROCEDURE RC_KPI_EMAIL_CONTENT (
        i_uploadId        IN NUMBER,
        rc_invalid_list   IN RC_CYCLE_COUNT_UPLOAD_INV_LIST);

    PROCEDURE RC_KPI_DOWNLOAD_CYCLE_COUNT (
        i_user_id                     IN     VARCHAR2,
        i_repair_partner_id           IN     NUMBER,
        i_bpm                         IN     NUMBER,
        i_year                        IN     NUMBER,
        i_qtr                         IN     VARCHAR2,
        o_cycle_count_download_list      OUT RC_CYCLE_COUNT_DOWNLOAD_LIST,
        o_msg                            OUT VARCHAR2,
        o_status                         OUT NUMBER);
END RC_KPI_DATA_EXTRACT;
/