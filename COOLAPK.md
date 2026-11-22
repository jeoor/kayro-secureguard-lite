# 一加 ColorOS 17 免解/伪回锁：SecureGuard 拦截 ksud 的实测与处理

> Kayro SecureGuard Lite v2.0.2 · 实测版，不是长期稳定版  
> PLZ110 / ColorOS 17 / KSU 3.3.1 / 免解 + EFISP 伪回锁（未修补 vendor_boot）

## 问题

`ksud` 被 `oplus_secure_guard_new` 反复拦截、结束：

```text
[secureguard_new][root_check] ... execve_block
[secureguard_new][root_check] ... need kill! (/data/adb/ksud)
```

普通 `post-fs-data.sh` 没用：目标约 1.6s 加载，`ksud` 约 3.4s 被拦，模块脚本约 5s 才跑。

## 只卸一个就够

直接结束 `ksud` 的标签只有 `[secureguard_new]`。卸载后 30 次 `su`，`execve_block` / `need kill` 都是 0。

`inte` 是腾讯 ACE，`oplus_secure_common` 涉及指纹支付，`cdt_integrity` 是系统组件；它们不参与，保留。

## 做法

- KSU `initrc` 注入两个一次性服务。
- early：`post-fs` 起轮询，目标出现即非强制 `rmmod`，失败重试，最多 6 秒。
- final：`boot_completed` 复核一次，刷新卡片。
- 无守护进程、无 WebUI、不改分区、不碰假回锁、不用 `rmmod -f`。

## 实测

- early 2.19–2.96s、final 19.63–21.07s 退出 0。
- 重启后目标未加载，256s 仍为 0。
- 假回锁 green / 1 / locked 保持；vendor_boot 的 ko 原样存在。
- 19.5s `KERNEL_SECURITY_CHECK: Added` 是 560 个 `.ko` 表登记，不是加载。

## 安装

1. 下载 [v2.0.2 Release](https://github.com/jeoor/kayro-secureguard-lite/releases/tag/v2.0.2) 的 ZIP。
2. 管理器安装，重启；点 Action 复核。

```text
SHA-256 4cd0283e5ef1d85b9aa01941f6959090b244afd9187ba036aafe95cc7090fe03
```

卸载或禁用并重启即恢复原状。

## 注意

- 仅 PLZ110 / ColorOS 17 / KSU 3.3.1 / 免解 + 未修补 vendor_boot 实测；OTA、late-load、正常解锁、修补 vendor_boot 未验证。
- 机制上是 root/ksud 触发，不是伪回锁本身；不是所有免解/伪回锁机器都一定触发，先看 `dmesg | grep secureguard_new`。
- initrc 在 KSU 安全模式下仍会执行；early 在 `post-fs` 运行，安全模式挡不住那次 `rmmod`。依赖安全模式完全禁用者勿装。
- 卡片是快照；boot 完成后变化需点 Action 刷新。

## 开源

[GitHub](https://github.com/jeoor/kayro-secureguard-lite) · [Release](https://github.com/jeoor/kayro-secureguard-lite/releases/tag/v2.0.2) · MIT

配图建议：模块卡片、Action 输出、`dmesg | grep kayro_sg_`。
