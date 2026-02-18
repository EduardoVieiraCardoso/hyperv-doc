# Relatório Hyper-V - SERVIDOR-HV01

**Data de Geração:** 2026-02-18 10:30:45

---

## 1. Informações do Host

| Propriedade | Valor |
|---|---|
| Hostname | SERVIDOR-HV01 |
| Domain | CONTOSO.COM |
| Fabricante | Dell Inc. |
| Modelo | PowerEdge R740 |
| OS | Windows Server 2022 Standard |
| OSBuild | 20348 |
| CPUFísico | Intel(R) Xeon(R) Gold 6348 CPU @ 2.60GHz |
| RAMTotal | 256.00 GB |
| DefaultVirtualHDPath | D:\VirtualMachines |
| DefaultVHDPath | D:\VirtualHardDisks |
| DownloadedVMPath | D:\VirtualMachineGroups |
| NumProcessorsLogicos | 56 |

---

## 2. Máquinas Virtuais - Resumo

**Total de VMs:** 8

| Nome | Estado | Geração | vCPUs | RAM_Startup | Uptime |
|---|---|---|---|---|---|
| SERVIDOR-APP01 | Running | 2 | 4 | 16.00 GB | 45d 12:30 |
| SERVIDOR-APP02 | Running | 2 | 4 | 16.00 GB | 45d 12:30 |
| SERVIDOR-DB01 | Running | 2 | 8 | 32.00 GB | 45d 12:30 |
| SERVIDOR-DB02 | Running | 2 | 8 | 32.00 GB | 45d 12:30 |
| SERVIDOR-WEB01 | Running | 2 | 2 | 8.00 GB | 30d 08:15 |
| SERVIDOR-WEB02 | Running | 2 | 2 | 8.00 GB | 30d 08:15 |
| SERVIDOR-BACKUP | Off | 2 | 4 | 16.00 GB | N/A |
| SERVIDOR-TESTE | Paused | 2 | 2 | 8.00 GB | N/A |

---

## 3. Máquinas Virtuais - Detalhes

### SERVIDOR-APP01

#### Informações Gerais

| Propriedade | Valor |
|---|---|
| Estado | Running |
| Geração | 2 |
| vCPUs | 4 |
| RAM Startup | 16.00 GB |
| RAM Dinâmica | Habilitada |
| RAM Máxima | 24.00 GB |
| RAM Atribuída | 20.50 GB |
| Uptime | 45d 12:30 |

#### Discos

| Controller | Path | Formato | Tipo | TamanhoMax | TamanhoPhy | PercentUso |
|---|---|---|---|---|---|---|
| SCSI [0:0] | D:\VirtualHardDisks\SERVIDOR-APP01_OS.vhdx | VHDX | Dinâmico | 100.00 GB | 45.30 GB | 45.30% |
| SCSI [1:0] | D:\VirtualHardDisks\SERVIDOR-APP01_DATA.vhdx | VHDX | Dinâmico | 500.00 GB | 380.50 GB | 76.10% |

#### Adaptadores de Rede

| Nome | Endereço | Switch | MACAddress | VLANId | Status |
|---|---|---|---|---|---|
| Ethernet | 192.168.1.50 | VLAN10_Produção | 00-15-5D-01-02-03 | 10 | OK |
| Ethernet 2 | 192.168.2.50 | VLAN20_Dados | 00-15-5D-01-02-04 | 20 | OK |

#### Snapshots

| Nome | Tipo | Criado | Idade | Parent |
|---|---|---|---|---|
| Antes-Atualização-SQL | Standard | 2026-02-18 09:00 | 0d 01:30 | (root) |
| Backup-Diário | Standard | 2026-02-17 20:00 | 1d 14:30 | (root) |
| Backup-Semanal | Standard | 2026-02-10 22:00 | 8d 12:30 ⚠ ANTIGO | (root) |

> ⚠ **AVISO:** Snapshots com mais de 7 dias detectados. Considere remover para liberar espaço.

### SERVIDOR-DB01

#### Informações Gerais

| Propriedade | Valor |
|---|---|
| Estado | Running |
| Geração | 2 |
| vCPUs | 8 |
| RAM Startup | 32.00 GB |
| RAM Dinâmica | Habilitada |
| RAM Máxima | 48.00 GB |
| RAM Atribuída | 46.25 GB |
| Uptime | 45d 12:30 |

#### Discos

| Controller | Path | Formato | Tipo | TamanhoMax | TamanhoPhy | PercentUso |
|---|---|---|---|---|---|---|
| SCSI [0:0] | D:\VirtualHardDisks\SERVIDOR-DB01_OS.vhdx | VHDX | Dinâmico | 100.00 GB | 52.10 GB | 52.10% |
| SCSI [1:0] | D:\VirtualHardDisks\SERVIDOR-DB01_LOGS.vhdx | VHDX | Dinâmico | 200.00 GB | 185.30 GB | 92.65% |
| SCSI [1:1] | D:\VirtualHardDisks\SERVIDOR-DB01_DATA.vhdx | VHDX | Dinâmico | 1000.00 GB | 820.40 GB | 82.04% |

#### Adaptadores de Rede

| Nome | Endereço | Switch | MACAddress | VLANId | Status |
|---|---|---|---|---|---|
| Ethernet | 192.168.1.100 | VLAN10_Produção | 00-15-5D-01-03-01 | 10 | OK |

### SERVIDOR-BACKUP

#### Informações Gerais

| Propriedade | Valor |
|---|---|
| Estado | Off |
| Geração | 2 |
| vCPUs | 4 |
| RAM Startup | 16.00 GB |
| RAM Dinâmica | Desabilitada |
| RAM Máxima | 16.00 GB |
| RAM Atribuída | - |
| Uptime | N/A |

#### Discos

| Controller | Path | Formato | Tipo | TamanhoMax | TamanhoPhy | PercentUso |
|---|---|---|---|---|---|---|
| IDE [0:0] | D:\VirtualHardDisks\SERVIDOR-BACKUP_OS.vhd | VHD | Fixo | 80.00 GB | 80.00 GB | 100.00% |

#### Adaptadores de Rede

| Nome | Endereço | Switch | MACAddress | VLANId | Status |
|---|---|---|---|---|---|
| Ethernet | (VM desligada) | Desconectado | 00-15-5D-01-04-01 | Nenhuma | Desconectado |

---

## 4. Switches Virtuais

**Total de Switches:** 3

| Nome | Tipo | Adaptador | AllowMgmtOS | IOV |
|---|---|---|---|---|
| VLAN10_Produção | External | Broadcom NetXtreme Gigabit Ethernet #2 | True | False |
| VLAN20_Dados | External | Broadcom NetXtreme Gigabit Ethernet #3 | False | False |
| Switch-Interno | Internal | N/A | True | False |

---

## 5. Inventário de VHDs

| Path | Formato | Tipo | TamanhoMax | TamanhoPhy | PercentUso |
|---|---|---|---|---|---|
| D:\VirtualHardDisks\SERVIDOR-APP01_OS.vhdx | VHDX | Dinâmico | 100.00 GB | 45.30 GB | 45.30% |
| D:\VirtualHardDisks\SERVIDOR-APP01_DATA.vhdx | VHDX | Dinâmico | 500.00 GB | 380.50 GB | 76.10% |
| D:\VirtualHardDisks\SERVIDOR-APP02_OS.vhdx | VHDX | Dinâmico | 100.00 GB | 48.20 GB | 48.20% |
| D:\VirtualHardDisks\SERVIDOR-APP02_DATA.vhdx | VHDX | Dinâmico | 500.00 GB | 390.10 GB | 78.02% |
| D:\VirtualHardDisks\SERVIDOR-DB01_OS.vhdx | VHDX | Dinâmico | 100.00 GB | 52.10 GB | 52.10% |
| D:\VirtualHardDisks\SERVIDOR-DB01_LOGS.vhdx | VHDX | Dinâmico | 200.00 GB | 185.30 GB | 92.65% |
| D:\VirtualHardDisks\SERVIDOR-DB01_DATA.vhdx | VHDX | Dinâmico | 1000.00 GB | 820.40 GB | 82.04% |
| D:\VirtualHardDisks\SERVIDOR-DB02_OS.vhdx | VHDX | Dinâmico | 100.00 GB | 55.60 GB | 55.60% |
| D:\VirtualHardDisks\SERVIDOR-DB02_LOGS.vhdx | VHDX | Dinâmico | 200.00 GB | 188.90 GB | 94.45% |
| D:\VirtualHardDisks\SERVIDOR-DB02_DATA.vhdx | VHDX | Dinâmico | 1000.00 GB | 850.30 GB | 85.03% |
| D:\VirtualHardDisks\SERVIDOR-WEB01_OS.vhdx | VHDX | Dinâmico | 80.00 GB | 38.50 GB | 48.13% |
| D:\VirtualHardDisks\SERVIDOR-WEB02_OS.vhdx | VHDX | Dinâmico | 80.00 GB | 40.20 GB | 50.25% |
| D:\VirtualHardDisks\SERVIDOR-BACKUP_OS.vhd | VHD | Fixo | 80.00 GB | 80.00 GB | 100.00% |
| D:\VirtualHardDisks\SERVIDOR-TESTE_OS.vhdx | VHDX | Dinâmico | 60.00 GB | 25.40 GB | 42.33% |

**Resumo:**
- Total de VHDs: 14

---

*Relatório gerado automaticamente por Get-HyperVReport.ps1*
