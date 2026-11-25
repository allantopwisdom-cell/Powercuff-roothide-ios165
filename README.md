# Powercuff：roothide 适配工程

目标设备：iPhone 14 Pro Max（A16，iPhone15,3），iOS 16.5，用户提供的越狱版本 roothide Dopamine 3.0.13-30。

本工程基于 Ryan Petrich 的 Powercuff。它通过 thermalmonitord 的私有热模拟接口请求系统节流，并不直接设置 CPU/GPU 频率。实际频率、充电速度、显示亮度和流畅度由系统决定。构建通过不能证明这些私有接口在目标设备有效。

## 构建与安装

- 原生 roothide 包：`THEOS_PACKAGE_SCHEME=roothide`，Debian 架构 `iphoneos-arm64e`，Mach-O 架构 `arm64e`，iOS 14+ ABI。
- 不能将普通 `iphoneos-arm64` 的 rootless 包改名后当作 roothide 包安装。
- 使用 roothide 自己的软件源安装 PreferenceLoader 和 tweak 注入依赖。
- 与原版共用 `com.rpetrich.powercuff` 包标识和设置域，用于替换原版；旧设置会保留，安装前请先将节流改为“关闭”。
- 注入仅限 `thermalmonitord`、`SpringBoard`。未硬编码 `/var/jb`、随机 jbroot 或偏好文件绝对路径。

### GitHub Actions

将本目录内容完整推送到自己的仓库 `main` 分支（包括 `.github/workflows/build.yml`）。默认每次 push 触发，也可到 Actions → Build roothide deb → Run workflow 手动运行。完成后在运行页面的 Artifacts 下载 `Powercuff-roothide-arm64e`，解压可得 deb 和校验值。Artifacts 是构建产物，不会自动发布 Release。

Actions 使用 macOS、固定版本 roothide Theos 和 iOS 16.5 SDK。无需 Apple 开发者账号、证书或仓库 Secrets；上传源码仍需要用户自己的 GitHub 登录权限。

本机已具备同样依赖时：

```sh
export THEOS=/absolute/path/to/roothide-theos
python3 scripts/validate.py
make package
python3 scripts/validate.py --packages packages
```

### 在 iPhone 上验证

1. 将旧 Powercuff 节流设为关闭，卸载冲突的 Powercuff 改版。
2. 使用 roothide 环境里的 Sileo 安装此 deb；安装后完成一次用户空间重启（Userspace Reboot），让 thermalmonitord 和 SpringBoard 重新加载。工程不提供自动杀进程的安装脚本。
3. 到“设置 → Powercuff”，先选“轻度”，对比固定负载下的表现；再打开“仅低电量模式启用”，验证低电量开关能实时控制。
4. 切回“关闭”应恢复系统策略。若无效果，检查两个进程是否允许注入、CommonProduct 是否仍提供目标方法，并查看系统日志中的 `[Powercuff]`。需要真机日志才能继续诊断，不能仅凭安装成功推断有效。
5. 卸载前先关闭节流；卸载后再次用户空间重启。若卡顿严重，用越狱的禁用 tweak 注入功能启动后卸载。

## 实现调整

保留原作五档模式（off/nominal/light/moderate/heavy），使用独立的通知注册，限制输入范围。只有 SpringBoard 读取并发布偏好；thermalmonitord 只消费模式。使用公开 `NSProcessInfoPowerStateDidChangeNotification` 和 `isLowPowerModeEnabled` 监听低电量状态。正确使用 CF 通知回调签名，保留目标对象释放清理，检查私有方法存在后才 hook。

设置 UI 默认值为关闭，但替换安装时旧偏好仍会生效。没有引入未经目标系统验证的 GPProduct fallback、`nil` 重置或强制覆盖真实热传感器逻辑。

## 验证边界与源码来源

`validate.py` 检查 plist、默认值、通知目标、deb 实际架构、arm64e ABI 和包内路径。它不会在 iPhone 上运行插件，也不验证续航收益。没有访问或测试用户的 iPhone；具体越狱版本号是用户提供的信息。

来源、比较结果和许可证状态见 `SOURCES.md`。上游没有许可证文件，本工程保留作者归属，不擅自为上游代码添加 MIT/GPL 授权；GitHub 上的派生仓库应保留来源和修改记录。
