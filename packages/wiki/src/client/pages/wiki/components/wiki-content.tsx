/**
 * @file Central content area: Markdown rendering with source badges.
 */

import { useEffect, useRef, useCallback } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import rehypeSlug from "rehype-slug";
import rehypeHighlight from "rehype-highlight";
import { Link } from "react-router";
import { ScrollArea } from "../../../components/ui/scroll-area.tsx";
import { SourceBadge } from "./source-badge.tsx";
import type { WikiPage } from "@indexion/api-client";

type Props = {
  readonly page: WikiPage;
};

export const WikiContent = ({ page }: Props): React.JSX.Element => {
  const contentRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!contentRef.current) return;
    const codeBlocks = contentRef.current.querySelectorAll("pre code.language-mermaid");
    for (const block of codeBlocks) {
      const pre = block.parentElement;
      if (!pre || pre.dataset.rendered === "true") continue;
      pre.dataset.rendered = "true";
      const code = block.textContent ?? "";
      const container = document.createElement("div");
      container.className = "my-4";
      pre.replaceWith(container);
      import("mermaid").then(({ default: mermaid }) => {
        mermaid.initialize({ startOnLoad: false, theme: "dark" });
        const id = `mermaid-${Math.random().toString(36).slice(2)}`;
        mermaid.render(id, code).then(({ svg }) => {
          container.innerHTML = svg;
        });
      });
    }
  }, [page.content]);

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
    <ScrollArea className="h-full">
      <article ref={contentRef} className="mx-auto max-w-3xl px-8 py-6">
        {page.sources.length > 0 && (
          <details className="mb-4">
            <summary className="cursor-pointer text-xs text-muted-foreground">
              Relevant source files
            </summary>
            <div className="mt-2 flex flex-wrap gap-2">
              {page.sources.map((src) => (
                <SourceBadge key={src.file} source={src} />
              ))}
            </div>
          </details>
        )}

        <div className="prose prose-invert max-w-none prose-headings:scroll-mt-16 prose-pre:bg-muted prose-code:text-sm">
          <ReactMarkdown
            remarkPlugins={[remarkGfm]}
            rehypePlugins={[rehypeSlug, rehypeHighlight]}
            components={{ a: renderLink }}
          >
            {page.content}
          </ReactMarkdown>
        </div>
      </article>
    </ScrollArea>
  );
};
