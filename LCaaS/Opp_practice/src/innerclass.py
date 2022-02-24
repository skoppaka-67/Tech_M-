class student:

    def __init__(self,name,rollmo):
        self.name = name
        self.rollmo = rollmo

        # self.lap = self.laptop()

    def show(self):
        print(self.name,self.rollmo)

    class laptop:

        def __init__(self,cpu,ram,brand):
            self.cpu = cpu
            self.ram = ram
            self.brand = brand

        def show(self):
            print(self.cpu, self.ram,self.brand)





s1 = student('kiran',2)
s2 = student('santhi',1)



lap1 = student.laptop("i5",8,"hp")
lap1.show()