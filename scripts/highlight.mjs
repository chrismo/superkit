#!/usr/bin/env node

// Pre-processes markdown files to replace fenced code blocks with
// Shiki-highlighted HTML. Run before Jekyll so it passes through unchanged.

import fs from "node:fs";
import path from "node:path";
import { createHighlighter } from "shiki";

const GRAMMAR_PATH =
  process.env.SPQ_GRAMMAR_PATH ||
  path.resolve("grammars/spq.tmLanguage.json");

const THEME = "github-dark";

// Map fenced code block language tags to Shiki language IDs.
// Tags not in this map (and not built-in to Shiki) are left untouched.
function mapLang(tag) {
  if (!tag) return "spq"; // untagged blocks in expert-guide are SuperSQL
  if (tag === "sql") return "spq";
  if (tag === "mdtest-command") return "bash";
  if (tag === "mdtest-output") return "spq";
  if (tag === "json lines") return "json";
  if (tag === "text") return null; // leave as plain text
  if (tag.startsWith("mdtest-input")) {
    const filename = tag.slice("mdtest-input".length).trim();
    if (filename.endsWith(".json")) return "json";
    return "spq"; // .sup files and anything else
  }
  // bash, json, etc. — pass through to Shiki built-in
  return tag;
}

// Match fenced code blocks: ```lang\n...\n```
// The lang tag can contain spaces (e.g., "json lines", "mdtest-input za.sup")
const FENCE_RE = /^```([^\n]*)\n([\s\S]*?)^```$/gm;

function processMarkdown(content, highlighter) {
  return content.replace(FENCE_RE, (match, rawTag, code) => {
    const tag = rawTag.trim();
    const lang = mapLang(tag);

    if (lang === null) {
      // Explicitly no highlighting (e.g., "text") — leave as-is
      return match;
    }

    try {
      const html = highlighter.codeToHtml(code, { lang, theme: THEME });
      return html;
    } catch {
      // Unknown language or grammar error — leave block untouched
      return match;
    }
  });
}

async function main() {
  if (!fs.existsSync(GRAMMAR_PATH)) {
    console.error(`Grammar not found at ${GRAMMAR_PATH}`);
    console.error(
      "Set SPQ_GRAMMAR_PATH or place spq.tmLanguage.json in grammars/"
    );
    process.exit(1);
  }

  const spqGrammar = JSON.parse(fs.readFileSync(GRAMMAR_PATH, "utf-8"));

  const highlighter = await createHighlighter({
    themes: [THEME],
    langs: [
      "bash",
      "json",
      {
        ...spqGrammar,
        name: "spq",
      },
    ],
  });

  // Process markdown files in _build/ and _build/tutorials/
  const files = [
    ...fs
      .readdirSync("_build")
      .filter((f) => f.endsWith(".md"))
      .map((f) => path.join("_build", f)),
    ...fs
      .readdirSync("_build/tutorials")
      .filter((f) => f.endsWith(".md"))
      .map((f) => path.join("_build/tutorials", f)),
  ];

  let totalBlocks = 0;
  for (const file of files) {
    const original = fs.readFileSync(file, "utf-8");
    const result = processMarkdown(original, highlighter);

    if (result !== original) {
      const origBlocks = original.match(FENCE_RE)?.length || 0;
      const remainingBlocks = result.match(FENCE_RE)?.length || 0;
      const replaced = origBlocks - remainingBlocks;
      totalBlocks += replaced;
      fs.writeFileSync(file, result);
      console.log(`${file}: ${replaced}/${origBlocks} blocks highlighted`);
    } else {
      console.log(`${file}: no changes`);
    }
  }

  console.log(`\nDone. ${totalBlocks} blocks highlighted across ${files.length} files.`);
}

main();
