<p align="center">
  <h1 align="center"> <code>webview_flutter</code> </h1>
</p>



This project is based on [webview_flutter@4.6.0](https://pub.dev/packages/webview_flutter/versions/4.6.0).

## 1. Installation and Usage

### 1.1 Installation

Go to the project directory and add the following dependencies in pubspec.yaml

<!-- tabs:start -->

#### pubspec.yaml

```yaml
dependencies:
  webview_flutter:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_packages.git
      path: packages/webview_flutter
      # ref: webview_flutter-v4.4.2-ohos-1.0.0
      ref: TAG  #   Please select the TAG according to the TAG version table below
```

Execute Command

```bash
flutter pub get
```

<!-- tabs:end -->

**TAG Version Table**

| Flutter Version | TAG | Branch |
| :--- | :--- | :--- |
| 3.35 | `webview_flutter-v4.13.0-ohos-1.0.0` | `br_webview_flutter-v4.13.0_ohos` |
| 3.27 | `webview_flutter-v4.13.0-ohos-1.0.0` | `br_webview_flutter-v4.13.0_ohos` |
| 3.22 | `webview_flutter-v4.8.0-ohos-1.0.0` | `br_webview_flutter-v4.8.0_ohos` |
| 3.7 | `webview_flutter-v4.4.2-ohos-1.0.0` | `master` |

## 1.2 Usage

For use cases [ohos/example](./example)

## 2. Constraints

### 2.1 Compatibility

This document is verified based on the following versions:

1. Flutter: 3.7.12-ohos-1.1.1; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;
### 2.2 **Permission Requirements**

The following permissions include the `system_basic` permission, but the default application permission is `normal`. Only the `normal` permission can be used. Therefore, the error **9568289** may be reported during the installation of the HAP package. For details, see [Document](https://developer.huawei.com/consumer/en/doc/harmonyos-guides-V5/bm-tool-V5#EN_TOPIC_0000001884757326__%E5%AE%89%E8%A3%85hap%E6%97%B6%E6%8F%90%E7%A4%BAcode9568289-error-install-failed-due-to-grant-request-permissions-failed) Change the application level to `system_basic`.

####  2.2.1 **Add permissions to the module.json5 file in the entry directory.**

Open  `entry/src/main/module.json5` and add the following information:

```diff
"requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:network_reason",
        "usedScene": {
          "abilities": [
            "EntryAbility"
          ],
          "when": "inuse"
        }
      },
    ]
```

#### 2.2.2 **Add the reason for applying for the preceding permission to the entry directory.**

Open  `entry/src/main/resources/base/element/string.json` and add the following information:

```diff
{
  "string": [
    {
      "name": "network_reason",
      "value": "use network"
    }
  ]
}
```
## 3. API

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

| Name                                                         | Description                  | Type                                                         | ohos Support |
| ------------------------------------------------------------ | ---------------------------- | ------------------------------------------------------------ | ------------ |
| NavigationRequestCallback([NavigationRequest](#NavigationRequest ) navigationRequest) | FutureOr<NavigationDecision> | Signature for callbacks that report a pending navigation request. | function     |
| PageEventCallback(String url)                                | Future<void>                 | Signature for callbacks that report page events triggered by the native web view. | function     |
| ProgressCallback(int progress)                               | Future<void>                 | Signature for callbacks that report loading progress of a page. | function     |
| WebResourceErrorCallback([WebResourceError](#WebResourceError ) error) | Future<void>                 | Signature for callbacks that report a resource loading error. | function     |

## 4. Properties

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

### WebViewWidget

| Name            | Description                                       | Type              | ohos Support |
| --------------- | ------------------------------------------------- | ----------------- | ------------ |
| controller      | Controls a WebView provided by the host platform. | WebViewController | yes          |
| layoutDirection | layoutDirection                                   | TextDirection     | yes          |

### WebViewController

| Name                                                         | return            | Description                                                  | Type     | ohos Support |
| ------------------------------------------------------------ | ----------------- | ------------------------------------------------------------ | -------- | ------------ |
| fromPlatformCreationParams([PlatformWebViewControllerCreationParams](#PlatformWebViewControllerCreationParams) params, {void Function([WebViewPermissionRequest](#WebViewPermissionRequest) request)? onPermissionRequest}) | WebViewController | Constructs a [WebViewController] from creation params for a specific | function | yes          |
| fromPlatform([PlatformWebViewController](#PlatformWebViewController) this.platform, {void Function([WebViewPermissionRequest](#WebViewPermissionRequest) request)? onPermissionRequest}) | WebViewController | Constructs a [WebViewController] from a specific platform implementation. | function | yes          |
| loadFile(String absoluteFilePath)                            | Future<void>      | Loads the file located on the specified [absoluteFilePath].  | function | yes          |
| loadFlutterAsset(String key)                                 | Future<void>      | Loads the Flutter asset specified in the pubspec.yaml file.  | function | yes          |
| loadHtmlString(String html, {String? baseUrl})               | Future<void>      | Loads the supplied HTML string.                              | function | yes          |
| loadRequest(Uri uri, { [LoadRequestMethod](#LoadRequestMethod) method = LoadRequestMethod.get,  Map<String, String> headers = const <String, String>{}, Uint8List? body}) | Future<void>      | Makes a specific HTTP request and loads the response in the webview. | function | yes          |
| currentUrl()                                                 | Future<String?>   | Returns the current URL that the WebView is displaying.      | function | yes          |
| canGoBack()                                                  | Future<bool>      | Checks whether there's a back history item.                  | function | yes          |
| canGoForward()                                               | Future<bool>      | Checks whether there's a forward history item.               | function | yes          |
| goBack()                                                     | Future<void>      | Goes back in the history of this WebView.                    | function | yes          |
| goForward()                                                  | Future<void>      | Goes forward in the history of this WebView.                 | function | yes          |
| reload()                                                     | Future<void>      | Reloads the current URL.                                     | function | yes          |
| setNavigationDelegate([NavigationDelegate](#NavigationDelegate ) delegate) | Future<void>      | Sets the [NavigationDelegate] containing the callback methods that are | function | yes          |
| clearCache()                                                 | Future<void>      | Clears all caches used by the WebView.                       | function | yes          |
| clearLocalStorage()                                          | Future<void>      | Clears the local storage used by the WebView.                | function | yes          |
| runJavaScript(String javaScript)                             | Future<void>      | Runs the given JavaScript in the context of the current page. | function | yes          |
| runJavaScriptReturningResult(String javaScript)              | Future<Object>    | Runs the given JavaScript in the context of the current page, and returns the result. | function | yes          |
| addJavaScriptChannel(String name, {required void Function(JavaScriptMessage) onMessageReceived}) | Future<void>      | Adds a new JavaScript channel to the set of enabled channels. | function | yes          |
| removeJavaScriptChannel(String javaScriptChannelName)        | Future<void>      | Removes the JavaScript channel with the matching name from the set of enabled channels. | function | yes          |
| getTitle()                                                   | Future<String?>   | The title of the currently loaded page.                      | function | yes          |
| scrollTo(int x, int y)                                       | Future<void>      | Sets the scrolled position of this view.                     | function | yes          |
| scrollBy(int x, int y)                                       | Future<void>      | Moves the scrolled position of this view.                    | function | yes          |
| getScrollPosition()                                          | Future<Offset>    | Returns the current scroll position of this view.            | function | yes          |
| enableZoom(bool enabled)                                     | Future<void>      | Whether to support zooming using the on-screen zoom controls and gestures. | function | yes          |
| setBackgroundColor(Color color)                              | Future<void>      | Sets the current background color of this view.              | function | yes          |
| setJavaScriptMode([JavaScriptMode](#JavaScriptMode ) javaScriptMode) | Future<void>      | Sets the JavaScript execution mode to be used by the WebView. | function | yes          |
| setUserAgent(String? userAgent)                              | Future<void>      | Sets the value used for the HTTP `User-Agent:` request header. | function | yes          |
| setOnConsoleMessage(void Function([JavaScriptConsoleMessage](#JavaScriptConsoleMessage ) message) onConsoleMessage) | Future<void>      | Sets a callback that notifies the host application on any log messages written to the JavaScript console. | function | yes          |
| setOnJavaScriptAlertDialog(Future<void> Function([JavaScriptAlertDialogRequest](#JavaScriptAlertDialogRequest ) request) onJavaScriptAlertDialog) | Future<void>      | Sets a callback that notifies the host application that the web page wants to display a JavaScript alert() dialog. | function | yes          |
| setOnJavaScriptConfirmDialog(Future<bool> Function([JavaScriptConfirmDialogRequest](#JavaScriptConfirmDialogRequest ) request) onJavaScriptConfirmDialog) | Future<void>      | Sets a callback that notifies the host application that the web page wants to display a JavaScript confirm() dialog. | function | yes          |
| setOnJavaScriptTextInputDialog(Future<String> Function([JavaScriptTextInputDialogRequest](#JavaScriptTextInputDialogRequest) request) onJavaScriptTextInputDialog) | Future<void>      | Sets a callback that notifies the host application that the web page wants to display a JavaScript prompt() dialog. | function | yes          |
| getUserAgent()                                               | Future<String?>   | Gets the value used for the HTTP `User-Agent:` request header. | function | yes          |

### NavigationDelegate

| Name                       | Description                                                  | Type     | ohos Support |
| -------------------------- | ------------------------------------------------------------ | -------- | ------------ |
| fromPlatformCreationParams | Constructs a [NavigationDelegate] from creation params for a specific platform | function | yes          |
| fromPlatform               | Constructs a [NavigationDelegate] from a specific platform implementation. | function | yes          |

### HttpAuthRequest

| Name                                                         | return       | Description                            | Type     | ohos Support |
| ------------------------------------------------------------ | ------------ | -------------------------------------- | -------- | ------------ |
| onProceed([WebViewCredential](#WebViewCredential ) credential) | Future<void> | The callback to authenticate.          | function | yes          |
| onCancel()                                                   | Future<void> | The callback to cancel authentication. | function | yes          |
| host                                                         |              | The host requiring authentication.     | String   | yes          |
| realm                                                        |              | The realm requiring authentication.    | String   | yes          |

### JavaScriptAlertDialogRequest

| Name    | Description                                | Type   | ohos Support |
| ------- | ------------------------------------------ | ------ | ------------ |
| message | The message to be displayed in the window. | String | yes          |
| url     | The URL of the page requesting the dialog. | String | yes          |

### JavaScriptConfirmDialogRequest

| Name    | Description                                | Type   | ohos Support |
| ------- | ------------------------------------------ | ------ | ------------ |
| message | The message to be displayed in the window. | String | yes          |
| url     | The URL of the page requesting the dialog. | String | yes          |

### JavaScriptConsoleMessage

| Name    | Description                               | Type   | ohos Support |
| ------- | ----------------------------------------- | ------ | ------------ |
| level   | The severity of a JavaScript log message. | String | yes          |
| message | The message written to the console.       | String | yes          |

### JavaScriptMessage

| Name    | Description                                                  | Type   | ohos Support |
| ------- | ------------------------------------------------------------ | ------ | ------------ |
| message | The contents of the message that was sent by the JavaScript code. | String | yes          |

### JavaScriptTextInputDialogRequest

| Name        | Description                                          | Type    | ohos Support |
| ----------- | ---------------------------------------------------- | ------- | ------------ |
| message     | The message to be displayed in the window.           | String  | yes          |
| url         | The URL of the page requesting the dialog.           | String  | yes          |
| defaultText | The initial text to display in the text entry field. | String? | yes          |

### NavigationRequest

| Name        | Description                                                  | Type   | ohos Support |
| ----------- | ------------------------------------------------------------ | ------ | ------------ |
| url         | The URL of the pending navigation request.                   | String | yes          |
| isMainFrame | Indicates whether the request was made in the web site's main frame or a subframe. | bool   | yes          |

### PlatformWebViewController

| Name                                                         | return                                                  | Description                                                  | Type                                    | ohos Support |
| ------------------------------------------------------------ | ------------------------------------------------------- | ------------------------------------------------------------ | --------------------------------------- | ------------ |
| [PlatformWebViewControllerCreationParams](#PlatformWebViewControllerCreationParams) | [PlatformWebViewController](#PlatformWebViewController) | The parameters used to initialize the [PlatformWebViewController]. | PlatformWebViewControllerCreationParams | yes          |
| loadFile(String absoluteFilePath)                            | Future<void>                                            | Throws an ArgumentError if the [absoluteFilePath] does not exist. | function                                | yes          |
| loadFlutterAsset(String key)                                 | Future<void>                                            | Loads the Flutter asset specified in the pubspec.yaml file.  | function                                | yes          |
| loadHtmlString(String html, {String? baseUrl})               | Future<void>                                            | Loads the supplied HTML string.                              | function                                | yes          |
| loadRequest([LoadRequestParams](#LoadRequestParams) params)  | Future<void>                                            | Makes a specific HTTP request ands loads the response in the webview. | function                                | yes          |
| currentUrl()                                                 | Future<void>                                            | Accessor to the current URL that the WebView is displaying.  | function                                | yes          |
| canGoBack()                                                  | Future<bool>                                            | Checks whether there's a back history item.                  | function                                | yes          |
| canGoForward()                                               | Future<bool>                                            | Checks whether there's a forward history item.               | function                                | yes          |
| goBack()                                                     | Future<void>                                            | Goes back in the history of this WebView.                    | function                                | yes          |
| goForward()                                                  | Future<void>                                            | Goes forward in the history of this WebView.                 | function                                | yes          |
| reload()                                                     | Future<void>                                            | Reloads the current URL.                                     | function                                | yes          |
| clearCache()                                                 | Future<void>                                            | Clears all caches used by the WebView.                       | function                                | yes          |
| clearLocalStorage()                                          | Future<void>                                            | Clears the local storage used by the WebView.                | function                                | yes          |
| setPlatformNavigationDelegate([PlatformNavigationDelegate](#PlatformNavigationDelegate ) handler) | Future<void>                                            | Sets the [PlatformNavigationDelegate] containing the callback methods that are called during navigation events. | function                                | yes          |
| runJavaScript(String javaScript)                             | Future<void>                                            | Runs the given JavaScript in the context of the current page. | function                                | yes          |
| runJavaScriptReturningResult(String javaScript)              | Future<Object>                                          | Runs the given JavaScript in the context of the current page, and returns the result. | function                                | yes          |
| addJavaScriptChannel(String name, {required void Function(String  JavaScriptMessage) onMessageReceived}) | Future<void>                                            | Adds a new JavaScript channel to the set of enabled channels. | function                                | yes          |
| removeJavaScriptChannel(String javaScriptChannelName)        | Future<void>                                            | Removes the JavaScript channel with the matching name from the set of enabled channels. | function                                | yes          |
| getTitle()                                                   | Future<String?>                                         | The title of the currently loaded page.                      | function                                | yes          |
| scrollTo(int x, int y)                                       | Future<void>                                            | Sets the scrolled position of this view.                     | function                                | yes          |
| scrollBy(int x, int y)                                       | Future<void>                                            | Moves the scrolled position of this view.                    | function                                | yes          |
| getScrollPosition()                                          | Future<Offset>                                          | Returns the current scroll position of this view.            | function                                | yes          |
| enableZoom(bool enabled)                                     | Future<void>                                            | Whether to support zooming using the on-screen zoom controls and gestures. | function                                | yes          |
| setBackgroundColor(Color color)                              | Future<void>                                            | Sets the current background color of this view.              | function                                | yes          |
| setJavaScriptMode([JavaScriptMode](#JavaScriptMode ) javaScriptMode) | Future<void>                                            | Sets the JavaScript execution mode to be used by the WebView. | function                                | yes          |
| setUserAgent(String? userAgent)                              | Future<void>                                            | Sets the value used for the HTTP `User-Agent:` request header. | function                                | yes          |
| setOnPlatformPermissionRequest(void Function(PlatformWebViewPermissionRequest request) onPermissionRequest) | Future<void>                                            | Sets a callback that notifies the host application that web content is requesting permission to access the specified resources. | function                                | yes          |
| setOnConsoleMessage(void Function([JavaScriptConsoleMessage](#JavaScriptConsoleMessage ) message) onConsoleMessage) | Future<void>                                            | Sets a callback that notifies the host application on any log messages written to the JavaScript console. | function                                | yes          |
| setOnScrollPositionChange(void Function(ScrollPositionChange scrollPositionChange)? onScrollPositionChange) | Future<void>                                            | Sets the listener for content offset changes.                | function                                | yes          |
| setOnJavaScriptAlertDialog(Future<void> Function([JavaScriptAlertDialogRequest](#JavaScriptAlertDialogRequest ) request) onJavaScriptAlertDialog) | Future<void>                                            | Sets a callback that notifies the host application that the web page wants to display a JavaScript alert() dialog. | function                                | yes          |
| setOnJavaScriptConfirmDialog(Future<bool> Function([JavaScriptConfirmDialogRequest](#JavaScriptConfirmDialogRequest ) request) onJavaScriptConfirmDialog) | Future<void>                                            | Sets a callback that notifies the host application that the web page wants to display a JavaScript confirm() dialog. | function                                | yes          |
| setOnJavaScriptTextInputDialog(Future<String> Function([JavaScriptTextInputDialogRequest](#JavaScriptTextInputDialogRequest) request) onJavaScriptTextInputDialog) | Future<void>                                            | Sets a callback that notifies the host application that the web page wants to display a JavaScript prompt() dialog. | function                                | yes          |
| getUserAgent()                                               | Future<String?>                                         | Gets the value used for the HTTP `User-Agent:` request header. | function                                | yes          |

### PlatformWebViewControllerCreationParams

### PlatformNavigationDelegateCreationParams

### PlatformWebViewPermissionRequest

| Name  | return       | Description                                     | Type                          | ohos Support |
| ----- | ------------ | ----------------------------------------------- | ----------------------------- | ------------ |
| types |              | All resources access has been requested for.    | WebViewPermissionResourceType | yes          |
| grant | Future<void> | Grant permission for the requested resource(s). | function                      | yes          |
| deny  | Future<void> | Deny permission for the requested resource(s).  | function                      | yes          |

### LoadRequestParams

| Name    | Description                           | Type                | ohos Support |
| ------- | ------------------------------------- | ------------------- | ------------ |
| uri     | URI for the request.                  | Uri                 | yes          |
| method  | HTTP method used to make the request. | LoadRequestMethod   | yes          |
| headers | Headers for the request.              | Map<String, String> | yes          |
| body    | HTTP body for the request.            | Uint8List?          | yes          |

### PlatformNavigationDelegate

| Name    | Description                           | Type                | ohos Support |
| ------- | ------------------------------------- | ------------------- | ------------ |
| params  | URI for the request.                  | Uri                 | yes          |
| method  | HTTP method used to make the request. | LoadRequestMethod   | yes          |
| headers | Headers for the request.              | Map<String, String> | yes          |
| body    | HTTP body for the request.            | Uint8List?          | yes          |

### WebViewPermissionRequest

| Name     | return       | Description                                                  | Type                             | ohos Support |
| -------- | ------------ | ------------------------------------------------------------ | -------------------------------- | ------------ |
| platform |              | Implementation of [PlatformWebViewPermissionRequest] for the current platform | PlatformWebViewPermissionRequest | yes          |
| types    |              | All resources access has been requested for.                 | WebViewPermissionResourceType    | yes          |
| grant()  | Future<void> | Grant permission for the requested resource(s).              | function                         | yes          |
| deny()   | Future<void> | Deny permission for the requested resource(s).               | function                         | yes          |

### PlatformWebViewWidgetCreationParams

| Name               | Description                                                  | Type                                       | ohos Support |
| ------------------ | ------------------------------------------------------------ | ------------------------------------------ | ------------ |
| key                | IControls how one widget replaces another widget in the tree. | String                                     | yes          |
| controller         | The [PlatformWebViewController] that allows controlling the native web | PlatformWebViewController                  | yes          |
| layoutDirection    | The layout direction to use for the embedded WebView.        | TextDirection                              | yes          |
| gestureRecognizers | The `gestureRecognizers` specifies which gestures should be consumed by the web view. | Set<Factory<OneSequenceGestureRecognizer>> | yes          |

### UrlChange

| Name | Description                  | Type    | ohos Support |
| ---- | ---------------------------- | ------- | ------------ |
| url  | The new url of the web view. | String? | yes          |

### WebResourceError

| Name        | Description                                                  | Type   | ohos Support |
| ----------- | ------------------------------------------------------------ | ------ | ------------ |
| errorCode   | The integer code of the error (e.g. [WebViewClient.errorAuthentication]. | int    | yes          |
| description | Describes the error.                                         | String | yes          |

### WebViewCookie

| Name       | Description                     | Type   | ohos Support |
| ---------- | ------------------------------- | ------ | ------------ |
| name       | The cookie-name of the cookie.  | String | yes          |
| value      | The cookie-value of the cookie. | String | yes          |
| domain     | The domain-value of the cookie. | String | yes          |
| path = '/' | The path-value of the cookie.   | String | yes          |

### WebViewCredential

| Name     | Description    | Type   | ohos Support |
| -------- | -------------- | ------ | ------------ |
| user     | The user name. | String | yes          |
| password | The password.  | String | yes          |

### WebViewPermissionResourceType

| Name                                     | Description                            | Type  | ohos Support |
| ---------------------------------------- | -------------------------------------- | ----- | ------------ |
| WebViewPermissionResourceType.camera     | A media device that can capture video. | enums | yes          |
| WebViewPermissionResourceType.microphone | A media device that can capture audio. | enums | yes          |

### WebViewWidget

| Name            | Description                                       | Type              | ohos Support |
| --------------- | ------------------------------------------------- | ----------------- | ------------ |
| controller      | Controls a WebView provided by the host platform. | WebViewController | yes          |
| layoutDirection | layoutDirection                                   | TextDirection     | yes          |

### JavaScriptModeJavaScriptMode

| Name                        | Description                             | Type | ohos Support |
| --------------------------- | --------------------------------------- | ---- | ------------ |
| JavaScriptMode.disabled     | JavaScript execution is disabled.       | enum | yes          |
| JavascriptMode.unrestricted | JavaScript execution is not restricted. | enum | yes          |

### JavaScriptLogLevel

| Name                       | Description                                                  | Type | ohos Support |
| -------------------------- | ------------------------------------------------------------ | ---- | ------------ |
| JavaScriptLogLevel.error   | Indicates an error message was logged via an "error" event of the `console.error` method. | enum | yes          |
| JavaScriptLogLevel.warning | Indicates a warning message was logged using the `console.warning`  method. | enum | yes          |
| JavaScriptLogLevel.debug   | Indicates a debug message was logged using the `console.debug` method. | enum | yes          |
| JavaScriptLogLevel.info    | Indicates an informational message was logged using the `console.info` method. | enum | yes          |
| JavaScriptLogLevel.log     | Indicates a log message was logged using the `console.log` method. | enum | yes          |

### LoadRequestMethod

| Name                   | Description       | Type | ohos Support |
| ---------------------- | ----------------- | ---- | ------------ |
| LoadRequestMethod.get  | HTTP GET method.  | enum | yes          |
| LoadRequestMethod.post | HTTP POST method. | enum | yes          |

### NavigationDecision

| Name                        | Description                               | Type | ohos Support |
| --------------------------- | ----------------------------------------- | ---- | ------------ |
| NavigationDecision.prevent  | Prevent the navigation from taking place. | enum | yes          |
| NavigationDecision.navigate | Allow the navigation to take place.       | enum | yes          |

### WebResourceErrorType

| Name                                                   | Description                                               | Type | ohos Support |
| ------------------------------------------------------ | --------------------------------------------------------- | ---- | ------------ |
| WebResourceErrorType.authentication                    | User authentication failed on server.                     | enum | yes          |
| WebResourceErrorType.badUrl                            | Malformed URL.                                            | enum | yes          |
| WebResourceErrorType.connect                           | Failed to connect to the server.                          | enum | yes          |
| WebResourceErrorType.failedSslHandshake                | Failed to perform SSL handshake.                          | enum | yes          |
| WebResourceErrorType.file                              | Generic file error.                                       | enum | yes          |
| WebResourceErrorType.fileNotFound                      | File not found.                                           | enum | yes          |
| WebResourceErrorType.hostLookup                        | Server or proxy hostname lookup failed.                   | enum | yes          |
| WebResourceErrorType.io                                | Failed to read or write to the server.                    | enum | yes          |
| WebResourceErrorType.proxyAuthentication               | User authentication failed on proxy.                      | enum | yes          |
| WebResourceErrorType.redirectLoop                      | Too many redirects.                                       | enum | yes          |
| WebResourceErrorType.timeout                           | Connection timed out.                                     | enum | yes          |
| WebResourceErrorType.tooManyRequests                   | Too many requests during this load.                       | enum | yes          |
| WebResourceErrorType.unknown                           | Generic error.                                            | enum | yes          |
| WebResourceErrorType.unsafeResource                    | Resource load was canceled by Safe Browsing.              | enum | yes          |
| WebResourceErrorType.unsupportedAuthScheme             | Unsupported authentication scheme (not basic or digest).  | enum | yes          |
| WebResourceErrorType.unsupportedScheme                 | Unsupported URI scheme.                                   | enum | yes          |
| WebResourceErrorType.webContentProcessTerminated       | The web content process was terminated.                   | enum | yes          |
| WebResourceErrorType.webViewInvalidated                | The web view was invalidated.                             | enum | yes          |
| WebResourceErrorType.javaScriptExceptionOccurred       | A JavaScript exception occurred.                          | enum | yes          |
| WebResourceErrorType.javaScriptResultTypeIsUnsupported | The result of JavaScript execution could not be returned. | enum | yes          |

## 5. Known Issues

None

## 6. License

This project is licensed under  [BSD-3-Clause](https://gitcode.com/CPF-Flutter/flutter_packages/blob/master/packages/webview_flutter/webview_flutter/LICENSE) .


> Template version: v0.0.1