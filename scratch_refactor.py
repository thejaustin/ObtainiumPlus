import os
import re

BEHAVIOR_PROPS = {
    "useShizuku", "removeOnExternalUninstall", "disablePageTransitions",
    "reversePageTransitions", "autoExportOnChanges", "exportSettings",
    "parallelDownloads", "shizukuPretendToBeGooglePlay", "animationSpeedMultiplier",
    "enableContextualTips", "enableDeepLogging", "preferredUpdateSource"
}

UPDATE_PROPS = {
    "onlyCheckInstalledOrTrackOnlyApps", "obtainiumReleaseChannel", "autoUpdateRules"
}

PLUS_PROPS = {
    "plusEnableGlassmorphism", "plusEnablePopupSlider", "plusEnableExpressiveProgress",
    "plusEnableSmartRetries", "plusEnableAdvancedSorting", "plusEnableUserPreapproval",
    "plusDeveloperMode", "plusEnableSystemUpdateScanner", "plusTopUILayout",
    "plusShowDashboardSearch", "plusShowFloatingSearch", "plusFabShowSearch",
    "plusFabShowAddByUrl", "plusFabShowGithubStarred", "plusFabShowGithubPersonalRepos",
    "plusFabShowImportInstalled", "plusGlobalCornerRadius", "plusHomeCornerRadius",
    "plusSettingsCornerRadius", "plusOverrideIndividualCornerRadius", "plusEnableNotificationDigest",
    "plusUseCompactSettings"
}

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original_content = content
    needs_plus = False
    needs_behavior = False
    needs_update = False

    # Find which providers we need based on usages like `settings.prop` or `settingsProvider.prop`
    # We will look for any word that is in our sets.
    for prop in PLUS_PROPS:
        if prop in content: needs_plus = True
    for prop in BEHAVIOR_PROPS:
        if prop in content: needs_behavior = True
    for prop in UPDATE_PROPS:
        if prop in content: needs_update = True

    if not (needs_plus or needs_behavior or needs_update):
        return

    # Add imports if missing
    imports_to_add = []
    if needs_plus and "PlusSettingsProvider" not in content:
        imports_to_add.append("import 'package:obtainium/providers/plus_settings_provider.dart';\n")
    if needs_behavior and "BehaviorSettingsProvider" not in content:
        imports_to_add.append("import 'package:obtainium/providers/behavior_settings_provider.dart';\n")
    if needs_update and "UpdateSettingsProvider" not in content:
        imports_to_add.append("import 'package:obtainium/providers/update_settings_provider.dart';\n")

    if imports_to_add:
        # insert after last import
        lines = content.split('\n')
        last_import_idx = -1
        for i, line in enumerate(lines):
            if line.startswith('import '):
                last_import_idx = i
        if last_import_idx != -1:
            lines[last_import_idx] = lines[last_import_idx] + '\n' + "".join(imports_to_add).strip()
            content = '\n'.join(lines)
        else:
            content = "".join(imports_to_add) + content

    # Add the local variable declarations in build methods or anywhere settings is declared
    # We look for: final settings = context.watch<SettingsProvider>();
    # or final settingsProvider = Provider.of<SettingsProvider>(context);
    
    replacements = []
    if needs_plus:
        replacements.append("final plusSettings = Provider.of<PlusSettingsProvider>(context);")
    if needs_behavior:
        replacements.append("final behaviorSettings = Provider.of<BehaviorSettingsProvider>(context);")
    if needs_update:
        replacements.append("final updateSettings = Provider.of<UpdateSettingsProvider>(context);")
        
    repl_str = "\\g<0>\n    " + "\n    ".join(replacements)
    
    # We only inject if it's a Provider.of or context.watch AND we haven't already injected it
    if "PlusSettingsProvider" not in original_content:
        content = re.sub(r'(final|var)\s+settings(Provider)?\s*=\s*(?:context\.watch<SettingsProvider>\(\)|Provider\.of<SettingsProvider>\(context(?:,\s*listen:\s*(false|true))?\));', repl_str, content)

    # Now replace usages
    for prop in PLUS_PROPS:
        content = re.sub(r'\bsettings(Provider)?\.' + prop + r'\b', 'plusSettings.' + prop, content)
    for prop in BEHAVIOR_PROPS:
        content = re.sub(r'\bsettings(Provider)?\.' + prop + r'\b', 'behaviorSettings.' + prop, content)
    for prop in UPDATE_PROPS:
        content = re.sub(r'\bsettings(Provider)?\.' + prop + r'\b', 'updateSettings.' + prop, content)

    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Refactored {filepath}")

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart') and file != 'settings_provider.dart':
            process_file(os.path.join(root, file))
