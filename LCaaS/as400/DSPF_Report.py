import os, glob,json,re
from pymongo import MongoClient
import datetime
import pytz
client= MongoClient('localhost', 27017)
db=client['as400']
OUTPUT=[]
METADATA=[]
for files in glob.glob(r"D:\AS400\DSPF\*.DSPF"):
    lines=open(files, encoding="utf-8").readlines()
    d={}
    d['BMS_NAME'.lower()]=''
    d['MAPSET_NAME'.lower()]=''
    d['MAP_NAME'.lower()]=''
    d['LENGTH'.lower()]=''
    d['TYPE'.lower()]= ''
    d['Access_Mode'.lower()]=''
    d['FIELD_NAME'.lower()]=''
    d['position'.lower()]='',''
    flag = 0
    for line in lines:
        try:
            if(line!='' and line[5]=='A' and line[6]!='*'):
                # print(line)
                qflag=0
                eflag=0
                d['BMS_NAME'.lower()]= files.split("\\")[-1].split('.')[0]
                d['MAPSET_NAME'.lower()]= d['BMS_NAME'.lower()].split('.')[0]
                # print("16th position", line[16])
                if(line[16]=='R'):
                    xy= line[16:].split()[1]
                    # print(d['MAP_NAME'])
                    flag=1
                if(flag==1):
                    d['MAP_NAME'.lower()] = xy
                    # print("lines",line[40:])
                    if(line[32]!=' ' or line[33]!=' '):
                        s= line[32:].split()[0]
                        d['LENGTH'.lower()] = re.sub(r'[A-Z]+', '', s, re.I)
                        s=''

                    else:
                        d['LENGTH'.lower()]=''
                    # print('length', d['LENGTH'])
                    if (line[37] != ' '):
                        if(line[37]=='B'):
                            d['Access_Mode'.lower()] = "INPUT/OUTPUT"
                        if (line[37] == 'H'):
                            d['Access_Mode'.lower()] = "HIDDEN"
                        if (line[37] == 'I'.lower()):
                            d['Access_Mode'.lower()] = "INPUT"
                        if (line[37] == 'O'):
                            d['Access_Mode'.lower()] = "OUTPUT"
                        # print(d['Access_Mode'])
                    else:
                        d['Access_Mode'.lower()] = ''
                    if (line[18] != ' ' and line[16]!='R'):
                        fname=line[18:].split()[0]
                        # print(fname)
                        d['FIELD_NAME'.lower()] = fname

                        # print("field name",d['FIELD_NAME'])

                    if(line[39:].strip()==''):
                        d["TYPE".lower()]='Screen Variable'
                        d['position'.lower()]=''
                        eflag=1
                        METADATA.append(d)
                        d={}
                    elif(line[40]!=' ' or line[39]!= ' '):
                        # print(line)
                        p1= line[39:].split()[0]

                        # if(type(line[39:].split()[1][0:2]) == int):
                        x=line[39:].split()[1][0:2]
                        if(x.__contains__("'")):
                            # print("fetching line")
                            d['TYPE'.lower()]= "Screen Literal"
                            d['FIELD_NAME'.lower()]=line[39:].split("'")[1]
                            qflag=1


                        else:
                            d['TYPE'.lower()]= "Screen Variable"
                        p2 = x.replace("'", '')
                        if(p2[-1].isalpha()):
                            # print("p2",p2)
                            p2=p2[0:len(p2)-2]
                            # print(p2)

                        d['position']=p1+","+p2
                        # print(d)
                        if(qflag==1):
                            # print(d)
                            METADATA.append(d)
                            d={}

                        # elif(type(line[39:].split()[1][0])==int):
                        #     d['POS2']= line[39:].split()[1][0]
                        # print(d['POS1'], d['POS2'])
                    else:
                        # print("going inside else")
                        d['TYPE'.lower()]=''
                        d['position']=''
                    if( line[16]!='R'):
                        d['FIELD_NAME'.lower()] = fname
                        d['position'] = ''
                    # print(line)
                    # print(d)
                    if(d['position']!='' and d['LENGTH'.lower()]!=[''] and d['Access_Mode'.lower()]!='' and eflag!=1):
                        METADATA.append(d)
                        d={}

            print(METADATA)
        except Exception as e:
            # print("Exception line",line,e)
            pass


time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)
try:
    db.cics_field.delete_many({})
except Exception as e:
    print('Error while deleting orphan components report:'+str(e))
try:
    current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
    if db.cics_field.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                   "time_zone": time_zone,
                                                                   "headers": ["BMS_NAME".lower(), "MAPSET_NAME".lower(), "MAP_NAME".lower(), "FIELD_NAME".lower(), "TYPE".lower(), "position".lower(), "LENGTH".lower(), "Access_Mode".lower()],
                                                                   }}, upsert=True).acknowledged:
        print('update metadata sucess')
    if db.cics_field.insert_many(METADATA):
        print('update sucess')

except Exception as e:
    print('Error while inserting into orphan components:'+str(e))


