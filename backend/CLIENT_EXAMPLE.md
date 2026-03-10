# Pokémon Stadium Lite - Ejemplo de Cliente Socket.IO

Este documento proporciona ejemplos de cómo conectarse y usar el backend desde un cliente Socket.IO.

## Instalación del Cliente Socket.IO

Para Flutter (Dart):
```yaml
dependencies:
  socket_io_client: ^2.0.0
```

Para JavaScript/Node.js:
```bash
npm install socket.io-client
```

Para otros lenguajes, consultar: https://socket.io/docs/v4/client-installation/

## Ejemplo en JavaScript

```javascript
import io from 'socket.io-client';

// Conectar al servidor
const socket = io('http://localhost:8080', {
  reconnection: true,
  reconnectionDelay: 1000,
  reconnectionDelayMax: 5000,
  reconnectionAttempts: 5
});

// Evento: Conexión exitosa
socket.on('connect', () => {
  console.log('Connected to server');

  // Unirse al lobby
  socket.emit('join_lobby', { nickname: 'Player1' });
});

// Evento: Estado del lobby actualizado
socket.on('lobby_status', (data) => {
  console.log('Lobby status:', data);
  console.log('Players:', data.players);

  // Si ambos jugadores están listos, podemos marcar ready
  if (data.players.length === 2) {
    // Asignar pokémon
    socket.emit('assign_pokemon');
  }
});

// Evento: Pokémon asignados
socket.on('lobby_status', (data) => {
  if (data.players.every(p => p.team.length === 3)) {
    // Todos tienen equipo, marcar como ready
    socket.emit('ready');
  }
});

// Evento: Batalla iniciada
socket.on('battle_start', (data) => {
  console.log('Battle started!');
  console.log('Current turn:', data.currentTurn);
  console.log('Teams:', data.teams);

  // Esperar el turno para atacar
  if (isMyTurn(data.currentTurn)) {
    socket.emit('attack');
  }
});

// Evento: Resultado de turno
socket.on('turn_result', (data) => {
  console.log('Turn result:');
  console.log('- Attacker:', data.attacker);
  console.log('- Damage:', data.damage);
  console.log('- Defender HP:', data.defenderCurrentHp);
  console.log('- Pokemon defeated:', data.pokemonDefeated);
  console.log('- Next turn:', data.nextTurn);

  if (isMyTurn(data.nextTurn)) {
    socket.emit('attack');
  }
});

// Evento: Batalla finalizada
socket.on('battle_end', (data) => {
  console.log('Battle ended!');
  console.log('Winner:', data.winner);
});

// Evento: Error
socket.on('error', (error) => {
  console.error('Error:', error.message);
});

// Evento: Desconexión
socket.on('disconnect', () => {
  console.log('Disconnected from server');
});

function isMyTurn(turnPlayerId) {
  // Implementar lógica para verificar si es el turno del jugador actual
  return turnPlayerId === myPlayerId;
}
```

## Ejemplo en Dart (Flutter)

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class PokemonBattleService {
  late IO.Socket socket;

  void connect() {
    socket = IO.io('http://localhost:8080', <String, dynamic>{
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
      'reconnectionAttempts': 5,
      'transports': ['websocket', 'polling'],
    });

    // Conexión exitosa
    socket.onConnect((_) {
      print('Connected to server');
      joinLobby('PlayerDart');
    });

    // Escuchar estado del lobby
    socket.on('lobby_status', (data) {
      print('Lobby status: $data');
      handleLobbyStatus(data);
    });

    // Escuchar inicio de batalla
    socket.on('battle_start', (data) {
      print('Battle started: $data');
      handleBattleStart(data);
    });

    // Escuchar resultado de turno
    socket.on('turn_result', (data) {
      print('Turn result: $data');
      handleTurnResult(data);
    });

    // Escuchar fin de batalla
    socket.on('battle_end', (data) {
      print('Battle ended: $data');
      handleBattleEnd(data);
    });

    // Escuchar errores
    socket.on('error', (data) {
      print('Error: ${data['message']}');
    });

    // Desconexión
    socket.onDisconnect((_) {
      print('Disconnected from server');
    });
  }

  void joinLobby(String nickname) {
    socket.emit('join_lobby', {'nickname': nickname});
  }

  void assignPokemon() {
    socket.emit('assign_pokemon');
  }

  void ready() {
    socket.emit('ready');
  }

  void attack() {
    socket.emit('attack');
  }

  void handleLobbyStatus(dynamic data) {
    final status = data['status'];
    final players = List.from(data['players']);

    print('Status: $status, Players: ${players.length}');

    if (players.length == 2 && players.every((p) => p['team'].length == 0)) {
      assignPokemon();
    }

    if (players.length == 2 && players.every((p) => p['team'].length == 3)) {
      ready();
    }
  }

  void handleBattleStart(dynamic data) {
    final currentTurn = data['currentTurn'];
    print('Battle started! Current turn: $currentTurn');
  }

  void handleTurnResult(dynamic data) {
    final damage = data['damage'];
    final defenderHp = data['defenderCurrentHp'];
    final pokemonDefeated = data['pokemonDefeated'];
    final nextTurn = data['nextTurn'];

    print('Damage: $damage, Defender HP: $defenderHp, Next turn: $nextTurn');

    // El cliente debe verificar si es su turno antes de atacar
  }

  void handleBattleEnd(dynamic data) {
    final winner = data['winner'];
    print('Winner: $winner');
  }

  void disconnect() {
    socket.disconnect();
  }
}
```

## Flujo Típico de una Batalla

1. **Conexión**: Cliente se conecta al servidor
2. **Join Lobby**: Cliente envía `join_lobby` con su nickname
3. **Recibir estado**: Servidor emite `lobby_status` con el estado actual
4. **Asignar Pokémon**: Cuando hay 2 jugadores, cliente envía `assign_pokemon`
5. **Marcar Ready**: Después de asignar equipo, cliente envía `ready`
6. **Inicio de Batalla**: Cuando ambos están ready, servidor emite `battle_start`
7. **Ataques**:
   - Cliente espera evento `turn_result` o `battle_start` para saber su turno
   - Cuando es su turno, envía `attack`
   - Servidor responde con `turn_result`
8. **Fin de Batalla**: Servidor emite `battle_end` cuando hay ganador

## Consideraciones Importantes

### Turnos Atómicos
- Solo un jugador puede atacar a la vez
- El cliente debe esperar a recibir el evento que indica que es su turno
- NO debe enviar múltiples `attack` sin esperar respuesta

### Reconexión
- El cliente debe manejar desconexiones y reconexiones
- Si un jugador se desconecta durante la batalla, pierde automáticamente

### Estados Válidos
- **waiting**: Esperando más jugadores, no puedes atacar
- **ready**: Ambos listos, esperando que empiece batalla
- **battling**: Batalla en progreso, puedes atacar
- **finished**: Batalla terminada

## Estructura de Datos: Pokémon

```javascript
{
  pokemonId: Number,     // ID único del pokémon
  name: String,          // Nombre (e.g., "Bulbasaur")
  type: String,          // Tipo (e.g., "Grass")
  hp: Number,            // HP máximo
  currentHp: Number,     // HP actual en batalla
  attack: Number,        // Ataque
  defense: Number,       // Defensa
  speed: Number,         // Velocidad
  sprite: String,        // URL de la imagen
  defeated: Boolean      // ¿Está derrotado?
}
```

## Estructura de Datos: Jugador

```javascript
{
  id: String,            // ID único
  nickname: String,      // Nombre del jugador
  ready: Boolean,        // ¿Está listo?
  team: Array,           // Array de pokémon (máx 3)
  isActive: Boolean      // ¿Conectado?
}
```

## Testing Manual con curl y nc

Para probar la conexión HTTP:

```bash
curl http://localhost:8080/health
```

Respuesta esperada:
```json
{
  "status": "ok",
  "message": "Pokemon Stadium Lite backend is running",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## Debugging

### Habilitar logs en Socket.IO client (JavaScript)

```javascript
import { io } from 'socket.io-client';

const socket = io('http://localhost:8080', {
  reconnection: true,
  transports: ['websocket', 'polling']
});

socket.onAny((event, ...args) => {
  console.log(event, args);
});
```

### Habilitar logs en Socket.IO server (JavaScript)

```javascript
const io = new Server(httpServer, {
  cors: { origin: '*' }
});

io.engine.on("connection_error", (err) => {
  console.log(err.req);      // the request object
  console.log(err.code);     // the error code, e.g. 1
  console.log(err.message);  // the error message, e.g. "Session ID unknown"
  console.log(err.context);  // some additional error context
});
```

## Recursos

- [Socket.IO Client Documentation](https://socket.io/docs/v4/client-api/)
- [Socket.IO Server Documentation](https://socket.io/docs/v4/server-api/)
- [socket.io-client npm package](https://www.npmjs.com/package/socket.io-client)
- [socket_io_client Dart package](https://pub.dev/packages/socket_io_client)
