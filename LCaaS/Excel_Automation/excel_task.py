import csv
import codecs
from datetime import datetime
import json

file = codecs.open(r'D:\UipathSessionAttendanceList -06 May 21.csv', 'r', 'utf-16')

csvReader = csv.DictReader(file, delimiter='\t')

temp_name = ''
d1 = datetime.now()
d2 = datetime.now()
max_time = '06/05/2021, 5:11:00 PM'
# join_time=int
# left_time=int
METADATA = []
Lis = []
temp_name2 = ''
left = set()
join = set()

s = set()
s2 = set()


for row in csvReader:
    # print(row['Full Name'])
    # print(row)
    temp_name = row['Full Name']
    s.add(row['Full Name'])
    #s2.add(row)

    if temp_name == row['Full Name']:

        # print(temp_name)
        if row['User Action'] == 'Joined' or row['User Action'] == 'Joined before':
            join.add(row['Full Name'])

            join_time = row['Timestamp']
            d1 = datetime.strptime(join_time, "%d/%m/%Y, %H:%M:%S %p")
            # print("join_time"+join_time)

        if row['User Action'] == 'Left':
            left.add(row['Full Name'])

            left_time = row['Timestamp']
            # print("left_time"+left_time)
            d2 = datetime.strptime(left_time, "%d/%m/%Y, %H:%M:%S %p")
            # print(type(d2))
            # main_time=left_time-join_time

            if d2 > d1:
                d = d2 - d1
                duration = d.seconds / 60
                output = {"Name": temp_name,
                          "duration": duration,
                          }

                METADATA.append(output)
    else:
        temp_name = row['Full Name']

h = {}
# METADATA=sorted(METADATA,key=itemgetter('Name'))

# print(json.dumps(METADATA, indent=4))
f = 0
temp_duration = 0.0

for j in s:

    for i in METADATA:

        if j == i['Name']:
            temp_duration = i['duration'] + temp_duration
    if temp_duration == 0.0:


        output = {'Name': j}
        Lis.append(output)
    if temp_duration > 0.0:
        output = {"Name": j,
                  "duration": temp_duration}
        Lis.append(output)
        temp_duration = 0.0

for r in csvReader:
    print(r)
    if r['Full Name'] in join and r['Full Name'] not in left:
        print(r['Full Name'])

# print(left)
print(json.dumps(Lis, indent=4))
#print(s2)
