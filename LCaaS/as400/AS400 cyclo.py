import glob,os,re,requests
import pandas as pd
import xlsxwriter
from pymongo import MongoClient
import config1

jsondict = {}
Dict = {}
client = MongoClient(config1.database['mongo_endpoint_url'])
db = client[config1.database['database_name']]

# client = MongoClient('localhost', 27017)
# db = client['as400']


from collections import OrderedDict
RPG_Path ="D:\AS400\RPG"
CL_Path = 'D:\AS400\CL'
str1=" "
payload = {}
METADATA =[]
CCData=[]
dou_counts = 0
dow_counts = 0
do_counts = 0
if_counts = 0
ifne_counts = 0
ifle_counts = 0
ifgt_counts = 0
ifge_counts = 0
ifeq_counts = 0
iflt_counts = 0
cas_counts = 0
caseq_counts = 0
casge_counts = 0
casgt_counts = 0
casle_counts = 0
caslt_counts = 0
casne_counts = 0
cab_counts = 0
cabeq_counts = 0
cabge_counts = 0
cabgt_counts = 0
cable_counts = 0
cablt_counts = 0
cabne_counts = 0
when_counts = 0
all_if_counts = 0
exsr_counts = 0
goto_counts = 0
for_counts = 0
all_do_counts = 0
all_cas_counts = 0
all_cab_counts = 0




#db.cross_reference_report.remove()

Select = False
Modulename = ""

for filename in glob.glob(os.path.join(RPG_Path,'*.RPG')):
    ModuleName = filename


    f = open(ModuleName, "r")
    #print(ModuleName)

    r = 0
    CCData = []
    when_counts = 0
    all_if_counts = 0
    exsr_counts = 0
    goto_counts = 0
    for_counts = 0
    all_do_counts = 0
    all_cas_counts = 0
    all_cab_counts = 0
    if_counts = 0
    ifne_counts = 0
    ifle_counts = 0
    ifgt_counts = 0
    ifge_counts = 0
    ifeq_counts = 0
    iflt_counts = 0
    dou_counts = 0
    dow_counts = 0
    do_counts = 0
    cas_counts = 0
    caseq_counts = 0
    casge_counts = 0
    casgt_counts = 0
    casle_counts = 0
    caslt_counts = 0
    casne_counts = 0
    cab_counts = 0
    cabeq_counts = 0
    cabge_counts = 0
    cabgt_counts = 0
    cable_counts = 0
    cablt_counts = 0
    cabne_counts = 0






    for data in f:


        if len(data) > 7:

            #data = data[5:72]


            if data[6] == '*' or re.search("//", data) or data[5] == 'd' or data[5] == 'f':

                # print(data)
                continue
            else:

                Select_Rex = re.findall(r'^.*\sselect.*', data.casefold())
                End_Select_Rex = re.findall(r'^.*\sends1.*', data.casefold())
                #print(Select_Rex)
                if (Select_Rex != []):
                    Select = True
                    #print(data)

                if (Select):
                    When_Select = re.findall(r'^.*\swhen.*', data.casefold())
                    if (When_Select != []):
                        when_counts = when_counts + 1
                        continue

                if (End_Select_Rex != []):
                    Select = False

                if re.search(r' if', data.casefold()):
                    if_counts = if_counts + 1
                elif re.search(r' ifeq', data.casefold()):
                    ifeq_counts = ifeq_counts + 1
                elif re.search(r' ifgt', data.casefold()):
                    ifgt_counts = if_counts + 1
                elif re.search(r' ifge', data.casefold()):
                    ifge_counts = ifge_counts+1
                elif re.search(r' iflt', data.casefold()):
                    iflt_counts = iflt_counts+1
                elif re.search(r' ifle', data.casefold()):
                    ifle_counts = ifle_counts+1
                elif re.search(r' ifne', data.casefold()):
                    ifne_counts = ifne_counts+1

                all_if_counts = if_counts+ifeq_counts+ifgt_counts+ifge_counts+iflt_counts+ifle_counts+ifne_counts
                #print(all_if_counts)


                # Exsr_Rex = re.findall(r'^.*\sexsr', data.casefold())
                # if (Exsr_Rex != []):
                #     exsr_counts = exsr_counts + 1
                #     #print(exsr_counts)
                #     continue

                Goto_Rex = re.findall(r'^.*\sgoto', data.casefold())
                if (Goto_Rex != []):
                    goto_counts = goto_counts + 1
                    continue

                For_Rex = re.findall(r'^.*\sfor', data.casefold())
                if (For_Rex != []):
                    for_counts = for_counts + 1
                    continue

                if re.search(r' do ', data.casefold()):
                    do_counts_counts = do_counts + 1
                elif re.search(r' dou', data.casefold()):
                    dou_counts = dou_counts + 1
                elif re.search(r' dow', data.casefold()):
                    dow_counts = dow_counts + 1

                all_do_counts = do_counts + dou_counts + dow_counts
                #print(all_do_counts)


                if re.search(r' cas  ', data.casefold()):
                    cas_counts = cas_counts + 1
                elif re.search(r' caseq', data.casefold()):
                    caseq_counts = caseq_counts + 1
                elif re.search(r' casgt', data.casefold()):
                    casgt_counts = casgt_counts + 1
                elif re.search(r' casge', data.casefold()):
                    casge_counts = casge_counts+1
                elif re.search(r' caslt', data.casefold()):
                    caslt_counts = caslt_counts+1
                elif re.search(r' casle', data.casefold()):
                    casle_counts = casle_counts+1
                elif re.search(r' casne', data.casefold()):
                    casne_counts = casne_counts+1

                all_cas_counts = cas_counts+caseq_counts+casgt_counts+casge_counts+caslt_counts+casle_counts+casne_counts


                if re.search(r' cab  ', data.casefold()):
                    cab_counts = cab_counts + 1
                elif re.search(r' cabeq', data.casefold()):
                    cabeq_counts = cabeq_counts + 1
                elif re.search(r' cabgt', data.casefold()):
                    cabgt_counts = cabgt_counts + 1
                elif re.search(r' cabge', data.casefold()):
                    cabge_counts = cabge_counts+1
                elif re.search(r' cablt', data.casefold()):
                    cablt_counts = cablt_counts+1
                elif re.search(r' cable', data.casefold()):
                    cable_counts = cable_counts+1
                elif re.search(r' cabne', data.casefold()):
                    cabne_counts = cabne_counts+1

        all_cab_counts = cab_counts + cabeq_counts + cabgt_counts + cabge_counts + cablt_counts + cable_counts + cabne_counts


    r = when_counts+all_if_counts+exsr_counts+goto_counts+for_counts+all_do_counts+all_cas_counts+all_cab_counts
    #print(all_if_counts)
    CCData.append(r + 1)
    res = int("".join(map(str, CCData)))
    #print(res)
#print(ModuleName,CCData)

    # jsondict["data"] = Dict
    # print(CCData)

    METADATA.append({'component_name': ModuleName.strip("D:\AS400").strip("RPG").replace(" ","_"),
                                                     'component_type': 'RPG',
                                                     'cyclomatic_complexity':res})
#print(METADATA)

    payload = ({"component_name": ModuleName.strip(RPG_Path).strip(".RPG").replace(" ","_")},
     {"$set": {"cyclomatic_complexity": res}})
    print(payload)
    db.master_inventory_report.update_one(*payload)


res = 0
CLModuleName = ""
for filename in glob.glob(os.path.join(CL_Path,'*.CL')):
    CLModuleName = filename
   # print(CLModuleName)
    f = open(CLModuleName, "r")
    cl_if_counts = 0
    r = 0
    CCData.clear()

    for data in f:
        DATA_LIST = data.split()
        if len(DATA_LIST) > 1:

            if DATA_LIST[0].__contains__('/*') and DATA_LIST[-1].__contains__('*/'):
                #print(DATA_LIST)
                continue

            else:
                 #print(DATA_LIST)

                 lines = ' '.join(str(e) for e in DATA_LIST)
                 #print(lines)
                 if re.search('if\s.*', lines.casefold()):
                     cl_if_counts = cl_if_counts + 1

    r = cl_if_counts
    #print(cl_if_counts)
    CCData.append(r + 1)
    res = int("".join(map(str, CCData)))
    #print(res)
#print(CLModuleName,CCData)

    METADATA.append({'component_name': CLModuleName.strip("D:\AS400").strip("CL").replace(" ","_"),
                                                     'component_type': 'CL',
                                                     'cyclomatic_complexity':res})

    payload = ({"component_name": CLModuleName.strip(CL_Path).strip(".CL").replace(" ","_")},
     {"$set": {"cyclomatic_complexity":res}})
    #print(payload)
    db.master_inventory_report.update_one(*payload)
    print(payload)
