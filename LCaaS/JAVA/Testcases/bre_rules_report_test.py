"""
owner: Bhavya JS
This is the test case for rules report
"""

import bre_rules_report
import unittest
extensions=['.jsp','.java','.css','.js']

class SimpleTest(unittest.TestCase):
     def test_getallreports(self):

         """This test the getall reports function of the report. This returns the json for the given input file."""

         self.assertEqual(bre_rules_report.reports.getallreports(r"D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\services\ApartmentInfo.java",extensions),{
                                                        "component_name" : "ApartmentInfo.java",
                                                        "component_type" : "JAVA_CLASS",
                                                        "Function_name" : "getApartments",
                                                        "Rule_Id" : "RULE-1",
                                                        "Rule_statements" : " while(res.next()){  ModelApartment MA = new ModelApartment();  MA.setid(Integer.parseInt(res.getString(\"id\"))); MA.setname(res.getString(\"name\")); MA.setprice(Integer.parseInt(res.getString(\"price\"))); MA.setaddress(res.getString(\"address\")); MA.setcity(res.getString(\"city\")); MA.setfloorArea(Integer.parseInt(res.getString(\"floorArea\"))); MA.setNoOfBedRooms(Integer.parseInt(res.getString(\"NoOfBedRooms\"))); MA.setdescription(res.getString(\"description\"));  datarate.add(MA); }",
                                                        "parent_rule_id" : "RULE-1",
                                                        "statement_group" : "",
                                                        "rule_category" : "",
                                                        "business_documentation" : "",
                                                        "rule_description" : ""})

         self.assertEqual(bre_rules_report.reports.getallreports(r"D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\services\ApartmentInfo.java",extensions), {"component_name" : "ApartmentInfo.java",
                                                        "component_type" : "JAVA_CLASS",
                                                        "Function_name" : "getApartmanetById",
                                                        "Rule_Id" : "RULE-2",
                                                        "Rule_statements" : " while(res.next()){    MA.setid(Integer.parseInt(res.getString(\"id\"))); MA.setname(res.getString(\"name\")); MA.setprice(Integer.parseInt(res.getString(\"price\"))); MA.setaddress(res.getString(\"address\")); MA.setcity(res.getString(\"city\")); MA.setfloorArea(Integer.parseInt(res.getString(\"floorArea\"))); MA.setNoOfBedRooms(Integer.parseInt(res.getString(\"NoOfBedRooms\"))); MA.setdescription(res.getString(\"description\"));   }",
                                                        "parent_rule_id" : "RULE-2",
                                                        "statement_group" : "",
                                                        "rule_category" : "",
                                                        "business_documentation" : "",
                                                        "rule_description" : ""
                                                    })
         self.assertEqual(bre_rules_report.reports.getallreports(r"D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\services\AddApartment.java",extensions), {"component_name" : "AddApartment.java",
                                                        "component_type" : "SERVLET",
                                                        "Function_name" : "doPost",
                                                        "Rule_Id" : "RULE-1",
                                                        "Rule_statements" : "  if(dispatcher!=null)  {  dispatcher.forward(request,response);  }",
                                                        "parent_rule_id" : "RULE-1",
                                                        "statement_group" : "",
                                                        "rule_category" : "",
                                                        "business_documentation" : "",
                                                        "rule_description" : ""
                                                    })
         self.assertEqual(bre_rules_report.reports.getallreports(r"D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\services\adminAddApartment.java",extensions), {"component_name" : "adminAddApartment.java",
                                                        "component_type" : "SERVLET",
                                                        "Function_name" : "doPost",
                                                        "Rule_Id" : "RULE-1",
                                                        "Rule_statements" : "  if(dispatcher!=null)  {  dispatcher.forward(request,response);  }",
                                                        "parent_rule_id" : "RULE-1",
                                                        "statement_group" : "",
                                                        "rule_category" : "",
                                                        "business_documentation" : "",
                                                        "rule_description" : ""
                                                    })
         self.assertEqual(bre_rules_report.reports.getallreports(r"D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\services\deleteApartment.java",extensions), {"component_name" : "deleteApartment.java",
                                                        "component_type" : "SERVLET",
                                                        "Function_name" : "doPost",
                                                        "Rule_Id" : "RULE-1",
                                                        "Rule_statements" : "  if(dispatcher!=null)  {  dispatcher.forward(request,response);  }",
                                                        "parent_rule_id" : "RULE-1",
                                                        "statement_group" : "",
                                                        "rule_category" : "",
                                                        "business_documentation" : "",
                                                        "rule_description" : ""
                                                    })
     def test_componenttype(self):

         '''This function tests the extension of given file'''

         b = bre_rules_report.reports.getcomponenttype(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\services\ApartmentInfo.java')
         c=bre_rules_report.reports.getcomponenttype(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\WebContent\css\adminTable.css')
         d=bre_rules_report.reports.getcomponenttype(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\WebContent\aboutus.jsp')
         self.assertEqual(b, 'JAVA_CLASS')
         self.assertEqual(c, 'STYLE_SHEET')
         self.assertEqual(d, 'JAVA_SERVER_PAGE')

     def test_create_dictionary(self):

         """This function test the dictionary output for the given file"""

         self.assertEqual(bre_rules_report.reports.createdict(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\services\ApartmentInfo.java'),{
                                         "addApartmentInfo": [
                                         "  public void addApartmentInfo(ModelApartment apartInfo) {  ",
                                         "    // TODO Auto-generated method stub  ",
                                         "    try {  ",
                                         "      Connection con = DbConnection.getConnection();   ",
                                         "      PreparedStatement st = con.prepareStatement(\"insert into apartment(name,price,address,city,floorArea,NoOfBedRooms,description, userID) values(?,?,?,?,?,?,?, ?)\");  ",
                                         "      st.setString(1,apartInfo.getname());  ",
                                         "      st.setInt(2,apartInfo.getprice());  ",
                                         "      st.setString(3,apartInfo.getaddress());  ",
                                         "      st.setString(4,apartInfo.getcity());  ",
                                         "      st.setInt(5,apartInfo.getfloorArea());  ",
                                         "      st.setInt(6,apartInfo.getNoOfBedRooms());  ",
                                         "      st.setString(7,apartInfo.getdescription());    ",
                                         "      st.setInt(8, apartInfo.getUserID());  ",
                                         "      st.executeUpdate();  ",
                                         "      st.close();  ",
                                         "      con.close();      ",
                                         "    } catch (SQLException e) {  ",
                                         "      // TODO Auto-generated catch block  ",
                                         "      e.printStackTrace();  ",
                                         "    }  ",
                                         "  }  "]})
         self.assertEqual(bre_rules_report.reports.createdict(r'D:\Lcaas_java\Requirements\source_files\Property_codedump\src\com\masterofproperty\apartment\services\ApartmentInfo.java'),
                                                          {"getApartments": [
                                        "  public ArrayList<ModelApartment> getApartments() {  ",
                                        "    // TODO Auto-generated method stub  ",
                                        "    ArrayList<ModelApartment> datarate = new ArrayList<ModelApartment>();  ",
                                        "    try {   ",
                                        "      Connection con = DbConnection.getConnection();         ",
                                        "      Statement st  = con.createStatement();  ",
                                        "      String sql =\"select id,name,price,address,city,floorArea,NoOfBedRooms,description from apartment\";  ",
                                        "      ResultSet res = st.executeQuery(sql);  ",
                                        "      while(res.next()){  ",
                                        "        ModelApartment MA = new ModelApartment();  ",
                                        "        MA.setid(Integer.parseInt(res.getString(\"id\")));  ",
                                        "        MA.setname(res.getString(\"name\"));  ",
                                        "        MA.setprice(Integer.parseInt(res.getString(\"price\")));  ",
                                        "        MA.setaddress(res.getString(\"address\"));  ",
                                        "        MA.setcity(res.getString(\"city\"));  ",
                                        "        MA.setfloorArea(Integer.parseInt(res.getString(\"floorArea\")));  ",
                                        "        MA.setNoOfBedRooms(Integer.parseInt(res.getString(\"NoOfBedRooms\")));  ",
                                        "        MA.setdescription(res.getString(\"description\"));  ",
                                        "        datarate.add(MA);  ",
                                        "      }  ",
                                        "      con.close();  ",
                                        "      st.close();  ",
                                        "      } catch (Exception e) {  ",
                                        "        System.out.println(\"exception\");  ",
                                        "        System.out.println(e);  ",
                                        "          }  ",
                                        "    return datarate;  ",
                                        "  }  "
                                    ]})

if __name__ == '__main__':
        unittest.main()