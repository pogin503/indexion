/**
 * @file JSX intrinsic element declarations for @vscode-elements/elements.
 *
 * React 19 uses React.JSX namespace for custom element types.
 * Must use `interface` (not `type`) so TypeScript merges these entries
 * into the existing IntrinsicElements interface instead of replacing it.
 */

import type {
  VscodeTextfield,
  VscodeTree,
  VscodeTreeItem,
  VscodeCollapsible,
  VscodeIcon,
  VscodeBadge,
  VscodeScrollable,
  VscodeDivider,
  VscodeButton,
  VscodeSingleSelect,
  VscodeOption,
  VscodeLabel,
  VscodeCheckbox,
  VscodeProgressBar,
  VscodeTabs,
  VscodeTabHeader,
  VscodeTabPanel,
  VscodeFormGroup,
  VscodeFormHelper,
} from "@vscode-elements/elements";

type WC<E, A = object> = React.DetailedHTMLProps<React.HTMLAttributes<E>, E> & A;

declare module "react" {
  namespace JSX {
    interface IntrinsicElements {
      "vscode-textfield": WC<
        VscodeTextfield,
        {
          value?: string;
          placeholder?: string;
          type?: string;
          disabled?: boolean;
          readonly?: boolean;
          required?: boolean;
          autofocus?: boolean;
          min?: string | number;
          max?: string | number;
          step?: string | number;
        }
      >;
      "vscode-tree": WC<VscodeTree, { indent?: number; "indent-guides"?: string }>;
      "vscode-tree-item": WC<
        VscodeTreeItem,
        { label?: string; branch?: boolean; open?: boolean; selected?: boolean; active?: boolean }
      >;
      "vscode-collapsible": WC<VscodeCollapsible, { heading?: string; description?: string; open?: boolean }>;
      "vscode-icon": WC<VscodeIcon, { name?: string; size?: number; spin?: boolean; "spin-duration"?: number }>;
      "vscode-badge": WC<VscodeBadge, { variant?: string }>;
      "vscode-scrollable": WC<VscodeScrollable, { shadow?: boolean }>;
      "vscode-divider": WC<VscodeDivider, { role?: string }>;
      "vscode-button": WC<
        VscodeButton,
        { disabled?: boolean; secondary?: boolean; icon?: boolean; appearance?: string }
      >;
      "vscode-single-select": WC<VscodeSingleSelect, { value?: string }>;
      "vscode-option": WC<VscodeOption, { value?: string; selected?: boolean; disabled?: boolean }>;
      "vscode-label": WC<VscodeLabel>;
      "vscode-checkbox": WC<
        VscodeCheckbox,
        {
          checked?: boolean;
          disabled?: boolean;
          value?: string;
          label?: string;
          name?: string;
          required?: boolean;
          indeterminate?: boolean;
          autofocus?: boolean;
        }
      >;
      "vscode-progress-bar": WC<
        VscodeProgressBar,
        {
          value?: number;
          max?: number;
          indeterminate?: boolean;
        }
      >;
      "vscode-tabs": WC<
        VscodeTabs,
        {
          panel?: boolean;
          "selected-index"?: number;
        }
      >;
      "vscode-tab-header": WC<VscodeTabHeader, { active?: boolean; panel?: boolean }>;
      "vscode-tab-panel": WC<VscodeTabPanel, { hidden?: boolean; panel?: boolean }>;
      "vscode-form-group": WC<
        VscodeFormGroup,
        { variant?: "horizontal" | "vertical" | "settings-group" }
      >;
      "vscode-form-helper": WC<VscodeFormHelper>;
    }
  }
}
