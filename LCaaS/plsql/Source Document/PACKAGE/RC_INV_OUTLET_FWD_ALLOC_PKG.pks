CREATE OR REPLACE PACKAGE RMKTGADM.RC_INV_OUTLET_FWD_ALLOC_PKG
AS
   /*
   ****************************************************************************************************************
   * Object Name  : RC_INV_OUTLET_FWD_ALLOC_PKG
   * Project Name : Refresh Central
   * Copy Rights  : Cisco Systems, INC., CALIFORNIA
   * Description  : Forward Outlet Allocation
   * Created Date : 11-MAR-2019
   ===================================================================================================+
   * Version   Date            Modified by                     Description
   ===================================================================================================+
     1.0       11-MAR-2019     csirigir                        First Draft.

   ===================================================================================================+
   **************************************************************************************************************** */

   PROCEDURE RC_INV_OUTLET_FWD_ALLOC_PROC;
   
   PROCEDURE RC_MAIN;

   PROCEDURE RC_OUTLET_VALIDATION;

   PROCEDURE RC_OUTLET_VERIFICATION_SCRIPT;

   PROCEDURE RC_CCW_DATA_UPDATE;

   PROCEDURE RC_EXCLUDE_OUTLET_ALLOC_PROC;

   PROCEDURE RC_DELTA_OUTLET_TEMPLATE (
        o_delta_excel_list   OUT RC_DELTA_OUTLET_LIST);

   PROCEDURE RC_DELTA_OUTLET_PIDS_UPLOAD (
        i_user_id             IN VARCHAR2,
        i_upload_id           IN NUMBER,
        i_delta_outlet_pids   IN RC_DELTA_OUTLET_LIST);

   PROCEDURE DELTA_OUTLET_PIDS_EMAIL (i_uploadId IN NUMBER);  
   
END RC_INV_OUTLET_FWD_ALLOC_PKG;
/