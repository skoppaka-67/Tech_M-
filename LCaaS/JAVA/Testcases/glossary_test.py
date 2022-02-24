"""
Test Cases for Glossary
Dependencies: glossary file and config file
"""



import glossary
import unittest
import config

test_path = config.test_path
extentions = [".jsp", ".java", ".css", ".js"]


class glossary_test(unittest.TestCase):
    def test1(self):
        """
        1.This test case is for getallfiles function in glossary file.
        2.Here we are testing whether all the files in directories are accessing or not
        :return: will return test case passed if all the files in the directory equals to return value of get all files function output
        """
        res = glossary.getallfiles(test_path, extentions)
        self.assertEqual(res, ['D:\\Lcaas_java\\Requirements\\test_files\\Apartment.jsp',
                               'D:\\Lcaas_java\\Requirements\\test_files\\ApartmentInfo.java',
                               'D:\\Lcaas_java\\Requirements\\test_files\\idealhomeform.css'])

    def test2(self):
        """
        1.This function is for glossary function with one java file
        2.here we are testing whether all the variables in java file are accessing by the function are not
        :return: will return passed if variables in file and return value of function are equal
        """
        res = glossary.glossary(test_path, extentions)

        self.assertEqual(res, [{'File_name': 'IdealHome.java', 'Variable': 'sID', 'Business_Meaning': ''},
                               {'File_name': 'IdealHome.java', 'Variable': 'userID', 'Business_Meaning': ''},
                               {'File_name': 'IdealHome.java', 'Variable': 'title', 'Business_Meaning': ''},
                               {'File_name': 'IdealHome.java', 'Variable': 'description', 'Business_Meaning': ''},
                               {'File_name': 'IdealHome.java', 'Variable': 'name', 'Business_Meaning': ''},
                               {'File_name': 'IdealHome.java', 'Variable': 'email', 'Business_Meaning': ''},
                               {'File_name': 'IdealHome.java', 'Variable': 'pnumber', 'Business_Meaning': ''}])

    def test3(self):
        """
                1.This function is for glossary function with another java file
                2.here we are testing whether all the variables in java file are accessing by the function are not
                :return: will return passed if variables in file and return value of function are equal
                """
        res = glossary.glossary(test_path, extentions)
        print(res)
        self.assertEqual(res, [{'File_name': 'userDAO.java', 'Variable': 'dburl', 'Business_Meaning': ''},
                               {'File_name': 'userDAO.java', 'Variable': 'dbuname', 'Business_Meaning': ''},
                               {'File_name': 'userDAO.java', 'Variable': 'dbpassword', 'Business_Meaning': ''},
                               {'File_name': 'userDAO.java', 'Variable': 'dbdriver', 'Business_Meaning': ''}])


if __name__ == '__main__':
    unittest.main()
