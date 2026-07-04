class UserInput {
  double gender = 0.0;
  double age = 20.0;
  double height = 1.60;
  double weight = 60.0;
  double familyHistory = 0.0;
  double favc = 0.0;
  double fcvc = 2.0;
  double ncp = 3.0;
  double caec = 1.0;
  double smoke = 0.0;
  double ch2o = 2.0;
  double scc = 0.0;
  double faf = 0.0;
  double tue = 0.0;
  double calc = 0.0;
  double mtrans = 3.0;

  // Fungsi untuk mengonversi data ke dalam bentuk List array untuk model AI
  List<double> toList() {
    return [
      gender, age, height, weight, familyHistory,
      favc, fcvc, ncp, caec, smoke, ch2o,
      scc, faf, tue, calc, mtrans
    ];
  }
}