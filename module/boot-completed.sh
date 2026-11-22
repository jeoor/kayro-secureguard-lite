#!/system/bin/sh
# 开机完成再兜底卸载一次，然后只写卡片结论，不统计检测信息。
T=oplus_secure_guard_new
state() {
    grep -q "^$T " /proc/modules 2>/dev/null
    case $? in
        0) echo 1 ;;
        1) echo 0 ;;
        *) echo unknown ;;
    esac
}
if [ ! -r /proc/modules ]; then
    s=unknown
else
    s=$(state)
    if [ "$s" = 1 ]; then
        /system/bin/rmmod "$T" 2>/dev/null
        s=$(state)
    fi
fi
case "$s" in
    0) desc="✅ 已完成卸载 · 自动卸载 oplus_secure_guard_new" ;;
    1) desc="⚠️ 未卸载 · 自动卸载 oplus_secure_guard_new" ;;
    *) desc="⚠️ 状态未知 · 自动卸载 oplus_secure_guard_new" ;;
esac
KSU_MODULE=kayro_secureguard /data/adb/ksud module config set --temp override.description "$desc" >/dev/null 2>&1
exit 0
