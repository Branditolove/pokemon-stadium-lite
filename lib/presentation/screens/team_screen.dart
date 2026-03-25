import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/game_provider.dart';
import '../widgets/pokemon_card.dart';
import 'battle_screen.dart';
import 'lobby_screen.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({Key? key}) : super(key: key);

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen>
    with SingleTickerProviderStateMixin {
  bool _isReady = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _readyForBattle(GameProvider gameProvider) {
    setState(() => _isReady = true);
    gameProvider.ready();
  }

  void _backToLobby(GameProvider gameProvider) {
    gameProvider.disconnect();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LobbyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final lobby = gameProvider.lobby;
        final currentPlayer = gameProvider.currentPlayer;

        if (lobby.isBattling) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const BattleScreen()),
            );
          });
        }

        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          appBar: AppBar(
            backgroundColor: AppColors.pokemonRed,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: AppColors.pokemonYellow),
              onPressed: () => _backToLobby(gameProvider),
            ),
            title: Text(
              'Tu Equipo',
              style: GoogleFonts.bangers(
                color: AppColors.pokemonYellow,
                fontSize: 24,
                letterSpacing: 1,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // ─── Player Header ──────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF880000), Color(0xFF440000)],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                          border:
                              Border.all(color: AppColors.pokemonYellow, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            currentPlayer?.nickname.isNotEmpty == true
                                ? currentPlayer!.nickname[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.pokemonYellow,
                              fontSize: 22,
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
                              currentPlayer?.nickname ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${currentPlayer?.team.length ?? 0} Pokémon asignados',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      // Status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _isReady
                              ? AppColors.hpHealthy.withOpacity(0.2)
                              : Colors.black26,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isReady
                                ? AppColors.hpHealthy
                                : Colors.white30,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _isReady ? '✓ LISTO' : '⏳ PREP',
                          style: TextStyle(
                            color: _isReady
                                ? AppColors.hpHealthy
                                : Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─── Team Grid ──────────────────────────────
                      if (currentPlayer != null &&
                          currentPlayer.team.isNotEmpty) ...[
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: currentPlayer.team.length,
                          itemBuilder: (context, index) {
                            return PokemonCard(
                              pokemon: currentPlayer.team[index],
                              isSelected: false,
                            );
                          },
                        ),
                      ] else ...[
                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.darkGray,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFF333333), width: 1),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                  color: AppColors.pokemonYellow,
                                  strokeWidth: 2.5),
                              SizedBox(height: 14),
                              Text(
                                'Obteniendo tu equipo...',
                                style: TextStyle(
                                    color: Color(0xFF666666), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ─── Rival Status ────────────────────────────
                      if (lobby.players.length > 1) ...[
                        const Text(
                          'RIVAL',
                          style: TextStyle(
                            color: AppColors.pokemonYellow,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...lobby.players
                            .where((p) =>
                                currentPlayer?.id != null && p.id != null
                                    ? p.id != currentPlayer!.id
                                    : p.nickname != currentPlayer?.nickname)
                            .map((player) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkGray,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFF333333),
                                        width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF3a3a3a),
                                        ),
                                        child: Center(
                                          child: Text(
                                            player.nickname.isNotEmpty
                                                ? player.nickname[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              player.nickname,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '${player.team.length} Pokémon',
                                              style: const TextStyle(
                                                  color: Color(0xFF666666),
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (player.ready)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.hpHealthy
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: AppColors.hpHealthy,
                                                width: 1),
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
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color:
                                                    const Color(0xFF444444),
                                                width: 1),
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
                                ))
                            .toList(),
                        const SizedBox(height: 20),
                      ],

                      // Error
                      if (gameProvider.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
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
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: !_isReady
                  ? SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: currentPlayer != null &&
                                currentPlayer.team.isNotEmpty
                            ? () => _readyForBattle(gameProvider)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.hpHealthy,
                          disabledBackgroundColor: const Color(0xFF336633),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 8,
                        ),
                        child: const Text(
                          '⚔️  ¡Listo para Batallar!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (_, __) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0d2b0d),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.hpHealthy
                                .withOpacity(_glowAnimation.value),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.hpHealthy
                                  .withOpacity(_glowAnimation.value * 0.3),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppColors.hpHealthy, size: 32),
                            const SizedBox(height: 8),
                            const Text(
                              '¡Listo!',
                              style: TextStyle(
                                color: AppColors.hpHealthy,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lobby.players.length > 1
                                  ? (lobby.allPlayersReady
                                      ? 'Iniciando batalla...'
                                      : 'Esperando al rival...')
                                  : 'Esperando jugadores...',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
