database={}
new_database=""
def data(database_ui):
    new_database=database_ui
    database['database_name']=new_database

database['database_name']="BNSF_NAT_SSi_KT"
database['hostname']='localhost'
database['port']=27017


# database = {
#     'hostname': 'localhost',
#     'port': 27017,
#     'database_name': 'BNSF_NAT_POC2'
#
# }

file ={'D:\\WORK\\NAT': '*.NAT'}
#file = {'D:\\NAT': '*.NAT'}

cl_file = {'D:\\BNSF\\POC\\COPY': "*"}
CopyPath = 'D:\\BNSF\\POC\\COPY'

codebase_information = {

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


     'file_location':'D:\\bnsf\\NAT_POC\\NAT',
    #'file_location': 'D:\\NAT',

    # 'condition_path':'C:\C\sample_n.xlsx',
    'condition_path': r'D:\bnsf\NAT_POC\NAT\one_click\\sample_n.xlsx',

     'code_location': 'D:\\bnsf\\NAT_POC'
    #'code_location': 'D:\\',

}
