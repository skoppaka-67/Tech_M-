import csv, json,codecs,copy
from datetime import datetime
import pprint

max_time = '06/05/2021, 5:11:00 PM'
METADATA = []
filepath = r'D:\UipathSessionAttendanceList -06 May 21.csv'

file = codecs.open(filepath, 'r', 'utf-16')

csvReader = csv.DictReader(file, delimiter='\t')

def time_calculator(name,max_time):
    cad_container = {}
    time_Spent =0
    cad_container['Full Name'] = name
    cad_container['join'] = []
    cad_container['left'] = []

    file1 = codecs.open(filepath, 'r', 'utf-16')

    csvReader1 = csv.DictReader(file1, delimiter='\t')

    for row in csvReader1:
        if row['Full Name'] == name and (row['User Action'] == 'Joined' or row['User Action'] == 'Joined before'):
            join_time = row['Timestamp']
            d1 = datetime.strptime(join_time, "%d/%m/%Y, %H:%M:%S %p")
            cad_container['join'].append(d1)

        if row['Full Name'] == name and row['User Action'] == 'Left':
            left_time = row['Timestamp']
            l1 = datetime.strptime(left_time, "%d/%m/%Y, %H:%M:%S %p")
            cad_container['left'].append(l1)

    if len(cad_container['left']) < len(cad_container['join']):
        left_time = max_time
        l1 = datetime.strptime(left_time, "%d/%m/%Y, %H:%M:%S %p")
        cad_container['left'].append(l1)

    for index in range(0,len(cad_container['join'])):

        time_Spent = (cad_container['left'][index]-cad_container['join'][index]).seconds/60 + time_Spent

    return time_Spent

for row in csvReader:


    if row['User Action'] == 'Joined' or row['User Action'] == 'Joined before':
        cand_name = row['Full Name']
        time = time_calculator(cand_name,max_time)
        output_dict ={
            'Full Name': cand_name,
            "time_spent_in_call": time
        }
        if output_dict not  in METADATA:
            METADATA.append(copy.deepcopy(output_dict))
            output_dict.clear()
        output_dict.clear()


print(json.dumps(METADATA,indent=4))


