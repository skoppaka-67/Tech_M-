# import pymongo
# from pymongo import MongoClient
# from collections import defaultdict
# import pytz
# import datetime
#
# client=MongoClient('localhost', 27017)
# db=client['as400']
#
#
# # map_name= request.args.get('map_name')
# collections= db.cics_field.find({'type':{'$ne':'metadata'}}).sort("_id", pymongo.ASCENDING)
# d=defaultdict(list)
# out_data=[]
# l=[]
# for collection in collections:
#     # d['MAP_NAME']=
#     f_name=collection['field_name'].rstrip().replace(" ", "&nbsp;")
#     x=[collection['position']], f_name, collection['type'], collection['length']
#     d[collection['map_name']].append(x)
#     # print(type(collection['field_name']))
#     l.append(collection['map_name'])
# # print(d)
#
# for k,v in d.items():
#     # if (k == 'ACRV880'):
#         # print()
#     disp = ''
#     x=0
#     y=0
#     dd={}
#     d1=0
#     d2=0
#     add_len=0
#     val=''
#
#     for i in range(len(v)):
#         # if(i==10):
#         #     break
#         # print(k,v[i][0][0], v[i][1],"values",v)
#         if(v[i][1]!=''):
#             try:
#                 # if(v[i][0][0][1]==','):
#                 p1=v[i][0][0].split(',')[0]
#                 p2 = v[i][0][0].split(',')[1]
#                 type= v[i][2]
#                 length=v[i][3]
#                 # print(type)
#                 # print(length)
#                 if(i==0):
#                     x=0
#                 else:
#                     x = int(p1)-int(d1)
#                 if(x>0):
#                     d2=0
#                     y = int(p2) - int(d2)
#                     add_len=0
#                 else:
#                     if(i==0):
#                         y=0
#                     else:
#                         y = int(p2)-int(d2)
#                 # print(type(v[i][1]))
#                 print(v[i][1])
#                 d1=p1
#                 d2=p2
#
#                 # print("postiotion",v[i][0][0][0], v[i][0][0][1])
#                 # print(x,y, v[i][0][0][0], v[i][0][0][1])
#                 # print(p1, p2, x, y, add_len, v[i][1])
#                 disp+=int(x)*'<br>'
#                 if(x==0):
#                     disp+=(int(y)-add_len)*'&nbsp;'
#                     # print(y, add_len)
#                 else:
#                     # print(int(y))
#                     disp+=(int(y)-1)*'&nbsp;'
#
#                 # if (x > 0 and v[i][1] != ''):
#                 #     add_len = len(v[i][1])
#                 #     val = v[i][1]
#                 # else:
#                 #     add_len = len(v[i][1])
#                 #     val += v[i][1]
#                 if(type=='Screen Variable'):
#                     disp+='_'*int(length)
#                     # print(v[i][1])
#                 else:
#                     disp+=v[i][1]
#                 if(type=='Screen Variable'):
#                     add_len=int(length)
#                 elif (type!="Screen Variable" and v[i][1].strip() != ''):
#                     add_len = len(v[i][1])-6*str(v[i][1]).count("&nbsp;")+str(v[i][1]).count("&nbsp;")
#                     print(6*str(v[i][1]).count("&nbsp;"))
#                     # add_len = len(v[i][1])
#                 # print("disp", val, int(y), len(v[i][1]), v[i][1])
#                 # print(disp)
#                 # if(y<0 or len(disp)>70):
#                 #     print("y", len(disp),disp)
#             except Exception as e:
#                 print(e)
#         # print(disp)
#     dd={"MAP_NAME": k, "codeString": disp}
#     out_data.append(dd)
# # print(out_data)
# # print(list(set(l)))
# time_zone = 'Asia/Calcutta'
# tz = pytz.timezone(time_zone)
# try:
#     db.codeString.delete_many({})
# except Exception as e:
#     print('Error while deleting orphan components report:' + str(e))
# try:
#     current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
#     if db.codeString.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
#                                                                 "time_zone": time_zone,
#                                                                 "headers": [ "MAP_NAME","codeString"
#                                                                             ],
#                                                                 }}, upsert=True).acknowledged:
#         print('update metadata sucess')
#     if db.codeString.insert_many(out_data):
#         print('update sucess')
#
# except Exception as e:
#     print('Error while inserting into orphan components:' + str(e))
# # # #
# #     except:
# #         pass
# # x=0
# # y=0
# # disp=''
# #
# #
# #         pos= collection['POS']
# #         if(len(pos)!=1):
# #             # print(x,y)
# #             x = int(pos[0])-x
# #             y = int(pos[1])-y
# #             # print(pos[0], pos[1])
# #             if(y<0):
# #                 y=0
# #             print(x, y)
# #             disp+=int(x)*'<br>'
# #             disp+=int(y)*'&nbsp'
# #             disp+=collection['FIELD_NAME']
# #
# #
# #
# #         else:
# #             disp+=collection['FIELD_NAME']
# # print(disp)
#
#
#
# # input_array=[[1,2,'Comp1'], [1,7,'Comp2'],[2,3,'Comp3']]
# # x=0
# # y=0
# # out_val=''
# # for inp in input_array:
# #     x=inp[0]-x
# #     y=inp[1]-y
# #     out_val+="<br/>"*int(x)
# #     out_val+="&nbsp"*int(y)
# #     out_val+=inp[2]
# #
# # # print(out_val)

import pymongo
from pymongo import MongoClient
from collections import defaultdict
import pytz
import datetime

client=MongoClient('localhost', 27017)
db=client['as400']


# map_name= request.args.get('map_name')
collections= db.cics_field.find({'type':{'$ne':'metadata'}}).sort("_id", pymongo.ASCENDING)
d=defaultdict(list)
out_data=[]
l=[]
for collection in collections:
    # d['MAP_NAME']=
    f_name=collection['field_name'].rstrip().replace(" ", "&nbsp;")
    x=[collection['position']], f_name, collection['type'], collection['length']
    d[collection['map_name']].append(x)
    # print(type(collection['field_name']))
    l.append(collection['map_name'])
print(d)

for k,v in d.items():
    # if (k == 'ACRV880'):
        # print()
    disp = ''
    x=0
    y=0
    dd={}
    d1=0
    d2=0
    add_len=0
    val=''
    print(k)
    for i in range(len(v)):
        # if(i==10):
        #     break
        # print(k,v[i][0][0], v[i][1],"values",v)
        if(v[i][1]!=''):
            try:
                # if(v[i][0][0][1]==','):
                # print(v[i], v[i][0][0])
                p1=v[i][0][0].split(',')[0]
                p2 = v[i][0][0].split(',')[1]
                type= v[i][2]
                length=v[i][3]
                print("position",p1,p2)
                # print(type)
                # print(length)
                if(i==0):
                    x=int(p1)
                    y=int(p2)
                else:
                    x = int(p1)-int(d1)
                if(x>0):
                    d2=0
                    y = int(p2) - int(d2)
                    add_len=0
                else:
                    if(i==0):
                        y=0
                    else:
                        y = int(p2)-int(d2)
                # print(type(v[i][1]))
                # print(x,y)
                d1=p1
                d2=p2

                # print("postiotion",v[i][0][0][0], v[i][0][0][1])
                # print(x,y, v[i][0][0][0], v[i][0][0][1])
                # print(p1, p2, x, y, add_len, v[i][1])
                disp+=int(x)*'<br>'
                if(x==0):
                    disp+=(int(y)-add_len)*'&nbsp;'
                    # print(y, add_len)
                else:
                    # print(int(y))
                    disp+=(int(y)-1)*'&nbsp;'

                # if (x > 0 and v[i][1] != ''):
                #     add_len = len(v[i][1])
                #     val = v[i][1]
                # else:
                #     add_len = len(v[i][1])
                #     val += v[i][1]
                if(type=='Screen Variable'):
                    disp+='_'*int(length)
                    # print(v[i][1])
                else:
                    disp+=v[i][1]
                if(type=='Screen Variable'):
                    add_len=int(length)
                elif (type!="Screen Variable" and v[i][1].strip() != ''):
                    add_len = len(v[i][1])-6*str(v[i][1]).count("&nbsp;")+str(v[i][1]).count("&nbsp;")
                    # print(6*str(v[i][1]).count("&nbsp;"))
                    # add_len = len(v[i][1])
                # print("disp", val, int(y), len(v[i][1]), v[i][1])
                # print(disp)
                # if(y<0 or len(disp)>70):
                #     print("y", len(disp),disp)
            except Exception as e:
                print(e)
        # print(disp)
    dd={"MAP_NAME": k, "codeString": disp}
    out_data.append(dd)
# print(out_data)
# print(list(set(l)))
time_zone = 'Asia/Calcutta'
tz = pytz.timezone(time_zone)
try:
    db.codeString.delete_many({})
except Exception as e:
    print('Error while deleting orphan components report:' + str(e))
try:
    current_time = datetime.datetime.now(tz=tz).strftime("%A, %d. %B %Y %I:%M%p")
    if db.codeString.update_one({"type": "metadata"}, {"$set": {"last_updated_on": current_time,
                                                                "time_zone": time_zone,
                                                                "headers": [ "MAP_NAME","codeString"
                                                                            ],
                                                                }}, upsert=True).acknowledged:
        print('update metadata sucess')
    if db.codeString.insert_many(out_data):
        print('update sucess')

except Exception as e:
    print('Error while inserting into orphan components:' + str(e))
# # #
#     except:
#         pass
# x=0
# y=0
# disp=''
#
#
#         pos= collection['POS']
#         if(len(pos)!=1):
#             # print(x,y)
#             x = int(pos[0])-x
#             y = int(pos[1])-y
#             # print(pos[0], pos[1])
#             if(y<0):
#                 y=0
#             print(x, y)
#             disp+=int(x)*'<br>'
#             disp+=int(y)*'&nbsp'
#             disp+=collection['FIELD_NAME']
#
#
#
#         else:
#             disp+=collection['FIELD_NAME']
# print(disp)



# input_array=[[1,2,'Comp1'], [1,7,'Comp2'],[2,3,'Comp3']]
# x=0
# y=0
# out_val=''
# for inp in input_array:
#     x=inp[0]-x
#     y=inp[1]-y
#     out_val+="<br/>"*int(x)
#     out_val+="&nbsp"*int(y)
#     out_val+=inp[2]
#
# # print(out_val)