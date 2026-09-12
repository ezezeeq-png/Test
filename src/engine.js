import { clamp, randInt } from "./data.js";

function poisson(lambda) {
  const L = Math.exp(-lambda);
  let k = 0;
  let p = 1;
  do {
    k++;
    p *= Math.random();
  } while (p > L);
  return k - 1;
}

function teamStrength(club) {
  const lineup = club.lineup.length ? club.lineup : [];
  const players = lineup
    .map((id) => club.players.find((p) => p.id === id))
    .filter(Boolean);
  if (!players.length) return 50;
  return players.reduce((sum, p) => sum + p.ovr, 0) / players.length;
}

function weightedScorer(players) {
  const weights = players.map((p) => {
    if (p.pos === "FWD") return 5;
    if (p.pos === "MID") return 3;
    if (p.pos === "DEF") return 1;
    return 0.2;
  });
  const total = weights.reduce((a, b) => a + b, 0);
  let r = Math.random() * total;
  for (let i = 0; i < players.length; i++) {
    r -= weights[i];
    if (r <= 0) return players[i];
  }
  return players[players.length - 1];
}

export function simulateMatch(homeClub, awayClub) {
  const homeStrength = teamStrength(homeClub) + 3;
  const awayStrength = teamStrength(awayClub);
  const diff = homeStrength - awayStrength;

  const xgHome = clamp(1.35 + diff * 0.05, 0.15, 4.5);
  const xgAway = clamp(1.05 - diff * 0.05, 0.15, 4.5);

  const homeGoals = poisson(xgHome);
  const awayGoals = poisson(xgAway);

  const homePlayers = homeClub.lineup
    .map((id) => homeClub.players.find((p) => p.id === id))
    .filter(Boolean);
  const awayPlayers = awayClub.lineup
    .map((id) => awayClub.players.find((p) => p.id === id))
    .filter(Boolean);

  const events = [];
  for (let i = 0; i < homeGoals; i++) {
    const scorer = homePlayers.length ? weightedScorer(homePlayers) : null;
    events.push({
      minute: randInt(1, 90),
      side: "home",
      scorerId: scorer?.id ?? null,
      scorerName: scorer?.name ?? "Unknown",
    });
  }
  for (let i = 0; i < awayGoals; i++) {
    const scorer = awayPlayers.length ? weightedScorer(awayPlayers) : null;
    events.push({
      minute: randInt(1, 90),
      side: "away",
      scorerId: scorer?.id ?? null,
      scorerName: scorer?.name ?? "Unknown",
    });
  }
  events.sort((a, b) => a.minute - b.minute);

  for (const e of events) {
    const club = e.side === "home" ? homeClub : awayClub;
    const player = club.players.find((p) => p.id === e.scorerId);
    if (player) player.goals++;
  }
  for (const p of [...homePlayers, ...awayPlayers]) p.apps++;

  return { homeGoals, awayGoals, events };
}
