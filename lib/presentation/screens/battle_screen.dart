import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/player_model.dart';
import '../../data/models/pokemon_model.dart';
import '../providers/game_provider.dart';
import '../widgets/battle_log.dart';
import 'lobby_screen.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({Key? key}) : super(key: key);

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen>
    with TickerProviderStateMixin {
  bool _isAttacking = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Faint flash overlay (whole arena turns white when a pokemon faints)
  late AnimationController _faintFlashController;
  late Animation<double> _faintFlashOpacity;
  int _prevBattleLogLength = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _faintFlashController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _faintFlashOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.85), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 0.55), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 0.85), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 0.0), weight: 60),
    ]).animate(CurvedAnimation(
      parent: _faintFlashController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _faintFlashController.dispose();
    super.dispose();
  }

  void _attack(GameProvider gameProvider, String moveName) {
    if (!_isAttacking && gameProvider.isMyTurn && !gameProvider.needsPokemonSwitch) {
      setState(() => _isAttacking = true);
      gameProvider.attack(moveName);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _isAttacking = false);
      });
    }
  }

  void _backToLobby(GameProvider gameProvider) {
    gameProvider.disconnect();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LobbyScreen()),
    );
  }

  PlayerModel? _getOpponentPlayer(GameProvider gameProvider) {
    final currentPlayer = gameProvider.currentPlayer;
    if (currentPlayer == null) return null;
    return gameProvider.lobby.players
        .where((p) => currentPlayer.id != null && p.id != null
            ? p.id != currentPlayer.id
            : p.nickname != currentPlayer.nickname)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final currentPlayer = gameProvider.currentPlayer;
        final opponentPlayer = _getOpponentPlayer(gameProvider);
        final lobby = gameProvider.lobby;
        final currentPokemon = currentPlayer?.activePokemon;
        final opponentPokemon = opponentPlayer?.activePokemon;

        if (lobby.isFinished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showBattleEndDialog(context, gameProvider);
          });
        }

        // Detect pokemon fainted → trigger arena flash
        final logLen = gameProvider.battleLog.length;
        if (logLen > _prevBattleLogLength) {
          final newEntries = gameProvider.battleLog.sublist(_prevBattleLogLength);
          _prevBattleLogLength = logLen;
          if (newEntries.any((e) => e.contains('debilitado'))) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _faintFlashController.forward(from: 0.0);
            });
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0d1117),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, color: AppColors.pokemonYellow, size: 18),
                const SizedBox(width: 6),
                Text(
                  'BATALLA',
                  style: GoogleFonts.bangers(
                    color: AppColors.pokemonYellow,
                    fontSize: 26,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.bolt, color: AppColors.pokemonYellow, size: 18),
              ],
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // ─── Battle Arena ───────────────────────────────────────
              Expanded(
                flex: 5,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background gradient (sky / ground)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.0, 0.52, 0.52, 1.0],
                            colors: [
                              Color(0xFF1a3a5c),
                              Color(0xFF2d6a9f),
                              Color(0xFF2d5016),
                              Color(0xFF1a3009),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Horizon line
                    Align(
                      alignment: const Alignment(0, 0.04),
                      child: Container(height: 2, color: Colors.black26),
                    ),
                    // Stars in sky
                    ...List.generate(14, (i) {
                      final r = Random(i * 13 + 7);
                      return Positioned(
                        top: r.nextDouble() * 90,
                        left: r.nextDouble() * 360,
                        child: Container(
                          width: 2,
                          height: 2,
                          decoration: const BoxDecoration(
                            color: Colors.white54,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }),
                    // Clouds
                    const Positioned(
                        top: 14, left: 22,
                        child: _BattleCloud(width: 72, height: 26)),
                    const Positioned(
                        top: 38, left: 140,
                        child: _BattleCloud(width: 50, height: 18)),
                    const Positioned(
                        top: 10, right: 36,
                        child: _BattleCloud(width: 68, height: 24)),
                    // Grass strip on ground (horizon decoration)
                    Positioned(
                      top: 0, bottom: 0, left: 0, right: 0,
                      child: Column(
                        children: [
                          const Spacer(),
                          Container(
                            height: 6,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF3a6b14), Color(0xFF4a8c1c)],
                              ),
                            ),
                          ),
                          const SizedBox(height: 0),
                        ],
                      ),
                    ),

                    // Opponent status box — top-left
                    if (opponentPlayer != null && opponentPokemon != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        width: 172,
                        child: _StatusBox(
                          name: opponentPokemon.name,
                          nickname: opponentPlayer.nickname,
                          currentHp: opponentPokemon.currentHp,
                          maxHp: opponentPokemon.hp,
                        ),
                      ),

                    // Opponent sprite — top-right
                    if (opponentPokemon != null)
                      Positioned(
                        top: 10,
                        right: 8,
                        child: _PokemonSprite(
                          sprite: opponentPokemon.sprite,
                          size: 128,
                          flip: false,
                          currentHp: opponentPokemon.currentHp,
                          maxHp: opponentPokemon.hp,
                        ),
                      ),

                    // Player sprite — bottom-left
                    if (currentPokemon != null)
                      Positioned(
                        bottom: 12,
                        left: 8,
                        child: _PokemonSprite(
                          sprite: currentPokemon.sprite,
                          size: 145,
                          flip: true,
                          currentHp: currentPokemon.currentHp,
                          maxHp: currentPokemon.hp,
                        ),
                      ),

                    // Faint flash overlay
                    AnimatedBuilder(
                      animation: _faintFlashController,
                      builder: (_, __) => _faintFlashOpacity.value > 0
                          ? Positioned.fill(
                              child: Container(
                                color: Colors.white
                                    .withValues(alpha: _faintFlashOpacity.value),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Player status box — bottom-right
                    if (currentPlayer != null && currentPokemon != null)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        width: 172,
                        child: _StatusBox(
                          name: currentPokemon.name,
                          nickname: currentPlayer.nickname,
                          currentHp: currentPokemon.currentHp,
                          maxHp: currentPokemon.hp,
                        ),
                      ),
                  ],
                ),
              ),

              // ─── Battle Log ─────────────────────────────────────────
              Container(
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFF12121e),
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: AppColors.pokemonYellow.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: BattleLog(
                  messages: gameProvider.battleLog,
                  maxMessages: 3,
                ),
              ),

              // ─── Bottom Panel: Switch or Moves ───────────────────────
              gameProvider.needsPokemonSwitch && currentPlayer != null
                  ? _PokemonSwitchPanel(
                      alivePokemon: currentPlayer.team
                          .where((p) => !p.defeated)
                          .toList(),
                      onSwitch: (name) => gameProvider.switchPokemon(name),
                    )
                  : Container(
                      color: const Color(0xFF0d1117),
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Turn indicator
                          Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (gameProvider.isMyTurn) ...[
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (_, __) => Opacity(
                                      opacity: _pulseAnimation.value,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.hpHealthy,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'TU TURNO  —  ELIGE UN MOVIMIENTO',
                                    style: TextStyle(
                                      color: AppColors.hpHealthy,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppColors.pokemonRed.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'TURNO DEL RIVAL...',
                                    style: TextStyle(
                                      color: AppColors.pokemonRed.withOpacity(0.8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Move buttons
                          if (currentPokemon != null &&
                              currentPokemon.moves.isNotEmpty)
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 2.6,
                              children: currentPokemon.moves.map((move) {
                                final canAttack = gameProvider.isMyTurn &&
                                    !_isAttacking &&
                                    !lobby.isFinished;
                                return _MoveButton(
                                  moveName: move.name,
                                  movePower: move.power,
                                  moveType: move.type,
                                  enabled: canAttack,
                                  onTap: canAttack
                                      ? () => _attack(gameProvider, move.name)
                                      : null,
                                );
                              }).toList(),
                            )
                          else
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: (gameProvider.isMyTurn &&
                                        !_isAttacking &&
                                        !lobby.isFinished)
                                    ? () => _attack(gameProvider, 'tackle')
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.pokemonRed,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text(
                                  'ATACAR',
                                  style: TextStyle(
                                    color: AppColors.pokemonYellow,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

              // Error bar
              if (gameProvider.errorMessage != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: const Color(0xFF330000),
                  child: Row(
                    children: [
                      const Icon(Icons.error,
                          color: AppColors.hpCritical, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          gameProvider.errorMessage!,
                          style: const TextStyle(
                              color: AppColors.hpCritical, fontSize: 11),
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
          ),
        );
      },
    );
  }

  void _showBattleEndDialog(
      BuildContext context, GameProvider gameProvider) {
    final winnerId = gameProvider.lobby.winner;
    final currentPlayer = gameProvider.currentPlayer;
    final isVictory = winnerId == currentPlayer?.id;
    final winnerPlayer =
        gameProvider.lobby.players.where((p) => p.id == winnerId).firstOrNull;
    final winnerName = winnerPlayer?.nickname ?? winnerId ?? 'Desconocido';
    final brandonMessage = gameProvider.brandonMessage;
    final isBrandonWin = brandonMessage != null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isBrandonWin
                    ? [const Color(0xFF1a0000), const Color(0xFF3d0000)]
                    : isVictory
                        ? [const Color(0xFF0d2b0d), const Color(0xFF1a5c1a)]
                        : [const Color(0xFF2b0d0d), const Color(0xFF5c1a1a)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isBrandonWin
                    ? const Color(0xFFcc0000)
                    : isVictory
                        ? AppColors.hpHealthy
                        : AppColors.pokemonRed,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isBrandonWin
                          ? const Color(0xFFcc0000)
                          : isVictory
                              ? AppColors.hpHealthy
                              : AppColors.pokemonRed)
                      .withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isBrandonWin ? '💼' : isVictory ? '🏆' : '💀',
                  style: const TextStyle(fontSize: 56),
                ),
                const SizedBox(height: 10),
                Text(
                  isBrandonWin
                      ? '¡BRANDON GANA!'
                      : isVictory
                          ? '¡VICTORIA!'
                          : '¡DERROTA!',
                  style: GoogleFonts.bangers(
                    color: isBrandonWin
                        ? const Color(0xFFff4444)
                        : isVictory
                            ? AppColors.hpHealthy
                            : AppColors.pokemonRed,
                    fontSize: 38,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ganador: $winnerName',
                  style: const TextStyle(
                    color: AppColors.pokemonYellow,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Brandon's special message
                if (isBrandonWin) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF660000), width: 1),
                    ),
                    child: Column(
                      children: [
                        const Text('💬', style: TextStyle(fontSize: 20)),
                        const SizedBox(height: 6),
                        Text(
                          brandonMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFffaaaa),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _backToLobby(gameProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pokemonRed,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Volver al Lobby',
                      style: TextStyle(
                        color: AppColors.pokemonYellow,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Pokemon Switch Panel ─────────────────────────────────────────────────────
class _PokemonSwitchPanel extends StatelessWidget {
  final List<PokemonModel> alivePokemon;
  final void Function(String pokemonName) onSwitch;

  const _PokemonSwitchPanel({
    required this.alivePokemon,
    required this.onSwitch,
  });

  Color _hpColor(PokemonModel p) {
    if (p.hp == 0) return AppColors.hpHealthy;
    final pct = p.currentHp / p.hp;
    if (pct > 0.5) return AppColors.hpHealthy;
    if (pct > 0.25) return AppColors.hpWarning;
    return AppColors.hpCritical;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0d1117),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1a0000),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.pokemonRed, width: 1),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.catching_pokemon, color: AppColors.pokemonRed, size: 14),
                SizedBox(width: 6),
                Text(
                  '¡Elige tu siguiente Pokémon!',
                  style: TextStyle(
                    color: AppColors.pokemonYellow,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Pokemon cards
          Row(
            children: alivePokemon.map((pokemon) {
              final hpPct = pokemon.hp > 0 ? pokemon.currentHp / pokemon.hp : 0.0;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSwitch(pokemon.name),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1e2030), Color(0xFF12121e)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.pokemonYellow.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sprite
                        SizedBox(
                          height: 52,
                          width: 52,
                          child: pokemon.sprite.isNotEmpty
                              ? Image.network(
                                  pokemon.sprite,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.catching_pokemon,
                                    size: 36,
                                    color: AppColors.pokemonYellow,
                                  ),
                                )
                              : const Icon(
                                  Icons.catching_pokemon,
                                  size: 36,
                                  color: AppColors.pokemonYellow,
                                ),
                        ),
                        const SizedBox(height: 4),
                        // Name
                        Text(
                          pokemon.name[0].toUpperCase() + pokemon.name.substring(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // HP bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Stack(
                            children: [
                              Container(height: 6, color: const Color(0xFF333333)),
                              FractionallySizedBox(
                                widthFactor: hpPct.clamp(0.0, 1.0),
                                child: Container(height: 6, color: _hpColor(pokemon)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pokemon.currentHp}/${pokemon.hp} HP',
                          style: TextStyle(
                            color: _hpColor(pokemon),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Status Box (Pokemon-game HUD style) ─────────────────────────────────────
class _StatusBox extends StatefulWidget {
  final String name;
  final String nickname;
  final int currentHp;
  final int maxHp;

  const _StatusBox({
    required this.name,
    required this.nickname,
    required this.currentHp,
    required this.maxHp,
  });

  @override
  State<_StatusBox> createState() => _StatusBoxState();
}

class _StatusBoxState extends State<_StatusBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _hpAnim;
  int _displayHp = 0;

  @override
  void initState() {
    super.initState();
    _displayHp = widget.currentHp;
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
  }

  @override
  void didUpdateWidget(_StatusBox old) {
    super.didUpdateWidget(old);
    if (old.currentHp != widget.currentHp) {
      _hpAnim = IntTween(begin: _displayHp, end: widget.currentHp).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
      );
      _hpAnim.addListener(() => setState(() => _displayHp = _hpAnim.value));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _hpColor() {
    if (widget.maxHp == 0) return AppColors.hpHealthy;
    final pct = _displayHp / widget.maxHp;
    if (pct > 0.5) return AppColors.hpHealthy;
    if (pct > 0.25) return AppColors.hpWarning;
    return AppColors.hpCritical;
  }

  @override
  Widget build(BuildContext context) {
    final pct =
        (_displayHp / (widget.maxHp == 0 ? 1 : widget.maxHp)).clamp(0.0, 1.0);
    final isFainted = widget.currentHp == 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: isFainted ? const Color(0xFFf0f0f0) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 6,
              offset: const Offset(2, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  widget.name.toUpperCase(),
                  style: TextStyle(
                    color: isFainted ? Colors.grey : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isFainted)
                const Text(
                  'DEB.',
                  style: TextStyle(
                    color: Color(0xFFCC0000),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  widget.nickname,
                  style: const TextStyle(
                      color: Color(0xFF666666), fontSize: 9),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                'HP',
                style: TextStyle(
                    color: isFainted ? Colors.grey : const Color(0xFF333333),
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(height: 9, color: const Color(0xFFDDDDDD)),
                      FractionallySizedBox(
                        widthFactor: pct,
                        child: Container(height: 9, color: _hpColor()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$_displayHp / ${widget.maxHp}',
              style:
                  const TextStyle(color: Color(0xFF777777), fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pokemon Sprite ───────────────────────────────────────────────────────────
class _PokemonSprite extends StatefulWidget {
  final String sprite;
  final double size;
  final bool flip;
  final int currentHp;
  final int maxHp;

  const _PokemonSprite({
    required this.sprite,
    required this.size,
    this.flip = false,
    this.currentHp = 100,
    this.maxHp = 100,
  });

  @override
  State<_PokemonSprite> createState() => _PokemonSpriteState();
}

class _PokemonSpriteState extends State<_PokemonSprite>
    with SingleTickerProviderStateMixin {
  late AnimationController _hitController;
  late Animation<double> _hitFlash;

  @override
  void initState() {
    super.initState();
    _hitController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    // Two-pulse red flash: hit → fade → hit → fade
    _hitFlash = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 0.2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.75), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 0.0), weight: 40),
    ]).animate(_hitController);
  }

  @override
  void didUpdateWidget(_PokemonSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentHp < oldWidget.currentHp && widget.currentHp >= 0) {
      _hitController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _hitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFainted = widget.currentHp == 0;

    Widget img = widget.sprite.isNotEmpty
        ? Image.network(
            widget.sprite,
            height: widget.size,
            width: widget.size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(Icons.catching_pokemon,
                size: widget.size * 0.65, color: AppColors.pokemonYellow),
          )
        : Icon(Icons.catching_pokemon,
            size: widget.size * 0.65, color: AppColors.pokemonYellow);

    if (widget.flip) {
      img = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(pi),
        child: img,
      );
    }

    // Grayscale + fade for fainted pokemon
    if (isFainted) {
      img = Opacity(
        opacity: 0.35,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0,      0,      0,      1, 0,
          ]),
          child: img,
        ),
      );
      return img;
    }

    return AnimatedBuilder(
      animation: _hitController,
      builder: (context, child) => ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.red.withValues(alpha: _hitFlash.value),
          BlendMode.srcATop,
        ),
        child: child,
      ),
      child: img,
    );
  }
}

// ─── Move Button ──────────────────────────────────────────────────────────────
class _MoveButton extends StatelessWidget {
  final String moveName;
  final int movePower;
  final String moveType;
  final bool enabled;
  final VoidCallback? onTap;

  const _MoveButton({
    required this.moveName,
    required this.movePower,
    required this.moveType,
    required this.enabled,
    this.onTap,
  });

  Color _darkenColor(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getTypeColor(moveType);
    final darkColor = _darkenColor(color);
    final displayName = moveName
        .split('-')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
        .join(' ');

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [darkColor, color],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(enabled ? 0.2 : 0.05),
            width: 1,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            splashColor: Colors.white30,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.only(left: 9),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            moveType.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '⚡ $movePower',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Battle Cloud ─────────────────────────────────────────────────────────────
class _BattleCloud extends StatelessWidget {
  final double width;
  final double height;

  const _BattleCloud({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: height * 0.4,
            child: Container(
              width: width * 0.48,
              height: height * 0.6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(width),
              ),
            ),
          ),
          Positioned(
            left: width * 0.2,
            top: 0,
            child: Container(
              width: width * 0.52,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(width),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: height * 0.35,
            child: Container(
              width: width * 0.42,
              height: height * 0.65,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(width),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
