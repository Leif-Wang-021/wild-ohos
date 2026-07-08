import 'dart:io';
import 'package:wild/utils/app_platform.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wild/pages/auth_cubit.dart';
import 'package:wild/pages/novel/font_size_cubit.dart';
import 'package:wild/pages/novel/paragraph_spacing_cubit.dart';
import 'package:wild/pages/novel/line_height_cubit.dart';
import 'package:wild/pages/novel/theme_cubit.dart';
import 'package:wild/pages/novel/reader_type_cubit.dart';
import 'package:wild/src/rust/api/system.dart';
import 'package:wild/pages/novel/top_bar_height_cubit.dart';
import 'package:wild/pages/novel/bottom_bar_height_cubit.dart';
import 'package:wild/cubits/reader_background_cubit.dart';
import 'package:wild/cubits/volume_control_cubit.dart';

import '../methods.dart';

class InitPage extends StatefulWidget {
  const InitPage({super.key});

  @override
  State<StatefulWidget> createState() => _InitPageState();
}

class _InitPageState extends State<InitPage> {
  Future<void> _initializeCubits() async {
    String root;
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      root = await desktopRoot();
    } else {
      root = await dataRoot();
    }
    if (kDebugMode) {
      print('root: $root');
    }
    await init(root: root);

    // 鍒濆鍖栨墍鏈?Cubit
    final fontSizeCubit = context.read<FontSizeCubit>();
    final paragraphSpacingCubit = context.read<ParagraphSpacingCubit>();
    final lineHeightCubit = context.read<LineHeightCubit>();
    final themeCubit = context.read<ThemeCubit>();
    final authCubit = context.read<AuthCubit>();
    final topBarHeightCubit = context.read<TopBarHeightCubit>();
    final bottomBarHeightCubit = context.read<BottomBarHeightCubit>();
    final readerTypeCubit = context.read<ReaderTypeCubit>();
    final readerBackgroundCubit = context.read<ReaderBackgroundCubit>();
    final volumeControlCubit = context.read<VolumeControlCubit>();

    // 绛夊緟鎵€鏈?Cubit 鍒濆鍖栧畬鎴?
    await Future.wait([
      fontSizeCubit.loadFontSize(),
      paragraphSpacingCubit.loadSpacing(),
      lineHeightCubit.loadLineHeight(),
      themeCubit.loadTheme(),
      authCubit.init(),
      topBarHeightCubit.loadHeight(),
      bottomBarHeightCubit.loadHeight(),
      readerTypeCubit.loadType(),
      readerBackgroundCubit.init(root),
      volumeControlCubit.init(),
    ]);

    if (authCubit.state.status == AuthStatus.authenticated) {
      // 濡傛灉宸茬粡鐧诲綍锛岃烦杞埌棣栭〉
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // 濡傛灉鏈櫥褰曪紝璺宠浆鍒扮櫥褰曢〉
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeCubits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            var width = 1080;
            var height = 1920;
            var min = constraints.maxWidth > constraints.maxHeight 
                ? constraints.maxHeight 
                : constraints.maxWidth;
            var newHeight = min;
            var newWidth = min * (width / height);
            
            return Stack(
              children: [
                Center(
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black,
                          Colors.black,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.95, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Image.asset(
                      'lib/assets/startup.png',
                      width: newWidth,
                      height: newHeight,
                    ),
                  ),
                ),
                // 鍔犺浇鎸囩ず鍣?
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 48,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}




