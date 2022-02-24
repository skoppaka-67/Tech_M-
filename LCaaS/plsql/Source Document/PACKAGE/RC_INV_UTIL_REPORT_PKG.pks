CREATE OR REPLACE PACKAGE CRPADM./*AppDB: 1045348*/          "RC_INV_UTIL_REPORT_PKG"                         
AS
/*
  ****************************************************************************************************************
  * Object Name       :RC_INV_UTIL_REPORT_PKG
  *  Project Name : lNVENTORY
   * Copy Rights:   Cisco Systems, INC., CALIFORNIA
  * Description       : This API for inventory Report  utility
  * Created Date:
  ===================================================================================================+
  * Date         Modified by     Bug/Case #           Revision                   Description
  ===================================================================================================+
    13-Sep-2017  satbanda                             1.0                       Created new version
    14-Sep-2017  sridvasu                             1.1                       Added RC_INV_PID_ASSIGN_EXCEPTN_RPT
    05-Oct-2017  satbanda  (Satyanarayana Bandaru)    1.2                       Modified GET_Z05_MOV_VALUE function for new requirement.
    06-Oct-2017  satbanda  (Satyanarayana Bandaru)    1.3                       Added function fn_get_alldgi_inv for calculating GDGI Quanity.
    25-Oct-2017  satbanda  (Satyanarayana Bandaru)    2.0                       Added procedure for Inventory transfer requests
  ===================================================================================================+
 */
    v_message VARCHAR2(32767);

    PROCEDURE RC_INV_DISPOSITION_MAIL(i_mail_from  IN VARCHAR2,
                                      i_mail_to    IN VARCHAR2);

    PROCEDURE RC_INV_PID_ASSIGN_EXCEPTN_RPT;
    
    PROCEDURE INV_PID_ASSIGN_EXCEPTN_RPT_V2 (STATUS OUT VARCHAR2);

    FUNCTION GET_Z05_MOV_VALUE (NON_EU_B      NUMBER,
                                                  NON_EU_D      NUMBER,
                                                  EU_B          NUMBER,
                                                  EU_D          NUMBER,
                                                  LRO_B         NUMBER,
                                                  DG_Z29_Z26    NUMBER,
                                                  FVE_FGI       NUMBER,
                                                  DG_Z05        NUMBER,
                                                  LRO_FGI       NUMBER)
    RETURN VARCHAR2;

    FUNCTION fn_get_alldgi_inv (   i_user_id        VARCHAR2,
                                   i_site_code      VARCHAR2, --comma seperated values if input is multiple sites
                                   i_part_number    VARCHAR2,
                                   i_yield_flag     VARCHAR2 DEFAULT 'N')
    RETURN VARCHAR2;

    PROCEDURE RC_INV_TRANS_NOTIFY_MAIL;


   END RC_INV_UTIL_REPORT_PKG;
/