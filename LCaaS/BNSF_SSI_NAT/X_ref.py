import os,re,glob,sys
from collections import OrderedDict
import pandas as pd
from pymongo import MongoClient

#count = [0]*2
count = 0
import config

f=open("D:\\bnsf\\BNSF_NAT\\one_click\\errors.txt","a")
# f.seek(0)
# f.truncate()

cobol_folder_name = config.codebase_information['NAT']['folder_name']
cobol_extension_type = config.codebase_information['NAT']['extension']
map_folder_name= config.codebase_information['MAP']['folder_name']
copy_folder_name= config.codebase_information['COPYBOOK']['folder_name']
client = MongoClient(config.database['hostname'], config.database['port'])
db = client[config.database['database_name']]

# file_path = "D:\\bnsf\\NAT_POC\\NAT"
# map_path = "D:\\bnsf\\NAT_POC\\MAP"

file_path=config.codebase_information["code_location"]+"\\"+cobol_folder_name
map_path= config.codebase_information["code_location"]+"\\"+map_folder_name
#print("fiel",file_path)

def comment():
  try:
    count = 0
    for filename in glob.glob(os.path.join(file_path,"*.NAT")):
        f = open(filename,"r")
        for line in f.readlines():
            if len(line)>8:
                line = line[8:]
                if line[0] == "*":
                    count = count+1
                    #print(count)
    return count
  except Exception as e:
      from datetime import datetime
      exc_type, exc_obj, exc_tb = sys.exc_info()
      fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
      print(exc_type, fname, exc_tb.tb_lineno)
      f.write(str(datetime.now()))
      f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
          exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
      pass


def copybook(filename,line,type):
  try:
    #print("Lines passed:",line)
    # for filename in glob.glob(os.path.join(file_path,"*.txt")):
    #     f = open(filename,"r")
    #     for line in f.readlines():
    #         if len(line)>7:
    #             line = line[8:]
    #             if line[0] == "*":
    #                 continue
                if re.search ("INCLUDE.*",line):
                    copy_line = line.split()
                    copybook_value = copy_line[1]
                    #print(copybook_value)
                    METADATA.append({
                                             'filename' : '',
                                             'component_name': filename,
                                             'component_type': type,
                                             'calling_app_name': 'UNKNOWN',
                                             'called_name': copybook_value +".CPY",
                                             'called_type': "COPYBOOK",
                                             'called_app_name': 'UNKNOWN',
                                              'dd_name': '',
                                             'access_mode': '',
                                             'step_name': '',
                                             'Comments': ""

                                             })
                    #



                    return copybook_value

  except Exception as e:
    from datetime import datetime

    exc_type, exc_obj, exc_tb = sys.exc_info()
    fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
    print(exc_type, fname, exc_tb.tb_lineno)
    f.write(str(datetime.now()))
    f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
        exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
    pass


def sub_program(filename,line,type):
    # for filename in glob.glob(os.path.join(file_path,"*.txt")):
    #     f = open(filename,"r")
    #     for line in f.readlines():
    #         if len(line)>7:
    #             line = line[8:]
    #             if line[0] == "*":
    #                 continue
                try:
                    if re.search(" CALL ",line) or re.search("CALLNAT ",line) and line.lstrip().startswith("CALL") or line.lstrip().startswith("CALLNAT"):

                        call_line = line.split()
                        call_value = call_line[1].strip("'")
                        call_value_1=""
                        if call_value.strip().startswith("#"):
                            for lis in buffer_list:
                                if lis.split(":=")[0].strip()==call_value.strip():
                                    call_value_1=lis.split(":=")[1].strip().replace("'","").replace("\n","")
                        if call_value_1!="":
                            call_value=call_value_1.replace('"','')

                        METADATA.append({'filename': '',
                                                 'component_name': filename,
                                                 'component_type': type,
                                                 'calling_app_name':  'UNKNOWN',
                                                 'called_name': call_value+".NAT",
                                                 'called_type': "NATURAL-PROGRAM",
                                                 'called_app_name': 'UNKNOWN',
                                                 'dd_name': '',
                                                 'access_mode': '',
                                                 'step_name': '',
                                                 'Comments': ""
                                                 })
                    if re.search("LOCAL USING", line):
                            # print(line)
                            Call_line = line.split()
                            # print("line:",Call_line)
                            call_index = Call_line.index("USING")
                            # print("using:",call_index)
                            map_variable = call_index + 1
                            req_map_variable = Call_line[map_variable]
                            # print("Local:",req_map_variable)
                            METADATA.append({
                                'filename': '',
                                'component_name': filename,
                                'component_type': type,
                                'calling_app_name': 'UNKNOWN',
                                'called_name': req_map_variable + ".LDA",
                                'called_type': "LDA",
                                'called_app_name': 'UNKNOWN',
                                'dd_name': '',
                                'access_mode': '',
                                'step_name': '',
                                'Comments': ""

                            })
                    if re.search("PARAMETER USING ", line):
                            # print(line)
                            Call_line = line.split()
                            # print("line:",Call_line)
                            call_index = Call_line.index("USING")
                            # print("using:",call_index)
                            map_variable = call_index + 1
                            req_map_variable = Call_line[map_variable]
                            # print("Local:",req_map_variable)
                            METADATA.append({
                                'filename': '',
                                'component_name': filename,
                                'component_type': type,
                                'calling_app_name': 'UNKNOWN',
                                'called_name': req_map_variable+".PDA",
                                'called_type': "PDA",
                                'called_app_name': 'UNKNOWN',
                                'dd_name': '',
                                'access_mode': '',
                                'step_name': '',
                                'Comments': ""
                            })

                except Exception as e:
                    from datetime import datetime
                    exc_type, exc_obj, exc_tb = sys.exc_info()
                    fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
                    print(exc_type, fname, exc_tb.tb_lineno)
                    f.write(str(datetime.now()))
                    f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
                        exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
                    pass

def maps(filename,line,type):
  try:
    # for filename in glob.glob(os.path.join(file_path,"*.txt")):
    #     f = open(filename,"r")
    #     for line in f.readlines():
    #         if len(line)>7:
    #             line = line[8:]
    #             if line[0] == "*":
    #                 continue
                if re.search("USING MAP",line):
                    #print(line)
                    map_line = line.split()
                    # print("line:",map_line)
                    map_index = map_line.index("MAP")
                    # print("MAPINDEX:",map_index)
                    map_variable = map_index+1
                    req_map_variable = map_line[map_variable].strip("'")
                    # print("MAPPPPPP:",req_map_variable)
                    METADATA.append({
                                             'filename': '',
                                             'component_name': filename,
                                             'component_type': type,
                                             'calling_app_name': 'UNKNOWN',
                                             'called_name': req_map_variable+".MAP",
                                             'called_type': "MAP",
                                             'called_app_name': 'UNKNOWN',
                                             'dd_name': '',
                                             'access_mode': '',
                                             'step_name': '',
                                             'Comments': ""

                                             })

                    return req_map_variable
  except Exception as e:
      from datetime import datetime
      exc_type, exc_obj, exc_tb = sys.exc_info()
      fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
      print(exc_type, fname, exc_tb.tb_lineno)
      f.write(str(datetime.now()))
      f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
          exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
      pass


def workfiles(filename,line,type):
  try:
    if re.search("WORK FILE.*",line):
        workfiles = line.split()
        #print("Workfile:", workfiles)
        workfiles_variable = workfiles[1:4]
        disp = workfiles[0]
        #workfiles_variable = workfiles_variable.strip("'")
        #print("Workfile:", workfiles_variable)
        workfiles_value = " "
        workfiles_value = workfiles_value.join(workfiles_variable)
        #print("Workfile:", workfiles_value)
        METADATA.append({
                                     'filename': '',
                                     'component_name': filename,
                                     'component_type': type,
                                     'calling_app_name': 'UNKNOWN',
                                     'called_name': workfiles_value,
                                     'called_type': "WORK-FILES",
                                     'called_app_name': 'UNKNOWN',
                                     'dd_name': '',
                                     'access_mode': disp,
                                     'step_name': '',
                                     'Comments': ""

                                    })

        return workfiles_value
  except Exception as e:
      from datetime import datetime
      exc_type, exc_obj, exc_tb = sys.exc_info()
      fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
      print(exc_type, fname, exc_tb.tb_lineno)
      f.write(str(datetime.now()))
      f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
          exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
      pass


def callnat(filename,line,type ):
  try:
    if line.strip().startswith("#CALLNAT") and line.__contains__(":="):
        call_value=line.split(":=")[1].replace("'","")
        METADATA.append({'filename': '',
                                     'component_name': filename,
                                     'component_type': type,
                                     'calling_app_name': 'UNKNOWN',
                                     'called_name': call_value.replace("\n","").strip() + ".NAT",
                                     'called_type': "NATURAL-PROGRAM",
                                     'called_app_name': 'UNKNOWN',
                                     'dd_name': '',
                                     'access_mode': '',
                                     'step_name': '',
                                     'Comments': ""
                                     })

    elif line.strip().startswith("FETCH RETURN "):
        fetch_value = line.split("RETURN")[1].split("'")[1]
        METADATA.append({'filename': '',
                         'component_name': filename,
                         'component_type': type,
                         'calling_app_name': 'UNKNOWN',
                         'called_name': fetch_value.replace("\n", "").strip() + ".NAT",
                         'called_type': "NATURAL-PROGRAM",
                         'called_app_name': 'UNKNOWN',
                         'dd_name': '',
                         'access_mode': '',
                         'step_name': '',
                         'Comments': ""
                                       })

    elif re.search("\s*STACK\s*=\s*[(]\s*LOGON\s*",line):
        stack_value= line.split("STACK")[1].split(";")[1]

        METADATA.append({'filename': '',
                         'component_name': filename,
                         'component_type': type,
                         'calling_app_name': 'UNKNOWN',
                         'called_name': stack_value.replace("\n", "").strip() + ".NAT",
                         'called_type': "NATURAL-PROGRAM",
                         'called_app_name': 'UNKNOWN',
                         'dd_name': '',
                         'access_mode': '',
                         'step_name': '',
                         'Comments': ""
                         })

  except Exception as e:
      from datetime import datetime
      exc_type, exc_obj, exc_tb = sys.exc_info()
      fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
      print(exc_type, fname, exc_tb.tb_lineno)
      f.write(str(datetime.now()))
      f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
          exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
      pass


def main():
 try:
    # comment()
    # copybook()
    # sub_program()
    # maps()
    comment()
    #db.cross_reference_report.remove()
    global METADATA
    METADATA = []
    global buffer_list
    files=[file_path]
    for filename1 in files:
        os.chdir(filename1)
        for filename in os.listdir(filename1):
            buffer_list=[]
            if filename.endswith(".NAT"):
                type = "NATURAL-PROGRAM"
            elif filename.endswith(".MAP"):
                type = "MAP"
            f = open(os.getcwd()+"\\"+filename,"r")
            lines = f.readlines()
            #print(filename)
            DEFINE_FLAG=False
            for i,line in enumerate(lines):
                if len(line)>5:
                    line = line[5:]
                    # if line.__contains__("END-DEFINE"):
                    #     DEFINE_FLAG = True
                    # if not DEFINE_FLAG:
                    #     continue

                    #print(line)
                    if line.__contains__("/*") and not line.strip().startswith("*"):
                        line = line.split("/*")[0] + "\n"
                    if line.__contains__(":="):
                        buffer_list.append(line)
                    if line[0] == "*" or line.lstrip().startswith("/*"):
                        # print("comment:",line)
                        continue
                    #global copy_var
                    copybook(filename,line,type )
                    sub_program(filename,line,type)
                    maps(filename,line,type)
                    callnat(filename,line,type)

                    # workfiles(filename,line,type)
                #print("COPY_VAR:",copy_var)

    # for filename in glob.glob(os.path.join(map_path,"*.map")):
    #     f = open(filename, "r")
    #     lines = f.readlines()
    #     # print(filename)
    #
    #     for i, line in enumerate(lines):
    #         if len(line) > 8:
    #
    #             line = line[8:]
    #             print(line)
    #             if line[0] == "*":
    #                 continue
    #             # global copy_var
    #             copybook(filename, line)
    #             sub_program(filename, line)
    #             maps(filename, line)
    #             workfiles(filename, line)

    h = {"type": "metadata", "headers": ["filename", "component_name", "component_type",
                                         "calling_app_name", "called_name", "called_type", "called_app_name", "dd_name", "access_mode",
                                         "step_name","Comments"]}

    db_data = {"data": METADATA,
               "headers": ["filename", "component_name", "component_type","calling_app_name","called_name","called_type","called_app_name",
                           "dd_name", "access_mode", "step_name","Comments"]}

    db.cross_reference_report.delete_many({})
    db.cross_reference_report.insert_one(h)
    output_data=[]
    output_data=[dict(t) for t in {tuple(d.items()) for d in METADATA}]
    #print(output_data)

    db.cross_reference_report.insert_many(output_data)
 except Exception as e:
        from datetime import datetime
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        f.write(str(datetime.now()))
        f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
            exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
        pass

    # df = pd.DataFrame(METADATA)
    # columnsTitles = ['filename','component_name','component_type','calling_app_name','called_name','called_type','called_app_name','dd_name','access_mode','step_name','Comments']
    # writer = pd.ExcelWriter('CrossRef Testing.xlsx', engine ='xlsxwriter')
    # df.reindex(columns=columnsTitles)
    # df.to_excel(writer,'Sheet1', index =False)
    # writer.save()

if __name__ == '__main__':

    main()


f.close()