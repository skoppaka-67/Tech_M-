# import verizon.aps_cobol_flowchart_fixed as aps_cobol_flowchart_fixed
import unittest
# import config

class MyTestCase(unittest.TestCase):
    # def test1(self):
    #     self.assertRaises(IndexError, aps_cobol_flowchart_fixed.process())

    def test_string(self):
        a = 'some'
        b = 'some'
        self.assertEqual(a, b)

