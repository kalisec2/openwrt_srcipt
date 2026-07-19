
#!/bin/sh
# =============================================
# OpenClash 一键安装脚本 for OpenWRT
# 作者: Grok 助手
# =============================================

set -e  # 遇到错误立即退出

echo "🚀 OpenClash 一键安装脚本启动..."

# 检查 root 权限
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 错误：请使用 root 权限运行此脚本 (sudo 或 ssh root)"
    exit 1
fi

echo "📦 更新 opkg 软件源..."
opkg update

echo "📥 安装依赖包..."
opkg install bash iptables dnsmasq-full curl ca-bundle ipset ip-full \
    iptables-mod-tproxy iptables-mod-extra ruby ruby-yaml kmod-tun \
    kmod-inet-diag unzip luci-compat luci luci-base rpcd rpcd-mod-file \
    rpcd-mod-luci luci-lib-jsonc || {
        echo "⚠️ 部分依赖安装失败，继续尝试安装 OpenClash..."
    }

echo "🌐 获取 OpenClash 最新版本..."
curl -L --retry 3 --connect-timeout 10 \
    https://gh-proxy.org/https://api.github.com/repos/vernesong/OpenClash/releases/latest \
    -o /tmp/openclash_version.json

if [ ! -s /tmp/openclash_version.json ]; then
    echo "❌ 错误：无法获取 OpenClash 版本信息"
    exit 1
fi

download_url=$(cat /tmp/openclash_version.json | jsonfilter -e '@.assets[*].browser_download_url' | grep '\.ipk$' | head -n 1)

if [ -z "$download_url" ]; then
    echo "❌ 错误：未找到 OpenClash IPK 下载链接"
    exit 1
fi

echo "⬇️ 下载 OpenClash: $download_url"
curl -L --retry 3 --connect-timeout 15 "$download_url" -o /tmp/openclash.ipk

if [ ! -s /tmp/openclash.ipk ]; then
    echo "❌ 错误：下载 OpenClash 失败"
    exit 1
fi

echo "📦 安装 OpenClash..."
opkg install /tmp/openclash.ipk

echo "🧹 清理临时文件..."
rm -f /tmp/openclash_version.json /tmp/openclash.ipk

echo "✅ OpenClash 安装完成！"
echo "========================================"
echo "建议操作："
echo "1. 重启路由器: reboot"
echo "2. 在 LuCI 界面 → 服务 → OpenClash 进行配置"
echo "3. 如遇问题，可尝试: opkg update && opkg install openclash"
echo "========================================"
