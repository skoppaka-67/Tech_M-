CREATE OR REPLACE PACKAGE BODY CRPADM./*AppDB: 1024272*/                         "RC_INV_SHORTAGE_DATA_FETCH" 
AS
   /**************************************************************************************************************************************************************************
             || Object Name     :
             || Modules        :
             || Description    : 
             || Modification History
             ||
             ||----------------------------------------------------------------------------------------------------------------------------------------------------------------
             ||Date                       By                     Version        Comments
             ||----------------------------------------------------------------------------------------------------------------------------------------------------------------
             |03-28-2017             obabrier                   1.0            Initial package
             ||-----------------------------------------------------------------------------------------------------------------------------------------------------------
     **************************************************************************************************************************************************************************/

   /*------------------------ Procedure to calculate BL Products ---------------------------------------*/
    PROCEDURE RC_INV_SHORTAGE_DATA_EXTRACT (i_user_id                VARCHAR2,
                                            i_min                   NUMBER,
                                            i_max                   NUMBER,
                                            i_filter_column_name    VARCHAR2,
                                            i_filter_user_input     VARCHAR2,
                                            i_sort_column_name      VARCHAR2,
                                            i_sort_column_by        VARCHAR2,
                                            i_filter_list           IN RC_NEW_FILTER_OBJ_LIST,
                                            o_total_row_count       OUT NUMBER,
                                            o_bl_list               OUT RC_INV_SHORTAGE_LIST)
   IS
      lv_bl_list             RC_INV_SHORTAGE_LIST;
      lv_execution_date      DATE;
      lv_err_msg             VARCHAR2 (1000);

      lv_count_query                  VARCHAR2 (32767) DEFAULT NULL;
      lv_row_clause                   VARCHAR2 (150) DEFAULT NULL;
      lv_query                        VARCHAR2 (32767);
      lv_main_query                   VARCHAR2 (32767);
      lv_filter_column_name           VARCHAR2 (100);
      lv_filter_column                VARCHAR2 (100);
      lv_filter_user_input            VARCHAR2 (100);
      lv_filter_value                 VARCHAR2 (1000);
      lv_filter_data_list             RC_FILTER_DATA_OBJ_LIST;
      lv_count                        NUMBER;
      lv_null_query                   VARCHAR2 (32767);
      lv_sort_qry                     VARCHAR (300);
      lv_sort_column_name             VARCHAR2 (100);
      lv_sort_column_by               VARCHAR2 (100);
      lv_total_row_count              NUMBER;

      
   BEGIN
   DBMS_Output.PUT_LINE('RC_INV_SHORTAGE_DATA_EXTRACT Procedure is starting');
      lv_bl_list := RC_INV_SHORTAGE_LIST ();
      lv_sort_column_name := i_sort_column_name;
      lv_sort_column_by := i_sort_column_by;
      lv_filter_column := UPPER (TRIM (i_filter_column_name));
      lv_filter_user_input := UPPER (TRIM (i_filter_user_input));
      lv_count_query := 'SELECT COUNT(*) FROM RMKTGADM.RC_INV_SHORTAGE WHERE 1 = 1 ';

       
lv_main_query:=                 'SELECT 
                                  PART_NUMBER,
                                  SITE_CODE ,
                                  NEGATIVE_INVENTORY,
                                  FVE_RETAIL ,
                                  FVE_OUTLET ,
                                  FVE_EXCESS ,
                                  LRO_YES_RETAIL,
                                  LRO_YES_OUTLET,
                                  LRO_YES_EXCESS,
                                  LRO_NO_RETAIL ,
                                  LRO_NO_OUTLET ,
                                  LRO_NO_EXCESS ,
                                  GDGI          ,
                                  POE_IN_TRANSIT,
                                  OTHER_INVENTORY,
                                  OPP_PART,  
                              ROW_NUMBER() OVER (';
                          
      IF     (   lv_sort_column_name IS NOT NULL
              OR lv_sort_column_name NOT LIKE 'NULL')
         AND (   lv_sort_column_by IS NOT NULL
              OR lv_sort_column_by NOT LIKE 'NULL')
      THEN
         lv_sort_column_name := UPPER (TRIM (lv_sort_column_name));
         lv_sort_column_by := UPPER (TRIM (lv_sort_column_by));

         CASE
            WHEN lv_sort_column_name = 'PART NUMBER'
            THEN
               lv_sort_column_name := 'PART_NUMBER';
            WHEN lv_sort_column_name = 'SITE CODE'
            THEN
               lv_sort_column_name := 'SITE_CODE';
            WHEN lv_sort_column_name = 'INVENTORY'
            THEN
               lv_sort_column_name := 'NEGATIVE_INVENTORY';
            WHEN lv_sort_column_name = 'FVE RETAIL'
            THEN
               lv_sort_column_name := 'FVE_RETAIL';
            WHEN lv_sort_column_name = 'FVE OUTLET'
            THEN
               lv_sort_column_name := 'FVE_OUTLET';
            WHEN lv_sort_column_name = 'FVE EXCESS'
            THEN
               lv_sort_column_name := 'FVE_EXCESS';
            WHEN lv_sort_column_name = 'LRO YES RETAIL'
            THEN
               lv_sort_column_name := 'LRO_YES_RETAIL';
            WHEN lv_sort_column_name = 'LRO YES OUTLET'
            THEN
               lv_sort_column_name := 'LRO_YES_OUTLET';
            WHEN lv_sort_column_name = 'LRO YES EXCESS'
            THEN
               lv_sort_column_name := 'LRO_YES_EXCESS';
            WHEN lv_sort_column_name = 'LRO NO RETAIL'
            THEN
               lv_sort_column_name := 'LRO_NO_RETAIL';
            WHEN lv_sort_column_name = 'LRO NO OUTLET'
            THEN
               lv_sort_column_name := 'LRO_NO_OUTLET';
            WHEN lv_sort_column_name = 'LRO NO EXCESS'
            THEN
               lv_sort_column_name := 'LRO_NO_EXCESS';
            WHEN lv_sort_column_name = 'GDGI'
            THEN
               lv_sort_column_name := 'GDGI';  
            WHEN lv_sort_column_name = 'OPP PART'
            THEN
               lv_sort_column_name := 'OPP_PART';  
            WHEN lv_sort_column_name = 'POE IN TRANSIT'
            THEN
               lv_sort_column_name := 'POE_IN_TRANSIT';  
            WHEN lv_sort_column_name = 'OTHER INVENTORY'
            THEN
               lv_sort_column_name := 'OTHER_INVENTORY';  
            ELSE
               lv_sort_column_name := lv_sort_column_name;
         END CASE;

         -- For getting the limited set of data based on the min and max values
         lv_sort_qry :=
            ' ORDER BY ' || lv_sort_column_name || ' ' || lv_sort_column_by;

         lv_main_query := lv_main_query || lv_sort_qry;
      ELSE
         lv_main_query := lv_main_query || ' ORDER BY PART_NUMBER ASC';
      END IF;

       lv_main_query := lv_main_query || ') RNUM
                FROM RMKTGADM.RC_INV_SHORTAGE';
                
      --For Column Level Filtering based on the user input
      IF lv_filter_column IS NOT NULL AND lv_filter_user_input IS NOT NULL
      THEN
         CASE
            WHEN lv_filter_column = 'PART NUMBER'
            THEN
               lv_filter_column := 'PART_NUMBER';
            WHEN lv_filter_column = 'SITE CODE'
            THEN
               lv_filter_column := 'SITE_CODE';
            WHEN lv_filter_column = 'INVENTORY'
            THEN
               lv_filter_column := 'NEGATIVE_INVENTORY';
            WHEN lv_filter_column = 'FVE RETAIL'
            THEN
               lv_filter_column := 'FVE_RETAIL';
            WHEN lv_filter_column = 'FVE OUTLET'
            THEN
               lv_filter_column := 'FVE_OUTLET';
            WHEN lv_filter_column = 'FVE EXCESS'
            THEN
               lv_filter_column := 'FVE_EXCESS';
            WHEN lv_filter_column = 'LRO YES RETAIL'
            THEN
               lv_filter_column := 'LRO_YES_RETAIL';
            WHEN lv_filter_column = 'LRO YES OUTLET'
            THEN
               lv_filter_column := 'LRO_YES_OUTLET';
            WHEN lv_filter_column = 'LRO YES EXCESS'
            THEN
               lv_filter_column := 'LRO_YES_EXCESS';
            WHEN lv_filter_column = 'LRO NO RETAIL'
            THEN
               lv_filter_column := 'LRO_NO_RETAIL';
            WHEN lv_filter_column = 'LRO NO OUTLET'
            THEN
               lv_filter_column := 'LRO_NO_OUTLET';
            WHEN lv_filter_column = 'LRO NO EXCESS'
            THEN
               lv_filter_column := 'LRO_NO_EXCESS';
            WHEN lv_filter_column = 'GDGI'
            THEN
               lv_filter_column := 'GDGI';  
            WHEN lv_filter_column = 'OPP PART'
            THEN
               lv_filter_column := 'OPP_PART';  
            WHEN lv_filter_column = 'POE IN TRANSIT'
            THEN
               lv_filter_column := 'POE_IN_TRANSIT';  
            WHEN lv_filter_column = 'RESERVATION TYPE'
            THEN
               lv_filter_column := 'RESERVATION_TYPE'; 
            ELSE
               lv_filter_column := lv_filter_column;
         END CASE;         

         lv_main_query :=
               lv_main_query
            || ' WHERE (UPPER(TRIM('
            || lv_filter_column
            || ')) LIKE (UPPER(TRIM(''%'
            || lv_filter_user_input
            || '%''))))';
         lv_count_query :=
               lv_count_query
            || ' AND (UPPER(TRIM('
            || lv_filter_column
            || ')) LIKE (UPPER(TRIM(''%'
            || lv_filter_user_input
            || '%''))))';
      END IF;
      
      
      
      
      IF i_filter_list IS NOT EMPTY
      THEN
         FOR IDX IN 1 .. i_filter_list.COUNT ()
         LOOP
            IF     (i_filter_list (idx).COL_NAME IS NOT NULL)
               AND (i_filter_list (idx).COL_NAME NOT LIKE ' ')
            THEN
               lv_filter_column_name :=
                  UPPER (TO_CHAR (TRIM (i_filter_list (idx).COL_NAME)));
                 DBMS_Output.PUT_LINE('================TEST FOR I_FILTER_LIST: ' 
                                          || lv_filter_column_name
                                          ||'=====================');
             CASE
            WHEN lv_filter_column_name = 'PART NUMBER'
            THEN
               lv_filter_column_name := 'PART_NUMBER';
            WHEN lv_filter_column_name = 'SITE CODE'
            THEN
               lv_filter_column_name := 'SITE_CODE';
            WHEN lv_filter_column_name = 'INVENTORY'
            THEN
               lv_filter_column_name := 'NEGATIVE_INVENTORY';
            WHEN lv_filter_column_name = 'FVE RETAIL'
            THEN
               lv_filter_column_name := 'FVE_RETAIL';
            WHEN lv_filter_column_name = 'FVE OUTLET'
            THEN
               lv_filter_column_name := 'FVE_OUTLET';
            WHEN lv_filter_column_name = 'FVE EXCESS'
            THEN
               lv_filter_column_name := 'FVE_EXCESS';
            WHEN lv_filter_column_name = 'LRO YES RETAIL'
            THEN
               lv_filter_column_name := 'LRO_YES_RETAIL';
            WHEN lv_filter_column_name = 'LRO YES OUTLET'
            THEN
               lv_filter_column_name := 'LRO_YES_OUTLET';
            WHEN lv_filter_column_name = 'LRO YES EXCESS'
            THEN
               lv_filter_column_name := 'LRO_YES_EXCESS';
            WHEN lv_filter_column_name = 'LRO NO RETAIL'
            THEN
               lv_filter_column_name := 'LRO_NO_RETAIL';
            WHEN lv_filter_column_name = 'LRO NO OUTLET'
            THEN
               lv_filter_column_name := 'LRO_NO_OUTLET';
            WHEN lv_filter_column_name = 'LRO NO EXCESS'
            THEN
               lv_filter_column_name := 'LRO_NO_EXCESS';
            WHEN lv_filter_column_name = 'GDGI'
            THEN
               lv_filter_column_name := 'GDGI';  
            WHEN lv_filter_column_name = 'OPP PART'
            THEN
               lv_filter_column_name := 'OPP_PART';  
            WHEN lv_filter_column_name = 'POE IN TRANSIT'
            THEN
               lv_filter_column_name := 'POE_IN_TRANSIT';  
            WHEN lv_filter_column_name = 'OTHER INVENTORY'
            THEN
               lv_filter_column_name := 'OTHER_INVENTORY'; 
                ELSE
                   lv_filter_column_name := lv_filter_column_name;
             END CASE;         
             
               IF IDX = 1  
               THEN
               lv_main_query :=
                     lv_main_query
                  || ' WHERE ('
                  || lv_filter_column_name
                  || ' IN (';
               ELSE                     
               lv_main_query :=
                     lv_main_query
                  || ' AND ('
                  || lv_filter_column_name
                  || ' IN (';

               END IF;   

               
               lv_count_query :=
                     lv_count_query
                  || ' AND ('
                  || lv_filter_column_name
                  || ' IN (';

               lv_filter_data_list := i_filter_list (idx).COL_VALUE;

               FOR IDX IN 1 .. lv_filter_data_list.COUNT ()
               LOOP
                  IF lv_count > 999
                  THEN
                     lv_count := 1;
                     lv_main_query :=
                           lv_main_query
                        || ' ) OR '
                        || lv_filter_column_name
                        || ' IN ( ';

                     lv_count_query :=
                           lv_count_query
                        || ' ) OR '
                        || lv_filter_column_name
                        || ' IN ( ';
                  END IF;

                  IF lv_filter_data_list IS NOT EMPTY
                  THEN
                     IF     (lv_filter_data_list (idx).FILTER_DATA
                                IS NOT NULL)
                        AND (lv_filter_data_list (idx).FILTER_DATA NOT LIKE
                                ' ')
                     THEN
                        lv_filter_value :=
                           TO_CHAR (
                              TRIM (lv_filter_data_list (idx).FILTER_DATA));

                        IF lv_filter_value LIKE '/'
                        THEN
                           lv_null_query :=
                              ' OR ' || lv_filter_column_name || ' IS NULL ';
                        END IF;

                        IF idx = 1
                        THEN
                           lv_main_query :=
                                 lv_main_query
                              || ''''
                              || lv_filter_value
                              || '''';
                           lv_count_query :=
                                 lv_count_query
                              || ''''
                              || lv_filter_value
                              || '''';
                        ELSE
                           lv_main_query :=
                                 lv_main_query
                              || ','
                              || ''''
                              || lv_filter_value
                              || '''';
                           lv_count_query :=
                                 lv_count_query
                              || ','
                              || ''''
                              || lv_filter_value
                              || '''';
                        END IF;
                     END IF;
                  END IF;

                  lv_count := lv_count + 1;
               END LOOP;

               lv_main_query := lv_main_query || ' ) ' || lv_null_query || ')';
               lv_count_query :=
                  lv_count_query || ' ) ' || lv_null_query || ')';
            END IF;
         END LOOP;
      END IF;      

     lv_row_clause := ' ) WHERE RNUM <= ' || i_max || ' AND RNUM > ' || i_min;

    lv_main_query := lv_main_query || lv_row_clause;
    

      IF     (   lv_sort_column_name IS NOT NULL
              OR lv_sort_column_name NOT LIKE 'NULL')
         AND (   lv_sort_column_by IS NOT NULL
              OR lv_sort_column_by NOT LIKE 'NULL')
      THEN
         -- For getting the limited set of data based on the min and max values
         lv_sort_qry :=
            ' ORDER BY ' || lv_sort_column_name || ' ' || lv_sort_column_by;

         lv_main_query := lv_main_query || lv_sort_qry;
      ELSE
         lv_main_query := lv_main_query || ' ORDER BY PART_NUMBER ASC';
      END IF;

                            
lv_query := 'SELECT RC_INV_SHORTAGE_OBJ (
                                  PART_NUMBER,
                                  SITE_CODE ,
                                  NEGATIVE_INVENTORY,
                                  FVE_RETAIL ,
                                  FVE_OUTLET ,
                                  FVE_EXCESS ,
                                  LRO_YES_RETAIL,
                                  LRO_YES_OUTLET,
                                  LRO_YES_EXCESS,
                                  LRO_NO_RETAIL ,
                                  LRO_NO_OUTLET ,
                                  LRO_NO_EXCESS ,
                                  GDGI          ,
                                  POE_IN_TRANSIT,
                                  OTHER_INVENTORY,
                                  OPP_PART)   
                    FROM( ' || lv_main_query;
DBMS_Output.PUT_LINE('Main QUERY: ' || lv_query);
       EXECUTE IMMEDIATE lv_query BULK COLLECT INTO lv_bl_list;
            FOR idx IN 1 .. lv_bl_list.COUNT ()  LOOP
          DBMS_Output.PUT_LINE(TO_CHAR(lv_bl_list(idx).PART_NUMBER ));
     END LOOP;
 DBMS_Output.PUT_LINE('Main QUERY DONE ========================================================= ');    
DBMS_Output.PUT_LINE(' ');
DBMS_Output.PUT_LINE('Count QUERY: ' || lv_count_query);
      EXECUTE IMMEDIATE lv_count_query INTO lv_total_row_count;
   DBMS_Output.PUT_LINE(TO_CHAR(lv_total_row_count));   
 DBMS_Output.PUT_LINE('Count QUERY DONE ========================================================= ');    
DBMS_Output.PUT_LINE(' ');

o_total_row_count :=lv_total_row_count;
o_bl_list:=lv_bl_list;
 

   EXCEPTION
      WHEN OTHERS
      THEN
         lv_err_msg :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
            lv_err_msg,
            NULL,
            'WCT_DATA_EXTRACT.WCT_EXCLUDE_PID_DATA_EXTRACT',
            'PACKAGE',            
            i_user_id,
            'Y');
   END RC_INV_SHORTAGE_DATA_EXTRACT;

   PROCEDURE RC_INV_GET_UNIQUE_PID (
      i_user_id                  IN     VARCHAR2,
      i_filter_column_name       IN     VARCHAR2,
      i_filter_list              IN     RC_NEW_FILTER_OBJ_LIST,
      o_bl_filter_list      OUT RC_GET_UNIQUE_PID_LIST)
   IS
      lv_final_demand_list    RC_GET_UNIQUE_PID_LIST;
      v_query                 CLOB;                        --VARCHAR2 (32767);
      v_main_query            CLOB;                        --VARCHAR2 (32767);
      lv_filter_column        VARCHAR2 (100);
      lv_total_row_count      NUMBER;
      lv_filter_column_name   VARCHAR2 (100);
      lv_user_id              VARCHAR2 (100);
      lv_in_query             CLOB;
      lv_filter_value         VARCHAR2 (1000);
      v_count_query           VARCHAR2 (32767) DEFAULT NULL;
      lv_filter_data_list     RC_FILTER_DATA_OBJ_LIST;
      lv_null_query           VARCHAR2 (32767);
   BEGIN
      lv_final_demand_list := RC_GET_UNIQUE_PID_LIST ();
      lv_user_id := i_user_id;

      lv_filter_column := UPPER (TRIM (i_filter_column_name));
         CASE
            WHEN lv_filter_column = 'PART NUMBER'
            THEN
               lv_filter_column := 'PART_NUMBER';
            WHEN lv_filter_column = 'SITE CODE'
            THEN
               lv_filter_column := 'SITE_CODE';
            WHEN lv_filter_column = 'INVENTORY'
            THEN
               lv_filter_column := 'NEGATIVE_INVENTORY';
            WHEN lv_filter_column = 'FVE RETAIL'
            THEN
               lv_filter_column := 'FVE_RETAIL';
            WHEN lv_filter_column = 'FVE OUTLET'
            THEN
               lv_filter_column := 'FVE_OUTLET';
            WHEN lv_filter_column = 'FVE EXCESS'
            THEN
               lv_filter_column := 'FVE_EXCESS';
            WHEN lv_filter_column = 'LRO YES RETAIL'
            THEN
               lv_filter_column := 'LRO_YES_RETAIL';
            WHEN lv_filter_column = 'LRO YES OUTLET'
            THEN
               lv_filter_column := 'LRO_YES_OUTLET';
            WHEN lv_filter_column = 'LRO YES EXCESS'
            THEN
               lv_filter_column := 'LRO_YES_EXCESS';
            WHEN lv_filter_column = 'LRO NO RETAIL'
            THEN
               lv_filter_column := 'LRO_NO_RETAIL';
            WHEN lv_filter_column = 'LRO NO OUTLET'
            THEN
               lv_filter_column := 'LRO_NO_OUTLET';
            WHEN lv_filter_column = 'LRO NO EXCESS'
            THEN
               lv_filter_column := 'LRO_NO_EXCESS';
            WHEN lv_filter_column = 'GDGI'
            THEN
               lv_filter_column := 'GDGI';  
            WHEN lv_filter_column = 'OPP PART'
            THEN
               lv_filter_column := 'OPP_PART';  
            WHEN lv_filter_column = 'POE IN TRANSIT'
            THEN
               lv_filter_column := 'POE_IN_TRANSIT';  
            WHEN lv_filter_column = 'OTHER INVENTORY'
            THEN
               lv_filter_column := 'OTHER_INVENTORY'; 
            ELSE
               lv_filter_column := lv_filter_column;
         END CASE;

      v_main_query := 'SELECT *
                FROM ( SELECT 
                                  PART_NUMBER,
                                  SITE_CODE ,
                                  NEGATIVE_INVENTORY,
                                  FVE_RETAIL ,
                                  FVE_OUTLET ,
                                  FVE_EXCESS ,
                                  LRO_YES_RETAIL,
                                  LRO_YES_OUTLET,
                                  LRO_YES_EXCESS,
                                  LRO_NO_RETAIL ,
                                  LRO_NO_OUTLET ,
                                  LRO_NO_EXCESS ,
                                  GDGI          ,
                                  POE_IN_TRANSIT,
                                  OTHER_INVENTORY,
                                  OPP_PART   
                        FROM RMKTGADM.RC_INV_SHORTAGE  ) 
               WHERE 1=1';

      -- For Column Level Filtering based on the user input


      IF i_filter_list IS NOT EMPTY
      THEN
         GET_IN_CONDITION_FOR_QUERY (i_filter_list, lv_in_query);


         v_main_query := v_main_query || lv_in_query;
      END IF;

      v_query :=
            ' SELECT DISTINCT '
         || lv_filter_column
         || ' FROM ( '
         || v_main_query
         || ' )';

      v_query :=
         v_query || ' ORDER BY ' || lv_filter_column || ' ASC NULLS FIRST';


      BEGIN
DBMS_Output.PUT_LINE('Main QUERY DONE ========================================================= ');    
         
DBMS_Output.PUT_LINE(v_query);
 
         EXECUTE IMMEDIATE v_query BULK COLLECT INTO lv_final_demand_list;
            FOR idx IN 1 .. lv_final_demand_list.COUNT ()  LOOP
          DBMS_Output.PUT_LINE(TO_CHAR(lv_final_demand_list(idx)));
     END LOOP;
         o_bl_filter_list := lv_final_demand_list;

      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            o_bl_filter_list := RC_GET_UNIQUE_PID_LIST ();
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         -- Logging exception
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12),
            NULL,
            'WCT_DATA_EXTRACT.WCT_GET_UNIQUE_PID',
            'PROCEDURE',
            lv_user_id,
            'N');
   END;   
   
   
  
   PROCEDURE GET_IN_CONDITION_FOR_QUERY (
      i_filter_list       RC_NEW_FILTER_OBJ_LIST,
      i_in_query      OUT CLOB)
   IS
      lv_in_query             CLOB;
      lv_null_query           VARCHAR2 (32767);
      lv_count                NUMBER;
      lv_filter_data_list     RC_FILTER_DATA_OBJ_LIST;
      lv_filter_column_name   VARCHAR2 (100);
      lv_filter_value         VARCHAR2 (1000);
   BEGIN
      lv_count := 1;

      IF i_filter_list IS NOT EMPTY
      THEN
         FOR IDX IN 1 .. i_filter_list.COUNT ()
         LOOP
            IF     (i_filter_list (idx).COL_NAME IS NOT NULL)
               AND (i_filter_list (idx).COL_NAME NOT LIKE ' ')
            THEN
               lv_filter_column_name :=
                  UPPER (TO_CHAR (TRIM (i_filter_list (idx).COL_NAME)));
         CASE
            WHEN lv_filter_column_name = 'PART NUMBER'
            THEN
               lv_filter_column_name := 'PART_NUMBER';
            WHEN lv_filter_column_name = 'SITE CODE'
            THEN
               lv_filter_column_name := 'SITE_CODE';
            WHEN lv_filter_column_name = 'INVENTORY'
            THEN
               lv_filter_column_name := 'NEGATIVE_INVENTORY';
            WHEN lv_filter_column_name = 'FVE RETAIL'
            THEN
               lv_filter_column_name := 'FVE_RETAIL';
            WHEN lv_filter_column_name = 'FVE OUTLET'
            THEN
               lv_filter_column_name := 'FVE_OUTLET';
            WHEN lv_filter_column_name = 'FVE EXCESS'
            THEN
               lv_filter_column_name := 'FVE_EXCESS';
            WHEN lv_filter_column_name = 'LRO YES RETAIL'
            THEN
               lv_filter_column_name := 'LRO_YES_RETAIL';
            WHEN lv_filter_column_name = 'LRO YES OUTLET'
            THEN
               lv_filter_column_name := 'LRO_YES_OUTLET';
            WHEN lv_filter_column_name = 'LRO YES EXCESS'
            THEN
               lv_filter_column_name := 'LRO_YES_EXCESS';
            WHEN lv_filter_column_name = 'LRO NO RETAIL'
            THEN
               lv_filter_column_name := 'LRO_NO_RETAIL';
            WHEN lv_filter_column_name = 'LRO NO OUTLET'
            THEN
               lv_filter_column_name := 'LRO_NO_OUTLET';
            WHEN lv_filter_column_name = 'LRO NO EXCESS'
            THEN
               lv_filter_column_name := 'LRO_NO_EXCESS';
            WHEN lv_filter_column_name = 'GDGI'
            THEN
               lv_filter_column_name := 'GDGI';  
            WHEN lv_filter_column_name = 'OPP PART'
            THEN
               lv_filter_column_name := 'OPP_PART';  
            WHEN lv_filter_column_name = 'POE IN TRANSIT'
            THEN
               lv_filter_column_name := 'POE_IN_TRANSIT';  
            WHEN lv_filter_column_name = 'OTHER INVENTORY'
            THEN
               lv_filter_column_name := 'OTHER_INVENTORY'; 
            ELSE
               lv_filter_column_name := lv_filter_column_name;
         END CASE;

               lv_in_query := lv_in_query || ' AND ';

               lv_filter_data_list := i_filter_list (idx).COL_VALUE;

               FOR IDX IN 1 .. lv_filter_data_list.COUNT ()
               LOOP
                  IF lv_count > 999
                  THEN
                     lv_count := 1;
                     lv_in_query :=
                           lv_in_query
                        || ') OR UPPER ('
                        || lv_filter_column_name
                        || ') IN (';
                  END IF;

                  IF lv_filter_data_list IS NOT EMPTY
                  THEN
                     IF     (lv_filter_data_list (idx).FILTER_DATA
                                IS NOT NULL)
                        AND (lv_filter_data_list (idx).FILTER_DATA NOT LIKE
                                ' ')
                     THEN
                        lv_filter_value :=
                           UPPER (
                              TO_CHAR (
                                 TRIM (lv_filter_data_list (idx).FILTER_DATA)));

                        IF lv_filter_value LIKE '/'
                        THEN
                           lv_null_query :=
                              'OR ' || lv_filter_column_name || ' IS NULL';
                        END IF;

                        IF idx = 1
                        THEN
                           lv_in_query :=
                                 lv_in_query
                              || '(UPPER ('
                              || lv_filter_column_name
                              || ') IN ('
                              || ''''
                              || lv_filter_value
                              || '''';
                        ELSE
                           IF lv_count = 1
                           THEN
                              lv_in_query :=
                                    lv_in_query
                                 || ''''
                                 || lv_filter_value
                                 || '''';
                           ELSE
                              lv_in_query :=
                                    lv_in_query
                                 || ','
                                 || ''''
                                 || lv_filter_value
                                 || '''';
                           END IF;
                        END IF;
                     END IF;
                  END IF;

                  lv_count := lv_count + 1;
               END LOOP;

               lv_in_query := lv_in_query || ')' || lv_null_query || ')';
               lv_null_query := ' ';
            END IF;
         END LOOP;

         i_in_query := lv_in_query;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'NO DATA FOUND',
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12),
            NULL,
            'WCT_DATA_EXTRACT.WCT_EXCLUDE_PID_DATA_EXTRACT',
            'PROCEDURE',
            NULL,
            'Y');
      WHEN OTHERS
      THEN
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12),
            NULL,
            'WCT_DATA_EXTRACT.WCT_EXCLUDE_PID_DATA_EXTRACT',
            'PROCEDURE',
            NULL,
            'Y');
   END;

    PROCEDURE RC_INV_SHORTAGE_TRANS_DATA_EXT (i_user_id                VARCHAR2,
                                            i_min                   NUMBER,
                                            i_max                   NUMBER,
                                            i_filter_column_name    VARCHAR2,
                                            i_filter_user_input     VARCHAR2,
                                            i_sort_column_name      VARCHAR2,
                                            i_sort_column_by        VARCHAR2,
                                            i_filter_list           IN RC_NEW_FILTER_OBJ_LIST,
                                            o_total_row_count       OUT NUMBER,
                                            o_inventory_sum         OUT NUMBER,
                                            o_bl_list               OUT RC_INV_SHORTAGE_TRANS_LIST)
   IS
      lv_bl_list             RC_INV_SHORTAGE_TRANS_LIST;
      lv_execution_date      DATE;
      lv_err_msg             VARCHAR2 (1000);

      lv_count_query                  VARCHAR2 (32767) DEFAULT NULL;
      lv_row_clause                   VARCHAR2 (150) DEFAULT NULL;
      lv_query                        VARCHAR2 (32767);
      lv_main_query                   VARCHAR2 (32767);
      lv_filter_column_name           VARCHAR2 (100);
      lv_filter_column                VARCHAR2 (100);
      lv_filter_user_input            VARCHAR2 (100);
      lv_filter_value                 VARCHAR2 (1000);
      lv_filter_data_list             RC_FILTER_DATA_OBJ_LIST;
      lv_count                        NUMBER;
      lv_null_query                   VARCHAR2 (32767);
      lv_sort_qry                     VARCHAR (300);
      lv_sort_column_name             VARCHAR2 (100);
      lv_sort_column_by               VARCHAR2 (100);
      lv_total_row_count              NUMBER;
      lv_sum_query                    VARCHAR2 (32767) DEFAULT NULL;
      lv_inventory_sum                NUMBER;
      
   BEGIN
   DBMS_Output.PUT_LINE('RC_INV_SHORTAGE_TRANS_DATA_EXT Procedure is starting');
      lv_bl_list := RC_INV_SHORTAGE_TRANS_LIST ();
      lv_sort_column_name := i_sort_column_name;
      lv_sort_column_by := i_sort_column_by;
      lv_filter_column := UPPER (TRIM (i_filter_column_name));
      lv_filter_user_input := UPPER (TRIM (i_filter_user_input));
      lv_count_query := 'SELECT COUNT(*) FROM RMKTGADM.RC_INV_SHORTAGE_TRANSACTION WHERE 1 = 1 ';
      lv_sum_query := 'SELECT SUM(TRANSACTION_VALUE) FROM RMKTGADM.RC_INV_SHORTAGE_TRANSACTION WHERE 1 = 1 ';
       
lv_main_query:=                 'SELECT 
                                  PART_NUMBER,
                                  TRANSACTION_TYPE,
                                  ORDER_ID,
                                  QUOTE_ID,
                                  QUOTE_LINE_ID,
                                  SHIPSET,
                                  WEB_ORDER_STATUS,
                                  QUOTE_STATUS,
                                  SO_LINE_STATUS,
                                  INVENTORY_SITE,
                                  RESERVED_QTY,
                                  RESERVED_FGI,       
                                  RESERVED_DGI,               
                                  TRANSACTION_VALUE,           
                                  THEATER,
                                  NEGATIVE_INVENTORY, 
                                  SITE_CODE,   
                                  OTHER_INVENTORY,
                                  REMARKS,
                                  PID_RESERVATION,
                                  AVAILABLE_POSITIVE,  
                              ROW_NUMBER() OVER (';
                          
      IF     (   lv_sort_column_name IS NOT NULL
              OR lv_sort_column_name NOT LIKE 'NULL')
         AND (   lv_sort_column_by IS NOT NULL
              OR lv_sort_column_by NOT LIKE 'NULL')
      THEN
         lv_sort_column_name := UPPER (TRIM (lv_sort_column_name));
         lv_sort_column_by := UPPER (TRIM (lv_sort_column_by));

         CASE
            WHEN lv_sort_column_name = 'PART NUMBER'
            THEN
               lv_sort_column_name := 'PART_NUMBER';
            WHEN lv_sort_column_name = 'TRANSACTION TYPE'
            THEN
               lv_sort_column_name := 'TRANSACTION_TYPE';
            WHEN lv_sort_column_name = 'ORDER ID'
            THEN
               lv_sort_column_name := 'ORDER_ID';
            WHEN lv_sort_column_name = 'QUOTE ID'
            THEN
               lv_sort_column_name := 'QUOTE_ID';
            WHEN lv_sort_column_name = 'LINE ID'
            THEN
               lv_sort_column_name := 'QUOTE_LINE_ID';
            WHEN lv_sort_column_name = 'SHIPSET'
            THEN
               lv_sort_column_name := 'SHIPSET';
            WHEN lv_sort_column_name = 'WEB ORDER STATUS'
            THEN
               lv_sort_column_name := 'WEB_ORDER_STATUS';
            WHEN lv_sort_column_name = 'QUOTE STATUS'
            THEN
               lv_sort_column_name := 'QUOTE_STATUS';
            WHEN lv_sort_column_name = 'SO LINE STATUS'
            THEN
               lv_sort_column_name := 'SO_LINE_STATUS';
            WHEN lv_sort_column_name = 'INVENTORY SITE'
            THEN
               lv_sort_column_name := 'INVENTORY_SITE';
            WHEN lv_sort_column_name = 'RESERVED QTY'
            THEN
               lv_sort_column_name := 'RESERVED_QTY';
            WHEN lv_sort_column_name = 'RESERVED FGI'
            THEN
               lv_sort_column_name := 'RESERVED_FGI';
            WHEN lv_sort_column_name = 'RESERVED_DGI'
            THEN
               lv_sort_column_name := 'RESERVED_DGI';  
            WHEN lv_sort_column_name = 'TRANSACTION VALUE'
            THEN
               lv_sort_column_name := 'TRANSACTION_VALUE';  
            WHEN lv_sort_column_name = 'THEATER'
            THEN
               lv_sort_column_name := 'THEATER';  
            WHEN lv_sort_column_name = 'NEGATIVE INVENTORY'
            THEN
               lv_sort_column_name := 'NEGATIVE_INVENTORY';  
            WHEN lv_sort_column_name = 'SITE CODE'
            THEN
               lv_sort_column_name := 'SITE_CODE'; 
            WHEN lv_sort_column_name = 'OTHER INVENTORY'
            THEN
               lv_sort_column_name := 'OTHER_INVENTORY'; 
            WHEN lv_sort_column_name = 'REMARKS'
            THEN
               lv_sort_column_name := 'REMARKS';
            WHEN lv_sort_column_name = 'PID RESERVATION'
            THEN
               lv_sort_column_name := 'PID_RESERVATION'; 
            WHEN lv_sort_column_name = 'AVAILABLE POSITIVE'
            THEN
               lv_sort_column_name := 'AVAILABLE_POSITIVE';                                              
            ELSE
               lv_sort_column_name := lv_sort_column_name;
         END CASE;

         -- For getting the limited set of data based on the min and max values
         lv_sort_qry :=
            ' ORDER BY ' || lv_sort_column_name || ' ' || lv_sort_column_by;

         lv_main_query := lv_main_query || lv_sort_qry;
      ELSE
         lv_main_query := lv_main_query || ' ORDER BY part_number,transaction_type DESC,site_code,NVL (order_id, quote_id),NVL (shipset, quote_line_id) ASC';
      END IF;

       lv_main_query := lv_main_query || ') RNUM
                FROM RMKTGADM.RC_INV_SHORTAGE_TRANSACTION';
                
      --For Column Level Filtering based on the user input
      IF lv_filter_column IS NOT NULL AND lv_filter_user_input IS NOT NULL
      THEN
         CASE
            WHEN lv_filter_column = 'PART NUMBER'
            THEN
               lv_filter_column := 'PART_NUMBER';
            WHEN lv_filter_column = 'TRANSACTION TYPE'
            THEN
               lv_filter_column := 'TRANSACTION_TYPE';
            WHEN lv_filter_column = 'ORDER ID'
            THEN
               lv_filter_column := 'ORDER_ID';
            WHEN lv_filter_column = 'QUOTE ID'
            THEN
               lv_filter_column := 'QUOTE_LINE_ID';
            WHEN lv_filter_column = 'LINE ID'
            THEN
               lv_filter_column := 'LINE_ID';
            WHEN lv_filter_column = 'SHIPSET'
            THEN
               lv_filter_column := 'SHIPSET';
            WHEN lv_filter_column = 'WEB ORDER STATUS'
            THEN
               lv_filter_column := 'WEB_ORDER_STATUS';
            WHEN lv_filter_column = 'QUOTE STATUS'
            THEN
               lv_filter_column := 'QUOTE_STATUS';
            WHEN lv_filter_column = 'SO LINE STATUS'
            THEN
               lv_filter_column := 'SO_LINE_STATUS';
            WHEN lv_filter_column = 'INVENTORY SITE'
            THEN
               lv_filter_column := 'INVENTORY_SITE';
            WHEN lv_filter_column = 'RESERVED QTY'
            THEN
               lv_filter_column := 'RESERVED_QTY';
            WHEN lv_filter_column = 'RESERVED FGI'
            THEN
               lv_filter_column := 'RESERVED_FGI';
            WHEN lv_filter_column = 'RESERVED_DGI'
            THEN
               lv_filter_column := 'RESERVED_DGI';  
            WHEN lv_filter_column = 'TRANSACTION VALUE'
            THEN
               lv_filter_column := 'TRANSACTION_VALUE';  
            WHEN lv_filter_column = 'THEATER'
            THEN
               lv_filter_column := 'THEATER';  
            WHEN lv_filter_column = 'NEGATIVE INVENTORY'
            THEN
               lv_filter_column := 'NEGATIVE_INVENTORY';  
           WHEN lv_filter_column = 'SITE CODE'
            THEN
               lv_filter_column := 'SITE_CODE'; 
            WHEN lv_filter_column = 'OTHER INVENTORY'
            THEN
               lv_filter_column := 'OTHER_INVENTORY'; 
            WHEN lv_filter_column = 'REMARKS'
            THEN
               lv_filter_column := 'REMARKS';
            WHEN lv_filter_column = 'PID RESERVATION'
            THEN
               lv_filter_column := 'PID_RESERVATION'; 
            WHEN lv_filter_column = 'AVAILABLE POSITIVE'
            THEN
               lv_filter_column := 'AVAILABLE_POSITIVE';                                              
             ELSE
               lv_filter_column := lv_filter_column;
         END CASE;         

         lv_main_query :=
               lv_main_query
            || ' WHERE (UPPER(TRIM('
            || lv_filter_column
            || ')) LIKE (UPPER(TRIM(''%'
            || lv_filter_user_input
            || '%''))))';
         lv_count_query :=
               lv_count_query
            || ' AND (UPPER(TRIM('
            || lv_filter_column
            || ')) LIKE (UPPER(TRIM(''%'
            || lv_filter_user_input
            || '%''))))';
        lv_sum_query :=
               lv_sum_query
            || ' AND (UPPER(TRIM('
            || lv_filter_column
            || ')) LIKE (UPPER(TRIM(''%'
            || lv_filter_user_input
            || '%''))))';            
      END IF;
      
      
      
      
      IF i_filter_list IS NOT EMPTY
      THEN
         FOR IDX IN 1 .. i_filter_list.COUNT ()
         LOOP
            IF     (i_filter_list (idx).COL_NAME IS NOT NULL)
               AND (i_filter_list (idx).COL_NAME NOT LIKE ' ')
            THEN
               lv_filter_column_name :=
                  UPPER (TO_CHAR (TRIM (i_filter_list (idx).COL_NAME)));
                 DBMS_Output.PUT_LINE('================TEST FOR I_FILTER_LIST: ' 
                                          || lv_filter_column_name
                                          ||'=====================');
             CASE
            WHEN lv_filter_column_name = 'PART NUMBER'
            THEN
               lv_filter_column_name := 'PART_NUMBER';
            WHEN lv_filter_column_name = 'TRANSACTION TYPE'
            THEN
               lv_filter_column_name := 'TRANSACTION_TYPE';
            WHEN lv_filter_column_name = 'ORDER ID'
            THEN
               lv_filter_column_name := 'ORDER_ID';
            WHEN lv_filter_column_name = 'QUOTE ID'
            THEN
               lv_filter_column_name := 'QUOTE_ID';
            WHEN lv_filter_column_name = 'LINE ID'
            THEN
               lv_filter_column_name := 'QUOTE_LINE_ID';
            WHEN lv_filter_column_name = 'SHIPSET'
            THEN
               lv_filter_column_name := 'SHIPSET';
            WHEN lv_filter_column_name = 'WEB ORDER STATUS'
            THEN
               lv_filter_column_name := 'WEB_ORDER_STATUS';
            WHEN lv_filter_column_name = 'QUOTE STATUS'
            THEN
               lv_filter_column_name := 'QUOTE_STATUS';
            WHEN lv_filter_column_name = 'SO LINE STATUS'
            THEN
               lv_filter_column_name := 'SO_LINE_STATUS';
            WHEN lv_filter_column_name = 'INVENTORY SITE'
            THEN
               lv_filter_column_name := 'INVENTORY_SITE';
            WHEN lv_filter_column_name = 'RESERVED QTY'
            THEN
               lv_filter_column_name := 'RESERVED_QTY';
            WHEN lv_filter_column_name = 'RESERVED FGI'
            THEN
               lv_filter_column_name := 'RESERVED_FGI';
            WHEN lv_filter_column_name = 'RESERVED_DGI'
            THEN
               lv_filter_column_name := 'RESERVED_DGI';  
            WHEN lv_filter_column_name = 'TRANSACTION VALUE'
            THEN
               lv_filter_column_name := 'TRANSACTION_VALUE';  
            WHEN lv_filter_column_name = 'THEATER'
            THEN
               lv_filter_column_name := 'THEATER';  
            WHEN lv_filter_column_name = 'NEGATIVE INVENTORY'
            THEN
               lv_filter_column_name := 'NEGATIVE_INVENTORY';  
           WHEN lv_filter_column_name = 'SITE CODE'
            THEN
               lv_filter_column_name := 'SITE_CODE'; 
            WHEN lv_filter_column_name = 'OTHER INVENTORY'
            THEN
               lv_filter_column_name := 'OTHER_INVENTORY'; 
            WHEN lv_filter_column_name = 'REMARKS'
            THEN
               lv_filter_column_name := 'REMARKS';
            WHEN lv_filter_column_name = 'PID RESERVATION'
            THEN
               lv_filter_column_name := 'PID_RESERVATION'; 
            WHEN lv_filter_column_name = 'AVAILABLE POSITIVE'
            THEN
               lv_filter_column_name := 'AVAILABLE_POSITIVE';      
            ELSE
                   lv_filter_column_name := lv_filter_column_name;
            END CASE;         
             
               IF IDX = 1  
               THEN
               lv_main_query :=
                     lv_main_query
                  || ' WHERE ('
                  || lv_filter_column_name
                  || ' IN (';
               ELSE                     
               lv_main_query :=
                     lv_main_query
                  || ' AND ('
                  || lv_filter_column_name
                  || ' IN (';

               END IF;   

               
               lv_count_query :=
                     lv_count_query
                  || ' AND ('
                  || lv_filter_column_name
                  || ' IN (';
               lv_sum_query :=
                     lv_sum_query
                  || ' AND ('
                  || lv_filter_column_name
                  || ' IN (';

               lv_filter_data_list := i_filter_list (idx).COL_VALUE;

               FOR IDX IN 1 .. lv_filter_data_list.COUNT ()
               LOOP
                  IF lv_count > 999
                  THEN
                     lv_count := 1;
                     lv_main_query :=
                           lv_main_query
                        || ' ) OR '
                        || lv_filter_column_name
                        || ' IN ( ';

                     lv_count_query :=
                           lv_count_query
                        || ' ) OR '
                        || lv_filter_column_name
                        || ' IN ( ';
                     lv_sum_query :=
                           lv_sum_query
                        || ' ) OR '
                        || lv_filter_column_name
                        || ' IN ( ';                        
                  END IF;

                  IF lv_filter_data_list IS NOT EMPTY
                  THEN
                     IF     (lv_filter_data_list (idx).FILTER_DATA
                                IS NOT NULL)
                        AND (lv_filter_data_list (idx).FILTER_DATA NOT LIKE
                                ' ')
                     THEN
                        lv_filter_value :=
                           TO_CHAR (
                              TRIM (lv_filter_data_list (idx).FILTER_DATA));

                        IF lv_filter_value LIKE '/'
                        THEN
                           lv_null_query :=
                              ' OR ' || lv_filter_column_name || ' IS NULL ';
                        END IF;

                        IF idx = 1
                        THEN
                           lv_main_query :=
                                 lv_main_query
                              || ''''
                              || lv_filter_value
                              || '''';
                           lv_count_query :=
                                 lv_count_query
                              || ''''
                              || lv_filter_value
                              || '''';
                           lv_sum_query :=
                                 lv_sum_query
                              || ''''
                              || lv_filter_value
                              || '''';                              
                        ELSE
                           lv_main_query :=
                                 lv_main_query
                              || ','
                              || ''''
                              || lv_filter_value
                              || '''';
                           lv_count_query :=
                                 lv_count_query
                              || ','
                              || ''''
                              || lv_filter_value
                              || '''';
                           lv_sum_query :=
                                 lv_sum_query
                              || ','
                              || ''''
                              || lv_filter_value
                              || '''';                              
                        END IF;
                     END IF;
                  END IF;

                  lv_count := lv_count + 1;
               END LOOP;

               lv_main_query := lv_main_query || ' ) ' || lv_null_query || ')';
               lv_count_query :=
                  lv_count_query || ' ) ' || lv_null_query || ')';
               lv_sum_query :=
                  lv_sum_query || ' ) ' || lv_null_query || ')';                  
            END IF;
         END LOOP;
      END IF;      

     lv_row_clause := ' ) WHERE RNUM <= ' || i_max || ' AND RNUM > ' || i_min;

    lv_main_query := lv_main_query || lv_row_clause;
    

      IF     (   lv_sort_column_name IS NOT NULL
              OR lv_sort_column_name NOT LIKE 'NULL')
         AND (   lv_sort_column_by IS NOT NULL
              OR lv_sort_column_by NOT LIKE 'NULL')
      THEN
         -- For getting the limited set of data based on the min and max values
         lv_sort_qry :=
            ' ORDER BY ' || lv_sort_column_name || ' ' || lv_sort_column_by;

         lv_main_query := lv_main_query || lv_sort_qry;
      ELSE
         lv_main_query := lv_main_query || 'ORDER BY part_number,transaction_type DESC,site_code,NVL (order_id, quote_id),NVL (shipset, quote_line_id) ASC';
      END IF;

                            
lv_query := 'SELECT RC_INV_SHORTAGE_TRANS_OBJ (
                                  PART_NUMBER,
                                  TRANSACTION_TYPE,
                                  ORDER_ID,
                                  QUOTE_ID,
                                  QUOTE_LINE_ID,
                                  SHIPSET,
                                  WEB_ORDER_STATUS,
                                  QUOTE_STATUS,
                                  SO_LINE_STATUS,
                                  INVENTORY_SITE,
                                  RESERVED_QTY,
                                  RESERVED_FGI,       
                                  RESERVED_DGI,               
                                  TRANSACTION_VALUE,           
                                  THEATER,
                                  NEGATIVE_INVENTORY, 
                                  SITE_CODE,   
                                  OTHER_INVENTORY,
                                  REMARKS,
                                  PID_RESERVATION,
                                  AVAILABLE_POSITIVE)   
                    FROM( ' || lv_main_query;
DBMS_Output.PUT_LINE('Main QUERY: ' || lv_query);
       EXECUTE IMMEDIATE lv_query BULK COLLECT INTO lv_bl_list;
            FOR idx IN 1 .. lv_bl_list.COUNT ()  LOOP
          DBMS_Output.PUT_LINE(TO_CHAR(lv_bl_list(idx).PART_NUMBER ));
     END LOOP;
 DBMS_Output.PUT_LINE('Main QUERY DONE ========================================================= ');    
DBMS_Output.PUT_LINE(' ');
DBMS_Output.PUT_LINE('Count QUERY: ' || lv_count_query);
      EXECUTE IMMEDIATE lv_count_query INTO lv_total_row_count;
   DBMS_Output.PUT_LINE(TO_CHAR(lv_total_row_count));   
 DBMS_Output.PUT_LINE('Count QUERY DONE ========================================================= ');    
DBMS_Output.PUT_LINE(' ');
DBMS_Output.PUT_LINE('Sum QUERY: ' || lv_sum_query);
      EXECUTE IMMEDIATE lv_sum_query INTO lv_inventory_sum;
   DBMS_Output.PUT_LINE(TO_CHAR(lv_inventory_sum));   
 DBMS_Output.PUT_LINE('Count QUERY DONE ========================================================= ');    

o_total_row_count :=lv_total_row_count;
o_inventory_sum:=lv_inventory_sum;
o_bl_list:=lv_bl_list;
 

   EXCEPTION
      WHEN OTHERS
      THEN
         lv_err_msg :=
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12);
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
            lv_err_msg,
            NULL,
            'WCT_DATA_EXTRACT.WCT_EXCLUDE_PID_DATA_EXTRACT',
            'PACKAGE',            
            i_user_id,
            'Y');
   END RC_INV_SHORTAGE_TRANS_DATA_EXT;

   PROCEDURE RC_TRANS_GET_UNIQUE_PID (
      i_user_id                  IN     VARCHAR2,
      i_filter_column_name       IN     VARCHAR2,
      i_filter_list              IN     RC_NEW_FILTER_OBJ_LIST,
      o_bl_filter_list           OUT    RC_GET_UNIQUE_PID_LIST)
   IS
      lv_final_demand_list    RC_GET_UNIQUE_PID_LIST;
      v_query                 CLOB;                        --VARCHAR2 (32767);
      v_main_query            CLOB;                        --VARCHAR2 (32767);
      lv_filter_column        VARCHAR2 (100);
      lv_total_row_count      NUMBER;
      lv_filter_column_name   VARCHAR2 (100);
      lv_user_id              VARCHAR2 (100);
      lv_in_query             CLOB;
      lv_filter_value         VARCHAR2 (1000);
      v_count_query           VARCHAR2 (32767) DEFAULT NULL;
      lv_filter_data_list     RC_FILTER_DATA_OBJ_LIST;
      lv_null_query           VARCHAR2 (32767);
   BEGIN
      lv_final_demand_list := RC_GET_UNIQUE_PID_LIST ();
      lv_user_id := i_user_id;

      lv_filter_column := UPPER (TRIM (i_filter_column_name));
         CASE
           WHEN lv_filter_column = 'PART NUMBER'
            THEN
               lv_filter_column := 'PART_NUMBER';
            WHEN lv_filter_column = 'TRANSACTION TYPE'
            THEN
               lv_filter_column := 'TRANSACTION_TYPE';
            WHEN lv_filter_column = 'ORDER ID'
            THEN
               lv_filter_column := 'ORDER_ID';
            WHEN lv_filter_column = 'QUOTE ID'
            THEN
               lv_filter_column := 'QUOTE_ID';
            WHEN lv_filter_column = 'LINE ID'
            THEN
               lv_filter_column := 'QUOTE_LINE_ID';
            WHEN lv_filter_column = 'SHIPSET'
            THEN
               lv_filter_column := 'SHIPSET';
            WHEN lv_filter_column = 'WEB ORDER STATUS'
            THEN
               lv_filter_column := 'WEB_ORDER_STATUS';
            WHEN lv_filter_column = 'QUOTE STATUS'
            THEN
               lv_filter_column := 'QUOTE_STATUS';
            WHEN lv_filter_column = 'SO LINE STATUS'
            THEN
               lv_filter_column := 'SO_LINE_STATUS';
            WHEN lv_filter_column = 'INVENTORY SITE'
            THEN
               lv_filter_column := 'INVENTORY_SITE';
            WHEN lv_filter_column = 'RESERVED QTY'
            THEN
               lv_filter_column := 'RESERVED_QTY';
            WHEN lv_filter_column = 'RESERVED FGI'
            THEN
               lv_filter_column := 'RESERVED_FGI';
            WHEN lv_filter_column = 'RESERVED_DGI'
            THEN
               lv_filter_column := 'RESERVED_DGI';  
            WHEN lv_filter_column = 'TRANSACTION VALUE'
            THEN
               lv_filter_column := 'TRANSACTION_VALUE';  
            WHEN lv_filter_column = 'THEATER'
            THEN
               lv_filter_column := 'THEATER';  
            WHEN lv_filter_column = 'NEGATIVE INVENTORY'
            THEN
               lv_filter_column := 'NEGATIVE_INVENTORY';  
           WHEN lv_filter_column = 'SITE CODE'
            THEN
               lv_filter_column := 'SITE_CODE'; 
            WHEN lv_filter_column = 'OTHER INVENTORY'
            THEN
               lv_filter_column := 'OTHER_INVENTORY'; 
            WHEN lv_filter_column = 'REMARKS'
            THEN
               lv_filter_column := 'REMARKS';
            WHEN lv_filter_column = 'PID RESERVATION'
            THEN
               lv_filter_column := 'PID_RESERVATION'; 
            WHEN lv_filter_column = 'AVAILABLE POSITIVE'
            THEN
               lv_filter_column := 'AVAILABLE_POSITIVE';                                              
            ELSE
               lv_filter_column := lv_filter_column;
         END CASE;

      v_main_query := 'SELECT *
                FROM ( SELECT 
                                  PART_NUMBER,
                                  TRANSACTION_TYPE,
                                  ORDER_ID,
                                  QUOTE_ID,
                                  QUOTE_LINE_ID,
                                  SHIPSET,
                                  WEB_ORDER_STATUS,
                                  QUOTE_STATUS,
                                  SO_LINE_STATUS,
                                  INVENTORY_SITE,
                                  RESERVED_QTY,
                                  RESERVED_FGI,       
                                  RESERVED_DGI,               
                                  TRANSACTION_VALUE,           
                                  THEATER,
                                  NEGATIVE_INVENTORY, 
                                  SITE_CODE,   
                                  OTHER_INVENTORY,
                                  REMARKS,
                                  PID_RESERVATION,
                                  AVAILABLE_POSITIVE
                        FROM RMKTGADM.RC_INV_SHORTAGE_TRANSACTION) 
               WHERE 1=1';

      -- For Column Level Filtering based on the user input


      IF i_filter_list IS NOT EMPTY
      THEN
         GET_IN_CONDITION_FOR_QUERY (i_filter_list, lv_in_query);


         v_main_query := v_main_query || lv_in_query;
      END IF;

      v_query :=
            ' SELECT DISTINCT '
         || lv_filter_column
         || ' FROM ( '
         || v_main_query
         || ' )';

      v_query :=
         v_query || ' ORDER BY ' || lv_filter_column || ' ASC NULLS FIRST';


      BEGIN
DBMS_Output.PUT_LINE('Main QUERY DONE ========================================================= ');    
         
DBMS_Output.PUT_LINE(v_query);
 
         EXECUTE IMMEDIATE v_query BULK COLLECT INTO lv_final_demand_list;
            FOR idx IN 1 .. lv_final_demand_list.COUNT ()  LOOP
          DBMS_Output.PUT_LINE(TO_CHAR(lv_final_demand_list(idx)));
     END LOOP;
         o_bl_filter_list := lv_final_demand_list;

      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            o_bl_filter_list := RC_GET_UNIQUE_PID_LIST ();
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         -- Logging exception
         CRPADM.RC_GLOBAL_ERROR_LOGGING (
            'OTHERS',
               SUBSTR (SQLERRM, 1, 200)
            || SUBSTR (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 12),
            NULL,
            'WCT_DATA_EXTRACT.WCT_GET_UNIQUE_PID',
            'PROCEDURE',
            lv_user_id,
            'N');
   END;   
   
   
   PROCEDURE RC_INV_EXCEL_DOWNLOAD (
       o_inv_list                      OUT RC_INV_SHORTAGE_LIST,
       o_trans_list                    OUT RC_INV_SHORTAGE_TRANS_LIST)
    IS
    lv_inv_list         RC_INV_SHORTAGE_LIST;
    lv_trans_list        RC_INV_SHORTAGE_TRANS_LIST;
    BEGIN

       SELECT RC_INV_SHORTAGE_OBJ (
                                  PART_NUMBER,
                                  SITE_CODE,
                                  NEGATIVE_INVENTORY,
                                  FVE_RETAIL,
                                  FVE_OUTLET,
                                  FVE_EXCESS,
                                  LRO_YES_RETAIL,
                                  LRO_YES_OUTLET,
                                  LRO_YES_EXCESS,
                                  LRO_NO_RETAIL,
                                  LRO_NO_OUTLET,
                                  LRO_NO_EXCESS,       
                                  GDGI,                          
                                  POE_IN_TRANSIT ,    
                                  OTHER_INVENTORY,
                                  OPP_PART)   
    BULK COLLECT INTO lv_inv_list
        FROM (SELECT PART_NUMBER,
                                  SITE_CODE,
                                  NEGATIVE_INVENTORY,
                                  FVE_RETAIL,
                                  FVE_OUTLET,
                                  FVE_EXCESS,
                                  LRO_YES_RETAIL,
                                  LRO_YES_OUTLET,
                                  LRO_YES_EXCESS,
                                  LRO_NO_RETAIL,
                                  LRO_NO_OUTLET,
                                  LRO_NO_EXCESS,       
                                  GDGI,                       
                                  POE_IN_TRANSIT ,    
                                  OTHER_INVENTORY,
                                  OPP_PART
                FROM (Select PART_NUMBER,
                                  SITE_CODE,
                                  NEGATIVE_INVENTORY,
                                  FVE_RETAIL,
                                  FVE_OUTLET,
                                  FVE_EXCESS,
                                  LRO_YES_RETAIL,
                                  LRO_YES_OUTLET,
                                  LRO_YES_EXCESS,
                                  LRO_NO_RETAIL,
                                  LRO_NO_OUTLET,
                                  LRO_NO_EXCESS,       
                                  GDGI,               
                                  POE_IN_TRANSIT ,    
                                  OTHER_INVENTORY,OPP_PART FROM RMKTGADM.RC_INV_SHORTAGE) WHERE 1=1 ORDER BY PART_NUMBER ASC );
     FOR idx IN 1 .. lv_inv_list.COUNT ()  LOOP
          DBMS_Output.PUT_LINE(TO_CHAR(lv_inv_list(idx).PART_NUMBER ));
     END LOOP;                                  

SELECT RC_INV_SHORTAGE_TRANS_OBJ (
                                  PART_NUMBER,
                                  TRANSACTION_TYPE,
                                  ORDER_ID,
                                  QUOTE_ID,
                                  QUOTE_LINE_ID,
                                  SHIPSET,
                                  WEB_ORDER_STATUS,
                                  QUOTE_STATUS,
                                  SO_LINE_STATUS,
                                  INVENTORY_SITE,
                                  RESERVED_QTY,
                                  RESERVED_FGI,       
                                  RESERVED_DGI,               
                                  TRANSACTION_VALUE,           
                                  THEATER,
                                  NEGATIVE_INVENTORY, 
                                  SITE_CODE,   
                                  OTHER_INVENTORY,
                                  REMARKS,
                                  PID_RESERVATION,
                                  AVAILABLE_POSITIVE)
             BULK COLLECT INTO lv_trans_list
        FROM (SELECT PART_NUMBER,
                                  TRANSACTION_TYPE,
                                  ORDER_ID,
                                  QUOTE_ID,
                                  QUOTE_LINE_ID,
                                  SHIPSET,
                                  WEB_ORDER_STATUS,
                                  QUOTE_STATUS,
                                  SO_LINE_STATUS,
                                  INVENTORY_SITE,
                                  RESERVED_QTY,
                                  RESERVED_FGI,       
                                  RESERVED_DGI,               
                                  TRANSACTION_VALUE,           
                                  THEATER,
                                  NEGATIVE_INVENTORY, 
                                  SITE_CODE,   
                                  OTHER_INVENTORY,
                                  REMARKS,
                                  PID_RESERVATION,
                                  AVAILABLE_POSITIVE
                FROM (Select PART_NUMBER,
                                  TRANSACTION_TYPE,
                                  ORDER_ID,
                                  QUOTE_ID,
                                  QUOTE_LINE_ID,
                                  replace(SHIPSET,'-',null) SHIPSET,
                                  WEB_ORDER_STATUS,
                                  QUOTE_STATUS,
                                  SO_LINE_STATUS,
                                  INVENTORY_SITE,
                                  RESERVED_QTY,
                                  RESERVED_FGI,       
                                  RESERVED_DGI,               
                                  TRANSACTION_VALUE,           
                                  THEATER,
                                  NEGATIVE_INVENTORY, 
                                  SITE_CODE,   
                                  OTHER_INVENTORY,
                                  REMARKS,
                                  PID_RESERVATION,
                                  AVAILABLE_POSITIVE FROM RMKTGADM.RC_INV_SHORTAGE_TRANSACTION) WHERE 1=1 ORDER BY PART_NUMBER ASC );
     FOR idx IN 1 .. lv_trans_list.COUNT ()  LOOP
          DBMS_Output.PUT_LINE(TO_CHAR(lv_trans_list(idx).PART_NUMBER ));
     END LOOP;                                  
    o_inv_list:=lv_inv_list;
    o_trans_list:=lv_trans_list;
    
    END;
   
       
END RC_INV_SHORTAGE_DATA_FETCH;
/