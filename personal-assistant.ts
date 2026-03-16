/**
 * Personal Assistant — powered by Claude
 *
 * Uses the Claude Agent SDK with MCP servers for Gmail + Google Calendar.
 *
 * SETUP (one-time):
 *   1. Get a Google OAuth client:
 *      - Go to console.cloud.google.com → Create project → Enable Gmail API + Calendar API
 *      - Create OAuth credentials (Desktop app) → download client_secret.json
 *
 *   2. Install MCP servers:
 *      npm install -g @gptscript-ai/gmail-mcp @gptscript-ai/google-calendar-mcp
 *      (or use the official ones when stable)
 *
 *   3. Set your API key:
 *      export ANTHROPIC_API_KEY=sk-ant-...
 *
 *   4. Run:
 *      npx ts-node personal-assistant.ts
 *      # or with bun:
 *      bun personal-assistant.ts
 */

import { query } from "@anthropic-ai/claude-agent-sdk";
import * as readline from "readline";

const SYSTEM_PROMPT = `You are a personal assistant for Sigurd. You are proactive, concise, and helpful.

You have access to:
- Gmail: read/search emails, create drafts
- Google Calendar: view events, create meetings, find free time
- Web search: look up current information

When the user asks about their schedule, emails, or wants to set up meetings — use the tools directly.
Always confirm before sending emails or creating calendar events.

Today's date: ${new Date().toLocaleDateString("en-US", { weekday: "long", year: "numeric", month: "long", day: "numeric" })}`;

async function chat(prompt: string): Promise<string> {
  const parts: string[] = [];

  for await (const message of query({
    prompt,
    options: {
      systemPrompt: SYSTEM_PROMPT,
      model: "claude-opus-4-6",
      allowedTools: ["WebSearch", "WebFetch"],

      // Requires: client_secret.json from Google Cloud Console (Gmail + Calendar APIs enabled)
      mcpServers: {
        gmail: {
          command: "npx",
          args: ["-y", "@gptscript-ai/gmail-mcp"],
          env: { GOOGLE_CLIENT_SECRET_FILE: "./client_secret.json" },
        },
        calendar: {
          command: "npx",
          args: ["-y", "@gptscript-ai/google-calendar-mcp"],
          env: { GOOGLE_CLIENT_SECRET_FILE: "./client_secret.json" },
        },
      },
    },
  })) {
    if ("result" in message) {
      parts.push(message.result);
    }
  }

  return parts.join("").trim();
}

async function main() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  console.log("\nPersonal Assistant ready. Type your message (or 'exit' to quit).\n");

  const ask = () => {
    rl.question("You: ", async (input) => {
      const trimmed = input.trim();
      if (!trimmed || trimmed.toLowerCase() === "exit") {
        console.log("\nGoodbye!");
        rl.close();
        return;
      }

      try {
        const response = await chat(trimmed);
        console.log(`\nAssistant: ${response}\n`);
      } catch (err) {
        console.error("Error:", err instanceof Error ? err.message : err);
      }

      ask();
    });
  };

  ask();
}

main();
