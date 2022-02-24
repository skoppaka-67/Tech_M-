import xlrd,os,copy,re,glob,xlsxwriter,openpyxl
from pymongo import MongoClient
import time,datetime ,pytz
import timeit
import pandas as pd
import config
import csv

"Version: Fixed all bugs working fine"
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


def Db_Insert(METADATA):
    UpdateCounter = 0
    UpdateCounter = UpdateCounter + 1
    db_data = {"data": METADATA,
               "headers": ["program_name", "map_name", "field_name", "validation_rule", "rule_number", ]}

    try:
        keys = list(db_data.keys())
        print('parent keys', keys)

        if 'data' in keys:
            # fetching headers
            x_BRE_report_header_list = db_data['headers']
            print('CICS rule report', x_BRE_report_header_list)
            # Adding header field to db_data
            db_data['headers'] = x_BRE_report_header_list

            if len(db_data['data']) == 0:
                print({"status": "failure", "reason": "data field is empty"})
            else:
                # Delete all COBOl associated records in the table
                previousDeleted = False
                try:
                    if UpdateCounter == 1:
                        if db.cics_rule_report.delete_many(
                                {"type": {"$ne": "metadata"}}).acknowledged:
                            print('Deleted all the CICS components from the CICS rule report')
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

                        db.cics_rule_report.insert_many(db_data['data'])
                        print('db inserteed bro')
                        # updating the timestamp based on which report is called
                        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
                        # Setting the time so that we know when each of the JCL and COBOLs were run

                        # db.cross_reference_report.insert_one({"type":"metadata", "JCL":{"last_updated_on":ct},"COBOL":{"last_updated_on":ct}})

                        if db.cics_rule_report.count_documents({"type": "metadata"}) > 0:
                            print('meta happen o naw',
                                  db.cics_rule_report.update_one({"type": "metadata"},
                                                                 {"$set": {
                                                                     "BRE.last_updated_on": current_time,
                                                                     "BRE.time_zone": time_zone,
                                                                     "headers": x_BRE_report_header_list
                                                                 }},
                                                                 upsert=True).acknowledged)
                        else:
                            db.cics_rule_report.insert_one(
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


# print(METADATA)



field_list=[]
Screen_variable=db.cics_field.find({"type" : "Screen Variable"})

METADATA=[]
for var in Screen_variable:
    field_list.append(' '+var['field_name'] + 'A'+' ')
    field_list.append(' '+var['field_name'] + 'I'+' ')
    field_list.append(' '+var['field_name'] + 'O'+' ')
    field_list.append(' '+var['field_name'] + 'L'+' ')
    field_list.append(' '+var['field_name'] + 'F'+' ')
# field_list = [' BISMSGO ']
print("Field_list:",field_list)
Bre_pgm_name = []
Bre_pgm_name1 = db.bre_report2.distinct("pgm_name")
for iter in Bre_pgm_name1:
    # print(iter)
    if iter == None:
        continue
    else:
        Bre_pgm_name.append(iter)


# print("BRE:",Bre_pgm_name)
for pgm in range(len(Bre_pgm_name)):

    cursor=db.bre_report2.find({"pgm_name":Bre_pgm_name[pgm]})
    # print("PGM:",pgm)
    METADATA = []
    for lines in cursor:
        # print("Lines:",lines)
        cursor1 = cursor.clone()
        source_line=lines['source_statements']
        if any(ext in source_line for ext in field_list):
            additional_flag = False
            source_line_list=[]
            source_statement=lines['source_statements']
            #print("source",source_statement)
            map_name_value_list=[]
            map_name_value_list1=[]
            rule_with_space=""
            rule_id=lines["Rule"]
            p_id1 = lines["rule_relation"]
            listofpid1=p_id1.split(',')
            p_id=lines["rule_relation"]
            p_id=p_id.split(',')
            p_id=p_id[0]
            cursor_flag=False
            below_cursor_flag=False
            Evaluate_flag=False
            evaluate_counter_flag=False
            evaluate_counter=0


            # extra added lines. #########################################################################

            source_line_split = source_line.split()
            for field in range(len(source_line_split)):
                new_value = ' ' + source_line_split[field] + ' '
                if new_value in field_list:

                    field_var = source_line_split[field]
                    field_var = field_var.strip()
                    field_var1 = field_var
                    field_var = field_var[:-1]

                    map_name = db.cics_field.find({"field_name": field_var})
                    for map_name_value in map_name:

                        map_name_value_list.append(map_name_value["map_name"])
                        print("Check1:",field_var1)
            METADATA.append(
                {"program_name": lines["pgm_name"], "map_name": (" , ".join(map_name_value_list)),
                 "field_name": field_var1, "validation_rule": source_line, "rule_number": rule_id})
            ########################################################################################################################
            if  source_statement.__contains__(' IF ') or source_statement.__contains__(' WHEN ') or source_statement.__contains__(' EVALUATE ') or source_statement.__contains__(' ELSE '):
                if source_statement.__contains__(' EVALUATE ') and not source_statement.__contains__(' IF '):
                    Evaluate_flag = False
                    evaluate_counter=1
                None
            else:

                rule_id =listofpid1[len(listofpid1)-1]

            pgm_name = rule_id.split('-')
            source_line_split = source_line.split()
            for field in range(len(source_line_split)):
                new_value = ' ' + source_line_split[field] + ' '
                if new_value in field_list:

                    field_var = source_line_split[field]
                    field_var = field_var.strip()
                    field_var2 = field_var
                    field_var = field_var[:-1]

                    map_name1 = db.cics_field.find({"field_name": field_var})
                    for map_name_value in map_name1:

                        map_name_value_list1.append(map_name_value["map_name"])


            if not Evaluate_flag:
                for second_loop_lines in cursor1:
                    listofid=second_loop_lines["rule_relation"]
                    listofid=listofid.split(',')
                    if second_loop_lines["Rule"] == p_id and additional_flag ==False:
                        cursor_flag=True



                    if cursor_flag  and second_loop_lines["Rule"] != rule_id:
                        additional_flag=True

                        source_line_list.append(second_loop_lines["source_statements"])
                        print("CHeck2:",second_loop_lines["pgm_name"])
                        METADATA.append({"program_name": second_loop_lines["pgm_name"],
                                         "map_name": (" , ".join(map_name_value_list1)), "field_name": field_var2,
                                         "validation_rule": second_loop_lines["source_statements"], "rule_number": second_loop_lines["Rule"]})

                    if second_loop_lines["Rule"] == rule_id:
                        #source_line_list.append(second_loop_lines["source_statements"] )
                        #print("dseodo1111",second_loop_lines["source_statements"])
                        #print(second_loop_lines["Rule"])
                        #print("rule_id",rule_id)
                        cursor_flag = False
                        below_cursor_flag = True
                        rule_with_space=" "+rule_id


                    if below_cursor_flag and (rule_id in listofid or rule_with_space in listofid)  :

                        source_line_list.append(second_loop_lines["source_statements"] )
                        print("Var2:",field_var2)
                        METADATA.append({"program_name": second_loop_lines["pgm_name"],
                                         "map_name": (" , ".join(map_name_value_list1)), "field_name": field_var2,
                                         "validation_rule": second_loop_lines["source_statements"], "rule_number": second_loop_lines["Rule"]})



                # pgm_name=rule_id.split('-')
                # source_line_split=source_line.split()
                # for field in range(len(source_line_split)):
                #     new_value=' '+source_line_split[field]+' '
                #     if new_value in field_list:
                #         print("dataaaa",source_line_split[field])
                #         field_var=source_line_split[field]
                #         field_var=field_var.strip()
                #         field_var1=field_var
                #         field_var=field_var[:-1]
                #         print(field_var)
                #         map_name=db.cics_field.find({"field_name":field_var})
                #         for map_name_value in map_name:
                #             print("map",map_name_value["map_name"])
                #             map_name_value_list.append(map_name_value["map_name"])

                #METADATA.append({"program_name":second_loop_lines["pgm_name"],"map_name":(" , ".join(map_name_value_list)),"field_name":field_var1,"validation_rule":" ".join(source_line_list),"rule_number":rule_id})

    Db_Insert(METADATA)




df = pd.DataFrame(METADATA)
df.to_csv("final1.csv", index=False, encoding='utf-8')

# keys = METADATA[0].keys()
# with open('CICS2-req-2.csv', 'w') as output_file:
#      dict_writer = csv.DictWriter(output_file, keys)
#      dict_writer.writeheader()
#      dict_writer.writerows(METADATA)
