CREATE OR REPLACE PACKAGE APPS./*AppDB: 9632758*/        "XXCTS_PR2S_ITEM_ORG_ASGN_PKG" 
                                             
AS
   /*
   *******************************************************************************
   *File Name    : XXCTS_PR2S_ITEM_ORG_ASGN_PKG_PS.sql
   *Description  : :Assigning Item to the respective org.
   *Author        : salsanka
   *Schema          : APPS
   *History:
   *Date           Author            Change Notes
   *------        --------           ------------------------
   *17 Aug 2017    salsanka          Initial Creation
   *16 Feb 2018    salsanka          Modified as part of defect fix : DE166035 -- Changed item org assignment pkg name
   *******************************************************************************
   */
   PROCEDURE insert_items_to_rec_org (
      p_item_id   IN mtl_system_items_b.inventory_item_id%TYPE      ,      p_org_id    IN mtl_parameters.organization_id%TYPE DEFAULT NULL
      );

   --START:: Added as part of defect fix : DE166035
   PROCEDURE insert_items_to_cost_org (
      p_item_id   IN mtl_system_items_b.inventory_item_id%TYPE      ,      p_org_id    IN mtl_parameters.organization_id%TYPE  DEFAULT NULL
      );

   PROCEDURE log_flow (p_log_message VARCHAR2);
--END:: Added as part of defect fix : DE166035
END xxcts_pr2s_item_org_asgn_pkg;
/