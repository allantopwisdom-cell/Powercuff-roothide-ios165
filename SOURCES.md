# GitHub 搜索与采用依据

检索日期：2026-11-26（北京时间）。以下仓库均通过 GitHub API 搜索及公开源码核对；仓库名称或介绍不能证明支持特定系统。

| 项目 | 结论 |
| --- | --- |
| [rpetrich/Powercuff](https://github.com/rpetrich/Powercuff) | 原版；采用其热模拟机制、模式映射、作者归属及设置布局。原构建依赖旧 framework 子模块，不适用于直接构建本目标。 |
| [Mikasa-san/Powercuff](https://github.com/Mikasa-san/Powercuff) | 简化改版；同一个 token 被两次通知注册覆盖，且两个进程都会发布模式，不作为基础。 |
| [Baldaran/Powercuff-r3vamp](https://github.com/Baldaran/Powercuff-r3vamp) | 包含 GPProduct fallback；用检测 `/var/jb` 拼接偏好路径，不适合直接用作 roothide 适配依据。 |
| [Baldaran/Powercuff-MOD](https://github.com/Baldaran/Powercuff-MOD) | 另一改版；未发现它提供目标 roothide 环境的可验证支持证据。 |
| [a-user-of-python/powercuff](https://github.com/a-user-of-python/powercuff) | 普通 rootless port 与 Actions，可参考 CI 思路；不是原生 roothide 包。 |
| [tomaszpoliszuk/ActivatorListenerForPowercuff](https://github.com/tomaszpoliszuk/ActivatorListenerForPowercuff) | Activator 扩展，不是 Powercuff 核心，本工程不需要。 |
| [brkr1/PowerCuffAutoOff](https://github.com/brkr1/PowerCuffAutoOff) | 充电时自动关闭的辅助插件，本工程不需要。 |
| [herrbimmer/PowerCuff](https://github.com/herrbimmer/PowerCuff) | macOS 软件，与本次 iOS 插件无关。 |

采用的原版提交：`a97c445a4a8fd2ce1cfe9fbc16fdf82a930b62d1`。

构建使用 [roothide/theos](https://github.com/roothide/theos) 提交 `958fea4f779943505b15b93c88bb4db8d97b346d`，子模块固定于该提交。其 `vendor/mod/roothide/package/deb.mk` 将 Debian 架构设为 `iphoneos-arm64e`；动态库安装名使用 loader 相对的 `.jbroot`。本工程不把文件硬编码安装到 `/var/jb`，也不要求用户填写随机 jbroot。

[iOS SDK 来源：theos/sdks](https://github.com/theos/sdks)。CI 固定 SDK 仓库提交，使用 iPhoneOS16.5.sdk。SDK 不放入本源码归档。

## 许可证与归属

原版仓库在上述提交没有 LICENSE 文件；GitHub 元数据 license 为 null。保留 Ryan Petrich 的作者信息、上游链接及设置页版权信息。未将任意分支的授权推定为原版许可，也未给上游代码添加新许可证。GitHub 的公开代码及 fork 功能不等同于任意用途的开源授权；进一步分发请遵守上游权利及 GitHub 相关条款。

## 目标支持的证据范围

用户给出的设备和版本作为工程目标，不作为已经验证过的兼容性声明。没有读取目标 iPhone 的 thermalmonitord 二进制或真机日志；CommonProduct 方法在 A16/iOS16.5 上的可用性需要真机确认。源码对缺失的类和方法会跳过 hook 并输出日志。
