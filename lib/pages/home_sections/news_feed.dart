import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_flutter/pages/home_page.dart';
import 'package:hello_flutter/state/news_provider.dart';

class NewsFeedSection extends ConsumerWidget {
  const NewsFeedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(newsProvider);
    return RoundedPaddedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEWS',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Expanded(
            child: news.when(
              data: (items) {
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _NewsItemTile(
                      title: item.title,
                      dateUnix: item.dateUnix,
                      contents: item.contents,
                      important: item.important,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Failed to load news: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsItemTile extends StatelessWidget {
  const _NewsItemTile({
    required this.title,
    required this.dateUnix,
    required this.contents,
    required this.important,
  });

  final String title;
  final int dateUnix;
  final String contents;
  final bool important;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      onTap: () => _showNewsModal(context),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateTime.fromMillisecondsSinceEpoch(
                  dateUnix * 1000,
                ).toLocal().toString(),
              ),
              const SizedBox(width: 8),
              if (important)
                const Chip(label: Text('Important')),
            ],
          ),
          const SizedBox(height: 4),
          Text(contents, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Future<void> _showNewsModal(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(title, style: theme.textTheme.titleMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(contents, style: theme.textTheme.bodyMedium),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
