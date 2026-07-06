import 'package:flutter/material.dart';
import '../models/user_input.dart';
import '../services/data_scaler.dart';
import '../services/tflite_service.dart';
import '../widgets/custom_radio_button.dart';
import '../widgets/custom_number_input.dart';
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
  final _formKeyStep0 = GlobalKey<FormState>();

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

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      return _formKeyStep0.currentState?.validate() ?? false;
    }
    // Step 1 & 2: semua dropdown/radio sudah punya default value
    return true;
  }

  void _onStepContinue() {
    if (!_validateCurrentStep()) return;

    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
    } else {
      _submitData();
    }
  }

  void _submitData() async {
    // Re-validasi step 0 untuk keamanan
    if (!(_formKeyStep0.currentState?.validate() ?? false)) {
      setState(() => _currentStep = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mohon lengkapi data fisik terlebih dahulu")),
      );
      return;
    }

    if (!_isModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Model sedang dimuat, mohon tunggu...")),
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
      MaterialPageRoute(
          builder: (context) => ResultScreen(resultStatus: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kuesioner Kesehatan")),
      body: Column(
        children: [
          // Indikator loading model
          if (!_isModelLoaded) LinearProgressIndicator(),

          Expanded(
            child: Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: _onStepContinue,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed:
                                _isSubmitting ? null : details.onStepContinue,
                            child: _isSubmitting && isLastStep
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(isLastStep
                                    ? "Prediksi Sekarang"
                                    : "Lanjut"),
                          ),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: details.onStepCancel,
                              child: Text("Kembali"),
                            ),
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
                  state:
                      _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: Form(
                    key: _formKeyStep0,
                    child: Column(
                      children: [
                        // Gender - Radio Button
                        CustomRadioButton(
                          label: "Jenis Kelamin",
                          value: userInput.gender,
                          options: [
                            RadioOption(label: "Perempuan", value: 0.0),
                            RadioOption(label: "Laki-laki", value: 1.0),
                          ],
                          onChanged: (val) =>
                              setState(() => userInput.gender = val),
                        ),
                        // Age - Number Input Box
                        CustomNumberInput(
                          label: "Usia",
                          suffix: "tahun",
                          hintText: "Contoh: 25",
                          value: userInput.age,
                          allowDecimal: false,
                          onChanged: (val) =>
                              setState(() => userInput.age = val),
                        ),
                        // Height - Number Input Box (meter)
                        CustomNumberInput(
                          label: "Tinggi Badan",
                          suffix: "meter",
                          hintText: "Contoh: 1.65",
                          value: userInput.height,
                          allowDecimal: true,
                          onChanged: (val) =>
                              setState(() => userInput.height = val),
                        ),
                        // Weight - Number Input Box (kg)
                        CustomNumberInput(
                          label: "Berat Badan",
                          suffix: "kg",
                          hintText: "Contoh: 65",
                          value: userInput.weight,
                          allowDecimal: true,
                          onChanged: (val) =>
                              setState(() => userInput.weight = val),
                        ),
                        // Family History with Overweight - Radio Button
                        CustomRadioButton(
                          label: "Riwayat Obesitas Keluarga",
                          value: userInput.familyHistory,
                          options: [
                            RadioOption(label: "Ya", value: 1.0),
                            RadioOption(label: "Tidak", value: 0.0),
                          ],
                          onChanged: (val) =>
                              setState(() => userInput.familyHistory = val),
                        ),
                      ],
                    ),
                  ),
                ),

                // ═══════════════════════════════════════════
                // LANGKAH 2: DIET & MAKAN
                // ═══════════════════════════════════════════
                Step(
                  title: Text("Diet"),
                  isActive: _currentStep >= 1,
                  state:
                      _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: Column(
                    children: [
                      // FAVC - Radio Button
                      CustomRadioButton(
                        label: "Konsumsi Makanan Berkalori Tinggi",
                        value: userInput.favc,
                        options: [
                          RadioOption(label: "Ya", value: 1.0),
                          RadioOption(label: "Tidak", value: 0.0),
                        ],
                        onChanged: (val) =>
                            setState(() => userInput.favc = val),
                      ),
                      // FCVC - Dropdown
                      CustomDropdown(
                        label: "Frekuensi Makan Sayur",
                        value: userInput.fcvc,
                        items: [
                          DropdownMenuItem(
                              value: 1.0, child: Text("Tidak pernah")),
                          DropdownMenuItem(
                              value: 2.0, child: Text("Kadang-kadang")),
                          DropdownMenuItem(value: 3.0, child: Text("Selalu")),
                        ],
                        onChanged: (val) =>
                            setState(() => userInput.fcvc = val!),
                      ),
                      // NCP - Dropdown
                      CustomDropdown(
                        label: "Jumlah Makan Utama Harian",
                        value: userInput.ncp,
                        items: [
                          DropdownMenuItem(value: 1.0, child: Text("1 kali")),
                          DropdownMenuItem(value: 2.0, child: Text("2 kali")),
                          DropdownMenuItem(value: 3.0, child: Text("3 kali")),
                          DropdownMenuItem(value: 4.0, child: Text("> 3 kali")),
                        ],
                        onChanged: (val) =>
                            setState(() => userInput.ncp = val!),
                      ),
                      // CAEC - Dropdown
                      CustomDropdown(
                        label: "Konsumsi Makanan Antara Jam Makan Utama",
                        value: userInput.caec,
                        items: [
                          DropdownMenuItem(value: 0.0, child: Text("Tidak")),
                          DropdownMenuItem(
                              value: 1.0, child: Text("Kadang-kadang")),
                          DropdownMenuItem(value: 2.0, child: Text("Sering")),
                          DropdownMenuItem(value: 3.0, child: Text("Selalu")),
                        ],
                        onChanged: (val) =>
                            setState(() => userInput.caec = val!),
                      ),
                      // CH2O - Dropdown
                      CustomDropdown(
                        label: "Konsumsi Air Harian",
                        value: userInput.ch2o,
                        items: [
                          DropdownMenuItem(
                              value: 1.0, child: Text("< 1 liter")),
                          DropdownMenuItem(
                              value: 2.0, child: Text("1 - 2 liter")),
                          DropdownMenuItem(
                              value: 3.0, child: Text("> 2 liter")),
                        ],
                        onChanged: (val) =>
                            setState(() => userInput.ch2o = val!),
                      ),
                      // SCC - Radio Button
                      CustomRadioButton(
                        label: "Pemantauan Konsumsi Kalori",
                        value: userInput.scc,
                        options: [
                          RadioOption(label: "Ya", value: 1.0),
                          RadioOption(label: "Tidak", value: 0.0),
                        ],
                        onChanged: (val) => setState(() => userInput.scc = val),
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
                  state:
                      _currentStep > 2 ? StepState.complete : StepState.indexed,
                  content: Column(
                    children: [
                      // SMOKE - Radio Button
                      CustomRadioButton(
                        label: "Merokok",
                        value: userInput.smoke,
                        options: [
                          RadioOption(label: "Ya", value: 1.0),
                          RadioOption(label: "Tidak", value: 0.0),
                        ],
                        onChanged: (val) =>
                            setState(() => userInput.smoke = val),
                      ),
                      // FAF - Dropdown
                      CustomDropdown(
                        label: "Frekuensi Aktivitas Fisik (dalam seminggu)",
                        value: userInput.faf,
                        items: [
                          DropdownMenuItem(
                              value: 0.0, child: Text("Tidak ada")),
                          DropdownMenuItem(
                              value: 1.0, child: Text("1 - 2 hari")),
                          DropdownMenuItem(
                              value: 2.0, child: Text("2 - 4 hari")),
                          DropdownMenuItem(
                              value: 3.0, child: Text("4 - 5 hari")),
                        ],
                        onChanged: (val) =>
                            setState(() => userInput.faf = val!),
                      ),
                      // TUE - Dropdown
                      CustomDropdown(
                        label: "Waktu Penggunaan Perangkat Teknologi",
                        value: userInput.tue,
                        items: [
                          DropdownMenuItem(
                              value: 0.0, child: Text("0 - 2 jam")),
                          DropdownMenuItem(
                              value: 1.0, child: Text("3 - 5 jam")),
                          DropdownMenuItem(value: 2.0, child: Text("> 5 jam")),
                        ],
                        onChanged: (val) =>
                            setState(() => userInput.tue = val!),
                      ),
                      // CALC - Dropdown
                      CustomDropdown(
                        label: "Konsumsi Alkohol",
                        value: userInput.calc,
                        items: [
                          DropdownMenuItem(
                              value: 0.0, child: Text("Tidak minum")),
                          DropdownMenuItem(
                              value: 1.0, child: Text("Kadang-kadang")),
                          DropdownMenuItem(value: 2.0, child: Text("Sering")),
                          DropdownMenuItem(value: 3.0, child: Text("Selalu")),
                        ],
                        onChanged: (val) =>
                            setState(() => userInput.calc = val!),
                      ),
                      // MTRANS - Dropdown
                      CustomDropdown(
                        label: "Transportasi Utama",
                        value: userInput.mtrans,
                        items: [
                          DropdownMenuItem(value: 0.0, child: Text("Mobil")),
                          DropdownMenuItem(value: 1.0, child: Text("Motor")),
                          DropdownMenuItem(value: 2.0, child: Text("Sepeda")),
                          DropdownMenuItem(
                              value: 3.0, child: Text("Transportasi Umum")),
                          DropdownMenuItem(
                              value: 4.0, child: Text("Jalan Kaki")),
                        ],
                        onChanged: (val) =>
                            setState(() => userInput.mtrans = val!),
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
