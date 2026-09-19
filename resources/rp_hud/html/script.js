const menu = document.getElementById("menu");
const closeBtn = document.getElementById("close-btn");
const inventoryBtn = document.getElementById("inventory-btn");
const hungerFill = document.getElementById("hunger-fill");
const thirstFill = document.getElementById("thirst-fill");

function resourceName() {
  return typeof GetParentResourceName === "function"
    ? GetParentResourceName()
    : "rp_hud";
}

function post(endpoint, body = {}) {
  return fetch(`https://${resourceName()}/${endpoint}`, {
    method: "POST",
    headers: { "Content-Type": "application/json; charset=UTF-8" },
    body: JSON.stringify(body),
  });
}

function closeMenu() {
  menu.classList.add("hidden");
  post("close");
}

closeBtn.addEventListener("click", closeMenu);
inventoryBtn.addEventListener("click", () => post("openInventory"));

// Le menu doit toujours pouvoir se fermer avec Echap, sinon le joueur reste
// coince avec la souris affichee et ne peut plus jouer.
document.addEventListener("keyup", (e) => {
  if (e.key === "Escape" && !menu.classList.contains("hidden")) {
    closeMenu();
  }
});

window.addEventListener("message", (event) => {
  const data = event.data;

  switch (data.action) {
    case "open":
      menu.classList.remove("hidden");
      break;
    case "close":
      menu.classList.add("hidden");
      break;
    case "needs":
      hungerFill.style.width = `${Math.max(0, Math.min(100, data.hunger))}%`;
      thirstFill.style.width = `${Math.max(0, Math.min(100, data.thirst))}%`;
      break;
  }
});
