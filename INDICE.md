# 📚 Índice do Repositório - Hyper-V Report Generator

## 🎯 Comece Aqui

Se você é **novo** neste repositório:

1. 📖 Leia: [README.md](README.md) — Visão geral completa
2. ⚡ Execute: [GUIA-RAPIDO.md](GUIA-RAPIDO.md) — Passo-a-passo
3. ✅ Verifique: [VERIFICACAO.md](VERIFICACAO.md) — Confirmação técnica

---

## 📂 O Que Cada Arquivo Contém

### 🔧 Script Principal

#### [Get-HyperVReport.ps1](Get-HyperVReport.ps1) (31 KB)
```
Script PowerShell único que coleta tudo e gera relatórios
├─ 1.045 linhas de código
├─ 6 funções auxiliares
├─ 5 fases de execução
└─ Zero dependências externas
```

**Principais Funções:**
- `Format-Bytes` — Converte bytes em GB/TB
- `Format-Uptime` — Formata tempo de atividade
- `Get-SafeVHD` — Coleta VHD com tratamento de erro
- `ConvertTo-MarkdownTable` — Gera tabelas Markdown
- `ConvertTo-HtmlTable` — Gera tabelas HTML com CSS
- `Get-StatusBadge` — Cria badges coloridos

**Como Usar:**
```powershell
# Básico
.\Get-HyperVReport.ps1

# Com OutputPath customizado
.\Get-HyperVReport.ps1 -OutputPath "C:\Reports"
```

---

### 📖 Documentação

#### [README.md](README.md) (5 KB) — 📋 Documentação Completa
Tudo que você precisa saber:
- ✅ Requisitos do sistema
- ✅ Quick Start com exemplos
- ✅ O que é coletado (detalhe de cada seção)
- ✅ Estrutura de repositório
- ✅ Casos de uso reais
- ✅ Troubleshooting comum
- ✅ Segurança e privacidade

**Quando usar:** Primeira vez usando a ferramenta

---

#### [GUIA-RAPIDO.md](GUIA-RAPIDO.md) (5 KB) — ⚡ Como Usar (Passo-a-Passo)
Instruções práticas:
- 5️⃣ Passos de preparação
- 3️⃣ Métodos de execução
- 📋 Checklist pré-execução
- 💡 Casos de uso com exemplos
- 🔄 Agendamento automático
- 🆘 Troubleshooting rápido

**Quando usar:** Pronto para executar agora

---

#### [VERIFICACAO.md](VERIFICACAO.md) (9 KB) — ✅ Checklist Técnico
Análise completa de implementação:
- ✅ Verificação por fase (Preflight até Saída)
- 📊 Detalhes de cada coleta (Host, VMs, Switches, VHDs)
- 🛡️ Tratamento de erros
- 📝 Contagem de código
- ✅ Checklist final de requisitos

**Quando usar:** Validar que tudo foi implementado corretamente

---

### 📊 Exemplos

#### [EXEMPLO-SAIDA.md](EXEMPLO-SAIDA.md) (6 KB) — 📋 Saída Real Markdown
Exemplo completo de um relatório gerado:
- 🖥️ Informações de Host (12 propriedades)
- 🖥️ Resumo de VMs (8 máquinas)
- 📋 Detalhes de VMs (Info, Discos, NICs, Snapshots)
- 🔄 Switches Virtuais (3 switches)
- 💾 Inventário de VHDs (14 discos)
- ⚠️ Alertas (snapshots antigos)

**Quando usar:** Entender como fica a saída final

---

### 📋 Administrativo

#### [LICENSE](LICENSE) (1 KB) — 📜 MIT License
Licença de código aberto MIT:
- ✓ Livre para usar comercialmente
- ✓ Livre para modificar
- ✓ Livre para distribuir
- ⚠️ Sem garantia

---

#### [SUMARIO.md](SUMARIO.md) (7 KB) — 📊 Este Arquivo
Visão geral executiva completa:
- 📊 Status: 100% Completo
- ✅ Todas as fases implementadas
- 📈 Estatísticas do código
- 🎯 Próximas ações
- 🏆 Conclusão

---

## 🗺️ Mapa de Navegação

```
Primeiro Acesso?
│
├─ Ler → README.md (visão geral)
├─ Aprender → GUIA-RAPIDO.md (como usar)
├─ Ver Exemplo → EXEMPLO-SAIDA.md (saída esperada)
└─ Executar → .\Get-HyperVReport.ps1

Dúvidas Técnicas?
│
├─ Como usar? → GUIA-RAPIDO.md
├─ Problema? → README.md (Troubleshooting)
├─ Confirmação? → VERIFICACAO.md
└─ Exemplo? → EXEMPLO-SAIDA.md

Validar Implementação?
│
├─ Ler → VERIFICACAO.md (checklist)
├─ Revisar → SUMARIO.md (estatísticas)
└─ Testar → .\Get-HyperVReport.ps1
```

---

## 📖 Leitura por Cenário

### 🎓 "Sou Novo na Ferramenta"

**Ordem recomendada:**
1. [README.md](README.md) — Entenda o propósito e requisitos
2. [EXEMPLO-SAIDA.md](EXEMPLO-SAIDA.md) — Veja como fica
3. [GUIA-RAPIDO.md](GUIA-RAPIDO.md) — Siga os passos
4. Execute: `.\Get-HyperVReport.ps1`

**Tempo:** ~15 minutos

---

### ⚙️ "Preciso Integrar/Agendar"

**Ordem recomendada:**
1. [GUIA-RAPIDO.md](GUIA-RAPIDO.md) — Seção "Agendar Automaticamente"
2. [Get-HyperVReport.ps1](Get-HyperVReport.ps1) — Review do código
3. Customizar se necessário
4. Agendar via Task Scheduler

**Tempo:** ~30 minutos

---

### ✅ "Validar Implementação Completa"

**Ordem recomendada:**
1. [VERIFICACAO.md](VERIFICACAO.md) — Checklist linha-por-linha
2. [SUMARIO.md](SUMARIO.md) — Estatísticas
3. Execute: `.\Get-HyperVReport.ps1` — Teste real
4. Compare com [EXEMPLO-SAIDA.md](EXEMPLO-SAIDA.md)

**Tempo:** ~1 hora

---

### 🆘 "Algo Deu Errado"

**Diagnosticar:**
1. [README.md](README.md) — Seção Troubleshooting
2. [GUIA-RAPIDO.md](GUIA-RAPIDO.md) — Seção Troubleshooting Rápido
3. Execute novamente com feedback
4. Verifique [VERIFICACAO.md](VERIFICACAO.md) para validação

---

## 🎯 Checklist de Inicialização

Antes de executar o script:

- [ ] Windows Server 2019 ou superior
- [ ] PowerShell aberto como **Administrador**
- [ ] Hyper-V instalado (`Get-WindowsFeature Hyper-V`)
- [ ] Leu [GUIA-RAPIDO.md](GUIA-RAPIDO.md)
- [ ] OutputPath é válido e tem espaço
- [ ] [Get-HyperVReport.ps1](Get-HyperVReport.ps1) no diretório

---

## 📞 Referência Rápida

| Dúvida | Arquivo | Seção |
|--------|---------|-------|
| Como usar? | [GUIA-RAPIDO.md](GUIA-RAPIDO.md) | 🚀 Como Usar |
| Como instalar? | [README.md](README.md) | 🚀 Quick Start |
| O que coleta? | [README.md](README.md) | 📊 O Que é Coletado |
| Exemplo de saída? | [EXEMPLO-SAIDA.md](EXEMPLO-SAIDA.md) | Qualquer seção |
| Algum erro? | [README.md](README.md) | 🆘 Troubleshooting |
| Implementação OK? | [VERIFICACAO.md](VERIFICACAO.md) | ✅ Checklist Final |
| Agendar? | [GUIA-RAPIDO.md](GUIA-RAPIDO.md) | 🔄 Agendar Automaticamente |

---

## 📊 Estatísticas do Repositório

```
Total de Arquivos:  7
├─ Script:          1 (Get-HyperVReport.ps1)
├─ Documentação:    4 (README, GUIA, VERIFICACAO, SUMARIO)
├─ Exemplos:        1 (EXEMPLO-SAIDA)
└─ Legal:           1 (LICENSE)

Total de Tamanho:   ~65 KB
├─ Script:          31 KB (974 linhas)
├─ Documentação:    27 KB
├─ Exemplos:        6 KB
└─ Legal:           1 KB

Funções:            6 (auxiliares no script)
Fases:              5 (coleta, geração, saída)
Requisitos:         ✓ Listados (3 principais)
```

---

## 🚀 Próximo Passo

👉 **Comece agora:**

1. Abra PowerShell **como Administrador**
2. Navegue até pasta com [Get-HyperVReport.ps1](Get-HyperVReport.ps1)
3. Execute: `.\Get-HyperVReport.ps1`
4. Aguarde conclusão
5. Abra `HyperV-Report_*.html` no navegador

**Estimated Time:** 5-10 minutos (primeiro Hyper-V com poucas VMs)

---

## 📝 Versão e Data

- **Versão:** 1.0
- **Data:** 18 de Fevereiro de 2026
- **Status:** ✅ Pronto para Produção
- **Compatibilidade:** Windows Server 2019+

---

**🎉 Tudo pronto para começar!**
