# -*- coding: utf-8 -*-
"""
@author: naveen
"""
from tqdm import tqdm
from pymongo import MongoClient

client = MongoClient('localhost', 27017)
db = client["CRST_FULLDB"]
col = db["varimpactcodebase"]

from flask import Flask, jsonify, request

app = Flask(__name__)

from elasticsearch import Elasticsearch
from elasticsearch.helpers import bulk

es = Elasticsearch([{'host': 'localhost', 'port': 9200}])

print(col.count())

# Pull from mongo and dump into ES using bulk API
actions = []
for data in tqdm(col.find(), total=col.count()):
    data.pop('_id')

    action = {
        "_index": "screenfields",
        "_type": "data",
        "_source": data
    }
    actions.append(action)

# delete = es1.indices.delete(index = 'light')
request_body = {
    "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 0
    }
}

bulk(es, actions, index='screenfields')




@app.route('/query')
def Query():
    a = es.search(index='screenfields', body={},timeout=100)
    return jsonify(query=a)


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5001)
