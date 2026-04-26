var MAIL_SENDER_NAME = 'Catatan Psikolog Support';
var MAIL_SENDER_ADDRESS = 'support@catatanpsikolog.id';
var SIGNATURE_TOLERANCE_MS = 5 * 60 * 1000;

function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return jsonResponse_(400, {
        success: false,
        code: 'BAD_REQUEST',
        message: 'request body is required',
      });
    }

    var payload = JSON.parse(e.postData.contents);
    var validation = validatePayload_(payload);
    if (!validation.ok) {
      return jsonResponse_(validation.status, {
        success: false,
        code: validation.code,
        message: validation.message,
      });
    }

    var secret = getMailWebhookSecret_();
    var signingString = buildSigningString_(
      validation.data.timestamp,
      validation.data.request_id,
      validation.data.to,
      validation.data.subject,
      validation.data.html,
      validation.data.reply_to,
      validation.data.use_custom_from,
    );
    var expectedSignature = computeSignature_(secret, signingString);

    if (expectedSignature !== validation.data.signature) {
      return jsonResponse_(401, {
        success: false,
        code: 'UNAUTHORIZED',
        message: 'invalid signature',
      });
    }

    ensureFreshTimestamp_(validation.data.timestamp);
    ensureRequestIdNotReplayed_(validation.data.request_id, validation.data.timestamp);

    var mailOptions = {
      htmlBody: validation.data.html,
      name: MAIL_SENDER_NAME,
    };

    if (validation.data.reply_to) {
      mailOptions.replyTo = validation.data.reply_to;
    }

    if (validation.data.use_custom_from && canUseCustomFrom_()) {
      mailOptions.from = MAIL_SENDER_ADDRESS;
    }

    GmailApp.sendEmail(validation.data.to, validation.data.subject, '', mailOptions);

    return jsonResponse_(200, {
      success: true,
      code: 'OK',
      message: 'email sent',
      request_id: validation.data.request_id,
    });
  } catch (err) {
    return jsonResponse_(400, {
      success: false,
      code: 'BAD_REQUEST',
      message: String(err && err.message ? err.message : err),
    });
  }
}

function validatePayload_(payload) {
  if (!payload || typeof payload !== 'object') {
    return failure_(400, 'BAD_REQUEST', 'json body must be an object');
  }

  var timestamp = asString_(payload.timestamp);
  var requestId = asString_(payload.request_id);
  var signature = asString_(payload.signature).toLowerCase();
  var to = asString_(payload.to);
  var subject = asString_(payload.subject);
  var html = asString_(payload.html);
  var replyTo = asString_(payload.reply_to);
  var useCustomFrom = payload.use_custom_from !== false;

  if (!timestamp) return failure_(400, 'BAD_REQUEST', 'timestamp is required');
  if (!requestId) return failure_(400, 'BAD_REQUEST', 'request_id is required');
  if (!signature) return failure_(400, 'BAD_REQUEST', 'signature is required');
  if (!to) return failure_(400, 'BAD_REQUEST', 'to is required');
  if (!subject) return failure_(400, 'BAD_REQUEST', 'subject is required');
  if (!html) return failure_(400, 'BAD_REQUEST', 'html is required');

  if (!/^[0-9a-f]{64}$/.test(signature)) {
    return failure_(400, 'BAD_REQUEST', 'signature must be a sha256 hex string');
  }

  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(to)) {
    return failure_(400, 'BAD_REQUEST', 'recipient email is invalid');
  }

  if (subject.length > 200) {
    return failure_(400, 'BAD_REQUEST', 'subject is too long');
  }

  if (html.length > 200000) {
    return failure_(400, 'BAD_REQUEST', 'html is too long');
  }

  var parsedTime = Date.parse(timestamp);
  if (isNaN(parsedTime)) {
    return failure_(400, 'BAD_REQUEST', 'timestamp must be ISO-8601');
  }

  return {
    ok: true,
    data: {
      timestamp: timestamp,
      request_id: requestId,
      signature: signature,
      to: to,
      subject: subject,
      html: html,
      reply_to: replyTo,
      use_custom_from: useCustomFrom,
    },
  };
}

function failure_(status, code, message) {
  return {
    ok: false,
    status: status,
    code: code,
    message: message,
  };
}

function asString_(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function getMailWebhookSecret_() {
  var secret = PropertiesService.getScriptProperties().getProperty('MAIL_WEBHOOK_SECRET');
  if (!secret) {
    throw new Error('MAIL_WEBHOOK_SECRET is not configured');
  }
  return secret;
}

function canUseCustomFrom_() {
  var aliases = GmailApp.getAliases();
  return aliases.indexOf(MAIL_SENDER_ADDRESS) !== -1;
}

function buildSigningString_(timestamp, requestId, to, subject, html, replyTo, useCustomFrom) {
  return [timestamp, requestId, to, subject, html, replyTo || '', useCustomFrom ? '1' : '0'].join('\n');
}

function computeSignature_(secret, signingString) {
  var signatureBytes = Utilities.computeHmacSha256Signature(signingString, secret);
  return bytesToHex_(signatureBytes);
}

function bytesToHex_(bytes) {
  return bytes.map(function(byte) {
    var value = byte;
    if (value < 0) {
      value += 256;
    }
    var hex = value.toString(16);
    return hex.length === 1 ? '0' + hex : hex;
  }).join('');
}

function ensureFreshTimestamp_(timestamp) {
  var now = Date.now();
  var requestTime = Date.parse(timestamp);
  if (Math.abs(now - requestTime) > SIGNATURE_TOLERANCE_MS) {
    throw new Error('timestamp is outside allowed window');
  }
}

function ensureRequestIdNotReplayed_(requestId, timestamp) {
  var cache = CacheService.getScriptCache();
  var cacheKey = 'mail_request_id:' + requestId;
  if (cache.get(cacheKey)) {
    throw new Error('request_id has already been used');
  }

  var secondsRemaining = Math.max(
    1,
    Math.ceil((SIGNATURE_TOLERANCE_MS - Math.abs(Date.now() - Date.parse(timestamp))) / 1000),
  );
  cache.put(cacheKey, '1', secondsRemaining);
}

function jsonResponse_(status, payload) {
  payload.http_status = status;
  return ContentService
    .createTextOutput(JSON.stringify(payload))
    .setMimeType(ContentService.MimeType.JSON);
}
