
class Computer:
    def __init__(self,cpu,ram): #equlent to constructor
        self.cpu = cpu
        self.ram = ram

    def config(self): # we can pass varibles only using self keyword
        #print("config",self.cpu,self.ram)
        pass



com1 = Computer("i5",8) # obj creation
com2 = Computer('i7',16)


com1.config() #invoking
com2.config()

class Computer1:
    def __init__(self):
        self.name = "kiran"
        self.age = 25

    def compare(self,other):
        if self.age == other.age:
            return True
        else:
            return False



c1 = Computer1()
c2 = Computer1()




if c1.age == c2.age:
    print("they are same ")

if c1.compare(c2):
    print("they are sameee")
else:
    print("not same" )