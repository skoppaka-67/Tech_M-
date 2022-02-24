"""
Testcases for JAVA show code report
Dependencies: Show code file and config
"""

import show_code_report
import unittest
import config

test_path = config.test_path
extentions = [".jsp", ".java", ".css", ".js"]

class test_show_code(unittest.TestCase):
    def test1(self):
        """
        1.This test case is for getallfiles function in glossary file.
        2.Here we are testing whether all the files in directories are accessing or not
        :return: will return test case passed if all the files in the directory equals to return value of get all files function output
        """
        res = show_code_report.get_files(test_path, extentions)
        self.assertEqual(res,['D:\\Lcaas_java\\Requirements\\test_files\\Apartment.jsp',
                              'D:\\Lcaas_java\\Requirements\\test_files\\idealhomeform.css',
                              'D:\\Lcaas_java\\Requirements\\test_files\\userDAO.java'])



    def test_extensiontype(self):
        """
        1.this test case is for getExtensionType function in show code
        2.here we are testing extension type for java, css, jsp and js files
        """
        file=r"D:\Lcaas_java\Requirements\test_files\userDAO.java"
        res=show_code_report.getExtensionType(file)
        self.assertEqual(res,"DATA_ACCESS_OBJECT")
        file2=r"D:\Lcaas_java\Requirements\test_files\idealhomeform.css"
        res2=show_code_report.getExtensionType(file2)
        self.assertEqual(res2,"STYLE_SHEET")
    def test_showcode(self):
        """
        1.this test case is for show code function in show code report
        2. here we are testing whether all the lines in a file are accesing or not with <br> tag after each line
        """
        res=show_code_report.show_code(test_path)
        self.assertEqual(res,[{'component_name': 'userDAO.java', 'component_type': 'DATA_ACCESS_OBJECT',
                               'codeString': 'package com.masterofproperty.user;\n<br>import java.sql.DriverManager;\n'
                                             '<br>import java.sql.PreparedStatement;\n<br>import java.sql.Connection;\n'
                                             '<br>import java.sql.SQLException;\n<br>public class userDAO {\n<'
                                             'br>\tprivate String dburl ="jdbc:mysql://localhost:3306/oop";\n'
                                             '<br>\tprivate String dbuname="root";\n<br>\tprivate String dbpassword="";\n'
                                             '<br>\tprivate String dbdriver ="com.mysql.jdbc.Driver";\n<br>\tpublic void loadDriver(String dbdriver)\n<br>\t{\n<br>\t\ttry {\n<br>\t\t\tClass.forName(dbdriver);\n'
                                             '<br>\t\t} catch (ClassNotFoundException e) {\n<br>\t\t\t// TODO Auto-generated catch block\n<br>\t\t\te.printStackTrace();\n<br>\t\t}\n<br>\t}\n<br>\tpublic Connection getConnection()\n<br>\t{\n'
                                             '<br>\t\tConnection con = null;\n<br>\t\ttry {\n<br>\t\t\tcon = DriverManager.getConnection(dburl, dbuname, dbpassword);\n<br>\t\t\tSystem.out.println("Connected");\n<br>\t\t} catch (SQLException e) {\n'
                                             '<br>\t\t\t// TODO Auto-generated catch block\n<br>\t\t\te.printStackTrace();\n<br>\t\t\tSystem.out.println("not connected");\n<br>\t\t}\n<br>\t\treturn con;\n<br>\t}\n'}]
)



if __name__ == '__main__':
    unittest.main()
