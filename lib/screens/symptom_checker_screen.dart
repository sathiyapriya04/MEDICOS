import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SymptomCheckerScreen extends StatefulWidget {
  @override
  _SymptomCheckerScreenState createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final TextEditingController _symptomController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _responseText = '';
  String _medicineText = '';
  bool _loading = false;

  // Preserving the original symptom solutions and medicines maps
  final Map<String, String> _symptomSolutions = {
  'headache': 'Rest, stay hydrated, and take over-the-counter pain relievers.',
    'fever': 'Drink fluids, rest, and consider paracetamol if it\'s high.',
    'cough': 'Stay hydrated and use cough syrup if needed.',
  'sore throat': 'Gargle with warm salt water and use throat lozenges.',
  'cold': 'Rest, hydrate, and take steam inhalation.',
  'nausea': 'Avoid solid food, stay hydrated, and try ginger tea.',
  'vomiting': 'Drink clear fluids and rest the stomach.',
  'diarrhea': 'Stay hydrated and consume electrolyte-rich fluids.',
  'constipation': 'Increase fiber intake and drink plenty of water.',
  'fatigue': 'Get adequate rest and eat nutritious foods.',
  'dizziness': 'Lie down, avoid sudden movements, and drink water.',
  'chest pain': 'Rest and seek medical attention if it persists.',
  'shortness of breath': 'Sit upright, breathe slowly, and seek medical help.',
  'back pain': 'Apply heat/cold, rest, and consider stretching exercises.',
  'abdominal pain': 'Apply warm compress and monitor for changes.',
  'acne': 'Wash face regularly, avoid oily food, and try topical treatments.',
  'rash': 'Avoid allergens and apply calamine lotion.',
  'itching': 'Use antihistamines and avoid scratching.',
  'burning eyes': 'Rinse with cold water and use lubricating eye drops.',
  'dry eyes': 'Use artificial tears and avoid screen overuse.',
  'blurred vision': 'Rest eyes and consult an optometrist.',
  'ear pain': 'Warm compress and pain relievers help.',
  'runny nose': 'Use decongestants and stay warm.',
  'stuffed nose': 'Steam inhalation and nasal drops.',
  'toothache': 'Rinse with salt water and apply clove oil.',
  'gum bleeding': 'Use soft toothbrush and rinse with antiseptic mouthwash.',
  'swollen gums': 'Rinse with warm salt water and maintain oral hygiene.',
  'hair loss': 'Use anti-hair fall shampoo and consider supplements.',
  'anxiety': 'Practice relaxation techniques and deep breathing.',
  'depression': 'Seek counseling and try staying active.',
  'insomnia': 'Avoid caffeine and maintain sleep hygiene.',
  'leg cramps': 'Stretching, hydration, and magnesium supplements.',
  'muscle pain': 'Apply cold/hot compress and take rest.',
  'joint pain': 'Use anti-inflammatory medication and rest.',
  'knee pain': 'Apply ice packs and avoid overexertion.',
  'elbow pain': 'Rest, compression, and elevate the elbow.',
  'shoulder pain': 'Use hot/cold compress and stretch gently.',
  'neck pain': 'Apply heat, rest, and do neck stretches.',
  'eye strain': 'Follow 20-20-20 rule and reduce screen time.',
  'indigestion': 'Eat smaller meals and avoid spicy foods.',
  'heartburn': 'Avoid heavy meals and consider antacids.',
  'gas': 'Avoid carbonated drinks and try walking after meals.',
  'bloating': 'Eat slowly and reduce intake of legumes.',
  'hiccups': 'Hold your breath or sip cold water.',
  'frequent urination': 'Avoid caffeine and consult doctor if persistent.',
  'burning urination': 'Drink water and consult for UTI.',
  'urine retention': 'Seek immediate medical attention.',
  'sweating': 'Wear breathable clothes and stay cool.',
  'night sweats': 'Keep bedroom cool and use cotton sheets.',
  'body aches': 'Take pain relievers and get adequate rest.',
  'chills': 'Stay warm and hydrated.',
  'palpitations': 'Practice deep breathing and avoid stimulants.',
  'bruising': 'Apply cold compress and elevate the area.',
  'high blood pressure': 'Take prescribed antihypertensives and reduce stress.',
  'high cholesterol': 'Take statins and adjust diet.',
  'muscle weakness': 'Take potassium supplements and physical therapy.',
  'joint stiffness': 'Use pain relievers and do stretching exercises.',
  'ringing in ears': 'Use noise masking devices or hearing aids.',
  'dry mouth': 'Stay hydrated and use saliva substitutes.',
  'thirst': 'Drink plenty of water and electrolytes.',
  'frequent headaches': 'Manage stress and avoid triggers.',
  'poor appetite': 'Try appetite stimulants and eat small, frequent meals.',
  'difficulty swallowing': 'Use swallowing aids and seek speech therapy.',
  'excessive hunger': 'Consider blood sugar regulation and balanced diet.',
  'excessive thirst': 'Stay hydrated and consult for diabetes.',
  'swelling': 'Use compression and elevate affected areas.',
  'severe fatigue': 'Consult for underlying conditions like anemia or thyroid.',
  'bruises easily': 'Consider vitamin C or vitamin K supplements.',
  'chronic cough': 'Use cough suppressant and seek medical advice.',
  'pale skin': 'Consider iron and vitamin B12 supplements.',
  'bleeding gums': 'Ensure good oral hygiene and vitamin C intake.',
  'memory loss': 'Use memory enhancement techniques and supplements.',
  'mood swings': 'Consider mood stabilizers and regular therapy.',
  'sensitivity to light': 'Wear sunglasses and limit exposure.',
  'loss of appetite': 'Consult a nutritionist and consider appetite stimulants.',
  'unexplained weight loss': 'Consult a doctor to check for thyroid or cancer.',
  'yellowing skin': 'Seek medical attention for liver or gallbladder issues.',
  'dehydration': 'Increase fluid intake and use oral rehydration solutions.',
  'cold sweats': 'Manage stress levels and stay hydrated.',
  'difficulty breathing': 'Use prescribed inhalers or seek medical attention.',
  'pale or blue lips': 'Seek emergency care for oxygen deficiency.',
  'painful urination': 'Take antibiotics if UTI is suspected and drink water.',
  'swollen lymph nodes': 'Consult for infections or other conditions.',
  'bloody stools': 'Seek immediate medical attention for possible gastrointestinal bleeding.',
  'stomach bloating': 'Take anti-gas medication and consult a doctor.',
  'nightmares': 'Practice relaxation techniques and consult for sleep disorders.',
  'numbness': 'Consult a doctor for nerve-related issues or vitamin deficiencies.',
  'unexplained weight gain': 'Check for thyroid problems and consult a healthcare provider.',
  'low blood sugar': 'Consume glucose tablets or sugary drinks as needed.',
  'excessive bruising': 'Consult for possible blood clotting issues.',
  'shivering': 'Ensure warmth and consider hydration.',
  'nausea after meals': 'Try antacids or other medications for digestive health.',
  'dehydrated skin': 'Use moisturizers and drink plenty of water.',
  'liver pain': 'Consult a doctor for liver disease or gallbladder issues.',
  'neck stiffness': 'Use pain relievers and consider physical therapy.',
  'constant yawning': 'Ensure adequate sleep and manage stress levels.',
  'cold hands or feet': 'Consider circulation supplements and warm clothing.',
  'skin discoloration': 'Consult a dermatologist for proper skin care.',
  'loss of coordination': 'Seek medical advice for neurological issues.',
  'fainting': 'Sit or lie down, drink water, and consult for underlying conditions.',
  'nausea and vomiting': 'Use anti-nausea medications and stay hydrated.',
  'chronic fatigue': 'Consult for underlying causes like anemia or thyroid issues.',
  'tinnitus': 'Consult an audiologist for treatment options.',
  'poor circulation': 'Use compression socks and consult a doctor.',
  'chronic pain': 'Manage with pain relievers and physical therapy.',
  'stress': 'Practice relaxation techniques and consider therapy.',
  'muscle cramps': 'Hydration, magnesium supplements, and stretching.',
};

final Map<String, String> _symptomMedicines = {
  'headache': 'Paracetamol, Ibuprofen',
  'fever': 'Paracetamol, Ibuprofen',
  'cough': 'Benadryl, Dextromethorphan',
  'sore throat': 'Strepsils, Betadine Gargle',
  'cold': 'Cetirizine, Steam inhalation',
  'nausea': 'Domperidone, Ondansetron',
  'vomiting': 'Ondansetron, ORS',
  'diarrhea': 'Loperamide, ORS',
  'constipation': 'Lactulose, Isabgol',
  'fatigue': 'Vitamin B Complex, Iron supplements',
  'dizziness': 'Meclizine, Dimenhydrinate',
  'chest pain': 'Aspirin, Nitroglycerin (seek urgent care)',
  'shortness of breath': 'Inhaler (Salbutamol), Oxygen',
  'back pain': 'Ibuprofen, Diclofenac Gel',
  'abdominal pain': 'Buscopan, Simethicone',
  'acne': 'Benzoyl peroxide, Clindamycin Gel',
  'rash': 'Calamine lotion, Antihistamines',
  'itching': 'Levocetirizine, Cetrizine',
  'burning eyes': 'Tears Naturale, Refresh Eye Drops',
  'dry eyes': 'Lubricant eye drops, Omega-3',
  'blurred vision': 'Lubricating drops (if dryness), see doctor',
  'ear pain': 'Paracetamol, Ear drops (Otogesic)',
  'runny nose': 'Antihistamines, Decongestant',
  'stuffed nose': 'Otrivin, Nasal saline spray',
  'toothache': 'Ibuprofen, Clove oil',
  'gum bleeding': 'Chlorhexidine mouthwash, Vit C',
  'swollen gums': 'Antiseptic rinse, Metronidazole gel',
  'hair loss': 'Minoxidil, Biotin supplements',
  'anxiety': 'Alprazolam (under supervision), Herbal tea',
  'depression': 'Sertraline, Counseling',
  'insomnia': 'Melatonin, Zolpidem',
  'leg cramps': 'Magnesium, ORS',
  'muscle pain': 'Ibuprofen, Muscle relaxants',
  'joint pain': 'Diclofenac, Glucosamine',
  'knee pain': 'Diclofenac Gel, Paracetamol',
  'elbow pain': 'Volini Spray, Ibuprofen',
  'shoulder pain': 'Cold pack, Naproxen',
  'neck pain': 'Massage cream, Ibuprofen',
  'eye strain': 'Lubricating drops, Rest',
  'indigestion': 'Gelusil, Digene',
  'heartburn': 'Ranitidine, Omeprazole',
  'gas': 'Simethicone, Eno',
  'bloating': 'Dimethicone, Herbal tea',
  'hiccups': 'Chlorpromazine (if persistent)',
  'frequent urination': 'Oxybutynin (if due to bladder), consult',
  'burning urination': 'Ciprofloxacin, Alkalizer',
  'urine retention': 'Medical intervention needed',
  'sweating': 'Antiperspirants, Propantheline',
  'night sweats': 'Cooling sheets, consult if persistent',
  'body aches': 'Paracetamol, Ibuprofen',
  'chills': 'Warm fluids, Paracetamol',
  'palpitations': 'Propranolol (consult doctor)',
  'bruising': 'Cold compress, Arnica cream',
  'high blood pressure': 'Lisinopril, Amlodipine',
  'high cholesterol': 'Atorvastatin, Simvastatin',
  'muscle weakness': 'Potassium supplements, Physical therapy',
  'joint stiffness': 'Ibuprofen, Stretching exercises',
  'ringing in ears': 'Hearing aids, Noise masking devices',
  'dry mouth': 'Saliva substitutes, Hydration',
  'thirst': 'Electrolyte solution, Water',
  'frequent headaches': 'Stress management, Pain relievers (Paracetamol)',
  'poor appetite': 'Appetite stimulants, Small meals',
  'difficulty swallowing': 'Swallowing aids, Speech therapy',
  'excessive hunger': 'Blood sugar regulation, Balanced diet',
  'excessive thirst': 'Hydration, Consult doctor for diabetes',
  'swelling': 'Compression, Elevation',
  'severe fatigue': 'Consult for anemia, thyroid problems',
  'bruises easily': 'Vitamin C, Vitamin K supplements',
  'chronic cough': 'Cough suppressant, Consult doctor',
  'pale skin': 'Iron supplements, Vitamin B12',
  'bleeding gums': 'Good oral hygiene, Vitamin C',
  'memory loss': 'Memory supplements, Cognitive exercises',
  'mood swings': 'Mood stabilizers, Therapy',
  'sensitivity to light': 'Sunglasses, Limit exposure',
  'loss of appetite': 'Nutritionist consultation, Appetite stimulants',
  'unexplained weight loss': 'Consult for thyroid, cancer checks',
  'yellowing skin': 'Consult doctor for liver or gallbladder issues',
  'dehydration': 'Oral rehydration solutions, Increased fluid intake',
  'cold sweats': 'Stress management, Hydration',
  'difficulty breathing': 'Inhaler, Seek medical attention',
  'pale or blue lips': 'Seek emergency care, Oxygen therapy',
  'painful urination': 'Ciprofloxacin, Alkalizer',
  'swollen lymph nodes': 'Consult for infections, Medical evaluation',
  'bloody stools': 'Immediate medical attention for gastrointestinal bleeding',
  'stomach bloating': 'Anti-gas medication, Consult doctor',
  'nightmares': 'Relaxation techniques, Sleep disorder consultation',
  'numbness': 'Consult doctor for nerve issues, Vitamin supplements',
  'unexplained weight gain': 'Thyroid check, Consult healthcare provider',
  'low blood sugar': 'Glucose tablets, Sugary drinks',
  'excessive bruising': 'Consult doctor for clotting issues',
  'shivering': 'Warmth, Hydration',
  'ringing in ears': 'Consult audiologist, Noise masking',
  'nausea after meals': 'Antacids, Digestive aids',
  'dehydrated skin': 'Moisturizers, Hydration',
  'liver pain': 'Consult doctor for liver disease or gallbladder issues',
  'neck stiffness': 'Pain relievers, Physical therapy',
  'constant yawning': 'Adequate sleep, Stress management',
  'cold hands or feet': 'Circulation supplements, Warm clothing',
  'skin discoloration': 'Consult dermatologist for proper care',
  'loss of coordination': 'Consult doctor for neurological issues',
  'fainting': 'Sit or lie down, Hydration, Medical consultation',
  'nausea and vomiting': 'Anti-nausea medications, Hydration',
  'chronic fatigue': 'Consult doctor for anemia, thyroid problems',
  'tinnitus': 'Consult audiologist for treatment options',
  'poor circulation': 'Compression socks, Consult doctor',
  'chronic pain': 'Pain relievers, Physical therapy',
  'stress': 'Relaxation techniques, Therapy',
  'muscle cramps': 'Magnesium supplements, Hydration'
};

Future<void> _startListening() async {
  bool available = await _speech.initialize(
    onStatus: (status) {
      if (status == "done" || status == "notListening") {
        setState(() => _isListening = false);
      }
    },
    onError: (error) {
      print("Speech recognition error: $error");
    },
  );
  if (available) {
    setState(() {
      _isListening = true;
      _symptomController.clear();
    });
    _speech.listen(
      onResult: (val) => setState(() {
        _symptomController.text = val.recognizedWords;
      }),
    );
  }
}

void _checkLocalSymptoms(String symptom) async {
  setState(() {
    _loading = true;
    _responseText = '';
    _medicineText = '';
  });
  final key = symptom.toLowerCase().trim();
  final solution = _symptomSolutions[key] ?? 'No information found for "$symptom". Try rephrasing.';
  final medicine = _symptomMedicines[key] ?? 'No recommended medicine found for "$symptom".';

  setState(() {
    _responseText = solution;
    _medicineText = medicine;
  });

  await _flutterTts.speak("Here's the suggestion for $symptom. $solution. Recommended medicines are: $medicine.");
  setState(() {
    _isListening = false;
    _loading = false;
  });
}

@override
void dispose() {
  _speech.stop();
  _flutterTts.stop();
  _symptomController.dispose();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  // Define green color scheme
  final primaryGreen = Color(0xFF2E7D32); // Forest green
  final lightGreen = Color(0xFFE8F5E9);   // Light green for backgrounds
  final accentGreen = Color(0xFF00C853);  // Bright green for buttons/highlights

  return Scaffold(
    appBar: AppBar(
      title: Text(
        'Symptom Checker',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: primaryGreen,
      elevation: 0,
    ),
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryGreen.withOpacity(0.05), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  'What symptoms are you experiencing?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: primaryGreen,
                  ),
                ),
              ),

              // Search Input Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _symptomController,
                  decoration: InputDecoration(
                    hintText: 'Describe your symptom',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, color: primaryGreen),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.arrow_forward, color: accentGreen),
                      onPressed: () {
                        if (_symptomController.text.trim().isNotEmpty) {
                          _checkLocalSymptoms(_symptomController.text.trim());
                          FocusScope.of(context).unfocus();
                        }
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                  style: TextStyle(fontSize: 16),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _checkLocalSymptoms(value.trim());
                    }
                  },
                ),
              ),

              SizedBox(height: 16),

              // Voice Input Button
              InkWell(
                onTap: _isListening ? null : _startListening,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.grey.shade400 : accentGreen,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _isListening
                            ? Colors.transparent
                            : accentGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        _isListening ? 'Listening...' : 'Speak Your Symptoms',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Loading indicator
              if (_loading)
                Center(
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Getting advice...',
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Results
              if (_responseText.isNotEmpty && !_loading)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: lightGreen,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryGreen.withOpacity(0.3)),
                          ),
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.healing, color: primaryGreen),
                                  SizedBox(width: 8),
                                  Text(
                                    'Recommendation',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text(
                                _responseText,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryGreen.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.medication, color: primaryGreen),
                                  SizedBox(width: 8),
                                  Text(
                                    'Recommended Medicine',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text(
                                _medicineText,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: lightGreen.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: primaryGreen, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Always consult a healthcare professional for proper diagnosis and treatment.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: primaryGreen,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
}