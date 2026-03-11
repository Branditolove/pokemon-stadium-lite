import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/pokemon_model.dart';

class PokemonCard extends StatelessWidget {
  final PokemonModel pokemon;
  final bool isSelected;
  final VoidCallback? onTap;

  const PokemonCard({
    Key? key,
    required this.pokemon,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  Color _darken(Color color, [double factor = 0.22]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - factor).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final primaryType =
        pokemon.type.isNotEmpty ? pokemon.type[0].toLowerCase() : 'normal';
    final typeColor = AppColors.getTypeColor(primaryType);
    final darkTypeColor = _darken(typeColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.pokemonYellow
                : typeColor.withOpacity(0.55),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.pokemonYellow.withOpacity(0.45)
                  : typeColor.withOpacity(0.25),
              blurRadius: isSelected ? 14 : 8,
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            children: [
              // ── Top: Type gradient with sprite ──────────────────────
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [typeColor.withOpacity(0.85), darkTypeColor],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pokeball watermark
                      Positioned(
                        right: -12,
                        bottom: -12,
                        child: Opacity(
                          opacity: 0.13,
                          child: const Icon(
                            Icons.catching_pokemon,
                            size: 72,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Sprite
                      Positioned(
                        bottom: 4,
                        child: pokemon.sprite.isNotEmpty
                            ? Image.network(
                                pokemon.sprite,
                                height: 78,
                                width: 78,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.catching_pokemon,
                                  size: 58,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              )
                            : Icon(
                                Icons.catching_pokemon,
                                size: 58,
                                color: Colors.white.withOpacity(0.7),
                              ),
                      ),
                      // Selected checkmark
                      if (isSelected)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.pokemonYellow,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.check,
                                color: Colors.black, size: 14),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Bottom: Info section ─────────────────────────────────
              Expanded(
                flex: 6,
                child: Container(
                  color: const Color(0xFF1a1a2e),
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name
                      Text(
                        pokemon.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Type chips
                      Wrap(
                        spacing: 3,
                        children: pokemon.type
                            .map(
                              (t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.getTypeColor(
                                      t.toLowerCase()),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  t.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 5),
                      Container(height: 1, color: Colors.white12),
                      const SizedBox(height: 4),
                      // Stat bars
                      _StatBar(
                          label: 'HP',
                          value: pokemon.hp,
                          color: AppColors.hpHealthy),
                      const SizedBox(height: 3),
                      _StatBar(
                          label: 'ATK',
                          value: pokemon.attack,
                          color: const Color(0xFFFF6B35)),
                      const SizedBox(height: 3),
                      _StatBar(
                          label: 'DEF',
                          value: pokemon.defense,
                          color: const Color(0xFF4ECDC4)),
                      const SizedBox(height: 3),
                      _StatBar(
                          label: 'SPD',
                          value: pokemon.speed,
                          color: AppColors.pokemonYellow),
                      // Defeated badge
                      if (pokemon.defeated) ...[
                        const SizedBox(height: 5),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.hpCritical.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                                color: AppColors.hpCritical, width: 1),
                          ),
                          child: const Text(
                            'DEBILITADO',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.hpCritical,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat Bar ─────────────────────────────────────────────────────────────────
class _StatBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  static const int _maxStat = 255;

  const _StatBar(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final fraction = (value / _maxStat).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 26,
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 8,
                fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                Container(height: 5, color: Colors.white12),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(height: 5, color: color),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 24,
          child: Text(
            value.toString(),
            textAlign: TextAlign.right,
            style: TextStyle(
                color: color, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
