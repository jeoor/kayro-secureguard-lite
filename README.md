# Kayro SecureGuard Lite

KernelSU 模块 · v2.0.2 · Kayro · MIT

> 实测环境：一加 15T `PLZ110` / ColorOS 17 / KernelSU 3.3.1 / **免解 + EFISP 伪回锁（未修补 vendor_boot）**。其它 root 环境未验证。

[![CI](https://github.com/jeoor/kayro-secureguard-lite/actions/workflows/ci.yml/badge.svg)](https://github.com/jeoor/kayro-secureguard-lite/actions/workflows/ci.yml)

只做一件事：**开机早期卸载 `oplus_secure_guard_new`**；在本机实测中消除 SecureGuard 对 `ksud` 的拦截/结束与安全警告触发源。无守护进程、无 WebUI、不修改分区、不改变回锁属性。

## 为什么只卸一个模块

实机日志显示，直接结束 `ksud` 的是 `oplus_secure_guard_new`：

```text
[secureguard_new][root_check] ... execve_block
[secureguard_new][root_check] ... need kill! (/data/adb/ksud)
```

`inte` 是腾讯 ACE 内核完整性组件，`oplus_secure_common` 提供指纹支付等公共能力，`cdt_integrity` 是系统组件；实测它们不产生上述 `ksud` 拦截。卸载它们只会增加游戏、支付或系统稳定性风险，因此**保持加载**。

只匹配精确名称 `oplus_secure_guard_new`，不碰其它内核模块。

## 原理

- 使用 KernelSU 的 **initrc 注入**，在 init 读取 `init.rc` 时追加两个一次性服务。
- `kayro_sg_early`：`on post-fs` 启动，`seclabel u:r:ksu:s0`，在 ksu 域内联轮询 `/proc/modules`；目标一出现就 `rmmod`，失败重试，最多 6 秒。
- `kayro_sg_final`：`on property:sys.boot_completed=1` 启动，只复核一次；若目标在 boot 完成前被厂商重新加载，就地卸载，并调用 `action.sh` 刷新卡片。
- 不依赖 `/data` 文件：目标在 `/data` 挂载前就已经加载；`post-fs-data.sh` 约 5 秒才运行，而 `ksud` 约 3.4 秒就被拦截。
- 不使用 `block_modules`/boot-patch：`oplus_secure_guard_new` 位于 `modules.load.recovery`，启动期 block 可能导致 recovery 失败或 bootloop（[KernelSU #3908](https://github.com/tiann/KernelSU/pull/3908)），而且会改动 boot 分区。
- 不使用 `rmmod -f`：目标被引用时强制卸载可能崩溃；这里非强制 + 重试。

## 卡片与 Action

- 开机完成后 final 服务写一次 **临时 `override.description`**，卡片显示最后状态，例如 `ACTIVE · SecureGuard 未加载 · 未观察到 ksud 拦截`。
- 点 Action 立即重新检测并刷新卡片，输出目标状态、`execve_block`、`need kill`、涉及 `ksud` 次数。
- 卡片是**快照**，不是实时监控：正常运行时目标不会被重新加载；若后期被外部事件改变，点 Action 刷新。自动实时刷新需要常驻守护进程，会违背“无额外功耗”，因此没有采用。

## v2.0.1 实测（initrc 与 v2.0.2 相同）

| 项目 | 结果 |
|---|---|
| early 服务 | 2.17–2.19s 启动；2.93–2.96s 退出 0 |
| final 服务 | 19.22–19.63s 启动；20.00–21.07s 退出 0 |
| 目标模块 | 连续重启后均未加载；256s 后仍为 0 |
| 30 次 `su` | `execve_block 0`、`need kill 0`、涉及 `ksud 0` |
| 常驻进程/告警 | 无 `ksud`/`kayro` 进程，无相关 alarm |
| 卡片 | v2.0.1 动态描述正确；v2.0.2 只改 Action/版本，未实机安装 |
| 假回锁 | `verifiedbootstate=green`、`flash.locked=1`、`vbmeta.device_state=locked` 保持 |
| vendor_boot | `oplus_secure_guard_new.ko` 原样存在，未改动 |
> v2.0.2 只修改 Action 诊断与版本，initrc 卸载逻辑未变；按用户要求未在实机安装 v2.0.2。

`KERNEL_SECURITY_CHECK: Added: oplus_secure_guard_new.ko` 是 OPlus ACE 在 19.5s 把 560 个 `.ko` 文件名登记进哈希表，不是加载模块；目标计数始终为 0。

## 安装

1. 下载 [`kayro_secureguard-v2.0.2.zip`](dist/kayro_secureguard-v2.0.2.zip)，核对 SHA-256。
2. 在 KernelSU 管理器中从本地安装，重启。
3. 开机后卡片显示最终状态；Action 可随时复核。

卸载或禁用模块并重启，`oplus_secure_guard_new` 会随系统正常加载，恢复原状。

## 文件

```text
module.prop
action.sh
initrc/kayro_secureguard.rc
LICENSE
```

ZIP 2,891 字节  
SHA-256 `4cd0283e5ef1d85b9aa01941f6959090b244afd9187ba036aafe95cc7090fe03`

## 适用性

本机是 **免解 + EFISP 伪回锁（未修补 vendor_boot）** 环境。`need kill` 指向 `/data/adb/ksud`，机制上是 **root/ksud 执行触发**，不是伪回锁本身；免解/伪回锁是 PLZ110 上跑 ksud 的常见路径，所以现象集中在这类机器。正常解锁、其它 root 管理器或其它 ColorOS 版本未验证；修补过 vendor_boot 的变体未纳入验证，本项目结论只覆盖未修补 vendor_boot。安装前先看 `dmesg | grep secureguard_new` 是否有 `need kill`。

## 边界

- 只验证 PLZ110 / ColorOS 17 / KernelSU 3.3.1；未验证 OTA 后固件、其它 ColorOS 版本或 late-load 模式。
- Android 17 上部分 KernelSU-Next legacy/non-GKI 构建存在 initrc 注入静默失败（init 改为 fstat + 单次 read_iter）；本机 KernelSU 3.3.1 mainline 实测正常。若更换管理器/固件，请检查 `dmesg | grep kayro_sg_` 是否出现服务日志。
- 这是有意移除厂商完整性检查，会降低 SecureGuard 的检测能力；启动早期卸载厂商安全模块，长期/OTA 稳定性未验证（两轮重启通过）。
- KernelSU 文档明确：initrc 代码在安全模式下仍会执行。本模块 early 服务在 `post-fs` 运行，安全模式无法阻止这次 `rmmod`；代码有 6s 超时且不阻塞启动、不改分区，但若依赖安全模式完全禁用本模块，请不要安装。
- 新固件若改变模块加载时机或名称，需要重新验证。

## 参考

- [KernelSU initrc 注入](https://kernelsu.org/guide/module.html#initrc-injection)
- [KernelSU #3908：启动期 block 目标会破坏 recovery](https://github.com/tiann/KernelSU/pull/3908)
- [OPlus Kernel Lab：把 `oplus_secure_guard`/`_new` 加入 vendor blacklist](https://xdaforums.com/t/kernel-oos-aosp-oplus-kernel-lab.4782243/page-43#post-90777719)
- [Coolapk：OPlus 内核云控/遥测模块清单](https://www.coolapk.com/feed/74597659)
- [知乎：`inte` 是腾讯 ACE 内核完整性检测](https://www.zhihu.com/question/2089675358908040541/answer/2092690033698460930)
- [ColorOS Termux 安全警告讨论](https://linux.do/t/topic/726964/4)
- [Android 17 initrc 注入失败案例](https://xdaforums.com/t/guide-kebab-kernelsu-next-modules-on-android-17-fixing-the-silent-init-rc-injection-failure.4809636/)
- [gbl_root_canoe / EFISP 假回锁](https://github.com/1vivy/gbl_root_canoe)
- [ko_uninstall 参考实现](https://github.com/kazaf080726/ko_uninstall)
