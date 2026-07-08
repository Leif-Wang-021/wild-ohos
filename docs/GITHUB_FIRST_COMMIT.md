# GitHub 首次提交前清单

这份清单用于上传 GitHub 前最后检查。当前仓库的定位是：`niuhuan/wild` 的非官方 HarmonyOS / OpenHarmony 移植分支。原版应用主体和开源基础来自上游 `wild`，本仓库新增的是鸿蒙移植、真机兼容、包体整理和相关修复。

## 建议仓库信息

仓库名称建议：

```text
wild-ohos
```

GitHub About 建议：

```text
轻小说文库(文库8)三方客户端 wild 的非官方鸿蒙移植分支。 (代码由 AI 辅助编写，人类调试修复)
```

Topics 建议：

```text
flutter, harmonyos, openharmony, ohos, wenku8, light-novel, reader, rust, flutter-rust-bridge
```

## 上传前文件清单

需要保留：

- `README.md`
- `LICENSE`
- `CHANGELOG.md`
- `pubspec.yaml`
- `pubspec.lock`
- `analysis_options.yaml`
- `flutter_rust_bridge.yaml`
- `lib/`
- `rust/`
- `rust_builder/`
- `ohos/`
- `android/`
- `ios/`
- `linux/`
- `macos/`
- `web/`
- `windows/`
- `third_party/flutter_packages/packages/webview_flutter/`
- `docs/screenshots/`
- `.github/workflows/`
- `.gitignore`

不要上传：

- `build/`
- `.dart_tool/`
- `.hvigor/`
- `oh_modules/`
- `node_modules/`
- `rust/target/`
- `*.hap`
- `*.hsp`
- `*.app`
- `*.p12`
- `*.cer`
- `*.csr`
- `*.mobileprovision`
- `*.log`
- DevEco / IDE 本地配置
- 本地真机截图临时文件
- 微信缓存目录中的图片原文件

## 首次提交说明

建议 commit message：

```text
Initial HarmonyOS port
```

建议提交说明：

```text
基于 niuhuan/wild 整理非官方 HarmonyOS / OpenHarmony Flutter 移植分支：

- 保留原版 wild 的主体功能和 GPLv3 开源基础
- 添加 OHOS Stage 工程和 FlutterAbility 宿主
- 接入 arm64 Flutter OHOS engine 与 Rust 动态库
- 适配登录、书架、搜索、阅读、历史记录、关于页等主要流程
- 修复 Wenku8 搜索与书架 WebView 解析
- 修复阅读页正文图片与插图加载
- 添加 HarmonyOS 图标、URL 跳转、屏幕常亮等平台兼容
- 清理临时调试文件、无用构建缓存和 x86_64 包体内容
- 更新 README、截图、GPLv3 声明和上传前清单
```

## 上传后还要补的内容

- 在 `README.md` 的“鸿蒙版 Source Code”处填入新仓库地址。
- 在 GitHub About 填写推荐文案。
- 确认 Release 附件只上传 release HAP，不上传签名证书或本地缓存。
- 如果提供安装包，Release 描述中说明仅支持 HarmonyOS / OpenHarmony arm64 真机。
- 如果继续同步上游，需要保留上游来源链接和 GPLv3 协议说明。
