# -*- coding: utf-8 -*-
"""
@author: naveen
"""

try:
    import os
    import sys
    
    import elasticsearch
    from elasticsearch import Elasticsearch
    import pandas as pd
    
    print("All Modules Loaded ! ")
except Exception as e:
    print("Some Modules are Missing {}".format(e))
    
def connect_elasticsearch():
    es = None
    es = Elasticsearch([{'host': 'localhost', 'port': 9200}])
    if es.ping():
        print('Yupiee  Connected ')
    else:
        print('Awww it could not connect!')
    return es
es = connect_elasticsearch()

es.indices.create(index='person', ignore=400)


res =  es.indices.get_alias("*")
for Name in res:
    print(Name)
    
e1={
    "first_name":"Soumil",
    "last_name":"Shah",
    "age": 24,
    "about": "Full stack Software Developers ",
    "interests": ['Youtube','music'],
}

e2={
    "first_name":"nitin",
    "last_name":"Shah",
    "age": 58,
    "about": "Soumil father ",
    "interests": ['Stock','Relax'],
}

res1 = es.index(index='person',doc_type='people', body=e1)
res2 = es.index(index='person',doc_type='people', body=e2)

query={"query" : {
        "match_all" : {}
    }}

res = es.search(index="person", body=query, size=1000)











    