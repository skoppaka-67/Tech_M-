CREATE OR REPLACE PACKAGE RMKTGADM./*AppDB: 1030336*/            "RC_INV_OUTLET_CCW_REV_ALLOC" 
IS

/*===================================================================================================+
     |                                 Cisco Systems, INC., CALIFORNIA                                   |
     +====================================================================================================+
     | Object Name    RMKTGADM.RC_INV_OUTLET_CCW_REV_ALLOC
     |
     | Module        :

     | Description   :
     |
     | Revision History:
     | -----------------
     | Date        Updated By                               Bug/Case#                  Rev   Comments
     |==========  ================                         ===========                ==== ================================================
     | #######     mohamms2(Mohammed reyaz Shaik)               ACT                    1.0  Created                                                                |
     | 11-Jan-18   mohamms2(Mohammed Reyaz Shaik)          User story# US159221        1.1  As part of Sprint#18 Release resticted to run if it aleady ran in 90mins |
      =================================================================================================== */

PROCEDURE RC_INV_MAIN;

PROCEDURE RC_INV_OUTLET_CCW_REVERSE;


END RC_INV_OUTLET_CCW_REV_ALLOC;
/