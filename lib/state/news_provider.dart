import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'native_gate.dart';

class NewsItemData {
  final String title;
  final int dateUnix;
  final String contents;
  final bool important;

  const NewsItemData({
    required this.title,
    required this.dateUnix,
    required this.contents,
    required this.important,
  });
}

final newsProvider = FutureProvider<List<NewsItemData>>((ref) async {
  final gate = ref.read(nativeGateProvider);
  final result = await gate.daemonRpc('latest_news', const <Object?>['en']);
  if (result is! List) {
    return const <NewsItemData>[];
  }
  return result.map<NewsItemData>((item) {
    if (item is! Map) {
      return const NewsItemData(
        title: 'Unknown',
        dateUnix: 0,
        contents: '',
        important: false,
      );
    }
    final title = item['title'];
    final dateUnix = item['date_unix'];
    final contents = item['contents'];
    final important = item['important'];
    return NewsItemData(
      title: title is String ? title : 'Unknown',
      dateUnix: dateUnix is int ? dateUnix : 0,
      contents: contents is String ? contents : '',
      important: important is bool ? important : false,
    );
  }).toList();
});
