/**
 * @file Code block with KGF-based syntax highlighting.
 *
 * Extracts language from className (e.g. "language-typescript")
 * and passes it to useKgfHighlight, which fetches the matching
 * KGF spec via the injected KgfSpecProvider.
 *
 * No hardcoded language aliases — spec resolution is the
 * responsibility of the fetchSpec implementation.
 */

import { useMemo } from "react";
import { useKgfHighlight } from "./use-kgf-highlight.ts";

function extractLang(className: string | undefined): string | null {
  const match = /language-(\S+)/.exec(className ?? "");
  return match ? match[1]! : null;
}

type Props = React.HTMLAttributes<HTMLElement> & {
  children?: React.ReactNode;
  className?: string;
};

export const KgfCodeBlock = (props: Props): React.JSX.Element => {
  const lang = useMemo(() => extractLang(props.className), [props.className]);
  const code = String(props.children).replace(/\n$/, "");
  const { segments } = useKgfHighlight(lang, code);

  return (
    <code className={props.className}>
      {segments.map((seg, i) =>
        seg.color ? (
          <span key={i} style={{ color: seg.color }}>
            {seg.text}
          </span>
        ) : (
          <span key={i}>{seg.text}</span>
        ),
      )}
    </code>
  );
};
