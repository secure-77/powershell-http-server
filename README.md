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
- directory listing and navigation enabled
- directory traversal possible
- download and view in browser (for txt files) possible


