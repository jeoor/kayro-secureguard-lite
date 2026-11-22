# 安全设计

## 范围

- 只对精确名称 `oplus_secure_guard_new` 执行 `rmmod`，不模糊匹配，不使用 `-f`。
- 不改 boot/vendor_boot/EFISP，不写分区，不改属性，不加 SELinux 规则。
- 不卸载 `inte`、`oplus_secure_common`、`cdt_integrity`。
- 不做启动期 block，不删除 vendor_dlkm 中的 ko；recovery 仍按原样加载。

## 稳定性

- early/final 都是后台 `oneshot` 服务，`timeout` 兜底，不阻塞 init。
- `rmmod` 失败重试；目标不存在时 early 最多等 6 秒后退出。
- 失败只是保持原状，不会 bootloop；可随时禁用/卸载模块。
- 无守护进程、无 WebUI、无后台循环；服务结束后零残留。

## 卡片

- final 服务与 Action 各写一次临时 `override.description`；下次 `post-fs-data` 自动清除。
- 卡片是快照，不是实时监控；自动实时需要常驻进程，会增加待机功耗。

## 假回锁

- `fake_bl_efisp` 在 EFISP/ABL 层，本项目不碰。
- 两轮重启后 `verifiedbootstate=green`、`flash.locked=1`、`vbmeta.device_state=locked` 保持。
- vendor_boot 中的 `oplus_secure_guard_new.ko` 未删除/替换，gbl_root_canoe 的检查仍成立。

## 残余风险

- 有意移除厂商完整性检查，会降低 SecureGuard 的检测能力。
- initrc 代码在 KSU 安全模式下仍会执行；early 在 `post-fs` 运行，安全模式挡不住那次 `rmmod`。代码有超时、不阻塞、不改分区，但这是 initrc 方案的固有风险。
- 启动早期卸载厂商安全模块，长期/OTA 稳定性未验证（两轮重启通过）。
- OTA、late-load、正常解锁、修补过 vendor_boot 的变体未验证。
- 卡片是快照；后期变化需点 Action 刷新。
