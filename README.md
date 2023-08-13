# README.md
Create a table of Cyberark PSM sessions over a period of time

The Powershell script create a table with the number of active RDP sessions on Cyberark PSM servers for a set number of repetitions and a time interval between checks.

The following values are required to run the script:
- ServerList [Mandatory]: represents the file containing the list of PSM servers
- numCycles: represents the number of checks. Values accepted from 1 to 13. If not indicated, the default value is 7
- numMinutes: represents the number of minutes between one check and another. Accepted values from 1 to 5. If not indicated, the default value is 5

# Run with default parameters
PSM-Sessions-Table -ServerList  C:\TMP\ServerList.csv   (in this case the number of checks is 7 and waiting time is 5 minutes)
  
# Run with Cycles 
PSM-Sessions-Table -ServerList C:\TMP\ServerList.csv -numCycles 3
  
# Run with Minutes
PSM-Sessions-Table -ServerList C:\TMP\ServerList.csv -numMinutes 2

# Run with Cycles and Minutes
PSM-Sessions-Table -ServerList C:\TMP\ServerList.csv -numCycles 5 -numMinutes 2

# Requirements
- The user used to connect to the servers must have the necessary permissions to be able to execute the commands.
- To connect to the servers it is necessary to use valid credentials (domain user)
- it is necessary that the servers are reachable from the client from which the script is executed

# EXAMPLE File input
computername,role,description
PSM-1-01.mydomain.local,PSM,10.10.10.1 - PSM Pool 01
PSM-1-02.mydomain.local,PSM,10.10.10.2 - PSM Pool 01
PSM-2-01.mydomain.local,PSM,10.10.10.3 - PSM Pool 02
PSM-2-02.mydomain.local,PSM,10.10.10.4 - PSM Pool 02


# EXAMPLE Output
PSM-1-01	PSM-1-02	PSM-2-01	PSM-2-02
10			11			11			10
11			11			12			12
11			11			12			13
12			12			12			13
13			13			13			11

