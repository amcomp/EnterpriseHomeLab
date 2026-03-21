function New-User {
    # Set params for function
    param (
        [Parameter(Mandatory=$true)]
        [string]$GivenName,

        [Parameter(Mandatory=$true)]
        [string]$Surname,

        [Parameter(Mandatory=$true)]
        [ValidateSet('IT', 'HR', 'Finance')]
        [string]$DepartmentOption,

        [Parameter(Mandatory=$false)]
        [string]$Title = "Employee",

        # Set for your own domain
        [string]$Domain = "blackboxlab.org"
    )
        # Process the parameters to create the user account
        $FirstInitial = $GivenName.Substring(0,1).ToLower()
        $SamAccountName = ($FirstInitial + $Surname).ToLower()
        $UPN = "$SamAccountName@$Domain"

        # Check if user already exists
        if (Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue) {
            Write-Error "User '$SamAccountName' already exists in Active Directory."
            return
        }

        # Define OU and group based on department selection, in this envrionment, I am only planning three departments. 
        $DeptConfig = switch ($DepartmentOption.ToUpper()) {
            'IT' { 
                [PSCustomObject]@{ 
                    OU    = 'OU=IT,OU=HomeLabUsers,DC=home,DC=lab'
                    Group = 'IT' 
                    DeptName = 'Information Technology'
                } 
            }
            'HR' { 
                [PSCustomObject]@{ 
                    OU    = 'OU=HR,OU=HomeLabUsers,DC=home,DC=lab'
                    Group = 'HR' 
                    DeptName = 'Human Resources'
                } 
            }
            'FINANCE' { 
                [PSCustomObject]@{ 
                    OU    = 'OU=Finance,OU=HomeLabUsers,DC=home,DC=lab'
                    Group = 'Finance' 
                    DeptName = 'Finance'
                } 
            }
        }
        
        # Prompt for password securely
        $Password = Read-Host -Prompt "Enter password for $SamAccountName" -AsSecureString

        #Setup parameters for New-ADUser
        $UserParams = @{
            Name                  = "$GivenName $Surname"
            GivenName             = $GivenName
            Surname               = $Surname
            DisplayName           = "$Surname, $GivenName"
            Department            = $DeptConfig.DeptName
            Path                  = $DeptConfig.OU
            UserPrincipalName     = $UPN
            SamAccountName        = $SamAccountName
            EmailAddress          = $UPN
            AccountPassword       = $Password
            Enabled               = $true
            Title                 = $Title
            ChangePasswordAtLogon = $true
            PassThru              = $true
        }

        # Try to create the user and add to group, with error handling
        try {
            Write-Host "Creating user $SamAccountName..." -ForegroundColor Cyan
            $NewADUser = New-ADUser @UserParams
            
            Write-Host "Adding to group: $($DeptConfig.Group)..." -ForegroundColor Cyan
            Add-ADGroupMember -Identity $DeptConfig.Group -Members $NewADUser
            
            Write-Host "Successfully created $GivenName $Surname" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to create user or add to group. Details: $_"
        }
    }
