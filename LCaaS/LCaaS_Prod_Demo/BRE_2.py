from pymongo import MongoClient

import copy,re,datetime
from termcolor import  cprint
import pytz
import cProfile

SCRIPT_VERSION = "BRE-Report2 Author - Saikiran "
"""
SCRIPT --- Rules Report

Input --- Detailed Report

Output Format --

{
"fragment_id":"",
"para_name":'',
'pgm_name':" ",
'source_statements':'',
'Rule category':"",
'parent_rule_id':""
}


"""

''' Database Connection

Host - 127.0. 0.1
Db_name -  CRST_FULLV1

'''
mongoClient = MongoClient('localhost', 27017)
db = mongoClient['CRST_FULLV1']

bre_json_objects = []
Meatadata = []

storage = []
parent_rule_id_List = []

parent_rule_realation_List = []

new_json = {
"fragment_id":"",
"para_name":'',
'pgm_name':" ",
'source_statements':'',
'Rule category':"",
'parent_rule_id':""

}
matadata=[]
lookup_List = set()
sorted_parent_id_list = []
parent_rule_id_dict={}
prev_parent_id = []
whencounter = 0
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)




def InsterHeaders():
    """
    Function will take no parameters 
    insert headers into db 
    
    :return: None
    """
    try:
        db.bre_report2.Remove_duplicates()
        h = {"type": "metadata",
             "headers": ["fragment_id", "pgm_name", "para_name", "source_statements", "rule_category", "Rule"]}

        db.bre_report2.insert_one(h)
        cprint("Headers Got Inserted...!",'blue')

    except Exception as e:
        print('Error:' + str(e))

def sorted_nicely( l ):
    
    """ Sort the given iterable in the way that humans expect. (Not in binary way based on digits)"""
    
    convert = lambda text: int(text) if text.isdigit() else text
    alphanum_key = lambda key: [ convert(c) for c in re.split('([0-9]+)', key) ]

    return sorted(l, key = alphanum_key)

def Remove_duplicates(duplicate):
    """
    
    
    :param duplicate: list with duplicates
    :return: List without duplicates
    """
    final_list = []
    for list_iter in duplicate:
        if list_iter not in final_list:
            final_list.append(list_iter)
    return final_list

def main():


    ''' Component names list from BRE1 to process component by component in serialized manner'''
    compnentname_list = db.bre_rules_report.distinct("pgm_name")

    ''' Component names list from BRE2 to keep track of execution in case of abrupt termination'''
    bre_complist = db.bre_report2.distinct("pgm_name")

    '''Use this List only when you want to ignore components - add them to below list '''
    ignore_list = []

    for component in compnentname_list:

     if component != None:

        '''check component is already processed incase of faliure or abending'''
        if  component.split(".")[0] in bre_complist  or component.split(".")[0] in ignore_list :

            print(component,"igonred")

            continue

        flag = False

        process_start_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("Process for"+component+"is Started at - "+str(process_start_time),'green')

        start_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("DB got hit at "+str(start_time), "yellow" )

        collection = db.bre_rules_report

        '''To Filter and Fetch BRE-1 Records as required for rest of the process '''

        details = collection.find({"$and":[{"pgm_name": component},
                                            {"parent_rule_id" :{"$ne": ""}},

                                           {'type': {"$ne": "metadata"}},
                                          ]}).sort("_id",1)



        [bre_json_objects.append(s) for s in details]

        end_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
        cprint("Data got Fetched at " + str(end_time), 'yellow')


        for i in range(0,len(bre_json_objects)):


            j = i + 1

            # print(i)

            try:
                if j < len(bre_json_objects):

                    if bre_json_objects[i]['source_statements'].__contains__("EVALUATE") and not (bre_json_objects[i]['source_statements'].__contains__("END-EVALUATE ")):
                        bre_json_objects[i]['parent_rule_id'] = bre_json_objects[j]['parent_rule_id'] ## Evaluate handling

                    '''Based on parent rule Id- Grouping the Records'''

                    if bre_json_objects[i]['parent_rule_id'] != bre_json_objects[j]['parent_rule_id']:

                        new_json["para_name"] = new_json["para_name"]
                        new_json['pgm_name'] = bre_json_objects[i]['pgm_name'].replace(".","")
                        new_json['source_statements'] = new_json['source_statements'] + " <br> " + str(storage).strip(
                            "[]").replace(",", "").replace('"', "")
                        new_json['parent_rule_id'] = bre_json_objects[i]['parent_rule_id']
                        storage.clear()
                        new_json1 = copy.deepcopy(new_json)
                        Meatadata.append(new_json1)
                        # print(Meatadata)
                        new_json.clear()
                        flag = False

                    if flag:
                        storage.append(bre_json_objects[j]['source_statements'] + " <br> ")
                        continue

                    if bre_json_objects[i]['parent_rule_id'] == bre_json_objects[j]['parent_rule_id']:
                        # new_json.clear()
                        new_json["para_name"] =bre_json_objects[i]['para_name']
                        new_json['pgm_name'] = bre_json_objects[i]['pgm_name'].replace(".","")
                        new_json['source_statements'] =bre_json_objects[i]['source_statements']+ " <br> " + bre_json_objects[j]['source_statements']
                        flag = True
                else:

                    new_json["para_name"] = bre_json_objects[i]['para_name']
                    new_json['pgm_name'] = bre_json_objects[i]['pgm_name'].replace(".","")

                    new_json['source_statements'] = new_json['source_statements'] + " <br> " + str(storage).strip(
                        "[]").replace(
                        ",", "").replace('"', "")
                    new_json['parent_rule_id'] = bre_json_objects[i]['parent_rule_id']
                    storage.clear()
                    new_json1 = copy.deepcopy(new_json)
                    Meatadata.append(new_json1)
            except KeyError as e:
                # print(e)
                if str(e).__contains__('para_name'):#rule continuation (nested ifs)
                    new_json["para_name"] = bre_json_objects[i]['para_name']
                    new_json['pgm_name'] = bre_json_objects[i]['pgm_name'].replace(".", "")

                    new_json['source_statements'] = bre_json_objects[i]['source_statements']
                    new_json['parent_rule_id'] =bre_json_objects[i]['parent_rule_id']
                    storage.clear()
                    new_json1 = copy.deepcopy(new_json)
                    Meatadata.append(new_json1)

        '''collecting old rule id '''
        for index,i in enumerate(Meatadata,1):

                unsplitted_parent_id = i["parent_rule_id"]
                pgmname = i["pgm_name"].replace(".","")
                paraname = i['para_name']
                source_statements = i['source_statements']
                Rule = i['parent_rule_id']
                rule_relation = ""

                bre2_json = {"fragment_id": component.replace('.','')+"-"+str(index),"pgm_name": pgmname.replace(".",""), "para_name": paraname, "source_statements": source_statements,'rule_category':" ", 'Rule': Rule,
                             'rule_relation': rule_relation,"rule_description":""}
                splitted_parent_id = unsplitted_parent_id.split(",")


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

        [lookup_List.add(i) for i in parent_rule_id_List]


        for i in parent_rule_realation_List:
            for j in i:
                lookup_List.add(j)



        [sorted_parent_id_list.append(x) for x in sorted_nicely(lookup_List)]





        for filename in compnentname_list:
          if filename != None:


            compnentname =  filename.replace(".","")

            index = 1

            for item in sorted_parent_id_list:

                current_compnentname = item.split("-")[0]

                if compnentname == current_compnentname:

                    parent_rule_id_dict[item] = "Rule" + "-" + str(index).zfill(4)
                    index = index+1
                    continue
                else:
                    current_compnentname = item.split("-")[0]
                    index = 1



        '''' New Rule's and Rule Relation Tagging   '''

        for i in matadata:
            i['Rule'] = parent_rule_id_dict[i['Rule']]


        for iter in matadata:
            if len(iter['rule_relation']) == 1:
                iter['rule_relation'] = parent_rule_id_dict[str(iter['rule_relation']).strip("[]").replace("'","")]
            else:
                for ii in iter['rule_relation']:
                    if ii  in parent_rule_id_dict.keys():
                        pos = iter['rule_relation'].index(ii)
                        #for remmoving and inserting at the same index.
                        iter['rule_relation'].pop(pos)
                        iter['rule_relation'].insert(pos,parent_rule_id_dict[ii])




        for sub in matadata:  # convert dict values to string
            for key in sub:
                sub[key] = str(sub[key]).strip("[]").replace("'","")


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
                process_end_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
                cprint("Data for " + component + " Genrated..... and Inserted to DataBase ..! at "+str(process_end_time),'magenta')

        except Exception as e:
            print('Error:' + str(e))

        new_json.clear()
        bre_json_objects.clear()


        matadata.clear()
        Meatadata.clear()
        lookup_List.clear()
        sorted_parent_id_list.clear()
        parent_rule_id_dict.clear()
        prev_parent_id.clear()
        parent_rule_realation_List.clear()

        parent_rule_id_List.clear()



cProfile.run('main()')
# main()