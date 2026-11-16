import { run } from "uebersicht";

const CLI = `"$HOME/.local/bin/jot-cli"`;

export const command = `${CLI} agenda --json`;
export const refreshFrequency = 30000;

// Widgets can't be dragged: change top/left here to move it. Desktop icons draw above widgets.
// No backdrop blur: Übersicht's window can't see the wallpaper behind it.
export const className = `
  top: 40px;
  left: 24px;
  width: 300px;
  padding: 14px 16px;
  border-radius: 14px;
  background: rgba(28, 28, 32, 0.92);
  border: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.35);
  color: #f2f2f2;
  font: 13px -apple-system, BlinkMacSystemFont, sans-serif;
`;

// Clicks reload from the CLI right away instead of waiting for the next refresh.
export const updateState = (event, prev) =>
  event.error ? { ...prev, error: String(event.error) } : { output: event.output, error: null };

const SECTIONS = [
  ["overdue", "Overdue", 10],
  ["today", "Today", 10],
  ["upcoming", "Upcoming", 6],
  ["todo", "To do", 6],
];

const s = {
  title: { fontSize: 11, fontWeight: 700, letterSpacing: 0.6, opacity: 0.6, margin: "10px 0 4px" },
  row: { display: "flex", alignItems: "baseline", gap: 8, padding: "2px 0" },
  box: { cursor: "pointer", width: 14, flex: "none" },
  body: { flex: 1, lineHeight: 1.35 },
  when: { fontSize: 11, opacity: 0.65, whiteSpace: "nowrap" },
};

const Row = ({ item, urgent, dispatch }) => {
  const done = () =>
    run(`${CLI} done ${item.id} && ${CLI} agenda --json`).then((output) => dispatch({ output }));
  return (
    <div style={s.row}>
      {item.todo ? <span style={s.box} onClick={done}>○</span> : <span style={s.box}>·</span>}
      <span style={s.body}>{item.body}</span>
      {item.label && <span style={{ ...s.when, color: urgent ? "#ff7b72" : undefined }}>{item.label}</span>}
    </div>
  );
};

export const render = ({ output, error }, dispatch) => {
  if (error) return <div>jot: {error}</div>;
  let a;
  try {
    a = JSON.parse(output);
  } catch {
    return <div style={{ opacity: 0.6 }}>jot: loading…</div>;
  }
  const shown = SECTIONS.filter(([key]) => a[key] && a[key].length);
  if (!shown.length) return <div style={{ opacity: 0.6 }}>Nothing due</div>;
  return (
    <div>
      {shown.map(([key, title, max]) => (
        <div key={key}>
          <div style={{ ...s.title, color: key === "overdue" ? "#ff7b72" : undefined }}>{title.toUpperCase()}</div>
          {a[key].slice(0, max).map((item) => (
            <Row key={item.id} item={item} urgent={key === "overdue"} dispatch={dispatch} />
          ))}
          {a[key].length > max && <div style={s.when}>+{a[key].length - max} more</div>}
        </div>
      ))}
    </div>
  );
};
