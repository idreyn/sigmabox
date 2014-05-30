from lib601.dist import *

d1 = DDist({'G': 0.2, 'F': 0.3, 'C': 0.3, 'FC': 0.2})


def d2(s):
    if s == 'G':
        return DDist({1: 0.1, 2: 0.2, 3: 0.3, 'L': 0.4})
    elif s == 'F':
        return DDist({1: 0.0, 2: 0.1, 3: 0.1, 'L': 0.8})
    elif s == 'C':
        return DDist({1: 0.1, 2: 0.1, 3: 0.1, 'L': 0.7})
    elif s == 'FC':
        return DDist({1: 0.0, 2: 0.0, 3: 0.1, 'L': 0.9})
