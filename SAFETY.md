# 安全设计

## 作用范围

- 只对精确名称 `oplus_secure_guard_new` 执行 `rmmod`，不模糊匹配，不使用 `-f`。
- 不修改 boot/vendor_boot/EFISP、不写分区、不加载内核模块、不写系统属性、不添加 SELinux 规则。
- 不卸载 `inte`、`oplus_secure_common`、`cdt_integrity` 或任何其它模块。
- 不使用 KernelSU `block_modules`/boot-patch：避免影响 recovery 和假回锁。
- 不删除或替换 `vendor_dlkm` 中的 `oplus_secure_guard_new.ko`，OPlus ACE 的文件哈希表仍可正常登记它。

## 稳定性

- early 服务在后台运行，不阻塞 init；轮询最多 6 秒，`timeout` 强制结束。
- final 服务只在 `sys.boot_completed=1` 运行一次，最多 10 秒；用于复核 boot 完成前是否被重新加载。
- `rmmod` 失败会重试；目标不存在时 early 服务最多等 6 秒后退出。
- 卸载失败只是保持原状，不会 bootloop；模块可随时在管理器中禁用/卸载。
- 无守护进程、无 WebUI、无后台循环；服务结束后零残留。

## 卡片刷新

- 开机完成由 final 服务写一次临时 `override.description`；点 Action 再写一次。
- 临时配置在下次 `post-fs-data` 自动清除；模块被禁用时卡片回到静态描述，不会留下过期状态。
- 卡片是快照，不是实时监控；自动实时刷新需要常驻守护进程，会增加待机功耗，因此没有采用。

## 假回锁兼容

- `fake_bl_efisp`（gbl_root_canoe）在 EFISP/ABL 层做 fakelock；本项目不触碰该层。
- 实测 `ro.boot.verifiedbootstate=green`、`ro.boot.flash.locked=1`、`ro.boot.vbmeta.device_state=locked` 在两轮完整重启后保持。
- `vendor_boot` 中的 `oplus_secure_guard_new.ko` 未被删除或替换；gbl_root_canoe 的 vendor_boot 检查仍通过。
- 因为不在启动加载阶段 block，recovery 仍能按原样加载该模块，避免 #3908 描述的 recovery 失败。

## 残余风险

- 这是有意移除厂商完整性检查，可能降低系统对篡改的检测能力。
- Android 17 上部分 KernelSU-Next legacy/non-GKI 构建存在 initrc 注入静默失败；本机 KernelSU 3.3.1 mainline 已实测正常。更换管理器/固件后应检查 `dmesg | grep kayro_sg_`。
- 若目标被其它内核模块强引用，`rmmod` 会失败并保持原状；不会强制卸载。
- 新固件若改变模块加载时机或名称，需要重新验证。
- 卡片是快照；后期若发生外部变化，需点 Action 刷新，不能自动感知。
