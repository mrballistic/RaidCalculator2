// Switches the glass top bar to its dark material while it sits over a
// section marked data-topbar="dark", the way iOS bars adapt to what's
// scrolling beneath them.
(() => {
  const bar = document.querySelector(".topbar");
  const dark = [...document.querySelectorAll('[data-topbar="dark"]')];
  if (!bar || !dark.length) return;

  let queued = false;
  function update() {
    queued = false;
    const probe = bar.offsetHeight / 2;
    const over = dark.some((el) => {
      const r = el.getBoundingClientRect();
      return r.top <= probe && r.bottom >= probe;
    });
    bar.classList.toggle("topbar--dark", over);
  }
  function queue() {
    if (!queued) { queued = true; requestAnimationFrame(update); }
  }
  addEventListener("scroll", queue, { passive: true });
  addEventListener("resize", queue);
  update();
})();
