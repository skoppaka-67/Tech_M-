import os,copy
import re
from pymongo import MongoClient
import datetime
import pytz
import requests
import json

os.chdir(r"D:\WORK\POC's\BNSF\SSI\NAT")
a = [0] * 2
meta_data = []
# write_file=open("output_3.json", "w+")
client = MongoClient("localhost", 27017)
db = client["BNSF_NAT_SSI"]
table_name={}

def Remove(duplicate):
    final_list = []
    for list_iter in duplicate:
        if list_iter not in final_list:
            final_list.append(list_iter)
    return final_list
## ret_table returns table name which is present in that line. If the line contains number instead of table name, it will return number and based on that we can process furthre
def ret_table(files, read_lines, table_names):
  num_flag= False
  lines = re.search("^read\s|^get\s|^find\s|^update|^store|^delete|^select", read_lines[5:].strip().lower())
  try:
    if lines.string:
      x = read_lines[5:].strip().split()
      if (len(x) > 1):
        if x[1].strip().__contains__("("):
          # print(x[1])
          num= x[1].split("(")[1].split(")")[0]
          # print("num", num)
          if type(eval(num))==int:
              num_flag=True
              # print("integer",num)

        if (x[1].strip() == "NUMBER" or x[1].strip() == "FIRST" or num_flag or x[1].strip() == "RECORD"):
            if x[2] in table_names.keys():
                # print("read lines", read_lines)
                table = table_names[x[2]]
                # print("table names 1", table_names)
                # print(x[2])
                # print("modified table", table)
            else:
                # print("insid e numbers",x)
                table=x[2]
        ################ Added by Kiran ################
        # elif "FROM" in x :
        #
        #         index_of_from = x.index("FROM")
        #         table = x[index_of_from+1]

        else:
            if read_lines[5:].strip().lower().startswith("find"):
                # print("find", read_lines)
                if x[1] in table_names.keys():
                    # print("read lines", read_lines)
                    table = table_names[x[1]]
                    # print("table names 2",table_names)
                    # print(x[1])
                    # print("modified table", table)
                else:
                    # print("insid e /numbers",x)
                    table = x[1]
            else:
                table = x[1]

      elif (len(x) == 1 and x[0] == "DELETE" or x[0] == "STORE" or x[0] == "UPDATE"):
        # print(files,x)
        table = meta_data[len(meta_data) - 1]['table']
      table = table.replace("(", "")
      table = table.replace(")", "")
      if (table.isdigit() and len(table) <= 3):
        table = x[2]
      elif (table == "/*"):
        table = x[0]
      return table  ##Returns table name
  except Exception as e:
    # print(e)
    pass


for files in os.listdir():
  # print(files)
  if (files.endswith(".NAT")):
    open_file = open(os.getcwd() + "\\" + files).readlines()
    open_file1 = iter(open_file)
    line_list = copy.deepcopy(open_file)
    for read_lines in line_list:
      commentline = read_lines[5:]
      if commentline.lstrip().startswith("*") or commentline.lstrip().startswith("/*"):
        continue
      else:
        if read_lines.lower().__contains__("view of"):
            key_name=read_lines[7:].split("VIEW OF")[0].strip()
            value_name=read_lines[7:].split("VIEW OF")[1].strip()
            table_name[key_name]=value_name

        # print("table_name",table_name)
        table = ret_table(files, read_lines, table_name)  ##Return Table name
      if (table != None):
        xy = open_file.index(read_lines)
        sql_query = ''
        sql_query += (open_file[xy][5:]).strip() + " "  ##adding 1st line to sql query
        next_line = 0

        ##getting queried lines
        while (next_line != -1):
          strip_line = open_file[xy + next_line][5:].strip().lower()
          strip_line1 = open_file[xy + next_line + 1][5:].strip().lower()
          ################ Modified by Kiran ################
          if (strip_line.endswith("with") or strip_line1.startswith("where") or strip_line1.startswith(
            "start") or strip_line1.startswith("and") or strip_line1.startswith("or") or strip_line1.startswith("into")or strip_line1.startswith("from") or strip_line1.startswith("set")or strip_line1.startswith(",")  or strip_line1.startswith("with") or strip_line1.startswith("view") ): #combine these lines with previous line
            sql_query += (open_file[xy + next_line + 1][5:]).strip() + " "
            if sql_query.__contains__("/"):
                index_value = sql_query.index("/*")
                sql_query = sql_query[0:index_value].strip()
          else:
            next_line = -1
            break
          next_line += 1 #to go the next index of line in file
          sql_query = sql_query.replace("\n", "")
          if sql_query.__contains__("/"):
              index_value = sql_query.index("/*")
              sql_query = sql_query[0:index_value].strip()
        ################ added by Kiran ################
          if strip_line.__contains__("end-select"):
              break

        crud_val = read_lines[5:].lower().split()[0]
        if (crud_val == "get" or crud_val == "find" ):
          crud_val = "READ"
        if (crud_val == "store"):
          crud_val = "CREATE"
        if (table.isdigit()): #To go the particular line based on the number
          if (len(table) > 3):
            for new_read_line in open_file:
              if (new_read_line[:5].find(table) >= 3):
                table = ret_table(files, new_read_line, table_name)  ##if it is a line number
        if (table.endswith('.') and table!=None ):  ##if it is a label
          for new1_read_line in range(len(open_file)):
            # print("2", table.lower(), table)
            if (type(open_file[new1_read_line][4:].strip())!=None and table!=None and  open_file[new1_read_line][4:].lower().strip() == table.lower()):
              table = ret_table(files, open_file[new1_read_line + 1], table_name)
        crud_val = crud_val.upper()

        # print("working")
        if (table == 'SAME' or table == "same"): #fetching previous table name
          # print(read_lines[8:].strip().lower())
          table = meta_data[len(meta_data) - 1]['table']
          # print(table)
        if (crud_val == "READ" or crud_val == "CREATE" or crud_val == "UPDATE" or crud_val == "DELETE" or crud_val =="SELECT") :
          if crud_val == "DELETE":
            table = sql_query.split()[2]
          if crud_val == "SELECT":
            # if table == '*':

              split_query = sql_query.split()
              # print(type(split_query))
              # table = sql_query.split()[4]


              multitable_list = []
              from_flag = False
              for i in split_query:
                  if i =="FROM":
                      from_flag = True
                      continue
                  if i == "WHERE":
                      from_flag = False
                  if from_flag:
                    multitable_list.append(i)
              if len(multitable_list) == 1:
                  table = multitable_list[0]
              else:
                  s = '^'.join(multitable_list)
                  comma_list = s.split(",")
                  for i in comma_list:
                     single_table_list = i.split("^")

                     if len(single_table_list)<=2:
                         table = single_table_list[0]
                         json_format = {
                             "component_name": files,
                             "component_type": "NATURAL-PROGRAM",
                             "calling_app_name": "Unknown",
                             "table": table,
                             "CRUD": crud_val.replace("SELECT","READ"),
                             "SQL": sql_query
                         }
                         meta_data.append(json_format)
                     else:
                         table = single_table_list[1]
                     # continue
                         json_format = {
                             "component_name": files,
                             "component_type": "NATURAL-PROGRAM",
                             "calling_app_name": "Unknown",
                             "table": table,
                             "CRUD": crud_val.replace("SELECT","READ"),
                             "SQL": sql_query
                         }
                         meta_data.append(json_format)

          if sql_query.__contains__("/"):
              index_value = sql_query.index("/*")
              sql_query = sql_query[0:index_value].strip()
          json_format = {
            "component_name": files,
            "component_type": "NATURAL-PROGRAM",
            "calling_app_name":"Unknown",
            "table": table,
            "CRUD": crud_val.replace("SELECT","READ"),
            "SQL": sql_query
          }
          meta_data.append(json_format)

# f=open("crud_jsonv1.1.json","w+")
# f.write(json.dumps(meta_data, indent=4))
try:
  db.crud_report.delete_many({})
except Exception as e:
  print('Error while deleting missing components report:' + str(e))
# r = requests.post('http://localhost:5008/api/v1/update/', json={"data": meta_data,
#                                                                                "headers": ["COMPONENT_NAME", "COMPONENT_TYPE",
#                                                                                            "TABLE", "CRUD", "SQL"]})
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
print("metadata", meta_data)
try:

  db.crud_report.insert_one(
    {"type": "metadata", "COBOL": {"last_updated_on": current_time, "time_zone": time_zone},
     "headers": ["component_name", "component_type","calling_app_name", "table", "CRUD", "SQL"]})
  db.crud_report.insert_many(Remove(meta_data))

except Exception as e:
  print(e)



