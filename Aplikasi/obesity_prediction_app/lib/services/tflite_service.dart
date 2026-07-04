import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  Interpreter? _interpreter;

  // Nama label HARUS berurutan persis seperti output LabelEncoder saat di Python.
  // Contoh urutan umum (pastikan sesuaikan dengan hasil Python Anda):
  final List<String> labels = [
    "Insufficient Weight",
    "Normal Weight",
    "Obesity Type I",
    "Obesity Type II",
    "Obesity Type III",
    "Overweight Level I",
    "Overweight Level II"
  ];

  // Memuat model dari folder assets
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model_obesitas_cnn1d.tflite');
      debugPrint('Model berhasil dimuat!');
    } catch (e) {
      debugPrint('Gagal memuat model: $e');
    }
  }

  // Fungsi utama untuk memprediksi
  String predict(List<double> inputFeatures) {
    if (_interpreter == null) {
      return "Model belum siap";
    }

    // PENTING: CNN 1D membutuhkan dimensi input [Batch, Timesteps, Channels]
    // Dalam kasus ini shape-nya adalah [1, 16, 1].
    // Kita ubah list 1D menjadi 3D array:
    var input = [
      inputFeatures.map((feature) => [feature]).toList()
    ];

    // Output shape dari model adalah [1, 7] (karena ada 7 class obesitas)
    var output = List.filled(1 * 7, 0.0).reshape([1, 7]);

    // Jalankan mesin prediksi
    _interpreter!.run(input, output);

    // Proses output (Softmax) untuk mencari probabilitas tertinggi (Argmax)
    List<double> probabilities = (output[0] as List).cast<double>();
    double maxProb = probabilities[0];
    int maxIndex = 0;

    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        maxIndex = i;
      }
    }

    // Kembalikan nama klasifikasi obesitas
    return labels[maxIndex];
  }

  // Membersihkan memori saat aplikasi ditutup
  void dispose() {
    _interpreter?.close();
  }
}