database = {
    'hostname':'localhost',
    'port':27017,

    'database_name':'BNSF_NAT'

}




file ={r"D:\WORK\POC's\BNSF\SSI\NAT": '*.NAT'}

cl_file={}
CopyPath = ''
# cl_file={'D:\\BNSF\\POC\\COPY':"*"}
# CopyPath = 'D:\\BNSF\\POC\\COPY'

codebase_information = {

    'COBOL':{
        'folder_name':'NAT',
        'extension':'NAT'
    },
    'COPYBOOK':{
        'folder_name':'COPYBOOK',
        'extension':'CPY'
    },

    'INCLUDE':{
        'folder_name':'COPYBOOK',
        'extension':'CPY'
    },
    'JCL': {
        'folder_name': 'JCL',
        'extension': 'JCL'
    },
    'PROC': {
        'folder_name': 'PROC',
        'extension': 'PROC'
    },
    'SYSIN': {
        'folder_name': 'SYSIN',
        'extension': 'SYSIN'
    },
    'SCRIPTS':{
        'folder_name': 'SCRIPTS',
        'extension': 'SCR' },


    'file_location':r"D:\WORK\POC's\BNSF\SSI\NAT",
    'condition_path':r"D:\WORK\POC's\BNSF\SSI\sample_n.xlsx",

    'code_location': r"D:\WORK\POC's\BNSF\SSI\NAT"

}
