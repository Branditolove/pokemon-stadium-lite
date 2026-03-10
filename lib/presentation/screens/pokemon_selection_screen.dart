import 'package:flutter/material.dart';
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
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const TeamScreen()),
            );
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
              'Elige tu Equipo (${_selectedIds.length}/3)',
              style: const TextStyle(
                color: AppColors.pokemonYellow,
                fontWeight: FontWeight.bold,
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
                          childAspectRatio: 0.85,
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

                          return GestureDetector(
                            onTap: canSelect ? () => _toggleSelection(id) : null,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.darkGray,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.pokemonYellow
                                      : canSelect
                                          ? AppColors.pokemonRed
                                          : Colors.grey.shade800,
                                  width: isSelected ? 3 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isSelected)
                                    const Align(
                                      alignment: Alignment.topRight,
                                      child: Padding(
                                        padding: EdgeInsets.only(right: 8, top: 8),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: AppColors.pokemonYellow,
                                          size: 20,
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 28),
                                  sprite.isNotEmpty
                                      ? Image.network(
                                          sprite,
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.catching_pokemon,
                                            color: AppColors.pokemonYellow,
                                            size: 60,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.catching_pokemon,
                                          color: AppColors.pokemonYellow,
                                          size: 60,
                                        ),
                                  const SizedBox(height: 8),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 4,
                                    children: types
                                        .map((t) => Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _typeColor(t),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                t,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Confirm button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _selectedIds.length == 3
                              ? () => gameProvider.selectTeam(_selectedIds)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.hpHealthy,
                            disabledBackgroundColor: const Color(0xFF336633),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
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
