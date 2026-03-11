/** Public reconcile configuration. */
export interface ReconcileConfig {
  rootDir: string;
}

/** Build the graph for the configured root. */
export function buildGraph(config: ReconcileConfig): string {
  return config.rootDir;
}

/** Render reports for human review. */
export class ReportRenderer {
  render(): string {
    return "ok";
  }
}
