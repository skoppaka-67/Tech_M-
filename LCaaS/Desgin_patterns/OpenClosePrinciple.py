from enum import Enum


class Color(Enum):
    RED = 1
    GREEN = 2
    BLUE = 3

class Size(Enum):
    SMALL = 1
    Medium = 2
    Large = 3

class Product:

    def __init__(self,name,color,size):
        self.name = name
        self.color = color
        self.size = size


class ProductFilter:

    def filter_by_color(self,products,color):
            for p in products:
                if p.color == color: yield

