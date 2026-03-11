# Pokémon Stadium Lite - Backend

Backend en Node.js para la aplicación "Pokémon Stadium Lite", un juego multiplayer de batallas de Pokémon en tiempo real usando WebSockets.

## Stack Técnico

- **Node.js 18+**
- **Express.js** - Framework web
- **Socket.IO** - WebSockets en tiempo real
- **Mongoose** - ODM para MongoDB
- **Axios** - Cliente HTTP
- **Clean Architecture** - Estructura de código organizada

## Instalación

### Requisitos Previos

- Node.js 18 o superior
- MongoDB 4.0 o superior
- npm o yarn

### Pasos de Instalación

1. **Clonar el repositorio**

```bash
git clone <repo-url>
cd pokemon-stadium-lite/backend
```

2. **Instalar dependencias**

```bash
npm install
```

3. **Crear archivo `.env`**

```bash
cp .env.example .env
```

4. **Configurar variables de entorno**

Editar `.env` con tu configuración:

```
MONGODB_URI=mongodb://localhost:27017/pokemon_stadium
PORT=8080
HOST=0.0.0.0
POKEMON_API_URL=https://pokemon-api-92034153384.us-central1.run.app
```

## Ejecutar el Servidor

### Modo Producción

```bash
npm start
```

### Modo Desarrollo (con nodemon)

```bash
npm run dev
```

El servidor escuchará en `http://0.0.0.0:8080`

## Estructura del Proyecto

```
backend/
├── src/
│   ├── domain/                 # Lógica de negocio pura
│   │   ├── entities/          # Entidades del dominio
│   │   │   ├── Player.js
│   │   │   ├── Lobby.js
│   │   │   ├── Battle.js
│   │   │   └── PokemonState.js
│   │   └── repositories/      # Interfaces de repositorios
│   │       ├── IPlayerRepository.js
│   │       ├── ILobbyRepository.js
│   │       └── IBattleRepository.js
│   ├── application/            # Casos de uso y servicios
│   │   ├── usecases/          # Casos de uso
│   │   │   ├── JoinLobbyUseCase.js
│   │   │   ├── AssignPokemonUseCase.js
│   │   │   ├── ReadyUseCase.js
│   │   │   └── AttackUseCase.js
│   │   └── services/          # Servicios de aplicación
│   │       └── BattleService.js
│   ├── infrastructure/         # Implementaciones concretas
│   │   ├── database/          # Conexión y modelos
│   │   │   ├── connection.js
│   │   │   └── models/
│   │   │       ├── PlayerModel.js
│   │   │       ├── LobbyModel.js
│   │   │       └── BattleModel.js
│   │   ├── repositories/      # Implementaciones de repositorios
│   │   │   ├── MongoPlayerRepository.js
│   │   │   ├── MongoLobbyRepository.js
│   │   │   └── MongoBattleRepository.js
│   │   └── http/              # Rutas HTTP
│   │       └── routes/
│   │           └── healthRoutes.js
│   ├── interfaces/             # Interfaces externas
│   │   └── socket/            # Manejadores de Socket.IO
│   │       ├── SocketHandler.js
│   │       └── events.js
│   └── app.js                 # Configuración principal
├── server.js                  # Entry point
├── package.json
├── .env.example
└── README.md
```

## Arquitectura

La aplicación sigue **Clean Architecture** con separación clara entre:

- **Domain**: Entidades y reglas de negocio (sin dependencias externas)
- **Application**: Casos de uso y lógica de aplicación
- **Infrastructure**: Implementaciones concretas (BD, APIs externas)
- **Interfaces**: Controladores y adaptadores (HTTP, Socket.IO)

## API Endpoints

### Health Check

```
GET /health
```

**Respuesta:**
```json
{
  "status": "ok",
  "message": "Pokemon Stadium Lite backend is running",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## WebSocket Events

### Eventos del Cliente → Servidor

#### `join_lobby`
El jugador se une al lobby global.

**Payload:**
```json
{
  "nickname": "string"
}
```

#### `assign_pokemon`
El servidor asigna 3 Pokémon aleatorios al jugador.

**Payload:** Vacío

#### `ready`
El jugador confirma su equipo y está listo para la batalla.

**Payload:** Vacío

#### `attack`
El jugador realiza un ataque (solo válido si es su turno).

**Payload:**
```json
{
  "moveName": "string"
}
```

### Eventos del Servidor → Cliente

#### `lobby_status`
Estado actual del lobby (enviado a todos en la sala).

**Payload:**
```json
{
  "status": "waiting|ready|battling|finished",
  "players": [
    {
      "id": "string",
      "nickname": "string",
      "ready": boolean,
      "team": [
        {
          "pokemonId": number,
          "name": "string",
          "type": "string",
          "hp": number,
          "currentHp": number,
          "attack": number,
          "defense": number,
          "speed": number,
          "sprite": "string",
          "defeated": boolean
        }
      ],
      "isActive": boolean
    }
  ]
}
```

#### `battle_start`
La batalla ha comenzado.

**Payload:**
```json
{
  "currentTurn": "player_id",
  "teams": [
    {
      "playerId": "string",
      "nickname": "string",
      "team": [...]
    }
  ]
}
```

#### `turn_result`
Resultado de un ataque.

**Payload:**
```json
{
  "attacker": "player_id",
  "defender": "player_id",
  "damage": number,
  "defenderCurrentHp": number,
  "pokemonDefeated": boolean,
  "newPokemon": {
    "pokemonId": number,
    "name": "string",
    ...
  } | null,
  "nextTurn": "player_id"
}
```

#### `battle_end`
La batalla ha terminado.

**Payload:**
```json
{
  "winner": "player_id"
}
```

#### `error`
Hay un error en la operación.

**Payload:**
```json
{
  "message": "string"
}
```

## Reglas de Negocio

### Team Selection
- Cada jugador recibe 3 Pokémon aleatorios
- No se repiten Pokémon entre jugadores
- Los stats se obtienen de la API externa

### Battle Flow
1. El turno comienza con el jugador cuyo Pokémon tiene mayor Speed
2. Los turnos son secuenciales y atómicos (sin race conditions)
3. **Daño**: `max(5, floor(attacker.attack × move.power / (2 × defender.defense)))`
4. Si HP ≤ 0, el Pokémon es derrotado
5. Si hay Pokémon disponible, entra automáticamente
6. Si no hay más Pokémon, fin de batalla

> **Nota sobre la fórmula de daño:** El spec base propone `Attack - Defense (mín. 1)`, sin
> embargo la API externa retorna stats reales con rangos amplios (ej. Attack 49–134,
> Defense 49–230), lo que genera daño constante de 1 cuando Defense ≥ Attack.
> Para lograr batallas balanceadas y dinámicas, la fórmula fue extendida para incluir
> el poder del movimiento (`move.power`), replicando la mecánica real de Pokémon.

### Lobby States
- **waiting**: Esperando 2 jugadores
- **ready**: Ambos jugadores marcados como ready
- **battling**: Batalla en progreso
- **finished**: Hay un ganador

## API Externa de Pokémon

Se utiliza la siguiente API para obtener datos de Pokémon:

```
GET https://pokemon-api-92034153384.us-central1.run.app/list
```

Retorna lista de Pokémon: `[{id, name}, ...]`

```
GET https://pokemon-api-92034153384.us-central1.run.app/list/:id
```

Retorna detalles: `{id, name, type, hp, attack, defense, speed, sprite}`

## Modelos MongoDB

### Player
```javascript
{
  nickname: String,
  socketId: String,
  lobbyId: ObjectId,
  team: [{
    pokemonId: Number,
    name: String,
    type: String,
    hp: Number,
    currentHp: Number,
    attack: Number,
    defense: Number,
    speed: Number,
    sprite: String,
    defeated: Boolean
  }],
  ready: Boolean,
  isActive: Boolean,
  createdAt: Date
}
```

### Lobby
```javascript
{
  status: String (waiting/ready/battling/finished),
  players: [ObjectId],
  currentTurn: ObjectId,
  winner: ObjectId,
  createdAt: Date
}
```

### Battle
```javascript
{
  lobbyId: ObjectId,
  turns: [{
    attacker: ObjectId,
    defender: ObjectId,
    damage: Number,
    timestamp: Date
  }],
  winner: ObjectId,
  startedAt: Date,
  endedAt: Date
}
```

## Manejo de Errores

El servidor implementa manejo centralizado de errores:

- **Socket.IO errors**: Se emite evento `error` al cliente
- **Express errors**: Middleware de error global
- **MongoDB errors**: Se registran en logs

## Consideraciones de Producción

1. **Bases de datos**: Usar MongoDB Atlas o instancia dedicada
2. **Variables de entorno**: Nunca commitear `.env`, usar variables de entorno del servidor
3. **CORS**: Configurado para aceptar todas las orígenes (cambiar en producción)
4. **SSL/TLS**: Configurar en reverse proxy (nginx, Apache)
5. **Rate limiting**: Implementar según necesidad
6. **Logging**: Usar Winston o similar para logs estructurados

## Testing

Para testing manual con Socket.IO:

```javascript
const io = require('socket.io-client');

const socket = io('http://localhost:8080');

socket.on('connect', () => {
  console.log('Connected');
  socket.emit('join_lobby', { nickname: 'Player1' });
});

socket.on('lobby_status', (data) => {
  console.log('Lobby status:', data);
});

socket.on('error', (error) => {
  console.error('Error:', error);
});
```

## Troubleshooting

### MongoDB connection error
- Verificar que MongoDB esté corriendo
- Verificar `MONGODB_URI` en `.env`

### Port already in use
- Cambiar `PORT` en `.env`
- Encontrar proceso: `lsof -i :8080` (macOS/Linux)

### Socket.IO connection issues
- Verificar CORS configuration
- Probar con diferentes transports (websocket, polling)

## Contribución

1. Crear rama feature: `git checkout -b feature/nombre`
2. Commit cambios: `git commit -m 'Descripción'`
3. Push rama: `git push origin feature/nombre`
4. Crear Pull Request

## Licencia

MIT

## Contacto

Pokemon Stadium Lite Team
