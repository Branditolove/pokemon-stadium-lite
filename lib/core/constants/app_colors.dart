import 'package:flutter/material.dart';

class AppColors {
  // Pokémon Official Colors
  static const Color pokemonRed = Color(0xFFCC0000);
  static const Color pokemonYellow = Color(0xFFFFCB05);
  static const Color pokemonBlack = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkGray = Color(0xFF2A2A2A);
  static const Color lightGray = Color(0xFFE0E0E0);

  // HP Bar Colors
  static const Color hpHealthy = Color(0xFF4CAF50); // Green
  static const Color hpWarning = Color(0xFFFFA500); // Orange
  static const Color hpCritical = Color(0xFFFF0000); // Red

  // Type Colors (Pokémon types)
  static const Map<String, Color> typeColors = {
    'normal': Color(0xFFA8A878),
    'fire': Color(0xFFF08030),
    'water': Color(0xFF6890F0),
    'electric': Color(0xFFF8D030),
    'grass': Color(0xFF78C850),
    'ice': Color(0xFF98D8D8),
    'fighting': Color(0xFFC03028),
    'poison': Color(0xFFA040A0),
    'ground': Color(0xFFE0C068),
    'flying': Color(0xFFA890F0),
    'psychic': Color(0xFFF85888),
    'bug': Color(0xFFA8B820),
    'rock': Color(0xFFB8A038),
    'ghost': Color(0xFF705898),
    'dragon': Color(0xFF7038F8),
    'dark': Color(0xFF705848),
    'steel': Color(0xFFB8B8D0),
    'fairy': Color(0xFFEE99AC),
  };

  static Color getTypeColor(String type) {
    return typeColors[type.toLowerCase()] ?? Color(0xFFA8A878);
  }
}
