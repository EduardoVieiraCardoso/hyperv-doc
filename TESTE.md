# 🧪 Teste do Script Corrigido

Agora o script está **totalmente compatível com PowerShell 5.1** e **cria diretórios automaticamente**.

## ✅ O Que Foi Corrigido

### 1️⃣ Operadores `??` Removidos
- **Problema:** PowerShell 5.1 (Windows Server 2019) não suporta `??`
- **Solução:** Substituídos por `if ($null -eq ...) { ... } else { ... }`
- **Resultado:** ✅ Compatível com PS 5.1+

### 2️⃣ Criação Automática de Diretório
- **Problema:** Script exigia que `C:\Reports` já existisse
- **Solução:** Agora cria automaticamente se não existir
- **Resultado:** ✅ Sem erros de validação

---

## 🚀 Como Testar

### Opção A: Com PowerShell como Administrador

```powershell
# No servidor Windows Server 2019/2022

# 1. Abra PowerShell como ADMINISTRADOR
# 2. Navegue até pasta do script
cd C:\Scripts

# 3. Execute (criará C:\Reports automaticamente)
.\Get-HyperVReport.ps1 -OutputPath "C:\Reports"

# 4. Aguarde conclusão (~5-10 min dependendo do ambiente)
```

### Opção B: Com Bypass de ExecutionPolicy (se bloqueado)

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Scripts\Get-HyperVReport.ps1" -OutputPath "C:\Reports"
```

### Opção C: Usando Pasta Existente

```powershell
.\Get-HyperVReport.ps1 -OutputPath "C:\Existing\Folder"
```

### Opção D: Usando Pasta Padrão (Diretório Atual)

```powershell
.\Get-HyperVReport.ps1
```

---

## 📊 Saída Esperada

Se funcionou corretamente, você verá:

```
[1/5] Executando validações preflight...
  - Criando diretório: C:\Reports
✓ OutputPath validado: C:\Reports

[2/5] Coletando dados do ambiente Hyper-V...
  - Coletando informações do host...
  ✓ Host coletado
  - Coletando informações de VMs...
  ✓ [N] VMs encontradas
  - Coletando informações de switches virtuais...
  ✓ [N] switches encontrados
    - Processando VM: VM-NAME-1
    - Processando VM: VM-NAME-2
    ...
  - Coletando inventário de VHDs...
  ✓ Inventário completo coletado

[3/5] Gerando relatório Markdown...
✓ Relatório Markdown criado: C:\Reports\HyperV-Report_SERVER_2026-02-18.md

[4/5] Gerando relatório HTML...
✓ Relatório HTML criado: C:\Reports\HyperV-Report_SERVER_2026-02-18.html

[5/5] Finalizando...

====================================================================
RELATÓRIO GERADO COM SUCESSO
====================================================================

Arquivos gerados:
  📄 Markdown: C:\Reports\HyperV-Report_SERVER_2026-02-18.md
  🌐 HTML:     C:\Reports\HyperV-Report_SERVER_2026-02-18.html

Resumo da coleta:
  • Host:       SERVER
  • VMs:        8
  • Switches:   3
  • VHDs:       14

✓ Processo concluído em 2026-02-18 14:30:45
```

---

## 🎯 Verificação Pós-Execução

✅ **Verifique:**
1. Pasta `C:\Reports` foi criada?
2. Arquivo `.md` foi gerado?
3. Arquivo `.html` foi gerado?
4. Ambos têm o mesmo nome com timestamp?

✅ **Teste HTML:**
```powershell
# Abra o HTML no navegador
start "C:\Reports\HyperV-Report_SERVER_2026-02-18.html"

# Ou copie o arquivo para seu PC e abra
```

✅ **Teste Markdown:**
```powershell
# Abra em editor de texto ou GitHub
Get-Content "C:\Reports\HyperV-Report_SERVER_2026-02-18.md" | Out-Host
```

---

## ❌ Se Algo Der Errado

### Erro: "Acesso negado"
```powershell
# Certifique-se que está executando como ADMINISTRADOR
# PowerShell → Clique direito → "Executar como administrador"
```

### Erro: "Módulo Hyper-V não encontrado"
```powershell
# Hyper-V não está instalado
Get-WindowsFeature Hyper-V

# Se não estiver [X], instale:
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart
```

### Erro: "ExecutionPolicy impede execução"
```powershell
# Use bypass:
powershell -ExecutionPolicy Bypass -File ".\Get-HyperVReport.ps1" -OutputPath "C:\Reports"
```

### Erro: "Não há VMs"
```powershell
# Normal! Se o host não tem VMs, o script relata 0 VMs
# Script continua funcional e gera relatório vazio para essa seção
```

---

## 📈 Tempo de Execução Estimado

| Ambiente | Tempo |
|----------|-------|
| Sem VMs | 1-2 min |
| 1-5 VMs | 5-10 min |
| 5-10 VMs | 10-15 min |
| 10+ VMs | 15-30 min |

*Primeira execução é mais lenta (coleta de dados)*

---

## 🎉 Resultado Final

Você terá 2 arquivos profissionais:

1. **HyperV-Report_SERVER_2026-02-18.md**
   - Markdown puro
   - Compatível com GitHub, GitLab, SharePoint
   - Para documentação técnica

2. **HyperV-Report_SERVER_2026-02-18.html**
   - HTML self-contained
   - Sem dependências externas
   - Pronto para impressão/PDF
   - Visual profissional

---

## ✨ Resumo

| Item | Status |
|------|--------|
| PowerShell 5.1 compatível | ✅ |
| Criar diretório automaticamente | ✅ |
| Sem operadores ?? | ✅ |
| Relatório Markdown | ✅ |
| Relatório HTML | ✅ |
| Pronto para produção | ✅ |

---

**Boa sorte! 🚀**

Qualquer dúvida, veja os outros arquivos de documentação na pasta.
