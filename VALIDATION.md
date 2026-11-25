# 构建验证记录

目标：iPhone 14 Pro Max / iOS 16.5 / roothide Dopamine 3.0.13-30（设备与越狱版本由用户提供）。

- 源码与 plist 静态检查：通过。
- Logos 预处理、Objective-C 编译（包含 -Werror）、链接、签名、Debian 打包：在本机 Linux aarch64 工具链上通过。
- 包的 `iphoneos-arm64e` 元数据、实际 arm64e Mach-O 和 roothide 目录布局：通过检查。
- **本机产物的 iOS 14+ arm64e ABI：未通过。** Apple clang 13 Linux 交叉工具链生成 CPU subtype `0x2`，链接器也报告 ABI 不兼容。校验器已按预期拒绝。该 deb 仅供本地检查，不放入交付压缩包，不能作为安装包使用。
- Initial GitHub Actions build run [45717275051](https://github.com/allantopwisdom-cell/Powercuff-roothide-ios165/actions/runs/45717275051) passed for commit `da0366747e0ce3268dc0c408b02a28db66d622ef`; its downloaded deb validated as roothide arm64e subtype `0x80000002`, with a 69,568-byte tweak binary. SHA256SUMS and Debian metadata/content checks passed; package SHA-256: `a92054d4b609de9e6719b484a72f408e137290a5774b88aef2498ab6a946cf4f`.
- 用户报告该版安装后 Settings 中没有 Powercuff 项。检查发现独立 PreferenceLoader plist 被放在 `Preferences/Powercuff/Powercuff.plist` 子目录；[PreferenceLoader 实现](https://github.com/DHowett/preferenceloader/blob/master/Tweak.xm) 会把嵌套目录按本地化 bundle 路径处理。修复已将其移至 `Preferences/Powercuff.plist`，并在校验器中加入平面路径断言。
- GitHub Actions 修复版构建 [45722567257](https://github.com/allantopwisdom-cell/Powercuff-roothide-ios165/actions/runs/45722567257) 在提交 `30c584d5c3fec911823416c06d3825ed3580dcb9` 上通过，ABI/package 校验与工件上传成功。
- 修复版 deb 独立验证通过：PreferenceLoader plist 位于 `Library/PreferenceLoader/Preferences/Powercuff.plist`；无旧嵌套注册 plist；arm64e subtype `0x80000002`，tweak 二进制 69,568 字节；SHA256SUMS、`dpkg-deb --info/--contents` 均通过。版本 `0.1.1~roothide2`，包大小 12,660 字节；SHA-256：`436e55dfeea014a264f80943a3ad7e290c0862e671aedaf146fdd739d79adfe8`。
- GitHub Release：[v0.1.1-roothide2](https://github.com/allantopwisdom-cell/Powercuff-roothide-ios165/releases/tag/v0.1.1-roothide2)，包含 deb 与 SHA256SUMS。
- 修复版尚未在真机复测。旧版设置入口缺失问题已定位并修正，需安装修复版后执行一次 Userspace Reboot 再确认。

请以最新 GitHub Actions 运行结论和下载 deb 的校验结果为准。源码归档不包含 SDK、工具链、凭据或未经通过的本机 deb。
