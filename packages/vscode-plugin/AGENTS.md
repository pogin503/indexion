# Agent Policy

## Package Management

- Use bun as the package manager.

## Development Workflow

- Run lint, typecheck, and test commands as appropriate during development.

## Debugging Approach

- To avoid assumptions, read related files when you become confused.
- Also, add notes to the end of this file explaining why you needed to read those files.
- In many cases, this timing coincides with when you feel like writing type casts (such as "as any").

## Tests

- Colocate unit specs with implementations using [name].spec.ts to increase cohesion: placement/, runtime/, helpers/.
- Place integration or combined end-to-end specs under spec/ as [purpose].spec.ts.
- Keep unit tests close to the code-under-test; use spec/ only for cross-module scenarios.

## Lint Rules

- Follow project rules strictly: always use braces; never use && as a ternary; avoid let; prefer guards and explicit types.
- Treat warnings as actionable; fix them proactively whenever feasible.

## Advice Policy

- Do not propose improvements unless explicitly requested by the user.
- When you detect major negligence, significant oversights, or potentially buggy behavior, issue a clear warning.

## Runners

- Select runners based on package.json's packageManager field.
- If packageManager starts with bun, use `bun run <script>` (e.g., `bun run lint`, `bun run typecheck`, `bun run test`).
- **NEVER use `bun test` directly.** `bun test` invokes Bun's built-in test runner, NOT the project's test framework (vitest). Always use `bun run test` to execute the `test` script defined in package.json.
- If using npm, pnpm, or yarn, invoke the equivalent via their native runner (e.g., pnpm run test, npm run typecheck).
- Prefer invoking scripts defined in package.json over ad-hoc binaries to honor workspace tooling.

## Temp Files

- Use ephemeral files named [name].tmp.ts for exploratory checks or one-off validations.
- Remove .tmp files immediately after use to keep the tree clean.
- When a useful check is validated in a .tmp file, promote it into a proper \*.spec.ts (co-located or under spec/) to prevent regressions.

## Testing Guidelines

- When creating unit test files, place [name].spec.ts in the same location as the target file.
- For complex unit tests involving multiple files, place them in the spec folder and name the file according to the test purpose.
- Coverage should be reasonable, but consider anything that lacks comprehensive coverage to be of generally low quality.

## No Magic Policy

- 実装は「よしなに」動かさず、必ず明示的な引数を要求し、不足時は throw します。環境変数（OPENAI_API_KEY, OPENAI_MODEL）はライブラリ内部で直接参照せず、src/index.ts からの注入に限定します。依存導入とスクリプトは bun を利用し、lint と typecheck を常に実行して通すこと。ロジックは一気に書かず、機能ごとにファイルを分離します（例: prompts, json-schema, response-extract, types, fake-sql）。
