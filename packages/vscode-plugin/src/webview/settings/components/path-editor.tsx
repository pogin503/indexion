/**
 * @file Reusable path input component with browse button.
 */

import React from "react";

type PathEditorProps = {
  readonly label: string;
  readonly value: string;
  readonly placeholder?: string;
  readonly hint?: string;
  readonly onChange: (value: string) => void;
};

export const PathEditor = ({ label, value, placeholder, hint, onChange }: PathEditorProps): React.JSX.Element => (
  <vscode-form-group variant="vertical">
    <vscode-label>{label}</vscode-label>
    <vscode-textfield
      value={value}
      placeholder={placeholder}
      onInput={(e: React.FormEvent) => onChange((e.target as HTMLInputElement).value)}
    />
    {hint && <vscode-form-helper>{hint}</vscode-form-helper>}
  </vscode-form-group>
);
