const defaultLocation = 'global';

export function generationPrompt({ course, outcome, sources, contentType }) {
  return `You create internal draft material for NursePath Pakistan.\n` +
    `Course: ${course}\nLearning outcome: ${outcome}\nContent type: ${contentType}\n` +
    `Use only the supplied source excerpts. Do not invent doses, numerical values, citations, or recommendations. ` +
    `Return valid JSON matching the supplied response schema. If sources are insufficient, return {"status":"insufficient_sources"}.\n` +
    `Sources:\n${sources.map((source) => `[${source.id}] ${source.excerpt}`).join('\n')}`;
}

export async function generateWithVertex({ projectId, accessToken, model, prompt, responseSchema, location = defaultLocation }) {
  if (!projectId || !accessToken || !model) throw new Error('Vertex configuration is incomplete');
  const endpoint = `https://${location === 'global' ? 'aiplatform.googleapis.com' : `${location}-aiplatform.googleapis.com`}/v1/projects/${projectId}/locations/${location}/publishers/google/models/${model}:generateContent`;
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0, responseMimeType: 'application/json', responseSchema },
    }),
  });
  if (!response.ok) throw new Error(`Vertex request failed with ${response.status}`);
  const result = await response.json();
  const text = result.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) throw new Error('Vertex returned no structured content');
  return { item: JSON.parse(text), usage: result.usageMetadata ?? {} };
}
