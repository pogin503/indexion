/**
 * @file Configuration section component for the settings panel.
 */

import React from "react";
import type { SettingsConfig } from "../../../panels/settings/messages.ts";
import layout from "../../components/sidebar-layout.module.css";
import styles from "./config-section.module.css";

type ConfigSectionProps = {
  readonly config: SettingsConfig;
  readonly onChange: (config: SettingsConfig) => void;
  readonly onSave: (config: SettingsConfig) => void;
};

export const ConfigSection = ({ config, onChange, onSave }: ConfigSectionProps): React.JSX.Element => {
  const handleChange = (key: keyof SettingsConfig, value: string | number): void => {
    onChange({ ...config, [key]: value });
  };

  return (
    <div className={styles.section}>
      <vscode-form-group variant="vertical">
        <vscode-label>Binary Path</vscode-label>
        <vscode-textfield
          value={config.binaryPath}
          placeholder="auto-detect"
          onInput={(e: React.FormEvent) => handleChange("binaryPath", (e.target as HTMLInputElement).value)}
        />
        <vscode-form-helper>Leave empty to auto-detect from PATH</vscode-form-helper>
      </vscode-form-group>

      <vscode-form-group variant="vertical">
        <vscode-label>KGF Specs Directory</vscode-label>
        <vscode-textfield
          value={config.specsDir}
          onInput={(e: React.FormEvent) => handleChange("specsDir", (e.target as HTMLInputElement).value)}
        />
      </vscode-form-group>

      <vscode-form-group variant="vertical">
        <vscode-label>Default Threshold</vscode-label>
        <vscode-textfield
          type="number"
          min="0"
          max="1"
          step="0.05"
          value={String(config.defaultThreshold)}
          onInput={(e: React.FormEvent) =>
            handleChange("defaultThreshold", Number((e.target as HTMLInputElement).value))
          }
        />
      </vscode-form-group>

      <vscode-form-group variant="vertical">
        <vscode-label>Default Strategy</vscode-label>
        <vscode-single-select
          value={config.defaultStrategy}
          onChange={(e: React.FormEvent) => handleChange("defaultStrategy", (e.target as HTMLSelectElement).value)}
        >
          <vscode-option value="tfidf">TF-IDF</vscode-option>
          <vscode-option value="ncd">NCD</vscode-option>
          <vscode-option value="hybrid">Hybrid</vscode-option>
          <vscode-option value="apted">APTED</vscode-option>
          <vscode-option value="tsed">TSED</vscode-option>
        </vscode-single-select>
      </vscode-form-group>

      <vscode-button onClick={() => onSave(config)} className={layout.alignStart}>
        Save
      </vscode-button>
    </div>
  );
};
