
class A:

    def __init__(self):
        print("in a init")

    def fet1(self):
        print("fet1 is working")

    def fet2(self):
        print("fet2 is working")

class B(A):

    def __init__(self):
        super().__init__()
        print("in B init")

    def fet3(self):
        print("fet3 is working")

    def fet4(self):
        print("fet4 is working")


a1 =B()
 
