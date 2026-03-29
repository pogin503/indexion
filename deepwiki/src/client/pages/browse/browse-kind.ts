export const kindBadgeClass = (kind: string): string => {
  switch (kind) {
    case "Function": return "bg-blue-500/10 text-blue-400 border-blue-500/20";
    case "Struct": case "Class": return "bg-green-500/10 text-green-400 border-green-500/20";
    case "Enum": case "Variant": return "bg-yellow-500/10 text-yellow-400 border-yellow-500/20";
    case "Trait": case "Interface": return "bg-purple-500/10 text-purple-400 border-purple-500/20";
    default: return "";
  }
};
