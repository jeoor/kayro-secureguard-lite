# 实机验证记录

日期：2026-11-22  
设备：一加 15T `PLZ110`，ColorOS 17，KernelSU 3.3.1  
模块：`kayro_secureguard` v2.0.2  
环境：免解 + EFISP 伪回锁（未修补 vendor_boot）

## 通过项

- [x] 两轮完整重启：early 2.19–2.96s、final 19.63–21.07s 均退出 0。
- [x] 每次重启后 `oplus_secure_guard_new` 未加载；256s 后仍为 0。
- [x] 30 次 `su` 后无新增 `execve_block` / `need kill`。
- [x] 无 `ksud`/`kayro` 残留进程，无相关 alarm。
- [x] 卡片 v2.0.2 动态描述正确；web=false。
- [x] `ro.boot.verifiedbootstate=green`、`flash.locked=1`、`vbmeta.device_state=locked` 保持。
- [x] `vendor_boot` 中 `oplus_secure_guard_new.ko` 未改动。
- [x] `fake_bl_efisp` 保持启用。
- [x] Action 输出：目标未加载，执行拦截 0，need kill 0，涉及 ksud 0。

## 未覆盖

- 未在 OTA 后固件、其它 ColorOS 版本、late-load 模式验证。
- 未做游戏/支付/相机长期业务回归。
- `inte` 未卸载，未做专项功耗对比。
- 卡片快照：后期变化需点 Action 刷新。
