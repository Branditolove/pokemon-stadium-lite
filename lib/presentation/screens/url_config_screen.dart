import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../providers/game_provider.dart';
import 'lobby_screen.dart';

class UrlConfigScreen extends StatefulWidget {
  const UrlConfigScreen({Key? key}) : super(key: key);

  @override
  State<UrlConfigScreen> createState() => _UrlConfigScreenState();
}

class _UrlConfigScreenState extends State<UrlConfigScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _urlController;
  bool _isLoading = false;
  String? _savedUrl;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _rotateController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    _loadSavedUrl();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  static const String _defaultBackendUrl =
      'https://pokemon-stadium-backend-production.up.railway.app';

  Future<void> _loadSavedUrl() async {
    final url = await StorageService.getBackendUrl();
    if (mounted) {
      setState(() {
        _savedUrl = url;
        _urlController.text = url ?? _defaultBackendUrl;
      });
    }
  }

  Future<void> _connectToBackend() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showError('Por favor ingresa una URL');
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      _showError('La URL debe comenzar con http:// o https://');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await StorageService.saveBackendUrl(url);
      if (mounted) {
        final gameProvider =
            Provider.of<GameProvider>(context, listen: false);
        await gameProvider.connectToBackend(url);
        if (gameProvider.isSocketConnected) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LobbyScreen()),
            );
          }
        } else {
          if (mounted) {
            _showError('No se pudo conectar al servidor');
            setState(() => _isLoading = false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Error de conexión: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.hpCritical,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ─── Top hero ─────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF990000), Color(0xFF660000)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                child: Column(
                  children: [
                    // Animated Pokeball
                    AnimatedBuilder(
                      animation: _rotateController,
                      builder: (_, child) => Transform.rotate(
                        angle: _rotateController.value * 2 * 3.14159,
                        child: child,
                      ),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.pokemonYellow.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Column(
                            children: [
                              Container(
                                  height: 42,
                                  color: AppColors.pokemonRed),
                              Container(height: 4, color: Colors.black),
                              Expanded(
                                  child: Container(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Pokémon Stadium',
                      style: TextStyle(
                        color: AppColors.pokemonYellow,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const Text(
                      'LITE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Form ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SERVIDOR',
                      style: TextStyle(
                        color: AppColors.pokemonYellow,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ingresa la IP del backend',
                      style: TextStyle(
                          color: Color(0xFF666666), fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _urlController,
                      style: const TextStyle(
                          color: AppColors.lightGray, fontSize: 15),
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        hintText: 'https://tu-servidor.up.railway.app',
                        hintStyle: TextStyle(color: Color(0xFF555555)),
                        prefixIcon: Icon(Icons.link_rounded,
                            color: AppColors.pokemonRed),
                        filled: true,
                        fillColor: AppColors.darkGray,
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(14)),
                          borderSide:
                              BorderSide(color: Color(0xFF444444), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(14)),
                          borderSide: BorderSide(
                              color: AppColors.pokemonYellow, width: 2),
                        ),
                      ),
                      enabled: !_isLoading,
                      onSubmitted: (_) => _connectToBackend(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _connectToBackend,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pokemonRed,
                          disabledBackgroundColor:
                              const Color(0xFF882222),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 8,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: AppColors.pokemonYellow,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Conectar',
                                style: TextStyle(
                                  color: AppColors.pokemonYellow,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),

                    // Last saved URL
                    if (_savedUrl != null) ...[
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.darkGray,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF444444), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.history,
                                color: Color(0xFF666666), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Última URL',
                                    style: TextStyle(
                                        color: Color(0xFF888888),
                                        fontSize: 11),
                                  ),
                                  Text(
                                    _savedUrl!,
                                    style: const TextStyle(
                                        color: AppColors.lightGray,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
