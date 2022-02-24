
import pymongo

class Database:

    # def __init__(self,db_name,col_name):
    #     self.db_name = db_name
    #     self.col_name = col_name

        # self.Db_conn(self.db_name,self.col_name)
    @staticmethod
    def Db_conn(db_name, col_name):
        conn = pymongo.MongoClient("localhost", 27017)
        return conn[db_name][col_name]

    def db_update(self, db_name, col_name, Metadata):

        cursy = self.Db_conn(db_name, col_name)

        try:
            cursy.insert_many(Metadata)
            print(db_name, col_name, "Created and inserted")

        except Exception as e:
            print("Error:", db_name, col_name, e)

    def db_delete(self, db_name, col_name):
        cursy = self.Db_conn(db_name, col_name)
        try:
            cursy.delete_many({})
            print(db_name, col_name, "Deleted")

        except Exception as e:
            print("Error:", db_name, col_name, e)

    @staticmethod
    def fetch_db_cursor_to_list(cursor):
        data_list = []
        for js_bre_data_iter in cursor:
            data_list.append(js_bre_data_iter)
        return data_list
