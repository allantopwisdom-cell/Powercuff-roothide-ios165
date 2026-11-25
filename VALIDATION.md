# 构建验证记录

目标：iPhone 14 Pro Max / iOS 16.5 / roothide Dopamine 3.0.13-30（设备与越狱版本由用户提供）。

- 源码与 plist 静态检查：通过。
- Logos 预处理、Objective-C 编译（包含 -Werror）、链接、签名、Debian 打包：在本机 Linux aarch64 工具链上通过。
- 包的 `iphoneos-arm64e` 元数据、实际 arm64e Mach-O 和 roothide 目录布局：通过检查。
- **本机产物的 iOS 14+ arm64e ABI：未通过。** Apple clang 13 Linux 交叉工具链生成 CPU subtype `0x2`，链接器也报告 ABI 不兼容。校验器已按预期拒绝。该 deb 仅供本地检查，不放入交付压缩包，不能作为安装包使用。
- GitHub Actions run [45716609594](https://github.com/allantopwisdom-cell/Powercuff-roothide-ios165/actions/runs/45716609594) succeeded on macOS 15 for commit `c626e140741714b46b30daf999193ddfc6ca31ca`; workflow steps, including ABI/package validation and artifact upload, all passed.
- Downloaded CI deb: the independent validator confirmed its roothide payload layout and arm64e subtype `0x80000002` (iOS 14+ ABI), with a 69,568-byte tweak binary. This first artifact's checksum list used a repository-root-relative path, so this source revision fixes it to be artifact-root-relative; verify the next Actions artifact before relying on its SHA256SUMS.
- 真机安装与节流效果：未验证。没有访问用户 iPhone。

请以最新 GitHub Actions 运行结论和下载 deb 的校验结果为准。源码归档不包含 SDK、工具链、凭据或未经通过的本机 deb。
