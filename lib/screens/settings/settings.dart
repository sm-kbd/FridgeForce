import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'riyoukiyaku.dart';
import 'contact.dart';
import 'syokudata.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("設定")),
      body: SettingsList(
        sections: [
          // Section 1
          SettingsSection(
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                title: const Text('利用規約'),
                onPressed: (context) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RiyoukiyakuPage()),
                  );
                },
              ),
              SettingsTile.navigation(
                title: const Text('消費期限デフォルト設定'),
                onPressed: (context) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SyokudataPage()),
                  );
                },
              ),
              SettingsTile.navigation(
                title: const Text('問い合わせ'),
                onPressed: (context) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContactPage()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
