# PLZ110 实机报告

## 设备

| 项目 | 值 |
|---|---|
| 型号 | 一加 15T `PLZ110`（`OP64DDL1`） |
| 系统 | ColorOS 17 / Android 17 |
| Build fingerprint | `OnePlus/PLZ110/OP64DDL1:17/CP2A.260605.016/B.538ec70-2cc19a2-2cc2343:user/release-keys` |
| 内核 | `6.12.69-android16-6-g5fd39602326e-ab16372235-4k` |
| KernelSU | Manager/ksud 3.3.1（32680），UAPI 5，LKM，`late_load=false` |
| SELinux | Enforcing |
| Root 环境 | 免解 + EFISP 伪回锁（维修部 vendor_boot） |
| 假回锁 | `fake_bl_efisp` / gbl_root_canoe（EFISP/ABL 层） |

## 根因

`oplus_secure_guard_new` 是 ColorOS 的系统完整性校验内核模块，实测在启动约 3.4 秒时拦截 `ksud`：

```text
[secureguard_new][root_check] ... execve_block
[secureguard_new][root_check] ... need kill! (/data/adb/ksud)
```

约 4.9 秒还会拦截执行模块脚本的 busybox。因此 `post-fs-data.sh`（约 5 秒）执行 `rmmod` 已经太晚。

## v2.0.1 结果

| 项目 | 结果 |
|---|---|
| early 服务 | 2.17–2.19s 启动；2.93–2.96s 退出 0 |
| final 服务 | 19.22–19.63s 启动；20.00–21.07s 退出 0 |
| 目标模块 | 连续重启后均未加载；256s 后仍为 0 |
| 30 次 `su` | `execve_block 0`、`need kill 0`、涉及 `ksud 0` |
| 常驻进程/告警 | 无 `ksud`/`kayro` 进程；无相关 alarm |
| 卡片 | v2.0.1，动态描述 `ACTIVE · SecureGuard 已卸载 · 拦截 0 次` |
| 假回锁属性 | `verifiedbootstate=green`、`flash.locked=1`、`vbmeta.device_state=locked` |
| vendor_boot | `oplus_secure_guard_new.ko` 92,000 字节，原样存在 |
| 模块字段 | enabled=true、action=true、web=false、update=false |

## 关于 19.5s 的 `KERNEL_SECURITY_CHECK`

该日志把 560 个 `.ko` 文件名登记进 OPlus ACE 哈希表，包括 `oplus_secure_guard_new.ko`，**不是加载模块**；目标计数始终为 0，`[last unloaded]` 指 2.9s 的卸载。该检查读取的是 vendor_dlkm 文件，本项目未删除/替换文件，因此不冲突。

## 结论

只卸载 `oplus_secure_guard_new` 即可消除对 `ksud` 的拦截；`inte`、`oplus_secure_common`、`cdt_integrity` 保持加载。模块不修改分区、不改回锁属性、不常驻。
