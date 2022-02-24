from pymongo import MongoClient

client=MongoClient('localhost',27017)

db=client['CRST_FULLV1']

db1=client['CRST']

cursor = db1.keyword_lookup.find({'type': {"$ne": "metadata"}})


# #db1.bre_rules_report.insert_many(cursor)
data=db.keyword_lookup.insert_many(cursor)