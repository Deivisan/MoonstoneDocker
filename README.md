# 🌙 Moonstone Docker

Repositório dedicado ao desenvolvimento de Docker nativo no POCO X5 5G (Moonstone) com Android 16 / Infinity X.

## 🎯 Objetivo

Criar um kernel customizado com suporte completo ao Docker (PID_NS + CGROUP_DEVICE) sem comprometer funcionalidades críticas como touchscreen.

## 📁 Estrutura

```
MoonstoneDocker/
├── Plano-Operacional-Kernel-Docker.md  # Plano detalhado de implementação
├── Scripts/
│   ├── docker-check.sh                 # Verificador de compatibilidade Docker
│   ├── moon-connect.ps1                # Ferramenta de conexão (PowerShell)
│   ├── auto-connect.sh                 # Auto-conexão ADB/SSH
│   └── sync-workspace.sh               # Sincronização PC ↔ Dispositivo
└── README.md                           # Este arquivo
```

## 🚀 Como Usar

### 1. Verificar Compatibilidade
```bash
# No dispositivo (via Termux)
./Scripts/docker-check.sh
```

### 2. Conectar ao Dispositivo
```powershell
# No PC (PowerShell)
.\Scripts\moon-connect.ps1 menu
```

### 3. Sincronizar Workspace
```bash
# No PC (Bash/WSL)
./Scripts/sync-workspace.sh
```

## 📋 Status Atual

- ✅ Scripts de automação prontos
- ✅ Plano operacional definido
- 🔄 Kernel custom aguardando build
- ⏳ Docker nativo pendente

## 🔧 Requisitos

- **Dispositivo:** POCO X5 5G (Moonstone)
- **Android:** 16 / Infinity X
- **Kernel:** 5.4.300 (Darkmoon-KSU)
- **Host:** Ubuntu 22.04/WSL2 + toolchains

## 📚 Documentação

- [Plano Operacional Completo](Plano-Operacional-Kernel-Docker.md)
- [ROADMAP Android](../Android/ROADMAP_ANDROID.md)
- [Kernel Engineering Guide](../Android/KERNEL_ENGINEERING_GUIDE.md)

## 🤝 Contribuição

1. Fork o repo
2. Crie uma branch (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto é parte do ecossistema Android customizado. Consulte [CONTRIBUTING.md](../Android/CONTRIBUTING.md) para detalhes.

---

**Responsável:** DevSan · Atualizado em 03/12/2025