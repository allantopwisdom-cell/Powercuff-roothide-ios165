# 构建验证记录

目标：iPhone 14 Pro Max / iOS 16.5 / roothide Dopamine 3.0.13-30（设备与越狱版本由用户提供）。

- 源码与 plist 静态检查：通过。
- Logos 预处理、Objective-C 编译（包含 -Werror）、链接、签名、Debian 打包：在本机 Linux aarch64 工具链上通过。
- 包的 `iphoneos-arm64e` 元数据、实际 arm64e Mach-O 和 roothide 目录布局：通过检查。
- **本机产物的 iOS 14+ arm64e ABI：未通过。** Apple clang 13 Linux 交叉工具链生成 CPU subtype `0x2`，链接器也报告 ABI 不兼容。校验器已按预期拒绝。该 deb 仅供本地检查，不放入交付压缩包，不能作为安装包使用。
- GitHub Actions：已配置 macOS 15 + Apple 编译器、固定版本 roothide Theos 和 SDK，打包后再次校验实际 ABI。需要 GitHub 登录及运行成功后，才能称为云端编译通过。
- 真机安装与节流效果：未验证。没有访问用户 iPhone。

请以 GitHub Actions 的运行结论和实际下载的 deb 校验结果为准。源码归档不包含 SDK、工具链、凭据或未经通过的 deb。
