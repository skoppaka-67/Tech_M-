"""
owner: Bhavya JS
This is the test case for comment report
"""

import comment_line
import unittest
extentions=['.jsp','.java','.css','.js']

class SimpleTest(unittest.TestCase):
     def test_files(self):

         '''This function tests total number of files.'''

         a = comment_line.getallfiles(r'D:\Lcaas_java\Requirements\source_files', extentions)
         self.assertEqual(len(a), 77)


     def test_componenttype(self):

         '''This function tests the extension of given file'''

         b = comment_line.getcomponenttype(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\services\ApartmentInfo.java')
         c=comment_line.getcomponenttype(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\WebContent\css\adminTable.css')
         d=comment_line.getcomponenttype(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\WebContent\aboutus.jsp')
         self.assertEqual(b, 'JAVA_CLASS')
         self.assertEqual(c, 'STYLE_SHEET')
         self.assertEqual(d, 'JAVA_SERVER_PAGE')

     def test_reports(self):
         '''This function tests the output of the given file.'''


         self.assertEqual(comment_line.getallreports(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\services\ApartmentInfo.java'),{

                            "application" : "APARTMENT",
                            "component_type" : "JAVA_CLASS",
                            "component_name" : "ApartmentInfo",
                            "codeString" : "// TODO Auto-generated method stub<br>// TODO Auto-generated catch block<br>// TODO Auto-generated method stub<br>// TODO Auto-generated method stub<br>      // execute the preparedstatement<br>\// TODO Auto-generated method stub<br>// TODO Auto-generated method stub<br>// TODO Auto-generated catch block"
    })
         self.assertEqual(comment_line.getallreports(r'comment_line.getallreports(D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\services\DbConnection.java'),{
                          "application": "APARTMENT",
                          "component_type": "JAVA_CLASS",
                          "component_name": "DbConnection",
                          "codeString": "// TODO Auto-generated method stub<br>// TODO Auto-generated catch block<br>// TODO Auto-generated method stub<br>// TODO Auto-generated method stub<br>      // execute the preparedstatement<br>// TODO Auto-generated method stub<br>// TODO Auto-generated method stub<br>// TODO Auto-generated catch block\n"
         })
         self.assertEqual(comment_line.getallreports(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\servlet\AddApartment.java'),
                         {"application": "APARTMENT",
                            "component_type": "SERVLET",
                            "component_name": "AddApartment",
                            "codeString": "/**<br>* Servlet implementation class AddApartment<br>*/<br>"
                         })

     def test_reportsempty(self):

         """this function checks for comment lines, if not present returns True. """

         self.assertTrue(comment_line.getallreports(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\idealhome\services\IdealHomeDAO.java'))
         self.assertTrue(comment_line.getallreports(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\idealhome\services\IIdealHome.java'))
         self.assertTrue(comment_line.getallreports(r'D:\Lcaas_java\comments\no comment.java'))


if __name__ == '__main__':
        unittest.main()