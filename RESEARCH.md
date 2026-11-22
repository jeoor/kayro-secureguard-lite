# 上游调研与结论

## 关键资料

| 来源 | 结论 |
|---|---|
| [KernelSU initrc 注入](https://kernelsu.org/guide/module.html#initrc-injection) | 模块 `initrc/*.rc` 在 init 读取 init.rc 时追加，早于 `post-fs-data`；支持 service/trigger/property 触发。 |
| [KernelSU #3908](https://github.com/tiann/KernelSU/pull/3908) | `oplus_secure_guard_new.ko` 位于 `modules.load.recovery`；启动加载阶段 block 会让 recovery 失败或 bootloop。因此不采用 `block_modules`/boot-patch。 |
| [Android 17 initrc 注入失败案例](https://xdaforums.com/t/guide-kebab-kernelsu-next-modules-on-android-17-fixing-the-silent-init-rc-injection-failure.4809636/) | Android 17 的 init 改为 `fstat` + 单次 `read_iter`，部分 KernelSU-Next legacy 构建的追加注入会静默失败。本机 KernelSU 3.3.1 mainline 实测注入成功。 |
| [OPlus Kernel Lab](https://xdaforums.com/t/kernel-oos-aosp-oplus-kernel-lab.4782243/page-43#post-90777719) | 社区把 `oplus_secure_guard` 与 `_new` 加入 vendor blacklist，确认目标是 vendor 完整性模块；该做法要改 boot/vendor_boot。 |
| [Coolapk 内核模块清单](https://www.coolapk.com/feed/74597659) | `oplus_security_guard`/`oplus_secure_guard_new` 是系统完整性校验；`oplus_security_keventupload` 上传内核安全事件。 |
| [知乎：inte 与 ACE](https://www.zhihu.com/question/2089675358908040541/answer/2092690033698460930) | `inte` 是腾讯 ACE 内核完整性检测，开机与每小时做哈希比对，功耗很低；不是结束 ksud 的模块。 |
| OPlus ACE `oplus_kernel_security_check.c` 社区说明 | `KERNEL_SECURITY_CHECK` 属于内核完整性检测（系统调用表 / ko 完整性）。实机 19.5s 的 `Added:` 日志是登记 560 个 `.ko` 文件名到哈希表，不是加载模块。 |
| [gbl_root_canoe](https://github.com/1vivy/gbl_root_canoe) | 假回锁在 EFISP/ABL 层完成；WebUI 只检查 vendor_boot ramdisk 是否含 `oplus_secure_guard_new`，不改运行时模块。 |
| [ko_uninstall](https://github.com/kazaf080726/ko_uninstall) | 其守护进程主要盯 `inte` 家族的复活；本项目目标在实测中不会重载，因此不引入常驻守护。 |
| [酷安：一加 15 EFISP/免解教程](https://www.coolapk.com/feed/71668307) | 免解/EFISP 伪回锁会修改或依赖 vendor_boot，是 PLZ110 上跑 ksud 的常见路径；但 `need kill` 指向 ksud 执行，不能据此证明只有伪回锁环境才会触发。 |

## 最终判断

- 直接结束 `ksud` 的日志标签只来自 `[secureguard_new]`；卸载该模块后 30 次 `su` 无新增 `need kill`/`execve_block`。
- `inte`、`oplus_secure_common`、`cdt_integrity` 不参与这次拦截；保留它们更稳定，也不影响游戏/支付相关组件。
- 采用 initrc 服务而不是模块脚本：目标在 `/data` 挂载前加载，模块脚本约 5 秒才运行，已晚于 3.4 秒的拦截。
- 不采用启动期 block：会改 boot 分区，且 #3908 证明可能破坏 recovery，也可能与 EFISP 假回锁冲突。
- 不采用强制卸载：非强制 + 重试即可，失败保持原状，避免内核崩溃。
- 不采用守护进程：实测目标只在启动阶段加载，卸载后到 256s 未重载；常驻监控只会增加待机功耗。final 服务已覆盖 boot 完成前的复核，之后由 Action 手动刷新。
- 免解/伪回锁与本问题目前是**相关性**，不是已证明的因果：本机是免解 + EFISP 伪回锁环境，SecureGuard 的 `need kill` 指向 `ksud`；正常解锁/其它 root 环境未验证，不能写成“只对伪回锁生效”。
