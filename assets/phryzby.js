// Shared machinery for a chapter page: colour the Ruby, boot CRuby under
// WebAssembly, and hand the page a VM. Everything about the physics lives in
// the .rb files this fetches — a page that wants to say something new writes
// Ruby, not JavaScript.

const RUNTIME = "https://cdn.jsdelivr.net/npm/@ruby/wasm-wasi@2.10.1/dist/browser/+esm";
const BINARY = "https://cdn.jsdelivr.net/npm/@ruby/3.4-wasm-wasi@2.10.1/dist/ruby+stdlib.wasm";

// Files are fetched and evaluated in order, so the requires at the top of each
// one have nothing to do. Defining it away is cheaper than editing the source
// the page is meant to be showing you.
const SHIM = "def require_relative(_path) = true\n";

export const RAD = Math.PI / 180;
export const $ = (id) => document.getElementById(id);

// Everything is addressed from the site root, resolved against this module
// rather than the page, so a chapter one directory down needs no ../ of its
// own and the tree is identical on every page.
const ROOT = new URL("../", import.meta.url);
const at = (path) => new URL(path, ROOT).href;

const PARTS = [
  "expression", "equation", "scope", "quantities", "law", "solver", "scenario", "degrees",
];

// Order is the order the requires in lib/physics.rb imply.
export const ENGINE = PARTS.map((part) => `lib/physics/${part}.rb`);

// The book, as the tree draws it: which page owns which file.
export const BOOK = [
  {
    group: "the engine",
    page: "engine.html",
    dir: "lib/physics/",
    files: PARTS.map((part) => `lib/physics/${part}.rb`).concat("lib/pythagoras.rb"),
  },
  {
    group: "light",
    dir: "lib/light/",
    files: [ "lib/light/optics.rb" ],
    chapters: [
      { page: "light/reflection.html", files: [ "lib/light/reflection.rb" ] },
      { page: "light/refraction.html", files: [ "lib/light/refraction.rb" ] },
      { page: "light/reflectance.html", files: [ "lib/light/reflectance.rb" ] },
    ],
  },
];

const TITLES = {
  "engine.html": "0 · The engine",
  "light/reflection.html": "1.1 · Reflection",
  "light/refraction.html": "1.2 · Refraction",
  "light/reflectance.html": "1.3 · Reflectance",
};

// A file belonging to this page opens in the editor; one belonging to another
// opens that chapter. So the tree is the table of contents as well.
function mountTree(host, { here, loaded, open }) {
  const rows = [];

  const link = (label, href, { nest = false, current = false, away = false } = {}) => {
    const a = document.createElement("a");
    a.textContent = label;
    a.href = href;
    if (nest) a.classList.add("nest");
    if (away) a.classList.add("elsewhere");
    if (current) a.setAttribute("aria-current", "page");
    return a;
  };

  const heading = (text, className) => {
    const node = document.createElement("div");
    node.className = className;
    node.textContent = text;
    return node;
  };

  const fileRow = (path, page) => {
    const label = path.split("/").pop();
    const mine = loaded.has(path);
    const row = link(label, mine ? "#" : at(page), { nest: true, away: !mine });
    if (mine) {
      row.addEventListener("click", (event) => { event.preventDefault(); open(path); });
      row.dataset.path = path;
    }
    return row;
  };

  BOOK.forEach((section) => {
    rows.push(heading(section.group, "group"));

    if (section.chapters) {
      if (section.files) {
        rows.push(heading(section.dir, "dir"));
        section.files.forEach((path) => rows.push(fileRow(path, section.chapters[0].page)));
      }
      section.chapters.forEach((chapter) => {
        rows.push(link(TITLES[chapter.page], at(chapter.page), { current: chapter.page === here }));
        chapter.files.forEach((path) => rows.push(fileRow(path, chapter.page)));
      });
    } else {
      rows.push(link(TITLES[section.page], at(section.page), { current: section.page === here }));
      rows.push(heading(section.dir, "dir"));
      section.files.forEach((path) => rows.push(fileRow(path, section.page)));
    }
  });

  host.replaceChildren(...rows);

  return (path) => {
    host.querySelectorAll("a[data-path]").forEach((row) => {
      row.setAttribute("aria-current", String(row.dataset.path === path));
    });
  };
}

// --- syntax highlighting ---------------------------------------------------
// Small enough to read, which is the point: nothing is imported to colour it.

const KEYWORDS = /^(class|module|def|do|end|self|if|unless|then|else|return)$/;
const escape = (s) => s.replace(/[&<>]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" }[c]));
const span = (kind, text) => `<span class="tok-${kind}">${escape(text)}</span>`;

export function highlight(code) {
  // Strings come first in the alternation, so a # inside one does not start a
  // comment and an interpolation is not mistaken for the rest of the line.
  const pattern = /("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')|(#[^\n]*)|(:[A-Za-z_]\w*[?!]?)|(\b[a-z_]\w*:)|(\b[A-Z]\w*\b)|(\b\d+(?:\.\d+)?\b)|(\b[a-z_]\w*[?!]?\b)|(\*\*|==|\.\.|[{}()\[\].,<>+\-*\/=|])/g;
  let out = "";
  let last = 0;
  let match;

  while ((match = pattern.exec(code)) !== null) {
    out += escape(code.slice(last, match.index));
    const [text, string, comment, symbol, key, constant, number, word, operator] = match;

    if (string) out += span("str", text);
    else if (comment) out += span("com", text);
    else if (symbol || key) out += span("sym", text);
    else if (constant) out += span("const", text);
    else if (number) out += span("num", text);
    else if (word) out += KEYWORDS.test(text) ? span("kw", text) : escape(text);
    else if (operator) out += span("op", text);
    else out += escape(text);

    last = pattern.lastIndex;
  }
  return out + escape(code.slice(last));
}

// --- ray drawing -----------------------------------------------------------

export const SCENE = { width: 300, height: 200, cx: 150, cy: 100, len: 76 };

export const above = (a) => [ SCENE.cx - Math.sin(a * RAD) * SCENE.len,
                              SCENE.cy - Math.cos(a * RAD) * SCENE.len ];
export const mirrored = (a) => [ SCENE.cx + Math.sin(a * RAD) * SCENE.len,
                                 SCENE.cy - Math.cos(a * RAD) * SCENE.len ];
export const below = (a) => [ SCENE.cx + Math.sin(a * RAD) * SCENE.len,
                              SCENE.cy + Math.cos(a * RAD) * SCENE.len ];

// A ray is its line plus a head drawn at the tip. The head is the same size on
// a hairline as on a thick ray — only the width carries meaning — so it is
// built here rather than left to an SVG marker, which scales with stroke.
const HEAD = 7;

export function ray(x1, y1, x2, y2, width = 3, opacity = 1) {
  const span = Math.hypot(x2 - x1, y2 - y1);
  const ux = (x2 - x1) / span, uy = (y2 - y1) / span;
  const bx = x2 - ux * HEAD, by = y2 - uy * HEAD;
  const half = HEAD * 0.42;
  return `<line x1="${x1}" y1="${y1}" x2="${bx}" y2="${by}" stroke="var(--ray)"
      stroke-width="${width}" stroke-opacity="${opacity}"/>
    <path d="M ${x2} ${y2} L ${bx - uy * half} ${by + ux * half}
      L ${bx + uy * half} ${by - ux * half} z" fill="var(--ray)" fill-opacity="${opacity}"/>`;
}

export const label = (x, y, text, fill = "var(--ink-soft)", anchor = "middle") =>
  `<text x="${x}" y="${y}" text-anchor="${anchor}" font-size="8.5" fill="${fill}"
    font-family="var(--mono)">${text}</text>`;

// The surface, the normal, and nothing else. `second` names the medium below
// when there is one; a mirror has no below worth naming.
export function stage({ second = null } = {}) {
  const faint = `stroke="var(--rule)" stroke-width="1"`;
  const parts = [
    second
      ? `<rect x="0" y="100" width="300" height="100" fill="var(--rule)" opacity=".3"/>`
      : `<rect x="0" y="100" width="300" height="100" fill="var(--rule)" opacity=".55"/>`,
    `<line x1="0" y1="100" x2="300" y2="100" ${faint}/>`,
    `<line x1="150" y1="10" x2="150" y2="190" ${faint} stroke-dasharray="3 4"/>`,
    label(156, 15, "normal", "var(--ink-soft)", "start"),
  ];
  if (second) {
    parts.push(label(294, 94, "μ₁", "var(--ink-soft)", "end"));
    parts.push(label(294, 114, "μ₂", "var(--ink-soft)", "end"));
  } else {
    parts.push(label(294, 114, "mirror", "var(--ink-soft)", "end"));
  }
  return parts;
}

// --- the editor ------------------------------------------------------------

function mountEditor(files, { tabs, pre, textarea }, announce = () => {}) {
  let active = 0;

  const remember = () => { if (textarea.value !== "") files[active].code = textarea.value; };

  const repaint = () => {
    pre.innerHTML = highlight(textarea.value) + "\n";
    pre.scrollTop = textarea.scrollTop;
    pre.scrollLeft = textarea.scrollLeft;
  };

  const show = (index) => {
    remember();
    active = index;
    textarea.value = files[index].code;
    [ ...tabs.children ].forEach((b, n) => b.setAttribute("aria-selected", String(n === index)));
    repaint();
    announce(files[index].key);
  };

  tabs.innerHTML = "";
  files.forEach((file, index) => {
    const button = document.createElement("button");
    button.type = "button";
    button.setAttribute("role", "tab");
    button.textContent = file.label;
    button.addEventListener("click", () => show(index));
    tabs.append(button);
  });

  textarea.addEventListener("input", repaint);
  textarea.addEventListener("scroll", repaint);
  textarea.spellcheck = false;

  show(0);
  return {
    remember,
    showPath: (key) => show(Math.max(0, files.findIndex((file) => file.key === key))),
    reset: (restore) => {
      files.forEach((file) => { file.code = restore(file); });
      show(active);
    },
  };
}

// --- the page --------------------------------------------------------------

async function fetchRuby(files) {
  return Promise.all(files.map(async (file) => ({
    ...file,
    label: file.label || file.key.split("/").pop(),
    // Revalidated rather than taken from cache: a stale law running against a
    // fresh page fails in ways that look like the law is wrong.
    code: (await fetch(at(file.key), { cache: "no-cache" }).then((r) => r.text())).trimEnd(),
  })));
}

async function loadVM(onStatus) {
  const { DefaultRubyVM } = await import(RUNTIME);
  const response = await fetch(BINARY);
  const total = +response.headers.get("content-length") || 0;
  const reader = response.body.getReader();
  const chunks = [];
  let seen = 0;

  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(value);
    seen += value.length;
    const mb = (seen / 1048576).toFixed(1);
    onStatus(total ? `Fetching CRuby… ${mb} of ${(total / 1048576).toFixed(1)} MB`
                   : `Fetching CRuby… ${mb} MB`);
  }

  onStatus("Compiling…");
  const module = await WebAssembly.compile(await new Blob(chunks).arrayBuffer());
  return (await DefaultRubyVM(module)).vm;
}

/**
 * Wires a chapter page together.
 *
 *   files   — the .rb files to fetch, evaluate in order, and show as tabs
 *   harness — Ruby that the page's controls call into
 *   onSolve — called with the vm whenever a control moves
 */
export async function chapter({ page, files, harness = "", onSolve, showEngine = false }) {
  const status = $("status");
  const run = $("run");
  const reset = $("reset");
  const say = (text, bad = false) => {
    status.textContent = text;
    status.classList.toggle("err", bad);
  };

  // The engine is loaded on every page and shown only on its own. Files are
  // evaluated in the order given, because that is the order the requires
  // imply, and shown in `tab` order.
  const engine = ENGINE.map((key, index) => ({ key, hidden: !showEngine, tab: index - ENGINE.length }));
  const loaded = await fetchRuby([ ...engine, ...files ]);
  const originals = loaded.map((file) => file.code);
  const tabbed = loaded.filter((file) => !file.hidden)
    .map((file, index) => ({ file, at: file.tab ?? index }))
    .sort((a, b) => a.at - b.at).map((entry) => entry.file);

  let markTree = () => {};
  const editor = mountEditor(tabbed, { tabs: $("tabs"), pre: $("highlight"), textarea: $("source") },
    (key) => markTree(key));
  markTree = mountTree($("tree"), {
    here: page,
    loaded: new Set(tabbed.map((file) => file.key)),
    open: (key) => editor.showPath(key),
  });
  markTree(tabbed[0].key);

  let vm = null;
  const view = {
    get vm() { return vm; },
    say,
    refresh() {
      if (!vm) return onSolve(null);
      try {
        onSolve(vm);
        say("Solved in Ruby.");
      } catch (error) {
        say(String(error).split("\n")[0], true);
      }
    },
  };

  const evaluate = () => {
    editor.remember();
    loaded.forEach((file) => vm.eval(file.code));
    if (harness) vm.eval(harness);
  };

  run.addEventListener("click", async () => {
    try {
      if (vm) { evaluate(); view.refresh(); return; }
      run.disabled = true;
      say("Fetching CRuby…");
      vm = await loadVM(say);
      vm.eval(SHIM);
      evaluate();
      run.textContent = "Re-run the laws";
      run.disabled = false;
      if (reset) reset.hidden = false;
      view.refresh();
    } catch (error) {
      say(String(error).split("\n")[0], true);
      run.disabled = false;
    }
  });

  if (reset) {
    reset.addEventListener("click", () => {
      editor.reset((file) => originals[loaded.indexOf(file)]);
      if (vm) { evaluate(); view.refresh(); }
    });
  }

  return view;
}
