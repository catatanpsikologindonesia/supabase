export type RenderedEmailTemplate = {
  subject: string;
  html: string;
};

type DemoRequestEmailInput = {
  requestId: string;
  submittedAt: string;
  fullname: string;
  position: string;
  email: string;
  whatsapp: string;
  clinicName: string;
  clinicType: string;
  addressLine: string;
  rtRw: string;
  subdistrict: string;
  district: string;
  city: string;
  province: string;
  postalCode: string;
  referralSource: string | null;
  subscribe: boolean;
  privacy: boolean;
  message: string | null;
};

const DEMO_EMAIL_BRAND_NAME = 'Catatan Psikolog Support';
const DEMO_ADMIN_RECIPIENT = 'support@catatanpsikolog.id';

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function safeValue(value: string | null | undefined): string {
  const normalized = String(value ?? '').trim();
  return normalized ? normalized : '-';
}

function formatSubmittedAtHuman(isoLikeString: string): string {
  const parsed = new Date(isoLikeString);
  if (Number.isNaN(parsed.getTime())) return isoLikeString;

  const formatter = new Intl.DateTimeFormat('id-ID', {
    timeZone: 'Asia/Jakarta',
    day: '2-digit',
    month: 'long',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  });

  return formatter.format(parsed).replace('.', ':');
}

function normalizeWhatsappLink(rawWhatsapp: string): string {
  const digits = rawWhatsapp.replace(/\D/g, '');
  if (!digits) return 'https://wa.me/';
  if (digits.startsWith('0')) return `https://wa.me/62${digits.slice(1)}`;
  return `https://wa.me/${digits}`;
}

function toViewModel(input: DemoRequestEmailInput) {
  return {
    requestId: escapeHtml(safeValue(input.requestId)),
    submittedAt: escapeHtml(formatSubmittedAtHuman(input.submittedAt)),
    fullname: escapeHtml(safeValue(input.fullname)),
    position: escapeHtml(safeValue(input.position)),
    email: escapeHtml(safeValue(input.email)),
    whatsapp: escapeHtml(safeValue(input.whatsapp)),
    clinicName: escapeHtml(safeValue(input.clinicName)),
    clinicType: escapeHtml(safeValue(input.clinicType)),
    addressLine: escapeHtml(safeValue(input.addressLine)),
    rtRw: escapeHtml(safeValue(input.rtRw)),
    subdistrict: escapeHtml(safeValue(input.subdistrict)),
    district: escapeHtml(safeValue(input.district)),
    city: escapeHtml(safeValue(input.city)),
    province: escapeHtml(safeValue(input.province)),
    postalCode: escapeHtml(safeValue(input.postalCode)),
    referralSource: escapeHtml(safeValue(input.referralSource)),
    message: escapeHtml(safeValue(input.message)),
    subscribeText: input.subscribe ? 'Ya' : 'Tidak',
    privacyText: input.privacy ? 'Ya' : 'Tidak',
    whatsappLink: escapeHtml(normalizeWhatsappLink(input.whatsapp)),
  };
}

// Periwinkle brand colours for Psikolog
const BRAND_GRADIENT = 'background:#7B7BBB; background-image:linear-gradient(135deg,#5a5a99 0%,#7B7BBB 55%,#A5A5D3 100%)';
const BRAND_LINK_COLOR = '#5a5a99';
const BRAND_TABLE_BG = '#f7f7fc';
const BRAND_TABLE_BORDER = '#d4d4ec';

export function renderDemoAdminEmailTemplate(input: DemoRequestEmailInput): RenderedEmailTemplate {
  const view = toViewModel(input);

  const html = `<!DOCTYPE html>
<html lang="id">
  <head>
    <meta charset="UTF-8" />
    <title>Permintaan Demo Baru</title>
  </head>
  <body style="margin:0; padding:0; background:#eeeef6; font-family:Arial, Helvetica, sans-serif; color:#1f2937;">
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="background:#eeeef6; padding:24px 12px;">
      <tr>
        <td align="center">
          <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="700" style="max-width:700px; width:100%; background:#ffffff; border:1px solid #d4d4ec; border-radius:16px; overflow:hidden;">
            <tr>
              <td style="padding:22px 26px; ${BRAND_GRADIENT};">
                <h2 style="margin:0; color:#ffffff; font-size:24px;">Permintaan Demo Baru</h2>
                <p style="margin:8px 0 0; color:#ffffff; font-size:13px;">
                  Sumber:
                  <a href="https://www.catatanpsikolog.id" style="color:#ffffff; text-decoration:underline;">https://www.catatanpsikolog.id</a>
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:22px 26px;">
                <table cellpadding="0" cellspacing="0" border="0" width="100%" style="border-collapse:collapse;">
                  <tr><td style="padding:10px; width:34%; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">Nama Lengkap</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER};">${view.fullname}</td></tr>
                  <tr><td style="padding:10px; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">Jabatan</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER};">${view.position}</td></tr>
                  <tr><td style="padding:10px; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">Email</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER};">${view.email}</td></tr>
                  <tr><td style="padding:10px; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">WhatsApp</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER};">${view.whatsapp}</td></tr>
                  <tr><td style="padding:10px; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">Nama Praktik/Biro</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER};">${view.clinicName}</td></tr>
                  <tr><td style="padding:10px; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">Jenis Praktik</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER};">${view.clinicType}</td></tr>
                  <tr><td style="padding:10px; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">Alamat Praktik</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER};">${view.addressLine}</td></tr>
                  <tr><td style="padding:10px; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">RT/RW</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER};">${view.rtRw}</td></tr>
                  <tr><td style="padding:10px; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">Kelurahan/Desa</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER};">${view.subdistrict}</td></tr>
                  <tr><td style="padding:10px; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">Kecamatan</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER};">${view.district}</td></tr>
                  <tr><td style="padding:10px; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">Kota/Kab</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER};">${view.city}</td></tr>
                  <tr><td style="padding:10px; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">Provinsi</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER};">${view.province}</td></tr>
                  <tr><td style="padding:10px; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">Kode Pos</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER};">${view.postalCode}</td></tr>
                  <tr><td style="padding:10px; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">Sumber Info</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER};">${view.referralSource}</td></tr>
                  <tr><td style="padding:10px; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">Pesan</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER};">${view.message}</td></tr>
                  <tr><td style="padding:10px; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">Berlangganan</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER};">${view.subscribeText}</td></tr>
                  <tr><td style="padding:10px; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">Setuju Kebijakan Privasi</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER};">${view.privacyText}</td></tr>
                  <tr><td style="padding:10px; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">Kode Pengajuan</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER}; font-weight:700;">${view.requestId}</td></tr>
                  <tr><td style="padding:10px; background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER};">Waktu Pengajuan</td><td style="padding:10px; border:1px solid ${BRAND_TABLE_BORDER};">${view.submittedAt}</td></tr>
                </table>
                <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin-top:18px;">
                  <tr>
                    <td style="border-radius:10px; ${BRAND_GRADIENT};">
                      <a href="${view.whatsappLink}" style="display:inline-block; padding:12px 18px; font-size:14px; font-weight:700; color:#ffffff; text-decoration:none; border-radius:10px;">Hubungi via WhatsApp</a>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
            <tr>
              <td style="padding:14px 20px; background:#f1f1f8; border-top:1px solid #d4d4ec; text-align:center; color:#64748b; font-size:12px;">
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
    subject: `Permintaan Demo Baru - ${safeValue(input.clinicName)} | ${safeValue(input.requestId)}`,
    html,
  };
}

export function renderDemoUserEmailTemplate(input: DemoRequestEmailInput): RenderedEmailTemplate {
  const view = toViewModel(input);

  const html = `<!DOCTYPE html>
<html lang="id">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Konfirmasi Pengajuan Demo</title>
  </head>
  <body style="margin:0; padding:0; background:#eeeef6; font-family:Arial, Helvetica, sans-serif; color:#1f2937;">
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="background:#eeeef6; padding:22px 10px;">
      <tr>
        <td align="center">
          <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="620" style="max-width:620px; width:100%; background:#ffffff; border:1px solid #d4d4ec; border-radius:16px; overflow:hidden;">
            <tr>
              <td style="padding:0; ${BRAND_GRADIENT};">
                <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
                  <tr>
                    <td style="padding:24px 26px 20px;">
                      <div style="display:inline-block; padding:7px 18px; border:2px solid rgba(255,255,255,0.55); border-radius:999px; font-size:11px; font-weight:700; letter-spacing:1px; text-transform:uppercase; color:#ffffff; background:rgba(255,255,255,0.06);">
                        CATATAN PSIKOLOG
                      </div>
                      <h1 style="margin:16px 0 10px; font-size:28px; line-height:1.05; color:#ffffff; font-weight:700;">
                        Konfirmasi Pengajuan Demo
                      </h1>
                      <p style="margin:0; font-size:14px; line-height:1.5; color:rgba(255,255,255,0.96);">
                        Pengajuan Anda telah kami terima dan sedang diproses oleh tim Catatan Psikolog.
                      </p>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
            <tr>
              <td style="padding:22px 24px 10px;">
                <p style="margin:0 0 12px; font-size:15px; line-height:1.7;">
                  Halo <strong>${view.fullname}</strong>,
                </p>
                <p style="margin:0; font-size:15px; line-height:1.7; color:#374151;">
                  Terima kasih atas ketertarikan Anda pada layanan kami. Pengajuan demo untuk
                  <strong>${view.clinicName}</strong> telah berhasil kami catat.
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:0 24px 12px;">
                <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="background:${BRAND_TABLE_BG}; border:1px solid ${BRAND_TABLE_BORDER}; border-radius:12px;">
                  <tr>
                    <td style="padding:14px 16px;">
                      <div style="font-size:11px; color:#5a5a99; margin-bottom:6px; text-transform:uppercase; letter-spacing:0.7px;">
                        Kode Pengajuan
                      </div>
                      <div style="font-size:22px; font-weight:700; letter-spacing:0.3px; color:#0f172a; line-height:1.3;">
                        ${view.requestId}
                      </div>
                      <div style="margin-top:7px; font-size:12px; color:#60727a;">
                        Simpan kode ini untuk keperluan tindak lanjut.
                      </div>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
            <tr>
              <td style="padding:4px 24px 10px;">
                <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="border-collapse:collapse;">
                  <tr>
                    <td style="padding:9px 0; border-bottom:1px solid #edf2f4; font-size:13px; color:#64748b; width:44%;">Nama Praktik/Biro</td>
                    <td style="padding:9px 0; border-bottom:1px solid #edf2f4; font-size:13px; color:#0f172a; font-weight:600;">${view.clinicName}</td>
                  </tr>
                  <tr>
                    <td style="padding:9px 0; border-bottom:1px solid #edf2f4; font-size:13px; color:#64748b;">Nomor WhatsApp</td>
                    <td style="padding:9px 0; border-bottom:1px solid #edf2f4; font-size:13px; color:#0f172a; font-weight:600;">${view.whatsapp}</td>
                  </tr>
                  <tr>
                    <td style="padding:9px 0; font-size:13px; color:#64748b;">Waktu Pengajuan</td>
                    <td style="padding:9px 0; font-size:13px; color:#0f172a; font-weight:600;">${view.submittedAt}</td>
                  </tr>
                </table>
              </td>
            </tr>
            <tr>
              <td style="padding:10px 24px 22px;">
                <p style="margin:0; font-size:15px; line-height:1.7; color:#374151;">
                  Kami akan menghubungi Anda melalui WhatsApp untuk penjadwalan sesi demo.
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:16px 24px; background:#f8f8fc; border-top:1px solid #e0e0f0;">
                <p style="margin:0 0 4px; font-size:14px; color:#111827; font-weight:700;">Salam hangat,</p>
                <p style="margin:0; font-size:14px; color:#1f2937;">
                  ${DEMO_EMAIL_BRAND_NAME}<br />
                  <a href="https://www.catatanpsikolog.id" style="color:${BRAND_LINK_COLOR}; text-decoration:none;">www.catatanpsikolog.id</a>
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:12px 18px; background:#f1f1f8; border-top:1px solid #d4d4ec; text-align:center; color:#64748b; font-size:12px; line-height:1.5;">
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
    subject: `Konfirmasi Pengajuan Demo Catatan Psikolog | ${safeValue(input.requestId)}`,
    html,
  };
}

export function demoAdminAddress(): string {
  return DEMO_ADMIN_RECIPIENT;
}
