export const CLUB_NAMES = [
  "Real Corvia", "Athletic Novara", "Steel City FC", "Port Union",
  "Northgate Rangers", "Vale Rovers", "Iron Bridge FC", "Sunhaven United",
  "Grantham Athletic", "Bellmouth City", "Kestrel Rovers", "Harbor Town FC",
];

const FIRST_NAMES = [
  "Marco", "Luca", "Diego", "Kevin", "Mateo", "Bruno", "Tomas", "Aldo",
  "Erik", "Sven", "Nils", "Igor", "Pavel", "Dario", "Rafael", "Andres",
  "Youssef", "Karim", "Idris", "Malik", "Jamal", "Femi", "Kwame", "Amir",
  "Jonas", "Lukas", "Matteo", "Enzo", "Théo", "Hugo", "Milan", "Vlad",
  "Ryo", "Kenji", "Haruto", "Minho", "Jae", "Wei", "Chen", "Arjun",
];
const LAST_NAMES = [
  "Ferreira", "Santini", "Novak", "Keller", "Bianchi", "Moreau", "Costa",
  "Weiss", "Larsen", "Berg", "Kovac", "Petrov", "Silva", "Reyes", "Adeyemi",
  "Diallo", "Osei", "Haddad", "Rahman", "Suzuki", "Tanaka", "Park", "Kim",
  "Wong", "Patel", "Sharma", "Dubois", "Lefevre", "Marchetti", "Rossi",
  "Vidal", "Herrera", "Almeida", "Bakker", "Van Dijk", "Nowak", "Horvat",
];

let idCounter = 1;
export function nextId() {
  return `p${idCounter++}`;
}

export function randInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

export function pick(arr) {
  return arr[randInt(0, arr.length - 1)];
}

export function clamp(v, min, max) {
  return Math.max(min, Math.min(max, v));
}

function randomName() {
  return `${pick(FIRST_NAMES)} ${pick(LAST_NAMES)}`;
}

export function generatePlayer(position, baseOvr) {
  const ovr = clamp(baseOvr + randInt(-8, 8), 40, 94);
  const age = randInt(18, 34);
  const value = Math.round(
    Math.pow(Math.max(ovr - 40, 1), 2.6) * 120 * (age < 27 ? 1.3 : 0.75)
  );
  return {
    id: nextId(),
    name: randomName(),
    pos: position,
    age,
    ovr,
    value,
    goals: 0,
    apps: 0,
  };
}

const SQUAD_TEMPLATE = [
  ["GK", 3],
  ["DEF", 6],
  ["MID", 6],
  ["FWD", 5],
];

export function generateSquad(baseOvr) {
  const squad = [];
  for (const [pos, count] of SQUAD_TEMPLATE) {
    for (let i = 0; i < count; i++) {
      squad.push(generatePlayer(pos, baseOvr));
    }
  }
  return squad;
}

export function generateClub(name, isUserClub) {
  const baseOvr = isUserClub ? 68 : randInt(58, 80);
  return {
    id: name.toLowerCase().replace(/\s+/g, "-"),
    name,
    isUserClub: !!isUserClub,
    budget: isUserClub ? 15_000_000 : randInt(2_000_000, 20_000_000),
    players: generateSquad(baseOvr),
    formation: "4-4-2",
    lineup: [],
  };
}

export const FORMATIONS = {
  "4-4-2": { GK: 1, DEF: 4, MID: 4, FWD: 2 },
  "4-3-3": { GK: 1, DEF: 4, MID: 3, FWD: 3 },
  "3-5-2": { GK: 1, DEF: 3, MID: 5, FWD: 2 },
  "4-5-1": { GK: 1, DEF: 4, MID: 5, FWD: 1 },
  "3-4-3": { GK: 1, DEF: 3, MID: 4, FWD: 3 },
};

export function autoLineup(club) {
  const shape = FORMATIONS[club.formation];
  const byPos = { GK: [], DEF: [], MID: [], FWD: [] };
  for (const p of club.players) byPos[p.pos].push(p);
  for (const pos in byPos) byPos[pos].sort((a, b) => b.ovr - a.ovr);

  const lineup = [];
  for (const pos of ["GK", "DEF", "MID", "FWD"]) {
    const need = shape[pos];
    for (let i = 0; i < need && byPos[pos][i]; i++) {
      lineup.push(byPos[pos][i].id);
    }
  }
  return lineup;
}
