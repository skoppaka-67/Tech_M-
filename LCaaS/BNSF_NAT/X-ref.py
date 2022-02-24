import os,re,glob
from collections import OrderedDict
import pandas as pd
from pymongo import MongoClient

#count = [0]*2
count = 0
METADATA = []

client = MongoClient('localhost', 27017)
db = client['BNSF_NAT_SSI']



file_path = r"D:\WORK\POC's\BNSF\SSI\NAT"
map_path = ""

def comment():
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




def copybook(filename,line,type):
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
                    # print(copy_line)
                    copybook_value = copy_line[1]
                    #print(copybook_value)
                    METADATA.append(OrderedDict({
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

                                             }))
                    #



                    return copybook_value

def sub_program(filename,line,type):
    # for filename in glob.glob(os.path.join(file_path,"*.txt")):
    #     f = open(filename,"r")
    #     for line in f.readlines():
    #         if len(line)>7:
    #             line = line[8:]
    #             if line[0] == "*":
    #                 continue
                try:
                    # if re.search(" CALL ",line) or re.search("CALLNAT ",line) and line.lstrip().startswith("CALL") or line.lstrip().startswith("CALLNAT"):
                    if re.search(" CALL ",line) and line.lstrip().startswith("CALL") :

                        call_line = line.split()
                        call_value = call_line[1].strip("'")
                        #print("CALL_VALUE:",call_value)
                        METADATA.append(OrderedDict({'filename': '',
                                                 'component_name': filename,
                                                 'component_type': type,
                                                 'calling_app_name':  'UNKNOWN',

                                                 'called_name': call_value+".cbl",
                                                 'called_type': "COBOL",
                                                 'called_app_name': 'UNKNOWN',
                                                 'dd_name': '',
                                                 'access_mode': '',
                                                 'step_name': '',

                                                 'Comments': ""

                                                 }))

                    if re.search("CALLNAT ",line) and line.lstrip().startswith("CALLNAT"):
                        call_line = line.split()
                        call_value = call_line[1].strip("'")
                        # print("CALL_VALUE:",call_value)
                        METADATA.append(OrderedDict({'filename': '',
                                                     'component_name': filename,
                                                     'component_type': type,
                                                     'calling_app_name': 'UNKNOWN',

                                                     'called_name': call_value + ".NAT",
                                                     'called_type': "NATURAL-PROGRAM",
                                                     'called_app_name': 'UNKNOWN',
                                                     'dd_name': '',
                                                     'access_mode': '',
                                                     'step_name': '',

                                                     'Comments': ""

                                                     }))
                    if re.search("LOCAL USING", line):
                            # print(line)
                            Call_line = line.split()
                            # print("line:",Call_line)
                            call_index = Call_line.index("USING")
                            # print("using:",call_index)
                            map_variable = call_index + 1
                            req_map_variable = Call_line[map_variable]
                            # print("Local:",req_map_variable)
                            METADATA.append(OrderedDict({
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

                            }))
                    if re.search("PARAMETER USING ", line):
                            # print(line)
                            Call_line = line.split()
                            # print("line:",Call_line)
                            call_index = Call_line.index("USING")
                            # print("using:",call_index)
                            map_variable = call_index + 1
                            req_map_variable = Call_line[map_variable]
                            # print("Local:",req_map_variable)
                            METADATA.append(OrderedDict({
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

                            }))


                except Exception as e:
                    print(e)

def maps(filename,line,type):
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
                    METADATA.append(OrderedDict({
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

                                             }))



                    return req_map_variable

def workfiles(filename,line,type):
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
        METADATA.append(OrderedDict({
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

                                    }))

        return workfiles_value
def main():
    # comment()
    # copybook()
    # sub_program()
    # maps()

    comment()
    #db.cross_reference_report.remove()

    files=[r"D:\WORK\POC's\BNSF\SSI\NAT"]
    for filename1 in files:
        os.chdir(filename1)
        for filename in os.listdir(filename1):
            if filename.endswith(".NAT"):
                type = "NATURAL-PROGRAM"
            elif filename.endswith(".MAP"):
                type = "MAP"
            f = open(os.getcwd()+"\\"+filename,"r")
            lines = f.readlines()
            #print(filename)

            for i,line in enumerate(lines):
                if len(line)>5:

                    line = line[6:]
                    # print(line)
                    if line[0] == "*" or line.lstrip().startswith("/*"):
                        # print("comment:",line)
                        continue
                    #global copy_var
                    copybook(filename,line,type)
                    sub_program(filename,line,type)
                    maps(filename,line,type)
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

    # db.cross_reference_report.deleteMany({'type': {"$ne": "metadata"}},{'component_type':"NATURAL-PROGRAM"},{'component_type':"COPYBOOK"})
    db.cross_reference_report.insert_one(h)
    db.cross_reference_report.insert_many(METADATA)


    # df = pd.DataFrame(METADATA)
    # columnsTitles = ['filename','component_name','component_type','calling_app_name','called_name','called_type','called_app_name','dd_name','access_mode','step_name','Comments']
    #
    #
    # writer = pd.ExcelWriter('CrossRef Testing.xlsx', engine ='xlsxwriter')
    # df.reindex(columns=columnsTitles)
    # df.to_excel(writer,'Sheet1', index =False)
    # writer.save()

if __name__ == '__main__':
    main()


