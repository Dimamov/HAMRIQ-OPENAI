const json = (body, status = 200) => new Response(JSON.stringify(body, null, 2), {
  status,
  headers: {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
    'Access-Control-Allow-Origin': '*'
  }
});

export async function onRequestGet({ request, env }) {
  const url = new URL(request.url);
  const shouldTestOpenAI = url.searchParams.get('openai') === '1';
  const providedAdminToken = url.searchParams.get('token') || request.headers.get('x-hamriq-health-token') || '';
  const configuredAdminToken = env.HAMRIQ_HEALTH_TOKEN || '';
  const canRunProviderTest = Boolean(configuredAdminToken && providedAdminToken === configuredAdminToken);

  const result = {
    ok: true,
    service: 'HAMRIQ health check',
    checked_at: new Date().toISOString(),
    host: url.hostname,
    deployment_reachable: true,
    environment: {
      openai_configured: Boolean(env.OPENAI_API_KEY && env.OPENAI_MODEL),
      provider_test_requires_token: true
    },
    tests: {
      openai_provider: shouldTestOpenAI ? 'token_required' : 'not_run_add_openai_1_with_token_to_test'
    }
  };

  if (!env.OPENAI_API_KEY || !env.OPENAI_MODEL) {
    result.ok = false;
    result.tests.openai_provider = shouldTestOpenAI ? 'skipped_missing_environment_variable' : result.tests.openai_provider;
    return json(result, 200);
  }

  if (shouldTestOpenAI && !canRunProviderTest) {
    result.ok = false;
    result.tests.openai_provider = 'skipped_missing_or_invalid_health_token';
    return json(result, 200);
  }

  if (shouldTestOpenAI && canRunProviderTest) {
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
