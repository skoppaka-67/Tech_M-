CREATE OR REPLACE PACKAGE BODY APPS./*AppDB: 9632762*/         "XXCTS_PR2S_ITEM_ORG_ASGN_PKG" 
                                                        
AS
   /*
   *******************************************************************************
   *File Name    : XXCTS_PR2S_ITEM_ORG_ASGN_PKG_PB.sql
   *Description  :Assigning Item to the respective org.
   *Author        : salsanka
   *Schema          : APPS
   *History:
   *Date           Author            Change Notes
   *------        --------           ------------------------
   *17 Aug 2017    salsanka          Initial Creation
   *16 Feb 2018    salsanka          Modified as part of defect fix : DE166035 -- Changed item org assignment pkg name
   *******************************************************************************
   */
   g_master_org_id   NUMBER (10) := 900000000;
   -- g_item_org_assgn_intf_id   NUMBER := 90000000;
   g_user_id         fnd_user.user_id%TYPE := 1900805535;

   --START:: Added as part of defect fix : DE166035
   PROCEDURE log_flow (p_log_message VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, p_log_message);
      DBMS_OUTPUT.put_line (p_log_message);
   END log_flow;

   --END:: Added as part of defect fix : DE166035
   PROCEDURE insert_items_to_rec_org (
      p_item_id   IN mtl_system_items_b.inventory_item_id%TYPE      ,      p_org_id    IN mtl_parameters.organization_id%TYPE DEFAULT NULL
      )
   IS
      l_msg                    VARCHAR2 (4000);
      l_cost_org               mtl_parameters.organization_id%TYPE; -- Added as part of Defect fix DE166035
      l_item_tt                ego_item_pub.item_tbl_type;
      x_items_tt               ego_item_pub.item_tbl_type;
      l_master_org_code        mtl_parameters.organization_code%TYPE;
      l_master_org_id          mtl_parameters.organization_id%TYPE;
      x_inventory_item_id      mtl_system_items_b.inventory_item_id%TYPE;
      x_organization_id        mtl_system_items_b.organization_id%TYPE;
      x_return_status          VARCHAR2 (1);
      x_msg_count              NUMBER;
      x_message_list           error_handler.error_tbl_type;
      x_msg                    VARCHAR2 (4000);
      l_resp_appl_id           fnd_responsibility_tl.application_id%TYPE;
      l_resp_id                fnd_responsibility_tl.responsibility_id%TYPE;
      l_resp_name              fnd_responsibility_tl.responsibility_name%TYPE
                                  := 'CTS Inventory Super User - MOAC';
      l_validation_exception   EXCEPTION;
      i_num                    NUMBER := 1;
      l_item_assign_cost_org   VARCHAR2(1);

      CURSOR get_stg_item (
         l_master_org_id    mtl_parameters.organization_id%TYPE)
      IS
         SELECT a.ROWID, a.*
           FROM apps.mtl_system_items_b a                          --327620833
          WHERE     inventory_item_id = p_item_id
                AND a.organization_id = l_master_org_id;

      CURSOR get_org_details
      IS
           select m.organization_id,
                  m.organization_code,
                  m.attribute10,
                  m.attribute12
                   from (
SELECT mp.organization_id,
                  mp.organization_code,
                  mp.attribute10,
                  mp.attribute12
             FROM apps.mtl_parameters mp, apps.org_organization_definitions ood
            WHERE     (mp.attribute10 = 'Y' OR mp.attribute12 = '108')
                  AND mp.organization_id = ood.organization_id
                  AND NVL (ood.disable_date, SYSDATE + 1) >= TRUNC (SYSDATE)
UNION  
       select DISTINCT mp.cost_organization_id,
                  mp1.organization_code,
                  mp.attribute10,
                  mp.attribute12
             FROM apps.mtl_parameters mp, apps.org_organization_definitions ood,apps.mtl_parameters mp1
            WHERE     (mp.attribute10 = 'Y' OR mp.attribute12 = '108')
                  AND mp.organization_id = ood.organization_id
                  AND NVL (ood.disable_date, SYSDATE + 1) >= TRUNC (SYSDATE)  
                  AND mp.cost_organization_id = mp1.organization_id   )m 
                  where 1=1 
                   and m.organization_id not in (select organization_id from apps.mtl_system_items_b
                  where inventory_item_id =p_item_id )
         ORDER BY 3;
   BEGIN
      log_flow ('Begin');

     <<label1>>
      BEGIN
         SELECT frt.application_id, frt.responsibility_id
           INTO l_resp_appl_id, l_resp_id
           FROM apps.fnd_responsibility_tl frt
          WHERE frt.responsibility_name = l_resp_name;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            log_flow ('Resp ID Does not exists for: ' || l_resp_name);
            RAISE l_validation_exception;
         WHEN OTHERS
         THEN
            log_flow (
                  'Error While Deriving Resp ID and Resp Appl ID for: '
               || l_resp_name);
            RAISE l_validation_exception;
      END label1;

      BEGIN
         SELECT organization_code, organization_id
           INTO l_master_org_code, l_master_org_id
           FROM mtl_parameters
          WHERE organization_code =
                   fnd_profile.VALUE ('XXCTS_INV_MASTER_ORG_CODE');
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            log_flow ('Resp ID Does not exists for: ' || l_resp_name);
            RAISE l_validation_exception;
         WHEN OTHERS
         THEN
            log_flow (
                  'Error While Deriving Resp ID and Resp Appl ID for: '
               || l_resp_name);
            RAISE l_validation_exception;
      END;

      fnd_global.apps_initialize (user_id        => g_user_id,
                                  resp_id        => l_resp_id,
                                  resp_appl_id   => l_resp_appl_id);
      fnd_file.put_line (fnd_file.LOG, 'apps initialized ');

      FOR cr_itm IN get_stg_item (l_master_org_id)
      LOOP
         fnd_file.put_line (fnd_file.LOG, 'item :: ' || cr_itm.segment1);

         FOR c_idx IN get_org_details
         LOOP
            fnd_file.put_line (fnd_file.LOG,
                               'Org Id  :: ' || c_idx.organization_id);
            --? Set local PC to current value
            --l_process_code := cr_itm.process_code;

            --    ? Running style Create or Update only.
            --   IF cr_itm.action_code = 'I' THEN
            l_item_tt (i_num).transaction_type := 'CREATE'; -- ? Replace this with ?UPDATE? for update transaction.
            --      ELSE -- ?U? update
            --        l_item_tt(1).transaction_type  := 'UPDATE';
            --      END IF;
            l_item_tt (i_num).segment1 := cr_itm.segment1;
            l_item_tt (i_num).inventory_item_id := cr_itm.inventory_item_id;
            l_item_tt (i_num).organization_id := c_idx.organization_id; --cr_itm.organization_id;
            l_item_tt (i_num).description := cr_itm.description;
            --l_item_tt(1).long_description           := cr_itm.long_description;
            l_item_tt (i_num).primary_uom_code := cr_itm.primary_uom_code;
            l_item_tt (i_num).inventory_item_status_code :=
               cr_itm.inventory_item_status_code;
            --l_item_tt(1).template_name              := cr_itm.template_name;
            --? General Planning Tab
            l_item_tt (i_num).min_minmax_quantity :=
               cr_itm.min_minmax_quantity;
            l_item_tt (i_num).max_minmax_quantity :=
               cr_itm.max_minmax_quantity;
            l_item_tt (i_num).minimum_order_quantity :=
               cr_itm.minimum_order_quantity;
            l_item_tt (i_num).maximum_order_quantity :=
               cr_itm.maximum_order_quantity;
            l_item_tt (i_num).fixed_lot_multiplier :=
               cr_itm.fixed_lot_multiplier;
            l_item_tt (i_num).source_type := cr_itm.source_type;
            --l_item_tt(1).source_organization_id     := get_org_id(cr_itm.source_organization_code);
            l_item_tt (i_num).source_subinventory :=
               cr_itm.source_subinventory;
            -- Lead Times Tab
            l_item_tt (i_num).full_lead_time := cr_itm.full_lead_time;
            -- physical attributes tab
            l_item_tt (i_num).weight_uom_code := cr_itm.weight_uom_code;
            l_item_tt (i_num).unit_weight := cr_itm.unit_weight;
            l_item_tt (i_num).volume_uom_code := cr_itm.volume_uom_code;
            l_item_tt (i_num).unit_volume := cr_itm.unit_volume;
            l_item_tt (i_num).dimension_uom_code := cr_itm.dimension_uom_code;
            l_item_tt (i_num).unit_length := cr_itm.unit_length;
            l_item_tt (i_num).unit_width := cr_itm.unit_width;
            l_item_tt (i_num).unit_height := cr_itm.unit_height;
            --purchasing tab
            l_item_tt (i_num).buyer_id := NULL;          --cr_itm.buyer_name);
            l_item_tt (i_num).list_price_per_unit :=
               cr_itm.list_price_per_unit;
            --     l_item_tt(1).expense_account            := cr_itm.expense_account;
            l_item_tt (i_num).hazard_class_id := cr_itm.hazard_class_id;
            -- Order Management Tab
            --l_item_tt(1).sales_account              := get_gl_ccid(cr_itm.sales_account);
            --? Costing Tab
            --l_item_tt(1).cost_of_sales_account      := cr_itm.cost_of_sales_account;
            --? attributes
            l_item_tt (i_num).attribute1 := cr_itm.attribute1;
            l_item_tt (i_num).attribute2 := cr_itm.attribute2;
            l_item_tt (i_num).attribute3 := cr_itm.attribute3;
            l_item_tt (i_num).attribute4 := cr_itm.attribute4;
            l_item_tt (i_num).attribute5 := cr_itm.attribute5;
            l_item_tt (i_num).attribute6 := cr_itm.attribute6;
            l_item_tt (i_num).attribute7 := cr_itm.attribute7;
            l_item_tt (i_num).attribute8 := cr_itm.attribute8;
            l_item_tt (i_num).attribute13 := cr_itm.attribute13;
            l_item_tt (i_num).attribute14 := cr_itm.attribute14;
            i_num := i_num + 1;
         END LOOP;

         log_flow ('Calling ego_item_pub.process_items');
         ego_item_pub.process_items (p_api_version     => 1.0,
                                     p_init_msg_list   => fnd_api.g_true,
                                     p_commit          => fnd_api.g_true,
                                     p_item_tbl        => l_item_tt,
                                     x_item_tbl        => x_items_tt,
                                     x_return_status   => x_return_status,
                                     x_msg_count       => x_msg_count);
         log_flow ('x_return_status : ' || x_return_status);

         IF (x_return_status = fnd_api.g_ret_sts_success)
         THEN
            FOR i IN 1 .. x_items_tt.COUNT
            LOOP
               log_flow (
                  'Inventory Item Id : ' || x_items_tt (i).inventory_item_id);
               x_inventory_item_id := x_items_tt (i).inventory_item_id;
               log_flow (
                  '  Organization Id :' || x_items_tt (i).organization_id);
               x_organization_id := x_items_tt (i).organization_id;
            END LOOP;

            COMMIT;
                     /*  log_flow ('Deriving costing org for the rec org : ' || p_org_id);

                        BEGIN
                           SELECT COST_ORGANIZATION_ID
                             INTO l_cost_org
                             FROM apps.mtl_parameters
                            WHERE organization_id = p_org_id;
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              log_flow (
                                 'No COST Org defined for the rec org :' || p_org_id);
                              RAISE l_validation_exception;
                           WHEN OTHERS
                           THEN
                              log_flow (
                                    'Exception in deriving Costing Org for the rec org :'
                                 || p_org_id);
                              RAISE l_validation_exception;
                        END;
                        
                        BEGIN
                           SELECT count(1)
                             INTO l_item_assign_cost_org
                             FROM apps.mtl_system_items_b
                            WHERE organization_id = l_cost_org
                            AND inventory_item_id = p_item_id;
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              log_flow (
                                 'Item :'|| p_item_id||' not assigned to cost org' || l_cost_org);                              
                           WHEN OTHERS
                           THEN
                              log_flow (
                                    'Exception in deriving Item :'|| p_item_id||' assignment to cost org' || l_cost_org);
                              RAISE l_validation_exception;
                        END;

                        log_flow ('Calling Insert item to Cost org :' || l_cost_org);
                            
            IF l_item_assign_cost_org > 1 THEN 
                insert_items_to_cost_org (p_item_id,l_cost_org);
            END IF;*/
         ELSE                  --? ITEM MASTER FAILED Process out the messages
            error_handler.get_message_list (x_message_list => x_message_list);

            FOR i IN 1 .. x_message_list.COUNT
            LOOP
               l_msg := l_msg || '; ' || x_message_list (i).MESSAGE_TEXT;
            END LOOP;

            log_flow ('l_msg : ' || l_msg);
         END IF;
      END LOOP;                                             --? Main Item loop
   EXCEPTION
      WHEN l_validation_exception
      THEN
         log_flow ('Validation Error: ' || SQLERRM);
      WHEN OTHERS
      THEN
         log_flow ('Others Error in Item Load: ' || SQLERRM);
   END insert_items_to_rec_org;

   --START ::Added as part of defect fix : DE166035
   PROCEDURE insert_items_to_cost_org (
      p_item_id   IN mtl_system_items_b.inventory_item_id%TYPE      ,      p_org_id    IN mtl_parameters.organization_id%TYPE DEFAULT NULL
      )
   IS
      l_msg                    VARCHAR2 (4000);
      l_item_tt                ego_item_pub.item_tbl_type;
      x_items_tt               ego_item_pub.item_tbl_type;
      l_master_org_code        mtl_parameters.organization_code%TYPE;
      l_master_org_id          mtl_parameters.organization_id%TYPE;
      x_inventory_item_id      mtl_system_items_b.inventory_item_id%TYPE;
      x_organization_id        mtl_system_items_b.organization_id%TYPE;
      x_return_status          VARCHAR2 (1);
      x_msg_count              NUMBER;
      x_message_list           error_handler.error_tbl_type;
      x_msg                    VARCHAR2 (4000);
      l_resp_appl_id           fnd_responsibility_tl.application_id%TYPE;
      l_resp_id                fnd_responsibility_tl.responsibility_id%TYPE;
      l_resp_name              fnd_responsibility_tl.responsibility_name%TYPE
                                  := 'CTS Inventory Super User - MOAC';
      l_validation_exception   EXCEPTION;
      i_num                    NUMBER := 1;

      CURSOR get_stg_item (
         l_master_org_id    mtl_parameters.organization_id%TYPE)
      IS
         SELECT a.ROWID, a.*
           FROM apps.mtl_system_items_b a                          --327620833
          WHERE     inventory_item_id = p_item_id
                AND a.organization_id = l_master_org_id;

      CURSOR get_cost_org
      IS
         SELECT DISTINCT cost_organization_id
           FROM apps.mtl_parameters
          WHERE organization_id IN (SELECT mp.organization_id
                                      FROM apps.mtl_parameters mp,
                                           apps.org_organization_definitions ood
                                     WHERE     (   mp.attribute10 = 'Y'
                                                OR mp.attribute12 = '108')
                                           AND mp.organization_id =
                                                  ood.organization_id
                                           AND NVL (ood.disable_date,
                                                    SYSDATE + 1) >=
                                                  TRUNC (SYSDATE))
                                                  and  organization_id not in (select organization_id from apps.mtl_system_items_b
                  where inventory_item_id =p_item_id );
   BEGIN
      log_flow ('Begin');

     <<label1>>
      BEGIN
         SELECT frt.application_id, frt.responsibility_id
           INTO l_resp_appl_id, l_resp_id
           FROM apps.fnd_responsibility_tl frt
          WHERE frt.responsibility_name = l_resp_name;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            log_flow ('Resp ID Does not exists for: ' || l_resp_name);
            RAISE l_validation_exception;
         WHEN OTHERS
         THEN
            log_flow (
                  'Error While Deriving Resp ID and Resp Appl ID for: '
               || l_resp_name);
            RAISE l_validation_exception;
      END label1;

      BEGIN
         SELECT organization_code, organization_id
           INTO l_master_org_code, l_master_org_id
           FROM mtl_parameters
          WHERE organization_code =
                   fnd_profile.VALUE ('XXCTS_INV_MASTER_ORG_CODE');
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            log_flow ('Resp ID Does not exists for: ' || l_resp_name);
            RAISE l_validation_exception;
         WHEN OTHERS
         THEN
            log_flow (
                  'Error While Deriving Resp ID and Resp Appl ID for: '
               || l_resp_name);
            RAISE l_validation_exception;
      END;

      fnd_global.apps_initialize (user_id        => g_user_id,
                                  resp_id        => l_resp_id,
                                  resp_appl_id   => l_resp_appl_id);
      log_flow ('apps initialized ');

      FOR cr_itm IN get_stg_item (l_master_org_id)
      LOOP
         log_flow ('item :: ' || cr_itm.segment1);

         FOR c_idx IN get_cost_org
         LOOP
            log_flow ('Cost Org Id :: ' || c_idx.cost_organization_id);
            --? Set local PC to current value
            --l_process_code := cr_itm.process_code;

            --    ? Running style Create or Update only.
            --   IF cr_itm.action_code = 'I' THEN
            l_item_tt (i_num).transaction_type := 'CREATE'; -- ? Replace this with ?UPDATE? for update transaction.
            --      ELSE -- ?U? update
            --        l_item_tt(1).transaction_type  := 'UPDATE';
            --      END IF;
            l_item_tt (i_num).segment1 := cr_itm.segment1;
            l_item_tt (i_num).inventory_item_id := cr_itm.inventory_item_id;
            l_item_tt (i_num).organization_id := c_idx.cost_organization_id; --cr_itm.organization_id;
            l_item_tt (i_num).description := cr_itm.description;
            --l_item_tt(1).long_description           := cr_itm.long_description;
            l_item_tt (i_num).primary_uom_code := cr_itm.primary_uom_code;
            l_item_tt (i_num).inventory_item_status_code :=
               cr_itm.inventory_item_status_code;
            --l_item_tt(1).template_name              := cr_itm.template_name;
            --? General Planning Tab
            l_item_tt (i_num).min_minmax_quantity :=
               cr_itm.min_minmax_quantity;
            l_item_tt (i_num).max_minmax_quantity :=
               cr_itm.max_minmax_quantity;
            l_item_tt (i_num).minimum_order_quantity :=
               cr_itm.minimum_order_quantity;
            l_item_tt (i_num).maximum_order_quantity :=
               cr_itm.maximum_order_quantity;
            l_item_tt (i_num).fixed_lot_multiplier :=
               cr_itm.fixed_lot_multiplier;
            l_item_tt (i_num).source_type := cr_itm.source_type;
            --l_item_tt(1).source_organization_id     := get_org_id(cr_itm.source_organization_code);
            l_item_tt (i_num).source_subinventory :=
               cr_itm.source_subinventory;
            -- Lead Times Tab
            l_item_tt (i_num).full_lead_time := cr_itm.full_lead_time;
            -- physical attributes tab
            l_item_tt (i_num).weight_uom_code := cr_itm.weight_uom_code;
            l_item_tt (i_num).unit_weight := cr_itm.unit_weight;
            l_item_tt (i_num).volume_uom_code := cr_itm.volume_uom_code;
            l_item_tt (i_num).unit_volume := cr_itm.unit_volume;
            l_item_tt (i_num).dimension_uom_code := cr_itm.dimension_uom_code;
            l_item_tt (i_num).unit_length := cr_itm.unit_length;
            l_item_tt (i_num).unit_width := cr_itm.unit_width;
            l_item_tt (i_num).unit_height := cr_itm.unit_height;
            --purchasing tab
            l_item_tt (i_num).buyer_id := NULL;          --cr_itm.buyer_name);
            l_item_tt (i_num).list_price_per_unit :=
               cr_itm.list_price_per_unit;
            --     l_item_tt(1).expense_account            := cr_itm.expense_account;
            l_item_tt (i_num).hazard_class_id := cr_itm.hazard_class_id;
            -- Order Management Tab
            --l_item_tt(1).sales_account              := get_gl_ccid(cr_itm.sales_account);
            --? Costing Tab
            --l_item_tt(1).cost_of_sales_account      := cr_itm.cost_of_sales_account;
            --? attributes
            l_item_tt (i_num).attribute1 := cr_itm.attribute1;
            l_item_tt (i_num).attribute2 := cr_itm.attribute2;
            l_item_tt (i_num).attribute3 := cr_itm.attribute3;
            l_item_tt (i_num).attribute4 := cr_itm.attribute4;
            l_item_tt (i_num).attribute5 := cr_itm.attribute5;
            l_item_tt (i_num).attribute6 := cr_itm.attribute6;
            l_item_tt (i_num).attribute7 := cr_itm.attribute7;
            l_item_tt (i_num).attribute8 := cr_itm.attribute8;
            l_item_tt (i_num).attribute13 := cr_itm.attribute13;
            l_item_tt (i_num).attribute14 := cr_itm.attribute14;
            i_num := i_num + 1;
         END LOOP;

         log_flow ('Calling ego_item_pub.process_items');
         ego_item_pub.process_items (p_api_version     => 1.0,
                                     p_init_msg_list   => fnd_api.g_true,
                                     p_commit          => fnd_api.g_true,
                                     p_item_tbl        => l_item_tt,
                                     x_item_tbl        => x_items_tt,
                                     x_return_status   => x_return_status,
                                     x_msg_count       => x_msg_count);
         log_flow ('x_return_status : ' || x_return_status);

         IF (x_return_status = fnd_api.g_ret_sts_success)
         THEN
            -- Insert_to_costing_org
            FOR i IN 1 .. x_items_tt.COUNT
            LOOP
               log_flow (
                  'Inventory Item Id : ' || x_items_tt (i).inventory_item_id);
               x_inventory_item_id := x_items_tt (i).inventory_item_id;
               log_flow (
                  '  Organization Id :' || x_items_tt (i).organization_id);
               x_organization_id := x_items_tt (i).organization_id;
            END LOOP;

            COMMIT;
         ELSE                  --? ITEM MASTER FAILED Process out the messages
            error_handler.get_message_list (x_message_list => x_message_list);

            FOR i IN 1 .. x_message_list.COUNT
            LOOP
               l_msg := l_msg || '; ' || x_message_list (i).MESSAGE_TEXT;
            END LOOP;

            log_flow ('l_msg : ' || l_msg);
         END IF;
      END LOOP;                                             --? Main Item loop
   EXCEPTION
      WHEN l_validation_exception
      THEN
         log_flow ('Validation Error: ' || SQLERRM);
      WHEN OTHERS
      THEN
         log_flow ('Others Error in Item Load: ' || SQLERRM);
   END insert_items_to_cost_org;
--END ::Added as part of defect fix : DE166035
END xxcts_pr2s_item_org_asgn_pkg;
/