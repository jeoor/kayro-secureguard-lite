#!/system/bin/sh
# 开机完成只更新卡片结论，不统计检测信息。
T=oplus_secure_guard_new
if grep -q "^$T " /proc/modules 2>/dev/null; then
    desc="⚠️ 未卸载"
else
    desc="✅ 已完成卸载"
fi
KSU_MODULE=kayro_secureguard /data/adb/ksud module config set --temp override.description "$desc" >/dev/null 2>&1
exit 0
