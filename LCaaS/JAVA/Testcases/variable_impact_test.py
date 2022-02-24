"""
owner: Bhavya JS
This is the test case for variable impact report
"""

import variable_imapact
import unittest
extentions=['.jsp','.java','.css','.js']

class SimpleTest(unittest.TestCase):
    def test_files(self):

        '''This function tests total number of files.'''

        a=variable_imapact.getallfiles(r'D:\Lcaas_java\Requirements\source_files',extentions)
        self.assertEqual(len(a),47)

    def test_componenttype(self):

        '''This function tests the extension of given file'''

        b=variable_imapact.getcomponenttype(r'Requirements\source_files\src\AdminLogin.java')
        c = variable_imapact.getcomponenttype(r'Requirements\source_files\src\jsp\admin.jsp')
        d = variable_imapact.getcomponenttype(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\WebContent\css\adminTable.css')
        self.assertEqual(c, "JAVA_SERVER_PAGE")
        self.assertEqual(b,'JAVA_CLASS')
        self.assertEqual(d, 'STYLE_SHEET')


    def test_reports(self):

       '''This function tests the output of the given file.'''

       self.assertEqual(variable_imapact.getallreports(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\services\ApartmentInfo.java'),{
               "component_name" : "ApartmentInfo",
               "component_type" : "JAVA_CLASS",
               "sourcestatements" : "package com.masterofproperty.apartment.services;"})
       self.assertEqual(variable_imapact.getallreports(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\services\ApartmentInfo.java'), {
               "component_name" : "ApartmentInfo",
               "component_type" : "JAVA_CLASS",
               "sourcestatements" : "import java.sql.Connection;"})
       self.assertEqual(variable_imapact.getallreports(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\services\DbConnection.java'),{
               "component_name": "DbConnection",
               "component_type": "JAVA_CLASS",
               "sourcestatements": "package com.masterofproperty.apartment.services;"
       })
       self.assertTrue(variable_imapact.getallreports(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\servlet'))


if __name__ == '__main__':
   unittest.main()