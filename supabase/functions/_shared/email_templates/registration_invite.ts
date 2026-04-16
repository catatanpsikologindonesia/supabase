export type RenderedEmailTemplate = {
  subject: string;
  html: string;
};

type RegistrationInviteEmailInput = {
  registrationUrl: string;
  expiresText: string;
};

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

export function renderRegistrationInviteEmailTemplate(
  input: RegistrationInviteEmailInput,
): RenderedEmailTemplate {
  const registrationUrl = escapeHtml(input.registrationUrl);
  const expiresText = escapeHtml(input.expiresText);

  const html = `<!DOCTYPE html>
<html lang="id">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Registrasi Pasien</title>
  </head>
  <body style="margin:0; padding:0; background:#f3f7f6; font-family:Arial, Helvetica, sans-serif; color:#16302b;">
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="background:#f3f7f6; padding:22px 10px;">
      <tr>
        <td align="center">
          <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="620" style="max-width:620px; width:100%; background:#ffffff; border:1px solid #d9e7e3; border-radius:16px; overflow:hidden;">
            <tr>
              <td style="padding:24px 26px; background:#1f8a70; background-image:linear-gradient(135deg,#166b57 0%, #1f8a70 58%, #39b38f 100%);">
                <div style="display:inline-block; padding:7px 18px; border:2px solid rgba(255,255,255,0.45); border-radius:999px; font-size:11px; font-weight:700; letter-spacing:1px; text-transform:uppercase; color:#ffffff;">
                  CATATAN PSIKOLOG
                </div>
                <h1 style="margin:16px 0 10px; font-size:28px; line-height:1.08; color:#ffffff; font-weight:700;">
                  Registrasi Pasien
                </h1>
                <p style="margin:0; font-size:14px; line-height:1.6; color:rgba(255,255,255,0.96);">
                  Silakan lengkapi data registrasi pasien melalui tautan yang kami kirimkan berikut ini.
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:24px;">
                <p style="margin:0 0 12px; font-size:15px; line-height:1.7;">Halo,</p>
                <p style="margin:0 0 16px; font-size:15px; line-height:1.7; color:#38534d;">
                  Untuk melanjutkan proses registrasi pasien, silakan buka tautan berikut.
                </p>
                <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 16px;">
                  <tr>
                    <td style="border-radius:10px; background:#1f8a70;">
                      <a href="${registrationUrl}" style="display:inline-block; padding:12px 18px; font-size:14px; font-weight:700; color:#ffffff; text-decoration:none; border-radius:10px;">
                        Buka Form Registrasi
                      </a>
                    </td>
                  </tr>
                </table>
                <p style="margin:0 0 12px; font-size:14px; line-height:1.7; color:#4c6761;">
                  Jika tombol di atas tidak berfungsi, salin tautan ini ke browser Anda:
                </p>
                <p style="margin:0 0 16px; font-size:13px; line-height:1.7; word-break:break-all;">
                  <a href="${registrationUrl}" style="color:#166b57; text-decoration:underline;">${registrationUrl}</a>
                </p>
                <div style="padding:14px 16px; background:#eff8f5; border:1px solid #cfe8e0; border-radius:12px; font-size:14px; line-height:1.7; color:#274640;">
                  ${expiresText}
                </div>
                <p style="margin:16px 0 0; font-size:14px; line-height:1.7; color:#4c6761;">
                  Jika Anda tidak merasa meminta registrasi ini, abaikan email ini.
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:16px 24px; background:#f8fbfa; border-top:1px solid #e1ece8;">
                <p style="margin:0 0 4px; font-size:14px; color:#16302b; font-weight:700;">Catatan Psikolog Support</p>
                <p style="margin:0; font-size:14px; color:#38534d;">
                  <a href="https://www.catatanpsikolog.id" style="color:#166b57; text-decoration:none;">www.catatanpsikolog.id</a>
                </p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`;

  return {
    subject: 'Registrasi Pasien - Catatan Psikolog',
    html,
  };
}
