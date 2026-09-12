import { CLUB_NAMES, generateClub, generatePlayer, autoLineup, randInt, pick } from "./data.js";
import { simulateMatch } from "./engine.js";

const SAVE_KEY = "osm_clone_save_v1";
const NUM_CLUBS = 8;

function roundRobinFixtures(clubIds) {
  const ids = [...clubIds];
  if (ids.length % 2 !== 0) ids.push(null);
  const n = ids.length;
  const rounds = [];
  const half = n / 2;
  let arr = [...ids];

  for (let r = 0; r < n - 1; r++) {
    const round = [];
    for (let i = 0; i < half; i++) {
      const home = arr[i];
      const away = arr[n - 1 - i];
      if (home !== null && away !== null) {
        round.push(r % 2 === 0 ? [home, away] : [away, home]);
      }
    }
    rounds.push(round);
    arr = [arr[0], ...arr.slice(-1), ...arr.slice(1, -1)];
  }

  const secondLeg = rounds.map((round) => round.map(([h, a]) => [a, h]));
  return [...rounds, ...secondLeg];
}

export function newGame(userClubName) {
  const names = [...CLUB_NAMES].sort(() => Math.random() - 0.5).slice(0, NUM_CLUBS);
  if (!names.includes(userClubName)) names[0] = userClubName;

  const clubs = names.map((name) => generateClub(name, name === userClubName));
  for (const club of clubs) club.lineup = autoLineup(club);

  const fixtureRounds = roundRobinFixtures(clubs.map((c) => c.id));
  const fixtures = fixtureRounds.map((round, matchday) =>
    round.map(([home, away]) => ({
      matchday,
      home,
      away,
      played: false,
      homeGoals: null,
      awayGoals: null,
      events: [],
    }))
  );

  const state = {
    userClubId: clubs.find((c) => c.isUserClub).id,
    clubs,
    fixtures,
    matchday: 0,
    season: 1,
    transferPool: [],
    log: [],
  };
  refreshTransferPool(state);
  saveGame(state);
  return state;
}

export function refreshTransferPool(state) {
  const pool = [];
  const positions = ["GK", "DEF", "MID", "FWD"];
  for (let i = 0; i < 8; i++) {
    pool.push(generatePlayer(pick(positions), randInt(55, 85)));
  }
  state.transferPool = pool;
}

export function getClub(state, clubId) {
  return state.clubs.find((c) => c.id === clubId);
}

export function userClub(state) {
  return getClub(state, state.userClubId);
}

export function totalMatchdays(state) {
  return state.fixtures.length;
}

export function isSeasonOver(state) {
  return state.matchday >= state.fixtures.length;
}

export function playMatchday(state) {
  if (isSeasonOver(state)) return null;
  const round = state.fixtures[state.matchday];
  const reports = [];
  for (const fixture of round) {
    const home = getClub(state, fixture.home);
    const away = getClub(state, fixture.away);
    if (!home.lineup.length) home.lineup = autoLineup(home);
    if (!away.lineup.length) away.lineup = autoLineup(away);
    const result = simulateMatch(home, away);
    fixture.played = true;
    fixture.homeGoals = result.homeGoals;
    fixture.awayGoals = result.awayGoals;
    fixture.events = result.events;
    reports.push({ home: home.name, away: away.name, ...result });
  }
  state.matchday++;
  refreshTransferPool(state);
  saveGame(state);
  return reports;
}

export function computeStandings(state) {
  const table = {};
  for (const club of state.clubs) {
    table[club.id] = {
      id: club.id,
      name: club.name,
      played: 0,
      won: 0,
      drawn: 0,
      lost: 0,
      gf: 0,
      ga: 0,
      pts: 0,
    };
  }
  for (const round of state.fixtures) {
    for (const f of round) {
      if (!f.played) continue;
      const h = table[f.home];
      const a = table[f.away];
      h.played++;
      a.played++;
      h.gf += f.homeGoals;
      h.ga += f.awayGoals;
      a.gf += f.awayGoals;
      a.ga += f.homeGoals;
      if (f.homeGoals > f.awayGoals) {
        h.won++;
        a.lost++;
        h.pts += 3;
      } else if (f.homeGoals < f.awayGoals) {
        a.won++;
        h.lost++;
        a.pts += 3;
      } else {
        h.drawn++;
        a.drawn++;
        h.pts++;
        a.pts++;
      }
    }
  }
  return Object.values(table).sort(
    (a, b) => b.pts - a.pts || b.gf - b.ga - (a.gf - a.ga) || b.gf - a.gf
  );
}

export function buyPlayer(state, playerId) {
  const club = userClub(state);
  const idx = state.transferPool.findIndex((p) => p.id === playerId);
  if (idx === -1) return { ok: false, reason: "not-found" };
  const player = state.transferPool[idx];
  if (club.budget < player.value) return { ok: false, reason: "budget" };
  club.budget -= player.value;
  club.players.push(player);
  state.transferPool.splice(idx, 1);
  saveGame(state);
  return { ok: true };
}

export function sellPlayer(state, playerId) {
  const club = userClub(state);
  const idx = club.players.findIndex((p) => p.id === playerId);
  if (idx === -1) return { ok: false, reason: "not-found" };
  if (club.players.length <= 11) return { ok: false, reason: "too-few" };
  const [player] = club.players.splice(idx, 1);
  const fee = Math.round(player.value * 0.7);
  club.budget += fee;
  club.lineup = club.lineup.filter((id) => id !== player.id);
  saveGame(state);
  return { ok: true, fee };
}

export function setFormation(state, formation) {
  const club = userClub(state);
  club.formation = formation;
  club.lineup = autoLineup(club);
  saveGame(state);
}

export function setLineup(state, lineup) {
  const club = userClub(state);
  club.lineup = lineup;
  saveGame(state);
}

export function saveGame(state) {
  localStorage.setItem(SAVE_KEY, JSON.stringify(state));
}

export function loadGame() {
  const raw = localStorage.getItem(SAVE_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

export function clearGame() {
  localStorage.removeItem(SAVE_KEY);
}
