## 🚀 Como Usar - Guia Rápido

### 1️⃣ Prepare o Servidor

```powershell
# No servidor Windows Server 2019+ com Hyper-V
# Abra PowerShell como ADMINISTRADOR

# Verifique se Hyper-V está habilitado
Get-WindowsFeature Hyper-V
# Resultado esperado: [X] Hyper-V (Status: Installed)

# Se não estiver instalado:
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart
```

### 2️⃣ Coloque o Script

```powershell
# Copie Get-HyperVReport.ps1 para o servidor
# Exemplo: C:\Scripts\

cd C:\Scripts
```

### 3️⃣ Execute

**Opção A: Diretório Atual (Padrão)**
```powershell
.\Get-HyperVReport.ps1
```

**Opção B: Especificar Saída**
```powershell
.\Get-HyperVReport.ps1 -OutputPath "C:\Reports"
```

**Opção C: Bypass ExecutionPolicy (se bloqueado)**
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Scripts\Get-HyperVReport.ps1"
```

### 4️⃣ Acompanhe o Progresso

```
[1/5] Executando validações preflight...
✓ OutputPath validado: C:\Scripts

[2/5] Coletando dados do ambiente Hyper-V...
  - Coletando informações do host...
  ✓ Host coletado
  - Coletando informações de VMs...
  ✓ 12 VMs encontradas
  ...

[3/5] Gerando relatório Markdown...
✓ Relatório Markdown criado: C:\Scripts\HyperV-Report_SERVER01_2026-02-18.md

[4/5] Gerando relatório HTML...
✓ Relatório HTML criado: C:\Scripts\HyperV-Report_SERVER01_2026-02-18.html

[5/5] Finalizando...

===================== RELATÓRIO GERADO COM SUCESSO =====================
✓ Processo concluído em 2026-02-18 14:30:45
```

### 5️⃣ Veja os Resultados

**Arquivos Gerados:**
```
C:\Scripts\HyperV-Report_SERVER01_2026-02-18.md     ← Markdown para docs
C:\Scripts\HyperV-Report_SERVER01_2026-02-18.html   ← HTML para navegador
```

**Abrir HTML:**
```powershell
# No servidor
start "C:\Scripts\HyperV-Report_SERVER01_2026-02-18.html"

# Ou enviar arquivo para seu PC Windows
# E abrir no navegador (Chrome, Edge, Firefox, Safari)
```

---

## 💡 Casos de Uso

### 📋 Documentação de Cliente
```powershell
# Segunda-feira de cada mês
.\Get-HyperVReport.ps1 -OutputPath "\\fileserver\Clientes\ClienteA\Docs"
# Salva com timestamp automático → fácil rastrear mudanças
```

### 🔄 Agendar Automaticamente
```powershell
# Via Task Scheduler do Windows
# OU via cron do Linux (se remoto)

# PowerShell Scheduled Job
$trigger = New-JobTrigger -Weekly -DaysOfWeek Monday -At 6:00AM
Register-ScheduledJob -Name "HyperVReport" `
  -ScriptBlock { C:\Scripts\Get-HyperVReport.ps1 -OutputPath "C:\Reports" } `
  -Trigger $trigger
```

### 🎓 Verificar Antes de Mudanças
```powershell
# 1. Gerar relatório antes
.\Get-HyperVReport.ps1 -OutputPath "C:\Backups\Before"

# 2. Aplicar mudanças no Hyper-V

# 3. Gerar relatório depois
.\Get-HyperVReport.ps1 -OutputPath "C:\Backups\After"

# 4. Comparar: Markdown/HTML lado-a-lado
```

---

## ✅ Checklist Pré-Execução

- [ ] PowerShell aberto **como Administrador**
- [ ] Servidor **Windows Server 2019+**
- [ ] **Hyper-V** instalado (`Get-WindowsFeature Hyper-V`)
- [ ] OutputPath é **válido e tem espaço livre**
- [ ] Script **Get-HyperVReport.ps1** está no mesmo diretório

---

## 🆘 Troubleshooting

| Problema | Solução |
|----------|---------|
| "Acesso negado" | Execute como Administrador (clique direito → Run as Administrator) |
| "Módulo Hyper-V não encontrado" | Instale Hyper-V: `Install-WindowsFeature -Name Hyper-V` |
| "ExecutionPolicy" block | Use: `powershell -ExecutionPolicy Bypass -File script.ps1` |
| OutputPath não existe | Crie a pasta: `mkdir C:\Reports` |
| Lentidão com muitas VMs | Normal! Cada VM é processada sequencialmente. Primeira execução: ~5-10min |
| VHD inaccessível warning | Normal! Script continua e mostra "N/A" para esse VHD |

---

## 📧 Compartilhar com Clientes

### Markdown (.md)
```bash
# Envie para docs/wiki
# GitLab/GitHub renderiza automaticamente
# SharePoint/OneDrive mostra formatado
```

### HTML (.html)
```bash
# 1. Abra no navegador
# 2. CTRL+P → Imprimir
# 3. "Salvar como PDF"
# 4. Envie o PDF pro cliente

# OU
# Envie direto o HTML (arquivo único, sem dependências)
```

---

## ⏱️ Exemplo de Uso em Cenário Real

```powershell
# 📅 Terça-feira - Auditoria Mensal de Hyper-V

$timestamp = Get-Date -Format "yyyy-MM"
$outputPath = "\\fileserver\Audits\$timestamp"

# Criar pasta se não existir
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force
}

# Executar relatório
C:\Scripts\Get-HyperVReport.ps1 -OutputPath $outputPath

# Enviar email pro gestor
$html = Get-Item "$outputPath\*.html" | Select-Object -First 1
Send-Item -Path $html.FullName -To "manager@company.com" `
  -Subject "Relatório Hyper-V $(Get-Date -Format 'MMMM yyyy')"
```

---

## 🎯 Próximas Execuções

```powershell
# Primeira execução (coleta completa)
.\Get-HyperVReport.ps1

# Após completar, você terá:
# ✓ Documentação completa do ambiente
# ✓ Baseline para comparações futuras
# ✓ Lista de VMs, VHDs, snapshots para auditoria
# ✓ Pronto para compartilhar com cliente/equipe
```

---

**💬 Dúvidas?** Veja README.md para documentação completa.
