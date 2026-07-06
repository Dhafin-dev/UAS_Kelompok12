import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'home_screen.dart';

class ResultScreen extends StatelessWidget {
  final String resultStatus;

  const ResultScreen({super.key, required this.resultStatus});

  // Logika UX warna berdasarkan hasil prediksi
  Color _getResultColor(String status) {
    if (status.contains("Normal") || status.contains("Insufficient")) {
      return AppColors.normalWeight;
    } else if (status.contains("Overweight")) {
      return AppColors.overWeight;
    } else {
      return AppColors.obesity;
    }
  }

  // Ikon berdasarkan hasil
  IconData _getResultIcon(String status) {
    if (status.contains("Normal")) {
      return Icons.check_circle_outline;
    } else if (status.contains("Insufficient")) {
      return Icons.info_outline;
    } else if (status.contains("Overweight")) {
      return Icons.warning_amber_rounded;
    } else {
      return Icons.error_outline;
    }
  }

  // Deskripsi penjelasan kondisi
  String _getDescription(String status) {
    if (status.contains("Insufficient")) {
      return "Berat badan Anda berada di bawah batas ideal. Ini dapat meningkatkan risiko kekurangan nutrisi dan menurunkan daya tahan tubuh.";
    } else if (status.contains("Normal")) {
      return "Hebat! Berat badan Anda berada di batas sehat. Ini menunjukkan keseimbangan yang baik antara pola makan dan aktivitas fisik Anda.";
    } else if (status.contains("Overweight Level I")) {
      return "Berat badan Anda sedikit di atas batas ideal. Dengan sedikit perhatian pada pola makan, Anda bisa kembali ke berat badan yang sehat.";
    } else if (status.contains("Overweight Level II")) {
      return "Berat badan Anda cukup di atas batas ideal. Disarankan untuk mulai mengatur pola makan dan meningkatkan aktivitas fisik secara rutin.";
    } else if (status.contains("Obesity Type I")) {
      return "Anda terindikasi obesitas tingkat I. Kondisi ini memerlukan perhatian serius untuk mencegah komplikasi kesehatan di kemudian hari.";
    } else if (status.contains("Obesity Type II")) {
      return "Anda terindikasi obesitas tingkat II. Disarankan untuk berkonsultasi dengan dokter guna mendapatkan penanganan yang lebih terarah.";
    } else if (status.contains("Obesity Type III")) {
      return "Anda terindikasi obesitas tingkat III. Sangat disarankan untuk segera berkonsultasi dengan dokter spesialis.";
    }
    return "";
  }

  // Saran tindakan
  String _getSuggestion(String status) {
    if (status.contains("Insufficient")) {
      return "Tingkatkan asupan kalori dengan makanan bergizi seimbang dan konsultasikan dengan ahli gizi untuk program penambahan berat badan yang sehat.";
    } else if (status.contains("Normal")) {
      return "Terus pertahankan pola makan sehat dan olahraga rutin Anda. Lakukan pemeriksaan kesehatan berkala untuk menjaga kondisi optimal.";
    } else if (status.contains("Overweight")) {
      return "Mulailah dengan mengurangi makanan tinggi kalori, perbanyak sayur dan buah, serta rutinkan olahraga minimal 30 menit per hari.";
    } else {
      return "Segera konsultasikan kondisi Anda dengan dokter dan ahli gizi untuk mendapatkan panduan yang tepat. Hindari diet ekstrem tanpa pengawasan medis.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getResultColor(resultStatus);
    final icon = _getResultIcon(resultStatus);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: Text("Hasil Diagnosis"), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(height: 8),

            // Ilustrasi ikon dalam lingkaran
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: color),
            ),

            SizedBox(height: 24),
            Text(
              "Kondisi Anda saat ini:",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 12),

            // Kartu Hasil
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                resultStatus,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),

            SizedBox(height: 20),

            // Deskripsi kondisi
            Text(
              _getDescription(resultStatus),
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
            ),

            SizedBox(height: 20),

            // Kartu saran tindakan
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: AppColors.primary, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Saran",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _getSuggestion(resultStatus),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Tombol kembali
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
                child: Text("Kembali ke Beranda"),
              ),
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
