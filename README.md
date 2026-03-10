# Pokémon Stadium Lite

Full-stack Pokémon battle app built with Flutter + Node.js + MongoDB.

## Architecture

- **Frontend**: Flutter (Android/iOS)
- **Backend**: Node.js + Express + Socket.IO
- **Database**: MongoDB
- **Real-time**: Socket.IO WebSockets
- **Pokémon Data**: External API (Cloud Run)

## Quick Start

### Prerequisites
- Node.js >= 18.0.0
- Flutter SDK (latest)
- MongoDB (local or cloud)

### 1. Start MongoDB

```bash
# If using local MongoDB
mongod --dbpath ./data/db
```

Or set up MongoDB Atlas cloud database and get connection string.

### 2. Start Backend

```bash
cd backend

# Copy environment template
cp .env.example .env

# Edit .env with your MongoDB URI
# MONGODB_URI=mongodb://localhost:27017/pokemon_stadium
# PORT=8080

# Install dependencies
npm install

# Start development server with auto-reload
npm run dev

# Or start production server
npm start
```

Backend runs at `http://0.0.0.0:8080`

### 3. Run Flutter App

```bash
cd ..  # Back to project root

# Get dependencies
flutter pub get

# Run on Android/iOS
flutter run

# Or specify device
flutter run -d chrome
```

### 4. On First Launch

1. Enter your local backend URL (e.g., `http://192.168.1.100:8080`)
2. Enter a nickname
3. Assign Pokémon team
4. Mark as ready
5. Wait for opponent
6. Battle starts when both players are ready

## Project Structure

```
pokemon_app/
├── lib/                              # Flutter frontend
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_colors.dart      # Color scheme
│   │   └── services/
│   │       ├── socket_service.dart  # Socket.IO client
│   │       └── storage_service.dart # Local preferences
│   ├── data/
│   │   └── models/
│   │       ├── pokemon_model.dart   # Pokémon data structure
│   │       ├── player_model.dart    # Player data structure
│   │       └── lobby_model.dart     # Lobby data structure
│   ├── presentation/
│   │   ├── providers/
│   │   │   └── game_provider.dart   # Game state management
│   │   ├── screens/
│   │   │   ├── url_config_screen.dart
│   │   │   ├── lobby_screen.dart
│   │   │   ├── team_screen.dart
│   │   │   └── battle_screen.dart
│   │   └── widgets/
│   │       ├── hp_bar.dart
│   │       ├── pokemon_card.dart
│   │       └── battle_log.dart
│   └── main.dart                    # Entry point
├── backend/                          # Node.js backend
│   ├── src/
│   │   ├── domain/
│   │   │   ├── entities/            # Business logic entities
│   │   │   │   ├── Battle.js
│   │   │   │   ├── Lobby.js
│   │   │   │   ├── Player.js
│   │   │   │   └── PokemonState.js
│   │   │   └── repositories/        # Repository interfaces
│   │   ├── application/
│   │   │   ├── usecases/            # Business logic
│   │   │   │   ├── JoinLobbyUseCase.js
│   │   │   │   ├── AssignPokemonUseCase.js
│   │   │   │   ├── ReadyUseCase.js
│   │   │   │   └── AttackUseCase.js
│   │   │   └── services/
│   │   │       └── BattleService.js
│   │   ├── infrastructure/
│   │   │   ├── database/
│   │   │   │   ├── connection.js    # MongoDB connection
│   │   │   │   └── models/          # Mongoose schemas
│   │   │   ├── repositories/        # Repository implementations
│   │   │   └── http/
│   │   │       └── routes/
│   │   │           └── healthRoutes.js
│   │   └── interfaces/
│   │       └── socket/              # Socket.IO handlers
│   │           ├── SocketHandler.js
│   │           └── events.js
│   ├── server.js                    # HTTP server entry
│   ├── app.js                       # Express + Socket.IO setup
│   └── package.json
├── pubspec.yaml                      # Flutter dependencies
└── README.md                         # This file
```

## Socket.IO Events

### Client → Server (Flutter emits, Backend listens)

| Event | Payload | Description |
|-------|---------|-------------|
| `join_lobby` | `{nickname: string}` | Join the game lobby |
| `assign_pokemon` | (none) | Request random Pokémon team |
| `ready` | (none) | Mark team ready to battle |
| `attack` | (none) | Execute attack on current turn |

### Server → Client (Backend emits, Flutter listens)

| Event | Payload | Description |
|-------|---------|-------------|
| `lobby_status` | `{status, players}` | Lobby state update |
| `battle_start` | `{currentTurn, teams}` | Battle started, send initial state |
| `turn_result` | `{attacker, defender, damage, defenderCurrentHp, pokemonDefeated, newPokemon, nextTurn}` | Attack result |
| `battle_end` | `{winner}` | Battle finished |
| `error` | `{message: string}` | Error occurred |

## Battle Rules

- Each player gets 3 random Pokémon (no duplicates between players)
- First turn determined by highest Speed stat
- Damage calculation: `max(1, attacker.attack - defender.defense)`
- When a Pokémon is defeated (HP = 0), next Pokémon automatically enters
- Battle ends when one player has no Pokémon left
- Disconnection during battle = automatic loss

## Environment Variables

### Backend (.env)

```env
MONGODB_URI=mongodb://localhost:27017/pokemon_stadium
PORT=8080
NODE_ENV=development
```

## Dependencies

### Flutter (pubspec.yaml)

- `flutter`: SDK
- `provider`: State management
- `socket_io_client`: ^3.0.0 - WebSocket client
- `shared_preferences`: ^2.3.0 - Local storage
- `http`: ^1.2.0 - HTTP requests
- `cupertino_icons`: ^1.0.8 - iOS icons

### Backend (package.json)

- `express`: ^4.18.2 - Web framework
- `socket.io`: ^4.6.1 - Real-time communication
- `mongoose`: ^7.5.0 - MongoDB driver
- `cors`: ^2.8.5 - CORS middleware
- `dotenv`: ^16.3.1 - Environment variables
- `axios`: ^1.5.0 - HTTP client
- `nodemon`: ^3.0.1 - Dev: Auto-reload

## Development

### Backend Development

```bash
cd backend
npm run dev  # Starts with nodemon
```

### Flutter Development

```bash
flutter pub get      # Get dependencies
flutter run         # Run app
flutter run -d web  # Run on web (debug)
```

### Debugging

**Flutter**: Enable debug prints in Socket events
- Check `lib/core/services/socket_service.dart`
- Check `lib/presentation/providers/game_provider.dart`

**Backend**: Check console logs from Node.js
- Socket connection logs
- Use cases execution logs
- Database queries

## Testing

### Manual Testing Checklist

- [ ] Backend starts without errors
- [ ] Flutter connects to backend URL
- [ ] Join lobby with nickname
- [ ] Assign Pokémon (team appears)
- [ ] Second player joins and assigns team
- [ ] Both players mark ready
- [ ] Battle starts with correct order
- [ ] Attack button works and shows damage
- [ ] HP bar updates correctly
- [ ] Pokémon switches when defeated
- [ ] Winner is announced correctly
- [ ] Can rejoin and play again

## Troubleshooting

### "Cannot connect to backend"
- Check backend is running: `http://localhost:8080/health`
- Verify correct IP address (not localhost, use actual IP if on different device)
- Check CORS is enabled in backend

### "Socket connection fails"
- Ensure WebSocket transport is enabled
- Check firewall isn't blocking port 8080
- Verify URL format: `http://IP:PORT` (not `https://`)

### "Pokemon data not loading"
- Check Pokémon API is accessible
- Verify MongoDB has Pokémon data
- Check network tab in browser DevTools

### "Battle doesn't start"
- Both players must have teams assigned
- Both players must mark ready
- Check for errors in console logs

## API Endpoints

### Health Check

```
GET /health
Response: { status: 'ok' }
```

## Performance Notes

- WebSocket connection reduces latency
- Atomic turn processing prevents race conditions
- MongoDB indexes on frequently queried fields
- Pokémon data cached after first fetch

## License

MIT

## Authors

Pokémon Stadium Lite Team

---

**Last Updated**: 2026-03-06
**Version**: 1.0.0
