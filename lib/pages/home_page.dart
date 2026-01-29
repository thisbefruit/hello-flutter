import 'package:flutter/material.dart';
import 'package:hello_flutter/pages/home_sections/account_info.dart';
import 'package:hello_flutter/pages/home_sections/connect_card.dart';
import 'package:hello_flutter/pages/home_sections/news_feed.dart';
import 'package:hello_flutter/pages/home_sections/social_row.dart';
import 'package:hello_flutter/pages/home_sections/top_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const HomeTopBar(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(82 / 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AccountInfoSection(),
                  const SizedBox(height: 14),
                  const Expanded(child: NewsFeedSection()),
                  const SizedBox(height: 14),
                  const SocialRowSection(),
                  const SizedBox(height: 14),
                  const ConnectCardSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoundedPaddedCard extends StatelessWidget {
  const RoundedPaddedCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
