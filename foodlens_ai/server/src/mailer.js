const nodemailer = require('nodemailer');

function safeHeader(value) {
  return String(value || '').replace(/[\r\n"]/g, '').trim();
}

function createTestMailer({ smtpUser, fromName, fromEmail, transport }) {
  return async function sendTestEmail() {
    if (!smtpUser || !fromEmail) throw new Error('SMTP sender is not configured');
    return transport.sendMail({
      from: `"${safeHeader(fromName)}" <${safeHeader(fromEmail)}>`,
      to: safeHeader(smtpUser),
      subject: 'FoodLens AI 郵件設定測試',
      text: 'FoodLens AI 本機開發環境的 SMTP 設定正常。',
    });
  };
}

function createNodemailerTestMailer(config) {
  if (!config.user || !config.password) {
    return async () => { throw new Error('SMTP credentials are required'); };
  }
  const transport = nodemailer.createTransport({
    host: config.host,
    port: config.port,
    secure: config.secure,
    auth: { user: config.user, pass: config.password },
    requireTLS: !config.secure,
  });
  return createTestMailer({
    smtpUser: config.user,
    fromName: config.fromName,
    fromEmail: config.fromEmail,
    transport,
  });
}

module.exports = { createNodemailerTestMailer, createTestMailer };
