# Notepad
New-RDRemoteApp -CollectionName "LabApps" -DisplayName "Notepad" -FilePath "C:\Windows\System32\notepad.exe" -ShowInWebAccess $true

Restart-Service -Name "TermService","Tssdis","SessionEnv" -Force