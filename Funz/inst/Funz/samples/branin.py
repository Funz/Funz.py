import math as m
def branin(x1,x2):
    x1 = x1*15-5
    x2 = x2*15

    return (x2 - 5/(4*m.pi**2)*(x1**2) + 5/m.pi*x1 -6 )**2 + 10*(1-1/(8*m.pi))*m.cos(x1) +10

print('z={0}'.format( branin( ?x1 , ?x2 ) ) )
