# powershell-http-server
 simple powershell http server, dont use in production!


 start with

```powershell
.\webserver.ps1

# start privileged in the current directory
start-process powershell -argumentList "-ep bypass -NoExit -c cd $($PWD); .\webserver.ps1" -verb runas
```

- server listen on all interfaces so you need admin permissions to run the script
- listen on port 8088
- directory listing and navigation
- directory traversal
- file download
- browser view (for utf-8 readable files)

![image](https://user-images.githubusercontent.com/31564517/205432495-c8999711-e9b4-48c9-b3a8-d36e586cdb9e.png)



