#Requires -RunAsAdministrator
#Requires -Modules Hyper-V

<#
.SYNOPSIS
    Gera documentacao completa do ambiente Hyper-V local.
.DESCRIPTION
    Coleta informacoes do host, VMs, virtual switches, discos virtuais e
    snapshots/checkpoints. Gera relatorios em Markdown (.md) e HTML.
    Nao faz nenhuma alteracao no ambiente - apenas leitura.
.PARAMETER OutputPath
    Diretorio para salvar os relatorios. Padrao: diretorio atual.
.EXAMPLE
    .\Get-HyperVReport.ps1
.EXAMPLE
    .\Get-HyperVReport.ps1 -OutputPath C:\Relatorios
.EXAMPLE
    PowerShell -ExecutionPolicy Bypass -File .\Get-HyperVReport.ps1
#>
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Diretorio para salvar os relatorios.")]
    [string]$OutputPath = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# ============================================================
# FUNCOES AUXILIARES
# ============================================================

function Format-Bytes {
    param([long]$Bytes)
    if ($Bytes -le 0) { return '-' }
    if ($Bytes -ge 1TB) { return '{0:N2} TB' -f ($Bytes / 1TB) }
    if ($Bytes -ge 1GB) { return '{0:N2} GB' -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return '{0:N2} MB' -f ($Bytes / 1MB) }
    return '{0:N2} KB' -f ($Bytes / 1KB)
}

function Format-Uptime {
    param([TimeSpan]$Uptime)
    if ($Uptime.TotalSeconds -lt 1) { return '-' }
    if ($Uptime.Days -gt 0) {
        return '{0}d {1:D2}:{2:D2}' -f $Uptime.Days, $Uptime.Hours, $Uptime.Minutes
    }
    return '{0:D2}:{1:D2}:{2:D2}' -f $Uptime.Hours, $Uptime.Minutes, $Uptime.Seconds
}

function Get-SafeVHD {
    param([string]$Path)
    try {
        return Get-VHD -Path $Path -ErrorAction Stop
    }
    catch {
        Write-Warning "Nao foi possivel ler VHD '$Path': $($_.Exception.Message)"
        return [PSCustomObject]@{
            Path      = $Path
            VhdFormat = 'Erro'
            VhdType   = 'Erro'
            Size      = 0
            FileSize  = 0
        }
    }
}

function Escape-Markdown {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '' }
    return $Text.Replace('|', '\|').Replace('`', '\`')
}

function ConvertTo-MarkdownTable {
    param(
        [Parameter(Mandatory)]
        [array]$Data,
        [Parameter(Mandatory)]
        [string[]]$Columns,
        [Parameter(Mandatory)]
        [string[]]$Properties
    )

    if ($Data.Count -eq 0) { return '' }

    $header = '| ' + ($Columns -join ' | ') + ' |'
    $separator = '|' + (($Columns | ForEach-Object { '---' }) -join '|') + '|'

    $rows = foreach ($item in $Data) {
        $cells = foreach ($prop in $Properties) {
            $val = $item.$prop
            if ($null -eq $val) { '' } else { Escape-Markdown ([string]$val) }
        }
        '| ' + ($cells -join ' | ') + ' |'
    }

    return ($header, $separator, ($rows -join "`n")) -join "`n"
}

function ConvertTo-HtmlTable {
    param(
        [Parameter(Mandatory)]
        [array]$Data,
        [Parameter(Mandatory)]
        [string[]]$Columns,
        [Parameter(Mandatory)]
        [string[]]$Properties
    )

    if ($Data.Count -eq 0) { return '<p><em>Nenhum item encontrado.</em></p>' }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('<table>')
    [void]$sb.AppendLine('<thead><tr>')
    foreach ($col in $Columns) {
        [void]$sb.AppendLine("  <th>$([System.Web.HttpUtility]::HtmlEncode($col))</th>")
    }
    [void]$sb.AppendLine('</tr></thead>')
    [void]$sb.AppendLine('<tbody>')

    foreach ($item in $Data) {
        [void]$sb.Append('<tr>')
        foreach ($prop in $Properties) {
            $val = if ($null -eq $item.$prop) { '' } else { [string]$item.$prop }
            $class = ''
            if ($prop -eq 'State' -or $prop -eq 'Estado') {
                switch -Wildcard ($val) {
                    '*Running*' { $class = ' class="status-running"' }
                    '*Off*'     { $class = ' class="status-off"' }
                    '*Saved*'   { $class = ' class="status-saved"' }
                    '*Paused*'  { $class = ' class="status-saved"' }
                }
            }
            [void]$sb.Append("<td$class>$([System.Web.HttpUtility]::HtmlEncode($val))</td>")
        }
        [void]$sb.AppendLine('</tr>')
    }

    [void]$sb.AppendLine('</tbody>')
    [void]$sb.AppendLine('</table>')
    return $sb.ToString()
}

# ============================================================
# FASE 1: PREFLIGHT
# ============================================================

Write-Host '================================================' -ForegroundColor Cyan
Write-Host '  Get-HyperVReport - Documentacao Hyper-V' -ForegroundColor Cyan
Write-Host '================================================' -ForegroundColor Cyan
Write-Host ''

# Carregar System.Web para HtmlEncode
Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue

if (-not (Test-Path $OutputPath -PathType Container)) {
    try {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-Host "[OK] Diretorio de saida criado: $OutputPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Nao foi possivel criar o diretorio de saida: $OutputPath"
        exit 1
    }
}

$reportDate = Get-Date -Format 'yyyy-MM-dd'
$reportDateTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$hostName = $env:COMPUTERNAME
$baseName = "HyperV-Report_${hostName}_${reportDate}"
$mdFile = Join-Path $OutputPath "$baseName.md"
$htmlFile = Join-Path $OutputPath "$baseName.html"

Write-Host "[INFO] Host: $hostName" -ForegroundColor Yellow
Write-Host "[INFO] Data: $reportDateTime" -ForegroundColor Yellow
Write-Host "[INFO] Saida: $OutputPath" -ForegroundColor Yellow
Write-Host ''

# ============================================================
# FASE 2: COLETA DE DADOS
# ============================================================

Write-Host 'Coletando dados...' -ForegroundColor Cyan

# --- Host ---
Write-Host '  [1/5] Informacoes do host...' -ForegroundColor Gray
$vmHost = Get-VMHost
$osInfo = Get-CimInstance Win32_OperatingSystem
$compInfo = Get-CimInstance Win32_ComputerSystem
$cpuInfo = @(Get-CimInstance Win32_Processor)

$hostData = [ordered]@{
    'Nome do Computador'      = $hostName
    'Dominio'                 = $compInfo.Domain
    'Fabricante / Modelo'     = "$($compInfo.Manufacturer) $($compInfo.Model)".Trim()
    'Sistema Operacional'     = "$($osInfo.Caption) (Build $($osInfo.BuildNumber))"
    'Processador(es) Fisico(s)' = ($cpuInfo | ForEach-Object {
        "$($_.Name.Trim()) ($($_.NumberOfCores) cores, $($_.NumberOfLogicalProcessors) threads)"
    }) -join '; '
    'RAM Fisica Total'        = Format-Bytes $compInfo.TotalPhysicalMemory
    'Processadores Logicos (Hyper-V)' = $vmHost.LogicalProcessorCount
    'Caminho Padrao VHD'      = $vmHost.VirtualHardDiskPath
    'Caminho Padrao VM'       = $vmHost.VirtualMachinePath
    'Live Migration'          = if ($vmHost.VirtualMachineMigrationEnabled) { 'Habilitado' } else { 'Desabilitado' }
    'NUMA Spanning'           = if ($vmHost.NumaSpanningEnabled) { 'Habilitado' } else { 'Desabilitado' }
}

# --- VMs ---
Write-Host '  [2/5] Maquinas virtuais...' -ForegroundColor Gray
$allVMs = @(Get-VM)

$vmDetails = foreach ($vm in $allVMs) {
    $disks = @(Get-VMHardDiskDrive -VM $vm -ErrorAction SilentlyContinue)
    $nics  = @(Get-VMNetworkAdapter -VM $vm -ErrorAction SilentlyContinue)
    $proc  = Get-VMProcessor -VM $vm -ErrorAction SilentlyContinue

    $vhdInfos = foreach ($disk in $disks) {
        if ($disk.Path) {
            $vhd = Get-SafeVHD -Path $disk.Path
            [PSCustomObject]@{
                Controller  = "$($disk.ControllerType) $($disk.ControllerNumber)"
                Location    = $disk.ControllerLocation
                Path        = $disk.Path
                VhdFormat   = $vhd.VhdFormat
                VhdType     = $vhd.VhdType
                MaxSize     = Format-Bytes $vhd.Size
                CurrentSize = Format-Bytes $vhd.FileSize
                RawSize     = $vhd.Size
                RawFileSize = $vhd.FileSize
            }
        }
        elseif ($null -ne $disk.DiskNumber) {
            [PSCustomObject]@{
                Controller  = "$($disk.ControllerType) $($disk.ControllerNumber)"
                Location    = $disk.ControllerLocation
                Path        = "Passthrough Disk #$($disk.DiskNumber)"
                VhdFormat   = 'Passthrough'
                VhdType     = 'Fisico'
                MaxSize     = '-'
                CurrentSize = '-'
                RawSize     = 0
                RawFileSize = 0
            }
        }
    }

    $nicInfos = foreach ($nic in $nics) {
        $ips = if ($nic.IPAddresses -and $nic.IPAddresses.Count -gt 0) {
            ($nic.IPAddresses | Where-Object { $_ -notmatch ':' } | Select-Object -First 3) -join ', '
        }
        elseif ($vm.State -ne 'Running') {
            '(VM desligada)'
        }
        else {
            '(indisponivel)'
        }

        $vlanId = try {
            $vlanSetting = Get-VMNetworkAdapterVlan -VMNetworkAdapter $nic -ErrorAction Stop
            if ($vlanSetting.AccessVlanId -gt 0) { $vlanSetting.AccessVlanId } else { '-' }
        } catch { '-' }

        [PSCustomObject]@{
            Name      = $nic.Name
            Switch    = if ($nic.SwitchName) { $nic.SwitchName } else { '(nenhum)' }
            VLAN      = $vlanId
            MAC       = $nic.MacAddress
            IPs       = $ips
        }
    }

    [PSCustomObject]@{
        VM         = $vm
        Disks      = $disks
        VHDs       = $vhdInfos
        NICs       = $nicInfos
        vCPUs      = if ($proc) { $proc.Count } else { $vm.ProcessorCount }
    }
}

# Resumo de VMs
$vmSummary = foreach ($detail in $vmDetails) {
    $vm = $detail.VM
    [PSCustomObject]@{
        Nome        = $vm.Name
        Estado      = [string]$vm.State
        Geracao     = $vm.Generation
        vCPUs       = $detail.vCPUs
        'RAM Startup' = Format-Bytes $vm.MemoryStartup
        'Mem. Dinamica' = if ($vm.DynamicMemoryEnabled) { 'Sim' } else { 'Nao' }
        'RAM Atribuida' = if ($vm.State -eq 'Running') { Format-Bytes $vm.MemoryAssigned } else { '-' }
        Uptime      = Format-Uptime $vm.Uptime
    }
}

# --- Switches ---
Write-Host '  [3/5] Virtual Switches...' -ForegroundColor Gray
$allSwitches = @(Get-VMSwitch)

$switchSummary = foreach ($sw in $allSwitches) {
    $connectedVMs = @(Get-VMNetworkAdapter -All -ErrorAction SilentlyContinue |
        Where-Object { $_.SwitchName -eq $sw.Name -and $_.VMName } |
        Select-Object -ExpandProperty VMName -Unique)

    [PSCustomObject]@{
        Nome             = $sw.Name
        Tipo             = [string]$sw.SwitchType
        'Adaptador Fisico' = if ($sw.NetAdapterInterfaceDescription) { $sw.NetAdapterInterfaceDescription } else { '-' }
        'Mgmt OS'        = if ($sw.AllowManagementOS) { 'Sim' } else { 'Nao' }
        'Emb. Teaming'   = if ($sw.EmbeddedTeamingEnabled) { 'Sim' } else { 'Nao' }
        IOV              = if ($sw.IovEnabled) { 'Sim' } else { 'Nao' }
        'VMs Conectadas' = $connectedVMs.Count
    }
}

# --- VHDs consolidado ---
Write-Host '  [4/5] Discos virtuais...' -ForegroundColor Gray
$allVhdData = foreach ($detail in $vmDetails) {
    foreach ($vhd in $detail.VHDs) {
        if ($vhd) {
            [PSCustomObject]@{
                VM          = $detail.VM.Name
                Path        = $vhd.Path
                Formato     = $vhd.VhdFormat
                Tipo        = $vhd.VhdType
                'Tam. Maximo'  = $vhd.MaxSize
                'Tam. Atual'   = $vhd.CurrentSize
                'Uso %'     = if ($vhd.RawSize -gt 0) {
                    '{0:N1}%' -f (($vhd.RawFileSize / $vhd.RawSize) * 100)
                } else { '-' }
                RawSize     = $vhd.RawSize
                RawFileSize = $vhd.RawFileSize
            }
        }
    }
}

$totalProvisioned = ($allVhdData | Measure-Object -Property RawSize -Sum).Sum
$totalUsed = ($allVhdData | Measure-Object -Property RawFileSize -Sum).Sum

# --- Snapshots ---
Write-Host '  [5/5] Snapshots/Checkpoints...' -ForegroundColor Gray
$allSnapshots = @(Get-VM | Get-VMSnapshot -ErrorAction SilentlyContinue)

$snapshotData = foreach ($snap in $allSnapshots) {
    $age = ((Get-Date) - $snap.CreationTime).Days
    [PSCustomObject]@{
        VM        = $snap.VMName
        Nome      = $snap.Name
        Tipo      = [string]$snap.SnapshotType
        Criacao   = $snap.CreationTime.ToString('yyyy-MM-dd HH:mm')
        'Idade (dias)' = $age
        Parent    = if ($snap.ParentSnapshotName) { $snap.ParentSnapshotName } else { '-' }
    }
}

$oldSnapshots = @($allSnapshots | Where-Object { ((Get-Date) - $_.CreationTime).Days -gt 7 })

Write-Host ''
Write-Host 'Coleta concluida!' -ForegroundColor Green
Write-Host ''

# ============================================================
# FASE 3: GERACAO MARKDOWN
# ============================================================

Write-Host 'Gerando relatorio Markdown...' -ForegroundColor Cyan

$md = [System.Text.StringBuilder]::new()

[void]$md.AppendLine("# Relatorio Hyper-V: $hostName")
[void]$md.AppendLine('')
[void]$md.AppendLine("*Gerado em: $reportDateTime por Get-HyperVReport.ps1*")
[void]$md.AppendLine('')
[void]$md.AppendLine('---')
[void]$md.AppendLine('')

# Sumario
[void]$md.AppendLine('## Sumario')
[void]$md.AppendLine('')
[void]$md.AppendLine('1. [Informacoes do Host](#informacoes-do-host)')
[void]$md.AppendLine('2. [Resumo de Maquinas Virtuais](#resumo-de-maquinas-virtuais)')
[void]$md.AppendLine('3. [Detalhes por VM](#detalhes-por-vm)')
[void]$md.AppendLine('4. [Virtual Switches](#virtual-switches)')
[void]$md.AppendLine('5. [Discos Virtuais](#discos-virtuais)')
[void]$md.AppendLine('6. [Snapshots / Checkpoints](#snapshots--checkpoints)')
[void]$md.AppendLine('')
[void]$md.AppendLine('---')
[void]$md.AppendLine('')

# Host
[void]$md.AppendLine('## Informacoes do Host')
[void]$md.AppendLine('')
foreach ($key in $hostData.Keys) {
    [void]$md.AppendLine("- **${key}:** $($hostData[$key])")
}
[void]$md.AppendLine('')
[void]$md.AppendLine('---')
[void]$md.AppendLine('')

# VMs Resumo
[void]$md.AppendLine('## Resumo de Maquinas Virtuais')
[void]$md.AppendLine('')

if ($vmSummary.Count -eq 0) {
    [void]$md.AppendLine('*Nenhuma maquina virtual encontrada.*')
}
else {
    $running = @($allVMs | Where-Object State -eq 'Running').Count
    $off = @($allVMs | Where-Object State -eq 'Off').Count
    $other = $allVMs.Count - $running - $off
    $totalVCPU = ($vmDetails | Measure-Object -Property vCPUs -Sum).Sum
    $totalStartupRam = ($allVMs | Measure-Object -Property MemoryStartup -Sum).Sum

    [void]$md.AppendLine("**Totais:** $($allVMs.Count) VMs ($running Running, $off Off$(if($other -gt 0){", $other Outro(s)"})), $totalVCPU vCPUs alocadas, $(Format-Bytes $totalStartupRam) RAM startup")
    [void]$md.AppendLine('')

    $table = ConvertTo-MarkdownTable -Data $vmSummary `
        -Columns @('Nome', 'Estado', 'Ger.', 'vCPUs', 'RAM Startup', 'Mem. Din.', 'RAM Atrib.', 'Uptime') `
        -Properties @('Nome', 'Estado', 'Geracao', 'vCPUs', 'RAM Startup', 'Mem. Dinamica', 'RAM Atribuida', 'Uptime')
    [void]$md.AppendLine($table)
}

[void]$md.AppendLine('')
[void]$md.AppendLine('---')
[void]$md.AppendLine('')

# Detalhes por VM
[void]$md.AppendLine('## Detalhes por VM')
[void]$md.AppendLine('')

foreach ($detail in $vmDetails) {
    $vm = $detail.VM
    [void]$md.AppendLine("### $($vm.Name)")
    [void]$md.AppendLine('')

    # Config
    $dynInfo = if ($vm.DynamicMemoryEnabled) {
        "Sim (Min: $(Format-Bytes $vm.MemoryMinimum), Max: $(Format-Bytes $vm.MemoryMaximum))"
    } else { 'Nao' }

    [void]$md.AppendLine("- **Geracao:** $($vm.Generation) | **Versao:** $($vm.Version) | **vCPUs:** $($detail.vCPUs)")
    [void]$md.AppendLine("- **RAM Startup:** $(Format-Bytes $vm.MemoryStartup) | **Memoria Dinamica:** $dynInfo")
    [void]$md.AppendLine("- **Estado:** $($vm.State) | **Uptime:** $(Format-Uptime $vm.Uptime)")

    if ($vm.Notes) {
        $notes = Escape-Markdown ($vm.Notes.Trim())
        if ($notes.Length -gt 200) { $notes = $notes.Substring(0, 200) + '...' }
        [void]$md.AppendLine("- **Notas:** $notes")
    }
    [void]$md.AppendLine('')

    # Discos
    [void]$md.AppendLine('**Discos Virtuais:**')
    [void]$md.AppendLine('')
    if ($detail.VHDs -and @($detail.VHDs).Count -gt 0) {
        $diskTable = ConvertTo-MarkdownTable -Data @($detail.VHDs) `
            -Columns @('Controller', 'Loc.', 'Caminho', 'Formato', 'Tipo', 'Tam. Max', 'Tam. Atual') `
            -Properties @('Controller', 'Location', 'Path', 'VhdFormat', 'VhdType', 'MaxSize', 'CurrentSize')
        [void]$md.AppendLine($diskTable)
    }
    else {
        [void]$md.AppendLine('*(nenhum disco virtual anexado)*')
    }
    [void]$md.AppendLine('')

    # NICs
    [void]$md.AppendLine('**Adaptadores de Rede:**')
    [void]$md.AppendLine('')
    if ($detail.NICs -and @($detail.NICs).Count -gt 0) {
        $nicTable = ConvertTo-MarkdownTable -Data @($detail.NICs) `
            -Columns @('Nome', 'Switch', 'VLAN', 'MAC', 'IPs') `
            -Properties @('Name', 'Switch', 'VLAN', 'MAC', 'IPs')
        [void]$md.AppendLine($nicTable)
    }
    else {
        [void]$md.AppendLine('*(nenhum adaptador de rede configurado)*')
    }
    [void]$md.AppendLine('')
    [void]$md.AppendLine('---')
    [void]$md.AppendLine('')
}

# Switches
[void]$md.AppendLine('## Virtual Switches')
[void]$md.AppendLine('')

if ($switchSummary.Count -eq 0) {
    [void]$md.AppendLine('*Nenhum virtual switch encontrado.*')
}
else {
    $swTable = ConvertTo-MarkdownTable -Data $switchSummary `
        -Columns @('Nome', 'Tipo', 'Adaptador Fisico', 'Mgmt OS', 'Emb. Teaming', 'IOV', 'VMs Conectadas') `
        -Properties @('Nome', 'Tipo', 'Adaptador Fisico', 'Mgmt OS', 'Emb. Teaming', 'IOV', 'VMs Conectadas')
    [void]$md.AppendLine($swTable)
}

[void]$md.AppendLine('')
[void]$md.AppendLine('---')
[void]$md.AppendLine('')

# VHDs consolidado
[void]$md.AppendLine('## Discos Virtuais')
[void]$md.AppendLine('')

if ($allVhdData.Count -eq 0) {
    [void]$md.AppendLine('*Nenhum disco virtual encontrado.*')
}
else {
    [void]$md.AppendLine("**Totais:** $($allVhdData.Count) disco(s), $(Format-Bytes $totalProvisioned) provisionado, $(Format-Bytes $totalUsed) em uso")
    [void]$md.AppendLine('')

    $vhdTable = ConvertTo-MarkdownTable -Data $allVhdData `
        -Columns @('VM', 'Caminho', 'Formato', 'Tipo', 'Tam. Maximo', 'Tam. Atual', 'Uso %') `
        -Properties @('VM', 'Path', 'Formato', 'Tipo', 'Tam. Maximo', 'Tam. Atual', 'Uso %')
    [void]$md.AppendLine($vhdTable)
}

[void]$md.AppendLine('')
[void]$md.AppendLine('---')
[void]$md.AppendLine('')

# Snapshots
[void]$md.AppendLine('## Snapshots / Checkpoints')
[void]$md.AppendLine('')

if ($snapshotData.Count -eq 0) {
    [void]$md.AppendLine('*Nenhum snapshot/checkpoint encontrado. (Otimo!)*')
}
else {
    if ($oldSnapshots.Count -gt 0) {
        [void]$md.AppendLine("> **Atencao:** $($oldSnapshots.Count) snapshot(s) com mais de 7 dias. Snapshots antigos consomem disco e podem degradar a performance.")
        [void]$md.AppendLine('')
    }

    $snapTable = ConvertTo-MarkdownTable -Data $snapshotData `
        -Columns @('VM', 'Nome', 'Tipo', 'Criacao', 'Idade (dias)', 'Parent') `
        -Properties @('VM', 'Nome', 'Tipo', 'Criacao', 'Idade (dias)', 'Parent')
    [void]$md.AppendLine($snapTable)
}

[void]$md.AppendLine('')
[void]$md.AppendLine('---')
[void]$md.AppendLine('')
[void]$md.AppendLine('*Relatorio gerado por Get-HyperVReport.ps1 v1.0*')

# ============================================================
# FASE 4: GERACAO HTML
# ============================================================

Write-Host 'Gerando relatorio HTML...' -ForegroundColor Cyan

$cssStyle = @'
body {
    font-family: Segoe UI, Tahoma, Geneva, Verdana, sans-serif;
    margin: 20px 40px;
    color: #333;
    background: #fff;
    line-height: 1.6;
}
h1 {
    color: #0078D4;
    border-bottom: 3px solid #0078D4;
    padding-bottom: 10px;
}
h2 {
    color: #0078D4;
    border-bottom: 1px solid #ddd;
    padding-bottom: 5px;
    margin-top: 30px;
}
h3 { color: #444; margin-top: 25px; }
table {
    border-collapse: collapse;
    width: 100%;
    margin: 15px 0;
    font-size: 14px;
}
th {
    background-color: #0078D4;
    color: white;
    padding: 10px 12px;
    text-align: left;
}
td {
    padding: 8px 12px;
    border-bottom: 1px solid #ddd;
}
tr:nth-child(even) { background-color: #f2f6fa; }
tr:hover { background-color: #e0eaf5; }
.status-running { color: #107C10; font-weight: bold; }
.status-off { color: #D83B01; font-weight: bold; }
.status-saved { color: #CA5010; font-weight: bold; }
.warning {
    background: #FFF4CE;
    border-left: 4px solid #CA5010;
    padding: 10px 15px;
    margin: 15px 0;
}
.summary-box {
    background: #f0f6ff;
    border: 1px solid #0078D4;
    border-radius: 4px;
    padding: 12px 18px;
    margin: 15px 0;
}
.meta { color: #666; font-style: italic; font-size: 13px; }
dl { margin: 10px 0; }
dt { font-weight: bold; color: #555; float: left; width: 280px; clear: left; padding: 4px 0; }
dd { margin-left: 290px; padding: 4px 0; }
nav { margin: 15px 0; }
nav a { margin-right: 15px; color: #0078D4; text-decoration: none; }
nav a:hover { text-decoration: underline; }
@media print {
    body { margin: 0; }
    tr:hover { background-color: inherit; }
    h1, h2 { color: #333; }
    th { background-color: #666; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
}
'@

$html = [System.Text.StringBuilder]::new()

[void]$html.AppendLine('<!DOCTYPE html>')
[void]$html.AppendLine('<html lang="pt-BR">')
[void]$html.AppendLine('<head>')
[void]$html.AppendLine('  <meta charset="UTF-8">')
[void]$html.AppendLine('  <meta name="viewport" content="width=device-width, initial-scale=1.0">')
[void]$html.AppendLine("  <title>Relatorio Hyper-V - $hostName - $reportDate</title>")
[void]$html.AppendLine("  <style>$cssStyle</style>")
[void]$html.AppendLine('</head>')
[void]$html.AppendLine('<body>')
[void]$html.AppendLine('')

# Titulo
[void]$html.AppendLine("<h1>Relatorio Hyper-V: $hostName</h1>")
[void]$html.AppendLine("<p class=`"meta`">Gerado em: $reportDateTime</p>")

# Nav
[void]$html.AppendLine('<nav>')
[void]$html.AppendLine('  <a href="#host-info">Host</a>')
[void]$html.AppendLine('  <a href="#vm-summary">VMs</a>')
[void]$html.AppendLine('  <a href="#vm-details">Detalhes</a>')
[void]$html.AppendLine('  <a href="#switches">Switches</a>')
[void]$html.AppendLine('  <a href="#vhds">Discos</a>')
[void]$html.AppendLine('  <a href="#snapshots">Snapshots</a>')
[void]$html.AppendLine('</nav>')
[void]$html.AppendLine('')

# Host
[void]$html.AppendLine('<h2 id="host-info">Informacoes do Host</h2>')
[void]$html.AppendLine('<dl>')
foreach ($key in $hostData.Keys) {
    $val = [System.Web.HttpUtility]::HtmlEncode($hostData[$key])
    [void]$html.AppendLine("  <dt>$([System.Web.HttpUtility]::HtmlEncode($key))</dt><dd>$val</dd>")
}
[void]$html.AppendLine('</dl>')
[void]$html.AppendLine('')

# VMs Resumo
[void]$html.AppendLine('<h2 id="vm-summary">Resumo de Maquinas Virtuais</h2>')

if ($vmSummary.Count -eq 0) {
    [void]$html.AppendLine('<p><em>Nenhuma maquina virtual encontrada.</em></p>')
}
else {
    $running = @($allVMs | Where-Object State -eq 'Running').Count
    $off = @($allVMs | Where-Object State -eq 'Off').Count
    $other = $allVMs.Count - $running - $off
    $totalVCPU = ($vmDetails | Measure-Object -Property vCPUs -Sum).Sum
    $totalStartupRam = ($allVMs | Measure-Object -Property MemoryStartup -Sum).Sum

    [void]$html.AppendLine("<div class=`"summary-box`">")
    [void]$html.AppendLine("  <strong>$($allVMs.Count)</strong> VMs (<strong>$running</strong> Running, <strong>$off</strong> Off$(if($other -gt 0){", <strong>$other</strong> Outro(s)"})) &mdash; <strong>$totalVCPU</strong> vCPUs alocadas &mdash; <strong>$(Format-Bytes $totalStartupRam)</strong> RAM startup")
    [void]$html.AppendLine('</div>')

    $vmHtmlTable = ConvertTo-HtmlTable -Data $vmSummary `
        -Columns @('Nome', 'Estado', 'Ger.', 'vCPUs', 'RAM Startup', 'Mem. Din.', 'RAM Atrib.', 'Uptime') `
        -Properties @('Nome', 'Estado', 'Geracao', 'vCPUs', 'RAM Startup', 'Mem. Dinamica', 'RAM Atribuida', 'Uptime')
    [void]$html.AppendLine($vmHtmlTable)
}
[void]$html.AppendLine('')

# Detalhes por VM
[void]$html.AppendLine('<h2 id="vm-details">Detalhes por VM</h2>')

foreach ($detail in $vmDetails) {
    $vm = $detail.VM
    [void]$html.AppendLine("<h3>$([System.Web.HttpUtility]::HtmlEncode($vm.Name))</h3>")

    $dynInfo = if ($vm.DynamicMemoryEnabled) {
        "Sim (Min: $(Format-Bytes $vm.MemoryMinimum), Max: $(Format-Bytes $vm.MemoryMaximum))"
    } else { 'Nao' }

    [void]$html.AppendLine('<dl>')
    [void]$html.AppendLine("  <dt>Geracao / Versao</dt><dd>Gen $($vm.Generation) / v$($vm.Version)</dd>")
    [void]$html.AppendLine("  <dt>vCPUs</dt><dd>$($detail.vCPUs)</dd>")
    [void]$html.AppendLine("  <dt>RAM Startup</dt><dd>$(Format-Bytes $vm.MemoryStartup)</dd>")
    [void]$html.AppendLine("  <dt>Memoria Dinamica</dt><dd>$dynInfo</dd>")
    [void]$html.AppendLine("  <dt>Estado / Uptime</dt><dd>$($vm.State) / $(Format-Uptime $vm.Uptime)</dd>")

    if ($vm.Notes) {
        $safeNotes = [System.Web.HttpUtility]::HtmlEncode($vm.Notes.Trim())
        [void]$html.AppendLine("  <dt>Notas</dt><dd>$safeNotes</dd>")
    }
    [void]$html.AppendLine('</dl>')

    # Discos
    [void]$html.AppendLine('<h4>Discos Virtuais</h4>')
    if ($detail.VHDs -and @($detail.VHDs).Count -gt 0) {
        $diskHtml = ConvertTo-HtmlTable -Data @($detail.VHDs) `
            -Columns @('Controller', 'Loc.', 'Caminho', 'Formato', 'Tipo', 'Tam. Max', 'Tam. Atual') `
            -Properties @('Controller', 'Location', 'Path', 'VhdFormat', 'VhdType', 'MaxSize', 'CurrentSize')
        [void]$html.AppendLine($diskHtml)
    }
    else {
        [void]$html.AppendLine('<p><em>Nenhum disco virtual anexado.</em></p>')
    }

    # NICs
    [void]$html.AppendLine('<h4>Adaptadores de Rede</h4>')
    if ($detail.NICs -and @($detail.NICs).Count -gt 0) {
        $nicHtml = ConvertTo-HtmlTable -Data @($detail.NICs) `
            -Columns @('Nome', 'Switch', 'VLAN', 'MAC', 'IPs') `
            -Properties @('Name', 'Switch', 'VLAN', 'MAC', 'IPs')
        [void]$html.AppendLine($nicHtml)
    }
    else {
        [void]$html.AppendLine('<p><em>Nenhum adaptador de rede configurado.</em></p>')
    }
    [void]$html.AppendLine('')
}

# Switches
[void]$html.AppendLine('<h2 id="switches">Virtual Switches</h2>')

if ($switchSummary.Count -eq 0) {
    [void]$html.AppendLine('<p><em>Nenhum virtual switch encontrado.</em></p>')
}
else {
    $swHtml = ConvertTo-HtmlTable -Data $switchSummary `
        -Columns @('Nome', 'Tipo', 'Adaptador Fisico', 'Mgmt OS', 'Emb. Teaming', 'IOV', 'VMs Conectadas') `
        -Properties @('Nome', 'Tipo', 'Adaptador Fisico', 'Mgmt OS', 'Emb. Teaming', 'IOV', 'VMs Conectadas')
    [void]$html.AppendLine($swHtml)
}
[void]$html.AppendLine('')

# VHDs
[void]$html.AppendLine('<h2 id="vhds">Discos Virtuais</h2>')

if ($allVhdData.Count -eq 0) {
    [void]$html.AppendLine('<p><em>Nenhum disco virtual encontrado.</em></p>')
}
else {
    [void]$html.AppendLine("<div class=`"summary-box`">")
    [void]$html.AppendLine("  <strong>$($allVhdData.Count)</strong> disco(s) &mdash; <strong>$(Format-Bytes $totalProvisioned)</strong> provisionado &mdash; <strong>$(Format-Bytes $totalUsed)</strong> em uso")
    [void]$html.AppendLine('</div>')

    $vhdHtml = ConvertTo-HtmlTable -Data $allVhdData `
        -Columns @('VM', 'Caminho', 'Formato', 'Tipo', 'Tam. Maximo', 'Tam. Atual', 'Uso %') `
        -Properties @('VM', 'Path', 'Formato', 'Tipo', 'Tam. Maximo', 'Tam. Atual', 'Uso %')
    [void]$html.AppendLine($vhdHtml)
}
[void]$html.AppendLine('')

# Snapshots
[void]$html.AppendLine('<h2 id="snapshots">Snapshots / Checkpoints</h2>')

if ($snapshotData.Count -eq 0) {
    [void]$html.AppendLine('<p><em>Nenhum snapshot/checkpoint encontrado. (Otimo!)</em></p>')
}
else {
    if ($oldSnapshots.Count -gt 0) {
        [void]$html.AppendLine("<div class=`"warning`">")
        [void]$html.AppendLine("  <strong>Atencao:</strong> $($oldSnapshots.Count) snapshot(s) com mais de 7 dias. Snapshots antigos consomem disco e podem degradar a performance.")
        [void]$html.AppendLine('</div>')
    }

    $snapHtml = ConvertTo-HtmlTable -Data $snapshotData `
        -Columns @('VM', 'Nome', 'Tipo', 'Criacao', 'Idade (dias)', 'Parent') `
        -Properties @('VM', 'Nome', 'Tipo', 'Criacao', 'Idade (dias)', 'Parent')
    [void]$html.AppendLine($snapHtml)
}
[void]$html.AppendLine('')

# Footer
[void]$html.AppendLine('<hr>')
[void]$html.AppendLine("<p class=`"meta`">Relatorio gerado por Get-HyperVReport.ps1 v1.0</p>")
[void]$html.AppendLine('</body>')
[void]$html.AppendLine('</html>')

# ============================================================
# FASE 5: ESCRITA DE ARQUIVOS E RESUMO
# ============================================================

Write-Host 'Salvando relatorios...' -ForegroundColor Cyan

$md.ToString() | Out-File -FilePath $mdFile -Encoding UTF8 -Force
$html.ToString() | Out-File -FilePath $htmlFile -Encoding UTF8 -Force

Write-Host ''
Write-Host '================================================' -ForegroundColor Green
Write-Host '  Relatorio gerado com sucesso!' -ForegroundColor Green
Write-Host '================================================' -ForegroundColor Green
Write-Host ''
Write-Host "  Markdown: $mdFile" -ForegroundColor White
Write-Host "  HTML:     $htmlFile" -ForegroundColor White
Write-Host ''
Write-Host "  VMs encontradas:      $($allVMs.Count)" -ForegroundColor White
Write-Host "  Virtual Switches:     $($allSwitches.Count)" -ForegroundColor White
Write-Host "  Discos virtuais:      $($allVhdData.Count)" -ForegroundColor White
Write-Host "  Snapshots:            $($allSnapshots.Count)" -ForegroundColor White
Write-Host ''
