import 'dart:convert';
import 'package:flutter/material.dart';

/// Categories grouping settings blocks.
enum SettingsCategory {
  lookAndMotion,
  homeAndLibrary,
  updatesAndNotifications,
  installAndSafety,
  advanced,
}

extension SettingsCategoryExtension on SettingsCategory {
  String get id {
    switch (this) {
      case SettingsCategory.lookAndMotion:
        return 'look_and_motion';
      case SettingsCategory.homeAndLibrary:
        return 'home_and_library';
      case SettingsCategory.updatesAndNotifications:
        return 'updates_and_notifications';
      case SettingsCategory.installAndSafety:
        return 'install_and_safety';
      case SettingsCategory.advanced:
        return 'advanced';
    }
  }

  String get labelKey {
    switch (this) {
      case SettingsCategory.lookAndMotion:
        return 'settingsTabLookMotion';
      case SettingsCategory.homeAndLibrary:
        return 'settingsTabHomeLibrary';
      case SettingsCategory.updatesAndNotifications:
        return 'settingsTabUpdatesNotifications';
      case SettingsCategory.installAndSafety:
        return 'settingsTabInstallSafety';
      case SettingsCategory.advanced:
        return 'settingsTabAdvancedDebug';
    }
  }

  IconData get icon {
    switch (this) {
      case SettingsCategory.lookAndMotion:
        return Icons.palette_outlined;
      case SettingsCategory.homeAndLibrary:
        return Icons.grid_view_outlined;
      case SettingsCategory.updatesAndNotifications:
        return Icons.system_update_outlined;
      case SettingsCategory.installAndSafety:
        return Icons.install_mobile_outlined;
      case SettingsCategory.advanced:
        return Icons.code_rounded;
    }
  }
}

/// Metadata descriptor for a modular settings card or group block.
class SettingsBlockDescriptor {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
  final SettingsCategory category;
  final int defaultPriority;
  final bool isProOrAdvanced;
  final List<String> persistKeys;

  const SettingsBlockDescriptor({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.category,
    required this.defaultPriority,
    this.isProOrAdvanced = false,
    this.persistKeys = const [],
  });

  bool matchesKey(String key) => id == key || persistKeys.contains(key);
}

/// User's custom settings layout configuration.
class SettingsLayoutConfiguration {
  final String preset;
  final Set<String> pinnedBlocks;
  final Set<String> hiddenBlocks;
  final List<String> customBlockOrder;

  const SettingsLayoutConfiguration({
    this.preset = 'standard',
    this.pinnedBlocks = const {},
    this.hiddenBlocks = const {},
    this.customBlockOrder = const [],
  });

  bool isPinned(String blockId) => pinnedBlocks.contains(blockId);
  bool isHidden(String blockId) => hiddenBlocks.contains(blockId);

  SettingsLayoutConfiguration copyWith({
    String? preset,
    Set<String>? pinnedBlocks,
    Set<String>? hiddenBlocks,
    List<String>? customBlockOrder,
  }) {
    return SettingsLayoutConfiguration(
      preset: preset ?? this.preset,
      pinnedBlocks: pinnedBlocks ?? this.pinnedBlocks,
      hiddenBlocks: hiddenBlocks ?? this.hiddenBlocks,
      customBlockOrder: customBlockOrder ?? this.customBlockOrder,
    );
  }

  Map<String, dynamic> toJson() => {
    'preset': preset,
    'pinned': pinnedBlocks.toList(),
    'hidden': hiddenBlocks.toList(),
    'order': customBlockOrder,
  };

  factory SettingsLayoutConfiguration.fromJson(Map<String, dynamic> json) {
    return SettingsLayoutConfiguration(
      preset: json['preset'] as String? ?? 'standard',
      pinnedBlocks: Set<String>.from(json['pinned'] as List? ?? []),
      hiddenBlocks: Set<String>.from(json['hidden'] as List? ?? []),
      customBlockOrder: List<String>.from(json['order'] as List? ?? []),
    );
  }

  String encode() => jsonEncode(toJson());

  static SettingsLayoutConfiguration decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const SettingsLayoutConfiguration();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return SettingsLayoutConfiguration.fromJson(decoded);
      }
    } catch (_) {}
    return const SettingsLayoutConfiguration();
  }
}

/// Central registry of all settings blocks available for customization.
class SettingsBlockRegistry {
  static const List<SettingsBlockDescriptor> allBlocks = [
    // Look & Motion
    SettingsBlockDescriptor(
      id: 'theme_palette',
      titleKey: 'theme',
      descriptionKey: 'themeDescription',
      icon: Icons.color_lens_outlined,
      category: SettingsCategory.lookAndMotion,
      defaultPriority: 10,
      persistKeys: [
        'look.theme',
        'look.colour',
        'look.designSystem',
        'look.textLanguage',
      ],
    ),
    SettingsBlockDescriptor(
      id: 'shapes_corners',
      titleKey: 'themeShapes',
      descriptionKey: 'themeShapesDesc',
      icon: Icons.rounded_corner_rounded,
      category: SettingsCategory.lookAndMotion,
      defaultPriority: 20,
      persistKeys: ['plusShapesAndCorners'],
    ),
    SettingsBlockDescriptor(
      id: 'motion_haptics',
      titleKey: 'settingsTabMotionHaptics',
      descriptionKey: 'settingsTabMotionHapticsDesc',
      icon: Icons.animation_rounded,
      category: SettingsCategory.lookAndMotion,
      defaultPriority: 30,
      persistKeys: ['look.motion', 'look.haptics', 'look.controls'],
    ),
    SettingsBlockDescriptor(
      id: 'settings_page_appearance',
      titleKey: 'settingsPage',
      descriptionKey: 'settingsPageDescription',
      icon: Icons.settings_accessibility_rounded,
      category: SettingsCategory.lookAndMotion,
      defaultPriority: 40,
      persistKeys: [
        'look.settingsPage',
        'look.settingsGroups',
        'look.settingsExtras',
      ],
    ),

    // Home & Library
    SettingsBlockDescriptor(
      id: 'app_tile_design',
      titleKey: 'settingsGroupTiles',
      descriptionKey: 'appTileDisplay',
      icon: Icons.auto_awesome_mosaic_outlined,
      category: SettingsCategory.homeAndLibrary,
      defaultPriority: 10,
      persistKeys: ['home.tiles', 'home.tileStyle'],
    ),
    SettingsBlockDescriptor(
      id: 'app_list_layout',
      titleKey: 'settingsGroupAppList',
      descriptionKey: 'defaultViewMode',
      icon: Icons.view_list_rounded,
      category: SettingsCategory.homeAndLibrary,
      defaultPriority: 20,
      persistKeys: ['home.appList'],
    ),
    SettingsBlockDescriptor(
      id: 'categories_sorting',
      titleKey: 'settingsGroupCategoriesSorting',
      descriptionKey: 'categorySettings',
      icon: Icons.category_outlined,
      category: SettingsCategory.homeAndLibrary,
      defaultPriority: 30,
      persistKeys: ['categorySettings'],
    ),
    SettingsBlockDescriptor(
      id: 'updates_in_list',
      titleKey: 'settingsGroupUpdatesInList',
      descriptionKey: 'updatesPlacementDescription',
      icon: Icons.update_rounded,
      category: SettingsCategory.homeAndLibrary,
      defaultPriority: 40,
      persistKeys: ['home.updatesInList'],
    ),
    SettingsBlockDescriptor(
      id: 'navigation_search',
      titleKey: 'settingsGroupNavSearch',
      descriptionKey: 'settingsGroupNavSearch',
      icon: Icons.navigation_outlined,
      category: SettingsCategory.homeAndLibrary,
      defaultPriority: 50,
      persistKeys: ['home.navSearch'],
    ),
    SettingsBlockDescriptor(
      id: 'floating_add_button',
      titleKey: 'settingsGroupAddButton',
      descriptionKey: 'plusEnableFABDescription',
      icon: Icons.add_circle_outline_rounded,
      category: SettingsCategory.homeAndLibrary,
      defaultPriority: 60,
      persistKeys: ['home.addButton'],
    ),
    SettingsBlockDescriptor(
      id: 'home_app_details',
      titleKey: 'settingsGroupHomeDetails',
      descriptionKey: 'plusHomeDashboardDescription',
      icon: Icons.home_outlined,
      category: SettingsCategory.homeAndLibrary,
      defaultPriority: 70,
      persistKeys: ['home.homeDetails'],
    ),
    SettingsBlockDescriptor(
      id: 'swipe_gestures',
      titleKey: 'swipeSettingsGroup',
      descriptionKey: 'swipeGesturesDescription',
      icon: Icons.swipe_outlined,
      category: SettingsCategory.homeAndLibrary,
      defaultPriority: 80,
      persistKeys: ['swipeGestures'],
    ),
    SettingsBlockDescriptor(
      id: 'library_management',
      titleKey: 'librarySettingsGroup',
      descriptionKey: 'librarySettingsDesc',
      icon: Icons.local_library_outlined,
      category: SettingsCategory.homeAndLibrary,
      defaultPriority: 90,
      persistKeys: ['libraryAndStorage', 'home.discover'],
    ),

    // Updates & Notifications
    SettingsBlockDescriptor(
      id: 'update_frequency',
      titleKey: 'updateCheckFrequency',
      descriptionKey: 'updateCheckFrequencyDescription',
      icon: Icons.schedule_rounded,
      category: SettingsCategory.updatesAndNotifications,
      defaultPriority: 10,
      persistKeys: ['updates_schedule'],
    ),
    SettingsBlockDescriptor(
      id: 'update_conditions',
      titleKey: 'networkRestrictions',
      descriptionKey: 'networkRestrictionsDescription',
      icon: Icons.wifi_protected_setup_rounded,
      category: SettingsCategory.updatesAndNotifications,
      defaultPriority: 20,
      persistKeys: ['updates_constraints', 'updates_performance'],
    ),
    SettingsBlockDescriptor(
      id: 'update_notifications',
      titleKey: 'notifications',
      descriptionKey: 'notificationsDescription',
      icon: Icons.notifications_active_outlined,
      category: SettingsCategory.updatesAndNotifications,
      defaultPriority: 30,
      persistKeys: ['notifications'],
    ),

    // Install & Safety
    SettingsBlockDescriptor(
      id: 'installer_engine',
      titleKey: 'installerEngine',
      descriptionKey: 'installerEngineDescription',
      icon: Icons.install_mobile_outlined,
      category: SettingsCategory.installAndSafety,
      defaultPriority: 10,
      persistKeys: ['installation_method', 'install.downloads'],
    ),
    SettingsBlockDescriptor(
      id: 'safety_ban_warnings',
      titleKey: 'settingsGroupSafety',
      descriptionKey: 'safetyAndRateLimitsGroupDesc',
      icon: Icons.shield_outlined,
      category: SettingsCategory.installAndSafety,
      defaultPriority: 20,
      isProOrAdvanced: true,
      persistKeys: ['safetyAndRateLimits'],
    ),
    SettingsBlockDescriptor(
      id: 'package_verification',
      titleKey: 'packageVerification',
      descriptionKey: 'packageVerificationDescription',
      icon: Icons.verified_user_outlined,
      category: SettingsCategory.installAndSafety,
      defaultPriority: 30,
      persistKeys: ['install.before', 'install.sources'],
    ),

    // System & Advanced
    SettingsBlockDescriptor(
      id: 'backup_export',
      titleKey: 'backupAndRestore',
      descriptionKey: 'backupAndRestoreDescription',
      icon: Icons.backup_outlined,
      category: SettingsCategory.advanced,
      defaultPriority: 10,
      persistKeys: ['advanced_data'],
    ),
    SettingsBlockDescriptor(
      id: 'developer_tools',
      titleKey: 'developerSettings',
      descriptionKey: 'developerSettingsDescription',
      icon: Icons.developer_mode_rounded,
      category: SettingsCategory.advanced,
      defaultPriority: 20,
      isProOrAdvanced: true,
      persistKeys: ['advanced.developer', 'troubleshootingAndSystem'],
    ),
    SettingsBlockDescriptor(
      id: 'microg_integration',
      titleKey: 'microgHub',
      descriptionKey: 'microgHubDescription',
      icon: Icons.extension_outlined,
      category: SettingsCategory.advanced,
      defaultPriority: 30,
      isProOrAdvanced: true,
      persistKeys: ['advanced.microg', 'microg_hub'],
    ),
  ];

  static SettingsBlockDescriptor? findById(String id) {
    for (final b in allBlocks) {
      if (b.id == id) return b;
    }
    return null;
  }

  static List<SettingsBlockDescriptor> forCategory(SettingsCategory category) {
    return allBlocks.where((b) => b.category == category).toList()
      ..sort((a, b) => a.defaultPriority.compareTo(b.defaultPriority));
  }
}
