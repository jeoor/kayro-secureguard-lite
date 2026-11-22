#!/system/bin/sh
# Action：单次诊断并刷新卡片；不常驻、不写持久配置。
T=oplus_secure_guard_new
KSUD=/data/adb/ksud
V=2.0.2

if [ -r /proc/modules ]; then
    if grep -q "^$T " /proc/modules 2>/dev/null; then loaded=1; else loaded=0; fi
else
    loaded=unknown
fi

if dmesg >/dev/null 2>&1; then
    set -- $(dmesg 2>/dev/null | awk '
        /secureguard_new/ {
            if (/execve_block/) b++
            if (/need kill/) { k++; if (/ksud/) s++ }
        }
        END { printf "%d %d %d\n", b+0, k+0, s+0 }')
    b=$1 k=$2 s=$3
else
    b=unknown k=unknown s=unknown
fi

if [ -x "$KSUD" ] && "$KSUD" --version >/dev/null 2>&1; then ksud=ok; else ksud=fail; fi

case "$loaded" in
    1) if [ "$b" = unknown ]; then desc="WARN · SecureGuard 仍加载 · 日志不可读"; else desc="WARN · SecureGuard 仍加载 · 拦截 $b 次"; fi ;;
    0)
        if [ "$b" = unknown ]; then
            desc="UNKNOWN · 目标未加载 · 日志不可读"
        elif [ "$k" -gt 0 ]; then
            desc="ACTIVE · 已卸载 · 历史拦截 $k 次"
        else
            desc="ACTIVE · SecureGuard 未加载 · 未观察到 ksud 拦截"
        fi ;;
    *) desc="UNKNOWN · /proc/modules 不可读" ;;
esac
if ! KSU_MODULE=kayro_secureguard "$KSUD" module config set --temp override.description "$desc" >/dev/null 2>&1; then
    card=fail
else
    card=ok
fi

printf 'Kayro SecureGuard Lite v%s\n' "$V"
printf '%s\n' '------------------------'
case "$loaded" in
    1) printf '目标：已加载\n' ;;
    0) printf '目标：未加载\n' ;;
    *) printf '目标：未知（/proc/modules 不可读）\n' ;;
esac
printf '执行拦截：%s 次\n' "$b"
printf 'need kill：%s 次\n' "$k"
printf '涉及 ksud：%s 次\n' "$s"
if [ "$ksud" = ok ]; then printf 'ksud 执行：正常\n'; else printf 'ksud 执行：失败\n'; fi
if [ "$card" = fail ]; then printf '卡片刷新：失败\n'; fi
case "$loaded" in
    1) printf '结论：SecureGuard 仍在运行，可能继续拦截 ksud。\n' ;;
    0)
        if [ "$b" = unknown ]; then
            printf '结论：目标未加载，但内核日志不可读，无法判断历史拦截。\n'
        elif [ "$k" -gt 0 ]; then
            printf '结论：目标已卸载；本启动周期卸载前有 %s 次 need kill。\n' "$k"
        else
            printf '结论：当前快照未观察到 SecureGuard 拦截 ksud；不保证未来或其它进程。\n'
        fi ;;
    *) printf '结论：状态未知，无法判断 ksud 是否会被拦截。\n' ;;
esac
exit 0
