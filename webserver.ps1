
#params
param (
    [int]$port,
    [string]$suffix
    )

Add-Type -AssemblyName System.Web

# no args, run with default params
if (!$port -and !$suffix) {

    Write-Host "[+] using defaults, check if admin"
    #check if admin
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

    if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "[+] you are admin"
        $suffix = ''
        $port = 8088

    } else {
        
        Write-Host "[+] you are not admin, try to start with suffix"
        $suffix = '/MDEServer'
        $port = 10246

    }
} else {
    Write-Host "[+] trying to start server on http://<ip>:$($port)$($suffix)/ ..."
}


# try to start webserver
try {

    $httpsrvlsnr = New-Object System.Net.HttpListener;
    $httpsrvlsnr.Prefixes.Add("http://+:$($port)$($suffix)/");
    $httpsrvlsnr.Start();
    $webroot = New-PSDrive -Name webroot -PSProvider FileSystem -Root $PWD.Path
    [byte[]]$buffer = $null
    
    Write-Host "[+] server started and listening on all interfaces, access it via http://<ip>:$($port)$($suffix)/ you need the tailing slash!"
}
catch {
    
    Write-Host "`n[ERROR]" $Error[0]
    Remove-PSDrive -Name webroot -PSProvider FileSystem -ErrorAction SilentlyContinue;
    Write-Host "`n[-] if you get access denied, try to start the server without parameters or find a allowed port and suffix by running 'netsh http show urlacl' then start the webserver for example with '.\webserver.ps1 80 /Temporary_Listen_Addresses'`n"
}


function List-Files($dir) {
    
    $upDir = $dir.substring(0,$dir.LastIndexOf('\'))

    if (!$upDir.Contains('\')) {
        $upDir = 'C:\'
    } 

    $outPut  = "<html><a href='$($suffix)/stop'>Stop Server</a>`t<a href='$($suffix)/'>Home</a>`t<a href='$($suffix)/?folder=C:\'>Root (C:\)</a>`t<a href='$($suffix)/?folder=$($upDir)'>UP</a>"  
    $outPut += "<pre>Current Directory: " + $dir + "<br><br>"
    try {

        $folderContent = Get-ChildItem -Path $dir -Force -ErrorAction Stop
   
        foreach ($item in $folderContent)
        {
            $urlPath= [System.Web.HttpUtility]::UrlEncode($item.FullName)
            if (Test-Path -Path $item.FullName -PathType Container)
            {
                $outPut +=  "<span style=""display: inline-block; width: 50px;"">"+$item.Mode+"</span><span style=""display: inline-block; width: 150px;"">"+$item.LastWriteTime+"</span><span style=""display: inline-block; width: 120px;"">"+$item.Length+"</span><span><a href='$($suffix)/?folder=$($urlPath)'>"+$item.Name+"</a></span><br>"
            }
            else {
    
                $outPut +=  "<span style=""display: inline-block; width: 50px;"">"+$item.Mode+"</span><span style=""display: inline-block; width: 150px;"">"+$item.LastWriteTime+"</span><span style=""display: inline-block; width: 120px;"">"+$item.Length+"</span><span><a href='$($suffix)/?file=$($urlPath)'>"+$item.Name+"</a></span> - <span><a href='?dl=$($urlPath)'>(Download)</a></span><br>"
            }
        }
        
    }
    catch {
        $outPut += $Error[0]
    }

    $outPut += "</pre></html>"
    return $outPut
}

function downloadFile($newPath) {
    try {
        # ... download file
        $BUFFER = [System.IO.File]::ReadAllBytes($newPath)
        $ctx.Response.ContentLength64 = $BUFFER.Length
        $ctx.Response.SendChunked = $FALSE
        $ctx.Response.ContentType = "application/octet-stream"
        $filename = Split-Path -Leaf $newPath
        $ctx.Response.AddHeader("Content-Disposition", "attachment; filename=$filename")
        $ctx.Response.AddHeader("Last-Modified", [IO.File]::GetLastWriteTime($newPath).ToString('r'))
        $ctx.Response.AddHeader("Server", "Powershell Webserver/1.1 on ")
        $ctx.Response.OutputStream.Write($BUFFER, 0, $BUFFER.Length)
    }
    catch
    {
        $outPut += $Error[0]
        $buffer = [System.Text.Encoding]::UTF8.GetBytes("<html><pre>$($outPut)</pre></html>");
        $ctx.Response.ContentLength64 = $buffer.Length;
        $ctx.Response.OutputStream.WriteAsync($buffer, 0, $buffer.Length)
    }
}

while ($httpsrvlsnr.IsListening) {
    try {
        $ctx = $httpsrvlsnr.GetContext();
        
        if ($ctx.Request.RawUrl -eq "$($suffix)/") {

            $outPut = List-Files($PWD.Path)
            $buffer = [System.Text.Encoding]::UTF8.GetBytes("<html><pre>$($outPut)</pre></html>");
            $ctx.Response.ContentLength64 = $buffer.Length;
            $ctx.Response.OutputStream.WriteAsync($buffer, 0, $buffer.Length)

        }
        elseif ($ctx.Request.RawUrl -eq "$($suffix)/stop"){
            $buffer = [System.Text.Encoding]::UTF8.GetBytes("<html><pre>Server Stopped</pre></html>");
            $ctx.Response.ContentLength64 = $buffer.Length;
            $ctx.Response.OutputStream.WriteAsync($buffer, 0, $buffer.Length)
            $httpsrvlsnr.Stop();
            Remove-PSDrive -Name webroot -PSProvider FileSystem;
        }
        elseif ($ctx.Request.RawUrl.StartsWith("$($suffix)/?folder=")) {

            $newPath = $ctx.Request.RawUrl.Substring(9 + $suffix.Length)
            $newPath = [System.Web.HttpUtility]::UrlDecode($newPath)
            Write-Host "Requested folder: " $newPath 
            if (Test-Path -Path  $newPath -PathType Container)
            {
                $outPut = List-Files($newPath)
                $buffer = [System.Text.Encoding]::UTF8.GetBytes("<html><pre>$($outPut)</pre></html>");
                $ctx.Response.ContentLength64 = $buffer.Length;
                $ctx.Response.OutputStream.WriteAsync($buffer, 0, $buffer.Length)
            }
        } # open in browser
        elseif ($ctx.Request.RawUrl.StartsWith("$($suffix)/?file="))
        {    
            $newPath = $ctx.Request.RawUrl.Substring(7 + $suffix.Length)
            $newPath = [System.Web.HttpUtility]::UrlDecode($newPath)
            Write-Host "Requested file: " $newPath
            try {
                if ([System.IO.File]::Exists(($newPath))) {
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes((Get-Content -Path $newPath));
                    $ctx.Response.ContentLength64 = $buffer.Length;
                    $ctx.Response.OutputStream.WriteAsync($buffer, 0, $buffer.Length)
                }            
            }
            catch {
                $outPut += $Error[0]
                $buffer = [System.Text.Encoding]::UTF8.GetBytes("<html><pre>$($outPut)</pre></html>");
                $ctx.Response.ContentLength64 = $buffer.Length;
                $ctx.Response.OutputStream.WriteAsync($buffer, 0, $buffer.Length)
            }
       
        } # browser download
        elseif ($ctx.Request.RawUrl.StartsWith("$($suffix)/?dl="))
        {    
            $newPath = $ctx.Request.RawUrl.Substring(5 + + $suffix.Length)
            $newPath = [System.Web.HttpUtility]::UrlDecode($newPath)
            Write-Host "download file: " $newPath
            downloadFile($newPath)
         
        } # direct downloads
        elseif ($ctx.Request.RawUrl -match "$($suffix)\/[A-Za-z0-9-\s.)(\[\]]") {
            
            $newPath = $ctx.Request.RawUrl
            $newPath = [System.Web.HttpUtility]::UrlDecode($newPath)
            $newPath = Join-Path -Path $PWD.Path -ChildPath $ctx.Request.RawUrl.Trim("/\")
            Write-Host "Direct dowload file: " $newPath
            downloadFile($newPath)
        }

    }
    catch [System.Net.HttpListenerException] {
        Write-Host ($_);
    }
}

