@echo off

color 1f

set fname=
set lname=

:name
set /p fname="Enter client's first name: "
set /p lname="Enter client's last name: "



cd %homepath%/Desktop
powercfg /energy /output %fname-%lname.htm

findstr "Design Capacity" %fname-%lname.htm
findstr "Last Full Charge" %fname-%lname.htm

for /f "tokens=1 "