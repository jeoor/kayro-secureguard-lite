# 变更记录

## v2.0.2 · 2026-11-22

- Action 修复：`/proc/modules` 不可读时显示 UNKNOWN，不再当成“未加载”。
- `dmesg` 不可读时拦截计数显示 UNKNOWN；统计只匹配 `secureguard_new` 的 `execve_block`/`need kill`。
- 增加 `ksud --version` 执行检查；结论改为“当前快照未观察到”，不再声称 ksud 永不被拦截。
- 卡片写入失败会显式输出；版本提升，initrc 卸载逻辑未变。

## v2.0.1 · 2026-11-22


- 增加 `on property:sys.boot_completed=1` 的一次性 final 服务：复核并在必要时卸载，同时刷新模块卡片。
- 卡片改用临时 `override.description`：开机完成写一次，Action 点击时再写一次；无常驻、无轮询。
- Action 改为格式化输出目标状态、`execve_block`、`need kill`、涉及 `ksud` 次数。
- 两轮完整重启验证：early 2.19–2.96s、final 19.63–21.07s 均退出 0；目标未加载，假回锁属性不变。

## v2.0.0 · 2026-11-22

- 改为 initrc 注入 + init 服务：`on post-fs` 在 ksu 域内联轮询并 `rmmod`，早于 `ksud` 被拦截。
- 只处理 `oplus_secure_guard_new`，保留 `inte`、`oplus_secure_common`、`cdt_integrity`。
- 删除诊断版状态机、WebUI、守护进程和多余兜底脚本。

## v1.0.1 · Phase 1

- 识别真实 OPlus 标签，分别统计 `execve_block`、`execve_report`、`need kill` 和 `ksud`。
- 加入 `remove_oplus_guard`，补齐 KernelSU CLI 回退及只读能力检查。
- 在 PLZ110 上通过 ADB Root 与设备 BusyBox 验证只读诊断 ZIP。
