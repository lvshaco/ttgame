package.path = package.path .. ";../../3rdlib/?.lua"
package.cpath = package.cpath .. ";../../bin/?.so;../../3rdlib/?.so"
print(package.path)
print(package.cpath)
