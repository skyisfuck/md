$url = "https://raw.githubusercontent.com/jborean93/ansible-windows/master/scripts/Upgrade-PowerShell.ps1"
$file = "$env:temp\Upgrade-PowerShell.ps1"
$username = "test"
$password = "`1q"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

# PowerShell �汾��ֻ���� 3.0, 4.0 �� 5.1
&$file -Version 4.0 -Username $username -Password $password -Verbose