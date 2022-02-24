database = {
    'mongo_endpoint_url':'localhost:27017',
    'database_name':'as400'

}


RPG_Path ="D:\AS400\RPG"
CL_Path = 'D:\AS400\CL'
CopyPath = 'D:\AS400\COPY'

file ={ 'D:\AS400\RPG': '*.RPG'}

cl_file={'D:\AS400*\CL':"*.CL"}

xreffile ={ 'D:\AS400*\RPG1': '*.RPG','D:\AS400*\COPY' : '*.CPY'}

shfile ={ 'D:\AS400': '*.RPG','D:\AS400*\COPY' : '*.CPY','D:\AS400*\CL':"*.CL"}



codebase_information = {

    'COBOL':{
        'folder_name':'RPG',
        'extension':'RPG'
    },
    'COPYBOOK':{
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


    'code_location':'D:\\AS400',
    'condition_path':"C:\\C\\sample.xlsx"
    # code_location = "E:\\Work\\Work\\Automation\\Projects\\Mainframe Static Code Analyser\\Nopoor inputs"

}


