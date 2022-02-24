CREATE OR REPLACE PACKAGE BODY RMKTGADM./*AppDB: 1041258*/                      "RC_INV_C3_CYCLE_COUNT_PKG" 
AS
 /*
****************************************************************************************************************
* Object Name       :RC_INV_C3_CYCLE_COUNT_PKG
*  Project Name : Refresh Central
 * Copy Rights:   Cisco Systems, INC., CALIFORNIA
* Description       : This API for C3 Cycle Count Report
* Created Date: 27th Nov, 2017
===================================================================================================+
* Version              Date                     Modified by                     Description
===================================================================================================+
 1.0                   27th Nov, 2017            sridvasu                     Created for C3 Cycle count Report.
 1.1                   22nd Dec. 2017            sridvasu                     Added conditions for Report Run Date
 1.2                   19th Jul, 2018            sridvasu                     Renamed the display message from C3 Cycle Count Report to DGI Reconciliation Report
 1.3                   14th Sep, 2018            sridvasu                     As part of US224425 for DGI Reconciliation access to RP
 1.4                   22nd Feb, 2019            sridvasu                     Modified code to restrict Z32 site  
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
                               i_UPDATED_BY         VARCHAR2)
   AS
      l_errid   NUMBER;
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      v_message := NULL;

      SELECT RMK_INV_ERROR_S.NEXTVAL INTO l_errid FROM DUAL;

      INSERT INTO RMK_INV_ERROR_LOG (ERR_ID,
                                     Module_Name,
                                     Entity_Name,
                                     Entity_ID,
                                     EXT_Entity_Name,
                                     EXT_Entity_ID,
                                     ERROR_TYPE,
                                     Error_Message,
                                     CREATED_BY,
                                     CREATION_DATE,
                                     LAST_UPDATED_BY,
                                     LAST_UPDATE_DATE)
           VALUES (l_errid,
                   i_Module_Name,
                   i_Entity_Name,
                   i_Entity_ID,
                   i_EXT_Entity_Name,
                   i_EXT_Entity_ID,
                   i_Error_Type,
                   i_Error_Message,
                   i_CREATED_BY,
                   SYSDATE,
                   i_UPDATED_BY,
                   SYSDATE);

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_message :=
               SUBSTR (SQLERRM, 1, 200)
            || ' i_Module_Name->'
            || i_Module_Name
            || ' i_Entity_Name->'
            || i_Entity_Name
            || ' i_Entity_ID->'
            || i_Entity_ID
            || ' i_EXT_Entity_Name->'
            || i_EXT_Entity_Name
            || ' i_EXT_Entity_ID->'
            || i_EXT_Entity_ID
            || ' i_Error_Type->'
            || i_Error_Type
            || ' i_Error_Message->'
            || i_Error_Message
            || ' i_CREATED_BY->'
            || i_CREATED_BY
            || ' i_UPDATED_BY->'
            || i_UPDATED_BY;

         SELECT RMK_INV_ERROR_S.NEXTVAL INTO l_errid FROM DUAL;

         INSERT INTO RMK_INV_ERROR_LOG (ERR_ID,
                                        Module_Name,
                                        Error_Message,
                                        CREATION_DATE)
              VALUES (l_errid,
                      'ERROR_LOG',
                      v_message,
                      SYSDATE);

         COMMIT;
   END P_RC_ERROR_LOG;
   
PROCEDURE P_RC_INV_C3_CYCLECNT_LOAD
AS

lv_time      CHAR(2);

BEGIN

-->> Archive Mechanism to keep last 18 months data previous fiscal calendar months

    DELETE FROM RC_INV_C3_CYCLECNT
          WHERE TRUNC (REPORT_RUN_DATE) > ADD_MONTHS (TRUNC (SYSDATE), -18)
                AND REPORT_RUN_DATE < (SELECT MIN(CALENDAR_DATE) FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM A
                                        WHERE FISCAL_MONTH_ID IN (SELECT FISCAL_MONTH_ID FROM RMKTGADM.CDM_TIME_HIERARCHY_DIM
                                                                    WHERE CALENDAR_DATE = ADD_MONTHS (TRUNC (SYSDATE), -18)));

    COMMIT;
    
    
    SELECT TO_CHAR(SYSDATE, 'PM') INTO lv_time FROM DUAL;


    IF lv_time = 'AM' THEN
    
        UPDATE RC_INV_C3_CYCLECNT SET STATUS_FLAG = 'N' 
            WHERE ZCODE IN (SELECT CONFIG_NAME FROM RC_INV_CONFIG WHERE CONFIG_TYPE = '4 AM PST') AND STATUS_FLAG = 'Y';    

        INSERT INTO RC_INV_C3_CYCLECNT
            SELECT 
            INVENTORY_ITEM_ID,
            PART_NUMBER,
            ZCODE,
            CYCLE_COUNT_HEADER_NAME,
            SUBINVENTORY,
            ADJUSTMENT_QUANTITY,
            PARTNER_QUANTITY,
            C3_QUANTITY,
            REPORT_RUN_DATE,
            CREATION_DATE,
            LAST_UPDATE_DATE,
            decode(ENTRY_STATUS_CODE, 1, 'Uncounted', 2, 'Pending Approval', 3, 'Recount', 4, 'Rejected', 5, 'Completed') ENTRY_STATUS_CODE,
            STATUS_FLAG
                FROM RC_INV_C3_CYCLECNT_STG WHERE ZCODE IN (SELECT CONFIG_NAME FROM RC_INV_CONFIG WHERE CONFIG_TYPE = '4 AM PST') AND STATUS_FLAG = 'Y';
                
    ELSIF lv_time = 'PM' THEN  
    
        UPDATE RC_INV_C3_CYCLECNT SET STATUS_FLAG = 'N' 
            WHERE ZCODE IN (SELECT CONFIG_NAME FROM RC_INV_CONFIG WHERE CONFIG_TYPE = '9 PM PST') AND STATUS_FLAG = 'Y';     

        INSERT INTO RC_INV_C3_CYCLECNT
            SELECT 
            INVENTORY_ITEM_ID,
            PART_NUMBER,
            ZCODE,
            CYCLE_COUNT_HEADER_NAME,
            SUBINVENTORY,
            ADJUSTMENT_QUANTITY,
            PARTNER_QUANTITY,
            C3_QUANTITY,
            REPORT_RUN_DATE,
            CREATION_DATE,
            LAST_UPDATE_DATE,
            decode(ENTRY_STATUS_CODE, 1, 'Uncounted', 2, 'Pending Approval', 3, 'Recount', 4, 'Rejected', 5, 'Completed') ENTRY_STATUS_CODE,
            STATUS_FLAG
                FROM RC_INV_C3_CYCLECNT_STG WHERE ZCODE IN (SELECT CONFIG_NAME FROM RC_INV_CONFIG WHERE CONFIG_TYPE = '9 PM PST') AND STATUS_FLAG = 'Y';      

    END IF;
    
    COMMIT;
    
        EXCEPTION
              WHEN OTHERS
              THEN
                v_message:=SUBSTR(SQLERRM,1,200);

                 P_RC_ERROR_LOG (
                    I_module_name       => 'P_RC_INV_C3_CYCLECNT_LOAD',
                    I_entity_name       => NULL,
                    I_entity_id         => NULL,
                    I_ext_entity_name   => NULL,
                    I_ext_entity_id     => NULL,
                    I_error_type        => 'EXCEPTION',
                    i_Error_Message     =>    'Error getting while loading C3 Cycle count table '
                                           || ' <> '
                                           || v_message
                                           || ' LineNo=> '
                                           || DBMS_UTILITY.Format_error_backtrace,
                    I_created_by        => 'RC_INV_C3_CYCLE_COUNT_PKG',
                    I_updated_by        => 'RC_INV_C3_CYCLE_COUNT_PKG');    

END P_RC_INV_C3_CYCLECNT_LOAD;

PROCEDURE P_RC_ORG_SUBINV_ENTRY_STATUS (i_login_user IN VARCHAR2, -- Added as part of US224425 for DGI Recon access to RP on 14-SEP-2018
                                        i_user_role IN VARCHAR2, -- Added as part of US224425 for DGI Recon access to RP on 14-SEP-2018
                                        i_report_run_date IN VARCHAR2,
                                        O_TO_ORG OUT T_TO_ORG_TBL,
                                        O_TO_SUBINV OUT T_TO_SUBINV_TBL,
                                        O_ENTRY_STATUS OUT T_ENTRY_STATUS_TBL,
                                        O_RPT_RUN_DATE OUT T_RPT_RUN_DATE_TBL,
                                        o_report_run_message OUT VARCHAR2)
AS

    lv_to_org               T_TO_ORG_TBL;
    lv_to_subinv            T_TO_SUBINV_TBL;
    lv_entry_status         T_ENTRY_STATUS_TBL;
    lv_rpt_run_date         T_RPT_RUN_DATE_TBL;
    lv_report_run_date      VARCHAR2(200) := '';
    lv_r_partner_id         NUMBER; -- Added as part of US224425 for DGI Recon access to RP on 14-SEP-2018
    lv_zcode1               VARCHAR2(1000);--VARCHAR2(10); 
    lv_zcode2               VARCHAR2(1000);
    lv_report_run_date1     VARCHAR2(50);
    lv_report_run_date2     VARCHAR2(50);
    lv_report_run_message   VARCHAR2(500) := NULL;

BEGIN
        
        lv_to_org       := T_TO_ORG_TBL();
        lv_to_subinv    := T_TO_SUBINV_TBL();
        lv_entry_status := T_ENTRY_STATUS_TBL();
        lv_rpt_run_date := T_RPT_RUN_DATE_TBL();
        lv_report_run_date := i_report_run_date;
            
/* Start As part of US224425 Commented below code for DGI Recon access to RP on 14-SEP-2018 by sridvasu */      
        
--        BEGIN
--                 
--        SELECT T_TO_ORG_OBJ (ZCODE)
--          BULK COLLECT INTO lv_to_org
--          FROM (SELECT DISTINCT zcode
--                  FROM crpadm.RC_PRODUCT_REPAIR_PARTNER
--                 WHERE zcode IS NOT NULL AND active_flag = 'Y' order by zcode);  
--        
--        EXCEPTION
--              WHEN OTHERS
--              THEN
--                v_message:=SUBSTR(SQLERRM,1,200); 
--                dbms_output.put_line(v_message);
--        END;  

/* End As part of US224425 Commented below code for DGI Recon access to RP 14-SEP-2018 by sridvasu */    

/* Start As part of US224425 Added below code for DGI Recon access to RP on 14-SEP-2018 by sridvasu */ 

        IF i_login_user IS NOT NULL AND (UPPER (i_user_role) NOT LIKE '%ADMIN%' AND UPPER (i_user_role) NOT LIKE '%BPM%') 
         THEN

--            BEGIN
--                SELECT REPAIR_PARTNER_ID
--                  INTO lv_r_partner_id
--                  FROM crpadm.RC_REPAIR_PARTNER_USER_MAP
--                 WHERE user_name = i_login_user;
--             EXCEPTION
--                WHEN OTHERS
--                THEN
--                   lv_r_partner_id := NULL;
--             END;
--
--
--             IF lv_r_partner_id IS NOT NULL
--             THEN
                 
                    SELECT T_TO_ORG_OBJ (ZCODE)
                      BULK COLLECT INTO lv_to_org
                      FROM (SELECT DISTINCT ZCODE
                                    FROM CRPADM.RC_PRODUCT_REPAIR_PARTNER RP
                                         INNER JOIN CRPADM.RC_REPAIR_PARTNER_USER_MAP USR
                                             ON RP.REPAIR_PARTNER_ID = USR.REPAIR_PARTNER_ID
                                   WHERE     ZCODE IS NOT NULL
                                         AND RP.ACTIVE_FLAG = 'Y'
                                         AND USR.ACTIVE_FLAG = 'Y' AND ZCODE <> 'Z32'
                                         AND USER_NAME = i_login_user
                                         ORDER BY ZCODE);
                                         

--                      (SELECT DISTINCT zcode
--                              FROM crpadm.RC_PRODUCT_REPAIR_PARTNER
--                             WHERE zcode IS NOT NULL AND active_flag = 'Y' 
--                             AND zcode <> 'Z32' -->> Added to restrict Z32 on 22-Feb-2019
--                             AND repair_partner_id = lv_r_partner_id order by zcode);
                 
--             END IF;

        ELSE

                    SELECT T_TO_ORG_OBJ (ZCODE)
                      BULK COLLECT INTO lv_to_org
                      FROM (SELECT DISTINCT zcode
                              FROM crpadm.RC_PRODUCT_REPAIR_PARTNER
                             WHERE zcode IS NOT NULL 
                             AND zcode <> 'Z32' -->> Added to restrict Z32 on 22-Feb-2019
                             AND active_flag = 'Y' order by zcode); 

        END IF;           
        
 /* End As part of US224425 Added below code for DGI Recon access to RP on 14-SEP-2018 by sridvasu */
        
        BEGIN
        
        IF lv_report_run_date IS NOT NULL --AND lv_report_run_date <> ''
        THEN
        
/* Start As part of US224425 Commented below code for DGI Recon access to RP on 14-SEP-2018 by sridvasu */         
        
--        SELECT T_TO_SUBINV_OBJ (SUB_INVENTORY_LOCATION)
--          BULK COLLECT INTO lv_to_subinv
--          FROM (SELECT DISTINCT sub_inventory_location
--                  FROM crpadm.RC_SUB_INV_LOC_MSTR 
--                   WHERE SUB_INVENTORY_LOCATION IN (SELECT DISTINCT SUBINVENTORY FROM RC_INV_C3_CYCLECNT 
--                                                        WHERE TRUNC(REPORT_RUN_DATE) = TO_DATE(lv_report_run_date,'MM/DD/YYYY'))
--             order by sub_inventory_location);

/* End As part of US224425 Commented below code for DGI Recon access to RP on 14-SEP-2018 by sridvasu */ 

/* Start As part of US224425 Added below code for DGI Recon access to RP on 14-SEP-2018 by sridvasu */ 

              IF i_login_user IS NOT NULL AND (UPPER (i_user_role) NOT LIKE '%ADMIN%' AND UPPER (i_user_role) NOT LIKE '%BPM%')
              THEN

--                 BEGIN
--                    SELECT REPAIR_PARTNER_ID
--                      INTO lv_r_partner_id
--                      FROM crpadm.RC_REPAIR_PARTNER_USER_MAP
--                     WHERE user_name = i_login_user;
--                 EXCEPTION
--                    WHEN OTHERS
--                    THEN
--                       lv_r_partner_id := NULL;
--                 END;
--
--                 IF lv_r_partner_id IS NOT NULL
--                 THEN

                    SELECT T_TO_SUBINV_OBJ (SUB_INVENTORY_LOCATION)
                      BULK COLLECT INTO lv_to_subinv
                      FROM (SELECT DISTINCT SUBINVENTORY SUB_INVENTORY_LOCATION
                              FROM RC_INV_C3_CYCLECNT
                             WHERE     ZCODE IN (SELECT DISTINCT zcode
                                                   FROM crpadm.RC_PRODUCT_REPAIR_PARTNER RP
                                                   INNER JOIN CRPADM.RC_REPAIR_PARTNER_USER_MAP USR
                                             ON RP.REPAIR_PARTNER_ID = USR.REPAIR_PARTNER_ID
                                                  WHERE RP.ACTIVE_FLAG = 'Y'
                                                    AND USR.ACTIVE_FLAG = 'Y'
                                                    AND USER_NAME = i_login_user)
--                                                        AND repair_partner_id = lv_r_partner_id)
                                   AND ZCODE IS NOT NULL
                                   AND ZCODE <> 'Z32' -->> Added to restrict Z32 on 22-Feb-2019
                                   AND TRUNC (REPORT_RUN_DATE) = TO_DATE(lv_report_run_date,'MM/DD/YYYY')
                                           ORDER BY SUBINVENTORY);
                    
--                 END IF;
              ELSE

                    SELECT T_TO_SUBINV_OBJ (SUB_INVENTORY_LOCATION)
                      BULK COLLECT INTO lv_to_subinv
                      FROM (SELECT DISTINCT SUBINVENTORY SUB_INVENTORY_LOCATION
                              FROM RC_INV_C3_CYCLECNT
                             WHERE     ZCODE IN (SELECT DISTINCT zcode
                                                   FROM crpadm.RC_PRODUCT_REPAIR_PARTNER
                                                  WHERE     active_flag = 'Y')
                                   AND ZCODE IS NOT NULL
                                   AND ZCODE <> 'Z32' -->> Added to restrict Z32 on 22-Feb-2019
                                   AND TRUNC (REPORT_RUN_DATE) = TO_DATE(lv_report_run_date,'MM/DD/YYYY')
                                           ORDER BY SUBINVENTORY);
                                        
              END IF;        

/* End As part of US224425 Added below code for DGI Recon access to RP on 14-SEP-2018 by sridvasu */ 
             
        ELSE
        
        SELECT MAX(TO_CHAR(REPORT_RUN_DATE,'MM/DD/YYYY'))
            INTO lv_report_run_date
            FROM RC_INV_C3_CYCLECNT WHERE STATUS_FLAG = 'Y';
            
/* Start As part of US224425 Commented below code for DGI Recon access to RP on 14-SEP-2018 by sridvasu */
         
--        SELECT T_TO_SUBINV_OBJ (SUB_INVENTORY_LOCATION)
--          BULK COLLECT INTO lv_to_subinv
--          FROM (SELECT DISTINCT sub_inventory_location
--                  FROM crpadm.RC_SUB_INV_LOC_MSTR 
--                   WHERE SUB_INVENTORY_LOCATION IN (SELECT DISTINCT SUBINVENTORY FROM RC_INV_C3_CYCLECNT 
--                                                        WHERE TRUNC(REPORT_RUN_DATE) = TO_DATE(lv_report_run_date,'MM/DD/YYYY'))
--             order by sub_inventory_location);

/* End As part of US224425 Commented below code for DGI Recon access to RP on 14-SEP-2018 by sridvasu */ 

/* Start As part of US224425 Added below code for DGI Recon access to RP on 14-SEP-2018 by sridvasu */ 

              IF i_login_user IS NOT NULL AND (UPPER (i_user_role) NOT LIKE '%ADMIN%' AND UPPER (i_user_role) NOT LIKE '%BPM%') 
              THEN

--                 BEGIN
--                    SELECT REPAIR_PARTNER_ID
--                      INTO lv_r_partner_id
--                      FROM crpadm.RC_REPAIR_PARTNER_USER_MAP
--                     WHERE user_name = i_login_user;
--                 EXCEPTION
--                    WHEN OTHERS
--                    THEN
--                       lv_r_partner_id := NULL;
--                 END;
--
--                 IF lv_r_partner_id IS NOT NULL
--                 THEN

                    SELECT T_TO_SUBINV_OBJ (SUB_INVENTORY_LOCATION)
                      BULK COLLECT INTO lv_to_subinv
                      FROM (SELECT DISTINCT SUBINVENTORY SUB_INVENTORY_LOCATION
                              FROM RC_INV_C3_CYCLECNT
                             WHERE     ZCODE IN (SELECT DISTINCT zcode
                                                   FROM crpadm.RC_PRODUCT_REPAIR_PARTNER RP
                                                   INNER JOIN CRPADM.RC_REPAIR_PARTNER_USER_MAP USR
                                             ON RP.REPAIR_PARTNER_ID = USR.REPAIR_PARTNER_ID
                                                  WHERE RP.ACTIVE_FLAG = 'Y'
                                                    AND USR.ACTIVE_FLAG = 'Y'
                                                    AND USER_NAME = i_login_user)
--                                                        AND repair_partner_id = lv_r_partner_id)
                                   AND ZCODE IS NOT NULL
                                   AND ZCODE <> 'Z32' -->> Added to restrict Z32 on 22-Feb-2019
                                   AND TRUNC (REPORT_RUN_DATE) = TO_DATE(lv_report_run_date,'MM/DD/YYYY')
                                           ORDER BY SUBINVENTORY);
                    
--                 END IF;
              ELSE

                    SELECT T_TO_SUBINV_OBJ (SUB_INVENTORY_LOCATION)
                      BULK COLLECT INTO lv_to_subinv
                      FROM (SELECT DISTINCT SUBINVENTORY SUB_INVENTORY_LOCATION
                              FROM RC_INV_C3_CYCLECNT
                             WHERE     ZCODE IN (SELECT DISTINCT zcode
                                                   FROM crpadm.RC_PRODUCT_REPAIR_PARTNER
                                                  WHERE     active_flag = 'Y')
                                   AND ZCODE IS NOT NULL
                                   AND ZCODE <> 'Z32' -->> Added to restrict Z32 on 22-Feb-2019
                                   AND TRUNC (REPORT_RUN_DATE) = TO_DATE(lv_report_run_date,'MM/DD/YYYY')
                                           ORDER BY SUBINVENTORY);
                                        
              END IF;        

/* End As part of US224425 Added below code for DGI Recon access to RP on 14-SEP-2018 by sridvasu */ 
                     
        END IF;
                  
        EXCEPTION
              WHEN OTHERS
              THEN
                v_message:=SUBSTR(SQLERRM,1,200); 
                dbms_output.put_line(v_message);
        END;                       
             
        
        BEGIN
        
        SELECT T_ENTRY_STATUS_OBJ (CONFIG_NAME)
          BULK COLLECT INTO lv_entry_status
          FROM (SELECT CONFIG_NAME 
                  FROM RC_INV_CONFIG WHERE CONFIG_TYPE = 'C3_CC_ENTRY_STATUSES' order by config_id);
                  
        EXCEPTION
              WHEN OTHERS
              THEN
                v_message:=SUBSTR(SQLERRM,1,200); 
                dbms_output.put_line(v_message);
        END; 
        
        
        BEGIN
                
        SELECT T_RPT_RUN_DATE_OBJ (REPORT_RUN_DATE)
          BULK COLLECT INTO LV_RPT_RUN_DATE
          FROM (SELECT TO_CHAR(REPORT_RUN_DATE,'MM/DD/YYYY') REPORT_RUN_DATE FROM                  
                    (SELECT DISTINCT MAX(REPORT_RUN_DATE) REPORT_RUN_DATE FROM RC_INV_C3_CYCLECNT WHERE STATUS_FLAG = 'N' AND REPORT_RUN_DATE >= SYSDATE-90
                    GROUP BY TO_CHAR(REPORT_RUN_DATE,'MM/DD/YYYY') ORDER BY REPORT_RUN_DATE DESC));  
         
          EXCEPTION
              WHEN OTHERS
              THEN
                v_message:=SUBSTR(SQLERRM,1,200); 
                dbms_output.put_line(v_message);
        END;           
                     
/* Start Added code to display banner message on 17-SEP-2018 by sridvasu */

            IF lv_report_run_date IS NOT NULL 
            THEN
            
              IF i_login_user IS NOT NULL AND (UPPER (i_user_role) NOT LIKE '%ADMIN%' AND UPPER (i_user_role) NOT LIKE '%BPM%')
              THEN
              
--                 BEGIN
--                    SELECT REPAIR_PARTNER_ID
--                      INTO lv_r_partner_id
--                      FROM crpadm.RC_REPAIR_PARTNER_USER_MAP
--                     WHERE user_name = i_login_user;
--                 EXCEPTION
--                    WHEN OTHERS
--                    THEN
--                       lv_r_partner_id := NULL;
--                 END;
--
--                 IF lv_r_partner_id IS NOT NULL
--                 THEN

                    SELECT LISTAGG(ZCODE, ', ') WITHIN GROUP (ORDER BY ZCODE) 
                        INTO lv_zcode1
                    FROM crpadm.RC_PRODUCT_REPAIR_PARTNER RP
                                         INNER JOIN CRPADM.RC_REPAIR_PARTNER_USER_MAP USR
                                             ON RP.REPAIR_PARTNER_ID = USR.REPAIR_PARTNER_ID
                                   WHERE RP.ACTIVE_FLAG = 'Y'
                                         AND USR.ACTIVE_FLAG = 'Y'
                                         AND ZCODE <> 'Z32'
                                         AND USER_NAME = i_login_user
                                         AND ZCODE IN (SELECT CONFIG_NAME FROM RC_INV_CONFIG WHERE CONFIG_TYPE = '4 AM PST');
--                        WHERE   active_flag = 'Y'
--                         AND ZCODE <> 'Z32' -->> Added to restrict Z32 on 22-Feb-2019
--                         AND repair_partner_id = lv_r_partner_id; 
                                   
                    SELECT MAX (DISTINCT TO_CHAR (REPORT_RUN_DATE, 'MM/DD/YYYY HH:MI:SS AM'))
                      INTO lv_report_run_date1
                      FROM RC_INV_C3_CYCLECNT
                     WHERE     TRUNC (REPORT_RUN_DATE) = TO_DATE (lv_report_run_date, 'MM/DD/YYYY')
                           AND ZCODE IN lv_zcode1;
                           
                     SELECT LISTAGG(ZCODE, ', ') WITHIN GROUP (ORDER BY ZCODE) 
                        INTO lv_zcode2
                    FROM crpadm.RC_PRODUCT_REPAIR_PARTNER RP
                                         INNER JOIN CRPADM.RC_REPAIR_PARTNER_USER_MAP USR
                                             ON RP.REPAIR_PARTNER_ID = USR.REPAIR_PARTNER_ID
                                   WHERE RP.ACTIVE_FLAG = 'Y'
                                         AND USR.ACTIVE_FLAG = 'Y'
                                         AND ZCODE <> 'Z32'
                                         AND USER_NAME = i_login_user
                                         AND ZCODE IN (SELECT CONFIG_NAME FROM RC_INV_CONFIG WHERE CONFIG_TYPE = '9 PM PST');
--                        WHERE   active_flag = 'Y'
--                         AND ZCODE <> 'Z32' -->> Added to restrict Z32 on 22-Feb-2019
--                         AND repair_partner_id = lv_r_partner_id; 
                                   
                    SELECT MAX (DISTINCT TO_CHAR (REPORT_RUN_DATE, 'MM/DD/YYYY HH:MI:SS AM'))
                      INTO lv_report_run_date2
                      FROM RC_INV_C3_CYCLECNT
                     WHERE     TRUNC (REPORT_RUN_DATE) = TO_DATE (lv_report_run_date, 'MM/DD/YYYY')
                           AND ZCODE IN lv_zcode2;
                           
                     
                    IF lv_report_run_date1 IS NOT NULL AND lv_report_run_date2 IS NOT NULL
                THEN
                
                    lv_report_run_message := 'DGI Reconciliation was generated for '|| lv_zcode1 || ' sites at  ' || lv_report_run_date1 || ' and for '|| lv_zcode2 || ' sites at  ' || lv_report_run_date2; 
                    
                ELSIF lv_report_run_date1 IS NULL AND lv_report_run_date2 IS NOT NULL
                THEN                                 
                                
                    lv_report_run_message := 'DGI Reconciliation was generated for '|| lv_zcode2 || ' sites at  ' || lv_report_run_date2; 
                
                ELSIF lv_report_run_date1 IS NOT NULL AND lv_report_run_date2 IS NULL
                THEN
                
                lv_report_run_message := 'DGI Reconciliation was generated for '|| lv_zcode1 || ' sites at  ' || lv_report_run_date1;
                
                ELSE
                
                lv_report_run_message := '';               
                
                END IF;
                    
--                 END IF;
              ELSE

                SELECT MAX (DISTINCT TO_CHAR (REPORT_RUN_DATE, 'MM/DD/YYYY HH:MI:SS AM'))
                  INTO lv_report_run_date1
                  FROM RC_INV_C3_CYCLECNT
                 WHERE     TRUNC (REPORT_RUN_DATE) = TO_DATE (lv_report_run_date, 'MM/DD/YYYY')
                       AND ZCODE IN (SELECT CONFIG_NAME FROM RC_INV_CONFIG WHERE CONFIG_TYPE = '4 AM PST');
                       
                SELECT MAX (DISTINCT TO_CHAR (REPORT_RUN_DATE, 'MM/DD/YYYY HH:MI:SS AM'))
                  INTO lv_report_run_date2
                  FROM RC_INV_C3_CYCLECNT
                 WHERE     TRUNC (REPORT_RUN_DATE) = TO_DATE (lv_report_run_date, 'MM/DD/YYYY')
                       AND ZCODE IN (SELECT CONFIG_NAME FROM RC_INV_CONFIG WHERE CONFIG_TYPE = '9 PM PST'); 
                       
                IF lv_report_run_date1 IS NOT NULL AND lv_report_run_date2 IS NOT NULL
                THEN
                
                    lv_report_run_message := 'DGI Reconciliation was generated for Z05, Z20 and Z31 sites at  ' || lv_report_run_date1 || ' and for Z29, Z26 and Z28 sites at ' || lv_report_run_date2; 
                    
                ELSIF lv_report_run_date1 IS NULL AND lv_report_run_date2 IS NOT NULL
                THEN                                 
                                
                    lv_report_run_message := 'DGI Reconciliation was generated for Z29, Z26 and Z28 sites at ' || lv_report_run_date2; 
                
                ELSIF lv_report_run_date1 IS NOT NULL AND lv_report_run_date2 IS NULL
                THEN
                
                lv_report_run_message := 'DGI Reconciliation was generated for Z05, Z20 and Z31 sites at  ' || lv_report_run_date1;
                
                ELSE
                
                lv_report_run_message := '';               
                
                END IF; 
                
              END IF;
              
            ELSE
            
              IF i_login_user IS NOT NULL AND (UPPER (i_user_role) NOT LIKE '%ADMIN%' AND UPPER (i_user_role) NOT LIKE '%BPM%')
              THEN

--                 BEGIN
--                    SELECT REPAIR_PARTNER_ID
--                      INTO lv_r_partner_id
--                      FROM crpadm.RC_REPAIR_PARTNER_USER_MAP
--                     WHERE user_name = i_login_user;
--                 EXCEPTION
--                    WHEN OTHERS
--                    THEN
--                       lv_r_partner_id := NULL;
--                 END;
--
--                 IF lv_r_partner_id IS NOT NULL
--                 THEN

                    SELECT LISTAGG(ZCODE, ', ') WITHIN GROUP (ORDER BY ZCODE) 
                        INTO lv_zcode1
                    FROM crpadm.RC_PRODUCT_REPAIR_PARTNER RP
                                         INNER JOIN CRPADM.RC_REPAIR_PARTNER_USER_MAP USR
                                             ON RP.REPAIR_PARTNER_ID = USR.REPAIR_PARTNER_ID
                                   WHERE     ZCODE <> 'Z32'
                                         AND RP.ACTIVE_FLAG = 'Y'
                                         AND USR.ACTIVE_FLAG = 'Y'
                                         AND USER_NAME = i_login_user
                                         AND ZCODE IN (SELECT CONFIG_NAME FROM RC_INV_CONFIG WHERE CONFIG_TYPE = '4 AM PST');
--                        WHERE   active_flag = 'Y'
--                                   AND ZCODE <> 'Z32' -->> Added to restrict Z32 on 22-Feb-2019
--                                   AND repair_partner_id = lv_r_partner_id; 
                                   
                    SELECT MAX (DISTINCT TO_CHAR (REPORT_RUN_DATE, 'MM/DD/YYYY HH:MI:SS AM'))
                      INTO lv_report_run_date1
                      FROM RC_INV_C3_CYCLECNT
                     WHERE ZCODE IN lv_zcode1;
                     
                     SELECT LISTAGG(ZCODE, ', ') WITHIN GROUP (ORDER BY ZCODE) 
                        INTO lv_zcode2
                    FROM crpadm.RC_PRODUCT_REPAIR_PARTNER RP
                                         INNER JOIN CRPADM.RC_REPAIR_PARTNER_USER_MAP USR
                                             ON RP.REPAIR_PARTNER_ID = USR.REPAIR_PARTNER_ID
                                   WHERE     ZCODE <> 'Z32'
                                         AND RP.ACTIVE_FLAG = 'Y'
                                         AND USR.ACTIVE_FLAG = 'Y'
                                         AND USER_NAME = i_login_user
                                         AND ZCODE IN (SELECT CONFIG_NAME FROM RC_INV_CONFIG WHERE CONFIG_TYPE = '9 PM PST');
--                        WHERE   active_flag = 'Y'
--                                   AND ZCODE <> 'Z32' -->> Added to restrict Z32 on 22-Feb-2019
--                                   AND repair_partner_id = lv_r_partner_id; 
                                   
                    SELECT MAX (DISTINCT TO_CHAR (REPORT_RUN_DATE, 'MM/DD/YYYY HH:MI:SS AM'))
                      INTO lv_report_run_date2
                      FROM RC_INV_C3_CYCLECNT
                     WHERE ZCODE IN lv_zcode2;
                    
                    IF lv_report_run_date1 IS NOT NULL AND lv_report_run_date2 IS NOT NULL
                THEN
                
                    lv_report_run_message := 'DGI Reconciliation was generated for '|| lv_zcode1 || ' sites at  ' || lv_report_run_date1 || ' and for '|| lv_zcode2 || ' sites at  ' || lv_report_run_date2; 
                    
                ELSIF lv_report_run_date1 IS NULL AND lv_report_run_date2 IS NOT NULL
                THEN                                 
                                
                    lv_report_run_message := 'DGI Reconciliation was generated for '|| lv_zcode2 || ' sites at  ' || lv_report_run_date2; 
                
                ELSIF lv_report_run_date1 IS NOT NULL AND lv_report_run_date2 IS NULL
                THEN
                
                lv_report_run_message := 'DGI Reconciliation was generated for '|| lv_zcode1 || ' sites at  ' || lv_report_run_date1;
                
                ELSE
                
                lv_report_run_message := '';               
                
                END IF;
                    
--                 END IF;
              ELSE

                SELECT MAX (DISTINCT TO_CHAR (REPORT_RUN_DATE, 'MM/DD/YYYY HH:MI:SS AM'))
                  INTO lv_report_run_date1
                  FROM RC_INV_C3_CYCLECNT
                 WHERE ZCODE IN (SELECT CONFIG_NAME FROM RC_INV_CONFIG WHERE CONFIG_TYPE = '4 AM PST');
                       
                SELECT MAX (DISTINCT TO_CHAR (REPORT_RUN_DATE, 'MM/DD/YYYY HH:MI:SS AM'))
                  INTO lv_report_run_date2
                  FROM RC_INV_C3_CYCLECNT
                 WHERE ZCODE IN (SELECT CONFIG_NAME FROM RC_INV_CONFIG WHERE CONFIG_TYPE = '9 PM PST'); 
                       
                IF lv_report_run_date1 IS NOT NULL AND lv_report_run_date2 IS NOT NULL
                THEN
                
                    lv_report_run_message := 'DGI Reconciliation was generated for Z05, Z20 and Z31 sites at  ' || lv_report_run_date1 || ' and for Z29, Z26 and Z28 sites at ' || lv_report_run_date2; 
                    
                ELSIF lv_report_run_date1 IS NULL AND lv_report_run_date2 IS NOT NULL
                THEN                                 
                                
                    lv_report_run_message := 'DGI Reconciliation was generated for Z29, Z26 and Z28 sites at ' || lv_report_run_date2; 
                
                ELSIF lv_report_run_date1 IS NOT NULL AND lv_report_run_date2 IS NULL
                THEN
                
                lv_report_run_message := 'DGI Reconciliation was generated for Z05, Z20 and Z31 sites at  ' || lv_report_run_date1;
                
                ELSE
                
                lv_report_run_message := '';               
                
                END IF; 
                
              END IF; 
                                        
            END IF; 
              
/* End Added code to display banner message on 17-SEP-2018 by sridvasu */

        O_TO_ORG        := lv_to_org;
        O_TO_SUBINV     := lv_to_subinv;
        O_ENTRY_STATUS  := lv_entry_status;
        O_RPT_RUN_DATE  := lv_rpt_run_date;
        o_report_run_message := lv_report_run_message;
        
        EXCEPTION
              WHEN OTHERS
              THEN
                v_message:=SUBSTR(SQLERRM,1,200);

                 P_RC_ERROR_LOG (
                    I_module_name       => 'P_RC_ORG_SUBINV_ENTRY_STATUS',
                    I_entity_name       => NULL,
                    I_entity_id         => NULL,
                    I_ext_entity_name   => NULL,
                    I_ext_entity_id     => NULL,
                    I_error_type        => 'EXCEPTION',
                    i_Error_Message     =>    'Error getting while getting from to orgs '
                                           || ' <> '
                                           || v_message
                                           || ' LineNo=> '
                                           || DBMS_UTILITY.Format_error_backtrace,
                    I_created_by        => 'RC_INV_C3_CYCLE_COUNT_PKG',
                    I_updated_by        => 'RC_INV_C3_CYCLE_COUNT_PKG');
            
        END P_RC_ORG_SUBINV_ENTRY_STATUS;       

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
    o_report_run_message   OUT NOCOPY VARCHAR2)

IS

lv_query                VARCHAR2(32767);
lv_cnt_query            VARCHAR2(32767);
lv_inv_c3_cyclecount_tab        RC_INV_C3_CYCLECNT_TAB := RC_INV_C3_CYCLECNT_TAB();
lv_count              NUMBER;
lv_sort_column_name   VARCHAR2 (100);
lv_sort_column_by     VARCHAR2 (100);
lv_min_row            NUMBER;
lv_max_row            NUMBER;
lv_part_number          VARCHAR2(32767);
lv_part_numbers         VARCHAR2(32767);
lv_report_run_date      VARCHAR2(32767);
lv_report_run_dates     VARCHAR2(32767);
lv_report_run_message   VARCHAR2(32767);

BEGIN

    lv_sort_column_name    := UPPER (TRIM (i_sort_column_name));
    lv_sort_column_by      := UPPER (TRIM (i_sort_column_by));
    lv_min_row             := TO_NUMBER (i_min_row);
    lv_max_row             := TO_NUMBER (i_max_row);


lv_cnt_query := 'SELECT COUNT(*) FROM RC_INV_C3_CYCLECNT WHERE 1=1';


lv_query := 'SELECT RC_INV_C3_CYCLECNT_OBJ (
                                            INVENTORY_ITEM_ID,
                                            PART_NUMBER,
                                            ZCODE,
                                            SUBINVENTORY,
                                            ADJUSTMENT_QUANTITY,
                                            PARTNER_QUANTITY,
                                            C3_QUANTITY,
                                            CREATION_DATE,
                                            LAST_UPDATE_DATE,
                                            ENTRY_STATUS_CODE,
                                            V_ATTR1,
                                            V_ATTR2,
                                            V_ATTR3,
                                            V_ATTR4,
                                            N_ATTR1,
                                            N_ATTR2,
                                            N_ATTR3,
                                            N_ATTR4,
                                            D_ATTR1,
                                            D_ATTR2,
                                            D_ATTR3,
                                            D_ATTR4
                                           )
                FROM
                ( 
                SELECT 
                    INVENTORY_ITEM_ID,
                    PART_NUMBER,
                    ZCODE,
                    SUBINVENTORY,
                    ADJUSTMENT_QUANTITY,
                    PARTNER_QUANTITY,
                    C3_QUANTITY,
                    CREATION_DATE,
                    LAST_UPDATE_DATE,
                    ENTRY_STATUS_CODE,
                    NULL V_ATTR1,
                    NULL V_ATTR2,
                    NULL V_ATTR3,
                    NULL V_ATTR4,
                    NULL N_ATTR1,
                    NULL N_ATTR2,
                    NULL N_ATTR3,
                    NULL N_ATTR4,
                    NULL D_ATTR1,
                    NULL D_ATTR2,
                    NULL D_ATTR3,
                    NULL D_ATTR4,';
                    
                
             -- Code for adding the ROW_NUMBER()  OVER or ROWNUM based on whether the sorting is applied or not
            IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
             THEN
                IF i_report_run_date is null 
                THEN
                    lv_query :=
                          lv_query
                       || 'ROW_NUMBER()  OVER (ORDER BY '
                       || lv_sort_column_name
                       || ' '
                       || lv_sort_column_by
                       || ' ) AS rnum 
                                FROM RC_INV_C3_CYCLECNT
                                WHERE 1 = 1
                               -- AND CREATION_DATE >= SYSDATE - 8/24
                                AND STATUS_FLAG = ''Y''';
                                
                     lv_cnt_query := lv_cnt_query || ' AND STATUS_FLAG = ''Y''';  
                     
                ELSE
                    lv_query :=
                          lv_query
                       || 'ROW_NUMBER()  OVER (ORDER BY '
                       || lv_sort_column_name
                       || ' '
                       || lv_sort_column_by
                       || ' ) AS rnum 
                                FROM RC_INV_C3_CYCLECNT
                                WHERE 1 = 1';

                    lv_cnt_query := lv_cnt_query; 
                                                
                END IF;                                                
            ELSE
                IF i_report_run_date is null
                THEN
                    lv_query :=
                          lv_query
                       || 'ROWNUM AS rnum 
                                FROM RC_INV_C3_CYCLECNT
                                WHERE 1 = 1
                              --  AND CREATION_DATE >= SYSDATE - 8/24
                                AND STATUS_FLAG = ''Y''';
                                
                    lv_cnt_query := lv_cnt_query || ' AND STATUS_FLAG = ''Y''';  
                    
                ELSE
                    lv_query :=
                          lv_query
                       || 'ROWNUM AS rnum 
                                FROM RC_INV_C3_CYCLECNT
                                WHERE 1 = 1';
                                
                    lv_cnt_query := lv_cnt_query;                                 
                
                END IF;                           
            END IF;
            

            IF i_part_number IS NOT NULL 
            THEN
            
            lv_count:=0;
            
            FOR REC IN (SELECT DISTINCT UPPER(TRIM(REGEXP_SUBSTR(i_part_number, '[^ ,]+', 1, LEVEL))) AS part
                        FROM DUAL
                            CONNECT BY REGEXP_SUBSTR (i_part_number,'[^ ,]+',1, LEVEL)  IS NOT NULL)
            LOOP
            
                                 
               SELECT LISTAGG (part_number, ',') WITHIN GROUP (ORDER BY part_number, ',') into lv_part_number
               from
                  (SELECT part_number        
                  FROM RC_INV_C3_CYCLECNT
               WHERE    UPPER (part_number) LIKE '%'||rec.part||'%'
               GROUP BY part_number);
       
            IF lv_count>0
            THEN
            
                lv_part_numbers := lv_part_numbers ||','|| lv_part_number;
                          
            ELSE
                lv_part_numbers:= lv_part_number;
               
            END IF;
            
            lv_count:=lv_count+1;    
            
            dbms_output.put_line (lv_part_numbers);
            
            END LOOP;   
            
            lv_count:=0; 
            
                lv_query := lv_query || ' AND UPPER(PART_NUMBER) IN (SELECT DISTINCT UPPER(TRIM(REGEXP_SUBSTR('''||lv_part_numbers||''', ''[^ ,]+'', 1, LEVEL))) AS part
                        FROM DUAL
                            CONNECT BY REGEXP_SUBSTR ('''||lv_part_numbers||''',''[^ ,]+'',1, LEVEL)  IS NOT NULL)';
                
                                                                               
                lv_cnt_query := lv_cnt_query || ' AND UPPER(PART_NUMBER) IN (SELECT DISTINCT UPPER(TRIM(REGEXP_SUBSTR('''||lv_part_numbers||''', ''[^ ,]+'', 1, LEVEL))) AS part
                        FROM DUAL
                            CONNECT BY REGEXP_SUBSTR ('''||lv_part_numbers||''',''[^ ,]+'',1, LEVEL)  IS NOT NULL)';
                                                                                               
            END IF;


            IF i_zcode IS NOT NULL 
            THEN
                lv_query := lv_query||' AND ZCODE = '''|| i_zcode ||'''';
                
                lv_cnt_query := lv_cnt_query||' AND ZCODE = '''|| i_zcode ||'''';
                               
            END IF;

            IF i_subinv IS NOT NULL 
            THEN
                lv_query := lv_query||' AND SUBINVENTORY = '''|| i_subinv ||'''';
                
                lv_cnt_query := lv_cnt_query||' AND SUBINVENTORY = '''|| i_subinv ||'''';
                
            END IF;
            
            IF i_entry_status IS NOT NULL 
            THEN
                lv_query := lv_query||' AND ENTRY_STATUS_CODE = '''|| i_entry_status ||'''';
                
                lv_cnt_query := lv_cnt_query||' AND ENTRY_STATUS_CODE = '''|| i_entry_status ||'''';
                
            END IF;            

            IF i_report_run_date IS NOT NULL 
            THEN
                lv_query := lv_query||' AND TRUNC(REPORT_RUN_DATE) = to_date('||''''|| i_report_run_date ||''',''MM/DD/YYYY'')';
                
                lv_cnt_query := lv_cnt_query||' AND TRUNC(REPORT_RUN_DATE) = to_date('||''''|| i_report_run_date ||''',''MM/DD/YYYY'')';
            
            END IF;    
/* Start commented below code on 17-SEP-2018 by sridvasu */          
                
--                SELECT MAX (DISTINCT TO_CHAR (REPORT_RUN_DATE, 'MM/DD/YYYY HH:MI:SS AM'))
--                  INTO lv_report_run_date
--                  FROM RC_INV_C3_CYCLECNT
--                 WHERE     TRUNC (REPORT_RUN_DATE) = TO_DATE (i_report_run_date, 'MM/DD/YYYY')
--                       AND ZCODE IN (SELECT CONFIG_NAME FROM RC_INV_CONFIG WHERE CONFIG_TYPE = '4 AM PST');
--                       
--                SELECT MAX (DISTINCT TO_CHAR (REPORT_RUN_DATE, 'MM/DD/YYYY HH:MI:SS AM'))
--                  INTO lv_report_run_dates
--                  FROM RC_INV_C3_CYCLECNT
--                 WHERE     TRUNC (REPORT_RUN_DATE) = TO_DATE (i_report_run_date, 'MM/DD/YYYY')
--                       AND ZCODE IN (SELECT CONFIG_NAME FROM RC_INV_CONFIG WHERE CONFIG_TYPE = '9 PM PST'); 
--                       
--/* Start Added conditions for report run date 22-DEC-2017 */                             
--
--                IF lv_report_run_date IS NOT NULL AND lv_report_run_dates IS NOT NULL
--                THEN
--                
--                    lv_report_run_message := 'DGI Reconciliation was generated for Z05, Z20 and Z31 sites at  ' || lv_report_run_date || ' and for Z29, Z26 and Z28 sites at ' || lv_report_run_dates; -- Renamed the display message from C3 Cycle Count Report to DGI Reconciliation Report on 19th Jul, 2018 by sridvasu  
--                            
--                    o_report_run_message := lv_report_run_message;  
--                    
--                ELSIF lv_report_run_date IS NULL AND lv_report_run_dates IS NOT NULL
--                THEN                                 
--                                
--                    lv_report_run_message := 'DGI Reconciliation was generated for Z29, Z26 and Z28 sites at ' || lv_report_run_dates;  -- Renamed the display message from C3 Cycle Count Report to DGI Reconciliation Report on 19th Jul, 2018 by sridvasu 
--                    
--                    o_report_run_message := lv_report_run_message; 
--                
--                ELSIF lv_report_run_date IS NOT NULL AND lv_report_run_dates IS NULL
--                THEN
--                
--                lv_report_run_message := 'DGI Reconciliation was generated for Z05, Z20 and Z31 sites at  ' || lv_report_run_date;  -- Renamed the display message from C3 Cycle Count Report to DGI Reconciliation Report on 19th Jul, 2018 by sridvasu
--                
--                o_report_run_message := lv_report_run_message;
--                
--                ELSE
--                
--                o_report_run_message := '';               
--                
--                END IF;    
--
--/* End Added conditions for report run date 22-DEC-2017 */                        
--                
--             
--             
--/* Start Added conditions for report run date 22-DEC-2017 */                             
--
--                IF lv_report_run_date IS NOT NULL AND lv_report_run_dates IS NOT NULL
--                THEN
--                
--                    lv_report_run_message := 'DGI Reconciliation was generated for Z05, Z20 and Z31 sites at  ' || lv_report_run_date || ' and for Z29, Z26 and Z28 sites at ' || lv_report_run_dates;  -- Renamed the display message from C3 Cycle Count Report to DGI Reconciliation Report on 19th Jul, 2018 by sridvasu 
--                            
--                    o_report_run_message := lv_report_run_message;  
--                    
--                ELSIF lv_report_run_date IS NULL AND lv_report_run_dates IS NOT NULL
--                THEN                                 
--                                
--                    lv_report_run_message := 'DGI Reconciliation was generated for Z29, Z26 and Z28 sites at ' || lv_report_run_dates; -- Renamed the display message from C3 Cycle Count Report to DGI Reconciliation Report on 19th Jul, 2018 by sridvasu 
--                    
--                    o_report_run_message := lv_report_run_message; 
--                
--                ELSIF lv_report_run_date IS NOT NULL AND lv_report_run_dates IS NULL
--                THEN
--                
--                lv_report_run_message := 'DGI Reconciliation was generated for Z05, Z20 and Z31 sites at  ' || lv_report_run_date;  -- Renamed the display message from C3 Cycle Count Report to DGI Reconciliation Report on 19th Jul, 2018 by sridvasu
--                
--                o_report_run_message := lv_report_run_message;
--                
--                ELSE
--                
--                o_report_run_message := '';               
--                
--                END IF;    
--
--/* End Added conditions for report run date 22-DEC-2017 */ 
--
--            ELSE
--  
--                
--                SELECT TO_CHAR(MAX(REPORT_RUN_DATE),'MM/DD/YYYY HH:MI:SS AM')
--                    INTO lv_report_run_date
--                  FROM RC_INV_C3_CYCLECNT WHERE ZCODE IN (SELECT CONFIG_NAME FROM RC_INV_CONFIG WHERE CONFIG_TYPE = '4 AM PST');   
--                          
--                SELECT TO_CHAR(MAX(REPORT_RUN_DATE),'MM/DD/YYYY HH:MI:SS AM')
--                    INTO lv_report_run_dates
--                  FROM RC_INV_C3_CYCLECNT WHERE ZCODE IN (SELECT CONFIG_NAME FROM RC_INV_CONFIG WHERE CONFIG_TYPE = '9 PM PST');  
--                  
--                    lv_report_run_message := 'DGI Reconciliation was generated for Z05, Z20 and Z31 sites at  ' || lv_report_run_date || ' and for Z29, Z26 and Z28 sites at ' || lv_report_run_dates; -- Renamed the display message from C3 Cycle Count Report to DGI Reconciliation Report on 19th Jul, 2018 by sridvasu  
--                            
--                    o_report_run_message := lv_report_run_message;                  
--            
--    
--            END IF;  

/* End commented below code on 17-SEP-2018 by sridvasu */           
             
             -- For Sorting based on the user selection
             IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
             THEN
                lv_query :=
                      lv_query
                   || ' ) RC_C3CYCLE WHERE rnum >='
                   || i_min_row
                   || ' AND rnum <='
                   || i_max_row;

                lv_query :=
                      lv_query
                   || ' ORDER BY RC_C3CYCLE.'
                   || lv_sort_column_name
                   || ' '
                   || lv_sort_column_by;
             ELSE
                lv_query :=
                      lv_query
                   || ' AND ROWNUM <= '
                   || i_max_row
                   || ') WHERE rnum >='
                   || i_min_row;
             END IF;
             
             dbms_output.put_line (lv_query);
             dbms_output.put_line (lv_cnt_query);
             
             
             
            BEGIN

                EXECUTE IMMEDIATE lv_query BULK COLLECT INTO lv_inv_c3_cyclecount_tab;               
                
                EXECUTE IMMEDIATE lv_cnt_query INTO lv_count;


            EXCEPTION
              WHEN OTHERS
              THEN
                v_message:=SUBSTR(SQLERRM,1,200);

                 P_RC_ERROR_LOG (
                    I_module_name       => 'P_RC_INV_C3_CYCLECNT_LOAD_UI',
                    I_entity_name       => NULL,
                    I_entity_id         => NULL,
                    I_ext_entity_name   => NULL,
                    I_ext_entity_id     => NULL,
                    I_error_type        => 'EXCEPTION',
                    i_Error_Message     =>    'Error getting while executing c3 cycle count '
                                           || ' <> '
                                           || v_message
                                           || ' LineNo=> '
                                           || DBMS_UTILITY.Format_error_backtrace,
                    I_created_by        => 'RC_INV_C3_CYCLE_COUNT_PKG',
                    I_updated_by        => 'RC_INV_C3_CYCLE_COUNT_PKG');
            END;             
             
             o_c3_cyclecount := lv_inv_c3_cyclecount_tab;
             
             o_count    := lv_count;
             
END P_RC_INV_C3_CYCLECNT_LOAD_UI;


PROCEDURE P_RC_INV_C3_CYCLECNT_SUM_LOAD
    (    
    i_zcode                 VARCHAR2,
    i_subinv              VARCHAR2,
    i_min_row                NUMBER,
    i_max_row                NUMBER,
    i_sort_column_name       VARCHAR2,
    i_sort_column_by         VARCHAR2,
    o_c3_sum_cyclecount  OUT NOCOPY  RC_INV_C3_CYCLECNT_SUM_TAB,
    o_count                OUT NOCOPY  NUMBER)
IS

lv_query                VARCHAR2(32767);
lv_cnt_query            VARCHAR2(32767);
lv_c3_sum_cyclecount_tab        RC_INV_C3_CYCLECNT_SUM_TAB := RC_INV_C3_CYCLECNT_SUM_TAB();
lv_count              NUMBER;
lv_sort_column_name   VARCHAR2 (100);
lv_sort_column_by     VARCHAR2 (100);
lv_min_row            NUMBER;
lv_max_row            NUMBER;

BEGIN
    
    lv_sort_column_name    := UPPER (TRIM (i_sort_column_name));
    lv_sort_column_by      := UPPER (TRIM (i_sort_column_by));
    lv_min_row             := TO_NUMBER (i_min_row);
    lv_max_row             := TO_NUMBER (i_max_row);



lv_cnt_query := 'SELECT COUNT(*) FROM 
                 (
                  SELECT 
                     ZCODE,
                     SUBINVENTORY,
                     TOTAL_POSITIVE_ADJUSTMENT,';


lv_query := 'SELECT RC_INV_C3_CYCLECNT_SUM_OBJ (
                                                   ZCODE,
                                                   SUBINVENTORY,
                                                   TOTAL_POSITIVE_ADJUSTMENT,
                                                   TOTAL_NEGATIVE_ADJUSTMENT
                                                   ) 
                 FROM
                (
                SELECT 
                     ZCODE,
                     SUBINVENTORY,
                     TOTAL_POSITIVE_ADJUSTMENT,';


            -- Code for adding the ROW_NUMBER()  OVER or ROWNUM based on whether the sorting is applied or not
            IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
             THEN
                lv_query :=
                      lv_query
                   || 'TOTAL_NEGATIVE_ADJUSTMENT,
                       ROW_NUMBER()  OVER (ORDER BY '
                   || lv_sort_column_name
                   || ' '
                   || lv_sort_column_by
                   || ' ) AS rnum 
                        FROM 
                            (
                            SELECT
                                ZCODE, 
                                SUBINVENTORY,
                                SUM(CASE WHEN ADJUSTMENT_QUANTITY > 0 THEN ADJUSTMENT_QUANTITY ELSE 0 END) TOTAL_POSITIVE_ADJUSTMENT,SUM(CASE WHEN ADJUSTMENT_QUANTITY < 0 THEN ABS(ADJUSTMENT_QUANTITY) ELSE 0 END) TOTAL_NEGATIVE_ADJUSTMENT
                                FROM RC_INV_C3_CYCLECNT
                                        WHERE 1 = 1
                                       -- AND CREATION_DATE >= SYSDATE - 8/24
                                        AND STATUS_FLAG = ''Y''';

                lv_cnt_query :=
                      lv_cnt_query
                   || 'TOTAL_NEGATIVE_ADJUSTMENT,
                        ROW_NUMBER()  OVER (ORDER BY '
                   || lv_sort_column_name
                   || ' '
                   || lv_sort_column_by
                   || ' ) AS rnum 
                        FROM 
                            (
                            SELECT
                                ZCODE, 
                                SUBINVENTORY,
                                SUM(CASE WHEN ADJUSTMENT_QUANTITY > 0 THEN ADJUSTMENT_QUANTITY ELSE 0 END) TOTAL_POSITIVE_ADJUSTMENT,SUM(CASE WHEN ADJUSTMENT_QUANTITY < 0 THEN ABS(ADJUSTMENT_QUANTITY) ELSE 0 END) TOTAL_NEGATIVE_ADJUSTMENT
                                FROM RC_INV_C3_CYCLECNT
                                        WHERE 1 = 1
                                       -- AND CREATION_DATE >= SYSDATE - 8/24
                                        AND STATUS_FLAG = ''Y''';
                                                                                               
            ELSE
                lv_query :=
                      lv_query
                   || 'TOTAL_NEGATIVE_ADJUSTMENT 
                        FROM 
                            (
                            SELECT
                                ZCODE, 
                                SUBINVENTORY,
                                SUM(CASE WHEN ADJUSTMENT_QUANTITY > 0 THEN ADJUSTMENT_QUANTITY ELSE 0 END) TOTAL_POSITIVE_ADJUSTMENT,SUM(CASE WHEN ADJUSTMENT_QUANTITY < 0 THEN ABS(ADJUSTMENT_QUANTITY) ELSE 0 END) TOTAL_NEGATIVE_ADJUSTMENT
                                FROM RC_INV_C3_CYCLECNT
                                        WHERE 1 = 1
                                       -- AND CREATION_DATE >= SYSDATE - 8/24
                                        AND STATUS_FLAG = ''Y''';
                            
               lv_cnt_query :=
                      lv_cnt_query
                   || 'TOTAL_NEGATIVE_ADJUSTMENT 
                        FROM 
                            (
                            SELECT
                                ZCODE, 
                                SUBINVENTORY,
                                SUM(CASE WHEN ADJUSTMENT_QUANTITY > 0 THEN ADJUSTMENT_QUANTITY ELSE 0 END) TOTAL_POSITIVE_ADJUSTMENT,SUM(CASE WHEN ADJUSTMENT_QUANTITY < 0 THEN ABS(ADJUSTMENT_QUANTITY) ELSE 0 END) TOTAL_NEGATIVE_ADJUSTMENT
                                FROM RC_INV_C3_CYCLECNT
                                        WHERE 1 = 1
                                       -- AND CREATION_DATE >= SYSDATE - 8/24
                                        AND STATUS_FLAG = ''Y''';                                                        
            END IF;
            
            
            IF i_zcode IS NOT NULL 
            THEN
            
                lv_query := lv_query||' AND ZCODE = '''|| i_zcode ||'''';
                
                lv_cnt_query := lv_cnt_query||' AND ZCODE = '''|| i_zcode ||'''';
                
            END IF;
            
            
            IF i_subinv IS NOT NULL 
            THEN
            
                lv_query := lv_query||' AND SUBINVENTORY = '''|| i_subinv ||'''';
                
                lv_cnt_query := lv_cnt_query||' AND SUBINVENTORY = '''|| i_subinv ||'''';
                
            END IF;            
            
            
            lv_query := lv_query || ' GROUP BY ZCODE, SUBINVENTORY';
            
            lv_cnt_query := lv_cnt_query || ' GROUP BY ZCODE, SUBINVENTORY))';
            

             -- For Sorting based on the user selection
             IF lv_sort_column_name IS NOT NULL AND lv_sort_column_by IS NOT NULL
             THEN
                lv_query :=
                      lv_query
                   || ' )) RC_C3CYCLE WHERE rnum >='
                   || i_min_row
                   || ' AND rnum <='
                   || i_max_row;

                lv_query :=
                      lv_query
                   || ' ORDER BY RC_C3CYCLE.'
                   || lv_sort_column_name
                   || ' '
                   || lv_sort_column_by;
             ELSE
                lv_query :=
                      lv_query
                   || ' )) RC_C3CYCLE WHERE ROWNUM >='
                   || i_min_row
                   || ' AND ROWNUM <='
                   || i_max_row;
             END IF;            
            
            
             dbms_output.put_line (lv_query);
             dbms_output.put_line (lv_cnt_query);            
            
            BEGIN

                EXECUTE IMMEDIATE lv_query BULK COLLECT INTO lv_c3_sum_cyclecount_tab;
                
                EXECUTE IMMEDIATE lv_cnt_query INTO lv_count;


            EXCEPTION
              WHEN OTHERS
              THEN
                v_message:=SUBSTR(SQLERRM,1,200);

                 P_RC_ERROR_LOG (
                    I_module_name       => 'P_RC_INV_C3_CYCLECNT_SUM_LOAD',
                    I_entity_name       => NULL,
                    I_entity_id         => NULL,
                    I_ext_entity_name   => NULL,
                    I_ext_entity_id     => NULL,
                    I_error_type        => 'EXCEPTION',
                    i_Error_Message     =>    'Error getting while executing c3 cycle count '
                                           || ' <> '
                                           || v_message
                                           || ' LineNo=> '
                                           || DBMS_UTILITY.Format_error_backtrace,
                    I_created_by        => 'RC_INV_C3_CYCLE_COUNT_PKG',
                    I_updated_by        => 'RC_INV_C3_CYCLE_COUNT_PKG');
            END;             
             
             o_c3_sum_cyclecount := lv_c3_sum_cyclecount_tab;
             
             o_count    := lv_count;            
            
            
END P_RC_INV_C3_CYCLECNT_SUM_LOAD;

END RC_INV_C3_CYCLE_COUNT_PKG;
/