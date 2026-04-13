/**
 * @file Dev entry point for testing KgfCodeBlock in isolation.
 *
 * Run `bun run dev` to start the Vite dev server.
 * Bundled specs: typescript.kgf (exact match) and universal.kgf (fallback).
 * Languages without an exact spec fall back to universal highlighting.
 */

import { useCallback } from "react";
import ReactDOM from "react-dom/client";
import { KgfSpecProvider } from "./highlight-context.ts";
import { KgfCodeBlock } from "./kgf-code-block.tsx";
import specTs from "./dev-spec.kgf?raw";
import specUniversal from "./dev-universal.kgf?raw";

const SAMPLES: ReadonlyArray<{
  lang: string;
  label: string;
  code: string;
}> = [
  {
    lang: "typescript",
    label: "TypeScript (exact spec)",
    code: `function greet(name: string): string {
  const msg = \`Hello, \${name}!\`;
  console.log(msg);
  return msg;
}

type Result<T> = { ok: true; value: T } | { ok: false; error: string };`,
  },
  {
    lang: "typescript",
    label: "TypeScript — async (exact spec)",
    code: `async function fetchData(url: string): Promise<Response> {
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(\`HTTP \${res.status}\`);
  }
  return res;
}`,
  },
  {
    lang: "python",
    label: "Python (no exact spec → universal fallback)",
    code: `def fibonacci(n: int) -> list[int]:
    a, b = 0, 1
    result = []
    for _ in range(n):
        result.append(a)
        a, b = b, a + b
    return result`,
  },
  {
    lang: "unknown-lang",
    label: "Unknown language (→ universal fallback)",
    code: `{ "key": "value", "count": 42 }`,
  },
];

const SPECS: Record<string, string> = {
  typescript: specTs,
  universal: specUniversal,
};

const App = (): React.JSX.Element => {
  const fetchSpec = useCallback(
    async (lang: string): Promise<string | null> => SPECS[lang] ?? null,
    [],
  );

  return (
    <KgfSpecProvider value={fetchSpec}>
      <div style={styles.root}>
        <h1 style={styles.title}>Syntax Highlight — Dev</h1>
        <p style={styles.subtitle}>
          Specs: <code>typescript</code> (exact), <code>universal</code>{" "}
          (fallback). Languages without an exact spec get universal
          highlighting.
        </p>
        {SAMPLES.map((s, i) => (
          <section key={i} style={styles.section}>
            <h2 style={styles.sectionTitle}>{s.label}</h2>
            <pre style={styles.codeBlock}>
              <KgfCodeBlock className={`language-${s.lang}`}>
                {s.code}
              </KgfCodeBlock>
            </pre>
          </section>
        ))}
      </div>
    </KgfSpecProvider>
  );
};

const styles = {
  root: {
    maxWidth: 800,
    margin: "0 auto",
    padding: 24,
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
    color: "#e0e0e0",
    background: "#1a1a2e",
    minHeight: "100vh",
  },
  title: { fontSize: 24, marginBottom: 4 },
  subtitle: { fontSize: 13, color: "#888", marginBottom: 24 },
  section: { marginBottom: 32 },
  sectionTitle: { fontSize: 16, marginBottom: 8, color: "#aaa" },
  codeBlock: {
    background: "#0d1117",
    padding: "12px 16px",
    borderRadius: 6,
    overflow: "auto" as const,
    fontSize: 14,
    lineHeight: 1.5,
    fontFamily: "ui-monospace, SFMono-Regular, monospace",
  },
} as const;

const root = document.getElementById("root");
if (root) {
  ReactDOM.createRoot(root).render(<App />);
}
