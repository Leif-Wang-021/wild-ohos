import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wild/services/cover_cache.dart';
import 'package:wild/src/rust/api/wenku8.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;

class CachedImageProvider extends ImageProvider<CachedImageProvider> {
  final String url;
  final double scale;

  CachedImageProvider(this.url, {this.scale = 1.0});

  @override
  ImageStreamCompleter loadImage(
    CachedImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale,
    );
  }

  @override
  Future<CachedImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  Future<ui.Codec> _loadAsync(CachedImageProvider key) async {
    assert(key == this);
    // 离线/未缓存时 Rust 端会失败，先尝试 Dart 侧本地封面缓存。
    final local = CoverCache.instance.get(url);
    if (local != null) {
      return ui.instantiateImageCodec(await local.readAsBytes());
    }
    try {
      final path = await downloadImage(url: url);
      final bytes = await File(path).readAsBytes();
      // 抓取成功后写入本地封面缓存，供日后离线使用。
      unawaited(CoverCache.instance.put(url, bytes));
      return ui.instantiateImageCodec(bytes);
    } catch (e) {
      // 联网失败且无本地缓存：回退再查一次（可能刚被写入）。
      final fallback = CoverCache.instance.get(url);
      if (fallback != null) {
        return ui.instantiateImageCodec(await fallback.readAsBytes());
      }
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    final CachedImageProvider typedOther = other as CachedImageProvider;
    return url == typedOther.url && scale == typedOther.scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() =>
      '$runtimeType(url: ${describeIdentity(url)}, scale: $scale)';
}

class CachedImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image(
      image: CachedImageProvider(url),
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.withAlpha(80),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.withAlpha(80),
          child: const Icon(Icons.broken_image),
        );
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}
