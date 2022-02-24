import xlrd,copy,re,datetime,os,glob
from pymongo import MongoClient
import pandas as pd
import openpyxl
import pytz
import timeit

op_path = r"D:\BNSF_1\Excel\Excel_op"
op_path1 = r"D:\BNSF_1\Excel"

Meatadata = []
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)
mongoClient = MongoClient('localhost', 27017)
db = mongoClient['BNSF_NAT_emb']


keyword = {
    " AND ":"and\n ",
    " OR " : "OR\n",
    "and"  : "and\n",
    " or is equal to ": " or ",
    "OR=" : "or",
    "&lt;":"<",
    "&gt;":">"

}

def get_bre_data_in_list(Metadata):
    source_stmnts = []
    process = []
    details = []
    rule_id = []
    notes = []
    para_name = []


    for data in Meatadata:
        source_stmnts.append(data["source_statements"].replace("<br>",""))
        process.append(data["Process"].replace("<br>",""))
        details.append(data["Details"].replace("<br>",""))
        rule_id.append(data["parent_rule_id"].replace("<br>",""))
        notes.append(data["Notes"].replace("<br>",""))
        para_name.append(data["para_name"].replace("<br>", ""))

    return source_stmnts,process,details,rule_id,notes,para_name

def get_files():


    filenames_list = []
    for filename1 in glob.glob(os.path.join(op_path1, '*.xlsx')):
        filenames_list.append(filename1)


    return filenames_list

def json_tuner(new_json,filename):

    for k in new_json:
        buff = new_json[k].split("\n")
        buff1 = []
        for val in buff:
            if val.strip() == "":
                continue
            else:
                buff1.append(val.strip())
        new_json[k] = "\n".join(buff1)

    """Add Select Feilds of DB Var's to Note Column"""

    if new_json["source_statements"].__contains__("SELECT")  and \
             new_json["source_statements"].__contains__(" VIEW ") :

        try:

            view_index = new_json["source_statements"].split().index("VIEW")
            var = new_json["source_statements"].split()[view_index+1]


            """Use var to fecth the values from collection """
            cursy=db.db_variables.find_one({"Filename":filename,"view_var":var},{"_id":0})

            values = cursy["related_var"]

            new_json["Notes"] = "The view " + var + " Contains Fields " + values

        except Exception as e:

            print(new_json["source_statements"],filename,e)
            # raise Exception
            new_json["Notes"] = ""

    else:
        new_json["Notes"] = ""

    return new_json


def assined_pattren(line):


    if line.__contains__(":="):

        """
        FFRM-CERT-NAME := 'CERTIF ONFILE AT BNSF RWY'  FFRM-CERT-CODE := ' '  FFRM-CERT-DECL := 
        
        """
        translated_line = []
        # print(line.split(":="))
        for index, char in enumerate(line.split(":=")):
            if index == len(line.split(":=")) -1 :
                translated_line.append(" with"+ char )
            else:
                if index ==0:
                    if len(char.split())>1:
                        temp = char.split()
                        temp.insert(-1,"Populate")
                        translated_line.append(" ".join(temp)+" ")
                    else:
                        translated_line.append("Populate " +char )
                else:
                    translated_line.append("with"+char ) ## Change it to "and" + cahr if u need and separation

        # print("".join(translated_line))

        return " ".join(translated_line)

    else:
        return line
def remove_duplicates(list):
    if list == []:
       return list
    res = []
    for i in list:
        i = i.strip().replace("\n","")
        if i not in res:
            res.append(i)

    return res

def Excel_maker():


    for loc in get_files():

        wb = xlrd.open_workbook(loc)
        wb0 = openpyxl.Workbook()
        wb0.save(op_path+'\\'  +loc.split("\\")[-1])

        for sheetnum in range(0,len(wb.sheets())):
            sheet = wb.sheet_by_index(sheetnum)
            sheet.cell_value(0, 0)
            new_json = {
                'source_statements': '',
                'Process': "",
                'Details': "",
                'parent_rule_id': "",
                "para_name":""
            }
            storage = []
            storage1 = []
            storage2 = []
            storage3 = []
            flag = False
            sheet_name = wb.sheet_names()[sheetnum]

            for i in range(0, sheet.nrows):
                j = i + 1

                try:
                    if j < sheet.nrows:
                        if sheet.cell_value(i, 5) != sheet.cell_value(j, 5):

                            updated_string = ""
                            if len(storage1) > 0 and storage1[-1] ==sheet.row_values(j)[4] + "\n":

                                for key in keyword:
                                    if sheet.row_values(i)[4].strip().__contains__(key):

                                        updated_string  = updated_string.replace(key, keyword[key])
                                        new_json['Details'] = updated_string + "Then" + " \n " + \
                                                                        sheet.row_values(j)[4]
                                    else:
                                        new_json['Details'] = sheet.row_values(i)[4] + "Then" + "\n " + sheet.row_values(j)[4]
                            else:
                                    new_json['Details'] = new_json['Details']+"\n" +"\n".join(storage2)

                            new_json['source_statements'] = new_json['source_statements'] +"\n" + "\n".join(storage)
                            new_json['Process'] =  new_json['Process'] +"\n" +"\n".join(storage1)
                            storage3.extend(new_json['para_name'].split("\n"))
                            new_json['para_name'] = "\n".join(remove_duplicates(storage3))
                            # new_json['Details'] =  new_json['Details'] +"\n" +"\n".join(storage2)
                            if sheet.row_values(i)[5] == "parent_rule":
                                new_json['parent_rule_id'] =""
                            else:
                                new_json['parent_rule_id'] = sheet.row_values(i)[5]
                            storage.clear()
                            storage1.clear()
                            storage2.clear()
                            storage3.clear()

                            new_json = json_tuner(new_json,sheet_name)

                            if new_json !={'source_statements': '', 'Process': '', 'Details': '', 'parent_rule_id': '',"para_name":''}:
                                data_loader(new_json)
                                new_json.clear()
                                flag = False
                            else:
                                new_json.clear()
                                flag = False
                                continue
                            # print(Meatadata)

                        if flag:
                            storage.append(sheet.row_values(j)[2] + "\n ")
                            storage1.append(sheet.row_values(j)[3] + "\n ")
                            storage2.append(assined_pattren(sheet.row_values(j)[4]) + "\n ")
                            storage3.append(sheet.row_values(j)[7] + "\n ")

                            continue

                        if sheet.cell_value(i, 5) == sheet.cell_value(j, 5):
                            if sheet.row_values(i)[4].strip().startswith("check if "):

                                updated_string =sheet.row_values(i)[4].strip()
                                for key in keyword:
                                    if sheet.row_values(i)[4].strip().__contains__(key):

                                        updated_string  = updated_string.replace(key, keyword[key])
                                        new_json['Details'] = updated_string + "Then" + " \n " + \
                                                                        assined_pattren(sheet.row_values(j)[4])

                                    else:

                                        new_json['Details'] = sheet.row_values(i)[4] + "Then" + "\n " + assined_pattren(sheet.row_values(j)[4])
                            else:
                                new_json['Details'] =  assined_pattren(sheet.row_values(i)[4]) + "\n " + assined_pattren(sheet.row_values(j)[4])

                            new_json['source_statements'] = sheet.row_values(i)[2] + " \n " + sheet.row_values(j)[2]
                            new_json['Process'] = sheet.row_values(i)[3] + "\n " + sheet.row_values(j)[3]
                            new_json['para_name'] = sheet.row_values(i)[7] + "\n " + sheet.row_values(j)[7]
                            flag = True

                    else:
                        updated_string = ''
                        if new_json != {}:
                            if not 'parent_rule_id'  in new_json:
                                new_json['parent_rule_id'] = sheet.row_values(i)[5]
                                new_json['Details'] = new_json['Details'] + "\n" + "\n".join(storage2)
                                new_json['source_statements'] = new_json['source_statements'] + "\n" + "\n".join(
                                    storage)
                                new_json['Process'] = new_json['Process'] + "\n" + "\n".join(storage1)
                                storage3.extend(new_json['para_name'].split("\n"))
                                new_json['para_name'] = "\n".join(remove_duplicates(storage3))
                            new_json = json_tuner(new_json,sheet_name)
                            if new_json != {'source_statements': '', 'Process': '', 'Details': '',
                                            'parent_rule_id': '','para_name':''}:

                                data_loader(new_json)

                except KeyError as e:

                    new_json['source_statements'] = sheet.row_values(i)[2]
                    new_json['Process'] = sheet.row_values(i)[3]
                    new_json['Details'] = assined_pattren(sheet.row_values(i)[4])
                    new_json['parent_rule_id'] = sheet.row_values(i)[5]
                    new_json['para_name'] = sheet.row_values(i)[7]
                    new_json = json_tuner(new_json,sheet_name)
                    if new_json != {'source_statements': '', 'Process': '', 'Details': '', 'parent_rule_id': '','para_name':''}:
                        data_loader(new_json)
                    new_json.clear()
                    storage.clear()
                    storage1.clear()
                    storage2.clear()

                    # print(e)

            with pd.ExcelWriter(op_path+'\\' + loc.split("\\")[-1],engine='openpyxl', mode="a") as writer1:

                    source_stmnts,process,details,rule_id,notes,para_name = get_bre_data_in_list(Meatadata)

                    if Meatadata == []:
                        continue
                    print("Processing for--->", sheet_name)
                    dct = {
                        "Seq": [x for x in range(1, len(Meatadata) + 1)],
                        'para_name': para_name,
                        'source_statements':source_stmnts,
                        "Process": process,
                        "Details": details,
                        'parent_rule_id':rule_id,
                        "Notes": notes
                    }
                    df_1 = pd.DataFrame(dct)
                    Meatadata.clear()
                    df_1.to_excel(writer1, sheet_name=sheet_name, index=False)
                



            # wb0.remove(wb0["Sheet"])
            # wb0.save(op_path+'\\' +"new_" + loc.split("\\")[-1])



def data_loader(new_json):

    if new_json['source_statements']== '\n' or new_json['source_statements']== '':

        return "Empty Json"


    else:
        Meatadata.append(copy.deepcopy(new_json))


        return "Success"

if __name__ == '__main__':
    # Start timer
    start = timeit.default_timer()
    Excel_maker()
    # assined_pattren("")
    stop = timeit.default_timer()
    print('Total execution time: ', stop - start)
