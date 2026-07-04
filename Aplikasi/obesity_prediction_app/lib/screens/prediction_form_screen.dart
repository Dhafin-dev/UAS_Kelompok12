import 'package:flutter/material.dart';
import '../models/user_input.dart';
import '../services/data_scaler.dart';
import '../services/tflite_service.dart';
import '../widgets/custom_slider.dart';
import '../widgets/custom_dropdown.dart';
import 'result_screen.dart';

class PredictionFormScreen extends StatefulWidget {
  const PredictionFormScreen({super.key});

  @override
  State<PredictionFormScreen> createState() => _PredictionFormScreenState();
}

class _PredictionFormScreenState extends State<PredictionFormScreen> {
  int _currentStep = 0;
  bool _isModelLoaded = false;
  bool _isSubmitting = false;
  UserInput userInput = UserInput();
  TFLiteService tfliteService = TFLiteService();

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    await tfliteService.loadModel();
    if (mounted) {
      setState(() => _isModelLoaded = true);
    }
  }

  void _submitData() async {
    if (!_isModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Model AI sedang dimuat, mohon tunggu...")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // 1. Ambil data mentah
    List<double> rawData = userInput.toList();

    // 2. Normalisasi
    List<double> scaledData = DataScaler.transform(rawData);

    // 3. Prediksi
    String result = tfliteService.predict(scaledData);

    // 4. Pindah ke layar hasil
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ResultScreen(resultStatus: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kuesioner Kesehatan")),
      body: Column(
        children: [
          // Indikator loading model
          if (!_isModelLoaded)
            LinearProgressIndicator(),

          Expanded(
            child: Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 2) {
                  setState(() => _currentStep += 1);
                } else {
                  _submitData(); // Jika di langkah terakhir, proses AI
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              controlsBuilder: (context, details) {
                final isLastStep = _currentStep == 2;
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : details.onStepContinue,
                          child: _isSubmitting && isLastStep
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(isLastStep ? "Prediksi Sekarang" : "Lanjut"),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details.onStepCancel,
                            child: Text("Kembali"),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                // ═══════════════════════════════════════════
                // LANGKAH 1: DATA FISIK
                // ═══════════════════════════════════════════
                Step(
                  title: Text("Fisik"),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: Column(
                    children: [
                      // Gender
                      CustomDropdown(
                        label: "Jenis Kelamin",
                        value: userInput.gender,
                        items: [
                          DropdownMenuItem(value: 0.0, child: Text("Perempuan")),
                          DropdownMenuItem(value: 1.0, child: Text("Laki-Laki")),
                        ],
                        onChanged: (val) => setState(() => userInput.gender = val!),
                      ),
                      // Age
                      CustomSlider(
                        label: "Usia (Tahun)",
                        value: userInput.age,
                        min: 10,
                        max: 80,
                        divisions: 70,
                        onChanged: (val) => setState(() => userInput.age = val),
                      ),
                      // Height
                      CustomSlider(
                        label: "Tinggi Badan (M)",
                        value: userInput.height,
                        min: 1.00,
                        max: 2.20,
                        divisions: 120,
                        onChanged: (val) => setState(() => userInput.height = val),
                      ),
                      // Weight
                      CustomSlider(
                        label: "Berat Badan (Kg)",
                        value: userInput.weight,
                        min: 30,
                        max: 180,
                        divisions: 150,
                        onChanged: (val) => setState(() => userInput.weight = val),
                      ),
                      // Family History with Overweight
                      CustomDropdown(
                        label: "Riwayat Keluarga Overweight",
                        value: userInput.familyHistory,
                        items: [
                          DropdownMenuItem(value: 0.0, child: Text("Tidak")),
                          DropdownMenuItem(value: 1.0, child: Text("Ya")),
                        ],
                        onChanged: (val) => setState(() => userInput.familyHistory = val!),
                      ),
                    ],
                  ),
                ),

                // ═══════════════════════════════════════════
                // LANGKAH 2: DIET & MAKAN
                // ═══════════════════════════════════════════
                Step(
                  title: Text("Diet"),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: Column(
                    children: [
                      // FAVC - Sering makan makanan berkalori tinggi
                      CustomDropdown(
                        label: "Sering makan berkalori tinggi?",
                        value: userInput.favc,
                        items: [
                          DropdownMenuItem(value: 0.0, child: Text("Tidak")),
                          DropdownMenuItem(value: 1.0, child: Text("Ya")),
                        ],
                        onChanged: (val) => setState(() => userInput.favc = val!),
                      ),
                      // FCVC - Frekuensi makan sayur
                      CustomSlider(
                        label: "Frekuensi Makan Sayur (Setiap Makan, 1-3)",
                        value: userInput.fcvc,
                        min: 1,
                        max: 3,
                        divisions: 2,
                        onChanged: (val) => setState(() => userInput.fcvc = val),
                      ),
                      // NCP - Jumlah makan utama per hari
                      CustomSlider(
                        label: "Makan Utama per Hari (1-4)",
                        value: userInput.ncp,
                        min: 1,
                        max: 4,
                        divisions: 3,
                        onChanged: (val) => setState(() => userInput.ncp = val),
                      ),
                      // CAEC - Konsumsi makanan di antara jam makan
                      CustomDropdown(
                        label: "Makan di Antara Jam Makan",
                        value: userInput.caec,
                        items: [
                          DropdownMenuItem(value: 0.0, child: Text("Tidak Pernah")),
                          DropdownMenuItem(value: 1.0, child: Text("Kadang-kadang")),
                          DropdownMenuItem(value: 2.0, child: Text("Sering")),
                          DropdownMenuItem(value: 3.0, child: Text("Selalu")),
                        ],
                        onChanged: (val) => setState(() => userInput.caec = val!),
                      ),
                      // CH2O - Konsumsi air harian
                      CustomSlider(
                        label: "Konsumsi Air per Hari (Liter, 1-3)",
                        value: userInput.ch2o,
                        min: 1,
                        max: 3,
                        divisions: 20,
                        onChanged: (val) => setState(() => userInput.ch2o = val),
                      ),
                      // SCC - Monitor kalori
                      CustomDropdown(
                        label: "Apakah Anda Monitor Kalori?",
                        value: userInput.scc,
                        items: [
                          DropdownMenuItem(value: 0.0, child: Text("Tidak")),
                          DropdownMenuItem(value: 1.0, child: Text("Ya")),
                        ],
                        onChanged: (val) => setState(() => userInput.scc = val!),
                      ),
                    ],
                  ),
                ),

                // ═══════════════════════════════════════════
                // LANGKAH 3: GAYA HIDUP
                // ═══════════════════════════════════════════
                Step(
                  title: Text("Gaya Hidup"),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                  content: Column(
                    children: [
                      // SMOKE
                      CustomDropdown(
                        label: "Apakah Anda Merokok?",
                        value: userInput.smoke,
                        items: [
                          DropdownMenuItem(value: 0.0, child: Text("Tidak")),
                          DropdownMenuItem(value: 1.0, child: Text("Ya")),
                        ],
                        onChanged: (val) => setState(() => userInput.smoke = val!),
                      ),
                      // FAF - Frekuensi aktivitas fisik
                      CustomSlider(
                        label: "Aktivitas Fisik per Minggu (0-3 hari)",
                        value: userInput.faf,
                        min: 0,
                        max: 3,
                        divisions: 3,
                        onChanged: (val) => setState(() => userInput.faf = val),
                      ),
                      // TUE - Waktu penggunaan gadget
                      CustomSlider(
                        label: "Waktu Pakai Gadget per Hari (0-2 jam)",
                        value: userInput.tue,
                        min: 0,
                        max: 2,
                        divisions: 20,
                        onChanged: (val) => setState(() => userInput.tue = val),
                      ),
                      // CALC - Konsumsi alkohol
                      CustomDropdown(
                        label: "Konsumsi Alkohol",
                        value: userInput.calc,
                        items: [
                          DropdownMenuItem(value: 0.0, child: Text("Tidak Pernah")),
                          DropdownMenuItem(value: 1.0, child: Text("Kadang-kadang")),
                          DropdownMenuItem(value: 2.0, child: Text("Sering")),
                          DropdownMenuItem(value: 3.0, child: Text("Selalu")),
                        ],
                        onChanged: (val) => setState(() => userInput.calc = val!),
                      ),
                      // MTRANS - Transportasi utama
                      CustomDropdown(
                        label: "Transportasi Utama",
                        value: userInput.mtrans,
                        items: [
                          DropdownMenuItem(value: 0.0, child: Text("Mobil")),
                          DropdownMenuItem(value: 1.0, child: Text("Motor")),
                          DropdownMenuItem(value: 2.0, child: Text("Sepeda")),
                          DropdownMenuItem(value: 3.0, child: Text("Transportasi Umum")),
                          DropdownMenuItem(value: 4.0, child: Text("Jalan Kaki")),
                        ],
                        onChanged: (val) => setState(() => userInput.mtrans = val!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    tfliteService.dispose();
    super.dispose();
  }
}