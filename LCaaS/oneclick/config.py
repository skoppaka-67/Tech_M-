"""
Instances
for running particular instance edit instance as
1.Instance1 = cobol
2.Instance2 = natural
3.Instance3 = java
4.Instance4 = vb6
5.Instance5 = vbnet
6.Instance6 = plsql
"""

Instance1 = ''  ## edit for running cobol instance
Instance2 = ''  ## edit for running natural instance
Instance3 = ''  ## edit for running java instance
Instance4 = ''  ## edit for running vb6 instance
Instance5 = 'vbnet'  ## edit for running vbnet instance
Instance6 = ''  ## edit for running plsql instance

database_COBOL = {
    'hostname': 'localhost',
    'port': 27017,
    'database_name':'COBOL_test'
}

# def db_cobol(dbname):
#     print(dbname)
#     database_COBOL['database_name'] = dbname
#     print(database_COBOL['database_name'])





def db_natural(dbname):
    database_NAT['database_name'] = dbname


def db_java(dbname):
    database_JAVA['database_name'] = dbname


def db_vb6(dbname):
    database_VB6['database_name'] = dbname


def db_vbnet(dbname):
    database_VBNET['database_name'] = dbname


def db_plsql(dbname):
    database_PLSQL['database_name'] = dbname


cobol_python_path = r'C:\Users\KS00561356\PycharmProjects\LCaaS\oneclick\COBOL'
natural_python_path = r'D:\Lcaas\one_click\NAT'
java_python_path = r'D:\Lcaas\one_click\JAVA'
vb6_python_path = r'D:\Lcaas\one_click\VB6'
vbnet_python_path = r'D:\Lcaas\one_click\VBNET'
plsql_python_path = r'D:\Lcaas\one_click\PLSQL'

database_NAT = {
    'hostname': 'localhost',
    'port': 27017,
    'database_name': 'NAT'
}
database_JAVA = {
    'hostname': 'localhost',
    'port': 27017,
    'database_name': 'JAVA'
}
database_VB6 = {
    'hostname': 'localhost',
    'port': 27017,
    'database_name': 'VB6'
}
database_VBNET = {
    'hostname': 'localhost',
    'port': 27017,
    'database_name': 'VBNET'
}
database_PLSQL = {
    'hostname': 'localhost',
    'port': 27017,
    'database_name': 'PLSQL'
}


COBOL_codebase_information = {
    'NAT': {
        'folder_name': 'NAT',
        'extension': 'NAT'
    },

    'COBOL': {
        'folder_name': 'COBOL',
        'extension': 'cbl'
    },
    'NATURAL': {
        'folder_name': 'NATURAL',
        'extension': 'nat'
    },
    'bnsf': {
        'folder_name': 'bnsf',
        'extension': 'cbl'
    },
    'COPYBOOK': {
        'folder_name': 'COPYBOOK',
        'extension': 'cpy'
    },
    'JCL': {
        'folder_name': 'JCL',
        'extension': 'jcl'
    },
    'PROC': {
        'folder_name': 'PROC',
        'extension': 'proc'
    },
    'DCLGEN': {
        'folder_name': 'DCLGEN',
        'extension': 'dclgen'
    },
    'MAP': {
        'folder_name': 'MAP',
        'extension': 'MAP'
    },
    'CTL-PROC': {
        'folder_name': 'CTLPROC',
        'extension': 'CTLPROC'
    },
    'PRF': {
        'folder_name': 'PRF',
        'extension': 'PRF'
    },
    'INCLUDE': {
        'folder_name': 'INCLUDE',
        'extension': 'SCR'},

    'code_location': r'D:\Lcaas\COBOL_IMS\source_files',
    'condition_path': 'D:\Lcaas\one_click\sample.xlsx',

}
NAT_codebase_information = {

    'NAT': {
        'folder_name': 'NAT',
        'extension': 'NAT'
    },
    'COPYBOOK': {
        'folder_name': 'COPYBOOK',
        'extension': 'CPY'
    },
    'JCL': {
        'folder_name': 'JCL',
        'extension': 'JCL'
    },
    'PROC': {
        'folder_name': 'PROC',
        'extension': 'PROC'
    },
    'MAP': {
        'folder_name': 'MAP',
        'extension': 'MAP'
    },
    'INCLUDE': {
        'folder_name': 'INCLUDE',
        'extension': 'SCR'},
    'VB': {
        'folder_name': 'VB',
        'extension': 'vb'},
    'condition_path': 'D:\Lcaas\one_click\sample_n.xlsx',
    'code_location': r'D:\Lcaas\one_click\NAT\source_files\output',
    'cl_file': {'D:\\BNSF\\POC\\COPY': "*"},
    'CopyPath': 'D:\\BNSF\\POC\\COPY'
}
JAVA_codebase_information = {
    'VB': {
        'folder_name': 'WebApplications',
        'extension': 'aspx'
    },
    'code_location': r"D:\Lcaas_java\Requirements\source_files",
    'extensions': [".jsp", ".java", ".css", ".js"],
    'componenttypecn': "componenttype",
    'crudcn': "crud_report",
    'screenfieldcn': "screenfields",
    'variableimpactcn': "varimpactcodebase",
    'commentreportcn': "cobol_output",
    'showcodecn': "codebase",
    'masterinventorycn': "master_inventory_report",
    'crossreferencecn': "cross_reference_report",
    'glossarycn': "glossary",
    'missingreportcn': "missing_components_report",
    'orphanreportcn': "orphan_report",
    'processflowcn': "procedure_flow_table",
    'brecn': "rule_report",
    'screensimcn': "screen_simulation",
    'validationreportcn': "validation_report"
}
VB6_codebase_information = {
    'VB': {
        'folder_name': 'WebApplications',
        'extension': 'aspx'
    },
    'code_location': r"D:\Lcaas\one_click\VB6\source_files\files",
    'Excel_path': "D:\\Keywords\\Natural_BRE_Cookbook.xlsx",
    'crudcn': "crud_report",
    'screenfieldcn': "screenfields",
    'variableimpactcn': "varimpactcodebase",
    'commentreportcn': "cobol_output",
    'showcodecn': "codebase",
    'masterinventorycn': "master_inventory_report",
    'crossreferencecn': "cross_reference_report",
    'glossarycn': "glossary",
    'missingreportcn': "missing_components_report",
    'orphanreportcn': "orphan_report",
    'processflowcn': "procedure_flow_table",
    'brecn': "rule_report",
    'screensimcn': "screen_simulation",
    'validationreportcn': "validation_report",
    'flowchart': "para_flowchart_data"
}
VBNET_codebase_information = {
    'VB': {
        'folder_name': 'aspx',
        'extension': 'aspx'
    },
    'code_location': r'D:\Lcaas\one_click\VBNET\sourcefiles\FILES',
    'condition_path': 'sample.xlsx',
    'crudcn': "crud_report",
    'screenfieldcn': "screenfields",
    'variableimpactcn': "varimpactcodebase",
    'commentreportcn': "cobol_output",
    'showcodecn': "codebase",
    'masterinventorycn': "master_inventory_report",
    'crossreferencecn': "cross_reference_report",
    'glossarycn': "glossary",
    'missingreportcn': "missing_components_report",
    'orphanreportcn': "orphan_report",
    'processflowcn': "procedure_flow_table",
    'brecn': "rule_report",
    'screensimcn': "screen_simulation",
    'validationreportcn': "validation_report",
    'flowchart': "para_flowchart_data"
}
PLSQL_codebase_information = {

    'PKB': {
        'folder_name': 'PKB',
        'extension': 'pkb'
    },
    'PKS': {
        'folder_name': 'PKS',
        'extension': 'pks'
    },
    'NATURAL': {
        'folder_name': 'PKB',
        'extension': 'pkb'
    },
    'PRC': {
        'folder_name': 'PRC',
        'extension': 'prc'
    },
    'FNC': {
        'folder_name': 'FNC',
        'extension': 'fnc'
    },
    'TRG': {
        'folder_name': 'TRG',
        'extension': 'trg'
    },
    'code_location': r'D:\Lcaas\one_click\PLSQL\Source_files'
}

if __name__ == '__main__':
    pass