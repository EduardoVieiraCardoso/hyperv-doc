# Get-HyperVReport

Gera documentacao completa do ambiente Hyper-V com um unico script PowerShell.
Produz relatorios em **Markdown** e **HTML** — pronto para entregar ao cliente ou versionar no Git.

## Requisitos

- Windows Server 2019 ou superior com a role Hyper-V instalada
- Executar como **Administrador**
- Nenhum modulo externo necessario (usa o modulo Hyper-V nativo)

## Como Usar

```powershell
# Modo mais simples - gera no diretorio atual
.\Get-HyperVReport.ps1

# Salvar em um diretorio especifico
.\Get-HyperVReport.ps1 -OutputPath C:\Relatorios

# Se a politica de execucao bloquear
PowerShell -ExecutionPolicy Bypass -File .\Get-HyperVReport.ps1
```

Os relatorios sao salvos como:

```
HyperV-Report_<HOSTNAME>_<DATA>.md
HyperV-Report_<HOSTNAME>_<DATA>.html
```

## O Que Coleta

| Secao | Informacoes |
|-------|-------------|
| **Host** | Nome, dominio, hardware, OS, CPU, RAM, paths do Hyper-V |
| **VMs** | Nome, estado, geracao, vCPUs, RAM, memoria dinamica, uptime |
| **Detalhes por VM** | Discos virtuais (tamanho, tipo), adaptadores de rede (switch, VLAN, MAC, IPs) |
| **Virtual Switches** | Tipo, adaptador fisico, management OS, IOV, VMs conectadas |
| **Discos Virtuais** | Formato, tipo, tamanho maximo vs atual, percentual de uso |
| **Snapshots** | Nome, tipo, data, idade em dias, alertas para snapshots antigos |

## Saida

- **Markdown (.md)** — Texto limpo com tabelas, facil de versionar e ler
- **HTML (.html)** — Arquivo auto-contido com CSS inline, visual profissional, print-friendly

## Notas

- O script **apenas le** informacoes — nao faz nenhuma alteracao no host ou VMs
- Consultas de VHD podem demorar em hosts com muitos discos em storage lento
- IPs das VMs requerem que a VM esteja ligada com Integration Services ativo
- Erros de acesso a VHDs sao tratados graciosamente (mostra "Erro" em vez de travar)
