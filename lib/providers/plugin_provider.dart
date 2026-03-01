import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:obtainium/utils/logger.dart';

class ObtainiumPlugin {
  final String id;
  final String name;
  final String description;
  final String githubUrl;
  final String jsCode;
  final bool enabled;

  ObtainiumPlugin({
    required this.id,
    required this.name,
    required this.description,
    required this.githubUrl,
    required this.jsCode,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'githubUrl': githubUrl,
    'jsCode': jsCode,
    'enabled': enabled,
  };

  factory ObtainiumPlugin.fromJson(Map<String, dynamic> json) => ObtainiumPlugin(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    githubUrl: json['githubUrl'],
    jsCode: json['jsCode'],
    enabled: json['enabled'] ?? true,
  );
}

class PluginProvider with ChangeNotifier {
  final List<ObtainiumPlugin> _plugins = [];
  SharedPreferences? _prefs;

  List<ObtainiumPlugin> get plugins => _plugins;

  Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    final data = _prefs?.getStringList('installed_plugins') ?? [];
    _plugins.addAll(data.map((e) => ObtainiumPlugin.fromJson(jsonDecode(e))));
    notifyListeners();
  }

  Future<void> installFromUrl(String url) async {
    try {
      talker.info('Installing plugin from: $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Mock parsing for now - in reality, we'd extract metadata from the JS file
        final plugin = ObtainiumPlugin(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'New Plugin',
          description: 'Custom source from GitHub',
          githubUrl: url,
          jsCode: response.body,
        );
        _plugins.add(plugin);
        await _save();
        notifyListeners();
      }
    } catch (e, stack) {
      talker.handle(e, stack, 'Plugin Installation Failed');
    }
  }

  Future<void> _save() async {
    await _prefs?.setStringList(
      'installed_plugins',
      _plugins.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> removePlugin(String id) async {
    _plugins.removeWhere((element) => element.id == id);
    await _save();
    notifyListeners();
  }
}
