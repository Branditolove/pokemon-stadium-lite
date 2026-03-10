const PokemonState = require('../../domain/entities/PokemonState');
const axios = require('axios');

/**
 * AssignPokemonUseCase - Asigna Pokémon al equipo del jugador.
 * Si se pasan pokemonIds específicos, los usa; si no, selecciona 3 aleatorios.
 * Obtiene los 4 mejores movimientos de cada pokémon desde PokeAPI.
 */
class AssignPokemonUseCase {
  constructor(playerRepository, lobbyRepository) {
    this.playerRepository = playerRepository;
    this.lobbyRepository = lobbyRepository;
    this.pokemonApiUrl = process.env.POKEMON_API_URL || 'https://pokemon-api-92034153384.us-central1.run.app';
  }

  async execute(input) {
    const { playerId, lobbyId, pokemonIds } = input;

    if (!playerId || !lobbyId) {
      throw new Error('PlayerId and lobbyId are required');
    }

    const player = await this.playerRepository.findById(playerId);
    if (!player) throw new Error('Player not found');

    const lobby = await this.lobbyRepository.findById(lobbyId);
    if (!lobby) throw new Error('Lobby not found');

    let selectedIds;
    if (pokemonIds && pokemonIds.length === 3) {
      selectedIds = pokemonIds;
    } else {
      const availablePokemon = await this._getAvailablePokemon(lobby);
      selectedIds = this._selectRandomPokemon(availablePokemon, 3);
    }

    // Fetch stats + moves for each pokemon in parallel
    const team = await Promise.all(
      selectedIds.map(async (pokemonId) => {
        const [detail, moves] = await Promise.all([
          this._getPokemonDetail(pokemonId),
          this._getPokemonMoves(pokemonId)
        ]);
        return new PokemonState(
          detail.id,
          detail.name,
          detail.type,
          detail.hp,
          detail.attack,
          detail.defense,
          detail.speed,
          detail.sprite,
          moves
        );
      })
    );

    player.team = team;
    await this.playerRepository.update(player);

    return {
      player,
      pokemon: team.map(p => p.getCurrentState())
    };
  }

  async _getAvailablePokemon(lobby) {
    try {
      const response = await axios.get(`${this.pokemonApiUrl}/list`);
      const allPokemon = Array.isArray(response.data) ? response.data : (response.data.data || []);

      const assignedPokemonIds = new Set();
      for (const playerRef of lobby.players) {
        const fullPlayer = await this.playerRepository.findById(playerRef.id);
        if (fullPlayer && fullPlayer.team) {
          fullPlayer.team.forEach(pokemon => assignedPokemonIds.add(pokemon.pokemonId));
        }
      }

      return allPokemon.filter(p => !assignedPokemonIds.has(p.id));
    } catch (error) {
      console.error('Error getting available pokemon:', error);
      throw error;
    }
  }

  _selectRandomPokemon(availablePokemon, count) {
    if (availablePokemon.length < count) {
      throw new Error('Not enough available pokemon');
    }
    const selected = [];
    const indices = new Set();
    while (selected.length < count) {
      const randomIndex = Math.floor(Math.random() * availablePokemon.length);
      if (!indices.has(randomIndex)) {
        indices.add(randomIndex);
        selected.push(availablePokemon[randomIndex].id);
      }
    }
    return selected;
  }

  async _getPokemonDetail(pokemonId) {
    try {
      const response = await axios.get(`${this.pokemonApiUrl}/list/${pokemonId}`);
      return response.data.data ? response.data.data : response.data;
    } catch (error) {
      console.error(`Error getting pokemon detail for ID ${pokemonId}:`, error);
      throw error;
    }
  }

  /**
   * Obtiene los 4 mejores movimientos de un pokemon desde PokeAPI.
   * Filtra level-up moves, ordena por nivel descendente, toma los top 4,
   * luego fetch cada move para obtener power, type, pp.
   */
  async _getPokemonMoves(pokemonId) {
    try {
      const response = await axios.get(`https://pokeapi.co/api/v2/pokemon/${pokemonId}`);
      const pokemonData = response.data;

      // Filter level-up moves only
      const levelUpMoves = pokemonData.moves
        .map(m => {
          const levelDetail = m.version_group_details.find(
            d => d.move_learn_method.name === 'level-up'
          );
          return levelDetail ? { url: m.move.url, level: levelDetail.level_learned_at } : null;
        })
        .filter(Boolean)
        .sort((a, b) => b.level - a.level)
        .slice(0, 4);

      if (levelUpMoves.length === 0) {
        // Fallback: take first 4 moves
        const fallback = pokemonData.moves.slice(0, 4).map(m => ({ url: m.move.url, level: 0 }));
        levelUpMoves.push(...fallback);
      }

      // Fetch move details in parallel
      const moves = await Promise.all(
        levelUpMoves.map(async (m) => {
          try {
            const moveRes = await axios.get(m.url);
            const moveData = moveRes.data;
            return {
              name: moveData.name,
              power: moveData.power || 40,
              type: moveData.type.name,
              pp: moveData.pp || 10
            };
          } catch {
            return { name: 'tackle', power: 40, type: 'normal', pp: 35 };
          }
        })
      );

      return moves;
    } catch (error) {
      console.error(`Error getting moves for pokemon ${pokemonId}:`, error.message);
      // Return a default tackle move on error
      return [{ name: 'tackle', power: 40, type: 'normal', pp: 35 }];
    }
  }
}

module.exports = AssignPokemonUseCase;
