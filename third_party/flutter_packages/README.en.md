# Flutter Packages

## Introduction

This repository is an extension of the Flutter community’s official plugin library ([flutter/packages](vscode-file://vscode-app/e:/Microsoft VS Code/resources/app/out/vs/code/electron-browser/workbench/workbench.html)), adding compatibility and adaptation for the OpenHarmony platform. With this repository, developers can seamlessly integrate commonly used plugins into Flutter applications and gain full support for OpenHarmony native capabilities with minimal business changes.

[OpenHarmony Compatible Packages](#packages)

[OpenHarmony Compatible Third-Party Libraries](https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.en.md)

> *For third-party library issues, please submit an issue to the corresponding repository. For third-party library adaptation requests, please submit an issue to the* [CPF-Flutter](https://gitcode.com/CPF-Flutter/docs/issues) *organization.*

## Contribution Guidelines

This repository employs a multi-branch management strategy. **Each third-party library version maintains dedicated dev and release branches**.

| Branch Type    | Naming Convention                       |
| -------------- | --------------------------------------- |
| Dev Branch     | `br_<library-name>-v<version>_ohos_dev` |
| Release Branch | `br_<library-name>-v<version>_ohos`     |

When contributing code, please adhere to the following process:

1. **Identify the Target Branch**: Locate the appropriate dev branch for the third-party library and version you intend to modify.

2. **Develop from the Dev Branch**: Fork the repository and create your feature branch from the corresponding dev branch.

3. **Submit Your Pull Request**: Open a pull request targeting the **dev branch** of the respective library version.

> **Important**: Release branches are designated for stable releases only and do not accept direct pull requests. All contributions must be submitted to the appropriate dev branch for the corresponding library version.

## Getting Started

Before using the plugins from this repository, please ensure that you have completed the OpenHarmony environment setup for the Flutter SDK.

- **Environment Setup**

  Refer to the documentation in the [flutter_flutter](https://gitcode.com/openharmony-tpc/flutter_flutter) repository under the section “Environment Configuration”.

- **Example Reference**

  Visit the  [flutter_samples](https://gitcode.com/openharmony-tpc/flutter_samples) repository to find integration demo examples.

## Dependency Reference

Third-party libraries adapted for OpenHarmony should be imported via Git repository. In addition to the required `url` field, commonly used parameters are as follows:

- `path`: The actual path to the library within the repository; otherwise, `pubspec.yaml` may not be found.
- `ref` (optional): Specify the version to be pulled, which can be the **branch name **, **tag **, or **commit id**. If not written, use the default branch of the repository. It is recommended to use the **tag  **.

**Reference by Tag**：

```yaml
dev_dependencies:
  pigeon:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/pigeon
      ref: pigeon-v26.1.5-ohos-1.0.0	# Release tag
```

**Reference by Branch:**

```yaml
dev_dependencies:
  pigeon:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/pigeon
      ref: pigeon-v21.2.0 # Branch name
```

## Usage Examples

### 1. Use of tool library pigeon

1. Introduce the pigeon library and add new configuration to dev_dependencies in pubspec.yaml:

    ```yaml
    dependencies:
      pigeon:
        git:
          url: https://gitcode.com/openharmony-tpc/flutter_packages.git
          path: packages/pigeon
          ref: pigeon-v26.1.5-ohos-1.0.0
    ```
    
2. Run `flutter pub get` in the project root directory;

3. Run `flutter pub run pigeon in the project root directory --input <dart communication model file path> --arkts_out <arkts platform method code output file path, example./ohos/entry/src/main/ets/xxx.ets> `

The template code for communication between Flutter and the OpenHarmony platform will be generated;

4. For calling examples, refer to packages/pigeon/example/app/ohos/entry/src/main/ets/plugins/MessagePlugin.ets

### 2. Use of plug-in library

Take path_provider as an example:
1. In the referenced project, add new dependencies configuration in pubspec.yaml:

   ```yaml
   dependencies:
     path_provider:
       git:
         url: https://gitcode.com/openharmony-tpc/flutter_packages.git
         path: packages/path_provider/path_provider
         ref: provider-v2.1.5-ohos-1.0.0
   ```
   
2. Run `flutter pub get` in the project root directory; (ohos/entry/oh-package.json5 will automatically add related plug-in har dependencies)

3. Call the path_provider related API in the business code, and it will run normally on the OpenHarmony platform.

Example: Add the path_provider library dependency that supports the OpenHarmony platform to a Flutter-compatible OpenHarmony project;

Reference examples: https://gitcode.com/openharmony-tpc/flutter_samples/tree/master/ohos/pictures_provider_demo.


## <a id="packages">OpenHarmony Compatible Packages</a>

<table border="1" cellspacing="0" cellpadding="5" style="border-collapse:collapse; text-align:center;">
<tr>
<th>No</th>
<th>Original Package Name</th>
<th>Flutter Framework Recommended Version</th>
<th>Original Package Version</th>
<th>release Branch</th>
<th>Dev Branch</th>
<th>Tag</th>
<th>Status</th>
</tr>
<tr>
<td rowspan="4">1</td>
<td rowspan="4">pigeon</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/pigeon/versions/14.0.0">14.0.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/pigeon">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/pigeon">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/pigeon-v14.0.0-ohos-1.0.0/packages/pigeon">pigeon-v14.0.0-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/pigeon/versions/21.2.0">21.2.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/pigeon-v21.2.0/packages/pigeon">pigeon-v21.2.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/pigeon-v21.2.0/packages/pigeon">pigeon-v21.2.0</a></td>
<td></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/pigeon/versions/25.3.2">25.3.2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_pigeon-v25.3.2_ohos/packages/pigeon">br_pigeon-v25.3.2_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_pigeon-v25.3.2_ohos_dev/packages/pigeon">br_pigeon-v25.3.2_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/pigeon-v25.3.2-ohos-1.0.0/packages/pigeon">pigeon-v25.3.2-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/pigeon/versions/26.1.5">26.1.5</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_pigeon-v26.1.5_ohos/packages/pigeon">br_pigeon-v26.1.5_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_pigeon-v26.1.5_ohos_dev/packages/pigeon">br_pigeon-v26.1.5_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/pigeon-v26.1.5-ohos-1.0.0/packages/pigeon">pigeon-v26.1.5-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td rowspan="4">2</td>
<td rowspan="4">file_selector</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/file_selector/versions/1.0.1">1.0.1</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/file_selector/file_selector">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/file_selector/file_selector">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/file_selector-v1.0.1-ohos-1.0.0/packages/file_selector/file_selector">file_selector-v1.0.1-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/file_selector/versions/1.0.3">1.0.3</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_file_selector-v1.0.3_ohos/packages/file_selector/file_selector">br_file_selector-v1.0.3_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_file_selector-v1.0.3_ohos_dev/packages/file_selector/file_selector">br_file_selector-v1.0.3_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/file_selector-v1.0.3-ohos-1.0.0/packages/file_selector/file_selector">file_selector-v1.0.3-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/file_selector/versions/1.0.3">1.0.3</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_file_selector-v1.0.3_ohos/packages/file_selector/file_selector">br_file_selector-v1.0.3_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_file_selector-v1.0.3_ohos_dev/packages/file_selector/file_selector">br_file_selector-v1.0.3_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/file_selector-v1.0.3-ohos-1.0.0/packages/file_selector/file_selector">file_selector-v1.0.3-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/file_selector/versions/1.1.0">1.1.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_file_selector-v1.1.0_ohos/packages/file_selector/file_selector">br_file_selector-v1.1.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_file_selector-v1.1.0_ohos_dev/packages/file_selector/file_selector">br_file_selector-v1.1.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/file_selector-v1.1.0-ohos-1.0.0/packages/file_selector/file_selector">file_selector-v1.1.0-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td rowspan="4">3</td>
<td rowspan="4">image_picker</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/image_picker/versions/1.0.4">1.0.4</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/image_picker/image_picker">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/image_picker/image_picker">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/image_picker-v1.0.4-ohos-1.0.0/packages/image_picker/image_picker">image_picker-v1.0.4-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/image_picker/versions/1.1.2">1.1.2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_image_picker-v1.1.2_ohos/packages/image_picker/image_picker">br_image_picker-v1.1.2_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_image_picker-v1.1.2_ohos_dev/packages/image_picker/image_picker">br_image_picker-v1.1.2_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/image_picker-v1.1.2-ohos-1.0.0/packages/image_picker/image_picker">image_picker-v1.1.2-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/image_picker/versions/1.1.2">1.1.2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_image_picker-v1.1.2_ohos/packages/image_picker/image_picker">br_image_picker-v1.1.2_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_image_picker-v1.1.2_ohos_dev/packages/image_picker/image_picker">br_image_picker-v1.1.2_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/image_picker-v1.1.2-ohos-1.0.0/packages/image_picker/image_picker">image_picker-v1.1.2-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/image_picker/versions/1.2.1">1.2.1</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_image_picker-v1.2.1_ohos/packages/image_picker/image_picker">br_image_picker-v1.2.1_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_image_picker-v1.2.1_ohos_dev/packages/image_picker/image_picker">br_image_picker-v1.2.1_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/image_picker-v1.2.1-ohos-1.0.0/packages/image_picker/image_picker">image_picker-v1.2.1-ohos-1.0.0</a></td>
<td>Adapted</td>
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
<td>Adapted</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/url_launcher/versions/6.3.0">6.3.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_url_launcher-v6.3.0_ohos/packages/url_launcher/url_launcher">br_url_launcher-v6.3.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_url_launcher-v6.3.0_ohos_dev/packages/url_launcher/url_launcher">br_url_launcher-v6.3.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/url_launcher_v6.3.0-ohos-1.0.0/packages/url_launcher/url_launcher">url_launcher_v6.3.0-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/url_launcher/versions/6.3.1">6.3.1</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_url_launcher_v6.3.1_ohos/packages/url_launcher/url_launcher">br_url_launcher_v6.3.1_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_url_launcher_v6.3.1_ohos_dev/packages/url_launcher/url_launcher">br_url_launcher_v6.3.1_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/url_launcher_v6.3.1-ohos-1.0.0/packages/url_launcher/url_launcher">url_launcher_v6.3.1-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/url_launcher/versions/6.3.2">6.3.2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_url_launcher-v6.3.2_ohos/packages/url_launcher/url_launcher">br_url_launcher-v6.3.2_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_url_launcher-v6.3.2_ohos_dev/packages/url_launcher/url_launcher">br_url_launcher-v6.3.2_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/url_launcher_v6.3.2-ohos-1.0.0/packages/url_launcher/url_launcher">url_launcher_v6.3.2-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td rowspan="4">6</td>
<td rowspan="4">shared_preferences</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/shared_preferences/versions/2.2.2">2.2.2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/shared_preferences/shared_preferences">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/shared_preferences/shared_preferences">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/shared_preferences-v2.2.2-ohos-1.0.0/packages/shared_preferences/shared_preferences">shared_preferences-v2.2.2-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/shared_preferences/versions/2.3.2">2.3.2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_shared_preferences-v2.3.2_ohos/packages/shared_preferences/shared_preferences">br_shared_preferences-v2.3.2_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_shared_preferences-v2.3.2_ohos_dev/packages/shared_preferences/shared_preferences">br_shared_preferences-v2.3.2_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/shared_preferences-v2.3.2-ohos-1.0.0/packages/shared_preferences/shared_preferences">shared_preferences-v2.3.2-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/shared_preferences/versions/2.5.3">2.5.3</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_shared_preferences-v2.5.3_ohos/packages/shared_preferences/shared_preferences">br_shared_preferences-v2.5.3_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_shared_preferences-v2.5.3_ohos_dev/packages/shared_preferences/shared_preferences">br_shared_preferences-v2.5.3_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/shared_preferences-v2.5.3-ohos-1.0.0/packages/shared_preferences/shared_preferences">shared_preferences-v2.5.3-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/shared_preferences/versions/2.5.4">2.5.4</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_shared_preferences-v2.5.4_ohos/packages/shared_preferences/shared_preferences">br_shared_preferences-v2.5.4_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_shared_preferences-v2.5.4_ohos_dev/packages/shared_preferences/shared_preferences">br_shared_preferences-v2.5.4_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/shared_preferences-v2.5.4-ohos-1.0.0/packages/shared_preferences/shared_preferences">shared_preferences-v2.5.4-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td rowspan="4">7</td>
<td rowspan="4">path_provider</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/path_provider/versions/2.1.1">2.1.1</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/path_provider/path_provider">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/path_provider/path_provider">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/provider-v2.1.1-ohos-1.0.0/packages/path_provider/path_provider">provider-v2.1.1-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/path_provider/versions/2.1.4">2.1.4</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_path_provider-v2.1.4_ohos/packages/path_provider/path_provider">br_path_provider-v2.1.4_ohos</a></td>
<td>-</td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/provider-v2.1.4_ohos-1.0.0/packages/path_provider/path_provider">provider-v2.1.4_ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/path_provider/versions/2.1.5">2.1.5</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_path_provider-v2.1.5_ohos/packages/path_provider/path_provider">br_path_provider-v2.1.5_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_path_provider-v2.1.5_ohos_dev/packages/path_provider/path_provider">br_path_provider-v2.1.5_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/provider-v2.1.5-ohos-1.0.0/packages/path_provider/path_provider">provider-v2.1.5-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/path_provider/versions/2.1.5">2.1.5</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_path_provider-v2.1.5_ohos/packages/path_provider/path_provider">br_path_provider-v2.1.5_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_path_provider-v2.1.5_ohos_dev/packages/path_provider/path_provider">br_path_provider-v2.1.5_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/provider-v2.1.5-ohos-1.0.0/packages/path_provider/path_provider">provider-v2.1.5-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td rowspan="4">8</td>
<td rowspan="4">local_auth</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/local_auth/versions/2.1.6">2.1.6</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/local_auth/local_auth">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/local_auth/local_auth">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/local_auth-v2.1.6-ohos-1.0.0/packages/local_auth/local_auth">local_auth-v2.1.6-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/local_auth/versions/2.3.0">2.3.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_local_auth-v2.3.0_ohos/packages/local_auth/local_auth">br_local_auth-v2.3.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_local_auth-v2.3.0_ohos_dev/packages/local_auth/local_auth">br_local_auth-v2.3.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/local_auth-v2.3.0-ohos-1.0.0/packages/local_auth/local_auth">local_auth-v2.3.0-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/local_auth/versions/2.3.0">2.3.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_local_auth-v2.3.0_ohos/packages/local_auth/local_auth">br_local_auth-v2.3.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_local_auth-v2.3.0_ohos_dev/packages/local_auth/local_auth">br_local_auth-v2.3.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/local_auth-v2.3.0-ohos-1.0.0/packages/local_auth/local_auth">local_auth-v2.3.0-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/local_auth/versions/3.0.0">3.0.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_local_auth-v3.0.0_ohos/packages/local_auth/local_auth">br_local_auth-v3.0.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_local_auth-v3.0.0_ohos_dev/packages/local_auth/local_auth">br_local_auth-v3.0.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/local_auth-v3.0.0-ohos-1.0.0/packages/local_auth/local_auth">local_auth-v3.0.0-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td rowspan="4">9</td>
<td rowspan="4">camera</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/camera/versions/0.10.5+5">0.10.5+5</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/camera/camera">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/camera/camera">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/camera-v0.10.5_5-ohos-1.0.0/packages/camera/camera">camera-v0.10.5_5-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/camera/versions/0.11.0+2">0.11.0+2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_camera-v0.11.0+2_ohos/packages/camera/camera">br_camera-v0.11.0+2_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_camera-v0.11.0_2_ohos_dev/packages/camera/camera">br_camera-v0.11.0_2_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/camera-v0.11.0_2-ohos-1.0.0/packages/camera/camera">camera-v0.11.0_2-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/camera/versions/0.11.1">0.11.1</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_camera-v0.11.1_ohos/packages/camera/camera">br_camera-v0.11.1_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_camera-v0.11.1_ohos_dev/packages/camera/camera">br_camera-v0.11.1_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/camera-v0.11.1-ohos-1.0.0/packages/camera/camera">camera-v0.11.1-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/camera/versions/0.11.3">0.11.3</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_camera-v0.11.3_ohos/packages/camera/camera">br_camera-v0.11.3_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_camera-v0.11.3_ohos_dev/packages/camera/camera">br_camera-v0.11.3_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/camera-v0.11.3-ohos-1.0.0/packages/camera/camera">camera-v0.11.3-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td rowspan="4">10</td>
<td rowspan="4">video_player</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/video_player/versions/2.7.2">2.7.2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/video_player/video_player">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/video_player/video_player">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/video_player-v2.7.2-ohos-1.0.0/packages/video_player/video_player">video_player-v2.7.2-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/video_player/versions/2.9.2">2.9.2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_video_player-v2.9.2_ohos/packages/video_player/video_player">br_video_player-v2.9.2_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_video_player-v2.9.2_ohos_dev/packages/video_player/video_player">br_video_player-v2.9.2_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/video_player-v2.9.2-ohos-1.0.0/packages/video_player/video_player">video_player-v2.9.2-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/video_player/versions/2.10.0">2.10.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_video_player-v2.10.0_ohos/packages/video_player/video_player">br_video_player-v2.10.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_video_player-v2.10.0_ohos_dev/packages/video_player/video_player">br_video_player-v2.10.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/video_player-v2.10.0-ohos-1.0.0/packages/video_player/video_player">video_player-v2.10.0-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/video_player/versions/2.10.1">2.10.1</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_video_player-v2.10.1_ohos/packages/video_player/video_player">br_video_player-v2.10.1_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_video_player-v2.10.1_ohos_dev/packages/video_player/video_player">br_video_player-v2.10.1_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/video_player-v2.10.1-ohos-1.0.0/packages/video_player/video_player">video_player-v2.10.1-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td rowspan="4">11</td>
<td rowspan="4">webview_flutter</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/webview_flutter/versions/4.4.2">4.4.2</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/webview_flutter/webview_flutter">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/webview_flutter/webview_flutter">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/webview_flutter-v4.4.2-ohos-1.0.0/packages/webview_flutter/webview_flutter">webview_flutter-v4.4.2-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/webview_flutter/versions/4.8.0">4.8.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_webview_flutter-v4.8.0_ohos/packages/webview_flutter/webview_flutter">br_webview_flutter-v4.8.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_webview_flutter-v4.8.0_ohos_dev/packages/webview_flutter/webview_flutter">br_webview_flutter-v4.8.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/webview_flutter-v4.8.0-ohos-1.0.0/packages/webview_flutter/webview_flutter">webview_flutter-v4.8.0-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/webview_flutter/versions/4.13.0">4.13.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_webview_flutter-v4.13.0_ohos/packages/webview_flutter/webview_flutter">br_webview_flutter-v4.13.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_webview_flutter-v4.13.0_ohos_dev/packages/webview_flutter/webview_flutter">br_webview_flutter-v4.13.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/webview_flutter-v4.13.0-ohos-1.0.0/packages/webview_flutter/webview_flutter">webview_flutter-v4.13.0-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/webview_flutter/versions/4.13.0">4.13.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_webview_flutter-v4.13.0_ohos/packages/webview_flutter/webview_flutter">br_webview_flutter-v4.13.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_webview_flutter-v4.13.0_ohos_dev/packages/webview_flutter/webview_flutter">br_webview_flutter-v4.13.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/webview_flutter-v4.13.0-ohos-1.0.0/packages/webview_flutter/webview_flutter">webview_flutter-v4.13.0-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td rowspan="1">12</td>
<td rowspan="1">webview_flutter-v4.4.4</td>
<td></td>
<td><a href="https://pub.dev/packages/webview_flutter-v4.4.4/versions/4.4.4">4.4.4</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/webview_flutter-v4.4.4">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/webview_flutter-v4.4.4">dev</a></td>
<td></td>
<td>Adapted</td>
</tr>
<tr>
<td rowspan="4">13</td>
<td rowspan="4">in_app_purchase</td>
<td>3.7</td>
<td><a href="https://pub.dev/packages/in_app_purchase/versions/3.1.11">3.1.11</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/in_app_purchase/in_app_purchase">master</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/dev/packages/in_app_purchase/in_app_purchase">dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/in_app_purchase_v3.1.11-ohos-1.0.0/packages/in_app_purchase/in_app_purchase">in_app_purchase_v3.1.11-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.22</td>
<td><a href="https://pub.dev/packages/in_app_purchase/versions/3.2.0">3.2.0</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_in_app_purchase-v3.2.0_ohos/packages/in_app_purchase/in_app_purchase">br_in_app_purchase-v3.2.0_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_in_app_purchase-v3.2.0_ohos_dev/packages/in_app_purchase/in_app_purchase">br_in_app_purchase-v3.2.0_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/in_app_purchase_v3.2.0-ohos-1.0.0/packages/in_app_purchase/in_app_purchase">in_app_purchase_v3.2.0-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.27</td>
<td><a href="https://pub.dev/packages/in_app_purchase/versions/3.2.3">3.2.3</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_in_app_purchase-v3.2.3_ohos/packages/in_app_purchase/in_app_purchase">br_in_app_purchase-v3.2.3_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_in_app_purchase-v3.2.3_ohos_dev/packages/in_app_purchase/in_app_purchase">br_in_app_purchase-v3.2.3_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/in_app_purchase_v3.2.3-ohos-1.0.0/packages/in_app_purchase/in_app_purchase">in_app_purchase_v3.2.3-ohos-1.0.0</a></td>
<td>Adapted</td>
</tr>
<tr>
<td>3.35</td>
<td><a href="https://pub.dev/packages/in_app_purchase/versions/3.2.3">3.2.3</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_in_app_purchase-v3.2.3_ohos/packages/in_app_purchase/in_app_purchase">br_in_app_purchase-v3.2.3_ohos</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_in_app_purchase-v3.2.3_ohos_dev/packages/in_app_purchase/in_app_purchase">br_in_app_purchase-v3.2.3_ohos_dev</a></td>
<td><a href="https://gitcode.com/CPF-Flutter/flutter_packages/tree/in_app_purchase_v3.2.3-ohos-1.0.0/packages/in_app_purchase/in_app_purchase">in_app_purchase_v3.2.3-ohos-1.0.0</a></td>
<td>Adapted</td>
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


- Note: A status of `-` indicates a pure Dart library that works out of the box.

## FAQ

### 1. Run `flutter pub get` displayed `"File name too long"` error

Open the `Git Bash` or `cmd.exe`(you need to have git as an environment variable) and execute the following command:
``` 
  git config --global core.longpaths true
```

## Communication

- **Issue Feedback:** Submit issues to the [Flutter Framework Repository](https://gitcode.com/CPF-Flutter/flutter_flutter/issues) or related third-party libraries.