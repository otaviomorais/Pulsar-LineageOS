# Pulsar-LineageOS

LineageOS 22.1 + [LinDroid](https://github.com/Linux-on-droid) para **POCO F3 / alioth (sm8250)**.

Este repo orquestra o build: pin de repos (manifesto), patches e pipeline. O kernel (com driver LinDroid EVDI) vive no repo separado [`kernel_xiaomi_sm8250`](https://github.com/otaviomorais/kernel_xiaomi_sm8250), mantido "do zero" (base LineageOS 4.19) para nao misturar com o kernel Pulsar.

## Estrutura

```
├── local_manifests/pulsar_lindroid.xml   # pin: kernel + repos LinDroid
├── patches/
│   ├── frameworks_native/                # inputflinger: desabilitar input via idc
│   ├── frameworks_base/                  # ignore uevent com NAME nulo (Extcon)
│   └── device_xiaomi_alioth/             # inherit vendor/lindroid/lindroid.mk
├── scripts/apply-patches.sh              # aplica os patches no tree sincronizado
├── build.sh                              # pipeline completo (init + sync + build)
└── .github/workflows/build.yml           # build em runner self-hosted x86_64
```

## Build (host x86_64)

Requisitos: repo tool, ~120 GB livres, 16 GB+ RAM. Veja https://wiki.lineageos.org/requirements

```bash
git clone https://github.com/otaviomorais/Pulsar-LineageOS
cd Pulsar-LineageOS
./build.sh ~/lineage-lindroid
```

O script faz: `repo init -b lineage-22.1` → copia o manifesto → `repo sync` → aplica patches → `breakfast alioth && brunch alioth`.

Resultado: `out/target/product/alioth/lineage_alioth-*.zip`

> Nota: o GitHub Actions publico nao tem disco/RAM para ROM (sync ~40 GB+). Por isso o workflow usa `runs-on: [self-hosted, linux, x86_64]` — registre um runner numa maquina x86_64 (guia: https://github.com/otaviomorais/Pulsar-LineageOS/settings/actions/runners).

## Kernel

Base: `LineageOS/android_kernel_xiaomi_sm8250` branch `lineage-22.1` (4.19.325).

Adicionado em `kernel_xiaomi_sm8250`:
- `drivers/lindroid-drm/` (fork EVDI do [lindroid-drm-loopback](https://github.com/Linux-on-droid/lindroid-drm-loopback)) + wiring em `drivers/Makefile` / `drivers/Kconfig`
- configs LinDroid em `arch/arm64/configs/vendor/xiaomi/alioth.config`:
  `SYSVIPC`, `UTS_NS`, `PID_NS`, `IPC_NS`, `USER_NS`, `NET_NS`, `CGROUP_DEVICE`, `CGROUP_FREEZER`, `DRM_LINDROID_EVDI`

A ROM builda o kernel pela arvore (nada de prebuilt).

## Flash

```
# device suportado: alioth / aliothin
adb reboot bootloader
fastboot flash recovery out/target/product/alioth/...recovery.img   # se quiser
# sideload do zip via recovery, ou flash manual de boot/system/vendor
```

## LinDroid no dispositivo (pos-flash)

1. Abra o app **LinDroid** e siga os prompts (concede root via adb: `adb root`).
2. Crie o container:
   ```
   adb shell -t lxc_create default -t lindroid -- -f /dev/fd/4 "4</data/data/org.lindroid.ui/files/rootfs.tar.gz"
   ```
3. Anexe ao shell do container:
   ```
   adb shell -t lxc_attach default -- "/bin/bash -c \"source /etc/profile && exec su - root\""
   ```
4. Credenciais: `lindroid` / `lindroid`.
5. Para rodar app Wayland manualmente (com kwin ativo):
   ```
   export XDG_RUNTIME_DIR=/tmp/runtime-lindroid && mkdir -p $XDG_RUNTIME_DIR && chmod 700 $XDG_RUNTIME_DIR
   EGL_PLATFORM=wayland WAYLAND_DISPLAY=wayland-0 APP
   ```

### Fixes conhecidos (do pinned message do grupo LinDroid)

- **Soft reboot ao iniciar container (Android 14+)** — workaround temporario: https://t.me/linux_on_droid/10346
- **overlayfs nao monta por causa de casefold** — hack: https://github.com/android-kxxt/android_kernel_xiaomi_sm8450/commit/ae700d3d04a2cd8b34e1dae434b0fdc9cde535c7
- **FCM / CONFIG_SYSVIPC** — tratado em `apply-patches.sh` (remove `# CONFIG_SYSVIPC is not set` dos `android-base.config` do kernel).
- apt overwrite dentro do container: `sudo apt-get -o Dpkg::Options::="--force-overwrite" <...>`
