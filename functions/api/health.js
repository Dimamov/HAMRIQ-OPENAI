const json = (body, status = 200) => new Response(JSON.stringify(body, null, 2), {
  status,
  headers: {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
    'Access-Control-Allow-Origin': '*'
  }
});

const mask = value => {
  if (!value) return null;
  const text = String(value);
  if (text.length <= 10) return `${text.slice(0, 2)}…${text.slice(-2)}`;
  return `${text.slice(0, 7)}…${text.slice(-4)}`;
};

export async function onRequestGet({ request, env }) {
  const url = new URL(request.url);
  const shouldTestOpenAI = url.searchParams.get('openai') === '1';

  const result = {
    ok: true,
    service: 'HAMRIQ health check',
    checked_at: new Date().toISOString(),
    host: url.hostname,
    deployment_reachable: true,
    environment: {
      OPENAI_API_KEY_present: Boolean(env.OPENAI_API_KEY),
      OPENAI_API_KEY_preview: env.OPENAI_API_KEY ? mask(env.OPENAI_API_KEY) : null,
      OPENAI_MODEL_present: Boolean(env.OPENAI_MODEL),
      OPENAI_MODEL_value: env.OPENAI_MODEL || null
    },
    tests: {
      openai_provider: shouldTestOpenAI ? 'pending' : 'not_run_add_openai_1_to_test'
    }
  };

  if (!env.OPENAI_API_KEY || !env.OPENAI_MODEL) {
    result.ok = false;
    result.tests.openai_provider = shouldTestOpenAI ? 'skipped_missing_environment_variable' : result.tests.openai_provider;
    return json(result, 200);
  }

  if (shouldTestOpenAI) {
    try {
      const response = await fetch('https://api.openai.com/v1/responses', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${env.OPENAI_API_KEY}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          model: env.OPENAI_MODEL,
          store: false,
          max_output_tokens: 24,
          input: 'Reply with exactly: HAMRIQ_HEALTH_OK'
        }),
        signal: AbortSignal.timeout(20000)
      });

      const body = await response.json().catch(() => ({}));
      if (!response.ok) {
        result.ok = false;
        result.tests.openai_provider = 'failed';
        result.openai_error = {
          status: response.status,
          message: body?.error?.message || 'OpenAI request failed'
        };
        return json(result, 200);
      }

      const text = (body.output || [])
        .flatMap(item => item.content || [])
        .filter(item => item.type === 'output_text')
        .map(item => item.text)
        .join('\n')
        .trim();

      result.tests.openai_provider = text.includes('HAMRIQ_HEALTH_OK') ? 'passed' : 'responded_unexpectedly';
      result.openai_response_preview = text.slice(0, 80);
    } catch (error) {
      result.ok = false;
      result.tests.openai_provider = 'failed';
      result.openai_error = {
        message: error?.message || 'OpenAI test failed'
      };
    }
  }

  return json(result, 200);
}
