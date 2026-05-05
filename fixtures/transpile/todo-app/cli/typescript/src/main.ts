import { runCli } from "./cli.ts";

function main(): void {
  const argv = process.argv.slice(2);
  const storePath = process.env.TODO_STORE ?? ".todo-store.json";
  const now = new Date().toISOString();
  const result = runCli(argv, storePath, now);
  process.stdout.write(result.output + "\n");
  process.exit(result.exitCode);
}

main();
