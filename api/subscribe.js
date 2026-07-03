export const config = {
  runtime: 'edge',
};

export default async function handler(req) {
  // Only allow POST
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const { email } = await req.json();

    // Basic email validation
    if (!email || !email.includes('@')) {
      return new Response(JSON.stringify({ error: 'Invalid email' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const RESEND_API_KEY = process.env.RESEND_API_KEY;

    if (!RESEND_API_KEY) {
      return new Response(JSON.stringify({ error: 'Missing API key' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Notify you of new signup
    const r1 = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'TwistLog <hello@twistlog.com>',
        to: ['twistlog.app@gmail.com'],
        subject: '🎉 New TwistLog Waitlist Signup',
        html: `
          <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; background: #0f1410; color: #d4ddd4; border-radius: 8px;">
            <h2 style="color: #c9a84c; margin: 0 0 16px;">New Waitlist Signup</h2>
            <p style="margin: 0 0 8px;">Someone just joined the TwistLog waitlist:</p>
            <p style="font-size: 1.2rem; font-weight: 600; color: #f0f5f0; background: #141a14; padding: 12px 16px; border-radius: 4px; border-left: 3px solid #c9a84c;">${email}</p>
            <p style="margin-top: 24px; font-size: 0.8rem; color: #5a6b5a;">twistlog.com · PivotEdge LLC</p>
          </div>
        `,
      }),
    });
    if (!r1.ok) {
      const err = await r1.text();
      return new Response(JSON.stringify({ error: 'Resend error', detail: err }), {
        status: 500, headers: { 'Content-Type': 'application/json' },
      });
    }

    // Send confirmation to the user
    await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'TwistLog <hello@twistlog.com>',
        to: [email],
        subject: "You're on the TwistLog waitlist",
        html: `
          <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto; padding: 40px 32px; background: #0f1410; color: #d4ddd4; border-radius: 8px;">
            <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 32px;">
              <div style="width: 40px; height: 40px; border-radius: 50%; border: 2px solid #c9a84c; display: flex; align-items: center; justify-content: center;">
                <span style="color: #c9a84c; font-size: 18px;">⟳</span>
              </div>
              <span style="font-size: 1.4rem; font-weight: 700; letter-spacing: 0.05em; color: #f0f5f0;">Twist<span style="color: #c9a84c;">Log</span></span>
            </div>
            <h2 style="color: #f0f5f0; margin: 0 0 16px; font-size: 1.4rem;">You're on the list.</h2>
            <p style="margin: 0 0 16px; color: #d4ddd4; line-height: 1.7;">
              Thanks for your interest in TwistLog — the smart sensor ring that passively tracks when you open your prescription bottle.
            </p>
            <p style="margin: 0 0 24px; color: #d4ddd4; line-height: 1.7;">
              We'll reach out when we're ready for early access. No spam, just launch updates.
            </p>
            <div style="background: #141a14; border: 1px solid rgba(201,168,76,0.2); border-radius: 6px; padding: 16px 20px; margin-bottom: 32px;">
              <p style="margin: 0; font-size: 0.85rem; color: #52b788; font-weight: 600; letter-spacing: 0.1em; text-transform: uppercase; margin-bottom: 8px;">What TwistLog does</p>
              <p style="margin: 0; font-size: 0.9rem; color: #d4ddd4; line-height: 1.6;">One twist detected. Dose logged. No app to open. No button to press. Double-dose prevention built in.</p>
            </div>
            <p style="margin: 0; font-size: 0.75rem; color: #5a6b5a;">
              © 2026 TwistLog · PivotEdge LLC · <a href="https://twistlog.com" style="color: #5a6b5a;">twistlog.com</a>
            </p>
          </div>
        `,
      }),
    });

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });

  } catch (err) {
    console.error('Subscribe error:', err);
    return new Response(JSON.stringify({ error: 'Server error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
