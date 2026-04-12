/**
 * @file Settings app component, extracted for testability.
 */

import React, { useEffect, useState } from "react";
import type { SettingsToWebview, SettingsFromWebview, SettingsConfig } from "../../panels/settings/messages.ts";
import { usePostMessage, useWebviewMessage } from "../bridge/context.tsx";
import { ConfigSection } from "./components/config-section.tsx";
import styles from "./app.module.css";

const DEFAULT_CONFIG: SettingsConfig = {
  binaryPath: "",
  specsDir: "kgfs",
  defaultThreshold: 0.7,
  defaultStrategy: "tfidf",
  includes: [],
  excludes: [],
};

export const SettingsApp = (): React.JSX.Element => {
  const postMessage = usePostMessage<SettingsFromWebview>();
  const [globalConfig, setGlobalConfig] = useState<SettingsConfig>(DEFAULT_CONFIG);
  const [localConfig, setLocalConfig] = useState<SettingsConfig>(DEFAULT_CONFIG);
  const [activeTab, setActiveTab] = useState<"global" | "local">("local");
  const [saveStatus, setSaveStatus] = useState<string>("");

  useWebviewMessage<SettingsToWebview>((message) => {
    if (message.type === "configLoaded") {
      setGlobalConfig(message.global);
      setLocalConfig(message.local);
    }
    if (message.type === "saved") {
      setSaveStatus(message.success ? "Saved!" : "Failed to save");
      setTimeout(() => setSaveStatus(""), 2000);
    }
  });

  useEffect(() => {
    postMessage({ type: "load" });
  }, [postMessage]);

  const handleSave = (scope: "global" | "local", config: SettingsConfig): void => {
    postMessage({ type: "save", scope, config });
  };

  return (
    <div className={styles.container}>
      <h1 className={styles.title}>indexion Settings</h1>
      <div className={styles.tabs}>
        <button
          className={`${styles.tab} ${activeTab === "local" ? styles.tabActive : ""}`}
          onClick={() => setActiveTab("local")}
          type="button"
        >
          Local (.indexion/)
        </button>
        <button
          className={`${styles.tab} ${activeTab === "global" ? styles.tabActive : ""}`}
          onClick={() => setActiveTab("global")}
          type="button"
        >
          Global
        </button>
      </div>
      {saveStatus && <div className={styles.status}>{saveStatus}</div>}
      <ConfigSection
        config={activeTab === "global" ? globalConfig : localConfig}
        onChange={(config) => {
          if (activeTab === "global") {
            setGlobalConfig(config);
          } else {
            setLocalConfig(config);
          }
        }}
        onSave={(config) => handleSave(activeTab, config)}
      />
    </div>
  );
};
