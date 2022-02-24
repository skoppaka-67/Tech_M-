"""
author : Bhavya, Bhanu
VERSION -1
"""
# import flask
# import flask_socketio
import logging
import time
from loguru import logger
import datetime
from pymongo import MongoClient
import config
from tqdm import tqdm
from termcolor import colored
from flask import Flask, request, render_template, jsonify, Response, redirect
# from flask_socketio import SocketIO
import os

app = Flask(__name__)
# async_mode = None
# socket_ = SocketIO(app, async_mode=async_mode)
# import logging
# logging.basicConfig(filename='consolelogs.log')

client = MongoClient('localhost', 27017)
""" The below Instance1,Instance2,Instance3,Instance4,Instance5,Instance6 are variables that contains the  
    instance name fetched from the config file to run the required reports."""

Instance1 = config.Instance1
Instance2 = config.Instance2
Instance3 = config.Instance3
Instance4 = config.Instance4
Instance5 = config.Instance5
Instance6 = config.Instance6

# f = open('D:\Lcaas\one_click\consolelogs.txt', 'a+')
logger.add(r"C:\Users\KS00561356\PycharmProjects\LCaaS\oneclick\static\kirankoppaka.log", format="{time} - {message}")


def cobol():
    print(colored('STARTED GENERATING COBOL REPORTS', 'blue'))
    for i in tqdm(range(1), desc="Loading......"):
        try:
            # db = client[config.database_COBOL['database_name']]
            # if db.collection.count() > 0:
            client.drop_database(
                config.database_COBOL['database_name'])  ## deletes the database if it is already present.
            print('succesfully deleted cobol database')
        except Exception as e:
            print(colored(e, 'Error in deleting cobol database', 'red'))
        try:
            # from COBOL import COBOL_MainInventoryReport  ## Runs the Maininventory report from the COBOL folder
            path = config.cobol_python_path + '\COBOL_MainInventoryReport.py'
            os.system('py ' + path)
            # f.write('cobol master inventory generated successfully')
            # f.close()
            # f.close()
            logger.info('cobol master inventory generated successfully')
            print('COBOL MASTER INVENTORY generated successfully')
        except Exception as e:
            print('error running in cobol master inventory')
        try:
            # from COBOL import COBOL_Glossary_dead  ## Runs the glossary report from the COBOL folder
            path = config.cobol_python_path + '\COBOL_Glossary_dead.py'
            os.system('py' + ' ' + path)
            logger.info('cobol glossary generated successfully, kiran koppaka')
            print('COBOL GLOSSARY generated successfully')
        except Exception as e:
            print(colored(e, 'error running in cobol glossary', 'red'))
        try:
            # from COBOL import jcl_Xref  ## Runs the jcl crossreference report from the COBOL folder
            path = config.cobol_python_path + '\jcl_Xref.py'
            os.system('py' + ' ' + path)
            logger.info('cobol JCL xref generated successfully')

            print('COBOL JCL XREF generated successfully')
        except Exception as e:
            print(colored(e, 'error running in JCL XREF', 'red'))
        # try:
        #     from COBOL import XRefCobol_file_xref                  ## Runs the crosreference report from the COBOL folder
        #     print('COBOL XREF generated successfully')
        # except Exception as e:
        #     print(colored(e, 'error running in Cobol XREF','red'))
        try:
            # from COBOL import COBOL_missing_components_generator  ## Runs the missing component report from the COBOL folder
            path = config.cobol_python_path + '\COBOL_missing_components_generator.py'
            os.system('py' + ' ' + path)
            logger.info('cobol missing report generated successfully')
            print('COBOL MISSING COMPONENT generated successfully')
        except Exception as e:
            print(colored(e, 'error running in cobol missing report', 'red'))
        try:
            # from COBOL import COBOL_orphan_report_generator  ## Runs the orphan report from the COBOL folder
            path = config.cobol_python_path + '\COBOL_orphan_report_generator.py'
            os.system('py' + ' ' + path)
            logger.info('cobol orphan report generated successfully')

            print('COBOL ORPHAN generated successfully')
        except Exception as e:
            print(colored(e, 'error running in cobol orphan report', 'red'))
        try:
            # from COBOL import BRE_optimizedcode_Mainframe_COBOL  ## Runs the BRE1 report from the COBOL folder
            path = config.cobol_python_path + '\BRE_optimizedcode_Mainframe_COBOL.py'
            os.system('py' + ' ' + path)
            logger.info('cobol bre1 generated successfully')
            print('COBOL BRE1 generated successfully')
        except Exception as e:
            print(colored(e, 'error running in cobol BRE1 ', 'red'))
        try:
            # from COBOL import bre_late2_COBOL  ## Runs the BRE2 report from the COBOL folder
            path = config.cobol_python_path + '\\bre_late2_COBOL.py'
            os.system('py' + ' ' + path)
            logger.info('cobol bre2 generated successfully')
            print('COBOL BRE2 generated successfully')
        except Exception as e:
            print(colored(e, 'error running in cobol BRE2', 'red'))
        try:
            # from COBOL import keyword_replace_cobol  ## Runs the keyword report from the COBOL folder
            path = config.cobol_python_path + '\keyword_replace_cobol.py'
            os.system('py' + ' ' + path)
            logger.info('cobol keyword replace generated successfully')
            print('COBOL KEYWORD REPLACE generated successfully')
        except Exception as e:
            print(colored(e, 'error running in cobol annotations', 'red'))
        try:
            # from COBOL import COBOL_flowchart_la31_7_bnsf  ## Runs the flowchart report from the COBOL folder
            path = config.cobol_python_path + '\COBOL_flowchart_la31_7_bnsf.py'
            os.system('py' + ' ' + path)
            logger.info('cobol flowchart generated successfully')
            print('COBOL FLOW CHART generated successfully')
        except Exception as e:
            print(colored(e, 'error running in cobol flowchart', 'red'))
        try:
            # from COBOL import COBOL_fuction_crud_file_ver5  ## Runs the CRUD report from the COBOL folder
            path = config.cobol_python_path + '\COBOL_fuction_crud_file_ver5.py'
            os.system('py' + ' ' + path)
            logger.info('cobol crud generated successfully')
            print('COBOL CRUD generated successfully')
        except Exception as e:
            print(colored(e, 'error running in cobol crud', 'red'))
        # try:
        #     from COBOL import Final_MF_Processflow_Ec_COBOL      ## Runs the processflow external calls report from the COBOL folder
        #     print('COBOL PROCESS FLOW EC generated successfully')
        # except Exception as e:
        #     print(colored(e, 'error running in cobol process flow with external calls ','red'))
        try:
            # from COBOL import COBOL_Final_process_flow_with_exit_dead_para_removed  ## Runs the process flow report from the COBOL folder
            path = config.cobol_python_path + '\COBOL_Final_process_flow_with_exit_dead_para_removed.py'
            os.system('py' + ' ' + path)
            logger.info('cobol processflow generated successfully')
            print('COBOL PROCESS FLOW generated successfully')
        except Exception as e:
            print(colored(e, 'error running in cobol process flow with dead para', 'red'))

        # try:
        #     from COBOL import COBOL_drop_impact                  ## Runs the drop impact report from the COBOL folder
        #     print('COBOL DROP IMPACT generated successfully')
        # except Exception as e:
        #     print(colored(e, 'error running in cobol drop impact','red'))
        try:
            # from COBOL import COBOL_VarImpactCodebase  ## Runs the variable impact report from the COBOL folder
            path = config.cobol_python_path + '\COBOL_VarImpactCodebase.py'
            os.system('py' + ' ' + path)
            logger.info('cobol variable impact report generated successfully')
            print('COBOL VARIMPACT CODEBASE generated successfully')
        except Exception as e:
            print(colored(e, 'error running in cobol variable impact report', 'red'))
        try:
            # from COBOL import commented_lines_COBOL  ## Runs the commented lines report from the COBOL folder
            path = config.cobol_python_path + '\commented_lines_COBOL.py'
            os.system('py' + ' ' + path)
            logger.info('cobol commented report generated successfully')
            print('COBOL COMMENTED LINES generated successfully')
        except Exception as e:
            print(colored(e, 'error running in cobol commented lines', 'red'))
        try:
            # from COBOL import codebase_upload_COBOL  ## Runs the codebase upload report from the COBOL folder
            path = config.cobol_python_path + '\codebase_upload_COBOL.py'
            os.system('py' + ' ' + path)
            logger.info('cobol show code generated successfully')
            print('COBOL CODEBASE generated successfully')
        except Exception as e:
            print(colored(e, 'error running in cobol code base', 'red'))
        try:
            # from COBOL import COBOL_Expanded_codebase_upload  ## Runs the Expanded codebase report from the COBOL folder
            path = config.cobol_python_path + '\COBOL_Expanded_codebase_upload.py'
            os.system('py' + ' ' + path)
            logger.info('cobol expanded codebase generated successfully')
            print('COBOL EXPANDED CODEBASE generated successfully')
        except Exception as e:
            print(colored(e, 'error running in cobol expanded code base', 'red'))
        print(colored('COBOL FILES GEENRATED SUCCESSFULLY'), 'green')
        # except Exception as e:                                       ## Throws error if there is any error in running all COBOL files
        #     print(colored(e, 'Error in running cobol files','red'))


# def natural():
#     print(colored('STARTED GENERATING NATURAL REPORTS', 'yellow'))
#
#     for i in tqdm(range(1), desc="Loading......"):
#         try:
#             client.drop_database(
#                 config.database_NAT['database_name'])  ## deletes the database if it is already present.
#             print('successfully deleted previous NAT database')
#         except Exception as e:
#             print(colored(e, 'error in deleting natural database', 'red'))
#         try:
#             # from NAT import NAT_BRE1  ## Runs the BRE1 report from NAT folder.
#             path = config.natural_python_path + '\\NAT_BRE1.py'
#             os.system('py ' + path)
#             logger.info('natural bre1 generated successfully')
#             print('NAT BRE1 generated successfully')
#
#         except Exception as e:
#             print(colored(e, 'error running in natural BRE1', 'red'))
#         try:
#             # from NAT import NAT_Universal_BRE_2_final  ## Runs the BRE2 report from NAT folder.
#             path = config.natural_python_path + '\\NAT_Universal_BRE_2_final.py'
#             os.system('py ' + path)
#             logger.info('natural bre2 generated successfully')
#             print('NAT BRE2 generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in natural BRE2', 'red'))
#         try:
#             # from NAT import NAT_master_inventory_new  ## Runs the master inventory report from NAT folder.
#             path = config.natural_python_path + '\\NAT_master_inventory_new.py'
#             os.system('py ' + path)
#             logger.info('natural master inventory generated successfully')
#             print('NAT MASTERINVENTORY generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in natural master inventory', 'red'))
#         try:
#             # from NAT import NAT_X_ref  ## Runs the cross reference report from NAT folder.
#             path = config.natural_python_path + '\\NAT_X_ref.py'
#             os.system('py ' + path)
#             logger.info('natural xref generated successfully')
#             print('NAT XREF generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in natural XREF', 'red'))
#         try:
#             # from NAT import NAT_Missing_Comp  ## Runs the missing component report from NAT folder.
#             path = config.natural_python_path + '\\NAT_Missing_Comp.py'
#             os.system('py ' + path)
#             logger.info('natural missing report generated successfully')
#             print('NAT MISSING COMPONENT generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in natural missing report', 'red'))
#         try:
#             # from NAT import NAT_orphan  ## Runs the orphan report from NAT folder.
#             path = config.natural_python_path + '\\NAT_orphan.py'
#             os.system('py ' + path)
#             logger.info('natural orphan report generated successfully')
#             print('NAT ORPHAN generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in natural orphan report', 'red'))
#         try:
#             # from NAT import NAT_Cyclomatic_Complexities  ## Runs the cyclomatic complexity report from NAT folder.
#             path = config.natural_python_path + '\\NAT_Cyclomatic_Complexities.py'
#             os.system('py ' + path)
#             logger.info('natural cyclomatic complexities updated')
#             print('NAT CYCLOMATIC COMPLEXITY generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in natural cyclomatic complexity', 'red'))
#         try:
#             # from NAT import NAT_DB_Variables_Collection  ## Runs the DB variables report from NAT folder.
#             path = config.natural_python_path + '\\NAT_DB_Variables_Collection.py'
#             os.system('py ' + path)
#             logger.info('natural db variables generated successfully')
#             print('NAT DB VARIABLES generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in natural DB variables collection ', 'red'))
#         try:
#             # from NAT import NAT_keyword_replace  ## Runs the keyword replace report from NAT folder.
#             path = config.natural_python_path + '\\NAT_keyword_replace.py'
#             os.system('py ' + path)
#             logger.info('natural keyword replace done')
#             print('NAT KEYWORD REPLACE generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in natural annotations', 'red'))
#         try:
#             # from NAT import nat_flowchart_new  ## Runs the flowchart report from NAT folder.
#             path = config.natural_python_path + '\\nat_flowchart_new.py'
#             os.system('py ' + path)
#             logger.info('natural flowchart generated successfully')
#             print('NAT FLOWCHART generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in natural flowchart', 'red'))
#
#         try:
#             # from NAT import NAT_CRUD  ## Runs the CRUD report from NAT folder.
#             path = config.natural_python_path + '\\NAT_CRUD.py'
#             os.system('py ' + path)
#             logger.info('natural crud generated successfully')
#             print('NAT CRUD generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in natural crud', 'red'))
#
#         # try:
#         #     from NAT import NAT_Process_flow_extcalls                       ## Runs the process flow external calls report from NAT folder.
#         #     print('NAT PROCESS FLOW EC generated successfully')
#         # except Exception as e:
#         #     print(colored(e, 'error running in natural process flow with external calls','red'))
#         try:
#             # from NAT import NAT_ProcessFlow  ## Runs the processflow report from NAT folder.
#             path = config.natural_python_path + '\\NAT_ProcessFlow.py'
#             os.system('py ' + path)
#             logger.info('natural process flow generated successfully')
#             print('NAT PROCESSFLOW generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in natural process flow', 'red'))
#         try:
#             # from NAT import NAT_Glossary  ## Runs the Glossary report from NAT folder.
#             path = config.natural_python_path + '\\NAT_Glossary.py'
#             os.system('py ' + path)
#             logger.info('natural glossary generated successfully')
#             print('NAT GLOSSARY generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in natural glossary', 'red'))
#         try:
#             # from NAT import NAT_drop_impact  ## Runs the drop impact report from NAT folder.
#             path = config.natural_python_path + '\\NAT_drop_impact.py'
#             os.system('py ' + path)
#             logger.info('natural drop impact generated successfully')
#             print('NAT DROP IMPACT generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in natural drop impact ', 'red'))
#         print(colored('NAT FILES GENERATED SUCCESSFULLY'), 'green')
#     # except Exception as e:  ## Throws error if there is any error in running all NATURAL files
#     #     print(colored(e, 'error in running natural files', 'red'))


# def java():
#     print(colored('STARTED GENERATING JAVA REPORTS', 'magenta'))
#     for i in tqdm(range(1), desc="Loading......"):
#         try:
#             try:
#                 client.drop_database(
#                     config.database_JAVA['database_name'])  ## deletes the database if it is already present.
#                 print('successfully deleted previous java database')
#             except Exception as e:
#                 print(colored(e, 'error in deleting java database', 'red'))
#             try:
#                 # from JAVA import component_type  ## Runs the component type report from JAVA folder.
#                 path = config.java_python_path + '\\component_type.py'
#                 os.system('py ' + path)
#                 print('JAVA COMPONENT TYPE generated successfully')
#             except Exception as e:
#                 print(colored(e, 'error running in java component type ', 'red'))
#             try:
#                 # from JAVA import master_inventory  ## Runs the master inventory report from JAVA folder.
#                 path = config.java_python_path + '\\master_inventory.py'
#                 os.system('py ' + path)
#                 print('JAVA MASTER INVENTORY generated successfully')
#             except Exception as e:
#                 print(colored(e, 'error in running java master inventory', 'red'))
#             try:
#                 # from JAVA import master_inventory2  ## Runs the master inventory2 report from JAVA folder.
#                 path = config.java_python_path + '\\master_inventory2.py'
#                 os.system('py ' + path)
#                 print('JAVA MASTER INVENTORY 2 generated successfully')
#             except Exception as e:
#                 print(colored(e, 'error in running java master inventory 2', 'red'))
#             try:
#                 # from JAVA import glossary  ## Runs the glossary report from JAVA folder.
#                 path = config.java_python_path + '\\glossary.py'
#                 os.system('py ' + path)
#                 print('JAVA GLOSSARY generated successfully')
#             except Exception as e:
#                 print(colored(e, 'error in running java glossary', 'red'))
#             try:
#                 # from JAVA import cross_reference  ## Runs the crossrefernce report from JAVA folder.
#                 path = config.java_python_path + '\\cross_reference.py'
#                 os.system('py ' + path)
#                 print('JAVA CROSS REFERNCE generated successfully')
#             except Exception as e:
#                 print(colored(e, 'error in running java XREF', 'red'))
#             try:
#                 # from JAVA import missingreport  ## Runs the missing component report from JAVA folder.
#                 path = config.java_python_path + '\\missingreport.py'
#                 os.system('py ' + path)
#                 print('JAVA MISSING COMPONENT generated successfully')
#             except Exception as e:
#                 print(colored(e, 'error in running java missing report', 'red'))
#             try:
#                 # from JAVA import orphan_report  ## Runs the orphan report from JAVA folder.
#                 path = config.java_python_path + '\\orphan_report.py'
#                 os.system('py ' + path)
#                 print('JAVA ORPHAN generated successfully')
#             except Exception as e:
#                 print(colored(e, 'error in running java orphan report', 'red'))
#             try:
#                 # from JAVA import cyclomatic_complexity  ## Runs the cyclomatic complexity report from JAVA folder.
#                 path = config.java_python_path + '\\cyclomatic_complexity.py'
#                 os.system('py ' + path)
#                 print('JAVA CYCLOMATIC COMPLEXITY generated successfully')
#             except Exception as e:
#                 print(colored(e, 'error in running java cyclomatic complexity', 'red'))
#             try:
#                 # from JAVA import process_flow  ## Runs the process flow report from JAVA folder.
#                 path = config.java_python_path + '\\process_flow.py'
#                 os.system('py ' + path)
#                 print('JAVA PROCESSFLOW generated successfully')
#             except Exception as e:
#                 print(colored(e, 'error in running java process flow', 'red'))
#             try:
#                 # from JAVA import crud_report  ## Runs the CRUD report from JAVA folder.
#                 path = config.java_python_path + '\\crud_report.py'
#                 os.system('py ' + path)
#                 print('JAVA CRUD generated successfully')
#             except Exception as e:
#                 print(colored(e, 'error in running java crud report', 'red'))
#             try:
#                 # from JAVA import bre_rules_report  ## Runs the bre rules report from JAVA folder.
#                 path = config.java_python_path + '\\bre_rules_report.py'
#                 os.system('py ' + path)
#                 print('JAVA BRE generated successfully')
#             except Exception as e:
#                 print(colored(e, 'error in running java bre report', 'red'))
#             try:
#                 # from JAVA import screenfields  ## Runs the screenfields report from JAVA folder.
#                 path = config.java_python_path + '\\screenfields.py'
#                 os.system('py ' + path)
#                 print('JAVA SCREENFILEDS generated successfully')
#             except Exception as e:
#                 print(colored(e, 'error in running java screenfields', 'red'))
#             try:
#                 # from JAVA import flowchart_java  ## Runs the flowchart report from JAVA folder.
#                 path = config.java_python_path + '\\flowchart_java.py'
#                 os.system('py ' + path)
#                 print('JAVA FLOWCHART generated successfully')
#             except Exception as e:
#                 print(colored(e, 'error running in java flowchart', 'red'))
#             try:
#                 # from JAVA import variable_imapact  ## Runs the variable impact report from JAVA folder.
#                 path = config.java_python_path + '\\variable_imapact.py'
#                 os.system('py ' + path)
#                 print('JAVA VARIABLE IMPACT generated successfully')
#             except Exception as e:
#                 print(colored(e, 'error in running java variable impact report', 'red'))
#             try:
#                 # from JAVA import validation_report  ## Runs the validation report from JAVA folder.
#                 path = config.java_python_path + '\\validation_report.py'
#                 os.system('py ' + path)
#                 print('JAVA VALIDATION generated successfully')
#             except Exception as e:
#                 print(colored(e, 'error in running java validation report', 'red'))
#             try:
#                 # from JAVA import screen_simulation  ## Runs the screen simulation report from JAVA folder.
#                 path = config.java_python_path + '\\screen_simulation.py'
#                 os.system('py ' + path)
#                 print('JAVA SCREEN SIMULATION generated successfully')
#             except Exception as e:
#                 print(colored(e, 'error in running java screen simulation', 'red'))
#             try:
#                 # from JAVA import show_code_report  ## Runs the show code report from JAVA folder.
#                 path = config.java_python_path + '\\show_code_report.py'
#                 os.system('py ' + path)
#                 print('JAVA SHOW CODE generated successfully')
#             except Exception as e:
#                 print(colored(e, 'error in running java show code report', 'red'))
#             try:
#                 # from JAVA import comment_line  ## Runs the comment line report from JAVA folder.
#                 path = config.java_python_path + '\\comment_line.py'
#                 os.system('py ' + path)
#                 print('JAVA COMMENT LINE generated successfully')
#             except Exception as e:
#                 print(colored(e, 'error in running java comment line report', 'red'))
#             print(colored('JAVA FILES GENERATED SUCCESSFULLY'), 'green')
#         except Exception as e:  ## Throws error if there is any error in running all JAVA files.
#             print('error in running java files')
#
#
# def vb6():
#     print('STARTED GENERATING VB6 REPORTS')
#     for i in tqdm(range(1), desc="Loading......"):
#         try:
#
#             client.drop_database(
#                 config.database_VB6['database_name'])  ## deletes the database if it is already present.
#             print('successfully deleted previous vb6 database')
#         except Exception as e:
#             print(colored(e, 'error in deleting vb6 database', 'red'))
#
#         try:
#             # from VB6 import crud_report  ## Runs the CRUD report from VB6 folder.
#             path = config.vb6_python_path + '\\crud_report.py'
#             os.system('py ' + path)
#             print('VB6 CRUD generated successfully')
#         except Exception as e:
#             print(colored(e, 'error in running vb6 Xref', 'red'))
#         try:
#             # from VB6 import bre_2_report  ## Runs the BRE2 report from VB6 folder.
#             path = config.vb6_python_path + '\\bre_2_report.py'
#             os.system('py ' + path)
#             print('VB6 BRE generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in Vb6 bre', 'red'))
#         try:
#             # from VB6 import screenfields  ## Runs the screenfields report from VB6 folder.
#             path = config.vb6_python_path + '\\screenfields.py'
#             os.system('py ' + path)
#             print('VB6 SCREENFIELDS generated successfully')
#         except Exception as e:
#             print(colored(e, 'error in running vb6 screenfields', 'red'))
#         try:
#             # from VB6 import master_inventory  ## Runs the master inventory report from VB6 folder.
#             path = config.vb6_python_path + '\\master_inventory.py'
#             os.system('py ' + path)
#             print('VB6 MASTER INVENTORY generated successfully')
#         except Exception as e:
#             print(colored(e, 'error in running vb6 master inventory', 'red'))
#         try:
#             # from VB6 import cross_reference  ## Runs the cross reference report from VB6 folder.
#             path = config.vb6_python_path + '\\cross_reference.py'
#             os.system('py ' + path)
#             print('VB6 CROSSREFERNCE generated successfully')
#         except Exception as e:
#             print(colored(e, 'error in running vb6 crud report', 'red'))
#         try:
#             # from VB6 import Glossary  ## Runs the glossary report from VB6 folder.
#             path = config.vb6_python_path + '\\Glossary.py'
#             os.system('py ' + path)
#             print('VB6 GLOSSARY generated successfully')
#         except Exception as e:
#             print(colored(e, 'error in running vb6 glossary report', 'red'))
#         try:
#             # from VB6 import showcode_report  ## Runs the showcode report from VB6 folder.
#             path = config.vb6_python_path + '\\showcode_report.py'
#             os.system('py ' + path)
#             print('VB6 SHOWCODE generated successfully')
#         except Exception as e:
#             print(colored(e, 'error in running vb6 show code report', 'red'))
#         try:
#             # from VB6 import variable_impact_report  ## Runs the variable impact report from VB6 folder.
#             path = config.vb6_python_path + '\\variable_impact_report.py'
#             os.system('py ' + path)
#             print('VB6 VARIABLE IMPACT generated successfully')
#         except Exception as e:
#             print(colored(e, 'error in running vb6 variable impact report', 'red'))
#         try:
#             # from VB6 import process_flow  ## Runs the process flow report from VB6 folder.
#             path = config.vb6_python_path + '\\process_flow.py'
#             os.system('py ' + path)
#             print('VB6 PROCESSFLOW generated successfully')
#         except Exception as e:
#             print(colored(e, 'error in running vb6 process flow', 'red'))
#         try:
#             # from VB6 import validation_report  ## Runs the validation report from VB6 folder.
#             path = config.vb6_python_path + '\\validation_report.py'
#             os.system('py ' + path)
#             print('VB6 VALIDATION generated successfully')
#         except Exception as e:
#             print(colored(e, 'error in running vb6 validation report', 'red'))
#         try:
#             # from VB6 import cyclomatic_complexity  ## Runs the cyclomatic report from VB6 folder.
#             path = config.vb6_python_path + '\\cyclomatic_complexity.py'
#             os.system('py ' + path)
#             print('VB6 CYCLOMATIC COMPLEXITY generated successfully')
#         except Exception as e:
#             print(colored(e, 'error in running vb6 cyclomatic complexity', 'red'))
#         try:
#             # from VB6 import OrphanMissingReport  ## Runs the orphan report from VB6 folder.
#             path = config.vb6_python_path + '\\OrphanMissingReport.py'
#             os.system('py ' + path)
#             print('VB6 ORPHAN generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in vb6 orphan and missing report', 'red'))
#         try:
#             from VB6 import flow_Chart  ## Runs the flow chart report from VB6 folder.
#             print('VB6 FLOWCHART generated successfully')
#         except Exception as e:
#             print(colored(e, 'error in running vb6 flowchart', 'red'))
#         try:
#             from VB6 import commented_report  ## Runs the comment report from VB6 folder.
#             print('VB6 COMMNET LINES generated successfully')
#         except Exception as e:
#             print(colored(e, 'error in running vb6 comment report', 'red'))
#         print('VB6 FILES GENERATED SUCCESSFULLY')
#         # except Exception as e:                                              ## Throws error if there is any error in running all JAVA files.
#         #     print(colored(e, 'error in running vb6 files','red'))
#
#
# def vbnet():
#     print(colored('STARTED GENERATING VB.NET REPORTS', 'blue'))
#
#     for i in tqdm(range(1), desc="Loading......"):
#         try:
#             client.drop_database(
#                 config.database_VBNET['database_name'])  ## deletes the database if it is already present.
#             print('successfully deleted vbnet database')
#         except Exception as e:
#             print(colored(e, 'Error in deleting vbnet database', 'red'))
#         try:
#             from VBNET import master_inventory  ## Runs the master inventory report from VB6 folder.
#             print('VBNET MASTER INVENTORY generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in vbnet master inventory', 'red'))
#         try:
#             from VBNET import CrossRef  ## Runs the cross refernce report from VB6 folder.
#             print('VBNET CROSS REFRENCE generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in vbnet cross reference', 'red'))
#         try:
#             from VBNET import Glossary  ## Runs the glossary report from VB6 folder.
#             print('VBNET GLOSSARY generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in vbnet glossary', 'red'))
#         try:
#             from VBNET import commented_report  ## Runs the comment report from VB6 folder.
#             print('VBNET COMMENTED LINES generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in vbnet commented report', 'red'))
#         try:
#             from VBNET import MissingReport  ## Runs the missing report from VB6 folder.
#             print('VBNET MISSING COMPONENT generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in vbnet missing report', 'red'))
#         # try:
#         #     from VBNET import OrphanReport                                      ## Runs the orphan report from VB6 folder.
#         #     print('VBNET ORPHAN generated successfully')
#         # except Exception as e:
#         #     print(colored(e, 'error running in vbnet orphan report','red'))
#         try:
#             from VBNET import Process_flow_click_event  ## Runs the process flow report from VB6 folder.
#             print('VBNET PROCESSFLOW generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in vbnet process flow', 'red'))
#         try:
#             from VBNET import CRUD_Report_VB  ## Runs the crud report from VB6 folder.
#             print('VBNET CRUD generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in vbnet crud report', 'red'))
#         try:
#             from VBNET import bre_2_report_vb  ## Runs the BRE2 report from VB6 folder.
#             print('VBNET BRE generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in vbnet rules report', 'red'))
#         try:
#             from VBNET import variable_impact_report  ## Runs the variable impact report from VB6 folder.
#             print('VBNET VARIABLE IMPACT generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in vbnet variable impact report', 'red'))
#         try:
#             from VBNET import screenfields  ## Runs the screenfields report from VB6 folder.
#             print('VBNET SCREENFIELDS generated successfully')
#         except Exception as e:
#             print(e, 'error running in vbnet screenfields')
#         try:
#             from VBNET import validation_report  ## Runs the validation report from VB6 folder.
#             print('VBNET VALIDATION generated successfully')
#         except Exception as e:
#             print('error running in vbnet validation report')
#         try:
#             from VBNET import screen_simulation  ## Runs the screen simulation report from VB6 folder.
#             print('VBNET SCREEN SIMULATION generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in vbnet screen simulation', 'red'))
#         try:
#             from VBNET import showcode_report  ## Runs the showcode report from VB6 folder.
#             print('VBNET SHOWCODE generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in vbnet show code report', 'red'))
#         try:
#             from VBNET import flow_Chart  ## Runs the flowchart report from VB6 folder.
#             print('VBNET FLOWCHART generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in vbnet flowchart', 'red'))
#         print(colored('VBNET FILES GENERATED SUCCESSFULLY'), 'green')
#         # except Exception as e:                                                  ## Throws error if there is any error in running all JAVA files.
#         #     print(colored(e, 'error running in vbnet files','red'))
#
#
# def plsql():
#     print('STARTED GENERATING PLSQL REPORTS')
#     for i in tqdm(range(1), desc="Loading......"):
#         try:
#             client.drop_database(
#                 config.database_PLSQL['database_name'])  ## deletes the database if it is already present.
#             print('successfully deleted previous plsql database')
#         except Exception as e:
#             print(colored(e, 'error in deleting plsql database', 'red'))
#         try:
#             from PLSQL import master_Proc_level_feature  ## Runs the master inventory report from PLSQL folder.
#             print('PLSQL MASTER INVENTORY generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in plsql master inventory ', 'red'))
#         try:
#             from PLSQL import Commented_Lines  ## Runs the commented report from PLSQL folder.
#             print('PLSQL COMMENTED LINES generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in plsql comment lines ', 'red'))
#         try:
#             from PLSQL import BRE_PLSQL  ## Runs the BRE1 report from PLSQL folder.
#             print('PLSQL BRE1 generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in plsql bre 1', 'red'))
#         try:
#             from PLSQL import bre_2_plsql  ## Runs the BRE2 report from PLSQL folder.
#             print('PLSQL BRE2 generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in plsql bre2', 'red'))
#         try:
#             from PLSQL import glosssary  ## Runs the glossary report from PLSQL folder.
#             print('PLSQL GLOSSARY generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in plsql glossary ', 'red'))
#         try:
#             from PLSQL import flowchart_plsql  ## Runs the flowchart report from PLSQL folder.
#             print('PLSQL FLOWCHART generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in plsql flowchart', 'red'))
#         try:
#             from PLSQL import CRUD_Report  ## Runs the crud report from PLSQL folder.
#             print('PLSQL CRUD generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in plsql crud ', 'red'))
#         try:
#             from PLSQL import showcode  ## Runs the showcode report from PLSQL folder.
#             print('PLSQL SHOWCODE generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in plsql show code', 'red'))
#         try:
#             from PLSQL import processflow  ## Runs the process flow report from PLSQL folder.
#             print('PLSQL PROCESSFLOW generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in plsql process flow ', 'red'))
#         try:
#             from PLSQL import var_impact_report  ## Runs the variable impact report from PLSQL folder.
#             print('PLSQL VARIABLE IMPACT generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in plsql variable impact report ', 'red'))
#         try:
#             from PLSQL import Missing_Report1  ## Runs the missing component report from PLSQL folder.
#             print('PLSQL MISSING COMPONENT generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in plsql missing report', 'red'))
#         try:
#             from PLSQL import Orphan_Report1  ## Runs the orphan report from PLSQL folder.
#             print('PLSQL ORPHAN generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in plsql orphan report', 'red'))
#         try:
#             from PLSQL import DropImpct_PLSQL  ## Runs the drop impact report from PLSQL folder.
#             print('PLSQL DROP IMPACT generated successfully')
#         except Exception as e:
#             print(colored(e, 'error running in plsql drop impact', 'red'))
#         print(colored('PLSQL FILES GENERATED SUCCESSFULLY'), 'green')
#         # except Exception as e:                                                      ## Throws error if there is any error in running all PLSQL files.
#         #         print(colored(e, 'error running in plsql files','red'))
#

""" The below main function is used to run the function that has been selected  
according to the user. """


def main():
    # try:
    #     if Instance4 == 'vb6':
    #         vb6()
    # except Exception as e:
    #     print(e)
    # try:
    #     if Instance3 == 'java':
    #         java()
    # except Exception as e:
    #     print(e)
    #
    # try:
    #     if Instance2 == 'natural':
    #         natural()
    # except Exception as e:
    #     print(e)
    # try:
    #     if Instance5 == 'vbnet':
    #         vbnet()
    # except Exception as e:
    #     print(e)
    # try:
    #     if Instance6 == 'plsql':
    #         plsql()
    # except Exception as e:
    #     print(e)
    try:
        if Instance1 == 'cobol':
            cobol()
    except Exception as e:
        print(e)


@app.route('/', methods=['GET', 'POST'])
def one_click_UI():
    if request.method == 'GET':
        return render_template('index.html')
    if request.method == 'POST':
        # dbcobol = request.form.get('dbcobol')
        # app.logger.info('working!!!!!!!!!!!!!!!!!')
        # flask_socketio.send('working')
        # print(dbcobol)
        # dbnatural = request.form.get('dbnatural')
        # print(dbnatural)
        # dbjava = request.form.get('dbjava')
        # dbvb6 = request.form.get('dbvb6')
        # print(dbvb6)
        # dbvbnet = request.form.get('dbvbnet')
        # dbplsql = request.form.get('dbplsql')
        if request.form.getlist('cobol') == ['cobol']:
            # if dbcobol != '':
            #     config_file = open('config.py','a')
            #     lines = config_file.readlines()
            #     if lines[22] == '':
            #         lines[22] = "'database_name' :" + dbcobol
            #     config_file.close()
            #     # config.db_cobol(dbcobol)
            # print(request.form.getlist('cobol'))
            cobol()
    #     if request.form.getlist('natural') == ['natural']:
    #         # if dbnatural !='':
    #         #     config.db_natural(dbnatural)
    #         natural()
    #     if request.form.getlist('java') == ['java']:
    #         # print(dbjava)
    #         # if dbjava !='':
    #         #     config.db_java(dbnatural)
    #         java()
    #     if request.form.getlist('vb6') == ['vb6']:
    #         # if dbvb6 != '':
    #         #     print(dbvb6)
    #         #     config.db_vb6(dbvb6)
    #         vb6()
    #     if request.form.getlist('vbnet') == ['vbnet']:
    #         # if dbvbnet !='':
    #         #     print(dbvbnet)
    #         #     config.db_vbnet(dbvbnet)
    #         vbnet()
    #     if request.form.getlist('plsql') == ['plsql']:
    #         # if dbplsql !='':
    #         #     print(dbplsql)
    #         #     config.db_plsql(dbplsql)
    #         plsql()
    # f.close()
    # os.remove('consolelogs.log')
    return render_template('logger.html')


# configure logger


# adjusted flask_logger
def flask_logger():
    """creates logging information"""
    with open("D:\Lcaas\one_click\static\kirankoppaka.log") as log_info:
        for i in range(25):
            # logger.info(f"iteration #{i}")
            data = log_info.read()
            yield data.encode()
            time.sleep(1)
        # Create empty job.log, old logging will be deleted
        open(r"D:\Lcaas\one_click\static\kirankoppaka.log", 'w').close()


@app.route("/logs", methods=["GET"])
def stream():
    """returns logging information"""
    # Response(flask_logger(), mimetype="text/plain", content_type="text/event-stream")
    # return render_template('index.html')
    return Response(flask_logger(),mimetype="text/plain", content_type="text/event-stream")




# main()
if __name__ == '__main__':
    # os.system('py D:\Lcaas\one_click\COBOL\COBOL_MainInventoryReport.py')
    # path = config.cobol_python_path + '\COBOL_MainInventoryReport.py'
    # os.system('py ' + path)
    # cobol()
    app.run(port=5005, debug=True)
    # socket_.run(app, debug=True)
