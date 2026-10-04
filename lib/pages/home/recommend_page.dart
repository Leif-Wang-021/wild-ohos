import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wild/src/rust/wenku8/models.dart' as w8;
import 'package:wild/widgets/cached_image.dart';
import 'package:wild/widgets/cf_page_loader.dart';
import 'package:wild/widgets/novel_grid.dart';
import 'package:wild/widgets/wenku8_js.dart';

import 'recommend_cubit.dart';

class RecommendPage extends StatelessWidget {
  const RecommendPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RecommendCubit()..load(),
      child: Scaffold(
        body: BlocBuilder<RecommendCubit, RecommendState>(
          builder: (context, state) {
            if (state is RecommendLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is RecommendError) {
              return RefreshIndicator(
                onRefresh: () => context.read<RecommendCubit>().load(),
                child: ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 160,
                      child: Center(child: Text('加载失败: ${state.message}')),
                    ),
                  ],
                ),
              );
            }
            if (state is RecommendLoaded) {
              return _RecommendContent(blocks: state.blocks);
            }
            if (state is RecommendChallenge) {
              // Cloudflare challenge: fetch the page through a WebView session.
              return _RecommendWebViewFallback(apiHost: state.apiHost);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _RecommendContent extends StatelessWidget {
  final List<w8.HomeBlock> blocks;

  const _RecommendContent({required this.blocks});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<RecommendCubit>().load(),
      child: ListView.builder(
        itemCount: blocks.length,
        itemBuilder: (context, index) {
          final block = blocks[index];
          return _HomeBlockWidget(block: block);
        },
      ),
    );
  }
}

class _RecommendWebViewFallback extends StatelessWidget {
  final String apiHost;

  const _RecommendWebViewFallback({required this.apiHost});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RecommendCubit>();
    return Stack(
      children: [
        const Center(child: CircularProgressIndicator()),
        Positioned(
          left: 0,
          top: 0,
          width: 1,
          height: 1,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.01,
              child: CfPageLoader(
                apiHost: apiHost,
                path: '/index.php?charset=gbk',
                parserJs: Wenku8Js.indexBlocks,
                onSuccess: cubit.applyWebViewJson,
                onError: cubit.setError,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeBlockWidget extends StatelessWidget {
  final w8.HomeBlock block;

  const _HomeBlockWidget({required this.block});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            block.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: novelGridColumns(context),
              childAspectRatio: kNovelCardAspectRatio,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: block.list.length,
            itemBuilder: (context, index) {
              final novel = block.list[index];
              return _NovelCoverCard(novel: novel);
            },
          ),
        ),
      ],
    );
  }
}

class _NovelCoverCard extends StatelessWidget {
  final w8.NovelCover novel;

  const _NovelCoverCard({required this.novel});

  @override
  Widget build(BuildContext context) {
    var card = Card(
      clipBehavior: Clip.antiAlias,
      elevation: .5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: CachedImage(url: novel.img, fit: BoxFit.cover)),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              novel.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/novel/info', arguments: novel.aid);
      },
      child: card,
    );
  }
}
