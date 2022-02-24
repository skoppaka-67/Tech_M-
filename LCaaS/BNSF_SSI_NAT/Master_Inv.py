import os,sys
import config
from pymongo import MongoClient
import requests

# client = MongoClient("localhost", 27017)
# db = client["BNSF_NAT_POC"]
#client = MongoClient(config.database['hostname'], config.database['port'])
#db = client[config.database['database_name']]
metadata = []

os.chdir(config.codebase_information["file_location"])
#os.chdir(r'D:\NAT')


f = open('D:\\bnsf\\BNSF_NAT\\one_click\\errors.txt', 'a')
f.seek(0)
f.truncate()


def file_oper(file, typeoffile):
    try:
        whole_content = [0] * 6
        # #print(nol)
        comment_lines = 0
        empty_lines = 0
        nol =0
        if (typeoffile == "NAT") or (typeoffile == "MAP"):
            if (typeoffile == "NAT"):
                typeoffile = "NATURAL-PROGRAM"
            if ((typeoffile == "MAP")):
                typeoffile = "MAP"

        # os.chdir(r"C:\Users\SG00561466\Downloads\natural_adabas")
            str2file = os.getcwd() + "\\" + file
            #print(str2file)
            open_file = open(str2file).readlines()
            nol = len(open_file)
            for i in range(nol):
                # file_proc.write(open_file[i].lstrip())
                if (len(open_file[i]) > 4) and open_file[i][6:].strip()!="" :
                    if (open_file[i][6] == "*" or open_file[i][8] == ("*") or (
                            open_file[i][5].lstrip().startswith("/*"))):
                        comment_lines += 1
                    elif open_file[i].strip() == "":
                        empty_lines += 1
        if (typeoffile == "PDA") or typeoffile == "LDA":
            if typeoffile == "PDA":
                typeoffile = "PDA"
            elif typeoffile == "LDA":
                typeoffile = "LDA"
            str2file = os.getcwd() + "\\" + file
            open_file = open(str2file).readlines()
            nol = len(open_file)
            # #print(nol)
            comment_lines = 0
            empty_lines = 0
            for i in range(nol):
                line = open_file[i].lstrip()
                if (len(line) > 4):
                    if (line.__contains__("**C") or line.__contains__("/*C") ):
                        comment_lines += 1
                    elif open_file[i].strip() == "":
                        empty_lines += 1

        if (typeoffile == "DDM"):
            typeoffile = "DDM"
            str2file = os.getcwd() + "\\" + file
            open_file = open(str2file).readlines()
            nol = len(open_file)
            # #print(nol)
            comment_lines = 0
            empty_lines = 0
            for i in range(nol):
                if (open_file[i][0] == "*" or open_file[i][0] == ("*") or (
                        open_file[i][0].lstrip().startswith("/*"))):
                    comment_lines += 1
                elif open_file[i].strip() == "":
                        empty_lines += 1

        if (nol != 0):
            exec_lines = nol - comment_lines - empty_lines
            whole_content[0] = nol
            whole_content[1] = comment_lines
            whole_content[2] = empty_lines
            whole_content[3] = exec_lines
            whole_content[4] = typeoffile
            # #print(whole_content)
            whole_content[5] = file
            # file_proc.close()

            return whole_content
    except Exception as e:
        from datetime import datetime
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        f.write(str(datetime.now()))
        f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
            exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
        pass


# file_path = r"C:\Users\SG00561466\Downloads\nat_file"
try:
    for files in os.listdir():
        if (files):
            print(files)
            filetype=files.split('.')[-1]
            # new_file_name = os.path.join(os.getcwd() + "\\" + files1[0].split("-")[-1]+".nat")
            # # #print(files, new_file_name)
            # file_proc=open
            #print("fff", files)
            txt_doc = file_oper(files ,filetype)
            #print(txt_doc)
            json_format = {
                ##    "_id" : ObjectId("5d762bce9a675101401955ab"),
                "component_name": txt_doc[5],
                "component_type": txt_doc[4],
                "Loc": txt_doc[0],
                "commented_lines": txt_doc[1],
                "blank_lines": txt_doc[2],
                "Sloc": txt_doc[3],
                # "Path": os.getcwd(),
                "application": "Unknown",
                "orphan": "",
                "Active": "",
                "execution_details": "",
                "no_of_variables": "",
                "no_of_dead_lines": "",
                "cyclomatic_complexity": "",
                "dead_para_count": "",
                "dead_para_list": "",
                "total_para_count": ""
            }
            metadata.append(json_format)
            # #print(metadata)
except Exception as e:
    from datetime import datetime
    exc_type, exc_obj, exc_tb = sys.exc_info()
    fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
    print(exc_type, fname, exc_tb.tb_lineno)
    f.write(str(datetime.now()))
    f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
        exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
    pass


#print(metadata)
r = requests.post('http://localhost:5008/api/v1/update/masterInventory', json={"data":metadata,"headers":["component_name","component_type","Loc","commented_lines","blank_lines","Sloc","application","no_of_dead_lines", "cyclomatic_complexity","dead_para_count","total_para_count"]})
#print(r.status_code)
#print(r.text)
f.close()
