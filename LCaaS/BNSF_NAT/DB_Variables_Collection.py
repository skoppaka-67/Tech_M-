import os, json, copy
from pymongo import MongoClient

filespath = r"D:\WORK\POC's\embargo"
extentions = ['.NAT']
client = MongoClient('localhost', 27017)
db = client['BNSF_NAT_emb']['db_variables']
METADATA = []

def getallfiles(filespath,extentions):  # function to return the file paths in the given directory with given extention
    filelist = []
    for root, dirs, files in os.walk(filespath):
        for file in files:
            if file.lower().endswith(tuple([item.lower() for item in extentions])):
                filelist.append(os.path.join(root, file))
    return filelist



def further_annotate(output):
    #
    # output = {
    # "Filename": "SWBNDBHL.NAT",
    # "view_var": "#WB_FFRM",
    # "related_var": [
    #      "2 FLG_AAR",
    #     "2 EFF_DATE",
    #     "2 FLG_404",
    #     "2 EDI_VRSN",
    #     "2 EDI_SEND_CD",
    #     "2 EDI_SEND_CD",
    #     "3 FLG_998"
    # ]
    # }


    new_realate_var = []
    storage=[]
    next_prefix =''
    flag = False

    pre_fix_holder = 2


    for index,values in enumerate(output["related_var"]):

        pre_fix_value = int(values.split()[0])

        if  index+1 < len(output["related_var"]):

            try:

                next_prefix = int(output["related_var"][index+1].split()[0])
            except ValueError as v :
                print(output,v)
        else:

            if storage != []:

                if flag:
                    storage.append(values.split()[1])

                new_realate_var.append("further defined as  (" + ", ".join(storage) + ")")
                storage.clear()

        if pre_fix_value ==2 or pre_fix_value < pre_fix_holder:

            if storage == []:
                new_realate_var.append(values.split()[1])
                pre_fix_holder = pre_fix_value
            else:
                new_realate_var.append("further defined as  (" + ", ".join(storage) + ")")
                new_realate_var.append(values.split()[1])
                pre_fix_holder = pre_fix_value
                storage.clear()

            continue

        if pre_fix_value == pre_fix_holder and pre_fix_value != next_prefix:
            if storage !=[]:
                storage.append(values)
                new_realate_var.append("further defined as  ("+", ".join(storage) + ")" )
                storage.clear()
                flag = False

            continue

        elif pre_fix_value != pre_fix_holder:
            flag = True
            pre_fix_holder = pre_fix_value
            if storage !=[]:
                new_realate_var.append("further defined as  (" + ", ".join(storage) + ")")
                storage.clear()



        if flag:
            storage.append(values.split()[1])

    if storage != []:

        new_realate_var.append("further defined as  (" + ", ".join(storage) + ")")
        storage.clear()


    output["related_var1"] = output["related_var"]
    output["related_var"] = ", ".join(new_realate_var)
    print(json.dumps(output,indent=4))
    # print(" ".join(new_realate_var))
    print("\n","****-----------------------------*****")



    return output




def view_var():
    files = getallfiles(filespath, extentions)

    output = {}
    flag = False
    for file in files:
        f = open(file, 'r')
        line_list = f.readlines()
        sub_flag = False
        ref_var_list = []
        view_var = ''
        ref_var = ''

        for index,line in enumerate(line_list):
            line = line[4:]
            if not (line.__contains__("END-DEFINE")):
                if  (len(line.split()) <=1 or line.strip().startswith("*"))  :
                    continue
            if line.strip().startswith("INDEPENDENT"):
                print(line)

            if line.strip().startswith('DEFINE DATA'):
                flag = True
            if line.strip().startswith('END-DEFINE'):

                flag = False

            if flag:

                if line.strip().startswith("1") or line.strip().startswith("01"):
                    if sub_flag:
                        output['Filename'] = file.split('\\')[-1]
                        output['view_var'] = view_var
                        output['related_var'] = copy.deepcopy(ref_var_list)

                        METADATA.append(copy.deepcopy(further_annotate(output)))
                        output.clear()
                        ref_var_list.clear()

                    sub_flag = False
                    if line_list[index+1][4:].strip().startswith("1") or line_list[index+1][4:].strip().startswith("01"):

                        continue

                    else:
                        if line.__contains__("REDEFINE"):
                            view_var = line.split("REDEFINE")[1].split()[0]
                        else:
                            view_var = line.split()[1]

                if line.strip().startswith("2") or line.strip().startswith("02"):
                    sub_flag = True

                if sub_flag:
                    if line.__contains__("REDEFINE"):
                        ref_var = line.split("REDEFINE")[0].strip()+" " + line.split("REDEFINE")[1].strip()
                    else:
                        if line.split()[0].strip()[0].isdigit():
                            ref_var =  line.split()[0].strip() + " "+  line.split()[1].strip()

                    ref_var_list.append(ref_var)
            else:
                if sub_flag:
                    output['Filename'] = file.split('\\')[-1]
                    output['view_var'] = view_var
                    output['related_var'] = copy.deepcopy(ref_var_list)

                    METADATA.append(copy.deepcopy(further_annotate(output)))
                    output.clear()
                    ref_var_list.clear()

                sub_flag = False




if __name__ == '__main__':
    view_var()
    try:
        db.delete_many({})
        db.insert_many(METADATA)
        print("Update Success")
    except Exception as e :
        print("Exception: ",e)
    # further_annotate({})