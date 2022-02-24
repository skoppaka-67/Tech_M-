from pymongo import MongoClient
hostname = 'localhost'
database_name = 'BNSF_NAT_SSI'
import xlsxwriter
#database_name1='COBOL'
port=27017
client = MongoClient(hostname, port)
db = client[database_name]
workbook = xlsxwriter.Workbook('call_chain.xlsx')
worksheet = workbook.add_worksheet("call_chain")
Format=workbook.add_format({'bold': True,'bg_color':'yellow','border_color':'black'})
worksheet.write('A1','Level_1',Format)
worksheet.write('B1','Level_2',Format)
worksheet.write('C1','Level_3',Format)
worksheet.write('D1','Level_4',Format)
worksheet.write('E1','Level_5',Format)
worksheet.write('F1','Level_6',Format)
worksheet.write('G1','Level_7',Format)
worksheet.write('H1','Level_8',Format)
worksheet.write('I1','Level_9',Format)
worksheet.write('J1', 'Level_10', Format)

data=db.orphan_report.find({"component_type" : "NATURAL-PROGRAM"})

row=1

def callchain(name,type,col,CL):
    global row
    name_list = []
    if col==0:
        worksheet.write(row, col, name)
    col=col+1
    component_name = name

    component_type = type
    connections_1 = db.cross_reference_report.find(
        {"$and": [{"component_name": component_name}, {"component_type": component_type}]}, {'_id': 0})
    for k in connections_1:
        worksheet.write(row, col, k["called_name"])

        if k["called_name"] == name or k["called_name"] in CL:

            continue
        CL.append(k["called_name"])
        callchain(k["called_name"],k["called_type"],col,CL)
        connections = db.cross_reference_report.find(
            {"$and": [{"component_name": k["called_name"]}, {"component_type": k["called_type"]}]}, {'_id': 0}).count()
        name_list.append(name)
        if connections == 0:
          row = row + 1
    col=0


for k in data:
    col=0
    GLOBAL_LIST=[]
    name=k["component_name"]
    type="NATURAL-PROGRAM"
    print(name)
    GLOBAL_LIST.append(name)
    callchain(name,type,col,GLOBAL_LIST)
workbook.close()


import pandas

excel_data_df = pandas.read_excel('call_chain.xlsx', sheet_name='call_chain')

json_str = excel_data_df.to_json(orient='records')



# import json
# import copy
# dup_list=copy.deepcopy(json.loads(json_str))
# for l,k in enumerate(json.loads(json_str)):
#     val=k.keys()
#     for i in val:
#         if k[i]==None:
#             print(dup_list[l][i])
#             dup_list[l].update({i:"  "})
#
# print(dup_list)