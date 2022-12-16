# powershell-http-server
 simple powershell http server, dont use in production!


 start with

```powershell
# using defaults 
.\webserver.ps1

# start on port 8080
.\webserver.ps1 8080

# start on port 80 and /Temporary_Listen_Addresses path if you are non priviliged
.\webserver.ps1 80  /Temporary_Listen_Addresses


# start privileged in the current directory
start-process powershell -argumentList "-ep bypass -NoExit -c cd $($PWD); .\webserver.ps1" -verb runas
```

if you are not admin and get access denied, check with `netsh http show urlacl` to find allowed ports and urls

for example
```powershell
Reserved URL            : https://*:5358/
        User: BUILTIN\Users
            Listen: Yes
            Delegate: No

```


- server listen on all interfaces so you need admin permissions to run the script
- listen per default on port 8088 if you are admin
- listen per default on port 10246 and path /MDEServer if you are not admin (access the server via http://<ip>:10246/MDEServer/)
- directory listing and navigation
- directory traversal
- file download
- browser view (for utf-8 readable files)

![image](https://user-images.githubusercontent.com/31564517/205432495-c8999711-e9b4-48c9-b3a8-d36e586cdb9e.png)



