import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // PENTING: Untuk production, gunakan Firebase Cloud Functions
  // Ini hanya untuk keperluan praktik/demo

  static const String _senderEmail = 'your_email@gmail.com';
  // Gunakan App Password dari Google Account (bukan password biasa)
  // Settings > Security > 2-Step Verification > App passwords
  static const String _appPassword = 'your_app_password_here';

  static Future<bool> sendNilaiNotification({
    required String toEmail,
    required String namaMahasiswa,
    required String matkul,
    required String nilai,
    required String grade,
  }) async {
    try {
      final smtpServer = gmail(_senderEmail, _appPassword);

      final message = Message()
        ..from = Address(_senderEmail, 'SIAKAD App')
        ..recipients.add(toEmail)
        ..subject = '📚 Nilai Baru Tersedia - $matkul'
        ..html =
            '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <div style="background: #1565C0; color: white; padding: 20px; border-radius: 8px 8px 0 0;">
              <h2>🎓 SIAKAD - Notifikasi Nilai</h2>
            </div>
            <div style="padding: 20px; border: 1px solid #eee; border-radius: 0 0 8px 8px;">
              <p>Halo <strong>$namaMahasiswa</strong>,</p>
              <p>Nilai kamu untuk mata kuliah berikut telah tersedia:</p>
              <table style="width: 100%; border-collapse: collapse;">
                <tr style="background: #f5f5f5;">
                  <td style="padding: 10px; border: 1px solid #ddd;"><strong>Mata Kuliah</strong></td>
                  <td style="padding: 10px; border: 1px solid #ddd;">$matkul</td>
                </tr>
                <tr>
                  <td style="padding: 10px; border: 1px solid #ddd;"><strong>Nilai</strong></td>
                  <td style="padding: 10px; border: 1px solid #ddd;">$nilai</td>
                </tr>
                <tr style="background: #f5f5f5;">
                  <td style="padding: 10px; border: 1px solid #ddd;"><strong>Grade</strong></td>
                  <td style="padding: 10px; border: 1px solid #ddd; font-size: 20px; font-weight: bold; color: #1565C0;">$grade</td>
                </tr>
              </table>
              <p style="color: #666; margin-top: 20px;">Login ke aplikasi SIAKAD untuk melihat detail lengkap.</p>
            </div>
          </div>
        ''';

      await send(message, smtpServer);
      return true;
    } catch (e) {
      print('Email error: $e');
      return false;
    }
  }
}
