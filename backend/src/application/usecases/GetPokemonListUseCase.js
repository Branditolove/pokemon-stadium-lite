const axios = require('axios');

/**
 * GetPokemonListUseCase - Obtiene la lista de los 20 pokemon con sus tipos
 * Los resultados se cachean en memoria para evitar llamadas repetidas.
 */
class GetPokemonListUseCase {
  constructor() {
    this.pokemonApiUrl = process.env.POKEMON_API_URL || 'https://pokemon-api-92034153384.us-central1.run.app';
    this._cache = null;
  }

  async execute() {
    if (this._cache) {
      return this._cache;
    }

    const listResponse = await axios.get(`${this.pokemonApiUrl}/list`);
    const allPokemon = Array.isArray(listResponse.data)
      ? listResponse.data
      : (listResponse.data.data || []);

    // Fetch detail for each pokemon to get type info
    const details = await Promise.all(
      allPokemon.map(async (p) => {
        try {
          const res = await axios.get(`${this.pokemonApiUrl}/list/${p.id}`);
          const data = res.data.data ? res.data.data : res.data;
          return {
            pokemonId: data.id,
            name: data.name,
            type: data.type || [],
            sprite: data.sprite || data.sprites?.front_default || ''
          };
        } catch (e) {
          return {
            pokemonId: p.id,
            name: p.name,
            type: [],
            sprite: ''
          };
        }
      })
    );

    this._cache = details;
    return details;
  }
}

module.exports = GetPokemonListUseCase;
