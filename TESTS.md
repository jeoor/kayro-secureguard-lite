# 测试结果

## v2.0.1 实测（initrc 与 v2.0.2 相同）

| 测试 | 结果 |
|---|---|
| 两轮完整重启 | early 2.19–2.96s、final 19.63–21.07s 均退出 0 |
| 目标状态 | 每次重启后 `/proc/modules` 无 `oplus_secure_guard_new`；256s 后仍为 0 |
| 30 次 `su` | 新增 `execve_block 0`、`need kill 0`、涉及 `ksud 0` |
| 常驻进程 | 无 `ksud`/`kayro` 进程 |
| 唤醒告警 | `dumpsys alarm` 无 ksud/kayro 条目 |
| 卡片 | v2.0.1 动态描述正确；v2.0.2 Action 未实机安装 |
| 假回锁 | green / 1 / locked 在每次重启后保持 |
| vendor_boot | `oplus_secure_guard_new.ko` 未改动 |
| Action | 目标未加载；执行拦截 0；need kill 0；涉及 ksud 0 |
| 模块字段 | enabled=true、action=true、web=false、update=false |
| ZIP | 2,891 字节；SHA-256 `4cd0283e5ef1d85b9aa01941f6959090b244afd9187ba036aafe95cc7090fe03` |

> v2.0.2 只改 Action 诊断与版本；启动卸载逻辑与 v2.0.1 相同。按用户要求未在实机安装 v2.0.2。Action 的 UNKNOWN 分支为代码审查，未强制制造不可读场景。

## 未覆盖

- OTA 后的新固件、其它 ColorOS 版本、late-load 模式。
- 游戏反作弊、支付、相机等业务功能的长期回归。
- `inte` 的每小时哈希比对未做专项功耗测量；本项目不卸载它。
- 卡片快照语义：正常运行时目标不会重载；若后期变化，需点 Action 刷新。
- Action 的 `/proc/modules`、`dmesg` 不可读分支未做设备强制测试。

## 复现

```sh
# 模块字段与卡片
/data/adb/ksud module list

# 目标与拦截计数
grep -c '^oplus_secure_guard_new ' /proc/modules
dmesg | grep -c execve_block
dmesg | grep -c 'need kill'

# init 服务是否执行
dmesg | grep -E 'kayro_sg_early|kayro_sg_final'

# Action
sh /data/adb/modules/kayro_secureguard/action.sh

# 假回锁属性
getprop ro.boot.verifiedbootstate
getprop ro.boot.flash.locked
getprop ro.boot.vbmeta.device_state
```
