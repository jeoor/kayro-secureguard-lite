#!/system/bin/sh
# Action：检测一次并刷新模块卡片描述；不常驻、不写持久配置。
T=oplus_secure_guard_new
if grep -q "^$T " /proc/modules 2>/dev/null; then loaded=1; else loaded=0; fi
set -- $(dmesg 2>/dev/null | awk '
/execve_block/ { b++ }
/need kill/ { k++; if (/ksud/) s++ }
END { printf "%d %d %d\n", b+0, k+0, s+0 }')
b=$1; k=$2; s=$3

if [ "$loaded" = 1 ]; then
    desc="WARN · SecureGuard 仍加载 · 拦截 $b 次"
elif [ "$k" -gt 0 ]; then
    desc="ACTIVE · 已卸载 · 历史拦截 $k 次"
else
    desc="ACTIVE · SecureGuard 已卸载 · 拦截 0 次"
fi
KSU_MODULE=kayro_secureguard /data/adb/ksud module config set --temp override.description "$desc" >/dev/null 2>&1

printf 'Kayro SecureGuard Lite v2.0.1\n'
printf '%s\n' '------------------------'
if [ "$loaded" = 1 ]; then printf '目标：已加载\n'; else printf '目标：未加载\n'; fi
printf '执行拦截：%s 次\n' "$b"
printf 'need kill：%s 次\n' "$k"
printf '涉及 ksud：%s 次\n' "$s"
if [ "$loaded" = 1 ]; then
    printf '结论：SecureGuard 仍在运行，ksud 可能继续被拦截。\n'
else
    printf '结论：SecureGuard 已卸载，ksud 不再被拦截。\n'
fi
exit 0
