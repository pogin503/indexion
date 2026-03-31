export type FolderEntry = {
  path: string;
  name: string;
  children: FolderEntry[];
  files: FileEntry[];
};

export type FileEntry = {
  path: string;
  name: string;
  symbols: SymEntry[];
};

export type SymEntry = {
  id: string;
  name: string;
  kind: string;
};
