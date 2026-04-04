export type RenderedEmailTemplate = {
  subject: string;
  html: string;
};

export type PatientInvitationFlow =
  | 'registration_required'
  | 'consent_required'
  | 'info_only';

type PatientInvitationEmailInput = {
  flow: PatientInvitationFlow;
  clinicName: string;
  registrationUrl?: string;
  expiresText?: string;
  sessionText: string;
};

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function resolveDisplayTimezone(timezone: string): string {
  const candidate = timezone.trim();
  if (!candidate) return 'Asia/Jakarta';

  try {
    new Intl.DateTimeFormat('id-ID', { timeZone: candidate }).format(new Date());
    return candidate;
  } catch {
    return 'Asia/Jakarta';
  }
}

export function formatSessionRangeText(
  startAt: Date,
  endAt: Date,
  timezone: string,
): string {
  const resolvedTimezone = resolveDisplayTimezone(timezone);
  const dateText = startAt.toLocaleDateString('id-ID', {
    weekday: 'long',
    day: '2-digit',
    month: 'long',
    year: 'numeric',
    timeZone: resolvedTimezone,
  });
  const startTime = startAt.toLocaleTimeString('id-ID', {
    hour: '2-digit',
    minute: '2-digit',
    timeZone: resolvedTimezone,
  });
  const endTime = endAt.toLocaleTimeString('id-ID', {
    hour: '2-digit',
    minute: '2-digit',
    timeZone: resolvedTimezone,
  });

  return `${dateText}, ${startTime} - ${endTime}`;
}

export function renderPatientInvitationEmailTemplate(
  input: PatientInvitationEmailInput,
): RenderedEmailTemplate {
  const clinicName = escapeHtml(input.clinicName);
  const sessionText = escapeHtml(input.sessionText);
  const registrationUrl = input.registrationUrl ? escapeHtml(input.registrationUrl) : '';
  const expiresText = input.expiresText ? escapeHtml(input.expiresText) : '';

  if (input.flow === 'info_only') {
    const html = `<!DOCTYPE html>
<html lang="id">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Jadwal Sesi Klinik</title>
  </head>
  <body style="margin:0; padding:0; background:#f2f2fb; font-family:Arial, Helvetica, sans-serif; color:#2f2f4d;">
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="background:#f2f2fb; padding:22px 10px;">
      <tr>
        <td align="center">
          <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="620" style="max-width:620px; width:100%; background:#ffffff; border:1px solid #ddddef; border-radius:16px; overflow:hidden;">
            <tr>
              <td style="padding:24px 26px; background:#A5A5D3; background-image:linear-gradient(135deg,#8b8bc2 0%, #A5A5D3 58%, #c3c3ea 100%);">
                <div style="display:inline-block; padding:7px 18px; border:2px solid rgba(255,255,255,0.45); border-radius:999px; font-size:11px; font-weight:700; letter-spacing:1px; text-transform:uppercase; color:#ffffff;">
                  CATATAN PSIKOLOG
                </div>
                <h1 style="margin:16px 0 10px; font-size:28px; line-height:1.08; color:#ffffff; font-weight:700;">
                  Jadwal Sesi Klinik
                </h1>
                <p style="margin:0; font-size:14px; line-height:1.6; color:rgba(255,255,255,0.96);">
                  Jadwal sesi Anda sudah tersedia. Tidak diperlukan registrasi atau persetujuan tambahan.
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:24px;">
                <p style="margin:0 0 12px; font-size:15px; line-height:1.7;">Halo,</p>
                <p style="margin:0 0 16px; font-size:15px; line-height:1.7; color:#535379;">
                  Jadwal sesi Anda di <strong>${clinicName}</strong> telah ditetapkan sebagai berikut:
                </p>
                <div style="padding:14px 16px; background:#f3f0fb; border:1px solid #ddd2f1; border-radius:12px; font-size:14px; line-height:1.7; color:#434365; margin-bottom:16px;">
                  ${sessionText}
                </div>
                <p style="margin:0; font-size:14px; line-height:1.7; color:#66668c;">
                  Jika Anda memiliki pertanyaan, silakan hubungi klinik terkait.
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:16px 24px; background:#f8fbfa; border-top:1px solid #e1ece8;">
                <p style="margin:0 0 4px; font-size:14px; color:#2f2f4d; font-weight:700;">Salam hangat,</p>
                <p style="margin:0; font-size:14px; color:#535379;">
                  Catatan Psikolog<br />
                  <a href="https://www.catatanpsikolog.id" style="color:#8b8bc2; text-decoration:none;">www.catatanpsikolog.id</a>
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:12px 18px; background:#f1f5f7; border-top:1px solid #e2e8eb; text-align:center; color:#64748b; font-size:12px; line-height:1.5;">
                &copy; PT Lintas Buana Sistem Digital - Catatan Psikolog. All Rights Reserved.
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`;

    return {
      subject: 'Jadwal Sesi Klinik - Catatan Psikolog',
      html,
    };
  }

  const title =
    input.flow === 'registration_required'
      ? 'Registrasi Pasien'
      : 'Persetujuan Data Pasien';
  const intro =
    input.flow === 'registration_required'
      ? 'Silakan lengkapi data registrasi pasien melalui tautan berikut.'
      : 'Silakan setujui berbagi data dengan klinik tujuan melalui tautan berikut.';
  const actionLabel =
    input.flow === 'registration_required'
      ? 'Buka Form Registrasi'
      : 'Buka Form Persetujuan';
  const actionText =
    input.flow === 'registration_required'
      ? 'lengkapi registrasi pasien'
      : 'setujui berbagi data dengan klinik tujuan';

  const html = `<!DOCTYPE html>
<html lang="id">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${title}</title>
  </head>
  <body style="margin:0; padding:0; background:#f2f2fb; font-family:Arial, Helvetica, sans-serif; color:#2f2f4d;">
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="background:#f2f2fb; padding:22px 10px;">
      <tr>
        <td align="center">
          <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="620" style="max-width:620px; width:100%; background:#ffffff; border:1px solid #ddddef; border-radius:16px; overflow:hidden;">
            <tr>
              <td style="padding:24px 26px; background:#A5A5D3; background-image:linear-gradient(135deg,#8b8bc2 0%, #A5A5D3 58%, #c3c3ea 100%);">
                <div style="display:inline-block; padding:7px 18px; border:2px solid rgba(255,255,255,0.45); border-radius:999px; font-size:11px; font-weight:700; letter-spacing:1px; text-transform:uppercase; color:#ffffff;">
                  CATATAN PSIKOLOG
                </div>
                <h1 style="margin:16px 0 10px; font-size:28px; line-height:1.08; color:#ffffff; font-weight:700;">
                  ${title}
                </h1>
                <p style="margin:0; font-size:14px; line-height:1.6; color:rgba(255,255,255,0.96);">
                  ${intro}
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:24px;">
                <p style="margin:0 0 12px; font-size:15px; line-height:1.7;">Halo,</p>
                <p style="margin:0 0 16px; font-size:15px; line-height:1.7; color:#535379;">
                  Anda diundang ke <strong>${clinicName}</strong>.
                </p>
                <div style="padding:14px 16px; background:#f3f0fb; border:1px solid #ddd2f1; border-radius:12px; font-size:14px; line-height:1.7; color:#434365; margin-bottom:16px;">
                  Jadwal sesi: ${sessionText}
                </div>
                <p style="margin:0 0 16px; font-size:15px; line-height:1.7; color:#535379;">
                  Silakan ${actionText} melalui tautan berikut.
                </p>
                <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 16px;">
                  <tr>
                    <td style="border-radius:10px; background:#A5A5D3; background-image:linear-gradient(135deg,#8b8bc2 0%, #A5A5D3 58%, #c3c3ea 100%);">
                      <a href="${registrationUrl}" style="display:inline-block; padding:12px 18px; font-size:14px; font-weight:700; color:#ffffff; text-decoration:none; border-radius:10px;">
                        ${actionLabel}
                      </a>
                    </td>
                  </tr>
                </table>
                <p style="margin:0 0 12px; font-size:14px; line-height:1.7; color:#66668c;">
                  Jika tombol di atas tidak berfungsi, salin tautan ini ke browser Anda:
                </p>
                <p style="margin:0 0 16px; font-size:13px; line-height:1.7; word-break:break-all;">
                  <a href="${registrationUrl}" style="color:#8b8bc2; text-decoration:underline;">${registrationUrl}</a>
                </p>
                <div style="padding:14px 16px; background:#f3f0fb; border:1px solid #ddd2f1; border-radius:12px; font-size:14px; line-height:1.7; color:#434365;">
                  ${expiresText}
                </div>
                <p style="margin:16px 0 0; font-size:14px; line-height:1.7; color:#66668c;">
                  Jika Anda tidak merasa meminta undangan ini, abaikan email ini.
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:16px 24px; background:#f8fbfa; border-top:1px solid #e1ece8;">
                <p style="margin:0 0 4px; font-size:14px; color:#2f2f4d; font-weight:700;">Salam hangat,</p>
                <p style="margin:0; font-size:14px; color:#535379;">
                  Catatan Psikolog<br />
                  <a href="https://www.catatanpsikolog.id" style="color:#8b8bc2; text-decoration:none;">www.catatanpsikolog.id</a>
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:12px 18px; background:#f1f5f7; border-top:1px solid #e2e8eb; text-align:center; color:#64748b; font-size:12px; line-height:1.5;">
                &copy; PT Lintas Buana Sistem Digital - Catatan Psikolog. All Rights Reserved.
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`;

  return {
    subject:
      input.flow === 'registration_required'
        ? 'Registrasi Pasien - Catatan Psikolog'
        : 'Persetujuan Data Pasien - Catatan Psikolog',
    html,
  };
}
