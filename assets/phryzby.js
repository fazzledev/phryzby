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

// Re-running has to start from the same place every time. Ruby will happily
// reopen a module that is no longer in the file, so what a run defines is
// taken away before the next one begins — but only what these files defined,
// never anything that was there before them.
const RELOAD = String.raw`
module Reload
  def self.remember = @present = Object.constants

  def self.check(source)
    RubyVM::InstructionSequence.compile(source)
    ""
  rescue SyntaxError => e
    e.message.lines.first.to_s.strip
  end

  def self.forget(names)
    names.each do |name|
      key = name.to_sym
      next if @present.include?(key)

      Object.send(:remove_const, key) if Object.const_defined?(key, false)
    end
  end
end
`;

// module Refraction, class Numeric, Crossing = … — what a file puts at the
// top level, however it puts it there.
const DECLARES = /^(?:\s*(?:module|class)\s+([A-Z]\w*)|([A-Z]\w*)\s*=[^=])/gm;

const declared = (source) =>
  [ ...source.matchAll(DECLARES) ].map((found) => found[1] || found[2]);

// The console runs against the top-level binding, so locals persist between
// lines and every constant the laws defined is in scope. Printed output comes
// back alongside the value, the way irb shows both.
const CONSOLE = String.raw`
require "stringio"

module Console
  SEPARATOR = "\u0000"

  class << self
    attr_accessor :inputs
  end
  self.inputs = {}

  def self.run(source)
    printed = StringIO.new
    previous = $stdout
    $stdout = printed
    value = eval(source, TOPLEVEL_BINDING)
    [ "ok", printed.string, value.inspect ].join(SEPARATOR)
  rescue Exception => error
    [ "error", printed.string, "#{error.class}: #{error.message}" ].join(SEPARATOR)
  ensure
    $stdout = previous
  end
end
`;

// Single-quoted, so nothing the reader types is interpolated on the way in.
const asRubyString = (text) => `'${text.replace(/\\/g, "\\\\").replace(/'/g, "\\'")}'`;

export const RAD = Math.PI / 180;
export const $ = (id) => document.getElementById(id);

// Everything is addressed from the site root, resolved against this module
// rather than the page, so a chapter one directory down needs no ../ of its
// own and the tree is identical on every page.
const ROOT = new URL("../", import.meta.url);
const at = (path) => new URL(path, ROOT).href;

const PARTS = [
  "expression", "equation", "scope", "quantities", "law", "solver", "scenario", "angles",
  "notation", "showing",
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
    chapters: [
      { page: "light/incidence.html", files: [ "lib/light/incidence.rb" ] },
      { page: "light/reflection.html", files: [ "lib/light/reflection.rb" ] },
      { page: "light/refraction.html", files: [ "lib/light/refraction.rb" ] },
      { page: "light/reflectance.html", files: [ "lib/light/reflectance.rb" ] },
      { page: "light/total-internal-reflection.html",
        files: [ "lib/light/total_internal_reflection.rb" ] },
    ],
  },
];

const TITLES = {
  "engine.html": "0 · The engine",
  "light/incidence.html": "1.1 · Incidence",
  "light/reflection.html": "1.2 · Reflection",
  "light/refraction.html": "1.3 · Refraction",
  "light/reflectance.html": "1.4 · Reflectance",
  "light/total-internal-reflection.html": "1.5 · Total internal reflection",
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

      // A chapter is one file, so the chapter is the row. Its files are named
      // on the tabs; `owns` is what carries an edit mark back to the tree.
      section.chapters.forEach((chapter) => {
        const row = link(TITLES[chapter.page], at(chapter.page), { current: chapter.page === here });
        row.dataset.owns = chapter.files.join(" ");
        rows.push(row);
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
export function stage({ second = null, surface = "mirror" } = {}) {
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
    parts.push(label(294, 114, surface, "var(--ink-soft)", "end"));
  }
  return parts;
}

// --- resizing --------------------------------------------------------------

const AUTO_RUN = "phryzby.autorun";

// Reads the setting with no argument, writes it with one.
function autoRun(next) {
  try {
    if (next === undefined) return localStorage.getItem(AUTO_RUN) === "on";
    localStorage.setItem(AUTO_RUN, next ? "on" : "off");
  } catch {
    // A browser that refuses storage still toggles; it just forgets.
  }
  return next;
}

const LAYOUT = "phryzby.layout";
const DEFAULTS = { tree: 272, side: 416, console: 208 };

const remembered = () => {
  try {
    return { ...DEFAULTS, ...JSON.parse(localStorage.getItem(LAYOUT) || "{}") };
  } catch {
    return { ...DEFAULTS };
  }
};

function mountPanes() {
  const panes = document.querySelector(".panes");
  const code = document.querySelector(".pane.code");
  const editor = document.querySelector(".editor");
  const box = document.querySelector(".console");
  if (!panes) return;

  const sizes = remembered();
  const apply = () => {
    const root = document.documentElement.style;
    root.setProperty("--tree", `${sizes.tree}px`);
    root.setProperty("--side", `${sizes.side}px`);
    root.setProperty("--console", `${sizes.console}px`);
    try {
      localStorage.setItem(LAYOUT, JSON.stringify(sizes));
    } catch {
      // A browser that refuses storage still resizes; it just forgets.
    }
  };

  const grip = (axis) => {
    const node = document.createElement("div");
    node.className = axis === "y" ? "grip row" : "grip";
    return node;
  };

  // Each grip owns one measurement. `sign` is which way dragging grows it.
  const drags = (node, { axis, key, sign, min, max }) => {
    // Tracked on the window rather than the grip, so a fast drag that outruns
    // the pointer does not drop the gesture.
    node.addEventListener("pointerdown", (event) => {
      event.preventDefault();
      node.classList.add("dragging");
      const from = axis === "y" ? event.clientY : event.clientX;
      const origin = sizes[key];

      const move = (moved) => {
        const travelled = (axis === "y" ? moved.clientY : moved.clientX) - from;
        sizes[key] = Math.round(Math.min(max(), Math.max(min, origin + sign * travelled)));
        apply();
      };
      const stop = () => {
        node.classList.remove("dragging");
        window.removeEventListener("pointermove", move);
        window.removeEventListener("pointerup", stop);
        window.removeEventListener("pointercancel", stop);
      };

      window.addEventListener("pointermove", move);
      window.addEventListener("pointerup", stop);
      window.addEventListener("pointercancel", stop);
    });

    node.addEventListener("dblclick", () => { sizes[key] = DEFAULTS[key]; apply(); });
  };

  const left = grip("x");
  const right = grip("x");
  panes.insertBefore(left, panes.children[1]);
  panes.insertBefore(right, panes.children[3]);
  drags(left, { axis: "x", key: "tree", sign: 1, min: 140, max: () => innerWidth * 0.4 });
  drags(right, { axis: "x", key: "side", sign: -1, min: 260, max: () => innerWidth * 0.55 });

  if (box && editor) {
    const between = grip("y");
    code.insertBefore(between, box);
    drags(between, { axis: "y", key: "console", sign: -1, min: 64,
                     max: () => code.clientHeight - 120 });
  }

  apply();
}

// --- the console -----------------------------------------------------------

function mountConsole({ log, form, input, hint }, { evaluate, examples = [] }) {
  const history = [];
  let position = 0;

  const write = (text, kind) => {
    const line = document.createElement("div");
    line.className = kind;
    line.textContent = text;
    log.append(line);
    log.scrollTop = log.scrollHeight;
    return line;
  };

  const ask = (source) => {
    write(source, "said");
    const answer = evaluate(source);
    if (answer === null) return write("Run the laws first.", "warned");
    const [status, printed, value] = answer;
    if (printed) write(printed.replace(/\n$/, ""), "printed");
    write(value, status === "ok" ? "answered" : "failed");
  };

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    const source = input.value.trim();
    if (!source) return;
    history.push(source);
    position = history.length;
    input.value = "";
    ask(source);
  });

  // Up and down walk the history, the way a shell does.
  input.addEventListener("keydown", (event) => {
    if (event.key !== "ArrowUp" && event.key !== "ArrowDown") return;
    if (!history.length) return;
    event.preventDefault();
    position += event.key === "ArrowUp" ? -1 : 1;
    position = Math.max(0, Math.min(history.length, position));
    input.value = history[position] ?? "";
  });

  examples.forEach((example) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "try";
    button.textContent = example;
    button.addEventListener("click", () => { input.value = example; input.focus(); });
    hint.append(button);
  });

  return { clear: () => log.replaceChildren(), note: (text) => write(text, "noted"), ask };
}

// --- the editor ------------------------------------------------------------

/**
 * Per-line marks for the gutter: which lines of `after` are new or altered,
 * and where lines were taken out. Matching head and tail are trimmed first, so
 * the quadratic part only ever sees the region that actually differs.
 */
function changeMarks(before, after) {
  const line = new Array(after.length).fill(null);
  const cut = new Set();
  const cutTop = new Set();

  let head = 0;
  while (head < before.length && head < after.length && before[head] === after[head]) head++;

  let tail = 0;
  while (tail < before.length - head && tail < after.length - head &&
         before[before.length - 1 - tail] === after[after.length - 1 - tail]) tail++;

  const gone = before.slice(head, before.length - tail);
  const come = after.slice(head, after.length - tail);
  if (!gone.length && !come.length) return { line, cut, cutTop };

  if (gone.length * come.length > 250000) {
    come.forEach((_, n) => { line[head + n] = gone.length ? "mod" : "add"; });
    return { line, cut, cutTop };
  }

  const ops = align(gone, come);
  let k = 0;

  while (k < ops.length) {
    if (ops[k].kind === "same") { k++; continue; }

    const at = ops[k].j;
    const added = [];
    let removed = 0;

    while (k < ops.length && ops[k].kind !== "same") {
      if (ops[k].kind === "add") added.push(ops[k].j); else removed++;
      k++;
    }

    if (added.length) added.forEach((j) => { line[head + j] = removed ? "mod" : "add"; });
    else if (head + at === 0) cutTop.add(0);
    else cut.add(head + at - 1);
  }

  return { line, cut, cutTop };
}

function align(before, after) {
  const n = before.length, m = after.length;
  const common = Array.from({ length: n + 1 }, () => new Uint16Array(m + 1));

  for (let i = n - 1; i >= 0; i--) {
    for (let j = m - 1; j >= 0; j--) {
      common[i][j] = before[i] === after[j]
        ? common[i + 1][j + 1] + 1
        : Math.max(common[i + 1][j], common[i][j + 1]);
    }
  }

  const ops = [];
  let i = 0, j = 0;

  while (i < n && j < m) {
    if (before[i] === after[j]) { ops.push({ kind: "same", j }); i++; j++; }
    else if (common[i + 1][j] >= common[i][j + 1]) { ops.push({ kind: "gone", j }); i++; }
    else { ops.push({ kind: "add", j }); j++; }
  }
  while (i < n) { ops.push({ kind: "gone", j }); i++; }
  while (j < m) { ops.push({ kind: "add", j }); j++; }

  return ops;
}

function mountEditor(files, { tabs, pre, textarea, gutter },
                     { announce = () => {}, changed = () => {} } = {}) {
  let active = 0;

  const remember = () => { if (textarea.value !== "") files[active].code = textarea.value; };
  const textOf = (index) => (index === active ? textarea.value : files[index].code);
  const edited = (index) => textOf(index) !== files[index].original;

  // Only the textarea scrolls; the highlighted layer and the gutter follow it.
  const sync = () => {
    pre.scrollTop = textarea.scrollTop;
    pre.scrollLeft = textarea.scrollLeft;
    if (gutter) gutter.scrollTop = textarea.scrollTop;
  };

  const rule = () => {
    if (!gutter) return;

    const after = textarea.value.split("\n");
    const marks = changeMarks((files[active].original ?? "").split("\n"), after);

    gutter.replaceChildren(...after.map((_, n) => {
      const row = document.createElement("div");
      row.className = [ "gline", marks.line[n], marks.cut.has(n) && "cut",
                        marks.cutTop.has(n) && "cut-top" ].filter(Boolean).join(" ");
      row.textContent = String(n + 1);
      return row;
    }));
  };

  const flag = () => {
    [ ...tabs.children ].forEach((button, n) => button.classList.toggle("changed", edited(n)));
    changed(files.filter((_, n) => edited(n)).map((file) => file.key));
  };

  const repaint = () => {
    pre.innerHTML = highlight(textarea.value) + "\n";
    rule();
    sync();
    flag();
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
    button.append(file.label, Object.assign(document.createElement("span"), { className: "dot" }));
    button.addEventListener("click", () => show(index));
    tabs.append(button);
  });

  textarea.addEventListener("input", repaint);
  textarea.addEventListener("scroll", sync);
  textarea.spellcheck = false;

  show(0);
  return {
    remember,
    showPath: (key) => show(Math.max(0, files.findIndex((file) => file.key === key))),
    // Not via show(), whose first act is to remember the textarea — which is
    // exactly the text being thrown away.
    reset: () => {
      files.forEach((file) => { file.code = file.original; });
      textarea.value = files[active].code;
      repaint();
      announce(files[active].key);
    },
  };
}

// --- the page --------------------------------------------------------------

async function fetchRuby(files) {
  return Promise.all(files.map(async (file) => {
    // Revalidated rather than taken from cache: a stale law running against a
    // fresh page fails in ways that look like the law is wrong.
    const code = (await fetch(at(file.key), { cache: "no-cache" }).then((r) => r.text())).trimEnd();

    // `original` is what the repository says, `code` what the reader has done
    // to it since. The gutter and Revert both measure from it.
    return { ...file, label: file.label || file.key.split("/").pop(), code, original: code };
  }));
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
 *   opening — the chapter's one move, run in the console the moment Ruby boots
 */
export async function chapter({ page, files, harness = "", onSolve, showEngine = false,
                                examples = [], opening = [], presents = null, shows = null }) {
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

  // How a chapter is shown comes after the laws it shows, because it composes
  // them. The vocabulary it draws with is machinery and stays out of the way;
  // the declaration itself sits beside the law, because changing it is the
  // point.
  const shown = shows
    ? [ { key: "lib/light/picture.rb", hidden: true },
        { key: shows.file, label: "shown.rb", tab: 1.5 } ]
    : [];
  const loaded = await fetchRuby([ ...engine, ...files, ...shown ]);
  const tabbed = loaded.filter((file) => !file.hidden)
    .map((file, index) => ({ file, at: file.tab ?? index }))
    .sort((a, b) => a.at - b.at).map((entry) => entry.file);

  // VS Code's habit: a bar in the gutter beside every line you touched, a dot
  // on the tab, an M on the file in the tree.
  const markChanged = (keys) => {
    const dirty = new Set(keys);
    $("tree").querySelectorAll("a[data-path]").forEach((row) => {
      row.classList.toggle("changed", dirty.has(row.dataset.path));
    });
    $("tree").querySelectorAll("a[data-owns]").forEach((row) => {
      row.classList.toggle("changed", row.dataset.owns.split(" ").some((key) => dirty.has(key)));
    });
  };

  let markTree = () => {};
  const editor = mountEditor(
    tabbed,
    { tabs: $("tabs"), pre: $("highlight"), textarea: $("source"), gutter: $("gutter") },
    { announce: (key) => markTree(key), changed: markChanged },
  );
  markTree = mountTree($("tree"), {
    here: page,
    loaded: new Set(tabbed.map((file) => file.key)),
    open: (key) => editor.showPath(key),
  });
  markTree(tabbed[0].key);

  let vm = null;

  mountPanes();

  const repl = mountConsole(
    { log: $("log"), form: $("ask"), input: $("line"), hint: $("hint") },
    {
      examples,
      evaluate(source) {
        if (!vm) return null;
        return vm.eval(`Console.run(${asRubyString(source)})`).toString().split("\u0000");
      },
    },
  );

  const view = {
    get vm() { return vm; },
    say,
    refresh() {
      if (!vm) return onSolve ? onSolve(null) : undefined;
      try {
        if (onSolve) onSolve(vm);
        if (shows) move();
        say("Solved in Ruby.");
      } catch (error) {
        say(String(error).split("\n")[0], true);
      }
    },
  };

  // Every constant any run has defined, so a module renamed in the editor
  // takes its old name away with it.
  const defined = new Set(loaded.flatMap((file) => declared(file.original)));

  // A page that is shown rather than drawn: the law states itself into one
  // half, the demonstration into the other, and nothing here knows optics.
  const reading = () => {
    const pairs = [ ...document.querySelectorAll("#demo [data-vary]") ]
      .map((control) => `${control.dataset.vary}: ${control.value}`);

    return pairs.length ? `{ ${pairs.join(", ")} }` : `Physics.shown(${shows.law}).showing_of.opening`;
  };

  const move = () => {
    vm.eval(`Console.inputs = ${reading()}`);
    const [ picture, readouts, labels ] =
      vm.eval(`Physics.shown(${shows.law}).showing_of.moved(${reading()})`).toString().split("\u0000");

    $("picture").innerHTML = picture;
    $("readouts").innerHTML = readouts;
    labels.split("\u0002").forEach((pair) => {
      const [ name, text ] = pair.split("\u0001");
      const shown = document.getElementById(`${name}-out`);
      if (shown) shown.textContent = text;
    });
  };

  // The law states itself. Not a copy of the source: a second walk of the
  // same tree the solver uses, so an edited law restates itself too.
  const present = () => {
    const statement = $("statement");
    if (statement && presents) statement.innerHTML = vm.eval(`${presents}.to_html`).toString();
    if (!shows) return;

    const held = [ ...document.querySelectorAll("#demo [data-vary]") ]
      .map((control) => [ control.dataset.vary, control.value ]);

    $("law").innerHTML = vm.eval(`Physics.shown(${shows.law}).showing_of.law.to_html`).toString();
    $("demo").innerHTML = vm.eval(`Physics.shown(${shows.law}).showing_of.to_html(${reading()})`).toString();

    // Re-rendering draws the controls back at their declared start, so where
    // they had been dragged to is put back.
    held.forEach(([ name, value ]) => {
      const control = document.querySelector(`#demo [data-vary="${name}"]`);
      if (control) control.value = value;
    });

    vm.eval(`def surface = Physics.shown(${shows.law}).new(**Console.inputs)`);
    move();
  };

  if (shows) $("demo").addEventListener("input", (event) => {
    if (event.target.dataset.vary) move();
  });

  const evaluate = () => {
    editor.remember();
    const sources = loaded.map((file) => file.code);

    // Nothing is taken away until everything parses, so a half-typed law
    // leaves the working one standing.
    sources.forEach((source) => {
      const bad = vm.eval(`Reload.check(${asRubyString(source)})`).toString();
      if (bad) throw new Error(bad);

      declared(source).forEach((name) => defined.add(name));
    });

    vm.eval(`Reload.forget(${JSON.stringify([ ...defined ])})`);
    sources.forEach((source) => vm.eval(source));
    vm.eval(CONSOLE);
    if (harness) vm.eval(harness);
    present();
  };

  let booting = false;

  const rerun = () => {
    try {
      evaluate();
      view.refresh();
    } catch (error) {
      say(String(error).split("\n")[0], true);
    }
  };

  const boot = async () => {
    if (vm || booting) return;
    booting = true;
    try {
      run.disabled = true;
      say("Fetching CRuby…");
      vm = await loadVM(say);
      vm.eval(SHIM);
      vm.eval(RELOAD);
      vm.eval("Reload.remember");
      evaluate();
      run.textContent = "Re-run the laws";
      if (reset) reset.hidden = false;
      view.refresh();
      repl.clear();
      repl.ask("RUBY_VERSION");
      opening.forEach((line) => repl.ask(line));
    } catch (error) {
      say(String(error).split("\n")[0], true);
    } finally {
      booting = false;
      run.disabled = false;
    }
  };

  if (opening.length) {
    repl.note(`Press “Run in Ruby” to boot, then try:  ${opening[opening.length - 1]}`);
  }

  run.addEventListener("click", () => (vm ? rerun() : boot()));

  if (reset) {
    reset.addEventListener("click", () => {
      editor.reset();
      if (vm) rerun();
    });
  }

  // Auto-run waits for a pause in typing, because a law is a syntax error for
  // most of the time it takes to write one.
  const auto = $("auto");
  if (auto) {
    let pending = null;
    auto.checked = autoRun();
    auto.addEventListener("change", () => {
      autoRun(auto.checked);
      if (auto.checked) (vm ? rerun() : boot());
    });

    $("source").addEventListener("input", () => {
      if (!auto.checked || !vm || booting) return;
      clearTimeout(pending);
      say("Waiting for you to stop typing…");
      pending = setTimeout(rerun, 700);
    });

    if (auto.checked) boot();
  }

  return view;
}
