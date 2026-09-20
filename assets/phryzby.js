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

function mountEditor(files, { tabs, pre, textarea }) {
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
  return { remember, reset: (restore) => {
    files.forEach((file) => { file.code = restore(file); });
    show(active);
  } };
}

// --- the page --------------------------------------------------------------

async function fetchRuby(files) {
  return Promise.all(files.map(async (file) => ({
    ...file,
    label: file.label || file.path.split("/").pop(),
    code: (await fetch(file.path).then((r) => r.text())).trimEnd(),
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
export async function chapter({ files, harness = "", onSolve }) {
  const status = $("status");
  const run = $("run");
  const reset = $("reset");
  const say = (text, bad = false) => {
    status.textContent = text;
    status.classList.toggle("err", bad);
  };

  // Evaluated in the order given, because that is the order the requires
  // imply. Shown in `tab` order, and not shown at all when `hidden` — the
  // engine has to be loaded on every page but has its own page to be read on.
  const loaded = await fetchRuby(files);
  const originals = loaded.map((file) => file.code);
  const tabbed = loaded.filter((file) => !file.hidden)
    .map((file, index) => ({ file, at: file.tab ?? index }))
    .sort((a, b) => a.at - b.at).map((entry) => entry.file);
  const editor = mountEditor(tabbed, { tabs: $("tabs"), pre: $("highlight"), textarea: $("source") });

  let vm = null;
  const page = {
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
      if (vm) { evaluate(); page.refresh(); return; }
      run.disabled = true;
      say("Fetching CRuby…");
      vm = await loadVM(say);
      vm.eval(SHIM);
      evaluate();
      run.textContent = "Re-run the laws";
      run.disabled = false;
      if (reset) reset.hidden = false;
      page.refresh();
    } catch (error) {
      say(String(error).split("\n")[0], true);
      run.disabled = false;
    }
  });

  if (reset) {
    reset.addEventListener("click", () => {
      editor.reset((file) => originals[loaded.indexOf(file)]);
      if (vm) { evaluate(); page.refresh(); }
    });
  }

  return page;
}
