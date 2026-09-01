import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chameleon_icons/chameleon_icons.dart';

void main() {
  runApp(const MyApp());
}

class AppIconOption {
  final String id;
  final String name;
  final String assetPath;
  final bool isDefault;

  const AppIconOption({
    required this.id,
    required this.name,
    required this.assetPath,
    this.isDefault = false,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chameleon Icons',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2481CC), // Telegram Blue
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2481CC),
          brightness: Brightness.dark,
        ),
      ),
      home: const IconPickerScreen(),
    );
  }
}

class IconPickerScreen extends StatefulWidget {
  const IconPickerScreen({super.key});

  @override
  State<IconPickerScreen> createState() => _IconPickerScreenState();
}

class _IconPickerScreenState extends State<IconPickerScreen> {
  String _platformVersion = 'Loading...';
  String _currentIcon = '';
  bool _isLoading = false;
  final _chameleonIcons = ChameleonIcons();

  final List<AppIconOption> _icons = const [
    AppIconOption(
      id: 'MainActivityDefault',
      name: 'Default Classic',

      assetPath: 'assets/icons/default.png',
      isDefault: true,
    ),
    AppIconOption(
      id: 'MainActivityDark',
      name: 'Midnight Dark',

      assetPath: 'assets/icons/dark.png',
    ),
    AppIconOption(
      id: 'MainActivityGold',
      name: 'Luxury Gold',

      assetPath: 'assets/icons/gold.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    String platformVersion;
    try {
      platformVersion = await _chameleonIcons.getPlatformVersion() ?? 'Unknown';
    } on PlatformException {
      platformVersion = 'Failed to get platform version';
    }

    final activeIcon = await _chameleonIcons.getCurrentIcon();

    if (!mounted) return;
    setState(() {
      _platformVersion = platformVersion;
      _currentIcon = activeIcon;
    });
  }

  bool _isIconSelected(AppIconOption icon) {
    if (icon.isDefault) {
      // On iOS: AppIcon or MainActivityDefault
      // On Android: MainActivityDefault
      return _currentIcon == 'MainActivityDefault' ||
          _currentIcon == 'AppIcon' ||
          _currentIcon.isEmpty;
    }
    return _currentIcon == icon.id;
  }

  Future<void> _selectIcon(AppIconOption icon) async {
    if (_isIconSelected(icon) || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (icon.isDefault) {
        await _chameleonIcons.resetIcon();
      } else {
        await _chameleonIcons.changeIcon(icon.id);
      }

      final updatedIcon = await _chameleonIcons.getCurrentIcon();

      if (!mounted) return;
      setState(() {
        _currentIcon = updatedIcon;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('App icon changed to "${icon.name}"'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to change icon: ${e.message}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'App Icon',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Platform & Current Status Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _platformVersion,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Active: ${_currentIcon.isEmpty ? "Default" : _currentIcon}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'CHOOSE AN ICON',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),

            // Telegram-style Horizontal Row Container
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _icons.map((iconOption) {
                  final isSelected = _isIconSelected(iconOption);

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _selectIcon(iconOption),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Squircle App Icon Preview with Stacked Checkmark Badge
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                    width: isSelected ? 3 : 0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                                .withValues(alpha: 0.25)
                                          : Colors.black.withValues(
                                              alpha: 0.12,
                                            ),
                                      blurRadius: isSelected ? 10 : 6,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.asset(
                                    iconOption.assetPath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: theme.colorScheme.surfaceContainer,
                                      child: const Icon(
                                        Icons.broken_image_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Telegram Checkmark Badge
                              if (isSelected)
                                Positioned(
                                  right: -4,
                                  bottom: -4,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.surface,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Icon Label
                          Text(
                            iconOption.name,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Telegram-style Radio Indicator
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
