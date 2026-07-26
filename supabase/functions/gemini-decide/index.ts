const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type DecideRequest = {
  systemPrompt?: string;
  observation?: string;
  jpegBase64?: string;
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  const model = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.5-flash";
  if (!apiKey) {
    return json({ error: "gemini_not_configured" }, 503);
  }

  let input: DecideRequest;
  try {
    input = await request.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  const systemPrompt = input.systemPrompt?.trim() ?? "";
  const observation = input.observation?.trim() ?? "";
  if (!systemPrompt || !observation) {
    return json({ error: "prompt_and_observation_required" }, 400);
  }
  if (systemPrompt.length > 12_000 || observation.length > 4_000) {
    return json({ error: "input_too_large" }, 413);
  }

  const parts: Record<string, unknown>[] = [{ text: observation }];
  if (input.jpegBase64) {
    if (input.jpegBase64.length > 2_800_000) {
      return json({ error: "image_too_large" }, 413);
    }
    parts.push({
      inline_data: {
        mime_type: "image/jpeg",
        data: input.jpegBase64,
      },
    });
  }

  const geminiResponse = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": apiKey,
      },
      body: JSON.stringify({
        system_instruction: { parts: [{ text: systemPrompt }] },
        contents: [{ role: "user", parts }],
        generationConfig: {
          temperature: 0.4,
          maxOutputTokens: 100,
        },
      }),
    },
  );

  const payload = await geminiResponse.json();
  if (!geminiResponse.ok) {
    console.error("Gemini error", geminiResponse.status, payload);
    return json({ error: "gemini_request_failed" }, 502);
  }

  const text = payload?.candidates?.[0]?.content?.parts
    ?.map((part: { text?: string }) => part.text ?? "")
    .join("")
    .trim();

  if (!text) {
    return json({ error: "empty_gemini_response" }, 502);
  }
  return json({ text });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
