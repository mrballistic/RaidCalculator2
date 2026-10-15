// Translates the page in place, like mrballistic.com. The language is, in
// order: ?lang= in the URL (for sharing and testing, not saved), the
// visitor's pick from the menu (saved), the first of the browser's languages
// the site has, then English. The HTML is the English text; other languages
// come from i18n/<lang>.json and replace each [data-i18n] element's contents
// and each [data-i18n-alt|aria-label|content] attribute. Loaded in <head>,
// without defer, so a non-English page stays hidden until it's translated
// rather than flashing English first.
(() => {
  const LANGS = {
    en: "English", es: "Español", fr: "Français", it: "Italiano", ja: "日本語", de: "Deutsch",
    "zh-Hant": "繁體中文", "zh-Hans": "简体中文", ko: "한국어", "pt-BR": "Português (BR)", ru: "Русский",
  };
  const KEY = "rc-lang";
  const ATTRS = ["alt", "aria-label", "content"];
  const base = new URL("i18n/", document.currentScript.src);
  const badges = new URL("badges/", document.currentScript.src);
  const assets = new URL("./", document.currentScript.src);
  const BADGE_TYPE = { "app-store": "svg", "google-play": "png" };
  const root = document.documentElement;

  // A browser tag (fr-CA, zh-TW, pt-PT…) to a language the site has, or null.
  function match(tag) {
    if (!tag) return null;
    const t = tag.toLowerCase();
    const exact = Object.keys(LANGS).find((l) => l.toLowerCase() === t);
    if (exact) return exact;
    if (t.startsWith("zh")) {
      return /hant|-tw|-hk|-mo/.test(t) ? "zh-Hant" : "zh-Hans";
    }
    if (t.startsWith("pt")) return "pt-BR";
    const primary = t.split("-")[0];
    return Object.keys(LANGS).find((l) => l === primary) || null;
  }

  function saved() {
    try { return localStorage.getItem(KEY); } catch (e) { return null; }
  }

  function initial() {
    const fromURL = match(new URLSearchParams(location.search).get("lang"));
    if (fromURL) return fromURL;
    const picked = match(saved());
    if (picked) return picked;
    for (const tag of navigator.languages?.length ? navigator.languages : [navigator.language]) {
      const found = match(tag);
      if (found) return found;
    }
    return "en";
  }

  const cache = {};
  function load(lang) {
    if (!cache[lang]) {
      cache[lang] = fetch(new URL(lang + ".json", base)).then((r) => {
        if (!r.ok) throw new Error(r.status);
        return r.json();
      });
    }
    return cache[lang];
  }

  let strings = {};
  let current = "en";

  // Applies the current strings within `scope`; scripts call it for UI they add.
  // innerHTML is deliberate: values come only from this site's own
  // i18n/*.json (same origin, written in the repo, never from visitors) and
  // keep the English's inline markup, such as links and &nbsp;.
  function apply(scope = document) {
    scope.querySelectorAll("[data-i18n]").forEach((el) => {
      const s = strings[el.dataset.i18n];
      if (s != null) el.innerHTML = s;
    });
    for (const attr of ATTRS) {
      scope.querySelectorAll(`[data-i18n-${attr}]`).forEach((el) => {
        const s = strings[el.getAttribute(`data-i18n-${attr}`)];
        if (s != null) el.setAttribute(attr, s);
      });
    }
    // Store badges in the page's language: Apple's and Google's official
    // localized artwork in badges/, the page's own English files otherwise.
    scope.querySelectorAll("[data-badge]").forEach((el) => {
      if (!el.dataset.enSrc) el.dataset.enSrc = el.getAttribute("src");
      const kind = el.dataset.badge;
      el.src = current === "en" ? el.dataset.enSrc : new URL(`${kind}-${current}.${BADGE_TYPE[kind]}`, badges).href;
    });
    // App screenshots in the page's language: l10n/<lang>/ holds each
    // [data-shot] image under its English name (scripts/www_shots.py).
    scope.querySelectorAll("[data-shot]").forEach((el) => {
      if (!el.dataset.enSrc) el.dataset.enSrc = el.getAttribute("src");
      const file = el.dataset.enSrc.split("/").pop();
      el.src = current === "en" ? el.dataset.enSrc : new URL(`l10n/${current}/${file}`, assets).href;
    });
    // Shown in every language but English, such as the privacy page's note.
    scope.querySelectorAll("[data-i18n-not-en]").forEach((el) => { el.hidden = current === "en"; });
  }

  function reveal() { root.classList.remove("i18n-pending"); }

  async function use(lang, save) {
    if (save) { try { localStorage.setItem(KEY, lang); } catch (e) { /* private mode */ } }
    try {
      strings = await load(lang);
      current = lang;
    } catch (e) {
      // Couldn't load: stay in English rather than show nothing.
      strings = await load("en").catch(() => ({}));
      current = "en";
    }
    root.lang = current;
    const ready = () => {
      apply();
      const select = document.querySelector(".lang-select");
      if (select) select.value = current;
      reveal();
      document.dispatchEvent(new CustomEvent("rc-language", { detail: current }));
    };
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", ready, { once: true });
    else ready();
  }

  function addMenu() {
    const bar = document.querySelector(".topbar-inner");
    if (!bar) return;
    const label = document.createElement("label");
    label.className = "lang";
    const select = document.createElement("select");
    select.className = "lang-select";
    select.setAttribute("aria-label", "Language");
    select.setAttribute("data-i18n-aria-label", "lang.label");
    for (const [code, name] of Object.entries(LANGS)) {
      const option = document.createElement("option");
      option.value = code;
      option.lang = code;
      option.textContent = name;
      select.append(option);
    }
    select.value = current;
    select.addEventListener("change", () => use(select.value, true));
    label.append(select);
    // At the end of the bar, across from the name.
    bar.append(label);
  }

  window.RCI18N = { apply, get language() { return current; } };

  const lang = initial();
  if (lang !== "en") {
    root.classList.add("i18n-pending");
    // Never leave the page hidden if the strings are slow or fail.
    setTimeout(reveal, 2500);
  }
  current = lang;
  document.addEventListener("DOMContentLoaded", addMenu, { once: true });
  // English needs no fetch until someone switches back to it.
  if (lang === "en") { load("en").then((s) => { strings = s; }).catch(() => {}); }
  else use(lang, false);
})();
