module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, error: 'Method not allowed' });
  }

  try {
    const { email } = req.body;
    const normalizedEmail = typeof email === 'string' ? email.trim().toLowerCase() : '';

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
      return res.status(400).json({ success: false, error: 'Invalid email' });
    }

    const RESEND_API_KEY = process.env.RESEND_API_KEY;

    if (!RESEND_API_KEY) {
      return res.status(500).json({ success: false, error: 'Missing API key' });
    }

    const r1 = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'TwistLog <hello@twistlog.com>',
        to: ['twistlog.app@gmail.com'],
        subject: 'New TwistLog Waitlist Signup',
        html: `<p>New signup: <strong>${normalizedEmail}</strong></p>`,
      }),
    });

    if (!r1.ok) {
      const detail = await r1.text();
      return res.status(500).json({ success: false, error: 'Resend error', detail });
    }

    await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'TwistLog <hello@twistlog.com>',
        to: [normalizedEmail],
        subject: "You're on the TwistLog waitlist",
        html: `<p>Thanks for joining the TwistLog waitlist.</p><p>We'll send prototype updates and early access timing when ready.</p>`,
      }),
    });

    return res.status(200).json({ success: true });

  } catch (err) {
    return res.status(500).json({ success: false, error: 'Server error', detail: err.message });
  }
};
