"""
Desc - Decomp report creation Phase 2 and 3 combined to single Script.

Author - Saikiran(KS00561356)



"""


import xlrd,copy,re,datetime,os,glob,json
from pymongo import MongoClient
import pandas as pd
import openpyxl
import pytz
import timeit


op_path = r"D:\decomp\output" # Path for Output
op_path1 = r"D:\decomp" # Path for Input
# op_path1 = "D:\\COBOL\\output"
# op_path = "D:\\COBOL\\final_output"
Meatadata = []
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

################## DB Connection #########################

mongoClient = MongoClient('localhost', 27017)
db = mongoClient['BNSF_NAT_emb']

##########################################################

##########################################################

################## Addtional Annotations #################

keyword = {

    " AND ":"and\n ",
    " OR " : "OR\n",
    "and"  : "and\n",
    " or is equal to ": " or ",
    "OR=" : "or"


}
##########################################################

##########Convert list of Dict's to individual list#######

def get_bre_data_in_list(Metadata):
    """
    Read BRE JSON's and unpack each key value to individual lists to write to
    Excel sheets using dataframes
    :param Metadata:
    :return: lists of source_stmnts,process,details,rule_id,notes
    """
    source_stmnts = []
    process = []
    details = []
    rule_id = []
    notes = []
    for data in Meatadata:
        source_stmnts.append(data["source_statements"].replace("<br>",""))
        process.append(data["Process"].replace("<br>",""))
        details.append(data["Details"].replace("<br>",""))
        rule_id.append(data["parent_rule_id"].replace("<br>",""))
        notes.append(data["Notes"].replace("<br>",""))

    return source_stmnts,process,details,rule_id,notes

##########################################################

########## Read file source file name Excels #############

def get_files():
    """
    Static method to read and create list of file names for the input files
    floder path
    :return: list of input files
    """
    filenames_list = []
    for filename1 in glob.glob(os.path.join(op_path1, '*.xlsx')):
        filenames_list.append(filename1)

    return filenames_list

##########################################################

########## Tune Jsons and add View vars in Notes #########
def json_tuner(new_json,filename):

    """
    1.Read the Json and remove empty lines
    2.Add View variables from the code to Notes field based on View parent variable
    View child vars are stored in DB we need to read db_variables collection and
    populate child vars in Notes field
    3.Add empty notes field in case of no Select keyword on details column

    :param new_json:
    :param filename:
    :return: fine tuned Json after removing Empty lines in each column and added view var's in
    Notes column

    """
    for k in new_json:
        buff = new_json[k].split("\n")
        buff1 = []
        for val in buff:
            if val.strip() == "":
                continue
            else:
                buff1.append(val.strip())
        new_json[k] = "\n".join(buff1)

    #################################################
    """Add Select Fields of DB Var's to Note Column"""
    ###################################################
    if new_json["source_statements"].__contains__("SELECT")  and \
            new_json["source_statements"].__contains__(" VIEW ") :
        try:
            view_index = new_json["source_statements"].split().index("VIEW")
            var = new_json["source_statements"].split()[view_index+1]

            ##################################################
            """Use var to fetch the values from collection """
            ####################################################

            cursy=db.db_variables.find_one({"Filename":filename,"view_var":var},{"_id":0})
            values = cursy["related_var"]
            new_json["Notes"] = new_json["Notes"] + "The view " + var + " Contains Fields " + values

        except Exception as e:
            print(new_json["source_statements"],filename,e)
            # raise Exception
            new_json["Notes"] = ""
    else:
        if "Notes" in new_json:
            new_json["Notes"] =new_json["Notes"] + ""
        else:
            new_json["Notes"] = ''

    return new_json

##########################################################


########## Annotations of Cobol Assign var Pattern #########

def assined_pattren(line):
    """
    Searched for := in the given file and Annotate it.
    Example:

        input - #AT-DESTINATION := TRUE
        output -  Populate  AT-DESTINATION with TRUE



    :param line:
    :return: Annotated line as string
    """


    if line.__contains__(":="):


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

##########################################################


######### Read input Excels and create new exces  #########

def Excel_maker():
    """
    Desc - Read Excels and merge the cells based on Parent rule id and write to new excels

    1. Read Excels Sheet by Sheet and create jsons for each sheet data after merging based
       on parent Rule-ids

    2. Read Each sheets column by column and merge the columns based on same parent rule id

    3. write the new data to new excels sheet by sheet

    :return: Void
    """

    for loc in get_files():
        wb = xlrd.open_workbook(loc)
        wb0 = openpyxl.Workbook()
        wb0.save(op_path+'\\' +loc.split("\\")[-1])#.split("\\")[-1]
        for sheetnum in range(0,len(wb.sheets())):
            sheet = wb.sheet_by_index(sheetnum)

            sheet.cell_value(0,0)
            new_json = {
                'source_statements': '',
                'Process': "",
                'Details': "",
                'parent_rule_id': ""
            }
            storage = []
            storage1 = []
            storage2 = []
            flag = False
            sheet_name = wb.sheet_names()[sheetnum]
            for i in range(0, sheet.nrows):
                # print(i)
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
                            # new_json['Details'] =  new_json['Details'] +"\n" +"\n".join(storage2)
                            if sheet.row_values(i)[5] == "parent_rule":
                                new_json['parent_rule_id'] =""
                            else:
                                new_json['parent_rule_id'] = sheet.row_values(i)[5]
                            storage.clear()
                            storage1.clear()
                            storage2.clear()

                            new_json = json_tuner(new_json,sheet_name)

                            if new_json !={'source_statements': '', 'Process': '', 'Details': '', 'parent_rule_id': ''}:
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

                            continue

                        if sheet.cell_value(i, 5) == sheet.cell_value(j, 5):
                            if sheet.row_values(i)[4].strip().startswith("check if "):# In Phase2 all the if statements annoted as check if, which is used to identify conditional statements

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
                            # new_json['Details'] = sheet.row_values(i)[4] + " \n " + sheet.row_values(j)[4]
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
                            new_json = json_tuner(new_json,sheet_name)
                            if new_json != {'source_statements': '', 'Process': '', 'Details': '',
                                            'parent_rule_id': ''}:

                                data_loader(new_json)

                except KeyError as e:

                    new_json['source_statements'] = sheet.row_values(i)[2]
                    new_json['Process'] = sheet.row_values(i)[3]
                    new_json['Details'] = assined_pattren(sheet.row_values(i)[4])
                    new_json['parent_rule_id'] = sheet.row_values(i)[5]
                    new_json = json_tuner(new_json,sheet_name)
                    if new_json != {'source_statements': '', 'Process': '', 'Details': '', 'parent_rule_id': ''}:
                        data_loader(new_json)
                    new_json.clear()
                    storage.clear()
                    storage1.clear()
                    storage2.clear()

                    # print(e)

            #### wrting to new Excel output

            with pd.ExcelWriter(op_path+'\\' + loc.split("\\")[-1],engine='openpyxl', mode="a") as writer1:

                source_stmnts,process,details,rule_id,notes = get_bre_data_in_list(Meatadata)



                if Meatadata == []:
                    continue
                print("Processing for--->", sheet_name)
                dct = {
                    "Seq": [x for x in range(1, len(Meatadata) + 1)],
                    'source_statements':source_stmnts,
                    "Process": process,
                    "Details": details,
                    'parent_rule_id':rule_id,
                    "Notes": notes
                }
                df_1 = pd.DataFrame(dct)
                Meatadata.clear()
                df_1.to_excel(writer1, sheet_name=sheet_name, index=False)


##########################################################


#######################################
        """ Phase 3 functions """

###########################################################


######################Pahse-3###############################


def data_loader(new_json):
    """
    Decs:
        1. Remover empty json to avoid empty cell in new excels
        2. Remove the SQL query in the details column with "Execute the query as given in the note" and
           and move the actual query to Notes column
        3. Remove Empty Json's
    Helper func:
        1. jsonsplitter
        2. move_query_to_notes

    :param new_json: json which is going to be written in new execls
    :return:

    """

    if new_json['source_statements']== '\n' or new_json['source_statements']== '':

        return "Empty Json"


    else:
        leng = new_json['Details'].count('\n')
        if leng > 15:

            # print(json.dumps(jsonsplitter(new_json),indent=4))
            split_list = jsonsplitter(new_json)
            for json1 in split_list:

                if json1['Details'].__contains__("EXEC SQL") and json1['Details'].__contains__(
                        "End of DB2 operation"):

                    move_query_to_notes(json1)

                elif json1['Details'].__contains__("EXEC SQL") and json1['Details'].__contains__("END-EXEC"):

                    move_query_to_notes(json1)

                else:

                    Meatadata.append(copy.deepcopy(json1))
            return "Success"



        else:

            if new_json['Details'].__contains__("EXEC SQL") and new_json['Details'].__contains__("End of DB2 operation") :

                move_query_to_notes(new_json)

            elif new_json['Details'].__contains__("EXEC SQL") and new_json['Details'].__contains__("END-EXEC"):

                move_query_to_notes(new_json)

            else:

                Meatadata.append(copy.deepcopy(new_json))

                return "Success"


def jsonsplitter(new_json):
    """
    Helper function to spilt the json to not exceed 15 lines in each column
    :param new_json:
    :return: list of splitted json
    """

    splitted_json_list = []
    upper_limit = 14
    lower_limt = 0
    flag = True
    leng = len(new_json["Details"].split("\n"))
    detl_list = new_json["Details"].split("\n")
    src_lit =  new_json["source_statements"].split("\n")

    while flag:
        temp_json = new_json

        if upper_limit >= leng:
            temp_json["Details"] = "\n".join(detl_list[lower_limt:])
            temp_json["source_statements"] = "\n".join(src_lit[lower_limt:])
            splitted_json_list.append(copy.deepcopy(temp_json))
            flag = False

        else:
            temp_json["Details"] = "\n".join(detl_list[lower_limt:upper_limit])
            temp_json["source_statements"] = "\n".join( src_lit[lower_limt:upper_limit])
            splitted_json_list.append(copy.deepcopy(temp_json))
            lower_limt = upper_limit
            upper_limit = upper_limit+14


    return splitted_json_list


def move_query_to_notes(new_json):
    """
    Helper function to move query to Notes key in the json and annotate with different string
    :param new_json:
    :return: newly formed json with query moved to Notes
    """
    temp_json = {
        'source_statements': '',
        'Process': "",
        'Details': "",
        'parent_rule_id': "",
        'Notes':""

    }

    if new_json['Details'].__contains__("EXEC SQL") and new_json['Details'].__contains__("End of DB2 operation"):
        index_of_exec = new_json['Details'].index("EXEC SQL")
        index_of_end_exec = new_json['Details'].index("End of DB2 operation") + 20

        new_source_stmnt = new_json['Details'][:index_of_exec] + "Execute the query as given in the note" + new_json[
                                                                                                                'Details'][
                                                                                                            index_of_end_exec:]

        notes = new_json['Details'][index_of_exec: index_of_end_exec]

        temp_json["source_statements"] = new_json["source_statements"]
        temp_json["Process"] = new_json["Process"]
        temp_json["Details"] = new_source_stmnt
        temp_json["Notes"] = new_json["Notes"]+ " \n " + notes

        return data_loader(temp_json)



    if new_json['Details'].__contains__("EXEC SQL") and new_json['Details'].__contains__("END-EXEC"):
        index_of_exec = new_json['Details'].index("EXEC SQL")
        index_of_end_exec = new_json['Details'].index("END-EXEC") + 8

        new_source_stmnt = new_json['Details'][:index_of_exec] + "Execute the query as given in the note" + \
                           new_json['Details'][index_of_end_exec:]
        notes = new_json['Details'][index_of_exec: index_of_end_exec]

        temp_json["source_statements"] = new_json["source_statements"]
        temp_json["Process"] = new_json["Process"]
        temp_json["Details"] = new_source_stmnt
        temp_json["Notes"] = new_json["Notes"] + " \n " + notes

        return data_loader(temp_json)



if __name__ == '__main__':
    # Start timer
    start = timeit.default_timer()
    #### Call To Main ###
    Excel_maker()
    # assined_pattren("")
    stop = timeit.default_timer()
    print('Total execution time: ', stop - start)
