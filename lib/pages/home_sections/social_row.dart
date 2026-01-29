import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialRowSection extends StatelessWidget {
  const SocialRowSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _SocialCard(
          image: 'images/twitter.png',
          url: 'https://twitter.com/GephOfficial',
        ),
        SizedBox(width: 8),
        _SocialCard(
          image: 'images/telegram.png',
          url: 'https://t.me/gephusers',
        ),
        SizedBox(width: 8),
        _SocialCard(
          image: 'images/forum.png',
          url: 'https://community.geph.io',
        ),
        SizedBox(width: 8),
        _SocialCard(
          image: 'images/github.png',
          url: 'https://github.com/geph-official',
        ),
      ],
    );
  }
}

class _SocialCard extends StatelessWidget {
  const _SocialCard({required this.image, required this.url});

  final String image;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () {
          launchUrl(Uri.parse(url));
        },
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: SizedBox(height: 82 / 2.5, child: Image.asset(image)),
          ),
        ),
      ),
    );
  }
}
