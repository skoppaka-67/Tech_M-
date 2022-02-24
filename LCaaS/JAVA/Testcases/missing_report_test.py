"""
owner: Bhavya JS
This is the test case for missing component report
"""

import missingreport
import unittest
extentions=['.jsp','.java','.css','.js']
class SimpleTest(unittest.TestCase):
     def test_missingrepot(self):

         """This function tests the reports from the missing component report database."""

         self.assertEqual(missingreport.Missingreport_json(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\servlet\adminAddApartment.java'),{
             "component_name": "adminAddApartment.java",
             "component_type": "SERVLET"
         })
         self.assertEqual(missingreport.Missingreport_json(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\servlet\AddApartment.java'),{
             "component_name": "AddApartment.java",
             "component_type": "SERVLET"
         })
         self.assertEqual(missingreport.Missingreport_json(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\land\servlet\insert.java'),{
             "component_name": "insert.java",
             "component_type": "SERVLET"
         })
         self.assertEqual(missingreport.Missingreport_json(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\land\servlet\admininsert.java'),{
             "component_name": "admininsert.java",
             "component_type": "SERVLET"
         })
         self.assertEqual(missingreport.Missingreport_json(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\model\House.java'),{
             "component_name": "House.java",
             "component_type": "JAVA_CLASS"
         })

if __name__ == '__main__':
        unittest.main()