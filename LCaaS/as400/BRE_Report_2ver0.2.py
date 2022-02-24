from pymongo import MongoClient
import pandas as pd
import xlrd,copy,re,datetime,os,glob
import pytz
import json
from operator import itemgetter
SCRIPT_VERSION = "BRE-Report2- Author - Saikiran After fixing missing lines and replaceing parent rule id at some palces   "


mongoClient = MongoClient('localhost', 27017)
db = mongoClient['as400']
h = {"type": "metadata", "headers":["fragment_id","pgm_name", "para_name", "source_statements","rule_category", "Rule"]}
db.bre_report2.remove()
db.bre_report2.insert_one(h)
bre_json_objects = []
Meatadata = []
flag = False
storage = []
parent_rule_id_List = []
RPG_Path ="D:\AS400\RPG1"
parent_rule_realation_List = []
#print(sheet.row_values(1))
new_json = {
'fragment_id':'',
"para_name":'',
'pgm_name':" ",
'source_statements':'',
'rule_category':'',
'parent_rule_id':"",
'rule_description':""


}
matadata=[]
lookup_List = []
sorted_parent_id_list = []
parent_rule_id_dict={}
prev_parent_id = []
whencounter = 0
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)

def sorted_nicely( l ):
    """ Sort the given iterable in the way that humans expect."""
    convert = lambda text: int(text) if text.isdigit() else text
    alphanum_key = lambda key: [ convert(c) for c in re.split('([0-9]+)', key) ]
    return sorted(l, key = alphanum_key)

def Remove(duplicate):
    final_list = []
    for list_iter in duplicate:
        if list_iter not in final_list:
            final_list.append(list_iter)
    return final_list

def main():
    flag = False


    collection = db.bre_rules_report
    details = collection.find({"$and":[{"parent_rule_id" :{"$ne": ""}},
                                       {"source_statements": {"$ne": "endif"}},
                                       {"source_statements": {"$ne": "select"}},
                                       {'type': {"$ne": "metadata"}},
                                       ]}).sort("_id",1)
    for bre_data_iter in details:

        bre_json_objects.append(bre_data_iter)

    #print(bre_json_objects)
    df = pd.DataFrame(bre_json_objects)

    # del df["business_documentation"]
    df.to_excel("Book11.xlsx", index=False)
    loc = ("Book11.xlsx")
    wb = xlrd.open_workbook(loc)
    sheet = wb.sheet_by_index(0)
    sheet.cell_value(0, 0)


    for i in range(1,sheet.nrows):
        # print(i)

      j = i + 1
      try:
        if j < sheet.nrows:

            if sheet.cell_value(i, 4) != sheet.cell_value(j, 4):
                # new_json.clear()

                new_json["para_name"] = sheet.row_values(i)[3]
                new_json['pgm_name'] = sheet.row_values(i)[5]
                new_json['source_statements'] = new_json['source_statements'] + " <br> " + str(storage).strip("[]").replace(",","").replace('"',"")

                new_json['parent_rule_id'] = sheet.row_values(i)[4]
                new_json["rule_description"]= ""
                storage.clear()
                new_json1 = copy.deepcopy(new_json)
                Meatadata.append(new_json1)
                # print(Meatadata)
                new_json.clear()
                flag = False

            if flag:
                storage.append(sheet.row_values(j)[8] + " <br> ")
                continue

            if sheet.cell_value(i, 4) == sheet.cell_value(j, 4):
                # new_json.clear()
                new_json["para_name"] = sheet.row_values(i)[3]
                new_json['pgm_name'] = sheet.row_values(i)[5]
                new_json['source_statements'] = sheet.row_values(i)[8] + " <br> " + sheet.row_values(j)[8]
                new_json["rule_description"] = ""
                flag = True
        else:

            new_json["para_name"] = sheet.row_values(i)[3]
            new_json['pgm_name'] = sheet.row_values(i)[5]

            new_json['source_statements'] = new_json['source_statements'] + " <br> " + str(storage).strip("[]").replace(
                ",", "").replace('"', "")
            new_json["rule_description"] = ""
            new_json['parent_rule_id'] = sheet.row_values(i)[4]

            storage.clear()
            new_json1 = copy.deepcopy(new_json)
            Meatadata.append(new_json1)
      except KeyError as e :
          new_json['source_statements'] = sheet.row_values(i)[8]
          new_json["rule_description"] = ""
          new_json['parent_rule_id'] = sheet.row_values(i)[4]
          storage.clear()
          new_json1 = copy.deepcopy(new_json)
          Meatadata.append(new_json1)
          # print(Meatadata)
          new_json.clear()

    #print(json.dumps(Meatadata, indent=4))

    for index,i in enumerate(Meatadata,1):

            unsplitted_parent_id = i["parent_rule_id"]
            #print(unsplitted_parent_id)
            pgmname = i["pgm_name"]
            paraname = i['para_name']
            source_statements = i['source_statements']
            Rule = i['parent_rule_id']
            rule_relation = ""
            # print(bre2_json)
            bre2_json = {"fragment_id":index,"pgm_name": pgmname, "para_name": paraname, "source_statements": source_statements,'rule_category':'',"rule_description":"" ,'Rule': Rule,
                         'rule_relation': rule_relation}
            splitted_parent_id = unsplitted_parent_id.split(",")
            #print(splitted_parent_id)

            if len(splitted_parent_id) == 1:
                bre2_json['Rule']= splitted_parent_id[0]
                parent_rule_id_List.append(splitted_parent_id[0])

            else:
                var = len(splitted_parent_id)
                parent_rule_id_List.append(splitted_parent_id[var-1])

                bre2_json['Rule'] = splitted_parent_id[var-1]

                bre2_json['rule_relation']= (splitted_parent_id[:var-1])
                parent_rule_realation_List.append(splitted_parent_id[:var-1])


            matadata.append(bre2_json)


            #continue

    for i in parent_rule_id_List:
        lookup_List.append(i)

    for i in parent_rule_realation_List:
        for j in i:
            lookup_List.append(j)


    for x in sorted_nicely(lookup_List):
        sorted_parent_id_list.append(x)



    no_dup_list = Remove(sorted_parent_id_list)

    for filename in glob.glob(os.path.join(RPG_Path, '*.RPG')):

        #print(filename.strip("D:\AS400\RPG\\").strip("."))
        compnentname = filename.strip("D:\AS400\RPG1\\").strip(".")
        index = 1
        #for index, item in enumerate(no_dup_list, start=1):
        for item in no_dup_list:

            current_compnentname = item.split("-")[0]

            if compnentname == current_compnentname:

                parent_rule_id_dict[item] = "Rule" + "-" + str(index).zfill(4)
                index = index+1
                continue
            else:
                current_compnentname = item.split("-")[0]
                index = 1








    for k, v in parent_rule_id_dict.items():
        for i in matadata:
            if i['Rule'] == k:
                i['Rule'] = v

    for k, value in parent_rule_id_dict.items():
        for iter in matadata:
            for i in iter['rule_relation']:

                if i == k:
                    iter['rule_relation'].remove(k)
                    iter['rule_relation'].append(value)

    for sub in matadata:  # convert dict values to string
        for key in sub:
            sub[key] = str(sub[key]).strip("[]").replace("'","")



    whencounter = 0
    for index , item in enumerate(matadata): # fix for select when issue
        try:
            if item["source_statements"].__contains__("when") :
                whencounter = whencounter +1

            if whencounter == 1:
                matadata[index]['source_statements']=" select <br> "+matadata[index]['source_statements']

            if item["source_statements"].__contains__("endsl"):
                item["source_statements"] = item["source_statements"][10:]
                whencounter = 0

        except IndexError as e :
            pass

    print(json.dumps(matadata,indent=4))







    try:
        db.bre_report2.delete_many({'type': {"$ne": "metadata"}})

    except Exception as e:
        print('Error:' + str(e))

        # Insert into DB
    try:

        db.bre_report2.insert_many(matadata)

        # updating the timestamp based on which report is called
        current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        if db.bre_report2.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                     "time_zone": time_zone,
                                                                     # "headers":["component_name","component_type"],
                                                                     "script_version": SCRIPT_VERSION
                                                                     }}, upsert=True).acknowledged:
            print('update sucess')

    except Exception as e:
        print('Error:' + str(e))
    os.remove("Book11.xlsx")
    new_json.clear()
    bre_json_objects.clear()
    no_dup_list.clear()

    matadata.clear()
    Meatadata.clear()
    lookup_List.clear()
    sorted_parent_id_list.clear()
    parent_rule_id_dict.clear()
    prev_parent_id.clear()
    parent_rule_realation_List.clear()

    parent_rule_id_List.clear()



main()