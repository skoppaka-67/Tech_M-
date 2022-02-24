from pymongo import MongoClient
import copy
import pandas as pd
import numpy as np
hostname = 'localhost'
database_name = 'BNSF_NAT_POC_LATEST'
port = 27017
client = MongoClient(hostname, port)
db = client[database_name]
name=""
op_path = "D:\\BNSF_Excel_data\\"
def sub_main(name,type,call_list):
    component_name = name
    component_type = type
    connections_1 = db.cross_reference_report.find(
        {"$and": [{"component_name": component_name}, {"component_type": component_type}]}, {'_id': 0})
    connections_2=copy.deepcopy(connections_1)
    call_list.extend([x["called_name"] for x in connections_1 if x["called_type"]=="NATURAL-PROGRAM"])
    for k in connections_2:
       if k["called_name"] == name:
           continue
       sub_main(k["called_name"],"NATURAL-PROGRAM",call_list)
    return call_list
def call_chainer():
    call_data = []
    master_data=db.master_inventory_report.find({"component_type" : "NATURAL-PROGRAM"},{"_id":0})
    #master_data=[{"component_name":"WBIB425"}]
    for json_data in master_data:
        call_list=[]
        call_data=[]
        name=json_data["component_name"]
        #name="WBIB425."

        # if not name == "SWBN824.NAT":
        #     continue
        # print(name)
        type="NATURAL-PROGRAM"
        call_list.append(name)
        call_data=sub_main(name,type,call_list)
        with pd.ExcelWriter(op_path+call_data[0]+'.xlsx') as writer1:
            for pgm_name in call_data:
                bre_json_objects,source_json,parent_id,fragment_Id,process_id = get_bre_data_in_list(pgm_name)
                if bre_json_objects ==[]:
                    continue
                print("Processing for--->",pgm_name)
                dct = {
                    "Seq": [x for x in range(1,len(bre_json_objects)+1)],
                    "Fragement_id":fragment_Id,
                    "Source_statement":source_json,
                    "Process": process_id,
                    "Details": bre_json_objects,
                    "parent_rule":parent_id,
                    "Notes":""
                }
                df_1 = pd.DataFrame(dct)
                bre_json_objects.clear()
                source_json.clear()
                parent_id.clear()
                df_1.to_excel(writer1, sheet_name=pgm_name, index=False)

def get_bre_data_in_list(pgm_name):
    bre_json_objects = []
    source_json=[]
    parent_id=[]
    frg_id=[]
    process_id=[]
    BRE_CONN = db.bre_rules_report.find(
        {"pgm_name": pgm_name.split(".")[0]}, {'_id': 0})
    buffer_rule=[]
    prev_rule=""
    process_var=""
    if_data=""
    for data in BRE_CONN:
        if_data = ""
        if prev_rule != data["parent_rule_id"].split(",")[-1]:
            buffer_rule.append("")
            bre_json_objects.append("")
            source_json.append("")
            parent_id.append("")
            frg_id.append("")
            process_id.append("")

        if data["source_statements"].strip().startswith("CALL"):
            process_var = "Call external program "+data["source_statements"].strip().split()[1].replace("'","").replace("<br>","")

        elif data["source_statements"].strip().startswith("FIND ") and not data["source_statements"].__contains__("(1)"):
            process_var = "Search through the file "+ data["source_statements"].split()[1]
        elif data["source_statements"].__contains__("ESCAPE ROUTINE"):
            process_var = "Exit the loop"
        elif data["source_statements"].__contains__(":=") and not( data["source_statements"].strip().startswith("IF ") or
                                                                   data["source_statements"].strip().startswith("WHEN ") or
          data["source_statements"].strip().startswith("ELSE ") or data["source_statements"].strip().startswith("END-REPEAT ") ):
            process_var = "Populate "+data["source_statements"].split(":=")[0].replace("<br>","")

        elif data["source_statements"].strip().startswith("MARK "):
            process_var = data["source_statements"].replace("MARK", "Focus the curosr to the screen field ")
            process_var = process_var.split("(")[0]
        elif data["source_statements"].__contains__("MOVE ") and data["source_statements"].__contains__(" TO "):
            process_var = "Populate "+ data["source_statements"].split(" TO ")[1].replace("<br>","")
        elif data["source_statements"].strip().startswith("PERFORM ") or data["source_statements"].strip().startswith("@PERFORM "):
            process_var ="Execute sub-routine "+ data["source_statements"].strip().split()[1].replace("<br>","")
        elif data["source_statements"].__contains__("END-SUBROUTINE"):
            process_var="End of sub-routine "
        elif data["source_statements"].__contains__("DEFINE ")and data["source_statements"].__contains__(" SUBROUTINE"):
            process_var = data["source_statements"].replace("DEFINE ","Define ").replace("SUBROUTINE","sub-routine").replace("<br>","")
        elif data["source_statements"].__contains__(" DECIDE FOR FIRST CONDITION "):
            process_var="Validate the following condition and process first match"
        elif data["source_statements"].__contains__(" DECIDE FOR EVERY CONDITION "):
            process_var = "Validate the each condition below and execute the logic"
        elif data["source_statements"].strip().startswith("RESET "):
            process_var=data["source_statements"].replace("RESET ","Reset ").replace("<br>","")
        elif data["source_statements"].strip().startswith("DECIDE ON FIRST VALUE "):
            process_var= data["source_statements"].replace("DECIDE ON FIRST VALUE ","Validate the first matching value for variable ").replace("<br>","")

        elif data["source_statements"].strip().startswith("DECIDE ON EVERY VALUE "):
            process_var = data["source_statements"].replace("DECIDE ON EVERY VALUE ",
                                                            "Validate for the every matching value of ").replace(
                "<br>", "")

        elif data["source_statements"].strip().__contains__("FETCH RETTURN"):
           process_var = " Execute the external program "+data["source_statements"].split("RETURN")[1].strip().split()[0].reaplce("'","") + \
                         " and return back the control after execution "


        elif data["source_statements"].strip().startswith("EXAMINE ") and data["source_statements"].__contains__(" FOR ") and \
                data["source_statements"].__contains__(" GIVING "):
            process_var = data["source_statements"].replace("EXAMINE","Search through the array")
            process_var=process_var.split("GIVING")[0].replace("<br>","")

        elif   data["source_statements"].strip().startswith("SELECT ") and data["source_statements"].__contains__(" VIEW ") and \
                data["source_statements"].__contains__(" FROM "):
           try:
             process_var  = "Lookup database "+  data["source_statements"].split("FROM")[1].split()[0] + " for matching records and fetch into view " + \
                            data["source_statements"].split("VIEW")[1].split()[0]

           except Exception as e:
               print(data["source_statements"])
               process_var=""
        else:
            process_var=""

        op_list=["AND","OR","EQ","NE","=",":=","<",">","<=",">=","GE","GQ"]

        if data["source_statements"].strip().startswith("IF "):

            if len(data["source_statements"].replace("<br>","").split())>2:
                if not data["source_statements"].strip().split()[1].startswith("(") and not data["source_statements"].strip().split()[2] in op_list:
                    None

            else:

                 if_data= data["source_statements"].strip().replace("IF ","if ").replace("<br>","")+" is valid then "

        process_id.append(process_var)
        buffer_rule.append(data["parent_rule_id"])
        if  if_data == "":
            # Adding MOVE ,ADD, COMPRESS.
            if data["source_statements"].strip().startswith("MOVE") and (
                    data["source_statements"].strip().split()[1] == ("RIGHT") or
                    data["source_statements"].strip().split()[1] == ("LEFT")) and data[
                "source_statements"].strip().__contains__(" TO "):

                data_1=data["source_statements"].replace('<br>','')
                quote_flag=False
                if data_1.__contains__("'"): # Value inside quote are replaced with "_" and processed to prevent from lossing data.
                    var_val=data_1.split("'")[1].replace(" ","_")
                    data_1=data_1.replace(data_1.split("'")[1] , var_val)
                    quote_flag=True

                data_1=" Populate " +data_1.split(" TO ")[1].strip().split()[0]+" with "+ data_1.split(" TO ")[0].strip().split()[-1]+ " " + \
                data_1.split()[1].strip()+" aligned"

                if quote_flag:
                    data_1=data_1.replace(var_val ,var_val.replace("_"," "))
                    quote_flag = False
                bre_json_objects.append(data_1)

            elif data["source_statements"].strip().startswith("ADD ") and  data[
                "source_statements"].strip().__contains__(" TO "):
                data_1=data["source_statements"].replace('<br>', '')
                mod_data="Increase "+data_1.split(" TO ")[1].split()[0]+" by "+ data_1.split(" TO ")[0].split()[-1]
                bre_json_objects.append(mod_data)

            elif data["source_statements"].strip().startswith("COMPRESS ") and  data[
                "source_statements"].strip().__contains__(" INTO "):

                data_1 = data["source_statements"].replace('<br>', '')

                bre_json_objects.append(data_1.replace("COMPRESS","CONCATENATE").replace("INTO ","and populate to "))

            else:
                bre_json_objects.append(data["rule_description"].replace("<br>",""))
        else:

            bre_json_objects.append(if_data)

        if data["source_statements"].replace("<br>","").__contains__("END-SUBROUTINE"):
            sub_var="END-SUBROUTINE"+"- ("+data["para_name"]+")"
            source_json.append(data["source_statements"].replace("<br>","").replace("END-SUBROUTINE",sub_var))
        else:
          source_json.append(data["source_statements"].replace("<br>",""))

        parent_id.append(data["parent_rule_id"])
        frg_id.append(data["fragment_Id"])

        if len(data["parent_rule_id"]) > 0:
            prev_rule = data["parent_rule_id"].split(",")[-1]
        else:
            prev_rule=""

    return bre_json_objects,source_json,parent_id,frg_id,process_id


call_chainer()
