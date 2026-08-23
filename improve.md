# improvements
improve the following things you can add packages and change the folder structure if you like create also components if needed since i provide 2 main 
examples one for text and other for settings
## within waiter screen
within waiter context
### mobile / tablet
- improve the appbar in terms of font size, color, and responsiveness
- settings page: 
  - theme toggler in modern way
  - app info like name version etc...
### desktop
- improve the appbar in terms of font size, color, and responsiveness especially for the brand identity `BrewLine`
- setting page see example of settings: 
  - page for waiter should include theme toggler in modern way
  - apps info like name version etc...
  - 

## shared UI
use the app_sizes.dart inside these components

- create custom text components which uses google fonts
example but you can improve it and minimize it

```dart
import 'package:flutter/material.dart';

// Define an enum for common text types from the theme
enum UiTextType {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
}

/// A reusable Text widget that leverages the application's theme.
/// It applies the theme's text styles by default and allows for custom overrides.
class UiText extends StatelessWidget {
  final String text;
  final TextStyle? style; // Optional style to override theme defaults
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool softWrap;
  final UiTextType type; // Parameter to select base theme text style

  const UiText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap = true,
    this.type = UiTextType.bodyMedium, // Default to bodyMedium if not specified
  });

  @override
  Widget build(BuildContext context) {
    // Access the current theme's text theme and color scheme
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Select the base style based on the 'type' parameter
    TextStyle? baseStyle;
    switch (type) {
      case UiTextType.displayLarge:
        baseStyle = textTheme.displayLarge;
        break;
      case UiTextType.displayMedium:
        baseStyle = textTheme.displayMedium;
        break;
      case UiTextType.displaySmall:
        baseStyle = textTheme.displaySmall;
        break;
      case UiTextType.headlineLarge:
        baseStyle = textTheme.headlineLarge;
        break;
      case UiTextType.headlineMedium:
        baseStyle = textTheme.headlineMedium;
        break;
      case UiTextType.headlineSmall:
        baseStyle = textTheme.headlineSmall;
        break;
      case UiTextType.titleLarge:
        baseStyle = textTheme.titleLarge;
        break;
      case UiTextType.titleMedium:
        baseStyle = textTheme.titleMedium;
        break;
      case UiTextType.titleSmall:
        baseStyle = textTheme.titleSmall;
        break;
      case UiTextType.bodyLarge:
        baseStyle = textTheme.bodyLarge;
        break;
      case UiTextType.bodyMedium:
        baseStyle = textTheme.bodyMedium;
        break;
      case UiTextType.bodySmall:
        baseStyle = textTheme.bodySmall;
        break;
      case UiTextType.labelLarge:
        baseStyle = textTheme.labelLarge;
        break;
      case UiTextType.labelMedium:
        baseStyle = textTheme.labelMedium;
        break;
      case UiTextType.labelSmall:
        baseStyle = textTheme.labelSmall;
        break;
    }

    // Ensure a base style is always available. If theme style is null, fallback to a default.
    // The `copyWith` here ensures the color from the current color scheme is applied
    // if the baseStyle doesn't already have a color or if it needs to adapt to `onSurface`.
    // Then the explicitly provided `style` will override this if it has its own color.
    TextStyle effectiveStyle = (baseStyle ?? const TextStyle()).copyWith(
      color: colorScheme.onSurface, // Default text color based on theme
    );

    // Merge with any provided custom style. Properties in `style` will take precedence.
    effectiveStyle = effectiveStyle.merge(style);

    return Text(
      text,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
      style: effectiveStyle,
    );
  }
}
```

- improve `profile_chip.dart` so late will be bound to database and detected username and role profile.
- create an M3 expressive card that can take image, text, subtext(optional), and actions. it will use custom text component.
- create an M3 responsive button 
- create an M3 responsive list that i can use in following context: 
  - title & subtitle | trailing | price | trailing | action icon for deleting order 


## exmaple of settings
this setting is identical to another projetc of mine but i loved this approach it contains many widgets inside make it responsive for both mobile & tablet and desktop

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/features/settings/widgets/about_screen.dart';
import 'package:walt/features/settings/widgets/currency_selection_screen.dart';
import 'package:walt/features/settings/widgets/ota_update_screen.dart';
import 'package:walt/features/settings/widgets/theme_selection_screen.dart';
import 'package:walt/features/settings/widgets/profile/header.dart';
import 'package:walt/shared/list_ui.dart';
import 'package:walt/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    const Widget divider = SizedBox(height: 2);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const ProfileApp(),
              const SizedBox(height: 32),

              /// 🔹 PREFERENCES
              AppListSection(
                title: 'Preferences',
                children: [
                  AppListGroup(
                    useCard: false,
                    children: [
                      AppListTile(
                        style: ListStyle.outlined,
                        title: 'Theme',
                        subtitle: 'Change theme',
                        leading: const AppListAvatar(
                          icon: Icons.dark_mode_rounded,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ThemeSelectionScreen(),
                            ),
                          );
                        },
                      ),
                      divider,
                      AppListTile(
                        style: ListStyle.outlined,
                        title: 'Currency',
                        subtitle: settings.currency,
                        leading: const AppListAvatar(
                          icon: Icons.currency_exchange,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CurrencySelectionScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              /// 🔹 SECURITY
              AppListSection(
                title: 'Security',
                children: [
                  AppListGroup(
                    useCard: false,
                    children: [
                      AppListTile(
                        style: ListStyle.outlined,
                        title: 'Fingerprint',
                        subtitle: 'Use biometrics to unlock',
                        leading: const AppListAvatar(icon: Icons.fingerprint),
                        trailing: Switch(
                          value: settings.isFingerprintEnabled,
                          onChanged: (val) async {
                            final success = await settingsNotifier
                                .toggleFingerprint(ref);
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Authentication failed or not available',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              /// 🔹 Others
              AppListSection(
                title: 'Others',
                children: [
                  AppListGroup(
                    useCard: false,
                    children: [
                      AppListTile(
                        style: ListStyle.outlined,
                        title: 'About',
                        subtitle: 'about Walt v${Appinfo.version}',

                        leading: const AppListAvatar(icon: Icons.info),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AboutScreen(),
                            ),
                          );
                        },
                      ),
                      divider,
                      AppListTile(
                        style: ListStyle.outlined,
                        title: 'Update',
                        subtitle: 'Check for updates',
                        leading: const AppListAvatar(icon: Icons.update),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OtaUpdateScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
```
