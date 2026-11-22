#!/system/bin/sh
# Action：单次诊断，不常驻、不写配置。
T=oplus_secure_guard_new
KSUD=/data/adb/ksud
V=2.0.10

if [ -r /proc/modules ]; then
    grep -q "^$T " /proc/modules 2>/dev/null
    rc=$?
    case "$rc" in
        0) loaded=1 ;;
        1) loaded=0 ;;
        *) loaded=unknown ;;
    esac
else
    loaded=unknown
fi

if _dmesg=$(dmesg 2>/dev/null); then
    set -- $(printf '%s\n' "$_dmesg" | awk '
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

printf 'Kayro SecureGuard Lite v%s\n' "$V"
printf '%s\n' '------------------------'
case "$loaded" in
    1) printf '目标：已加载\n' ;;
    0) printf '目标：未加载\n' ;;
    *) printf '目标：未知（/proc/modules 读取失败）\n' ;;
esac
printf '执行拦截：%s 次\n' "$b"
printf 'need kill：%s 次\n' "$k"
printf '涉及 ksud：%s 次\n' "$s"
if [ "$ksud" = ok ]; then printf 'ksud 执行：正常\n'; else printf 'ksud 执行：失败\n'; fi
case "$loaded" in
    1) printf '结论：SecureGuard 仍在运行，可能继续拦截 ksud。\n' ;;
    0)
        if [ "$b" = unknown ]; then
            printf '结论：目标未加载，但内核日志不可读，无法判断历史拦截。\n'
        elif [ "$b" -gt 0 ] || [ "$k" -gt 0 ]; then
            printf '结论：本启动周期观察到 SecureGuard 拦截记录（execve_block %s，need kill %s）。\n' "$b" "$k"
        else
            printf '结论：当前快照未发现 SecureGuard 拦截 ksud。\n'
        fi ;;
    *) printf '结论：状态未知，无法判断 ksud 是否会被拦截。\n' ;;
esac
exit 0
