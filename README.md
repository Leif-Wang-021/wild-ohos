# wild(鸿蒙版)

wild(鸿蒙版) 是一个使用 Flutter 开发的轻小说文库(文库8)第三方客户端的 HarmonyOS / OpenHarmony 分支。

本项目基于上游 [niuhuan/wild](https://github.com/niuhuan/wild) 进行适配，保留原版的阅读、书架、搜索、分类、排行和历史记录等体验，并补充 HarmonyOS 真机运行所需的平台兼容处理。鸿蒙适配代码由 AI 辅助编写，人类调试修复。

> 本项目不是轻小说文库官方应用，与轻小说文库及其运营方无关。

## 截图

<p>
  <img src="docs/screenshots/01-home.jpg" width="24%" alt="首页" />
  <img src="docs/screenshots/02-history.jpg" width="24%" alt="阅读历史" />
  <img src="docs/screenshots/03-reader.jpg" width="24%" alt="阅读页" />
  <img src="docs/screenshots/04-illustration.jpg" width="24%" alt="插图页" />
</p>

## 功能特性

### 阅读

- 支持小说阅读，支持章节跳转
- 自定义阅读主题（浅色 / 深色 / 跟随系统）
- 自定义字体大小、行高、段落间距
- 阅读进度自动保存
- 支持继续阅读功能
- 竖屏阅读自动滚动
- 支持正文插图加载
- 查看评论

### 书架功能

- 书架分类管理
- 支持多选操作
- 支持从网页书架同步并解析书架内容

### 搜索功能

- 支持按书名和作者搜索
- 搜索历史记录
- 点击作者名快速搜索该作者的其他作品
- 搜索结果无限滚动加载

### 分类浏览

- 支持多种分类标签
- 支持按更新 / 热门 / 完结 / 动画化筛选
- 分类浏览历史记录
- 无限滚动加载

### 排行榜

- 支持多种排序方式（更新 / 发布 / 访问量 / 推荐 / 收藏等）
- 排行榜浏览历史记录
- 无限滚动加载

### 其他功能

- 用户登录 / 登出
- 阅读历史记录
- 完结小说专区
- 动画化作品标记
- 自动签到
- HarmonyOS 真机 arm64 HAP 构建
- HarmonyOS 图标、启动、WebView、URL 跳转、屏幕常亮等兼容处理

## 鸿蒙适配状态

- 目标设备：HarmonyOS / OpenHarmony arm64 真机
- Flutter OHOS：基于 OpenHarmony Flutter 适配
- DevEco Studio：6.1 / API 23 环境验证
- HAP 架构：仅保留 `arm64-v8a`
- 当前 release HAP 体积：约 42.8 MB
- Bundle Name：`com.opensource.wild`

说明：当前仓库面向真机 arm64 包整理，默认不再包含 x86_64 模拟器原生库。如果需要 x86_64 模拟器调试，需要单独恢复 x86_64 Flutter engine 和 Rust 动态库。

## 构建和运行

### 安装依赖

```bash
flutter pub get
```

### 运行开发版本

```bash
flutter run
```

### 构建 HarmonyOS HAP

Windows / PowerShell 示例：

```powershell
$env:DEVECO_SDK_HOME = "D:\Program Files\Huawei\DevEco Studio\sdk"
$env:HOS_SDK_HOME = "D:\Program Files\Huawei\DevEco Studio\sdk"
$env:JAVA_HOME = "D:\Program Files\Huawei\DevEco Studio\jbr"
$env:PATH = "F:\flutter_ohos\bin;D:\Program Files\Huawei\DevEco Studio\tools\ohpm\bin;D:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin;D:\Program Files\Huawei\DevEco Studio\tools\node;D:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains;D:\Program Files\Huawei\DevEco Studio\jbr\bin;$env:PATH"

flutter build hap --release --target-platform ohos-arm64
```

输出路径：

```text
build\ohos\hap\entry-default-signed.hap
```

### 安装到真机

```powershell
hdc install -r build\ohos\hap\entry-default-signed.hap
hdc shell aa start -a EntryAbility -b com.opensource.wild
```

## Rust 动态库

鸿蒙包使用 `ohos/entry/libs/arm64-v8a/librust_lib_wild.so`。如果修改 Rust 代码，需要重新交叉编译并替换该文件。

```powershell
$env:PATH = "$env:USERPROFILE\.cargo\bin;D:\ohos-cc;$env:PATH"
$env:CC_aarch64_unknown_linux_ohos = "aarch64-unknown-linux-ohos-clang.cmd"
$env:AR_aarch64_unknown_linux_ohos = "llvm-ar.cmd"

cd rust
cargo build --target aarch64-unknown-linux-ohos --release
```

## 项目来源

- 上游 Source Code：[https://github.com/niuhuan/wild](https://github.com/niuhuan/wild)
- 鸿蒙版 Source Code：[https://github.com/Leif-Wang-021/wild-ohos](https://github.com/Leif-Wang-021/wild-ohos)
- 上游协议：GNU General Public License v3.0 (GPLv3)

## 责任声明

1. 本项目仅供学习和研究使用，不得用于商业用途。
2. 本项目不存储任何小说内容，所有内容均来自网络。
3. 本项目不承担任何因使用本软件而产生的法律责任。
4. 本项目与轻小说文库官方无关，相关内容版权归原网站及原作者所有。
5. 使用本软件即表示同意以上声明。

## 开源协议

本项目采用 GNU General Public License v3.0 (GPLv3) 协议开源。这意味着：

1. 你可以自由使用、修改和分发本软件。
2. 你必须保留版权声明和许可声明。
3. 如果你分发修改后的版本，必须使用相同的 GPLv3 协议。
4. 你必须提供源代码。
5. 你的修改必须开源。

作为上游 `wild` 的派生版本，分发修改后的源码或安装包时应继续遵守 GPLv3，并保留上游来源、版权声明和许可证。

详情请查看 [LICENSE](LICENSE) 文件。
