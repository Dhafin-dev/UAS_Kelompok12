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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text("Hasil Diagnosis AI"), automaticallyImplyLeading: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Kondisi Anda saat ini:", style: TextStyle(fontSize: 18, color: Colors.grey[700])),
              SizedBox(height: 16),
              
              // Kartu Hasil
              Container(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: _getResultColor(resultStatus).withValues(alpha: 0.2),
                  border: Border.all(color: _getResultColor(resultStatus), width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  resultStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _getResultColor(resultStatus)),
                ),
              ),
              
              SizedBox(height: 48),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
                child: Text("Kembali ke Beranda"),
              )
            ],
          ),
        ),
      ),
    );
  }
}