import { initializeApp } from "firebase-admin/app";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";

initializeApp();

const geminiApiKey = defineSecret("GEMINI_API_KEY");

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

function extractJson(text: string): AdviceResponse {
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end <= start) {
    throw new HttpsError("internal", "Gemini did not return JSON.");
  }

  const parsed = JSON.parse(text.slice(start, end + 1)) as Record<string, unknown>;
  return {
    summary: asText(parsed.summary, "Here is a preparation plan."),
    tips: readStringList(parsed.tips),
    deadlines: readStringList(parsed.deadlines),
    weeklyPlan: readStringList(parsed.weeklyPlan),
    usedAi: true,
  };
}

export const getCalendarPrepAdvice = onCall(
  { secrets: [geminiApiKey], region: "us-central1" },
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

    const apiKey = geminiApiKey.value();
    if (!apiKey) {
      throw new HttpsError("failed-precondition", "Gemini API key is not configured.");
    }

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.3 },
        }),
      },
    );

    if (!response.ok) {
      throw new HttpsError("internal", `Gemini request failed with ${response.status}.`);
    }

    const body = await response.json() as {
      candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
    };
    const text = body.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) {
      throw new HttpsError("internal", "Gemini returned an empty response.");
    }

    return extractJson(text);
  },
);
