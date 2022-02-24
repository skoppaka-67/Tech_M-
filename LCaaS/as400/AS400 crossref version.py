import glob,os,re
#import pandas as pd
from collections import OrderedDict
from pymongo import MongoClient
import config1
import json
file = config1.xreffile

cl_file=config1.cl_file

METADATA =[]
PR_LISTS = []
Lists1 = []
Lists2 = []
DICT = {}
Final_Lists = []
storage = ""
positive_values = ""
DATA_LIST = []
value_pr1 = ""
extpgm1 = ""
extpgm = ""
called_value = ""
COPY_DICT = []
item = ""
METADATA1=[]
METADATA2=[]


# client = MongoClient(config1.database['mongo_endpoint_url'])
# db = client[config1.database['database_name']]
client = MongoClient('localhost', 27017)
db = client['as400']


db.cross_reference_report.remove()

# file_list=['*.RPG','*.CPY']



for file_location,file_type in file.items():

        for filename in glob.glob(os.path.join(file_location,file_type)):
                Type = "AS400"

                ModuleName = filename
                ModuleLen = len(ModuleName)

                f = open(ModuleName,"r")

                PR_LISTS.clear()
                Lists1.clear()
                Lists2.clear()
                for data in f:
                    extpgm1 = ""
                    value_pr1 = ""

                    if len(data) >7:

                        data = data[6:72]

                        if data[0] == '*' or re.search("//",data):


                            continue
                        else:

                            if re.search('\spr\s',data):
                                #global extpgm1,value_pr

                                splitted = data.split('  ' + 'pr')


                                if splitted[1].__contains__("extpgm"):

                                        value_pr1 = splitted[0]
                                        Lists1.append(value_pr1.strip())
                                        extpgm1 = splitted[1]
                                        Lists2.append(extpgm1.strip())

                                else:

                                    value_pr = splitted[0]
                                    PR_LISTS.append(value_pr.strip())
                COPY_DICT = dict(zip(Lists1, Lists2))

                f2 = open(ModuleName, "r")
                for data in f2:
                    if len(data) >7:

                        data = data[6:72]


                        if data[0] == '*' or re.search("//",data):


                            continue
                        else:

                            if re.search(r'^\s*call.*', data):
                                variable = data.strip().split()

                                datas = variable[0]
                                called_value = variable[1]
                                called_value = variable[1].strip("'")
                                if datas == "callb" or "callp":
                                    if datas == "callb":
                                        datas = "Bound procedure"
                                    elif datas == "callp":
                                        datas = "Prototype procedure"
                                    else:
                                        datas = "Program"
                                if called_value in list(COPY_DICT.keys()):
                                    storage = COPY_DICT[called_value]

                                else:
                                    storage = ""

                                    if called_value.__contains__("("):
                                        # len1 = len(called_value)
                                        index = called_value.index("(")
                                        called_value1 = called_value[:index]
                                        called_value = called_value1



                                METADATA.append(OrderedDict({'component_name': ModuleName.strip(file_location).strip(file_type).replace(" ","_"),
                                                             'component_type': file_type.strip(".*") ,
                                                             'called_name': called_value,
                                                             'called_type': datas,
                                                             'calling_app_name':"",
                                                             'called_app_name':"",
                                                             'step_name': '',
                                                             'disp': '',
                                                             'Comments': storage,
                                                             'dd_name': '',
                                                             'file_name': ''
                                                             }))

                        if re.search(r'COPY .*',data) or re.search(r'copy .*',data):
                            copy1 = data.strip().split()

                            datas1 = copy1[0]
                            called_value1 = copy1[1]

                            copy_list = called_value1.split(',')

                            source_file = copy_list[0]
                            copy_book = copy_list[1]

                            METADATA.append(OrderedDict({'component_name':  ModuleName.strip(file_location).strip(file_type).replace(" ","_"),
                                             'component_type': file_type.strip(".*"),
                                             'called_name' : called_value1,
                                             'called_type': 'Copybook',
                                             'calling_app_name':"",
                                             'called_app_name':"",
                                             'step_name': '',
                                             'disp': '',
                                             'Comments': '',
                                             'dd_name': '',
                                             'file_name': ''
                                             }))





                Final_Lists.clear()
                f1 = open(ModuleName, "r")

                for data in f1:
                    if len(data) >7:

                        data = data[6:72]


                        if data[0] == '*' or re.search("//",data):


                            continue
                        else:
                            declared_values = ""
                            for declared_values in PR_LISTS:

                                if declared_values.casefold() in data.casefold():
                                    Final_Lists.append(declared_values)


                DICT.clear()
                for word in Final_Lists:

                    DICT[word] = DICT.get(word, 0) + 1


                for key,values in DICT.items():

                    if values >1:
                        positive_values = "Used"
                        storage = key

                    else:
                        positive_values = "Not Used"
                        storage = key

                    METADATA.append(OrderedDict({'component_name': ModuleName.strip(file_location).strip(file_type).replace(" ","_"),
                                             'component_type': file_type.strip(".*"),
                                             'called_name': storage,
                                             'called_type': 'Procedure',
                                             'calling_app_name':"",
                                             'called_app_name':"",
                                             'step_name': '',
                                             'disp': '',
                                             'Comments': positive_values,
                                             'dd_name': '',
                                             'file_name': ''
                                             }))

                f2 = open(ModuleName, "r")
                for data in f2:
                    extpgm1 = ""
                    value_pr1 = ""

                    if len(data) > 7:

                        data = data[5:72]

                        if data[1] == '*' or re.search("//", data):

                            continue
                        else:
                            if data[0] == 'f':
                                data = data[1:]

                                if data.casefold().__contains__("disk"):

                                    data = data.split()
                                    file_value = data[0]

                                    file_description = ' '.join(data[1:])
                                    modes = file_description[0]

                                    if modes == "i":
                                        mode_description = "INPUT MODE"
                                    elif modes == "o":
                                        mode_description = "OUTPUT MODE"
                                    elif modes == "u":
                                        mode_description = "UPDATE MODE"
                                    elif modes == "c":
                                        mode_description = "COMBINED MODE"
                                    METADATA.append(
                                        {'component_name': ModuleName.strip(file_location).strip(file_type).replace(
                                            " ", "_"),
                                         'component_type': file_type.strip(".*"),
                                         'called_name': file_value,
                                         'called_type': "FILE",
                                         'calling_app_name':"",
                                         'called_app_name':"",
                                         'step_name': '',
                                         'disp': mode_description,
                                         'Comments': file_description,
                                         'dd_name': '',
                                         'file_name': ''
                                         })
                                if data.__contains__("workstn"):

                                    data = data.split()
                                    file_value = data[0]
                                    file_description = ' '.join(data[1:])
                                    modes = file_description[0]

                                    if modes == "i":
                                        mode_description = "INPUT MODE"
                                    elif modes == "o":
                                        mode_description = "OUTPUT MODE"
                                    elif modes == "u":
                                        mode_description = "UPDATE MODE"
                                    elif modes == "c":
                                        mode_description = "COMBINED MODE"
                                    METADATA.append(
                                        {'component_name': ModuleName.strip(file_location).strip(file_type).replace(
                                            " ", "_"),
                                         'component_type': file_type.strip(".*"),
                                         'called_name': file_value,
                                         'called_type': "DISPLAY FILE",
                                         'calling_app_name':"",
                                         'called_app_name':"",
                                         'step_name': '',
                                         'disp': mode_description,
                                         'Comments': file_description,
                                         'dd_name': '',
                                         'file_name': ''
                                         })


        h = {"type": "metadata", "headers": [ "component_name", "component_type", "called_name",
                                             "called_type",  'calling_app_name',
                                                         'called_app_name',"dd_name", "disp", "step_name", "Comments"]}


        db_data ={"data": METADATA,
                     "headers": ["component_name", "component_type", "called_name",
                                             "called_type",  'calling_app_name',
                                                         'called_app_name',"dd_name", "disp", "step_name", "Comments"]}
db.cross_reference_report.insert_one(h)
db.cross_reference_report.insert_many(METADATA)
print(METADATA)
for file_location,file_type in cl_file.items():
    for filename in glob.glob(os.path.join(file_location,file_type)):
        ModuleName = filename


        f = open(ModuleName, "r")

        for data in f:
            DATA_LIST = data.split()
            if len(DATA_LIST) > 1:

                if DATA_LIST[0].__contains__('/*') and DATA_LIST[-1].__contains__('*/'):

                    continue

                else:


                     lines = ' '.join(str(e) for e in DATA_LIST)


                     if re.search(r'DCLF .*', lines) or re.search(r'dclf .*', lines):
                            lines_splitted = lines.strip().split()

                            fname = lines_splitted[1]
                            if fname.__contains__("("):
                                index = fname.index("(")
                                called_value1 = fname[index+1:-1]
                                fname = called_value1

                                METADATA1.append(OrderedDict({'component_name': ModuleName.strip(file_location).replace(" ","_").strip("."),
                                                         'component_type': file_type.strip("*."),
                                                         'called_name': fname,
                                                         'called_type': 'File',
                                                         'calling_app_name':"",
                                                         'called_app_name':"",
                                                         'step_name': '',
                                                         'disp': '',
                                                         'Comments': '',
                                                         'dd_name': '',
                                                         'file_name': ''}))




                     if re.search(r'CALLPRC .*', lines) or re.search(r'callprc .*', lines):

                         callprc_value = lines[lines.find("PRC(")+4 : lines.find(")")]


                         METADATA1.append(OrderedDict({'component_name': ModuleName.strip(file_location).replace(" ","_").strip("."),
                                                        'component_type': file_type.strip("*."),
                                                        'called_name': callprc_value,
                                                        'called_type': 'Procedure',
                                                        'calling_app_name':"",
                                                        'called_app_name':"",
                                                        'step_name': '',
                                                        'disp': '',
                                                        'Comments': '',
                                                        'dd_name': '',
                                                        'file_name': ''}))

                     if re.search(r'CALL .*', lines) or re.search(r'call .*', lines):

                        pgmvalue = lines[lines.find("PGM(")+4 : lines.find(")")]

                        METADATA1.append(OrderedDict({'component_name': ModuleName.strip(file_location).replace(" ","_").strip("."),
                                                     'component_type': file_type.strip("*."),
                                                     'called_name': pgmvalue,
                                                     'called_type': 'Program',
                                                     'calling_app_name':"",
                                                     'called_app_name':"",
                                                     'step_name': '',
                                                     'disp': '',
                                                     'Comments': '',
                                                     'dd_name': '',
                                                     'file_name': ''}))



    db.cross_reference_report.insert_many(METADATA1)

    #print(METADATA1)