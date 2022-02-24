CREATE OR REPLACE PACKAGE CRPREP./*AppDB: 1041330*/          "RC_SCRAP_PART_REDUCTION"                  
AS
   PROCEDURE RC_UPLOAD_SCRAP_DETAILS (
        i_user_id       IN  VARCHAR2,
        i_user_role     IN  VARCHAR2,
        i_scrap_details_list   IN RC_SCRAP_DETAILS_LIST,
         i_excel_file    IN  BLOB,
        o_upload_status OUT NUMBER);
   PROCEDURE RC_SCRAP_DATA_EXTRACT(i_user_id VARCHAR2,i_min NUMBER, i_max NUMBER,o_execution_date OUT VARCHAR2,o_total_row_count OUT NUMBER,
      o_scrap_reduce_list       OUT RC_SCRAP_REDUCE_LIST);
PROCEDURE RC_SCRAP_REDUCTION_CALC(i_upload_id    IN  NUMBER);
   PROCEDURE GLOBAL_UPLOADER_EMAIL (
      i_uploadId           IN NUMBER,
      i_status           IN NUMBER);
END RC_SCRAP_PART_REDUCTION;
/