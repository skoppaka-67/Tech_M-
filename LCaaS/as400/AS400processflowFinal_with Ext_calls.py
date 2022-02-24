SCRIPT_VERSION = 'v0.3 opening copybooks included'

from pymongo import MongoClient

import glob, copy, os, re
import json
import requests
import pandas as pd
from pandas import ExcelWriter
import linecache
from collections import OrderedDict
import ast
import config1
call_dict ={}
call_dict_list = []
sp_list = ""
case = "caseq"
begin ="begsr"
search_element=["begsr","exsr","caseq"]
end = "endsr"
call_sub = "exsr"
begin_sr = []     #list of All begin subroutines
execute_sr = []   # list of all execute subroutines
lines=[]
to = []
From=" "
fun_repositary=OrderedDict()
child_fun = []
master_alive = set()
Dead_keys= set()
main_excsr = []
METADATA=OrderedDict()
count_of_dead_lines=[]
dead_para_count=[]
dead_para_list=[]
dead_para_list1=" "
total_para_count=[]
tempfilename=''
dead_Metadata=OrderedDict()
output = OrderedDict()
row = OrderedDict()



CopyPath = config1.CopyPath
file = config1.file

client = MongoClient('localhost', 27017)
db = client['as400']


# client = MongoClient(config1.database['mongo_endpoint_url'])
# db = client[config1.database['database_name']]



def expand_copybooks(filename):
    #print(filename)
    file_handle = open(filename, "r")
    for line in file_handle:
        try:
            if line[6].__contains__("*") or re.search("//", line):
                continue
            else:
                copyfile = open("copyexpanded.txt", "a")
                if not line[5] == 'd' or line[5] == 'D':
                    line_list = line.casefold().split()

                    for iter in line_list:
                        if iter.__contains__("/copy"):
                            var = (len(line_list))
                            if var >=2:
                                copyname =line_list[var-1]

                                if copyname.__contains__(","):
                                    copyname_list = copyname.split(",")

                                    var = len(copyname_list)
                                    copyname = copyname_list[var-1]

                                    copyname = copyname + '.cpy'

                                    Copyfilepath = CopyPath + '\\' + copyname

                                    if os.path.isfile(Copyfilepath):
                                        tempcopyfile = open(os.path.join(CopyPath, copyname), "r")
                                        copyfile.write("#########" + " " + "BEGIN" + " " + line + '\n')
                                        for copylines in tempcopyfile.readlines():
                                            copyfile.write(copylines)
                                            copyfile.write('\n')
                                        copyfile.write("#####" + " " + "COPY END" + "####" + '\n')
                                    #else:


                    copyfile.write(line)

                copyfile.close()






        except Exception:

            pass


def read_lines(filename):

    dict = OrderedDict()
    dict_dead=OrderedDict()
    flag = False
    data = []
    file_handle = open(filename, "r")
    fun_name = ''
    count = 0
    storage = []

    for  line in file_handle:

        try:
            if line[6].__contains__("*") or re.search("//", line):
                continue
            else:

                if re.search(end, line.casefold()):  # counting lines
                    # print('end number', index)

                    dict[fun_name] = copy.deepcopy(storage)
                    storage.clear()
                    dict_dead[fun_name] = count
                    count = 2


                    flag = False
                    #  print(line + '------------------------------------------')
                if flag:

                    count = count + 1
                    storage.append(line.strip().casefold())
                    if line.lower().__contains__("call"):
                        templine = line.lower().split()

                        if line.__contains__("callb"):
                            index = templine.index("callb")
                            call_dict[fun_name] = templine[index + 1]
                            call_dict_list.append(copy.deepcopy(call_dict))
                            call_dict.clear()

                        elif line.__contains__("callp"):
                            index = templine.index("callp")
                            call_dict[fun_name] = templine[index + 1].split("(")[0]
                            call_dict_list.append(copy.deepcopy(call_dict))
                            call_dict.clear()

                        else:
                            index = templine.index("call")
                            call_dict[fun_name] = templine[index+1]
                            call_dict_list.append(copy.deepcopy(call_dict))
                            call_dict.clear()




                if  line.casefold().__contains__(begin):
                    flag = True
                    if (re.search('.*begsr$',line,re.IGNORECASE)):
                        new_line1 = line.casefold().strip().split("begsr".casefold())
                        var = len(new_line1)
                        temp_fun_name = new_line1[var - 2]
                        temp_fun_name=temp_fun_name.strip().split()
                        var1 = len(temp_fun_name)
                        fun_name=temp_fun_name[var1-1].casefold().strip()
                        #print(fun_name)

                    else:

                        new_line=line.casefold().strip().split("begsr".casefold())

                        var = len(new_line)
                        fun_name = new_line[var-1].casefold().strip(';').strip()

                        #print(fun_name)

        except Exception as e:
            # print(line)
            pass

    return dict

def findAliveChildren(ele):

   try:
    if fun_repositary[ele] == []:

        master_alive.add(ele)
        return
    else:
        for item in fun_repositary[ele]:
            master_alive.add(ele)
            if item in master_alive:

                continue
            else:

             master_alive.add(item.casefold())
             findAliveChildren(item.casefold())
   except KeyError :
       return

def find_the_main(filename):
    main_excsr.clear()
    file_handle = open(filename, "r")
    Lines_until_begsr=[]
    lines_List = []

    for line in file_handle.readlines():
        if line.__contains__(begin):
            break
        elif (re.search('\s\scas.*', line, re.IGNORECASE)):
            value_list1 = line.split()
            var = len(value_list1)
            fun_name = value_list1[var - 1]
            main_excsr.append(fun_name)
        else:
            Lines_until_begsr.append(line.split())

    for lines in Lines_until_begsr:

        if lines.__contains__("exsr".casefold()):
            index = lines.index("exsr".casefold())
            main_excsr.append(lines[index+1])

    #print(main_excsr)

    return main_excsr



def findinzsr(filename):
    file_handle = open(filename, "r")
    for line in file_handle.readlines():
        if line.lower().__contains__("*inzsr"):
            main_excsr.append("*inzsr")


    return main_excsr




def main():
    for file_location, file_type in file.items():
        for filename in glob.glob(os.path.join(file_location, file_type)):
            tempfilename = filename

            filename = filename.strip(file_location).replace(" ","_") + file_type.strip(".*")
            #print(filename)


            expand_copybooks(tempfilename)

            METADATA[filename]=[]

            output = (read_lines('copyexpanded.txt'))
            #print(json.dumps(output,indent=4))

            fun_repositary.clear()

            master_alive.clear()

            count_of_dead_lines.clear()
            for key in output:

                for i in output[key]:

                    value_list =i.split()

                    if  (value_list.__contains__("exsr".casefold())):
                        index_exsr = value_list.index("exsr".casefold())
                        child_fun.append(value_list[index_exsr+1].casefold().strip(';')) #values of assocative function names which are having exsr in output dict values
                    if (re.search('\s\scas.*',i,re.IGNORECASE)):
                        value_list1=i.split()
                        var = len(value_list1)
                        fun_name = value_list1[var-1]
                        #print(fun_name)

                        child_fun.append(fun_name.casefold())

                #print(child_fun)

                fun_repositary[key ] =copy.deepcopy(child_fun)
                #print(json.dumps(fun_repositary,indent=4))

                child_fun.clear()
            find_the_main('copyexpanded.txt')
            findinzsr('copyexpanded.txt')

            for ele in main_excsr:
                findAliveChildren(ele)

            Dead_keys = (set(fun_repositary.keys() - master_alive))
            # print(main_excsr)
            # print(fun_repositary.keys())
            # print("------------------------")
            # print(master_alive)
            #
            # print("------------------------")
            #
            # print(Dead_keys)

            for item2 in main_excsr:

                row ={"from": "Main","to" : item2,"Name":"Main" }

                METADATA[filename].append(row)
            for call in call_dict_list:

                for k,v in call.items():

                    row = {"from" : k,
                           "to": v.replace("'",""),
                           "Name": "External_Program"
                    }

                    METADATA[filename].append(row)

            call_dict_list.clear()

            for item1 in master_alive:
                try:
                    for i in fun_repositary[item1]:
                        name = item1
                        to = i
                        row = {"from": name, "to": to, "Name": name}
                        METADATA[filename].append(row)
                except KeyError as e :
                    pass

            for item3 in Dead_keys:
                dead_lines_count=0
                dead_lines_count=2
                for i in output[item3]:
                    #print(item3)
                    dead_lines_count = dead_lines_count+1
                count_of_dead_lines.append(dead_lines_count)
                #print(dead_lines_count)


            dead_para_count=len(Dead_keys)
            dead_para_list= list(Dead_keys)
            dead_para_list1 = ",".join(dead_para_list)

            #print(dead_para_list1)


            total_para_count = len(output.keys())

            no_of_dead_lines = sum(count_of_dead_lines)
            component_name = filename.strip(file_location).strip(".").strip(".RPG").replace(" ","_")
            #print(component_name)

            #print(no_of_dead_lines)

            # payload ={"component_name": component_name}, {
            #     "$set": {"dead_para_count": dead_para_count,"dead_para_list":dead_para_list1,
            #              "no_of_dead_lines": no_of_dead_lines, 'total_para_count': total_para_count}}

            #payload = json.dumps(payload)
            #print(json.dumps(payload,indent=4))



            # db.master_inventory_report.update_many({"component_name": component_name}, {
            #     "$set": {"dead_para_count": dead_para_count,"dead_para_list":dead_para_list1,
            #              "no_of_dead_lines": no_of_dead_lines, 'total_para_count': total_para_count}})
            # ##print(dead_para_list)

            os.remove('copyexpanded.txt')



            #print("-------------------------")


        print(json.dumps(METADATA,indent = 4 ))
        # j = json.dumps(METADATA,indent = 4)
        # f = open("ProcessFlow.txt ", "w")
        # f.write(j)
        # f.close()

main()

r = requests.post('http://localhost:5004/api/v1/update/procedureFlow',json={"data":METADATA})
print(r.status_code)
print(r.text)





