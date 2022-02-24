
class A:

    def show(self):
        print("in A show")

class B(A):

    def show(self):
        print("in B Show")



a1 = B()
a1.show()

class Lode:



    def overlode(self,A= None,B=None,c=None):

        if A != None and B != None and c != None :

            return  A+B+c
        elif A != None and B != None :
            return  A+B
        else:
            return  A

obj = Lode()

print(obj.overlode(5,22,55))