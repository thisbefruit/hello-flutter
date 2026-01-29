import 'package:flutter/material.dart';
import 'package:hello_flutter/pages/account_details_page.dart';
import 'package:hello_flutter/pages/settings_page.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final double height = 82;
    return SizedBox(
      height: height,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: Image.asset('images/gephlogo.png'),
                iconSize: height / 3,
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AccountDetailsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.account_circle_outlined),
                iconSize: height / 2.5,
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                icon: const Icon(Icons.settings_outlined),
                iconSize: height / 2.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
