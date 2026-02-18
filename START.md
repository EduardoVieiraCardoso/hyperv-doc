# 🚀 START.md - Comece Aqui!

**Bem-vindo ao Hyper-V Report Generator!**

Se você chegou aqui é porque quer gerar relatórios de inventário Hyper-V rapidamente.

---

## ⚡ 3 Passos Rápidos

### 1️⃣ Preparar
```powershell
# Abra PowerShell como ADMINISTRADOR
# No servidor Windows Server 2019+ com Hyper-V

# Verifique se Hyper-V existe
Get-WindowsFeature Hyper-V
# Deve retordar: [X] Hyper-V
```

### 2️⃣ Executar
```powershell
# Se o script está no diretório atual:
.\Get-HyperVReport.ps1

# OU especifique pasta de saída:
.\Get-HyperVReport.ps1 -OutputPath "C:\Reports"
```

### 3️⃣ Abrir Resultado
```powershell
# Um navegador vai abrir automaticamente com o HTML
# OU abra manualmente:
start "HyperV-Report_SERVER01_2026-02-18.html"
```

---

## 📚 Documentação

Depois de executar, explore:

| Arquivo | Para |
|---------|------|
| [README.md](README.md) | Entender como funciona |
| [GUIA-RAPIDO.md](GUIA-RAPIDO.md) | Mais detalhes de execução |
| [EXEMPLO-SAIDA.md](EXEMPLO-SAIDA.md) | Ver como fica o relatório |
| [INDICE.md](INDICE.md) | Navegar toda a documentação |

---

## ❓ Dúvida Rápida?

**"Deu erro de permissão"**
```powershell
# Execute assim:
powershell -ExecutionPolicy Bypass -File ".\Get-HyperVReport.ps1"
```

**"O comando Get-VM não existe"**
```powershell
# Hyper-V não está instalado. Instale:
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart
```

**"Preciso de mais ajuda"**
→ Veja [README.md](README.md) Seção Troubleshooting

---

## 🎯 O Que Você Terá

Após executar, receberá 2 arquivos:

```
✅ HyperV-Report_SERVER01_2026-02-18.md
   └─ Markdown puro (para documentação)

✅ HyperV-Report_SERVER01_2026-02-18.html
   └─ HTML bonito (para apresentação/impressão/PDF)
```

Ambos com:
- 📊 Dados completos do host
- 🖥️ Todas as VMs (specs, discos, NICs, snapshots)
- 🔄 Switches virtuais
- 💾 Inventário de VHDs
- ⚠️ Alertas automáticos

---

## 💡 Dica

**Primeiro uso?** Leia [GUIA-RAPIDO.md](GUIA-RAPIDO.md)  
**Quer validar tudo?** Veja [VERIFICACAO.md](VERIFICACAO.md)  
**Precisa de exemplo?** Abra [EXEMPLO-SAIDA.md](EXEMPLO-SAIDA.md)

---

## 🎬 Pronto?

```powershell
# 1. Abra PowerShell como Admin
# 2. Digite:
.\Get-HyperVReport.ps1

# 3. Espere aparecer: ✓ Processo concluído
# 4. Arquivos prontos!
```

**Tempo estimado:** 5-10 minutos  
**Dificuldade:** Muito fácil ⭐

---

**Boa sorte! 🎉**
