/**
 * @file Mock for the 'vscode' module used in extension host tests.
 *
 * Provides minimal implementations of VSCode APIs so that
 * pure logic in bridge, config, providers, and views can be tested.
 *
 * All implementations are function-based (no classes) to comply with
 * project ESLint rules. Each mock returns plain objects matching the
 * VSCode API shape that tests rely on.
 */

/** VSCode Position value. */
export type Position = { readonly line: number; readonly character: number };

/** Create a Position. */
export const Position = function createPosition(line: number, character: number): Position {
  return { line, character };
} as unknown as { new (line: number, character: number): Position };

/** VSCode Range value. */
export type Range = { readonly start: Position; readonly end: Position };

/** Range constructor options. */
type RangeArgs = {
  readonly start: Position | number;
  readonly end: Position | number;
  readonly startChar?: number;
  readonly endChar?: number;
};

/** Create a Range from positions or line numbers. */
const createRange = (args: RangeArgs): Range => {
  if (typeof args.start === "number") {
    return {
      start: { line: args.start, character: args.startChar ?? 0 },
      end: { line: args.end as number, character: args.endChar ?? 0 },
    };
  }
  return { start: args.start as Position, end: args.end as Position };
};

export const Range = function rangeConstructor(
  ...args: [RangeArgs] | [Position | number, Position | number, number?, number?]
): Range {
  if (args.length === 1) {
    return createRange(args[0]);
  }
  return createRange({ start: args[0], end: args[1], startChar: args[2], endChar: args[3] });
} as unknown as { new (start: Position | number, end: Position | number, startChar?: number, endChar?: number): Range };

/** VSCode DocumentSymbol value. */
export type DocumentSymbol = {
  readonly name: string;
  readonly detail: string;
  readonly kind: SymbolKind;
  readonly range: Range;
  readonly selectionRange: Range;
  children: DocumentSymbol[];
};

/** DocumentSymbol constructor options. */
type DocumentSymbolOptions = {
  readonly name: string;
  readonly detail: string;
  readonly kind: SymbolKind;
  readonly range: Range;
  readonly selectionRange: Range;
};

/** Create a DocumentSymbol from positional args (VSCode compat) or options. */
const createDocumentSymbol = (opts: DocumentSymbolOptions): DocumentSymbol => ({
  name: opts.name,
  detail: opts.detail,
  kind: opts.kind,
  range: opts.range,
  selectionRange: opts.selectionRange,
  children: [],
});

export const DocumentSymbol = function documentSymbolConstructor(
  ...args: [DocumentSymbolOptions] | [string, string, SymbolKind, Range, Range]
): DocumentSymbol {
  if (args.length === 1) {
    return createDocumentSymbol(args[0]);
  }
  return createDocumentSymbol({
    name: args[0],
    detail: args[1],
    kind: args[2],
    range: args[3],
    selectionRange: args[4],
  });
} as unknown as {
  new (name: string, detail: string, kind: SymbolKind, range: Range, selectionRange: Range): DocumentSymbol;
};

/** VSCode symbol kinds. */
export enum SymbolKind {
  File = 0,
  Module = 1,
  Namespace = 2,
  Package = 3,
  Class = 4,
  Method = 5,
  Property = 6,
  Field = 7,
  Constructor = 8,
  Enum = 9,
  Interface = 10,
  Function = 11,
  Variable = 12,
  Constant = 13,
  String = 14,
  Number = 15,
  Boolean = 16,
  Array = 17,
  Object = 18,
  Key = 19,
  Null = 20,
  EnumMember = 21,
  Struct = 22,
  Event = 23,
  Operator = 24,
  TypeParameter = 25,
}

/** VSCode tree item collapse state. */
export enum TreeItemCollapsibleState {
  None = 0,
  Collapsed = 1,
  Expanded = 2,
}

/** VSCode TreeItem value. */
export type TreeItem = {
  label?: string;
  description?: string;
  iconPath?: unknown;
  contextValue?: string;
  command?: unknown;
  tooltip?: string;
  collapsibleState?: TreeItemCollapsibleState;
};

export const TreeItem = function createTreeItem(label: string, collapsibleState?: TreeItemCollapsibleState): TreeItem {
  return { label, collapsibleState };
} as unknown as { new (label: string, collapsibleState?: TreeItemCollapsibleState): TreeItem };

/** VSCode ThemeIcon value. */
export type ThemeIcon = { readonly id: string };

export const ThemeIcon = function createThemeIcon(id: string): ThemeIcon {
  return { id };
} as unknown as { new (id: string): ThemeIcon };

/** VSCode SemanticTokensLegend value. */
export type SemanticTokensLegend = {
  readonly tokenTypes: string[];
  readonly tokenModifiers: string[];
};

export const SemanticTokensLegend = function createLegend(
  tokenTypes: string[],
  tokenModifiers: string[],
): SemanticTokensLegend {
  return { tokenTypes, tokenModifiers };
} as unknown as { new (tokenTypes: string[], tokenModifiers: string[]): SemanticTokensLegend };

/** Token data entry for the builder. */
type TokenEntry = {
  readonly line: number;
  readonly col: number;
  readonly length: number;
  readonly typeIndex: number;
  readonly modifiers: number;
};

/** VSCode SemanticTokensBuilder value. */
export type SemanticTokensBuilder = {
  readonly legend?: SemanticTokensLegend;
  push(entry: TokenEntry): void;
  build(): { readonly data: Uint32Array };
};

export const SemanticTokensBuilder = function createBuilder(legend?: SemanticTokensLegend): SemanticTokensBuilder {
  const data: TokenEntry[] = [];
  return {
    legend,
    push(entry: TokenEntry) {
      data.push(entry);
    },
    build() {
      return { data: new Uint32Array(data.length * 5) };
    },
  };
} as unknown as { new (legend?: SemanticTokensLegend): SemanticTokensBuilder };

/** VSCode CodeLens value. */
export type CodeLens = { readonly range: Range; readonly command?: unknown };

export const CodeLens = function createCodeLens(range: Range, command?: unknown): CodeLens {
  return { range, command };
} as unknown as { new (range: Range, command?: unknown): CodeLens };

/** VSCode progress location. */
export enum ProgressLocation {
  Notification = 15,
}

/** VSCode EventEmitter mock. */
export type EventEmitter<T> = {
  event: (handler: (e: T) => void) => { dispose: () => void };
  fire: (data: T) => void;
};

export const EventEmitter = function createEventEmitter<T>(): EventEmitter<T> {
  const handlers: Array<(e: T) => void> = [];
  return {
    event: (handler: (e: T) => void) => {
      handlers.push(handler);
      return { dispose: () => {} };
    },
    fire: (data: T) => {
      for (const h of handlers) {
        h(data);
      }
    },
  };
} as unknown as { new <T>(): EventEmitter<T> };

/** Disposable helper. */
const disposable = (): { dispose: () => void } => ({ dispose: () => {} });

/** VSCode workspace mock. */
export const workspace = {
  getConfiguration: (_section?: string) => ({
    get: <T>(_key: string, defaultValue: T): T => defaultValue,
  }),
  workspaceFolders: undefined as ReadonlyArray<{ uri: { fsPath: string } }> | undefined,
  openTextDocument: async () => ({}),
};

/** VSCode window mock. */
export const window = {
  withProgress: async <T>(
    _options: unknown,
    task: (
      _progress: unknown,
      token: { isCancellationRequested: boolean; onCancellationRequested: () => { dispose: () => void } },
    ) => Promise<T>,
  ): Promise<T> => task({}, { isCancellationRequested: false, onCancellationRequested: () => disposable() }),
  showErrorMessage: async (_msg: string) => undefined,
  showInformationMessage: async (_msg: string) => undefined,
  showQuickPick: async (items: unknown[]) => items[0],
  showInputBox: async (_options: unknown) => "",
  showOpenDialog: async (_options: unknown) => undefined,
  showTextDocument: async () => undefined,
  registerTreeDataProvider: () => disposable(),
  registerWebviewViewProvider: () => disposable(),
  createWebviewPanel: () => ({
    webview: {
      html: "",
      onDidReceiveMessage: () => disposable(),
      asWebviewUri: (uri: unknown) => uri,
      postMessage: () => true,
    },
    reveal: () => {},
    onDidDispose: () => disposable(),
    dispose: () => {},
  }),
  createOutputChannel: (_name: string) => ({
    appendLine: (_msg: string) => {},
    append: (_msg: string) => {},
    clear: () => {},
    show: () => {},
    hide: () => {},
    dispose: () => {},
  }),
};

/** VSCode commands mock. */
export const commands = {
  registerCommand: (_id: string, _handler: unknown) => disposable(),
  executeCommand: async (_command: string, ..._args: unknown[]) => undefined,
  getCommands: async () => [] as string[],
};

/** VSCode languages mock. */
export const languages = {
  registerDocumentSymbolProvider: (_selector: unknown, _provider: unknown) => disposable(),
  registerDocumentSemanticTokensProvider: (_selector: unknown, _provider: unknown, _legend: unknown) => disposable(),
  registerCodeLensProvider: (_selector: unknown, _provider: unknown) => disposable(),
};

/** VSCode Uri mock. */
export const Uri = {
  file: (path: string) => ({ fsPath: path, toString: () => `file://${path}`, scheme: "file" }),
  joinPath: (base: { fsPath?: string }, ...segments: string[]) => {
    const joined = [base.fsPath ?? "", ...segments].join("/");
    return { fsPath: joined, toString: () => `file://${joined}`, scheme: "file" };
  },
};

/** VSCode env mock. */
export const env = {
  clipboard: {
    writeText: async (_text: string) => {},
  },
};
