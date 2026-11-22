# 恢复说明

## 正常恢复

在 KernelSU 管理器中禁用或卸载 `kayro_secureguard`，重启即可。`oplus_secure_guard_new` 会随系统正常加载，SecureGuard 恢复原状。

## 如果开机异常

本模块不修改分区、不阻塞 init、服务由 `timeout 6` 兜底，理论上不会造成 bootloop。若仍无法开机：

1. 按 KernelSU 恢复指南触发安全模式（首屏后连续按音量减，标准 LKM 启动），安全模式会禁用全部模块。
2. 进入系统后禁用或卸载本模块，再重启。
3. 如安全模式不可用，可在 Recovery 中创建 `/data/adb/modules/kayro_secureguard/disable` 后重启，再在管理器卸载。

本项目没有改动 boot、vendor_boot、EFISP 或 super 分区，因此不需要重刷镜像来恢复。
