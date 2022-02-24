"""
Test Cases for master inventory report
Dependencies: master inventory file and config file
"""


import unittest
import master_inventory
import config

test_path=config.test_path
extensions=config.extensions

class master_inv_test(unittest.TestCase):
    def test_allfiles(self):
        """
        1.This test case is for getallfiles function in glossary file.
        2.Here we are testing whether all the files in directories are accessing or not
        :return: will return test case passed if all the files in the directory equals to return value of get all files function output
        """
        res=master_inventory.get_files(test_path,extensions)
        self.assertEqual(res,['D:\\Lcaas_java\\Requirements\\test_files\\adminNewApartment.jsp',
                              'D:\\Lcaas_java\\Requirements\\test_files\\adminTable.css',
                              'D:\\Lcaas_java\\Requirements\\test_files\\userDAO.java'])

    def test_extensiontype(self):
        """
        1.this test case is for getExtensionType function in show code
        2.here we are testing extension type for java, css, jsp and js files
        """
        file=r"D:\Lcaas_java\Requirements\test_files\adminNewApartment.jsp"
        res=master_inventory.getExtensionType(file)
        self.assertEqual(res,"JAVA_SERVER_PAGE")
        file2=r"D:\Lcaas_java\Requirements\test_files\userDAO.java"
        res2=master_inventory.getExtensionType(file2)
        self.assertEqual(res2,"DATA_ACCESS_OBJECT")
    def test_fetchapplication(self):
        """
        1.this test case is for fetch application function in show code
        2.here we are testing application type for java, css, jsp and js files

        """
        file = r"D:\Lcaas_java\Requirements\test_files\adminNewApartment.jsp"
        res = master_inventory.fetch_application(file)
        self.assertEqual(res, "WEBCONTENT")
        file2 = r"D:\Lcaas_java\Requirements\test_files\userDAO.java"
        res2 = master_inventory.fetch_application(file2)
        self.assertEqual(res2, "USER")
    def test_master_inventory(self):
        """
        1.This test case is for master_inventory function
        2.Here we are testing total lines, empty lines, blank lines, Sloc, comment lines, total para count
        """
        res=master_inventory.master_inventory(test_path)
        print(res)
        self.assertEqual(res,[{'component_name': 'adminNewApartment.jsp', 'component_type': 'JAVA_SERVER_PAGE', 'Loc': 126, 'commented_lines': 6, 'blank_lines': 10, 'Sloc': 110, 'Path': '', 'application': 'WEBCONTENT', 'orphan': '', 'Active': '', 'execution_details': '', 'no_of_variables': '', 'no_of_dead_lines': '', 'cyclomatic_complexity': '', 'FP': '', 'dead_para_count': '', 'dead_para_list': '', 'total_para_count': '', 'comments': ''},
                              {'component_name': 'adminTable.css', 'component_type': 'STYLE_SHEET', 'Loc': 121, 'commented_lines': 0, 'blank_lines': 16, 'Sloc': 105, 'Path': '', 'application': 'WEBCONTENT', 'orphan': '', 'Active': '', 'execution_details': '', 'no_of_variables': '', 'no_of_dead_lines': '', 'cyclomatic_complexity': '', 'FP': '', 'dead_para_count': '', 'dead_para_list': '', 'total_para_count': '', 'comments': ''},
                              {'component_name': 'userDAO.java', 'component_type': 'DATA_ACCESS_OBJECT', 'Loc': 37, 'commented_lines': 2, 'blank_lines': 5, 'Sloc': 30, 'Path': '', 'application': 'USER', 'orphan': '', 'Active': '', 'execution_details': '', 'no_of_variables': '', 'no_of_dead_lines': '', 'cyclomatic_complexity': '', 'FP': '', 'dead_para_count': '', 'dead_para_list': '', 'total_para_count': 2, 'comments': ''}]
)






if __name__ == '__main__':
    unittest.main()