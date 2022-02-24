class Node:
    def __init__(self, data=None, next_elm=None):
        self.data = data
        self.next_elm = next_elm


class Linked_list:
    def __init__(self):
        self.head = None

    def insert_at_begning(self, data):
        node = Node(data, self.head)  # passing head value along with data to make it next node and store inside the current node object
        self.head = node # onde after creating the current node with next node data in it we will promte the current node as head node


    def inster_at_end(self,data):
        if self.head is None:
            self.head = Node(data,None)
            return

        itr = self.head
        while itr.next_elm: # every node will have cureent
                            # data and next elm data so we start the iteration with the head elem
                            # and util reches the last elm we will run a while loop

            itr = itr.next_elm

        itr.next_elm=Node(data,None) # once after reaching the last node add a node to last node next elm which is last

    def print(self):
        if self.head is None:
            print("Linked List is empty")
            return
        itr = self.head
        listr = ''
        while itr:
            listr = listr + str(itr.data) + '-->'
            itr = itr.next_elm
        print(listr)

    def insert_values(self,data_list):
        # self.head = None
        for data in data_list:
            self.inster_at_end(data)

    def get_length(self):
        count= 0
        itr = self.head
        while itr:
            count += 1
            itr = itr.next_elm

        return count

    def remove_at(self,index):
        if index < 0 or index >= self.get_length():
            raise Exception("Invalid index")
        if index == 0 :
            self.head = self.head.next
            return
        count = 0
        itr = self.head
        while itr:
            if count == index-1:
                itr.next_elm = itr.next_elm.next_elm
                break
            itr = itr.next_elm
            count += 1

    def insert_at(self,index,data):
        if index < 0 or index >= self.get_length():
            raise Exception("Invalid index")
        if index == 0:
            self.insert_at_begning(data)
            return
        count = 0
        itr = self.head
        while itr:
            if count == index-1:
                node = Node(data,iter.next_elm)
                itr.next_elm = node
                break
            itr = itr.next_elm
            count += 1

if __name__ == '__main__':
    ll = Linked_list()
    ll.insert_at_begning(5)
    ll.insert_at_begning(89)
    ll.inster_at_end(22)
    ll.insert_at_begning(33)
    ll.insert_values([1,2,3,4,"apple"])
    ll.remove_at(4)
    print("lenght of Linked _list: ",ll.get_length())

    ll.print()
