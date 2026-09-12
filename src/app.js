import { CLUB_NAMES, FORMATIONS } from "./data.js";
import {
  newGame,
  loadGame,
  saveGame,
  clearGame,
  userClub,
  getClub,
  computeStandings,
  playMatchday,
  isSeasonOver,
  totalMatchdays,
  buyPlayer,
  sellPlayer,
  setFormation,
  setLineup,
} from "./store.js";

const app = document.getElementById("app");

let state = loadGame();
let tab = "team";
let lastReports = null;
let toast = null;

const POS_LABEL = { GK: "GB", DEF: "DEF", MID: "MIL", FWD: "ATT" };
const money = (n) => `${Math.round(n).toLocaleString("fr-FR")} €`;

function render() {
  if (!state) {
    app.innerHTML = renderNewGame();
    return;
  }
  app.innerHTML = `
    <div class="screen">
      ${renderHeader()}
      <div class="content">${renderTab()}</div>
      ${toast ? `<div class="toast">${toast}</div>` : ""}
    </div>
    ${renderNav()}
  `;
}

function renderNewGame() {
  const clubs = CLUB_NAMES.map(
    (name) => `<button class="club-pick" data-action="new-game" data-name="${name}">${name}</button>`
  ).join("");
  return `
    <div class="onboarding">
      <h1>⚽ Prime League Manager</h1>
      <p>Choisis ton club et prends les commandes de ton équipe : effectif, tactique, transferts et simulation de matchs, comme dans un vrai jeu de manager de foot mobile.</p>
      <div class="club-grid">${clubs}</div>
    </div>
  `;
}

function renderHeader() {
  const club = userClub(state);
  return `
    <header class="topbar">
      <div class="club-id">
        <strong>${club.name}</strong>
        <span>${money(club.budget)}</span>
      </div>
      <div class="season-id">
        <span>Saison ${state.season}</span>
        <span>J${Math.min(state.matchday + 1, totalMatchdays(state))}/${totalMatchdays(state)}</span>
      </div>
      <button class="icon-btn" data-action="reset">↺</button>
    </header>
  `;
}

function renderNav() {
  const tabs = [
    ["team", "👕", "Équipe"],
    ["tactics", "🎯", "Tactique"],
    ["play", "▶️", "Jouer"],
    ["league", "🏆", "Ligue"],
    ["transfers", "💰", "Mercato"],
  ];
  return `
    <nav class="bottom-nav">
      ${tabs
        .map(
          ([id, icon, label]) => `
        <button class="nav-btn ${tab === id ? "active" : ""}" data-action="tab" data-tab="${id}">
          <span class="nav-icon">${icon}</span>
          <span class="nav-label">${label}</span>
        </button>`
        )
        .join("")}
    </nav>
  `;
}

function renderTab() {
  if (tab === "team") return renderTeam();
  if (tab === "tactics") return renderTactics();
  if (tab === "play") return renderPlay();
  if (tab === "league") return renderLeague();
  if (tab === "transfers") return renderTransfers();
  return "";
}

function renderTeam() {
  const club = userClub(state);
  const inLineup = new Set(club.lineup);
  const order = { GK: 0, DEF: 1, MID: 2, FWD: 3 };
  const players = [...club.players].sort(
    (a, b) => order[a.pos] - order[b.pos] || b.ovr - a.ovr
  );
  const rows = players
    .map((p) => {
      const selected = inLineup.has(p.id);
      return `
      <li class="player-row ${selected ? "selected" : ""}" data-action="toggle-player" data-id="${p.id}">
        <span class="pos-badge pos-${p.pos}">${POS_LABEL[p.pos]}</span>
        <span class="player-name">${p.name}</span>
        <span class="player-age">${p.age} ans</span>
        <span class="player-ovr">${p.ovr}</span>
        <span class="player-check">${selected ? "✅" : ""}</span>
      </li>`;
    })
    .join("");
  return `
    <h2>Effectif (${club.players.length})</h2>
    <p class="hint">Titulaires : ${club.lineup.length}/11 — touche un joueur pour le mettre/sortir du onze.</p>
    <button class="primary" data-action="auto-lineup">Composer automatiquement</button>
    <ul class="player-list">${rows}</ul>
  `;
}

function renderTactics() {
  const club = userClub(state);
  const options = Object.keys(FORMATIONS)
    .map(
      (f) =>
        `<button class="formation-pick ${club.formation === f ? "active" : ""}" data-action="set-formation" data-formation="${f}">${f}</button>`
    )
    .join("");
  const shape = FORMATIONS[club.formation];
  return `
    <h2>Tactique</h2>
    <p class="hint">Formation actuelle : <strong>${club.formation}</strong></p>
    <div class="formation-grid">${options}</div>
    <div class="pitch">
      ${["GK", "DEF", "MID", "FWD"]
        .map(
          (row) => `
        <div class="pitch-row">
          ${Array.from({ length: shape[row] })
            .map(() => `<div class="pitch-dot pos-${row}">${POS_LABEL[row]}</div>`)
            .join("")}
        </div>`
        )
        .join("")}
    </div>
  `;
}

function renderPlay() {
  const club = userClub(state);
  if (isSeasonOver(state)) {
    return `
      <h2>Saison terminée</h2>
      <p>Bravo, tu as terminé la saison ${state.season} !</p>
      <button class="primary" data-action="next-season">Démarrer la saison suivante</button>
      ${lastReports ? renderReports() : ""}
    `;
  }
  const round = state.fixtures[state.matchday];
  const fixtureLines = round
    .map((f) => {
      const home = getClub(state, f.home).name;
      const away = getClub(state, f.away).name;
      const isUser = f.home === state.userClubId || f.away === state.userClubId;
      return `<li class="${isUser ? "user-match" : ""}">${home} vs ${away}</li>`;
    })
    .join("");
  return `
    <h2>Journée ${state.matchday + 1}</h2>
    <ul class="fixture-list">${fixtureLines}</ul>
    <button class="primary" data-action="play-matchday" ${club.lineup.length < 11 ? "disabled" : ""}>
      ${club.lineup.length < 11 ? "Compose ton onze (11 joueurs)" : "Simuler la journée"}
    </button>
    ${lastReports ? renderReports() : ""}
  `;
}

function renderReports() {
  const items = lastReports
    .map((r) => {
      const events = r.events
        .map(
          (e) =>
            `<li>${e.minute}' — ${e.scorerName} (${e.side === "home" ? r.home : r.away})</li>`
        )
        .join("");
      return `
      <div class="match-report">
        <div class="score-line"><strong>${r.home} ${r.homeGoals} - ${r.awayGoals} ${r.away}</strong></div>
        ${events ? `<ul class="event-list">${events}</ul>` : `<p class="hint">Aucun but.</p>`}
      </div>`;
    })
    .join("");
  return `<h3>Derniers résultats</h3>${items}`;
}

function renderLeague() {
  const standings = computeStandings(state);
  const rows = standings
    .map(
      (s, i) => `
      <tr class="${s.id === state.userClubId ? "user-row" : ""}">
        <td>${i + 1}</td>
        <td>${s.name}</td>
        <td>${s.played}</td>
        <td>${s.won}</td>
        <td>${s.drawn}</td>
        <td>${s.lost}</td>
        <td>${s.gf - s.ga}</td>
        <td><strong>${s.pts}</strong></td>
      </tr>`
    )
    .join("");
  return `
    <h2>Classement</h2>
    <table class="standings">
      <thead>
        <tr><th>#</th><th>Club</th><th>J</th><th>G</th><th>N</th><th>P</th><th>Diff</th><th>Pts</th></tr>
      </thead>
      <tbody>${rows}</tbody>
    </table>
  `;
}

function renderTransfers() {
  const club = userClub(state);
  const poolRows = state.transferPool
    .map(
      (p) => `
      <li class="player-row">
        <span class="pos-badge pos-${p.pos}">${POS_LABEL[p.pos]}</span>
        <span class="player-name">${p.name}</span>
        <span class="player-ovr">${p.ovr}</span>
        <span class="player-value">${money(p.value)}</span>
        <button class="mini-btn" data-action="buy" data-id="${p.id}" ${club.budget < p.value ? "disabled" : ""}>Acheter</button>
      </li>`
    )
    .join("");
  const squadRows = club.players
    .map(
      (p) => `
      <li class="player-row">
        <span class="pos-badge pos-${p.pos}">${POS_LABEL[p.pos]}</span>
        <span class="player-name">${p.name}</span>
        <span class="player-ovr">${p.ovr}</span>
        <span class="player-value">${money(Math.round(p.value * 0.7))}</span>
        <button class="mini-btn danger" data-action="sell" data-id="${p.id}" ${club.players.length <= 11 ? "disabled" : ""}>Vendre</button>
      </li>`
    )
    .join("");
  return `
    <h2>Mercato</h2>
    <p class="hint">Budget : <strong>${money(club.budget)}</strong></p>
    <h3>Joueurs disponibles</h3>
    <ul class="player-list">${poolRows}</ul>
    <h3>Vendre un joueur</h3>
    <ul class="player-list">${squadRows}</ul>
  `;
}

function showToast(msg) {
  toast = msg;
  render();
  setTimeout(() => {
    toast = null;
    render();
  }, 1800);
}

app.addEventListener("click", (e) => {
  const target = e.target.closest("[data-action]");
  if (!target) return;
  const action = target.dataset.action;

  if (action === "new-game") {
    state = newGame(target.dataset.name);
    tab = "team";
    render();
    return;
  }
  if (action === "reset") {
    if (confirm("Recommencer une nouvelle partie ? La progression actuelle sera perdue.")) {
      clearGame();
      state = null;
      render();
    }
    return;
  }
  if (action === "tab") {
    tab = target.dataset.tab;
    render();
    return;
  }
  if (action === "toggle-player") {
    const club = userClub(state);
    const id = target.dataset.id;
    const inLineup = club.lineup.includes(id);
    if (inLineup) {
      setLineup(state, club.lineup.filter((x) => x !== id));
    } else {
      if (club.lineup.length >= 11) {
        showToast("Le onze est déjà complet (11/11).");
        return;
      }
      setLineup(state, [...club.lineup, id]);
    }
    render();
    return;
  }
  if (action === "auto-lineup") {
    const club = userClub(state);
    setFormation(state, club.formation);
    render();
    return;
  }
  if (action === "set-formation") {
    setFormation(state, target.dataset.formation);
    render();
    return;
  }
  if (action === "play-matchday") {
    lastReports = playMatchday(state);
    render();
    return;
  }
  if (action === "next-season") {
    state = newGame(userClub(state).name);
    lastReports = null;
    render();
    return;
  }
  if (action === "buy") {
    const res = buyPlayer(state, target.dataset.id);
    if (!res.ok) showToast(res.reason === "budget" ? "Budget insuffisant." : "Indisponible.");
    else showToast("Joueur recruté !");
    render();
    return;
  }
  if (action === "sell") {
    const res = sellPlayer(state, target.dataset.id);
    if (!res.ok) showToast("Impossible de vendre (minimum 11 joueurs).");
    else showToast(`Joueur vendu pour ${money(res.fee)}.`);
    render();
    return;
  }
});

render();
