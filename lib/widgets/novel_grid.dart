import 'package:flutter/material.dart';

/// 计算自适应的小说网格列数。
///
/// 根据可用宽度决定列数：手机竖屏约 3 列，平板/横屏依次增加到 4、5、6 列，
/// 使每本小说的卡片宽度保持在一个舒适范围内。
int novelGridColumns(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 1600) return 7;
  if (width >= 1280) return 6;
  if (width >= 1000) return 5;
  if (width >= 720) return 4;
  return 3;
}

/// 小说封面卡片宽高比（宽 / 高）。
const double kNovelCardAspectRatio = 207 / 307;
