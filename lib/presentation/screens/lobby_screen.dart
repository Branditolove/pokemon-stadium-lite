import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../providers/game_provider.dart';
import 'pokemon_selection_screen.dart';
import 'url_config_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({Key? key}) : super(key: key);

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

// ─── Bot data ─────────────────────────────────────────────────
const _botOptions = [
  {
    'difficulty': 'easy',
    'name': 'Toby',
    'stars': '⭐',
    'label': 'FÁCIL',
    'desc': 'Principiante, se distrae atacando',
    'color': Color(0xFF2e7d32),
    'border': Color(0xFF4caf50),
    'icon': '🌿',
  },
  {
    'difficulty': 'medium',
    'name': 'Gary',
    'stars': '⭐⭐⭐',
    'label': 'MEDIO',
    'desc': 'Rival equilibrado, elige el mejor movimiento',
    'color': Color(0xFFe65100),
    'border': Color(0xFFff9800),
    'icon': '🔥',
  },
  {
    'difficulty': 'brandon',
    'name': 'Brandon',
    'stars': '💀💀💀',
    'label': 'IMPOSIBLE',
    'desc': 'Lo contrataron para ganar. Siempre.',
    'color': Color(0xFF4a0000),
    'border': Color(0xFFcc0000),
    'icon': '💼',
  },
];

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nicknameController;
  bool _isJoining = false;
  String? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _joinLobby(GameProvider gameProvider) {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      _showError('Por favor ingresa tu nickname');
      return;
    }
    if (_selectedDifficulty == null) {
      _showError('Elige un oponente primero');
      return;
    }
    final bot = _botOptions.firstWhere((b) => b['difficulty'] == _selectedDifficulty);
    gameProvider.setSelectedBot(_selectedDifficulty!, bot['name'] as String);
    setState(() => _isJoining = true);
    gameProvider.joinLobby(nickname);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isJoining = false);
    });
  }

  void _changeUrl(GameProvider gameProvider) {
    gameProvider.disconnect();
    StorageService.clearBackendUrl();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const UrlConfigScreen()),
    );
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
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final lobby = gameProvider.lobby;
        final currentPlayer = gameProvider.currentPlayer;

        if (gameProvider.needsTeamSelection) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) => const PokemonSelectionScreen()),
            );
          });
        }

        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          appBar: AppBar(
            backgroundColor: AppColors.pokemonRed,
            elevation: 0,
            title: Text(
              'Pokémon Stadium Lite',
              style: GoogleFonts.bangers(
                color: AppColors.pokemonYellow,
                fontSize: 22,
                letterSpacing: 1,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: AppColors.pokemonYellow),
                onPressed: () => _changeUrl(gameProvider),
                tooltip: 'Cambiar servidor',
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // ─── Hero Header ─────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.pokemonRed, Color(0xFF880000)],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    children: [
                      // Pokeball
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Column(
                            children: [
                              Container(
                                  height: 35,
                                  color: AppColors.pokemonRed),
                              Container(height: 4, color: Colors.black),
                              Expanded(child: Container(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'LOBBY',
                        style: GoogleFonts.bangers(
                          color: AppColors.pokemonYellow,
                          fontSize: 42,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel(lobby.status),
                          style: TextStyle(
                            color: _statusColor(lobby.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // ─── Nickname Input ───────────────────────────
                      if (currentPlayer == null) ...[
                        const SizedBox(height: 4),
                        TextField(
                          controller: _nicknameController,
                          style: const TextStyle(
                              color: AppColors.lightGray, fontSize: 16),
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            hintText: 'Tu nombre de entrenador',
                            hintStyle:
                                TextStyle(color: Color(0xFF555555)),
                            prefixIcon: Icon(Icons.person_outline,
                                color: AppColors.pokemonRed),
                            filled: true,
                            fillColor: AppColors.darkGray,
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(14)),
                              borderSide: BorderSide(
                                  color: Color(0xFF444444), width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(14)),
                              borderSide: BorderSide(
                                  color: AppColors.pokemonYellow, width: 2),
                            ),
                          ),
                          enabled: !_isJoining,
                          onSubmitted: (_) => _joinLobby(gameProvider),
                        ),
                        const SizedBox(height: 20),
                        // ─── Bot Selection ────────────────────────────
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'ELIGE TU OPONENTE',
                            style: GoogleFonts.bangers(
                              color: AppColors.pokemonYellow,
                              fontSize: 18,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._botOptions.map((bot) {
                          final isSelected = _selectedDifficulty == bot['difficulty'];
                          final borderColor = bot['border'] as Color;
                          final bgColor = bot['color'] as Color;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDifficulty = bot['difficulty'] as String),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? bgColor.withOpacity(0.35) : AppColors.darkGray,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? borderColor : const Color(0xFF333333),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: borderColor.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  Text(bot['icon'] as String, style: const TextStyle(fontSize: 26)),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              bot['name'] as String,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : const Color(0xFFbbbbbb),
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: bgColor.withOpacity(0.5),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                bot['label'] as String,
                                                style: TextStyle(
                                                  color: borderColor,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          bot['desc'] as String,
                                          style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(bot['stars'] as String, style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle_rounded, color: borderColor, size: 22),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isJoining
                                ? null
                                : () => _joinLobby(gameProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.pokemonRed,
                              disabledBackgroundColor:
                                  const Color(0xFF882222),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 6,
                            ),
                            child: _isJoining
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: AppColors.pokemonYellow,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    _selectedDifficulty != null
                                        ? '⚔ LUCHAR CONTRA ${(_botOptions.firstWhere((b) => b['difficulty'] == _selectedDifficulty)['name'] as String).toUpperCase()}'
                                        : 'Entrar al Lobby',
                                    style: const TextStyle(
                                      color: AppColors.pokemonYellow,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                      ] else ...[
                        // ─── Joined indicator ─────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1a2a1a),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.hpHealthy, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: AppColors.hpHealthy, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Conectado como',
                                      style: TextStyle(
                                          color: AppColors.hpHealthy,
                                          fontSize: 11),
                                    ),
                                    Text(
                                      currentPlayer.nickname,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => gameProvider.resetPlayerState(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Cambiar',
                                  style: TextStyle(
                                    color: AppColors.pokemonYellow,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // ─── Players ──────────────────────────────────
                      if (lobby.players.isNotEmpty) ...[
                        Row(
                          children: [
                            const Text(
                              'JUGADORES',
                              style: TextStyle(
                                color: AppColors.pokemonYellow,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.pokemonRed,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${lobby.players.length}/2',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...lobby.players.map((player) {
                          final isCurrent =
                              currentPlayer?.id != null && player.id != null
                                  ? player.id == currentPlayer!.id
                                  : player.nickname ==
                                      currentPlayer?.nickname;
                          return _PlayerTile(
                            nickname: player.nickname,
                            isReady: player.ready,
                            isCurrentPlayer: isCurrent,
                          );
                        }).toList(),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppColors.darkGray,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFF333333), width: 1),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.catching_pokemon,
                                color: AppColors.pokemonYellow
                                    .withOpacity(0.35),
                                size: 52,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'El lobby está vacío',
                                style: TextStyle(
                                    color: Color(0xFF555555), fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        // ─── Spawn bot (when already in lobby alone) ──
                        if (currentPlayer != null) ...[
                          const SizedBox(height: 20),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'INVOCAR OPONENTE',
                              style: TextStyle(
                                color: AppColors.pokemonYellow,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._botOptions.map((bot) {
                            final isSelected = _selectedDifficulty == bot['difficulty'];
                            final borderColor = bot['border'] as Color;
                            final bgColor = bot['color'] as Color;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedDifficulty = bot['difficulty'] as String),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? bgColor.withOpacity(0.35) : AppColors.darkGray,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? borderColor : const Color(0xFF333333),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [BoxShadow(color: borderColor.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)]
                                      : [],
                                ),
                                child: Row(
                                  children: [
                                    Text(bot['icon'] as String, style: const TextStyle(fontSize: 26)),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                bot['name'] as String,
                                                style: TextStyle(
                                                  color: isSelected ? Colors.white : const Color(0xFFbbbbbb),
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: bgColor.withOpacity(0.5),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  bot['label'] as String,
                                                  style: TextStyle(
                                                    color: borderColor,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            bot['desc'] as String,
                                            style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(bot['stars'] as String, style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle_rounded, color: borderColor, size: 22),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _selectedDifficulty == null ? null : () {
                                final bot = _botOptions.firstWhere((b) => b['difficulty'] == _selectedDifficulty);
                                gameProvider.setSelectedBot(_selectedDifficulty!, bot['name'] as String);
                                gameProvider.spawnBot(_selectedDifficulty!);
                              },
                              icon: const Text('⚔', style: TextStyle(fontSize: 18)),
                              label: Text(
                                _selectedDifficulty != null
                                    ? 'INVOCAR A ${(_botOptions.firstWhere((b) => b['difficulty'] == _selectedDifficulty)['name'] as String).toUpperCase()}'
                                    : 'SELECCIONA UN OPONENTE',
                                style: const TextStyle(
                                  color: AppColors.pokemonYellow,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedDifficulty != null ? AppColors.pokemonRed : const Color(0xFF333333),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 6,
                              ),
                            ),
                          ),
                        ],
                      ],

                      if (gameProvider.errorMessage != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF330000),
                            border: Border.all(
                                color: AppColors.hpCritical, width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.hpCritical, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  gameProvider.errorMessage!,
                                  style: const TextStyle(
                                      color: AppColors.hpCritical,
                                      fontSize: 12),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => gameProvider.clearError(),
                                child: const Icon(Icons.close,
                                    color: AppColors.hpCritical, size: 16),
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
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'waiting':
        return AppColors.pokemonYellow;
      case 'ready':
        return AppColors.hpHealthy;
      case 'battling':
        return AppColors.pokemonRed;
      default:
        return const Color(0xFF888888);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'waiting':
        return '● ESPERANDO';
      case 'ready':
        return '● LISTO';
      case 'battling':
        return '⚔ BATALLANDO';
      case 'finished':
        return '✓ TERMINADO';
      default:
        return status.toUpperCase();
    }
  }
}

class _PlayerTile extends StatelessWidget {
  final String nickname;
  final bool isReady;
  final bool isCurrentPlayer;

  const _PlayerTile({
    required this.nickname,
    required this.isReady,
    required this.isCurrentPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            isCurrentPlayer ? const Color(0xFF1e1e0a) : AppColors.darkGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentPlayer
              ? AppColors.pokemonYellow
              : const Color(0xFF333333),
          width: isCurrentPlayer ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrentPlayer
                  ? AppColors.pokemonRed
                  : const Color(0xFF3a3a3a),
            ),
            child: Center(
              child: Text(
                nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isCurrentPlayer)
                  const Text(
                    'Tú',
                    style: TextStyle(
                        color: AppColors.pokemonYellow, fontSize: 11),
                  ),
              ],
            ),
          ),
          if (isReady)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.hpHealthy.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.hpHealthy, width: 1),
              ),
              child: const Text(
                '✓ LISTO',
                style: TextStyle(
                  color: AppColors.hpHealthy,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: const Color(0xFF444444), width: 1),
              ),
              child: const Text(
                '⏳ ESPERA',
                style: TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
