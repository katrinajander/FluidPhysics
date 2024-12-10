import numpy as np

omega = 1
rho = 0

zero = 10
north = 10
northeast = 10
east = 10
southeast = 10
south = 10
southwest = 10
west = 10
northwest = 10

for i in range(1):
    rho = zero + north + south + east + west + northwest + northeast + southwest + southeast
    ux = (east + northeast + southeast - northwest - west - southwest) / rho
    uy = (north + northeast + northwest - south - southeast - southwest) / rho

    print(f"ux: {ux}")
    print(f"uy: {uy}")

    one9thrho = rho/9
    one36thrho = rho/36

    ux3 = 3 * ux
    uy3 = 3 * uy
    ux2 = ux * uy
    uy2 = uy * uy
    uxuy2 = 2 * ux * uy
    u2 = ux2 + uy2
    u215 = 1.5 * u2

    print(f"u215: {u215}")

    zero  = 4*one9thrho * (1                        	  - u215)
    east  += omega * (   one9thrho * (1 + ux3       + 4.5*ux2        - u215) - east)
    west  += omega * (   one9thrho * (1 - ux3       + 4.5*ux2        - u215) - west)
    north  += omega * (   one9thrho * (1 + uy3       + 4.5*uy2        - u215) - north)
    south  += omega * (   one9thrho * (1 - uy3       + 4.5*uy2        - u215) - south)
    northeast += omega * (  one36thrho * (1 + ux3 + uy3 + 4.5*(u2+uxuy2) - u215) - northeast)
    southeast += omega * (  one36thrho * (1 + ux3 - uy3 + 4.5*(u2-uxuy2) - u215) - southeast)
    northwest += omega * (  one36thrho * (1 - ux3 + uy3 + 4.5*(u2-uxuy2) - u215) - northwest)
    southwest += omega * (  one36thrho * (1 - ux3 - uy3 + 4.5*(u2+uxuy2) - u215) - southwest)

sum = zero + north + south + east + west + northwest + northeast + southwest + southeast

print(f"zero {zero}")
print(f"north {north}")
print(f"northeast {northeast}")
print(f"east {east}")
print(f"southeast {southeast}")
print(f"south {south}")
print(f"southwest {southwest}")
print(f"west {west}")
print(f"northwest {northwest}")
print(f"sum {sum}")