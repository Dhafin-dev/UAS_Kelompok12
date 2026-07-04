class DataScaler {
  // TODO: Ganti angka di bawah ini dengan nilai "mean_" dari StandardScaler di Python Anda
  static const List<double> means = [
    0.50, 24.31, 1.70, 86.58, 0.81, 0.88, 2.41, 2.68, 1.50, 0.02, 2.00, 0.04, 0.98, 0.65, 1.20, 2.36
  ];
  
  // TODO: Ganti angka di bawah ini dengan nilai "scale_" (std dev) dari StandardScaler di Python Anda
  static const List<double> stds = [
    0.50, 6.34, 0.09, 26.19, 0.39, 0.32, 0.53, 0.27, 0.60, 0.14, 0.61, 0.20, 0.85, 0.60, 0.51, 0.40
  ];

  /// Fungsi untuk menormalisasi 16 input pengguna sebelum masuk ke model TFLite
  static List<double> transform(List<double> rawInputs) {
    if (rawInputs.length != 16) {
      throw Exception("Input harus berjumlah 16 fitur");
    }

    List<double> scaledInputs = [];
    for (int i = 0; i < rawInputs.length; i++) {
      // Menghindari pembagian dengan nol jika std sangat kecil
      double std = stds[i] == 0 ? 1 : stds[i];
      double scaledValue = (rawInputs[i] - means[i]) / std;
      scaledInputs.add(scaledValue);
    }
    return scaledInputs;
  }
}