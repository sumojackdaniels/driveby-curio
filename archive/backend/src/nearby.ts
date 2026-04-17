import { z } from "zod";
import Anthropic from "@anthropic-ai/sdk";
import { Request, Response } from "express";

// --- Request / Response schemas ---

export const NearbyRequestSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  heading: z.number().min(0).max(360),
  radius_km: z.number().positive().max(100).default(10),
  topics: z.array(z.string().min(1)).min(1).max(20),
});

export type NearbyRequest = z.infer<typeof NearbyRequestSchema>;

const POISchema = z.object({
  name: z.string(),
  topics: z.array(z.string()),
  description: z.string(),
  lat: z.number(),
  lng: z.number(),
});

const POIResponseSchema = z.object({
  pois: z.array(POISchema).max(12),
});

export type POI = z.infer<typeof POISchema>;
export type POIResponse = z.infer<typeof POIResponseSchema>;

// --- Claude client ---

const anthropic = new Anthropic();

function buildPrompt(req: NearbyRequest): string {
  return `You are a knowledgeable tour guide. Generate 5-12 real, factual points of interest within ${req.radius_km} km of latitude ${req.lat}, longitude ${req.lng}.

The driver is heading ${req.heading}° and is interested in these topics: ${req.topics.join(", ")}.

Requirements:
- Every POI must be a REAL place that actually exists at the coordinates you provide.
- Each POI must relate to at least one of the listed topics.
- Descriptions should be 2-3 sentences of fascinating, educational content — like a tour guide narrating.
- Prefer POIs that are ahead of or near the driver's heading direction.
- Coordinates must be accurate for the real location.

Respond with ONLY valid JSON in this exact format, no other text:
{
  "pois": [
    {
      "name": "Place Name",
      "topics": ["Matching Topic"],
      "description": "2-3 sentence fascinating description.",
      "lat": 39.8112,
      "lng": -77.2258
    }
  ]
}`;
}

// --- Handler ---

export async function nearbyHandler(req: Request, res: Response): Promise<void> {
  // Validate request body
  const parsed = NearbyRequestSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      error: "Invalid request",
      details: parsed.error.issues,
    });
    return;
  }

  try {
    const message = await anthropic.messages.create({
      model: "claude-sonnet-4-20250514",
      max_tokens: 2048,
      messages: [
        {
          role: "user",
          content: buildPrompt(parsed.data),
        },
      ],
    });

    // Extract text from response
    const textBlock = message.content.find((block) => block.type === "text");
    if (!textBlock || textBlock.type !== "text") {
      res.status(500).json({ error: "No text response from Claude" });
      return;
    }

    // Parse and validate Claude's JSON response
    let poiData: unknown;
    try {
      poiData = JSON.parse(textBlock.text);
    } catch {
      console.error("Claude returned invalid JSON:", textBlock.text);
      res.status(500).json({ error: "Invalid JSON from Claude" });
      return;
    }

    const validated = POIResponseSchema.safeParse(poiData);
    if (!validated.success) {
      console.error("Claude response failed validation:", validated.error.issues);
      res.status(500).json({ error: "Claude response failed validation" });
      return;
    }

    res.json(validated.data);
  } catch (err) {
    console.error("Claude API error:", err);
    res.status(500).json({ error: "Failed to generate POIs" });
  }
}
