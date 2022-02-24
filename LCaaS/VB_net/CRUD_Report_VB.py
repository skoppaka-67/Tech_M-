import config
import os, re, sys
import requests
from pymongo import MongoClient
code_location = config.codebase_information['code_location']
pgm_list = []
mongoClient = MongoClient('localhost', 27017)
db = mongoClient['vb_update']
class crud():

    def __init__(self):
       global  metadata
       metadata= []
    def main(filename):
      try:
        prev_flag = False
        test_flag=False
        variable_dict={}
        sql_query=""
        pgm_list.append(filename.split('\\')[-1])
        with open(filename,encoding='utf8') as input_file:
            for line in input_file:
                if line.strip().startswith("'") or line.strip() == "":
                    continue
                if line.strip().endswith("_"):
                   prev_line=line
                   prev_flag=True
                   continue
                if prev_flag:
                    line=prev_line.replace("\n"," ")+line
                    prev_line=""
                if line.strip().startswith("If "):
                    continue
                if re.search('\s*\w*\s*[=]\s*"\s*\w.*"',line):
                    var_name=line.split("=")[0].strip().split(" ")
                    sql_data= line.split("=")[1].strip()
                    if len(var_name)==4:
                        variable_dict[var_name[1]]=sql_data
                    elif len(var_name)==2:
                        variable_dict[var_name[1]] = sql_data
                    elif len(var_name) == 1:
                        variable_dict[var_name[0]] = sql_data
                if line.__contains__("SqlCommand") or line.__contains__("SqlDataAdapter"):

                    test_flag=True

                    sql_query=line.lower().split("new")[1]

                    if sql_query.__contains__('"'):
                        sql_query=sql_query.split('"')[1]
                    else:
                        sql_query=sql_query.split("(")[1].split(",")[0]
                        sql_query=variable_dict[sql_query].replace('"','')
                    #crud.output_func(sql_query,filename,metadata)
                if line.upper().__contains__("END FUNCTION") or line.upper().__contains__("END SUB"):
                    variable_dict.clear()
        return test_flag
      except Exception as e:
          exc_type, exc_obj, exc_tb = sys.exc_info()
          fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
          print(exc_type, fname, exc_tb.tb_lineno)
          return e
    def output_func(sql_query,pgm_name,metadata):

        try:

            if sql_query.upper().strip().startswith("INSERT "):
                table_name=sql_query.split()[2].split("(")[0]
                crud="CREATE"
            elif sql_query.upper().strip().startswith("SELECT "):
                table_name=sql_query.split("from")[1].strip().split(" ")[0].split("(")[0]
                crud = "READ"
            elif sql_query.upper().strip().startswith("UPDATE "):
                table_name = sql_query.split()[1].split("(")[0]
                crud="UPDATE"
            elif sql_query.upper().strip().startswith("DELETE "):
                table_name = sql_query.split()[1].split("(")[0]
                if table_name=="from":
                    table_name = sql_query.split()[2].split("(")[0]
                crud="DELETE"
            com_type=""
            if len(pgm_name.split("\\")[-1].split('.'))==2:
                com_type="VB"
            elif len(pgm_name.split("\\")[-1].split('.'))==3:
                com_type="CODEBEHIND"

            metadata.append({"component_name" : pgm_name.split("\\")[-1],
            "component_type" : com_type,
            "Table" : table_name,
            "CRUD" : crud,
            "SQL" : sql_query,
            "calling_app_name" :pgm_name.split("\\")[-2].upper()
             })

        except Exception as e:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
            print(exc_type, fname, exc_tb.tb_lineno)

        return metadata
    def Db_Insert(METADATA):

        import time, datetime, pytz
        time_zone = 'Asia/Calcutta'
        tz = pytz.timezone(time_zone)
        UpdateCounter = 0
        UpdateCounter = UpdateCounter + 1
        db_data = {"data": METADATA,
                   "headers": ['component_name','component_type','Table','CRUD','SQL','calling_app_name']}
        try:
            keys = list(db_data.keys())
            print('parent keys', keys)
            if 'data' in keys:
                # fetching headers
                x_CRUD_report_header_list = db_data['headers']
                print('COBOL Report header list', x_CRUD_report_header_list)
                # Adding header field to db_data
                db_data['headers'] = x_CRUD_report_header_list
                if len(db_data['data']) == 0:
                    print({"status": "failure", "reason": "data field is empty"})
                else:
                    # Delete all COBOl associated records in the table
                    previousDeleted = False
                    try:
                        if UpdateCounter == 1:
                            if db.crud_report.delete_many(
                                    {"type": {"$ne": "metadata"}}).acknowledged:
                                print('Deleted all the COBOL components from the x-reference report')
                                previousDeleted = True
                                print('--------just deleted all de cobols')
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

                            db.crud_report.insert_many(db_data['data'])
                            print('db inserteed bro')
                            # updating the timestamp based on which report is called
                            current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
                            # Setting the time so that we know when each of the JCL and COBOLs were run

                            # db.cross_reference_report.insert_one({"type":"metadata", "JCL":{"last_updated_on":ct},"COBOL":{"last_updated_on":ct}})

                            if db.crud_report.count_documents({"type": "metadata"}) > 0:
                                print('meta happen o naw',
                                      db.crud_report.update_one({"type": "metadata"},
                                                                     {"$set": {
                                                                         "BRE.last_updated_on": current_time,
                                                                         "BRE.time_zone": time_zone,
                                                                         "headers": x_CRUD_report_header_list
                                                                     }},
                                                                     upsert=True).acknowledged)
                            else:
                                db.crud_report.insert_one(
                                    {"type": "metadata",
                                     "COBOL": {"last_updated_on": current_time, "time_zone": time_zone},
                                     "headers": x_CRUD_report_header_list})

                            print(current_time)
                            print({"status": "success", "reason": "Successfully inserted data and "})
                        except Exception as e:
                            print('Error' + str(e))
                            print({"status": "failed", "reason": str(e)})

        except Exception as e:
            print('Error: ' + str(e))
            print({"status": "failure", "reason": "Response json not in the required format"})

        return "success"
    def startup(self):
        for path, subdirs, files in os.walk(code_location):
            for name in files:
                # if not name == "CPProp3Year.VB":
                #     continue
                filename = os.path.join(path, name)
                if filename.split('\\')[-1].upper().endswith(".VB") or filename.split('\\')[-1].upper().endswith("MASTER.VB"):

                # if filename.split("\\")[-1].split('.')[-1].upper() == "VB" or filename.split("\\")[-1].split('.')[1].upper() == "ASPX" :
                    crud.main(filename)
        print(metadata)
        crud.Db_Insert(metadata)

if __name__ == '__main__':
    crud_object=crud()
    crud_object.startup()
