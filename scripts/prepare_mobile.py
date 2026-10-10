"""One-time migration to mobile navigation and shared loading components."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
lib = root / 'prepmate_mobile/lib'
for file in lib.rglob('*.dart'):
    text = file.read_text(encoding='utf-8')
    # Keep determinate score rings: they show a measurement, not loading.
    pattern = r'CircularProgressIndicator\(([^()]*)\)'
    changed = re.sub(pattern, lambda m: m.group(0) if 'value:' in m.group(1) else 'AppLoading(' + m.group(1) + ')', text)
    if changed != text:
        changed = "import 'package:prepmate_mobile/core/widgets/app_loading.dart';\n" + changed
        file.write_text(changed, encoding='utf-8')

file = lib / 'features/home/presentation/screens/home_screen.dart'
text = file.read_text(encoding='utf-8')
text = re.sub(r"import .*interview_screen.dart';\n", '', text)
text = text.replace('  bool _profileDialogShown = false;', '  bool _profileDialogShown = false;\n  final Set<int> _visitedTabs = {0};')
text = text.replace('    final bottomNavIndex = ref.watch(bottomNavProvider);', '    final bottomNavIndex = ref.watch(bottomNavProvider);\n    _visitedTabs.add(bottomNavIndex);')
start = text.index('      body: IndexedStack(')
end = text.index('      bottomNavigationBar:', start)
text = text[:start] + '''      body: IndexedStack(
        index: bottomNavIndex,
        children: List.generate(3, (index) => TickerMode(
          enabled: index == bottomNavIndex,
          child: !_visitedTabs.contains(index) ? const SizedBox.shrink()
            : TweenAnimationBuilder<double>(
                key: ValueKey('$index-${index == bottomNavIndex}'),
                tween: Tween(begin: 0, end: 1),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero : const Duration(milliseconds: 240),
                builder: (context, value, child) => Opacity(opacity: value,
                  child: Transform.translate(offset: Offset(0, 8 * (1 - value)), child: child)),
                child: switch (index) {
                  0 => const _HomeContent(),
                  1 => const AnalyzeScreen(),
                  _ => const CoursesScreen(),
                },
              ),
        )),
      ),
''' + text[end:]
start = text.index('    return BottomNavigationBar(')
end = text.index('\n  }\n}', start)
text = text[:start] + '''    return NavigationBar(
      selectedIndex: currentIndex,
      backgroundColor: colors.cardBackground,
      indicatorColor: colors.primarySoft,
      animationDuration: const Duration(milliseconds: 240),
      onDestinationSelected: (index) {
        if (index == 3) {
          context.push('/profile');
        } else {
          ref.read(bottomNavProvider.notifier).state = index;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics_rounded), label: 'Analyze'),
        NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories), label: 'Learn'),
        NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );''' + text[end:]
file.write_text(text, encoding='utf-8')

# Preserve the old import path without maintaining a second home implementation.
(lib / 'features/home/screens/home_screen.dart').write_text("export '../presentation/screens/home_screen.dart' show HomeScreen;\n", encoding='utf-8')

file = lib / 'config/theme.dart'
text = file.read_text(encoding='utf-8').replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'page_transitions.dart';")
text = text.replace('static ThemeData lightTheme = ThemeData(', '''static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.light.primary),
    pageTransitionsTheme: transitions,
    appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0, scrolledUnderElevation: 0),''')
text = text.replace('static ThemeData darkTheme = ThemeData(', '''static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.dark.primary, brightness: Brightness.dark),
    pageTransitionsTheme: transitions,
    appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0, scrolledUnderElevation: 0),''')
text = text.replace('class AppTheme {', '''class AppTheme {
  static const transitions = PageTransitionsTheme(builders: {
    TargetPlatform.android: PrepMatePageTransitions(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  });''')
file.write_text(text, encoding='utf-8')
