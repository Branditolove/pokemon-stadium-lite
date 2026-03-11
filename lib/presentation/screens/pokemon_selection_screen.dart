import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/game_provider.dart';
import 'team_screen.dart';

class PokemonSelectionScreen extends StatefulWidget {
  const PokemonSelectionScreen({Key? key}) : super(key: key);

  @override
  State<PokemonSelectionScreen> createState() => _PokemonSelectionScreenState();
}

class _PokemonSelectionScreenState extends State<PokemonSelectionScreen> {
  List<int> _selectedIds = [];
  String _selectedType = 'Todos';
  bool _confirming = false;

  List<String> _getAvailableTypes(List<dynamic> pokemon) {
    final types = <String>{'Todos'};
    for (final p in pokemon) {
      final typeList = p['type'] as List?;
      if (typeList != null) {
        for (final t in typeList) {
          types.add(_capitalize(t.toString()));
        }
      }
    }
    return types.toList()..sort((a, b) => a == 'Todos' ? -1 : a.compareTo(b));
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  List<dynamic> _filterPokemon(List<dynamic> pokemon) {
    if (_selectedType == 'Todos') return pokemon;
    return pokemon.where((p) {
      final types = (p['type'] as List?)?.map((t) => _capitalize(t.toString())).toList() ?? [];
      return types.contains(_selectedType);
    }).toList();
  }

  void _toggleSelection(int pokemonId) {
    setState(() {
      if (_selectedIds.contains(pokemonId)) {
        _selectedIds.remove(pokemonId);
      } else if (_selectedIds.length < 3) {
        _selectedIds.add(pokemonId);
      }
    });
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire': return Colors.deepOrange;
      case 'water': return Colors.blue;
      case 'grass': return Colors.green;
      case 'electric': return Colors.amber;
      case 'psychic': return Colors.pink;
      case 'ice': return Colors.cyan;
      case 'dragon': return Colors.indigo;
      case 'dark': return Colors.brown;
      case 'fairy': return Colors.pinkAccent;
      case 'fighting': return Colors.red;
      case 'poison': return Colors.purple;
      case 'ground': return Colors.orange;
      case 'rock': return Colors.grey;
      case 'bug': return Colors.lightGreen;
      case 'ghost': return Colors.deepPurple;
      case 'steel': return Colors.blueGrey;
      case 'flying': return Colors.lightBlue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final pokemon = gameProvider.availablePokemon;
        final currentPlayer = gameProvider.currentPlayer;

        // Navigate to TeamScreen when team has been assigned
        if (currentPlayer != null && currentPlayer.team.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const TeamScreen()),
              );
            }
          });
        }

        // Reset confirming state if server returned an error
        if (_confirming && gameProvider.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _confirming = false);
          });
        }

        final availableTypes = _getAvailableTypes(pokemon);
        final filteredPokemon = _filterPokemon(pokemon);

        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          appBar: AppBar(
            backgroundColor: AppColors.pokemonRed,
            elevation: 0,
            title: Text(
              'Elige tu Equipo  ${_selectedIds.length}/3',
              style: GoogleFonts.bangers(
                color: AppColors.pokemonYellow,
                fontSize: 22,
                letterSpacing: 1,
              ),
            ),
            centerTitle: true,
          ),
          body: pokemon.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.pokemonYellow),
                      SizedBox(height: 16),
                      Text(
                        'Cargando Pokémon...',
                        style: TextStyle(color: AppColors.lightGray),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Type filter chips
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: availableTypes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final type = availableTypes[index];
                          final isSelected = _selectedType == type;
                          return FilterChip(
                            label: Text(
                              type,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.lightGray,
                                fontSize: 12,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedType = type),
                            backgroundColor: AppColors.darkGray,
                            selectedColor: AppColors.pokemonRed,
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? AppColors.pokemonRed : Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),

                    // Pokemon grid
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredPokemon.length,
                        itemBuilder: (context, index) {
                          final p = filteredPokemon[index];
                          final id = p['pokemonId'] as int? ?? 0;
                          final name = p['name'] as String? ?? '';
                          final types = (p['type'] as List?)
                                  ?.map((t) => _capitalize(t.toString()))
                                  .toList() ??
                              [];
                          final sprite = p['sprite'] as String? ?? '';
                          final isSelected = _selectedIds.contains(id);
                          final canSelect = _selectedIds.length < 3 || isSelected;

                          final primaryTypeColor = types.isNotEmpty
                              ? _typeColor(types[0])
                              : AppColors.darkGray;
                          final darkPrimary = HSLColor.fromColor(primaryTypeColor)
                              .withLightness(
                                (HSLColor.fromColor(primaryTypeColor).lightness - 0.22)
                                    .clamp(0.0, 1.0))
                              .toColor();

                          return GestureDetector(
                            onTap: canSelect ? () => _toggleSelection(id) : null,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.pokemonYellow
                                      : primaryTypeColor.withOpacity(0.5),
                                  width: isSelected ? 3 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? AppColors.pokemonYellow.withOpacity(0.4)
                                        : primaryTypeColor.withOpacity(0.2),
                                    blurRadius: isSelected ? 12 : 6,
                                    spreadRadius: isSelected ? 2 : 0,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Column(
                                  children: [
                                    // Type gradient header with sprite
                                    Expanded(
                                      flex: 6,
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              primaryTypeColor.withOpacity(0.85),
                                              darkPrimary
                                            ],
                                          ),
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Pokeball watermark
                                            Positioned(
                                              right: -8,
                                              bottom: -8,
                                              child: Opacity(
                                                opacity: 0.12,
                                                child: const Icon(
                                                  Icons.catching_pokemon,
                                                  size: 60,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            sprite.isNotEmpty
                                                ? Image.network(
                                                    sprite,
                                                    height: 75,
                                                    width: 75,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (_, __, ___) =>
                                                        Icon(
                                                      Icons.catching_pokemon,
                                                      color: Colors.white
                                                          .withOpacity(0.7),
                                                      size: 55,
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.catching_pokemon,
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                    size: 55,
                                                  ),
                                            if (isSelected)
                                              Positioned(
                                                top: 6,
                                                right: 6,
                                                child: Container(
                                                  width: 22,
                                                  height: 22,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppColors.pokemonYellow,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.3),
                                                        blurRadius: 4,
                                                      )
                                                    ],
                                                  ),
                                                  child: const Icon(Icons.check,
                                                      color: Colors.black,
                                                      size: 14),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Dark info section
                                    Expanded(
                                      flex: 4,
                                      child: Container(
                                        color: const Color(0xFF1a1a2e),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 6),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              name.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                                letterSpacing: 0.3,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 3,
                                              children: types
                                                  .map(
                                                    (t) => Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 5,
                                                          vertical: 1),
                                                      decoration: BoxDecoration(
                                                        color: _typeColor(t),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Text(
                                                        t.toUpperCase(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Error message
                    if (gameProvider.errorMessage != null && !_confirming) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF330000),
                            border: Border.all(color: AppColors.hpCritical, width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.hpCritical, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  gameProvider.errorMessage!,
                                  style: const TextStyle(color: AppColors.hpCritical, fontSize: 12),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => gameProvider.clearError(),
                                child: const Icon(Icons.close, color: AppColors.hpCritical, size: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Confirm button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (_selectedIds.length == 3 && !_confirming)
                              ? () {
                                  setState(() => _confirming = true);
                                  gameProvider.clearError();
                                  gameProvider.selectTeam(_selectedIds);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.hpHealthy,
                            disabledBackgroundColor: const Color(0xFF336633),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _confirming
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  _selectedIds.length == 3
                                      ? '✓ Confirmar Equipo'
                                      : 'Selecciona ${3 - _selectedIds.length} más',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
