export function normalizePath(input: string): string {
  return input.replaceAll("\\", "/");
}

export const defaultFormat = "json";
