# Hyper-V Report Generator

Ferramenta de documentação de ambientes Hyper-V com geração de relatórios em Markdown e HTML.

Um script PowerShell único, sem dependências externas, que coleta inventário completo do seu ambiente Hyper-V e gera relatórios profissionais prontos para apresentar a clientes.

## ✨ Características

- **Coleta Completa**: Host, VMs, Switches Virtuais, VHDs e Snapshots
- **Relatórios Profissionais**: Markdown + HTML self-contained com CSS inline
- **Print-Friendly**: HTML com suporte a impressão otimizada
- **Zero Dependências**: Usa apenas cmdlets Hyper-V nativos
- **Tratamento Robusto de Erros**: Nunca falha, mesmo com VHDs inacessíveis
- **Alertas Inteligentes**: Detecta snapshots com mais de 7 dias
- **Execução Rápida**: Otimizado para grandes ambientes

## 📋 Requisitos

- **Windows Server 2019** ou superior
- **Hyper-V** instalado e habilitado
- **Privilégios Administrativos** (Execute como Administrador)
- PowerShell 5.0+

## 🚀 Quick Start

### 1. Executar com Padrões

```powershell
.\Get-HyperVReport.ps1
```

Gera relatórios no diretório atual:
- `HyperV-Report_HOSTNAME_2026-02-18.md`
- `HyperV-Report_HOSTNAME_2026-02-18.html`

### 2. Especificar Diretório de Saída

```powershell
.\Get-HyperVReport.ps1 -OutputPath "C:\Reports"
```

## 🔐 Executar com Bypass (se necessário)

Se a Execution Policy bloquear o script:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Scripts\Get-HyperVReport.ps1"
```

Ou temporariamente na sessão:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\Get-HyperVReport.ps1
```

## 📊 O Que é Coletado?

### Host (Servidor)
- Nome e domínio
- Fabricante/Modelo
- Sistema Operacional (versão/build)
- Processador físico e lógico
- RAM total
- Caminhos padrão de VM/VHD

### Máquinas Virtuais
- Nome e estado (Running/Off/Paused/Saved)
- Geração (Gen 1/Gen 2)
- vCPUs e configuração de memória
- Uptime
- Discos (controlador, caminho, formato, tamanho)
- Adaptadores de rede (IP, Switch, MAC, VLAN)
- Snapshots (nome, tipo, data, idade)

### Switches Virtuais
- Nome e tipo (Internal/External/Private)
- Adaptador físico associado
- Configurações de Management OS e IOV

### VHDs
- Caminho e formato (VHD/VHDX)
- Tipo (Diferenciador/Fixo/Dinâmico)
- Tamanho máximo e físico utilizado
- Percentual de uso

### Snapshots
- Detalhes completos com alertas de idade
- Aviso automático para snapshots > 7 dias

## 📁 Estrutura do Repositório

```
hyperv-doc/
├── Get-HyperVReport.ps1    # Script único (ferramenta completa)
├── README.md                # Este arquivo
└── LICENSE                  # MIT License
```

## 🔍 Exemplo de Saída

### Markdown
Tabelas formatadas, seções hierárquicas, alertas de snapshots antigos:

```markdown
# Relatório Hyper-V - SERVER01

## 1. Informações do Host

| Propriedade | Valor |
|---|---|
| Hostname | SERVER01 |
| OS | Windows Server 2022 Standard |
| RAM Total | 128.00 GB |
...
```

### HTML
Visual profissional com:
- Cores Microsoft Blue (#0078D4)
- Tabelas com hover
- Badges de status coloridas
- Print-friendly
- Responsivo

## ⚙️ Configuração Avançada

O script valida automaticamente:
- ✓ Execução como Administrador
- ✓ Módulo Hyper-V disponível
- ✓ OutputPath válido

Nenhuma configuração manual necessária.

## 🛡️ Segurança

- **Apenas Leitura**: O script apenas coleta informações, não modifica nada
- **Sem Credenciais**: Usa contexto de execução do usuário
- **Tratamento de Erro Gracioso**: VHDs inacessíveis não travam o script

## 📝 Tratamento de Erros

| Cenário | Comportamento |
|---|---|
| VHD inacessível | Mostra "N/A" na tabela + warning no console |
| VM sem discos | Mostra "(nenhum disco)" |
| VM sem NICs | Mostra "(nenhuma NIC)" |
| VM desligada | Mostra "-" para RAM atribuída, "(VM desligada)" para IP |

## 🎯 Casos de Uso

- 📋 **Documentação de Clientes**: Gere relatório antes/depois de mudanças
- 🏗️ **Planejamento de Capacidade**: Analise uso de recursos
- 📊 **Auditoria**: Mantenha histórico de snapshots e VHDs
- 🔄 **Migração**: Compare ambientes origem/destino
- 📈 **Reportes Executivos**: Use o HTML para apresentações

## 📄 Licença

MIT License - Veja [LICENSE](LICENSE) para detalhes.

## 💡 Dicas

1. **Agende Relatórios**: Use Task Scheduler para coletar dados semanalmente
2. **Compare Versões**: Execute em diferentes datas para rastrear mudanças
3. **Customize o HTML**: Edite as cores/fonts direto no script
4. **Imprima para PDF**: Abra o HTML no navegador e use "Imprimir"

## 🐛 Troubleshooting

### "Módulo Hyper-V não encontrado"
Certifique-se que Hyper-V está instalado:
```powershell
Get-WindowsFeature Hyper-V
```

### "Acesso negado"
Execute como Administrador:
```powershell
# PowerShell como Admin
.\Get-HyperVReport.ps1
```

### Lentidão com muitas VMs
Normal - o script processa cada VM sequencialmente. Primeira execução é mais lenta.

---

**Versão:** 1.0  
**Compatibilidade:** Windows Server 2019+  
**Maintainer:** Consultor de TI
