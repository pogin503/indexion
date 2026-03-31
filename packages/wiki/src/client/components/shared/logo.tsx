/**
 * indexion logo — Single Source of Truth for the "ix" glyph paths.
 *
 * The original SVG (logo.svg) uses viewBox="0 0 208 290" with white fill on
 * transparent. The glyph ink bounds are:
 *   - "i" dot:   Y 68–91
 *   - body:      Y 120–235
 *   - bg blocks: full height (used as negative-space counters)
 *
 * Consumers control size via className (e.g. h-5). fill defaults to
 * currentColor so it adapts to light/dark themes automatically.
 */

const IX_PATHS = [
  // "x" glyph + right background block
  "M71 289.28V0H207.96V289.28H71ZM150.872 234.752H201.048V220.16H186.712L150.104 176.896L185.688 135.424H199V120.832H153.432V135.424H167L140.632 167.68L115.032 135.424H130.392V120.832H78.424V135.424H93.784L129.88 177.92L94.04 220.16H78.424V234.752H125.784V220.16H112.216L139.096 187.392L165.72 220.16H150.872V234.752Z",
  // "i" glyph + left background block
  "M0 289.28V0H77.056V289.28H0ZM29.44 68.096V91.392H48.896V68.096H29.44ZM11.264 234.752H69.12V220.16H49.152V120.832H10.752V135.424H31.232V220.16H11.264V234.752Z",
] as const;

type Props = {
  readonly className?: string;
};

export const Logo = ({ className = "h-5" }: Props): React.JSX.Element => (
  <svg
    className={`w-auto ${className}`}
    viewBox="0 0 208 290"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    aria-label="indexion"
  >
    {IX_PATHS.map((d, i) => (
      <path key={i} d={d} fill="currentColor" />
    ))}
  </svg>
);
