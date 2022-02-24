





class HashTable:
    def __init__(self,size):
        self.size = size
        self.data = [[] for _ in range(self.size)]



    def set(self,key,value):
        address = hash(key)%self.size


        bucket = self.data[address]
        found_key = False
        for index, record in enumerate(bucket):
            record_key, record_val = record

            # check if the bucket has same key as
            # the key to be inserted
            if record_key == key:
                found_key = True
                break

        if found_key:
            bucket[index] = (key, value)
        else:
            bucket.append((key, value))



hash_table = HashTable(2)
hash_table.set("grapes",1000)
hash_table.set("apples",1000)
hash_table.set("mangos",1000)
print(hash_table.data)

