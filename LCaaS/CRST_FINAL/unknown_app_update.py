from pymongo import MongoClient
import pandas as pd
client = MongoClient('localhost', 27017)
db = client['CRST_FULLV1']


# db.master_inventory_report.update_many({"component_type":"COBOL"},{"$set":{"application":"CRST"}})


# db.cross_reference_report.update_many({"component_type":"COBOL"},{"$set":{"calling_app_name":"Unknown"}})
# db.cross_reference_report.update_many({"component_type":"COBOL"},{"$set":{"called_app_name":"Unknown"}})


# db.crud_report.update_many({"component_type":"COBOL"},{"$set":{"calling_app_name":"Unknown"}})

# db.orphan_report.update_many({"component_type":"COPYBOOK"},{"$set":{"application":"Unknown"}})

# db.missing_components_report.update_many({"component_type":"COBOL"},{"$set":{"application":"Unknown"}})

db.cobol_output.update_many({"component_type":"COBOL"},{"$set":{"application":"CRST"}})

# db.drop_impact.update_many({"drop_impact_type":"FILE"},{"$set":{"application":"Unknown"}})