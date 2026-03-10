# Pokémon Stadium Lite - Flutter Frontend

## Descripción General

Frontend completo para la aplicación "Pokémon Stadium Lite" desarrollado en Flutter. La aplicación permite a dos jugadores conectarse a través de un servidor backend Socket.IO, seleccionar sus equipos de Pokémon y batallar en tiempo real.

## Estructura de Archivos

```
lib/
├── main.dart                           # Punto de entrada de la aplicación
│
├── core/
│   ├── constants/
│   │   └── app_colors.dart            # Colores y temas de la aplicación
│   │
│   └── services/
│       ├── socket_service.dart        # Servicio Socket.IO para comunicación en tiempo real
│       └── storage_service.dart       # Servicio para almacenar preferencias locales
│
├── data/
│   └── models/
│       ├── pokemon_model.dart         # Modelo de datos para un Pokémon
│       ├── player_model.dart          # Modelo de datos para un jugador
│       └── lobby_model.dart           # Modelo de datos para el estado del lobby
│
└── presentation/
    ├── providers/
    │   └── game_provider.dart         # Provider de estado global con ChangeNotifier
    │
    ├── screens/
    │   ├── url_config_screen.dart     # Pantalla 1: Configuración de URL del backend
    │   ├── lobby_screen.dart          # Pantalla 2: Ingreso al lobby
    │   ├── team_screen.dart           # Pantalla 3: Visualización del equipo
    │   └── battle_screen.dart         # Pantalla 4: Batalla en tiempo real
    │
    └── widgets/
        ├── pokemon_card.dart          # Widget para mostrar información de un Pokémon
        ├── hp_bar.dart                # Widget para mostrar barra de HP animada
        └── battle_log.dart            # Widget para mostrar el registro de batalla
```

## Dependencias

```yaml
socket_io_client: ^3.0.0      # Cliente Socket.IO para comunicación en tiempo real
shared_preferences: ^2.3.0    # Almacenamiento local de preferencias
http: ^1.2.0                  # Cliente HTTP
provider: ^6.1.2              # State management
```

## Pantallas Implementadas

### 1. URL Config Screen
- **Archivo**: `lib/presentation/screens/url_config_screen.dart`
- **Funcionalidad**:
  - Permite ingresar la URL base del servidor backend
  - Guarda la URL en `shared_preferences` para futuras conexiones
  - Valida que la URL tenga formato correcto (http:// o https://)
  - Intenta conectar al servidor antes de proceder
  - Muestra la última URL guardada
  - Fondo tema Pokémon (rojo/negro)

### 2. Lobby Screen
- **Archivo**: `lib/presentation/screens/lobby_screen.dart`
- **Funcionalidad**:
  - TextField para ingresar el nickname del entrenador
  - Botón "Unirse al Lobby" que emite evento `join_lobby`
  - Muestra estado actual del lobby: "Esperando jugadores" / "¡Lobby listo!"
  - Lista de jugadores conectados con sus nicknames y estado ready/waiting
  - Botón para cambiar URL del servidor
  - Auto-navega a TeamScreen cuando el lobby está listo

### 3. Team Screen
- **Archivo**: `lib/presentation/screens/team_screen.dart`
- **Funcionalidad**:
  - Muestra los 3 Pokémon asignados al jugador
  - Para cada Pokémon: sprite (GIF animado), nombre, tipo, stats (HP, ATK, DEF, SPD)
  - Botón "¡Listo para Batallar!" que emite evento `ready`
  - Muestra el estado del rival: "Rival listo ✓" / "Rival esperando..."
  - Auto-navega a BattleScreen cuando comienza la batalla
  - Diseño tipo carta Pokémon con bordes redondeados

### 4. Battle Screen
- **Archivo**: `lib/presentation/screens/battle_screen.dart`
- **Funcionalidad**:
  - Layout de batalla:
    - ARRIBA: Pokémon activo del rival (sprite grande, nombre, HP bar animada)
    - MEDIO: Log de batalla (últimos 5 mensajes)
    - ABAJO: Pokémon activo propio (sprite grande, nombre, HP bar animada)
    - BOTTOM: Botón "⚔️ ATACAR" (solo habilitado cuando es tu turno)
  - Indicador de turno con colores diferenciados
  - Botón ATACAR emite evento `attack`
  - Actualiza HP animadamente al recibir `turn_result`
  - Muestra diálogo de victoria/derrota al terminar la batalla
  - Animación de shake en el botón de ataque

## Modelos de Datos

### PokemonModel
```dart
class PokemonModel {
  final int id;                    // ID del Pokémon
  final String name;               // Nombre
  final List<String> type;         // Tipos (ej: ["water", "flying"])
  final int hp;                    // HP máximo
  int currentHp;                   // HP actual (mutable)
  final int attack;                // Estadística de Ataque
  final int defense;               // Estadística de Defensa
  final int speed;                 // Estadística de Velocidad
  final String sprite;             // URL del sprite animado
  bool defeated;                   // Si fue derrotado

  double get hpPercentage;         // Getter para el porcentaje de HP
}
```

### PlayerModel
```dart
class PlayerModel {
  final String nickname;                    // Nickname del jugador
  bool ready;                               // Si está listo para batallar
  List<PokemonModel> team;                  // Equipo de 3 Pokémon
  String? currentPokemonName;               // Nombre del Pokémon activo

  int get activePokemonIndex;               // Índice del Pokémon activo
  PokemonModel? get activePokemon;          // Pokémon activo actual
  bool get hasAlivePokemons;                // Si tiene Pokémon vivos
}
```

### LobbyModel
```dart
class LobbyModel {
  String status;                   // waiting, ready, battling, finished
  List<PlayerModel> players;       // Lista de jugadores
  String? currentTurn;             // Nickname del jugador con turno
  String? winner;                  // Nickname del ganador

  bool get isReady;                // Estado == 'ready'
  bool get isBattling;             // Estado == 'battling'
  bool get isFinished;             // Estado == 'finished'
  bool get isWaiting;              // Estado == 'waiting'
  bool get allPlayersReady;        // Todos los jugadores listos
}
```

## State Management (GameProvider)

### Archivo: `lib/presentation/providers/game_provider.dart`

GameProvider es un ChangeNotifier que:

#### Estado
- `_lobby`: Estado actual del lobby
- `_currentPlayer`: Jugador actual
- `_battleLog`: Registro de mensajes de batalla
- `_isMyTurn`: Si es el turno del jugador actual
- `_errorMessage`: Último mensaje de error
- `_isConnecting`: Si se está conectando

#### Métodos Públicos
- `connectToBackend(String url)`: Conecta al servidor backend
- `joinLobby(String nickname)`: Se une al lobby con un nickname
- `assignPokemon()`: Solicita la asignación de equipo
- `ready()`: Indica que está listo para batallar
- `attack()`: Realiza un ataque
- `clearBattleLog()`: Limpia el registro de batalla
- `clearError()`: Limpia el mensaje de error
- `disconnect()`: Desconecta del servidor

#### Listeners (Socket.IO)
- `lobby_status`: Actualiza el estado del lobby
- `battle_start`: Inicia la batalla
- `turn_result`: Procesa el resultado de un turno
- `battle_end`: Finaliza la batalla
- `error`: Maneja mensajes de error

## Servicios

### SocketService
- **Archivo**: `lib/core/services/socket_service.dart`
- Singleton que gestiona la conexión Socket.IO
- Métodos:
  - `connect(String baseUrl)`: Conecta al servidor
  - `emit(String event, [dynamic data])`: Emite eventos
  - `on(String event, Function callback)`: Escucha eventos
  - `off(String event)`: Deja de escuchar un evento
  - `disconnect()`: Desconecta del servidor

### StorageService
- **Archivo**: `lib/core/services/storage_service.dart`
- Gestiona el almacenamiento local con `shared_preferences`
- Métodos:
  - `saveBackendUrl(String url)`: Guarda la URL del backend
  - `getBackendUrl()`: Obtiene la URL guardada
  - `clearBackendUrl()`: Elimina la URL guardada

## Widgets Personalizados

### HPBar
- **Archivo**: `lib/presentation/widgets/hp_bar.dart`
- Barra de HP animada con cambio de color según el estado
- Colores:
  - Verde: >50% HP
  - Naranja: 25-50% HP
  - Rojo: <25% HP
- Animación suave de cambios de HP

### PokemonCard
- **Archivo**: `lib/presentation/widgets/pokemon_card.dart`
- Muestra información completa de un Pokémon
- Elementos:
  - Sprite (GIF animado)
  - Nombre
  - Tipos con colores específicos
  - Stats (HP, ATK, DEF, SPD)
  - Indicador de derrota

### BattleLog
- **Archivo**: `lib/presentation/widgets/battle_log.dart`
- Muestra los últimos 5 mensajes de la batalla
- Scroll automático al agregar nuevos mensajes
- Borde rojo Pokémon

## Temas y Colores

### Paleta de Colores
- **Pokémon Red**: #CC0000 (rojo oficial Pokémon)
- **Pokémon Yellow**: #FFCB05 (amarillo oficial)
- **Dark Background**: #121212 (fondo oscuro)
- **Dark Gray**: #2A2A2A
- **HP Healthy**: #4CAF50 (verde)
- **HP Warning**: #FFA500 (naranja)
- **HP Critical**: #FF0000 (rojo)

### Tipos de Pokémon
Se incluyen colores específicos para cada tipo de Pokémon (Normal, Fire, Water, Electric, etc.)

## Eventos Socket.IO

### Emitidos (Cliente → Servidor)
```
join_lobby → {'nickname': string}
assign_pokemon → (sin datos)
ready → (sin datos)
attack → (sin datos)
```

### Recibidos (Servidor → Cliente)
```
lobby_status → {status: string, players: [...]}
battle_start → {currentTurn: nickname, teams: {...}}
turn_result → {attacker, defender, damage, defenderCurrentHp, pokemonDefeated, newPokemon, nextTurn}
battle_end → {winner: nickname}
error → {message: string}
```

## Flujo de la Aplicación

1. **URL Config**: Usuario ingresa URL del servidor
2. **Lobby**: Usuario ingresa nickname y se une al lobby
3. **Team**: Usuario ve su equipo asignado y confirma estar listo
4. **Battle**: Batalla en tiempo real hasta que uno de los dos gane

## Características Principales

✓ Conexión en tiempo real con Socket.IO
✓ State management con Provider
✓ Almacenamiento local con SharedPreferences
✓ Animaciones suaves (HP, shake en ataque)
✓ Tema oscuro estilo Pokémon
✓ Manejo de errores con SnackBars
✓ UI responsiva y atractiva
✓ Colores específicos para tipos de Pokémon
✓ Navegación automática entre pantallas
✓ Sincronización en tiempo real de turnos y HP

## Cómo Ejecutar

1. Clonar el repositorio
2. `flutter pub get` - Descargar dependencias
3. Asegurarse que el backend está ejecutándose
4. `flutter run` - Ejecutar la aplicación
5. Ingresa la URL del backend (ej: http://192.168.1.100:8080)
6. Inicia el juego

## Notas Técnicas

- Todas las conexiones Socket.IO usan WebSocket
- La conexión se intenta automáticamente si hay URL guardada
- Los sprites de Pokémon se cargan desde URLs externas
- El HP se anima sobre 600ms con curva lineal
- Los mensajes de error se muestran como SnackBars durante 3 segundos
- La aplicación maneja desconexiones y errores de red gracefully
