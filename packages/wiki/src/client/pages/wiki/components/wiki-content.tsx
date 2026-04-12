/**
 * @file Central content area: Markdown rendering with source badges.
 */

import { useCallback } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import rehypeSlug from "rehype-slug";
import { Link } from "react-router";
import { MermaidDiagram } from "../../../components/shared/mermaid-diagram.tsx";
import { KgfCodeBlock } from "../../../components/shared/kgf-code-block.tsx";
import { SourceBadge } from "./source-badge.tsx";
import type { WikiPage } from "@indexion/api-client";
import { useDict } from "../../../i18n/index.ts";

type Props = {
  readonly page: WikiPage;
};

export const WikiContent = ({ page }: Props): React.JSX.Element => {
  const d = useDict();
  const renderPre = useCallback(
    (
      props: React.HTMLAttributes<HTMLPreElement> & {
        children?: React.ReactNode;
      },
    ) => {
      const child = Array.isArray(props.children)
        ? props.children[0]
        : props.children;
      const isMermaid =
        child != null &&
        typeof child === "object" &&
        "props" in child &&
        /language-mermaid/.test(child.props?.className ?? "");
      if (isMermaid) {
        // Mermaid handles its own container — render children directly without <pre> wrapper
        return <>{props.children}</>;
      }
      return (
        <pre {...props} className="overflow-x-auto rounded-lg bg-muted p-4">
          {props.children}
        </pre>
      );
    },
    [],
  );

  const renderCode = useCallback(
    (
      props: React.HTMLAttributes<HTMLElement> & {
        children?: React.ReactNode;
        className?: string;
      },
    ) => {
      const match = /language-mermaid/.exec(props.className ?? "");
      if (match) {
        const code = String(props.children).replace(/\n$/, "");
        return <MermaidDiagram code={code} className="my-4" />;
      }
      return <KgfCodeBlock {...props} />;
    },
    [],
  );

  const renderLink = useCallback(
    (props: React.AnchorHTMLAttributes<HTMLAnchorElement>) => {
      const href = props.href ?? "";
      if (href.startsWith("wiki://")) {
        const pageId = href.slice(7);
        return <Link to={`/wiki/${pageId}`}>{props.children}</Link>;
      }
      return <a {...props} />;
    },
    [],
  );

  return (
    <article className="mx-auto w-full max-w-3xl px-4 py-4 md:px-8 md:py-6">
      {page.sources.length > 0 && (
        <details className="mb-4">
          <summary className="cursor-pointer text-xs text-muted-foreground">
            {d.wiki_source_files}
          </summary>
          <div className="mt-2 flex flex-wrap gap-2">
            {page.sources.map((src) => (
              <SourceBadge key={src.file} source={src} />
            ))}
          </div>
        </details>
      )}

      <div className="prose dark:prose-invert max-w-none prose-headings:scroll-mt-16 prose-pre:p-0 prose-pre:bg-transparent">
        <ReactMarkdown
          remarkPlugins={[remarkGfm]}
          rehypePlugins={[rehypeSlug]}
          components={{ pre: renderPre, a: renderLink, code: renderCode }}
        >
          {page.content}
        </ReactMarkdown>
      </div>
    </article>
  );
};
