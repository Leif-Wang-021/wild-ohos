# Flutter Packages

> **仓库迁移公告**：本仓库（`openharmony-tpc/flutter_packages`）计划于 **2026年6月10日** 迁移至 [CPF-Flutter/flutter_packages](https://gitcode.com/CPF-Flutter/flutter_packages)，届时旧仓库地址将自动重定向至新地址。迁移后请及时更新 Git 远程地址及项目中的依赖引用。详情参见：[迁移公告](https://gitcode.com/openharmony-tpc/flutter_flutter/wiki/Flutter%20%E9%B8%BF%E8%92%99%E5%8C%96%E4%BB%93%E5%BA%93%E8%BF%81%E7%A7%BB%E5%85%AC%E5%91%8A%EF%BC%9A%E5%85%A8%E6%96%B0%20CPF-Flutter%20%E7%BB%84%E7%BB%87%E4%B8%8A%E7%BA%BF)

## 仓库介绍

本仓库基于 Flutter 社区官方插件库（[flutter/packages](https://github.com/flutter/packages/)）进行扩展，新增对 OpenHarmony 平台的兼容适配。通过本仓库，开发者可在 Flutter 应用中无缝集成常用插件，通过最小化业务改动获得完整的OpenHarmony原生能力支持。

[OpenHarmony平台已适配packages三方库](#packages)

[OpenHarmony平台已适配三方库列表](https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md)

> 三方库问题请在对应仓库提交 issue；三方库适配请求请至 [CPF-Flutter](https://gitcode.com/CPF-Flutter/docs/issues) 组织提交 issue。

## 贡献指南

本仓库采用多分支管理策略，**每个三方库版本都有对应的 dev 分支和release分支：**

| 分支名       | 命名格式                       |
| ------------ | ------------------------------ |
| dev 分支     | `br_<库名>-v<版本号>_ohos_dev` |
| release 分支 | `br_<库名>-v<版本号>_ohos`     |

**开发者贡献代码时，请遵循以下流程：**

1. **确定目标分支**：根据您要修改的三方库及版本，找到对应的 dev 分支。
2. **基于 dev 分支开发**：fork 从对应的 dev 分支进行开发。
3. **提交 PR：将代码变更提交到对应的 **dev 分支**。

> **注意**：release 分支为发布分支，不接受直接提交PR。所有代码贡献请务必提交到对应三方库版本的 dev 分支上。

## 开始使用

使用本仓库插件前，请确保已完成 Flutter SDK 的 OpenHarmony 环境配置。

- **环境搭建**

  参考 [flutter_flutter](https://gitcode.com/openharmony-tpc/flutter_flutter) 仓库文档 `【环境配置】`。

- **示例参考**

  前往 [flutter_samples](https://gitcode.com/openharmony-tpc/flutter_samples) 仓库获取集成示例 Demo。
  

## 引用方式

适配了OpenHarmony的三方库需通过Git仓库引入。除必填的 `url` 外，常用参数如下：

- `path` : 库在仓库中的实际路径，否则可能找不到 `pubspec.yaml`。
- `ref`（可选） : 指定要拉取的版本，可以是 **分支名**、**标签（tag）** 或 **commit id**，不写则使用仓库默认分支，推荐使用**标签（tag）**。

**按标签引用（tag)：**

```yaml
dev_dependencies:
  pigeon:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/pigeon
      ref: pigeon-v26.1.5-ohos-1.0.0	# 发布标签
```

**按分支引用（branch）:**

```yaml
dev_dependencies:
  pigeon:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/pigeon
      ref: pigeon-v21.2.0 # 分支名
```

## 使用示例

### 一、工具库pigeon使用

1. 引入pigeon库，在pubspec.yaml中dev_dependencies新增配置：

   ```yaml
   dev_dependencies:
     pigeon:
       git:
         url: https://gitcode.com/openharmony-tpc/flutter_packages.git
         path: packages/pigeon
         ref: pigeon-v26.1.5-ohos-1.0.0
   ```

2. 项目根目录运行 `flutter pub get`。

3. 项目根目录运行 `flutter pub run pigeon --input <dart通信模型文件路径> --arkts_out <arkts平台方法代码输出文件路径，示例./ohos/entry/src/main/ets/xxx.ets>`，将会生成Flutter与OpenHarmony平台通信的模板代码。

4. 调用示例，参考packages/pigeon/example/app/ohos/entry/src/main/ets/plugins/MessagePlugin.ets。

### 二、 插件库使用

以 path_provider 举例：

1. 在引用的项目中，pubspec.yaml中dependencies新增配置：

    ```yaml
    dependencies:
      path_provider:
        git:
          url: https://gitcode.com/openharmony-tpc/flutter_packages.git
          path: packages/path_provider/path_provider
          ref: provider-v2.1.5-ohos-1.0.0
    ```
    
2. 项目根目录运行 `flutter pub get`，ohos/entry/oh-package.json5会自动添加相关插件har依赖。

3. 在业务代码中调用path_provider相关api，它会在OpenHarmony平台正常运行。

   示例：在某个Flutter兼容OpenHarmony项目中加入支持OpenHarmony平台的path_provider库依赖。

   可参考示例：[pictures_provider_demo](https://gitcode.com/openharmony-tpc/flutter_samples/tree/master/ohos/pictures_provider_demo)

## <a id='packages'>OpenHarmony平台已适配packages三方库</a>

<table border="1" cellspacing="0" cellpadding="5" style="border-collapse:collapse; text-align:center;">
<tr>
<th>序号</th>
<th>原库名</th>
<th>Flutter框架推荐版本</th>
<th>原库版本</th>
<th>release分支</th>
<th>dev分支</th>
<th>tag</th>
<th>状态</th>
</tr>
<tr>
<td rowspan="4">1</td>
<td rowspan="4">pigeon</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/pigeon/versions/14.0.0">14.0.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/pigeon">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/pigeon">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/pigeon-v14.0.0-ohos-1.0.0/packages/pigeon">pigeon-v14.0.0-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/pigeon/versions/21.2.0">21.2.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/pigeon-v21.2.0/packages/pigeon">pigeon-v21.2.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/pigeon-v21.2.0/packages/pigeon">pigeon-v21.2.0</a></td>
<td></td>
<td>已适配</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/pigeon/versions/25.3.2">25.3.2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_pigeon-v25.3.2_ohos/packages/pigeon">br_pigeon-v25.3.2_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_pigeon-v25.3.2_ohos_dev/packages/pigeon">br_pigeon-v25.3.2_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/pigeon-v25.3.2-ohos-1.0.0/packages/pigeon">pigeon-v25.3.2-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/pigeon/versions/26.1.5">26.1.5</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_pigeon-v26.1.5_ohos/packages/pigeon">br_pigeon-v26.1.5_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_pigeon-v26.1.5_ohos_dev/packages/pigeon">br_pigeon-v26.1.5_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/pigeon-v26.1.5-ohos-1.0.0/packages/pigeon">pigeon-v26.1.5-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td rowspan="4">2</td>
<td rowspan="4">file_selector</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/file_selector/versions/1.0.1">1.0.1</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/file_selector/file_selector">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/file_selector/file_selector">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/file_selector-v1.0.1-ohos-1.0.0/packages/file_selector/file_selector">file_selector-v1.0.1-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/file_selector/versions/1.0.3">1.0.3</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_file_selector-v1.0.3_ohos/packages/file_selector/file_selector">br_file_selector-v1.0.3_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_file_selector-v1.0.3_ohos_dev/packages/file_selector/file_selector">br_file_selector-v1.0.3_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/file_selector-v1.0.3-ohos-1.0.0/packages/file_selector/file_selector">file_selector-v1.0.3-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/file_selector/versions/1.0.3">1.0.3</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_file_selector-v1.0.3_ohos/packages/file_selector/file_selector">br_file_selector-v1.0.3_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_file_selector-v1.0.3_ohos_dev/packages/file_selector/file_selector">br_file_selector-v1.0.3_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/file_selector-v1.0.3-ohos-1.0.0/packages/file_selector/file_selector">file_selector-v1.0.3-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/file_selector/versions/1.1.0">1.1.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_file_selector-v1.1.0_ohos/packages/file_selector/file_selector">br_file_selector-v1.1.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_file_selector-v1.1.0_ohos_dev/packages/file_selector/file_selector">br_file_selector-v1.1.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/file_selector-v1.1.0-ohos-1.0.0/packages/file_selector/file_selector">file_selector-v1.1.0-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td rowspan="4">3</td>
<td rowspan="4">image_picker</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/image_picker/versions/1.0.4">1.0.4</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/image_picker/image_picker">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/image_picker/image_picker">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/image_picker-v1.0.4-ohos-1.0.0/packages/image_picker/image_picker">image_picker-v1.0.4-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/image_picker/versions/1.1.2">1.1.2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_image_picker-v1.1.2_ohos/packages/image_picker/image_picker">br_image_picker-v1.1.2_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_image_picker-v1.1.2_ohos_dev/packages/image_picker/image_picker">br_image_picker-v1.1.2_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/image_picker-v1.1.2-ohos-1.0.0/packages/image_picker/image_picker">image_picker-v1.1.2-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/image_picker/versions/1.1.2">1.1.2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_image_picker-v1.1.2_ohos/packages/image_picker/image_picker">br_image_picker-v1.1.2_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_image_picker-v1.1.2_ohos_dev/packages/image_picker/image_picker">br_image_picker-v1.1.2_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/image_picker-v1.1.2-ohos-1.0.0/packages/image_picker/image_picker">image_picker-v1.1.2-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/image_picker/versions/1.2.1">1.2.1</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_image_picker-v1.2.1_ohos/packages/image_picker/image_picker">br_image_picker-v1.2.1_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_image_picker-v1.2.1_ohos_dev/packages/image_picker/image_picker">br_image_picker-v1.2.1_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/image_picker-v1.2.1-ohos-1.0.0/packages/image_picker/image_picker">image_picker-v1.2.1-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td rowspan="4">4</td>
<td rowspan="4">animations</td>
<td>3.7</td>
<td></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/animations">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/animations">dev</a></td>
<td></td>
<td>-</td>
</tr>
<tr>
<td>3.22</td>
<td></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/animations">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/animations">dev</a></td>
<td></td>
<td>-</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/animations/versions/2.0.11">2.0.11</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_animations-v2.0.11_ohos/packages/animations">br_animations-v2.0.11_ohos</a></td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/animations/versions/2.0.11">2.0.11</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_animations-v2.0.11_ohos/packages/animations">br_animations-v2.0.11_ohos</a></td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
<tr>
<td rowspan="4">5</td>
<td rowspan="4">url_launcher</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/url_launcher/versions/6.1.11">6.1.11</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/url_launcher/url_launcher">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/url_launcher/url_launcher">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/url_launcher_v6.1.11-ohos-1.0.0/packages/url_launcher/url_launcher">url_launcher_v6.1.11-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/url_launcher/versions/6.3.0">6.3.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_url_launcher-v6.3.0_ohos/packages/url_launcher/url_launcher">br_url_launcher-v6.3.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_url_launcher-v6.3.0_ohos_dev/packages/url_launcher/url_launcher">br_url_launcher-v6.3.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/url_launcher_v6.3.0-ohos-1.0.0/packages/url_launcher/url_launcher">url_launcher_v6.3.0-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/url_launcher/versions/6.3.1">6.3.1</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_url_launcher_v6.3.1_ohos/packages/url_launcher/url_launcher">br_url_launcher_v6.3.1_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_url_launcher_v6.3.1_ohos_dev/packages/url_launcher/url_launcher">br_url_launcher_v6.3.1_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/url_launcher_v6.3.1-ohos-1.0.0/packages/url_launcher/url_launcher">url_launcher_v6.3.1-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/url_launcher/versions/6.3.2">6.3.2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_url_launcher-v6.3.2_ohos/packages/url_launcher/url_launcher">br_url_launcher-v6.3.2_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_url_launcher-v6.3.2_ohos_dev/packages/url_launcher/url_launcher">br_url_launcher-v6.3.2_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/url_launcher_v6.3.2-ohos-1.0.0/packages/url_launcher/url_launcher">url_launcher_v6.3.2-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td rowspan="4">6</td>
<td rowspan="4">shared_preferences</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/shared_preferences/versions/2.2.2">2.2.2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/shared_preferences/shared_preferences">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/shared_preferences/shared_preferences">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/shared_preferences-v2.2.2-ohos-1.0.0/packages/shared_preferences/shared_preferences">shared_preferences-v2.2.2-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/shared_preferences/versions/2.3.2">2.3.2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_shared_preferences-v2.3.2_ohos/packages/shared_preferences/shared_preferences">br_shared_preferences-v2.3.2_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_shared_preferences-v2.3.2_ohos_dev/packages/shared_preferences/shared_preferences">br_shared_preferences-v2.3.2_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/shared_preferences-v2.3.2-ohos-1.0.0/packages/shared_preferences/shared_preferences">shared_preferences-v2.3.2-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/shared_preferences/versions/2.5.3">2.5.3</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_shared_preferences-v2.5.3_ohos/packages/shared_preferences/shared_preferences">br_shared_preferences-v2.5.3_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_shared_preferences-v2.5.3_ohos_dev/packages/shared_preferences/shared_preferences">br_shared_preferences-v2.5.3_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/shared_preferences-v2.5.3-ohos-1.0.0/packages/shared_preferences/shared_preferences">shared_preferences-v2.5.3-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/shared_preferences/versions/2.5.4">2.5.4</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_shared_preferences-v2.5.4_ohos/packages/shared_preferences/shared_preferences">br_shared_preferences-v2.5.4_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_shared_preferences-v2.5.4_ohos_dev/packages/shared_preferences/shared_preferences">br_shared_preferences-v2.5.4_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/shared_preferences-v2.5.4-ohos-1.0.0/packages/shared_preferences/shared_preferences">shared_preferences-v2.5.4-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td rowspan="4">7</td>
<td rowspan="4">path_provider</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/path_provider/versions/2.1.1">2.1.1</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/path_provider/path_provider">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/path_provider/path_provider">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/provider-v2.1.1-ohos-1.0.0/packages/path_provider/path_provider">provider-v2.1.1-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/path_provider/versions/2.1.4">2.1.4</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_path_provider-v2.1.4_ohos/packages/path_provider/path_provider">br_path_provider-v2.1.4_ohos</a></td>
<td>-</td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/provider-v2.1.4_ohos-1.0.0/packages/path_provider/path_provider">provider-v2.1.4_ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/path_provider/versions/2.1.5">2.1.5</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_path_provider-v2.1.5_ohos/packages/path_provider/path_provider">br_path_provider-v2.1.5_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_path_provider-v2.1.5_ohos_dev/packages/path_provider/path_provider">br_path_provider-v2.1.5_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/provider-v2.1.5-ohos-1.0.0/packages/path_provider/path_provider">provider-v2.1.5-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/path_provider/versions/2.1.5">2.1.5</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_path_provider-v2.1.5_ohos/packages/path_provider/path_provider">br_path_provider-v2.1.5_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_path_provider-v2.1.5_ohos_dev/packages/path_provider/path_provider">br_path_provider-v2.1.5_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/provider-v2.1.5-ohos-1.0.0/packages/path_provider/path_provider">provider-v2.1.5-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td rowspan="4">8</td>
<td rowspan="4">local_auth</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/local_auth/versions/2.1.6">2.1.6</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/local_auth/local_auth">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/local_auth/local_auth">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/local_auth-v2.1.6-ohos-1.0.0/packages/local_auth/local_auth">local_auth-v2.1.6-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/local_auth/versions/2.3.0">2.3.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_local_auth-v2.3.0_ohos/packages/local_auth/local_auth">br_local_auth-v2.3.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_local_auth-v2.3.0_ohos_dev/packages/local_auth/local_auth">br_local_auth-v2.3.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/local_auth-v2.3.0-ohos-1.0.0/packages/local_auth/local_auth">local_auth-v2.3.0-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/local_auth/versions/2.3.0">2.3.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_local_auth-v2.3.0_ohos/packages/local_auth/local_auth">br_local_auth-v2.3.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_local_auth-v2.3.0_ohos_dev/packages/local_auth/local_auth">br_local_auth-v2.3.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/local_auth-v2.3.0-ohos-1.0.0/packages/local_auth/local_auth">local_auth-v2.3.0-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/local_auth/versions/3.0.0">3.0.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_local_auth-v3.0.0_ohos/packages/local_auth/local_auth">br_local_auth-v3.0.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_local_auth-v3.0.0_ohos_dev/packages/local_auth/local_auth">br_local_auth-v3.0.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/local_auth-v3.0.0-ohos-1.0.0/packages/local_auth/local_auth">local_auth-v3.0.0-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td rowspan="4">9</td>
<td rowspan="4">camera</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/camera/versions/0.10.5+5">0.10.5+5</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/camera/camera">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/camera/camera">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/camera-v0.10.5_5-ohos-1.0.0/packages/camera/camera">camera-v0.10.5_5-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/camera/versions/0.11.0+2">0.11.0+2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_camera-v0.11.0+2_ohos/packages/camera/camera">br_camera-v0.11.0+2_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_camera-v0.11.0_2_ohos_dev/packages/camera/camera">br_camera-v0.11.0_2_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/camera-v0.11.0_2-ohos-1.0.0/packages/camera/camera">camera-v0.11.0_2-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/camera/versions/0.11.1">0.11.1</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_camera-v0.11.1_ohos/packages/camera/camera">br_camera-v0.11.1_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_camera-v0.11.1_ohos_dev/packages/camera/camera">br_camera-v0.11.1_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/camera-v0.11.1-ohos-1.0.0/packages/camera/camera">camera-v0.11.1-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/camera/versions/0.11.3">0.11.3</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_camera-v0.11.3_ohos/packages/camera/camera">br_camera-v0.11.3_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_camera-v0.11.3_ohos_dev/packages/camera/camera">br_camera-v0.11.3_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/camera-v0.11.3-ohos-1.0.0/packages/camera/camera">camera-v0.11.3-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td rowspan="4">10</td>
<td rowspan="4">video_player</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/video_player/versions/2.7.2">2.7.2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/video_player/video_player">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/video_player/video_player">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/video_player-v2.7.2-ohos-1.0.0/packages/video_player/video_player">video_player-v2.7.2-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/video_player/versions/2.9.2">2.9.2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_video_player-v2.9.2_ohos/packages/video_player/video_player">br_video_player-v2.9.2_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_video_player-v2.9.2_ohos_dev/packages/video_player/video_player">br_video_player-v2.9.2_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/video_player-v2.9.2-ohos-1.0.0/packages/video_player/video_player">video_player-v2.9.2-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/video_player/versions/2.10.0">2.10.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_video_player-v2.10.0_ohos/packages/video_player/video_player">br_video_player-v2.10.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_video_player-v2.10.0_ohos_dev/packages/video_player/video_player">br_video_player-v2.10.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/video_player-v2.10.0-ohos-1.0.0/packages/video_player/video_player">video_player-v2.10.0-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/video_player/versions/2.10.1">2.10.1</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_video_player-v2.10.1_ohos/packages/video_player/video_player">br_video_player-v2.10.1_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_video_player-v2.10.1_ohos_dev/packages/video_player/video_player">br_video_player-v2.10.1_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/video_player-v2.10.1-ohos-1.0.0/packages/video_player/video_player">video_player-v2.10.1-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td rowspan="4">11</td>
<td rowspan="4">webview_flutter</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/webview_flutter/versions/4.4.2">4.4.2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/webview_flutter/webview_flutter">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/webview_flutter/webview_flutter">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/webview_flutter-v4.4.2-ohos-1.0.0/packages/webview_flutter/webview_flutter">webview_flutter-v4.4.2-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/webview_flutter/versions/4.8.0">4.8.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_webview_flutter-v4.8.0_ohos/packages/webview_flutter/webview_flutter">br_webview_flutter-v4.8.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_webview_flutter-v4.8.0_ohos_dev/packages/webview_flutter/webview_flutter">br_webview_flutter-v4.8.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/webview_flutter-v4.8.0-ohos-1.0.0/packages/webview_flutter/webview_flutter">webview_flutter-v4.8.0-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/webview_flutter/versions/4.13.0">4.13.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_webview_flutter-v4.13.0_ohos/packages/webview_flutter/webview_flutter">br_webview_flutter-v4.13.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_webview_flutter-v4.13.0_ohos_dev/packages/webview_flutter/webview_flutter">br_webview_flutter-v4.13.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/webview_flutter-v4.13.0-ohos-1.0.0/packages/webview_flutter/webview_flutter">webview_flutter-v4.13.0-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/webview_flutter/versions/4.13.0">4.13.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_webview_flutter-v4.13.0_ohos/packages/webview_flutter/webview_flutter">br_webview_flutter-v4.13.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_webview_flutter-v4.13.0_ohos_dev/packages/webview_flutter/webview_flutter">br_webview_flutter-v4.13.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/webview_flutter-v4.13.0-ohos-1.0.0/packages/webview_flutter/webview_flutter">webview_flutter-v4.13.0-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td rowspan="1">12</td>
<td rowspan="1">webview_flutter-v4.4.4</td>
<td></td>
<td><a href="https://pub.dev/packages/webview_flutter-v4.4.4/versions/4.4.4">4.4.4</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/webview_flutter-v4.4.4">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/webview_flutter-v4.4.4">dev</a></td>
<td></td>
<td>已适配</td>
</tr>
<tr>
<td rowspan="4">13</td>
<td rowspan="4">in_app_purchase</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/in_app_purchase/versions/3.1.11">3.1.11</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/in_app_purchase/in_app_purchase">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/in_app_purchase/in_app_purchase">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/in_app_purchase_v3.1.11-ohos-1.0.0/packages/in_app_purchase/in_app_purchase">in_app_purchase_v3.1.11-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/in_app_purchase/versions/3.2.0">3.2.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_in_app_purchase-v3.2.0_ohos/packages/in_app_purchase/in_app_purchase">br_in_app_purchase-v3.2.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_in_app_purchase-v3.2.0_ohos_dev/packages/in_app_purchase/in_app_purchase">br_in_app_purchase-v3.2.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/in_app_purchase_v3.2.0-ohos-1.0.0/packages/in_app_purchase/in_app_purchase">in_app_purchase_v3.2.0-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/in_app_purchase/versions/3.2.3">3.2.3</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_in_app_purchase-v3.2.3_ohos/packages/in_app_purchase/in_app_purchase">br_in_app_purchase-v3.2.3_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_in_app_purchase-v3.2.3_ohos_dev/packages/in_app_purchase/in_app_purchase">br_in_app_purchase-v3.2.3_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/in_app_purchase_v3.2.3-ohos-1.0.0/packages/in_app_purchase/in_app_purchase">in_app_purchase_v3.2.3-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/in_app_purchase/versions/3.2.3">3.2.3</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_in_app_purchase-v3.2.3_ohos/packages/in_app_purchase/in_app_purchase">br_in_app_purchase-v3.2.3_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_in_app_purchase-v3.2.3_ohos_dev/packages/in_app_purchase/in_app_purchase">br_in_app_purchase-v3.2.3_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/in_app_purchase_v3.2.3-ohos-1.0.0/packages/in_app_purchase/in_app_purchase">in_app_purchase_v3.2.3-ohos-1.0.0</a></td>
<td>已适配</td>
</tr>
<tr>
<td rowspan="1">14</td>
<td rowspan="1">css_colors</td>
<td>-</td>
<td></td>
<td>-</td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
<tr>
<td rowspan="1">15</td>
<td rowspan="1">flutter_adaptive_scaffold</td>
<td>-</td>
<td></td>
<td>-</td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
<tr>
<td rowspan="1">16</td>
<td rowspan="1">flutter_image</td>
<td>-</td>
<td></td>
<td>-</td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
<tr>
<td rowspan="1">17</td>
<td rowspan="1">flutter_lints</td>
<td>-</td>
<td></td>
<td>-</td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
<tr>
<td rowspan="1">18</td>
<td rowspan="1">flutter_markdown</td>
<td>-</td>
<td></td>
<td>-</td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
<tr>
<td rowspan="1">19</td>
<td rowspan="1">flutter_migrate</td>
<td>-</td>
<td></td>
<td>-</td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
<tr>
<td rowspan="1">20</td>
<td rowspan="1">go_router</td>
<td>-</td>
<td></td>
<td>-</td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
<tr>
<td rowspan="1">21</td>
<td rowspan="1">go_router_builder</td>
<td>-</td>
<td></td>
<td>-</td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
<tr>
<td rowspan="1">22</td>
<td rowspan="1">metrics_center</td>
<td>-</td>
<td></td>
<td>-</td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
<tr>
<td rowspan="1">23</td>
<td rowspan="1">multicast_dns</td>
<td>-</td>
<td></td>
<td>-</td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
<tr>
<td rowspan="1">24</td>
<td rowspan="1">palette_generator</td>
<td>-</td>
<td></td>
<td>-</td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
<tr>
<td rowspan="1">25</td>
<td rowspan="1">pointer_interceptor</td>
<td>-</td>
<td></td>
<td>-</td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
<tr>
<td rowspan="1">26</td>
<td rowspan="1">rfw</td>
<td>-</td>
<td></td>
<td>-</td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
<tr>
<td rowspan="1">27</td>
<td rowspan="1">standard_message_codec</td>
<td>-</td>
<td></td>
<td>-</td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
<tr>
<td rowspan="1">28</td>
<td rowspan="1">two_dimensional_scrollables</td>
<td>-</td>
<td></td>
<td>-</td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
<tr>
<td rowspan="1">29</td>
<td rowspan="1">web_benchmarks</td>
<td>-</td>
<td></td>
<td>-</td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
<tr>
<td rowspan="1">30</td>
<td rowspan="1">xdg_directories</td>
<td>-</td>
<td></td>
<td>-</td>
<td>-</td>
<td></td>
<td>-</td>
</tr>
</table>


- 注意：状态为`-`表示为纯Dart库

## FAQ

1. 运行 `flutter pub get` 遇到 `"File name too long"` 问题。

   打开 `Git Bash` 或 `运行 cmd`（需要将git添加到环境变量中），执行以下命令：

    ``` 
      git config --global core.longpaths true
    ```

## 问题交流

- 问题反馈：欢迎在 [Flutter框架仓库](https://gitcode.com/CPF-Flutter/flutter_flutter/issues) 以及各个Flutter三方库提交issue。

