// Setup guide: https://supabase.com/docs/guides/functions
// Supabase Edge Functions use built-in Deno.serve
declare const Deno: any;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID')
    const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY')

    if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
      return new Response(
        JSON.stringify({ error: 'OneSignal credentials not set in Supabase Secrets' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
      )
    }

    const payload = await req.json()
    payload.app_id = ONESIGNAL_APP_ID

    const authHeader = ONESIGNAL_REST_API_KEY.startsWith('Key ') || ONESIGNAL_REST_API_KEY.startsWith('Basic ')
      ? ONESIGNAL_REST_API_KEY
      : (ONESIGNAL_REST_API_KEY.startsWith('os_v2_') ? `Key ${ONESIGNAL_REST_API_KEY}` : `Basic ${ONESIGNAL_REST_API_KEY}`)

    const response = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': authHeader,
      },
      body: JSON.stringify(payload),
    })

    const data = await response.json()

    return new Response(
      JSON.stringify(data),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: response.status,
      }
    )
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error?.message ?? String(error) }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
