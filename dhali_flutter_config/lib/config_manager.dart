import 'dart:convert';
import 'dart:html';
import 'package:http/http.dart' as http;

class ConfigManager {
  static bool _alreadyReloaded = false;
  static const String prodConfigUrl =
      'https://raw.githubusercontent.com/Dhali-org/Dhali-config/master/public.prod.json';
  static const String stagingConfigUrl =
      'https://raw.githubusercontent.com/Dhali-org/Dhali-config/master/public.staging.json';

  static Map<String, dynamic>? config;

  static bool isStagingEnvironment() {
    return window.location.href.contains("staging");
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
            "Config version has changed. Updating local storage and applying new configuration.");
        window.localStorage['config'] = jsonEncode(config);
        window.location.reload();
      } else {
        print("Config version is up to date.");
      }
    } catch (e) {
      print("An error occurred while updating configuration: $e");
    }
  }
}
