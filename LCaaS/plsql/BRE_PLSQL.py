import xlrd,os,copy,re,glob,xlsxwriter,openpyxl
from pymongo import MongoClient
import time,datetime ,pytz
import timeit
import config
import json

client = MongoClient('localhost', 27017)
db = client['plsql']

# client = MongoClient(config.database['hostname'], config.database['port'])
# db = client[config.database['database_name']]

cobol_folder_name = config.codebase_information['NATURAL']['folder_name']
code_location =config.codebase_information['code_location']
CobolPath=code_location+'\\'+cobol_folder_name


def type1(filename):
    Program_Name = open(filename)
    print(filename)
    comment_flag = False
    begin_flag = False
    procedure_name = ""
    end_procedure_name = ""

    for line in Program_Name.readlines():

        first_line=re.findall(r'^\s*CREATE\s*OR\s*REPLACE\s*.*',line)

        if line.strip().startswith('/*'):
            comment_flag = True

        if line.strip().endswith('*/'):
            comment_flag = False
            continue
        if line.strip()=="":
            continue

        if line.strip().startswith('--') or comment_flag:
           continue
        else:

            with open("source_line" + '.txt', "a+") as source_file:

                if first_line!=[]:
                    source_file.write(line+'\n')

                if line.strip().startswith('PROCEDURE '):

                    source_file.write(line)
                    procedure_name= line.split()
                    if procedure_name[1].__contains__('('):
                        procedure_name=procedure_name[1].split('(')
                        procedure_name=procedure_name[0]
                    else:
                        procedure_name=procedure_name[1]

                if line.strip().startswith('BEGIN'):

                    begin_flag=True
                if begin_flag:

                  source_file.write(line)

                  if line.strip().startswith('END '):

                      end_procedure_name=line.split()

                      if end_procedure_name[1].endswith(';'):

                            end_procedure_name=end_procedure_name[1]

                            if procedure_name==end_procedure_name[:-1]:

                                begin_flag=False

            source_file.close()

    onelinebuffer = []
    actualline=""
    onelineflag=False
    keyword=["ELSE","BEGIN","PROCEDURE","IF","FOR","FORALL","THEN","LOOP","EXCEPTION","SELECT","INSERT","END","UPDATE","DELETE","RETURN","WHEN"]
    with open("source_line" + '.txt', "r+") as source_file1:

        with open("one_line_file" + '.txt', "a+") as one_file:

            for line in source_file1.readlines():
             if line.strip()=="":
                continue
             else:
                line=line.replace('\n','')
                source_line_split=line.split()
                actualline=line
                if source_line_split[0] in keyword :

                    if onelinebuffer != []:
                        line5 = ""
                        for data in range(len(onelinebuffer)):
                            line5 = line5 + onelinebuffer[data]
                            onelineflag = False

                        #line5 = line5 + ' ^' + onelinesplit[1]
                        one_file.write('\n')
                        one_file.write(line5)
                        onelinebuffer = []
                        if source_line_split[0] in keyword and actualline.__contains__(';') or line.strip().startswith('THEN') or line.strip().startswith('END IF') or line.strip().startswith('BEGIN') or \
                            line.strip().startswith('LOOP') or line.strip().startswith('END-LOOP') or line.strip().startswith('END') or line.strip().startswith('ELSE') or line.strip().startswith('ELSIF')  :
                            one_file.write('\n')
                            one_file.write(line)

                            continue
                        else:

                            onelineflag = True
                            actualline = actualline + ' ' + '<br>' + ' '
                            onelinebuffer.append(actualline)
                            continue
                    else:
                        if line.__contains__(';'):
                            one_file.write('\n')
                            one_file.write(line)
                            continue
                        else:
                            if line.strip().startswith('ELSE'):
                                one_file.write('\n')
                                one_file.write(line)

                            else:
                                onelineflag = True
                                actualline = actualline + ' ' + '<br>' + ' '
                                onelinebuffer.append(actualline)
                                continue
                elif actualline.__contains__(';'):
                    if onelineflag:
                               onelineflag = False
                               #actualline = actualline + '           ^'+onelinesplit[1]
                               onelinebuffer.append(actualline)
                               line = ""
                               for data in range(len(onelinebuffer)):
                                   line = line + onelinebuffer[data]
                               one_file.write('\n')
                               one_file.write(line)
                               onelinebuffer=[]
                               continue
                    else:
                        onelinebuffer.append(line)
                        if onelinebuffer != []:
                            line5 = ""
                            for data in range(len(onelinebuffer)):
                                line5 = line5 + onelinebuffer[data]

                            one_file.write('\n')
                            one_file.write(line5)

                elif onelineflag:

                    actualline = actualline + ' ' + '<br>' + ' '
                    onelinebuffer.append(actualline)
                    continue

                else:

                    if line.strip().startswith('ELSE'):
                        one_file.write('\n')
                        one_file.write(line5)

                    else:
                        actualline = actualline + ' ' + '<br>' + ' '
                        onelinebuffer.append(actualline)
                        continue


                onelinebuffer = []

    one_file.close()
    source_file1.close()


    BR=['IF',"THEN",'ELSIF','CASE','WHEN']
    CR=['ELSE']
    CF=["SELECT","INSERT","UPDATE","DELETE"]
    TA=['LOOP','WHILE','FOR','FORALL','PROCEDURE','COMMIT']
    TR=['EXCEPTION']
    METADATA=[]
    rule_number=0
    package_name=""
    function_name=""
    single_proc_name=""
    trigger_name=""
    parent_rule_id=[]
    case_flag=False
    exception_flag=False
    with open("one_line_file" + '.txt', "r+") as input_file:
        for input_line in input_file:

            # input_line=input_line.replace('<br>','\n')
            package= re.findall(r'^\s*CREATE\s*OR\s*REPLACE\s*.*', input_line)

            if package!=[]:

                split_line=input_line.split()

                if split_line[0]=="CREATE" and split_line[1]=="OR" and split_line[3]=="PACKAGE" and split_line[4]=="BODY" :

                    package_name=filename.split("\\")[-1].split(".")[0]

                elif split_line[0]=="CREATE" and split_line[3]=="PROCEDURE":
                    #single_proc_name=split_line[4]
                    procedure_name=split_line[4]

                elif split_line[0]=="CREATE" and split_line[3]=="FUNCTION":

                    function_name =  split_line[4]

                elif split_line[0]=="CREATE" and split_line[3]=="TRIGGER":

                    trigger_name =  split_line[4]

            if input_line.strip()=="":
                continue
            input_line1=input_line.split()
            rule_number=rule_number+1
            if input_line.strip().startswith('PROCEDURE '):
                # rule_number = 1 #procedure level rule sepration
                procedure_name = input_line.split()
                if procedure_name[1].__contains__('('):
                    procedure_name = procedure_name[1].split('(')
                    procedure_name = copy.deepcopy(procedure_name[0])
                else:
                    procedure_name = copy.deepcopy(procedure_name[1])

            rule_id=filename.split("\\")[-1].split(".")[0] +'-'+str(rule_number)

            ifregexx = re.match('^\s*IF\s.*', input_line,re.IGNORECASE)
            endifregexx = re.match('\s*END\s*IF.*', input_line,re.IGNORECASE)
            else_if_regexx = re.match('\s*ELSIF.*', input_line,re.IGNORECASE)
            when_regexx = re.match('.*\sWHEN\s.*', input_line,re.IGNORECASE)
            case_regexx = re.match('^\s*CASE\s.*', input_line,re.IGNORECASE)
            end_case_regexx = re.match('^\s*END\s*CASE.*', input_line,re.IGNORECASE)
            exception_regexx = re.match('\s*EXCEPTION.*', input_line,re.IGNORECASE)

            if ifregexx != None:
                parent_rule_id.append(rule_id)


            if exception_regexx!=None:
                exception_flag=True

            if else_if_regexx!=None:
                p_id_list_len2 = len(parent_rule_id)
                if parent_rule_id != []:
                    del parent_rule_id[p_id_list_len2 - 1]
                parent_rule_id.append(rule_id)

            if case_regexx!=None:
                when_counter=0
                case_flag=True

            if case_flag:

                if when_regexx!=None:
                    when_counter=when_counter+1
                    if when_counter==1:
                        parent_rule_id.append(rule_id)
                    elif when_counter>1:
                        p_id_list_len2 = len(parent_rule_id)
                        if parent_rule_id != []:
                            del parent_rule_id[p_id_list_len2 - 1]
                        parent_rule_id.append(rule_id)

            if input_line1[0] in  BR:

                rule_catg_br="Business Rule"
                if exception_flag:
                    if when_regexx!=None:
                        rule_catg_br ="Technical Rule"


                METADATA.append({'s_no': '', 'procedure_name': procedure_name,'function_name':function_name,'trigger_name':trigger_name,
                                 'fragment_Id': rule_id,
                                 'para_name': '', 'source_statements': input_line.strip(), 'package_name': package_name,
                                 'rule_category': rule_catg_br,
                                 'parent_rule_id': ",".join(parent_rule_id), 'business_documentation': ''})

                continue
            elif input_line1[0] in CR:
                METADATA.append({'s_no': '', 'procedure_name': procedure_name,'function_name':function_name,'trigger_name':trigger_name,
                                 'fragment_Id': rule_id,
                                 'para_name': '', 'source_statements': input_line.strip(), 'package_name': package_name,
                                 'rule_category': "Connected Business Rule",
                                 'parent_rule_id': ",".join(parent_rule_id), 'business_documentation': ''})
                continue
            elif input_line1[0] in CF:
                METADATA.append({'s_no': '', 'procedure_name': procedure_name,'function_name':function_name,'trigger_name':trigger_name,
                                 'fragment_Id': rule_id,
                                 'para_name': '', 'source_statements': input_line.strip(), 'package_name': package_name,
                                 'rule_category': "CRUD Fragment",
                                 'parent_rule_id': ",".join(parent_rule_id), 'business_documentation': ''})
                continue
            elif input_line1[0] in TA:
                METADATA.append({'s_no': '', 'procedure_name': procedure_name,'function_name':function_name,'trigger_name':trigger_name,
                                 'fragment_Id': rule_id,
                                 'para_name': '', 'source_statements': input_line.strip(), 'package_name': package_name,
                                 'rule_category': "Technical Action",
                                 'parent_rule_id': ",".join(parent_rule_id), 'business_documentation': ''})

                continue
            elif input_line1[0] in TR:
                METADATA.append({'s_no': '', 'procedure_name': procedure_name,'function_name':function_name,'trigger_name':trigger_name,
                                 'fragment_Id': rule_id,
                                 'para_name': '', 'source_statements': input_line.strip(), 'package_name': package_name,
                                 'rule_category': "Technical Rule",
                                 'parent_rule_id': ",".join(parent_rule_id), 'business_documentation': ''})

                continue
            else:
                rule_catg="Other Action"
                if input_line.__contains__(':='):
                    rule_catg="Business Action"
                if input_line.strip().startswith('END '):
                    if endifregexx!=None:
                        rule_catg = "Business Rule"
                    elif end_case_regexx!=None:
                        rule_catg = "Business Rule"
                    else:
                        exception_flag=False
                        rule_catg = "Technical Rule"
                METADATA.append({'s_no': '', 'procedure_name': procedure_name,'function_name':function_name,'trigger_name':trigger_name,
                                 'fragment_Id': rule_id,
                                 'para_name': '', 'source_statements': input_line.strip(), 'package_name': package_name,
                                 'rule_category': rule_catg,
                                 'parent_rule_id': ",".join(parent_rule_id), 'business_documentation': ''})

                if endifregexx != None:
                    p_id_list_len2 = len(parent_rule_id)
                    if parent_rule_id != []:
                        del parent_rule_id[p_id_list_len2 - 1]

                if end_case_regexx != None:
                    when_counter = 0
                    case_flag = False
                    p_id_list_len2 = len(parent_rule_id)
                    if parent_rule_id != []:
                        del parent_rule_id[p_id_list_len2 - 1]
                continue
    print(json.dumps(METADATA,sort_keys=False,indent=4))
    db.bre_rules_report.insert_many(METADATA)
    os.remove("source_line.txt")
    os.remove("one_line_file.txt")
    import csv
    keys = METADATA[0].keys()
    with open('CICS2.csv', 'w') as output_file:
          dict_writer = csv.DictWriter(output_file, keys)
          dict_writer.writeheader()
          dict_writer.writerows(METADATA)

    #os.remove('CICS2.csv')
for filename in glob.glob(os.path.join(CobolPath, '*.pkb')):
    type1(filename)
for filename in glob.glob(os.path.join(CobolPath, '*.fnc')):
    type1(filename)
for filename in glob.glob(os.path.join(CobolPath, '*.trg')):
    type1(filename)
for filename in glob.glob(os.path.join(CobolPath, '*.prc')):
    type1(filename)
