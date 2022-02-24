class Node:
    def __init__(self, data):
        self.data = data
        self.next = None


class Stack:
    def __init__(self):
        self.head = None

    def push(self, data):
        if self.head is None:
            self.head = Node(data)
        else:
            new_node = Node(data)
            new_node.next = self.head
            self.head = new_node

    def isempty(self):
        if self.head is None:
            return True
        else:
            return False

    def pop(self):
        if self.isempty():
            return None
        else:
            poped_node = self.head
            self.head = self.head.next
            poped_node.next = None
            return poped_node.data

    def peek(self):
        if self.isempty():
            return None
        else:
            return self.head.data

    def display(self):
        if self.isempty():
            return None
        else:
            iter_node = self.head

            while iter_node is not None:
                print(iter_node.data, " ->", end=" ")

                iter_node = iter_node.next
            print()


Mystack = Stack()
Mystack.push(22)
Mystack.push(33)
Mystack.push(99)
Mystack.push(77)

Mystack.display()

print(Mystack.peek())

Mystack.pop()
Mystack.pop()

Mystack.display()
