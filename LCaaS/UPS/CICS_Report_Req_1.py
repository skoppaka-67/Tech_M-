import xlrd,os,copy,re,glob,xlsxwriter,openpyxl
from pymongo import MongoClient
import time,datetime ,pytz
import timeit
import pandas as pd
import config
import csv
from SortedSet.sorted_set import SortedSet

PGM_ID=[]
Current_Division_Name=""
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

client = MongoClient(config.database['hostname'], config.database['port'])
db = client[config.database['database_name']]

cobol_folder_name = config.codebase_information['BMS']['folder_name']
cobol_extension_type = config.codebase_information['BMS']['extension']

code_location =config.codebase_information['code_location']
ConditionPath=config.codebase_information['condition_path']
CobolPath=code_location+'\\'+cobol_folder_name
OUTPUT_DATA = []
METADATA=[]
def main():
 for filename in glob.glob(os.path.join(CobolPath,'*.bms')):
    print(filename)
    field_name=""
    variable=""
    attribute_name=""
    position_name=""
    lenght=""
    mapset_name=""
    map_name=""
    type=""
    multiline_flag = False
    Program_Name = open(filename)
    for line in Program_Name.readlines():

        line2=line

        line=line[0:72]

        filename1 = filename.split('\\')
        len_file = len(filename1)
        filename1 = filename1[len_file - 1][:-4]

        if line.strip()=="":
            continue
        if line.startswith("*"):
            continue
        if multiline_flag == False :
            pos_line = ""
            length_line = ""
            attrb_line = ""
            #field_name = ""
            initila_line = ""
            initila_flag=False
        #line=line.lower()

        line1=line
        line=line.split()

        if len(line)>=2:
            if line[1]=='DFHMSD' or line[1]=='DFHMDI' or line[1]=='DFHMDF':
                 print("First:",line[1])
                 field_name=line[0]
                 variable="Screen Variable"


        if line1.__contains__('DFHMSD'):
            mapset_name=line[0]
        if line1.__contains__('DFHMDI'):
            map_name=line[0]
        if line1.__contains__('DFHMDF'):
            multiline_flag = False
            if multiline_flag == False:
                pos_line = ""
                length_line = ""
                attrb_line = ""
                #field_name = ""
                initila_line = ""
                #variable = ""
            if line1.__contains__('POS'):
                pos_line=line1.split('POS')
                pos_line=pos_line[1].split(')')
                pos_line=pos_line[0].replace('=(','')
                #print(pos_line)
            if line1.__contains__('LENGTH'):
                length_line=line1.split('LENGTH')
                length_line=length_line[1].split(',')
                length_line=length_line[0].replace('=','')
            if line1.__contains__('ATTRB'):
                attrb_line=line1.split('ATTRB')
                attrb_line = attrb_line[1].split(')')
                attrb_line = attrb_line[0].replace('=(', '')
                attrb_line = attrb_line.replace(" ", "")
                attrb_line = attrb_line.replace("=", " ").strip()
            if line1.__contains__('INITIAL'):

                initila_line=line1.split('INITIAL')
                initila_line = initila_line[1].split(',')
                initila_line = initila_line[0].replace('=','')
                initila_line = initila_line.strip()
                field_name = initila_line.replace("'", "")
                variable = "Screen Literal"

        if multiline_flag:

                if line1.__contains__('POS'):
                    pos_line = line1.split('POS')
                    pos_line = pos_line[1].split(')')
                    pos_line = pos_line[0].replace('=(', '')
                    # print(pos_line)
                if line1.__contains__('LENGTH'):
                    length_line = line1.split('LENGTH')
                    length_line = length_line[1].split(',')
                    length_line = length_line[0].replace('=', '')
                if line1.__contains__('ATTRB'):
                    attrb_line = line1.split('ATTRB')
                    attrb_line = attrb_line[1].split(')')
                    attrb_line = attrb_line[0].replace('=(', '')
                    attrb_line= attrb_line.replace(" ","")
                    attrb_line= attrb_line.replace("="," ").strip()
                if line1.__contains__('INITIAL') or initila_flag:
                    if initila_flag:
                        second_line=line1[0:71].split()
                        if len(second_line)>0:
                         second_line=second_line[0]
                        else:
                            second_line=""
                        second_line_number=line1.find(second_line)
                        if line1.endswith('*'):
                            if initial_starting_line == second_line_number:
                                space=''
                            else:
                                space=' '
                            initila_line=initila_line+'<br>'+line1[initial_starting_line:71]
                            continue
                        elif line1[0:71].strip().endswith("'"):

                            if initial_starting_line == second_line_number:
                                space=''
                            else:
                                space=' '

                            initila_line = initila_line +'<br>'+line1[initial_starting_line:71].rstrip()
                            initila_flag=False

                    else:
                        initial_starting_line=line1.find('INITIAL')
                        initila_line = line1[0:71].split('INITIAL')
                        initila_line = initila_line[1].split(',')
                        initila_line = initila_line[0].replace('=', '')
                        initila_line_count=initila_line.count("'")

                        if initila_line_count==2:
                            initila_line=initila_line.rstrip()

                        print(initila_line,initila_line_count)
                        if len(line2)>72:
                            if not initila_line.strip().endswith("'") or line2[71]=="*":
                                initila_flag=True
                                continue
                        else:
                            if not initila_line.strip().endswith("'") :
                                initila_flag=True
                                continue


                    field_name = initila_line.replace("'","")

                    print(field_name)
                    variable="Screen Literal"


        #print(pos_line,length_line,attrb_line)
        if (line1.__contains__(' X') or line1[0:72].endswith(' *'))  and (pos_line=="" or length_line=="" or attrb_line=="" or initila_line==""):
                multiline_flag=True

                continue
        if pos_line =="" and length_line=="" and attrb_line=="":
            None
        else:
          METADATA.append({"bms_name":filename1,"mapset_name":mapset_name,"map_name":map_name,"field_name":field_name.replace("\n",""),"type":variable,"position":pos_line.replace("\n",""),"length":length_line.replace("\n",""),"attribute":attrb_line.replace("\n","")})
          #print(METADATA)
          field_name=""
          pos_line = ""
          length_line = ""
          attrb_line = ""
          initila_line = ""
          variable = ""

 #return (METADATA)

 def Db_Insert(METADATA):
     UpdateCounter = 0
     UpdateCounter = UpdateCounter + 1
     db_data = {"data": METADATA,
                "headers": ["bms_name", "mapset_name", "map_name", "field_name", "type", "position", "length", "attribute"]}

     try:
         keys = list(db_data.keys())
         print('parent keys', keys)

         if 'data' in keys:
             # fetching headers
             x_BRE_report_header_list = db_data['headers']
             print('COBOL Report header list', x_BRE_report_header_list)
             # Adding header field to db_data
             db_data['headers'] = x_BRE_report_header_list

             if len(db_data['data']) == 0:
                 print({"status": "failure", "reason": "data field is empty"})
             else:
                 # Delete all COBOl associated records in the table
                 previousDeleted = False
                 try:
                     if UpdateCounter == 1:
                         if db.cics_field.delete_many(
                                 {"type": {"$ne": "metadata"}}).acknowledged:
                             print('Deleted all the COBOL components from the cics_field report')
                             previousDeleted = True

                         else:
                             print('Something went wrong')
                             print({"status": "failed",
                                    "reason": "unable to delete from database. Please check in with your Administrator"})
                             print('--------did not deleted all de cobols')
                 except Exception as e:
                     print({"status": "failed", "reason": str(e)})

                 # Update the database with the content from HTTP request body

                 if previousDeleted or UpdateCounter == 1:

                     try:

                         db.cics_field.insert_many(db_data['data'])
                         print('db inserteed bro')
                         # updating the timestamp based on which report is called
                         current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
                         # Setting the time so that we know when each of the JCL and COBOLs were run

                         # db.cross_reference_report.insert_one({"type":"metadata", "JCL":{"last_updated_on":ct},"COBOL":{"last_updated_on":ct}})

                         if db.cics_field.count_documents({"type": "metadata"}) > 0:
                             print('meta happen o naw',
                                   db.cics_field.update_one({"type": "metadata"},
                                                                  {"$set": {
                                                                      "BRE.last_updated_on": current_time,
                                                                      "BRE.time_zone": time_zone,
                                                                      "headers": x_BRE_report_header_list
                                                                  }},
                                                                  upsert=True).acknowledged)
                         else:
                             db.cics_field.insert_one(
                                 {"type": "metadata",
                                  "COBOL": {"last_updated_on": current_time, "time_zone": time_zone},
                                  "headers": x_BRE_report_header_list})

                         print(current_time)
                         print({"status": "success", "reason": "Successfully inserted data and "})
                     except Exception as e:
                         print('Error' + str(e))
                         print({"status": "failed", "reason": str(e)})

     except Exception as e:
         print('Error: ' + str(e))
         print({"status": "failure", "reason": "Response json not in the required format"})
 Db_Insert(METADATA)
 keys = METADATA[0].keys()
 with open('people.csv', 'w') as output_file:
     dict_writer = csv.DictWriter(output_file, keys)
     dict_writer.writeheader()
     dict_writer.writerows(METADATA)

main()




