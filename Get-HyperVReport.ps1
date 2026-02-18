#Requires -RunAsAdministrator
#Requires -Modules Hyper-V

<#
.SYNOPSIS
Coleta inventário completo de ambiente Hyper-V e gera relatórios em Markdown e HTML.

.DESCRIPTION
Script PowerShell para documentar ambientes Hyper-V em clientes. Coleta dados de hosts,
VMs, switches virtuais, VHDs e snapshots. Gera relatórios em Markdown e HTML self-contained
com CSS inline pronto para impressão.

.PARAMETER OutputPath
Diretório de saída para os relatórios. Padrão: diretório atual.

.EXAMPLE
.\Get-HyperVReport.ps1

.EXAMPLE
.\Get-HyperVReport.ps1 -OutputPath "C:\Reports"

.NOTES
Requer execução como administrador em servidor Windows Server 2019+
com Hyper-V habilitado.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Get-Location).Path
)

# ============================================================================
# FUNÇÕES AUXILIARES
# ============================================================================

function Format-Bytes {
    <#
    .SYNOPSIS
    Converte bytes para formato legível (GB/TB)
    #>
    param([long]$Bytes)
    
    if ($null -eq $Bytes -or $Bytes -eq 0) {
        return "0 B"
    }
    
    $sizes = @("B", "KB", "MB", "GB", "TB", "PB")
    $order = 0
    
    while ($Bytes -ge 1024 -and $order -lt $sizes.Count - 1) {
        $order++
        $Bytes = $Bytes / 1024
    }
    
    return "{0:N2} {1}" -f $Bytes, $sizes[$order]
}

function Format-Uptime {
    <#
    .SYNOPSIS
    Formata TimeSpan em formato legível (ex: "45d 12:30")
    #>
    param([TimeSpan]$Uptime)
    
    if ($null -eq $Uptime) {
        return "N/A"
    }
    
    $days = $Uptime.Days
    $hours = $Uptime.Hours
    $minutes = $Uptime.Minutes
    
    if ($days -gt 0) {
        return "{0}d {1:00}:{2:00}" -f $days, $hours, $minutes
    }
    
    return "{0:00}:{1:00}" -f $hours, $minutes
}

function Get-SafeVHD {
    <#
    .SYNOPSIS
    Wrapper seguro para Get-VHD com tratamento de erro
    #>
    param([string]$Path)
    
    try {
        $vhd = Get-VHD -Path $Path -ErrorAction Stop
        return $vhd
    }
    catch {
        Write-Warning "VHD inacessível: $Path ($($_.Exception.Message))"
        return $null
    }
}

function ConvertTo-MarkdownTable {
    <#
    .SYNOPSIS
    Converte array de objetos para tabela Markdown
    #>
    param(
        [Parameter(ValueFromPipeline = $true)]
        [object[]]$InputObject,
        
        [string[]]$Columns
    )
    
    begin {
        $objects = @()
    }
    
    process {
        $objects += $InputObject
    }
    
    end {
        if ($objects.Count -eq 0) {
            return "| Sem dados |`n|---|"
        }
        
        # Se não especificar colunas, usa todas
        if (-not $Columns) {
            $Columns = $objects[0].PSObject.Properties.Name
        }
        
        # Cabeçalho
        $header = "| " + ($Columns -join " | ") + " |"
        $separator = "| " + (($Columns | ForEach-Object { "---" }) -join " | ") + " |"
        
        $lines = @($header, $separator)
        
        # Linhas de dados
        foreach ($obj in $objects) {
            $row = @()
            foreach ($col in $Columns) {
                $value = $obj.$col
                
                if ($null -eq $value) {
                    $value = ""
                }
                
                # Escape de caracteres especiais em Markdown
                $value = $value.ToString() -replace "\|", "\|" -replace "`"", "\`"" -replace "`n", " "
                
                $row += $value
            }
            
            $lines += "| " + ($row -join " | ") + " |"
        }
        
        return $lines -join "`n"
    }
}

function ConvertTo-HtmlTable {
    <#
    .SYNOPSIS
    Converte array de objetos para tabela HTML com classes CSS
    #>
    param(
        [Parameter(ValueFromPipeline = $true)]
        [object[]]$InputObject,
        
        [string[]]$Columns,
        
        [string]$TableClass = "data-table"
    )
    
    begin {
        $objects = @()
    }
    
    process {
        $objects += $InputObject
    }
    
    end {
        if ($objects.Count -eq 0) {
            return "<p><em>Sem dados</em></p>"
        }
        
        # Se não especificar colunas, usa todas
        if (-not $Columns) {
            $Columns = $objects[0].PSObject.Properties.Name
        }
        
        $html = @()
        $html += "<table class=`"$TableClass`">"
        $html += "<thead><tr>"
        
        foreach ($col in $Columns) {
            $html += "<th>$([System.Net.WebUtility]::HtmlEncode($col))</th>"
        }
        
        $html += "</tr></thead>"
        $html += "<tbody>"
        
        $rowNum = 0
        foreach ($obj in $objects) {
            $rowClass = if ($rowNum % 2 -eq 0) { "even" } else { "odd" }
            $html += "<tr class=`"$rowClass`">"
            
            foreach ($col in $Columns) {
                $value = $obj.$col
                
                if ($null -eq $value) {
                    $value = ""
                }
                
                $encodedValue = [System.Net.WebUtility]::HtmlEncode($value.ToString())
                $html += "<td>$encodedValue</td>"
            }
            
            $html += "</tr>"
            $rowNum++
        }
        
        $html += "</tbody></table>"
        
        return $html -join "`n"
    }
}

function Get-StatusBadge {
    <#
    .SYNOPSIS
    Retorna badge HTML de status com cor
    #>
    param(
        [string]$Status,
        [switch]$Html
    )
    
    $colors = @{
        "Running" = "#28a745"
        "Off"     = "#dc3545"
        "Paused"  = "#ffc107"
        "Saved"   = "#17a2b8"
    }
    
    $color = if ($null -eq $colors[$Status]) { "#6c757d" } else { $colors[$Status] }
    
    if ($Html) {
        return "<span class='badge' style='background-color: $color; color: white; padding: 3px 8px; border-radius: 3px; font-size: 0.85em;'>$Status</span>"
    }
    else {
        return $Status
    }
}

# ============================================================================
# FASE 1: PREFLIGHT
# ============================================================================

Write-Host "[1/5] Executando validações preflight..." -ForegroundColor Cyan

# Validar e criar OutputPath se necessário
if (-not (Test-Path $OutputPath -PathType Container)) {
    Write-Host "  - Criando diretório: $OutputPath" -ForegroundColor Gray
    try {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    catch {
        Write-Error "Não foi possível criar OutputPath: $OutputPath ($_)"
        exit 1
    }
}

Write-Host "✓ OutputPath validado: $OutputPath" -ForegroundColor Green

# ============================================================================
# FASE 2: COLETA DE DADOS
# ============================================================================

Write-Host "[2/5] Coletando dados do ambiente Hyper-V..." -ForegroundColor Cyan

# Dados do Host
Write-Host "  - Coletando informações do host..." -ForegroundColor Gray
$hostname = $env:COMPUTERNAME
$vmHost = Get-VMHost -ErrorAction SilentlyContinue
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
$processor = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1

$hostData = @{
    Hostname              = $hostname
    Domain                = if ($computerSystem.Domain) { $computerSystem.Domain } else { "WORKGROUP" }
    Fabricante            = if ($null -eq $computerSystem.Manufacturer) { "N/A" } else { $computerSystem.Manufacturer }
    Modelo                = if ($null -eq $computerSystem.Model) { "N/A" } else { $computerSystem.Model }
    OS                    = if ($null -eq $osInfo.Caption) { "N/A" } else { $osInfo.Caption }
    OSBuild               = if ($null -eq $osInfo.BuildNumber) { "N/A" } else { $osInfo.BuildNumber }
    CPUFísico             = if ($null -eq $processor.Name) { "N/A" } else { $processor.Name }
    RAMTotal              = Format-Bytes ($computerSystem.TotalPhysicalMemory)
    DefaultVirtualHDPath  = if ($null -eq $vmHost.VirtualMachinePath) { "N/A" } else { $vmHost.VirtualMachinePath }
    DefaultVHDPath        = if ($null -eq $vmHost.VirtualHardDiskPath) { "N/A" } else { $vmHost.VirtualHardDiskPath }
    DownloadedVMPath      = if ($null -eq $vmHost.VirtualMachineGroupPath) { "N/A" } else { $vmHost.VirtualMachineGroupPath }
    NumProcessorsLogicos  = $computerSystem.NumberOfLogicalProcessors
}

Write-Host "  ✓ Host coletado" -ForegroundColor Green

# Dados de VMs
Write-Host "  - Coletando informações de VMs..." -ForegroundColor Gray
$vms = Get-VM -ErrorAction SilentlyContinue | Sort-Object Name
$vmCount = $vms.Count
Write-Host "  ✓ $vmCount VMs encontradas" -ForegroundColor Green

# Dados de Switches
Write-Host "  - Coletando informações de switches virtuais..." -ForegroundColor Gray
$vmSwitches = Get-VMSwitch -ErrorAction SilentlyContinue | Sort-Object Name
$switchCount = $vmSwitches.Count
Write-Host "  ✓ $switchCount switches encontrados" -ForegroundColor Green

# Estrutura de dados para VMs com detalhes
$vmDetails = @()

foreach ($vm in $vms) {
    Write-Host "    - Processando VM: $($vm.Name)" -ForegroundColor DarkGray
    
    # Processador e memória
    $vmProcessor = Get-VMProcessor -VM $vm -ErrorAction SilentlyContinue
    $vcpu = $vmProcessor.Count
    
    $startupMemory = $vm.MemoryStartup
    $dynamicMemory = if ($vm.DynamicMemoryEnabled) { "Habilitada" } else { "Desabilitada" }
    $memoryMaximum = $vm.MemoryMaximum
    $memoryAssigned = $vm.MemoryAssigned
    
    # Uptime
    $uptime = if ($vm.State -eq "Running") {
        New-TimeSpan -Start $vm.CreationTime -End (Get-Date)
    } else {
        $null
    }
    
    # Discos (VHD)
    $disks = @()
    try {
        $vmDisks = Get-VMHardDiskDrive -VM $vm -ErrorAction SilentlyContinue
        
        foreach ($disk in $vmDisks) {
            $vhdInfo = Get-SafeVHD -Path $disk.Path
            
            if ($vhdInfo) {
                $diskObj = [PSCustomObject]@{
                    Controller = "$($disk.ControllerType) [$($disk.ControllerNumber):$($disk.ControllerLocation)]"
                    Path       = $disk.Path
                    Formato    = $vhdInfo.VhdFormat
                    Tipo       = $vhdInfo.VhdType
                    TamanhoMax = Format-Bytes $vhdInfo.Size
                    TamanhoPhy = Format-Bytes $vhdInfo.FileSize
                    PercentUso = if ($vhdInfo.Size -gt 0) { "{0:P1}" -f ($vhdInfo.FileSize / $vhdInfo.Size) } else { "0%" }
                }
            }
            else {
                $diskObj = [PSCustomObject]@{
                    Controller = "$($disk.ControllerType) [$($disk.ControllerNumber):$($disk.ControllerLocation)]"
                    Path       = $disk.Path
                    Formato    = "N/A"
                    Tipo       = "N/A"
                    TamanhoMax = "N/A"
                    TamanhoPhy = "N/A"
                    PercentUso = "N/A"
                }
            }
            
            $disks += $diskObj
        }
    }
    catch {
        Write-Warning "Erro ao coletar discos de $($vm.Name): $_"
    }
    
    if ($disks.Count -eq 0) {
        $disks = @([PSCustomObject]@{ Info = "(nenhum disco)" })
    }
    
    # NICs
    $nics = @()
    try {
        $vmNics = Get-VMNetworkAdapter -VM $vm -ErrorAction SilentlyContinue
        
        foreach ($nic in $vmNics) {
            $nicObj = [PSCustomObject]@{
                Nome         = $nic.Name
                Endereço     = if ($nic.IPAddresses) { $nic.IPAddresses[0] } else { "(VM desligada)" }
                Switch       = if ($null -eq $nic.SwitchName) { "Desconectado" } else { $nic.SwitchName }
                MACAddress   = $nic.MacAddress
                VLANId       = if ($nic.VlanSetting.AccessVlanId) { $nic.VlanSetting.AccessVlanId } else { "Nenhuma" }
                Status       = $nic.Status
            }
            
            $nics += $nicObj
        }
    }
    catch {
        Write-Warning "Erro ao coletar NICs de $($vm.Name): $_"
    }
    
    if ($nics.Count -eq 0) {
        $nics = @([PSCustomObject]@{ Info = "(nenhuma NIC)" })
    }
    
    # Snapshots
    $snapshots = @()
    try {
        $vmSnapshots = Get-VMSnapshot -VM $vm -ErrorAction SilentlyContinue | Sort-Object CreationTime -Descending
        
        foreach ($snapshot in $vmSnapshots) {
            $snapshotAge = New-TimeSpan -Start $snapshot.CreationTime -End (Get-Date)
            $ageAlert = if ($snapshotAge.TotalDays -gt 7) { " ⚠ ANTIGO" } else { "" }
            
            $snapshotObj = [PSCustomObject]@{
                Nome       = $snapshot.Name
                Tipo       = $snapshot.SnapshotType
                Criado     = $snapshot.CreationTime.ToString("yyyy-MM-dd HH:mm")
                Idade      = "{0}d {1:00}h{2}" -f $snapshotAge.Days, $snapshotAge.Hours, $ageAlert
                Parent     = if ($null -eq $snapshot.ParentSnapshotName) { "(root)" } else { $snapshot.ParentSnapshotName }
            }
            
            $snapshots += $snapshotObj
        }
    }
    catch {
        Write-Warning "Erro ao coletar snapshots de $($vm.Name): $_"
    }
    
    # Objeto consolidado de VM
    $vmDetailObj = [PSCustomObject]@{
        Nome                = $vm.Name
        Estado              = $vm.State
        Geração             = $vm.Generation
        vCPUs               = $vcpu
        RAM_Startup         = Format-Bytes $startupMemory
        RAM_Dinâmica        = $dynamicMemory
        RAM_Máxima          = Format-Bytes $memoryMaximum
        RAM_Atribuída       = if ($vm.State -eq "Running") { Format-Bytes $memoryAssigned } else { "-" }
        Uptime              = Format-Uptime $uptime
        Discos              = $disks
        NICs                = $nics
        Snapshots           = $snapshots
    }
    
    $vmDetails += $vmDetailObj
}

# Inventário de VHDs (todos do host)
Write-Host "  - Coletando inventário de VHDs..." -ForegroundColor Gray
$allVHDs = @()
$vhdPaths = @()

# Coletar paths de VHDs de todas as VMs
foreach ($vm in $vms) {
    try {
        $vmDisks = Get-VMHardDiskDrive -VM $vm -ErrorAction SilentlyContinue
        $vhdPaths += $vmDisks.Path
    }
    catch {
        Write-Warning "Erro ao coletar paths de VHD de $($vm.Name): $_"
    }
}

# Remover duplicatas
$vhdPaths = @($vhdPaths | Sort-Object -Unique)

foreach ($vhdPath in $vhdPaths) {
    $vhd = Get-SafeVHD -Path $vhdPath
    
    if ($vhd) {
        $vhdObj = [PSCustomObject]@{
            Path       = $vhd.Path
            Formato    = $vhd.VhdFormat
            Tipo       = $vhd.VhdType
            TamanhoMax = Format-Bytes $vhd.Size
            TamanhoPhy = Format-Bytes $vhd.FileSize
            PercentUso = if ($vhd.Size -gt 0) { "{0:P1}" -f ($vhd.FileSize / $vhd.Size) } else { "0%" }
        }
        
        $allVHDs += $vhdObj
    }
}

Write-Host "  ✓ Inventário completo coletado" -ForegroundColor Green

# ============================================================================
# FASE 3: GERAÇÃO MARKDOWN
# ============================================================================

Write-Host "[3/5] Gerando relatório Markdown..." -ForegroundColor Cyan

$timestamp = Get-Date -Format "yyyy-MM-dd"
$reportName = "HyperV-Report_$hostname`_$timestamp"
$mdPath = Join-Path $OutputPath "$reportName.md"

$mdContent = @()
$mdContent += "# Relatório Hyper-V - $hostname"
$mdContent += ""
$mdContent += "**Data de Geração:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$mdContent += ""
$mdContent += "---"
$mdContent += ""
$mdContent += "## 1. Informações do Host"
$mdContent += ""

# Tabela de informações do host
$hostTable = $hostData.GetEnumerator() | ForEach-Object {
    [PSCustomObject]@{
        Propriedade = $_.Key
        Valor       = $_.Value
    }
}

$mdContent += ConvertTo-MarkdownTable $hostTable -Columns @("Propriedade", "Valor")
$mdContent += ""

# Seção de VMs - Resumo
$mdContent += "## 2. Máquinas Virtuais - Resumo"
$mdContent += ""
$mdContent += "**Total de VMs:** $vmCount"
$mdContent += ""

if ($vmCount -gt 0) {
    $vmSummary = $vmDetails | ForEach-Object {
        [PSCustomObject]@{
            Nome         = $_.Nome
            Estado       = $_.Estado
            Geração      = $_.Geração
            vCPUs        = $_.vCPUs
            RAM_Startup  = $_.RAM_Startup
            Uptime       = $_.Uptime
        }
    }
    
    $mdContent += ConvertTo-MarkdownTable $vmSummary -Columns @("Nome", "Estado", "Geração", "vCPUs", "RAM_Startup", "Uptime")
    $mdContent += ""
}

# Seção de VMs - Detalhes
$mdContent += "## 3. Máquinas Virtuais - Detalhes"
$mdContent += ""

foreach ($vmDetail in $vmDetails) {
    $mdContent += "### $($vmDetail.Nome)"
    $mdContent += ""
    
    # Info geral
    $vmInfo = [PSCustomObject]@{
        Propriedade = @(
            "Estado",
            "Geração",
            "vCPUs",
            "RAM Startup",
            "RAM Dinâmica",
            "RAM Máxima",
            "RAM Atribuída",
            "Uptime"
        )
        Valor       = @(
            $vmDetail.Estado,
            $vmDetail.Geração,
            $vmDetail.vCPUs,
            $vmDetail.RAM_Startup,
            $vmDetail.RAM_Dinâmica,
            $vmDetail.RAM_Máxima,
            $vmDetail.RAM_Atribuída,
            $vmDetail.Uptime
        )
    }
    
    $mdContent += "#### Informações Gerais"
    $mdContent += ""
    $mdContent += ConvertTo-MarkdownTable $vmInfo -Columns @("Propriedade", "Valor")
    $mdContent += ""
    
    # Discos
    $mdContent += "#### Discos"
    $mdContent += ""
    if ($vmDetail.Discos[0].Info) {
        $mdContent += $vmDetail.Discos[0].Info
    }
    else {
        $mdContent += ConvertTo-MarkdownTable $vmDetail.Discos -Columns @("Controller", "Path", "Formato", "Tipo", "TamanhoMax", "TamanhoPhy", "PercentUso")
    }
    $mdContent += ""
    
    # NICs
    $mdContent += "#### Adaptadores de Rede"
    $mdContent += ""
    if ($vmDetail.NICs[0].Info) {
        $mdContent += $vmDetail.NICs[0].Info
    }
    else {
        $mdContent += ConvertTo-MarkdownTable $vmDetail.NICs -Columns @("Nome", "Endereço", "Switch", "MACAddress", "VLANId", "Status")
    }
    $mdContent += ""
    
    # Snapshots
    if ($vmDetail.Snapshots.Count -gt 0) {
        $mdContent += "#### Snapshots"
        $mdContent += ""
        
        if ($vmDetail.Snapshots[0].Info) {
            $mdContent += $vmDetail.Snapshots[0].Info
        }
        else {
            $mdContent += ConvertTo-MarkdownTable $vmDetail.Snapshots -Columns @("Nome", "Tipo", "Criado", "Idade", "Parent")
            
            # Alerta de snapshots antigos
            $oldSnapshots = $vmDetail.Snapshots | Where-Object { $_ -match "⚠ ANTIGO" }
            if ($oldSnapshots.Count -gt 0) {
                $mdContent += ""
                $mdContent += "> ⚠ **AVISO:** Snapshots com mais de 7 dias detectados. Considere remover para liberar espaço."
            }
        }
        $mdContent += ""
    }
    
    $mdContent += ""
}

# Seção de Switches
$mdContent += "## 4. Switches Virtuais"
$mdContent += ""
$mdContent += "**Total de Switches:** $switchCount"
$mdContent += ""

if ($switchCount -gt 0) {
    $switchSummary = $vmSwitches | ForEach-Object {
        [PSCustomObject]@{
            Nome           = $_.Name
            Tipo           = $_.SwitchType
            Adaptador      = if ($null -eq $_.NetAdapterInterfaceDescription) { "N/A" } else { $_.NetAdapterInterfaceDescription }
            AllowMgmtOS    = $_.AllowManagementOS
            IOV            = $_.IOVSupport
        }
    }
    
    $mdContent += ConvertTo-MarkdownTable $switchSummary -Columns @("Nome", "Tipo", "Adaptador", "AllowMgmtOS", "IOV")
    $mdContent += ""
}

# Seção de Inventário de VHDs
$mdContent += "## 5. Inventário de VHDs"
$mdContent += ""

if ($allVHDs.Count -gt 0) {
    $mdContent += ConvertTo-MarkdownTable $allVHDs -Columns @("Path", "Formato", "Tipo", "TamanhoMax", "TamanhoPhy", "PercentUso")
    $mdContent += ""
    
    # Totais
    $totalVHDs = $allVHDs.Count
    $mdContent += "**Resumo:**"
    $mdContent += "- Total de VHDs: $totalVHDs"
    $mdContent += ""
}
else {
    $mdContent += "Nenhum VHD encontrado."
    $mdContent += ""
}

# Rodapé
$mdContent += "---"
$mdContent += ""
$mdContent += "*Relatório gerado automaticamente por Get-HyperVReport.ps1*"
$mdContent += ""

# Salvar Markdown
$mdContent | Out-File -FilePath $mdPath -Encoding UTF8 -Force
Write-Host "✓ Relatório Markdown criado: $mdPath" -ForegroundColor Green

# ============================================================================
# FASE 4: GERAÇÃO HTML
# ============================================================================

Write-Host "[4/5] Gerando relatório HTML..." -ForegroundColor Cyan

$htmlPath = Join-Path $OutputPath "$reportName.html"

$htmlHeader = @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Relatório Hyper-V - $hostname</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            background: #f5f5f5;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            padding: 40px;
        }
        
        h1 {
            color: #0078D4;
            border-bottom: 3px solid #0078D4;
            padding-bottom: 10px;
            margin-bottom: 20px;
            font-size: 2em;
        }
        
        h2 {
            color: #0078D4;
            margin-top: 30px;
            margin-bottom: 15px;
            font-size: 1.5em;
            border-left: 4px solid #0078D4;
            padding-left: 10px;
        }
        
        h3 {
            color: #005A9E;
            margin-top: 20px;
            margin-bottom: 10px;
            font-size: 1.2em;
        }
        
        h4 {
            color: #666;
            margin-top: 15px;
            margin-bottom: 8px;
            font-size: 1em;
            font-weight: 600;
        }
        
        .metadata {
            background: #f0f8ff;
            border-left: 4px solid #0078D4;
            padding: 10px 15px;
            margin-bottom: 20px;
            border-radius: 4px;
        }
        
        .data-table {
            width: 100%;
            border-collapse: collapse;
            margin: 15px 0;
            font-size: 0.95em;
        }
        
        .data-table th {
            background: #0078D4;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            border: 1px solid #0078D4;
        }
        
        .data-table td {
            padding: 10px 12px;
            border: 1px solid #ddd;
        }
        
        .data-table tr.even {
            background: #f9f9f9;
        }
        
        .data-table tr.odd {
            background: white;
        }
        
        .data-table tbody tr:hover {
            background: #f0f8ff;
            transition: background 0.2s;
        }
        
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 0.85em;
            font-weight: 600;
            color: white;
        }
        
        .badge-running {
            background: #28a745;
        }
        
        .badge-off {
            background: #dc3545;
        }
        
        .badge-paused {
            background: #ffc107;
            color: #333;
        }
        
        .badge-saved {
            background: #17a2b8;
        }
        
        .alert {
            padding: 15px;
            margin: 15px 0;
            border-radius: 4px;
            border-left: 4px solid;
        }
        
        .alert-warning {
            background: #fff3cd;
            border-color: #ffc107;
            color: #856404;
        }
        
        .summary {
            background: #f0f8ff;
            padding: 15px;
            border-radius: 4px;
            margin: 15px 0;
            border-left: 4px solid #0078D4;
        }
        
        .summary-item {
            margin: 8px 0;
        }
        
        .summary-item strong {
            color: #0078D4;
        }
        
        footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            text-align: center;
            color: #666;
            font-size: 0.9em;
        }
        
        @media print {
            body {
                background: white;
                padding: 0;
            }
            
            .container {
                max-width: 100%;
                box-shadow: none;
                padding: 0;
            }
            
            h1, h2 {
                page-break-after: avoid;
            }
            
            .data-table {
                page-break-inside: avoid;
            }
        }
    </style>
</head>
<body>
    <div class="container">
"@

$htmlFooter = @"
        <footer>
            <p><em>Relatório gerado automaticamente por Get-HyperVReport.ps1 em $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</em></p>
        </footer>
    </div>
</body>
</html>
"@

$htmlBody = @()

# Título e metadata
$htmlBody += "<h1>Relatório Hyper-V - $hostname</h1>"
$htmlBody += "<div class='metadata'><strong>Data de Geração:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</div>"

# Seção 1: Host
$htmlBody += "<h2>1. Informações do Host</h2>"

$hostTable = $hostData.GetEnumerator() | ForEach-Object {
    [PSCustomObject]@{
        Propriedade = $_.Key
        Valor       = $_.Value
    }
}

$htmlBody += ConvertTo-HtmlTable $hostTable -Columns @("Propriedade", "Valor")

# Seção 2: Resumo de VMs
$htmlBody += "<h2>2. Máquinas Virtuais - Resumo</h2>"
$htmlBody += "<div class='summary'><div class='summary-item'><strong>Total de VMs:</strong> $vmCount</div></div>"

if ($vmCount -gt 0) {
    $vmSummary = $vmDetails | ForEach-Object {
        [PSCustomObject]@{
            Nome         = $_.Nome
            Estado       = (Get-StatusBadge $_.Estado -Html)
            Geração      = $_.Geração
            vCPUs        = $_.vCPUs
            RAM_Startup  = $_.RAM_Startup
            Uptime       = $_.Uptime
        }
    }
    
    $htmlBody += ConvertTo-HtmlTable $vmSummary -Columns @("Nome", "Estado", "Geração", "vCPUs", "RAM_Startup", "Uptime")
}

# Seção 3: Detalhes de VMs
$htmlBody += "<h2>3. Máquinas Virtuais - Detalhes</h2>"

foreach ($vmDetail in $vmDetails) {
    $htmlBody += "<h3>$($vmDetail.Nome)</h3>"
    
    # Info geral
    $vmInfo = [PSCustomObject]@{
        Propriedade = @(
            "Estado",
            "Geração",
            "vCPUs",
            "RAM Startup",
            "RAM Dinâmica",
            "RAM Máxima",
            "RAM Atribuída",
            "Uptime"
        )
        Valor       = @(
            (Get-StatusBadge $vmDetail.Estado -Html),
            $vmDetail.Geração,
            $vmDetail.vCPUs,
            $vmDetail.RAM_Startup,
            $vmDetail.RAM_Dinâmica,
            $vmDetail.RAM_Máxima,
            $vmDetail.RAM_Atribuída,
            $vmDetail.Uptime
        )
    }
    
    $htmlBody += "<h4>Informações Gerais</h4>"
    $htmlBody += ConvertTo-HtmlTable $vmInfo -Columns @("Propriedade", "Valor")
    
    # Discos
    $htmlBody += "<h4>Discos</h4>"
    if ($vmDetail.Discos[0].Info) {
        $htmlBody += "<p><em>$($vmDetail.Discos[0].Info)</em></p>"
    }
    else {
        $htmlBody += ConvertTo-HtmlTable $vmDetail.Discos -Columns @("Controller", "Path", "Formato", "Tipo", "TamanhoMax", "TamanhoPhy", "PercentUso")
    }
    
    # NICs
    $htmlBody += "<h4>Adaptadores de Rede</h4>"
    if ($vmDetail.NICs[0].Info) {
        $htmlBody += "<p><em>$($vmDetail.NICs[0].Info)</em></p>"
    }
    else {
        $htmlBody += ConvertTo-HtmlTable $vmDetail.NICs -Columns @("Nome", "Endereço", "Switch", "MACAddress", "VLANId", "Status")
    }
    
    # Snapshots
    if ($vmDetail.Snapshots.Count -gt 0) {
        $htmlBody += "<h4>Snapshots</h4>"
        
        if ($vmDetail.Snapshots[0].Info) {
            $htmlBody += "<p><em>$($vmDetail.Snapshots[0].Info)</em></p>"
        }
        else {
            $htmlBody += ConvertTo-HtmlTable $vmDetail.Snapshots -Columns @("Nome", "Tipo", "Criado", "Idade", "Parent")
            
            $oldSnapshots = $vmDetail.Snapshots | Where-Object { $_ -match "⚠ ANTIGO" }
            if ($oldSnapshots.Count -gt 0) {
                $htmlBody += "<div class='alert alert-warning'>⚠ <strong>AVISO:</strong> Snapshots com mais de 7 dias detectados. Considere remover para liberar espaço.</div>"
            }
        }
    }
}

# Seção 4: Switches
$htmlBody += "<h2>4. Switches Virtuais</h2>"
$htmlBody += "<div class='summary'><div class='summary-item'><strong>Total de Switches:</strong> $switchCount</div></div>"

if ($switchCount -gt 0) {
    $switchSummary = $vmSwitches | ForEach-Object {
        [PSCustomObject]@{
            Nome           = $_.Name
            Tipo           = $_.SwitchType
            Adaptador      = if ($null -eq $_.NetAdapterInterfaceDescription) { "N/A" } else { $_.NetAdapterInterfaceDescription }
            AllowMgmtOS    = $_.AllowManagementOS
            IOV            = $_.IOVSupport
        }
    }
    
    $htmlBody += ConvertTo-HtmlTable $switchSummary -Columns @("Nome", "Tipo", "Adaptador", "AllowMgmtOS", "IOV")
}

# Seção 5: Inventário de VHDs
$htmlBody += "<h2>5. Inventário de VHDs</h2>"

if ($allVHDs.Count -gt 0) {
    $htmlBody += ConvertTo-HtmlTable $allVHDs -Columns @("Path", "Formato", "Tipo", "TamanhoMax", "TamanhoPhy", "PercentUso")
    
    $htmlBody += "<div class='summary'>"
    $htmlBody += "<div class='summary-item'><strong>Total de VHDs:</strong> $($allVHDs.Count)</div>"
    $htmlBody += "</div>"
}
else {
    $htmlBody += "<p><em>Nenhum VHD encontrado.</em></p>"
}

# Combinar e salvar HTML
$htmlFinal = $htmlHeader + ($htmlBody -join "`n") + $htmlFooter
$htmlFinal | Out-File -FilePath $htmlPath -Encoding UTF8 -Force

Write-Host "✓ Relatório HTML criado: $htmlPath" -ForegroundColor Green

# ============================================================================
# FASE 5: SAÍDA
# ============================================================================

Write-Host "[5/5] Finalizando..." -ForegroundColor Cyan
Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "RELATÓRIO GERADO COM SUCESSO" -ForegroundColor Green
Write-Host "=" * 70
Write-Host ""
Write-Host "Arquivos gerados:" -ForegroundColor Yellow
Write-Host "  📄 Markdown: $mdPath"
Write-Host "  🌐 HTML:     $htmlPath"
Write-Host ""
Write-Host "Resumo da coleta:" -ForegroundColor Yellow
Write-Host "  • Host:       $hostname"
Write-Host "  • VMs:        $vmCount"
Write-Host "  • Switches:   $switchCount"
Write-Host "  • VHDs:       $($allVHDs.Count)"
Write-Host ""
Write-Host "✓ Processo concluído em $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""
