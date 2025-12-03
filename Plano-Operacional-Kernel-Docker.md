# 📘 Plano Operacional — Kernel Docker + Touchscreen OK

> **Escopo:** POCO X5 5G (moonstone) · Android 16 / Infinity X · Kernel 5.4.300 (Vertex/Darkmoon)
> **Meta:** Recompilar e empacotar um `boot.img` com suporte total ao Docker (PID_NS + CGROUP_DEVICE) **sem regredir o touchscreen**.
> **Status Atual:** Kernel Darkmoon-KSU 5.4.294 em produção, faltando duas flags críticas. Scripts e artefatos prontos em `Kernel-Lab/`.

---

## 1. Objetivos e Critérios de Aceite

| Objetivo | Critério de Aceite | Fonte de Verificação |
|----------|-------------------|-----------------------|
| Kernel recompilado com Docker | `CONFIG_PID_NS=y` e `CONFIG_CGROUP_DEVICE=y` no `.config` final | `Scripts/docker-check.sh` e `check-config.sh` (Moby) |
| Touchscreen preservado | Driver Focaltech carrega sem erros, toques respondem após boot | `dmesg | grep -i focal`, teste manual +`getevent -l`
| Boot image segura | Repack com DTB original + magiskboot valida integridade | `Kernel-Lab/Build-Workspace/5-4-300-docker/package_boot.sh` logs |
| Documentação de fallback | Passos claros para restore via `fastboot flash boot <backup>` | Seção 6 deste plano |

---

## 2. Insumos Obrigatórios

1. **Fontes & Artefatos**
   - `Kernel-Lab/Build-Workspace/5-4-300-docker/` (scripts `prepare_env.sh`, `build_kernel.sh`, `package_boot.sh`).
   - `.config` base em `Kernel-Lab/Analysis/configs/2025-12-01-limitless/...config`.
   - DTB original em `Kernel-Lab/Analysis/ROMs/Rising/extracted/vendor_boot_unpack/dtb`.
2. **Toolchains**
   - Clang 20.x (KamiClang 21.0 recomendado). `prepare_env.sh` injeta `prebuilts/clang/...` no `PATH`.
3. **Ambiente Host**
   - Ubuntu 22.04/WSL2 com `build-essential`, `bc`, `bison`, `flex`, `lz4`, `llvm`, `clang`, `python3`, `rsync`, `android-tools-adb`, `android-tools-fastboot`.
4. **Backup/Recovery**
   - `boot.img` estável + `vendor_boot.img` da ROM Infinity X (`Backup/KernelBuilds/...`).
   - Recovery custom (TWRP/OrangeFox) instalado para emergências.

---

## 3. Fases do Operacional

### Fase 0 — Pré-voo (30 min)

1. **Sincronizar workspace:** `./Scripts/sync-workspace.sh`.
2. **Verificar adb/fastboot:** `adb devices` → `fastboot devices`.
3. **Backup adicional:** `adb pull /dev/block/by-name/boot ./Backup/device-boot-backups/$(date +%F)-moonstone-boot.img`.
4. **Check env:** `Kernel-Lab/Build-Workspace/5-4-300-docker/prepare_env.sh` (confere toolchain + paths).

### Fase 1 — Fonte e Config (45 min)

1. `cd Kernel-Lab/Build-Workspace/5-4-300-docker`
2. `./scripts/clone_or_update.sh` *(alias fictício; usar script equivalente existente, ex.: `./setup_source.sh` se disponível)*.
3. Copiar `.config` base:

   ```bash
   cp ../../Analysis/configs/2025-12-01-limitless-kernel-limitless-docker-20251201.config out/.config
   ```

4. Aplicar fragmento docker: `./scripts/apply_docker_config.sh docker_flags.config`.
5. Rodar `make olddefconfig O=out` para consolidar.

### Fase 2 — Build Incremental (60–90 min)

1. **Smoke build (sem alterações)**
   - `./build_kernel.sh --skip-docker` → garante ambiente funcional.
2. **Build Docker**
   - `./build_kernel.sh --with-docker --jobs=$(nproc)` → gera `Image.gz-dtb` em `out/arch/arm64/boot/`.
3. **Checks pós-build:**
   - `scripts/extract_config.sh out/arch/arm64/boot/Image.gz > out/config-final`.
   - `grep CONFIG_PID_NS out/config-final` e `CONFIG_CGROUP_DEVICE`.
   - `sha256sum out/arch/arm64/boot/Image.gz-dtb` → registrar em `Releases/<data>/SHA256SUMS.txt`.

### Fase 3 — Patch Touchscreen (15 min)

1. Confirmar alias `"focaltech,fts"` em `drivers/input/touchscreen/focaltech_core.c` (ver `Docs/touchscreen-diagnostico.md`).
2. Se ausente, aplicar patch incremental (guardar diff em `Kernel-Lab/patches/`):

   ```c
   static const struct of_device_id focaltech_of_match[] = {
       { .compatible = "focaltech,fts", },
       { .compatible = "focaltech,fts3358", },
       ...
   }
   ```

3. Rebuild rápido (`./build_kernel.sh --incremental drivers/input/touchscreen`).

### Fase 4 — Empacotamento (20 min)

1. `./package_boot.sh \
      --kernel out/arch/arm64/boot/Image.gz \
      --dtb ../../Analysis/ROMs/Rising/extracted/vendor_boot_unpack/dtb \
      --ramdisk Resources/boot/base-ramdisk.cpio \
      --out Releases/$(date +%F)/boot-docker.img`
2. Script utiliza `magiskboot` → verificar log `package_boot.log`.
3. Gerar zip AnyKernel3 opcional: `./scripts/make_anykernel.sh --source Releases/... --out Releases/.../AnyKernel3-docker.zip`.

### Fase 5 — Testes no dispositivo (40 min)

1. **Boot temporário:** `fastboot boot boot-docker.img`.
2. Monitorar serial/pstore: `adb shell cat /sys/fs/pstore/console-ramoops-0` se rebootar.
3. Validar touchscreen: `adb shell getevent -l | head`, abrir `PointerLocation` no Dev Options.
4. Validar Docker:

   ```bash
   adb shell su -c "/data/data/com.termux/files/home/Android/Scripts/docker-check.sh"
   adb shell su -c "dockerd-start >/data/local/tmp/dockerd.log 2>&1 &"
   adb shell su -c "docker run --rm hello-world"
   ```

5. Se tudo OK, `fastboot flash boot boot-docker.img` + `fastboot reboot`.

### Fase 6 — Pós-flight & Rollback

1. Registrar métricas em `Docs/BUILD_TROUBLESHOOTING.md` (tempo de build, temperaturas, logs).
2. Atualizar `Releases/<data>/README.md` com:
   - Hashes
   - Config resumo (`scripts/configdiff.sh`).
3. Fallback: `fastboot flash boot Backup/device-boot-backups/<data>-moonstone-boot.img`.

---

## 4. Matriz de Validação

| Etapa | Comando | Resultado Esperado |
|-------|---------|--------------------|
| Config check | `grep PID_NS out/config-final` | `CONFIG_PID_NS=y` |
| Touch init | `dmesg | grep -i focaltech` | Probe sem `-ENODEV` |
| USB Gadget | `dmesg | grep -i gadget` | Sem crashes pós-boot |
| Docker flags | `sudo ./Scripts/docker-check.sh` | Todos ✅ |
| Docker hello | `docker run hello-world` | Mensagem "Hello from Docker" |
| Thermal | `adb shell dumpsys thermalservice` | Sem throttling extremo |

---

## 5. Telemetria e Logs

- **Build logs:** `out/build.log` (redirect `./build_kernel.sh | tee out/build.log`).
- **Package logs:** `Releases/<data>/package_boot.log`.
- **Runtime:** `adb logcat -b kernel -s focaltech`, `adb shell dmesg -w`.
- **Panic capture:** habilitar `CONFIG_PSTORE_CONSOLE` (já ativo segundo configs em `Analysis/configs`).

---

## 6. Gestão de Risco & Fallbacks

| Risco | Sinal | Mitigação |
|-------|-------|-----------|
| Bootloop PID_NS | Loop no logo, `pstore` com crash init | Boot via fastboot em backup; reverter flag e testar `user ns` primeiro |
| Touchscreen morto | Sem eventos em `getevent` | Reutilizar DTB vendor, garantir alias, comparar DT2W nodes |
| Docker ainda falha | `dockerd` reclama de cgroup | Verificar montagem em `dockerd-start`, garantir `CONFIG_NAMESPACES` + `CONFIG_MEMCG` |
| Build quebra | Erros Clang/ld | Rodar `./Scripts/fast_test_flags.sh` para sanity, limpar via `make mrproper O=out` |

---

## 7. Próximos Passos (Roadmap curto)

1. **Automação CI local:** criar workflow `Kernel-Lab/Build-Workspace/ci.yml` para rodar `build_kernel.sh` via container.
2. **Driver guardrails:** portar script que confirma presença de nodes críticos (`/sys/touchpanel/*`).
3. **Magisk module:** converter boot image em zip flashável + patch para KernelSU toggle.
4. **Observabilidade:** integrar `adb shell perfetto` + `systrace` pós-boot para medir impacto do Docker.

> **Responsável:** DevSan · Atualizado em 01/12/2025  
> Qualquer ajuste deve ser versionado junto com os scripts correspondentes em `Kernel-Lab/Build-Workspace/`.