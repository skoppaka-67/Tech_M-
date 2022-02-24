SCRIPT_VERSION = "AUTHOR Sai kiran"

import  glob,os,re,copy,json,sys
from pymongo import MongoClient
import config
import pytz
import datetime
import collections

client = MongoClient(config.database['hostname'], config.database['port'])
db = client[config.database['database_name']]

time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)
f = open('errors.txt', 'a')
# f.seek(0)
# f.truncate()

cobol_folder_name = config.codebase_information['NAT']['folder_name']
file_path=config.codebase_information["code_location"]+"\\"+cobol_folder_name
dead_dict_list=[]
Natfile = file_path
Meatadata = []
procedure_divison_dict ={}
procedure_divison_storage =[]
'''PerProcessDB is used to delete previous data in Collection and add Headers to it
Input: No Input
Output: No Output
'''
def PerPorcessDB():
    db.glossary.remove()
    h = {"type": "metadata", "headers": ["component_name", "Variable", "Business_Meaning", "Dead"]}
    db.glossary.insert_one(h)

PerPorcessDB()

'''
Def procedure_divison is used to read lines from procedure_divison and store them in a list
Input: Source file to process
Output: List which contians lines after procedure_divison
'''


def Remove(duplicate):

    final_list = []
    for list_iter in duplicate:
        if list_iter not in final_list:
            final_list.append(list_iter)
    return final_list
def procedure_divison(file_entry):
   with open(file_entry, 'r') as f:
        content = f.readlines()

        start_falg =False
        procedure_divison_dict.clear()
        procedure_divison_storage.clear()
        for line in content:

             # #print(line)
             temp_line = line
             # line = line[6:]
             if temp_line.replace(" ", "").__contains__("SET") or temp_line.replace(" ", "").__contains__("RESET") :
                start_falg = True
                # continue
             try:
                 if start_falg:
                     # if not len(line)>5:
                     #     print()
                     #     continue
                     # print(file_entry)
                     if line[6]=="*" or  line[8]=="*" or line.strip() == " ":
                         continue

                     procedure_divison_storage.append(line.strip())
                     # f = open("temp.txt", "w+")
                     # f.write(line.strip)

             except Exception as e:
                 from datetime import datetime
                 exc_type, exc_obj, exc_tb = sys.exc_info()
                 fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
                 print(exc_type, fname, exc_tb.tb_lineno)
                 f.write(str(datetime.now()))
                 f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
                     exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
                 pass


        # procedure_divison_dict[file_entry.split("\\")[-1].strip(".NAT")] = copy.deepcopy(procedure_divison_storage)

        return procedure_divison_storage
'''
Main function is used to capture the variables in declartion part of a Natural Program
Input: No parameters passed 
Output: List with json's which contains component name, variable name , business desc and Dead info along with DB update
'''
def main():
    for filename in glob.glob(os.path.join(Natfile, '*.NAT')):
        # #print(filename)
        d= {}
        companent_name = open(filename, "r")
        for line in companent_name.readlines():
            # #print(line)
            if not len(line) > 5:
                continue
            if (not (line[6].__contains__("*") or line[8].__contains__("*") )):

                if line[6].lstrip().startswith("/*"):
                    pass
                else:

                    if line.__contains__("#"):
                        # if not line.__contains__("REDEFINE"):
                        if re.search("DEFINE DATA",line) or re.search("REDEFINE",line) or re.search("DEFINE WINDOW",line) :
                            continue

                        else:
                            # #print(line.split())
                            for i in line.split():
                                # #print(i)
                                if i.startswith("#"):

                                    var = i.split("(")[0]
                                    Glossary_json = {"component_name": filename.split("\\")[-1], "Variable": var,
                                                     "Business_Meaning": "","Dead":"Yes"}
                                    d=procedure_divison(filename)

                                    for line in d :
                                        if var in line:
                                            Glossary_json["Dead"] ="No"
                                            # #print(Glossary_json)
                                    Meatadata.append(Glossary_json)
    # #print(Meatadata)
#     for i in  Meatadata:
#         #print(json.dumps(i,indent=4))
# #
    #counting no of var and dead Var's in a component
    for d in Meatadata:
        if d['Dead'] == "Yes":
            dead_dict_list.append(d)
    # #print(dead_dict_list)
    '''collect component name's and count total number of variables in a single component to list'''
    count = collections.Counter([d['component_name'] for d in Meatadata])
    #print (json.dumps(count,indent=4))
    '''collect component name's and count total number of dead variables in a single component to list'''
    count1 = collections.Counter([d['component_name'] for d in dead_dict_list])
    #print("DEad_var:",json.dumps(count1,indent=4))

    '''Update master inventory's  total number of varibles felid with the count
    this will happen in a iterative way to update component by component 
    '''
    for dict, values in count.items():
        db.master_inventory_report.update_one({"component_name": dict}, {
            "$set": {"no_of_variables": values}})
        # #print("no_of_variables Updated")
    '''Update master inventory's  total number of dead varibles felid with the count1
       this will happen in a iterative way to update component by component     
     '''
    for dict, values in count1.items():
        db.master_inventory_report.update_one({"component_name": dict}, {
            "$set": {"no_of_dead_variables": values}})
        # #print("no_of_dead_variables Updated")


    # Insert into DB
    try:
        import datetime
        db.glossary.insert_many(Remove(Meatadata))
        # updating the timestamp based on which report is called
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        if db.glossary.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                  "time_zone": time_zone,
                                                                  # "headers":["component_name","component_type"],
                                                                  "script_version": SCRIPT_VERSION
                                                                  }}, upsert=True).acknowledged:
            pass
            #print('update sucess')


    except Exception as e:
        from datetime import datetime
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        f.write(str(datetime.now()))
        f.write('\n' + str(exc_type) + '\n' + fname + '\n' + str(
            exc_tb.tb_lineno) + '\n' + '***********************************' + '\n')
        pass

main()
f.close()
