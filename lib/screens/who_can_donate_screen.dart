import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/app_config.dart';
import '../common/colors.dart';
import '../data/info_group.dart';
import '../widgets/action_button.dart';

class WhoCanDonateScreen extends StatelessWidget {
  static const route = 'who-can-donate';
  const WhoCanDonateScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context)
        .textTheme
        .titleLarge
        ?.copyWith(color: MainColors.primary);

    return Scaffold(
      appBar: AppBar(title: const Text('Who Can Donate Blood?')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ...InfoGroup.whoCanDonate.map(
                    (g) => ExpansionTile(
                  title: Text(g.title, style: titleStyle),
                  initiallyExpanded: g.id == 0,
                  children: g.info
                      .map(
                        (c) => ListTile(
                      leading: const Icon(
                        Icons.bookmark_outline,
                        color: MainColors.primary,
                      ),
                      title: Text(c),
                    ),
                  )
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ActionButton(
                  text: 'Learn More',
                  callback: () async {
                    final url = AppConfig.bloodDonationInfoLink;
                    if (await canLaunch(url)) {
                      await launch(url);
                    } else {
                      Fluttertoast.showToast(msg: 'Could not launch the link');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}