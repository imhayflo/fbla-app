import { initializeApp } from "firebase-admin/app";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";

initializeApp();

const openAIApiKey = defineSecret("OPENAI_API_KEY");

type CalendarItem = {
  title?: unknown;
  type?: unknown;
  level?: unknown;
  date?: unknown;
};

type AdviceResponse = {
  summary: string;
  tips: string[];
  deadlines: string[];
  weeklyPlan: string[];
  usedAi: boolean;
};

function asText(value: unknown, fallback: string): string {
  return typeof value === "string" && value.trim().length > 0
    ? value.trim()
    : fallback;
}

function readStringList(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value
    .map((item) => String(item).trim())
    .filter((item) => item.length > 0)
    .slice(0, 6);
}

function listOrFallback(value: unknown, fallback: string[]): string[] {
  const list = readStringList(value);
  return list.length > 0 ? list : fallback;
}

function extractJson(text: string): AdviceResponse {
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end <= start) {
    throw new HttpsError("internal", "ChatGPT did not return JSON.");
  }

  const parsed = JSON.parse(text.slice(start, end + 1)) as Record<string, unknown>;
  return {
    summary: asText(parsed.summary, "Here is a preparation plan."),
    tips: listOrFallback(parsed.tips, [
      "Review the official event guidelines and scoring criteria.",
      "Make a short practice plan with checkpoints before the event date.",
      "Ask an adviser or officer for feedback before finalizing materials.",
    ]),
    deadlines: listOrFallback(parsed.deadlines, [
      "This week: confirm the rules, schedule, and required materials.",
      "Two weeks before: complete a timed practice or study review.",
      "One week before: polish details and confirm travel or meeting logistics.",
    ]),
    weeklyPlan: listOrFallback(parsed.weeklyPlan, [
      "Week 1: understand the event and collect resources.",
      "Week 2: prepare your content, notes, or study plan.",
      "Week 3: practice, get feedback, and tighten weak areas.",
    ]),
    usedAi: true,
  };
}

export const getCalendarPrepAdvice = onCall(
  { secrets: [openAIApiKey], region: "us-central1" },
  async (request): Promise<AdviceResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in before generating advice.");
    }

    const items = Array.isArray(request.data?.items)
      ? (request.data.items as CalendarItem[]).slice(0, 8)
      : [];
    const eventsText = items.length === 0
      ? "No upcoming events are currently loaded."
      : items
        .map((item) => {
          const title = asText(item.title, "Untitled event");
          const type = asText(item.type, "FBLA event");
          const level = asText(item.level, "");
          const date = asText(item.date, "date not set");
          return `- ${title} (${type}${level ? `, ${level}` : ""}) on ${date}`;
        })
        .join("\n");

    const prompt = `
You are an FBLA preparation coach for a student.
Use these upcoming calendar items:
${eventsText}

Return only valid JSON with exactly these keys:
summary: short string
tips: array of 3-5 concise strings
deadlines: array of 3-5 strings with concrete example preparation deadlines
weeklyPlan: array of 3-5 strings
`;

    const apiKey = openAIApiKey.value();
    if (!apiKey) {
      throw new HttpsError("failed-precondition", "OpenAI API key is not configured.");
    }

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: process.env.OPENAI_MODEL ?? "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: "You are a concise FBLA preparation coach. Return only valid JSON.",
          },
          { role: "user", content: prompt },
        ],
        response_format: { type: "json_object" },
        temperature: 0.3,
        max_tokens: 700,
      }),
    });

    if (!response.ok) {
      throw new HttpsError("internal", `OpenAI request failed with ${response.status}.`);
    }

    const body = await response.json() as {
      choices?: Array<{ message?: { content?: string } }>;
    };
    const text = body.choices?.[0]?.message?.content;
    if (!text) {
      throw new HttpsError("internal", "ChatGPT returned an empty response.");
    }

    return extractJson(text);
  },
);
