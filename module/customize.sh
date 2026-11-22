#!/system/bin/sh
prop="$MODPATH/module.prop"
version=$(sed -n 's/^version=//p' "$prop" 2>/dev/null)
author=$(sed -n 's/^author=//p' "$prop" 2>/dev/null)
ui_print "Kayro SecureGuard Lite ${version:-unknown}"
ui_print "Author : ${author:-unknown}"
ui_print "Target : oplus_secure_guard_new"
ui_print "Boot   : post-fs 自动卸载 + boot_completed 兜底"
ui_print "Action : 点击运行检测"
