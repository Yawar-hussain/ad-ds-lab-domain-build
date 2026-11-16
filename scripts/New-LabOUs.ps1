<#
.SYNOPSIS
    Creates the lab OU structure and department security groups in Active Directory.

.DESCRIPTION
    Builds this tree under the domain root:
        YawarLab
        ├── Users
        │   ├── IT
        │   ├── Finance
        │   ├── HR
        │   └── Contractors
        ├── Workstations
        ├── Servers
        ├── Groups
        └── Disabled Users
    It also creates one security group per department, plus a Helpdesk group, in the Groups OU.
    Safe to run more than once: anything that already exists is skipped.

.NOTES
    LAB USE ONLY. Run on DC01 as a Domain Admin.
    Requires the ActiveDirectory module (installed with the AD DS role / RSAT).
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$RootOUName = 'YawarLab',
    [string[]]$Departments = @('IT', 'Finance', 'HR', 'Contractors')
)

Import-Module ActiveDirectory -ErrorAction Stop

$domainDN = (Get-ADDomain).DistinguishedName

function New-LabOU {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Name, [string]$Path)
    $dn = "OU=$Name,$Path"
    if (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$dn'" -ErrorAction SilentlyContinue) {
        Write-Host "[skip]   OU exists: $dn" -ForegroundColor Yellow
    }
    elseif ($PSCmdlet.ShouldProcess($dn, 'Create OU')) {
        New-ADOrganizationalUnit -Name $Name -Path $Path -ProtectedFromAccidentalDeletion $true
        Write-Host "[create] OU: $dn" -ForegroundColor Green
    }
    return $dn
}

# Top-level OUs
$rootDN   = New-LabOU -Name $RootOUName -Path $domainDN
$usersDN  = New-LabOU -Name 'Users'          -Path $rootDN
$groupsDN = New-LabOU -Name 'Groups'         -Path $rootDN
New-LabOU -Name 'Workstations'   -Path $rootDN | Out-Null
New-LabOU -Name 'Servers'        -Path $rootDN | Out-Null
New-LabOU -Name 'Disabled Users' -Path $rootDN | Out-Null

# Department OUs and groups
foreach ($dept in $Departments) {
    New-LabOU -Name $dept -Path $usersDN | Out-Null
}

foreach ($groupName in ($Departments | ForEach-Object { "GRP-$_" }) + 'GRP-Helpdesk') {
    if (Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue) {
        Write-Host "[skip]   Group exists: $groupName" -ForegroundColor Yellow
    }
    elseif ($PSCmdlet.ShouldProcess($groupName, 'Create security group')) {
        New-ADGroup -Name $groupName -GroupScope Global -GroupCategory Security -Path $groupsDN
        Write-Host "[create] Group: $groupName" -ForegroundColor Green
    }
}

Write-Host "`nDone. Check the result with:" -ForegroundColor Cyan
Write-Host "  Get-ADOrganizationalUnit -SearchBase '$rootDN' -Filter * | Select-Object Name, DistinguishedName"
