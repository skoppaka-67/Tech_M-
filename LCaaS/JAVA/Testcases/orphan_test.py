
"""
owner: Bhavya JS
This is the test case for orphan report
"""
import orphan_report
import unittest
extentions=['.jsp','.java','.css','.js']
class SimpleTest(unittest.TestCase):
     def test_orphan(self):

         """This function tests the reports from the orphan report database."""

         self.assertEqual(orphan_report.orphanreport_json(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\servlet\updateApartment.java'),{
             "called_name": "updateApartment.java",
             "called_type": "SERVLET",
             "called_app_name": "APARTMENT"
         })
         self.assertEqual(orphan_report.orphanreport_json(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\servlet\adminAddApartment.java'),{
             "called_name": "adminAddApartment.java",
             "called_type": "SERVLET",
             "called_app_name": "APARTMENT"
         })
         self.assertEqual(orphan_report.orphanreport_json(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\servlet\AddApartment.java'),{
             "called_name": "AddApartment.java",
             "called_type": "SERVLET",
             "called_app_name": "APARTMENT"
         })
         self.assertEqual(orphan_report.orphanreport_json(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\servlet\update.java'),{
             "called_name": "update.java",
             "called_type": "SERVLET",
             "called_app_name": "HOUSE"
         })
         self.assertEqual(orphan_report.orphanreport_json(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\model\ModelApartment.java'),{
             "called_name": "ModelApartment.java",
             "called_type": "JAVA_CLASS",
             "called_app_name": "MODEL"
         })

if __name__ == '__main__':
        unittest.main()