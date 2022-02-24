import config
import os ,re
import requests
code_location=config.codebase_information['code_location']

pub_func = "public function"
pub_share = "public shared"
pub_sub = "public sub"
private_sub = "private sub"
private_share = "private shared"
private_func = "private function"
friend_func = "friend function"
friend_sub = "friend sub"
import copy
global ProgramflowList
ProgramflowList=[]
pgm_list=[]
paradict={}
def main(filename):
    print(filename)
    pgm_list.append(filename.split('\\')[-1])
    para_name_list=[]
    input_list=[]
    with open(filename) as input_file:

        for line in input_file:
            if line.strip().startswith("'") or line.strip()=="":
                continue
            input_list.append(line)
            if re.search(pub_func,line,re.IGNORECASE) or \
                re.search(friend_func,line,re.IGNORECASE) or \
                re.search(private_func,line,re.IGNORECASE) or \
                re.search(private_share,line,re.IGNORECASE) or \
                re.search(pub_sub,line,re.IGNORECASE) or \
                re.search(private_sub,line,re.IGNORECASE) or \
                re.search(pub_share,line,re.IGNORECASE) or \
                     re.search(friend_sub,line,re.IGNORECASE) :

                if line.rstrip().endswith(")") or line.__contains__(")") or line.__contains__("("):
                    para_name_collection = line.split("(")
                    para_name_list.append( para_name_collection[0].split()[-1])

    input_file.close()
    function_call(input_list,para_name_list)

def function_call(input_list,para_name_list):
    flow_dict={}
    para_name=""
    para_list=[]
    count=0
    global total_executed_para_list
    total_executed_para_list=[]
    global master_alive
    master_alive= set()
    global master_dead
    master_dead=set()
    for function_line in input_list:
        if re.search(pub_func, function_line, re.IGNORECASE) or \
                re.search(friend_func, function_line, re.IGNORECASE) or \
                re.search(private_func, function_line, re.IGNORECASE) or \
                re.search(private_share, function_line, re.IGNORECASE) or \
                re.search(pub_sub, function_line, re.IGNORECASE) or \
                re.search(private_sub, function_line, re.IGNORECASE) or \
                re.search(pub_share, function_line, re.IGNORECASE) or\
                re.search(friend_sub,function_line,re.IGNORECASE):
            if function_line.rstrip().endswith(")") or function_line.__contains__(")") or function_line.__contains__('('):
                para_name_collection = function_line.split("(")
                para_name =para_name_collection[0].split()[-1]
            if count!=0:
                flow_dict[previous_para_name]=para_list
                para_list=[]
                previous_para_name=para_name
            else:
                previous_para_name=para_name
            count=count+1
        else:
            matches = [x for x in para_name_list if ' '+x+'(' in function_line]
            if matches!=[]:
                total_executed_para_list.append(matches[0])
                para_list.append(matches[0])
    flow_dict[para_name]=para_list


    # for data2 in flow_dict:
    #      paravalue=flow_dict.get(data2)
    #      if paravalue!=[]:
    #          master_alive.add(data2)
    #          break
    #
    # for elemente in paravalue:
    #     findAliveChildren(elemente,flow_dict)
    # for elements1 in paravalue:
    #     master_alive.add(elements1)
    # notalivepara=[]
    # for item in para_name_list:
    #     if item in master_alive:
    #         continue
    #     else:
    #         notalivepara.append(item)
    # master_alive.clear()
    # for alivepara1 in notalivepara:
    #
    #     try:
    #         del flow_dict[alivepara1]
    #     except KeyError:
    #         continue

    print(flow_dict)
    # Add first para name
    # for val in para_name_list:
    #
    #     if flow_dict[val] ==[]:
    #         total_executed_para_list.append(val)
    #     else:
    #         total_executed_para_list.append(val)
    #         break
    #
    # flow_dict_1=copy.deepcopy(flow_dict)
    #
    #
    # dead_para_list=set(para_name_list)-set(total_executed_para_list)
    #
    # print("dead",dead_para_list)
    #
    #
    # for data in dead_para_list:
    #     Deadchildern(data,flow_dict)
    #
    # print("mastrer,",master_dead)
    #
    # for alivepara1 in dead_para_list:
    #     try:
    #         del flow_dict[alivepara1]
    #     except KeyError:
    #         continue
    #
    # for elemente in total_executed_para_list:
    #     findAliveChildren(elemente,flow_dict)
    #
    # # for data2 in dead_para_list:
    # #     try:
    # #         del flow_dict[data2]
    # #     except Exception as e:
    # #         print(e)
    #
    # # adding first para
    # for data2 in flow_dict:
    #     paravalue = flow_dict.get(data2)
    #     if paravalue != []:
    #         master_alive.add(data2)
    #         break
    # print("gg",master_alive)
    # print(para_name_list)
    # value= set(para_name_list) - master_alive
    # print(value)
    # for alivepara1 in dead_para_list:
    #     try:
    #         del flow_dict[alivepara1]
    #     except KeyError:
    #         continue
    #
    # first_value_list=[]
    # for k in flow_dict:
    #     first_value_list.append(flow_dict[k])
    # first_value_list_1=set()
    # for j in first_value_list:
    #     for k in j:first_value_list_1.add(k) # value from alive paras
    #
    # #first_value_list_1.update(master_alive)
    #
    # print("full",first_value_list_1)
    # master_alive.clear()
    #
    # # dead paras value
    #
    # for element in dead_para_list:
    #     findAliveChildren(element,flow_dict_1)
    # master_alive.update(dead_para_list)
    #
    # print("dead",type(dead_para_list),master_alive)
    #
    # common_values=first_value_list_1.intersection(master_alive)
    #
    # print("comomo",common_values)
    #
    # unique_values=master_alive - common_values
    #
    # print("qui",unique_values)
    #
    # unique_values.update(dead_para_list)
    # for alivepara1 in unique_values:
    #     try:
    #         del flow_dict_1[alivepara1]
    #     except KeyError:
    #         continue
    # print(flow_dict_1)
    flowData(flow_dict)

def flowData(flow_dict):
    import copy
    Keys=['from','to','name']
    Values=[]
    Newlist=[]
    Dict={}

    for Key in (flow_dict):
        for item in flow_dict[Key]:
           Values.append(Key)
           Values.append(item)
           Values.append(Key)
           templist = Values.copy()
           for i in range(len(Keys)):
              Dict[Keys[i]] = templist[i]
           newdict=copy.deepcopy(Dict)
           Newlist.append(newdict)
           Dict.clear()
           Values.clear()
    templist1 = Newlist.copy()
    ProgramflowList.append(templist1)
    Newlist.clear()

def findAliveChildren(ele,flow_dict):

   try:
    if flow_dict[ele] == []:
        master_alive.add(ele)
        return
    else:
        for item in flow_dict[ele]:
            if item in master_alive:
                continue
            else:
                 master_alive.add(item)
                 findAliveChildren(item,flow_dict)
   except KeyError :
       return

def Deadchildern(ele, flow_dict):

       try:
           if flow_dict[ele] == []:
               master_dead.add(ele)
               return
           else:
               for item in flow_dict[ele]:
                   if item in master_dead:
                       continue
                   else:
                       master_dead.add(item)
                       Deadchildern(item, flow_dict)
       except KeyError:
           return

for path, subdirs, files in os.walk(code_location):
    for name in files:
        filename = os.path.join(path, name)
        if filename.split("\\")[-1].split('.')[-1].upper() =="VB":
           main(filename)

for i in range(len(pgm_list)):
    paradict[pgm_list[i]]=ProgramflowList[i]


r = requests.post('http://localhost:5000/api/v1/update/procedureFlow',json={"data":paradict})
print(r.status_code)
print(r.text)