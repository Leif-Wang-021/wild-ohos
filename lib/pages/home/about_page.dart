import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wild/methods.dart';
import 'package:wild/pages/update_cubit.dart';
import 'package:wild/utils/app_version.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _upstreamSourceUrl = 'https://github.com/niuhuan/wild';
  static const _licenseUrl =
      'https://github.com/niuhuan/wild/blob/master/LICENSE';
  static const _portSourceUrl = 'https://github.com/Leif-Wang-021/wild-ohos';
  static const _portIssuesUrl =
      'https://github.com/Leif-Wang-021/wild-ohos/issues';

  String get _displayVersion => AppVersion.display;

  Future<void> _launchUrl(BuildContext context, String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('待上传 GitHub 后填写')));
      return;
    }

    if (await openExternalUrl(url)) return;

    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法打开链接')));
    }
  }

  Future<void> _checkUpdate(BuildContext context, UpdateState state) async {
    final messenger = ScaffoldMessenger.of(context);
    final updateInfo = await context.read<UpdateCubit>().checkUpdate(
      force: true,
    );
    if (!context.mounted) return;

    final knownUpdate = updateInfo ?? state.updateInfo;
    if (knownUpdate != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('发现新版本 ${knownUpdate.version}'),
          action: SnackBarAction(
            label: '打开',
            onPressed: () => _launchUrl(context, knownUpdate.url),
          ),
        ),
      );
    } else {
      messenger.showSnackBar(const SnackBar(content: Text('当前已是最新版本')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<UpdateCubit, UpdateState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('关于')),
          body: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.noScaling),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              children: [
                const _AppMark(),
                const SizedBox(height: 16),
                const Text(
                  'wild(鸿蒙版)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '版本 $_displayVersion',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: OutlinedButton.icon(
                    onPressed: () => _checkUpdate(context, state),
                    icon: Icon(
                      state.updateInfo == null
                          ? Icons.refresh
                          : Icons.system_update,
                      size: 20,
                    ),
                    label: Text(
                      state.updateInfo == null
                          ? '检查更新'
                          : '发现新版本 ${state.updateInfo!.version}，点击查看',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionText(
                          title: '关于 wild',
                          body:
                              'wild 是一个使用 Flutter 开发的轻小说文库客户端，提供流畅的阅读体验和丰富的功能。',
                        ),
                        const SizedBox(height: 18),
                        const _SectionText(
                          title: '鸿蒙移植版',
                          body:
                              '当前版本基于 OpenHarmony Flutter 适配，保留原版体验并补充平台兼容处理，代码由 Codex 编写。',
                        ),
                        const SizedBox(height: 18),
                        _SectionText(
                          title: '开源协议',
                          body:
                              '本项目采用 GNU General Public License v3.0 (GPLv3) 协议开源。',
                          onTap: () => _launchUrl(context, _licenseUrl),
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.source_outlined,
                          title: '上游 Source Code',
                          value: _upstreamSourceUrl,
                          onTap: () => _launchUrl(context, _upstreamSourceUrl),
                        ),
                        _InfoRow(
                          icon: Icons.code,
                          title: '鸿蒙版 Source Code',
                          value:
                              _portSourceUrl.isEmpty
                                  ? '待上传 GitHub 后填写'
                                  : _portSourceUrl,
                          onTap: () => _launchUrl(context, _portSourceUrl),
                        ),
                        _InfoRow(
                          icon: Icons.feedback_outlined,
                          title: '问题反馈',
                          value:
                              _portIssuesUrl.isEmpty
                                  ? '待上传 GitHub 后填写'
                                  : _portIssuesUrl,
                          onTap: () => _launchUrl(context, _portIssuesUrl),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AppMark extends StatelessWidget {
  const _AppMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.bookmark, color: Colors.white, size: 38),
      ),
    );
  }
}

class _SectionText extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback? onTap;

  const _SectionText({required this.title, required this.body, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(fontSize: 14, height: 1.45)),
      ],
    );

    if (onTap == null) return child;
    return InkWell(onTap: onTap, child: child);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
