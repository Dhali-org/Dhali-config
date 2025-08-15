import 'dart:convert';
import 'dart:html';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConfigManager {
  static bool _alreadyReloaded = false;
  static const String prodConfigUrl =
      'https://raw.githubusercontent.com/Dhali-org/Dhali-config/master/public.prod.json';
  static const String stagingConfigUrl =
      'https://raw.githubusercontent.com/Dhali-org/Dhali-config/master/public.staging.json';

  static Map<String, dynamic>? config;

  static bool isStagingEnvironment() {
    String deploy_env = const String.fromEnvironment("DEPLOYMENT_ENVIRONMENT");
    return deploy_env == "staging" ||
        window.location.href.contains("staging") ||
        window.location.href.contains("localhost");
  }

  static Future<Map<String, dynamic>> fetchConfig() async {
    String url = isStagingEnvironment() ? stagingConfigUrl : prodConfigUrl;
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load configuration');
    }
  }

  static Future<void> checkAndUpdateConfig() async {
    if (_alreadyReloaded) {
      return;
    }
    _alreadyReloaded = true;
    try {
      config = await fetchConfig();
      String latestVersion = config!['VERSION'];
      String? localConfig = window.localStorage['config'];
      Map<String, dynamic> localConfigJson =
          localConfig != null ? jsonDecode(localConfig) : {};

      if (localConfig == null || latestVersion != localConfigJson['VERSION']) {
        print(
          "Config version has changed. Updating local storage and applying new configuration.",
        );
        window.localStorage['config'] = jsonEncode(config);
        window.location.reload();
      } else {
        print("Config version is up to date.");
      }
    } catch (e) {
      print("An error occurred while updating configuration: $e");
    }
  }

  static List<InlineSpan> _buildFeatureTextSpans(
    String text,
    BuildContext context,
  ) {
    final List<InlineSpan> spans = [];
    final theme = Theme.of(context);
    final linkStyle = TextStyle(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
    );

    final RegExp linkRegExp = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');

    text.splitMapJoin(
      linkRegExp,
      onMatch: (Match match) {
        final String linkText = match.group(1)!;
        final String url = match.group(2)!;
        spans.add(
          TextSpan(
            text: linkText,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => window.open(url, '_blank'),
          ),
        );
        return '';
      },
      onNonMatch: (String nonMatch) {
        spans.add(TextSpan(text: nonMatch));
        return '';
      },
    );
    return spans;
  }

  static void showNewFeaturesDialog(BuildContext context) {
    const showFeaturesValue = 'false';
    String? localConfig = window.localStorage['config'];
    if (localConfig == null) {
      return;
    }
    var localConfigJson = jsonDecode(localConfig);
    if (localConfigJson['show_new_features'] != showFeaturesValue) {
      final newFeatures = localConfigJson['new_features'];

      if (newFeatures is List && newFeatures.isNotEmpty) {
        // Show the dialog after the first frame has been built.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              localConfigJson['show_new_features'] = showFeaturesValue;
              window.localStorage['config'] = jsonEncode(localConfigJson);
              return AlertDialog(
                title: const Text("What's New"),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: newFeatures.map<Widget>((feature) {
                      final theme = Theme.of(context);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: theme.textTheme.bodyMedium,
                                  children: _buildFeatureTextSpans(
                                    feature.toString(),
                                    context,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          );
        });
      }
    }
  }
}
