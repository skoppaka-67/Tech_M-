from datetime import datetime
from flask import Flask, jsonify, request
from elasticsearch import Elasticsearch
from tqdm import tqdm
from pymongo import MongoClient

client = MongoClient('localhost', 27017)
db = client["CRST_FULLDB"]
col = db["varimpactcodebase"]

es = Elasticsearch()

app = Flask(__name__)

# @app.route('/', methods=['GET'])
# def index():
#     results = es.get(index='contents', doc_type='title', id='my-new-slug')
#     return jsonify(results['_source'])
#
#

def insert_data():


    for data in tqdm(col.find(), total=col.count()):
        data.pop('_id')

        action = {
            "_index": "screenfields",
            "_type": "data",
            "_source": data
        }

        es.index(index = "screenfields1", doc_type = "data", body = data)



insert_data()
# @app.route('/search', methods=['POST'])
# def search():
#     keyword = request.form['keyword']
#
#     body = {
#         "query": {
#             "multi_match": {
#                 "query": keyword,
#                 "fields": ["content", "title"]
#             }
#         }
#     }
#
#     res = es.search(index="contents", doc_type="title", body=body)
#
#     return jsonify(res['hits']['hits'])
#
# app.run(port=5000, debug=True)