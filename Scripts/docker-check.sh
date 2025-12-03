#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# 🐳 DOCKER CHECK - Verificador de Compatibilidade
# ============================================================
# Autor: DevSan | Data: 30/11/2025
# Dispositivo: POCO X5 5G (Moonstone)
# ============================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Contadores
PASS=0
FAIL=0
WARN=0

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║      🐳 DOCKER COMPATIBILITY CHECK - MOONSTONE            ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Função para verificar config
check_config() {
    local config=$1
    local required=$2  # "required" ou "optional"
    
    if zcat /proc/config.gz 2>/dev/null | grep -q "^${config}=y"; then
        echo -e "  ${GREEN}✅${NC} ${config}"
        ((PASS++))
        return 0
    elif zcat /proc/config.gz 2>/dev/null | grep -q "^${config}=m"; then
        echo -e "  ${YELLOW}🔶${NC} ${config} (module)"
        ((WARN++))
        return 0
    else
        if [ "$required" = "required" ]; then
            echo -e "  ${RED}❌${NC} ${config} ${RED}[CRÍTICO]${NC}"
            ((FAIL++))
        else
            echo -e "  ${YELLOW}⚠️${NC} ${config} (opcional)"
            ((WARN++))
        fi
        return 1
    fi
}

# Info do sistema
echo -e "${BLUE}📱 INFORMAÇÕES DO SISTEMA${NC}"
echo "  ├─ Kernel: $(uname -r)"
echo "  ├─ Arch: $(uname -m)"
echo "  └─ Android: $(getprop ro.build.version.release 2>/dev/null || echo 'N/A')"
echo ""

# Verificar se /proc/config.gz existe
if [ ! -f /proc/config.gz ]; then
    echo -e "${RED}❌ /proc/config.gz não encontrado!${NC}"
    echo "   Kernel precisa ser compilado com CONFIG_IKCONFIG=y"
    exit 1
fi

# === NAMESPACES (CRÍTICO) ===
echo -e "${YELLOW}📋 NAMESPACES (CRÍTICO para Docker)${NC}"
check_config "CONFIG_NAMESPACES" "required"
check_config "CONFIG_UTS_NS" "required"
check_config "CONFIG_IPC_NS" "required"
check_config "CONFIG_USER_NS" "optional"
check_config "CONFIG_PID_NS" "required"
check_config "CONFIG_NET_NS" "required"
echo ""

# === CGROUPS (CRÍTICO) ===
echo -e "${YELLOW}📋 CGROUPS (CRÍTICO para Docker)${NC}"
check_config "CONFIG_CGROUPS" "required"
check_config "CONFIG_CGROUP_CPUACCT" "optional"
check_config "CONFIG_CGROUP_DEVICE" "required"
check_config "CONFIG_CGROUP_FREEZER" "optional"
check_config "CONFIG_CGROUP_SCHED" "optional"
check_config "CONFIG_CPUSETS" "optional"
check_config "CONFIG_MEMCG" "optional"
check_config "CONFIG_CGROUP_PIDS" "optional"
echo ""

# === REDE ===
echo -e "${YELLOW}📋 NETWORK DRIVERS${NC}"
check_config "CONFIG_VETH" "required"
check_config "CONFIG_BRIDGE" "required"
check_config "CONFIG_BRIDGE_NETFILTER" "optional"
check_config "CONFIG_IP_NF_FILTER" "optional"
check_config "CONFIG_IP_NF_NAT" "optional"
check_config "CONFIG_IP_NF_TARGET_MASQUERADE" "optional"
check_config "CONFIG_NETFILTER_XT_MATCH_ADDRTYPE" "optional"
check_config "CONFIG_NETFILTER_XT_MATCH_CONNTRACK" "optional"
check_config "CONFIG_NETFILTER_XT_MATCH_IPVS" "optional"
echo ""

# === STORAGE ===
echo -e "${YELLOW}📋 STORAGE DRIVERS${NC}"
check_config "CONFIG_OVERLAY_FS" "required"
check_config "CONFIG_EXT4_FS" "optional"
check_config "CONFIG_EXT4_FS_POSIX_ACL" "optional"
check_config "CONFIG_EXT4_FS_SECURITY" "optional"
echo ""

# === MISC ===
echo -e "${YELLOW}📋 RECURSOS OPCIONAIS${NC}"
check_config "CONFIG_BINFMT_MISC" "optional"
check_config "CONFIG_POSIX_MQUEUE" "optional"
check_config "CONFIG_SECCOMP" "optional"
check_config "CONFIG_SECCOMP_FILTER" "optional"
check_config "CONFIG_KEYS" "optional"
echo ""

# === RESULTADO FINAL ===
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}📊 RESULTADO FINAL${NC}"
echo "  ├─ ✅ Passou: $PASS"
echo "  ├─ ⚠️ Avisos: $WARN"
echo "  └─ ❌ Falhou: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     🎉 KERNEL COMPATÍVEL COM DOCKER NATIVO!               ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  Próximos passos:"
    echo "  1. pkg install root-repo"
    echo "  2. pkg install docker"
    echo "  3. sudo dockerd --iptables=false"
    echo "  4. sudo docker run hello-world"
else
    echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║     ⛔ KERNEL NÃO COMPATÍVEL - RECOMPILAÇÃO NECESSÁRIA    ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  Flags que precisam ser habilitados no kernel:"
    echo ""
    
    # Listar flags faltantes
    for flag in CONFIG_PID_NS CONFIG_CGROUP_DEVICE CONFIG_VETH CONFIG_BRIDGE CONFIG_OVERLAY_FS; do
        if ! zcat /proc/config.gz 2>/dev/null | grep -q "^${flag}=y"; then
            echo "  • $flag=y"
        fi
    done
    
    echo ""
    echo "  Consulte: ROADMAP_ANDROID.md seção 'Kernel Customizado'"
fi
echo ""