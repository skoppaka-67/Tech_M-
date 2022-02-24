class student:

    school ='telusko'

    def __init__(self,m1,m2,m3):
        self.m1 = m1
        self.m2 = m2
        self.m3 = m3

    def avg(self): #instence methods
        '''

        two types of instance methods

        Accesor Methods - only to fetch the values  example : get methods
        Mutator Methods -  to modify values example : set methods

        '''

        return (self.m1 + self.m2 + self.m3)/3

    @classmethod
    def info(cls):
        '''Decorators are important for cls methods to differ from other methods '''
        return cls.school

    @staticmethod
    def laptop():
        '''its importent to mark the staic method with decorator  inside a class'''
        print("this is an static method ")


s1 = student(22,33,44)
s2 = student(32,43,54)

print(s1.avg())
print(student.info()) ## class methods need to be accessed using class names but not objects
student.laptop()