# Kayro SecureGuard Lite

[![CI](https://github.com/jeoor/kayro-secureguard-lite/actions/workflows/ci.yml/badge.svg)](https://github.com/jeoor/kayro-secureguard-lite/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/jeoor/kayro-secureguard-lite)](https://github.com/jeoor/kayro-secureguard-lite/releases/latest)
[![License](https://img.shields.io/github/license/jeoor/kayro-secureguard-lite)](LICENSE)

KernelSU 模块 · v2.0.4 · MIT

> 适用：存在 `oplus_secure_guard_new` 的 OPlus ColorOS 设备  
> 实测：一加 15T `PLZ110` / ColorOS 17 / KernelSU 3.3.1 / 免解 + EFISP 伪回锁（未修补 vendor_boot）
> 定位：实测版

## 做什么

开机早期卸载 `oplus_secure_guard_new`，消除 SecureGuard 对 `ksud` 的拦截/结束与安全警告触发源。

无守护进程、无 WebUI、不改分区、不碰假回锁。

## 为什么只卸一个

日志里结束 `ksud` 的标签只有 `[secureguard_new]`。`inte`（腾讯 ACE）、`oplus_secure_common`（指纹支付）、`cdt_integrity` 不参与，保留。

机制上是 **root/ksud 触发**，不是伪回锁本身；免解/伪回锁只是 PLZ110 上跑 ksud 的常见路径。修补过 vendor_boot 的变体未验证。

## 做法

- KernelSU `initrc` 注入一个一次性服务 `kayro_sg_early`。
- `on post-fs`，ksu 域轮询；目标出现即非强制 `rmmod`，失败重试，最多 6 秒。
- 为什么是 post-fs：目标约 1.6s 加载、`ksud` 约 3.4s 被拦、`post-fs-data` 约 5s 才跑；模块脚本会太晚。
- 不再有 `boot_completed` 自动复核；boot-completed 只写一次卡片结论（`✅ 已完成卸载` / `⚠️ 未卸载`），检测只在点 Action 时运行。
- 不用 `block_modules`/boot-patch：`oplus_secure_guard_new` 在 `modules.load.recovery` 中，启动期 block 有 recovery/假回锁风险。
- 不用 `rmmod -f`：被引用时强制卸载可能崩溃。

## 卡片与检测

开机完成写一次卡片结论：`✅ 已完成卸载` / `⚠️ 未卸载`，不显示 ksud 检测信息。点 Action（三角）运行一次检测，输出目标、执行拦截、`need kill`、涉及 `ksud`、`ksud` 执行状态。

不常驻、不实时监控。

## 实测（v2.0.1/v2.0.2，early 与 v2.0.4 相同）

| 项目 | 结果 |
|---|---|
| early | 2.19–2.96s 退出 0 |
| 目标 | 重启后未加载；256s 仍为 0 |
| 30 次 `su` | `execve_block 0`、`need kill 0`、涉及 `ksud 0` |
| 假回锁 | green / 1 / locked 保持 |

v2.0.4 仅调整卡片结论与 Action 检测；early 自动卸载逻辑不变。
19.5s 的 `KERNEL_SECURITY_CHECK: Added` 是 560 个 `.ko` 表登记，不是加载。

## 安装

1. 下载 [v2.0.4 Release](https://github.com/jeoor/kayro-secureguard-lite/releases/tag/v2.0.4) 的 ZIP。
2. 管理器安装，重启；点 Action 运行检测。

```text
2,892 bytes
SHA-256 616ac253f8f9efef9f09648beac85da4c1f742e3fa6897a869d630ecff62e9f3
```

只从本仓库 Release 下载并核对 SHA；不要用第三方转存。  
卸载或禁用并重启，`oplus_secure_guard_new` 随系统恢复加载。

## 开发

```sh
pwsh -NoProfile -File ./tests/verify.ps1   # 连续构建两次，校验一致性与 ZIP 内容
```

## 边界

- 实测仅 PLZ110 / ColorOS 17 / KSU 3.3.1 mainline / 免解 + 未修补 vendor_boot；其它 ColorOS 机型/版本/root 方式未逐一验证，安装前先 `dmesg | grep secureguard_new` 确认同一模块。
- KSU 文档明确 initrc 代码在安全模式下仍会执行；early 在 `post-fs` 运行，安全模式挡不住那次 `rmmod`。代码有 6s 超时、不阻塞、不改分区；依赖安全模式完全禁用者勿装。
- 启动早期卸载厂商安全模块，长期/OTA 稳定性未验证（两轮重启通过）。
- 卡片是快照，只显示卸载结论；不显示 ksud 检测信息。

## 链接

[源码](https://github.com/jeoor/kayro-secureguard-lite) · [Release](https://github.com/jeoor/kayro-secureguard-lite/releases/tag/v2.0.4) · [Issues](https://github.com/jeoor/kayro-secureguard-lite/issues) · [CI](https://github.com/jeoor/kayro-secureguard-lite/actions/workflows/ci.yml)

参考：[KernelSU initrc](https://kernelsu.org/guide/module.html#initrc-injection) · [KernelSU #3908](https://github.com/tiann/KernelSU/pull/3908) · [gbl_root_canoe](https://github.com/1vivy/gbl_root_canoe) · [inte 归属](https://www.zhihu.com/question/2089675358908040541/answer/2092690033698460930)
