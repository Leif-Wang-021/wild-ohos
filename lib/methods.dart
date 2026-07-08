import 'dart:io';
import 'package:flutter/services.dart';
import 'package:wild/utils/app_platform.dart';

MethodChannel _channel = const MethodChannel('methods');

// OHOS-AWARE
Future<String> dataRoot() async {
  if (AppPlatform.isOHOS) {
    return "/data/storage/el2/base/haps/entry/files";
  }
  try {
    return await _channel.invokeMethod("dataRoot");
  } catch (e) {
    return "/data/storage/el2/base/haps/entry/files";
  }
}

// OHOS-AWARE
Future<bool> getKeepScreenOn() async {
  if (AppPlatform.isOHOS) return false;
  try {
    return await _channel.invokeMethod("getKeepScreenOn");
  } catch (e) {
    return false;
  }
}

// OHOS-AWARE
Future setKeepScreenOn(bool keepScreenOn) async {
  if (AppPlatform.isOHOS) return;
  try {
    return await _channel.invokeMethod("setKeepScreenOn", keepScreenOn);
  } catch (e) {
    return;
  }
}

Future<bool> openExternalUrl(String url) async {
  if (!AppPlatform.isOHOS) return false;
  try {
    return await _channel.invokeMethod<bool>("openUrl", url) ?? false;
  } catch (e) {
    return false;
  }
}
