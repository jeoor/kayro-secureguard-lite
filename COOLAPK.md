# 一加 ColorOS 17：让 ksud 不再被 SecureGuard 结束

> Kayro SecureGuard Lite v2.0.1 · KernelSU
> 实测环境：一加 15T PLZ110 / ColorOS 17 / KSU 3.3.1 / 免解 + EFISP 伪回锁（维修部 vendor_boot）

## 问题

在 PLZ110 上，KernelSU 的 `ksud` 会被 `oplus_secure_guard_new` 反复拦截/结束：

```text
[secureguard_new][root_check] ... execve_block
[secureguard_new][root_check] ... need kill! (/data/adb/ksud)
```

表现是 `ksud` 反复被杀、安全警告弹窗、后台反复唤醒。普通 `post-fs-data.sh` 没用：目标约 1.6s 加载，`ksud` 约 3.4s 被拦，而模块脚本约 5s 才执行。

## 只卸一个就够

实机日志里，直接结束 `ksud` 的标签只有 `[secureguard_new]`。卸载 `oplus_secure_guard_new` 后连续 30 次 `su`，`execve_block` 和 `need kill` 都是 0。

`inte` 是腾讯 ACE 的内核完整性检测，`oplus_secure_common` 涉及指纹支付等公共能力，`cdt_integrity` 是系统组件；它们不参与这次拦截，所以**没有动**。少卸一个模块，少一分游戏/支付/稳定性风险。

## 适用环境

本机是 **免解 + EFISP 伪回锁（维修部 vendor_boot）** 环境。`need kill` 指向 `/data/adb/ksud`，机制上是 **root/ksud 执行触发**，不是伪回锁本身；免解/伪回锁是 PLZ110 上跑 ksud 的常见路径，所以现象集中在这类机器。正常解锁、其它 root 管理器或其它 ColorOS 版本未验证；先看 `dmesg | grep secureguard_new` 有没有 `need kill` 再决定。

## 做法

用 KernelSU 的 initrc 注入，在 `init.rc` 里追加两个一次性服务：

- `kayro_sg_early`：`on post-fs` 启动，`seclabel u:r:ksu:s0`，在 ksu 域轮询 `/proc/modules`；目标出现就非强制 `rmmod`，失败重试，最多 6 秒。
- `kayro_sg_final`：`sys.boot_completed=1` 时复核一次；若目标在 boot 完成前被重新加载，就地卸载并刷新卡片。

没有守护进程、没有 WebUI、没有后台循环。不修改分区、不碰 EFISP/假回锁、不在启动加载阶段 block（`oplus_secure_guard_new` 在 `modules.load.recovery` 里，启动期 block 有 recovery 风险），也不用 `rmmod -f`。

模块卡片会显示：

```text
ACTIVE · SecureGuard 已卸载 · 拦截 0 次
```

点 Action 可随时重新检测并刷新卡片。

## 实测

| 项目 | 结果 |
|---|---|
| early 服务 | 2.19–2.96s 启动并退出 0 |
| final 服务 | 19.63–21.07s 启动并退出 0 |
| 目标模块 | 两轮重启后均未加载 |
| 30 次 `su` | 执行拦截 0、need kill 0、涉及 ksud 0 |
| 常驻进程/告警 | 无 ksud/kayro 进程，无相关 alarm |
| 假回锁 | green / 1 / locked 保持不变 |
| vendor_boot | `oplus_secure_guard_new.ko` 原样存在 |

补充：`dmesg` 里 19.5s 的 `[KERNEL_SECURITY_CHECK]: Added: oplus_secure_guard_new.ko` 是 OPlus ACE 把 560 个 `.ko` 文件名登记进哈希表，不是重新加载；目标计数一直为 0。

## 和假回锁的关系

假回锁 `fake_bl_efisp` 在 EFISP/ABL 层，本项目完全不碰。我们没有删/替换 vendor_boot 里的 ko，gbl_root_canoe 的 vendor_boot 检查仍然成立；recovery 也仍按原样加载该模块，不会触发启动期 block 的 recovery 问题。

## 安装

1. 下载 Release 里的 `kayro_secureguard-v2.0.1.zip`。
2. KernelSU 管理器本地安装，重启。
3. 开机后看模块卡片；点 Action 可复核。

```text
SHA-256: 9df6ce309b64dd262709b5a7b4d6c5146901553cfcad01bc100b8d070da50391
```

卸载或禁用模块并重启，`oplus_secure_guard_new` 会随系统正常加载，恢复原状。

## 注意

- 仅 PLZ110 / ColorOS 17 / KernelSU 3.3.1 mainline + 免解/伪回锁环境实测；OTA、其它 ColorOS 版本、late-load、正常解锁环境未验证。
- 不是所有免解/伪回锁机器都一定触发；先看 `dmesg | grep secureguard_new`，有 `need kill` 再装。
- Android 17 上部分 KernelSU-Next legacy 构建存在 initrc 注入静默失败；换管理器后先看 `dmesg | grep kayro_sg_`。
- 这是有意移除厂商完整性检查，会降低 SecureGuard 的检测能力。
- 卡片是快照；正常运行时目标不会重载，boot 完成后的外部变化需点 Action 刷新。自动实时监控需要常驻进程，会增加待机功耗，所以没做。

## 开源

GitHub：https://github.com/jeoor/kayro-secureguard-lite  
Release：https://github.com/jeoor/kayro-secureguard-lite/releases/latest  
MIT License，欢迎 issue / PR 补充其它机型与固件的数据。

---

配图建议：模块卡片、Action 输出、`dmesg | grep kayro_sg_` 两行服务日志。
