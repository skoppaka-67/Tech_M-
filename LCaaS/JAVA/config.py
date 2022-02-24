filespath = r"D:\WORK\JAVA"
foldernames = ["src\\com\\masterofproperty\\", "WebContent"]
remainingfilepath = filespath + "\\Property_codedump\\src\\"

dbname = "java"

extensions = ['.java','.jsp','.js','.css']

componenttypecn = "componenttype"

crudcn = "crud_report"
screenfieldcn = "screenfields"
variableimpactcn = "varimpactcodebase"
commentreportcn = "cobol_output"
showcodecn = "codebase"
masterinventorycn = "master_inventory_report"
crossreferencecn = "cross_reference_report"
glossarycn = "glossary"
missingreportcn = "missing_components_report"
orphanreportcn = "orphan_report"
processflowcn = "procedure_flow_table"
brecn = "rule_report"
screensimcn = "screen_simulation"
validationreportcn = "validation_report"



codebase_information = {'VB':{'folder_name':'WebApplications',
                              'extension':'aspx'},
                        'code_location':"D:\\Lcaas_java\\Requirements\\source_files"}

vb = codebase_information['VB']['folder_name']
code_location = codebase_information['code_location']
vb_path = code_location + '\\*'
vb_component_path = "D:\\Lcaas_java\\Requirements\\source_files"