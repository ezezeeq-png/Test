const btn = document.getElementById("counter-btn");
let count = 0;

btn.addEventListener("click", () => {
  count++;
  btn.textContent = `Cliqué ${count} fois`;
});
