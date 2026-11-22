# 项目进度

| 阶段 | 状态 |
|---|---|
| 上游与参考审计 | 已核对 KernelSU initrc 注入、`#3908`、Android 17 注入失败案例、OPlus Kernel Lab、Coolapk 模块清单、`inte` 归属、`KERNEL_SECURITY_CHECK` 与 EFISP 假回锁资料。 |
| Phase 1 · 只读诊断 | 完成，见 [实机报告](DEVICE_REPORT.md) 与 [测试结果](TESTS.md)。 |
| Phase 2 · 实机验证 | 完成：确认 `oplus_secure_guard_new` 在约 3.4s 拦截 `ksud`；单独卸载后 30 次 `su` 无新增拦截。 |
| Phase 3 · 开机自动卸载 | 完成 v2.0.1：early 服务约 2.9s 前卸载，final 服务开机完成复核并刷新卡片；假回锁与 vendor_boot 未受影响。 |

## 当前版本

- 模块 ID：`kayro_secureguard`
- 版本：v2.0.1（versionCode 20001）
- 交付：`dist/kayro_secureguard-v2.0.1.zip`，2,462 字节，SHA-256 `9df6ce30…50391`
- 只卸载 `oplus_secure_guard_new`；不碰 `inte`/`oplus_secure_common`/`cdt_integrity`。

## 边界

- 只针对 PLZ110 / ColorOS 17 / KernelSU 3.3.1 实测。
- 未验证 OTA 后固件、其它 ColorOS 版本或 late-load 模式。
- 卡片是快照；正常运行时目标不会重载，后期变化需点 Action 刷新。
