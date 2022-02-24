# # class fun:
# #     def __init__(self,l):
# #         self.l = l
# #     def __iter__(self):
# #         self.a = 15
# #         return self
# #     def __next__(self):
# #         a = self.a
# #         if a > self.l:
# #             raise  StopIteration
# #         self.a = a+1
# #         return a
#
# # for i in fun(18):
# #     print(i,end=' ')
#
# #
# # def Fun(x):
# #     while(x!=0):
# #         if x % 3 == 0:
# #             yield  x
# #         x -=1
# # for i in Fun(9):
# #     print(i,end=" ")
#
# # from math import  sin,cos,pi
#
# def decorprog(f):
#     def fun(x):
#         res = int(f(x))
#         print(res)
#     return  fun
# sin = decorprog(cos)
# for f in [sin, cos]:
#     f(pi)

# l = [[1,2],[3,4],[5,6]]
# m = [(y,x) for x,y in l]
#
# print(m)

def fib():
    a,b = 0 ,1
    while True:
        yield  a
        a,b = b, a+b

for f in fib():
    if f > 100:
        break
    print(f)

n = 7
fact  = 1
for i in range(1,n+1):

    fact = fact*i
print(fact)