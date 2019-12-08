$url = "https://raw.githubusercontent.com/jborean93/ansible-windows/master/scripts/Upgrade-PowerShell.ps1"
$file = "$env:temp\Upgrade-PowerShell.ps1"
$username = "administrator"
$password = "PASSWD"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

# PowerShell 版本，只能用 3.0, 4.0 和 5.1 
&$file -Version 4.0 -Username $username -Password $password -Verbose
