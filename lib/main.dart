import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/services/storage_service.dart';
import 'presentation/providers/game_provider.dart';
import 'presentation/screens/lobby_screen.dart';
import 'presentation/screens/url_config_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if backend URL is already saved
  final savedUrl = await StorageService.getBackendUrl();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => GameProvider(),
        ),
      ],
      child: MyApp(
        savedUrl: savedUrl,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? savedUrl;

  const MyApp({
    Key? key,
    this.savedUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon Stadium Lite',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: AppColors.pokemonRed,
          secondary: AppColors.pokemonYellow,
          surface: AppColors.darkGray,
          background: AppColors.darkBackground,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.pokemonRed,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.pokemonYellow),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.pokemonRed,
            foregroundColor: AppColors.pokemonYellow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.pokemonYellow,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: AppColors.pokemonYellow,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: AppColors.lightGray,
          ),
          bodyMedium: TextStyle(
            color: AppColors.lightGray,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: AppColors.darkGray,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.pokemonRed,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.pokemonRed,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.pokemonYellow,
              width: 2,
            ),
          ),
        ),
      ),
      home: _buildHome(context),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _buildHome(BuildContext context) {
    if (savedUrl != null && savedUrl!.isNotEmpty) {
      // Auto-connect if URL is saved
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final gameProvider =
            Provider.of<GameProvider>(context, listen: false);
        if (!gameProvider.isSocketConnected) {
          gameProvider.connectToBackend(savedUrl!);
        }
      });

      return const LobbyScreen();
    } else {
      return const UrlConfigScreen();
    }
  }
}
