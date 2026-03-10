# Pokémon Stadium Lite Backend - Índice de Archivos

Guía rápida para navegación y referencia de todos los archivos del proyecto.

## Documentación (Lee primero)

| Archivo | Descripción |
|---------|-------------|
| [README.md](README.md) | Documentación principal, instalación y uso |
| [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) | Resumen ejecutivo del proyecto |
| [VERIFICATION.md](VERIFICATION.md) | Verificación técnica y checklist |
| [CLIENT_EXAMPLE.md](CLIENT_EXAMPLE.md) | Ejemplos de cliente en JavaScript y Dart |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Guías de despliegue en múltiples plataformas |

## Configuración

| Archivo | Descripción |
|---------|-------------|
| [package.json](package.json) | Dependencias y scripts NPM |
| [.env.example](.env.example) | Variables de entorno de ejemplo |
| [Dockerfile](Dockerfile) | Contenedorización Docker |
| [docker-compose.yml](docker-compose.yml) | Stack Docker con MongoDB |
| [.dockerignore](.dockerignore) | Archivos ignorados en Docker |

## Código Fuente

### Entry Point

| Archivo | Ruta | Descripción |
|---------|------|-------------|
| [server.js](server.js) | `/` | Punto de entrada de la aplicación |
| [app.js](src/app.js) | `/src/` | Configuración principal Express + Socket.IO |

### Domain Layer

#### Entidades

| Archivo | Ruta | Descripción |
|---------|------|-------------|
| [Player.js](src/domain/entities/Player.js) | `/src/domain/entities/` | Entidad de jugador con equipo |
| [Lobby.js](src/domain/entities/Lobby.js) | `/src/domain/entities/` | Entidad de lobby global |
| [Battle.js](src/domain/entities/Battle.js) | `/src/domain/entities/` | Entidad de batalla |
| [PokemonState.js](src/domain/entities/PokemonState.js) | `/src/domain/entities/` | Entidad de estado de pokémon |

#### Repositorios (Interfaces)

| Archivo | Ruta | Descripción |
|---------|------|-------------|
| [IPlayerRepository.js](src/domain/repositories/IPlayerRepository.js) | `/src/domain/repositories/` | Interfaz para persistencia de jugador |
| [ILobbyRepository.js](src/domain/repositories/ILobbyRepository.js) | `/src/domain/repositories/` | Interfaz para persistencia de lobby |
| [IBattleRepository.js](src/domain/repositories/IBattleRepository.js) | `/src/domain/repositories/` | Interfaz para persistencia de batalla |

### Application Layer

#### Casos de Uso

| Archivo | Ruta | Descripción |
|---------|------|-------------|
| [JoinLobbyUseCase.js](src/application/usecases/JoinLobbyUseCase.js) | `/src/application/usecases/` | Unir jugador a lobby |
| [AssignPokemonUseCase.js](src/application/usecases/AssignPokemonUseCase.js) | `/src/application/usecases/` | Asignar 3 pokémon aleatorios |
| [ReadyUseCase.js](src/application/usecases/ReadyUseCase.js) | `/src/application/usecases/` | Marcar jugador como ready |
| [AttackUseCase.js](src/application/usecases/AttackUseCase.js) | `/src/application/usecases/` | Ejecutar ataque en batalla |

#### Servicios

| Archivo | Ruta | Descripción |
|---------|------|-------------|
| [BattleService.js](src/application/services/BattleService.js) | `/src/application/services/` | Servicio de gestión de batallas |

### Infrastructure Layer

#### Base de Datos

| Archivo | Ruta | Descripción |
|---------|------|-------------|
| [connection.js](src/infrastructure/database/connection.js) | `/src/infrastructure/database/` | Conexión a MongoDB |

#### Modelos MongoDB

| Archivo | Ruta | Descripción |
|---------|------|-------------|
| [PlayerModel.js](src/infrastructure/database/models/PlayerModel.js) | `/src/infrastructure/database/models/` | Esquema Mongoose para jugador |
| [LobbyModel.js](src/infrastructure/database/models/LobbyModel.js) | `/src/infrastructure/database/models/` | Esquema Mongoose para lobby |
| [BattleModel.js](src/infrastructure/database/models/BattleModel.js) | `/src/infrastructure/database/models/` | Esquema Mongoose para batalla |

#### Implementaciones de Repositorios

| Archivo | Ruta | Descripción |
|---------|------|-------------|
| [MongoPlayerRepository.js](src/infrastructure/repositories/MongoPlayerRepository.js) | `/src/infrastructure/repositories/` | Implementación de persistencia de jugador |
| [MongoLobbyRepository.js](src/infrastructure/repositories/MongoLobbyRepository.js) | `/src/infrastructure/repositories/` | Implementación de persistencia de lobby |
| [MongoBattleRepository.js](src/infrastructure/repositories/MongoBattleRepository.js) | `/src/infrastructure/repositories/` | Implementación de persistencia de batalla |

#### Rutas HTTP

| Archivo | Ruta | Descripción |
|---------|------|-------------|
| [healthRoutes.js](src/infrastructure/http/routes/healthRoutes.js) | `/src/infrastructure/http/routes/` | Rutas de health check |

### Interfaces Layer

#### Socket.IO

| Archivo | Ruta | Descripción |
|---------|------|-------------|
| [events.js](src/interfaces/socket/events.js) | `/src/interfaces/socket/` | Definición de eventos Socket.IO |
| [SocketHandler.js](src/interfaces/socket/SocketHandler.js) | `/src/interfaces/socket/` | Manejador principal de eventos Socket.IO |

## Diagrama de Dependencias

```
server.js (Entry Point)
    └── src/app.js
        ├── Express + Socket.IO Setup
        ├── src/interfaces/socket/SocketHandler.js
        │   ├── src/application/usecases/
        │   │   ├── JoinLobbyUseCase.js
        │   │   ├── AssignPokemonUseCase.js
        │   │   ├── ReadyUseCase.js
        │   │   └── AttackUseCase.js
        │   └── src/application/services/BattleService.js
        │       └── src/infrastructure/repositories/
        │           ├── MongoPlayerRepository.js
        │           ├── MongoLobbyRepository.js
        │           └── MongoBattleRepository.js
        ├── src/infrastructure/database/connection.js
        └── src/infrastructure/http/routes/healthRoutes.js

Repositorios
    └── src/infrastructure/repositories/
        ├── MongoPlayerRepository.js
        ├── MongoLobbyRepository.js
        └── MongoBattleRepository.js
            ├── src/domain/repositories/ (Interfaces)
            │   ├── IPlayerRepository.js
            │   ├── ILobbyRepository.js
            │   └── IBattleRepository.js
            └── src/infrastructure/database/models/
                ├── PlayerModel.js
                ├── LobbyModel.js
                └── BattleModel.js

Entidades del Dominio
    └── src/domain/entities/
        ├── Player.js
        ├── Lobby.js
        ├── Battle.js
        └── PokemonState.js
```

## Rutas de Lectura Recomendada

### Para Principiantes
1. [README.md](README.md) - Descripción general
2. [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Resumen de características
3. [CLIENT_EXAMPLE.md](CLIENT_EXAMPLE.md) - Cómo usar desde el cliente

### Para Desarrolladores Backend
1. [README.md](README.md) - Instalación
2. [src/app.js](src/app.js) - Punto de entrada
3. [src/interfaces/socket/SocketHandler.js](src/interfaces/socket/SocketHandler.js) - Lógica principal
4. [src/application/usecases/](src/application/usecases/) - Casos de uso

### Para Arquitectos
1. [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Visión general
2. [VERIFICATION.md](VERIFICATION.md) - Checklist técnico
3. [src/domain/](src/domain/) - Lógica de negocio
4. [DEPLOYMENT.md](DEPLOYMENT.md) - Despliegue

### Para DevOps/SRE
1. [DEPLOYMENT.md](DEPLOYMENT.md) - Múltiples plataformas
2. [Dockerfile](Dockerfile) - Contenedorización
3. [docker-compose.yml](docker-compose.yml) - Stack local
4. [.env.example](.env.example) - Variables de configuración

## Búsqueda Rápida por Funcionalidad

### Autenticación y Usuarios
- [JoinLobbyUseCase.js](src/application/usecases/JoinLobbyUseCase.js) - Unir usuario
- [MongoPlayerRepository.js](src/infrastructure/repositories/MongoPlayerRepository.js) - Gestión BD

### Equipos de Pokémon
- [AssignPokemonUseCase.js](src/application/usecases/AssignPokemonUseCase.js) - Asignación
- [src/domain/entities/PokemonState.js](src/domain/entities/PokemonState.js) - Estado

### Batalla
- [AttackUseCase.js](src/application/usecases/AttackUseCase.js) - Lógica de ataque
- [BattleService.js](src/application/services/BattleService.js) - Servicio
- [BattleModel.js](src/infrastructure/database/models/BattleModel.js) - Persistencia

### WebSocket Real-Time
- [SocketHandler.js](src/interfaces/socket/SocketHandler.js) - Manejador principal
- [events.js](src/interfaces/socket/events.js) - Definición de eventos

### Base de Datos
- [connection.js](src/infrastructure/database/connection.js) - Conexión
- [src/infrastructure/database/models/](src/infrastructure/database/models/) - Esquemas

### HTTP API
- [healthRoutes.js](src/infrastructure/http/routes/healthRoutes.js) - Health check

## Estadísticas del Proyecto

- **Total Archivos**: 34
- **Archivos JavaScript**: 23
- **Documentación**: 5 archivos
- **Líneas de Código**: ~1,942 (solo src/)
- **Tamaño Total**: 152 KB

## Cómo Comenzar

### 1. Instalación
```bash
npm install
cp .env.example .env
```

### 2. Ejecución Local
```bash
npm run dev
```

### 3. Ejecución con Docker
```bash
docker-compose up -d
```

### 4. Verificación
```bash
curl http://localhost:8080/health
```

## Útiles

- [Ejemplos de Cliente](CLIENT_EXAMPLE.md) - Código de prueba
- [Guía de Despliegue](DEPLOYMENT.md) - Diferentes entornos
- [Verificación](VERIFICATION.md) - Checklist técnico

---

**Última actualización**: 2024-03-06
**Versión**: 1.0.0
