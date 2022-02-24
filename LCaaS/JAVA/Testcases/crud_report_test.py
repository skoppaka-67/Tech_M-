"""
owner: Bhavya JS
This is the test case for crud report
"""

import crud_report
import unittest
extentions=['.jsp','.java','.css','.js']

class SimpleTest(unittest.TestCase):
     def test_crud(self):

         """This function tests the identify crud function for given line """

         self.assertEqual(crud_report.identifyCRUD("SELECT * FROM apartment WHERE userID = ?"),
                          "READ")
         self.assertEqual(crud_report.identifyCRUD("UPDATE users SET firstname  ?, lastname = ?, email = ?, country = ?, password = ? += WHERE userID = ?"),
                          "UPDATE")
         self.assertEqual(crud_report.identifyCRUD("DELETE FROM idealhome WHERE sId = ?"), "DELETE")
         self.assertEqual(crud_report.identifyCRUD("insert into users(firstname, lastname, email, country, password) values(?,?,?,?,?)"),
                          "CREATE")

     def test_tablename(self):

         """ This function tets the tablename function of the report. It checks
         whether the crud opertaion is correct for given sql """

         self.assertEqual(crud_report.tablename("SELECT * FROM apartment WHERE userID = ?"),"apartment")
         self.assertEqual(crud_report.tablename("UPDATE users SET firstname  ?, lastname = ?, email = ?, country = ?, password = ? += WHERE userID = ?"), "users")
         self.assertEqual(crud_report.tablename("DELETE FROM idealhome WHERE sId = ?"), "idealhome")
         self.assertEqual(crud_report.tablename("insert into users(firstname, lastname, email, country, password) values(?,?,?,?,?)"), "users")

     def test_dao(self):

         """ This function test the dao files function and chekcks the json """

         self.assertEqual(crud_report.dao_files("D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\user\userDAO.java"),
                          {"component_name" : "userDAO",
                            "component_type" : "DATA_ACCESS_OBJECT",
                            "function_name" : "insert",
                            "SQL" : " insert into users(firstname, lastname, email, country, password) values(?,?,?,?,?)",
                            "CRUD" : "CREATE",
                            "Table_name" : "users"})
         self.assertEqual(crud_report.dao_files("D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\userValidation\loginValidDAO.java"),
                          {
                            "component_name" : "loginValidDAO",
                            "component_type" : "DATA_ACCESS_OBJECT",
                            "function_name" : "getFirstname",
                            "SQL" : "select email, password, firstname, userID from users",
                            "CRUD" : "READ",
                            "Table_name" : "users"})
         self.assertEqual(crud_report.dao_files("D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\userOperation\userAccountDAO.java"),
                          {"component_name" : "userAccountDAO",
                            "component_type" : "DATA_ACCESS_OBJECT",
                            "function_name" : "displayhouse",
                            "SQL" : "SELECT * FROM house WHERE userID = ?",
                            "CRUD" : "READ",
                            "Table_name" : "house"})


if __name__ == '__main__':
    unittest.main()